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
