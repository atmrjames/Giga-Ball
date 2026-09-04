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

    /// How much harder a gripping paddle throws the ball off its ends.
    ///
    /// James, round 305: "I also think the angle at which the ball bounces off the paddle
    /// should be more extreme as if the paddle is more grippy." A grippy surface does not just
    /// curve the flight afterwards, it takes the ball further off centre in the first place -
    /// so Ball Spin raises the paddle's angular influence for as long as it runs.
    ///
    /// A half again rather than double: the influence multiplies a bend that is already
    /// clamped at both ends by `angleAdjustmentK` and `minimumDeg`, so this steepens the
    /// bounce without letting the edges return a ball that runs along the field sideways.
    static let grippyInfluence: Double = 1.5

    static func angleInfluence(inert: Bool, flipped: Bool, gripping: Bool = false) -> Double {
        if inert { return 0 }
        if flipped { return flippedInfluence }
        return gripping ? grippyInfluence : 1
        // Inert first and Flipped second, unchanged: a paddle that gives no angle at all gives
        // none however grippy it is, and Flipped's over-correction is its own statement rather
        // than something to multiply
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
    /// owns the ball's column outright. The ball is drawn toward wherever the paddle is, on
    /// the spring below rather than as a cursor - so it takes a moment to answer, and carries
    /// on a little past the paddle before it settles.
    static func steeredTowards(paddleX: CGFloat, from x: CGFloat,
                               velocity: CGFloat = 0,
                               leftWall: CGFloat, rightWall: CGFloat,
                               radius: CGFloat,
                               paddleSpeed: CGFloat = 0,
                               fieldWidth: CGFloat = 0,
                               delta: TimeInterval = 1.0/60)
    -> (x: CGFloat, velocity: CGFloat) {
        let target = paddleX + steeringLead(paddleSpeed: paddleSpeed, fieldWidth: fieldWidth)
        let stepped = steeringStep(x: x, velocity: velocity, towards: target, delta: delta)
        let held = max(leftWall + radius, min(rightWall - radius, stepped.x))
        return (held, held == stepped.x ? stepped.velocity : 0)
        // **A wall stops the swing as well as the ball.** Clamping the position and keeping the
        // velocity would leave the ball pressed against the wall with the spring still winding
        // up behind it, and it would spring off the moment the paddle moved back - which is a
        // catapult rather than steering. A wall is a stop: what reaches it is at rest
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

    // MARK: The spring, and why it is not a lag any more
    //
    // James, round 284: "Ball control is too controlling over the ball. When moving the
    // paddle, the ball shouldn't follow immediately. There should be some lag and some
    // inertia. The ball also shouldn't snap into place, its momentum should take it slightly
    // beyond the paddle and then swing back. The ball should have more inertia."
    //
    // **The last two sentences are why this had to change shape rather than change a number.**
    // What was here closed a fixed share of the gap every frame - an exponential lag, and the
    // defining property of an exponential lag is that it *cannot* overshoot. It approaches the
    // target from one side and slows down for ever. However the share was tuned, "its momentum
    // should take it slightly beyond the paddle and then swing back" was not a thing it could
    // be asked to do; the ball would only ever have arrived faster or slower.
    //
    // So the ball is on a spring now. It carries a sideways velocity of its own, the paddle's
    // column pulls on it, and a damping term takes energy out. Two numbers describe the whole
    // of it, and both are the ones a person can actually reason about:
    //
    // - `steeringNaturalFrequency` - how stiff the spring is, in radians per second. Bigger is
    //   a ball that hurries.
    // - `steeringDampingRatio` - below 1 it overshoots and swings back, at 1 it arrives and
    //   stops dead, above 1 it crawls in. This is the "swing back", and it is a ratio rather
    //   than a rate so the two numbers can be tuned independently.
    //
    // Round 209's lesson is kept and made stronger. It found that a share taken once per frame
    // gave a different feel at 120fps than at 60 ("the ball seems to have no moments of its
    // own"), and answered it by compounding the share over the frame's length. A spring
    // integrated once per frame has the same fault in a worse form - the *stability* of the
    // integration depends on the frame length, so a long frame does not merely feel different,
    // it can throw the ball across the field. `steeringStep` is the answer: the frame is
    // consumed in fixed slices, so the trajectory is the frame rate's business no longer.

    /// How stiff the spring pulling a steered ball to the paddle's column is, in radians per
    /// second.
    ///
    /// Set against what it replaced rather than from nothing, and the comparison is worth
    /// writing down because the obvious one is misleading. The old lag closed 16% of the gap
    /// every sixtieth of a second: two thirds of the way to the paddle in a tenth of a second,
    /// and then a long asymptotic crawl it never quite finished. So "how long until it gets
    /// there" is the wrong question to tune against - the old pull never got there at all, it
    /// merely stopped being distinguishable from having got there.
    ///
    /// What the player feels is the *start*, and that is what this is set by. At 11 rad/s the
    /// first frame of a chase moves the ball about 2% of the gap where the old pull moved it
    /// 16%, and a tenth of a second in it is 39% of the way across where the old one was 65%.
    /// It then arrives carrying speed, passes the paddle, and is gathered back - about a third
    /// of a second to the far side of the swing and settled by three quarters of one.
    ///
    /// **Loosened again in round 293** (James: "ball steering could still do with some more
    /// inertia on the ball, the tether between the ball and paddle should feel more like a
    /// piece of string"). A string is the picture to design to: it goes slack when the paddle
    /// moves toward the ball, it pulls when the paddle moves away, and what is on the end of it
    /// arrives late and keeps going. Eleven answered the first half of that and not the second
    /// - the ball was already most of the way to the paddle before its own momentum mattered.
    ///
    /// At 8 the first frame of a chase moves the ball about 1% of the gap where the old
    /// exponential pull moved it 16%, it is a third of the way across at a tenth of a second,
    /// and it reaches the paddle's column at about a fifth of a second carrying enough speed to
    /// go a fifth of the way past.
    ///
    /// **The first value tried was 14 and it was the test that argued it down.** At 14 the ball
    /// crossed the paddle's column at the tenth-of-a-second mark, which is no more lag than
    /// there had ever been; the overshoot was there and the inertia was not. Both halves of
    /// James's note have to be true at once, and this is the same trade taken one step further.
    static let steeringNaturalFrequency: CGFloat = 8

    /// How heavily that spring is damped, as a fraction of critical.
    ///
    /// **A little under half, so it overshoots by about a fifth of the distance and comes
    /// back.** The overshoot of a step response is `exp(-pi*z/sqrt(1-z*z))`: 0.16 at a damping
    /// ratio of 0.5, and 0.20 at 0.45. Round 284 asked for "slightly beyond the paddle and then
    /// swing back" and round 293 for a tether that feels "more like a piece of string", which
    /// is the same request one notch further - a string's load swings wider than a stiff arm's.
    ///
    /// Still one swing. Below about 0.3 a second swing becomes visible, and a ball that
    /// oscillates around the paddle is a ball the player has stopped being able to place.
    static let steeringDampingRatio: CGFloat = 0.45

    /// The longest slice of time the spring is integrated over in one go.
    ///
    /// A quarter of a 60fps frame. Not a tuning value: a spring integrated in steps larger
    /// than a fraction of its own period gains energy instead of losing it, and the fix is to
    /// take smaller steps rather than to soften the spring.
    static let steeringStepSeconds: CGFloat = 1.0/240

    /// One frame of the spring: where the ball goes and how fast it is going sideways.
    ///
    /// Semi-implicit rather than plain Euler - the velocity is advanced first and the position
    /// uses the new one - because it is the integrator that conserves energy on an oscillator
    /// rather than quietly adding it. A ball that gained a little every swing would take
    /// longer to settle each time it was pushed, which is not a thing anybody would think to
    /// look for and would read as the power-up being erratic.
    static func steeringStep(x: CGFloat, velocity: CGFloat, towards target: CGFloat,
                             delta: TimeInterval) -> (x: CGFloat, velocity: CGFloat) {
        guard delta > 0 else { return (x, velocity) }
        let frequency = steeringNaturalFrequency
        let damping = 2*steeringDampingRatio*frequency
        var position = x
        var speed = velocity
        var remaining = CGFloat(delta)
        while remaining > 0 {
            let slice = min(steeringStepSeconds, remaining)
            remaining -= slice
            speed += (frequency*frequency*(target - position) - damping*speed)*slice
            position += speed*slice
        }
        return (position, speed)
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

    /// Which paddle a magnetised ball is pulled toward.
    ///
    /// **The nearer of the two** (James, round 225's matrix: "ball is magnetised to the
    /// closest paddle and not to the other"). Two magnets pulling one ball is a ball pulled to
    /// the point between them, which is the one place neither paddle is.
    ///
    /// Ties go to the real paddle, which is the one the player is steering: with the ball
    /// exactly between them the choice is arbitrary, and an arbitrary choice should be the one
    /// the player can do something about.
    static func magnetisedTowards(ballX: CGFloat, paddleX: CGFloat,
                                  mirrorX: CGFloat?) -> CGFloat {
        guard let mirrorX else { return paddleX }
        return abs(mirrorX - ballX) < abs(paddleX - ballX) ? mirrorX : paddleX
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

    /// The angle the arrow points at, given where the finger is and where the ball is.
    ///
    /// **The arrow points at the finger** (James, round 232: "aimed sticky arrow should move
    /// relative to touch and drag gesture", and "a tap above the paddle moves the arrow to the
    /// tap position"). Both notes are the same rule said twice: the shot goes where you are
    /// touching, whether you got there by tapping or by dragging.
    ///
    /// That replaces round 10's answer, which mapped the finger's x across the screen onto a
    /// fixed arc. It was absolute, which was the half round 10 got right, but the arc had no
    /// relationship to where the ball actually was - aiming at a brick meant learning the
    /// mapping rather than pointing at the brick.
    ///
    /// **Never flat and never downward.** The clamp is the same `minimum` every bounce in the
    /// game is held to: a ball launched along the paddle's own line runs sideways until
    /// something stops it, and one launched below it is a ball thrown away.
    static func aimedAngle(at finger: CGPoint, from ball: CGPoint,
                           minimum: Double) -> Double {
        let dx = Double(finger.x - ball.x)
        let dy = Double(finger.y - ball.y)
        guard dx != 0 || dy != 0 else { return Double.pi/2 }

        let angle = atan2(dy, dx)
        return max(minimum, min(Double.pi - minimum, angle))
        // atan2 gives the whole circle; the clamp folds everything at or below the horizontal
        // onto the shallowest shot the game allows, so a finger dragged under the ball still
        // aims somewhere sensible rather than snapping to the far side
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
