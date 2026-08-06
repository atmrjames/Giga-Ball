//
//  EndlessIIProgression.swift
//  Megaball
//
//  How Endless 2.0 opens simply and gets stranger.
//
//  Three things ramp with height, and they are deliberately separate because they answer
//  different questions: how much of the field is doing anything unusual, how many unusual
//  things one brick may do at once, and which unusual things are on the table at all.
//  Turning them together would make depth a single difficulty dial; keeping them apart is
//  what lets a deep field be varied rather than merely harder.
//
//  Nothing is ever locked out. Every style keeps a small weight from the first metre, so a
//  player who never passes 20m still meets Portals and Spawners - rarely, and as a surprise
//  rather than as the thing that ended the run. What depth changes is how likely each one
//  is, not whether it exists.
//
//  Pure arithmetic over a height and a shuffled order, so all of it can be reasoned about
//  and tested without a scene.
//

import Foundation

struct EndlessIIProgression {

    /// The order styles are introduced in, shuffled once per run.
    ///
    /// Shuffled, so two runs to the same height meet a different subset. That is what makes
    /// the mode teach itself: a player who only ever reaches 40m still sees something new
    /// most runs, rather than the same first three things for ever.
    let introductionOrder: [EndlessIIStyle]

    /// Metres between one style being introduced and the next.
    static let introductionSpacing = 12

    /// The weight a style carries before its turn comes.
    ///
    /// Not zero. Rare enough to be a surprise, common enough that a few hours of short runs
    /// will show somebody everything.
    static let earlyWeight = 6
    static let introducedWeight = 100

    /// How often a brick takes a style at all, as a chance in 100.
    static let openingStyleChance = 4
    static let deepStyleChance = 22
    /// How often a brick that already has one is allowed a second.
    static let openingStackChance = 3
    static let deepStackChance = 40
    /// The height by which both have reached their full value.
    static let rampMetres = 160

    static func make(shuffling styles: [EndlessIIStyle] = EndlessIIStyle.allCases)
    -> EndlessIIProgression {
        EndlessIIProgression(introductionOrder: styles.shuffled())
    }

    // MARK: - Which styles are on the table

    /// The height a style is introduced at.
    ///
    /// The first is available immediately - a run that opened with nothing unusual for
    /// twelve metres would just be Endless.
    func introductionHeight(of style: EndlessIIStyle) -> Int {
        guard let place = introductionOrder.firstIndex(of: style) else { return 0 }
        return place*EndlessIIProgression.introductionSpacing
    }

    /// How strongly a style should be drawn at this height, relative to the others.
    func weight(for style: EndlessIIStyle, at height: Int) -> Int {
        height >= introductionHeight(of: style)
            ? EndlessIIProgression.introducedWeight
            : EndlessIIProgression.earlyWeight
    }

    /// Picks a style, respecting the weights.
    ///
    /// Draws from everything every time rather than from what has been introduced, which is
    /// what keeps the early appearances possible. Returns nil only if given nothing.
    func pickStyle(from styles: [EndlessIIStyle], at height: Int,
                   roll: (Int) -> Int = { Int.random(in: 0..<$0) }) -> EndlessIIStyle? {
        guard styles.isEmpty == false else { return nil }
        let total = styles.reduce(0) { $0 + weight(for: $1, at: height) }
        guard total > 0 else { return styles.first }

        var remaining = roll(total)
        for style in styles {
            remaining -= weight(for: style, at: height)
            if remaining < 0 { return style }
        }
        return styles.last
    }

    // MARK: - How much of the field is unusual

    /// The chance in 100 that a brick takes a style.
    func styleChance(at height: Int) -> Int {
        EndlessIIProgression.ramped(from: EndlessIIProgression.openingStyleChance,
                                    to: EndlessIIProgression.deepStyleChance,
                                    at: height)
    }

    /// The chance in 100 that a brick which already has a style is allowed a second.
    ///
    /// A chance rather than a height gate, so a stack is possible from the first metre and
    /// merely unlikely. The real rate is this multiplied by the chance of the first style,
    /// so stacks stay rarer than singles at every depth without a third number to tune.
    func stackChance(at height: Int) -> Int {
        EndlessIIProgression.ramped(from: EndlessIIProgression.openingStackChance,
                                    to: EndlessIIProgression.deepStackChance,
                                    at: height)
    }

    /// Linear from the opening value to the deep one, then flat.
    ///
    /// Flat rather than ever-climbing: a run that keeps getting denser eventually becomes
    /// unplayable rather than hard, and a ceiling is what lets a deep run settle into a
    /// rhythm instead of grinding to a halt.
    static func ramped(from opening: Int, to deep: Int, at height: Int) -> Int {
        guard height > 0 else { return opening }
        guard height < rampMetres else { return deep }
        let progress = Double(height)/Double(rampMetres)
        return opening + Int((Double(deep - opening)*progress).rounded())
    }
}
