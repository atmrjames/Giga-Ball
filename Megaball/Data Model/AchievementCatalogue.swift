//
//  AchievementCatalogue.swift
//  Megaball
//
//  Which mode each achievement belongs to, so the achievements page can be read the way
//  the statistics page is - one section per mode (play-test round 126: "use tab bar in
//  achievements view").
//
//  The answer is not a matter of taste: an achievement belongs to the modes it can actually
//  be *earned* in, and that is written down already in the checks that award them. This file
//  is that reading, made once, with the guard that decides it named beside every entry - so a
//  future reader can confirm an entry against the check rather than against an opinion.
//
//  Three rules cover all sixty-six:
//
//  - A check guarded by `endlessMode` belongs to **both** endless modes. `endlessMode` is
//    true in Endless and in Endless Mayhem; only `gameMode == .endlessII` separates them, and
//    none of these checks asks that.
//  - A check guarded by `endlessMode == false`, or one living in the between-levels pass that
//    only a campaign run reaches, belongs to **Classic**.
//  - A check with no mode guard at all - the power-up and paddle ones, which happen wherever
//    the ball is - belongs to **all three**.
//
//  The daily had none until round 310, and that was a rule rather than an oversight:
//  `achievementsCheck()` returns early for a daily, because a daily played on a level someone
//  has not earned must not unlock what earning it would have (daily spec §9).
//
//  It has nineteen now - `earnableInDaily`, which is James's workbook's Daily Challenge column -
//  and §9's rule is untouched by them, because not one is about a level or a pack. Ten are facts
//  about the daily's own history and nine are things that happen inside a rally.
//

import Foundation
import GameKit

enum AchievementCatalogue {

