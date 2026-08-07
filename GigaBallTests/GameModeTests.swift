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
}
