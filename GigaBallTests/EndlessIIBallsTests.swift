//
//  EndlessIIBallsTests.swift
//  GigaBallTests
//
//  The rule phase 7 exists for: the run continues while at least one ball is in play, and the
//  life is lost when the last one goes. It is one line of arithmetic and it decides whether a
//  run ends, so it is worth being able to see.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIBallsTests: XCTestCase {

    func testLosingOneOfSeveralCostsNothing() {
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 4), .carryOn)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 3), .carryOn)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 2), .carryOn)
    }

    func testLosingTheLastOneEndsTheLife() {
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 1), .lifeLost)
    }

    func testASingleBallBehavesExactlyAsItAlwaysHas() {
        // Classic and Endless never have more than one, so this is the only answer they can
        // ever get - which is what keeps them untouched by any of this
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 1), .lifeLost)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 0), .lifeLost)
    }

    func testFourIsTheCeiling() {
        XCTAssertTrue(EndlessIIBalls.canAdd(inPlay: 1))
        XCTAssertTrue(EndlessIIBalls.canAdd(inPlay: 3))
        XCTAssertFalse(EndlessIIBalls.canAdd(inPlay: 4))
        XCTAssertFalse(EndlessIIBalls.canAdd(inPlay: 5))
    }

    // MARK: - Launching

    // "For new multi-balls they should appear out of the paddle at a random angle close to
    // vertical - maybe 25deg each side." The offset is injectable, so the fan's edges are
    // pinned here while the game rolls inside them.

    func testANewBallKeepsTheRunsSpeed() {
        // Ball speed is one shared value across every ball in play, so a ball added during a
        // Slow Ball arrives slow rather than at whatever it was created with
        for offset in [-1.0, -0.3, 0, 0.5, 1.0] {
            let launched = EndlessIIBalls.paddleLaunchVelocity(speed: 200, offset: offset)
            XCTAssertEqual(hypot(launched.dx, launched.dy), 200, accuracy: 0.001)
        }
    }

    func testTheMiddleOfTheFanIsStraightUp() {
        let launched = EndlessIIBalls.paddleLaunchVelocity(speed: 200, offset: 0)
        XCTAssertEqual(launched.dx, 0, accuracy: 0.001)
        XCTAssertEqual(launched.dy, 200, accuracy: 0.001)
    }

    func testTheFanIsTwentyFiveDegreesEachSide() {
        for offset in [-1.0, 1.0] {
            let launched = EndlessIIBalls.paddleLaunchVelocity(speed: 100, offset: offset)
            let offVertical = abs(atan2(launched.dy, launched.dx) - .pi/2)*180/Double.pi
            XCTAssertEqual(Double(offVertical), EndlessIIBalls.launchSpreadDegrees,
                           accuracy: 0.001)
            XCTAssertGreaterThan(launched.dy, 0, "always climbing into the field")
        }
    }

    func testAnOffsetPastTheFanIsClamped() {
        // The offset is rolled, but the roll must not be able to point along the paddle
        let wild = EndlessIIBalls.paddleLaunchVelocity(speed: 100, offset: 40)
        let edge = EndlessIIBalls.paddleLaunchVelocity(speed: 100, offset: 1)
        XCTAssertEqual(wild.dx, edge.dx, accuracy: 0.001)
        XCTAssertEqual(wild.dy, edge.dy, accuracy: 0.001)
    }

    // MARK: - In the scene

    func testTheSceneReportsOneBallUntilOneIsAdded() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        XCTAssertEqual(scene.endlessIIBallsInPlay.count, 1)
        XCTAssertTrue(scene.endlessIICanAddBall)
    }

    func testOtherModesNeverAddABall() {
        // Classic and Endless keep a single ball. Nothing here is allowed to reach them
        for mode in [GameMode.classic, .endless] {
            let scene = GameScene()
            scene.gameMode = mode
            XCTAssertFalse(scene.endlessIICanAddBall, "\(mode)")
            XCTAssertFalse(scene.endlessIIAddBall(), "\(mode)")
            XCTAssertEqual(scene.endlessIIBallsInPlay.count, 1, "\(mode)")
        }
    }

    func testLosingABallInAnotherModeStillEndsTheLife() {
        // The early return in ballLostAnimation must never fire outside Endless 2.0
        let scene = GameScene()
        scene.gameMode = .classic
        XCTAssertFalse(scene.endlessIIBallWasLost(scene.ball))
    }

    // MARK: - Losing the first ball

    private func sceneWithExtras(_ positions: [CGPoint]) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        scene.totalStatsArray = [TotalStats()]
        // Losing a ball counts one, and a scene built by hand has no stats behind it
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(scene.ball)
        for point in positions {
            let extra = SKSpriteNode()
            extra.name = BallCategoryName
            extra.position = point
            extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
            extra.physicsBody?.velocity = CGVector(dx: 50, dy: 120)
            scene.addChild(extra)
            scene.endlessIIExtraBalls.append(extra)
        }
        return scene
    }

    func testTheHandoverWaitsForTheStepToFinish() {
        // "One ball fell below the paddle, the other ball disappeared and the first one got
        // stuck at the bottom of the screen under the paddle." A position written inside a
        // contact is undone by the rest of the step (§8.6), so the handover was thrown away
        // while the survivor was removed anyway
        let scene = sceneWithExtras([CGPoint(x: 30, y: 300)])
        scene.ball.position = CGPoint(x: 0, y: -500)

        XCTAssertTrue(scene.endlessIIBallWasLost(scene.ball))
        XCTAssertEqual(scene.ball.position, CGPoint(x: 0, y: -500), "moved during the contact")
        XCTAssertEqual(scene.endlessIIExtraBalls.count, 1, "the survivor left before it handed over")

        scene.applyEndlessIIBallHandover()
        XCTAssertEqual(scene.ball.position, CGPoint(x: 30, y: 300))
        XCTAssertEqual(scene.ball.physicsBody?.velocity.dy, 120)
        XCTAssertTrue(scene.endlessIIExtraBalls.isEmpty, "the survivor should be gone now")
    }

    func testTheHandoverTakesTheHighestSurvivor() {
        // Two balls reaching the bottom together: handing the first ball the position of one
        // that is itself about to be lost puts it straight back on the floor
        let scene = sceneWithExtras([CGPoint(x: 0, y: -480), CGPoint(x: 60, y: 240)])
        scene.ball.position = CGPoint(x: 0, y: -500)

        XCTAssertTrue(scene.endlessIIBallWasLost(scene.ball))
        scene.applyEndlessIIBallHandover()
        XCTAssertEqual(scene.ball.position.y, 240)
    }

    func testNothingIsHandedOverTwice() {
        let scene = sceneWithExtras([CGPoint(x: 30, y: 300)])
        XCTAssertTrue(scene.endlessIIBallWasLost(scene.ball))
        scene.applyEndlessIIBallHandover()

        let landed = scene.ball.position
        scene.applyEndlessIIBallHandover()
        XCTAssertEqual(scene.ball.position, landed)
    }

    // MARK: - Saving

    func testABallIsWrittenAsFourValues() {
        let flat = EndlessIIBalls.flattened([
            .init(position: CGPoint(x: 1, y: 2), velocity: CGVector(dx: 3, dy: 4)),
        ])
        XCTAssertEqual(flat, [1, 2, 3, 4])
    }

    func testEveryBallComesBackAsItWentIn() {
        let balls: [EndlessIIBalls.Saved] = [
            .init(position: CGPoint(x: -12.5, y: 340), velocity: CGVector(dx: 200, dy: -180)),
            .init(position: CGPoint(x: 88, y: -4), velocity: CGVector(dx: -60, dy: 60)),
            .init(position: CGPoint(x: 0, y: 0), velocity: CGVector(dx: 0, dy: 0)),
        ]
        XCTAssertEqual(EndlessIIBalls.unflattened(EndlessIIBalls.flattened(balls)), balls)
    }

    func testNothingSavedRestoresNothing() {
        XCTAssertTrue(EndlessIIBalls.unflattened(nil).isEmpty)
        XCTAssertTrue(EndlessIIBalls.unflattened([]).isEmpty)
        XCTAssertTrue(EndlessIIBalls.flattened([]).isEmpty)
    }

    func testAHalfWrittenBallIsDropped() {
        // A save is a file on disk that a bad write may have left in any state, and this is
        // read at launch. Reading past the end there is a crash on opening the app
        let one: [Double] = [1, 2, 3, 4]
        for trailing in 1...3 {
            let ragged = one + Array(repeating: 9.0, count: trailing)
            XCTAssertEqual(EndlessIIBalls.unflattened(ragged).count, 1, "\(trailing) extra")
        }
    }

    func testNoMoreBallsComeBackThanTheModeAllows() {
        // The first ball is not in here, so the most there can be is one short of the maximum.
        // A save claiming more came from somewhere that was not this game
        let many = (0..<10).map { index in
            EndlessIIBalls.Saved(position: CGPoint(x: CGFloat(index), y: 0),
                                 velocity: CGVector(dx: 1, dy: 1))
        }
        XCTAssertEqual(EndlessIIBalls.flattened(many).count,
                       (EndlessIIBalls.maximum - 1)*EndlessIIBalls.savedPropertiesCount)
        XCTAssertEqual(EndlessIIBalls.unflattened(Array(repeating: 1.0, count: 40)).count,
                       EndlessIIBalls.maximum - 1)
    }

    func testAFullFieldOfBallsSurvivesAPause() {
        // The case the format exists for: four balls in play when the pause menu opens
        let balls = (0..<(EndlessIIBalls.maximum - 1)).map { index in
            EndlessIIBalls.Saved(position: CGPoint(x: CGFloat(index)*10, y: 100),
                                 velocity: CGVector(dx: CGFloat(index) - 1, dy: 300))
        }
        let restored = EndlessIIBalls.unflattened(EndlessIIBalls.flattened(balls))
        XCTAssertEqual(restored, balls)
        XCTAssertEqual(restored.count + 1, EndlessIIBalls.maximum)
    }

    // MARK: - A loss reported twice

    /// **Endless Mayhem has one life.** A run that carries on after its last ball is the
    /// worst kind of bug in this mode: it invalidates the height, and the height is the score.
    ///
    /// The primary ball's handover is deferred to `didSimulatePhysics`, because a position
    /// written inside a contact does not stick (§8.6). In the window between the contact and
    /// the handover, the ball is still at the bottom and the survivor is still in the extras
    /// list - so a second contact reported against the same ball found two balls in play and
    /// read it as another carry-on. Two losses counted, one handover done, and the run
    /// continued with a ball it should not have had (play-test round 39).
    func testTheSameBallCannotBeLostTwiceWhileItsHandoverIsPending() {
        let scene = GameScene()
        scene.gameMode = .endlessII

        let survivor = SKSpriteNode()
        scene.endlessIIExtraBalls = [survivor]
        scene.endlessIIPendingHandover = survivor
        // The state the deferred handover leaves behind for one step

        XCTAssertTrue(scene.endlessIIBallWasLost(scene.ball),
                      "a repeat report is not a second loss")
        XCTAssertEqual(scene.totalStatsArray.first?.ballsLost ?? 0, 0,
                       "and it costs no ball")
    }

    /// The guard is narrow on purpose: with no handover pending, losing the primary ball is a
    /// real loss and must be handled.
    func testAPrimaryBallLossWithNoHandoverPendingIsStillALoss() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        XCTAssertNil(scene.endlessIIPendingHandover)
        XCTAssertFalse(scene.endlessIIBallWasLost(scene.ball),
                       "the last ball ends the run")
    }
}
