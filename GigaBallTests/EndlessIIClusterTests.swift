//
//  EndlessIIClusterTests.swift
//  GigaBallTests
//
//  A cluster is a designed shape placed in an undesigned field. Two things have to hold for
//  that to be true: the shape has to arrive whole, and the field either side of it has to
//  carry on - which is one character in the expansion and the easiest thing here to get
//  quietly wrong.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIClusterTests: XCTestCase {

    private let columns = 11

    func testEveryClusterIsDrawnAsARectangle() {
        // Ragged rows would place their shape correctly and pad the short ones from the left,
        // which is not the shape anybody drew
        for cluster in EndlessIICluster.all {
            let widths = Set(cluster.rows.map(\.count))
            XCTAssertEqual(widths.count, 1, "\(cluster.name) has rows of differing widths")
            XCTAssertFalse(cluster.rows.isEmpty, cluster.name)
        }
    }

    func testEveryClusterFitsTheField() {
        for cluster in EndlessIICluster.all {
            XCTAssertLessThanOrEqual(cluster.width, columns, cluster.name)
            XCTAssertGreaterThan(cluster.width, 0, cluster.name)
        }
    }

    func testEveryClusterUsesCharactersTheGeneratorKnows() {
        let known: Set<Character> = [".", "N", "M", "i", "I", "?"]
        for cluster in EndlessIICluster.all {
            for row in cluster.rows {
                for character in row {
                    XCTAssertTrue(known.contains(character),
                                  "\(cluster.name) uses \(character)")
                }
            }
        }
    }

    // MARK: - Placement

    func testAClusterOnlyGoesWhereItFitsWhole() {
        // A shape half off the side of the field is not the shape, and the wall would be
        // doing the part of the work the design was supposed to do
        let places = EndlessIICluster.placements(width: 5, in: columns)
        XCTAssertEqual(places.first, 0)
        XCTAssertEqual(places.last, columns - 5)

        for column in places {
            XCTAssertLessThanOrEqual(column + 5, columns)
        }
    }

    func testAClusterWiderThanTheFieldIsNeverPlaced() {
        XCTAssertTrue(EndlessIICluster.placements(width: 12, in: columns).isEmpty)
        XCTAssertTrue(EndlessIICluster.placements(width: 0, in: columns).isEmpty)
    }

    func testEveryClusterHasSomewhereToGo() {
        for cluster in EndlessIICluster.all {
            XCTAssertFalse(EndlessIICluster.placements(width: cluster.width, in: columns).isEmpty,
                           cluster.name)
        }
    }

    // MARK: - Expansion

    func testTheFieldCarriesOnEitherSideOfACluster() {
        // The one character that separates a cluster from a set row. Empties here would cut a
        // hole in the row around the shape, and the cluster would read as a set row with a
        // small thing in the middle
        let cluster = EndlessIICluster(name: "Test", rows: ["NN"], minimumHeight: 0)
        let expanded = cluster.expanded(atColumn: 4, fieldWidth: columns)

        XCTAssertEqual(expanded.count, 1)
        XCTAssertEqual(expanded[0], "????NN?????")
    }

    func testAClusterLandsExactlyWhereItIsPut() {
        let cluster = EndlessIICluster(name: "Test", rows: [".N.", "N.N"], minimumHeight: 0)

        for column in EndlessIICluster.placements(width: 3, in: columns) {
            let expanded = cluster.expanded(atColumn: column, fieldWidth: columns)
            XCTAssertEqual(expanded.count, 2)

            for (index, row) in expanded.enumerated() {
                let characters = Array(row)
                XCTAssertEqual(characters.count, columns)
                let written = Array(cluster.rows[index])
                for offset in 0..<3 {
                    XCTAssertEqual(characters[column + offset], written[offset],
                                   "column \(column), row \(index)")
                }
            }
        }
    }

    func testEveryRealClusterExpandsToTheFieldWidth() {
        for cluster in EndlessIICluster.all {
            let expanded = cluster.expanded(atColumn: 0, fieldWidth: columns)
            XCTAssertEqual(expanded.count, cluster.rows.count, cluster.name)
            for row in expanded {
                XCTAssertEqual(row.count, columns, cluster.name)
            }
        }
    }

    // MARK: - Ramping

    func testTheOpeningOffersOnlyTheSimpleOnes() {
        // A run opens gently, and the first cluster a player meets should be one they can
        // read at a glance rather than a walled vault
        let opening = EndlessIICluster.available(at: 0)
        XCTAssertFalse(opening.isEmpty)
        for cluster in opening {
            XCTAssertLessThanOrEqual(cluster.width, 3, "\(cluster.name) is early and wide")
        }
    }

    func testMoreArriveAsTheRunGoesOn() {
        let opening = EndlessIICluster.available(at: 0).count
        let middle = EndlessIICluster.available(at: 120).count
        let deep = EndlessIICluster.available(at: 300).count

        XCTAssertLessThan(opening, middle)
        XCTAssertLessThan(middle, deep)
        XCTAssertEqual(deep, EndlessIICluster.all.count, "everything should be reachable")
    }

    func testTheSetPiecesAreRarerThanTheBlocks() {
        // The same rule the uniform phases follow: a run that kept serving set pieces would
        // be a run of set pieces
        let block = EndlessIICluster.all.first { $0.name == "Block" }
        let vault = EndlessIICluster.all.first { $0.name == "Vault" }
        XCTAssertNotNil(block)
        XCTAssertNotNil(vault)
        XCTAssertGreaterThan(block!.weight, vault!.weight)
    }

    // MARK: - Picking

    func testPickingHonoursTheWeights() {
        // The first weight's worth of the roll gives the first cluster, and so on
        let choices = EndlessIICluster.available(at: 0)
        guard let first = choices.first else { return XCTFail("nothing available at 0m") }

        XCTAssertEqual(EndlessIICluster.pick(at: 0, roll: { _ in 0 })?.name, first.name)
        XCTAssertEqual(EndlessIICluster.pick(at: 0, roll: { _ in first.weight - 1 })?.name,
                       first.name)
        if choices.count > 1 {
            XCTAssertEqual(EndlessIICluster.pick(at: 0, roll: { _ in first.weight })?.name,
                           choices[1].name)
        }
    }

    func testPickingAlwaysReturnsSomethingAtEveryHeight() {
        for height in [0, 25, 50, 100, 200, 400, 1000] {
            XCTAssertNotNil(EndlessIICluster.pick(at: height, roll: { Int($0/2) }),
                            "nothing at \(height)m")
        }
    }
}

