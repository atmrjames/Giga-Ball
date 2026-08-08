//
//  EndlessIIBricks.swift
//  Megaball
//
//  The brick behaviours Endless 2.0 adds, applied on top of an ordinary brick rather than
//  replacing it.
//
//  The game identifies a brick's *type* by its texture - normal, multi-hit, indestructible,
//  invisible - and everything from scoring to destruction reads that. These three are not
//  types in that sense: a spinning brick is still a normal brick worth a normal score. So
//  they are applied as behaviour to a brick that already has its type, which means none of
//  the existing scoring, collision or destruction code needs to know they exist.
//
//  That is also what keeps them out of the other modes. Nothing calls this except the
//  Endless 2.0 generation path.
//
//  Note on why none of this uses SKActions. `countBricks()` decides whether a row move is
//  underway by asking every brick `hasActions()`, and a row is only generated once no brick
//  is moving. A brick running a repeating spin or flash would answer yes for ever, so the
//  field would descend once and then stop. These are driven from the scene's update instead,
//  which also means they stop when the game is paused without anything having to pause them.
//

import SpriteKit

/// A brick that comes and goes, and is only solid while it is there.
struct EndlessIIFlasher {
    let brick: SKSpriteNode
    let solidFor: TimeInterval
    let passableFor: TimeInterval
    /// Seconds into the cycle: solid, fade out, passable, fade back in.
    var phase: TimeInterval
    /// Seconds to leave the brick alone for. A new row fades itself in, and writing alpha
    /// every frame from the moment it appears would fight that - one brick popping into a
    /// row that is still arriving.
    var warmUp: TimeInterval = 0.6

    static let fade: TimeInterval = 0.2
    /// Not fully transparent. A brick you cannot see at all is one you cannot plan around.
    ///
    /// High enough that the green still shows. Lower than this and the brick goes muddy
    /// brown against the purple field, which reads as a different kind of brick rather than
    /// as this one ghosted.
    static let passableAlpha: CGFloat = 0.35
    /// Where the fade back in stops, short of solid.
    ///
    /// It has to stop short. Becoming solid is the one step that can be held - the brick
    /// waits rather than materialising around the ball - and if the fade had already
    /// finished, a held brick would sit there looking solid while the ball sailed through
    /// it. Ending here means full opacity and solidity always arrive together.
    static let returningAlpha: CGFloat = 0.75

    var cycle: TimeInterval { solidFor + EndlessIIFlasher.fade + passableFor + EndlessIIFlasher.fade }

    /// How the brick should look and behave part-way through its cycle.
    ///
    /// Solid only while it is fully opaque. It stops being solid the instant it starts
    /// fading, and does not become solid again until it has finished fading back - so at
    /// every moment in between, what the player sees is what the ball will do.
    func state(at phase: TimeInterval) -> (solid: Bool, alpha: CGFloat) {
        let fade = EndlessIIFlasher.fade
        let faded = EndlessIIFlasher.passableAlpha
        let fadingOutAt = solidFor
        let passableAt = fadingOutAt + fade
        let fadingInAt = passableAt + passableFor

        let returning = EndlessIIFlasher.returningAlpha

        switch phase {
        case ...fadingOutAt:
            return (true, 1)
        case ..<passableAt:
            return (false, 1 + (faded - 1)*CGFloat((phase - fadingOutAt)/fade))
        case ..<fadingInAt:
            return (false, faded)
        default:
            let progress = min(1, (phase - fadingInAt)/fade)
            return (false, faded + (returning - faded)*CGFloat(progress))
        }
    }
}

/// A brick that turns on the spot.
struct EndlessIISpinner {
    let brick: SKSpriteNode
    /// Radians per second, signed for direction.
    let rate: CGFloat
}

extension GameScene {

    /// How often an ordinary brick gains one of these behaviours instead of staying plain.
    ///
    /// Deliberately low. These are meant to punctuate a field rather than fill it, and the
    /// right number is a play-testing question.
    static let endlessIIBehaviourChance = 12

    /// Clamped so a frame the app spent in the background does not advance every flashing
    /// brick through several cycles at once.
    private static let maximumTickInterval: TimeInterval = 1.0/20.0

