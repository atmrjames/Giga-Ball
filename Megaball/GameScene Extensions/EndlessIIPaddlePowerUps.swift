//
//  EndlessIIPaddlePowerUps.swift
//  Megaball
//
//  Phase 8b: the power-ups that change what the paddle does.
//
//  Eight of them, good and bad together, because they want tuning against each other: a
//  paddle that curves the ball toward itself, one that teleports the ball to the top, one
//  that burns the nearest rows, one that steers the ball in flight, one whose launches are
//  aimed by hand - and three saboteurs that take the paddle's influence away, invert it, or
//  reverse the controls.
//
//  The arithmetic of each lives in `EndlessIIPaddleEffects`, pure and tested. What lives here
//  is the clocks, the drawing, and the places each effect is plugged into the scene - which
//  are deliberately few and named, because the paddle's contact handler is old code that
//  should be *asked* about power-ups rather than rewritten around them.
//
//  Everything is Endless 2.0 only. The bad ones deduct like every red power-up; the whole
//  batch runs on `EndlessIIClock`, so pausing, extending and expiring behave like the rest
//  of the game.
//

import SpriteKit

extension GameScene {

    static let endlessIIPaddlePowerUpDuration: TimeInterval = 10

    /// How many paddle hits one collection of a paddle power-up lasts.
    ///
    /// The whole batch is turn-based rather than timed - like the sticky paddle, which is
    /// the request play-testing made in as many words. A power-up you spend by using reads
    /// differently from one that evaporates while the ball is away at the top of the field.
    static let endlessIIPaddlePowerUpTurns: TimeInterval = 5

    // MARK: - Collection

    func endlessIICollectAimedSticky() {
        endlessIIAimedStickyClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
        endlessIIInertPaddleClock.reset()
        endlessIIFlippedAngleClock.reset()
        // **Aimed Sticky cancels the angle-benders, and they cancel it** (James's rule,
        // round 99): an aimed launch and a paddle that ignores or flips where it was struck
        // are answers to the same question, and running both is one lying about the other.
        // Most recent wins. Portal Paddle stays compatible with all of them - its rules
        // apply from the top of the screen, not from the paddle
    }

    /// Cancels Aimed Sticky because an angle-bender was collected over it.
    ///
    /// The clock stops, so no *future* catch is aimed - but a hold the player is in right
    /// now keeps its launch, through the same owed-hold flag an expired clock uses. A ball
    /// sitting on the paddle mid-aim with the aim machinery torn down would never leave.
    func endlessIICancelAimedSticky() {
        guard endlessIIAimedStickyClock.isRunning || endlessIIAimedStickyOwedTurn else { return }
        if endlessIIAimHold || endlessIINextHeldBall != nil {
            endlessIIAimOwedHold = true
        }
        endlessIIAimedStickyClock.reset()
        endlessIIAimedStickyOwedTurn = false
    }

    func endlessIICollectMagnetism() {
        endlessIIMagnetismClock.collect(GameScene.endlessIIPaddlePowerUpTurns,
                                        deepestLevel: EndlessIIPaddleEffects.magnetismStrength.count - 1)
    }

