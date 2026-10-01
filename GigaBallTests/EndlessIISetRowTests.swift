//
//  EndlessIISetRowTests.swift
//  GigaBallTests
//
//  Set rows are written as text so a person can read and edit them, which means a typo in one
//  is a shape that silently comes out wrong rather than a compile error. These check the
//  things a typo would break.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIISetRowTests: XCTestCase {

    func testEveryPatternIsOneToThreeRowsOrASection() {
        // Longer than three and it stops being a landmark and becomes the field - which is
        // what a section is for (James, round 357, asking for "more rows, sections,
        // clusters"). A section may run to six rows and is gated past the opening, so a
        // run's first minutes still meet only the short ones
        for pattern in EndlessIISetRow.all {
            XCTAssertGreaterThan(pattern.rows.count, 0, pattern.name)
            XCTAssertLessThanOrEqual(pattern.rows.count, 6, pattern.name)
            if pattern.rows.count > 3 {
                XCTAssertGreaterThanOrEqual(pattern.minimumHeight, 100,
                                            "\(pattern.name) is a section in the opening")
            }
        }
    }

    func testEveryRowIsTheWidthItWasDesignedFor() {
        // A short row is a typo, and it would quietly leave the right-hand columns empty.
        for pattern in EndlessIISetRow.all {
            for row in pattern.rows {
                XCTAssertEqual(row.count, EndlessIISetRow.designedForColumns,
                               "\(pattern.name): '\(row)'")
            }
        }
    }

    func testEveryCharacterMeansSomething() {
        // The six shared ones, **or one this pattern's own legend defines** (round 240). A
        // legend is what lets a row be made of a shape or an action rather than of the four
        // brick kinds the shared alphabet reaches
        for pattern in EndlessIISetRow.all {
            let known = Set(pattern.legend.keys).union(EndlessIIBrickSpec.classic.keys)
            for row in pattern.rows {
                for character in row {
                    XCTAssertTrue(known.contains(character),
                                  "\(pattern.name): '\(character)'")
                }
            }
        }
    }

    func testNoPatternIsCompletelySolid() {
        // A full row of indestructible bricks is a run-ending wall, not a shape.
        //
        // Asked through the legend since round 240. The rule is unchanged and was always about
        // what a cell *is*; the check used to read the character, which meant a row of
        // Standard wedges - entirely breakable - was reported as a wall because `W` is not one
        // of the six letters it knew
        for pattern in EndlessIISetRow.all {
            let anyGap = pattern.rows.contains { $0.contains(".") }
            let anyBreakable = pattern.rows.contains { row in
                row.contains { EndlessIIBrickSpec.spec(for: $0,
                                                       legend: pattern.legend).isBreakable }
            }
            XCTAssertTrue(anyGap || anyBreakable, "\(pattern.name) can never be got past")
        }
    }

    /// James, round 190: "Mazes of indestructible bricks **dotted with normal bricks so they
    /// don't just fly by**."
    ///
    /// Written as a rule about the catalogue rather than about the three shapes named
    /// "maze", so it holds for anything heavy that gets added later: a pattern made mostly of
    /// indestructibles has to contain something worth breaking. Without that it is a wall
    /// that descends past with nothing to earn from it - the ball rattles off it and the row
    /// is a tax on time.
    /// James, round 357: "Ball can get stuck above solid row on indestructible bricks". The
    /// test above asks the question of a whole pattern, which is how the Vault passed it: its
    /// lid was solid and the rows under it had gaps. A ball is stuck by a *row*, so every row is
    /// asked. `?` counts as a wall here, because it can be anything the generator makes - and
    /// `endlessIIOpenASolidUnbreakableRow` answers the rows a pattern cannot see coming
    func testNoSingleRowIsAWallFromSideToSide() {
        for pattern in EndlessIISetRow.all {
            for row in pattern.rows {
                let open = row.contains { character in
                    character == "." || (character != "?"
                        && EndlessIIBrickSpec.spec(for: character,
                                                   legend: pattern.legend).isBreakable)
                }
                XCTAssertTrue(open, "\(pattern.name): '\(row)' is a wall a ball cannot get past")
            }
        }
    }

    func testAnyMostlyIndestructiblePatternHasSomethingWorthHavingInIt() {
        var checked = 0
        for pattern in EndlessIISetRow.all {
            let cells = pattern.rows.flatMap { Array($0) }.filter { $0 != "." }
            let walls = cells.filter { $0 == "I" || $0 == "i" }.count
            guard walls*2 > cells.count else { continue }
            checked += 1

            let worthHaving = cells.contains { $0 == "N" || $0 == "M" || $0 == "?" }
            XCTAssertTrue(worthHaving,
                          "\(pattern.name) is mostly indestructible with nothing in it - a "
                          + "wall that just flies by")
        }
        XCTAssertGreaterThan(checked, 0,
                             "no pattern is mostly indestructible, so this checked nothing - "
                             + "the mazes are exactly what it was written for")
    }

    func testTheMazesAreGatedByHowHeavyTheyAre() {
        // Catacomb is open from both sides, Warren has a lid, Bastion is nearly closed. They
        // should arrive in that order, whatever the run's schedule does on top
        let byName = Dictionary(uniqueKeysWithValues: EndlessIISetRow.all.map { ($0.name, $0) })
        guard let light = byName["Catacomb"], let middle = byName["Warren"],
              let heavy = byName["Bastion"] else {
            return XCTFail("the mazes have been renamed - the gates below are about them")
        }
        XCTAssertLessThan(light.minimumHeight, middle.minimumHeight)
        XCTAssertLessThan(middle.minimumHeight, heavy.minimumHeight)
    }

    func testNoPatternIsEmpty() {
        for pattern in EndlessIISetRow.all {
            let anything = pattern.rows.contains { $0.contains(where: { $0 != "." }) }
            XCTAssertTrue(anything, "\(pattern.name) is nothing at all")
        }
    }

    func testTheSimplestOnesAreAvailableFromTheStart() {
        XCTAssertFalse(EndlessIISetRow.available(at: 0).isEmpty)
    }

    func testDeeperPatternsAreNotOfferedEarly() {
        let early = EndlessIISetRow.available(at: 0)
        for pattern in early {
            XCTAssertEqual(pattern.minimumHeight, 0, pattern.name)
        }
        XCTAssertGreaterThan(EndlessIISetRow.available(at: 1000).count, early.count)
    }

    func testReadingPastTheEndOfARowIsEmptyRatherThanACrash() {
        // A field wider than the patterns were drawn for must leave the shape alone.
        let row = EndlessIISetRow.all[0].rows[0]
        XCTAssertEqual(EndlessIISetRow.character(in: row, column: 999), ".")
        XCTAssertEqual(EndlessIISetRow.character(in: row, column: -1), ".")
    }

    func testEveryPatternHasAName() {
        for pattern in EndlessIISetRow.all {
            XCTAssertFalse(pattern.name.isEmpty)
        }
        XCTAssertEqual(Set(EndlessIISetRow.all.map(\.name)).count, EndlessIISetRow.all.count)
    }
}


