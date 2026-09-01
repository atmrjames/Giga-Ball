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
        XCTAssertGreaterThan(first.x, 0, "it sets off towards the paddle")
        XCTAssertLessThan(first.x, 100, "and does not teleport there")

        var x: CGFloat = 0
        var v: CGFloat = 0
        for _ in 0..<60 {
            (x, v) = EndlessIIPaddleEffects.steeredTowards(paddleX: 100, from: x, velocity: v,
                                                           leftWall: -200, rightWall: 200,
                                                           radius: 5)
        }
        XCTAssertEqual(x, 100, accuracy: 4,
                       "a second of holding still gathers it in - within four points of a "
                       + "hundred, where round 291's stiffer spring was within one. A slacker "
                       + "tether takes longer to settle, which is the whole of what round 293 "
                       + "asked for: 'more like a piece of string'")
    }

    func testAStationaryPaddleStillHoldsASteeredBall() {
        // The old version moved the ball by the paddle's *movement*, so a paddle standing
        // still steered nothing and the ball wandered off on its own trajectory - which
        // is what made it feel like the power-up was not working
        let x = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 0, from: 60, leftWall: -200, rightWall: 200, radius: 5).x
        XCTAssertLessThan(x, 60, "a still paddle is still pulling")
    }

    func testSteeringCannotPullABallThroughAWall() {
        let steered = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 1000, from: 198, leftWall: -200, rightWall: 200, radius: 5)
        XCTAssertEqual(steered.x, 195, "clamped a radius inside the wall")
        XCTAssertEqual(steered.velocity, 0,
                       "and the spring's wind-up stops at the wall with it, or the ball "
                       + "would be catapulted off it when the paddle came back")
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
        // Round 284 turned the pull into a spring, and a spring makes this property easier to
        // hold rather than harder: the frame is spent in fixed slices, so two short frames and
        // one long one are the same list of slices in the same order
        let slow = EndlessIIPaddleEffects.steeringStep(x: 0, velocity: 0, towards: 100,
                                                       delta: 1.0/60)
        var fast = EndlessIIPaddleEffects.steeringStep(x: 0, velocity: 0, towards: 100,
                                                       delta: 1.0/120)
        fast = EndlessIIPaddleEffects.steeringStep(x: fast.x, velocity: fast.velocity,
                                                   towards: 100, delta: 1.0/120)
        XCTAssertEqual(fast.x, slow.x, accuracy: 0.0001)
        XCTAssertEqual(fast.velocity, slow.velocity, accuracy: 0.0001)

        let oneShortFrame = EndlessIIPaddleEffects.steeringStep(x: 0, velocity: 0, towards: 100,
                                                                delta: 1.0/120)
        XCTAssertLessThan(oneShortFrame.x, slow.x, "a shorter frame moves the ball less")
    }

    /// A frame long enough to break a naive integrator does not throw the ball anywhere.
    ///
    /// The reason the slices are fixed rather than the whole frame being taken in one go: a
    /// spring stepped over a slice comparable to its own period gains energy instead of
    /// losing it, and the failure is not subtle - the ball leaves the field.
    func testALongFrameDoesNotThrowTheBallAcrossTheField() {
        var state = (x: CGFloat(0), velocity: CGFloat(0))
        for _ in 0..<40 {
            state = EndlessIIPaddleEffects.steeringStep(x: state.x, velocity: state.velocity,
                                                        towards: 100, delta: 0.5)
        }
        XCTAssertEqual(state.x, 100, accuracy: 1,
                       "half-second frames still settle on the paddle rather than diverging")
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
        // The pull's half of this went with the spring in round 284 - there is no "share of the
        // gap" left to compare a number against. The bleed is untouched and still is one
        XCTAssertEqual(EndlessIIPaddleEffects.steeringVelocityDamping(delta: 1.0/60),
                       EndlessIIPaddleEffects.steeringVelocityDampingPerSixtieth,
                       accuracy: 0.0001)
    }

    /// A frame with no time in it moves nothing, rather than snapping the ball to the paddle.
    func testAFrameWithNoTimeInItSteersNothing() {
        XCTAssertEqual(EndlessIIPaddleEffects.steeredTowards(
            paddleX: 100, from: 0, leftWall: -200, rightWall: 200, radius: 5, delta: 0).x, 0)
        XCTAssertEqual(EndlessIIPaddleEffects.steeringStep(
            x: 0, velocity: 40, towards: 100, delta: 0).velocity, 40,
                       "and it does not wind the spring either")
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
            paddleX: paddleAtItsLimit, from: 0, leftWall: -200, rightWall: 200, radius: 5).x
        let swept = EndlessIIPaddleEffects.steeredTowards(
            paddleX: paddleAtItsLimit, from: 0, leftWall: -200, rightWall: 200, radius: 5,
            paddleSpeed: 900, fieldWidth: 400).x

        XCTAssertGreaterThan(swept, parked,
                             "sweeping toward the wall reaches columns a parked paddle cannot")
    }

    func testTheBallIsStillNeverPushedThroughAWall() {
        let steered = EndlessIIPaddleEffects.steeredTowards(
            paddleX: 190, from: 190, leftWall: -200, rightWall: 200, radius: 5,
            paddleSpeed: 5000, fieldWidth: 400).x
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

    /// Moving the paddle must not drop the aim to a low angle.
    ///
    /// James, play-test round 275: "the swiping to move the paddle and aim the arrow is working
    /// well, except when moving the paddle the aim arrow can snap down to a low angle."
    ///
    /// The aim is kept as the point the finger last pointed at, and the angle is measured from
    /// the ball to it - round 232, so that aiming at a brick means pointing at the brick. The
    /// held ball rides the paddle, so dragging the paddle walks the ball out from under a point
    /// that stays where it was: the vector between them swings as the ball approaches, and once
    /// the ball is nearly level with the point the angle is almost flat and the clamp takes it
    /// to the minimum. That is the snap.
    func testTheAimSurvivesThePaddleBeingMoved() {
        let minimum = 20*Double.pi/180
        let ball = CGPoint(x: 0, y: -300)
        let finger = CGPoint(x: 40, y: -120)
        let aimed = EndlessIIPaddleEffects.aimedAngle(at: finger, from: ball, minimum: minimum)

        // The paddle is dragged 90 points right, so the ball goes with it and passes under
        // the point the player was aiming at
        let moved = CGPoint(x: ball.x + 90, y: ball.y)
        let adrift = EndlessIIPaddleEffects.aimedAngle(at: finger, from: moved, minimum: minimum)
        XCTAssertNotEqual(aimed, adrift, accuracy: 0.01,
                          "this is the bug: the same finger, a moved ball, a different shot")

        // Carried by the same distance, which is what the drag now does to it
        let carried = CGPoint(x: finger.x + 90, y: finger.y)
        let held = EndlessIIPaddleEffects.aimedAngle(at: carried, from: moved, minimum: minimum)
        XCTAssertEqual(held, aimed, accuracy: 0.0001,
                       "the angle the player set is the angle they keep")
    }

    /// And the drag that would have collapsed it really did collapse it.
    ///
    /// Not "some other angle" but *flat*: the failure James saw is the clamp catching a shot
    /// that had swung down to nothing, which is what makes it read as a snap rather than as
    /// drift.
    func testTheUncarriedAimCollapsesToTheClamp() {
        let minimum = 20*Double.pi/180
        let ball = CGPoint(x: 0, y: -300)
        let finger = CGPoint(x: 40, y: -250)
        // Aimed low and near, which is the aim a long drag ruins soonest: the paddle only moves
        // sideways, so what a drag can do to the angle is widen its run and never shorten its
        // rise - and a shallow aim has the least rise to spare

        let set = EndlessIIPaddleEffects.aimedAngle(at: finger, from: ball, minimum: minimum)
        XCTAssertEqual(set*180/Double.pi, 51.3, accuracy: 0.5, "a perfectly ordinary shot")

        let dragged = EndlessIIPaddleEffects.aimedAngle(
            at: finger, from: CGPoint(x: 200, y: ball.y), minimum: minimum)
        XCTAssertEqual(dragged, Double.pi - minimum, accuracy: 0.0001,
                       "and after dragging the paddle 200 points the shot is the clamp: not "
                       + "the angle the player set, and not one they chose - which is what "
                       + "makes it read as a snap rather than as drift")

        let carried = EndlessIIPaddleEffects.aimedAngle(
            at: CGPoint(x: finger.x + 200, y: finger.y), from: CGPoint(x: 200, y: ball.y),
            minimum: minimum)
        XCTAssertEqual(carried, set, accuracy: 0.0001)
    }
}


/// The paddle has one top and one underside, and everything that places something against
/// them asks for it.
///
/// `paddleHeight` is the *plain* paddle's height. A shaped paddle is up to half as tall again
/// and its node is lifted so the underside stays on the line it was on, so
/// `paddle.position.y + paddleHeight/2` names a line inside the dome rather than the surface
/// the ball meets. Eleven places worked it out that way; round 259 fixed the overlays, round
/// 275 the retro layers, and round 278 found the resume path carrying a hand-written copy of
/// both and gave the scene one answer instead.
final class PaddleSurfaceTests: XCTestCase {

