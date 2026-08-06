//
//  BallBounceTests.swift
//  GigaBallTests
//
//  Two bounces that have been wrong for a long time, and are geometry rather than physics -
//  which is what makes them testable without running a scene.
//
//  The seam: every brick is its own rectangle, so a row of them has joins in it, and a ball
//  arriving on a join is resolved against two bodies at once. It leaves off what is
//  geometrically a corner rather than off the flat face the player can see.
//
//  The wall: the game has always kept the ball away from travelling horizontally, because a
//  horizontal ball never comes back. Nothing was doing the same at the other end, so a ball
//  arriving at a side wall almost vertically left almost vertically, hit it again a few frames
//  later, and ran up the screen in a stack of tiny bounces.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class BallBounceTests: XCTestCase {

    private func makeScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameWidth = 360
        scene.brickWidth = 40
        scene.brickHeight = 20
        return scene
    }

    /// Two bricks side by side, as a row of them is.
    private let pair = CGRect(x: -40, y: 100, width: 80, height: 20)

    // MARK: - The seam

    func testABallArrivingFromAboveLeavesFlat() {
        // The whole point: a pair of bricks is one surface, and a ball dropping onto the join
        // between them should go back up, not off sideways
        let scene = makeScene()
        let before = BallState(position: CGPoint(x: 0, y: 140),
                               velocity: CGVector(dx: 30, dy: -200))

        XCTAssertEqual(scene.seamFace(from: before, over: pair), .top)
    }

    func testABallArrivingFromBelowLeavesFlat() {
        let scene = makeScene()
        let before = BallState(position: CGPoint(x: 5, y: 60),
                               velocity: CGVector(dx: -20, dy: 220))

        XCTAssertEqual(scene.seamFace(from: before, over: pair), .bottom)
    }

    func testABallArrivingFromTheSideStillHitsTheSide() {
        // A row also has ends, and the correction must not turn a genuine side-on hit into a
        // bounce off the top
        let scene = makeScene()
        let before = BallState(position: CGPoint(x: -90, y: 108),
                               velocity: CGVector(dx: 240, dy: 10))

        XCTAssertEqual(scene.seamFace(from: before, over: pair), .left)
    }

    func testACornerGoesToTheFaceTheBallActuallyArrivedAt() {
        // Off the corner of the whole surface, where the ball was outside on both axes.
        //
        // The face is the one it reached *last*, which is the opposite of what it looks like
        // it should be: crossing the line a face sits on is not the same as arriving at the
        // face. Both of these were checked by walking the ball forward by hand.
        let scene = makeScene()

        // Away to the left and only just above, closing flat. It passes the height of the row
        // while still well to the side, and meets it at the end
        let alongside = BallState(position: CGPoint(x: -100, y: 130),
                                  velocity: CGVector(dx: 300, dy: -100))
        XCTAssertEqual(scene.seamFace(from: alongside, over: pair), .left)

        // Just past the end and well above, dropping steeply. It passes the end of the row
        // while still above it, and comes down onto the top
        let overhead = BallState(position: CGPoint(x: -50, y: 200),
                                 velocity: CGVector(dx: 100, dy: -400))
        XCTAssertEqual(scene.seamFace(from: overhead, over: pair), .top)
    }

    func testAStationaryBallHasNoFace() {
        // Nothing to reflect, and no direction to work one out from
        let scene = makeScene()
        let still = BallState(position: CGPoint(x: 0, y: 140), velocity: .zero)
        XCTAssertNil(scene.seamFace(from: still, over: pair))
    }

    func testTheSurfaceIsTheBricksTakenTogether() {
        // Two frames become one rectangle, which is what "as if it were one long brick" means
        let left = CGRect(x: -40, y: 100, width: 40, height: 20)
        let right = CGRect(x: 0, y: 100, width: 40, height: 20)
        XCTAssertEqual(left.union(right), pair)
    }

    // MARK: - The wall

    func testABallLeavingAWallIsTurnedAwayFromVertical() {
        // The bug: a ball arriving almost vertically leaves almost vertically, and is back in
        // the wall a few frames later at the same angle
        let scene = makeScene()
        let grazing = scene.pushedOffTheWall(dx: 2, dy: 300)

        let angleFromVertical = abs(atan2(Double(grazing.dx), Double(grazing.dy))*180/Double.pi)
        XCTAssertGreaterThanOrEqual(angleFromVertical, GameScene.minWallAngleDeg - 0.001)
    }

    func testTheSpeedIsExactlyPreserved() {
        // The one thing the physics rules cannot have changed. Opening the angle out must not
        // make the ball faster or slower
        let scene = makeScene()

        for (dx, dy) in [(CGFloat(2), CGFloat(300)), (-1, -420), (0, 260), (5, -180)] {
            let before = sqrt(dx*dx + dy*dy)
            let after = scene.pushedOffTheWall(dx: dx, dy: dy)
            XCTAssertEqual(sqrt(after.dx*after.dx + after.dy*after.dy), before, accuracy: 0.001,
                           "\(dx),\(dy)")
        }
    }

    func testItKeepsTheDirectionTheBallWasGoing() {
        // Away from the wall it just left, and on up or on down as it was
        let scene = makeScene()

        let rising = scene.pushedOffTheWall(dx: 1, dy: 300)
        XCTAssertGreaterThan(rising.dx, 0)
        XCTAssertGreaterThan(rising.dy, 0)

        let falling = scene.pushedOffTheWall(dx: -1, dy: -300)
        XCTAssertLessThan(falling.dx, 0)
        XCTAssertLessThan(falling.dy, 0)
    }

    func testAnOrdinaryBounceIsLeftAlone() {
        // Only the grazing ones are touched. A bounce that already leaves at a sensible angle
        // must come back exactly as it went in
        let scene = makeScene()
        let ordinary = scene.pushedOffTheWall(dx: 200, dy: 200)

        XCTAssertEqual(ordinary.dx, 200, accuracy: 0.001)
        XCTAssertEqual(ordinary.dy, 200, accuracy: 0.001)
    }

    func testAPerfectlyVerticalBallIsGivenSomewhereToGo() {
        // Exactly vertical is the worst case, and the one that sticks
        let scene = makeScene()
        let vertical = scene.pushedOffTheWall(dx: 0, dy: 300)

        XCTAssertGreaterThan(abs(vertical.dx), 0)
        XCTAssertEqual(sqrt(vertical.dx*vertical.dx + vertical.dy*vertical.dy), 300,
                       accuracy: 0.001)
    }

    func testAStationaryBallIsNotInvented() {
        let scene = makeScene()
        let still = scene.pushedOffTheWall(dx: 0, dy: 0)
        XCTAssertEqual(still.dx, 0)
        XCTAssertEqual(still.dy, 0)
    }
}
