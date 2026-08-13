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

    /// The order power-ups are introduced in, shuffled once per run alongside the styles.
    ///
    /// Indices into the probability array rather than a named type, because that array is
    /// what the drop actually reads and a second list of names would only have to be kept in
    /// step with it.
    var powerUpOrder: [Int] = []

    /// Metres between one style being introduced and the next.
    ///
    /// Spread so the last one arrives around 280m, which leaves most of a long run for the
    /// second half of the ramp - the part where what is already known gets more common and
    /// starts combining, rather than where new things keep appearing.
    static let introductionSpacing = 35

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
    ///
    /// A thousand metres, because that is roughly where the top of the original Endless
    /// leaderboard sits and plenty of people pass 100m. A ramp that finished at 160 would
    /// mean the mode stopped developing in the first minute of a good run and the remaining
    /// nine hundred metres were the same field over and over.
    ///
    /// Reaching that far is only sane because what ramps is not difficulty. Density moves a
    /// little; what really changes is how many different things are in play, how often they
    /// combine, and how likely the rare ones are - so a deep field is stranger than a
    /// shallow one rather than simply fuller.
    static let rampMetres = 1000

    /// How front-loaded the ramp is. Below 1 pulls the curve up early; 1 would be a straight
    /// line. At 0.4 a hundred metres is about a third of the way to the deep figures rather
    /// than a tenth.
    static let rampEasing = 0.4

    static func make(shuffling styles: [EndlessIIStyle] = EndlessIIStyle.allCases,
                     powerUps: Int = LevelPackSetup().powerUpNameArray.count) -> EndlessIIProgression {
        // Every power-up in the table, including Endless 2.0's own, derived from the array
        // that names them rather than counted by hand - the hand-count came up short the
        // first time a batch landed, which is exactly what §8.6 says literals do. A new
        // power-up missing from this shuffle is introduced at 0m, the opposite of introduced
        EndlessIIProgression(introductionOrder: styles.shuffled(),
                             powerUpOrder: Array(0..<powerUps).shuffled())
    }

    /// Metres between one power-up being introduced and the next.
    ///
    /// Tighter than the styles' spacing because there are three times as many of them, and a
    /// run that had met only a handful by four hundred metres would feel thin rather than
    /// gradual.
    static let powerUpIntroductionSpacing = 14

    /// The height a power-up is introduced at.
    func powerUpIntroductionHeight(of index: Int) -> Int {
        guard let place = powerUpOrder.firstIndex(of: index) else { return 0 }
        return place*EndlessIIProgression.powerUpIntroductionSpacing
    }

    /// What a power-up's authored weight should be scaled to at this height.
    ///
    /// Rarity is preserved rather than replaced: being introduced does not make something
    /// common, it restores whatever weight it was given in the first place. Before that it
    /// keeps a fraction of it, so an early run can still turn one up as a surprise - the same
    /// rule the styles follow, for the same reason.
    func powerUpWeightScale(for index: Int, at height: Int) -> Double {
        height >= powerUpIntroductionHeight(of: index)
            ? 1
            : EndlessIIProgression.powerUpEarlyScale
    }

    static let powerUpEarlyScale = 0.15

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

    /// How often an ordinary brick becomes a set of four Tiny ones.
    ///
    /// The one size that changes how a field is *played* rather than how it looks: four
    /// quarter-cell bricks in a cell are four separate shots, and a run that meets them in its
    /// first twenty metres meets the hardest thing in the mode before it has met the rest.
    /// So this is held near zero at the start and reaches its full rate deep, where a player
    /// who has got that far is asking for something to do.
    ///
    /// It also does not begin at all until a run is properly under way. The opening is a plain
    /// field on purpose (§12.1), and Tiny is the least plain thing in it.
    func tinyChance(at height: Int) -> Int {
        guard height >= EndlessIIProgression.tinyFirstMetres else { return 0 }
        return EndlessIIProgression.ramped(from: EndlessIIProgression.openingTinyChance,
                                           to: EndlessIIProgression.deepTinyChance,
                                           at: height)
    }

    /// Where Tiny bricks start being offered at all.
    static let tinyFirstMetres = 40
    /// One brick in a hundred at the start, against one in twenty-five deep.
    static let openingTinyChance = 1
    static let deepTinyChance = 4

    // MARK: - How much of the field is unusual

    /// The chance in 100 that a brick takes a style.
    func styleChance(at height: Int) -> Int {
        guard height > 0 else { return 0 }
        // Nothing unusual on the first screen at all. The moment the height moves, styles
        // start arriving - but a player's first look at Endless 2.0 is a plain field
        return EndlessIIProgression.ramped(from: EndlessIIProgression.openingStyleChance,
                                    to: EndlessIIProgression.deepStyleChance,
                                    at: height)
    }

    /// The chance in 100 that a brick which already has a style is allowed a second.
    ///
    /// A chance rather than a height gate, so a stack is possible from the first metre and
    /// merely unlikely. The real rate is this multiplied by the chance of the first style,
    /// so stacks stay rarer than singles at every depth without a third number to tune.
    func stackChance(at height: Int) -> Int {
        guard height > 0 else { return 0 }
        // Nothing unusual on the first screen, and a stack is the most unusual thing there
        // is - leaving this at its opening value while the first roll was zero was an
        // inconsistency rather than a shortcut
        return EndlessIIProgression.ramped(from: EndlessIIProgression.openingStackChance,
                                    to: EndlessIIProgression.deepStackChance,
                                    at: height)
    }

    /// Linear from the opening value to the deep one, then flat.
    ///
    /// Flat only once the far end is reached, and the far end is a long way out. There has
    /// to be a ceiling somewhere - a field that keeps getting denser eventually becomes
    /// unplayable rather than hard - but it belongs past where almost every run ends, not
    /// inside the first minute of a good one.
    static func ramped(from opening: Int, to deep: Int, at height: Int) -> Int {
        guard height > 0 else { return opening }
        guard height < rampMetres else { return deep }

        // Eased, not linear. A thousand metres is the right place for the *deep* figures to
        // land, but a straight line puts a hundred metres a tenth of the way there - and most
        // players do not often pass a hundred metres. A run that is still nine parts plain
        // white bricks by then has shown them almost nothing of the mode, which is the one
        // thing §2 says it must not do: rarity must not mean deep.
        //
        // The curve is steep early and flattens, so most of the variety arrives in the first
        // couple of hundred metres and the rest of the climb is the rare things getting
        // likelier. The endpoints are untouched: the opening is as gentle as it was and a deep
        // field is exactly as strange as it was.
        let progress = pow(Double(height)/Double(rampMetres), rampEasing)
        return opening + Int((Double(deep - opening)*progress).rounded())
    }
}

