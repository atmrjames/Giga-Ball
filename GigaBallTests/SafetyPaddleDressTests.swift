//
//  SafetyPaddleDressTests.swift
//  GigaBallTests
//
//  What the safety paddle wears, and what shape it is, when other paddle power-ups are running
//  at the same time.
//
//  James, round 313, from one screenshot with four power-ups in it: "sticky paddle plus safety
//  paddle - sticky texture is on the underside of the safety paddle", and "sticky paddle plus
//  safety paddle plus split paddle plus paddle portal - blue portal texture between the
//  sections of the paddle, safety paddle should also be split".
//
//  The bar has followed the paddle's width, scale, picture and shape since round 203's parity
//  list. Its face and its holes are the two cells that were left.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class SafetyPaddleDressTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.brickHeight = 20
        scene.brickWidth = 40
        scene.gameWidth = 400
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.finalBrickRowHeight = -100
        scene.paddle.size = CGSize(width: 90, height: 10)
        scene.paddleSticky.size = CGSize(width: 90, height: 11)
        return scene
    }

    private func bar(_ scene: GameScene) -> SKSpriteNode? {
        scene.childNode(withName: GameScene.endlessIISafetyPaddleName) as? SKSpriteNode
    }

    private func face(of node: SKSpriteNode) -> SKSpriteNode? {
        node.childNode(withName: GameScene.endlessIISafetyPaddleTopName) as? SKSpriteNode
    }

    private func segments(_ bar: SKSpriteNode) -> [SKSpriteNode] {
        bar.children.compactMap { $0 as? SKSpriteNode }
            .filter { $0.name == GameScene.endlessIISafetyPaddleSegmentName }
    }

    // MARK: - The sticky face

    /// The report: the sticky band sat under the bar rather than on it.
    ///
    /// `paddleSticky` is anchored (0.5, 0) in the scene file, so the paddle's own eleven points
    /// grow *upward* from the line they are placed on. The bar's strip was a plain
    /// `SKSpriteNode`, anchored in its middle, so the same placement hung half of it below.
    func testTheStickyFaceStandsOnTheBarRatherThanUnderIt() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.stickyPaddleCatches = 3
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()

        let strip = try XCTUnwrap(face(of: bar), "a bar that catches has to look like one")
        let stripBottom = strip.position.y - strip.size.height*strip.anchorPoint.y
        XCTAssertGreaterThanOrEqual(stripBottom, -bar.size.height/2 - 0.01,
                                    "nothing of the face may hang below the bar's underside")
        XCTAssertEqual(strip.anchorPoint.y, 0, accuracy: 0.0001,
                       "which is what the paddle's own sticky strip does")
    }

    /// And it goes away again when the catches are spent.
    func testTheFaceComesOffWhenNothingWantsIt() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.stickyPaddleCatches = 3
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()
        XCTAssertNotNil(face(of: bar))

        scene.stickyPaddleCatches = 0
        scene.tickEndlessIISafetyPaddle()
        XCTAssertNil(face(of: bar))
    }

    // MARK: - The split

    func testTheBarIsWholeWhileThePaddleIs() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()

        XCTAssertTrue(segments(bar).isEmpty)
        XCTAssertNotNil(bar.texture, "one bar, drawing itself")
    }

    /// The report: a split paddle should have a split twin.
    func testTheBarSplitsWithThePaddle() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIICollectDoublePaddle()
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()

        let pieces = segments(bar)
        XCTAssertGreaterThan(pieces.count, 1, "a bar with the paddle's holes in it")
        XCTAssertNil(bar.texture,
                     "the span stops drawing itself - what is drawn now is its children")
        var alpha: CGFloat = 1
        bar.color.getWhite(nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0, accuracy: 0.0001, "and paints nothing across the holes")
        // The alpha rather than `== .clear`: `.clear` is built in the grey colour space and
        // what comes back off a sprite is sRGB, so two transparent blacks compare unequal

        let paddleCentres = scene.endlessIISplitSegmentCentres
        XCTAssertEqual(pieces.count, paddleCentres.count,
                       "the same number of pieces as the paddle, in the same places")
        for (piece, centre) in zip(pieces.sorted { $0.position.x < $1.position.x },
                                   paddleCentres.sorted()) {
            XCTAssertEqual(piece.position.x, centre, accuracy: 0.5)
        }
    }

    /// Each piece wears its own face, so nothing is drawn across a hole.
    func testEachPieceWearsItsOwnStickyFace() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIICollectDoublePaddle()
        scene.stickyPaddleCatches = 3
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()

        let pieces = segments(bar)
        XCTAssertFalse(pieces.isEmpty)
        XCTAssertNil(face(of: bar), "the whole bar's own face goes with the whole bar")
        for piece in pieces {
            let strip = try XCTUnwrap(face(of: piece), "every piece catches, so every piece "
                                      + "has to look like it does")
            XCTAssertEqual(strip.size.width, piece.size.width, accuracy: 0.5,
                           "and no wider than the piece it is on")
        }
    }

    /// Put back exactly, which is the bargain every one of these power-ups makes.
    func testTheBarComesBackTogetherWhenTheSplitEnds() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIICollectDoublePaddle()
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()
        XCTAssertFalse(segments(bar).isEmpty)

        scene.endlessIIDoublePaddleClock.reset()
        scene.tickEndlessIISafetyPaddle()

        XCTAssertTrue(segments(bar).isEmpty)
        XCTAssertNotNil(bar.texture)
        XCTAssertEqual(bar.color, GameScene.endlessIIHaloColour)
    }

    /// A ball can fall through the holes, which is the whole point of a split.
    func testTheBodyHasTheHolesInItToo() throws {
        let scene = self.scene()
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIICollectDoublePaddle()
        let bar = try XCTUnwrap(self.bar(scene))
        scene.tickEndlessIISafetyPaddle()

        let body = try XCTUnwrap(bar.physicsBody)
        XCTAssertEqual(body.categoryBitMask, CollisionTypes.safetyPaddleCategory.rawValue,
                       "still a safety paddle contact, however many pieces it is in")
        XCTAssertLessThan(body.area, bar.size.width*bar.size.height/2500 + 1,
                          "an area smaller than the whole span is the holes being real")
    }
}

