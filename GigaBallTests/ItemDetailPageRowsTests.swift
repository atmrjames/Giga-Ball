//
//  ItemDetailPageRowsTests.swift
//  GigaBallTests
//
//  The rows of an item's own page - a power-up's facts and an achievement's state (round 364).
//
//  `ItemsStatsViewController.tableView(_:cellForRowAt:)` was a quarter covered: the brick page
//  ran under the tests and the power-up and achievement pages never did, though both changed in
//  rounds 351 and 361. Each expectation is read off the catalogue the page reads, so the test
//  says "the page shows what the game holds" rather than restating one power-up's numbers.
//

import XCTest
@testable import Giga_Ball

final class ItemDetailPageRowsTests: XCTestCase {

    private func page(sender: String, index: Int,
                      _ configure: (TotalStats) -> Void = { _ in }) throws -> ItemsStatsViewController {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: ItemsStatsViewController.self))
        let page = try XCTUnwrap(board.instantiateViewController(withIdentifier: "itemsStatsView")
                                 as? ItemsStatsViewController)
        let stats = TotalStats()
        configure(stats)
        page.totalStatsArray = [stats]
        page.sender = sender
        page.passedIndex = index
        page.loadViewIfNeeded()
        page.totalStatsArray = [stats]
        // Again after loading: the page reads the stats file as it loads, and the test's own
        // record is the one under test
        page.statsTableView.reloadData()
        return page
    }

    /// The page's rows as it would draw them: (what, value).
    private func rows(_ page: ItemsStatsViewController) -> [(String, String)] {
        let table = page.statsTableView!
        return (0..<page.tableView(table, numberOfRowsInSection: 0)).map { row in
            let cell = page.tableView(table, cellForRowAt: IndexPath(row: row, section: 0))
                as! StatsTableViewCell
            return (cell.statDescription.text ?? "", cell.statValue.text ?? "")
        }
    }

    private func value(_ label: String, in rows: [(String, String)]) -> String? {
        rows.first { $0.0 == label }?.1
    }

    // MARK: - A power-up's page

    /// Released, collected and the rate, from the player's own tallies.
    func testAPowerUpsPageShowsItsTallies() throws {
        let setup = LevelPackSetup()
        let index = try XCTUnwrap((0..<LevelPackSetup.firstEndlessIIPowerUp).first {
            setup.powerUpMultiplierArray[$0].isEmpty == false
                && setup.powerUpTimerArray[$0].isEmpty == false
        }, "a power-up with a multiplier and a duration")
        let shown = rows(try page(sender: "Power-Ups", index: index) {
            $0.powerupsGenerated[index] = 10
            $0.powerupsCollected[index] = 7
        })
        XCTAssertEqual(value("Released", in: shown), "10")
        XCTAssertEqual(value("Collected", in: shown), "7")
        XCTAssertEqual(value("Collection rate", in: shown), "70%")
        XCTAssertEqual(value("Duration", in: shown), setup.powerUpTimerArray[index])
        let multiplier = setup.powerUpMultiplierArray[index]
        XCTAssertEqual(value(multiplier.hasPrefix("+") ? "Multiplier bonus" : "Multiplier penalty",
                             in: shown), multiplier)
        XCTAssertNil(value("Found in", in: shown), "found everywhere, so the page does not say")
    }

    /// A power-up never released has no rate to give, and says nothing rather than "0%".
    func testAPowerUpNeverSeenHasNoRate() throws {
        let shown = rows(try page(sender: "Power-Ups", index: 0))
        XCTAssertNil(value("Collection rate", in: shown))
        XCTAssertEqual(value("Released", in: shown), "0")
    }

    /// A Mayhem power-up says where it is found.
    func testAMayhemPowerUpSaysWhereItIsFound() throws {
        let index = LevelPackSetup.firstEndlessIIPowerUp
        XCTAssertEqual(value("Found in", in: rows(try page(sender: "Power-Ups", index: index))),
                       GameMode.endlessII.name)
    }

    /// No row stands empty: every row the page counts has something in it (round 351).
    func testEveryPowerUpsRowsAllSaySomething() throws {
        let setup = LevelPackSetup()
        for index in setup.powerUpNameArray.indices where setup.retiredPowerUpIndices.contains(index) == false {
            for (label, value) in rows(try page(sender: "Power-Ups", index: index)) {
                XCTAssertFalse(label.isEmpty, "\(setup.powerUpNameArray[index]): an empty row")
                XCTAssertFalse(value.isEmpty, "\(setup.powerUpNameArray[index]): \(label) has no value")
            }
        }
    }

    // MARK: - An achievement's page

    func testAnEarnedAchievementSaysWhen() throws {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 5; components.hour = 12
        let date = Calendar.current.date(from: components)!
        let shown = rows(try page(sender: "Achievements", index: 89) {
            $0.achievementsUnlockedArray[89] = true
            $0.achievementDates[89] = date
        })
        XCTAssertEqual(shown.first?.0, "Date completed")
        XCTAssertEqual(shown.first?.1, "05/09/2026")
    }

    /// An all-or-nothing achievement not yet earned is Incomplete, with no share beside it
    /// (James, round 361: "they are either complete or not").
    func testAnUnearnedAllOrNothingAchievementIsIncomplete() throws {
        let shown = rows(try page(sender: "Achievements", index: 82))
        XCTAssertEqual(shown.first?.0, "Incomplete")
        XCTAssertEqual(shown.first?.1, "")
    }

    /// One with a share shows it, under the label the share is.
    func testAnUnearnedCountedAchievementShowsItsShare() throws {
        let shown = rows(try page(sender: "Achievements", index: 28) {
            $0.achievementsPercentageCompleteArray[28] = "42.0%"
        })
        XCTAssertEqual(shown.first?.0, TotalStats.achievementProgressLabel(28))
        XCTAssertEqual(shown.first?.1, "42.0%")
    }
}
