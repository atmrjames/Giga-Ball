//
//  EndlessIIPaddleEffects.swift
//  Megaball
//
//  The arithmetic of the paddle batch, separately from the paddle.
//
//  Phase 8b's power-ups all change what the paddle does - how it angles a bounce, which way
//  it moves, what it pulls toward itself. The *rules* live here as pure functions so they can
//  be tested without a scene, and so what each power-up actually is can be read in one
//  screen rather than found spread through the contact handler.
//

import CoreGraphics
import Foundation

enum EndlessIIPaddleEffects {

    // MARK: - The bounce angle

    /// What multiplies the paddle's angular influence on a bounce.
    ///
    /// The paddle has always bent the bounce by where the ball lands on it. Inert Paddle
    /// takes that influence away; Flipped Angle turns it round. Inert wins when both are
    /// running, because no influence is also no influence to invert - and a player suffering
    /// both at once has enough to think about without the tiebreak being interesting.
    static func angleInfluence(inert: Bool, flipped: Bool) -> Double {
        if inert { return 0 }
        if flipped { return -1 }
        return 1
    }

    // MARK: - Reversed Controls

    /// What multiplies the finger's movement before it reaches the paddle.
    static func controlDirection(reversed: Bool) -> CGFloat {
        reversed ? -1 : 1
    }

    // MARK: - Magnetism

    /// How much of the gap toward the paddle a falling ball closes this frame.
    ///
    /// Expressed as a horizontal velocity adjustment that preserves the ball's speed: the
    /// velocity is rotated toward the paddle rather than added to, because ball speed is a
    /// single shared value the whole game protects (§5.5) and a pull that changed it would
    /// quietly break that.
    ///
    /// Strength falls off with distance - near the paddle the pull is real, high in the
    /// field it is barely there - and only a *falling* ball is pulled. Curving a rising ball
    /// back toward the paddle would shorten every climb, which turns a beneficial power-up
    /// into a subtle penalty.
    static func magnetised(velocity: CGVector, ballAt ball: CGPoint, paddleAt paddle: CGPoint,
                           strength: CGFloat, delta: TimeInterval) -> CGVector {
        guard velocity.dy < 0 else { return velocity }
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        guard speed > 0 else { return velocity }

        let gap = ball.y - paddle.y
        guard gap > 0 else { return velocity }
        let falloff = max(0, 1 - gap/EndlessIIPaddleEffects.magnetismReach)
        guard falloff > 0 else { return velocity }

        let currentAngle = atan2(velocity.dy, velocity.dx)
        let towardPaddle = atan2(paddle.y - ball.y, paddle.x - ball.x)
        var turn = towardPaddle - currentAngle
        while turn > .pi { turn -= 2 * .pi }
        while turn < -.pi { turn += 2 * .pi }
        // The short way round, or a ball just past the paddle's centre line would swing
        // through half a circle to approach from the other side

        let step = max(-EndlessIIPaddleEffects.magnetismTurnRate*CGFloat(delta),
                       min(EndlessIIPaddleEffects.magnetismTurnRate*CGFloat(delta),
                           turn*strength*falloff))
        let angle = currentAngle + step
        return CGVector(dx: cos(angle)*speed, dy: sin(angle)*speed)
    }

    /// How far above the paddle the pull reaches at all.
    static let magnetismReach: CGFloat = 420
    /// The most the velocity may turn per second, whatever the numbers ask for.
    ///
    /// A cap rather than a tuning value: without it a strong pull on a near ball snaps the
    /// velocity onto the paddle in a frame, which reads as teleporting rather than curving.
    static let magnetismTurnRate: CGFloat = 2.4
    /// The pull at each stacking level - collected again while running, it strengthens.
    static let magnetismStrength: [CGFloat] = [0.9, 1.6]

    // MARK: - Ball Steering

