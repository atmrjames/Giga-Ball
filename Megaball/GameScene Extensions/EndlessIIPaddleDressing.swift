//
//  EndlessIIPaddleDressing.swift
//  Megaball
//
//  What the paddle batch looks like while it runs.
//
//  Play-testing asked for the mechanics to be visible on the field rather than only in the
//  ring: a Portal Paddle should look like a portal (paddle blue, exit strip yellow along the
//  top - the same pair the portal bricks wear), a magnet should look like a magnet and show
//  its pull, and a steered ball should be visibly connected to the paddle steering it. The
//  same yellow exit strip also marks the top whenever exactly one Portal brick is in play,
//  because a single portal's exit *is* the top, and nothing said so.
//
//  All of it is drawn per frame from the clocks and the field - nothing here is state that
//  can be forgotten, which is what keeps a tinted paddle from staying tinted after the
//  power-up that tinted it has gone.
//

import SpriteKit

extension GameScene {

    /// Keeps the paddle's dress and the field's connective tissue in step with the clocks.
    /// Called from the paddle batch's tick, every frame, Endless 2.0 only.
    func tickEndlessIIPaddleDressing() {
        dressEndlessIIPaddle()
        refreshEndlessIIPaddleGlow()
        refreshEndlessIIRetroPortalArt()
        showEndlessIITopExitStrip()
        drawEndlessIIPullLines()

        let stickyUnderInert = stickyPaddleCatches != 0
            && endlessIIInertPaddleClock.isRunning
        for sticky in [paddleSticky, paddleRetroStickyTexture] {
            sticky.color = .gray
            sticky.colorBlendFactor = stickyUnderInert ? 0.85 : 0
        }
        // The sticky wears monochrome while the paddle is inert (James's design): the
        // catch still works, but the launch is the wall's answer, and the greyed
        // graphic is how the pairing says so
    }

    // MARK: - The paddle's colour

    /// Tints the paddle for whichever paddle power-up is running.
    ///
    /// Portal blue wins over magnet red when both run at once - the portal changes where the
    /// ball *goes*, which is the more important thing to be reading. No power-up, no tint.
    /// Swaps the retro paddle's picture for its Portal one, and back, as the clock starts and
    /// stops.
    ///
    /// **On the change and not every frame**, which is §8.6's own note about building textures:
    /// the retro dressing is otherwise refreshed when the *shape* changes, and a Portal Paddle
    /// collected without a shape power-up running changes no shape at all - so without this the
    /// swap would wait for an unrelated event, or never happen.
    ///
    /// `SKTexture(imageNamed:)` is cheap and cached, but assigning three of them sixty times a
    /// second is the shape of thing round 291 measured as the stutter, so the flag earns its
    /// place.
    func refreshEndlessIIRetroPortalArt() {
        guard paddleTexture == retroPaddle else { return }
        let running = endlessIIPortalPaddleClock.isRunning
        guard running != endlessIIRetroWearsPortalArt else { return }

        endlessIIRetroWearsPortalArt = running
        refreshEndlessIIRetroShapeDressing(
            endlessIIPaddleSurface.flatMap { endlessIIPaddleShapeSuffix($0) })
    }

    /// The glow that sits behind the paddle while a Portal Paddle runs.
    static let paddleGlowName = "endlessIIPaddleGlow"

    /// **One halo per paddle shape, and none per theme** (James, round 315: "new paddle glow
    /// graphics - same idea as the portal bricks, the glow graphic should sit centred behind
    /// the paddle during the portal power-up. There is a glow for each paddle shape").
    ///
    /// Per shape and not per theme is his sentence and it is also the right design: a glow is
    /// a soft halo of one colour, and a candy paddle and an ice one cast the same one.
    ///
    /// **The plain paddle's is called `squarePaddleGlow`**, which does not match the other
    /// five. They are `regularPaddle<Shape>Glow`; the unshaped one is named for what it looks
    /// like - a square-ended bar - rather than for the set it belongs to, and `squarePaddle`
    /// is separately the name of a paddle *theme*. Both plain paddles are 225x30, so the
    /// picture fits either reading and the file is right whichever was meant. Asked for by
    /// both names rather than renamed, so that if a square-themed glow is ever drawn this does
    /// not quietly take its place.
    func endlessIIPaddleGlowTexture() -> SKTexture? {
        endlessIIPaddleGlowArt().map { SKTexture(imageNamed: $0.glow) }
    }

