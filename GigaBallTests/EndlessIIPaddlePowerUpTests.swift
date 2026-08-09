//
//  EndlessIIPaddlePowerUpTests.swift
//  GigaBallTests
//
//  Phase 8b's rules, pinned down where they are pure. The clocks, the bounce influence, the
//  pull, the steering clamp, the halo's reach and the aim's default are all arithmetic - the
//  scene only asks them - so this is where each power-up's meaning is written twice.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

// MARK: - The clock every timed power-up runs on

final class EndlessIIClockTests: XCTestCase {

    func testACollectionStartsTheClock() {
        var clock = EndlessIIClock()
        clock.collect(10)
        XCTAssertTrue(clock.isRunning)
        XCTAssertEqual(clock.remaining, 10)
        XCTAssertEqual(clock.fraction, 1)
    }

    func testASecondCollectionExtendsAndTheRingReadsFull() {
        var clock = EndlessIIClock()
        clock.collect(10)
        clock.run(down: 6)
        clock.collect(10)

        XCTAssertEqual(clock.remaining, 14)
        XCTAssertEqual(clock.fraction, 1, "topped up is full, not fourteen tenths")
    }

    func testDeepeningOnlyHappensOnACollectionThatFoundItRunning() {
        var clock = EndlessIIClock()
        clock.collect(10, deepestLevel: 1)
        XCTAssertEqual(clock.level, 0, "the first collection is the base effect")

        clock.collect(10, deepestLevel: 1)
        XCTAssertEqual(clock.level, 1)

        clock.collect(10, deepestLevel: 1)
        XCTAssertEqual(clock.level, 1, "never past the table that defines the steps")
    }

    func testExpiryClearsTheLevelToo() {
        var clock = EndlessIIClock()
        clock.collect(10, deepestLevel: 1)
        clock.collect(10, deepestLevel: 1)
        clock.run(down: 25)

        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.level, 0, "the next collection starts over")
        XCTAssertEqual(clock.fraction, 0)
    }

    func testARestoredClockIsClampedInEveryDirection() {
        // A save is a file on disk read at launch, and the level is used as an index
        var clock = EndlessIIClock()
        clock.restore(remaining: -5, total: -1, level: 9, deepestLevel: 1)
        XCTAssertEqual(clock.remaining, 0)
        XCTAssertEqual(clock.level, 1)

        clock.restore(remaining: 8, total: 4, level: 0)
        XCTAssertGreaterThanOrEqual(clock.total, clock.remaining,
                                    "the ring must never read more than full")
    }
}

// MARK: - The arithmetic of each effect

final class EndlessIIPaddleEffectsTests: XCTestCase {

