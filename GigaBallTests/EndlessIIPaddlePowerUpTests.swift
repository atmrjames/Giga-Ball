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
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: true, flipped: false), 0)
        XCTAssertEqual(EndlessIIPaddleEffects.angleInfluence(inert: true, flipped: true), 0,
                       "no influence is also no influence to invert")
    }

    /// Flipped over-corrects rather than merely inverting (play-test round 46: "not doing
    /// much"). At a plain -1 a flipped bounce is the mirror of the one you asked for, which is
    /// only noticeable if you were steering hard - and most catches are near the paddle's
    /// centre, where the whole term is close to zero whatever this returns.
    func testFlippedOverCorrectsRatherThanMerelyInverting() {
        let flipped = EndlessIIPaddleEffects.angleInfluence(inert: false, flipped: true)
        XCTAssertLessThan(flipped, -1, "inverted and then some")
        XCTAssertGreaterThan(flipped, -3, "still proportional to how much steer was asked for")
        XCTAssertEqual(flipped, EndlessIIPaddleEffects.flippedInfluence)
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
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence,
                       EndlessIIPaddleEffects.flippedInfluence)
        // Read off the constant rather than written out again: this test held its own copy of
        // -1 and failed the moment the strength was tuned, which is the suite catching a
        // second copy of a decision exactly as it should
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

    // MARK: - Paddle Halo stacking (play-test round 98)

    /// "Getting this power-up whilst it's already active should make it grow bigger."
    /// Each collection that finds the clock running climbs one reach level, to the ladder's
    /// deepest rung and no further.
    func testRecollectingTheHaloClimbsTheReachLadder() {
        var clock = EndlessIIClock()
        let deepest = EndlessIIPaddleEffects.haloReach.count - 1

        clock.collect(GameScene.endlessIIPaddlePowerUpTurns, deepestLevel: deepest)
        XCTAssertEqual(clock.level, 0, "the first collection is the base halo")

        clock.collect(GameScene.endlessIIPaddlePowerUpTurns, deepestLevel: deepest)
        clock.collect(GameScene.endlessIIPaddlePowerUpTurns, deepestLevel: deepest)
        XCTAssertEqual(clock.level, deepest, "two re-collections reach the top")

        clock.collect(GameScene.endlessIIPaddlePowerUpTurns, deepestLevel: deepest)
        XCTAssertEqual(clock.level, deepest, "and the ladder has a top")
    }

    /// The ladder must actually climb: each level reaches further than the one before,
    /// or a re-collection buys nothing the player can see.
    func testEveryHaloLevelReachesFurtherThanTheLast() {
        let ladder = EndlessIIPaddleEffects.haloReach
        XCTAssertGreaterThanOrEqual(ladder.count, 3,
                                    "round 98 asked for a stack worth noticing")
        for (shorter, longer) in zip(ladder, ladder.dropFirst()) {
            XCTAssertGreaterThan(longer, shorter)
        }
    }

    /// An expired halo starts again from the base. Levels are earned within one run of the
    /// power-up, not banked across them.
    func testAnExpiredHaloForgetsItsLevel() {
        var clock = EndlessIIClock()
        let deepest = EndlessIIPaddleEffects.haloReach.count - 1
        clock.collect(2, deepestLevel: deepest)
        clock.collect(2, deepestLevel: deepest)
        XCTAssertEqual(clock.level, 1)

        for _ in 0..<8 { clock.spendTurn() }
        XCTAssertFalse(clock.isRunning)
        XCTAssertEqual(clock.level, 0, "expiry resets the ladder with the clock")
    }

    // MARK: - The angle group cancels itself (play-test round 99)

    /// Aimed Sticky, Inert Paddle and Flipped Angle are answers to the same question -
    /// what happens to the ball's angle at the paddle - and the most recent one wins.
    func testCollectingAimedStickyCancelsTheAngleBenders() {
        let scene = GameScene()
        scene.endlessIICollectInertPaddle()
        scene.endlessIICollectFlippedAngle()

        scene.endlessIICollectAimedSticky()
        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning)
        XCTAssertFalse(scene.endlessIIFlippedAngleClock.isRunning)
    }

    func testCollectingAnAngleBenderCancelsAimedSticky() {
        let scene = GameScene()
        scene.endlessIICollectAimedSticky()
        scene.endlessIICollectInertPaddle()
        XCTAssertFalse(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertTrue(scene.endlessIIInertPaddleClock.isRunning)

        scene.endlessIICollectFlippedAngle()
        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning,
                       "the benders replace each other too - bad power-ups do not queue")
        XCTAssertTrue(scene.endlessIIFlippedAngleClock.isRunning)
    }

    /// Portal Paddle is compatible with the whole group: its rules apply from the top of
    /// the screen, not from the paddle, so nothing here may touch it.
    func testPortalPaddleSurvivesTheAngleGroup() {
        let scene = GameScene()
        scene.endlessIICollectPortalPaddle()
        scene.endlessIICollectAimedSticky()
        scene.endlessIICollectInertPaddle()
        scene.endlessIICollectFlippedAngle()
        XCTAssertTrue(scene.endlessIIPortalPaddleClock.isRunning)
    }

    /// A cancellation that lands mid-aim must not strand the held ball: the launch it was
    /// aiming is still owed, through the same flag an expired clock uses.
    func testCancellingMidHoldStillOwesTheLaunch() {
        let scene = GameScene()
        scene.endlessIICollectAimedSticky()
        scene.endlessIIAimHold = true

        scene.endlessIICancelAimedSticky()
        XCTAssertFalse(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertTrue(scene.endlessIIAimOwedHold,
                      "a ball on the paddle mid-aim with the machinery gone would never leave")
    }
}

