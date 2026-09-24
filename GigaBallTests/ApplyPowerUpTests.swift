//
//  ApplyPowerUpTests.swift
//  GigaBallTests
//
//  Every power-up, collected.
//
//  `applyPowerUp` is the single riskiest function in the app by the CRAP metric James asked to
//  keep using: complexity 168, coverage 1%, thirteen hundred executable lines. It is the one
//  funnel every collection passes through, and it is a switch with sixty-five arms, each one
//  reaching into a different corner of the scene.
//
//  What makes it worth testing is not the arithmetic in any one arm. It is CLAUDE.md's widest
//  trap: "adding a power-up lengthens about a dozen parallel arrays", and this is where the
//  texture that identifies one is turned into the counter that records it. A copy-pasted arm
//  that bumps its neighbour's counter is invisible from every other angle - the power-up works,
//  the stats page is quietly wrong, and no existing test looks.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ApplyPowerUpTests: XCTestCase {

    /// The pair the sweep is inside, so a crash can say which one it was.
    ///
    /// **An ObjC exception is not an assertion.** It unwinds the test method where it is
    /// thrown, so a sweep of thousands of pairs reports "attempt to insert nil object" with no
    /// word about which pair was being collected - which is most of the information. The pair
    /// is written here as it starts and cleared when the sweep finishes, and `tearDown` says
    /// what it was holding if the sweep never got there.
    private var pairUnderTest: String?

    override func tearDown() {
        if let pair = pairUnderTest {
            XCTFail("the sweep stopped inside '\(pair)'")
        }
        pairUnderTest = nil
        super.tearDown()
    }

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 360
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.hapticsSetting = false
        scene.soundsSetting = false
        scene.ballLostBool = false
        // **It starts true.** A scene begins with no ball in play, and `applyPowerUp` refuses
        // everything while that is so - which is right, and is also how the first draft of the
        // multiplier test below spent two runs measuring nothing
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 90, height: 12)
        // The preconditions a running game always meets. `applyPowerUp` force-unwraps the
        // ball's body - a Lose a Life sets its damping - and a scene that has not been through
        // `didMove` has neither ball nor paddle in it
        // `didMove` fills this from the same property, and `didMove` wants a presented .sks
        // scene with a dozen named children in it. The order is what a test needs, and the
        // order is now readable on its own
        // The two that reach outside the process. CLAUDE.md's round 306 finding is that a
        // simulator has no audio server and every wait for one is charged to the batch
        return scene
    }

    private func drop(_ texture: SKTexture, on scene: GameScene) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture)
        node.name = PowerUpCategoryName
        scene.addChild(node)
        return node
    }

    /// Collecting a power-up records *that* power-up.
    ///
    /// The arrays are indexed together: `powerUpTexturesInOrder[i]` is the picture,
    /// `powerupsCollected[i]` is the tally. The switch is written by texture and has to arrive
    /// at the same `i`, sixty-five times, by hand.
    ///
    /// **One scene, not one per power-up.** Every `GameScene` builds sixty-five textures out of
    /// drawn artwork as it is initialised, so a scene each was four thousand of them and UIKit
    /// gave out partway through with `-[UIImageConfiguration bufferId]: unrecognized selector`.
    /// The tally is reset instead, which is the only state this asks about.
    func testEveryPowerUpRecordsItself() {
        let scene = self.scene()
        let all = scene.powerUpTexturesInOrder
        XCTAssertGreaterThan(all.count, 60, "the list is empty, so this test proves nothing")

        var wrong: [String] = []
        let names = LevelPackSetup().powerUpNameArray

        for (index, texture) in all.enumerated() {
            scene.totalStatsArray = [TotalStats()]
            scene.ballLostBool = false
            let node = drop(texture, on: scene)
            scene.applyPowerUp(node: node, silently: true)

            let tally = scene.totalStatsArray[0].powerupsCollected
            let counted = tally.indices.filter { tally[$0] > 0 }
            let name = index < names.count ? names[index] : "#\(index)"

            if counted != [index] {
                wrong.append("\(name) (\(index)) bumped \(counted)")
            }
        }

        XCTAssertEqual(wrong, [],
                       "a power-up that records itself as another one is a stats page that is "
                       + "quietly wrong for ever: \n" + wrong.joined(separator: "\n"))
    }

    /// And it does not crash on the way, which for a switch this size is worth its own line.
    func testEveryPowerUpCanBeCollected() {
        let scene = self.scene()
        let all = scene.powerUpTexturesInOrder
        XCTAssertGreaterThan(all.count, 60, "the list is empty, so this test proves nothing")

        for texture in all {
            scene.ballLostBool = false
            let node = drop(texture, on: scene)
            scene.applyPowerUp(node: node, silently: true)
        }
    }

    /// The tally has a slot for every power-up there is.
    ///
    /// Read off the list rather than written down, which is the rule that has caught most of
    /// the parallel-array misses: a table one short is a power-up that can never be recorded.
    func testTheTallyIsAsLongAsTheList() {
        XCTAssertGreaterThanOrEqual(TotalStats().powerupsCollected.count,
                                    scene().powerUpTexturesInOrder.count,
                                    "every power-up needs somewhere to be counted")
    }

    /// The crash the sweep found on its first arm.
    ///
    /// Extra Ball rolls a gained life into the row, and `rollInGainedLife` ran
    /// `shown..<lifeIcons.count` - a range that traps when the lower bound is above the upper,
    /// which is the shape of round 312's `Int.random(in: 0...(-1))`. It needs a scene whose
    /// life icons have not been built, which is what a scene that has not been through
    /// `didMove` is, and two of the three uses of `lifeIcons` in that function were already
    /// defended against exactly that.
    func testAGainedLifeDoesNotTrapBeforeTheIconsExist() {
        let scene = self.scene()
        XCTAssertTrue(scene.lifeIcons.isEmpty, "this is the state being defended against")

        scene.numberOfLives = 3
        scene.rollInGainedLife()
        // Trapped here before the clamp

        scene.numberOfLives = 1
        scene.rollInGainedLife()
    }

    /// One collection's multiplier change does not carry into the next.
    ///
    /// `powerUpScore` is reset before the switch and `powerUpMultiplierScore` was not, and
    /// afterwards the scene runs `multiplier = Scoring.adjusted(multiplier, by:)` on it - so an
    /// arm that never sets it applied the *previous* collection's change a second time.
    /// Sixty-four of the sixty-five set it, which is why nothing ever showed. The one that does
    /// not is Multi-Ball, so catching one after a bad power-up docked the multiplier again.
    func testAMultiplierChangeDoesNotCarryIntoTheNextCollection() {
        let scene = self.scene()
        let all = scene.powerUpTexturesInOrder

        scene.powerUpMultiplierScore = -0.1
        // Where a bad power-up leaves it. Set directly rather than by collecting one, because
        // the obvious way to arrange it - collect a Lose a Life first - sets `ballLostBool`,
        // and the next collection is then refused at the top of the function

        scene.multiplier = 2
        scene.applyPowerUp(node: drop(all[28], on: scene), silently: true)

        XCTAssertEqual(scene.totalStatsArray[0].powerupsCollected[28], 1,
                       "the collection has to have happened for this to be about anything")
        XCTAssertEqual(scene.powerUpMultiplierScore, 0,
                       "Multi-Ball sets none, so it must find none")
        XCTAssertEqual(scene.multiplier, 2, accuracy: 0.0001,
                       "and the multiplier is left where the last power-up put it")
    }

    /// A ball already lost takes nothing with it.
    func testNothingIsCollectedAfterTheBallIsLost() {
        let scene = self.scene()
        scene.ballLostBool = true
        let node = drop(scene.powerUpTexturesInOrder[0], on: scene)
        scene.applyPowerUp(node: node, silently: true)

        XCTAssertEqual(scene.totalStatsArray[0].powerupsCollected.reduce(0, +), 0,
                       "the run is over; the drop cannot be caught")
    }
}

