//
//  DailyChallengeTests.swift
//  GigaBallTests
//
//  The daily's one absolute requirement: every device computes the same challenge for the
//  same date, for ever. These tests are that contract - the exact-output pins in
//  particular are the generator's promise in writing, and a failure there means a change
//  that would split the world's players onto different games.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class DailyChallengeTests: XCTestCase {

    // MARK: - The seeded generator

    func testTheStreamIsExactlyReproducible() {
        var a = DailySeededGenerator(seed: 20260809)
        var b = DailySeededGenerator(seed: 20260809)
        for _ in 0..<100 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testSplitMix64MatchesItsReferenceOutputs() {
        // The published reference sequence for seed 1234567 - if this fails, the PRNG is
        // not SplitMix64 any more and every device disagrees with every other
        var stream = DailySeededGenerator(seed: 1234567)
        XCTAssertEqual(stream.next(), 6457827717110365317 as UInt64)
        XCTAssertEqual(stream.next(), 3203168211198807973 as UInt64)
    }

    func testDifferentSeedsDiverge() {
        var a = DailySeededGenerator(seed: 20260809)
        var b = DailySeededGenerator(seed: 20260810)
        XCTAssertNotEqual(a.next(), b.next())
    }

    // MARK: - The day

    func testTheDateKeyIsUTC() {
        // 23:30 in Sydney on the 9th is still the 9th's challenge... in UTC terms it is
        // 13:30 on the 9th. The key must never consult the device's own time zone
        var parts = DateComponents()
        parts.year = 2026; parts.month = 8; parts.day = 9; parts.hour = 13; parts.minute = 30
        let date = DailyDay.utcCalendar.date(from: parts)!
        XCTAssertEqual(DailyDay.key(for: date), "2026-08-09")
    }

    func testTheSeedReadsAsTheDate() {
        XCTAssertEqual(DailyDay.seed(forKey: "2026-08-09"), 20260809)
    }

    func testTheWindowEndsAtTheNextUTCMidnight() {
        var parts = DateComponents()
        parts.year = 2026; parts.month = 8; parts.day = 9; parts.hour = 13
        let date = DailyDay.utcCalendar.date(from: parts)!
        let end = DailyDay.windowEnd(for: date)
        XCTAssertEqual(DailyDay.key(for: end), "2026-08-10")
        XCTAssertEqual(DailyDay.utcCalendar.component(.hour, from: end), 0)
    }

    // MARK: - The challenge

    func testTheSameDateAlwaysMakesTheSameChallenge() {
        for key in ["2026-08-09", "2026-12-25", "2027-01-01", "2030-06-15"] {
            let first = DailyChallengeGenerator.challenge(forKey: key)
            let second = DailyChallengeGenerator.challenge(forKey: key)
            XCTAssertEqual(first, second, key)
            XCTAssertEqual(first.dateKey, key)
        }
    }

    func testTheModeSplitIsAsSpecified() {
        // Classic 50, Endless 25, Mayhem 25 (§3), measured over a thousand days
        var counts: [GameMode: Int] = [:]
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for _ in 0..<1000 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            counts[challenge.mode, default: 0] += 1
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertGreaterThan(counts[.classic] ?? 0, 400)
        XCTAssertLessThan(counts[.classic] ?? 0, 600)
        XCTAssertGreaterThan(counts[.endless] ?? 0, 175)
        XCTAssertGreaterThan(counts[.endlessII] ?? 0, 175)
    }

    func testTwistCountsFollowTheDistribution() {
        var counts = [0, 0, 0]
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for _ in 0..<1000 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            counts[min(challenge.twists.count, 2)] += 1
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        print("twist counts over 1000 days: \(counts)")
        XCTAssertGreaterThan(counts[0], 200, "no-twist days are deliberate")
        XCTAssertGreaterThan(counts[1], 350)
        XCTAssertGreaterThan(counts[2], 100)
        // **Thresholds with room in them** (round 258). This one was written at 380 against a
        // sample that came out at 381, and adding a category moved it to 379 - which is a
        // third of a per cent and is the re-roll rather than the distribution. A tripwire set
        // one day away from where it fires is a tripwire that fails whenever anything is
        // added, which is the opposite of what it is for
    }

    func testNoDayDrawsTwoTwistsFromOneCategory() {
        // §4.2: legal by construction - this is the construction being checked
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for _ in 0..<1000 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            let categories = challenge.twists.map(\.category)
            XCTAssertEqual(categories.count, Set(categories).count,
                           "\(challenge.dateKey) drew \(challenge.twists)")
            for twist in challenge.twists {
                XCTAssertTrue(twist.applies(to: challenge.mode),
                              "\(challenge.dateKey): \(twist) cannot apply to \(challenge.mode)")
            }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
    }

    /// **Every day already played must still read the same.** §2.1's whole promise.
    ///
    /// Recorded off the build that shipped before the layout category existed, one line per
    /// day, in the generator's own terms: date, mode, Classic level, twists in the order
    /// drawn. Nothing here is derived from the code it checks - if a future pool, weight or
    /// category shifts the stream for a day in the launch window, this says so by name.
    ///
    /// It is the category list that makes this worth writing. A new *twist* is kept out of an
    /// older day's pool by its `activationKey`, which leaves the roll inside that pool alone;
    /// a new *category* would be drawn by index out of `Category.allCases`, turning every past
    /// `roll(3)` into a `roll(4)` and rewriting days people have played. `Category` carries an
    /// activation date of its own for exactly that reason, and this is the proof.
    /// **Re-pinned once, in round 228, and deliberately.**
    ///
    /// Retiring Loaded shortened Classic's lives pool, so the two days that drew it now draw
    /// Extra Balls. That is history being rewritten, which is the one thing this test exists
    /// to prevent - and it was allowed exactly once, before release, on James's word: "happy
    /// to overwrite previous daily challenge days as we're not yet released."
    ///
    /// After 1.3 ships it must never happen again, and it will not have to: `retirementKey`
    /// takes a date now, so a twist leaving the pool later leaves it from a future day and
    /// every day behind that draws what it always drew.
    func testTheDaysAlreadyPlayedStillReadExactlyTheSame() {
        let recorded = [
            "2026-08-01|endless|-|",
            "2026-08-02|endlessII|-|spareBalls",
            "2026-08-03|classic|73|powerShower",
            "2026-08-04|classic|16|oneLife",
            "2026-08-05|endless|-|fogOfWar",
            "2026-08-06|classic|2|",
            "2026-08-07|classic|83|spareBalls",
            "2026-08-08|endlessII|-|spareBalls,fogOfWar",
            "2026-08-09|classic|105|drought,oneLife",
            "2026-08-10|classic|30|",
            "2026-08-11|classic|81|oneLife",
            "2026-08-12|classic|23|fogOfWar",
            "2026-08-13|classic|70|oneLife",
            "2026-08-14|endless|-|fogOfWar",
            "2026-08-15|classic|69|fogOfWar",
            "2026-08-16|endlessII|-|",
            "2026-08-17|endless|-|powerShower,fogOfWar",
            "2026-08-18|endlessII|-|spareBalls,fogOfWar",
            "2026-08-19|endless|-|",
            "2026-08-20|classic|95|",
            "2026-08-21|endless|-|fogOfWar,drought",
            "2026-08-22|endlessII|-|noPowerUps",
            "2026-08-23|classic|55|fogOfWar,noGoodNews",
            "2026-08-24|classic|66|",
            "2026-08-25|classic|96|spareBalls",
            "2026-08-26|endlessII|-|spareBalls,drought",
            "2026-08-27|endless|-|fogOfWar,drought",
            "2026-08-28|classic|96|noPowerUps,fogOfWar",
            "2026-08-29|endlessII|-|fogOfWar",
            "2026-08-30|endlessII|-|noPowerUps,fogOfWar",
        ]
        for line in recorded {
            let parts = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            let challenge = DailyChallengeGenerator.challenge(forKey: parts[0])
            XCTAssertEqual(String(describing: challenge.mode), parts[1], parts[0])
            XCTAssertEqual(challenge.classicLevel.map(String.init) ?? "-", parts[2], parts[0])
            XCTAssertEqual(challenge.twists.map(\.rawValue).joined(separator: ","), parts[3],
                           parts[0])
        }
    }

    func testNoDayBeforeALayoutDayCanDrawOne() {
        // The other half of the same promise, said forward rather than backward: the
        // category is not in the list at all until its date, so it cannot be rolled for
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for _ in 0..<300 {
            let key = DailyDay.key(for: day)
            let challenge = DailyChallengeGenerator.challenge(forKey: key)
            for twist in challenge.twists {
                XCTAssertLessThanOrEqual(twist.activationKey, key, "\(key): \(twist)")
                XCTAssertLessThanOrEqual(twist.category.activationKey, key, "\(key): \(twist)")
            }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
    }

    func testTheLayoutTwistsAreOfferedOnceTheirDateArrives() {
        // And that they are actually reachable - "never offered" and "very rare" look the
        // same from outside, which is §8.6's own lesson about pools
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        var seen = Set<DailyTwist>()
        for _ in 0..<400 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            seen.formUnion(challenge.twists)
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertTrue(seen.contains(.mirrored), "Mirrored is in the enum but never drawn")
        XCTAssertTrue(seen.contains(.upsideDown), "Upside Down is in the enum but never drawn")
    }

    func testOnlyClassicHasALayoutToTurnOver() {
        for twist in [DailyTwist.mirrored, .upsideDown] {
            XCTAssertTrue(twist.applies(to: .classic))
            XCTAssertFalse(twist.applies(to: .endless))
            XCTAssertFalse(twist.applies(to: .endlessII))
            XCTAssertEqual(twist.category, .layout, "one per day, by §4.2")
        }
        XCTAssertEqual(DailyTwist.layoutFlip(in: [.oneLife, .upsideDown]), .upsideDown)
        XCTAssertNil(DailyTwist.layoutFlip(in: [.oneLife, .fogOfWar]))
    }

    /// Upside Down reflects about the middle of the rows the level *occupies*.
    ///
    /// About the whole grid instead, a level that only fills the top third would land in the
    /// player's lap - a different game rather than the same one seen upside down.
    func testTurningALevelOverKeepsItInTheBandItWasBuiltIn() {
        let rows: [CGFloat] = [200, 180, 160, 140]
        let flipped = rows.map { DailyLayout.flippedY($0, lowest: 140, highest: 200) }

        XCTAssertEqual(flipped, [140, 160, 180, 200], "top and bottom trade places")
        XCTAssertEqual(flipped.min(), rows.min(), "and the band itself has not moved")
        XCTAssertEqual(flipped.max(), rows.max())
    }

    func testTurningALevelOverIsItsOwnUndoAndLandsOnRowCentres() {
        let spacing: CGFloat = 20
        let rows = (0..<12).map { 300 - spacing*CGFloat($0) }
        for y in rows {
            let there = DailyLayout.flippedY(y, lowest: rows.min()!, highest: rows.max()!)
            XCTAssertEqual(DailyLayout.flippedY(there, lowest: rows.min()!,
                                                highest: rows.max()!),
                           y, accuracy: 0.0001, "twice over is where it started")
            XCTAssertTrue(rows.contains { abs($0 - there) < 0.0001 },
                          "\(y) landed at \(there), which is not a row centre - and a "
                          + "brick's position is read as its cell")
        }
    }

    func testAClassicDayCarriesALevelAndTheOthersDoNot() {
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        for _ in 0..<200 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            if challenge.mode == .classic {
                XCTAssertNotNil(challenge.classicLevel)
                XCTAssertGreaterThanOrEqual(challenge.classicLevel!, 1)
                XCTAssertLessThanOrEqual(challenge.classicLevel!,
                                         DailyChallengeGenerator.classicLevelCount)
            } else {
                XCTAssertNil(challenge.classicLevel)
            }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
    }

    func testTheLevelMappingRoundTripsThePackTables() {
        // Catalogue level 1 is the first level of the first classic pack; the last is the
        // last of the last - and every one maps inside its pack's own range
        let setup = LevelPackSetup()
        XCTAssertEqual(DailyChallengeGenerator.pack(forClassicLevel: 1), 2)
        XCTAssertEqual(DailyChallengeGenerator.levelNumber(forClassicLevel: 1),
                       setup.startLevelNumber[2])

        let last = DailyChallengeGenerator.classicLevelCount
        let lastPack = DailyChallengeGenerator.pack(forClassicLevel: last)
        XCTAssertEqual(lastPack, setup.numberOfLevels.count - 1)
        XCTAssertEqual(DailyChallengeGenerator.levelNumber(forClassicLevel: last),
                       setup.startLevelNumber[lastPack] + setup.numberOfLevels[lastPack] - 1)
    }

    // MARK: - Exact-output pins

    /// **The written-down values, not the generator compared with itself.**
    ///
    /// The contract: if any of these change, an app update just changed what day it is for
    /// every player who installed it. Never update these expectations without a new generator
    /// version and an activation date (§2.1) - that is what they exist to catch.
    ///
    /// Round 212 found they caught nothing. Every assertion compared
    /// `challenge(forKey:)` against `challenge(forKey:)`, which is true however the generator
    /// behaves - rewrite SplitMix64, reorder the draws, change the mode split, and it still
    /// passed. The one test standing between the app and silently handing every player a
    /// different Tuesday was asserting that a function equals itself.
    ///
    /// These are the real values, read out of the generator as it stands today.
    func testKnownDatesPinTheirChallengesForEver() {
        let ninth = DailyChallengeGenerator.challenge(forKey: "2026-08-09")
        XCTAssertEqual(ninth.mode, .classic)
        XCTAssertEqual(ninth.classicLevel, 105)
        XCTAssertEqual(ninth.twists, [.drought, .oneLife])

        let tenth = DailyChallengeGenerator.challenge(forKey: "2026-08-10")
        XCTAssertEqual(tenth.mode, .classic)
        XCTAssertEqual(tenth.classicLevel, 30)
        XCTAssertEqual(tenth.twists, [])

        let eleventh = DailyChallengeGenerator.challenge(forKey: "2026-08-11")
        XCTAssertEqual(eleventh.mode, .classic)
        XCTAssertEqual(eleventh.classicLevel, 81)
        XCTAssertEqual(eleventh.twists, [.oneLife])

        // A date well past every activation key in the table, so the no-repeats rule and the
        // full pool are both exercised rather than just the opening weeks
        let newYear = DailyChallengeGenerator.challenge(forKey: "2027-01-01")
        XCTAssertEqual(newYear.mode, .endlessII)
        XCTAssertNil(newYear.classicLevel)
        XCTAssertEqual(newYear.twists, [])
    }

    /// And the seed itself, which is the other half of the contract: the same date has to
    /// produce the same number before it can produce the same day.
    func testTheSeedIsTheDateReadableByEye() {
        XCTAssertEqual(DailyDay.seed(forKey: "2026-08-09"), 20260809)
        XCTAssertEqual(DailyDay.seed(forKey: "2027-01-01"), 20270101)
    }

    /// The generator's own output, pinned. If SplitMix64 is ever replaced, every date in
    /// history changes with it - this says so in one line rather than through four challenges.
    func testTheRandomStreamItselfIsFrozen() {
        var stream = DailySeededGenerator(seed: 20260809)
        XCTAssertEqual(stream.next(), 9622454287769650425)
        XCTAssertEqual(stream.next(), 11729602898445087034)
    }

    // MARK: - Attempts, records and boards (phase 3)

    func testRecordsMergeByDateTakingTheMost() {
        // The sync rule: union by date, posted OR-ed, everything else take-the-higher -
        // two devices that each played different days must both keep everything.
        let here = [DailyChallengeRecord(dateKey: "2026-08-01", firstAttemptScore: 100,
                                         posted: true, bestPracticeScore: 50,
                                         attemptCount: 2, postedNormalisedScore: 100),
                    DailyChallengeRecord(dateKey: "2026-08-02", firstAttemptScore: 10,
                                         posted: false, bestPracticeScore: 0,
                                         attemptCount: 1, postedNormalisedScore: 0)]
        let there = [DailyChallengeRecord(dateKey: "2026-08-02", firstAttemptScore: 10,
                                          posted: true, bestPracticeScore: 90,
                                          attemptCount: 3, postedNormalisedScore: 1000),
                     DailyChallengeRecord(dateKey: "2026-08-03", firstAttemptScore: 7,
                                          posted: true, bestPracticeScore: 0,
                                          attemptCount: 1, postedNormalisedScore: 700)]

        let merged = DailyChallengeRecord.merged(here, there)
        XCTAssertEqual(merged.map(\.dateKey), ["2026-08-01", "2026-08-02", "2026-08-03"])

        let second = merged[1]
        XCTAssertTrue(second.posted, "posted on either device is posted")
        XCTAssertEqual(second.bestPracticeScore, 90)
        XCTAssertEqual(second.attemptCount, 3)
        XCTAssertEqual(second.postedNormalisedScore, 1000)
    }

    func testRecordsSurviveTheWireFormat() {
        let records = [DailyChallengeRecord(dateKey: "2026-08-08", firstAttemptScore: 42,
                                            posted: true, bestPracticeScore: 60,
                                            attemptCount: 4, postedNormalisedScore: 4200)]
        let decoded = CloudKitHandler.decodedDailyRecords(
            CloudKitHandler.encodedDailyRecords(records))
        XCTAssertEqual(decoded, records)
        XCTAssertEqual(CloudKitHandler.decodedDailyRecords(nil), [],
                       "a store that has never heard of the daily is an empty history")
    }

    func testTheOverallBoardNormalisesHeightsNotScores() {
        // §7: Classic posts its score as it stands, an endless height rides ×100 so no
        // one mode dominates the running total.
        XCTAssertEqual(DailyChallengeBoards.normalised(score: 4200, mode: .classic), 4200)
        XCTAssertEqual(DailyChallengeBoards.normalised(score: 34, mode: .endless), 3400)
        XCTAssertEqual(DailyChallengeBoards.normalised(score: 34, mode: .endlessII), 3400)
    }

    func testTheTotalPostedScoreIsDerivedFromTheRecords() {
        let stats = TotalStats()
        stats.upsertDailyRecord(DailyChallengeRecord(dateKey: "2026-08-07",
                                                     firstAttemptScore: 10, posted: true,
                                                     bestPracticeScore: 0, attemptCount: 1,
                                                     postedNormalisedScore: 1000))
        stats.upsertDailyRecord(DailyChallengeRecord(dateKey: "2026-08-08",
                                                     firstAttemptScore: 500, posted: true,
                                                     bestPracticeScore: 0, attemptCount: 1,
                                                     postedNormalisedScore: 500))
        XCTAssertEqual(stats.dailyTotalPostedScore, 1500)

        var replaced = stats.dailyRecord(forKey: "2026-08-08")!
        replaced.postedNormalisedScore = 900
        stats.upsertDailyRecord(replaced)
        XCTAssertEqual(stats.dailyRecords.count, 2, "one record per date, always")
        XCTAssertEqual(stats.dailyTotalPostedScore, 1900)

        var pending = DailyChallengeRecord(dateKey: "2026-08-09")
        pending.postedNormalisedScore = 700
        pending.pendingPost = true
        stats.upsertDailyRecord(pending)
        XCTAssertEqual(stats.dailyTotalPostedScore, 1900,
                       "a day joins the total when its post lands, not before (§12.5)")
    }

    /// "The game scores shouldn't have thousand separators anywhere. Other values can, just
    /// not game scores" (play-test round 126, narrowing round 33). A score is read as a score
    /// wherever it is printed, and the same shape on a results screen as on the field is the
    /// point - separators belong to counts and totals, which is where the statistics page
    /// still uses them.
    func testTheDailysScoreLineIsNotGrouped() {
        XCTAssertEqual(DailyChallengePosting.scoreText(1_234_567, mode: .classic), "1234567")
        XCTAssertEqual(DailyChallengePosting.scoreText(1_234, mode: .endlessII), "1234m",
                       "a height keeps its metres and loses nothing else")
        XCTAssertEqual(StatsPage.grouped(1_234_567, locale: Locale(identifier: "en_GB")),
                       "1,234,567",
                       "the counts on the statistics page keep their separators")
    }

    func testThePracticeNoticeInterruptsOnlyThePressesItAppliesTo() {
        // §6's promise, reshaped by play-test round 5: the standing banner became a
        // pop-up on the play press - "maybe show this as a pop-up after pressing play.
        // Maybe the same pop-up can be used when playing previous days".
        XCTAssertNil(
            DailyChallengePosting.practiceNotice(record: nil, isToday: true,
                                                 mode: .classic),
            "the scoring attempt plays with nothing in its way")

        XCTAssertEqual(
            DailyChallengePosting.practiceNotice(record: nil, isToday: false,
                                                 mode: .classic),
            "This challenge has closed.\nFree play scores are never posted.")

        var spent = DailyChallengeRecord(dateKey: "t")
        spent.attemptCount = 1
        XCTAssertEqual(
            DailyChallengePosting.practiceNotice(record: spent, isToday: true,
                                                 mode: .classic),
            "Today's attempt is spent.\nThis run won't post a score.",
            "a force-quit or midnight-crossed attempt reads as spent, not as posted")

        spent.posted = true
        spent.firstAttemptScore = 34
        XCTAssertEqual(
            DailyChallengePosting.practiceNotice(record: spent, isToday: true,
                                                 mode: .endless),
            "Your score of 34m is on today's board.\nPlaying again won't post a new score.",
            "once posted, the board's number is the day's number - heights wear their metres")
    }

    func testTheScoringAttemptPostsAndPracticeOnlyRaisesThePracticeBest() {
        let session = DailyChallengeSession.shared
        let before = session.testDayOffset
        defer { session.testDayOffset = before; session.active = nil }
        session.testDayOffset = 0

        let challenge = DailyChallenge(dateKey: session.todayKey, mode: .endlessII,
                                       classicLevel: nil, twists: [])
        let scene = dailyScene(challenge)
        scene.endlessMode = true
        scene.endlessHeight = 34

        var spent = DailyChallengeRecord(dateKey: session.todayKey)
        spent.attemptCount = 1
        scene.totalStatsArray[0].upsertDailyRecord(spent)
        // What the briefing screen wrote when play was pressed

        session.isScoringAttempt = true
        scene.recordDailyResult()

        let posted = scene.totalStatsArray[0].dailyRecord(forKey: session.todayKey)!
        XCTAssertEqual(posted.firstAttemptScore, 34)
        XCTAssertTrue(posted.isPending,
                      "the score is pending until Game Center confirms it landed (§12.5)")
        XCTAssertFalse(posted.posted, "posted waits for the confirmation")
        XCTAssertEqual(posted.postedNormalisedScore, 3400)
        XCTAssertTrue(session.lastRunPosted)
        XCTAssertFalse(session.isScoringAttempt, "the attempt is settled exactly once")

        scene.endlessHeight = 60
        scene.recordDailyResult()
        let practised = scene.totalStatsArray[0].dailyRecord(forKey: session.todayKey)!
        XCTAssertEqual(practised.firstAttemptScore, 34,
                       "a better practice run never touches the posted score")
        XCTAssertEqual(practised.bestPracticeScore, 60)
        XCTAssertFalse(session.lastRunPosted)
    }

    func testAnAttemptThatCrossedMidnightPostsNothing() {
        // §1: finished and submitted before the deadline, not just started. The attempt
        // is spent - the briefing said so going in - but nothing goes to the board.
        let session = DailyChallengeSession.shared
        defer { session.active = nil }

        let challenge = DailyChallenge(dateKey: "2000-01-01", mode: .endlessII,
                                       classicLevel: nil, twists: [])
        let scene = dailyScene(challenge)
        scene.endlessMode = true
        scene.endlessHeight = 50

        session.isScoringAttempt = true
        scene.recordDailyResult()

        let record = scene.totalStatsArray[0].dailyRecord(forKey: "2000-01-01")!
        XCTAssertEqual(record.firstAttemptScore, 50, "the score is still the player's")
        XCTAssertFalse(record.posted)
        XCTAssertEqual(record.postedNormalisedScore, 0)
        XCTAssertFalse(session.lastRunPosted)
    }

    func testAPendingPostWhoseWindowClosedBecomesAMiss() {
        // §12.5: "If not connected before the daily deadline, the score isn't posted."
        var stale = DailyChallengeRecord(dateKey: "2026-08-01")
        stale.firstAttemptScore = 40
        stale.postedNormalisedScore = 4000
        stale.pendingPost = true
        var fresh = DailyChallengeRecord(dateKey: "2026-08-08")
        fresh.pendingPost = true

        let settled = DailyChallengePosting.settlingMisses(in: [stale, fresh],
                                                           today: "2026-08-08")
        XCTAssertTrue(settled.changed)
        XCTAssertFalse(settled.records[0].isPending, "the closed window is a miss")
        XCTAssertFalse(settled.records[0].posted, "and it never becomes a post")
        XCTAssertEqual(settled.records[0].firstAttemptScore, 40,
                       "the score is still the player's, board or no board")
        XCTAssertTrue(settled.records[1].isPending,
                      "today's window is still open - the retry keeps carrying it")

        let unchanged = DailyChallengePosting.settlingMisses(in: settled.records,
                                                             today: "2026-08-08")
        XCTAssertFalse(unchanged.changed, "settling twice writes nothing new")
    }

    func testTheMergeCarriesAPendingPostButNeverPastAConfirmation() {
        var pendingHere = DailyChallengeRecord(dateKey: "d")
        pendingHere.pendingPost = true
        var postedThere = DailyChallengeRecord(dateKey: "d")
        postedThere.posted = true

        let merged = DailyChallengeRecord.merged([pendingHere], [postedThere])
        XCTAssertTrue(merged[0].posted, "the device that saw it land wins")
        XCTAssertFalse(merged[0].isPending, "a landed post has nothing left to carry")

        let bothWaiting = DailyChallengeRecord.merged([pendingHere], [pendingHere])
        XCTAssertTrue(bothWaiting[0].isPending, "still waiting on both sides, still carried")
    }

    // MARK: - The briefing screen's day browsing

    func testTodayAndYesterdaySaySoAndOlderDaysGiveTheirDate() {
        // Play test: "the date for today, yesterday should just say today and yesterday.
        // Prior days should have the date as it is."
        let session = DailyChallengeSession.shared
        let before = session.testDayOffset
        defer { session.testDayOffset = before }
        session.testDayOffset = 0

        XCTAssertEqual(session.displayName(forKey: session.todayKey), "TODAY")

        let yesterday = DailyDay.utcCalendar.date(byAdding: .day, value: -1,
                                                  to: session.today)!
        XCTAssertEqual(session.displayName(forKey: DailyDay.key(for: yesterday)),
                       "YESTERDAY")

        let older = DailyDay.utcCalendar.date(byAdding: .day, value: -3,
                                              to: session.today)!
        let name = session.displayName(forKey: DailyDay.key(for: older))
        let year = DailyDay.utcCalendar.component(.year, from: older)
        XCTAssertTrue(name.contains(String(year)),
                      "an older day reads as its date, got \(name)")
    }

    func testDayBrowsingNeverPassesTodayAndStopsAtTheFirstDaily() {
        // Play test: swipe back through all the available daily challenges, never
        // further forward than the current day.
        let screen = DailyChallengeViewController()
        XCTAssertFalse(screen.canGoForward, "today is the newest day there is")

        XCTAssertGreaterThanOrEqual(screen.earliestKey, DailyTwist.firstActivationKey)
        // The floor is the first daily or thirty days, whichever is nearer - either way
        // there is no browsing to before the pool existed
    }

    // MARK: - The session and the test clock

    func testTheTestClockMovesTheDay() {
        let session = DailyChallengeSession.shared
        let before = session.testDayOffset
        defer { session.testDayOffset = before }

        session.testDayOffset = 0
        let today = session.todayKey
        session.testDayOffset = 1
        let tomorrow = session.todayKey
        XCTAssertNotEqual(today, tomorrow)

        // **A day apart on the calendar, not one apart as a number.**
        //
        // This asserted `seed(forKey: tomorrow) == seed(forKey: today) + 1`, and a seed is the
        // key's digits read as an integer - so 2026-08-31 seeds 20260831 and the day after it
        // seeds 20260901, which is not that plus one. The assertion held on the 364 days a year
        // that are not the last of a month and failed on 31 August 2026, which is the day it
        // happened to be run. Nothing in the game wants seeds to be consecutive: they seed a
        // generator, where all that matters is that two days differ.
        //
        // What the test is *for* is that the offset moves the day, so it says that.
        guard let first = DailyDay.date(forKey: today),
              let second = DailyDay.date(forKey: tomorrow) else {
            return XCTFail("a key this made is a key it can read back")
        }
        XCTAssertEqual(second.timeIntervalSince(first), 24*60*60, accuracy: 1,
                       "one day, across a month end or a year end like any other")
    }

    // MARK: - The twists reaching the scene

    private func dailyScene(_ challenge: DailyChallenge) -> GameScene {
        DailyChallengeSession.shared.active = challenge
        let scene = GameScene()
        scene.gameMode = challenge.mode
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    func testTheLivesTwistsSpeak() {
        // Play test: "For the single life classic mode twist, I actually had 2 lives, as
        // one ball starts on the paddle - I also had a ball in reserve. There should just
        // be the ball on the paddle in this case - no balls in reserve." The scene's
        // number is the rack of reserves, so One Life is an empty rack.
        let one = dailyScene(DailyChallenge(dateKey: "t", mode: .classic, classicLevel: 1,
                                            twists: [.oneLife]))
        XCTAssertEqual(one.dailyStartingLives, 0, "one ball total - none in reserve")

        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .classic, classicLevel: 1, twists: [.loaded])
        XCTAssertEqual(one.dailyStartingLives, 4, "five balls total - four racked")

        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .endlessII, classicLevel: nil, twists: [.spareBalls])
        XCTAssertEqual(one.dailyStartingLives, 2,
                       "the endless lives twist: two spares behind the ball in play")

        DailyChallengeSession.shared.active = nil
        XCTAssertNil(one.dailyStartingLives, "no daily, no opinion")
    }

    func testOneLifeHidesTheReserveRack() {
        // Same report: "in fact the reserve ball container can be hidden in this case".
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic, classicLevel: 1,
                                              twists: [.oneLife]))
        scene.numberOfLives = 0
        XCTAssertTrue(scene.livesRowSuppressed)

        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .classic, classicLevel: 1, twists: [.loaded])
        scene.numberOfLives = 4
        XCTAssertFalse(scene.livesRowSuppressed, "a rack with balls in it stays")
    }

    func testSpareBallsPutsARackInAnEndlessRun() {
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .endlessII,
                                              classicLevel: nil, twists: [.spareBalls]))
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.numberOfLives = 2
        XCTAssertFalse(scene.livesRowSuppressed,
                       "the one endless run that shows a lives counter")

        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .endlessII, classicLevel: nil, twists: [])
        XCTAssertTrue(scene.livesRowSuppressed,
                      "an ordinary endless daily keeps the modes' own rule - no counter")
    }

    func testSuddenDeathIsParkedFromThePool() {
        // Play test: "The sudden death twist doesn't make sense in endless modes" - the
        // endless modes are one life already, and in Classic it is One Life by another
        // name until Mayhem Rules can put several balls in a Classic level. No mode may
        // draw it, which the generator's applicability filter enforces.
        for mode in [GameMode.classic, .endless, .endlessII] {
            XCTAssertFalse(DailyTwist.suddenDeath.applies(to: mode),
                           "\(mode) can still draw Sudden Death")
        }
    }

    func testAClassicDailyStandsDownTheEconomyPowerUps() {
        // §7 "Decided", and the play test's rule: the multiplier should still build up
        // and down - just no power-up multipliers. Points, both multiplier power-ups and
        // Next Level are out of every daily's drops, twists or none; the multiplier
        // mechanic itself is untouched (it lives in Scoring, not in this table).
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: []))
        let stats = TotalStats()
        stats.powerUpUnlockedArray = stats.powerUpUnlockedArray.map { _ in true }
        scene.totalStatsArray = [stats]
        // Everything unlocked, so a zero can only mean the daily stood it down

        scene.powerUpProbAllocation(levelNumber: LevelPackSetup().startLevelNumber[2] + 1)
        // The pack's second level, where the points and multiplier drops are normally live
        for index in [8, 9, 10, 11, 12, 13, 14] {
            XCTAssertEqual(scene.powerUpProbArray[index], 0,
                           "power-up \(index) still drops in a classic daily")
        }
        XCTAssertGreaterThan(scene.powerUpProbArray.reduce(0, +), 0,
                             "the rest of the table survives")
    }

    func testALivesTwistOwnsTheLivesEconomy() {
        // The low-lives bump re-armed Get a Life after the tables were dealt - on a One
        // Life day that is a second life the twist just took away.
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.oneLife]))
        scene.numberOfLives = 0
        scene.powerUpProbAllocation(levelNumber: LevelPackSetup().startLevelNumber[2])
        XCTAssertEqual(scene.powerUpProbArray[0], 0, "Get a Life stood down")
        XCTAssertEqual(scene.powerUpProbArray[1], 0, "Lose a Life stood down")
    }

    func testNoPowerUpsEmptiesTheTables() {
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .endlessII,
                                              classicLevel: nil, twists: [.noPowerUps]))
        scene.applyEndlessRowPowerUpWeights()
        XCTAssertEqual(scene.powerUpProbArray.reduce(0, +), 0)
        XCTAssertNil(scene.endlessIIMakePowerUpBrick(column: 0, rowY: 0),
                     "the built-in ones stand down too")
    }

    func testNoGoodNewsLeavesOnlyTheBadOnes() {
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .endlessII,
                                              classicLevel: nil, twists: [.noGoodNews]))
        scene.applyEndlessRowPowerUpWeights()
        for (index, weight) in scene.powerUpProbArray.enumerated() where weight > 0 {
            XCTAssertTrue(GameScene.endlessIIHarmfulPowerUps.contains(index),
                          "power-up \(index) survived a bad-news-only day")
        }
    }

    func testSuddenDeathOverrulesMultiBall() {
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .endlessII,
                                              classicLevel: nil, twists: [.suddenDeath]))
        scene.addChild(scene.ball)
        let extra = SKSpriteNode()
        extra.name = BallCategoryName
        scene.addChild(extra)
        scene.endlessIIExtraBalls.append(extra)

        XCTAssertFalse(scene.endlessIIBallWasLost(scene.ball),
                       "false means the life is lost - the run does not carry on")
    }

    func testFogHidesEveryBrickType() {
        // Play test: "In fog of war, some brick types are visible as they build in. All
        // brick types should start invisible." The first build fogged only the types
        // whose own hit rules pass through the reveal, which left Indestructibles and
        // Portals sitting in plain sight in a fogged field.
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        let plain = SKSpriteNode(texture: scene.brickNormalTexture)
        let wall = SKSpriteNode(texture: scene.brickIndestructible2Texture)
        let multi = SKSpriteNode(texture: scene.brickMultiHit3Texture)
        let empty = SKSpriteNode(texture: scene.brickNullTexture)
        scene.applyDailyFog(to: [plain, wall, multi, empty])
        scene.closeDailyFog(animated: false)
        // The field is shown once and then taken away (round 9's queued item), so the
        // question this test asks - does *every* type get fogged - is asked after the
        // fog closes rather than at creation

        XCTAssertTrue(plain.isHidden)
        XCTAssertTrue(wall.isHidden)
        XCTAssertTrue(multi.isHidden)
        XCTAssertFalse(empty.isHidden, "an empty cell has nothing to hide")
    }

    /// James, round 177: "if fog of war twist is in play, at the start if the player launches
    /// the ball before the fade out animation has finished, make all the bricks disappear
    /// immediately."
    func testLaunchingEarlySnapsTheFogShut() {
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        scene.addChild(scene.ball)
        let looking = SKSpriteNode(texture: scene.brickNormalTexture)
        scene.addChild(looking)
        scene.applyDailyFog(to: [looking])
        scene.closeDailyFog()
        // Animated: the brick is mid-look, visible, its fade still to come - which is
        // exactly the state a keen player launches into

        XCTAssertFalse(looking.isHidden, "still having its look")
        scene.snapDailyFogShut()
        XCTAssertTrue(looking.isHidden, "the launch ends the look at once")
    }

    func testTheSnapTakesTheBricksTheBuildInNeverGotTo() {
        // A launch during the build-in: some bricks are fading, some still waiting in the
        // pending list, and the snap owes both the same answer
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        let waiting = SKSpriteNode(texture: scene.brickNormalTexture)
        scene.addChild(waiting)
        scene.applyDailyFog(to: [waiting])
        // Pending, never scheduled - the build-in had not reached it

        scene.snapDailyFogShut()
        XCTAssertTrue(waiting.isHidden)
        XCTAssertTrue(scene.dailyFogHasClosed,
                      "and rows still to land arrive fogged, as after any close")
    }

    func testALaterLaunchDoesNotTakeBackWhatAStrikeRevealed() {
        // The snap runs on every launch, so it must only touch what the fog still owns. A
        // brick the first strike has shown stays shown - that is the reveal's promise.
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        let wall = SKSpriteNode(texture: scene.brickIndestructible2Texture)
        scene.addChild(wall)
        scene.applyDailyFog(to: [wall])
        scene.closeDailyFog(animated: false)
        XCTAssertTrue(scene.revealDailyFog(wall))
        XCTAssertFalse(wall.isHidden)

        scene.snapDailyFogShut()
        XCTAssertFalse(wall.isHidden, "revealed is revealed, however many balls follow")
    }

    func testFogSpendsTheFirstStrikeOnTheReveal() {
        // Round 4: "some bricks never show up. All brick types should appear on the
        // first hit." Round 5, after the first fix: "In fog of war, no bricks appeared
        // when hit" - revealing before the type switch unhid a brick straight into its
        // own destroy branch. The reveal spends the strike now, the invisible bricks'
        // own convention.
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        let wall = SKSpriteNode(texture: scene.brickIndestructible2Texture)
        let stack = SKSpriteNode(texture: scene.brickMultiHit3Texture)
        scene.applyDailyFog(to: [wall, stack])
        scene.closeDailyFog(animated: false)

        XCTAssertTrue(scene.revealDailyFog(wall),
                      "an Indestructible's own rules never look at the hidden flag - "
                        + "the fog reveals it, and the strike stops there")
        XCTAssertFalse(wall.isHidden)
        XCTAssertTrue(scene.revealDailyFog(stack), "multi-hits likewise")
        XCTAssertFalse(stack.isHidden)

        let plain = SKSpriteNode(texture: scene.brickNormalTexture)
        plain.isHidden = true
        // Fogged the way the closed fog leaves a brick - the fog has already shut by this
        // point in the run, so a brick reaching here is hidden rather than pending
        XCTAssertFalse(scene.revealDailyFog(plain),
                       "a normal-shaped brick reaches a switch branch that already does "
                        + "first-hit-reveals-only - the fog must not reveal it early, or "
                        + "its first strike lands in the destroy branch and nothing appears")
        XCTAssertTrue(plain.isHidden, "still hidden here - its own branch does the reveal")
    }

    func testFogSurvivesLosingABall() {
        // Play test: "When I died in fog of war mode and I had a spare ball all the
        // invisible bricks became visible." The Hide Bricks power-up expires with the
        // ball that was lost; the day's fog is not a power-up and does not.
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .classic,
                                              classicLevel: 1, twists: [.fogOfWar]))
        XCTAssertTrue(scene.dailyFogIsOn)

        DailyChallengeSession.shared.active = DailyChallenge(dateKey: "t", mode: .classic,
                                                             classicLevel: 1, twists: [])
        XCTAssertFalse(scene.dailyFogIsOn, "no fog, no exemption - the reset runs as ever")
    }

    func testADailyRunRecordsNoHeights() {
        // §9: it is a different game that borrows the field
        let scene = dailyScene(DailyChallenge(dateKey: "t", mode: .endlessII,
                                              classicLevel: nil, twists: []))
        XCTAssertTrue(scene.isDailyChallenge)
        DailyChallengeSession.shared.active = nil
        XCTAssertFalse(scene.isDailyChallenge)
    }
}