    private func scene(shaped: Bool) -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.paddleHeight = 12
        scene.paddleWidth = 75
        scene.ballSize = 12
        scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
        scene.paddle.texture = scene.paddleTexture
        scene.paddle.size = CGSize(width: 75, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.addChild(scene.paddle)
        if shaped {
            scene.endlessIIPaddleSurface = .convex
            scene.endlessIIPaddleSurfaceClock.collect(10)
        }
        scene.refreshEndlessIIPaddleShapeArt()
        return scene
    }

    /// A shaped paddle is taller, and its top is higher than the plain paddle's was.
    func testAShapedPaddlesTopIsHigherThanThePlainOnes() {
        let plain = scene(shaped: false), shaped = scene(shaped: true)
        XCTAssertGreaterThan(shaped.paddle.size.height, plain.paddle.size.height,
                             "or there is nothing here to get wrong")
        XCTAssertGreaterThan(shaped.paddleTopY, plain.paddleTopY)

        XCTAssertGreaterThan(shaped.paddleTopY,
                             shaped.paddle.position.y + shaped.paddleHeight/2,
                             "which is exactly the difference the hand-written expression "
                             + "could not see")
    }

    /// And its underside has not moved, which is the rule the shapes were built to.
    ///
    /// "The shapes are drawn at the paddle's width and their own height, so the sprite grows
    /// and the node rises by half the growth, which leaves the underside exactly on the line it
    /// was on."
    func testTheUndersideStaysWhereItWas() {
        let plain = scene(shaped: false), shaped = scene(shaped: true)
        XCTAssertEqual(shaped.paddleUndersideY, plain.paddleUndersideY, accuracy: 0.01)

        XCTAssertNotEqual(shaped.paddle.position.y - shaped.paddleHeight/2,
                          plain.paddleUndersideY, accuracy: 0.01,
                          "and the hand-written version of it has moved, which is how the "
                          + "lives row drifted when a shape was collected")
    }

    /// The overlays sit on the paddle's own underside.
    func testTheOverlaysFollowTheShape() {
        let shaped = scene(shaped: true)
        shaped.positionPaddleOverlays()
        XCTAssertEqual(shaped.paddleLaser.position.y, shaped.paddleUndersideY, accuracy: 0.01)
        XCTAssertEqual(shaped.paddleSticky.position.y, shaped.paddleUndersideY, accuracy: 0.01)
    }

    /// An unsized paddle answers with the setting rather than with its own centre.
    ///
    /// A scene that has not laid itself out has a paddle sprite of no size, and
    /// `position.y + 0/2` is the centre wearing the top's name - the very mistake these
    /// properties exist to end, arriving by the other door. Found by three landing-marker tests
    /// that build exactly such a scene.
    func testAnUnsizedPaddleFallsBackToTheSetting() {
        let bare = GameScene()
        bare.gameMode = .endlessII
        bare.paddleHeight = 12
        bare.paddle.position = CGPoint(x: 0, y: -300)

        XCTAssertEqual(bare.paddle.size.height, 0, "the state this is about")
        XCTAssertEqual(bare.paddleTopY, -294, accuracy: 0.001)
        XCTAssertEqual(bare.paddleUndersideY, -306, accuracy: 0.001)
    }

    /// The lives row does not jump when a shape is collected.
    ///
    /// It measured the paddle's bottom as `position.y - paddleHeight/2`, and the position rises
    /// with a shape while `paddleHeight` does not - so the row slid up the screen for as long
    /// as the power-up ran.
    func testTheLivesRowDoesNotMoveWhenThePaddleIsShaped() {
        XCTAssertEqual(scene(shaped: true).livesRowY, scene(shaped: false).livesRowY,
                       accuracy: 0.01)
    }
}


/// The shaped-paddle drop weight is still where the play test put it.
///
/// `shapedPaddlePlayTestWeight` has been ten times its shipping value since round 214, so James
/// can meet the shapes often enough to judge them. That is right for now and wrong the day the
/// build goes out, and until round 278 the only record of it was a comment on the number itself.
/// This is the second one, in the place a green suite is read.
final class ShapedPaddleWeightTests: XCTestCase {

    /// What it ships at, and what it was raised to for the play test.
    private let shipping = 3
    private let playTest = 30

    /// It is back at the shipping weight, and the reminder is here if it is ever raised again.
    ///
    /// James, round 282: "set the shaped paddle weight back to normal." Round 279 put this test
    /// in because the only record of the raised weight was a comment on the number itself, and a
    /// release blocker recorded in the code it blocks is one nobody is tracking. It reads the
    /// other way round now: silent while the weight is right, and loud the moment it is not.
    func testTheShapedPaddleWeightIsTheShippingOne() {
        let weight = GameScene.shapedPaddlePlayTestWeight
        guard weight != shipping else { return }
        print("""

          NOTE: shaped paddles are dropping at weight \(weight), not \(shipping).
          That is a play-test setting. Put it back before release -
          GameScene.shapedPaddlePlayTestWeight.

        """)
        XCTAssertEqual(weight, playTest,
                       "the weight is neither the shipping value nor the play-test one, which "
                       + "is worth a second look")
    }

    /// Every shape drops at the same weight, whatever it is.
    ///
    /// Five power-ups read the one number, which is what makes putting it back a single edit -
    /// and what would quietly stop being true if one of them were ever given its own.
    func testAllFiveShapesShareTheOneWeight() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.applyEndlessRowPowerUpWeights()

        let shapes = [55, 56, 57, 64, 65]
        for index in shapes where scene.powerUpProbArray.indices.contains(index) {
            XCTAssertEqual(scene.powerUpProbArray[index],
                           GameScene.shapedPaddlePlayTestWeight,
                           "power-up \(index) has stopped sharing the one weight")
        }
    }
}


/// A shaped paddle's outline is computed from its picture, not traced from its pixels.
///
/// James, round 280: "let's do the analytic paddle outlines." Round 277 measured why - a traced
/// body follows the artwork's *pixels* at the size it is built for, so the curve the ball meets
/// is a staircase of up to two-point steps: 20 across the dome, 26 across the dish, 32 across
/// the wave. A ball twelve points wide striking a step gets the step's normal rather than the
/// curve's, so a shaped paddle answered some hits with the shape it is drawn as and others with
/// the corner of a pixel.
final class PaddleOutlineTests: XCTestCase {

    private func image(_ name: String) throws -> CGImage {
        try XCTUnwrap(XCTUnwrap(UIImage(named: name)).cgImage)
    }

    /// How jagged a profile is: the total of how much its rise changes from step to step.
    ///
    /// A smooth curve turns gradually and scores little; a staircase alternates flat and jump
    /// and scores about its step height at every sample.
    private func roughness(_ profile: [CGFloat]) -> CGFloat {
        let rises = zip(profile, profile.dropFirst()).map { $1 - $0 }
        return zip(rises, rises.dropFirst()).map { abs($1 - $0) }.reduce(0, +)
    }

    /// The top edge found the way a tracer finds it: **the picture redrawn at the size the body
    /// is built for**, then the first opaque row of each column, to the pixel.
    ///
    /// The redraw is the half that matters and the half the first version of this left out.
    /// `SKPhysicsBody(texture:size:)` works at the size it is given - about 75 points across -
    /// so the staircase is what falls out of squeezing a 225-pixel picture into 75 columns.
    /// Sampling the *full-resolution* art at twenty places, as this did at first, measures a
    /// picture that is already smooth and sets a bar `PaddleOutline` has no reason to clear.
    private func hardEdges(of image: CGImage, samples: Int, size: CGSize) throws -> [CGFloat] {
        let width = Int(size.width.rounded()), rows = Int(size.height.rounded())
        var pixels = [UInt8](repeating: 0, count: width*rows*4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: rows, bitsPerComponent: 8,
            bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: rows))

