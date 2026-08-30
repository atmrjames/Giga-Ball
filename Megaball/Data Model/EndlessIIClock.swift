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
//  The rules are held in one place: a second collection restarts the duration rather than
//  adding to it, and where a magnitude makes sense a further collection deepens it, one step
//  at a time, never past the table that defines the steps. §5.4's original default was to
//  extend; round 220's interaction matrix says reset, everywhere, and stacking is expressed
//  as depth instead.
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

    var isRunning: Bool { remaining > 0 || goodbye > 0 }

    /// How much is left, from one down to zero, for the ring.
    ///
    /// **Zero for the whole goodbye second** (James, round 259: "the power-up HUD progress bar
    /// is resetting and quickly animating down at the end of the last paddle hit segment. This
    /// is unnecessary. Delay the change back to a normal paddle, but there's no need for this
    /// additional animation").
    ///
    /// The goodbye was built as an ordinary clock of one second, which meant the ring refilled
    /// itself and swept round again - a second countdown, of a thing that had already counted
    /// down, that nobody had asked for. The delay is the point and the animation was a side
    /// effect of how it was expressed. Spent, is what the ring says now, for the second the
    /// paddle takes to change back.
    var fraction: CGFloat {
        guard lingering == false else { return 0 }
        return total > 0 ? CGFloat(max(0, min(1, remaining/total))) : 0
    }

    /// Seconds of goodbye left after the last turn is spent.
    ///
    /// **Its own field rather than the clock reset to a one-second timer** (round 263). The
    /// goodbye used to be expressed by overwriting `total`, `remaining` and `countsTurns`,
    /// which had two consequences nobody wanted: the ring refilled and swept round a second
    /// time, and the segment marks came off because the clock had stopped counting turns. Kept
    /// apart, everything the ring reads about turns survives the goodbye and simply reads as
    /// spent.
    var goodbye: TimeInterval = 0

    /// A collection lands.
    ///
    /// **The clock starts again rather than being added to** (James, round 220's interaction
    /// matrix, which says "duration is reset" for every power-up collected on top of itself).
    /// §5.4's original default was to extend, and extending is what made a run that met three
    /// Drifts in a row spend half a minute sliding sideways: the collections compounded, and
    /// a power-up whose *length* stacks is a different power-up from one whose strength does.
    /// Resetting keeps a collection worth having - the clock is full again - without letting
    /// the good ones run away or the bad ones become a sentence.
    ///
    /// The deepening step still only happens on a collection that found it running, so the
    /// first collection is always the base effect and stacking is expressed as depth, which is
    /// the axis the matrix does describe ("further ball speed decrease, duration is reset").
    ///
    /// This is also how the original twenty-eight have always behaved: they cancel their own
    /// timer action and schedule a fresh one, which is a reset written out longhand.
    mutating func collect(_ duration: TimeInterval, deepestLevel: Int = 0) {
        if isRunning {
            level = min(level + 1, deepestLevel)
        }
        remaining = duration
        total = duration
    }

    /// A collection that never runs out on its own.
    ///
    /// The Lock, and only the Lock (James, round 218: "Lock shouldn't have a timer. It is only
    /// stopped by Key"). A held clock reads as running for ever and its ring reads as full,
    /// which is the honest picture: there is no time left on it to show, because time is not
    /// what ends it.
    ///
    /// Held rather than given an enormous duration, because a duration is something the ring
    /// would draw down and something a Lock-freezes-everything rule would have to remember to
    /// leave alone. A full ring that never moves says "until a Key" without a word.
    mutating func hold() {
        remaining = 1
        total = 1
        countsTurns = false
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
    mutating func spendTurn(thenLingerFor linger: TimeInterval = 0) {
        guard goodbye == 0 else { return }
        // A clock already saying goodbye has nothing left to spend, and spending one anyway
        // was taking a second off the farewell rather than a turn off the power-up
        remaining = max(0, remaining - 1)
        if remaining == 0, total > 0, linger > 0 {
            goodbye = linger
            // `total`, `remaining` and `countsTurns` are all left exactly as they are, so the
            // ring keeps its segment marks through the goodbye and shows every one of them
            // spent. Overwriting them refilled the ring and took the marks off, which is a
            // different power-up's HUD wearing this one's icon for a second
            // **The last turn does not end it, it starts the goodbye** (James, round 231: "on
            // the last bounce of a paddle hit based power up, wait a second to remove the
            // power up and HUD icon. Especially the shaped paddles power ups. They look weird
            // when they immediately change to a normal paddle when the ball bounces").
            //
            // A second of ordinary time, spent by `run(down:)` like any other clock, so
            // everything that reads "is it running" goes on saying yes for that second: the
            // paddle keeps its shape, the ring keeps its icon, and the effect keeps working.
            // It stops counting *turns* though, because there are none left to count - which
            // is also what takes the segment marks off the ring for the last second, and
            // that is the honest picture of a power-up that has no turns and a little time.
            //
            // **Asked for rather than assumed**, and Descent is why. It counts rows, not
            // paddle hits, and a Descent that ran a second past its last row would not be
            // worth exactly its rows any more - which is a promise §5.4 makes and a test
            // holds it to. The goodbye is for the power-ups a player watches change shape.
        } else if remaining == 0, total > 0 {
            self = EndlessIIClock()
        }
    }

    /// How long a spent turn-based power-up stays before it goes.
    ///
    /// One second, which is James's own number. Long enough that a shape does not snap back in
    /// the same frame the ball leaves it, short enough that nobody plays a bounce on it.
    static let lingerSeconds: TimeInterval = 1

    /// Whether this clock is running out its goodbye rather than its turns.
    ///
    /// Not saved: a run resumed mid-goodbye comes back without it, which is a power-up ending
    /// a second early after an interruption that took longer than that anyway.
    var lingering: Bool { goodbye > 0 }

    /// Play advanced by this much.
    mutating func run(down delta: TimeInterval) {
        if goodbye > 0 {
            goodbye = max(0, goodbye - delta)
            if goodbye == 0 { self = EndlessIIClock() }
            return
            // A clock in its goodbye has no turns left to spend and no time left to run: the
            // only thing still counting is the second the paddle takes to change back
        }
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
