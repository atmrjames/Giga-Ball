//
//  BallPathTests.swift
//  GigaBallTests
//
//  A prediction the player aims with. A line that says "you will hit that brick" and does not
//  is worse than no line at all, so the arithmetic is pinned down here rather than judged by
//  looking at it.
//

import XCTest
import CoreGraphics
@testable import Giga_Ball

final class BallPathTests: XCTestCase {

    /// A field 200 wide and 400 tall, with the paddle line at the bottom.
    private let bounds = BallPath.Bounds(left: -100, right: 100, ceiling: 200, paddleLine: -200)
    private let radius: CGFloat = 5

    private func predict(from start: CGPoint, _ velocity: CGVector,
                         bricks: [CGRect] = [], length: CGFloat = 0) -> BallPath.Prediction {
        BallPath.predict(from: start, velocity: velocity, radius: radius,
                         bounds: bounds, bricks: bricks, maximumLength: length)
    }

    // MARK: - The line itself

    func testABallGoingStraightDownLandsBelowItself() {
        let path = predict(from: CGPoint(x: 30, y: 100), CGVector(dx: 0, dy: -100))

        XCTAssertEqual(path.points.count, 2)
        XCTAssertEqual(path.landing?.x, 30)
        XCTAssertEqual(path.landing?.y, bounds.paddleLine + radius)
        XCTAssertFalse(path.stoppedAtBrick)
    }

