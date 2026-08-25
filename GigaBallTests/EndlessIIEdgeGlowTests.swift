//
//  EndlessIIEdgeGlowTests.swift
//  GigaBallTests
//
//  One picture serves three edges, and the way that goes wrong is silent: a glow drawn with its
//  bright side facing into the field instead of against the wall is still a glow, still fades,
//  and is simply backwards. So is one whose length and depth have swapped over - it is then a
//  strip twenty points long lying across a field four hundred wide.
//
//  Neither shows up as a crash and both look deliberate in a screenshot, which is what these
//  are here to catch.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIEdgeGlowTests: XCTestCase {

    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.gameWidth = 380
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.numberOfBrickColumns = 11
        return scene
    }

    func testTheArtworkIsInTheCatalogue() {
        XCTAssertNotNil(GameScene.endlessIIEdgeGlowTexture,
                        "PortalLength is what all three edges are drawn from - without it "
                        + "there is no glow at all, which is the fallback and not a failure")
    }

    /// Depth across, length along - and the two must not swap.
    ///
    /// The top edge is turned a quarter turn *after* it is sized, so its size is written the
    /// same way round as the sides': width is the depth of the glow and height is the length of
    /// the edge. Reading that backwards gives a strip twenty points long lying across the top.
    func testEachEdgeIsAsLongAsTheEdgeItRunsAlong() {
        let scene = fieldScene()
        let depth = GameScene.endlessIIEdgeGlowDepth

        let top = scene.endlessIIEdgeGlowSize(along: .top)
        XCTAssertEqual(top.width, depth, "the depth is the sprite's width, before it is turned")
        XCTAssertEqual(top.height, scene.gameWidth, accuracy: 0.5,
                       "and its height is the length, which for the top is the field's width")

        for edge in [GameScene.EndlessIIEdge.left, .right] {
            let size = scene.endlessIIEdgeGlowSize(along: edge)
            XCTAssertEqual(size.width, depth, "\(edge)")
            XCTAssertEqual(size.height, scene.endlessIIPlayAreaHeight, accuracy: 0.5, "\(edge)")
        }
    }

    /// The bright side is against the wall on every edge.
    ///
    /// This is the assertion the whole file exists for. The artwork is bright along its own
    /// *left* edge, so the transforms have to put that edge against the top, the left wall and
    /// the right wall in turn - and a glow facing the wrong way is a glow that reads as a
    /// shadow falling the wrong direction.
    func testTheBrightEdgeHugsTheWall() {
        let scene = fieldScene()
        let depth = GameScene.endlessIIEdgeGlowDepth

        for edge in [GameScene.EndlessIIEdge.top, .left, .right] {
            scene.showEndlessIIEdgeGlow(edge, wanted: true)
            guard let glow = scene.childNode(withName: edge.glowName) as? SKSpriteNode else {
                return XCTFail("\(edge) drew no glow")
            }
            glow.size = scene.endlessIIEdgeGlowSize(along: edge)

            // The middle of the artwork's bright edge, in the sprite's own coordinates, put
            // through the very transform the scene gave it
            let bright = CGPoint(x: -glow.size.width/2, y: 0)
            let inField = glow.convert(bright, to: scene)

            switch edge {
            case .top:
                XCTAssertEqual(inField.y, scene.endlessIIPlayAreaTop, accuracy: 1,
                               "the top's bright edge should sit on the line the field starts at")
            case .left:
                XCTAssertEqual(inField.x, -scene.gameWidth/2, accuracy: 1,
                               "the left glow should be brightest against the left wall")
            case .right:
                XCTAssertEqual(inField.x, scene.gameWidth/2, accuracy: 1,
                               "the right glow should be brightest against the right wall")
            }

            // And the far side is the one reaching into the field, a depth away
            let far = glow.convert(CGPoint(x: glow.size.width/2, y: 0), to: scene)
            switch edge {
            case .top: XCTAssertEqual(far.y, scene.endlessIIPlayAreaTop - depth, accuracy: 1)
            case .left: XCTAssertEqual(far.x, -scene.gameWidth/2 + depth, accuracy: 1)
            case .right: XCTAssertEqual(far.x, scene.gameWidth/2 - depth, accuracy: 1)
            }
        }
    }

    /// Each edge has one glow, however many times it is asked for.
    func testAskingTwiceLeavesOneGlow() {
        let scene = fieldScene()
        for _ in 0..<5 { scene.showEndlessIIEdgeGlow(.left, wanted: true) }
        var found = 0
        scene.enumerateChildNodes(withName: GameScene.EndlessIIEdge.left.glowName) { _, _ in
            found += 1
        }
        XCTAssertEqual(found, 1)
    }

    /// And it goes when the doorway does.
    func testAGlowIsTakenAwayWhenItIsNoLongerWanted() {
        let scene = fieldScene()
        scene.showEndlessIIEdgeGlow(.top, wanted: true)
        XCTAssertNotNil(scene.childNode(withName: GameScene.EndlessIIEdge.top.glowName))

        scene.showEndlessIIEdgeGlow(.top, wanted: false)
        XCTAssertNil(scene.childNode(withName: GameScene.EndlessIIEdge.top.glowName),
                     "a wall that is a wall again should not still be glowing")
    }

    /// The three edges are three different nodes, not one moved about.
    func testEachEdgeKeepsItsOwnGlow() {
        let scene = fieldScene()
        for edge in [GameScene.EndlessIIEdge.top, .left, .right] {
            scene.showEndlessIIEdgeGlow(edge, wanted: true)
        }
        let names = Set([GameScene.EndlessIIEdge.top, .left, .right].map(\.glowName))
        XCTAssertEqual(names.count, 3, "the names have to differ or one lookup finds another")
        for name in names {
            XCTAssertNotNil(scene.childNode(withName: name), name)
        }
    }
}
