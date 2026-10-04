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

    // MARK: - Shaped paddle faces

    // §12.0, James's idea from the fourth play test: convex, concave, wavy and jagged paddle
    // tops, all bad, each making the outgoing angle harder to predict.

    /// **The wedges are the exception, and they are the exception on purpose.**
    ///
    /// The rule was: odd, f(-x) = -f(x), so no shape favours a side - "a paddle with a bias is
    /// a paddle that is wrong rather than one that is tricky", which is why Jagged was rebuilt
    /// out of a triangle wave in the first place.
    ///
    /// James asked for Wedge Left and Wedge Right in round 213, and a wedge is *nothing but* a
    /// bias - a face tilted one way so the middle no longer returns the ball straight up. That
    /// is a deliberate change to the rule rather than a shape that slipped through it, so the
    /// wedges are named here rather than the check being weakened for everything.
    ///
    /// What still holds for them is the half that keeps a shaped face playable: the range. A
    /// wedge may not send the ball anywhere a flat paddle could not.
    func testEveryShapeIsEvenHandedAndStaysInRange() {
        let wedges: Set<PaddleBounce.Surface> = [.wedgeLeft, .wedgeRight]

        for surface in PaddleBounce.Surface.allCases where wedges.contains(surface) == false {
            for step in stride(from: 0.05, through: 1.0, by: 0.05) {
                let right = PaddleBounce.shaped(step, by: surface)
                let left = PaddleBounce.shaped(-step, by: surface)
                XCTAssertEqual(right, -left, accuracy: 0.0001, "\(surface) at \(step)")
                XCTAssertLessThanOrEqual(abs(right), 1.0001, "\(surface) at \(step)")
            }
            XCTAssertEqual(PaddleBounce.shaped(0, by: surface), 0, accuracy: 0.0001,
                           "\(surface): the middle is still the middle")
        }

        for surface in wedges {
            for step in stride(from: -1.0, through: 1.0, by: 0.05) {
                XCTAssertLessThanOrEqual(abs(PaddleBounce.shaped(step, by: surface)), 1.0001,
                                         "\(surface) at \(step)")
            }
        }
        XCTAssertEqual(PaddleBounce.shaped(0, by: .wedgeLeft),
                       -PaddleBounce.shaped(0, by: .wedgeRight), accuracy: 0.0001,
                       "the two wedges have to be each other's mirror, or one is the harder")
    }

    func testNoShapeMeansNoChange() {
        for step in stride(from: -1.0, through: 1.0, by: 0.25) {
            XCTAssertEqual(PaddleBounce.shaped(step, by: nil), step)
        }
    }

    func testConvexIsSteeperInTheMiddleAndConcaveIsFlatter() {
        // The two are opposites, which is the whole of why both exist
        let convex = PaddleBounce.shaped(0.2, by: .convex)
        let flat = 0.2
        let concave = PaddleBounce.shaped(0.2, by: .concave)
        XCTAssertGreaterThan(convex, flat, "a dome exaggerates a near-centre landing")
        XCTAssertLessThan(concave, flat, "a dish forgives one")
    }

    func testTheWavyAndJaggedFacesTurnBackOnThemselves() {
        // Both are unpredictable in the same way: further out is not always further round,
        // so two landings close together can send the ball opposite ways
        for surface in [PaddleBounce.Surface.wavy, .jagged] {
            var reversals = 0
            var previous = PaddleBounce.shaped(-1, by: surface)
            var rising = true
            for step in stride(from: -0.95, through: 1.0, by: 0.05) {
                let value = PaddleBounce.shaped(step, by: surface)
                let nowRising = value > previous
                if nowRising != rising { reversals += 1 }
                rising = nowRising
                previous = value
            }
            XCTAssertGreaterThan(reversals, 2, "\(surface) should turn back on itself")
        }
    }

    func testAShapedFaceStillCannotReturnABallFlatterThanTheMinimum() {
        for surface in PaddleBounce.Surface.allCases {
            for step in stride(from: -1.0, through: 1.0, by: 0.1) {
                let angle = PaddleBounce.angleDegrees(
                    arriving: CGVector(dx: 400, dy: -20),
                    collision: PaddleBounce.shaped(step, by: surface),
                    adjustmentK: 45, influence: 1, minimumDeg: 10)
                XCTAssertGreaterThanOrEqual(angle, 10, "\(surface) at \(step)")
                XCTAssertLessThanOrEqual(angle, 170, "\(surface) at \(step)")
            }
        }
    }

    func testAnInertPaddleFlattensEveryShape() {
        // Inert sets the influence to zero, so nothing the shape says is heard - which is the
        // reason the shapes need no conflict rule against it
        for surface in PaddleBounce.Surface.allCases {
            let angle = PaddleBounce.angleDegrees(
                arriving: CGVector(dx: 60, dy: -300),
                collision: PaddleBounce.shaped(0.8, by: surface),
                adjustmentK: 45, influence: 0, minimumDeg: 10)
            XCTAssertEqual(angle, atan2(300.0, 60.0)*180/Double.pi, accuracy: 0.001,
                           "\(surface)")
        }
    }

    func testEveryShapedFaceIsAPowerUpTheGameCanActuallyOffer() {
        // §8.6's rule in the power-up axis: being in an enum and in a formula is not enough.
        // Each of the four has to be in the name array, the drop weights and the catalogue,
        // or it is a shape nobody will ever meet
        let setup = LevelPackSetup()
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.powerUpProbArray = Array(repeating: 0, count: setup.powerUpNameArray.count)
        scene.applyEndlessRowPowerUpWeights()

        var offerable = 0
        for surface in PaddleBounce.Surface.allCases {
            guard let index = setup.powerUpNameArray.firstIndex(of: surface.displayName) else {
                return XCTFail("\(surface) is not in the name array")
            }
            let entry = PowerUpCatalogue.all.first { $0.name == surface.displayName }
            guard entry?.availability != .retired else {
                XCTAssertEqual(scene.powerUpProbArray[index], 0,
                               "\(surface) is retired but can still drop, which is the "
                               + "difference between withdrawn and merely very rare")
                continue
            }
            // **A retired face keeps its slot and its formula, and stops being offered**
            // (round 213). The slot has to stay because the stored arrays are read by index;
            // what changes is that nobody meets it. So the rule flips for these: not "must be
            // droppable" but "must not be"
            offerable += 1
            XCTAssertGreaterThan(scene.powerUpProbArray[index], 0,
                                 "\(surface) never drops in Mayhem")
            XCTAssertEqual(setup.powerUpMultiplierArray[index], "-0.1", "the shapes are bad")
            XCTAssertTrue(PowerUpCatalogue.all.contains { $0.name == surface.displayName },
                          "\(surface) is not in the catalogue")
        }
        XCTAssertGreaterThan(offerable, 0,
                             "every shaped face is retired - the power-up exists in the enum "
                             + "and nowhere a player can reach it")
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

    func testAStruckPracticeBrickStaysSolidTheFrameItIsStruck() {
        // James, round 161: "brick hit disappear animation" should be the game's. The game
        // hides a destroyed brick and keeps its body for two frames, so the bounce the ball is
        // in the middle of resolves against something; the practice field used to take the
        // body away on the contact and fade the brick over 0.15s, so the ball could pass
        // through the brick it had just broken - which is not a thing the game ever does
        let scene = PaddleSpeedScene(size: CGSize(width: 390, height: 400))
        scene.layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)
        scene.soundsSetting = false
        scene.hapticsSetting = false
        // Silent, because a test that plays a sound is a test that opens an audio context
        scene.placeForTesting(ballX: 195, paddleX: 195, arriving: CGVector(dx: 40, dy: -300))

        guard let brick = scene.children.first(where: { $0.name == PaddleSpeedScene.brickName })
                as? SKSpriteNode else {
            return XCTFail("the practice field puts bricks up")
        }

        XCTAssertTrue(scene.canKnockOut(brick))
        scene.knockOut(brick)
        XCTAssertNotNil(brick.physicsBody,
                        "still solid on the frame it was struck, as in the game")
        XCTAssertFalse(brick.isHidden, "and still drawn - it goes two frames later")
    }

    func testAPracticeBrickIsNotKnockedOutTwice() {
        // The ball is touching the brick for every one of the frames it stays solid for, and
        // each of them reports a contact. Without the guard each would restart the sequence,
        // so the brick would never reach the moment it goes away
        let scene = PaddleSpeedScene(size: CGSize(width: 390, height: 400))
        scene.layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)
        scene.soundsSetting = false
        scene.hapticsSetting = false
        scene.placeForTesting(ballX: 195, paddleX: 195, arriving: CGVector(dx: 40, dy: -300))

        guard let brick = scene.children.first(where: { $0.name == PaddleSpeedScene.brickName })
                as? SKSpriteNode else {
            return XCTFail("the practice field puts bricks up")
        }
        scene.knockOut(brick)
        XCTAssertFalse(scene.canKnockOut(brick),
                       "a brick on its way out is not struck again, nor is one that is away")
    }

    func testThePracticeFieldLeavesTheThumbTheRoomTheGameDoes() {
        // Round 147: the paddle-speed screen put the paddle a kill-line's clearance above the
        // field's floor - 36 points - where the game leaves nearly 200
        let layout = GameSceneLayout(screen: CGSize(width: 393, height: 852), bottomInset: 34)
        XCTAssertGreaterThan(layout.paddleCentreAboveScreenBottom, 150)
        XCTAssertLessThan(layout.paddleCentreAboveScreenBottom, layout.screen.height/3)
    }
}

