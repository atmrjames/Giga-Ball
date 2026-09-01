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
    /// The plain one, the Rounded one and - since round 272 - the Diamond, which are the three
    /// a Square brick can wear. Convex, Concave and Wedge are Normal-only by `suits(_ size:)`,
    /// so asking for those would be asking for a picture of a brick the generator cannot build:
    /// James, round 271, "I haven't decided if I'll do square versions of the other brick
    /// shapes yet."
    ///
    /// **Read off the rules rather than listed**, so the day a square Wedge becomes buildable
    /// this starts asking for its picture without anybody remembering to.
    private func missingSquareArt() -> [String] {
        var missing: [String] = []
        for size in [BrickSize.square, .big] {
            let suffix = GameScene.artSuffix(for: size)
            let shapes = [""] + GameScene.ShapedBrickArt.allCases
                .filter { $0.style.suits(size) && $0.style.suitsAnyBrickOf(size) }
                .map(\.rawValue)
            for (_, names) in brickTypes {
                for name in names {
                    for shape in shapes {
                        let wanted = name + shape + suffix
                        if UIImage(named: wanted) == nil { missing.append(wanted) }
                    }
                }
            }
        }
        return missing.sorted()
    }

    /// The on-hit overlays, and the two bricks that are their own picture.
    ///
    /// James, round 271: the four directional panels "just for the 2x1 and 2x2 shape bricks",
    /// the power-up brick's badge, and the portal brick. Named rather than derived, because
    /// there is no list in the game that these fall out of - they are what the four on-hit
    /// actions and the two Endless Mayhem brick types wear.
    private func missingMarkArt() -> [String] {
        var missing: [String] = []
        for side in EndlessIISide.allCases {
            for square in [false, true] {
                let name = "BrickDirectional" + side.artName + "Open"
                    + (square ? GameScene.squareArtSuffix : "")
                if UIImage(named: name) == nil { missing.append(name) }
            }
        }
        if UIImage(named: GameScene.powerUpBrickArtName) == nil {
            missing.append(GameScene.powerUpBrickArtName)
        }
        for size in [BrickSize.normal, .square, .big] {
            for side in EndlessIISide.allCases {
                let name = "BrickDirectional" + side.artName + "Open"
                    + GameScene.artSuffix(for: size)
                if UIImage(named: name) == nil { missing.append(name) }
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
        XCTAssertEqual(missingSquareArt(), stillToDrawAtSquareProportions,
                       "§8.5's Square list has moved - strike what has arrived, and add what "
                       + "has not")
    }

    /// **The six classic Diamond squares.**
    ///
    /// James delivered the retro set complete and, for classic, the two Indestructibles only -
    /// checked against the pictures rather than the names, because the retro-prefixed ones are
    /// unmistakably the retro bevel. Until they arrive those six bricks fall back to the oblong
    /// Diamond stretched into a square rhombus, which is the same bargain every unfinished
    /// shape has made and is why the fallback exists.
    ///
    /// Named here rather than in a comment somewhere, so the day they land this test fails and
    /// says which line of §8.5 to strike - which is the whole reason this file exists.
    private let stillToDrawAtSquareProportions: [String] = []
    // **Empty since round 274.** It was the six classic Diamond squares, and James drew them
    // the same evening he drew the Big set - so both sizes are complete in both themes

    /// **The on-hit overlays exist** as of round 271 - all eight panels and the badge.
    ///
    /// Which closes §8.5's "still to draw" line for the on-hit actions: Fixed, Exploding and
    /// Spawner keep their drawn glyphs by James's decision ("keep the existing T shape", "keep
    /// the asterisk/star icon", "keep the plus icon"), so Directional was the only one that
    /// needed pictures, and the power-up brick the only brick that needed one of its own.
    func testTheOnHitMarksAreDrawn() {
        XCTAssertEqual(missingMarkArt(), [],
                       "anything printed here is either art to draw or a name the lookup is "
                       + "building wrongly")
    }

    // MARK: - Twist badges

    /// The file each twist's badge would be, by the naming James delivered them under.
    ///
    /// **Asked of `DailyTwist.allCases`**, so a twist added later appears here on its own and
    /// the answer to "is anything missing" is never a list somebody maintained. The names are
    /// his rather than derived from the case names - `GoodNewsTwistIcon` for No Good News,
    /// `NoPauseTwistIcon` for No Breaks - so this is also where a rename would be noticed.
    private let twistArt: [DailyTwist: String] = [
        .oneLife: "OneLifeTwistIcon",
        .spareBalls: "ExtraBallsTwistIcon",
        .noPowerUps: "NoPowerUpsNewsTwistIcon",
        .noGoodNews: "GoodNewsTwistIcon",
        .noBadNews: "NoBadNewsTwistIcon",
        .powerShower: "PowerShowerTwistIcon",
        .drought: "DroughtTwistIcon",
        .fogOfWar: "FogTwistIcon",
        .mirrored: "MirroredTwistIcon",
        .upsideDown: "UpsideDownTwistIcon",
        .brickSwap: "BrickSwapTwistIcon",
        .noPausing: "NoPauseTwistIcon",
        .timeTrial: "TimeTrialTwistIcon",
        .mayhemBricks: "ExtraMayhemTwistIcon",
        .monochromatic: "MonochromeTwistIcon",
        .dailyTheme: "ThemeTwistIcon",
        .alwaysOn: "AlwaysOnTwistIcon",
        .landslide: "LandslideTwistIcon",
    ]

    /// The two that are furniture rather than twists: retired, kept only so a case name that
    /// is a key in the save and in `retirementKey` never changes meaning.
    private var retiredTwists: [DailyTwist] {
        DailyTwist.allCases.filter { $0.retirementKey < "9999" }
    }

    func testEveryTwistWithArtworkIsActuallyUsingIt() {
        for (twist, name) in twistArt {
            XCTAssertNotNil(UIImage(named: name),
                            "\(twist.displayName) is wired to \(name), which is not in the "
                            + "catalogue")
            XCTAssertEqual(twist.icon.pngData(), UIImage(named: name)?.pngData(),
                           "\(twist.displayName) still draws its placeholder - the badge and "
                           + "the file are two different pictures")
        }
    }

    /// Which live twists have no badge, asked rather than remembered.
    ///
    /// James, round 290: "are there any I am missing from the set?" This is the answer, and it
    /// keeps answering: a twist added tomorrow with no art fails here on the day it is added
    /// rather than on the day somebody notices a violet placeholder on the briefing screen.
    func testTheOnlyTwistsWithoutArtworkAreTheTwoDisclosureOnes() {
        let missing = DailyTwist.allCases.filter {
            twistArt[$0] == nil && retiredTwists.contains($0) == false
        }
        XCTAssertEqual(Set(missing), Set([.fullDeck, .levelPegging]),
                       "Full Deck and Level Pegging are the two live twists still wearing a "
                       + "drawing; anything else in this list is a twist that arrived without "
                       + "a badge, and anything missing from it is one James has since drawn")
    }

    func testTheRetiredTwistsAreTheTwoNobodyCanBeGiven() {
        XCTAssertEqual(Set(retiredTwists), Set([.loaded, .suddenDeath]),
                       "they need no artwork because no day can draw them - they are kept so "
                       + "that a case name which is a key in the save keeps its meaning")
    }

    /// The list, printed, so a round that adds a type or a shape can read what it owes.
    func testWhatIsStillToDraw() {
        let bricks = missingBrickArt()
        let paddles = missingPaddleArt().filter { deliberatelyBorrowed.contains($0) == false }
        print("\n  Art still to draw:")
        let squares = missingSquareArt()
        let marks = missingMarkArt()
        let twists = DailyTwist.allCases
            .filter { twistArt[$0] == nil && retiredTwists.contains($0) == false }
            .map(\.displayName)
        print("    bricks:  \(bricks.isEmpty ? "none" : bricks.joined(separator: ", "))")
        print("    squares: \(squares.isEmpty ? "none" : squares.joined(separator: ", "))")
        print("    marks:   \(marks.isEmpty ? "none" : marks.joined(separator: ", "))")
        print("    paddles: \(paddles.isEmpty ? "none" : paddles.joined(separator: ", "))")
        print("    twists:  \(twists.isEmpty ? "none" : twists.joined(separator: ", "))")
        print("")
    }
}
