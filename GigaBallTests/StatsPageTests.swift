//
//  StatsPageTests.swift
//  GigaBallTests
//
//  The statistics page used to be twenty-five hard-coded rows, each deciding for itself whether
//  it had anything to show. Splitting it into a section per mode (play-test round 11) moved that
//  decision somewhere it can be checked, and these are the checks.
//
//  The two things worth guarding are the ones that would be embarrassing rather than wrong: a
//  section showing rows about a mode that has never been played, and a section that has been
//  played showing nothing at all.
//

import XCTest
@testable import Giga_Ball

final class StatsPageTests: XCTestCase {

    private func labels(_ tab: StatsPage.Tab, _ stats: TotalStats) -> [String] {
        StatsPage.rows(for: tab, stats: stats).map { $0.label }
    }

    // MARK: - A player who has never played

    func testEverySectionOfAFreshFileSaysThereIsNothingYet() {
        let fresh = TotalStats()
        for tab in StatsPage.Tab.allCases {
            XCTAssertEqual(StatsPage.rows(for: tab, stats: fresh), [StatsPage.nothingYet],
                           "\(tab)")
        }
    }

    func testASectionIsNeverEmpty() {
        // An empty section is a blank screen with a title on it, which reads as a page that has
        // failed to load rather than as a mode not yet played
        let fresh = TotalStats()
        for tab in StatsPage.Tab.allCases {
            XCTAssertFalse(StatsPage.rows(for: tab, stats: fresh).isEmpty, "\(tab)")
        }
    }

    // MARK: - Each mode fills in only its own section

    func testAnEndlessRunFillsEndlessAndLeavesMayhemEmpty() {
        let stats = TotalStats()
        stats.endlessModeHeight = [40, 120, 80]
        stats.playTimeSecs = 600

        XCTAssertEqual(labels(.endless, stats),
                       ["Runs played", "Best height", "Total height", "Average height"])
        XCTAssertEqual(StatsPage.rows(for: .mayhem, stats: stats), [StatsPage.nothingYet])
        XCTAssertEqual(StatsPage.rows(for: .classic, stats: stats), [StatsPage.nothingYet])

        let values = StatsPage.rows(for: .endless, stats: stats).map { $0.value }
        XCTAssertEqual(values, ["3", "120 m", "240 m", "80 m"])
    }

    func testAMayhemRunFillsMayhemAndLeavesEndlessEmpty() {
        // Endless Mayhem's heights had no home on the old page at all - it shipped a mode whose
        // numbers were recorded and never shown
        let stats = TotalStats()
        stats.endlessIIModeHeight = [55]

        XCTAssertEqual(StatsPage.rows(for: .mayhem, stats: stats).map { $0.value },
                       ["1", "55 m", "55 m", "55 m"])
        XCTAssertEqual(StatsPage.rows(for: .endless, stats: stats), [StatsPage.nothingYet])
    }

    func testClassicRowsNeedALevelPlayed() {
        let stats = TotalStats()
        XCTAssertEqual(StatsPage.rows(for: .classic, stats: stats), [StatsPage.nothingYet])

        stats.levelsPlayed = 4
        stats.levelsCompleted = 3
        stats.cumulativeScore = 9_120
        XCTAssertTrue(labels(.classic, stats).contains("Total score"))
        XCTAssertEqual(StatsPage.rows(for: .classic, stats: stats)
                        .first { $0.label == "Level completion rate" }?.value, "75%")
    }

    func testDailyRowsCountOnlyTheDaysThatLanded() {
        let stats = TotalStats()
        var played = DailyChallengeRecord(dateKey: "2026-08-09")
        played.firstAttemptScore = 4_000
        played.attemptCount = 3
        var posted = DailyChallengeRecord(dateKey: "2026-08-10")
        posted.firstAttemptScore = 7_500
        posted.attemptCount = 1
        posted.posted = true
        posted.postedNormalisedScore = 610
        stats.dailyChallengeRecords = [played, posted]

        let rows = StatsPage.rows(for: .daily, stats: stats)
        XCTAssertEqual(rows.first { $0.label == "Days played" }?.value, "2")
        XCTAssertEqual(rows.first { $0.label == "Days posted" }?.value, "1")
        XCTAssertEqual(rows.first { $0.label == "Attempts" }?.value, "4")
        // The counting attempt is the first one, so the best day is the best first attempt
        XCTAssertEqual(rows.first { $0.label == "Best day score" }?.value, "7500")
        XCTAssertEqual(rows.first { $0.label == "Total posted score" }?.value, "610")
    }

    // MARK: - Overall

    func testOverallCountsPlayInEveryMode() {
        // A player who has only ever played Mayhem still has an Overall section: the play time
        // and the ball counts are written on every mode's branch
        let stats = TotalStats()
        stats.endlessIIModeHeight = [30]
        stats.playTimeSecs = 4_000
        stats.ballHits = 250

        let rows = StatsPage.rows(for: .overall, stats: stats)
        XCTAssertNotEqual(rows, [StatsPage.nothingYet])
        XCTAssertEqual(rows.first?.label, "Total play time")
        XCTAssertEqual(rows.first?.value, "1 hour")
    }

    func testLasersAppearOnlyOnceOneHasBeenFired() {
        let stats = TotalStats()
        stats.levelsPlayed = 1
        XCTAssertFalse(labels(.overall, stats).contains("Lasers fired"))

        stats.lasersFired = 12
        stats.lasersHit = 5
        XCTAssertTrue(labels(.overall, stats).contains("Lasers fired"))
        XCTAssertTrue(labels(.overall, stats).contains("Lasers hit"))
    }

    // MARK: - Formatting

    func testAPercentageOfNothingIsZeroRatherThanNotANumber() {
        // Dividing by a mode played zero times printed the word "nan" on the page
        XCTAssertEqual(StatsPage.percentage(0, of: 0), "0%")
        XCTAssertEqual(StatsPage.percentage(3, of: 4), "75%")
    }

    func testPlayTimeReadsInTheUnitsItAlwaysHas() {
        XCTAssertEqual(StatsPage.playTime(0), "1 minute")
        // Under two minutes still reads as one: a first level takes less than a minute, and
        // being told you have played for no time at all is the wrong thing to say
        XCTAssertEqual(StatsPage.playTime(119), "1 minute")
        XCTAssertEqual(StatsPage.playTime(600), "10 minutes")
        XCTAssertEqual(StatsPage.playTime(3_601), "1 hour")
        XCTAssertEqual(StatsPage.playTime(7_200), "2 hours")
    }

    func testEveryTabHasATitleShortEnoughToSitFiveAcross() {
        for tab in StatsPage.Tab.allCases {
            XCTAssertFalse(tab.title.isEmpty, "\(tab)")
            XCTAssertLessThanOrEqual(tab.title.count, 8, tab.title)
        }
        // The picker is built from allCases, so a tab added without a section would show an
        // empty segment rather than fail to compile
        XCTAssertEqual(StatsPage.Tab.allCases.count, 5)
    }
}