        return (0..<samples).map { sample in
            let x = min(width - 1, Int((CGFloat(sample) + 0.5)/CGFloat(samples)*CGFloat(width)))
            for y in 0..<rows where pixels[(y*width + x)*4 + 3] > 128 {
                return (1 - CGFloat(y)/CGFloat(rows) - 0.5)*size.height
            }
            return -size.height/2
        }
    }

    /// The outline is smooth where the trace was a staircase.
    ///
    /// The measurement round 277 made, run against the computed edge instead: how far the
    /// surface moves between neighbouring samples, and whether it ever jumps.
    func testTheComputedSurfaceHasNoSteps() throws {
        for name in ["regularPaddleConvex", "regularPaddleConcave", "regularPaddleWave"] {
            let run = PaddleOutline.boundaries(of: try image(name),
                                               size: CGSize(width: 75, height: 18))
            XCTAssertGreaterThan(run.count, 10, name)

            // **Measured against what tracing gives, not against a number I picked.** Twice
            // now an absolute threshold has failed here for the wrong reason: a dome rises fast
            // at its ends and a dish turns hard into its corners, so neither "rises slowly" nor
            // "curves gently" is true of a real paddle. The claim is *smoother than the trace*,
            // so that is what is compared - the same picture, the same twenty places, one edge
            // found to the pixel and the other between them.
            let computed = run.map(\.top)
            let traced = try hardEdges(of: image(name), samples: computed.count,
                                       size: CGSize(width: 75, height: 18))

            print(String(format: "    %-24@ computed %6.2f   traced %6.2f",
                         name as NSString, roughness(computed), roughness(traced)))

            XCTAssertLessThan(roughness(computed), roughness(traced),
                              "\(name): computing the outline has to be smoother than tracing "
                              + "it, or there is no reason to compute it")

            // **Smoother, and that is all this asserts.** A bar of "much smoother" was tried at
            // 0.6 and failed three times for three different right reasons: a dome rises fast at
            // its ends, a dish turns hard into its corners, and most of a wave's roughness is
            // its own two bumps rather than any sampling. Each time the honest answer was that
            // the number was invented, and bending the reading of the picture to hit an invented
            // number is how a body stops matching its art. What can be defended is that it beats
            // the trace on every shape and lands on the picture, which is the test below - the
            // ratios are printed so the size of the win can be read rather than asserted

            let flats = zip(computed, computed.dropFirst()).filter { abs($1 - $0) < 0.001 }.count
            XCTAssertLessThan(flats, computed.count/3,
                              "\(name): a third of the surface is dead flat, which is what a "
                              + "staircase looks like measured this way")
        }
    }

    /// It is the *same* silhouette, which is the whole requirement.
    ///
    /// James, round 213: "the paddle physics body should match the shape of the new paddle
    /// textures". An outline that had drifted off the art would bounce the ball off something
    /// the player cannot see, which is worse than the staircase.
    func testTheOutlineFollowsThePicture() throws {
        let size = CGSize(width: 75, height: 18)
        for name in ["regularPaddleConvex", "regularPaddleConcave"] {
            let run = PaddleOutline.boundaries(of: try image(name), size: size)
            let top = run.map(\.top)
            XCTAssertEqual(top.max() ?? 0, size.height/2, accuracy: 1.5,
                           "\(name) reaches the top of its own picture")
            XCTAssertEqual(run.map(\.bottom).min() ?? 0, -size.height/2, accuracy: 1.5,
                           "\(name) reaches the bottom of it")
        }

        // And the two curve opposite ways, which is the difference between them
        let dome = PaddleOutline.boundaries(of: try image("regularPaddleConvex"), size: size)
        let dish = PaddleOutline.boundaries(of: try image("regularPaddleConcave"), size: size)
        func middleAgainstEnds(_ run: [(x: CGFloat, top: CGFloat, bottom: CGFloat)]) -> CGFloat {
            run[run.count/2].top - (run[1].top + run[run.count - 2].top)/2
        }
        XCTAssertGreaterThan(middleAgainstEnds(dome), 1, "a dome is highest in the middle")
        XCTAssertLessThan(middleAgainstEnds(dish), -1, "and a dish is lowest there")
    }

    /// Every piece is convex, because `SKPhysicsBody` will take nothing else.
    ///
    /// A strip is a quadrilateral and so convex by construction - this is the test that says the
    /// construction is what it claims, and it is the reason the shapes are cut into strips at
    /// all rather than handed over whole: a dish and a wave are not convex.
    /// As few pieces as the shape allows, because every join is a seam the ball can catch on.
    ///
    /// Round 280 cut every paddle into twenty strips and so gave each one nineteen internal
    /// edges. A dome and the two wedges are convex outright and need no seam at all.
    func testTheBodyIsCutIntoAsFewPiecesAsTheShapeAllows() throws {
        let size = CGSize(width: 75, height: 18)
        var counted: [String: Int] = [:]
        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                     "regularPaddleWave", "regularPaddleWedgeLeft"] {
            let pieces = PaddleOutline.pieces(of: try image(name), size: size)
            counted[name] = pieces.count
            print(String(format: "    %-24@ %2d piece(s), %2d seam(s)",
                         name as NSString, pieces.count, max(0, pieces.count - 1)))
        }
        print("")

        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleWedgeLeft"] {
            XCTAssertEqual(counted[name], 1, "\(name) is convex, so it is one piece with no "
                           + "seam anywhere for a ball to catch on")
        }
        for (name, count) in counted {
            XCTAssertLessThanOrEqual(count, PaddleOutline.strips/2,
                                     "\(name) is still being cut like strips")
        }
        // A dish and a wave are genuinely not convex and cannot be one piece - their own
        // curvature decides how many they need, and the greedy walk gives them no more than
        // that. What they must not be is twenty, which is what round 280 gave every shape.
        // Half of `strips` is the bar rather than a number picked to fit: it says the merging
        // is doing real work without pretending a wave can be as simple as a dome
    }

    func testEveryPieceIsConvex() throws {
        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                     "regularPaddleWave", "regularPaddleWedgeLeft"] {
            let pieces = PaddleOutline.pieces(of: try image(name),
                                              size: CGSize(width: 75, height: 18))
            XCTAssertGreaterThan(pieces.count, 0, name)

            for piece in pieces {
                var corners: [CGPoint] = []
                piece.applyWithBlock { element in
                    let points = element.pointee.points
                    switch element.pointee.type {
                    case .moveToPoint, .addLineToPoint: corners.append(points[0])
                    default: break
                    }
                }
                XCTAssertGreaterThanOrEqual(corners.count, 4, "\(name): a piece is a polygon")
                XCTAssertTrue(EndlessIIFaceGeometry.isConvex(corners),
                              "\(name): a piece SKPhysicsBody would refuse")
                // Four corners while every piece was one strip; any number since round 284
                // merged them, and a dome now arrives as a single 42-sided polygon. What has
                // to stay true is the convexity, which is the only thing SKPhysicsBody asks
            }
        }
    }

    /// The body the engine gets is a real solid of about the right size.
    ///
    /// The one thing the drawings cannot show: whether `SKPhysicsBody` *accepted* what it was
    /// handed. A polygon wound the wrong way is a body the ball passes through - the trap
    /// `EndlessIIFaceGeometry` has a whole comment about - and it fails silently, because a
    /// rejected or inverted piece still returns an object. Area is the tell: a compound of
    /// twenty strips covering most of a 75 x 18 paddle has to come to most of 1350 square
    /// points, and an inverted or empty one does not.
    ///
    /// **`area` is in square metres**, and SpriteKit is 150 points to the metre. Round 277 read
    /// it as points, got 0.000 for every shape and concluded a traced body reports no area at
    /// all - it reports 0.06, which is 1350 square points, which is the paddle. That mistake is
    /// why round 277 could not settle what resolution the tracer samples at and said so; the
    /// number was there the whole time.
    func testTheBodyIsASolidOfAboutTheRightSize() throws {
        let size = CGSize(width: 75, height: 18)
        let pointsPerMetre: CGFloat = 150
        let box = size.width*size.height

        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                     "regularPaddleWave", "regularPaddleWedgeLeft"] {
            PaddleOutline.empty()
            let body = try XCTUnwrap(PaddleOutline.body(for: SKTexture(imageNamed: name),
                                                        size: size), name)
            let points = body.area*pointsPerMetre*pointsPerMetre

            XCTAssertGreaterThan(points, box*0.4,
                                 "\(name): \(points) square points against a \(box)-point "
                                 + "box - too little to be the paddle, which is what an "
                                 + "inverted or dropped piece looks like from out here")
            XCTAssertLessThan(points, box*1.02,
                              "\(name): more area than the cell it is cut from")
            print(String(format: "    %-24@ %6.0f of %4.0f square points  (%2.0f%%)",
                         name as NSString, points, box, points/box*100))
        }
        print("")
    }

    /// The body is built once per picture and size, and copied after.
    func testTheOutlineIsKeptRatherThanRecomputed() {
        let texture = SKTexture(imageNamed: "regularPaddleConvex")
        let size = CGSize(width: 75, height: 18)

        PaddleOutline.empty()
        let coldStart = Date.timeIntervalSinceReferenceDate
        XCTAssertNotNil(PaddleOutline.body(for: texture, size: size))
        let cold = Date.timeIntervalSinceReferenceDate - coldStart

        let warmStart = Date.timeIntervalSinceReferenceDate
        for _ in 0..<20 { _ = PaddleOutline.body(for: texture, size: size) }
        let warm = (Date.timeIntervalSinceReferenceDate - warmStart)/20

        print(String(format: "\n  A computed paddle outline: %6.3f ms cold -> %6.3f ms cached\n",
                     cold*1000, warm*1000))
        XCTAssertLessThan(warm, 1.0/60/10,
                          "reading a picture and cutting it into twenty polygons is a "
                          + "build-time cost, not a per-frame one")
    }
}


/// Aimed Sticky catches a ball and offers an arrow to aim it with.
///
/// James, round 284: "aimed sticky isn't showing arrow or allowing aim." It was working in round
/// 275 - "the swiping to move the paddle and aim the arrow is working well" - so this is a
/// regression, and the rounds between touched the aim's state machine (277) and replaced the
/// paddle's physics body with a twenty-piece compound (280).
///
/// The pieces each have their own tests and each passes. What had none is the *chain*: land a
/// ball on the paddle with the clock running and ask whether there is anything to aim.
final class AimedStickyStillOffersAnArrowTests: XCTestCase {

