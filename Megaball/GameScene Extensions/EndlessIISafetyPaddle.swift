//
//  EndlessIISafetyPaddle.swift
//  Megaball
//
//  The Safety Paddle (§5.4): a second paddle, fixed under the lowest brick row, for a while.
//
//  Deliberately double-edged, like Gravity. It keeps the ball up in the field, which is the
//  gift; and while it is there the ball cannot reach the bricks from below, which is the
//  price. A power-up that was only a gift would be a power-up nobody has to think about.
//
//  Three decisions worth keeping, because each one was a way of getting it wrong:
//
//  - **Its own collision category.** The paddle's would have been wrong twice over: a
//    contact there spends a paddle turn and counts as a landing, and Aimed Sticky, Portal
//    Paddle and Magnetism all answer paddle contacts. A screen block's would have been wrong
//    once: `didBegin` decides which *kind* of block was struck from its shape - narrower than
//    it is tall means a side wall - so a wide, short safety paddle would have been read as
//    the ceiling and deactivated Giga-Ball on touch.
//  - **It does not descend.** The field moves and the furniture does not, which is what
//    makes it a line the player can rely on for as long as it lasts.
//  - **It is never stranded.** A surface left behind after its clock stops would change the
//    rest of the run, so it is removed by the tick that finds the clock stopped - the same
//    rule Ghost Ball has about the ball's alpha.
//

import SpriteKit

extension GameScene {

    /// How long a safety paddle stands.
    ///
    /// Longer than the field batch's clocks, because the value of this one is that you can
    /// plan around it: a surface you cannot rely on for a few shots is a surprise rather
    /// than a tool.
    static let endlessIISafetyPaddleDuration = GameScene.endlessIIPaddlePowerUpDuration

    /// How much of the field it used to span, before round 184.
    ///
    /// Kept as the note it earned rather than as a number in use: the width was a share of
    /// the *field* (0.42), chosen so it was "a little wider than the paddle and nothing like
    /// the whole width" - it has to be possible to get past it, or the bricks are unreachable
    /// for twelve seconds and the run simply stops. James's round-184 call takes it to the
    /// paddle's own width, which honours that reasoning more exactly than a fixed share
    /// could: the paddle's width is what Expand and Shrink write, so the surface tracks it.
    static let endlessIISafetyPaddleLegacyWidth: CGFloat = 0.42

    static let endlessIISafetyPaddleName = "endlessIISafetyPaddle"

    /// Where it stands: one full brick row below the low-limit line.
    ///
    /// **Measured from the line the player sees, not from the row the code counts** (round
    /// 200: "safety paddle should sit one brick row width below the low level brick line").
    /// The line is drawn at `finalBrickRowHeight - brickHeight/2`, so the old
    /// `finalBrickRowHeight - brickHeight` put the bar only half a row under it - close
    /// enough that a brick arriving on the last row and the bar beneath it read as one
    /// object. A row of clear air keeps them two things: below the field so it never sits
    /// inside a brick, and well above the real paddle.
    var endlessIISafetyPaddleY: CGFloat { finalBrickRowHeight - brickHeight*1.5 }

    func endlessIICollectSafetyPaddle() {
        guard gameMode == .endlessII else { return }
        endlessIISafetyPaddleClock.collect(GameScene.endlessIISafetyPaddleDuration)
        showEndlessIISafetyPaddle()
    }

    /// The picture the safety paddle wears: the player's own paddle, wherever it is kept.
    ///
    /// The Retro theme draws its paddle on `paddleRetroTexture` rather than on the paddle
    /// sprite, so asking the sprite would dress this as a plain bar beside a paddle that is
    /// anything but - the lesson Double Paddle learned in round 166.
    var endlessIISafetyPaddleDress: SKTexture? {
        if paddleTexture == retroPaddle, let art = paddleRetroTexture.texture { return art }
        return paddle.texture ?? paddleTexture
    }

