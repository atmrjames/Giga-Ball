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