    // MARK: - The best so far

    /// The best this mode has seen, from the mode's own runs.
    ///
    /// Each endless mode keeps its own list. Reading the other one's would show an Endless 2.0
    /// player a best they set in a different game.
    var endlessBestHeight: Int? {
        guard let stats = totalStatsArray.first else { return nil }
        return gameMode == .endlessII
            ? stats.endlessIIHeights.max()
            : stats.endlessModeHeight.max()
    }

    /// Puts the player's best height under the current one, or takes it away if there is none.
    ///
    /// Every place that used to hide this label in endless mode calls this instead. Showing it
    /// once at level load was not enough: the states show and hide the whole HUD row as play
    /// starts and as the pause menu closes, and each of those hid it again a third of a second
    /// after it appeared.
    ///
    /// It reuses the multiplier label, which endless mode hides because it has no multiplier -
    /// so this costs no new node and inherits a position that is already right. Smaller and
    /// dimmer than the live figure, because it is the thing you glance at rather than the
    /// thing you are watching.
    func showEndlessIIBest() {
        guard endlessMode else { return }
        // Both endless modes. A best height is the thing a run is measured against, and the
        // original mode wanted it for exactly the same reason - it was only ever here because
        // this is where it was written
        guard isDailyChallenge == false else {
            multiplierLabel.isHidden = true
            return
        }
        // A daily is measured against today's board, not the campaign's best - the figure
        // is a different game's (play-test note), and §9 keeps the two apart both ways
        guard let best = endlessBestHeight, best > 0 else {
            multiplierLabel.isHidden = true
            return
        }
        // No best yet - a first run has nothing to be measured against, and the label goes
        // back to being the one endless mode does not use

        multiplierLabel.isHidden = false
        multiplierLabel.text = "BEST \(best)m"
        multiplierLabel.fontSize = fontSize*0.7
        multiplierLabel.horizontalAlignmentMode = .right
        multiplierLabel.fontColor = UIColor(white: 1, alpha: 0.45)
        multiplierLabel.position.x = scoreLabel.position.x
        multiplierLabel.position.y = scoreLabel.position.y - fontSize*1.2
    }

    /// Clears it once the run passes it. Beating your best should feel like it happened.
    func refreshEndlessIIBest() {
        guard endlessMode, multiplierLabel.isHidden == false else { return }
        guard let best = endlessBestHeight, endlessHeight > best else { return }

        multiplierLabel.text = "NEW BEST"
        multiplierLabel.fontColor = brickGreenGigaball
        // Left showing rather than removed - the run is now writing the number that will be
        // sitting there next time
    }

    // MARK: - Power-up schedule

    /// Damps the power-ups a run has not been introduced to yet.
    ///
    /// Applied on top of whatever the allocation tables decided rather than replacing them,
    /// so every authored weight and every level-specific tweak still holds - this only says
    /// how much of that weight is available at this depth.
    ///
    /// Never to zero. A weight of one is the difference between a power-up somebody might
    /// meet in their first run and one they certainly will not.
    func applyEndlessIIPowerUpSchedule() {
        guard gameMode == .endlessII else { return }
        let progression = endlessIIProgression

        for index in powerUpProbArray.indices where powerUpProbArray[index] > 0 {
            let scale = progression.powerUpWeightScale(for: index, at: endlessHeight)
            guard scale < 1 else { continue }
            powerUpProbArray[index] = max(1, Int((Double(powerUpProbArray[index])*scale).rounded()))
        }
        powerUpProbSum = powerUpProbArray.reduce(0, +)
        // Recomputed here because the draw divides by this, and a sum left over from before
        // the damping would make every weight mean something slightly different
    }

    // MARK: - Generating

    /// Picks what a single cell of a new Endless 2.0 row holds.
    ///
    /// Two questions, in order: is there a brick here at all, and if so what kind. Density
    /// and composition are separate because they change at different rates - the field stops
    /// getting fuller around 500m, and carries on getting stranger for another 500 after
    /// that.
    func endlessIIBrickTexture() -> SKTexture {
        let progression = endlessIIProgression
        guard Double.random(in: 0..<1) < progression.density(at: endlessHeight,
                                                             phase: endlessIIPhase) else {
            return brickNullTexture
        }

        switch endlessIIPhaseBehaviour ?? progression.pickBehaviour(at: endlessHeight) {
        case .multiHit: return brickMultiHit3Texture
        case .indestructibleOnce: return brickIndestructible1Texture
        case .indestructibleAlways: return brickIndestructible2Texture
        case .invisible: return brickInvisibleTexture
        case .standard: return brickNormalTexture
        }
    }

