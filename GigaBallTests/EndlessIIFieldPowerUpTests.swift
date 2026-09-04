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
        scene.ball.size = CGSize(width: 10, height: 10)
        // Both, as the game itself does - `setUpGame` writes `ballSize` and then sizes the
        // sprite from it. Since round 284 the Aura reads its reach off the *sprite*, so that it
        // grows when Increase Ball Size scales the ball, and a scene that set only the number
        // gave the glow a reach of nothing
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

    /// **Nothing is cleared** (James, round 215: "the bottom 2 rows of bricks should remain in
    /// play, they just move up along with everything else. It looked like they were
    /// 'cleared'. This power up should really just be called retreat as there is no
    /// clearing").
    ///
    /// These three used to assert the opposite - that the lowest two occupied rows were
    /// destroyed, that "lowest level" meant levels rather than row heights, and that a row
    /// meant the whole row rather than one brick. That was round 136's reading of the power-up
    /// and it is now the wrong one, so what they pin is inverted rather than deleted: the same
    /// three fields, and every brick still standing afterwards.
    func testNoBrickIsDestroyedByARetreat() {
        let scene = fieldScene()
        let low = brick(in: scene, x: 0, y: 40)
        let next = brick(in: scene, x: 0, y: 40 + scene.brickHeight)
        let high = brick(in: scene, x: 0, y: 40 + scene.brickHeight*4)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNotNil(low.parent, "the lowest row stays in play")
        XCTAssertNotNil(next.parent, "and the one above it")
        XCTAssertNotNil(high.parent)
    }

    func testAGapBetweenOccupiedRowsCostsNothingEither() {
        let scene = fieldScene()
        let low = brick(in: scene, x: 0, y: 40)
        let next = brick(in: scene, x: 0, y: 40 + scene.brickHeight*5)
        let high = brick(in: scene, x: 0, y: 40 + scene.brickHeight*9)

        scene.endlessIICollectClearAndRetreat()
        for standing in [low, next, high] { XCTAssertNotNil(standing.parent) }
    }

    func testTwoBricksOnOneRowBothStay() {
        let scene = fieldScene()
        let left = brick(in: scene, x: -50, y: 40)
        let right = brick(in: scene, x: 50, y: 44)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertNotNil(left.parent)
        XCTAssertNotNil(right.parent)
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

    /// James, round 172: "Descent power up moves the bricks down too fast and at a variable
    /// rate. It should be a slow and steady rate for a fixed period of time."
    ///
    /// The variable rate was the countdown being zeroed the moment it came due, *before* the
    /// guards - so a step that could not be taken because the last one was still animating, or
    /// because an aim was holding the field, threw its whole interval away and the next step
    /// arrived an interval late.
    func testAHeldStepDoesNotThrowAwayItsInterval() {
        let scene = fieldScene()
        scene.endlessIICollectDescent()
        scene.endlessMoveInProgress = true

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 0, "nothing steps while one is animating")

        scene.endlessMoveInProgress = false
        scene.endlessIIPaddleFrameDelta = 0
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 1,
                       "and the interval it waited is still owed to it, so the step lands "
                       + "at once rather than a whole interval later")
    }

    func testTheRemainderIsCarriedRatherThanDiscarded() {
        // A long frame leaves the remainder behind, so the rate stays the rate
        let scene = fieldScene()
        scene.endlessIICollectDescent()

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep*1.5
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 1)

        scene.endlessMoveInProgress = false
        // The step just taken is animating, and one animating step blocks the next - which is
        // the rule above. What is being asked here is only what the countdown kept
        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep*0.5
        scene.tickEndlessIIDescent()
        XCTAssertEqual(scene.endlessHeight, 2, "the half it carried completes the next step")
    }

    func testDescentIsSlowEnoughToWatch() {
        // A row a second, against the 0.55 it ran at - which read as the field falling
        XCTAssertGreaterThanOrEqual(GameScene.endlessIIDescentStep, 0.9)
        XCTAssertGreaterThan(GameScene.endlessIIDescentRows, 4,
                             "still the biggest single source of height in the mode")
        XCTAssertLessThan(GameScene.endlessIIDescentRows, 9,
                          "and not the run being handed to you (round 51)")
    }

    /// James's suggestion, round 52: measure the descent in rows rather than seconds - "a
    /// fixed number of rows is what the player actually experiences, where seconds are what
    /// the code happens to count."
    func testADescentIsWorthExactlyItsRowsHoweverLongTheyTake() {
        let scene = fieldScene()
        scene.endlessIICollectDescent()

        var steps = 0
        for _ in 0..<GameScene.endlessIIDescentRows*3 {
            scene.endlessMoveInProgress = false
            // Each animated step would otherwise block the next - the loop stands in for
            // the animations finishing, however long each took
            scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep
            scene.tickEndlessIIDescent()
            if scene.endlessHeight > steps { steps = scene.endlessHeight }
        }

        XCTAssertEqual(steps, GameScene.endlessIIDescentRows,
                       "six rows, not six seconds' worth of whatever the field allowed")
        XCTAssertFalse(scene.endlessIIDescentClock.isRunning, "and spent means over")
    }

    func testAHoldSpendsNoRows() {
        // The whole reason rows are the better unit: a held field used to eat the clock
        // without yielding anything
        let scene = fieldScene()
        scene.endlessIICollectDescent()
        let budget = scene.endlessIIDescentClock.remaining

        scene.endlessMoveInProgress = true
        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep*4
        scene.tickEndlessIIDescent()

        XCTAssertEqual(scene.endlessIIDescentClock.remaining, budget, accuracy: 0.001,
                       "no row taken, no row spent")
    }

    func testALockedDescentNeitherStepsNorSpends() {
        // A Lock freezes the timed power-ups, and for a clock that counts rows the freeze
        // is the cadence stopping. The raw frame delta used to leak through here - a locked
        // Descent kept stepping while its clock stood still, free rows for the freeze
        let scene = fieldScene()
        scene.endlessIICollectDescent()
        scene.endlessIILockClock.collect(10)

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep*2
        scene.tickEndlessIIDescent()

        XCTAssertEqual(scene.endlessHeight, 0)
        XCTAssertEqual(scene.endlessIIDescentClock.remaining,
                       TimeInterval(GameScene.endlessIIDescentRows), accuracy: 0.001)
    }

    func testDescentsRingIsSegmentedIntoRows() {
        // Six marks say "six rows"; a smooth arc only says "about half a Descent"
        let scene = fieldScene()
        scene.endlessIICollectDescent()
        let entry = scene.endlessIIFieldRingEntries().first { $0.id == "endlessIIDescent" }
        XCTAssertEqual(entry?.segments, GameScene.endlessIIDescentRows)
    }

    func testARestoredDescentStillCountsRows() {
        // The flag is not in the save; the restore path sets it the way collect(turns:) does
        let scene = fieldScene()
        scene.endlessIIRestoreFieldClock(key: "endlessIIDescent", remaining: 3, total: 6,
                                         magnitude: 0)
        XCTAssertTrue(scene.endlessIIDescentClock.countsTurns)
        XCTAssertTrue(scene.endlessIIDescentClock
                        .outlastsALockDrop(lead: GameScene.endlessIILockLead))
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

    /// A Portal is never a target. An **invisible brick is**, since round 299.
    ///
    /// James: "auto aim should be able to aim at invisible bricks even if they are not
    /// visible." `isHidden` means one thing on a brick in this game - an Invisible brick that
    /// has not been struck - and it is solid, it scores, and it is precisely the brick a free
    /// shot is most use against, because it is the one the player cannot aim at themselves.
    ///
    /// This test asserted the opposite until that round, which is why it is rewritten rather
    /// than deleted: the Portal half of it was and is correct, and the hidden half was a
    /// decision that has been reversed rather than a rule that was broken.
    func testAutoAimIgnoresPortalsAndTakesInvisibleBricks() {
        let scene = fieldScene()
        brick(in: scene, x: 20, y: 40, role: .portal)
        let higher = brick(in: scene, x: -60, y: 90)

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, higher.position.x,
                       "a Portal is struck rather than destroyed, so aiming at one spends the "
                       + "free shot on nothing")

        let hidden = brick(in: scene, x: 0, y: 50)
        hidden.isHidden = true
        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero)?.x, hidden.position.x,
                       "and the invisible brick below it is now the better target, because it "
                       + "is lower and it is a brick")
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

    /// James, round 207: "sticky paddle overrides auto aim, so the ball doesn't hit the aimed
    /// brick. This is wrong. The ball should hit the aimed brick."
    ///
    /// The turn is spent on the contact, before the paddle decides whether to bounce or catch.
    /// A catch then returned before the aim was ever asked, so the turn was paid and thrown
    /// away and the ball left at the plain angle for where it was sitting.
    func testAStickyCatchDeliversTheAutoAimTurnItPaidFor() {
        let scene = fieldScene()
        scene.ballSpeedLimit = 100
        let target = brick(in: scene, x: 60, y: 120)
        scene.ball.position = .zero
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAutoAim()

        scene.endlessIISpendPaddleTurns()
        // The contact. The catch happens here and no bounce angle is chosen - the ball is
        // simply held, which is what made the turn disappear

        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 100)
        // The plain launch the release computes from where the ball sits on the paddle
        scene.endlessIIAimTheStickyLaunch(scene.ball)

        let leave = scene.ball.physicsBody!.velocity
        let heading = atan2(Double(leave.dy), Double(leave.dx))
        let wanted = atan2(Double(target.position.y - scene.ball.position.y),
                           Double(target.position.x - scene.ball.position.x))
        XCTAssertEqual(heading, wanted, accuracy: 0.001,
                       "the held ball still leaves at the angle it was sitting at")
    }

    /// And it is the *turn* that buys the aim, not the clock merely running: the first launch
    /// of a life follows no paddle contact, spends nothing, and so takes the shot the player
    /// aimed by placing the paddle - the same answer an ordinary bounce gives.
    func testALaunchThatPaidNoTurnIsLeftAlone() {
        let scene = fieldScene()
        scene.ballSpeedLimit = 100
        brick(in: scene, x: 60, y: 120)
        scene.ball.position = .zero
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAutoAim()
        // Running, but no contact has been made - nothing is owed

        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 100)
        scene.endlessIIAimTheStickyLaunch(scene.ball)

        XCTAssertEqual(scene.ball.physicsBody!.velocity.dx, 0, accuracy: 0.001)
        XCTAssertEqual(scene.ball.physicsBody!.velocity.dy, 100, accuracy: 0.001)
    }

    /// The turn is delivered once. A second release in the same breath - a Multi-Ball queue
    /// emptying on consecutive taps - must not keep aiming off one paid contact.
    func testTheOwedAimIsSpentByTheLaunchThatTakesIt() {
        let scene = fieldScene()
        scene.ballSpeedLimit = 100
        brick(in: scene, x: 60, y: 120)
        scene.ball.position = .zero
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.endlessIICollectAutoAim()
        scene.endlessIISpendPaddleTurns()

        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 100)
        scene.endlessIIAimTheStickyLaunch(scene.ball)
        XCTAssertFalse(scene.endlessIIAutoAimOwedTurn, "the turn was delivered")

        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 100)
        scene.endlessIIAimTheStickyLaunch(scene.ball)
        XCTAssertEqual(scene.ball.physicsBody!.velocity.dx, 0, accuracy: 0.001,
                       "a second release off one paid contact takes no aim")
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

    /// **The per-frame clamp must not undo the wrap.**
    ///
    /// James, round 300: "the wrap around power up isn't letting the paddle wrap around any
    /// more." Round 293 added `endlessIIKeepThePaddleInsideTheWalls` and ran it every frame to
    /// chase a laser turret, and it carried its own copy of the clamp - so from that round on,
    /// a paddle driven off the edge was hauled back inside the walls before it could ever
    /// reach the other one. The power-up existed and did nothing.
    ///
    /// This is the frame-loop test rather than the pure-function one above: the rule was
    /// always right, and a second writer was overruling it.
    func testTheEveryFrameClampLeavesAWrappingPaddleAlone() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)

        scene.paddle.position.x = 500
        scene.endlessIIKeepThePaddleInsideTheWalls()
        XCTAssertEqual(scene.paddle.position.x, 150, accuracy: 0.01,
                       "without the wrap it still clamps at the wall, which is round 293's job")

        scene.endlessIICollectWrapAround()

        scene.paddle.position.x = 190
        scene.endlessIIKeepThePaddleInsideTheWalls()
        XCTAssertEqual(scene.paddle.position.x, 190, accuracy: 0.01,
                       "a paddle overhanging the edge is left overhanging")

        scene.paddle.position.x = 210
        scene.endlessIIKeepThePaddleInsideTheWalls()
        XCTAssertEqual(scene.paddle.position.x, -190, accuracy: 0.01,
                       "and one driven past it comes back in from the other side")
    }

    /// **The clamp runs after the growth it is chasing.**
    ///
    /// James, round 300: "laser turrets are still moving away from the paddle a pixel or two
    /// when the paddle is dragged against the edge" - the same sentence as round 293, which
    /// moved the clamp into `update` and did not fix it, because SpriteKit evaluates actions
    /// *after* `update` returns. Expand animates `xScale` over 0.2s, so a clamp in `update`
    /// answers for the paddle as it was one frame ago and the paddle grows out from under it.
    ///
    /// The test is the override's existence and its behaviour: a paddle whose width has just
    /// grown is inside the walls, with its overlays moved to match, by the time this hook has
    /// run.
    func testTheWallClampRunsInDidEvaluateActions() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)
        scene.paddle.position.x = 150
        // Hard against the wall at its old width

        scene.paddle.size = CGSize(width: 200, height: 20)
        // What the Expand action will have done by the time actions have been evaluated

        scene.didEvaluateActions()

        XCTAssertEqual(scene.paddle.position.x, 100, accuracy: 0.01,
                       "the grown paddle is pulled back so its end sits on the wall")
        XCTAssertEqual(scene.paddleLaser.position.x, scene.paddle.position.x, accuracy: 0.01,
                       "and the turrets came with it, rather than a frame later")
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

    /// James, round 177: "Wrap around power-up, the ball is still hitting the wall a lot
    /// rather than wrapping around. It seems to wrap around the first time, but then reverts
    /// to hitting the wall. The paddle seems to have no problems."
    ///
    /// One wall hit can be reported as more than one contact, and each note used to be its
    /// own teleport - two of them are a round trip that lands the ball back on the wall it
    /// struck, wearing the engine's bounce. The paddle never suffered because its wrap is a
    /// position rule with no contact in it.
    func testOneWallHitWrapsOnceHoweverOftenTheEngineMentionsIt() {
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.ball.position = CGPoint(x: 195, y: 0)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 80, dy: 50))
        scene.endlessIICollectWrapAround()

        XCTAssertTrue(scene.endlessIIWrapTook(scene.ball))
        XCTAssertTrue(scene.endlessIIWrapTook(scene.ball))
        XCTAssertTrue(scene.endlessIIWrapTook(scene.ball))
        scene.applyEndlessIIWraps()

        XCTAssertLessThan(scene.ball.position.x, 0,
                          "wrapped once - not shuttled back to the wall it struck")
    }

    func testALateContactNoteDoesNotWrapABallTravellingAwayFromItsWall() {
        // The other way a duplicate arrives: a frame late, after the teleport. The ball is
        // then beside the far wall heading away from it, and that ball is mid-flight - not
        // leaving the field
        let scene = fieldScene()
        scene.gameWidth = 400
        scene.ball.position = CGPoint(x: -194, y: 0)
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.ball.physicsBody?.velocity = CGVector(dx: 80, dy: 50)
        scene.ballStateBeforeStep[ObjectIdentifier(scene.ball)] =
            BallState(position: scene.ball.position, velocity: CGVector(dx: 80, dy: 50))
        // Just in from the left wall, travelling right - exactly where a wrap leaves a ball

        scene.endlessIICollectWrapAround()
        XCTAssertTrue(scene.endlessIIWrapTook(scene.ball))
        scene.applyEndlessIIWraps()

        XCTAssertLessThan(scene.ball.position.x, 0, "left where it was, mid-flight")
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
        // A tenth of the *room* the bounce has, which at 90° with a 10° minimum is 80° of it
        XCTAssertEqual(GameScene.randomisedBounceAngle(from: 90, minimumDeg: 10, share: 0.1),
                       98, accuracy: 0.001)
        XCTAssertEqual(GameScene.randomisedBounceAngle(from: 90, minimumDeg: 10, share: -0.1),
                       82, accuracy: 0.001)
    }

    // MARK: - The one the tests never asked

    /// **A ball travelling down still travels down.**
    ///
    /// James, round 258: "Random bounce power up is still broken." It was, and in the one way
    /// nothing here had ever asked about: `atan2` reports -180...180 and the arithmetic was
    /// written for 0...180, so clamping a ball descending at -45° to "at least the minimum"
    /// returned **+10** - a fair descent slammed into a shallow climb, at every brick contact,
    /// for the whole ten seconds.
    ///
    /// And +10 is `minAngleDeg` exactly, which is the escape hatch's own trigger, so the
    /// shallow climb was then re-aimed with a random jitter frame after frame. That is the
    /// vibrating James reported in round 185, and it survived two rounds of narrowing the
    /// spread because **every test written for it passed an upward angle**.
    func testADescendingBallIsStillDescendingAfterwards() {
        for arriving in [-15.0, -45.0, -90.0, -135.0, -168.0] {
            for share in stride(from: -0.10, through: 0.10, by: 0.02) {
                let bounced = GameScene.randomisedBounceAngle(from: arriving, minimumDeg: 10,
                                                              share: share)
                XCTAssertLessThan(bounced, 0,
                                  "\(arriving)° thrown by \(share) came back climbing")
                XCTAssertGreaterThanOrEqual(bounced, -170)
                XCTAssertLessThanOrEqual(bounced, -10)
            }
        }
    }

    /// Down and up are thrown off by the same amount, because they are the same bounce.
    func testTheSameBounceUpOrDownIsThrownTheSameWay() {
        for magnitude in [15.0, 45.0, 90.0, 135.0, 168.0] {
            let up = GameScene.randomisedBounceAngle(from: magnitude, minimumDeg: 10, share: 0.1)
            let down = GameScene.randomisedBounceAngle(from: -magnitude, minimumDeg: 10,
                                                       share: 0.1)
            XCTAssertEqual(up, -down, accuracy: 0.001, "\(magnitude)°")
        }
    }

    /// A shallow bounce to the left is as gently nudged as a shallow one to the right.
    ///
    /// The old form was proportional to the heading rather than to its distance from
    /// horizontal, so 170° - a ball skimming leftward - was treated as seventeen times the
    /// bounce that 10° is, when they are the same ball going opposite ways.
    func testShallowIsShallowWhicheverWayTheBallIsGoing() {
        let right = GameScene.randomisedBounceAngle(from: 20, minimumDeg: 10, share: 0.1)
        let left = GameScene.randomisedBounceAngle(from: 160, minimumDeg: 10, share: 0.1)
        XCTAssertEqual(abs(right - 20), abs(left - 160), accuracy: 0.001,
                       "the same distance from horizontal is the same size of nudge")

        let steepRight = GameScene.randomisedBounceAngle(from: 70, minimumDeg: 10, share: 0.1)
        let steepLeft = GameScene.randomisedBounceAngle(from: 110, minimumDeg: 10, share: 0.1)
        XCTAssertEqual(abs(steepRight - 70), abs(steepLeft - 110), accuracy: 0.001)

        // The *size* rather than the direction: one share steepens a rightward bounce and
        // shallows a leftward one, because the nudge is added to a heading measured from the
        // right-hand horizontal. It does not matter, because the roll is symmetric - what
        // would matter, and is what this pins, is one side being nudged harder than the other
    }

    /// A bounce with no room to be thrown is handed back untouched.
    ///
    /// The escape hatch in `ballHorizontalControl` owns the ones at or under the minimum, and
    /// two things rescuing one bounce is the other half of what the vibrating was.
    func testABounceWithNoRoomIsLeftExactlyAsItArrived() {
        for arriving in [10.0, 8.0, -10.0, 172.0, -175.0] {
            XCTAssertEqual(GameScene.randomisedBounceAngle(from: arriving, minimumDeg: 10,
                                                           share: 0.1),
                           arriving, accuracy: 0.0001, "\(arriving)°")
        }
    }

    /// James, round 185: "randomised bounce is way too erratic... the ball seems to go crazy,
    /// vibrating and glitching constantly. Perhaps the bounce angle adjustment should be much
    /// narrower, like +/- 10% of the actual bounce angle."
    ///
    /// Degrees were the wrong unit, which is why narrowing them twice did not help. A fixed
    /// ±25° is nothing to a bounce leaving at 90° and everything to one leaving at 15° - it
    /// threw the shallow ones below the minimum the game allows, where `breakHorizontalRuns`
    /// caught them and fired its own jittering escape every frame.
    func testAShallowBounceIsNudgedGentlyAndASteepOneMore() {
        let shallow = GameScene.randomisedBounceAngle(from: 15, minimumDeg: 10, share: 0.1)
        let steep = GameScene.randomisedBounceAngle(from: 120, minimumDeg: 10, share: 0.1)

        XCTAssertEqual(shallow - 15, 0.5, accuracy: 0.001, "a shallow nudge for a shallow bounce")
        XCTAssertEqual(steep - 120, 5, accuracy: 0.001)
        // A tenth of the room each has: five degrees above the minimum for the shallow one,
        // fifty for the steep. Round 258 changed the basis from the heading to the room, which
        // is what makes 15° and 165° the same bounce
    }

    func testItNeverThrowsAShallowBounceIntoTheEscapeHatch() {
        // The vibrating itself: a bounce pushed under `minAngleDeg` is caught by
        // `breakHorizontalRuns`, which re-aims it with its own random jitter, every frame
        let minimum = 10.0
        for arriving in stride(from: 11.0, through: 40.0, by: 1) {
            for share in stride(from: -0.10, through: 0.10, by: 0.02) {
                let bounced = GameScene.randomisedBounceAngle(from: arriving,
                                                              minimumDeg: minimum, share: share)
                XCTAssertGreaterThanOrEqual(bounced, minimum,
                                            "\(arriving)° thrown by \(share)")
            }
        }
    }

    /// A bad power-up may be unfair. It may not hand the player a ball that never comes down,
    /// which is the one heading the game refuses in every other place it touches an angle.
    func testItNeverThrowsTheBallPastTheAngleTheGameRefuses() {
        for share in stride(from: -0.6, through: 0.6, by: 0.05) {
            for arriving in [12.0, 45.0, 90.0, 135.0, 168.0] {
                let bounced = GameScene.randomisedBounceAngle(from: arriving, minimumDeg: 10,
                                                              share: share)
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
        scene.endlessIICollectDrift(direction: 1)
        let before = brick.position.x

        scene.tickEndlessIIDrift(0.5)
        XCTAssertNotEqual(brick.position.x, before, accuracy: 0.0001)
        XCTAssertEqual(brick.position.y, 40, "sideways only - a brick's y is its row (§8.6)")
    }

    /// Round 201: two Drifts, one per direction, sharing a clock.
    ///
    /// Driven in frame-sized ticks rather than one long one, because round 209 made the field
    /// move a **column at a time**: a step covers exactly one cell and then waits, so a single
    /// two-second tick asks for a distance the power-up will no longer travel in one go. That
    /// is the change, not a regression - and driving it the way `update` does is what the test
    /// should have been doing anyway.
    private func driftFor(_ seconds: TimeInterval, in scene: GameScene) {
        let frame = 1.0/60
        for _ in 0..<Int(seconds/frame) { scene.tickEndlessIIDrift(frame) }
    }

    /// Each Drift slides its own way, and the other one ends it.
    ///
    /// **Inverted in round 223.** It used to reverse the slide and extend the clock, on round
    /// 201's reading that a player holding both had been handed a dial rather than two coats
    /// of the same paint. James's interaction matrix answers the pair differently - "cancels
    /// out" - which makes them each other's opposite the way Expand and Shrink are, and those
    /// have cancelled since 2020.
    func testEachDriftSlidesItsOwnWayAndTheOtherOneCancelsIt() {
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 200)

        scene.endlessIICollectDrift(direction: -1)
        driftFor(1.0, in: scene)
        XCTAssertLessThan(brick.position.x, 0, "Drift Left slides the field leftward")
        let slid = brick.position.x

        scene.endlessIICollectDrift(direction: 1)
        XCTAssertFalse(scene.endlessIIDriftClock.isRunning, "the two did not cancel")

        driftFor(5.0, in: scene)
        XCTAssertGreaterThanOrEqual(brick.position.x, slid,
                                    "a cancelled drift went on sliding leftward")
        XCTAssertLessThanOrEqual(brick.position.x, 0,
                                 "cancelling turned the field around instead of stopping it")
    }

    /// The point of the change: between steps the field is exactly on its columns, where the
    /// generator, the crush and the neighbour rules all expect to find it.
    ///
    /// Started *on* a column centre, because that is the claim - a step moves the field by
    /// exactly one cell, so a field that was on the grid is still on it. The first draft of
    /// this test put the brick at x = 0, which is a column *edge* on a field with an even
    /// number of columns, and then asked why the brick was not on a centre: it had never been
    /// on one, and the drift had faithfully preserved the offset it was given.
    func testTheFieldRestsOnAColumnCentreBetweenSteps() {
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 200)
        brick.position.x = scene.endlessIIColumnCentre(nearest: 0)
        let started = brick.position.x
        scene.endlessIICollectDrift(direction: 1)

        driftFor(2.0, in: scene)
        // A full column covered, and the rest of the interval spent still
        XCTAssertEqual(brick.position.x, scene.endlessIIColumnCentre(nearest: brick.position.x),
                       accuracy: 0.001, "a step lands on a column and waits there")
        XCTAssertEqual(brick.position.x - started, scene.brickWidth, accuracy: 0.001,
                       "exactly one cell, not a fraction of one and not two")
    }

    func testItGoesRoundTheSideRatherThanLosingTheField() {
        // A power-up that quietly destroyed the bricks that reached the edge would be a
        // different power-up, so a brick that runs out of field comes back at the other side
        let scene = driftScene()
        let brick = brick(in: scene, x: scene.gameWidth/2 - scene.brickWidth/2, y: 40)
        scene.endlessIICollectDrift(direction: 1)
        scene.endlessIIDriftDirection = 1

        for _ in 0..<20 { scene.tickEndlessIIDrift(0.2) }
        XCTAssertNotNil(brick.parent, "and never destroyed by it")
        XCTAssertLessThan(brick.position.x, 0,
                          "out at the right and back in at the left, still going the same way")
        XCTAssertEqual(brick.position.y, 40, "and never off its row (§8.6)")
    }

    func testItKeepsGoingTheSameWayForTheWholeDrift() {
        // James, round 167: "the bricks should slowly drift from left to right or right to
        // left". They swayed instead - *any* brick reaching a wall turned the whole field
        // round, and on a field that spans the width there is nearly always a brick near an
        // edge, so it reversed every second or two and travelled about half a cell each way.
        // Measured in play at 1-2 second intervals and never more than 22 points of travel
        let scene = driftScene()
        brick(in: scene, x: scene.gameWidth/2 - scene.brickWidth/2, y: 40)
        brick(in: scene, x: -scene.gameWidth/2 + scene.brickWidth/2, y: 40)
        // One against each wall, which is the arrangement that used to reverse it every frame
        scene.endlessIICollectDrift(direction: 1)
        scene.endlessIIDriftDirection = 1

        for _ in 0..<40 { scene.tickEndlessIIDrift(0.1) }
        XCTAssertEqual(scene.endlessIIDriftDirection, 1, "one direction, for the whole drift")
    }

    func testAWrappedBrickLandsOnAColumnCentre() {
        // The shift is the field's whole width, which is a whole number of columns - so a
        // brick that goes round the side lands on a column rather than between two, and the
        // cells the generator and the crush speak in stay the cells everything else means
        let scene = driftScene()
        let left = -scene.gameWidth/2 + scene.brickWidth/2
        let brick = brick(in: scene, x: left, y: 40)
        scene.endlessIICollectDrift(direction: 1)
        scene.endlessIIDriftDirection = -1

        for _ in 0..<40 { scene.tickEndlessIIDrift(0.1) }
        scene.endlessIIDriftClock.run(down: GameScene.endlessIIDriftDuration)
        scene.tickEndlessIIDrift(0.016)
        XCTAssertEqual(brick.position.x,
                       scene.endlessIIColumnCentre(nearest: brick.position.x), accuracy: 0.0001)
    }

    func testAnAnchoredBrickIsLeftWhereItWasStruck() {
        // The rule the descent uses. A Fixed brick's whole meaning is that it stopped there
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 40)
        brick.endlessIIIsAnchored = true
        scene.endlessIICollectDrift(direction: 1)
        scene.tickEndlessIIDrift(0.5)

        XCTAssertEqual(brick.position.x, 0, accuracy: 0.0001)
    }

    func testEverythingLandsBackOnAColumnCentreWhenItEnds() {
        // The grid is how the generator, the crush and the neighbour rules all speak
        let scene = driftScene()
        let brick = brick(in: scene, x: 0, y: 40)
        scene.endlessIICollectDrift(direction: 1)
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
        scene.endlessIICollectDrift(direction: 1)
        scene.tickEndlessIIDrift(0.5)
        XCTAssertEqual(brick.position.x, 0, accuracy: 0.0001)
    }

    // MARK: - Safety Paddle

    /// James, round 169: "I got stuck with an empty screen, no bricks coming down from the top
    /// after the lowest brick it destroyed. This happened after the clear and retreat power up
    /// and coming back from the pause screen."
    ///
    /// It looked like a pause bug and was not. `moveEndlessModeRowDown` sets
    /// `endlessMoveInProgress` and the new row's own action clears it on completion - so if
    /// those bricks leave before the action finishes, which is what Clear And Retreat does to
    /// them, the completion never runs. `countBricks` was the only other writer and it wrote
    /// from *inside* its loop over the bricks, so an empty field never reached the line at all
    /// and the flag stayed true, and the guard refused to generate another row for the rest of
    /// the run. Pausing appeared to fix it because the ball reset clears the flag by hand.
    /// `countBricks` reads the achievement arrays, so the scene it is asked of needs its
    /// stats - the class's own helper does not set them, and an empty `totalStatsArray` is an
    /// index-out-of-range that takes the whole test run down with it rather than one test.
    ///
    /// The field is **held** in each of these, which is the only way to ask the question. The
    /// last thing `countBricks` does is start the next row when the bottom is clear, and that
    /// sets the flag again - so on an unheld field the flag is true afterwards either way, and
    /// "stuck true" and "true because the descent just began" are the same reading. Holding it
    /// stops the follow-on move, so what is left is what the count itself decided.
    private func descentScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.endlessMode = true
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.gameWidth = 400
        scene.numberOfBrickColumns = 10
        // Real cell geometry, because a test that destroys a brick runs the gravity fill
        // sweep, and `EndlessIIFieldGeometry.cell(at:)` divides by these - a zero-width
        // cell is NaN, and Int(NaN) is the crash the full suite caught (round 177)
        scene.endlessIIClearAndRetreatClock.collect(5)
        return scene
    }

    private func brick(on scene: GameScene, x: CGFloat, moving: Bool = false) {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: 30, height: 15)
        brick.position = CGPoint(x: x, y: 200)
        brick.name = BrickCategoryName
        scene.addChild(brick)
        if moving { brick.run(.moveBy(x: 0, y: -15, duration: 5)) }
    }

    /// Runs the retreat's lift to wherever it is going, the way a run of frames would.
    ///
    /// The lift stopped being a single write in round 185 - it glides over a third of a
    /// second, because a field that jumped two rows in one frame is what James saw and
    /// reported as the collection animation shifting up two rows. So a test that wants the
    /// field *where the retreat is taking it* has to let the frames happen. Bounded, so a
    /// glide that never lands fails rather than hangs.
    @discardableResult
    private func settleRetreat(_ scene: GameScene, file: StaticString = #filePath,
                               line: UInt = #line) -> Int {
        for frames in 0..<600 {
            if scene.endlessIIFieldShiftHasSettled { return frames }
            scene.tickEndlessIIFieldShift(1.0/60.0)
        }
        XCTFail("the retreat's lift never settled", file: file, line: line)
        return -1
    }

    /// James, round 169: "clear and retreat should remove the bottom 2 rows, it should move all
    /// rows up 2 rows for some time. It should move the low brick line up 2 rows too. As if the
    /// game is set 2 rows higher."
    ///
    /// The line is the half that can be done without deciding what happens to a brick pushed
    /// off the top of the field, and it is the half that makes the retreat real: clearing the
    /// two lowest rows moved the bricks away from the paddle and left the line they die on
    /// where it was, so the room the power-up made was room the descent took straight back.
    func testARetreatLiftsTheLineTheFieldDiesOn() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        scene.finalBrickRowHeight = -100
        let floor = scene.finalBrickRowHeight

        scene.endlessIICollectClearAndRetreat()
        XCTAssertEqual(scene.finalBrickRowHeight, floor, accuracy: 0.001,
                       "and not in the frame it was caught in - the line slides")
        settleRetreat(scene)
        XCTAssertEqual(scene.finalBrickRowHeight,
                       floor + CGFloat(GameScene.endlessIIRetreatRows)*scene.brickHeight,
                       accuracy: 0.001,
                       "two rows further from the paddle for as long as the clock runs")
    }

    func testTheLineComesBackDownWhenTheRetreatEnds() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        scene.finalBrickRowHeight = -100
        let floor = scene.finalBrickRowHeight

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        scene.endlessIIClearAndRetreatClock.run(down: GameScene.endlessIIClearAndRetreatDuration)
        settleRetreat(scene)

        XCTAssertEqual(scene.finalBrickRowHeight, floor, accuracy: 0.001,
                       "or the run would keep the room for ever, which is a different power-up")
        XCTAssertEqual(scene.endlessIIFieldShift, 0)
    }

    /// James, round 177, answering round 172's open question: "I think it's ok if the top 2
    /// rows just get hidden behind the HUD. They're there, but effectively out of the game
    /// and hidden from view." So the bricks lift with the line now - the whole field, two
    /// rows further from the paddle, for as long as the clock runs.
    func testARetreatLiftsTheBricksWithTheLine() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        let low = brick(in: scene, x: 0, y: 40)
        let next = brick(in: scene, x: 0, y: 60)
        let survivor = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        for (standing, was) in [(low, 40.0), (next, 60.0), (survivor, 120.0)] {
            XCTAssertNotNil(standing.parent, "nothing is cleared any more (round 215)")
            XCTAssertEqual(standing.position.y, CGFloat(was) + 2*scene.brickHeight,
                           accuracy: 0.001,
                           "every row is carried up with the frame, including the lowest two")
        }
    }

    func testTheFieldComesBackDownWhenTheRetreatEnds() {
        // "For some time": the lift is the clock's, and the clear's two rows are the only
        // permanent part
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        let survivor = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        scene.endlessIIClearAndRetreatClock.run(down: GameScene.endlessIIClearAndRetreatDuration)
        settleRetreat(scene)

        XCTAssertEqual(survivor.position.y, 120, accuracy: 0.001,
                       "the hidden rows re-enter from behind the HUD as the line drops back")
    }

    func testAnAnchoredBrickRidesTheLiftToo() {
        // The frame is what moves, not the conveyor - an anchor is anchored to the field,
        // and the field went up
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        let anchored = brick(in: scene, x: 0, y: 140)
        anchored.endlessIIIsAnchored = true

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        XCTAssertEqual(anchored.position.y, 140 + 2*scene.brickHeight, accuracy: 0.001)
    }

    func testASaveTakenMidRetreatStoresTheRowsWhereTheyBelong() {
        // The restored clock is still running, so the restore's first tick lifts the field
        // again - a save that kept the lifted positions would be lifted twice
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        let survivor = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        XCTAssertEqual(scene.endlessIICanonicalRestingY(survivor.position.y), 120,
                       accuracy: 0.001, "where it belongs, not where the lift has it")

        scene.endlessIIClearAndRetreatClock.run(down: GameScene.endlessIIClearAndRetreatDuration)
        settleRetreat(scene)
        XCTAssertEqual(scene.endlessIICanonicalRestingY(survivor.position.y), 120,
                       accuracy: 0.001, "and the same answer once the lift is over")
    }

    func testASecondRetreatDoesNotStackTheLift() {
        // extendsDuration: longer, not higher
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        scene.finalBrickRowHeight = -100
        let floor = scene.finalBrickRowHeight

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        XCTAssertEqual(scene.finalBrickRowHeight,
                       floor + CGFloat(GameScene.endlessIIRetreatRows)*scene.brickHeight,
                       accuracy: 0.001)
    }

    /// James, round 184: "the power animation when I collected it shifted up 2 rows".
    ///
    /// Nothing was in the wrong place - the field simply arrived two rows higher in the one
    /// frame the power-up was caught in, and a whole field jumping two rows in no time reads
    /// as a glitch rather than as a retreat. It slides now.
    func testTheFieldSlidesItsTwoRowsRatherThanJumpingThem() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        let survivor = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        XCTAssertEqual(survivor.position.y, 120, accuracy: 0.001,
                       "the clear is instant; the lift is not")

        scene.tickEndlessIIFieldShift(1.0/60.0)
        let afterOneFrame = survivor.position.y
        XCTAssertGreaterThan(afterOneFrame, 120, "it has started")
        XCTAssertLessThan(afterOneFrame, 120 + 2*scene.brickHeight,
                          "and one frame is not the whole of it")

        let frames = settleRetreat(scene)
        XCTAssertGreaterThan(frames, 1, "several frames' worth of movement to watch")
        XCTAssertEqual(survivor.position.y, 120 + 2*scene.brickHeight, accuracy: 0.001,
                       "and it lands exactly where the instant version put it")
    }

    /// The glide is only safe because nothing reads the field while it runs.
    ///
    /// A brick's `position.y` is its row (§8.6), and mid-slide every brick is between two -
    /// so the descent, the generator and the bottom-zone check all have to stand down until
    /// the field has landed, at *both* ends of the retreat.
    func testTheFieldIsHeldWhileTheLiftIsStillMoving() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        _ = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        settleRetreat(scene)
        XCTAssertTrue(scene.endlessIIFieldIsHeld, "held by the clock, as it always was")

        scene.endlessIIClearAndRetreatClock.run(down: GameScene.endlessIIClearAndRetreatDuration)
        scene.tickEndlessIIFieldShift(1.0/60.0)
        XCTAssertFalse(scene.endlessIIFieldShiftHasSettled)
        XCTAssertTrue(scene.endlessIIFieldIsHeld,
                      "the clock has stopped but the field is still coming down, and a row "
                      + "read off a brick between rows is the trap of §8.6")

        settleRetreat(scene)
        XCTAssertFalse(scene.endlessIIFieldIsHeld, "and it lets go once the field has landed")
    }

    /// A run saved mid-slide comes back where it belongs, exactly as one saved mid-lift does.
    ///
    /// `endlessIICanonicalRestingY` subtracts however much lift there is, whole rows or a
    /// fraction of one, so the answer is the brick's own row at every point of the glide -
    /// which is what stops a resume lifting a field that is already lifted.
    func testASaveTakenMidSlideStillStoresTheRowsWhereTheyBelong() {
        let scene = descentScene()
        scene.endlessIIClearAndRetreatClock.reset()
        scene.brickHeight = 20
        _ = brick(in: scene, x: 0, y: 40)
        _ = brick(in: scene, x: 0, y: 60)
        let survivor = brick(in: scene, x: 0, y: 120)

        scene.endlessIICollectClearAndRetreat()
        scene.tickEndlessIIFieldShift(1.0/120.0)
        XCTAssertFalse(scene.endlessIIFieldShiftHasSettled, "caught in the middle of it")
        XCTAssertEqual(scene.endlessIICanonicalRestingY(survivor.position.y), 120,
                       accuracy: 0.001)
    }

    func testAnEmptyFieldIsNotStillMoving() {
        let scene = descentScene()
        scene.endlessMoveInProgress = true

        scene.countBricks()
        XCTAssertFalse(scene.endlessMoveInProgress,
                       "nothing on the field can be mid-step, so nothing holds the descent")
    }

    func testAStillFieldIsNotMovingEitherWhateverTheLastBrickSaid() {
        // The flag used to be whatever the last brick examined happened to say
        let scene = descentScene()
        scene.endlessMoveInProgress = true
        for x in [CGFloat(-40), 0, 40] { brick(on: scene, x: x) }

        scene.countBricks()
        XCTAssertFalse(scene.endlessMoveInProgress)
    }

    func testAFieldWithOneBrickMidStepIsMoving() {
        // Enumeration order is not ours to choose, which is the point: one brick mid-step
        // holds the field whether it is seen first or last
        let scene = descentScene()
        scene.endlessMoveInProgress = false
        brick(on: scene, x: -40)
        brick(on: scene, x: 40, moving: true)

        scene.countBricks()
        XCTAssertTrue(scene.endlessMoveInProgress)
    }

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
                       scene.finalBrickRowHeight - scene.brickHeight*1.5, accuracy: 0.001,
                       "one full brick row below the low-limit line, which is drawn half a "
                       + "row under the lowest brick row (round 200) - clear air, so the bar "
                       + "and a last-row brick read as two things")
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

    /// A second collection refills it rather than building a second bar.
    ///
    /// It used to check the clock had grown; from round 220 a second collection resets it, so
    /// what matters is that one bar stands with a full clock rather than two standing at once.
    ///
    /// **Spends bounces rather than seconds since round 305**, when the power-up moved onto a
    /// turn budget - `run(down:)` deliberately does not touch a turns clock any more, so the
    /// old version of this test burned five seconds that no longer exist and then asserted the
    /// clock was full, which it would have been either way. Rewritten rather than deleted: the
    /// thing it is about - one bar, refilled, not two - has not changed.
    func testASecondCollectionRefillsItRatherThanStackingTwo() {
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIISafetyPaddleClock.spendTurn()
        scene.endlessIISafetyPaddleClock.spendTurn()
        XCTAssertEqual(scene.endlessIISafetyPaddleClock.remaining,
                       TimeInterval(GameScene.endlessIISafetyPaddleBounces - 2), accuracy: 0.001,
                       "two of the five bounces are spent")

        scene.endlessIICollectSafetyPaddle()

        XCTAssertEqual(scene.endlessIISafetyPaddleClock.remaining,
                       TimeInterval(GameScene.endlessIISafetyPaddleBounces), accuracy: 0.001,
                       "the budget did not start again")
        var found = 0
        scene.enumerateChildNodes(withName: GameScene.endlessIISafetyPaddleName) { _, _ in
            found += 1
        }
        XCTAssertEqual(found, 1, "full again, not thicker")
    }

    func testItIsNeverStranded() {
        // A surface left behind after its clock stops would change the rest of the run -
        // the same rule Ghost Ball has about the ball's alpha
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        for _ in 0..<GameScene.endlessIISafetyPaddleBounces {
            scene.endlessIISafetyPaddleClock.spendTurn()
        }
        scene.endlessIISafetyPaddleClock.run(down: EndlessIIClock.lingerSeconds)
        // Every bounce spent, then the goodbye run out - which `run(down:)` still does for a
        // turns clock, and is the only thing it does for one
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

    /// James, round 166: "with Safety Paddle, the ball shouldn't contact it when coming from
    /// below, it should pass through it."
    ///
    /// It was written as a trade - keeps the ball up, seals the bricks off from underneath -
    /// and in play the second half reads as the ball being cheated rather than as a price:
    /// a shot from the paddle that would have reached the field bounces off a bar the player
    /// was *given*. The bit is cleared on the ball rather than the bar, so four balls each
    /// get their own answer about one surface.
    private func ballUnderTheBar(_ scene: GameScene) -> SKSpriteNode {
        let ball = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        ball.physicsBody?.collisionBitMask = CollisionTypes.safetyPaddleCategory.rawValue
        ball.physicsBody?.contactTestBitMask = CollisionTypes.safetyPaddleCategory.rawValue
        scene.addChild(ball)
        return ball
    }

    private func meetsTheBar(_ ball: SKSpriteNode) -> Bool {
        let bit = CollisionTypes.safetyPaddleCategory.rawValue
        return (ball.physicsBody?.collisionBitMask ?? 0) & bit != 0
    }

    func testABallClimbingFromUnderneathPassesThrough() {
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        guard let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return XCTFail("the bar stands") }

        let ball = ballUnderTheBar(scene)
        ball.position.y = bar.position.y - bar.size.height
        scene.endlessIIExtraBalls = [ball]
        scene.refreshEndlessIISafetyPaddleReachability()

        XCTAssertFalse(meetsTheBar(ball), "underneath it, so it climbs straight through")
    }

    func testABallAboveItIsStillCaught() {
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        guard let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return XCTFail("the bar stands") }

        let ball = ballUnderTheBar(scene)
        ball.position.y = bar.position.y + bar.size.height + ball.size.height
        scene.endlessIIExtraBalls = [ball]
        scene.refreshEndlessIISafetyPaddleReachability()

        XCTAssertTrue(meetsTheBar(ball), "which is the half of the power-up that is a gift")
    }

    func testItGoesSolidOnlyOnceTheBallIsClearOfIt() {
        // Not at the moment the ball's centre passes: a ball made solid while it still
        // overlaps the bar is one the engine shoves aside, which is a jolt mid-climb
        let scene = safetyScene()
        scene.endlessIICollectSafetyPaddle()
        guard let bar = scene.childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return XCTFail("the bar stands") }

        let ball = ballUnderTheBar(scene)
        ball.position.y = bar.position.y + bar.size.height/2 + 1
        scene.endlessIIExtraBalls = [ball]
        scene.refreshEndlessIISafetyPaddleReachability()

        XCTAssertFalse(meetsTheBar(ball), "its underside is still inside the bar")
    }

    func testWithNoBarStandingEveryBallHasItsFullMaskBack() {
        let scene = safetyScene()
        let ball = ballUnderTheBar(scene)
        ball.physicsBody?.collisionBitMask = 0
        ball.physicsBody?.contactTestBitMask = 0
        scene.endlessIIExtraBalls = [ball]
        scene.refreshEndlessIISafetyPaddleReachability()

        XCTAssertTrue(meetsTheBar(ball),
                      "a mask left cleared is a mask that lies about what the ball can hit")
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
        let index = setup.powerUpNameArray.firstIndex(of: "Random Bounce")
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
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.addChild(scene.ball)
        return scene
    }

    /// James, round 182: "with ghost ball and aura power-ups together, I can still see the
    /// aura effect around the ball. Any power-up like this where there's an additional effect
    /// on the ball, it should also be invisible when the ball is invisible. The aura power
    /// should still be functional, just not visible."
    func testTheAuraIsAsInvisibleAsTheBallItRings() {
        let scene = mayhem()
        scene.ballSize = 10
        scene.totalStatsArray = [TotalStats()]
        scene.ball.position = CGPoint(x: 0, y: 300)   // up among the bricks, so ghosted
        scene.endlessIICollectAura()
        scene.endlessIICollectGhostBall()

        scene.tickEndlessIIGhostBall()
        scene.tickEndlessIIAura()

        XCTAssertEqual(scene.ball.alpha, 0, accuracy: 0.001, "the ball is ghosted")
        XCTAssertEqual(scene.endlessIIAuraNodes.first?.effectiveAlpha, 0,
                       "and its ring goes with it")
        // **Effective rather than its own** (round 284). The glow is the ball's child now, so
        // it keeps an alpha of 1 and SpriteKit multiplies it by the ball's on the way to the
        // screen - which is the same answer arrived at by inheritance rather than by a line
        // that copies it. Asking the glow for its own alpha would pass whatever the ball did
    }

    func testGhostingChangesNothingButTheDrawing() {
        // "The aura power should still be functional, just not visible" - so the honest test
        // is that the *same* field is struck either way. Two identical scenes, one ghosted,
        // and the only difference between them is the alpha
        func struckBricks(ghosted: Bool) -> Int {
            let scene = mayhem()
            scene.ballSize = 10
            scene.ball.size = CGSize(width: 10, height: 10)
            scene.brickWidth = 40
            scene.brickHeight = 20
            scene.totalStatsArray = [TotalStats()]
            scene.ball.position = CGPoint(x: 0, y: 300)
            // Reach is `ballSize/2 * 2.0` = 10, and a brick must be clear of the ball itself
            // (`endlessIIAuraReaches` wants the nearest point beyond the ball's own radius),
            // so a brick whose edge sits 8 points away is inside the ring and outside the ball
            let brick = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
            brick.name = BrickCategoryName
            brick.position = CGPoint(x: 0, y: 318)
            scene.addChild(brick)
            scene.endlessIICollectAura()
            if ghosted { scene.endlessIICollectGhostBall() }
            scene.tickEndlessIIGhostBall()
            scene.tickEndlessIIAura()
            return scene.endlessIIAuraHitBricks.count
        }

        let seen = struckBricks(ghosted: false)
        XCTAssertGreaterThan(seen, 0, "the aura reaches something to begin with")
        XCTAssertEqual(struckBricks(ghosted: true), seen,
                       "and reaches exactly the same when nobody can see it")
    }

    func testTheAuraComesBackWithTheBallBelowTheBricks() {
        let scene = mayhem()
        scene.ballSize = 10
        scene.totalStatsArray = [TotalStats()]
        scene.ball.position = CGPoint(x: 0, y: 50)   // below the field, so seen
        scene.endlessIICollectAura()
        scene.endlessIICollectGhostBall()

        scene.tickEndlessIIGhostBall()
        scene.tickEndlessIIAura()

        XCTAssertEqual(scene.ball.alpha, 1, accuracy: 0.001)
        XCTAssertEqual(scene.endlessIIAuraNodes.first?.effectiveAlpha, 1)
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
        // The answer to missing art, held here against a theme index that does not exist.
        // It was the glass theme until James drew it (round 153); the rule outlives the gap,
        // because a ball wearing somebody else's spikes is worse than a ball wearing none
        let scene = mayhem(theme: 99)
        scene.ball.texture = scene.ballTexture
        scene.endlessIICollectWreckingBall()
        scene.refreshEndlessIIWreckingBall()

        XCTAssertNil(scene.endlessIIWreckingTexture(for: .normal))
        XCTAssertNil(spikes(scene))
        XCTAssertEqual(scene.ball.texture, scene.ballTexture, "still its own ball")
    }

    func testTheThemeOrderIsPinnedByTheThreeTexturesThatAreADifferentSize() {
        // The map from a theme index to a file name is written out by hand, and a map that
        // is one out gives an Ice ball Outline spikes - which looks like art nobody likes
        // rather than like a bug. Three themes have a size of their own: the square theme's
        // spikes are drawn *inside* a 50pt square, the candy cane's reach 72, and the glass
        // theme has no art at all. Any shuffle of the order moves at least one of them
        let scene = mayhem()
        let expected: [(theme: Int, width: CGFloat?)] = [(4, 50), (8, 72), (99, nil)]

        for (theme, width) in expected {
            scene.ballSetting = theme
            let texture = scene.endlessIIWreckingTexture(for: .normal)
            guard let width else {
                XCTAssertNil(texture, "a theme that does not exist has no art")
                continue
            }
            XCTAssertEqual(texture?.size().width, width, "theme \(theme) is not where it was")
        }
    }

    func testEveryOtherThemeHasArtForAllThreeBalls() {
        // The count that stops a theme being silently skipped - the same trap as a style
        // that is in the enum but not in a pool. All twelve since round 153
        let scene = mayhem()
        for theme in 0..<LevelPackSetup().ballImageArray.count {
            scene.ballSetting = theme
            for dress in [GameScene.BallDress.normal, .giga, .undestructi] {
                XCTAssertNotNil(scene.endlessIIWreckingTexture(for: dress),
                                "theme \(theme) has no wrecking art")
            }
        }
    }
}

