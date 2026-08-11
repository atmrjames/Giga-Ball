//
//  EndlessIIPaddlePowerUps.swift
//  Megaball
//
//  Phase 8b: the power-ups that change what the paddle does.
//
//  Eight of them, good and bad together, because they want tuning against each other: a
//  paddle that curves the ball toward itself, one that teleports the ball to the top, one
//  that burns the nearest rows, one that steers the ball in flight, one whose launches are
//  aimed by hand - and three saboteurs that take the paddle's influence away, invert it, or
//  reverse the controls.
//
//  The arithmetic of each lives in `EndlessIIPaddleEffects`, pure and tested. What lives here
//  is the clocks, the drawing, and the places each effect is plugged into the scene - which
//  are deliberately few and named, because the paddle's contact handler is old code that
//  should be *asked* about power-ups rather than rewritten around them.
//
//  Everything is Endless 2.0 only. The bad ones deduct like every red power-up; the whole
//  batch runs on `EndlessIIClock`, so pausing, extending and expiring behave like the rest
//  of the game.
//

import SpriteKit

extension GameScene {

    static let endlessIIPaddlePowerUpDuration: TimeInterval = 10

    /// How many paddle hits one collection of a paddle power-up lasts.
    ///
    /// The whole batch is turn-based rather than timed - like the sticky paddle, which is
    /// the request play-testing made in as many words. A power-up you spend by using reads
    /// differently from one that evaporates while the ball is away at the top of the field.
    static let endlessIIPaddlePowerUpTurns: TimeInterval = 5

    // MARK: - Collection

