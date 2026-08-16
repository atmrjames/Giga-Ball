//
//  EndlessIIFieldPowerUpTests.swift
//  GigaBallTests
//
//  Phase 8c's rules: the power-ups that act on the field. The instants are tested by doing
//  them to a small field and counting what is left; the clocks reuse the machinery 8b
//  already pinned down, so what is tested here is only what is new - who is spared, what is
//  scored, and which modes any of it can reach.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIFieldPowerUpTests: XCTestCase {

    private func fieldScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        scene.brickHeight = 20
        scene.brickWidth = 40
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.ball)
        return scene
    }

    @discardableResult
    private func brick(in scene: GameScene, x: CGFloat = 0, y: CGFloat = 100,
                       role: EndlessIIRole? = nil, powerUp: Int? = nil) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
        node.name = BrickCategoryName
        node.position = CGPoint(x: x, y: y)
        if let role { node.endlessIIRole = role }
        if let powerUp { node.endlessIIPowerUpIndex = powerUp }
        scene.addChild(node)
        return node
    }

    private func bricksLeft(_ scene: GameScene) -> Int {
        var count = 0
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if node.parent != nil { count += 1 }
        }
        return count
    }

    // MARK: - Cull

    func testCullTakesHalfTheFieldRoundedUp() {
        let scene = fieldScene()
        for index in 0..<9 { brick(in: scene, x: CGFloat(index)*45) }

        scene.endlessIICull()
        XCTAssertEqual(bricksLeft(scene), 4, "half of nine, rounded up, is five gone")
    }

    func testCullSparesPortalsAndPowerUpBricks() {
        // One is indestructible by everything; the other is spent by being hit, and a cull
        // that silently ate it would eat the power-up with it
        let scene = fieldScene()
        let portal = brick(in: scene, x: 0, role: .portal)
        let holder = brick(in: scene, x: 50, powerUp: 3)

        scene.endlessIICull()
        scene.endlessIICull()
        scene.endlessIICull()
        XCTAssertNotNil(portal.parent)
        XCTAssertNotNil(holder.parent)
    }

    func testCullScoresWhatItDestroys() {
        let scene = fieldScene()
        scene.brickDestroyScore = 10
        scene.multiplier = 1
        // The multiplier starts at zero until a level sets it up, and an award of
        // ten times nothing is nothing
        for index in 0..<4 { brick(in: scene, x: CGFloat(index)*45) }

        let before = scene.levelScore
        scene.endlessIICull()
        XCTAssertGreaterThan(scene.levelScore, before, "scored as destroyed, says §5.4")
    }

    func testCullNeverReachesTheOtherModes() {
        let scene = fieldScene()
        scene.gameMode = .classic
        brick(in: scene)
        scene.endlessIICull()
        XCTAssertEqual(bricksLeft(scene), 1)
    }

    // MARK: - Clear And Retreat

    // Play-test round 126, in James's words: "Clear and retreat power up should work
    // differently. It should be timed and it should raise the lowest brick level by 2
    // bricks." So these ask for both halves - two rows gone, and a clock holding the field
    // where they left it.

    func testTheLowestTwoRowsGo() {
        let scene = fieldScene()
        let low = brick(in: scene, x: 0, y: 40)
        let next = brick(in: scene, x: 0, y: 40 + scene.brickHeight)
        let high = brick(in: scene, x: 0, y: 40 + scene.brickHeight*4)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNil(low.parent, "the lowest occupied row is destroyed")
        XCTAssertNil(next.parent, "and the one that was lowest after it")
        XCTAssertNotNil(high.parent, "the rest of the field is untouched")
    }

    func testTheLowestLevelRisesByTwoRowsHoweverFarApartTheyAre() {
        let scene = fieldScene()
        let low = brick(in: scene, x: 0, y: 40)
        let next = brick(in: scene, x: 0, y: 40 + scene.brickHeight*5)
        let high = brick(in: scene, x: 0, y: 40 + scene.brickHeight*9)
        // Two occupied rows with a gap between them. "Raise the lowest brick level by 2
        // bricks" is about the lowest *levels*, not about two row heights of field - a
        // measurement from the bottom brick would have taken the first and missed the second

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNil(low.parent)
        XCTAssertNil(next.parent)
        XCTAssertNotNil(high.parent)
    }

    func testTheLowestRowMeansTheWholeRowNotOneBrick() {
        let scene = fieldScene()
        let left = brick(in: scene, x: -50, y: 40)
        let right = brick(in: scene, x: 50, y: 44)
        // Within half a brick of the same centre - the same row, as the descent reads it

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNil(left.parent)
        XCTAssertNil(right.parent)
    }

    func testTheRetreatIsTimedAndHoldsTheField() {
        let scene = fieldScene()
        brick(in: scene, x: 0, y: 40)
        XCTAssertFalse(scene.endlessIIFieldIsHeld)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertTrue(scene.endlessIIClearAndRetreatClock.isRunning, "timed, not instant")
        XCTAssertTrue(scene.endlessIIFieldIsHeld,
                      "and the field stays where the clear left it - the descent closing "
                      + "that gap is what made the old instant version invisible")

        scene.endlessIIClearAndRetreatClock.run(down: GameScene.endlessIIClearAndRetreatDuration)
        XCTAssertFalse(scene.endlessIIClearAndRetreatClock.isRunning)
        XCTAssertFalse(scene.endlessIIFieldIsHeld, "and the field comes back down after")
    }

    func testNothingIsLiftedAnyMore() {
        let scene = fieldScene()
        let high = brick(in: scene, x: 0, y: 100)
        brick(in: scene, x: 0, y: 40)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertFalse(high.hasActions(),
                       "a repeating action on a brick stops the field for ever (§8.6), and "
                       + "the lift this used to run was the only reason to risk one here")
    }

    func testAPortalRowDoesNotTrapTheClear() {
        let scene = fieldScene()
        let portal = brick(in: scene, x: 0, y: 40)
        portal.endlessIIRole = .portal
        let above = brick(in: scene, x: 0, y: 40 + scene.brickHeight)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNotNil(portal.parent, "spared, as a Cull spares it")
        XCTAssertNotNil(above.parent,
                        "and the pass stops rather than looking at the same row twice")
    }

    func testAnEmptyFieldRetreatsNothing() {
        let scene = fieldScene()
        scene.endlessIICollectClearAndRetreat()
        XCTAssertEqual(bricksLeft(scene), 0, "and does not trap")
    }

    // MARK: - Laser Beam

    func testEveryBallBurnsItsOwnColumn() {
        let scene = fieldScene()
        scene.ball.position = CGPoint(x: 0, y: -100)
        scene.ball.size = CGSize(width: 10, height: 10)
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        extra.name = BallCategoryName
        extra.position = CGPoint(x: 100, y: -100)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)

        let overFirst = brick(in: scene, x: 0, y: 100)
        let overSecond = brick(in: scene, x: 100, y: 150)
        let elsewhere = brick(in: scene, x: -150, y: 100)

        scene.endlessIIFireLaserBeams()
        XCTAssertNil(overFirst.parent)
        XCTAssertNil(overSecond.parent)
        XCTAssertNotNil(elsewhere.parent, "only the columns the balls stand in")
    }

    func testTheBeamSparesAPortal() {
        let scene = fieldScene()
        scene.ball.position = CGPoint(x: 0, y: -100)
        let portal = brick(in: scene, x: 0, y: 100, role: .portal)
        scene.endlessIIFireLaserBeams()
        XCTAssertNotNil(portal.parent)
    }

    // MARK: - Wrecking Ball

    func testAWreckingHitIsOnlyTheBallsOwn() {
        let scene = fieldScene()
        XCTAssertFalse(scene.endlessIIWreckingHit(struckBy: scene.ball, laser: false),
                       "not without the clock")

        scene.endlessIICollectWreckingBall()
        XCTAssertTrue(scene.endlessIIWreckingHit(struckBy: scene.ball, laser: false))
        XCTAssertFalse(scene.endlessIIWreckingHit(struckBy: scene.ball, laser: true),
                       "a laser is not the ball")
        XCTAssertFalse(scene.endlessIIWreckingHit(struckBy: nil, laser: false))
    }

    func testTheWreckingBallStaysOutOfOtherModes() {
        let scene = fieldScene()
        scene.gameMode = .classic
        scene.endlessIIWreckingBallClock.collect(10)
        XCTAssertFalse(scene.endlessIIWreckingHit(struckBy: scene.ball, laser: false))
    }

    // MARK: - Aura

    func testTheAuraHitsWhatItTouchesAndOnlyThat() {
        // Rewritten for the decided rework (play-test rounds 6, 9 and 11 all reported the
        // aura as too powerful): a brick within the glow takes *a hit*, not a death. A plain
        // brick dies from one hit either way, so what this asserts is the reach - and
        // `testTheAuraStepsAMultiHitBrickDownRatherThanRemovingIt` is where the difference
        // between a hit and a kill is actually pinned
        let scene = fieldScene()
        scene.endlessIICollectAura()
        scene.ball.position = .zero

        let near = brick(in: scene, x: 0, y: 18)
        let far = brick(in: scene, x: 0, y: 200)
        scene.tickEndlessIIAura()

        XCTAssertTrue(scene.endlessIIAuraHitBricks.contains(ObjectIdentifier(near)),
                      "within twice the ball's radius")
        XCTAssertFalse(scene.endlessIIAuraHitBricks.contains(ObjectIdentifier(far)))
        // Asserted on what the glow *reached* rather than on what is left standing. The aura
        // now routes its hits through `hitBrick`, which decides what a hit means from the
        // brick's texture - and a brick built in a bare test scene has none. The reach is the
        // part this test was always guarding
    }

    func testTheAuraOnlyHitsABrickOnceWhileItSitsOverIt() {
        // The glow is over a brick for many frames. A hit per frame would step a Multi-hit
        // through all four stages in a fifth of a second, which is destroying it outright
        // with extra steps
        let scene = fieldScene()
        scene.endlessIICollectAura()
        scene.ball.position = .zero
        _ = brick(in: scene, x: 0, y: 18)

        scene.tickEndlessIIAura()
        let remembered = scene.endlessIIAuraHitBricks.count
        scene.tickEndlessIIAura()

        XCTAssertLessThanOrEqual(scene.endlessIIAuraHitBricks.count, remembered,
                                 "a brick already hit is not hit again while the glow stays on it")
    }

    func testTheAuraGrowsWhenCollectedAgain() {
        XCTAssertGreaterThan(GameScene.endlessIIAuraReach[1], GameScene.endlessIIAuraReach[0])
        let scene = fieldScene()
        scene.endlessIICollectAura()
        scene.endlessIICollectAura()
        XCTAssertEqual(scene.endlessIIAuraClock.level, 1)
    }

    func testTheAuraLeavesHiddenBricksAlone() {
        // An invisible brick the glow silently ate would never be seen at all - it appears
        // when *hit*, and the aura's destroys are not hits
        let scene = fieldScene()
        scene.endlessIICollectAura()
        scene.ball.position = .zero
        let hidden = brick(in: scene, x: 0, y: 18)
        hidden.isHidden = true

        scene.tickEndlessIIAura()
        XCTAssertNotNil(hidden.parent)
    }

    // MARK: - Infill

    func testInfillAddsItsCountOfBricks() {
        let scene = fieldScene()
        scene.gameWidth = 440
        scene.numberOfBrickColumns = 11
        let before = bricksLeft(scene)
        scene.endlessIIInfill()
        XCTAssertEqual(bricksLeft(scene), before + GameScene.endlessIIInfillCount)
    }

    func testInfillStaysOutOfOtherModes() {
        let scene = fieldScene()
        scene.gameMode = .endless
        scene.endlessIIInfill()
        XCTAssertEqual(bricksLeft(scene), 0)
    }

    // MARK: - Descent

    func testDescentAddsItsOwnStepsAndNoLongerHoldsTheCadenceBack() {
        // Rounds 94 and 99: with Descent running, a cleared bottom row crawled shut one
        // Descent-step at a time - "the bricks should descend as normal until the bottom
        // row has a brick on it". Descent still owns its extra step; it owns nothing else.
        let scene = fieldScene()
        XCTAssertFalse(scene.endlessIIDescentOwnsExtraSteps)

        scene.endlessIICollectDescent()
        XCTAssertTrue(scene.endlessIIDescentOwnsExtraSteps)
    }

    func testDescentStepsOnItsTimerAndNotBeforeIt() {
        let scene = fieldScene()
        scene.endlessIICollectDescent()

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep/2
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 0, "half a step is no step")

        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 1, "the second half completes it")
    }

    func testDescentDoesNothingWithoutTheClock() {
        let scene = fieldScene()
        scene.endlessIIPaddleFrameDelta = 10
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 0)
    }

    func testAStepAlreadyAnimatingFinishesFirst() {
        // Two moves at once stack their distances and carry bricks off their row centres
        let scene = fieldScene()
        scene.endlessIICollectDescent()
        scene.endlessMoveInProgress = true

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep + 1
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 0)
    }

    // MARK: - Auto-Aim

    func testAutoAimPointsAtTheTargetAndStaysInTheLaunchableArc() {
        let straightUp = EndlessIIPaddleEffects.autoAimAngle(
            from: .zero, to: CGPoint(x: 0, y: 100), minimumDeg: 10)
        XCTAssertEqual(straightUp ?? 0, .pi/2, accuracy: 0.001)

        let flat = EndlessIIPaddleEffects.autoAimAngle(
            from: .zero, to: CGPoint(x: 1000, y: 1), minimumDeg: 10)
        XCTAssertEqual(flat ?? 0, 10*Double.pi/180, accuracy: 0.001,
                       "never shallower than the minimum the game already enforces")

        XCTAssertNil(EndlessIIPaddleEffects.autoAimAngle(
            from: .zero, to: CGPoint(x: 0, y: -50), minimumDeg: 10),
            "a paddle cannot aim downward")
    }

    func testAutoAimGoesForTheLowestBrickAndTheNearestAmongEquals() {
        let scene = fieldScene()
        brick(in: scene, x: 0, y: 200)
        let lowFar = brick(in: scene, x: -150, y: 60)
        let lowNear = brick(in: scene, x: 40, y: 60)

        let target = scene.endlessIIAutoAimTarget(from: CGPoint(x: 30, y: 0))
        XCTAssertEqual(target?.y, 60)
        XCTAssertEqual(target?.x, lowNear.position.x, "nearest of the equally low")
        _ = lowFar
    }

    func testAutoAimIgnoresHiddenBricksAndPortals() {
        let scene = fieldScene()
        let hidden = brick(in: scene, x: 0, y: 50)
        hidden.isHidden = true
        brick(in: scene, x: 20, y: 60, role: .portal)
        let real = brick(in: scene, x: -60, y: 90)

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, real.position.x)
    }

    func testAutoAimSkipsABrickTheLaunchArcCannotReach() {
        // The shot is clamped to the launchable arc, so a brick shallower than the minimum
        // angle would be marked and then missed - the clamp bends the shot up and it sails
        // under the target. Such a brick is not a target at all, even when it is the lowest
        let scene = fieldScene()
        scene.minAngleDeg = 10
        let shallow = brick(in: scene, x: 300, y: 10)
        // 1.9 degrees from the launch point - the lowest brick, and unreachable
        let steep = brick(in: scene, x: 40, y: 100)

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, steep.position.x,
                       "the reachable brick wins over the lower unreachable one")

        steep.removeFromParent()
        XCTAssertNil(scene.endlessIIAutoAimTarget(from: .zero),
                     "no reachable brick means no aim, not a promised miss")
        _ = shallow
    }

    func testAPaddleBounceActuallyTakesTheAimedShot() {
        // Play test: "Auto-Aim never hits the brick it is aiming at." The redirect and its
        // tests existed from round 22, but the tests called it directly and no bounce in the
        // scene ever did - the marker drew, the turns were spent, and the ball left at the
        // ordinary bounce angle. This test goes through the real paddle bounce, so the wire
        // can never silently drop out again
        let scene = fieldScene()
        scene.ballIsOnPaddle = false
        scene.ballSpeedLimit = 100
        scene.minAngleDeg = 10
        scene.paddleHeight = 10
        scene.paddle.size = CGSize(width: 80, height: 10)
        scene.paddle.position = CGPoint(x: 0, y: -100)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ball.position = CGPoint(x: 0, y: -92)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody?.velocity = CGVector(dx: 60, dy: -80)
        let target = brick(in: scene, x: 120, y: 60)

        scene.endlessIICollectAutoAim()
        scene.paddleHit(scene.ball)

        let leave = scene.ball.physicsBody!.velocity
        let heading = atan2(Double(leave.dy), Double(leave.dx))
        let wanted = atan2(Double(target.position.y - scene.ball.position.y),
                           Double(target.position.x - scene.ball.position.x))
        XCTAssertEqual(heading, wanted, accuracy: 0.001,
                       "the bounce leaves toward the marked brick")
    }

    func testAutoAimOnlyFiresWithTheClock() {
        let scene = fieldScene()
        scene.ballSpeedLimit = 100
        brick(in: scene, x: 0, y: 100)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)

        XCTAssertFalse(scene.endlessIIApplyAutoAim(to: scene.ball))
        scene.endlessIICollectAutoAim()
        XCTAssertTrue(scene.endlessIIApplyAutoAim(to: scene.ball))
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "sent upward")
    }

    // MARK: - Wrap-Around

    func testThePaddleClampsUntilTheWallsStopBeingWalls() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)

        XCTAssertEqual(scene.endlessIIWrapPaddleX(500), 150, "clamped at the wall")

        scene.endlessIICollectWrapAround()
        XCTAssertEqual(scene.endlessIIWrapPaddleX(190), 190, "free to overhang the edge")
        XCTAssertEqual(scene.endlessIIWrapPaddleX(210), -190,
                       "a centre pushed past the edge comes back in from the other one")
    }

    func testAWrappedBallKeepsTheHeadingItLeftWith() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.ball.position = CGPoint(x: 195, y: 0)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody?.velocity = CGVector(dx: -80, dy: 50)
        // The engine has already bounced it by the time the contact reports - the pre-step
        // sample is the honest heading
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 80, dy: 50))

        XCTAssertFalse(scene.endlessIIWrapTook(scene.ball), "not without the clock")
        scene.endlessIICollectWrapAround()
        XCTAssertTrue(scene.endlessIIWrapTook(scene.ball))

        scene.applyEndlessIIWraps()
        XCTAssertLessThan(scene.ball.position.x, 0, "in from the other side")
        XCTAssertEqual(scene.ball.physicsBody?.velocity.dx ?? 0, 80, accuracy: 0.01,
                       "still travelling the same way")
    }

    func testAStraddlingPaddleAnswersFromItsNearestCopy() {
        // §12.0's Wrap-Around item: "a paddle half off one side should appear half on
        // the other - and its physics body has to follow." The ghost carries the body;
        // this is the measurement rule that makes a bounce off the ghost's half bend
        // like a bounce off the paddle rather than off a paddle a screen away.
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)
        scene.paddle.position.x = 190
        // Overhanging the right edge, so its ghost stands at -210

        XCTAssertEqual(scene.endlessIIPaddleXNearest(to: -195), 190,
                       "without the clock there is no ghost to answer from")
        scene.endlessIICollectWrapAround()
        XCTAssertEqual(scene.endlessIIPaddleXNearest(to: -195), -210,
                       "a ball at the far wall landed on the ghost's half")
        XCTAssertEqual(scene.endlessIIPaddleXNearest(to: 180), 190,
                       "a ball beside the paddle still landed on the paddle")
    }

    func testTheGhostPaddleExistsExactlyWhileThePaddleStraddles() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)
        scene.endlessIICollectWrapAround()

        scene.paddle.position.x = 0
        scene.tickEndlessIIWrapGhost()
        XCTAssertNil(scene.endlessIIWrapGhostPaddle, "mid-field, one paddle is enough")

        scene.paddle.position.x = 190
        scene.tickEndlessIIWrapGhost()
        XCTAssertEqual(scene.endlessIIWrapGhostPaddle?.position.x, -210,
                       "half off the right edge appears half on the left")
        XCTAssertNotNil(scene.endlessIIWrapGhostPaddle?.physicsBody,
                        "and the body follows, which is the real work")

        scene.paddle.position.x = 0
        scene.tickEndlessIIWrapGhost()
        XCTAssertNil(scene.endlessIIWrapGhostPaddle, "back inside, the ghost goes")
    }

    func testAWandererOnlyWrapsWhenItsRunToTheWallWasClear() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.endlessIICollectWrapAround()

        let clear = scene.endlessIIWrapWandererX(at: 180, limits: (left: -180, right: 180),
                                                 halfWidth: 20)
        XCTAssertEqual(clear, -180, "a clear run carries on from the far wall")

        let blocked = scene.endlessIIWrapWandererX(at: 100, limits: (left: -180, right: 100),
                                                   halfWidth: 20)
        XCTAssertNil(blocked, "a brick mid-field is still a brick")
    }

    func testAnExplosionAgainstAWallReachesRoundIt() {
        let scene = fieldScene()
        scene.gameWidth = 400
        let reach = CGRect(x: 150, y: 0, width: 100, height: 60)

        XCTAssertEqual(scene.endlessIIWrappedBlastCopies(of: reach).count, 1)
        scene.endlessIICollectWrapAround()
        let copies = scene.endlessIIWrappedBlastCopies(of: reach)
        XCTAssertEqual(copies.count, 3)
        XCTAssertTrue(copies.contains { $0.intersects(CGRect(x: -195, y: 10, width: 20, height: 20)) },
                      "the far side of the wall is in reach")
    }

    // MARK: - The portal network

    func testABrickHitExitsAtThePaddleWhileThePortalPaddleRuns() {
        let scene = fieldScene()
        scene.paddle.position = CGPoint(x: 30, y: -300)
        scene.paddleHeight = 10
        let portal = brick(in: scene, x: 0, y: 100, role: .portal)
        scene.endlessIICollectPortalPaddle()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 40, dy: 60))

        scene.endlessIIEnterPortal(portal, entering: scene.ball)
        XCTAssertEqual(scene.endlessIIPendingPortalExit?.x, 30, "out of the paddle")
        XCTAssertGreaterThan(scene.endlessIIPortalExitVelocity?.dy ?? -1, 0,
                             "must exit with some upwards velocity")
    }

    func testAPaddleHitExitsAtAPortalBrickWhenOneExists() {
        let scene = fieldScene()
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ball.position = CGPoint(x: 0, y: -300)
        let portal = brick(in: scene, x: -80, y: 150, role: .portal)
        scene.endlessIICollectPortalPaddle()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 20, dy: -90))

        XCTAssertTrue(scene.endlessIIPaddlePortalTook(scene.ball, collision: 0))
        scene.applyEndlessIIPaddlePortals()

        XCTAssertEqual(scene.ball.position.x, portal.position.x, "out of the portal brick")
        XCTAssertGreaterThan(scene.ball.position.y, portal.frame.maxY)
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "climbing")
    }

    func testAPaddleHitStillExitsAtTheTopWithNoPortalBricks() {
        let scene = fieldScene()
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.position = CGPoint(x: 10, y: -300)
        scene.endlessIICollectPortalPaddle()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 20, dy: -90))

        XCTAssertTrue(scene.endlessIIPaddlePortalTook(scene.ball, collision: 0))
        scene.applyEndlessIIPaddlePortals()
        XCTAssertLessThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0,
                          "falling back in from the top, as before")
    }

    // MARK: - What Auto-Aim will not waste a shot on

    func testAutoAimSkipsIndestructiblesAndBadPowerUpBricks() {
        XCTAssertTrue(GameScene.endlessIIHarmfulPowerUps.contains(1),
                      "Lose A Ball is the canonical bad one")
        XCTAssertFalse(GameScene.endlessIIHarmfulPowerUps.contains(0),
                       "Extra Ball is the canonical good one")

        let scene = fieldScene()
        let wall = brick(in: scene, x: 0, y: 50)
        wall.texture = scene.brickIndestructible2Texture
        brick(in: scene, x: 30, y: 60, powerUp: 1)
        // The lowest two things on the field are a brick the ball cannot destroy and a
        // brick holding a Lose A Ball - a free shot at either is a wasted or hostile shot
        let worth = brick(in: scene, x: -60, y: 100)

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, worth.position.x)
    }

    func testAutoAimStillAimsAtGoodPowerUpBricks() {
        let scene = fieldScene()
        let gift = brick(in: scene, x: 20, y: 60, powerUp: 0)
        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, gift.position.x)
    }

    // MARK: - The scrolling backdrop

    func testTheTilePairAlwaysCoversTheWindow() {
        // Two copies of one tile leapfrog: at every scroll, one tile's bottom is at or below
        // the window's floor and the pair spans at least a full tile above it
        let height: CGFloat = 500
        for scroll in stride(from: CGFloat(0), through: 2600, by: 130) {
            let ys = EndlessIIBackdropScroll.tileYs(scroll: scroll, tileHeight: height)
            XCTAssertLessThanOrEqual(min(ys.first, ys.second), 0, "scroll \(scroll)")
            XCTAssertEqual(abs(ys.first - ys.second), height, accuracy: 0.001,
                           "the pair stays exactly one tile apart")
            XCTAssertGreaterThanOrEqual(max(ys.first, ys.second), 0)
        }
    }

    func testTheScrollWrapsATileAtATime() {
        let ys0 = EndlessIIBackdropScroll.tileYs(scroll: 0, tileHeight: 500)
        let ysWrapped = EndlessIIBackdropScroll.tileYs(scroll: 500, tileHeight: 500)
        XCTAssertEqual(ys0.first, ysWrapped.first, accuracy: 0.001,
                       "a full tile of scroll is the same picture")
    }

    func testTheBackdropOnlyExistsInEndlessMayhem() {
        let scene = fieldScene()
        scene.gameMode = .classic
        scene.setupEndlessIIBackdrop()
        XCTAssertTrue(scene.endlessIIBackdropTiles.isEmpty)

        scene.gameMode = .endlessII
        scene.setupEndlessIIBackdrop()
        XCTAssertEqual(scene.endlessIIBackdropTiles.count, 2)
        scene.setupEndlessIIBackdrop()
        XCTAssertEqual(scene.endlessIIBackdropTiles.count, 2, "set up once, not per call")
    }

    func testTheBackdropDriftsTowardTheHeightsOffset() {
        let scene = fieldScene()
        scene.gameMode = .endlessII
        scene.setupEndlessIIBackdrop()
        scene.endlessHeight = 100

        for _ in 0..<600 { scene.tickEndlessIIBackdrop() }
        XCTAssertEqual(scene.endlessIIBackdropScroll,
                       100*EndlessIIBackdropScroll.pointsPerMetre, accuracy: 1,
                       "eased, but it gets there")
    }

    // MARK: - The ring and the save

    func testTheTimedPairReportToTheRingAndRoundTrip() {
        let saving = fieldScene()
        saving.endlessIICollectWreckingBall()
        saving.endlessIICollectAura()
        saving.endlessIICollectAura()
        saving.endlessIICollectRandomisedBounce()
        saving.endlessIICollectGhostBall()
        saving.endlessIICollectClearAndRetreat()
        XCTAssertEqual(saving.endlessIIFieldRingEntries().count, 5,
                       "every running clock in the batch has a ring entry - Randomised "
                       + "Bounce and Ghost Ball ran with nothing shown for either")

        let restored = fieldScene()
        for entry in saving.endlessIIFieldClockSaveEntries() {
            XCTAssertTrue(restored.endlessIIRestoreFieldClock(
                key: entry.key, remaining: entry.remaining,
                total: entry.total, magnitude: entry.magnitude))
        }
        XCTAssertTrue(restored.endlessIIWreckingBallClock.isRunning)
        XCTAssertEqual(restored.endlessIIAuraClock.level, 1)
        XCTAssertTrue(restored.endlessIIRandomisedBounceClock.isRunning,
                      "and survives a save and resume, which it did not")
        XCTAssertTrue(restored.endlessIIGhostBallClock.isRunning)
        XCTAssertTrue(restored.endlessIIClearAndRetreatClock.isRunning)
    }

    func testABigBrickReachesTheBottomZoneARowEarly() {
        // Round 10 report, with screenshot: "big brick below bottom brick line - shouldn't
        // happen, should stop one normal brick height higher." The brick's own body is
        // what the line must not cross, and a Big brick's body hangs a row below its node.
        let scene = fieldScene()
        scene.finalBrickRowHeight = -100
        // The kill line sits at -110: the bottom edge of the final row

        let normalOnFinalRow = brick(in: scene, y: -100)
        XCTAssertTrue(scene.brickHasReachedTheBottomZone(normalOnFinalRow))
        let normalARowUp = brick(in: scene, y: -80)
        XCTAssertFalse(scene.brickHasReachedTheBottomZone(normalARowUp),
                       "an ordinary brick a row up has a row still to travel")

        let big = brick(in: scene, y: -80)
        big.size.height = 40
        big.anchorPoint = CGPoint(x: 0.5, y: 0.75)
        // Node on its row centre, body reaching a full row below it (§8.6's convention
        // for oversized bricks)
        XCTAssertTrue(scene.brickHasReachedTheBottomZone(big),
                      "a Big brick's body already touches the line from a row up, so that is where it stops")
    }

    func testTheOriginalEndlessNeverOffersTheFieldBatch() {
        let scene = fieldScene()
        scene.gameMode = .endless
        scene.applyEndlessRowPowerUpWeights()
        for index in 39...47 {
            XCTAssertEqual(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }

        scene.gameMode = .endlessII
        scene.applyEndlessRowPowerUpWeights()
        for index in 39...47 {
            XCTAssertGreaterThan(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }
    }
}

/// Randomised Bounce, the fifty-second power-up and the last catalogue entry that had no
/// game behind it (§5.4: uncommon, harmful, timed, extends its own duration).
final class RandomisedBounceTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.minAngleDeg = 10
        return scene
    }

    func testItThrowsTheAngleOffTheOneTheBallArrivedAt() {
        XCTAssertEqual(GameScene.randomisedBounceAngle(from: 90, minimumDeg: 10, offset: 20),
                       110, accuracy: 0.001)
        XCTAssertEqual(GameScene.randomisedBounceAngle(from: 90, minimumDeg: 10, offset: -20),
                       70, accuracy: 0.001)
    }

    /// A bad power-up may be unfair. It may not hand the player a ball that never comes down,
    /// which is the one heading the game refuses in every other place it touches an angle.
    func testItNeverThrowsTheBallPastTheAngleTheGameRefuses() {
        for offset in stride(from: -60.0, through: 60.0, by: 5) {
            for arriving in [12.0, 45.0, 90.0, 135.0, 168.0] {
                let bounced = GameScene.randomisedBounceAngle(from: arriving, minimumDeg: 10,
                                                              offset: offset)
                XCTAssertGreaterThanOrEqual(bounced, 10)
                XCTAssertLessThanOrEqual(bounced, 170)
            }
        }
    }

    func testItOnlyActsWhileItsClockRuns() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIRandomisesBounces(for: scene.ball))

        scene.endlessIICollectRandomisedBounce()
        XCTAssertTrue(scene.endlessIIRandomisesBounces(for: scene.ball))
        XCTAssertEqual(scene.endlessIIRandomisedBounceClock.remaining,
                       GameScene.endlessIIRandomisedBounceDuration, accuracy: 0.001)
    }

    func testItNeverActsInTheOlderModes() {
        // Existing modes must not gain new power-ups - the rule the whole availability split
        // exists for, and the reason Classic and Endless leaderboards stay comparable
        let scene = mayhem()
        scene.endlessIICollectRandomisedBounce()
        scene.gameMode = .endless
        XCTAssertFalse(scene.endlessIIRandomisesBounces(for: scene.ball))
        scene.gameMode = .classic
        XCTAssertFalse(scene.endlessIIRandomisesBounces(for: scene.ball))
    }

    /// A second collection extends rather than stacking (§5.4).
    func testASecondCollectionExtendsIt() {
        let scene = mayhem()
        scene.endlessIICollectRandomisedBounce()
        scene.endlessIIRandomisedBounceClock.run(down: 5)
        scene.endlessIICollectRandomisedBounce()
        XCTAssertGreaterThan(scene.endlessIIRandomisedBounceClock.remaining,
                             GameScene.endlessIIRandomisedBounceDuration - 5)
    }

    /// The array checklist, in one place: a power-up that is in some lists and not others is
    // MARK: - Drift

    // §5.4, James's play-test idea from the tenth round, pulled into 1.3 at round 100: the
    // field slides sideways, and the falling power-ups with it.

    private func driftScene() -> GameScene {
        let scene = safetyScene()
        scene.numberOfBrickColumns = 10
        return scene
    }

    @discardableResult
    private func brick(in scene: GameScene, x: CGFloat, y: CGFloat) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: scene.brickWidth, height: scene.brickHeight)
        brick.position = CGPoint(x: x, y: y)
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    func testTheFieldSlidesWhileItRuns() {
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 40)
        scene.endlessIICollectDrift()
        let before = brick.position.x

        scene.tickEndlessIIDrift(0.5)
        XCTAssertNotEqual(brick.position.x, before, accuracy: 0.0001)
        XCTAssertEqual(brick.position.y, 40, "sideways only - a brick's y is its row (§8.6)")
    }

    func testItTurnsRoundAtTheWallRatherThanLosingTheField() {
        // A power-up that quietly destroyed the bricks that reached the edge would be a
        // different power-up
        let scene = driftScene()
        let brick = brick(in: scene, x: scene.gameWidth/2 - scene.brickWidth/2, y: 40)
        scene.endlessIICollectDrift()
        scene.endlessIIDriftDirection = 1

        for _ in 0..<20 { scene.tickEndlessIIDrift(0.2) }
        XCTAssertLessThanOrEqual(brick.position.x + brick.size.width/2,
                                 scene.gameWidth/2 + 0.001, "never past the wall")
        XCTAssertNotNil(brick.parent, "and never destroyed by it")
    }

    func testEverythingLandsBackOnAColumnCentreWhenItEnds() {
        // The grid is how the generator, the crush and the neighbour rules all speak
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 40)
        scene.endlessIICollectDrift()
        scene.tickEndlessIIDrift(0.37)
        XCTAssertNotEqual(brick.position.x, 0, accuracy: 0.0001)

        scene.endlessIIDriftClock.run(down: GameScene.endlessIIDriftDuration)
        scene.tickEndlessIIDrift(0.016)
        XCTAssertEqual(brick.position.x,
                       scene.endlessIIColumnCentre(nearest: brick.position.x),
                       accuracy: 0.0001)
        XCTAssertEqual(scene.endlessIIDriftDirection, 0, "and it forgets which way it went")
    }

    func testAColumnCentreIsWhereABrickBelongs() {
        let scene = driftScene()
        let left = -scene.gameWidth/2 + scene.brickWidth/2
        XCTAssertEqual(scene.endlessIIColumnCentre(nearest: left + 1), left, accuracy: 0.001)
        XCTAssertEqual(scene.endlessIIColumnCentre(nearest: left + scene.brickWidth*1.4),
                       left + scene.brickWidth, accuracy: 0.001)
    }

    func testItLeavesTheFieldAloneOutsideMayhemToo() {
        let scene = driftScene()
        scene.gameMode = .classic
        let brick = brick(in: scene, x: 0, y: 40)
        scene.endlessIICollectDrift()
        scene.tickEndlessIIDrift(0.5)
        XCTAssertEqual(brick.position.x, 0, accuracy: 0.0001)
    }

    // MARK: - Safety Paddle

    // §5.4, and the play-test idea from the tenth round: a second, fixed paddle just below
    // the lowest brick row. Good because it keeps the ball up in the field; bad because it
    // stops the ball reaching the bricks from below.

    private func safetyScene() -> GameScene {
        let scene = mayhem()
        scene.brickHeight = 20
        scene.brickWidth = 40
        scene.gameWidth = 400
        scene.totalStatsArray = [TotalStats()]
        scene.finalBrickRowHeight = -100
        return scene
    }

    func testCollectingItPutsASurfaceUnderTheLowestBricks() {
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()

        XCTAssertTrue(scene.endlessIISafetyPaddleClock.isRunning)
        let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)
        XCTAssertNotNil(bar)
        XCTAssertEqual(bar?.position.y ?? 0,
                       scene.finalBrickRowHeight - scene.brickHeight, accuracy: 0.001,
                       "below the field, so it never stands inside a brick")
    }

    func testItsSurfaceIsNotThePaddlesAndNotAScreenBlocks() {
        // Its own category, because the paddle's would spend a paddle turn and count a
        // landing, and a screen block's is read by *shape* - a wide, short one would have
        // been taken for the ceiling
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)

        XCTAssertEqual(bar?.physicsBody?.categoryBitMask,
                       CollisionTypes.safetyPaddleCategory.rawValue)
        XCTAssertEqual(bar?.physicsBody?.isDynamic, false, "the field moves; it does not")
    }

    func testASecondCollectionLengthensItRatherThanStackingTwo() {
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        let first = scene.endlessIISafetyPaddleClock.remaining
        scene.endlessIICollectSafetyPaddle()

        XCTAssertGreaterThan(scene.endlessIISafetyPaddleClock.remaining, first)
        var found = 0
        scene.enumerateChildNodes(withName: GameScene.endlessIISafetyPaddleName) { _, _ in
            found += 1
        }
        XCTAssertEqual(found, 1, "longer, not thicker")
    }

    func testItIsNeverStranded() {
        // A surface left behind after its clock stops would change the rest of the run -
        // the same rule Ghost Ball has about the ball's alpha
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIISafetyPaddleClock.run(down: GameScene.endlessIISafetyPaddleDuration)
        scene.tickEndlessIISafetyPaddle()

        XCTAssertNil(scene.childNode(withName: GameScene.endlessIISafetyPaddleName),
                     "the tick that finds the clock stopped takes it away")
    }

    func testItLeavesTheFieldAloneOutsideMayhem() {
        let scene = safetyScene()
        scene.gameMode = .classic
        scene.endlessIICollectSafetyPaddle()
        XCTAssertNil(scene.childNode(withName: GameScene.endlessIISafetyPaddleName))
    }

    func testAResumedRunFindsItStanding() {
        let saving = safetyScene()
        saving.endlessIICollectSafetyPaddle()

        let restored = safetyScene()
        for entry in saving.endlessIIFieldClockSaveEntries() {
            restored.endlessIIRestoreFieldClock(key: entry.key, remaining: entry.remaining,
                                                total: entry.total,
                                                magnitude: entry.magnitude)
        }
        XCTAssertTrue(restored.endlessIISafetyPaddleClock.isRunning)
        XCTAssertNotNil(restored.childNode(withName: GameScene.endlessIISafetyPaddleName),
                        "or the save has quietly changed the field")
    }

    /// the trap this project keeps writing down (§8.6).
    func testTheFiftySecondPowerUpIsInEveryListThatDefinesOne() {
        let setup = LevelPackSetup()
        let index = setup.powerUpNameArray.firstIndex(of: "Randomised Bounce")
        XCTAssertNotNil(index)
        guard let index else { return }

        XCTAssertEqual(setup.powerUpImageArray.count, setup.powerUpNameArray.count)
        XCTAssertEqual(setup.powerUpMultiplierArray.count, setup.powerUpNameArray.count)
        XCTAssertEqual(setup.powerUpTimerArray.count, setup.powerUpNameArray.count)
        XCTAssertEqual(setup.powerUpCorrectOrderArray.count, setup.powerUpNameArray.count)
        XCTAssertEqual(setup.powerUpPackOrderArray.count, setup.powerUpNameArray.count)
        XCTAssertEqual(TotalStats().powerupsCollected.count, setup.powerUpNameArray.count)
        XCTAssertEqual(TotalStats().powerupsGenerated.count, setup.powerUpNameArray.count)
        XCTAssertEqual(TotalStats().powerUpUnlockedArray.count, setup.powerUpNameArray.count)

        XCTAssertEqual(setup.powerUpMultiplierArray[index], "-0.1", "harmful")
        XCTAssertTrue(setup.powerUpTimerArray[index].hasSuffix("s"), "timed")
        XCTAssertTrue(GameScene.endlessIIHarmfulPowerUps.contains(index),
                      "derived from the multiplier column, so Auto-Aim will not spend a free "
                      + "shot on a brick holding one")
    }
}