    func endlessIICollectPortalPaddle() {
        endlessIIPortalPaddleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectPaddleHalo() {
        endlessIIPaddleHaloClock.collect(GameScene.endlessIIPaddlePowerUpTurns,
                                         deepestLevel: EndlessIIPaddleEffects.haloReach.count - 1)
    }

    func endlessIICollectBallSteering() {
        endlessIIBallSteeringClock.collect(GameScene.endlessIIPaddlePowerUpDuration)
        // Timed, alone in this batch (play-test round 15). Turns are the right unit for a
        // power-up that acts *on* a paddle hit; steering acts continuously between them,
        // and counting hits meant the effect ended in the middle of using it
    }

    // MARK: - Shaped paddle faces

    /// Gives the paddle a shaped top for the next few turns (§12.0).
    ///
    /// One shape at a time: a paddle cannot be domed and dished at once, so the later
    /// collection replaces the earlier and the turns start again. Nothing else in the paddle
    /// group needs a conflict rule against these, which is the part worth knowing - a shape
    /// only decides *where the ball behaves as though it landed*, so Inert Paddle still
    /// flattens it (influence zero hears nothing the shape says), Flipped Angle still mirrors
    /// it, and Auto-Aim still overrides it, because the aim replaces the angle afterwards.
    func endlessIICollectPaddleSurface(_ surface: PaddleBounce.Surface) {
        endlessIIPaddleSurface = surface
        endlessIIPaddleSurfaceClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
        showEndlessIIPaddleSurface()
    }

    // MARK: - The shape the ball actually meets

    /// The art for a shape, or nil where James has not drawn one yet.
    ///
    /// The theme is ignored for now: the first set is the classic paddle's, and James asked
    /// for it to stand in for every theme until the rest are drawn. When they arrive this
    /// becomes the theme's own prefix instead of `regular`.
    func endlessIIPaddleShapeTextureName(_ surface: PaddleBounce.Surface) -> String? {
        switch surface {
        case .convex: return "regularPaddleConvex"
        case .concave: return "regularPaddleConcave"
        case .wavy: return "regularPaddleWave"
        case .jagged: return nil
            // Retired (round 213). No art was drawn for it and none will be
        }
    }

    /// Puts the shaped art on the paddle and rebuilds its body to match, or takes both away.
    ///
    /// **The body is the picture** (James, round 213: "the paddle physics body should match
    /// the shape of the new paddle textures... when these paddles are enabled, the ball
    /// physics is determined by the shape of the paddle, not the ball angle calculations").
    /// The paddle's body has always been built with `SKPhysicsBody(texture:size:)`, which
    /// traces the artwork's own silhouette - so swapping the texture and rebuilding is all it
    /// takes for the engine to start bouncing the ball off a dome or a dish.
    ///
    /// **The bottom stays put.** The shapes are drawn at the paddle's width and their own
    /// height - a convex face is half as tall again - so the sprite grows and the node rises
    /// by half the growth, which leaves the underside exactly on the line it was on. The body
    /// is centred on the node, so it moves with the art rather than away from it.
    func refreshEndlessIIPaddleShapeArt() {
        let running = endlessIIPaddleSurfaceClock.isRunning
        let wanted = running ? endlessIIPaddleSurface.flatMap {
            endlessIIPaddleShapeTextureName($0)
        } : nil

        let width = paddle.size.width
        guard wanted != endlessIIPaddleShapeArtName
                || (wanted != nil && abs(width - endlessIIPaddleShapeBodyWidth) > 0.5)
        else { return }
        // Every frame, and does nothing on almost all of them - but a *resize* counts as a
        // change too (James, round 214: "how do the paddle shapes deal with the expand and
        // shrink power-ups?"). Expand and Shrink write `paddle.size.width` directly, and the
        // body is traced from the picture at a given size: without this the sprite grew and
        // the body it bounces off did not, so a wider domed paddle had a narrower dome inside
        // it that the ball passed straight through at the ends

        endlessIIPaddleShapeArtName = wanted
        paddle.position.y -= endlessIIPaddleShapeLift
        endlessIIPaddleShapeLift = 0
        // Whatever the last shape raised the paddle by is given back first, so the shapes
        // cannot stack their lifts on top of each other

        let texture = wanted.map { SKTexture(imageNamed: $0) } ?? paddleTexture
        let grown = wanted == nil ? paddleHeight
            : paddleHeight*(texture.size().height/max(1, paddleTexture.size().height))

        paddle.texture = texture
        paddle.size = CGSize(width: width, height: grown)
        endlessIIPaddleShapeBodyWidth = width

        if wanted != nil {
            paddle.centerRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            // **A shaped paddle is stretched whole, not nine-sliced.** `paddleCapRect` is
            // written in the *plain* art's unit coordinates - 80 wide with 10pt caps - and a
            // shaped picture is a different size, so those fractions would protect the wrong
            // strips of it. Stretching the whole texture is also the honest reading of what a
            // wider shape is: a wider dome, not a dome with flat pieces let into its ends
        }
        endlessIIPaddleShapeLift = (grown - paddleHeight)/2
        paddle.position.y += endlessIIPaddleShapeLift

        rebuildEndlessIIPaddleBody()
    }

    /// Traces the paddle's current picture, and keeps everything the old body was carrying.
    func rebuildEndlessIIPaddleBody() {
        guard let texture = paddle.texture, let old = paddle.physicsBody else { return }
        let body = SKPhysicsBody(texture: texture, size: paddle.size)
            ?? SKPhysicsBody(rectangleOf: paddle.size)
        body.allowsRotation = false
        body.friction = 0
        body.affectedByGravity = false
        body.isDynamic = true
        body.pinned = old.pinned
        body.restitution = old.restitution
        body.linearDamping = old.linearDamping
        body.categoryBitMask = old.categoryBitMask
        body.collisionBitMask = old.collisionBitMask
        body.contactTestBitMask = old.contactTestBitMask
        paddle.physicsBody = body
        // Copied off the old one rather than written out again: the paddle's masks are set in
        // one place at setup and a second copy here would be wrong the first time they change
    }

    /// Whether the shape - rather than the angle formula - is deciding this bounce.
    var endlessIIShapeOwnsTheBounce: Bool {
        endlessIIPaddleSurfaceClock.isRunning && endlessIIPaddleShapeArtName != nil
    }

    /// Tidies up what the engine's reflection off a shaped face gave, without replacing it.
    ///
    /// The engine has already bounced the ball off the silhouette by the time a contact is
    /// reported (§8.6), so the *direction* here is the shape's answer and is left alone. Two
    /// things still have to hold, because they are true of every paddle bounce in the game and
    /// nothing about a shape changes them: the ball leaves at the run's own speed, and never
    /// so flat that it runs sideways across the field for seconds at a time.
    @discardableResult
    func endlessIIApplyShapedBounce(to subject: SKSpriteNode) -> Bool {
        guard endlessIIShapeOwnsTheBounce, let body = subject.physicsBody else { return false }
        let velocity = body.velocity
        let speed = hypot(velocity.dx, velocity.dy)
        guard speed > 0 else { return false }

        var angle = atan2(Double(velocity.dy), Double(velocity.dx))
        let minimum = minAngleDeg*Double.pi/180
        if angle < 0 { angle = -angle }
        // Upward, always: a dome can reflect a ball down its own side, and a paddle that
        // returned the ball *into* the floor would be a shape that loses the run
        angle = min(max(angle, minimum), Double.pi - minimum)

        body.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                 dy: sin(angle)*Double(ballSpeedLimit))
        return true
    }

    /// Draws the shape over the paddle's top, so the face can be read rather than guessed.
    ///
    /// A curve along the top edge, in the harmful pink these power-ups wear, redrawn whenever
    /// the paddle changes size. It is a picture of the very function the bounce uses - the
    /// same `shaped` call, sampled across the width - so the drawing cannot promise a face
    /// the bounce does not give.
    func showEndlessIIPaddleSurface() {
        drawEndlessIIPaddleSurface(on: paddle)
        if let mirror = childNode(withName: GameScene.endlessIIMirrorPaddleName)
            as? SKSpriteNode {
            drawEndlessIIPaddleSurface(on: mirror)
        }
        // **The mirror wears the face too** (round 211, James's parity call). It is a full
        // bounce surface that computes its angle from the same `PaddleBounce` call the paddle
        // does, so a shape it showed but did not give would be the one kind of parity worth
        // refusing - a picture of a face the bounce disagrees with. The Safety Paddle stays
        // flat and unmarked: it is furniture rather than a paddle, spends no paddle turns,
        // and answers a ball with the backstop's arithmetic on purpose
    }

