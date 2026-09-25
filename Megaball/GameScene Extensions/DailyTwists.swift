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
import CoreImage

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
        // Five balls total, four of them racked. Retired from the pool in round 228 - Extra
        // Balls covers it - but a hand-built challenge still means what it says
        if DailyChallengeSession.shared.has(.suddenDeath) { return 0 }
        // Sudden Death in Classic is One Life by another name; in the endless modes it
        // has its own teeth (see endlessIIBallWasLost's gate). Retired in round 228 for
        // exactly that reason, and still honoured if a challenge asks for it
        if DailyChallengeSession.shared.has(.spareBalls) {
            let endless = DailyChallengeSession.shared.active?.mode.isEndless ?? endlessMode
            return endless ? 2 : GameScene.classicStartingRack + 2
        }
        // **Two more than the mode's own rack** (round 228's workbook: "two extra balls are
        // provided"). In the endless modes the rack is empty, so two more is a rack of two;
        // in Classic it is two on top of whatever the level would have given, which is the
        // only reading under which the same twist means the same thing in both.
        //
        // **It read `numberOfLives` until round 310, and that was a bug** (James: "the Extra
        // Balls twist on a Classic Mode Daily Challenge should provide 2 extra balls to normal,
        // not just 2 balls. So that would be 1 ball in play and 5 balls in reserve to start").
        //
        // The value is *self-referential*: `PreGame` writes `numberOfLives = dailyStartingLives
        // ?? 3`, so the property is read on the right-hand side of its own assignment and
        // answers with whatever the last run left behind - nought on a fresh launch. Two more
        // than nothing is two, which is what he counted. Asking the constant instead makes the
        // sentence true whatever came before.
        //
        // **And the mode comes from the day rather than from the scene's flag.** `endlessMode`
        // is a scene property that something has to have set first, and the day already knows
        // which mode it is - so a rule about what the *challenge* grants should read the
        // challenge. It falls back to the scene's flag for the case that has no active day, in
        // which case this line is unreachable anyway
        return nil
    }

    /// Whether the rack of reserve balls should stay off the screen for this run.
    ///
    /// Two cases: an endless daily *without* Extra Balls (the modes' own rule - one ball,
    /// no counter), and a lives twist that empties the rack (One Life), where an empty
    /// container reading "no lives left" all run would be the twist rubbing it in. The
    /// play test asked for it hidden outright.
    var dailyLivesRowHidden: Bool {
        guard isDailyChallenge else { return false }
        if DailyChallengeSession.shared.has(.timeTrial) { return true }
        // **A Time Trial shows no rack** (James, round 346: "still shows balls as lives in the
        // game even though it's unlimited lives - no need to show this graphic"). Losing a ball
        // costs nothing there (`dailyLifeIsSpent`), so a count of them is a limit that does not
        // apply - the pause screen and resume card already say "Unlimited balls" (round 344)
        if endlessMode { return DailyChallengeSession.shared.has(.spareBalls) == false }
        return dailyStartingLives == 0 && numberOfLives <= 0
        // Dynamic on purpose: if a Get a Life ever lands mid-run the rack has something
        // to say again, and it comes back
    }

    /// The one question the lives-row drawing asks: should the rack be off screen.
    ///
    /// Outside a daily this is the old rule - endless modes have no rack. Inside one,
    /// the day decides: Extra Balls puts a rack in an endless run, One Life takes the
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
    /// The player is leaving mid-run and said to post what they had (round 300).
    ///
    /// James: "quitting a daily should post the partial score - ask the user with a pop up,
    /// otherwise assume not." The pop-up is `GigaBallConfirm.postDailyScore` and this is the
    /// yes: it runs the same recording a run's natural end runs, which is the whole point -
    /// a partial score is a score, and routing it through the one recorder means it lands in
    /// the record, on the board and in the practice best by exactly the rules a finished run
    /// obeys, including the ones about closed days and forfeits.
    ///
    /// Nothing here decides anything. The deciding was done on the pop-up, and a run whose
    /// player said no simply never sends this.
    @objc func postDailyPartialScoreReceived(_ notification: Notification) {
        recordDailyResult()
    }

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
        if session.forfeitedByLeaving {
            session.isScoringAttempt = false
            record.bestPracticeScore = max(record.bestPracticeScore, score)
            totalStatsArray[0].upsertDailyRecord(record)
            session.forfeitedByLeaving = false
            return
        }
        // **No Breaks, forfeited** (§4): "backgrounding the app forfeits posting". The score
        // is kept as practice rather than thrown away - the run was really played - but it is
        // not the attempt any more, and the attempt itself was already spent when play was
        // pressed. Cleared here because a forfeit belongs to the run that earned it and the
        // next one starts clean

        if session.isScoringAttempt {
            session.isScoringAttempt = false
            record.firstAttemptScore = score
            if challenge.dateKey == session.todayKey {
                session.lastRunPosted = true
                record.pendingPost = true
                record.postedNormalisedScore =
                    DailyChallengeBoards.normalised(score: score, mode: challenge.mode)
                totalStatsArray[0].upsertDailyRecord(record)
                GameCenterHandler().submitDailyScores(dayScore: score) { landed in
                    if landed {
                        DailyChallengePosting.confirmPosted(dateKey: challenge.dateKey)
                    }
                }
                // Pending until Game Center confirms it landed (§12.5): offline, signed
                // out or a board that does not exist yet all leave the record pending,
                // and the retry loop carries it while the window is open. `posted`, the
                // badge and the overall total all wait for the confirmation - which is
                // also why the total is submitted from there, not here
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

        powerUpProbArray[1] = 0   // Lose A Ball
        powerUpProbArray[48] = 0  // Lock
        powerUpProbArray[49] = 0  // Key
        // **The power-up workbook's Daily column is the overarching rule** (James, round
        // 228). Lose A Ball, Lock and Key are marked as not available in a Daily Challenge,
        // and the reasons are the board's: losing a ball for free is luck deciding a
        // leaderboard, and a Lock that only a Key can end is a run that can be frozen for as
        // long as the day lasts if the Key never falls.
        //
        // Written out here for the three that matter today. The rest of that column wants
        // encoding beside the power-ups themselves rather than listed in this function, which
        // is queued with the bricks workbook (§12.0)

        if session.has(.fogOfWar) {
            powerUpProbArray[15] = 0  // Show Bricks
            powerUpProbArray[16] = 0  // Hide Bricks
            // **Neither falls on a fogged day** (James, round 226: "don't allow the hide
            // bricks or show bricks power-ups to fall in Daily Challenges with the fog of war
            // twist", and the workbook's own disallowed list). Show Bricks would undo the
            // twist for whoever caught it, which is the day's rules being handed back by a
            // drop roll; Hide Bricks would hide what is hidden already, which is a power-up
            // that does nothing at all
        }

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
            where GameScene.endlessIIBeneficialPowerUps.contains(index) == false {
                powerUpProbArray[index] = 0
            }
        }
        // **Each day keeps one side and nothing else** (James, round 315: "the yellow ones are
        // considered neither good nor bad. For twist days where it's good or bad power-ups
        // only, these shouldn't show up at all for either").
        //
        // **This reverses round 229 on his word**, and that round is worth reading before
        // changing it back: it moved *from* this rule *to* the other one, quoting him on Wipe
        // - "it can be considered a neutral power-up as it depends what power-ups are enabled.
        // So it can fall during both no good power-ups and no bad power-ups twists". The
        // reasoning was that which side a Wipe falls on is a property of the day rather than
        // of the power-up.
        //
        // What has changed since is the artwork. The power-up icons are colour-coded now -
        // green good, red bad, yellow neither - so neutrality is a thing the player can see
        // on the badge, and a day that says "Bad power-ups only" showing a yellow one reads as
        // the twist failing rather than as a subtlety. The screens have been promising this
        // wording all along: `.noGoodNews` describes itself as "Bad power-ups only" and
        // `.noBadNews` as "Good power-ups only", which is what this now does and is not what
        // round 229 did.
        //
        // Written as "keep one side" rather than "ban two", so a fourth category invented
        // later is excluded by default rather than silently allowed - which is the shape of
        // the fault round 229 was fixing in the first place
        if session.has(.landslide) {
            powerUpProbArray[23] = 0  // Quicksand
            // The workbook's own disallowed list. Quicksand moves the field down and leaves it
            // there, which on a day whose whole twist is the field moving down is a power-up
            // that cannot be told from the weather
        }

        if let standing = dailyAlwaysOnPowerUp {
            powerUpProbArray[standing] = 0
            for other in GameScene.endlessIIExclusiveIndicesEnded(byCollecting: standing)
                + GameScene.classicIndicesEnded(byCollecting: standing) {
                if powerUpProbArray.indices.contains(other) { powerUpProbArray[other] = 0 }
            }
            // **Both halves of the game** (James, round 340: an Always On day "shouldn't show
            // cancelling power-ups"). Mayhem's exclusions were asked and the original
            // twenty-eight were not, so a Classic day standing on Expand Paddle went on
            // dropping Shrink Paddle - and the tray has only one slot for the pair, so catching
            // it ended the day's twist. The tray's own families are that answer.
            // **Neither the standing power-up nor anything that would end it** (the workbook's
            // own disallowed list: "anything that contradicts the always on power-up / the
            // always on power-up itself"). Catching the one that is already on is a drop that
            // does nothing, and catching one that ends it is the day's twist being taken away
            // by a drop roll - which is the same objection Fog of War has to Show Bricks.
            //
            // What contradicts what is `EndlessIIExclusions`, from round 223, so this list is
            // the one the game already plays by rather than a second opinion about it
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

    /// The theme this run is played in, whatever the player usually plays in.
    ///
    /// Nil on an ordinary day, and on every day that is not a daily: the player's own three
    /// settings stand. Monochromatic forces Classic, Theme draws one from the date.
    ///
    /// One question rather than two, because both twists live in the `look` category and a
    /// day therefore has at most one of them (round 229) - the caller should not have to know
    /// that, and `userSettings` should not have to ask twice.
    /// **The colour actually goes** (round 300). This is §4's Blackout, and it turns out not
    /// to need a twist of its own: `monochromatic` has shipped since round 229 promising "All
    /// the colour is gone" in its own briefing and delivering the *Classic theme*, which is
    /// not colourless. The blurb was describing Blackout and the code was forcing a dress.
    ///
    /// `SKScene` is an `SKEffectNode` subclass, so the filter goes on the scene itself and
    /// nothing is reparented. That matters more here than it sounds: the alternative is
    /// wrapping the world in an effect node, and this game's hardest invariants are positions
    /// read straight off the scene's children (§8.6 - a brick's `position.y` is its row).
    ///
    /// The theme forcing stays. Classic is the theme whose bricks are told apart by colour, so
    /// greying *it* is the difficulty the twist was graduated from a dress for; greying a
    /// theme that already distinguishes bricks by shape would be a picture change rather than
    /// a rule change.
    var dailyMonochrome: Bool {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active else {
            return false
        }
        return challenge.twists.contains(.monochromatic)
    }

    /// Puts the run in greyscale, or takes it out again.
    ///
    /// Idempotent and called from one place, so a resumed run and a fresh one arrive at the
    /// same screen - a filter left on from a previous scene would be the worse failure, since
    /// nothing else in the game would look wrong enough to notice.
    ///
    /// **The cost was measured before it was built** (round 284): a full field through
    /// `CIPhotoEffectMono` costs 1.82x the unfiltered draw, 1.69ms against 3.08ms, on this
    /// Mac's GPU through the simulator. Both numbers are small, and the ratio is the honest
    /// part - the oldest supported iPhone is a different machine and there is not one to hand.
    func applyDailyMonochrome() {
        guard dailyMonochrome else {
            shouldEnableEffects = false
            filter = nil
            return
        }
        filter = CIFilter(name: "CIPhotoEffectMono")
        shouldEnableEffects = true
    }

    var dailyForcedTheme: Int? {
        guard isDailyChallenge else { return nil }
        return DailyTwist.forcedTheme(for: DailyChallengeSession.shared.active)
    }

    /// The power-up that is on all day, or nil on a day that is not an Always On day.
    var dailyAlwaysOnPowerUp: Int? {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active,
              challenge.twists.contains(.alwaysOn) else { return nil }
        return DailyTwist.alwaysOnPowerUp(forKey: challenge.dateKey, mode: challenge.mode)
    }

    /// Puts the day's standing power-up back the moment it stops.
    ///
    /// **Re-collected rather than made unending**, which is the whole reason this is three
    /// lines instead of forty. Every one of the lasting power-ups already knows how to start
    /// itself, in the one switch that has mapped a power-up to its effect since 2020; teaching
    /// forty of them a second, permanent mode would be forty chances to teach one of them
    /// wrongly. Asking "is it still running, and if not, collect it again" reuses the mapping
    /// that is already right.
    ///
    /// What is running is `activeRecentPowerUpIndices`, which is the same question the pause
    /// screen asks and answers for both halves of the game - the old tray bars and Mayhem's
    /// own clocks.
    func tickDailyAlwaysOn() {
        guard let index = dailyAlwaysOnPowerUp else { return }
        guard gameState.currentState is Playing, isPaused == false else { return }
        guard dailyStandingPowerUpIsRunning(index) == false else { return }
        guard powerUpTextureArray.indices.contains(index) else { return }

        let carrier = SKSpriteNode(texture: powerUpTextureArray[index])
        applyPowerUp(node: carrier, silently: true, standing: true)
        // Through a carrier sprite because the switch reads a texture, which is the identity
        // every collection in the game is decided by. Silently, because nothing here is a
        // catch: no sound, no haptic, no statistic, and nothing taken off the count of
        // power-ups on screen - the player caught this one once, this morning, by opening the
        // day
    }

    /// Whether the day's standing power-up is running now.
    ///
    /// **James, round 341: the Always On power-up "was failing to activate".** It was being
    /// collected sixty times a second. This used to ask `activeRecentPowerUpIndices`, which
    /// answers the pause screen's question - *which* of a tray slot's two power-ups was caught
    /// - by looking the slot up in the list of power-ups recently caught. An Always On
    /// collection is silent and is never in that list, so for a slot that holds two (Shrink
    /// Ball shares one with Expand Ball) the answer was "neither", every frame, and the tick
    /// collected it again every frame. Measured on the simulator: `active []` against a lit bar.
    ///
    /// The tray's own bar is the honest answer here, because on an Always On day the other
    /// power-up in the slot cannot drop (`classicIndicesEnded(byCollecting:)`) - a lit bar in
    /// the standing power-up's slot can only be the standing power-up. Mayhem's own power-ups
    /// have exact clocks and are asked of them, as before.
    func dailyStandingPowerUpIsRunning(_ index: Int) -> Bool {
        if let slot = GameScene.trayPowerUpFamilies.firstIndex(where: { $0.contains(index) }),
           iconTimerArray.indices.contains(slot) {
            let bar = iconTimerArray[slot]
            return bar.isHidden == false && (bar.xScale > 0.001 || bar.hasActions())
            // **Or still growing.** A collection shows the bar at no width and grows it to full
            // over a twentieth of a second before the countdown starts, and a bar at no width
            // reads as not running - which on Shrink Ball meant a second collection in that
            // twentieth, from three quarters of the size to half, and the smallest-ball
            // achievement handed out by the twist
        }
        return activeRecentPowerUpIndices().contains(index)
    }

    /// How long a Landslide waits between rows.
    ///
    /// Slower than Mayhem's own cadence on purpose. Classic's levels are built to be cleared
    /// from a standing start, not defended, so a field arriving at the pace Mayhem's does
    /// would end most levels before they could be read.
    static let dailyLandslideStep: TimeInterval = 6

    /// Whether enough has passed for the field to take another step.
    ///
    /// Pure, and tested as such: the tick that asks it stands down unless the scene is in
    /// `Playing`, which a scene built in a test is not - so the cadence would otherwise be the
    /// one part of this that nothing could check.
    static func landslideIsDue(now: TimeInterval, lastStep: TimeInterval) -> Bool {
        lastStep != 0 && now - lastStep >= GameScene.dailyLandslideStep
    }

    /// Whether the day's field is coming down.
    var dailyLandslide: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.landslide)
    }

    /// The line a Classic brick wraps at, and the row it comes back on.
    ///
    /// The floor is a paddle's own gap above the paddle, which is the same line
    /// `bricksAreAtTheBottom` has always drawn. The ceiling is the level's top row, where the
    /// grid was built.
    var dailyLandslideFloor: CGFloat { paddle.position.y + minPaddleGap }
    var dailyLandslideCeiling: CGFloat { yBrickOffset }

    /// Steps the whole field down one row every few seconds, for ever.
    ///
    /// **A brick that reaches the bottom comes back at the top** (James, round 231: "if a
    /// brick makes it to the bottom un-hit, it should wrap around back to the top. This way
    /// the level doesn't end once all the bricks vanish off the bottom"). That is what makes
    /// this a twist rather than a countdown: the field is a conveyor, the level cannot empty
    /// itself by falling past the paddle, and the only way to clear it is still to hit it.
    ///
    /// It also settles a question Classic has never had to answer. Mayhem's descent is
    /// pressure rather than a death rule, and Classic has no lower limit to destroy bricks at
    /// - so a landslide that simply kept going would push bricks through the paddle, and one
    /// that ended the run on arrival would be inventing a way to lose. Wrapping is neither: the
    /// field keeps coming, and what it costs the player is room and time.
    ///
    /// Driven from `update` rather than a repeating action, the way everything in this game
    /// that moves bricks is: `countBricks` gates on a brick having no actions, and a brick
    /// carrying a permanent one would stop the field being counted for ever (§8.6).
    func tickDailyLandslide(_ currentTime: TimeInterval) {
        guard dailyLandslide, gameState.currentState is Playing, isPaused == false else {
            dailyLandslideLastStep = currentTime
            return
        }
        if dailyLandslideLastStep == 0 { dailyLandslideLastStep = currentTime }
        guard GameScene.landslideIsDue(now: currentTime,
                                       lastStep: dailyLandslideLastStep) else { return }
        dailyLandslideLastStep = currentTime

        let floor = dailyLandslideFloor
        let ceiling = dailyLandslideCeiling
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
            if brick.position.y - self.brickHeight < floor {
                brick.position.y = ceiling
                brick.alpha = 0
                brick.run(.fadeIn(withDuration: 0.25))
                // Written straight up rather than glided, and faded in where it lands: a brick
                // travelling the height of the field would be a brick between rows for most of
                // a second, and a brick's `position.y` is its row (§8.6). Appearing is the
                // honest picture anyway - it has come round, not flown home
            } else {
                brick.run(.moveBy(x: 0, y: -self.brickHeight, duration: 0.25))
            }
        }
        if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.5) }
        if soundsSetting { run(endlessRowDownSound) }
        // The same step and the same sound the endless modes use, because it is the same
        // event: a player who has met one should recognise the other
    }

    /// Whether the day takes the pause button away.
    ///
    /// §4's nerve twist: "The pause button is disabled for the run. Backgrounding the app
    /// forfeits posting."
    var dailyNoPausing: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.noPausing)
    }

    /// Whether the player may pause at all right now.
    ///
    /// One question for both routes in - the button and the swipe - because a twist that
    /// closed the button and left the gesture open would be no twist at all, and the two
    /// checks are three hundred lines apart.
    var dailyPausingIsAllowed: Bool { dailyNoPausing == false }

    /// Gives up the day's attempt because the player left the app.
    ///
    /// **The run carries on.** Ending somebody's game from the outside is worse than not
    /// scoring it, and the twist is about nerve rather than punishment - so the ball stays in
    /// play and what is lost is the posting. Called from the same notification that pauses
    /// every other run when the app goes to the background: on a No Breaks day that
    /// notification cannot be allowed to pause, because the app pausing itself would hand the
    /// player exactly what the twist withholds.
    ///
    /// Nothing to undo. A forfeited attempt stays forfeited for the rest of the run, which is
    /// the point - coming back does not give it back.
    func dailyForfeitByLeaving() {
        guard dailyNoPausing else { return }
        DailyChallengeSession.shared.forfeitedByLeaving = true
    }

    /// Which way the day turns the level over, if it does.
    var dailyLayoutFlip: DailyTwist? {
        guard isDailyChallenge else { return nil }
        return DailyTwist.layoutFlip(in: DailyChallengeSession.shared.active?.twists ?? [])
    }

    /// Turns the day's level over, before anything is built from it.
    ///
    /// **Layout only, and only on a fresh field.** The bricks arrive already placed - every
    /// `loadLevelN` sets `position` and hands the array over - so one reflection here reaches
    /// all hundred-odd levels without touching any of them. A *resumed* run must not be
    /// flipped again: the save holds the positions the player left, which are the flipped
    /// ones, and a second reflection would put the level back the way it was drawn.
    ///
    /// The two reflections are not the same kind of reflection, and that is the whole of it.
    /// **Mirrored** is about the field's own centre line, because a shape that sat on the
    /// left is meant to end up on the right - that is the twist. **Upside Down** is about the
    /// middle of the rows the level actually *occupies*: reflecting about the whole grid
    /// instead would drop a level that only fills the top third straight into the player's
    /// lap, which is a different game rather than the same one seen upside down.
    ///
    /// Both land every brick exactly on a cell centre, which matters even in Classic - the
    /// grid arithmetic elsewhere reads a brick's position as its cell.
    func applyDailyLayoutFlip(to bricks: [SKNode]) {
        guard savedGame == nil, let flip = dailyLayoutFlip else { return }

        let placed = bricks.compactMap { $0 as? SKSpriteNode }
            .filter { $0.texture != brickNullTexture }
        guard placed.isEmpty == false else { return }
        // Empty cells are dropped by `brickCreation` anyway, and counting them would make
        // the occupied band the whole grid - which is exactly the reflection to avoid

        switch flip {
        case .mirrored:
            for brick in bricks { brick.position.x = -brick.position.x }
            // A negation, because the columns are laid out symmetrically about x = 0
        case .upsideDown:
            let lowest = placed.map(\.position.y).min()!
            let highest = placed.map(\.position.y).max()!
            for brick in bricks {
                brick.position.y = DailyLayout.flippedY(brick.position.y,
                                                        lowest: lowest, highest: highest)
            }
        default:
            return
        }
    }

    /// Whether the day is a Time Trial.
    var dailyTimeTrial: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.timeTrial)
    }

    /// Whether losing the ball costs a life.
    ///
    /// It always did, and on a Time Trial day it should not: the workbook's Details column for
    /// the twist says "unlimited lives" in as many words. Ninety seconds is the whole of the
    /// challenge, and a day that took the clock *and* the lives was two limits where the design
    /// asks for one - a bad start ended the attempt with a minute of it left on the board.
    ///
    /// A free function rather than a line inside the ball-loss path, because that path cannot
    /// be stood up in a test and this is the part worth pinning.
    static func dailyLifeIsSpent(onTimeTrial timeTrial: Bool) -> Bool { timeTrial == false }

    /// Builds the countdown into the HUD, on the multiplier's row and to its left.
    ///
    /// **James, round 340: "in the time trial, the countdown timer should be to the left of
    /// the multiplier, and have an 's' after the number."** It was centred under the power-up
    /// tray, which put the one number that is counting *down* in the middle of the field on
    /// its own, away from the two that count up. The HUD's numbers belong together: the score,
    /// the multiplier under it, and now the clock beside the multiplier.
    ///
    /// **Not centre-top beside the pause button**, which was the first try - that spot reads
    /// as free in the scene file and is exactly where the Dynamic Island sits on the device.
    /// It is the same lesson the old mode icon learned (its removal comment says "directly
    /// under the notch"), and the first screenshot of a Time Trial run showed a clock that
    /// was there and invisible.
    func setupDailyClock() {
        guard dailyTimeTrial, dailyClockLabel == nil else { return }
        let clock = SKLabelNode(fontNamed: multiplierLabel.fontName)
        clock.fontSize = multiplierLabel.fontSize
        clock.fontColor = scoreLabel.fontColor
        clock.zPosition = 10
        addChild(clock)
        dailyClockLabel = clock
        placeTheDailyClock()
        showDailyClock()
    }

    /// Puts the clock a fixed gap to the left of the multiplier, whatever the multiplier says.
    ///
    /// The multiplier is drawn as a strip of placed characters rather than as the label's own
    /// text, so the label's frame says nothing about how wide it is. `FixedWidthDigits` is
    /// what places those characters, and asking it the same question gives the width actually
    /// drawn - which is the only way a label to the left of it can know where its right edge
    /// belongs.
    func placeTheDailyClock() {
        guard let clock = dailyClockLabel else { return }
        clock.horizontalAlignmentMode = .right
        clock.verticalAlignmentMode = multiplierLabel.verticalAlignmentMode
        // Set here rather than where the label is built, because the geometry below only means
        // anything if the clock grows leftwards: its right edge is what is being placed
        let drawn = UIFont(name: multiplierLabel.fontName ?? "", size: multiplierLabel.fontSize)
            .map { FixedWidthDigits.layout(multiplierShown.isEmpty ? "x1.0" : multiplierShown,
                                           font: $0).width } ?? 0
        clock.position = CGPoint(x: multiplierLabel.position.x - drawn - labelSpacing*2,
                                 y: multiplierLabel.position.y)
        // Twice the label spacing, which is the gap the HUD keeps between the pause button and
        // the score on the row above: near enough to read as one row, far enough that a
        // two-figure clock and a rising multiplier never touch
    }

    /// Runs the whistle's clock. From `update`, every frame, in every mode.
    ///
    /// **The clock runs from the first launch until the whistle, stopping only for a pause**
    /// (James, round 346: "the countdown clock stops when the ball is caught by a sticky paddle
    /// - it should always continue to count down unless the game is paused").
    ///
    /// It used to stop whenever the ball was on the paddle, to make the ninety seconds seconds
    /// of play rather than of hesitation - and a sticky catch is the ball on the paddle, so a
    /// Sticky Paddle quietly bought time: hold the ball, and the clock held too. It waits only
    /// for the first serve now, so reading the field before the run starts is free and nothing
    /// after it is. The pause guard matters on the days that can pause; on a No Breaks Time
    /// Trial there is no pause to hold it.
    func tickDailyTimeTrial(_ delta: TimeInterval) {
        guard dailyTimeTrial, gameoverStatus == false,
              gameState.currentState is Playing, isPaused == false else { return }
        dailyTimeTrialUnderway = GameScene.timeTrialUnderway(already: dailyTimeTrialUnderway,
                                                            ballOnPaddle: ballIsOnPaddle)
        guard dailyTimeTrialUnderway else { return }
        guard spendDailyTimeTrial(delta) else { return }

        gameoverStatus = true
        removeAction(forKey: "gameTimer")
        levelTimerBonus = 0
        gameState.enter(InbetweenLevels.self)
        // The whistle ends the run the way running out of lives does - the same flag, the
        // same state - so everything downstream (the daily result, the game-over screen,
        // posting) treats it as a run that finished rather than a special case. The score
        // at the whistle is the score, which is the whole twist
    }

    /// Whether the Time Trial's clock is running, given whether it already was and where the
    /// ball is: from the first moment the ball leaves the paddle, for good (round 346). A ball
    /// caught on a sticky paddle afterwards does not stop it.
    static func timeTrialUnderway(already: Bool, ballOnPaddle: Bool) -> Bool {
        already || ballOnPaddle == false
    }

    /// Spends flight time off the clock, and reports whether the whistle blew.
    ///
    /// Split from the tick so the arithmetic can be tested without a state machine - the
    /// guards above need a scene mid-game, and the counting does not.
    func spendDailyTimeTrial(_ delta: TimeInterval) -> Bool {
        dailyTimeTrialRemaining = max(0, dailyTimeTrialRemaining - delta)
        showDailyClock()
        return dailyTimeTrialRemaining <= 0
    }

    /// Says what is left, in whole seconds, turning urgent for the last ten.
    ///
    /// With its unit on it (James, round 340: "have an 's' after the number"). The number sits
    /// beside a multiplier that wears its own "x", and a bare figure in that company reads as
    /// a second score.
    func showDailyClock() {
        guard let clock = dailyClockLabel else { return }
        let seconds = Int(dailyTimeTrialRemaining.rounded(.up))
        clock.text = "\(seconds)s"
        clock.fontColor = seconds <= 10 ? .red : scoreLabel.fontColor
        countDownTheLastSeconds(seconds)
        placeTheDailyClock()
        // Placed again on every tick, because the multiplier beside it changes width when it
        // climbs past x10 and the clock's own right edge is measured from it
    }

    /// Three, two, one, over the field, as the Time Trial's last seconds go.
    ///
    /// **James, round 341: "create a 3, 2, 1 graphic for the end of a time trial too that plays
    /// in the final few seconds in the same style as the ready, go animation when resuming" -
    /// with "simple timing beeps" under it.** The clock in the corner turns red for the last
    /// ten, which is a thing to notice if you are looking at the corner, and nobody is: the
    /// ball is in the middle of the screen. The whistle was arriving unannounced.
    ///
    /// Shown once per second rather than once per frame: `showDailyClock` runs on every tick,
    /// and the number is only news the frame it changes.
    func countDownTheLastSeconds(_ seconds: Int) {
        guard dailyTimeTrial, seconds != dailyCountdownShown else { return }
        dailyCountdownShown = seconds
        guard (1...GameScene.dailyCountdownFrom).contains(seconds),
              dailyTimeTrialRemaining < TimeInterval(GameScene.dailyCountdownFrom) + 0.99
        else { return }
        // The second clause keeps a fresh run at ninety from counting anything, and a resume
        // that lands on three from announcing a second it has already half spent twice

        let digit = dailyCountdownNode ?? {
            let node = SKSpriteNode()
            node.zPosition = readyCountdown.zPosition
            node.position = readyCountdown.position
            addChild(node)
            dailyCountdownNode = node
            return node
        }()
        let picture = GameScene.countdownDigit("\(seconds)", height: readyCountdown.size.height)
        digit.texture = SKTexture(image: picture)
        digit.size = picture.size
        digit.removeAllActions()
        digit.isHidden = false
        digit.setScale(2)
        digit.alpha = 0
        digit.run(.sequence([
            .group([.scale(to: 1, duration: 0.25), .fadeIn(withDuration: 0.25)]),
            .wait(forDuration: 0.45),
            .group([.scale(to: 0.5, duration: 0.25), .fadeOut(withDuration: 0.25)]),
            .hide(),
        ]))
        // READY's own three steps - in from double size, a hold, out to half - over a second,
        // so each number has gone before the next arrives
        playMayhemSound("countdownTick")
    }

    /// How many of the last seconds are counted aloud.
    static let dailyCountdownFrom = 3

    /// A number drawn the way READY and GO! are drawn: pale lime, a lime edge, a lime glow,
    /// in the face the game's own numbers wear.
    ///
    /// Drawn rather than delivered as three more pictures because the three pictures would be
    /// this, and a drawing made here cannot fall out of step with a theme or a size the way a
    /// set of files can. READY's letters are about three fifths of its picture's height, and
    /// these numbers are set to match them, so a three standing where READY stood is the same
    /// size of thing.
    static func countdownDigit(_ text: String, height: CGFloat) -> UIImage {
        let lime = UIColor(red: 0.8235, green: 1, blue: 0, alpha: 1)
        let pale = UIColor(red: 0.96, green: 1, blue: 0.86, alpha: 1)
        let font = UIViewController.gameScoreFont(ofSize: (height*0.62/0.72).rounded())
        let glow = NSShadow()
        glow.shadowColor = lime.withAlphaComponent(0.9)
        glow.shadowBlurRadius = height*0.14
        glow.shadowOffset = .zero

        let drawn = NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: pale,
            .strokeColor: lime, .strokeWidth: -6, .shadow: glow,
        ])
        let measured = drawn.size()
        let canvas = CGSize(width: ceil(measured.width + height*0.5), height: height)
        return UIGraphicsImageRenderer(size: canvas).image { _ in
            let origin = CGPoint(x: (canvas.width - measured.width)/2,
                                 y: (canvas.height - measured.height)/2)
            drawn.draw(at: origin)
            drawn.draw(at: origin)
            // Twice, so the glow is as strong as READY's rather than a single soft pass
        }
    }

    /// How much more often a brick takes a style on a Extra Mayhem day.
    ///
    /// Three, against an opening chance of 4-in-100 ramping to 22: the opening plays like the
    /// mid-game and the mid-game like the depths, without the field ever becoming the wall of
    /// set pieces a x10 would make of it. The stacking roll is deliberately left alone - more
    /// bricks doing *something* is the twist; more bricks doing two things at once is a
    /// different, nastier day nobody asked for.
    static let dailyMayhemBricksFactor = 3

    /// Whether the day turns the style dial up.
    var dailyMayhemBricks: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.mayhemBricks)
    }

    /// The day's word on a style chance the progression just computed.
    func dailyStyledChance(_ chance: Int) -> Int {
        dailyMayhemBricks ? min(85, chance*GameScene.dailyMayhemBricksFactor) : chance
        // Capped where a motif phase sits, which is the loudest the field ever legitimately
        // gets - the twist may match the game's own maximum, never exceed it
    }

    /// The day's brick remap, when Brick Swap is on. Nil otherwise.
    var dailyBrickSwap: DailyTwist.DailyBrickSwap? {
        guard isDailyChallenge, DailyChallengeSession.shared.has(.brickSwap),
              let key = DailyChallengeSession.shared.active?.dateKey else { return nil }
        return DailyTwist.DailyBrickSwap.drawn(forKey: key)
    }

    /// Remaps the day's brick types, before anything is measured off them.
    ///
    /// Same shape as the layout flip and applied at the same door: the levels hand their
    /// bricks over with textures already set, so one pass in `brickCreation` reaches all of
    /// them, and a *resumed* run must not be touched - the save carries the swapped textures
    /// already, and swapping again would double-apply a remap whose source type still exists.
    ///
    /// The textures are compared and assigned through the scene's own properties rather than
    /// named constants, because the Retro theme swaps those properties at load - a remap
    /// written against the standard art would quietly un-theme every brick it touched.
    ///
    /// **If the drawn remap finds nothing to change, the field is hardened instead.** A level
    /// with no multi-hit bricks on a Softened day would be a twist that visibly does nothing,
    /// and "does nothing" reads as broken (§8.6's lesson about pools, one door over). Still
    /// deterministic: the fallback depends only on the day and the level.
    func applyDailyBrickSwap(to bricks: [SKNode]) {
        guard savedGame == nil, let swap = dailyBrickSwap else { return }

        let sprites = bricks.compactMap { $0 as? SKSpriteNode }
        let applied = applyBrickSwapPass(swap, to: sprites)
        if applied == false, swap != .hardened {
            _ = applyBrickSwapPass(.hardened, to: sprites)
        }
    }

    /// One remap over the field. Returns whether it changed anything.
    func applyBrickSwapPass(_ swap: DailyTwist.DailyBrickSwap,
                                    to sprites: [SKSpriteNode]) -> Bool {
        var touched = false
        for brick in sprites {
            switch swap {
            case .hardened where brick.texture == brickNormalTexture:
                brick.texture = brickMultiHit3Texture
                brick.color = .white
                // The level painted this brick through `colorBlendFactor`, which
                // `brickCreation` only turns on for normals - but the *colour* stays set,
                // and a multi-hit texture with a stale blend reads tinted. White is inert
            case .softened where brick.texture == brickMultiHit1Texture
                            || brick.texture == brickMultiHit2Texture
                            || brick.texture == brickMultiHit3Texture:
                brick.texture = brickNormalTexture
            case .veiled where brick.texture == brickNormalTexture:
                brick.texture = brickInvisibleTexture
                // `brickCreation`'s own invisible check runs after this pass and hides it,
                // the same way it hides a level's authored invisibles
            default:
                continue
            }
            touched = true
        }
        return touched
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

            guard dailyFogHasClosed == false else {
                brick.isHidden = true
                continue
            }
            // A row arriving mid-run is fogged the moment it exists. The look below is the
            // *opening* field's, and a row that showed itself every time one was generated
            // would not be a fog at all

            dailyFogPending.append(brick)
        }
    }

    /// Takes the opening field away, once the player has had a look at it.
    ///
    /// Fog of War used to hide the field at creation, so a fogged day opened on an empty
    /// screen and the first shot was blind (queued from the ninth play-test round: the level
    /// should show its hand first). The bricks now build in visible, hold for a beat, and
    /// fade out together - so you get one look at what you are about to lose sight of, which
    /// is the difference between a twist and a blindfold.
    ///
    /// Called when the build-in finishes, however it finished: a skipped build-in still gets
    /// its look, just a shorter one. Idempotent, because all three of those paths can be
    /// reached in one run.
    ///
    /// Since round 140 this is the *sweeper* rather than the whole of it: a build-in fogs
    /// each brick as it lands, and what reaches here is whatever the build-in never owned -
    /// a field built with no animation at all, or the bricks left over when a tap skipped
    /// the build-in halfway down.
    func closeDailyFog(animated: Bool = true) {
        guard dailyFogIsOn, dailyFogHasClosed == false else { return }
        dailyFogHasClosed = true

        let showing = dailyFogPending
        dailyFogPending.removeAll()
        guard showing.isEmpty == false else { return }

        guard animated else {
            for brick in showing { brick.isHidden = true }
            return
        }
        // Without the look, for tests: what the fade arrives at is the part worth asserting,
        // and a test that waited out the animation would be a test about a timer

        for brick in showing where brick.parent != nil {
            dailyFogTaking.append(brick)
            brick.run(.sequence([
                .wait(forDuration: GameScene.dailyFogLook),
                .fadeOut(withDuration: GameScene.dailyFogClose),
                .run { [weak self] in
                    brick.isHidden = true; brick.alpha = 1
                    self?.dailyFogTaken(brick)
                },
            ]))
            // Hidden *and* returned to full alpha at the end: `revealDailyFog` fades a
            // struck brick back in from zero, and a brick left on alpha zero would be
            // revealed to nothing
        }
    }

    /// How long a row is readable before the fog takes it, and how long the fog takes.
    ///
    /// Long enough to look at and too short to memorise. The twist is meant to make you
    /// remember a field rather than read one, and a fade that lingered would hand back most
    /// of what the twist takes away.
    ///
    /// **Much shorter than they were** (play-test round 126: "I was able to start playing
    /// before the bricks disappeared", and the fog should be "faster and foggier"). A look
    /// of 1.1 seconds and a fade of 0.55 measured from the *end* of the build-in meant the
    /// field was still going when the first ball was already in it.
    static let dailyFogLook: TimeInterval = 0.45
    static let dailyFogClose: TimeInterval = 0.3

    /// Takes at once whatever the fog was still taking gently.
    ///
    /// James, round 177: "if fog of war twist is in play, at the start if the player launches
    /// the ball before the fade out animation has finished, make all the bricks disappear
    /// immediately." The look and the fades exist to show the field *before* play starts; a
    /// player who launches early has declared the look over, and a field still fading around
    /// a live ball hands back sight the twist is meant to have taken.
    ///
    /// Called from `releaseBall`, so it covers every launch - which is also why it must only
    /// touch what the fog still owns: `dailyFogTaking` (scheduled or mid-fade) and
    /// `dailyFogPending` (never scheduled at all), never the bricks a strike has revealed,
    /// which a later launch must not take back. Hiding a brick whose fade is mid-flight is
    /// safe: the fade's own completion sets the same two values this does, and the scheduled
    /// closes that have not started yet check `isHidden` and stand down.
    func snapDailyFogShut() {
        guard dailyFogIsOn else { return }
        for brick in dailyFogTaking where brick.parent != nil {
            brick.isHidden = true
            brick.alpha = 1
        }
        dailyFogTaking.removeAll()

        guard dailyFogHasClosed == false else { return }
        dailyFogHasClosed = true
        for brick in dailyFogPending where brick.parent != nil {
            brick.isHidden = true
        }
        dailyFogPending.removeAll()
        // The sweeper's own job, done without the look: a launch this early means the
        // build-in is still running, and rows still to land arrive fogged through
        // `applyDailyFog`'s closed-fog branch
    }

    /// Fogs one brick a beat after it has landed, rather than waiting for the whole field.
    ///
    /// This is the answer to playing before the fog closed: the fog no longer starts when
    /// the build-in ends, it travels down the field with it. A row is taken while the rows
    /// below it are still arriving, so the last brick to land is the last to fade and the
    /// field is gone by the time it is whole (play-test round 126: "fading row by row as the
    /// rows below build in"). You still get your look - one row at a time, which is what
    /// makes a fogged field something you remember rather than something you read.
    ///
    /// Scheduled from the scene and only the fade itself run on the brick, because
    /// `countBricks()` gates row generation on a brick having no actions (§8.6) - a wait of
    /// most of a second attached to a brick would hold the field's descent for that long.
    func scheduleDailyFog(for brick: SKSpriteNode, landingAt arrival: TimeInterval) {
        guard dailyFogIsOn, dailyFogHasClosed == false else { return }
        guard let index = dailyFogPending.firstIndex(where: { $0 === brick }) else { return }
        dailyFogPending.remove(at: index)
        dailyFogTaking.append(brick)
        // In the taking list until its fade lands it hidden - `snapDailyFogShut` reads this

        run(.sequence([
            .wait(forDuration: arrival + GameScene.dailyFogLook),
            .run { [weak self] in
                guard let self, brick.parent != nil, brick.isHidden == false else { return }
                guard self.dailyFogIsOn else { return }
                brick.run(.sequence([
                    .fadeOut(withDuration: GameScene.dailyFogClose),
                    .run { [weak self] in
                        brick.isHidden = true; brick.alpha = 1
                        self?.dailyFogTaken(brick)
                    },
                ]))
            },
        ]))
    }

    /// Strikes one brick off the taking list, once the fog has it (or a hit saved it).
    ///
    /// Without this the list only ever grows, and `snapDailyFogShut` on a *later* launch
    /// would re-hide bricks the fog had long finished with - including any a strike had
    /// revealed since, which is exactly what a reveal promises cannot happen.
    func dailyFogTaken(_ brick: SKSpriteNode) {
        if let index = dailyFogTaking.firstIndex(where: { $0 === brick }) {
            dailyFogTaking.remove(at: index)
        }
    }

    /// Brings one brick out of the fog, spending the strike on the reveal. Returns
    /// whether it did, so the caller stops there.
    ///
    /// The fog borrows the invisible bricks' own convention (§4): the first strike shows
    /// you the brick and costs the hit; what the brick does about being hit starts from
    /// the second. The first fix revealed *before* the type switch without spending the
    /// strike - which unhid a brick straight into its own destroy branch, so a fogged
    /// field's bricks died mid-fade and "no bricks appeared when hit" (the fifth round's
    /// report). Only the types whose own switch branches already reveal-and-stop are
    /// left to themselves; everything else - multi-hits, Indestructibles, Portals,
    /// power-up bricks - is revealed here, because their own rules never look at the
    /// hidden flag.
    func revealDailyFog(_ brick: SKSpriteNode) -> Bool {
        guard dailyFogIsOn, brick.isHidden else { return false }

        let ownBranchReveals = brick.endlessIIRole != .portal
            && brick.endlessIIPowerUpIndex == nil
            && [brickMultiHit1Texture, brickMultiHit2Texture, brickMultiHit3Texture,
                brickMultiHit4Texture, brickIndestructible1Texture,
                brickIndestructible2Texture].contains(brick.texture) == false
        guard ownBranchReveals == false else { return false }
        // Normal-shaped bricks (styled ones included) and the invisible texture reach
        // switch branches that already do first-hit-reveals-only - the fog leans on them

        dailyFogTaken(brick)
        // Out of the taking list, or a later launch's snap would take back what this
        // strike has just given

        brick.isHidden = false
        brick.alpha = 0
        brick.run(.fadeIn(withDuration: 0.2))
        // The same fade an invisible brick has always come back with
        return true
    }
}


/// The layout twists' arithmetic, apart from the scene so it can be tested without one.
enum DailyLayout {

    /// Where a brick goes when the level is turned upside down.
    ///
    /// Reflected about the midpoint of the occupied band: `lowest` and `highest` swap, and
    /// everything between them trades places evenly. Because the rows are evenly spaced,
    /// every answer is a row centre - which is the property the rest of the game relies on.
    static func flippedY(_ y: CGFloat, lowest: CGFloat, highest: CGFloat) -> CGFloat {
        lowest + highest - y
    }
}
