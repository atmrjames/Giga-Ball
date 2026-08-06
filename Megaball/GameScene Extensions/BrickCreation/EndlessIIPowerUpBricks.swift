//
//  EndlessIIPowerUpBricks.swift
//  Megaball
//
//  A power-up built into the field rather than falling out of it.
//
//  Every power-up in the game so far is a thing that drops and has to be caught, which makes
//  collecting one a question about the paddle. This is the same power-up asked as a question
//  about the ball: it is a brick, it is sitting up there in the field, and breaking it is what
//  sets it off.
//
//  The point is what that does to a *bad* one. A falling Lose A Ball is avoided by moving the
//  paddle out of the way, which costs nothing and is not really a decision. A Lose A Ball built
//  into the field is a brick you have to not hit - it is in the way, it is in the middle of the
//  shot you wanted, and leaving it there means playing around it for as long as it takes to
//  descend past you. So it is never destroyed by reaching the bottom: it carries on down and
//  out, and a player who spent twenty metres avoiding it is not punished at the last moment by
//  the field clearing it for them.
//
//  Two cells tall and one wide, which on a grid whose cells are twice as wide as they are tall
//  makes it square - the shape a power-up already has when it falls. That is the whole reason
//  for the shape: it should read as a power-up sitting in the field rather than as a brick with
//  a picture on it.
//

import SpriteKit

/// Where a power-up brick's sprite and body sit relative to its node.
///
/// The same trick a Big brick uses, and for the same reason: the node stays on the row centre
/// that the descent and the bottom-row check both read, and the extra size is expressed as an
/// anchor point and an offset body. It covers its own row and the one below, which was left
/// empty a row earlier.
struct EndlessIIPowerUpBrick {
    let cell: CGSize

    var size: CGSize { CGSize(width: cell.width, height: cell.height*2) }

    /// Puts the node on the upper cell's centre while the sprite covers both.
    var anchorPoint: CGPoint { CGPoint(x: 0.5, y: 0.75) }

    /// The body follows the sprite, not the node.
    var bodyCentre: CGPoint { CGPoint(x: 0, y: -cell.height/2) }

    func nodeX(column: Int, gameWidth: CGFloat) -> CGFloat {
        -gameWidth/2 + cell.width/2 + cell.width*CGFloat(column)
    }

    static func fits(column: Int, columns: Int) -> Bool {
        column >= 0 && column < columns
    }
}

extension GameScene {

    /// How often a row commits to the two-row sequence a power-up brick needs.
    ///
    /// Rare. It is a whole power-up sitting in the field, good or bad, and one every few
    /// screens is an event where one every screen is a mechanic.
    static let endlessIIPowerUpBrickChance = 5

    static let powerUpBrickName = "endlessIIPowerUpBrick"

