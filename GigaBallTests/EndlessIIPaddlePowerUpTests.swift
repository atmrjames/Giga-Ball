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

    /// A second collection starts the clock again rather than adding to it.
    ///
    /// **Inverted in round 220**, where James's interaction matrix says "duration is reset"
    /// for every power-up collected on top of itself. It used to read fourteen here: four
    /// seconds left plus ten. Extending is what let three Drifts in a row spend half a minute
    /// sliding the field sideways, and a power-up whose *length* stacks is a different
    /// power-up from one whose strength does. The ring reads full either way, which is the
    /// half of the old test that was always right.
    func testASecondCollectionResetsAndTheRingReadsFull() {
        var clock = EndlessIIClock()
        clock.collect(10)
        clock.run(down: 6)
        clock.collect(10)

        XCTAssertEqual(clock.remaining, 10, "the second collection was added rather than reset")
        XCTAssertEqual(clock.fraction, 1, "topped up is full")
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

    /// James, round 200: "the ball should be attracted to the whole length of the paddle,
    /// not just a single point on it. The inertia of the ball and power of paddle magnetism
    /// should determine where the ball hits."
    func testABallAlreadyLandingOnThePaddleIsLeftToItsOwnFlight() {
        // Falling at 45 degrees toward a spot well inside the span: the magnet has nothing
        // to add, so inertia decides the landing - this is the fix for every ball being
        // steered away from the centre
        let before = CGVector(dx: 50, dy: -50)
        let after = EndlessIIPaddleEffects.magnetised(
            velocity: before, ballAt: CGPoint(x: -30, y: 30),
            paddleAt: .zero, paddleHalfWidth: 60, strength: 1, delta: 1.0/60.0)
        XCTAssertEqual(after.dx, before.dx, accuracy: 0.001)
        XCTAssertEqual(after.dy, before.dy, accuracy: 0.001)
    }

    func testABallMissingThePaddleIsBentTowardTheNearerEdge() {
        // Falling straight down at x = -200 with the paddle spanning -60...60: bent right,
        // toward the edge it can actually make - not toward the centre
        let after = EndlessIIPaddleEffects.magnetised(
            velocity: CGVector(dx: 0, dy: -100), ballAt: CGPoint(x: -200, y: 60),
            paddleAt: .zero, paddleHalfWidth: 60, strength: 1, delta: 1.0/60.0)
        XCTAssertGreaterThan(after.dx, 0, "pulled toward the span it would otherwise miss")
    }

    func testTheCentreOfThePaddleIsReachableAgain() {
        // The old fixed target a third out from centre meant a ball heading dead-centre was
        // actively pushed off it. Heading dead-centre now stays dead-centre
        let before = CGVector(dx: 0, dy: -100)
        let after = EndlessIIPaddleEffects.magnetised(
            velocity: before, ballAt: CGPoint(x: 0, y: 100),
            paddleAt: .zero, paddleHalfWidth: 60, strength: 1, delta: 1.0/60.0)
        XCTAssertEqual(after.dx, 0, accuracy: 0.001,
                       "a flight into the middle is not the magnet's to redirect")
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

    /// James, round 209: "the ball steering power up now feels way too sensitive, the ball
    /// seems to have no moments of its own."
    ///
    /// Both halves of the steering were a flat share taken **once per frame**, and the scene
    /// asks for 120 frames a second - so on a ProMotion phone the pull was applied twice as
    /// often as the numbers were tuned for, and the ball's own sideways line was bled away
    /// twice as fast. What the player felt was the frame rate, not the design.
    ///
    /// These pin the property that makes the two the same power-up: the same journey over the
    /// same *time*, whatever the frame rate delivering it.
    func testSteeringPullsTheSameAmountAtSixtyAndOneHundredAndTwenty() {
        let atSixty = EndlessIIPaddleEffects.steeringFollow(delta: 1.0/60)
        let atOneTwenty = EndlessIIPaddleEffects.steeringFollow(delta: 1.0/120)

        // Two 120fps frames must land where one 60fps frame does
        let twoFast = 1 - (1 - atOneTwenty)*(1 - atOneTwenty)
        XCTAssertEqual(twoFast, atSixty, accuracy: 0.0001)
        XCTAssertLessThan(atOneTwenty, atSixty, "a shorter frame moves the ball less")
    }

    func testTheSidewaysBleedIsTheSameOverTheSameTime() {
        let atSixty = EndlessIIPaddleEffects.steeringVelocityDamping(delta: 1.0/60)
        let atOneTwenty = EndlessIIPaddleEffects.steeringVelocityDamping(delta: 1.0/120)
        XCTAssertEqual(atOneTwenty*atOneTwenty, atSixty, accuracy: 0.0001)
        XCTAssertGreaterThan(atOneTwenty, atSixty,
                             "a shorter frame keeps more of the ball's own line")
    }

    /// The sixtieth-of-a-second numbers are the ones round 15 tuned by hand, so a frame of
    /// exactly that length must still behave exactly as it did.
    func testAFrameOfASixtiethIsUnchangedFromTheTunedNumbers() {
        XCTAssertEqual(EndlessIIPaddleEffects.steeringFollow(delta: 1.0/60),
                       EndlessIIPaddleEffects.steeringFollowPerSixtieth, accuracy: 0.0001)
        XCTAssertEqual(EndlessIIPaddleEffects.steeringVelocityDamping(delta: 1.0/60),
                       EndlessIIPaddleEffects.steeringVelocityDampingPerSixtieth,
                       accuracy: 0.0001)
    }

    /// A frame with no time in it moves nothing, rather than snapping the ball to the paddle.
    func testAFrameWithNoTimeInItSteersNothing() {
        XCTAssertEqual(EndlessIIPaddleEffects.steeringFollow(delta: 0), 0)
        XCTAssertEqual(EndlessIIPaddleEffects.steeredTowards(
            paddleX: 100, from: 0, leftWall: -200, rightWall: 200, radius: 5, delta: 0), 0)
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
        scene.endlessIICollectInertPaddle()
        scene.endlessIICollectReversedControls()
        XCTAssertEqual(scene.endlessIIInertPaddleClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns)

        scene.endlessIISpendPaddleTurns()
        XCTAssertEqual(scene.endlessIIInertPaddleClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns - 1)
        XCTAssertEqual(scene.endlessIIReversedControlsClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns - 1)

        for _ in 0..<Int(GameScene.endlessIIPaddlePowerUpTurns) {
            scene.endlessIISpendPaddleTurns()
        }
        XCTAssertTrue(scene.endlessIIInertPaddleClock.lingering,
                      "five turns and it is saying goodbye (round 231)")
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning, "five turns, a second, gone")
    }

    /// The three that act between bounces are measured in seconds, not in bounces.
    ///
    /// Ball Steering since round 15, Magnetism and Paddle Halo since round 218's workbook.
    /// All three do their work while the ball is nowhere near the paddle, and a contact is
    /// the wrong thing to bill them for: counting hits ended them in the middle of using them.
    func testTheContinuousPaddlePowerUpsAreNotSpentByAContact() {
        let scene = paddleScene()
        scene.endlessIICollectMagnetism()
        scene.endlessIICollectPaddleHalo()
        scene.endlessIICollectBallSteering()

        scene.endlessIISpendPaddleTurns()

        XCTAssertEqual(scene.endlessIIMagnetismClock.remaining,
                       GameScene.endlessIIPaddlePowerUpDuration, accuracy: 0.001,
                       "Magnetism was billed for a bounce")
        XCTAssertEqual(scene.endlessIIPaddleHaloClock.remaining,
                       GameScene.endlessIIPaddlePowerUpDuration, accuracy: 0.001,
                       "the halo was billed for a bounce")
        XCTAssertEqual(scene.endlessIIBallSteeringClock.remaining,
                       GameScene.endlessIIPaddlePowerUpDuration, accuracy: 0.001)
    }

    /// James, round 169: "all of a sudden, the other ball appeared on the middle of the
    /// paddle" - and round 180, mid-Ghost Ball: "the ball suddenly appeared back on my
    /// paddle. I think one of the stuck ball features must've kicked in."
    ///
    /// It was the aimed catch. The on-paddle follow places the ball at the paddle's x plus
    /// a remembered offset, and `releaseBall` zeroes that offset - so a caught ball sat at
    /// its landing spot for a frame and then snapped to the paddle's centre. The extras'
    /// branch had always recorded its offset, which is why round 175's hunt through the
    /// extras found nothing.
    func testAnAimedCatchHoldsTheBallWhereItLanded() {
        let scene = paddleScene()
        scene.addChild(scene.ball)
        scene.addChild(scene.paddle)
        scene.paddle.position = CGPoint(x: -30, y: -300)
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.position = CGPoint(x: 10, y: -290)
        scene.endlessIICollectAimedSticky()

        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false))
        XCTAssertEqual(scene.ballRelativePositionOnPaddle, 40, accuracy: 0.001,
                       "the follow keeps it forty points right of centre - where it landed, "
                       + "not the middle of the paddle")
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
        XCTAssertTrue(scene.endlessIIAimedStickyClock.lingering,
                      "the last landing spends the turns out - what is left is the goodbye")
        XCTAssertTrue(scene.endlessIIAimedStickyClock.countsTurns,
                      "and it keeps counting turns through the goodbye (round 263), so the "
                      + "ring keeps its segment marks and shows every one of them spent "
                      + "rather than dropping to a smooth arc for the last second")

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
        scene.endlessIICollectInertPaddle()
        let entry = scene.endlessIIPaddleRingEntries()
            .first { $0.id == "endlessIIInertPaddle" }
        XCTAssertEqual(entry?.segments, Int(GameScene.endlessIIPaddlePowerUpTurns),
                       "five marks say five turns, the way the sticky paddle's ring does")
        // Asked for by name rather than taken as the first entry. `first` is whichever clock
        // comes earliest in the ring's own order, so a second clock running for any reason
        // makes this test measure a different power-up and report the answer as this one's -
        // which it did once, in a full-suite run that has not repeated
    }

    /// And a ring measured in seconds draws no marks at all.
    ///
    /// A segmented ring fed a fraction that moves smoothly reads as broken, and a smooth ring
    /// fed one that only moves in steps reads as segmented (round 215's landing marker). The
    /// two have to agree, so the marks follow the clock rather than the power-up's batch.
    func testATimedPaddlePowerUpsRingIsNotSegmented() {
        let scene = paddleScene()
        scene.endlessIICollectPaddleHalo()
        let entry = scene.endlessIIPaddleRingEntries()
            .first { $0.id == "endlessIIPaddleHalo" }
        XCTAssertNotNil(entry, "the halo's own ring, not whichever one happens to be first")
        XCTAssertNil(entry?.segments, "the halo runs on seconds now, so it has no turns to mark")
    }

    func testOtherModesSpendNothing() {
        let scene = paddleScene()
        scene.endlessIICollectInertPaddle()
        scene.gameMode = .classic
        scene.endlessIISpendPaddleTurns()
        XCTAssertEqual(scene.endlessIIInertPaddleClock.remaining,
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
        XCTAssertFalse(scene.endlessIIPortalPaddleClock.countsTurns,
                       "the last turn is spent - what is left is round 231's goodbye second")
        XCTAssertTrue(scene.endlessIIPaddlePortalTook(SKSpriteNode(), collision: 0),
                      "and it still swallows")

        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIPortalPaddleClock.isRunning)
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

        XCTAssertTrue(scene.endlessIIAimMoved(to: CGPoint(x: 150, y: 200)),
                      "the moving finger is the aim")
        let target = scene.endlessIIAimTarget!
        let swung = scene.endlessIIAimAngle(for: target)
        XCTAssertLessThan(swung, .pi/2,
                          "a finger to the right of the ball aims right of straight up")
        // Given a height as well as an x from round 232: the arrow points *at* the finger
        // now, so a touch level with the ball is a direction the clamp has to fold away
    }

    func testNothingIsConsumedWhenNothingIsAimed() {
        let scene = paddleScene()
        XCTAssertFalse(scene.endlessIIAimMoved(to: CGPoint(x: 30, y: 0)))
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
        XCTAssertEqual(scene.stickyPaddleCatches, 0,
                       "the aim takes over from a plain Sticky rather than running beside it")
        // Round 260: the two are one power-up at two settings, so collecting the aimed one
        // ends the plain one. This test used to set three catches and assert all three
        // survived the launch; there are none to survive now, and the claim it was making -
        // that an aimed launch spends no catch - is asserted below instead

        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 3
        // Put back by hand, which no play path does any more, purely so the launch has
        // something it could wrongly spend

        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: .zero, velocity: CGVector(dx: 0, dy: -100))
        scene.endlessIIAimedCatch(scene.ball, isExtra: false)

        XCTAssertTrue(scene.endlessIIAimLaunch())
        XCTAssertFalse(scene.ballIsOnPaddle)
        XCTAssertEqual(scene.stickyPaddleCatches, 3,
                       "Aimed Sticky owns the launch - no sticky catch is spent")
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "it left upward")
    }

    /// **The world no longer stops** (James, round 215: "the game doesn't pause. It acts more
    /// like the existing sticky power up").
    ///
    /// This asked for round 33's design - "can we pause the game whilst the user aims? As soon
    /// as they lift their finger the ball fires and the game continues?" - and that design is
    /// withdrawn. What survives is the half that was never about freezing: a catch holds the
    /// ball, and the launch sends it. Everything else on the field is expected to carry on
    /// exactly as it was, which is what the other ball below now checks.
    func testACatchHoldsTheBallAndLeavesTheRestOfTheFieldAlone() {
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

        XCTAssertTrue(scene.endlessIIAimHold, "a ball is being aimed")
        XCTAssertEqual(flying.physicsBody?.velocity.dx, 70,
                       "the other ball carries on - nothing is frozen any more")
        XCTAssertTrue(scene.pauseExtraBallVelocities.isEmpty,
                      "and nothing was stored up to hand back")

        XCTAssertTrue(scene.endlessIIAimLaunch())
        XCTAssertFalse(scene.endlessIIAimHold, "the tap has taken the shot")
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
        scene.gameMode = .endlessII
        // The mode matters from round 223: what ends what is asked of `EndlessIIExclusions`
        // through `endlessIIDisplace`, which stands down outside Endless Mayhem so that the
        // classic power-ups two of the pairs reach cannot be displaced in Classic
        scene.endlessIICollectInertPaddle()
        scene.endlessIICollectFlippedAngle()

        scene.endlessIICollectAimedSticky()
        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning)
        XCTAssertFalse(scene.endlessIIFlippedAngleClock.isRunning)
    }

    func testCollectingAnAngleBenderCancelsAimedSticky() {
        let scene = GameScene()
        scene.gameMode = .endlessII
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
/// James, round 182, with a screenshot: "with aimed sticky, the paddle got stuck, the ball
/// flew off in the wrong direction and then ended up below the paddle, vibrating around at
/// the bottom of the screen."
///
/// All three symptoms are one stale entry. A held ball can reach the bottom - the paddle is
/// driven out from under it by a portal or a wrap - and the queue survived that by *skipping*
/// nodes that had left the scene. The primary ball never leaves the scene, only moves, so its
/// entry could never be skipped: it stayed at the head of the queue, `endlessIIAimTarget`
/// never went nil, and `endlessIIAimMoved` takes every touch while there is a target, which
/// is a paddle that has stopped moving.
final class AimedStickyLostBallTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSpeedLimit = 100
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 120, height: 12)
        return scene
    }

    private func extraBall(in scene: GameScene) -> SKSpriteNode {
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        extra.name = BallCategoryName
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)
        return extra
    }

    /// James, round 211, approving the parity proposal: the twins wear what the paddle wears.
    ///
    /// A shaped face is the case where visual parity without behavioural parity would be a
    /// lie - a picture of a face the bounce disagrees with - so the mirror takes both or
    /// neither. It takes both.
    func testTheMirrorBouncesByTheSameShapedFaceThePaddleDoes() {
        let scene = mayhem()
        let extra = extraBall(in: scene)
        extra.position = CGPoint(x: 30, y: 10)
        extra.physicsBody?.velocity = CGVector(dx: 0, dy: -100)

        let flat = PaddleBounce.shaped(0.5, by: nil)
        let convex = PaddleBounce.shaped(0.5, by: .convex)
        XCTAssertNotEqual(flat, convex, accuracy: 0.0001,
                          "the shape has to change the reading, or this proves nothing")
    }

    func testALostBallLetsGoOfThePaddle() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        _ = extraBall(in: scene)          // a second ball, so the run carries on
        scene.endlessIIFirstBallWasCaught()
        XCTAssertTrue(scene.endlessIIHeldBalls.contains { $0 === scene.ball })

        _ = scene.endlessIIBallWasLost(scene.ball)

        XCTAssertFalse(scene.endlessIIHeldBalls.contains { $0 === scene.ball },
                       "a ball at the bottom is not being held, whatever happens next")
        XCTAssertNil(scene.endlessIIAimTarget,
                     "so the aim has nothing to hold on to - which is the stuck paddle")
    }

    func testThePaddleMovesAgainAfterAHeldBallIsLost() {
        // The symptom in the words it was reported in: a touch has to reach the paddle again
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        _ = extraBall(in: scene)
        scene.endlessIIFirstBallWasCaught()
        XCTAssertTrue(scene.endlessIIAimMoved(to: CGPoint(x: 40, y: 0)), "while aiming, the aim owns the touch")

        _ = scene.endlessIIBallWasLost(scene.ball)

        XCTAssertFalse(scene.endlessIIAimMoved(to: CGPoint(x: 40, y: 0)),
                       "and once there is nothing to aim, the touch belongs to the paddle")
    }

    func testTheWorldIsNotLeftFrozenAroundABallThatHasGone() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        _ = extraBall(in: scene)
        scene.endlessIIFirstBallWasCaught()
        scene.endlessIIBeginAimHold()
        XCTAssertTrue(scene.endlessIIAimHold)

        _ = scene.endlessIIBallWasLost(scene.ball)
        XCTAssertFalse(scene.endlessIIAimHold, "the hold ends with the ball it was holding")
    }

    /// James, round 185: "aimed sticky still has the same issue as before."
    ///
    /// Round 182 closed the one way the aim target could outlive its ball. It was not the only
    /// way, and it did not need to be: the touch handler called `endlessIIAimMoved` and threw
    /// the answer away, so a drag was swallowed whenever the *hold flag* was up - whether or
    /// not there was anything to aim. These two pin the rule from both ends: the aim only
    /// takes a touch it can use, and a hold with nothing to aim ends itself.
    func testTheAimDeclinesATouchWhenThereIsNothingToAim() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        XCTAssertFalse(scene.endlessIIAimMoved(to: CGPoint(x: 40, y: 0)),
                       "nothing caught yet, so the touch belongs to the paddle")

        _ = extraBall(in: scene)
        scene.endlessIIFirstBallWasCaught()
        XCTAssertTrue(scene.endlessIIAimMoved(to: CGPoint(x: 40, y: 0)), "and once there is, the aim takes it")
    }

    func testAHoldWithNothingLeftToAimEndsItself() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        scene.endlessIIFirstBallWasCaught()
        scene.endlessIIBeginAimHold()
        XCTAssertTrue(scene.endlessIIAimHold)

        scene.endlessIIClearHeldBalls()
        // However the queue emptied - a Wipe, a life lost, a resume - the freeze must not
        // outlive it: a frozen field with no arrow is a game that has stopped
        scene.tickEndlessIIAimHold()

        XCTAssertFalse(scene.endlessIIAimHold)
    }

    func testTheBackstopLeavesARealHoldAlone() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        scene.endlessIIFirstBallWasCaught()
        scene.endlessIIBeginAimHold()

        scene.tickEndlessIIAimHold()
        XCTAssertTrue(scene.endlessIIAimHold, "there is still a ball waiting to be fired")
    }

    func testTheQueueDropsBallsTheSceneHasLetGoOf() {
        // The belt to that pair of braces: an extra that leaves the field takes its offset
        // with it, so the two arrays cannot drift apart across a long run
        let scene = mayhem()
        let extra = extraBall(in: scene)
        scene.stickyPaddleCatches = 3
        XCTAssertTrue(scene.endlessIICatchExtraBall(extra))
        XCTAssertEqual(scene.endlessIIHeldBalls.count, 1)

        extra.removeFromParent()
        scene.pruneEndlessIIHeldBalls()

        XCTAssertTrue(scene.endlessIIHeldBalls.isEmpty)
        XCTAssertTrue(scene.endlessIIHeldOffsets.isEmpty,
                      "index for index, or the next ball launches from the wrong spot")
    }
}

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
        scene.ballSize = 16
        scene.paddleWidth = 120
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.paddle.physicsBody?.categoryBitMask = CollisionTypes.paddleCategory.rawValue
        scene.paddle.name = PaddleCategoryName
        scene.addChild(scene.paddle)
        return scene
    }

    /// James, round 180: the gap "should be bigger - big enough for ball to fit though",
    /// it must not collide - "the ball should be able to fall through the middle" - and a
    /// "longer paddle should make more segments, not longer segments."
    func testTheGapFitsTheBallWithRoomToSpare() {
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 120, standardWidth: 120,
                                                           ballSize: 16)
        XCTAssertEqual(layout.count, 2, "the unexpanded split is the familiar two pieces")
        XCTAssertGreaterThanOrEqual(layout.gap, 16*1.5 - 0.001,
                                    "a ball and a half - falling through is a thing that "
                                    + "happens, not a pixel-perfect trick")
    }

    func testALongerPaddleMakesMoreSegmentsNotLongerOnes() {
        let standard = GameScene.endlessIIDoublePaddleLayout(span: 120, standardWidth: 120,
                                                             ballSize: 16)
        let expanded = GameScene.endlessIIDoublePaddleLayout(span: 240, standardWidth: 120,
                                                             ballSize: 16)
        XCTAssertGreaterThan(expanded.count, standard.count, "more segments")
        XCTAssertEqual(expanded.segment, standard.segment, accuracy: 0.001,
                       "each the size the split has always shown, not stretched")
    }

    func testAShrunkenPaddleGivesUpPieceNeverGap() {
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 70, standardWidth: 120,
                                                           ballSize: 16)
        XCTAssertEqual(layout.count, 2, "one segment is not a split at all")
        XCTAssertGreaterThanOrEqual(layout.gap, 16*1.5 - 0.001,
                                    "a gap the ball cannot fall through is the one thing "
                                    + "this must never build")
    }

    func testTheLayoutAlwaysSpansThePaddleExactly() {
        for span in [70, 120, 180, 240, 300] as [CGFloat] {
            let layout = GameScene.endlessIIDoublePaddleLayout(span: span, standardWidth: 120,
                                                               ballSize: 16)
            let total = CGFloat(layout.count)*layout.segment
                + CGFloat(layout.count - 1)*layout.gap
            XCTAssertEqual(total, span, accuracy: 0.001, "at span \(span)")
        }
    }

    func testItEndsOnPaddleHitsNowNotOnAClockNobodyRan() {
        // Round 180: "it doesn't ever end. This should be based on paddle hits, not timed."
        // The old twelve seconds were in the Lock's freeze list but in no run-down loop,
        // so nothing ever decremented them
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        XCTAssertTrue(scene.endlessIIDoublePaddleClock.countsTurns)

        for _ in 0..<GameScene.endlessIIDoublePaddleTurns {
            scene.endlessIISpendPaddleTurns()
        }
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIDoublePaddleClock.isRunning,
                       "five landings, a second's goodbye, and the paddle is whole again")
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
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 120, standardWidth: 120,
                                                           ballSize: 16)
        let gapShare = layout.gap*CGFloat(layout.count - 1)/120
        XCTAssertEqual(split, whole*(1 - gapShare), accuracy: whole*0.02,
                       "and what is missing is exactly the gaps - a ball down one has "
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

    func testItDrawsItsSegmentsAndStopsDrawingItself() {
        let scene = mayhem()
        scene.paddle.texture = SKTexture(image: PowerUpIcon.doublePaddle)
        scene.endlessIICollectDoublePaddle()

        let layout = GameScene.endlessIIDoublePaddleLayout(span: 120, standardWidth: 120,
                                                           ballSize: 16)
        XCTAssertEqual(halves(scene).count, layout.count)
        XCTAssertNil(scene.paddle.texture, "or the split would be drawn over a whole paddle")
        let expected = 120/2 - layout.segment/2
        for half in halves(scene) {
            XCTAssertEqual(abs(half.position.x), expected, accuracy: 0.01,
                           "each piece sits over its own body")
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
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 200, standardWidth: 120,
                                                           ballSize: 16)
        XCTAssertEqual(halves(scene).count, layout.count)
        XCTAssertGreaterThan(layout.count, 2,
                             "a wider paddle is cut into more segments, not longer ones - "
                             + "round 180's rule applied to the recut too")
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

        for _ in 0..<GameScene.endlessIIDoublePaddleTurns {
            scene.endlessIISpendPaddleTurns()
        }
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        // The last landing starts a second's goodbye rather than ending it (round 231), so
        // the paddle is still split until that second is up
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

    func testItIsAClockTheWipeClearsAndTheLockIgnores() {
        // Round 180 moved it to paddle hits, and a Lock stops time - it has no opinion
        // about clocks that do not spend any (the sticky paddle's own arrangement)
        XCTAssertFalse(GameScene.endlessIITimedClockPaths.contains(\GameScene.endlessIIDoublePaddleClock))
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
        for _ in 0..<GameScene.endlessIIDoublePaddleTurns {
            scene.endlessIISpendPaddleTurns()
        }
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
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

    /// James, round 180: "the mirrored paddle should be a different colour (Giga-Ball
    /// green/yellow) and sit behind the original paddle so it's clear which one follows the
    /// tap. It also wasn't counting down it's segments, it just remained on the whole time."
    func testTheMirrorIsGreenAndStandsBehindThePaddle() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }

        XCTAssertLessThan(mirror.zPosition, scene.paddle.zPosition,
                          "when the two cross, the one in front is yours")
        XCTAssertEqual(mirror.color, GameScene.endlessIIMirrorPaddleColour,
                       "the Giga-Ball lime, so the pair never read as two of yours")
        XCTAssertEqual(mirror.colorBlendFactor, 1, accuracy: 0.001)
    }

    func testTheMirrorStaysGreenThroughTheDressRefresh() {
        // The tick re-dresses the mirror in the paddle's texture every frame, and a texture
        // write leaves whatever colour the sprite carries - one missed re-tint and the
        // mirror flashes white
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.tickEndlessIIMirrorPaddle()
        XCTAssertEqual(mirror(scene)?.color, GameScene.endlessIIMirrorPaddleColour)
    }

    /// An expanded paddle's twin expands with it.
    ///
    /// The tick watched `paddle.size` and rebuilt the mirror when it moved - but Expand and
    /// Shrink animate `paddle.xScale` and never touch the size, so for those two the check
    /// never fired and the mirror stayed the width it was born at. The one power-up in the
    /// game whose whole job is to be the paddle was the width of a paddle that was not there.
    func testTheMirrorGrowsWithAnExpandedPaddle() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.paddle.xScale = 1.6
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertEqual(mirror(scene)?.xScale ?? 0, scene.paddle.xScale, accuracy: 0.001,
                       "the paddle expanded and its twin did not")
    }

    /// And one collected part-way through an Expand arrives the right size.
    func testAMirrorCollectedDuringAnExpandArrivesExpanded() {
        let scene = mayhem()
        scene.paddle.xScale = 0.7
        scene.endlessIICollectMirrorPaddle()

        XCTAssertEqual(mirror(scene)?.xScale ?? 0, 0.7, accuracy: 0.001,
                       "it appeared at the wrong size and would have jumped on its first tick")
    }

    /// The twin's body is traced from the shape it is wearing.
    ///
    /// Round 211 gave the mirror the shaped face, and it was right until round 213 stopped the
    /// shapes being formulas: from then on the paddle's dome was a traced silhouette and the
    /// mirror was a rectangle wearing a picture of one. It showed a shape and gave a flat
    /// bounce, which is the exact parity round 211 said was worth refusing.
    func testTheMirrorTracesTheShapeItIsWearing() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPaddleSurface(.convex)
        scene.endlessIIPaddleShapeArtName = "regularPaddleConvex"
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertEqual(scene.endlessIIMirrorPaddleBodyArt, "regularPaddleConvex",
                       "the twin kept a flat body under a shaped picture")
    }

    /// And it notices a shape being swapped for one exactly as tall.
    ///
    /// The rebuild used to be gated on the size moving. The two wedges are the same height as
    /// each other, so swapping one for the other changes the slope the ball meets and nothing
    /// the size check can see - a mirror sloped the wrong way, which on a surface whose whole
    /// job is to be the opposite of the paddle is the worst possible thing to get wrong.
    func testTheMirrorNoticesAWedgeBecomingItsMirror() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPaddleSurface(.wedgeLeft)
        scene.endlessIIPaddleShapeArtName = "regularPaddleWedgeLeft"
        scene.tickEndlessIIMirrorPaddle()
        XCTAssertEqual(scene.endlessIIMirrorPaddleBodyArt, "regularPaddleWedgeRight")

        scene.endlessIICollectPaddleSurface(.wedgeRight)
        scene.endlessIIPaddleShapeArtName = "regularPaddleWedgeRight"
        scene.tickEndlessIIMirrorPaddle()
        XCTAssertEqual(scene.endlessIIMirrorPaddleBodyArt, "regularPaddleWedgeLeft",
                       "the twin was still sloped the old way")
    }

    /// A wedge-left paddle gets a wedge-right twin, in the picture and in the body both.
    ///
    /// "The mirror paddle should be a mirror of the original paddle, that includes the
    /// paddle's shape. e.g. if the original paddle is wedge left, the mirror paddle should be
    /// wedge right" (James, round 233). The twin wore the paddle's own picture, which for the
    /// one pair of faces that is not symmetrical made it a copy rather than a reflection: two
    /// paddles sloping the same way, on the surface whose whole job is to be the opposite one.
    func testTheMirrorWearsTheReflectionOfAWedge() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPaddleSurface(.wedgeLeft)
        scene.endlessIIPaddleShapeArtName = "regularPaddleWedgeLeft"
        scene.tickEndlessIIMirrorPaddle()

        XCTAssertEqual(scene.endlessIIMirrorPaddleSurface, .wedgeRight,
                       "the twin sloped the same way as the paddle")
        XCTAssertEqual(scene.endlessIIMirrorPaddleShapeArtName, "regularPaddleWedgeRight")
        XCTAssertEqual(scene.endlessIIMirrorPaddleBodyArt, "regularPaddleWedgeRight",
                       "the picture was reflected and the body it bounces off was not")
    }

    /// A symmetrical face is its own reflection, so the twin wears exactly what the paddle has.
    ///
    /// Worth pinning: the cheap way to mirror a sprite is a negative `xScale`, and it would
    /// have looked right on every shape here while leaving the traced body's handedness up to
    /// the engine. Naming the reflected artwork instead means a face with no drawn opposite -
    /// which is all four of these - keeps the picture it already had rather than an undefined
    /// one.
    func testASymmetricalShapeIsItsOwnReflection() {
        for surface in [PaddleBounce.Surface.convex, .concave, .wavy, .jagged] {
            XCTAssertEqual(surface.mirrored, surface,
                           "\(surface.displayName) was swapped for a face nobody has drawn")
        }
        XCTAssertEqual(PaddleBounce.Surface.wedgeLeft.mirrored, .wedgeRight)
        XCTAssertEqual(PaddleBounce.Surface.wedgeRight.mirrored, .wedgeLeft)
    }

    /// And the formula fallback is reflected too, for a face whose art is missing.
    ///
    /// The two wedges are the one pair `PaddleBounce.shaped` gives genuinely different answers
    /// for - every other face is odd, so its reflection is itself - and the fallback is what
    /// answers when a theme has no shaped artwork. A mirror that traced the reflection but
    /// calculated the original would slope one way in the picture and the other in the bounce.
    func testTheFallbackFormulaIsReflectedAsWell() {
        XCTAssertEqual(PaddleBounce.shaped(0, by: .wedgeLeft.mirrored),
                       PaddleBounce.shaped(0, by: .wedgeRight), accuracy: 0.0001)
        XCTAssertNotEqual(PaddleBounce.shaped(0, by: .wedgeLeft),
                          PaddleBounce.shaped(0, by: .wedgeRight),
                          "the two wedges stopped being opposites and this test proves nothing")
    }

    /// With no shape running it goes back to being a rectangle.
    func testAPlainMirrorIsNotTraced() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPaddleSurface(.concave)
        scene.endlessIIPaddleShapeArtName = "regularPaddleConcave"
        scene.tickEndlessIIMirrorPaddle()

        scene.endlessIIPaddleSurfaceClock.reset()
        scene.endlessIIPaddleShapeArtName = nil
        scene.tickEndlessIIMirrorPaddle()
        XCTAssertNil(scene.endlessIIMirrorPaddleBodyArt,
                     "the shape expired and the twin kept its silhouette")
    }

    /// The twin answers to the paddle's own power-ups.
    ///
    /// Round 225's matrix: the mirror "also becomes inert" and "also has the bounce angle
    /// flipped". Its influence was a hard 1, which made it the one surface in the mode an
    /// Inert Paddle could not reach - and a power-up that switches off half the paddles reads
    /// as broken rather than as half-working.
    func testAnInertPaddleFlattensTheMirrorToo() {
        let scene = mayhem()
        scene.angleAdjustmentK = 45
        scene.minAngleDeg = 20
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }

        func outgoing(landingAt x: CGFloat) -> CGFloat {
            scene.ball.position = CGPoint(x: mirror.position.x + x, y: mirror.position.y + 8)
            scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -300)
            scene.endlessIIMirrorPaddleHit(scene.ball)
            return scene.ball.physicsBody?.velocity.dx ?? 0
        }

        XCTAssertNotEqual(outgoing(landingAt: -40), outgoing(landingAt: 40), accuracy: 1,
                          "where the ball lands on the twin should bend its bounce")

        scene.endlessIICollectInertPaddle()
        XCTAssertEqual(outgoing(landingAt: -40), outgoing(landingAt: 40), accuracy: 1,
                       "an Inert Paddle should reach the twin as well")
    }

    /// The twin fires on the same beat, from its own mirrored edge.
    ///
    /// Round 225's matrix: "mirrored paddle gets lasers". Copied from the laser just built
    /// rather than built again, so its texture, its theme and whether a Giga-Ball has made it
    /// pass through bricks are all the paddle's laser's, and nothing here has to be told when
    /// any of that changes.
    func testTheMirrorFiresOnTheSameBeat() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }

        let laser = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 20))
        laser.name = LaserCategoryName
        laser.position = CGPoint(x: scene.paddle.position.x - 40, y: scene.paddle.position.y)
        scene.endlessIIFireMirrorLaser(matching: laser)

        var twins: [SKNode] = []
        scene.enumerateChildNodes(withName: LaserCategoryName) { node, _ in
            if node !== laser { twins.append(node) }
        }
        XCTAssertEqual(twins.count, 1, "the twin did not fire")
        XCTAssertEqual(twins.first?.position.x ?? 0, mirror.position.x + 40, accuracy: 0.01,
                       "a shot leaving the paddle's left edge leaves the twin's right")
    }

    /// And nothing fires when no mirror is standing.
    func testNoMirrorMeansNoSecondShot() {
        let scene = mayhem()
        let laser = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 20))
        laser.name = LaserCategoryName
        laser.position = CGPoint(x: -40, y: -300)
        scene.addChild(laser)
        scene.endlessIIFireMirrorLaser(matching: laser)

        var found = 0
        scene.enumerateChildNodes(withName: LaserCategoryName) { _, _ in found += 1 }
        XCTAssertEqual(found, 1, "a shot with no twin to fire from fired twice")
    }

    func testTheMirrorEndsOnPaddleHitsNow() {
        // The old twelve seconds were in the Lock's freeze list but in no run-down loop -
        // collected once, the mirror simply never left and its ring never moved
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        XCTAssertTrue(scene.endlessIIMirrorPaddleClock.countsTurns)

        for _ in 0..<GameScene.endlessIIMirrorPaddleTurns {
            scene.endlessIISpendPaddleTurns()
        }
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIMirrorPaddleClock.isRunning)
        scene.tickEndlessIIMirrorPaddle()
        XCTAssertNil(mirror(scene), "and the mirror leaves with its clock")
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

    /// A second collection refills it rather than standing a second mirror.
    ///
    /// It used to check the clock had grown; from round 220 a second collection resets it, so
    /// what matters here is that the *field* is unchanged - one mirror, with a full clock.
    /// That was always the half of this test worth having.
    func testASecondCollectionRefillsItRatherThanStackingTwo() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIIMirrorPaddleClock.spendTurn()
        scene.endlessIICollectMirrorPaddle()

        XCTAssertEqual(scene.endlessIIMirrorPaddleClock.remaining,
                       GameScene.endlessIIPaddlePowerUpTurns, "the turns did not come back")
        var found = 0
        scene.enumerateChildNodes(withName: GameScene.endlessIIMirrorPaddleName) { _, _ in
            found += 1
        }
        XCTAssertEqual(found, 1, "full again, not two of them")
    }

    func testItIsNeverStranded() {
        // A surface left standing after its clock stops would change the rest of the run -
        // the Safety Paddle's own rule
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        for _ in 0..<GameScene.endlessIIMirrorPaddleTurns {
            scene.endlessIIMirrorPaddleClock.spendTurn()
        }
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

/// Cluster (§12.0, James's round-169 design): "a set of ~12 tiny balls are released upwards
/// at random angles from the centre of the paddle. If they hit something they count as a
/// single hit, but are also destroyed immediately. They do not combine with other power-ups.
/// They are just normal balls."
final class EndlessIIClusterPowerUpTests: XCTestCase {
// Not EndlessIIClusterTests - that name belongs to the brick formations' suite

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSize = 12
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 40, y: -300)
        scene.addChild(scene.paddle)
        return scene
    }

    private func pellets(_ scene: GameScene) -> [SKSpriteNode] {
        var found: [SKSpriteNode] = []
        scene.enumerateChildNodes(withName: ClusterCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { found.append(sprite) }
        }
        return found
    }

    func testTheBurstIsTwelveTinyBallsFromThePaddlesCentre() {
        let scene = mayhem()
        scene.endlessIIReleaseCluster()

        let burst = pellets(scene)
        XCTAssertEqual(burst.count, GameScene.endlessIIClusterCount)
        for pellet in burst {
            XCTAssertEqual(pellet.position.x, scene.paddle.position.x, accuracy: 0.001,
                           "from the centre of the paddle, wherever the paddle is")
            XCTAssertLessThan(pellet.size.width, scene.ballSize,
                              "tiny - visibly not a run ball")
        }
    }

    func testEveryBallLeavesUpwardsAtItsOwnAngle() {
        let scene = mayhem()
        scene.endlessIIReleaseCluster()

        var headings = Set<Int>()
        for pellet in pellets(scene) {
            let velocity = pellet.physicsBody?.velocity ?? .zero
            XCTAssertGreaterThan(velocity.dy, 0, "released upwards - all of them")
            headings.insert(Int(atan2(velocity.dy, velocity.dx)*180 / .pi))
        }
        XCTAssertGreaterThan(headings.count, 3,
                             "random angles - a burst, not a volley in step")
    }

    func testAClusterBallIsAmmunitionAndNotARunBall() {
        // "They are just normal balls" means normal hit rules, not membership of the run:
        // a Multi-Ball ball is a ball the run continues on, and a cluster ball is not
        let scene = mayhem()
        scene.endlessIIReleaseCluster()

        XCTAssertTrue(scene.endlessIIExtraBalls.isEmpty,
                      "not in the extras - losing all twelve costs nothing")
        for pellet in pellets(scene) {
            XCTAssertNotEqual(pellet.name, BallCategoryName)
            XCTAssertEqual(pellet.physicsBody?.categoryBitMask,
                           CollisionTypes.laserCategory.rawValue,
                           "the laser's category, so every brick already tests contact "
                           + "with it and hitBrick's laser path does one-hit-then-gone")
        }
    }

    func testAClusterBallBouncesOffASideWallAndDiesAtTheCeiling() {
        // The ball half of "just normal balls": a laser dies on any block it meets, and a
        // cluster ball only dies where there is nothing to bounce toward
        let scene = mayhem()
        let side = SKSpriteNode(); side.size = CGSize(width: 10, height: 400)
        let top = SKSpriteNode(); top.size = CGSize(width: 400, height: 10)
        let pellet = SKNode(); pellet.name = ClusterCategoryName

        XCTAssertTrue(scene.endlessIIClusterSurvivesWall(pellet, block: side))
        XCTAssertFalse(scene.endlessIIClusterSurvivesWall(pellet, block: top))

        let laser = SKNode(); laser.name = LaserCategoryName
        XCTAssertFalse(scene.endlessIIClusterSurvivesWall(laser, block: side),
                       "a real laser still dies on whatever block it meets")
    }

    func testTheBurstOnlyExistsInMayhem() {
        let scene = mayhem()
        scene.gameMode = .classic
        scene.endlessIIReleaseCluster()
        XCTAssertTrue(pellets(scene).isEmpty)
    }

    func testClusterIsInThePoolAndWorthAGoodChip() {
        // §8.6: a style - or a power-up - has to be in a pool to exist; from the outside
        // "never offered" looks exactly like "very rare"
        let scene = mayhem()
        scene.applyEndlessRowPowerUpWeights()
        XCTAssertGreaterThan(scene.powerUpProbArray[61], 0)

        let setup = LevelPackSetup()
        XCTAssertEqual(setup.powerUpNameArray[61], "Cluster")
        XCTAssertEqual(setup.powerUpMultiplierArray[61], "+0.1", "good, and says so")
        XCTAssertFalse(GameScene.endlessIIHarmfulPowerUps.contains(61),
                       "so a free shot may set it off, and No Good News days zero it")
    }
}