/// Which paddle a magnetised ball is drawn to while a Mirror Paddle stands.
///
/// James, round 225's matrix: "ball is magnetised to the closest paddle and not to the other."
/// Two magnets pulling one ball is a ball pulled to the point between them, which is the one
/// place neither paddle is.
final class MagnetismChoosesAPaddleTests: XCTestCase {

    func testWithNoMirrorItIsAlwaysTheRealPaddle() {
        XCTAssertEqual(EndlessIIPaddleEffects.magnetisedTowards(ballX: 90, paddleX: -50,
                                                                mirrorX: nil), -50)
    }

    func testTheNearerOfTheTwoPulls() {
        XCTAssertEqual(EndlessIIPaddleEffects.magnetisedTowards(ballX: 90, paddleX: -50,
                                                                mirrorX: 50), 50)
        XCTAssertEqual(EndlessIIPaddleEffects.magnetisedTowards(ballX: -90, paddleX: -50,
                                                                mirrorX: 50), -50)
    }

    /// A tie goes to the paddle the player is steering.
    ///
    /// With the ball exactly between them the choice is arbitrary, and an arbitrary choice
    /// should be the one the player can do something about.
    func testATieGoesToTheRealPaddle() {
        XCTAssertEqual(EndlessIIPaddleEffects.magnetisedTowards(ballX: 0, paddleX: -50,
                                                                mirrorX: 50), -50)
    }
}

/// The random kick that was only half removed, and the power-up that is supposed to be the
/// only thing throwing a bounce off.
///
/// James, play-test rounds 84, 88 and 98: the ball "changing direction slightly" with nothing
/// to blame. Round 98 found the cause - one angle correction in ten got up to five degrees of
/// random deflection - and took it out of `ballHorizontalControl`. The identical block was
/// left standing in `ballVerticalControl`, and a brick strike runs both, so it has been firing
/// on one brick contact in ten ever since, in every mode.
///
/// Round 313, alongside it: "Randomised bounce doesn't seem to be working". A bounce thrown
/// off by an ambient kick nobody knows about, and a power-up whose whole job is to throw
/// bounces off, are hard to tell apart - which is the second reason this had to go.
final class BounceIsAFunctionOfTheBounceTests: XCTestCase {

    /// One scene, driven many times.
    ///
    /// Deliberately not one scene per repeat: entering `Playing` asks `MusicHandler` for a
    /// volume, and two hundred of those on a simulator is the audio-server abort CLAUDE.md
    /// describes, which arrives as a named failing test that never ran.
    private func playing(mode: GameMode = .classic) -> GameScene {
        let scene = GameScene()
        scene.gameMode = mode
        scene.ballIsOnPaddle = false
        scene.gameState.enter(Playing.self)
        scene.ballSpeedLimit = 600
        scene.ballIsOnPaddle = false
        scene.addChild(scene.ball)
        scene.ball.position = CGPoint(x: 40, y: 0)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.brickWidth = 40
        return scene
    }

    /// Somewhere new for each repeat.
    ///
    /// The first draft of these bounced the ball off the same point two hundred times and got
    /// six different headings out of it - which was the loop-breaker being right. Two hundred
    /// identical bounces from one place *is* a loop, and it escalates its kick the longer the
    /// same one repeats. What is under test here is an honest bounce, so each repeat has to
    /// happen somewhere the detector has not seen.
    private func place(_ scene: GameScene, _ repeatIndex: Int) {
        scene.frameNumber = repeatIndex
        scene.ball.position = CGPoint(x: CGFloat(repeatIndex%17)*80 - 640,
                                      y: CGFloat(repeatIndex)*37)
        scene.ball.physicsBody!.velocity = CGVector(dx: 180, dy: 400)
    }

    private let brick: SKSpriteNode = {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
        node.position = CGPoint(x: 0, y: 120)
        return node
    }()

    private func heading(_ scene: GameScene) -> Double {
        let v = scene.ball.physicsBody!.velocity
        return atan2(Double(v.dy), Double(v.dx))/Double.pi*180
    }

    /// The same bounce, two hundred times, must leave the same way.
    func testTheVerticalCorrectionDoesNotThrowTheOccasionalBounceOffCourse() {
        let scene = playing()
        var headings: Set<String> = []
        for frame in 0..<200 {
            place(scene, frame)
            scene.ballVerticalControl(brickNode: brick, for: scene.ball)
            headings.insert(String(format: "%.4f", heading(scene)))
        }
        XCTAssertEqual(headings.count, 1,
                       "one bounce, one outcome: \(headings.sorted())")
    }

    /// And the horizontal one, which is where the kick was removed in round 98. Kept so the
    /// pair cannot drift apart again.
    func testTheHorizontalCorrectionDoesNotEither() {
        let scene = playing()
        var headings: Set<String> = []
        for frame in 0..<200 {
            place(scene, frame)
            scene.ballHorizontalControl(angleDegInput: 65.8, brickNode: brick,
                                        for: scene.ball)
            headings.insert(String(format: "%.4f", heading(scene)))
        }
        XCTAssertEqual(headings.count, 1,
                       "one bounce, one outcome: \(headings.sorted())")
    }

