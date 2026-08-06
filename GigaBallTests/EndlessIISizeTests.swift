//
//  EndlessIISizeTests.swift
//  GigaBallTests
//
//  A Big brick's node sits on a row centre while its sprite covers four cells around it.
//  That split is what lets the descent and the bottom-row check keep working unchanged, and
//  it is exactly the kind of arithmetic that looks right and is off by half a cell. These
//  pin it against the same formula the generator uses to place an ordinary brick.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIISizeTests: XCTestCase {

    // The real proportions: a cell is twice as wide as it is tall.
    private let cell = CGSize(width: 40, height: 20)
    private let gameWidth: CGFloat = 440   // 11 columns
    private let columns = 11
    private let rowY: CGFloat = 300

    private var plan: EndlessIIBigBrick { EndlessIIBigBrick(cell: cell) }

    /// Where the generator puts an ordinary brick in a column.
    private func ordinaryX(_ column: Int) -> CGFloat {
        -gameWidth/2 + cell.width/2 + cell.width*CGFloat(column)
    }

    func testItSitsOnTheLeftColumnLikeAnyOtherBrick() {
        // The node's position is what the descent moves and what the bottom-row check
        // reads, so it has to be an ordinary cell position, not the middle of four.
        for column in 0..<(columns - 1) {
            XCTAssertEqual(plan.nodeX(leftColumn: column, gameWidth: gameWidth),
                           ordinaryX(column), accuracy: 0.0001)
        }
    }

    func testItCoversExactlyTwoColumnsAndTwoRows() {
        let covered = plan.coverage(leftColumn: 3, rowY: rowY, gameWidth: gameWidth)

        XCTAssertEqual(covered.width, cell.width*2, accuracy: 0.0001)
        XCTAssertEqual(covered.height, cell.height*2, accuracy: 0.0001)
        XCTAssertEqual(covered.minX, ordinaryX(3) - cell.width/2, accuracy: 0.0001)
        XCTAssertEqual(covered.maxX, ordinaryX(4) + cell.width/2, accuracy: 0.0001)
        // Its own row on top, and the row below - the gap left for it a row earlier
        XCTAssertEqual(covered.maxY, rowY + cell.height/2, accuracy: 0.0001)
        XCTAssertEqual(covered.minY, rowY - cell.height - cell.height/2, accuracy: 0.0001)
    }

    func testTheAnchorPointPutsTheSpriteWhereTheCoverageSaysItIs() {
        // The sprite is placed by anchor point, the coverage is computed directly. If these
        // disagree the brick is drawn somewhere other than where it is solid.
        let column = 5
        let x = plan.nodeX(leftColumn: column, gameWidth: gameWidth)
        let anchor = plan.anchorPoint
        let size = plan.size

        let drawn = CGRect(x: x - anchor.x*size.width, y: rowY - anchor.y*size.height,
                           width: size.width, height: size.height)
        let claimed = plan.coverage(leftColumn: column, rowY: rowY, gameWidth: gameWidth)

        XCTAssertEqual(drawn.minX, claimed.minX, accuracy: 0.0001)
        XCTAssertEqual(drawn.minY, claimed.minY, accuracy: 0.0001)
        XCTAssertEqual(drawn.width, claimed.width, accuracy: 0.0001)
        XCTAssertEqual(drawn.height, claimed.height, accuracy: 0.0001)
    }

    func testTheBodyIsCentredOnTheSpriteNotTheNode() {
        let column = 2
        let claimed = plan.coverage(leftColumn: column, rowY: rowY, gameWidth: gameWidth)
        let nodeAt = CGPoint(x: plan.nodeX(leftColumn: column, gameWidth: gameWidth), y: rowY)
        let bodyAt = CGPoint(x: nodeAt.x + plan.bodyCentre.x, y: nodeAt.y + plan.bodyCentre.y)

        XCTAssertEqual(bodyAt.x, claimed.midX, accuracy: 0.0001)
        XCTAssertEqual(bodyAt.y, claimed.midY, accuracy: 0.0001)
    }

    // MARK: - Fitting

    func testItNeverHangsOffTheRightEdge() {
        XCTAssertTrue(EndlessIIBigBrick.fits(leftColumn: columns - 2, columns: columns))
        XCTAssertFalse(EndlessIIBigBrick.fits(leftColumn: columns - 1, columns: columns))
        XCTAssertFalse(EndlessIIBigBrick.fits(leftColumn: -1, columns: columns))
        XCTAssertTrue(EndlessIIBigBrick.fits(leftColumn: 0, columns: columns))
    }

    func testEveryColumnTheGeneratorCanPickFits() {
        // The generator draws from 0..<columns-1; nothing in that range may fall off.
        for column in 0..<(columns - 1) {
            XCTAssertTrue(EndlessIIBigBrick.fits(leftColumn: column, columns: columns),
                          "column \(column)")
            let covered = plan.coverage(leftColumn: column, rowY: rowY, gameWidth: gameWidth)
            XCTAssertGreaterThanOrEqual(covered.minX, -gameWidth/2 - 0.0001, "column \(column)")
            XCTAssertLessThanOrEqual(covered.maxX, gameWidth/2 + 0.0001, "column \(column)")
        }
    }
}

extension EndlessIISizeTests {

    // MARK: - Tiny layouts

    func testATinySetIsEitherFourQuartersOrADiagonalPair() {
        // Anything else would leave a cell filled in a way that reads as a mistake rather
        // than as a shape.
        for _ in 0..<200 {
            let layout = GameScene.endlessIITinyLayout()
            XCTAssertTrue(layout.count == 4 || layout.count == 2, "\(layout.count)")
        }
    }

    func testEveryQuarterSitsInADifferentCornerOfTheCell() {
        for _ in 0..<200 {
            let layout = GameScene.endlessIITinyLayout()
            XCTAssertEqual(Set(layout.map { "\($0.x),\($0.y)" }).count, layout.count)
            for offset in layout {
                XCTAssertEqual(abs(offset.x), 0.25, accuracy: 0.0001)
                XCTAssertEqual(abs(offset.y), 0.25, accuracy: 0.0001)
            }
        }
    }

    func testAPairIsAlwaysDiagonal() {
        // Two side by side would be an oddly-shaped brick; two on a diagonal leave a route
        // through the cell, which is the point of having them.
        for _ in 0..<200 {
            let layout = GameScene.endlessIITinyLayout()
            guard layout.count == 2 else { continue }
            XCTAssertNotEqual(layout[0].x, layout[1].x)
            XCTAssertNotEqual(layout[0].y, layout[1].y)
        }
    }

    func testTheFullSetIsTheCommonCase() {
        // A diagonal pair should read as a variation on something familiar.
        let full = (0..<400).filter { _ in GameScene.endlessIITinyLayout().count == 4 }.count
        XCTAssertGreaterThan(full, 200)
    }
}