    /// Draws the shape over a surface's top, so the face can be read rather than guessed.
    ///
    /// A curve along the top edge, in the harmful pink these power-ups wear, redrawn whenever
    /// the surface changes size. It is a picture of the very function the bounce uses - the
    /// same `shaped` call, sampled across the width - so the drawing cannot promise a face
    /// the bounce does not give.
    private func drawEndlessIIPaddleSurface(on host: SKSpriteNode) {
        host.childNode(withName: GameScene.paddleSurfaceName)?.removeFromParent()
        guard let surface = endlessIIPaddleSurface, endlessIIPaddleSurfaceClock.isRunning
        else { return }

        let width = host.size.width
        let height = host.size.height
        let path = CGMutablePath()
        let samples = 48
        for step in 0...samples {
            let share = Double(step)/Double(samples)
            let collision = share*2 - 1
            let x = CGFloat(collision)*width/2
            let lift = CGFloat(PaddleBounce.shaped(collision, by: surface) - collision)
            let y = height/2 + lift*height*0.45
            // The *difference* the shape makes, drawn as height: a flat paddle would be a
            // straight line, and every bump is somewhere the angle disagrees with a flat face
            if step == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }

        let profile = SKShapeNode(path: path)
        profile.name = GameScene.paddleSurfaceName
        profile.strokeColor = GameScene.endlessIIPaddleSurfaceColour
        profile.lineWidth = max(2, height*0.22)
        profile.lineCap = .round
        profile.zPosition = 1
        host.addChild(profile)
    }

    static let paddleSurfaceName = "endlessIIPaddleSurface"
    static let endlessIIPaddleSurfaceColour = UIColor(red: 1, green: 0.22, blue: 0.62, alpha: 1)

    /// Takes the shape away when its turns run out.
    func refreshEndlessIIPaddleSurface() {
        refreshEndlessIIPaddleShapeArt()
        guard endlessIIPaddleSurface != nil else { return }
        if endlessIIPaddleSurfaceClock.isRunning == false {
            endlessIIPaddleSurface = nil
            paddle.childNode(withName: GameScene.paddleSurfaceName)?.removeFromParent()
            childNode(withName: GameScene.endlessIIMirrorPaddleName)?
                .childNode(withName: GameScene.paddleSurfaceName)?.removeFromParent()
            // The mirror's copy goes with it, or a mirror outliving the shape keeps showing
            // a face neither surface has any more
        }
    }

    func endlessIICollectInertPaddle() {
        endlessIIInertPaddleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
        endlessIIFlippedAngleClock.reset()
        endlessIICancelAimedSticky()
        // Most recent wins across the whole angle group: Inert replaces Flipped as well as
        // Aimed Sticky, or a full flip would hide behind a dead paddle and reappear when it
        // expired - two bad power-ups queueing up instead of one
    }

    func endlessIICollectFlippedAngle() {
        endlessIIFlippedAngleClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
        endlessIIInertPaddleClock.reset()
        endlessIICancelAimedSticky()
    }

    func endlessIICollectReversedControls() {
        endlessIIReversedControlsClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    func endlessIICollectAutoAim() {
        endlessIIAutoAimClock.collect(GameScene.endlessIIPaddlePowerUpTurns)
    }

    /// The power-ups a free shot should not be spent on - the bad ones, by the same
    /// judgement the reference page prints. Derived from the multiplier column rather than
    /// listed, so a new bad power-up is excluded the day it exists.
    static let endlessIIHarmfulPowerUps: Set<Int> = {
        var harmful = Set(LevelPackSetup().powerUpMultiplierArray.enumerated()
            .filter { $0.element == "-0.1" }
            .map { $0.offset })
        harmful.insert(1)
        // Lose A Ball's multiplier chip is blank - losing the ball speaks for itself - so
        // the derivation misses the single worst thing a free shot could set off
        return harmful
    }()

    /// The brick an Auto-Aim bounce goes for: the lowest on the field, nearest first among
    /// equals - the one that is threatening the run, which is the one worth a free shot.
    ///
    /// Only bricks worth the shot: never a Portal or an Indestructible, which the ball
    /// cannot destroy, and never a brick holding a bad power-up - a free shot that sets off
    /// a Lose A Ball is not a free shot. And only bricks the shot can actually arrive at:
    /// `endlessIIAimCanReach` keeps the marker's promise and the shot's delivery the same
    /// thing, which is why the marker and the redirect both choose through here.
    func endlessIIAutoAimTarget(from origin: CGPoint) -> CGPoint? {
        var best: (position: CGPoint, distance: CGFloat)?
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            guard self.endlessIIWorthAimingAt(brick) else { return }
            guard self.endlessIIAimCanReach(node.position, from: origin) else { return }
            let distance = abs(node.position.x - origin.x)
            if let current = best {
                if node.position.y < current.position.y - 1
                    || (abs(node.position.y - current.position.y) <= 1
                        && distance < current.distance) {
                    best = (node.position, distance)
                }
            } else {
                best = (node.position, distance)
            }
        }
        return best?.position
    }

    /// Whether a shot from here can actually arrive there.
    ///
    /// The target must be above the launch point, and the straight line to it must lie
    /// inside the launchable arc. `autoAimAngle` clamps to that arc, so a brick outside it
    /// would be *marked* and then missed - the shot, bent up to the minimum angle, sails
    /// past underneath it. A brick the arc cannot reach is simply not a target; a higher
    /// brick the shot can reach is a better use of the bounce than a promised miss.
    func endlessIIAimCanReach(_ target: CGPoint, from origin: CGPoint) -> Bool {
        let dy = Double(target.y - origin.y)
        guard dy > 0 else { return false }
        let angleDeg = atan2(dy, Double(target.x - origin.x))*180/Double.pi
        return angleDeg >= minAngleDeg && angleDeg <= 180 - minAngleDeg
    }

