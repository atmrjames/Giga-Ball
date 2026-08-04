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
    /// UserDefaults writes. Kept here so the tests exercise the same transform
    /// the app applies, and so the removal has something concrete to compare to.
    private func applyForceUnlock(to stats: TotalStats) {
        stats.levelPackUnlockedArray = stats.levelPackUnlockedArray.map { _ in true }
        stats.levelUnlockedArray = stats.levelUnlockedArray.map { _ in true }
        stats.powerUpUnlockedArray = stats.powerUpUnlockedArray.map { _ in true }
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

    func testForceUnlockLeavesThemesAndIconsAlone() {
        // checkPremium() rewrites packs, levels and power-ups but NOT themes or
        // app icons, even though the spec describes all four as unlocked by
        // completing packs. So themes and icons are still genuinely earned
        // while everything else is given away. Recorded because it is the kind
        // of asymmetry that a removal would otherwise quietly normalise in the
        // wrong direction.
        let stats = TotalStats()
        applyForceUnlock(to: stats)

        XCTAssertEqual(stats.themeUnlockedArray.filter { $0 }.count, 1,
                       "Themes are untouched by the force-unlock")
        XCTAssertEqual(stats.appIconUnlockedArray.filter { $0 }.count, 1,
                       "App icons are untouched by the force-unlock")
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
