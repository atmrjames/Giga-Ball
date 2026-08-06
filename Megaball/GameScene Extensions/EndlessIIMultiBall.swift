//
//  EndlessIIMultiBall.swift
//  Megaball
//
//  More than one ball in play, in Endless 2.0 only.
//
//  The scene is built around a single `ball`, and around three hundred places read it. Almost
//  all of them are still right: there is always a ball, it is still the one the paddle catches
//  and the one every existing power-up acts on. What changes is that there may be others
//  beside it, and that losing one is no longer the end of the life.
//
//  So the extras live alongside the ball rather than replacing it. `ball` never changes
//  identity - when it is the one lost, an extra hands over its position and velocity and is
//  removed, so the ball the rest of the game holds carries on from where the survivor was.
//  Nothing else has to know that a swap happened, which is what keeps Classic and Endless
//  untouched by any of this.
//

import SpriteKit

extension GameScene {

    /// How far a new ball is placed from the one it came from.
    static var multiBallClearanceFactor: CGFloat { 1.6 }

    /// Every ball currently in play, the primary one first.
    var endlessIIBallsInPlay: [SKSpriteNode] {
        guard gameMode == .endlessII else { return [ball] }
        return [ball] + endlessIIExtraBalls.filter { $0.parent != nil }
    }

    /// Whether another ball may be added.
    var endlessIICanAddBall: Bool {
        gameMode == .endlessII
            && EndlessIIBalls.canAdd(inPlay: endlessIIBallsInPlay.count)
    }

    /// Adds a ball, turned away from the one it came from.
    ///
    /// This is what Multi-Ball will call. Every ball now gets its own contact handling - its
    /// own wall bounces, paddle angles, brick corrections and portal jumps - so an extra one
    /// plays exactly as the first does.
    ///
    /// What is still missing is the drop itself: the power-up weights and the per-power-up
    /// stats arrays are sized by the number of power-ups and decoded from disk, so adding one
    /// needs a migration that cannot get a player's existing progress wrong. Until that lands,
    /// nothing calls this.
    ///
    /// Returns whether one was actually added, so a power-up with nothing to do can say so
    /// rather than being collected for nothing.
    @discardableResult
    func endlessIIAddBall() -> Bool {
        guard endlessIICanAddBall else { return false }

        let parent = ball
        let index = endlessIIExtraBalls.count
        let heading = EndlessIIBalls.launchAngle(of: parent.physicsBody?.velocity ?? .zero,
                                                 index: index)

        let extra = SKSpriteNode(texture: parent.texture)
        extra.size = parent.size
        extra.zPosition = parent.zPosition
        extra.name = BallCategoryName
        extra.position = EndlessIIBalls.launchPosition(
            from: parent.position, heading: heading,
            clearance: ballSize*GameScene.multiBallClearanceFactor)
        addChild(extra)

        extra.physicsBody = endlessIIBallBody(radius: ballSize/2)
        extra.physicsBody?.velocity = heading
        endlessIIExtraBalls.append(extra)

        // Arriving out of the ball it came from, so the new one is seen to be new rather than
        // simply appearing in the field
        extra.setScale(0.2)
        extra.run(.scale(to: 1, duration: 0.15))

        if hapticsSetting { mediumHaptic.impactOccurred() }
        return true
    }

    /// A body set up exactly like the ball's.
    ///
    /// Built here rather than copied from the ball, because a physics body belongs to one node
    /// and cannot be shared - and because getting one of these masks wrong gives a ball that
    /// falls through the field rather than one that plays slightly differently.
    func endlessIIBallBody(radius: CGFloat) -> SKPhysicsBody {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.allowsRotation = false
        body.friction = 0.0
        body.affectedByGravity = false
        body.isDynamic = true
        body.mass = ball.physicsBody?.mass ?? 0.1
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = CollisionTypes.ballCategory.rawValue
        body.collisionBitMask = CollisionTypes.brickCategory.rawValue
            | CollisionTypes.paddleCategory.rawValue
            | CollisionTypes.screenBlockCategory.rawValue
            | CollisionTypes.boarderCategory.rawValue
            | CollisionTypes.backstopCategory.rawValue
        body.contactTestBitMask = CollisionTypes.brickCategory.rawValue
            | CollisionTypes.paddleCategory.rawValue
            | CollisionTypes.screenBlockCategory.rawValue
            | CollisionTypes.boarderCategory.rawValue
            | CollisionTypes.bottomScreenBlockCategory.rawValue
            | CollisionTypes.backstopCategory.rawValue
        return body
    }

    /// Deals with a ball reaching the bottom.
    ///
    /// Returns true when the run carries on, which is the caller's signal to stop - the life,
    /// the sound, the save and the reset are all for the last ball only.
    func endlessIIBallWasLost(_ lost: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII else { return false }
        guard EndlessIIBalls.losing(oneOf: endlessIIBallsInPlay.count) == .carryOn else {
            // The last one. Whichever node it was, the primary ball is the one the rest of
            // the game will reset, so anything still lying around goes with it
            endlessIIClearExtraBalls()
            return false
        }

        if lost === ball {
            // The one the rest of the game holds. It cannot simply be removed, so a survivor
            // hands over where it is and how it is travelling, and steps out of the way
            guard let survivor = endlessIIExtraBalls.first(where: { $0.parent != nil }) else {
                return false
            }
            ball.position = survivor.position
            ball.physicsBody?.velocity = survivor.physicsBody?.velocity ?? .zero
            retire(survivor)
        } else {
            retire(lost)
        }

        totalStatsArray[0].ballsLost += 1
        if hapticsSetting { softHaptic.impactOccurred() }
        if soundsSetting { self.run(ballLostSound) }
        // Counted and heard, because losing one of four is still losing one - it is only the
        // run that carries on
        return true
    }

    private func retire(_ extra: SKSpriteNode) {
        endlessIIExtraBalls.removeAll { $0 === extra }
        extra.physicsBody = nil
        extra.run(.sequence([.group([.scale(to: 0, duration: 0.1),
                                     .fadeOut(withDuration: 0.1)]),
                             .removeFromParent()]))
    }

    /// Takes every extra ball off the field. For starting, resetting and losing the life.
    func endlessIIClearExtraBalls() {
        for extra in endlessIIExtraBalls {
            extra.removeAllActions()
            extra.removeFromParent()
        }
        endlessIIExtraBalls.removeAll()
    }

    /// Keeps the extras in step with the ball each frame.
    ///
    /// Ball speed is one shared value across every ball in play (§5.5), so a speed power-up
    /// collected by any of them applies to all - which is also what stops the set drifting
    /// into a slow ball and three fast ones over a long run.
    func tickEndlessIIExtraBalls() {
        guard gameMode == .endlessII, endlessIIExtraBalls.isEmpty == false else { return }

        endlessIIExtraBalls.removeAll { $0.parent == nil }

        let wanted = hypot(ball.physicsBody?.velocity.dx ?? 0,
                           ball.physicsBody?.velocity.dy ?? 0)
        for extra in endlessIIExtraBalls {
            extra.texture = ball.texture
            extra.size = ball.size
            // The ball's own look and size are shared too: a Giga-Ball or an Expand Ball that
            // only applied to one of four would read as three balls that had gone wrong

            guard let body = extra.physicsBody, wanted > 0 else { continue }
            let speed = hypot(body.velocity.dx, body.velocity.dy)
            guard speed > 0.001, abs(speed - wanted) > 1 else { continue }
            body.velocity = CGVector(dx: body.velocity.dx/speed*wanted,
                                     dy: body.velocity.dy/speed*wanted)
        }
    }
}