// MARK: - What the field is made of

/// A stretch of field with a character of its own.
///
/// Phases are the seasoning, not the meal: short runs of something particular punctuating
/// ordinary generated field. They exist so density ebbs and flows rather than sitting on
/// whatever the ramp says, because a field that is always exactly as full as its height
/// dictates reads as a machine.
enum EndlessIIPhase: String, CaseIterable {
    case standard, quiet, swarm, drift, flicker
    case cascade, minefield, fortress, gauntlet, carousel
    /// One kind of brick and nothing else, for as long as it lasts.
    case monoculture
    /// Every brick is the same size, and it is not the usual one.
    case giants, miniatures
    /// Every brick wears the same pair of styles.
    case motif

    /// How much this phase multiplies the height's density by.
    var densityFactor: Double {
        switch self {
        case .quiet: return 0.45
        case .drift, .flicker, .carousel: return 0.8
        case .swarm: return 1.15
        case .fortress, .minefield: return 1.25
        case .standard, .cascade, .gauntlet: return 1.0
        case .monoculture, .motif: return 0.9
        case .giants: return 0.7
        case .miniatures: return 1.3
        }
    }

    /// Whether every brick in this phase should be the same, rather than drawn afresh each
    /// time.
    ///
    /// A field where everything is one thing is a different problem from a field where
    /// everything is different, and it is a problem the player can actually plan against -
    /// which is what makes it a relief after a mixed stretch rather than another kind of
    /// noise. It also shows off a combination properly: one spinning Multi-hit brick is a
    /// curiosity, a screen of them is a puzzle.
    var isUniform: Bool {
        switch self {
        case .monoculture, .giants, .miniatures, .motif: return true
        default: return false
        }
    }

    /// The styles this phase leans on, if any. Empty means the ordinary mix.
    var favours: [EndlessIIStyle] {
        switch self {
        case .drift: return [.moving]
        case .flicker: return [.flashing]
        case .cascade: return [.gravity]
        case .minefield: return [.exploding]
        case .gauntlet: return [.directional]
        case .carousel: return [.spinning, .rounded]
        case .standard, .quiet, .swarm, .fortress: return []
        case .monoculture, .giants, .miniatures, .motif: return []
        }
    }

    /// How likely this phase is to be drawn. Quiet is the most likely single outcome, so
    /// breathers arrive often without ever being scheduled.
    var weight: Int {
        switch self {
        case .quiet: return 26
        case .standard: return 22
        // The uniform ones are the rarest. They are the strongest flavour here, and a run
        // that kept serving them would be a run of set pieces rather than a field
        case .monoculture, .giants, .miniatures, .motif: return 4
        default: return 8
        }
    }

    /// The height below which this phase does not appear, keeping the opening plain.
    var minimumHeight: Int {
        switch self {
        case .standard, .quiet: return 0
        case .swarm, .drift, .flicker: return 40
        case .cascade, .minefield: return 120
        case .fortress, .gauntlet, .carousel: return 250
        case .monoculture, .miniatures: return 150
        case .giants: return 200
        // A motif is two styles at once, so it waits until stacking is a thing a player has
        // met on ordinary bricks first
        case .motif: return 350
        }
    }

    /// How long a phase lasts, in metres.
    static let shortest = 5
    static let longest = 25
}

extension EndlessIIProgression {

    // MARK: - Density

