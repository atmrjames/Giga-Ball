//
//  LevelPackSetupTests.swift
//  GigaBallTests
//
//  LevelPackSetup is ~30 parallel arrays indexed by pack, level, power-up,
//  theme, icon and achievement. Nothing enforces that they stay the same
//  length as each other, and the unlock gates index straight into them, so an
//  off-by-one shows up as the wrong name against the wrong level rather than
//  as a crash. These tests pin the lengths and the index arithmetic.
//

import XCTest
@testable import Giga_Ball

final class LevelPackSetupTests: XCTestCase {

    private var setup: LevelPackSetup!

    override func setUp() {
        super.setUp()
        setup = LevelPackSetup()
    }

    // MARK: - Asset integrity

    func testInstantiationResolvesEveryImageAsset() {
        // Every image array is built with a force-unwrapped UIImage(named:), so
        // constructing LevelPackSetup at all proves the assets are present and
        // correctly named. A renamed or dropped asset crashes here rather than
        // on whichever screen happens to display it.
        XCTAssertNotNil(setup)
        XCTAssertFalse(setup.themeIconArray.isEmpty)
        XCTAssertFalse(setup.appIconImageArray.isEmpty)
        XCTAssertFalse(setup.levelImageArray.isEmpty)
        XCTAssertFalse(setup.powerUpImageArray.isEmpty)
    }

    // MARK: - Packs

    func testPackArraysAgree() {
        // 11 content packs plus the tutorial and endless mode.
        XCTAssertEqual(setup.levelPackNameArray.count, 13)
        XCTAssertEqual(setup.numberOfLevels.count, setup.levelPackNameArray.count)
        XCTAssertEqual(setup.startLevelNumber.count, setup.levelPackNameArray.count)
    }

    func testElevenContentPacksOfTenLevels() {
        // Indices 0 and 1 are the tutorial and endless mode, which hold one
        // generated level each. The eleven real packs hold ten apiece.
        let contentPacks = setup.numberOfLevels.dropFirst(2)
        XCTAssertEqual(contentPacks.count, 11)
        XCTAssertTrue(contentPacks.allSatisfy { $0 == 10 },
                      "Every content pack should hold ten levels: \(Array(contentPacks))")
        XCTAssertEqual(contentPacks.reduce(0, +), 110)
    }

    func testStartLevelNumbersAreContiguous() {
        // Level numbers are global and contiguous: pack n starts where pack
        // n-1 ended. This is the arithmetic the level and pack selectors use to
        // turn a pack index into a level index, so a gap here mislabels a whole
        // pack rather than failing visibly.
        for pack in 2..<(setup.startLevelNumber.count - 1) {
            let expected = setup.startLevelNumber[pack] + setup.numberOfLevels[pack]
            XCTAssertEqual(setup.startLevelNumber[pack + 1], expected,
                           "Pack \(pack + 1) should start at \(expected)")
        }
        XCTAssertEqual(setup.startLevelNumber[2], 1, "Classic pack starts at level 1")
        XCTAssertEqual(setup.startLevelNumber.last, 101, "Challenge pack starts at level 101")
    }

    // MARK: - Levels

    func testLevelArraysAgree() {
        // 110 hand-designed levels plus one entry for endless mode.
        XCTAssertEqual(setup.levelNameArray.count, 111)
        XCTAssertEqual(setup.levelImageArray.count, setup.levelNameArray.count)
    }

    func testLevelNamesAreUnique() {
        let unique = Set(setup.levelNameArray)
        XCTAssertEqual(unique.count, setup.levelNameArray.count,
                       "Duplicate level names break level lookup by name")
    }

    // MARK: - Power-ups

    func testPowerUpArraysAgree() {
        let expected = 28
        XCTAssertEqual(setup.powerUpNameArray.count, expected)
        XCTAssertEqual(setup.powerUpImageArray.count, expected)
        XCTAssertEqual(setup.powerUpDescriptionArray.count, expected)
        XCTAssertEqual(setup.powerUpUnlockedDescriptionArray.count, expected)
        XCTAssertEqual(setup.powerUpHiddenUnlockedDescriptionArray.count, expected)
        XCTAssertEqual(setup.powerUpMultiplierArray.count, expected)
        XCTAssertEqual(setup.powerUpTimerArray.count, expected)
        XCTAssertEqual(setup.powerUpCorrectOrderArray.count, expected)
        XCTAssertEqual(setup.powerUpPackOrderArray.count, expected)
    }

    func testPowerUpDisplayOrderIsAPermutation() {
        // powerUpCorrectOrderArray reorders the power-ups for display. If it is
        // not a permutation of 0..<28 then some power-up is shown twice and
        // another never appears at all.
        XCTAssertEqual(Set(setup.powerUpCorrectOrderArray), Set(0..<28))
    }

    func testPowerUpPackOrderStaysInRange() {
        // Indexes the pack that unlocks each power-up.
        XCTAssertTrue(setup.powerUpPackOrderArray.allSatisfy { $0 >= 0 && $0 < 13 },
                      "Out-of-range pack index: \(setup.powerUpPackOrderArray)")
    }

    // MARK: - Themes and icons

    func testTwelveThemesAndTwelveIcons() {
        XCTAssertEqual(setup.themeNameArray.count, 12)
        XCTAssertEqual(setup.themeIconArray.count, 12)
        XCTAssertEqual(setup.ballImageArray.count, 12)
        XCTAssertEqual(setup.paddleImageArray.count, 12)
        XCTAssertEqual(setup.appIconNameArray.count, 12)
        XCTAssertEqual(setup.appIconImageArray.count, 12)
    }

    func testAppIconNamesAreUnique() {
        // These are passed to setAlternateIconName, so a duplicate means one
        // icon is unreachable.
        XCTAssertEqual(Set(setup.appIconNameArray).count, setup.appIconNameArray.count)
    }

    // MARK: - Game Center

    func testLeaderboardIdentifiersAreUniqueAndComplete() {
        // One leaderboard per level, excluding the levels that do not carry one.
        XCTAssertEqual(setup.levelLeaderboardsArray.count, 61)
        XCTAssertEqual(Set(setup.levelLeaderboardsArray).count,
                       setup.levelLeaderboardsArray.count,
                       "Duplicate leaderboard ID would post two levels' scores to one board")
        XCTAssertTrue(setup.levelLeaderboardsArray.allSatisfy { !$0.isEmpty })
    }

    func testAchievementArraysAgree() {
        let expected = setup.achievementsNameArray.count
        XCTAssertEqual(setup.achievementsPreEarnedDescriptionArray.count, expected)
        XCTAssertEqual(setup.achievementsEarnedDescriptionArray.count, expected)
        XCTAssertEqual(setup.achievementsImageArray.count, expected)
    }

    func testAchievementNamesAreUnique() {
        XCTAssertEqual(Set(setup.achievementsNameArray).count,
                       setup.achievementsNameArray.count)
    }
}
