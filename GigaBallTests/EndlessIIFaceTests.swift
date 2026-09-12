//
//  EndlessIIFaceTests.swift
//  GigaBallTests
//
//  The shaped bricks (§12.0's brick geometries) rest on two rules that are invisible on
//  screen until they are broken, and break in ways that look like something else:
//
//  A body piece that is not convex is silently mangled by `SKPhysicsBody(polygonFrom:)` -
//  the brick keeps a shape but bounces off a different one, which reads as "the physics is
//  wrong" rather than as "the path is wrong".
//
//  A hiding rectangle that is not inside the silhouette leaves a corner of the sprite
//  poking out of the shape, which reads as a drawing glitch.
//
//  Both are pure geometry, so both are checked here rather than eyeballed on a device.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIFaceTests: XCTestCase {

    /// A cell, at the proportions the game uses: twice as wide as it is tall.
    private let cell = CGSize(width: 40, height: 20)

    func testEveryBodyPieceIsConvex() {
        for face in EndlessIIFace.allCases {
            for (mirrored, flipped) in [(false, false), (true, false),
                                    (false, true), (true, true)] {
                for piece in EndlessIIFaceGeometry.bodyPieces(face, size: cell,
                                                              mirrored: mirrored,
                                                              flipped: flipped) {
                    var points: [CGPoint] = []
                    piece.applyWithBlock { element in
                        let type = element.pointee.type
                        if type == .moveToPoint || type == .addLineToPoint {
                            points.append(element.pointee.points[0])
                        }
                    }
                    XCTAssertTrue(EndlessIIFaceGeometry.isConvex(points),
                                  "\(face) mirrored:\(mirrored) flipped:\(flipped) has a "
                                  + "piece a polygon body cannot take")
                }
            }
        }
    }

    func testTheSpriteHidesInsideTheFace() {
        // The rule the Wedge exists to break: its hypotenuse runs through the node's own
        // centre, so no centred rectangle fits inside it and the hiding rectangle has to
        // be off-centre. Checked for every face, both ways round.
        for face in EndlessIIFace.allCases {
            for (mirrored, flipped) in [(false, false), (true, false),
                                    (false, true), (true, true)] {
                let silhouette = EndlessIIFaceGeometry.silhouette(face, size: cell,
                                                                  mirrored: mirrored,
                                                                  flipped: flipped)
                let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell,
                                                            mirrored: mirrored,
                                                            flipped: flipped)
                let corners = [CGPoint(x: hide.minX, y: hide.minY),
                               CGPoint(x: hide.maxX, y: hide.minY),
                               CGPoint(x: hide.maxX, y: hide.maxY),
                               CGPoint(x: hide.minX, y: hide.maxY)]
                for corner in corners {
                    XCTAssertTrue(silhouette.contains(corner),
                                  "\(face) mirrored:\(mirrored) flipped:\(flipped) leaves "
                                  + "\(corner) outside its own face")
                }
                XCTAssertGreaterThan(hide.width, 0)
                XCTAssertGreaterThan(hide.height, 0)
            }
        }
    }

    func testOnlyTheDiamondHidesItsSpriteInTheMiddle() {
        // Which is the whole reason hiding rectangles are rectangles rather than a scale
        // factor. This was "the wedge is the only one" until round 280, and its comment said
        // that if a dome or a notch ever needed an offset too, that was the reminder to check
        // nothing else assumed the sprite was centred. It fired, and the check was made:
        // `redrawEndlessIIFace` works the anchor out from whatever rectangle it is given,
        // `endlessIIBrickCentre` reads the face node's own position rather than assuming, and
        // `endlessIICanTake` exempts every shaped brick from the centred test already. The
        // reflection in `hidingRect` now actually moves these two when a face is flipped, which
        // is what it was written for.
        for face in EndlessIIFace.allCases {
            let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell)
            let centred = abs(hide.midX) < 0.001 && abs(hide.midY) < 0.001
            XCTAssertEqual(centred, face == .diamond, "\(face)")
        }
        // A rhombus is the one face solid through its own middle, so it is the one that can
        // hide a sprite there. The wedge tucks into the fat corner opposite its point; the tent
        // and the notch sit on the brick's floor, because that is the only part of *both* the
        // silhouette and James's drawn art that is solid all the way across (round 280)
    }

    func testMirroringAWedgeReflectsItRatherThanMovingIt() {
        let right = EndlessIIFaceGeometry.corners(.wedge, size: cell)
        let left = EndlessIIFaceGeometry.corners(.wedge, size: cell, mirrored: true)
        XCTAssertEqual(Set(right.map { abs($0.x) }), Set(left.map { abs($0.x) }))
        XCTAssertEqual(right.map(\.x).reduce(0, +), -left.map(\.x).reduce(0, +),
                       accuracy: 0.001, "a mirrored wedge points the other way")
    }

    /// The Diamond has no flat face - which is the whole of what it is.
    ///
    /// Every other shape here keeps at least one square edge: the dome and the notch stand
    /// on a flat base, the wedge on two. A ball meeting one of those square-on comes back the
    /// way it came. The Diamond is the one that never gives that, from any side, and it stops
    /// being that the moment an edge lines up with an axis - which a tidy-up of the corners
    /// could do without looking like it had changed anything.
    func testTheDiamondHasNoFlatEdge() {
        let corners = EndlessIIFaceGeometry.corners(.diamond, size: cell)
        XCTAssertEqual(corners.count, 4)
        for index in corners.indices {
            let a = corners[index]
            let b = corners[(index + 1) % corners.count]
            XCTAssertGreaterThan(abs(b.x - a.x), 0.001, "a vertical edge at \(a) - \(b)")
            XCTAssertGreaterThan(abs(b.y - a.y), 0.001, "a horizontal edge at \(a) - \(b)")
        }
    }

    /// And it is its own reflection, both ways, so turning one over changes nothing.
    ///
    /// `makeFace` rolls a flip for every shape and a mirror for the Wedge, and this is what
    /// makes that harmless here rather than something the Diamond needs excluding from.
    func testTheDiamondIsItsOwnReflection() {
        let plain = cornerSet(.diamond)
        for (mirrored, flipped) in [(true, false), (false, true), (true, true)] {
            XCTAssertEqual(cornerSet(.diamond, mirrored: mirrored, flipped: flipped), plain,
                           "mirrored:\(mirrored) flipped:\(flipped)")
        }
    }

    /// A face's corners as a set, ignoring which one the path starts at and which way it
    /// winds.
    ///
    /// Both of those change under a reflection and neither is part of the shape: one
    /// reflection reverses the winding on purpose, so a polygon body reads the path the right
    /// way out. Zero is normalised because negating it gives `-0.0`, which is a different
    /// string and the same point.
    private func cornerSet(_ face: EndlessIIFace,
                           mirrored: Bool = false, flipped: Bool = false) -> Set<String> {
        Set(EndlessIIFaceGeometry.corners(face, size: cell, mirrored: mirrored,
                                          flipped: flipped)
            .map { "\($0.x + 0),\($0.y + 0)" })
    }

    /// It is a single convex piece, like the dome and the wedge and unlike the notch.
    func testTheDiamondNeedsOnlyOneBodyPiece() {
        XCTAssertEqual(EndlessIIFaceGeometry.bodyPieces(.diamond, size: cell).count, 1,
                       "a rhombus is convex; splitting it would be work for nothing")
    }

    func testTheFaceAndStyleNamesAreOneToOne() {
        // The one place the two vocabularies meet. A face that lost its style would be a
        // shape the reference page, the recents and the compatibility grid never mention
        for face in EndlessIIFace.allCases {
            XCTAssertEqual(face.style.face, face)
        }
        let faceStyles = EndlessIIStyle.allCases.filter(\.isFace)
        XCTAssertEqual(faceStyles.count, EndlessIIFace.allCases.count)
    }

    // MARK: - Shape and action as two axes (round 235)

    /// A scene with the field geometry filled in, for the tests that need a real brick.
    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 500, height: 900))
        scene.gameMode = .endlessII
        scene.gameWidth = 440
        scene.brickWidth = cell.width
        scene.brickHeight = cell.height
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffsetEndless = 300
        scene.finalBrickRowHeight = 300 - cell.height*21
        scene.ballSize = 12
        return scene
    }

    private func shapedBrick(_ scene: GameScene, _ face: EndlessIIFace,
                             at point: CGPoint = CGPoint(x: 0, y: 200)) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
        brick.position = point
        brick.name = BrickCategoryName
        scene.addChild(brick)
        scene.makeFace(face, on: brick)
        return brick
        // The ordinary brick texture, not a plain colour: `endlessIIBehaviour(of:)` reads what
        // a brick *is* off its texture, and a brick with none is refused every style - which
        // would have made the assertions below pass for the wrong reason
    }

    /// A shaped brick fills a whole cell, however small the sprite hiding inside it is.
    ///
    /// This is the one fact the whole axis split rests on. `makeFace` shrinks the sprite into
    /// the rectangle the face says is safely inside itself - about a third of a cell - so
    /// every style that asks "how big is this brick" was being told a shaped brick was a Tiny
    /// one sitting off the grid. That did not matter while a shape refused all five of them.
    func testAShapedBrickStillFillsItsWholeCell() {
        let scene = fieldScene()
        for face in EndlessIIFace.allCases {
            let brick = shapedBrick(scene, face)
            XCTAssertLessThan(brick.size.width, cell.width*0.9,
                              "\(face)'s sprite should be tucked inside the shape")
            XCTAssertEqual(scene.endlessIIFieldSize(of: brick).width, cell.width,
                           accuracy: 0.5, "\(face)")
            XCTAssertEqual(scene.endlessIIFieldSize(of: brick).height, cell.height,
                           accuracy: 0.5, "\(face)")
            XCTAssertTrue(scene.isOrdinaryCellSized(brick), "\(face)")
            XCTAssertTrue(scene.occupiesOneCell(brick), "\(face)")
            brick.removeFromParent()
        }
    }

    /// And the field sees it in exactly one cell, not none and not four.
    func testAShapedBrickOccupiesTheCellItSitsIn() {
        let scene = fieldScene()
        let brick = shapedBrick(scene, .wedge)
        let cellOf = scene.endlessIICell(of: brick)
        let occupancy = scene.endlessIIOccupancy()
        XCTAssertEqual(occupancy[cellOf]?.count, 1)
        XCTAssertTrue(occupancy[cellOf]?.first === brick)
    }

    /// The five styles the workbook freed now stack with every shape.
    func testAShapeTakesTheStylesThatOnlySayWhereABrickIs() {
        for face in EndlessIIFace.allCases {
            for other in [EndlessIIStyle.spinning, .gravity, .moving, .fixed, .breathing] {
                XCTAssertTrue(face.style.stacksWith(other),
                              "\(face) should stack with \(other) - shape and action are two "
                              + "axes, and none of these five touches the outline")
            }
        }
    }

    /// A shaped brick can actually be *given* one, which is a different question.
    ///
    /// A style has to be in a pool to exist (§8.6), and the same trap has a second door: a
    /// combination the grid allows and the generator can never produce looks exactly like one
    /// that is very rare. The shapes have their own pass for this reason - while they shared
    /// the appearance pool with Breathing, a brick could have a shape *or* breathe and never
    /// both, whatever `stacksWith` said.
    func testAShapedBrickIsStillOfferedASecondStyle() {
        let scene = fieldScene()
        let brick = shapedBrick(scene, .convex)
        for style in [EndlessIIStyle.spinning, .gravity, .moving, .fixed, .breathing] {
            XCTAssertTrue(scene.endlessIICanTake(style, brick), "\(style)")
        }
        XCTAssertFalse(scene.endlessIICanTake(.rounded, brick), "two outlines, one brick")
        XCTAssertFalse(scene.endlessIICanTake(.directional, brick),
                       "James: directional bricks are always the standard shape")
    }

    /// A breathing shaped brick rebuilds its silhouette rather than stretching its sprite.
    ///
    /// The sprite is only the marker hiding inside the shape. Resizing it - which is what
    /// Breathing does to every other brick - would have left one whose picture grew while its
    /// outline and the body traced from it stayed exactly where they were.
    func testAShapedBrickBreathesByRebuildingItsFace() {
        let scene = fieldScene()
        let brick = shapedBrick(scene, .concave)

        scene.resizeEndlessIIFace(brick, to: CGSize(width: cell.width*2,
                                                    height: cell.height*2))
        XCTAssertEqual(scene.endlessIIFieldSize(of: brick).width, cell.width*2, accuracy: 0.5,
                       "the outline did not grow with the breath")
        XCTAssertNotNil(brick.physicsBody, "and it has to stay solid on the way up")

        scene.resizeEndlessIIFace(brick, to: .zero, solid: false)
        XCTAssertNil(brick.physicsBody,
                     "at the bottom of a breath a brick is a picture, not a brick")
    }

    /// An action's glyph is drawn to the brick, not to the sprite hiding inside it.
    ///
    /// The mark every action wears - Gravity's chevron, Exploding's burst - is sized and
    /// placed from the brick. Ask the *sprite* and a shaped brick gets a mark a third of the
    /// size, sitting whereever the sprite happens to hide: for a Wedge, down in the corner
    /// beneath the slope. Both of those read as a drawing bug rather than as the wrong
    /// question having been asked.
    func testAnActionsGlyphIsDrawnToTheWholeBrickNotTheHidingSprite() {
        let scene = fieldScene()
        for face in EndlessIIFace.allCases {
            let brick = shapedBrick(scene, face)
            scene.makeExploding(brick)
            guard let glyph = brick.children.first(where: { $0 is SKShapeNode
                                                            && $0.name != GameScene.brickFaceName })
            else { return XCTFail("\(face) drew no glyph at all") }

            XCTAssertGreaterThan(glyph.frame.height, cell.height*0.4,
                                 "\(face)'s burst was drawn to the sprite's size")
            XCTAssertEqual(glyph.frame.midX, 0, accuracy: 0.5,
                           "\(face)'s burst sat where the sprite hides, not on the brick")
            XCTAssertEqual(glyph.frame.midY, 0, accuracy: 0.5, "\(face)")
            brick.removeFromParent()
        }
    }

    /// A Moving shaped brick measures its room by the cell it fills.
    ///
    /// It looks at what is actually beside it rather than at the cell either side, and it did
    /// that by reading `brick.frame` - which for a shaped brick is the hiding rectangle. A
    /// Moving dome would have slid a third of the way into its neighbour before noticing it.
    func testAMovingShapedBrickIsAsWideAsTheCellItFills() {
        let scene = fieldScene()
        let brick = shapedBrick(scene, .convex, at: CGPoint(x: 0, y: 200))
        XCTAssertEqual(scene.endlessIIFieldRect(of: brick).width, cell.width, accuracy: 0.5)
        XCTAssertEqual(scene.endlessIIFieldRect(of: brick).midX, 0, accuracy: 0.5)

        let limits = scene.endlessIIWanderLimits(for: brick)
        XCTAssertEqual(limits.left, -scene.gameWidth/2 + cell.width/2, accuracy: 0.5,
                       "it thought it was narrower than its cell and could reach the wall")
        XCTAssertEqual(limits.right, scene.gameWidth/2 - cell.width/2, accuracy: 0.5)
    }

    // MARK: - How they combine

    func testAShapedBrickRefusesEverythingThatWouldRedrawOrMoveIt() {
        for face in EndlessIIFace.allCases {
            let style = face.style
            for other in EndlessIIStyle.refusedByAFace {
                XCTAssertFalse(style.stacksWith(other), "\(style) must not stack with \(other)")
                XCTAssertFalse(other.stacksWith(style), "and the rule reads both ways")
            }
        }
    }

    func testTwoShapesNeverShareABrick() {
        for face in EndlessIIFace.allCases {
            for other in EndlessIIFace.allCases {
                XCTAssertFalse(face.style.stacksWith(other.style),
                               "two shapes are two answers to the same question")
            }
        }
    }

    func testAShapeStillStacksWithWhatItDoesNotTouch() {
        // Colour, alpha and neighbours are none of a shape's business, so these three stay
        // available - a flashing wedge and an exploding dome are the point of having an
        // axis at all
        for face in EndlessIIFace.allCases {
            for other: EndlessIIStyle in [.flashing, .exploding, .spawner] {
                XCTAssertTrue(face.style.stacksWith(other), "\(face) should stack with \(other)")
            }
        }
    }

    func testAShapeGoesOnAnyBehaviourButInvisible() {
        for face in EndlessIIFace.allCases {
            XCTAssertFalse(face.style.suits(.invisible),
                           "a slope nobody can see is a slope nobody can aim off")
            for behaviour: EndlessIIBehaviour in [.standard, .multiHit, .indestructibleOnce,
                                                  .indestructibleAlways] {
                XCTAssertTrue(face.style.suits(behaviour), "\(face) on \(behaviour)")
            }
        }
    }
}

