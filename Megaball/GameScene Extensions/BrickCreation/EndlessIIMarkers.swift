//
//  EndlessIIMarkers.swift
//  Megaball
//
//  The hundred-metre lines that drift down behind the field.
//
//  Height in Endless is a number in a corner, and a number in a corner is hard to feel. The
//  field descending is the thing the player actually watches, so putting the milestones into
//  that motion is what turns a score into a sense of distance travelled - you see 300m coming
//  before you reach it, and you see it go past.
//
//  Behind everything, dim, and never in the way. A marker competing with the bricks for
//  attention would be worse than no marker at all.
//

import SpriteKit

extension GameScene {

    static let endlessIIMarkerName = "endlessIIMarker"
    /// How often a line appears.
    static let endlessIIMarkerSpacing = 100

    /// How far ahead of itself a marker is created, in rows.
    ///
    /// A marker means "this is where 300m was", and where 300m *is* is the bottom of the
    /// field - the row the player is clearing when the counter reads 300. So the line has to
    /// enter at the top a whole field earlier and descend with everything else, arriving at
    /// the bottom row exactly as the height is reached.
    ///
    /// It used to be created at the height it named, which put it at the top of the screen at
    /// the moment the player was told they had got there - the line then spent the next
    /// twenty-two rows travelling down to where it should have been when it appeared.
    /// The field's depth. A line entering at the top has this many descents to make before it
    /// is level with the lowest row - counted from the height *after* the row that carried it
    /// was generated, which is the one row this was short by: the 100m line was still on screen
    /// at 101m because it reached the bottom a row late.
    static var endlessIIMarkerLead: Int { GameSceneLayout.brickRows }

    /// Adds a line for the height this row will represent by the time it reaches the bottom.
    ///
    /// Created in that row and then carried down with it, so it stays attached to the field
    /// rather than being a line at roughly the right place.
    func addEndlessIIMarkerIfDue() {
        guard gameMode == .endlessII else { return }

        let arriving = endlessHeight + GameScene.endlessIIMarkerLead
        guard arriving > 0 else { return }

        let best = totalStatsArray.first?.endlessIIHeights.max() ?? 0
        let isBest = best > 0 && arriving == best
        let isHundred = arriving % GameScene.endlessIIMarkerSpacing == 0
        guard isBest || isHundred else { return }

        let marker = SKNode()
        marker.name = GameScene.endlessIIMarkerName
        marker.position = CGPoint(x: 0, y: yBrickOffsetEndless)
        marker.zPosition = 0.6
        // Above the background and below the bricks, which sit at 1. A marker in front of the
        // field would be something to look past rather than something to notice.
        //
        // On the row's centre line rather than its top edge, because the row it arrives in is
        // generated empty for it - see `endlessIIRowIsMilestone`. A line drawn across the
        // middle of a row with nothing in it is a line you can read
        addChild(marker)

        let colour = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.3)
        let text = isBest ? "BEST \(best)m" : "\(arriving)m"

