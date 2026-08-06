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
        XCTAssertEqual(BrickTypeCatalogue.allBehaviours.count, 5)
        XCTAssertEqual(Set(BrickTypeCatalogue.allBehaviours).count, 5)

        let sizes = BrickTypeCatalogue.sections.last?.entries.count
        XCTAssertEqual(sizes, BrickSize.allCases.count)
    }

    func testTheThreeSectionsAccountForEveryEntry() {
        let sections = BrickTypeCatalogue.sections
        XCTAssertEqual(sections.count, 3)
        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       sections.reduce(0) { $0 + $1.entries.count })
        XCTAssertEqual(BrickTypeCatalogue.allEntries.count,
                       5 + EndlessIIStyle.allCases.count + BrickSize.allCases.count)
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
            XCTAssertTrue(entry.isNew, "\(entry.name) is a new style and should say so")
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
        // Rounded only rewrites a shape, so it argues with nothing
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .rounded), "Any other style")

        // Spinning refuses two of the nine. Naming the seven it takes is a list to work
        // through; naming the two it does not is a fact
        XCTAssertEqual(BrickTypeCatalogue.styles(stackingWith: .spinning),
                       "Any but Moving, Directional")

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
