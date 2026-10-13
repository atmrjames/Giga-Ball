//
//  StickyCatch.swift
//  Megaball
//
//  Catching the ball on the sticky paddle *before* the physics step, rather than after it.
//
//  The catch used to be made in `paddleHit`, which runs from `didBegin(_:)`. The ball and the
//  paddle collide as well as report contact, so by the time that contact arrived SpriteKit had
//  already resolved the bounce and moved the ball - and the catch then zeroed the velocity and
//  snapped the ball back down onto the paddle. The snap was visible: the play-test saw the ball
//  "bounce off a fraction after it hits the paddle, before snapping back into position".
//
//  It is §8.6's first trap in a new place. A contact reports the state *after* the engine has
//  acted, so anything that needs the approach - which face was struck, which way a portal sends
//  a ball, and now whether a ball was about to land on the paddle - has to be sampled in
//  `update`, before physics. `ballStateBeforeStep` is that sample and this reads it.
//
//  Doing it here means no bounce happens at all: the ball is stopped on the frame it would have
//  crossed the paddle's surface, so there is nothing to snap back from.
//

import SpriteKit

extension GameScene {

    /// How far ahead the catch looks: one frame at sixty.
    ///
    /// How far ahead the catch looks: one frame, whatever a frame is worth here.
    ///
    /// It used to be a fixed sixtieth, which was right for as long as every device drew at
    /// 60Hz - on a 120Hz screen it looked two frames ahead instead of one (§12.0's iPhone 17
    /// note). Now it is the frame the scene actually measured, so the question stays "will
    /// this step land the ball on the paddle" at either refresh rate.
    ///
    /// Clamped and given a floor: the first frame of a run has no previous timestamp, and a
    /// frame that took a quarter of a second - a resume, a hitch - must not have the catch
    /// reaching a quarter of a second into the future.
    ///
    /// Being a hair eager costs nothing: the catch puts the ball on `ballStartingPositionY`
    /// whatever it was doing, so an early catch sticks it exactly where a late one would.
    static let stickyLookaheadFloor: TimeInterval = 1.0/120.0
    static let stickyLookaheadCeiling: TimeInterval = 1.0/30.0

    var stickyLookahead: TimeInterval {
        min(max(frameDelta, GameScene.stickyLookaheadFloor),
            GameScene.stickyLookaheadCeiling)
    }

