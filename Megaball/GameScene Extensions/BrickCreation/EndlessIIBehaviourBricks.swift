//
//  EndlessIIBehaviourBricks.swift
//  Megaball
//
//  The six bricks that act on the field around them: Gravity, Moving, Directional,
//  Exploding, Spawner and Portal.
//
//  There is no artwork for any of them, so each is an ordinary brick tinted a colour nothing
//  else uses, with a shape drawn over it saying what it does. The tint alone would not be
//  enough - a player should not have to learn six colours before the first one surprises
//  them - so the glyph carries the meaning and the colour makes it findable.
//
//  Two of them are not new nodes but new answers to old questions, which is why they hook
//  into `hitBrick` rather than living here entirely: a Directional brick refuses damage from
//  five sides, and a Portal is never damaged at all.
//

import SpriteKit

extension GameScene {

    /// How often an ordinary brick takes one of these roles.
    ///
    /// Low, and lower than the phase 3 behaviours, because each of these changes what the
    /// field does rather than only how one brick behaves.
    static let endlessIIRoleChance = 10

    /// The height from which a Directional brick may face left or right.
    static let endlessIISideFacingFrom = 200
    /// And the chance of meeting one before then, because nothing is ever locked out.
    static let endlessIISideFacingEarlyChance = 8

