//
//  EndlessIIFieldTests.swift
//  GigaBallTests
//
//  The cell map is derived from brick positions, so it is only as good as the arithmetic
//  that converts one to the other. If a brick placed in column 4 reads back as column 3,
//  every neighbour question about it is answered about the wrong part of the field - an
//  explosion clears the wrong bricks, a Spawner fills an occupied cell - and nothing crashes
//  to say so.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIFieldTests: XCTestCase {

    // The real proportions: a cell is twice as wide as it is tall.
    private let geometry = EndlessIIFieldGeometry(gameWidth: 440,
                                                  cell: CGSize(width: 40, height: 20),
                                                  topRowY: 300,
                                                  columns: 11)

    /// Exactly how the generator places an ordinary brick.
    private func generatorPosition(column: Int, row: Int) -> CGPoint {
        CGPoint(x: -440/2 + 40/2 + 40*CGFloat(column), y: 300 - 20*CGFloat(row))
    }

    func testItAgreesWithWhereTheGeneratorPutsABrick() {
        for column in 0..<11 {
            for row in 0..<22 {
                let placed = generatorPosition(column: column, row: row)
                let read = geometry.cell(at: placed)
                XCTAssertEqual(read.column, column, "column \(column) row \(row)")
                XCTAssertEqual(read.row, row, "column \(column) row \(row)")
            }
        }
    }

    func testACellRoundTripsThroughItsCentre() {
        for column in 0..<11 {
            for row in 0..<22 {
                let cell = EndlessIICell(column: column, row: row)
                XCTAssertEqual(geometry.cell(at: geometry.centre(of: cell)), cell)
            }
        }
    }

    func testAPointAnywhereInACellReadsAsThatCell() {
        // Bricks do not always sit dead centre: a Moving brick wanders and a falling one is
        // between rows. Anything inside the cell has to answer with the cell.
        let cell = EndlessIICell(column: 6, row: 9)
        let centre = geometry.centre(of: cell)
        for dx in [-19.0, -10.0, 0.0, 10.0, 19.0] as [CGFloat] {
            for dy in [-9.0, -4.0, 0.0, 4.0, 9.0] as [CGFloat] {
                XCTAssertEqual(geometry.cell(at: CGPoint(x: centre.x + dx, y: centre.y + dy)),
                               cell, "offset \(dx),\(dy)")
            }
        }
    }

    // MARK: - Footprints

    func testEveryBrickClaimsAtLeastOneCell() {
        // A Tiny brick is a quarter of a cell and a spinning one smaller still. A brick that
        // claimed no cells would be invisible to every neighbour question.
        XCTAssertEqual(geometry.footprint(of: CGSize(width: 20, height: 10)).columns, 1)
        XCTAssertEqual(geometry.footprint(of: CGSize(width: 20, height: 10)).rows, 1)
        XCTAssertEqual(geometry.footprint(of: CGSize(width: 14, height: 14)).columns, 1)
        XCTAssertEqual(geometry.footprint(of: CGSize(width: 14, height: 14)).rows, 1)
    }

    func testAnOrdinaryBrickClaimsOneCellAndABigOneClaimsFour() {
        let ordinary = geometry.footprint(of: CGSize(width: 40, height: 20))
        XCTAssertEqual(ordinary.columns, 1)
        XCTAssertEqual(ordinary.rows, 1)

        let big = geometry.footprint(of: CGSize(width: 80, height: 40))
        XCTAssertEqual(big.columns, 2)
        XCTAssertEqual(big.rows, 2)
    }

    // MARK: - Neighbours

    func testThereAreEightNeighboursAndTheCellIsNotOneOfThem() {
        let cell = EndlessIICell(column: 5, row: 5)
        let neighbours = EndlessIIFieldGeometry.neighbours(of: cell)

        XCTAssertEqual(neighbours.count, 8)
        XCTAssertEqual(Set(neighbours).count, 8)
        XCTAssertFalse(neighbours.contains(cell))
        for neighbour in neighbours {
            XCTAssertLessThanOrEqual(abs(neighbour.column - cell.column), 1)
            XCTAssertLessThanOrEqual(abs(neighbour.row - cell.row), 1)
        }
    }

    func testNeighboursOffTheEdgeAreReportedAndLeftToTheCaller() {
        // Corners still return eight; whether a cell is on the field is a separate question,
        // because the answer differs - a Spawner must not fill one, an explosion may find
        // nothing there and carry on.
        let corner = EndlessIICell(column: 0, row: 0)
        let neighbours = EndlessIIFieldGeometry.neighbours(of: corner)
        XCTAssertEqual(neighbours.count, 8)
        XCTAssertTrue(neighbours.contains(EndlessIICell(column: -1, row: -1)))
        XCTAssertFalse(geometry.isInsideWidth(EndlessIICell(column: -1, row: 0)))
        XCTAssertFalse(geometry.isInsideWidth(EndlessIICell(column: 11, row: 0)))
        XCTAssertTrue(geometry.isInsideWidth(EndlessIICell(column: 10, row: 0)))
    }

    // MARK: - Impact side

    func testAWideBrickStruckOnTopReportsTheTop() {
        // Scaled by the brick's half-extents. Without that a brick twice as wide as it is
        // tall reports a top hit for almost anything, and a Directional brick facing up
        // would be destructible from the sides.
        let size = CGSize(width: 40, height: 20)
        let brick = CGPoint(x: 0, y: 0)

        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: 15, y: 12),
                                            brickAt: brick, brickSize: size), .top)
        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: -15, y: -12),
                                            brickAt: brick, brickSize: size), .bottom)
        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: 24, y: 5),
                                            brickAt: brick, brickSize: size), .right)
        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: -24, y: -5),
                                            brickAt: brick, brickSize: size), .left)
    }

    func testTheSideIsRelativeToTheBrickNotTheOrigin() {
        let size = CGSize(width: 40, height: 20)
        let brick = CGPoint(x: -180, y: 260)
        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: brick.x, y: brick.y + 14),
                                            brickAt: brick, brickSize: size), .top)
        XCTAssertEqual(EndlessIIImpact.side(ballAt: CGPoint(x: brick.x - 26, y: brick.y),
                                            brickAt: brick, brickSize: size), .left)
    }

    // MARK: - Roles

    func testARoleTravelsWithItsBrick() {
        let brick = SKSpriteNode()
        XCTAssertNil(brick.endlessIIRole)

        brick.endlessIIRole = .portal
        XCTAssertEqual(brick.endlessIIRole, .portal)

        brick.endlessIIVulnerableSide = .left
        XCTAssertEqual(brick.endlessIIVulnerableSide, .left)
        XCTAssertEqual(brick.endlessIIRole, .portal, "setting one must not clear the other")

        brick.endlessIIRole = nil
        XCTAssertNil(brick.endlessIIRole)
    }

    func testABrickWithNoRoleIsTheDefault() {
        // Every brick in Classic and Endless goes through the same hit path, so the absence
        // of a role is what keeps all of this inert there.
        XCTAssertNil(SKSpriteNode().endlessIIRole)
        XCTAssertNil(SKSpriteNode().endlessIIVulnerableSide)
    }
}
