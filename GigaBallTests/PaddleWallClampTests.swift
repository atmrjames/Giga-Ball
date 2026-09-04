//
//  PaddleWallClampTests.swift
//  GigaBallTests
//
//  **The wall clamp reaches all three modes, so all three are checked here** (round 302).
//
//  CLAUDE.md's rule: where a fix touches shared mechanics it applies to every mode, and
//  Classic and the original Endless deserve real scrutiny because those are the leaderboards
//  with years of scores on them. Round 300 rewrote the clamp and moved it to a different point
//  in the frame, and until now every test of it was written against Endless Mayhem - the one
//  mode whose leaderboards are new.
//
//  The clamp is deliberately mode-blind. `endlessIIPaddleHalfWidth` is `paddle.size.width/2`,
//  which is true everywhere, and `endlessIIWrapPaddleX` is a plain clamp unless Wrap-Around is
//  running, which needs `gameMode == .endlessII`. So Classic and Endless should behave exactly
//  as they always have, and *that* is the claim worth testing: not that the new code works, but
//  that the old modes cannot tell it changed.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class PaddleWallClampTests: XCTestCase {

    private func scene(_ mode: GameMode) -> GameScene {
        let scene = GameScene()
        scene.gameMode = mode
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    private let modes: [(String, GameMode)] = [
        ("Classic", .classic), ("Endless", .endless), ("Endless Mayhem", .endlessII)
    ]

    /// The wall holds in every mode, from either side, whether or not the paddle was already
    /// outside it.
    func testThePaddleStopsAtTheWallInEveryMode() {
        for (name, mode) in modes {
            let game = scene(mode)

            for (pushed, expected) in [(CGFloat(500), CGFloat(150)), (-500, -150),
                                       (150, 150), (-150, -150), (0, 0), (100, 100)] {
                game.paddle.position.x = pushed
                game.didEvaluateActions()
                XCTAssertEqual(game.paddle.position.x, expected, accuracy: 0.01,
                               "\(name): a paddle at \(pushed) should sit at \(expected)")
            }
        }
    }

    /// **A paddle that grows at the wall is pulled in, in every mode.**
    ///
    /// This is round 293's report and round 300's fix. Expand animates `xScale` over 0.2s and
    /// SpriteKit evaluates actions *after* `update`, so the correction has to run in
    /// `didEvaluateActions` or it answers for the paddle as it was a frame ago. Expand exists
    /// in all three modes, so the drift did too - it was only ever *reported* in Mayhem
    /// because that is where the laser turrets are drawn on the paddle's ends.
    func testAPaddleThatGrowsAtTheWallIsPulledInInEveryMode() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 150
            // Hard against the wall at 100 wide

            game.paddle.size = CGSize(width: 200, height: 20)
            // What the Expand action will have done by the time actions have been evaluated

            game.didEvaluateActions()
            XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01,
                           "\(name): the grown paddle's end should sit on the wall")
            for (what, node) in [("laser", game.paddleLaser), ("sticky", game.paddleSticky),
                                 ("retro", game.paddleRetroTexture),
                                 ("retro sticky", game.paddleRetroStickyTexture)] {
                XCTAssertEqual(node.position.x, game.paddle.position.x, accuracy: 0.01,
                               "\(name): the \(what) dress should have come with the paddle, "
                               + "not a frame later")
            }
            // **Every strip, not just the lasers** (James, round 305: "sticky paddle graphic,
            // like the laser turrets graphic, is also moving away from the paddle a pixel or
            // two when the paddle is dragged against the edge"). They all hang off
            // `positionPaddleOverlays` and `positionRetroPaddleLayers`, so round 300's move to
            // `didEvaluateActions` fixed the lot - but only the laser was being asserted, which
            // is how a report about the sticky can arrive after the laser is fixed and leave
            // nobody sure whether it is the same bug
        }
    }

    /// **Only Mayhem can leave the walls.**
    ///
    /// Wrap-Around is a Mayhem power-up, and `endlessIIWrapIsRunning` asks the mode as well as
    /// the clock. A collected wrap must not make Classic's or Endless's walls porous - those
    /// are the runs with years of scores behind them, and a paddle that could leave the screen
    /// would be a scoring change, not a visual one.
    func testACollectedWrapCannotOpenTheWallsInTheOldModes() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.endlessIICollectWrapAround()

            game.paddle.position.x = 210
            game.didEvaluateActions()

            if mode == .endlessII {
                XCTAssertEqual(game.paddle.position.x, -190, accuracy: 0.01,
                               "Mayhem: the paddle wraps to the far side")
            } else {
                XCTAssertEqual(game.paddle.position.x, 150, accuracy: 0.01,
                               "\(name): the walls are still walls whatever the clock says")
            }
        }
    }

    /// The clamp is idempotent, which is what makes it safe to run every frame.
    ///
    /// It runs on every frame of every mode now. A clamp that moved the paddle a little each
    /// time it was asked would drag it off the wall over a few seconds of standing still, and
    /// the symptom would be a paddle that creeps - which is exactly the class of bug round 293
    /// and round 300 were both chasing.
    func testRunningTheClampRepeatedlyChangesNothing() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 500
            game.didEvaluateActions()
            let settled = game.paddle.position.x

            for _ in 0..<600 { game.didEvaluateActions() }
            XCTAssertEqual(game.paddle.position.x, settled, accuracy: 0.0001,
                           "\(name): ten seconds of frames at the wall moved the paddle")
        }
    }
    /// **A ball waiting on the paddle has to go where the paddle goes.**
    ///
    /// The clamp moves the paddle on frames where no touch is happening - that is the whole
    /// point of it, since Expand grows a paddle standing still at the wall. But the resting
    /// ball is only re-placed inside `touchesMoved`, so a clamp that nudges the paddle without
    /// carrying the ball leaves the ball behind: it ends up off-centre on the paddle, or in the
    /// worst case beyond its end, and the serve goes somewhere the player did not aim.
    ///
    /// Every mode, because Expand and the waiting ball both exist in all three.
    func testAWaitingBallIsCarriedWhenTheClampMovesThePaddle() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 150
            game.ballIsOnPaddle = true
            game.ballRelativePositionOnPaddle = 20
            game.ball.position.x = game.paddle.position.x + 20

            game.paddle.size = CGSize(width: 200, height: 20)
            game.didEvaluateActions()

            XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01, "\(name): paddle clamped")
            XCTAssertEqual(game.ball.position.x - game.paddle.position.x, 20, accuracy: 0.01,
                           "\(name): the ball kept its place on the paddle rather than being "
                           + "left where the paddle used to be")
        }
    }

    /// **And the aim point rides the paddle too.**
    ///
    /// Round 275: "when moving the paddle the aim arrow can snap down to a low angle." The aim
    /// is kept as the point the finger last pointed at and the angle is measured from the ball
    /// to it, so a ball that walks out from under a stationary point swings the arrow - and
    /// once the ball is nearly level with the point, the angle flattens to the clamp. The touch
    /// handler carries the point by however far the paddle actually went; a clamp that moves
    /// the paddle for a different reason has to do the same, or a resize at the wall does
    /// exactly what dragging used to.
    func testTheAimPointRidesAClampedPaddle() {
        let game = scene(.endlessII)
        game.paddle.position.x = 150
        game.endlessIIAimHold = true
        game.endlessIIAimTouched = true
        game.endlessIIAimTouchX = 160

        game.paddle.size = CGSize(width: 200, height: 20)
        game.didEvaluateActions()

        XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01)
        XCTAssertEqual(game.endlessIIAimTouchX, 110, accuracy: 0.01,
                       "the aim point moved by the same 50 the paddle did, so the angle held")
    }

    /// A clamp that changes nothing must not drag the ball or the aim with it.
    ///
    /// The early return is what guarantees that, and it is worth a test of its own: the guard
    /// is the only thing standing between "runs every frame" and "writes to the ball every
    /// frame", and a later edit that moved work above it would be silent.
    func testAClampThatDoesNothingTouchesNothing() {
        let game = scene(.endlessII)
        game.paddle.position.x = 40
        game.ballIsOnPaddle = true
        game.ballRelativePositionOnPaddle = 20
        game.ball.position.x = 999
        // Somewhere the clamp would have to write over if it ran

        game.endlessIIAimHold = true
        game.endlessIIAimTouched = true
        game.endlessIIAimTouchX = 55

        game.didEvaluateActions()

        XCTAssertEqual(game.paddle.position.x, 40, accuracy: 0.01, "nothing to clamp")
        XCTAssertEqual(game.ball.position.x, 999, accuracy: 0.01,
                       "so the ball was not written to at all")
        XCTAssertEqual(game.endlessIIAimTouchX, 55, accuracy: 0.01, "nor the aim")
    }

}
