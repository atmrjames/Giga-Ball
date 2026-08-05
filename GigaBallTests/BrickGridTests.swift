//
//  BrickGridTests.swift
//  GigaBallTests
//
//  The grid is the foundation for every brick type that is bigger, smaller, moves or
//  cares what is next to it, so the rules it enforces are worth pinning before anything
//  is built on top of them.
//

import XCTest
import CoreGraphics
@testable import Giga_Ball

final class BrickGridTests: XCTestCase {

    /// Eleven brick columns, which is half the classic field, at half-cell resolution.
    private func grid(brickColumns: Int = 11, brickRows: Int = 8) -> BrickGrid {
        BrickGrid(brickColumns: brickColumns, brickRows: brickRows)
    }

    // MARK: - Resolution

    func testABrickFieldIsCountedInHalfCells() {
        let field = grid(brickColumns: 22, brickRows: 10)
        XCTAssertEqual(field.columns, 44)
        XCTAssertEqual(field.rows, 20)
    }

    func testTheThreeSizesFitTheHalfCellGridExactly() {
        // The whole reason for half-cell resolution: no fractions, no special cases.
        XCTAssertEqual(BrickSize.tiny.halfCells, 1)
        XCTAssertEqual(BrickSize.normal.halfCells, 2)
        XCTAssertEqual(BrickSize.big.halfCells, 4)
        XCTAssertEqual(BrickSize.tiny.scale, 0.5)
        XCTAssertEqual(BrickSize.normal.scale, 1.0)
        XCTAssertEqual(BrickSize.big.scale, 2.0)
    }

    func testFourTinyBricksFitWhereOneNormalWould() {
        var field = grid()
        for dx in 0..<2 {
            for dy in 0..<2 {
                XCTAssertNotNil(field.place(.tiny, at: GridCell(dx, dy)))
            }
        }
        XCTAssertEqual(field.count, 4)
        XCTAssertNil(field.place(.tiny, at: GridCell(0, 0)), "that quarter is taken")
    }

    // MARK: - Placement

    func testABrickOccupiesEveryCellItCovers() {
        var field = grid()
        let id = field.place(.big, at: GridCell(4, 4))
        XCTAssertNotNil(id)
        for dx in 4..<8 {
            for dy in 4..<8 {
                XCTAssertEqual(field.brick(at: GridCell(dx, dy))?.id, id)
            }
        }
        XCTAssertNil(field.brick(at: GridCell(8, 4)), "one past its right edge")
    }

    func testABrickWillNotOverlapAnother() {
        var field = grid()
        field.place(.normal, at: GridCell(2, 2))
        XCTAssertNil(field.place(.normal, at: GridCell(3, 2)), "overlaps by one half-cell")
        XCTAssertNotNil(field.place(.normal, at: GridCell(4, 2)), "clear of it")
    }

    func testABrickWillNotHangOffTheEdge() {
        var field = grid(brickColumns: 4, brickRows: 4)
        XCTAssertNil(field.place(.big, at: GridCell(6, 0)), "would run past the right edge")
        XCTAssertNotNil(field.place(.big, at: GridCell(4, 0)), "ends exactly at it")
    }

    func testRemovingABrickFreesItsCells() {
        var field = grid()
        let id = field.place(.big, at: GridCell(0, 0))!
        XCTAssertFalse(field.isFree(GridCell(2, 2)))
        field.remove(id: id)
        XCTAssertTrue(field.isFree(GridCell(2, 2)))
        XCTAssertNil(field.brick(id: id))
    }

    // MARK: - Reservation

    func testReservedCellsAreKeptClearWithoutHoldingABrick() {
        // What a Moving brick's roaming space and a Spinning brick's clearance need: the
        // cells are not occupied, but nothing may be put in them.
        var field = grid()
        field.reserve([GridCell(5, 5)])
        XCTAssertNil(field.brick(at: GridCell(5, 5)))
        XCTAssertFalse(field.isFree(GridCell(5, 5)))
        XCTAssertNil(field.place(.tiny, at: GridCell(5, 5)))
    }

