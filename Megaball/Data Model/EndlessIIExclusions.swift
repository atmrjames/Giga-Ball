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

import SpriteKit

extension GameScene {

    /// The power-up indices that collecting this index would end.
    ///
    /// The bridge between `EndlessIIExclusions`, which speaks in named power-ups, and the
    /// drop tables, which speak in indices. Built from the name array so a rename cannot
    /// silently empty it, and returning nothing for a power-up that ends nothing - which is
    /// most of them, and the reason this reads as short.
    static func endlessIIExclusiveIndicesEnded(byCollecting index: Int) -> [Int] {
        let names = LevelPackSetup().powerUpNameArray
        guard names.indices.contains(index),
              let collected = EndlessIIExclusive(powerUpName: names[index]) else { return [] }
        return EndlessIIExclusions.ended(byCollecting: collected)
            .compactMap { ended in names.firstIndex(of: ended.powerUpName) }
    }
}

extension EndlessIIExclusive {

    /// The name this power-up carries in `LevelPackSetup.powerUpNameArray`.
    ///
    /// Written out rather than derived from the case name: the two have drifted once already
    /// (Ball Steering became Ball Control in round 218 while the case stayed `ballControl`),
    /// and a mapping that guesses is a mapping that is quietly empty the next time they drift.
    var powerUpName: String {
        switch self {
        case .gigaBall: return "Giga-Ball"
        case .inertBall: return "Inert Ball"
        case .wreckingBall: return "Wrecking Ball"
        case .ballAura: return "Ball Aura"
        case .stickyPaddle: return "Sticky Paddle"
        case .aimedSticky: return "Aimed Sticky"
        case .inertPaddle: return "Inert Paddle"
        case .flippedAngle: return "Flipped Bounce Angle"
        case .autoAim: return "Auto-Aim"
        case .ballSpin: return "Ball Spin"
        case .portalPaddle: return "Portal"
        case .ballControl: return "Ball Control"
        }
    }

    init?(powerUpName: String) {
        guard let match = EndlessIIExclusive.allCases
            .first(where: { $0.powerUpName == powerUpName }) else { return nil }
        self = match
    }
}