/// The power-up brick: a power-up built into the field rather than falling out of it.
final class EndlessIIPowerUpBrickTests: XCTestCase {

    private let cell = CGSize(width: 40, height: 20)
    private var plan: EndlessIIPowerUpBrick { EndlessIIPowerUpBrick(cell: cell) }

    func testItIsSquareOnScreen() {
        // The whole reason for the shape. A cell is twice as wide as it is tall, so one cell
        // wide and two tall comes out square - which is the shape a power-up already has when
        // it falls, and what makes this read as a power-up sitting in the field
        XCTAssertEqual(plan.size.width, plan.size.height, accuracy: 0.0001)
        XCTAssertEqual(plan.size.width, cell.width, accuracy: 0.0001)
        XCTAssertEqual(plan.size.height, cell.height*2, accuracy: 0.0001)
    }

    func testItsNodeSitsOnARowCentreLikeEveryOtherBrick() {
        // The rule everything in Endless 2.0 bends around: a brick's position.y is its row.
        // The extra height is expressed as an anchor point, not as a moved node
        let gameWidth: CGFloat = 440
        let width = cell.width
        let ordinary = { (column: Int) in -gameWidth/2 + width/2 + width*CGFloat(column) }

        for column in 0..<11 {
            XCTAssertEqual(plan.nodeX(column: column, gameWidth: gameWidth),
                           ordinary(column), accuracy: 0.0001)
        }
    }

    func testTheSpriteCoversItsOwnRowAndTheOneBelow() {
        let rowY: CGFloat = 300
        let anchor = plan.anchorPoint
        let drawn = CGRect(x: -anchor.x*plan.size.width, y: rowY - anchor.y*plan.size.height,
                           width: plan.size.width, height: plan.size.height)

        XCTAssertEqual(drawn.maxY, rowY + cell.height/2, accuracy: 0.0001)
        XCTAssertEqual(drawn.minY, rowY - cell.height*1.5, accuracy: 0.0001)
    }

    func testTheBodyIsCentredOnTheSpriteRatherThanTheNode() {
        // Or it would be solid across the row above and empty across the row below
        XCTAssertEqual(plan.bodyCentre.y, -cell.height/2, accuracy: 0.0001)
        XCTAssertEqual(plan.bodyCentre.x, 0, accuracy: 0.0001)
    }

    func testItOnlyGoesWhereThereIsAColumnForIt() {
        XCTAssertTrue(EndlessIIPowerUpBrick.fits(column: 0, columns: 11))
        XCTAssertTrue(EndlessIIPowerUpBrick.fits(column: 10, columns: 11))
        XCTAssertFalse(EndlessIIPowerUpBrick.fits(column: 11, columns: 11))
        XCTAssertFalse(EndlessIIPowerUpBrick.fits(column: -1, columns: 11))
    }

    func testItIsRarerThanTheOtherTwoRowShapes() {
        // It is a whole power-up sitting in the field, good or bad. One every few screens is
        // an event; one every screen is a mechanic
        XCTAssertLessThan(GameScene.endlessIIPowerUpBrickChance, GameScene.endlessIIBigChance)
        XCTAssertLessThan(GameScene.endlessIIPowerUpBrickChance, GameScene.endlessIISpinChance)
    }

    func testABrickRemembersWhichPowerUpItHolds() {
        let brick = SKSpriteNode()
        XCTAssertNil(brick.endlessIIPowerUpIndex)
        brick.endlessIIPowerUpIndex = 7
        XCTAssertEqual(brick.endlessIIPowerUpIndex, 7)
    }
}