    func testReleasingACellMakesItAvailableAgain() {
        var field = grid()
        field.reserve([GridCell(5, 5)])
        field.release([GridCell(5, 5)])
        XCTAssertNotNil(field.place(.tiny, at: GridCell(5, 5)))
    }

    // MARK: - Moving

    func testABrickCanMoveIntoSpaceItCurrentlyOccupies() {
        // A one-cell step overlaps the brick's own footprint, which must not block it.
        var field = grid()
        let id = field.place(.normal, at: GridCell(4, 4))!
        XCTAssertTrue(field.move(id: id, to: GridCell(5, 4)))
        XCTAssertEqual(field.brick(id: id)?.origin, GridCell(5, 4))
        XCTAssertTrue(field.isFree(GridCell(4, 4)), "the cell it left")
    }

    func testABrickWillNotMoveOntoAnother() {
        var field = grid()
        let mover = field.place(.normal, at: GridCell(0, 0))!
        field.place(.normal, at: GridCell(2, 0))
        XCTAssertFalse(field.move(id: mover, to: GridCell(1, 0)))
        XCTAssertEqual(field.brick(id: mover)?.origin, GridCell(0, 0), "left where it was")
    }

    func testABrickWillNotMoveIntoAReservedCell() {
        var field = grid()
        let id = field.place(.normal, at: GridCell(0, 0))!
        field.reserve([GridCell(2, 0)])
        XCTAssertFalse(field.move(id: id, to: GridCell(1, 0)))
    }

    // MARK: - Neighbours

    func testNeighboursIncludeDiagonals() {
        var field = grid()
        let centre = field.place(.tiny, at: GridCell(5, 5))!
        field.place(.tiny, at: GridCell(4, 4))   // diagonal
        field.place(.tiny, at: GridCell(5, 4))   // above
        field.place(.tiny, at: GridCell(7, 5))   // one gap away

        let touching = field.neighbours(of: centre).map(\.origin)
        XCTAssertEqual(Set(touching), [GridCell(4, 4), GridCell(5, 4)])
    }

    func testABigBrickTouchesEverythingAlongItsEdge() {
        // Adjacency is measured by cell, not by distance from a centre - so a Big brick's
        // blast reaches everything against its side, not just the nearest one.
        var field = grid()
        let big = field.place(.big, at: GridCell(4, 4))!
        field.place(.tiny, at: GridCell(3, 4))
        field.place(.tiny, at: GridCell(3, 7))
        field.place(.tiny, at: GridCell(3, 9))   // past its bottom corner

        XCTAssertEqual(field.neighbours(of: big).count, 2)
    }

    func testABrickIsNotItsOwnNeighbour() {
        var field = grid()
        let id = field.place(.big, at: GridCell(0, 0))!
        XCTAssertTrue(field.neighbours(of: id).isEmpty)
    }

    // MARK: - Falling

    func testABrickFallsUntilSomethingStopsIt() {
        var field = grid(brickColumns: 4, brickRows: 5)   // 10 rows of half-cells
        let floor = field.place(.normal, at: GridCell(0, 8))!
        let faller = field.place(.normal, at: GridCell(0, 0))!

        let moved = field.settle([faller])
        XCTAssertEqual(moved.count, 1)
        XCTAssertEqual(field.brick(id: faller)?.origin, GridCell(0, 6), "resting on the floor brick")
        XCTAssertEqual(field.brick(id: floor)?.origin, GridCell(0, 8), "which has not moved")
    }

    func testABrickFallsToTheBottomWhenNothingIsBelow() {
        var field = grid(brickColumns: 4, brickRows: 5)
        let faller = field.place(.normal, at: GridCell(0, 0))!
        field.settle([faller])
        XCTAssertEqual(field.brick(id: faller)?.origin, GridCell(0, 8), "the lowest row it fits in")
    }

    func testTwoBricksFallingIntoOneColumnStack() {
        // Settled from the bottom up, so the lower one lands first and the upper one rests
        // on it rather than passing through.
        var field = grid(brickColumns: 4, brickRows: 5)
        let upper = field.place(.normal, at: GridCell(0, 0))!
        let lower = field.place(.normal, at: GridCell(0, 4))!

        field.settle([upper, lower])

        XCTAssertEqual(field.brick(id: lower)?.origin, GridCell(0, 8))
        XCTAssertEqual(field.brick(id: upper)?.origin, GridCell(0, 6))
    }

