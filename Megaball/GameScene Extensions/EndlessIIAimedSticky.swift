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

        let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
            ?? subject.physicsBody?.velocity ?? .zero
        endlessIIAimDefaultAngles[ObjectIdentifier(subject)] =
            EndlessIIPaddleEffects.defaultLaunchAngle(arriving: arriving)

        if isExtra {
            subject.physicsBody?.velocity = .zero
            subject.position.y = ballStartingPositionY
            if endlessIIHeldBalls.contains(where: { $0 === subject }) == false {
                endlessIIHeldBalls.append(subject)
                endlessIIHeldOffsets.append(subject.position.x - paddle.position.x)
            }
        } else {
            removeAction(forKey: "gameTimer")
            ballIsOnPaddle = true
            subject.physicsBody?.velocity = .zero
            subject.position.y = ballStartingPositionY
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
    func endlessIIBeginAimHold() {
        guard endlessIIAimHold == false else { return }

        if ballIsOnPaddle == false, let velocity = ball.physicsBody?.velocity,
           velocity.dx != 0 || velocity.dy != 0 {
            pauseBallVelocityX = velocity.dx
            pauseBallVelocityY = velocity.dy
        }
        // The primary ball may be mid-flight while an extra is caught; its heading has to
        // survive the freeze the same way it survives the pause menu

        endlessIIRecordExtraBallVelocities()
        pauseAllNodes()
        endlessIIAimHold = true
    }

    /// Lets the world go again, restoring every heading the freeze took.
    ///
    /// The launching ball is skipped - its velocity belongs to the aim, applied by the
    /// caller straight after this returns.
    func endlessIIEndAimHold(launching: SKSpriteNode?) {
        guard endlessIIAimHold else { return }
        endlessIIAimHold = false

        for name in [PaddleCategoryName, BallCategoryName, BrickCategoryName,
                     BrickRemovalCategoryName, LaserCategoryName] {
            enumerateChildNodes(withName: name) { node, _ in node.isPaused = false }
        }
        enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            let move = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 7.5)
            node.run(move, withKey: "PowerUpDrop")
        }
        // The same wake the pause menu's countdown gives - the drops lost their action when
        // the world froze, so they are set falling again

        if launching !== ball, ballIsOnPaddle == false,
           endlessIIHeldBalls.contains(where: { $0 === ball }) == false,
           pauseBallVelocityX != 0 || pauseBallVelocityY != 0 {
            ball.physicsBody?.velocity = CGVector(dx: pauseBallVelocityX,
                                                  dy: pauseBallVelocityY)
            pauseBallVelocityX = 0
            pauseBallVelocityY = 0
        }
        for (index, extra) in endlessIIExtraBalls.enumerated() {
            guard extra !== launching, extra.parent != nil else { continue }
            guard endlessIIHeldBalls.contains(where: { $0 === extra }) == false else { continue }
            guard pauseExtraBallVelocities.indices.contains(index) else { continue }
            extra.physicsBody?.velocity = pauseExtraBallVelocities[index]
        }
        pauseExtraBallVelocities.removeAll()
        // Everything the freeze stopped is sent on its way - except what the paddle is
        // still holding, which stays held

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

    /// The angle the aim currently points at: the finger's absolute position across the
    /// screen once it has moved, the default bounce until then.
    func endlessIIAimAngle(for target: SKSpriteNode) -> Double {
        if endlessIIAimTouched {
            return EndlessIIPaddleEffects.aimedAngle(
                fingerFraction: Double(endlessIIAimTouchX/(gameWidth/2)),
                straight: straightLaunchAngleRad,
                maximum: maxLaunchAngleRad)
        }
        let fallback = straightLaunchAngleRad + minLaunchAngleRad
        return endlessIIAimDefaultAngles[ObjectIdentifier(target)] ?? fallback
    }

    // MARK: - The touches

    /// A moving finger while a ball is being aimed *is* the aim - absolute, so where the
    /// thumb sits on the screen is where the arrow points. Returns whether it took the
    /// touch - the caller skips moving the paddle while aiming.
    func endlessIIAimMoved(to x: CGFloat) -> Bool {
        guard endlessIIAimTarget != nil else { return false }
        endlessIIAimTouchX = x
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
        target.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                                dy: sin(angle)*Double(ballSpeedLimit))
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
            // The Giga-Ball green the mode uses for anything of its own, over everything -
            // an aiming aid that can hide behind a brick is not aiming anything.
            // A pathless parent now: the shaft hangs off it as segments, because one node
            // wears one stroke and the fuzziness needs a different stroke every step

            let length = max(ballSize*4.5,
                             finalBrickRowHeight - brickHeight/2 - target.position.y - ballSize)
            // From the held ball almost to the lowest brick row (play-test round 36 - the
            // third lengthening, each one asking for more reach, so this one goes to the
            // thing itself: where the bricks begin, less a ball's grace. The max keeps the
            // round-10 length as the floor for the rare catch high up the field

            // Fuzzy like the trajectory line, so the two aiming aids speak one visual
            // language (play-test round 39): crisp at the ball, and the further it looks
            // the wider, softer and fainter the stroke - the same swell-and-glow the
            // trajectory wears, on the same curve. With one difference, because this is
            // the control the player is actively steering: the alpha keeps a floor and
            // the head stays legible. A blurred tip is honest; a vanished one is an
            // aiming aid that stopped aiming
            let step = max(ballSize*0.9, 1)
            let pieces = max(Int((length/step).rounded(.up)), 1)
            for piece in 0..<pieces {
                let a = length*CGFloat(piece)/CGFloat(pieces)
                let b = length*CGFloat(piece + 1)/CGFloat(pieces)
                let along = (a + b)/2/length
                let certainty = pow(1 - along, 1.8)

                let segment = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: a, y: 0))
                path.addLine(to: CGPoint(x: b, y: 0))
                segment.path = path
                segment.strokeColor = GameScene.endlessIIHaloColour
                    .withAlphaComponent(max(0.3, 0.95*certainty))
                segment.lineWidth = 2 + (1 - certainty)*2
                segment.glowWidth = (1 - certainty)*(1 - certainty)*6
                segment.lineCap = .round
                node.addChild(segment)
            }

            let head = SKShapeNode()
            let headPath = CGMutablePath()
            headPath.move(to: CGPoint(x: length - ballSize*0.7, y: ballSize*0.55))
            headPath.addLine(to: CGPoint(x: length, y: 0))
            headPath.addLine(to: CGPoint(x: length - ballSize*0.7, y: -ballSize*0.55))
            head.path = headPath
            head.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.55)
            head.lineWidth = 2.5
            head.glowWidth = 3
            head.lineCap = .round
            node.addChild(head)
            // The head wears the far end's blur but not its fade - soft-edged and glowing
            // like the trajectory's tail, and still unmistakably the pointer

            addChild(node)
            endlessIIAimArrow = node
            return node
        }()

        arrow.position = target.position
        arrow.zRotation = CGFloat(endlessIIAimAngle(for: target))
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