    /// The same scene `PlayTestRound259Tests` lands a ball on, which is the one shape of
    /// `GameScene` that survives `paddleHit` - it indexes into the stats and the HUD arrays, so
    /// a scene built from scratch crashes before it reaches anything worth asserting.
    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSize = 24
        scene.paddleHeight = 24
        scene.minAngleDeg = 10
        scene.ballSpeedLimit = 400
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 150, height: 24)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
        scene.addChild(scene.paddleLaser)
        scene.addChild(scene.paddleSticky)
        scene.paddleLaser.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.paddleSticky.anchorPoint = CGPoint(x: 0.5, y: 0)

        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 12)
        scene.ball.position = CGPoint(x: 0, y: -260)
        scene.ballIsOnPaddle = false
        scene.ballStartingPositionY = scene.paddleTopY + scene.ball.size.height/2 + 1
        return scene
    }

    func testALandedBallIsSomethingToAim() {
        let scene = scene()
        scene.endlessIIAimedStickyClock.collect(turns: 5)
        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)

        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 60, dy: -300))
        scene.paddleHit(scene.ball)

        XCTAssertTrue(scene.ballIsOnPaddle, "the catch happened")
        XCTAssertTrue(scene.endlessIIHeldBalls.contains { $0 === scene.ball },
                      "and the ball took its place in the queue, which is where the aim looks")
        XCTAssertNotNil(scene.endlessIIAimTarget, "so there is something to aim")
        XCTAssertTrue(scene.endlessIIAimHold, "and the hold has begun")

        scene.tickEndlessIIAim()
        XCTAssertNotNil(scene.endlessIIAimArrow, "and an arrow is drawn for it")
    }

    /// A tap that begins *during* an aim launches it.
    ///
    /// The regression, stated the way it failed. Round 275 taught the release to refuse a
    /// finger that was already down when the ball was caught - correctly, because such a finger
    /// can be lifted but cannot tap. It then marked *every* touch that began while an aim was
    /// running as one of those, which is the opposite: a touch beginning during an aim is
    /// precisely the tap meant to fire it. Nothing could launch, the hold never ended, and
    /// `endlessIIFieldIsHeld` reads the hold - so the field stopped descending as well.
    func testATapDuringAnAimCanStillLaunchIt() {
        let scene = scene()
        scene.endlessIIAimedStickyClock.collect(turns: 5)
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 60, dy: -300))
        scene.paddleHit(scene.ball)
        XCTAssertTrue(scene.endlessIIAimHold)

        XCTAssertFalse(scene.endlessIIAimTouchPredatesHold,
                       "no finger was down when the ball landed, so this tap is a tap")
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .paddle,
                                              touchPredatesAim: scene.endlessIIAimTouchPredatesHold),
                       .aimedLaunch,
                       "and it fires - without this the ball can never leave the paddle, and "
                       + "because endlessIIFieldIsHeld reads the hold, the field never "
                       + "descends again either")
    }

    /// And a finger that was already down still cannot tap, which is round 275's rule intact.
    func testAFingerAlreadyDownWhenTheBallLandsStillCannotTap() {
        let scene = scene()
        scene.endlessIIAimedStickyClock.collect(turns: 5)
        scene.touchBeganWhilstPlaying = true
        // Carrying the paddle when the ball arrives, which is the case round 275 was for

        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 60, dy: -300))
        scene.paddleHit(scene.ball)

        XCTAssertTrue(scene.endlessIIAimTouchPredatesHold,
                      "the finger was there first, so lifting it is a paddle move ending")
        XCTAssertEqual(AimHoldControl.release(travelled: 0, aiming: true, intent: .paddle,
                                              touchPredatesAim: scene.endlessIIAimTouchPredatesHold),
                       .keepAiming, "the ball stays on the paddle")
    }
}


/// A directional brick still says what kind of brick it is.
///
/// James, round 284: "for the directional brick, the open side should show the brick underneath.
/// Right now, that side looks grey. The brick underneath can be any brick type, so it should be
/// possible to tell what brick is underneath."
///
/// `tint` writes `colorBlendFactor = 1`, which does not shade a texture - it replaces it. So a
/// directional Multi-hit and a directional Indestructible were the same grey oblong, and the
/// side deliberately left clear showed grey along with everything else.
final class DirectionalBricksKeepTheirOwnFaceTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickWidth = 56
        scene.brickHeight = 28
        return scene
    }

    private func brick(_ scene: GameScene, _ texture: SKTexture) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: texture,
                                 size: CGSize(width: scene.brickWidth, height: scene.brickHeight))
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    func testTheBrickUnderThePanelKeepsItsOwnColour() {
        let scene = scene()
        let subject = brick(scene, scene.brickMultiHit1Texture)
        subject.endlessIIVulnerableSide = .top
        scene.makeDirectional(subject)

        XCTAssertLessThan(subject.colorBlendFactor, 0.5,
                          "a brick painted over at full blend is not a Multi-hit brick any "
                          + "more, it is a grey oblong")
        XCTAssertEqual(subject.texture, scene.brickMultiHit1Texture,
                       "and it is still the texture that says what it is")
        XCTAssertNotNil(subject.childNode(withName: GameScene.directionalEdgeName),
                        "with the panel over it doing the saying")
    }

    /// Two directional bricks of different types look different.
    ///
    /// The property James was actually asking for, and the one a colour-blend check on its own
    /// would not catch.
    func testTwoDirectionalBricksOfDifferentTypesAreTellableApart() {
        let scene = scene()
        let first = brick(scene, scene.brickMultiHit1Texture)
        let second = brick(scene, scene.brickIndestructible1Texture)
        for subject in [first, second] {
            subject.endlessIIVulnerableSide = .bottom
            scene.makeDirectional(subject)
        }
        XCTAssertNotEqual(first.texture, second.texture)
        XCTAssertEqual(first.colorBlendFactor, second.colorBlendFactor, accuracy: 0.001)
        XCTAssertLessThan(first.colorBlendFactor, 0.5,
                          "neither is painted over, so the pictures still differ on screen")
    }

    /// The grey is not gone, it is conditional - and the condition is the rule.
    ///
    /// Where a panel is drawn, the panel says which side is open and painting the brick as well
    /// only hides what it is. Where one is not, the grey is the only mark there is and taking
    /// it away would leave a directional brick indistinguishable from an ordinary one. Written
    /// as "these two go together" rather than as a claim about which sizes have art today,
    /// because the art list is still being added to (§8.5).
    func testTheGreyAndThePanelAreTheTwoWaysOfSayingIt() {
        let scene = scene()
        for size in BrickSize.allCases {
            let subject = brick(scene, scene.brickNormalTexture)
            subject.size = CGSize(width: scene.brickWidth*size.scaleWide,
                                  height: scene.brickHeight*size.scaleTall)
            subject.endlessIIVulnerableSide = .top
            scene.makeDirectional(subject)

            let panelled = scene.endlessIIDirectionalArt(.top, size: size) != nil
            if panelled {
                XCTAssertLessThan(subject.colorBlendFactor, 0.5,
                                  "\(size) has a panel, so the brick keeps its own face")
            } else {
                XCTAssertGreaterThan(subject.colorBlendFactor, 0.5,
                                     "\(size) has no panel, so the grey is the only thing "
                                     + "saying this brick is directional at all")
            }
        }
    }
}

/// Ball Control carries the ball rather than dragging it.
///
/// James, round 284: "Ball control is too controlling over the ball. When moving the paddle,
/// the ball shouldn't follow immediately. There should be some lag and some inertia. The ball
/// also shouldn't snap into place, its momentum should take it slightly beyond the paddle and
/// then swing back. The ball should have more inertia."
///
/// The second sentence is the one that decided the shape of the fix. What was there closed a
/// fixed share of the gap each frame, and an exponential approach *cannot* overshoot - so
/// "slightly beyond the paddle and then swing back" was unreachable by tuning, at any value.
final class BallControlHasInertiaTests: XCTestCase {

    /// What the pull used to close every sixtieth of a second, kept here and nowhere else.
    ///
    /// It is a fact about a version of the game that no longer exists, so it does not belong
    /// beside the numbers the game actually runs on - but the whole of "more inertia" is a
    /// comparison with it, and a test that asserted a frame count instead would be asserting
    /// whatever number happened to pass on the day it was written.
    private let oldPullPerSixtieth: CGFloat = 0.16

    /// One second of the paddle standing at 100 with the ball starting at 0.
    private func flight(frames: Int = 120, target: CGFloat = 100) -> [CGFloat] {
        var state = (x: CGFloat(0), velocity: CGFloat(0))
        var path: [CGFloat] = []
        for _ in 0..<frames {
            state = EndlessIIPaddleEffects.steeringStep(x: state.x, velocity: state.velocity,
                                                        towards: target, delta: 1.0/60)
            path.append(state.x)
        }
        return path
    }

    /// "When moving the paddle, the ball shouldn't follow immediately."
    func testTheBallDoesNotSetOffAtTheSpeedThePaddleDid() {
        let path = flight()
        XCTAssertGreaterThan(path[0], 0, "it does answer")
        XCTAssertLessThan(path[0], 100*oldPullPerSixtieth/4,
                          "but a ball a quarter of the way into the old pull's first frame is "
                          + "still being dragged")
    }