    func testInertTakesTheInfluenceAwayAndBeatsFlipped() {
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: false, flipped: false), 1)
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: false, flipped: true), -1)
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: true, flipped: false), 0)
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: true, flipped: true), 0,
                       "no influence is also no influence to invert")
    }

    func testReversedControlsIsExactlyASignFlip() {
        XCTAssertEqual(EndlessIIPaddleEffects.controlDirection(reversed: false), 1)
        XCTAssertEqual(EndlessIIPaddleEffects.controlDirection(reversed: true), -1)
    }

    // MARK: Magnetism

    private func pull(_ velocity: CGVector, ballAt ball: CGPoint,
                      paddleAt paddle: CGPoint = .zero) -> CGVector {
        EndlessIIPaddleEffects.magnetised(velocity: velocity, ballAt: ball, paddleAt: paddle,
                                          strength: 1, delta: 1.0/60.0)
    }

    func testAFallingBallIsPulledTowardThePaddle() {
        // Ball falling straight down, paddle off to the right: the pull bends it right
        let bent = pull(CGVector(dx: 0, dy: -100), ballAt: CGPoint(x: -50, y: 100))
        XCTAssertGreaterThan(bent.dx, 0)
        XCTAssertLessThan(bent.dy, 0, "still falling")
    }

    func testThePullPreservesTheBallsSpeed() {
        // Ball speed is a single shared value the whole game protects (§5.5)
        let before = CGVector(dx: 60, dy: -80)
        let after = pull(before, ballAt: CGPoint(x: 30, y: 200))
        let speedBefore = (before.dx*before.dx + before.dy*before.dy).squareRoot()
        let speedAfter = (after.dx*after.dx + after.dy*after.dy).squareRoot()
        XCTAssertEqual(speedAfter, speedBefore, accuracy: 0.001)
    }

    func testARisingBallIsLeftAlone() {
        // Pulling a climbing ball back would shorten every climb - a beneficial power-up
        // must not be a subtle penalty
        let rising = CGVector(dx: 30, dy: 90)
        XCTAssertEqual(pull(rising, ballAt: CGPoint(x: 50, y: 100)), rising)
    }

    func testThePullFadesWithDistance() {
        let near = pull(CGVector(dx: 0, dy: -100), ballAt: CGPoint(x: -50, y: 60))
        let far = pull(CGVector(dx: 0, dy: -100), ballAt: CGPoint(x: -50, y: 400))
        XCTAssertGreaterThan(near.dx, far.dx, "the magnet is a magnet, not a tractor beam")
    }

    func testThePullIsCappedAndTheCapOpensUpNearThePaddle() {
        // "Make the magnetism strong when the ball is near the paddle so it's very hard to
        // miss" - the cap scales with proximity, so near the paddle the pull is hard homing
        // and high in the field it is still only a lean
        let bent = EndlessIIPaddleEffects.magnetised(
            velocity: CGVector(dx: 0, dy: -100), ballAt: CGPoint(x: -200, y: 10),
            paddleAt: .zero, strength: 100, delta: 1.0/60.0)
        let turned = abs(atan2(bent.dy, bent.dx) - atan2(CGFloat(-100), CGFloat(0)))
        let falloff = 1 - 10/EndlessIIPaddleEffects.magnetismReach
        let openedCap = EndlessIIPaddleEffects.magnetismTurnRate
        let boosted = openedCap*(1 + EndlessIIPaddleEffects.magnetismCloseBoost*falloff)/60
        XCTAssertLessThanOrEqual(turned, boosted + 0.001)
        XCTAssertGreaterThan(turned, openedCap/60,
                             "near the paddle the pull exceeds the far cap")
    }

    // MARK: Steering

    func testASteeredBallIsDrawnTowardsThePaddleRatherThanNudgedByIt() {
        // Round 15: "the paddle needs to control the x-position of the ball with some
        // inertia - the ball should forget its original trajectory." So the target is
        // where the paddle *is*, not how far it moved, and the ball closes part of the
        // gap each frame rather than arriving at once.
        let first = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 100, from: 0, leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertGreaterThan(first, 0, "it sets off towards the paddle")
        XCTAssertLessThan(first, 100, "and does not teleport there")

        var x: CGFloat = 0
        for _ in 0..<60 {
            x = EndlessIIPaddleEffects.steeredTowards(paddleX: 100, from: x,
                                                      leftWall: -200, rightWall: 200,
                                                      radius: 5)
        }
        XCTAssertEqual(x, 100, accuracy: 1, "a second of holding still gathers it in")
    }

    func testAStationaryPaddleStillHoldsASteeredBall() {
        // The old version moved the ball by the paddle's *movement*, so a paddle standing
        // still steered nothing and the ball wandered off on its own trajectory - which
        // is what made it feel like the power-up was not working
        let x = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 0, from: 60, leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertLessThan(x, 60, "a still paddle is still pulling")
    }

    func testSteeringCannotPullABallThroughAWall() {
        let x = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 1000, from: 198, leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertEqual(x, 195, "clamped a radius inside the wall")
    }

    func testASteeredBallLosesItsSidewaysSpeedWithoutLosingPace() {
        let before = CGVector(dx: 300, dy: 300)
        let after = EndlessIIPaddleEffects.steeredVelocity(before)
        let speedBefore = (before.dx*before.dx + before.dy*before.dy).squareRoot()
        let speedAfter = (after.dx*after.dx + after.dy*after.dy).squareRoot()

        XCTAssertLessThan(abs(after.dx), abs(before.dx), "the sideways motion bleeds away")
        XCTAssertGreaterThan(after.dy, before.dy, "into the vertical")
        XCTAssertEqual(speedAfter, speedBefore, accuracy: 0.001,
                       "a steered ball is not a slower ball")
    }

    func testSteeringKeepsTheBallGoingTheWayItWasVertically() {
        let falling = EndlessIIPaddleEffects.steeredVelocity(CGVector(dx: -200, dy: -400))
        XCTAssertLessThan(falling.dy, 0, "a falling ball keeps falling")
    }

    // MARK: The halo

    func testTheHaloTouchesABrickWhoseCornerDipsIn() {
        let brick = CGRect(x: 30, y: 20, width: 40, height: 20)
        XCTAssertTrue(EndlessIIPaddleEffects.haloTouches(brick: brick, paddleAt: .zero,
                                                         reach: 40))
        XCTAssertFalse(EndlessIIPaddleEffects.haloTouches(brick: brick, paddleAt: .zero,
                                                          reach: 30))
    }

    func testTheHaloDoesNotReachBelowThePaddle() {
        let below = CGRect(x: -10, y: -50, width: 20, height: 10)
        XCTAssertFalse(EndlessIIPaddleEffects.haloTouches(brick: below, paddleAt: .zero,
                                                          reach: 100))
    }

    // MARK: The aim

    func testTheAimReadsTheFingersAbsolutePosition() {
        // Round 10: "the arrow direction should adjust based on the absolute position of
        // the user's finger. More left on the screen = further left and vice versa."
        let straight = Double.pi/2
        let arc = 70*Double.pi/180
        let centre = EndlessIIPaddleEffects.aimedAngle(fingerFraction: 0,
                                                       straight: straight, maximum: arc)
        let left = EndlessIIPaddleEffects.aimedAngle(fingerFraction: -1,
                                                     straight: straight, maximum: arc)
        let right = EndlessIIPaddleEffects.aimedAngle(fingerFraction: 1,
                                                      straight: straight, maximum: arc)
        XCTAssertEqual(centre, straight, "the centre of the screen aims straight up")
        XCTAssertEqual(left, straight + arc, accuracy: 0.001,
                       "the left wall is the leftmost aim")
        XCTAssertEqual(right, straight - arc, accuracy: 0.001)
    }

    func testTheAimClampsAtTheWalls() {
        // A finger dragged past the play area cannot aim along the paddle
        let straight = Double.pi/2
        let arc = 70*Double.pi/180
        let past = EndlessIIPaddleEffects.aimedAngle(fingerFraction: -3,
                                                     straight: straight, maximum: arc)
        XCTAssertEqual(past, straight + arc, accuracy: 0.001,
                       "an aim that could point along the paddle is an aim into the wall")
    }

    func testTheDefaultAngleIsTheMirrorOfTheArrival() {
        // Arriving down and to the right leaves up and to the right
        let angle = EndlessIIPaddleEffects.defaultLaunchAngle(
            arriving: CGVector(dx: 50, dy: -50))
        XCTAssertEqual(angle, .pi/4, accuracy: 0.001)
    }
}