    /// Whether a free shot at this brick is worth taking.
    ///
    /// Auto-Aim spends a bounce. Spending it on something the shot cannot change is worse
    /// than not aiming at all, because the player gave up the bounce they would have had
    /// (play-test round 11 asked for exactly this list, and round 22 finished it):
    ///
    /// - **Portals and Indestructibles.** The ball cannot destroy either.
    /// - **A brick holding a bad power-up.** A free shot that sets off Lose A Ball is not a
    ///   free shot.
    /// - **A brick that is passable right now.** A Flashing brick in its faded phase has no
    ///   collision category at all, so the shot would go straight through it.
    /// - **A Directional brick that can only be hurt from the top.** A shot from the paddle
    ///   arrives at the underside. Left and right are left in: a brick up and to one side
    ///   can be met on its flank, so those shots are not wasted.
    func endlessIIWorthAimingAt(_ brick: SKSpriteNode) -> Bool {
        guard brick.parent != nil, brick.isHidden == false else { return false }
        guard brick.endlessIIRole != .portal else { return false }
        guard brick.texture != brickIndestructible1Texture,
              brick.texture != brickIndestructible2Texture else { return false }
        if let held = brick.endlessIIPowerUpIndex,
           GameScene.endlessIIHarmfulPowerUps.contains(held) { return false }
        if let body = brick.physicsBody, body.categoryBitMask == 0 { return false }
        if brick.endlessIIRole == .directional,
           brick.endlessIIVulnerableSide == .top { return false }
        return true
    }