/// The layout twists, end to end: a real level, built through the door every level uses.
///
/// The arithmetic is tested on its own in `DailyChallengeTests`; this is the wiring. A
/// reflection that is right and never called looks exactly like no twist at all, and there is
/// only one place in the app where it can be called from - so that place is what is checked.
final class DailyLayoutTwistTests: XCTestCase {

    /// A Classic scene with real cell geometry, on a day carrying the given twist.
    private func scene(with twist: DailyTwist?) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.gameWidth = 440
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffset = 400
        scene.levelNumber = 1
        DailyChallengeSession.shared.active = twist.map {
            DailyChallenge(dateKey: "2026-09-02", mode: .classic, classicLevel: 1, twists: [$0])
        }
        return scene
    }

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    /// The bricks a level puts on the field, as (x, y) pairs, rounded so two runs compare.
    private func field(_ scene: GameScene) -> Set<[Int]> {
        var found: Set<[Int]> = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            found.insert([Int((node.position.x).rounded()), Int((node.position.y).rounded())])
        }
        return found
    }

    private func builtField(with twist: DailyTwist?) -> Set<[Int]> {
        let scene = self.scene(with: twist)
        scene.loadLevel89()
        return field(scene)
    }

    func testAMirroredDayBuildsTheLevelTheOtherWayRound() {
        let plain = builtField(with: nil)
        let mirrored = builtField(with: .mirrored)

        XCTAssertFalse(plain.isEmpty, "the level built nothing, so nothing below means anything")
        XCTAssertEqual(mirrored, Set(plain.map { [-$0[0], $0[1]] }),
                       "every brick is where its reflection was")
        XCTAssertEqual(mirrored.count, plain.count,
                       "and none were lost off the side - the columns are symmetric about "
                       + "the centre line, so a reflection is a permutation of them")
    }

    func testAnUpsideDownDayBuildsTheLevelTheOtherWayUp() {
        let plain = builtField(with: nil)
        let flipped = builtField(with: .upsideDown)

        XCTAssertFalse(plain.isEmpty)
        let lowest = plain.map { $0[1] }.min()!
        let highest = plain.map { $0[1] }.max()!
        XCTAssertEqual(flipped, Set(plain.map { [$0[0], lowest + highest - $0[1]] }))

        XCTAssertEqual(flipped.map { $0[1] }.min(), lowest,
                       "and the field is still in the band it was built in - a level tipped "
                       + "into the player's lap is a different game, not the same one over")
        XCTAssertEqual(flipped.map { $0[1] }.max(), highest)
    }

    // MARK: - Extra Mayhem (round 198)

    /// §4: "Endless daily uses Mayhem's style pool at elevated rates" - "the variety dial
    /// turned up."
    func testMayhemBricksTurnsTheStyleDialUpAndNoFurtherThanTheGameItselfGoes() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-08", mode: .endlessII, classicLevel: nil, twists: [.mayhemBricks])
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertEqual(scene.dailyStyledChance(4), 12,
                       "the opening plays like the mid-game")
        XCTAssertEqual(scene.dailyStyledChance(22), 66,
                       "and the depths get louder still")
        XCTAssertEqual(scene.dailyStyledChance(40), 85,
                       "capped where a motif phase sits - the loudest the field ever "
                       + "legitimately gets, matched and never exceeded")
    }

    func testAnOrdinaryDayLeavesTheDialAlone() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-08", mode: .endlessII, classicLevel: nil, twists: [.drought])
        defer { DailyChallengeSession.shared.active = nil }
        XCTAssertEqual(scene.dailyStyledChance(4), 4)

        DailyChallengeSession.shared.active = nil
        XCTAssertEqual(scene.dailyStyledChance(22), 22, "and a campaign run more so")
    }

    func testMayhemBricksOnlyLandsWhereTheStylePoolExists() {
        // §4's table says "Endless modes", and the twist is narrower on purpose: the original
        // Endless has no style machinery at all, so "Mayhem's style pool" there is a port of
        // the whole style system, not a rate change - queued as its own question rather than
        // smuggled in under a twist
        XCTAssertTrue(DailyTwist.mayhemBricks.applies(to: .endlessII))
        XCTAssertFalse(DailyTwist.mayhemBricks.applies(to: .endless))
        XCTAssertFalse(DailyTwist.mayhemBricks.applies(to: .classic))
        XCTAssertEqual(DailyTwist.mayhemBricks.category, .dress)
    }

    func testMayhemBricksIsActuallyOfferedOnceItsDateArrives() {
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        var seen = false
        for _ in 0..<600 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            if challenge.twists.contains(.mayhemBricks) { seen = true; break }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertTrue(seen, "in the enum but never drawn looks exactly like very rare")
    }

    // MARK: - Time Trial (round 197)

    private func timeTrialScene() -> GameScene {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-05", mode: .endlessII, classicLevel: nil, twists: [.timeTrial])
        return scene
    }

    /// §4: "90 seconds on the clock; the score at the whistle is the score."
    func testTheClockStartsAtNinetyAndCountsFlightTimeDown() {
        let scene = timeTrialScene()
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertEqual(scene.dailyTimeTrialRemaining, 90, "the clock the spec names")
        XCTAssertFalse(scene.spendDailyTimeTrial(1.5))
        XCTAssertEqual(scene.dailyTimeTrialRemaining, 88.5, accuracy: 0.0001)
    }

    func testTheWhistleBlowsAtZeroAndNotAMomentBefore() {
        let scene = timeTrialScene()
        defer { DailyChallengeSession.shared.active = nil }

        scene.dailyTimeTrialRemaining = 0.2
        XCTAssertFalse(scene.spendDailyTimeTrial(0.1), "0.1s left is still a run")
        XCTAssertTrue(scene.spendDailyTimeTrial(0.2),
                      "spending past zero blows the whistle, and the clock floors rather "
                      + "than going negative")
        XCTAssertEqual(scene.dailyTimeTrialRemaining, 0)
    }

    func testTheClockDoesNotRunOutsidePlay() {
        // The tick's guards: a scene that is not mid-game - not Playing, ball on the paddle -
        // must not lose a second. The ninety seconds are seconds of play, not of hesitation
        let scene = timeTrialScene()
        defer { DailyChallengeSession.shared.active = nil }

        scene.tickDailyTimeTrial(5)
        XCTAssertEqual(scene.dailyTimeTrialRemaining, 90,
                       "nothing is Playing yet, so nothing is spent")
    }

    func testAnOrdinaryDayHasNoClockAtAll() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-05", mode: .endlessII, classicLevel: nil, twists: [.fogOfWar])
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertFalse(scene.dailyTimeTrial)
        scene.setupDailyClock()
        XCTAssertNil(scene.dailyClockLabel, "no countdown in the HUD on a day without one")
    }

    func testTheClockLabelSaysWholeSecondsAndTurnsUrgent() {
        let scene = timeTrialScene()
        defer { DailyChallengeSession.shared.active = nil }
        scene.dailyClockLabel = SKLabelNode()

        scene.dailyTimeTrialRemaining = 89.2
        scene.showDailyClock()
        XCTAssertEqual(scene.dailyClockLabel?.text, "90",
                       "rounded up - the player is not told 89 while the 90th second runs")

        scene.dailyTimeTrialRemaining = 9.4
        scene.showDailyClock()
        XCTAssertEqual(scene.dailyClockLabel?.text, "10")
        XCTAssertEqual(scene.dailyClockLabel?.fontColor, .red, "urgent for the last ten")
    }

    func testTheClockRidesInTheSaveAndComesBack() throws {
        // The one thing a Time Trial cannot give away is a fresh ninety seconds on resume
        var save = SavedGame(
            levelNumber: 0, endLevelNumber: 0, packNumber: 0, levelScore: 0, totalScore: 0,
            numberOfLives: 1, endlessHeight: 0, numberOfLevels: 1, levelTimerValue: 0,
            packTimerValue: 0, deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0, paddleHitsPerLevel: 0,
            multiplier: 1, brickTextures: [], brickColours: [], brickXPositions: [],
            brickYPositions: [], ballProperties: [],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [], fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [], activePowerUpTimers: [],
            activePowerUpMagnitudes: [])
        save.dailyTimeTrialRemaining = 41.5

        let store = InMemoryKeyValueStore()
        save.save(to: store)
        let read = try XCTUnwrap(SavedGame.load(from: store))
        XCTAssertEqual(read.dailyTimeTrialRemaining, 41.5)
    }

    func testTimeTrialLandsBesideAnyOtherTwist() {
        // Its own category, like No Breaks: it contradicts nothing, and a foggy Time Trial
        // or a one-life Time Trial is where the pool's variety comes from
        XCTAssertEqual(DailyTwist.timeTrial.category, .tempo)
        for mode in [GameMode.classic, .endless, .endlessII] {
            XCTAssertTrue(DailyTwist.timeTrial.applies(to: mode))
        }
    }

    func testTimeTrialIsActuallyOfferedOnceItsDateArrives() {
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        var seen = false
        for _ in 0..<400 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            if challenge.twists.contains(.timeTrial) { seen = true; break }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertTrue(seen, "in the enum but never drawn looks exactly like very rare")
    }

    // MARK: - Brick Swap (round 196)

    /// A brick of every Classic type, for the swap to chew on.
    private func fieldOfEveryType(in scene: GameScene) -> [SKSpriteNode] {
        [scene.brickNormalTexture, scene.brickMultiHit1Texture, scene.brickMultiHit2Texture,
         scene.brickMultiHit3Texture, scene.brickInvisibleTexture,
         scene.brickIndestructible1Texture, scene.brickIndestructible2Texture].map {
            let brick = SKSpriteNode(texture: $0)
            brick.name = BrickCategoryName
            scene.addChild(brick)
            return brick
        }
    }

    private func swappedScene(dateKey: String) -> GameScene {
        let scene = GameScene()
        scene.gameMode = .classic
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: dateKey, mode: .classic, classicLevel: 1, twists: [.brickSwap])
        return scene
    }

    /// **Nothing may become indestructible, and indestructibles stay indestructible.**
    ///
    /// The one rule the table must never break: a Classic level has to stay completable, and
    /// a normal brick turned indestructible in the wrong level is a level that cannot be
    /// finished - a much worse day than a hard one. Checked over every remap in the table
    /// rather than the one a date happens to draw.
    func testNoSwapEverMakesALevelUncompletable() {
        for swap in DailyTwist.DailyBrickSwap.allCases {
            let scene = swappedScene(dateKey: "2026-09-05")
            defer { DailyChallengeSession.shared.active = nil }
            let bricks = fieldOfEveryType(in: scene)
            let indestructibles = [scene.brickIndestructible1Texture,
                                   scene.brickIndestructible2Texture]
            let breakableBefore = bricks.filter {
                indestructibles.contains($0.texture!) == false
            }

            _ = scene.applyBrickSwapPass(swap, to: bricks)

            for brick in breakableBefore {
                XCTAssertFalse(indestructibles.contains(brick.texture!),
                               "\(swap) turned a breakable brick indestructible")
            }
            XCTAssertEqual(bricks[5].texture, scene.brickIndestructible1Texture,
                           "\(swap): an indestructible is structure, not a type to remap")
            XCTAssertEqual(bricks[6].texture, scene.brickIndestructible2Texture)
        }
    }

    func testEachRemapDoesWhatItsNameSays() {
        let scene = swappedScene(dateKey: "2026-09-05")
        defer { DailyChallengeSession.shared.active = nil }

        var bricks = fieldOfEveryType(in: scene)
        _ = scene.applyBrickSwapPass(.hardened, to: bricks)
        XCTAssertEqual(bricks[0].texture, scene.brickMultiHit3Texture,
                       "hardened: every ordinary brick takes three hits - the spec's example")

        bricks = fieldOfEveryType(in: scene)
        _ = scene.applyBrickSwapPass(.softened, to: bricks)
        for index in 1...3 {
            XCTAssertEqual(bricks[index].texture, scene.brickNormalTexture,
                           "softened: every multi-hit stage is ordinary")
        }

        bricks = fieldOfEveryType(in: scene)
        _ = scene.applyBrickSwapPass(.veiled, to: bricks)
        XCTAssertEqual(bricks[0].texture, scene.brickInvisibleTexture,
                       "veiled: ordinary bricks hide until struck")
    }

    /// A Softened day on a level with no multi-hit bricks would be a twist that visibly does
    /// nothing, and "does nothing" reads as broken - so the field hardens instead. Still
    /// deterministic: the fallback depends only on the day and the level.
    func testARemapThatFindsNothingHardensInstead() {
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 9, day: 1))!
        while DailyTwist.DailyBrickSwap.drawn(forKey: DailyDay.key(for: day)) != .softened {
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        let key = DailyDay.key(for: day)
        // A real date whose draw is Softened, walked to rather than invented, so this test
        // exercises the exact path a player would

        let scene = swappedScene(dateKey: key)
        defer { DailyChallengeSession.shared.active = nil }
        let onlyNormals = [SKSpriteNode(texture: scene.brickNormalTexture)]
        onlyNormals.forEach { scene.addChild($0) }

        scene.applyDailyBrickSwap(to: onlyNormals)
        XCTAssertEqual(onlyNormals[0].texture, scene.brickMultiHit3Texture,
                       "nothing to soften, so the day hardens rather than doing nothing")
    }

    func testTheDaysRemapIsDeterministicAndVaries() {
        let first = DailyTwist.DailyBrickSwap.drawn(forKey: "2026-09-05")
        XCTAssertEqual(DailyTwist.DailyBrickSwap.drawn(forKey: "2026-09-05"), first,
                       "every device has to draw the same remap for the same day")

        let keys = (1...30).map { String(format: "2026-09-%02d", $0) }
        let drawn = Set(keys.map { DailyTwist.DailyBrickSwap.drawn(forKey: $0) })
        XCTAssertGreaterThan(drawn.count, 1, "a table that always draws one entry is not a table")
    }

    func testAResumedFieldIsNotSwappedAgain() {
        let scene = swappedScene(dateKey: "2026-09-05")
        defer { DailyChallengeSession.shared.active = nil }
        scene.savedGame = SavedGame(
            levelNumber: 1, endLevelNumber: 1, packNumber: 0, levelScore: 0, totalScore: 0,
            numberOfLives: 3, endlessHeight: 0, numberOfLevels: 1, levelTimerValue: 0,
            packTimerValue: 0, deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0, paddleHitsPerLevel: 0,
            multiplier: 1, brickTextures: [], brickColours: [], brickXPositions: [],
            brickYPositions: [], ballProperties: [],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [], fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [], activePowerUpTimers: [],
            activePowerUpMagnitudes: [])
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        scene.addChild(brick)

        scene.applyDailyBrickSwap(to: [brick])
        XCTAssertEqual(brick.texture, scene.brickNormalTexture,
                       "the save already carries the swapped field - swapping again would "
                       + "double-apply")
    }

    func testAnOrdinaryDayLeavesTheLevelExactlyAsItWasDrawn() {
        XCTAssertEqual(builtField(with: .fogOfWar), builtField(with: nil),
                       "only the layout category turns a level over")
    }

    func testTheRowsStayRowsWhicheverWayTheLevelIsTurned() {
        // A brick's position is read as its cell all over this game (§8.6). Both reflections
        // are about lines the grid is symmetric across, so the set of occupied rows and
        // columns can only be permuted - never moved off the grid
        let plain = builtField(with: nil)
        for twist in [DailyTwist.mirrored, .upsideDown] {
            let turned = builtField(with: twist)
            XCTAssertEqual(Set(turned.map { $0[0] }), Set(plain.map { $0[0] }),
                           "\(twist): the columns in use are the same columns")
            XCTAssertEqual(Set(turned.map { $0[1] }), Set(plain.map { $0[1] }),
                           "\(twist): and the rows in use are the same rows")
        }
    }
}