    /// Randomised Bounce is then the one thing that does scatter a bounce, and it reaches a
    /// real one rather than only its own arithmetic - the round 88 lesson, where Auto-Aim was
    /// built, documented, tested, and called by nothing.
    func testRandomisedBounceReachesARealBounce() {
        let scene = playing(mode: .endlessII)
        scene.endlessIICollectRandomisedBounce()
        XCTAssertTrue(scene.endlessIIRandomisedBounceClock.isRunning)

        let honest = 65.8
        var headings: Set<String> = []
        var worst = 0.0
        for frame in 0..<200 {
            place(scene, frame)
            // A new frame each time, because the power-up randomises one bounce per ball per
            // frame - the round 283 stutter fix. Left at one frame this would scatter once
            // and then look exactly like a power-up that does nothing
            scene.ballHorizontalControl(angleDegInput: honest, for: scene.ball)
            headings.insert(String(format: "%.4f", heading(scene)))
            worst = max(worst, abs(heading(scene) - honest))
        }
        XCTAssertGreaterThan(headings.count, 20,
                             "the power-up has to actually change the angle a bounce leaves at")
        XCTAssertGreaterThan(worst, 5,
                             "a power-up nobody can see the effect of is a power-up that does "
                             + "not work - James, round 313")
    }

    /// With the clock stopped it is the honest bounce again, which is what makes the scatter
    /// above the power-up rather than the weather.
    func testWithoutThePowerUpTheSameBounceIsTheSameBounce() {
        let scene = playing(mode: .endlessII)
        var headings: Set<String> = []
        for frame in 0..<200 {
            place(scene, frame)
            scene.ballHorizontalControl(angleDegInput: 65.8, for: scene.ball)
            headings.insert(String(format: "%.4f", heading(scene)))
        }
        XCTAssertEqual(headings.count, 1, "\(headings.sorted())")
    }
}

/// The phantom-brick tripwire, and the one thing it kept crying at.
///
/// James's round 313 log, from a vanilla Classic daily with no twists in it:
/// `PHANTOM BRICKS: 142 solid but unseeable`. 142 is most of a Classic field, and the moment
/// it fired at was the level build-in - which sets every brick to alpha zero and scale zero
/// and pops the rows in from the top on a stagger. Every brick still waiting its turn was
/// solid and unseeable, correctly.
///
/// A tripwire that cries at correct behaviour is one whose next real finding gets skipped
/// over, which is the second time that has been said about this one (round 312 was Hide
/// Bricks).
final class PhantomBrickWatchTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.yBrickOffsetEndless = 300
        return scene
    }

    @discardableResult
    private func brick(in scene: GameScene, at x: CGFloat) -> SKSpriteNode {
        let brick = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
        brick.name = BrickCategoryName
        brick.position = CGPoint(x: x, y: 100)
        brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
        brick.physicsBody?.categoryBitMask = CollisionTypes.brickCategory.rawValue
        scene.addChild(brick)
        return brick
    }

    /// The report: a field mid-build-in is not a field of phantoms.
    func testAFieldWaitingItsTurnInTheBuildInIsNotReported() {
        let scene = self.scene()
        for column in 0..<11 {
            let waiting = brick(in: scene, at: CGFloat(column)*40 - 200)
            waiting.alpha = 0
            waiting.setScale(0)
            waiting.run(.sequence([.wait(forDuration: Double(column)*0.04),
                                   .group([.fadeIn(withDuration: GameScene.classicBuildInPop),
                                           .scale(to: 1, duration: GameScene.classicBuildInPop)])]))
        }
        XCTAssertEqual(scene.phantomBrickPositions().count, 0,
                       "the build-in is the animation working, not 142 phantoms")
    }

    /// And it still finds the thing it was built for: solid, unseeable, and nothing running.
    func testABrickLeftInvisibleWithNothingRunningIsStillReported() {
        let scene = self.scene()
        let stranded = brick(in: scene, at: 0)
        stranded.alpha = 0

        XCTAssertEqual(scene.phantomBrickPositions(), [stranded.position],
                       "a Fog reveal that did not finish, or a brick shrunk and never grown "
                       + "back, is exactly what this watch is for")
    }

    func testAVisibleBrickIsNeverReported() {
        let scene = self.scene()
        brick(in: scene, at: 0)
        XCTAssertTrue(scene.phantomBrickPositions().isEmpty)
    }

    /// The row waiting above the field, which is what the enriched report caught.
    ///
    /// A live Endless log said `16x alpha 0.00 plain row -1` - row minus one being *above* the
    /// top row, where the next row is staged with its alpha at nothing until its turn comes.
    /// Solid and unseeable, and neither one matters: no ball can reach above the play area,
    /// and showing a row before it arrives is what would be the bug.
    ///
    /// **A whole row wide, read off the layout** (round 313). The other open report against
    /// this watch was `PHANTOM BRICKS: 11 solid but unseeable` in the original Endless mode,
    /// all at one y, two seconds into a run - and `GameSceneLayout.brickColumns` is
    /// `brickRows/2`, which is **eleven**. So that report is one full row at one height with
    /// nothing drawn, which is precisely what a staged build-in row is; original Endless stages
    /// its rows exactly as Mayhem does, through `prepareEndlessIIBuildIn`. Taking the count
    /// from the layout rather than typing it again is what lets the test say so.
    func testARowStagedAboveTheFieldIsNotReported() {
        let scene = self.scene()
        for column in 0..<GameSceneLayout.brickColumns {
            let waiting = brick(in: scene, at: CGFloat(column)*40 - 200)
            waiting.position.y = scene.yBrickOffsetEndless + scene.brickHeight
            waiting.alpha = 0
        }
        XCTAssertTrue(scene.phantomBrickPositions().isEmpty,
                      "the next row has not arrived yet")
    }

    /// **Hide Bricks is the game working, and the texture guard never covered it.**
    ///
    /// Round 312 closed this watch against "a brick that is meant to be unseeable" and its own
    /// note said Hide Bricks was one of the two cases handled. It was not:
    /// `powerUpNormalToInvisibleBricks` writes `isHidden` and leaves the texture alone, so
    /// every brick it hid walked through a guard that asks about the texture. The watch has
    /// been crying at that power-up in Classic and the original Endless for the whole ten
    /// seconds it runs.
    ///
    /// The signal is the tray bar, because that is how this power-up already says it is
    /// running - the timer, the ring and the save all read it.
    func testHideBricksIsNotAFieldOfPhantoms() {
        let scene = self.scene()
        for column in 0..<11 {
            brick(in: scene, at: CGFloat(column)*40 - 200).isHidden = true
        }
        scene.hiddenBricksIconBar.isHidden = false

        XCTAssertTrue(scene.endlessHiddenBricksIsRunning, "the state this is about")
        XCTAssertTrue(scene.phantomBrickPositions().isEmpty,
                      "eleven hidden bricks with Hide Bricks running is the power-up, not "
                      + "eleven phantoms")
        XCTAssertFalse(scene.phantomBrickReasons().contains("hidden"),
                       "and the reasons line has to agree with the count, or they answer "
                       + "two different questions")
    }

    /// And the moment it stops, they are watched again.
    func testHiddenBricksAreWatchedAgainWhenThePowerUpEnds() {
        let scene = self.scene()
        let hidden = brick(in: scene, at: 0)
        hidden.isHidden = true
        scene.hiddenBricksIconBar.isHidden = false
        XCTAssertTrue(scene.phantomBrickPositions().isEmpty)

        scene.hiddenBricksIconBar.isHidden = true
        XCTAssertEqual(scene.phantomBrickPositions(), [hidden.position],
                       "a brick still hidden after the power-up ended is a reveal that did "
                       + "not finish, which is precisely what this watch is for")
    }

    /// The exclusion is `isHidden` alone, not a ten-second hole in the watch.
    ///
    /// Hide Bricks writes one property. A brick faded or shrunk to nothing while it runs is
    /// still a fault, and would be missed by an exclusion drawn any wider.
    func testAFadedBrickIsStillReportedWhileHideBricksRuns() {
        let scene = self.scene()
        let faded = brick(in: scene, at: 0)
        faded.alpha = 0
        scene.hiddenBricksIconBar.isHidden = false

        XCTAssertEqual(scene.phantomBrickPositions(), [faded.position],
                       "Hide Bricks does not fade bricks, so a faded one is not it")
    }

    /// **The staged row is excused at any row height** (round 369, James's Mac log: `PHANTOM
    /// BRICKS: 11 solid but unseeable - 11x alpha 0.00 plain row -1`). A row -1 brick's lower
    /// edge lies exactly on the field's upper one, and at a row height that is not a round
    /// number "exactly" came out a hair below it. These two are a pair the arithmetic trips on,
    /// found for SpriteKit's arithmetic rather than Swift's: a node keeps its position and size
    /// in single precision, so the pair has to trip after both are rounded to a Float - the
    /// first pair tried tripped on paper and passed in the scene.
    func testTheStagedRowIsExcusedWhateverTheRowHeight() {
        let scene = self.scene()
        scene.brickHeight = 33.955756157170434
        scene.yBrickOffsetEndless = 831.9896246381859
        for column in 0..<11 {
            let waiting = SKSpriteNode(color: .red,
                                       size: CGSize(width: 40, height: scene.brickHeight))
            waiting.name = BrickCategoryName
            waiting.position = CGPoint(x: CGFloat(column)*40 - 200,
                                       y: scene.yBrickOffsetEndless + scene.brickHeight)
            waiting.physicsBody = SKPhysicsBody(rectangleOf: waiting.size)
            waiting.physicsBody?.categoryBitMask = CollisionTypes.brickCategory.rawValue
            waiting.alpha = 0
            scene.addChild(waiting)
        }
        XCTAssertEqual(scene.phantomBrickPositions(), [],
                       "a row waiting above the field is not eleven phantoms")
        XCTAssertEqual(scene.phantomBrickReasons(), "")
    }

    /// And the row that *has* arrived is still watched.
    func testTheTopRowOfTheFieldIsStillWatched() {
        let scene = self.scene()
        let arrived = brick(in: scene, at: 0)
        arrived.position.y = scene.yBrickOffsetEndless
        arrived.alpha = 0

        XCTAssertEqual(scene.phantomBrickPositions(), [arrived.position],
                       "one row lower is in the field, where a ball can hit it")
    }

    /// Round 312's exclusion, kept: a brick meant to be unseeable is not a phantom.
    func testAnInvisibleTexturedBrickIsStillExcluded() {
        let scene = self.scene()
        let hidden = brick(in: scene, at: 0)
        hidden.texture = scene.brickInvisibleTexture
        hidden.isHidden = true

        XCTAssertTrue(scene.phantomBrickPositions().isEmpty,
                      "Hide Bricks and Mayhem's Invisible brick both work this way")
    }
}

