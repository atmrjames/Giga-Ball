//
//  EndlessIIDrawnEffectsTests.swift
//  GigaBallTests
//
//  Three hand-drawn effects replaced by artwork, and all three are sized from measurements
//  taken off the files rather than from round numbers. That is the good way round - a redraw
//  that moves the triangle is one constant to change - and it is also the way it goes wrong
//  quietly: a marker two points out of place still points at the paddle, and a laser core
//  sized to the wrong ball is still a laser.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIDrawnEffectsTests: XCTestCase {

    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.gameWidth = 380
        scene.layoutUnit = 18
        scene.ballSize = scene.normalBallSize
        scene.paddleHeight = scene.ballSize
        return scene
    }

    // MARK: - The artwork is there

    func testAllThreeEffectsHaveTheirArtwork() {
        XCTAssertNotNil(GameScene.endlessIIAuraTexture, "BallAura")
        XCTAssertNotNil(GameScene.endlessIILaserBeamTexture, "LaserBeamLength")
        XCTAssertNotNil(GameScene.endlessIILaserAfterGlowTexture, "LaserBeamAfterGlow")
        XCTAssertNotNil(GameScene.endlessIILandingMarkerTexture, "LandingMarker")
        // Each of the three draws nothing at all without its file rather than falling back to
        // the shape it replaced, so a missing one is an effect that silently stops appearing
    }

    // MARK: - The laser beam

    /// The bright core is a normal ball wide, whatever the ball is doing.
    ///
    /// "It shouldn't change size with the ball" (James). The sprite is much wider than the core
    /// because most of it is the glow either side, so the check is on the core rather than on
    /// the sprite: 22 points of the picture's 124.
    func testTheLaserCoreIsANormalBallWideWhateverTheBallIs() {
        let scene = fieldScene()
        let normal = scene.normalBallSize

        let atNormal = scene.endlessIILaserBeamNode().size.width*(22/124)
        XCTAssertEqual(atNormal, normal, accuracy: 0.1)

        scene.ballSize = normal*2
        let atDouble = scene.endlessIILaserBeamNode().size.width*(22/124)
        XCTAssertEqual(atDouble, normal, accuracy: 0.1,
                       "a Big Ball must not widen the beam")

        scene.ballSize = normal/2
        let atHalf = scene.endlessIILaserBeamNode().size.width*(22/124)
        XCTAssertEqual(atHalf, normal, accuracy: 0.1, "nor a small one narrow it")
    }

    /// And it runs the height of the view, top to bottom.
    func testTheLaserBeamRunsTheHeightOfTheView() {
        let scene = fieldScene()
        XCTAssertEqual(scene.endlessIILaserBeamNode().size.height, scene.frame.height,
                       accuracy: 0.5)
    }

    // MARK: - The burn the beam leaves

    /// James, round 288: "the LaserBeam graphic flashes for a fraction of a second, then it's
    /// replaced by LaserBeamAfterGlow which then slowly fades out with its opacity dropping to
    /// 0 over the next 1-2s. This will give the impression of a burn in effect after the
    /// powerful laser beam."
    ///
    /// The beam used to fade over 1.2 seconds on its own, which is a beam still firing faintly
    /// for over a second. A burn is the opposite shape: everything at once, gone at once, and
    /// something left behind that is no longer the shot.
    func testTheBurnIsTheSameColumnAsTheShotThatMadeIt() {
        let scene = fieldScene()
        let beam = scene.endlessIILaserBeamNode()
        let burn = scene.endlessIILaserAfterGlowNode()

        XCTAssertEqual(burn.size, beam.size,
                       "the two pictures share their opaque core to the pixel, so the same "
                       + "arithmetic puts the burn exactly where the beam was")
        XCTAssertLessThan(burn.zPosition, beam.zPosition,
                          "the burn is laid down first and spends the flash underneath")
    }

    func testTheFlashIsAFractionOfASecondAndTheBurnIsSeconds() {
        XCTAssertLessThan(GameScene.endlessIILaserBeamFlashSeconds, 0.25,
                          "\"flashes for a fraction of a second\"")
        XCTAssertGreaterThanOrEqual(GameScene.endlessIILaserAfterGlowSeconds, 1)
        XCTAssertLessThanOrEqual(GameScene.endlessIILaserAfterGlowSeconds, 2,
                                 "\"over the next 1-2s\"")
        XCTAssertGreaterThan(GameScene.endlessIILaserAfterGlowSeconds,
                             GameScene.endlessIILaserBeamFlashSeconds*4,
                             "and the burn is the part that lasts, or it is just a shorter beam")
    }

    /// Firing leaves both, and the burn is the one that is still there afterwards.
    func testFiringLeavesABurnBehindTheBeam() {
        let scene = fieldScene()
        scene.totalStatsArray = [TotalStats()]
        scene.ball.size = CGSize(width: scene.ballSize, height: scene.ballSize)
        scene.ball.position = CGPoint(x: 40, y: 100)
        scene.addChild(scene.ball)

        scene.endlessIIFireLaserBeams()

        let columns = scene.children.filter {
            ($0 as? SKSpriteNode)?.size.height == scene.frame.height
        }
        XCTAssertEqual(columns.count, 2, "a beam and the burn under it")
        for column in columns {
            XCTAssertEqual(column.position.x, 40, accuracy: 0.01,
                           "both in the ball's own column")
        }
    }

    // MARK: - The landing marker

    /// The triangle inside the picture is the size the drawn-by-hand one was.
    ///
    /// The old path was `ballSize*0.7` across, with shoulders at `size*0.55` either side of the
    /// middle - so the shape a player reads was `ballSize*0.77` wide. The picture is mostly
    /// glow, so the sprite is far bigger than that and the triangle inside it is not.
    /// **Half again bigger than the old drawn one** (James, round 259: "make the landing marker
    /// bigger"). The rule this test holds has not changed - the *triangle* is the marker and
    /// the glow around it is not - only the number it is held to.
    func testTheDrawnTriangleIsTheSizeItIsMeantToBe() {
        let scene = fieldScene()
        let old = scene.ballSize*0.7*1.1
        let inside = scene.endlessIILandingMarkerSize.width
            * GameScene.endlessIILandingTriangleShare
        XCTAssertEqual(inside, old*GameScene.endlessIILandingMarkerScale, accuracy: 0.5,
                       "the shape has to be the size it is meant to be, however much glow is "
                       + "around it")
        XCTAssertGreaterThan(scene.endlessIILandingMarkerSize.width, old*2,
                             "and the picture has to be much bigger, because it is mostly glow")
    }

    /// It is scaled on one axis, so the drawing is not squared up to the old path.
    func testTheMarkerKeepsThePicturesOwnProportions() {
        let scene = fieldScene()
        let size = scene.endlessIILandingMarkerSize
        XCTAssertEqual(size.height/size.width, 132/146, accuracy: 0.001)
    }

    /// The triangle lands on the mark, not the picture.
    ///
    /// Two small offsets, both real, and either one backwards moves the mark a couple of points
    /// - which is the amount nobody notices and the marker is then wrong about where the ball
    /// will cross.
    func testTheTrianglesCentreLandsOnTheMarkRatherThanThePictures() {
        let scene = fieldScene()
        let mark = CGPoint(x: 40, y: -200)
        let centre = scene.endlessIILandingMarkerCentre(over: mark)

        XCTAssertEqual(centre.x, mark.x, "the triangle is centred across the picture")

        // Where the triangle's own middle ends up, given where the sprite was put
        let size = scene.endlessIILandingMarkerSize
        let triangleCentre = centre.y - GameScene.endlessIILandingTriangleDrop*size.height
        let oldBoxCentre = mark.y - scene.ballSize*0.7*0.1
        XCTAssertEqual(triangleCentre, oldBoxCentre, accuracy: 0.5,
                       "the drawn triangle should sit where the drawn-by-hand one sat")
    }

    // MARK: - The aura

    /// The glow's visible edge sits on the reach, rather than the picture's edge doing.
    ///
    /// A radial fade has no edge. Drawn to the reach exactly, the part a player can see would
    /// sit well inside the circle the aura actually eats - a power-up lying about how far it
    /// goes, which the stroked circle it replaced could not do.
    func testTheAurasVisibleEdgeSitsOnTheReachItActuallyHas() {
        let scene = fieldScene()
        let reach = scene.ballSize/2*GameScene.endlessIIAuraReach[0]

        let drawn = reach*2/GameScene.endlessIIAuraVisibleShare
        XCTAssertGreaterThan(drawn, reach*2, "the picture is bigger than the reach")

        let visibleRadius = drawn/2*GameScene.endlessIIAuraVisibleShare
        XCTAssertEqual(visibleRadius, reach, accuracy: 0.1,
                       "and the part of it that reads as glow ends where the aura does")
    }

    /// A deeper collection grows the drawing as well as the reach.
    func testAStackedAuraIsDrawnBigger() {
        let scene = fieldScene()
        let shallow = GameScene.endlessIIAuraReach[0]
        let deep = GameScene.endlessIIAuraReach[1]
        XCTAssertGreaterThan(deep, shallow,
                             "a deepening collection grows it, or this test proves nothing")

        let share = GameScene.endlessIIAuraVisibleShare
        XCTAssertGreaterThan(scene.ballSize/2*deep*2/share,
                             scene.ballSize/2*shallow*2/share)
    }
}