/// "With portal paddle and aimed sticky together, the aiming arrow should come from the top
/// of the screen down, as the ball should be going through the paddle and wrapping around to
/// the top" (play-test round 128).
final class AimedStickyThroughThePortalPaddleTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSpeedLimit = 100
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        return scene
    }

    func testAnAimedShotOnlyPortalsWhileThePortalPaddleRuns() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIAimLaunchesThroughThePaddle)

        scene.endlessIICollectPortalPaddle()
        XCTAssertTrue(scene.endlessIIAimLaunchesThroughThePaddle)
    }

    /// The last turn still counts, the way every other paddle power-up's does: the turn that
    /// expired the clock is the one being spent on this contact.
    func testTheOwedTurnStillSendsTheShotThrough() {
        let scene = mayhem()
        scene.endlessIIPortalPaddleOwedTurn = true
        XCTAssertTrue(scene.endlessIIAimLaunchesThroughThePaddle)
    }

    func testThePortalledLaunchArrivesAtTheTopTravellingDown() {
        let scene = mayhem()
        scene.ball.position = CGPoint(x: 20, y: -300)
        scene.endlessIICollectPortalPaddle()

        let up = Double.pi/3
        // Sixty degrees - aimed up and to the right, as the arrow would show it
        scene.endlessIIPortalTheAimedLaunch(scene.ball, angle: up)

        XCTAssertGreaterThan(scene.ball.position.y, 0, "it re-enters at the top of the field")
        XCTAssertLessThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0,
                          "travelling down - a ball re-entering upward would only buy an "
                          + "immediate bounce off the ceiling")
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dx ?? 0, 0,
                             "and still to the right, which is the half of the aim that survives")
    }

    func testTheSpentTurnIsNotSpentTwice() {
        let scene = mayhem()
        scene.endlessIIPortalPaddleOwedTurn = true
        scene.endlessIIPortalTheAimedLaunch(scene.ball, angle: Double.pi/2)
        XCTAssertFalse(scene.endlessIIPortalPaddleOwedTurn)
    }
}

// MARK: - Double Paddle

