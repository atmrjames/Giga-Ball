//
//  EndlessIIPlayTestFixesTests.swift
//  GigaBallTests
//
//  Written from a play-test report, in the terms it was reported in. Each of these is a
//  sentence somebody typed after playing the build, turned into the question the code has to
//  keep answering the same way.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

/// "The power-up brick appeared, but the power-up was not applied when the brick was hit."
final class EndlessIIPowerUpBrickTriggerTests: XCTestCase {

    func testABrickUsesTheSceneUsesTheSameTextureTheSwitchCompares() {
        // The whole bug. `applyPowerUp` decides what to do by comparing the sprite's texture
        // against the ones the scene holds, and a texture built from the same image is a
        // different texture - so the brick broke, was counted, and did nothing at all
        let scene = GameScene()
        scene.gameMode = .endlessII
        guard scene.powerUpTextureArray.isEmpty == false else { return }

        for index in scene.powerUpTextureArray.indices {
            XCTAssertTrue(scene.endlessIIPowerUpTexture(index) === scene.powerUpTextureArray[index],
                          "power-up \(index) would set off nothing")
        }
    }

    func testAnIndexTheSceneDoesNotHaveStillGivesATexture() {
        // Rather than trapping. The arrays are grown in several places when a power-up is
        // added, and this is read at the moment a brick is built
        let scene = GameScene()
        XCTAssertNotNil(scene.endlessIIPowerUpTexture(scene.powerUpTextureArray.count))
    }
}

/// "No more than 1 power-up brick should be in play at one time."
final class EndlessIIPowerUpBrickCountTests: XCTestCase {

    private func brick(holding index: Int) -> SKSpriteNode {
        let node = SKSpriteNode()
        node.name = BrickCategoryName
        node.endlessIIPowerUpIndex = index
        return node
    }

    func testTheSceneCountsThePowerUpBricksOnTheField() {
        let scene = GameScene()
        XCTAssertTrue(scene.endlessIIPowerUpBricksInPlay.isEmpty)

        scene.addChild(brick(holding: 3))
        XCTAssertEqual(scene.endlessIIPowerUpBricksInPlay.count, 1)
    }

    func testAnOrdinaryBrickIsNotCountedAsAPowerUpBrick() {
        let scene = GameScene()
        let plain = SKSpriteNode()
        plain.name = BrickCategoryName
        scene.addChild(plain)
        XCTAssertTrue(scene.endlessIIPowerUpBricksInPlay.isEmpty)
    }

    func testASecondOneIsNeverBuiltWhileTheFirstIsStillInPlay() {
        // Two of these on screen is two shots you have to not take
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.addChild(brick(holding: 0))

        XCTAssertNil(scene.endlessIIMakePowerUpBrick(column: 0, rowY: 0))
        XCTAssertEqual(scene.endlessIIPowerUpBricksInPlay.count, 1)
    }
}

/// "For multi-ball a sticky paddle should catch both balls. On release, the first ball caught
/// goes first, then the second ball on the next tap."
final class EndlessIIStickyPaddleQueueTests: XCTestCase {