/// **The Mayhem events and the sounds they are waiting for** (§8.5, round 314).
///
/// James is writing the sounds; the code is wired to play them the moment a file appears under
/// the right name, so he needs nothing from here to iterate. **Six have arrived** (rounds 327b
/// and 327c), which is what this class now has to say: the delivered ones resolve, the awaited
/// ones are still silence rather than a crash, and the three portal events find the one
/// recording they share.
final class MayhemSoundTests: XCTestCase {

    /// Delivered, and therefore expected to resolve. The portal jump is one recording for three
    /// events, so it is listed under its own name rather than theirs.
    private let delivered = ["explosion", "cull", "infill", "spawner", "laserBeam", "portalJump"]

    /// Still to be made. Each is silence and a haptic until it is.
    private let names = ["aura", "brickLocked", "paddleHalo", "multiBall",
                         "safetyPaddle", "mirrorPaddle", "drift"]

    /// The three that have no file of their own and play the shared jump instead.
    private let sharingThePortalJump = ["brickPortal", "paddlePortal", "wrapAround"]

    func testTheDeliveredSoundsAreFound() {
        for name in delivered {
            XCTAssertNotNil(GameScene.mayhemSound(name),
                            "\(name) is in Megaball/Sounds and in the Resources phase, so the "
                            + "bundle lookup has to find it")
        }
    }

