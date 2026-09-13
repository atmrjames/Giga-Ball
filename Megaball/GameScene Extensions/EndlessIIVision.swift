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

    /// How far the Trajectory Line draws, in ball radii, by stacking level.
    ///
    /// A second collection refills the clock; a third lengthens the line. The lengths
    /// are generous because the line also stops at the first brick - deep fields cut it short
    /// on their own, so the limit mostly shows on an empty screen.
    static let endlessIITrajectoryReach: [CGFloat] = [40, 80]

    // MARK: - Collection

    /// Starts or extends the Ball Trajectory - in paddle hits, like the Landing Marker.
    ///
    /// **Both vision power-ups count hits** (round 218's workbook). They answer the same
    /// question about the same bounce, and one of them measured in seconds while the other
    /// measured in bounces meant two rings counting differently side by side.
    func endlessIICollectTrajectoryLine() {
        if endlessIITrajectoryRemaining > 0 {
            endlessIITrajectoryLevel = min(endlessIITrajectoryLevel + 1,
                                           GameScene.endlessIITrajectoryReach.count - 1)
            // Already running: this collection extends, and past that it lengthens
        }
        endlessIITrajectoryRemaining = GameScene.endlessIIPaddlePowerUpTurns
        endlessIITrajectoryTotal = endlessIITrajectoryRemaining
        // Reset, not extended, like every other clock in the mode since round 220
    }

    /// A paddle contact spends a Ball Trajectory turn. Called from the shared spend.
    func endlessIISpendTrajectoryTurn() {
        guard endlessIITrajectoryRemaining > 0 else { return }
        endlessIITrajectoryRemaining = max(0, endlessIITrajectoryRemaining - 1)
        if endlessIITrajectoryRemaining == 0 { endlessIITrajectoryTotal = 0 }
    }

    /// Starts or extends the Landing Marker - in paddle hits, not seconds, like the rest
    /// of the paddle-facing power-ups after the turn-based revision.
    func endlessIICollectLandingMarker() {
        endlessIILandingRemaining = GameScene.endlessIIPaddlePowerUpTurns
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
        // Capped, so a pause or a background cannot hand the marker's easing a whole second
        // of movement in one frame.
        //
        // **Neither clock is measured in it any more** (round 218's workbook): the Ball
        // Trajectory and the Landing Marker both count paddle hits now, spent in
        // `endlessIISpendTrajectoryTurn` and `endlessIISpendLandingTurn`. The delta is still
        // what the marker's smoothing moves by, which is a frame's worth of easing rather
        // than a power-up's worth of time

        guard endlessIITrajectoryRemaining > 0 || endlessIILandingRemaining > 0 else {
            endlessIIClearVision()
            return
        }

        let bricks = endlessIIVisionBricks()
        let portals = endlessIIVisionPortals()
        let bounds = endlessIIVisionBounds()
        var lineIndex = 0
        var markerIndex = 0

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil else { continue }
            let velocity = subject.physicsBody?.velocity ?? .zero
            guard velocity.dx != 0 || velocity.dy != 0 else { continue }
            // A held or waiting ball has no path yet. Its line would be a dot

            let reach = GameScene.endlessIITrajectoryReach[endlessIITrajectoryLevel]*ballSize/2
            let passesThrough = subject.texture == gigaBallTexture
                || subject.texture == gigaBallNormal
            // A Giga-Ball goes *through* bricks, so a line that stops at the first one is
            // drawing a wall that is not there (play-test round 122). The prediction is only
            // honest if it knows what the ball can do - and the ball itself is where that is
            // written, since the texture is what the power-up changes
            let path = BallPath.predict(from: subject.position, velocity: velocity,
                                        radius: subject.size.width/2, bounds: bounds,
                                        bricks: passesThrough ? [] : bricks,
                                        maximumLength: endlessIITrajectoryRemaining > 0 ? reach : 0,
                                        brickBounces: endlessIITrajectoryRemaining > 0
                                            ? GameScene.endlessIITrajectoryBrickBounces : 0,
                                        absorbers: passesThrough ? [] : portals)

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
                    var travelled: CGFloat = 0
                    for (from, to) in zip(points, points.dropFirst()) {
                        travelled += hypot(to.x - from.x, to.y - from.y)
                    }
                    let afterBounce = max(ballSize*5, reach - travelled)
                    points.append(CGPoint(x: landing.x + cos(angle)*afterBounce,
                                          y: landing.y + sin(angle)*afterBounce))
                    // The bounce the paddle would give from where it stands now, drawn by
                    // the same rule paddleHit applies - the line keeps going off the paddle
                    // so the player can aim the shot after the catch, not just the catch.
                    //
                    // **As long as the line has left to run** (James, round 308: the line
                    // "stops short when the ball is heading towards/bouncing off the paddle").
                    // It was a flat five ball-widths however much reach the power-up had, so a
                    // ball falling straight at the paddle drew a long line to it and a stub off
                    // it - which reads as the prediction giving up exactly where the player is
                    // about to need it. The whole line is `reach` long wherever it goes now,
                    // with the five-ball floor kept for a ball that arrives having already
                    // spent it
                }
                lineIndex = endlessIIDrawFadingTrajectory(points, from: lineIndex)
            }
            if endlessIILandingRemaining > 0, let landing = path.landing {
                let marker = endlessIIVisionMarker(at: markerIndex)
                let mark = CGPoint(x: endlessIISettledLandingX(landing.x, for: marker,
                                                               delta: delta),
                                   y: paddle.position.y + paddleHeight*1.2)
                marker.position = endlessIILandingMarkerCentre(over: mark)
                markerIndex += 1
                // The *triangle* goes on the mark, not the picture: the picture is mostly
                // glow and its shape sits a little below the middle of it
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
                        paddleLine: paddleTopY,
                        sidesWrap: endlessIIWrapIsRunning)
    }
    // The paddle's *top*, not its centre: contact is the ball's bottom against the top
    // surface, which is how `catchStickyBallBeforeStep` already judges it (the predictor
    // adds the ball's radius itself). Handed the centre, the prediction ran half a paddle
    // too far before calling it a landing, and the extra vertical travel bought a sideways
    // error that grew as the approach flattened - play-test round 97's "as if it's
    // expecting the ball to travel a little further before it contacts the paddle",
    // which was the diagnosis stated as a sighting

    /// Every brick the line should stop at, as rectangles.
    ///
    /// `frame` rather than position-and-size, because a Big or power-up brick's node is not
    /// at its sprite's centre - the frame is what the ball actually meets. Flashing bricks
    /// that are currently passable are left in: the ball may pass, but so may it not by the
    /// time it arrives, and a line through a brick that turns solid is the worse lie.
    /// The portals, which a predicted line **ends at** rather than bounces off.
    ///
    /// A Portal is not a wall (play-test round 128): the ball does not come back off one, it
    /// goes in. Nor is it a hole - a line drawn straight through would promise a flight the
    /// ball will not take. And where it comes *out* cannot be predicted honestly either: a
    /// pair chooses its exit at the moment of entry. So the line ends at the mouth, which is
    /// the only one of the three that is true.
    func endlessIIVisionPortals() -> [CGRect] {
        var portals: [CGRect] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard node.isHidden == false,
                  (node as? SKSpriteNode)?.endlessIIRole == .portal else { return }
            portals.append(node.frame)
        }
        return portals
    }

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
    ///
    /// **A sprite rather than a shape node** (round 258). Forty-six of these are laid every
    /// frame per ball, and an `SKShapeNode` re-tessellates when it is handed a path and is
    /// rendered through an offscreen pass when it glows. They all wear one texture now, so
    /// SpriteKit draws the whole line in a single batch. `FadingLine` says the rest.
    private func endlessIIVisionLine(at index: Int) -> (glow: SKSpriteNode, core: SKSpriteNode) {
        while endlessIITrajectoryLines.count <= index*2 + 1 {
            let glowing = endlessIITrajectoryLines.count % 2 == 0
            let line = FadingLine.segment(glow: glowing)
            addChild(line)
            endlessIITrajectoryLines.append(line)
            // Under the balls and power-ups, over the background and bricks - and faint,
            // because four of these must not shout over the field they are explaining
        }
        return (endlessIITrajectoryLines[index*2], endlessIITrajectoryLines[index*2 + 1])
        // **Two nodes to a segment** (round 260): a wide coloured glow and a narrow white core
        // over it - James: "a blurry white with a giga-ball yellow/green glow". Kept in one
        // pool, alternating, so the trim below still counts nodes and cannot lose one of a pair
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
                let certainty = FadingLine.certainty(along: along, sharpness: sharpness)

                let segment = endlessIIVisionLine(at: index)
                index += 1

                let core = FadingLine.coreThickness(certainty: certainty)
                let blur = FadingLine.blurWidth(certainty: certainty)
                // **Wider and blurrier with distance than round 258 drew it** (James, round
                // 260: "make the line more blurry and wider the further it gets from the
                // ball"). Both numbers were tuned when the blur was an `SKShapeNode`'s glow,
                // which spread further for the same figure than a stretched picture does.
                //
                // **Less extreme since round 308** (James: "ball trajectory is now too wide
                // over its length - make the widening less extreme - it also looks weird when
                // it overlaps itself"). The swell was 1.5 to 5.0, more than three times over,
                // and it is now 1.5 to 3.1 with the blur eased to match. The two complaints are
                // one thing: a wide translucent line crossing its own path composites twice
                // where it overlaps, so the fatter the far end the more obvious the crossing.
                //
                // Narrowing reduces that rather than curing it - the cure is drawing the whole
                // polyline into a single node so an overlap composites once, which is a round
                // of its own and is queued rather than smuggled in here

                FadingLine.lay(segment.core, from: head, to: tail,
                               thickness: core, blur: blur,
                               alpha: FadingLine.coreAlpha(certainty: certainty))
                FadingLine.lay(segment.glow, from: head, to: tail,
                               thickness: core, blur: blur + core*1.6,
                               alpha: FadingLine.glowAlpha(certainty: certainty))
                // **Half of what it was** (James, round 299: "make the ball trajectory line
                // more transparent, maybe half of what it is now"). Both the core and the glow
                // are halved rather than only the core, and the floors with them: the line is
                // one thing made of two, and fading one of them changes what it *is* - a core
                // at half strength over a glow at full is a soft band with a hole in it
                // The glow is the same line drawn wider and fainter underneath. It reaches
                // past the core by a share of the core's own width, so it opens out as the
                // line widens rather than staying a fixed halo around a growing stroke
                // The blur grows as the confidence falls, which is the same statement made
                // twice - a line you can barely see and can barely locate. Round 85 said
                // the first cut of this was not fuzzy enough: the width stayed fixed, so
                // the far end was a thin crisp core with a faint halo rather than a blur.
                // Now the stroke itself swells as the certainty falls - a wide faint line
                // is what the eye reads as fuzz - and the blur grows on a square, so it
                // arrives mostly over the far half, where the guessing is.
                //
                // The three numbers are exactly the ones the shape node was given (round
                // 258); what changed is that the blur is now the picture's own soft edge
                // being stretched rather than an offscreen glow pass per segment
            }
            travelled += length
        }
        return index
    }

    /// How much of the gap to a freshly predicted landing the marker closes in a sixtieth of
    /// a second.
    ///
    /// Low enough to swallow the shimmer, high enough that the marker is still telling the
    /// truth about where the ball is going rather than about where it was going.
    static let endlessIILandingFollowPerSixtieth: CGFloat = 0.18

    /// Beyond this, the prediction has genuinely changed course and the marker jumps.
    ///
    /// A ball's landing point moves for two quite different reasons, and they want opposite
    /// treatment. Frame to frame it wanders by a fraction of a point, because the prediction is
    /// re-walked from a position that has moved a little - that is the shimmer. When the ball
    /// actually bounces, or a brick in its way is destroyed, the landing moves by a large
    /// distance all at once, and easing across the field would draw a marker sliding to a place
    /// the ball is not going yet. One cell is comfortably above the first and far below the
    /// second.
    var endlessIILandingSnapDistance: CGFloat { max(brickWidth, ballSize*2) }

    /// The marker's x, eased rather than snapped.
    ///
    /// James, round 209: "landing marker icon can look a bit jittery as the ball's landing
    /// position slightly adjusts. Can we make this movement smoother or have a moving average
    /// position so it doesn't update so frequently by such small amounts."
    ///
    /// A moving average would lag by however long the window is; easing toward the prediction
    /// costs the same smoothing without a fixed delay, and settles rather than trailing. Time
    /// based, not per frame, so it behaves the same at 60 and 120 - the mistake Ball Steering
    /// made and the same round found.
    ///
    /// A marker being placed for the first time has nowhere to ease from, so it is put where
    /// it belongs: easing from a node's birth position drags it in from the middle of the
    /// scene, which is a much worse jitter than the one being fixed.
    func endlessIISettledLandingX(_ wanted: CGFloat, for marker: SKNode,
                                  delta: TimeInterval) -> CGFloat {
        guard let placed = marker.userData?["placed"] as? Bool, placed, delta > 0 else {
            if marker.userData == nil { marker.userData = NSMutableDictionary() }
            marker.userData?["placed"] = true
            return wanted
        }
        guard abs(wanted - marker.position.x) < endlessIILandingSnapDistance else {
            return wanted
        }
        let share = 1 - pow(1 - GameScene.endlessIILandingFollowPerSixtieth,
                            CGFloat(delta)*60)
        return marker.position.x + (wanted - marker.position.x)*share
    }

    /// The landing marker for the nth ball, made when first needed.
    ///
    /// **The drawn triangle goes exactly where the drawn-by-hand one was** (James, round 243:
    /// "make sure the actual triangle is put in the same place as the existing one, with the
    /// glow effect surrounding it"), which takes a little arithmetic because the artwork is
    /// mostly glow. The picture is 146 x 132 points and the triangle inside it is 55.3 x 37,
    /// centred across and a hair below centre down - so the sprite has to be about two and a
    /// half times the size of the shape a player actually reads, and nudged so the triangle
    /// rather than the picture lands on the mark.
    ///
    /// The old path was `ballSize*0.7` across the shoulders by the same down to the point,
    /// with its apex at -0.6 and its shoulders at +0.4 of that - so its box sat a tenth of the
    /// size *below* the node. Both of those are what is matched here.
    private func endlessIIVisionMarker(at index: Int) -> SKSpriteNode {
        while endlessIILandingMarkers.count <= index {
            let marker = SKSpriteNode(texture: GameScene.endlessIILandingMarkerTexture)
            marker.zPosition = 5
            marker.alpha = 0.9
            addChild(marker)
            endlessIILandingMarkers.append(marker)
            // Pointing down, and above the backstop's layer - it lives above the paddle.
            // Play-testing preferred it to the ghost ball, which crowded the paddle itself
        }
        let marker = endlessIILandingMarkers[index]
        marker.size = endlessIILandingMarkerSize
        return marker
    }

    /// How big the whole picture has to be for its triangle to be the size the old one was.
    ///
    /// Followed rather than set once, because the ball can change size under it and the marker
    /// has always been drawn to the ball.
    var endlessIILandingMarkerSize: CGSize {
        let triangleWidth = ballSize*0.7*1.1*GameScene.endlessIILandingMarkerScale
        // The old path's shoulders: `size*0.55` either side of the middle, where size is
        // `ballSize*0.7`
        let width = triangleWidth/GameScene.endlessIILandingTriangleShare
        return CGSize(width: width, height: width*(132/146))
        // The picture's own proportions. Scaled on one axis only, so the triangle inside it
        // stays the shape it was drawn as rather than being squared up to the old one - the
        // old one was a hand-written path and this is a drawing, and stretching a drawing to
        // match a path is the wrong way round
    }

    /// How much bigger than the old drawn triangle the marker is.
    ///
    /// James, round 259: "make the landing marker bigger." Applied to the *triangle*, which is
    /// what a player sees as the marker - the picture around it is mostly glow, and scaling the
    /// picture would have grown the halo faster than the mark inside it.
    ///
    /// A half again. Enough to answer the report at a glance, and short of the point where the
    /// mark starts covering the paddle it is pointing at.
    static let endlessIILandingMarkerScale: CGFloat = 1.5

    /// How wide the triangle is as a share of the whole picture: 55.3 points of 146, measured
    /// off the file rather than guessed, so a redraw that moves it is one number to change.
    static let endlessIILandingTriangleShare: CGFloat = 55.3/146

    /// Where the triangle's middle sits inside the picture, as a share of its height measured
    /// from the middle: 51.3% from the top, so a touch below centre.
    static let endlessIILandingTriangleDrop: CGFloat = 0.513 - 0.5

    /// Loaded once. Nil draws nothing, which is a marker that has quietly stopped marking - the
    /// same bargain the aura makes, and the reason there is a test that the artwork is present.
    static let endlessIILandingMarkerTexture: SKTexture? =
        UIImage(named: "LandingMarker").map { SKTexture(image: $0) }

    /// Where the sprite's centre goes, so that the *triangle's* centre lands on `point`.
    ///
    /// Two offsets, both small and both real: the old triangle's box sat a tenth of its size
    /// below the node it hung from, and the new one sits a little below the middle of its own
    /// picture. Getting either backwards moves the mark by a couple of points, which is exactly
    /// the amount nobody notices and the marker is then wrong about where the ball will be.
    func endlessIILandingMarkerCentre(over point: CGPoint) -> CGPoint {
        let size = endlessIILandingMarkerSize
        let oldBoxCentre = -ballSize*0.7*0.1
        return CGPoint(x: point.x,
                       y: point.y + oldBoxCentre
                           + GameScene.endlessIILandingTriangleDrop*size.height)
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
        while endlessIITrajectoryLines.count > lines*2 {
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
                texture: PowerUpIcon.ringTexture(named: "TrajectoryIcon"),
                remaining: CGFloat(endlessIITrajectoryRemaining/endlessIITrajectoryTotal),
                segments: Int(endlessIITrajectoryTotal)))
        }
        if endlessIILandingRemaining > 0, endlessIILandingTotal > 0 {
            entries.append(PowerUpRingHUD.Entry(
                id: "endlessIILanding",
                texture: PowerUpIcon.ringTexture(named: "LandingMarkerIcon"),
                remaining: CGFloat(endlessIILandingRemaining/endlessIILandingTotal),
                segments: Int(endlessIILandingTotal)))
            // **Segmented, because it counts paddle hits** (James, round 215: "the progress
            // bar on the HUD icon acted as segmented on a paddle hit, which is right, but
            // there were no dividing lines between the segments").
            //
            // It was passing nil, which draws one continuous arc - and an arc fed a fraction
            // that only moves in steps looks segmented without being segmented, which is
            // precisely what he saw. The trajectory above is marked the same way from round
            // 218, where it stopped running on time and started counting hits too.
        }
        return entries
    }
}