    /// Where a steered ball ends up after the paddle moved.
    ///
    /// A fraction of the paddle's own movement, applied to the ball's position and clamped
    /// inside the walls - steering must never be able to push a ball through one.
    static func steered(x: CGFloat, paddleMovedBy delta: CGFloat,
                        leftWall: CGFloat, rightWall: CGFloat, radius: CGFloat) -> CGFloat {
        let moved = x + delta*EndlessIIPaddleEffects.steeringFactor
        return max(leftWall + radius, min(rightWall - radius, moved))
    }

    /// How much of the paddle's movement the ball inherits.
    ///
    /// Half. All of it makes the ball a puppet and aiming trivial; this much reads as
    /// influence - the ball leans the way the paddle goes.
    static let steeringFactor: CGFloat = 0.5

    // MARK: - Paddle Halo

    /// How far the halo reaches from the paddle's centre, by stacking level, as a multiple
    /// of the paddle's width.
    static let haloReach: [CGFloat] = [0.9, 1.3]

    /// Whether a brick is inside the halo.
    ///
    /// The semicircle above the paddle: within reach of its centre, and not below it. The
    /// nearest point of the brick's rectangle is what is measured, so a wide brick whose
    /// corner dips into the glow is touched by it - which is what "touches" means on screen.
    static func haloTouches(brick: CGRect, paddleAt paddle: CGPoint, reach: CGFloat) -> Bool {
        guard brick.maxY >= paddle.y else { return false }
        let nearestX = max(brick.minX, min(paddle.x, brick.maxX))
        let nearestY = max(brick.minY, min(paddle.y, brick.maxY))
        let dx = nearestX - paddle.x
        let dy = nearestY - paddle.y
        return dx*dx + dy*dy <= reach*reach
    }

    // MARK: - Aimed Sticky

    /// The launch angle a drag has chosen, in radians.
    ///
    /// The default is the angle the ball would have bounced at anyway (§5.4), so releasing
    /// without dragging changes nothing. Dragging swings it between the same limits every
    /// launch respects - an aim that could point along the paddle would be an aim into the
    /// wall beside it.
    static func aimedAngle(default defaultAngle: Double, draggedBy dx: CGFloat,
                           minimum: Double, maximum: Double) -> Double {
        let swing = Double(dx)*EndlessIIPaddleEffects.aimRadiansPerPoint
        return max(minimum, min(maximum, defaultAngle + swing))
    }

    /// How far a point of drag swings the aim.
    ///
    /// The whole usable arc is about two radians, so a comfortable thumb's travel - a couple
    /// of hundred points - sweeps all of it without a hand having to cross the screen.
    static let aimRadiansPerPoint: Double = 0.011

    /// The angle a ball leaves the paddle at, given where it lands and how it arrives.
    ///
    /// The same rule `paddleHit` applies: the reflection, bent by up to `adjustment` degrees
    /// by how far off-centre the landing is, and never allowed shallower than the minimum.
    /// Written here so the Trajectory Line can draw the same bounce the paddle will actually
    /// give - a predicted angle that differed from the real one would be worse than none.
    static func paddleBounceAngle(arriving velocity: CGVector, landingX: CGFloat,
                                  paddleX: CGFloat, paddleHalfWidth: CGFloat,
                                  adjustmentK: Double, minimumDeg: Double,
                                  influence: Double) -> Double {
        var angleDeg = defaultLaunchAngle(arriving: velocity)*180/Double.pi
        let offset = max(-1, min(1, Double((landingX - paddleX)/max(1, paddleHalfWidth))))
        angleDeg -= adjustmentK*offset*influence
        angleDeg = max(minimumDeg, min(180 - minimumDeg, angleDeg))
        return angleDeg*Double.pi/180
    }

    /// The bounce a ball arriving with this velocity would have taken off a flat paddle.
    ///
    /// Only the reflection, deliberately: the paddle's angular influence depends on where
    /// the ball would have landed *after* the player moved the paddle, which has not
    /// happened yet. The plain mirror is the honest default.
    static func defaultLaunchAngle(arriving velocity: CGVector) -> Double {
        guard velocity.dx != 0 || velocity.dy != 0 else { return .pi/2 }
        return atan2(Double(abs(velocity.dy)), Double(velocity.dx))
    }
}
