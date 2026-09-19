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