/// The whole of the seam correction, from the strikes a step recorded to the velocity the ball
/// leaves with. `seamFace` is pinned above; this is the part that acts on it, which no test
/// ran until round 358's coverage pass found it at nothing.
///
/// The fault it exists for (BrickSeamBounce's header): a ball arriving on the seam between two
/// surviving bricks "bounces off what is geometrically a corner", so the field "looks like it
/// is lying about its own shape".
final class SeamBounceResolutionTests: XCTestCase {

    private let left = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
    private let right = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))

    private func scene(arrivingFrom position: CGPoint, at velocity: CGVector) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.ballIsOnPaddle = false
        scene.gameState.enter(Playing.self)
        scene.ballSpeedLimit = 600
        scene.addChild(scene.ball)
        scene.ball.position = position
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody!.velocity = velocity
        scene.brickWidth = 40
        left.position = CGPoint(x: -20, y: 100)
        right.position = CGPoint(x: 20, y: 100)
        scene.recordBallStatesBeforeStep()
        return scene
    }

    func testABallUpIntoTheSeamComesBackDownTheWayItWentUp() {
        let scene = scene(arrivingFrom: CGPoint(x: -4, y: 80), at: CGVector(dx: 180, dy: 572.364))
        // At the speed limit, where the game holds every ball in flight
        scene.noteBrickStrike(ball: scene.ball, brick: left)
        scene.noteBrickStrike(ball: scene.ball, brick: right)
        scene.ball.physicsBody!.velocity = CGVector(dx: -300, dy: -260)
        // What the engine made of it: thrown back off a corner, the wrong way across

        scene.resolveBrickSeamBounces()

        let v = scene.ball.physicsBody!.velocity
        XCTAssertGreaterThan(v.dx, 0, "still travelling the way it was across the row")
        XCTAssertLessThan(v.dy, 0, "and back down off the bricks' underside")
        XCTAssertEqual(hypot(v.dx, v.dy), 600, accuracy: 1, "at its own speed")
        XCTAssertTrue(scene.brickSeamStrikes.isEmpty, "and the step's strikes are cleared")
    }

    func testOneBrickIsARealCornerAndIsLeftToTheEngine() {
        let scene = scene(arrivingFrom: CGPoint(x: -4, y: 80), at: CGVector(dx: 120, dy: 400))
        scene.noteBrickStrike(ball: scene.ball, brick: left)
        let engine = CGVector(dx: -300, dy: -260)
        scene.ball.physicsBody!.velocity = engine

        scene.resolveBrickSeamBounces()

        XCTAssertEqual(scene.ball.physicsBody!.velocity, engine)
        XCTAssertTrue(scene.brickSeamStrikes.isEmpty)
    }

    func testAGigaBallHasNoBounceToCorrect() {
        let scene = scene(arrivingFrom: CGPoint(x: -4, y: 80), at: CGVector(dx: 120, dy: 400))
        scene.ball.texture = scene.gigaBallTexture
        scene.noteBrickStrike(ball: scene.ball, brick: left)
        scene.noteBrickStrike(ball: scene.ball, brick: right)
        let through = CGVector(dx: 120, dy: 400)
        scene.ball.physicsBody!.velocity = through

        scene.resolveBrickSeamBounces()

        XCTAssertEqual(scene.ball.physicsBody!.velocity, through, "it passes through bricks")
    }

    func testNothingIsCorrectedOutsidePlayButTheStrikesStillGo() {
        let scene = scene(arrivingFrom: CGPoint(x: -4, y: 80), at: CGVector(dx: 120, dy: 400))
        scene.gameState.enter(Paused.self)
        scene.noteBrickStrike(ball: scene.ball, brick: left)
        scene.noteBrickStrike(ball: scene.ball, brick: right)
        let engine = CGVector(dx: -300, dy: -260)
        scene.ball.physicsBody!.velocity = engine

        scene.resolveBrickSeamBounces()

        XCTAssertEqual(scene.ball.physicsBody!.velocity, engine)
        XCTAssertTrue(scene.brickSeamStrikes.isEmpty,
                      "or a pause would carry a stale strike into the next step")
    }

    func testABallWithNoRecordedApproachIsLeftAlone() {
        let scene = scene(arrivingFrom: CGPoint(x: -4, y: 80), at: CGVector(dx: 120, dy: 400))
        scene.ballStateBeforeStep.removeAll()
        scene.noteBrickStrike(ball: scene.ball, brick: left)
        scene.noteBrickStrike(ball: scene.ball, brick: right)
        let engine = CGVector(dx: -300, dy: -260)
        scene.ball.physicsBody!.velocity = engine

        scene.resolveBrickSeamBounces()

        XCTAssertEqual(scene.ball.physicsBody!.velocity, engine,
                       "without the approach there is no telling which face was struck")
    }
}

