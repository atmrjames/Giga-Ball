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

    func testTheOriginalEndlessNeverOffersTheFieldBatch() {
        let scene = fieldScene()
        scene.gameMode = .endless
        scene.applyEndlessRowPowerUpWeights()
        for index in 39...45 {
            XCTAssertEqual(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }

        scene.gameMode = .endlessII
        scene.applyEndlessRowPowerUpWeights()
        for index in 39...45 {
            XCTAssertGreaterThan(scene.powerUpProbArray[index], 0, "power-up \(index)")
        }
    }
}