        // Both ends. A marker spends its whole life behind the field, and a label at one edge
        // is a label a brick can sit on top of - two of them makes it far more likely that
        // one is readable, and costs a label
        var textWidth: CGFloat = 0
        for alignment in [SKLabelHorizontalAlignmentMode.left, .right] {
            let label = SKLabelNode(fontNamed: scoreLabel.fontName)
            label.text = text
            label.fontSize = fontSize*0.6
            label.fontColor = colour
            label.horizontalAlignmentMode = alignment
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: alignment == .left
                                        ? -gameWidth/2 + labelSpacing
                                        : gameWidth/2 - labelSpacing,
                                     y: 0)
            marker.addChild(label)
            textWidth = max(textWidth, label.frame.width)
        }
        // On the line rather than sitting above it, so the two read as one marking. The line
        // breaks around each label rather than running underneath, which is what stops the
        // text fighting a rule drawn through its middle

        let gap = textWidth + labelSpacing*1.5
        let middle = SKShapeNode(rect: CGRect(x: -gameWidth/2 + gap, y: -0.5,
                                              width: max(0, gameWidth - gap*2), height: 1))
        let leftStub = SKShapeNode(rect: CGRect(x: -gameWidth/2, y: -0.5,
                                                width: labelSpacing/2, height: 1))
        let rightStub = SKShapeNode(rect: CGRect(x: gameWidth/2 - labelSpacing/2, y: -0.5,
                                                 width: labelSpacing/2, height: 1))
        for line in [middle, leftStub, rightStub] {
            line.fillColor = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.16)
            line.strokeColor = .clear
            line.alpha = isBest ? 0.5 : 1
            marker.addChild(line)
        }
    }

    /// How often the small unlabelled ticks appear.
    static let endlessIITickSpacing = 10

    /// How far a tick reaches in from each wall, as a fraction of the play area's width.
    static let endlessIITickLength: CGFloat = 0.045

    /// Whether the row being generated right now is the one a milestone marker will arrive in.
    ///
    /// Asked during row generation, which happens before the height is incremented - so the row
    /// being built is the one that will be labelled a field's depth from now.
    ///
    /// A hundred-metre line, or a personal best, is the thing on that row worth reading, and a
    /// row of bricks drawn over it hides most of it. The row is generated empty instead. What
    /// arrives there later is fair game: a Gravity brick can fall into it and a Spawner can
    /// fill it, and that is a field doing what fields do rather than a marker being born
    /// covered up.
    var endlessIIRowIsMilestone: Bool {
        guard gameMode == .endlessII else { return false }
        let arriving = endlessHeight + 1 + GameScene.endlessIIMarkerLead
        guard arriving > 0 else { return false }

        if arriving % GameScene.endlessIIMarkerSpacing == 0 { return true }
        let best = totalStatsArray.first?.endlessIIHeights.max() ?? 0
        return best > 0 && arriving == best
    }

    /// Puts the marks that are already in the opening field there.
    ///
    /// Every other marker enters at the top and descends into place, which works for heights
    /// the run has not reached yet. The opening field is different: it is built all at once,
    /// and the twenty-two rows of it already stand for 0m at the bottom up to 21m at the top.
    /// Nothing had ever placed those, so the first tick a player saw was at 30m and the scale
    /// appeared to start in the wrong place.
    ///
    /// 0m is the bottom row - where the field is now, and where the brick the first ball is
    /// aimed at sits.
    func seedEndlessIIMarkers() {
        guard gameMode == .endlessII else { return }

        for row in 0..<numberOfBrickRows {
            let height = numberOfBrickRows - 1 - row
            guard height % GameScene.endlessIITickSpacing == 0 else { continue }
            guard height % GameScene.endlessIIMarkerSpacing != 0 || height == 0 else { continue }

            let y = yBrickOffsetEndless - brickHeight*CGFloat(row) - brickHeight/2
            addEndlessIITick(at: y)
        }
        // Only the tens. A hundred-metre line cannot already be in the opening field, and 0m
        // gets a tick like any other ten so the scale starts where the player does
    }

    /// Adds a pair of short marks at the sides for the tens.
    ///
    /// The hundreds say how far you have come; these say how fast it is going past. A run
    /// spends most of its time between two hundred-metre lines with nothing moving to measure
    /// the descent against, and a tick every ten metres gives the field a scale without adding
    /// anything to read - which is why they carry no label and stop well short of the bricks.
    func addEndlessIITickIfDue() {
        guard gameMode == .endlessII else { return }

        let arriving = endlessHeight + GameScene.endlessIIMarkerLead
        guard arriving > 0, arriving % GameScene.endlessIITickSpacing == 0 else { return }
        guard arriving % GameScene.endlessIIMarkerSpacing != 0 else { return }
        // A hundred is a hundred, not a hundred and a tick

        addEndlessIITick(at: yBrickOffsetEndless - brickHeight/2)
    }

    /// A tick sits on the *bottom* edge of the row it belongs to, where a milestone marker
    /// sits on the row's centre line.
    ///
    /// They are doing different jobs. A milestone row is generated empty and the line is the
    /// thing in it, so the middle is where it belongs. A tick shares its row with whatever the
    /// field put there, and the boundary between two rows is the one place in a row that
    /// nothing is ever drawn - so that is where a mark can be read without competing.
    func addEndlessIITick(at y: CGFloat) {
        let tick = SKNode()
        tick.name = GameScene.endlessIIMarkerName
        tick.position = CGPoint(x: 0, y: y)
        tick.zPosition = 0.6
        addChild(tick)

        let length = gameWidth*GameScene.endlessIITickLength
        for x in [-gameWidth/2, gameWidth/2 - length] {
            let line = SKShapeNode(rect: CGRect(x: x, y: -0.5, width: length, height: 1))
            line.fillColor = UIColor(white: 1, alpha: 0.11)
            line.strokeColor = .clear
            tick.addChild(line)
        }
        // Dimmer than a hundred-metre line and a twentieth of its width. They are meant to be
        // felt at the edge of vision rather than looked at
    }

    /// Moves the markers down with the field, and clears the ones that have left it.
    ///
    /// Separate from the brick descent because markers are not bricks - they must not be
    /// counted, hit, or wait for the bottom row to clear before the field can move.
    func moveEndlessIIMarkersDown() {
        guard gameMode == .endlessII else { return }
        let move = SKAction.moveBy(x: 0, y: -brickHeight, duration: 0.05)

        enumerateChildNodes(withName: GameScene.endlessIIMarkerName) { node, _ in
            if node.position.y <= self.endlessIIMarkerFloor {
                node.name = nil
                node.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
                // Renamed first so the next descent does not find it again and restart the
                // fade it is already running
                return
            }
            node.run(move)
        }
    }

    /// Where a marker's work is done: the bottom edge of the lowest row a brick can occupy.
    ///
    /// Past that the line is below the field entirely. It used to carry on to the bottom of
    /// the screen, which put a moving line through the gap in front of the paddle - the part
    /// of the screen the player is actually watching - long after it had anything to say.
    var endlessIIMarkerFloor: CGFloat { finalBrickRowHeight - brickHeight/2 }

    func clearEndlessIIMarkers() {
        enumerateChildNodes(withName: GameScene.endlessIIMarkerName) { node, _ in
            node.removeFromParent()
        }
    }
}

