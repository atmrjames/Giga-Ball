//
//  DailyTwists.swift
//  Megaball
//
//  Where the day's twists reach the scene.
//
//  The scene never knows it is playing a daily - it plays Classic or an endless mode
//  exactly as ever, and asks `DailyChallengeSession` at a handful of named points whether
//  the day says otherwise. Keeping the hooks few and listed here is what keeps the daily
//  from becoming a fourth copy of the game: it is the same game, asked politely to differ.
//
//  The other half of this file is the standing-down: a daily run must never touch the
//  campaign's saves, heights, or high scores (§9 of the daily spec). Those gates live at
//  the write sites, but the questions they ask are defined here.
//

import SpriteKit

extension GameScene {

    var isDailyChallenge: Bool {
        DailyChallengeSession.shared.isActive
    }

    /// The day's word on how many *reserve* balls the run starts with. Nil means the
    /// mode's own.
    ///
    /// Reserves, because that is what `numberOfLives` has always counted: Classic's three
    /// lives are three balls in the rack under the paddle, plus the one already on it.
    /// The first build returned totals here, and "One Life" handed the player a ball on
    /// the paddle *and* one in reserve - the play test counted two lives. A twist's number
    /// is the total; the scene's number is the rack.
    var dailyStartingLives: Int? {
        guard isDailyChallenge else { return nil }
        if DailyChallengeSession.shared.has(.oneLife) { return 0 }
        // One ball total: the one on the paddle, an empty rack
        if DailyChallengeSession.shared.has(.loaded) { return 4 }
        // Five balls total, four of them racked
        if DailyChallengeSession.shared.has(.suddenDeath) { return 0 }
        // Sudden Death in Classic is One Life by another name; in the endless modes it
        // has its own teeth (see endlessIIBallWasLost's gate). Parked from the pool for
        // now, but a hand-built challenge still means what it says
        if DailyChallengeSession.shared.has(.spareBalls) { return 2 }
        // Three balls total for the endless modes, whose baseline rack is empty
        return nil
    }

    /// Whether the rack of reserve balls should stay off the screen for this run.
    ///
    /// Two cases: an endless daily *without* Spare Balls (the modes' own rule - one ball,
    /// no counter), and a lives twist that empties the rack (One Life), where an empty
    /// container reading "no lives left" all run would be the twist rubbing it in. The
    /// play test asked for it hidden outright.
    var dailyLivesRowHidden: Bool {
        guard isDailyChallenge else { return false }
        if endlessMode { return DailyChallengeSession.shared.has(.spareBalls) == false }
        return dailyStartingLives == 0 && numberOfLives <= 0
        // Dynamic on purpose: if a Get a Life ever lands mid-run the rack has something
        // to say again, and it comes back
    }

    /// The one question the lives-row drawing asks: should the rack be off screen.
    ///
    /// Outside a daily this is the old rule - endless modes have no rack. Inside one,
    /// the day decides: Spare Balls puts a rack in an endless run, One Life takes the
    /// empty one out of a Classic run.
    var livesRowSuppressed: Bool {
        isDailyChallenge ? dailyLivesRowHidden : endlessMode
    }

    /// What this daily run scored, in the mode's own terms (§7): Classic's level score
    /// with its timer bonus, an endless run's height.
    var dailyRunScore: Int {
        endlessMode ? endlessHeight : levelScore + levelTimerBonus
    }

    /// The daily's own record-keeping, run when a daily ends - the counterpart of
    /// everything `saveGameData` deliberately does not do for a daily (§9).
    ///
    /// The scoring attempt writes its result and, if the window is still open, posts to
    /// the boards; every other run is practice and only ever raises the practice best.
    /// A run that crossed midnight writes its score but never posts (§1) - the attempt
    /// was spent when play was pressed, and the briefing said so going in.
    ///
    /// Also puts the run's score where the game-over screen reads it: the campaign path
    /// does that as part of the stats writing this run must never touch, and without it
    /// a Classic daily ended on "Score: 0" whatever the run earned.
    func recordDailyResult() {
        guard let challenge = DailyChallengeSession.shared.active else { return }
        let session = DailyChallengeSession.shared
        let score = dailyRunScore

        if endlessMode == false {
            totalScore = totalScore + levelScore + levelTimerBonus
        }
        // Display only - the cumulative stats the campaign path feeds stay untouched

        var record = totalStatsArray[0].dailyRecord(forKey: challenge.dateKey)
            ?? DailyChallengeRecord(dateKey: challenge.dateKey)

        session.lastRunPosted = false
        if session.isScoringAttempt {
            session.isScoringAttempt = false
            record.firstAttemptScore = score
            if challenge.dateKey == session.todayKey {
                session.lastRunPosted = true
                record.posted = true
                record.postedNormalisedScore =
                    DailyChallengeBoards.normalised(score: score, mode: challenge.mode)
                totalStatsArray[0].upsertDailyRecord(record)
                GameCenterHandler().submitDailyScores(
                    dayScore: score,
                    runningTotal: totalStatsArray[0].dailyTotalPostedScore)
                // The record goes in before the total is read, so the total includes
                // today - and the total board only ever grows, so resubmitting the
                // whole of it is safe and self-healing (§7)
            }
        } else {
            record.bestPracticeScore = max(record.bestPracticeScore, score)
            // The attempt itself was counted when play was pressed - the briefing
            // screen owns the counting, this owns the results
        }

        totalStatsArray[0].upsertDailyRecord(record)
        // Persisted by the saveGameStats that follows in the end-of-run sequence
    }