/// The every-frame catch for a ball travelling horizontally (`breakHorizontalRuns`). Round
/// 358's coverage pass found a fifth of it run. "A horizontal ball never comes down, so it can
/// never be lost and never be played" - the one heading the game cannot allow.
final class HorizontalRunBreakerTests: XCTestCase {

    private func flying(_ velocity: CGVector) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.minAngleDeg = 15
        scene.ballIsOnPaddle = false
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody!.velocity = velocity
        return scene
    }

    private func heading(_ v: CGVector) -> Double {
        atan2(Double(abs(v.dy)), Double(abs(v.dx)))*180/Double.pi
    }

    func testANearlyFlatBallIsLiftedOffHorizontalKeepingItsWay() {
        for _ in 0..<40 {
            let scene = flying(CGVector(dx: -598, dy: 20))
            scene.breakHorizontalRuns()
            let v = scene.ball.physicsBody!.velocity
            XCTAssertLessThan(v.dx, 0, "still going left")
            XCTAssertGreaterThan(v.dy, 0, "still climbing")
            XCTAssertEqual(hypot(v.dx, v.dy), hypot(598, 20), accuracy: 0.5, "at its own speed")
            XCTAssertGreaterThanOrEqual(heading(v), 15 - 0.01)
            XCTAssertLessThanOrEqual(heading(v), 15 + GameScene.horizontalEscapeJitter + 0.01)
        }
    }

    func testADeadFlatBallIsSentOneWayOrTheOther() {
        var ups = 0
        for _ in 0..<60 {
            let scene = flying(CGVector(dx: 500, dy: 0))
            scene.breakHorizontalRuns()
            let v = scene.ball.physicsBody!.velocity
            XCTAssertGreaterThan(v.dx, 0)
            XCTAssertNotEqual(v.dy, 0)
            XCTAssertGreaterThanOrEqual(heading(v), 15 - 0.01)
            if v.dy > 0 { ups += 1 }
        }
        XCTAssertTrue((1...59).contains(ups), "both ways turn up, \(ups) of 60 went up")
    }

    func testTheEscapesDifferSoTwoBallsDoNotLeaveInLockstep() {
        let headings = (0..<20).map { _ -> Double in
            let scene = flying(CGVector(dx: 600, dy: -5))
            scene.breakHorizontalRuns()
            return heading(scene.ball.physicsBody!.velocity)
        }
        XCTAssertGreaterThan(Set(headings.map { ($0*100).rounded() }).count, 5)
    }

    func testABallSteepEnoughAlreadyIsLeftAlone() {
        let scene = flying(CGVector(dx: 500, dy: 150))
        // 16.7 degrees: just above the 15 the scene allows
        scene.breakHorizontalRuns()
        XCTAssertEqual(scene.ball.physicsBody!.velocity.dx, 500, accuracy: 0.01)
        XCTAssertEqual(scene.ball.physicsBody!.velocity.dy, 150, accuracy: 0.01)
    }

    func testABallOnThePaddleOrBarelyMovingIsNotItsBusiness() {
        let held = flying(CGVector(dx: 300, dy: 0))
        held.ballIsOnPaddle = true
        held.breakHorizontalRuns()
        XCTAssertEqual(held.ball.physicsBody!.velocity.dy, 0, "a held ball rides the paddle")

        let still = flying(CGVector(dx: 0.5, dy: 0))
        still.breakHorizontalRuns()
        XCTAssertEqual(still.ball.physicsBody!.velocity.dy, 0)
    }
}

/// The ceiling and the backstop, through the contact handler itself. Round 358's coverage pass
/// found neither branch run by any test - and the ceiling's is the fix for "ran along the top
/// of the screen horizontally until something else knocked it out of it".
final class CeilingAndBackstopContactTests: XCTestCase {

    private func playing() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        scene.minAngleDeg = 15
        scene.ballSpeedLimit = 600
        scene.brickWidth = 40
        scene.gameState.enter(Playing.self)
        scene.ballIsOnPaddle = false
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody!.categoryBitMask = CollisionTypes.ballCategory.rawValue
        return scene
    }

    private func block(_ scene: GameScene, size: CGSize, category: CollisionTypes) -> SKSpriteNode {
        let node = SKSpriteNode(color: .clear, size: size)
        node.physicsBody = SKPhysicsBody(rectangleOf: size)
        node.physicsBody!.categoryBitMask = category.rawValue
        scene.addChild(node)
        return node
    }

    func testTheCeilingAlwaysSendsTheBallDown() {
        // Whatever the engine has already done to it: the approach is what decides
        for engine in [CGVector(dx: 300, dy: -520), CGVector(dx: 300, dy: 520)] {
            let scene = playing()
            let ceiling = block(scene, size: CGSize(width: 400, height: 40),
                                category: .screenBlockCategory)
            scene.ball.position = CGPoint(x: 10, y: 300)
            scene.ball.physicsBody!.velocity = CGVector(dx: 300, dy: 520)
            scene.recordBallStatesBeforeStep()
            scene.ball.physicsBody!.velocity = engine

            scene.handleContact(between: scene.ball.physicsBody!, and: ceiling.physicsBody!)

            let v = scene.ball.physicsBody!.velocity
            XCTAssertLessThan(v.dy, 0, "engine said \(engine)")
            XCTAssertGreaterThan(v.dx, 0, "and it keeps travelling the way it was")
        }
    }

    func testASideBlockIsAWall() {
        let scene = playing()
        let side = block(scene, size: CGSize(width: 20, height: 600), category: .screenBlockCategory)
        scene.ball.position = CGPoint(x: 180, y: 0)
        scene.ball.physicsBody!.velocity = CGVector(dx: 400, dy: 300)
        scene.recordBallStatesBeforeStep()

        scene.handleContact(between: side.physicsBody!, and: scene.ball.physicsBody!)

        XCTAssertLessThan(scene.ball.physicsBody!.velocity.dx, 0, "back off the right-hand side")
        XCTAssertGreaterThan(scene.ball.physicsBody!.velocity.dy, 0)
    }

    func testTheBackstopSpendsACatchAndSendsTheBallBackUp() {
        let scene = playing()
        scene.paddle.position = CGPoint(x: 0, y: -300)
        let backstop = block(scene, size: CGSize(width: 400, height: 10), category: .backstopCategory)
        scene.backstopCatches = 3
        scene.ball.position = CGPoint(x: 0, y: -380)
        scene.ball.physicsBody!.velocity = CGVector(dx: 590, dy: 40)
        // Already turned up by the engine, and very shallow

        scene.handleContact(between: scene.ball.physicsBody!, and: backstop.physicsBody!)

        XCTAssertEqual(scene.backstopCatches, 2)
        let v = scene.ball.physicsBody!.velocity
        XCTAssertGreaterThan(v.dy, 0)
        let heading = atan2(Double(v.dy), Double(abs(v.dx)))*180/Double.pi
        XCTAssertGreaterThanOrEqual(heading, 15 - 0.01, "never sent off flat")
    }

    func testTheLastCatchPutsTheBackstopAwayAndNeverGoesNegative() {
        let scene = playing()
        scene.paddle.position = CGPoint(x: 0, y: -300)
        let backstop = block(scene, size: CGSize(width: 400, height: 10), category: .backstopCategory)
        scene.ball.position = CGPoint(x: 0, y: -380)
        scene.ball.physicsBody!.velocity = CGVector(dx: 200, dy: 400)

        scene.backstopCatches = 1
        scene.handleContact(between: scene.ball.physicsBody!, and: backstop.physicsBody!)
        XCTAssertEqual(scene.backstopCatches, 0)
        XCTAssertTrue(scene.hasActions(), "the backstop's put-away is under way")

        scene.handleContact(between: scene.ball.physicsBody!, and: backstop.physicsBody!)
        XCTAssertEqual(scene.backstopCatches, 0, "a hit in the put-away does not owe a catch")
    }
}