/// Ball Spin (§12.0, James's play-test idea from the second round): "the paddle's own velocity
/// at contact grips the ball - as if there were friction between the two - and the ball leaves
/// on a curved path, curving harder the faster the paddle was moving."
final class EndlessIIBallSpinTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSpeedLimit = 400
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(scene.paddle)
        return scene
    }

    // MARK: - The grip

    func testAStillPaddleGripsNothing() {
        XCTAssertEqual(EndlessIIBallSpin.turnRate(paddleSpeed: 0), 0)
        XCTAssertEqual(EndlessIIBallSpin.turnRate(
            paddleSpeed: EndlessIIBallSpin.gripThreshold - 1), 0,
            "a paddle creeping along is not friction, it is noise")
    }

    func testFasterPaddleCurvesHarder() {
        let gentle = EndlessIIBallSpin.turnRate(paddleSpeed: 300)
        let brisk = EndlessIIBallSpin.turnRate(paddleSpeed: 900)
        XCTAssertGreaterThan(gentle, 0)
        XCTAssertGreaterThan(brisk, gentle, "curving harder the faster the paddle was moving")
    }

    func testTheCurveIsCappedHoweverHardThePaddleIsFlicked() {
        let fast = EndlessIIBallSpin.turnRate(paddleSpeed: EndlessIIBallSpin.fullGripSpeed)
        let absurd = EndlessIIBallSpin.turnRate(paddleSpeed: 12_000)
        XCTAssertEqual(absurd, fast, accuracy: 0.0001,
                       "a flick can be silly, and the ball still has to be playable")
        XCTAssertEqual(fast, EndlessIIBallSpin.strongestTurn, accuracy: 0.0001)
    }

    func testTheBallCurvesTheWayThePaddleWasTravelling() {
        // "As if there were friction between the two"
        XCTAssertGreaterThan(EndlessIIBallSpin.turnRate(paddleSpeed: 500), 0)
        XCTAssertLessThan(EndlessIIBallSpin.turnRate(paddleSpeed: -500), 0)
    }

    // MARK: - The flight

    func testTheCurveKeepsTheBallsSpeedExactly() {
        // The whole game rests on the ball holding its speed - so the curve is a rotation,
        // never a sideways push
        let before = CGVector(dx: 120, dy: 260)
        let after = EndlessIIBallSpin.turned(before, rate: 1.2, delta: 1/60)
        XCTAssertEqual(hypot(after.dx, after.dy), hypot(before.dx, before.dy), accuracy: 0.001)
        XCTAssertNotEqual(atan2(after.dy, after.dx), atan2(before.dy, before.dx),
                          "but it does turn")
    }

    func testTheGripIsSpentAsTheBallTravels() {
        let rate = EndlessIIBallSpin.turnRate(paddleSpeed: 900)
        let afterHalf = EndlessIIBallSpin.decayed(rate, over: 0.5)
        let afterOne = EndlessIIBallSpin.decayed(rate, over: 1)

        XCTAssertLessThan(abs(afterHalf), abs(rate))
        XCTAssertLessThan(abs(afterOne), abs(afterHalf),
                          "sharpest off the paddle, straightening as it goes")
    }

    // MARK: - In the scene

    func testAPaddleHitWhileItRunsGripsTheBall() {
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        scene.endlessIIPaddleGripSpeed = 800
        // The grip reads its own short-memory sample since round 214, so that a swipe
        // followed by a steady hand still curves the ball - see `tickEndlessIIPaddleTravel`

        scene.endlessIIGripBall(scene.ball)
        XCTAssertNotNil(scene.endlessIIBallSpinRates[ObjectIdentifier(scene.ball)])
    }

    func testNothingIsGrippedWithoutThePowerUp() {
        let scene = mayhem()
        scene.endlessIIPaddleGripSpeed = 800
        // The grip reads its own short-memory sample since round 214, so that a swipe
        // followed by a steady hand still curves the ball - see `tickEndlessIIPaddleTravel`
        scene.endlessIIGripBall(scene.ball)
        XCTAssertTrue(scene.endlessIIBallSpinRates.isEmpty)
    }

    func testACaughtBallIsNotGripped() {
        // A catch is not a bounce, and Aimed Sticky owns what happens next - which is
        // §12.0's "conflicts with the paddle group", in the one place it actually bites
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        scene.endlessIIPaddleGripSpeed = 800
        // The grip reads its own short-memory sample since round 214, so that a swipe
        // followed by a steady hand still curves the ball - see `tickEndlessIIPaddleTravel`
        scene.endlessIIHeldBalls.append(scene.ball)

        scene.endlessIIGripBall(scene.ball)
        XCTAssertTrue(scene.endlessIIBallSpinRates.isEmpty)
    }

    func testACurveIsForgottenWhenItsBallIsCaught() {
        // The catch owns what happens next: a ball released by an aim must leave at the
        // angle the aim chose, not that plus whatever the last flick was still worth
        let scene = mayhem()
        scene.endlessIIBallSpinRates[ObjectIdentifier(scene.ball)] = 1.0
        scene.endlessIIHeldBalls.append(scene.ball)

        scene.applyEndlessIIBallSpin(1/60)
        XCTAssertTrue(scene.endlessIIBallSpinRates.isEmpty)
    }

    func testACurveIsForgottenWhenItsBallLeavesTheField() {
        // The rates are keyed by ball, so they must not grow a tail of dead entries
        let scene = mayhem()
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)
        scene.endlessIIBallSpinRates[ObjectIdentifier(extra)] = 1.0

        extra.removeFromParent()
        scene.applyEndlessIIBallSpin(1/60)
        XCTAssertTrue(scene.endlessIIBallSpinRates.isEmpty)
    }

    func testItEndsOnPaddleHitsLikeTheRestOfTheBatch() {
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        XCTAssertTrue(scene.endlessIIBallSpinClock.countsTurns)

        for _ in 0..<GameScene.endlessIIBallSpinTurns {
            scene.endlessIISpendPaddleTurns()
        }
        XCTAssertTrue(scene.endlessIIBallSpinClock.lingering,
                      "the last turn starts the goodbye rather than ending it (round 231)")
        XCTAssertTrue(scene.endlessIIBallSpinClock.countsTurns,
                      "it keeps counting turns through the goodbye (round 263). The goodbye "
                      + "used to be expressed by blanking this and rewriting the clock as a "
                      + "one-second timer, which refilled the ring and took its segment marks "
                      + "off for the last second - two things nobody had asked for")

        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIBallSpinClock.isRunning)
    }

    func testItLeavesTheOtherModesAlone() {
        let scene = mayhem()
        scene.gameMode = .classic
        scene.endlessIICollectBallSpin()
        XCTAssertFalse(scene.endlessIIBallSpinClock.isRunning)
    }

    func testThePaddleSpeedIsSampledFromItsOwnMovement() {
        // Sampled once a frame rather than read at the contact, where the paddle has often
        // already been moved again by the same frame's touch
        let scene = mayhem()
        scene.paddle.position.x = 0
        scene.endlessIIPaddleLastX = 0
        scene.paddle.position.x = 10

        scene.tickEndlessIIPaddleTravel(0.1)
        XCTAssertEqual(scene.endlessIIPaddleSpeed, 100, accuracy: 0.001, "points per second")

        scene.tickEndlessIIPaddleTravel(0.1)
        XCTAssertEqual(scene.endlessIIPaddleSpeed, 0, accuracy: 0.001,
                       "a paddle let go of reads as still, not as holding the last flick")
    }

    func testItIsInThePoolAndWorthAGoodChip() {
        let scene = mayhem()
        scene.applyEndlessRowPowerUpWeights()
        XCTAssertGreaterThan(scene.powerUpProbArray[62], 0)

        let setup = LevelPackSetup()
        XCTAssertEqual(setup.powerUpNameArray[62], "Ball Spin")
        XCTAssertEqual(setup.powerUpMultiplierArray[62], "+0.1")
        XCTAssertEqual(setup.powerUpTimerArray[62], "5 paddle hits")
    }
}

