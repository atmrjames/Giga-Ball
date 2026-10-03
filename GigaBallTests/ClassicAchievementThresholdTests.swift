//
//  ClassicAchievementThresholdTests.swift
//  GigaBallTests
//
//  Every threshold in Classic's end-of-level achievement check, at its line and just under it
//  (round 364).
//
//  `InbetweenLevels.achievementsCheck` was the riskiest function in the app by the CRAP measure
//  - complexity 128, its award branches never run under a test - and it awards achievements
//  players have been earning since 2020. Each case is the achievement's own sentence: the
//  points, the balls, the power-ups, the counts and the clock it names. Writing them found
//  Serial Dodger reading the last level's power-ups rather than the pack's.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ClassicAchievementThresholdTests: XCTestCase {

    /// A Classic level just finished, mid-pack, with nothing earned yet.
    private func ending(_ configure: (GameScene) -> Void = { _ in }) -> GameScene {
        DailyChallengeSession.shared.active = nil
        let scene = GameScene()
        scene.gameMode = .classic
        scene.endlessMode = false
        scene.totalStatsArray = [TotalStats()]
        scene.packNumber = 2
        scene.levelNumber = 3
        scene.endLevelNumber = 10
        scene.numberOfLevels = 10
        scene.gameoverStatus = false
        scene.levelTimerValue = 120
        scene.packTimerValue = 1_200
        scene.deathsPerLevel = 1
        scene.deathsPerPack = 1
        scene.powerUpsGeneratedPerLevel = 2
        scene.powerUpsCollectedPerLevel = 1
        configure(scene)
        InbetweenLevels(scene: scene).achievementsCheck()
        return scene
    }

    private func earned(_ index: Int, _ configure: @escaping (GameScene) -> Void) -> Bool {
        ending(configure).totalStatsArray[0].achievementsUnlockedArray[index]
    }

    /// The last level of a pack, finished.
    private func packEnd(_ scene: GameScene) {
        scene.levelNumber = scene.endLevelNumber
    }

    func testPointsOnASingleLevel() {
        // "Collect 5,000 points on a single level" and 10,000: the level's score and its bonus
        XCTAssertTrue(earned(43) { $0.levelScore = 4_500; $0.levelTimerBonus = 500 })
        XCTAssertFalse(earned(43) { $0.levelScore = 4_499; $0.levelTimerBonus = 500 })
        XCTAssertTrue(earned(44) { $0.levelScore = 10_000 })
        XCTAssertFalse(earned(44) { $0.levelScore = 9_999 })
    }

    func testTotalPoints() {
        // "Earn 100,000 / 500,000 / 1,000,000 total points", and a share short of it
        for (index, target) in [(51, 100_000), (52, 500_000), (53, 1_000_000)] {
            XCTAssertTrue(earned(index) { $0.totalStatsArray[0].cumulativeScore = target },
                          "\(index)")
            let short = ending { $0.totalStatsArray[0].cumulativeScore = target/4 }
            XCTAssertFalse(short.totalStatsArray[0].achievementsUnlockedArray[index])
            XCTAssertEqual(short.totalStatsArray[0].achievementsPercentageCompleteArray[index],
                           "25.0%", "\(index): a quarter of the way")
        }
    }

    func testBallsLostOnALevel() {
        // "Complete level without losing ball" and "losing 3 or more balls"
        XCTAssertTrue(earned(36) { $0.deathsPerLevel = 0 })
        XCTAssertFalse(earned(36) { $0.deathsPerLevel = 1 })
        XCTAssertTrue(earned(37) { $0.deathsPerLevel = 3 })
        XCTAssertFalse(earned(37) { $0.deathsPerLevel = 2 })
    }

    func testPowerUpsOnALevel() {
        // "Collect all power-ups on a level" (five at least) and "Collect no power-ups on a level"
        XCTAssertTrue(earned(38) { $0.powerUpsGeneratedPerLevel = 5; $0.powerUpsCollectedPerLevel = 5 })
        XCTAssertFalse(earned(38) { $0.powerUpsGeneratedPerLevel = 6; $0.powerUpsCollectedPerLevel = 5 })
        XCTAssertFalse(earned(38) { $0.powerUpsGeneratedPerLevel = 4; $0.powerUpsCollectedPerLevel = 4 })
        XCTAssertTrue(earned(39) { $0.powerUpsGeneratedPerLevel = 5; $0.powerUpsCollectedPerLevel = 0 })
        XCTAssertFalse(earned(39) { $0.powerUpsGeneratedPerLevel = 5; $0.powerUpsCollectedPerLevel = 1 })
        XCTAssertFalse(earned(39) { $0.powerUpsGeneratedPerLevel = 4; $0.powerUpsCollectedPerLevel = 0 })
    }

    func testLevelsCompleted() {
        // "Complete first level", then 10, 100, 1,000 and 10,000
        XCTAssertTrue(earned(45) { $0.totalStatsArray[0].levelsCompleted = 1 })
        for (index, target) in [(46, 10), (47, 100), (48, 1_000), (49, 10_000)] {
            XCTAssertTrue(earned(index) { $0.totalStatsArray[0].levelsCompleted = target },
                          "\(index)")
            XCTAssertFalse(earned(index) { $0.totalStatsArray[0].levelsCompleted = target - 1 },
                           "\(index)")
        }
    }

    func testAQuickLevel() {
        // "Complete level in under a minute"
        XCTAssertTrue(earned(40) { $0.levelTimerValue = 60 })
        XCTAssertFalse(earned(40) { $0.levelTimerValue = 61 })
    }

    func testPointsOnAPack() {
        // "Collect 10,000 / 25,000 / 50,000 points on a single pack" - at a pack's end only
        for (index, target) in [(59, 10_000), (60, 25_000), (61, 50_000)] {
            XCTAssertTrue(earned(index) { self.packEnd($0); $0.totalScore = target }, "\(index)")
            XCTAssertFalse(earned(index) { self.packEnd($0); $0.totalScore = target - 1 })
            XCTAssertFalse(earned(index) { $0.totalScore = target }, "\(index): mid-pack")
        }
    }

    func testBallsLostOnAPack() {
        // "Complete pack without losing ball" and "losing 10 or more balls"
        XCTAssertTrue(earned(54) { self.packEnd($0); $0.deathsPerPack = 0; $0.deathsPerLevel = 0 })
        XCTAssertTrue(earned(55) { self.packEnd($0); $0.deathsPerPack = 9; $0.deathsPerLevel = 1 })
        XCTAssertFalse(earned(55) { self.packEnd($0); $0.deathsPerPack = 8; $0.deathsPerLevel = 1 })
        // The last level's losses are folded into the pack's before the pack is asked
    }

    func testAllPowerUpsOnAPack() {
        // "Collect all power-ups on a pack"
        XCTAssertTrue(earned(56) {
            self.packEnd($0)
            $0.powerUpsGeneratedPerPack = 4; $0.powerUpsCollectedPerPack = 4
            $0.powerUpsGeneratedPerLevel = 2; $0.powerUpsCollectedPerLevel = 2
        })
    }

    /// "Collect no power-ups on a pack." It asked whether the *last level* had dropped five,
    /// beside the *pack's* collections, from 2020 until round 364 - so a pack that dropped
    /// twenty power-ups over its ten levels, none of them taken, earned nothing unless the
    /// last level alone had dropped five of them.
    func testNoPowerUpsOnAPackCountsThePacksDrops() {
        XCTAssertTrue(earned(57) {
            self.packEnd($0)
            $0.powerUpsGeneratedPerPack = 18; $0.powerUpsCollectedPerPack = 0
            $0.powerUpsGeneratedPerLevel = 2; $0.powerUpsCollectedPerLevel = 0
        }, "twenty dropped across the pack, none taken")
        XCTAssertFalse(earned(57) {
            self.packEnd($0)
            $0.powerUpsGeneratedPerPack = 18; $0.powerUpsCollectedPerPack = 0
            $0.powerUpsGeneratedPerLevel = 2; $0.powerUpsCollectedPerLevel = 1
        }, "one taken on the last level")
        XCTAssertFalse(earned(57) {
            self.packEnd($0)
            $0.powerUpsGeneratedPerPack = 2; $0.powerUpsCollectedPerPack = 0
            $0.powerUpsGeneratedPerLevel = 2; $0.powerUpsCollectedPerLevel = 0
        }, "four is not enough to have avoided anything")
    }

    func testAQuickPack() {
        // "Complete pack in under ten minutes"
        XCTAssertTrue(earned(58) { self.packEnd($0); $0.packTimerValue = 600 })
        XCTAssertFalse(earned(58) { self.packEnd($0); $0.packTimerValue = 601 })
    }

    /// A game over earns none of the level's own.
    func testAGameOverEarnsNoLevelAchievement() {
        let scene = ending { $0.gameoverStatus = true; $0.deathsPerLevel = 0; $0.levelTimerValue = 10 }
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[36])
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[40])
    }
}

