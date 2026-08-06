//
//  EndlessIIFieldPowerUps.swift
//  Megaball
//
//  Phase 8c: the power-ups that act on the field rather than on the ball.
//
//  Six of the batch's eight. Four are instants - Cull takes half the field at random, Clear
//  And Retreat takes the lowest row and pushes everything back up, Laser Beam burns one
//  column per ball, and Infill (the bad one) fills empty cells with new bricks. Two run on
//  clocks: Wrecking Ball makes every hit lethal while still bouncing, and Aura destroys what
//  the glow around each ball touches.
//
//  Descent and Wrap-Around are the other two, and they are deliberately not here yet: one
//  drives the field's own descent machinery and the other asks the side walls to stop being
//  walls, and each wants its own careful visit rather than a corner of this file.
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

    /// Destroys the lowest occupied row and pushes the whole field up one row (§5.4).
    func endlessIIClearAndRetreat() {
        guard gameMode == .endlessII else { return }

        var lowestY: CGFloat = .greatestFiniteMagnitude
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard node.parent != nil else { return }
            lowestY = min(lowestY, node.position.y)
        }
        guard lowestY < .greatestFiniteMagnitude else { return }

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
            if abs(brick.position.y - lowestY) < self.brickHeight/2 {
                guard brick.endlessIIRole != .portal,
                      brick.endlessIIPowerUpIndex == nil else { return }
                self.endlessIIBrickDestroyed(brick)
                self.endlessIIDestroy(brick)
            }
        }
        // The lowest row is anything on that row's centre - a brick's position.y is its row,
        // which is the one fact all of Endless 2.0 bends around

        let retreat = SKAction.moveBy(x: 0, y: brickHeight, duration: 0.1)
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard self.endlessIIStaysPut(node) == false else { return }
            node.run(retreat)
        }
        // Up by exactly a row, so every brick lands on a row centre again. Anchored bricks
        // hold their ground the same way they do against the descent

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(endlessRowDownSound) }
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

            let beam = SKSpriteNode(color: GameScene.endlessIIHaloColour,
                                    size: CGSize(width: subject.size.width,
                                                 height: frame.height))
            beam.position = CGPoint(x: beamX, y: 0)
            beam.zPosition = 4
            beam.alpha = 0.7
            addChild(beam)
            beam.run(.sequence([.fadeOut(withDuration: 0.35), .removeFromParent()]))
            // The beam itself, gone in a third of a second - the destruction is the instant,
            // the light is just how the player reads which columns it was
        }

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    // MARK: - Wrecking Ball

    func endlessIICollectWreckingBall() {
        endlessIIWreckingBallClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
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
        endlessIIAuraClock.collect(GameScene.endlessIIPaddlePowerUpDuration,
                                   deepestLevel: GameScene.endlessIIAuraReach.count - 1)
    }

    /// The aura's reach as a multiple of the ball's radius, by stacking level. Twice the
    /// ball's radius to start (§5.4); a deepening collection grows it.
    static let endlessIIAuraReach: [CGFloat] = [2.0, 2.8]

    /// Destroys what each ball's glow touches, and keeps the glow on the balls.
    ///
    /// The ball bounces only off bricks it touches itself (§5.4) - which needs no code,
    /// because a brick the aura reaches is destroyed before the ball arrives at it.
    func tickEndlessIIAura() {
        guard endlessIIAuraClock.isRunning else {
            if endlessIIAuraNodes.isEmpty == false {
                endlessIIAuraNodes.forEach { $0.removeFromParent() }
                endlessIIAuraNodes.removeAll()
            }
            return
        }

        let reach = ballSize/2*GameScene.endlessIIAuraReach[
            min(endlessIIAuraClock.level, GameScene.endlessIIAuraReach.count - 1)]
        let balls = endlessIIBallsInPlay.filter { $0.parent != nil }

        while endlessIIAuraNodes.count < balls.count {
            let glow = SKShapeNode(circleOfRadius: 1)
            glow.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.5)
            glow.fillColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.12)
            glow.lineWidth = 1.5
            glow.zPosition = 3
            addChild(glow)
            endlessIIAuraNodes.append(glow)
        }
        while endlessIIAuraNodes.count > balls.count {
            endlessIIAuraNodes.removeLast().removeFromParent()
        }

        var destroyed = false
        for (index, subject) in balls.enumerated() {
            let glow = endlessIIAuraNodes[index]
            glow.position = subject.position
            glow.setScale(reach)

            enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
                guard brick.endlessIIRole != .portal else { return }
                guard brick.endlessIIPowerUpIndex == nil else { return }
                guard brick.isHidden == false else { return }
                let nearestX = max(brick.frame.minX, min(subject.position.x, brick.frame.maxX))
                let nearestY = max(brick.frame.minY, min(subject.position.y, brick.frame.maxY))
                let dx = nearestX - subject.position.x
                let dy = nearestY - subject.position.y
                guard dx*dx + dy*dy <= reach*reach else { return }
                self.endlessIIBrickDestroyed(brick)
                self.endlessIIDestroy(brick)
                destroyed = true
            }
        }
        if destroyed {
            countBricks()
            if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.5) }
        }
    }

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

    // MARK: - The ring and the save

    func endlessIIFieldRingEntries() -> [PowerUpRingHUD.Entry] {
        var entries: [PowerUpRingHUD.Entry] = []
        if endlessIIWreckingBallClock.isRunning {
            entries.append(PowerUpRingHUD.Entry(
                id: "endlessIIWreckingBall", texture: SKTexture(image: PowerUpIcon.wreckingBall),
                remaining: endlessIIWreckingBallClock.fraction, segments: nil))
        }
        if endlessIIAuraClock.isRunning {
            entries.append(PowerUpRingHUD.Entry(
                id: "endlessIIAura", texture: SKTexture(image: PowerUpIcon.aura),
                remaining: endlessIIAuraClock.fraction, segments: nil))
        }
        return entries
    }

    func endlessIIFieldClockSaveEntries() -> [(key: String, remaining: Double, total: Double,
                                               magnitude: Int)] {
        [("endlessIIWreckingBall", endlessIIWreckingBallClock),
         ("endlessIIAura", endlessIIAuraClock)]
            .filter { $0.1.isRunning }
            .map { ($0.0, $0.1.remaining, $0.1.total, $0.1.level) }
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
        default:
            return false
        }
        return true
    }

    /// Runs the batch's clocks. From `update`, beside the paddle batch's tick.
    func tickEndlessIIFieldPowerUps() {
        guard gameMode == .endlessII else { return }
        if gameState.currentState is Playing && isPaused == false {
            endlessIIWreckingBallClock.run(down: endlessIIPaddleFrameDelta)
            endlessIIAuraClock.run(down: endlessIIPaddleFrameDelta)
        }
        tickEndlessIIAura()
    }

    func endlessIIResetFieldPowerUps() {
        endlessIIWreckingBallClock.reset()
        endlessIIAuraClock.reset()
        endlessIIAuraNodes.forEach { $0.removeFromParent() }
        endlessIIAuraNodes.removeAll()
    }
}
