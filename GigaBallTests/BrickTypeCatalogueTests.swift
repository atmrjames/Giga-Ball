//
//  BrickTypeCatalogueTests.swift
//  GigaBallTests
//
//  A reference page is only worth having while it is right. The compatibility lines are read
//  off `EndlessIIStyle` so they cannot drift, and these tests cover the part that can: whether
//  every brick the game can build has something written about it.
//
//  Adding a style to `EndlessIIStyle` and forgetting to describe it would leave a page that is
//  quietly incomplete, which is worse than one that is obviously missing - a player who looks
//  something up and does not find it concludes the page is not the place to look.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class BrickTypeCatalogueTests: XCTestCase {

    func testEveryStyleTheGameCanBuildIsListed() {
        let listed = Set(BrickTypeCatalogue.styleOrder)
        XCTAssertEqual(listed, Set(EndlessIIStyle.allCases))
        XCTAssertEqual(BrickTypeCatalogue.styleOrder.count, EndlessIIStyle.allCases.count,
                       "a style is listed twice")
    }

    func testEverySizeAndBehaviourIsListed() {
        // Five behaviours exist, and the compatibility lines still name all five - but the
        // page shows four rows, because the two Indestructible states are one brick that
        // changes rather than two bricks
        XCTAssertEqual(BrickTypeCatalogue.allBehaviours.count, 5)
        XCTAssertEqual(Set(BrickTypeCatalogue.allBehaviours).count, 5)
        XCTAssertEqual(BrickTypeCatalogue.section(titled: "Classic Brick Types")?.count, 4)
        XCTAssertEqual(BrickTypeCatalogue.section(titled: "Sizes")?.count,
                       BrickSize.allCases.count - 1)
        // One short of the four since round 270, because Square is listed under Shapes
        // Asked for by name rather than by position. The page grew from three sections to
        // five in round 237 and the sizes stopped being last, which a positional test would
        // have reported as the sizes having gone missing
    }

    func testABrickThatChangesShowsEveryStateItPassesThrough() {
        // The whole identity of a Multi-Hit brick is that it steps down, and an
        // Indestructible x1 is only interesting because of what it turns into
        XCTAssertEqual(BrickTypeIcons.states(of: .multiHit).count, 4)
        XCTAssertEqual(BrickTypeIcons.states(of: .indestructibleOnce).count, 2)
        XCTAssertEqual(BrickTypeIcons.states(of: .indestructibleAlways).count, 2)
        XCTAssertEqual(BrickTypeIcons.states(of: .standard).count, 1)
        XCTAssertEqual(BrickTypeIcons.states(of: .invisible).count, 1)
    }

    func testTheRetroThemeIsRespected() {
        // The Retro theme swaps the brick textures in the scene, so a page still showing the
        // standard ones is a page of bricks the player does not have
        let defaults = UserDefaults.standard
        let saved = defaults.integer(forKey: "brickSetting")
        defer { defaults.set(saved, forKey: "brickSetting") }

        defaults.set(0, forKey: "brickSetting")
        XCTAssertNil(BrickTypeIcons.retroName(for: "BrickNormal"))

        defaults.set(1, forKey: "brickSetting")
        XCTAssertEqual(BrickTypeIcons.retroName(for: "BrickNormal"), "retroBrickNormal")
        XCTAssertEqual(BrickTypeIcons.retroName(for: "BrickMultiHit3"), "RetroBrickMultiHit3")
        XCTAssertEqual(BrickTypeIcons.retroName(for: "BrickInvisible"), "retroBrickInvisible")
        // There is no Retro Indestructible artwork, and the scene does not swap it either -
        // inventing a substitute here would be the page disagreeing with the game
        XCTAssertNil(BrickTypeIcons.retroName(for: "BrickIndestructible1"))
    }

    func testTheSectionsAccountForEveryEntryExactlyOnce() {
        // Five headings since round 237, and they are the brick workbook's: "the bricks info
        // screen should be broken up into more sections - use the brick details reference"
        // (James). "Styles" had been fourteen entries under one heading covering three
        // unrelated ideas - what a brick is shaped like, what it does, and two that are
        // neither
        let sections = BrickTypeCatalogue.sections
        XCTAssertEqual(sections.map(\.title),
                       ["Classic Brick Types", "Endless Mayhem Brick Types",
                        "Shapes", "Sizes", "Movement Actions", "On-Hit Actions"])
        // Six since round 270: "Brick actions should be split into 2 categories" (James)
        // The two "what is this brick" headings together at the top (James, round 238) -
        // everything under them is a modifier of a brick rather than a kind of one

        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       sections.reduce(0) { $0 + $1.entries.count })
        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       4 + EndlessIIStyle.allCases.count + 1 + BrickSize.allCases.count)
        // The extra one is the power-up brick, which is neither a style nor a size

        let names = BrickTypeCatalogue.allEntries.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "an entry is listed under two headings")
    }

    /// Every style reaches exactly one of the three headings that hold styles.
    ///
    /// The split is by hand - `shapeOrder` and `actionOrder` are written out, and Portal is
    /// named on its own - so the way it goes wrong is a style landing in neither list and
    /// quietly leaving the page. `styleOrder` is built from the three, and the test above
    /// pins it against `allCases`, so this says the *pieces* do not overlap.
    func testEveryStyleIsUnderExactlyOneHeading() {
        let shapes = Set(BrickTypeCatalogue.shapeOrder)
        let actions = Set(BrickTypeCatalogue.actionOrder)
        let movement = Set(BrickTypeCatalogue.movementOrder)
        let onHit = Set(BrickTypeCatalogue.onHitOrder)
        XCTAssertTrue(movement.isDisjoint(with: onHit))
        XCTAssertEqual(movement.union(onHit), actions)
        XCTAssertEqual(movement.count + onHit.count, actions.count, "an action is in both")
        XCTAssertTrue(shapes.isDisjoint(with: actions))
        XCTAssertFalse(shapes.contains(.portal))
        XCTAssertFalse(actions.contains(.portal))
        XCTAssertEqual(shapes.count + actions.count + 1, EndlessIIStyle.allCases.count)

        // And the shapes heading is the shapes: the four faces, plus Rounded, which the
        // workbook calls a shape and the game has always treated as one
        XCTAssertEqual(shapes, Set(EndlessIIFace.allCases.map(\.style) + [.rounded]))
    }

    func testEveryEntryHasSomethingToSay() {
        for entry in BrickTypeCatalogue.allEntries {
            XCTAssertFalse(entry.name.isEmpty)
            XCTAssertFalse(entry.description.isEmpty, entry.name)
            XCTAssertFalse(entry.facts.isEmpty, entry.name)
            for fact in entry.facts {
                XCTAssertFalse(fact.label.isEmpty, entry.name)
                XCTAssertFalse(fact.value.isEmpty, "\(entry.name): \(fact.label)")
            }
        }
    }

    func testTheNewMaterialIsMarkedAsEndlessIIOnly() {
        // §7.3 asks for it, so a player does not go looking for a Portal in a Classic pack
        for entry in BrickTypeCatalogue.sections[1].entries {
            XCTAssertTrue(entry.isNew, "\(entry.name) is new and should say so")
        }
        for entry in BrickTypeCatalogue.sections[0].entries {
            XCTAssertFalse(entry.isNew, "\(entry.name) has always been in the game")
        }
    }

    // MARK: - The derived lines

    func testTheBehaviourLineFollowsTheGameRatherThanTheProse() {
        // Flashing is the one style Invisible cannot take - both are about whether the brick
        // can be seen - so its line has to name the four it can, not say "any"
        let flashing = BrickTypeCatalogue.behaviours(carrying: .flashing)
        XCTAssertFalse(flashing.contains("Invisible"))
        XCTAssertTrue(flashing.contains("Standard"))
        XCTAssertTrue(flashing.contains("Multi-Hit"))

        XCTAssertEqual(BrickTypeCatalogue.behaviours(carrying: .rounded), "Any")
        XCTAssertEqual(BrickTypeCatalogue.behaviours(carrying: .spinning), "Any")
    }

    func testDirectionalCannotDescribeABrickThatIsNeverDestroyed() {
        let line = BrickTypeCatalogue.behaviours(carrying: .directional)
        XCTAssertFalse(line.contains("Indestructible ×2"))
        XCTAssertTrue(line.contains("Indestructible ×1"))
    }

    func testAPortalSaysWhatItActuallyIs() {
        // Portal does not find an Indestructible brick, it makes one. Listing behaviours
        // would say "Indestructible ×2" and imply the generator went looking for one
        XCTAssertEqual(BrickTypeCatalogue.behaviours(carrying: .portal),
                       "Always Indestructible ×2")
    }

    func testTheStackingLineMatchesTheCompatibilityGrid() {
        for style in EndlessIIStyle.allCases {
            let line = BrickTypeCatalogue.styles(stackingWith: style)
            XCTAssertFalse(line.isEmpty, "\(style)")

            // Never itself, whichever way round the line is put. Two of the same style on one
            // brick is the second one doing nothing
            XCTAssertFalse(line.contains(BrickTypeCatalogue.name(of: style)), "\(style)")

            // Said either as the styles it works with or as the ones it does not, so the
            // check is on whichever list the line is actually naming
            let named = line.hasPrefix("Any but")
                ? EndlessIIStyle.allCases.filter { style.stacksWith($0) == false && $0 != style }
                : EndlessIIStyle.allCases.filter { style.stacksWith($0) }
            guard line != "Any other style" else { continue }

            for other in named {
                XCTAssertTrue(line.contains(BrickTypeCatalogue.name(of: other)),
                              "\(style) should name \(other) in \"\(line)\"")
            }
            for other in EndlessIIStyle.allCases where named.contains(other) == false && other != style {
                XCTAssertFalse(line.contains(BrickTypeCatalogue.name(of: other)),
                               "\(style) should not name \(other) in \"\(line)\"")
            }
        }
    }

    func testTheStackingLineIsSaidWhicheverWayIsShorter() {
        // Rounded rewrites the brick's outline, so its only argument is with the styles that
        // do the same - and naming those is shorter than naming the nine it takes
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .rounded),
                       "Any but Convex, Concave, Wedge, Diamond, Breathing")
        // Breathing since round 142: a face drawn once at the brick's size does not follow a
        // brick that then changes size. Diamond since round 234, and it is the fourth shape
        // rather than a new kind of exclusion - which is what this line is here to show: a
        // shape added to the enum lands in this sentence without anybody writing it down

        // Spinning went the other way in round 235, and the sentence turned round with it -
        // which is the whole point of the rule this test is about. The workbook took four
        // styles off it (Fixed, Gravity, Exploding, Spawner, all of which answer in cells,
        // which a turning brick has left behind) and gave it back the four shapes and
        // Directional, so naming what it *refuses* is now the shorter half
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .spinning),
                       "Any but Moving, Gravity, Fixed, Exploding, Spawner")
        // The five are the same five; the order is `styleOrder`'s, which round 270 changed when
        // it split the actions into the ones you can see happening and the ones you cannot
        // Breathing left that list in round 237 - the matrix says Spinning and Breathing go
        // together, and the objection was never quite true: Spinning turns the node and
        // touches no geometry at all

        // A Portal is never damaged and never destroyed, so anything about being destroyed or
        // about being solid has nothing to attach to - and there its exclusions are no shorter
        // than its partners, so the partners are named
        let portal = BrickTypeCatalogue.styles(stackingWith: .portal)
        XCTAssertNotEqual(portal, "Any other style")
        XCTAssertFalse(portal.hasPrefix("Any but"))
        XCTAssertTrue(portal.contains("Rounded"))
        XCTAssertFalse(portal.contains("Exploding"))
    }

    func testEveryStyleSaysWhichSizesItComesIn() {
        for style in EndlessIIStyle.allCases {
            XCTAssertFalse(BrickTypeCatalogue.sizes(carrying: style).isEmpty, "\(style)")
        }
        // **These were pinned to the wrong answers for three rounds**, which is the whole
        // reason the sentence is derived now. Round 237 opened Fixed and Moving to any size and
        // Gravity to everything but Tiny, and moved only the generator's copy of the rule - so
        // the page went on saying "Normal" and this test went on agreeing with it
        XCTAssertEqual(BrickTypeCatalogue.sizes(carrying: .gravity), "Any")
        // Any size since round 244, when the fall stopped walking the occupancy map a row at a
        // time and started measuring frames - which a quarter-cell brick can be measured by
        XCTAssertEqual(BrickTypeCatalogue.sizes(carrying: .fixed), "Any")
        XCTAssertEqual(BrickTypeCatalogue.sizes(carrying: .moving), "Any")

        // A Big brick cannot spin: the clearance a full-size one needs to turn is already two
        // cells in each direction
        XCTAssertFalse(BrickTypeCatalogue.sizes(carrying: .spinning).contains("Big"))

        // And the page's answer is the generator's answer, for every style and every size -
        // which is the property that makes the two impossible to drift apart again
        for style in EndlessIIStyle.allCases {
            for size in BrickSize.allCases where style.suits(size) {
                let sentence = BrickTypeCatalogue.sizes(carrying: style)
                XCTAssertTrue(sentence == "Any"
                              || sentence.contains(BrickTypeCatalogue.name(of: size)),
                              "\(style) takes \(size) and the page does not say so")
            }
        }
    }

    func testEveryEntryDrawsSomething() {
        for entry in BrickTypeCatalogue.allEntries {
            let icon = BrickTypeIcons.image(for: entry.art)
            XCTAssertEqual(icon.size, BrickTypeIcons.canvas, entry.name)
        }
    }

    // MARK: - How the detail page sets a description

    /// The description label as the storyboard builds it: semibold 18, and 40pt narrower than
    /// the screen. Read from the same numbers here rather than guessed, so a test that passes
    /// is a test about the page a player actually sees.
    private let descriptionFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
    private let descriptionWidth: CGFloat = 402 - 40

    /// A one-line description is centred under the icon and the name; a paragraph is not.
    ///
    /// **No brick entry writes a paragraph any more** (round 291): every description on this
    /// page is now the line from James's brick workbook, and the longest of them is a dozen
    /// words. The rule this test guards is a property of the *page* rather than of the
    /// catalogue, and the page still has to hold it - the power-ups page shares the layout, a
    /// description can grow again, and the rule was written because centring every line of a
    /// six-line block was legible and wrong.
    ///
    /// So it is asked of a paragraph rather than of the catalogue. The line that used to fail
    /// here - "no entry writes a paragraph any more, check the rule still earns its keep" - was
    /// the test saying in advance what it should become when this day came.
    func testLongDescriptionsAreNotCentred() {
        let paragraph = "Turns on the spot, and the bounce turns with it. The generator "
            + "leaves the cells around it clear, because a brick twice as wide as it is tall "
            + "needs the room to get round."
        XCTAssertFalse(ItemsStatsViewController.descriptionIsCentred(
            paragraph, font: descriptionFont, width: descriptionWidth),
                       "a description long enough to wrap is left-aligned")

        for entry in BrickTypeCatalogue.allEntries where entry.description.count > 120 {
            XCTAssertFalse(ItemsStatsViewController.descriptionIsCentred(
                entry.description, font: descriptionFont, width: descriptionWidth), entry.name)
        }
    }

    /// And every one of them is short enough to sit centred, which is what the workbook bought.
    func testTheWorkbooksDescriptionsAllFitOnALine() {
        for entry in BrickTypeCatalogue.allEntries {
            XCTAssertLessThan(entry.description.count, 120,
                              "\(entry.name) is longer than James's workbook line - either the "
                              + "sheet says more than this, or a paragraph has grown back")
        }
    }

    func testShortDescriptionsAreCentred() {
        XCTAssertTrue(ItemsStatsViewController.descriptionIsCentred(
            "Gives you an extra ball", font: descriptionFont, width: descriptionWidth))
        // Two lines still reads as the end of the heading; three is body text
        XCTAssertTrue(ItemsStatsViewController.descriptionIsCentred(
            "A brick that takes two hits before it breaks apart entirely",
            font: descriptionFont, width: descriptionWidth))
    }

    /// Before the label has been laid out its width is zero, and a height measured against no
    /// width is meaningless - so the page centres rather than flush-lefting everything for one
    /// frame and then moving it.
    func testAnUnlaidOutLabelCentres() {
        XCTAssertTrue(ItemsStatsViewController.descriptionIsCentred(
            BrickTypeCatalogue.allEntries[0].description, font: descriptionFont, width: 0))
    }

    /// Every drawn face the naming rule can ask for is actually in the asset catalogue.
    ///
    /// The rule is a string built at runtime - the plain texture's name with the shape's name
    /// after it - so a missing file is not a compile error and not a crash. It is a brick that
    /// draws nothing, in a mode where bricks that draw nothing already exist on purpose, which
    /// is the kind of thing that goes unnoticed for rounds.
    func testEveryShapedFaceHasItsArtwork() {
        // The names `endlessIIBrickTextureName` can return, in both themes. The two
        // Indestructibles are deliberately absent from the retro list: that theme has never
        // had its own Indestructible art, so those bricks wear the classic face in both
        let classic = ["BrickNormal", "BrickInvisible", "BrickMultiHit1", "BrickMultiHit2",
                       "BrickMultiHit3", "BrickMultiHit4",
                       "BrickIndestructible1", "BrickIndestructible2"]
        let retro = ["retroBrickNormal", "retroBrickInvisible", "RetroBrickMultiHit1",
                     "RetroBrickMultiHit2", "RetroBrickMultiHit3", "RetroBrickMultiHit4"]

        for base in classic + retro {
            XCTAssertNotNil(UIImage(named: base), base)
            for shape in [GameScene.ShapedBrickArt.rounded, .wedge] {
                let name = base + shape.rawValue
                XCTAssertNotNil(UIImage(named: name), name)
            }
        }
    }

    /// The two categories James split the actions into, in his own words.
    ///
    /// Round 270: "Movement actions - these bricks can just use whatever brick graphic, with
    /// no additional graphic required. The movement is enough of an indication of the brick
    /// type: Spinning, flashing, breathing, moving, gravity". And: "On-hit actions - these
    /// bricks have overlay graphics... as these bricks otherwise can't be told apart until
    /// they're hit and run their action: Power-up (square bricks only), fixed, exploding,
    /// spawner, directional".
    ///
    /// Written out rather than derived, because this *is* the decision - there is nothing on
    /// `EndlessIIStyle` that knows whether an action shows itself before it happens, and a
    /// derivation would only be this list wearing a disguise.
    func testTheActionsAreSplitTheWayJamesSplitThem() {
        XCTAssertEqual(Set(BrickTypeCatalogue.movementOrder),
                       [.spinning, .flashing, .breathing, .moving, .gravity])
        XCTAssertEqual(Set(BrickTypeCatalogue.onHitOrder),
                       [.fixed, .exploding, .spawner, .directional])

        // The power-up brick is the fifth on-hit one and is listed at the top of the page as a
        // type in its own right, so it is not in the list - but it is on the page, and it is
        // the one that already wears the overlay the others are waiting for
        let named = BrickTypeCatalogue.allEntries.map(\.name)
        XCTAssertTrue(named.contains("Power-Up"))
    }

    /// Square is a shape, not a size.
    ///
    /// James, round 270: "Square brick should be under shapes, not sizes." Listed there
    /// *instead of* rather than as well - a player who finds the same brick under two headings
    /// has no way of knowing they are the same brick.
    func testSquareIsUnderShapes() {
        let shapes = BrickTypeCatalogue.section(titled: "Shapes")?.map(\.name) ?? []
        let sizes = BrickTypeCatalogue.section(titled: "Sizes")?.map(\.name) ?? []
        XCTAssertTrue(shapes.contains("Square"), "shapes: \(shapes)")
        XCTAssertFalse(sizes.contains("Square"), "sizes: \(sizes)")
        XCTAssertEqual(sizes.sorted(), ["Big", "Normal", "Tiny"])
    }

    /// What the page says a size can carry is what the generator will let it carry.
    ///
    /// This line was hand-typed - "Any but Spinning" for a Big brick, "Any" for the rest - and
    /// had been wrong since the drawn faces arrived: a Big brick cannot take Breathing or any
    /// of the four faces, and a Tiny one cannot take any of the six.
    func testWhatEachSizeCanCarryIsReadOffTheRules() {
        for size in BrickSize.allCases {
            let said = BrickTypeCatalogue.styles(fitting: size)
            for style in BrickTypeCatalogue.styleOrder where style.suits(size) == false {
                XCTAssertTrue(said.contains(BrickTypeCatalogue.name(of: style)),
                              "\(BrickTypeCatalogue.name(of: size)) does not say it refuses "
                              + BrickTypeCatalogue.name(of: style))
            }
        }
        XCTAssertEqual(BrickTypeCatalogue.styles(fitting: .normal), "Any")
        XCTAssertNotEqual(BrickTypeCatalogue.styles(fitting: .big), "Any")
    }
}