/// Quicksand in Endless Mayhem: Retreat's opposite number.
///
/// James, round 218: "Quicksand as 2 different versions. The one in Classic Mode is
/// persistent. The bricks move down and stay there. In the Endless modes... it should be
/// temporary. The bricks move down for some time, then move back. The opposite of Retreat. It
/// should show up as the same power-up in the information view and use the same icons."
///
/// One slot, two behaviours, which is what makes the information view show one entry without
/// anything having to be told to hide the other.
final class EndlessIIQuicksandTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickHeight = 20
        scene.brickWidth = 40
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    private func brick(_ scene: GameScene, y: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
        node.name = BrickCategoryName
        node.position = CGPoint(x: 0, y: y)
        scene.addChild(node)
        return node
    }

    /// The field steps two rows toward the paddle, and the line it dies on comes with it.
    func testTheFieldStepsTowardThePaddle() {
        let scene = mayhem()
        let node = brick(scene, y: 100)
        let floor = scene.finalBrickRowHeight

        scene.endlessIICollectQuicksand()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }

        let step = CGFloat(GameScene.endlessIIRetreatRows)*scene.brickHeight
        XCTAssertEqual(node.position.y, 100 - step, accuracy: 0.01,
                       "the bricks did not come down")
        XCTAssertEqual(scene.finalBrickRowHeight, floor - step, accuracy: 0.01,
                       "the line the field dies on stayed where it was")
    }

    /// And steps back when the clock ends, which is the half that makes it temporary.
    func testTheFieldGoesBackWhenItEnds() {
        let scene = mayhem()
        let node = brick(scene, y: 100)

        scene.endlessIICollectQuicksand()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }
        scene.endlessIIQuicksandClock.reset()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }

        XCTAssertEqual(node.position.y, 100, accuracy: 0.01, "the field never came back up")
        XCTAssertEqual(scene.endlessIIFieldShift, 0, accuracy: 0.01)
    }

    /// A Retreat and a Quicksand together leave the field where it was.
    ///
    /// The matrix's own answer for that pair, and it costs nothing: the two are one number
    /// counted in opposite directions rather than two effects that have to know about each
    /// other.
    func testARetreatAndAQuicksandCancel() {
        let scene = mayhem()
        let node = brick(scene, y: 100)

        scene.endlessIICollectClearAndRetreat()
        scene.endlessIICollectQuicksand()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }

        XCTAssertEqual(node.position.y, 100, accuracy: 0.01, "the two did not cancel")
    }

    /// The field is held while it runs, the way it is held for a Retreat.
    func testTheFieldIsHeldWhileItRuns() {
        let scene = mayhem()
        scene.endlessIICollectQuicksand()
        XCTAssertTrue(scene.endlessIIFieldIsHeld)
    }

    /// It does not drop on top of itself.
    func testItIsNotOfferedWhileOneIsAlreadyRunning() {
        let scene = mayhem()
        XCTAssertTrue(scene.powerUpCanAppear(23))
        scene.endlessIICollectQuicksand()
        XCTAssertFalse(scene.powerUpCanAppear(23))
    }

    /// Classic's Quicksand is untouched: no clock, and the old permanent move.
    func testClassicsQuicksandIsNotThisOne() {
        let scene = mayhem()
        scene.gameMode = .classic
        scene.endlessIICollectQuicksand()
        XCTAssertFalse(scene.endlessIIQuicksandClock.isRunning,
                       "Classic collected the endless version")
    }

    /// It is in the one table, so it is in the ring, the save and the Wipe.
    func testItIsInTheTableThatFeedsTheRingTheSaveAndTheWipe() {
        let scene = mayhem()
        scene.endlessIICollectQuicksand()

        XCTAssertTrue(scene.endlessIIFieldRingEntries().contains { $0.id == "endlessIIQuicksand" })
        XCTAssertTrue(scene.endlessIIFieldClockSaveEntries().contains { $0.key == "endlessIIQuicksand" })
        XCTAssertTrue(GameScene.endlessIIWipeableClockPaths.contains(\.endlessIIQuicksandClock))
        XCTAssertTrue(GameScene.endlessIITimedClockPaths.contains(\.endlessIIQuicksandClock),
                      "a Lock has to freeze it")

        scene.endlessIIRestoreFieldClock(key: "endlessIIQuicksand", remaining: 4,
                                         total: 10, magnitude: 0)
        XCTAssertTrue(scene.endlessIIQuicksandClock.isRunning, "a resumed run lost it")
    }
}

