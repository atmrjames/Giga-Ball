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

    func testTheLowestRowGoesAndTheFieldStepsUp() {
        let scene = fieldScene()
        let low = brick(in: scene, x: 0, y: 40)
        let high = brick(in: scene, x: 0, y: 100)

        scene.endlessIIClearAndRetreat()
        XCTAssertNil(low.parent, "the lowest occupied row is destroyed")
        XCTAssertNotNil(high.parent)
        XCTAssertTrue(high.hasActions(), "the survivor is on its way up a row")
        // The step up is an animation; what matters here is that it was given one and the
        // destroyed row was not
    }

    func testTheLowestRowMeansTheWholeRowNotOneBrick() {
        let scene = fieldScene()
        let left = brick(in: scene, x: -50, y: 40)
        let right = brick(in: scene, x: 50, y: 44)
        // Within half a brick of the same centre - the same row, as the descent reads it

        scene.endlessIIClearAndRetreat()
        XCTAssertNil(left.parent)
        XCTAssertNil(right.parent)
    }

    func testAnEmptyFieldRetreatsNothing() {
        let scene = fieldScene()
        scene.endlessIIClearAndRetreat()
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

    func testTheAuraDestroysWhatItTouchesAndOnlyThat() {
        let scene = fieldScene()
        scene.endlessIICollectAura()
        scene.ball.position = .zero

        let near = brick(in: scene, x: 0, y: 18)
        let far = brick(in: scene, x: 0, y: 200)
        scene.tickEndlessIIAura()

        XCTAssertNil(near.parent, "within twice the ball's radius")
        XCTAssertNotNil(far.parent)
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

    func testDescentSuspendsTheNormalCadenceWhileItRuns() {
        // §5.4: both at once would double-step the field
        let scene = fieldScene()
        XCTAssertFalse(scene.endlessIIDescentSuspendsCadence)

        scene.endlessIICollectDescent()
        XCTAssertTrue(scene.endlessIIDescentSuspendsCadence)
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

        let target = scene.endlessIIAutoAimTarget(from: 30)
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

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: 0)?.x, real.position.x)
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

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: 0)?.x, worth.position.x)
    }

    func testAutoAimStillAimsAtGoodPowerUpBricks() {
        let scene = fieldScene()
        let gift = brick(in: scene, x: 20, y: 60, powerUp: 0)
        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: 0)?.x, gift.position.x)
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
        XCTAssertEqual(saving.endlessIIFieldRingEntries().count, 2)

        let restored = fieldScene()
        for entry in saving.endlessIIFieldClockSaveEntries() {
            XCTAssertTrue(restored.endlessIIRestoreFieldClock(
                key: entry.key, remaining: entry.remaining,
                total: entry.total, magnitude: entry.magnitude))
        }
        XCTAssertTrue(restored.endlessIIWreckingBallClock.isRunning)
        XCTAssertEqual(restored.endlessIIAuraClock.level, 1)
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