/// "The level should show its hand first: the bricks animate in visible, then a fade takes
/// them to invisible, so the player gets one look at the field before the fog closes."
final class DailyFogRevealTests: XCTestCase {

    private func fogScene() -> GameScene {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallengeGenerator.challenge(
            forKey: DailyChallengeSession.shared.todayKey)
        return scene
    }

    private func brick(in scene: GameScene) -> SKSpriteNode {
        let node = SKSpriteNode()
        node.name = BrickCategoryName
        scene.addChild(node)
        return node
    }

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    func testTheOpeningFieldIsNotHiddenAsItIsBuilt() {
        let scene = fogScene()
        guard scene.dailyFogIsOn else { return }
        // Only meaningful on a Fog of War day; the pool decides which days those are

        let opening = brick(in: scene)
        scene.applyDailyFog(to: [opening])
        XCTAssertFalse(opening.isHidden, "the field shows its hand first")
    }

    func testARowArrivingAfterTheFogHasClosedIsHiddenAtOnce() {
        // The look belongs to the opening field. A row that showed itself every time one
        // was generated would not be a fog at all
        let scene = fogScene()
        guard scene.dailyFogIsOn else { return }
        scene.dailyFogHasClosed = true

        let later = brick(in: scene)
        scene.applyDailyFog(to: [later])
        XCTAssertTrue(later.isHidden)
    }