/// Where the Paddle Halo sits while the field is somewhere else.
///
/// James, round 218, on the matrix's "halo moves in line with bricks": "I mean that the halo
/// tracks the field's vertical shift."
final class PaddleHaloFollowsTheFieldTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickHeight = 20
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.paddle)
        scene.paddle.position = CGPoint(x: 40, y: -300)
        return scene
    }

    func testItSitsAtThePaddleWithTheFieldWhereItStarted() {
        let scene = mayhem()
        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.y, -300, accuracy: 0.01)
        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.x, 0, accuracy: 0.01,
                       "it stands at the centre of the field, not on the paddle (round 184)")
    }

    /// A Retreat lifts every brick two rows away, and the glow goes with them - or it would
    /// reach two rows less of the field for as long as the retreat ran.
    func testItRisesWithARetreat() {
        let scene = mayhem()
        scene.endlessIICollectClearAndRetreat()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }

        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.y,
                       -300 + CGFloat(GameScene.endlessIIRetreatRows)*scene.brickHeight,
                       accuracy: 0.01)
    }

    func testItFallsWithAQuicksand() {
        let scene = mayhem()
        scene.endlessIICollectQuicksand()
        for _ in 0..<200 { scene.tickEndlessIIFieldShift(1/60) }

        XCTAssertEqual(scene.endlessIIPaddleHaloCentre.y,
                       -300 - CGFloat(GameScene.endlessIIRetreatRows)*scene.brickHeight,
                       accuracy: 0.01)
    }
}

