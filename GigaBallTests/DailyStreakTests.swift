//
//  DailyStreakTests.swift
//  GigaBallTests
//
//  §7's streaks, derived from the per-day records rather than stored beside them.
//

import XCTest
@testable import Giga_Ball

final class DailyStreakTests: XCTestCase {

    private func day(_ key: String) -> Date { DailyStreak.date(fromKey: key)! }

    private func records(posted: [String], played: [String] = []) -> [DailyChallengeRecord] {
        posted.map { DailyChallengeRecord(dateKey: $0, firstAttemptScore: 100, posted: true) }
            + played.map { DailyChallengeRecord(dateKey: $0, posted: false, attemptCount: 3) }
    }

    // MARK: - The current streak

    func testAStreakIsTheDaysInARowEndingToday() {
        let history = records(posted: ["2026-03-01", "2026-03-02", "2026-03-03"])
        XCTAssertEqual(DailyStreak.current(records: history, today: day("2026-03-03")), 3)
    }

    /// **Today being unplayed does not break it.** The day is not over, and a player told
    /// their streak was broken every morning until they played would be told a lie by lunch.
    func testTodayUnplayedLeavesYesterdaysStreakStanding() {
        let history = records(posted: ["2026-03-01", "2026-03-02", "2026-03-03"])
        XCTAssertEqual(DailyStreak.current(records: history, today: day("2026-03-04")), 3)
    }

    /// Missing yesterday as well is the streak being over rather than in progress.
    func testMissingYesterdayEndsIt() {
        let history = records(posted: ["2026-03-01", "2026-03-02", "2026-03-03"])
        XCTAssertEqual(DailyStreak.current(records: history, today: day("2026-03-05")), 0)
    }

    /// **A day played but not posted is not a day in the streak.** Practice is playable all
    /// day, and a streak of days somebody opened would be a streak of nothing.
    func testPracticeDaysDoNotCount() {
        let history = records(posted: ["2026-03-01", "2026-03-03"], played: ["2026-03-02"])
        XCTAssertEqual(DailyStreak.current(records: history, today: day("2026-03-03")), 1)
    }

    func testNoHistoryIsNoStreak() {
        XCTAssertEqual(DailyStreak.current(records: [], today: day("2026-03-03")), 0)
        XCTAssertEqual(DailyStreak.longest(records: []), 0)
    }

    // MARK: - The longest

    func testTheLongestIsTheBestRunThereHasEverBeen() {
        let history = records(posted: ["2026-03-01", "2026-03-02", "2026-03-03",
                                       "2026-03-09",
                                       "2026-03-20", "2026-03-21"])
        XCTAssertEqual(DailyStreak.longest(records: history), 3)
        XCTAssertEqual(DailyStreak.current(records: history, today: day("2026-03-21")), 2,
                       "the current one is the run it is in, not the best one it has had")
    }

    func testOneDayIsAStreakOfOne() {
        XCTAssertEqual(DailyStreak.longest(records: records(posted: ["2026-03-01"])), 1)
    }

    // MARK: - The calendar does the counting

    /// **Months, and February.** The days either side of a boundary are consecutive, and
    /// string arithmetic on "2026-02-28" would say otherwise.
    func testItCountsAcrossMonthAndYearBoundaries() {
        XCTAssertTrue(DailyStreak.isTheDayAfter("2026-03-01", "2026-02-28"))
        XCTAssertTrue(DailyStreak.isTheDayAfter("2027-01-01", "2026-12-31"))
        XCTAssertFalse(DailyStreak.isTheDayAfter("2026-03-02", "2026-02-28"))

        let across = records(posted: ["2026-02-27", "2026-02-28", "2026-03-01", "2026-03-02"])
        XCTAssertEqual(DailyStreak.current(records: across, today: day("2026-03-02")), 4)
    }

    /// A leap year has a 29th, and it is in the middle of the run.
    func testALeapDayIsADayLikeAnyOther() {
        let leap = records(posted: ["2028-02-28", "2028-02-29", "2028-03-01"])
        XCTAssertEqual(DailyStreak.longest(records: leap), 3)
        XCTAssertTrue(DailyStreak.isTheDayAfter("2028-02-29", "2028-02-28"))
    }

    /// And a year that is not a leap year has none, so the 28th runs into the 1st.
    func testANonLeapYearHasNoTwentyNinth() {
        XCTAssertTrue(DailyStreak.isTheDayAfter("2026-03-01", "2026-02-28"))
        XCTAssertNil(DailyStreak.date(fromKey: "2026-02-29"),
                     "2026 is not a leap year, so there is no 29th to be a day")
    }

    /// **A key that names no day is refused rather than rolled forward.**
    ///
    /// `Calendar.date(from:)` is lenient - handed a 30th of February it returns the 2nd of
    /// March rather than nil - so without a check a corrupted key out of iCloud would quietly
    /// become a real day and could join a streak it has nothing to do with.
    func testAKeyThatNamesNoDayIsRefused() {
        for nonsense in ["2026-02-30", "2026-13-01", "2026-00-10", "2026-01-32",
                         "not-a-date", "2026-01", ""] {
            XCTAssertNil(DailyStreak.date(fromKey: nonsense), nonsense)
        }
        XCTAssertNotNil(DailyStreak.date(fromKey: "2026-02-28"), "and a real day still is one")
    }

    /// Nothing is stored, so two devices merging their histories agree by construction.
    ///
    /// The reason the streak is derived rather than kept in `TotalStats` beside the records:
    /// a stored counter would have to be recomputed on every merge, and a device that did not
    /// would carry a streak its own history denies.
    func testAMergedHistoryAnswersForItself() {
        let phone = records(posted: ["2026-03-01", "2026-03-02"])
        let pad = records(posted: ["2026-03-03", "2026-03-04"])
        let merged = DailyChallengeRecord.merged(phone, pad)

        XCTAssertEqual(DailyStreak.current(records: merged, today: day("2026-03-04")), 4,
                       "neither device had a four-day streak; together they did")
    }

    /// The days a run is counted in read as days.
    func testTheUnitsReadAsDays() {
        XCTAssertEqual(StatsPage.days(1), "1 day")
        XCTAssertEqual(StatsPage.days(0), "0 days")
        XCTAssertEqual(StatsPage.days(12), "12 days")
    }
}