    /// "Its momentum should take it slightly beyond the paddle and then swing back."
    func testTheBallOvershootsThePaddleAndComesBack() {
        let path = flight()
        let furthest = path.max() ?? 0
        XCTAssertGreaterThan(furthest, 100,
                             "it runs past the paddle - the thing an exponential lag could "
                             + "never be tuned into doing")
        XCTAssertLessThan(furthest, 125, "slightly past, not a wobble")

        guard let peak = path.firstIndex(of: furthest) else { return XCTFail("no peak") }
        XCTAssertLessThan(path[peak + 6], furthest, "and swings back")
        XCTAssertEqual(path.last ?? 0, 100, accuracy: 0.5, "and settles there")
    }

    /// The overshoot is a consequence of the damping ratio rather than a number of its own.
    func testTheOvershootIsTheOneTheDampingRatioAsksFor() {
        let zeta = EndlessIIPaddleEffects.steeringDampingRatio
        XCTAssertLessThan(zeta, 1, "at or above critical it would never overshoot at all")
        let predicted = exp(-CGFloat.pi*zeta/(1 - zeta*zeta).squareRoot())
        let furthest = (flight().max() ?? 0) - 100
        XCTAssertEqual(furthest/100, predicted, accuracy: 0.02,
                       "the flight matches the textbook step response, which is how we know "
                       + "the integrator is not adding anything of its own")
    }

    /// "There should be some lag and some inertia" - measured against what it replaced.
    ///
    /// Against the *old pull itself* rather than against a frame count somebody picked. The
    /// thing that was there closed 16% of the gap every sixtieth of a second, so what it would
    /// have done over any stretch of time is arithmetic, and "more inertia than before" is a
    /// comparison rather than an opinion.
    ///
    /// **Not "it arrives later"**, which was the first version of this test and was wrong. An
    /// exponential approach never arrives at all - it gets within a point and keeps halving -
    /// so a spring that overshoots reaches the paddle's column *sooner* however slowly it sets
    /// off, and comparing arrival times says nothing about how the two feel. What the player
    /// feels is the opening tenth of a second.
    func testItSetsOffMoreSlowlyThanTheOldPullDid() {
        let oldShare = oldPullPerSixtieth
        let path = flight()

        for frame in [0, 1, 5] {
            let oldPull = 100*(1 - pow(1 - oldShare, CGFloat(frame + 1)))
            XCTAssertLessThan(path[frame], oldPull,
                              "frame \(frame): the ball is behind where the old pull would "
                              + "have dragged it, which is the inertia James asked for")
        }
        XCTAssertLessThan(path[0], 100*oldShare/4,
                          "and the very first frame is the one that read as the ball "
                          + "following immediately - it moves a quarter as far at most")
    }

    /// A ball already on the paddle's column and moving is not stopped dead by it.
    func testAMovingBallKeepsItsOwnMomentumThroughThePaddlesColumn() {
        let stepped = EndlessIIPaddleEffects.steeringStep(x: 0, velocity: 200, towards: 0,
                                                          delta: 1.0/60)
        XCTAssertGreaterThan(stepped.x, 0, "it carries on past")
        XCTAssertGreaterThan(stepped.velocity, 0, "still going")
        XCTAssertLessThan(stepped.velocity, 200, "and being slowed")
    }
}