/// "Double paddle - the paddle splits in two, each half the width of the original" (James's
/// play-test idea from the second round, pulled into 1.3 at round 100).
///
/// The interesting claim to hold is not that the paddle looks split but that it *is* split:
/// one node, one contact path, and a real hole in the middle where there is no body at all.
final class EndlessIIDoublePaddleTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.paddle.physicsBody?.categoryBitMask = CollisionTypes.paddleCategory.rawValue
        scene.paddle.name = PaddleCategoryName
        scene.addChild(scene.paddle)
        return scene
    }

    private func halves(_ scene: GameScene) -> [SKNode] {
        scene.paddle.children.filter { $0.name == GameScene.doublePaddleHalfName }
    }

    func testCollectingItLeavesAHoleInTheMiddleOfThePaddle() {
        let scene = mayhem()
        let whole = scene.paddle.physicsBody?.area ?? 0
        scene.endlessIICollectDoublePaddle()

        let split = scene.paddle.physicsBody?.area ?? 0
        XCTAssertLessThan(split, whole, "there is less paddle than there was")
        XCTAssertEqual(split, whole*(1 - GameScene.endlessIIDoublePaddleGap), accuracy: whole*0.02,
                       "and what is missing is exactly the gap - a ball down the middle has "
                       + "somewhere to fall through, which is the whole power-up")
    }

    func testTheSplitPaddleIsStillOnePaddle() {
        // The cheap part of the design, and the part worth guarding: a second *node* would
        // have meant teaching the touch handler, the bounce, the Halo and the Portal about a
        // list of paddles
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()

        XCTAssertEqual(scene.children.filter { $0.name == PaddleCategoryName }.count, 1)
        XCTAssertEqual(scene.paddle.physicsBody?.categoryBitMask,
                       CollisionTypes.paddleCategory.rawValue,
                       "and a contact still arrives as a paddle contact")
        XCTAssertEqual(scene.paddle.size.width, 120,
                       "the span is unchanged, so the bounce still reads the landing spot "
                       + "across the whole paddle")
    }

    func testItDrawsTwoHalvesAndStopsDrawingItself() {
        let scene = mayhem()
        scene.paddle.texture = SKTexture(image: PowerUpIcon.doublePaddle)
        scene.endlessIICollectDoublePaddle()

        XCTAssertEqual(halves(scene).count, 2)
        XCTAssertNil(scene.paddle.texture, "or the split would be drawn over a whole paddle")
        let gap = 120*GameScene.endlessIIDoublePaddleGap
        for half in halves(scene) {
            XCTAssertEqual(abs(half.position.x), (120 - gap)/2/2 + gap/2, accuracy: 0.01,
                           "each half sits over its own body")
        }
    }

    func testAResizedPaddleIsCutAgain() {
        // Expand and Shrink Paddle write the width directly. A split paddle that grew and
        // kept the body it had when it was small would be a paddle with a hole in the wrong
        // place
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        let narrow = scene.paddle.physicsBody?.area ?? 0

        scene.paddle.size.width = 200
        scene.refreshEndlessIIDoublePaddle()
        XCTAssertGreaterThan(scene.paddle.physicsBody?.area ?? 0, narrow)
        XCTAssertEqual(halves(scene).count, 2, "still two, and both wider")
    }

    func testTheRebuiltBodyKeepsWhateverMasksThePaddleHad() {
        // Wrap-Around takes the border bit away so the paddle can leave the field, and every
        // level state puts it back. A replacement body built from remembered constants would
        // undo whichever was in force when the split started
        let scene = mayhem()
        scene.paddle.physicsBody?.collisionBitMask = CollisionTypes.paddleCategory.rawValue
        scene.endlessIICollectDoublePaddle()

        XCTAssertEqual(scene.paddle.physicsBody?.collisionBitMask,
                       CollisionTypes.paddleCategory.rawValue,
                       "the border bit stays gone")
    }

    func testItPutsThePaddleBackWhenTheClockStops() {
        let scene = mayhem()
        let whole = scene.paddle.physicsBody?.area ?? 0
        let dress = SKTexture(image: PowerUpIcon.doublePaddle)
        scene.paddle.texture = dress
        scene.endlessIICollectDoublePaddle()

        scene.endlessIIDoublePaddleClock.run(down: GameScene.endlessIIDoublePaddleDuration)
        scene.refreshEndlessIIDoublePaddle()

        XCTAssertTrue(halves(scene).isEmpty)
        XCTAssertEqual(scene.paddle.texture, dress, "wearing its own dress again")
        XCTAssertEqual(scene.paddle.physicsBody?.area ?? 0, whole, accuracy: whole*0.01,
                       "and whole - a power-up that left the paddle in pieces after its "
                       + "clock stopped would be a power-up that never ended")
    }

    func testTheLifeResetPutsItBackToo() {
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIIResetPaddlePowerUps()

        XCTAssertFalse(scene.endlessIIDoublePaddleClock.isRunning)
        XCTAssertTrue(halves(scene).isEmpty)
    }

    func testItIsAClockTheLockFreezesAndTheWipeClears() {
        XCTAssertTrue(GameScene.endlessIITimedClockPaths.contains(\GameScene.endlessIIDoublePaddleClock))
        XCTAssertTrue(GameScene.endlessIIWipeableClockPaths.contains(\GameScene.endlessIIDoublePaddleClock))
    }

    func testItSavesAndComesBackSplit() {
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        guard let saved = scene.endlessIIPaddleClockSaveEntries()
            .first(where: { $0.key == "endlessIIDoublePaddle" }) else {
            return XCTFail("a running Double Paddle must be in the save")
        }

        let resumed = mayhem()
        XCTAssertTrue(resumed.endlessIIRestorePaddleClock(key: saved.key, remaining: saved.remaining,
                                                          total: saved.total, magnitude: saved.magnitude))
        XCTAssertEqual(halves(resumed).count, 2,
                       "split on the spot, so a resumed game draws the paddle it is about "
                       + "to bounce with")
    }

    /// James, round 166: "I got the double paddle power up but it didn't seem to do anything."
    ///
    /// It did everything except be visible. In the Retro theme the paddle the player sees is
    /// not the paddle sprite - it is `paddleRetroTexture`, a separate node drawn over the top
    /// at zPosition 4 with its own art - so the body was split, the halves were drawn
    /// underneath it, and a whole paddle was painted over them. The only sign of the power-up
    /// was a ball falling through the middle of a paddle that looked solid.
    private func retro(_ scene: GameScene) {
        scene.paddleTexture = scene.retroPaddle
        scene.paddleRetroTexture.texture = scene.retroPaddle
        scene.paddleRetroTexture.size = CGSize(width: 146, height: 31)
        scene.paddleRetroTexture.isHidden = false
    }

    func testTheRetroDressDoesNotPaintOverTheSplit() {
        let scene = mayhem()
        retro(scene)
        scene.endlessIICollectDoublePaddle()

        XCTAssertEqual(halves(scene).count, 2)
        XCTAssertTrue(scene.paddleRetroTexture.isHidden,
                      "a whole paddle drawn over the split is the power-up doing nothing")
    }

    func testTheRetroDressComesBackWhenTheSplitEnds() {
        let scene = mayhem()
        retro(scene)
        scene.endlessIICollectDoublePaddle()
        scene.endlessIIDoublePaddleClock.run(down: GameScene.endlessIIDoublePaddleDuration)
        scene.refreshEndlessIIDoublePaddle()

        XCTAssertEqual(halves(scene).count, 0)
        XCTAssertFalse(scene.paddleRetroTexture.isHidden,
                       "the player's own paddle comes back when the power-up ends")
    }

    func testTheHalvesWearTheThemeThePlayerChose() {
        let scene = mayhem()
        retro(scene)
        scene.endlessIICollectDoublePaddle()

        let half = halves(scene).first as? SKSpriteNode
        XCTAssertEqual(half?.texture, scene.retroPaddle,
                       "a split paddle still looks like the paddle that was chosen")
        XCTAssertEqual(half?.size.height, scene.paddleRetroTexture.size.height,
                       "at the art's own proportions - the Retro dress is much taller than "
                       + "the paddle it stands for")
    }

    func testTheBodyIsThePaddlesHeightWhateverThePictureIs() {
        // The Retro dress is two and a half times as tall as the paddle. A body built to the
        // picture would catch balls above and below the paddle everybody else is playing with
        let plain = mayhem()
        plain.endlessIICollectDoublePaddle()
        let plainArea = plain.paddle.physicsBody?.area ?? 0

        let themed = mayhem()
        retro(themed)
        themed.endlessIICollectDoublePaddle()
        XCTAssertEqual(themed.paddle.physicsBody?.area ?? 0, plainArea, accuracy: 0.0001,
                       "the same paddle, whatever it is wearing")
    }
}