/// Round 184's three paddle answers: the steering lead, the halo standing still, and the
/// safety paddle wearing the player's own paddle.
final class EndlessIIRound184Tests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 400
        scene.paddleWidth = 100
        scene.paddle.size = CGSize(width: 100, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.addChild(scene.paddle)
        return scene
    }

    // MARK: - Ball Steering reaching the walls

    /// James, round 184: "it's currently impossible/very difficult to get the ball to hit
    /// bricks in the columns closest to the walls as the ball wants to be always centred over
    /// the paddle."
    ///
    /// The cause is arithmetic rather than feel: the ball was drawn to the paddle's *centre*,
    /// and a paddle's centre cannot come closer to a wall than half its own width - so the
    /// outer half-paddle was unreachable however well the player played.
    func testAStillPaddleSteersExactlyAsItDid() {
        XCTAssertEqual(EndlessIIPaddleEffects.steeringLead(paddleSpeed: 0, fieldWidth: 400), 0,
                       "a parked paddle leads by nothing")
    }

    func testASweptPaddleCarriesTheBallAheadOfIt() {
        let lead = EndlessIIPaddleEffects.steeringLead(paddleSpeed: 600, fieldWidth: 400)
        XCTAssertGreaterThan(lead, 0, "the ball runs ahead of a paddle sweeping right")
        XCTAssertLessThan(EndlessIIPaddleEffects.steeringLead(paddleSpeed: -600,
                                                              fieldWidth: 400), 0)
    }

    func testTheLeadCannotThrowTheBallAcrossTheField() {
        let absurd = EndlessIIPaddleEffects.steeringLead(paddleSpeed: 20_000, fieldWidth: 400)
        XCTAssertLessThanOrEqual(absurd, 400*EndlessIIPaddleEffects.steeringLeadCap + 0.001)
    }

    func testASweepReachesNearerTheWallThanAParkedPaddleCan() {
        // The whole point, stated as the thing the player was asking for
        let paddleAtItsLimit: CGFloat = 150      // a 100-wide paddle against a 400-wide field
        let parked = EndlessIIPaddleEffects.steeredTowards(
            paddleX: paddleAtItsLimit, from: 0, leftWall: -200, rightWall: 200, radius: 5)
        let swept = EndlessIIPaddleEffects.steeredTowards(
            paddleX: paddleAtItsLimit, from: 0, leftWall: -200, rightWall: 200, radius: 5,
            paddleSpeed: 900, fieldWidth: 400)

        XCTAssertGreaterThan(swept, parked,
                             "sweeping toward the wall reaches columns a parked paddle cannot")
    }

    func testTheBallIsStillNeverPushedThroughAWall() {
        let steered = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 190, from: 190, leftWall: -200, rightWall: 200, radius: 5,
            paddleSpeed: 5000, fieldWidth: 400)
        XCTAssertLessThanOrEqual(steered, 195.001)
    }

    // MARK: - The halo standing still

    /// James, round 184: "the paddle halo power up is much too powerful. Just moving the
    /// paddle side to side allows the player to gain a lot of height quickly."
    func testTheHaloStandsInTheMiddleWhereverThePaddleIs() {
        let scene = mayhem()
        scene.paddle.position.x = 150
        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.x, 0,
                       "swept side to side, the glow no longer sweeps with it")
        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.y, scene.paddle.position.y,
                       "still at the paddle's height - it is the paddle's field, not the sky")
    }

    // MARK: - The safety paddle's look

    /// James, round 184: "safety paddle should be the same width as the standard paddle and
    /// look the same but be giga-ball yellow/green."
    func testTheSafetyPaddleIsThePaddlesTwin() {
        let scene = mayhem()
        scene.endlessIICollectSafetyPaddle()

        guard let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return XCTFail("a safety paddle stands") }
        XCTAssertEqual(bar.size.width, scene.paddle.size.width, accuracy: 0.001)
        XCTAssertEqual(bar.size.height, scene.paddle.size.height, accuracy: 0.001)
        XCTAssertEqual(bar.color, GameScene.endlessIIHaloColour, "the Giga-Ball lime")
        XCTAssertEqual(bar.colorBlendFactor, 1, accuracy: 0.001)
    }
}

