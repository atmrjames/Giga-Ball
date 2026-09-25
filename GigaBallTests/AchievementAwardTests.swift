//
//  AchievementAwardTests.swift
//  GigaBallTests
//
//  The award path itself, round 311.
//
//  Written because the CRAP metric pointed here. `achievementsCheck` scores a cyclomatic
//  complexity of 128 at nought percent coverage - fifth riskiest function in the app - and round
//  310 had just added twenty-one achievements to the machinery around it. The pure parts got
//  tests at the time (`DailyAchievementsTests`); the *award* itself did not, and it is where the
//  one rule that must never break lives.
//
//  That rule: a Daily Challenge is played on a level the player may not have earned, so a day
//  must not unlock what earning that level would have (daily spec §9). Round 310 replaced a
//  blanket refusal with a list, which is a much better rule and a much easier one to get wrong.
//

import XCTest
@testable import Giga_Ball

final class AchievementAwardTests: XCTestCase {

    private func scene(daily: Bool) -> GameScene {
        let game = GameScene()
        game.gameMode = .endlessII
        game.totalStatsArray = [TotalStats()]
        if daily {
            DailyChallengeSession.shared.active = DailyChallenge(
                dateKey: "2026-10-08", mode: .endlessII, classicLevel: nil, twists: [])
        } else {
            DailyChallengeSession.shared.active = nil
        }
        return game
    }

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    // MARK: - The daily rule

    /// A campaign run can earn anything the catalogue holds.
    func testAnOrdinaryRunCanEarnACampaignAchievement() {
        let game = scene(daily: false)
        XCTAssertTrue(game.award(24), "a first power-up, wherever the paddle was")
        XCTAssertTrue(game.totalStatsArray[0].achievementsUnlockedArray[24])
    }

    /// **A daily cannot earn the campaign's**, which is §9 and is the whole point of the gate.
    func testADailyCannotEarnACampaignAchievement() {
        let game = scene(daily: true)
        for index in AchievementCatalogue.classicOnly.sorted().prefix(8) {
            XCTAssertFalse(game.award(index),
                           "\(LevelPackSetup().achievementsNameArray[index]) is a level's or a "
                           + "pack's, and a day is played on a level nobody had to earn")
            XCTAssertFalse(game.totalStatsArray[0].achievementsUnlockedArray[index],
                           "and nothing was written down either")
        }
    }

    /// But it can earn its own, which is what round 310 was for.
    func testADailyCanEarnTheOnesTheWorkbookGivesIt() {
        for index in AchievementCatalogue.earnableInDaily.sorted() {
            let game = scene(daily: true)
            XCTAssertTrue(game.award(index),
                          "\(LevelPackSetup().achievementsNameArray[index]) is marked for the "
                          + "Daily Challenge in James's workbook")
        }
    }

    /// The two Mayhem additions the sheet leaves blank stay blank.
    func testTheTwoMayhemOnlyAdditionsAreStillRefusedInADaily() {
        let game = scene(daily: true)
        for index in [77, 78] {
            XCTAssertFalse(game.award(index),
                           "\(LevelPackSetup().achievementsNameArray[index]) has no Daily "
                           + "Challenge column in the workbook")
        }
    }

    // MARK: - Awarding once

    /// An achievement is earned once, and the second ask changes nothing.
    ///
    /// The return value is what `newItemsBool` is driven from, so a second `true` would show the
    /// player a "new items" badge for something they earned last week.
    func testTheSecondAskIsRefused() {
        let game = scene(daily: false)
        XCTAssertTrue(game.award(24))
        XCTAssertFalse(game.award(24), "already earned")
    }

    /// A date is stamped, because the achievements page sorts by it.
    func testEarningStampsTheDate() {
        let game = scene(daily: false)
        let before = Date()
        XCTAssertTrue(game.award(24))
        XCTAssertGreaterThanOrEqual(game.totalStatsArray[0].achievementDates[24], before)
    }

