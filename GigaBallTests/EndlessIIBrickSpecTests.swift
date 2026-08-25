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

    func testEverySizeIsBuildableInAFormationNow() {
        // Big was refused for two rounds, because it spans two rows and the reserve-and-build
        // sequence owned the row it ran on. A formation books it a row ahead instead, which the
        // queue can do because it holds the whole shape
        for size in BrickSize.allCases {
            XCTAssertTrue(EndlessIIBrickSpec(size: size).isBuildable, "\(size)")
        }
    }

    /// A Big brick drawn in a formation has the room for it drawn as well.
    ///
    /// It fills a two-by-two, and only its top-left cell carries the spec - so the three cells
    /// beside and below it have to be empty in the grid, or the formation is asking for two
    /// bricks in one place. The field would build both and the shape would come out wrong in a
    /// way that looks like a generator bug rather than like a grid with a typo in it.
    func testEveryBigBrickInAFormationHasItsOtherThreeCellsLeftEmpty() {
        for formation in EndlessIIFormationCatalogue.all where formation.rows.isEmpty == false {
            for row in formation.rows.indices {
                for column in 0..<formation.rows[row].count {
                    guard formation.spec(atRow: row, column: column).size == .big else {
                        continue
                    }
                    for (dr, dc) in [(0, 1), (1, 0), (1, 1)] {
                        let spec = formation.spec(atRow: row + dr, column: column + dc)
                        XCTAssertTrue(spec.isEmpty,
                                      "\(formation.name)'s Big brick at row \(row) column "
                                      + "\(column) needs the cell at +\(dr),+\(dc) left "
                                      + "empty, and it holds something")
                    }
                }
            }
        }
    }

    /// A formation cannot ask for a style the size cannot carry.
    ///
    /// The rules are the game's own (`EndlessIIStyle.suits(_:BrickSize)`), which is the same
    /// place `endlessIICanTake` and the reference page now read them from. A Tiny wedge is the
    /// obvious mistake and is worth catching where it is written.
    func testAStyleTheSizeCannotCarryIsRefused() {
        XCTAssertEqual(EndlessIIBrickSpec(shape: .wedge, size: .tiny).faults,
                       [.styleRefusesSize(.wedge, .tiny)])
        XCTAssertEqual(EndlessIIBrickSpec(size: .tiny, actions: [.breathing]).faults,
                       [.styleRefusesSize(.breathing, .tiny)])
        // Breathing rather than Gravity, which was the example here until round 244 opened the
        // fall to every size. A quarter-cell brick shrinking to half of a quarter is a brick
        // nobody can hit, and that has not changed
        XCTAssertTrue(EndlessIIBrickSpec(size: .tiny, actions: [.gravity]).isBuildable,
                      "a Tiny brick falls now, and a formation may ask for one that does")
        XCTAssertTrue(EndlessIIBrickSpec(size: .tiny, actions: [.flashing]).isBuildable,
                      "and the ones a quarter-cell brick can carry still go on it")
    }

    /// A Tiny cell becomes four quarter-cell bricks, and they join the row.
    ///
    /// The three new ones have to reach the row's own array or the count and the arrival
    /// animation never see them - the same bargain `applyEndlessIISizes` makes for a Tiny brick
    /// the generator made.
    func testATinyCellBecomesFourQuartersThatJoinTheRow() {
        let scene = fieldScene()
        let node = brick(scene)
        scene.endlessIIDesignedSpecs = [(node, EndlessIIBrickSpec(behaviour: .standard,
                                                                  size: .tiny))]
        var row: [SKNode] = [node]
        scene.applyEndlessIIDesignedSpecs(to: &row)

        XCTAssertTrue(row.count == 4 || row.count == 2,
                      "a Tiny set is all four quarters or one of the two diagonal pairs, "
                      + "and a pair is what leaves a route through the cell")
        XCTAssertEqual(node.size.width, scene.brickWidth/2 - scene.endlessIITinyGap,
                       accuracy: 0.5, "the original became the first quarter")
        for piece in row.compactMap({ $0 as? SKSpriteNode }) {
            XCTAssertLessThan(piece.size.width, scene.brickWidth*0.75, "every piece is a quarter")
            XCTAssertEqual(scene.endlessIISizeOf(piece), .tiny)
        }
    }

    // MARK: - What the builder does with a legend

    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 500, height: 900))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 440
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffsetEndless = 300
        scene.finalBrickRowHeight = 300 - 20*21
        scene.ballSize = 12
        return scene
    }

    private func brick(_ scene: GameScene) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: 40, height: 20))
        brick.position = CGPoint(x: 0, y: 200)
        brick.name = BrickCategoryName
        brick.endlessIIStaysPlain = true
        scene.addChild(brick)
        return brick
    }

    /// A legend's character becomes the brick the legend describes.
    func testTheBuilderPutsOnWhatTheLegendAsksFor() {
        let scene = fieldScene()
        let node = brick(scene)
        scene.endlessIIDesignedSpecs = [(node, EndlessIIBrickSpec(behaviour: .standard,
                                                                 shape: .diamond,
                                                                 actions: [.gravity]))]
        var row: [SKNode] = []
        scene.applyEndlessIIDesignedSpecs(to: &row)

        XCTAssertEqual(node.endlessIIFace, .diamond)
        XCTAssertEqual(node.endlessIIRole, .gravity)
        XCTAssertTrue(scene.endlessIIDesignedSpecs.isEmpty,
                      "spent as it is applied, or the next row would style this brick again")
    }

    /// A named orientation is kept rather than rolled.
    ///
    /// Every shaped brick turns over on a coin (round 154), because a field of them all facing
    /// up is a field of flat undersides. A formation that wants two rows of wedges to agree
    /// needs that coin *not* tossed, and the mechanism is the one the resume path already uses.
    func testANamedOrientationIsNotRolled() {
        let scene = fieldScene()
        for _ in 0..<12 {
            let node = brick(scene)
            scene.endlessIIDesignedSpecs = [(node, EndlessIIBrickSpec(shape: .wedge,
                                                                      mirrored: true,
                                                                      flipped: false))]
            var row: [SKNode] = []
            scene.applyEndlessIIDesignedSpecs(to: &row)
            XCTAssertEqual(node.endlessIIFaceMirrored, true)
            XCTAssertEqual(node.endlessIIFaceFlipped, false)
            node.removeFromParent()
        }
    }

    /// A named open side is kept too, which is what makes a one-angle formation possible.
    func testANamedOpenSideIsKept() {
        let scene = fieldScene()
        let node = brick(scene)
        scene.endlessIIDesignedSpecs = [(node, EndlessIIBrickSpec(actions: [.directional],
                                                                  side: .left))]
        var row: [SKNode] = []
        scene.applyEndlessIIDesignedSpecs(to: &row)
        XCTAssertEqual(node.endlessIIVulnerableSide, .left)
    }

    /// A designed brick is never handed a *random* style.
    ///
    /// `endlessIIStaysPlain` is what stops the generator's own passes reaching it, and it stays
    /// on: the legend is the whole of what a designed cell wears. A shape somebody arranged and
    /// then had a spinner dropped into is not the shape they arranged.
    func testADesignedBrickIsStillSkippedByTheGeneratorsOwnPasses() {
        let scene = fieldScene()
        let node = brick(scene)
        scene.endlessIIDesignedSpecs = [(node, EndlessIIBrickSpec(shape: .convex))]
        var row: [SKNode] = []
        scene.applyEndlessIIDesignedSpecs(to: &row)

        XCTAssertTrue(node.endlessIIStaysPlain)
        XCTAssertFalse(scene.endlessIICanTake(.spinning, node),
                       "the generator must not be able to add to a designed brick")
    }

    /// The behaviour a spec names decides the texture; nil leaves it to the field's mix.
    func testASpecsBehaviourChoosesTheTexture() {
        let scene = fieldScene()
        XCTAssertEqual(scene.endlessIIBrickTexture(for: EndlessIIBrickSpec(behaviour: .multiHit)),
                       scene.brickMultiHit3Texture)
        XCTAssertEqual(scene.endlessIIBrickTexture(
            for: EndlessIIBrickSpec(behaviour: .indestructibleAlways)),
                       scene.brickIndestructible2Texture)
        XCTAssertEqual(scene.endlessIIBrickTexture(for: .nothing), scene.brickNullTexture)
    }

    /// The shared alphabet still builds what it always built.
    ///
    /// The old characters go through the spec path now rather than a switch of their own, so
    /// this is the check that the move changed nothing for the thirty-one shapes already
    /// written.
    func testTheOldAlphabetStillBuildsTheSameBricks() {
        let scene = fieldScene()
        scene.endlessIISetRowLegend = [:]
        let row = "N.MiI?"
        XCTAssertEqual(scene.endlessIIBrickTexture(for: scene.endlessIISetRowSpec(row, column: 0)),
                       scene.brickNormalTexture)
        XCTAssertEqual(scene.endlessIIBrickTexture(for: scene.endlessIISetRowSpec(row, column: 1)),
                       scene.brickNullTexture)
        XCTAssertEqual(scene.endlessIIBrickTexture(for: scene.endlessIISetRowSpec(row, column: 2)),
                       scene.brickMultiHit3Texture)
        XCTAssertEqual(scene.endlessIIBrickTexture(for: scene.endlessIISetRowSpec(row, column: 3)),
                       scene.brickIndestructible1Texture)
        XCTAssertEqual(scene.endlessIIBrickTexture(for: scene.endlessIISetRowSpec(row, column: 4)),
                       scene.brickIndestructible2Texture)
        XCTAssertTrue(scene.endlessIISetRowSpec(row, column: 5).isPlain,
                      "`?` asks for nothing, and the generator answers")
    }

    /// A formation's legend is read while it is being laid down and gone the moment it is.
    ///
    /// `A` means something different in every shape, so a legend outliving its formation would
    /// build the next one out of the last one's bricks.
    func testALegendIsClearedWithTheFormationThatBroughtIt() {
        let scene = fieldScene()
        scene.endlessIISetRowQueue = ["AA", "AA"]
        scene.endlessIISetRowLegend = ["A": EndlessIIBrickSpec(behaviour: .multiHit)]

        XCTAssertEqual(scene.endlessIINextSetRow(reservationPending: false), "AA")
        XCTAssertEqual(scene.endlessIISetRowLegend.count, 1, "still mid-formation")

        XCTAssertEqual(scene.endlessIINextSetRow(reservationPending: false), "AA")
        XCTAssertTrue(scene.endlessIISetRowLegend.isEmpty,
                      "the last row went out, so the key goes with it")
    }

    /// Millrace is a channel, which means its two rows must not be the same wedge.
    ///
    /// The shape is two rows of slopes with the field's own bricks between them, and the whole
    /// idea is that the slopes *agree* - a 180-degree turn apart, so their hypotenuses run
    /// parallel and a ball inside is passed along rather than thrown out. Two rows of the same
    /// wedge would be two rows of the same wedge, and nothing would read as a channel.
    ///
    /// Worth pinning because the orientations are four booleans and the failure is a shape that
    /// still builds, still looks deliberate, and does not do the one thing it was drawn for.
    func testMillracesTwoRowsAreOppositeTurnsOfTheSameWedge() {
        guard let millrace = EndlessIIFormationCatalogue.all.first(where: {
            $0.name == "Millrace"
        }) else { return XCTFail("Millrace has left the catalogue") }

        let top = millrace.spec(atRow: 0, column: 0)
        let bottom = millrace.spec(atRow: 2, column: 0)
        XCTAssertEqual(top.shape, .wedge)
        XCTAssertEqual(bottom.shape, .wedge)
        XCTAssertNotEqual(top.mirrored, bottom.mirrored)
        XCTAssertNotEqual(top.flipped, bottom.flipped)
        // Both axes turned: a half turn, which leaves the two slopes parallel. Turning one axis
        // only would put them at right angles, which is a funnel and a different shape

        XCTAssertTrue(millrace.spec(atRow: 1, column: 1).isPlain,
                      "the middle row is the field's own bricks, or there is nothing to catch")
    }

    // MARK: - Which way up a formation lands

    /// **The first row written is the one that ends up at the top.**
    ///
    /// The field descends - everything moves down a row and the new one is built at a fixed y
    /// at the top - so the row emitted *first* ends up *lowest*. A queue drained from the front
    /// therefore laid every formation out upside down, which is what this pins.
    ///
    /// It survived a long time because most of the catalogue is symmetrical: a ring, a cross, a
    /// diamond and a chequer look the same either way up. The shapes that gave it away are the
    /// six that say which way up they go in their own comments.
    func testAFormationIsQueuedSoItsWrittenTopRowLandsHighest() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = 11

        scene.endlessIIQueueFormation(rows: ["TOP", "MIDDLE", "BOTTOM"], legend: [:])
        // Queued through the builder's own function rather than by hand. Seeding the array
        // directly would pass whether or not the reversal is still in the code, which is the
        // one thing this test is for

        XCTAssertEqual(scene.endlessIINextSetRow(reservationPending: false), "BOTTOM",
                       "the first row out is the one that lands lowest, so it has to be the "
                       + "one written last")
        XCTAssertEqual(scene.endlessIINextSetRow(reservationPending: false), "MIDDLE")
        XCTAssertEqual(scene.endlessIINextSetRow(reservationPending: false), "TOP",
                       "and the row written first is emitted last, which puts it on top")
    }

    /// A whole formation, queued and drained, comes back the way it was written.
    ///
    /// The test above pins the first row out; this one pins the *shape*, by draining the queue
    /// and reading the rows back into the order they will be seen in. Written because the bug
    /// was never about one row - it was about a lid ending up under the thing it lidded.
    func testAQueuedFormationDrainsIntoTheOrderItWasWrittenIn() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = 11

        let written = ["LID", "MIDDLE", "FLOOR"]
        scene.endlessIIQueueFormation(rows: written, legend: [:])

        let emitted = written.indices.compactMap { _ in
            scene.endlessIINextSetRow(reservationPending: false)
        }
        // Exactly as many rows as were queued, and not "until it returns nil": an empty queue
        // rolls for a *new* formation, so draining past the end would sometimes pick one up
        // and this would be a test that failed one run in six

        XCTAssertEqual(emitted.reversed(), written,
                       "the rows are emitted bottom-first, so reading them back up the field "
                       + "has to give the formation as it was drawn")
    }

    /// The legend goes out with the last row and not before.
    ///
    /// `A` means something different in every formation, so a legend that outlived its own
    /// shape would dress the next one's bricks.
    func testTheLegendIsClearedOnlyWhenTheFormationIsSpent() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = 11

        let legend: [Character: EndlessIIBrickSpec] = ["A": EndlessIIBrickSpec(behaviour: .multiHit)]
        scene.endlessIIQueueFormation(rows: ["AAA", "AAA"], legend: legend)

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertEqual(scene.endlessIISetRowLegend["A"], legend["A"],
                       "one row still to come, so the key is still needed")

        _ = scene.endlessIINextSetRow(reservationPending: false)
        XCTAssertTrue(scene.endlessIISetRowLegend.isEmpty,
                      "the shape is spent, so its key goes with it")
    }

    /// A formation that says which way up it goes has its lid above its contents.
    ///
    /// Read off the catalogue rather than written down: these are the shapes whose comments
    /// describe an orientation, and the property they share is that the unbreakable part is
    /// drawn before - and so lands above - the part worth breaking.
    func testEveryLiddedFormationHasItsLidOverItsContents() {
        for name in ["Anvil", "Vault"] {
            guard let formation = EndlessIIFormationCatalogue.all.first(where: {
                $0.name == name && $0.rows.isEmpty == false
            }) else { continue }

            func unbreakable(_ row: Int) -> Int {
                (0..<formation.rows[row].count)
                    .map { formation.spec(atRow: row, column: $0) }
                    .filter { $0.isEmpty == false && $0.isBreakable == false }
                    .count
            }
            let top = unbreakable(0)
            let bottom = unbreakable(formation.rows.count - 1)
            XCTAssertGreaterThan(top, bottom,
                                 "\(name) is a lid over something, so its first row - the one "
                                 + "that lands highest - has to be the unbreakable one")
        }
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
    ///
    /// **Scatters are exempt**, and not as a convenience: a scatter has no drawn grid at all -
    /// its rows are rolled at placement, from a character it names separately - so there is
    /// nothing here to compare a legend against. Asking anyway reports every scatter that
    /// carries a legend as carrying a dead one.
    func testNoFormationCarriesALegendEntryItNeverUses() {
        for formation in EndlessIIFormationCatalogue.all where formation.rows.isEmpty == false {
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
