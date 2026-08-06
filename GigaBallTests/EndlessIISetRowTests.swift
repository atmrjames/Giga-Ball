//
//  EndlessIISetRowTests.swift
//  GigaBallTests
//
//  Set rows are written as text so a person can read and edit them, which means a typo in one
//  is a shape that silently comes out wrong rather than a compile error. These check the
//  things a typo would break.
//

import XCTest
@testable import Giga_Ball

final class EndlessIISetRowTests: XCTestCase {

    func testEveryPatternIsOneToThreeRows() {
        // Longer than three and it stops being a landmark and becomes the field.
        for pattern in EndlessIISetRow.all {
            XCTAssertGreaterThan(pattern.rows.count, 0, pattern.name)
            XCTAssertLessThanOrEqual(pattern.rows.count, 3, pattern.name)
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
        let known: Set<Character> = [".", "N", "M", "i", "I", "?"]
        for pattern in EndlessIISetRow.all {
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
        for pattern in EndlessIISetRow.all {
            let anyGap = pattern.rows.contains { $0.contains(".") }
            let anyBreakable = pattern.rows.contains { row in
                row.contains(where: { $0 == "N" || $0 == "M" || $0 == "?" })
            }
            XCTAssertTrue(anyGap || anyBreakable, "\(pattern.name) can never be got past")
        }
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
