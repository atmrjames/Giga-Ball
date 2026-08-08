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
        showEndlessIITopExitStrip()
        drawEndlessIIPullLines()
    }

    // MARK: - The paddle's colour

    /// Tints the paddle for whichever paddle power-up is running.
    ///
    /// Portal blue wins over magnet red when both run at once - the portal changes where the
    /// ball *goes*, which is the more important thing to be reading. No power-up, no tint.
    private func dressEndlessIIPaddle() {
        if endlessIIPortalPaddleClock.isRunning {
            paddle.color = GameScene.portalBlueColour
            paddle.colorBlendFactor = 0.75
        } else if endlessIIMagnetismClock.isRunning {
            paddle.color = GameScene.endlessIIMagnetColour
            paddle.colorBlendFactor = 0.75
        } else if paddle.colorBlendFactor != 0 {
            paddle.colorBlendFactor = 0
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

        guard wanted else {
            endlessIITopExitStrip?.removeFromParent()
            endlessIITopExitStrip = nil
            return
        }

        let single = gameMode == .endlessII ? endlessIIPortals().first : nil
        let colour = single?.endlessIIPortalIsBlue == true
            ? GameScene.portalYellowColour
            : (single != nil ? GameScene.portalBlueColour : GameScene.portalYellowColour)
        // The strip is the other end of whatever portal is in play, so it wears the other
        // colour of the pair - a blue brick's exit is yellow, a yellow brick's is blue.
        // The Portal Paddle alone keeps the yellow exit it has always had

        let strip = endlessIITopExitStrip ?? {
            let node = SKSpriteNode(color: colour,
                                    size: CGSize(width: gameWidth, height: 5))
            node.position = CGPoint(x: 0, y: frame.height/2 - topScreenBlock.size.height - 2.5)
            node.zPosition = 4
            node.alpha = 0
            addChild(node)
            node.run(.fadeAlpha(to: 0.8, duration: 0.2))
            endlessIITopExitStrip = node
            return node
        }()
        strip.color = colour
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
            path.addLine(to: CGPoint(x: paddle.position.x,
                                     y: paddle.position.y + paddleHeight/2))
            line.path = path
            line.strokeColor = entry.colour.withAlphaComponent(0.15 + entry.strength*0.45)
        }
    }
}