    /// **A name with no file of its own falls through to the shared one** (round 327b). James
    /// delivered `portalJump` for "either portal brick, or portal paddle, or wrap-around", and
    /// naming the event first keeps that a default: a `brickPortal` recording would win the day
    /// it lands, with nothing to rewire.
    func testThePortalEventsFallBackToTheSharedRecording() {
        for name in sharingThePortalJump {
            XCTAssertNil(GameScene.mayhemSound(name), "\(name) has no recording of its own yet")
        }
        XCTAssertNotNil(GameScene.mayhemSound("portalJump"),
                        "which is why the fallback has to resolve")
    }

    /// **Nil until the file exists, and never a crash.**
    ///
    /// `SKAction.playSoundFileNamed` is handed a name at property-initialisation time for the
    /// ten sounds the game already has, and what it does with a name that has no file behind
    /// it is not something to discover on a player's device. `mayhemSound` asks the bundle
    /// first, so an unrecorded sound is silence and a haptic - exactly what these events do
    /// today, which is what makes wiring them up ahead of the audio a safe thing to do.
    func testAnUnrecordedSoundIsSilenceRatherThanAnything() {
        for name in names {
            XCTAssertNil(GameScene.mayhemSound(name),
                         "\(name) has no recording yet, so this has to answer nil")
        }
    }

    /// And asking twice is the same answer, because these fire mid-play.
    func testTheAnswerIsKept() {
        for name in names {
            XCTAssertNil(GameScene.mayhemSound(name))
            XCTAssertNil(GameScene.mayhemSound(name), "\(name): asked twice, cached once")
        }
    }

    /// A scene with sounds switched off plays nothing, and one with them on plays nothing
    /// either while the files are missing. Neither may throw.
    func testPlayingOneIsSafeWithOrWithoutTheSetting() {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        for setting in [true, false] {
            scene.soundsSetting = setting
            for name in names + delivered + sharingThePortalJump {
                scene.playMayhemSound(name)
                scene.playMayhemSound(name, or: "portalJump")
            }
        }
    }

    /// The ten that do exist still resolve, so the bundle check is not simply always false.
    ///
    /// Without this the three tests above would pass just as well if `mayhemSound` returned
    /// nil unconditionally, and the day James adds a file nothing would play.
    func testASoundThatDoesExistIsFound() {
        XCTAssertNotNil(GameScene.mayhemSound("brickHit"),
                        "brickHit.mp3 ships with the app, so the bundle lookup has to find "
                        + "it - or these tests are asserting that a broken lookup is broken")
    }
}