    func endlessIICollectAimedSticky() {
        endlessIIAimedStickyClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectMagnetism() {
        endlessIIMagnetismClock.collect(GameScene.endlessIIPaddlePowerUpTurns,
                                        deepestLevel: EndlessIIPaddleEffects.magnetismStrength.count - 1)
    }

    func endlessIICollectPortalPaddle() {
        endlessIIPortalPaddleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectPaddleHalo() {
        endlessIIPaddleHaloClock.collect(GameScene.endlessIIPaddlePowerUpTurns,
                                         deepestLevel: EndlessIIPaddleEffects.haloReach.count - 1)
    }

    func endlessIICollectBallSteering() {
        endlessIIBallSteeringClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
        // Timed, alone in this batch (play-test round 15). Turns are the right unit for a
        // power-up that acts *on* a paddle hit; steering acts continuously between them,
        // and counting hits meant the effect ended in the middle of using it
    }

    func endlessIICollectInertPaddle() {
        endlessIIInertPaddleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectFlippedAngle() {
        endlessIIFlippedAngleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectReversedControls() {
        endlessIIReversedControlsClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectAutoAim() {
        endlessIIAutoAimClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    /// The power-ups a free shot should not be spent on - the bad ones, by the same
    /// judgement the reference page prints. Derived from the multiplier column rather than
    /// listed, so a new bad power-up is excluded the day it exists.
    static let endlessIIHarmfulPowerUps: Set<Int> = {
        var harmful = Set(LevelPackSetup().powerUpMultiplierArray.enumerated()
            .filter { $0.element == "-0.1" }
            .map { $0.offset })
        harmful.insert(1)
        // Lose A Ball's multiplier chip is blank - losing the ball speaks for itself - so
        // the derivation misses the single worst thing a free shot could set off
        return harmful
    }()

    /// The brick an Auto-Aim bounce goes for: the lowest on the field, nearest first among
    /// equals - the one that is threatening the run, which is the one worth a free shot.
    ///
    /// Only bricks worth the shot: never a Portal or an Indestructible, which the ball
    /// cannot destroy, and never a brick holding a bad power-up - a free shot that sets off
    /// a Lose A Ball is not a free shot.
    func endlessIIAutoAimTarget(from x: CGFloat) -> CGPoint? {
        var best: (position: CGPoint, distance: CGFloat)?
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            guard self.endlessIIWorthAimingAt(brick) else { return }
            let distance = abs(node.position.x - x)
            if let current = best {
                if node.position.y < current.position.y - 1
                    || (abs(node.position.y - current.position.y) <= 1
                        && distance < current.distance) {
                    best = (node.position, distance)
                }
            } else {
                best = (node.position, distance)
            }
        }
        return best?.position
    }

    /// Whether a free shot at this brick is worth taking.
    ///
    /// Auto-Aim spends a bounce. Spending it on something the shot cannot change is worse
    /// than not aiming at all, because the player gave up the bounce they would have had
    /// (play-test round 11 asked for exactly this list, and round 22 finished it):
    ///
    /// - **Portals and Indestructibles.** The ball cannot destroy either.
    /// - **A brick holding a bad power-up.** A free shot that sets off Lose A Ball is not a
    ///   free shot.
    /// - **A brick that is passable right now.** A Flashing brick in its faded phase has no
    ///   collision category at all, so the shot would go straight through it.
    /// - **A Directional brick that can only be hurt from the top.** A shot from the paddle
    ///   arrives at the underside. Left and right are left in: a brick up and to one side
    ///   can be met on its flank, so those shots are not wasted.
    func endlessIIWorthAimingAt(_ brick: SKSpriteNode) -> Bool {
        guard brick.parent != nil, brick.isHidden == false else { return false }
        guard brick.endlessIIRole != .portal else { return false }
        guard brick.texture != brickIndestructible1Texture,
              brick.texture != brickIndestructible2Texture else { return false }
        if let held = brick.endlessIIPowerUpIndex,
           GameScene.endlessIIHarmfulPowerUps.contains(held) { return false }
        if let body = brick.physicsBody, body.categoryBitMask == 0 { return false }
        if brick.endlessIIRole == .directional,
           brick.endlessIIVulnerableSide == .top { return false }
        return true
    }

    /// A ring drawn on the brick Auto-Aim would send the next bounce at.
    ///
    /// The shot itself already draws a beam, but that is after the fact - by the time it is
    /// visible the bounce has happened. This says where the free shot is *going* while there
    /// is still a decision to make about where to stand (play-test round 11's "subtle graphic
    /// showing the general direction").
    ///
    /// Driven from `update` rather than by an action on the brick, because a repeating action
    /// on a brick stops the field descending for ever (§8.6).
    func refreshEndlessIIAutoAimMarker() {
        let aiming = gameMode == .endlessII
            && (endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn)
        let target = aiming ? endlessIIAutoAimTarget(from: paddle.position.x) : nil

        guard let target else {
            childNode(withName: GameScene.autoAimMarkerName)?.removeFromParent()
            return
        }

        let marker: SKShapeNode
        if let existing = childNode(withName: GameScene.autoAimMarkerName) as? SKShapeNode {
            marker = existing
        } else {
            marker = SKShapeNode(circleOfRadius: brickHeight*0.55)
            marker.name = GameScene.autoAimMarkerName
            marker.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.55)
            marker.lineWidth = 2
            marker.fillColor = .clear
            marker.zPosition = 4
            addChild(marker)
        }
        marker.position = target
    }

    static let autoAimMarkerName = "endlessIIAutoAimMarker"

    /// Sends a ball leaving the paddle at the lowest brick instead of wherever it was going.
    /// Returns whether it did - asked at the end of the bounce, so it overrides the angle
    /// but not the catches, the swallow, or anything else the paddle decided first.
    func endlessIIApplyAutoAim(to subject: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII,
              endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn
        else { return false }
        endlessIIAutoAimOwedTurn = false
        // The last turn still aims - the turn that expired the clock is this bounce
        guard let target = endlessIIAutoAimTarget(from: subject.position.x) else { return false }
        guard let angle = EndlessIIPaddleEffects.autoAimAngle(
            from: subject.position, to: target, minimumDeg: minAngleDeg) else { return false }

        subject.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                                 dy: sin(angle)*Double(ballSpeedLimit))

        let beam = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: subject.position)
        path.addLine(to: target)
        beam.path = path
        beam.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.7)
        beam.lineWidth = 2
        beam.zPosition = 4
        addChild(beam)
        beam.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        // The shot drawn for a beat, so an aimed bounce reads as aimed rather than lucky

        return true
    }

    // MARK: - The hooks the scene asks

    /// One paddle contact happened: every running paddle power-up spends a turn.
    ///
    /// Called once per genuine landing, before the catches and the portal - the contact is
    /// the turn, whatever the paddle then does with it. With Multi-Ball every ball's landing
    /// spends one, which is the price of running four balls through a five-turn power-up.
    func endlessIISpendPaddleTurns() {
        guard gameMode == .endlessII else { return }
        endlessIIPortalPaddleOwedTurn = endlessIIPortalPaddleClock.isRunning
        endlessIIAimedStickyOwedTurn = endlessIIAimedStickyClock.isRunning
        endlessIIAutoAimOwedTurn = endlessIIAutoAimClock.isRunning
        // Snapshotted before the spend: the effects these buy land later in the same
        // contact, and a clock expired by its own last turn must still deliver it

        endlessIIAimedStickyClock.spendTurn()
        endlessIIMagnetismClock.spendTurn()
        endlessIIPortalPaddleClock.spendTurn()
        endlessIIPaddleHaloClock.spendTurn()
        endlessIIInertPaddleClock.spendTurn()
        // Ball Steering is not here: it runs on time now, and spending it a turn as well
        // would end it twice as fast as its ring says
        endlessIIFlippedAngleClock.spendTurn()
        endlessIIReversedControlsClock.spendTurn()
        endlessIIAutoAimClock.spendTurn()
        endlessIISpendLandingTurn()
    }

    /// What multiplies the paddle's angular influence on a bounce - see `paddleHit`.
    var endlessIIPaddleAngleInfluence: Double {
        EndlessIIPaddleEffects.angleInfluence(inert: endlessIIInertPaddleClock.isRunning,
                                              flipped: endlessIIFlippedAngleClock.isRunning)
    }

    /// What multiplies the finger's movement before it reaches the paddle - see `touchesMoved`.
    var endlessIIControlDirection: CGFloat {
        EndlessIIPaddleEffects.controlDirection(reversed: endlessIIReversedControlsClock.isRunning)
    }

    /// Notes that a ball has entered a Portal Paddle, to re-enter at the top.
    ///
    /// Deferred rather than done: this is called from inside a contact, and a position
    /// written there is undone by the rest of the step (§8.6). Returns whether the paddle
    /// took the ball, so the caller skips the bounce it would otherwise be correcting.
    func endlessIIPaddlePortalTook(_ subject: SKSpriteNode, collision: Double) -> Bool {
        guard gameMode == .endlessII,
              endlessIIPortalPaddleClock.isRunning || endlessIIPortalPaddleOwedTurn
        else { return false }
        endlessIIPortalPaddleOwedTurn = false
        endlessIIPendingPaddlePortals.append(subject)
        endlessIIPendingPortalCollisions[ObjectIdentifier(subject)] = collision
        // Where on the paddle the ball went through, kept for the exit: the re-entry
        // angle is the bounce this spot would have given (play test: the ball just
        // carried on, and the portal gave no control)
        if hapticsSetting { mediumHaptic.impactOccurred() }
        return true
    }

    /// Puts every ball the paddle swallowed this step back in at the top.
    ///
    /// Runs from `didSimulatePhysics`. The horizontal velocity is kept and the vertical one
    /// points down (§5.4) - the ball falls back into the field from above, which is the whole
    /// gift: everything between the paddle and the top is skipped.
    func applyEndlessIIPaddlePortals() {
        guard endlessIIPendingPaddlePortals.isEmpty == false else { return }
        let exits = endlessIIPendingPaddlePortals
        endlessIIPendingPaddlePortals.removeAll()

        for subject in exits {
            guard subject.parent != nil, let body = subject.physicsBody else { continue }
            let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
                ?? body.velocity
            // The velocity it entered with, sampled before the engine's own bounce - the
            // reported one has already been turned round (§8.6)

            let collision = endlessIIPendingPortalCollisions
                .removeValue(forKey: ObjectIdentifier(subject)) ?? 0
            let speed = Double(max(hypot(arriving.dx, arriving.dy), ballSpeedLimit))
            var angleDeg = atan2(Double(abs(arriving.dy)), Double(arriving.dx))*180/Double.pi
            angleDeg -= angleAdjustmentK*collision*endlessIIPaddleAngleInfluence
            angleDeg = min(max(angleDeg, minAngleDeg), 180 - minAngleDeg)
            let angleRad = angleDeg*Double.pi/180
            // The bounce this spot on the paddle would have given (the same formula
            // paddleHit uses), so where the ball goes through decides where it comes
            // out - the play test found the pass-through gave no control at all

            if let portal = endlessIIPortals().randomElement() {
                let from = subject.position
                subject.position = CGPoint(x: portal.position.x,
                                           y: portal.frame.maxY + subject.size.height)
                body.velocity = CGVector(dx: cos(angleRad)*speed, dy: sin(angleRad)*speed)
                endlessIIShowPortalJump(from: from, to: subject.position)
                portal.run(.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                                      .fadeAlpha(to: 1, duration: 0.12)]))
                // The network: with Portal bricks in play the paddle connects to them, one
                // chosen at random, and the ball climbs out of the brick into the field
            } else {
                subject.position = CGPoint(x: subject.position.x,
                                           y: frame.height/2 - topScreenBlock.size.height
                                              - subject.size.height)
                body.velocity = CGVector(dx: cos(angleRad)*speed, dy: -sin(angleRad)*speed)
                // On its own the paddle's portal exits at the top, falling back in - the
                // bounce angle mirrored downward
            }

            if endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn,
               let target = endlessIIAutoAimTarget(from: subject.position.x) {
                endlessIIAutoAimOwedTurn = false
                let dx = Double(target.x - subject.position.x)
                let dy = Double(target.y - subject.position.y)
                let length = max(hypot(dx, dy), 1)
                body.velocity = CGVector(dx: dx/length*speed, dy: dy/length*speed)
                // Portal Paddle × Auto-Aim (§12.0): both speak in sequence - the hit
                // still portals, and the aim owns the *re-entry*, pointed at the lowest
                // brick worth hitting. Together they were cancelling out: the aim set
                // the launch and the portal threw it away
            }
        }
    }

    // MARK: - Each frame

    /// Runs the batch's clocks down and drives the halo. Called from `update`.
    ///
    /// The clocks and the halo live here; magnetism, steering and the paddle portals write
    /// to physics bodies, so they run from `didSimulatePhysics` instead - the one place such
    /// writes stick (§8.6). The frame's delta is kept for them.
    func tickEndlessIIPaddlePowerUps(_ currentTime: TimeInterval) {
        guard gameMode == .endlessII else { return }

        let delta = endlessIIPaddleLastTick == 0 ? 0
            : min(currentTime - endlessIIPaddleLastTick, 0.5)
        endlessIIPaddleLastTick = currentTime
        endlessIIPaddleFrameDelta = delta

        if gameState.currentState is Playing && isPaused == false {
            tickEndlessIIPaddleHalo()
        }
        tickEndlessIIPaddleDressing()
        if gameState.currentState is Playing && isPaused == false {
            endlessIIBallSteeringClock.run(down: delta)
        }
        // The rest of the batch counts paddle hits, spent in `endlessIISpendPaddleTurns`.
        // Ball Steering is the exception: it acts continuously rather than on contact, so
        // it runs on the clock (play-test round 15)

        if endlessIIPaddleHaloClock.isRunning == false {
            endlessIIPaddleHaloNode?.removeFromParent()
            endlessIIPaddleHaloNode = nil
        }
    }

    /// The body-writing effects, from `didSimulatePhysics`.
    func applyEndlessIIPaddlePhysics() {
        guard gameMode == .endlessII else { return }
        applyEndlessIIPaddlePortals()
        guard gameState.currentState is Playing, isPaused == false else { return }
        applyEndlessIIMagnetism(endlessIIPaddleFrameDelta)
        applyEndlessIIBallSteering()
    }

    private func applyEndlessIIMagnetism(_ delta: TimeInterval) {
        guard endlessIIMagnetismClock.isRunning else { return }
        let strength = EndlessIIPaddleEffects.magnetismStrength[
            min(endlessIIMagnetismClock.level, EndlessIIPaddleEffects.magnetismStrength.count - 1)]

        let pullCeiling = finalBrickRowHeight + brickHeight*2
        // The pull only wakes once the ball is below the field's bottom couple of rows
        // (play test: it started drawing the ball in far too early) - the magnet is a
        // landing aid, not a tractor beam through the field

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil, let body = subject.physicsBody else { continue }
            guard subject !== ball || ballIsOnPaddle == false else { continue }
            guard subject.position.y < pullCeiling else { continue }
            let side: CGFloat = subject.position.x >= paddle.position.x ? 1 : -1
            let target = CGPoint(x: paddle.position.x + side*paddle.size.width*0.3,
                                 y: paddle.position.y)
            // Pulled toward a spot a third out from the centre, on the ball's own side - a
            // magnet aimed dead centre landed every ball vertically, and a vertical bounce
            // is the least useful one the paddle can give
            body.velocity = EndlessIIPaddleEffects.magnetised(
                velocity: body.velocity, ballAt: subject.position,
                paddleAt: target, strength: strength, delta: delta)
        }
    }

    private func applyEndlessIIBallSteering() {
        guard endlessIIBallSteeringClock.isRunning else { return }

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil else { continue }
            guard subject !== ball || ballIsOnPaddle == false else { continue }
            guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { continue }
            // A held ball already rides the paddle; steering it twice doubles the ride

            subject.position.x = EndlessIIPaddleEffects.steeredTowards(
                paddleX: paddle.position.x, from: subject.position.x,
                leftWall: -gameWidth/2, rightWall: gameWidth/2,
                radius: subject.size.width/2)

            if let body = subject.physicsBody {
                body.velocity = EndlessIIPaddleEffects.steeredVelocity(body.velocity)
            }
            // The ball is drawn to the paddle's column and its sideways momentum bleeds
            // away into vertical, so it forgets the trajectory it arrived on. Bricks and
            // walls still bounce it - the bounce simply does not last, because the pull
            // gathers it back in over the next few frames (play-test round 15)
        }
    }

    private func tickEndlessIIPaddleHalo() {
        guard endlessIIPaddleHaloClock.isRunning else { return }
        let reach = paddle.size.width*EndlessIIPaddleEffects.haloReach[
            min(endlessIIPaddleHaloClock.level, EndlessIIPaddleEffects.haloReach.count - 1)]

        let halo = endlessIIPaddleHaloNode ?? {
            let node = SKShapeNode()
            node.fillColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.14)
            node.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.45)
            node.lineWidth = 1.5
            node.zPosition = 2
            addChild(node)
            endlessIIPaddleHaloNode = node
            return node
        }()

        if abs(endlessIIPaddleHaloDrawnReach - reach) > 0.5 {
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: reach, startAngle: 0, endAngle: .pi,
                        clockwise: false)
            path.closeSubpath()
            halo.path = path
            endlessIIPaddleHaloDrawnReach = reach
            // Rebuilt only when the reach changes - a fresh CGPath per frame for a shape
            // that is almost always the same size is the kind of habit update loops die of
        }
        halo.position = paddle.position

        var destroyed = false
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
            guard brick.endlessIIRole != .portal else { return }
            guard brick.endlessIIPowerUpIndex == nil else { return }
            // A Portal is not destructible by anything, and a power-up brick is spent by
            // being *hit* - a halo that silently ate one would eat the power-up with it
            guard EndlessIIPaddleEffects.haloTouches(brick: brick.frame,
                                                     paddleAt: self.paddle.position,
                                                     reach: reach) else { return }
            self.endlessIIBrickDestroyed(brick)
            self.endlessIIDestroy(brick)
            destroyed = true
            // The same pair a crushed brick goes through: the roles react - an Exploding
            // brick caught by the glow still explodes - and then it is gone, scored, with
            // no power-up roll. A glow that showered power-ups would be a farm
        }
        if destroyed {
            countBricks()
            if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.5) }
        }
    }

    static let endlessIIHaloColour = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)

    // MARK: - The ring HUD

    func endlessIIPaddleRingEntries() -> [PowerUpRingHUD.Entry] {
        let clocks: [(String, EndlessIIClock, UIImage)] = [
            ("endlessIIAimedSticky", endlessIIAimedStickyClock, PowerUpIcon.aimedSticky),
            ("endlessIIMagnetism", endlessIIMagnetismClock, PowerUpIcon.magnetism),
            ("endlessIIPortalPaddle", endlessIIPortalPaddleClock, PowerUpIcon.portalPaddle),
            ("endlessIIPaddleHalo", endlessIIPaddleHaloClock, PowerUpIcon.paddleHalo),
            ("endlessIIBallSteering", endlessIIBallSteeringClock, PowerUpIcon.ballSteering),
            ("endlessIIInertPaddle", endlessIIInertPaddleClock, PowerUpIcon.inertPaddle),
            ("endlessIIFlippedAngle", endlessIIFlippedAngleClock, PowerUpIcon.flippedAngle),
            ("endlessIIReversedControls", endlessIIReversedControlsClock, PowerUpIcon.reversedControls),
            ("endlessIIAutoAim", endlessIIAutoAimClock, PowerUpIcon.autoAim),
        ]
        return clocks.compactMap { id, clock, icon in
            guard clock.isRunning else { return nil }
            return PowerUpRingHUD.Entry(id: id, texture: SKTexture(image: icon),
                                        remaining: clock.fraction,
                                        segments: Int(clock.total))
            // Segmented like the sticky paddle's ring: five marks say "five turns" where a
            // smooth arc only says "most of it"
        }
    }

    // MARK: - Saving

    /// Every running clock, in the form the save's active-power-up arrays hold.
    ///
    /// The id doubles as the save key, so a clock that is added to the ring is saved and
    /// restored with no third list to keep in step.
    func endlessIIPaddleClockSaveEntries() -> [(key: String, remaining: Double, total: Double,
                                                magnitude: Int)] {
        [("endlessIIAimedSticky", endlessIIAimedStickyClock),
         ("endlessIIMagnetism", endlessIIMagnetismClock),
         ("endlessIIPortalPaddle", endlessIIPortalPaddleClock),
         ("endlessIIPaddleHalo", endlessIIPaddleHaloClock),
         ("endlessIIBallSteering", endlessIIBallSteeringClock),
         ("endlessIIInertPaddle", endlessIIInertPaddleClock),
         ("endlessIIFlippedAngle", endlessIIFlippedAngleClock),
         ("endlessIIReversedControls", endlessIIReversedControlsClock),
         ("endlessIIAutoAim", endlessIIAutoAimClock)]
            .filter { $0.1.isRunning }
            .map { ($0.0, $0.1.remaining, $0.1.total, $0.1.level) }
    }

    /// Puts one saved clock back, if the key is one of this batch's. Returns whether it was.
    @discardableResult
    func endlessIIRestorePaddleClock(key: String, remaining: Double, total: Double,
                                     magnitude: Int) -> Bool {
        switch key {
        case "endlessIIAimedSticky":
            endlessIIAimedStickyClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIMagnetism":
            endlessIIMagnetismClock.restore(remaining: remaining, total: total,
                                            level: magnitude,
                                            deepestLevel: EndlessIIPaddleEffects.magnetismStrength.count - 1)
        case "endlessIIPortalPaddle":
            endlessIIPortalPaddleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIPaddleHalo":
            endlessIIPaddleHaloClock.restore(remaining: remaining, total: total,
                                             level: magnitude,
                                             deepestLevel: EndlessIIPaddleEffects.haloReach.count - 1)
        case "endlessIIBallSteering":
            endlessIIBallSteeringClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIInertPaddle":
            endlessIIInertPaddleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIFlippedAngle":
            endlessIIFlippedAngleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIReversedControls":
            endlessIIReversedControlsClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIAutoAim":
            endlessIIAutoAimClock.restore(remaining: remaining, total: total, level: 0)
        default:
            return false
        }
        return true
    }

    /// Ends the whole batch. For the life ending and the field resetting.
    func endlessIIResetPaddlePowerUps() {
        endlessIIAimedStickyClock.reset()
        endlessIIMagnetismClock.reset()
        endlessIIPortalPaddleClock.reset()
        endlessIIPaddleHaloClock.reset()
        endlessIIBallSteeringClock.reset()
        endlessIIInertPaddleClock.reset()
        endlessIIFlippedAngleClock.reset()
        endlessIIReversedControlsClock.reset()
        endlessIIAutoAimClock.reset()
        endlessIIPendingPaddlePortals.removeAll()
        endlessIIPaddleHaloNode?.removeFromParent()
        endlessIIPaddleHaloNode = nil
        endlessIIPaddleHaloDrawnReach = 0
        endlessIISteeringPending = 0
        endlessIITopExitStrip?.removeFromParent()
        endlessIITopExitStrip = nil
        endlessIIPullLines.forEach { $0.removeFromParent() }
        endlessIIPullLines.removeAll()
        if paddle.colorBlendFactor != 0 { paddle.colorBlendFactor = 0 }
        endlessIIAimHold = false
        endlessIIEndAim()
        endlessIIResetBackdrop()
    }
}