// MARK: - Building the opening field in

extension GameScene {

    /// How long one row takes to arrive.
    ///
    /// The same 0.05s the field takes to move down a row for the rest of the run, because it
    /// is the same movement. The opening field was scaling and fading each brick into place,
    /// which is how bricks arrive in Classic - here it should look like the field descending,
    /// since that is what it will do from this moment until the run ends.
    static let endlessIIBuildInStep: TimeInterval = 0.05

    /// The gap between one row arriving and the next.
    ///
    /// Longer than the step, so the rows are distinct: a row lands, then the next one comes
    /// down. Twenty-two of these is the whole cascade, and it wants to be over before a player
    /// has finished deciding where to aim.
    static let endlessIIBuildInStagger: TimeInterval = 0.035

    /// When a brick in the opening field should arrive.
    ///
    /// Ordered by row so the field builds downward from the top - the direction it will keep
    /// arriving from for the rest of the run, which makes the animation say something about
    /// the mode rather than just being movement.
    func endlessIIBuildInDelay(for brick: SKSpriteNode) -> TimeInterval {
        let row = max(0, endlessIICell(of: brick).row)
        return GameScene.endlessIIBuildInStagger*Double(row)
    }

    /// Holds a brick at the top of the field, waiting for its turn to come down.
    ///
    /// Every brick in the opening field arrives the way every brick arrives for the rest of
    /// the run: at the top row, pushed down a row at a time by the ones behind it. So they all
    /// start on the top row rather than one row above their own place, and the field grows
    /// downward out of the top of the screen instead of fading into position.
    func prepareEndlessIIBuildIn(_ brick: SKSpriteNode) {
        brick.alpha = 0
        endlessIIBuildInFinalY[ObjectIdentifier(brick)] = brick.position.y
        brick.position.y = endlessIIGeometry.topRowY
        endlessIIBuildInBricks.append(brick)
    }