/// The bounce a shaped paddle gives.
///
/// James, round 213: "when these paddles are enabled, the ball physics is determined by the
/// shape of the paddle, not the ball angle calculations."
///
/// So the engine's reflection off the silhouette is the answer, and the angle formula is
/// skipped rather than layered on top. Two things still hold, because they are true of every
/// paddle bounce and nothing about a shape changes them: the ball leaves at the run's own
/// speed, and never flat enough to run sideways across the field.
final class ShapedPaddleBounceTests: XCTestCase {

    private func shaped() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSpeedLimit = 400
        scene.minAngleDeg = 20
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectPaddleSurface(.convex)
        scene.endlessIIPaddleShapeArtName = "regularPaddleConvex"
        return scene
    }

    func testTheShapeOnlyOwnsTheBounceWhileItIsRunning() {
        let scene = shaped()
        XCTAssertTrue(scene.endlessIIShapeOwnsTheBounce)

        scene.endlessIIPaddleSurfaceClock.reset()
        XCTAssertFalse(scene.endlessIIShapeOwnsTheBounce)
        XCTAssertFalse(scene.endlessIIApplyShapedBounce(to: scene.ball),
                       "with no shape running the ordinary bounce has to be left alone")
    }

    /// The direction is the shape's, so a reflection off the side of a dome is kept as a
    /// steep shot - it is only the speed that is set.
    func testTheReflectionIsKeptAndOnlyTheSpeedIsSet() {
        let scene = shaped()
        scene.ball.physicsBody?.velocity = CGVector(dx: 30, dy: 40)   // speed 50, well off pace
        XCTAssertTrue(scene.endlessIIApplyShapedBounce(to: scene.ball))

        let out = scene.ball.physicsBody!.velocity
        XCTAssertEqual(hypot(out.dx, out.dy), scene.ballSpeedLimit, accuracy: 0.001)
        XCTAssertEqual(atan2(Double(out.dy), Double(out.dx)),
                       atan2(40, 30), accuracy: 0.001, "the shape's own answer, kept")
    }

    /// **A dome can reflect a ball down its own side.** A paddle that returned the ball into
    /// the floor would be a shape that loses the run rather than one that makes it harder.
    func testABallReflectedDownwardsIsSentBackUp() {
        let scene = shaped()
        scene.ball.physicsBody?.velocity = CGVector(dx: 200, dy: -300)
        scene.endlessIIApplyShapedBounce(to: scene.ball)
        XCTAssertGreaterThan(scene.ball.physicsBody!.velocity.dy, 0)
    }

    func testItIsNeverFlatEnoughToRunSideways() {
        let scene = shaped()
        for dx in [-400.0, -50, -1, 1, 50, 400] as [CGFloat] {
            scene.ball.physicsBody?.velocity = CGVector(dx: dx, dy: 0.5)
            scene.endlessIIApplyShapedBounce(to: scene.ball)
            let out = scene.ball.physicsBody!.velocity
            let degrees = abs(atan2(Double(out.dy), Double(out.dx))*180/Double.pi)
            XCTAssertGreaterThanOrEqual(degrees, scene.minAngleDeg - 0.001, "dx \(dx)")
            XCTAssertLessThanOrEqual(degrees, 180 - scene.minAngleDeg + 0.001, "dx \(dx)")
        }
    }

    /// The retired shape has no art, so it can never take the bounce - the one case where
    /// "no picture" has to mean "no physics" rather than falling back to something.
    func testTheRetiredShapeHasNoArtAndSoOwnsNothing() {
        let scene = shaped()
        XCTAssertNil(scene.endlessIIPaddleShapeTextureName(.jagged))
    }
}