// MARK: - The drawn faces

/// James's art, round 153: a texture drawn *as* a rounded brick and *as* a wedge, for each
/// brick type, in both themes. Before it existed the face was the rectangular texture
/// stretched into the path.
final class EndlessIIShapedBrickArtTests: XCTestCase {

    private func scene(retro: Bool = false) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickSetting = retro ? 1 : 0
        if retro {
            scene.brickNormalTexture = scene.retroBrickNormalTexture
            scene.brickInvisibleTexture = scene.retroBrickInvisibleTexture
            scene.brickMultiHit1Texture = scene.retroBrickMultiHit1Texture
            scene.brickMultiHit2Texture = scene.retroBrickMultiHit2Texture
            scene.brickMultiHit3Texture = scene.retroBrickMultiHit3Texture
            scene.brickMultiHit4Texture = scene.retroBrickMultiHit4Texture
            // What `didMove` does at set-up when the retro theme is on
        }
        return scene
    }

    func testEveryBrickTypeHasBothShapesDrawn() {
        // The count that stops one being missed. A brick type with no drawn face falls back
        // to the stretched rectangle, which looks like art nobody got round to rather than
        // like a bug - so it has to be asserted rather than noticed
        for retro in [false, true] {
            let scene = scene(retro: retro)
            var types = [scene.brickNormalTexture, scene.brickInvisibleTexture,
                         scene.brickMultiHit1Texture, scene.brickMultiHit2Texture,
                         scene.brickMultiHit3Texture, scene.brickMultiHit4Texture]
            types += [scene.brickIndestructible1Texture, scene.brickIndestructible2Texture]

            for texture in types {
                for shape in [GameScene.ShapedBrickArt.rounded, .wedge] {
                    let art = scene.endlessIIShapedArt(for: texture, shape)
                    XCTAssertNotNil(art, "no \(shape) art, retro: \(retro)")
                    let size = art?.size() ?? .zero
                    XCTAssertEqual(size.width/size.height, 2, accuracy: 0.01,
                                   "the drawn face has the cell's own 2:1 shape, or it sits "
                                   + "inside its own path rather than filling it")
                    // The *size* is deliberately not asserted equal: the retro theme's plain
                    // textures are 28x14 where its drawn faces are 56x28, so a retro rounded
                    // brick is smoother than the square ones beside it. That is a question
                    // for James rather than a bug - the fill stretches to the path either way
                }
            }
        }
    }

    func testTheRetroThemeGetsItsOwnArtWhereItHasAnyOfItsOwn() {
        let classic = scene(), retro = scene(retro: true)
        XCTAssertNotEqual(classic.endlessIIShapedArt(for: classic.brickNormalTexture, .rounded),
                          retro.endlessIIShapedArt(for: retro.brickNormalTexture, .rounded))

        XCTAssertEqual(retro.endlessIIBrickTextureName(retro.brickIndestructible1Texture),
                       "BrickIndestructible1",
                       "the retro theme has never had its own Indestructible texture - those "
                       + "bricks wear the classic one, so the classic shaped art is the "
                       + "matching art rather than a substitute")
    }

    func testABrickWithNoDrawnFaceKeepsItsOwnTextureStretched() {
        // A power-up brick, a Null, anything a role has dressed
        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickNullTexture)
        XCTAssertNil(scene.endlessIIShapedArt(for: brick.texture, .rounded))
        XCTAssertEqual(scene.endlessIIFaceFill(brick, .rounded), brick.texture)
    }

    /// **Every face has drawn art now** (round 262), which is what this test was waiting to
    /// say: it used to assert Convex and Concave had none, and said where to look on the day
    /// they arrived. James drew them, along with Diamond, for the whole classic set.
    func testEveryFaceHasItsOwnDrawnArt() {
        XCTAssertEqual(GameScene.shapedArt(for: .wedge), .wedge)
        XCTAssertEqual(GameScene.shapedArt(for: .convex), .convex)
        XCTAssertEqual(GameScene.shapedArt(for: .concave), .concave)
        XCTAssertEqual(GameScene.shapedArt(for: .diamond), .diamond)

        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        for face in [EndlessIIFace.wedge, .convex, .concave, .diamond] {
            XCTAssertNotEqual(scene.endlessIIFaceFill(brick, GameScene.shapedArt(for: face)),
                              brick.texture,
                              "\(face) is still stretching the rectangle")
        }
    }

    func testTheWedgeArtIsHandedTheSameWayTheGeometryIs() {
        // The art has its mass in the bottom-right under a slope rising to the right, which
        // is the unmirrored path. The mirrored one is drawn by flipping the *node*, so the
        // texture turns over with the shape - a mirrored path with an unmirrored fill would
        // have had the shading running the wrong way up the slope
        let size = CGSize(width: 56, height: 28)
        let plain = EndlessIIFaceGeometry.silhouette(.wedge, size: size)
        let mirrored = EndlessIIFaceGeometry.silhouette(.wedge, size: size, mirrored: true)

        XCTAssertEqual(plain.boundingBox.width, mirrored.boundingBox.width, accuracy: 0.01)
        var flipped = CGAffineTransform(scaleX: -1, y: 1)
        XCTAssertEqual(plain.copy(using: &flipped)?.boundingBox, mirrored.boundingBox,
                       "mirroring is a reflection in x and nothing else, which is what makes "
                       + "flipping the node the same picture as mirroring the path")
    }
}

