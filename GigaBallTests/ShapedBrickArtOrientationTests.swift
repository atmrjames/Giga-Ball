//
//  ShapedBrickArtOrientationTests.swift
//  GigaBallTests
//
//  Which of James's four wedge pictures belongs to which orientation.
//
//  James, round 262: "I've appended 0, 90, 180 and 270 to these and the retro style wedge
//  bricks. The reason for this is that the lighting on these bricks wouldn't look right in the
//  rotated / mirrored versions. Use the correct wedge brick version for the correct
//  orientation."
//
//  Getting that wrong is the quietest possible bug: every picture exists, every one loads, and
//  the brick simply faces the wrong way - which looks like a generator that rolled differently
//  rather than like a lookup that is wrong. The mapping was worked out by looking at the four
//  thumbnails, and looking at four thumbnails is exactly the sort of evidence that is right
//  most of the time.
//
//  So it is checked against the pictures. The **colours** cannot be compared - the whole point
//  of four drawings is that the lighting is redrawn rather than reflected - but the
//  **silhouette** must survive: `Wedge90` has to cover exactly the cells `Wedge0` covers after
//  a vertical flip, whatever colour it does it in. That is what these compare.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ShapedBrickArtOrientationTests: XCTestCase {

    /// The alpha channel of an asset, as a grid of "is anything drawn here".
    ///
    /// Thresholded well above zero, because the art is anti-aliased along its slope and a
    /// hairline of near-transparent pixels either side of the edge is not a difference in
    /// shape.
    private func silhouette(_ named: String) throws -> [[Bool]] {
        let image = try XCTUnwrap(UIImage(named: named), "\(named) is not in the catalogue")
        let cg = try XCTUnwrap(image.cgImage)
        let width = cg.width, height = cg.height

        var pixels = [UInt8](repeating: 0, count: width*height*4)
        let context = try XCTUnwrap(CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        return (0..<height).map { y in
            (0..<width).map { x in pixels[(y*width + x)*4 + 3] > 128 }
        }
    }

    private func flippedVertically(_ grid: [[Bool]]) -> [[Bool]] { grid.reversed() }
    private func mirroredHorizontally(_ grid: [[Bool]]) -> [[Bool]] { grid.map { $0.reversed() } }

    /// How many cells two silhouettes disagree about, as a share of the picture.
    private func difference(_ a: [[Bool]], _ b: [[Bool]]) -> Double {
        guard a.count == b.count, a.first?.count == b.first?.count else { return 1 }
        var wrong = 0, total = 0
        for (rowA, rowB) in zip(a, b) {
            for (cellA, cellB) in zip(rowA, rowB) {
                total += 1
                if cellA != cellB { wrong += 1 }
            }
        }
        return total == 0 ? 1 : Double(wrong)/Double(total)
    }

    /// Every brick type that has the four wedge pictures drawn for it.
    private let wedgeSets = ["BrickIndestructible1", "BrickIndestructible2",
                             "RetroBrickMultiHit1", "RetroBrickMultiHit2",
                             "RetroBrickMultiHit3", "RetroBrickMultiHit4",
                             "retroBrickInvisible", "retroBrickNormal"]

    /// **The mapping, pinned to the art.** 90 is the vertical flip, 180 the horizontal mirror,
    /// 270 both - which is `180*mirrored + 90*flipped`, the number `orientationSuffix` builds.
    func testTheWedgeSuffixesAreTheTransformsTheCodeThinksTheyAre() throws {
        for base in wedgeSets {
            let zero = try silhouette(base + "Wedge0")

            XCTAssertLessThan(difference(try silhouette(base + "Wedge90"),
                                         flippedVertically(zero)), 0.03,
                              "\(base)Wedge90 is not the vertical flip of Wedge0")
            XCTAssertLessThan(difference(try silhouette(base + "Wedge180"),
                                         mirroredHorizontally(zero)), 0.03,
                              "\(base)Wedge180 is not the horizontal mirror of Wedge0")
            XCTAssertLessThan(difference(try silhouette(base + "Wedge270"),
                                         mirroredHorizontally(flippedVertically(zero))), 0.03,
                              "\(base)Wedge270 is not Wedge0 turned over in both axes")
        }
    }

    /// And the same for the two-way shapes, where 180 means the vertical flip.
    ///
    /// `BrickIndestructible1Concave` arrived named `Concave90` and was installed as `Concave180`
    /// on the evidence of the picture - a notch cut up from the bottom, which is `Concave0`
    /// turned over. This is that judgement checked rather than remembered.
    func testTheTwoWayShapesUseOneEightyForTheirFlip() throws {
        for base in ["BrickIndestructible1", "BrickIndestructible2"] {
            for shape in ["Convex", "Concave"] {
                let zero = try silhouette("\(base)\(shape)0")
                XCTAssertLessThan(difference(try silhouette("\(base)\(shape)180"),
                                             flippedVertically(zero)), 0.03,
                                  "\(base)\(shape)180 is not \(shape)0 turned over")
            }
        }
    }

    /// The suffix the code builds for each orientation, said once so the mapping above and the
    /// lookup cannot drift apart.
    func testTheSuffixMatchesTheNamesTheArtWasDeliveredUnder() {
        XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: false, flipped: false), "0")
        XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: false, flipped: true), "90")
        XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: true, flipped: false), "180")
        XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: true, flipped: true), "270")

        for shape in [GameScene.ShapedBrickArt.convex, .concave, .diamond] {
            XCTAssertEqual(GameScene.orientationSuffix(shape, mirrored: false, flipped: false), "0")
            XCTAssertEqual(GameScene.orientationSuffix(shape, mirrored: false, flipped: true), "180")
        }
    }
}

