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
        let shape = endlessIIPaddleSurface.flatMap { endlessIIPaddleShapeSuffix($0) }
        let names = shape.map { ["regularPaddle\($0)Glow"] }
            ?? ["regularPaddleGlow", "squarePaddleGlow"]

        for name in names where UIImage(named: name) != nil {
            return SKTexture(imageNamed: name)
        }
        return nil
        // A shape with no glow drawn - Jagged, which has no paddle picture either - answers
        // nil and wears no halo, rather than borrowing the plain one and sitting wrong
    }

    /// How far the paddle's glow reaches past it, in points.
    ///
    /// Measured off the pair rather than typed, exactly as `portalGlowMargin` is: James drew
    /// every glow in this delivery twenty points wider and taller than the thing it belongs
    /// to, bricks and paddles alike.
    static let paddleGlowMargin: CGSize = {
        guard UIImage(named: "squarePaddle") != nil,
              UIImage(named: "squarePaddleGlow") != nil else { return .zero }
        let paddle = SKTexture(imageNamed: "squarePaddle").size()
        let glow = SKTexture(imageNamed: "squarePaddleGlow").size()
        return CGSize(width: max(0, glow.width - paddle.width),
                      height: max(0, glow.height - paddle.height))
    }()

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

        glow.texture = texture
        glow.size = CGSize(width: paddle.size.width + GameScene.paddleGlowMargin.width,
                           height: paddle.size.height + GameScene.paddleGlowMargin.height)
        glow.position = .zero
        // Centred on the paddle node, which is where the paddle's own picture is drawn - and
        // a split paddle keeps its full span (round 313s), so one halo across the whole of it
        // is right rather than one per piece
    }

    private func dressEndlessIIPaddle() {
        let tint: UIColor?
        if endlessIIPortalPaddleClock.isRunning {
            tint = GameScene.portalBlueColour
        } else if endlessIIMagnetismClock.isRunning {
            tint = GameScene.endlessIIMagnetColour
        } else {
            tint = nil
        }

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
        var wanted: [(ball: SKSpriteNode, colour: UIColor, strength: CGFloat)] = []

        if endlessIIMagnetismClock.isRunning {
            for subject in endlessIIBallsInPlay where subject.parent != nil {
                guard subject.physicsBody?.velocity.dy ?? 0 < 0 else { continue }
                let gap = subject.position.y - paddle.position.y
                guard gap > 0 else { continue }
                let proximity = max(0, 1 - gap/EndlessIIPaddleEffects.magnetismReach)
                guard proximity > 0.05 else { continue }
                wanted.append((subject, GameScene.endlessIIMagnetColour, proximity))
            }
        }

        if endlessIIBallSteeringClock.isRunning {
            for subject in endlessIIBallsInPlay where subject.parent != nil {
                guard subject !== ball || ballIsOnPaddle == false else { continue }
                guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { continue }
                wanted.append((subject, GameScene.endlessIIHaloColour, 0.5))
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

        for (index, entry) in wanted.enumerated() {
            let line = endlessIIPullLines[index]
            let path = CGMutablePath()
            path.move(to: entry.ball.position)
            path.addLine(to: CGPoint(x: paddle.position.x, y: paddleTopY))
            line.path = path
            line.strokeColor = entry.colour.withAlphaComponent(0.15 + entry.strength*0.45)
        }
    }
}