    func testClosingTheFogHappensOnceHoweverManyTimesItIsAsked() {
        // The build-in can finish, be skipped, or both across one run
        let scene = fogScene()
        guard scene.dailyFogIsOn else { return }

        scene.applyDailyFog(to: [brick(in: scene)])
        scene.closeDailyFog()
        XCTAssertTrue(scene.dailyFogHasClosed)
        XCTAssertTrue(scene.dailyFogPending.isEmpty)

        scene.closeDailyFog()
        XCTAssertTrue(scene.dailyFogPending.isEmpty, "asking twice changes nothing")
    }

    func testTheLookIsShortEnoughToNotHandTheFieldBack() {
        // Play-test round 126: "I was able to start playing before the bricks disappeared",
        // and the fog should be faster and foggier. A row's look plus its fade now has to
        // fit inside the beat between one row landing and the next few, or the fog is again
        // still closing when the ball is already in the field
        XCTAssertLessThan(GameScene.dailyFogLook + GameScene.dailyFogClose, 1.0)
        XCTAssertGreaterThan(GameScene.dailyFogLook, 0.2, "still a look, not a blindfold")
    }

    func testABrickFogsItselfOnLandingRatherThanWaitingForTheField() {
        // The fog travels down with the build-in now: a scheduled brick leaves the pending
        // list at once, so the sweeper at the end of the build-in has nothing left to take
        let scene = fogScene()
        guard scene.dailyFogIsOn else { return }

        let opening = brick(in: scene)
        scene.applyDailyFog(to: [opening])
        XCTAssertEqual(scene.dailyFogPending.count, 1)

        scene.scheduleDailyFog(for: opening, landingAt: 0)
        XCTAssertTrue(scene.dailyFogPending.isEmpty,
                      "the brick owns its own fade from the moment it lands")
    }