    /// An index past the end of the catalogue is refused rather than trapping.
    ///
    /// Not hypothetical: a stats file written by a newer build is longer than this build's
    /// catalogue, which is the shape of the bug that crashed the app on launch for a player with
    /// years of synced data.
    func testAnIndexOutOfRangeIsRefused() {
        let game = scene(daily: false)
        XCTAssertFalse(game.award(-1))
        XCTAssertFalse(game.award(AchievementCatalogue.identifiers.count))
        XCTAssertFalse(game.award(10_000))
    }

    // MARK: - Power-Up Completionist

    /// It counts every power-up that is still offered, and no more.
    func testCompletionistWantsEveryPowerUpThatIsStillOffered() {
        let game = scene(daily: false)
        let setup = LevelPackSetup()
        let wanted = (0..<game.totalStatsArray[0].powerupsCollected.count)
            .filter { setup.retiredPowerUpIndices.contains($0) == false }
        XCTAssertFalse(wanted.isEmpty)

        for index in wanted { game.totalStatsArray[0].powerupsCollected[index] = 1 }
        game.checkPowerUpCompletionist()
        XCTAssertTrue(game.totalStatsArray[0].achievementsUnlockedArray[83],
                      "every live power-up collected at least once")
    }

    /// A retired power-up cannot hold it back, or nobody who arrived after it went could earn it.
    func testARetiredPowerUpDoesNotHoldItBack() {
        let game = scene(daily: false)
        let setup = LevelPackSetup()
        guard let retired = setup.retiredPowerUpIndices.first else {
            return XCTAssert(true, "nothing retired in this build, so nothing to prove")
        }
        for index in 0..<game.totalStatsArray[0].powerupsCollected.count {
            game.totalStatsArray[0].powerupsCollected[index] = 1
        }
        game.totalStatsArray[0].powerupsCollected[retired] = 0

        game.checkPowerUpCompletionist()
        XCTAssertTrue(game.totalStatsArray[0].achievementsUnlockedArray[83],
                      "the one still missing is one the game no longer offers")
    }

    /// One short of the set is not the set, and the bar says how far along it is.
    func testOneShortIsNotEarnedAndShowsItsProgress() {
        let game = scene(daily: false)
        let setup = LevelPackSetup()
        let wanted = (0..<game.totalStatsArray[0].powerupsCollected.count)
            .filter { setup.retiredPowerUpIndices.contains($0) == false }
        for index in wanted { game.totalStatsArray[0].powerupsCollected[index] = 1 }
        game.totalStatsArray[0].powerupsCollected[wanted[0]] = 0

        game.checkPowerUpCompletionist()
        XCTAssertFalse(game.totalStatsArray[0].achievementsUnlockedArray[83])

        let shown = game.totalStatsArray[0].achievementsPercentageCompleteArray[83]
        XCTAssertNotEqual(shown, "0.0%", "a player one short deserves to see how close they are")
        XCTAssertNotEqual(shown, "100%")
    }

    /// **A finished set is always delivered, however the file arrived.**
    ///
    /// The throttle that stops this reporting the same percentage to Game Center every ten
    /// seconds compares the share against what is already stored - and on its own that would
    /// take the early return for ever on a file whose percentage says "100%" while the unlocked
    /// flag is still false, so the achievement could never be earned.
    ///
    /// Not hypothetical: `awardProgress` writes the two together, so they cannot drift apart
    /// locally, but the iCloud merge takes the flags and the percentages from different sides.
    /// This family of arrays coming back disagreeing is the whole reason `padded(_:toMatch:)`
    /// exists.
    func testAFinishedSetIsEarnedEvenIfTheStoredShareAlreadySaysDone() {
        let game = scene(daily: false)
        let setup = LevelPackSetup()
        for index in 0..<game.totalStatsArray[0].powerupsCollected.count
        where setup.retiredPowerUpIndices.contains(index) == false {
            game.totalStatsArray[0].powerupsCollected[index] = 1
        }
        game.totalStatsArray[0].achievementsPercentageCompleteArray[83] = "100%"
        game.totalStatsArray[0].achievementsUnlockedArray[83] = false
        // The shape a merge can leave behind: the share says done, the flag says not

        game.checkPowerUpCompletionist()
        XCTAssertTrue(game.totalStatsArray[0].achievementsUnlockedArray[83],
                      "the completion is delivered rather than thrown away by the throttle")
    }

