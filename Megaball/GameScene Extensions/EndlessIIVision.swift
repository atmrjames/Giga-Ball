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

    /// Starts or extends the Landing Marker - in paddle hits, not seconds, like the rest
    /// of the paddle-facing power-ups after the turn-based revision.
    func endlessIICollectLandingMarker() {
        endlessIILandingRemaining += GameScene.endlessIIPaddlePowerUpTurns
        endlessIILandingTotal = endlessIILandingRemaining
    }

    /// A paddle contact spends a Landing Marker turn. Called from the shared spend.
    func endlessIISpendLandingTurn() {
        guard endlessIILandingRemaining > 0 else { return }
        endlessIILandingRemaining = max(0, endlessIILandingRemaining - 1)
        if endlessIILandingRemaining == 0 { endlessIILandingTotal = 0 }
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
        }
        // The trajectory's clock runs on time; the landing marker's runs on paddle hits
        // (endlessIISpendLandingTurn) - pausing freezes both, each in its own way

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
                                        maximumLength: endlessIITrajectoryRemaining > 0 ? reach : 0,
                                        brickBounces: endlessIITrajectoryRemaining > 0
                                            ? GameScene.endlessIITrajectoryBrickBounces : 0)

            if endlessIITrajectoryRemaining > 0, path.points.count > 1 {
                var points = path.points
                if let landing = path.landing, points.count >= 2 {
                    let last = points[points.count - 1]
                    let previous = points[points.count - 2]
                    let incoming = CGVector(dx: last.x - previous.x, dy: last.y - previous.y)
                    let angle = EndlessIIPaddleEffects.paddleBounceAngle(
                        arriving: incoming, landingX: landing.x,
                        paddleX: paddle.position.x, paddleHalfWidth: paddle.size.width/2,
                        adjustmentK: angleAdjustmentK, minimumDeg: minAngleDeg,
                        influence: endlessIIPaddleAngleInfluence)
                    let reach = ballSize*5
                    points.append(CGPoint(x: landing.x + cos(angle)*reach,
                                          y: landing.y + sin(angle)*reach))
                    // The bounce the paddle would give from where it stands now, drawn by
                    // the same rule paddleHit applies - the line keeps going off the paddle
                    // so the player can aim the shot after the catch, not just the catch
                }
                lineIndex = endlessIIDrawFadingTrajectory(points, from: lineIndex)
            }
            if endlessIILandingRemaining > 0, let landing = path.landing {
                let marker = endlessIIVisionMarker(at: markerIndex)
                marker.position = CGPoint(x: landing.x,
                                          y: paddle.position.y + paddleHeight*1.2)
                markerIndex += 1
            }
            // Just above the paddle, pointing down at where the ball will cross - below it,
            // the Backstop covered it whenever the two ran together. Pulled in closer to
            // the paddle's top in round 11 ("move landing marker closer to top of paddle")
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
            // Overwritten per segment by endlessIIDrawFadingTrajectory - this is the colour a
            // segment has before it knows how far down the path it sits
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

    /// Draws a predicted path as a run of short segments that fade and blur with distance.
    ///
    /// **The fading is the honesty.** The predictor is arithmetic, and the scene applies its
    /// own corrections at every bounce - angles nudged off horizontal and vertical, a
    /// two-brick seam resolved as one face - so the far end of a long line is a guess wearing
    /// a prediction's clothes. Drawn solid it claims a precision it does not have; drawn
    /// fading it says where the ball is going and admits it is less sure the further it looks
    /// (play-test round 39). That is what makes two brick bounces worth drawing at all.
    ///
    /// A second collection sharpens it: `endlessIITrajectoryLevel` holds the fade open longer,
    /// so a deepened Trajectory Line really is a clearer one.
    ///
    /// Returns the next free index in the shared line pool.
    private func endlessIIDrawFadingTrajectory(_ points: [CGPoint], from start: Int) -> Int {
        guard points.count > 1 else { return start }

        let step = max(ballSize*0.9, 1)
        let sharpness = CGFloat(endlessIITrajectoryLevel)
        let total = zip(points, points.dropFirst()).reduce(CGFloat(0)) {
            $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y)
        }
        guard total > 0 else { return start }

        var index = start
        var travelled: CGFloat = 0

        for (from, to) in zip(points, points.dropFirst()) {
            let length = hypot(to.x - from.x, to.y - from.y)
            guard length > 0 else { continue }
            let pieces = max(Int((length/step).rounded(.up)), 1)

            for piece in 0..<pieces {
                let a = CGFloat(piece)/CGFloat(pieces)
                let b = CGFloat(piece + 1)/CGFloat(pieces)
                let head = CGPoint(x: from.x + (to.x - from.x)*a, y: from.y + (to.y - from.y)*a)
                let tail = CGPoint(x: from.x + (to.x - from.x)*b, y: from.y + (to.y - from.y)*b)

                // How far along the whole path this piece sits, which is the only thing the
                // fade depends on - so it carries across bounces rather than restarting at
                // each one, and a line that has turned a corner keeps getting less certain
                let along = (travelled + length*(a + b)/2)/total
                let certainty = pow(1 - along, 1.8 - min(sharpness, 2)*0.45)

                let segment = endlessIIVisionLine(at: index)
                index += 1
                let path = CGMutablePath()
                path.move(to: head)
                path.addLine(to: tail)
                segment.path = path
                segment.strokeColor = UIColor(white: 1, alpha: max(0.05, 0.45*certainty))
                segment.glowWidth = (1 - certainty)*3
                // The blur grows as the confidence falls, which is the same statement made
                // twice - a line you can barely see and can barely locate
            }
            travelled += length
        }
        return index
    }

    /// The landing marker for the nth ball, made when first needed.
    private func endlessIIVisionMarker(at index: Int) -> SKShapeNode {
        while endlessIILandingMarkers.count <= index {
            let size = ballSize*0.7
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: -size*0.6))
            path.addLine(to: CGPoint(x: -size*0.55, y: size*0.4))
            path.addLine(to: CGPoint(x: size*0.55, y: size*0.4))
            path.closeSubpath()
            let marker = SKShapeNode(path: path)
            marker.strokeColor = .clear
            marker.fillColor = UIColor(white: 1, alpha: 0.7)
            marker.zPosition = 5
            // Pointing down now, and above the backstop's layer - it lives above the paddle
            // A small triangle pointing up at the crossing point, sitting under the paddle -
            // play-testing preferred it to the ghost ball, which crowded the paddle itself
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