/// A power-up that reaches the bottom unclaimed. Round 358's coverage pass found the branch
/// unrun: it keeps the on-screen count honest and moves the two Power-Up Leaver achievements.
final class MissedPowerUpTests: XCTestCase {

    private func missed(generated: Int, collected: Int) -> (GameScene, SKSpriteNode) {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].powerupsGenerated[2] = generated
        scene.totalStatsArray[0].powerupsCollected[2] = collected
        scene.powerUpsOnScreen = 1
        let powerUp = SKSpriteNode(texture: scene.powerUpTexturesInOrder[2])
        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: 8)
        powerUp.physicsBody!.categoryBitMask = CollisionTypes.powerUpCategory.rawValue
        scene.addChild(powerUp)
        let floor = SKSpriteNode(color: .clear, size: CGSize(width: 400, height: 20))
        floor.physicsBody = SKPhysicsBody(rectangleOf: floor.size)
        floor.physicsBody!.categoryBitMask = CollisionTypes.bottomScreenBlockCategory.rawValue
        scene.addChild(floor)
        scene.handleContact(between: powerUp.physicsBody!, and: floor.physicsBody!)
        return (scene, powerUp)
    }

    func testAMissedPowerUpLeavesTheScreenAndTheCount() {
        let (scene, powerUp) = missed(generated: 10, collected: 4)
        XCTAssertEqual(scene.powerUpsOnScreen, 0)
        XCTAssertTrue(powerUp.hasActions(), "fading away rather than vanishing")
    }

    func testTheLeaverAchievementsCountWhatWasLeft() {
        let (scene, _) = missed(generated: 60, collected: 15)
        XCTAssertEqual(scene.totalStatsArray[0].achievementsPercentageCompleteArray[30], "45.0%")
        XCTAssertEqual(scene.totalStatsArray[0].achievementsPercentageCompleteArray[31], "4.5%")
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[30])
    }

    func testAHundredLeftEarnsTheFirst() {
        let (scene, _) = missed(generated: 130, collected: 30)
        XCTAssertTrue(scene.totalStatsArray[0].achievementsUnlockedArray[30])
        XCTAssertEqual(scene.totalStatsArray[0].achievementsPercentageCompleteArray[30], "100%")
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[31])
    }
}

/// The serve (`releaseBall`). Round 358b's coverage list had it at nothing, and every ball in
/// every mode leaves the paddle through it. The angle is the paddle's oldest rule: straight up
/// less up to sixty degrees for how far from the middle the ball sits, and always at least ten
/// off vertical, so no serve goes straight up and straight back down.
final class ServeTests: XCTestCase {

    private func onThePaddle(at offset: CGFloat) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        scene.ballSpeedLimit = 600
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 100, height: 12)
        scene.paddle.position = CGPoint(x: 20, y: -300)
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.ball.position = CGPoint(x: 20 + offset*50, y: -288)
        scene.ballIsOnPaddle = true
        scene.ballLostBool = true
        return scene
    }

    private func degrees(_ scene: GameScene) -> Double {
        let v = scene.ball.physicsBody!.velocity
        return atan2(Double(v.dy), Double(v.dx))*180/Double.pi
    }

    func testTheBallLeavesAtTheSpeedLimitAndIsInPlay() {
        let scene = onThePaddle(at: 0.3)
        scene.brickBounceCounter = 7
        scene.releaseBall()
        let v = scene.ball.physicsBody!.velocity
        XCTAssertEqual(hypot(v.dx, v.dy), 600, accuracy: 0.5)
        XCTAssertFalse(scene.ballIsOnPaddle)
        XCTAssertFalse(scene.ballLostBool)
        XCTAssertEqual(scene.brickBounceCounter, 0)
    }

    func testTheSpotOnThePaddleSetsTheAngle() {
        // Right of the middle sends it right, left sends it left, further out is shallower
        for (offset, expected) in [(0.5, 50.0), (1.0, 20.0), (-0.5, 130.0), (-1.0, 160.0)] {
            let scene = onThePaddle(at: CGFloat(offset))
            scene.releaseBall()
            XCTAssertEqual(degrees(scene), expected, accuracy: 0.01, "offset \(offset)")
        }
    }

    func testABallPastTheEndIsServedAsIfFromTheEnd() {
        let scene = onThePaddle(at: 1.6)
        scene.releaseBall()
        XCTAssertEqual(degrees(scene), 20, accuracy: 0.01)
    }

    func testTheMiddleGoesEitherWayButNeverStraightUp() {
        var lefts = 0
        for _ in 0..<40 {
            let scene = onThePaddle(at: 0)
            scene.releaseBall()
            let angle = degrees(scene)
            XCTAssertTrue(abs(angle - 80) < 0.01 || abs(angle - 100) < 0.01, "\(angle)")
            if angle > 90 { lefts += 1 }
        }
        XCTAssertTrue((1...39).contains(lefts), "\(lefts) of 40 went left")
    }

    func testAServedBallMeetsThePaddleAgain() {
        // A waiting ball is taken out of the paddle's collisions so the engine cannot shove it
        // along a shaped paddle; "only a launch can put it back"
        let scene = onThePaddle(at: 0.3)
        scene.setEndlessIIHeldBallRestsOnPaddle(true, for: scene.ball)
        let paddle = CollisionTypes.paddleCategory.rawValue
        XCTAssertEqual(scene.ball.physicsBody!.collisionBitMask & paddle, 0)

        scene.releaseBall()

        XCTAssertNotEqual(scene.ball.physicsBody!.collisionBitMask & paddle, 0)
        XCTAssertNotEqual(scene.ball.physicsBody!.contactTestBitMask & paddle, 0)
    }

    func testAnInertCatchLaunchesAtTheWallsAngleOnce() {
        // "A ball caught while the paddle was inert launches at the angle the inert bounce
        // would have given (James's design) - the wall's answer, not the paddle's"
        let scene = onThePaddle(at: 0.9)
        scene.stickyInertLaunchAngleRad = 63*Double.pi/180
        scene.releaseBall()
        XCTAssertEqual(degrees(scene), 63, accuracy: 0.01)
        XCTAssertNil(scene.stickyInertLaunchAngleRad, "spent on the one launch")
    }
}

/// A ball held on a shaped paddle leaves along the face, not by where it sits.
///
/// **James, round 360:** "With a shaped paddle and sticky paddle power ups active together, the
/// launch angle of the ball should be based on the angle of the paddle at the position of the
/// ball, not based on the position of the ball on the paddle. For example a wedge left paddle
/// would always fire the ball to the left wherever the ball was positioned on the paddle
/// because that's the way the paddle is facing. For the regular flat paddle, the current
/// behaviour should stay the same."
final class ShapedPaddleLaunchTests: XCTestCase {

