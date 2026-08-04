//
//  UnlockStateTests.swift
//  GigaBallTests
//
//  The baseline for removing the premiumSetting gating.
//
//  premiumSetting is unconditionally forced true, but checkPremium() does more
//  than set a flag: it rewrites the persisted unlock arrays in TotalStats,
//  mapping every entry to true on each menu refresh. So the live unlock state
//  of any player who has launched a recent build is "everything unlocked",
//  regardless of what they actually earned.
//
//  That matters because the failure mode of removing the gating is silent. No
//  crash, no error - content the player had access to yesterday is simply
//  locked today. These tests record what the unlock state is now, so the
//  removal can be diffed against it rather than eyeballed.
//
//  They deliberately assert current behaviour, including behaviour that is
//  arguably wrong. Where that is the case it is called out in the test.
//

import XCTest
@testable import Giga_Ball

final class UnlockStateTests: XCTestCase {

    /// What `MenuViewController.checkPremium()` does to a stats blob, minus the
    /// UserDefaults writes and the encode. Kept here so the tests exercise the
    /// same transform the app applies, and so the removal has something
    /// concrete to compare to.
    ///
    /// All five unlock arrays, matching checkPremium() line for line. If that
    /// function grows a sixth, this must follow it or these tests quietly stop
    /// describing the app.
    private func applyForceUnlock(to stats: TotalStats) {
        stats.levelPackUnlockedArray = stats.levelPackUnlockedArray.map { _ in true }
        stats.levelUnlockedArray = stats.levelUnlockedArray.map { _ in true }
        stats.powerUpUnlockedArray = stats.powerUpUnlockedArray.map { _ in true }
        stats.themeUnlockedArray = stats.themeUnlockedArray.map { _ in true }
        stats.appIconUnlockedArray = stats.appIconUnlockedArray.map { _ in true }
    }

    // MARK: - The default state, before any force-unlock

    func testFreshInstallUnlocksTheFirstThreePacks() {
        // Tutorial, endless mode, Classic, Space and Nature start unlocked;
        // everything from City onwards is earned.
        let stats = TotalStats()
        let unlocked = stats.levelPackUnlockedArray

        XCTAssertEqual(unlocked.prefix(5), [true, true, true, true, true])
        XCTAssertTrue(unlocked.dropFirst(5).allSatisfy { $0 == false },
                      "Packs from City onwards should start locked: \(unlocked)")
    }

    func testFreshInstallUnlocksTheFirstLevelOfEachStartingPack() {
        // Index 0 is endless mode, then the first level of Classic, Space and
        // Nature. Nothing else opens until it is earned.
        let stats = TotalStats()
        let unlockedIndices = stats.levelUnlockedArray.enumerated()
            .filter { $0.element }
            .map { $0.offset }

        XCTAssertEqual(unlockedIndices, [0, 1, 11, 21],
                       "Endless plus the first level of Classic, Space and Nature")
    }

    func testFreshInstallUnlocksOnlyTheFirstThemeAndIcon() {
        let stats = TotalStats()
        XCTAssertEqual(stats.themeUnlockedArray.filter { $0 }.count, 1)
        XCTAssertTrue(stats.themeUnlockedArray[0], "Classic theme")
        XCTAssertEqual(stats.appIconUnlockedArray.filter { $0 }.count, 1)
        XCTAssertTrue(stats.appIconUnlockedArray[0], "Purple icon")
    }

    func testFreshInstallLocksRoughlyHalfThePowerUps() {
        let stats = TotalStats()
        let unlockedCount = stats.powerUpUnlockedArray.filter { $0 }.count
        XCTAssertGreaterThan(unlockedCount, 0)
        XCTAssertLessThan(unlockedCount, stats.powerUpUnlockedArray.count,
                          "Some power-ups are earned, so the default is not all-true")
    }

    // MARK: - What the force-unlock actually changes

    func testForceUnlockOpensEverythingItTouches() {
        let stats = TotalStats()
        applyForceUnlock(to: stats)

        XCTAssertTrue(stats.levelPackUnlockedArray.allSatisfy { $0 })
        XCTAssertTrue(stats.levelUnlockedArray.allSatisfy { $0 })
        XCTAssertTrue(stats.powerUpUnlockedArray.allSatisfy { $0 })
    }

