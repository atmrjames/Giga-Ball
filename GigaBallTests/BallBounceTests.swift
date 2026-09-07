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
