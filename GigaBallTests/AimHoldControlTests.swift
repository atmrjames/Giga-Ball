//
//  AimHoldControlTests.swift
//  GigaBallTests
//

import XCTest
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

    /// James, round 172: "I think moving the paddle when aimed sticky is active is not good. It
    /// should just be the arrow angle. Unless sticky paddle is also active, then the paddle
    /// movement should be allowed too."
    ///
    /// So round 33's two-decision control is what *Sticky Paddle underneath* buys, not what
    /// Aimed Sticky gives on its own. The two tests above describe the paired case and pass
    /// unchanged, because carrying the paddle is still the default answer for the question
    /// "may it move" - it is the question that is new.
    func testWithoutStickyPaddleEveryDragIsTheAim() {
        for y in [CGFloat(0), paddleTop + 1, paddleTop, paddleTop - 200] {
            XCTAssertEqual(AimHoldControl.intent(touchY: y, paddleTopY: paddleTop,
                                                 paddleMayMove: false),
                           .aim, "at \(y): two decisions on one finger, and the aim is the "
                           + "one the power-up is for")
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
