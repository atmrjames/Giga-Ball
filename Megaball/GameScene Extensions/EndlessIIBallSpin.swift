//
//  EndlessIIBallSpin.swift
//  Megaball
//
//  Ball Spin: the paddle grips the ball, and the ball leaves on a curve.
//
//  James's play-test idea from the second round, and §12.0's build note is most of the design:
//  "the paddle's own velocity at contact grips the ball - as if there were friction between the
//  two - and the ball leaves on a curved path, curving harder the faster the paddle was moving.
//  Wears a grippy paddle texture while active."
//
//  Three things in that note decide the whole implementation.
//
//  **The paddle's velocity is sampled from the touch handler, not the contact.** By the time a
//  contact is reported the engine has resolved it, and the paddle has often already been moved
//  again by the same frame's touch - so the speed read there is not the speed that did the
//  gripping. `tickEndlessIIPaddleTravel` samples the paddle's own movement once a frame, which
//  is where the touch handler's writes land.
//
//  **The curve is applied from `didSimulatePhysics`, never inside the contact** (§8.6). A
//  velocity written during contact resolution is undone by the rest of the step.
//
//  **It is a rotation, not a push.** Nudging the velocity sideways would change the ball's
//  speed, and the whole game is built on the ball holding its speed - the angle discipline in
//  `ballHorizontalControl`, the speed power-ups, the launch. Turning the heading a little each
//  frame curves the path and leaves the speed exactly alone.
//

import SpriteKit

/// The arithmetic of the curve, apart from the scene so it can be tested without one.
enum EndlessIIBallSpin {

    /// How fast the paddle must be moving to grip at all, in points per second.
    ///
    /// A paddle creeping along under a ball is not friction, it is noise - and without a floor
    /// every ordinary bounce would leave on a faint curve nobody asked for.
    static let gripThreshold: CGFloat = 60

    /// The paddle speed that earns the full curve, in points per second. Past this it stops
    /// growing: a flick can be fast enough to be silly, and the ball still has to be playable.
    static let fullGripSpeed: CGFloat = 1400

    /// How far the heading turns per second at full grip, in radians. A quarter-turn over a
    /// second of flight - clearly a curve, never a boomerang.
    static let strongestTurn: CGFloat = .pi/2

    /// How much of the spin is left after a second of flight.
    ///
    /// The grip is spent as the ball travels, so the curve is sharpest just off the paddle and
    /// has straightened out by the time the ball reaches the field. A curve that lasted the
    /// whole flight would make the ball unaimable rather than interesting.
    static let decayPerSecond: CGFloat = 0.25

    /// The turn rate a paddle moving at this speed grips the ball with.
    ///
    /// Signed: the ball curves the way the paddle was travelling, which is what "as if there
    /// were friction between the two" means. Below the threshold there is no grip at all.
    static func turnRate(paddleSpeed: CGFloat) -> CGFloat {
        let magnitude = abs(paddleSpeed)
        guard magnitude > gripThreshold else { return 0 }
        let span = max(1, fullGripSpeed - gripThreshold)
        let strength = min(1, (magnitude - gripThreshold)/span)
        return (paddleSpeed < 0 ? -1 : 1)*strength*strongestTurn
    }

    /// What is left of a turn rate after this much flight.
    static func decayed(_ rate: CGFloat, over delta: TimeInterval) -> CGFloat {
        guard delta > 0 else { return rate }
        return rate*pow(decayPerSecond, CGFloat(delta))
    }

    /// The velocity a spinning ball has after this much of a frame.
    ///
    /// A rotation, so the speed is untouched - see the file's note.
    static func turned(_ velocity: CGVector, rate: CGFloat,
                       delta: TimeInterval) -> CGVector {
        guard rate != 0, delta > 0 else { return velocity }
        let angle = atan2(velocity.dy, velocity.dx) + rate*CGFloat(delta)
        let speed = hypot(velocity.dx, velocity.dy)
        return CGVector(dx: cos(angle)*speed, dy: sin(angle)*speed)
    }
}

extension GameScene {

