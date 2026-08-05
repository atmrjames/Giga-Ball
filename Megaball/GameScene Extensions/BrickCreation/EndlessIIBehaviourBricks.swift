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

    static let gravityBrickColour = UIColor(red: 0.42, green: 0.66, blue: 1.0, alpha: 1)
    static let movingBrickColour = UIColor(red: 1.0, green: 0.60, blue: 0.15, alpha: 1)
    static let directionalBrickColour = UIColor(red: 0.42, green: 0.42, blue: 0.48, alpha: 1)
    static let explodingBrickColour = UIColor(red: 1.0, green: 0.22, blue: 0.62, alpha: 1)
    static let spawnerBrickColour = UIColor(red: 0.20, green: 0.85, blue: 0.72, alpha: 1)
    static let portalBrickColour = UIColor(red: 0.78, green: 0.55, blue: 1.0, alpha: 1)

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
        guard gameMode == .endlessII else { return }

        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture == brickNormalTexture else { continue }
            guard brick.endlessIIRole == nil else { continue }
            guard endlessIIIsPlain(brick) else { continue }
            guard Int.random(in: 1...100) <= GameScene.endlessIIRoleChance else { continue }

            switch Int.random(in: 0...5) {
            case 0: makeGravity(brick)
            case 1: makeMoving(brick)
            case 2: makeDirectional(brick)
            case 3: makeExploding(brick)
            case 4: makeSpawner(brick)
            default: makePortal(brick)
            }
        }
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

    /// Wanders left and right across two cells.
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
                                                  home: brick.position.x,
                                                  reach: brickWidth/2,
                                                  direction: Bool.random() ? 1 : -1))
    }

    // MARK: - Directional

    /// Only takes damage from one side.
    ///
    /// Drawn dark like an Indestructible brick with the hittable edge picked out bright, so
    /// which side works is read off the brick rather than remembered.
    func makeDirectional(_ brick: SKSpriteNode) {
        let side: EndlessIISide = [.top, .bottom, .left, .right].randomElement() ?? .bottom
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
    func makePortal(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .portal
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
        glyph.strokeColor = GameScene.portalBrickColour
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

        let velocity = ball.physicsBody?.velocity ?? .zero
        ball.position = CGPoint(x: ball.position.x,
                                y: yBrickOffsetEndless + brickHeight/2 + ballSize)
        ball.physicsBody?.velocity = velocity

        if hapticsSetting { mediumHaptic.impactOccurred() }

        let flash = SKAction.sequence([.fadeAlpha(to: 0.35, duration: 0.08),
                                       .fadeAlpha(to: 1, duration: 0.12)])
        brick.run(flash)
    }

    static let endlessIIPortalCooldownSeconds: TimeInterval = 0.5

    // MARK: - Reacting

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

        endlessIIWanderers.removeAll { $0.brick.parent == nil }
        for index in endlessIIWanderers.indices {
            var wanderer = endlessIIWanderers[index]
            let step = GameScene.movingSpeed*brickWidth*CGFloat(delta)*wanderer.direction
            var x = wanderer.brick.position.x + step
            if x > wanderer.home + wanderer.reach {
                x = wanderer.home + wanderer.reach
                wanderer.direction = -1
            } else if x < wanderer.home - wanderer.reach {
                x = wanderer.home - wanderer.reach
                wanderer.direction = 1
            }
            wanderer.brick.position.x = x
            endlessIIWanderers[index] = wanderer
        }

        for key in endlessIIFallers.keys {
            guard var fall = endlessIIFallers[key] else { continue }
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
                endlessIIFallers[key] = fall
            }
        }
    }

    func resetEndlessIIRoles() {
        endlessIIWanderers.removeAll()
        endlessIIFallers.removeAll()
        endlessIIPortalCooldown = 0
    }
}

/// A Gravity brick on its way down.
struct EndlessIIFall {
    let brick: SKSpriteNode
    let targetY: CGFloat
}

/// A Moving brick and the span it wanders across.
struct EndlessIIWander {
    let brick: SKSpriteNode
    /// The x it was generated at, and how far either side of it it may go.
    let home: CGFloat
    let reach: CGFloat
    var direction: CGFloat
}