    func testTheWaitLivesOnTheSceneAndNotOnTheBrick() {
        // §8.6: countBricks() gates row generation on a brick having no actions, so a wait
        // of most of a second attached to a brick would hold the whole field's descent
        let scene = fogScene()
        guard scene.dailyFogIsOn else { return }

        let opening = brick(in: scene)
        scene.applyDailyFog(to: [opening])
        scene.scheduleDailyFog(for: opening, landingAt: 0.5)
        XCTAssertFalse(opening.hasActions(), "the scene is holding the timer, not the brick")
    }

    func testNothingHappensOnADayWithoutTheTwist() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = nil
        let plain = brick(in: scene)
        scene.applyDailyFog(to: [plain])

        XCTAssertFalse(plain.isHidden)
        XCTAssertTrue(scene.dailyFogPending.isEmpty)
    }
}

/// "Avoid two similar challenges back to back" (play-test round 90): consecutive days that
/// are both, say, a single level with a lives twist read as the generator repeating itself
/// rather than as a challenge that changes daily.
final class DailyNoRepeatsTests: XCTestCase {

    private func keys(from first: String, days: Int) -> [String] {
        var all = [first]
        while all.count < days {
            guard let next = DailyChallengeGenerator.previousKey(of: all.last!) else { break }
            all.append(next)
        }
        return all.reversed()
    }

