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
    /// Lower than it looks, because one roll now makes four bricks rather than one. At the
    /// old figure a tenth of the field became Tiny and then quadrupled in visual weight.
    static let endlessIITinyChance = 4

    /// Which quarters of a cell a Tiny set fills.
    ///
    /// All four, or one of the two diagonal pairs. The diagonals are the interesting ones:
    /// they leave a route through the cell rather than a solid block, so a Tiny set is
    /// sometimes an obstacle and sometimes a gap with something in it - and the ball can be
    /// threaded between them.
    static func endlessIITinyLayout() -> [CGPoint] {
        let topLeft = CGPoint(x: -0.25, y: 0.25)
        let topRight = CGPoint(x: 0.25, y: 0.25)
        let bottomLeft = CGPoint(x: -0.25, y: -0.25)
        let bottomRight = CGPoint(x: 0.25, y: -0.25)

        switch Int.random(in: 0...3) {
        case 0: return [topLeft, bottomRight]
        case 1: return [topRight, bottomLeft]
        default: return [bottomLeft, bottomRight, topLeft, topRight]
        }
        // Weighted toward the full set, so a diagonal pair reads as a variation on something
        // familiar rather than as the normal case
    }

    /// How much of each quarter cell the brick actually fills.
    ///
    /// The gap between the four is what makes them read as four bricks rather than one brick
    /// with hairlines scratched across it. It has to come out of the brick rather than being
    /// added around it, or the set would no longer fill its cell.
    static let endlessIITinyFill: CGFloat = 0.82

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
    func endlessIIReserveOrBuildBig() -> (skip: Set<Int>, dueAt: Int?, spinAt: Int?) {
        guard gameMode == .endlessII else { return ([], nil, nil) }

        let due = endlessIIPendingBigColumn
        let spinDue = endlessIIPendingSpinColumn
        let clearDue = endlessIIPendingClearColumn
        endlessIIPendingBigColumn = nil
        endlessIIPendingSpinColumn = nil
        endlessIIPendingClearColumn = nil

        if let left = due {
            return ([left, left + 1], left, nil)
            // Its top half fills these cells here; its bottom half fills the gap below
        }

        if let column = spinDue {
            // The spinner goes here, with its side cells empty. The cell below was left
            // empty a row ago; the cell above is left empty by the next row.
            endlessIIPendingClearColumn = column
            return (Set([column - 1, column + 1].filter { $0 >= 0 && $0 < numberOfBrickColumns }),
                    nil, column)
        }

        if let column = clearDue {
            return ([column], nil, nil)
            // The cell above a spinner placed a row ago
        }

        if Int.random(in: 1...100) <= GameScene.endlessIISpinChance {
            let column = Int.random(in: 0..<max(1, numberOfBrickColumns))
            endlessIIPendingSpinColumn = column
            return ([column], nil, nil)
            // Left empty for the cell below the spinner the next row will place
        }

        let bigChance = endlessIIPhase == .giants ? 90 : GameScene.endlessIIBigChance
        guard Int.random(in: 1...100) <= bigChance else { return ([], nil, nil) }
        let left = Int.random(in: 0..<max(1, numberOfBrickColumns - 1))
        guard EndlessIIBigBrick.fits(leftColumn: left, columns: numberOfBrickColumns) else {
            return ([], nil, nil)
        }
        endlessIIPendingBigColumn = left
        return ([left, left + 1], nil, nil)
        // Left empty for the brick the next row will build down into
    }

    /// How often a row commits to the three-row sequence a spinning brick needs.
    static let endlessIISpinChance = 12

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
    func applyEndlessIISizes(to bricks: inout [SKNode]) {
        guard gameMode == .endlessII else { return }

        var made: [SKNode] = []
        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.texture == brickNormalTexture else { continue }
            guard brick.endlessIIStaysPlain == false else { continue }
            guard isOrdinaryCellSized(brick) else { continue }
            // Already resized - the Big brick this row built comes through here too
            let chance = endlessIIPhase == .miniatures ? 100 : GameScene.endlessIITinyChance
            guard Int.random(in: 1...100) <= chance else { continue }
            made.append(contentsOf: Array(makeTiny(brick).dropFirst()) as [SKNode])
        }
        bricks.append(contentsOf: made)
        // The three new quarters join the row, so the arrival animation and the brick count
        // see them like anything else generated this row
    }

    /// Whether a brick is still exactly one cell.
    ///
    /// Compared with a tolerance, not for equality. `SKSpriteNode.size` is backed by floats,
    /// so a width assigned straight from `brickWidth` does not read back as `brickWidth` -
    /// a plain `==` here is always false, which silently turns off everything it guards.
    func isOrdinaryCellSized(_ brick: SKSpriteNode) -> Bool {
        abs(brick.size.width - brickWidth) < 0.5 && abs(brick.size.height - brickHeight) < 0.5
    }

    /// Replaces a brick with the four quarter-cell bricks that fill its cell.
    ///
    /// Four, not one. A single quarter-cell brick floating in the middle of an otherwise
    /// empty cell reads as a mistake - a normal brick that failed to draw properly - because
    /// nothing else in the field sits anywhere but on the grid. Four of them fill the cell
    /// exactly, so the cell still looks like a cell, and what the player gets is a brick
    /// that takes four hits to clear and opens gaps as it goes rather than one that vanishes
    /// in a single hit and leaves a hole.
    ///
    /// The original node becomes the bottom-left quarter and the other three are new, so
    /// whatever the caller already did to it - its texture, its colour - carries into at
    /// least one of them.
    func makeTiny(_ brick: SKSpriteNode) -> [SKSpriteNode] {
        let quarter = CGSize(width: brickWidth/2*GameScene.endlessIITinyFill,
                             height: brickHeight/2*GameScene.endlessIITinyFill)
        let home = brick.position
        var quarters: [SKSpriteNode] = []

        for (index, offset) in GameScene.endlessIITinyLayout().enumerated() {
            let piece: SKSpriteNode
            if index == 0 {
                piece = brick
            } else {
                piece = SKSpriteNode(texture: brick.texture)
                piece.color = brick.color
                piece.colorBlendFactor = brick.colorBlendFactor
                piece.zPosition = brick.zPosition
                piece.name = BrickCategoryName
                addChild(piece)
            }
            piece.size = quarter
            piece.position = CGPoint(x: home.x + offset.x*brickWidth,
                                     y: home.y + offset.y*brickHeight)
            piece.physicsBody = brickBody(SKPhysicsBody(rectangleOf: quarter))
            quarters.append(piece)
        }
        return quarters
        // All four keep their row centre within half a cell of the original, so the descent
        // and the bottom-row check still read them as belonging to this row
    }
}
