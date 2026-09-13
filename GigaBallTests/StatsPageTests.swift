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
                       ["Runs played", "Hi-Score height", "Total height", "Average height"])
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
        XCTAssertEqual(rows.first { $0.label == "Hi-Score day" }?.value,
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
        XCTAssertEqual(rows.first { $0.label == "Most hits on a single ball" }?.value, "41")
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
        XCTAssertFalse(labels.contains("Most hits on a single ball"),
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

// MARK: - Paddle speed

/// "Is the paddle speed try-out screen still in the backlog?" It was open rather than
/// backlogged, and this is it (play-test round 13): a slider from 1.0 to 3.0 in tenths,
/// which the old five-step index could not express. The conversion is what these pin -
/// a player who has been on x1.25 for years must open the new screen already on x1.25.
final class PaddleSpeedTests: XCTestCase {

    private func emptyDefaults() -> UserDefaults {
        let suite = UserDefaults(suiteName: "paddleSpeedTests")!
        suite.removePersistentDomain(forName: "paddleSpeedTests")
        return suite
    }

    func testAFreshInstallGetsTheShippedDefaultRatherThanTheSlowestPaddle() {
        // `integer(forKey:)` answers 0 for a key that was never written, and 0 was a real
        // index meaning x1.00 - so reading it that way would hand every new player the
        // slowest paddle while the code claimed the default was x1.50
        XCTAssertEqual(PaddleSpeed.stored(emptyDefaults()), PaddleSpeed.fallback)
    }

    func testAnOldIndexIsReadAsTheSpeedItAlwaysMeant() {
        let defaults = emptyDefaults()
        for (index, factor) in PaddleSpeed.legacyFactors.enumerated() {
            defaults.set(index, forKey: PaddleSpeed.legacyKey)
            XCTAssertEqual(PaddleSpeed.stored(defaults), factor,
                           "index \(index) has meant \(factor) since 2020")
        }
    }

    func testTheChosenSpeedWinsOverTheOldIndex() {
        let defaults = emptyDefaults()
        defaults.set(0, forKey: PaddleSpeed.legacyKey)
        PaddleSpeed.store(2.25, in: defaults)
        XCTAssertEqual(PaddleSpeed.stored(defaults), 2.25, accuracy: 0.0001)
    }

    func testSavingAlsoLeavesTheOldKeyPointingSomewhereSensible() {
        // A settings file is a save format, and one that goes silently empty is what
        // bites a downgrade or a restore
        let defaults = emptyDefaults()
        PaddleSpeed.store(2.1, in: defaults)
        XCTAssertEqual(defaults.integer(forKey: PaddleSpeed.legacyKey), 3,
                       "x2.10 is nearest the old x2.00 step")
    }

    func testTheSliderMovesInQuartersAndStaysInItsRange() {
        // Quarters rather than tenths (James, round 121): nine steps a thumb can land on,
        // and every one of the five old settings is still exactly reachable
        XCTAssertEqual(PaddleSpeed.snapped(1.6), 1.5, accuracy: 0.0001)
        XCTAssertEqual(PaddleSpeed.snapped(1.7), 1.75, accuracy: 0.0001)
        XCTAssertEqual(PaddleSpeed.snapped(0.2), 1.0, accuracy: 0.0001)
        XCTAssertEqual(PaddleSpeed.snapped(9), 3.0, accuracy: 0.0001)
        for legacy in PaddleSpeed.legacyFactors {
            XCTAssertEqual(PaddleSpeed.snapped(legacy), legacy, accuracy: 0.0001,
                           "an old setting must land exactly on a step, not near one")
        }
    }

    func testTheLabelReadsTheWayTheRowAlwaysHas() {
        XCTAssertEqual(PaddleSpeed.label(1.5), "x1.50")
        XCTAssertEqual(PaddleSpeed.label(3), "x3.00")
    }
}

/// "Total play time per mode" and "duration stats beside height for both endless modes"
/// (play-test round 85's stats list).
final class PerModeTimeTests: XCTestCase {

    func testTheFourModesSplitTheSameSecondsTheTotalCounts() {
        let stats = TotalStats()
        stats.creditPlayTime(30, mode: .classic, isDailyChallenge: false)
        stats.creditPlayTime(40, mode: .endless, isDailyChallenge: false)
        stats.creditPlayTime(50, mode: .endlessII, isDailyChallenge: false)
        stats.creditPlayTime(60, mode: .endlessII, isDailyChallenge: true)

        XCTAssertEqual(stats.classicPlayTimeSecs, 30)
        XCTAssertEqual(stats.endlessPlayTimeSecs, 40)
        XCTAssertEqual(stats.endlessIIPlayTimeSecs, 50)
        XCTAssertEqual(stats.dailyPlayTimeSecs, 60,
                       "a daily is its own game whatever field it borrows")
    }

    func testAModeNeverPlayedStaysAbsentRatherThanZero() {
        let stats = TotalStats()
        XCTAssertNil(stats.classicPlayTimeSecs)
        stats.creditPlayTime(0, mode: .classic, isDailyChallenge: false)
        XCTAssertNil(stats.classicPlayTimeSecs, "a level that took no time is not a play time")

        XCTAssertFalse(StatsPage.rows(for: .classic, stats: stats)
                        .contains { $0.label == "Play time" },
                       "a tab never played should not print a play time of none")
    }

    func testThePlayTimeRowAppearsOnceTheModeHasBeenPlayed() {
        let stats = TotalStats()
        stats.levelsPlayed = 1
        stats.creditPlayTime(3_661, mode: .classic, isDailyChallenge: false)
        let row = StatsPage.rows(for: .classic, stats: stats).first { $0.label == "Play time" }
        XCTAssertEqual(row?.value, StatsPage.playTime(3_661))
    }

    /// A run is not a lifetime: `playTime` floors everything under two minutes to "1 minute",
    /// and most endless runs end inside two minutes - so every run would report the same
    /// figure and the longest would equal the average for ever.
    func testARunIsTimedAtARunsScaleRatherThanALifetimes() {
        XCTAssertEqual(StatsPage.runTime(45), "45s")
        XCTAssertEqual(StatsPage.runTime(60), "1m 00s")
        XCTAssertEqual(StatsPage.runTime(125), "2m 05s")
        XCTAssertEqual(StatsPage.playTime(45), "1 minute", "the lifetime total keeps its shape")
    }

    func testRunDurationsRideBesideTheHeights() {
        let stats = TotalStats()
        stats.endlessModeHeight = [10, 40]
        stats.recordRunDuration(60, inMayhem: false)
        stats.recordRunDuration(120, inMayhem: false)

        let rows = StatsPage.rows(for: .endless, stats: stats)
        XCTAssertEqual(rows.first { $0.label == "Longest run" }?.value, StatsPage.runTime(120))
        XCTAssertEqual(rows.first { $0.label == "Average run" }?.value, StatsPage.runTime(90))
    }

    func testTheAverageRunCountsOnlyTheRunsThatHaveADuration() {
        // Durations went into the save long after heights did, so a long-standing player has
        // runs from before they existed. Dividing the recorded seconds by every run ever
        // played would report an average shorter than any run they have actually had
        let stats = TotalStats()
        stats.endlessIIModeHeight = [10, 20, 30, 40]
        stats.recordRunDuration(100, inMayhem: true)

        let rows = StatsPage.rows(for: .mayhem, stats: stats)
        XCTAssertEqual(rows.first { $0.label == "Average run" }?.value, StatsPage.runTime(100))
    }

    func testAnEndlessModeWithNoDurationsYetShowsNoneOfTheseRows() {
        let stats = TotalStats()
        stats.endlessModeHeight = [10]
        let rows = StatsPage.rows(for: .endless, stats: stats)
        XCTAssertFalse(rows.contains { $0.label == "Longest run" })
        XCTAssertTrue(rows.contains { $0.label == "Hi-Score height" }, "the heights still show")
    }

    // MARK: - The achievements page's tabs

    // Play-test round 126: "Use tab bar in achievements view". The tabs are the statistics
    // page's, so what is filed under each has to match where the achievement can be earned.

    func testTheTabsAreTheStatisticsPagesTabs() {
        XCTAssertEqual(AchievementCatalogue.tabs.map(\.title),
                       ["All"] + StatsPage.Tab.allCases.dropFirst().map(\.title),
                       "one screen's sections, read off the other's, so they cannot drift")
    }

    /// **Every achievement is filed under a tab**, and for ten of them that tab is the Daily.
    ///
    /// This asked for at least one *play* mode and was right until round 318, which moved the
    /// daily's ten out of "every play mode" and into a set that names no play mode at all -
    /// they are facts about a history rather than about a rally. So the question is no longer
    /// "does it belong to a mode" but "is it reachable from a tab", which is what a player
    /// actually needs and what the page actually does: `earnableInDaily` is how the Daily tab
    /// finds them.
    ///
    /// The invariant this protects is unchanged and is the one that matters: an achievement
    /// listed under nothing is invisible on that page however correct its data is.
    func testEveryAchievementIsFiledUnderAtLeastOneTab() {
        let count = LevelPackSetup().achievementsNameArray.count
        for index in 0..<count {
            let listed = AchievementCatalogue.modes(for: index).isEmpty == false
                || AchievementCatalogue.dailyOnly.contains(index)
            XCTAssertTrue(listed, "achievement \(index) "
                          + "\"\(LevelPackSetup().achievementsNameArray[index])\" is on no tab")
        }
    }

    func testAnAchievementIsNeverBothEndlessOnlyAndClassicOnly() {
        XCTAssertTrue(AchievementCatalogue.endlessOnly
            .isDisjoint(with: AchievementCatalogue.classicOnly))
    }

    /// **An Endless milestone is listed under Endless alone** (James, round 318: "remove the
    /// endless mode achievements from showing up in the endless mayhem section").
    ///
    /// This asserted the opposite, and its reasoning was right when it was written: `endlessMode`
    /// is true in both endless modes and none of these checks asks which, so a height milestone
    /// really is *earnable* in either. What changed is round 309, which gave Mayhem its own
    /// eleven milestones - so the Mayhem tab listed Endless's eleven above Mayhem's eleven,
    /// every pair saying the same thing twice.
    ///
    /// Earning is deliberately unchanged: taking these off a Mayhem run would take achievements
    /// off players who hold them. This is about which tab lists them.
    func testAnEndlessMilestoneIsListedUnderEndlessAlone() {
        XCTAssertTrue(AchievementCatalogue.belongs(0, to: .endless))
        XCTAssertFalse(AchievementCatalogue.belongs(0, to: .endlessII),
                       "Mayhem has its own 10m milestone at 66 - listing Endless's as well "
                       + "is the same achievement twice under one heading")
        XCTAssertFalse(AchievementCatalogue.belongs(0, to: .classic))
        XCTAssertTrue(AchievementCatalogue.belongs(66, to: .endlessII), "and Mayhem's own stays")
    }

    /// The daily's own history is under the Daily tab and nowhere else.
    ///
    /// Ten of them fell through to the default bucket, which is "every play mode", so Week Long
    /// Streak and First Daily Challenge were listed under Classic, Endless and Mayhem. They are
    /// facts about a history rather than about a rally, and no amount of Classic play earns one.
    func testTheDailysOwnAchievementsAreOnlyUnderDaily() {
        for index in AchievementCatalogue.dailyOnly {
            XCTAssertTrue(AchievementCatalogue.belongs(index, to: .daily), "\(index)")
            for mode in [GameMode.classic, .endless, .endlessII] {
                XCTAssertFalse(AchievementCatalogue.belongs(index, to: mode),
                               "achievement \(index) is a daily fact and was listed under "
                               + "\(mode)")
            }
        }
    }

    /// **Every index in a mode set names the achievement its comment says it does.**
    ///
    /// This is the test that would have caught round 318's other fault, and it is the only kind
    /// that can: a number typed into a `Set<Int>` is unverifiable by reading. `endlessOnly` held
    /// 95 with the comment "Butter Fingers", and 95 is *Top Of The Charts* - so a daily
    /// leaderboard placing was filed as an endless achievement, two places off, and Butter
    /// Fingers was left in the bucket that means "earnable everywhere".
    ///
    /// Asked by name rather than by number: the sets are checked against what the strings
    /// actually say, so the next index typed into one is checked the moment it is added.
    func testTheModeSetsNameWhatTheyThinkTheyName() {
        let names = LevelPackSetup().achievementsNameArray

        for index in AchievementCatalogue.endlessOnly {
            let name = names[index]
            XCTAssertFalse(name.contains("Mayhem"),
                           "\(index) \"\(name)\" is a Mayhem achievement in endlessOnly")
            XCTAssertFalse(name.contains("Daily") || name.contains("Streak")
                           || name.contains("Charts") || name.contains("Top 10"),
                           "\(index) \"\(name)\" is a daily achievement in endlessOnly")
            XCTAssertFalse(name.contains("Pack"),
                           "\(index) \"\(name)\" is a Classic achievement in endlessOnly")
        }

        for index in AchievementCatalogue.mayhemOnly where names[index].contains("Milestone")
            || names[index].contains("Total Height") {
            XCTAssertTrue(names[index].contains("Mayhem"),
                          "\(index) \"\(names[index])\" is under Mayhem and does not say so")
        }

        for index in AchievementCatalogue.endlessOnly where names[index].contains("Milestone")
            || names[index].contains("Total Height") {
            XCTAssertTrue(names[index].contains("Endless Mode"),
                          "\(index) \"\(names[index])\" is under Endless and does not say so")
        }

        for index in AchievementCatalogue.dailyOnly {
            let name = names[index]
            XCTAssertTrue(name.contains("Daily") || name.contains("Streak")
                          || name.contains("Charts") || name.contains("Top 10")
                          || name.contains("Twist"),
                          "\(index) \"\(name)\" is filed as the daily's own history and "
                          + "does not read like one")
        }
    }

    func testAPackAchievementIsClassicOnly() {
        XCTAssertTrue(AchievementCatalogue.belongs(6, to: .classic))
        XCTAssertFalse(AchievementCatalogue.belongs(6, to: .endless))
        XCTAssertFalse(AchievementCatalogue.belongs(6, to: .endlessII))
    }

    func testAPowerUpAchievementCountsEverywhere() {
        // "Now We're Talking" - a first power-up, wherever the paddle was
        for mode in [GameMode.classic, .endless, .endlessII] {
            XCTAssertTrue(AchievementCatalogue.belongs(24, to: mode), "\(mode)")
        }
    }

    /// **The daily's tab has rows in it now** (round 310, from James's workbook).
    ///
    /// It used to be empty, and the note under it explained why: `achievementsCheck()` returns
    /// early for a daily, because a daily played on a level someone has not earned must not
    /// unlock what earning it would have (daily spec §9). That was right for the campaign's
    /// achievements and was only a blanket because the daily had nothing of its own.
    ///
    /// The tab is `earnableInDaily`, which is the workbook's Daily Challenge column - and the
    /// note stays, because a tab that lists nineteen of ninety-eight still owes the reader an
    /// explanation of what it is not listing.
    func testTheDailyTabIsTheWorkbooksOwnColumn() {
        let count = LevelPackSetup().achievementsNameArray.count
        let listed = Set(AchievementCatalogue.indices(for: .daily, count: count))
        XCTAssertEqual(listed, AchievementCatalogue.earnableInDaily)
        XCTAssertFalse(listed.isEmpty, "the daily has its own set as of round 310")
        XCTAssertTrue(AchievementCatalogue.emptyNote(for: .daily).isEmpty == false)
    }

    /// And §9's rule survives it: not one of them is a level's or a pack's.
    ///
    /// This is the assertion that matters. The tab could be wrong in a way the equality above
    /// cannot see - `earnableInDaily` is a written-down set, and a mistake in it would be
    /// faithfully reproduced by both. What must never be true is that a day on a lent level can
    /// unlock what earning that level would have.
    func testNothingEarnableInADailyIsAboutALevelOrAPack() {
        for index in AchievementCatalogue.earnableInDaily {
            XCTAssertFalse(AchievementCatalogue.classicOnly.contains(index),
                           "\(LevelPackSetup().achievementsNameArray[index]) is filed under "
                           + "Classic, which is where every level and pack achievement lives")
        }
    }

    func testTheAllTabHoldsEveryAchievement() {
        let count = LevelPackSetup().achievementsNameArray.count
        XCTAssertEqual(AchievementCatalogue.indices(for: nil, count: count).count, count)
    }

    /// Both sync tables must name every field, or a device quietly keeps a stat to itself -
    /// the shape of trap ENDLESS-2-SPECIFICATION §8.6 keeps warning about.
    func testEverySyncedModeTimeIsNamedInTheKeyTable() {
        XCTAssertEqual(CloudKitHandler.modeTimeKeys.count, 4)
        XCTAssertEqual(CloudKitHandler.runDurationKeys.count, 2)
        XCTAssertEqual(Set(CloudKitHandler.modeTimeKeys.map(\.key)).count, 4,
                       "no two modes may share an iCloud key")
    }
}
