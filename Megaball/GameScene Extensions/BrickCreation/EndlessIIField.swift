//
//  EndlessIIField.swift
//  Megaball
//
//  Which brick is in which cell.
//
//  Nothing in the game could answer that before. Brick positions are computed inline from a
//  column index and never read back, and the only question anyone asks of a brick is where
//  it is in points. Four of the phase 5 bricks - Gravity, Moving, Exploding and Spawner -
//  are defined entirely in terms of their neighbours, so they need the question answered.
//
//  Rather than keep a grid alongside the scene and risk the two disagreeing, this reads the
//  scene: the bricks are the truth, and a cell map is derived from them when something needs
//  one. Cheap enough at a couple of hundred bricks, and it cannot go stale.
//

import SpriteKit

struct EndlessIICell: Hashable {
    let column: Int
    /// Counted downward from the row new bricks arrive in, so row 0 is the top.
    let row: Int
}

/// Converts between points and cells, using the same arithmetic the generator uses to place
/// a brick - so a brick placed in column j always reads back as column j.
struct EndlessIIFieldGeometry {
    let gameWidth: CGFloat
    let cell: CGSize
    /// The y the generator places a new row at.
    let topRowY: CGFloat
    let columns: Int

    func centre(of cell: EndlessIICell) -> CGPoint {
        CGPoint(x: -gameWidth/2 + self.cell.width/2 + self.cell.width*CGFloat(cell.column),
                y: topRowY - self.cell.height*CGFloat(cell.row))
    }

    func cell(at point: CGPoint) -> EndlessIICell {
        let column = ((point.x + gameWidth/2 - cell.width/2)/cell.width).rounded()
        let row = ((topRowY - point.y)/cell.height).rounded()
        return EndlessIICell(column: Int(column), row: Int(row))
    }

    /// Whether a cell is inside the field's width. Rows are unbounded upward - a brick
    /// above the top row is one that has not arrived yet.
    func isInsideWidth(_ cell: EndlessIICell) -> Bool {
        cell.column >= 0 && cell.column < columns
    }

    /// How many cells across and down a brick of this size covers.
    ///
    /// Never less than one: a Tiny brick is a quarter of a cell but it is still in a cell,
    /// and a brick that claimed no cells would be invisible to everything here.
    func footprint(of size: CGSize) -> (columns: Int, rows: Int) {
        (max(1, Int((size.width/cell.width).rounded())),
         max(1, Int((size.height/cell.height).rounded())))
    }

    /// The eight cells around one, in reading order.
    static func neighbours(of cell: EndlessIICell) -> [EndlessIICell] {
        var found: [EndlessIICell] = []
        for row in (cell.row - 1)...(cell.row + 1) {
            for column in (cell.column - 1)...(cell.column + 1) {
                guard row != cell.row || column != cell.column else { continue }
                found.append(EndlessIICell(column: column, row: row))
            }
        }
        return found
    }
}

extension GameScene {

    var endlessIIGeometry: EndlessIIFieldGeometry {
        EndlessIIFieldGeometry(gameWidth: gameWidth,
                               cell: CGSize(width: brickWidth, height: brickHeight),
                               topRowY: yBrickOffsetEndless,
                               columns: numberOfBrickColumns)
    }

    /// Every cell that currently holds a brick, and how much of it is filled.
    ///
    /// The fraction matters because of Tiny bricks. Four of them share a cell, and clearing
    /// one leaves the cell three-quarters full - which to anything asking "is this cell
    /// occupied" looked exactly the same as untouched. That is what stopped a Gravity brick
    /// falling into a cell that visibly had a hole in it, and what made a Moving brick stop
    /// against what looked like empty space.
    func endlessIIFill() -> [EndlessIICell: CGFloat] {
        let geometry = endlessIIGeometry
        let cellArea = brickWidth*brickHeight
        var fill: [EndlessIICell: CGFloat] = [:]

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            let origin = geometry.cell(at: node.position)
            let size = geometry.footprint(of: brick.size)
            let share = (brick.size.width*brick.size.height)
                / (cellArea*CGFloat(size.columns*size.rows))
            for row in 0..<size.rows {
                for column in 0..<size.columns {
                    let cell = EndlessIICell(column: origin.column + column,
                                             row: origin.row + row)
                    fill[cell, default: 0] += share
                }
            }
        }
        return fill
    }

    /// How full a cell has to be before it counts as blocking something.
    ///
    /// Half. One Tiny brick left in a cell is something the ball can get past and something
    /// a falling brick should be able to land on top of; three of them is not.
    static let endlessIIBlockingFill: CGFloat = 0.5

    func endlessIICellBlocks(_ cell: EndlessIICell, fill: [EndlessIICell: CGFloat]) -> Bool {
        (fill[cell] ?? 0) >= GameScene.endlessIIBlockingFill
    }

    /// Every brick in every cell that holds one.
    ///
    /// A Big brick claims all four of its cells, so a neighbour search finds it from any
    /// side rather than only from the one its node happens to sit on.
    ///
    /// A list per cell rather than one brick. Four Tiny bricks share a cell, and while this
    /// returned a single brick the other three were invisible to everything that asked - the
    /// last one enumerated answered for the cell and the rest did not exist. That is what let
    /// a Moving Tiny brick slide through its own neighbours, and what stopped an Exploding
    /// one taking the Tiny bricks beside it.
    func endlessIIOccupancy() -> [EndlessIICell: [SKSpriteNode]] {
        let geometry = endlessIIGeometry
        var occupied: [EndlessIICell: [SKSpriteNode]] = [:]

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            let origin = geometry.cell(at: node.position)
            let size = geometry.footprint(of: brick.size)
            for row in 0..<size.rows {
                for column in 0..<size.columns {
                    occupied[EndlessIICell(column: origin.column + column,
                                           row: origin.row + row), default: []].append(brick)
                }
            }
        }
        return occupied
    }

    /// Every brick currently in the scene, once each.
    ///
    /// The occupancy map lists a Big brick in each of its four cells, so reading it for a
    /// per-brick pass would visit that one four times.
    func endlessIIBricks() -> [SKSpriteNode] {
        var found: [SKSpriteNode] = []
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let brick = node as? SKSpriteNode { found.append(brick) }
        }
        return found
    }

    /// The cell a brick's node sits in.
    func endlessIICell(of brick: SKSpriteNode) -> EndlessIICell {
        endlessIIGeometry.cell(at: brick.position)
    }

    /// The lowest row a brick can occupy before it is cleared away.
    var endlessIILowestRow: Int {
        endlessIIGeometry.cell(at: CGPoint(x: 0, y: finalBrickRowHeight)).row
    }
}