/// Which power-ups end which, from the matrix's "most recent power-up overrides".
///
/// Fifteen cells of it, and deliberately not the group model `PowerUpCatalogue.conflict` uses:
/// these are pairs rather than a partition. Inert Ball ends a Giga-Ball, a Wrecking Ball and a
/// Ball Aura, and those three combine happily with each other. Auto-Aim ends a Portal, and a
/// Portal runs contentedly beside an Inert Paddle.
final class EndlessIIExclusionTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// The table, against the matrix, written out in its own terms.
    func testTheTableIsTheMatrix() {
        let expected: [(EndlessIIExclusive, EndlessIIExclusive)] = [
            (.inertBall, .gigaBall), (.wreckingBall, .inertBall), (.ballAura, .inertBall),
            (.inertPaddle, .aimedSticky), (.flippedAngle, .aimedSticky),
            (.flippedAngle, .inertPaddle), (.autoAim, .aimedSticky), (.autoAim, .portalPaddle),
            (.autoAim, .inertPaddle), (.autoAim, .flippedAngle), (.ballSpin, .stickyPaddle),
            (.ballSpin, .aimedSticky), (.ballSpin, .ballControl), (.ballSpin, .inertPaddle),
            (.ballSpin, .autoAim),
        ]
        XCTAssertEqual(EndlessIIExclusions.pairs.count, expected.count)
        for (a, b) in expected {
            XCTAssertTrue(EndlessIIExclusions.pairs.contains { ($0 == a && $1 == b) || ($0 == b && $1 == a) },
                          "\(a) and \(b) are not named as ending each other")
        }
    }

    /// "Most recent overrides" reads both ways, so the lookup has to.
    func testItReadsBothWaysRound() {
        XCTAssertTrue(EndlessIIExclusions.ended(byCollecting: .autoAim).contains(.aimedSticky))
        XCTAssertTrue(EndlessIIExclusions.ended(byCollecting: .aimedSticky).contains(.autoAim))
    }

    /// The pairs that are *not* there matter as much as the ones that are.
    func testWhatCombinesIsLeftAlone() {
        XCTAssertFalse(EndlessIIExclusions.ended(byCollecting: .gigaBall).contains(.wreckingBall),
                       "a wrecking Giga-Ball is the matrix's own answer, not a conflict")
        XCTAssertFalse(EndlessIIExclusions.ended(byCollecting: .gigaBall).contains(.ballAura))
        XCTAssertFalse(EndlessIIExclusions.ended(byCollecting: .portalPaddle).contains(.inertPaddle),
                       "a Portal and an Inert Paddle agree perfectly")
        XCTAssertFalse(EndlessIIExclusions.ended(byCollecting: .ballSpin).contains(.flippedAngle),
                       "spin off a flipped angle is simply spin the other way")
    }

    /// Collecting one ends the other, on the scene.
    func testCollectingAutoAimEndsTheAimedStickyAndThePortal() {
        let scene = mayhem()
        scene.endlessIICollectAimedSticky()
        scene.endlessIICollectPortalPaddle()
        scene.endlessIICollectAutoAim()

        XCTAssertFalse(scene.endlessIIAimedStickyClock.isRunning)
        XCTAssertFalse(scene.endlessIIPortalPaddleClock.isRunning)
        XCTAssertTrue(scene.endlessIIAutoAimClock.isRunning)
    }

    /// And the other way round, which is what "most recent" means.
    func testCollectingTheAimedStickyEndsTheAutoAim() {
        let scene = mayhem()
        scene.endlessIICollectAutoAim()
        scene.endlessIICollectAimedSticky()

        XCTAssertFalse(scene.endlessIIAutoAimClock.isRunning)
        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)
    }

    /// Ball Spin ends everything else that decides where the ball leaves the paddle.
    func testBallSpinEndsTheOtherAnswersToTheSameQuestion() {
        let scene = mayhem()
        scene.endlessIICollectInertPaddle()
        scene.endlessIICollectBallSteering()
        scene.endlessIICollectBallSpin()

        XCTAssertFalse(scene.endlessIIInertPaddleClock.isRunning)
        XCTAssertFalse(scene.endlessIIBallSteeringClock.isRunning)
        XCTAssertTrue(scene.endlessIIBallSpinClock.isRunning)
    }

    /// A Wrecking Ball ends an Inert Ball, which says the opposite of it.
    func testAWreckingBallEndsAnInertBall() {
        let scene = mayhem()
        scene.runClassicPowerUpTimer(key: "powerUpUndestructiBall",
                                     wait: .wait(forDuration: 10), ending: .run {})
        scene.endlessIICollectWreckingBall()

        XCTAssertNil(scene.action(forKey: "powerUpUndestructiBall"),
                     "the ball cannot be unable to break bricks and break every brick at once")
    }

    /// Nothing outside Endless Mayhem is displaced by any of this.
    func testTheOtherModesAreLeftAlone() {
        let scene = mayhem()
        scene.gameMode = .classic
        scene.runClassicPowerUpTimer(key: "powerUpUndestructiBall",
                                     wait: .wait(forDuration: 10), ending: .run {})
        scene.endlessIIDisplace(byCollecting: .wreckingBall)
        XCTAssertNotNil(scene.action(forKey: "powerUpUndestructiBall"))
    }
}

