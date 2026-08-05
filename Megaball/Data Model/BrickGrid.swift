//
//  BrickGrid.swift
//  Megaball
//
//  Where the bricks are, and what is next to what.
//
//  The existing game computes brick positions inline against a fixed 22-column layout and
//  keeps no record of the field's shape - a brick is an SKSpriteNode at a position, and
//  the only way to ask what is next to it is to search every node by distance. That is
//  enough for the modes that exist, where every brick is one cell and nothing moves.
//
//  It is not enough for bricks that are bigger or smaller than a cell, that fall into
//  gaps, that need clear space around them, or that destroy their neighbours. Those all
//  need the same thing: somewhere to ask what occupies a cell.
//
//  Resolution. The grid counts in *half-cells*, so the three brick sizes are exact:
//
//      Tiny    1x1 half-cells      a quarter of a normal brick
//      Normal  2x2 half-cells
//      Big     4x4 half-cells      two normal bricks square
//
//  One integer grid expresses all of them, with no fractional arithmetic and no special
//  cases. A classic 22-column field is 44 half-cells across.
//
//  This type is deliberately free of SpriteKit. It knows where things are, not how they
//  are drawn, so it can be tested without a scene.
//

import CoreGraphics
import Foundation

/// A position in the grid, counted in half-cells. Column 0 is the left edge, row 0 the top.
struct GridCell: Hashable {
    var column: Int
    var row: Int

    init(_ column: Int, _ row: Int) {
        self.column = column
        self.row = row
    }
}

/// How much of the grid a brick occupies.
enum BrickSize: Int, CaseIterable {
    case tiny = 1
    case normal = 2
    case big = 4

    /// The brick's extent in half-cells, on both axes.
    var halfCells: Int { rawValue }

    /// How this size relates to a normal brick, for scoring and artwork.
    var scale: CGFloat { CGFloat(rawValue)/CGFloat(BrickSize.normal.rawValue) }
}

/// A brick's identity within the grid. The grid does not care what a brick *is* - that
/// belongs to the brick's own type - only where it sits and how big it is.
struct GridBrick: Equatable {
    let id: Int
    var origin: GridCell
    var size: BrickSize

    /// Every half-cell this brick covers.
    var cells: [GridCell] {
        (0..<size.halfCells).flatMap { dx in
            (0..<size.halfCells).map { dy in
                GridCell(origin.column + dx, origin.row + dy)
            }
        }
    }
}

struct BrickGrid {

    /// Width and height in half-cells.
    let columns: Int
    let rows: Int

    private var bricks: [Int: GridBrick] = [:]
    private var occupant: [GridCell: Int] = [:]
    /// Cells kept clear on purpose - the space a Moving brick roams, or the clearance a
    /// Spinning brick's corners sweep through. Reserved cells are not occupied and hold no
    /// brick, but nothing else may be placed in them.
    private var reserved: Set<GridCell> = []

    private var nextID = 0

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    /// Built from a column count in whole bricks, which is how the rest of the game and
    /// every existing level counts.
    init(brickColumns: Int, brickRows: Int) {
        self.init(columns: brickColumns*BrickSize.normal.halfCells,
                  rows: brickRows*BrickSize.normal.halfCells)
    }

    // MARK: - Reading

    var allBricks: [GridBrick] { Array(bricks.values) }
    var count: Int { bricks.count }

    func brick(id: Int) -> GridBrick? { bricks[id] }

    func contains(_ cell: GridCell) -> Bool {
        cell.column >= 0 && cell.column < columns && cell.row >= 0 && cell.row < rows
    }

    func brick(at cell: GridCell) -> GridBrick? {
        occupant[cell].flatMap { bricks[$0] }
    }

    /// Whether a cell is inside the grid, empty, and not held clear for something else.
    func isFree(_ cell: GridCell) -> Bool {
        contains(cell) && occupant[cell] == nil && !reserved.contains(cell)
    }

    /// Whether a brick of this size would fit with its top-left at this cell.
    func canPlace(_ size: BrickSize, at origin: GridCell) -> Bool {
        GridBrick(id: -1, origin: origin, size: size).cells.allSatisfy(isFree)
    }

    // MARK: - Writing

    /// Places a brick and returns its id, or nil if it does not fit.
    @discardableResult
    mutating func place(_ size: BrickSize, at origin: GridCell) -> Int? {
        guard canPlace(size, at: origin) else { return nil }
        let brick = GridBrick(id: nextID, origin: origin, size: size)
        nextID += 1
        bricks[brick.id] = brick
        brick.cells.forEach { occupant[$0] = brick.id }
        return brick.id
    }

    @discardableResult
    mutating func remove(id: Int) -> GridBrick? {
        guard let brick = bricks.removeValue(forKey: id) else { return nil }
        brick.cells.forEach { occupant[$0] = nil }
        return brick
    }

    /// Holds cells clear so nothing is placed in them.
    ///
    /// Used for the space a Moving brick roams and the clearance a Spinning brick needs -
    /// the brick itself occupies its own cells as usual, and these are the ones around it.
    mutating func reserve(_ cells: [GridCell]) {
        cells.filter { isFree($0) }.forEach { reserved.insert($0) }
    }

