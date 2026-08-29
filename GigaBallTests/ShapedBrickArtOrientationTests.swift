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

    /// Retro has Rounded and Wedge and is waiting for the rest.
    func testRetroKeepsItsStretchedFillWhereTheArtIsNotDrawnYet() {
        let scene = scene(retro: true)
        scene.brickNormalTexture = SKTexture(imageNamed: "retroBrickNormal")

        for shape in [GameScene.ShapedBrickArt.rounded, .wedge] {
            XCTAssertNotNil(scene.endlessIIShapedArt(for: scene.brickNormalTexture, shape),
                            "retro has had \(shape.rawValue) since round 153")
        }
        for shape in [GameScene.ShapedBrickArt.convex, .concave, .diamond] {
            XCTAssertNil(scene.endlessIIShapedArt(for: scene.brickNormalTexture, shape),
                         "retro's \(shape.rawValue) is not drawn, so the honest answer is "
                         + "nil and the face keeps stretching the brick's own texture")
        }
    }
}