/// What the paddle's grip reads at the moment of contact.
///
/// James, round 214: "ball spin doesn't seem to do anything."
///
/// The grip is sampled on the frame the ball lands, and a frame at 120fps is eight
/// milliseconds of finger. A player swipes the paddle across and then holds it steady to meet
/// the ball - so the instantaneous speed at impact is very often zero, and a power-up that only
/// works if you happen to still be moving on that exact frame reads as one that does nothing.
final class PaddleGripMemoryTests: XCTestCase {

    private func moving() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.addChild(scene.paddle)
        return scene
    }

    /// The flick survives the pause before the bounce.
    func testAFlickIsStillRememberedAMomentAfterTheFingerStops() {
        let scene = moving()
        scene.endlessIIPaddleLastX = 0
        scene.paddle.position.x = 0

        scene.paddle.position.x = 10
        scene.tickEndlessIIPaddleTravel(1.0/120)          // a real flick
        let flick = scene.endlessIIPaddleGripSpeed
        XCTAssertGreaterThan(flick, EndlessIIBallSpin.gripThreshold)

        for _ in 0..<6 { scene.tickEndlessIIPaddleTravel(1.0/120) }   // held still, 50ms
        XCTAssertGreaterThan(scene.endlessIIPaddleGripSpeed,
                             EndlessIIBallSpin.gripThreshold,
                             "the flick was forgotten before the ball could arrive")
        XCTAssertLessThan(scene.endlessIIPaddleGripSpeed, flick, "and it is fading, not held")
    }

    /// But not for long: this bridges a swipe to a bounce, it does not give the paddle a
    /// memory. A paddle parked for half a second grips nothing.
    func testAPaddleLeftAloneStopsGripping() {
        let scene = moving()
        scene.endlessIIPaddleLastX = 0
        scene.paddle.position.x = 10
        scene.tickEndlessIIPaddleTravel(1.0/120)

        for _ in 0..<60 { scene.tickEndlessIIPaddleTravel(1.0/120) }  // half a second
        XCTAssertLessThan(abs(scene.endlessIIPaddleGripSpeed),
                          EndlessIIBallSpin.gripThreshold)
    }

    /// A flick the other way is a new flick, not a continuation - so the ball curves the way
    /// the paddle is going now, which is the whole promise of the power-up.
    func testAFlickTheOtherWayIsTakenImmediately() {
        let scene = moving()
        scene.endlessIIPaddleLastX = 0
        scene.paddle.position.x = 10
        scene.tickEndlessIIPaddleTravel(1.0/120)
        XCTAssertGreaterThan(scene.endlessIIPaddleGripSpeed, 0)

        scene.paddle.position.x = 9
        scene.tickEndlessIIPaddleTravel(1.0/120)
        XCTAssertLessThan(scene.endlessIIPaddleGripSpeed, 0,
                          "the paddle is going the other way")
    }
}