    /// Catches the ball on the sticky paddle if this step would land it there.
    ///
    /// Called from `update`, after `recordBallStatesBeforeStep` and before physics runs.
    ///
    /// Deliberately only the main ball. The extra balls of Multi-Ball are caught by
    /// `endlessIICatchExtraBall` on contact, and they are held in a queue rather than stopped
    /// dead - that path has its own ordering to preserve and is not what was reported.
    func catchStickyBallBeforeStep() {
        let delta = stickyLookahead
        guard stickyPaddleCatches != 0, ballIsOnPaddle == false else { return }
        guard let body = ball.physicsBody, body.velocity.dy < 0 else { return }
        // Descending only: a ball on its way up through the paddle's line is leaving, not
        // arriving, and catching it would take it back

        guard let before = ballStateBeforeStep[ObjectIdentifier(ball)] else { return }

        let paddleTop = paddle.position.y + paddleHeight/2
        let ballBottom = before.position.y - ball.size.height/2
        guard ballBottom > paddleTop else { return }
        // Already at or past the surface: this step is not the one that arrives, and the
        // ordinary contact path can have it

        let fall = -before.velocity.dy*CGFloat(delta)
        guard ballBottom - fall <= paddleTop else { return }
        // Not landing this step

        // Where it lands, rather than where it is now: at speed the ball crosses a good part of
        // its own width in a frame, and the band it is judged against is only a paddle wide
        let share = (ballBottom - paddleTop)/max(fall, 0.0001)
        let landingX = before.position.x + before.velocity.dx*CGFloat(delta)*share

        let paddleX = gameMode == .endlessII
            ? endlessIIPaddleXNearest(to: landingX) : paddle.position.x
        // The paddle copy this ball is landing on: the paddle itself, or its wrap-around
        // ghost on the far side, exactly as `paddleHit` decides it

        guard landingX > paddleX - paddle.size.width/2 + ball.size.width/3,
              landingX < paddleX + paddle.size.width/2 - ball.size.width/3 else { return }
        // The same band `paddleHit` judges a catch by, so a ball caught here and a ball caught
        // there are caught in the same places - the band is narrower than the paddle, and a
        // ball outside it must still bounce

        if endlessIIAimedStickyClock.isRunning || endlessIIAimedStickyOwedTurn {
            return
        }
        // Aimed Sticky owns the launch while it runs and catches anywhere on the top surface,
        // not just in the band. Its catch is a different thing and it happens on contact

        ball.position.x = landingX
        ballRelativePositionOnPaddle = landingX - paddleX
        // **Where on the paddle it was caught**, which is what makes the held ball ride the
        // paddle at the spot it landed. `paddleHit` sets this on the way past, and the whole
        // point of this function is that `paddleHit` no longer runs - so without this line the
        // value was whatever it was last time, and after a ball loss that is 0: dead centre.
        // The play test saw it as the ball "snapping into the middle of the paddle even if it
        // wasn't caught in the middle" (round 39)

        endlessIISpendPaddleTurns()
        // **The catch is the contact, and it spends what a contact spends** (James, round 312:
        // "with portal paddle and sticky paddle active together, sticky paddle counts turns
        // down, but portal paddle doesn't so you get extra turns. Both power-ups should count
        // down turns together. This should apply to all the turn based power ups when active
        // together").
        //
        // Round 311 gave the catch the Auto-Aim turn alone and wrote the general question down
        // in §12.0 rather than answering it. This is the answer. A sticky catch is the ball
        // landing on the paddle, and eleven Mayhem paddle clocks count paddle landings - so a
        // player running Sticky Paddle was getting free turns on every one of them, which is
        // why the sticky counter ran out while the portal's did not.
        //
        // Aimed Sticky is not double-spent: its own catch happens on contact and this function
        // returns above before reaching here while its clock runs.
        //
        // **The old comment, kept because the reasoning still holds** (James, round 311:
        // "with sticky paddle and auto aim on together, the ball should still launch towards the
        // aimed brick. Currently it launches based on the ball's position on the paddle").
        //
        // The comment at the foot of this function has always said the shape of it: "the contact
        // never happens now, so the tap and the sound `paddleHit` would have made have to be
        // made here". The turn is the third thing on that list and it was missed, so
        // `endlessIIAimTheStickyLaunch` - which correctly refuses to aim a launch that paid for
        // nothing - refused every sticky launch there has ever been.
        //
        // That reasoning asked whether one turn or all of them was right; James has said all
        // of them, so the narrow version above is gone

        performStickyCatch()
        // Moved to where it was going before it is stopped, so it sticks where it would have
        // landed rather than where it happened to be when the frame began
        touchBeganWhilstPlaying = false
        // **Only a tap launches it** (James, round 385: "For the safety paddle and mirror paddle
        // with the sticky paddle enabled, the ball launches if the finger is released from the
        // screen. It should release on a tap"). A finger already down when the ball lands is
        // in the middle of something else - moving the paddle, usually - and its lift is the
        // end of that, not a request to launch. Voided here, the lift does nothing and the next
        // touch is the tap. Aimed Sticky has asked the same question since round 383
        // (`endlessIIAimTouchPredatesHold`); the plain catches on all three surfaces ask it now

        if hapticsSetting {
            lightHaptic.impactOccurred()
        }
        if soundsSetting {
            self.run(stickyPaddleHitSound)
        }
        // The contact never happens now, so the tap and the sound `paddleHit` would have made
        // have to be made here, or the catch lands in silence and with no feel at all - which
        // is the other half of what round 39 reported
    }
}

// MARK: - The auto-release

extension GameScene {

    /// How long Sticky holds a ball before letting it go itself.
    ///
    /// James, round 385b: "If a ball is held on a sticky paddle for 10s it should release
    /// itself following a READY-GO release animation like the resume from pause animation."
    /// A held ball stops the run without pausing it - the clocks, the descent and the drops all
    /// go on - and nothing but the player's tap ever ended that, so a ball could sit there for
    /// as long as anyone cared to leave it. Ten seconds is long enough to line up any shot.
    static let stickyHoldLimit: TimeInterval = 10

    /// When READY and GO! appear, counted back from the release so the ball leaves at ten
    /// seconds exactly: READY for a second, as the resume shows it, and GO! a quarter of a
    /// second before the launch, which is when the resume's GO! starts play.
    static let stickyReadyLead: TimeInterval = 1.25
    static let stickyGoLead: TimeInterval = 0.25