extension ClassicAchievementThresholdTests {

    func testPacksCompleted() {
        // "Complete first pack" (any pack ending with a score), then 10, 100 and 1,000
        XCTAssertTrue(earned(62) { self.packEnd($0); $0.totalStatsArray[0].packHighScores[0] = 4_000 })
        for (index, target) in [(63, 10), (64, 100), (65, 1_000)] {
            XCTAssertTrue(earned(index) { self.packEnd($0); $0.totalStatsArray[0].packsCompleted = target },
                          "\(index)")
            XCTAssertFalse(earned(index) { self.packEnd($0); $0.totalStatsArray[0].packsCompleted = target - 1 },
                           "\(index)")
        }
    }
}

/// What a finished endless run leaves in the player's history (round 364).
///
/// `InbetweenLevels.saveGameData`'s endless half was never run under a test, and it is the line
/// every endless figure the game shows comes from: the Hi-Score height, the statistics page's
/// runs and averages, the best-so-far on the milestones, and the total-height achievements.
final class EndlessRunRecordTests: XCTestCase {

    private func runEnds(_ mode: GameMode, height: Int, seconds: Int = 60,
                         before: (TotalStats) -> Void = { _ in }) -> TotalStats {
        DailyChallengeSession.shared.active = nil
        let scene = GameScene()
        scene.gameMode = mode
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.packLevelHighScoresArray = Array(repeating: Array(repeating: 0, count: 10), count: 11)
        // What a running game loads from the stats; the ending writes it back whatever the mode
        before(scene.totalStatsArray[0])
        scene.endlessHeight = height
        scene.levelTimerValue = seconds
        let state = InbetweenLevels(scene: scene)
        state.saveGameData()
        state.achievementsCheck()
        return scene.totalStatsArray[0]
    }