    /// Each achievement's Game Center identifier, in the order the arrays hold them.
    ///
    /// **Written down rather than left in a comment** (round 309). Every award site in the game
    /// spells its own identifier as a string literal beside the index it is setting, which is
    /// two facts kept in step by hand at sixty-six sites - and thirty more were about to be
    /// added. Here the pair is one fact, and `GameScene.award(_:)` takes only the index.
    ///
    /// Append-only, like every other array in this family: a shipped identifier can never be
    /// renamed, because Game Center has it.
    static let identifiers: [String] = [
        "achievementEndlessTen",              // 0 Endless Mode 10m Milestone
        "achievementEndlessHundred",          // 1 Endless Mode 100m Milestone
        "achievementEndlessFiveHundred",      // 2 Endless Mode 500m Milestone
        "achievementEndlessOneK",             // 3 Endless Mode 1,000m Milestone
        "achievementEndlessFiveK",            // 4 Endless Mode 5,000m Total Height
        "achievementEndlessTenK",             // 5 Endless Mode 10,000m Total Height
        "classicPackComplete",                // 6 Classic Pack Complete
        "spacePackComplete",                  // 7 Space Pack Complete
        "naturePackComplete",                 // 8 Nature Pack Complete
        "urbanPackComplete",                  // 9 City Pack Complete
        "foodPackComplete",                   // 10 Food Pack Complete
        "computerPackComplete",               // 11 Computer Pack Complete
        "bodyPackComplete",                   // 12 Body Pack Complete
        "worldPackComplete",                  // 13 World Pack Complete
        "emojiPackComplete",                  // 14 Emoji Pack Complete
        "numbersPackComplete",                // 15 Numbers Pack Complete
        "challengePackComplete",              // 16 Challenge Pack Complete
        "endlessOneMins",                     // 17 Endless Mode 1 Minute Milestone
        "endlessFiveMins",                    // 18 Endless Mode 5 Minute Milestone
        "endlessTenMins",                     // 19 Endless Mode 10 Minute Milestone
        "endlessThirtyMins",                  // 20 Endless Mode 30 Minute Milestone
        "endlessSixtyMins",                   // 21 Endless Mode 1 Hour Milestone
        "endlessCleared",                     // 22 Tidying Up
        "mysteryPowerUp",                     // 23 Taking The Plunge
        "firstPowerUp",                       // 24 Now We’re Talking
        "gigaLasers",                         // 25 Giga-Lasers!
        "endBackstop",                        // 26 Didn’t Even Need It
        "favouritePowerUp",                   // 27 That’s My Favourite
        "powerUpCollectorHundred",            // 28 100 And Counting
        "powerUpCollectorThousand",           // 29 Hoarder
        "powerUpLeaverHundred",               // 30 Picky
        "powerUpLeaverThousand",              // 31 Power-Up Shy
        "maxPaddleSize",                      // 32 This Is Too Easy
        "minPaddleSize",                      // 33 Good Luck
        "maxBallSize",                        // 34 Beach Ball
        "minBallSize",                        // 35 Pinball
        "noBallsLost",                        // 36 Invincible
        "threeBallsLost",                     // 37 Hanging on
        "allLevelPowerUps",                   // 38 Super Powers
        "noLevelPowerUps",                    // 39 Mere Mortal
        "quickLevelComplete",                 // 40 Giga-Speedy
        "fivePaddleHits",                     // 41 Supreme Paddle Efficiency
        "tenPaddleHits",                      // 42 Paddle Master
        "fiveKPointsLevel",                   // 43 5,000 Points On 1 Level
        "tenKPointsLevel",                    // 44 10,000 Points On 1 Level
        "oneLevelsComplete",                  // 45 1 Level Down
        "tenLevelsComplete",                  // 46 Level Decade
        "hunderdLevelsComplete",              // 47 Level Century
        "oneKLevelsComplete",                 // 48 Level Millennium
        "tenKLevelsComplete",                 // 49 Level 10 Millenia
        "paddleSpeed",                        // 50 Panic Move
        "hundredKTotalScore",                 // 51 100,000 And Counting
        "fiveHundredKTotalScore",             // 52 Half A Mill
        "millTotalScore",                     // 53 Millionaire
        "noBallsLostPack",                    // 54 God-Like
        "tenBallsLostPack",                   // 55 More Balls Please
        "allPackPowerUps",                    // 56 Super Hero
        "noPackPowerUps",                     // 57 Serial Dodger
        "quickPackComplete",                  // 58 And Time
        "tenKPointsPack",                     // 59 10,000 Points On 1 Pack
        "twoFiveKPointsPack",                 // 60 25,000 Points On 1 Pack
        "fiftyKPointsPack",                   // 61 50,000 Points On 1 Pack
        "onePacksComplete",                   // 62 1 Pack Down
        "tenPacksComplete",                   // 63 Pack Decade
        "hundredPacksComplete",               // 64 Pack Century
        "thousandPacksComplete",              // 65 Pack Millennium
        "mayhemTen",                          // 66 Endless Mayhem
        "mayhemHundred",                      // 67 Endless Mayhem
        "mayhemFiveHundred",                  // 68 Endless Mayhem
        "mayhemOneK",                         // 69 Endless Mayhem
        "mayhemFiveKTotal",                   // 70 Endless Mayhem
        "mayhemTenKTotal",                    // 71 Endless Mayhem
        "mayhemOneMinute",                    // 72 Endless Mayhem
        "mayhemFiveMinutes",                  // 73 Endless Mayhem
        "mayhemTenMinutes",                   // 74 Endless Mayhem
        "mayhemThirtyMinutes",                // 75 Endless Mayhem
        "mayhemOneHour",                      // 76 Endless Mayhem
        "mayhemClear",                        // 77 Tidying Up Amongst The Mayhem
        "mayhemPowerUpBrick",                 // 78 Feel The Power Of The Brick
        "mayhemWreckingGiga",                 // 79 Giga-Wrecking Ball!
        "mayhemThreeBalls",                   // 80 Juggler
        "mayhemPortalTravel",                 // 81 Wormhole
        "mayhemSurviveReversed",              // 82 Paddle Master
        "allPowerUpsCollected",               // 83 Power-Up Completionist
        "fivePowerUpsActive",                 // 84 Multi-Talented
        "firstDailyChallenge",                // 85 First Daily Challenge
        "tenDailyChallenges",                 // 86 Serial Daily Challenger
        "hundredDailyChallenges",             // 87 Experienced Daily Challenger
        "yearOfDailyChallenges",              // 88 Seasoned Daily Challenger
        "dailyWeekStreak",                    // 89 Week Long Streak
        "dailyMonthStreak",                   // 90 Month Long Streak
        "dailyYearStreak",                    // 91 Year Long Streak
        "dailyTopTen",                        // 92 Top 10 Finish
        "dailyFirstPlace",                    // 93 Top Of The Charts
        "allTwistsPlayed",                    // 94 Twist Completionist
        "butterFingers",                      // 95 Butter Fingers
        "maximumBallSpeed",                   // 96 Blur
        "minimumBallSpeed",                   // 97 Pokey
    ]