    func testABallGoingUpLandsAfterTheCeilingTurnsIt() {
        // Up is not "never coming down": off the ceiling and straight back to the paddle
        // line, which is exactly what the real ball does
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 100))
        XCTAssertNotNil(path.landing)
    }

    func testABallGoingUpUnderABrickNeverReachesThePaddle() {
        let above = CGRect(x: -10, y: 100, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 100), bricks: [above])
        XCTAssertNil(path.landing)
        XCTAssertTrue(path.stoppedAtBrick)
    }

    func testAStationaryBallGoesNowhere() {
        let path = predict(from: CGPoint(x: 0, y: 0), .zero)
        XCTAssertEqual(path.points, [CGPoint(x: 0, y: 0)])
        XCTAssertNil(path.landing)
    }

    func testTheLineTurnsAtTheSideWall() {
        // Down and to the right at 45 degrees, from the middle
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -1))

        XCTAssertEqual(path.points.count, 3, "start, wall, paddle")
        XCTAssertEqual(path.points[1].x, bounds.right - radius, accuracy: 0.001)
        XCTAssertEqual(path.points[1].y, -(bounds.right - radius), accuracy: 0.001)
        XCTAssertNotNil(path.landing)
        XCTAssertLessThan(path.landing!.x, path.points[1].x, "it should be coming back left")
    }

    func testTheLineTurnsAtTheCeiling() {
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 1))

        XCTAssertEqual(path.points[1].y, bounds.ceiling - radius, accuracy: 0.001)
        XCTAssertNotNil(path.landing, "up, off the ceiling, and back down to the paddle")
    }

    func testTheBallIsMeasuredBySurfaceRatherThanCentre() {
        // Its centre stops a radius short of the wall, because that is where it touches
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -0.001))
        XCTAssertEqual(path.points[1].x, bounds.right - radius, accuracy: 0.001)
    }

    // MARK: - Bricks

    func testTheLineStopsAtTheFirstBrickItWouldMeet() {
        let near = CGRect(x: -10, y: 100, width: 20, height: 10)
        let far = CGRect(x: -10, y: 150, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 1),
                           bricks: [far, near])

        XCTAssertTrue(path.stoppedAtBrick)
        XCTAssertEqual(path.points.last!.y, near.minY - radius, accuracy: 0.001)
        XCTAssertNil(path.landing)
    }

    func testABrickBesideThePathDoesNotStopIt() {
        let beside = CGRect(x: 40, y: 100, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 1), bricks: [beside])
        XCTAssertFalse(path.stoppedAtBrick)
    }

    func testABrickBehindTheBallDoesNotStopIt() {
        // Behind and to the left, with the ball heading right - not straight behind a
        // vertical ball, which meets it again honestly on the way back off the ceiling
        let behind = CGRect(x: -60, y: -10, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -1), bricks: [behind])
        XCTAssertFalse(path.stoppedAtBrick)
    }

    func testAVerticalBallMeetsABrickBelowItOnTheWayBackDown() {
        // The case the test above must not accidentally forbid: up, off the ceiling, and
        // straight back down into it. That brick is genuinely in the path
        let below = CGRect(x: -10, y: -100, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: 1), bricks: [below])
        XCTAssertTrue(path.stoppedAtBrick)
    }

    func testTheBrickTheBallIsTouchingIsIgnored() {
        // Otherwise the path stops where it starts, every time the ball is against something.
        // Heading down and away, so the path cannot honestly meet this brick again
        let touching = CGRect(x: -10, y: -4, width: 20, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -1), bricks: [touching])
        XCTAssertFalse(path.stoppedAtBrick)
        XCTAssertNotNil(path.landing, "it left the brick behind and played on")
    }

    func testABrickIsMetABallsWidthEarlyOnItsSide() {
        // Approaching a brick from the side, the ball touches it a radius before its face
        let brick = CGRect(x: 40, y: -10, width: 20, height: 20)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: 0), bricks: [brick])

        XCTAssertTrue(path.stoppedAtBrick)
        XCTAssertEqual(path.points.last!.x, brick.minX - radius, accuracy: 0.001)
    }

    func testABrickFoundAfterABounceStillStopsTheLine() {
        // Down and right, off the wall, into a brick on the way back
        let brick = CGRect(x: -20, y: -160, width: 40, height: 10)
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -1), bricks: [brick])

        XCTAssertTrue(path.stoppedAtBrick)
        XCTAssertNil(path.landing, "it never reaches the paddle line")
    }

    // MARK: - Length

    func testALimitedLineStopsWhereItIsToldTo() {
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: -1), length: 50)

        XCTAssertEqual(path.points.count, 2)
        XCTAssertEqual(path.points[1].y, -50, accuracy: 0.001)
        XCTAssertNil(path.landing, "it was cut short of the paddle")
    }

    func testALimitedLineStillTurnsAtAWallItReachesFirst() {
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: 0), length: 200)

        XCTAssertEqual(path.points.count, 3, "start, wall, and the end of its length")
        XCTAssertEqual(path.points[1].x, bounds.right - radius, accuracy: 0.001)
    }

    func testAnUnlimitedLineIsTheDefault() {
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 0, dy: -1))
        XCTAssertNotNil(path.landing)
    }

    // MARK: - Not running away

    func testAShallowBallDoesNotDrawForEver() {
        // A nearly-horizontal ball bounces from wall to wall many times in very little height,
        // and every bounce is a place the scene's own angle rules may nudge the real ball -
        // so the prediction stops being one long before it stops being possible to draw
        let path = predict(from: CGPoint(x: 0, y: 0), CGVector(dx: 1, dy: -0.001))
        XCTAssertLessThanOrEqual(path.points.count, BallPath.maximumBounces + 2)
    }

    func testEveryPathStartsAtTheBall() {
        for velocity in [CGVector(dx: 1, dy: 1), CGVector(dx: -3, dy: -1),
                         CGVector(dx: 0, dy: -1), CGVector(dx: 2, dy: 0)] {
            let start = CGPoint(x: 12, y: -30)
            XCTAssertEqual(predict(from: start, velocity).points.first, start)
        }
    }

    // MARK: - Bouncing off bricks

    /// The Landing Marker's question is unchanged: it stops at the first brick, because a
    /// landing worked out through two bounces would be a confident claim about where to stand.
    func testTheDefaultStillStopsAtTheFirstBrick() {
        let brick = CGRect(x: -10, y: 40, width: 20, height: 10)
        let path = BallPath.predict(from: .zero, velocity: CGVector(dx: 0, dy: 1), radius: 1,
                                    bounds: wideBounds(), bricks: [brick])
        XCTAssertTrue(path.stoppedAtBrick)
        XCTAssertEqual(path.points.count, 2, "start and the brick")
    }

    /// With a budget it turns instead, off the face it actually meets. Straight up into a
    /// brick's underside comes straight back down.
    func testABrickBounceReversesTheFaceItMeets() {
        let brick = CGRect(x: -10, y: 40, width: 20, height: 10)
        let path = BallPath.predict(from: .zero, velocity: CGVector(dx: 0, dy: 1), radius: 1,
                                    bounds: wideBounds(), bricks: [brick], brickBounces: 2)
        XCTAssertFalse(path.stoppedAtBrick, "it had a bounce left")
        XCTAssertGreaterThan(path.points.count, 2)

        let turn = path.points[1]
        let after = path.points[2]
        XCTAssertLessThan(after.y, turn.y, "a bounce off the underside sends it back down")
    }

    /// The budget is a budget. Given more bricks than bounces, it stops at the one it cannot
    /// afford - which is what keeps a long line from becoming a guess (play-test round 39).
    func testItStopsOnceTheBounceBudgetIsSpent() {
        let low = CGRect(x: -10, y: 40, width: 20, height: 10)
        let high = CGRect(x: -10, y: -40, width: 20, height: 10)
        let path = BallPath.predict(from: .zero, velocity: CGVector(dx: 0, dy: 1), radius: 1,
                                    bounds: wideBounds(), bricks: [low, high], brickBounces: 1)
        XCTAssertTrue(path.stoppedAtBrick,
                      "one bounce spent on the first brick, stopped at the second")
    }

    private func wideBounds() -> BallPath.Bounds {
        BallPath.Bounds(left: -500, right: 500, ceiling: 500, paddleLine: -500)
    }
}
