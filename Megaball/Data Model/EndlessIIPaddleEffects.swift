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
    ///
    /// **Why both of these read as weaker than they are** (play-test rounds 39 and 46, which
    /// reported them separately as "does nothing" and "not doing much"). The whole term is
    /// `angleAdjustmentK * collisionPercentage * influence`, and `collisionPercentage` is how
    /// far off-centre the ball landed. Near the middle of the paddle it is close to zero, so
    /// the term is close to zero *whatever this returns* - and most catches are near the
    /// middle. Neither power-up is broken; both are invisible exactly when the player is
    /// playing safe, which is most of the time.
    ///
    /// Flipped answers that by over-correcting rather than merely inverting: at 1.8 a
    /// deliberate steer comes back close to twice as hard the other way, which is unmistakable
    /// the first time it happens and still proportional to how much you asked for.
    static let flippedInfluence: Double = -1.8

    static func angleInfluence(inert: Bool, flipped: Bool) -> Double {
        if inert { return 0 }
        if flipped { return flippedInfluence }
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

        let boost = 1 + EndlessIIPaddleEffects.magnetismCloseBoost*falloff
        let cap = EndlessIIPaddleEffects.magnetismTurnRate*boost*CGFloat(delta)
        // The cap opens up as the ball closes in: high in the field the pull is a lean, and
        // near the paddle it is very hard to miss - which is the request, in as many words
        let step = max(-cap, min(cap, turn*(strength + strength*falloff)))
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
    /// How many times stronger the turn cap is at the paddle than at the reach's edge.
    static let magnetismCloseBoost: CGFloat = 4
    /// The pull at each stacking level - collected again while running, it strengthens.
    static let magnetismStrength: [CGFloat] = [0.9, 1.6]

    // MARK: - Ball Steering

    /// Where a steered ball is pulled to: the paddle's own column, approached rather than
    /// snapped to, and never past a wall.
    ///
    /// Rebuilt in play-test round 15. It used to add a share of the paddle's *movement* to
    /// the ball, which meant a stationary paddle steered nothing and the ball kept whatever
    /// sideways trajectory it already had - "horrid", and rightly: the power-up said the
    /// paddle steers the ball and the ball was still mostly steering itself. Now the paddle
    /// owns the ball's column outright. The ball is drawn toward wherever the paddle is,
    /// closing a fixed fraction of the gap each frame, which is what gives the movement
    /// weight rather than making the ball a cursor.
    static func steeredTowards(paddleX: CGFloat, from x: CGFloat,
                               leftWall: CGFloat, rightWall: CGFloat,
                               radius: CGFloat) -> CGFloat {
        let wanted = x + (paddleX - x)*steeringFollow
        return max(leftWall + radius, min(rightWall - radius, wanted))
    }

    /// How much of the gap to the paddle a steered ball closes each frame.
    ///
    /// The inertia, in one number. High enough that the ball answers the paddle at once,
    /// low enough that it arrives rather than teleports - and low enough that a bounce off
    /// a brick visibly throws it off course before it is gathered back in.
    static let steeringFollow: CGFloat = 0.16

    /// How much of a steered ball's sideways speed survives each frame.
    ///
    /// The other half of "the ball should forget its original trajectory": bleeding the
    /// horizontal velocity away stops the physics engine arguing with the steering every
    /// frame, which is what would otherwise make a steered ball jitter. What is taken out
    /// sideways is put back vertically by `steeredVelocity`, so the ball keeps its pace -
    /// a steered ball is not a slower ball.
    static let steeringVelocityDamping: CGFloat = 0.82

    /// A steered ball's velocity after this frame's damping: less sideways, the same speed.
    static func steeredVelocity(_ velocity: CGVector) -> CGVector {
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        guard speed > 0 else { return velocity }
        let dx = velocity.dx*steeringVelocityDamping
        let upward: CGFloat = velocity.dy >= 0 ? 1 : -1
        let dy = upward*max(0, speed*speed - dx*dx).squareRoot()
        return CGVector(dx: dx, dy: dy)
    }

    // MARK: - Paddle Halo

    /// How far the halo reaches from the paddle's centre, by stacking level, as a multiple
    /// of the paddle's width. Raised again in round 11: at [1.9, 2.6] it only touched the
    /// bottom row of a low field, and the request is the bottom *two*.
    static let haloReach: [CGFloat] = [2.3, 3.0]
    // Raised twice by play-testing: from [0.9, 1.3] when the glow never reached a brick,
    // and from [1.5, 2.1] when it still fell short of the field ("it didn't reach the
    // bottom line of bricks - it should reach at least the bottom 2 rows"). The paddle
    // gap is seven layout units and the paddle five, so 1.9 widths is nine and a half
    // units from the centre - the bottom two rows, with the ball's approach to spare

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

    /// The launch angle a finger has chosen, in radians.
    ///
    /// Absolute, not accumulated (play-test round 10: "the arrow direction should adjust
    /// based on the absolute position of the user's finger - more left on the screen =
    /// further left"). The finger's x as a fraction of the half-width maps straight onto
    /// the usable arc: the left wall is the leftmost aim, the centre is straight up, the
    /// right wall the rightmost. An absolute aim cannot drift from the thumb the way an
    /// accumulated drag could. The default angle - the bounce the ball would have taken -
    /// still applies until the finger first moves, so releasing without dragging changes
    /// nothing (§5.4).
    static func aimedAngle(fingerFraction: Double, straight: Double,
                           maximum: Double) -> Double {
        let clamped = max(-1.0, min(1.0, fingerFraction))
        return straight - clamped*maximum
    }

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

    /// The angle that sends a ball from here to there, clamped to the launchable arc.
    ///
    /// Auto-Aim's whole rule. Nil when the target is not above the ball - a paddle cannot
    /// aim downward, and pretending it could would fire the ball into the floor.
    static func autoAimAngle(from ball: CGPoint, to target: CGPoint,
                             minimumDeg: Double) -> Double? {
        let dy = target.y - ball.y
        guard dy > 0 else { return nil }
        var angleDeg = atan2(Double(dy), Double(target.x - ball.x))*180/Double.pi
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
