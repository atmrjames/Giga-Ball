//
//  EndlessIIStickyPaddle.swift
//  Megaball
//
//  A sticky paddle that holds more than one ball, in Endless 2.0 only.
//
//  The paddle has always held exactly one ball, because there has only ever been one. With
//  Multi-Ball there may be four, and a paddle that catches the first and bounces the rest is
//  a power-up that quietly stops working the moment another power-up is collected.
//
//  So the paddle holds a queue rather than a ball. Every ball that lands in the sticky band is
//  caught and sits where it landed; each launch tap sends the *oldest* one on its way, which is
//  the order they were caught in and the only order a player can predict. The rest keep waiting.
//
//  The first ball is in the queue too, rather than being handled beside it. It is the one the
//  rest of the game holds and the one `releaseBall` launches, but for the purpose of whose turn
//  it is it is simply the ball that was caught whenever it was caught - so a first ball caught
//  after an extra goes second, which is what "first caught goes first" has to mean.
//

import SpriteKit

extension GameScene {

    /// Whether the sticky paddle is holding anything beyond the first ball.
    var endlessIIHasHeldExtras: Bool {
        endlessIIHeldBalls.contains { $0 !== ball && $0.parent != nil }
    }

    /// Whose turn it is to launch.
    ///
    /// The head of the queue, skipping anything that has left the scene - a ball can be lost
    /// while the paddle is holding it if the paddle is driven out from under it by a portal or
    /// a wrap.
    ///
    /// **Skipping is not enough on its own** (round 182): an extra that is lost leaves the
    /// scene and is skipped for ever, but the primary ball is never removed from the scene -
    /// only repositioned - so a stale entry for it can never be skipped, and it sat at the
    /// head of the queue holding the aim hostage. `endlessIIBallWasLost` releases a lost ball
    /// now, which is the fix; this stays as the belt to that pair of braces, and the prune
    /// below keeps the queue from growing a tail of dead extras across a long run.
    var endlessIINextHeldBall: SKSpriteNode? {
        endlessIIHeldBalls.first { $0.parent != nil }
    }

    /// Drops anything from the queue that is no longer on the field.
    ///
    /// Called from the paddle tick, so a queue can never carry a node the scene has let go -
    /// the offsets are kept in step index for index, which is why this cannot simply filter.
    func pruneEndlessIIHeldBalls() {
        guard endlessIIHeldBalls.isEmpty == false else { return }
        for index in endlessIIHeldBalls.indices.reversed()
        where endlessIIHeldBalls[index].parent == nil {
            setEndlessIIHeldBallRestsOnPaddle(false, for: endlessIIHeldBalls[index])
            endlessIISafetyHeldBalls.remove(ObjectIdentifier(endlessIIHeldBalls[index]))
            endlessIIHeldBalls.remove(at: index)
            if endlessIIHeldOffsets.indices.contains(index) {
                endlessIIHeldOffsets.remove(at: index)
            }
        }
    }

    /// Whether a tap should launch a held extra rather than the first ball.
    ///
    /// The first ball resting on the paddle at the start of a life is not in the queue, so it
    /// launches as it always has. Once the queue has something in it, the queue decides.
    var endlessIITapLaunchesHeldBall: Bool {
        guard gameMode == .endlessII else { return false }
        guard let next = endlessIINextHeldBall else { return false }
        return next !== ball || endlessIIIsHeldOnSafetyBar(next)
        // **The first ball counts too when it is on the safety bar** (round 285). It is excluded
        // here because a first ball resting on the *paddle* at the start of a life is launched
        // by `releaseBall`, which is six years of code this queue does not want to duplicate -
        // but a ball caught on the bar is not on the paddle, is not at the start of a life, and
        // has nothing else in the game that would ever let it go
    }

