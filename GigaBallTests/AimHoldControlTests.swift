//
//  AimHoldControlTests.swift
//  GigaBallTests
//

import XCTest
import SpriteKit
import CoreGraphics
@testable import Giga_Ball

/// "With both running the player can aim *and* reposition. Letting go of the screen leaves
/// the ball on the paddle; the ball only launches on a tap. A swipe on or below the paddle
/// moves the paddle; a swipe above the paddle moves the aim arrow" (James, play-test round
/// 33, built round 155).
final class AimHoldControlTests: XCTestCase {

    private let paddleTop: CGFloat = -300

    func testASwipeAboveThePaddleAims() {
        XCTAssertEqual(AimHoldControl.intent(touchY: 0, paddleTopY: paddleTop), .aim)
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop + 1, paddleTopY: paddleTop), .aim,
                       "the whole field above the paddle is where a player looks when "
                       + "choosing where to shoot")
    }

    func testASwipeOnOrBelowThePaddleMovesThePaddle() {
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop, paddleTopY: paddleTop), .paddle,
                       "a thumb resting on the thing it is dragging should drag it")
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop - 200, paddleTopY: paddleTop),
                       .paddle, "and the thumb's usual home is below the paddle")
    }
    /// **The paddle may always be carried** (James, round 215: "drag below the paddle moves
    /// the paddle. Drag above the paddle moves the arrow relative to the drag").
    ///
    /// This replaces round 172's rule, which made the paddle immovable while aiming unless
    /// Sticky Paddle happened to be running too - two decisions on one finger being one too
    /// many, when the world stopped for the aim. The world does not stop any more, so a paddle
    /// that cannot be moved is a paddle that cannot answer a field still coming down.
    func testTheDragBelowCarriesThePaddleWhateverElseIsRunning() {
        for sticky in [true, false] {
            XCTAssertEqual(AimHoldControl.intent(touchY: -300, paddleTopY: -280,
                                                 paddleMayMove: sticky), .paddle,
                           "below the paddle carries it, sticky \(sticky)")
            XCTAssertEqual(AimHoldControl.intent(touchY: -200, paddleTopY: -280,
                                                 paddleMayMove: sticky), .aim,
                           "above the paddle aims, sticky \(sticky)")
        }
    }

    func testWithStickyPaddleTheHeightStillDecides() {
        XCTAssertEqual(AimHoldControl.intent(touchY: 0, paddleTopY: paddleTop,
                                             paddleMayMove: true), .aim)
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop - 200, paddleTopY: paddleTop,
                                             paddleMayMove: true), .paddle,
                       "that power-up's whole promise is that the ball comes with the paddle")
    }

    func testOnlyATapLaunches() {
        XCTAssertTrue(AimHoldControl.launches(travelled: 0))
        XCTAssertTrue(AimHoldControl.launches(travelled: AimHoldControl.tapSlop),
                      "fingers roll; a couple of points of roll is not a swipe")
        XCTAssertFalse(AimHoldControl.launches(travelled: AimHoldControl.tapSlop + 1))
    }

    func testAFingerThatWandersAndComesBackIsNotATap() {
        // The reason the scene accumulates distance travelled rather than measuring the
        // distance from where the touch began: an adjustment that ends where it started
        // would otherwise fire the shot the player was still lining up
        let outAndBack = 40 + 40 as CGFloat
        XCTAssertFalse(AimHoldControl.launches(travelled: outAndBack))
    }

    func testTheSlopIsSmallEnoughToBeAnAccidentAndNotAMove() {
        // A move the player meant is a move they can see. The paddle-speed multiplier goes
        // up to x3, so ten points of finger is up to thirty points of paddle - already
        // visible, and anything larger would let a real drag pass as a tap
        XCTAssertLessThanOrEqual(AimHoldControl.tapSlop, 12)
        XCTAssertGreaterThan(AimHoldControl.tapSlop, 0)
    }
}

/// What lifting the finger means while a ball is being aimed.
///
/// James, round 209: "Aimed sticky is broken. The ball isn't going where the arrow is aimed,
/// the game scene then gets stuck paused but the ball is moving, the ball can go below the
/// paddle and vibrate around."
///
/// One fall-through causes all three. The release rule answered a yes/no question - does this
/// tap fire? - and `touchesEnded` read "no" as "not mine", letting the touch reach the
/// ordinary paddle release. That launched the held ball at the angle for wherever it was
/// sitting on the paddle, ignoring the arrow, and returned without ending the freeze the catch
/// had put the world into: hence a moving ball in a stopped field, passing through a paddle
/// that was still held.
///
/// Reachable since round 172 stopped the aim drag carrying the paddle. Before that, dragging
/// moved the paddle and set `paddleMoved`, which the ordinary release checks - so the change
/// that made aiming feel right is the one that took the guard off the door.
final class AimReleaseTests: XCTestCase {

