//
//  EndlessIIFieldPowerUps.swift
//  Megaball
//
//  Phase 8c: the power-ups that act on the field rather than on the ball.
//
//  Seven of the batch's eight. Three are instants - Cull takes half the field at random,
//  Laser Beam burns one column per ball, and Infill (the bad one) fills empty cells with new
//  bricks. Four run on clocks: Wrecking Ball makes every hit lethal while still bouncing,
//  Aura destroys what the glow around each ball touches, Descent drives the field's own
//  one-row step on a timer, and Retreat lifts the whole field two rows and then holds it
//  there - which is the half of it that used to be missing.
//
//  Wrap-Around is the eighth, and it is deliberately not here yet: it asks the side walls
//  to stop being walls - for the paddle and Moving bricks and explosions too - and that is
//  its own careful visit rather than a corner of this file.
//
//  Everything destroys through the same pair a crush uses - roles react, nothing rolls a
//  power-up - except the Wrecking Ball, whose hits are ordinary hits that happen to win:
//  those score, roll and count exactly like the ball's own.
//

import SpriteKit

extension GameScene {

    // MARK: - Cull

    /// Destroys half the remaining bricks, chosen at random, of any type (§5.4).
    ///
    /// Its value is highest exactly when the field is worst - and being random rather than
    /// chosen means it relieves the pressure without deciding the shape of what is left.
    /// Portals and power-up bricks are spared: one is indestructible by everything, and the
    /// other is spent by being hit, not eaten silently.
    func endlessIICull() {
        guard gameMode == .endlessII else { return }
        var candidates: [SKSpriteNode] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
            guard brick.endlessIIRole != .portal else { return }
            guard brick.endlessIIPowerUpIndex == nil else { return }
            candidates.append(brick)
        }
        guard candidates.isEmpty == false else { return }

        let taken = candidates.shuffled().prefix((candidates.count + 1)/2)
        for brick in taken {
            levelScore = levelScore + Scoring.award(brickDestroyScore, multiplier: multiplier)
            // Scored as destroyed, the spec says - including the indestructibles the
            // ordinary destroy path refuses to score
            endlessIIBrickDestroyed(brick)
            brick.removeFromParent()
        }
        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    // MARK: - Clear And Retreat

    /// How many rows the lowest brick level rises by. Two, James's number (round 136).
    static let endlessIIRetreatRows = 2

    /// How long the field is held where the lift left it.
    ///
    /// Longer than Descent's six, because this is the answer to that; shorter than the
    /// paddle batch's ten, because a held field is a field that is not descending, and in
    /// this mode the descent is where height - the score - comes from. The player is
    /// trading tempo for room, and eight seconds is enough room to be worth the trade
    /// without the run standing still long enough to notice.
    static let endlessIIClearAndRetreatDuration = GameScene.endlessIIPaddlePowerUpDuration

    /// How long the field takes to give up its two rows - and to take them back, in seconds.
    ///
    /// **It used to be one write, and one write is a teleport.** The whole field jumped two
    /// rows in the frame the power-up was caught, which is what James saw and reported as
    /// "the power animation when I collected it shifted up 2 rows" (round 184). Nothing was
    /// in the wrong place; it simply arrived there in no time at all, and a jump the height
    /// of two rows reads as a glitch rather than as the field retreating.
    ///
    /// Short enough that the eight seconds of held field are still the power-up, long enough
    /// that the movement is legible - and the same on the way back down, where the rows
    /// hidden behind the HUD come back into view rather than appearing there.
    static let endlessIIFieldShiftSeconds: TimeInterval = 0.35

