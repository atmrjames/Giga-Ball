//
//  DailyAchievementsTests.swift
//  GigaBallTests
//
//  The ten achievements the daily's own history earns, round 310.
//
//  From James's workbook: First Daily Challenge, Serial / Experienced / Seasoned Daily
//  Challenger, the three streaks, Top 10 Finish, Top Of The Charts and Twist Completionist.
//
//  Every one of them is derived rather than stored - the records already carry the day and
//  whether it posted, and a day's twists can always be worked out again from its key. These
//  tests are what says the derivation is right, because the only other way to see a Year Long
//  Streak is to play for a year.
//

import XCTest
@testable import Giga_Ball

final class DailyAchievementsTests: XCTestCase {

    /// A run of consecutive posted days, ending on the given key.
    private func posted(days: Int, endingOn last: String = "2026-09-05")
        -> [DailyChallengeRecord] {
        guard var day = DailyDay.date(forKey: last) else { return [] }
        var records: [DailyChallengeRecord] = []
        for _ in 0..<days {
            var record = DailyChallengeRecord(dateKey: DailyDay.key(for: day))
            record.posted = true
            record.attemptCount = 1
            records.append(record)
            day = DailyDay.utcCalendar.date(byAdding: .day, value: -1, to: day)!
        }
        return records
    }

    private func earned(_ records: [DailyChallengeRecord]) -> Set<Int> {
        DailyAchievements.earned(from: records, on: "2026-09-05")
    }

    // MARK: - The counts

    /// "Post a score in a Daily Challenge."
    func testOnePostedDayEarnsTheFirstAndNothingElse() {
        let earned = earned(posted(days: 1))
        XCTAssertTrue(earned.contains(DailyAchievements.firstPost))
        XCTAssertFalse(earned.contains(DailyAchievements.tenPosts))
        XCTAssertFalse(earned.contains(DailyAchievements.weekStreak),
                       "one day is not a week")
    }

    /// The counts arrive at exactly the number the sheet names, and not before.
    func testEachCountArrivesOnItsOwnDay() {
        for count in DailyAchievements.counts {
            XCTAssertFalse(earned(posted(days: count.days - 1)).contains(count.index),
                           "\(count.days - 1) days must not earn the \(count.days) achievement")
            XCTAssertTrue(earned(posted(days: count.days)).contains(count.index),
                          "\(count.days) days must earn it")
        }
    }

    /// A day played but never posted is not a completed challenge.
    ///
    /// The sheet's first row is "post a score in a Daily Challenge", and the three counts under
    /// it are that sentence with a bigger number. Free play is playable all day.
    func testDaysPlayedWithoutPostingDoNotCount() {
        var records = posted(days: 20)
        for index in records.indices { records[index].posted = false }
        let earned = earned(records)
        XCTAssertFalse(earned.contains(DailyAchievements.firstPost))
        XCTAssertFalse(earned.contains(DailyAchievements.tenPosts))
        XCTAssertFalse(earned.contains(DailyAchievements.weekStreak))
    }

    // MARK: - The streaks

    /// "Complete every Daily Challenge for 1 week" is seven days in a row.
    func testEachStreakWantsThatManyDaysInARow() {
        for streak in DailyAchievements.streaks {
            XCTAssertFalse(earned(posted(days: streak.days - 1)).contains(streak.index))
            XCTAssertTrue(earned(posted(days: streak.days)).contains(streak.index))
        }
    }

    /// A gap breaks a streak, and the count carries on regardless.
    ///
    /// Ten days on either side of a missed day is twenty posted days - Serial Daily Challenger -
    /// and the longest run in it is ten, which is not a fortnight and not a Week Long Streak's
    /// business either way. The point of the assertion is that the two questions are separate.
    func testAGapBreaksTheStreakButNotTheCount() {
        let recent = posted(days: 5, endingOn: "2026-09-05")
        let older = posted(days: 5, endingOn: "2026-08-20")
        let earned = earned(recent + older)

        XCTAssertTrue(earned.contains(DailyAchievements.tenPosts),
                      "ten days posted is ten days posted, whenever they were")
        XCTAssertFalse(earned.contains(DailyAchievements.weekStreak),
                       "the longest run is five, and a fortnight of nothing sits in the middle")
    }

    /// The streak arithmetic is `DailyStreak`'s, not a second copy of it.
    func testTheStreakAgreesWithTheTypeThatOwnsIt() {
        let records = posted(days: 9, endingOn: "2026-09-05")
            + posted(days: 3, endingOn: "2026-07-01")
        XCTAssertEqual(DailyStreak.longest(records: records), 9)
        XCTAssertTrue(earned(records).contains(DailyAchievements.weekStreak))
        XCTAssertFalse(earned(records).contains(DailyAchievements.monthStreak))
    }

    // MARK: - Twist Completionist

    /// "Play a Daily Challenge with each twist at least once."
    ///
    /// The target is the twists still being *offered*, which is the only version of the question
    /// anyone can answer: four twists are retired, and requiring every case would make this
    /// unearnable by anyone who was not playing before they went.
    func testTheTargetIsTheTwistsStillBeingOffered() {
        let live = DailyAchievements.liveTwists(on: "2026-09-05")
        XCTAssertFalse(live.isEmpty, "the pool is not empty on a day the daily is running")
    }

