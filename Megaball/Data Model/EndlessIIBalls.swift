//
//  EndlessIIBalls.swift
//  Megaball
//
//  The rules a collection of balls follows, separately from the balls themselves.
//
//  Endless 2.0 is the only mode that has more than one (§5.5). Classic and Endless keep a
//  single ball and are not touched by any of this - which is the whole reason the scene grows
//  a *collection* alongside its ball rather than being rewritten around one.
//
//  The rule that matters: the run continues while at least one ball is in play, and the life
//  is lost when the last one goes. Everything else here follows from that.
//

import CoreGraphics

enum EndlessIIBalls {

    /// How many balls may be in play at once.
    ///
    /// Four. Past that the field stops being something a player reads and becomes something
    /// they watch, and each ball is a physics body running its own contact handling - §12
    /// asks specifically whether four is affordable.
    static let maximum = 4

    /// Whether another ball can be added.
    static func canAdd(inPlay: Int) -> Bool {
        inPlay < maximum
    }

    /// What losing a ball costs.
    ///
    /// The distinction the whole phase is built on. With one ball this is the behaviour the
    /// game has always had; with more, losing one is free and only the last one ends the run.
    enum Loss {
        /// Balls remain. The run carries on and nothing is spent.
        case carryOn
        /// That was the last one.
        case lifeLost
    }

    static func losing(oneOf inPlay: Int) -> Loss {
        inPlay > 1 ? .carryOn : .lifeLost
    }

    /// Where a new ball is launched, relative to the ball it was added from.
    ///
    /// Turned away from the parent rather than copied from it, or a Multi-Ball would produce
    /// two balls travelling as one and the player would not know anything had happened until
    /// they drifted apart. Alternating sides keeps the pair symmetrical about the original,
    /// so the field is opened up evenly rather than pushed to one side.
    ///
    /// The speed is the parent's. Ball speed is a single shared value across every ball in
    /// play (§5.5), so a new one arrives at whatever speed the run is running at.
    static func launchAngle(of parent: CGVector, index: Int) -> CGVector {
        let speed = (parent.dx*parent.dx + parent.dy*parent.dy).squareRoot()
        guard speed > 0 else {
            // Added while the ball is sitting on the paddle, which has no heading yet
            let spread = spreadAngle*CGFloat(index.isMultiple(of: 2) ? 1 : -1)
            return CGVector(dx: sin(spread), dy: cos(spread))
        }

        let heading = atan2(parent.dy, parent.dx)
        let turn = spreadAngle*CGFloat(index.isMultiple(of: 2) ? 1 : -1)
        return CGVector(dx: cos(heading + turn)*speed, dy: sin(heading + turn)*speed)
    }

    /// How far a new ball is turned from its parent.
    ///
    /// Wide enough that the two separate immediately and narrow enough that a ball added while
    /// travelling up is still travelling up - a new ball that launches sideways into a wall
    /// reads as a mistake rather than as a gift.
    static let spreadAngle: CGFloat = .pi/6

    /// Where a new ball is placed, given where its parent is.
    ///
    /// Clear of the parent, or the two are created inside one another and the physics resolves
    /// that by throwing both somewhere arbitrary.
    static func launchPosition(from parent: CGPoint, heading: CGVector,
                               clearance: CGFloat) -> CGPoint {
        let speed = (heading.dx*heading.dx + heading.dy*heading.dy).squareRoot()
        guard speed > 0 else { return CGPoint(x: parent.x, y: parent.y + clearance) }
        return CGPoint(x: parent.x + heading.dx/speed*clearance,
                       y: parent.y + heading.dy/speed*clearance)
    }

    // MARK: - Saving

    /// One ball as it is written into a save: where it is and how it is travelling.
    struct Saved: Equatable {
        var position: CGPoint
        var velocity: CGVector
    }

    /// The four values each extra ball carries: x, y, dx, dy.
    ///
    /// Four rather than the primary ball's five - the fifth there is the paddle's x, which
    /// belongs to the game rather than to a ball and is written once.
    static let savedPropertiesCount = 4

    /// Flattens the extra balls into the array a save holds.
    ///
    /// Flat doubles rather than a nested type because that is the shape every other array in
    /// `SavedGame` already has, and because a save written by this build has to still decode in
    /// the next one.
    static func flattened(_ balls: [Saved]) -> [Double] {
        balls.prefix(maximum - 1).flatMap {
            [Double($0.position.x), Double($0.position.y),
             Double($0.velocity.dx), Double($0.velocity.dy)]
        }
        // Capped on the way in as well as on the way out. A save holding five extras came from
        // somewhere that was not this game, and restoring it would put more balls on the field
        // than the mode allows
    }

    /// Reads the extra balls back out of a save.
    ///
    /// Forgiving in both directions: a trailing group that is short of four values is dropped
    /// rather than read past the end, and anything beyond the maximum is ignored. A save is a
    /// file on disk that an older build - or a bad write - may have left in any state, and this
    /// runs at launch where a trap is a crash on opening the app.
    static func unflattened(_ properties: [Double]?) -> [Saved] {
        guard let properties else { return [] }

        let whole = properties.count/savedPropertiesCount
        return (0..<min(whole, maximum - 1)).map { index in
            let base = index*savedPropertiesCount
            return Saved(position: CGPoint(x: properties[base], y: properties[base + 1]),
                         velocity: CGVector(dx: properties[base + 2], dy: properties[base + 3]))
        }
    }
}
