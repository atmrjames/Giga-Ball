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
    static let endlessIISafetyPaddleDuration: TimeInterval = 12

    /// How much of the field it spans.
    ///
    /// A little wider than the paddle and nothing like the whole width: it has to be
    /// possible to get past it, or the bricks are unreachable for twelve seconds and the run
    /// simply stops.
    static let endlessIISafetyPaddleWidth: CGFloat = 0.42

    static let endlessIISafetyPaddleName = "endlessIISafetyPaddle"

    /// Where it stands: one row below the lowest a brick may occupy.
    ///
    /// Below the field, so it never sits inside a brick, and well above the real paddle, so
    /// the two are read as two things.
    var endlessIISafetyPaddleY: CGFloat { finalBrickRowHeight - brickHeight }

    func endlessIICollectSafetyPaddle() {
        guard gameMode == .endlessII else { return }
        endlessIISafetyPaddleClock.collect(GameScene.endlessIISafetyPaddleDuration)
        showEndlessIISafetyPaddle()
    }

    /// Puts the surface on the field, or leaves the one already there alone.
    ///
    /// A second collection extends the clock rather than building a second paddle - which is
    /// what `extendsDuration` means in the catalogue, and what a player collecting two of
    /// them expects: longer, not thicker.
    func showEndlessIISafetyPaddle() {
        guard gameMode == .endlessII else { return }
        guard childNode(withName: GameScene.endlessIISafetyPaddleName) == nil else { return }

        let size = CGSize(width: max(brickWidth*2,
                                     gameWidth*GameScene.endlessIISafetyPaddleWidth),
                          height: max(4, brickHeight*0.35))
        // Never zero on either axis: SpriteKit refuses a body built from an empty rectangle
        // and hands back a node with no body at all, which is a safety paddle the ball falls
        // straight through - the kind of failure that looks like the power-up doing nothing
        let bar = SKSpriteNode(color: GameScene.endlessIIHaloColour, size: size)
        bar.name = GameScene.endlessIISafetyPaddleName
        bar.position = CGPoint(x: 0, y: endlessIISafetyPaddleY)
        bar.zPosition = 2
        bar.alpha = 0

        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.affectedByGravity = false
        body.friction = 0
        body.restitution = 1
        body.categoryBitMask = CollisionTypes.safetyPaddleCategory.rawValue
        body.collisionBitMask = CollisionTypes.ballCategory.rawValue
        body.contactTestBitMask = CollisionTypes.ballCategory.rawValue
        bar.physicsBody = body
        addChild(bar)

        bar.run(.fadeIn(withDuration: 0.15))
        // Faded in rather than appearing: a surface that arrives under a ball already on its
        // way down is easier to believe if it is seen arriving

        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    /// Takes it away, whenever the clock is not running.
    ///
    /// Called every frame rather than scheduled, because a clock can end in more ways than
    /// by running out: a Wipe ends it, and a run ending resets it.
    func tickEndlessIISafetyPaddle() {
        guard let bar = childNode(withName: GameScene.endlessIISafetyPaddleName) else { return }
        guard endlessIISafetyPaddleClock.isRunning == false else { return }
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
        if soundsSetting { run(ballPaddleHitSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }

        let xSpeed = body.velocity.dx
        let ySpeed = abs(body.velocity.dy)
        var angleDeg = Double(atan2(Double(ySpeed), Double(xSpeed)))/Double.pi*180
        let minimum = minAngleDeg*2
        if angleDeg < minimum { angleDeg = minimum }
        if angleDeg > 180 - minimum { angleDeg = 180 - minimum }
        ballHorizontalControl(angleDegInput: angleDeg, for: subject)
    }
}