    /// The nine-slice the paddle's picture is wearing *right now*.
    ///
    /// **Copied live, not looked up** (round 201: "the rounded edges of the safety paddle
    /// don't look the same as the main paddle"). The paddle wears the whole-texture rect at
    /// standard width and only switches to the protective cap rect when a resize stretches
    /// it (`paddleCenterRectZero`/`Plus`); the bar was wearing the cap rect always. At
    /// standard width that is two different renderings of one picture: the paddle scales its
    /// caps uniformly with everything else, the bar held them at native size. A twin has to
    /// copy the state, not the wardrobe - and this only holds because the twin is the
    /// paddle's own size; Split Paddle's *narrower* segments must keep their own rects
    /// (round 182's lesson, unchanged).
    var endlessIIPaddleDressCenterRect: CGRect {
        paddleTexture == retroPaddle ? paddleRetroTexture.centerRect : paddle.centerRect
    }

    /// Puts the surface on the field, or leaves the one already there alone.
    ///
    /// A second collection refills the clock rather than building a second paddle - which is
    /// what `extendsDuration` means in the catalogue, and what a player collecting two of
    /// them expects: longer, not thicker.
    func showEndlessIISafetyPaddle() {
        guard gameMode == .endlessII else { return }
        guard childNode(withName: GameScene.endlessIISafetyPaddleName) == nil else { return }

        let size = CGSize(width: max(20, paddle.size.width),
                          height: max(4, paddle.size.height))
        // **The paddle's own size** (James, round 184: "safety paddle should be the same
        // width as the standard paddle and look the same but be giga-ball yellow/green"). It
        // was a fixed share of the field's width, which made it a different object that
        // happened to bounce - reading it as the paddle's twin is the whole point, and it is
        // also honest about how much of the floor it really covers.
        //
        // Never zero on either axis: SpriteKit refuses a body built from an empty rectangle
        // and hands back a node with no body at all, which is a safety paddle the ball falls
        // straight through - the kind of failure that looks like the power-up doing nothing
        let bar = SKSpriteNode(texture: endlessIISafetyPaddleDress, size: size)
        bar.color = GameScene.endlessIIHaloColour
        bar.colorBlendFactor = 1
        bar.centerRect = endlessIIPaddleDressCenterRect
        // The paddle's picture, tinted the Giga-Ball lime, wearing the same nine-slice
        // state the paddle itself is wearing at this moment - see that property's note for
        // why copying the cap rect unconditionally made the ends look wrong (round 201)
        bar.name = GameScene.endlessIISafetyPaddleName
        bar.position = CGPoint(x: 0, y: endlessIISafetyPaddleY)
        bar.zPosition = 2
        bar.alpha = 0

        bar.physicsBody = endlessIISafetyPaddleBody(size: size)
        addChild(bar)

        bar.run(.fadeIn(withDuration: 0.15))
        // Faded in rather than appearing: a surface that arrives under a ball already on its
        // way down is easier to believe if it is seen arriving

        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    /// **A ball coming up from underneath goes straight through it** (James, round 166).
    ///
    /// The surface is there to keep a falling ball in the field, not to seal the bricks off
    /// from below. Blocking the climb was the "price" the power-up was written with, and in
    /// play it reads as the ball being cheated rather than as a trade: a shot from the paddle
    /// that would have reached the field bounces off a bar the player was given as a gift.
    ///
    /// Done exactly as the real paddle steps out of a ball's way - the bit is cleared on *the
    /// ball's* body rather than on the bar's, so with four balls in play each one gets its own
    /// answer. One bar cannot be solid and not solid at the same time; four balls can each be
    /// told something different about it.
    ///
    /// Solid only once a ball is *clear above* it, rather than from the moment its centre
    /// passes: a ball made solid while it still overlaps the bar is one the engine shoves out
    /// of the way, which is a jolt in the middle of a climb. On the way down that costs
    /// nothing - a descending ball is clear above the bar until the instant they touch, which
    /// is when the bounce is wanted anyway.
    func refreshEndlessIISafetyPaddleReachability() {
        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else {
            for subject in endlessIIBallsInPlay {
                setEndlessIISafetyPaddleReachable(true, for: subject)
            }
            return
            // No bar: every ball gets the bit back. Nothing would collide with it either way,
            // but a mask left cleared is a mask that lies about what the ball can hit
        }
        let top = bar.position.y + bar.size.height/2
        for subject in endlessIIBallsInPlay {
            setEndlessIISafetyPaddleReachable(subject.position.y - subject.size.height/2 >= top,
                                              for: subject)
        }
    }

    func setEndlessIISafetyPaddleReachable(_ reachable: Bool, for subject: SKSpriteNode) {
        guard let body = subject.physicsBody else { return }
        let bit = CollisionTypes.safetyPaddleCategory.rawValue

        let collision = reachable ? body.collisionBitMask | bit : body.collisionBitMask & ~bit
        let contact = reachable ? body.contactTestBitMask | bit : body.contactTestBitMask & ~bit

        if body.collisionBitMask != collision { body.collisionBitMask = collision }
        if body.contactTestBitMask != contact { body.contactTestBitMask = contact }
    }

    /// The bar's body, rebuilt whenever its size changes - the mirror's own pattern.
    /// The bar's body: a rectangle, or the shape's own silhouette while one is running.
    ///
    /// Traced only while a shape owns the bounce, for the mirror's reason (round 216): a plain
    /// bar has been a rectangle since it was built and bounces predictably because of it, and
    /// tracing the ordinary paddle picture would change how it plays for no reason anybody
    /// asked for. With a shape running the trace *is* the parity - "safety paddle is shaped to
    /// match the paddle's geometry" is the matrix's own wording, and a shaped picture over a
    /// flat body would show one face and give another.
    func endlessIISafetyPaddleBody(size: CGSize) -> SKPhysicsBody {
        endlessIISafetyPaddleBodyArt = endlessIIShapeOwnsTheBounce
            ? endlessIIPaddleShapeArtName : nil
        let body: SKPhysicsBody
        if endlessIIShapeOwnsTheBounce, let art = endlessIISafetyPaddleDress {
            body = TracedBodyCache.body(texture: art, size: size)
                ?? SKPhysicsBody(rectangleOf: size)
        } else {
            body = SKPhysicsBody(rectangleOf: size)
        }
        body.isDynamic = false
        body.affectedByGravity = false
        body.friction = 0
        body.restitution = 1
        body.categoryBitMask = CollisionTypes.safetyPaddleCategory.rawValue
        body.collisionBitMask = CollisionTypes.ballCategory.rawValue
        body.contactTestBitMask = CollisionTypes.ballCategory.rawValue
        return body
    }

    /// Takes it away, whenever the clock is not running.
    ///
    /// Called every frame rather than scheduled, because a clock can end in more ways than
    /// by running out: a Wipe ends it, and a run ending resets it.
    func tickEndlessIISafetyPaddle() {
        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return }
        guard endlessIISafetyPaddleClock.isRunning == false else {
            let wantedArt = endlessIIShapeOwnsTheBounce ? endlessIIPaddleShapeArtName : nil
            if bar.size != paddle.size || wantedArt != endlessIISafetyPaddleBodyArt,
               paddle.size.width > 0, paddle.size.height > 0 {
                bar.size = CGSize(width: paddle.size.width, height: paddle.size.height)
                bar.texture = endlessIISafetyPaddleDress
                bar.color = GameScene.endlessIIHaloColour
                bar.colorBlendFactor = 1
                bar.centerRect = endlessIIPaddleDressCenterRect
                bar.physicsBody = endlessIISafetyPaddleBody(size: bar.size)
                // **Re-dressed as well as resized** (round 224). It took the paddle's picture
                // once, at birth, so a shape collected while the bar stood left it wearing the
                // plain face. The tint has to be written back with the texture, for the
                // mirror's reason: a texture write leaves whatever colour the sprite carries.
                // The nine-slice is the paddle's own either way - round 231 found that a
                // shaped picture is the same width as the plain one, so the cap rect protects
                // the same strip on both
            }
            if bar.xScale != paddle.xScale || bar.yScale != paddle.yScale {
                bar.xScale = paddle.xScale
                bar.yScale = paddle.yScale
                // Expand and Shrink animate `xScale` and never touch `size`, so the check
                // above never fired for them - the same miss the mirror had until round 216
            }
            // **The paddle's twin follows the paddle** (round 203, the first cell of the
            // parity matrix James asked for): Expand and Shrink write the paddle's width
            // directly, and a bar that kept its birth width was the same object at a
            // different size - the mirror learned this in round 180, and the nine-slice
            // has to be re-copied with it or the fresh width stretches the old state
            return
        }
        bar.name = nil
        // Renamed first, so a second tick before the fade finishes does not queue a second
        // removal on the same node
        bar.physicsBody = nil
        bar.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
    }

