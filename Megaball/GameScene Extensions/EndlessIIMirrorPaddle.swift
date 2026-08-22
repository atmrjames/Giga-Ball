//
//  EndlessIIMirrorPaddle.swift
//  Megaball
//
//  Mirror Paddle (§12.0): a second paddle, at the same height, travelling the other way.
//
//  The other half of the Double Paddle row - James's play-test idea from the second round -
//  and the half the queue priced honestly: "a second paddle is per-ball contact handling all
//  over again". Double Paddle turned out not to need any of that, because it never left the
//  one node. This one does leave it: the mirror is somewhere else on the screen, so it is a
//  real second surface with a real second contact path.
//
//  **What it does.** The mirror stands level with the paddle and holds the mirrored x: the
//  player goes left, it goes right, and the two meet in the middle. It covers the side you
//  have just abandoned, which is the whole idea - the ball you cannot reach is exactly the
//  ball it is under.
//
//  Four decisions, each of which was a way of getting it wrong:
//
//  - **Its own collision category**, the Safety Paddle's lesson applied a second time. The
//    paddle's would spend a paddle turn and count a landing, and Aimed Sticky, Portal Paddle
//    and Magnetism all answer paddle contacts - a ball caught by a power-up on a paddle the
//    player is not touching is a ball nobody can launch.
//  - **It bounces like a paddle, not like a wall.** The Safety Paddle uses the backstop's
//    arithmetic because it is furniture; this is a paddle, so it bends the bounce by where the
//    ball landed across its face, through the same `PaddleBounce` call the real one makes. A
//    mirror that returned the ball at the angle it arrived would be a moving wall.
//  - **It is not a node the rest of the game knows about.** Nothing else looks it up, and it
//    is removed by the tick that finds the clock stopped - the Safety Paddle's never-stranded
//    rule, for the same reason: a surface left behind changes the rest of the run.
//  - **It wears the paddle's own dress**, whatever that is at the time, so it reads as a
//    paddle rather than as a bar. In the Retro theme that art lives on a separate node
//    entirely, which is the trap Double Paddle fell into one round earlier.
//

import SpriteKit
import CoreImage

extension GameScene {

    /// How many paddle hits the mirror stands for.
    ///
    /// It was twelve seconds, but the seconds were never wired to any run-down loop, so the
    /// mirror simply never left and its ring never moved (James, round 180: "it wasn't
    /// counting down it's segments, it just remained on the whole time"). Paddle hits now,
    /// like the rest of the paddle batch - and hits on the *real* paddle only, because
    /// `endlessIIMirrorPaddleHit` deliberately spends nothing.
    static let endlessIIMirrorPaddleTurns = Int(GameScene.endlessIIPaddlePowerUpTurns)

    static let endlessIIMirrorPaddleName = "endlessIIMirrorPaddle"

    func endlessIICollectMirrorPaddle() {
        guard gameMode == .endlessII else { return }
        endlessIIMirrorPaddleClock.collect(turns: GameScene.endlessIIMirrorPaddleTurns)
        showEndlessIIMirrorPaddle()
    }

    /// Whether a mirror is standing.
    var endlessIIMirrorPaddleIsUp: Bool {
        gameMode == .endlessII && endlessIIMirrorPaddleClock.isRunning
    }

    /// Where the mirror stands for a paddle at `x`.
    ///
    /// Mirrored about the centre line, which is what makes it travel the other way: the
    /// player's own movement is the only thing driving it, so there is nothing to tune and
    /// nothing that can drift out of step with the finger.
    ///
    /// Pure, and tested as such - the whole of what this power-up *is* is one negation, and
    /// the rest of the file is the plumbing that keeps a second sprite honest.
    static func endlessIIMirrorPaddleX(paddleX: CGFloat) -> CGFloat { -paddleX }

    /// The mirror's tint: the Giga-Ball lime, so the pair never read as two of yours.
    static let endlessIIMirrorPaddleColour: UIColor =
        #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)

