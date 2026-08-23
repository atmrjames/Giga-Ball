//
//  EndlessIIBrickSpecTests.swift
//  GigaBallTests
//
//  A formation is authored long before it is built, and the mistakes it can carry are all
//  quiet ones. A legend asking for a Spinning Fixed brick does not crash and does not look
//  wrong in the source - it produces a field where one cell is not what the author drew, and
//  the way that reads from the outside is "the shape came out wrong sometimes".
//
//  So the catalogue is walked here and every cell of every formation is put to the rules the
//  game already has. That is the whole design of `EndlessIIBrickSpec`: it asks and never
//  rules, so this file is where "is this brick possible" is answered, once, against
//  `EndlessIIStyle` rather than against a second copy of the compatibility grid.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIBrickSpecTests: XCTestCase {

    // MARK: - The shared legend

    /// The six characters every formation written before round 238 uses still mean what they
    /// meant, and still describe bricks the game can build.
    func testTheClassicAlphabetSurvivesTheMoveToSpecs() {
        XCTAssertEqual(EndlessIIBrickSpec.classic.count, 6)
        for (character, spec) in EndlessIIBrickSpec.classic {
            XCTAssertTrue(spec.isBuildable, "\(character): \(spec.faults)")
        }
        XCTAssertTrue(EndlessIIBrickSpec.classic["."]?.isEmpty == true)
        XCTAssertTrue(EndlessIIBrickSpec.classic["?"]?.isPlain == true,
                      "`?` asks for nothing, which is what makes it the generator's choice")
        XCTAssertEqual(EndlessIIBrickSpec.classic["M"]?.behaviour, .multiHit)
    }

    /// A formation's own key wins over the shared one, and an unknown character is empty.
    func testALegendOverridesTheSharedAlphabet() {
        let mine: [Character: EndlessIIBrickSpec] = [
            "N": EndlessIIBrickSpec(behaviour: .multiHit),
            "A": EndlessIIBrickSpec(shape: .diamond),
        ]
        XCTAssertEqual(EndlessIIBrickSpec.spec(for: "N", legend: mine).behaviour, .multiHit)
        XCTAssertEqual(EndlessIIBrickSpec.spec(for: "A", legend: mine).shape, .diamond)
        XCTAssertEqual(EndlessIIBrickSpec.spec(for: "I", legend: mine).behaviour,
                       .indestructibleAlways, "the shared alphabet still answers")
        XCTAssertTrue(EndlessIIBrickSpec.spec(for: "z", legend: mine).isEmpty,
                      "an unknown character is empty, which is what the old builder did")
    }

    // MARK: - What the validator catches

    func testASpecAskingForTwoShapesIsRefused() {
        let spec = EndlessIIBrickSpec(shape: .convex, actions: [.wedge])
        XCTAssertFalse(spec.isBuildable)
        XCTAssertTrue(spec.faults.contains(.notAnAction(.wedge)),
                      "a shape in the actions list is a typo, and is worth saying so")
    }

    func testAnActionInTheShapeSlotIsRefused() {
        let spec = EndlessIIBrickSpec(shape: .spinning)
        XCTAssertEqual(spec.faults, [.notAShape(.spinning)])
    }

    /// The pair rules are the game's own, not a copy.
    ///
    /// Spinning and Fixed refuse each other on the 2026 brick workbook's matrix - one anchors a
    /// brick where it stands and the other never lets it stand still. Nothing in the validator
    /// knows that; it asks `stacksWith`, so the day the matrix changes this test changes with
    /// the game rather than against it.
    func testTwoActionsThatRefuseEachOtherAreRefusedHere() {
        let spec = EndlessIIBrickSpec(actions: [.spinning, .fixed])
        XCTAssertEqual(spec.faults, [.stylesRefuseEachOther(.spinning, .fixed)])
        XCTAssertFalse(EndlessIIStyle.spinning.stacksWith(.fixed),
                       "and it is the game's own answer, or this test proves nothing")
    }

    /// And the shape-against-action rules come from the same place.
    func testAShapeAndAnActionThatRefuseEachOtherAreRefused() {
        // "Directional bricks are always the standard shape" (James, on the brick workbook)
        let spec = EndlessIIBrickSpec(shape: .diamond, actions: [.directional])
        XCTAssertFalse(spec.isBuildable)

        // And the pairing the same round *allowed* is allowed here
        XCTAssertTrue(EndlessIIBrickSpec(shape: .convex, actions: [.gravity]).isBuildable)
    }

    func testAStyleTheBehaviourCannotCarryIsRefused() {
        // An Invisible brick is not drawn until it is struck, so a shaped one would answer
        // hits with a slope nobody can see
        let spec = EndlessIIBrickSpec(behaviour: .invisible, shape: .wedge)
        XCTAssertEqual(spec.faults, [.styleRefusesBehaviour(.wedge, .invisible)])
    }

    func testThreeStylesOnOneBrickIsRefused() {
        let spec = EndlessIIBrickSpec(shape: .convex, actions: [.gravity, .flashing])
        XCTAssertTrue(spec.faults.contains(.tooManyStyles(3)),
                      "the cap is \(GameScene.endlessIIMaximumStyles), and it is the game's")
    }

    func testAnOpenSideWithoutDirectionalIsRefused() {
        XCTAssertEqual(EndlessIIBrickSpec(side: .top).faults, [.sideWithoutDirectional])
        XCTAssertTrue(EndlessIIBrickSpec(actions: [.directional], side: .top).isBuildable)
    }

    func testAnOrientationWithoutAShapeIsRefused() {
        XCTAssertEqual(EndlessIIBrickSpec(flipped: true).faults, [.orientationWithoutAShape])
        XCTAssertTrue(EndlessIIBrickSpec(shape: .wedge, flipped: true).isBuildable)
    }

    /// An empty cell is never wrong, whatever else is set on it.
    func testAnEmptyCellIsAlwaysBuildable() {
        var spec = EndlessIIBrickSpec.nothing
        spec.actions = [.spinning, .fixed]
        XCTAssertTrue(spec.isBuildable, "nothing is being built, so nothing can be impossible")
    }

    // MARK: - The catalogue itself

    /// **Every cell of every designed formation describes a brick the game can build.**
    ///
    /// This is the test the format exists for. A legend is a small thing to get wrong and the
    /// failure is invisible: the field builds *something* in that cell, and what reads back is
    /// "the shape comes out wrong sometimes" rather than "Turbine's legend is invalid".
    func testEveryFormationInTheCatalogueIsBuildable() {
        for formation in EndlessIIFormationCatalogue.all {
            for (character, spec) in formation.legend {
                XCTAssertTrue(spec.isBuildable,
                              "\(formation.name), '\(character)': "
                              + spec.faults.map(\.description).joined(separator: "; "))
            }
        }
    }

    /// And every character a formation draws with is one its legend or the shared one knows.
    ///
    /// A typo in a grid is silent in the other direction: an unknown character reads as empty,
    /// so a mistyped cell is a hole in the shape rather than an error.
    func testEveryCharacterDrawnIsACharacterDefined() {
        for formation in EndlessIIFormationCatalogue.all {
            let known = Set(formation.legend.keys).union(EndlessIIBrickSpec.classic.keys)
            for row in formation.rows {
                for character in row where known.contains(character) == false {
                    XCTFail("\(formation.name) draws with '\(character)', "
                            + "which neither its legend nor the shared alphabet defines")
                }
            }
        }
    }

    /// A legend entry that is never drawn is dead weight, and usually a renamed character.
    func testNoFormationCarriesALegendEntryItNeverUses() {
        for formation in EndlessIIFormationCatalogue.all {
            let drawn = Set(formation.rows.flatMap { $0 })
            for character in formation.legend.keys where drawn.contains(character) == false {
                XCTFail("\(formation.name) defines '\(character)' and never draws it")
            }
        }
    }

    /// Every formation is rectangular, because a ragged one is a shape with a hole nobody meant.
    func testEveryFormationIsRectangular() {
        for formation in EndlessIIFormationCatalogue.all where formation.rows.isEmpty == false {
            let widths = Set(formation.rows.map(\.count))
            XCTAssertEqual(widths.count, 1,
                           "\(formation.name) has rows of \(widths.sorted()) characters")
        }
    }

    /// A formation made mostly of Indestructibles has to contain something worth breaking.
    ///
    /// James, round 190: "mazes of indestructible bricks dotted with normal bricks so they
    /// don't just fly by". The dotting is the design - a wall of nothing but indestructibles is
    /// a row the ball rattles off with nothing to earn, and it descends past as a tax on time.
    /// Stated about the whole catalogue rather than about the three mazes, so anything heavy
    /// added later has to obey it. It condemned an existing shape the first time it ran.
    func testAHeavyFormationAlwaysHasSomethingWorthBreaking() {
        for formation in EndlessIIFormationCatalogue.all where formation.rows.isEmpty == false {
            let cells = formation.rows.flatMap { $0 }
                .map { EndlessIIBrickSpec.spec(for: $0, legend: formation.legend) }
                .filter { $0.isEmpty == false }
            guard cells.isEmpty == false else { continue }

            let unbreakable = cells.filter {
                $0.behaviour == .indestructibleOnce || $0.behaviour == .indestructibleAlways
            }
            guard unbreakable.count*2 > cells.count else { continue }
            // Mostly unbreakable. Anything less than that is a shape with hard bits in it,
            // which is a different thing and a good one

            XCTAssertLessThan(unbreakable.count, cells.count,
                              "\(formation.name) is all Indestructible - a wall that flies "
                              + "past with nothing to earn from it (James, round 190)")
        }
    }
}
