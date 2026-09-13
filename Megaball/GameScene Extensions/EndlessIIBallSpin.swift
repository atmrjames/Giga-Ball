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
    ///
    /// **It was 1400, which the play area cannot produce** (James, round 283: "ball spin isn't
    /// curving the ball - what is actually happening?"). The field is about 400 points across,
    /// so 1400 points a second is crossing it three and a half times in one - a speed no thumb
    /// reaches and certainly not while tracking a ball. Everything below full grip is scaled
    /// linearly from `gripThreshold`, so a brisk 400 pt/s swipe was earning a quarter of the
    /// curve and a fast 600 pt/s one under half.
    ///
    /// Measured rather than guessed at, in `testWhatBallSpinAndRandomBounceActuallyDo`: at 400
    /// pt/s the ball turned 16 degrees over its *whole* flight and under 5 of them in the first
    /// quarter second, which is the part played near the paddle where a curve would be seen. At
    /// 700 the same swipe earns the quarter-turn a second the design always intended, and the
    /// ceiling is still above what an ordinary swipe reaches so a hard flick still means more.
    static let fullGripSpeed: CGFloat = 700

    /// How far the heading turns per second at full grip, in radians.
    ///
    /// **Doubled in round 322** (James, round 320: "ball spin stronger"). It was a quarter-turn
    /// a second, which `testWhatBallSpinAndRandomBounceActuallyDo` put at 19 degrees in the
    /// first quarter second and 65 over the whole flight. Doubled together with a faster
    /// `decayPerSecond`, so the extra bend lands where it is seen, just off the paddle: about
    /// 36 degrees in that first quarter second, and 95 in all - still a curve and not a
    /// boomerang, because most of that is spent before the ball reaches the bricks.
    static let strongestTurn: CGFloat = .pi

    /// How much of the spin is left after a second of flight.
    ///
    /// The grip is spent as the ball travels, so the curve is sharpest just off the paddle and
    /// has straightened out by the time the ball reaches the field. A curve that lasted the
    /// whole flight would make the ball unaimable rather than interesting. 0.25 until round
    /// 322, spent faster now to keep the stronger turn close to the paddle - see
    /// `strongestTurn`.
    static let decayPerSecond: CGFloat = 0.15

    /// How much of a paddle flick the *grip* still remembers a second later.
    ///
    /// Tiny, because this bridges the gap between a swipe and a bounce rather than giving the
    /// paddle a memory: half of it survives a tenth of a second, and by half a second an
    /// ordinary flick is already under `gripThreshold`.
    static let gripMemoryPerSecond: CGFloat = 0.001

    /// The turn a ball earns by *sliding* across a grippy surface that is not keeping up
    /// with it, at the very shallowest arrival.
    ///
    /// **James, round 313: "ball spin power still doesn't seem to be putting spin on the ball
    /// unless the paddle is moving"** - the same note as round 305, after round 305's answer.
    ///
    /// That answer was the collision offset: dead centre gives nothing, the edge gives
    /// `edgeTurn`. Measured, it delivers **nothing at all in the middle**, 5.4 degrees over a
    /// whole flight a quarter of the way out, and 21.6 at the very edge - against 34.5 for a
    /// 400 pt/s swipe and 54.8 for a brisk 600. And a player holding the paddle still is a
    /// player who has put it under the ball, which is exactly where the term is zero. So the
    /// power-up really did nothing unless the paddle moved, and the reason was that the
    /// quantity chosen to stand for the slide does not measure the slide.
    ///
    /// What does is the ball's own horizontal speed. A ball arriving at 45 degrees is crossing
    /// the surface at 0.7 of its speed whether it lands in the middle or the corner, and that
    /// is the friction the note is about. Taken as a *fraction* of the ball's speed rather than
    /// in points per second, so a Decrease Ball Speed does not quietly turn the grip off.
    ///
    /// A third of the flick's turn: a swipe is still the bigger half of the power-up, and this
    /// reads as grip rather than as a second flick.
    ///
    /// **It replaces round 305's `edgeTurn` rather than joining it**, because the two are the
    /// same claim about the same friction and they disagree about which way it acts. The edge
    /// term curved the ball *towards* the side it landed on, and a ball travelling right lands
    /// right - so it curved along the slide where friction acts against it. Measured with both
    /// in place: at a 45-degree arrival the two nearly cancelled half way out, 15.3 degrees of
    /// curve dead centre falling to 4.5 at the mid-point of the paddle, which is a power-up
    /// that gets weaker the harder you cut the ball.
    ///
    /// Doubled with `strongestTurn` in round 322, so it stays the same share of the flick.
    static let slideTurn: CGFloat = .pi/3

    /// The most the three together may ask for, so a fast flick into the corner stays playable.
    /// Doubled with the two it caps, in round 322.
    static let steepestTurn: CGFloat = .pi*4/3

    /// The turn rate a paddle grips the ball with.
    ///
    /// Signed: the ball curves the way the paddle was travelling, which is what "as if there
    /// were friction between the two" means - and, since round 305, the way the ball was
    /// already sliding when it met an off-centre surface.
    ///
    /// `collision` is where the ball struck, from -1 at the left end through 0 at the middle
    /// to 1 at the right, which is what `PaddleBounce.collision` already answers for the
    /// bounce angle. Defaulted so the arithmetic can still be asked the old question.
    /// - Parameter collision: where the ball struck, -1 to 1. **No longer part of the
    ///   arithmetic** - see `slideTurn` for why the slide replaced it - but still taken,
    ///   because every caller knows it, it is the natural thing to reach for here, and a
    ///   parameter quietly removed is a parameter quietly re-added by the next person who
    ///   wants a baseline. Its test says the surface's own grip is the same wherever a ball
    ///   lands on it.
    static func turnRate(paddleSpeed: CGFloat, collision: CGFloat = 0,
                         arriving: CGVector = .zero) -> CGFloat {
        let magnitude = abs(paddleSpeed)
        var rate: CGFloat = 0
        if magnitude > gripThreshold {
            let span = max(1, fullGripSpeed - gripThreshold)
            let strength = min(1, (magnitude - gripThreshold)/span)
            rate += (paddleSpeed < 0 ? -1 : 1)*strength*strongestTurn
        }
        // The threshold still guards the *speed* term only: a paddle creeping along under a
        // ball is noise, and that was always what the floor was for

        let speed = hypot(arriving.dx, arriving.dy)
        if speed > 0 {
            rate -= (arriving.dx/speed)*slideTurn
            // **Against the slide, which is what friction is.** The ball is crossing the
            // surface to the right, so the surface drags its contact point to the left and the
            // heading turns that way - which steepens the bounce rather than flattening it,
            // and a steeper bounce is the one the rest of the game already wants
            // (`minAngleDeg` exists to stop shallow ones). Curving it further along its own
            // path would fight that discipline on every grip.
            //
            // No threshold: a ball with any horizontal travel at all is sliding, and the
            // fraction is already near nothing for one falling nearly straight down
        }

        return min(max(rate, -steepestTurn), steepestTurn)
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
        endlessIIDisplace(byCollecting: .ballSpin)
        endlessIIBallSpinClock.collect(turns: GameScene.endlessIIBallSpinTurns)
        startEndlessIIGrip()
        // Spin and every other answer to "where does the ball go when it leaves the paddle"
        // are one question with one answer (round 223's matrix) - and the paddle says which it
        // is giving by wearing the grip, which also replaces Sticky and Aimed Sticky outright
        // rather than sitting over them (James, round 261). See `EndlessIIGrip`
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

        let fade = pow(EndlessIIBallSpin.gripMemoryPerSecond, CGFloat(delta))
        let faded = endlessIIPaddleGripSpeed*fade
        endlessIIPaddleGripSpeed =
            abs(endlessIIPaddleSpeed) >= abs(faded)
                || (endlessIIPaddleSpeed < 0) != (faded < 0)
            ? endlessIIPaddleSpeed : faded
        // **The grip reads the recent flick; everything else reads this frame** (James, round
        // 214: "ball spin doesn't seem to do anything").
        //
        // `endlessIIPaddleSpeed` stays exactly what it was - the distance covered since the
        // last frame, and zero the moment the finger stops. That is deliberate and tested: a
        // paddle let go of must not read as holding its last flick, because Ball Steering
        // leads its target by this and would keep pulling.
        //
        // But the *grip* is sampled on the one frame the ball lands, and a frame at 120fps is
        // eight milliseconds of finger. A player swipes the paddle across and then holds it
        // steady to meet the ball, so at the moment of contact the instantaneous speed is very
        // often zero - and a power-up that only works if you happen to still be moving on that
        // exact frame reads as one that does nothing. This keeps the larger of now and a moment
        // ago, and is gone within a few tenths, which is long enough to bridge a swipe to a
        // bounce and far too short to be a memory. A flick the other way is taken at once,
        // because that is a new flick rather than a continuation.
    }

    /// Grips a ball that has just come off the paddle.
    ///
    /// Called from `paddleHit`, after the bounce the paddle would have given anyway - the spin
    /// bends the flight that follows rather than replacing the bounce. A ball that was *caught*
    /// gets no grip: a catch is not a bounce, and Aimed Sticky owns what happens next (§12.0's
    /// note that this conflicts with the paddle group - it does, and this is where).
    /// - Parameter collision: where the ball struck the surface, -1 to 1. The callers know
    ///   which surface they are - the paddle, the mirror, the safety bar - and each has
    ///   already worked this out for the bounce angle, so it is passed rather than guessed.
    func endlessIIGripBall(_ subject: SKSpriteNode, collision: CGFloat = 0) {
        guard endlessIIBallSpinIsRunning else { return }
        guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { return }
        let rate = EndlessIIBallSpin.turnRate(
            paddleSpeed: endlessIIPaddleGripSpeed,
            collision: collision,
            arriving: ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
                ?? subject.physicsBody?.velocity ?? .zero)
        // **The velocity before the step, not the one the contact reports** (§8.6's first
        // trap). By the time this runs the engine has already turned the ball round, so the
        // reported `dx` is the *outgoing* slide - which is the same size but tells the grip to
        // curve the wrong way on every bounce off a vertical face. `ballStateBeforeStep` is
        // the sample taken in `update`, before physics.
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
        endlessIIPaddleGripSpeed = 0
        endlessIIPaddleLastX = paddle.position.x
        endlessIIRemoveSpinTrails()
    }

    // MARK: - The trail

    /// How many fading copies follow a spinning ball.
    static let endlessIISpinTrailCount = 6
    /// How far apart the copies sit, in seconds of flight rather than frames, so the streak is
    /// the same length at 60fps and 120fps.
    static let endlessIISpinTrailSpacing: TimeInterval = 0.025
    /// The nearest copy's opacity at full strength; each one behind it is fainter.
    static let endlessIISpinTrailAlpha: CGFloat = 0.45
    /// How much smaller the last copy is than the ball, as a share of its size.
    static let endlessIISpinTrailTaper: CGFloat = 0.4
    /// A move further than this in one frame is a wrap or a portal, not flight, and the streak
    /// starts again rather than drawing copies across the field.
    static let endlessIISpinTrailBreak: CGFloat = 60
    static let endlessIISpinTrailName = "endlessIISpinTrail"

    /// Lays each spinning ball's streak along where it has just been, from `didSimulatePhysics`.
    ///
    /// **James, round 320: "ball spin stronger plus a motion trail."** The trail is what lets a
    /// player *see* the curve rather than infer it from where the ball ends up, so it shows
    /// exactly while a ball carries a spin rate and fades with the rate as the grip is spent -
    /// the streak says how much bend is left.
    ///
    /// Pooled sprites placed by hand each frame rather than copies spawned with a fade action:
    /// a spawn per frame is a node allocated a frame at 120fps for as long as the ball spins,
    /// and the pool is six nodes a ball for the life of the spin. Placed from sampled positions
    /// timed by the frame delta, so a pause holds the streak still instead of letting it drain.
    func tickEndlessIISpinTrails(_ delta: TimeInterval) {
        guard endlessIISpinTrails.isEmpty == false || endlessIIBallSpinRates.isEmpty == false
        else { return }
        guard gameState.currentState is Playing, isPaused == false else { return }

        endlessIISpinTrailClock += max(0, delta)
        let now = endlessIISpinTrailClock
        let count = GameScene.endlessIISpinTrailCount
        let oldest = GameScene.endlessIISpinTrailSpacing*Double(count + 1)
        var live = Set<ObjectIdentifier>()

        for subject in endlessIIBallsInPlay {
            let key = ObjectIdentifier(subject)
            guard let rate = endlessIIBallSpinRates[key], let parent = subject.parent
            else { continue }
            live.insert(key)

            var history = endlessIISpinTrailHistory[key] ?? []
            if let last = history.first,
               hypot(subject.position.x - last.point.x, subject.position.y - last.point.y)
                > GameScene.endlessIISpinTrailBreak {
                history.removeAll()
            }
            history.insert((now, subject.position), at: 0)
            while history.count > 1, let tail = history.last, now - tail.time > oldest {
                history.removeLast()
            }
            endlessIISpinTrailHistory[key] = history

            let strength = EndlessIIBallSpin.trailStrength(rate: rate)
            for (index, ghost) in endlessIISpinTrailGhosts(for: subject, in: parent).enumerated() {
                let age = GameScene.endlessIISpinTrailSpacing*Double(index + 1)
                guard let sample = history.first(where: { now - $0.time >= age }) else {
                    ghost.isHidden = true
                    continue
                }
                // Too young a streak has no sample that old yet, so it grows out from the
                // ball over its first few frames rather than appearing whole

                if ghost.texture !== subject.texture { ghost.texture = subject.texture }
                let along = CGFloat(index + 1)/CGFloat(count)
                let shrink = 1 - GameScene.endlessIISpinTrailTaper*along
                ghost.size = CGSize(width: subject.size.width*shrink,
                                    height: subject.size.height*shrink)
                // `size` carries the ball's scale already (§8.6), so the copy is sized
                // outright and never scaled itself
                ghost.color = subject.color
                ghost.colorBlendFactor = subject.colorBlendFactor
                ghost.zPosition = subject.zPosition - 0.1
                ghost.position = sample.point
                let fade = 1 - along + 1/CGFloat(count)
                ghost.alpha = subject.alpha*GameScene.endlessIISpinTrailAlpha*fade*strength
                ghost.isHidden = false
            }
        }

        for (key, ghosts) in endlessIISpinTrails where live.contains(key) == false {
            ghosts.forEach { $0.removeFromParent() }
            endlessIISpinTrails[key] = nil
            endlessIISpinTrailHistory[key] = nil
        }
        // A ball whose spin is spent, caught or gone takes its streak with it
    }

    /// The pool for one ball, made on its first spinning frame and kept beside it.
    private func endlessIISpinTrailGhosts(for subject: SKSpriteNode,
                                          in parent: SKNode) -> [SKSpriteNode] {
        let key = ObjectIdentifier(subject)
        if let ghosts = endlessIISpinTrails[key], ghosts.first?.parent === parent {
            return ghosts
        }
        endlessIISpinTrails[key]?.forEach { $0.removeFromParent() }
        let ghosts = (0..<GameScene.endlessIISpinTrailCount).map { _ -> SKSpriteNode in
            let ghost = SKSpriteNode()
            ghost.name = GameScene.endlessIISpinTrailName
            ghost.isHidden = true
            parent.addChild(ghost)
            return ghost
        }
        endlessIISpinTrails[key] = ghosts
        return ghosts
    }

    func endlessIIRemoveSpinTrails() {
        endlessIISpinTrails.values.joined().forEach { $0.removeFromParent() }
        endlessIISpinTrails.removeAll()
        endlessIISpinTrailHistory.removeAll()
    }
}

extension EndlessIIBallSpin {

    /// How strongly a spinning ball's trail shows, 0 to 1.
    ///
    /// Full from half the strongest flick's turn up, and fading below that as the grip is
    /// spent, so a ball that has nearly straightened out trails nearly nothing.
    static func trailStrength(rate: CGFloat) -> CGFloat {
        min(1, abs(rate)/(strongestTurn/2))
    }
}