    /// And the steps on the way are throttled, which is what the guard is for.
    func testAnUnchangedShareIsNotWrittenAgain() {
        let game = scene(daily: false)
        game.totalStatsArray[0].powerupsCollected[0] = 1
        game.checkPowerUpCompletionist()
        let share = game.totalStatsArray[0].achievementsPercentageCompleteArray[83]
        XCTAssertNotEqual(share, "100%", "one power-up is not the set")

        game.totalStatsArray[0].achievementsUnlockedArray[83] = true
        game.totalStatsArray[0].achievementsPercentageCompleteArray[83] = share
        game.checkPowerUpCompletionist()
        XCTAssertEqual(game.totalStatsArray[0].achievementsPercentageCompleteArray[83], share,
                       "nothing new was collected, so nothing was written")
    }
}


/// James's old task list, made in round 344: "For achievements like 5 minutes in endless mode,
/// could have best so far when incomplete."
final class EndlessMilestoneProgressTests: XCTestCase {

    func testTheBestHeightSoFarIsTheProgress() {
        let stats = TotalStats()
        stats.endlessModeHeight = [40, 312, 120]
        XCTAssertEqual(stats.endlessMilestoneProgress(3) ?? 0, 0.312, accuracy: 0.0001,
                       "312m of the 1,000m milestone")
        XCTAssertEqual(stats.achievementProgressText(3), "312m · 31%",
                       "James, round 346: the height itself, and the share after it")
        XCTAssertEqual(stats.endlessMilestoneProgress(69) ?? 0, 0, accuracy: 0.0001,
                       "Mayhem's own milestone counts Mayhem runs only")
    }

    func testMayhemRunsCountForTheSharedMilestones() {
        let stats = TotalStats()
        stats.endlessIIModeHeight = [450]
        XCTAssertEqual(stats.endlessMilestoneProgress(2) ?? 0, 0.9, accuracy: 0.0001)
        XCTAssertEqual(stats.endlessMilestoneProgress(68) ?? 0, 0.9, accuracy: 0.0001)
    }

    func testTheLongestRunIsTheProgressOnTheMinutes() {
        let stats = TotalStats()
        stats.endlessModeDurations = [90]
        stats.endlessIIDurations = [240]
        XCTAssertEqual(stats.endlessMilestoneProgress(18) ?? 0, 0.8, accuracy: 0.0001,
                       "four minutes of five, from either mode")
        XCTAssertEqual(stats.endlessMilestoneProgress(73) ?? 0, 0.8, accuracy: 0.0001)
        XCTAssertEqual(stats.endlessMilestoneProgress(17) ?? 0, 1, accuracy: 0.0001,
                       "never past the whole")
    }

    func testATimeReadsInMinutesAndSeconds() {
        let stats = TotalStats()
        stats.endlessIIDurations = [252]
        XCTAssertEqual(stats.achievementProgressText(18), "4m 12s · 84%")
        stats.endlessIIDurations = [42]
        XCTAssertEqual(stats.achievementProgressText(17), "42s · 70%")
    }

    func testAnythingElseKeepsItsStoredFigure() {
        let stats = TotalStats()
        XCTAssertNil(stats.endlessMilestoneProgress(30))
        stats.achievementsPercentageCompleteArray[30] = "12.5%"
        XCTAssertEqual(stats.achievementProgressText(30), "12.5%")
        XCTAssertEqual(stats.achievementProgressText(0), "", "no runs, nothing to show")
    }

    /// The table names the achievements the award code actually awards for these.
    func testTheMilestonesAreRealAchievements() {
        for index in TotalStats.endlessMilestones.keys {
            XCTAssertTrue(AchievementCatalogue.identifiers.indices.contains(index), "\(index)")
        }
    }
}
