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

// MARK: - iCloud

final class CloudArrayLengthTests: XCTestCase {

    /// Every merge in `CloudKitHandler` walks one array's length while indexing the other, and
    /// the two come from different versions of the app - the local one from this build, the
    /// stored one from whichever version last wrote it.
    ///
    /// Adding the twenty-ninth power-up made the local array longer than the stored one, and
    /// the first launch after the update read one past the end of the stored array and crashed,
    /// on the device of somebody with years of synced progress. `TotalStats.padded` had covered
    /// exactly this hazard for the file on disk; the cloud copy was missed, because the file is
    /// the one that looks like a save.
    func testAShorterCloudArrayIsBroughtUpToLength() {
        let local = [true, false, true, false, true]
        let cloud = [true, false]

        let padded = CloudKitHandler.padded(cloud, toMatch: local)

        XCTAssertEqual(padded.count, local.count)
        XCTAssertEqual(Array(padded.prefix(2)), cloud, "what iCloud already knew is untouched")
        XCTAssertEqual(Array(padded.suffix(3)), Array(local.suffix(3)),
                       "and what it has never heard of takes this device's answer")
    }

    func testALongerCloudArrayIsLeftAlone() {
        // Written by a newer build. Truncating it would throw away progress the moment somebody
        // opened an older version on a second device
        let local = [1, 2]
        let cloud = [1, 2, 3, 4]

        XCTAssertEqual(CloudKitHandler.padded(cloud, toMatch: local), cloud)
    }

    func testEqualLengthsAreUnchanged() {
        let both = [0, 1, 2]
        XCTAssertEqual(CloudKitHandler.padded(both, toMatch: both), both)
    }

    func testAnEmptyCloudArrayBecomesTheLocalOne() {
        // What a device that has never synced looks like
        let local = [true, true, false]
        XCTAssertEqual(CloudKitHandler.padded([Bool](), toMatch: local), local)
    }

    func testNoMergeLoopWalksPastEitherArray() {
        // The guard rail rather than the fix: every loop in the file is bounded by the shorter
        // of the two arrays, so a length mismatch in either direction cannot crash. Read from
        // the source, because this is a rule about all of them and new ones keep being added
        let source = try! String(contentsOfFile: CloudArrayLengthTests.handlerPath,
                                 encoding: .utf8)
        let unbounded = source
            .split(separator: "\n")
            .map(String.init)
            .filter { $0.contains("for i in 0..<") && $0.contains("min(") == false }

        XCTAssertTrue(unbounded.isEmpty,
                      "these walk one array's length unchecked:\n" + unbounded.joined(separator: "\n"))
    }

    private static var handlerPath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Megaball/CloudKitHandler.swift")
            .path
    }
}
