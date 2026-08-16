//
//  EndlessIIDoublePaddle.swift
//  Megaball
//
//  Double Paddle (§12.0): the paddle splits in two, with a hole in the middle.
//
//  James's play-test idea from the second round, pulled into 1.3 at round 100, and the queue
//  priced it honestly: "a second paddle is per-ball contact handling all over again". It is
//  not, in the end, and the reason is worth writing down.
//
//  **There is still exactly one paddle node.** The split is a *composite physics body* - two
//  rectangles in one body, with a gap between them - and two child sprites drawn where those
//  rectangles are. So every other thing that knows about the paddle carries on working
//  untouched: the touch handler moves one node, `paddleHit` reads one position and one width,
//  the Halo hangs off it, Aimed Sticky catches on it, the Portal swallows through it, and a
//  shaped face still bends the bounce by where the ball landed. A second *node* would have
//  meant teaching all of that about a list of paddles, which is what the note was pricing.
//
//  The one thing the split changes is what it should change: there is a hole in the middle of
//  the paddle, and a ball down the centre goes through it.
//
//  The halves are cut *within* the paddle's existing width rather than each being half the
//  original width with the pair spanning wider. That is a small departure from the note, and
//  deliberate: the paddle's width is written by the size power-ups and read by the bounce, and
//  a power-up that quietly widened the span would have had to fight both. Worth James's eye.
//

import SpriteKit

extension GameScene {

    /// How long the paddle stays split.
    ///
    /// Time rather than paddle turns, unlike most of the batch: the interesting thing about a
    /// split paddle is the shots you decline to take, and a clock that only moves when you
    /// *do* take one would last a strangely long time in exactly the situation it is hardest.
    static let endlessIIDoublePaddleDuration: TimeInterval = 12

    /// How wide the hole is, as a share of the paddle. A little over a ball, so a ball
    /// straight down the middle goes through and a ball anywhere else does not.
    static let endlessIIDoublePaddleGap: CGFloat = 0.14

    static let doublePaddleHalfName = "endlessIIDoublePaddleHalf"

    func endlessIICollectDoublePaddle() {
        guard gameMode == .endlessII else { return }
        endlessIIDoublePaddleClock.collect(GameScene.endlessIIDoublePaddleDuration)
        refreshEndlessIIDoublePaddle()
    }

    /// Whether the paddle is currently in two pieces.
    var endlessIIPaddleIsSplit: Bool {
        gameMode == .endlessII && endlessIIDoublePaddleClock.isRunning
    }

    /// Builds, maintains and takes down the split. Called once a frame from the paddle tick.
    ///
    /// Rebuilt whenever the paddle's width changes, because Expand and Shrink Paddle write
    /// that width directly and the halves are cut from it - a split paddle that grew would
    /// otherwise keep the body it had when it was small.
    func refreshEndlessIIDoublePaddle() {
        guard endlessIIPaddleIsSplit else {
            guard endlessIIDoublePaddleWidth > 0 else { return }
            endlessIIDoublePaddleWidth = 0
            paddle.children
                .filter { $0.name == GameScene.doublePaddleHalfName }
                .forEach { $0.removeFromParent() }
            paddle.texture = endlessIIDoublePaddleDress ?? paddle.texture
            paddle.color = .white
            paddle.colorBlendFactor = 0
            paddle.physicsBody = paddleBodyMatchingCurrent(SKPhysicsBody(rectangleOf: paddle.size))
            endlessIIDoublePaddleDress = nil
            return
            // Put back exactly: one body, one sprite, its own dress. A power-up that left the
            // paddle in pieces after its clock stopped would be a power-up that never ended
        }

        if paddle.texture != nil { endlessIIDoublePaddleDress = paddle.texture }
        // The paddle's dress changes underneath this - themes, Lasers, the sticky and retro
        // textures - so the current one is remembered every frame rather than once at the
        // start, and the halves wear whatever it is now

        guard abs(endlessIIDoublePaddleWidth - paddle.size.width) > 0.5 else { return }
        endlessIIDoublePaddleWidth = paddle.size.width

        let gap = paddle.size.width*GameScene.endlessIIDoublePaddleGap
        let halfWidth = (paddle.size.width - gap)/2
        let offset = (halfWidth + gap)/2
        let size = CGSize(width: halfWidth, height: paddle.size.height)

        let left = SKPhysicsBody(rectangleOf: size, center: CGPoint(x: -offset, y: 0))
        let right = SKPhysicsBody(rectangleOf: size, center: CGPoint(x: offset, y: 0))
        paddle.physicsBody = paddleBodyMatchingCurrent(SKPhysicsBody(bodies: [left, right]))
        // One body made of two rectangles. Every contact still arrives as a paddle contact,
        // which is the whole trick - nothing downstream has to know there are two of them

        paddle.children
            .filter { $0.name == GameScene.doublePaddleHalfName }
            .forEach { $0.removeFromParent() }
        for x in [-offset, offset] {
            let half = SKSpriteNode(texture: endlessIIDoublePaddleDress, size: size)
            half.name = GameScene.doublePaddleHalfName
            half.position = CGPoint(x: x, y: 0)
            half.zPosition = 0.1
            paddle.addChild(half)
        }
        paddle.texture = nil
        paddle.color = .clear
        paddle.colorBlendFactor = 1
        // The node keeps its size - the bounce measures where the ball landed across the
        // whole span, and the span has not changed - but stops drawing itself, because what
        // is drawn now is its two children
    }

    /// Dresses a replacement body in the settings the paddle's current one is wearing.
    ///
    /// Not a list of the right values, deliberately. The paddle's masks are rewritten from a
    /// dozen places - every level state puts the border bit back, Wrap-Around takes it away so
    /// the paddle can leave the field, the ball-lost sequence changes it twice - and a
    /// replacement body built from remembered constants would undo whichever of those was in
    /// force at the moment the split happened to start.
    func paddleBodyMatchingCurrent(_ body: SKPhysicsBody) -> SKPhysicsBody {
        guard let current = paddle.physicsBody else { return body }
        body.allowsRotation = current.allowsRotation
        body.friction = current.friction
        body.affectedByGravity = current.affectedByGravity
        body.isDynamic = current.isDynamic
        body.restitution = current.restitution
        body.usesPreciseCollisionDetection = current.usesPreciseCollisionDetection
        body.categoryBitMask = current.categoryBitMask
        body.collisionBitMask = current.collisionBitMask
        body.contactTestBitMask = current.contactTestBitMask
        return body
    }
}
