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
        scene.ballSize = 10
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

    func testABallHeldOnThePaddleIsStillHeldAfterAResume() {
        // A saved ball with no heading was not travelling, which means it was being held.
        // Restored as an ordinary ball it would sit there for ever: nothing launches a ball
        // that is not in the queue
        let scene = stickyScene()
        scene.endlessIIRestoreExtraBalls(from: [
            .init(position: CGPoint(x: 0, y: 0), velocity: .zero),
            .init(position: CGPoint(x: 40, y: 200), velocity: CGVector(dx: 100, dy: 100)),
        ])

        XCTAssertEqual(scene.endlessIIExtraBalls.count, 2)
        XCTAssertEqual(scene.endlessIIHeldBalls.count, 1)
        XCTAssertTrue(scene.endlessIITapLaunchesHeldBall)
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

    override func setUp() {
        super.setUp()
        splashScreenIsShowing = false
        // The host app is a real launch, and its splash screen sets this global on the way
        // past. Left alone, these tests read whatever the app happened to be doing
    }

    override func tearDown() {
        splashScreenIsShowing = false
        super.tearDown()
    }

    private func waitingScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessIIBuildInWaiting = true
        return scene
    }

    func testTheFieldWaitsWhileTheSplashIsUp() {
        let scene = waitingScene()
        splashScreenIsShowing = true

        scene.tickEndlessIIBuildIn(0)
        scene.tickEndlessIIBuildIn(60)
        XCTAssertTrue(scene.endlessIIBuildInWaiting, "started while the splash was up")
    }

    func testTheFieldWaitsWhileTheLevelIntroIsUp() {
        // The cover that was actually hiding it. The splash is only up on a cold launch; the
        // level intro is there every time a run starts
        let scene = waitingScene()
        scene.endlessIILevelIntroShowing = true

        scene.tickEndlessIIBuildIn(0)
        scene.tickEndlessIIBuildIn(60)
        XCTAssertTrue(scene.endlessIIBuildInWaiting, "started behind the level intro")
    }

    func testTheFieldWaitsABeatLongerThanTheCoverSaysTo() {
        // A beat, not a few seconds. The splash clears its flag and then fades; the level
        // intro posts after its view is already off, so this only has the splash to cover
        let scene = waitingScene()
        scene.endlessIILevelIntroShowing = true
        scene.tickEndlessIIBuildIn(0)
        scene.endlessIILevelIntroShowing = false

        scene.tickEndlessIIBuildIn(GameScene.endlessIIBuildInSettle/2)
        XCTAssertTrue(scene.endlessIIBuildInWaiting, "started while the intro was still going")

        scene.tickEndlessIIBuildIn(GameScene.endlessIIBuildInSettle)
        XCTAssertFalse(scene.endlessIIBuildInWaiting)
    }

    func testTheFieldWaitsEvenBeforeACoverHasGoneUp() {
        // The level intro fades in a quarter of a second after the level is built, so a field
        // that started the moment it was asked would already be arriving behind it
        let scene = waitingScene()
        scene.tickEndlessIIBuildIn(0)
        XCTAssertTrue(scene.endlessIIBuildInWaiting)

        scene.tickEndlessIIBuildIn(GameScene.endlessIIBuildInCoverGrace)
        XCTAssertFalse(scene.endlessIIBuildInWaiting)
    }

    func testATapPutsTheFieldUpRatherThanServingTheWait() {
        // Somebody who taps wants to play, and the tap must not launch the ball into a screen
        // with nothing in it yet
        let scene = waitingScene()
        scene.tickEndlessIIBuildIn(0)

        XCTAssertTrue(scene.finishEndlessIIBuildIn())
        XCTAssertFalse(scene.endlessIIBuildInWaiting)
    }
}

/// "The first hit of a fixed brick locks it in place then it becomes a normal multi-hit
/// brick requiring the most hits to destroy it."
final class EndlessIIFixedHardensTests: XCTestCase {

    func testAnchoringTurnsAPlainBrickIntoAFreshMultiHit() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.name = BrickCategoryName
        brick.endlessIIRole = .fixed
        scene.addChild(brick)