    /// Lifts the whole field two rows and holds it there (§5.4).
    ///
    /// **It used to be instant, and instant was the bug** (play-test round 126: "should be
    /// timed"). It cleared the lowest row, lifted everything a row, and then the cadence -
    /// which exists to close exactly the gap it had just made - took both back inside a
    /// second. The retreat the name promises never lasted long enough to be seen, let alone
    /// played around. So it comes with a clock: while that clock runs the field is held - no
    /// cadence, no Descent, no new rows - and when it ends the field comes back down into the
    /// room that was made, so the height it is worth is deferred rather than lost.
    ///
    /// **And it takes nothing** (round 215). Two rounds ran it as a clear *and* a lift, which
    /// was one answer too many: the lower limit and every brick rise together, so the lift
    /// alone already puts the whole field two rows further from the paddle, and the clear was
    /// buying nothing while taking bricks - and their score - off the player.
    func endlessIICollectClearAndRetreat() {
        guard gameMode == .endlessII else { return }

        endlessIIClearAndRetreatClock.collect(GameScene.endlessIIClearAndRetreatDuration)
        // **Nothing is cleared** (James, round 215: "the bottom 2 rows of bricks should remain
        // in play, they just move up along with everything else. It looked like they were
        // 'cleared'. This power up should really just be called retreat as there is no
        // clearing").
        //
        // It used to destroy the two lowest rows here and then lift the field. The lift is the
        // whole power-up on its own: the lower limit and every brick rise together, so the
        // field's *relationship to the line* is unchanged while the whole of it steps two rows
        // further from the paddle. The clear was buying nothing the retreat did not already
        // give, and it was buying it by taking bricks - and their score - off the player.
        //
        // It is also most of what made this stutter: destroying two full rows in one frame
        // runs every one of their removals, roles and counters at once, on the same frame the
        // glide starts.

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(endlessRowDownSound) }
    }

    /// Lifts the whole field - line and bricks - while a retreat runs, and puts both back.
    ///
    /// **"As if the game is set 2 rows higher"** (James, round 169: "it should move all rows
    /// up 2 rows for some time. It should move the low brick line up 2 rows too"). Round 172
    /// did the line and deferred the bricks on the question of what happens to a row lifted
    /// off the top of the field; round 177 answered it: "it's ok if the top 2 rows just get
    /// hidden behind the HUD. They're there, but effectively out of the game and hidden from
    /// view." So the bricks lift with the line now - every one of them, anchored included,
    /// because this is the frame moving rather than the conveyor conveying, and an anchor is
    /// anchored to the field, which is what moved.
    ///
    /// Lifted in one write rather than an action: `countBricks` gates the descent on
    /// `hasActions()` (§8.6), and a brick still gliding upward when the hold ends would stall
    /// the field. The build-in destinations shift with the bricks, because a save taken
    /// mid-flight reads those instead of positions.
    ///
    /// Safe to move because **the field is held for the whole duration** - `endlessIIFieldIsHeld`
    /// is true while this clock runs, so nothing generates a row or steps the field against a
    /// floor that is temporarily somewhere else. When the clock ends the field comes back down
    /// two rows - the hidden rows re-enter, the line drops back - and the descent closes the
    /// gap the *clear* made, which is where the deferred height comes from.
    ///
    /// Driven from the tick rather than scheduled, because a clock can end in more ways than by
    /// running out: a Wipe ends it, and a run ending resets it (the Safety Paddle's own rule).
    /// One variable drives line and bricks together, which is also what makes a resume honest:
    /// the save writes rows with the lift subtracted (`endlessIICanonicalRestingY`), the lift
    /// variable starts a fresh scene at zero, and the first tick of a restored running clock
    /// lifts everything once - never twice.
    func tickEndlessIIFieldShift(_ frameDelta: TimeInterval = 0) {
        guard gameMode == .endlessII else { return }
        let wanted = endlessIIFieldShiftWanted
        let room = wanted - endlessIIFieldShift
        guard abs(room) > 0.01 else { return }

        let travel = CGFloat(GameScene.endlessIIRetreatRows)*brickHeight
            / CGFloat(GameScene.endlessIIFieldShiftSeconds)*CGFloat(max(0, frameDelta))
        let delta = room > 0 ? min(room, travel) : max(room, -travel)
        guard delta != 0 else { return }
        // A frame with no time in it moves nothing rather than snapping: the collect path
        // calls the tick with no delta, and the movement is the following frames' work

        finalBrickRowHeight += delta
        endlessIIFieldShift += delta
        if abs(wanted - endlessIIFieldShift) < 0.01 { endlessIIFieldShift = wanted }
        // Landed exactly, so the lift a save subtracts is a whole number of rows and the
        // arithmetic that decides the field is settled has nothing left to be unsure about
        showEndlessIILowerLimit()
        // The line reads `finalBrickRowHeight`, so it moves by being asked again

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            node.position.y += delta
        }
        for key in endlessIIBuildInFinalY.keys {
            endlessIIBuildInFinalY[key]! += delta
        }
        // Whole rows at a time, so a brick's position.y is still its row (§8.6) - the rows
        // themselves are simply two further from the paddle until the clock ends
    }

    /// Where the field's borrowed rows should be right now.
    ///
    /// Up two while a Retreat runs, down two while a Quicksand does, and back where it started
    /// once neither is. **The two cancel when both run**, which is the matrix's answer for
    /// that pair and costs nothing here: they are one number counted in opposite directions,
    /// rather than two effects that have to be told about each other.
    var endlessIIFieldShiftWanted: CGFloat {
        var rows = 0
        if endlessIIClearAndRetreatClock.isRunning { rows += GameScene.endlessIIRetreatRows }
        if endlessIIQuicksandClock.isRunning { rows -= GameScene.endlessIIRetreatRows }
        return CGFloat(rows)*brickHeight
    }

    /// Quicksand, in Endless Mayhem: the field steps two rows toward the paddle and holds.
    ///
    /// Retreat's opposite in every part. The lower limit comes down with the bricks, so the
    /// field's relationship to the line it dies on is unchanged and what the player loses is
    /// *room*: the same two rows Retreat gives them, taken away for as long as it runs. When
    /// the clock ends the field steps back up.
    ///
    /// Classic's Quicksand is a different animal and stays one - it moves the bricks down and
    /// leaves them there, which is a permanent loss in a mode where the field does not descend
    /// on its own. Here the field descends anyway, so a permanent step down would be a power
    /// -up that only cost the player a few seconds of the descent it was going to make itself.
    func endlessIICollectQuicksand() {
        guard gameMode == .endlessII else { return }
        endlessIIQuicksandClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(endlessRowDownSound) }
    }

    /// Whether the field has finished moving to where the retreat wants it.
    ///
    /// The field is held while it has not, which is what makes a glided lift safe: a brick's
    /// `position.y` is its row (§8.6), and mid-glide every brick is between two. Nothing may
    /// read a row off the field until it has landed - so the descent, the generator and the
    /// bottom-zone check all stand down for the third of a second at each end.
    var endlessIIFieldShiftHasSettled: Bool {
        abs(endlessIIFieldShiftWanted - endlessIIFieldShift) <= 0.01
    }

    /// The row a brick belongs on with the retreat's temporary lift taken back off.
    ///
    /// For the save: a run saved mid-retreat stores its bricks where they *belong*, exactly
    /// as one saved mid-build-in stores destinations rather than flight positions - and for
    /// the same reason. The restored clock is still running, so the first tick after the
    /// restore applies the lift to the restored field; a save that kept the lifted positions
    /// would be lifted a second time.
    func endlessIICanonicalRestingY(_ restingY: CGFloat) -> CGFloat {
        restingY - endlessIIFieldShift
    }

    // MARK: - Laser Beam

    /// One sustained vertical beam per ball in play, each from its own x, destroying the
    /// whole column including Indestructible (§5.4).
    func endlessIIFireLaserBeams() {
        guard gameMode == .endlessII else { return }

        for subject in endlessIIBallsInPlay where subject.parent != nil {
            let beamX = subject.position.x
            let halfWidth = subject.size.width/2

            enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
                guard brick.endlessIIRole != .portal else { return }
                guard brick.endlessIIPowerUpIndex == nil else { return }
                guard brick.frame.minX <= beamX + halfWidth,
                      brick.frame.maxX >= beamX - halfWidth else { return }
                self.endlessIIBrickDestroyed(brick)
                self.endlessIIDestroy(brick)
            }

            let afterGlow = endlessIILaserAfterGlowNode()
            afterGlow.position = CGPoint(x: beamX, y: 0)
            addChild(afterGlow)
            afterGlow.run(.sequence([
                .wait(forDuration: GameScene.endlessIILaserBeamFlashSeconds
                        + GameScene.endlessIILaserBeamFadeSeconds),
                .fadeOut(withDuration: GameScene.endlessIILaserAfterGlowSeconds),
                .removeFromParent()]))

            let beam = endlessIILaserBeamNode()
            beam.position = CGPoint(x: beamX, y: 0)
            addChild(beam)
            beam.run(.sequence([
                .wait(forDuration: GameScene.endlessIILaserBeamFlashSeconds),
                .fadeOut(withDuration: GameScene.endlessIILaserBeamFadeSeconds),
                .removeFromParent()]))
            // **A flash, and then a burn** (James, round 288: "the LaserBeam graphic flashes
            // for a fraction of a second, then it's replaced by LaserBeamAfterGlow which then
            // slowly fades out with its opacity dropping to 0 over the next 1-2s. This will
            // give the impression of a burn in effect after the powerful laser beam").
            //
            // The beam used to fade out over 1.2 seconds on its own, bloom and all, which is a
            // beam that is *still firing* faintly for over a second. What a burn wants is the
            // opposite shape: the whole thing at once, gone almost immediately, and something
            // left behind on the retina that has nothing to do with the shot any more.
            //
            // **The afterglow is added first and simply outlives the beam.** "Replaced by"
            // read literally would be remove one node and add another on the same frame, and
            // that is a frame where the column is empty if either action slips - so the burn is
            // laid down underneath from the start and revealed when the beam goes. It is
            // invisible until then: the two pictures share their opaque core exactly, so during
            // the flash the beam is drawn over every pixel of it.
            //
            // **Made unmissable** (play-test round 102: "doesn't appear to do anything").
            // The mechanics were right all along - a beam through each ball's column, as
            // the description says - but it fired the instant the paddle caught the icon,
            // at the ball's column where the player's eyes are not, silently, for a third
            // of a second. It was built as two sprites for that - a wide additive bloom with
            // a bright core over it - which is what one drawn strip is now (round 243)
        }

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(laserFiredSound) }
    }

    /// The beam's own picture: a white-hot core with the glow falling away either side of it.
    ///
    /// James delivered `LaserBeamLength` for this, and it is built the way `PortalLength` is -
    /// a *length* of an effect, uniform along it, so it stretches to the height of the view
    /// with nothing to distort. What it is not uniform across is its width, and the numbers
    /// below are the two measurements that matter: the picture is 124 points wide and its
    /// opaque core is the middle 22 of them.
    ///
    /// **The core is a normal ball wide, whatever size the ball currently is** (James, round
    /// 243: "it shouldn't change size with the ball"). The column it *destroys* is still the
    /// ball's own width - that is the mechanic and it is untouched - so a shrunken ball now
    /// fires a beam wider than the column it clears. That is the right way round: the beam is
    /// light and the column is what the light did.
    func endlessIILaserBeamNode() -> SKSpriteNode {
        endlessIIBeamNode(GameScene.endlessIILaserBeamTexture, zPosition: 4)
    }

    /// What the beam leaves behind: the same column, without the bloom.
    ///
    /// `LaserBeamAfterGlow` is not a second effect that has to be lined up with the first. The
    /// two pictures are the same size and share their opaque core to the pixel - measured off
    /// the files, both 372 across at 3x with the core running 153 to 218 - so the afterglow is
    /// the beam with the glow either side of it taken away, and it is sized by the same
    /// arithmetic. That is what makes the burn land exactly where the beam was rather than
    /// approximately.
    ///
    /// A step behind the beam in `zPosition`, because it is added first and has to spend the
    /// flash underneath it.
    func endlessIILaserAfterGlowNode() -> SKSpriteNode {
        endlessIIBeamNode(GameScene.endlessIILaserAfterGlowTexture, zPosition: 3.9)
    }

    /// The geometry both of them share.
    ///
    /// **The core is a normal ball wide, whatever size the ball currently is** - see the beam's
    /// own note. Written once so the burn cannot drift from the shot that made it.
    private func endlessIIBeamNode(_ texture: SKTexture?, zPosition: CGFloat) -> SKSpriteNode {
        let core: CGFloat = 22, whole: CGFloat = 124
        let node = SKSpriteNode(texture: texture)
        node.size = CGSize(width: normalBallSize*(whole/core), height: frame.height)
        node.zPosition = zPosition
        node.alpha = 0.9
        return node
    }

    /// How long the beam is held at full before it starts to go.
    ///
    /// "A fraction of a second", which is the flash. Round 288 had the beam vanish at the end
    /// of it; James, round 291: "the initial flash of the laser beam is great, but it should
    /// fade out over 1s rather than immediate."
    static let endlessIILaserBeamFlashSeconds: TimeInterval = 0.12

    /// How long the beam then takes to go.
    ///
    /// **The flash and the fade are two numbers because they are two things.** Round 288
    /// replaced a single 1.2-second fade with an instant cut, on the reasoning that a beam
    /// which dims slowly is a beam still firing - and the burn is what should last. Half of
    /// that was right: what the cut lost is that the beam *arriving* and the beam *leaving* are
    /// both worth seeing, and a shot that disappears between two frames never looks like it was
    /// switched off, it looks like it was never there. Held, then faded, then the burn.
    static let endlessIILaserBeamFadeSeconds: TimeInterval = 1.0

    /// How long the burn takes to go, once the beam has finished going.
    ///
    /// The middle of the "1-2s" asked for, and it starts where the beam's fade ends rather than
    /// where its flash does - "the after glow underneath should then take *another* 1-2s"
    /// (round 291). So the whole thing is a tenth of a second of flash, a second of the beam
    /// fading, and a second and a half of the mark it left: about two and a half seconds from a
    /// shot that used to be over in one.
    static let endlessIILaserAfterGlowSeconds: TimeInterval = 1.5

    /// Loaded once. Nil in a build without the artwork, which draws a white rectangle - the
    /// beam that was there before it, near enough, rather than nothing at all.
    static let endlessIILaserBeamTexture: SKTexture? =
        UIImage(named: "LaserBeamLength").map { SKTexture(image: $0) }

    /// Loaded once, like the beam's. Nil draws a white rectangle that fades, which is a
    /// coarser burn rather than none at all.
    static let endlessIILaserAfterGlowTexture: SKTexture? =
        UIImage(named: "LaserBeamAfterGlow").map { SKTexture(image: $0) }

    // MARK: - Wrecking Ball

    func endlessIICollectWreckingBall() {
        endlessIIDisplace(byCollecting: .wreckingBall)
        endlessIIWreckingBallClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
        // It ends an Inert Ball, which is the one power-up that says the opposite of it
        // (round 223's matrix). Giga-Ball and the Aura it runs happily beside
    }

    /// Whether this hit destroys whatever it struck, whatever it struck (§5.4).
    ///
    /// Asked by `hitBrick` before the type switch. Only the ball's own hits - a laser is not
    /// the ball - and never a Portal or a power-up brick, which have their own rules and are
    /// checked before this is asked.
    func endlessIIWreckingHit(struckBy: SKSpriteNode?, laser: Bool) -> Bool {
        gameMode == .endlessII && endlessIIWreckingBallClock.isRunning
            && laser == false && struckBy != nil
    }

    // MARK: - Aura

    func endlessIICollectAura() {
        endlessIIDisplace(byCollecting: .ballAura)
        endlessIIAuraClock.collect(GameScene.endlessIIPaddlePowerUpDuration,
                                   deepestLevel: GameScene.endlessIIAuraReach.count - 1)
    }

    /// The aura's reach as a multiple of the ball's radius, by stacking level. Twice the
    /// ball's radius to start (§5.4); a deepening collection grows it.
    static let endlessIIAuraReach: [CGFloat] = [2.0, 2.8]

    /// How much of the artwork's half-width still reads as glow.
    ///
    /// `BallAura` fades from the middle outward and reaches nothing at its own edge, so "how
    /// big is it" has no single answer. Measured off the file: alpha is a half at 47% of the
    /// half-width, a quarter at 63%, a tenth at 77% and nothing at all by 92%. The sprite is
    /// drawn `reach*2/this` across, so whichever contour is chosen here is the one that ends
    /// up sitting on the circle the aura actually eats.
    ///
    /// It replaced a stroked circle whose rim sat exactly on the reach, so the reach was
    /// unmistakable and the effect was flat. This keeps the honesty and loses the rim.
    ///
    /// **The tenth contour was the first choice and the quarter is the second** (round 284,
    /// James: "Aura should be bigger"). Both are measured; the disagreement is about what a
    /// player reads as the edge of a glow, and a tenth of a faint alpha is not something
    /// anybody sees. Putting the *quarter* contour on the reach draws the ring 23% wider,
    /// which is the note answered, and costs a faint halo hanging a little outside what the
    /// aura eats - the smaller of the two lies, now that one of them has been played.
    ///
    /// Nothing about the power-up changes with it. The reach, the strikes and the clock are
    /// all untouched: this number only decides how big the picture of them is.
    static let endlessIIAuraVisibleShare: CGFloat = 0.63

    /// Behind the ball rather than over it (James, round 284: "should be behind the ball not
    /// on top of it").
    ///
    /// Negative because the glow is the ball's **child** now, and a child with a negative
    /// `zPosition` is drawn before its parent's own picture. It used to be a sibling at the
    /// ball's own `zPosition` of 3, which leaves the order to whichever was added last - and
    /// the glow is always added last, so it was always the one on top.
    static let endlessIIAuraZPosition: CGFloat = -1

    /// Loaded once. Nil leaves a sprite with no texture, which draws nothing - so a build
    /// without the artwork has an aura that works and cannot be seen.
    static let endlessIIAuraTexture: SKTexture? =
        UIImage(named: "BallAura").map { SKTexture(image: $0) }

    /// Hits what each ball's glow touches, and keeps the glow on the balls.
    ///
    /// **A hit, not a kill** (play-test rounds 6, 9 and 11 all said the same thing: too
    /// powerful). A brick the aura reaches takes exactly what it would have taken from the
    /// ball itself, so a Multi-hit steps down one stage rather than vanishing, an
    /// Indestructible shrugs, and a special fires its own on-hit rule. Destroying outright
    /// made the aura a wider Giga-Ball, which is a different power-up that already exists.
    ///
    /// Aura and Giga-Ball together come to what the aura used to be on its own, and that is
    /// the intended good combination rather than an oversight.
    ///
    /// Each brick is hit **once per pass**. The glow sits over a brick for many frames, and
    /// a hit every frame would step a Multi-hit through all four stages in a fifth of a
    /// second - which is destroying it outright with extra steps. A brick is remembered
    /// until the glow leaves it.
    func tickEndlessIIAura() {
        guard endlessIIAuraClock.isRunning else {
            if endlessIIAuraNodes.isEmpty == false {
                endlessIIAuraNodes.forEach { $0.removeFromParent() }
                endlessIIAuraNodes.removeAll()
            }
            return
        }

        let multiplier = GameScene.endlessIIAuraReach[
            min(endlessIIAuraClock.level, GameScene.endlessIIAuraReach.count - 1)]
        let balls = endlessIIBallsInPlay.filter { $0.parent != nil }

        while endlessIIAuraNodes.count < balls.count {
            let glow = SKSpriteNode(texture: GameScene.endlessIIAuraTexture)
            glow.zPosition = GameScene.endlessIIAuraZPosition
            endlessIIAuraNodes.append(glow)
            // Not added to anything here. Each glow is parented to its own ball below, and a
            // glow that spent one frame on the scene first would spend it at the origin
        }
        while endlessIIAuraNodes.count > balls.count {
            endlessIIAuraNodes.removeLast().removeFromParent()
        }

        var touchedNow: Set<ObjectIdentifier> = []
        var struck: [SKSpriteNode] = []

        for (index, subject) in balls.enumerated() {
            let glow = endlessIIAuraNodes[index]
            if glow.parent !== subject {
                glow.removeFromParent()
                subject.addChild(glow)
            }
            glow.position = .zero
            // **A child of the ball, which is three of James's round 284 notes at once.** It
            // was a sibling on the scene, told the ball's position once a frame from `update` -
            // which is *before* the physics step, so the glow was drawn where the ball had been
            // one frame ago. At the speed a ball travels that is most of its own width behind
            // it, and "it lags behind the ball too far" is exactly what that looks like. A
            // child has no position of its own to be stale.
            //
            // It also settles the other two. `zPosition` below zero puts it behind the ball's
            // picture instead of over it, where a sibling at the same height was drawn on top
            // for no better reason than being added second; and a child inherits its parent's
            // scale, so a ball that grows takes its glow with it.
            //
            // **And ghosting now costs no line at all.** Round 182 - "with ghost ball and aura
            // power-ups together, I can still see the aura effect around the ball... it should
            // also be invisible when the ball is invisible" - was answered by copying the
            // ball's alpha on to the glow each frame, which was only ever needed because the
            // glow was not the ball's child. It is now, and SpriteKit multiplies a child's
            // alpha by its parent's, so a ghosted ball fades its own ring the way it has always
            // faded the Wrecking Ball's spikes. Do not put the copy back: at alpha 1 it is
            // harmless and at anything else it fades the glow twice.

            let reach = subject.size.width/2*multiplier
            let scale = max(subject.xScale, 0.01)
            glow.size = CGSize(width: reach*2/GameScene.endlessIIAuraVisibleShare/scale,
                               height: reach*2/GameScene.endlessIIAuraVisibleShare/scale)
            // **The reach is read off the ball rather than off `ballSize`**, which is what
            // makes the glow grow and shrink with it (James, round 284). `ballSize` is the
            // ordinary ball's width and never moves; the Increase and Decrease Ball Size
            // power-ups work by animating the ball's *scale*, and a sprite's `size` carries
            // its scale - so a ball at 1.5x reports a width half again as big and the ring
            // round it widens to match. At scale 1 this is the number the old line gave.
            //
            // **And the picture is divided by that scale**, because a child is drawn in its
            // parent's coordinates: whatever size is set here is multiplied by the ball's own
            // scale on the way to the screen, so setting the screen size directly would apply
            // the growth twice. What is left after the division is a constant, which is the
            // giveaway that it is right - the glow is a fixed multiple of the ball it belongs
            // to, and the ball is the thing that changes size.
            //
            // **Sized so the glow's edge sits on the reach**, not so the *picture* does. A
            // radial fade has no edge, and drawn to the reach exactly it would show a soft
            // blob well inside the circle it actually eats - which is a power-up lying about
            // how far it goes. `endlessIIAuraVisibleShare` is where that is worked out

            enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
                guard brick.endlessIIPowerUpIndex == nil else { return }
                guard brick.isHidden == false else { return }
                guard self.endlessIIAuraReaches(brick, from: subject, reach: reach) else {
                    return
                }
                touchedNow.insert(ObjectIdentifier(brick))
                guard self.endlessIIAuraHitBricks.contains(ObjectIdentifier(brick)) == false
                else { return }
                struck.append(brick)
            }
        }

        endlessIIAuraHitBricks = touchedNow
        // Only what the glow is on *now* is remembered, so a brick that leaves the glow and
        // comes back - the field descends past a stationary ball - is fair game again

        for brick in struck where brick.parent != nil {
            hitBrick(node: brick, sprite: brick, struckBy: ball)
        }
        // Through the same door the ball uses, so every rule that belongs to a brick type
        // fires: the multi-hit ladder, the scoring, the specials' own consequences

        if struck.isEmpty == false {
            countBricks()
            if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.5) }
        }
    }

    /// Whether the glow, and not the ball itself, is over this brick.
    ///
    /// The inner test is the point: a brick the ball is actually touching is the ball's own
    /// business and it bounces off it as ever. The aura's gift is the bricks beside the one
    /// being struck, which is why the ball's own radius is excluded rather than included.
    func endlessIIAuraReaches(_ brick: SKSpriteNode, from subject: SKSpriteNode,
                              reach: CGFloat) -> Bool {
        let nearestX = max(brick.frame.minX, min(subject.position.x, brick.frame.maxX))
        let nearestY = max(brick.frame.minY, min(subject.position.y, brick.frame.maxY))
        let dx = nearestX - subject.position.x
        let dy = nearestY - subject.position.y
        let distance = dx*dx + dy*dy
        let ballRadius = subject.size.width/2
        return distance <= reach*reach && distance > ballRadius*ballRadius
    }

    // MARK: - Lock and Key

    /// A Lock lands. Extends, like every other timed power-up.
    func endlessIICollectLock() {
        endlessIILockClock.hold()
        // **No timer** (James, round 218). It ran fifteen seconds and then let go by itself,
        // which made the Key a convenience rather than the answer. Held, the Key is the only
        // way out and a Lock is a thing that happens *to* you until you undo it
    }

    /// A Key lands, and the Lock ends.
    ///
    /// The clock is cleared outright rather than run down: a Key is the answer to a Lock,
    /// and an answer that only shortened it would leave the player still locked.
    func endlessIITurnKey() {
        endlessIILockClock = EndlessIIClock()
    }

    /// Whether the timed power-ups are frozen.
    var endlessIILocked: Bool { endlessIILockClock.isRunning }

    /// How much time the timed power-ups see this frame.
    ///
    /// Zero while a Lock runs, which is the whole of the freeze: every clock in the mode
    /// counts down through this, so there is one place that decides and no clock that can be
    /// forgotten. The Lock's own clock deliberately does not use it - it has to run down to
    /// end by itself.
    var endlessIIClockDelta: TimeInterval {
        endlessIILocked ? 0 : endlessIIPaddleFrameDelta
    }

    /// Whether a Lock is worth dropping.
    ///
    /// Only while something is running for it to freeze, and only while that something has
    /// enough left to still be running when the Lock reaches the paddle (§5.4). A Lock that
    /// lands on an empty board freezes nothing and reads as a dud, which is worse than a
    /// power-up that did not drop.
    var endlessIILockMayDrop: Bool {
        guard gameMode == .endlessII, endlessIILocked == false else { return false }
        if endlessIIClassicTimerRunning { return true }
        // The old timers count as something to freeze from round 221. A field with nothing but
        // a Giga-Ball running was a field a Lock declined to drop on, though a Lock is now
        // exactly what that player wants
        return endlessIITimedClocks.contains {
            $0.outlastsALockDrop(lead: GameScene.endlessIILockLead)
        }
        // Asked of each clock rather than compared in seconds (§12.0's descent-in-rows
        // item): Descent's clock counts rows now, and rows do not decay while the Lock falls
    }

    /// Whether a Key is worth dropping: only while there is a Lock to undo.
    var endlessIIKeyMayDrop: Bool {
        gameMode == .endlessII && endlessIILocked
    }

    /// How long a dropped power-up takes to fall, near enough. A clock with less than this
    /// left will have expired before the Lock could freeze it.
    static let endlessIILockLead: TimeInterval = 2.0

    /// Every clock a Lock would freeze, as key paths.
    ///
    /// Key paths rather than values because three different things now need this list and one
    /// of them writes: the drop rule asks what is running, the freeze stops them counting, and
    /// a Wipe clears them. A list that could only be read would have needed a second list that
    /// could be written, and two lists of the same eight clocks is how one of them ends up
    /// missing the ninth.
    static let endlessIITimedClockPaths: [ReferenceWritableKeyPath<GameScene, EndlessIIClock>] = [
        \.endlessIIWreckingBallClock, \.endlessIIAuraClock, \.endlessIIDescentClock,
        \.endlessIIWrapAroundClock, \.endlessIIBallSteeringClock, \.endlessIIMagnetismClock,
        \.endlessIIPaddleHaloClock, \.endlessIIPortalPaddleClock,
        \.endlessIIRandomisedBounceClock, \.endlessIIGhostBallClock,
        \.endlessIIClearAndRetreatClock, \.endlessIISafetyPaddleClock,
        \.endlessIIDriftClock, \.endlessIIQuicksandClock,
    ]
    // Double Paddle and Mirror Paddle left this list in round 180: they were designed as
    // 12-second clocks but were never in any run-down loop, so both ran for ever (James:
    // "it doesn't ever end" / "it just remained on the whole time") - and the cure was the
    // design change he asked for, not the loop: they end on paddle hits now, like the rest
    // of the paddle batch, which also puts them where a Lock rightly ignores them

    /// Every clock a Lock would freeze. One list, so the drop rule and the freeze cannot
    /// disagree about what "a timed power-up" means.
    var endlessIITimedClocks: [EndlessIIClock] {
        GameScene.endlessIITimedClockPaths.map { self[keyPath: $0] }
    }

    /// Every clock a Wipe clears: the timed ones above, and the ones counted in paddle hits
    /// rather than in seconds.
    ///
    /// The turn-based ones are not here because a Lock ignores them - a Lock stops time, and
    /// they do not spend time - but a Wipe ends *power-ups*, and those are power-ups. Which is
    /// why this is a longer list than the one above rather than the same one.
    ///
    /// The Lock is deliberately in neither. §5.4: a Wipe that removed a Lock would be strictly
    /// better than a Key, and a Key that is never worth collecting is a power-up that may as
    /// well not drop.
    static let endlessIIWipeableClockPaths: [ReferenceWritableKeyPath<GameScene, EndlessIIClock>] =
        endlessIITimedClockPaths + [
            \.endlessIIAimedStickyClock, \.endlessIIInertPaddleClock,
            \.endlessIIFlippedAngleClock, \.endlessIIReversedControlsClock,
            \.endlessIIAutoAimClock,
            \.endlessIIDoublePaddleClock, \.endlessIIMirrorPaddleClock,
            \.endlessIIBallSpinClock,
        ]

    // MARK: - What ends what

    /// Ends whatever the power-up just collected cannot run alongside.
    ///
    /// The matrix's "most recent power-up overrides", from the one list in
    /// `EndlessIIExclusions`. Called at the top of each of those power-ups' own collection, so
    /// the field is already clear by the time it starts.
    ///
    /// Two of the pairs reach outside Endless Mayhem's own clocks - Giga-Ball and Inert Ball
    /// are the original twenty-eight's, run as actions - and they end the way a Wipe ends
    /// them, by running the block their own wait would have run (round 222).
    func endlessIIDisplace(byCollecting collected: EndlessIIExclusive) {
        guard gameMode == .endlessII else { return }
        for other in EndlessIIExclusions.ended(byCollecting: collected) {
            endlessIIEnd(other)
        }
    }

    /// Ends one power-up now, whichever kind of clock it keeps.
    private func endlessIIEnd(_ which: EndlessIIExclusive) {
        switch which {
        case .gigaBall: endClassicPowerUp(key: "powerUpGigaBall")
        case .inertBall: endClassicPowerUp(key: "powerUpUndestructiBall")
        case .wreckingBall: endlessIIWreckingBallClock.reset()
        case .ballAura: endlessIIAuraClock.reset()
        case .stickyPaddle:
            while stickyPaddleCatches > 0 { spendStickyPaddleCatch() }
            // Spent rather than zeroed: the last catch leaving is what puts the paddle's face
            // back, releases a ball still sitting on it and clears the icon, and all of that
            // has to happen whether the catches ran out or were taken away
        case .aimedSticky: endlessIICancelAimedSticky()
        case .inertPaddle: endlessIIInertPaddleClock.reset()
        case .flippedAngle: endlessIIFlippedAngleClock.reset()
        case .autoAim:
            endlessIIAutoAimClock.reset()
            endlessIIAutoAimOwedTurn = false
        case .ballSpin: endlessIIBallSpinClock.reset()
        case .portalPaddle:
            endlessIIPortalPaddleClock.reset()
            endlessIIPortalPaddleOwedTurn = false
            // The owed turn goes with it, for the Wipe's reason: a debt is part of the
            // power-up, and the power-up has been taken away rather than run out
        case .ballControl: endlessIIBallSteeringClock.reset()
        }
    }

    /// One of the original twenty-eight, ended now - its own ending block, run early.
    func endClassicPowerUp(key: String) {
        guard let ending = classicPowerUpEndings[key] else { return }
        removeAction(forKey: key)
        for (timerKey, timers) in endlessIIClassicTimers where timerKey == key {
            for (node, name) in timers { node.removeAction(forKey: name) }
        }
        classicPowerUpEndings.removeValue(forKey: key)
        run(ending)
    }

    // MARK: - The original twenty-eight, under a Lock

    /// Every timed power-up from the original twenty-eight, and the actions that time it.
    ///
    /// **A Lock freezes these too** (James, round 221's interaction matrix, which lists Slow
    /// ball, Increase ball speed, Expand paddle, Shrink paddle, Hide bricks, Gravity field,
    /// Giga-ball, Inert ball, Lasers, Expand ball and Shrink ball beside Lock and Key). Until
    /// now a Lock froze Endless Mayhem's own clocks and left these running, so a player who
    /// locked a field full of power-ups watched half of them expire anyway.
    ///
    /// These do not run on `EndlessIIClock`. Each is an `SKAction` sequence on the scene - a
    /// wait, then a block that puts everything back - with two more actions animating the icon
    /// and its bar. Freezing them is setting the speed of those three to zero, which is what
    /// an `SKAction` means by frozen: the wait stops counting and the bar stops draining, so
    /// the bar goes on saying how much would be left.
    ///
    /// Written out once here rather than looked up at three call sites. The pairs share their
    /// icon and bar keys, because they share their icon: a paddle cannot be expanded and
    /// shrunk at once, so there is one paddle-size timer whichever of the two started it.
    var endlessIIClassicTimers: [(key: String, timers: [(node: SKNode, key: String)])] {
        [("powerUpDecreaseBallSpeed",
          [(ballSpeedIcon, "powerUpDecreaseBallSpeedTimer"), (ballSpeedIconBar, "ballSpeedTimer")]),
         ("powerUpIncreaseBallSpeed",
          [(ballSpeedIcon, "powerUpDecreaseBallSpeedTimer"), (ballSpeedIconBar, "ballSpeedTimer")]),
         ("powerUpIncreasePaddleSize",
          [(paddleSizeIcon, "powerUpPaddleSizeTimer"), (paddleSizeIconBar, "paddleSizeTimer")]),
         ("powerUpDecreasePaddleSize",
          [(paddleSizeIcon, "powerUpPaddleSizeTimer"), (paddleSizeIconBar, "paddleSizeTimer")]),
         ("powerUpGravityBall",
          [(gravityIcon, "powerUpGravityTimer"), (gravityIconBar, "gravityTimer")]),
         ("powerUpInvisibleBricks",
          [(hiddenBricksIcon, "powerUpHiddenBricksTimer"),
           (hiddenBricksIconBar, "invisibleBricksTimer")]),
         ("powerUpGigaBall",
          [(gigaBallIcon, "powerUpGigaBallTimer"), (gigaBallIconBar, "gigaBallTimer")]),
         ("powerUpUndestructiBall",
          [(gigaBallIcon, "powerUpGigaBallTimer"), (gigaBallIconBar, "gigaBallTimer")]),
         ("powerUpLasers",
          [(lasersIcon, "powerUpLaserTimer"), (lasersIconBar, "laserTimer")]),
         ("powerUpIncreaseBallSize",
          [(ballSizeIcon, "powerUpBallSizeTimer"), (ballSizeIconBar, "ballSizeTimer")]),
         ("powerUpDecreaseBallSize",
          [(ballSizeIcon, "powerUpBallSizeTimer"), (ballSizeIconBar, "ballSizeTimer")])]
    }

    /// Schedules the ending of one of the original twenty-eight's timed power-ups.
    ///
    /// Every one of them was written the same way: a wait, then a block that puts everything
    /// back, run on the scene under a name. This is that, plus one thing - the ending block is
    /// **kept**, under the same name, so that something else can run it early.
    ///
    /// That is the whole of what a Wipe needed. Ending a power-up before its time means doing
    /// exactly what its own ending does, and the only two the Wipe could reach before this
    /// (Gravity and Inert Ball) got there by a second copy of that block written out by hand -
    /// two copies of a decision, which is wrong the first time the decision changes. Here the
    /// Wipe runs the very same `SKAction` the wait would have run.
    ///
    /// Used by the collection paths and by the resume paths both, which is also how the two
    /// stopped being able to disagree about what ending a power-up means.
    func runClassicPowerUpTimer(key: String, wait: SKAction, ending: SKAction) {
        classicPowerUpEndings[key] = ending
        let forget = SKAction.run { [weak self] in
            self?.classicPowerUpEndings.removeValue(forKey: key)
        }
        run(.sequence([wait, ending, forget]), withKey: key)
        // Forgotten after it fires, so `classicPowerUpEndings` says what is *running* rather
        // than what has ever run - which is what the Wipe reads to know there is anything to do
    }

    /// Whether any of the original twenty-eight's timers is running right now.
    ///
    /// Asked of the actions rather than of a flag, because the actions are the only record
    /// these power-ups keep of being on - `inertBallRunning` has said so since round 148 and
    /// this is the same reading, generalised.
    var endlessIIClassicTimerRunning: Bool {
        endlessIIClassicTimers.contains { action(forKey: $0.key) != nil }
    }

    /// Holds the old timers where they are, or lets them run again.
    ///
    /// **Written every frame rather than at each end of a Lock**, and that is the point rather
    /// than laziness: a power-up collected *during* a Lock starts a fresh action at full speed,
    /// and a freeze applied only when the Lock landed would miss it. Rewriting a speed that is
    /// already right costs nothing and cannot be forgotten.
    func endlessIIHoldClassicTimers(_ frozen: Bool) {
        guard gameMode == .endlessII else { return }
        let speed: CGFloat = frozen ? 0 : 1
        for (key, timers) in endlessIIClassicTimers {
            if let running = action(forKey: key), running.speed != speed { running.speed = speed }
            for (node, timerKey) in timers {
                if let running = node.action(forKey: timerKey), running.speed != speed {
                    running.speed = speed
                }
            }
        }
        // The lasers keep firing while frozen, and should: they fire from a `Timer` rather
        // than from this action, and a Lasers that never runs out is exactly what a Lock is
        // for. All that stops is the countdown to its ending
    }

    // MARK: - Wipe

    /// Ends every power-up the player has running, at once. Bad (§5.4).
    ///
    /// A Lock survives it, which is the one exception the design names: a Wipe that removed a
    /// Lock would do everything a Key does and more, and a Key nobody needs is a power-up that
    /// may as well not drop.
    ///
    /// The Mayhem clocks go through the shared list, so a power-up added later is wiped by
    /// having been added to that list rather than by anyone remembering this function. The two
    /// after it are the only power-ups from the original twenty-eight that fall in this mode
    /// and last long enough to be worth ending - the other two that drop here (Reset Multi-Hit
    /// and Remove Indestructible) happen once and are already over.
    func endlessIIWipe() {
        guard gameMode == .endlessII else { return }

        for path in GameScene.endlessIIWipeableClockPaths {
            self[keyPath: path] = EndlessIIClock()
        }
        endlessIIPortalPaddleOwedTurn = false
        // The Portal Paddle owes the ball one more bounce after its clock runs out, so that a
        // turn already under way is honoured. A Wipe is not the clock running out - it is the
        // power-up being taken away, and the debt goes with it

        wipeClassicTimers()
    }

    /// Every one of the original twenty-eight's timed power-ups, ended now.
    ///
    /// Each one's own ending block, run early - the same `SKAction` its wait would have run,
    /// kept by `runClassicPowerUpTimer` for exactly this. The action and the two animating its
    /// icon go first, or the ending would fire a second time later and hide an icon bar that a
    /// power-up collected since might be using.
    ///
    /// **This replaces `wipeGravity` and `wipeInertBall`**, which did the same job for two of
    /// the eleven by writing out what their ending blocks do. That was a second copy of a
    /// decision in the two places the game is oldest, and the other nine were simply not
    /// wiped at all - the matrix asks for all of them (round 222).
    private func wipeClassicTimers() {
        for (key, _) in endlessIIClassicTimers { endClassicPowerUp(key: key) }
    }

    /// Whether a Wipe is worth dropping: only while there is something for it to end.
    ///
    /// The same shape as the Lock's rule and for a related reason, though not the same one. A
    /// Lock with nothing to freeze is a dud; a *bad* power-up with nothing to take away is
    /// worse than a dud, it is a gift - the player collects it and gets away with it.
    var endlessIIWipeMayDrop: Bool {
        guard gameMode == .endlessII else { return false }
        if GameScene.endlessIIWipeableClockPaths.contains(where: { self[keyPath: $0].isRunning }) {
            return true
        }
        return endlessIIClassicTimerRunning
    }

    /// Whether Undestructi-Ball is running. It has no flag of its own - its expiry is an
    /// action on the scene, so the action's presence is the flag.
    var inertBallRunning: Bool { action(forKey: "powerUpUndestructiBall") != nil }

    // MARK: - Infill

    /// Adds bricks in random empty cells. Bad (§5.4).
    func endlessIIInfill() {
        guard gameMode == .endlessII else { return }

        let occupied = endlessIIOccupancy()
        let geometry = endlessIIGeometry
        let reserved = endlessIISpinnerClearanceCells()
        var empty: [EndlessIICell] = []
        for row in 0...max(0, endlessIILowestRow) {
            for column in 0..<geometry.columns {
                let cell = EndlessIICell(column: column, row: row)
                guard occupied[cell]?.isEmpty != false else { continue }
                guard reserved.contains(cell) == false else { continue }
                empty.append(cell)
            }
        }

        for cell in empty.shuffled().prefix(GameScene.endlessIIInfillCount) {
            let brick = SKSpriteNode(texture: brickNormalTexture)
            brick.color = brickWhite
            brick.colorBlendFactor = 1.0
            brick.size = CGSize(width: brickWidth, height: brickHeight)
            brick.position = geometry.centre(of: cell)
            brick.zPosition = 1
            brick.name = BrickCategoryName
            brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: brick.size))
            brick.setScale(0.4)
            brick.alpha = 0
            addChild(brick)
            brick.run(.group([.scale(to: 1, duration: 0.15), .fadeIn(withDuration: 0.15)]))
        }
        // The same arrival a Spawner gives its bricks, because it is the same event seen
        // from the other side: the field growing where it was not asked to

        countBricks()
        if hapticsSetting { rigidHaptic.impactOccurred() }
    }

    /// How many bricks one Infill adds. Enough to feel, few enough that the field is still
    /// the field - and rows that were empty stay mostly empty.
    static let endlessIIInfillCount = 6

    // MARK: - Descent

    /// How many rows a Descent is worth.
    ///
    /// Rows rather than seconds (James's suggestion, round 52, built round 178): a fixed
    /// number of rows is what the player actually experiences, where seconds were what the
    /// code happened to count - and counted badly, because a hold or a slow animation ate
    /// clock without yielding a row, so two collections were worth different heights
    /// depending on what the field was doing. Six, matching the six seconds it replaced at
    /// a row a second: still clearly the biggest single source of height in the mode, which
    /// is the point of it (round 51), without being the only one that matters. The ring
    /// shows six segments now, so what is left reads as rows rather than as "about half".
    static let endlessIIDescentRows = 6

    func endlessIICollectDescent() {
        endlessIIDescentClock.collect(turns: GameScene.endlessIIDescentRows)
    }

    /// How often the field steps down while Descent runs.
    ///
    /// The spec says "continuously"; this is the grid-preserving reading of it - a steady
    /// cadence of the same one-row step the field has always made, because a brick's
    /// position.y is its row and a field that drifted off its row centres would break
    /// everything that reads them (§8.6).
    ///
    /// **Slower than it was** (James, round 172: "moves the bricks down too fast and at a
    /// variable rate - it should be a slow and steady rate for a fixed period"). It ran at
    /// 0.55s, just under two rows a second, which read as the field falling rather than
    /// descending. A row a second is a rate a player can watch and plan against, and over the
    /// fixed six seconds it is still the largest single source of height in the mode - which
    /// is the point of the power-up (round 51).
    static let endlessIIDescentStep: TimeInterval = 1.0

    /// Drives the descent. Called from the field batch's tick.
    ///
    /// The whole power-up is the existing row-step asked on a timer instead of on the bottom
    /// row emptying: `moveEndlessModeRowDown` already destroys what passes the lower limit
    /// unscored, builds the next row, counts the height and moves the markers - which is why
    /// Descent is free height, and why it is a power-up.
    func tickEndlessIIDescent() {
        guard endlessIIDescentClock.isRunning else {
            endlessIIDescentAccumulated = 0
            return
        }

        endlessIIDescentAccumulated += endlessIIClockDelta
        // `endlessIIClockDelta`, not the raw frame delta: a Lock freezes the timed
        // power-ups, and for a clock that counts rows the freeze is the *cadence* stopping.
        // The raw delta here used to let a locked Descent keep stepping while its clock
        // stood still - free rows for the length of the freeze
        guard endlessIIDescentAccumulated >= GameScene.endlessIIDescentStep else { return }

        guard endlessMoveInProgress == false else { return }
        // A step already animating finishes first - two moves at once would stack their
        // distances and carry bricks off their row centres

        guard endlessIIFieldIsHeld == false else { return }
        // Descent is the field's other way down, and it must stop for an aim like the
        // cadence does - otherwise the one power-up that exists to drop the field does it
        // while the player is holding the ball still and cannot answer (round 87)

        endlessIIDescentAccumulated -= GameScene.endlessIIDescentStep
        // **Spent only when the step is actually taken, and subtracted rather than zeroed.**
        //
        // This is the "variable rate" James saw. The countdown used to be zeroed the moment it
        // came due, *before* the two guards below - so a step that could not be taken because
        // the last one was still animating, or because an aim was holding the field, threw its
        // whole interval away and started again from nothing. The next step then arrived a
        // whole extra interval late, and the cadence wandered between one and two seconds
        // depending on what the field happened to be doing.
        //
        // Subtracting keeps the phase: a long frame or a short hold leaves the remainder
        // behind, and the rate stays the rate.

        endlessIIDescentClock.spendTurn()
        moveEndlessModeRowDown()
        // A row taken is a row spent - the budget is rows, so nothing but a taken step can
        // spend one, and a Descent is always worth exactly its six however long they take
    }

    /// Whether Descent owns extra steps of the field right now.
    ///
    /// It no longer suspends the empty-bottom-row cadence (rounds 94 and 99): that rule
    /// only fires over a gap, and a gap must close at full speed whatever else is running.
    /// What Descent owns is its own additional step, on its own timer, on top of the
    /// normal rules - serialised against them by `endlessMoveInProgress` like every step.
    var endlessIIDescentOwnsExtraSteps: Bool {
        endlessIIDescentClock.isRunning
    }

    // MARK: - The ring and the save

    /// The batch's clocks, with the name they save under and the icon the ring shows.
    ///
    /// One table, because the ring and the save were two hand-written lists of the same
    /// clocks and they had already disagreed: Randomised Bounce and Ghost Ball were added to
    /// the freeze list, the wipe list and the tick, and to neither of these - so both ran
    /// with nothing in the ring to say so, and both were quietly lost by a save and resume.
    /// Now a clock that is in the table is in all three, and a clock that is not is in none.
    var endlessIIFieldClocks: [(id: String, clock: EndlessIIClock, icon: SKTexture)] {
        [("endlessIIWreckingBall", endlessIIWreckingBallClock,
          PowerUpIcon.ringTexture("WreckingBallIcon", PowerUpIcon.hud("WreckingBallIcon", PowerUpIcon.wreckingBall))),
         ("endlessIIAura", endlessIIAuraClock,
          PowerUpIcon.ringTexture("AuraIcon", PowerUpIcon.hud("AuraIcon", PowerUpIcon.aura))),
         ("endlessIIDescent", endlessIIDescentClock,
          PowerUpIcon.ringTexture("DescentIcon", PowerUpIcon.hud("DescentIcon", PowerUpIcon.descent))),
         ("endlessIIWrapAround", endlessIIWrapAroundClock,
          PowerUpIcon.ringTexture("WrapIcon", PowerUpIcon.hud("WrapIcon", PowerUpIcon.wrapAround))),
         ("endlessIIRandomisedBounce", endlessIIRandomisedBounceClock,
          PowerUpIcon.ringTexture("RandomBounceIcon", PowerUpIcon.hud("RandomBounceIcon", PowerUpIcon.randomisedBounce))),
         ("endlessIIGhostBall", endlessIIGhostBallClock,
          PowerUpIcon.ringTexture("GhostBallIcon", PowerUpIcon.hud("GhostBallIcon", PowerUpIcon.ghostBall))),
         ("endlessIIClearAndRetreat", endlessIIClearAndRetreatClock,
          PowerUpIcon.ringTexture("ClearAndRetreatIcon", PowerUpIcon.hud("ClearAndRetreatIcon", PowerUpIcon.clearAndRetreat))),
         ("endlessIIQuicksand", endlessIIQuicksandClock,
          PowerUpIcon.ringTexture("QuicksandIcon",
                                  PowerUpIcon.hud("QuicksandIcon",
                                                  UIImage(named: "PowerUpBricksDown")
                                                    ?? PowerUpIcon.clearAndRetreat))),
         // **Its own round icon now** (round 241's delivery). It wore Classic's Quicksand
         // badge, because it is Classic's Quicksand - the same power-up doing a temporary
         // version of the same thing (round 218) - and a square badge in a round ring is a
         // square in a circle. The badge is still the fallback, so the two are the same
         // picture anywhere the drawn one is missing
         ("endlessIISafetyPaddle", endlessIISafetyPaddleClock,
          PowerUpIcon.ringTexture("SafetyPaddleIcon", PowerUpIcon.hud("SafetyPaddleIcon", PowerUpIcon.safetyPaddle))),
         ("endlessIIDrift", endlessIIDriftClock,
          endlessIIDriftDirection < 0
              ? PowerUpIcon.ringTexture(
                    "DriftLeftIcon",
                    PowerUpIcon.hud("DriftLeftIcon",
                                    PowerUpIcon.mirrored(PowerUpIcon.hud("DriftIcon",
                                                                         PowerUpIcon.drift))))
              : PowerUpIcon.ringTexture("DriftIcon",
                                        PowerUpIcon.hud("DriftIcon", PowerUpIcon.drift)))]
        // The ring shows which way the field is sliding. **Drawn art for the leftward one
        // now** (James, round 210's delivery): it was the rightward icon flipped, which is
        // the right answer while there is only one picture and the wrong one as soon as
        // there are two - a mirrored image is mirrored in every part, including any part
        // that was never meant to read backwards. The mirror stays as the fallback, so a
        // build without the new art looks exactly as it did
    }

    func endlessIIFieldRingEntries() -> [PowerUpRingHUD.Entry] {
        endlessIIFieldClocks.compactMap { id, clock, texture in
            guard clock.isRunning else { return nil }
            return PowerUpRingHUD.Entry(id: id, texture: texture,
                                        remaining: clock.fraction,
                                        segments: clock.countsTurns ? Int(clock.total) : nil)
            // Descent's ring is segmented like the sticky paddle's: six marks say "six rows",
            // where a smooth arc only says "about half a Descent"
        }
    }

    func endlessIIFieldClockSaveEntries() -> [(key: String, remaining: Double, total: Double,
                                               magnitude: Int)] {
        endlessIIFieldClocks
            .filter { $0.clock.isRunning }
            .map { ($0.id, $0.clock.remaining, $0.clock.total, $0.clock.level) }
    }

    @discardableResult
    func endlessIIRestoreFieldClock(key: String, remaining: Double, total: Double,
                                    magnitude: Int) -> Bool {
        switch key {
        case "endlessIIWreckingBall":
            endlessIIWreckingBallClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIAura":
            endlessIIAuraClock.restore(remaining: remaining, total: total, level: magnitude,
                                       deepestLevel: GameScene.endlessIIAuraReach.count - 1)
        case "endlessIIDescent":
            endlessIIDescentClock.restore(remaining: remaining, total: total, level: 0)
            endlessIIDescentClock.countsTurns = true
            // The flag is not in the save; what marks a restored Descent as rows is the same
            // thing that marks a fresh one - this line and `collect(turns:)` respectively
        case "endlessIIWrapAround":
            endlessIIWrapAroundClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIRandomisedBounce":
            endlessIIRandomisedBounceClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIGhostBall":
            endlessIIGhostBallClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIClearAndRetreat":
            endlessIIClearAndRetreatClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIQuicksand":
            endlessIIQuicksandClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIDrift":
            endlessIIDriftClock.restore(remaining: remaining, total: total, level: 0)
            if endlessIIDriftDirection == 0 { endlessIIDriftDirection = 1 }
            // A resumed drift keeps drifting. The direction rides in the save since round
            // 201 (two Drifts, one per direction, so which way is part of which power-up);
            // this line is only the fallback for a save written before it carried one
        case "endlessIISafetyPaddle":
            endlessIISafetyPaddleClock.restore(remaining: remaining, total: total, level: 0)
            showEndlessIISafetyPaddle()
            // The surface comes back with its clock: a resumed run that had one standing
            // must find it standing, or the save has quietly changed the field
        default:
            return false
        }
        return true
    }

    /// Runs the batch's clocks. From `update`, beside the paddle batch's tick.
    func tickEndlessIIFieldPowerUps() {
        guard gameMode == .endlessII else { return }
        endlessIIHoldClassicTimers(endlessIILocked)
        // **Outside the playing guard below, deliberately.** The original twenty-eight's
        // timers freeze with the rest from round 221, and a freeze is a state rather than a
        // step: it has to be true whether or not the frame is one the clocks count. A pause
        // taken inside a Lock would otherwise hand every old timer its speed back.
        if gameState.currentState is Playing && isPaused == false {
            endlessIIWreckingBallClock.run(down: endlessIIClockDelta)
            endlessIIAuraClock.run(down: endlessIIClockDelta)
            endlessIIRandomisedBounceClock.run(down: endlessIIClockDelta)
            endlessIIGhostBallClock.run(down: endlessIIClockDelta)
            endlessIIClearAndRetreatClock.run(down: endlessIIClockDelta)
            endlessIIQuicksandClock.run(down: endlessIIClockDelta)
            endlessIISafetyPaddleClock.run(down: endlessIIClockDelta)
            endlessIIDriftClock.run(down: endlessIIClockDelta)
            tickEndlessIIGhostBall()
            tickEndlessIISafetyPaddle()
            tickEndlessIIDescent()
        }
        tickEndlessIIAura()
        tickEndlessIIFieldShift(endlessIIPaddleFrameDelta)
        // Outside the Playing guard, like the Aura's: the floor has to come back down after a
        // clock that ended while the game was paused
        refreshEndlessIIWreckingBall()
        // Outside the Playing guard, like the Aura's tick: the spikes have to come off a
        // ball whose clock ran out while the game was paused, and go back on when a run is
        // resumed - neither of which happens while nothing is being ticked
    }

    // MARK: - Randomised Bounce

    /// How long one collection lasts, and how much of the angle it throws off.
    ///
    /// **A share of the bounce, not a number of degrees** (James, round 185: "randomised
    /// bounce is way too erratic. It should just be the ball bouncing slightly differently
    /// from how it normally does. Instead the ball seems to go crazy, vibrating and glitching
    /// constantly. Perhaps the bounce angle adjustment should be much narrower, like +/- 10%
    /// of the actual bounce angle").
    ///
    /// Round 180 narrowed it from 35 degrees to 25 and it was still wrong, because degrees
    /// were the wrong unit. A fixed ±25° is nothing to a bounce leaving at 90° and everything
    /// to one leaving at 15°: it throws the shallow bounces *below the minimum the game
    /// allows*, where `breakHorizontalRuns` catches them and fires its own escape - every
    /// frame, with its own jitter, which is the vibrating and glitching. Proportional, it
    /// cannot: ten per cent of a shallow angle is a shallow nudge, so the ball never lands
    /// where the escape hatch has to save it.
    ///
    /// **Widened from 0.10 to 0.35 in round 283**, because a tenth was invisible. James: "there's
    /// no discernible randomness to the bounce." It was narrowed twice - 35 degrees to 25, then
    /// to a tenth of the room - while chasing a vibrating ball that turned out to be the sign
    /// bug round 258 found, and once that was fixed nobody put it back. Measured: a tenth moved
    /// a 45-degree bounce by 3.5 degrees and a 70-degree one by 6, which is *less* than the
    /// player already gets from hitting the paddle nearer one end. A third moves them by 12 and
    /// 21, which is a bounce you cannot predict - and it is still proportional to the room, so
    /// it still cannot throw a shallow bounce below the minimum into the escape hatch's arms.
    static let endlessIIRandomisedBounceDuration = GameScene.endlessIIPaddlePowerUpDuration
    static let endlessIIRandomisedBounceSpread: Double = 0.35

    /// Starts or extends Randomised Bounce (§5.4: timed, extends its own duration).
    func endlessIICollectRandomisedBounce() {
        endlessIIRandomisedBounceClock.collect(GameScene.endlessIIRandomisedBounceDuration)
    }

    /// The angle a bounce leaves at while this runs: the honest one, thrown off by up to
    /// `spread` degrees either way.
    ///
    /// Pure, so the rule can be tested without a running game, and separate from the scene
    /// so the one place that applies it cannot disagree with the one place that describes it.
    ///
    /// **Never past the minimum.** The game's whole angle discipline is that a bounce is
    /// never so near horizontal that the ball stops coming down (`ballHorizontalControl`,
    /// `breakHorizontalRuns`), and a bad power-up is allowed to be unfair but not to hand the
    /// player a ball that can never be lost or played. So the offset is clamped back inside
    /// the launchable arc rather than allowed out of it.
    /// - Parameter share: the fraction of the room the bounce has to throw it off by, where a
    ///   caller wants to name one. Tests pass it to ask for a known bounce; play rolls it.
    static func randomisedBounceAngle(from angleDeg: Double, minimumDeg: Double,
                                      spread: Double = endlessIIRandomisedBounceSpread,
                                      share: Double? = nil) -> Double {
        let fraction = share ?? Double.random(in: -spread...spread)

        let travellingDown = angleDeg < 0
        let magnitude = abs(angleDeg)
        // **The sign is the ball's up or down and is never a magnitude** (round 258). This is
        // what "still broken" was: `atan2` reports -180...180 and this arithmetic was written
        // for 0...180, so `max(angleDeg + ..., minimumDeg)` on a ball travelling *down* at
        // -45° returned +10 - the ball was slammed from a fair descent into a shallow climb,
        // at every brick contact, for the whole ten seconds. And +10 is `minAngleDeg` exactly,
        // which is the escape hatch's own trigger, so the shallow climb was then re-aimed with
        // a random jitter frame after frame. That is the vibrating, and it survived two rounds
        // of narrowing the spread because every test written for it passed an upward angle

        let steepness = min(magnitude, 180 - magnitude)
        // How far this bounce is from horizontal, which is the thing the game actually cares
        // about. A heading of 10° and one of 170° are both a ball skimming sideways, and the
        // old proportional form treated the second as seventeen times the first

        let room = steepness - minimumDeg
        guard room > 0 else { return angleDeg }
        // **A bounce with no room is left exactly as it arrived.** The escape hatch in
        // `ballHorizontalControl` owns the ones at or under the minimum, and two things
        // rescuing one bounce is the other half of what the vibrating was

        let nudged = magnitude + room*fraction
        // A tenth of the *room*, not a tenth of the angle. It cannot reach the minimum, so
        // the clamp below can no longer fire at the spread this ships at - it is kept for a
        // future spread wider than 1, where it could

        let bounded = min(max(nudged, minimumDeg), 180 - minimumDeg)
        return travellingDown ? -bounded : bounded
    }

    /// Whether this bounce should be randomised at all.
    ///
    /// Every ball, and only while the clock runs. An extra ball keeping its honest bounce
    /// while the first one lied would be stranger than either.
    func endlessIIRandomisesBounces(for subject: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, endlessIIRandomisedBounceClock.isRunning else {
            return false
        }
        guard randomisedBounceFrame[ObjectIdentifier(subject)] != frameNumber else {
            return false
        }
        randomisedBounceFrame[ObjectIdentifier(subject)] = frameNumber
        return true
        // **One nudge per ball per frame** (James, round 283: "the ball stutters a lot when
        // this power up is active").
        //
        // A bounce is one event and `didBegin` is not: it reports once per *fixture pair*, so a
        // brick built from two convex halves - which is every concave brick - reports twice for
        // one strike, and a ball meeting the seam between two bricks reports twice again. Each
        // report ran the whole correction, so each drew its own random angle and the ball came
        // out of a single bounce having been aimed two or three different ways in one frame.
        // That is the stutter, and widening the spread would have made it worse rather than
        // better.
        //
        // The same shape of guard `paddleHit` has carried since round 259, for the same reason
        // and against the same §8.6 trap. Kept here rather than at the call sites because this
        // is already the one gate every one of them asks
    }


    // MARK: - Ghost Ball

    static let endlessIIGhostBallDuration = GameScene.endlessIIPaddlePowerUpDuration

    func endlessIICollectGhostBall() {
        endlessIIGhostBallClock.collect(GameScene.endlessIIGhostBallDuration)
    }

    /// Whether a ball at this height can be seen while Ghost Ball runs.
    ///
    /// Pure and stated once: the ball is invisible while it is up among the bricks and comes
    /// back the moment it drops below the lowest row - "you see where it lands, not where it
    /// flies" (play-test round 11). The line is the field's own bottom, so it moves as the
    /// field descends and the rule needs no separate upkeep.
    static func ghostBallIsVisible(ballY: CGFloat, lowestBrickRow: CGFloat) -> Bool {
        ballY < lowestBrickRow
    }

    /// Hides and shows the balls each frame. Dressing only - nothing here touches physics,
    /// which is the whole reason a bad power-up this strong is survivable: the ball you
    /// cannot see is exactly the ball that was always there.
    func tickEndlessIIGhostBall() {
        guard endlessIIGhostBallWasRunning || endlessIIGhostBallClock.isRunning else { return }
        let running = endlessIIGhostBallClock.isRunning
        endlessIIGhostBallWasRunning = running

        for subject in endlessIIBallsInPlay where subject.parent != nil {
            guard running else {
                subject.alpha = 1
                continue
                // Put back on the frame the clock ends, whatever the ball was doing - an
                // invisible ball left behind by an expired power-up is a lost run
            }
            subject.alpha = GameScene.ghostBallIsVisible(ballY: subject.position.y,
                                                          lowestBrickRow: finalBrickRowHeight)
                ? 1 : 0
        }
    }

    func endlessIIResetFieldPowerUps() {
        endlessIIGhostBallClock.reset()
        endlessIIGhostBallWasRunning = false
        for subject in endlessIIBallsInPlay { subject.alpha = 1 }
        endlessIIRandomisedBounceClock.reset()
        endlessIIWreckingBallClock.reset()
        endlessIIAuraClock.reset()
        endlessIIDescentClock.reset()
        endlessIIDescentAccumulated = 0
        endlessIIClearAndRetreatClock.reset()
        endlessIISafetyPaddleClock.reset()
        endlessIIDriftClock.reset()
        endlessIIDriftDirection = 0
        childNode(withName: GameScene.endlessIISafetyPaddleName)?.removeFromParent()
        endlessIIAuraNodes.forEach { $0.removeFromParent() }
        endlessIIAuraNodes.removeAll()
    }
}