    private func held(on surface: PaddleBounce.Surface?, at offset: CGFloat) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSpeedLimit = 600
        scene.minAngleDeg = 15
        scene.paddleHeight = 12
        scene.addChild(scene.paddle)
        scene.paddle.texture = scene.paddleTexture
        scene.paddle.size = CGSize(width: 90, height: 12)
        scene.paddle.position = CGPoint(x: 20, y: -300)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        if let surface {
            scene.endlessIICollectPaddleSurface(surface)
            scene.refreshEndlessIIPaddleShapeArt()
        }
        scene.addChild(scene.ball)
        scene.ball.size = CGSize(width: 12, height: 12)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.ball.position = CGPoint(x: 20 + offset, y: -288)
        scene.ballIsOnPaddle = true
        return scene
    }

    private func launched(on surface: PaddleBounce.Surface?, at offset: CGFloat) -> Double {
        let scene = held(on: surface, at: offset)
        scene.releaseBall()
        let v = scene.ball.physicsBody!.velocity
        return atan2(Double(v.dy), Double(v.dx))*180/Double.pi
    }

    func testAWedgeLeftAlwaysFiresLeft() {
        for offset: CGFloat in [-35, -15, 0, 15, 35] {
            XCTAssertGreaterThan(launched(on: .wedgeLeft, at: offset), 90, "from \(offset)")
        }
    }

    /// One shape after the other, again and again, each its own (round 365). The outline caches
    /// were keyed on a texture's address, so a new texture given a freed one's address was
    /// given its outline too - the full suite saw a Wedge Right fire at a Wedge Left's 105
    /// degrees, one run in many, straight after the Wedge Left's own test.
    func testAlternatingShapesEachLaunchAsThemselves() {
        for round in 0..<12 {
            XCTAssertGreaterThan(launched(on: .wedgeLeft, at: -35), 90, "round \(round): left")
            XCTAssertLessThan(launched(on: .wedgeRight, at: -35), 90, "round \(round): right")
        }
    }

    /// Two pictures never share an identity; one picture asked for twice always does.
    func testATexturesCacheIdentityIsItsPicture() {
        let left = SKTexture(imageNamed: "regularPaddleWedgeLeft")
        let right = SKTexture(imageNamed: "regularPaddleWedgeRight")
        XCTAssertNotEqual(left.cacheIdentity, right.cacheIdentity)
        XCTAssertEqual(left.cacheIdentity, SKTexture(imageNamed: "regularPaddleWedgeLeft").cacheIdentity)
        let drawn = SKTexture(image: UIImage(systemName: "circle")!)
        let other = SKTexture(image: UIImage(systemName: "square")!)
        XCTAssertNotEqual(drawn.cacheIdentity, other.cacheIdentity, "unnamed pictures by object")
    }

    func testAWedgeRightAlwaysFiresRight() {
        for offset: CGFloat in [-35, -15, 0, 15, 35] {
            XCTAssertLessThan(launched(on: .wedgeRight, at: offset), 90, "from \(offset)")
        }
    }

    func testADomeFiresOutwardFromEachSide() {
        XCTAssertGreaterThan(launched(on: .convex, at: -30), 90, "the left of a dome faces left")
        XCTAssertLessThan(launched(on: .convex, at: 30), 90, "and the right faces right")
    }

    func testADishFiresInwardFromEachSide() {
        XCTAssertLessThan(launched(on: .concave, at: -30), 90, "the left of a dish faces right")
        XCTAssertGreaterThan(launched(on: .concave, at: 30), 90)
    }

    func testAShapedLaunchIsNeverFlat() {
        for surface in PaddleBounce.Surface.allCases {
            for offset: CGFloat in [-40, -20, 0, 20, 40] {
                let angle = launched(on: surface, at: offset)
                XCTAssertGreaterThanOrEqual(angle, 15 - 0.01, "\(surface) at \(offset)")
                XCTAssertLessThanOrEqual(angle, 165 + 0.01, "\(surface) at \(offset)")
            }
        }
    }

    func testTheFlatPaddleKeepsItsOwnRule() {
        // Halfway to the right end: the old rule's 50 degrees, not a face's straight up
        XCTAssertEqual(launched(on: nil, at: 22.5), 50, accuracy: 0.01)
    }

    func testAShapeThatHasRunOutLaunchesFlat() {
        let scene = held(on: .wedgeLeft, at: 22.5)
        scene.endlessIIPaddleSurfaceClock = EndlessIIClock()
        scene.releaseBall()
        let v = scene.ball.physicsBody!.velocity
        XCTAssertEqual(atan2(Double(v.dy), Double(v.dx))*180/Double.pi, 50, accuracy: 0.01)
    }
}

/// The angle rules every brick hit ends with (round 364), in all three modes.
///
/// `ballHorizontalControl` keeps a ball off the horizontal - "never so flat that it runs
/// sideways across the field for seconds at a time" - and `ballVerticalControl` keeps it off the
/// vertical, where it would rise and fall on one spot for ever. Coverage found the very lines that
/// do it had never run under a test: the four escapes from the flat band and the eight snaps out
/// of the upright one. Shared mechanics, and Classic and the original Endless have years of
/// scores on them, so what they do is pinned as it stands.
final class BallAngleLimitsTests: XCTestCase {

    private let minimum = 15.0

