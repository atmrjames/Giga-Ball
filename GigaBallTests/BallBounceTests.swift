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
// MARK: - The paddle's own bounce

/// The angle the paddle returns a ball at, which is the most characteristic number in the
/// game - and which was written out three times until round 147 put it in one place.
final class PaddleBounceTests: XCTestCase {

    private let arrivingSteeply = CGVector(dx: 60, dy: -300)

    func testTheMiddleOfThePaddleReturnsTheAngleItArrivedAt() {
        // Nothing to bend: the spot is the middle, so the paddle behaves as a wall does
        let straight = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: 0,
                                                 adjustmentK: 45, influence: 1,
                                                 minimumDeg: 10)
        let arrivedAt = atan2(300.0, 60.0)*180/Double.pi
        XCTAssertEqual(straight, arrivedAt, accuracy: 0.001)
    }

    func testTheSidesOfThePaddleBendItTowardThatSide() {
        // Right of the middle sends the ball right, which is a smaller angle
        let right = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: 0.5,
                                              adjustmentK: 45, influence: 1, minimumDeg: 10)
        let left = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: -0.5,
                                             adjustmentK: 45, influence: 1, minimumDeg: 10)
        XCTAssertLessThan(right, left)
        XCTAssertEqual(left - right, 45, accuracy: 0.001, "half the paddle, half the bend")
    }

    func testItNeverReturnsABallFlatterThanTheMinimum() {
        // Without this the edges return a ball that runs along the field sideways for
        // seconds at a time
        for collision in stride(from: -1.0, through: 1.0, by: 0.1) {
            let angle = PaddleBounce.angleDegrees(arriving: CGVector(dx: 400, dy: -20),
                                                  collision: collision, adjustmentK: 45,
                                                  influence: 1, minimumDeg: 10)
            XCTAssertGreaterThanOrEqual(angle, 10, "\(collision)")
            XCTAssertLessThanOrEqual(angle, 170, "\(collision)")
        }
    }

    func testItAlwaysSendsTheBallUpwards() {
        // The vertical component is taken as an absolute: the paddle's top face is the only
        // one that bounces, so the answer always travels up
        for dy in [-300.0, 300.0] {
            let velocity = PaddleBounce.velocity(arriving: CGVector(dx: 100, dy: dy),
                                                 collision: 0.3, adjustmentK: 45,
                                                 influence: 1, minimumDeg: 10, speed: 500)
            XCTAssertGreaterThan(velocity.dy, 0, "arriving dy \(dy)")
            XCTAssertEqual(hypot(velocity.dx, velocity.dy), 500, accuracy: 0.001)
        }
    }

    func testAnInertPaddleStopsTheSpotMatteringAndAFlippedOneInvertsIt() {
        let plain = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: 0.6,
                                              adjustmentK: 45, influence: 1, minimumDeg: 10)
        let inert = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: 0.6,
                                              adjustmentK: 45, influence: 0, minimumDeg: 10)
        let flipped = PaddleBounce.angleDegrees(arriving: arrivingSteeply, collision: 0.6,
                                                adjustmentK: 45, influence: -1, minimumDeg: 10)
        let arrivedAt = atan2(300.0, 60.0)*180/Double.pi
        XCTAssertEqual(inert, arrivedAt, accuracy: 0.001, "the spot stops mattering")
        XCTAssertEqual((plain + flipped)/2, arrivedAt, accuracy: 0.001,
                       "flipped bends by the same amount the other way")
    }

    func testWhereOnThePaddleIsMeasuredFromItsMiddle() {
        XCTAssertEqual(PaddleBounce.collision(ballX: 100, paddleX: 100, paddleWidth: 80), 0)
        XCTAssertEqual(PaddleBounce.collision(ballX: 140, paddleX: 100, paddleWidth: 80), 1,
                       accuracy: 0.001)
        XCTAssertEqual(PaddleBounce.collision(ballX: 60, paddleX: 100, paddleWidth: 80), -1,
                       accuracy: 0.001)
        XCTAssertGreaterThan(PaddleBounce.collision(ballX: 200, paddleX: 100, paddleWidth: 80), 1,
                            "past the end is not clamped - the caller decides what that means")
    }

    func testThePracticeFieldBouncesTheWayTheGameDoes() {
        // Round 147: the practice field's paddle was a plain elastic body, so it mirrored the
        // ball back rather than bending the bounce by where it landed - which is a wall, not
        // a paddle. Same formula, same numbers, so the screen answers the question it asks
        let scene = PaddleSpeedScene(size: CGSize(width: 390, height: 400))
        scene.layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)

        scene.placeForTesting(ballX: 195, paddleX: 195,
                              arriving: CGVector(dx: 40, dy: -300))
        guard let middle = scene.paddleBounceVelocity() else {
            return XCTFail("a ball on the paddle's middle is a bounce")
        }
        XCTAssertGreaterThan(middle.dy, 0, "it always comes back up")

        scene.placeForTesting(ballX: 195 + 30, paddleX: 195,
                              arriving: CGVector(dx: 40, dy: -300))
        guard let toTheRight = scene.paddleBounceVelocity() else {
            return XCTFail("still on the face")
        }
        XCTAssertGreaterThan(toTheRight.dx, middle.dx,
                             "landing right of the middle sends it right, as in the game")
    }

    func testThePracticeFieldLeavesAnEdgeHitToThePhysics() {
        // Past the paddle's end is not a face bounce, and the game does not bend those either
        let scene = PaddleSpeedScene(size: CGSize(width: 390, height: 400))
        scene.layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)
        scene.placeForTesting(ballX: 390, paddleX: 100, arriving: CGVector(dx: 40, dy: -300))
        XCTAssertNil(scene.paddleBounceVelocity())
    }

    func testThePracticeFieldLeavesTheThumbTheRoomTheGameDoes() {
        // Round 147: the paddle-speed screen put the paddle a kill-line's clearance above the
        // field's floor - 36 points - where the game leaves nearly 200
        let layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)
        XCTAssertGreaterThan(layout.paddleCentreAboveScreenBottom, 150)
        XCTAssertLessThan(layout.paddleCentreAboveScreenBottom, layout.screen.height/3)
    }
}