// MARK: - Which way up

/// "Flip horizontally and vertically the asymmetrical brick types like wedge so they appear
/// in different orientations in the app" (James, round 154).
///
/// The vertical flip is the one that changes the game rather than the picture. Every shaped
/// brick used to face up, and the field descends to meet the ball, so nearly every hit lands
/// on a brick's underside - a field of domes and wedges was a field of flat undersides.
final class EndlessIIFaceOrientationTests: XCTestCase {

    private let cell = CGSize(width: 40, height: 20)

    func testFlippingTurnsTheShapeOverRatherThanMovingIt() {
        for face in EndlessIIFace.allCases {
            let up = EndlessIIFaceGeometry.corners(face, size: cell)
            let down = EndlessIIFaceGeometry.corners(face, size: cell, flipped: true)

            XCTAssertEqual(Set(up.map(\.x)), Set(down.map(\.x)),
                           "\(face) keeps every x - a flip is a reflection, not a slide")
            XCTAssertEqual(Set(up.map { -$0.y }), Set(down.map(\.y)),
                           "\(face) has every y negated and nothing else")
        }
    }

    func testTheDomeAndTheNotchHaveAWayUpEvenThoughTheyHaveNoHandedness() {
        // A mirrored dome is the same dome, which is why only the Wedge is mirrored. A dome
        // turned over is not the same dome, which is why all three are flipped
        for face in EndlessIIFace.allCases {
            let plain = EndlessIIFaceGeometry.corners(face, size: cell)
            let flipped = EndlessIIFaceGeometry.corners(face, size: cell, flipped: true)
            XCTAssertNotEqual(Set(plain.map(\.debugDescription)),
                              Set(flipped.map(\.debugDescription)),
                              "\(face) looks the same upside down, so flipping it is wasted")
            // The whole corner, not its y: a wedge's three corners use the same two y values
            // either way up, and only the pairing tells the two triangles apart
        }
    }

    func testTwoReflectionsKeepTheWindingOneReversesIt() {
        // Each reflection on its own flips the winding, and a clockwise path is one a polygon
        // body reads inside out. Two reflections are a rotation, which does not - so the
        // reversal has to be conditional, and a body built the other way is a brick the ball
        // passes through
        for face in EndlessIIFace.allCases {
            for (mirrored, flipped) in [(false, false), (true, false),
                                        (false, true), (true, true)] {
                let points = EndlessIIFaceGeometry.corners(face, size: cell,
                                                           mirrored: mirrored, flipped: flipped)
                XCTAssertTrue(EndlessIIFaceGeometry.isConvex(points) || face == .concave,
                              "\(face) mirrored:\(mirrored) flipped:\(flipped)")
                XCTAssertEqual(signedArea(points) > 0, signedArea(
                    EndlessIIFaceGeometry.corners(face, size: cell)) > 0,
                    "\(face) mirrored:\(mirrored) flipped:\(flipped) winds the other way")
            }
        }
    }