        XCTAssertTrue(scene.endlessIIAnchorIfNeeded(brick))
        XCTAssertTrue(brick.endlessIIIsAnchored)
        XCTAssertEqual(brick.texture, scene.brickMultiHit1Texture,
                       "the anchor now costs the full multi-hit ladder to dig out")
    }

    func testABrickThatWasAlreadyMultiHitKeepsItsOwnLadder() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let brick = SKSpriteNode(texture: scene.brickMultiHit3Texture)
        brick.name = BrickCategoryName
        brick.endlessIIRole = .fixed
        scene.addChild(brick)

        scene.endlessIIAnchorIfNeeded(brick)
        XCTAssertEqual(brick.texture, scene.brickMultiHit3Texture,
                       "two hits already taken are not refunded")
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

    func testTheBestHeightKeepsItsOwnColour() {
        // "It's changing colours to white and giga-ball green yellow as if certain multipliers
        // have been reached. In Endless 2.0 the multiplier isn't part of the game at all."
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        scene.totalStatsArray[0].endlessIIModeHeight = [200]

        scene.showEndlessIIBest()
        let painted = scene.multiplierLabel.fontColor
        scene.setMultiplierColour(.green)

        XCTAssertEqual(scene.multiplierLabel.fontColor, painted)
    }

    func testTheMultiplierIsStillPaintedWhereThereIsOne() {
        let scene = GameScene()
        scene.endlessMode = false
        scene.setMultiplierColour(.green)
        XCTAssertEqual(scene.multiplierLabel.fontColor, .green)
    }

    func testTheMultiplierStillShowsInTheModesThatHaveOne() {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.endlessMode = false
        scene.scoreFactorString = "2.0"
        scene.showMultiplier()

        let drawn = scene.multiplierLabel.childNode(withName: "digits")?.children
            .compactMap { ($0 as? SKLabelNode) }
            .filter { $0.isHidden == false }
            .sorted { $0.position.x < $1.position.x }
            .compactMap(\.text)
            .joined()
        XCTAssertEqual(drawn, "x2.0")
        // Read off the characters actually drawn rather than the label's own `text`: the
        // HUD numbers are placed one character at a time now so they stop dancing as they
        // change (play-test rounds 18 and 19). What is on screen is what this test was
        // always asking about
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

/// "Endless Mode menu view table scores have no dates. Why is that?"
final class EndlessRunDatePairingTests: XCTestCase {

    private let day = TimeInterval(60*60*24)

    func testEveryRunGetsItsOwnDateWhenTheListsMatch() {
        let dates = [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 100)]
        let paired = LevelStatsViewController.pair([10, 20], with: dates)

        XCTAssertEqual(paired.map(\.height), [10, 20])
        XCTAssertEqual(paired.map(\.date), dates)
    }

    func testTheRunsWithoutDatesAreTheOldOnes() {
        // The bug in the report. Dates were added to the save long after heights were, so a
        // player from before that has more heights than dates - and pairing from the start
        // left the *newest* runs undated, which are the ones at the top of the list
        let recent = [Date(timeIntervalSince1970: 900), Date(timeIntervalSince1970: 1000)]
        let paired = LevelStatsViewController.pair([10, 20, 30, 40], with: recent)

        XCTAssertNil(paired[0].date, "the oldest run predates dates being recorded")
        XCTAssertNil(paired[1].date)
        XCTAssertEqual(paired[2].date, recent[0])
        XCTAssertEqual(paired[3].date, recent[1], "the newest run has the newest date")
    }

    func testNoDatesAtAllIsNotACrash() {
        let paired = LevelStatsViewController.pair([10, 20], with: [])
        XCTAssertEqual(paired.count, 2)
        XCTAssertTrue(paired.allSatisfy { $0.date == nil })
    }

    func testMoreDatesThanHeightsStillPairsTheHeightsItHas() {
        // Heights synced from another device can arrive without their dates, and the reverse
        // is possible too. Neither may drop a run from the list
        let dates = (0..<3).map { Date(timeIntervalSince1970: TimeInterval($0)) }
        XCTAssertEqual(LevelStatsViewController.pair([10], with: dates).count, 1)
    }
}