    /// The ball met the safety paddle. Sends it back up the field.
    ///
    /// The backstop's arithmetic, for the same reason it exists there: a flat surface can
    /// return a ball at an angle so shallow that it runs sideways across the field for
    /// seconds at a time, and a minimum angle is what stops that. Nothing here spends a
    /// paddle turn, counts a paddle hit, or touches the aim - this is furniture the ball
    /// bounces off, and every power-up that answers a paddle contact stays out of it.
    func endlessIISafetyPaddleHit(_ subject: SKSpriteNode) {
        guard let body = subject.physicsBody else { return }
        guard body.velocity.dy < 0 else { return }
        // **A climbing ball is passing through, not bouncing** (round 200: "safety paddle is
        // setting off haptics when ball travels through it from below"). The bits that make
        // the bar solid are restored the moment a ball comes clear above it, and a ball still
        // edge-touching at that instant registers a contact - which then rang the haptic and,
        // worse, rewrote a climbing ball's velocity through the bounce arithmetic below. Only
        // a ball moving *down* has any business here
        if endlessIISafetyPaddleCaught(subject) { return }
        // **Before the sound, the haptic and the shape**, because a catch is the surface
        // deciding not to bounce at all - the same order the paddle asks its own catches in,
        // and it plays the sticky sound rather than the bounce one

        if soundsSetting { run(ballPaddleHitSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }

        if endlessIIApplyShapedBounce(to: subject) {
            endlessIIGripBall(subject)
            return
        }
        // The shape decides, exactly as it does on the paddle and on the mirror: the engine
        // has already reflected the ball off the traced silhouette, and that reflection is the
        // answer rather than something to layer a formula on top of

        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return }
        let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity ?? body.velocity
        let collision = PaddleBounce.collision(ballX: subject.position.x,
                                               paddleX: bar.position.x,
                                               paddleWidth: bar.size.width)
        let angleDeg = PaddleBounce.angleDegrees(
            arriving: arriving,
            collision: PaddleBounce.shaped(min(max(collision, -1), 1), by: endlessIIPaddleSurface),
            adjustmentK: angleAdjustmentK,
            influence: endlessIIPaddleAngleInfluence,
            minimumDeg: minAngleDeg)
        ballHorizontalControl(angleDegInput: angleDeg, for: subject)
        _ = endlessIIApplyAutoAim(to: subject)
        endlessIIGripBall(subject)
        // **It is a paddle now** (James, round 224: "go with the latest definition", against
        // his matrix giving the safety paddle the paddle's shape, its Inert Paddle, its
        // Flipped Bounce Angle, its Auto-Aim, its Random Bounce and its Ball Spin).
        //
        // Round 211 called it furniture and answered with the backstop's arithmetic on
        // purpose, which is what the first three lines of this used to be: the ball's own
        // angle, reflected, with nothing about where it landed. Every one of those five
        // power-ups needs the position back to have anything to act on - a Flipped Angle with
        // no angle to flip is a power-up that does nothing on the surface it is standing on.
        //
        // The sequence is the paddle's own, in the paddle's own order, so the two cannot drift:
        // the bend, then the control, then the aim, then the grip. Randomised Bounce needs no
        // line of its own because `ballHorizontalControl` has applied it to every corrected
        // bounce in the game since round 125 - paddle, wall, brick, backstop and this.
    }
    // MARK: - A sticky safety paddle

