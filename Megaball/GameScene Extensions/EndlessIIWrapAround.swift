//
//  EndlessIIWrapAround.swift
//  Megaball
//
//  Wrap-Around: the side walls stop being walls.
//
//  The last of phase 8c, and deliberately the last thing built in phase 8: it changes the
//  shape of the field rather than one rule about the ball (§5.4). While the clock runs, a
//  ball leaving one side re-enters the other with the velocity it left with; the paddle
//  driven off one edge reappears at the other; a Moving brick with a clear run to a wall
//  carries on from the far one; and an explosion against a wall reaches round it.
//
//  None of it touches the wall physics. The walls stay exactly where they are - the ball
//  still contacts them, and the contact is answered with a teleport instead of a bounce,
//  deferred to didSimulatePhysics like every other position written during contact
//  resolution (§8.6). The corners stop being the safe places they usually are, which is the
//  whole point.
//

import SpriteKit

extension GameScene {

    func endlessIICollectWrapAround() {
        endlessIIWrapAroundClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
    }

    var endlessIIWrapIsRunning: Bool {
        gameMode == .endlessII && endlessIIWrapAroundClock.isRunning
    }

    // MARK: - The ball

    /// Notes that a ball has hit a side wall it should pass through. Returns whether it did,
    /// so the caller skips the bounce it would otherwise be correcting.
    func endlessIIWrapTook(_ subject: SKSpriteNode) -> Bool {
        guard endlessIIWrapIsRunning else { return false }
        endlessIIPendingWraps.append(subject)
        return true
    }

    /// Carries every wrapped ball to the far side, from `didSimulatePhysics`.
    ///
    /// The velocity is the pre-step sample: the engine has already bounced the ball off the
    /// wall by the time the contact is reported (§8.6), and a wrapped ball keeps the heading
    /// it *left* with - that is what makes the two sides one surface.
    func applyEndlessIIWraps() {
        guard endlessIIPendingWraps.isEmpty == false else { return }
        let wraps = endlessIIPendingWraps
        endlessIIPendingWraps.removeAll()

        for subject in wraps {
            guard subject.parent != nil, let body = subject.physicsBody else { continue }
            let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
                ?? body.velocity

            if subject === ball { crookedBallNote("wrap") }
            let radius = subject.size.width/2
            let inside = gameWidth/2 - radius - 1
            subject.position.x = subject.position.x > 0 ? -inside : inside
            body.velocity = arriving
            // Out one side, in the other, still travelling the same way
        }
    }

    // MARK: - The paddle

    /// Where the paddle ends up after a move, given that the walls may not be walls.
    ///
    /// Ordinarily the paddle clamps at the walls; while the wrap runs, a centre pushed past
    /// an edge comes back in from the other one. Written as a pure position rule so the
    /// touch handler stays one line either way.
    func endlessIIWrapPaddleX(_ x: CGFloat) -> CGFloat {
        let limit = gameWidth/2 - paddle.size.width/2
        guard endlessIIWrapIsRunning else {
            return max(-limit, min(limit, x))
        }
        if x > gameWidth/2 { return x - gameWidth }
        if x < -gameWidth/2 { return x + gameWidth }
        return x
        // Free to overhang the edge, and wrapped once the centre crosses it - "driven off
        // one edge, reappears at the other" (§5.4)
    }

    /// The x of the paddle copy nearest this ball: the paddle itself, or - while the wrap
    /// runs and the paddle straddles an edge - its ghost on the other side. `paddleHit`
    /// measures every landing against this, so a bounce off the ghost's half bends the
    /// angle by where the ball really sat on it, not by a paddle a screen away.
    func endlessIIPaddleXNearest(to x: CGFloat) -> CGFloat {
        let real = paddle.position.x
        guard endlessIIWrapIsRunning, abs(x - real) > gameWidth/2 else { return real }
        return real + (x > real ? gameWidth : -gameWidth)
    }