/// **Every power-up collected on top of every other one** (James, round 329: "make sure all the
/// power-ups are working as intended, including all the interactions between the different
/// power-ups").
///
/// Sixty-five power-ups make 4,225 ordered pairs, which is far past what anybody can play - and
/// the pairs are where this game's faults have actually lived: an Expand caught while a Shrink
/// was animating (round 321), a Grow on a ball already heading back to normal (round 324), a
/// sticky catch spending another paddle power-up's turn (round 312). Each was one pair, and each
/// was found by a person meeting it.
///
/// What a machine can do here is not judge whether a pair *feels* right - that is James's - but
/// prove that no pair leaves the scene in a state the next frame cannot survive. The invariants
/// are the ones the game itself relies on everywhere: a ball with a body, finite positions, a
/// paddle with a width, and a rack that has not gone negative.
final class PowerUpPairInteractionTests: XCTestCase {

    /// The pair the sweep is inside, so a crash can say which one it was.
    ///
    /// **An ObjC exception is not an assertion.** It unwinds the test method where it is
    /// thrown, so a sweep of thousands of pairs reports "attempt to insert nil object" with no
    /// word about which pair was being collected - which is most of the information. The pair
    /// is written here as it starts and cleared when the sweep finishes, and `tearDown` says
    /// what it was holding if the sweep never got there.
    private var pairUnderTest: String?

    override func tearDown() {
        if let pair = pairUnderTest {
            XCTFail("the sweep stopped inside '\(pair)'")
        }
        pairUnderTest = nil
        super.tearDown()
    }

    private func scene(mode: GameMode = .endlessII) -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = mode
        let stats = TotalStats()
        stats.achievementsUnlockedArray = stats.achievementsUnlockedArray.map { _ in true }
        scene.totalStatsArray = [stats]
        scene.multiplier = Scoring.multiplierBase
        // **Both of these are what a running game has and a bare scene does not.** The
        // multiplier is zero on a fresh `GameScene` and set to its base when a run starts, so a
        // fixture without it reports every power-up that returns before the multiplier line as
        // having zeroed it. And an achievement that has not been earned calls Game Center on
        // the way out, which in a test is a slow no-op with an error in the log for each one -
        // 4,225 pairs of those is a test nobody will run twice
        scene.gameWidth = 360
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.numberOfLives = 3
        scene.hapticsSetting = false
        scene.soundsSetting = false
        scene.ballLostBool = false
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.ball.physicsBody?.velocity = CGVector(dx: 120, dy: 200)
        scene.addChild(scene.paddle)
        scene.paddle.size = CGSize(width: 90, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        return scene
    }

    /// Put a scene beyond use before letting go of it.
    ///
    /// **A pair that collects Lasers leaves a repeating `Timer` behind, and a `Timer` holds its
    /// target.** One is nothing; this test makes thousands of scenes, and every one that ever
    /// held lasers would have stayed alive with its nodes, its physics world and its timer for
    /// the rest of the run. The first attempt at this test died twice without reaching an
    /// assertion, four minutes in, and that is what it was: scenes piling up faster than
    /// anything could reclaim them. `endEverythingInFlight` is the app's own way out of a
    /// scene, which is the right thing to lean on here - if it stops being enough for the app,
    /// this test notices first.
    private func retire(_ scene: GameScene) {
        scene.endEverythingInFlight()
        scene.removeAllChildren()
    }

