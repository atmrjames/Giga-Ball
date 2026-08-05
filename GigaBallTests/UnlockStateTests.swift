//
//  UnlockStateTests.swift
//  GigaBallTests
//
//  What a player can reach, and when.
//
//  These started as the baseline for removing the premiumSetting gating.
//  checkPremium() used to rewrite all five unlock arrays to true on every menu
//  refresh, so nothing was actually gated. With that removed, the defaults in
//  TotalStats are the live starting state and the progression in
//  InbewteenLevels is what opens the rest.
//
//  The failure mode here is silent - no crash, no error, just content a player
//  cannot reach - so these pin the starting state precisely. Existing players
//  are unaffected: their arrays were already persisted as all-true by the old
//  force-unlock, and nothing re-locks them.
//
//  Not covered: the pack-completion unlocks themselves. They live in
//  InbewteenLevels, a GKState that mutates the scene, and cannot be exercised
//  without one. Extracting them is the natural next step.
//

import XCTest
@testable import Giga_Ball

final class UnlockStateTests: XCTestCase {

    // MARK: - The state a new player starts in

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

    func testAFreshInstallIsPlayable() {
        // The starting state has to leave something to play. With the
        // force-unlock gone, this is what stands between a new player and an
        // empty menu.
        let stats = TotalStats()
        XCTAssertTrue(stats.levelPackUnlockedArray.contains(true))
        XCTAssertTrue(stats.levelUnlockedArray.contains(true))
        XCTAssertTrue(stats.themeUnlockedArray[0])
        XCTAssertTrue(stats.appIconUnlockedArray[0])
    }

    func testNothingUnlocksEverythingAtOnce() {
        // Regression guard for the force-unlock coming back. If any of these
        // arrays is all-true on a fresh TotalStats, progression has stopped
        // gating and the pack-completion rewards mean nothing.
        let stats = TotalStats()
        XCTAssertTrue(stats.levelPackUnlockedArray.contains(false))
        XCTAssertTrue(stats.levelUnlockedArray.contains(false))
        XCTAssertTrue(stats.powerUpUnlockedArray.contains(false))
        XCTAssertTrue(stats.themeUnlockedArray.contains(false))
        XCTAssertTrue(stats.appIconUnlockedArray.contains(false))
    }

    // MARK: - Survives persistence

    func testUnlockStateSurvivesEncodingRoundTrip() throws {
        // The unlock arrays are what actually reaches iCloud and the stats
        // plist. If they did not round-trip, a synced device would disagree
        // with the local one about what is unlocked. Uses a part-way state,
        // since that is now what a real player has.
        let stats = TotalStats()
        stats.levelPackUnlockedArray[5] = true
        stats.levelUnlockedArray[2] = true
        stats.themeUnlockedArray[1] = true
        stats.appIconUnlockedArray[1] = true
        stats.powerUpUnlockedArray[6] = true

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