    /// The modes an achievement can be earned in.
    ///
    /// A set rather than a single mode, because most of them are honestly more than one:
    /// "Beach Ball" is a power-up on a paddle and does not care which mode the paddle is in.
    static func modes(for index: Int) -> Set<GameMode> {
        if dailyOnly.contains(index) { return [] }
        if mayhemOnly.contains(index) { return [.endlessII] }
        if bothEndlessModes.contains(index) { return [.endless, .endlessII] }
        if endlessOnly.contains(index) { return [.endless] }
        if classicOnly.contains(index) { return [.classic] }
        return []
    }
    // **An achievement earnable anywhere belongs to no tab but All** (James, round 329d, with
    // Pokey as his example: slow the ball to its minimum speed, which every mode can do). The
    // default used to be all three play modes, so two thirds of the page was repeated under
    // Classic, Endless and Mayhem and a player looking for "what does Mayhem have" was reading
    // mostly the same list they had just read under Classic. An empty set is the honest
    // answer to "which mode is this one's own", and All is where everything still is
    // **Two faults James found by reading the page** (round 318: "remove the endless mode
    // achievements from showing up in the endless mayhem section - check the other sections to
    // make sure they only show achievements available in those game modes").
    //
    // `endlessOnly` answered both endless modes, which was true when it was written and stopped
    // being true in round 309: that round gave Mayhem its own height, total-height and duration
    // milestones, 66 to 76, precisely because it had been sharing Endless's. Sharing them on the
    // *tab* outlasted sharing them in the game, so the Mayhem tab listed eleven Endless
    // milestones above its own eleven, one pair at a time, saying the same thing twice.
    //
    // Whether a Mayhem run still *earns* the Endless ones is a separate question and the answer
    // is deliberately unchanged - the checks do not ask which endless mode it is, and rewriting
    // that would take achievements off players who have them. What this decides is which tab
    // lists them, which is round 310's own note about `mayhemOnly` read the other way round.
    //
    // And the daily's own ten fell through to the default, which is "every play mode" - so
    // Week Long Streak and First Daily Challenge were listed under Classic, Endless and Mayhem.
    // They are facts about a history rather than about a rally and belong to no play mode at
    // all, which is what the empty set says. The Daily tab reaches them through
    // `earnableInDaily` and is unaffected.

    /// The daily's own ten: facts about a history rather than about a rally.
    ///
    /// Awarded from the menu rather than from a scene (see `award` below) - how many days have
    /// posted, how long the streak is, where a day finished on the board, whether every twist
    /// has been met. None of them can be earned by playing Classic, Endless or Mayhem outside
    /// the daily, so none of them is listed under those tabs.
    static let dailyOnly: Set<Int> = Set(85...94)
    // **85 to 94, and round 318 wrote 87 to 96** - two out at both ends, which put Butter
    // Fingers and Blur in the set meaning "a fact about a history, listed under no play mode"
    // and left First Daily Challenge and Serial Daily Challenger in the bucket meaning
    // "earnable everywhere". Corrected in round 319a by `testTheModeSetsNameWhatTheyThinkTheyName`,
    // which is the test round 318 wrote for exactly this and whose first full run had not
    // happened when the round was committed. The range is First Daily Challenge (85) through
    // Twist Completionist (94); 95, 96 and 97 are Butter Fingers, Blur and Pokey

