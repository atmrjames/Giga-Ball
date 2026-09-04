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

/// The last clause of §8's posted-score container: "free play attempts played after the post
/// get listed in the same container".
final class DailyFreePlayLineTests: XCTestCase {

    private func record(attempts: Int, best: Int = 0) -> DailyChallengeRecord {
        DailyChallengeRecord(dateKey: "2026-03-01", firstAttemptScore: 900, posted: true,
                             bestPracticeScore: best, attemptCount: attempts)
    }

    /// **The counting attempt is not free play.** A day played once has none, and saying
    /// "1 free play" under its own score would be counting the same run twice.
    func testTheFirstAttemptIsNotFreePlay() {
        XCTAssertNil(DailyCardView.freePlayLine(record(attempts: 1), unit: ""))
        XCTAssertNil(DailyCardView.freePlayLine(record(attempts: 0), unit: ""))
    }

    func testItCountsTheAttemptsBeyondTheFirst() {
        XCTAssertEqual(DailyCardView.freePlayLine(record(attempts: 2, best: 400), unit: ""),
                       "1 free play, best 400")
        XCTAssertEqual(DailyCardView.freePlayLine(record(attempts: 4, best: 400), unit: ""),
                       "3 free plays, best 400")
    }

    /// An endless day counts in metres, like everything else about it.
    func testItCarriesTheModesUnit() {
        XCTAssertEqual(DailyCardView.freePlayLine(record(attempts: 2, best: 120), unit: "m"),
                       "1 free play, best 120m")
    }

    /// Free plays that scored nothing are still free plays.
    func testAFreePlayWithNoScoreIsStillCounted() {
        XCTAssertEqual(DailyCardView.freePlayLine(record(attempts: 3), unit: ""), "2 free plays")
    }

    /// **A free play that beat the posted score is still shown.** Hiding it would be the
    /// summary quietly editing what happened; the posted score is the day's number and says so
    /// on the line above.
    func testABetterFreePlayIsNotHidden() {
        XCTAssertEqual(DailyCardView.freePlayLine(record(attempts: 2, best: 5000), unit: ""),
                       "1 free play, best 5000")
    }

    /// **A day that did not post shows no free-play line**, because its headline number is
    /// already the best of everything played - `max(firstAttemptScore, bestPracticeScore)` - so
    /// a line under it would print the same figure twice.
    ///
    /// Found by drawing the card and looking at it: the strings were right and the card said
    /// 8100m over 8100m. §8's wording is "free play attempts played *after the post*", which is
    /// the rule this restores.
    func testANotPostedDayShowsNoFreePlayLine() {
        let card = DailyCardView(frame: CGRect(x: 0, y: 0, width: 360, height: 400))
        let missed = DailyChallengeRecord(dateKey: "2026-03-03", firstAttemptScore: 0,
                                          posted: false, bestPracticeScore: 8100,
                                          attemptCount: 3)
        card.show(key: missed.dateKey, isToday: true, record: missed, standing: nil)
        XCTAssertEqual(card.resultTextForTesting.contains("free play"), false,
                       "the headline is already the free-play best")

        let posted = DailyChallengeRecord(dateKey: "2026-03-02", firstAttemptScore: 12480,
                                          posted: true, bestPracticeScore: 15900,
                                          attemptCount: 4)
        card.show(key: posted.dateKey, isToday: true, record: posted, standing: nil)
        XCTAssertEqual(card.resultTextForTesting.contains("free play"), false,
                       "**and a posted day does not list them either, since round 306** "
                       + "(James: \"there's no need to show the details of the free play game "
                       + "scores\"). It was §8's posted-score container doing what §8 asked, "
                       + "and the card is better without it: a second score beside the day's "
                       + "own invited exactly the comparison it then had to explain away. "
                       + "`freePlayLine` itself is still built and still tested below - this "
                       + "is about what the card chooses to draw")
        XCTAssertTrue(card.resultTextForTesting.contains("12480"),
                      "the day's own number is still the headline")
    }

    /// It says free play, which is what the player reads everywhere else (round 12's rename).
    func testItUsesTheWordThePlayerReads() {
        let line = DailyCardView.freePlayLine(record(attempts: 2, best: 10), unit: "")
        XCTAssertEqual(line?.contains("practice"), false)
        XCTAssertEqual(line?.contains("free play"), true)
    }
}