    /// Catches an extra ball on the sticky paddle.
    ///
    /// Returns whether it was caught, so the caller knows not to bounce it.
    @discardableResult
    func endlessIICatchExtraBall(_ extra: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, stickyPaddleCatches != 0 else { return false }
        guard endlessIIHeldBalls.contains(where: { $0 === extra }) == false else { return true }

        extra.physicsBody?.velocity = .zero
        extra.position.y = ballStartingPositionY
        endlessIIHeldBalls.append(extra)
        endlessIIHeldOffsets.append(endlessIIHeldShare(of: extra))
        setEndlessIIHeldBallRestsOnPaddle(true, for: extra)
        // Where on the paddle it landed, kept as an offset so it rides the paddle rather than
        // sitting still while the paddle moves out from under it - and so it launches at the
        // angle its own landing spot earns, exactly as the first ball does

        if endlessIIRetroHidesPaddleTop {
            paddleRetroStickyTexture.isHidden = false
        }
        // Retro's own sticky layer, and only when retro is actually using it. A paddle wearing
        // the grip shows the shared overlay instead, and putting this one up as well would be
        // retro's sticky picture laid over everybody else's grip
        return true
    }

    /// Notes that the first ball has been caught, so it takes its place in the queue.
    func endlessIIFirstBallWasCaught() {
        guard gameMode == .endlessII else { return }
        guard endlessIIHeldBalls.contains(where: { $0 === ball }) == false else { return }
        endlessIIHeldBalls.append(ball)
        endlessIIHeldOffsets.append(endlessIIHeldShare(of: ball))
        setEndlessIIHeldBallRestsOnPaddle(true, for: ball)
    }

    /// Where a ball is sitting across the paddle, as a fraction of its half-width.
    ///
    /// **A share rather than a distance** (James, round 293: "when the paddle resizes with
    /// sticky paddle power-ups active and a ball on the paddle, the ball should move to
    /// maintain its relative position on the paddle").
    ///
    /// The queue used to keep the offset in points, taken at the catch and written back every
    /// frame. That holds a ball still relative to the *field* while the paddle grows or shrinks
    /// underneath it - so a ball caught at the very tip of a paddle that then expands ends up
    /// somewhere in its middle, and one on a paddle that shrinks slides off the end and hangs
    /// in the air beside it. A share is the same number the launch angle has always been
    /// measured in, so the ball also leaves at the angle its *current* spot earns rather than
    /// the one its old spot did.
    ///
    /// Measured against the drawn half-width, because Expand and Shrink animate `xScale` and
    /// never touch `paddle.size.width` - see `endlessIIPaddleHalfWidth`.
    func endlessIIHeldShare(of subject: SKSpriteNode) -> CGFloat {
        let half = endlessIIPaddleHalfWidth
        guard half > 0 else { return 0 }
        return (subject.position.x - paddle.position.x)/half
    }

    /// Takes the paddle out of a held ball's collisions, and puts it back on launch.
    ///
    /// **James, round 291: "with a sticky shaped paddle, the ball moves on the paddle after it
    /// has landed. Like it slides down the paddle's shape. The ball should remain fixed in
    /// position relative to the paddle once it's been caught."**
    ///
    /// A held ball is *placed* every frame - on the paddle's x plus the offset it landed at,
    /// at `ballStartingPositionY` - and that placement happens in `update`, before the physics
    /// step. On a plain paddle the two never disagree: the ball sits on a flat top and the
    /// engine finds nothing to resolve. On a **shaped** one, `ballStartingPositionY` is a
    /// single height for a surface that is a dome or a dish, so a ball placed anywhere but the
    /// middle is placed slightly *inside* the traced body - and the engine's job is to push
    /// overlapping bodies apart, which on a slope means sideways. Every frame: written to the
    /// right place, pushed down the slope, written back. That is the slide.
    ///
    /// Clearing the paddle's bit is the same move the safety bar makes for a climbing ball
    /// (`setEndlessIISafetyPaddleReachable`) and for the same reason - it is written on *the
    /// ball's* body rather than the paddle's, so four balls can each be told something
    /// different about the same surface, and a caught ball is the only one being told anything.
    ///
    /// The contact bit goes with it. A ball resting on the paddle should not be reporting fresh
    /// landings, which is what `paddleLandingFrame` has been guarding against since round 259.
    func setEndlessIIHeldBallRestsOnPaddle(_ held: Bool, for subject: SKSpriteNode) {
        guard let body = subject.physicsBody else { return }
        let bit = CollisionTypes.paddleCategory.rawValue
        let collision = held ? body.collisionBitMask & ~bit : body.collisionBitMask | bit
        let contact = held ? body.contactTestBitMask & ~bit : body.contactTestBitMask | bit
        if body.collisionBitMask != collision { body.collisionBitMask = collision }
        if body.contactTestBitMask != contact { body.contactTestBitMask = contact }
    }

