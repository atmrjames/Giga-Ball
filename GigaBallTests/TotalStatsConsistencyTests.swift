//
//  TotalStatsConsistencyTests.swift
//  GigaBallTests
//
//  Every achievement is reached by indexing a fixed-length array. Those arrays come out of a
//  file written by whichever version of the app last saved it, so a release that adds an
//  achievement leaves every older file one entry short - and the crash lands at the moment
//  the player earns something, which is the worst possible time for it.
//

import XCTest
@testable import Giga_Ball

final class TotalStatsConsistencyTests: XCTestCase {

    func testAShortArrayIsBroughtUpToLength() {
        let stats = TotalStats()
        let full = stats.achievementsUnlockedArray.count
        XCTAssertGreaterThan(full, 0)

        stats.achievementsUnlockedArray = Array(repeating: true, count: full - 5)
        stats.achievementDates = Array(repeating: Date(), count: full - 5)
        stats.achievementsPercentageCompleteArray = Array(repeating: "", count: full - 5)

        stats.makeAchievementArraysConsistent()

        XCTAssertEqual(stats.achievementsUnlockedArray.count, full)
        XCTAssertEqual(stats.achievementDates.count, full)
        XCTAssertEqual(stats.achievementsPercentageCompleteArray.count, full)
    }

    func testWhatWasAlreadyThereIsKept() {
        // Padding must not disturb the entries a player has actually earned.
        let stats = TotalStats()
        let full = stats.achievementsUnlockedArray.count
        stats.achievementsUnlockedArray = Array(repeating: false, count: full - 3)
        stats.achievementsUnlockedArray[0] = true
        stats.achievementsUnlockedArray[7] = true

        stats.makeAchievementArraysConsistent()

        XCTAssertTrue(stats.achievementsUnlockedArray[0])
        XCTAssertTrue(stats.achievementsUnlockedArray[7])
        XCTAssertFalse(stats.achievementsUnlockedArray[full - 1])
    }

    func testAFileFromANewerBuildIsLeftAlone() {
        // Longer means it was written by a version that knows about more achievements than
        // this one. Trimming it to fit would throw that player's progress away.
        let stats = TotalStats()
        let full = stats.achievementsUnlockedArray.count
        stats.achievementsUnlockedArray = Array(repeating: true, count: full + 4)

        stats.makeAchievementArraysConsistent()

        XCTAssertEqual(stats.achievementsUnlockedArray.count, full + 4)
    }

    func testEveryAchievementIndexTheGameUsesIsInRange() {
        // The padding is only worth having if it reaches as far as the code does.
        let stats = TotalStats()
        stats.achievementsUnlockedArray = []
        stats.achievementDates = []
        stats.makeAchievementArraysConsistent()

        let highestIndexUsed = 65
        XCTAssertGreaterThan(stats.achievementsUnlockedArray.count, highestIndexUsed)
        XCTAssertGreaterThan(stats.achievementDates.count, highestIndexUsed)
    }

    func testPaddingAnEmptyArrayGivesTheFullDefaults() {
        let stats = TotalStats()
        let expected = stats.achievementsUnlockedArray
        stats.achievementsUnlockedArray = []
        stats.makeAchievementArraysConsistent()
        XCTAssertEqual(stats.achievementsUnlockedArray, expected)
    }
}