/// The two Drifts cancel rather than reverse.
///
/// Round 201 made collecting the opposite one turn the field around and extend the clock - a
/// dial rather than two coats of the same paint - which was a good answer to a question round
/// 223's matrix has since answered differently: "cancels out". These two are each other's
/// opposite the way Expand and Shrink are, and those have cancelled since 2020.
final class DriftsCancelTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickWidth = 40
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    func testTheOppositeDriftEndsIt() {
        let scene = mayhem()
        scene.endlessIICollectDrift(direction: 1)
        XCTAssertTrue(scene.endlessIIDriftClock.isRunning)

        scene.endlessIICollectDrift(direction: -1)
        XCTAssertFalse(scene.endlessIIDriftClock.isRunning, "the two did not cancel")
    }

    /// The same one again refills it, like every other power-up.
    func testTheSameDriftRefillsIt() {
        let scene = mayhem()
        scene.endlessIICollectDrift(direction: 1)
        scene.endlessIIDriftClock.run(down: 5)
        scene.endlessIICollectDrift(direction: 1)

        XCTAssertEqual(scene.endlessIIDriftClock.remaining,
                       GameScene.endlessIIDriftDuration, accuracy: 0.001)
        XCTAssertEqual(scene.endlessIIDriftDirection, 1, "it turned around instead")
    }

    /// A cancelled drift still puts the field back on its grid.
    ///
    /// The clock is reset and the tick does the rest, because stopping the slide by hand here
    /// would leave the field between columns - and a brick between columns is a brick on no
    /// row at all (§8.6).
    func testACancelledDriftLeavesTheFieldOnItsGrid() {
        let scene = mayhem()
        scene.endlessIICollectDrift(direction: 1)
        scene.endlessIICollectDrift(direction: -1)
        scene.tickEndlessIIDrift(1/60)

        XCTAssertEqual(scene.endlessIIDriftDirection, 0, "the drift never finished")
    }
}

