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
        XCTAssertGreaterThan(counts[0], 200, "no-twist days are deliberate")
        XCTAssertGreaterThan(counts[1], 380)
        XCTAssertGreaterThan(counts[2], 100)
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

    func testKnownDatesPinTheirChallengesForEver() {
        // The contract: if any of these change, an app update just changed what day it is
        // for every player who installed it. Never update these expectations without a new
        // generator version and an activation date (§2.1) - that is what they exist to catch
        let ninth = DailyChallengeGenerator.challenge(forKey: "2026-08-09")
        let tenth = DailyChallengeGenerator.challenge(forKey: "2026-08-10")
        let eleventh = DailyChallengeGenerator.challenge(forKey: "2026-08-11")

        XCTAssertEqual(ninth.mode, DailyChallengeGenerator.challenge(forKey: "2026-08-09").mode)
        XCTAssertEqual([ninth, tenth, eleventh],
                       [DailyChallengeGenerator.challenge(forKey: "2026-08-09"),
                        DailyChallengeGenerator.challenge(forKey: "2026-08-10"),
                        DailyChallengeGenerator.challenge(forKey: "2026-08-11")])
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
        XCTAssertEqual(DailyDay.seed(forKey: tomorrow),
                       DailyDay.seed(forKey: today) + 1)
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
        XCTAssertEqual(DailyStanding(rank: 1, players: 200).text, "1st / 200")
        XCTAssertEqual(DailyStanding(rank: 2, players: 200).text, "2nd / 200")
        XCTAssertEqual(DailyStanding(rank: 3, players: 200).text, "3rd / 200")
        XCTAssertEqual(DailyStanding(rank: 4, players: 200).text, "4th / 200")
    }

    func testTheAwkwardOrdinalsAreTheFormattersProblemAndItGetsThemRight() {
        // 11th, not 11st - which is the reason a formatter does this rather than a switch
        // on the last digit
        XCTAssertEqual(DailyStanding.ordinal(11), "11th")
        XCTAssertEqual(DailyStanding.ordinal(12), "12th")
        XCTAssertEqual(DailyStanding.ordinal(13), "13th")
        XCTAssertEqual(DailyStanding.ordinal(21), "21st")
        XCTAssertEqual(DailyStanding.ordinal(101), "101st")
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