    mutating func release(_ cells: [GridCell]) {
        cells.forEach { reserved.remove($0) }
    }

    func isReserved(_ cell: GridCell) -> Bool { reserved.contains(cell) }

    /// Moves a brick, if the destination is clear of everything except itself.
    @discardableResult
    mutating func move(id: Int, to origin: GridCell) -> Bool {
        guard let brick = bricks[id] else { return false }
        let destination = GridBrick(id: id, origin: origin, size: brick.size)
        let vacating = Set(brick.cells)
        let fits = destination.cells.allSatisfy { cell in
            contains(cell) && !reserved.contains(cell)
                && (occupant[cell] == nil || occupant[cell] == id || vacating.contains(cell))
        }
        guard fits else { return false }

        brick.cells.forEach { occupant[$0] = nil }
        destination.cells.forEach { occupant[$0] = id }
        bricks[id] = destination
        return true
    }

    // MARK: - Adjacency

    /// The bricks touching this one, including diagonally.
    ///
    /// This is what an Exploding brick destroys. Measured by cell rather than by distance,
    /// so a Big brick's neighbours are everything along its whole edge, and a Tiny brick's
    /// are only what is immediately around its quarter cell.
    func neighbours(of id: Int) -> [GridBrick] {
        guard let brick = bricks[id] else { return [] }
        let own = Set(brick.cells)
        var found: Set<Int> = []

        for cell in brick.cells {
            for dx in -1...1 {
                for dy in -1...1 where !(dx == 0 && dy == 0) {
                    let side = GridCell(cell.column + dx, cell.row + dy)
                    guard own.contains(side) == false, let other = occupant[side] else { continue }
                    found.insert(other)
                }
            }
        }
        return found.compactMap { bricks[$0] }
    }

    // MARK: - Falling

    /// Lets the given bricks fall into the space below them, and reports where they landed.
    ///
    /// Rows count downward, so falling means increasing row. Bricks are settled from the
    /// bottom up, so one falling into a gap does not overtake another already on its way
    /// into the same gap - which is what makes two gravity bricks in a column resolve in
    /// order rather than overlapping.
    ///
    /// Returns each brick that moved with the distance it fell, in half-cells, so the
    /// caller can animate the fall rather than teleporting it.
    @discardableResult
    mutating func settle(_ ids: [Int]) -> [(id: Int, from: GridCell, to: GridCell)] {
        let falling = ids.compactMap { bricks[$0] }.sorted {
            ($0.origin.row + $0.size.halfCells) > ($1.origin.row + $1.size.halfCells)
        }

        var moved: [(id: Int, from: GridCell, to: GridCell)] = []
        for brick in falling {
            let from = brick.origin
            var destination = from
            while true {
                let next = GridCell(destination.column, destination.row + 1)
                guard move(id: brick.id, to: next) else { break }
                destination = next
            }
            if destination != from {
                moved.append((brick.id, from, destination))
            }
        }
        return moved
    }

    // MARK: - Geometry

    /// Where a cell sits, given the rect the whole grid occupies.
    ///
    /// The rect is in scene coordinates, where y increases upward, while rows increase
    /// downward - so row 0 is at the top of the rect.
    func position(of cell: GridCell, in rect: CGRect) -> CGPoint {
        let size = halfCellSize(in: rect)
        return CGPoint(x: rect.minX + (CGFloat(cell.column) + 0.5)*size.width,
                       y: rect.maxY - (CGFloat(cell.row) + 0.5)*size.height)
    }

    /// The centre of a brick, which is not the centre of its origin cell unless it is Tiny.
    func centre(of brick: GridBrick, in rect: CGRect) -> CGPoint {
        let size = halfCellSize(in: rect)
        let extent = CGFloat(brick.size.halfCells)
        return CGPoint(x: rect.minX + (CGFloat(brick.origin.column) + extent/2)*size.width,
                       y: rect.maxY - (CGFloat(brick.origin.row) + extent/2)*size.height)
    }

    func size(of brick: GridBrick, in rect: CGRect) -> CGSize {
        let half = halfCellSize(in: rect)
        let extent = CGFloat(brick.size.halfCells)
        return CGSize(width: half.width*extent, height: half.height*extent)
    }

    func halfCellSize(in rect: CGRect) -> CGSize {
        CGSize(width: rect.width/CGFloat(columns), height: rect.height/CGFloat(rows))
    }

    /// The cell containing a point, or nil if it falls outside the grid.
    func cell(at point: CGPoint, in rect: CGRect) -> GridCell? {
        let size = halfCellSize(in: rect)
        guard size.width > 0, size.height > 0 else { return nil }
        // floor, not truncation: Int() rounds toward zero, so a point just outside the
        // top or left edge gave -0.5 -> 0 and landed in the grid rather than outside it.
        let column = Int(floor((point.x - rect.minX)/size.width))
        let row = Int(floor((rect.maxY - point.y)/size.height))
        let cell = GridCell(column, row)
        return contains(cell) ? cell : nil
    }
}
