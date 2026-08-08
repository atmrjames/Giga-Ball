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
                              .exploding, .spawner, .portal, .fixed], to: bricks)
        // Fixed was in the enum, in the compatibility grid, in the reference page and in the
        // progression's style list, and in neither pool - so it could never be applied to a
        // brick and nobody had ever seen one. Being everywhere except the one line that
        // offers it is exactly the kind of gap that looks like rarity from the outside
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

        var fill = endlessIIFill()
        let geometry = endlessIIGeometry
        let lowestRow = endlessIILowestRow

        let falling = endlessIIBricks()
            .filter { $0.endlessIIRole == .gravity }
            .sorted { endlessIICell(of: $0).row > endlessIICell(of: $1).row }

        for brick in falling {
            let from = endlessIICell(of: brick)
            var to = from
            while to.row < lowestRow {
                let below = EndlessIICell(column: to.column, row: to.row + 1)
                guard endlessIICellBlocks(below, fill: fill) == false else { break }
                to = below
            }
            guard to != from else { continue }

            fill[from] = 0
            fill[to] = 1
            // Kept in step so a stack of them lands in order rather than each one falling
            // through the space the one before it just claimed
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
        let halfWidth = brick.size.width/2

        var leftLimit = -gameWidth/2 + halfWidth
        var rightLimit = gameWidth/2 - halfWidth
        // The walls, until a brick gets in the way first

        // Measured against what is actually beside it rather than against the cell either
        // side. A Tiny brick is a quarter of a cell, so its neighbours are mostly *in* its own
        // cell - which a cell-granular look never saw, and a Moving Tiny brick slid straight
        // through the three quarters it shares a cell with. Worse, the cell either side held
        // whichever of its four bricks happened to be enumerated last, so the same set blocked
        // it from one direction and not the other.
        let mine = brick.frame
        let overlap = min(mine.height, brickHeight)*0.4
        // Bricks in the same horizontal band. A Tiny brick on the bottom of a cell is stopped
        // by the one beside it, not by the one above it

        for other in endlessIIBricks() where other !== brick {
            let theirs = other.frame
            guard theirs.maxY - mine.minY > overlap, mine.maxY - theirs.minY > overlap else {
                continue
            }
            if theirs.maxX <= mine.minX + 0.5 {
                leftLimit = max(leftLimit, theirs.maxX + halfWidth)
            } else if theirs.minX >= mine.maxX - 0.5 {
                rightLimit = min(rightLimit, theirs.minX - halfWidth)
            }
        }
        return (max(leftLimit, -gameWidth/2 + halfWidth),
                min(rightLimit, gameWidth/2 - halfWidth))
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
        var sides: [EndlessIISide] = endlessHeight >= GameScene.endlessIISideFacingFrom
            || Int.random(in: 1...100) <= GameScene.endlessIISideFacingEarlyChance
            ? [.top, .bottom, .left, .right]
            : [.top, .bottom]

        let reachable = sides.filter { endlessIISideIsReachable($0, from: brick) }
        if reachable.isEmpty == false { sides = reachable }
        // A vulnerable side facing an Indestructible neighbour is a brick that cannot be
        // destroyed at all, which is not a hard brick but a broken one. If every side is
        // blocked the brick stays as it is rather than becoming an accidental wall

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

    /// Whether the ball could actually reach a given face of a brick.
    ///
    /// Only asks about the cell immediately beyond it. A longer look would be more accurate
    /// and much less predictable - the field changes constantly, and a brick that was fair
    /// when it arrived should not have to stay fair for ever.
    func endlessIISideIsReachable(_ side: EndlessIISide, from brick: SKSpriteNode) -> Bool {
        let cell = endlessIICell(of: brick)

        // A wall is not something the ball can get behind. A brick in the outermost column
        // with its soft side facing outward is a brick nothing can ever destroy - which is not
        // a hard brick, it is a broken one
        if side == .left && cell.column <= 0 { return false }
        if side == .right && cell.column >= numberOfBrickColumns - 1 { return false }

        let beyond: EndlessIICell
        switch side {
        case .top: beyond = EndlessIICell(column: cell.column, row: cell.row - 1)
        case .bottom: beyond = EndlessIICell(column: cell.column, row: cell.row + 1)
        case .left: beyond = EndlessIICell(column: cell.column - 1, row: cell.row)
        case .right: beyond = EndlessIICell(column: cell.column + 1, row: cell.row)
        }
        let neighbours = endlessIIOccupancy()[beyond] ?? []
        return neighbours.allSatisfy { $0.texture != brickIndestructible1Texture
                                    && $0.texture != brickIndestructible2Texture }
        // Every brick in the cell, not whichever one answered for it. A vulnerable side facing
        // an Indestructible brick is a brick that cannot be destroyed at all
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

        let field = endlessIIBricks()
        var caught: Set<ObjectIdentifier> = [ObjectIdentifier(brick)]
        var queue = [brick]
        var destroyed: [SKSpriteNode] = []

        while queue.isEmpty == false {
            let centre = queue.removeFirst()
            let blast = endlessIIBlastReach(of: centre)
            let copies = endlessIIWrappedBlastCopies(of: blast)
            for neighbour in field where copies.contains(where: { $0.intersects(neighbour.frame) }) {
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

    /// How far an explosion reaches: everything touching the brick, whatever size either of
    /// them is.
    ///
    /// A brick's own footprint again in each direction. On an ordinary brick that is exactly
    /// the eight cells around it, which is what §4.9 asks for. It was worked out from those
    /// eight cells directly, and that only ever meant the right thing at ordinary size - an
    /// Exploding Tiny brick's neighbours are the Tiny bricks touching it, three of which share
    /// its own cell, so a cell-granular blast missed every one of them. Measuring outward from
    /// the brick gives the same answer at ordinary size and the right one at the other two.
    func endlessIIBlastReach(of brick: SKSpriteNode) -> CGRect {
        let frame = brick.frame
        return frame.insetBy(dx: -frame.width, dy: -frame.height*2)
        // Two rows up and down, one brick each side - play-testing found a single row of
        // blast too polite for the space an explosion visually claims
    }

    /// Removes a brick that something else destroyed, rather than the ball.
    ///
    /// Deliberately not `removeBrick`: that awards a power-up roll and re-counts the field
    /// per brick, which for an explosion means a shower of power-ups and a lot of repeated
    /// work. The score is awarded here and the field counted once at the end.
    func endlessIIDestroy(_ brick: SKSpriteNode) {
        guard brick.parent != nil else { return }
        InGameRecents.shared.brickDestroyed()
        // The crush path skips removeBrick, so it counts itself for the run summary
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

    /// The cells a turning brick needs kept empty, its own included.
    ///
    /// All eight around it rather than the four the generator reserves. The generator only has
    /// to keep the arc clear of the rows it is building, and a diagonal neighbour is exactly
    /// on the edge of the sweep - close enough that anything arriving there later would clip.
    /// Nothing is lost by being careful here: a Spawner only needs somewhere to put a brick,
    /// and there is always somewhere else.
    func endlessIISpinnerClearanceCells() -> Set<EndlessIICell> {
        var reserved: Set<EndlessIICell> = []
        for spinner in endlessIISpinners where spinner.brick.parent != nil {
            let cell = endlessIICell(of: spinner.brick)
            reserved.insert(cell)
            reserved.formUnion(EndlessIIFieldGeometry.neighbours(of: cell))
        }
        return reserved
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
        let reserved = endlessIISpinnerClearanceCells()
        var made = 0

        for cell in EndlessIIFieldGeometry.neighbours(of: endlessIICell(of: brick)) {
            guard geometry.isInsideWidth(cell) else { continue }
            guard cell.row >= 0 && cell.row <= lowestRow else { continue }
            guard occupied[cell]?.isEmpty != false else { continue }
            // Anything at all in the cell, not just a brick that fills it. A cell holding one
            // Tiny brick is not somewhere a whole new brick can go
            guard reserved.contains(cell) == false else { continue }
            // A spinning brick sweeps a circle wider than its own cell, and the generator
            // leaves that room empty. Filling it later put a new brick inside the arc of one
            // already turning, and the two passed through each other

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

    // MARK: - Fixed

    /// Anchors itself where it is the first time it is struck, and is destroyed by the
    /// second hit.
    ///
    /// The interesting part is that the player chooses where the obstacle goes. One hit
    /// plants it, and where it is planted decides what the next twenty rows do - because
    /// anything descending onto it is destroyed by it, so it carves a channel up through
    /// everything that arrives above it.
    func makeFixed(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .fixed
        tint(brick, GameScene.fixedBrickColour)

        let unit = brick.size.height*0.28
        let pin = CGMutablePath()
        pin.move(to: CGPoint(x: -unit, y: unit*0.7))
        pin.addLine(to: CGPoint(x: unit, y: unit*0.7))
        pin.move(to: CGPoint(x: 0, y: unit*0.7))
        pin.addLine(to: CGPoint(x: 0, y: -unit*0.9))
        addGlyph(pin, to: brick, filled: false)
    }

    /// Anchors a Fixed brick, or reports that it is already anchored and should take the hit.
    ///
    /// Returns true when the hit was spent anchoring it, so the caller knows to stop there.
    func endlessIIAnchorIfNeeded(_ brick: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, brick.endlessIIRole == .fixed else { return false }
        guard brick.endlessIIIsAnchored == false else { return false }

        brick.endlessIIIsAnchored = true
        brick.removeAllActions()
        // Any descent already under way has to stop, or it finishes moving after anchoring

        if brick.texture == brickNormalTexture {
            brick.texture = brickMultiHit1Texture
            brick.colorBlendFactor = 0
        }
        // Anchoring also hardens it: a plain Fixed brick was being hit twice in quick
        // succession and never really came into play, so the anchor now costs the full
        // multi-hit ladder to dig out. A brick that was already multi-hit keeps its own
        // ladder, and anything else keeps its own rules - only the plain ones harden

        tint(brick, GameScene.fixedAnchoredColour)
        brick.run(.sequence([.scale(to: 1.15, duration: 0.06),
                             .scale(to: 1, duration: 0.1)]))
        if hapticsSetting { heavyHaptic.impactOccurred() }
        return true
    }

    /// The cells held by anchored bricks, which nothing may descend into.
    func endlessIIAnchoredCells() -> Set<EndlessIICell> {
        var held: Set<EndlessIICell> = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.endlessIIIsAnchored else { return }
            held.insert(self.endlessIICell(of: brick))
        }
        return held
    }

    /// Whether this brick stays where it is when the field descends.
    func endlessIIStaysPut(_ node: SKNode) -> Bool {
        gameMode == .endlessII && node.endlessIIIsAnchored
    }

    /// Whether a descending brick would land on an anchored one, and so be destroyed by it.
    func endlessIICrushedByAnchor(_ node: SKNode, anchored: Set<EndlessIICell>) -> Bool {
        guard gameMode == .endlessII, anchored.isEmpty == false else { return false }
        guard node.endlessIIIsAnchored == false else { return false }

        guard let sprite = node as? SKSpriteNode, sprite.size.width > brickWidth*1.5
                || sprite.size.height > brickHeight*1.5 else {
            let cell = endlessIIGeometry.cell(at: node.position)
            return anchored.contains(EndlessIICell(column: cell.column, row: cell.row + 1))
        }

        // An oversized brick descends onto an anchor with any part of its body, not just
        // the cell its node sits in - a Big brick slid straight past a Fixed brick under
        // its other half (play test). Every column the frame covers is asked, against
        // the row below the frame's lowest occupied row.
        let frame = sprite.frame
        let inset = brickWidth*0.25
        let left = endlessIIGeometry.cell(at: CGPoint(x: frame.minX + inset,
                                                      y: node.position.y)).column
        let right = endlessIIGeometry.cell(at: CGPoint(x: frame.maxX - inset,
                                                       y: node.position.y)).column
        let bottomRow = endlessIIGeometry.cell(at: CGPoint(x: node.position.x,
                                                           y: frame.minY + brickHeight*0.25)).row
        for column in min(left, right)...max(left, right)
        where anchored.contains(EndlessIICell(column: column, row: bottomRow + 1)) {
            return true
        }
        return false
    }

    static let fixedBrickColour = UIColor(red: 0.60, green: 0.80, blue: 0.35, alpha: 1)
    static let fixedAnchoredColour = UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1)

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
        let isBlue = endlessIIPortals().contains { $0.endlessIIPortalIsBlue } == false
        // Whichever colour is not already in the field, rather than "blue if there are none".
        // Those are the same answer until a Portal is removed - Zap clears Indestructible
        // bricks and a Portal is built on one - after which the survivor could be yellow and
        // the next one would be yellow as well. Two ends the same colour is the one thing the
        // colours exist to prevent
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
    func endlessIIEnterPortal(_ brick: SKSpriteNode, entering traveller: SKSpriteNode? = nil) {
        guard gameMode == .endlessII else { return }
        guard endlessIIPortalCooldown <= 0 else { return }
        endlessIIPortalCooldown = GameScene.endlessIIPortalCooldownSeconds

        let ball = traveller ?? self.ball
        endlessIIPortalTraveller = ball
        // The ball that arrived, which with more than one in play is not always the first
        let from = ball.position

        // How it was travelling *before* this step, not now. A Portal is built on an
        // Indestructible brick, so by the time the contact is reported the engine has already
        // bounced the ball off it - and reading the velocity here got the reflection rather
        // than the approach, which is why a ball going up and to the right came out of the far
        // end going up and to the left
        let velocity = ballStateBeforeStep[ObjectIdentifier(ball)]?.velocity
            ?? ball.physicsBody?.velocity ?? .zero
        let partner = endlessIIPortals().first { $0 !== brick }

        let to: CGPoint
        var leaving = velocity
        if endlessIIPortalPaddleClock.isRunning {
            to = CGPoint(x: paddle.position.x,
                         y: paddle.position.y + paddleHeight/2 + ballSize)
            leaving = CGVector(dx: velocity.dx, dy: abs(velocity.dy))
            // The network the play test asked for: while a Portal Paddle runs, every portal
            // connects to it. A brick hit sends the ball out of the paddle, always upward -
            // a ball exiting a paddle downward would be a ball exiting the game
        } else if let partner {
            let exit = endlessIIPortalExit(from: partner, heading: velocity)
            to = exit.point
            leaving = exit.heading
        } else {
            to = CGPoint(x: ball.position.x,
                         y: yBrickOffsetEndless + brickHeight/2 - ballSize)
            // On its own it is a lift to the top of the field. Just below the top, not above
            // it - an earlier version put the ball inside the top screen block and left the
            // physics to shove it back out
        }
        endlessIIPortalKeepsHeading = partner != nil || endlessIIPortalPaddleClock.isRunning
        endlessIIPortalExitVelocity = leaving

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

        showEndlessIIPortalsCooling()
    }

    /// Greys both ends out while the cooldown runs.
    ///
    /// The cooldown is the reason a ball can arrive at a Portal and bounce instead of jumping,
    /// which without this is a Portal that sometimes works and sometimes does not. The rings
    /// carry the state because they already carry the identity: colour means this end is a way
    /// through, grey means it is a wall for the moment.
    func showEndlessIIPortalsCooling() {
        for portal in endlessIIPortals() {
            guard let glyph = portal.childNode(withName: GameScene.glyphName) as? SKShapeNode
            else { continue }
            glyph.removeAllActions()
            glyph.strokeColor = GameScene.portalCoolingColour
        }
    }

    /// Puts their colours back, so the moment a Portal can be used again is one you can see.
    func showEndlessIIPortalsReady() {
        for portal in endlessIIPortals() {
            guard let glyph = portal.childNode(withName: GameScene.glyphName) as? SKShapeNode
            else { continue }
            glyph.removeAllActions()
            glyph.strokeColor = portal.endlessIIPortalIsBlue
                ? GameScene.portalBlueColour
                : GameScene.portalYellowColour
            glyph.run(.sequence([.scale(to: 1.25, duration: 0.08),
                                 .scale(to: 1, duration: 0.12)]))
            // A small pulse as well as the colour. The two ends can be off screen from each
            // other, and coming back to life is the thing worth noticing
        }
    }

    /// What a Portal's rings go while it cannot be entered.
    static let portalCoolingColour = UIColor(white: 0.45, alpha: 1)

    /// Where the ball is put down when it comes out of the far Portal.
    ///
    /// Clear of the brick, along the way it was travelling - and, above all, somewhere it is
    /// still in play. Pushing it along its heading was the whole rule, and a Portal against a
    /// side wall put the ball straight through that wall and out of the game: a jump the
    /// player set up correctly ended the run.
    ///
    /// So the heading is the first choice rather than the only one. If it leads outside, the
    /// ball leaves vertically instead, which is always available to a brick in the field, and
    /// keeps the sense of the journey - it carries on up, or on down. The velocity is never
    /// touched: which way the ball is going is the one thing a doorway must not change.
    func endlessIIPortalExit(from partner: SKSpriteNode,
                            heading velocity: CGVector) -> (point: CGPoint, heading: CGVector) {
        let brick = partner.frame
        let centre = CGPoint(x: brick.midX, y: brick.midY)
        let clearance = max(brick.width, brick.height)/2 + ballSize*1.5
        let playable = endlessIIPlayableRect

        let speed = max(1, hypot(velocity.dx, velocity.dy))
        let unit = CGVector(dx: velocity.dx/speed, dy: velocity.dy/speed)

        // What comes out of the far end is what went into the near one. That is what makes a
        // pair a doorway: a ball crossing the field from bottom left to top right carries on
        // from bottom left to top right, and the player can aim through it
        if playable.contains(CGPoint(x: centre.x + unit.dx*clearance,
                                     y: centre.y + unit.dy*clearance)) {
            return (CGPoint(x: centre.x + unit.dx*clearance, y: centre.y + unit.dy*clearance),
                    velocity)
        }

        // Unless carrying on would put it outside the field, which happens when the far end is
        // against a wall or in the bottom row. Then it bounces: the component that would have
        // taken it out is turned round, and the ball leaves the way it would have if it had
        // arrived there and hit the wall - which is a thing the player can read, where
        // vanishing is not
        let mirrored = [CGVector(dx: -unit.dx, dy: unit.dy),
                        CGVector(dx: unit.dx, dy: -unit.dy),
                        CGVector(dx: -unit.dx, dy: -unit.dy)]

        for heading in mirrored {
            let exit = CGPoint(x: centre.x + heading.dx*clearance,
                               y: centre.y + heading.dy*clearance)
            guard playable.contains(exit) else { continue }
            return (exit, CGVector(dx: heading.dx*speed, dy: heading.dy*speed))
        }

        // A Portal with no clear side at all, which takes a field that has boxed it in on
        // every one. Put the ball where it can go: still in play beats still travelling
        return (CGPoint(x: min(max(centre.x, playable.minX), playable.maxX),
                        y: min(max(centre.y, playable.minY), playable.maxY)),
                velocity)
    }

    /// Where the ball can be set down and still be in the game.
    ///
    /// Inside the walls and below the HUD bar, with the ball's own radius kept clear of each -
    /// a ball placed exactly on a wall is a ball the physics has to push somewhere.
    var endlessIIPlayableRect: CGRect {
        let inset = ballSize/2 + 1
        let top = frame.height/2 - screenBlockTopHeight - inset
        let bottom = -frame.height/2 + inset
        return CGRect(x: -gameWidth/2 + inset, y: bottom,
                      width: max(0, gameWidth - inset*2), height: max(0, top - bottom))
    }

    /// Moves the ball to a portal's exit, once the physics step is out of the way.
    func applyEndlessIIPortalExit() {
        guard let exit = endlessIIPendingPortalExit else { return }
        endlessIIPendingPortalExit = nil

        let ball = endlessIIPortalTraveller ?? self.ball
        endlessIIPortalTraveller = nil
        guard ball.parent != nil else { return }
        // The traveller can be lost between entering a portal and the step finishing

        let velocity = endlessIIPortalExitVelocity
            ?? ball.physicsBody?.velocity ?? .zero
        endlessIIPortalExitVelocity = nil
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

        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)
        let streak = SKShapeNode(path: path)
        streak.zPosition = 2
        streak.strokeColor = GameScene.portalBrickColour
        streak.lineWidth = 3
        streak.lineCap = .round
        streak.alpha = 0.5
        addChild(streak)
        streak.run(.sequence([.fadeOut(withDuration: 0.25), .removeFromParent()]))
        // A line joining the two, so the eye is taken from one end to the other rather than
        // having to find the ball again. Drawn between the actual points rather than as a
        // vertical bar: a lone Portal is a lift and its journey really is straight up, but a
        // pair can be anywhere, and a vertical line between two ends that are not vertically
        // apart points at neither of them
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
        endlessIINotedProgress()
        // Something was destroyed, so whatever the ball is doing it is not stuck
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
        let wasCooling = endlessIIPortalCooldown > 0
        endlessIIPortalCooldown = max(0, endlessIIPortalCooldown - delta)
        if wasCooling && endlessIIPortalCooldown <= 0 { showEndlessIIPortalsReady() }

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
            if let wrapped = endlessIIWrapWandererX(at: x, limits: limits,
                                                    halfWidth: wanderer.brick.size.width/2) {
                x = wrapped
                // Wrap-Around: a clear run to the wall carries on from the far one, same
                // direction - the walls are not walls for the bricks either (§5.4)
            } else if x >= limits.right {
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
        endlessIIPortalTraveller = nil
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