/// "Auto-Aim should skip bricks that are pointless to hit - indestructibles, anything whose
/// hit does nothing, and bad-power-up bricks - and aim at the next nearest worth hitting."
final class EndlessIIAutoAimTargetTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        return scene
    }

    private func brick(in scene: GameScene, at point: CGPoint = .zero) -> SKSpriteNode {
        let brick = SKSpriteNode()
        brick.name = BrickCategoryName
        brick.position = point
        brick.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 5))
        brick.physicsBody?.categoryBitMask = CollisionTypes.brickCategory.rawValue
        scene.addChild(brick)
        return brick
    }

    func testAnOrdinaryBrickIsWorthTheShot() {
        let scene = scene()
        XCTAssertTrue(scene.endlessIIWorthAimingAt(brick(in: scene)))
    }

    func testAPortalIsNot() {
        let scene = scene()
        let portal = brick(in: scene)
        portal.endlessIIRole = .portal
        XCTAssertFalse(scene.endlessIIWorthAimingAt(portal))
    }

    func testAnIndestructibleIsNot() {
        let scene = scene()
        let solid = brick(in: scene)
        solid.texture = scene.brickIndestructible1Texture
        XCTAssertFalse(scene.endlessIIWorthAimingAt(solid))
    }

    func testABrickHoldingABadPowerUpIsNot() {
        // A free shot that sets off Lose A Ball is not a free shot
        let scene = scene()
        let trap = brick(in: scene)
        trap.endlessIIPowerUpIndex = 1
        XCTAssertFalse(scene.endlessIIWorthAimingAt(trap))
    }

    func testABrickThatIsPassableRightNowIsNot() {
        // A Flashing brick in its faded phase has no collision category, so the shot would
        // go straight through it - "anything whose hit does nothing"
        let scene = scene()
        let ghost = brick(in: scene)
        ghost.physicsBody?.categoryBitMask = 0
        XCTAssertFalse(scene.endlessIIWorthAimingAt(ghost))
    }

    func testADirectionalBrickThatCanOnlyBeHurtFromAboveIsNot() {
        let scene = scene()
        let armoured = brick(in: scene)
        armoured.endlessIIRole = .directional
        armoured.endlessIIVulnerableSide = .top
        XCTAssertFalse(scene.endlessIIWorthAimingAt(armoured))
    }

    func testADirectionalBrickHurtFromBelowOrTheSideStillIs() {
        // A shot arrives at the underside, and a brick up and to one side can be met on its
        // flank - those shots are not wasted
        for side in [EndlessIISide.bottom, .left, .right] {
            let scene = scene()
            let angled = brick(in: scene)
            angled.endlessIIRole = .directional
            angled.endlessIIVulnerableSide = side
            XCTAssertTrue(scene.endlessIIWorthAimingAt(angled), "\(side)")
        }
    }

    func testTheShotGoesToTheLowestBrickWorthHitting() {
        let scene = scene()
        let lowIndestructible = brick(in: scene, at: CGPoint(x: 0, y: 10))
        lowIndestructible.texture = scene.brickIndestructible1Texture
        let worthIt = brick(in: scene, at: CGPoint(x: 40, y: 60))

        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero), worthIt.position,
                       "the lowest brick was one the shot cannot change")
    }

    func testNearestWinsAmongBricksOnTheSameRow() {
        let scene = scene()
        _ = brick(in: scene, at: CGPoint(x: 90, y: 30))
        let near = brick(in: scene, at: CGPoint(x: 12, y: 30))
        XCTAssertEqual(scene.endlessIIAutoAimTarget(from: .zero), near.position)
    }

    func testAFieldWithNothingWorthHittingAimsAtNothing() {
        // Rather than aiming at the one thing it was told not to
        let scene = scene()
        let portal = brick(in: scene)
        portal.endlessIIRole = .portal
        XCTAssertNil(scene.endlessIIAutoAimTarget(from: .zero))
    }
}

