//
//  EndlessIIAimedSticky.swift
//  Megaball
//
//  Aimed Sticky: the ball is held, and the launch is pointed by hand.
//
//  The Sticky Paddle has always answered *whether* the ball is held; this answers *where it
//  goes next*. While the clock runs, any ball that lands on the paddle is caught, an arrow
//  shows the angle it will leave at, and dragging swings the arrow. The default is the angle
//  the ball would have bounced at anyway (§5.4), so releasing without dragging changes
//  nothing - the power-up only ever adds a choice, never a chore.
//
//  It shares the launchControl conflict group with Sticky Paddle: one thing owns the launch.
//  While this runs, it is this - a catch costs no sticky catches, and the queue the sticky
//  paddle built (§5.5) is reused whole, so with Multi-Ball the balls still leave oldest
//  first, each at its own aimed angle.
//
//  Aiming is its own moment: the catch freezes the world the way the pause menu does, the
//  drag chooses the angle while everything holds its breath, and lifting the finger fires
//  the ball and lets play go again in the same frame. Play-testing arrived here after two
//  other answers - a frozen paddle read as the game pausing by accident, and a live paddle
//  made the drag do two jobs at once.
//

import SpriteKit

extension GameScene {

    // MARK: - Catching

    /// Catches a ball for aiming, if Aimed Sticky is running. Returns whether it did.
    ///
    /// Called from `paddleHit` before the ordinary sticky check, because this owns the
    /// launch while it runs. The arriving velocity is the pre-step sample - the contact's
    /// own velocity has already been bounced by the engine (§8.6), and the *arrival* is what
    /// the default angle is the mirror of.
    func endlessIIAimedCatch(_ subject: SKSpriteNode, isExtra: Bool) -> Bool {
        guard gameMode == .endlessII,
              endlessIIAimedStickyClock.isRunning || endlessIIAimedStickyOwedTurn
        else { return false }
        guard endlessIIInertPaddleClock.isRunning == false else { return false }
        // An inert paddle holds nothing - see paddleHit's sticky band
        if endlessIIAimedStickyClock.isRunning == false {
            endlessIIAimedStickyOwedTurn = false
            endlessIIAimOwedHold = true
        }
        // The last catch still catches - the turn that expired the clock is this one.
        // The owed flag becomes a *hold* flag rather than vanishing, because everything
        // downstream - the arrow, the drag, the launch on release - asks the clock, and
        // on the owed turn the clock has already stopped. Without the hold flag the last
        // catch froze the world with no owner: no arrow, no way to launch, and the ball
        // eventually fell through a paddle that had moved on (play-test round 10).
        // Set only once the inert guard has let the catch happen, so a refused catch
        // cannot leave a stale hold behind

        endlessIIAimDefaultAngles[ObjectIdentifier(subject)] =
            endlessIIWouldHaveBouncedAngle(subject, offSurfaceAt: paddle.position.x,
                                           width: paddle.size.width)

        if isExtra {
            subject.physicsBody?.velocity = .zero
            subject.position.y = restingBallY(
                atOffsetFromCentre: subject.position.x - paddle.position.x)
            if endlessIIHeldBalls.contains(where: { $0 === subject }) == false {
                endlessIIHeldBalls.append(subject)
                endlessIIHeldOffsets.append(endlessIIHeldShare(of: subject))
                setEndlessIIHeldBallRestsOnPaddle(true, for: subject)
            }
            // **A share of the half-width, which is what the queue holds** (round 295). Round
            // 293 changed `endlessIIHeldOffsets` from points to a fraction so a ball rides a
            // resize, and converted the two catches in `EndlessIIStickyPaddle` - this third
            // one, in another file, went on appending points. The tick then multiplied that
            // number by the half-width, so an extra caught forty points out from the centre
            // was placed twenty-four hundred points out: off the screen, on the next frame,
            // every time an Aimed Sticky caught a second ball.
            //
            // The paddle also comes out of its collisions here, for round 291's reason - a
            // held ball placed inside a shaped paddle's traced body slides down the slope
            //
            // **Both branches take the height at the ball's own place across the face** (round
            // 313), rather than `ballStartingPositionY`, which is the height of the shape's
            // highest point wherever the ball actually is. The ticks would have corrected it on
            // the next frame either way - so this is about the catch frame itself, where a ball
            // caught near the end of a wedge appeared most of its own width above the paddle
            // and then dropped onto it
        } else {
            removeAction(forKey: "gameTimer")
            ballIsOnPaddle = true
            subject.physicsBody?.velocity = .zero
            ballRelativePositionOnPaddle = subject.position.x - paddle.position.x
            subject.position.y = restingBallY(atOffsetFromCentre: ballRelativePositionOnPaddle)
            // **Where it landed, not where the last launch left off** (James, round 169:
            // "all of a sudden, the other ball appeared on the middle of the paddle";
            // round 180, mid-Ghost Ball: "the ball suddenly appeared back on my paddle").
            // The on-paddle follow places the ball at `paddle.x + this offset` every frame,
            // and `releaseBall` zeroes the offset - so a caught ball sat at its landing
            // spot for one frame and then snapped to the paddle's centre, which reads as a
            // teleport. The extras' branch above has always recorded its offset
            // (`endlessIIHeldOffsets`); this is the main ball getting the same memory -
            // and it is why round 175's hunt through the extras found nothing
            endlessIIFirstBallWasCaught()
            if musicSetting { MusicHandler.sharedHelper.menuVolume() }
        }

        if soundsSetting { run(stickyPaddleHitSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }
        endlessIIBeginAimHold()
        return true
    }

    // MARK: - The hold

    /// Freezes play while the aim is chosen.
    ///
    /// The first version kept the game running and let the drag move the paddle too, and
    /// play-testing called both wrong ways round: aiming should be its own moment. So a
    /// catch stops the world - every ball, brick and laser holds where it is, exactly the
    /// way the pause menu holds them - the drag chooses the angle, and lifting the finger
    /// fires the ball and lets the world go again.
    /// **The world no longer stops** (James, round 215: "new interaction plan for aimed
    /// sticky. Drag below the paddle moves the paddle. Drag above the paddle moves the arrow
    /// relative to the drag. Tap releases the ball. The game doesn't pause. It acts more like
    /// the existing sticky power up").
    ///
    /// Aiming used to freeze every ball, brick and laser the way the pause menu does, so the
    /// shot could be chosen with everything holding its breath. Three rounds of stutter
    /// reports came out of that freeze - it stopped the world for the *scene* but not for
    /// `didSimulatePhysics`, and every writer that moves a ball kept running through it
    /// (round 210) - and the freeze was never the point. The point is being able to aim. So
    /// the hold is now only a flag saying a ball is being aimed: the field keeps descending,
    /// the other balls keep flying, and the aim is something the player does while the game
    /// carries on, exactly as the ordinary Sticky Paddle does.
    func endlessIIBeginAimHold() {
        guard endlessIIAimHold == false else { return }

        if ballIsOnPaddle == false, let velocity = ball.physicsBody?.velocity,
           velocity.dx != 0 || velocity.dy != 0 {
            pauseBallVelocityX = velocity.dx
            pauseBallVelocityY = velocity.dy
        }
        // The primary ball may be mid-flight while an extra is caught; its heading has to
        // survive the freeze the same way it survives the pause menu

        endlessIIAimHold = true
        endlessIIAimTouchPredatesHold = touchBeganWhilstPlaying
        if touchBeganWhilstPlaying { endlessIIAimDragIntent = .paddle }
        // A finger already down when the catch happens was carrying the paddle, so it goes on
        // carrying it until it is lifted. Without this the drag would become an aim mid-gesture
        // the moment the ball landed, which is the same fault as a drag that crosses the
        // paddle's edge and is the more surprising half of it: nothing the player did changed
        // A finger already on the screen when the catch happens was not put there to aim, so
        // its release is a paddle move ending rather than a tap (play-test round 275)
        // Nothing is paused and no velocity is recorded: with the world still running there is
        // nothing to put back, which is also why `endlessIIEndAimHold` has so much less to do
    }

    /// Ends a hold that has nothing left to aim.
    ///
    /// The freeze stops every ball, brick and laser on the field, so it must never outlive the
    /// shot it was taken for. `endlessIIAimLaunch` ends it on the way out and round 182's
    /// ball-lost path ends it when the held ball reaches the bottom - this is the backstop for
    /// every other way the target could go (a Wipe, a life lost, a resume, a power-up that
    /// empties the queue), because a frozen world with no arrow and no ball to fire is a game
    /// that has stopped rather than a game that is waiting.
    ///
    /// Called once a frame from the paddle tick, which runs whatever else is happening.
    func tickEndlessIIAimHold() {
        guard endlessIIAimHold, endlessIIAimTarget == nil else { return }
        endlessIIEndAimHold(launching: nil)
    }

    /// Lets the world go again, restoring every heading the freeze took.
    ///
    /// The launching ball is skipped - its velocity belongs to the aim, applied by the
    /// caller straight after this returns.
    func endlessIIEndAimHold(launching: SKSpriteNode?) {
        guard endlessIIAimHold else { return }
        endlessIIAimHold = false

        // **Nothing to wake** since round 215: the aim no longer stops the world, so there is
        // no paused node to unpause and no stored heading to hand back. What is left of this
        // method is the flag above, and the launch the caller applies straight after.

        directionMarker.isHidden = true
        endlessIIHideExtraDirectionMarkers()
    }

    /// The ball whose launch is currently being aimed: the head of the held queue. The
    /// owed hold counts - the last catch of an expired clock is still an aimed catch.
    var endlessIIAimTarget: SKSpriteNode? {
        guard gameMode == .endlessII,
              endlessIIAimedStickyClock.isRunning || endlessIIAimOwedHold
        else { return nil }
        return endlessIINextHeldBall
    }

    /// The angle this ball would have left at, had the surface bounced it instead of catching
    /// it - the arrow's starting point before the finger has said anything.
    ///
    /// **James, round 312: "have the aimed sticky arrow aim where the ball would've bounced off
    /// the paddle as its starting angle."** It used `defaultLaunchAngle(arriving:)`, which is the
    /// arriving direction with its vertical flipped - a mirror bounce off a flat plate. That is
    /// not what this paddle does: a real bounce is steered by *where across the paddle* the ball
    /// landed, and by the shape, the Inert clock, the Flipped Angle and the grip. So the arrow
    /// started somewhere the ball would never have gone, and a player who released without
    /// aiming got a shot they had not been shown.
    ///
    /// `PaddleBounce.angleDegrees` is the same call `paddleHit` makes, with the same collision
    /// offset and the same influence, so the arrow's opening angle and an unaimed bounce cannot
    /// give different answers.
    func endlessIIWouldHaveBouncedAngle(_ subject: SKSpriteNode,
                                        offSurfaceAt surfaceX: CGFloat,
                                        width: CGFloat) -> Double {
        let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
            ?? subject.physicsBody?.velocity ?? .zero
        guard width > 0 else {
            return EndlessIIPaddleEffects.defaultLaunchAngle(arriving: arriving)
        }
        let collision = PaddleBounce.collision(ballX: subject.position.x,
                                               paddleX: surfaceX, paddleWidth: width)
        let degrees = PaddleBounce.angleDegrees(
            arriving: arriving,
            collision: PaddleBounce.shaped(min(max(collision, -1), 1),
                                           by: endlessIIPaddleSurface),
            adjustmentK: angleAdjustmentK,
            influence: endlessIIPaddleAngleInfluence,
            minimumDeg: minAngleDeg)
        return degrees*Double.pi/180
    }

    /// The angle the aim currently points at: the finger's absolute position across the
    /// screen once it has moved, the default bounce until then.
    func endlessIIAimAngle(for target: SKSpriteNode) -> Double {
        if endlessIIAimTouched {
            return EndlessIIPaddleEffects.aimedAngle(
                at: CGPoint(x: endlessIIAimTouchX, y: endlessIIAimTouchY),
                from: target.position,
                minimum: minLaunchAngleRad)
            // **The arrow points at the finger** (round 232). Round 10's version mapped the
            // finger's x across the screen onto a fixed arc: absolute, which was right, but
            // with no relationship to where the ball was - so aiming at a brick meant learning
            // the mapping rather than pointing at the brick
        }
        let fallback = straightLaunchAngleRad + minLaunchAngleRad
        return endlessIIAimDefaultAngles[ObjectIdentifier(target)] ?? fallback
    }

    // MARK: - The touches

    /// A moving finger while a ball is being aimed *is* the aim - absolute, so where the
    /// thumb sits on the screen is where the arrow points. Returns whether it took the
    /// touch - the caller skips moving the paddle while aiming.
    func endlessIIAimMoved(to point: CGPoint) -> Bool {
        guard endlessIIAimTarget != nil else { return false }
        endlessIIAimTouchX = point.x
        endlessIIAimTouchY = point.y
        endlessIIAimTouched = true
        return true
    }

    /// A tap or release while a ball is being aimed launches it. Returns whether it did.
    func endlessIIAimLaunch() -> Bool {
        guard let target = endlessIIAimTarget else { return false }

        endlessIIEndAimHold(launching: target)
        // The world goes first, so the launch velocity below is not overwritten by the
        // restore - and everything else resumes in the same frame the shot leaves

        let angle = endlessIIAimAngle(for: target)
        if endlessIIAimLaunchesThroughThePaddle {
            endlessIIPortalTheAimedLaunch(target, angle: angle)
        } else {
            target.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                                    dy: sin(angle)*Double(ballSpeedLimit))
        }
        endlessIIAimDefaultAngles[ObjectIdentifier(target)] = nil
        endlessIIAimTouched = false
        endlessIIAimOwedHold = false
        endlessIIReleasedFromPaddle(target)
        // Out of the queue, and no sticky catch is spent - this owns the launch (§5.4)

        if target === ball {
            ballIsOnPaddle = false
            ballLostBool = false
            brickBounceCounter = 0
            startLevelTimer()
            if musicSetting { MusicHandler.sharedHelper.gameVolume() }
        }

        if soundsSetting { run(ballReleaseSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }
        return true
    }

    /// Whether an aimed shot leaves *through* the paddle rather than off it.
    ///
    /// Aimed Sticky catches the ball before Portal Paddle can swallow it, so with both running
    /// the aim won the contact and the portal did nothing with the turn it had just spent
    /// (play-test round 128). The two speak in sequence instead, as they do with Auto-Aim: the
    /// aim still chooses the heading, and the paddle still swallows the ball - so the shot
    /// arrives at the *top* of the field travelling down, which is the whole gift of a portal
    /// paddle and the reason to be holding one.
    var endlessIIAimLaunchesThroughThePaddle: Bool {
        endlessIIPortalPaddleClock.isRunning || endlessIIPortalPaddleOwedTurn
    }

    /// Sends an aimed shot out through the paddle and back in at the top.
    ///
    /// The same exit `applyEndlessIIPaddlePortals` uses, with the aim's angle instead of the
    /// bounce's: a Portal brick if the field has one, and the top of the play area otherwise,
    /// where the heading is mirrored downward because a ball re-entering upward would only buy
    /// an immediate bounce off the ceiling.
    func endlessIIPortalTheAimedLaunch(_ target: SKSpriteNode, angle: Double) {
        endlessIIPortalPaddleOwedTurn = false
        let speed = Double(ballSpeedLimit)
        let from = target.position

        if let portal = endlessIIPortals().randomElement() {
            target.position = CGPoint(x: portal.position.x,
                                      y: portal.frame.maxY + target.size.height)
            target.physicsBody?.velocity = CGVector(dx: cos(angle)*speed,
                                                    dy: sin(angle)*speed)
            portal.run(.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                                  .fadeAlpha(to: 1, duration: 0.12)]))
        } else {
            target.position = CGPoint(x: target.position.x,
                                      y: frame.height/2 - topScreenBlock.size.height
                                         - target.size.height)
            target.physicsBody?.velocity = CGVector(dx: cos(angle)*speed,
                                                    dy: -abs(sin(angle)*speed))
        }
        endlessIIShowPortalJump(from: from, to: target.position)
        if hapticsSetting { mediumHaptic.impactOccurred() }
        playMayhemSound("paddlePortal")
    }

    // MARK: - The arrow

    /// Keeps the arrow on the aimed ball, pointing where the launch will go.
    ///
    /// Per frame, because the target rides the paddle and the aim rides the finger. No
    /// target, no arrow.
    func tickEndlessIIAim() {
        guard let target = endlessIIAimTarget, target.parent != nil else {
            endlessIIAimArrow?.removeFromParent()
            endlessIIAimArrow = nil
            return
        }

        let arrow = endlessIIAimArrow ?? {
            let node = SKShapeNode()
            node.zPosition = 9
            // A pathless parent: the line hangs off it as segments, because one node wears
            // one stroke and the fade needs a different one every step. Over everything -
            // an aiming aid that can hide behind a brick is not aiming anything

            let length = max(ballSize*4.5,
                             finalBrickRowHeight - brickHeight/2 - target.position.y - ballSize)
            // From the held ball almost to the lowest brick row (play-test round 36 - the
            // third lengthening, each one asking for more reach, so this one goes to the
            // thing itself: where the bricks begin, less a ball's grace. The max keeps the
            // round-10 length as the floor for the rare catch high up the field

            // **The line it was before round 260, drawn the way round 260 draws things, and
            // no arrowhead** (James, play-test round 275: "the new line looks bad. Let's go
            // back to something more similar to what was there previously, but with no arrow
            // head").
            //
            // Round 260 gave the aim the trajectory's own look - a white core inside a wide
            // green glow - on the reasoning that the two aids should speak one visual
            // language. The reasoning holds for the *trajectory*, which is a prediction the
            // player reads; it does not hold here, because this is a control the player is
            // steering, and a thick soft white line is a worse pointer than a thin bright
            // green one. The white core has gone and so has most of the blur: what is left is
            // the green glowing line of rounds 39 to 260, at its own widths and its own fade.
            //
            // **What it keeps from round 260 is how it is drawn.** The old line was a run of
            // glowing `SKShapeNode`s, which is exactly what round 258 took out of the
            // trajectory for costing an offscreen pass each, every frame - sixty of them here.
            // `FadingLine`'s sprites give the same picture in one batch, so going back to the
            // old *look* costs nothing to go back to.
            //
            // The head stays gone: James asked for that in round 260 and again here.
            let step = max(ballSize*0.9, 1)
            let pieces = max(Int((length/step).rounded(.up)), 1)
            for piece in 0..<pieces {
                let a = length*CGFloat(piece)/CGFloat(pieces)
                let b = length*CGFloat(piece + 1)/CGFloat(pieces)
                let along = (a + b)/2/length
                let certainty = pow(1 - along, 1.8)

                let segment = FadingLine.segment(glow: true, soft: true)
                FadingLine.lay(segment,
                               from: CGPoint(x: a, y: 0), to: CGPoint(x: b, y: 0),
                               width: 5.9*(1 + (1 - certainty)
                                           + (1 - certainty)*(1 - certainty)),
                               alpha: max(0.2, certainty),
                               soft: true)
                node.addChild(segment)
                // **The same widths, on the soft picture, fading further** (James, round 280:
                // "I like this style, I'd just like it to be a bit more blurred, and to fade
                // out the further from the ball it gets. This width is good though").
                //
                // Those two asks are in tension inside one texture. How much of a segment is
                // solid and how much is falloff is decided by the *picture*, not by anything
                // `lay` is told - so more blur at the same width means a smaller core, which
                // means a second picture. `FadingLine.softTexture` is a seventh solid against
                // the ordinary one's third, and at the same drawn width that is a bright thread
                // inside a wide haze rather than a bar with soft edges.
                //
                // The width is therefore said as a width. Round 276 chose these numbers against
                // the line James liked, in core-and-blur; here they are the same drawn sizes -
                // 5.9 points at the ball, three times that at the far end - said in the units
                // that survive a change of picture.
                //
                // The floor drops from 0.6 to 0.2, which is the fade. Round 276 raised it to
                // 0.6 to stop the line washing to olive, and the soft picture does not need
                // that: it is dimmer everywhere, so the near end carries the brightness and the
                // far end is free to go. A floor at all is the one difference from the
                // trajectory, and always was - a blurred tip is honest, a vanished one is an
                // aiming aid that has stopped aiming
            }

            addChild(node)
            endlessIIAimArrow = node
            return node
        }()

        let angle = endlessIIAimAngle(for: target)
        if endlessIIAimLaunchesThroughThePaddle {
            arrow.position = CGPoint(x: target.position.x,
                                     y: frame.height/2 - topScreenBlock.size.height
                                        - target.size.height)
            arrow.zRotation = CGFloat(-angle)
            // **Pointing down from the top** (play-test round 128). With Portal Paddle the
            // shot leaves through the paddle and arrives at the top of the field, so an arrow
            // rising from the ball would be showing a flight that does not happen. Drawn where
            // the ball will *appear*, at the heading it will appear with - the launch mirrors
            // the angle downward and so does this, from the same number
        } else {
            arrow.position = target.position
            arrow.zRotation = CGFloat(angle)
        }
    }

    /// Removes the aim state entirely. For resets and the batch ending.
    func endlessIIEndAim() {
        endlessIIAimTouched = false
        endlessIIAimOwedHold = false
        endlessIIAimDefaultAngles.removeAll()
        endlessIIAimArrow?.removeFromParent()
        endlessIIAimArrow = nil
    }
}