/// The guard behind the catalogue's own rule, for rows no pattern drew.
final class EndlessIISolidRowGuardTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = 11
        scene.brickWidth = 30
        scene.brickHeight = 15
        scene.gameWidth = 330
        return scene
    }

    private func row(in scene: GameScene, unbreakable columns: [Int]) -> [SKNode] {
        columns.map { column in
            let brick = SKSpriteNode(texture: scene.brickIndestructible2Texture,
                                     size: CGSize(width: scene.brickWidth, height: scene.brickHeight))
            brick.position = CGPoint(x: -scene.gameWidth/2 + scene.brickWidth/2
                                        + scene.brickWidth*CGFloat(column), y: 200)
            brick.name = BrickCategoryName
            scene.addChild(brick)
            return brick
        }
    }

    func testAWallFromSideToSideLosesOneBrick() {
        let scene = scene()
        var bricks = row(in: scene, unbreakable: Array(0..<11))
        scene.endlessIIOpenASolidUnbreakableRow(&bricks)
        XCTAssertEqual(bricks.count, 10, "a ball above it could never come back down")
        XCTAssertEqual(bricks.filter { $0.parent != nil }.count, 10)
    }

    func testARowWithAGapIsLeftAlone() {
        let scene = scene()
        var bricks = row(in: scene, unbreakable: [0, 1, 2, 3, 4, 6, 7, 8, 9, 10])
        scene.endlessIIOpenASolidUnbreakableRow(&bricks)
        XCTAssertEqual(bricks.count, 10)
    }

    /// Mutation testing, round 357: nothing said a full row of *breakable* bricks is left alone,
    /// so the guard could have counted every brick as a wall and still passed.
    func testAFullRowOfBreakableBricksIsLeftAlone() {
        let scene = scene()
        var bricks: [SKNode] = (0..<11).map { column in
            let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                     size: CGSize(width: scene.brickWidth, height: scene.brickHeight))
            brick.position = CGPoint(x: -scene.gameWidth/2 + scene.brickWidth/2
                                        + scene.brickWidth*CGFloat(column), y: 200)
            scene.addChild(brick)
            return brick
        }
        scene.endlessIIOpenASolidUnbreakableRow(&bricks)
        XCTAssertEqual(bricks.count, 11, "every one of them breaks, so there is a way through")
    }

    func testAFieldWithNoColumnsIsNotAsked() {
        let scene = scene()
        var bricks = row(in: scene, unbreakable: [0, 1])
        scene.numberOfBrickColumns = 0
        scene.endlessIIOpenASolidUnbreakableRow(&bricks)
        XCTAssertEqual(bricks.count, 2, "no columns to cover, so nothing to open - and no crash")
    }

    func testOnlyMayhemIsTouched() {
        let scene = scene()
        scene.gameMode = .endless
        var bricks = row(in: scene, unbreakable: Array(0..<11))
        scene.endlessIIOpenASolidUnbreakableRow(&bricks)
        XCTAssertEqual(bricks.count, 11)
    }
}
