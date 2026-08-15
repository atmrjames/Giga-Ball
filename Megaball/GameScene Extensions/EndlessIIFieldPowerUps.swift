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
//  one-row step on a timer, and Clear And Retreat takes the lowest two rows and then holds
//  the field where it left it - which is the half of it that used to be missing.
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

    /// How long the field is held where the clear left it.
    ///
    /// Longer than Descent's six, because this is the answer to that; shorter than the
    /// paddle batch's ten, because a held field is a field that is not descending, and in
    /// this mode the descent is where height - the score - comes from. The player is
    /// trading tempo for room, and eight seconds is enough room to be worth the trade
    /// without the run standing still long enough to notice.
    static let endlessIIClearAndRetreatDuration: TimeInterval = 8

    /// Raises the lowest brick level by two rows and holds the field there (§5.4).
    ///
    /// **It used to be instant, and instant was the bug** (play-test round 126: "should be
    /// timed"). It cleared the lowest row, lifted everything a row, and then the cadence -
    /// which exists to close exactly the gap it had just made - took both back inside a
    /// second. The retreat the name promises never lasted long enough to be seen, let alone
    /// played around.
    ///
    /// So the clear is now two rows deep rather than one, and it comes with a clock. While
    /// that clock runs the field is held: no cadence, no Descent, no new rows. When it ends
    /// the field comes back down into the room that was made, so the height those two rows
    /// are worth is deferred rather than lost.
    ///
    /// Nothing is lifted any more. The old version pushed every brick up a row to make the
    /// retreat visible, which meant deciding what happens to a brick pushed off the top; the
    /// lowest level rises here by the two lowest rows being destroyed, which is what the
    /// power-up says it does and needs no such rule.
    func endlessIICollectClearAndRetreat() {
        guard gameMode == .endlessII else { return }

        endlessIIClearAndRetreatClock.collect(GameScene.endlessIIClearAndRetreatDuration)
        endlessIIRaiseTheLowestBrickLevel(by: GameScene.endlessIIRetreatRows)

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(endlessRowDownSound) }
    }

    /// Destroys the lowest occupied rows, one row at a time from the bottom.
    ///
    /// A row at a time rather than "everything within two row heights of the lowest brick",
    /// because the two are not the same field: the lowest bricks can be a single brick with
    /// a gap above them, and the player asked for the lowest *level* to rise by two, not for
    /// two row heights of whatever happens to be down there. So the lowest occupied row goes,
    /// then whatever the lowest occupied row is after that.
    ///
    /// Portals and power-up bricks are spared, as they are by a Cull: one is indestructible
    /// to everything and the other is spent by being hit rather than eaten silently. A row
    /// holding nothing else is still counted as cleared - it has had everything taken from it
    /// that this may take.
    func endlessIIRaiseTheLowestBrickLevel(by rows: Int) {
        for _ in 0..<rows {
            var lowestY: CGFloat = .greatestFiniteMagnitude
            enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                guard node.parent != nil else { return }
                lowestY = min(lowestY, node.position.y)
            }
            guard lowestY < .greatestFiniteMagnitude else { return }
            // The lowest row is anything on that row's centre - a brick's position.y is its
            // row, which is the one fact all of Endless 2.0 bends around

            var cleared = false
            enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
                guard abs(brick.position.y - lowestY) < self.brickHeight/2 else { return }
                guard brick.endlessIIRole != .portal,
                      brick.endlessIIPowerUpIndex == nil else { return }
                self.endlessIIBrickDestroyed(brick)
                self.endlessIIDestroy(brick)
                cleared = true
            }
            guard cleared else { return }
            // A row of nothing but portals cannot be taken, and going round again would
            // find the same row and take nothing again
        }
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

            let bloom = SKSpriteNode(color: GameScene.endlessIIHaloColour,
                                     size: CGSize(width: subject.size.width*3,
                                                  height: frame.height))
            bloom.position = CGPoint(x: beamX, y: 0)
            bloom.zPosition = 4
            bloom.alpha = 0.35
            bloom.blendMode = .add
            addChild(bloom)
            bloom.run(.sequence([.fadeOut(withDuration: 1.2), .removeFromParent()]))

            let beam = SKSpriteNode(color: .white,
                                    size: CGSize(width: subject.size.width,
                                                 height: frame.height))
            beam.position = CGPoint(x: beamX, y: 0)
            beam.zPosition = 4.1
            beam.alpha = 0.9
            addChild(beam)
            beam.run(.sequence([.fadeOut(withDuration: 1.2), .removeFromParent()]))
            // **Made unmissable** (play-test round 102: "doesn't appear to do anything").
            // The mechanics were right all along - a beam through each ball's column, as
            // the description says - but it fired the instant the paddle caught the icon,
            // at the ball's column where the player's eyes are not, silently, for a third
            // of a second. Now it is the ring HUD's two-pass construction at field size: a
            // wide additive bloom underneath, a bright core on top, twice the linger, and
            // the laser's own sound below - the destruction is still the instant, and the
            // light finally insists on being seen
        }

        countBricks()
        if hapticsSetting { heavyHaptic.impactOccurred() }
        if soundsSetting { run(laserFiredSound) }
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

        var touchedNow: Set<ObjectIdentifier> = []
        var struck: [SKSpriteNode] = []

        for (index, subject) in balls.enumerated() {
            let glow = endlessIIAuraNodes[index]
            glow.position = subject.position
            glow.setScale(reach)

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
        endlessIILockClock.collect(GameScene.endlessIILockDuration)
    }

    /// A Key lands, and the Lock ends.
    ///
    /// The clock is cleared outright rather than run down: a Key is the answer to a Lock,
    /// and an answer that only shortened it would leave the player still locked.
    func endlessIITurnKey() {
        endlessIILockClock = EndlessIIClock()
    }

    static let endlessIILockDuration: TimeInterval = 15

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
        return endlessIITimedClocks.contains { $0.remaining > GameScene.endlessIILockLead }
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
    ]

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
        ]

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

        wipeGravity()
        wipeInertBall()
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
        return gravityActivated || inertBallRunning
    }

    /// Gravity, ended early.
    ///
    /// Its timer is an `SKAction` on the scene, so the action has to go as well as the effect -
    /// left running it would fire its own ending later and hide an icon bar that a power-up
    /// collected since might be using.
    private func wipeGravity() {
        guard gravityActivated || action(forKey: "powerUpGravityBall") != nil else { return }
        removeAction(forKey: "powerUpGravityBall")
        gravityIcon.removeAction(forKey: "powerUpGravityTimer")
        gravityIconBar.removeAction(forKey: "gravityTimer")
        deactivateGravity()
        gravityIconBar.isHidden = true
    }

    /// Whether Undestructi-Ball is running. It has no flag of its own - its expiry is an
    /// action on the scene, so the action's presence is the flag.
    var inertBallRunning: Bool { action(forKey: "powerUpUndestructiBall") != nil }

    /// Undestructi-Ball, ended early. Everything its own expiry block does, done now.
    private func wipeInertBall() {
        guard inertBallRunning else { return }
        removeAction(forKey: "powerUpUndestructiBall")
        gigaBallIcon.removeAction(forKey: "powerUpGigaBallTimer")
        gigaBallIconBar.removeAction(forKey: "gigaBallTimer")
        ball.texture = ballTexture
        ballPhysicsBodySet()
        gigaBallIcon.texture = iconGigaBallDisabledTexture
        gigaBallIconBar.isHidden = true
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

    // MARK: - Descent

    /// How long a Descent runs.
    ///
    /// Its own, rather than the ten seconds every other timed power-up gets. At a row every
    /// `endlessIIDescentStep` that shared duration was around eighteen rows a collection,
    /// which is a great deal of height from one pick-up - enough that it would dominate any
    /// accounting of which power-up gains the most, and enough to feel like the run being
    /// handed to you (play-test round 51). Six seconds is nearer eleven rows: still clearly
    /// the biggest single source of height in the mode, which is the point of it, without
    /// being the only one that matters.
    static let endlessIIDescentDuration: TimeInterval = 6

    func endlessIICollectDescent() {
        endlessIIDescentClock.collect(GameScene.endlessIIDescentDuration)
    }

    /// How often the field steps down while Descent runs.
    ///
    /// The spec says "continuously"; this is the grid-preserving reading of it - a fast,
    /// steady cadence of the same one-row step the field has always made, because a brick's
    /// position.y is its row and a field that drifted off its row centres would break
    /// everything that reads them (§8.6). Just under two rows a second reads as continuous
    /// motion and keeps every landing on a centre.
    static let endlessIIDescentStep: TimeInterval = 0.55

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

        endlessIIDescentAccumulated += endlessIIPaddleFrameDelta
        guard endlessIIDescentAccumulated >= GameScene.endlessIIDescentStep else { return }
        endlessIIDescentAccumulated = 0

        guard endlessMoveInProgress == false else { return }
        // A step already animating finishes first - two moves at once would stack their
        // distances and carry bricks off their row centres

        guard endlessIIFieldIsHeld == false else { return }
        // Descent is the field's other way down, and it must stop for an aim like the
        // cadence does - otherwise the one power-up that exists to drop the field does it
        // while the player is holding the ball still and cannot answer (round 87)

        moveEndlessModeRowDown()
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
    var endlessIIFieldClocks: [(id: String, clock: EndlessIIClock, icon: UIImage)] {
        [("endlessIIWreckingBall", endlessIIWreckingBallClock, PowerUpIcon.wreckingBall),
         ("endlessIIAura", endlessIIAuraClock, PowerUpIcon.aura),
         ("endlessIIDescent", endlessIIDescentClock, PowerUpIcon.descent),
         ("endlessIIWrapAround", endlessIIWrapAroundClock, PowerUpIcon.wrapAround),
         ("endlessIIRandomisedBounce", endlessIIRandomisedBounceClock,
          PowerUpIcon.randomisedBounce),
         ("endlessIIGhostBall", endlessIIGhostBallClock, PowerUpIcon.ghostBall),
         ("endlessIIClearAndRetreat", endlessIIClearAndRetreatClock,
          PowerUpIcon.clearAndRetreat),
         ("endlessIISafetyPaddle", endlessIISafetyPaddleClock,
          PowerUpIcon.safetyPaddle)]
    }

    func endlessIIFieldRingEntries() -> [PowerUpRingHUD.Entry] {
        endlessIIFieldClocks.compactMap { id, clock, icon in
            guard clock.isRunning else { return nil }
            return PowerUpRingHUD.Entry(id: id, texture: SKTexture(image: icon),
                                        remaining: clock.fraction, segments: nil)
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
        case "endlessIIWrapAround":
            endlessIIWrapAroundClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIRandomisedBounce":
            endlessIIRandomisedBounceClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIGhostBall":
            endlessIIGhostBallClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIClearAndRetreat":
            endlessIIClearAndRetreatClock.restore(remaining: remaining, total: total, level: 0)
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
        if gameState.currentState is Playing && isPaused == false {
            endlessIILockClock.run(down: endlessIIPaddleFrameDelta)
            // The Lock's own clock is the one thing a Lock does not freeze - it has to be
            // able to end by itself, or a run without a Key never gets its timers back

            endlessIIWreckingBallClock.run(down: endlessIIClockDelta)
            endlessIIAuraClock.run(down: endlessIIClockDelta)
            endlessIIDescentClock.run(down: endlessIIClockDelta)
            endlessIIRandomisedBounceClock.run(down: endlessIIClockDelta)
            endlessIIGhostBallClock.run(down: endlessIIClockDelta)
            endlessIIClearAndRetreatClock.run(down: endlessIIClockDelta)
            endlessIISafetyPaddleClock.run(down: endlessIIClockDelta)
            tickEndlessIIGhostBall()
            tickEndlessIISafetyPaddle()
            tickEndlessIIDescent()
        }
        tickEndlessIIAura()
    }

    // MARK: - Randomised Bounce

    /// How long one collection lasts, and how much of the angle it throws away.
    static let endlessIIRandomisedBounceDuration: TimeInterval = 15
    static let endlessIIRandomisedBounceSpread: Double = 35

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
    static func randomisedBounceAngle(from angleDeg: Double, minimumDeg: Double,
                                      spread: Double = endlessIIRandomisedBounceSpread,
                                      offset: Double? = nil) -> Double {
        let thrown = offset ?? Double.random(in: -spread...spread)
        return min(max(angleDeg + thrown, minimumDeg), 180 - minimumDeg)
    }

    /// Whether this bounce should be randomised at all.
    ///
    /// Only the main ball and only while the clock runs. An extra ball keeping its honest
    /// bounce while the first one lies would be stranger than either.
    func endlessIIRandomisesBounces(for subject: SKSpriteNode) -> Bool {
        gameMode == .endlessII && endlessIIRandomisedBounceClock.isRunning
    }

    // MARK: - Ghost Ball

    static let endlessIIGhostBallDuration: TimeInterval = 12

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
        childNode(withName: GameScene.endlessIISafetyPaddleName)?.removeFromParent()
        endlessIIAuraNodes.forEach { $0.removeFromParent() }
        endlessIIAuraNodes.removeAll()
    }
}
