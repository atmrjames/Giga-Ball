//
//  GameModeTests.swift
//  GigaBallTests
//
//  The mode's job is to answer the questions that used to be asked of level numbers. The
//  ones worth pinning are the separations - a mistake here leaks Endless 2.0's content
//  into a mode people have years of scores in, which is the one thing the design says
//  must not happen.
//

import XCTest
@testable import Giga_Ball

final class GameModeTests: XCTestCase {

    func testTheFourModes() {
        XCTAssertEqual(GameMode.allCases.count, 4)
        XCTAssertEqual(GameMode.classic.name, "Classic Mode")
        XCTAssertEqual(GameMode.endless.name, "Endless Mode")
        XCTAssertEqual(GameMode.endlessII.name, "Endless Mayhem")
        XCTAssertEqual(GameMode.daily.name, "Daily Challenge")
        // The daily is a menu identity, not a scene one - the scene always plays one of
        // the other three, and DailyChallengeSession is how it knows
    }

    func testRawValuesAreStableBecauseTheyArePersisted() {
        // Stored in defaults so a resumed run knows what it is. Renumbering these would
        // silently reinterpret somebody's saved game as a different mode.
        XCTAssertEqual(GameMode.classic.rawValue, 0)
        XCTAssertEqual(GameMode.endless.rawValue, 1)
        XCTAssertEqual(GameMode.endlessII.rawValue, 2)
    }

    func testBothEndlessModesDescendAndScoreByHeight() {
        XCTAssertTrue(GameMode.endless.isEndless)
        XCTAssertTrue(GameMode.endlessII.isEndless)
        XCTAssertFalse(GameMode.classic.isEndless)
    }

    // MARK: - Separation

    func testOnlyEndlessIIOffersTheNewPowerUps() {
        XCTAssertEqual(GameMode.classic.powerUpAvailability, .allModes)
        XCTAssertEqual(GameMode.endless.powerUpAvailability, .allModes)
        XCTAssertEqual(GameMode.endlessII.powerUpAvailability, .endlessII)
    }

    func testTheModesThatMustNotChangeSeeOnlyTheExistingPowerUps() {
        for mode in [GameMode.classic, .endless] {
            let offered = PowerUpCatalogue.available(in: mode.powerUpAvailability)
            XCTAssertEqual(offered.count, PowerUpCatalogue.existing.count, mode.name)
            XCTAssertTrue(offered.allSatisfy { $0.availability == .allModes }, mode.name)
        }
    }

    func testEndlessIIDoesNotPostToTheOriginalEndlessLeaderboards() {
        // Years of scores on the original board, and a mode with different bricks and
        // different power-ups is not comparable to them.
        XCTAssertTrue(GameMode.endless.sharesLeaderboardsWithEndless)
        XCTAssertFalse(GameMode.endlessII.sharesLeaderboardsWithEndless)
        XCTAssertFalse(GameMode.classic.sharesLeaderboardsWithEndless)
    }

    // MARK: - The board a finished run stands on (§12.0, global rank on the game-over screen)

    func testEachEndlessModeStandsOnItsOwnHeightBoard() {
        // The game-over line must never quote one endless mode's placing at the other's
        // player - the same separation the submission side keeps.
        XCTAssertEqual(GameMode.endless.runLeaderboard(packNumber: 1)?.id,
                       GameMode.endlessBestHeightLeaderboard)
        XCTAssertEqual(GameMode.endlessII.runLeaderboard(packNumber: 1)?.id,
                       GameMode.endlessIIBestHeightLeaderboard)
        XCTAssertNotEqual(GameMode.endless.runLeaderboard(packNumber: 1)?.id,
                          GameMode.endlessII.runLeaderboard(packNumber: 1)?.id)
    }

    func testAnEndlessRunNamesItsOwnMode() {
        XCTAssertEqual(GameMode.endless.runLeaderboard(packNumber: 1)?.name, "Endless Mode")
        XCTAssertEqual(GameMode.endlessII.runLeaderboard(packNumber: 1)?.name,
                       "Endless Mayhem")
    }

    func testAClassicRunStandsOnItsPacksBoardAndIsNamedForThePack() {
        // packNumber is an index into levelPackNameArray, so the Classic Pack is 2 - the
        // offset that had been written two different ways in two files.
        let classic = GameMode.classic.runLeaderboard(packNumber: 2)
        XCTAssertEqual(classic?.id, "leaderboardClassicPackScore")
        XCTAssertEqual(classic?.name, "Classic Pack")

        let last = GameMode.classic.runLeaderboard(
            packNumber: LevelPackSetup.firstPackNumber
                + LevelPackSetup.packScoreLeaderboards.count - 1)
        XCTAssertEqual(last?.id, "leaderboardChallengePackScore")
        XCTAssertEqual(last?.name, "Challenge Pack")
    }

    func testThePackBoardsLineUpWithThePacksAndWithPackHighScores() {
        // The save loop walks `packScoreLeaderboards` against `packHighScores`, and the
        // game-over line looks the same list up by packNumber. Three arrays that have to
        // agree, and nothing but this notices when they stop.
        XCTAssertEqual(LevelPackSetup.packScoreLeaderboards.count,
                       TotalStats().packHighScores.count)
        XCTAssertEqual(LevelPackSetup().levelPackNameArray.count,
                       LevelPackSetup.firstPackNumber
                        + LevelPackSetup.packScoreLeaderboards.count)
        for (index, board) in LevelPackSetup.packScoreLeaderboards.enumerated() {
            XCTAssertEqual(
                LevelPackSetup.packScoreLeaderboard(
                    forPack: index + LevelPackSetup.firstPackNumber),
                board)
        }
    }

    func testTheTutorialAndEndlessSlotsHoldNoPackBoard() {
        // They occupy the first two slots of levelPackNameArray and have no pack total,
        // so a lookup there must come back empty rather than off by two.
        XCTAssertNil(LevelPackSetup.packScoreLeaderboard(forPack: 0))
        XCTAssertNil(LevelPackSetup.packScoreLeaderboard(forPack: 1))
        XCTAssertNil(LevelPackSetup.packScoreLeaderboard(forPack: 99))
        XCTAssertNil(LevelPackSetup.packScoreLeaderboard(forPack: -1))
        XCTAssertNil(GameMode.classic.runLeaderboard(packNumber: 0))
    }

    func testTheDailyIsNotAskedThisWay() {
        // It has its own board and its own loader, and the game-over screen asks
        // DailyChallengeSession whether the run posted before asking anything at all.
        XCTAssertNil(GameMode.daily.runLeaderboard(packNumber: 2))
    }
}
