//
//  EndlessIIVision.swift
//  Megaball
//
//  The two vision power-ups: the Trajectory Line and the Landing Marker.
//
//  Phase 8's first batch, and deliberately the gentlest: neither changes a single rule of
//  play. One draws the path the ball is about to take, reflecting off the walls and stopping
//  at the first brick it would meet; the other says only where the ball will cross the
//  paddle's line. Both are the same question asked of `BallPath`, which is pure arithmetic
//  and tested as such - what lives here is only the asking, the drawing, and the timers.
//
//  Per ball, as §5.5 requires. With four balls in play that is four lines, which is exactly
//  the kind of thing that can only be judged by playing it - the drawing is kept thin and
//  quiet so the field stays legible underneath it.
//
//  Endless 2.0 only. The nodes are created on first use, driven from `update`, and removed
//  when the timer runs out, so the other modes never even allocate them.
//

import SpriteKit

extension GameScene {

    /// How long one collection lasts, matching the game's other timed power-ups.
    static let endlessIIVisionDuration: TimeInterval = 10

    /// How far the Trajectory Line draws, in ball radii, by stacking level.
    ///
    /// A second collection extends the clock; a third lengthens the line (§5.4). The lengths
    /// are generous because the line also stops at the first brick - deep fields cut it short
    /// on their own, so the limit mostly shows on an empty screen.
    static let endlessIITrajectoryReach: [CGFloat] = [40, 80]

    // MARK: - Collection

    /// Starts or extends the Trajectory Line.
    func endlessIICollectTrajectoryLine() {
        if endlessIITrajectoryRemaining > 0 {
            endlessIITrajectoryLevel = min(endlessIITrajectoryLevel + 1,
                                           GameScene.endlessIITrajectoryReach.count - 1)
            // Already running: this collection extends, and past that it lengthens
        }
        endlessIITrajectoryRemaining += GameScene.endlessIIVisionDuration
        endlessIITrajectoryTotal = endlessIITrajectoryRemaining
    }

    /// Starts or extends the Landing Marker.
    func endlessIICollectLandingMarker() {
        endlessIILandingRemaining += GameScene.endlessIIVisionDuration
        endlessIILandingTotal = endlessIILandingRemaining
    }

    // MARK: - Each frame

    /// Runs the timers down and redraws whatever is active.
    ///
    /// Called from `update` with the frame's timestamp. The prediction is re-asked every
    /// frame rather than cached, because everything it depends on - the ball, the field, the
    /// paddle - moves every frame; a stale line pointing through a brick that has already
    /// been destroyed is the lie this feature must not tell.
    func tickEndlessIIVision(_ currentTime: TimeInterval) {
        guard gameMode == .endlessII else { return }

        let delta = endlessIIVisionLastTick == 0 ? 0 : min(currentTime - endlessIIVisionLastTick, 0.5)
        endlessIIVisionLastTick = currentTime
        // Capped, so a pause or a background does not swallow the whole duration in one frame

        let running = gameState.currentState is Playing && isPaused == false
        if running {
            endlessIITrajectoryRemaining = max(0, endlessIITrajectoryRemaining - delta)
            endlessIILandingRemaining = max(0, endlessIILandingRemaining - delta)
        }
        // The clock only runs while play does - pausing freezes these like any other timer

        guard endlessIITrajectoryRemaining > 0 || endlessIILandingRemaining > 0 else {
            endlessIIClearVision()
            return
        }

        let bricks = endlessIIVisionBricks()
        let bounds = endlessIIVisionBounds()
        var lineIndex = 0
        var markerIndex = 0

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil else { continue }
            let velocity = subject.physicsBody?.velocity ?? .zero
            guard velocity.dx != 0 || velocity.dy != 0 else { continue }
            // A held or waiting ball has no path yet. Its line would be a dot

            let reach = GameScene.endlessIITrajectoryReach[endlessIITrajectoryLevel]*ballSize/2
            let path = BallPath.predict(from: subject.position, velocity: velocity,
                                        radius: subject.size.width/2, bounds: bounds,
                                        bricks: bricks,
                                        maximumLength: endlessIITrajectoryRemaining > 0 ? reach : 0)

            if endlessIITrajectoryRemaining > 0, path.points.count > 1 {
                endlessIIVisionLine(at: lineIndex).path = endlessIIVisionCGPath(path.points)
                lineIndex += 1
            }
            if endlessIILandingRemaining > 0, let landing = path.landing {
                let marker = endlessIIVisionMarker(at: markerIndex)
                marker.position = CGPoint(x: landing.x, y: paddle.position.y)
                markerIndex += 1
            }
            // The marker sits on the paddle's own line, whatever height the prediction used -
            // it is an aiming aid for the paddle, so it belongs where the paddle is
        }