/// "Aura is still too powerful." The decided shape: the ball bounces off bricks normally,
/// and bricks the glow reaches take the effect of a *single hit* rather than being destroyed.
final class EndlessIIAuraTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        return scene
    }

    private func ball(at point: CGPoint) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        node.position = point
        return node
    }

    private func brick(at point: CGPoint) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 20, height: 10))
        node.name = BrickCategoryName
        node.position = point
        return node
    }

    func testTheGlowReachesABrickBesideTheBall() {
        let scene = scene()
        let subject = ball(at: .zero)
        XCTAssertTrue(scene.endlessIIAuraReaches(brick(at: CGPoint(x: 22, y: 0)),
                                                 from: subject, reach: 40))
    }

    func testTheGlowDoesNotClaimTheBrickTheBallIsTouching() {
        // That one is the ball's own business, and it bounces off it as ever. The aura's
        // gift is the bricks beside the one being struck
        let scene = scene()
        let subject = ball(at: .zero)
        XCTAssertFalse(scene.endlessIIAuraReaches(brick(at: CGPoint(x: 2, y: 0)),
                                                  from: subject, reach: 40))
    }

    func testABrickOutOfReachIsUntouched() {
        let scene = scene()
        let subject = ball(at: .zero)
        XCTAssertFalse(scene.endlessIIAuraReaches(brick(at: CGPoint(x: 400, y: 0)),
                                                  from: subject, reach: 40))
    }

    func testReachGrowsWithASecondCollection() {
        // Stacking deepens it (§5.4), and the deeper reach has to actually be further
        XCTAssertGreaterThan(GameScene.endlessIIAuraReach[1], GameScene.endlessIIAuraReach[0])
    }

    func testTheAuraIsNoLongerAWiderGigaBall() {
        // The whole point of the rework: reach is a boundary, not a kill radius. A brick
        // inside it is hit once, and what a hit means is the brick type's own business
        let scene = scene()
        let subject = ball(at: .zero)
        let beside = brick(at: CGPoint(x: 22, y: 0))
        scene.addChild(beside)

        XCTAssertTrue(scene.endlessIIAuraReaches(beside, from: subject, reach: 40))
        XCTAssertNotNil(beside.parent, "reaching it is not the same as removing it")
    }

    /// Play-test screenshot: "a Big brick's body extends past its row centre, so on the
    /// bottom row its lower half crosses the limit line" - and covered it. The line is the
    /// kill line and has to stay legible, so it draws over the field rather than under it.
    func testTheKillLineDrawsAboveTheBricksAndBelowTheBall() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.showEndlessIILowerLimit()

        guard let line = scene.endlessIILowerLimitLine else {
            return XCTFail("the lower limit line was never made")
        }
        XCTAssertGreaterThan(line.zPosition, 1,
                             "a Big brick sits at 1 and would cover the line it crosses")
        XCTAssertLessThan(line.zPosition, 3,
                          "the ball and paddle are at 3 and must stay in front of it")
    }

    /// Play-test round 87, and the most expensive bug of that round: "with aimed sticky at
    /// one point the new bricks continued to descend whilst the old bricks stay paused", and
    /// after resuming "bricks continued to descend below the paddle". The aim hold stops the
    /// ticking world, and the descent is not ticked - it is triggered by the bottom row
    /// emptying - so it went on stepping while everything else stood still.
    func testTheFieldDoesNotDescendWhileTheAimIsHeld() {
        let scene = GameScene()
        scene.gameMode = .endlessII

        XCTAssertFalse(scene.endlessIIFieldIsHeld, "nothing held, nothing frozen")

        scene.endlessIIAimHold = true
        XCTAssertTrue(scene.endlessIIFieldIsHeld)

        scene.endlessIIAimHold = false
        scene.endlessIIAimedStickyOwedTurn = true
        XCTAssertTrue(scene.endlessIIFieldIsHeld,
                      "the turn owed is still an aim, and the field must wait for it too")
    }

    /// Play-test round 100: "if it was today or yesterday, write that instead of the
    /// date". A run from today must not name its date; an older run must.
    func testRunDatesReadTodayAsAWordAndOlderRunsAsDates() {
        let format = LevelStatsViewController.runDateFormat
        XCTAssertTrue(format.doesRelativeDateFormatting)

        let today = format.string(from: Date())
        XCTAssertFalse(today.contains("202"),
                       "a run from today should carry no year, only the word and a time")

        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        XCTAssertTrue(format.string(from: lastWeek).contains("202"),
                      "anything older than yesterday keeps the full date")
    }
}

/// "The landing marker is slightly off, and it looks worse at shallow angles - as if it's
/// expecting the ball to travel a little further before it contacts the paddle." It was:
/// the bounds handed to the predictor named the paddle's centre line, so the prediction
/// ran half a paddle deeper than the surface the ball actually meets.
final class EndlessIILandingMarkerGeometryTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.gameWidth = 400
        scene.paddleHeight = 12
        scene.paddle.position = CGPoint(x: 0, y: -300)
        return scene
    }

    func testTheBoundsNameThePaddlesTopNotItsCentre() {
        let scene = scene()
        XCTAssertEqual(scene.endlessIIVisionBounds().paddleLine,
                       scene.paddle.position.y + scene.paddleHeight/2,
                       "the same surface catchStickyBallBeforeStep judges against")
    }

    func testAShallowApproachLandsWhereTheBallActuallyArrives() {
        let scene = scene()
        let radius: CGFloat = 5

        let landing = BallPath.predict(
            from: CGPoint(x: -100, y: -200), velocity: CGVector(dx: 100, dy: -50),
            radius: radius, bounds: scene.endlessIIVisionBounds(), bricks: []).landing

        XCTAssertEqual(landing?.y ?? 0,
                       scene.paddle.position.y + scene.paddleHeight/2 + radius,
                       accuracy: 0.001,
                       "the ball's centre stops a radius above the paddle's top")
        XCTAssertEqual(landing?.x ?? 0, 78, accuracy: 0.001,
                       "89 down at 2:1 is 178 across - and every extra point of depth "
                       + "would push the mark 2 points sideways, which is the round-97 "
                       + "report: worse at shallow angles")
    }
}
