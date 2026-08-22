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

struct EndlessIIProgression: Codable, Equatable {

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

    // MARK: - What this run in particular does
    //
    // James, round 190: "Each game, what is and isn't available at the start is different so
    // each game feels very unique... The number of items available at the start should also
    // differ between games, and the timing and speed at which they are introduced should also
    // differ." The shuffled orders above already made *which* things arrive differ; these make
    // *how many* start in play, *how fast* the rest follow, and *how rare* each one is differ
    // too. All drawn once, at the start of the run, and carried in the save with it.

    /// How many of the shuffled styles are in play from the first metre.
    var openingStyles: Int = EndlessIIProgression.openingStyleRange.lowerBound

    /// How many power-ups beyond the standard ones are.
    var openingPowerUps: Int = EndlessIIProgression.openingPowerUpRange.lowerBound

    /// This run's metres between one style being introduced and the next.
    var styleSpacing: Int = EndlessIIProgression.introductionSpacing

    /// And between one power-up and the next.
    var powerUpSpacing: Int = EndlessIIProgression.powerUpIntroductionSpacing

    /// The order this run introduces its set rows in, as indices into `EndlessIISetRow.all`.
    ///
    /// James, round 190, listing what should be held back: "brick types and power ups and
    /// **brick sequences** and combinations of things".
    var setRowOrder: [Int] = []

    /// And its phases.
    var phaseOrder: [EndlessIIPhase] = []

    /// How many set rows are in play from the first metre.
    var openingSetRows: Int = EndlessIIProgression.openingSetRowRange.lowerBound

    /// How many phases are.
    var openingPhases: Int = EndlessIIProgression.openingPhaseRange.lowerBound

    /// The height this run first allows a *bad* power-up inside a power-up brick, and the
    /// height the *disastrous* ones join them. Optionals so a schedule saved before round
    /// 202 still decodes - those runs read the range midpoints, which is close to what they
    /// would have drawn.
    ///
    /// James, round 200: "the power up bricks power ups should be limited to power-ups that
    /// aren't completely disastrous, at least early on... good power ups only, then
    /// introduce bad power ups higher up, but not really bad ones, then worse ones can be
    /// added even higher up. Like everything in endless mayhem mode, there should be some
    /// randomness to which power ups are and aren't available as bricks and when."
    ///
    /// **The brick draw only.** A falling drop can be dodged; a brick's gift goes off in
    /// your hand, which is why the brick is held to a kinder standard than the sky is.
    var brickBadFromHeight: Int? = nil
    var brickDisastrousFromHeight: Int? = nil

    var badPowerUpBricksFrom: Int {
        brickBadFromHeight ?? EndlessIIProgression.midpoint(of: EndlessIIProgression.brickBadRange)
    }
    var disastrousPowerUpBricksFrom: Int {
        brickDisastrousFromHeight
            ?? EndlessIIProgression.midpoint(of: EndlessIIProgression.brickDisastrousRange)
    }

    static let brickBadRange = 50...120
    static let brickDisastrousRange = 160...280

    static func midpoint(of range: ClosedRange<Int>) -> Int {
        (range.lowerBound + range.upperBound)/2
    }

    /// Whether a power-up brick at this height may hold this power-up.
    func brickMayHold(_ index: Int, at height: Int) -> Bool {
        switch EndlessIIProgression.powerUpSeverity[index] ?? .good {
        case .good: return true
        case .mild: return true
            // Mild annoyances were always allowed - the note's "good power ups only" is
            // about the ones that turn a run, and a Fast Ball does not
        case .bad: return height >= badPowerUpBricksFrom
        case .disastrous: return height >= max(disastrousPowerUpBricksFrom,
                                               badPowerUpBricksFrom)
            // Never before the bad ones, however the two draws land
        }
    }

    /// How much a harmful power-up hurts, for the brick gate.
    enum PowerUpSeverity { case good, mild, bad, disastrous }

