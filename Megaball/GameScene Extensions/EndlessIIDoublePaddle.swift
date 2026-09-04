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

        let dressNow = endlessIIDoublePaddleHalfDress
        let widthMoved = abs(endlessIIDoublePaddleWidth - paddle.size.width) > 0.5
        let dressChanged = endlessIISplitHalfTexture !== dressNow.texture
        guard widthMoved || dressChanged else { return }
        endlessIIDoublePaddleWidth = paddle.size.width
        endlessIISplitHalfTexture = dressNow.texture
        // **Rebuilt when the picture changes as well as when the width does** (James, round
        // 305: "paddle graphics aren't applying to the split paddle correctly").
        //
        // The halves are children carrying their own copy of the paddle's texture, and this
        // guard used to ask only about the width - so a dress that changed while the paddle was
        // already split never reached them. Collecting Lasers, a theme swap from the pause
        // menu, the sticky band arriving: the paddle underneath changed picture and the two
        // pieces the player can actually see went on wearing the one they were born with,
        // until something happened to resize the paddle.
        //
        // Compared by identity rather than equality because `SKTexture` has no useful `==`,
        // and identity is exactly the question: the halves were built from *that* texture
        // object, and a different object is a different picture

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

    /// Where the two turrets sit, in scene coordinates: the outer edge of the outermost piece
    /// on each side.
    ///
    /// James, round 285: "only the outermost section of paddle should have a laser turret on
    /// its outer edge. There should only ever be 2 turrets with a split paddle." So a split
    /// paddle is armed exactly as much as a whole one is, and the shots come from the two ends
    /// of the formation.
    ///
    /// **Which means the generator needed no change at all.** It has always alternated between
    /// `paddle.position.x` plus and minus half the span, and the span's two ends *are* the
    /// outermost pieces' outer edges - the paddle node keeps its full width when it splits, and
    /// the first and last segments are flush with it. Round 285's first attempt gave every
    /// piece a turret and had to be taken out again; what was actually wrong was only the
    /// dress, which is below.
    ///
    /// Returned as positions rather than read off the generator because the generator writes
    /// them inline in the middle of building a sprite, and one of the two is behind a `retro`
    /// branch. This is the same two points said where the dress can ask for them.
    var endlessIISplitLaserTurrets: [CGFloat] {
        let centres = endlessIISplitSegmentCentres
        guard let first = centres.first, let last = centres.last else { return [] }
        return [first, last]
        // The two outermost pieces' centres. The turret is drawn across the piece and the shot
        // leaves from its outer edge, which is where the generator has always put it
    }

    /// Every segment's centre, in scene coordinates.
    var endlessIISplitSegmentCentres: [CGFloat] {
        let layout = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                           standardWidth: paddleWidth,
                                                           ballSize: ballSize)
        let pitch = layout.segment + layout.gap
        let first = -paddle.size.width/2 + layout.segment/2
        return (0..<layout.count).map { paddle.position.x + first + pitch*CGFloat($0) }
    }

    /// Where a ball landed on the *segment* it struck, -1 to 1.
    ///
    /// **A split paddle is two paddles that move together, not one paddle with a hole in it**
    /// (James, round 305: "I think the paddle sections should be treated like separate
    /// individual paddles that move together, rather than a single paddle with a hole in the
    /// middle").
    ///
    /// The bounce angle is taken from where the ball lands across the paddle, and measuring
    /// that across the *whole span* is what made the split read as one object: the inner ends
    /// of the two pieces are near the span's middle, so a ball hitting either of them came back
    /// almost straight up - the flattest, most centred bounce there is - even though it had
    /// struck the very edge of a piece. Half of each segment answered as if it were the middle
    /// of the paddle, and the two outer ends were the only parts that steered at all.
    ///
    /// Measured per segment, each piece steers across its own width like the paddle it is: the
    /// inner edges throw the ball inward hard, which is what makes aiming with a split paddle a
    /// different skill rather than a worse one.
    ///
    /// Nil when the paddle is not split, or when the ball is over a gap rather than a piece -
    /// a ball down a gap has struck nothing, and the caller keeps whatever the whole-span
    /// answer was rather than being handed a number about a segment it missed.
    func endlessIISplitCollision(ballX: CGFloat) -> CGFloat? {
        guard endlessIIPaddleIsSplit else { return nil }
        let layout = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                           standardWidth: paddleWidth,
                                                           ballSize: ballSize)
        guard layout.segment > 0 else { return nil }

        for centre in endlessIISplitSegmentCentres {
            let offset = ballX - centre
            guard abs(offset) <= layout.segment/2 else { continue }
            return min(max(offset/(layout.segment/2), -1), 1)
        }
        return nil
    }

    /// Cuts one of the paddle's overlays into pieces that sit on the split, or puts it back.
    ///
    /// **The bug this exists for, said once for all four of them.** The paddle wears four
    /// strips - the laser dress, the sticky band, and the Retro theme's own two - each sized to
    /// the whole paddle and drawn over it. A split paddle keeps its node's full width, so every
    /// one of those strips goes on being drawn across the gaps: a picture of a solid armed
    /// paddle over a paddle with holes in it. Round 233 found and fixed exactly this for the
    /// Retro *paddle* art, where a ball falling through a paddle that looked solid read as a
    /// bug rather than as the power-up; the spec has carried a note ever since that the other
    /// strips would do the same thing, and this is that note answered.
    ///
    /// The source strip is hidden by **alpha** rather than by `isHidden`, because `isHidden` on
    /// these is how the power-ups themselves say whether they are running at all, and a second
    /// opinion written into the same property would fight them.
    ///
    /// - Parameter centres: which segments wear it. Not always all of them: the lasers fire
    ///   from two turrets however many pieces there are (round 286), and a strip on a piece
    ///   with no turret would be back to claiming something untrue.
    func refreshEndlessIISplitOverlay(_ source: SKSpriteNode, centres: [CGFloat]) {
        let key = ObjectIdentifier(source)
        var pieces = endlessIISplitOverlays[key] ?? []

        let wanted = endlessIIPaddleIsSplit && source.isHidden == false && centres.isEmpty == false
        guard wanted else {
            if pieces.isEmpty == false {
                pieces.forEach { $0.removeFromParent() }
                endlessIISplitOverlays[key] = nil
                source.alpha = 1
            }
            return
            // Put back exactly, the same bargain the split itself makes: a power-up that left
            // the paddle undressed after its clock stopped would be one that never ended
        }

        let segment = GameScene.endlessIIDoublePaddleLayout(span: paddle.size.width,
                                                            standardWidth: paddleWidth,
                                                            ballSize: ballSize).segment
        while pieces.count < centres.count {
            let piece = SKSpriteNode(texture: source.texture)
            piece.zPosition = source.zPosition
            addChild(piece)
            pieces.append(piece)
        }
        while pieces.count > centres.count {
            pieces.removeLast().removeFromParent()
        }

        source.alpha = 0
        for (piece, centre) in zip(pieces, centres) {
            piece.texture = source.texture
            piece.size = CGSize(width: segment, height: source.size.height)
            piece.centerRect = paddleCapRect(for: source.texture)
            piece.position = CGPoint(x: centre, y: source.position.y)
            piece.alpha = 1
        }
        // Nine-sliced, for round 182's reason: a strip cut to a fraction of its width squashes
        // its own end caps in proportion to how short it is
        endlessIISplitOverlays[key] = pieces
    }

    /// Every overlay the split has to cut up, each with the segments it belongs on.
    ///
    /// **Two turrets for the lasers and all of them for the rest**, and the difference is the
    /// design rather than an inconsistency: a laser comes from two places (James, round 285:
    /// "there should only ever be 2 turrets with a split paddle") and a sticky paddle catches
    /// anywhere the paddle is, so every piece of it is sticky.
    ///
    /// The Retro theme keeps its own laser flash and sticky band on separate nodes at their own
    /// proportions, so they are here as well - they were the half of this the spec had written
    /// down and nobody had done.
    func refreshEndlessIISplitDress() {
        guard gameMode == .endlessII else { return }
        let all = endlessIISplitSegmentCentres
        let outer = all.isEmpty ? [] : [all[0], all[all.count - 1]]

        refreshEndlessIISplitOverlay(paddleLaser, centres: outer)
        refreshEndlessIISplitOverlay(paddleRetroLaserTexture, centres: outer)
        refreshEndlessIISplitOverlay(paddleSticky, centres: all)
        refreshEndlessIISplitOverlay(paddleRetroStickyTexture, centres: all)
    }

}