    private func stickyScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.stickyPaddleCatches = 4
        scene.stickyPaddleCatchesTotal = 4
        scene.addChild(scene.ball)
        // The first ball is always in the scene during play, and the queue skips anything
        // that has left it
        return scene
    }

    private func extraBall(in scene: GameScene, x: CGFloat) -> SKSpriteNode {
        let extra = SKSpriteNode()
        extra.name = BallCategoryName
        extra.position = CGPoint(x: x, y: 0)
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        extra.physicsBody?.velocity = CGVector(dx: 10, dy: -100)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)
        return extra
    }

    func testAnExtraBallIsCaughtRatherThanBounced() {
        let scene = stickyScene()
        let extra = extraBall(in: scene, x: 0)

        XCTAssertTrue(scene.endlessIICatchExtraBall(extra))
        XCTAssertEqual(extra.physicsBody?.velocity.dx, 0)
        XCTAssertEqual(extra.physicsBody?.velocity.dy, 0)
        XCTAssertTrue(scene.endlessIIHasHeldExtras)
    }

    func testNothingIsCaughtWithoutTheStickyPaddle() {
        let scene = stickyScene()
        scene.stickyPaddleCatches = 0
        let extra = extraBall(in: scene, x: 0)

        XCTAssertFalse(scene.endlessIICatchExtraBall(extra))
        XCTAssertFalse(scene.endlessIIHasHeldExtras)
    }

    func testCatchingTheSameBallTwiceDoesNotQueueItTwice() {
        // Contacts arrive more than once while a ball rests against the paddle
        let scene = stickyScene()
        let extra = extraBall(in: scene, x: 0)

        scene.endlessIICatchExtraBall(extra)
        scene.endlessIICatchExtraBall(extra)
        XCTAssertEqual(scene.endlessIIHeldBalls.count, 1)
    }

    func testTheFirstBallCaughtIsTheFirstToLeave() {
        let scene = stickyScene()
        let first = extraBall(in: scene, x: -20)
        let second = extraBall(in: scene, x: 20)

        scene.endlessIICatchExtraBall(first)
        scene.endlessIICatchExtraBall(second)

        XCTAssertTrue(scene.endlessIINextHeldBall === first)
        scene.endlessIILaunchHeldBall()
        XCTAssertTrue(scene.endlessIINextHeldBall === second)
        scene.endlessIILaunchHeldBall()
        XCTAssertNil(scene.endlessIINextHeldBall)
    }

    func testAFirstBallCaughtLastGoesLast() {
        // The reason the first ball is in the queue rather than handled beside it
        let scene = stickyScene()
        let extra = extraBall(in: scene, x: -20)

        scene.endlessIICatchExtraBall(extra)
        scene.endlessIIFirstBallWasCaught()

        XCTAssertTrue(scene.endlessIITapLaunchesHeldBall, "the extra was caught first")
        scene.endlessIILaunchHeldBall()
        XCTAssertFalse(scene.endlessIITapLaunchesHeldBall, "now it is the first ball's turn")
        XCTAssertTrue(scene.endlessIINextHeldBall === scene.ball)
    }

    func testATapBelongsToTheFirstBallWhenNothingElseIsHeld() {
        let scene = stickyScene()
        XCTAssertFalse(scene.endlessIITapLaunchesHeldBall)
    }

    func testOtherModesNeverHoldMoreThanOneBall() {
        for mode in [GameMode.classic, .endless] {
            let scene = stickyScene()
            scene.gameMode = mode
            let extra = extraBall(in: scene, x: 0)

            XCTAssertFalse(scene.endlessIICatchExtraBall(extra), "\(mode)")
            XCTAssertFalse(scene.endlessIITapLaunchesHeldBall, "\(mode)")
        }
    }

    func testLaunchingAHeldBallSpendsACatch() {
        let scene = stickyScene()
        let extra = extraBall(in: scene, x: 0)
        scene.endlessIICatchExtraBall(extra)

        scene.endlessIILaunchHeldBall()
        XCTAssertEqual(scene.stickyPaddleCatches, 3)
    }

    func testALaunchedBallLeavesTowardsTheSideItWasCaughtOn() {
        // The same rule the first ball launches by: caught left, leaves left
        let scene = stickyScene()
        XCTAssertGreaterThan(scene.endlessIILaunchAngle(atPaddleOffset: -1),
                             scene.endlessIILaunchAngle(atPaddleOffset: 1))
    }

    func testAnAngleIsNeverReadFromOffThePaddle() {
        // A ball can be caught with its centre past the paddle's end
        let scene = stickyScene()
        XCTAssertEqual(scene.endlessIILaunchAngle(atPaddleOffset: -4),
                       scene.endlessIILaunchAngle(atPaddleOffset: -1))
        XCTAssertEqual(scene.endlessIILaunchAngle(atPaddleOffset: 4),
                       scene.endlessIILaunchAngle(atPaddleOffset: 1))
    }

    func testABallLostWhileHeldLeavesTheQueue() {
        let scene = stickyScene()
        let first = extraBall(in: scene, x: -20)
        let second = extraBall(in: scene, x: 20)
        scene.endlessIICatchExtraBall(first)
        scene.endlessIICatchExtraBall(second)

        first.removeFromParent()
        XCTAssertTrue(scene.endlessIINextHeldBall === second)
    }
}

/// "One the return from pause count down, the second multi-ball continued before the countdown
/// had finished."
final class EndlessIIPauseHoldsEveryBallTests: XCTestCase {