    /// The authored tiers, by power-up index. Anything absent is `.good`.
    ///
    /// **A starting guess, and tuning it is one edit here** - the same promise §6.4 makes
    /// about the weights. Mild is a nuisance; bad turns the field or the paddle against
    /// you for a while; disastrous is the handful that can end a run on their own.
    static let powerUpSeverity: [Int: PowerUpSeverity] = [
        3: .mild,   // Fast Ball
        5: .mild,   // Shrink Paddle
        9: .mild,   // -100 Points
        11: .mild,  // -1000 Points
        13: .mild,  // Reset Multiplier
        16: .mild,  // Hide Bricks
        23: .mild,  // Quicksand
        27: .mild,  // Shrink Ball
        36: .disastrous, // Inert Paddle - a paddle that will not move is the run on a timer
        37: .bad,   // Flipped Angle
        38: .disastrous, // Reversed Controls - muscle memory turned against you
        44: .bad,   // Infill
        45: .bad,   // Descent
        48: .mild,  // Lock - the timers freeze, which mostly just delays
        51: .bad,   // Randomised Bounce
        54: .bad,   // Drift Right
        55: .bad,   // Convex Paddle
        56: .bad,   // Concave Paddle
        57: .bad,   // Wavy Paddle
        58: .disastrous, // Jagged Paddle - "stops being something you can read at all"
        59: .disastrous, // Split Paddle - holes in the floor
        60: .bad,   // Mirror Paddle
        63: .bad,   // Drift Left
        64: .bad,   // Wedge Left Paddle
        65: .bad,   // Wedge Right Paddle
    ]

    /// This run's multiplier on each power-up's authored weight, one per index.
    ///
    /// **Bounded, and that is the whole design of it.** James: "Rarity for items can be
    /// tweaked again so it's slightly different for each game. Although a generally rare
    /// power up shouldn't all of a sudden become the most common one." The range is narrow
    /// enough that the tiers cannot cross - the luckiest Rare stays rarer than the unluckiest
    /// Common - so a run feels differently weighted without the mode changing what its
    /// power-ups mean. There is a test on exactly that.
    var rarityTweak: [Double] = []

    /// How far into the gap after an introduction this run's density steps land, as a share
    /// of the gap. Rolled per run, so no two runs thicken on the same metres.
    var densityLagShare: Double = EndlessIIProgression.densityLagRange.lowerBound

    /// How big each density step is, relative to the others. Normalised when used, so these
    /// change where a run does its thickening without changing where it ends up.
    var densityStepTweak: [Double] = []

    /// How many styles start in play. Two is a run that opens nearly plain; five is one that
    /// opens busy and has less left to introduce.
    static let openingStyleRange = 2...5

    /// How many power-ups start in play, beyond the ones that always are.
    static let openingPowerUpRange = 4...10

    /// The spread of this run's style spacing, in metres, around the standard 35.
    static let styleSpacingRange = 24...50

    /// And of its power-up spacing, around the standard 14.
    static let powerUpSpacingRange = 9...20

    /// The most and least a run may weight a power-up by.
    static let rarityTweakRange = 0.78...1.30

    /// Where in the gap a density step may land. Never at the introduction itself - the new
    /// thing is meant to be seen before the field changes around it - and never so late that
    /// it collides with the next one.
    static let densityLagRange = 0.35...0.7

    /// How much one step may differ from another.
    static let densityStepRange = 0.6...1.5

    static let openingSetRowRange = 2...5
    static let openingPhaseRange = 3...6

    /// Metres between one set row or phase being introduced and the next.
    static let sequenceSpacing = 30

    // MARK: - Introductions quicken with depth
    //
    // James: "Density should generally rise with height, but new item introduction should
    // also rise with height." A constant spacing means the *rate* of new things is flat for
    // the whole run - one every 35m at 40m up and one every 35m at 600m up - which is the
    // opposite of rising. Each successive gap is a little shorter than the one before it, so
    // the deeper a run goes the more often something new arrives.

    /// What share of the previous gap each successive introduction takes.
    static let introductionQuickening = 0.93

    /// The shortest a gap may shrink to, as a share of the run's own spacing. Without a floor
    /// a long run would end up introducing something every few metres, which is a flood
    /// rather than a rise.
    static let shortestGapShare = 0.35