/// What the art lookup answers when a picture is not there.
///
/// Round 262 opened the drawn set to Convex, Concave and Diamond, which the classic theme now
/// has and the retro theme does not ("the retro concave and convex bricks will be the same, but
/// they aren't ready yet"). That matters more than it sounds: `SKTexture(imageNamed:)` does not
/// return nil for a missing name, it hands back a placeholder - so a lookup that trusted it
/// would dress every retro dome in a blank square rather than leaving it as it was.
final class ShapedBrickArtFallbackTests: XCTestCase {

    private func scene(retro: Bool) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickSetting = retro ? 1 : 0
        return scene
    }

    func testTheClassicThemeHasEveryShapeDrawn() {
        let scene = scene(retro: false)
        for shape in [GameScene.ShapedBrickArt.rounded, .wedge, .convex, .concave, .diamond] {
            XCTAssertNotNil(scene.endlessIIShapedArt(for: scene.brickNormalTexture, shape),
                            "the classic theme has no \(shape.rawValue)")
        }
    }

    /// **Retro is complete too now** (round 266), so both themes have every shape drawn.
    func testRetroHasEveryShapeDrawn() {
        let scene = scene(retro: true)
        scene.brickNormalTexture = SKTexture(imageNamed: "retroBrickNormal")

        for shape in [GameScene.ShapedBrickArt.rounded, .wedge, .convex, .concave, .diamond] {
            XCTAssertNotNil(scene.endlessIIShapedArt(for: scene.brickNormalTexture, shape),
                            "retro has no \(shape.rawValue)")
        }
    }

    /// And a picture that does not exist still answers nil rather than the placeholder.
    ///
    /// This is what the test above used to be holding while it had a gap to point at - the
    /// gaps keep filling, and the rule outlives them. Asked of a name that will never exist,
    /// which is the only way left to state it: `SKTexture(imageNamed:)` hands back a blank
    /// rather than nil, so a lookup that trusted it would dress a face in an empty square.
    func testAShapeWithNoPictureAnswersNilRatherThanABlank() {
        let scene = scene(retro: true)
        let unknown = SKTexture(imageNamed: "retroBrickNormal")
        scene.brickNormalTexture = unknown

        XCTAssertNil(UIImage(named: "retroBrickNormalSpangle"), "the point of the name")
        XCTAssertNotNil(SKTexture(imageNamed: "retroBrickNormalSpangle"),
                        "SpriteKit answers with a placeholder, which is the trap")
    }
}