    /// The glow picture for the paddle's current shape, and the paddle picture it was drawn
    /// against.
    ///
    /// The pair travels together because the difference between the two is the halo's margin -
    /// see `endlessIIPaddleGlowMargin`. Nil for a shape with no glow drawn, which is Jagged, the one
    /// shape with no paddle picture either: no halo rather than the plain one sitting wrong.
    func endlessIIPaddleGlowArt() -> (paddle: String, glow: String)? {
        let shape = endlessIIPaddleSurface.flatMap { endlessIIPaddleShapeSuffix($0) }
        let pairs = shape.map { [("regularPaddle\($0)", "regularPaddle\($0)Glow")] }
            ?? [("regularPaddle", "regularPaddleGlow"), ("squarePaddle", "squarePaddleGlow")]

        for (paddle, glow) in pairs
        where UIImage(named: paddle) != nil && UIImage(named: glow) != nil {
            return (paddle, glow)
        }
        return nil
    }

    /// **How much bigger the paddle's glow is than the paddle, as a margin** - not as a ratio.
    ///
    /// James, round 320: "on expanding/shrinking, scale the glows to keep them 40 points
    /// larger", and from the same list: "paddle portal glow should remain 20 points larger than
    /// paddle when paddle is longer and shorter". The two numbers are the same instruction a
    /// delivery apart, which is the argument for reading it off the artwork rather than typing
    /// it: the glows were drawn 20 points bigger and are now drawn 40, and this follows.
    ///
    /// **A ratio was wrong here, and right for the bricks.** A brick is scaled to its cell, so
    /// a glow at the same scale keeps the halo in proportion to the brick, which is what "at
    /// the same scale" means there. A paddle is not scaled to anything: Expand and Shrink move
    /// its width directly, so a ratio gives a doubled paddle a doubled halo - a thin rim at
    /// one width and a thick one at another, when the whole point is that it looks like the
    /// same light around the same paddle.
    ///
    /// Asked per shape because a shaped paddle's picture is taller than the plain one while
    /// its glow grows by the same absolute amount, so the margin is the one thing they share.
    func endlessIIPaddleGlowMargin() -> CGSize {
        guard let art = endlessIIPaddleGlowArt() else { return .zero }
        let paddle = SKTexture(imageNamed: art.paddle).size()
        let glow = SKTexture(imageNamed: art.glow).size()
        guard paddle.width > 0, paddle.height > 0 else { return .zero }
        return CGSize(width: glow.width - paddle.width, height: glow.height - paddle.height)
    }

    /// Puts it behind the paddle while the Portal Paddle runs, and takes it away after.
    ///
    /// **Sized from the paddle's own current size**, which is the one number that moves: the
    /// paddle grows with Expand, shrinks with Shrink and stands taller wearing a shape, and a
    /// halo that did not follow would be a halo that fits at one width only.
    ///
    /// No physics body, like the bricks' - a child sprite has none unless given one, and a
    /// glow the ball could bounce off would be a paddle bigger than it looks.
    func refreshEndlessIIPaddleGlow() {
        let existing = paddle.childNode(withName: GameScene.paddleGlowName) as? SKSpriteNode
        guard endlessIIPortalPaddleClock.isRunning,
              let texture = endlessIIPaddleGlowTexture()
        else { existing?.removeFromParent(); return }

        let glow = existing ?? {
            let made = SKSpriteNode()
            made.name = GameScene.paddleGlowName
            made.zPosition = -0.1
            paddle.addChild(made)
            return made
        }()

        let margin = endlessIIPaddleGlowMargin()
        let stretch = max(abs(paddle.xScale), 0.01)
        glow.texture = texture
        glow.size = CGSize(width: paddle.size.width + margin.width/stretch,
                           height: paddle.size.height + margin.height)
        // **Divided by the paddle's scale, because the glow is the paddle's child** (James,
        // round 327: "paddle glow is expanding and shrinking too far. It should stay 40 points
        // bigger than the paddle, not expand at the same rate"). Round 320 made the margin an
        // absolute 40 points rather than a ratio, and it was right until Expand and Shrink
        // stopped writing `paddle.size` and started animating `xScale` instead (round 321's
        // fix for a paddle caught mid-resize). A child's size is in the parent's coordinates,
        // so a doubled paddle drew the margin at double as well - a ratio again by the back
        // door, from the one direction the round 320 note did not cover. Dividing puts 40
        // points on the screen at every width. Only the width: `scaleX` is the only one
        // Expand and Shrink touch, and the height is already in screen points
        glow.position = .zero
        // Centred on the paddle node, which is where the paddle's own picture is drawn - and
        // a split paddle keeps its full span (round 313s), so one halo across the whole of it
        // is right rather than one per piece
    }

