//
//  EndlessIIExclusions.swift
//  Megaball
//
//  Which power-ups cannot run alongside which, and therefore end each other.
//
//  From James's interaction matrix (Giga-Ball 2026.xlsx), where the answer is written as
//  "most recent power-up overrides" - fifteen cells of it. It is deliberately *not* the
//  group model `PowerUpCatalogue.conflict` uses, and could not be: these are pairs rather
//  than a partition. Inert Ball ends a Giga-Ball, a Wrecking Ball and a Ball Aura, but those
//  three combine happily with each other. Auto-Aim ends a Portal, and a Portal runs quite
//  contentedly with an Inert Paddle. A group would have to claim a conflict the game does
//  not have, and §8.6's own warning applies: a rule written down twice is wrong the first
//  time the rule changes.
//
//  So this is the list of pairs, once, and the scene ends whichever half it did not just
//  collect. Symmetric by construction - "most recent overrides" means either order - which
//  is also what makes it readable next to the matrix it came from.
//

import Foundation

/// A power-up that ends, or is ended by, at least one other.
///
/// Only the ones that appear in a pair below. Everything else in the game combines, which is
/// the default answer and the reason this list is short.
enum EndlessIIExclusive: CaseIterable {
    case gigaBall
    case inertBall
    case wreckingBall
    case ballAura
    case stickyPaddle
    case aimedSticky
    case inertPaddle
    case flippedAngle
    case autoAim
    case ballSpin
    case portalPaddle
    case ballControl
}

enum EndlessIIExclusions {

    /// Every pair that cannot run at once. Collecting either ends the other.
    ///
    /// Read straight off the matrix, in its order, so the two can be compared line by line.
    static let pairs: [(EndlessIIExclusive, EndlessIIExclusive)] = [
        (.inertBall, .gigaBall),
        (.wreckingBall, .inertBall),
        (.ballAura, .inertBall),
        // Inert Ball is the one that stops the ball taking bricks, so everything that exists
        // to take bricks ends it. The three of them combine with each other, which is why
        // this cannot be a group

        (.inertPaddle, .aimedSticky),
        (.flippedAngle, .aimedSticky),
        (.flippedAngle, .inertPaddle),
        (.autoAim, .aimedSticky),
        (.autoAim, .portalPaddle),
        (.autoAim, .inertPaddle),
        (.autoAim, .flippedAngle),
        (.ballSpin, .stickyPaddle),
        (.ballSpin, .aimedSticky),
        (.ballSpin, .ballControl),
        (.ballSpin, .inertPaddle),
        (.ballSpin, .autoAim),
        // The rest all decide where the ball goes when it leaves the paddle, and two answers
        // to that question is one too many. Not every pair of them is here: a Portal and an
        // Inert Paddle agree perfectly (nothing angles the ball, and it comes out of the top),
        // and Ball Spin off a Flipped Angle is simply spin the other way
    ]

    /// What collecting this power-up ends.
    static func ended(byCollecting collected: EndlessIIExclusive) -> [EndlessIIExclusive] {
        pairs.compactMap { first, second in
            if first == collected { return second }
            if second == collected { return first }
            return nil
        }
    }
}
