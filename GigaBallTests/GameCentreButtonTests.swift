//
//  GameCentreButtonTests.swift
//  GigaBallTests
//
//  James, round 313: "The Game Center button on the game over / complete screen is in the top
//  right. Move it to the bottom right to line up with the other buttons, using the small
//  right-side button position and style."
//
//  It was a loose disc added over the container and pinned to `homeButton.centerYAnchor` -
//  and `homeButton` is hidden on that screen, left wherever the storyboard puts it, which is
//  the top corner. So the button was mirrored across the *top* of the screen rather than
//  lining up with the row it belonged to.
//
//  The row's right-hand slot is the run's detail (play-test round 10) and was already the
//  leaderboard for a daily. A classic or endless ending had nothing to put there, which is
//  what left this door homeless.
//

import XCTest
import GameKit
@testable import Giga_Ball

final class GameCentreButtonTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    /// `isDailyChallenge` is get-only and reads the session, which is the shape this project
    /// has tripped over before - the day is a fact about the app, not about a screen.
    private func screen(sender: String, daily: Bool) -> PauseMenuViewController {
        DailyChallengeSession.shared.active = daily
            ? DailyChallenge(dateKey: "2026-10-08", mode: .endlessII,
                             classicLevel: nil, twists: [])
            : nil
        let screen = PauseMenuViewController()
        screen.sender = sender
        return screen
    }

    /// The pause screen's right-hand slot is Settings, and there is a run to go back to.
    func testItIsNotOfferedWhilePaused() {
        XCTAssertFalse(screen(sender: "Pause", daily: false).gameCentreIsOffered)
        XCTAssertFalse(screen(sender: "Pause", daily: true).gameCentreIsOffered)
    }

    /// A daily's own board takes the slot - the same door, aimed at today's leaderboard.
    func testADailysOwnBoardKeepsTheSlot() {
        let daily = screen(sender: "Game Over", daily: true)
        XCTAssertTrue(daily.dailyGameOver)
        XCTAssertFalse(daily.gameCentreIsOffered,
                       "the slot is already the daily's leaderboard, and two doors in one "
                       + "button is one door too many")
    }

    /// Both endings that had nothing in that slot are the ones this is for.
    func testItIsOfferedAtTheEndOfAnOrdinaryRun() {
        for ending in ["Game Over", "Complete"] {
            let screen = self.screen(sender: ending, daily: false)
            XCTAssertEqual(screen.gameCentreIsOffered,
                           GKLocalPlayerStub.isAuthenticated,
                           "\(ending): offered exactly when there is an account behind it")
        }
    }

    /// Signed out, there is nothing to show.
    ///
    /// The rule the loose button carried and this keeps: a button that opens an authentication
    /// sheet at the end of a run is a door nobody asked to be shown. It cannot be driven from a
    /// test - `GKLocalPlayer.local` is the system's - so what is pinned here is that the answer
    /// is *asked of it* rather than assumed.
    func testItIsAskedOfTheAccount() {
        let ending = screen(sender: "Game Over", daily: false)
        XCTAssertEqual(ending.gameCentreIsOffered, GKLocalPlayerStub.isAuthenticated)
    }
}

/// What the simulator's Game Center answers, named so the expectation reads as a fact about
/// the machine rather than a guess.
enum GKLocalPlayerStub {
    static var isAuthenticated: Bool { GKLocalPlayer.local.isAuthenticated }
}