    /// Brings the opening field down, a row at a time.
    ///
    /// Waits for the splash screen. A run can be started or resumed while it is still up, and
    /// an animation played behind a full-screen cover is one the player sees the end of at
    /// best - which is exactly what was happening.
    func startEndlessIIBuildIn() {
        guard gameMode == .endlessII, savedGame == nil else { return }
        guard endlessIIBuildInBricks.isEmpty == false else { return }
        endlessIIBuildInWaiting = true
        // Not started here. `tickEndlessIIBuildIn` starts it on the first frame where nothing
        // is covering the scene - see there for why this is a poll rather than a notification
    }

    /// Starts the opening field the moment there is nobody standing in front of it.
    ///
    /// Asked every frame rather than arranged once. Listening for the splash screen to end
    /// assumed the splash was already up when the field was built, and whether it is depends
    /// on how the run was reached: from the menu it has long gone, and from a resume it goes
    /// up *after* the scene exists. A flag checked once is right for one of those orders and
    /// wrong for the other, where asking each frame is right for both - and costs a boolean
    /// test in a method that already runs every frame.
    func tickEndlessIIBuildIn(_ currentTime: TimeInterval) {
        guard endlessIIBuildInWaiting else { return }

        if endlessIIBuildInReadyAt == nil {
            endlessIIBuildInReadyAt = currentTime + GameScene.endlessIIBuildInCoverGrace
        }
        // The earliest it may start, set the first time it is asked. A cover that has not gone
        // up yet cannot be waited for: the level intro fades in a quarter of a second *after*
        // the level is built, so a field that started the moment it was asked would already be
        // arriving behind it

        if splashScreenIsShowing || endlessIILevelIntroShowing {
            endlessIIBuildInReadyAt = currentTime + GameScene.endlessIIBuildInSettle
            return
        }
        // Pushed back for as long as anything is in front of the scene, and by a beat again
        // once it goes

        guard let ready = endlessIIBuildInReadyAt, currentTime >= ready else { return }

        endlessIIBuildInWaiting = false
        endlessIIBuildInReadyAt = nil
        runEndlessIIBuildIn()
    }

    /// How long the field waits after the last thing covering it says it has gone.
    ///
    /// Short. The level intro posts its notification *after* taking its view off the screen,
    /// so by the time this is counted from there is genuinely nothing in the way - this is
    /// only covering the app's splash screen, which clears its flag and then spends a quarter
    /// of a second fading. Any longer and the run opens with a few seconds of nothing, which
    /// is what two seconds of it felt like.
    static let endlessIIBuildInSettle: TimeInterval = 0.35

    /// How long the field waits for a cover that has not gone up yet.
    ///
    /// The level intro fades in a quarter of a second *after* the level is built, so a field
    /// that started the moment it was asked would be arriving behind a screen that was still
    /// on its way. Only ever spent when nothing covers the scene at all.
    static let endlessIIBuildInCoverGrace: TimeInterval = 0.75