/// What a split paddle is painted with while a tinting power-up runs.
///
/// James, round 313: with a Sticky Paddle, a Safety Paddle, a Split Paddle and a Paddle Portal
/// all at once, "blue portal texture between the sections of the paddle".
///
/// It was not a texture. A split paddle stops drawing itself - `refreshEndlessIIDoublePaddle`
/// ends with `texture = nil`, `color = .clear` - and what the player sees is its two children.
/// The node keeps its full span, because the bounce measures where the ball landed across the
/// whole of it. `dressEndlessIIPaddle` then ran on the next frame and painted that span portal
/// blue at 0.75, and a textureless sprite with a colour draws a solid rectangle: the halves
/// covered the ends of it and the gap between them did not. The gap was the paddle itself,
/// showing through the hole it is supposed to have.
final class SplitPaddleTintTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 400
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.paddle.size = CGSize(width: 90, height: 10)
        scene.addChild(scene.paddle)
        return scene
    }

    private func halves(_ scene: GameScene) -> [SKSpriteNode] {
        scene.paddle.children.compactMap { $0 as? SKSpriteNode }
            .filter { $0.name == GameScene.doublePaddleHalfName }
    }

    private func alpha(of colour: UIColor) -> CGFloat {
        var alpha: CGFloat = 1
        colour.getWhite(nil, alpha: &alpha)
        return alpha
    }

    /// `UIColor ==` is exact, and the same colour round-tripped through a sprite comes back
    /// differing in the last bits - two that print identically compare unequal.
    private func isSame(_ colour: UIColor, _ other: UIColor,
                        file: StaticString = #filePath, line: UInt = #line) {
        var mine = (r: CGFloat(0), g: CGFloat(0), b: CGFloat(0), a: CGFloat(0))
        var theirs = mine
        colour.getRed(&mine.r, green: &mine.g, blue: &mine.b, alpha: &mine.a)
        other.getRed(&theirs.r, green: &theirs.g, blue: &theirs.b, alpha: &theirs.a)
        XCTAssertEqual(mine.r, theirs.r, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(mine.g, theirs.g, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(mine.b, theirs.b, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(mine.a, theirs.a, accuracy: 0.001, file: file, line: line)
    }

    /// The report: nothing may be painted across the gap.
    func testASplitPaddleDoesNotPaintItsOwnGap() {
        let scene = self.scene()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)

        XCTAssertFalse(halves(scene).isEmpty, "the split has to be built for this to be about "
                       + "anything")
        XCTAssertEqual(alpha(of: scene.paddle.color), 0, accuracy: 0.0001,
                       "the span stays invisible - the gap is a hole, not a portal")
        XCTAssertNil(scene.paddle.texture)
    }

    /// And the pieces wear the tint instead, so the power-up is still readable.
    func testThePiecesWearThePortalsColourInstead() {
        let scene = self.scene()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)

        for half in halves(scene) {
            XCTAssertEqual(half.colorBlendFactor, 0.75, accuracy: 0.0001,
                           "a split Portal Paddle still looks like a Portal Paddle")
            isSame(half.color, GameScene.portalBlueColour)
        }
    }

    /// A whole paddle is unchanged, which is every run that has no Double Paddle in it.
    func testAWholePaddleIsStillTintedItself() {
        let scene = self.scene()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)

        XCTAssertTrue(halves(scene).isEmpty)
        XCTAssertEqual(scene.paddle.colorBlendFactor, 0.75, accuracy: 0.0001)
        isSame(scene.paddle.color, GameScene.portalBlueColour)
    }

    /// The tint comes off the pieces when the power-up ends, like everything else here.
    func testThePiecesLoseTheTintWhenThePortalEnds() {
        let scene = self.scene()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)
        XCTAssertFalse(halves(scene).isEmpty)

        scene.endlessIIPortalPaddleClock.reset()
        scene.tickEndlessIIPaddlePowerUps(0)

        for half in halves(scene) {
            XCTAssertEqual(half.colorBlendFactor, 0, accuracy: 0.0001)
        }
    }
}