    func testATapWhileAimingFires() {
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true), .aimedLaunch)
        XCTAssertEqual(AimHoldControl.release(travelled: AimHoldControl.tapSlop, aiming: true),
                       .aimedLaunch)
    }

    /// The one that was missing: a release after an adjustment is not a launch **and is not
    /// somebody else's touch either**. It does nothing at all.
    func testAReleaseAfterAnAdjustmentDoesNothingRatherThanFallingThrough() {
        XCTAssertEqual(AimHoldControl.release(travelled: AimHoldControl.tapSlop + 1,
                                              aiming: true), .keepAiming)
        XCTAssertEqual(AimHoldControl.release(travelled: 400, aiming: true), .keepAiming)
    }

    func testWithNothingBeingAimedTheTouchBelongsToWhateverElseWantedIt() {
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: false), .notAiming)
        XCTAssertEqual(AimHoldControl.release(travelled: 400, aiming: false), .notAiming)
    }

    /// A drag out and back has still moved, so it is still an adjustment - the same reason
    /// `launches` measures total travel rather than the distance from where the touch began.
    func testAFingerThatGoesOutAndComesBackIsStillAnAdjustment() {
        XCTAssertEqual(AimHoldControl.release(travelled: 260, aiming: true), .keepAiming)
    }
}

/// What a freeze costs when a writer is left running through it.
///
/// James, round 210: "the game does get very jittery whilst this power-up is active."
///
/// `update`'s Mayhem branch stands its ticks down while a ball is being aimed, and pins their
/// last-tick clocks so nothing leaps the frozen seconds on release. `didSimulatePhysics` was
/// left running, and that is where every writer that *moves a ball* lives - gravity, steering,
/// magnetism, the spin. Writing `position` on a paused node still moves it (`isPaused` stops
/// actions and simulation, not property writes), so the held ball was being shoved about by
/// three effects while the aim tried to hold it still.
///
/// Gravity is the one that can be shown in arithmetic rather than by eye, because its pull
/// accumulates: this is what a two-second aim was quietly storing up behind a ball that
/// appeared to be standing still, all of it waiting to be spent the moment the shot left.
final class AimHoldFreezeTests: XCTestCase {

    func testTwoSecondsOfPullOnAStoppedBallIsAnAbsurdSpeed() {
        let speedLimit: CGFloat = 400
        var velocity = CGVector(dx: 0, dy: 0)
        for _ in 0..<120 {
            velocity = BallGravity.pulled(velocity, share: 1, delta: 1.0/60,
                                          speedLimit: speedLimit)
        }
        XCTAssertLessThan(velocity.dy, -speedLimit,
                          "a hold long enough to aim stored up more than the run's own speed")
    }

    /// And the band is what stops it being unbounded - which is also why the symptom was
    /// jitter and a lurch rather than the ball vanishing downward.
    func testTheBandKeepsEvenThatWithinReach() {
        let speedLimit: CGFloat = 400
        var velocity = CGVector(dx: 0, dy: 0)
        for _ in 0..<600 {
            velocity = BallGravity.pulled(velocity, share: 1, delta: 1.0/60,
                                          speedLimit: speedLimit)
        }
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        XCTAssertLessThanOrEqual(speed, speedLimit*BallGravity.fastestShare + 0.001)
    }
}

/// Where the arrow points, and which tap fires.
///
/// James, round 232: "aimed sticky arrow should move relative to touch and drag gesture. Its
/// angle should be limited so it can go to horizontal or below" and "a tap above the paddle
/// moves the arrow to the tap position. A tap below the paddle launches the ball."
final class AimedArrowPointsAtTheFingerTests: XCTestCase {

    private let minimum = 20*Double.pi/180

    private func degrees(_ radians: Double) -> Double { radians*180/Double.pi }

    /// The arrow points at the finger, which is both of his notes said once.
    func testItPointsWhereTheFingerIs() {
        let ball = CGPoint(x: 0, y: -300)

        let up = EndlessIIPaddleEffects.aimedAngle(at: CGPoint(x: 0, y: 100), from: ball,
                                                   minimum: minimum)
        XCTAssertEqual(degrees(up), 90, accuracy: 0.5, "straight above is straight up")

        let left = EndlessIIPaddleEffects.aimedAngle(at: CGPoint(x: -200, y: -100), from: ball,
                                                     minimum: minimum)
        let right = EndlessIIPaddleEffects.aimedAngle(at: CGPoint(x: 200, y: -100), from: ball,
                                                      minimum: minimum)
        XCTAssertGreaterThan(degrees(left), 90, "a finger to the left aims left")
        XCTAssertLessThan(degrees(right), 90, "a finger to the right aims right")
    }