    /// Takes a ball out of the queue as it launches.
    func endlessIIReleasedFromPaddle(_ launched: SKSpriteNode) {
        guard let index = endlessIIHeldBalls.firstIndex(where: { $0 === launched }) else { return }
        endlessIIHeldBalls.remove(at: index)
        endlessIIHeldOffsets.remove(at: index)
        endlessIISafetyHeldBalls.remove(ObjectIdentifier(launched))
        setEndlessIIHeldBallRestsOnPaddle(false, for: launched)
        endlessIIRefreshStickyPaddleLook()
    }

    /// Launches the oldest held extra.
    ///
    /// The launch angle comes from where it is sitting on the paddle, by the same rule the
    /// first ball's does - a ball caught at the edge leaves steeply and one caught in the
    /// middle leaves near enough straight up.
    func endlessIILaunchHeldBall() {
        guard let extra = endlessIINextHeldBall else { return }
        guard extra !== ball || endlessIIIsHeldOnSafetyBar(extra) else { return }

        let offset: Double
        if endlessIIIsHeldOnSafetyBar(extra) {
            offset = endlessIISafetyBarOffset(of: extra)
                ?? Double(endlessIIHeldShare(of: extra))
        } else {
            offset = Double(endlessIIHeldShare(of: extra))
        }
        // Read off the ball's live position rather than out of the queue, because the two agree
        // now and the live one is also right for a ball the player has watched move: a ball
        // carried by a resize leaves at the angle where it *is*
        let angle = endlessIILaunchAngle(atPaddleOffset: offset)
        // **The same arithmetic off a different surface** (James, round 284: a sticky safety
        // paddle's ball "goes up, like it would from the paddle"). All that changes is whose
        // width the landing spot is a fraction of - the angle rule itself is the one written
        // once below, so the two surfaces cannot drift apart
        extra.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                               dy: sin(angle)*Double(ballSpeedLimit))
        endlessIIReleasedFromPaddle(extra)
        spendStickyPaddleCatch()
        endlessIIAimTheStickyLaunch(extra)
        // A held extra leaves by the same bargain as the first ball: its catch spent the
        // Auto-Aim turn, so its launch is the shot that turn bought

        if soundsSetting { run(ballReleaseSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }
    }

    /// The launch angle for a ball sitting at this fraction across the paddle.
    ///
    /// The same arithmetic `releaseBall` does for the first ball, written once so the two
    /// cannot drift apart - a held extra that launched by a different rule would be a
    /// different power-up depending on which ball you were watching.
    func endlessIILaunchAngle(atPaddleOffset offset: Double) -> Double {
        let clamped = min(max(offset, -1), 1)
        guard clamped != 0 else {
            return Bool.random()
                ? straightLaunchAngleRad + minLaunchAngleRad
                : straightLaunchAngleRad - minLaunchAngleRad
        }
        let multiplier: Double = clamped < 0 ? 1 : -1
        return straightLaunchAngleRad
            - ((maxLaunchAngleRad - minLaunchAngleRad)*clamped)
            + (minLaunchAngleRad*multiplier)
    }

    /// Keeps every held ball on the paddle as it moves.
    ///
    /// Per frame, because the paddle is under the player's finger. The first ball is left
    /// alone - the existing code has moved it with the paddle since 2020, and two things
    /// writing the same position is how a ball ends up jittering between them.
    func tickEndlessIIHeldBalls() {
        guard gameMode == .endlessII, endlessIIHeldBalls.isEmpty == false else { return }
        pruneEndlessIIHeldBalls()
        guard endlessIIHeldBalls.isEmpty == false else { return }

        for (index, held) in endlessIIHeldBalls.enumerated() where held !== ball {
            guard held.parent != nil else { continue }
            if endlessIIIsHeldOnSafetyBar(held) {
                held.physicsBody?.velocity = .zero
                continue
                // A ball on the safety bar rides nothing: the bar stands in the middle of the
                // field and never moves sideways, so the ball stays exactly where it landed.
                // Held still all the same - a body left with its own velocity would drift off
                // a surface nothing is writing a position for
            }
            let share = endlessIIHeldOffsets.indices.contains(index) ? endlessIIHeldOffsets[index] : 0
            held.position.x = paddle.position.x + share*endlessIIPaddleHalfWidth
            held.position.y = ballStartingPositionY
            held.physicsBody?.velocity = .zero
            // The share is reconstituted against the paddle's *current* half-width, which is
            // what carries the ball with a resize instead of leaving it behind
        }

        endlessIIDropHeldBallsThatLeft()
    }