    /// Which power-up a brick is holding.
    ///
    /// Stored on the node like every other Endless 2.0 fact about a brick, so it survives
    /// whatever happens to it and disappears when it does.
    var endlessIIPowerUpBricksInPlay: [SKSpriteNode] {
        var found: [SKSpriteNode] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if node.endlessIIPowerUpIndex != nil, let brick = node as? SKSpriteNode {
                found.append(brick)
            }
        }
        return found
    }

    /// Picks a power-up for a brick to hold.
    ///
    /// Drawn from the same weighted table the falling ones use, so a brick holds whatever the
    /// mode would have dropped at this height - including the bad ones, which are most of the
    /// reason for having these at all. Returns nil when the table has nothing to offer.
    func endlessIIPowerUpForBrick() -> Int? {
        let candidates = powerUpProbArray.indices.filter { powerUpProbArray[$0] > 0 }
        guard candidates.isEmpty == false else { return nil }

        let total = candidates.reduce(0) { $0 + powerUpProbArray[$1] }
        guard total > 0 else { return candidates.first }

        var drawn = Int.random(in: 0..<total)
        for index in candidates {
            drawn -= powerUpProbArray[index]
            if drawn < 0 { return index }
        }
        return candidates.last
    }

    /// Builds the power-up brick a row owes, ready to animate in with the rest of the row.
    func endlessIIMakePowerUpBrick(column: Int, rowY: CGFloat) -> SKSpriteNode? {
        guard endlessIIPowerUpBricksInPlay.isEmpty else { return nil }
        // One at a time. Two of these on screen is two shots you have to not take, which is
        // most of the field for as long as they take to descend - and a second one arriving
        // while the first is still in the way turns a decision into a siege
        guard let index = endlessIIPowerUpForBrick() else { return nil }
        guard totalStatsArray.first?.powerUpUnlockedArray.indices.contains(index) == true,
              totalStatsArray[0].powerUpUnlockedArray[index] else { return nil }
        // A power-up the player has not unlocked yet is one they would not recognise, and
        // setting one off would be showing them something the packs have not reached

        let plan = EndlessIIPowerUpBrick(cell: CGSize(width: brickWidth, height: brickHeight))

        let brick = SKSpriteNode(texture: brickIndestructible2Texture)
        brick.size = plan.size
        brick.anchorPoint = plan.anchorPoint
        brick.position = CGPoint(x: plan.nodeX(column: column, gameWidth: gameWidth), y: rowY)
        brick.zPosition = 1
        brick.name = BrickCategoryName
        brick.endlessIIPowerUpIndex = index
        brick.endlessIIStaysPlain = true
        // Never given a style. It is already saying one thing loudly, and a spinning, flashing
        // power-up brick would be saying three
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: plan.size,
                                                    center: plan.bodyCentre))
        addChild(brick)

        let icon = SKSpriteNode(texture: endlessIIPowerUpTexture(index))
        icon.size = CGSize(width: plan.size.width*0.78, height: plan.size.width*0.78)
        icon.position = CGPoint(x: 0, y: -plan.cell.height/2)
        icon.zPosition = 1
        icon.name = GameScene.powerUpBrickName
        brick.addChild(icon)
        // The power-up's own icon, so which one it is is read the same way it is read falling.
        // Square, because the brick is - that is what the shape is for

        return brick
    }

    /// Sets off the power-up a brick was holding, and takes the brick with it.
    ///
    /// Returns whether there was one, so the caller knows the hit is spent.
    @discardableResult
    func endlessIITriggerPowerUpBrick(_ brick: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, let index = brick.endlessIIPowerUpIndex else { return false }

        let carrier = SKSpriteNode(texture: endlessIIPowerUpTexture(index))
        carrier.position = brick.position
        carrier.alpha = 0
        addChild(carrier)
        powerUpsOnScreen += 1
        // In the scene, invisible, and counted. `applyPowerUp` runs the collection animation
        // on the node and decrements the on-screen count - both of which need a node that is
        // actually in the scene and a count that was incremented when it appeared. A carrier
        // held outside the scene ran no actions, so the completion that clears the mystery
        // power-up never fired

        applyPowerUp(node: carrier)
        // Handed to the same method a caught power-up goes through, so every effect, timer,
        // icon and conflict rule is the one that already exists

        totalStatsArray[0].powerupsGenerated[index] += 1
        // Collected is counted by `applyPowerUp` itself, in whichever case it lands on

        endlessIIShowPowerUpBrickBurst(at: brick.position, index: index)
        brick.removeFromParent()
        return true
    }

    /// The scene's own texture for a power-up.
    ///
    /// `applyPowerUp` decides what to do by comparing the sprite's texture against the ones the
    /// scene holds, and two textures built from the same image are not the same texture. Built
    /// from the image, the brick set off nothing at all: it broke, it was counted, and the
    /// power-up it was holding never happened.
    func endlessIIPowerUpTexture(_ index: Int) -> SKTexture {
        powerUpTextureArray.indices.contains(index)
            ? powerUpTextureArray[index]
            : SKTexture(image: LevelPackSetup().powerUpImageArray[index])
    }

    private func endlessIIShowPowerUpBrickBurst(at point: CGPoint, index: Int) {
        let icon = SKSpriteNode(texture: endlessIIPowerUpTexture(index))
        icon.size = CGSize(width: brickWidth*0.8, height: brickWidth*0.8)
        icon.position = point
        icon.zPosition = 4
        addChild(icon)
        icon.run(.sequence([.group([.scale(to: 1.8, duration: 0.28),
                                    .fadeOut(withDuration: 0.28)]),
                            .removeFromParent()]))
        // The icon growing out of where the brick was, so what was set off is legible in the
        // moment it happens rather than only in the HUD afterwards
    }
}

extension SKNode {

    private static let powerUpIndexKey = "endlessIIPowerUp"

    /// Which power-up this brick is holding, if it is a power-up brick.
    var endlessIIPowerUpIndex: Int? {
        get { userData?[SKNode.powerUpIndexKey] as? Int }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?[SKNode.powerUpIndexKey] = newValue
        }
    }
}