    static let gravityBrickColour = UIColor(red: 0.42, green: 0.66, blue: 1.0, alpha: 1)
    static let movingBrickColour = UIColor(red: 1.0, green: 0.60, blue: 0.15, alpha: 1)
    static let directionalBrickColour = UIColor(red: 0.42, green: 0.42, blue: 0.48, alpha: 1)
    static let explodingBrickColour = UIColor(red: 1.0, green: 0.22, blue: 0.62, alpha: 1)
    static let spawnerBrickColour = UIColor(red: 0.20, green: 0.85, blue: 0.72, alpha: 1)
    static let portalBrickColour = UIColor(red: 0.78, green: 0.55, blue: 1.0, alpha: 1)
    static let portalBlueColour = UIColor(red: 0.30, green: 0.68, blue: 1.0, alpha: 1)
    static let portalYellowColour = UIColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1)

    private static let glyphName = "endlessIIGlyph"
    /// How fast a Gravity brick falls and a Moving brick wanders, in cells per second.
    private static let gravityFallSpeed: CGFloat = 6
    private static let movingSpeed: CGFloat = 1.1

    // MARK: - Applying

    /// Gives some new bricks a role.
    ///
    /// Only ordinary single-hit bricks of ordinary size, and only ones that did not already
    /// pick up a phase 3 behaviour - a brick doing two things at once is a brick nobody can
    /// read. Sizes are the exception and combine freely, which is the point of size being a
    /// separate axis.
    func applyEndlessIIRoles(to bricks: [SKNode]) {
        applyEndlessIIStyles([.gravity, .moving, .directional,
                              .exploding, .spawner, .portal], to: bricks)
    }

    /// Whether a brick is still plain enough to be given a role.
    ///
    /// Spinning and Flashing bricks are tracked by identity, so this asks the lists rather
    /// than trying to read it off the sprite.
    func endlessIIIsPlain(_ brick: SKSpriteNode) -> Bool {
        guard endlessIISpinners.contains(where: { $0.brick === brick }) == false else {
            return false
        }
        guard endlessIIFlashers.contains(where: { $0.brick === brick }) == false else {
            return false
        }
        return brick.childNode(withName: GameScene.roundedBrickOutlineName) == nil
    }

    private func tint(_ brick: SKSpriteNode, _ colour: UIColor) {
        brick.color = colour
        brick.colorBlendFactor = 1.0
    }

    /// Draws a shape over a brick, sized to the brick rather than to a cell so it stays
    /// legible on a Tiny one and does not look lost on a Big one.
    private func addGlyph(_ path: CGPath, to brick: SKSpriteNode,
                          filled: Bool = true, scale: CGFloat = 1) {
        let glyph = SKShapeNode(path: path)
        glyph.name = GameScene.glyphName
        glyph.strokeColor = UIColor(white: 0, alpha: 0.75)
        glyph.fillColor = filled ? UIColor(white: 0, alpha: 0.75) : .clear
        glyph.lineWidth = max(1.5, brick.size.height*0.08)
        glyph.setScale(scale)
        glyph.zPosition = 1
        // Follows the sprite, which on a Big brick is not centred on the node
        glyph.position = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                                 y: (0.5 - brick.anchorPoint.y)*brick.size.height)
        brick.addChild(glyph)
    }

    // MARK: - Gravity

    /// Falls into empty cells below it, and falls again whenever its support goes.
    func makeGravity(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .gravity
        tint(brick, GameScene.gravityBrickColour)

        let unit = brick.size.height*0.28
        let chevron = CGMutablePath()
        chevron.move(to: CGPoint(x: -unit, y: unit/2))
        chevron.addLine(to: CGPoint(x: 0, y: -unit/2))
        chevron.addLine(to: CGPoint(x: unit, y: unit/2))
        addGlyph(chevron, to: brick, filled: false)
    }

    /// Drops every Gravity brick as far as it will go.
    ///
    /// Resolved from the bottom up in one pass, so a stack of them lands in order rather
    /// than each one stopping on a brick that is itself about to move.
    func settleEndlessIIGravityBricks() {
        guard gameMode == .endlessII else { return }

        var occupied = endlessIIOccupancy()
        let geometry = endlessIIGeometry
        let lowestRow = endlessIILowestRow

        let falling = occupied.values
            .filter { $0.endlessIIRole == .gravity }
            .reduce(into: [ObjectIdentifier: SKSpriteNode]()) { $0[ObjectIdentifier($1)] = $1 }
            .values
            .sorted { endlessIICell(of: $0).row > endlessIICell(of: $1).row }

        for brick in falling {
            let from = endlessIICell(of: brick)
            var to = from
            while to.row < lowestRow {
                let below = EndlessIICell(column: to.column, row: to.row + 1)
                guard occupied[below] == nil else { break }
                to = below
            }
            guard to != from else { continue }

            occupied[from] = nil
            occupied[to] = brick
            endlessIIFallers[ObjectIdentifier(brick)] =
                EndlessIIFall(brick: brick, targetY: geometry.centre(of: to).y)
        }
    }

    // MARK: - Moving

    /// Slides sideways until something stops it, then goes the other way.
    ///
    /// The limits are not fixed when it is created - they are whatever is beside it right
    /// now. It travels until it reaches another brick or the wall, turns round, and does the
    /// same the other way. A brick with a neighbour on both sides simply does not move, and
    /// starts moving the moment one of them goes. That makes it part of the field rather
    /// than something overlapping it: it can never end up sitting on top of another brick,
    /// and clearing beside one visibly gives it room.
    ///
    /// Horizontally only, where the spec asks for a 2x2 region. A brick that left its row
    /// centre would break the one thing the descent and the bottom-row check rely on - see
    /// EndlessIISizes - and would be cleared away half a row early or late. The horizontal
    /// axis is the one worth having anyway: cells are twice as wide as they are tall, so it
    /// is where there is room to move.
    func makeMoving(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .moving
        tint(brick, GameScene.movingBrickColour)

        let unit = brick.size.height*0.26
        let arrows = CGMutablePath()
        arrows.move(to: CGPoint(x: -unit*1.6, y: 0))
        arrows.addLine(to: CGPoint(x: unit*1.6, y: 0))
        arrows.move(to: CGPoint(x: -unit*1.6, y: 0))
        arrows.addLine(to: CGPoint(x: -unit*0.8, y: unit*0.7))
        arrows.move(to: CGPoint(x: -unit*1.6, y: 0))
        arrows.addLine(to: CGPoint(x: -unit*0.8, y: -unit*0.7))
        arrows.move(to: CGPoint(x: unit*1.6, y: 0))
        arrows.addLine(to: CGPoint(x: unit*0.8, y: unit*0.7))
        arrows.move(to: CGPoint(x: unit*1.6, y: 0))
        arrows.addLine(to: CGPoint(x: unit*0.8, y: -unit*0.7))
        addGlyph(arrows, to: brick, filled: false)

        endlessIIWanderers.append(EndlessIIWander(brick: brick,
                                                  direction: Bool.random() ? 1 : -1))
    }

    /// How far a wandering brick may travel before something is in the way.
    ///
    /// Measured from what is actually beside it, so it re-reads the field rather than
    /// trusting limits worked out when the brick was made - the field it sits in changes
    /// constantly underneath it.
    func endlessIIWanderLimits(for brick: SKSpriteNode) -> (left: CGFloat, right: CGFloat) {
        let geometry = endlessIIGeometry
        let cell = geometry.cell(at: brick.position)
        let occupied = endlessIIOccupancy()
        let halfWidth = brick.size.width/2

        var leftLimit = -gameWidth/2 + halfWidth
        var rightLimit = gameWidth/2 - halfWidth
        // The walls, until a brick gets in the way first

        if let blocker = occupied[EndlessIICell(column: cell.column - 1, row: cell.row)],
           blocker !== brick {
            leftLimit = max(leftLimit, blocker.position.x + blocker.size.width/2 + halfWidth)
        }
        if let blocker = occupied[EndlessIICell(column: cell.column + 1, row: cell.row)],
           blocker !== brick {
            rightLimit = min(rightLimit, blocker.position.x - blocker.size.width/2 - halfWidth)
        }
        return (leftLimit, rightLimit)
    }

    // MARK: - Directional

    /// Only takes damage from one side.
    ///
    /// Drawn dark like an Indestructible brick with the hittable edge picked out bright, so
    /// which side works is read off the brick rather than remembered.
    func makeDirectional(_ brick: SKSpriteNode) {
        // Top and bottom first. The ball spends most of its time travelling up and down, so
        // a brick that only takes damage from above or below is something a player can solve
        // by waiting for the right pass. Left and right ask for a specific angle, which is a
        // much harder shot - so they stay rare until a run is well underway.
        let sides: [EndlessIISide] = endlessHeight >= GameScene.endlessIISideFacingFrom
            || Int.random(in: 1...100) <= GameScene.endlessIISideFacingEarlyChance
            ? [.top, .bottom, .left, .right]
            : [.top, .bottom]
        let side: EndlessIISide = sides.randomElement() ?? .bottom
        brick.endlessIIRole = .directional
        brick.endlessIIVulnerableSide = side
        tint(brick, GameScene.directionalBrickColour)

        let width = brick.size.width
        let height = brick.size.height
        let thickness = min(width, height)*0.2
        let edge: CGRect
        switch side {
        case .top:
            edge = CGRect(x: -width/2, y: height/2 - thickness, width: width, height: thickness)
        case .bottom:
            edge = CGRect(x: -width/2, y: -height/2, width: width, height: thickness)
        case .left:
            edge = CGRect(x: -width/2, y: -height/2, width: thickness, height: height)
        case .right:
            edge = CGRect(x: width/2 - thickness, y: -height/2, width: thickness, height: height)
        }

        let bar = SKShapeNode(rect: edge)
        bar.name = GameScene.glyphName
        bar.fillColor = brickWhite
        bar.strokeColor = .clear
        bar.zPosition = 1
        bar.position = CGPoint(x: (0.5 - brick.anchorPoint.x)*width,
                               y: (0.5 - brick.anchorPoint.y)*height)
        brick.addChild(bar)
    }

    /// Whether a hit on this brick should do anything at all.
    func endlessIIAcceptsHit(_ brick: SKSpriteNode, from side: EndlessIISide?) -> Bool {
        guard brick.endlessIIRole == .directional else { return true }
        guard let side else { return true }
        // A laser has no side; it comes from below and is treated as such by its caller
        return side == brick.endlessIIVulnerableSide
    }

    // MARK: - Exploding

    /// Takes its eight neighbours with it, whatever they are.
    func makeExploding(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .exploding
        tint(brick, GameScene.explodingBrickColour)

        let unit = brick.size.height*0.3
        let burst = CGMutablePath()
        for step in 0..<4 {
            let angle = CGFloat(step)*(.pi/4)
            burst.move(to: CGPoint(x: -cos(angle)*unit, y: -sin(angle)*unit))
            burst.addLine(to: CGPoint(x: cos(angle)*unit, y: sin(angle)*unit))
        }
        addGlyph(burst, to: brick, filled: false)
    }

    /// Shows what an explosion is about to take.
    ///
    /// Brief and small: a ring stepping outward from the brick over the cells it is claiming,
    /// and a flash on each of them. Long enough to see the connection between the brick that
    /// went and the ones going with it, short enough not to become a cutscene.
    func endlessIIShowBlast(at centre: CGPoint, over victims: [SKSpriteNode]) {
        let reach = max(brickWidth, brickHeight)*1.5

        let ring = SKShapeNode(circleOfRadius: reach)
        ring.position = centre
        ring.zPosition = 2
        ring.fillColor = .clear
        ring.strokeColor = GameScene.explodingBrickColour
        ring.lineWidth = 3
        ring.setScale(0.15)
        addChild(ring)
        ring.run(.sequence([.group([.scale(to: 1, duration: 0.18),
                                    .fadeOut(withDuration: 0.18)]),
                            .removeFromParent()]))

        for victim in victims {
            let flash = SKSpriteNode(color: GameScene.explodingBrickColour, size: victim.size)
            flash.position = victim.position
            flash.anchorPoint = victim.anchorPoint
            flash.zPosition = 2
            flash.alpha = 0.9
            addChild(flash)
            flash.run(.sequence([.group([.fadeOut(withDuration: 0.22),
                                         .scale(to: 1.3, duration: 0.22)]),
                                 .removeFromParent()]))
        }
        // Drawn as separate nodes rather than on the bricks themselves, because the bricks
        // are about to be removed and would take the animation with them

        if hapticsSetting { heavyHaptic.impactOccurred() }
    }

    /// Runs an explosion, and any it sets off.
    ///
    /// One pass over a queue with a set of everything already caught, so a brick detonates
    /// at most once however many explosions reach it, and a chain cannot loop.
    func endlessIIExplode(from brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }

        let occupied = endlessIIOccupancy()
        var caught: Set<ObjectIdentifier> = [ObjectIdentifier(brick)]
        var queue = [brick]
        var destroyed: [SKSpriteNode] = []

        while queue.isEmpty == false {
            let centre = queue.removeFirst()
            for cell in EndlessIIFieldGeometry.neighbours(of: endlessIICell(of: centre)) {
                guard let neighbour = occupied[cell] else { continue }
                guard caught.insert(ObjectIdentifier(neighbour)).inserted else { continue }
                // A Portal is not destructible by anything, explosions included
                guard neighbour.endlessIIRole != .portal else { continue }
                destroyed.append(neighbour)
                if neighbour.endlessIIRole == .exploding { queue.append(neighbour) }
            }
        }

        endlessIIShowBlast(at: brick.position, over: destroyed)
        // Shown whether or not it caught anything. An explosion with nothing beside it
        // achieves nothing, but a brick that only sometimes goes off reads as broken - and
        // seeing it fire into empty space is how a player learns what it would have done
        for victim in destroyed { endlessIIDestroy(victim) }
        if destroyed.isEmpty == false { countBricks() }
    }

    /// Removes a brick that something else destroyed, rather than the ball.
    ///
    /// Deliberately not `removeBrick`: that awards a power-up roll and re-counts the field
    /// per brick, which for an explosion means a shower of power-ups and a lot of repeated
    /// work. The score is awarded here and the field counted once at the end.
    func endlessIIDestroy(_ brick: SKSpriteNode) {
        guard brick.parent != nil else { return }
        if brick.texture != brickIndestructible2Texture {
            levelScore = levelScore + Scoring.award(brickDestroyScore, multiplier: multiplier)
        }
        brick.removeFromParent()
    }

    // MARK: - Spawner

    /// Refills its empty neighbours when destroyed.
    func makeSpawner(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .spawner
        tint(brick, GameScene.spawnerBrickColour)

        let unit = brick.size.height*0.28
        let plus = CGMutablePath()
        plus.move(to: CGPoint(x: -unit, y: 0))
        plus.addLine(to: CGPoint(x: unit, y: 0))
        plus.move(to: CGPoint(x: 0, y: -unit))
        plus.addLine(to: CGPoint(x: 0, y: unit))
        addGlyph(plus, to: brick, filled: false)
    }

    /// Fills the empty cells around a destroyed Spawner with ordinary bricks.
    ///
    /// Ordinary, and never another Spawner, so what it leaves behind is something the player
    /// can clear rather than something that keeps growing.
    func endlessIISpawn(around brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }

        let occupied = endlessIIOccupancy()
        let geometry = endlessIIGeometry
        let lowestRow = endlessIILowestRow
        var made = 0

        for cell in EndlessIIFieldGeometry.neighbours(of: endlessIICell(of: brick)) {
            guard geometry.isInsideWidth(cell) else { continue }
            guard cell.row >= 0 && cell.row <= lowestRow else { continue }
            guard occupied[cell] == nil else { continue }

            let spawned = SKSpriteNode(texture: brickNormalTexture)
            spawned.color = brickWhite
            spawned.colorBlendFactor = 1.0
            spawned.size = CGSize(width: brickWidth, height: brickHeight)
            spawned.position = geometry.centre(of: cell)
            spawned.zPosition = 1
            spawned.name = BrickCategoryName
            spawned.physicsBody = brickBody(SKPhysicsBody(rectangleOf: spawned.size))
            spawned.setScale(0.4)
            spawned.alpha = 0
            addChild(spawned)
            spawned.run(.group([.scale(to: 1, duration: 0.15),
                                .fadeIn(withDuration: 0.15)]))
            made += 1
        }

        if made > 0 { countBricks() }
    }

    // MARK: - Portal

    /// Sends the ball to the top of the field. Never destroyed.
    ///
    /// Built on the Indestructible ×2 texture rather than only being marked unbreakable,
    /// which buys the two rules that matter for free: the hit path already refuses to damage
    /// it, and the bottom-row check already ignores it. A Portal that counted would sit in
    /// the last row forever, waiting to be cleared, and no row would ever be generated again.
    /// Every Portal currently on the field, in the order they were made.
    func endlessIIPortals() -> [SKSpriteNode] {
        var found: [SKSpriteNode] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if node.endlessIIRole == .portal, let brick = node as? SKSpriteNode {
                found.append(brick)
            }
        }
        return found
    }

    /// Two at most, and never more.
    ///
    /// One on its own sends the ball to the top of the field. Two make a pair, and the pair
    /// works both ways - the ball comes out of whichever end it did not go into, still
    /// travelling the way it was. Three would be ambiguous about where a jump lands.
    static let endlessIIMaximumPortals = 2

    func endlessIIHasPortal() -> Bool {
        endlessIIPortals().count >= GameScene.endlessIIMaximumPortals
    }

    func makePortal(_ brick: SKSpriteNode) {
        let isBlue = endlessIIPortals().isEmpty
        brick.endlessIIRole = .portal
        brick.endlessIIPortalIsBlue = isBlue
        brick.texture = brickIndestructible2Texture

        // Left untinted, unlike every other role here. `colorBlendFactor` colourises a
        // texture but the result is still modulated by what the texture looks like, and the
        // Indestructible artwork is dark and shaded - so any colour comes out as a dark,
        // muddy version of itself. That is the right look for a brick that cannot be broken,
        // so the identity goes in the glyph rather than the body.
        let radius = min(brick.size.width, brick.size.height)*0.3
        let rings = CGMutablePath()
        rings.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2))
        rings.addEllipse(in: CGRect(x: -radius*0.5, y: -radius*0.5,
                                    width: radius, height: radius))
        // Two rings, so it cannot be mistaken for a Rounded brick's single one

        let glyph = SKShapeNode(path: rings)
        glyph.name = GameScene.glyphName
        glyph.strokeColor = isBlue ? GameScene.portalBlueColour : GameScene.portalYellowColour
        // Two colours so a player can see which end pairs with which. Neither is the way in:
        // hit the blue one and you come out of the yellow, hit the yellow and you come out
        // of the blue
        glyph.fillColor = .clear
        glyph.lineWidth = max(1.5, brick.size.height*0.1)
        glyph.zPosition = 1
        glyph.position = CGPoint(x: (0.5 - brick.anchorPoint.x)*brick.size.width,
                                 y: (0.5 - brick.anchorPoint.y)*brick.size.height)
        brick.addChild(glyph)
    }

    /// Moves the ball to the top of the field, keeping its speed and direction.
    ///
    /// The cooldown is what stops it being a trap: without it a ball arriving at the top
    /// travelling upward would bounce off the ceiling straight back into whatever sent it
    /// there, over and over.
    func endlessIIEnterPortal(_ brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }
        guard endlessIIPortalCooldown <= 0 else { return }
        endlessIIPortalCooldown = GameScene.endlessIIPortalCooldownSeconds

        let from = ball.position
        let velocity = ball.physicsBody?.velocity ?? .zero
        let partner = endlessIIPortals().first { $0 !== brick }

        let to: CGPoint
        if let partner {
            // Out of the far one, still travelling the way it was. Pushed clear of the brick
            // along that heading, or it arrives inside the thing it just came out of
            let speed = max(1, hypot(velocity.dx, velocity.dy))
            let clearance = max(brickWidth, brickHeight)/2 + ballSize*1.5
            to = CGPoint(x: partner.position.x + velocity.dx/speed*clearance,
                         y: partner.position.y + velocity.dy/speed*clearance)
        } else {
            to = CGPoint(x: ball.position.x,
                         y: yBrickOffsetEndless + brickHeight/2 - ballSize)
            // On its own it is a lift to the top of the field. Just below the top, not above
            // it - an earlier version put the ball inside the top screen block and left the
            // physics to shove it back out
        }
        endlessIIPortalKeepsHeading = partner != nil

        endlessIIPendingPortalExit = to
        // Not moved here. This runs from `didBegin`, which SpriteKit calls in the middle of
        // simulating the physics step - a position written to a dynamic body at that point is
        // overwritten when the step finishes resolving, so the ball never went anywhere. The
        // effects showed because they are separate nodes and nothing was undoing them.
        // Applied in `didSimulatePhysics` instead, which is the first moment after the step

        endlessIIShowPortalJump(from: from, to: to)
        if hapticsSetting { mediumHaptic.impactOccurred() }
        partner?.run(.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                                .fadeAlpha(to: 1, duration: 0.12)]))

        brick.run(.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                             .fadeAlpha(to: 1, duration: 0.12)]))
    }

    /// Moves the ball to a portal's exit, once the physics step is out of the way.
    func applyEndlessIIPortalExit() {
        guard let exit = endlessIIPendingPortalExit else { return }
        endlessIIPendingPortalExit = nil

        let velocity = ball.physicsBody?.velocity ?? .zero
        ball.position = exit
        if endlessIIPortalKeepsHeading {
            ball.physicsBody?.velocity = velocity
            // A pair is a doorway, so what goes in one side comes out of the other going the
            // same way. Turning it would make the exit unpredictable from the entrance
        } else {
            ball.physicsBody?.velocity = CGVector(dx: velocity.dx, dy: -abs(velocity.dy))
            // A lone Portal is a lift, and arriving at the top still travelling up only buys
            // an immediate bounce off the ceiling. Sending it down hands the player a run
            // back through the whole field, which is the point of going up there
        }
    }

    /// Marks both ends of a portal jump.
    ///
    /// Without this the jump is easy to miss entirely, and it was: bricks sit near the top of
    /// the field, so a Portal among them sends the ball a short distance, and a ball that
    /// moves half a screen in one frame with nothing to say why just looks like a bad bounce.
    /// A ring collapsing where it left and one opening where it arrives is the whole story.
    func endlessIIShowPortalJump(from: CGPoint, to: CGPoint) {
        for (position, collapsing) in [(from, true), (to, false)] {
            let ring = SKShapeNode(circleOfRadius: ballSize*1.8)
            ring.position = position
            ring.zPosition = 3
            ring.fillColor = .clear
            ring.strokeColor = GameScene.portalBrickColour
            ring.lineWidth = 3
            ring.setScale(collapsing ? 1 : 0.2)
            addChild(ring)
            ring.run(.sequence([.group([.scale(to: collapsing ? 0.2 : 1, duration: 0.22),
                                        .fadeOut(withDuration: 0.22)]),
                                .removeFromParent()]))
        }

        let streak = SKShapeNode(rect: CGRect(x: -1.5, y: min(from.y, to.y),
                                              width: 3, height: abs(to.y - from.y)))
        streak.position = CGPoint(x: from.x, y: 0)
        streak.zPosition = 2
        streak.fillColor = GameScene.portalBrickColour
        streak.strokeColor = .clear
        streak.alpha = 0.5
        addChild(streak)
        streak.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        // A line joining the two, so the eye is taken from one end to the other rather than
        // having to find the ball again
    }

    static let endlessIIPortalCooldownSeconds: TimeInterval = 0.5

    // MARK: - Reacting

    /// What Endless 2.0 does when a brick is struck but survives.
    ///
    /// Exploding and Spawner normally fire when their brick is destroyed. On an
    /// Indestructible one that moment never comes, so they fire on contact instead - which
    /// turns each of them into something that keeps working: a brick that clears its
    /// neighbours every time you hit it, or one that keeps refilling them. Neither runs
    /// away, because both only act on cells that are there to act on.
    func endlessIIBrickStruck(_ brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }
        guard let behaviour = endlessIIBehaviour(of: brick) else { return }

        switch brick.endlessIIRole {
        case .exploding where EndlessIIStyle.exploding.firesOnHit(with: behaviour):
            endlessIIExplode(from: brick)
        case .spawner where EndlessIIStyle.spawner.firesOnHit(with: behaviour):
            endlessIISpawn(around: brick)
        default: break
        }
    }

    /// What Endless 2.0 does when a brick is destroyed.
    ///
    /// Called from `removeBrick`, which is also reached by bricks that survive being hit -
    /// an Indestructible brick goes through it and stays exactly where it was - so the first
    /// thing this does is check the brick actually went.
    func endlessIIBrickDestroyed(_ brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }
        guard brick.texture != brickIndestructible1Texture,
              brick.texture != brickIndestructible2Texture else { return }

        switch brick.endlessIIRole {
        case .exploding: endlessIIExplode(from: brick)
        case .spawner: endlessIISpawn(around: brick)
        default: break
        }

        settleEndlessIIGravityBricks()
        // Whatever just went may have been holding something up
    }

    // MARK: - Driving

    /// Advances the falling and wandering bricks, and runs down the portal cooldown.
    func tickEndlessIIRoles(_ delta: TimeInterval) {
        endlessIIPortalCooldown = max(0, endlessIIPortalCooldown - delta)

        let rate = CGFloat(endlessIIProgression.motionRate(at: endlessHeight))
        // Everything that moves starts slow and speeds up. A spinning brick at full rate in
        // the first ten metres is noise; the same brick at 40% is something to read

        endlessIIWanderers.removeAll { $0.brick.parent == nil }
        for index in endlessIIWanderers.indices {
            var wanderer = endlessIIWanderers[index]
            let limits = endlessIIWanderLimits(for: wanderer.brick)
            guard limits.right - limits.left > 0.5 else { continue }
            // Penned in on both sides. It waits, and sets off again the moment one goes

            let step = GameScene.movingSpeed*rate*brickWidth*CGFloat(delta)*wanderer.direction
            var x = wanderer.brick.position.x + step
            if x >= limits.right {
                x = limits.right
                wanderer.direction = -1
            } else if x <= limits.left {
                x = limits.left
                wanderer.direction = 1
            }
            wanderer.brick.position.x = x
            endlessIIWanderers[index] = wanderer
        }

        for key in endlessIIFallers.keys {
            guard let fall = endlessIIFallers[key] else { continue }
            guard fall.brick.parent != nil else {
                endlessIIFallers[key] = nil
                continue
            }
            let step = GameScene.gravityFallSpeed*brickHeight*CGFloat(delta)
            if fall.brick.position.y - step <= fall.targetY {
                fall.brick.position.y = fall.targetY
                endlessIIFallers[key] = nil
            } else {
                fall.brick.position.y -= step
            }
        }
    }

    func resetEndlessIIRoles() {
        endlessIIWanderers.removeAll()
        endlessIIFallers.removeAll()
        endlessIIPortalCooldown = 0
        endlessIIPendingPortalExit = nil
    }
}

/// A Gravity brick on its way down.
struct EndlessIIFall {
    let brick: SKSpriteNode
    let targetY: CGFloat
}

/// A Moving brick and the way it is currently heading.
///
/// It carries no limits of its own. Where it can get to is whatever is beside it at the
/// moment it is asked, which is the only answer that stays true in a field that is being
/// cleared out from under it.
struct EndlessIIWander {
    let brick: SKSpriteNode
    var direction: CGFloat
}