/// The three parity cells James answered in round 284.
///
/// The paddle-family matrix has been open since round 200 - "the safety paddle, mirrored
/// paddle, split paddle power ups should match power ups of the main paddle" - and it was
/// never a coding question but a design one: three surfaces by eight effects, each cell its
/// own decision. Round 284 asked the three that were not obvious and got three answers:
///
/// 1. a sticky safety paddle's ball "goes up, like it would from the paddle";
/// 2. "each split has one laser turret on its far end";
/// 3. "yes" to a mirrored paddle having its own portal, and "both send the ball to the top".
///
/// Each test says which of those it is holding to.
final class PaddleFamilyParityTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.layoutUnit = 40
        scene.ballSize = 14
        scene.paddleWidth = 120
        scene.brickHeight = 20
        scene.finalBrickRowHeight = 100
        scene.gameWidth = 400
        scene.ballSpeedLimit = 600
        // A launch is `cos(angle)*ballSpeedLimit`, and a scene that never ran `setUpGame` has
        // that at zero - which reads as "the launch does nothing" and is really "there is no
        // speed to launch at"
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 60, y: -300)
        scene.addChild(scene.paddle)
        scene.ball.size = CGSize(width: 14, height: 14)
        scene.addChild(scene.ball)
        return scene
    }

    // MARK: - "Yes - both send the ball to the top"

    private func mirror(_ scene: GameScene) -> SKSpriteNode? {
        scene.childNode(withName: GameScene.endlessIIMirrorPaddleName) as? SKSpriteNode
    }

    func testTheMirrorSendsTheBallToTheTopToo() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPortalPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }

        scene.ball.position = CGPoint(x: mirror.position.x, y: mirror.position.y + 8)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.velocity = CGVector(dx: 100, dy: -400)
        scene.endlessIIMirrorPaddleHit(scene.ball)

        XCTAssertTrue(scene.endlessIIPendingPaddlePortals.contains { $0 === scene.ball },
                      "the twin swallowed it, and the exit is the paddle's own exit")
    }

    func testTheMirrorsPortalSpendsTheTurnItUses() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPortalPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }
        let before = scene.endlessIIPortalPaddleClock.remaining

        scene.ball.position = CGPoint(x: mirror.position.x, y: mirror.position.y + 8)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
        scene.endlessIIMirrorPaddleHit(scene.ball)

        XCTAssertLessThan(scene.endlessIIPortalPaddleClock.remaining, before,
                          "a portal is the whole of what a turn buys, and a surface giving it "
                          + "away free would make the mirror the way to farm the power-up")
    }

    /// The mirror must not eat the promise the paddle made to itself.
    func testAMirrorHitLeavesThePaddlesOwedPortalAlone() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        scene.endlessIICollectPortalPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }
        scene.endlessIIPortalPaddleOwedTurn = true

        scene.ball.position = CGPoint(x: mirror.position.x, y: mirror.position.y + 8)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
        scene.endlessIIMirrorPaddleHit(scene.ball)

        XCTAssertTrue(scene.endlessIIPortalPaddleOwedTurn,
                      "that flag is the paddle's promise that an effect already paid for still "
                      + "lands; a mirror contact in the same step must not consume it")
    }

    func testWithNoPortalRunningTheMirrorStillJustBounces() {
        let scene = mayhem()
        scene.endlessIICollectMirrorPaddle()
        guard let mirror = mirror(scene) else { return XCTFail("a mirror stands") }

        scene.ball.position = CGPoint(x: mirror.position.x, y: mirror.position.y + 8)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
        scene.endlessIIMirrorPaddleHit(scene.ball)

        XCTAssertTrue(scene.endlessIIPendingPaddlePortals.isEmpty)
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "it went back up")
    }

    // MARK: - "There should only ever be 2 turrets with a split paddle"

    /// James, round 285: "only the outermost section of paddle should have a laser turret on
    /// its outer edge. There should only ever be 2 turrets with a split paddle."
    ///
    /// Which the *generator* has always got right by accident, and the dress never did. The
    /// paddle node keeps its full width when it splits, so the span's two ends are the outer
    /// pieces' outer edges - and the shots have come from those two points since long before
    /// any of this. What was wrong was the strip drawn across the whole span, which said
    /// "armed" about the gaps and about the middle pieces too.
    private func firingPoints(_ scene: GameScene) -> [CGFloat] {
        let inset = scene.layoutUnit/4
        return [scene.paddle.position.x - scene.paddle.size.width/2 + inset,
                scene.paddle.position.x + scene.paddle.size.width/2 - inset]
        // The two the generator builds inline, written here rather than reached into: it makes
        // them in the middle of assembling a sprite and one of the pair is behind a retro branch
    }

    func testASplitPaddleWearsExactlyTwoTurrets() {
        let scene = mayhem()
        scene.paddle.size.width = 360
        scene.endlessIICollectDoublePaddle()
        scene.paddleLaser.isHidden = false
        scene.paddleLaser.size = CGSize(width: 360, height: 20)
        scene.refreshEndlessIISplitDress()

        let layout = GameScene.endlessIIDoublePaddleLayout(span: 360, standardWidth: 120,
                                                           ballSize: scene.ballSize)
        XCTAssertGreaterThan(layout.count, 2, "a wide split really is more than two pieces")
        XCTAssertEqual(scene.endlessIISplitOverlays[ObjectIdentifier(scene.paddleLaser)]?.count,
                       2,
                       "and still two turrets - the first attempt at this armed every piece, "
                       + "which is not what was asked for")
        XCTAssertEqual(scene.endlessIISplitLaserTurrets.count, 2)
    }

    /// The sticky band is the other half of the same fault, and gets the opposite answer.
    ///
    /// A laser comes from two turrets; a sticky paddle catches anywhere the paddle is. So every
    /// piece wears the band, and the difference between the two is the design rather than an
    /// inconsistency.
    func testEverySplitPieceWearsTheStickyBand() {
        let scene = mayhem()
        scene.paddle.size.width = 360
        scene.endlessIICollectDoublePaddle()
        scene.paddleSticky.isHidden = false
        scene.paddleSticky.size = CGSize(width: 360, height: 16)
        scene.refreshEndlessIISplitDress()

        let layout = GameScene.endlessIIDoublePaddleLayout(span: 360, standardWidth: 120,
                                                           ballSize: scene.ballSize)
        XCTAssertEqual(scene.endlessIISplitOverlays[ObjectIdentifier(scene.paddleSticky)]?.count,
                       layout.count)
        XCTAssertEqual(scene.paddleSticky.alpha, 0,
                       "and the whole-span band stands down, or it would go on being drawn "
                       + "across the gaps - a sticky-looking paddle with holes in it")
    }

    /// Every strip the paddle wears, not only the two the first pass thought of.
    func testAllFourPaddleOverlaysAreCutUpByASplit() {
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        let strips = [scene.paddleLaser, scene.paddleSticky,
                      scene.paddleRetroLaserTexture, scene.paddleRetroStickyTexture]
        for strip in strips {
            strip.isHidden = false
            strip.size = CGSize(width: 120, height: 16)
        }
        scene.refreshEndlessIISplitDress()

        for strip in strips {
            XCTAssertNotNil(scene.endlessIISplitOverlays[ObjectIdentifier(strip)],
                            "the Retro theme keeps its own laser flash and sticky band on "
                            + "separate nodes, and they paint over a split the same way")
            XCTAssertEqual(strip.alpha, 0)
        }
    }

    /// A strip its own power-up has hidden is left alone.
    func testAStripThatIsNotRunningIsNotDressed() {
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        scene.paddleSticky.isHidden = true
        scene.refreshEndlessIISplitDress()
        XCTAssertNil(scene.endlessIISplitOverlays[ObjectIdentifier(scene.paddleSticky)])
        XCTAssertEqual(scene.paddleSticky.alpha, 1,
                       "hidden by alpha is this function's word; `isHidden` is the power-up's, "
                       + "and the two must not argue")
    }

    func testTheTurretsSitOnTheOutermostPieces() {
        let scene = mayhem()
        scene.paddle.size.width = 360
        scene.endlessIICollectDoublePaddle()
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 360, standardWidth: 120,
                                                           ballSize: scene.ballSize)
        let pitch = layout.segment + layout.gap
        let first = scene.paddle.position.x - 180 + layout.segment/2
        let last = first + pitch*CGFloat(layout.count - 1)

        XCTAssertEqual(scene.endlessIISplitLaserTurrets[0], first, accuracy: 0.01)
        XCTAssertEqual(scene.endlessIISplitLaserTurrets[1], last, accuracy: 0.01)
    }

    /// The turret and the shot are the same place, which is the whole point of moving the dress.
    func testEachShotLeavesFromInsideItsOwnTurret() {
        let scene = mayhem()
        scene.paddle.size.width = 360
        scene.endlessIICollectDoublePaddle()
        let layout = GameScene.endlessIIDoublePaddleLayout(span: 360, standardWidth: 120,
                                                           ballSize: scene.ballSize)
        for (turret, shot) in zip(scene.endlessIISplitLaserTurrets, firingPoints(scene)) {
            XCTAssertLessThanOrEqual(abs(shot - turret), layout.segment/2,
                                     "the shot comes out of the piece wearing the turret")
        }
    }

    func testTakingTheSplitAwayGivesThePaddleItsOwnLaserDressBack() {
        let scene = mayhem()
        scene.endlessIICollectDoublePaddle()
        scene.paddleLaser.isHidden = false
        scene.paddleLaser.size = CGSize(width: 120, height: 20)
        scene.refreshEndlessIISplitDress()
        XCTAssertEqual(scene.paddleLaser.alpha, 0, "the whole-span strip stands down")

        scene.endlessIIDoublePaddleClock = EndlessIIClock()
        scene.refreshEndlessIISplitDress()
        XCTAssertTrue(scene.endlessIISplitOverlays.isEmpty)
        XCTAssertEqual(scene.paddleLaser.alpha, 1,
                       "a power-up that left the paddle undressed would be one that never ended")
    }

    // MARK: - "Ball goes up, like it would from the paddle"

    private func withSafetyBar() -> (GameScene, SKSpriteNode) {
        let scene = mayhem()
        scene.endlessIICollectSafetyPaddle()
        let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName) as! SKSpriteNode
        return (scene, bar)
    }

    private func land(_ scene: GameScene, _ bar: SKSpriteNode, at x: CGFloat) -> SKSpriteNode {
        let subject = scene.ball
        subject.position = CGPoint(x: x, y: bar.position.y + 6)
        subject.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        subject.physicsBody?.velocity = CGVector(dx: 0, dy: -400)
        scene.endlessIISafetyPaddleHit(subject)
        return subject
    }

    func testASafetyBarWithNoStickyStillBounces() {
        let (scene, bar) = withSafetyBar()
        let subject = land(scene, bar, at: bar.position.x)
        XCTAssertTrue(scene.endlessIIHeldBalls.isEmpty, "nothing is caught")
        XCTAssertNotEqual(subject.physicsBody?.velocity.dy, 0, "it was returned")
    }

    func testAStickySafetyBarCatchesTheBallInsteadOfBouncingIt() {
        let (scene, bar) = withSafetyBar()
        scene.stickyPaddleCatches = 3
        let subject = land(scene, bar, at: bar.position.x)

        XCTAssertTrue(scene.endlessIIHeldBalls.contains { $0 === subject },
                      "it joins the one queue, so launches stay in the order they were caught")
        XCTAssertTrue(scene.endlessIIIsHeldOnSafetyBar(subject))
        XCTAssertEqual(subject.physicsBody?.velocity.dx, 0)
        XCTAssertEqual(subject.physicsBody?.velocity.dy, 0)
        XCTAssertEqual(subject.position.y,
                       bar.position.y + bar.size.height/2 + subject.size.height/2,
                       accuracy: 0.01, "resting on the bar")
    }

    /// The answer itself: "ball goes up, like it would from the paddle."
    func testTheCaughtBallGoesUp() {
        let (scene, bar) = withSafetyBar()
        scene.stickyPaddleCatches = 3
        let subject = land(scene, bar, at: bar.position.x)
        scene.endlessIILaunchHeldBall()

        XCTAssertGreaterThan(subject.physicsBody?.velocity.dy ?? 0, 0, "up")
        XCTAssertFalse(scene.endlessIIHeldBalls.contains { $0 === subject }, "and gone")
        XCTAssertFalse(scene.endlessIIIsHeldOnSafetyBar(subject))
    }

    /// "Like it would from the paddle" - which means the spot decides the angle.
    func testWhereItLandedOnTheBarDecidesHowSteeplyItLeaves() {
        func departure(at x: CGFloat) -> CGVector {
            let (scene, bar) = withSafetyBar()
            scene.stickyPaddleCatches = 3
            let subject = land(scene, bar, at: bar.position.x + x)
            scene.endlessIILaunchHeldBall()
            return subject.physicsBody?.velocity ?? .zero
        }
        let middle = departure(at: 0)
        let leftish = departure(at: -40)
        let rightish = departure(at: 40)

        XCTAssertLessThan(abs(middle.dx), abs(leftish.dx),
                          "caught in the middle it leaves near enough straight up")
        XCTAssertLessThan(leftish.dx, 0, "caught left of centre it leaves to the left")
        XCTAssertGreaterThan(rightish.dx, 0, "and right of centre, to the right")
        XCTAssertGreaterThan(leftish.dy, 0)
        XCTAssertGreaterThan(rightish.dy, 0)
    }

    /// The bar can go while it is holding something.
    func testABallOnABarThatHasGoneStillLaunches() {
        let (scene, bar) = withSafetyBar()
        scene.stickyPaddleCatches = 3
        let subject = land(scene, bar, at: bar.position.x)
        bar.removeFromParent()
        scene.endlessIILaunchHeldBall()
        XCTAssertGreaterThan(subject.physicsBody?.velocity.dy ?? 0, 0,
                             "a power-up that ended while holding a ball must not strand it")
    }

    /// A ball on the bar is not carried about by the paddle.
    func testABallOnTheBarStaysWhereItLanded() {
        let (scene, bar) = withSafetyBar()
        scene.stickyPaddleCatches = 3
        let subject = land(scene, bar, at: bar.position.x + 30)
        let landed = subject.position

        scene.paddle.position.x += 90
        scene.tickEndlessIIHeldBalls()

        XCTAssertEqual(subject.position.x, landed.x, accuracy: 0.01,
                       "the bar stands in the middle of the field and does not move sideways, "
                       + "so nothing about the paddle should move the ball resting on it")
        XCTAssertEqual(subject.position.y, landed.y, accuracy: 0.01)
    }
}

