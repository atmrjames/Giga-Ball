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
            endlessIIWrapAroundClock.run(down: endlessIIPaddleFrameDelta)
        }

        let running = endlessIIWrapIsRunning
        if running, endlessIIWrapDressed == false {
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.color = GameScene.portalYellowColour
                wall.colorBlendFactor = 0.6
            }
            endlessIIWrapDressed = true
            // The walls wear the exit yellow while they are exits - the same language the
            // portals already speak
        } else if running == false, endlessIIWrapDressed {
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.colorBlendFactor = 0
            }
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
        if endlessIIWrapDressed {
            for wall in [sideScreenBlockLeft, sideScreenBlockRight] {
                wall.colorBlendFactor = 0
            }
            endlessIIWrapDressed = false
        }
    }
}