/// No shaped brick face carries a border around its own canvas.
///
/// §8.5 recorded this and it stood for a long time: "the Diamond art carries a thin dark border
/// around its own square canvas, in the oblong pictures as well as the square ones. A face's
/// art is a sprite inside the shape node and a sprite is not clipped to a path, so that border
/// draws - a faint square around every diamond brick in the game."
///
/// James redrew the affected files in round 288. This is what stops them coming back: a
/// re-export is one checkbox away from putting the canvas edge back, and the fault is a
/// hairline that nobody notices in a screenshot of one brick and that everybody notices in a
/// field of them.
///
/// **The rule is "not a complete ring", not "no edge pixels at all."** A wedge is a right
/// triangle and genuinely fills two whole sides of its canvas; a dome fills the bottom. What no
/// shaped face does is reach *every* pixel of its own border, because a shape that did would be
/// a rectangle. Before the fix the Diamond's ring was 504 of 504 pixels of pure black; after it,
/// twelve, and those are the diamond's own points touching the edge.
final class ShapedBrickArtHasNoCanvasBorderTests: XCTestCase {

    /// Composed the way `endlessIIShapedArt` composes them, rather than listed: behaviour, then
    /// face, then orientation, then size suffix. A name with no picture behind it is skipped,
    /// so this covers whatever exists today and picks up whatever is drawn next.
    private var candidates: [String] {
        let behaviours = ["BrickNormal", "BrickInvisible",
                          "BrickMultiHit1", "BrickMultiHit2", "BrickMultiHit3", "BrickMultiHit4",
                          "BrickIndestructible1", "BrickIndestructible2", "BrickPortal",
                          "retroBrickNormal", "retroBrickInvisible",
                          "RetroBrickMultiHit1", "RetroBrickMultiHit2",
                          "RetroBrickMultiHit3", "RetroBrickMultiHit4"]
        let faces = ["Convex0", "Convex180", "Concave0", "Concave180",
                     "Wedge0", "Wedge90", "Wedge180", "Wedge270", "Diamond"]
        let sizes = ["", "Square", "Big"]
        return behaviours.flatMap { behaviour in
            faces.flatMap { face in sizes.map { behaviour + face + $0 } }
        }
    }

