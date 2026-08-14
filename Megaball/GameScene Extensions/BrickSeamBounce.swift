//
//  BrickSeamBounce.swift
//  Megaball
//
//  Making a row of bricks bounce like a row of bricks.
//
//  Every brick is its own rectangle with its own physics body, and where two of them sit side
//  by side there is a seam. A ball arriving exactly on that seam touches both in the same step,
//  and the physics engine resolves it against two bodies at once - so instead of the flat face
//  the player can see, it bounces off what is geometrically a corner, and leaves at an angle
//  that has nothing to do with the surface it hit.
//
//  It is worst on bricks that survive the hit. A single-hit brick disappears and takes the
//  evidence with it; a Multi-hit or Indestructible pair stays there, so the same shot goes
//  wrong the same way and the field looks like it is lying about its own shape.
//
//  The fix is to answer the question the player is asking rather than the one the engine is:
//  when a ball strikes more than one brick in a single step, those bricks are treated as one
//  surface and the ball is reflected about that surface's face. Nothing else changes - the
//  speed is the speed it arrived with, and the existing angle rules run afterwards exactly as
//  they do on any other bounce, so a flat reflection that came out too shallow is still opened
//  up the way the game has always opened it up.
//
//  Deliberately only for two or more. A single brick struck near its corner is a real corner,
//  and the ball should behave like it hit one.
//

import SpriteKit

extension GameScene {

    /// Remembers where every ball was and how it was travelling before this step resolved.
    ///
    /// Called from `update`, which runs before the physics. By the time a contact is reported
    /// the engine has already begun resolving it, so the velocity read there is not the one the
    /// ball arrived with - and the arrival is the only thing that says which face was hit.
    func recordBallStatesBeforeStep() {
        ballStateBeforeStep.removeAll(keepingCapacity: true)
        for subject in endlessIIBallsInPlay {
            guard let body = subject.physicsBody else { continue }
            ballStateBeforeStep[ObjectIdentifier(subject)] =
                BallState(position: subject.position, velocity: body.velocity)
        }
    }

    /// Notes that a ball touched a brick during this step.
    ///
    /// The brick's frame is copied rather than the node kept, because most of the bricks this
    /// is called for are about to be destroyed by the very hit being recorded.
    func noteBrickStrike(ball subject: SKSpriteNode, brick: SKSpriteNode) {
        brickSeamStrikes[ObjectIdentifier(subject), default: []].append(brick.frame)
    }

    /// Turns a bounce off two bricks into a bounce off the face they share.
    ///
    /// Runs from `didSimulatePhysics` - the first moment after the step, and the only place a
    /// body can be written to and have it stick.
    func resolveBrickSeamBounces() {
        defer { brickSeamStrikes.removeAll(keepingCapacity: true) }
        guard gameState.currentState is Playing else { return }

        for subject in endlessIIBallsInPlay {
            let key = ObjectIdentifier(subject)
            guard let struck = brickSeamStrikes[key], struck.count > 1 else { continue }
            guard let before = ballStateBeforeStep[key], let body = subject.physicsBody else {
                continue
            }
            guard subject.texture != gigaBallTexture else { continue }
            // A Giga-Ball passes through bricks rather than bouncing off them, so there is no
            // bounce here to put right

            let surface = struck.dropFirst().reduce(struck[0]) { $0.union($1) }
            guard let face = seamFace(from: before, over: surface) else { continue }

            let flat: CGVector
            switch face {
            case .top, .bottom:
                flat = CGVector(dx: before.velocity.dx, dy: -before.velocity.dy)
            case .left, .right:
                flat = CGVector(dx: -before.velocity.dx, dy: before.velocity.dy)
            }
            if subject === ball { crookedBallNote("seam-bounce") }
            body.velocity = flat

            // The ordinary rules, run on the corrected bounce rather than instead of it. A
            // flat reflection can still come out too near horizontal, and that is a separate
            // problem the game already solves
            let angle = Double(atan2(flat.dy, flat.dx))/Double.pi*180
            ballHorizontalControl(angleDegInput: angle, for: subject)
            ballVerticalControl(for: subject)
        }
    }

    /// Which face of the combined surface the ball came in through.
    ///
    /// Decided from where the ball was before the step and which way it was going, not from
    /// where it ended up - the engine has already pushed it out of the bricks by now, and out
    /// of a corner it pushes diagonally, which is the very thing being corrected.
    ///
    /// Returns nil when the answer is not clear enough to act on, in which case the engine's
    /// own resolution stands.
    func seamFace(from before: BallState, over surface: CGRect) -> EndlessIISide? {
        let dx = before.velocity.dx
        let dy = before.velocity.dy
        guard dx != 0 || dy != 0 else { return nil }

        let outsideVertically = before.position.y > surface.maxY || before.position.y < surface.minY
        let outsideHorizontally = before.position.x > surface.maxX || before.position.x < surface.minX

        // A row of bricks is wider than it is tall, and a ball arriving from above or below is
        // the common case by a long way. Where the ball was clearly outside on one axis only,
        // that axis is the answer
        if outsideVertically && !outsideHorizontally {
            return before.position.y > surface.midY ? .top : .bottom
        }
        if outsideHorizontally && !outsideVertically {
            return before.position.x > surface.midX ? .right : .left
        }

        // Off a corner of the whole surface, where the ball was outside on both axes. Work out
        // when it reached each axis's edge; the face it came in through is the one it reached
        // *last*, because until then it was still level with the surface on that axis but not
        // yet over it on the other.
        //
        // The later of the two, not the earlier - which is the opposite of what it looks like
        // it should be. Crossing the line a face sits on is not the same as arriving at the
        // face: a ball can pass the height of a row of bricks while still well to the side of
        // it, and only meet the row when it later reaches the end.
        let overshootX = before.position.x > surface.midX
            ? before.position.x - surface.maxX
            : surface.minX - before.position.x
        let overshootY = before.position.y > surface.midY
            ? before.position.y - surface.maxY
            : surface.minY - before.position.y

        let timeX = dx == 0 ? CGFloat.infinity : abs(overshootX/dx)
        let timeY = dy == 0 ? CGFloat.infinity : abs(overshootY/dy)
        guard timeX.isFinite || timeY.isFinite else { return nil }

        if timeX > timeY {
            return before.position.x > surface.midX ? .right : .left
        }
        return before.position.y > surface.midY ? .top : .bottom
    }
}

/// Where a ball was and how it was travelling before a physics step.
struct BallState {
    let position: CGPoint
    let velocity: CGVector
}