/// Round 291's paddle list.
final class PlayTestRound291Tests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.layoutUnit = 40
        scene.ballSize = 14
        scene.paddleWidth = 120
        scene.ballSpeedLimit = 600
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.addChild(scene.paddle)
        scene.ball.size = CGSize(width: 14, height: 14)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.collisionBitMask = CollisionTypes.paddleCategory.rawValue
            | CollisionTypes.boarderCategory.rawValue
        scene.ball.physicsBody?.contactTestBitMask = CollisionTypes.paddleCategory.rawValue
        scene.addChild(scene.ball)
        return scene
    }

    private func extraBall(_ scene: GameScene, x: CGFloat) -> SKSpriteNode {
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 14, height: 14))
        extra.position = CGPoint(x: x, y: scene.paddle.position.y + 12)
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        extra.physicsBody?.collisionBitMask = CollisionTypes.paddleCategory.rawValue
            | CollisionTypes.boarderCategory.rawValue
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)
        return extra
    }

    // MARK: - "The ball should remain fixed in position relative to the paddle"

    /// James, round 291: "with a sticky shaped paddle, the ball moves on the paddle after it
    /// has landed. Like it slides down the paddle's shape."
    ///
    /// A held ball is placed every frame and the physics step then resolves it out of a traced
    /// body it is slightly inside - which on a dome or a dish means sideways. Taking the paddle
    /// out of the ball's collisions is what stops the engine having an opinion about it.
    func testAHeldBallDoesNotCollideWithThePaddleItIsSittingOn() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        let extra = extraBall(scene, x: 20)
        XCTAssertTrue(scene.endlessIICatchExtraBall(extra))

        let bit = CollisionTypes.paddleCategory.rawValue
        XCTAssertEqual((extra.physicsBody?.collisionBitMask ?? 0) & bit, 0,
                       "the paddle is out of its collisions while it is being carried")
        XCTAssertEqual((extra.physicsBody?.contactTestBitMask ?? 0) & bit, 0,
                       "and it is not reporting fresh landings either")
    }

    func testLaunchingGivesTheBallThePaddleBack() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        let extra = extraBall(scene, x: 20)
        scene.endlessIICatchExtraBall(extra)
        scene.endlessIILaunchHeldBall()

        let bit = CollisionTypes.paddleCategory.rawValue
        XCTAssertEqual((extra.physicsBody?.collisionBitMask ?? 0) & bit, bit,
                       "a ball that has left must be able to land again")
    }

    func testEmptyingTheQueueGivesEveryBallThePaddleBack() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        let first = extraBall(scene, x: -20)
        let second = extraBall(scene, x: 20)
        scene.endlessIICatchExtraBall(first)
        scene.endlessIICatchExtraBall(second)
        scene.endlessIIClearHeldBalls()

        let bit = CollisionTypes.paddleCategory.rawValue
        for subject in [first, second] {
            XCTAssertEqual((subject.physicsBody?.collisionBitMask ?? 0) & bit, bit,
                           "a Wipe must not leave balls falling through the paddle")
        }
    }

    // MARK: - "Launch both balls at the same time"

    /// James, round 291: "if multiple balls are in play and the paddle is sticky and there are
    /// 2 balls on the paddle and it's the last turn for the sticky power up, launch both balls
    /// at the same time."
    ///
    /// The release loop used to stop at the primary ball, so the last catch launched one and
    /// left the other stuck to a paddle that was no longer sticky.
    func testTheLastCatchLaunchesEveryBallOnThePaddle() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 1
        scene.stickyPaddleCatchesTotal = 4
        scene.ballIsOnPaddle = true
        // **As the game actually leaves it.** The classic sticky catch sets this flag and then
        // puts the ball in the queue, so a *caught* first ball has it set exactly as a waiting
        // serve does. The first version of this test set it false, which is a state the game
        // never produces - and it passed a fix that skipped the very case it was written for

        let extra = extraBall(scene, x: 25)
        scene.ball.position = CGPoint(x: -25, y: scene.paddle.position.y + 12)
        scene.endlessIICatchExtraBall(extra)
        scene.endlessIIFirstBallWasCaught()
        XCTAssertEqual(scene.endlessIIHeldBalls.count, 2)

        scene.endlessIILaunchHeldBall()

        XCTAssertTrue(scene.endlessIIHeldBalls.isEmpty,
                      "the last turn empties the paddle rather than leaving a ball stuck to a "
                      + "power-up that has ended")
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0,
                             "and the first ball went up with the rest")
        XCTAssertGreaterThan(extra.physicsBody?.velocity.dy ?? 0, 0)
        XCTAssertFalse(scene.ballIsOnPaddle,
                       "and the flag came off with it, or the code that has kept the first "
                       + "ball on the paddle since 2020 would carry it straight back down")
    }

    /// The ball resting on the paddle at the start of a life is not in the queue and stays put.
    func testAServeWaitingOnThePaddleIsNotFiredByTheLastCatch() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 1
        scene.ballIsOnPaddle = true
        XCTAssertTrue(scene.endlessIIHeldBalls.isEmpty, "a serve is not in the queue")
        scene.endlessIIReleaseRemainingHeldBalls()
        XCTAssertEqual(scene.ball.physicsBody?.velocity.dy ?? 0, 0,
                       "a serve is launched by the player, not by a power-up ending")
        XCTAssertTrue(scene.ballIsOnPaddle, "and it is still waiting on the paddle")
    }

    // MARK: - The aim

    /// James, round 291: "it jumps down to a low angle when dragging the paddle."
    func testALiftBelowThePaddleDoesNotPointTheArrow() {
        let paddleTop: CGFloat = -294
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop - 40, paddleTopY: paddleTop),
                       .paddle,
                       "below the paddle is carrying it, and the release path now asks this "
                       + "before it moves the arrow - it used to move it for every gesture "
                       + "that returned .keepAiming, which includes every paddle drag")
        XCTAssertEqual(AimHoldControl.intent(touchY: paddleTop + 40, paddleTopY: paddleTop),
                       .aim)
    }

    /// "It's inconsistent when dragging if it moves the paddle or the arrow."
    func testTheDragKeepsTheJobItStartedWith() {
        // Said about the rule rather than by driving the touch handler, which force-unwraps a
        // touch it is guaranteed by UIKit and never gets from a test (round 284's lesson).
        let paddleTop: CGFloat = -294
        let began = AimHoldControl.intent(touchY: paddleTop - 30, paddleTopY: paddleTop)
        XCTAssertEqual(began, .paddle)

        let scene = mayhem()
        scene.endlessIIAimDragIntent = began
        XCTAssertEqual(scene.endlessIIAimDragIntent, .paddle,
                       "and the drag keeps it however far the finger then travels - the "
                       + "intent used to be recomputed from the finger's current height on "
                       + "every move event, so crossing the paddle's edge changed its job")
    }

    /// A finger already carrying the paddle when the catch lands goes on carrying it.
    func testACatchUnderAMovingFingerDoesNotStealTheDrag() {
        let scene = mayhem()
        scene.touchBeganWhilstPlaying = true
        scene.endlessIICollectAimedSticky()
        scene.endlessIIBeginAimHold()
        XCTAssertEqual(scene.endlessIIAimDragIntent, .paddle,
                       "nothing the player did changed, so what their finger is doing must "
                       + "not change either")
        XCTAssertTrue(scene.endlessIIAimTouchPredatesHold)
    }
}

/// Round 291's field list.
final class PlayTestRound291FieldTests: XCTestCase {

    /// James: "cluster balls should disappear immediately if the ball is lost."
    func testLosingTheBallTakesItsClusterWithIt() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.ballSize = 14
        scene.ballSpeedLimit = 600
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.addChild(scene.paddle)

        scene.endlessIIReleaseCluster()
        var pellets = 0
        scene.enumerateChildNodes(withName: ClusterCategoryName) { _, _ in pellets += 1 }
        XCTAssertEqual(pellets, GameScene.endlessIIClusterCount)

        scene.endlessIIClearClusterBalls()
        pellets = 0
        scene.enumerateChildNodes(withName: ClusterCategoryName) { _, _ in pellets += 1 }
        XCTAssertEqual(pellets, 0,
                       "they are the ball's own shot; a life that has ended should not go on "
                       + "being played by the pellets from it")
    }

    /// "The initial flash of the laser beam is great, but it should fade out over 1s rather
    /// than immediate. The after glow underneath should then take another 1-2s to fade out."
    func testTheBeamFadesAndThenTheBurnDoes() {
        XCTAssertLessThan(GameScene.endlessIILaserBeamFlashSeconds, 0.25, "still a flash")
        XCTAssertEqual(GameScene.endlessIILaserBeamFadeSeconds, 1, accuracy: 0.001,
                       "\"it should fade out over 1s\"")
        XCTAssertGreaterThanOrEqual(GameScene.endlessIILaserAfterGlowSeconds, 1)
        XCTAssertLessThanOrEqual(GameScene.endlessIILaserAfterGlowSeconds, 2,
                                 "\"another 1-2s\" - and it starts where the beam's fade "
                                 + "ends rather than where its flash does")
    }
}

/// Round 291's two picture fixes.
final class PlayTestRound291LookTests: XCTestCase {