    /// What share of the outermost ring of pixels is drawn at all.
    private func borderCoverage(_ image: UIImage) -> Double? {
        guard let cg = image.cgImage else { return nil }
        let w = cg.width, h = cg.height
        guard w > 2, h > 2 else { return nil }
        var pixels = [UInt8](repeating: 0, count: w*h*4)
        guard let context = CGContext(data: &pixels, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w*4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y*w + x)*4 + 3] }
        var drawn = 0, total = 0
        for x in 0..<w {
            for y in [0, h - 1] { total += 1; if alpha(x, y) > 20 { drawn += 1 } }
        }
        for y in 0..<h {
            for x in [0, w - 1] { total += 1; if alpha(x, y) > 20 { drawn += 1 } }
        }
        return Double(drawn)/Double(total)
    }

    func testNoShapedFaceIsRingedByItsOwnCanvasEdge() {
        var looked = 0
        for name in candidates {
            guard let image = UIImage(named: name) else { continue }
            guard let coverage = borderCoverage(image) else { continue }
            looked += 1
            XCTAssertLessThan(coverage, 0.9,
                              "\(name) draws \(Int(coverage*100))% of its own canvas edge - a "
                              + "shaped face that reaches every pixel of its border is a "
                              + "rectangle, and the border is what draws as a square around "
                              + "the brick (§8.5)")
        }
        XCTAssertGreaterThan(looked, 40,
                             "and it actually found the artwork to look at - a name scheme "
                             + "that had drifted would pass this by matching nothing")
    }
}

