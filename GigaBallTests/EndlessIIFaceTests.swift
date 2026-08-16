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

    func testTheWedgeIsTheOnlyFaceWhoseSpriteSitsOffCentre() {
        // Which is the whole reason hiding rectangles are rectangles rather than a scale
        // factor. If a dome or a notch ever needs an offset too, this is the reminder to
        // check that nothing else assumed the sprite was centred.
        for face in EndlessIIFace.allCases {
            let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell)
            let centred = abs(hide.midX) < 0.001 && abs(hide.midY) < 0.001
            XCTAssertEqual(centred, face != .wedge, "\(face)")
        }
    }

    func testMirroringAWedgeReflectsItRatherThanMovingIt() {
        let right = EndlessIIFaceGeometry.corners(.wedge, size: cell)
        let left = EndlessIIFaceGeometry.corners(.wedge, size: cell, mirrored: true)
        XCTAssertEqual(Set(right.map { abs($0.x) }), Set(left.map { abs($0.x) }))
        XCTAssertEqual(right.map(\.x).reduce(0, +), -left.map(\.x).reduce(0, +),
                       accuracy: 0.001, "a mirrored wedge points the other way")
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

    func testConvexAndConcaveHaveNoDrawnFaceYet() {
        // §8.5. Stated rather than assumed, so the day they are drawn the test says where
        XCTAssertNil(GameScene.shapedArt(for: .convex))
        XCTAssertNil(GameScene.shapedArt(for: .concave))
        XCTAssertEqual(GameScene.shapedArt(for: .wedge), .wedge)

        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        XCTAssertEqual(scene.endlessIIFaceFill(brick, GameScene.shapedArt(for: .convex)),
                       brick.texture, "the dome still stretches the rectangle")
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

    func testAFaceWithNoDrawnArtStillGetsItsOldFill() {
        // Convex and Concave (§8.5). They keep the stretched texture until they are drawn,
        // and the fallback has to stay wired or they would come out blank
        let scene = retro()
        let subject = brick(scene)
        scene.makeFace(.convex, on: subject)

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
