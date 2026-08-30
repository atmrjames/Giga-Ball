//
//  ArtStillToDrawTests.swift
//  GigaBallTests
//
//  What art is missing, asked of the catalogue rather than remembered.
//
//  §8.5 is the shopping list James works from, and three separate tests have gone stale in
//  three rounds by naming a gap he then filled: "Convex and Concave, both themes" became
//  "retro's Convex", became "retro's Concave", became nothing at all. Each time the test was
//  asserting that a picture which now exists did not, and each time it had to be rewritten to
//  point somewhere else.
//
//  The mistake they share is that the gap was written down. This asks instead: every brick type
//  in every theme, every shape, and every paddle theme in every shape - what is not there? The
//  answer is compared against one list, in one place, so the day James draws something the
//  failure says exactly which line of §8.5 to strike, and the day something is *added* without
//  art the failure says that too.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ArtStillToDrawTests: XCTestCase {

    /// The brick type names the game asks the catalogue for, per theme.
    ///
    /// The same names `endlessIIBrickTextureName` builds, which is what makes this a check on
    /// the game's own lookup rather than on a list of files.
    private let brickTypes: [(theme: String, names: [String])] = [
        ("classic", ["BrickNormal", "BrickInvisible", "BrickMultiHit1", "BrickMultiHit2",
                     "BrickMultiHit3", "BrickMultiHit4",
                     "BrickIndestructible1", "BrickIndestructible2"]),
        ("retro", ["retroBrickNormal", "retroBrickInvisible",
                   "RetroBrickMultiHit1", "RetroBrickMultiHit2",
                   "RetroBrickMultiHit3", "RetroBrickMultiHit4"]),
        // Retro has never had its own Indestructible art and is not getting any (§8.5, James's
        // decision): those two bricks wear the classic pictures in both themes, so asking retro
        // for them would be asking for something nobody intends to draw
    ]

    /// Every brick picture the game could ask for and does not have.
    private func missingBrickArt() -> [String] {
        var missing: [String] = []
        for (_, names) in brickTypes {
            for name in names {
                for shape in [GameScene.ShapedBrickArt.rounded, .wedge,
                              .convex, .concave, .diamond] {
                    let plain = name + shape.rawValue
                    let oriented = [false, true].flatMap { mirrored in
                        [false, true].map { flipped in
                            plain + GameScene.orientationSuffix(shape, mirrored: mirrored,
                                                                flipped: flipped)
                        }
                    }
                    if UIImage(named: plain) != nil { continue }
                    if Set(oriented).allSatisfy({ UIImage(named: $0) != nil }) { continue }
                    missing.append(plain)
                    // A shape is drawn either as one picture or as the full set of orientations
                    // it can be seen in. Either answers; neither is the gap
                }
            }
        }
        return missing.sorted()
    }

    /// Every Square picture the game could ask for and does not have.
    ///
    /// The plain one and the Rounded one, which are the two a Square brick can wear: the four
    /// drawn faces are Normal-only by `suits(_ size:)`, so asking for a square Diamond would be
    /// asking for a picture of a brick the generator cannot build. James, round 270: "I haven't
    /// decided if I'll do square versions of the other brick shapes yet."
    private func missingSquareArt() -> [String] {
        var missing: [String] = []
        for (_, names) in brickTypes {
            for name in names {
                for shape in ["", GameScene.ShapedBrickArt.rounded.rawValue] {
                    let wanted = name + shape + GameScene.squareArtSuffix
                    if UIImage(named: wanted) == nil { missing.append(wanted) }
                }
            }
        }
        return missing.sorted()
    }

    /// Every paddle picture the game could ask for and does not have.
    private func missingPaddleArt() -> [String] {
        var missing: [String] = []
        for theme in GameScene.paddleThemePrefixes {
            for kind in ["Paddle", "Lasers", "Sticky", "Grip"] {
                for shape in ["", "Convex", "Concave", "Wave", "WedgeLeft", "WedgeRight"] {
                    let name = theme + kind + shape
                    if UIImage(named: name) == nil { missing.append(name) }
                }
            }
        }
        return missing.sorted()
    }

    /// **The two that are deliberate**, both James's own decisions, both recorded in §8.5.
    ///
    /// The ice theme has no plain sticky picture and borrows glass's, and candy's plain lasers
    /// are `stripyLasers` from the original assets. Neither is a gap and neither is going to be
    /// drawn, so they are named here rather than left to look like work outstanding.
    private let deliberatelyBorrowed: Set<String> = ["iceSticky", "candyLasers"]

    func testTheOnlyMissingPaddlePicturesAreTheTwoThatBorrowOnPurpose() {
        XCTAssertEqual(Set(missingPaddleArt()), deliberatelyBorrowed,
                       "§8.5's paddle list has moved - strike what has arrived, and add what "
                       + "has not")
    }

    /// **Every brick shape is drawn, in both themes** as of round 266.
    ///
    /// Which makes this the forward-looking half: a new brick type or a sixth shape added
    /// without art fails here, rather than quietly wearing a stretched rectangle until somebody
    /// notices in play.
    func testEveryBrickShapeIsDrawn() {
        XCTAssertEqual(missingBrickArt(), [],
                       "§8.5's shaped-face list is closed - anything printed here is either "
                       + "art to draw or a name the lookup is building wrongly")
    }

    /// **Every brick type has its Square pictures, in both themes** as of round 270.
    ///
    /// Same forward-looking job as the shape test above: a brick type added without them wears
    /// its oblong texture stretched to twice its height, which reads as art nobody got round to
    /// rather than as a bug.
    func testEveryBrickTypeIsDrawnAtSquareProportions() {
        XCTAssertEqual(missingSquareArt(), [],
                       "§8.5's Square list is closed - anything printed here is either art to "
                       + "draw or a name the lookup is building wrongly")
    }

    /// The list, printed, so a round that adds a type or a shape can read what it owes.
    func testWhatIsStillToDraw() {
        let bricks = missingBrickArt()
        let paddles = missingPaddleArt().filter { deliberatelyBorrowed.contains($0) == false }
        print("\n  Art still to draw:")
        let squares = missingSquareArt()
        print("    bricks:  \(bricks.isEmpty ? "none" : bricks.joined(separator: ", "))")
        print("    squares: \(squares.isEmpty ? "none" : squares.joined(separator: ", "))")
        print("    paddles: \(paddles.isEmpty ? "none" : paddles.joined(separator: ", "))")
        print("")
    }
}