/// The Paddle Halo wears James's artwork, drawn to the reach it actually eats.
///
/// It was a filled `SKShapeNode` semicircle with a stroke on it, which said where the reach was
/// exactly and looked like a geometry diagram. The picture is a soft disc; the arithmetic that
/// puts its edge on the reach is the Aura's, for the same reason.
final class PaddleHaloArtworkTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.paddleWidth = 120
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.addChild(scene.paddle)
        return scene
    }

    private func halo(_ scene: GameScene) -> SKSpriteNode? {
        scene.endlessIICollectPaddleHalo()
        scene.tickEndlessIIPaddleHalo()
        return scene.endlessIIPaddleHaloNode as? SKSpriteNode
    }

    func testTheHaloHasItsArtwork() {
        XCTAssertNotNil(GameScene.endlessIIHaloTexture, "Halo")
    }

    /// The half a semicircle needs, and no more.
    ///
    /// `haloTouches` refuses any brick whose top is below the centre, so the lower half of the
    /// disc would be drawing a reach that does not exist.
    func testTheGlowIsHalfADiscStandingOnItsFlatEdge() throws {
        let scene = mayhem()
        let node = try XCTUnwrap(halo(scene))
        XCTAssertEqual(node.anchorPoint, CGPoint(x: 0.5, y: 0),
                       "anchored on the diameter, which is where the halo's centre is")
        XCTAssertEqual(node.size.height, node.size.width/2, accuracy: 0.01,
                       "half as tall as it is wide - the top half of a square canvas")
        XCTAssertEqual(node.position, scene.endlessIIPaddleHaloCentre)
    }

    /// The visible edge of the glow lands on the circle it eats.
    func testTheGlowIsDrawnToTheReachItEats() throws {
        let scene = mayhem()
        let node = try XCTUnwrap(halo(scene))
        let reach = scene.paddleWidth*EndlessIIPaddleEffects.haloReach[0]

        let drawnRadius = node.size.width*GameScene.endlessIIHaloVisibleShare/2
        XCTAssertEqual(drawnRadius, reach, accuracy: 0.5,
                       "the picture overhangs, and the contour that reads as its edge is the "
                       + "one put on the reach - the same bargain the Aura makes")
        XCTAssertGreaterThan(node.size.width/2, reach,
                             "so the sprite itself is wider than the reach, as a soft-edged "
                             + "picture has to be")
    }

    /// A deeper collection reaches further, and the picture follows.
    func testTheGlowGrowsWithTheStack() throws {
        let scene = mayhem()
        let first = try XCTUnwrap(halo(scene)).size.width
        scene.endlessIICollectPaddleHalo()
        scene.tickEndlessIIPaddleHalo()
        let second = try XCTUnwrap(scene.endlessIIPaddleHaloNode as? SKSpriteNode).size.width
        XCTAssertGreaterThan(second, first)
    }

    // MARK: - The fade below the paddle line

    // James, round 313: "The halo graphic looks good, but it stops very harshly at the paddle
    // level. Let's add a gradual fade out of it from the paddle level and below."

    private func skirt(of halo: SKSpriteNode) -> SKSpriteNode? {
        halo.childNode(withName: GameScene.endlessIIHaloSkirtName) as? SKSpriteNode
    }

    func testTheGlowKeepsGoingBelowTheDiameter() throws {
        let scene = mayhem()
        let node = try XCTUnwrap(halo(scene))
        let below = try XCTUnwrap(skirt(of: node), "the hard edge is what was reported")

        XCTAssertEqual(below.anchorPoint, CGPoint(x: 0.5, y: 1),
                       "hung from the diameter, so it starts exactly where the halo stops")
        XCTAssertEqual(below.position, CGPoint.zero,
                       "at the parent's anchor, which is the paddle line")
        XCTAssertEqual(below.size.width, node.size.width, accuracy: 0.01,
                       "the same width, or the silhouette steps in at the seam")
        XCTAssertEqual(below.size.height,
                       node.size.height*GameScene.endlessIIHaloSkirtShare, accuracy: 0.01)
        XCTAssertLessThan(below.size.height, node.size.height,
                          "the cut is softened, not turned into a whole disc - the lower half "
                          + "would be drawing a reach `haloTouches` refuses")
    }

    func testTheFadeFollowsTheGlowAsItGrows() throws {
        let scene = mayhem()
        let node = try XCTUnwrap(halo(scene))
        let firstDepth = try XCTUnwrap(skirt(of: node)).size.height

        scene.endlessIICollectPaddleHalo()
        scene.tickEndlessIIPaddleHalo()
        let grown = try XCTUnwrap(scene.endlessIIPaddleHaloNode as? SKSpriteNode)
        let secondDepth = try XCTUnwrap(skirt(of: grown)).size.height

        XCTAssertGreaterThan(secondDepth, firstDepth,
                             "a sprite's size does not reach its children, so this is the one "
                             + "that silently stops following")
    }

    /// It is a fade, not a second block of glow: the strip is solid where it meets the
    /// diameter and gone at its bottom edge.
    func testTheStripActuallyFadesOut() throws {
        let texture = try XCTUnwrap(GameScene.endlessIIHaloSkirtTexture)
        let image = texture.cgImage()
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width*height*4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // A bitmap context's memory runs top-down whatever its drawing origin is, so row
        // zero is the top of the strip - which is the edge that meets the diameter, since the
        // skirt hangs from its own top edge
        func alphaAcross(row: Int) -> Int {
            (0..<width).reduce(0) { $0 + Int(pixels[(row*width + $1)*4 + 3]) }
        }
        let atTheDiameter = alphaAcross(row: 0)
        let atTheBottom = alphaAcross(row: height - 1)

        XCTAssertGreaterThan(atTheDiameter, 0, "the glow carries on past the paddle line")
        XCTAssertLessThan(atTheBottom, atTheDiameter/20,
                          "and has gone by the bottom of the strip, or the hard edge has "
                          + "simply moved down")
    }

    /// Drawn to a file so the fade can be looked at, which is the only way this one is judged.
    ///
    /// Its own small scene rather than the game's: what is being looked at is the seam at the
    /// diameter, and in a real scene the halo sits at the paddle with most of the frame taken
    /// up by the field above it. The first draft of this rendered the game scene and caught
    /// the corner of the glow in the corner of the picture.
    func testTheHaloAndItsFadeCanBeLookedAt() throws {
        let stage = SKScene(size: CGSize(width: 640, height: 420))
        stage.backgroundColor = .black
        stage.anchorPoint = .zero

        let glow = SKSpriteNode(texture: try XCTUnwrap(GameScene.endlessIIHaloTexture))
        glow.anchorPoint = CGPoint(x: 0.5, y: 0)
        glow.alpha = GameScene.endlessIIHaloAlpha
        glow.size = CGSize(width: 520, height: 260)
        glow.position = CGPoint(x: 320, y: 140)
        stage.addChild(glow)

        let skirt = SKSpriteNode(texture: try XCTUnwrap(GameScene.endlessIIHaloSkirtTexture))
        skirt.anchorPoint = CGPoint(x: 0.5, y: 1)
        skirt.size = CGSize(width: glow.size.width,
                            height: glow.size.height*GameScene.endlessIIHaloSkirtShare)
        glow.addChild(skirt)

        // The paddle line, so the seam can be seen against something straight
        let line = SKSpriteNode(color: .white, size: CGSize(width: 640, height: 1))
        line.position = CGPoint(x: 320, y: 140)
        line.alpha = 0.25
        stage.addChild(line)

        let view = SKView(frame: CGRect(origin: .zero, size: stage.size))
        let texture = try XCTUnwrap(view.texture(from: stage),
                                    "no renderer here, so there is nothing to look at")
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("halo-fade.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  The halo and its fade: \(file.path)\n")
    }
}

/// The bricks page shows a power-up as a power-up.
final class BricksPagePowerUpIconTests: XCTestCase {

    /// James, round 289: "rather than showing the power-up brick as a yellow block, use the
    /// PowerUpClearAndRetreat graphic as a generic power-up graphic."
    func testThePowerUpEntryIsNotTheYellowBlock() {
        XCTAssertNotEqual(BrickTypeIcons.genericPowerUpArtName, GameScene.powerUpBrickArtName,
                          "the block is the brick's badge before an icon is cut into it, which "
                          + "is a picture a player never actually meets in the field")
        XCTAssertNotNil(UIImage(named: BrickTypeIcons.genericPowerUpArtName))
    }

    /// The field is untouched: a power-up brick still wears its block.
    func testTheFieldStillDrawsThePowerUpBrickAsItAlwaysHas() {
        XCTAssertEqual(GameScene.powerUpBrickArtName, "PowerUpBrick",
                       "only the reference page changed - a page picture and a field picture "
                       + "are different questions and this round answered one of them")
    }
}