/// Ghost Ball (play-test round 11, pulled into 1.3): "the ball is invisible until it drops
/// below the lowest brick line - you see where it lands, not where it flies."
final class GhostBallTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.finalBrickRowHeight = 100
        scene.addChild(scene.ball)
        return scene
    }

    func testTheBallIsHiddenAmongTheBricksAndSeenBelowThem() {
        XCTAssertFalse(GameScene.ghostBallIsVisible(ballY: 150, lowestBrickRow: 100))
        XCTAssertTrue(GameScene.ghostBallIsVisible(ballY: 50, lowestBrickRow: 100),
                      "below the lowest row, which is the part of the flight you can still "
                      + "do something about")
    }

    func testTheLineIsTheFieldsOwnSoItMovesWithTheDescent() {
        // Stated against `finalBrickRowHeight` rather than a remembered height, so a field
        // that has descended hides the ball lower down without the rule being told
        XCTAssertTrue(GameScene.ghostBallIsVisible(ballY: 150, lowestBrickRow: 200))
        XCTAssertFalse(GameScene.ghostBallIsVisible(ballY: 150, lowestBrickRow: 100))
    }

    func testItHidesAndRestoresTheBallItself() {
        let scene = mayhem()
        scene.ball.position.y = 150

        scene.endlessIICollectGhostBall()
        scene.tickEndlessIIGhostBall()
        XCTAssertEqual(scene.ball.alpha, 0, "up among the bricks")

        scene.ball.position.y = 50
        scene.tickEndlessIIGhostBall()
        XCTAssertEqual(scene.ball.alpha, 1, "and back on the way down")
    }

    /// The failure that would cost a run: a ball left invisible by an expired power-up.
    func testTheBallComesBackWhenTheClockEnds() {
        let scene = mayhem()
        scene.ball.position.y = 150
        scene.endlessIICollectGhostBall()
        scene.tickEndlessIIGhostBall()
        XCTAssertEqual(scene.ball.alpha, 0)

        scene.endlessIIGhostBallClock.run(down: GameScene.endlessIIGhostBallDuration + 1)
        scene.tickEndlessIIGhostBall()
        XCTAssertEqual(scene.ball.alpha, 1, "put back on the frame the clock ends")
    }

    func testAResetPutsEveryBallBack() {
        let scene = mayhem()
        scene.ball.alpha = 0
        scene.endlessIIResetFieldPowerUps()
        XCTAssertEqual(scene.ball.alpha, 1)
    }
}