    /// How often a designed pattern starts, when nothing else has the generator busy.
    static let endlessIISetRowChance = 7

    /// How often a cluster starts, when nothing else has the generator busy.
    ///
    /// Higher than a set row's chance, because a cluster is a smaller event: a set row decides
    /// what the whole next row is, where a cluster is a thing sitting in a row that is
    /// otherwise whatever it was going to be.
    static let endlessIIClusterChance = 11

    /// Takes the next row of a designed pattern, starting one if it is time.
    ///
    /// Returns nil for an ordinary generated row, which is most of them.
    ///
    /// Clusters and set rows share this queue and everything downstream of it. A cluster is
    /// written as a small shape and expanded here into full-width rows whose every other
    /// column is `?` - "whatever the generator would have put there" - so the field carries on
    /// either side of it. That one character is the whole difference between the two, and it
    /// is why a cluster needs no new pipeline: the reservation guard, the height gating and
    /// the row-to-texture mapping all already do the right thing.
    func endlessIINextSetRow(reservationPending: Bool) -> String? {
        guard gameMode == .endlessII else { return nil }

        if endlessIISetRowQueue.isEmpty {
            guard reservationPending == false else { return nil }
            // A Big brick or a spinner is already shaping this row and the next. Two things
            // arranging the same cells would leave neither shape intact

            if Int.random(in: 1...100) <= GameScene.endlessIIClusterChance,
               let queued = endlessIIStartCluster() {
                endlessIISetRowQueue = queued
            } else {
                guard Int.random(in: 1...100) <= GameScene.endlessIISetRowChance else {
                    return nil
                }
                let choices = EndlessIISetRow.available(at: endlessHeight)
                guard let pattern = choices.randomElement() else { return nil }
                endlessIISetRowQueue = pattern.rows
            }
        }
        return endlessIISetRowQueue.removeFirst()
    }

    /// Picks a cluster and a column for it, and writes it out as rows.
    func endlessIIStartCluster() -> [String]? {
        guard let picked = EndlessIICluster.pick(at: endlessHeight,
                                                 roll: { Int.random(in: 0..<$0) }) else {
            return nil
        }
        let cluster = picked.materialised(fieldWidth: numberOfBrickColumns,
                                          pick: { Int.random(in: 0..<$0) })
        // A scatter rolls its arrangement here, at placement - the same one is a different
        // field every time it lands. A drawn cluster passes through unchanged
        let places = EndlessIICluster.placements(width: cluster.width,
                                                 in: numberOfBrickColumns)
        guard let column = places.randomElement() else { return nil }
        return cluster.expanded(atColumn: column, fieldWidth: numberOfBrickColumns)
    }

    /// What a designed row puts in one of its columns.
    func endlessIISetRowTexture(_ row: String, column: Int) -> SKTexture {
        switch EndlessIISetRow.character(in: row, column: column) {
        case "N": return brickNormalTexture
        case "M": return brickMultiHit3Texture
        case "i": return brickIndestructible1Texture
        case "I": return brickIndestructible2Texture
        case "?": return endlessIIBrickTexture()
        default: return brickNullTexture
        }
    }