// MARK: - The scene's wiring

final class EndlessIIPaddleSceneTests: XCTestCase {

    private func paddleScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    func testAPaddleContactSpendsOneTurnFromEveryRunningClock() {
        // "Make paddle power-ups turn based not time based - like sticky paddle - 5 turns
        // each." The contact is the turn, whatever the paddle then does with it
        let scene = paddleScene()
        scene.endlessIICollectMagnetism()
        scene.endlessIICollectReversedControls()
        XCTAssertEqual(scene.endlessIIMagnetismClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns)

        scene.endlessIISpendPaddleTurns()
        XCTAssertEqual(scene.endlessIIMagnetismClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns - 1)
        XCTAssertEqual(scene.endlessIIReversedControlsClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns - 1)

        for _ in 0..<Int(GameScene.endlessIIPaddlePowerUpTurns) {
            scene.endlessIISpendPaddleTurns()
        }
        XCTAssertFalse(scene.endlessIIMagnetismClock.isRunning, "five turns and it is gone")
    }

    func testTheLastAimedCatchStillOwnsItsLaunch() {
        // Round 10 report: "On the last go of an aimed sticky power up the ball stuck to
        // the paddle, no arrow appeared... The ball then fell to the bottom of the screen
        // below the paddle and started to vibrate." The last turn expired the clock
        // before the catch, and everything downstream asked the clock - so the hold had
        // no owner: no aim target, no arrow, no launch.
        let scene = paddleScene()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAimedSticky()
        for _ in 0..<Int(GameScene.endlessIIPaddlePowerUpTurns) {
            scene.endlessIISpendPaddleTurns()
        }
        XCTAssertFalse(scene.endlessIIAimedStickyClock.isRunning,
                       "the last landing spends the clock out")

        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false),
                      "the turn that expired the clock still catches")
        XCTAssertNotNil(scene.endlessIIAimTarget,
                        "and the catch has an owner: the arrow and the drag both key off the target")
        XCTAssertTrue(scene.endlessIIAimLaunch(), "and the tap still launches it")
        XCTAssertFalse(scene.endlessIIAimOwedHold, "the owed hold is spent by its launch")
    }

    func testATurnClockSpendsWholeTurns() {
        var clock = EndlessIIClock()
        clock.collect(GameScene.endlessIIPaddlePowerUpTurns)
        clock.spendTurn()
        XCTAssertEqual(clock.remaining, GameScene.endlessIIPaddlePowerUpTurns - 1)
        XCTAssertEqual(clock.fraction, 4.0/5.0, accuracy: 0.001,
                       "the ring drains a segment at a time")
    }

    func testTheRingShowsTheTurnsAsSegments() {
        let scene = paddleScene()
        scene.endlessIICollectPaddleHalo()
        let entry = scene.endlessIIPaddleRingEntries().first
        XCTAssertEqual(entry?.segments, Int(GameScene.endlessIIPaddlePowerUpTurns),
                       "five marks say five turns, the way the sticky paddle's ring does")
    }

    func testOtherModesSpendNothing() {
        let scene = paddleScene()
        scene.endlessIICollectMagnetism()
        scene.gameMode = .classic
        scene.endlessIISpendPaddleTurns()
        XCTAssertEqual(scene.endlessIIMagnetismClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns)
    }

    func testTheBadOnesChangeTheHooksTheSceneAsks() {
        let scene = paddleScene()
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence, 1)
        XCTAssertEqual(scene.endlessIIControlDirection, 1)

        scene.endlessIICollectFlippedAngle()
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence, -1)
        scene.endlessIICollectInertPaddle()
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence, 0)
        scene.endlessIICollectReversedControls()
        XCTAssertEqual(scene.endlessIIControlDirection, -1)
    }

    func testThePortalPaddleOnlySwallowsWhileItRuns() {
        let scene = paddleScene()
        let subject = SKSpriteNode()
        XCTAssertFalse(scene.endlessIIPaddlePortalTook(subject, collision: 0))

        scene.endlessIICollectPortalPaddle()
        XCTAssertTrue(scene.endlessIIPaddlePortalTook(subject, collision: 0.4))
        XCTAssertEqual(scene.endlessIIPendingPaddlePortals.count, 1)
        XCTAssertEqual(scene.endlessIIPendingPortalCollisions[ObjectIdentifier(subject)],
                       0.4, "where the ball went through rides along for the exit angle")
    }

    func testThePortalPaddlesLastTurnStillSwallows() {
        // Play test: "Portal paddle on its last turn doesn't work, the ball just
        // bounces off." Spending the last turn expires the clock before the paddle
        // acts; the turn being spent still delivers what it was spent on.
        let scene = paddleScene()
        scene.endlessIIPortalPaddleClock.collect(1)
        scene.endlessIISpendPaddleTurns()
        XCTAssertFalse(scene.endlessIIPortalPaddleClock.isRunning,
                       "the last turn is spent")
        XCTAssertTrue(scene.endlessIIPaddlePortalTook(SKSpriteNode(), collision: 0),
                      "and it still swallows")
    }

    func testOtherModesNeverSwallowABall() {
        let scene = paddleScene()
        scene.gameMode = .classic
        scene.endlessIIPortalPaddleClock.collect(10)
        XCTAssertFalse(scene.endlessIIPaddlePortalTook(SKSpriteNode(), collision: 0))
    }

    func testEveryRunningClockReportsToTheRing() {
        let scene = paddleScene()
        XCTAssertTrue(scene.endlessIIPaddleRingEntries().isEmpty)

        scene.endlessIICollectAimedSticky()
        scene.endlessIICollectMagnetism()
        scene.endlessIICollectReversedControls()
        XCTAssertEqual(scene.endlessIIPaddleRingEntries().count, 3)
    }

    func testTheBatchSavesAndRestoresThroughTheSameKeys() {
        let saving = paddleScene()
        saving.endlessIICollectMagnetism()
        saving.endlessIICollectMagnetism()
        // Collected twice, so the level has to survive too
        saving.endlessIICollectPaddleHalo()
        saving.endlessIIMagnetismClock.remaining = 7

        let restored = paddleScene()
        for entry in saving.endlessIIPaddleClockSaveEntries() {
            XCTAssertTrue(restored.endlessIIRestorePaddleClock(
                key: entry.key, remaining: entry.remaining,
                total: entry.total, magnitude: entry.magnitude))
        }

        XCTAssertEqual(restored.endlessIIMagnetismClock.remaining, 7)
        XCTAssertEqual(restored.endlessIIMagnetismClock.level, 1)
        XCTAssertTrue(restored.endlessIIPaddleHaloClock.isRunning)
    }

    func testAKeyFromSomeOtherPowerUpIsNotThisBatchs() {
        XCTAssertFalse(paddleScene().endlessIIRestorePaddleClock(
            key: "gigaBallTimer", remaining: 5, total: 10, magnitude: 0))
    }

    func testResetEndsTheWholeBatch() {
        let scene = paddleScene()
        scene.endlessIICollectAimedSticky()
        scene.endlessIICollectPortalPaddle()
        scene.endlessIIPendingPaddlePortals.append(SKSpriteNode())
        scene.endlessIIResetPaddlePowerUps()

        XCTAssertTrue(scene.endlessIIPaddleRingEntries().isEmpty)
        XCTAssertTrue(scene.endlessIIPendingPaddlePortals.isEmpty)
    }

    func testTheOriginalEndlessNeverOffersThePaddleBatch() {
        // The same constraint the vision batch pinned: these rows are built for both
        // endless modes, and years of scores live on the other one
        let scene = paddleScene()
        scene.gameMode = .endless
        scene.applyEndlessRowPowerUpWeights()
        for index in 31...38 {
            XCTAssertEqual(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }

        scene.gameMode = .endlessII
        scene.applyEndlessRowPowerUpWeights()
        for index in 31...38 {
            XCTAssertGreaterThan(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }
    }

    // MARK: Aimed Sticky in the scene

    func testACaughtBallIsHeldAndAimedAtItsOwnBounce() {
        let scene = paddleScene()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAimedSticky()

        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 50, dy: -50))
        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false))
        XCTAssertTrue(scene.ballIsOnPaddle)

        guard let target = scene.endlessIIAimTarget else { return XCTFail("nothing aimed") }
        XCTAssertEqual(scene.endlessIIAimAngle(for: target), .pi/4, accuracy: 0.01,
                       "the default is the bounce it would have taken")
    }

    func testMovingTheFingerSwingsTheAimToWhereItSits() {
        let scene = paddleScene()
        scene.gameWidth = 400
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAimedSticky()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 0, dy: -100))
        scene.endlessIIAimedCatch(scene.ball, isExtra: false)

        XCTAssertTrue(scene.endlessIIAimMoved(to: 150), "the moving finger is the aim")
        let target = scene.endlessIIAimTarget!
        let swung = scene.endlessIIAimAngle(for: target)
        XCTAssertLessThan(swung, .pi/2,
                          "a finger on the right of the screen aims right of straight up")
    }

    func testNothingIsConsumedWhenNothingIsAimed() {
        let scene = paddleScene()
        XCTAssertFalse(scene.endlessIIAimMoved(to: 30))
        XCTAssertFalse(scene.endlessIIAimLaunch())
    }

    func testTheLaunchSendsTheBallAtTheAimedAngleAndSpendsNoCatch() {
        let scene = paddleScene()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ballSpeedLimit = 100
        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 3
        scene.endlessIICollectAimedSticky()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 0, dy: -100))
        scene.endlessIIAimedCatch(scene.ball, isExtra: false)

        XCTAssertTrue(scene.endlessIIAimLaunch())
        XCTAssertFalse(scene.ballIsOnPaddle)
        XCTAssertEqual(scene.stickyPaddleCatches, 3,
                       "Aimed Sticky owns the launch - no sticky catch is spent")
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "it left upward")
    }

    func testACatchFreezesTheWorldAndTheLaunchLetsItGo() {
        // "Can we pause the game whilst the user aims? As soon as they lift their finger
        // the ball fires and the game continues?" - yes, and this is it
        let scene = paddleScene()
        scene.ballSpeedLimit = 100
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        let flying = SKSpriteNode()
        flying.name = BallCategoryName
        flying.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        flying.physicsBody?.velocity = CGVector(dx: 70, dy: -50)
        scene.addChild(flying)
        scene.endlessIIExtraBalls.append(flying)

        scene.endlessIICollectAimedSticky()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 0, dy: -100))
        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false))

        XCTAssertTrue(scene.endlessIIAimHold, "the world holds its breath")
        XCTAssertEqual(flying.physicsBody?.velocity.dx, 0, "the other ball froze too")
        XCTAssertEqual(scene.pauseExtraBallVelocities.first?.dx, 70,
                       "its heading survives the freeze")

        XCTAssertTrue(scene.endlessIIAimLaunch())
        XCTAssertFalse(scene.endlessIIAimHold, "lifting the finger lets the world go")
        XCTAssertEqual(flying.physicsBody?.velocity.dx ?? 0, 70, accuracy: 0.01,
                       "the other ball resumes its flight")
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "and the shot flies")
    }

    func testCatchingNeedsTheClock() {
        let scene = paddleScene()
        scene.addChild(scene.ball)
        XCTAssertFalse(scene.endlessIIAimedCatch(scene.ball, isExtra: false))
    }
}
