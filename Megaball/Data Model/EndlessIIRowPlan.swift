//
//  EndlessIIRowPlan.swift
//  Megaball
//
//  What a row leaves empty, and what it fills.
//
//  Rows in Endless Mayhem arrive one at a time from the top with nothing above them. Anything
//  taller than a single row therefore cannot be built when its turn comes: there is no row
//  above it to hang from. So the field builds those over two rows - one leaves the cells
//  empty, the next builds down into the gap - and a row is either reserving or building,
//  never both.
//
//  That sequence lived as four optional columns on the scene, one per shape, each cleared at
//  the top of the planning function and checked in a fixed order. It worked, and it was four
//  ways of saying one thing: four properties to clear on a reset, four cases in the priority
//  chain, and four places to remember when a fifth shape arrives.
//
//  A fifth is what is coming. The 2x1 square size wants this sequence (§12.0), a designed
//  formation asking for a Big brick wants to drive it rather than roll for it, and §6.2's
//  Monolith wants both at once. So the shape is a value now, and there is one slot to put it
//  in.
//
//  ## The spinner is the odd one
//
//  It is a single cell, not a tall shape - but it sweeps a circle wider than its own cell, so
//  the generator keeps the cells above and below it empty. That is the same sequence run over
//  three rows instead of two: reserve below, place, then book the clearance above. It is
//  expressed here as two shapes rather than as a special case, because "what does this row
//  leave empty" and "what does this row build" are the same two questions for it as for
//  everything else.
//

import Foundation

/// Something a row cannot build on its own.
enum EndlessIITwoRowBuild: Equatable {
    /// Two cells by two, hanging from its top-left cell (§8.6).
    case big(leftColumn: Int)
    /// One cell wide and two tall, holding a power-up.
    case powerUpBrick(column: Int)
    /// A turning brick, which needs the cells around it kept clear.
    case spinner(column: Int)
    /// The cell above a spinner placed a row ago.
    case spinnerClearance(column: Int)

    /// The column its own node sits in, whatever else it reaches.
    var column: Int {
        switch self {
        case .big(let column), .powerUpBrick(let column),
             .spinner(let column), .spinnerClearance(let column):
            return column
        }
    }

    /// The columns the row *before* this one has to leave empty.
    ///
    /// What a shape needs underneath it, which for the tall ones is the cells it will grow
    /// down into and for a spinner is the one cell beneath its swept circle.
    func columnsToReserve(in columns: Int) -> Set<Int> {
        switch self {
        case .big(let left): return trimmed([left, left + 1], to: columns)
        case .powerUpBrick(let column), .spinner(let column), .spinnerClearance(let column):
            return trimmed([column], to: columns)
        }
    }

    /// The columns the row that *builds* it has to leave empty.
    ///
    /// The same cells for a tall shape - it fills them itself, so the generator must not put an
    /// ordinary brick there first - and the two *sides* for a spinner, which is placed on this
    /// row and needs room to turn.
    func columnsToClear(in columns: Int) -> Set<Int> {
        switch self {
        case .big(let left): return trimmed([left, left + 1], to: columns)
        case .powerUpBrick(let column), .spinnerClearance(let column):
            return trimmed([column], to: columns)
        case .spinner(let column): return trimmed([column - 1, column + 1], to: columns)
        }
    }

    private func trimmed(_ wanted: [Int], to columns: Int) -> Set<Int> {
        Set(wanted.filter { $0 >= 0 && $0 < columns })
    }
}

/// One row's instructions: what to leave empty, and what to build.
struct EndlessIIRowPlan: Equatable {
    var skip: Set<Int> = []
    /// What this row builds. Nil on a row that is only reserving, which is most of them.
    var build: EndlessIITwoRowBuild?

    /// The left column of a Big brick due on this row.
    ///
    /// These three read the one value the row generator has always asked for by three names.
    /// Kept as names rather than as a `switch` at the call site, because the generator's job is
    /// to build a row and not to know which shapes exist.
    var dueAt: Int? {
        if case .big(let column) = build { return column }
        return nil
    }

    var powerUpAt: Int? {
        if case .powerUpBrick(let column) = build { return column }
        return nil
    }

    var spinAt: Int? {
        if case .spinner(let column) = build { return column }
        return nil
    }
}