/// The safety paddle becomes a paddle.
///
/// James, round 224: "go with the latest definition", against his matrix giving the safety
/// paddle the paddle's shape, its Inert Paddle, its Flipped Bounce Angle, its Auto-Aim, its
/// Random Bounce and its Ball Spin.
///
/// Round 211 called it furniture and answered with the backstop's arithmetic on purpose: the
/// ball's own angle, reflected, with nothing about where it landed. Every one of those five
/// power-ups needs the landing position back to have anything to act on - a Flipped Angle with
/// no angle to flip does nothing at all on the surface it is standing on.
final class SafetyPaddleParityTests: XCTestCase {

    private func safetyScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        scene.brickHeight = 20
        scene.paddleWidth = 120
        scene.angleAdjustmentK = 45
        scene.minAngleDeg = 20
        // The two the level setup gives the scene. A bare one has them at zero, and a bounce
        // with no adjustment to make bends by nothing whatever it is asked
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 120, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.endlessIICollectSafetyPaddle()
        return scene
    }

    private func bar(_ scene: GameScene) -> SKSpriteNode? {
        scene.childNode(withName: GameScene.endlessIISafetyPaddleName) as? SKSpriteNode
    }

    /// It grows with an expanded paddle, which it did not: Expand animates `xScale`.
    func testItGrowsWithAnExpandedPaddle() {
        let scene = safetyScene()
        scene.paddle.xScale = 1.5
        scene.tickEndlessIISafetyPaddle()

        XCTAssertEqual(bar(scene)?.xScale ?? 0, 1.5, accuracy: 0.001,
                       "the paddle expanded and its safety net did not")
    }

    /// It takes the paddle's shape while one is running, and its body is traced from it.
    func testItWearsTheShapeThePaddleIsWearing() {
        let scene = safetyScene()
        scene.endlessIICollectPaddleSurface(.concave)
        scene.endlessIIPaddleShapeArtName = "regularPaddleConcave"
        scene.tickEndlessIISafetyPaddle()

        XCTAssertEqual(scene.endlessIISafetyPaddleBodyArt, "regularPaddleConcave",
                       "a shaped picture over a flat body shows one face and gives another")
    }

    /// And notices a shape swapped for one exactly as tall.
    func testItNoticesAWedgeBecomingItsMirror() {
        let scene = safetyScene()
        scene.endlessIICollectPaddleSurface(.wedgeLeft)
        scene.endlessIIPaddleShapeArtName = "regularPaddleWedgeLeft"
        scene.tickEndlessIISafetyPaddle()

        scene.endlessIICollectPaddleSurface(.wedgeRight)
        scene.endlessIIPaddleShapeArtName = "regularPaddleWedgeRight"
        scene.tickEndlessIISafetyPaddle()
        XCTAssertEqual(scene.endlessIISafetyPaddleBodyArt, "regularPaddleWedgeRight")
    }

    /// Back to a rectangle when the shape ends.
    func testItGoesBackToBeingFlat() {
        let scene = safetyScene()
        scene.endlessIICollectPaddleSurface(.convex)
        scene.endlessIIPaddleShapeArtName = "regularPaddleConvex"
        scene.tickEndlessIISafetyPaddle()

        scene.endlessIIPaddleSurfaceClock.reset()
        scene.endlessIIPaddleShapeArtName = nil
        scene.tickEndlessIISafetyPaddle()
        XCTAssertNil(scene.endlessIISafetyPaddleBodyArt)
    }

    /// The angle the bar asks for now depends on where the ball landed on it.
    ///
    /// Asked of the arithmetic rather than of the ball, because the bar hands its answer to
    /// `ballHorizontalControl`, and that stands down unless the scene is in `Playing` - which
    /// a scene built in a test is not. What is under test is the decision: the bar's bounce is
    /// `PaddleBounce`'s, taken across the bar's own face, at the paddle's influence.
    func testWhereTheBallLandsBendsTheBounce() {
        let scene = safetyScene()
        let arriving = CGVector(dx: 0, dy: -300)

        func angle(landingAt x: CGFloat) -> Double {
            PaddleBounce.angleDegrees(
                arriving: arriving,
                collision: PaddleBounce.collision(ballX: x, paddleX: 0,
                                                  paddleWidth: scene.paddle.size.width),
                adjustmentK: scene.angleAdjustmentK,
                influence: scene.endlessIIPaddleAngleInfluence,
                minimumDeg: scene.minAngleDeg)
        }

        XCTAssertGreaterThan(angle(landingAt: -50), angle(landingAt: 50),
                             "a landing on the left should leave leftward of one on the right")
    }

    /// An Inert Paddle takes that back, which is the matrix's own answer for the pair.
    func testAnInertPaddleFlattensItAgain() {
        let scene = safetyScene()
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence, 1, accuracy: 0.001)

        scene.endlessIICollectInertPaddle()
        XCTAssertEqual(scene.endlessIIPaddleAngleInfluence, 0, accuracy: 0.001,
                       "no angle is applied from the ball's position relative to the bar")

        scene.endlessIICollectFlippedAngle()
        XCTAssertLessThan(scene.endlessIIPaddleAngleInfluence, 0,
                          "a Flipped Bounce Angle flips the bar's too")
        // Negative rather than a number: how *far* a flip overshoots is the flip's own
        // decision (it is 1.8, deliberately more than a mirror), and the claim here is only
        // that the bar answers to it. Ending the Inert Paddle above is the exclusion doing
        // its job, so what is being read is the flip alone
    }
}