    /// Whether losing any ball ends the run today, whatever the mode's own rules say.
    var dailySuddenDeath: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.suddenDeath)
    }

    /// Applies the day's economy to the power-up tables.
    ///
    /// Called at the end of both allocation paths - the classic per-level one and the
    /// endless per-row one - so whatever they decided, the day has the last word.
    func applyDailyEconomyTwists() {
        guard isDailyChallenge else { return }
        let session = DailyChallengeSession.shared

        powerUpProbArray[8] = 0   // +100 Points
        powerUpProbArray[9] = 0   // -100 Points
        powerUpProbArray[10] = 0  // +1000 Points
        powerUpProbArray[11] = 0  // -1000 Points
        powerUpProbArray[12] = 0  // x2 Multiplier
        powerUpProbArray[13] = 0  // Reset Multiplier
        powerUpProbArray[14] = 0  // Next Level
        // Every daily, before any twist speaks (§7 "Decided"): the board compares play,
        // not luck. The points and multiplier power-ups are score handed out by the drop
        // roll, and Next Level ends a single-level daily on the spot - an instant win no
        // board should hand to whoever's brick happened to hold it. The multiplier itself
        // still builds and falls exactly as Classic's always has - only the power-ups
        // that jump it are stood down. The endless modes excluded all of these already;
        // repeating them here is what makes the rule true of Classic dailies too

        if dailyStartingLives != nil {
            powerUpProbArray[0] = 0  // Get a Life
            powerUpProbArray[1] = 0  // Lose a Life
            // A lives twist means exactly what it says. The scene bumps Get a Life's
            // weight as lives run low - kindly meant, but on a One Life day it would be
            // dealing the player a second life the twist just took away
        }

        if session.has(.noPowerUps) {
            for index in powerUpProbArray.indices { powerUpProbArray[index] = 0 }
        }
        if session.has(.noGoodNews) {
            for index in powerUpProbArray.indices
            where GameScene.endlessIIHarmfulPowerUps.contains(index) == false {
                powerUpProbArray[index] = 0
            }
        }
        if session.has(.noBadNews) {
            for index in powerUpProbArray.indices
            where GameScene.endlessIIHarmfulPowerUps.contains(index) {
                powerUpProbArray[index] = 0
            }
        }
        if session.has(.powerShower) {
            powerUpProbFactor = 3
            // The drop roll is one-in-factor per destroyed brick, so smaller is rainier
        }
        if session.has(.drought) {
            powerUpProbFactor = 30
        }

        powerUpProbSum = powerUpProbArray.reduce(0, +)
        // Both callers sum the table just before calling this, so the sum they left
        // behind still counts the entries the day just zeroed. The drop roll re-sums
        // before drawing, but everything else that reads the sum should read the truth
    }

    /// Whether the day hides its field until it is struck.
    var dailyFogIsOn: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.fogOfWar)
    }

    /// Hides the day's bricks, where Fog of War is on.
    ///
    /// *Every* type, including Portals, power-up bricks and Indestructibles. The first
    /// build fogged only the bricks whose own hit rules pass through the reveal - which
    /// meant a fogged field with visible Indestructibles and Portals in it, and the play
    /// test saw exactly that ("some brick types are visible as they build in"). The
    /// reveal now happens at the top of `hitBrick`, before any type's own rules, so
    /// there is no type that can be fogged and not come back.
    func applyDailyFog(to bricks: [SKNode]) {
        guard dailyFogIsOn else { return }
        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture != brickNullTexture else { continue }
            // An empty cell has nothing to hide
            brick.isHidden = true
        }
    }

    /// Brings one brick out of the fog, the first time anything strikes it.
    ///
    /// Called before every type's own rules, so it reaches the bricks that never reach
    /// the type switch - and takes whatever struck it: ball, laser, explosion or halo.
    func revealDailyFog(_ brick: SKSpriteNode) {
        guard dailyFogIsOn, brick.isHidden else { return }
        brick.isHidden = false
        brick.alpha = 0
        brick.run(.fadeIn(withDuration: 0.2))
        // The same fade an invisible brick has always come back with
    }
}