/// The laser and sticky art that fits each shape.
///
/// James, round 213: "the paddles also come with their own lasers and sticky paddle graphics
/// to fit the new shapes... the bottom of each paddle shape should line up with the existing
/// paddle. This is true for the laser and stick paddle textures too."
final class ShapedPaddleDressingTests: XCTestCase {

    /// Every shape that has a paddle picture has the two overlays to go with it - a shaped
    /// paddle firing lasers must not wear a flat gun on a domed face.
    func testEveryDrawnShapeHasItsLaserAndStickyArt() {
        let scene = GameScene()
        for surface in PaddleBounce.Surface.allCases {
            guard let suffix = scene.endlessIIPaddleShapeSuffix(surface) else { continue }
            XCTAssertNotNil(UIImage(named: "regularPaddle\(suffix)"), "paddle \(surface)")
            XCTAssertNotNil(UIImage(named: "regularLasers\(suffix)"), "lasers \(surface)")
            XCTAssertNotNil(UIImage(named: "regularSticky\(suffix)"), "sticky \(surface)")
        }
    }

    /// The retired face is the one with no art, and it must stay that way rather than falling
    /// back to a picture that promises a shape it does not give.
    func testTheRetiredFaceHasNoDressingEither() {
        XCTAssertNil(GameScene().endlessIIPaddleShapeSuffix(.jagged))
    }

    /// **The bottom needs no arithmetic**, and this is the fact that makes that true: both
    /// overlays are anchored at their own underside in the scene file, so whatever height they
    /// are given they grow upward from the line they sit on. If somebody ever re-centres them
    /// the shapes will start floating, and this is what says so.
    func testTheOverlaysAreAnchoredAtTheirUnderside() {
        let scene = GameScene(fileNamed: "GameScene")
        let laser = scene?.childNode(withName: "paddleLaser") as? SKSpriteNode
        let sticky = scene?.childNode(withName: "paddleSticky") as? SKSpriteNode
        XCTAssertEqual(laser?.anchorPoint.y, 0, "the laser art hangs from its own bottom")
        XCTAssertEqual(sticky?.anchorPoint.y, 0, "and so does the sticky face")
    }
}

/// What the Paddle Halo does in a single frame.
///
/// James, round 215: "paddle halo causes game to become stuttery."
///
/// The glow destroyed every brick it touched on the same frame. That is one or two while it
/// erodes a field it already overlaps, and eleven at once the moment a whole row descends into
/// it - each running its role's reaction, its removal action, its scoring and its counters,
/// with an Exploding brick in the burst taking its neighbours too. The same one-frame pile-up
/// that made Retreat stutter when it cleared two rows.
final class PaddleHaloBiteTests: XCTestCase {

    /// A whole row arriving inside the glow is eaten over several frames, not in one.
    func testARowArrivingInTheGlowIsNotEatenInOneFrame() {
        let row = (0..<11).map { _ in CGFloat(-190) }
        XCTAssertEqual(EndlessIIPaddleEffects.haloBites(heights: row).count,
                       EndlessIIPaddleEffects.haloBitesPerFrame,
                       "the whole row went on one frame")
    }

    /// And it does keep eating - a cap that stopped it working would be worse than the stutter.
    func testItTakesABiteWheneverThereIsAnythingToBite() {
        for count in 1...11 {
            let bites = EndlessIIPaddleEffects.haloBites(heights: Array(repeating: 0, count: count))
            XCTAssertEqual(bites.count, min(count, EndlessIIPaddleEffects.haloBitesPerFrame),
                           "the glow went hungry with \(count) bricks in reach")
            XCTAssertEqual(Set(bites).count, bites.count, "it bit the same brick twice")
        }
    }

    /// Nothing in reach, nothing eaten.
    func testAnEmptyGlowEatsNothing() {
        XCTAssertTrue(EndlessIIPaddleEffects.haloBites(heights: []).isEmpty)
    }

    /// It erodes upward from the paddle rather than in scene-graph order.
    func testItEatsTheLowestBricksFirst() {
        let heights: [CGFloat] = [40, -190, 120, -170, 0]
        XCTAssertEqual(EndlessIIPaddleEffects.haloBites(heights: heights, limit: 3), [1, 3, 4],
                       "the glow ate downward, or in whatever order the field arrived in")
    }
}

/// A paused run comes back wearing the face it was paused in.
///
/// It used to come back domed, whatever it had been: which shape was running was the one part
/// of the paddle batch the save did not carry, on the grounds that the format is shared with a
/// shipped version and a fifteen-second power-up did not justify a migration. It does not need
/// one - every clock already saves a magnitude, and this clock has never had a use for it.
final class ShapedPaddleSurvivesAResumeTests: XCTestCase {

    /// The codes are written down, so they have to be distinct and they have to round-trip.
    func testEveryShapeIsWrittenDownUnderItsOwnNumber() {
        let codes = PaddleBounce.Surface.allCases.map(\.savedCode)
        XCTAssertEqual(Set(codes).count, codes.count, "two shapes share a saved code")
        XCTAssertFalse(codes.contains(0), "zero means *no shape recorded* and cannot be a shape")
        for surface in PaddleBounce.Surface.allCases {
            XCTAssertEqual(PaddleBounce.Surface(savedCode: surface.savedCode), surface,
                           "\(surface) did not come back as itself")
        }
    }

    /// A file can say anything. A number that is not a shape is not one.
    func testANumberThatIsNoShapeIsRefused() {
        XCTAssertNil(PaddleBounce.Surface(savedCode: 0))
        XCTAssertNil(PaddleBounce.Surface(savedCode: PaddleBounce.Surface.highestSavedCode + 1))
        XCTAssertNil(PaddleBounce.Surface(savedCode: -3))
    }

    /// Every shape survives being saved and put back.
    ///
    /// Two scenes for the whole loop rather than two per shape. A `GameScene` is not a cheap
    /// object to build and twelve of them in one test case was enough to have the host
    /// relaunch mid-test on a busy machine - a failure with no assertion behind it, which is
    /// the most confusing kind to be handed.
    func testEveryShapeComesBackFromTheSave() {
        let saved = GameScene()
        saved.gameMode = .endlessII
        let resumed = GameScene()
        resumed.gameMode = .endlessII

        for surface in PaddleBounce.Surface.allCases {
            saved.endlessIIPaddleSurfaceClock.reset()
            saved.endlessIIPaddleSurface = nil
            saved.endlessIICollectPaddleSurface(surface)
            guard let entry = saved.endlessIIPaddleClockSaveEntries()
                .first(where: { $0.key == "endlessIIPaddleSurface" }) else {
                    return XCTFail("a running shape was not in the save at all")
            }

            resumed.endlessIIPaddleSurfaceClock.reset()
            resumed.endlessIIPaddleSurface = nil
            resumed.endlessIIRestorePaddleClock(key: entry.key, remaining: entry.remaining,
                                                total: entry.total, magnitude: entry.magnitude)
            XCTAssertEqual(resumed.endlessIIPaddleSurface, surface,
                           "a run paused wearing \(surface) resumed wearing something else")
            XCTAssertTrue(resumed.endlessIIPaddleSurfaceClock.isRunning,
                          "the shape came back but its turns did not")
        }
    }

    /// A save from a build that recorded no shape still resumes, wearing the first of them.
    func testASaveWithNoShapeRecordedComesBackDomed() {
        let resumed = GameScene()
        resumed.gameMode = .endlessII
        resumed.endlessIIRestorePaddleClock(key: "endlessIIPaddleSurface", remaining: 5,
                                            total: 5, magnitude: 0)
        XCTAssertEqual(resumed.endlessIIPaddleSurface, .convex,
                       "an older save left the paddle with a running clock and no face")
    }
}

/// The second a spent turn-based power-up gets before it goes.
///
/// James, round 231: "on the last bounce of a paddle hit based power up, wait a second to
/// remove the power up and HUD icon. Especially the shaped paddles power ups. They look weird
/// when they immediately change to a normal paddle when the ball bounces."
final class SpentPowerUpsLingerTests: XCTestCase {