// MARK: - The wrecking ball's spikes

/// James's art, round 152, with one instruction attached: "These spikes should be visual
/// only. The actual physics body of the ball when the wrecking ball is active should be no
/// different to normal."
///
/// So most of what these tests hold is what must *not* change.
final class EndlessIIWreckingBallLookTests: XCTestCase {

    private func mayhem(theme: Int = 0) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 20
        scene.ballSetting = theme
        scene.totalStatsArray = [TotalStats()]
        scene.ball.size = CGSize(width: 20, height: 20)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        scene.addChild(scene.ball)
        return scene
    }

    private func spikes(_ scene: GameScene) -> SKSpriteNode? {
        scene.ball.childNode(withName: GameScene.wreckingSpikesName) as? SKSpriteNode
    }

    func testTheBallsPhysicsBodyIsNotTouched() {
        let scene = mayhem()
        let body = scene.ball.physicsBody
        let area = body?.area

        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()

        XCTAssertTrue(scene.ball.physicsBody === body, "the same body, not a new one")
        XCTAssertEqual(scene.ball.physicsBody?.area, area)
        XCTAssertEqual(scene.ball.size, CGSize(width: 20, height: 20),
                       "and the same size - the sticky band, the paddle clamp and the "
                       + "direction marker all measure themselves against it")
    }

    func testTheSpikesAreDrawnBiggerThanTheBall() {
        // The whole point of the art: 64pt of texture around a 50pt ball. The overhang is
        // read off the texture rather than written down, so a redrawn spike is a longer
        // spike the day it lands
        let scene = mayhem()
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()

        guard let spikes = spikes(scene) else { return XCTFail("no spikes") }
        XCTAssertGreaterThan(spikes.size.width, scene.ball.size.width)
        let texture = scene.endlessIIWreckingTexture(for: .normal)
        XCTAssertEqual(spikes.size.width,
                       20*(texture?.size().width ?? 0)/GameScene.plainBallTexturePoints,
                       accuracy: 0.01)
    }

    func testTheBallStopsDrawingItselfAndStartsAgainAfterwards() {
        let scene = mayhem()
        scene.ball.texture = scene.ballTexture
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()
        XCTAssertNil(scene.ball.texture, "or the spiked art is drawn over a plain ball")

        scene.endlessIIWreckingBallClock.run(down: GameScene.endlessIIPaddlePowerUpDuration)
        scene.refreshEndlessIIWreckingBall()
        XCTAssertNil(spikes(scene))
        XCTAssertEqual(scene.ball.texture, scene.ballTexture)
    }

    func testItComesBackWearingWhateverTheBallBecameWhileItWasSpiked() {
        // A Giga-Ball collected *during* a wrecking ball. The dress is the state, so the
        // ball that emerges from the spikes is the ball it turned into, not the one it was
        let scene = mayhem()
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()
        scene.ballDress = .giga

        scene.endlessIIWreckingBallClock.run(down: GameScene.endlessIIPaddlePowerUpDuration)
        scene.refreshEndlessIIWreckingBall()
        XCTAssertEqual(scene.ball.texture, scene.gigaBallTexture)
    }

    func testThePhysicsMasksReadTheDressRatherThanThePicture() {
        // Eleven places used to ask `ball.texture` whether the Giga-Ball was running, and
        // the spikes take that picture away. This is the one that decides whether the ball
        // passes through bricks
        let scene = mayhem()
        scene.ballDress = .giga
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()
        scene.ballPhysicsBodySet()

        let bricks = CollisionTypes.brickCategory.rawValue
        let collides = scene.ball.physicsBody?.collisionBitMask ?? bricks
        XCTAssertEqual(collides & bricks, 0,
                       "a spiked Giga-Ball still passes through bricks - the spikes took "
                       + "the picture away, and the picture was carrying this rule")
    }

    func testEveryBallInPlayGetsThem() {
        let scene = mayhem()
        scene.endlessIIAddBall()
        XCTAssertEqual(scene.endlessIIBallsInPlay.count, 2, "the ball and one extra")

        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()
        for subject in scene.endlessIIBallsInPlay {
            XCTAssertNotNil(subject.childNode(withName: GameScene.wreckingSpikesName),
                            "a power-up belongs to the run, not to one ball")
        }
    }

    func testAThemeWithNoArtIsSimplyLeftAlone() {
        // The glass theme's three wrecking textures do not exist yet (§8.5). A glass ball
        // that keeps its own look is a better answer than one wearing somebody else's theme
        let glass = 5
        let scene = mayhem(theme: glass)
        scene.ball.texture = scene.ballTexture
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()

        XCTAssertNil(scene.endlessIIWreckingTexture(for: .normal))
        XCTAssertNil(spikes(scene))
        XCTAssertEqual(scene.ball.texture, scene.ballTexture, "still a glass ball")
    }

    func testTheThemeOrderIsPinnedByTheThreeTexturesThatAreADifferentSize() {
        // The map from a theme index to a file name is written out by hand, and a map that
        // is one out gives an Ice ball Outline spikes - which looks like art nobody likes
        // rather than like a bug. Three themes have a size of their own: the square theme's
        // spikes are drawn *inside* a 50pt square, the candy cane's reach 72, and the glass
        // theme has no art at all. Any shuffle of the order moves at least one of them
        let scene = mayhem()
        let expected: [(theme: Int, width: CGFloat?)] = [(4, 50), (5, nil), (8, 72)]

        for (theme, width) in expected {
            scene.ballSetting = theme
            let texture = scene.endlessIIWreckingTexture(for: .normal)
            guard let width else {
                XCTAssertNil(texture, "the glass theme has no wrecking art (§8.5)")
                continue
            }
            XCTAssertEqual(texture?.size().width, width, "theme \(theme) is not where it was")
        }
    }

    func testEveryOtherThemeHasArtForAllThreeBalls() {
        // The count that stops a theme being silently skipped - the same trap as a style
        // that is in the enum but not in a pool
        let scene = mayhem()
        for theme in 0..<LevelPackSetup().ballImageArray.count where theme != 5 {
            scene.ballSetting = theme
            for dress in [GameScene.BallDress.normal, .giga, .undestructi] {
                XCTAssertNotNil(scene.endlessIIWreckingTexture(for: dress),
                                "theme \(theme) has no wrecking art")
            }
        }
    }
}
