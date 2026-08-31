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

    /// How many paddle hits the split lasts.
    ///
    /// It was twelve seconds, argued for on the grounds that the interesting thing about a
    /// split paddle is the shots you decline to take - but the twelve seconds were never
    /// wired to any run-down loop, so in play it simply never ended, and James's round-180
    /// ruling settles the design: "it doesn't ever end. This should be based on paddle hits,
    /// not timed." Five, like the rest of the paddle batch.
    static let endlessIIDoublePaddleTurns = Int(GameScene.endlessIIPaddlePowerUpTurns)

    /// How wide each gap is, in balls.
    ///
    /// Measured off the ball rather than the paddle (James, round 180: the gap "should be
    /// bigger - big enough for ball to fit though... the ball should be able to fall through
    /// the middle"). The original gap was 14% of the paddle - almost exactly one ball on the
    /// standard paddle, so the ball nearly never fitted: it clipped a segment instead, and the
    /// middle read as solid. Round 180 took it to a ball and a half; **round 182 takes it to
    /// two** on James's play test ("the gap is still too small - go with 2 ball widths"),
    /// which is a gap you can aim a ball through rather than one it has to be threaded into.
    static let endlessIIDoublePaddleGapBalls: CGFloat = 2

    static let doublePaddleHalfName = "endlessIIDoublePaddleHalf"

    func endlessIICollectDoublePaddle() {
        guard gameMode == .endlessII else { return }
        endlessIIDoublePaddleClock.collect(turns: GameScene.endlessIIDoublePaddleTurns)
        refreshEndlessIIDoublePaddle()
    }

    /// How the current span divides into segments and gaps.
    ///
    /// **A longer paddle makes more segments, not longer segments** (James, round 180). The
    /// segment is fixed at the standard paddle's half - the piece the unexpanded split shows
    /// two of - and an expanded span fits as many of those as it can with at least a
    /// ball-and-a-half of gap between neighbours; whatever width is left over widens the gaps
    /// evenly rather than the pieces. A shrunken paddle keeps its two segments and gives up
    /// gap width down to the minimum, because one segment is not a split at all.
    static func endlessIIDoublePaddleLayout(span: CGFloat, standardWidth: CGFloat,
                                            ballSize: CGFloat)
    -> (segment: CGFloat, gap: CGFloat, count: Int) {
        let minGap = ballSize*endlessIIDoublePaddleGapBalls
        var segment = max(1, (standardWidth - minGap)/2)
        var count = max(2, Int(floor((span + minGap)/(segment + minGap))))
        if CGFloat(count)*segment + CGFloat(count - 1)*minGap > span {
            count = 2
            segment = max(1, (span - minGap)/2)
            // Too narrow for two standard pieces: the pieces give way, the gap does not -
            // a gap the ball cannot fall through is the one thing this must never build
        }
        let gap = (span - CGFloat(count)*segment)/CGFloat(count - 1)
        return (segment, gap, count)
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
            paddleRetroTexture.isHidden = paddleTexture != retroPaddle
            // The Retro dress comes back by the same rule the rest of the game shows it by
            return
            // Put back exactly: one body, one sprite, its own dress. A power-up that left the
            // paddle in pieces after its clock stopped would be a power-up that never ended
        }

        paddleRetroTexture.isHidden = true
        // **Every frame, and outside the width guard below.** This is what James's "I got the
        // double paddle power up but it didn't seem to do anything" was: in the Retro theme
        // the paddle the player sees is not the paddle sprite at all - it is
        // `paddleRetroTexture`, a separate node drawn over the top at zPosition 4 with its own
        // art. The body was split and the halves were drawn underneath it, and a whole paddle
        // was painted over them, so the only sign of the power-up was a ball that sometimes
        // fell through the middle of a paddle that looked solid. Outside the guard because the
        // level states show this overlay again on their own schedule

        if paddle.texture != nil { endlessIIDoublePaddleDress = paddle.texture }
        // The paddle's dress changes underneath this - themes, Lasers, the sticky and retro
        // textures - so the current one is remembered every frame rather than once at the
        // start, and the halves wear whatever it is now

        guard abs(endlessIIDoublePaddleWidth - paddle.size.width) > 0.5 else { return }
        endlessIIDoublePaddleWidth = paddle.size.width

        let layout = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                           standardWidth: paddleWidth,
                                                           ballSize: ballSize)
        let dress = endlessIIDoublePaddleHalfDress
        let size = CGSize(width: layout.segment, height: dress.height)

        let bodySize = CGSize(width: layout.segment, height: paddle.size.height)
        let pitch = layout.segment + layout.gap
        let first = -paddle.size.width/2 + layout.segment/2
        let centres = (0..<layout.count).map { first + pitch*CGFloat($0) }
        // The *body* is the paddle's own height, whatever the picture's is: the Retro dress is
        // two and a half times as tall as the paddle it stands for, and a body built to the
        // picture would catch balls above and below the paddle everybody else is playing with
        paddle.physicsBody = paddleBodyMatchingCurrent(SKPhysicsBody(
            bodies: centres.map {
                SKPhysicsBody(rectangleOf: bodySize, center: CGPoint(x: $0, y: 0))
            }))
        // One body made of several rectangles. Every contact still arrives as a paddle
        // contact, which is the whole trick - nothing downstream has to know how many pieces
        // there are. The gaps carry no rectangle at all, so there is nothing in them for the
        // ball to collide with - a ball down a gap falls through (round 180)

        paddle.children
            .filter { $0.name == GameScene.doublePaddleHalfName }
            .forEach { $0.removeFromParent() }
        for x in centres {
            let half = SKSpriteNode(texture: dress.texture, size: size)
            half.name = GameScene.doublePaddleHalfName
            half.centerRect = dress.centerRect
            // **The rounded ends survive the cut** (James, round 182: "the edges of the 2
            // shorter paddles get distorted. Is there a way, like when the paddle shrinks and
            // expands, to make the rounded edges persist with different size paddles?"). Yes,
            // and it is the very trick he named: the paddle keeps its caps by nine-slicing its
            // own texture - `paddleCenterRectPlus` protects the end caps and stretches only
            // the middle - and a segment is just another paddle at another width, so it wants
            // the same treatment. Without it the whole texture scaled, and the caps squashed
            // in proportion to how short the piece was
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

    /// What the halves are painted with, how tall the picture is, and where its caps are.
    ///
    /// The Retro theme keeps its paddle art on `paddleRetroTexture` rather than on the paddle,
    /// at its own proportions - two and a half times the paddle's height and a little wider.
    /// So the halves take that art when it is the theme in play, and the plain sprite's
    /// otherwise. A split paddle should still look like the paddle the player chose.
    ///
    /// The `centerRect` comes with the picture because it belongs to it: it is measured in the
    /// texture's own unit coordinates, so the plain paddle's caps and the Retro art's caps are
    /// different fractions of different pictures. Taken from the sprite that is wearing the
    /// art rather than restated here - `paddleCenterRectPlus` is where these numbers are
    /// decided, and a second copy of them would be wrong the first time the art changed.
    var endlessIIDoublePaddleHalfDress: (texture: SKTexture?, height: CGFloat,
                                         centerRect: CGRect) {
        if paddleTexture == retroPaddle, let art = paddleRetroTexture.texture {
            return (art, paddleRetroTexture.size.height, paddleCapRect(for: art))
        }
        return (endlessIIDoublePaddleDress, paddle.size.height,
                paddleCapRect(for: endlessIIDoublePaddleDress))
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
    // MARK: - Lasers on a split paddle

    /// Where the lasers come from, in scene coordinates.
    ///
    /// James, round 284, answering the parity matrix's second open cell: "each split has one
    /// laser turret on its far end." A segment's *far* end is the one away from the paddle's
    /// middle - the outer edge of the pieces on the left, and of those on the right - so the
    /// shots come from the outside of the formation inwards, which is the picture the answer
    /// draws.
    ///
    /// **The whole paddle already agreed with this by accident, and only for two.** The classic
    /// generator fires alternately from `paddle.position.x` plus and minus half the span, and
    /// the outermost segments' outer edges *are* those two points - so an unexpanded split has
    /// been firing from the right places since the day it was built. What it never did was fire
    /// from anything in between: an expanded split is three, four or five pieces, and three of
    /// them were unarmed while wearing the laser dress.
    ///
    /// A middle segment is exactly as far from the centre on both sides, and takes the outer
    /// edge of whichever half of the paddle it is on - `<` rather than `<=`, so the count being
    /// odd cannot leave a piece with no answer.
    var endlessIILaserOrigins: [CGFloat] {
        let inset = layoutUnit/4
        // The laser's own width, which is what the classic generator insets its two shots by so
        // the beam leaves the paddle rather than half over the edge of it

        guard endlessIIPaddleIsSplit else {
            return [paddle.position.x - paddle.size.width/2 + inset,
                    paddle.position.x + paddle.size.width/2 - inset]
        }

        let layout = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                           standardWidth: paddleWidth,
                                                           ballSize: ballSize)
        let pitch = layout.segment + layout.gap
        let first = -paddle.size.width/2 + layout.segment/2
        return (0..<layout.count).map { index -> CGFloat in
            let centre = first + pitch*CGFloat(index)
            let outward: CGFloat = centre < 0 ? -1 : 1
            return paddle.position.x + centre + outward*(layout.segment/2 - inset)
        }
    }

    /// One laser dress per segment while the paddle is split, and the paddle's own otherwise.
    ///
    /// The dress is what says a surface is armed, and a single strip drawn across the whole
    /// span said it about the gaps as well - which is the one place a laser certainly does not
    /// come from. Each piece wears its own now, cut to its own width, so what is drawn and what
    /// fires are the same set of places.
    ///
    /// **A picture of a turret would be better than a strip cut short**, and is on §8.5's list.
    /// This is the honest version of what can be said with the art that exists.
    func refreshEndlessIISplitLaserDress() {
        let wanted = endlessIIPaddleIsSplit && paddleLaser.isHidden == false
        guard wanted else {
            if endlessIISplitLaserDress.isEmpty == false {
                endlessIISplitLaserDress.forEach { $0.removeFromParent() }
                endlessIISplitLaserDress.removeAll()
                paddleLaser.alpha = 1
            }
            return
        }

        let layout = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                           standardWidth: paddleWidth,
                                                           ballSize: ballSize)
        while endlessIISplitLaserDress.count < layout.count {
            let piece = SKSpriteNode(texture: paddleLaser.texture)
            piece.zPosition = paddleLaser.zPosition
            addChild(piece)
            endlessIISplitLaserDress.append(piece)
        }
        while endlessIISplitLaserDress.count > layout.count {
            endlessIISplitLaserDress.removeLast().removeFromParent()
        }

        paddleLaser.alpha = 0
        // Hidden by alpha rather than by `isHidden`: the power-up's own code shows and hides
        // that node to say whether the lasers are running at all, and a second opinion written
        // into the same property would fight it

        let pitch = layout.segment + layout.gap
        let first = -paddle.size.width/2 + layout.segment/2
        for (index, piece) in endlessIISplitLaserDress.enumerated() {
            piece.texture = paddleLaser.texture
            piece.size = CGSize(width: layout.segment, height: paddleLaser.size.height)
            piece.centerRect = paddleCapRect(for: paddleLaser.texture)
            piece.position = CGPoint(x: paddle.position.x + first + pitch*CGFloat(index),
                                     y: paddleLaser.position.y)
            piece.alpha = 1
        }
        // Nine-sliced like the halves themselves, for round 182's reason: a strip cut to a
        // fraction of its width squashes its own end caps in proportion to how short it is
    }

}