/// The Aura, after James's round 284 note about it.
///
/// "Aura should be bigger and should be behind the ball not on top of it. Also, it lags behind
/// the ball too far. And it should grow and shrink with the ball if those power ups are
/// active." Four complaints, and three of them have the same cause: the glow was a sibling on
/// the scene being told the ball's position from `update`, which runs *before* the physics
/// step. It is the ball's child now.
final class TheAuraRidesOnTheBallTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.finalBrickRowHeight = 100
        scene.ballSize = 10
        scene.ball.size = CGSize(width: 10, height: 10)
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.ball)
        scene.ball.position = CGPoint(x: 0, y: 50)
        return scene
    }

    /// It cannot lag, because it has no position of its own to be stale.
    func testTheGlowIsCarriedByTheBallRatherThanChasingIt() {
        let scene = mayhem()
        scene.endlessIICollectAura()
        scene.tickEndlessIIAura()

        let glow = scene.endlessIIAuraNodes.first
        XCTAssertNotNil(glow)
        XCTAssertTrue(glow?.parent === scene.ball,
                      "the glow rides on the ball; a sibling told the ball's position once a "
                      + "frame is a frame behind it wherever the telling happens")
        XCTAssertEqual(glow?.position, .zero)

        // And it keeps riding when the ball moves, without being told
        scene.ball.position = CGPoint(x: 120, y: 200)
        XCTAssertEqual(glow?.parent?.position, CGPoint(x: 120, y: 200))
    }

    func testTheGlowIsDrawnBehindTheBall() {
        let scene = mayhem()
        scene.endlessIICollectAura()
        scene.tickEndlessIIAura()
        XCTAssertLessThan(scene.endlessIIAuraNodes.first?.zPosition ?? 0, 0,
                          "a child below zero is drawn before its parent's own picture")
    }

    /// "It should grow and shrink with the ball if those power ups are active."
    ///
    /// Increase Ball Size animates `ball.setScale`, and a sprite's `size` carries its scale, so
    /// both halves of this follow from reading the reach off the ball instead of off `ballSize`.
    func testTheRingGrowsWithTheBall() {
        func ringWidth(ballScale: CGFloat) -> CGFloat {
            let scene = mayhem()
            scene.ball.setScale(ballScale)
            scene.endlessIICollectAura()
            scene.tickEndlessIIAura()
            guard let glow = scene.endlessIIAuraNodes.first else { return 0 }
            return glow.size.width*ballScale
            // On screen rather than in the ball's coordinates: a child is drawn through its
            // parent's scale, so its own `size` is deliberately the same at both
        }
        let plain = ringWidth(ballScale: 1)
        XCTAssertGreaterThan(plain, 0)
        XCTAssertEqual(ringWidth(ballScale: 1.5), plain*1.5, accuracy: 0.01,
                       "half again as big a ball wears half again as big a ring")
        XCTAssertEqual(ringWidth(ballScale: 0.5), plain*0.5, accuracy: 0.01,
                       "and a shrunk one wears a smaller one")
    }

    /// What it eats grows with it too, or the picture would be lying.
    func testTheReachGrowsWithTheBallAsWellAsTheRing() {
        func reaches(ballScale: CGFloat) -> Bool {
            let scene = mayhem()
            scene.brickWidth = 40
            scene.brickHeight = 20
            scene.ball.setScale(ballScale)
            scene.ball.position = CGPoint(x: 0, y: 300)
            let brick = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
            brick.name = BrickCategoryName
            brick.position = CGPoint(x: 0, y: 322)
            // The brick's underside is 12 points above the ball's centre. A plain ball's reach
            // is its radius of 5 doubled, so 10 - just short; at 1.5x the radius is 7.5 and the
            // reach is 15, which takes it
            scene.addChild(brick)
            scene.endlessIICollectAura()
            scene.tickEndlessIIAura()
            return scene.endlessIIAuraHitBricks.isEmpty == false
        }
        XCTAssertFalse(reaches(ballScale: 1), "out of reach of an ordinary ball")
        XCTAssertTrue(reaches(ballScale: 1.5), "and inside a grown one's")
    }

    /// The measured contour, said as a ratio rather than as a number to copy.
    func testTheRingIsDrawnWiderThanWhatItEats() {
        let scene = mayhem()
        scene.endlessIICollectAura()
        scene.tickEndlessIIAura()
        let reach = scene.ball.size.width/2*GameScene.endlessIIAuraReach[0]
        let drawn = (scene.endlessIIAuraNodes.first?.size.width ?? 0)/2
        XCTAssertGreaterThan(drawn, reach,
                             "a radial fade has no edge, so the picture has to overhang the "
                             + "circle it eats for the visible part to land on it")
        XCTAssertLessThan(drawn, reach*2, "and not by so much that it is a different circle")
    }
}

/// What a node is actually drawn at, parents included.
///
/// SpriteKit multiplies a child's alpha by its parent's and offers no property for the
/// product, so a test that wants to know whether something can be *seen* has to do the
/// multiplication itself.
extension SKNode {
    var effectiveAlpha: CGFloat {
        sequence(first: self, next: \.parent).map(\.alpha).reduce(1, *)
    }
}