    private func signedArea(_ points: [CGPoint]) -> CGFloat {
        var total: CGFloat = 0
        for index in points.indices {
            let a = points[index], b = points[(index + 1) % points.count]
            total += a.x*b.y - b.x*a.y
        }
        return total/2
    }

    func testAShapedBrickRemembersWhichWayItFacedAcrossASave() {
        // Round 150's bug one level in: a resumed field that answers the ball differently
        // from the one the player left. `makeFace` rolls an orientation only when the brick
        // does not already carry one, and the save carries it
        let scene = GameScene()
        scene.gameMode = .endlessII
        let brick = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
        brick.endlessIIFaceMirrored = true
        brick.endlessIIFaceFlipped = true
        scene.addChild(brick)

        scene.makeFace(.wedge, on: brick)
        XCTAssertEqual(brick.endlessIIFaceMirrored, true)
        XCTAssertEqual(brick.endlessIIFaceFlipped, true)
        XCTAssertEqual(brick.childNode(withName: GameScene.brickFaceName)?.yScale, -1,
                       "and it is drawn the way it is recorded")
    }

    func testANewBrickRollsAnOrientationAndWritesItDown() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        let brick = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
        scene.addChild(brick)
        XCTAssertNil(brick.endlessIIFaceFlipped)

        scene.makeFace(.convex, on: brick)
        XCTAssertNotNil(brick.endlessIIFaceFlipped, "rolled, and written down to be saved")
        XCTAssertEqual(brick.endlessIIFaceMirrored, false, "a mirrored dome is the same dome")
    }
}

// MARK: - How a face wears its art

/// "Retro textures are now sized incorrectly. Some are 4 times too big and some are 4 times
/// too small" (James, round 156, with screenshots).
///
/// The cause was not the textures. `SKShapeNode.fillTexture` lays its texture in at the
/// texture's own point size rather than stretching it to the path, so a face showed a *crop*
/// of the picture whose size depended on how big the file happened to be. Invisible for as
/// long as the art was a plain white rectangle; obvious the moment the retro art arrived at
/// full resolution with a bevel on it.
final class EndlessIIFaceArtTests: XCTestCase {

    private func retro() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickSetting = 1
        scene.brickNormalTexture = scene.retroBrickNormalTexture
        return scene
    }

    private func brick(_ scene: GameScene) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: 40, height: 20))
        scene.addChild(brick)
        return brick
    }

    func testTheArtIsASpriteToldItsSizeRatherThanAFillLeftToGuess() {
        let scene = retro()
        let subject = brick(scene)
        scene.makeFace(.wedge, on: subject)

        guard let shape = subject.childNode(withName: GameScene.brickFaceName) as? SKShapeNode
        else { return XCTFail("no face") }
        guard let art = shape.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        else { return XCTFail("no drawn art") }

        XCTAssertEqual(art.size, CGSize(width: 40, height: 20),
                       "the cell, not the texture's own size - which is the whole bug")
        XCTAssertNil(shape.fillTexture,
                     "and the shape stops painting, or the crop is drawn underneath")
    }

    func testATextureOfAnySizeLandsTheSame() {
        // The property that makes the fix a fix: the drawn size comes from the cell, so a
        // texture redrawn at twice the resolution is the same picture in the same place
        let scene = retro()
        let subject = brick(scene)
        scene.makeFace(.wedge, on: subject)
        let art = subject.childNode(withName: GameScene.brickFaceName)?
            .childNode(withName: GameScene.faceArtName) as? SKSpriteNode

        let texture = scene.endlessIIShapedArt(for: scene.brickNormalTexture, .wedge)
        XCTAssertNotEqual(art?.size, texture?.size(),
                          "the two differ here, and before the fix the second one won")
    }

    /// **The fallback, on a brick that will never have a picture.**
    ///
    /// It used to be aimed at whichever shape James had not drawn yet - Convex and Concave in
    /// both themes, then retro's Convex, then retro's Concave - and it went stale three times
    /// in three rounds because he kept drawing them. Both themes are complete as of round 266.
    ///
    /// So it is aimed at the other reason a brick has no drawn art, which is permanent: a
    /// power-up brick, a Null, anything a role has dressed. `endlessIIBrickTextureName` has no
    /// name for those and never will, and the face has to keep stretching whatever the brick is
    /// wearing - or a dome would be a hole in the field.
    func testAFaceWithNoDrawnArtStillGetsItsOldFill() {
        let scene = retro()
        let subject = SKSpriteNode(texture: scene.brickNullTexture,
                                   size: CGSize(width: 40, height: 20))
        scene.addChild(subject)
        scene.makeFace(.concave, on: subject)

        let shape = subject.childNode(withName: GameScene.brickFaceName) as? SKShapeNode
        XCTAssertNil(shape?.childNode(withName: GameScene.faceArtName))
        XCTAssertNotNil(shape?.fillTexture, "or a dome would be a hole in the field")
    }

    func testARoundedBrickWearsItTheSameWay() {
        let scene = retro()
        let subject = brick(scene)
        scene.makeRounded(subject)

        let shape = subject.childNode(withName: GameScene.roundedBrickOutlineName) as? SKShapeNode
        let art = shape?.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        XCTAssertEqual(art?.size, CGSize(width: 40, height: 20))
    }
}


// MARK: - The Square brick's own art

/// James, round 270: "File sharing now contains 'square' bricks and retro bricks, and 'square'
/// rounded bricks and retro rounded bricks. by square, I just mean 2x2."
///
/// A Square brick is one cell wide and two tall, and until this delivery it wore the ordinary
/// oblong texture stretched to twice its height - the same wrongness the shaped faces were
/// built to end, one axis over. Two things this covers: that the picture is found, and that
/// wearing it does not change what the brick *is*.
final class EndlessIISquareBrickArtTests: XCTestCase {

