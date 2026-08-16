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