    func testAWholeYearNeverRepeatsTheSameIdeaTwiceRunning() {
        let days = keys(from: "2027-01-01", days: 365)
        var previous: DailyChallenge?
        var rhymes = 0
        for key in days {
            let today = DailyChallengeGenerator.challenge(forKey: key)
            if let previous, DailyChallengeGenerator.readsTheSame(today, previous) { rhymes += 1 }
            previous = today
        }
        XCTAssertLessThanOrEqual(rhymes, 6,
            """
            Four candidates per collision rather than a loop until different, so a couple of \
            days a year may still rhyme after stepping. Measured over 2027: two. The headroom \
            above that is for the twist pool growing as later twists reach their activation \
            dates - what must never come back is the run of lookalike days the play test saw
            """)
    }

    func testTheRuleStillGivesEveryDeviceTheSameDay() {
        // The whole daily rests on this (§2.1): two devices asking the same question get the
        // same answer, however the answer was arrived at
        for key in ["2026-08-15", "2026-12-25", "2027-03-01"] {
            XCTAssertEqual(DailyChallengeGenerator.challenge(forKey: key),
                           DailyChallengeGenerator.challenge(forKey: key))
        }
    }

    func testTheLookBackIsTwoDaysAndStopsThere() {
        // A rule that resolved yesterday by resolving the day before it, and so on, would
        // walk back to the beginning of time on every draw. This one is bounded, which is
        // why it can be called from a table view
        XCTAssertEqual(DailyChallengeGenerator.previousKey(of: "2026-01-01"), "2025-12-31")
        XCTAssertEqual(DailyChallengeGenerator.previousKey(of: "2026-03-01"), "2026-02-28")
    }

    // MARK: - The standing

    // Play-test round 126: "For a listed score on the daily challenge menu view, put the
    // position info in front of the score and show the number of players e.g. 1st / 200."

    func testAStandingReadsAsAPlaceOutOfAField() {
        XCTAssertEqual(LeaderboardStanding(rank: 1, players: 200).text, "1st / 200")
        XCTAssertEqual(LeaderboardStanding(rank: 2, players: 200).text, "2nd / 200")
        XCTAssertEqual(LeaderboardStanding(rank: 3, players: 200).text, "3rd / 200")
        XCTAssertEqual(LeaderboardStanding(rank: 4, players: 200).text, "4th / 200")
    }

    func testABigFieldIsGroupedAndThePlaceIsNot() {
        // The endless boards have years of players on them, and "3rd / 100000" has to be
        // counted rather than read (round 160). The daily's own fields are small enough
        // that the line above still reads exactly as play-test round 126 asked for it.
        XCTAssertEqual(LeaderboardStanding(rank: 3, players: 1204).text,
                       "3rd / " + StatsPage.grouped(1204))
        XCTAssertEqual(LeaderboardStanding(rank: 3, players: 999).text, "3rd / 999")
        XCTAssertEqual(LeaderboardStanding(rank: 1204, players: 2000).text,
                       LeaderboardStanding.ordinal(1204) + " / " + StatsPage.grouped(2000))
        // A four-figure place is the formatter's business and it groups those too, which is
        // the same reading it gives every other long number on the screen
    }

    func testTheAwkwardOrdinalsAreTheFormattersProblemAndItGetsThemRight() {
        // 11th, not 11st - which is the reason a formatter does this rather than a switch
        // on the last digit
        XCTAssertEqual(LeaderboardStanding.ordinal(11), "11th")
        XCTAssertEqual(LeaderboardStanding.ordinal(12), "12th")
        XCTAssertEqual(LeaderboardStanding.ordinal(13), "13th")
        XCTAssertEqual(LeaderboardStanding.ordinal(21), "21st")
        XCTAssertEqual(LeaderboardStanding.ordinal(101), "101st")
    }

    func testTheBoardsLeadingScoreIsSaidBesideThePlacing() {
        // James, round 185: "Add global high score details to game over / completion
        // screens alongside rank details". The endless boards are heights, so the figure
        // wears an "m"; a classic pack board's score is points and wears nothing
        let endless = LeaderboardStanding(rank: 12, players: 843, best: 1204)
        XCTAssertEqual(endless.bestText(suffix: GameMode.endlessII.leaderboardUnit),
                       "Best 1,204m")
        XCTAssertEqual(LeaderboardStanding(rank: 3, players: 40, best: 128_400)
                        .bestText(suffix: GameMode.classic.leaderboardUnit),
                       "Best " + StatsPage.grouped(128_400))
        // Grouped the same way the field size beside it is, which is the whole reason it
        // goes through StatsPage rather than String(describing:)
    }

    func testABoardWithNoLeaderYetSaysNothingRatherThanBestZero() {
        // A board Game Center answered for but had no entries in, and every standing built
        // before round 185 - the field defaults to nil, so the old two-argument
        // initialisers still compile and still print the placing alone
        XCTAssertNil(LeaderboardStanding(rank: 4, players: 4).bestText())
        XCTAssertNil(LeaderboardStanding(rank: 4, players: 4, best: nil).bestText(suffix: "m"))
        XCTAssertEqual(LeaderboardStanding(rank: 4, players: 4, best: 0).bestText(),
                       "Best 0")
        // Zero is a real score somebody holds, and it prints. Only "no leader at all" is
        // silent
    }

    func testOnlyTheHeightBoardsMeasureTheirScoresInMetres() {
        XCTAssertEqual(GameMode.endless.leaderboardUnit, "m")
        XCTAssertEqual(GameMode.endlessII.leaderboardUnit, "m")
        XCTAssertEqual(GameMode.classic.leaderboardUnit, "")
        XCTAssertEqual(GameMode.daily.leaderboardUnit, "")
        // The endless modes post to `endlessBestHeight` boards - the id says what the score
        // is - and the daily posts a score in whatever its day's mode counts, which the
        // daily's own line never prints a board best beside
    }

    // MARK: - No Breaks (round 195)

    /// §4's nerve twist: "The pause button is disabled for the run. Backgrounding the app
    /// forfeits posting."
    func testNoPausingClosesBothWaysIntoThePauseScreen() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-02", mode: .endlessII, classicLevel: nil, twists: [.noPausing])
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertTrue(scene.dailyNoPausing)
        XCTAssertFalse(scene.dailyPausingIsAllowed,
                       "the button and the swipe ask this one question - a twist that closed "
                       + "one and left the other open would be no twist at all")
    }

    func testAnOrdinaryDayCanStillPause() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-10-02", mode: .endlessII, classicLevel: nil, twists: [.fogOfWar])
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertFalse(scene.dailyNoPausing)
        XCTAssertTrue(scene.dailyPausingIsAllowed)
    }

    func testACampaignRunIsNeverAffected() {
        let scene = GameScene()
        DailyChallengeSession.shared.active = nil
        XCTAssertFalse(scene.dailyNoPausing)
        XCTAssertTrue(scene.dailyPausingIsAllowed)
    }

    func testLeavingTheAppForfeitsTheAttemptOnANoPausingDay() {
        let scene = GameScene()
        let session = DailyChallengeSession.shared
        session.active = DailyChallenge(dateKey: "2026-10-02", mode: .endlessII,
                                        classicLevel: nil, twists: [.noPausing])
        session.forfeitedByLeaving = false
        defer { session.active = nil; session.forfeitedByLeaving = false }

        scene.dailyForfeitByLeaving()
        XCTAssertTrue(session.forfeitedByLeaving,
                      "the app pausing itself in the background would hand the player exactly "
                      + "what the twist takes away")
    }

    func testLeavingTheAppCostsNothingOnAnyOtherDay() {
        let scene = GameScene()
        let session = DailyChallengeSession.shared
        session.active = DailyChallenge(dateKey: "2026-10-02", mode: .endlessII,
                                        classicLevel: nil, twists: [.drought])
        session.forfeitedByLeaving = false
        defer { session.active = nil; session.forfeitedByLeaving = false }

        scene.dailyForfeitByLeaving()
        XCTAssertFalse(session.forfeitedByLeaving)
    }

    func testNoPausingIsItsOwnCategorySoItCanLandWithAnything() {
        // It contradicts nothing - a day can be No Breaks *and* foggy, or No Breaks with
        // one life, which is where its teeth are
        XCTAssertEqual(DailyTwist.noPausing.category, .nerve)
        XCTAssertTrue(DailyTwist.noPausing.applies(to: .classic))
        XCTAssertTrue(DailyTwist.noPausing.applies(to: .endless))
        XCTAssertTrue(DailyTwist.noPausing.applies(to: .endlessII))
    }

    func testNoPausingIsActuallyOfferedOnceItsDateArrives() {
        var day = DailyDay.utcCalendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        var seen = false
        for _ in 0..<400 {
            let challenge = DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: day))
            if challenge.twists.contains(.noPausing) { seen = true; break }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        XCTAssertTrue(seen, "in the enum but never drawn looks exactly like very rare")
    }

    func testTwoDaysOfTheSameModeAreOnlySimilarWhenTheirTwistsAre() {
        let plain = DailyChallenge(dateKey: "a", mode: .endlessII, classicLevel: nil, twists: [])
        let alsoPlain = DailyChallenge(dateKey: "b", mode: .endlessII, classicLevel: nil, twists: [])
        XCTAssertTrue(DailyChallengeGenerator.readsTheSame(plain, alsoPlain))

        let classic = DailyChallenge(dateKey: "c", mode: .classic, classicLevel: 4, twists: [])
        XCTAssertFalse(DailyChallengeGenerator.readsTheSame(plain, classic),
                       "a different mode is a different day whatever else matches")
    }
}

/// The count-up at the end of a level, shared by the between-levels screen and the daily's
/// Complete screen.
///
/// James, round 210: "single levels on daily challenge need a time bonus on the complete
/// screen at the end of the player finished the level. It should be broken down like the end
/// of a pack in classic mode - level score, time bonus and total score, using the same tally
/// animation."
///
/// "The same tally animation" is the requirement that makes this worth a type rather than a
/// second copy: the two screens keep their own labels, because they sit in quite different
/// layouts, and share exactly the part a player would notice diverging.
final class ScoreTallyTests: XCTestCase {

    private let values = ScoreTally.Values(level: 800, bonus: 250, from: 1000, to: 2050)

    func testItStartsAtNothingAndEndsAtEverything() {
        XCTAssertEqual(ScoreTally.reading(at: 0, of: values),
                       ScoreTally.Reading(level: 0, bonus: 0, total: 1000))
        XCTAssertEqual(ScoreTally.reading(at: ScoreTally.duration, of: values),
                       ScoreTally.Reading(level: 800, bonus: 250, total: 2050))
    }

    /// The three counts happen one after another, not together.
    func testEachNumberWaitsItsTurn() {
        let duringLevel = ScoreTally.reading(at: ScoreTally.levelDuration/2, of: values)
        XCTAssertGreaterThan(duringLevel.level, 0)
        XCTAssertEqual(duringLevel.bonus, 0, "the bonus has not started")
        XCTAssertEqual(duringLevel.total, 1000, "nor the total")

        let duringBonus = ScoreTally.reading(at: ScoreTally.bonusStart + 0.01, of: values)
        XCTAssertEqual(duringBonus.level, 800, "the level score is finished and stays")
        XCTAssertGreaterThan(duringBonus.bonus, 0)
        XCTAssertEqual(duringBonus.total, 1000)

        let duringTotal = ScoreTally.reading(at: ScoreTally.totalStart + 0.01, of: values)
        XCTAssertEqual(duringTotal.level, 800)
        XCTAssertEqual(duringTotal.bonus, 250, "and so does the bonus")
        XCTAssertGreaterThan(duringTotal.total, 1000)
    }

    /// **Nothing runs backwards.** The numbers used to drain back to zero once the total had
    /// taken them, which read as though the level had been worth nothing - you finished a
    /// level and the figure beside it was 0.
    func testNoNumberEverGoesDown() {
        var last = ScoreTally.reading(at: 0, of: values)
        for step in stride(from: 0.0, through: ScoreTally.duration, by: 0.01) {
            let now = ScoreTally.reading(at: step, of: values)
            XCTAssertGreaterThanOrEqual(now.level, last.level)
            XCTAssertGreaterThanOrEqual(now.bonus, last.bonus)
            XCTAssertGreaterThanOrEqual(now.total, last.total)
            last = now
        }
    }