/// Mirror Paddle (§12.0), the sixty-first power-up and the other half of the Double Paddle
/// row: "a mirrored second paddle that travels the other way".
///
/// The queue priced this half as the expensive one - "somewhere else on the screen", so a real
/// second surface with a real second contact path - and it is. What is worth pinning is that
/// the second surface behaves like a paddle without *being* the paddle: no paddle turn, no
/// landing, and none of the power-ups that answer a paddle contact answering this one.
final class EndlessIIMirrorPaddleTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 60, y: -300)
        scene.addChild(scene.paddle)
        return scene
    }

    private func mirror(_ scene: GameScene) -> SKSpriteNode? {
        scene.childNode(withName: GameScene.endlessIIMirrorPaddleName) as? SKSpriteNode
    }

    func testItStandsOppositeThePaddle() {
        XCTAssertEqual(GameScene.endlessIIMirrorPaddleX(paddleX: 80), -80)
        XCTAssertEqual(GameScene.endlessIIMirrorPaddleX(paddleX: -80), 80)
        XCTAssertEqual(GameScene.endlessIIMirrorPaddleX(paddleX: 0), 0,
                       "and the two are one paddle in the middle, which is the trade")
    }

    func testCollectingItPutsASecondPaddleOnTheField() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()

        XCTAssertTrue(scene.endlessIIMirrorPaddleClock.isRunning)
        guard let mirror = mirror(scene) else { return XCTFail("a second paddle stands") }
        XCTAssertEqual(mirror.position.x, -scene.paddle.position.x, accuracy: 0.001)
        XCTAssertEqual(mirror.position.y, scene.paddle.position.y, accuracy: 0.001,
                       "level with the paddle - it is a paddle, not furniture overhead")
        XCTAssertEqual(mirror.size, scene.paddle.size)
    }

    func testItIsNotThePaddleAndNotTheSafetyPaddle() {
        // Its own category, the Safety Paddle's lesson applied again: the paddle's would spend
        // a paddle turn and count a landing, and Aimed Sticky, Portal Paddle and Magnetism all
        // answer paddle contacts
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()

        XCTAssertEqual(mirror(scene)?.physicsBody?.categoryBitMask,
                       CollisionTypes.mirrorPaddleCategory.rawValue)
        XCTAssertNotEqual(CollisionTypes.mirrorPaddleCategory.rawValue,
                          CollisionTypes.paddleCategory.rawValue)
        XCTAssertEqual(mirror(scene)?.physicsBody?.isDynamic, false)
    }

    func testItFollowsThePaddleTheOtherWay() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.paddle.position.x = -95
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertEqual(mirror(scene)?.position.x ?? 0, 95, accuracy: 0.001,
                       "the player goes left, it goes right")
    }

    func testItKeepsThePaddlesSizeWhenExpandOrShrinkWritesOne() {
        // The width is written directly by the size power-ups, and a mirror that kept the
        // width it was born with would be a different paddle from the one it mirrors
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.paddle.size = CGSize(width: 200, height: 12)
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertEqual(mirror(scene)?.size.width ?? 0, 200, accuracy: 0.001)
        XCTAssertNotNil(mirror(scene)?.physicsBody, "and the body is rebuilt to match")
    }

    func testASecondCollectionLengthensItRatherThanStackingTwo() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        let first = scene.endlessIIMirrorPaddleClock.remaining
        scene.endlessIICollectMirrorPaddle()

        XCTAssertGreaterThan(scene.endlessIIMirrorPaddleClock.remaining, first)
        var found = 0
        scene.enumerateChildNodes(withName: GameScene.endlessIIMirrorPaddleName) { _, _ in
            found += 1
        }
        XCTAssertEqual(found, 1, "longer, not two of them")
    }

    func testItIsNeverStranded() {
        // A surface left standing after its clock stops would change the rest of the run -
        // the Safety Paddle's own rule
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIIMirrorPaddleClock.run(down: GameScene.endlessIIMirrorPaddleDuration)
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertNil(scene.childNode(withName: GameScene.endlessIIMirrorPaddleName),
                     "the tick that finds the clock stopped takes it away")
    }

    func testItLeavesTheFieldAloneOutsideMayhem() {
        let scene = mayhem()
        scene.gameMode = .classic
        scene.endlessIICollectMirrorPaddle()
        XCTAssertNil(scene.childNode(withName: GameScene.endlessIIMirrorPaddleName))
    }

    func testAResumedRunFindsItStanding() {
        let saving = mayhem()
        saving.endlessIICollectMirrorPaddle()
        guard let saved = saving.endlessIIPaddleClockSaveEntries()
            .first(where: { $0.key == "endlessIIMirrorPaddle" }) else {
            return XCTFail("a running Mirror Paddle must be in the save")
        }

        let resumed = mayhem()
        XCTAssertTrue(resumed.endlessIIRestorePaddleClock(key: saved.key,
                                                          remaining: saved.remaining,
                                                          total: saved.total,
                                                          magnitude: saved.magnitude))
        XCTAssertNotNil(resumed.childNode(withName: GameScene.endlessIIMirrorPaddleName),
                        "standing on the spot, so a resumed game draws what it bounces off")
    }

    func testTheBounceBendsByWhereTheBallLanded() {
        // A mirror that returned the ball at the angle it arrived would be a moving wall.
        // `PaddleBounce`'s own call, at influence 1, exactly as the real paddle makes it
        let scene = mayhem()
        scene.paddle.position.x = 0
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a second paddle stands") }

        let ball = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: -300)
        ball.position = CGPoint(x: mirror.position.x + 40, y: mirror.position.y + 8)
        scene.addChild(ball)

        scene.endlessIIMirrorPaddleHit(ball)
        let sent = ball.physicsBody?.velocity ?? .zero
        XCTAssertGreaterThan(sent.dy, 0, "it always comes back up")
        XCTAssertGreaterThan(sent.dx, 0, "landing right of the middle sends it right")
    }

    func testAnUndersideContactIsLeftToThePhysics() {
        // The top face only, as on the real paddle
        let scene = mayhem()
        scene.paddle.position.x = 0
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a second paddle stands") }

        let ball = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        let arriving = CGVector(dx: 20, dy: 300)
        ball.physicsBody?.velocity = arriving
        ball.position = CGPoint(x: mirror.position.x, y: mirror.position.y - 20)
        scene.addChild(ball)

        scene.endlessIIMirrorPaddleHit(ball)
        XCTAssertEqual(ball.physicsBody?.velocity.dy ?? 0, arriving.dy, accuracy: 0.001,
                       "a ball meeting the underside keeps whatever the engine gave it")
    }
}
