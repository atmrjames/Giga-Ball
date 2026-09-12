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
                       ["Classic Brick Types", "Shapes", "Sizes",
                        "Movement Actions", "On-Hit Actions"])
        // Five since round 317, when James moved the Portal and the power-up brick out of
        // their own "Endless Mayhem Brick Types" heading and into On-Hit Actions - which
        // emptied that heading. Both are bricks you cannot tell apart until you strike them,
        // which is what On-Hit Actions means

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
        XCTAssertTrue(actions.contains(.portal),
                      "Portal is an on-hit action since round 317, not a heading of its own")
        XCTAssertEqual(shapes.count + actions.count, EndlessIIStyle.allCases.count,
                       "every style is under exactly one heading, with none left over - the "
                       + "spare used to be Portal, which had its own section")

        // And the shapes heading is the shapes: the four faces, plus Rounded, which the
        // workbook calls a shape and the game has always treated as one
        XCTAssertEqual(shapes, Set(EndlessIIFace.allCases.map(\.style) + [.rounded]))
    }

    func testEveryEntryHasSomethingToSay() {
        for entry in BrickTypeCatalogue.allEntries {
            XCTAssertFalse(entry.name.isEmpty)
            XCTAssertFalse(entry.description.isEmpty, entry.name)
            // A picture, a name and a description is the whole of an entry since round 297
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

    /// And every one of them is short enough to sit centred, which is what the workbook bought.
    func testTheWorkbooksDescriptionsAllFitOnALine() {
        for entry in BrickTypeCatalogue.allEntries {
            XCTAssertLessThan(entry.description.count, 120,
                              "\(entry.name) is longer than James's workbook line - either the "
                              + "sheet says more than this, or a paragraph has grown back")
        }
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
                       [.fixed, .exploding, .spawner, .directional, .portal])
        // Portal since round 317: a brick you cannot tell from an Indestructible until you
        // strike it and it takes the ball, which is this heading's own sentence

        // The power-up brick is the sixth on-hit one and is not an `EndlessIIStyle`, so it is
        // not in this list - it reaches the section through `onHitActions`, and it is the one
        // that already wears the overlay the others are waiting for
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

/// **The information page's brick pictures, looked at** (round 316).
///
/// James: "make sure the info screens are updated with the new graphics." Most of the page
/// derives its pictures from the catalogue and so followed round 315's delivery on its own -
/// the power-up badges, the twist badges, the wrecking balls. The Portal did not, and could
/// not: its identity moved out of the brick and into the glow behind it, so a page drawing the
/// brick alone shows a lime oblong that says nothing.
///
/// Whether the rest of the page still reads is not a thing an assertion can answer, so this
/// draws every picture on it and prints where to find them.
final class BrickInfoPageRenderTests: XCTestCase {

    func testEveryInfoPagePictureCanBeLookedAt() throws {
        var art: [(String, BrickTypeArt)] = []
        for behaviour in [EndlessIIBehaviour.standard, .multiHit, .indestructibleOnce,
                          .indestructibleAlways, .invisible] {
            art.append(("\(behaviour)", .behaviour(behaviour)))
        }
        for style in EndlessIIStyle.allCases { art.append((style.rawValue, .style(style))) }
        for size in BrickSize.allCases { art.append(("\(size)", .size(size))) }
        art.append(("power-up", .powerUpBrick))

        let columns = 6
        let cell = BrickTypeIcons.canvas
        let pad: CGFloat = 8, label: CGFloat = 14
        let rows = (art.count + columns - 1)/columns
        let size = CGSize(width: CGFloat(columns)*(cell.width + pad) + pad,
                          height: CGFloat(rows)*(cell.height + label + pad) + pad)

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for (index, entry) in art.enumerated() {
                let column = index % columns, row = index/columns
                let x = pad + CGFloat(column)*(cell.width + pad)
                let y = pad + CGFloat(row)*(cell.height + label + pad)
                BrickTypeIcons.image(for: entry.1)
                    .draw(in: CGRect(x: x, y: y, width: cell.width, height: cell.height))
                (entry.0 as NSString).draw(
                    at: CGPoint(x: x, y: y + cell.height),
                    withAttributes: [.foregroundColor: UIColor(white: 0.75, alpha: 1),
                                     .font: UIFont.systemFont(ofSize: 9)])
            }
        }

        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("brick-info-page.png")
        try XCTUnwrap(image.pngData()).write(to: file)
        print("\n  Every picture on the brick information page: \(file.path)\n")
    }
}