    /// Never flat and never downward, however far under the ball the finger goes.
    func testItIsNeverFlatOrDownward() {
        let ball = CGPoint(x: 0, y: 0)
        for x in stride(from: -400.0, through: 400.0, by: 50) {
            for y in [-400.0, -50.0, 0.0] {
                let angle = EndlessIIPaddleEffects.aimedAngle(
                    at: CGPoint(x: x, y: y), from: ball, minimum: minimum)
                XCTAssertGreaterThanOrEqual(degrees(angle), degrees(minimum) - 0.001,
                                            "a shot at \(x), \(y) runs along the paddle line")
                XCTAssertLessThanOrEqual(degrees(angle), 180 - degrees(minimum) + 0.001)
            }
        }
    }

    /// A finger exactly on the ball is not a direction, and must not be read as one.
    func testAFingerOnTheBallAimsStraightUp() {
        let angle = EndlessIIPaddleEffects.aimedAngle(at: .zero, from: .zero, minimum: minimum)
        XCTAssertEqual(degrees(angle), 90, accuracy: 0.001)
    }

    // MARK: - Which tap fires

    /// A tap below the paddle launches; a tap above it does not.
    func testOnlyATapBelowThePaddleFires() {
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .paddle),
                       .aimedLaunch)
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .aim),
                       .keepAiming, "a tap above the paddle points the arrow, it does not fire")
    }

    /// A drag never fires, wherever it ends.
    func testADragNeverFires() {
        for intent in [AimHoldControl.Intent.aim, .paddle] {
            XCTAssertEqual(AimHoldControl.release(travelled: 200, aiming: true, intent: intent),
                           .keepAiming)
        }
    }

    /// And with no ball held, the release is nobody's business but the paddle's.
    func testWithNoBallHeldItIsNotAiming() {
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: false, intent: .paddle),
                       .notAiming)
    }

    /// A finger that was already down when the ball was caught cannot tap.
    ///
    /// James, play-test round 275: "if I let my finger go after the ball lands on the paddle,
    /// the ball releases. In this case, it should stay on the paddle. It should only release on
    /// a tap."
    ///
    /// The travel test cannot see this on its own. A player carrying the paddle when the ball
    /// arrives has been aiming for a fraction of a second by the time they lift, so they have
    /// travelled nothing *while aiming* - and the lift read as a tap and took the shot, on a
    /// gesture that was only ever a paddle move ending.
    func testALiftIsNotATapWhenTheFingerWasAlreadyDown() {
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .paddle,
                                              touchPredatesAim: true),
                       .keepAiming,
                       "the ball stays on the paddle")

        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .paddle,
                                              touchPredatesAim: false),
                       .aimedLaunch,
                       "and a tap that begins after the catch still fires")
    }

    /// Travelling still declines, whichever way the touch began.
    func testADragNeverLaunchesEitherWay() {
        for predates in [false, true] {
            XCTAssertEqual(AimHoldControl.release(travelled: 40, aiming: true, intent: .paddle,
                                                  touchPredatesAim: predates),
                           .keepAiming, "predates: \(predates)")
        }
    }
}

/// **An aim no longer pauses the field** (James, round 321: "Drift power up effect and rotating
/// bricks are pausing when aimed sticky is on and ball is on the paddle. Aimed sticky shouldn't
/// cause anything to pause anymore").
///
/// A spinning brick is the report's own example, and it is driven from the frame, so the question
/// is simply whether two frames apart during a hold it has turned.
final class AimHoldKeepsTheFieldMovingTests: XCTestCase {

    func testASpinningBrickKeepsTurningWhileABallIsAimed() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.gameWidth = 400

        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: 40, height: 20))
        brick.name = BrickCategoryName
        scene.addChild(brick)
        scene.applyEndlessIIStyle(.spinning, to: brick)

        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(scene.ball)
        scene.ballIsOnPaddle = true
        scene.gameState.enter(Playing.self)
        // Playing, because the field ticks only run in play, and a ball with a body, because the
        // play branch of `update` reads its velocity - the fixture `BallBounceTests` uses

        scene.endlessIIAimHold = true
        scene.update(100)
        let before = brick.zRotation
        scene.update(100.25)

        XCTAssertNotEqual(brick.zRotation, before, accuracy: 0.0001,
                          "a quarter of a second of aiming and the spinner should have turned")
    }
}

