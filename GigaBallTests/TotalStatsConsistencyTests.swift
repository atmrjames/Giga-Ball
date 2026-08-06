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

        stats.makeStoredArraysConsistent()

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

        stats.makeStoredArraysConsistent()

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

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.achievementsUnlockedArray.count, full + 4)
    }

    func testEveryAchievementIndexTheGameUsesIsInRange() {
        // The padding is only worth having if it reaches as far as the code does.
        let stats = TotalStats()
        stats.achievementsUnlockedArray = []
        stats.achievementDates = []
        stats.makeStoredArraysConsistent()

        let highestIndexUsed = 65
        XCTAssertGreaterThan(stats.achievementsUnlockedArray.count, highestIndexUsed)
        XCTAssertGreaterThan(stats.achievementDates.count, highestIndexUsed)
    }

    func testPaddingAnEmptyArrayGivesTheFullDefaults() {
        let stats = TotalStats()
        let expected = stats.achievementsUnlockedArray
        stats.achievementsUnlockedArray = []
        stats.makeStoredArraysConsistent()
        XCTAssertEqual(stats.achievementsUnlockedArray, expected)
    }
}

// MARK: - Power-ups

extension TotalStatsConsistencyTests {

    /// A stats file from before a power-up existed, which is what every current player has.
    private func aged(by missing: Int) -> TotalStats {
        var stats = TotalStats()
        stats.powerupsCollected.removeLast(missing)
        stats.powerupsGenerated.removeLast(missing)
        stats.powerUpUnlockedArray.removeLast(missing)
        return stats
    }

    func testAnOlderStatsFileIsBroughtUpToLength() {
        // The one that would take the app down: these arrays are indexed by power-up, and a
        // file written before Endless 2.0's power-ups existed is shorter than the arrays this
        // build reads. The first read past the end is a crash, on the device of somebody who
        // has been playing for years
        var stats = aged(by: 5)
        let fresh = TotalStats()

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected.count, fresh.powerupsCollected.count)
        XCTAssertEqual(stats.powerupsGenerated.count, fresh.powerupsGenerated.count)
        XCTAssertEqual(stats.powerUpUnlockedArray.count, fresh.powerUpUnlockedArray.count)
    }

    func testWhatThePlayerAlreadyDidIsUntouched() {
        // Padding must only ever add. Rewriting the entries that were there would throw away
        // years of somebody's collection counts to make room for a power-up they have not met
        var stats = aged(by: 3)
        stats.powerupsCollected[0] = 412
        stats.powerupsGenerated[0] = 900
        stats.powerUpUnlockedArray[1] = false

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected[0], 412)
        XCTAssertEqual(stats.powerupsGenerated[0], 900)
        XCTAssertFalse(stats.powerUpUnlockedArray[1])
    }

    func testAPowerUpNobodyHasMetStartsAtNothing() {
        var stats = aged(by: 2)
        let known = stats.powerupsCollected.count

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected[known], 0)
        XCTAssertEqual(stats.powerupsGenerated[known], 0)
    }

    func testAFileFromANewerBuildKeepsItsExtras() {
        // Only ever lengthens. A file with more entries than this build knows about was
        // written by a newer version, and truncating it would lose that player's progress the
        // moment they opened an older build
        var stats = TotalStats()
        stats.powerupsCollected.append(77)
        stats.powerupsGenerated.append(88)

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected.last, 77)
        XCTAssertEqual(stats.powerupsGenerated.last, 88)
    }

    func testTheStoredArraysAllAgreeOnTheirLength() {
        // Three arrays indexed by the same number. One of them being shorter is the same crash
        // in a different place
        var stats = aged(by: 4)
        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected.count, stats.powerupsGenerated.count)
        XCTAssertEqual(stats.powerupsCollected.count, stats.powerUpUnlockedArray.count)
    }

    func testAnEmptyFileIsFilledRatherThanLeftEmpty() {
        var stats = TotalStats()
        stats.powerupsCollected = []
        stats.powerupsGenerated = []
        stats.powerUpUnlockedArray = []

        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected.count, TotalStats().powerupsCollected.count)
        XCTAssertEqual(stats.powerUpUnlockedArray.count, TotalStats().powerUpUnlockedArray.count)
    }
}