    /// Puts the mirror on the field, or leaves the one already there alone.
    ///
    /// A second collection lengthens the clock rather than building a second mirror - what
    /// `extendsDuration` means in the catalogue, and what a player collecting two expects.
    func showEndlessIIMirrorPaddle() {
        guard gameMode == .endlessII else { return }
        guard childNode(withName: GameScene.endlessIIMirrorPaddleName) == nil else { return }

        let mirror = SKSpriteNode(texture: endlessIIMirrorPaddleDress,
                                  size: CGSize(width: max(1, paddle.size.width),
                                               height: max(1, paddle.size.height)))
        // Never zero on either axis: `SKPhysicsBody(rectangleOf:)` with an empty rectangle
        // hands back a node with no body at all - a paddle the ball falls straight through,
        // which is the Safety Paddle's own trap and looks exactly like nothing happening
        mirror.centerRect = endlessIIPaddleDressCenterRect
        // The same nine-slice state the paddle is wearing right now (round 201) - without
        // it an expanded paddle's mirror stretched its rounded ends flat
        mirror.name = GameScene.endlessIIMirrorPaddleName
        mirror.position = CGPoint(x: GameScene.endlessIIMirrorPaddleX(paddleX: paddle.position.x),
                                  y: paddle.position.y)
        mirror.xScale = paddle.xScale
        mirror.yScale = paddle.yScale
        // Born already matching, so a mirror collected while Expand is running does not
        // appear small and then jump on its first tick
        mirror.zPosition = paddle.zPosition - 0.1
        mirror.color = GameScene.endlessIIMirrorPaddleColour
        mirror.colorBlendFactor = 1
        // The Giga-Ball lime, and a step behind the real paddle (James, round 180: "the
        // mirrored paddle should be a different colour (Giga-Ball green/yellow) and sit
        // behind the original paddle so it's clear which one follows the tap"). When the
        // two cross in the middle, the white one in front is yours
        mirror.alpha = 0
        mirror.physicsBody = endlessIIMirrorPaddleBody(size: mirror.size)
        addChild(mirror)

        mirror.run(.fadeIn(withDuration: 0.15))
        // Faded in rather than appearing, the Safety Paddle's reasoning: a surface arriving
        // under a ball already on its way down is easier to believe if it is seen arriving

        showEndlessIIPaddleShadow()
        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    static let endlessIIPaddleShadowName = "mirrorPaddleShadow"

    /// Hangs a soft shadow under the real paddle while the mirror runs.
    ///
    /// James, round 200: "the front white paddle should have a slight soft drop shadow so
    /// the green/yellow paddle appears behind it." Depth is what says which of two crossing
    /// paddles is yours, and colour alone stopped saying it the moment they overlapped.
    ///
    /// SpriteKit has no layer shadows, so this is the game's usual trick: the paddle's own
    /// texture again, black, mostly transparent, a little larger and a few points low, as a
    /// child of the paddle so it follows every move for free. A negative child z draws it
    /// behind the paddle's own pixels and still in front of the mirror.
    /// How far the shadow reaches past every edge of the paddle, in points.
    static let endlessIIPaddleShadowSpread: CGFloat = 9

    /// How soft it is.
    static let endlessIIPaddleShadowBlur: Double = 7

    static let endlessIIPaddleShadowAlpha: CGFloat = 0.3

    /// A soft dark spread under the paddle, so the white paddle reads against the white
    /// mirror behind it.
    ///
    /// **Centred and blurred, not offset and hard** (James, round 209: "drop shadow on the
    /// paddle with mirror paddle active is too harsh. It should be centred on the paddle with
    /// some span and blur so it appears on all edges of the paddle and is soft and subtle").
    /// Round 200 built it as a second copy of the paddle's own picture, a little larger and
    /// pushed down - which draws a hard black lip under the bottom edge and nothing at all
    /// along the top, so it read as a duplicate paddle rather than as a shadow.
    ///
    /// An `SKEffectNode` with a gaussian blur is the only way to get a soft edge here: the art
    /// is a black copy of the paddle grown by `endlessIIPaddleShadowSpread` on every side, and
    /// the blur turns that margin into the falloff. **Rasterised**, so the blur is computed
    /// once and not every frame - the paddle moves constantly, and a live filter under it is a
    /// full-screen effect running at 120fps for a piece of scenery.
    ///
    /// Rasterising is also why the paddle's width is remembered: a cached bitmap does not
    /// follow Expand or Shrink, so a resize has to rebuild rather than restretch. The tick
    /// calls this every frame and it returns immediately unless the width has actually moved.
    func showEndlessIIPaddleShadow() {
        let name = GameScene.endlessIIPaddleShadowName
        if let existing = paddle.childNode(withName: name) {
            let builtFor = existing.userData?["builtForWidth"] as? CGFloat ?? 0
            guard abs(builtFor - paddle.size.width) > 0.5 else { return }
            existing.removeFromParent()
        }

        let spread = GameScene.endlessIIPaddleShadowSpread
        let art = SKSpriteNode(texture: paddle.texture,
                               size: CGSize(width: paddle.size.width + spread*2,
                                            height: paddle.size.height + spread*2))
        art.color = .black
        art.colorBlendFactor = 1
        art.centerRect = endlessIIPaddleDressCenterRect
        // The paddle's own current nine-slice, like the bar and the mirror (round 201)

        let shadow = SKEffectNode()
        shadow.name = name
        shadow.filter = CIFilter(name: "CIGaussianBlur",
                                 parameters: [kCIInputRadiusKey: GameScene.endlessIIPaddleShadowBlur])
        shadow.shouldRasterize = true
        shadow.alpha = GameScene.endlessIIPaddleShadowAlpha
        shadow.position = .zero
        // Centred on the paddle, so the spread is even on all four edges
        shadow.zPosition = -0.05
        shadow.userData = ["builtForWidth": paddle.size.width]
        shadow.addChild(art)
        paddle.addChild(shadow)
    }

    func removeEndlessIIPaddleShadow() {
        paddle.childNode(withName: GameScene.endlessIIPaddleShadowName)?.removeFromParent()
    }

    /// The twin's body: a rectangle, or the shape's own silhouette while one is running.
    ///
    /// **Traced only while a shape owns the bounce**, not always. A plain mirror has been a
    /// rectangle since round 180 and bounces predictably because of it; tracing the ordinary
    /// paddle picture would change how the twin plays for no reason anybody asked for. With a
    /// shape running the trace *is* the parity - the real paddle's dome is a traced silhouette
    /// (round 213), so a flat mirror wearing a domed picture would show one face and give
    /// another, which is the one parity round 211 said was worth refusing.
    func endlessIIMirrorPaddleBody(size: CGSize) -> SKPhysicsBody {
        endlessIIMirrorPaddleBodyArt = endlessIIShapeOwnsTheBounce
            ? endlessIIPaddleShapeArtName : nil
        let body: SKPhysicsBody
        if endlessIIShapeOwnsTheBounce, let art = endlessIIMirrorPaddleDress {
            body = SKPhysicsBody(texture: art, size: size)
        } else {
            body = SKPhysicsBody(rectangleOf: size)
        }
        body.isDynamic = false
        body.affectedByGravity = false
        body.friction = 0
        body.restitution = 1
        body.categoryBitMask = CollisionTypes.mirrorPaddleCategory.rawValue
        body.collisionBitMask = CollisionTypes.ballCategory.rawValue
        body.contactTestBitMask = CollisionTypes.ballCategory.rawValue
            | CollisionTypes.powerUpCategory.rawValue
        // **It collects drops as well as returning balls** (James, round 209). Contact only,
        // not collision: a drop should be taken, not bounced off
        return body
    }

    /// The picture the mirror wears: the paddle's, wherever the paddle is keeping it.
    ///
    /// The Retro theme draws its paddle on `paddleRetroTexture` rather than on the paddle
    /// sprite, so asking the sprite would dress the mirror as a plain bar next to a paddle
    /// that is anything but. Round 166 learned this the hard way on Double Paddle.
    var endlessIIMirrorPaddleDress: SKTexture? {
        if paddleTexture == retroPaddle, let art = paddleRetroTexture.texture { return art }
        return paddle.texture ?? paddleTexture
    }

    /// Keeps the mirror level with the paddle and opposite it, and takes it away when the
    /// clock stops. Called every frame from the paddle tick.
    ///
    /// Followed rather than animated, so it tracks the finger exactly and costs nothing when
    /// the finger is still - the same bargain the paddle's own dressing sprites make.
    func tickEndlessIIMirrorPaddle() {
        guard let mirror = childNode(withName: GameScene.endlessIIMirrorPaddleName)
                as? SKSpriteNode else { return }

        guard endlessIIMirrorPaddleIsUp else {
            mirror.name = nil
            // Renamed first, so a second tick before the fade finishes does not queue a
            // second removal on the same node
            mirror.physicsBody = nil
            mirror.run(.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
            removeEndlessIIPaddleShadow()
            // The shadow is the mirror's costume on the real paddle, and it leaves with it
            return
        }

        mirror.position = CGPoint(x: GameScene.endlessIIMirrorPaddleX(paddleX: paddle.position.x),
                                  y: paddle.position.y)

        let wantedArt = endlessIIShapeOwnsTheBounce ? endlessIIPaddleShapeArtName : nil
        if mirror.size != paddle.size || wantedArt != endlessIIMirrorPaddleBodyArt,
           paddle.size.width > 0, paddle.size.height > 0 {
            mirror.size = paddle.size
            mirror.centerRect = endlessIIPaddleDressCenterRect
            // The paddle switches its nine-slice on when a resize stretches it; its twin
            // switches with it or the two wear the same picture differently (round 201)
            mirror.physicsBody = endlessIIMirrorPaddleBody(size: paddle.size)
            // Split Paddle writes the paddle's width directly, and a mirror that kept the
            // width it was born with would be a different paddle from the one it mirrors
        }

        if mirror.xScale != paddle.xScale || mirror.yScale != paddle.yScale {
            mirror.xScale = paddle.xScale
            mirror.yScale = paddle.yScale
            // **Expand and Shrink do not write the width at all** - they animate `xScale`, and
            // have since long before any of this, so the check above never fired for them and
            // the twin of an expanded paddle stayed the width it was born at. Copied as a
            // scale rather than folded into the size on purpose: the real paddle is *scaled*,
            // so its rounded ends stretch with it, and a mirror that grew by resizing would
            // hold its ends square while the paddle beside it did not. The body follows the
            // node's scale, which is the same thing the paddle's own body has relied on for
            // six years
        }
        showEndlessIIPaddleShadow()
        // Rebuilt only when the paddle's width has actually moved - the shadow is a rasterised
        // blur, so a cached bitmap cannot be stretched by Expand or Shrink the way the mirror's
        // sprite can. It returns immediately on every other frame

        mirror.texture = endlessIIMirrorPaddleDress
        mirror.color = GameScene.endlessIIMirrorPaddleColour
        mirror.colorBlendFactor = 1
        // Re-tinted after the dress, every frame: the dress follows the paddle's own
        // texture, and a texture write resets nothing but still ships with whatever colour
        // the sprite carries - one missed frame here and the mirror flashes white
    }

    /// The ball met the mirror. Returns it the way the paddle would have.
    ///
    /// `PaddleBounce`'s own call, at influence 1: where the ball lands across the mirror's
    /// face is exactly as much of the answer as it is on the real paddle. The heading is
    /// sampled from before the step (§8.6) - a contact reports the velocity the engine has
    /// already bounced, and bending that one bends it twice.
    ///
    /// Nothing here spends a paddle turn, counts a paddle hit, or touches the aim. Every
    /// power-up that answers a paddle contact stays out of it, which is the whole reason this
    /// surface has a category of its own.
    func endlessIIMirrorPaddleHit(_ subject: SKSpriteNode) {
        guard let mirror = childNode(withName: GameScene.endlessIIMirrorPaddleName)
                as? SKSpriteNode else { return }
        guard let body = subject.physicsBody else { return }
        guard subject.position.y >= mirror.position.y else { return }
        // The top face only, as on the real paddle: a ball meeting the end or the underside
        // keeps whatever the engine gave it

        if soundsSetting { run(ballPaddleHitSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }

        if endlessIIApplyShapedBounce(to: subject) { return }
        // **The shape decides here too, exactly as it does on the paddle** (round 213). The
        // engine has already reflected the ball off the mirror's traced silhouette by the time
        // this contact is reported, and that reflection *is* the answer - so the formula below
        // stands down rather than being layered on top of it. Round 211 gave the mirror the
        // shaped face through `PaddleBounce.shaped`, which was right until the shapes stopped
        // being formulas: left alone, the twin would have gone on giving the old curve while
        // the paddle beside it gave the artwork's

        let arriving = ballStateBeforeStep[ObjectIdentifier(subject)]?.velocity ?? body.velocity
        let collision = PaddleBounce.collision(ballX: subject.position.x,
                                               paddleX: mirror.position.x,
                                               paddleWidth: mirror.size.width)
        let clamped = min(max(collision, -1), 1)
        body.velocity = PaddleBounce.velocity(arriving: arriving,
                                              collision: PaddleBounce.shaped(
                                                  clamped, by: endlessIIPaddleSurface),
                                              adjustmentK: PaddleBounce.adjustmentK,
                                              influence: endlessIIPaddleAngleInfluence,
                                              minimumDeg: PaddleBounce.minimumDeg,
                                              speed: hypot(arriving.dx, arriving.dy))
        _ = endlessIIApplyAutoAim(to: subject)
        endlessIIGripBall(subject)
        // **The twin answers to the paddle's own power-ups** (round 225's matrix: the mirror
        // also becomes inert, also has the bounce angle flipped, and a ball is directed at the
        // aimed brick "regardless of the paddle it bounces off"). The influence used to be a
        // hard 1 here, which made the mirror the one surface in the mode an Inert Paddle could
        // not reach - and a power-up that switches off half the paddles is a power-up that
        // reads as broken. The aim and the grip follow the paddle's own order
        // Clamped rather than refused past the ends: the engine only reports a contact where
        // the bodies actually met, so a fraction outside the face is the corner of it.
        //
        // **Shaped like the paddle** (round 211): with a shaped face running, the mirror gives
        // the same bounce the real paddle would - and shows the same curve. The twin follows
        // the paddle, and a bounce surface that looked shaped and answered flat would be the
        // one parity worth refusing.
        //
        // `shaped` is reached only by a face with no artwork, which is the same fallback the
        // paddle keeps in `paddleHit` - the two answer a shape the same way at every step
    }
}
