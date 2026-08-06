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
