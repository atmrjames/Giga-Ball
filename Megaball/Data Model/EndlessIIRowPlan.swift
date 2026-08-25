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
    /// One cell wide and two tall, and an ordinary brick - the Square size (§12.0).
    case square(column: Int)
    /// A turning brick, which needs the cells around it kept clear.
    case spinner(column: Int)
    /// The cell above a spinner placed a row ago.
    case spinnerClearance(column: Int)

    /// The column its own node sits in, whatever else it reaches.
    var column: Int {
        switch self {
        case .big(let column), .powerUpBrick(let column), .square(let column),
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
        case .powerUpBrick(let column), .square(let column),
             .spinner(let column), .spinnerClearance(let column):
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
        case .powerUpBrick(let column), .square(let column), .spinnerClearance(let column):
            return trimmed([column], to: columns)
        case .spinner(let column): return trimmed([column - 1, column + 1], to: columns)
        }
    }

    private func trimmed(_ wanted: [Int], to columns: Int) -> Set<Int> {
        Set(wanted.filter { $0 >= 0 && $0 < columns })
    }
}

/// One thing a row builds, and what it was drawn as.
///
/// The spec is the half that arrived in round 253. A Big or Square brick is built by its own
/// function from the field's own mix, which is right for a rolled one and wrong for a drawn
/// one: a formation asking for a multi-hit Big brick was getting a standard one, with nothing
/// anywhere to say it had not. It rides *with* the build rather than beside it, because a
/// booking and the thing it was booked as are one fact and two properties would be two.
struct EndlessIIBooking: Equatable {
    var build: EndlessIITwoRowBuild
    /// The legend's spec, when a formation is what booked this. Nil for the generator's own
    /// rolls, which are a size and nothing else.
    var spec: EndlessIIBrickSpec?

    init(_ build: EndlessIITwoRowBuild, spec: EndlessIIBrickSpec? = nil) {
        self.build = build
        self.spec = spec
    }
}

/// One row's instructions: what to leave empty, and what to build.
///
/// **A list rather than one slot** (round 254). A row could hold one shape, which was true of
/// everything that had ever asked for one: the generator rolls at most one per row, and a
/// formation was held to the same limit. §6.2's Monolith is the phase that cannot live with
/// it - "one enormous Big brick formation with a narrow route" is four Big bricks abreast, and
/// four bricks abreast is four reservations from one row.
///
/// What did *not* change is the rule underneath: a row either reserves or builds, never both.
/// A row with bookings outstanding builds them all; a row with none may make some. So there is
/// still only ever one generation of bookings in flight, and it is still the row below that
/// leaves the cells empty.
struct EndlessIIRowPlan: Equatable {
    var skip: Set<Int> = []
    /// What this row builds. Empty on a row that is only reserving, which is most of them.
    var builds: [EndlessIIBooking] = []

    init(skip: Set<Int> = [], builds: [EndlessIIBooking] = []) {
        self.skip = skip
        self.builds = builds
    }

    /// One shape, which is what almost every row that builds anything is building.
    init(skip: Set<Int> = [], build: EndlessIITwoRowBuild) {
        self.init(skip: skip, builds: [EndlessIIBooking(build)])
    }

    /// The Big bricks due on this row, and what each was drawn as.
    ///
    /// These four read the bookings the row generator has always asked for by name, rather
    /// than making every call site switch over a build it does not otherwise care about.
    var bigs: [EndlessIIBooking] {
        builds.filter { if case .big = $0.build { return true } else { return false } }
    }

    var squares: [EndlessIIBooking] {
        builds.filter { if case .square = $0.build { return true } else { return false } }
    }

    /// The two that are only ever rolled, and only ever one to a row.
    var powerUpAt: Int? {
        builds.compactMap { if case .powerUpBrick(let column) = $0.build { return column }
                            else { return nil } }.first
    }

    var spinAt: Int? {
        builds.compactMap { if case .spinner(let column) = $0.build { return column }
                            else { return nil } }.first
    }

    /// Whether this row builds something that counts as filling it.
    ///
    /// The density floor asks before the two-row shapes are added, because a row about to grow
    /// one is not an empty row. A spinner is not counted, which is how it has always been.
    var fillsTheRow: Bool {
        bigs.isEmpty == false || squares.isEmpty == false || powerUpAt != nil
    }
}
