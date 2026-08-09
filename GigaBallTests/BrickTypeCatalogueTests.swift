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
        XCTAssertEqual(BrickTypeCatalogue.sections[0].entries.count, 4)

        let sizes = BrickTypeCatalogue.sections.last?.entries.count
        XCTAssertEqual(sizes, BrickSize.allCases.count)
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

    func testTheThreeSectionsAccountForEveryEntry() {
        let sections = BrickTypeCatalogue.sections
        XCTAssertEqual(sections.count, 3)
        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       sections.reduce(0) { $0 + $1.entries.count })
        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       4 + EndlessIIStyle.allCases.count + 1 + BrickSize.allCases.count)
        // The extra one is the power-up brick, which is neither a style nor a size
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
        // Rounded rewrites the brick's outline, so its only argument is with the three
        // styles that do the same - and naming those three is shorter than naming the nine
        // it takes
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .rounded),
                       "Any but Convex, Concave, Wedge")

        // Spinning refuses the shapes and two others. Naming what it takes is a list to
        // work through; naming what it does not is a fact
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .spinning),
                       "Any but Convex, Concave, Wedge, Moving, Directional")

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
        // The two that are pinned to one cell, for reasons that are not the same reason
        XCTAssertEqual(BrickTypeCatalogue.sizes(carrying: .gravity), "Normal")
        XCTAssertEqual(BrickTypeCatalogue.sizes(carrying: .fixed), "Normal")
        // A Big brick cannot spin: the clearance a full-size one needs to turn is already two
        // cells in each direction
        XCTAssertFalse(BrickTypeCatalogue.sizes(carrying: .spinning).contains("Big"))
    }

    func testEveryEntryDrawsSomething() {
        for entry in BrickTypeCatalogue.allEntries {
            let icon = BrickTypeIcons.image(for: entry.art)
            XCTAssertEqual(icon.size, BrickTypeIcons.canvas, entry.name)
        }
    }
}
