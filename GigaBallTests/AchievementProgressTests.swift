//
//  AchievementProgressTests.swift
//  GigaBallTests
//
//  What the achievements pages say about an achievement not yet earned (round 361).
//
//  James, from his phone: "Some of mine show 0% complete when they shouldn't have that as an
//  option as they are either complete or not, some of them show 0% when there should be a best
//  so far with a %". His screenshots: Paddle Guru at "Percentage complete 0.0%", which is
//  survived or not; Experienced Daily Challenger at 0.0% beside a Serial Daily Challenger
//  already earned; Month Long Streak at 0.0% beside a Week Long Streak. And: "The achievements
//  detail screen, the graphic is way too big."
//

import XCTest
@testable import Giga_Ball

final class AchievementProgressTests: XCTestCase {

    private let today = "2026-10-03"

    /// Days in a row ending yesterday, all posted.
    private func postedDays(_ count: Int, endingOn last: String = "2026-10-02") -> [DailyChallengeRecord] {
        var keys = [last]
        while keys.count < count { keys.append(DailyChallengeGenerator.previousKey(of: keys.last!)!) }
        return keys.map { DailyChallengeRecord(dateKey: $0, firstAttemptScore: 100, posted: true,
                                               attemptCount: 1) }
    }

    /// A file nobody has played on says nothing beside any achievement - not "0.0%", which
    /// round 309 wrote as the starting string for every achievement from 66 on.
    func testAFreshFileShowsNoShareAnywhere() {
        let stats = TotalStats()
        let shown = stats.achievementsUnlockedArray.indices.filter {
            stats.achievementProgressText($0, today: today) != ""
        }
        XCTAssertEqual(shown, [], "nothing played, nothing to show a share of")
    }

    /// "Paddle Guru... Survive the Reversed Paddle Control power-up" is survived or not.
    func testAnAllOrNothingAchievementHasNoPercentage() {
        let stats = TotalStats()
        stats.achievementsPercentageCompleteArray[82] = "0.0%"
        XCTAssertEqual(stats.achievementProgressText(82, today: today), "")
        stats.achievementsPercentageCompleteArray[93] = "25.0%"
        XCTAssertEqual(stats.achievementProgressText(93, today: today), "",
                       "Top Of The Charts is a place on a board; no stored string makes it a share")
    }

    /// Experienced Daily Challenger, with Serial Daily Challenger's ten already posted.
    func testTheDailyCountShowsTheDaysPosted() {
        let stats = TotalStats()
        stats.dailyChallengeRecords = postedDays(14)
        XCTAssertEqual(stats.achievementProgressText(DailyAchievements.hundredPosts, today: today),
                       "14 of 100 · 14%")
        XCTAssertEqual(stats.achievementProgressText(DailyAchievements.yearOfPosts, today: today),
                       "14 of 365 · 3%")
        XCTAssertEqual(TotalStats.achievementProgressLabel(DailyAchievements.hundredPosts), "Progress")
    }

    /// Month Long Streak, with Week Long Streak earned: the best run so far.
    func testAStreakShowsTheBestRunSoFar() {
        let stats = TotalStats()
        stats.dailyChallengeRecords = postedDays(7)
        XCTAssertEqual(stats.achievementProgressText(DailyAchievements.monthStreak, today: today),
                       "7 days · 23%")
        XCTAssertEqual(TotalStats.achievementProgressLabel(DailyAchievements.monthStreak),
                       "Best so far")
        stats.dailyChallengeRecords = postedDays(1)
        XCTAssertEqual(stats.achievementProgressText(DailyAchievements.monthStreak, today: today),
                       "1 day · 3%")
    }

    /// Twist Completionist counts the live twists met on days played.
    func testTwistCompletionistCountsTheTwistsMet() throws {
        let stats = TotalStats()
        let day = try XCTUnwrap((1...60).lazy.map { offset -> String in
            var key = self.today
            for _ in 0..<offset { key = DailyChallengeGenerator.previousKey(of: key)! }
            return key
        }.first { DailyChallengeGenerator.challenge(forKey: $0).twists.isEmpty == false })
        stats.dailyChallengeRecords = [DailyChallengeRecord(dateKey: day, posted: false,
                                                            attemptCount: 1)]
        let progress = try XCTUnwrap(DailyAchievements.progress(
            for: DailyAchievements.everyTwist, records: stats.dailyRecords, on: today))
        XCTAssertGreaterThan(progress.done, 0)
        XCTAssertEqual(progress.of, DailyAchievements.liveTwists(on: today).count)
        XCTAssertTrue(stats.achievementProgressText(DailyAchievements.everyTwist, today: today)
            .hasPrefix("\(progress.done) of \(progress.of) · "))
    }

    /// A share that is written as the game goes is still shown - and a share of nothing is not.
    func testAStoredShareIsShownUnlessItIsNothing() {
        let stats = TotalStats()
        stats.achievementsPercentageCompleteArray[28] = "42.0%"
        XCTAssertEqual(stats.achievementProgressText(28, today: today), "42.0%")
        stats.achievementsPercentageCompleteArray[28] = "0.0%"
        XCTAssertEqual(stats.achievementProgressText(28, today: today), "")
        XCTAssertEqual(TotalStats.achievementProgressLabel(28), "Percentage complete")
    }

    /// Every stored share is one the game can actually write somewhere: in range, and not an
    /// endless milestone or a daily count, which are worked out rather than stored.
    func testTheStoredSharesAreTheOnesNobodyWorksOut() {
        for index in AchievementCatalogue.storedShare {
            XCTAssertTrue(TotalStats().achievementsPercentageCompleteArray.indices.contains(index))
            XCTAssertNil(TotalStats.endlessMilestones[index], "\(index)")
            XCTAssertNil(DailyAchievements.progress(for: index, records: [], on: today), "\(index)")
        }
    }
}

/// "The achievements detail screen, the graphic is way too big."
final class AchievementPageBadgeTests: XCTestCase {

    func testTheBadgeIsNoBiggerThanItWantsOnATallPhone() throws {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: ItemsStatsViewController.self))
        let page = try XCTUnwrap(board.instantiateViewController(withIdentifier: "itemsStatsView")
                                 as? ItemsStatsViewController)
        page.totalStatsArray = [TotalStats()]
        page.sender = "Achievements"
        page.passedIndex = 82
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 440, height: 956))
        window.rootViewController = page
        window.isHidden = false
        page.view.setNeedsLayout()
        page.view.layoutIfNeeded()

        XCTAssertLessThanOrEqual(page.powerUpImage.bounds.height, 100.5,
                                 "one row under it, and the room left over went into the badge")
        XCTAssertGreaterThan(page.powerUpImage.bounds.height, 60)
    }
}