    /// Catches a ball on the safety bar while Sticky Paddle is running.
    ///
    /// James, round 284, answering the parity matrix's first open cell - what does a *sticky*
    /// safety paddle do with the ball it catches? "Ball goes up, like it would from the
    /// paddle." So it is the paddle's own launch, from the paddle's own arithmetic, off a
    /// different surface: a ball caught near an end leaves steeply and one caught in the middle
    /// leaves near enough straight up, exactly as `endlessIILaunchAngle` has always said.
    ///
    /// **It joins the same queue.** There is one order of launches in this mode and a second
    /// list would be a second order - a ball caught on the bar and a ball caught on the paddle
    /// go out oldest first, together, because that is the only order a player can predict.
    ///
    /// **What it does not do is ride anything.** A held ball follows the paddle because the
    /// paddle is under the player's finger; the bar stands in the middle of the field and does
    /// not move sideways at all, so a ball caught on it is simply left where it landed. That is
    /// also why the primary ball can be caught here when it cannot be caught on the paddle by
    /// this route - the 2020 code that moves it with the paddle only runs while it is *on* the
    /// paddle, and a ball resting on the bar is not.
    ///
    /// Refused outside the bar's span for the reason the paddle refuses it: the sticky band is
    /// the top face, and a ball meeting the very end of the bar has met the end of it.
    @discardableResult
    func endlessIISafetyPaddleCaught(_ subject: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, stickyPaddleCatches != 0 else { return false }
        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode else { return false }
        guard endlessIIHeldBalls.contains(where: { $0 === subject }) == false else { return false }

        let reach = bar.size.width/2 - subject.size.width/3
        guard abs(subject.position.x - bar.position.x) < reach else { return false }

        subject.physicsBody?.velocity = .zero
        subject.position.y = bar.position.y + bar.size.height/2 + subject.size.height/2
        endlessIIHeldBalls.append(subject)
        endlessIIHeldOffsets.append(subject.position.x - bar.position.x)
        endlessIISafetyHeldBalls.insert(ObjectIdentifier(subject))
        // The offset is measured from the *bar* rather than the paddle, and only the launch
        // reads it - what makes this ball different from a paddle-held one is which surface's
        // width its spot is a fraction of

        endlessIIRefreshStickyPaddleLook()
        if soundsSetting { run(stickyPaddleHitSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }
        return true
    }

    /// Whether this ball is waiting on the safety bar rather than on the paddle.
    func endlessIIIsHeldOnSafetyBar(_ subject: SKSpriteNode) -> Bool {
        endlessIISafetyHeldBalls.contains(ObjectIdentifier(subject))
    }

    /// The fraction across the safety bar a held ball is sitting at, for its launch angle.
    ///
    /// Nil when the bar has gone - a power-up can end while it is holding something, and a ball
    /// left on a bar that no longer exists has to launch by *some* rule. The caller falls back
    /// to the paddle's, which is the same answer the same arithmetic would have given from a
    /// surface the same width.
    func endlessIISafetyBarOffset(of subject: SKSpriteNode) -> Double? {
        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName)
                as? SKSpriteNode, bar.size.width > 0 else { return nil }
        return Double((subject.position.x - bar.position.x)/(bar.size.width/2))
    }

}