    /// Between pairs: the app's own reset, and then the geometry by hand.
    ///
    /// **`powerUpsReset` hands the paddle and the ball back their size with an `SKAction`**,
    /// and an action does not run in a scene with no view - so in this fixture the animated
    /// half of the reset is a no-op and a Shrink Paddle's width survives into the next pair,
    /// and the next, until the paddle is too narrow for SpriteKit to build a body from and the
    /// app's own force-unwrap of it traps. That is the fixture's problem rather than the
    /// game's: on a phone the action runs. So the sizes are put back here, to the numbers the
    /// fixture started with, and everything else is left to the game.
    private func putBack(_ scene: GameScene) {
        scene.paddle.removeAllActions()
        scene.paddle.setScale(1)
        scene.paddle.size = CGSize(width: 90, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.paddleWidth = 90
        scene.ball.removeAllActions()
        scene.ball.setScale(1)
        scene.ball.position = .zero
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.ball.physicsBody?.velocity = CGVector(dx: 120, dy: 200)
        scene.ballSize = 12
        scene.powerUpsReset()
        scene.numberOfLives = 3
        scene.ballLostBool = false
        // A rack is the run's, not the power-ups'; a lost ball is what Lose A Life leaves.
        // The geometry goes back *before* the game's own reset rather than after, because the
        // reset reads the paddle and the ball it is handed
    }

    private func collect(_ index: Int, on scene: GameScene) {
        let node = SKSpriteNode(texture: scene.powerUpTexturesInOrder[index])
        node.name = PowerUpCategoryName
        scene.addChild(node)
        scene.ballLostBool = false
        scene.applyPowerUp(node: node, silently: true)
    }

    /// What must be true of the scene whatever has just been collected.
    private func survives(_ scene: GameScene, _ pair: String) -> [String] {
        var broken: [String] = []
        if scene.ball.physicsBody == nil { broken.append("the ball lost its body") }
        if scene.ball.position.x.isFinite == false || scene.ball.position.y.isFinite == false {
            broken.append("the ball is at \(scene.ball.position)")
        }
        if let velocity = scene.ball.physicsBody?.velocity,
           velocity.dx.isFinite == false || velocity.dy.isFinite == false {
            broken.append("the ball's velocity is \(velocity)")
        }
        if scene.paddle.size.width.isFinite == false || scene.paddle.size.width <= 0 {
            broken.append("the paddle is \(scene.paddle.size.width)pt wide")
        }
        if scene.paddle.xScale.isFinite == false || scene.paddle.xScale <= 0 {
            broken.append("the paddle is scaled to \(scene.paddle.xScale)")
        }
        if scene.ballSize.isFinite == false || scene.ballSize <= 0 {
            broken.append("the ball is \(scene.ballSize)pt")
        }
        if scene.numberOfLives < 0 { broken.append("the rack is \(scene.numberOfLives)") }
        if scene.multiplier.isFinite == false || scene.multiplier <= 0 {
            broken.append("the multiplier is \(scene.multiplier)")
        }
        return broken.map { "\(pair): \($0)" }
    }

    /// The sweep: every power-up collected on top of every other one.
    ///
    /// **A fresh `GameScene` costs 350ms to build and a collection costs two**, measured in
    /// round 329 - so 4,225 fresh scenes is twenty-one minutes and 4,225 collections on one
    /// scene is twenty seconds. The scene is reused and put back between pairs with
    /// `powerUpsReset`, which is the app's own way of taking everything off after a lost ball:
    /// leaning on it means the residue this sweep runs against is the residue the game itself
    /// leaves, and if that stops being enough for the game it stops being enough here.
    ///
    /// **Anything the sweep flags is then collected again on a scene of its own**, and only a
    /// pair that fails twice is reported. That is what keeps the cheap sweep honest: a fault
    /// that only appears after four thousand resets is a fault in the reset, not in the pair,
    /// and the second pass is where the two are told apart.
    func testNoPairOfPowerUpsLeavesTheSceneBroken() {
        sweepEveryPair(in: .endlessII)
    }

    /// And the same sweep in Classic, which is the mode with the years of scores on it.
    ///
    /// Most of Mayhem's own power-ups stand down outside Mayhem - they guard on the mode - so
    /// this is mainly the original set meeting each other, on a scene that answers questions
    /// the Mayhem one does not: level numbers, a pack, a rack of lives. It costs another
    /// forty seconds and it covers the mode a player is most likely to be in.
    func testNoPairOfPowerUpsBreaksAClassicRun() {
        sweepEveryPair(in: .classic)
    }

    private func sweepEveryPair(in mode: GameMode) {
        let names = LevelPackSetup().powerUpNameArray
        let scene = self.scene(mode: mode)
        let count = scene.powerUpTexturesInOrder.count
        XCTAssertGreaterThan(count, 60, "the list is empty, so this test proves nothing")

        var suspects: [(first: Int, second: Int, pair: String)] = []
        for first in 0..<count {
            for second in 0..<count {
                let pair = "\(mode): \(names[first]) then \(names[second])"
                pairUnderTest = pair
                putBack(scene)
                collect(first, on: scene)
                collect(second, on: scene)
                scene.tickEndlessIIPaddlePowerUps(1.0/60)
                scene.tickEndlessIIRescue(1.0/60)
                if survives(scene, pair).isEmpty == false {
                    suspects.append((first, second, pair))
                }
                pairUnderTest = nil
            }
        }
        retire(scene)

        var faults: [String] = []
        for suspect in suspects {
            autoreleasepool {
                let fresh = self.scene(mode: mode)
                pairUnderTest = suspect.pair
                collect(suspect.first, on: fresh)
                collect(suspect.second, on: fresh)
                fresh.tickEndlessIIPaddlePowerUps(1.0/60)
                fresh.tickEndlessIIRescue(1.0/60)
                faults.append(contentsOf: survives(fresh, suspect.pair))
                retire(fresh)
                pairUnderTest = nil
            }
        }
        XCTAssertEqual(faults, [], "\(faults.count) pairs left the scene in a state the next "
                       + "frame could not survive:\n" + faults.prefix(12).joined(separator: "\n"))
    }

    /// A long messy run: two thousand collections on one scene, nothing ever reset.
    ///
    /// **A pair is not what a run is.** The sweep above puts the scene back between pairs, which
    /// is what makes a failure attributable - and it means nothing in it ever meets a scene that
    /// has been collecting power-ups for ten minutes, which is the state every real run is in by
    /// the time it gets interesting. This is that: a seeded walk through the whole list, applied
    /// on top of whatever the last one left, with the geometry checked after every single one.
    ///
    /// The seed is fixed so a failure can be run again, and the step is reported with it: the
    /// message names the collection number and the power-up, which is enough to replay by hand.
    /// Lives are left out of the check here rather than topped up - thirty Lose A Lifes in a row
    /// is not a state the game can be in, and faking it back would be checking the fixture.
    func testALongChainOfCollectionsKeepsTheSceneInOnePiece() {
        let names = LevelPackSetup().powerUpNameArray
        let scene = self.scene()
        let count = scene.powerUpTexturesInOrder.count
        var seed: UInt64 = 0x9E3779B97F4A7C15

        for step in 0..<2_000 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let index = Int((seed >> 33) % UInt64(count))
            scene.ballLostBool = false
            scene.numberOfLives = 3
            collect(index, on: scene)
            scene.tickEndlessIIPaddlePowerUps(1.0/60)
            scene.tickEndlessIIRescue(1.0/60)

            let where_ = "collection \(step), \(names[index])"
            XCTAssertNotNil(scene.ball.physicsBody, "\(where_): the ball lost its body")
            XCTAssertTrue(scene.ball.position.x.isFinite && scene.ball.position.y.isFinite,
                          "\(where_): the ball is at \(scene.ball.position)")
            XCTAssertTrue(scene.paddle.size.width.isFinite && scene.paddle.size.width > 0,
                          "\(where_): the paddle is \(scene.paddle.size.width)pt wide")
            XCTAssertTrue(scene.paddle.xScale.isFinite && scene.paddle.xScale > 0,
                          "\(where_): the paddle is scaled to \(scene.paddle.xScale)")
            XCTAssertTrue(scene.ballSize.isFinite && scene.ballSize > 0,
                          "\(where_): the ball is \(scene.ballSize)pt")
            XCTAssertTrue(scene.multiplier.isFinite, "\(where_): the multiplier is \(scene.multiplier)")
            if scene.ball.physicsBody == nil { break }
            // One broken frame is the finding; two thousand copies of it are noise
        }
        retire(scene)
    }