    /// A ring drawn on the brick Auto-Aim would send the next bounce at.
    ///
    /// The shot itself already draws a beam, but that is after the fact - by the time it is
    /// visible the bounce has happened. This says where the free shot is *going* while there
    /// is still a decision to make about where to stand (play-test round 11's "subtle graphic
    /// showing the general direction").
    ///
    /// Driven from `update` rather than by an action on the brick, because a repeating action
    /// on a brick stops the field descending for ever (§8.6).
    func refreshEndlessIIAutoAimMarker() {
        let aiming = gameMode == .endlessII
            && (endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn)
        let launch = CGPoint(x: paddle.position.x,
                             y: paddle.position.y + paddleHeight/2 + ball.size.height/2)
        // Where the next bounce will leave from - the reachability check needs a height as
        // well as an x, so the marker judges the shot from the same spot the shot takes
        let target = aiming ? endlessIIAutoAimTarget(from: launch) : nil

        guard let target else {
            childNode(withName: GameScene.autoAimMarkerName)?.removeFromParent()
            return
        }

        let marker: SKShapeNode
        if let existing = childNode(withName: GameScene.autoAimMarkerName) as? SKShapeNode {
            marker = existing
        } else {
            marker = SKShapeNode(circleOfRadius: brickHeight*0.55)
            marker.name = GameScene.autoAimMarkerName
            marker.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.9)
            marker.lineWidth = 3
            marker.glowWidth = 3
            marker.fillColor = .clear
            // Prominent on purpose (§12.0): at 0.55 alpha and a hairline the ring read as
            // field dressing, and the one thing a free shot needs is a legible target
            marker.zPosition = 4
            addChild(marker)
        }
        marker.position = target
    }

    static let autoAimMarkerName = "endlessIIAutoAimMarker"

    /// Sends a ball leaving the paddle at the lowest brick instead of wherever it was going.
    /// Returns whether it did - asked at the end of the bounce, so it overrides the angle
    /// but not the catches, the swallow, or anything else the paddle decided first.
    func endlessIIApplyAutoAim(to subject: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII,
              endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn
        else { return false }
        endlessIIAutoAimOwedTurn = false
        // The last turn still aims - the turn that expired the clock is this bounce
        guard let target = endlessIIAutoAimTarget(from: subject.position) else { return false }
        guard let angle = EndlessIIPaddleEffects.autoAimAngle(
            from: subject.position, to: target, minimumDeg: minAngleDeg) else { return false }

        subject.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                                 dy: sin(angle)*Double(ballSpeedLimit))

        let beam = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: subject.position)
        path.addLine(to: target)
        beam.path = path
        beam.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.7)
        beam.lineWidth = 2
        beam.zPosition = 4
        addChild(beam)
        beam.run(.sequence([.fadeOut(withDuration: 0.3), .removeFromParent()]))
        // The shot drawn for a beat, so an aimed bounce reads as aimed rather than lucky

        return true
    }

    /// **A sticky catch delivers the aim it already paid for, when the ball leaves.**
    ///
    /// James, round 207: "sticky paddle overrides auto aim, so the ball doesn't hit the aimed
    /// brick. This is wrong. The ball should hit the aimed brick."
    ///
    /// The aim is asked at the end of the bounce, after every catch has returned - which is
    /// right, because a catch is the paddle deciding not to bounce at all. But the *turn* is
    /// spent on the contact, by `endlessIISpendPaddleTurns`, before anything decides what the
    /// paddle does with it. So a sticky catch was buying a turn of Auto-Aim and throwing it
    /// away, and the launch that followed left at the plain angle for where the ball happened
    /// to be sitting. The marker even kept drawing on the target the whole time it was held,
    /// promising a shot that was never going to be taken.
    ///
    /// This is the same bargain Portal Paddle and Sticky Paddle already struck twice (rounds
    /// 128 and 150): **the two speak in sequence rather than one cancelling the other.** The
    /// catch wins the contact - a held ball is held - and the aim owns the launch.
    ///
    /// Owed rather than merely running, so the aim is delivered exactly when it was paid for.
    /// The first launch of a life spends no turn and so takes no aim, which is the same answer
    /// the ordinary bounce gives: an aim costs a paddle contact, and the first launch is not
    /// one.
    ///
    /// **Aimed Sticky is deliberately not routed through here.** Its launch is its own path
    /// (`endlessIIAimLaunch`), and a power-up whose whole purpose is letting the player choose
    /// the shot must not have the choice taken back off them by the automatic one.
    func endlessIIAimTheStickyLaunch(_ launched: SKSpriteNode) {
        guard gameMode == .endlessII, endlessIIAutoAimOwedTurn else { return }
        _ = endlessIIApplyAutoAim(to: launched)
    }

    // MARK: - The hooks the scene asks

    /// One paddle contact happened: every running paddle power-up spends a turn.
    ///
    /// Called once per genuine landing, before the catches and the portal - the contact is
    /// the turn, whatever the paddle then does with it. With Multi-Ball every ball's landing
    /// spends one, which is the price of running four balls through a five-turn power-up.
    func endlessIISpendPaddleTurns() {
        guard gameMode == .endlessII else { return }
        endlessIIPortalPaddleOwedTurn = endlessIIPortalPaddleClock.isRunning
        endlessIIAimedStickyOwedTurn = endlessIIAimedStickyClock.isRunning
        endlessIIAutoAimOwedTurn = endlessIIAutoAimClock.isRunning
        // Snapshotted before the spend: the effects these buy land later in the same
        // contact, and a clock expired by its own last turn must still deliver it

        endlessIIAimedStickyClock.spendTurn()
        endlessIIMagnetismClock.spendTurn()
        endlessIIPortalPaddleClock.spendTurn()
        endlessIIPaddleHaloClock.spendTurn()
        endlessIIInertPaddleClock.spendTurn()
        // Ball Steering is not here: it runs on time now, and spending it a turn as well
        // would end it twice as fast as its ring says
        endlessIIFlippedAngleClock.spendTurn()
        endlessIIReversedControlsClock.spendTurn()
        endlessIIAutoAimClock.spendTurn()
        endlessIIPaddleSurfaceClock.spendTurn()
        endlessIIDoublePaddleClock.spendTurn()
        endlessIIMirrorPaddleClock.spendTurn()
        endlessIIBallSpinClock.spendTurn()
        // On hits since round 180 (James: "it doesn't ever end. This should be based on
        // paddle hits, not timed") - both had been 12-second clocks that no loop ran down
        endlessIISpendLandingTurn()
    }

    /// What multiplies the paddle's angular influence on a bounce - see `paddleHit`.
    var endlessIIPaddleAngleInfluence: Double {
        EndlessIIPaddleEffects.angleInfluence(inert: endlessIIInertPaddleClock.isRunning,
                                              flipped: endlessIIFlippedAngleClock.isRunning)
    }

    /// What multiplies the finger's movement before it reaches the paddle - see `touchesMoved`.
    var endlessIIControlDirection: CGFloat {
        EndlessIIPaddleEffects.controlDirection(reversed: endlessIIReversedControlsClock.isRunning)
    }

    /// Notes that a ball has entered a Portal Paddle, to re-enter at the top.
    ///
    /// Deferred rather than done: this is called from inside a contact, and a position
    /// written there is undone by the rest of the step (§8.6). Returns whether the paddle
    /// took the ball, so the caller skips the bounce it would otherwise be correcting.
    func endlessIIPaddlePortalTook(_ subject: SKSpriteNode, collision: Double) -> Bool {
        guard gameMode == .endlessII,
              endlessIIPortalPaddleClock.isRunning || endlessIIPortalPaddleOwedTurn
        else { return false }
        endlessIIPortalPaddleOwedTurn = false
        endlessIIPendingPaddlePortals.append(subject)
        endlessIIPendingPortalCollisions[ObjectIdentifier(subject)] = collision
        // Where on the paddle the ball went through, kept for the exit: the re-entry
        // angle is the bounce this spot would have given (play test: the ball just
        // carried on, and the portal gave no control)
        if hapticsSetting { mediumHaptic.impactOccurred() }
        return true
    }

    /// Puts every ball the paddle swallowed this step back in at the top.
    ///
    /// Runs from `didSimulatePhysics`. The horizontal velocity is kept and the vertical one
    /// points down (§5.4) - the ball falls back into the field from above, which is the whole
    /// gift: everything between the paddle and the top is skipped.
    func applyEndlessIIPaddlePortals() {
        guard endlessIIPendingPaddlePortals.isEmpty == false else { return }
        let exits = endlessIIPendingPaddlePortals
        endlessIIPendingPaddlePortals.removeAll()

        for subject in exits {
            guard subject.parent != nil, let body = subject.physicsBody else { continue }
            let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity
                ?? body.velocity
            // The velocity it entered with, sampled before the engine's own bounce - the
            // reported one has already been turned round (§8.6)

            let collision = endlessIIPendingPortalCollisions
                .removeValue(forKey: ObjectIdentifier(subject)) ?? 0
            let speed = Double(max(hypot(arriving.dx, arriving.dy), ballSpeedLimit))
            let angleDeg = PaddleBounce.angleDegrees(
                arriving: arriving, collision: collision, adjustmentK: angleAdjustmentK,
                influence: endlessIIPaddleAngleInfluence, minimumDeg: minAngleDeg)
            let angleRad = angleDeg*Double.pi/180
            // The bounce this spot on the paddle would have given (the same formula
            // paddleHit uses), so where the ball goes through decides where it comes
            // out - the play test found the pass-through gave no control at all

            if subject === ball { crookedBallNote("paddle-portal") }
            if let portal = endlessIIPortals().randomElement() {
                let from = subject.position
                subject.position = CGPoint(x: portal.position.x,
                                           y: portal.frame.maxY + subject.size.height)
                body.velocity = CGVector(dx: cos(angleRad)*speed, dy: sin(angleRad)*speed)
                endlessIIShowPortalJump(from: from, to: subject.position)
                portal.run(.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                                      .fadeAlpha(to: 1, duration: 0.12)]))
                // The network: with Portal bricks in play the paddle connects to them, one
                // chosen at random, and the ball climbs out of the brick into the field
            } else {
                subject.position = CGPoint(x: subject.position.x,
                                           y: frame.height/2 - topScreenBlock.size.height
                                              - subject.size.height)
                body.velocity = CGVector(dx: cos(angleRad)*speed, dy: -sin(angleRad)*speed)
                // On its own the paddle's portal exits at the top, falling back in - the
                // bounce angle mirrored downward
            }

            if endlessIIAutoAimClock.isRunning || endlessIIAutoAimOwedTurn,
               let target = endlessIIAutoAimTarget(from: subject.position) {
                endlessIIAutoAimOwedTurn = false
                let dx = Double(target.x - subject.position.x)
                let dy = Double(target.y - subject.position.y)
                let length = max(hypot(dx, dy), 1)
                body.velocity = CGVector(dx: dx/length*speed, dy: dy/length*speed)
                // Portal Paddle × Auto-Aim (§12.0): both speak in sequence - the hit
                // still portals, and the aim owns the *re-entry*, pointed at the lowest
                // brick worth hitting. Together they were cancelling out: the aim set
                // the launch and the portal threw it away
            }
        }
    }

    // MARK: - Each frame


    /// Runs the batch's clocks down and drives the halo. Called from `update`.
    ///
    /// The clocks and the halo live here; magnetism, steering and the paddle portals write
    /// to physics bodies, so they run from `didSimulatePhysics` instead - the one place such
    /// writes stick (§8.6). The frame's delta is kept for them.
    func tickEndlessIIPaddlePowerUps(_ currentTime: TimeInterval) {
        refreshEndlessIIPaddleSurface()
        refreshEndlessIIDoublePaddle()
        tickEndlessIIMirrorPaddle()
        // Takes the shape away the moment its last turn is spent, and leaves the paddle's
        // own face behind
        guard gameMode == .endlessII else { return }

        let delta = endlessIIPaddleLastTick == 0 ? 0
            : min(currentTime - endlessIIPaddleLastTick, 0.5)
        endlessIIPaddleLastTick = currentTime
        endlessIIPaddleFrameDelta = delta
        tickEndlessIIPaddleTravel(delta)
        tickEndlessIIAimHold()
        // A freeze with nothing left to aim is a game that has stopped - see the backstop
        // How fast the paddle is moving, sampled here rather than read at the contact - see
        // EndlessIIBallSpin for why the contact's reading is the wrong one

        if gameState.currentState is Playing && isPaused == false {
            tickEndlessIIPaddleHalo()
        }
        tickEndlessIIPaddleDressing()
        if gameState.currentState is Playing && isPaused == false {
            endlessIIBallSteeringClock.run(down: endlessIIClockDelta)
        }
        // The rest of the batch counts paddle hits, spent in `endlessIISpendPaddleTurns`.
        // Ball Steering is the exception: it acts continuously rather than on contact, so
        // it runs on the clock (play-test round 15)

        if endlessIIPaddleHaloClock.isRunning == false {
            endlessIIPaddleHaloNode?.removeFromParent()
            endlessIIPaddleHaloNode = nil
            endlessIIPaddleHaloDrawnReach = 0
            // **The drawn reach must die with the node** (play-test round 98: "I picked up
            // the halo whilst I had it and the halo disappeared"). Left stale, the next
            // collection at the same level computes the same reach, the rebuilt-only-when-
            // it-changes check sees no change, and the fresh node is given no path at all -
            // an invisible halo that still destroys bricks, because the destruction reads
            // `reach` and never the path
        }
    }

    /// The body-writing effects, from `didSimulatePhysics`.
    func applyEndlessIIPaddlePhysics() {
        guard gameMode == .endlessII else { return }
        applyEndlessIIPaddlePortals()
        guard gameState.currentState is Playing, isPaused == false else { return }
        applyEndlessIIMagnetism(endlessIIPaddleFrameDelta)
        applyEndlessIIBallSteering()
    }

    private func applyEndlessIIMagnetism(_ delta: TimeInterval) {
        guard endlessIIMagnetismClock.isRunning else { return }
        let strength = EndlessIIPaddleEffects.magnetismStrength[
            min(endlessIIMagnetismClock.level, EndlessIIPaddleEffects.magnetismStrength.count - 1)]

        let pullCeiling = finalBrickRowHeight + brickHeight*2
        // The pull only wakes once the ball is below the field's bottom couple of rows
        // (play test: it started drawing the ball in far too early) - the magnet is a
        // landing aid, not a tractor beam through the field

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil, let body = subject.physicsBody else { continue }
            guard subject !== ball || ballIsOnPaddle == false else { continue }
            guard subject.position.y < pullCeiling else { continue }
            body.velocity = EndlessIIPaddleEffects.magnetised(
                velocity: body.velocity, ballAt: subject.position,
                paddleAt: CGPoint(x: paddle.position.x, y: paddle.position.y),
                paddleHalfWidth: paddle.size.width/2,
                strength: strength, delta: delta)
            // The whole span is the magnet now (round 200) - the arithmetic aims at the
            // nearest reachable point of the paddle to the ball's own landing, so inertia
            // decides where on the paddle it arrives. The old fixed target a third out from
            // centre is gone, and with it both of its bugs: every ball was steered away from
            // the middle, and the landing was the magnet's choice rather than the flight's
        }
    }

    private func applyEndlessIIBallSteering() {
        guard endlessIIBallSteeringClock.isRunning else { return }

        for subject in endlessIIBallsInPlay {
            guard subject.parent != nil else { continue }
            guard subject !== ball || ballIsOnPaddle == false else { continue }
            guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { continue }
            // A held ball already rides the paddle; steering it twice doubles the ride

            subject.position.x = EndlessIIPaddleEffects.steeredTowards(
                paddleX: paddle.position.x, from: subject.position.x,
                leftWall: -gameWidth/2, rightWall: gameWidth/2,
                radius: subject.size.width/2,
                paddleSpeed: endlessIIPaddleSpeed, fieldWidth: gameWidth,
                delta: endlessIIPaddleFrameDelta)
            // The paddle's speed leads the target, which is what lets a swept paddle carry the
            // ball out to the columns beside the walls - see `steeringLead` (round 184). The
            // speed is the same per-frame sample Ball Spin takes, for the same reason

            if let body = subject.physicsBody {
                body.velocity = EndlessIIPaddleEffects.steeredVelocity(
                    body.velocity, delta: endlessIIPaddleFrameDelta)
            }
            // The ball is drawn to the paddle's column and its sideways momentum bleeds
            // away into vertical, so it forgets the trajectory it arrived on. Bricks and
            // walls still bounce it - the bounce simply does not last, because the pull
            // gathers it back in over the next few frames (play-test round 15)
        }
    }

    /// Where the halo sits: the middle of the field, at the paddle's height.
    ///
    /// **Fixed rather than carried** (James, round 184: "the paddle halo power up is much too
    /// powerful. Just moving the paddle side to side allows the player to gain a lot of height
    /// quickly. Perhaps the halo should be fixed to the centre of the game view, so it just
    /// clears bricks near the centre from the first few rows"). Riding the paddle turned a
    /// power-up into a technique: sweeping side to side swept the glow across the whole width
    /// of the field, which cleared the bottom rows as fast as the player could waggle a thumb -
    /// and in a mode where the bottom rows are what the height is made of, that is the run
    /// being played for you.
    ///
    /// Standing still it is still worth having and still asks something of the player: the
    /// bricks it reaches are the ones that come to *it*, so the value is in what the field
    /// happens to bring over the middle rather than in how fast a thumb moves.
    var endlessIIPaddleHaloCentre: CGPoint {
        CGPoint(x: 0, y: paddle.position.y)
    }

    private func tickEndlessIIPaddleHalo() {
        guard endlessIIPaddleHaloClock.isRunning else { return }
        let reach = paddleWidth*EndlessIIPaddleEffects.haloReach[
            min(endlessIIPaddleHaloClock.level, EndlessIIPaddleEffects.haloReach.count - 1)]
        // **The paddle's nominal width, not its current one** (play-test round 39). Measured
        // from the live paddle, a Shrink Paddle took the halo down with it and it stopped
        // reaching the bricks - so the two bad power-ups compounded into one that switched a
        // good one off. The halo is a field the paddle projects rather than part of the
        // paddle, and how far it reaches is not the paddle's business

        let halo = endlessIIPaddleHaloNode ?? {
            let node = SKShapeNode()
            node.fillColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.14)
            node.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.45)
            node.lineWidth = 1.5
            node.zPosition = 2
            addChild(node)
            endlessIIPaddleHaloNode = node
            return node
        }()

        if abs(endlessIIPaddleHaloDrawnReach - reach) > 0.5 {
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: reach, startAngle: 0, endAngle: .pi,
                        clockwise: false)
            path.closeSubpath()
            halo.path = path
            endlessIIPaddleHaloDrawnReach = reach
            // Rebuilt only when the reach changes - a fresh CGPath per frame for a shape
            // that is almost always the same size is the kind of habit update loops die of
        }
        halo.position = endlessIIPaddleHaloCentre

        var destroyed = false
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.parent != nil else { return }
            guard brick.endlessIIRole != .portal else { return }
            guard brick.endlessIIPowerUpIndex == nil else { return }
            // A Portal is not destructible by anything, and a power-up brick is spent by
            // being *hit* - a halo that silently ate one would eat the power-up with it
            guard EndlessIIPaddleEffects.haloTouches(brick: brick.frame,
                                                     paddleAt: self.endlessIIPaddleHaloCentre,
                                                     reach: reach) else { return }
            self.endlessIIBrickDestroyed(brick)
            self.endlessIIDestroy(brick)
            destroyed = true
            // The same pair a crushed brick goes through: the roles react - an Exploding
            // brick caught by the glow still explodes - and then it is gone, scored, with
            // no power-up roll. A glow that showered power-ups would be a farm
        }
        if destroyed {
            countBricks()
            if hapticsSetting { lightHaptic.impactOccurred(intensity: 0.5) }
        }
    }

    static let endlessIIHaloColour = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)

    // MARK: - The ring HUD

    func endlessIIPaddleRingEntries() -> [PowerUpRingHUD.Entry] {
        let clocks: [(String, EndlessIIClock, UIImage)] = [
            ("endlessIIAimedSticky", endlessIIAimedStickyClock, PowerUpIcon.hud("AimedStickyIcon", PowerUpIcon.aimedSticky)),
            ("endlessIIMagnetism", endlessIIMagnetismClock, PowerUpIcon.magnetism),
            ("endlessIIPortalPaddle", endlessIIPortalPaddleClock, PowerUpIcon.portalPaddle),
            ("endlessIIPaddleHalo", endlessIIPaddleHaloClock, PowerUpIcon.hud("PaddleHaloIcon", PowerUpIcon.paddleHalo)),
            ("endlessIIBallSteering", endlessIIBallSteeringClock, PowerUpIcon.ballSteering),
            ("endlessIIInertPaddle", endlessIIInertPaddleClock, PowerUpIcon.hud("InertPaddleIcon", PowerUpIcon.inertPaddle)),
            ("endlessIIFlippedAngle", endlessIIFlippedAngleClock, PowerUpIcon.hud("FlippedAngleIcon", PowerUpIcon.flippedAngle)),
            ("endlessIIReversedControls", endlessIIReversedControlsClock, PowerUpIcon.hud("ReversedControlsIcon", PowerUpIcon.reversedControls)),
            ("endlessIIAutoAim", endlessIIAutoAimClock, PowerUpIcon.autoAim),
            ("endlessIIPaddleSurface", endlessIIPaddleSurfaceClock,
             PowerUpIcon.paddleSurface(endlessIIPaddleSurface ?? .convex)),
            ("endlessIIDoublePaddle", endlessIIDoublePaddleClock,
             PowerUpIcon.hud("DoublePaddleIcon", PowerUpIcon.doublePaddle)),
            ("endlessIIMirrorPaddle", endlessIIMirrorPaddleClock,
             PowerUpIcon.hud("MirrorPaddleIcon", PowerUpIcon.mirrorPaddle)),
            // Round art for the ring, drawn rather than derived (round 210's delivery). The
            // badge stays as the fallback, so a build without it looks exactly as it did
            ("endlessIIBallSpin", endlessIIBallSpinClock, PowerUpIcon.ballSpin),
        ]
        return clocks.compactMap { id, clock, icon in
            guard clock.isRunning else { return nil }
            return PowerUpRingHUD.Entry(id: id, texture: SKTexture(image: icon),
                                        remaining: clock.fraction,
                                        segments: Int(clock.total))
            // Segmented like the sticky paddle's ring: five marks say "five turns" where a
            // smooth arc only says "most of it"
        }
    }

    // MARK: - Saving

    /// Every running clock, in the form the save's active-power-up arrays hold.
    ///
    /// The id doubles as the save key, so a clock that is added to the ring is saved and
    /// restored with no third list to keep in step.
    func endlessIIPaddleClockSaveEntries() -> [(key: String, remaining: Double, total: Double,
                                                magnitude: Int)] {
        [("endlessIIAimedSticky", endlessIIAimedStickyClock),
         ("endlessIIMagnetism", endlessIIMagnetismClock),
         ("endlessIIPortalPaddle", endlessIIPortalPaddleClock),
         ("endlessIIPaddleHalo", endlessIIPaddleHaloClock),
         ("endlessIIBallSteering", endlessIIBallSteeringClock),
         ("endlessIIInertPaddle", endlessIIInertPaddleClock),
         ("endlessIIFlippedAngle", endlessIIFlippedAngleClock),
         ("endlessIIReversedControls", endlessIIReversedControlsClock),
         ("endlessIIAutoAim", endlessIIAutoAimClock),
         ("endlessIIPaddleSurface", endlessIIPaddleSurfaceClock),
         ("endlessIIDoublePaddle", endlessIIDoublePaddleClock),
         ("endlessIIMirrorPaddle", endlessIIMirrorPaddleClock),
         ("endlessIIBallSpin", endlessIIBallSpinClock)]
            .filter { $0.1.isRunning }
            .map { ($0.0, $0.1.remaining, $0.1.total, $0.1.level) }
    }

    /// Puts one saved clock back, if the key is one of this batch's. Returns whether it was.
    @discardableResult
    func endlessIIRestorePaddleClock(key: String, remaining: Double, total: Double,
                                     magnitude: Int) -> Bool {
        switch key {
        case "endlessIIAimedSticky":
            endlessIIAimedStickyClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIMagnetism":
            endlessIIMagnetismClock.restore(remaining: remaining, total: total,
                                            level: magnitude,
                                            deepestLevel: EndlessIIPaddleEffects.magnetismStrength.count - 1)
        case "endlessIIPortalPaddle":
            endlessIIPortalPaddleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIPaddleHalo":
            endlessIIPaddleHaloClock.restore(remaining: remaining, total: total,
                                             level: magnitude,
                                             deepestLevel: EndlessIIPaddleEffects.haloReach.count - 1)
        case "endlessIIBallSteering":
            endlessIIBallSteeringClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIInertPaddle":
            endlessIIInertPaddleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIFlippedAngle":
            endlessIIFlippedAngleClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIReversedControls":
            endlessIIReversedControlsClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIAutoAim":
            endlessIIAutoAimClock.restore(remaining: remaining, total: total, level: 0)
        case "endlessIIPaddleSurface":
            endlessIIPaddleSurfaceClock.restore(remaining: remaining, total: total, level: 0)
            if endlessIIPaddleSurface == nil { endlessIIPaddleSurface = .convex }
            showEndlessIIPaddleSurface()
            // Which shape is not saved, and a resumed run comes back domed. Worth a note
            // rather than a fix: the save format is shared with a shipped version, and a
            // fifth field for a fifteen-second power-up is not worth a migration
        case "endlessIIDoublePaddle":
            endlessIIDoublePaddleClock.restore(remaining: remaining, total: total, level: 0)
            refreshEndlessIIDoublePaddle()
            // Split again on the spot rather than at the next frame, so a resumed game draws
            // the paddle it is about to bounce with
        case "endlessIIMirrorPaddle":
            endlessIIMirrorPaddleClock.restore(remaining: remaining, total: total, level: 0)
            showEndlessIIMirrorPaddle()
            // Standing again on the spot, for the same reason: a resumed game draws the
            // surfaces it is about to bounce off
        case "endlessIIBallSpin":
            endlessIIBallSpinClock.restore(remaining: remaining, total: total, level: 0)
            endlessIIBallSpinClock.countsTurns = true
            // The turn flag is not in the save - what marks a restored clock as counting
            // turns is this line, the way `collect(turns:)` marks a fresh one. The curve
            // itself is deliberately *not* restored: it is spent within a second of the
            // bounce that earned it, and a resumed ball has not just been bounced
        default:
            return false
        }
        return true
    }

    /// Ends the whole batch. For the life ending and the field resetting.
    func endlessIIResetPaddlePowerUps() {
        endlessIIAimedStickyClock.reset()
        endlessIIMagnetismClock.reset()
        endlessIIPortalPaddleClock.reset()
        endlessIIPaddleHaloClock.reset()
        endlessIIBallSteeringClock.reset()
        endlessIIInertPaddleClock.reset()
        endlessIIFlippedAngleClock.reset()
        endlessIIReversedControlsClock.reset()
        endlessIIAutoAimClock.reset()
        endlessIIPaddleSurfaceClock.reset()
        endlessIIResetBallSpin()
        endlessIIDoublePaddleClock.reset()
        refreshEndlessIIDoublePaddle()
        endlessIIMirrorPaddleClock.reset()
        tickEndlessIIMirrorPaddle()
        // The tick is what takes the mirror off the field, so the reset has to run it -
        // a surface left standing after the life that earned it would change the next one
        endlessIIPaddleSurface = nil
        paddle.childNode(withName: GameScene.paddleSurfaceName)?.removeFromParent()
        endlessIIPendingPaddlePortals.removeAll()
        endlessIIPaddleHaloNode?.removeFromParent()
        endlessIIPaddleHaloNode = nil
        endlessIIPaddleHaloDrawnReach = 0
        endlessIISteeringPending = 0
        endlessIITopExitStrip?.removeFromParent()
        endlessIITopExitStrip = nil
        endlessIIPullLines.forEach { $0.removeFromParent() }
        endlessIIPullLines.removeAll()
        if paddle.colorBlendFactor != 0 { paddle.colorBlendFactor = 0 }
        endlessIIAimHold = false
        endlessIIEndAim()
        endlessIIResetBackdrop()
    }
}