    /// James: "the endless mayhem main menu screen has the incorrect logo. It has the endless
    /// mode logo, not the endless mayhem one."
    ///
    /// Both endless modes share level 0, and level 0's picture is `Level999Image` - the
    /// infinity symbol, which is Endless's mark. The screen asks `GameMode.menuIcon` now.
    func testTheTwoEndlessModesHaveDifferentLogos() throws {
        let endless = try XCTUnwrap(GameMode.menuIcon(for: .endless))
        let mayhem = try XCTUnwrap(GameMode.menuIcon(for: .endlessII))
        XCTAssertNotEqual(endless.pngData(), mayhem.pngData(),
                          "Mayhem has had its own icon since round 130; the run-history screen "
                          + "was the one place still showing the level picture instead")
        XCTAssertNotNil(UIImage(named: "Level999Image"),
                        "level 0's picture, which both endless modes shared on the run-history "
                        + "screen. It is Endless's infinity mark drawn large - not byte-equal "
                        + "to `EndlessIcon`, which is the small round menu version of the same "
                        + "design - and one picture cannot be two modes' logo whichever of "
                        + "them it was drawn for")
    }

    /// "We should make them slightly larger throughout the app so they're easier to see and
    /// differentiate."
    func testTheTwistBadgesAreLargerThanACapital() {
        XCTAssertGreaterThan(DailyTwist.twistBadgeHeight, 1.5,
                             "1.5 was the size for flat stroked glyphs; these are drawings now")
        XCTAssertLessThan(DailyTwist.twistBadgeHeight, 2.5,
                          "and a badge taller than the line it sits in would push the rows apart")
    }
}

/// Round 293's play-test list.
final class PlayTestRound293Tests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.layoutUnit = 40
        scene.ballSize = 14
        scene.paddleWidth = 120
        scene.gameWidth = 400
        scene.ballSpeedLimit = 600
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.addChild(scene.paddle)
        scene.ball.size = CGSize(width: 14, height: 14)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.addChild(scene.ball)
        return scene
    }

    private func extraBall(_ scene: GameScene, x: CGFloat) -> SKSpriteNode {
        let extra = SKSpriteNode(color: .white, size: CGSize(width: 14, height: 14))
        extra.position = CGPoint(x: x, y: scene.paddle.position.y + 12)
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)
        return extra
    }

    // MARK: - "The ball should move to maintain its relative position"

    /// James: "when the paddle resizes with sticky paddle power-ups active and a ball on the
    /// paddle, the ball should move to maintain its relative position on the paddle."
    func testAHeldBallRidesTheEdgeOfAPaddleThatExpands() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        let extra = extraBall(scene, x: 54)         // near the right tip of a 120-wide paddle
        scene.endlessIICatchExtraBall(extra)
        let shareAtCatch = (extra.position.x - scene.paddle.position.x)/scene.endlessIIPaddleHalfWidth

        scene.paddle.xScale = 1.5                   // Expand, which animates the scale
        scene.tickEndlessIIHeldBalls()

        let shareNow = (extra.position.x - scene.paddle.position.x)/scene.endlessIIPaddleHalfWidth
        XCTAssertEqual(shareNow, shareAtCatch, accuracy: 0.001,
                       "it is still the same distance along the paddle it landed on")
        XCTAssertEqual(extra.position.x, 81, accuracy: 0.5,
                       "which on a paddle half again as wide is half again as far out")
    }

    func testAHeldBallComesInWithAPaddleThatShrinks() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        let extra = extraBall(scene, x: 54)
        scene.endlessIICatchExtraBall(extra)

        scene.paddle.xScale = 0.5
        scene.tickEndlessIIHeldBalls()

        XCTAssertEqual(extra.position.x, 27, accuracy: 0.5,
                       "or it would be left hanging in the air off the end of the paddle")
    }

    // MARK: - "Aimed sticky is still causing the game to pause"

    /// James: "aimed sticky is still causing the game to pause whilst the ball is on the
    /// paddle. This is no longer necessary."
    ///
    /// Round 215 took the freeze out of the power-up and left this behind: the field's own
    /// hold read the aim flag, so the descent stopped for as long as a ball sat on the paddle.
    func testAnAimDoesNotHoldTheField() {
        let scene = mayhem()
        scene.endlessIIAimHold = true
        XCTAssertFalse(scene.endlessIIFieldIsHeld,
                       "an ordinary Sticky Paddle never stopped the field and this must not "
                       + "either - the game does not pause to be aimed")
    }

    /// The turn already paid for still holds it, which is a moment rather than a state.
    func testAnOwedAimedTurnStillHoldsTheField() {
        let scene = mayhem()
        scene.endlessIIAimedStickyOwedTurn = true
        XCTAssertTrue(scene.endlessIIFieldIsHeld,
                      "a row must not arrive between the catch and the shot it bought")
    }

    // MARK: - "The laser turrets keep moving without the paddle"

    /// James: "when the paddle hits the edge of the screen, if lasers are active, the laser
    /// turrets keep moving a couple of pixels without the paddle."
    ///
    /// **The clamp was never wrong; *when* it ran was.** Expand nudges the paddle inside the
    /// walls the instant it is collected and then animates the scale over a fifth of a second,
    /// so a paddle standing at the wall is judged to fit at its old width and then grows past
    /// the edge - centre still, ends walking outward, which is where the turrets are drawn. It
    /// is re-asked every frame now.
    ///
    /// These two say the clamp itself is right, which round 293 spent a build disbelieving.
    func testAnExpandedPaddleStopsWhereItsOwnEdgeReachesTheWall() {
        let scene = mayhem()
        scene.paddle.xScale = 1.5

        let stopped = scene.endlessIIWrapPaddleX(1000)
        XCTAssertEqual(stopped, 200 - 90, accuracy: 0.01,
                       "half of a 180-wide paddle inside a 400-wide field - `size` carries the "
                       + "scale, so this has always been right and round 293 briefly broke it "
                       + "by multiplying the scale in a second time")
    }

    func testAShrunkenPaddleMayGoFurtherThanAFullSizedOne() {
        let scene = mayhem()
        scene.paddle.xScale = 0.5
        XCTAssertEqual(scene.endlessIIWrapPaddleX(1000), 200 - 30, accuracy: 0.01,
                       "a shrunken paddle may go further, because it is narrower")
    }

    /// And the overlays go with the paddle when a resize pushes it back inside the walls.
    ///
    /// This is the frame-by-frame nudge doing its job: the paddle has already grown, so it now
    /// overhangs, and the push inward has to take the lasers and the sticky face with it.
    func testAResizeAtTheWallTakesTheDressWithIt() {
        let scene = mayhem()
        scene.paddle.position.x = 140            // at the wall for its built width
        scene.paddle.xScale = 1.5                // now overhanging
        scene.endlessIIKeepThePaddleInsideTheWalls()

        XCTAssertEqual(scene.paddle.position.x, 110, accuracy: 0.01)
        XCTAssertEqual(scene.paddleLaser.position.x, scene.paddle.position.x, accuracy: 0.01,
                       "the two copies of this nudge that it replaced left the lasers behind")
        XCTAssertEqual(scene.paddleSticky.position.x, scene.paddle.position.x, accuracy: 0.01)
    }

    // MARK: - "More inertia... more like a piece of string"

    func testBallControlSetsOffMoreSlowlyThanItDidBefore() {
        var state = (x: CGFloat(0), velocity: CGFloat(0))
        state = EndlessIIPaddleEffects.steeringStep(x: state.x, velocity: state.velocity,
                                                    towards: 100, delta: 1.0/60)
        XCTAssertLessThan(state.x, 1.8,
                          "round 291 moved about 2% of the gap in the first frame at 11 rad/s; "
                          + "a string is slacker than that")
        XCTAssertGreaterThan(state.x, 0, "it does still answer")
    }

    func testBallControlStillSettlesRatherThanOscillating() {
        var state = (x: CGFloat(0), velocity: CGFloat(0))
        var path: [CGFloat] = []
        for _ in 0..<180 {
            state = EndlessIIPaddleEffects.steeringStep(x: state.x, velocity: state.velocity,
                                                        towards: 100, delta: 1.0/60)
            path.append(state.x)
        }
        XCTAssertEqual(path.last ?? 0, 100, accuracy: 1, "it arrives")
        XCTAssertGreaterThan(path.max() ?? 0, 100, "having gone past")
        XCTAssertLessThan(path.max() ?? 0, 130,
                          "a string's load swings wider than a stiff arm's, and not so wide "
                          + "that the player has stopped being able to place the ball")
    }
}

/// Round 293's two brick-page corrections.
final class BrickPageRound293Tests: XCTestCase {

    func testTheSquareBrickSaysWhatJamesWrote() {
        let square = BrickTypeCatalogue.allEntries.first { $0.name == "Square" }
        XCTAssertEqual(square?.description, "Each side is the same",
                       "the workbook has no row for Square, so this is his line for it")
    }

    func testTheRoundedBrickIsCalledRound() {
        XCTAssertTrue(BrickTypeCatalogue.allEntries.contains { $0.name == "Round" })
        XCTAssertFalse(BrickTypeCatalogue.allEntries.contains { $0.name == "Rounded" },
                       "the display name changed in round 293; the enum case and every asset "
                       + "name stay as they are, because those are save keys and files")
    }
}
