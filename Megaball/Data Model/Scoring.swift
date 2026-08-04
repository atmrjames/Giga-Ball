//
//  Scoring.swift
//  Megaball
//
//  The scoring and multiplier rules, lifted out of GameScene so they can be
//  tested. Pure arithmetic: no scene, no nodes, no state.
//
//  These functions reproduce what GameScene did inline, exactly, including
//  three things that look like mistakes and are deliberately preserved,
//  because changing any of them changes what players score and breaks
//  comparability with the leaderboards already posted:
//
//  - The multiplier steps every twentieth brick, not every brick.
//  - The brick path does not snap to the cap, so repeated += 0.1 from 1.0
//    accumulates binary floating-point error and the multiplier sits just
//    below or just above 2.0 rather than on it. The other two paths do snap.
//  - The level-completion award is not multiplied. The timer bonus is.
//
//  Each is called out at the function that carries it.
//

import Foundation

enum Scoring {

    // MARK: - Base values

    /// Points for destroying a brick, before the multiplier. Flat regardless of
    /// brick colour or type.
    static let brickDestroyed = 10

    /// Points for completing a level. Awarded unmultiplied - see `levelCompletionAward`.
    static let levelCompleted = 100

    /// The timer bonus a level starts with, before time taken is deducted.
    static let timerBonusStart = 500

    // MARK: - Multiplier bounds

    static let multiplierBase = 1.0
    static let multiplierCap = 2.0
    static let multiplierStep = 0.1

    /// The multiplier steps once per this many bricks destroyed, not once per
    /// brick. GameScene counts to nineteen and steps on the twentieth.
    static let bricksPerMultiplierStep = 20

    // MARK: - Awards

    /// Points for `base` at the current multiplier.
    ///
    /// Truncates toward zero, which is what `Int(Double)` does and what every
    /// score on the leaderboards was computed with. Note the asymmetry that
    /// gives negative point power-ups: -100 at 1.5x truncates to -150, but
    /// -100 at 1.05x truncates to -105 rather than rounding to -105.
    static func award(_ base: Int, multiplier: Double) -> Int {
        Int(Double(base) * multiplier)
    }

    /// Points for completing a level.
    ///
    /// Deliberately ignores the multiplier. The specification describes every
    /// award as multiplied, but GameScene adds this one flat, at both of its
    /// call sites. Preserved as-is.
    static func levelCompletionAward() -> Int {
        levelCompleted
    }

    /// The end-of-level timer bonus.
    ///
    /// Starts at `timerBonusStart`, loses a point per second taken, floors at
    /// zero, and is then multiplied - so a fast level finished on a high
    /// multiplier is worth substantially more than the brick score alone.
    static func timerBonus(from remaining: Int, elapsed: Int, multiplier: Double) -> Int {
        let afterTime = max(remaining - elapsed, 0)
        return Int(Double(afterTime) * multiplier)
    }

    // MARK: - Multiplier transitions

    /// The multiplier after destroying the brick that completes a step.
    ///
    /// Steps only while below the cap and does **not** snap to it, so from 1.0
    /// the sequence accumulates floating-point error and lands near 2.0 rather
    /// than on it. `steppedForBonus` and `adjusted` both snap; this one does
    /// not. Preserved because snapping would change scores.
    static func steppedForBrick(_ multiplier: Double) -> Double {
        multiplier < multiplierCap ? multiplier + multiplierStep : multiplier
    }

    /// The multiplier after a bonus award.
    ///
    /// Steps while below the cap and snaps to exactly the cap on reaching it.
    static func steppedForBonus(_ multiplier: Double) -> Double {
        guard multiplier < multiplierCap else { return multiplier }
        let stepped = multiplier + multiplierStep
        return stepped >= multiplierCap ? multiplierCap : stepped
    }

    /// The multiplier after a power-up applies `delta`, clamped to the base and
    /// the cap. Power-ups carry +0.1, -0.1 or 0.
    static func adjusted(_ multiplier: Double, by delta: Double) -> Double {
        let moved = multiplier + delta
        if moved < multiplierBase { return multiplierBase }
        if moved >= multiplierCap { return multiplierCap }
        return moved
    }

    /// Whether the multiplier should read as maxed out. GameScene uses this to
    /// colour the label, and it is `>=` rather than `==` precisely because the
    /// brick path can overshoot.
    static func isAtCap(_ multiplier: Double) -> Bool {
        multiplier >= multiplierCap
    }

    /// The multiplier as displayed: one decimal place, e.g. "1.0" ... "2.0".
    static func displayString(_ multiplier: Double) -> String {
        String(format: "%.1f", multiplier)
    }
}
