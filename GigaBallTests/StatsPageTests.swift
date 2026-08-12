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
        XCTAssertEqual(rows.first { $0.label == "Best day score" }?.value,
                       StatsPage.grouped(7_500))
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

    // MARK: - Row icons

    /// A symbol name that does not resolve draws nothing at all - it does not fail - so the
    /// only way this is caught is by asking for the image.
    ///
    /// This walks a file with every mode played, because a row that is never built is a row
    /// whose icon is never checked.
    func testEveryRowIconResolves() {
        let stats = TotalStats()
        stats.levelsPlayed = 6
        stats.levelsCompleted = 4
        stats.lasersFired = 3
        stats.endlessModeHeight = [20]
        stats.endlessIIModeHeight = [30]
        var day = DailyChallengeRecord(dateKey: "2026-08-10")
        day.firstAttemptScore = 900
        day.posted = true
        stats.dailyChallengeRecords = [day]

        var checked = 0
        for tab in StatsPage.Tab.allCases {
            for row in StatsPage.rows(for: tab, stats: stats) {
                guard let icon = row.icon else { continue }
                XCTAssertNotNil(UIImage(systemName: icon), "\(row.label): \(icon)")
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 25, "most of the page should be carrying an icon")
    }

    func testEveryRowThatSaysSomethingCarriesAnIcon() {
        // Except the empty state, which is a sentence rather than a statistic
        let stats = TotalStats()
        stats.levelsPlayed = 6
        for tab in [StatsPage.Tab.overall, .classic] {
            for row in StatsPage.rows(for: tab, stats: stats) {
                XCTAssertNotNil(row.icon, row.label)
            }
        }
        XCTAssertNil(StatsPage.nothingYet.icon)
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

    // MARK: - Thousands separators

    /// The statistics page groups its numbers; a lifetime brick count runs to seven digits
    /// and "1234567" has to be counted rather than read.
    func testLargeCountsAreGrouped() {
        XCTAssertEqual(StatsPage.grouped(1_234_567, locale: Locale(identifier: "en_GB")),
                       "1,234,567")
        XCTAssertEqual(StatsPage.grouped(999, locale: Locale(identifier: "en_GB")), "999")
    }

    /// The separator is the reader's own. A German player's thousands separator is a full
    /// stop, and a hard-coded comma would print a decimal point in their brick count.
    func testTheSeparatorIsTheReadersNotAComma() {
        XCTAssertEqual(StatsPage.grouped(1_234_567, locale: Locale(identifier: "de_DE")),
                       "1.234.567")
    }

    /// A fraction is two small numbers read as one thing. Grouping inside it would divide
    /// something already divided.
    func testFractionsAreNotGrouped() {
        XCTAssertEqual(StatsPage.fraction(1_000, 2_000), "1000/2000")
    }

    /// Every count on the page goes through the grouping, so a big number cannot appear
    /// ungrouped next to a grouped one.
    func testEveryCountOnThePageIsGrouped() {
        let stats = TotalStats()
        stats.levelsPlayed = 1_234_567
        stats.levelsCompleted = 1_234_567
        stats.cumulativeScore = 1_234_567
        stats.ballHits = 1_234_567
        stats.ballsLost = 1_234_567
        stats.bricksHit = [1_234_567]
        stats.bricksDestroyed = [1_234_567]
        stats.powerupsGenerated = [1_234_567]
        stats.powerupsCollected = [1_234_567]
        stats.packsPlayed = 1_234_567
        stats.packsCompleted = 1_234_567
        stats.lasersFired = 1_234_567
        stats.lasersHit = 1_234_567
        stats.endlessModeHeight = [1_234_567]
        stats.endlessIIModeHeight = [1_234_567]

        for tab in StatsPage.Tab.allCases {
            for row in StatsPage.rows(for: tab, stats: stats) {
                XCTAssertFalse(row.value.contains("1234567"),
                               "\(tab) - \(row.label): \(row.value)")
            }
        }
    }

    // MARK: - Hits per ball

    /// The average is arithmetic on two totals; the best has to be stored, because a maximum
    /// cannot be recovered from totals. Both wait until a ball has actually been lost.
    func testHitsPerBallAppearOnlyOnceABallHasBeenLost() {
        let stats = TotalStats()
        stats.levelsPlayed = 1
        stats.ballHits = 90
        XCTAssertFalse(labels(.overall, stats).contains("Average hits per ball"),
                       "nothing to divide by yet")

        stats.ballsLost = 6
        stats.bestBallHits = 41
        let rows = StatsPage.rows(for: .overall, stats: stats)
        XCTAssertEqual(rows.first { $0.label == "Average hits per ball" }?.value, "15")
        XCTAssertEqual(rows.first { $0.label == "Best single ball" }?.value, "41 hits")
    }

    /// A stats file written before `bestBallHits` existed decodes with it absent, and the page
    /// must read that as "no best yet" rather than crashing or printing nothing.
    func testAnOlderSaveWithNoBestBallReadsAsNone() {
        let stats = TotalStats()
        XCTAssertNil(stats.bestBallHits)
        XCTAssertEqual(stats.longestBallRun, 0)

        stats.levelsPlayed = 1
        stats.ballsLost = 2
        stats.ballHits = 10
        let labels = self.labels(.overall, stats)
        XCTAssertTrue(labels.contains("Average hits per ball"))
        XCTAssertFalse(labels.contains("Best single ball"),
                       "an absent best is not a best of zero")
    }

    // MARK: - Most effective power-up

    /// "The power up which saw the biggest height gain whilst active" - the play test's own
    /// words for what this row answers.
    func testTheMostEffectivePowerUpIsTheOneWithTheMostMetres() {
        var metres = TotalStats.freshPowerUpMetres
        metres[4] = 120
        metres[7] = 340
        metres[9] = 91
        XCTAssertEqual(StatsPage.mostEffective(metres)?.index, 7)
        XCTAssertEqual(StatsPage.mostEffective(metres)?.metres, 340)
    }

    /// James's answer to design question one: instant power-ups score nothing. They earn no
    /// exclusion list either - they are never *running*, so they are never counted, and an
    /// all-zero array must therefore produce no row at all rather than a nought-metre winner.
    func testAModeWithNoTimedPowerUpsHasNoAnswer() {
        XCTAssertNil(StatsPage.mostEffective(TotalStats.freshPowerUpMetres),
                     "nought metres for everything is no answer, not a winner on nought")
        XCTAssertNil(StatsPage.mostEffective(nil),
                     "a mode never played has no answer")
    }

    /// Ties go to the earlier power-up, which is the app's own display order. The rule is
    /// arbitrary; being the *same* answer twice is not.
    func testATieGoesToTheEarlierPowerUp() {
        var metres = TotalStats.freshPowerUpMetres
        metres[11] = 50
        metres[3] = 50
        XCTAssertEqual(StatsPage.mostEffective(metres)?.index, 3)
    }

    /// The row appears on the endless tabs and names the power-up, and the two endless modes
    /// are counted apart - Mayhem's climb must not decide Endless's answer.
    func testTheEndlessTabsCountApart() {
        let stats = TotalStats()
        stats.endlessModeHeight = [40]
        stats.endlessIIModeHeight = [90]

        var endless = TotalStats.freshPowerUpMetres
        endless[2] = 10
        stats.endlessPowerUpMetres = endless

        var mayhem = TotalStats.freshPowerUpMetres
        mayhem[5] = 10
        stats.endlessIIPowerUpMetres = mayhem

        let names = LevelPackSetup().powerUpNameArray
        let endlessRows = StatsPage.rows(for: .endless, stats: stats)
        let mayhemRows = StatsPage.rows(for: .mayhem, stats: stats)
        XCTAssertEqual(endlessRows.first { $0.label == "Most effective power-up" }?.value,
                       names[2])
        XCTAssertEqual(mayhemRows.first { $0.label == "Most effective power-up" }?.value,
                       names[5])
    }

    /// Every power-up running when a metre is scored gets the whole metre - James's answer to
    /// design question two. The totals therefore sum to more than the height climbed, which
    /// is the accepted cost of saying *while active* rather than *because of*.
    func testOverlappingPowerUpsEachGetTheWholeMetre() {
        let stats = TotalStats()
        stats.creditMetre(to: [3, 8, 12], inMayhem: true)
        stats.creditMetre(to: [3], inMayhem: true)

        let metres = stats.powerUpMetres(inMayhem: true)
        XCTAssertEqual(metres[3], 2)
        XCTAssertEqual(metres[8], 1)
        XCTAssertEqual(metres[12], 1)
        XCTAssertEqual(metres.reduce(0, +), 4, "two metres climbed, four metres credited")
        XCTAssertNil(stats.endlessPowerUpMetres, "a Mayhem metre is not an Endless one")
    }

    /// A stats file written before this existed decodes with both arrays absent, and the page
    /// has to read that as "no answer" rather than as a mode played with nothing running.
    func testAnOlderSaveHasNoMetresAndNoRow() {
        let stats = TotalStats()
        XCTAssertNil(stats.endlessPowerUpMetres)
        XCTAssertNil(stats.endlessIIPowerUpMetres)

        stats.endlessIIModeHeight = [30]
        XCTAssertFalse(labels(.mayhem, stats).contains("Most effective power-up"))

        stats.makeStoredArraysConsistent()
        XCTAssertNil(stats.endlessIIPowerUpMetres,
                     "padding must not turn never-played into played-and-scored-nothing")
    }

    /// The slots are sized off the power-up list rather than a literal, so the fifty-first
    /// power-up grows them with everything else.
    func testThereIsASlotForEveryPowerUp() {
        XCTAssertEqual(TotalStats.freshPowerUpMetres.count,
                       LevelPackSetup().powerUpNameArray.count)
    }
}