    /// Every day from `key` onwards that adds a twist nobody had met yet.
    ///
    /// **Forwards, not backwards.** A twist has an `activationKey` and is not in the pool on any
    /// day before it, so walking back through history can never meet the newest ones - which is
    /// exactly what the first version of this test found out.
    private func daysUntilEveryTwistIsMet(from key: String, limit: Int = 4_000)
        -> (records: [DailyChallengeRecord], last: String?, missing: Set<DailyTwist>) {
        let live = DailyAchievements.liveTwists(on: key)
        var met: Set<DailyTwist> = []
        var records: [DailyChallengeRecord] = []
        var last: String?
        var day = DailyDay.date(forKey: key)!

        for _ in 0..<limit where met.isSuperset(of: live) == false {
            let dayKey = DailyDay.key(for: day)
            let twists = Set(DailyChallengeGenerator.challenge(forKey: dayKey).twists)
            if twists.subtracting(met).isEmpty == false {
                last = dayKey
                met.formUnion(twists)
                var record = DailyChallengeRecord(dateKey: dayKey)
                record.attemptCount = 1
                records.append(record)
            }
            day = DailyDay.utcCalendar.date(byAdding: .day, value: 1, to: day)!
        }
        return (records, last, live.subtracting(met))
    }

    /// A history that has met every live twist earns it; one short of it does not.
    func testEveryLiveTwistMetEarnsItAndOneShortDoesNot() {
        let key = "2026-09-05"
        let walk = daysUntilEveryTwistIsMet(from: key)
        XCTAssertTrue(walk.missing.isEmpty,
                      "never offered inside four thousand days: "
                      + walk.missing.map(\.rawValue).sorted().joined(separator: ", "))

        XCTAssertTrue(DailyAchievements.earned(from: walk.records, on: key)
            .contains(DailyAchievements.everyTwist))

        let short = walk.records.filter { $0.dateKey != walk.last }
        XCTAssertFalse(DailyAchievements.earned(from: short, on: key)
            .contains(DailyAchievements.everyTwist),
                       "one twist missing is not every twist")
    }

    /// Played, not posted: a spent attempt still met the day's rules.
    func testADayPlayedWithoutPostingStillCountsForTheTwists() {
        let key = "2026-09-05"
        let walk = daysUntilEveryTwistIsMet(from: key)
        XCTAssertTrue(walk.missing.isEmpty)
        XCTAssertTrue(walk.records.allSatisfy { $0.posted == false },
                      "the walk builds played days, never posted ones")

        XCTAssertTrue(DailyAchievements.earned(from: walk.records, on: key)
            .contains(DailyAchievements.everyTwist),
                      "not one of these days posted, and all of them were played")
        XCTAssertFalse(DailyAchievements.earned(from: walk.records, on: key)
            .contains(DailyAchievements.firstPost),
                       "and none of them posted a score")
    }

    /// A day merely *listed* is not a day played.
    func testADayWithNoAttemptDoesNotCountForTheTwists() {
        let records = [DailyChallengeRecord(dateKey: "2026-09-05")]
        XCTAssertTrue(DailyAchievements.earned(from: records, on: "2026-09-05").isEmpty,
                      "an untouched record earns nothing at all")
    }

    // MARK: - The two placings

    /// "Finish in the top 10" and "finish first".
    func testThePlacingsAreReadOffTheStanding() {
        XCTAssertEqual(DailyAchievements.earned(fromStanding:
            LeaderboardStanding(rank: 1, players: 400)),
                       [DailyAchievements.topTen, DailyAchievements.firstPlace],
                       "first is also in the top ten")
        XCTAssertEqual(DailyAchievements.earned(fromStanding:
            LeaderboardStanding(rank: 10, players: 400)),
                       [DailyAchievements.topTen],
                       "tenth is the last place that counts")
        XCTAssertTrue(DailyAchievements.earned(fromStanding:
            LeaderboardStanding(rank: 11, players: 400)).isEmpty)
    }

    // MARK: - The catalogue's own bookkeeping

    /// The indices this type names are the ones the catalogue holds.
    ///
    /// The arrays are append-only and a player's unlocked flags are stored by position, so an
    /// index written down here and an entry written down there are one fact in two places -
    /// which is exactly the kind of pair that drifts.
    func testTheIndicesNameTheAchievementsTheySayTheyDo() {
        let names = LevelPackSetup().achievementsNameArray
        let expected: [(Int, String, String)] = [
            (DailyAchievements.firstPost, "First Daily Challenge", "firstDailyChallenge"),
            (DailyAchievements.tenPosts, "Serial Daily Challenger", "tenDailyChallenges"),
            (DailyAchievements.hundredPosts, "Experienced Daily Challenger",
             "hundredDailyChallenges"),
            (DailyAchievements.yearOfPosts, "Seasoned Daily Challenger",
             "yearOfDailyChallenges"),
            (DailyAchievements.weekStreak, "Week Long Streak", "dailyWeekStreak"),
            (DailyAchievements.monthStreak, "Month Long Streak", "dailyMonthStreak"),
            (DailyAchievements.yearStreak, "Year Long Streak", "dailyYearStreak"),
            (DailyAchievements.topTen, "Top 10 Finish", "dailyTopTen"),
            (DailyAchievements.firstPlace, "Top Of The Charts", "dailyFirstPlace"),
            (DailyAchievements.everyTwist, "Twist Completionist", "allTwistsPlayed"),
        ]
        for (index, name, identifier) in expected {
            XCTAssertEqual(names[index], name, "index \(index)")
            XCTAssertEqual(AchievementCatalogue.identifiers[index], identifier,
                           "index \(index)")
        }
    }

    /// Every one of the ten is earnable in a daily, which is the whole point of them.
    func testTheDailysOwnAchievementsAreEarnableInADaily() {
        for index in 85...94 {
            XCTAssertTrue(AchievementCatalogue.earnableInDaily.contains(index),
                          "\(LevelPackSetup().achievementsNameArray[index]) is the daily's own")
        }
    }
}