    /// How far above the opening set the `steps`-th introduction sits.
    ///
    /// Pure arithmetic, so the quickening can be reasoned about rather than sampled: strictly
    /// increasing in `steps`, and every gap between one step and the next is no larger than
    /// the gap before it and no smaller than the floor.
    static func introductionDistance(steps: Int, spacing: Int) -> Int {
        guard steps > 0, spacing > 0 else { return 0 }
        let smallest = Double(spacing)*shortestGapShare
        var total = 0.0
        var gap = Double(spacing)
        for _ in 0..<steps {
            total += gap
            gap = max(smallest, gap*introductionQuickening)
        }
        return max(1, Int(total.rounded()))
    }

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
        EndlessIIProgression(
            introductionOrder: styles.shuffled(),
            powerUpOrder: Array(0..<powerUps).shuffled(),
            openingStyles: Int.random(in: openingStyleRange),
            openingPowerUps: Int.random(in: openingPowerUpRange),
            styleSpacing: Int.random(in: styleSpacingRange),
            powerUpSpacing: Int.random(in: powerUpSpacingRange),
            setRowOrder: Array(0..<EndlessIISetRow.all.count).shuffled(),
            phaseOrder: EndlessIIPhase.allCases.shuffled(),
            openingSetRows: Int.random(in: openingSetRowRange),
            openingPhases: Int.random(in: openingPhaseRange),
            brickBadFromHeight: Int.random(in: brickBadRange),
            brickDisastrousFromHeight: Int.random(in: brickDisastrousRange),
            rarityTweak: (0..<powerUps).map { _ in Double.random(in: rarityTweakRange) },
            densityLagShare: Double.random(in: densityLagRange),
            densityStepTweak: (0..<styles.count).map { _ in
                Double.random(in: densityStepRange)
            })
    }

    /// Metres between one power-up being introduced and the next.
    ///
    /// Tighter than the styles' spacing because there are three times as many of them, and a
    /// run that had met only a handful by four hundred metres would feel thin rather than
    /// gradual.
    static let powerUpIntroductionSpacing = 14

    /// The height a power-up is introduced at.
    ///
    /// The first `openingPowerUps` of the shuffled order are in play from the start, and the
    /// rest follow at this run's own spacing. A power-up not in the order at all is treated as
    /// available immediately, which is the safe answer for one added since the save was
    /// written - the opposite of introduced.
    ///
    /// **The standard power-ups are never held back** (James, round 190: "The standard brick
    /// types and power ups are always available"). Those are the ones the original game has,
    /// everything below `firstEndlessIIPowerUp` - the vocabulary a player already knows, and
    /// the floor a run is playable on before it has been taught anything.
    func powerUpIntroductionHeight(of index: Int) -> Int {
        guard index >= LevelPackSetup.firstEndlessIIPowerUp else { return 0 }
        guard let place = powerUpOrder.firstIndex(of: index) else { return 0 }
        guard place >= openingPowerUps else { return 0 }
        return EndlessIIProgression.introductionDistance(steps: place - openingPowerUps + 1,
                                                         spacing: powerUpSpacing)
    }

    /// What a power-up's authored weight should be scaled to at this height.
    ///
    /// Rarity is preserved rather than replaced: being introduced does not make something
    /// common, it restores whatever weight it was given in the first place. Before that it
    /// keeps a fraction of it, so an early run can still turn one up as a surprise - the same
    /// rule the styles follow, for the same reason.
    func powerUpWeightScale(for index: Int, at height: Int) -> Double {
        let introduced = height >= powerUpIntroductionHeight(of: index)
        let base = introduced ? 1 : EndlessIIProgression.powerUpEarlyScale
        return base*tweak(for: index)
    }

    /// This run's weighting for one power-up. One when the run predates the tweak, which is
    /// what every save written before round 192 restores as.
    func tweak(for index: Int) -> Double {
        rarityTweak.indices.contains(index) ? rarityTweak[index] : 1
    }

    static let powerUpEarlyScale = 0.15

    // MARK: - Which styles are on the table

    /// The height a style is introduced at.
    ///
    /// The first `openingStyles` are available immediately - a run that opened with nothing
    /// unusual for twelve metres would just be Endless - and how many that is varies per run,
    /// which is what makes two runs to the same height feel differently stocked.
    func introductionHeight(of style: EndlessIIStyle) -> Int {
        guard let place = introductionOrder.firstIndex(of: style) else { return 0 }
        guard place >= openingStyles else { return 0 }
        return EndlessIIProgression.introductionDistance(steps: place - openingStyles + 1,
                                                         spacing: styleSpacing)
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
/// Codable because the run's phase order rides in the save with the rest of its schedule.
enum EndlessIIPhase: String, CaseIterable, Codable {
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

    /// **Density rises in steps, and each step follows a new thing rather than accompanying
    /// it** (James, round 212: "Density should increase with height in general, but new
    /// things should come first. So new things added -> increase density -> new things added
    /// -> increase density, and so on. Of course there should be randomised aspects to how
    /// dense, when it is increased, how it overlaps and interweaves with new items being
    /// added").
    ///
    /// It was a straight line from the opening to the cap, keyed to height alone. That climbs
    /// *through* every introduction, so the metre a new brick first appears is also a metre
    /// the field is fractionally fuller than the one before - the new thing arrives into a
    /// field that is already changing, which is the opposite of showing it to the player.
    ///
    /// Now the style schedule is the spine. Each introduction opens a gap; the density step
    /// lands part-way along that gap, so the new style is seen in the field it arrived in and
    /// the field thickens once the player has met it. The steps carry the whole ramp between
    /// them, so a run that introduces things quickly also thickens quickly - which is the
    /// coupling that was missing, and the reason this is keyed to the schedule rather than to
    /// a second ramp that happens to look similar.
    ///
    /// Three things are rolled per run: where in each gap the step lands (`densityLagShare`),
    /// how big each individual step is (`densityStepTweak`), and - already - how far apart the
    /// introductions themselves are. So two runs at the same height are rarely as full as each
    /// other, and neither is ever fuller than `cappedDensity` allows.
    func density(at height: Int, phase: EndlessIIPhase = .standard) -> Double {
        let base: Double
        if height <= 0 {
            base = EndlessIIProgression.firstScreenDensity
        } else if height >= EndlessIIProgression.densityCapMetres {
            base = EndlessIIProgression.cappedDensity
        } else {
            let opening = EndlessIIProgression.openingDensity
            let reach = EndlessIIProgression.cappedDensity - opening
            base = opening + reach*densityProgress(at: height)
        }
        return min(0.6, base*phase.densityFactor)
        // Capped again after the phase multiplies it, so a dense phase deep in a run cannot
        // put up a solid wall
    }

    /// How far along the climb from opening to cap this height stands, as steps rather than a
    /// slope.
    ///
    /// Each landed step contributes its own share, and the shares are the per-run tweaks
    /// normalised - so the tweaks change *where the thickening happens*, never where it ends
    /// up. A run whose early steps are large is one that fills fast and then settles; one
    /// whose late steps are large stays open and then closes in. Both arrive at the cap.
    func densityProgress(at height: Int) -> Double {
        let steps = densityStepHeights()
        guard steps.isEmpty == false else {
            return Double(height)/Double(EndlessIIProgression.densityCapMetres)
        }
        let landed = steps.prefix { $0 <= height }.count
        guard landed > 0 else { return 0 }

        let weights = (0..<steps.count).map { densityStepWeight($0) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return Double(landed)/Double(steps.count) }
        return min(1, weights.prefix(landed).reduce(0, +)/total)
    }

    /// The height each density step lands at: part-way along the gap after an introduction.
    func densityStepHeights() -> [Int] {
        let cap = EndlessIIProgression.densityCapMetres
        var heights: [Int] = []
        for place in 0..<introductionOrder.count {
            let style = introductionOrder[place]
            let arrives = introductionHeight(of: style)
            guard arrives > 0, arrives < cap else { continue }
            let next = place + 1 < introductionOrder.count
                ? introductionHeight(of: introductionOrder[place + 1])
                : cap
            let gap = max(1, next - arrives)
            let step = arrives + Int((Double(gap)*densityLagShare).rounded())
            // **After the introduction, never with it.** A share of the gap rather than a
            // fixed number of metres, so a run with tight spacing does not have its steps
            // land past the next new thing
            heights.append(min(cap, max(arrives + 1, step)))
        }
        return heights.sorted()
    }

    private func densityStepWeight(_ index: Int) -> Double {
        densityStepTweak.indices.contains(index) ? densityStepTweak[index] : 1
    }

    /// The most rows in a row that may arrive with nothing in them.
    ///
    /// Height is gained by clearing the bottom row, and a row with nothing in it is cleared the
    /// moment it arrives - so a run of empty rows is height for free. That sounds generous and
    /// is the opposite: the field rushes past, the player is deep before the mode has shown
    /// them anything, and the density that was meant to arrive gradually arrives all at once
    /// because it is keyed to a height they reached in seconds.
    ///
    /// Two is enough to keep the opening feeling open, and James confirmed the taste in
    /// round 99: "2 rows with no bricks is fine, even 3 or 4 occasionally." Round 98
    /// briefly tightened this to one, misreading his gap report - the voids he was seeing
    /// were far larger than anything generation produces, which points at the *cleared*
    /// field with Descent suspending the catch-up cadence, not at this rule at all.
    static let mostEmptyRowsInARow = 2

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

    /// The height a set row joins this run, its authored gate included.
    ///
    /// **The authored minimum is a floor the schedule can only ever push down from, never
    /// lift.** A row gated at 150m is gated there because of what it does to a field, and a
    /// lucky shuffle must not put it in front of somebody at 20m. What the schedule decides is
    /// how much *later* than that it arrives, and in what order relative to the others - which
    /// is what makes two runs to the same height meet different shapes.
    func setRowAvailableHeight(of index: Int) -> Int {
        let authored = EndlessIISetRow.all.indices.contains(index)
            ? EndlessIISetRow.all[index].minimumHeight : 0
        guard let place = setRowOrder.firstIndex(of: index) else { return authored }
        guard place >= openingSetRows else { return authored }
        return max(authored,
                   EndlessIIProgression.introductionDistance(
                       steps: place - openingSetRows + 1,
                       spacing: EndlessIIProgression.sequenceSpacing))
    }

    /// The set rows this run may draw at this height.
    func setRows(at height: Int) -> [EndlessIISetRow] {
        EndlessIISetRow.all.indices
            .filter { height >= setRowAvailableHeight(of: $0) }
            .map { EndlessIISetRow.all[$0] }
    }

    /// The height a phase joins this run, its authored gate included. Same rule as the rows.
    ///
    /// **Standard is never held back**, for the same reason the standard power-ups are not: it
    /// is the baseline mix rather than a set piece, and a run whose opening shuffle happened
    /// to hold back everything gated at zero would have had *no* phase available at all - the
    /// generator would have fallen back to Standard on every draw anyway, silently, which is
    /// the "never offered looks exactly like very rare" trap the other way round. A test
    /// caught it before it shipped.
    func phaseAvailableHeight(of phase: EndlessIIPhase) -> Int {
        guard phase != .standard else { return 0 }
        guard let place = phaseOrder.firstIndex(of: phase) else { return phase.minimumHeight }
        guard place >= openingPhases else { return phase.minimumHeight }
        return max(phase.minimumHeight,
                   EndlessIIProgression.introductionDistance(
                       steps: place - openingPhases + 1,
                       spacing: EndlessIIProgression.sequenceSpacing))
    }

    /// Draws a phase that is allowed at this height.
    func pickPhase(at height: Int,
                   roll: (Int) -> Int = { Int.random(in: 0..<$0) }) -> EndlessIIPhase {
        let allowed = EndlessIIPhase.allCases.filter { height >= phaseAvailableHeight(of: $0) }
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