    /// The last turn does not end it, it starts the goodbye.
    func testTheLastTurnLeavesASecondOnTheClock() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)

        XCTAssertTrue(clock.isRunning, "the shape snapped back in the frame the ball left it")
        XCTAssertTrue(clock.lingering)
        XCTAssertEqual(clock.goodbye, EndlessIIClock.lingerSeconds, accuracy: 0.001,
                       "the goodbye has its own field since round 263 - it used to be written "
                       + "over `remaining`, which refilled the ring and swept it round again")
        XCTAssertEqual(clock.remaining, 0, accuracy: 0.001,
                       "and the turns are all genuinely spent")
    }

    /// And it is a second of ordinary time, spent the way every other clock spends one.
    func testTheGoodbyeRunsOutOnTime() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)

        clock.run(down: EndlessIIClock.lingerSeconds/2)
        XCTAssertTrue(clock.isRunning, "half a second is not a second")

        clock.run(down: EndlessIIClock.lingerSeconds)
        XCTAssertFalse(clock.isRunning, "the goodbye never ended")
        XCTAssertFalse(clock.lingering)
    }

    /// A goodbye has to be asked for, and Descent does not ask.
    ///
    /// It counts rows rather than paddle hits, and a Descent running a second past its last
    /// row would not be worth exactly its rows any more - which is a promise §5.4 makes and a
    /// test holds it to.
    func testAClockThatAsksForNoGoodbyeSimplyEnds() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn()
        XCTAssertFalse(clock.isRunning, "it lingered without being asked to")
        XCTAssertFalse(clock.lingering)
    }

    /// A turn left is a turn left: the goodbye only starts when the bouncing has run out.
    func testAClockWithTurnsLeftDoesNotLinger() {
        var clock = EndlessIIClock()
        clock.collect(turns: 5)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)

        XCTAssertFalse(clock.lingering)
        XCTAssertEqual(clock.remaining, 4)
        XCTAssertTrue(clock.countsTurns)
    }

    /// **Its ring keeps its marks for that second, and shows every one of them spent.**
    ///
    /// It used to stop being segmented, because the goodbye was expressed by rewriting the
    /// clock as a one-second timer - which took the marks off *and* refilled the arc so it
    /// swept round a second time. James, round 259: "the power-up HUD progress bar is
    /// resetting and quickly animating down at the end of the last paddle hit segment. This is
    /// unnecessary." The delay was the point; the animation was a side effect of how it was
    /// written down.
    func testTheRingShowsTheGoodbyeAsSpentRatherThanRefilling() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)
        XCTAssertTrue(clock.countsTurns, "the marks stay")
        XCTAssertEqual(clock.total, 1, accuracy: 0.001, "and so does how many there were")
        XCTAssertEqual(clock.fraction, 0, accuracy: 0.001,
                       "spent, rather than full and sweeping round again")
    }

    /// The scene runs the goodbye down, or the power-up would never end at all.
    ///
    /// Turn-based clocks are spent by bouncing and by nothing else, so a clock that has
    /// swapped its turns for a second needs something to take that second off it.
    func testTheSceneRunsTheGoodbyeDown() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.endlessIICollectInertPaddle()
        for _ in 0..<Int(GameScene.endlessIIPaddlePowerUpTurns) { scene.endlessIISpendPaddleTurns() }
        XCTAssertTrue(scene.endlessIIInertPaddleClock.lingering, "it should be saying goodbye")

        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning,
                       "nothing was taking the second off it")
    }

    /// Every turn-based clock is in the list that runs the goodbye down.
    ///
    /// A clock left out would keep its shape for ever, which is the one failure this change
    /// could cause and the one nobody would think to look for.
    func testEveryTurnClockIsInTheList() {
        XCTAssertEqual(GameScene.endlessIITurnClockPaths.count,
                       GameScene.endlessIIPaddleTurnClockKeys.count,
                       "a turn-based clock is missing from one of the two lists")
    }
}

/// The ring shows James's shaped-paddle artwork, not the drawn profile.
///
/// Round 231: "shaped paddles aren't using the shaped paddle power up HUD icons yet." The art
/// arrived in round 213 and the ring went on drawing the profile `PaddleBounce.shaped` traces,
/// which is a fair picture of the old formula and no picture at all of what the paddle wears.
final class ShapedPaddleHudIconTests: XCTestCase {

    private func shaped(_ surface: PaddleBounce.Surface) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.endlessIICollectPaddleSurface(surface)
        return scene
    }

    /// Each shape names its own icon, and every one of those names is a real asset.
    ///
    /// The name is the whole risk here: `hud(_:_:)` falls back to the drawn badge, so a typo
    /// looks exactly like a shape whose art was never delivered.
    func testEveryShapeNamesArtThatExists() {
        for surface in PaddleBounce.Surface.allCases where surface != .jagged {
            let scene = shaped(surface)
            let name = scene.endlessIIPaddleShapeIconName
            XCTAssertNotNil(UIImage(named: name),
                            "\(surface) asks for \"\(name)\", which is not in the catalogue")
            XCTAssertNotNil(UIImage(named: name + "Disabled"),
                            "\(surface)'s disabled twin is missing")
        }
    }

    /// The five name five different pictures.
    func testTheShapesDoNotShareAnIcon() {
        let names = PaddleBounce.Surface.allCases
            .filter { $0 != .jagged }
            .map { shaped($0).endlessIIPaddleShapeIconName }
        XCTAssertEqual(Set(names).count, names.count, "two shapes wear the same badge")
    }

    /// And the ring asks for it, rather than for the drawn profile.
    func testTheRingCarriesTheArtwork() {
        let scene = shaped(.concave)
        let entry = scene.endlessIIPaddleRingEntries()
            .first { $0.id == "endlessIIPaddleSurface" }
        XCTAssertNotNil(entry, "a running shape is not in the ring at all")

        guard let art = UIImage(named: "ConcavePaddleIcon") else { return XCTFail("no art") }
        XCTAssertEqual(entry?.texture.size().width ?? 0, art.size.width, accuracy: 1,
                       "the ring is still drawing the profile rather than the picture")
    }
}

/// Where a held ball rests once the paddle has a shape.
///
/// James, round 232: "with an aimed sticky and a shaped paddle, the ball was sliding about on
/// the paddle. The ball should remain fixed on the paddle."
///
/// The resting height was worked out once at setup, from the plain paddle. A shaped paddle is
/// taller and sits higher, so the ball was placed inside the new silhouette - and a body the
/// engine finds inside another body is one it shoves out, every frame, in whatever direction
/// the overlap suggests. The sliding was not the hold failing; it was the hold putting the
/// ball somewhere the physics refused to leave it.
final class HeldBallRestsOnTheShapeTests: XCTestCase {

    private func shapedScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.paddleHeight = 12
        scene.paddleWidth = 120
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.paddle)
        scene.addChild(scene.ball)
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ballStartingPositionY = scene.paddle.position.y + 12/2 + 10/2 + 1
        return scene
    }

    /// A shaped paddle lifts the ball's resting height with it.
    func testTheRestingHeightFollowsAShape() {
        let scene = shapedScene()
        let flat = scene.ballStartingPositionY

        scene.endlessIICollectPaddleSurface(.convex)
        scene.refreshEndlessIIPaddleShapeArt()

        XCTAssertGreaterThan(scene.ballStartingPositionY, flat,
                             "a convex paddle is taller, so the ball rests higher")
        XCTAssertEqual(scene.ballStartingPositionY,
                       scene.paddle.position.y + scene.paddle.size.height/2
                           + scene.ball.size.height/2 + 1,
                       accuracy: 0.001,
                       "the ball should sit on the paddle it is actually standing on")
    }

    /// And it is never inside the paddle, which is the whole complaint.
    func testTheBallIsNeverInsideThePaddle() {
        for surface in PaddleBounce.Surface.allCases where surface != .jagged {
            let scene = shapedScene()
            scene.endlessIICollectPaddleSurface(surface)
            scene.refreshEndlessIIPaddleShapeArt()

            let paddleTop = scene.paddle.position.y + scene.paddle.size.height/2
            let ballBottom = scene.ballStartingPositionY - scene.ball.size.height/2
            XCTAssertGreaterThanOrEqual(ballBottom, paddleTop,
                                        "\(surface) leaves the ball inside its own silhouette")
        }
    }

    /// The height comes back when the shape ends.
    func testItComesBackWhenTheShapeEnds() {
        let scene = shapedScene()
        let flat = scene.ballStartingPositionY

        scene.endlessIICollectPaddleSurface(.convex)
        scene.refreshEndlessIIPaddleShapeArt()
        scene.endlessIIPaddleSurfaceClock.reset()
        scene.endlessIIPaddleSurface = nil
        scene.refreshEndlessIIPaddleShapeArt()

        XCTAssertEqual(scene.ballStartingPositionY, flat, accuracy: 0.001,
                       "the plain paddle got the shaped paddle's resting height")
    }
}

/// Aimed Sticky as a variant of Sticky, rather than a rival to it (round 260).
///
/// James: "it should be another variant of the sticky power-up, so it should apply the sticky
/// paddle texture. If the sticky power-up is caught during aimed sticky, the aimed sticky
/// power-up should be maintained with the number of paddle hits reset. If aimed sticky
/// power-up is caught during sticky, it should become aimed sticky."
final class AimedStickyIsAVariantOfStickyTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.addChild(scene.paddleSticky)
        scene.paddleSticky.isHidden = true
        return scene
    }

    func testCollectingItPutsTheStickyFaceOnThePaddle() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        XCTAssertFalse(scene.paddleSticky.isHidden,
                       "it is a sticky paddle, and a sticky paddle looks like one")
    }

    /// Aimed Sticky over a plain Sticky *becomes* the aim, rather than the two running at once.
    func testItTakesOverFromAPlainSticky() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 5

        scene.endlessIICollectAimedSticky()

        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertEqual(scene.stickyPaddleCatches, 0,
                       "one paddle, one rule about where the ball goes - and the aimed one is "
                       + "the higher setting, so the plain one stands down")
        XCTAssertFalse(scene.paddleSticky.isHidden)
    }

    /// And a plain Sticky over the aim refills the aim rather than downgrading it.
    func testAPlainStickyCollectedOverItRefillsTheAim() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        for _ in 0..<3 { scene.endlessIISpendPaddleTurns() }
        let spent = scene.endlessIIAimedStickyClock.remaining

        XCTAssertTrue(scene.endlessIIStickyRefillsTheAim(), "the aim takes the collection")
        XCTAssertGreaterThan(scene.endlessIIAimedStickyClock.remaining, spent,
                             "the hits reset, which is what a refill is")
        XCTAssertEqual(scene.stickyPaddleCatches, 0,
                       "and no plain Sticky starts underneath it")
    }

    /// With no aim running, a plain Sticky is a plain Sticky.
    func testAPlainStickyIsUntouchedWhenNoAimIsRunning() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIStickyRefillsTheAim())
    }

    /// A plain Sticky expiring underneath an aim must not take the face off with it.
    func testAStickyRunningOutUnderTheAimLeavesTheFaceOn() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        scene.stickyPaddleCatches = 1
        scene.spendStickyPaddleCatch()
        // Spent down to nothing, which is the path that decides whether the face stays
        XCTAssertFalse(scene.paddleSticky.isHidden,
                       "the aim is still running and still wants the face")
    }

    /// The aim's own last turn is what takes it off.
    func testTheFaceComesOffWithTheLastAimedTurn() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        for _ in 0..<Int(GameScene.endlessIIPaddlePowerUpTurns) + 1 {
            scene.endlessIISpendPaddleTurns()
        }
        scene.endlessIIAimedStickyClock.reset()
        // The clock *lingers* after its last turn so the ring can be seen ending, which is
        // why the face is taken off in the tick rather than at the spend - there is no single
        // moment to hang it on. Reset here stands for the linger running out

        scene.refreshEndlessIIStickyFace()
        XCTAssertTrue(scene.paddleSticky.isHidden)
    }
}