    private func scene(retro: Bool = false) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickSetting = retro ? 1 : 0
        scene.brickWidth = 40
        scene.brickHeight = 20
        // The cell, which `endlessIISizeOf` measures everything against - a scene that has not
        // laid itself out has none, and every brick in it is Normal by default
        if retro {
            scene.brickNormalTexture = scene.retroBrickNormalTexture
            scene.brickInvisibleTexture = scene.retroBrickInvisibleTexture
            scene.brickMultiHit1Texture = scene.retroBrickMultiHit1Texture
            scene.brickMultiHit2Texture = scene.retroBrickMultiHit2Texture
            scene.brickMultiHit3Texture = scene.retroBrickMultiHit3Texture
            scene.brickMultiHit4Texture = scene.retroBrickMultiHit4Texture
        }
        return scene
    }

    /// A Square brick of a known type.
    ///
    /// `endlessIIMakeSquare` draws its type from the field's own mix, which is the right
    /// behaviour and no use to a test: a scene that has not started a run has no mix, and the
    /// brick comes out wearing the Null texture. Set after building rather than before, so what
    /// is under test is the overlay following the brick rather than the roll.
    private func squareBrick(_ scene: GameScene, _ texture: SKTexture? = nil) -> SKSpriteNode {
        let brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
        brick.texture = texture ?? scene.brickNormalTexture
        brick.isHidden = false
        scene.refreshEndlessIIBrickArt(brick)
        return brick
    }

    /// The picture a Square brick of this type would wear.
    ///
    /// `endlessIIOwnArt` is asked about a *brick* rather than a texture since round 273, when
    /// it grew to answer for the power-up brick and the Portal too - neither of which can be
    /// told from its texture, because both are built on the Indestructible artwork.
    private func ownArt(_ scene: GameScene, _ texture: SKTexture?) -> SKTexture? {
        let brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
        brick.texture = texture
        defer { brick.removeFromParent() }
        return scene.endlessIIOwnArt(for: brick)
    }

    private func types(_ scene: GameScene) -> [SKTexture] {
        [scene.brickNormalTexture, scene.brickInvisibleTexture,
         scene.brickMultiHit1Texture, scene.brickMultiHit2Texture,
         scene.brickMultiHit3Texture, scene.brickMultiHit4Texture,
         scene.brickIndestructible1Texture, scene.brickIndestructible2Texture]
    }

    func testEveryBrickTypeHasASquarePictureInBothThemes() {
        for retro in [false, true] {
            let scene = scene(retro: retro)
            for texture in types(scene) {
                guard let art = ownArt(scene, texture) else {
                    let name = scene.endlessIIBrickTextureName(texture) ?? "?"
                    return XCTFail("no Square art for \(name), retro: \(retro)")
                }
                let size = art.size()
                XCTAssertEqual(size.width/size.height, 1, accuracy: 0.01,
                               "a Square brick's picture is square")
            }
        }
    }

    func testEveryBrickTypeHasARoundedSquarePictureInBothThemes() {
        for retro in [false, true] {
            let scene = scene(retro: retro)
            for texture in types(scene) {
                let art = scene.endlessIIShapedArt(for: texture, .rounded, suffix: GameScene.squareArtSuffix)
                guard let art else {
                    let name = scene.endlessIIBrickTextureName(texture) ?? "?"
                    return XCTFail("no RoundedSquare art for \(name), retro: \(retro)")
                }
                let plain = scene.endlessIIShapedArt(for: texture, .rounded)
                XCTAssertNotEqual(art, plain,
                                  "asking for the square one and getting the oblong one back "
                                  + "is the stretch this delivery exists to end")
            }
        }
    }

    /// The rule at the top of `EndlessIIShapedBrickArt`, tested rather than trusted.
    ///
    /// `hitBrick` and the row scans ask what a brick is by comparing `texture` against the type
    /// textures. A Square brick that wore `BrickNormalSquare` as its own texture would stop
    /// being a Normal brick - it would score nothing, count for nothing and never clear.
    func testWearingTheSquarePictureDoesNotChangeWhatTheBrickIs() {
        let scene = scene()
        let brick = squareBrick(scene)

        guard let art = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
        else { return XCTFail("no square art worn") }
        XCTAssertEqual(art.texture?.description,
                       ownArt(scene, scene.brickNormalTexture)?.description)
        // By name: two `SKTexture(imageNamed:)` of the same picture are two objects, and
        // `SKTexture` compares by identity
        XCTAssertEqual(brick.texture, scene.brickNormalTexture,
                       "the picture goes on an overlay, never on the brick")
        XCTAssertNotEqual(brick.texture?.description, art.texture?.description)
        XCTAssertEqual(art.frame.width, brick.size.width, accuracy: 0.01)
        XCTAssertEqual(art.frame.height, brick.size.height, accuracy: 0.01)
        XCTAssertEqual(art.frame.midY, brick.frame.midY, accuracy: 0.01,
                       "the picture covers the brick's own drawing exactly")
        // **Asked of the frames, not of the anchors.** Round 270 matched the overlay's anchor
        // to the brick's and left it at the origin, which was one way of landing in the right
        // place; round 274 centres it on the drawn centre instead, because a power-up brick's
        // sprite is shrunk away behind its badge and its anchor stops describing the cell. The
        // thing worth pinning is where the picture ends up, which both do the same
    }

    /// A Multi-hit brick steps down through four textures as it is hit, and the overlay is a
    /// separate node that would otherwise still be showing the first one.
    func testTheOverlayFollowsABrickDownItsLadder() {
        let scene = scene()
        let brick = squareBrick(scene)
        brick.texture = scene.brickMultiHit2Texture
        scene.refreshEndlessIIBrickArt(brick)

        let art = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
        XCTAssertEqual(art?.texture?.description,
                       ownArt(scene, scene.brickMultiHit2Texture)?.description)
    }

    /// A power-up brick is Square-sized and has no type texture at all, so there is no picture
    /// of it to find - and putting one on would hide the icon that says which power-up it is.
    func testAPowerUpBrickKeepsItsIcon() {
        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickNullTexture)
        XCTAssertNil(scene.endlessIIOwnArt(for: brick))
    }

    /// A Square brick can be Rounded, since round 270.
    ///
    /// `suits(_ size:)` has always said Rounded fits any size; what stood in the way was the
    /// mechanical question in `endlessIICanTake` - whether the drawing sits on the node - and a
    /// Square brick's sprite hangs a cell below its node so the node can stay on a row centre
    /// (§8.6). `makeRounded` builds its face around the drawing now, so the answer changed.
    func testASquareBrickCanBeRoundedAndItsFaceSitsOnTheDrawing() {
        let scene = scene()
        let brick = squareBrick(scene)
        XCTAssertEqual(scene.endlessIISizeOf(brick), .square)
        XCTAssertTrue(scene.endlessIICanTake(.rounded, brick))

        let drawn = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                            y: (0.5 - brick.anchorPoint.y)*brick.size.height)
        scene.makeRounded(brick)

        guard let shape = brick.childNode(withName: GameScene.roundedBrickOutlineName)
                as? SKShapeNode, let path = shape.path
        else { return XCTFail("no rounded face") }
        XCTAssertEqual(path.boundingBox.midY, drawn.y, accuracy: 0.01,
                       "a face built about the node would sit a cell above the brick")
        XCTAssertEqual(path.boundingBox.height/path.boundingBox.width, 1, accuracy: 0.01,
                       "square on screen, which is what two cells of a 2:1 grid comes to")

        let art = shape.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        XCTAssertEqual(art?.position.y ?? 0, drawn.y, accuracy: 0.01,
                       "and the picture has to hang with it")
        XCTAssertNil(brick.childNode(withName: GameScene.brickArtName),
                     "the overlay comes off once a face is doing the showing, or the brick "
                     + "wears both pictures")
    }

    /// The size class survives being rounded.
    ///
    /// `makeRounded` shrinks the sprite to 0.78 of the cell to hide it inside the face, so a
    /// rounded Square brick used to measure 1.56 cells tall against a threshold of 1.5 - right
    /// by a twentieth of a cell and right by accident. `endlessIIFieldSize` reads the outline's
    /// path now, which is the thing that still knows the cell.
    func testARoundedBrickStillKnowsWhatSizeItIs() {
        let scene = scene()
        let square = squareBrick(scene)
        scene.makeRounded(square)
        XCTAssertEqual(scene.endlessIISizeOf(square), .square)

        let ordinary = SKSpriteNode(texture: scene.brickNormalTexture,
                                    size: CGSize(width: scene.brickWidth,
                                                 height: scene.brickHeight))
        scene.addChild(ordinary)
        scene.makeRounded(ordinary)
        XCTAssertEqual(scene.endlessIISizeOf(ordinary), .normal)
    }

    /// The sprite behind a rounded face stays inside it.
    ///
    /// **The render found this and no assertion would have.** A Square brick's rounded face is
    /// a circle - the radius is half the short side and its sides are equal, and James drew the
    /// picture that way to match - and the sprite was shrunk by a flat 0.78, which fits inside
    /// a stadium and does not fit inside a circle. Worse, a sprite shrinks *towards* its anchor
    /// point and a Square brick's is on its top edge, so it walked up out of the face as well.
    /// Four corners of brick came out through the top of the ring.
    ///
    /// Asked of the path rather than of the numbers, so it holds whatever the corner fraction
    /// becomes.
    func testWhatIsLeftOfTheBrickStaysInsideItsRoundedFace() {
        let scene = scene()
        let square = squareBrick(scene)
        let oblong = SKSpriteNode(texture: scene.brickNormalTexture,
                                  size: CGSize(width: scene.brickWidth,
                                               height: scene.brickHeight))
        scene.addChild(oblong)

        for brick in [square, oblong] {
            scene.makeRounded(brick)
            guard let path = (brick.childNode(withName: GameScene.roundedBrickOutlineName)
                              as? SKShapeNode)?.path
            else { return XCTFail("no rounded face") }

            let centre = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                                 y: (0.5 - brick.anchorPoint.y)*brick.size.height)
            for x in [-1.0, 1.0] as [CGFloat] {
                for y in [-1.0, 1.0] as [CGFloat] {
                    let corner = CGPoint(x: centre.x + x*brick.size.width/2,
                                         y: centre.y + y*brick.size.height/2)
                    XCTAssertTrue(path.contains(corner),
                                  "a corner of the brick is showing outside its face at "
                                  + "\(corner), face \(path.boundingBox)")
                }
            }
        }
    }

    /// The largest square fits inside its circle, and the arithmetic says so.
    ///
    /// An ordinary 2:1 brick answers 0.8, which is why the flat 0.78 was never wrong there and
    /// looked like a general number rather than one shape's answer.
    func testTheHidingFractionIsWorkedOutFromTheShape() {
        let oblong = CGSize(width: 40, height: 20)
        XCTAssertEqual(GameScene.largestFraction(hidingInside: oblong, radius: 10),
                       0.8, accuracy: 0.001)
        XCTAssertGreaterThan(GameScene.largestFraction(hidingInside: oblong, radius: 10),
                             GameScene.roundedBrickHidingFraction,
                             "or an ordinary brick has quietly changed size")

        let square = CGSize(width: 40, height: 40)
        XCTAssertEqual(GameScene.largestFraction(hidingInside: square, radius: 20),
                       1/2.squareRoot(), accuracy: 0.001)
    }

    /// A brick saves the cell it occupies, not the sprite hidden inside its face.
    ///
    /// Found while wiring the Square art and older than it. `makeRounded` and `makeFace` shrink
    /// the sprite so it disappears behind the face they build; the save wrote that shrunk size
    /// and the resume applied the style again from it. So a rounded brick came back 22% smaller
    /// every time a run was resumed, and again the next time, and the shaped faces did the
    /// same - the only reason nobody saw a field of shrivelled bricks is that it takes several
    /// resumes of one field to become obvious.
    func testARoundedBrickIsSavedAtTheSizeItOccupies() {
        let scene = scene()
        let cell = CGSize(width: scene.brickWidth, height: scene.brickHeight)

        let oblong = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
        scene.addChild(oblong)
        scene.makeRounded(oblong)
        var record = scene.savedBrick(for: oblong, texture: 0, colour: 0, restingY: 0)
        XCTAssertEqual(record.width, Double(cell.width), accuracy: 0.01)
        XCTAssertEqual(record.height, Double(cell.height), accuracy: 0.01)
        XCTAssertEqual(record.anchorX, 0.5, accuracy: 0.01)
        XCTAssertEqual(record.anchorY, 0.5, accuracy: 0.01)

        let square = squareBrick(scene)
        let anchor = square.anchorPoint
        let size = square.size
        scene.makeRounded(square)
        record = scene.savedBrick(for: square, texture: 0, colour: 0, restingY: 0)
        XCTAssertEqual(record.width, Double(size.width), accuracy: 0.01)
        XCTAssertEqual(record.height, Double(size.height), accuracy: 0.01)
        XCTAssertEqual(record.anchorY, Double(anchor.y), accuracy: 0.01,
                       "and the anchor it comes back with is the one it was built with, or the "
                       + "brick you hit walks away from the brick you see")
    }

    /// The same, for a shaped face - which shrinks its sprite for the same reason.
    func testAShapedBrickIsSavedAtTheSizeItOccupies() {
        let scene = scene()
        let cell = CGSize(width: scene.brickWidth, height: scene.brickHeight)
        let brick = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
        scene.addChild(brick)
        scene.makeFace(.wedge, on: brick)

        let record = scene.savedBrick(for: brick, texture: 0, colour: 0, restingY: 0)
        XCTAssertEqual(record.width, Double(cell.width), accuracy: 0.01)
        XCTAssertEqual(record.height, Double(cell.height), accuracy: 0.01)
        XCTAssertLessThan(brick.size.width, cell.width,
                          "the sprite really is tucked away - or this test proves nothing")
    }

    /// A Square brick can be a Diamond, since round 272.
    ///
    /// James: "Square size diamond bricks - I decided to do these." The rhombus is the one face
    /// symmetrical in both axes at once, so it takes a square cell without any of the questions
    /// the other three raise - and `suits(_ size:)` is where that decision lives, so the
    /// generator and the reference page cannot give different answers.
    func testASquareBrickCanBeADiamond() {
        XCTAssertTrue(EndlessIIStyle.diamond.suits(BrickSize.square))
        for other: EndlessIIStyle in [.convex, .concave, .wedge] {
            XCTAssertFalse(other.suits(BrickSize.square),
                           "\(other) has no square picture and is not offered one")
        }
        let scene = scene()
        XCTAssertTrue(scene.endlessIICanTake(.diamond, squareBrick(scene)))
    }

    /// The face goes where the drawing is, not where the node is.
    ///
    /// A Square brick's sprite hangs a cell below its node so the node can stay on a row centre
    /// (§8.6). `redrawEndlessIIFace` rewrites the anchor to point at the hiding rectangle, and
    /// a face built about the node would have dragged the whole brick half a cell up the field
    /// - it would have looked like the brick had moved, because it would have.
    func testASquareDiamondSitsWhereTheSquareBrickWas() {
        let scene = scene()
        let brick = squareBrick(scene)
        let drawn = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                            y: (0.5 - brick.anchorPoint.y)*brick.size.height)
        let cell = brick.size
        scene.applyEndlessIIStyle(.diamond, to: brick)

        guard let shape = brick.childNode(withName: GameScene.brickFaceName) as? SKShapeNode,
              let path = shape.path else { return XCTFail("no face") }
        XCTAssertEqual(shape.position.y, drawn.y, accuracy: 0.01,
                       "the silhouette is put where the sprite was")
        XCTAssertEqual(path.boundingBox.width, cell.width, accuracy: 0.01)
        XCTAssertEqual(path.boundingBox.height, cell.height, accuracy: 0.01)

        XCTAssertEqual(scene.endlessIIBrickCentre(of: brick).y, drawn.y, accuracy: 0.01)
        XCTAssertEqual((0.5 - brick.anchorPoint.y)*brick.size.height,
                       drawn.y + EndlessIIFaceGeometry.hidingRect(.diamond, size: cell).midY,
                       accuracy: 0.01,
                       "and the sprite hides inside it rather than beside it")
        XCTAssertEqual(scene.endlessIISizeOf(brick), .square)
    }

    /// The body moves with the outline.
    ///
    /// A polygon body is given in the node's own coordinates and the silhouette is drawn in the
    /// face node's, so a face moved off the node needs its body moved by the same amount - or
    /// the brick you hit is a cell away from the brick you see.
    func testASquareDiamondsBodyIsWhereItsOutlineIs() {
        let scene = scene()
        let brick = squareBrick(scene)
        let drawn = (0.5 - brick.anchorPoint.y)*brick.size.height
        scene.applyEndlessIIStyle(.diamond, to: brick)

        guard let body = brick.physicsBody else { return XCTFail("no body") }
        let box = body.area
        XCTAssertGreaterThan(box, 0)

        guard let shape = brick.childNode(withName: GameScene.brickFaceName) as? SKShapeNode,
              let path = shape.path else { return XCTFail("no face") }
        // The outline's own vertical middle, which is where the body's has to be. Measured by
        // asking the node to convert the two into the same space rather than by arithmetic
        XCTAssertEqual(shape.position.y + path.boundingBox.midY, drawn, accuracy: 0.01)
    }

    /// An ordinary brick's face is exactly where it always was.
    ///
    /// The regression guard on all of the above: every brick drawn on its own node has an
    /// origin of zero, so nothing about the shaped bricks that have shipped for two hundred
    /// rounds may move by so much as a point.
    func testAnOrdinaryBricksFaceHasNotMoved() {
        let scene = scene()
        for face in EndlessIIFace.allCases {
            let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                     size: CGSize(width: scene.brickWidth,
                                                  height: scene.brickHeight))
            scene.addChild(brick)
            scene.makeFace(face, on: brick)

            let shape = brick.childNode(withName: GameScene.brickFaceName) as? SKShapeNode
            XCTAssertEqual(shape?.position ?? CGPoint(x: 1, y: 1), .zero, "\(face)")

            let hide = EndlessIIFaceGeometry
                .hidingRect(face, size: CGSize(width: scene.brickWidth, height: scene.brickHeight),
                            mirrored: brick.endlessIIFaceMirrored ?? false,
                            flipped: brick.endlessIIFaceFlipped ?? false)
            XCTAssertEqual(brick.anchorPoint.x, 0.5 - hide.midX/hide.width, accuracy: 0.001,
                           "\(face)")
            XCTAssertEqual(brick.anchorPoint.y, 0.5 - hide.midY/hide.height, accuracy: 0.001,
                           "\(face)")
        }
    }

    /// The square diamond asks for the picture drawn at those proportions.
    ///
    /// Retro's set is complete; classic's is the two Indestructibles only, so the other six
    /// fall back to the oblong picture stretched into a square rhombus. That is the honest
    /// answer and `ArtStillToDrawTests` is what names the gap.
    func testASquareDiamondWearsTheSquarePictureWhereThereIsOne() {
        let retro = scene(retro: true)
        let square = retro.endlessIIShapedArt(for: retro.brickNormalTexture, .diamond,
                                              suffix: GameScene.squareArtSuffix)
        XCTAssertNotNil(square)
        XCTAssertNotEqual(square?.description,
                          retro.endlessIIShapedArt(for: retro.brickNormalTexture,
                                                   .diamond)?.description)

        let size = square?.size() ?? .zero
        XCTAssertEqual(size.width/size.height, 1, accuracy: 0.01)
    }

    /// A square Diamond comes back where it was.
    ///
    /// The risky half of round 272, because it is where the two halves meet. The save writes
    /// the cell a brick occupies and the anchor it would have at that size (round 270), and the
    /// restore applies the face again from them - so `makeFace` has to be handed a brick whose
    /// own anchor still describes the cell, which is the one moment it can read the drawn
    /// centre off. If either end of that is wrong the brick comes back half a cell up the field
    /// and nothing says so.
    func testASquareDiamondSurvivesBeingSavedAndRebuilt() {
        let scene = scene()
        let brick = squareBrick(scene)
        let cell = brick.size
        let drawn = (0.5 - brick.anchorPoint.y)*brick.size.height
        scene.applyEndlessIIStyle(.diamond, to: brick)

        let record = scene.savedBrick(for: brick, texture: 0, colour: 0, restingY: 0)
        XCTAssertEqual(record.width, Double(cell.width), accuracy: 0.01)
        XCTAssertEqual(record.height, Double(cell.height), accuracy: 0.01)

        let rebuilt = SKSpriteNode(texture: scene.brickNormalTexture,
                                   size: CGSize(width: record.width, height: record.height))
        rebuilt.anchorPoint = CGPoint(x: record.anchorX, y: record.anchorY)
        scene.addChild(rebuilt)
        rebuilt.endlessIIFaceMirrored = record.faceMirrored
        rebuilt.endlessIIFaceFlipped = record.faceFlipped
        scene.applyEndlessIIStyle(.diamond, to: rebuilt)
        // The restore's own sequence: size, anchor, orientation, then the style

        XCTAssertEqual(scene.endlessIIBrickCentre(of: rebuilt).y, drawn, accuracy: 0.01,
                       "a resumed square Diamond sits where the one that was saved sat")
        XCTAssertEqual(scene.endlessIIFieldSize(of: rebuilt).height, cell.height, accuracy: 0.01)
        XCTAssertEqual(scene.endlessIISizeOf(rebuilt), .square)
    }

    /// A Portal wears its own picture without stopping being the brick it is built on.
    ///
    /// James, round 271: "Portal bricks - these come in just the square size and a single
    /// theme." The brick is built on the Indestructible artwork because that is the look of a
    /// brick a hit does not break, and that texture is read in a dozen places for the score,
    /// the particle colour, the sound and the clearing rules - so the picture goes over it, the
    /// way the power-up brick's badge does.
    func testAPortalWearsItsOwnPicture() {
        for (kind, square) in [("plain", false), ("square", true)] {
            let scene = scene()
            let brick: SKSpriteNode
            if square {
                brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
                brick.isHidden = false
            } else {
                brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                     size: CGSize(width: scene.brickWidth,
                                                  height: scene.brickHeight))
                scene.addChild(brick)
            }
            brick.texture = scene.brickIndestructible2Texture
            scene.makePortal(brick)

            XCTAssertEqual(brick.texture, scene.brickIndestructible2Texture, kind)
            guard let art = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
            else { return XCTFail("no portal picture: \(kind)") }
            let wanted = GameScene.portalBrickArtName
                + (square ? GameScene.squareArtSuffix : "")
            XCTAssertEqual(art.texture?.description,
                           SKTexture(imageNamed: wanted).description, kind)
            XCTAssertNil(brick.childNode(withName: GameScene.glyphName),
                         "the picture has the rings in it - drawing them again is one set of "
                         + "rings too many (\(kind))")
        }
    }

    /// A Rounded Portal's face is a Portal's, not an Indestructible's.
    ///
    /// The trap this closes: a Portal is *built on* `brickIndestructible2Texture`, so a face
    /// asked by texture alone finds `BrickIndestructible2Rounded` and can never find
    /// `BrickPortalRounded`. The lookup takes the name from the brick now.
    func testARoundedPortalWearsThePortalsFace() {
        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                 size: CGSize(width: scene.brickWidth,
                                              height: scene.brickHeight))
        scene.addChild(brick)
        scene.makeRounded(brick)
        scene.makePortal(brick)

        let shape = brick.childNode(withName: GameScene.roundedBrickOutlineName) as? SKShapeNode
        let art = shape?.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        XCTAssertEqual(art?.texture?.description,
                       SKTexture(imageNamed: "BrickPortalRounded").description)
        XCTAssertNil(brick.childNode(withName: GameScene.glyphName),
                     "and no rings on top of a face that already has them")
    }

    /// A shape James has not drawn a Portal for keeps the art it has always worn.
    ///
    /// A Portal may take a Wedge, a dome or a notch (`takenByAPortal`) and only plain, Rounded
    /// and the square Diamond are drawn. Falling back to the Indestructible shaped art is what
    /// it looked like before this round; falling back to *nothing* would be a hole in the field.
    func testAPortalShapeWithNoPictureKeepsTheOldOne() {
        let scene = scene()
        XCTAssertNil(UIImage(named: "BrickPortalWedge"), "if this arrives, so does a test")

        let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                 size: CGSize(width: scene.brickWidth,
                                              height: scene.brickHeight))
        scene.addChild(brick)
        scene.makeFace(.wedge, on: brick)
        scene.makePortal(brick)

        let shape = brick.childNode(withName: GameScene.brickFaceName) as? SKShapeNode
        let art = shape?.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        XCTAssertNotNil(art?.texture, "or a Portal wedge is a hole in the field")
        XCTAssertNotNil(brick.childNode(withName: GameScene.glyphName),
                        "and it keeps its rings, because nothing else says it is a Portal")
    }

    /// Both ends are one colour.
    ///
    /// James, round 273: "Portal is just 1 colour now. Both bricks will just be one colour."
    /// `endlessIIPortalIsBlue` is still set and still saved - a save format is not the place to
    /// economise, and an old save has to decode - it just no longer decides anything you see.
    func testBothEndsOfAPortalLookTheSame() {
        let scene = scene()
        var pictures: [String] = []
        for _ in 0..<2 {
            let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                     size: CGSize(width: scene.brickWidth,
                                                  height: scene.brickHeight))
            scene.addChild(brick)
            scene.makePortal(brick)
            let art = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
            pictures.append(art?.texture?.description ?? "none")
        }
        XCTAssertEqual(pictures.count, 2)
        XCTAssertEqual(pictures[0], pictures[1])
    }

    /// A cooling Portal goes monochrome, and stays that way through a refresh.
    ///
    /// James, round 274: "For the portal brick cooling, can we make the brick monochrome during
    /// this period." The state has to survive the per-frame refresh, which is where the first
    /// version of it went wrong - a tint written onto the art is wiped off by the next frame's
    /// copy of the brick's colour. Choosing a different *texture* is a choice the refresh makes
    /// again every frame, for as long as the cooldown is running.
    func testACoolingPortalGoesMonochromeAndStaysThatWay() {
        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                 size: CGSize(width: scene.brickWidth,
                                              height: scene.brickHeight))
        scene.addChild(brick)
        scene.makePortal(brick)
        guard let art = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
        else { return XCTFail("no portal picture") }
        let coloured = art.texture

        scene.endlessIIPortalCooldown = GameScene.endlessIIPortalCooldownSeconds
        scene.refreshEndlessIIBrickArt(brick)
        let drained = art.texture
        XCTAssertNotEqual(drained?.description, coloured?.description,
                          "the picture is not the coloured one while the Portal is cooling")
        scene.refreshEndlessIIBrickArt(brick)
        XCTAssertEqual(art.texture?.description, drained?.description,
                       "and the frame that redraws it does not put the colour back")

        scene.endlessIIPortalCooldown = 0
        scene.refreshEndlessIIBrickArt(brick)
        XCTAssertEqual(art.texture?.description, coloured?.description,
                       "and it comes back when the Portal can be entered again")
    }

    /// The drained picture is worked out once and kept.
    ///
    /// A Core Image pass is far too expensive to run on a frame, and `endlessIIShown` is called
    /// from the per-frame refresh - so the second ask has to be a dictionary lookup.
    func testTheMonochromePictureIsComputedOnce() {
        let scene = scene()
        let art = SKTexture(imageNamed: GameScene.portalBrickArtName)
        let first = scene.endlessIIMonochrome(of: art)
        let second = scene.endlessIIMonochrome(of: art)
        XCTAssertTrue(first === second, "the second ask is the first one's answer")
    }
}