    /// How many balls Sticky is holding. Mayhem keeps a queue of every caught ball, Aimed
    /// Sticky's included; elsewhere there is only the first ball, held when Sticky caught it
    /// rather than at a life's start.
    ///
    /// **Aimed Sticky counts too** (James, round 385c: "Aimed sticky should count and have a 10
    /// second auto release too, it releases at whatever angle is selected at 10s"). Round 385c
    /// first left it out, on the reading that its hold is the aim and the aim is what ends it;
    /// a held ball is a held ball, and the arrow says where it goes when the time is up.
    var stickyHeldBallCount: Int {
        if gameMode == .endlessII { return endlessIIHeldBalls.count }
        return ballIsOnPaddle && stickyCaughtTheFirstBall ? 1 : 0
    }

    /// Counts the hold, shows READY and GO!, and launches the ball at ten seconds as a tap
    /// would. Once a frame, and only in play: a pause, the resume's own countdown and the
    /// screens between levels are not time the ball was held.
    func tickStickyAutoRelease(_ delta: TimeInterval) {
        guard gameState.currentState is Playing, isPaused == false else { return }

        let held = stickyHeldBallCount
        defer { stickyHeldLastSeen = held }
        guard held > 0 else {
            stickyHoldClock = 0
            hideStickyCountdown()
            return
        }
        if held < stickyHeldLastSeen {
            stickyHoldClock = 0
            hideStickyCountdown()
        }
        // A ball has just left by a tap: the next in the queue starts its own ten seconds,
        // and a countdown that was for the one that left is taken down

        let before = stickyHoldClock
        stickyHoldClock += delta
        let limit = GameScene.stickyHoldLimit
        if before < limit - GameScene.stickyReadyLead,
           stickyHoldClock >= limit - GameScene.stickyReadyLead {
            showStickyCountdown(readyCountdown, sound: "countdownTick", hold: 0.5)
        }
        if before < limit - GameScene.stickyGoLead,
           stickyHoldClock >= limit - GameScene.stickyGoLead {
            readyCountdown.removeAllActions()
            readyCountdown.isHidden = true
            showStickyCountdown(goCountdown, sound: "countdownGo", hold: 0)
        }
        if stickyHoldClock >= limit {
            stickyHoldClock = 0
            launchStickyHeldBall()
            stickyCountdownShowing = false
            // GO! finishes its own way out, as the resume's does after play starts, rather
            // than being taken down by the next frame's empty paddle
        }
    }

    /// Launches the next held ball exactly as a tap would have - along the arrow, when Aimed
    /// Sticky is holding it.
    func launchStickyHeldBall() {
        if endlessIIAimTarget != nil, endlessIIAimLaunch() {
            touchBeganWhilstPlaying = false
            return
        }
        if endlessIITapLaunchesHeldBall {
            endlessIILaunchHeldBall()
        } else if ballIsOnPaddle {
            releaseBall()
        }
        touchBeganWhilstPlaying = false
        // A finger already down is not the launch's to finish - its lift should do nothing
    }

    /// READY or GO!, drawn the way the resume draws them: in from double size, a hold, out
    /// to half, with the same beep and the same tap. Driven by the hold's own clock rather than
    /// chained in completions, so the launch happens on the frame the clock says and a test can
    /// see it.
    private func showStickyCountdown(_ word: SKSpriteNode, sound: String, hold: TimeInterval) {
        stickyCountdownShowing = true
        word.removeAllActions()
        word.setScale(2)
        word.alpha = 0
        word.isHidden = false
        playMayhemSound(sound)
        if hapticsSetting { (sound == "countdownGo" ? heavyHaptic : mediumHaptic).impactOccurred() }
        word.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 1, duration: 0.25),
                            SKAction.fadeIn(withDuration: 0.25)]),
            SKAction.wait(forDuration: hold),
            SKAction.group([SKAction.scale(to: 0.5, duration: 0.25),
                            SKAction.fadeOut(withDuration: 0.25)]),
            SKAction.hide()
        ]))
    }

    /// Takes READY and GO! down if the auto-release put them up, and only then - the resume's
    /// countdown uses the same two words and is none of this function's business.
    func hideStickyCountdown() {
        guard stickyCountdownShowing else { return }
        stickyCountdownShowing = false
        for word in [readyCountdown, goCountdown] {
            word.removeAllActions()
            word.isHidden = true
        }
    }
}