    private func playing() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.ballIsOnPaddle = false
        scene.gameState.enter(Playing.self)
        scene.ballIsOnPaddle = false
        scene.ballSpeedLimit = 600
        scene.minAngleDeg = minimum
        scene.brickWidth = 40
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        return scene
    }

    private var place = 0

    /// Somewhere the loop-breaker has not seen, heading `degrees` at the run's speed.
    private func aim(_ scene: GameScene, _ degrees: Double, x: CGFloat? = nil) {
        place += 1
        scene.frameNumber = place
        scene.ball.position = CGPoint(x: x ?? CGFloat(place%9)*60 - 240, y: CGFloat(place)*41)
        let radians = degrees*Double.pi/180
        scene.ball.physicsBody!.velocity = CGVector(dx: cos(radians)*600, dy: sin(radians)*600)
    }

    private func heading(_ scene: GameScene) -> Double {
        let v = scene.ball.physicsBody!.velocity
        return atan2(Double(v.dy), Double(v.dx))*180/Double.pi
    }

    func testAFlatBounceIsLiftedOffTheHorizontalOnItsOwnSide() {
        let scene = playing()
        for (flat, quadrant) in [(5.0, 1.0), (-5.0, -1.0), (175.0, 1.0), (-175.0, -1.0)] {
            aim(scene, flat)
            scene.ballHorizontalControl(angleDegInput: flat, for: scene.ball)
            let out = heading(scene)
            XCTAssertGreaterThanOrEqual(abs(out), minimum - 0.01, "\(flat) left at \(out)")
            XCTAssertLessThanOrEqual(abs(out), 180 - minimum + 0.01, "\(flat) left at \(out)")
            XCTAssertEqual(out.sign == .minus ? -1 : 1, quadrant, "\(flat): up stays up")
            XCTAssertEqual(cos(out*Double.pi/180) > 0, cos(flat*Double.pi/180) > 0,
                           "\(flat): and it keeps going the way it was going")
        }
    }

    /// Exactly horizontal off a brick, it leaves away from the brick.
    func testADeadFlatBounceLeavesAwayFromTheBrick() {
        let scene = playing()
        let brick = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
        scene.addChild(brick)
        aim(scene, 0)
        brick.position = CGPoint(x: scene.ball.position.x, y: scene.ball.position.y + 30)
        scene.ballHorizontalControl(angleDegInput: 0, brickNode: brick, for: scene.ball)
        XCTAssertLessThanOrEqual(heading(scene), -minimum + 0.01, "the brick is above, so down")

        aim(scene, 0)
        brick.position = CGPoint(x: scene.ball.position.x, y: scene.ball.position.y - 30)
        scene.ballHorizontalControl(angleDegInput: 0, brickNode: brick, for: scene.ball)
        XCTAssertGreaterThanOrEqual(heading(scene), minimum - 0.01, "the brick is below, so up")
    }

    /// Dead flat the other way, off a brick, it leaves away from the brick too.
    func testADeadFlatBounceLeftwardsLeavesAwayFromTheBrick() {
        let scene = playing()
        let brick = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
        scene.addChild(brick)
        aim(scene, 180)
        brick.position = CGPoint(x: scene.ball.position.x, y: scene.ball.position.y + 30)
        scene.ballHorizontalControl(angleDegInput: 180, brickNode: brick, for: scene.ball)
        XCTAssertLessThan(heading(scene), 0, "the brick is above, so down")
        XCTAssertLessThanOrEqual(heading(scene), -minimum + 0.01)

        aim(scene, 180)
        brick.position = CGPoint(x: scene.ball.position.x, y: scene.ball.position.y - 30)
        scene.ballHorizontalControl(angleDegInput: 180, brickNode: brick, for: scene.ball)
        XCTAssertGreaterThan(heading(scene), 0, "the brick is below, so up")
        XCTAssertLessThanOrEqual(heading(scene), 180 - minimum + 0.01)
    }

    /// The ball waiting on the paddle is nobody's to turn, and nor is a ball Gravity is
    /// carrying high above it - both functions leave them exactly as they are.
    func testAWaitingBallAndAGravityBallAreLeftAlone() {
        let scene = playing()
        aim(scene, 5)
        scene.ballIsOnPaddle = true
        scene.ballHorizontalControl(angleDegInput: 5, for: scene.ball)
        XCTAssertEqual(heading(scene), 5, accuracy: 0.01, "on the paddle")
        aim(scene, 89)
        scene.ballVerticalControl(for: scene.ball)
        XCTAssertEqual(heading(scene), 89, accuracy: 0.01, "on the paddle")

        scene.ballIsOnPaddle = false
        scene.gravityActivated = true
        scene.ballSize = 12
        scene.paddle.position = CGPoint(x: 0, y: -400)
        aim(scene, 5)
        scene.ballHorizontalControl(angleDegInput: 5, for: scene.ball)
        XCTAssertEqual(heading(scene), 5, accuracy: 0.01, "high under Gravity")
        aim(scene, 89)
        scene.ballVerticalControl(for: scene.ball)
        XCTAssertEqual(heading(scene), 89, accuracy: 0.01, "high under Gravity")

        scene.ball.position = CGPoint(x: 0, y: -380)
        scene.ball.physicsBody!.velocity = CGVector(dx: 600*cos(5*Double.pi/180),
                                                    dy: 600*sin(5*Double.pi/180))
        scene.ballHorizontalControl(angleDegInput: 5, for: scene.ball)
        XCTAssertGreaterThanOrEqual(heading(scene), minimum - 0.01,
                                    "but near the paddle Gravity's ball is corrected like any")
        scene.ball.physicsBody!.velocity = CGVector(dx: 600*cos(89*Double.pi/180),
                                                    dy: 600*sin(89*Double.pi/180))
        scene.ballVerticalControl(for: scene.ball)
        XCTAssertEqual(heading(scene), 90 - minimum/2, accuracy: 0.01, "upright too")
    }

    /// Multi-Ball: the first ball waiting on the paddle is no reason to leave another ball
    /// flying flat - each is asked about itself.
    func testAnExtraBallIsCorrectedWhileTheFirstWaits() {
        let scene = playing()
        scene.ballIsOnPaddle = true
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        extra.position = CGPoint(x: 90, y: 200)
        scene.addChild(extra)
        extra.physicsBody!.velocity = CGVector(dx: 600*cos(5*Double.pi/180),
                                               dy: 600*sin(5*Double.pi/180))
        scene.ballHorizontalControl(angleDegInput: 5, for: extra)
        var v = extra.physicsBody!.velocity
        XCTAssertGreaterThanOrEqual(atan2(Double(v.dy), Double(v.dx))*180/Double.pi, minimum - 0.01)
        extra.physicsBody!.velocity = CGVector(dx: 600*cos(89*Double.pi/180),
                                               dy: 600*sin(89*Double.pi/180))
        scene.ballVerticalControl(for: extra)
        v = extra.physicsBody!.velocity
        XCTAssertEqual(atan2(Double(v.dy), Double(v.dx))*180/Double.pi, 90 - minimum/2,
                       accuracy: 0.01)
    }

    /// A steady bounce is left alone, and the speed is the speed it had.
    func testAnHonestBounceIsUntouched() {
        let scene = playing()
        aim(scene, 60)
        scene.ballHorizontalControl(angleDegInput: 60, for: scene.ball)
        XCTAssertEqual(heading(scene), 60, accuracy: 0.01)
        let v = scene.ball.physicsBody!.velocity
        XCTAssertEqual(hypot(v.dx, v.dy), 600, accuracy: 1)
    }

    /// Near-upright is pushed half the minimum off the vertical, on the side it leans - on
    /// either half of the field, which the function treats separately at the edge of the lean.
    func testANearlyUprightBallIsTippedOffTheVertical() {
        let scene = playing()
        let half = minimum/2
        for x: CGFloat in [120, -120] {
            for (upright, expected) in [(88.0, 90 - half), (92.0, 90 + half),
                                        (-88.0, -90 + half), (-92.0, -90 - half)] {
                aim(scene, upright, x: x)
                scene.ballVerticalControl(for: scene.ball)
                XCTAssertEqual(heading(scene), expected, accuracy: 0.01, "\(upright) at x \(x)")
            }
        }
    }

    /// Dead upright off a brick leans away from it.
    func testADeadUprightBounceLeansAwayFromTheBrick() {
        let scene = playing()
        let brick = SKSpriteNode(color: .red, size: CGSize(width: 40, height: 20))
        scene.addChild(brick)
        aim(scene, 90, x: 100)
        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 600)
        // Exactly upright: cos and sin of a right angle leave a speck of dx, which is a lean
        // already, and the brick's branch only answers a ball with none
        brick.position = CGPoint(x: 70, y: scene.ball.position.y)
        scene.ballVerticalControl(brickNode: brick, for: scene.ball)
        XCTAssertLessThan(heading(scene), 90, "the brick is to the left, so it leans right")
        XCTAssertLessThanOrEqual(heading(scene), 90 - minimum/2 + 0.01)

        aim(scene, 90, x: 100)
        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 600)
        brick.position = CGPoint(x: 130, y: scene.ball.position.y)
        scene.ballVerticalControl(brickNode: brick, for: scene.ball)
        XCTAssertGreaterThanOrEqual(heading(scene), 90 + minimum/2 - 0.01,
                                    "and to the right, so it leans left")
    }
}