    func runEndlessIIBuildIn() {
        guard endlessIIBuildInBricks.isEmpty == false else { return }
        endlessIIBuildingIn = true

        let step = GameScene.endlessIIBuildInStep
        let stagger = GameScene.endlessIIBuildInStagger
        let rows = endlessIIBuildInBricks.reduce(0) { deepest, brick in
            max(deepest, endlessIIBuildInRow(of: brick))
        }

        for brick in endlessIIBuildInBricks {
            guard brick.parent != nil else { continue }
            let row = endlessIIBuildInRow(of: brick)
            let arrives = rows - row
            // The deepest row is built first and pushed down by everything after it, which is
            // the order the field itself arrives in: a new row at the top, and the rest of the
            // field a row lower than it was

            var descent: [SKAction] = [.wait(forDuration: stagger*Double(arrives)),
                                       .fadeIn(withDuration: step)]
            for _ in 0..<row {
                descent.append(.wait(forDuration: max(0, stagger - step)))
                descent.append(.moveBy(x: 0, y: -brickHeight, duration: step))
            }
            brick.run(.sequence(descent))
            // Every brick moves on the same beat, so the whole field steps down together the
            // way it does in play - rather than each row sliding one place on its own
        }
        endlessIIBuildInBricks.removeAll()
        endlessIIBuildInFinalY.removeAll()

        // The row-down sound and knock, once per row, so the field arrives with the same
        // feedback it will give every time it moves for the rest of the run
        for row in 0...max(0, rows) {
            run(.sequence([.wait(forDuration: stagger*Double(row)),
                           .run { [weak self] in self?.endlessIIBuildInRowLanded() }]))
        }

        let total = stagger*Double(rows) + step
        run(.sequence([.wait(forDuration: total),
                       .run { [weak self] in self?.endlessIIBuildingIn = false }]))
        // Cleared on a timer rather than by counting bricks finishing, because the flag only
        // exists to know whether a tap should skip - and once everything has arrived there is
        // nothing left to skip
    }

    /// Which row a waiting brick belongs to.
    ///
    /// Read from where it was going to be, not from where it is: they are all sitting on the
    /// top row until their turn comes.
    func endlessIIBuildInRow(of brick: SKSpriteNode) -> Int {
        guard let finalY = endlessIIBuildInFinalY[ObjectIdentifier(brick)] else {
            return max(0, endlessIICell(of: brick).row)
        }
        return max(0, Int(((endlessIIGeometry.topRowY - finalY)/brickHeight).rounded()))
    }

    private func endlessIIBuildInRowLanded() {
        guard endlessIIBuildingIn else { return }
        if soundsSetting { run(endlessRowDownSound) }
        if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.4) }
    }

    /// Puts the whole field on screen now. Returns whether there was anything to skip, so a
    /// tap that lands during the build is spent on it rather than launching the ball.
    @discardableResult
    func finishEndlessIIBuildIn() -> Bool {
        if endlessIIBuildInWaiting {
            endlessIIBuildInWaiting = false
            endlessIIBuildInReadyAt = nil
            runEndlessIIBuildIn()
            return true
        }
        // Tapped while the field is still waiting for its moment. Somebody who taps wants to
        // play, so the wait is spent rather than served - and the tap is spent on the field
        // rather than launching the ball into a screen that has nothing in it yet

        guard endlessIIBuildingIn else { return false }
        endlessIIBuildingIn = false
        removeAllActions()
        // The per-row sound and knock are scheduled on the scene, and a skipped build-in
        // should not carry on tapping out rows that have already arrived

        let landed = endlessIIBuildInBricks
        endlessIIBuildInBricks.removeAll()
        for brick in landed where brick.parent != nil {
            if let finalY = endlessIIBuildInFinalY[ObjectIdentifier(brick)] {
                brick.position.y = finalY
            }
        }
        endlessIIBuildInFinalY.removeAll()
        // Anything still waiting its turn is sitting on the top row, so it is put where it was
        // always going rather than moved down by a guess

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            let unfinished = brick.hasActions()
            brick.removeAllActions()
            brick.alpha = 1
            brick.setScale(1)
            if unfinished { brick.position.y = self.endlessIIRowCentre(nearest: brick.position.y) }
            // A brick caught mid-descent is put on the row it was heading for, or it would sit
            // a fraction of a row out for the rest of the run - and a brick off its row centre
            // is the one thing the descent and the bottom-row check cannot survive
        }
        return true
    }

    /// The centre of the row nearest a given y, which is where every brick has to sit.
    func endlessIIRowCentre(nearest y: CGFloat) -> CGFloat {
        let rows = ((yBrickOffsetEndless - y)/brickHeight).rounded()
        return yBrickOffsetEndless - brickHeight*rows
    }
}
