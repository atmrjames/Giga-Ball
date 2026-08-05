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

    // MARK: - Applying

    /// Gives each new brick one of Endless 2.0's behaviours, sometimes.
    ///
    /// Only plain single-hit bricks are eligible. A spinning indestructible brick is a later
    /// phase's problem, and a flashing multi-hit brick would be unreadable.
    ///
    /// Called after the row's arrival animation has been set up, because that animation
    /// resets the colour blend on every normal brick and would undo the tinting here.
    func applyEndlessIIBehaviours(to bricks: [SKNode]) {
        guard gameMode == .endlessII else { return }

        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture == brickNormalTexture else { continue }
            guard Int.random(in: 1...100) <= GameScene.endlessIIBehaviourChance else { continue }

            // Spinning replaces the brick's size and Rounded replaces its body, and both
            // assume the sprite is centred on the node. A Big brick is neither, so it only
            // takes Flashing - which touches nothing but alpha and the collision mask.
            // Sizes and behaviours are meant to combine; making the other two follow an
            // offset sprite is worth doing once there is more than one thing that needs it.
            let centred = abs(brick.anchorPoint.x - 0.5) < 0.01
                && abs(brick.anchorPoint.y - 0.5) < 0.01
            switch Int.random(in: 0...2) {
            case 0 where centred && isOrdinaryCellSized(brick): makeSpinning(brick)
            case 2 where centred: makeRounded(brick)
            default: makeFlashing(brick)
            }
        }
    }

    /// Turns a brick into a small square that rotates.
    ///
    /// A static body still follows its node's rotation, so the bounce really does change
    /// with the angle - that is the whole point of the brick. The size is what keeps that
    /// safe: a full-width brick swings its corners deep into the rows above and below as it
    /// turns, and the ball can end up pinched in the gap that leaves. Shrunk to a square
    /// narrower than the row is tall, everything it sweeps stays inside its own row.
    func makeSpinning(_ brick: SKSpriteNode) {
        let side = brickHeight*0.7
        brick.size = CGSize(width: side, height: side)
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: brick.size))

        let direction: CGFloat = Bool.random() ? 1 : -1
        let secondsPerTurn = CGFloat.random(in: 2.5...4.5)
        endlessIISpinners.append(EndlessIISpinner(brick: brick,
                                                  rate: direction*(.pi*2)/secondsPerTurn))
    }

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

    /// Gives a brick a circular body, so glancing hits deflect at angles a rectangle never
    /// produces.
    ///
    /// There is no artwork for a round brick, so the circle is drawn over the sprite. It has
    /// to be visible: a brick that looks square and bounces round is a bug as far as the
    /// player is concerned.
    func makeRounded(_ brick: SKSpriteNode) {
        let radius = min(brick.size.width, brick.size.height)/2
        brick.physicsBody = brickBody(SKPhysicsBody(circleOfRadius: radius))

        let outline = SKShapeNode(circleOfRadius: radius)
        // Dark, not light. Bricks are pale against a dark field, and a white circle on a
        // white brick is no circle at all.
        outline.strokeColor = UIColor(white: 0, alpha: 0.55)
        outline.lineWidth = 2.5
        outline.fillColor = .clear
        outline.zPosition = 1
        outline.name = GameScene.roundedBrickOutlineName
        brick.addChild(outline)
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
    }

    /// Clears the tracked bricks. For starting a run, not for a brick being destroyed -
    /// those drop out of the lists on their own once they leave the scene.
    func resetEndlessIIBricks() {
        endlessIISpinners.removeAll()
        endlessIIFlashers.removeAll()
        endlessIIPendingBigColumn = nil
        endlessIILastTick = 0
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