    /// And the same power-up twice, which is a pair the field produces more often than most:
    /// two of a kind fall together whenever the weights come up that way.
    func testCollectingTheSameOneTwiceIsSafe() {
        let names = LevelPackSetup().powerUpNameArray
        let count = scene().powerUpTexturesInOrder.count
        var faults: [String] = []
        for index in 0..<count {
            autoreleasepool {
                let scene = self.scene()
                collect(index, on: scene)
                collect(index, on: scene)
                scene.tickEndlessIIPaddlePowerUps(1.0/60)
                faults.append(contentsOf: survives(scene, "\(names[index]) twice"))
                retire(scene)
            }
        }
        XCTAssertEqual(faults, [], faults.joined(separator: "\n"))
    }
}

/// What a power-up sounds like when it lands.
///
/// **James, round 334: "don't play normal power-up sound for power-ups that have other sounds
/// when activated"**, and "shrill noise happens seemingly at random".
final class PowerUpSoundTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        return scene
    }

    private func index(of name: String) -> Int? {
        LevelPackSetup().powerUpNameArray.firstIndex(of: name)
    }

    /// The ones that speak for themselves are named by power-up rather than by number.
    ///
    /// Seven since round 341, when Cluster joined them (James: "Cluster played both the
    /// cluster sound and the power-up sound when collected").
    func testTheOnesThatSpeakForThemselvesAreTheOnesNamed() {
        let names = LevelPackSetup().powerUpNameArray
        let spoken = GameScene.endlessIICollectionSounds
            .compactMap { names.indices.contains($0.key) ? names[$0.key] : nil }
        XCTAssertEqual(Set(spoken), ["Multi-Ball", "Brick Cull", "Brick Infill",
                                     "Laser Beam", "Safety Paddle", "Mirror Paddle", "Cluster"])
    }

    /// And the chime only stands down where a recording actually exists.
    ///
    /// The rule is asked of the bundle, not of the list: a sound nobody has recorded cannot
    /// stand in for the chime, so the power-up keeps the chime until one lands.
    func testTheChimeStandsDownOnlyForADeliveredSound() {
        let scene = self.scene()
        for (index, sound) in GameScene.endlessIICollectionSounds {
            guard scene.powerUpTexturesInOrder.indices.contains(index) else { continue }
            let texture = scene.powerUpTexturesInOrder[index]
            XCTAssertEqual(scene.endlessIIHasItsOwnVoice(texture),
                           GameScene.mayhemSound(sound) != nil,
                           "\(sound): the chime and the recording disagree")
        }
    }

    /// A power-up with nothing of its own keeps the chime.
    func testAnOrdinaryPowerUpKeepsTheChime() throws {
        let scene = self.scene()
        let index = try XCTUnwrap(index(of: "Expand Paddle"))
        XCTAssertFalse(scene.endlessIIHasItsOwnVoice(scene.powerUpTexturesInOrder[index]))
    }

    /// And nothing stands down outside Mayhem, where none of these sounds belongs.
    func testTheChimeIsUntouchedInClassic() throws {
        let scene = self.scene()
        scene.gameMode = .classic
        let index = try XCTUnwrap(index(of: "Multi-Ball"))
        XCTAssertFalse(scene.endlessIIHasItsOwnVoice(scene.powerUpTexturesInOrder[index]))
    }

    /// The throttle: a sound asked for twice in a frame is played once.
    ///
    /// Identical copies of one short recording started milliseconds apart comb filter, which is
    /// heard as a thin metallic whistle - the shrill noise, arriving at random because it
    /// depends on how many events happened to coincide.
    func testASoundAskedForTwiceInAFrameIsPlayedOnce() {
        let scene = self.scene()
        scene.soundsSetting = true
        guard GameScene.mayhemSound("explosion") != nil else {
            return XCTAssertTrue(true, "no recording to throttle yet, so nothing to test")
        }

        scene.playMayhemSound("explosion")
        let after = scene.action(forKey: "")
        _ = after
        scene.playMayhemSound("explosion")
        scene.playMayhemSound("explosion")
        // Three asks, and what is asserted is the rule rather than SpriteKit's book-keeping:
        // the gap is a twelfth of a second, which is longer than any frame
        XCTAssertGreaterThan(GameScene.mayhemSoundGap, 1.0/60,
                             "a throttle shorter than a frame throttles nothing")
        XCTAssertLessThan(GameScene.mayhemSoundGap, 0.2,
                          "and one longer than the sounds themselves would swallow real events")
    }
}

