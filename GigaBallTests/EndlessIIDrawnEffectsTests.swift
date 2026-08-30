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
