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

    static let glyphName = "endlessIIGlyph"
    /// The Directional brick's bright bar, named apart from the other glyphs so it can be
    /// replaced on its own when the brick is re-pointed.
    static let directionalEdgeName = "endlessIIDirectionalEdge"
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
        guard endlessIIBreathers.contains(where: { $0.brick === brick }) == false else {
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
    @discardableResult
    private func addGlyph(_ path: CGPath, to brick: SKSpriteNode,
                          filled: Bool = true, scale: CGFloat = 1,
                          weight: CGFloat = 1, contrast: CGFloat = 0.75) -> SKShapeNode {
        let glyph = SKShapeNode(path: path)
        glyph.name = GameScene.glyphName
        glyph.strokeColor = UIColor(white: 0, alpha: contrast)
        glyph.fillColor = filled ? UIColor(white: 0, alpha: contrast) : .clear
        glyph.lineWidth = max(1.5, endlessIIFieldSize(of: brick).height*0.08*weight)
        glyph.setScale(scale)
        glyph.zPosition = 1
        glyph.position = endlessIIBrickCentre(of: brick)
        glyph.userData = ["cell": endlessIIFieldSize(of: brick).height]
        // The cell it was drawn for, so `refreshEndlessIIBrickMarks` can tell how far the
        // brick has changed size since. Kept on the node rather than in a list beside it,
        // because the node is the thing that goes away when the brick does
        brick.addChild(glyph)
        return glyph
        // Positioned at the brick's middle, which on a Big brick and on a shaped one is not
        // the node's origin (§8.6), and weighted by the room the brick actually fills - a
        // shaped brick's sprite is a third of a cell, and a glyph drawn to it would have been
        // a mark too small to read on a brick of ordinary size
    }

    // MARK: - Gravity

    /// Falls into empty cells below it, and falls again whenever its support goes.
    func makeGravity(_ brick: SKSpriteNode) {
        brick.endlessIIRole = .gravity
        tint(brick, GameScene.gravityBrickColour)

        let unit = endlessIIFieldSize(of: brick).height*0.28
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

        let geometry = endlessIIGeometry
        let floor = geometry.centre(of: EndlessIICell(column: 0, row: endlessIILowestRow)).y

        var resting: [ObjectIdentifier: CGRect] = [:]
        var anchoredBricks: Set<ObjectIdentifier> = []
        let everything = endlessIIBricks()
        for brick in everything {
            resting[ObjectIdentifier(brick)] = endlessIIFieldRect(of: brick)
            if brick.endlessIIIsAnchored { anchoredBricks.insert(ObjectIdentifier(brick)) }
        }
        // Where every brick will *be*, not where it is. A stack of fallers has to land in
        // order rather than each one dropping through the space the one before it claimed, so
        // each landing is written back here before the next brick is asked

        let falling = everything
            .filter { $0.endlessIIRole == .gravity }
            .sorted { (resting[ObjectIdentifier($0)]?.minY ?? 0)
                    < (resting[ObjectIdentifier($1)]?.minY ?? 0) }
        // Bottom-most first, by the bottom of the brick rather than by its node - a Big
        // brick's node sits on the top-left of its footprint (§8.6), so sorting by node
        // would put a Big brick above a Normal one it is actually standing beside

        for brick in falling {
            let key = ObjectIdentifier(brick)
            guard let mine = resting[key] else { continue }

            var landing = floor + mine.height/2 - endlessIIFieldSize(of: brick).height/2
            var landedOn: ObjectIdentifier?
            // The floor is a row centre, and what has to sit on it is the brick's *field*
            // extent - a shaped brick's sprite is a third of a cell and its silhouette is not

            for other in everything where other !== brick {
                guard let theirs = resting[ObjectIdentifier(other)] else { continue }
                guard theirs.maxX > mine.minX + 0.5, theirs.minX < mine.maxX - 0.5 else {
                    continue
                }
                // Genuinely under it, not merely beside it. Two bricks in touching cells share
                // an edge exactly, so half a point of inset is the difference between "below
                // me" and "next to me"
                guard theirs.maxY <= mine.minY + 0.5 else { continue }

                let restingCentre = theirs.maxY + mine.height/2
                if restingCentre > landing {
                    landing = restingCentre
                    landedOn = ObjectIdentifier(other)
                }
            }
            // **Measured against frames, not cells** (round 244). The fall used to walk down
            // the occupancy map a whole row at a time, which cannot answer for a Tiny brick:
            // four of them share a cell, so the map can say how full that cell is and never
            // *where* in it the space is - and a quarter-cell brick dropped a whole row goes
            // through its own siblings. `endlessIIWanderLimits` had the same problem going
            // sideways and solved it this way in round 175; this is the same answer turned
            // ninety degrees, and it happens to serve every size at once

            var target = landing + (brick.position.y - mine.midY)
            // Back from "where the brick's middle goes" to "where its node goes", which are
            // the same thing for everything except a Big brick

            if endlessIISizeOf(brick) != .tiny {
                target = endlessIISnappedRestY(target, geometry: geometry)
            }
            // **Everything but a Tiny brick comes to rest on a row centre.** A brick's
            // `position.y` *is* its row (§8.6): the descent and the bottom-row check both read
            // it, and a brick resting half a row off is cleared at the wrong moment or blocks
            // generation for ever. A Tiny brick already lives off the row centres by design -
            // it is a quarter of a cell - and lands on the quarter-cell grid on its own,
            // because whatever it came to rest on is itself on the grid

            let crushes = landedOn.map { anchoredBricks.contains($0) } ?? false
            guard abs(target - brick.position.y) > 0.5 || crushes else { continue }
            // A brick already where it belongs is left alone - unless it is standing on an
            // anchor, which destroys it whether it moved to get there or was built there

            resting[key] = crushes
                ? CGRect(x: mine.minX, y: -.greatestFiniteMagnitude/4,
                         width: mine.width, height: mine.height)
                : mine.offsetBy(dx: 0, dy: target - brick.position.y)
            // A brick about to be destroyed claims nothing, so the next faller down the
            // column may have the space. Moved out of the field rather than removed from the
            // map, so nothing below has to check for a missing entry

            endlessIIFallers[key] = EndlessIIFall(brick: brick, targetY: target,
                                                 crushes: crushes)
            // **A Fixed brick destroys what falls onto it** (the 2026 brick workbook). It
            // lands first and is destroyed on arrival rather than vanishing in mid-air: the
            // brick has to be seen to run into the anchor, or a faller stopping short and
            // disappearing reads as a brick that failed rather than as one that was struck
        }
    }

    /// The nearest row centre at or above a resting height.
    ///
    /// **Above, never below.** A brick that comes to rest on a Tiny one is stopping half a cell
    /// off the grid, and rounding it down would push it into the thing it just landed on.
    /// Rounding up leaves a gap of at most half a cell, which is a brick sitting a little high
    /// rather than two bricks in one place.
    func endlessIISnappedRestY(_ y: CGFloat, geometry: EndlessIIFieldGeometry) -> CGFloat {
        let row = geometry.cell(at: CGPoint(x: 0, y: y)).row
        let centre = geometry.centre(of: EndlessIICell(column: 0, row: row)).y
        guard centre < y - 0.5 else { return centre }
        return geometry.centre(of: EndlessIICell(column: 0, row: row - 1)).y
        // Rows count downward, so the row above is one fewer
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
        // **No glyph.** James, play-test: "remove the arrow icon from moving bricks", which is
        // round 271's own rule applied to the one brick that was still breaking it - Moving is
        // a movement action, and "the movement is enough of an indication of the brick type".
        // A double-headed arrow on a brick that is visibly sliding from side to side was the
        // clearest case of a mark saying what the brick was already saying

        endlessIIWanderers.append(EndlessIIWander(brick: brick,
                                                  direction: Bool.random() ? 1 : -1))
    }

    /// How far a wandering brick may travel before something is in the way.
    ///
    /// Measured from what is actually beside it, so it re-reads the field rather than
    /// trusting limits worked out when the brick was made - the field it sits in changes
    /// constantly underneath it.
    func endlessIIWanderLimits(for brick: SKSpriteNode) -> (left: CGFloat, right: CGFloat) {
        let halfWidth = endlessIIFieldSize(of: brick).width/2
        let offset = endlessIIBrickCentre(of: brick).x
        // **How far the drawing is from the node**, which is half a cell for a Big brick: its
        // node sits on the top-left cell's centre so the node can stay on a row (§8.6), and its
        // sprite covers all four. Everything below is worked out for the *drawing* - the walls
        // are where the drawing must stop, and `endlessIIFieldRect` gives the neighbours in the
        // same space - and the tick moves the *node*, so the answer is converted at the end.
        //
        // James, play-test: "a big moving brick is moving beyond the edge of the game view by
        // half a brick width". Half a brick is exactly this offset, and it read as the brick
        // stopping half a cell short at the other wall as well

        var leftLimit = -gameWidth/2 + halfWidth
        var rightLimit = gameWidth/2 - halfWidth
        // The walls, until a brick gets in the way first

        // Measured against what is actually beside it rather than against the cell either
        // side. A Tiny brick is a quarter of a cell, so its neighbours are mostly *in* its own
        // cell - which a cell-granular look never saw, and a Moving Tiny brick slid straight
        // through the three quarters it shares a cell with. Worse, the cell either side held
        // whichever of its four bricks happened to be enumerated last, so the same set blocked
        // it from one direction and not the other.
        let mine = endlessIIFieldRect(of: brick)
        let overlap = min(mine.height, brickHeight)*0.4
        // Bricks in the same horizontal band. A Tiny brick on the bottom of a cell is stopped
        // by the one beside it, not by the one above it

        for other in endlessIIBricks() where other !== brick {
            guard other.endlessIIIsAnchored == false else { continue }
            // **An anchor is not a wall, it is a hazard** (the 2026 brick workbook: a Fixed
            // brick destroys what runs into it). Left in this list it would have turned the
            // wanderer round a hair's breadth short, which is the opposite of running into
            // something. Ignored here, the brick walks in and `endlessIIResolveAnchorOverlaps`
            // destroys it on the frame it arrives
            let theirs = endlessIIFieldRect(of: other)
            guard theirs.maxY - mine.minY > overlap, mine.maxY - theirs.minY > overlap else {
                continue
            }
            if theirs.maxX <= mine.minX + 0.5 {
                leftLimit = max(leftLimit, theirs.maxX + halfWidth)
            } else if theirs.minX >= mine.maxX - 0.5 {
                rightLimit = min(rightLimit, theirs.minX - halfWidth)
            }
        }
        return (max(leftLimit, -gameWidth/2 + halfWidth) - offset,
                min(rightLimit, gameWidth/2 - halfWidth) - offset)
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
        let preferred: [EndlessIISide] = endlessHeight >= GameScene.endlessIISideFacingFrom
            || Int.random(in: 1...100) <= GameScene.endlessIISideFacingEarlyChance
            ? [.top, .bottom, .left, .right]
            : [.top, .bottom]

        let open = endlessIIOpenSides(from: brick)
        let side: EndlessIISide = brick.endlessIIVulnerableSide
            ?? preferred.filter(open.contains).randomElement()
            ?? open.randomElement()
            ?? .bottom
        // A side the brick already carries is kept. That is how a resumed run comes back with
        // the same face open (round 174): the restore writes the saved side before applying the
        // role, and rolling here would throw it away - the same bargain `makeFace` makes with
        // a shaped brick's orientation.
        //
        // Otherwise the depth's own sides are preferred, and **a brick whose depth sides are
        // all blocked reaches past them to any open side at all** rather than settling for a
        // blocked one (James, round 233: a directional brick "shouldn't have its open face
        // next to an indestructible brick"). This used to keep the depth pool whenever none of
        // it was reachable, which meant a brick with an Indestructible above and another below
        // was handed one of those two faces and could never be destroyed - a brick with its
        // one soft side pressed against a wall, when it had a perfectly good side going spare.
        // An early left-facing brick is rarer than the depth ramp intends; an impossible brick
        // is worse than rare.
        //
        // `.bottom` is the last resort and is never reached from the generator: nothing with
        // no open side at all is offered the role (see `endlessIICanTake`). It is here for the
        // restore path, which applies the role to whatever the save says was directional
        brick.endlessIIRole = .directional
        brick.endlessIIVulnerableSide = side
        if endlessIIDirectionalArt(side, size: endlessIISizeOf(brick)) == nil {
            tint(brick, GameScene.directionalBrickColour)
        }
        endlessIIDrawVulnerableEdge(on: brick, side: side)
        // **No tint where there is a panel** (James, round 284: "for the directional brick, the
        // open side should show the brick underneath. Right now, that side looks grey. The
        // brick underneath can be any brick type, so it should be possible to tell what brick
        // is underneath").
        //
        // The grey was how a directional brick said what it was before round 271, when the mark
        // was a thin bright bar on an otherwise ordinary brick and the body had to carry the
        // identity. `tint` writes `colorBlendFactor = 1`, which does not shade the texture - it
        // *replaces* it - so a directional Multi-hit and a directional Indestructible were the
        // same grey oblong, and the one clear side showed grey too.
        //
        // The panel says it now, and says it better: three sides darkened, one left alone. What
        // shows through the open side is the brick's own picture, which is the whole point of
        // leaving it open. The tint stays only where no panel is drawn, because there the bar
        // is a small mark on a brick that would otherwise look ordinary.
    }

    /// The picture that says which face is soft, replacing whatever is there already.
    ///
    /// James, round 271: "I've created graphics that should overlay the bricks below, just for
    /// the 2x1 and 2x2 shape bricks. These can be applied to each brick size. The open side of
    /// the brick (i.e. the side of the brick that can be hit and causes damage) has been left
    /// open/transparent so the brick below can be seen."
    ///
    /// **The inverse of the bar it replaces**, and better for it: the bar drew the soft side
    /// bright and left the three hard ones looking like ordinary brick, so the mark to read was
    /// the small one. The overlay darkens the three hard sides and leaves the soft one clear,
    /// so what shows through the picture is the way in.
    ///
    /// Three pictures, for the three sizes worth drawing one for: 2:1 for Tiny and Normal,
    /// square for a Square brick, and a Big one of its own (round 274) - a Big brick is 2:1
    /// like an ordinary one and four times the area, so the ordinary panel stretched over it
    /// would have four times the border and a bevel to match. A Tiny brick keeps the ordinary
    /// panel scaled down, which is right: it is the same shape. Sized and placed off the
    /// *cell* rather than off `brick.size`, which is the hiding rectangle once a face is on it.
    func endlessIIDrawVulnerableEdge(on brick: SKSpriteNode, side: EndlessIISide) {
        brick.childNode(withName: GameScene.directionalEdgeName)?.removeFromParent()

        let cell = endlessIIFieldSize(of: brick)
        if let art = endlessIIDirectionalArt(side, size: endlessIISizeOf(brick)) {
            let panel = SKSpriteNode(texture: art, size: cell)
            panel.name = GameScene.directionalEdgeName
            panel.zPosition = 1
            panel.position = endlessIIBrickCentre(of: brick)
            brick.addChild(panel)
            return
        }
        // The drawn bar below is what a brick with no picture keeps, which is the same bargain
        // the shaped faces make: art that does not exist is a real answer, and the mark that
        // was there for two hundred rounds is a better fallback than no mark at all

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
        bar.name = GameScene.directionalEdgeName
        bar.fillColor = brickWhite
        bar.strokeColor = .clear
        bar.zPosition = 1
        bar.position = CGPoint(x: (0.5 - brick.anchorPoint.x)*width,
                               y: (0.5 - brick.anchorPoint.y)*height)
        brick.addChild(bar)
        // Named for itself rather than sharing the general glyph name, so re-pointing a brick
        // can take away the old bar and leave every other decoration on it alone. The sweep
        // below is the only caller that needs that, and it needs it exactly
    }

    /// The overlay drawn for a soft side, at the proportions this brick comes in.
    func endlessIIDirectionalArt(_ side: EndlessIISide, size: BrickSize) -> SKTexture? {
        let name = "BrickDirectional" + side.artName + "Open"
            + GameScene.artSuffix(for: size)
        guard UIImage(named: name) != nil else { return nil }
        return SKTexture(imageNamed: name)
        // Asked of the catalogue, not of SpriteKit, for the reason `endlessIIShapedArt` gives:
        // a name that is not there comes back as a placeholder rather than as nil
    }

    /// Keeps a brick's mark the size of the brick.
    ///
    /// James, play-test: "the icon on the brick should scale with the brick. For example a
    /// fixed brick that shrinks and grows, the icon should shrink and grow with the brick."
    ///
    /// Which is right and was never true: a glyph is drawn once at the cell the brick was built
    /// for, and Breathing changes that cell every frame - so a Fixed brick that also breathes
    /// kept a full-size T on a brick shrinking to half a cell, and the mark ended up wider than
    /// the thing it was marking. The directional panel had the same problem for the same
    /// reason, one node type over.
    ///
    /// Driven from the frame, like everything else that moves on a brick (§8.6), and inside the
    /// sweep that already visits every brick rather than in one of its own.
    func refreshEndlessIIBrickMarks(on brick: SKSpriteNode) {
        let cell = endlessIIFieldSize(of: brick)
        let centre = endlessIIBrickCentre(of: brick)

        if let glyph = brick.childNode(withName: GameScene.glyphName) as? SKShapeNode {
            let built = (glyph.userData?["cell"] as? CGFloat) ?? cell.height
            let scale = built > 0.01 ? cell.height/built : 1
            if abs(glyph.xScale - scale) > 0.001 { glyph.setScale(scale) }
            if glyph.position != centre { glyph.position = centre }
        }
        // Scaled off the *height*, which is the axis every size changes on together - a
        // Breathing brick shrinks about its middle on both, and scaling each axis separately
        // would let a mark go oval on anything that ever changes only one

        if let panel = brick.childNode(withName: GameScene.directionalEdgeName)
            as? SKSpriteNode {
            if panel.size != cell { panel.size = cell }
            if panel.position != centre { panel.position = centre }
        }
        if let bar = brick.childNode(withName: GameScene.directionalEdgeName) as? SKShapeNode {
            if bar.position != centre { bar.position = centre }
            // The drawn bar is the fallback for a brick with no panel. Its *path* is built to
            // the cell and is not rebuilt here, which is the one thing left un-followed - it
            // only shows where no picture exists, and every size has one
        }
    }

    /// Every face of this brick the ball could actually reach.
    ///
    /// Empty means the brick is walled in: an Indestructible neighbour or the field's edge on
    /// all four sides.
    func endlessIIOpenSides(from brick: SKSpriteNode) -> [EndlessIISide] {
        endlessIIOpenSides(from: brick, in: endlessIIOccupancy())
    }

    /// The same, against a field that has already been read.
    func endlessIIOpenSides(from brick: SKSpriteNode,
                            in occupancy: [EndlessIICell: [SKSpriteNode]]) -> [EndlessIISide] {
        EndlessIISide.allCases.filter { endlessIISideIsReachable($0, from: brick, in: occupancy) }
    }

    /// Turns any Directional brick whose soft face has since been blocked to face a side the
    /// ball can still reach.
    ///
    /// James, round 233: a directional brick should not "have its open face next to an
    /// indestructible brick" or "be penned in by them". Refusing the role at generation
    /// (`endlessIICanTake`) only answers the bricks that were already surrounded when they
    /// arrived, and in this mode almost none of them are: **the field descends and rows are
    /// generated above it**, so a brick with an open top face is offered that face over an
    /// empty cell and an Indestructible brick is lowered into it a moment later. The check at
    /// birth cannot see a row that does not exist yet.
    ///
    /// So the rule is enforced again after each new row, where the block actually happens. A
    /// brick that has become impossible is turned rather than removed - it keeps its type, its
    /// colour and its place, and only the bright bar moves - and one with nowhere left to turn
    /// is left as it is, because the field is descending and its neighbours will not be there
    /// for long.
    ///
    /// Re-pointing a brick the player has been aiming at is a real cost, and it is the smaller
    /// one: the alternative is a brick that cannot be destroyed at all, sitting in a field
    /// that has to be cleared.
    func endlessIIRepointBlockedDirectionals() {
        guard gameMode == .endlessII else { return }
        let occupancy = endlessIIOccupancy()
        // Read once and asked of every brick, rather than rebuilt for each of the four sides
        // of each of them
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode,
                  brick.endlessIIRole == .directional,
                  let side = brick.endlessIIVulnerableSide,
                  self.endlessIISideIsReachable(side, from: brick, in: occupancy) == false,
                  let open = self.endlessIIOpenSides(from: brick, in: occupancy).randomElement()
            else { return }
            brick.endlessIIVulnerableSide = open
            self.endlessIIDrawVulnerableEdge(on: brick, side: open)
        }
    }

    /// Whether the ball could actually reach a given face of a brick.
    ///
    /// Only asks about the cell immediately beyond it. A longer look would be more accurate
    /// and much less predictable - the field changes constantly, and a brick that was fair
    /// when it arrived should not have to stay fair for ever.
    func endlessIISideIsReachable(_ side: EndlessIISide, from brick: SKSpriteNode) -> Bool {
        endlessIISideIsReachable(side, from: brick, in: endlessIIOccupancy())
    }

    /// The same question against a field that has already been read.
    ///
    /// `endlessIIOccupancy()` walks every brick in the scene to build its map, so asking four
    /// sides of a dozen bricks the short way is fifty of those walks. The sweep below reads
    /// the field once and asks with this.
    func endlessIISideIsReachable(_ side: EndlessIISide, from brick: SKSpriteNode,
                                  in occupancy: [EndlessIICell: [SKSpriteNode]]) -> Bool {
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
        let neighbours = occupancy[beyond] ?? []
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

        let unit = endlessIIFieldSize(of: brick).height*0.3
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
        playMayhemSound("explosion")
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

        let unit = endlessIIFieldSize(of: brick).height*0.28
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

    /// Fills some of the empty cells around a destroyed Spawner with ordinary bricks.
    ///
    /// Ordinary, and never another Spawner, so what it leaves behind is something the player
    /// can clear rather than something that keeps growing.
    ///
    /// **Some, not all** (James, on the 2026 brick workbook: "spawner bricks when hit create
    /// between 1 and 8 bricks in the adjacent cells. This number and the position of the new
    /// bricks around the spawner should be randomised"). It used to fill every cell it could
    /// reach, which made it the most predictable brick in the mode: a Spawner in the open
    /// always produced the same ring, and one against a wall always produced the same half of
    /// one. What it leaves behind is now a shape the player has to read.
    /// How long a Spawner waits before it may fill its neighbours again.
    ///
    /// **A ball can rattle against an Indestructible Spawner** (James, round 214: "a spawned
    /// indestructible brick should have a cooling off period after spawning new bricks so the
    /// ball can't become trapped by continuously spawning bricks. Perhaps a second or 2").
    ///
    /// A destructible Spawner fires once, on the way out. An indestructible one never leaves,
    /// so it fires on *contact* instead - which is what makes it something that keeps working
    /// rather than something that happens once. The failure mode is the same property seen
    /// from the other side: a ball bouncing between it and a neighbour hits it several times a
    /// second, and each hit refills the cells around it, so the ball builds its own cell wall
    /// and is sealed in by the thing it is hitting.
    static let endlessIISpawnCoolOff: TimeInterval = 1.5

    /// Which of a Spawner's empty neighbours get bricks this time.
    ///
    /// Between one and eight, the count and the positions both drawn fresh (James, on the
    /// brick workbook). Eight is the ceiling because eight is all a cell has; the real cap is
    /// how many of them are empty, and a Spawner with one empty neighbour fills it every time
    /// rather than sometimes doing nothing - a hit that visibly produces nothing reads as a
    /// brick that failed rather than as one that rolled low.
    ///
    /// A pure function taking its own dice, because the scene it is called from cannot be
    /// stood up in a test and "sometimes fewer than all of them" is exactly the kind of
    /// statement that is true of the code and false of the game.
    static func endlessIISpawnChoice(from room: [EndlessIICell],
                                     count: (Int) -> Int = { Int.random(in: 1...$0) },
                                     order: ([EndlessIICell]) -> [EndlessIICell] = {
                                         $0.shuffled()
                                     }) -> [EndlessIICell] {
        guard room.isEmpty == false else { return [] }
        let wanted = min(max(count(min(room.count, 8)), 1), room.count)
        return Array(order(room).prefix(wanted))
        // Shuffled before it is trimmed, so *which* cells are filled is drawn as well as how
        // many. Taking the first n of the neighbour list in its natural order would have given
        // a count that varied and a shape that never did
    }

    func endlessIISpawn(around brick: SKSpriteNode) {
        guard gameMode == .endlessII else { return }

        let now = CACurrentMediaTime()
        let last = brick.userData?["endlessIILastSpawn"] as? CFTimeInterval
        if let last, now - last < GameScene.endlessIISpawnCoolOff { return }
        if brick.userData == nil { brick.userData = NSMutableDictionary() }
        brick.userData?["endlessIILastSpawn"] = now
        // Stamped on the brick rather than kept on the scene: each Spawner cools off on its
        // own, so two of them in a field do not share one timer and silence each other.
        // Stamped *before* the work, so a spawn that fills nothing still starts the clock -
        // a brick surrounded by full cells is exactly the one being hit repeatedly

        let occupied = endlessIIOccupancy()
        let geometry = endlessIIGeometry
        let lowestRow = endlessIILowestRow
        let reserved = endlessIISpinnerClearanceCells()
        var made = 0

        let room = EndlessIIFieldGeometry.neighbours(of: endlessIICell(of: brick)).filter { cell in
            guard geometry.isInsideWidth(cell) else { return false }
            guard cell.row >= 0 && cell.row <= lowestRow else { return false }
            guard occupied[cell]?.isEmpty != false else { return false }
            // Anything at all in the cell, not just a brick that fills it. A cell holding one
            // Tiny brick is not somewhere a whole new brick can go
            guard reserved.contains(cell) == false else { return false }
            // A spinning brick sweeps a circle wider than its own cell, and the generator
            // leaves that room empty. Filling it later put a new brick inside the arc of one
            // already turning, and the two passed through each other
            return true
        }

        for cell in GameScene.endlessIISpawnChoice(from: room) {
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
        endlessIIDrawFixedPin(on: brick)
    }

    /// The upside-down T that says a brick stops where it is, drawn heavier once it has.
    ///
    /// James, round 271: "keep the existing T shape, but flip it upside down so the top of the
    /// T is at the bottom of the brick. I think this better denotes it stopping. When it is
    /// locked in place after being hit, make the T shape thicker and higher contrast in colour
    /// to denote it is locked."
    ///
    /// Which is the right way round and reads immediately: a stem standing on a bar is a thing
    /// resting on the ground, and the bar was on top saying nothing at all. The two weights are
    /// the same mark rather than two marks, so a brick that locks while you are watching gets
    /// heavier rather than changing into something else.
    func endlessIIDrawFixedPin(on brick: SKSpriteNode) {
        brick.childNode(withName: GameScene.glyphName)?.removeFromParent()

        let unit = endlessIIFieldSize(of: brick).height*0.28
        let pin = CGMutablePath()
        pin.move(to: CGPoint(x: -unit, y: -unit*0.7))
        pin.addLine(to: CGPoint(x: unit, y: -unit*0.7))
        pin.move(to: CGPoint(x: 0, y: -unit*0.7))
        pin.addLine(to: CGPoint(x: 0, y: unit*0.9))

        let locked = brick.endlessIIIsAnchored
        addGlyph(pin, to: brick, filled: false,
                 weight: locked ? 1.9 : 1, contrast: locked ? 1 : 0.75)
    }

    /// The row centre a brick belongs on, for a brick that has been stopped between two.
    ///
    /// The field's own geometry answers it: `cell(at:)` rounds a point to the nearest cell and
    /// `centre(of:)` gives that cell's middle, so this is the same grid every other brick is
    /// placed on rather than a second opinion about where the rows are. A Big brick keeps its
    /// node on a row centre and expresses its size as an anchor point (§8.6), so measuring the
    /// node's own position is right for every size.
    func endlessIISnappedRowY(for brick: SKSpriteNode) -> CGFloat {
        guard brickHeight > 0, brickWidth > 0 else { return brick.position.y }
        let geometry = endlessIIGeometry
        return geometry.centre(of: geometry.cell(at: brick.position)).y
    }

    /// Anchors a Fixed brick, or reports that it is already anchored and should take the hit.
    ///
    /// Returns true when the hit was spent anchoring it, so the caller knows to stop there.
    func endlessIIAnchorIfNeeded(_ brick: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, brick.endlessIIRole == .fixed else { return false }
        guard brick.endlessIIIsAnchored == false else { return false }

        brick.endlessIIIsAnchored = true
        brick.removeAllActions()
        brick.position.y = endlessIISnappedRowY(for: brick)
        defer { endlessIIDrawFixedPin(on: brick) }
        // Redrawn heavier at the end of anchoring rather than here, because the texture below
        // changes on the way through and the glyph's weight is measured off the brick
        // Any descent already under way has to stop, or it finishes moving after anchoring -
        // **and stopping it leaves the brick wherever the animation had got to**, which is
        // halfway between two rows (James, round 184, with a screenshot: "somehow a normal
        // size fixed brick ended up becoming fixed halfway between 2 rows"). A brick's
        // `position.y` *is* its row (§8.6): the descent reads it, the bottom-row check reads
        // it, and a brick off its row centre is cleared at the wrong moment or blocks
        // generation for ever. So the anchor lands it back on the nearest row centre - the
        // one it was nearest when the ball caught it mid-descent

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
        playMayhemSound("brickLocked")
        return true
    }

    /// The cells held by anchored bricks, which nothing may descend into.
    func endlessIIAnchoredCells() -> Set<EndlessIICell> {
        var held: Set<EndlessIICell> = []
        let geometry = endlessIIGeometry
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode, brick.endlessIIIsAnchored else { return }
            let origin = self.endlessIICell(of: brick)
            let span = geometry.footprint(of: self.endlessIIFieldSize(of: brick))
            for row in 0..<span.rows {
                for column in 0..<span.columns {
                    held.insert(EndlessIICell(column: origin.column + column,
                                              row: origin.row + row))
                }
            }
        }
        return held
        // **Every cell it holds, not just the one its node is in.** A Big brick can be Fixed
        // since round 237, and an anchor that claimed one of its four cells would have let the
        // field descend into the other three - which is the trap a Big brick sets for anything
        // reading its node (§8.6), and the reason `endlessIIOccupancy` has always spanned
    }

    /// Whether this brick stays where it is when the field descends.
    func endlessIIStaysPut(_ node: SKNode) -> Bool {
        gameMode == .endlessII && node.endlessIIIsAnchored
    }

    /// Whether a descending brick would land on an anchored one, and so be destroyed by it.
    func endlessIICrushedByAnchor(_ node: SKNode, anchored: Set<EndlessIICell>) -> Bool {
        guard gameMode == .endlessII, anchored.isEmpty == false else { return false }
        guard node.endlessIIIsAnchored == false else { return false }

        guard let sprite = node as? SKSpriteNode else {
            let cell = endlessIIGeometry.cell(at: node.position)
            return anchored.contains(EndlessIICell(column: cell.column, row: cell.row + 1))
        }
        let size = endlessIIFieldSize(of: sprite)
        guard size.width > brickWidth*1.5 || size.height > brickHeight*1.5 else {
            let cell = endlessIIGeometry.cell(at: node.position)
            return anchored.contains(EndlessIICell(column: cell.column, row: cell.row + 1))
        }
        // The room the brick fills, not its sprite's. A shaped brick is always one ordinary
        // cell, so this asks the same question of it either way - but its sprite is a third of
        // a cell, and a test written against the sprite would have answered "not oversized"
        // for the wrong reason and gone on being right by luck (`endlessIIFieldSize`)

        // An oversized brick descends onto an anchor with any part of its body, not just
        // the cell its node sits in - a Big brick slid straight past a Fixed brick under
        // its other half (play test). Every column the frame covers is asked, against
        // the row below the frame's lowest occupied row.
        let frame = endlessIIFieldRect(of: sprite)
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

    /// Destroys an oversized brick that has ended up sharing space with an anchored one.
    ///
    /// `endlessIICrushedByAnchor` answers "is this brick descending onto an anchor", which is
    /// one of the two ways the field can reach an overlap and not the one James saw (round 172:
    /// "I have a big brick overlapping a fixed brick - in this case the fixed brick should
    /// destroy the big brick"). The other way round: **a Fixed brick anchors when it is
    /// struck**, and a Big brick's other half may already be over the cell it anchors in. No
    /// descent happens, so nothing asks the crush rule, and the two sit inside each other.
    ///
    /// Asked every frame rather than at the step, because that is the only way to catch a state
    /// that arrives without the field moving. Cheap: it does nothing at all until something is
    /// anchored, and Mayhem's fields are tens of bricks.
    ///
    /// The frames are inset before they are compared, so bricks that merely *touch* - which
    /// every pair of neighbours does - are not read as overlapping.
    func endlessIIResolveAnchorOverlaps() {
        guard gameMode == .endlessII else { return }

        var anchors: [CGRect] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard node.endlessIIIsAnchored, let sprite = node as? SKSpriteNode else { return }
            anchors.append(self.endlessIIFieldRect(of: sprite))
        }
        guard anchors.isEmpty == false else { return }

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let sprite = node as? SKSpriteNode, sprite.parent != nil,
                  sprite.endlessIIIsAnchored == false else { return }
            let frame = self.endlessIIFieldRect(of: sprite)
                .insetBy(dx: self.brickWidth*0.25, dy: self.brickHeight*0.25)
            // **Any brick, not only an oversized one** (the 2026 brick workbook: a Fixed brick
            // "destroys any brick that runs into it"). It was restricted to Big bricks because
            // they were the only ones that could end up sharing a cell - the generator never
            // puts two ordinary bricks in one, and destroying a brick on a near miss is a
            // brick the player was owed. A Moving brick can now walk into an anchor, so the
            // restriction stopped being true; the *inset* is what keeps the near miss safe,
            // and it always did the real work. Two bricks in touching cells inset by a quarter
            // of a cell each leave half a cell of daylight between them
            guard anchors.contains(where: { $0.intersects(frame) }) else { return }

            self.endlessIIBrickDestroyed(sprite)
            self.endlessIIDestroy(sprite)
            // The ordinary destroy path, so it scores, rolls and counts like the crush does
        }
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
        refreshEndlessIIBrickArt(brick)
        endlessIIRefreshFace(on: brick)
        refreshEndlessIIPortalGlow(on: brick)
        if endlessIIWearsPortalArt(brick) { return }
        // The glow goes on before the early return, because it belongs to every Portal and the
        // return is about the *glyph*: a shape with no picture still wants its halo
        // **The picture James drew has the rings in it**, so a brick wearing it needs no glyph
        // drawn on top - two sets of rings is one more than a Portal has. Everything below is
        // what a Portal wore for two hundred rounds and still wears wherever there is no
        // picture: a Portal may take a Wedge, a dome or a notch (`takenByAPortal`), and only
        // the plain, Rounded and square Diamond ones are drawn

        // Left untinted, unlike every other role here. `colorBlendFactor` colourises a
        // texture but the result is still modulated by what the texture looks like, and the
        // Indestructible artwork is dark and shaded - so any colour comes out as a dark,
        // muddy version of itself. That is the right look for a brick that cannot be broken,
        // so the identity goes in the glyph rather than the body.
        let cell = endlessIIFieldSize(of: brick)
        let radius = min(cell.width, cell.height)*0.3
        let rings = CGMutablePath()
        rings.addEllipse(in: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2))
        rings.addEllipse(in: CGRect(x: -radius*0.5, y: -radius*0.5,
                                    width: radius, height: radius))
        // Two rings, so it cannot be mistaken for a Rounded brick's single one

        let glyph = SKShapeNode(path: rings)
        glyph.name = GameScene.glyphName
        glyph.strokeColor = GameScene.portalReadyColour
        // **One colour, both ends**, since round 273 - James: "Portal is just 1 colour now.
        // Both bricks will just be one colour." It was blue and yellow so a player could see
        // which end pairs with which, and with exactly two in the field at a time that was
        // never information they had to act on: neither is the way in, and the far end is the
        // far end whichever colour it is. `endlessIIPortalIsBlue` is still set and still saved,
        // because a save format is not the place to economise and an old save has to decode
        glyph.fillColor = .clear
        glyph.lineWidth = max(1.5, cell.height*0.1)
        glyph.zPosition = 1
        glyph.position = endlessIIBrickCentre(of: brick)
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
            to = CGPoint(x: paddle.position.x, y: paddleTopY + ballSize)
            // The paddle's *own* top: a ball put down at the plain paddle's height while a
            // shaped one is on is a ball put down inside the silhouette, and a body the engine
            // finds inside another body is one it shoves out - which is round 232's sliding
            // ball, arriving by a different door
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
        if endlessIIPortalPaddleClock.isRunning == false, endlessIIPortalDriftDegrees != 0 {
            leaving = rotated(leaving, byDegrees: endlessIIPortalDriftDegrees)
        }
        endlessIIPortalDriftDegrees = min(
            endlessIIPortalDriftDegrees + GameScene.endlessIIPortalDriftStep,
            GameScene.endlessIIPortalDriftLimit)
        // **Portal drift** (round 101): each paddle-less transit turns the exit a little
        // further off true, so a portal pair whose geometry feeds itself cannot keep doing
        // so - the loop-breaker for the one cycle that never touches a wall or a brick and
        // so never shows the bounce detector a bounce. First transit exits exactly as
        // aimed; the drift only exists inside a run of consecutive transits, and a paddle
        // touch resets it. The Portal Paddle network is exempt: its exit is the paddle
        // itself, already the player's

        if partner != nil, endlessIIPortalPaddleClock.isRunning == false { _ = award(81) }
        // **Wormhole**: "have the ball travel between 2 portal bricks" (round 310). Two
        // *bricks*, so a lone portal lifting the ball to the top of the field does not count,
        // and neither does the Portal Paddle network - while that runs every portal exits at
        // the paddle rather than at another brick, which is the same journey the achievement is
        // not describing

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
        playMayhemSound("brickPortal")
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
            endlessIIPortalMark(on: portal)?.removeAllActions()
            endlessIIShowPortal(portal, cooling: true)
        }
    }

    /// Puts their colours back, so the moment a Portal can be used again is one you can see.
    func showEndlessIIPortalsReady() {
        for portal in endlessIIPortals() {
            endlessIIShowPortal(portal, cooling: false)
            endlessIIPortalMark(on: portal)?
                .run(.sequence([.scale(to: 1.25, duration: 0.08),
                                .scale(to: 1, duration: 0.12)]))
            // A small pulse as well as the colour. The two ends can be off screen from each
            // other, and coming back to life is the thing worth noticing
        }
    }

    /// Redraws whatever face a brick is wearing, now, rather than on the next frame.
    ///
    /// The per-frame sweeps get to this a frame later, which is fine for a Multi-hit brick
    /// stepping down and not fine for a Portal: `makePortal` has to know whether a picture is
    /// showing *before* it decides whether to draw the rings, and asking a frame early would
    /// have it draw them onto a brick that is about to have a Portal's own face.
    func endlessIIRefreshFace(on brick: SKSpriteNode) {
        if let shape = brick.childNode(withName: GameScene.roundedBrickOutlineName)
            as? SKShapeNode {
            _ = refreshEndlessIIFaceArt(brick, shape, .rounded,
                                        cell: endlessIIFaceCell(brick, shape: shape))
        }
        if let shape = brick.childNode(withName: GameScene.brickFaceName) as? SKShapeNode,
           let art = brick.endlessIIFace.flatMap(GameScene.shapedArt(for:)) {
            _ = refreshEndlessIIFaceArt(brick, shape, art,
                                        cell: endlessIIFaceCell(brick, shape: shape))
        }
    }

    /// The node that says whether a Portal can be entered.
    ///
    /// The drawn rings for a Portal with no picture, and the picture itself for one that has
    /// got one - which may be inside a face node, because a Portal can be Rounded or shaped.
    /// The cooling state is real feedback and had to survive the art arriving: it is the whole
    /// of what stops a ball arriving at the top and being sent straight back.
    func endlessIIPortalMark(on brick: SKSpriteNode) -> SKNode? {
        if let glyph = brick.childNode(withName: GameScene.glyphName) { return glyph }
        // **The rings win where they exist**, and they exist only where no picture does -
        // `makePortal` draws them precisely when it finds nothing else saying Portal

        for face in [GameScene.brickFaceName, GameScene.roundedBrickOutlineName] {
            if let node = brick.childNode(withName: face)?
                .childNode(withName: GameScene.faceArtName) { return node }
        }
        return brick.childNode(withName: GameScene.brickArtName)
    }

    /// Whether this brick is showing a picture of a *Portal*, as opposed to a picture.
    ///
    /// The distinction the first version of this missed. A Portal wearing a Wedge has face art
    /// - the Indestructible wedge it has always worn, because there is no Portal wedge drawn -
    /// and asking only whether a face has art said yes, so the brick lost its rings and had
    /// nothing at all left saying what it was. The name the art was resolved from is the thing
    /// that actually answers.
    func endlessIIWearsPortalArt(_ brick: SKSpriteNode) -> Bool {
        if brick.childNode(withName: GameScene.brickArtName) != nil { return true }

        let suffix = GameScene.artSuffix(for: endlessIISizeOf(brick))
        let mirrored = brick.endlessIIFaceMirrored ?? false
        let flipped = brick.endlessIIFaceFlipped ?? false
        for (name, art) in [(GameScene.roundedBrickOutlineName, GameScene.ShapedBrickArt.rounded),
                            (GameScene.brickFaceName,
                             brick.endlessIIFace.flatMap(GameScene.shapedArt(for:)) ?? .rounded)]
        where brick.childNode(withName: name) != nil {
            let source = endlessIIFaceArtName(for: brick, art, mirrored: mirrored,
                                              flipped: flipped, suffix: suffix)
            if source == GameScene.portalBrickArtName { return true }
        }
        return false
    }

    /// The glow that sits behind a Portal brick, and the name it answers to.
    static let portalGlowName = "endlessIIPortalGlow"

    /// **One picture per shape, turned by the node rather than drawn four ways.**
    ///
    /// James, round 315: "some glow graphics for all shapes of the portal bricks - these
    /// should sit centred behind portal bricks to the same scale - they should not have a
    /// physics body - these can be rotated and flipped as needed for the different brick
    /// orientations."
    ///
    /// So the name carries the shape and the size and **never the orientation**, which is
    /// where this parts company with `endlessIIShapedArt`. That builder asks for `Wedge90`
    /// before `Wedge` because round 262 drew the *bricks* four ways: a wedge lit from above is
    /// lit from below the moment it is flipped, and only a separate picture fixes that. A glow
    /// has no lighting to get wrong - it is a soft halo of one colour - so one picture reflects
    /// correctly, and asking for `BrickPortalWedge90Glow` would find nothing and fall back to
    /// no glow at all.
    func endlessIIPortalGlowTexture(for brick: SKSpriteNode) -> SKTexture? {
        let suffix = GameScene.artSuffix(for: endlessIISizeOf(brick))
        var shape = brick.endlessIIFace.flatMap(GameScene.shapedArt(for:))
        if shape == nil, brick.childNode(withName: GameScene.roundedBrickOutlineName) != nil {
            shape = .rounded
        }
        // **Rounded is not a face**, and the first version of this missed it. A dome, a notch,
        // a wedge and a diamond are `EndlessIIFace` values applied by `makeFace`; Rounded is a
        // *style*, applied by `makeRounded`, and leaves `endlessIIFace` nil. So a rounded
        // Portal asked for `BrickPortalGlow` and got the plain oblong halo behind a capsule -
        // which is exactly how it looked in the render. `endlessIIWearsPortalArt` two functions
        // down has always had to ask both questions for the same reason.
        let stem = GameScene.portalBrickArtName + (shape?.rawValue ?? "")

        for name in [stem + suffix + "Glow", stem + "Glow"] where UIImage(named: name) != nil {
            return SKTexture(imageNamed: name)
        }
        return nil
        // The sized picture first and the plain one after, the way every other lookup here
        // works: `BrickPortalRoundedSquareGlow` exists and `BrickPortalRoundedBigGlow` does
        // not, so a Big Rounded Portal wears the ordinary Rounded glow rather than none
    }

    /// Puts that glow behind the brick, or takes it away where there is no picture for it.
    ///
    /// **Sized to the cell and centred on the drawing, not on the node.** A brick wearing a
    /// face has had its sprite shrunk to hide behind that face (§8.6), so `brick.size` is the
    /// hiding rectangle rather than the cell - the same trap the resumed body and the
    /// multi-hit bar both fell into. `endlessIIFieldSize` and `endlessIIBrickCentre` are the
    /// two that know better, and the glyph above already uses them.
    ///
    /// **Reflected exactly as the face is**, `xScale = -1` mirrored and `yScale = -1` flipped,
    /// which is what `makeFace` does to the shape node one file along. A halo is symmetrical
    /// enough that this rarely shows, and doing it anyway means a wedge's glow leans the way
    /// its wedge leans.
    ///
    /// **No physics body**, as asked - and it gets one for free by being an `SKSpriteNode`
    /// added as a child, which has none unless somebody gives it one. Worth saying out loud
    /// because a glow the ball could bounce off would be a Portal that is bigger than it
    /// looks.
    func refreshEndlessIIPortalGlow(on brick: SKSpriteNode) {
        let existing = brick.childNode(withName: GameScene.portalGlowName) as? SKSpriteNode
        guard brick.endlessIIRole == .portal, let texture = endlessIIPortalGlowTexture(for: brick)
        else { existing?.removeFromParent(); return }

        let glow = existing ?? {
            let made = SKSpriteNode()
            made.name = GameScene.portalGlowName
            made.zPosition = -0.1
            brick.addChild(made)
            return made
        }()
        // Behind the brick's own drawing, and only just: the brick sits at zPosition 1, so a
        // child at -0.1 lands at 0.9 - under its own brick and over the field behind it

        let cell = endlessIIFieldSize(of: brick)
        let scale = GameScene.portalGlowScale(for: endlessIISizeOf(brick))
        glow.texture = endlessIIShown(texture, on: brick)
        glow.size = CGSize(width: cell.width*scale.width, height: cell.height*scale.height)
        glow.position = endlessIIBrickCentre(of: brick)
        // **A halo reaches past the brick, so it cannot be sized to the cell**, and it reaches
        // past it *proportionally* rather than by a fixed amount. Sized to the cell the whole
        // halo hid behind the brick; sized to the cell plus twenty points it was right on one
        // device and wrong on every other. See `portalGlowScale`
        glow.xScale = (brick.endlessIIFaceMirrored ?? false) ? -1 : 1
        glow.yScale = (brick.endlessIIFaceFlipped ?? false) ? -1 : 1
        // Through `endlessIIShown`, so the glow drains with the brick while the Portal is
        // cooling rather than staying lit under a grey brick (round 274)
    }

    /// **How much bigger a Portal's glow is than its brick, as a ratio** - not as a margin.
    ///
    /// James, round 316: "the portal brick glows are 20 points larger on purpose. At the same
    /// scale, they will show whilst placed under the portal bricks. Do not scale them down."
    ///
    /// Round 315b read that as a fixed twenty points and added it to the cell, which is right
    /// on exactly one device: the one whose cell happens to be the size the art was drawn at.
    /// A brick is scaled to its cell, and "at the same scale" means the glow is scaled by the
    /// same factor - so on a phone with a smaller cell the halo shrinks *with* the brick
    /// rather than staying twenty points proud of it, and on a larger one it grows.
    ///
    /// **The ratio is not one number, which is why it is asked per size.** The oblong pair is
    /// 1.357 by 1.714, the square 1.357 both ways and the Big 1.179 by 1.357 - a halo of the
    /// same absolute thickness around bricks of three different shapes. Asked of the pair that
    /// matches the brick's own size, and the shape does not come into it: every normal-size
    /// Portal picture is drawn on the same canvas, so a wedge and a dome share the oblong's
    /// ratio.
    ///
    /// One-to-one where either picture is missing, which sizes the glow to the cell - no halo
    /// showing rather than a halo of some invented size.
    static func portalGlowScale(for size: BrickSize) -> CGSize {
        let base = portalBrickArtName + artSuffix(for: size)
        guard UIImage(named: base) != nil, UIImage(named: base + "Glow") != nil else {
            return CGSize(width: 1, height: 1)
        }
        let brick = SKTexture(imageNamed: base).size()
        let glow = SKTexture(imageNamed: base + "Glow").size()
        guard brick.width > 0, brick.height > 0 else { return CGSize(width: 1, height: 1) }
        return CGSize(width: glow.width/brick.width, height: glow.height/brick.height)
    }

    /// Greys a Portal out, or brings it back.
    ///
    /// James, round 274: "For the portal brick cooling, can we make the brick monochrome during
    /// this period." A picture with the colour drained out of it, which keeps every light and
    /// dark where it was - so it reads as the same brick waiting rather than as a different
    /// brick. `endlessIIShown` is where that happens, on the way to the sprite, so it reaches a
    /// shaped Portal's face without this having to know which node is doing the showing.
    ///
    /// The rings drawn on a Portal with no picture still change colour, because a shape node
    /// has no picture to drain.
    func endlessIIShowPortal(_ brick: SKSpriteNode, cooling: Bool) {
        if let glyph = endlessIIPortalMark(on: brick) as? SKShapeNode {
            glyph.removeAllActions()
            glyph.strokeColor = cooling ? GameScene.portalCoolingColour
                                        : GameScene.portalReadyColour
            return
        }
        refreshEndlessIIBrickArt(brick)
        endlessIIRefreshFace(on: brick)
        refreshEndlessIIPortalGlow(on: brick)
        // **Nothing is written on the brick.** `endlessIIShown` reads the cooldown and hands
        // back the desaturated picture for as long as it is running, so the state is a
        // consequence of the clock rather than a flag somebody has to remember to clear - and
        // the per-frame refresh, which used to wipe a tint off, is now what keeps it on.
        // Refreshed here as well so it lands on the frame it is set rather than the next: a
        // Portal cools for a few seconds, and a state that reads late at both ends of a short
        // window barely reads at all
    }

    /// What a Portal's rings are when it can be entered.
    static let portalReadyColour = UIColor(red: 0.30, green: 0.68, blue: 1.0, alpha: 1)

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
        if ball === self.ball { crookedBallNote("portal-exit") }
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

        endlessIIGravitySettleAccumulator += delta
        if endlessIIGravitySettleAccumulator >= 0.25 {
            endlessIIGravitySettleAccumulator = 0
            settleEndlessIIGravityBricks()
        }
        // A standing settle, four times a second, on top of the settle a destruction
        // triggers. Destruction was the only trigger, and it is not the only way support
        // goes: a Moving brick slides out from underneath, the field steps down, a
        // neighbour finishes its own fall - which is how gravity bricks "sometimes
        // don't fall right away" (play-test round 11). The pass is cheap and idempotent:
        // a brick with support stays exactly where it is

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
            if let wrapped = endlessIIWrapWandererX(
                at: x, limits: limits,
                halfWidth: self.endlessIIFieldSize(of: wanderer.brick).width/2,
                offset: self.endlessIIBrickCentre(of: wanderer.brick).x) {
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
                if fall.crushes {
                    endlessIIBrickDestroyed(fall.brick)
                    endlessIIDestroy(fall.brick)
                    // The ordinary destroy path, so it scores, rolls a power-up and counts
                    // itself exactly as the descent's own crush does
                }
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
    /// Whether it is falling onto a Fixed brick, and so is destroyed the moment it arrives.
    var crushes: Bool = false
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