    /// Forgets any held ball that is no longer in the scene.
    private func endlessIIDropHeldBallsThatLeft() {
        var index = 0
        while index < endlessIIHeldBalls.count {
            if endlessIIHeldBalls[index].parent == nil {
                endlessIIHeldBalls.remove(at: index)
                if endlessIIHeldOffsets.indices.contains(index) {
                    endlessIIHeldOffsets.remove(at: index)
                }
            } else {
                index += 1
            }
        }
    }

    /// Hides the sticky look once the paddle is holding nothing.
    /// Not private since round 285: the safety bar catches balls too, and a catch that did
    /// not refresh the look would leave the sticky overlay saying nothing had happened.
    func endlessIIRefreshStickyPaddleLook() {
        guard endlessIIHasHeldExtras == false, ballIsOnPaddle == false else { return }
        if paddleTexture == retroPaddle {
            paddleRetroStickyTexture.isHidden = true
        }
    }

    /// Launches everything the paddle is still holding, each at its own spot's angle.
    ///
    /// For the sticky paddle ending while balls are still caught. The first ball is left
    /// alone - resting on the paddle is its ordinary state, and launching it belongs to the
    /// player's tap.
    func endlessIIReleaseRemainingHeldBalls() {
        guard gameMode == .endlessII, endlessIIAimedStickyClock.isRunning == false else { return }
        // Aimed Sticky holds its own licence to keep them

        while let held = endlessIINextHeldBall {
            // **The first ball leaves with the rest** (James, round 291: "if multiple balls are
            // in play and the paddle is sticky and there are 2 balls on the paddle and it's the
            // last turn for the sticky power up, launch both balls at the same time"). This
            // used to stop at the primary ball, so the last catch launched one ball and left
            // the other stuck to a paddle that was no longer sticky - it could only be freed by
            // losing it.
            //
            // **Being in the queue is the whole test**, and the first version of this fix asked
            // `ballIsOnPaddle` as well, which was wrong in the one way that mattered: the
            // classic sticky catch sets that flag *and then* calls
            // `endlessIIFirstBallWasCaught`, so a caught first ball has it set exactly as a
            // waiting serve does. The guard skipped the case it was written for. What tells the
            // two apart is the queue - a serve is never in it, because only a catch puts it
            // there - and the loop already walks nothing else.
            if held === ball { ballIsOnPaddle = false }
            // And the flag has to come off, or the code that has kept the first ball on the
            // paddle since 2020 would carry it straight back down

            let offset = endlessIIIsHeldOnSafetyBar(held)
                ? (endlessIISafetyBarOffset(of: held) ?? Double(endlessIIHeldShare(of: held)))
                : Double(endlessIIHeldShare(of: held))
            // Whichever surface is holding it, the same way `endlessIILaunchHeldBall` asks
            let angle = endlessIILaunchAngle(atPaddleOffset: offset)
            held.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                                  dy: sin(angle)*Double(ballSpeedLimit))
            endlessIIAimTheStickyLaunch(held)
            // **This loop had no aim at all** (round 311). Every other way a ball leaves the
            // paddle asks Auto-Aim what it thinks; the last-turn release, which lets go of the
            // whole queue at once, went straight out on the offset. Two balls launched by
            // different rules in the same instant is the drift `endlessIILaunchAngle` exists to
            // stop, arriving one level up
            endlessIIReleasedFromPaddle(held)
        }
        if endlessIIHeldBalls.contains(where: { $0 === ball }) == false {
            // Nothing left in the queue but flight - the sticky look can go too
            paddleRetroStickyTexture.isHidden = true
        }
    }

    /// Empties the paddle. For losing the life, resetting, and starting again.
    func endlessIIClearHeldBalls() {
        endlessIIHeldBalls.forEach { setEndlessIIHeldBallRestsOnPaddle(false, for: $0) }
        endlessIIHeldBalls.removeAll()
        endlessIIHeldOffsets.removeAll()
        endlessIISafetyHeldBalls.removeAll()
        // Every ball gets the paddle back, or a queue emptied by a Wipe would leave balls
        // falling through the paddle for the rest of the run
    }
}
