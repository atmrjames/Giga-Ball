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
    /// One less than the field's depth: a line entering at the top row has that many rows to
    /// travel before it is in the bottom one.
    static var endlessIIMarkerLead: Int { GameSceneLayout.brickRows - 1 }

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

    /// How long the whole cascade takes, top row to bottom.
    ///
    /// Short - it is a flourish before a run, not a title sequence, and anybody past their
    /// first few games wants to be playing. But it was 0.35s, which over twenty-two rows is
    /// sixteen milliseconds a row against a quarter-second fade on each brick: every row was
    /// still arriving while every other row was arriving, so the wave was there in the code
    /// and invisible on the screen. Long enough now to read as sweeping downward, and still
    /// over before a player has finished deciding where to aim.
    static let endlessIIBuildInSweep: TimeInterval = 0.9

    /// How long one brick takes to arrive once its turn comes.
    ///
    /// Shorter than the sweep by enough that the rows are distinct. A brick that fades in over
    /// longer than the gap between rows blurs into the ones after it, which is the whole
    /// difference between a cascade and everything appearing at once slightly unevenly.
    static let endlessIIBuildInFade: TimeInterval = 0.16

    /// When a brick in the opening field should appear.
    ///
    /// Ordered by row so the field builds downward from the top - the direction it will keep
    /// arriving from for the rest of the run, which makes the animation say something about
    /// the mode rather than just being movement.
    func endlessIIBuildInDelay(for brick: SKSpriteNode) -> TimeInterval {
        let row = max(0, endlessIICell(of: brick).row)
        let rows = max(1, numberOfBrickRows - 1)
        return GameScene.endlessIIBuildInSweep*min(1, Double(row)/Double(rows))
    }

    func startEndlessIIBuildIn() {
        guard gameMode == .endlessII, savedGame == nil else { return }
        endlessIIBuildingIn = true
        run(.sequence([.wait(forDuration: GameScene.endlessIIBuildInSweep + 0.3),
                       .run { [weak self] in self?.endlessIIBuildingIn = false }]))
        // Cleared on a timer rather than by counting bricks finishing, because the flag only
        // exists to know whether a tap should skip - and once everything has arrived there is
        // nothing left to skip
    }

    /// Puts the whole field on screen now. Returns whether there was anything to skip, so a
    /// tap that lands during the build is spent on it rather than launching the ball.
    @discardableResult
    func finishEndlessIIBuildIn() -> Bool {
        guard endlessIIBuildingIn else { return false }
        endlessIIBuildingIn = false

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            node.removeAllActions()
            node.alpha = 1
            node.setScale(1)
        }
        return true
    }
}
