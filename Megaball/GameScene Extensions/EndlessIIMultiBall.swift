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
    /// Called by Multi-Ball. Every ball gets its own contact handling - its own wall bounces,
    /// paddle angles, brick corrections and portal jumps - so an extra one plays exactly as the
    /// first does.
    ///
    /// Returns whether one was actually added, so a power-up with nothing to do can say so
    /// rather than being collected for nothing. In practice it always has something to do: the
    /// drop weight goes to zero while four are in play, so it stops being offered rather than
    /// being collected for nothing (§5.4).
    @discardableResult
    func endlessIIAddBall() -> Bool {
        guard endlessIICanAddBall else { return false }

        let parent = ball
        let currentSpeed = hypot(parent.physicsBody?.velocity.dx ?? 0,
                                 parent.physicsBody?.velocity.dy ?? 0)
        let heading = EndlessIIBalls.paddleLaunchVelocity(
            speed: currentSpeed > 0 ? currentSpeed : ballSpeedLimit,
            offset: Double.random(in: -1...1))

        let extra = SKSpriteNode(texture: parent.texture)
        extra.size = parent.size
        extra.zPosition = parent.zPosition
        extra.name = BallCategoryName
        extra.position = CGPoint(x: paddle.position.x, y: ballStartingPositionY)
        addChild(extra)
        // Out of the paddle, near vertical, like a launch - which is what it is. Appearing
        // beside the ball it came from read as a glitch in the middle of the field

        extra.physicsBody = endlessIIBallBody(radius: ballSize/2)
        extra.physicsBody?.velocity = heading
        endlessIIExtraBalls.append(extra)
        ballPhysicsBodySet()
        // A ball added while Giga-Ball is running is a Giga-Ball too. Its body is built plain
        // above, and this is what puts whatever the run is currently wearing onto it

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
        let body = SKPhysicsBody(circleOfRadius: max(radius, 0.5))
        // Never zero. A body of no size traps, and this is reached during a resume at launch,
        // where anything that has not been laid out yet is still reporting nothing
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

        if lost !== ball, lost.parent == nil || endlessIIExtraBalls.contains(where: { $0 === lost }) == false {
            return true
        }
        // Already dealt with. Several balls reach the bottom within a frame or two of each
        // other, and a ball that has been retired can still have a contact reported against
        // it - counting that as another loss spent balls that were never in play

        guard EndlessIIBalls.losing(oneOf: endlessIIBallsInPlay.count) == .carryOn else {
            // The last one. Whichever node it was, the primary ball is the one the rest of
            // the game will reset, so anything still lying around goes with it
            endlessIIClearExtraBalls()
            return false
        }

        if lost === ball {
            // The one the rest of the game holds. It cannot simply be removed, so a survivor
            // hands over where it is and how it is travelling, and steps out of the way
            guard let survivor = endlessIIExtraBalls
                .filter({ $0.parent != nil })
                .max(by: { $0.position.y < $1.position.y }) else {
                return false
            }
            // The highest one, rather than the first added. When two balls reach the bottom
            // together the other one is also about to be lost, and handing the first ball its
            // position put it on the floor - a ball that arrived already falling out of play

            endlessIIPendingHandover = survivor
            // Not now. This is running inside a contact, and a position or velocity written
            // there is undone by the rest of the step (§8.6) - so the handover was being
            // thrown away while the survivor was removed anyway, which left one ball gone and
            // the other still falling out of play under the paddle. It is applied from
            // `didSimulatePhysics`, the one place a body can be written to and have it stick
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

    /// Hands the first ball a survivor's place on the field, after the step has resolved.
    ///
    /// Called from `didSimulatePhysics`. The survivor is only taken off once the ball it is
    /// handing over to has actually taken over - losing both is how a run ends with no ball
    /// on the field at all.
    func applyEndlessIIBallHandover() {
        guard let survivor = endlessIIPendingHandover else { return }
        endlessIIPendingHandover = nil
        guard survivor.parent != nil else { return }

        ball.position = survivor.position
        ball.physicsBody?.velocity = survivor.physicsBody?.velocity ?? .zero
        ball.isHidden = false
        ball.alpha = 1
        retire(survivor)
    }

    private func retire(_ extra: SKSpriteNode) {
        endlessIIExtraBalls.removeAll { $0 === extra }
        endlessIIExtraBounceCounters[ObjectIdentifier(extra)] = nil
        endlessIIReleasedFromPaddle(extra)
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
        pauseExtraBallVelocities.removeAll()
        endlessIIExtraBounceCounters.removeAll()
        endlessIIClearHeldBalls()
        // Nothing left for the paddle to be holding
        // Or the next set of balls would be handed the last set's headings on the first pause
    }

    // MARK: - Pausing

    /// Records every extra ball's heading, unless it has been recorded already.
    ///
    /// Pausing zeroes the velocities on the field, so this has to happen first. It runs on
    /// both sides of the pause menu - going in, and again on the way out while the countdown
    /// holds the field still - and the second run must not overwrite the first with the zeroes
    /// the first one caused.
    func endlessIIRecordExtraBallVelocities() {
        guard gameMode == .endlessII else { return }
        let inPlay = endlessIIExtraBalls.filter { $0.parent != nil }
        guard inPlay.isEmpty == false else { return }
        guard pauseExtraBallVelocities.count != inPlay.count else { return }

        pauseExtraBallVelocities = inPlay.map { $0.physicsBody?.velocity ?? .zero }
    }

    /// Shows which way each extra ball is about to go, while the countdown runs.
    ///
    /// The scene owns one direction marker, for the one ball it was built around. These are
    /// made as they are needed and taken away with it - a marker on the first ball alone tells
    /// a player being counted back in about a quarter of what is on the field.
    func endlessIIShowExtraDirectionMarkers() {
        guard gameMode == .endlessII else { return }
        endlessIIHideExtraDirectionMarkers()

        for (index, extra) in endlessIIExtraBalls.enumerated() where extra.parent != nil {
            let heading = pauseExtraBallVelocities.indices.contains(index)
                ? pauseExtraBallVelocities[index]
                : extra.physicsBody?.velocity ?? .zero
            guard heading.dx != 0 || heading.dy != 0 else { continue }

            let marker = SKSpriteNode(texture: directionMarker.texture)
            marker.size = CGSize(width: extra.size.width*3.5, height: extra.size.height*3.5)
            marker.position = extra.position
            marker.zRotation = atan2(heading.dy, heading.dx)
            marker.zPosition = directionMarker.zPosition
            addChild(marker)
            endlessIIExtraDirectionMarkers.append(marker)
        }
    }

    func endlessIIHideExtraDirectionMarkers() {
        endlessIIExtraDirectionMarkers.forEach { $0.removeFromParent() }
        endlessIIExtraDirectionMarkers.removeAll()
    }

    // MARK: - Saving

    /// Every extra ball as a save holds it.
    ///
    /// Read at the moment of saving, so it is where the balls actually are rather than where
    /// they were when the pause menu opened.
    var endlessIISavedExtraBalls: [EndlessIIBalls.Saved] {
        endlessIIExtraBalls.filter { $0.parent != nil }.map {
            EndlessIIBalls.Saved(position: $0.position,
                                 velocity: $0.physicsBody?.velocity ?? .zero)
        }
    }

    /// Puts the extra balls back where a save left them.
    ///
    /// The velocities go into `pauseExtraBallVelocities` rather than straight onto the bodies,
    /// because a resumed game is a paused game: the countdown runs first, and every ball gets
    /// its velocity at the moment play actually starts. Setting them here would have four balls
    /// moving behind the countdown.
    func endlessIIRestoreExtraBalls(from saved: [EndlessIIBalls.Saved]) {
        guard gameMode == .endlessII else { return }
        endlessIIClearExtraBalls()
        pauseExtraBallVelocities = []

        for entry in saved {
            let extra = SKSpriteNode(texture: ball.texture)
            extra.size = ball.size
            extra.zPosition = ball.zPosition
            extra.name = BallCategoryName
            extra.position = entry.position
            addChild(extra)

            extra.physicsBody = endlessIIBallBody(radius: ballSize/2)
            extra.physicsBody?.velocity = .zero
            endlessIIExtraBalls.append(extra)
            pauseExtraBallVelocities.append(entry.velocity)

            if entry.velocity.dx == 0 && entry.velocity.dy == 0 {
                endlessIICatchExtraBall(extra)
            }
            // A ball with no heading was not travelling when the game was saved, which means
            // the sticky paddle was holding it. Put back as an ordinary ball it would sit
            // there for ever with nothing able to launch it, because the queue that launches
            // held balls would be empty
        }
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
            extra.setScale(ball.xScale)
            // The scale as well as the size: Expand Ball scales the node rather than resizing
            // it, and a physics body scales with its node - so an extra that copied only the
            // size was drawn and felt smaller than the ball beside it
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