    /// Whether an achievement is offered under a tab.
    ///
    /// The daily's tab is `earnableInDaily`, which is exactly James's workbook's Daily Challenge
    /// column - nineteen of round 310's additions and nothing else. It used to be answered false
    /// for everything, and the note under the empty tab explained why; the daily has its own set
    /// now, so the tab has something to show.
    static func belongs(_ index: Int, to mode: GameMode) -> Bool {
        mode == .daily ? dailyOnly.contains(index) : modes(for: index).contains(mode)
    }
    // **The daily's tab lists the daily's own, not everything a daily can earn** (James, round
    // 329d: "in those categories, just show the [achievements] only available in those game
    // modes... Pokey shows up in all the categories. I think it's better for it to end up in
    // the All category only"). `earnableInDaily` is nineteen of round 310's additions, and
    // almost all of them are earnable in an ordinary run too - so listing them here put the
    // same achievement under four tabs and made every tab a slightly shorter copy of All.
    // What a tab is for is what only that mode gives you. `earnableInDaily` still decides what
    // a daily run may *award*, which is a different question and unchanged

    /// The indices shown under a mode, in the order the arrays hold them.
    static func indices(for mode: GameMode?, count: Int) -> [Int] {
        guard let mode else { return Array(0..<count) }
        return (0..<count).filter { belongs($0, to: mode) }
    }

    /// Earned only in an endless run: the height and duration milestones, and clearing the
    /// field. Guarded by `endlessHeight`, `endlessModeDurationCheck` or `endlessMode` in
    /// `GameScene`, and by `scene.endlessMode` in the between-levels pass for the two totals.
    /// Earned only in Endless Mayhem: its own height, total-height and duration milestones.
    ///
    /// **Mayhem's first achievements of its own** (round 309, from James's workbook). Until now
    /// it shared the Endless six and the duration five, because none of those checks asks which
    /// endless mode it is in - so a Mayhem player earned them and nothing rewarded Mayhem.
    static let mayhemOnly: Set<Int> = [
        66, 67, 68, 69,   // 10m, 100m, 500m, 1,000m
        70, 71,           // 5,000m and 10,000m total height
        72, 73, 74, 75, 76,  // the duration milestones
        77,               // Tidying Up Amongst The Mayhem - the Mayhem twin of 22
        78,               // Feel The Power Of The Brick - power-up bricks are Mayhem's
        79, 80, 81, 82,   // Giga-Wrecking Ball, Juggler, Wormhole, Paddle Master
    ]
    // **Round 310 added six more from James's workbook.** Four of them - 79 to 82 - name things
    // only Mayhem has: the Wrecking Ball, three balls at once from its own multiball, portal
    // bricks and Reversed Paddle Control. The sheet marks them for the daily as well, and they
    // are: a daily *run* in Mayhem is a Mayhem run, and the checks that award them do not ask
    // whose scoreboard it is going to. What `mayhemOnly` decides is which **tab** they are
    // listed under, and that is Mayhem

