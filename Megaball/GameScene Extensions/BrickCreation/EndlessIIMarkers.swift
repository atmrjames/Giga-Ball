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
        marker.position = CGPoint(x: 0, y: yBrickOffsetEndless + brickHeight/2)
        marker.zPosition = 0.6
        // Above the background and below the bricks, which sit at 1. A marker in front of the
        // field would be something to look past rather than something to notice
        addChild(marker)

        let colour = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.3)
        let label = SKLabelNode(fontNamed: scoreLabel.fontName)
        label.text = isBest ? "BEST \(best)m" : "\(arriving)m"
        label.fontSize = fontSize*0.6
        label.fontColor = colour
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -gameWidth/2 + labelSpacing, y: 0)
        marker.addChild(label)
        // On the line rather than sitting above it, so the two read as one marking. The line
        // breaks around it rather than running underneath, which is what stops the text
        // fighting a rule drawn through its middle

        let gap = label.frame.width + labelSpacing*1.5
        let left = SKShapeNode(rect: CGRect(x: -gameWidth/2, y: -0.5,
                                            width: labelSpacing/2, height: 1))
        let right = SKShapeNode(rect: CGRect(x: -gameWidth/2 + gap, y: -0.5,
                                             width: gameWidth - gap, height: 1))
        for line in [left, right] {
            line.fillColor = isBest ? brickGreenGigaball : UIColor(white: 1, alpha: 0.16)
            line.strokeColor = .clear
            line.alpha = isBest ? 0.5 : 1
            marker.addChild(line)
        }
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
    /// Short. It is a flourish before a run, not a title sequence, and anybody past their
    /// first few games wants to be playing.
    static let endlessIIBuildInSweep: TimeInterval = 0.35

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