        endlessIITrimVision(lines: lineIndex, markers: markerIndex)
    }

    /// The play area as the predictor sees it.
    func endlessIIVisionBounds() -> BallPath.Bounds {
        BallPath.Bounds(left: -gameWidth/2, right: gameWidth/2,
                        ceiling: frame.height/2 - topScreenBlock.size.height,
                        paddleLine: paddle.position.y)
    }

    /// Every brick the line should stop at, as rectangles.
    ///
    /// `frame` rather than position-and-size, because a Big or power-up brick's node is not
    /// at its sprite's centre - the frame is what the ball actually meets. Flashing bricks
    /// that are currently passable are left in: the ball may pass, but so may it not by the
    /// time it arrives, and a line through a brick that turns solid is the worse lie.
    func endlessIIVisionBricks() -> [CGRect] {
        var bricks: [CGRect] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard node.isHidden == false else { return }
            bricks.append(node.frame)
        }
        return bricks
    }

    // MARK: - The nodes

    /// The line for the nth ball, made when first needed.
    private func endlessIIVisionLine(at index: Int) -> SKShapeNode {
        while endlessIITrajectoryLines.count <= index {
            let line = SKShapeNode()
            line.strokeColor = UIColor(white: 1, alpha: 0.35)
            line.lineWidth = 1.5
            line.lineCap = .round
            line.zPosition = 3
            // Under the balls and power-ups, over the background and bricks - and faint,
            // because four of these must not shout over the field they are explaining
            addChild(line)
            endlessIITrajectoryLines.append(line)
        }
        return endlessIITrajectoryLines[index]
    }

    /// The landing marker for the nth ball, made when first needed.
    private func endlessIIVisionMarker(at index: Int) -> SKShapeNode {
        while endlessIILandingMarkers.count <= index {
            let marker = SKShapeNode(circleOfRadius: ballSize/2)
            marker.strokeColor = UIColor(white: 1, alpha: 0.7)
            marker.fillColor = UIColor(white: 1, alpha: 0.15)
            marker.lineWidth = 1.5
            marker.zPosition = 3
            // A ghost of the ball, where the ball will be - the same size, so what it says
            // needs no legend
            addChild(marker)
            endlessIILandingMarkers.append(marker)
        }
        return endlessIILandingMarkers[index]
    }

    private func endlessIIVisionCGPath(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }

    /// Removes any drawing beyond what this frame used.
    ///
    /// A ball can be lost, caught, or stationary between frames, so the number of lines is a
    /// new answer every frame - and a line left behind belongs to a ball that no longer is.
    private func endlessIITrimVision(lines: Int, markers: Int) {
        while endlessIITrajectoryLines.count > lines {
            endlessIITrajectoryLines.removeLast().removeFromParent()
        }
        while endlessIILandingMarkers.count > markers {
            endlessIILandingMarkers.removeLast().removeFromParent()
        }
    }

    /// Ends both effects and removes their drawing. For timers running out, the ball being
    /// lost, and Endless 2.0's field reset.
    func endlessIIClearVision() {
        endlessIITrimVision(lines: 0, markers: 0)
        if endlessIITrajectoryRemaining <= 0 {
            endlessIITrajectoryLevel = 0
            endlessIITrajectoryTotal = 0
        }
        if endlessIILandingRemaining <= 0 {
            endlessIILandingTotal = 0
        }
    }

    /// Takes both effects off entirely, timers included. For the life ending.
    func endlessIIResetVision() {
        endlessIITrajectoryRemaining = 0
        endlessIILandingRemaining = 0
        endlessIIClearVision()
    }

    // MARK: - The ring HUD

    /// What the ring should show for these two, since they have no tray slot to be read from.
    func endlessIIVisionRingEntries() -> [PowerUpRingHUD.Entry] {
        var entries: [PowerUpRingHUD.Entry] = []
        if endlessIITrajectoryRemaining > 0, endlessIITrajectoryTotal > 0 {
            entries.append(PowerUpRingHUD.Entry(
                id: "endlessIITrajectory",
                texture: SKTexture(image: PowerUpIcon.trajectoryLine),
                remaining: CGFloat(endlessIITrajectoryRemaining/endlessIITrajectoryTotal),
                segments: nil))
        }
        if endlessIILandingRemaining > 0, endlessIILandingTotal > 0 {
            entries.append(PowerUpRingHUD.Entry(
                id: "endlessIILanding",
                texture: SKTexture(image: PowerUpIcon.landingMarker),
                remaining: CGFloat(endlessIILandingRemaining/endlessIILandingTotal),
                segments: nil))
        }
        return entries
    }
}
