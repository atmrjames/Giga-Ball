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
        guard gameMode == .endlessII, endlessIIAimedStickyClock.isRunning else { return false }

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

    /// The ball whose launch is currently being aimed: the head of the held queue.
    var endlessIIAimTarget: SKSpriteNode? {
        guard gameMode == .endlessII, endlessIIAimedStickyClock.isRunning else { return nil }
        return endlessIINextHeldBall
    }

    /// The angle the aim currently points at.
    func endlessIIAimAngle(for target: SKSpriteNode) -> Double {
        let fallback = straightLaunchAngleRad + minLaunchAngleRad
        let defaultAngle = endlessIIAimDefaultAngles[ObjectIdentifier(target)] ?? fallback
        return EndlessIIPaddleEffects.aimedAngle(
            default: defaultAngle, draggedBy: endlessIIAimDrag,
            minimum: straightLaunchAngleRad - maxLaunchAngleRad,
            maximum: straightLaunchAngleRad + maxLaunchAngleRad)
    }

    // MARK: - The touches

    /// A drag while a ball is being aimed swings the aim. Returns whether it did - the
    /// caller skips moving the paddle, because while aiming, the drag *is* the aim.
    func endlessIIAimDragged(by dx: CGFloat) -> Bool {
        guard endlessIIAimTarget != nil else { return false }
        endlessIIAimDrag += dx
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
        endlessIIAimDrag = 0
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
            let length = ballSize*3
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: length, y: 0))
            path.move(to: CGPoint(x: length - ballSize*0.7, y: ballSize*0.55))
            path.addLine(to: CGPoint(x: length, y: 0))
            path.addLine(to: CGPoint(x: length - ballSize*0.7, y: -ballSize*0.55))
            node.path = path
            node.strokeColor = GameScene.endlessIIHaloColour
            node.lineWidth = 2
            node.lineCap = .round
            node.zPosition = 9
            // The Giga-Ball green the mode uses for anything of its own, over everything -
            // an aiming aid that can hide behind a brick is not aiming anything
            addChild(node)
            endlessIIAimArrow = node
            return node
        }()

        arrow.position = target.position
        arrow.zRotation = CGFloat(endlessIIAimAngle(for: target))
    }

    /// Removes the aim state entirely. For resets and the batch ending.
    func endlessIIEndAim() {
        endlessIIAimDrag = 0
        endlessIIAimDefaultAngles.removeAll()
        endlessIIAimArrow?.removeFromParent()
        endlessIIAimArrow = nil
    }
}