    /// Moves the run on to the next phase when the current one has run its length.
    ///
    /// A uniform phase settles what it is made of once, here, rather than per brick - that
    /// is the whole point of it. Everything else clears those choices so the ordinary mix
    /// resumes.
    func advanceEndlessIIPhase() {
        guard gameMode == .endlessII else { return }
        guard endlessHeight >= endlessIIPhaseEndsAt else { return }

        let phase = endlessIIProgression.pickPhase(at: endlessHeight)
        endlessIIPhase = phase
        endlessIIPhaseEndsAt = endlessHeight
            + Int.random(in: EndlessIIPhase.shortest...EndlessIIPhase.longest)

        endlessIIPhaseBehaviour = nil
        endlessIIPhaseStyles = []
        guard phase.isUniform else { return }

        switch phase {
        case .monoculture:
            endlessIIPhaseBehaviour = endlessIIProgression.pickBehaviour(at: endlessHeight)
        case .motif:
            // A pair that can actually share a brick, drawn from what this depth offers
            let first = endlessIIProgression.pickStyle(from: EndlessIIStyle.allCases,
                                                       at: endlessHeight)
            let partners = EndlessIIStyle.allCases.filter { first?.stacksWith($0) == true }
            let second = endlessIIProgression.pickStyle(from: partners, at: endlessHeight)
            endlessIIPhaseStyles = [first, second].compactMap { $0 }
        default:
            break
        }
    }


    // MARK: - Applying

    /// What a brick is, as the rest of the game understands it.
    ///
    /// Read from the texture rather than stored, because the texture is where every other
    /// part of the game keeps this and two copies of the same fact would eventually differ.
    func endlessIIBehaviour(of brick: SKSpriteNode) -> EndlessIIBehaviour? {
        switch brick.texture {
        case brickNormalTexture: return .standard
        case brickMultiHit1Texture, brickMultiHit2Texture,
             brickMultiHit3Texture, brickMultiHit4Texture: return .multiHit
        case brickIndestructible1Texture: return .indestructibleOnce
        case brickIndestructible2Texture: return .indestructibleAlways
        case brickInvisibleTexture: return .invisible
        default: return nil
        }
    }

    /// At most two. Three is not ruled out by the compatibility grid, but a brick doing
    /// three things is one nobody can read at a glance, and legibility is what makes the
    /// combinations fun rather than noisy.
    static let endlessIIMaximumStyles = 2

    /// Whether a brick sits in exactly one cell - true of an ordinary brick and of a Tiny
    /// one, false of a Big one.
    func occupiesOneCell(_ brick: SKSpriteNode) -> Bool {
        let size = endlessIIGeometry.footprint(of: brick.size)
        return size.columns == 1 && size.rows == 1
    }

    /// Which styles a brick is already wearing.
    ///
    /// Worked out from the brick and the lists that drive it rather than kept as a separate
    /// record, so there is no second copy of the truth to fall out of step with the first.
    func endlessIIStyles(on brick: SKSpriteNode) -> [EndlessIIStyle] {
        var found: [EndlessIIStyle] = []
        if brick.childNode(withName: GameScene.roundedBrickOutlineName) != nil {
            found.append(.rounded)
        }
        if endlessIISpinners.contains(where: { $0.brick === brick }) { found.append(.spinning) }
        if endlessIIFlashers.contains(where: { $0.brick === brick }) { found.append(.flashing) }
        switch brick.endlessIIRole {
        case .gravity: found.append(.gravity)
        case .moving: found.append(.moving)
        case .directional: found.append(.directional)
        case .exploding: found.append(.exploding)
        case .spawner: found.append(.spawner)
        case .portal: found.append(.portal)
        case .fixed: found.append(.fixed)
        case nil: break
        }
        return found
    }

