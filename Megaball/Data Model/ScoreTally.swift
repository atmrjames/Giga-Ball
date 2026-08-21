//
//  ScoreTally.swift
//  Megaball
//
//  The count-up at the end of a level: level score, then the speed bonus, then the total
//  taking both on top of what it was when the level started.
//

import CoreGraphics
import QuartzCore

/// The arithmetic and the timing of the end-of-level count-up, with no view attached.
///
/// It lived inside `InbetweenViewController` until round 210, which was fine while one screen
/// counted. The daily's Complete screen wants the same three numbers counted the same way
/// (James: "it should be broken down like the end of a pack in classic mode - level score,
/// time bonus and total score, using the same tally animation"), and two copies of a timing
/// curve are two curves the first time either is touched.
///
/// The *labels* stay with each screen, because they sit in quite different layouts; what is
/// shared is what the numbers read at a given moment, which is the part a player would notice
/// diverging.
enum ScoreTally {

    /// What is being counted.
    struct Values {
        /// The level's own score.
        let level: Int
        /// The time bonus on top of it.
        let bonus: Int
        /// What the total stood at before this level.
        let from: Int
        /// What it stands at now.
        let to: Int
    }

    /// What the three numbers read at a moment.
    struct Reading: Equatable {
        let level: Int
        let bonus: Int
        let total: Int
    }

    /// Short on purpose: this sits between finishing a level and playing the next one, so it
    /// should read as a flourish rather than something to sit through.
    static let levelDuration: CFTimeInterval = 0.28
    static let bonusDuration: CFTimeInterval = 0.22
    static let totalDuration: CFTimeInterval = 0.36

    static var bonusStart: CFTimeInterval { levelDuration }
    static var totalStart: CFTimeInterval { bonusStart + bonusDuration }
    static var duration: CFTimeInterval { totalStart + totalDuration }

    /// How many haptic ticks the whole count is worth.
    static let hapticTicks = 10

    /// The reading at this point in the count.
    ///
    /// **Each number stays where it lands.** They used to drain back to zero once the total
    /// had taken them, which read as though the level had been worth nothing - you finished a
    /// level and the number beside it was 0. So whatever a phase has not reached yet reads
    /// zero, and whatever it has finished keeps its full value: the sequence is the point, and
    /// nothing runs backwards.
    ///
    /// Eased out, so each number decelerates into its value rather than stopping dead.
    static func reading(at elapsed: CFTimeInterval, of values: Values) -> Reading {
        guard elapsed < duration else {
            return Reading(level: values.level, bonus: values.bonus, total: values.to)
        }
        if elapsed < bonusStart {
            return Reading(level: scaled(values.level, by: easeOut(elapsed/levelDuration)),
                           bonus: 0,
                           total: values.from)
        }
        if elapsed < totalStart {
            let eased = easeOut((elapsed - bonusStart)/bonusDuration)
            return Reading(level: values.level,
                           bonus: scaled(values.bonus, by: eased),
                           total: values.from)
        }
        let eased = easeOut((elapsed - totalStart)/totalDuration)
        return Reading(level: values.level,
                       bonus: values.bonus,
                       total: values.from + scaled(values.to - values.from, by: eased))
    }

    /// Which haptic tick an elapsed time falls in, so a screen can buzz on the change.
    static func tick(at elapsed: CFTimeInterval) -> Int {
        Int(elapsed/duration*Double(hapticTicks))
    }

    static func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }

    private static func scaled(_ value: Int, by fraction: Double) -> Int {
        Int((Double(value)*fraction).rounded())
    }
}