    /// Marks achievements earned outside a running game, and reports them to Game Center.
    ///
    /// **The menu's half of `GameScene.award(_:)`** (round 310). The daily's own ten are facts
    /// about a history rather than about a rally - how many days have posted, how long the
    /// streak is, whether every twist has been met - and the screen that knows the history is a
    /// menu, which has no scene to ask. The two do the same three things in the same order: set
    /// the flag, stamp the date, tell Game Center.
    ///
    /// Bounds-checked rather than assumed equal, exactly as the scene's is: a stats file written
    /// by a newer build can be longer than this build's catalogue.
    ///
    /// - Returns: the indices that were newly earned, so a caller can decide whether to save.
    @discardableResult
    static func award(_ indices: Set<Int>, in stats: inout TotalStats) -> Set<Int> {
        var earned: Set<Int> = []
        for index in indices.sorted() {
            guard index >= 0, index < stats.achievementsUnlockedArray.count,
                  index < identifiers.count,
                  stats.achievementsUnlockedArray[index] == false else { continue }

            stats.achievementsUnlockedArray[index] = true
            if index < stats.achievementDates.count { stats.achievementDates[index] = Date() }
            if index < stats.achievementsPercentageCompleteArray.count {
                stats.achievementsPercentageCompleteArray[index] = "100%"
            }
            earned.insert(index)

            let identifier = identifiers[index]
            let achievement = GKAchievement(identifier: identifier)
            guard achievement.isCompleted == false else { continue }
            achievement.showsCompletionBanner = true
            GKAchievement.report([achievement]) { error in
                Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting \(identifier) achievement", privacy: .public)")
            }
        }
        return earned
    }

    /// The achievements a Daily Challenge run is allowed to earn.
    ///
    /// **The rule the daily spec's §9 was always half of.** `achievementsCheck()` returns early
    /// for a daily and every in-scene check guards on `isDailyChallenge == false`, because a
    /// daily can put a player on a level they have not earned and must not unlock what earning
    /// it would have. That is right for everything about levels, packs and totals, and it was
    /// only ever a blanket because the daily had nothing of its own.
    ///
    /// It does now. James's workbook marks a Daily Challenge column against nineteen of the
    /// round-310 additions, and every one of them is a thing that happens *inside a rally* -
    /// three balls at once, five power-ups running, the ball at its fastest - or a fact about
    /// the daily's own history. None of them is a level's or a pack's, so none of them can be
    /// unlocked by a level the player was lent for a day.
    ///
    /// The two Mayhem additions the sheet leaves blank stay blank: 77 clears the field, and 78
    /// is a power-up brick, and both are marked for Mayhem alone.
    static let earnableInDaily: Set<Int> = Set(79...97)

    static let endlessOnly: Set<Int> = [
        0, 1, 2, 3,   // 10m, 100m, 500m, 1,000m - endlessHeight, either endless mode
        4, 5,         // 5,000m and 10,000m total height
        17, 18, 19, 20, 21,  // the duration milestones
        22,           // Tidying Up - `endlessMode && bricksLeft == 0`
        // **Butter Fingers is not here, and round 318 put it here twice over.** That round read
        // 95 as Top Of The Charts, moved it to 97, and was wrong on both counts: 95 *is* Butter
        // Fingers, 93 is Top Of The Charts and 97 is Pokey, which is earnable anywhere. The
        // original number was right and the correction broke it. It is in `bothEndlessModes`
        // below instead, which is a distinction round 318 did not have and needed
    ]

    /// Earned in **either** endless mode, with no Mayhem twin to separate them.
    ///
    /// The milestones above are Endless-only on the tab because round 309 gave Mayhem its own
    /// eleven, so listing Endless's under Mayhem said the same thing twice. Butter Fingers has
    /// no twin: `ballLost` asks `endlessMode`, which is true in both, and there is one
    /// achievement for the pair. So it belongs on both tabs, and a set that can only say "one
    /// mode" cannot express that - which is why this exists rather than a number moved into a
    /// set that means something else.
    static let bothEndlessModes: Set<Int> = [
        95,           // Butter Fingers - `endlessMode && bricksDestroyedThisRun == 0`
    ]

    /// Earned only in a campaign run: everything about levels and packs, and the four checks
    /// that name `endlessMode == false` outright.
    static let classicOnly: Set<Int> = [
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,  // the eleven pack completions
        26,                       // Didn't Even Need It - `endlessMode == false`
        36, 37,                   // balls lost across a level
        38, 39,                   // every power-up on a level, and none
        40,                       // Giga-Speedy - a level under a minute
        41, 42,                   // paddle hits on a level - `endlessMode == false`
        43, 44,                   // points on one level
        45, 46, 47, 48, 49,       // levels completed
        51, 52, 53,               // total score - `endlessMode == false`
        54, 55, 56, 57, 58,       // a pack's balls, power-ups and time
        59, 60, 61,               // points on one pack
        62, 63, 64, 65,           // packs completed
    ]

    /// The tabs the page offers, in the statistics page's order and words.
    ///
    /// Nil is the "All" tab. The daily is included deliberately even though nothing is filed
    /// under it: the page says why, which is worth more than a missing tab that reads as an
    /// oversight.
    static let tabs: [(title: String, mode: GameMode?)] = [
        ("All", nil), ("Classic", .classic), ("Endless", .endless),
        ("Mayhem", .endlessII), ("Daily", .daily),
    ]

    /// What an empty tab says, in its own words rather than a shrug.
    static func emptyNote(for mode: GameMode?) -> String {
        mode == .daily
            ? "Nothing here yet. The daily's own achievements are the ones a day can earn - "
                + "a day played on a level you have not earned must not unlock what earning "
                + "it would have, so the campaign's are not among them."
            : "Nothing here yet."
    }
}