    /// Whether a brick can take a style on top of what it already is.
    ///
    /// Three separate questions. Whether the style suits the behaviour is a design rule and
    /// lives in `EndlessIIStyle.suits`. Whether it stacks with what the brick already wears
    /// is another, in `stacksWith`. Whether this particular sprite can carry it is a
    /// mechanical one: Rounded and Spinning both assume a sprite centred on its node, which
    /// a Big brick's is not.
    func endlessIICanTake(_ style: EndlessIIStyle, _ brick: SKSpriteNode) -> Bool {
        guard brick.endlessIIStaysPlain == false else { return false }
        guard let behaviour = endlessIIBehaviour(of: brick) else { return false }

        let worn = endlessIIStyles(on: brick)
        guard worn.count < GameScene.endlessIIMaximumStyles else { return false }
        guard worn.allSatisfy({ $0.stacksWith(style) }) else { return false }

        if style == .portal, endlessIIHasPortal() { return false }
        if style == .portal {
            // Portal does not need to find an Indestructible brick, it makes one: it takes
            // the behaviour over, because "a hit does nothing" is part of what a Portal is.
            // Everything else has to fit the behaviour already there.
            return behaviour != .invisible
        }
        guard style.suits(behaviour) else { return false }

        let centred = abs(brick.anchorPoint.x - 0.5) < 0.01
            && abs(brick.anchorPoint.y - 0.5) < 0.01
        switch style {
        case .rounded: return centred
        case .spinning: return centred && isOrdinaryCellSized(brick)
        case .fixed:
            // Ordinary size only, for the same reason as Gravity: only some quarters of a
            // Tiny set would ever draw it, and a Big one would wall off two columns at once
            return isOrdinaryCellSized(brick)
        case .gravity:
            // Ordinary size only. A quarter-cell brick falling on its own looks like a piece
            // of a set coming loose - and it would be, since the four quarters are separate
            // bricks and only some of them would ever draw the style
            guard isOrdinaryCellSized(brick) else { return false }

            // And never in a column a spinner is in. A falling brick stops on whatever is
            // below it, and a spinner's cell reads as empty to that check because the spinner
            // is not *in* the cells it sweeps - so the faller would come to rest inside a
            // turning brick. The spinner's clearance is kept clear of arrivals from the side
            // already; this is the same rule for arrivals from above
            let column = endlessIICell(of: brick).column
            return endlessIISpinners.contains {
                $0.brick.parent != nil && endlessIICell(of: $0.brick).column == column
            } == false
        case .moving:
            // Both work out where they may go by looking at a neighbouring cell, and both
            // measure from the node's position. On a Big brick neither holds: the cell to
            // its right is part of itself, and its node sits on its top-left corner rather
            // than its middle. So a Big Moving brick saw nothing in its way and slid over
            // its neighbours, hiding them until it moved on again. Restricted to bricks that
            // occupy exactly one cell until both are taught about footprints
            return occupiesOneCell(brick)
        default: return true
        }
    }

    /// Gives each new brick one of the appearance styles, sometimes.
    ///
    /// Any behaviour can take any of these now, so a Multi-hit brick can flash and an
    /// Indestructible one can turn. Spinning is applied by the generator instead, because
    /// it is the one style that needs cells reserved around it.
    ///
    /// Called after the row's arrival animation has been set up, because that animation
    /// resets the colour blend on every normal brick and would undo the tinting here.
    func applyEndlessIIBehaviours(to bricks: [SKNode]) {
        applyEndlessIIStyles([.rounded, .flashing], to: bricks)
    }

    /// Offers each brick a style from a pool, at whatever rate the run's depth calls for.
    ///
    /// The depth ramp lives here rather than in each style, so the two pools - the ones that
    /// change how a brick looks and the ones that change what it does to the field - get the
    /// same treatment without agreeing on anything.
    func applyEndlessIIStyles(_ pool: [EndlessIIStyle], to bricks: [SKNode]) {
        guard gameMode == .endlessII else { return }

        let progression = endlessIIProgression
        let height = endlessHeight

        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }

            // A brick already carrying something has to clear the stacking roll as well.
            // Both are chances rather than gates, so a stack is possible from the first
            // metre and simply unlikely
            let alreadyStyled = endlessIIStyles(on: brick).isEmpty == false
            var chance = alreadyStyled
                ? progression.stackChance(at: height)
                : progression.styleChance(at: height)
            if endlessIIPhaseStyles.isEmpty == false { chance = 85 }
            // A motif phase is the motif. Running it at the ordinary rate would produce a
            // stretch of plain bricks with the occasional themed one, which is not a phase
            guard Int.random(in: 1...100) <= chance else { continue }

            let offered = endlessIIPhaseStyles.isEmpty
                ? pool
                : pool.filter { endlessIIPhaseStyles.contains($0) }
            // A motif phase only offers what the motif is, so a whole stretch wears the same
            // pair rather than each brick drawing its own
            guard offered.isEmpty == false else { continue }