    /// Keeps the ghost half in step: while the paddle overhangs an edge, a second paddle
    /// sprite shows the overhang re-entering the far side, with a body of its own so the
    /// re-entering half bounces balls - "a paddle half off one side should appear half on
    /// the other, and its physics body has to follow" (§12.0). Dressed like the paddle
    /// every frame, because the paddle's dress changes under the power-up batch.
    func tickEndlessIIWrapGhost() {
        let limit = gameWidth/2 - paddle.size.width/2
        let overhangs = endlessIIWrapIsRunning && abs(paddle.position.x) > limit
        guard overhangs else {
            endlessIIWrapGhostPaddle?.removeFromParent()
            endlessIIWrapGhostPaddle = nil
            return
        }

        let ghost = endlessIIWrapGhostPaddle ?? {
            let node = SKSpriteNode(texture: paddle.texture, size: paddle.size)
            node.zPosition = paddle.zPosition
            node.name = PaddleCategoryName
            addChild(node)
            endlessIIWrapGhostPaddle = node
            return node
        }()

        if ghost.size != paddle.size || ghost.physicsBody == nil {
            ghost.size = paddle.size
            let body = SKPhysicsBody(rectangleOf: paddle.size)
            body.allowsRotation = false
            body.friction = 0
            body.affectedByGravity = false
            body.isDynamic = false
            body.restitution = 1
            body.usesPreciseCollisionDetection = true
            body.categoryBitMask = CollisionTypes.paddleCategory.rawValue
            body.collisionBitMask = CollisionTypes.paddleCategory.rawValue
            ghost.physicsBody = body
            // Remade only when the size changes (paddle size power-ups) - a rectangle,
            // because the ghost exists for its edges, not its silhouette
        }

        ghost.texture = paddle.texture
        ghost.color = paddle.color
        ghost.colorBlendFactor = paddle.colorBlendFactor
        ghost.position = CGPoint(
            x: paddle.position.x > 0 ? paddle.position.x - gameWidth
                                     : paddle.position.x + gameWidth,
            y: paddle.position.y)
    }

    // MARK: - The field

    /// Where a wandering brick that has reached a wall carries on from.
    ///
    /// Only when its run to the wall was clear: a brick blocked mid-field bounces off the
    /// blocker exactly as before, because wrapping it beside another brick would put it
    /// inside the field's own furniture. Returns nil when the wrap does not apply.
    func endlessIIWrapWandererX(at x: CGFloat, limits: (left: CGFloat, right: CGFloat),
                                halfWidth: CGFloat) -> CGFloat? {
        guard endlessIIWrapIsRunning else { return nil }
        let wallLeft = -gameWidth/2 + halfWidth
        let wallRight = gameWidth/2 - halfWidth

        if x >= limits.right, limits.right >= wallRight - 0.5, limits.left <= wallLeft + 0.5 {
            return wallLeft
        }
        if x <= limits.left, limits.left <= wallLeft + 0.5, limits.right >= wallRight - 0.5 {
            return wallRight
        }
        return nil
    }

    /// The blast reach, wrapped: an explosion against one wall also reaches in from the
    /// other. Both copies are checked by the explosion, so nothing else changes.
    func endlessIIWrappedBlastCopies(of reach: CGRect) -> [CGRect] {
        guard endlessIIWrapIsRunning else { return [reach] }
        return [reach,
                reach.offsetBy(dx: -gameWidth, dy: 0),
                reach.offsetBy(dx: gameWidth, dy: 0)]
    }

    // MARK: - Each frame

    /// Runs the clock, dresses the walls, and keeps everything honest when it ends.
    func tickEndlessIIWrapAround() {
        guard gameMode == .endlessII else { return }
        if gameState.currentState is Playing && isPaused == false {
            endlessIIWrapAroundClock.run(down: endlessIIClockDelta)
        }

        tickEndlessIIWrapGhost()

        let running = endlessIIWrapIsRunning
        if running, endlessIIWrapDressed == false {
            sideScreenBlockLeft.color = GameScene.portalBlueColour
            sideScreenBlockRight.color = GameScene.portalYellowColour
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.colorBlendFactor = 0.6
            }
            // Blue left, yellow right (§12.0's note): the walls are the two ends of one
            // portal pair, so they wear the pair's two colours
            paddle.physicsBody?.collisionBitMask &= ~CollisionTypes.boarderCategory.rawValue
            // The paddle's body is dynamic and collides with the frame's edge, so every
            // overhang the touch wrote was resolved straight back by the engine - the balls
            // wrapped and the paddle never could. While the walls are not walls, the paddle
            // stops colliding with them
            endlessIIWrapDressed = true
            // The walls wear the exit yellow while they are exits - the same language the
            // portals already speak
        } else if running == false, endlessIIWrapDressed {
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.colorBlendFactor = 0
            }
            paddle.physicsBody?.collisionBitMask |= CollisionTypes.boarderCategory.rawValue
            endlessIIWrapDressed = false

            let limit = gameWidth/2 - paddle.size.width/2
            if abs(paddle.position.x) > limit {
                paddle.position.x = max(-limit, min(limit, paddle.position.x))
            }
            // A paddle overhanging an edge when the walls come back is pushed back inside
            // them - left there, it would be half stuck outside a wall that is solid again
        }
    }

    func endlessIIResetWrapAround() {
        endlessIIWrapAroundClock.reset()
        endlessIIPendingWraps.removeAll()
        endlessIIWrapGhostPaddle?.removeFromParent()
        endlessIIWrapGhostPaddle = nil
        if endlessIIWrapDressed {
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.colorBlendFactor = 0
            }
            paddle.physicsBody?.collisionBitMask |= CollisionTypes.boarderCategory.rawValue
            endlessIIWrapDressed = false
        }
    }
}
