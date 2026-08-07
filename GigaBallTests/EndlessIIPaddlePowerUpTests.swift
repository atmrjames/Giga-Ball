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

    func testASteeredBallInheritsHalfThePaddlesMovement() {
        let x = EndlessIIPaddleEffects.steered(x: 0, paddleMovedBy: 40,
                                               leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertEqual(x, 40*EndlessIIPaddleEffects.steeringFactor)
    }

    func testSteeringCannotPushABallThroughAWall() {
        let x = EndlessIIPaddleEffects.steered(x: 198, paddleMovedBy: 100,
                                               leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertEqual(x, 195, "clamped a radius inside the wall")
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

    func testReleasingWithoutDraggingChangesNothing() {
        // §5.4's promise: the default is the angle the ball would have bounced at anyway
        let angle = EndlessIIPaddleEffects.aimedAngle(default: 1.2, draggedBy: 0,
                                                      minimum: 0.3, maximum: 2.8)
        XCTAssertEqual(angle, 1.2)
    }

    func testDraggingSwingsTheAimAndTheLimitsHold() {
        let swungLeft = EndlessIIPaddleEffects.aimedAngle(default: 1.2, draggedBy: -1000,
                                                          minimum: 0.3, maximum: 2.8)
        let swungRight = EndlessIIPaddleEffects.aimedAngle(default: 1.2, draggedBy: 1000,
                                                           minimum: 0.3, maximum: 2.8)
        XCTAssertEqual(swungLeft, 0.3, "an aim that could point along the paddle is an aim into the wall")
        XCTAssertEqual(swungRight, 2.8)
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
        XCTAssertFalse(scene.endlessIIPaddlePortalTook(subject))

        scene.endlessIICollectPortalPaddle()
        XCTAssertTrue(scene.endlessIIPaddlePortalTook(subject))
        XCTAssertEqual(scene.endlessIIPendingPaddlePortals.count, 1)
    }

    func testOtherModesNeverSwallowABall() {
        let scene = paddleScene()
        scene.gameMode = .classic
        scene.endlessIIPortalPaddleClock.collect(10)
        XCTAssertFalse(scene.endlessIIPaddlePortalTook(SKSpriteNode()))
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

    func testDraggingSwingsTheAim() {
        let scene = paddleScene()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAimedSticky()
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 0, dy: -100))
        scene.endlessIIAimedCatch(scene.ball, isExtra: false)

        XCTAssertTrue(scene.endlessIIAimDragged(by: 30), "the drag swings the aim - and the paddle moves too")
        let target = scene.endlessIIAimTarget!
        let swung = scene.endlessIIAimAngle(for: target)
        XCTAssertNotEqual(swung, .pi/2, accuracy: 0.01)
    }

    func testNothingIsConsumedWhenNothingIsAimed() {
        let scene = paddleScene()
        XCTAssertFalse(scene.endlessIIAimDragged(by: 30))
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
