//
//  EndlessIIClock.swift
//  Megaball
//
//  One timed power-up's clock: how long is left, what it counts down from, and how deep the
//  stacking has gone.
//
//  Endless 2.0's own power-ups keep their own time rather than borrowing an SKAction, because
//  an action pauses with its node and these have to pause with *play* - the countdown after
//  the pause menu runs the scene while the game stands still. The vision batch grew two of
//  these as loose properties; the paddle batch would have grown sixteen more, which is the
//  point at which the shape becomes a type.
//
//  The rules are §5.4's defaults, held in one place: a second collection extends the duration
//  rather than restarting it, and where a magnitude makes sense a further collection deepens
//  it, one step at a time, never past the table that defines the steps.
//

import CoreGraphics
import Foundation

struct EndlessIIClock: Equatable {

    /// Seconds left. Zero is off.
    var remaining: TimeInterval = 0
    /// What the ring's fraction is measured against - the remaining time at the moment of
    /// the last collection, so the ring reads full when a collection tops the clock up.
    var total: TimeInterval = 0
    /// How many deepening collections have landed while it was already running.
    var level: Int = 0
    /// Whether this clock counts turns - rows, catches - rather than seconds.
    ///
    /// Most turn-counting clocks are kept apart from the timed ones by which *list* they are
    /// in, and never need this. Descent is the exception that forced it (§12.0's rows item):
    /// a row budget spent on a time cadence belongs in the Lock's world - a Lock should both
    /// stop its stepping and count it as worth freezing - so it stays in the timed list, and
    /// the questions that assumed seconds ask the clock instead.
    var countsTurns: Bool = false

    var isRunning: Bool { remaining > 0 }

    /// How much is left, from one down to zero, for the ring.
    var fraction: CGFloat {
        total > 0 ? CGFloat(max(0, min(1, remaining/total))) : 0
    }

    /// A collection lands.
    ///
    /// Extends if already running; the deepening step only happens on a collection that
    /// found it running, so the first collection is always the base effect.
    mutating func collect(_ duration: TimeInterval, deepestLevel: Int = 0) {
        if isRunning {
            level = min(level + 1, deepestLevel)
        }
        remaining += duration
        total = remaining
    }

    /// A collection lands, measured in turns rather than seconds.
    mutating func collect(turns: Int, deepestLevel: Int = 0) {
        collect(TimeInterval(turns), deepestLevel: deepestLevel)
        countsTurns = true
    }

    /// Whether this clock will still be running by the time a Lock dropped now has fallen.
    ///
    /// The Lock's drop rule used to compare every clock's `remaining` against a lead measured
    /// in seconds - meaningless the moment one of the timed clocks counts rows. Asked of the
    /// clock instead: a seconds clock needs more left than the fall takes, and a turns clock
    /// does not decay with time at all, so any turn left will still be there when the Lock
    /// lands.
    func outlastsALockDrop(lead: TimeInterval) -> Bool {
        countsTurns ? isRunning : remaining > lead
    }

    /// A turn was used - for the clocks that count paddle hits rather than seconds,
    /// the way the sticky paddle always has (§5.4, revised in play-testing).
    mutating func spendTurn() {
        remaining = max(0, remaining - 1)
        if remaining == 0, total > 0 {
            self = EndlessIIClock()
        }
    }

    /// Play advanced by this much.
    mutating func run(down delta: TimeInterval) {
        remaining = max(0, remaining - delta)
        if remaining == 0, total > 0 {
            self = EndlessIIClock()
            // Expiry clears the level too - the next collection starts over, like every
            // other power-up in the game
        }
    }

    /// Puts a saved clock back.
    mutating func restore(remaining: TimeInterval, total: TimeInterval, level: Int,
                          deepestLevel: Int = 0) {
        self.remaining = max(0, remaining)
        self.total = max(self.remaining, total)
        self.level = min(max(0, level), deepestLevel)
        // Clamped in every direction: a save is a file on disk, read at launch, and a level
        // used as an index must not be able to trap
    }

    mutating func reset() {
        self = EndlessIIClock()
    }
}
