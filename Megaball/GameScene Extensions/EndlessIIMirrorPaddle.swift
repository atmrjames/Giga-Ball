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
        endlessIIMirrorCollectsDrops(mirror)
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
        playMayhemSound("mirrorPaddle")
    }

    static let endlessIIMirrorLaserStripName = "endlessIIMirrorLaserStrip"
    static let endlessIIMirrorWrapGhostName = "endlessIIMirrorWrapGhost"

    /// The mirror's own other half, while Wrap-Around lets the paddles through the walls.
    ///
    /// James, round 339: "With mirror paddle and wrap around power-ups, the paddles were
    /// blocked from wrapping around - they should be allowed, whilst maintaining the
    /// mirroring."
    ///
    /// The mirror stands at the negated x, so a paddle overhanging the right wall puts its twin
    /// overhanging the left one by the same amount - and the real paddle has a ghost that shows
    /// its overhang coming back in at the far side, while the twin had nothing: half of it
    /// simply went off the edge. This is the twin's ghost, built the way the paddle's is (a
    /// second sprite a field's width away, wearing the same picture, with a body of its own so
    /// the re-entering half returns balls), and in the twin's category so it bounces like the
    /// mirror rather than like the paddle. Mirroring is kept because it is derived: the twin is
    /// still wherever the paddle's negation puts it, and its ghost is wherever the twin's
    /// overhang lands.
    func tickEndlessIIMirrorWrapGhost(_ mirror: SKSpriteNode) {
        let existing = childNode(withName: GameScene.endlessIIMirrorWrapGhostName) as? SKSpriteNode
        let limit = gameWidth/2 - mirror.size.width/2
        guard endlessIIWrapIsRunning, abs(mirror.position.x) > limit else {
            existing?.removeFromParent()
            return
        }
        let ghost = existing ?? {
            let made = SKSpriteNode()
            made.name = GameScene.endlessIIMirrorWrapGhostName
            addChild(made)
            return made
        }()
        if ghost.texture !== mirror.texture { ghost.texture = mirror.texture }
        if ghost.size != mirror.size || ghost.physicsBody == nil {
            ghost.xScale = 1
            ghost.yScale = 1
            ghost.size = mirror.size
            ghost.physicsBody = endlessIIMirrorPaddleBody(size: mirror.size)
            // The mirror's size already carries its scale, so the ghost wears it at scale one
            // - copying the scale as well would draw it twice as wide as the twin it continues
        }
        ghost.centerRect = mirror.centerRect
        ghost.color = mirror.color
        ghost.colorBlendFactor = mirror.colorBlendFactor
        ghost.alpha = mirror.alpha
        ghost.zPosition = mirror.zPosition
        ghost.position = CGPoint(x: mirror.position.x > 0 ? mirror.position.x - gameWidth
                                                          : mirror.position.x + gameWidth,
                                 y: mirror.position.y)
    }

    /// The laser turrets, on the mirror, while the paddle wears them.
    ///
    /// James, round 321: "mirror paddle is firing lasers but doesn't have any turrets." Round
    /// 225 gave the twin its shots - `endlessIIFireMirrorLaser` - and nothing gave it the strip
    /// they come out of, so the lime paddle fired from a bare bar.
    ///
    /// **A sibling of the mirror, not a child of it**, and a copy of the paddle's own strip in
    /// every respect but its x. The mirror copies the paddle's `xScale`, and so does the strip,
    /// so a strip parented to the mirror would be scaled twice; §8.6's trap about
    /// `SKSpriteNode.size` carrying the scale is the same arithmetic. Standing beside it and
    /// copying anchor, scale, size and height straight off `paddleLaser` makes it the same strip
    /// in a second place, which is what the wrap ghost's strips are for the same reason.
    func dressEndlessIIMirrorTurrets(_ mirror: SKSpriteNode) {
        let existing = childNode(withName: GameScene.endlessIIMirrorLaserStripName) as? SKSpriteNode
        let showing = paddleLaser.isHidden == false && paddleLaser.parent != nil
        guard showing, let art = paddleLaser.texture else {
            existing?.removeFromParent()
            return
        }
        let strip = existing ?? {
            let made = SKSpriteNode()
            made.name = GameScene.endlessIIMirrorLaserStripName
            addChild(made)
            return made
        }()
        if strip.texture !== art { strip.texture = art }
        strip.anchorPoint = paddleLaser.anchorPoint
        strip.xScale = paddleLaser.xScale
        strip.yScale = paddleLaser.yScale
        strip.size = paddleLaser.size
        strip.centerRect = paddleLaser.centerRect
        strip.zPosition = mirror.zPosition + 0.05
        strip.color = GameScene.endlessIIMirrorPaddleColour
        strip.colorBlendFactor = mirror.colorBlendFactor
        strip.alpha = mirror.alpha
        strip.position = CGPoint(x: mirror.position.x,
                                 y: paddleLaser.position.y - paddle.position.y + mirror.position.y)
        // Lime like the mirror it sits on, and faded with it, so the pair still reads as the
        // twin rather than as the paddle's turrets left behind on the far side
    }

    static let endlessIIPaddleShadowName = "mirrorPaddleShadow"

    /// Hangs a soft shadow under the real paddle while the mirror runs.
    ///
    /// James, round 200: "the front white paddle should have a slight soft drop shadow so
    /// the green/yellow paddle appears behind it." Depth is what says which of two crossing
    /// paddles is yours, and colour alone stopped saying it the moment they overlapped.
    ///
    /// SpriteKit has no layer shadows, so it is a sprite of its own - see
    /// `showEndlessIIPaddleShadow` for how it came to be one.
    /// How far the shadow reaches past every edge of the paddle, in points.
    static let endlessIIPaddleShadowSpread: CGFloat = 9

    static let endlessIIPaddleShadowAlpha: CGFloat = 0.3

    /// A soft dark spread under the paddle, so the white paddle reads against the white
    /// mirror behind it.
    ///
    /// **Centred and blurred, not offset and hard** (James, round 209: "drop shadow on the
    /// paddle with mirror paddle active is too harsh. It should be centred on the paddle with
    /// some span and blur so it appears on all edges of the paddle and is soft and subtle").
    ///
    /// **Round 342 found why it never was** (James, round 339: "With mirror paddle and halo
    /// power-ups on together, the shadow around the white paddle can be seen, and it looks bad.
    /// This shadow should be a subtle drop shadow with soft edges that just pokes out of all
    /// sides of the white paddle evenly, growing and shrinking with the paddle as needed").
    /// It was a black copy of the paddle, grown by the spread and blurred in a rasterised
    /// `SKEffectNode`, hung on the paddle as a child - and two things were wrong with that:
    ///
    /// - **It was scaled twice.** It was sized from `paddle.size`, which already carries the
    ///   paddle's scale (`endlessIIPaddleHalfWidth` says why that is certain), and then drawn
    ///   inside the paddle, whose `xScale` applied to it again. Under Expand it ran far past the
    ///   ends while staying the same thickness above and below: the opposite of even.
    /// - **The blur was cut off.** An effect node crops its output to its children's bounds,
    ///   so the falloff past the grown copy stopped at a hard edge. On the dark field a 30%
    ///   black box vanishes; over the Halo's lime glow it is a dark rectangle.
    ///
    /// Now it is a sprite of its own beside the paddle rather than inside it, wearing one
    /// picture that is already soft (`endlessIIPaddleShadowTexture`), nine-sliced so the soft
    /// edge keeps its width however far the middle stretches, and sized every frame to the
    /// paddle as drawn plus the same margin on all four sides. Nothing is rasterised, so there
    /// is nothing to rebuild when the paddle changes size: a size write per frame is the whole
    /// cost.
    func showEndlessIIPaddleShadow() {
        let name = GameScene.endlessIIPaddleShadowName
        let shadow = (childNode(withName: name) as? SKSpriteNode) ?? {
            let made = SKSpriteNode(texture: GameScene.endlessIIPaddleShadowTexture)
            made.name = name
            made.centerRect = GameScene.endlessIIPaddleShadowCentre
            made.color = .black
            made.colorBlendFactor = 1
            addChild(made)
            return made
        }()
        let spread = GameScene.endlessIIPaddleShadowSpread
        let size = CGSize(width: abs(paddle.size.width) + spread*2,
                          height: abs(paddle.size.height) + spread*2)
        if shadow.size != size { shadow.size = size }
        shadow.position = paddle.position
        shadow.zPosition = paddle.zPosition - 0.05
        // Behind the paddle's own pixels and in front of the mirror, which sits a tenth back
        shadow.alpha = paddle.isHidden ? 0 : GameScene.endlessIIPaddleShadowAlpha
    }

    func removeEndlessIIPaddleShadow() {
        childNode(withName: GameScene.endlessIIPaddleShadowName)?.removeFromParent()
    }

    /// The shadow's one picture: a black pill whose edge fades out over `softEdge` points.
    ///
    /// Drawn once, with Core Graphics' own shadow - the pill itself is drawn far off the
    /// canvas and only its blurred shadow lands on it, which is the standard way to get a
    /// soft shape with nothing hard in the middle of it.
    static let endlessIIPaddleShadowSoftEdge: CGFloat = 8

    static let endlessIIPaddleShadowTexture: SKTexture = {
        let edge = endlessIIPaddleShadowSoftEdge
        let pill = CGSize(width: 24, height: 8)
        let canvas = CGSize(width: pill.width + edge*2, height: pill.height + edge*2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        let image = UIGraphicsImageRenderer(size: canvas, format: format).image { context in
            let cg = context.cgContext
            let away: CGFloat = 1000
            cg.setShadow(offset: CGSize(width: away, height: 0), blur: edge,
                         color: UIColor.black.cgColor)
            let rect = CGRect(x: edge - away, y: edge, width: pill.width, height: pill.height)
            cg.addPath(CGPath(roundedRect: rect, cornerWidth: pill.height/2,
                              cornerHeight: pill.height/2, transform: nil))
            cg.setFillColor(UIColor.black.cgColor)
            cg.fillPath()
        }
        return SKTexture(image: image)
    }()

    /// The middle of that picture, which is all that stretches: the soft edge and the pill's
    /// rounded ends keep their size whatever the paddle does.
    static var endlessIIPaddleShadowCentre: CGRect {
        let edge = endlessIIPaddleShadowSoftEdge
        let canvas = CGSize(width: 24 + edge*2, height: 8 + edge*2)
        let cap = edge + 4
        return CGRect(x: cap/canvas.width, y: 0.45,
                      width: (canvas.width - cap*2)/canvas.width, height: 0.1)
    }

    /// The twin's body: a rectangle, or the reflected shape's silhouette while one is running.
    ///
    /// **Traced only while a shape owns the bounce**, not always. A plain mirror has been a
    /// rectangle since round 180 and bounces predictably because of it; tracing the ordinary
    /// paddle picture would change how the twin plays for no reason anybody asked for. With a
    /// shape running the trace *is* the parity - the real paddle's dome is a traced silhouette
    /// (round 213), so a flat mirror wearing a domed picture would show one face and give
    /// another, which is the one parity round 211 said was worth refusing.
    func endlessIIMirrorPaddleBody(size: CGSize) -> SKPhysicsBody {
        endlessIIMirrorPaddleBodyArt = endlessIIMirrorPaddleShapeArtName
        let body: SKPhysicsBody
        if endlessIIShapeOwnsTheBounce, let art = endlessIIMirrorPaddleDress {
            body = TracedBodyCache.body(texture: art, size: size)
                ?? SKPhysicsBody(rectangleOf: size)
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

    /// Takes any power-up that has landed on the mirror.
    ///
    /// **James, round 209 and again in round 312: "mirrored paddle isn't able to collect power
    /// ups."** Round 209 answered it with a contact branch in `didBegin`, the masks were set on
    /// both sides, and the branch is still there and correct. It has never once run.
    ///
    /// Both bodies are static. The mirror is `isDynamic = false` because it is placed by hand
    /// every frame rather than simulated, and a falling power-up is `isDynamic = false` because
    /// it is moved by an action - and **SpriteKit does not report contacts between two static
    /// bodies**. The main paddle is dynamic, which is the only reason the same branch works
    /// there, and why this looked finished for a hundred rounds.
    ///
    /// Answered geometrically rather than by making either body dynamic. A dynamic mirror gets
    /// shoved by the ball it is meant to return; a dynamic power-up changes how every drop in
    /// the game behaves. Overlap is the whole question and the frame already knows both frames -
    /// which is the same reasoning `catchStickyBallBeforeStep` uses to catch the ball in
    /// `update` rather than waiting for a contact that comes too late.
    func endlessIIMirrorCollectsDrops(_ mirror: SKSpriteNode) {
        let catcher = mirror.frame
        guard catcher.width > 0, catcher.height > 0 else { return }

        var landed: [SKNode] = []
        enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            guard node.zPosition == 2 else { return }
            // Two is "still falling" - `collectPowerUpDrop` drops it to one as it takes it, and
            // asking here as well keeps a drop from being collected twice in one frame
            if node.frame.intersects(catcher) { landed.append(node) }
        }
        for drop in landed { collectPowerUpDrop(drop) }
    }

    /// The shape the twin wears: the paddle's, reflected.
    ///
    /// Nil when no shape is running, which is every ordinary paddle in the mode.
    var endlessIIMirrorPaddleSurface: PaddleBounce.Surface? {
        endlessIIPaddleSurfaceClock.isRunning ? endlessIIPaddleSurface?.mirrored : nil
    }

    /// The artwork name for that reflected shape, or nil where the shape is not owning the
    /// bounce - the same question `endlessIIPaddleShapeArtName` answers for the real paddle.
    var endlessIIMirrorPaddleShapeArtName: String? {
        guard endlessIIShapeOwnsTheBounce, let mirrored = endlessIIMirrorPaddleSurface
        else { return nil }
        return endlessIIPaddleShapeTextureName(mirrored)
    }

    /// The picture the mirror wears: the paddle's, wherever the paddle is keeping it - or the
    /// reflection of the paddle's shape, while one is running.
    ///
    /// The Retro theme draws its paddle on `paddleRetroTexture` rather than on the paddle
    /// sprite, so asking the sprite would dress the mirror as a plain bar next to a paddle
    /// that is anything but. Round 166 learned this the hard way on Double Paddle.
    ///
    /// **The reflection is read off the shape rather than off the paddle's sprite** (James,
    /// round 233). Copying the sprite gave a wedge-left paddle a wedge-left twin, which is a
    /// duplicate and not a mirror. Because the body below is traced from whatever this
    /// returns, naming the mirrored picture here is the whole of the change: the twin bounces
    /// the ball off the reflected face without anything else being told about it.
    var endlessIIMirrorPaddleDress: SKTexture? {
        if let art = endlessIIMirrorPaddleShapeArtName { return SKTexture(imageNamed: art) }
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
            childNode(withName: GameScene.endlessIIMirrorLaserStripName)?.removeFromParent()
            childNode(withName: GameScene.endlessIIMirrorWrapGhostName)?.removeFromParent()
            removeEndlessIIPaddleShadow()
            // The shadow is the mirror's costume on the real paddle, and it leaves with it
            return
        }

        mirror.position = CGPoint(x: GameScene.endlessIIMirrorPaddleX(paddleX: paddle.position.x),
                                  y: paddle.position.y)

        let wantedArt = endlessIIMirrorPaddleShapeArtName
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
        dressEndlessIIMirrorTurrets(mirror)
        tickEndlessIIMirrorWrapGhost(mirror)
        showEndlessIIPaddleShadow()
        // Every frame: it follows the paddle's position and its drawn size, which is a
        // position and a size write rather than anything rebuilt

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
        var twinX = mirror.position.x
        if endlessIIWrapIsRunning, abs(subject.position.x - twinX) > gameWidth/2 {
            twinX += subject.position.x > twinX ? gameWidth : -gameWidth
        }
        // Measured against whichever copy the ball met - the twin or its wrap ghost on the far
        // side (`tickEndlessIIMirrorWrapGhost`) - as `endlessIIPaddleXNearest` does for the
        // paddle. Against the twin a field away, a ghost landing is an edge hit at full angle
        let collision = PaddleBounce.collision(ballX: subject.position.x,
                                               paddleX: twinX,
                                               paddleWidth: mirror.size.width)
        let clamped = min(max(collision, -1), 1)

        if endlessIIMirrorPortalTook(subject, collision: clamped) { return }
        // **The twin has a portal of its own** (James, round 284: "yes - a mirrored paddle gets
        // its own portal, and both send the ball to the top"). Asked before the bounce is
        // written, exactly as the paddle asks it, because a portal is the paddle deciding not
        // to bounce at all - and the ball is put back at the top from `didSimulatePhysics`,
        // since a position written inside a contact is undone by the rest of the step (§8.6)

        body.velocity = PaddleBounce.velocity(arriving: arriving,
                                              collision: PaddleBounce.shaped(
                                                  clamped, by: endlessIIMirrorPaddleSurface),
                                              adjustmentK: PaddleBounce.adjustmentK,
                                              influence: endlessIIPaddleAngleInfluence,
                                              minimumDeg: PaddleBounce.minimumDeg,
                                              speed: hypot(arriving.dx, arriving.dy))
        _ = endlessIIApplyAutoAim(to: subject)
        endlessIIGripBall(subject, collision: clamped)
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