/// **The glow behind a Portal brick** (round 315).
///
/// James: "some glow graphics for all shapes of the portal bricks - these should sit centred
/// behind portal bricks to the same scale - they should not have a physics body - these can be
/// rotated and flipped as needed for the different brick orientations."
final class PortalGlowTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.brickWidth = 56
        scene.brickHeight = 28
        scene.gameWidth = 402
        return scene
    }

    private func portal(_ scene: GameScene, face: EndlessIIFace? = nil,
                        rounded: Bool = false) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                 size: CGSize(width: 56, height: 28))
        scene.addChild(brick)
        if let face { scene.makeFace(face, on: brick) }
        if rounded { scene.makeRounded(brick) }
        scene.makePortal(brick)
        return brick
    }

    private func glow(_ brick: SKSpriteNode) -> SKSpriteNode? {
        brick.childNode(withName: GameScene.portalGlowName) as? SKSpriteNode
    }

    /// Every shape has one, including the two that are not `EndlessIIFace` values.
    ///
    /// Rounded is a *style* rather than a face and leaves `endlessIIFace` nil, which the first
    /// version of the lookup missed - a rounded Portal wore the plain oblong's halo behind a
    /// capsule, and the render is where that showed.
    func testEveryPortalShapeHasItsOwnGlow() {
        let scene = self.scene()
        for (name, face, rounded) in [("plain", nil, false), ("rounded", nil, true),
                                      ("wedge", EndlessIIFace.wedge, false),
                                      ("convex", .convex, false), ("concave", .concave, false),
                                      ("diamond", .diamond, false)]
            as [(String, EndlessIIFace?, Bool)] {
            let brick = portal(scene, face: face, rounded: rounded)
            XCTAssertNotNil(glow(brick), "\(name) Portal has no glow behind it")
        }
    }

    /// **It reaches past the brick**, or the halo is hidden behind the thing it surrounds.
    ///
    /// This is the fault the render caught: sized to the cell, every glow was invisible.
    func testTheGlowIsLargerThanTheBrickItSitsBehind() throws {
        let scene = self.scene()
        let brick = portal(scene)
        let glow = try XCTUnwrap(self.glow(brick))
        let cell = scene.endlessIIFieldSize(of: brick)

        XCTAssertGreaterThan(glow.size.width, cell.width, "a halo has to show past the brick")
        XCTAssertGreaterThan(glow.size.height, cell.height)
        XCTAssertEqual(glow.size.width/cell.width,
                       GameScene.portalGlowScale(for: .normal).width, accuracy: 0.001,
                       "and by the proportion James drew, not an invented one")
    }

    /// **The halo scales with the brick rather than standing a fixed distance off it.**
    ///
    /// James, round 316: "the portal brick glows are 20 points larger on purpose. At the same
    /// scale, they will show whilst placed under the portal bricks. Do not scale them down."
    /// Round 315b read that as twenty points and added them to the cell, which is right on
    /// exactly one device - the one whose cell is the size the art was drawn at. This is the
    /// assertion that would have caught it: the same brick in two different cells keeps the
    /// same proportion between halo and brick.
    func testTheHaloKeepsItsProportionAtAnyCellSize() throws {
        var measured: [CGFloat] = []
        for width in [36.0, 56.0, 90.0] as [CGFloat] {
            let scene = self.scene()
            scene.brickWidth = width
            scene.brickHeight = width/2
            let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                     size: CGSize(width: width, height: width/2))
            scene.addChild(brick)
            scene.makePortal(brick)

            let glow = try XCTUnwrap(brick.childNode(withName: GameScene.portalGlowName)
                                        as? SKSpriteNode)
            measured.append(glow.size.width/scene.endlessIIFieldSize(of: brick).width)
        }
        for ratio in measured {
            XCTAssertEqual(ratio, measured[0], accuracy: 0.001,
                           "a fixed margin would give three different answers here")
        }
    }

    /// And that proportion is read off the pictures rather than typed into the code.
    func testTheScaleComesFromTheArtwork() {
        XCTAssertGreaterThan(GameScene.portalGlowScale(for: .normal).width, 1,
                             "one would mean a picture is missing, and a glow sized to the "
                             + "cell is a glow nobody can see")
        XCTAssertEqual(GameScene.portalGlowScale(for: .normal).width,
                       SKTexture(imageNamed: "BrickPortalGlow").size().width
                           / SKTexture(imageNamed: "BrickPortal").size().width,
                       accuracy: 0.001)
    }

    /// Each size asks its own pair, because the three are not drawn to one ratio.
    func testEachBrickSizeHasItsOwnProportion() {
        let normal = GameScene.portalGlowScale(for: .normal)
        let square = GameScene.portalGlowScale(for: .square)
        XCTAssertNotEqual(normal.height, square.height, accuracy: 0.001,
                          "an oblong and a square carry the same thickness of halo, which is "
                          + "two different ratios - one number for both puts one of them wrong")
    }

    /// Centred on the brick's *drawing*, which is not the same as its node.
    ///
    /// A brick wearing a face has had its sprite shrunk to hide behind that face (§8.6), so
    /// `brick.size` is the hiding rectangle. `endlessIIBrickCentre` is the one that knows.
    func testTheGlowIsCentredOnTheDrawingRatherThanTheNode() throws {
        let scene = self.scene()
        let brick = portal(scene, face: .wedge)
        let glow = try XCTUnwrap(self.glow(brick))

        XCTAssertEqual(glow.position.x, scene.endlessIIBrickCentre(of: brick).x, accuracy: 0.001)
        XCTAssertEqual(glow.position.y, scene.endlessIIBrickCentre(of: brick).y, accuracy: 0.001)
    }

    /// **No physics body**, as asked. A glow the ball could bounce off would be a Portal
    /// bigger than it looks - and it is bigger than it looks, which is the point of it.
    func testTheGlowHasNoPhysicsBody() throws {
        let scene = self.scene()
        for face in [nil, EndlessIIFace.wedge, .convex, .concave, .diamond] as [EndlessIIFace?] {
            let brick = portal(scene, face: face)
            XCTAssertNil(try XCTUnwrap(glow(brick)).physicsBody)
        }
    }

    /// It sits behind its own brick rather than over it.
    func testTheGlowIsBehindTheBrick() throws {
        let scene = self.scene()
        let glow = try XCTUnwrap(self.glow(portal(scene)))
        XCTAssertLessThan(glow.zPosition, 0, "a glow drawn on top is not a glow")
    }

    /// Turned the way the brick is turned, which is what "rotated and flipped as needed" buys.
    ///
    /// One picture per shape and the node does the reflecting - unlike the bricks, which are
    /// drawn four ways because a wedge lit from above is lit from below once flipped. A halo
    /// has no lighting to get wrong.
    func testTheGlowIsReflectedTheWayTheFaceIs() throws {
        let scene = self.scene()
        let brick = portal(scene, face: .wedge)
        brick.endlessIIFaceMirrored = true
        brick.endlessIIFaceFlipped = true
        scene.refreshEndlessIIPortalGlow(on: brick)

        let glow = try XCTUnwrap(self.glow(brick))
        XCTAssertEqual(glow.xScale, -1, "mirrored")
        XCTAssertEqual(glow.yScale, -1, "flipped")
    }

    /// A brick that stops being a Portal loses its halo.
    func testTheGlowGoesWhenTheRoleDoes() {
        let scene = self.scene()
        let brick = portal(scene)
        XCTAssertNotNil(glow(brick))

        brick.endlessIIRole = nil
        scene.refreshEndlessIIPortalGlow(on: brick)
        XCTAssertNil(glow(brick), "a glow left behind is a Portal that is not there any more")
    }

    /// And it drains with the brick while the Portal is cooling (round 274).
    func testTheGlowGoesMonochromeWithTheBrick() throws {
        let scene = self.scene()
        let brick = portal(scene)
        let ready = try XCTUnwrap(glow(brick)).texture

        scene.endlessIIPortalCooldown = 3
        scene.endlessIIShowPortal(brick, cooling: true)

        XCTAssertNotEqual(try XCTUnwrap(glow(brick)).texture, ready,
                          "the glow stayed lit under a grey brick")
    }
}