    func testEveryBallsHeadingIsRecordedBeforeItIsStopped() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        let extra = SKSpriteNode()
        extra.name = BallCategoryName
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        extra.physicsBody?.velocity = CGVector(dx: 120, dy: -200)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)

        scene.endlessIIRecordExtraBallVelocities()
        XCTAssertEqual(scene.pauseExtraBallVelocities, [CGVector(dx: 120, dy: -200)])
    }

    func testASecondRecordingDoesNotOverwriteTheFirstWithZeroes() {
        // It runs on the way into the pause menu and again on the way out, and by the second
        // run the velocities it would read have already been zeroed by the first
        let scene = GameScene()
        scene.gameMode = .endlessII
        let extra = SKSpriteNode()
        extra.name = BallCategoryName
        extra.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        extra.physicsBody?.velocity = CGVector(dx: 120, dy: -200)
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)

        scene.endlessIIRecordExtraBallVelocities()
        extra.physicsBody?.velocity = .zero
        scene.endlessIIRecordExtraBallVelocities()

        XCTAssertEqual(scene.pauseExtraBallVelocities, [CGVector(dx: 120, dy: -200)])
    }
}

/// "Build-in animation is still behind the splash screen."
final class EndlessIIBuildInTimingTests: XCTestCase {

    private func waitingScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessIIBuildInWaiting = true
        return scene
    }

    func testTheFieldWaitsWhileTheSplashIsUp() {
        let scene = waitingScene()
        splashScreenIsShowing = true
        defer { splashScreenIsShowing = false }

        scene.tickEndlessIIBuildIn(0)
        XCTAssertTrue(scene.endlessIIBuildInWaiting)
    }

    func testTheFieldWaitsABeatLongerThanTheSplashSaysTo() {
        // The splash clears its flag and then animates out over the top of the scene, so the
        // moment it says it has gone is the moment it starts going
        let scene = waitingScene()
        splashScreenIsShowing = true
        scene.tickEndlessIIBuildIn(0)
        splashScreenIsShowing = false

        scene.tickEndlessIIBuildIn(1)
        XCTAssertTrue(scene.endlessIIBuildInWaiting, "started while the splash was fading")

        scene.tickEndlessIIBuildIn(1 + GameScene.endlessIIBuildInSplashDelay)
        XCTAssertFalse(scene.endlessIIBuildInWaiting)
    }

    func testNothingIsWaitedForWhenThereWasNoSplash() {
        // Reached from the menu. A delay here would be a run that opens with a blank field
        let scene = waitingScene()
        splashScreenIsShowing = false

        scene.tickEndlessIIBuildIn(0)
        XCTAssertFalse(scene.endlessIIBuildInWaiting)
    }
}

/// "Best score below current score is still not showing."
final class EndlessIIBestHeightLabelTests: XCTestCase {

    func testTheLabelCarriesTheBestHeightInEndlessMode() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].endlessIIModeHeight = [40, 120, 90]

        scene.showEndlessIIBest()
        XCTAssertFalse(scene.multiplierLabel.isHidden)
        XCTAssertEqual(scene.multiplierLabel.text, "BEST 120m")
    }

    func testTheLabelIsHiddenWhenThereIsNoBestYet() {
        // The states used to hide it outright in endless mode, a third of a second after the
        // level load showed it. Now they ask this instead, so it has to answer both ways
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].endlessIIModeHeight = []

        scene.multiplierLabel.isHidden = false
        scene.showEndlessIIBest()
        XCTAssertTrue(scene.multiplierLabel.isHidden)
    }

    func testTheMultiplierNeverOverwritesTheBestHeight() {
        // "Best score is now showing, but immediately turns to a multiplier when a brick is
        // hit." Five places wrote the multiplier straight into this label
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].endlessIIModeHeight = [77]

        scene.showEndlessIIBest()
        scene.scoreFactorString = "1.0"
        scene.showMultiplier()

        XCTAssertEqual(scene.multiplierLabel.text, "BEST 77m")
    }

    func testTheMultiplierStillShowsInTheModesThatHaveOne() {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.endlessMode = false
        scene.scoreFactorString = "2.0"
        scene.showMultiplier()

        XCTAssertEqual(scene.multiplierLabel.text, "x2.0")
    }

    func testEachEndlessModeReadsItsOwnBest() {
        let scene = GameScene()
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].endlessIIModeHeight = [500]
        scene.totalStatsArray[0].endlessModeHeight = [70]

        scene.gameMode = .endless
        XCTAssertEqual(scene.endlessBestHeight, 70)
        scene.gameMode = .endlessII
        XCTAssertEqual(scene.endlessBestHeight, 500)
    }
}
