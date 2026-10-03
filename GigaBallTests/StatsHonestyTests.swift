//
//  StatsHonestyTests.swift
//  GigaBallTests
//
//  James, round 361, with a screenshot of the statistics page: "my power-ups collected is
//  higher than the power ups released, lasers hit is higher that lasers fired and bricks hit is
//  way higher than bricks destroyed. How is that possible?" 12,012 released, 40,953 collected,
//  341%; 19,928 lasers fired, 21,055 hit.
//
//  Bricks hit over bricks destroyed is honest - an Indestructible is hit for ever and never
//  destroyed, a Multi-Hit takes four - and so, James agreed, is lasers hit over fired: it counts
//  bricks struck, and a Giga-Ball laser strikes a column. Only the power-ups were a fault.
//

import XCTest
@testable import Giga_Ball

final class CollectionsHeldToReleasesTests: XCTestCase {

    /// What the Always On twist left in the file before round 341: one slot caught thousands
    /// of times and released once.
    func testNoPowerUpIsCaughtMoreOftenThanItFell() {
        let stats = TotalStats()
        stats.powerupsGenerated[3] = 1
        stats.powerupsCollected[3] = 28_000
        stats.powerupsGenerated[5] = 40
        stats.powerupsCollected[5] = 31
        stats.makeStoredArraysConsistent()

        XCTAssertEqual(stats.powerupsCollected[3], 1)
        XCTAssertEqual(stats.powerupsCollected[5], 31, "an honest tally is left alone")
        XCTAssertLessThanOrEqual(stats.powerupsCollected.reduce(0, +),
                                 stats.powerupsGenerated.reduce(0, +))
    }

    /// Lasers hit is a count of bricks struck and is allowed past the shots fired (James,
    /// round 361: "It's ok if lasers hit > lasers fired, I understand the reason").
    func testLasersHitIsLeftAsItIs() {
        let stats = TotalStats()
        stats.lasersFired = 19_928
        stats.lasersHit = 21_055
        stats.makeStoredArraysConsistent()
        XCTAssertEqual(stats.lasersHit, 21_055)
    }

    /// The page reads a rate of a hundred at most once the file is loaded.
    func testTheCollectionRateIsNeverOverAHundred() {
        let stats = TotalStats()
        stats.powerupsGenerated[0] = 10
        stats.powerupsCollected[0] = 34
        stats.levelsPlayed = 1
        stats.makeStoredArraysConsistent()
        let rows = StatsPage.rows(for: .overall, stats: stats)
        XCTAssertEqual(rows.first { $0.label == "Power-up collection rate" }?.value, "100%")
    }
}