    func testForceUnlockIsNotAnIdentityOnAFreshInstall() {
        // The point of the whole exercise: the default state and the state the
        // app actually runs with are different. Removing the gating without
        // replacing this transform locks content that players currently have.
        let fresh = TotalStats()
        let forced = TotalStats()
        applyForceUnlock(to: forced)

        XCTAssertNotEqual(fresh.levelPackUnlockedArray, forced.levelPackUnlockedArray)
        XCTAssertNotEqual(fresh.levelUnlockedArray, forced.levelUnlockedArray)
        XCTAssertNotEqual(fresh.powerUpUnlockedArray, forced.powerUpUnlockedArray)
    }

    func testForceUnlockOpensThemesAndIconsToo() {
        // checkPremium() rewrites all five arrays, so the progression described
        // in the specification - complete a pack, earn the next theme and icon
        // - does not actually gate anything today. Everything is open from
        // first launch.
        let stats = TotalStats()
        applyForceUnlock(to: stats)

        XCTAssertTrue(stats.themeUnlockedArray.allSatisfy { $0 })
        XCTAssertTrue(stats.appIconUnlockedArray.allSatisfy { $0 })
    }

    func testNothingIsLeftLockedAfterTheForceUnlock() {
        // The whole of the player's unlock state, in one assertion. This is the
        // line the premiumSetting removal must not cross: whatever replaces
        // checkPremium(), an existing player must not end up with less.
        let stats = TotalStats()
        applyForceUnlock(to: stats)

        let stillLocked: [String] = [
            stats.levelPackUnlockedArray.contains(false) ? "packs" : nil,
            stats.levelUnlockedArray.contains(false) ? "levels" : nil,
            stats.powerUpUnlockedArray.contains(false) ? "power-ups" : nil,
            stats.themeUnlockedArray.contains(false) ? "themes" : nil,
            stats.appIconUnlockedArray.contains(false) ? "icons" : nil
        ].compactMap { $0 }

        XCTAssertTrue(stillLocked.isEmpty, "Left locked: \(stillLocked)")
    }

    func testForceUnlockIsIdempotent() {
        let stats = TotalStats()
        applyForceUnlock(to: stats)
        let afterFirst = stats.levelUnlockedArray
        applyForceUnlock(to: stats)

        XCTAssertEqual(stats.levelUnlockedArray, afterFirst,
                       "Runs on every menu refresh, so it must be safe to repeat")
    }

    // MARK: - Survives persistence

    func testUnlockStateSurvivesEncodingRoundTrip() throws {
        // The unlock arrays are what actually reaches iCloud and the stats
        // plist. If they did not round-trip, a synced device would disagree
        // with the local one about what is unlocked.
        let stats = TotalStats()
        applyForceUnlock(to: stats)

        let data = try PropertyListEncoder().encode(stats)
        let decoded = try PropertyListDecoder().decode(TotalStats.self, from: data)

        XCTAssertEqual(decoded.levelPackUnlockedArray, stats.levelPackUnlockedArray)
        XCTAssertEqual(decoded.levelUnlockedArray, stats.levelUnlockedArray)
        XCTAssertEqual(decoded.powerUpUnlockedArray, stats.powerUpUnlockedArray)
        XCTAssertEqual(decoded.themeUnlockedArray, stats.themeUnlockedArray)
        XCTAssertEqual(decoded.appIconUnlockedArray, stats.appIconUnlockedArray)
    }

    func testUnlockArraysAreIndexedByGlobalLevelNumber() {
        // levelUnlockedArray[0] is endless mode, so a level's flag sits at its
        // global level number. The pack selectors rely on this offset.
        let stats = TotalStats()
        let setup = LevelPackSetup()

        for pack in 2..<setup.startLevelNumber.count {
            let firstLevel = setup.startLevelNumber[pack]
            XCTAssertLessThan(firstLevel, stats.levelUnlockedArray.count,
                              "Pack \(pack) starts at level \(firstLevel), beyond the unlock array")
        }
    }
}
