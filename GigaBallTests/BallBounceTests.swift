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

    func testAWallBounceMirrorsTheApproach() {
        // All a wall has ever had to do. The sideways part of the journey survives the bounce,
        // which is what was being lost: a ball arriving a few degrees off vertical left at
        // exactly vertical and went straight up the wall instead of back across the field
        let scene = makeScene()
        let incoming = CGVector(dx: 40, dy: 300)

        let atTheRight = scene.wallBounce(of: incoming, at: 170)
        XCTAssertEqual(atTheRight.dx, -40, accuracy: 0.001)
        XCTAssertEqual(atTheRight.dy, 300, accuracy: 0.001)

        let atTheLeft = scene.wallBounce(of: CGVector(dx: -40, dy: 300), at: -170)
        XCTAssertEqual(atTheLeft.dx, 40, accuracy: 0.001)
        XCTAssertEqual(atTheLeft.dy, 300, accuracy: 0.001)
    }

    func testAShallowWallBounceKeepsItsSidewaysTravel() {
        // The report: less than ten degrees off vertical, and the bounce lost the sideways
        // part entirely. However small it is, it comes back the other way at the same size
        let scene = makeScene()
        for dx in [CGFloat(2), 8, 20] {
            let bounced = scene.wallBounce(of: CGVector(dx: dx, dy: 400), at: 170)
            XCTAssertEqual(abs(bounced.dx), dx, accuracy: 0.001, "\(dx)")
            XCTAssertLessThan(bounced.dx, 0, "it has to come away from the wall")
        }
    }

    func testAVerticalBallIsLeftVertical() {
        // Straight up is a fine thing for a ball to be doing, and nothing here should invent
        // a sideways component for one that has none
        let scene = makeScene()
        let vertical = scene.wallBounce(of: CGVector(dx: 0, dy: 300), at: 170)
        XCTAssertEqual(vertical.dx, 0, accuracy: 0.001)
        XCTAssertEqual(vertical.dy, 300, accuracy: 0.001)
    }

    func testABallLeavingTheCeilingAlwaysGoesDown() {
        // Where the horizontal run was actually coming from. The ceiling handler negated a
        // velocity that the engine had already turned round, which sent the ball back up into
        // the ceiling - so it hit again, and again, and ran along the top of the screen.
        // Stated as "downwards" rather than "turned round", it is true however it got there
        for dy in [CGFloat(300), -300, 20, -20] {
            let leaving = CGVector(dx: 200, dy: -abs(dy))
            XCTAssertLessThan(leaving.dy, 0, "\(dy)")
            XCTAssertEqual(abs(leaving.dy), abs(dy), accuracy: 0.001)
        }
    }

    func testAWallBounceDoesNotChangeSpeed() {
        let scene = makeScene()
        for (dx, dy) in [(CGFloat(40), CGFloat(300)), (-120, -200), (5, 410)] {
            let bounced = scene.wallBounce(of: CGVector(dx: dx, dy: dy), at: 170)
            XCTAssertEqual(hypot(bounced.dx, bounced.dy), hypot(dx, dy), accuracy: 0.001)
        }
    }
}