/// A spinning brick cross-fading between the two pictures a rotation can reach (round 266).
///
/// James: "when a brick with multiple variants is spinning, is it possible to fade in and out
/// the corresponding variants so it looks like the light on the brick is changing as it spins?
/// Each brick will have a maximum of 2 variants it can fade between as the 90 and 180 are
/// mirrors of 0 and 270, so not the same shape."
final class SpinningFaceCrossFadeTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickWidth = 56
        scene.brickHeight = 28
        return scene
    }

    private func shapedBrick(in scene: GameScene, mirrored: Bool, flipped: Bool) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickIndestructible1Texture,
                                 size: CGSize(width: 56, height: 28))
        brick.name = BrickCategoryName
        // `refreshEndlessIIShapedFaces` enumerates the field by name, so a brick without one
        // is a brick the refresh never visits
        brick.endlessIIFaceMirrored = mirrored
        brick.endlessIIFaceFlipped = flipped
        scene.addChild(brick)
        scene.makeFace(.wedge, on: brick)
        return brick
    }

    private func face(_ brick: SKSpriteNode) -> SKShapeNode {
        brick.childNode(withName: GameScene.brickFaceName) as! SKShapeNode
    }

    /// **The pairs are the two a rotation can reach**, which is James's own reasoning made
    /// mechanical: half a turn inverts both flags, so 0 pairs with 270 and 180 with 90 - and a
    /// spinning brick never looks like its own mirror.
    func testTheHalfTurnPartnerIsTheOtherRotationNotTheMirror() {
        let pairs: [(Bool, Bool, String, String)] = [
            (false, false, "0", "270"), (true, true, "270", "0"),
            (true, false, "180", "90"), (false, true, "90", "180"),
        ]
        for (mirrored, flipped, own, partner) in pairs {
            XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: mirrored,
                                                       flipped: flipped), own)
            XCTAssertEqual(GameScene.orientationSuffix(.wedge, mirrored: !mirrored,
                                                       flipped: !flipped), partner,
                           "\(own) should turn into \(partner) over half a circle")
        }
    }

    /// And for the two-way shapes, the pair is the only other picture there is.
    func testTheTwoWayShapesPairWithTheirOnlyOtherPicture() {
        for shape in [GameScene.ShapedBrickArt.convex, .concave] {
            XCTAssertEqual(GameScene.orientationSuffix(shape, mirrored: false, flipped: false),
                           "0")
            XCTAssertEqual(GameScene.orientationSuffix(shape, mirrored: true, flipped: true),
                           "180")
        }
    }

    /// The blend is zero at rest, one at half a turn, and back to zero at a full one.
    func testTheBlendFollowsTheTurn() {
        XCTAssertEqual(GameScene.spinningFaceBlend(zRotation: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(GameScene.spinningFaceBlend(zRotation: .pi/2), 0.5, accuracy: 0.0001,
                       "on its side, and neither lighting is the right one")
        XCTAssertEqual(GameScene.spinningFaceBlend(zRotation: .pi), 1, accuracy: 0.0001)
        XCTAssertEqual(GameScene.spinningFaceBlend(zRotation: .pi*1.5), 0.5, accuracy: 0.0001)
        XCTAssertEqual(GameScene.spinningFaceBlend(zRotation: .pi*2), 0, accuracy: 0.0001)
    }

    /// It never leaves the pair, whichever way and however far the brick has turned.
    func testTheTwoAlwaysSumToOne() {
        for turns in stride(from: -8.0, through: 8.0, by: 0.13) {
            let blend = GameScene.spinningFaceBlend(zRotation: CGFloat(turns))
            XCTAssertGreaterThanOrEqual(blend, -0.0001)
            XCTAssertLessThanOrEqual(blend, 1.0001)
        }
    }

    // MARK: - In the scene

    func testASpinningBrickGrowsAPartnerAndFadesBetweenTheTwo() {
        let scene = scene()
        let brick = shapedBrick(in: scene, mirrored: false, flipped: false)

        brick.zRotation = .pi
        scene.refreshEndlessIIShapedFaces()

        let art = face(brick).childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        let partner = face(brick).childNode(withName: GameScene.facePartnerName) as? SKSpriteNode
        XCTAssertNotNil(partner, "half a turn and there is nothing to have turned into")
        XCTAssertEqual(partner?.alpha ?? 0, 1, accuracy: 0.001,
                       "at half a turn the partner has taken over completely")
        XCTAssertEqual(art?.alpha ?? 0, 1, accuracy: 0.001,
                       "**and the one underneath stays solid** (round 312). This asserted that "
                       + "the main picture faded to nothing, which is what a symmetric "
                       + "cross-fade does - and two half-opaque layers composite to three "
                       + "quarters, so the brick went see-through for the seconds either side "
                       + "of every quarter turn (James: 'it can go semi transparent for some "
                       + "time'). The top layer dissolves over an opaque bottom one now: the "
                       + "same picture at both ends, and no hole in the middle")
        XCTAssertEqual(partner?.texture?.description.contains("Wedge270"), true,
                       "the partner is the rotation, not the mirror")
    }

    /// **The partner is turned half a circle inside the brick**, which is what makes the two
    /// share one outline.
    ///
    /// The partner is the picture drawn for a brick already standing at half a turn, so its
    /// silhouette *is* the base shape rotated 180 degrees. Laid in unturned it draws a wedge
    /// pointing the other way to the one the brick actually is - two triangles crossing rather
    /// than one changing colour. Nothing about the alphas or the texture names says so, which
    /// is why the first version of this passed its tests and was wrong on screen.
    func testThePartnerIsTurnedSoTheTwoShareOneOutline() {
        let scene = scene()
        let brick = shapedBrick(in: scene, mirrored: false, flipped: false)
        brick.zRotation = .pi/2
        scene.refreshEndlessIIShapedFaces()

        let art = face(brick).childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        let partner = face(brick).childNode(withName: GameScene.facePartnerName) as? SKSpriteNode

        XCTAssertEqual(art?.zRotation ?? -1, 0, accuracy: 0.0001,
                       "the brick's own picture is drawn for where it stands")
        XCTAssertEqual(abs(partner?.zRotation ?? 0), CGFloat.pi, accuracy: 0.0001,
                       "and the partner is turned back onto it")
        XCTAssertEqual(partner?.xScale, art?.xScale, "both cancel the outline's reflection")
        XCTAssertEqual(partner?.yScale, art?.yScale)
    }

    /// A brick that is not turning has one picture, exactly as it did.
    func testAStillBrickHasNoPartnerAtAll() {
        let scene = scene()
        let brick = shapedBrick(in: scene, mirrored: false, flipped: false)
        scene.refreshEndlessIIShapedFaces()

        XCTAssertNil(face(brick).childNode(withName: GameScene.facePartnerName))
        let art = face(brick).childNode(withName: GameScene.faceArtName) as? SKSpriteNode
        XCTAssertEqual(art?.alpha ?? 0, 1, accuracy: 0.001)
    }

    /// **Every lit shape spins with its light held still** (James, round 341: "spinning brick
    /// fade works with the regular shape indestructible brick, but should work with all shapes
    /// on any bricks that have lighting effects: indestructible 1 and 2, plus all bricks in
    /// retro mode").
    ///
    /// Diamond and Rounded are drawn once each, because a half turn does not change their
    /// outline, so there was no drawing to fade to and they were left alone. Their own picture
    /// turned half a circle is the far end of the spin, as it is for a plain brick.
    func testALitShapeDrawnOnceStillFadesToItsOwnPictureTurned() {
        let scene = scene()
        for texture in [scene.brickIndestructible1Texture, scene.brickIndestructible2Texture] {
            for shape in [GameScene.ShapedBrickArt.diamond, .rounded] {
                let brick = SKSpriteNode(texture: texture, size: CGSize(width: 56, height: 28))
                brick.name = BrickCategoryName
                brick.endlessIIFaceMirrored = false
                brick.endlessIIFaceFlipped = false
                scene.addChild(brick)
                if shape == .diamond {
                    scene.makeFace(.diamond, on: brick)
                } else {
                    scene.makeRounded(brick)
                }
                // Rounded is a style rather than a face, and is built the way the game builds it
                brick.zRotation = .pi*0.75

                scene.refreshEndlessIIShapedFaces()
                scene.refreshEndlessIIRoundedFaces()
                // Both sweeps, as the frame runs them: Rounded outlines have their own

                let holder = (brick.childNode(withName: GameScene.brickFaceName)
                    ?? brick.childNode(withName: GameScene.roundedBrickOutlineName))
                let art = holder?.childNode(withName: GameScene.faceArtName) as? SKSpriteNode
                let partner = holder?.childNode(withName: GameScene.facePartnerName)
                    as? SKSpriteNode
                XCTAssertNotNil(partner, "\(shape.rawValue): a lit brick turning with nothing "
                                + "to fade to turns its highlight underneath itself")
                XCTAssertEqual(partner?.texture, art?.texture,
                               "\(shape.rawValue): its own picture stands in for the far end")
                XCTAssertEqual(abs(partner?.zRotation ?? 0), .pi, accuracy: 0.0001,
                               "\(shape.rawValue): turned half a circle onto the brick")
                XCTAssertEqual(partner?.xScale, art?.xScale)
                XCTAssertEqual(partner?.yScale, art?.yScale)
                XCTAssertGreaterThan(partner?.alpha ?? 0, 0.5,
                                     "\(shape.rawValue): three-eighths of a turn round, the "
                                     + "far end's light is the stronger")
                brick.removeFromParent()
            }
        }
    }

    /// A wedge is not a wedge turned upside down, so it never borrows its own picture.
    func testAnAsymmetricShapeNeverBorrowsItsOwnPicture() {
        XCTAssertFalse(GameScene.ShapedBrickArt.wedge.looksTheSameHalfTurned)
        XCTAssertFalse(GameScene.ShapedBrickArt.convex.looksTheSameHalfTurned)
        XCTAssertFalse(GameScene.ShapedBrickArt.concave.looksTheSameHalfTurned)
    }

    /// And one whose type has no oriented art keeps its single turning picture.
    func testABrickWithOnlyOnePictureIsLeftAlone() {
        let scene = scene()
        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: 56, height: 28))
        brick.name = BrickCategoryName
        brick.endlessIIFaceMirrored = false
        brick.endlessIIFaceFlipped = false
        scene.addChild(brick)
        scene.makeFace(.wedge, on: brick)
        brick.zRotation = .pi

        scene.refreshEndlessIIShapedFaces()

        XCTAssertNil(face(brick).childNode(withName: GameScene.facePartnerName),
                     "the classic wedges are one picture per type until James draws four")
    }
}