            guard let wanted = progression.pickStyle(from: offered, at: height),
                  endlessIICanTake(wanted, brick) else { continue }
            applyEndlessIIStyle(wanted, to: brick)
        }
    }

    func applyEndlessIIStyle(_ style: EndlessIIStyle, to brick: SKSpriteNode) {
        switch style {
        case .rounded: makeRounded(brick)
        case .spinning: makeSpinning(brick)
        case .flashing: makeFlashing(brick)
        case .gravity: makeGravity(brick)
        case .moving: makeMoving(brick)
        case .directional: makeDirectional(brick)
        case .exploding: makeExploding(brick)
        case .spawner: makeSpawner(brick)
        case .portal: makePortal(brick)
        case .fixed: makeFixed(brick)
        }
    }

    /// Sets a brick turning, at the shape and size it already is.
    ///
    /// A static body follows its node's rotation, so the bounce genuinely changes with the
    /// angle - which is the whole point, and only interesting because the thing turning is
    /// oblong. It used to shrink to a square so its corners could not reach the rows above
    /// and below, and that read as a different, smaller kind of brick rather than as a
    /// familiar one behaving strangely. The room it needs comes from the generator leaving
    /// its four neighbouring cells empty instead - see `endlessIISpinnerClearance`.
    func makeSpinning(_ brick: SKSpriteNode) {
        let direction: CGFloat = Bool.random() ? 1 : -1
        let secondsPerTurn = CGFloat.random(in: 2.5...4.5)
        endlessIISpinners.append(EndlessIISpinner(brick: brick,
                                                  rate: direction*(.pi*2)/secondsPerTurn))
    }

    /// How far a turning brick reaches, in cells.
    ///
    /// A brick twice as wide as it is tall sweeps a circle of radius √5/2 ≈ 1.12 cell
    /// heights, so the cell above, the cell below and both side cells have to be empty.
    static let endlessIISpinnerClearance = 1

    /// Fades a brick out and back, solid only while it is visible.
    ///
    /// Each state is held for a couple of seconds with a quick transition between, so it
    /// reads as a brick that comes and goes rather than one that flickers ambiguously.
    /// Tinted with the Giga-Ball glow so it is recognisable while it is still solid.
    func makeFlashing(_ brick: SKSpriteNode) {
        brick.color = brickGreenGigaball
        brick.colorBlendFactor = 1.0

        endlessIIFlashers.append(EndlessIIFlasher(brick: brick,
                                                  solidFor: .random(in: 2.0...3.0),
                                                  passableFor: .random(in: 1.5...2.5),
                                                  phase: .random(in: 0...2)))
        // Staggered starts, or a whole row would breathe in unison
    }

    /// Rounds a brick's corners - the same oblong shape, not a circle.
    ///
    /// It was a circle, and a circle is a different brick: it reads as something new sitting
    /// where a brick should be, and it throws the ball off even on a square-on hit along
    /// what looks like a flat edge. Rounded corners keep every straight hit exactly as it
    /// has always been and change only the glancing ones near a corner, which is the
    /// interesting part.
    ///
    /// There is no artwork for it, so the face is drawn: a rounded-rectangle shape filled
    /// with the brick's own texture and colour, so a Multi-hit or Indestructible brick keeps
    /// its own look and only loses its corners. The sprite behind it is shrunk rather than
    /// hidden - hiding it would hide the face too, since that is its child - and shrunk by
    /// `size` rather than by scale, which children would inherit.
    func makeRounded(_ brick: SKSpriteNode) {
        let face = brick.size
        let radius = min(face.width, face.height)*GameScene.roundedBrickCornerFraction
        let path = CGPath(roundedRect: CGRect(x: -face.width/2, y: -face.height/2,
                                              width: face.width, height: face.height),
                          cornerWidth: radius, cornerHeight: radius, transform: nil)

        brick.physicsBody = brickBody(SKPhysicsBody(polygonFrom: path))
        // A rounded rectangle is convex, which is all a polygon body asks for

        let shape = SKShapeNode(path: path)
        shape.fillTexture = brick.texture
        shape.fillColor = brick.colorBlendFactor > 0.5 ? brick.color : .white
        shape.strokeColor = .clear
        shape.zPosition = 0.1
        shape.name = GameScene.roundedBrickOutlineName
        brick.addChild(shape)

        brick.size = CGSize(width: face.width*0.78, height: face.height*0.78)
        // Small enough to sit entirely inside the rounded face, so no square corner shows
    }

    /// How much of a brick's short side is taken up by each rounded corner.
    ///
    /// A half, so the two short ends are full semicircles and the brick is a stadium - round
    /// at the sides rather than merely softened at the corners.
    static let roundedBrickCornerFraction: CGFloat = 0.5

    /// Keeps a rounded brick's face showing what the brick is.
    ///
    /// A Multi-hit brick steps down through four textures as it is hit, and the face is a
    /// separate node that would otherwise still be showing the first one.
    func refreshEndlessIIRoundedFaces() {
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode,
                  let shape = brick.childNode(withName: GameScene.roundedBrickOutlineName)
                    as? SKShapeNode else { return }
            let wantedColour = brick.colorBlendFactor > 0.5 ? brick.color : UIColor.white
            if shape.fillTexture !== brick.texture || shape.fillColor != wantedColour {
                shape.fillTexture = brick.texture
                shape.fillColor = wantedColour
                // Colour as well as texture: a rounded brick that also picked up a role is
                // tinted after its face was built, and the face has to follow
            }
        }
    }

    /// The collision settings every brick body shares, so a replacement body behaves exactly
    /// like the one the generator built.
    func brickBody(_ body: SKPhysicsBody) -> SKPhysicsBody {
        body.allowsRotation = false
        body.friction = 0.0
        body.affectedByGravity = false
        body.isDynamic = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = CollisionTypes.brickCategory.rawValue
        body.collisionBitMask = CollisionTypes.laserCategory.rawValue
        body.contactTestBitMask = CollisionTypes.laserCategory.rawValue
        return body
    }

    // MARK: - Driving

    /// Advances the spinning and flashing bricks. Called once a frame.
    func tickEndlessIIBricks(_ currentTime: TimeInterval) {
        guard gameMode == .endlessII else { return }

        let elapsed = currentTime - endlessIILastTick
        endlessIILastTick = currentTime
        guard gameState.currentState is Playing else { return }
        let delta = min(max(elapsed, 0), GameScene.maximumTickInterval)
        guard delta > 0 else { return }

        endlessIISpinners.removeAll { $0.brick.parent == nil }
        for spinner in endlessIISpinners {
            spinner.brick.zRotation += spinner.rate*CGFloat(delta)
        }

        endlessIIFlashers.removeAll { $0.brick.parent == nil }
        for index in endlessIIFlashers.indices {
            advanceFlasher(at: index, by: delta)
        }

        tickEndlessIIRoles(delta)
        tickEndlessIIRescue(delta)
        refreshEndlessIIRoundedFaces()
    }

    /// Clears the tracked bricks. For starting a run, not for a brick being destroyed -
    /// those drop out of the lists on their own once they leave the scene.
    func resetEndlessIIBricks() {
        endlessIISpinners.removeAll()
        endlessIIFlashers.removeAll()
        endlessIIPendingBigColumn = nil
        endlessIIPendingSpinColumn = nil
        endlessIIPendingClearColumn = nil
        endlessIIProgression = EndlessIIProgression.make()
        clearEndlessIIMarkers()
        endlessIISetRowQueue = []
        endlessIIPhase = .standard
        endlessIIPhaseEndsAt = 0
        endlessIIPhaseBehaviour = nil
        endlessIIPhaseStyles = []
        endlessIILastTick = 0
        resetEndlessIIRoles()
        endlessIIClearExtraBalls()
        // A run starts on one ball, whatever the last one ended on
    }

    private func advanceFlasher(at index: Int, by delta: TimeInterval) {
        var flasher = endlessIIFlashers[index]

        if flasher.warmUp > 0 {
            flasher.warmUp -= delta
            endlessIIFlashers[index] = flasher
            return
        }

        var phase = flasher.phase + delta

        if phase >= flasher.cycle {
            // About to become solid again. Not while the ball is inside it: turning the body
            // on underneath the ball leaves the ball buried in a brick, and the physics
            // resolves that by flinging it somewhere arbitrary. Holding just short of the
            // end of the cycle keeps it passable until the ball has gone.
            if ballOverlaps(flasher.brick) {
                phase = flasher.cycle - 0.001
            } else {
                phase -= flasher.cycle
            }
        }
        flasher.phase = phase
        endlessIIFlashers[index] = flasher

        let state = flasher.state(at: phase)
        flasher.brick.alpha = state.alpha
        setBrickSolid(flasher.brick, state.solid)
    }

    /// Whether the ball is close enough to the brick that making it solid would trap it.
    private func ballOverlaps(_ brick: SKSpriteNode) -> Bool {
        brick.frame.insetBy(dx: -ballSize/2, dy: -ballSize/2).contains(ball.position)
    }

    /// Turns a brick's collisions on and off without disturbing anything else about it.
    ///
    /// The name is left alone deliberately - the row descent and the brick count both find
    /// bricks by name, and a brick that is briefly passable is still part of the field.
    func setBrickSolid(_ brick: SKSpriteNode, _ solid: Bool) {
        guard let body = brick.physicsBody else { return }
        let wanted = solid ? CollisionTypes.brickCategory.rawValue : 0
        guard body.categoryBitMask != wanted else { return }
        body.categoryBitMask = wanted
        body.collisionBitMask = solid ? CollisionTypes.laserCategory.rawValue : 0
        body.contactTestBitMask = solid ? CollisionTypes.laserCategory.rawValue : 0
    }

    static let roundedBrickOutlineName = "endlessIIRoundedOutline"
}

