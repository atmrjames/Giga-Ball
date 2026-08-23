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
        // Five balls total, four of them racked. Retired from the pool in round 228 - Extra
        // Balls covers it - but a hand-built challenge still means what it says
        if DailyChallengeSession.shared.has(.suddenDeath) { return 0 }
        // Sudden Death in Classic is One Life by another name; in the endless modes it
        // has its own teeth (see endlessIIBallWasLost's gate). Retired in round 228 for
        // exactly that reason, and still honoured if a challenge asks for it
        if DailyChallengeSession.shared.has(.spareBalls) {
            return endlessMode ? 2 : numberOfLives + 2
        }
        // **Two more than the mode's own rack** (round 228's workbook: "two extra balls are
        // provided"). In the endless modes the rack is empty, so two more is a rack of two;
        // in Classic it is two on top of whatever the level would have given, which is the
        // only reading under which the same twist means the same thing in both
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
        if session.forfeitedByLeaving {
            session.isScoringAttempt = false
            record.bestPracticeScore = max(record.bestPracticeScore, score)
            totalStatsArray[0].upsertDailyRecord(record)
            session.forfeitedByLeaving = false
            return
        }
        // **No Pausing, forfeited** (§4): "backgrounding the app forfeits posting". The score
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
            where GameScene.endlessIIBeneficialPowerUps.contains(index) {
                powerUpProbArray[index] = 0
            }
        }
        if session.has(.noBadNews) {
            for index in powerUpProbArray.indices
            where GameScene.endlessIIHarmfulPowerUps.contains(index) {
                powerUpProbArray[index] = 0
            }
        }
        // **Each bans one side and leaves the middle alone** (round 229). No Good News used to
        // zero everything that was not *harmful*, which is not the same sentence: it took the
        // neutral ones down with the good, so a Mystery could not fall on a bad-news day and a
        // Wipe could fall on neither. The workbook says it plainly - No Bad News disallows the
        // -0.1 chips, No Good News disallows the +0.1 chips - and a power-up with no chip is
        // disallowed by neither
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
    var dailyForcedTheme: Int? {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active else {
            return nil
        }
        if challenge.twists.contains(.monochromatic) { return 0 }
        if challenge.twists.contains(.dailyTheme) {
            return DailyTwist.dailyThemeIndex(forKey: challenge.dateKey,
                                                  themeCount: LevelPackSetup().themeNameArray.count)
        }
        return nil
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
    /// every other run when the app goes to the background: on a No Pausing day that
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

    /// Builds the countdown into the HUD: centred, just below the power-up tray.
    ///
    /// **Not centre-top beside the pause button**, which was the first try - that spot reads
    /// as free in the scene file and is exactly where the Dynamic Island sits on the device.
    /// It is the same lesson the old mode icon learned (its removal comment says "directly
    /// under the notch"), and the first screenshot of a Time Trial run showed a clock that
    /// was there and invisible. Below the tray is real screen on every device, and a HUD
    /// label floating over the field's top rows is what every HUD label already does.
    func setupDailyClock() {
        guard dailyTimeTrial, dailyClockLabel == nil else { return }
        let clock = SKLabelNode(fontNamed: scoreLabel.fontName)
        clock.fontSize = scoreLabel.fontSize
        clock.fontColor = scoreLabel.fontColor
        clock.verticalAlignmentMode = .top
        clock.position = CGPoint(
            x: 0,
            y: powerUpTray.position.y - powerUpTray.size.height/2 - labelSpacing/2)
        clock.zPosition = 10
        addChild(clock)
        dailyClockLabel = clock
        showDailyClock()
    }

    /// Runs the whistle's clock. From `update`, every frame, in every mode.
    ///
    /// **The clock runs while the ball is live**: Playing, not paused, ball off the paddle.
    /// A ball waiting on the paddle does not count down, so the ninety seconds are seconds
    /// of play rather than seconds of hesitation - and a life lost buys the moment of reset
    /// back. The pause guard matters on the days that can pause; on a No Pausing Time Trial
    /// there is no pause to hold it.
    func tickDailyTimeTrial(_ delta: TimeInterval) {
        guard dailyTimeTrial, gameoverStatus == false,
              gameState.currentState is Playing, isPaused == false,
              ballIsOnPaddle == false, endlessIIAimHold == false
        else { return }
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
    func showDailyClock() {
        guard let clock = dailyClockLabel else { return }
        let seconds = Int(dailyTimeTrialRemaining.rounded(.up))
        clock.text = "\(seconds)"
        clock.fontColor = seconds <= 10 ? .red : scoreLabel.fontColor
    }

    /// How much more often a brick takes a style on a Mayhem Bricks day.
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
