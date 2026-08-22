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
    /// **The whole paddle is the magnet, not a point on it** (James, round 200: "the ball
    /// should be attracted to the whole length of the paddle, not just a single point...
    /// the inertia of the ball and power of paddle magnetism should determine where the
    /// ball hits"). The pull aims at the nearest point of the paddle's span to where the
    /// ball is currently heading - so a ball already falling onto the paddle gets no turn
    /// at all and lands wherever its own flight takes it, and a ball that would miss is
    /// bent just enough to make the edge. The old version aimed at a fixed spot a third
    /// out from centre, which actively steered every ball away from the middle - the
    /// "preventing the ball from hitting the centre" James saw - and made the landing the
    /// magnet's choice rather than the flight's.
    static func magnetised(velocity: CGVector, ballAt ball: CGPoint, paddleAt paddle: CGPoint,
                           paddleHalfWidth: CGFloat = 0,
                           strength: CGFloat, delta: TimeInterval) -> CGVector {
        guard velocity.dy < 0 else { return velocity }
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        guard speed > 0 else { return velocity }

        let gap = ball.y - paddle.y
        guard gap > 0 else { return velocity }
        let falloff = max(0, 1 - gap/EndlessIIPaddleEffects.magnetismReach)
        guard falloff > 0 else { return velocity }

        let landingX = ball.x + velocity.dx*(gap / -velocity.dy)
        // Where this flight lands at paddle height if nothing touches it - the ball's own
        // inertia, asked directly
        let margin = max(0, paddleHalfWidth - EndlessIIPaddleEffects.magnetismEdgeMargin)
        let targetX = min(max(landingX, paddle.x - margin), paddle.x + margin)
        // The nearest point of the span to where the ball is already going. Inside the span
        // the target *is* the landing, so the turn below is zero and inertia decides;
        // outside it the target is the nearer edge, inset a little so "hard to miss" does
        // not mean "caught by the last pixel"

        let currentAngle = atan2(velocity.dy, velocity.dx)
        let towardPaddle = atan2(paddle.y - ball.y, targetX - ball.x)
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

    /// How far inside the paddle's true edge the magnet aims a missing ball.
    static let magnetismEdgeMargin: CGFloat = 8

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
                               radius: CGFloat,
                               paddleSpeed: CGFloat = 0,
                               fieldWidth: CGFloat = 0,
                               delta: TimeInterval = 1.0/60) -> CGFloat {
        let gap = paddleX + steeringLead(paddleSpeed: paddleSpeed,
                                         fieldWidth: fieldWidth) - x
        let wanted = x + gap*steeringFollow(delta: delta)
        return max(leftWall + radius, min(rightWall - radius, wanted))
    }

    /// How far ahead of the paddle a steered ball is drawn while the paddle is moving.
    ///
    /// **This is what lets a steered ball reach the outermost columns** (James, round 184:
    /// "it's currently impossible/very difficult to get the ball to hit bricks in the columns
    /// closest to the walls as the ball wants to be always centred over the paddle. I think we
    /// should add some more inertia to the ball as it moves with the paddle").
    ///
    /// The diagnosis is exactly his: the ball was drawn to the paddle's *centre*, and a
    /// paddle's centre can never come closer to a wall than half its own width - so the outer
    /// half-paddle of every field was unreachable by construction, however well the player
    /// played. Leading the target by the paddle's own motion gives the ball the momentum he
    /// describes: sweep toward a wall and the ball runs ahead of the paddle and can arrive at
    /// the column beside it; hold still and the lead is nothing, so a parked paddle steers
    /// exactly as it did.
    ///
    /// Capped as a share of the field so a fast flick cannot throw the ball clean across it -
    /// the clamp in `steeredTowards` would catch that anyway, but a target that far out would
    /// pin the ball to the wall for as long as the flick lasted.
    static func steeringLead(paddleSpeed: CGFloat, fieldWidth: CGFloat) -> CGFloat {
        guard fieldWidth > 0 else { return 0 }
        let cap = fieldWidth*steeringLeadCap
        return max(-cap, min(cap, paddleSpeed*steeringLeadSeconds))
    }

    /// How much of the paddle's travel per second the lead is worth.
    static let steeringLeadSeconds: CGFloat = 0.14

    /// The furthest the lead may reach, as a share of the field's width.
    static let steeringLeadCap: CGFloat = 0.3

    /// How much of the gap to the paddle a steered ball closes in one sixtieth of a second.
    ///
    /// The inertia, in one number. High enough that the ball answers the paddle at once,
    /// low enough that it arrives rather than teleports - and low enough that a bounce off
    /// a brick visibly throws it off course before it is gathered back in.
    static let steeringFollowPerSixtieth: CGFloat = 0.16

    /// The share of the gap closed by a frame of this length.
    ///
    /// **Measured in time, not in frames** (James, round 209: "the ball steering power up now
    /// feels way too sensitive, the ball seems to have no moments of its own").
    ///
    /// It was a flat share taken once per frame, and the scene asks for 120 frames a second.
    /// So on a ProMotion phone the pull was applied twice as often as the number was tuned
    /// for: the ball closed about 30% of the gap in the time it was meant to close 16%, which
    /// is a ball glued to the paddle rather than drawn to it. Compounding it over the frame's
    /// own length gives the same journey at any frame rate - 0.16 at 60, about 0.084 at 120,
    /// and the same feel on both.
    static func steeringFollow(delta: TimeInterval) -> CGFloat {
        guard delta > 0 else { return 0 }
        return 1 - pow(1 - steeringFollowPerSixtieth, CGFloat(delta)*60)
    }

    /// How much of a steered ball's sideways speed survives each frame.
    ///
    /// The other half of "the ball should forget its original trajectory": bleeding the
    /// horizontal velocity away stops the physics engine arguing with the steering every
    /// frame, which is what would otherwise make a steered ball jitter. What is taken out
    /// sideways is put back vertically by `steeredVelocity`, so the ball keeps its pace -
    /// a steered ball is not a slower ball.
    static let steeringVelocityDampingPerSixtieth: CGFloat = 0.82

    /// How much of that sideways speed survives a frame of this length.
    ///
    /// The other half of the frame-rate bug above, and the half that answers "no momentum of
    /// its own" most directly: taken once per frame, a ball at 120fps lost its own line twice
    /// as fast as one at 60. Same compounding, same reason.
    static func steeringVelocityDamping(delta: TimeInterval) -> CGFloat {
        guard delta > 0 else { return 1 }
        return pow(steeringVelocityDampingPerSixtieth, CGFloat(delta)*60)
    }

    /// A steered ball's velocity after this frame's damping: less sideways, the same speed.
    static func steeredVelocity(_ velocity: CGVector,
                                delta: TimeInterval = 1.0/60) -> CGVector {
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        guard speed > 0 else { return velocity }
        let dx = velocity.dx*steeringVelocityDamping(delta: delta)
        let upward: CGFloat = velocity.dy >= 0 ? 1 : -1
        let dy = upward*max(0, speed*speed - dx*dx).squareRoot()
        return CGVector(dx: dx, dy: dy)
    }

    // MARK: - Paddle Halo

    /// How far the halo reaches from the paddle's centre, by stacking level, as a multiple
    /// of the paddle's width. Raised again in round 11: at [1.9, 2.6] it only touched the
    /// bottom row of a low field, and the request is the bottom *two*.
    static let haloReach: [CGFloat] = [2.3, 3.0, 3.7]
    // Three stacks rather than two (play-test round 98): collecting the halo while it is
    // running should visibly buy more field, and one step was easy to miss entirely. The
    // clock's deepest level follows this count, so the ladder is the only thing to edit
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

    /// How many bricks the glow eats in one frame.
    ///
    /// **A few at a time** (James, round 215: "paddle halo causes game to become stuttery").
    /// The glow destroyed every brick it touched on the same frame. That is one or two while
    /// it erodes a field it already overlaps, and eleven at once the moment a whole row
    /// descends into it - each running its role's reaction, its removal action, its scoring
    /// and its counters, with an Exploding brick in the burst taking its neighbours too. The
    /// same one-frame pile-up that made Retreat stutter when it cleared two rows.
    ///
    /// At a hundred and twenty frames a second, two a frame still clears a row in well under
    /// a tenth of a second, so nothing about how the halo feels changes.
    static let haloBitesPerFrame = 2

    /// Which of the bricks the glow is touching it eats this frame, lowest first.
    ///
    /// Returns positions into `heights`, so the caller keeps hold of its own bricks. Lowest
    /// first so the glow erodes upward from the paddle rather than picking bricks in whatever
    /// order the scene graph happens to hold them - the order was invisible while every
    /// touched brick went at once, and is the whole look of it now that they go a few at a
    /// time.
    static func haloBites(heights: [CGFloat], limit: Int = haloBitesPerFrame) -> [Int] {
        heights.indices
            .sorted { heights[$0] < heights[$1] }
            .prefix(max(0, limit))
            .map { $0 }
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
