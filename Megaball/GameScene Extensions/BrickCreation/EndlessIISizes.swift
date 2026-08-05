//
//  EndlessIISizes.swift
//  Megaball
//
//  Big and Tiny bricks. Size is a separate axis from type - a Big brick is still whatever
//  type it was - so like the behaviours in EndlessIIBricks, these are applied to a brick
//  that already exists rather than being types of their own.
//
//  The rule everything here bends around: a brick's `position.y` is how the rest of the
//  game knows which row it is in. The descent moves every brick down by one row, and the
//  bottom-row check that gates new-row generation asks whether a brick's position has
//  reached the last row. A brick that put its position anywhere other than its row centre
//  would be removed at the wrong moment, or would sit in the bottom row blocking generation
//  while looking like it was somewhere else.
//
//  So Tiny simply shrinks in place, and Big keeps its node on a row centre and expresses
//  the extra size as an anchor point and an offset physics body.
//

import SpriteKit

/// Where a Big brick's sprite and body sit relative to its node.
///
/// It covers two columns and two rows: the row it is generated in, and the row below -
/// which was deliberately left empty a row earlier, because new rows arrive at the top and
/// there is nothing above them to grow into.
struct EndlessIIBigBrick {
    /// One cell: the size of an ordinary brick.
    let cell: CGSize

    var size: CGSize { CGSize(width: cell.width*2, height: cell.height*2) }

    /// Puts the node on the top-left cell's centre while the sprite covers all four.
    var anchorPoint: CGPoint { CGPoint(x: 0.25, y: 0.75) }

    /// The body follows the sprite, not the node.
    var bodyCentre: CGPoint { CGPoint(x: cell.width/2, y: -cell.height/2) }

    /// The node sits on the left column's centre, the same x an ordinary brick there
    /// would have.
    func nodeX(leftColumn: Int, gameWidth: CGFloat) -> CGFloat {
        -gameWidth/2 + cell.width/2 + cell.width*CGFloat(leftColumn)
    }

    /// The rectangle the brick actually covers, for checking it lands on whole cells.
    func coverage(leftColumn: Int, rowY: CGFloat, gameWidth: CGFloat) -> CGRect {
        let x = nodeX(leftColumn: leftColumn, gameWidth: gameWidth)
        return CGRect(x: x - cell.width/2, y: rowY - cell.height*1.5,
                      width: cell.width*2, height: cell.height*2)
    }

    /// Whether a Big brick starting here fits the field.
    static func fits(leftColumn: Int, columns: Int) -> Bool {
        leftColumn >= 0 && leftColumn + 1 < columns
    }
}

extension GameScene {

    /// How often a row leaves room for a Big brick, and how often an ordinary brick shrinks.
    ///
    /// Both are opening guesses. Big costs two rows of setup, so it should be the rarer of
    /// the two even at the same number.
    static let endlessIIBigChance = 18
    static let endlessIITinyChance = 10

    // MARK: - Big

    /// Decides what this row owes a Big brick, and which columns it has to leave empty.
    ///
    /// Called at the top of row generation. A Big brick needs two rows, and rows arrive one
    /// at a time from the top with nothing above them, so it cannot be built in one go: a
    /// row leaves a two-cell gap, and the next row builds the brick down into it.
    ///
    /// Returns the columns this row must skip, and the left column of a Big brick that is
    /// now due - which is never the one just reserved, since a row either builds or
    /// reserves, not both.
    func endlessIIReserveOrBuildBig() -> (skip: Set<Int>, dueAt: Int?) {
        guard gameMode == .endlessII else { return ([], nil) }

        let due = endlessIIPendingBigColumn
        endlessIIPendingBigColumn = nil

        if let left = due {
            return ([left, left + 1], left)
            // Its top half fills these cells here; its bottom half fills the gap below
        }

        guard Int.random(in: 1...100) <= GameScene.endlessIIBigChance else { return ([], nil) }
        let left = Int.random(in: 0..<max(1, numberOfBrickColumns - 1))
        guard EndlessIIBigBrick.fits(leftColumn: left, columns: numberOfBrickColumns) else {
            return ([], nil)
        }
        endlessIIPendingBigColumn = left
        return ([left, left + 1], nil)
        // Left empty for the brick the next row will build down into
    }

    /// Builds the Big brick a row owes, ready to be animated in with the rest of the row.
    func endlessIIMakeBig(leftColumn: Int, rowY: CGFloat) -> SKSpriteNode {
        let plan = EndlessIIBigBrick(cell: CGSize(width: brickWidth, height: brickHeight))

        let brick = SKSpriteNode(texture: brickNormalTexture)
        brick.color = brickWhite
        brick.colorBlendFactor = 1.0
        brick.size = plan.size
        brick.anchorPoint = plan.anchorPoint
        brick.position = CGPoint(x: plan.nodeX(leftColumn: leftColumn, gameWidth: gameWidth),
                                 y: rowY)
        brick.zPosition = 1
        brick.name = BrickCategoryName
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: plan.size,
                                                    center: plan.bodyCentre))
        addChild(brick)
        return brick
    }

    // MARK: - Tiny

    /// Shrinks some ordinary bricks to a quarter of a cell.
    ///
    /// Centred, so the node stays on its row centre and the gaps open up evenly around it -
    /// a quarter-cell brick pushed into one corner would read as a misplaced normal brick
    /// rather than as a small one.
    func applyEndlessIISizes(to bricks: [SKNode]) {
        guard gameMode == .endlessII else { return }

        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture == brickNormalTexture else { continue }
            guard isOrdinaryCellSized(brick) else { continue }
            // Already resized - the Big brick this row built comes through here too
            guard Int.random(in: 1...100) <= GameScene.endlessIITinyChance else { continue }
            makeTiny(brick)
        }
    }

    /// Whether a brick is still exactly one cell.
    ///
    /// Compared with a tolerance, not for equality. `SKSpriteNode.size` is backed by floats,
    /// so a width assigned straight from `brickWidth` does not read back as `brickWidth` -
    /// a plain `==` here is always false, which silently turns off everything it guards.
    func isOrdinaryCellSized(_ brick: SKSpriteNode) -> Bool {
        abs(brick.size.width - brickWidth) < 0.5 && abs(brick.size.height - brickHeight) < 0.5
    }

    func makeTiny(_ brick: SKSpriteNode) {
        brick.size = CGSize(width: brickWidth/2, height: brickHeight/2)
        brick.physicsBody = brickBody(SKPhysicsBody(rectangleOf: brick.size))
    }
}
