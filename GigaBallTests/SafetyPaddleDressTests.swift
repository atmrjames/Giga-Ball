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

    /// **And the pieces are not tinted, because the glow says it instead** (round 316).
    ///
    /// These two tests asked for `portalBlueColour` at three-quarter blend, which is what a
    /// Portal Paddle wore from the round it was built. James took it off in round 316 - "I
    /// don't think the paddles require a tint any more. The glow effect is enough" - and
    /// round 315's artwork is what made the blue wrong rather than merely unnecessary: the
    /// Portal identity is the Giga-Ball lime now, across the bricks, their glows, the paddle
    /// glow and the retro paddle's own variant, so a blue paddle inside a lime halo read as
    /// two power-ups at once.
    ///
    /// The readability the old test was protecting is still protected, by the glow rather than
    /// by the tint, so that is what these ask for now.
    func testThePiecesAreNotTintedAndTheGlowSaysItInstead() {
        let scene = self.scene()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)

        for half in halves(scene) {
            XCTAssertEqual(half.colorBlendFactor, 0, accuracy: 0.0001,
                           "a split Portal Paddle is lit, not painted")
        }
        XCTAssertNotNil(scene.paddle.childNode(withName: GameScene.paddleGlowName),
                        "and with no tint, the halo is the only thing saying Portal")
    }

    /// A whole paddle, which is every run that has no Double Paddle in it.
    func testAWholePaddleIsLitRatherThanTinted() {
        let scene = self.scene()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)

        XCTAssertTrue(halves(scene).isEmpty)
        XCTAssertEqual(scene.paddle.colorBlendFactor, 0, accuracy: 0.0001,
                       "nothing is painted on it - `paint` with no tint takes the blend to "
                       + "zero and leaves the colour alone, since a colour at zero blend is "
                       + "not drawn")
        XCTAssertNotNil(scene.paddle.childNode(withName: GameScene.paddleGlowName))
    }

    /// **Magnetism was the last power-up tinting the paddle, and now nothing does** (James,
    /// round 327c: "for the magnetism graphic, there's no need to colour the paddle - show
    /// magnetism lines flowing towards the paddle from the ball, like it is being attracted to
    /// the paddle").
    ///
    /// Round 316 took the Portal Paddle's tint away on the same argument - draw the effect, not
    /// the paddle - and this is that argument finished. What says a magnet is running is the
    /// pull itself: dashes travelling up the line from the ball, which `drawEndlessIIPullLines`
    /// owns and `EndlessIIMagnetFlowTests` measures.
    func testMagnetismNoLongerPaintsThePaddle() {
        let scene = self.scene()
        scene.endlessIICollectMagnetism()
        scene.tickEndlessIIPaddlePowerUps(0)

        XCTAssertEqual(scene.paddle.colorBlendFactor, 0, accuracy: 0.0001,
                       "nothing paints the paddle any more")
        XCTAssertNil(scene.paddle.childNode(withName: GameScene.paddleGlowName),
                     "and Magnetism still has no halo - the lines are its whole signal")
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

/// Where a split paddle's own strips sit.
///
/// Round 313, found by rendering the four power-ups together and looking at them.
/// `refreshEndlessIISplitOverlay` builds a fresh `SKSpriteNode` for each piece, and a fresh
/// sprite is anchored in its middle - but `paddleSticky` and `paddleLaser` are both anchored
/// (0.5, 0) in the scene file, so they stand on the line they are placed on and grow upward
/// over the paddle. Every split piece therefore sat half a strip lower than the strip it was
/// standing in for: the same mistake the safety paddle's face was making, in the same round.
final class SplitOverlayAnchorTests: XCTestCase {

    func testASplitStripStandsWhereTheWholeStripStood() {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 400
        scene.ballSize = 12
        scene.paddleWidth = 150
        scene.paddle.size = CGSize(width: 150, height: 12)
        scene.addChild(scene.paddle)

        scene.paddleSticky.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.paddleSticky.size = CGSize(width: 150, height: 14)
        scene.paddleSticky.position = CGPoint(x: 0, y: -66)
        scene.paddleSticky.texture = scene.stickyPaddleTexture
        scene.addChild(scene.paddleSticky)

        scene.endlessIICollectDoublePaddle()
        scene.refreshEndlessIIDoublePaddle()
        scene.refreshEndlessIISplitDress()

        let pieces = scene.children.compactMap { $0 as? SKSpriteNode }
            .filter { $0 !== scene.paddleSticky && $0.texture === scene.paddleSticky.texture }
        XCTAssertFalse(pieces.isEmpty, "the split has to dress itself for this to be about "
                       + "anything")
        for piece in pieces {
            XCTAssertEqual(piece.anchorPoint, scene.paddleSticky.anchorPoint,
                           "a piece standing in for a strip has to stand where it stood")
            XCTAssertEqual(piece.frame.minY, scene.paddleSticky.frame.minY, accuracy: 0.5,
                           "its bottom edge is the strip's bottom edge")
        }
    }
}

/// The four power-ups from James's screenshot, drawn to a file so they can be looked at.
///
/// "Sticky paddle plus safety paddle plus split paddle plus paddle portal" is four power-ups
/// dressing two surfaces at once, and the project's rule is that visual work is verified by
/// looking. Reachable in play only by collecting four specific drops in one run.
final class PaddleDressRenderTests: XCTestCase {

    func testTheFourPowerUpsTogetherCanBeLookedAt() throws {
        let scene = GameScene(size: CGSize(width: 420, height: 260))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 400
        scene.brickHeight = 20
        scene.brickWidth = 40
        scene.ballSize = 12
        scene.paddleWidth = 150
        scene.backgroundColor = UIColor(red: 0.06, green: 0.05, blue: 0.14, alpha: 1)
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        scene.paddle.size = CGSize(width: 150, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -60)
        scene.paddle.texture = scene.paddleTexture
        scene.addChild(scene.paddle)

        scene.paddleSticky.size = CGSize(width: 150, height: 14)
        scene.paddleSticky.anchorPoint = CGPoint(x: 0.5, y: 0)
        scene.paddleSticky.position = CGPoint(x: 0, y: -66)
        scene.addChild(scene.paddleSticky)
        // The anchor the scene file gives it. A `GameScene` built here rather than loaded from
        // the .sks starts with a bare `SKSpriteNode` for each of these, and a picture that
        // stands on the paddle in the game would float in the middle of it in a render

        scene.finalBrickRowHeight = 80
        scene.stickyPaddleCatches = 3
        scene.endlessIICollectSafetyPaddle()
        scene.endlessIICollectDoublePaddle()
        scene.endlessIICollectPortalPaddle()
        scene.tickEndlessIIPaddlePowerUps(0)
        scene.tickEndlessIISafetyPaddle()
        scene.refreshEndlessIISplitDress()
        (scene.childNode(withName: GameScene.endlessIISafetyPaddleName))?.alpha = 1
        // The bar fades in over 0.15 seconds with an action, and actions do not run in a test

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene),
                                    "no renderer here, so there is nothing to look at")
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("paddle-dress.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  The paddle and its twin, with all four on: \(file.path)\n")
    }
}