    private func dressEndlessIIPaddle() {
        let tint: UIColor? = nil
        // **Nothing tints the paddle any more** (James, round 327b: "for the magnetism graphic,
        // there's no need to colour the paddle - show magnetism lines flowing towards the
        // paddle from the ball, like it is being attracted to the paddle"). Round 316 took the
        // Portal Paddle's tint away on the same reasoning - the effect is the thing to draw,
        // not the paddle - and Magnetism was the last one left wearing one. What says a magnet
        // is running is the pull itself, drawn below: dashes travelling up the line from the
        // ball to the paddle, which is the direction the force acts in.
        //
        // The variable stays rather than the branches below losing their parameter: a shaped
        // paddle, a split paddle and a mirror all paint through here, and the next power-up
        // that wants a colour should find one place to say so
        // **The Portal Paddle is no longer tinted** (James, round 316: "I don't think the
        // paddles require a tint any more. The glow effect is enough").
        //
        // It wore `portalBlueColour` from the round it was built, and round 315's artwork is
        // what made that wrong rather than merely unnecessary: the Portal identity moved to
        // the Giga-Ball lime - the bricks, the brick glows, the paddle glow and the retro
        // paddle's own variant are all lime now - so the blue was the one thing left saying a
        // different colour, and a lime halo around a blue paddle read as two power-ups.
        //
        // Magnetism keeps its tint, and is now the only thing here that has one. It has no
        // glow drawn for it, and red is the whole of how a magnet paddle says so.

        let halves = paddle.children.filter { $0.name == GameScene.doublePaddleHalfName }
        guard halves.isEmpty else {
            paint(halves.compactMap { $0 as? SKSpriteNode }, tint)
            if paddle.colorBlendFactor != 1 || paddle.color != .clear {
                paddle.color = .clear
                paddle.colorBlendFactor = 1
            }
            return
        }
        // **The pieces wear the tint, and the span underneath them stays invisible** (James,
        // round 313: with a split paddle and a Portal Paddle together, "blue portal texture
        // between the sections of the paddle").
        //
        // A split paddle stops drawing itself - `refreshEndlessIIDoublePaddle` ends with
        // `texture = nil`, `color = .clear` - and what the player sees is its two children.
        // The node keeps its full span, because the bounce measures where the ball landed
        // across the whole of it. This function then ran on the next frame and painted that
        // span portal blue at 0.75, and a textureless sprite with a colour draws a solid
        // rectangle: the halves covered the ends of it and the gap between them did not.
        //
        // So the gap was not a portal texture at all. It was the paddle itself, showing
        // through the hole it is supposed to have.

        paint([paddle], tint)
    }

    /// Puts a power-up's colour on whatever is currently standing for the paddle.
    private func paint(_ nodes: [SKSpriteNode], _ tint: UIColor?) {
        for node in nodes {
            guard let tint else {
                if node.colorBlendFactor != 0 { node.colorBlendFactor = 0 }
                continue
            }
            node.color = tint
            node.colorBlendFactor = 0.75
        }
    }

    /// The classic magnet red.
    static let endlessIIMagnetColour = UIColor(red: 0.95, green: 0.35, blue: 0.3, alpha: 1)

    // MARK: - The exit at the top

    /// The yellow strip along the top of the play area, shown while the top is somewhere a
    /// ball can come out of: a Portal Paddle is running, or exactly one Portal brick is in
    /// play (whose exit is the top, §4.11).
    private func showEndlessIITopExitStrip() {
        let portals = gameMode == .endlessII ? endlessIIPortals().count : 0
        let wanted = (endlessIIPortalPaddleClock.isRunning && portals == 0)
            || (endlessIIPortalPaddleClock.isRunning == false && portals == 1)
        // The strip marks the top as an exit, and the top is only the exit while nothing
        // better is: a Portal Paddle with bricks in play exits at the bricks, and a pair of
        // bricks exit at each other

        showEndlessIIEdgeGlow(.top, wanted: wanted)
        // **A glow rather than a bar** (James, round 242's delivery). It was five points of
        // flat colour at 0.8 alpha, which says "there is a line here" where the thing being
        // said is "the field opens out this way".
        //
        // **The strip no longer wears the portal's colour.** It used to take the far colour of
        // whatever pair was in play - a blue brick's exit is yellow - and the artwork cannot
        // carry that without being flattened into one hue (see `showEndlessIIEdgeGlow`). The
        // coding is the thing given up for the effect, and it is worth saying that it *was* a
        // decision rather than an oversight: a player with a blue brick on screen can no longer
        // read which end the top is. Two drawn variants would give both back
    }

    // MARK: - The pull

