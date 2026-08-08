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
        marker.position = CGPoint(x: 0, y: yBrickOffsetEndless - brickHeight/2)
        marker.zPosition = 0.6
        // The node sits *on* the line it draws, the same convention a tick uses, so one
        // floor test retires both correctly. It used to sit on the row centre and draw
        // half a brick lower, which is how a line carried on below the lower limit for
        // another half row after the check said it was done (play test)
        // Above the background and below the bricks, which sit at 1. A marker in front of the
        // field would be something to look past rather than something to notice.
        //
        // The line sits at the *bottom* of its row, where it lines up with the 10m ticks
        // and the lower limit line - a centred line measured against edge-aligned marks
        // read as being on the wrong row. The labels sit just above it, inside the empty
        // row generated for the marker, so bricks on neighbouring rows cannot cover them
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
            label.verticalAlignmentMode = .bottom
            label.position = CGPoint(x: alignment == .left
                                        ? -gameWidth/2 + labelSpacing
                                        : gameWidth/2 - labelSpacing,
                                     y: 3)
            marker.addChild(label)
            textWidth = max(textWidth, label.frame.width)
        }
        // On the line rather than sitting above it, so the two read as one marking. The line
        // breaks around each label rather than running underneath, which is what stops the
        // text fighting a rule drawn through its middle

        let gap = textWidth + labelSpacing*1.5
        let lineY: CGFloat = -0.5
        let middle = SKShapeNode(rect: CGRect(x: -gameWidth/2, y: lineY,
                                              width: gameWidth, height: 1))
        let leftStub = SKShapeNode(rect: CGRect(x: -gameWidth/2, y: lineY,
                                                width: labelSpacing/2, height: 1))
        let rightStub = SKShapeNode(rect: CGRect(x: gameWidth/2 - labelSpacing/2, y: lineY,
                                                 width: 0, height: 0))
        _ = gap
        // The line no longer breaks around the labels - it runs the full width at the
        // row's bottom edge and the labels float above it, so nothing fights
        for line in [middle, leftStub, rightStub] {
            line.fillColor = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.16)
            line.strokeColor = .clear
            line.alpha = isBest ? 0.5 : 1
            marker.addChild(line)
        }
    }

    /// The columns a milestone marker's labels sit in.
    ///
    /// The labels are pinned a label-spacing in from each wall, so it is the outermost
    /// column at each side that can cover one. Everything between them is fair game for
    /// bricks (play test: a whole empty row every hundred metres was a free rest).
    func endlessIIColumnIsMilestoneLabel(_ column: Int) -> Bool {
        column == 0 || column == numberOfBrickColumns - 1
    }

    /// How often the small unlabelled ticks appear.
    static let endlessIITickSpacing = 10

    /// How far a tick reaches in from each wall, as a fraction of the play area's width.
    ///
    /// Halved from its first guess after play-testing - at the old length the ticks read as
    /// part of the field rather than as marks on the wall beside it.
    static let endlessIITickLength: CGFloat = 0.0225

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

    /// Draws the line the field dies on.
    ///
    /// The lower limit - the row bricks are destroyed at, the depth the run is defending -
    /// had nothing marking it, and the play test asked for the bottom row to be more
    /// distinctive. A solid warm line under the last row says "here", unmistakably, in a
    /// colour nothing else on the field uses.
    func showEndlessIILowerLimit() {
        guard gameMode == .endlessII, endlessIILowerLimitLine == nil else { return }
        let line = SKSpriteNode(color: GameScene.endlessIILowerLimitColour,
                                size: CGSize(width: gameWidth, height: 1))
        line.position = CGPoint(x: 0, y: finalBrickRowHeight - brickHeight/2)
        line.zPosition = 0.5
        line.alpha = 0.09
        // Plain transparent white, like the ticks, and fainter than every height mark -
        // third play-test round: the warm colour still read as red, and a marker drawn
        // over this line has to stay readable, which means this one gives way. Below the
        // markers' zPosition too, for the same reason
        addChild(line)
        endlessIILowerLimitLine = line
    }

    static let endlessIILowerLimitColour = UIColor.white

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
        showEndlessIILowerLimit()
        setupEndlessIIBackdrop()
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
        // Whether a best-height line already owns this row is `addEndlessIITick`'s
        // question now - one rule, asked of the scene, rather than repeated arithmetic
    }

    /// Whether a marker or tick is already drawn at this height.
    ///
    /// The rule the play test asked for, stated once: a best-height line beats a hundred,
    /// and both beat a ten-metre tick. Rather than repeating the arithmetic at each
    /// caller - which is how a tick ended up drawn over a hundred-metre line - the
    /// question is asked of the scene: is there already a mark on this line.
    func endlessIIMarkExists(at y: CGFloat) -> Bool {
        var found = false
        enumerateChildNodes(withName: GameScene.endlessIIMarkerName) { node, stop in
            if abs(node.position.y - y) < self.brickHeight/2 {
                found = true
                stop.initialize(to: true)
            }
        }
        return found
    }

    /// Both a tick and a milestone marker sit on the *boundary* between two rows - the one
    /// place in a row that nothing else is ever drawn, so a mark can be read there without
    /// competing with the field.
    func addEndlessIITick(at y: CGFloat) {
        guard endlessIIMarkExists(at: y) == false else { return }
        // A hundred-metre line or a best-height line already owns this row: they say
        // everything a tick would, and more (play test - the ticks were drawing over them)

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

    /// Holds a brick just above the field, waiting for its turn to fall.
    ///
    /// The opening field rains in: each brick starts above the top of the play area and falls
    /// to its own row, deepest rows first so the field stacks up from the bottom. Stepping
    /// down in lockstep was tried first and read as a marching wall - play-testing asked for
    /// the fall.
    func prepareEndlessIIBuildIn(_ brick: SKSpriteNode) {
        brick.alpha = 0
        endlessIIBuildInFinalY[ObjectIdentifier(brick)] = brick.position.y
        brick.position.y = endlessIIGeometry.topRowY + brickHeight
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

        if endlessIIBuildInStartNow {
            endlessIIBuildInStartNow = false
            endlessIIBuildInWaiting = false
            endlessIIBuildInReadyAt = nil
            runEndlessIIBuildIn()
            return
        }
        // The level intro's final fade has begun: the field starts now, behind the last
        // quarter second of it, so something is already moving when the screen is readable

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

        let stagger = GameScene.endlessIIBuildInStagger
        let fallPerRow = GameScene.endlessIIBuildInFallPerRow
        let rows = endlessIIBuildInBricks.reduce(0) { deepest, brick in
            max(deepest, endlessIIBuildInRow(of: brick))
        }

        var landings: [Int: TimeInterval] = [:]
        for brick in endlessIIBuildInBricks {
            guard brick.parent != nil else { continue }
            let row = endlessIIBuildInRow(of: brick)
            guard let finalY = endlessIIBuildInFinalY[ObjectIdentifier(brick)] else { continue }

            let delay = stagger*Double(rows - row)
            let fall = max(0.06, fallPerRow*Double(row + 1))
            // The deepest rows leave first and fall furthest, so the field stacks up from
            // the bottom - each row lands just before the one that will sit above it

            let drop = SKAction.moveTo(y: finalY, duration: fall)
            drop.timingMode = .easeIn
            brick.run(.sequence([.wait(forDuration: delay),
                                 .group([.fadeIn(withDuration: 0.05), drop])]))

            let arrival = delay + fall
            if landings[row] == nil || arrival < landings[row]! { landings[row] = arrival }
        }
        endlessIIBuildInBricks.removeAll()
        // The destinations are kept until the fall completes, because a tap can skip it at
        // any moment and a mid-fall brick has to snap to where it was *going* - the nearest
        // row centre is where it happens to be, which is the wrong row for everything below
        // the top

        // The row-down knock as each row lands, so the field arrives with the same feedback
        // it will give every time it moves for the rest of the run
        for arrival in landings.values.sorted() {
            run(.sequence([.wait(forDuration: arrival),
                           .run { [weak self] in self?.endlessIIBuildInRowLanded() }]))
        }

        let total = (landings.values.max() ?? 0) + 0.05
        run(.sequence([.wait(forDuration: total),
                       .run { [weak self] in
                           self?.endlessIIBuildingIn = false
                           self?.endlessIIBuildInFinalY.removeAll()
                       }]))
        // Cleared on a timer rather than by counting bricks finishing, because the flag only
        // exists to know whether a tap should skip - and once everything has arrived there is
        // nothing left to skip
    }

    /// How long one row of fall takes. The bottom row falls the whole field in about a
    /// quarter of a second - a drop, not a descent.
    static let endlessIIBuildInFallPerRow: TimeInterval = 0.012

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
        // Anything still waiting its turn is sitting on the top row, so it is put where it was
        // always going rather than moved down by a guess.
        //
        // The destinations are NOT cleared here - the sweep below still needs them. They
        // were, and every brick a skip caught mid-fall took the nearest-row fallback
        // instead of its own destination: a brick still waiting out its delay was sitting
        // *above* the top row, whose nearest row centre is above the field - which is how
        // skipped build-ins left bricks parked on top of the HUD (the play-test screenshot)

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            let unfinished = brick.hasActions()
            brick.removeAllActions()
            brick.alpha = 1
            brick.setScale(1)
            guard unfinished else { return }
            if let finalY = self.endlessIIBuildInFinalY[ObjectIdentifier(brick)] {
                brick.position.y = finalY
            } else {
                brick.position.y = self.endlessIIRowCentre(nearest: brick.position.y)
            }
            // A brick caught mid-fall snaps to its own destination - the play test found
            // them frozen wherever the tap caught them, which left the whole field one
            // ragged diagonal. The nearest row centre is only the fallback for a brick
            // this build-in never owned
        }
        endlessIIBuildInFinalY.removeAll()
        return true
    }

    /// The centre of the row nearest a given y, which is where every brick has to sit.
    func endlessIIRowCentre(nearest y: CGFloat) -> CGFloat {
        let rows = ((yBrickOffsetEndless - y)/brickHeight).rounded()
        return yBrickOffsetEndless - brickHeight*rows
    }
}
