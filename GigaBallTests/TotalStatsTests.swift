//
//  TotalStatsTests.swift
//  GigaBallTests
//
//  TotalStats is the persisted stats model, encoded with PropertyListEncoder
//  into Documents/totalStatsStore.plist and mirrored key-by-key into iCloud.
//  Its arrays are indexed in parallel with LevelPackSetup's, so the two have
//  to agree in length or stats land against the wrong level, power-up or
//  achievement. It is also the one part of the persistence layer that already
//  uses Codable, so the round-trip is worth pinning before the save-game
//  format is moved onto the same footing.
//

import XCTest
@testable import Giga_Ball

final class TotalStatsTests: XCTestCase {

    // MARK: - Codable round-trip

    func testRoundTripsThroughPropertyListCoder() throws {
        let original = TotalStats()
        original.cumulativeScore = 123_456
        original.levelsCompleted = 42
        original.playTimeSecs = 9_999
        original.endlessModeHeight = [10, 250, 3_000]
        original.endlessModeHeightDate = [
            Date(timeIntervalSinceReferenceDate: 0),
            Date(timeIntervalSinceReferenceDate: 1_000),
            Date(timeIntervalSinceReferenceDate: 2_000)
        ]
        original.levelUnlockedArray[5] = true
        original.themeUnlockedArray[3] = true

        let data = try PropertyListEncoder().encode(original)
        let decoded = try PropertyListDecoder().decode(TotalStats.self, from: data)

        XCTAssertEqual(decoded.cumulativeScore, 123_456)
        XCTAssertEqual(decoded.levelsCompleted, 42)
        XCTAssertEqual(decoded.playTimeSecs, 9_999)
        XCTAssertEqual(decoded.endlessModeHeight, [10, 250, 3_000])
        XCTAssertEqual(decoded.endlessModeHeightDate.count, 3)
        XCTAssertTrue(decoded.levelUnlockedArray[5])
        XCTAssertTrue(decoded.themeUnlockedArray[3])
    }

    func testEndlessHistoryArraysStayInStep() throws {
        // endlessModeHeight and endlessModeHeightDate are parallel arrays, one
        // entry per session. The planned session-history screen reads them by
        // index, so they have to survive encoding at equal length.
        let stats = TotalStats()
        for i in 0..<25 {
            stats.endlessModeHeight.append(i * 17)
            stats.endlessModeHeightDate.append(Date(timeIntervalSinceReferenceDate: Double(i)))
        }

        let data = try PropertyListEncoder().encode(stats)
        let decoded = try PropertyListDecoder().decode(TotalStats.self, from: data)

        XCTAssertEqual(decoded.endlessModeHeight.count, decoded.endlessModeHeightDate.count)
        XCTAssertEqual(decoded.endlessModeHeight.count, 25)
    }

    func testDecodingRejectsGarbageRatherThanReturningPartialStats() {
        // The save-game path force-casts and crashes on corruption. TotalStats
        // should throw instead, so a corrupt stats file can be recovered from.
        let garbage = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        XCTAssertThrowsError(try PropertyListDecoder().decode(TotalStats.self, from: garbage))
    }

    // MARK: - Defaults

    func testFreshStatsStartEmpty() {
        let stats = TotalStats()
        XCTAssertEqual(stats.cumulativeScore, 0)
        XCTAssertEqual(stats.levelsPlayed, 0)
        XCTAssertEqual(stats.levelsCompleted, 0)
        XCTAssertEqual(stats.packsCompleted, 0)
        XCTAssertEqual(stats.ballsLost, 0)
        XCTAssertTrue(stats.endlessModeHeight.isEmpty)
        XCTAssertTrue(stats.endlessModeHeightDate.isEmpty)
    }

    func testPerPackScoreArraysCoverElevenPacks() {
        let stats = TotalStats()
        XCTAssertEqual(stats.packHighScores.count, 11)
        XCTAssertEqual(stats.packBestTimes.count, 11)

        let perPackLevelScores = [
            stats.pack1LevelHighScores, stats.pack2LevelHighScores,
            stats.pack3LevelHighScores, stats.pack4LevelHighScores,
            stats.pack5LevelHighScores, stats.pack6LevelHighScores,
            stats.pack7LevelHighScores, stats.pack8LevelHighScores,
            stats.pack9LevelHighScores, stats.pack10LevelHighScores,
            stats.pack11LevelHighScores
        ]
        XCTAssertEqual(perPackLevelScores.count, 11)
        XCTAssertTrue(perPackLevelScores.allSatisfy { $0.count == 10 },
                      "Each pack tracks ten level scores")
    }

    // MARK: - Alignment with LevelPackSetup

    func testStatsArraysMatchLevelPackSetupLengths() {
        // The two models are indexed against each other throughout the app.
        // These are the pairings that a new pack, power-up or achievement would
        // silently break.
        let stats = TotalStats()
        let setup = LevelPackSetup()

        XCTAssertEqual(stats.levelPackUnlockedArray.count, setup.levelPackNameArray.count,
                       "Pack unlock flags must line up with pack names")
        XCTAssertEqual(stats.levelUnlockedArray.count, setup.levelNameArray.count,
                       "Level unlock flags must line up with level names")
        XCTAssertEqual(stats.powerUpUnlockedArray.count, setup.powerUpNameArray.count,
                       "Power-up unlock flags must line up with power-up names")
        XCTAssertEqual(stats.powerupsCollected.count, setup.powerUpNameArray.count)
        XCTAssertEqual(stats.powerupsGenerated.count, setup.powerUpNameArray.count)
        XCTAssertEqual(stats.themeUnlockedArray.count, setup.themeNameArray.count)
        XCTAssertEqual(stats.appIconUnlockedArray.count, setup.appIconNameArray.count)
        XCTAssertEqual(stats.achievementsUnlockedArray.count, setup.achievementsNameArray.count,
                       "Achievement flags must line up with achievement names")
        XCTAssertEqual(stats.achievementsPercentageCompleteArray.count,
                       stats.achievementsUnlockedArray.count)
        XCTAssertEqual(stats.achievementDates.count,
                       stats.achievementsUnlockedArray.count)
    }

    func testBrickCountersCoverEveryBrickType() {
        let stats = TotalStats()
        XCTAssertEqual(stats.bricksHit.count, stats.bricksDestroyed.count)
        XCTAssertEqual(stats.bricksHit.count, 8)
    }
}