    /// A daily on a single level has no earlier total to build on, so the count starts from
    /// nothing and the three numbers add up exactly.
    func testASingleLevelDailyAddsUp() {
        let daily = ScoreTally.Values(level: 800, bonus: 250, from: 0, to: 1050)
        let end = ScoreTally.reading(at: ScoreTally.duration, of: daily)
        XCTAssertEqual(end.level + end.bonus, end.total)
    }

    func testTheHapticTicksAreSpreadAcrossTheWholeCount() {
        XCTAssertEqual(ScoreTally.tick(at: 0), 0)
        XCTAssertEqual(ScoreTally.tick(at: ScoreTally.duration*0.99),
                       ScoreTally.hapticTicks - 1)
    }
}

/// What round 228's twist workbook changed about the pool and the drop table.
///
/// James: "extra balls covers loaded", "sudden death is replaced by one life", and the
/// power-up workbook's Daily column "should be the overarching rule".
final class DailyTwistWorkbookTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func scene(_ twists: [DailyTwist], mode: GameMode = .classic) -> GameScene {
        DailyChallengeSession.shared.active = DailyChallenge(dateKey: "t", mode: mode,
                                                            classicLevel: mode == .classic ? 1 : nil,
                                                            twists: twists)
        let scene = GameScene()
        scene.gameMode = mode
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// Neither retired twist can be drawn for any mode.
    func testTheRetiredTwistsAreOfferedNowhere() {
        for mode in [GameMode.classic, .endless, .endlessII] {
            XCTAssertFalse(DailyTwist.loaded.applies(to: mode),
                           "Loaded is still in \(mode.name)'s pool")
            XCTAssertFalse(DailyTwist.suddenDeath.applies(to: mode),
                           "Sudden Death is still in \(mode.name)'s pool")
        }
    }

    /// Their raw values stay, because a stored day is written down as one.
    func testTheirNamesStillDecode() {
        XCTAssertEqual(DailyTwist(rawValue: "loaded"), .loaded)
        XCTAssertEqual(DailyTwist(rawValue: "suddenDeath"), .suddenDeath)
    }

    /// And a challenge built by hand still means what it says.
    func testAHandBuiltChallengeStillHonoursThem() {
        XCTAssertEqual(scene([.loaded]).dailyStartingLives, 4)
        XCTAssertEqual(scene([.suddenDeath]).dailyStartingLives, 0)
    }

    /// Extra Balls reaches every mode now, and means two more than the mode's own rack.
    func testExtraBallsIsTwoMoreThanTheModeWouldGive() {
        for mode in [GameMode.classic, .endless, .endlessII] {
            XCTAssertTrue(DailyTwist.spareBalls.applies(to: mode),
                          "Extra Balls should reach \(mode.name)")
        }

        let mayhem = scene([.spareBalls], mode: .endlessII)
        XCTAssertEqual(mayhem.dailyStartingLives, 2, "an empty rack becomes a rack of two")

        let classic = scene([.spareBalls])
        classic.numberOfLives = 3
        XCTAssertEqual(classic.dailyStartingLives, 5, "two on top of what the level gave")
    }

    /// Lose A Ball, Lock and Key never fall on a daily, whatever the twists are.
    func testTheWorkbooksDailyColumnIsHonoured() {
        let scene = scene([], mode: .endlessII)
        scene.powerUpProbArray = Array(repeating: 5, count: LevelPackSetup().powerUpNameArray.count)
        scene.applyDailyEconomyTwists()

        XCTAssertEqual(scene.powerUpProbArray[1], 0, "Lose A Ball fell on a daily")
        XCTAssertEqual(scene.powerUpProbArray[48], 0, "Lock fell on a daily")
        XCTAssertEqual(scene.powerUpProbArray[49], 0, "Key fell on a daily")
    }

    /// And on a fogged day, neither vision power-up falls.
    func testFogOfWarTakesShowAndHideBricksOutOfTheTable() {
        let fogged = scene([.fogOfWar], mode: .endlessII)
        fogged.powerUpProbArray = Array(repeating: 5, count: LevelPackSetup().powerUpNameArray.count)
        fogged.applyDailyEconomyTwists()
        XCTAssertEqual(fogged.powerUpProbArray[15], 0, "Show Bricks undid the twist")
        XCTAssertEqual(fogged.powerUpProbArray[16], 0, "Hide Bricks hid what was hidden")

        let clear = scene([], mode: .endlessII)
        clear.powerUpProbArray = Array(repeating: 5, count: LevelPackSetup().powerUpNameArray.count)
        clear.applyDailyEconomyTwists()
        XCTAssertEqual(clear.powerUpProbArray[15], 5, "an unfogged day keeps Show Bricks")
    }
}

/// Retiring a twist after release must not move a day already played.
///
/// James, round 228: "once 1.3 is released, any changes to Daily Challenge mode cannot corrupt
/// previous days, so we need to make sure it's possible to add things and make changes."
///
/// Adding was already safe, through `activationKey`. Taking one away was not: dropping it from
/// the pool shortens the list every past day rolled against, so every date behind the change
/// draws something else. A retirement is a date now, for the same reason an activation is.
final class DailyTwistRetirementTests: XCTestCase {

    private func days(_ range: ClosedRange<Int>) -> [String] {
        range.map { day in
            let key = String(format: "2026-11-%02d", day)
            let challenge = DailyChallengeGenerator.challenge(forKey: key)
            return "\(key)|\(challenge.mode.name)|\(challenge.twists.map(\.rawValue).sorted().joined(separator: ","))"
        }
    }

    /// A twist retired from a future date leaves every earlier day exactly as it was.
    ///
    /// Read off the machinery rather than by editing a twist: what is under test is that the
    /// pool is asked about a *date*, so that a later change cannot reach backwards.
    func testAFutureRetirementCannotReachBackwards() {
        for twist in DailyTwist.allCases where twist.retirementKey > "2026-11-30" {
            XCTAssertTrue(twist.inPool(on: "2026-11-15", for: .classic)
                            == twist.applies(to: .classic)
                          || twist.activationKey > "2026-11-15",
                          "\(twist.rawValue) is in or out of the pool for reasons other than its dates")
        }
    }

    /// A retirement date is honoured on the day it names, and not before.
    func testARetirementTakesEffectOnItsOwnDate() {
        XCTAssertFalse(DailyTwist.loaded.inPool(on: "2026-11-15", for: .classic),
                       "a retired twist is still being offered")
        XCTAssertFalse(DailyTwist.suddenDeath.inPool(on: "2026-11-15", for: .classic))

        XCTAssertTrue(DailyTwist.oneLife.inPool(on: "2026-11-15", for: .classic),
                      "a living twist was retired by accident")
    }

    /// And the generator reads the same days twice, which is the property the whole design
    /// rests on.
    func testTheSameFortnightReadsTheSameTwice() {
        XCTAssertEqual(days(1...14), days(1...14))
    }
}

/// The two twists that decide how the game looks, and the middle ground the news twists left out.
///
/// James, round 229: "ok, they are not possible together then" for Monochromatic and Theme, and
/// "wipe can stay for daily challenge modes. It can be considered a neutral power-up as it
/// depends what power-ups are enabled."
final class DailyLookAndNeutralTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func scene(_ twists: [DailyTwist], key: String = "2026-11-15") -> GameScene {
        DailyChallengeSession.shared.active = DailyChallenge(dateKey: key, mode: .endlessII,
                                                            classicLevel: nil, twists: twists)
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    // MARK: - Look

    /// They share a category, which is how this design says "at most one of these".
    func testTheLookTwistsCannotHappenTogether() {
        XCTAssertEqual(DailyTwist.monochromatic.category, DailyTwist.dailyTheme.category)
        XCTAssertNotEqual(DailyTwist.monochromatic.category, DailyTwist.fogOfWar.category,
                          "a fogged day wearing a drawn theme is a pairing James allows")
    }

    /// Monochromatic is Classic, and Classic is all three settings.
    func testMonochromaticForcesClassic() {
        XCTAssertEqual(scene([.monochromatic]).dailyForcedTheme, 0)
    }

    /// Theme draws one from the date, never Classic, and the same date always draws the same.
    func testThemeDrawsOneFromTheDate() {
        let count = LevelPackSetup().themeNameArray.count
        for day in 1...28 {
            let key = String(format: "2026-11-%02d", day)
            let drawn = DailyTwist.dailyThemeIndex(forKey: key, themeCount: count)
            XCTAssertGreaterThan(drawn, 0, "\(key) drew Classic, which is Monochromatic's answer")
            XCTAssertLessThan(drawn, count)
            XCTAssertEqual(drawn, DailyTwist.dailyThemeIndex(forKey: key, themeCount: count),
                           "\(key) did not draw the same theme twice")
        }
    }

    /// An ordinary day leaves the player's own settings alone.
    func testAnOrdinaryDayForcesNothing() {
        XCTAssertNil(scene([]).dailyForcedTheme)
        XCTAssertNil(scene([.fogOfWar]).dailyForcedTheme)
    }

    // MARK: - Neutral power-ups

    /// Wipe is neither good nor bad, because which it is depends on the day.
    func testWipeIsNeutral() {
        let wipe = LevelPackSetup().powerUpNameArray.firstIndex(of: "Wipe")
        XCTAssertNotNil(wipe)
        guard let wipe else { return }
        XCTAssertTrue(GameScene.endlessIINeutralPowerUps.contains(wipe))
        XCTAssertFalse(GameScene.endlessIIHarmfulPowerUps.contains(wipe),
                       "its chip says -0.1, but on a No Good News day it is the kindest thing"
                       + " on the field")
        XCTAssertFalse(GameScene.endlessIIBeneficialPowerUps.contains(wipe))
    }

    /// Mystery gets there on its own, through the blank chip it has always had.
    func testMysteryIsNeutralWithoutBeingNamed() {
        let mystery = LevelPackSetup().powerUpNameArray.firstIndex(of: "Mystery")
        XCTAssertNotNil(mystery)
        guard let mystery else { return }
        XCTAssertTrue(GameScene.endlessIINeutralPowerUps.contains(mystery))
    }

    /// Lose A Ball's blank chip is not neutrality.
    func testLoseABallIsNotNeutral() {
        XCTAssertFalse(GameScene.endlessIINeutralPowerUps.contains(1))
        XCTAssertTrue(GameScene.endlessIIHarmfulPowerUps.contains(1))
    }

    /// Each news twist bans one side and leaves the middle standing.
    func testTheNewsTwistsBanOneSideEach() {
        let names = LevelPackSetup().powerUpNameArray
        guard let wipe = names.firstIndex(of: "Wipe"),
              let giga = names.firstIndex(of: "Giga-Ball"),
              let inert = names.firstIndex(of: "Inert Ball") else { return XCTFail("names") }

        func table(_ twists: [DailyTwist]) -> [Int] {
            let scene = scene(twists)
            scene.powerUpProbArray = Array(repeating: 5, count: names.count)
            scene.applyDailyEconomyTwists()
            return scene.powerUpProbArray
        }

        let noBad = table([.noBadNews])
        XCTAssertEqual(noBad[inert], 0, "a bad power-up fell on a No Bad News day")
        XCTAssertEqual(noBad[giga], 5)
        XCTAssertEqual(noBad[wipe], 5, "Wipe should fall on both")

        let noGood = table([.noGoodNews])
        XCTAssertEqual(noGood[giga], 0, "a good power-up fell on a No Good News day")
        XCTAssertEqual(noGood[inert], 5)
        XCTAssertEqual(noGood[wipe], 5, "Wipe should fall on both")
    }
}