    /// How full the field should be at this height, as a fraction of its cells.
    ///
    /// The opening is nearly empty on purpose. A first row that already has several kinds of
    /// brick in it gives a player nothing to learn from - everything arrives at once and
    /// none of it is legible. Starting near-empty means the first unusual brick somebody
    /// sees is the only unusual thing on screen.
    ///
    /// It climbs far more slowly than the style ramp and stops climbing much earlier: past
    /// the cap what keeps changing is *what* the bricks are, not how many. A field that kept
    /// filling would end as a wall.
    static let openingDensity = 0.07
    /// The very first screen, before a run has moved at all.
    ///
    /// Thinner still than the opening. It is the only screen a player sees before deciding
    /// what this mode is, and it has to look like an invitation rather than a wall - a dozen
    /// bricks with space between them, all of them ordinary.
    static let firstScreenDensity = 0.035
    static let cappedDensity = 0.42
    static let densityCapMetres = 500

    func density(at height: Int, phase: EndlessIIPhase = .standard) -> Double {
        let base: Double
        if height <= 0 {
            base = EndlessIIProgression.firstScreenDensity
        } else if height >= EndlessIIProgression.densityCapMetres {
            base = EndlessIIProgression.cappedDensity
        } else {
            let progress = Double(height)/Double(EndlessIIProgression.densityCapMetres)
            base = EndlessIIProgression.openingDensity
                + (EndlessIIProgression.cappedDensity - EndlessIIProgression.openingDensity)*progress
        }
        return min(0.6, base*phase.densityFactor)
        // Capped again after the phase multiplies it, so a dense phase deep in a run cannot
        // put up a solid wall
    }

    /// The most rows in a row that may arrive with nothing in them.
    ///
    /// Height is gained by clearing the bottom row, and a row with nothing in it is cleared the
    /// moment it arrives - so a run of empty rows is height for free. That sounds generous and
    /// is the opposite: the field rushes past, the player is deep before the mode has shown
    /// them anything, and the density that was meant to arrive gradually arrives all at once
    /// because it is keyed to a height they reached in seconds.
    ///
    /// One. Two was the first answer, and the play test read two brickless rows at field
    /// speed as a void rather than a breather (round 98: "big gaps actually make the game
    /// harder") - one row of air keeps the opening feeling open, and the row after it always
    /// has something to play.
    static let mostEmptyRowsInARow = 1

    // MARK: - Which brick

    /// How strongly each behaviour should be drawn at this height.
    ///
    /// Standard starts as almost the only thing there is and becomes one option among many -
    /// by a thousand metres a plain white brick is a minority of what arrives. That is the
    /// other half of not going stale: if the field only ever got fuller, a deep run would be
    /// the opening with more of it.
    func behaviourWeights(at height: Int) -> [(EndlessIIBehaviour, Int)] {
        guard height > 0 else { return [(.standard, 100)] }
        // Ordinary bricks and nothing else to begin with, for the same reason
        let toward = { (opening: Int, deep: Int) in
            EndlessIIProgression.ramped(from: opening, to: deep, at: height)
        }
        return [
            (.standard, toward(100, 30)),
            (.multiHit, toward(14, 26)),
            (.indestructibleOnce, toward(3, 16)),
            (.indestructibleAlways, toward(2, 14)),
            (.invisible, toward(3, 14)),
        ]
        // The opening figures are what a player meets in their first minute, and they were set
        // as though the ramp would carry them - one in a hundred for three of the five meant
        // the first two hundred metres were very nearly all Standard. Raised so that even the
        // opening mix has something in it besides white bricks, while the deep mix - which is
        // what the whole climb is for - is unchanged
    }

    func pickBehaviour(at height: Int,
                       roll: (Int) -> Int = { Int.random(in: 0..<$0) }) -> EndlessIIBehaviour {
        let weights = behaviourWeights(at: height)
        let total = weights.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return .standard }
        var remaining = roll(total)
        for (behaviour, weight) in weights {
            remaining -= weight
            if remaining < 0 { return behaviour }
        }
        return .standard
    }

    // MARK: - Phases

    /// Draws a phase that is allowed at this height.
    func pickPhase(at height: Int,
                   roll: (Int) -> Int = { Int.random(in: 0..<$0) }) -> EndlessIIPhase {
        let allowed = EndlessIIPhase.allCases.filter { height >= $0.minimumHeight }
        let total = allowed.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return .standard }
        var remaining = roll(total)
        for phase in allowed {
            remaining -= phase.weight
            if remaining < 0 { return phase }
        }
        return .standard
    }

    // MARK: - How fast things move

    /// How quickly the moving parts move, as a multiple of their base rate.
    ///
    /// A spinning brick at full speed in the first ten metres is just noise. Starting slow
    /// gives a player time to read what the brick is doing before it starts doing it
    /// quickly, and speeding up is a way for a deep field to feel different without another
    /// brick in it.
    static let openingMotionRate = 0.55
    static let deepMotionRate = 1.6

    func motionRate(at height: Int) -> Double {
        let scaled = EndlessIIProgression.ramped(
            from: Int(EndlessIIProgression.openingMotionRate*100),
            to: Int(EndlessIIProgression.deepMotionRate*100), at: height)
        return Double(scaled)/100
    }
}