/// The Always On twist's standing power-up, collected silently and kept on.
///
/// **James, round 341, on the Peach day standing on Shrink Ball: "Always on applied as the ball
/// left the paddle - at least the power-up HUD icon lit up, but the power-up itself was not
/// applied" - and "it worked when I quit and resumed mid-game, it then reset when I lost the
/// ball."** Watched on the simulator with a log in the tick: the twist asked the pause screen's
/// question of which power-up a tray slot is running, got "neither" every frame for a silent
/// collection, and collected Shrink Ball again every frame - while refusing to at all whenever
/// the ball was waiting on the paddle.
final class DailyAlwaysOnKeepsItsPowerUpTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 360
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.hapticsSetting = false
        scene.soundsSetting = false
        scene.ballLostBool = false
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        scene.addChild(scene.ball)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.addChild(scene.paddle)
        scene.iconTimerArray = (0..<8).map { _ in
            let bar = SKSpriteNode()
            bar.isHidden = true
            bar.xScale = 0
            return bar
        }
        return scene
    }

    private static let shrinkBall = LevelPackSetup().powerUpNameArray.firstIndex(of: "Shrink Ball")!

    /// A lit bar in the standing power-up's own slot is that power-up running - and a bar that
    /// has only just been lit, still growing to full width, counts too.
    func testALitBarInItsSlotIsTheStandingPowerUpRunning() {
        let scene = scene()
        let index = Self.shrinkBall
        XCTAssertFalse(scene.dailyStandingPowerUpIsRunning(index), "nothing lit, nothing running")

        let slot = GameScene.trayPowerUpFamilies.firstIndex { $0.contains(index) }!
        let bar = scene.iconTimerArray[slot]
        bar.isHidden = false
        bar.run(.scaleX(to: 1, duration: 0.05))
        XCTAssertTrue(scene.dailyStandingPowerUpIsRunning(index),
                      "a bar still growing is running: reading it as stopped collected Shrink "
                      + "Ball a second time and took the ball to half size")

        bar.removeAllActions()
        bar.xScale = 0.6
        XCTAssertTrue(scene.dailyStandingPowerUpIsRunning(index),
                      "and a bar counting down is running, whether or not it is in the list of "
                      + "power-ups the player caught - which a silent collection never is")

        bar.isHidden = true
        XCTAssertFalse(scene.dailyStandingPowerUpIsRunning(index), "and hidden, it has ended")
    }

    /// Put back by the twist, it counts for nothing in the player's statistics.
    func testASilentCollectionLeavesTheTalliesAlone() {
        let scene = scene()
        let before = scene.totalStatsArray[0].powerupsCollected
        let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[Self.shrinkBall])
        scene.applyPowerUp(node: carrier, silently: true, standing: true)

        XCTAssertLessThan(scene.ballSizeTarget, 1, "the power-up itself did apply")
        XCTAssertEqual(scene.totalStatsArray[0].powerupsCollected, before,
                       "the day's standing power-up is not a catch, and was being counted as "
                       + "one every time the twist put it back")
    }

    /// And it is put on while the next ball waits on the paddle, not only once it is launched.
    func testTheDaysPowerUpGoesOnWhileTheBallWaitsOnThePaddle() {
        let scene = scene()
        scene.ballLostBool = true
        scene.ballIsOnPaddle = true
        let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[Self.shrinkBall])
        scene.applyPowerUp(node: carrier, silently: true, standing: true)
        XCTAssertLessThan(scene.ballSizeTarget, 1,
                          "\"the power-up should be active from the start\" - it waited for the "
                          + "launch, because the lost-ball flag stays up until then")

        let caught = self.scene()
        caught.ballLostBool = true
        caught.ballIsOnPaddle = true
        caught.applyPowerUp(node: SKSpriteNode(
            texture: caught.powerUpTextureArray[Self.shrinkBall]))
        XCTAssertEqual(caught.ballSizeTarget, 1,
                       "an ordinary catch in that window is still refused, as it always was")
    }
}