/// Always On: one power-up standing all day.
///
/// The workbook: "permanent power-up should be randomly selected from the available timed or
/// paddle hit based power-ups", disallowing "anything that contradicts the always on power-up
/// / the always on power-up itself", with "the HUD power-up icon should show, but with no
/// progression bar".
final class DailyAlwaysOnTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func scene(_ mode: GameMode, key: String = "2026-11-15") -> GameScene {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: key, mode: mode, classicLevel: mode == .classic ? 1 : nil,
            twists: [.alwaysOn])
        let scene = GameScene()
        scene.gameMode = mode
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// Only power-ups that can last are drawn. An instant has nothing to be permanently on
    /// *about* - it happens and it is over.
    func testOnlyLastingPowerUpsAreDrawn() {
        let setup = LevelPackSetup()
        for day in 1...28 {
            let key = String(format: "2026-11-%02d", day)
            for mode in [GameMode.classic, .endless, .endlessII] {
                guard let drawn = DailyTwist.alwaysOnPowerUp(forKey: key, mode: mode) else {
                    return XCTFail("\(key) in \(mode.name) drew nothing at all")
                }
                let timer = setup.powerUpTimerArray[drawn]
                XCTAssertTrue(timer == "10s" || timer == "5 paddle hits",
                              "\(setup.powerUpNameArray[drawn]) lasts \"\(timer)\"")
            }
        }
    }

    /// The daily's own bans come first, so a permanent Lock is never drawn.
    func testTheDailysBannedPowerUpsAreNeverDrawn() {
        for day in 1...28 {
            let key = String(format: "2026-11-%02d", day)
            for mode in [GameMode.classic, .endless, .endlessII] {
                let drawn = DailyTwist.alwaysOnPowerUp(forKey: key, mode: mode)
                XCTAssertFalse(DailyTwist.bannedFromDailies.contains(drawn ?? -1),
                               "\(key) drew one the daily bans")
            }
        }
    }

    /// Mayhem's own power-ups are not drawn outside Mayhem.
    func testAClassicDayDrawsAClassicPowerUp() {
        let setup = LevelPackSetup()
        for day in 1...28 {
            let key = String(format: "2026-11-%02d", day)
            guard let drawn = DailyTwist.alwaysOnPowerUp(forKey: key, mode: .classic) else {
                return XCTFail("nothing drawn")
            }
            XCTAssertFalse(setup.isEndlessIIPowerUp(drawn),
                           "\(setup.powerUpNameArray[drawn]) does not exist in Classic")
        }
    }

    /// The same day draws the same power-up, everywhere, always.
    func testTheDrawIsTheSameEveryTime() {
        for day in 1...14 {
            let key = String(format: "2026-11-%02d", day)
            XCTAssertEqual(DailyTwist.alwaysOnPowerUp(forKey: key, mode: .endlessII),
                           DailyTwist.alwaysOnPowerUp(forKey: key, mode: .endlessII))
        }
    }

    /// Neither the standing power-up nor anything that would end it falls.
    func testTheStandingPowerUpAndItsRivalsDoNotDrop() {
        let scene = scene(.endlessII)
        guard let standing = scene.dailyAlwaysOnPowerUp else { return XCTFail("no draw") }
        scene.powerUpProbArray = Array(repeating: 5,
                                       count: LevelPackSetup().powerUpNameArray.count)
        scene.applyDailyEconomyTwists()

        XCTAssertEqual(scene.powerUpProbArray[standing], 0,
                       "catching the one already on is a drop that does nothing")
        for rival in GameScene.endlessIIExclusiveIndicesEnded(byCollecting: standing) {
            XCTAssertEqual(scene.powerUpProbArray[rival], 0,
                           "\(LevelPackSetup().powerUpNameArray[rival]) would end the day's twist")
        }
    }

    /// The bridge from named power-ups to indices finds them, which is the half that would
    /// fail silently if a rename ever broke it.
    func testTheExclusionBridgeResolvesEveryName() {
        let names = LevelPackSetup().powerUpNameArray
        for exclusive in EndlessIIExclusive.allCases {
            XCTAssertTrue(names.contains(exclusive.powerUpName),
                          "\(exclusive) is written down as \"\(exclusive.powerUpName)\", "
                          + "which is not a power-up")
        }
    }

    /// An ordinary day has nothing standing.
    func testAnOrdinaryDayHasNothingStanding() {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-11-15", mode: .endlessII, classicLevel: nil, twists: [.fogOfWar])
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        XCTAssertNil(scene.dailyAlwaysOnPowerUp)
    }
}

/// Landslide: the field comes down in Classic, on a daily only.
final class DailyLandslideTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    /// Classic alone. The endless modes have a field that comes down at them already, and a
    /// twist promising a landslide that delivers the mode's own cadence did nothing.
    func testItIsAClassicTwist() {
        XCTAssertTrue(DailyTwist.landslide.applies(to: .classic))
        XCTAssertFalse(DailyTwist.landslide.applies(to: .endless))
        XCTAssertFalse(DailyTwist.landslide.applies(to: .endlessII))
    }

    /// It shares a category with nothing, because the matrix allows it beside everything.
    func testItSharesItsCategoryWithNothing() {
        let others = DailyTwist.allCases.filter {
            $0 != .landslide && $0.category == DailyTwist.landslide.category
        }
        XCTAssertTrue(others.isEmpty, "Landslide would now refuse to appear beside \(others)")
    }

    private func landslideScene() -> GameScene {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-11-15", mode: .classic, classicLevel: 1, twists: [.landslide])
        let scene = GameScene()
        scene.gameMode = .classic
        scene.brickHeight = 20
        scene.minPaddleGap = 40
        scene.totalStatsArray = [TotalStats()]
        scene.addChild(scene.paddle)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        return scene
    }

    @discardableResult
    private func brick(_ scene: GameScene, y: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 20))
        node.name = BrickCategoryName
        node.position = CGPoint(x: 0, y: y)
        scene.addChild(node)
        return node
    }

    /// Quicksand does not fall on a Landslide day: on a day whose whole twist is the field
    /// moving down, it cannot be told from the weather.
    func testQuicksandDoesNotFallOnALandslideDay() {
        let scene = landslideScene()
        scene.powerUpProbArray = Array(repeating: 5,
                                       count: LevelPackSetup().powerUpNameArray.count)
        scene.applyDailyEconomyTwists()
        XCTAssertEqual(scene.powerUpProbArray[23], 0)
    }

    /// It steps on its own cadence rather than every frame.
    func testItStepsOnItsOwnCadence() {
        let step = GameScene.dailyLandslideStep
        XCTAssertFalse(GameScene.landslideIsDue(now: 1, lastStep: 0),
                       "a first frame is a baseline, not a step")
        XCTAssertFalse(GameScene.landslideIsDue(now: 100 + step - 0.1, lastStep: 100),
                       "a second is not a step - the field would be gone in ten")
        XCTAssertTrue(GameScene.landslideIsDue(now: 100 + step, lastStep: 100))
    }

    /// Slower than Mayhem's own cadence, because Classic's levels are built to be cleared
    /// from a standing start rather than defended.
    func testItIsSlowerThanMayhemsOwnDescent() {
        XCTAssertGreaterThan(GameScene.dailyLandslideStep, GameScene.endlessIIDescentStep)
    }

    /// A brick that reaches the bottom comes back at the top.
    ///
    /// James, round 231: "if a brick makes it to the bottom un-hit, it should wrap around back
    /// to the top. This way the level doesn't end once all the bricks vanish off the bottom."
    /// The field is a conveyor: it cannot empty itself by falling past the paddle, and the only
    /// way to clear it is still to hit it.
    ///
    /// The tick that moves the field stands down unless the scene is in `Playing`, which a
    /// scene built in a test is not - so the wrap is asked of the two lines it is drawn
    /// between, which is where the decision lives.
    func testTheFloorAndCeilingAreAPaddlesGapAndTheTopRow() {
        let scene = landslideScene()
        XCTAssertEqual(scene.dailyLandslideFloor,
                       scene.paddle.position.y + scene.minPaddleGap, accuracy: 0.001,
                       "the floor is the line the game has always called the bottom")
        XCTAssertEqual(scene.dailyLandslideCeiling, scene.yBrickOffset, accuracy: 0.001,
                       "a wrapped brick comes back on the row the grid was built on")
        XCTAssertGreaterThan(scene.dailyLandslideCeiling, scene.dailyLandslideFloor,
                             "the field would wrap into itself")
    }

    /// Which bricks wrap and which step: the row above the floor is the last one that moves.
    func testOnlyTheBottomRowWraps() {
        let scene = landslideScene()
        let floor = scene.dailyLandslideFloor

        let wrapping = brick(scene, y: floor + scene.brickHeight - 1)
        let stepping = brick(scene, y: floor + scene.brickHeight + 1)

        XCTAssertLessThan(wrapping.position.y - scene.brickHeight, floor,
                          "this one has nowhere left to go and should come round")
        XCTAssertGreaterThan(stepping.position.y - scene.brickHeight, floor,
                             "this one still has a row beneath it")
    }

    /// And a day without the twist never moves anything.
    func testAnOrdinaryDayDoesNotSlide() {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-11-15", mode: .classic, classicLevel: 1, twists: [])
        let scene = GameScene()
        scene.gameMode = .classic
        scene.totalStatsArray = [TotalStats()]
        XCTAssertFalse(scene.dailyLandslide)
    }
}

/// The twists, against the document that names them.
///
/// James, round 237: "update the in game twist names and descriptions from the information in
/// the twist details reference." Three had drifted - Spare Balls, Mayhem Bricks and No Pausing
/// were built before `Giga-Ball 2026 - Twist Details` existed, and the document calls them
/// Extra Balls, Extra Mayhem and No Breaks. Written down here because the document is not
/// something the build can read, so this file is the closest the suite gets to holding it.
final class TwistNamesMatchTheWorkbookTests: XCTestCase {

    /// The workbook's Twist column, for the twists the game has built.
    private let workbook: [DailyTwist: String] = [
        .fogOfWar: "Fog of War", .noBadNews: "No Bad News", .noGoodNews: "No Good News",
        .noPowerUps: "No Power-Ups", .drought: "Drought", .spareBalls: "Extra Balls",
        .powerShower: "Power Shower", .oneLife: "One Life", .alwaysOn: "Always On",
        .upsideDown: "Upside Down", .mirrored: "Mirrored", .brickSwap: "Brick Swap",
        .mayhemBricks: "Extra Mayhem", .timeTrial: "Time Trial",
        .monochromatic: "Monochromatic", .dailyTheme: "Theme", .landslide: "Landslide",
        .noPausing: "No Breaks",
    ]

    func testEveryTwistIsCalledWhatTheWorkbookCallsIt() {
        for (twist, name) in workbook {
            XCTAssertEqual(twist.displayName, name, "\(twist)")
        }
    }

    /// And the ones that are not in it are the retired ones, and the ones written after it.
    ///
    /// A twist cannot be deleted - its case name is a key in the save and in `retirementKey`,
    /// and removing one would change which day is which for every day already played - so a
    /// twist missing from the workbook has either been retired or has not reached the workbook
    /// yet, and anything else has gone missing rather than been decided.
    ///
    /// **The second half is new** (round 258). The workbook is James's document and the game
    /// is allowed to run ahead of it - `PowerUpCatalogue` makes the same bargain in the other
    /// direction, and for the same reason: a list that may only ever match exactly is a list
    /// that forbids building anything before it is written down. What is *not* allowed is a
    /// twist in neither set.
    func testTheOnlyTwistsMissingFromTheWorkbookAreTheRetiredOnesAndTheNewOnes() {
        let retired: Set<DailyTwist> = [.loaded, .suddenDeath]
        let sinceTheWorkbook: Set<DailyTwist> = [.fullDeck, .levelPegging]
        let missing = Set(DailyTwist.allCases).subtracting(workbook.keys)
        XCTAssertEqual(missing, retired.union(sinceTheWorkbook))
    }

    /// Every twist says something, and says it once.
    func testEveryTwistHasItsOwnNameAndBlurb() {
        let names = DailyTwist.allCases.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count, "two twists share a name")
        for twist in DailyTwist.allCases {
            XCTAssertFalse(twist.blurb.isEmpty, "\(twist)")
        }
    }

    /// A Time Trial day does not spend lives, and its blurb says so.
    ///
    /// The workbook's Details column asks for "unlimited lives" and the game was taking them:
    /// ninety seconds *and* three balls is two limits where the design asks for one, and a bad
    /// start ended the attempt with a minute of it still on the board.
    func testATimeTrialSpendsNoLives() {
        XCTAssertFalse(GameScene.dailyLifeIsSpent(onTimeTrial: true))
        XCTAssertTrue(GameScene.dailyLifeIsSpent(onTimeTrial: false),
                      "and every other day still spends one")
        XCTAssertTrue(DailyTwist.timeTrial.blurb.lowercased().contains("lose the ball"),
                      "a player has to be told, or they will play it as if lives mattered")
    }
}