    /// How many paddle hits the grip lasts, like the rest of the paddle batch.
    static let endlessIIBallSpinTurns = Int(GameScene.endlessIIPaddlePowerUpTurns)

    func endlessIICollectBallSpin() {
        guard gameMode == .endlessII else { return }
        endlessIIBallSpinClock.collect(turns: GameScene.endlessIIBallSpinTurns)
    }

    var endlessIIBallSpinIsRunning: Bool {
        gameMode == .endlessII && endlessIIBallSpinClock.isRunning
    }

    /// Samples how fast the paddle is travelling, once a frame.
    ///
    /// The paddle has no velocity of its own - it is a static body moved by the touch handler -
    /// so its speed is the distance it covered since the last frame. Called from the paddle
    /// tick, which runs whether or not a finger is down, so a paddle let go of reads as still
    /// rather than holding the last flick for ever.
    func tickEndlessIIPaddleTravel(_ delta: TimeInterval) {
        guard delta > 0 else { return }
        let moved = paddle.position.x - endlessIIPaddleLastX
        endlessIIPaddleLastX = paddle.position.x
        endlessIIPaddleSpeed = moved/CGFloat(delta)
    }

    /// Grips a ball that has just come off the paddle.
    ///
    /// Called from `paddleHit`, after the bounce the paddle would have given anyway - the spin
    /// bends the flight that follows rather than replacing the bounce. A ball that was *caught*
    /// gets no grip: a catch is not a bounce, and Aimed Sticky owns what happens next (§12.0's
    /// note that this conflicts with the paddle group - it does, and this is where).
    func endlessIIGripBall(_ subject: SKSpriteNode) {
        guard endlessIIBallSpinIsRunning else { return }
        guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { return }
        let rate = EndlessIIBallSpin.turnRate(paddleSpeed: endlessIIPaddleSpeed)
        guard rate != 0 else { return }
        endlessIIBallSpinRates[ObjectIdentifier(subject)] = rate
    }

    /// Curves every gripped ball, from `didSimulatePhysics`.
    func applyEndlessIIBallSpin(_ delta: TimeInterval) {
        guard endlessIIBallSpinRates.isEmpty == false else { return }
        forgetEndlessIISpinsWithNoBall()
        // Housekeeping first, whatever the game is doing. A ball that has left the field or
        // been caught is not carrying a curve, and the rates are keyed by ball - so an entry
        // that outlives its ball is a leak the pause would otherwise preserve

        guard gameState.currentState is Playing, isPaused == false else { return }

        for subject in endlessIIBallsInPlay {
            let key = ObjectIdentifier(subject)
            guard let rate = endlessIIBallSpinRates[key], let body = subject.physicsBody
            else { continue }

            if subject === ball { crookedBallNote("spin") }
            body.velocity = EndlessIIBallSpin.turned(body.velocity, rate: rate, delta: delta)

            let left = EndlessIIBallSpin.decayed(rate, over: delta)
            endlessIIBallSpinRates[key] = abs(left) < 0.01 ? nil : left
            // Spent as it travels, and forgotten once there is nothing left to spend
        }
    }

    /// Drops the curve of any ball that is no longer flying under its own steam.
    ///
    /// A ball caught mid-curve gives its spin up: the catch owns what happens next, and a
    /// ball released by an aim must leave at the angle the aim chose, not at the angle plus
    /// whatever the paddle's last flick was still worth.
    func forgetEndlessIISpinsWithNoBall() {
        let flying = Set(endlessIIBallsInPlay
            .filter { subject in
                subject.parent != nil
                    && endlessIIHeldBalls.contains(where: { $0 === subject }) == false
            }
            .map(ObjectIdentifier.init))
        endlessIIBallSpinRates = endlessIIBallSpinRates.filter { flying.contains($0.key) }
    }

    func endlessIIResetBallSpin() {
        endlessIIBallSpinClock.reset()
        endlessIIBallSpinRates.removeAll()
        endlessIIPaddleSpeed = 0
        endlessIIPaddleLastX = paddle.position.x
    }
}