    func testAnEndlessRunIsRecordedWithItsLength() {
        let stats = runEnds(.endless, height: 312, seconds: 245)
        XCTAssertEqual(stats.endlessModeHeight, [312])
        XCTAssertEqual(stats.endlessModeDurations, [245])
        XCTAssertEqual(stats.endlessModeHeightDate.count, 1)
        XCTAssertEqual(stats.endlessIIHeights, [], "the original mode's run is not Mayhem's")
    }

    func testAMayhemRunIsRecordedApart() {
        let stats = runEnds(.endlessII, height: 177, seconds: 120) {
            $0.endlessIIModeHeight = [50]
        }
        XCTAssertEqual(stats.endlessIIHeights, [50, 177])
        XCTAssertEqual(stats.endlessIIDurations, [120])
        XCTAssertEqual(stats.endlessModeHeight, [], "and Mayhem's is not the original's")
    }

    func testEndlessTotalHeight() {
        // "Reach 5,000m / 10,000m Total Height in Endless Mode", over every run
        let five = runEnds(.endless, height: 1_000) { $0.endlessModeHeight = [4_000] }
        XCTAssertTrue(five.achievementsUnlockedArray[4])
        XCTAssertFalse(five.achievementsUnlockedArray[5])
        XCTAssertEqual(five.achievementsPercentageCompleteArray[5], "50.0%")
        let short = runEnds(.endless, height: 999) { $0.endlessModeHeight = [4_000] }
        XCTAssertFalse(short.achievementsUnlockedArray[4])
    }

    func testMayhemTotalHeight() {
        // Mayhem's own pair counts Mayhem's runs, not the original mode's
        let mayhem = runEnds(.endlessII, height: 1_000) { $0.endlessIIModeHeight = [4_000] }
        XCTAssertTrue(mayhem.achievementsUnlockedArray[70])
        XCTAssertFalse(mayhem.achievementsUnlockedArray[71])
        let original = runEnds(.endless, height: 1_000) { $0.endlessModeHeight = [4_000] }
        XCTAssertFalse(original.achievementsUnlockedArray[70],
                       "five thousand metres of the original mode is not Mayhem's")
    }
}