/// The grip: what the paddle wears while Ball Spin runs (rounds 261 and 262).
///
/// James, round 261: "it replaces the sticky and aimed sticky power-up and textures when
/// caught." Round 262, correcting which power-up it belongs to: "grip is for the ball spin,
/// not ball steering" - which is what §5.4 had said all along.
final class EndlessIIGripTests: XCTestCase {

    private func mayhem(theme: Int = 0) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.paddleSetting = theme
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.addChild(scene.paddleSticky)
        scene.addChild(scene.paddleRetroStickyTexture)
        scene.paddleSticky.isHidden = true
        return scene
    }

    /// Every theme has a grip drawn for it, plain and in all five shapes.
    ///
    /// Read off the theme list rather than written out, so a thirteenth theme fails here rather
    /// than silently borrowing the regular one's grip.
    func testEveryThemeHasAGripInEveryShape() {
        for (index, theme) in GameScene.paddleThemePrefixes.enumerated() {
            let scene = mayhem(theme: index)
            for shape in ["", "Convex", "Concave", "Wave", "WedgeLeft", "WedgeRight"] {
                XCTAssertEqual(scene.endlessIIThemedShapeArt("Grip", shape), "\(theme)Grip\(shape)",
                               "\(theme) is borrowing somebody else's grip for \(shape)")
            }
        }
    }

    func testCollectingBallSpinPutsTheGripOn() {
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        XCTAssertTrue(scene.endlessIIWearsGrip)
        XCTAssertFalse(scene.paddleSticky.isHidden)
        XCTAssertEqual(scene.endlessIIPaddleTopKind, "Grip")
    }

    /// "It replaces the sticky and aimed sticky power-up... when caught" - the power-ups, not
    /// only their pictures.
    func testItReplacesStickyAndAimedSticky() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 3
        scene.endlessIICollectAimedSticky()

        scene.endlessIICollectBallSpin()

        XCTAssertEqual(scene.stickyPaddleCatches, 0)
        XCTAssertFalse(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertEqual(scene.endlessIIPaddleTopKind, "Grip")
    }

    /// Retro's grip goes on the shared overlay, not on retro's own sticky node.
    ///
    /// James: "for retro, its regular sticky texture is quite different from the other paddles,
    /// but its grip texture is in the same style as the other paddles."
    func testRetroWearsItsGripOnTheSharedOverlay() {
        guard let retro = GameScene.paddleThemePrefixes.firstIndex(of: "retro") else {
            return XCTFail("retro has left the theme list")
        }
        let scene = mayhem(theme: retro)
        scene.paddleRetroStickyTexture.isHidden = false

        scene.endlessIICollectBallSpin()

        XCTAssertFalse(scene.paddleSticky.isHidden, "the grip is in everybody else's style")
        XCTAssertTrue(scene.paddleRetroStickyTexture.isHidden,
                      "and retro's own sticky picture stands down while it is worn")
    }

    /// The face comes off when the steering stops.
    func testTheGripComesOffWhenTheSteeringEnds() {
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        scene.endlessIIBallSpinClock.reset()

        scene.refreshEndlessIIStickyFace()
        XCTAssertTrue(scene.paddleSticky.isHidden)
    }

    /// And hands the picture back if a Sticky was collected underneath it.
    func testAStickyCollectedUnderTheGripGetsThePictureBack() {
        let scene = mayhem()
        scene.endlessIICollectBallSpin()
        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 3

        scene.endlessIIBallSpinClock.reset()
        scene.refreshEndlessIIStickyFace()

        XCTAssertFalse(scene.paddleSticky.isHidden, "the Sticky still wants a face")
        XCTAssertEqual(scene.endlessIIPaddleTopKind, "Sticky")
        XCTAssertEqual(scene.paddleSticky.texture, scene.stickyPaddleTexture)
    }
}

/// Play-test round 259's four, in the order James gave them.
final class PlayTestRound259Tests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSize = 24
        scene.paddleHeight = 24
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 150, height: 24)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
        scene.addChild(scene.paddleLaser)
        scene.addChild(scene.paddleSticky)
        scene.paddleLaser.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.paddleSticky.anchorPoint = CGPoint(x: 0.5, y: 0)
        return scene
    }

    // MARK: (a) The landing marker is too small

    /// James: "make the landing marker bigger."
    func testTheLandingMarkerIsBiggerThanItWas() {
        let scene = mayhem()
        let triangle = scene.endlessIILandingMarkerSize.width
            * GameScene.endlessIILandingTriangleShare

        XCTAssertEqual(triangle,
                       scene.ballSize*0.7*1.1*GameScene.endlessIILandingMarkerScale,
                       accuracy: 0.001,
                       "the *triangle* is what grows - the picture around it is mostly glow")
        XCTAssertGreaterThan(GameScene.endlessIILandingMarkerScale, 1)
    }

    /// And the mark still lands where the ball will, which is the thing size must not move.
    func testTheBiggerMarkerStillPointsAtTheSameSpot() {
        let scene = mayhem()
        let point = CGPoint(x: 40, y: -260)
        let centre = scene.endlessIILandingMarkerCentre(over: point)
        let size = scene.endlessIILandingMarkerSize

        XCTAssertEqual(centre.x, point.x, accuracy: 0.001)
        XCTAssertEqual(centre.y - GameScene.endlessIILandingTriangleDrop*size.height
                           + scene.ballSize*0.7*0.1,
                       point.y, accuracy: 0.001,
                       "the triangle's own centre is still on the point, at any size")
    }

    // MARK: (b) The overlays do not line up

    /// James: "the bottom of the graphic aligns with the bottom of the paddle graphic... some
    /// of the graphics are currently not aligned properly."
    ///
    /// A shaped paddle is taller than the plain one and its node rises by half the growth so
    /// its own underside stays put (round 213). The overlays were placed at the *plain*
    /// paddle's underside, so they sat the height of that lift too high - a quarter of the
    /// paddle's height under a dome, a tenth under a wave, nothing at all on the plain paddle,
    /// which is exactly "some of them".
    func testTheOverlaysSitOnThePaddlesOwnUnderside() {
        let scene = mayhem()
        let underside = scene.paddle.position.y - scene.paddle.size.height/2

        for surface in [PaddleBounce.Surface.convex, .concave, .wavy, .wedgeLeft, .wedgeRight] {
            scene.endlessIICollectPaddleSurface(surface)
            scene.refreshEndlessIIPaddleShapeArt()

            XCTAssertGreaterThan(scene.paddle.size.height, 24,
                                 "\(surface) should have grown the paddle")
            XCTAssertEqual(scene.paddle.position.y - scene.paddle.size.height/2, underside,
                           accuracy: 0.001,
                           "\(surface) moved the paddle's underside, which nothing may do")
            XCTAssertEqual(scene.paddleSticky.position.y, underside, accuracy: 0.001,
                           "\(surface)'s sticky pad is off the paddle's bottom line")
            XCTAssertEqual(scene.paddleLaser.position.y, underside, accuracy: 0.001,
                           "\(surface)'s lasers are off the paddle's bottom line")
        }
    }

    /// And a shape collected while the paddle is standing still places them straight away.
    func testTheOverlaysArePlacedWithoutWaitingForThePaddleToMove() {
        let scene = mayhem()
        scene.paddleSticky.position.y = 9999

        scene.endlessIICollectPaddleSurface(.convex)
        scene.refreshEndlessIIPaddleShapeArt()

        XCTAssertEqual(scene.paddleSticky.position.y,
                       scene.paddle.position.y - scene.paddle.size.height/2, accuracy: 0.001)
    }

    // MARK: (c) Two segments a hit

    /// James: "each hit on a shaped paddle is taking off 2 segments from the power-up HUD
    /// icon."
    ///
    /// `paddleHit` has one call site and spends one turn, so two turns is two calls - and
    /// `didBegin` is reported per contacting *fixture* pair. A dish or a wave traced from its
    /// picture is several convex pieces, so a ball landing where two meet begins contact with
    /// both. One landing is one turn however many times the engine says so.
    func testOneLandingSpendsOneTurnHoweverManyContactsItIsReportedAs() {
        let scene = mayhem()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.position = CGPoint(x: 0, y: -260)
        scene.ballIsOnPaddle = false
        // A run *starts* with the ball on the paddle, and `paddleHit` returns straight away
        // for a ball it is already holding - so a landing has to be a landing
        scene.endlessIICollectPaddleSurface(.concave)
        let turns = scene.endlessIIPaddleSurfaceClock.remaining

        scene.paddleHit(scene.ball)
        scene.paddleHit(scene.ball)
        scene.paddleHit(scene.ball)

        XCTAssertEqual(scene.endlessIIPaddleSurfaceClock.remaining, turns - 1, accuracy: 0.001,
                       "three contacts in one frame is one landing")
    }

    /// The next frame is a new landing, or the power-up would never end.
    func testTheNextFrameCountsAgain() {
        let scene = mayhem()
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.position = CGPoint(x: 0, y: -260)
        scene.ballIsOnPaddle = false
        scene.endlessIICollectPaddleSurface(.concave)
        let turns = scene.endlessIIPaddleSurfaceClock.remaining

        scene.paddleHit(scene.ball)
        scene.frameNumber += 1
        scene.paddleHit(scene.ball)

        XCTAssertEqual(scene.endlessIIPaddleSurfaceClock.remaining, turns - 2, accuracy: 0.001)
    }

    // MARK: (d) The ring animating itself down

    /// James: "the power-up HUD progress bar is resetting and quickly animating down at the
    /// end of the last paddle hit segment. This is unnecessary. Delay the change back to a
    /// normal paddle, but there's no need for this additional animation."
    func testTheGoodbyeSecondShowsSpentRatherThanRefilling() {
        var clock = EndlessIIClock()
        clock.collect(turns: 5)
        for _ in 0..<5 { clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds) }

        XCTAssertTrue(clock.isRunning, "the delay is the point and it stays")
        XCTAssertTrue(clock.lingering)
        XCTAssertEqual(clock.fraction, 0, accuracy: 0.001,
                       "an empty ring, not a full one sweeping round a second time")
        XCTAssertTrue(clock.countsTurns,
                      "and it keeps its segment marks, all of them spent")
        XCTAssertEqual(clock.total, 5, accuracy: 0.001, "so the ring still shows five")
    }

    /// The goodbye runs out on time and takes the power-up with it.
    func testTheGoodbyeEndsTheClock() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)
        XCTAssertTrue(clock.isRunning)

        clock.run(down: EndlessIIClock.lingerSeconds + 0.01)
        XCTAssertFalse(clock.isRunning)
    }

    /// And a hit during the goodbye spends nothing, because there is nothing left to spend.
    func testAHitDuringTheGoodbyeTakesNothingOffIt() {
        var clock = EndlessIIClock()
        clock.collect(turns: 1)
        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)
        let left = clock.goodbye

        clock.spendTurn(thenLingerFor: EndlessIIClock.lingerSeconds)
        XCTAssertEqual(clock.goodbye, left, accuracy: 0.001,
                       "a spend used to take a whole second off the farewell")
    }
}