    /// Faint lines from the paddle to whatever it is acting on: falling balls being pulled
    /// while Magnetism runs, and every steered ball while Ball Steering does.
    ///
    /// The line is the effect made visible - "show some effect of the ball being drawn to
    /// the paddle" - and it fades in as the pull gets stronger, so the strength near the
    /// paddle can be *seen* rising.
    private func drawEndlessIIPullLines() {
        var wanted: [(ball: SKSpriteNode, colour: UIColor, strength: CGFloat, flowing: Bool)] = []

        if endlessIIMagnetismClock.isRunning {
            for subject in endlessIIBallsInPlay where subject.parent != nil {
                guard subject.physicsBody?.velocity.dy ?? 0 < 0 else { continue }
                let gap = subject.position.y - paddle.position.y
                guard gap > 0 else { continue }
                let proximity = max(0, 1 - gap/EndlessIIPaddleEffects.magnetismReach)
                guard proximity > 0.05 else { continue }
                wanted.append((subject, GameScene.endlessIIMagnetColour, proximity, true))
            }
        }

        if endlessIIBallSteeringClock.isRunning {
            for subject in endlessIIBallsInPlay where subject.parent != nil {
                guard subject !== ball || ballIsOnPaddle == false else { continue }
                guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { continue }
                wanted.append((subject, GameScene.endlessIIHaloColour, 0.5, false))
                // Ball Steering keeps its solid line: the player is aiming that one, and a line
                // that flows toward the paddle would say the paddle is doing the work
            }
        }

        while endlessIIPullLines.count < wanted.count {
            let line = SKShapeNode()
            line.lineWidth = 1.5
            line.zPosition = 3
            addChild(line)
            endlessIIPullLines.append(line)
        }
        while endlessIIPullLines.count > wanted.count {
            endlessIIPullLines.removeLast().removeFromParent()
        }

        endlessIIMagnetFlowPhase += CGFloat(frameDelta)*GameScene.endlessIIMagnetFlowSpeed
        let span = GameScene.endlessIIMagnetDash + GameScene.endlessIIMagnetGap
        if endlessIIMagnetFlowPhase > span { endlessIIMagnetFlowPhase -= span }
        // Wrapped rather than left to grow: the dashes repeat every `span` points, so the phase
        // only ever has to say where inside one repeat they are

        for (index, entry) in wanted.enumerated() {
            let line = endlessIIPullLines[index]
            let target = CGPoint(x: paddle.position.x, y: paddleTopY)
            line.path = entry.flowing
                ? endlessIIFlowingPath(from: entry.ball.position, to: target,
                                       phase: endlessIIMagnetFlowPhase)
                : {
                    let path = CGMutablePath()
                    path.move(to: entry.ball.position)
                    path.addLine(to: target)
                    return path
                }()
            line.strokeColor = entry.colour.withAlphaComponent(0.15 + entry.strength*0.45)
        }
    }

    /// The ball-to-paddle line as dashes that have travelled `phase` points toward the paddle.
    ///
    /// **Drawn from the ball's end** (James, round 327b: "show magnetism lines flowing towards
    /// the paddle from the ball, like it is being attracted to the paddle"). A solid line says
    /// the two are joined; dashes moving one way say which of them is pulling, and that is the
    /// whole of what a magnet has to communicate.
    ///
    /// The first dash starts one full span behind the ball so it arrives rather than appearing:
    /// clipped to the segment, what the player sees is a dash growing out of the ball, running
    /// down the line and disappearing into the paddle.
    func endlessIIFlowingPath(from start: CGPoint, to end: CGPoint, phase: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let dx = end.x - start.x, dy = end.y - start.y
        let length = hypot(dx, dy)
        guard length > 1 else { return path }
        let unit = CGPoint(x: dx/length, y: dy/length)
        let span = GameScene.endlessIIMagnetDash + GameScene.endlessIIMagnetGap

        var travelled = phase.truncatingRemainder(dividingBy: span) - span
        while travelled < length {
            let from = max(0, travelled)
            let to = min(length, travelled + GameScene.endlessIIMagnetDash)
            if to > from {
                path.move(to: CGPoint(x: start.x + unit.x*from, y: start.y + unit.y*from))
                path.addLine(to: CGPoint(x: start.x + unit.x*to, y: start.y + unit.y*to))
            }
            travelled += span
        }
        return path
    }

    /// How long each dash is, how far apart they sit, and how fast they run, in points.
    ///
    /// Short dashes with a gap of their own size read as movement at a glance; a longer dash
    /// reads as a dashed line that happens to be shifting. The speed is a little quicker than a
    /// falling ball, so the pull looks like it is drawing the ball in rather than keeping up
    /// with it.
    static let endlessIIMagnetDash: CGFloat = 9
    static let endlessIIMagnetGap: CGFloat = 9
    static let endlessIIMagnetFlowSpeed: CGFloat = 220
}