extension GameScene {

    /// Puts something in a row that would otherwise be the third empty one in a row.
    ///
    /// Height in this mode is gained by clearing the bottom row, and a row with nothing in it
    /// is cleared the moment it arrives. So a run of empty rows is height for free - which
    /// sounds generous and is the opposite of it. The field rushes past, the player is deep
    /// before the mode has shown them anything, and the density that was meant to arrive
    /// gradually arrives all at once, because it is keyed to a height they reached in seconds.
    ///
    /// This is a floor rather than a change to the density curve. The opening is meant to be
    /// sparse and stays sparse; what it cannot be is *absent*, and one brick is the difference
    /// between a row that has to be played and a row that is not there.
    func endlessIIFillEmptyRowIfOverdue(_ row: [SKNode], reserved: Set<Int> = [],
                                        shapeComing: Bool = false) {
        guard gameMode == .endlessII else { return }

        guard shapeComing == false else {
            endlessIIEmptyRowRun = 0
            return
        }
        // A Big or power-up brick is about to be built into this row. It is added after this
        // runs, so the row looks empty from here and is not - filling it would put an ordinary
        // brick inside the shape's own footprint, which is what was found underneath a Big
        // brick after it broke

        let bricks = row.compactMap { $0 as? SKSpriteNode }
            .filter { $0.texture != brickNullTexture }

        guard bricks.isEmpty else {
            endlessIIEmptyRowRun = 0
            return
        }

        endlessIIEmptyRowRun += 1
        guard endlessIIEmptyRowRun > EndlessIIProgression.mostEmptyRowsInARow else { return }

        // One brick, somewhere in the middle two thirds. Against a wall it is easy to leave
        // alone, and leaving it alone is the thing this exists to stop
        let columns = max(1, numberOfBrickColumns)
        let margin = columns/6
        let candidates = row.compactMap { $0 as? SKSpriteNode }.filter { brick in
            let column = endlessIICell(of: brick).column
            guard reserved.contains(column) == false else { return false }
            // A cell kept clear is kept clear. These are the gap a shape from the next row
            // comes down into, or a spinner's clearance - a brick here is either buried
            // inside something else or in the way of something that turns
            return column >= margin && column < columns - margin
        }

        guard let chosen = candidates.randomElement()
                ?? row.compactMap({ $0 as? SKSpriteNode })
                      .first(where: { reserved.contains(endlessIICell(of: $0).column) == false })
        else { return }
        chosen.texture = endlessIIBrickTexture()
        if chosen.texture == brickNullTexture { chosen.texture = brickNormalTexture }
        // The mix this height would have produced, and an ordinary brick if that came up empty
        // as well - the point is that the row is not empty, not which brick it is

        chosen.color = brickWhite
        chosen.colorBlendFactor = 1.0
        endlessIIEmptyRowRun = 0
    }
}