    func testABrickWithNowhereToFallDoesNotReportAMove() {
        var field = grid(brickColumns: 4, brickRows: 5)
        let resting = field.place(.normal, at: GridCell(0, 8))!
        XCTAssertTrue(field.settle([resting]).isEmpty)
    }

    func testSettleReportsWhereEachBrickCameFromSoTheFallCanBeAnimated() {
        var field = grid(brickColumns: 4, brickRows: 5)
        let faller = field.place(.normal, at: GridCell(2, 0))!
        let moved = field.settle([faller])
        XCTAssertEqual(moved.first?.from, GridCell(2, 0))
        XCTAssertEqual(moved.first?.to, GridCell(2, 8))
    }

    // MARK: - Geometry

    private let rect = CGRect(x: -100, y: -200, width: 200, height: 400)

    func testHalfCellsDivideTheRectExactly() {
        let field = grid(brickColumns: 10, brickRows: 10)   // 20 x 20 half-cells
        let half = field.halfCellSize(in: rect)
        XCTAssertEqual(half.width, 10)
        XCTAssertEqual(half.height, 20)
    }

    func testRowZeroIsAtTheTopOfTheRect() {
        // Rows count downward while the scene's y counts upward, and getting this backwards
        // would build every field upside down.
        let field = grid(brickColumns: 10, brickRows: 10)
        let top = field.position(of: GridCell(0, 0), in: rect)
        let below = field.position(of: GridCell(0, 1), in: rect)
        XCTAssertGreaterThan(top.y, below.y)
        XCTAssertEqual(top.y, rect.maxY - 10)
    }

    func testABrickIsCentredOverEverythingItCovers() {
        var field = grid(brickColumns: 10, brickRows: 10)
        let id = field.place(.big, at: GridCell(0, 0))!
        let brick = field.brick(id: id)!

        XCTAssertEqual(field.centre(of: brick, in: rect).x, rect.minX + 20)
        XCTAssertEqual(field.size(of: brick, in: rect), CGSize(width: 40, height: 80))
    }

    func testATinyBrickIsAQuarterOfANormalOne() {
        var field = grid(brickColumns: 10, brickRows: 10)
        let tinyID = field.place(.tiny, at: GridCell(0, 0))!
        let normalID = field.place(.normal, at: GridCell(2, 0))!
        // Read back on their own lines: placing inside the argument of a read on the same
        // value mutates it mid-expression, and the read saw the grid as it was before
        let tiny = field.brick(id: tinyID)!
        let normal = field.brick(id: normalID)!

        let tinySize = field.size(of: tiny, in: rect)
        let normalSize = field.size(of: normal, in: rect)
        XCTAssertEqual(tinySize.width*2, normalSize.width)
        XCTAssertEqual(tinySize.height*2, normalSize.height)
    }

    func testAPointMapsBackToTheCellItLandsIn() {
        let field = grid(brickColumns: 10, brickRows: 10)
        let cell = GridCell(3, 7)
        let point = field.position(of: cell, in: rect)
        XCTAssertEqual(field.cell(at: point, in: rect), cell)
    }

    func testAPointOutsideTheGridMapsToNothing() {
        // All four edges. The two that fall short of the origin are the ones that matter:
        // truncation toward zero used to round them back into row or column 0.
        let field = grid(brickColumns: 10, brickRows: 10)
        XCTAssertNil(field.cell(at: CGPoint(x: rect.maxX + 10, y: 0), in: rect), "right")
        XCTAssertNil(field.cell(at: CGPoint(x: rect.minX - 1, y: 0), in: rect), "left")
        XCTAssertNil(field.cell(at: CGPoint(x: 0, y: rect.maxY + 1), in: rect), "above")
        XCTAssertNil(field.cell(at: CGPoint(x: 0, y: rect.minY - 10), in: rect), "below")
    }
}
