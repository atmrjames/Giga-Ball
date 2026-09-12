//
//  DailyChallenge.swift
//  Megaball
//
//  One short game a day, the same for everyone (DAILY-CHALLENGE-SPECIFICATION.md).
//
//  Everything in this file is pure: the UTC date goes in, a frozen challenge comes out, and
//  every device in the world computes the same one - that is the whole trick, and it is why
//  nothing here may touch Swift's own randomness. `SystemRandomNumberGenerator` is not
//  stable across devices or OS versions, so the generator runs on its own SplitMix64, and
//  the tests pin exact outputs for known dates as the contract that everyone agrees.
//
//  The pools are append-only with activation dates (§2.1): nothing is ever removed or
//  reweighted retroactively, so any past date replays identically for ever. A new twist is
//  a new row with a date after its release - never a change to an old one.
//

import Foundation

// MARK: - The seeded generator

/// SplitMix64: small, fast, well-studied, and - the only property that matters here -
/// exactly the same on every device for ever.
struct DailySeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// A roll in `0..<bound`, from the top bits, which SplitMix64 distributes well.
    mutating func roll(_ bound: Int) -> Int {
        guard bound > 1 else { return 0 }
        return Int(next() % UInt64(bound))
        // Modulo bias is real and irrelevant at these bounds (a few hundred at most
        // against 2^64) - and unlike rejection sampling it consumes exactly one draw,
        // which keeps the stream layout stable for ever, which matters far more here
    }
}

// MARK: - The day

enum DailyDay {

    /// The UTC calendar, which is the only one the daily knows.
    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    /// The date key that names a challenge: "2026-08-09", in UTC, for everyone.
    static func key(for date: Date) -> String {
        let parts = utcCalendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    /// The seed for a day: yyyymmdd as a number, so the mapping is inspectable by eye.
    static func seed(forKey key: String) -> UInt64 {
        UInt64(key.replacingOccurrences(of: "-", with: "")) ?? 0
    }

    /// When this day's scoring window closes: the next UTC midnight.
    static func windowEnd(for date: Date) -> Date {
        let start = utcCalendar.startOfDay(for: date)
        return utcCalendar.date(byAdding: .day, value: 1, to: start)!
    }

    /// The key turned back into the UTC midnight it names. Nil for a malformed key,
    /// which no stored key ever is - they are all made by `key(for:)`.
    static func date(forKey key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return utcCalendar.date(from: DateComponents(year: parts[0], month: parts[1],
                                                     day: parts[2]))
    }
}

// MARK: - Twists

/// A named, self-describing rule change (§4). The raw value is the persistence and
/// pool-identity name - append-only, never renamed.
enum DailyTwist: String, CaseIterable, Codable {
    case oneLife, loaded, suddenDeath, spareBalls
    case noPowerUps, noGoodNews, noBadNews, powerShower, drought
    case fogOfWar
    case mirrored, upsideDown, brickSwap
    case noPausing
    case timeTrial
    case mayhemBricks
    case monochromatic, dailyTheme
    case alwaysOn
    case landslide
    /// Endless Mayhem with nothing held back: every element in play from the first metre,
    /// each still as rare as it was written to be.
    case fullDeck
    /// The same, with rarity levelled: everything in play, and everything equally likely.
    case levelPegging

    /// §4.2's categories: a day draws at most one twist per category, which is what makes
    /// every combination the generator can produce legal by construction.
    enum Category: CaseIterable {
        case economy, lives, dress, layout, nerve, tempo, look, standing, field
        /// What the run has been introduced to, and how rare it is - which is a category
        /// because its two twists are the same dial at two settings and a day that drew both
        /// would be one twist arguing with itself.
        case disclosure

        /// The date this category may first be *drawn* (§2.1), and the reason it exists.
        ///
        /// A twist's own `activationKey` keeps a new twist out of an old day's pool, which
        /// leaves the roll that picks within the pool untouched. A new **category** is not
        /// covered by that: `rawChallenge` draws a category by index out of this list, so a
        /// fourth entry turns every past day's `roll(3)` into a `roll(4)` and rewrites what
        /// dates already played drew. The same trick one level up closes it - an old day
        /// sees exactly the three categories it saw, in the same order, and rolls the same
        /// number.
        var activationKey: String {
            switch self {
            case .economy, .lives, .dress: return "2026-08-01"
            case .layout: return "2026-09-01"
            case .nerve: return "2026-10-01"
            case .tempo: return "2026-10-01"
            case .look, .standing, .field: return "2026-11-01"
            case .disclosure: return "2026-12-01"
            }
            // **Three categories of one, and that is the design saying what it means.** A
            // category is how a day refuses to draw two of a kind, and each of these three
            // refuses only itself: James's matrix allows Always On, Landslide and the look
            // twists beside everything except Vanilla, which is not a twist at all. Folding
            // them into an existing category would forbid pairings he has allowed, and that
            // is a worse lie than a short list
        }
    }

    var category: Category {
        switch self {
        case .oneLife, .loaded, .suddenDeath, .spareBalls: return .lives
        case .noPowerUps, .noGoodNews, .noBadNews, .powerShower, .drought: return .economy
        case .fogOfWar: return .dress
        case .mirrored, .upsideDown, .brickSwap: return .layout
        case .noPausing: return .nerve
        case .timeTrial: return .tempo
        case .mayhemBricks: return .dress
        case .monochromatic, .dailyTheme: return .look
        case .alwaysOn: return .standing
        case .landslide: return .field
        case .fullDeck, .levelPegging: return .disclosure
        }
        // **The look category exists for these two** (James, round 229: "ok, they are not
        // possible together then"). Both decide which theme is on screen, and his matrix
        // marked the pair as allowed, which cannot be right - one says Classic only and the
        // other picks at random. A category is how this design says "at most one of these",
        // and they could not join `dress`, because Fog of War lives there and a fogged day
        // wearing a drawn theme is a pairing he does allow
    }

    /// What the day calls itself, on the card, the pause screen and the reference page.
    ///
    /// **These are the twist workbook's names** (James, round 237: "update the in game twist
    /// names and descriptions from the information in the twist details reference"). Three had
    /// drifted from it - Extra Balls, Extra Mayhem and No Breaks were built before the
    /// document existed and are Extra Balls, Extra Mayhem and No Breaks in it. The enum cases
    /// keep their old spellings on purpose: a case name is a key in the save and in
    /// `retirementKey`, and renaming one would change which day is which for every day already
    /// played.
    var displayName: String {
        switch self {
        case .oneLife: return "One Life"
        case .loaded: return "Loaded"
        case .suddenDeath: return "Sudden Death"
        case .spareBalls: return "Extra Balls"
        case .noPowerUps: return "No Power-Ups"
        case .noGoodNews: return "No Good News"
        case .noBadNews: return "No Bad News"
        case .powerShower: return "Power Shower"
        case .drought: return "Drought"
        case .fogOfWar: return "Fog of War"
        case .mirrored: return "Mirrored"
        case .upsideDown: return "Upside Down"
        case .brickSwap: return "Brick Swap"
        case .noPausing: return "No Breaks"
        case .timeTrial: return "Time Trial"
        case .mayhemBricks: return "Extra Mayhem"
        case .monochromatic: return "Monochromatic"
        case .dailyTheme: return "Theme"
        case .alwaysOn: return "Always On"
        case .landslide: return "Landslide"
        case .fullDeck: return "Full Deck"
        case .levelPegging: return "Level Pegging"
        }
    }

    /// One line each, in James's own words.
    ///
    /// **Taken from the workbook in round 310** (James: "for the twist descriptions, use the
    /// descriptions I provided in the details document"). The lines these replace were written
    /// here and were longer and chattier - "power-ups everywhere", "the level is the wrong way
    /// round" - which read well in isolation and badly in a list of three on a card.
    ///
    /// Four keep the wording written here, and deliberately: **Loaded** and **Sudden Death**
    /// are retired and have no row in the sheet, and **Full Deck** and **Level Pegging** have a
    /// row with the description column empty.
    var blurb: String {
        switch self {
        case .oneLife: return "Only one ball is provided"
        case .loaded: return "Five lives. Spend them well."
        case .suddenDeath: return "Any ball lost ends the run - every ball, every mode."
        case .spareBalls: return "Two extra balls are provided"
        case .noPowerUps: return "Just the paddle, the ball and the bricks"
        case .noGoodNews: return "Bad power-ups only"
        case .noBadNews: return "Good power-ups only"
        case .powerShower: return "Power-ups are more frequent"
        case .drought: return "Power-ups are rare"
        case .fogOfWar: return "Every brick is invisible"
        case .mirrored: return "The level is presented mirrored"
        case .upsideDown: return "The level is presented upside down"
        case .brickSwap: return "Brick types are swapped around"
        case .noPausing: return "The pause button is disabled"
        case .timeTrial: return "There’s only 90s available but unlimited lives"
        case .mayhemBricks: return "Brick variety is dialled up"
        case .monochromatic: return "All colour is drained from the game"
        case .dailyTheme: return "One theme is applied"
        case .alwaysOn: return "One power-up is permanently active"
        case .landslide: return "Bricks continuously descend downwards"
        case .fullDeck:
            return "Everything is in play from the first metre. The rare stays rare."
        case .levelPegging:
            return "Everything is in play from the first metre, and nothing is rarer than "
                + "anything else."
        }
    }

    /// Which modes the twist can be drawn for.
    func applies(to mode: GameMode) -> Bool {
        switch self {
        case .oneLife:
            return mode == .classic
            // The endless modes already have exactly one life
        case .spareBalls:
            return true
            // **Every mode, from round 228's twist workbook**: "two extra balls are
            // provided", which in Classic means two more than the mode's own rack and in the
            // endless modes means a rack where there was none. It began as the generous day
            // for the single-ball modes (James's suggestion from the first daily play test)
            // and has grown into the one lives twist that gives
        case .loaded:
            return false
            // **Retired** (James, round 228: "extra balls covers loaded"). Five lives in
            // Classic and three balls in the endless modes were the same idea counted twice,
            // and Extra Balls says it in a way that means something in every mode.
            //
            // The case stays rather than being deleted, for the reason `PowerUpAvailability
            // .retired` exists: a raw value is what a stored day is written down as, and a
            // day already played would decode into nothing without it
        case .mirrored, .upsideDown, .brickSwap:
            return mode == .classic
        case .landslide:
            return mode == .classic
            // **Classic alone** (the workbook's own column). The endless modes already have a
            // field that comes down at them, and a twist that promises a landslide and delivers
            // the mode's own cadence is a twist that did nothing
        case .fullDeck, .levelPegging:
            return mode == .endlessII
            // Mayhem alone, because the thing they turn off is Mayhem's introduction queue.
            // Classic has a designed level and the original Endless has height-band tables;
            // neither holds anything back, so neither has anything for these to let go of
        case .mayhemBricks:
            return mode == .endlessII
            // §4's table says "Endless modes", and this is narrower on purpose: the original
            // Endless has no style machinery at all - its rows come from height-band tables -
            // so "Mayhem's style pool" there is not a rate change but a port of the whole
            // style system into a mode that never had it. That is queued as its own question
            // rather than smuggled in under a twist. Here, where the pool exists, the twist
            // is the variety dial turned up - which is the table's own gloss on it
            // A designed layout is the thing being turned over, and only Classic has one:
            // the endless fields are generated a row at a time, where "the wrong way round"
            // would be a different random field rather than a familiar one seen afresh
        case .suddenDeath:
            return false
            // **Retired** (James, round 228: "sudden death is replaced by one life"), where
            // it had only been parked. The reasoning was already written and has not changed:
            // in the endless modes it was One Life said twice, and in Classic it is One Life
            // by another name. The scene keeps its teeth, because a hand-built challenge can
            // still ask for it
        default:
            return true
        }
    }

    /// How long a Time Trial lasts, in seconds. §4: "90 seconds on the clock; the score at
    /// the whistle is the score."
    static let timeTrialSeconds: Double = 90

    /// The date this twist may first be offered (§2.1). Append-only.
    var activationKey: String {
        switch self {
        case .mirrored, .upsideDown: return "2026-09-01"
        case .brickSwap: return "2026-09-01"
        // Joins the layout category on the category's own date. Safe to add to that pool
        // because no date this changes has been played: the pool only shifts days from the
        // activation forward, and the golden test pins the days behind it
        case .noPausing, .timeTrial: return "2026-10-01"
        case .mayhemBricks: return "2026-10-01"
        case .monochromatic, .dailyTheme: return "2026-11-01"
        case .alwaysOn, .landslide: return "2026-11-01"
        case .fullDeck, .levelPegging: return "2026-12-01"
        default: return "2026-08-01"
        }
        // The launch pool activates together; later twists carry later dates. A twist's date
        // keeps it out of an older day's *pool*, and `Category.activationKey` does the same
        // for the category it arrives in - between them, nothing already played changes
    }

    /// The date this twist stops being *drawn*, and the reason it exists.
    ///
    /// **Retiring a twist is adding one backwards** (James, round 228: "once 1.3 is released,
    /// any changes to Daily Challenge mode cannot corrupt previous days, so we need to make
    /// sure it's possible to add things and make changes"). Adding was already safe, through
    /// `activationKey`. Taking one away was not: dropping it from the pool shortens the list
    /// every past day rolled against, so every date behind the change draws something else.
    ///
    /// So a retirement is a date too. Before it the twist is in the pool exactly as it always
    /// was, and the days that drew it still draw it; from it, the pool is one shorter and the
    /// days after roll afresh. Set it in the *future* after 1.3 ships, the way an activation
    /// is set in the future, and nothing a player has played can move.
    ///
    /// Loaded and Sudden Death carry a date before the game's first daily, which is the one
    /// thing that will not be allowed later: it rewrites history, and it is allowed here only
    /// because there is no history yet (James: "happy to overwrite previous daily challenge
    /// days as we're not yet released"). The golden-record test caught the change, which is
    /// what it is for, and its pins were re-taken deliberately rather than quietly.
    var retirementKey: String {
        switch self {
        case .loaded, .suddenDeath: return "2000-01-01"
        default: return "9999-12-31"
        }
    }

    /// Whether this twist may be drawn for a day with this key.
    func inPool(on key: String, for mode: GameMode) -> Bool {
        applies(to: mode) && activationKey <= key && key < retirementKey
    }

    /// The Classic levels a layout flip is not worth offering on.
    ///
    /// James, round 294: "for the daily challenge twists mirrored and upside down, don't have
    /// these set for levels that are symmetrical and won't look different when flipped." A
    /// twist that changes nothing is a wasted day - the briefing promises a rule change and the
    /// level arrives looking as it always does.
    ///
    /// **This is James's own review, level by level, and it is the authority** (round 296). It
    /// replaced a measurement, and the reason is the sentence he added with the list: "there
    /// are also lots of other levels not mentioned here that are quite similar when either
    /// mirrored or upside down. The levels available for these twists should be *significantly
    /// different* when mirrored or upside down to make it interesting."
    ///
    /// Significantly different is a judgement, and the measurement could only answer
    /// *identical*: build the level, flip it, compare every brick. That found three levels
    /// where the two fields match to the pixel, and he found fifty-two worth excluding. All
    /// three of the measured ones are in his list, which is the shape you would expect - exact
    /// symmetry is the strictest case of the thing he is describing, and a strict subset is a
    /// measurement agreeing with a judgement rather than contradicting it.
    ///
    /// **And a measured bar underneath the judgement** (round 297): "for anything >=80% similar,
    /// exclude from the mirrored and upside down twists." So the table is his list *plus*
    /// every level where at least four bricks in five land on another of the same kind when the
    /// level is flipped. `DailyLayoutFlipTests` measures that share and fails if any level over
    /// the bar is missing from here, which turns "significantly different" from a judgement
    /// that has to be re-made by hand into one made once with a number to hold it.
    ///
    /// The bar adds seven levels to Mirrored and none to Upside Down - the three at or above it
    /// there were already on his list, and the next one down sits at 75%.
    ///
    /// Given per pack and recorded as global level numbers, which is what the generator draws:
    /// Classic starts at 1, Space at 11, Nature 21, City 31, Food 41, Computer 51, Body 61,
    /// World 71, Emoji 81, Numbers 91 and Challenge 101.
    static let levelsUnchangedBy: [DailyTwist: Set<Int>] = [
        .mirrored: [1, 2, 5, 6, 7, 8, 9, 10,           // Classic 1, 2, 5-10
                    11, 14, 15,                         // Space 1, 4, 5
                    21, 24, 25, 27, 29, 30,             // Nature 1, 4, 5, 7, 9, 10
                    32, 33, 34, 39,                     // City 2, 3, 4*, 9
                    41, 43, 45, 48,                     // Food 1, 3, 5, 8
                    51, 52, 54, 56, 57, 60,             // Computer 1, 2*, 4, 6, 7, 10
                    62, 63, 65, 66, 68, 69, 70,         // Body 2, 3, 5, 6*, 8*, 9, 10*
                    73, 79, 80,                         // World 3, 9, 10
                    81, 83, 84, 85, 89,                 // Emoji 1, 3, 4, 5*, 9
                    92, 93, 98, 99,                     // Numbers 2, 3, 8, 9*
                    101, 103, 104, 105, 106, 107, 108, 109, 110],
                                                        // Challenge 1, 3-10
        .upsideDown: [1, 8, 9, 10,                      // Classic 1, 8, 9, 10
                      14,                               // Space 4
                      27, 29,                           // Nature 7, 9
                      33,                               // City 3
                      51, 55,                           // Computer 1, 5
                      73,                               // World 3
                      81, 82, 84,                       // Emoji 1, 2, 4
                      98,                               // Numbers 8
                      101, 106, 108, 109, 110],         // Challenge 1, 6, 8, 9, 10
    ]
    // The seven marked `*` are the ones the **80% rule** adds to James's own review (round
    // 297: "for anything >=80% similar, exclude from the mirrored and upside down twists").
    // Nothing is added to Upside Down by it - the three levels at or above the bar there were
    // already on his list, and the next one down is at 75%.

    // **The last pack is Challenge, and James's note said Space twice.** His list runs in pack
    // order - Classic, Space, Nature, City, Food, Computer, Body, World, Emoji, Numbers - and
    // the only pack it never names is Challenge, which is exactly where the second "Space Pack"
    // heading sits. Read as Challenge, and worth confirming: it is nine of that pack's ten
    // levels, which is a lot to exclude, and if it really was meant for Space then Space's
    // levels are wrongly in the pool and Challenge's wrongly out.

    /// Whether this twist would visibly do something on this day's level.
    ///
    /// True for everything that is not a layout flip, and for every day with no Classic level
    /// to flip - the endless modes generate their own fields and have nothing fixed to be
    /// symmetric about.
    func changesSomething(onClassicLevel level: Int?) -> Bool {
        guard let level, let unchanged = DailyTwist.levelsUnchangedBy[self] else { return true }
        return unchanged.contains(level) == false
    }

    // MARK: - Which twists may share a day

    /// The pairs the design refuses, exactly as James's twist matrix draws them.
    ///
    /// The matrix is the *Twist Matrix* sheet of `Giga-Ball 2026 - Twist Details.xlsx`, twenty
    /// twists square, and this is every "No" cell in it between two twists that exist here. It
    /// is transcribed rather than derived because there is nothing to derive it from: whether
    /// Extra Mayhem sits well with Mirrored is a judgement about how a day reads, not a
    /// consequence of anything either of them does.
    ///
    /// **Seven of the eleven were already impossible** and are written down anyway. A day draws
    /// at most one twist per category, so every refusal within a family - the five among the
    /// economy twists, and One Life against Extra Balls - could never have happened. Keeping
    /// them here makes this a copy of the matrix rather than a copy of the leftovers, and
    /// `testTheCategoryRuleAlreadyCoversWhatItCovers` proves the overlap rather than assuming
    /// it, so the day a category is re-cut the test says which refusals stopped being free.
    ///
    /// The four that were live: **Extra Mayhem** against each of Upside Down, Mirrored and
    /// Brick Swap, and **Extra Balls** against Time Trial. Those four days were being generated
    /// before round 286.
    ///
    /// Vanilla is in the sheet as incompatible with everything and is not here: it is the
    /// no-twists day, which this already produces by drawing nothing. Classic Mayhem is in the
    /// sheet and is not built (§12's Mayhem Rules) - its row is recorded in the daily spec
    /// against the day it is.
    static let refusedPairs: [(DailyTwist, DailyTwist)] = [
        (.brickSwap, .mayhemBricks),
        (.drought, .noPowerUps),
        (.drought, .powerShower),
        (.mayhemBricks, .mirrored),
        (.mayhemBricks, .upsideDown),
        (.noBadNews, .noGoodNews),
        (.noBadNews, .noPowerUps),
        (.noGoodNews, .noPowerUps),
        (.noPowerUps, .powerShower),
        (.oneLife, .spareBalls),
        (.spareBalls, .timeTrial),
    ]

    /// Whether these two twists may share a day.
    ///
    /// Symmetric, because the matrix is: it is written out as one triangle and asked from both
    /// sides. A twist pairs with itself for the sake of the answer being total - nothing ever
    /// asks, since a day cannot draw the same twist twice.
    func pairsWith(_ other: DailyTwist) -> Bool {
        DailyTwist.refusedPairs.contains {
            ($0 == self && $1 == other) || ($0 == other && $1 == self)
        } == false
    }

    /// The draw weight within its category.
    var weight: Int {
        switch self {
        case .suddenDeath: return 6
        case .noPowerUps: return 8
        case .fogOfWar: return 8
        default: return 10
        }
    }

    /// The earliest day any pool entry activates - the first daily there ever was, and
    /// therefore the far end of the briefing screen's day browsing.
    static var firstActivationKey: String {
        allCases.map(\.activationKey).min() ?? "2026-08-01"
    }

    /// The remappings Brick Swap can draw, one per day (§4: "a small table of remappings,
    /// drawn deterministically").
    ///
    /// **Nothing here may map a breakable brick to an indestructible one**, and there is a
    /// test on the table rather than on the cases: a Classic level has to stay completable,
    /// and a normal brick turned indestructible in the wrong level is a level that cannot be
    /// finished - a much worse day than a hard one.
    enum DailyBrickSwap: CaseIterable {
        /// Every ordinary brick takes three hits (§4's own example).
        case hardened
        /// Every multi-hit brick is ordinary - the generous draw.
        case softened
        /// Every ordinary brick is invisible until struck. Different from Fog of War, which
        /// hides *everything* including the types that stay hidden machinery-side; this
        /// turns one type over and leaves multi-hits and indestructibles standing as
        /// landmarks to navigate by.
        case veiled

        /// The day's remap, drawn from the key on its own stream.
        ///
        /// **Its own seed offset, never a roll in `rawChallenge`.** The challenge stream's
        /// layout is what keeps every already-played day stable (§2.1), so a twist's private
        /// details have to come from a separate stream keyed off the same date - the same
        /// reason `seedOffset` exists at all.
        static func drawn(forKey key: String) -> DailyBrickSwap {
            var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: key) &+ 0xB51C)
            return allCases[stream.roll(allCases.count)]
        }
    }

    /// The power-up that is on all day, drawn from the key on its own stream.
    ///
    /// **Timed and turn-based only** (the workbook: "permanent power-up should be randomly
    /// selected from the available timed or paddle hit based power-ups"). An instant has
    /// nothing to be permanently on *about* - it happens and is over - so the pool is read off
    /// the duration column, which says "10s" or "5 paddle hits" for exactly the ones that last.
    ///
    /// The daily's own bans apply first, and Mayhem's own power-ups are excluded outside
    /// Mayhem. Returns nil if that leaves nothing, which is the honest answer for a mode with
    /// no lasting power-ups rather than a crash or an arbitrary pick.
    static func alwaysOnPowerUp(forKey key: String, mode: GameMode) -> Int? {
        let setup = LevelPackSetup()
        let lasting = setup.powerUpTimerArray.indices.filter { index in
            let timer = setup.powerUpTimerArray[index]
            guard timer == "10s" || timer == "5 paddle hits" else { return false }
            guard DailyTwist.bannedFromDailies.contains(index) == false else { return false }
            guard setup.retiredPowerUpIndices.contains(index) == false else { return false }
            return mode == .endlessII || setup.isEndlessIIPowerUp(index) == false
        }
        guard lasting.isEmpty == false else { return nil }

        var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: key) &+ 0x0A5A)
        return lasting[stream.roll(lasting.count)]
    }

    /// The power-ups no daily ever offers, whatever its twists say.
    ///
    /// From the power-up workbook's Daily column, which James made the overarching rule in
    /// round 228. Written here as well as applied in `applyDailyEconomyTwists`, because the
    /// Always On draw has to know before it picks - offering a permanent Lock would be a run
    /// frozen for the whole day.
    static let bannedFromDailies: Set<Int> = [1, 48, 49]

    /// The theme a Theme day is played in, drawn from the key on its own stream.
    ///
    /// Its own seed offset rather than a roll in `rawChallenge`, for `DailyBrickSwap`'s
    /// reason: the challenge stream's layout is what keeps every already-played day stable,
    /// so a twist's private details come from a separate stream keyed off the same date.
    ///
    /// Classic is excluded from the draw. It is the theme most players are already in, and a
    /// twist announcing "one theme, chosen for you" and then handing back the one on screen
    /// is a twist that did nothing - and it is Monochromatic's whole answer besides.
    static func dailyThemeIndex(forKey key: String, themeCount: Int) -> Int {
        guard themeCount > 1 else { return 0 }
        var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: key) &+ 0x7A11)
        return 1 + stream.roll(themeCount - 1)
    }

    /// Whether the day's layout is turned over, and which way. Nil when it is not.
    ///
    /// One question rather than two, because §4.2 puts both in the `layout` category and a
    /// day therefore has at most one of them - the caller should not have to know that.
    static func layoutFlip(in twists: [DailyTwist]) -> DailyTwist? {
        twists.first { $0.category == .layout }
    }
}

// MARK: - The challenge

/// A day's challenge, frozen: what the generator drew, and nothing that changes after.
/// The ten achievements the daily's own history earns.
///
/// **From James's workbook, built in round 310.** Every one of them is a question about days
/// already played, so none of them needs anything stored: the answers come off
/// `TotalStats.dailyRecords`, which the sync already merges, and off the standing the board
/// hands back when a score posts. That is the reason there is a type here rather than ten
/// checks scattered through the posting flow - the history is one thing, and one thing should
/// read it.
///
/// The indices are the catalogue's, written down once. Adding an achievement in the middle of
/// the list would move them, which is why nothing is ever inserted: the arrays are append-only
/// and a player's unlocked flags are stored by position.
enum DailyAchievements {

    static let firstPost = 85       // First Daily Challenge
    static let tenPosts = 86        // Serial Daily Challenger
    static let hundredPosts = 87    // Experienced Daily Challenger
    static let yearOfPosts = 88     // Seasoned Daily Challenger
    static let weekStreak = 89      // Week Long Streak
    static let monthStreak = 90     // Month Long Streak
    static let yearStreak = 91      // Year Long Streak
    static let topTen = 92          // Top 10 Finish
    static let firstPlace = 93      // Top Of The Charts
    static let everyTwist = 94      // Twist Completionist

    /// How many posted days each count wants.
    ///
    /// A *posted* day, not a played one: the sheet's first row says "post a score in a Daily
    /// Challenge", and the three counts under it are the same sentence with a bigger number.
    /// Free play does not count, which is the whole point of the attempt being one a day.
    static let counts: [(index: Int, days: Int)] = [
        (firstPost, 1), (tenPosts, 10), (hundredPosts, 100), (yearOfPosts, 365),
    ]

    /// How many days *in a row* each streak wants.
    ///
    /// Seven, thirty and three hundred and sixty-five. A month is thirty rather than a calendar
    /// month because the streak is a run of days and not a page of a diary: "complete every
    /// Daily Challenge for 1 month" read as a calendar month would mean a player who started on
    /// the second of a month could not earn it until the first of the next, having missed
    /// nothing.
    static let streaks: [(index: Int, days: Int)] = [
        (weekStreak, 7), (monthStreak, 30), (yearStreak, 365),
    ]

    /// The twists a player could be asked to meet, on the day the question is asked.
    ///
    /// Live ones only. Four twists are retired - Loaded and Sudden Death among them - and
    /// requiring every case would make Twist Completionist unearnable by anyone who was not
    /// playing before they went. A twist that has not activated yet is not required either, and
    /// once the achievement is earned it stays earned, so a twist added next year cannot take
    /// it back off a player who has it.
    static func liveTwists(on key: String) -> Set<DailyTwist> {
        Set(DailyTwist.allCases.filter { twist in
            [GameMode.classic, .endless, .endlessII].contains {
                twist.inPool(on: key, for: $0)
            }
        })
    }

    /// Which of the history's achievements the record list has earned.
    ///
    /// - Parameter key: today's key, which decides which twists are still being offered.
    static func earned(from records: [DailyChallengeRecord], on key: String) -> Set<Int> {
        var earned: Set<Int> = []

        let posted = records.filter(\.posted).count
        for count in counts where posted >= count.days { earned.insert(count.index) }

        let best = DailyStreak.longest(records: records)
        for streak in streaks where best >= streak.days { earned.insert(streak.index) }
        // `DailyStreak` already owns the arithmetic, and owns it more carefully than a second
        // copy would: it walks sorted keys through the calendar and refuses a key that does not
        // spell its own date back, which is the guard against a corrupted record joining a run
        // it has nothing to do with

        let played = records.filter { $0.attemptCount > 0 }.map(\.dateKey)
        var met: Set<DailyTwist> = []
        for day in played {
            met.formUnion(DailyChallengeGenerator.challenge(forKey: day).twists)
        }
        // Played rather than posted: the sheet says "play a Daily Challenge with each twist at
        // least once", and a day whose attempt was spent without finishing was still met.
        // Derived rather than recorded, because the generator is pure - a day's twists can
        // always be worked out again from its key, which is the same property the resume path
        // relies on

        if liveTwists(on: key).subtracting(met).isEmpty { earned.insert(everyTwist) }
        return earned
    }

    /// What a finishing position on the day's board earns.
    ///
    /// Checked when a standing comes back rather than stored, because the daily board is a
    /// *recurring* leaderboard: it resets at each deadline, so a past day's placing cannot be
    /// asked for again. If the answer is not taken when it arrives it is gone.
    static func earned(fromStanding standing: LeaderboardStanding) -> Set<Int> {
        var earned: Set<Int> = []
        if standing.rank <= 10 { earned.insert(topTen) }
        if standing.rank == 1 { earned.insert(firstPlace) }
        return earned
    }
}


struct DailyChallenge: Equatable {
    let dateKey: String
    let mode: GameMode
    /// The level, when the mode is Classic - a level number in the full catalogue,
    /// played in single-level mode.
    let classicLevel: Int?
    let twists: [DailyTwist]

    func has(_ twist: DailyTwist) -> Bool { twists.contains(twist) }
}

enum DailyChallengeGenerator {

    /// The full catalogue of Classic levels the daily can draw from.
    ///
    /// Derived from the pack tables rather than counted: packs 2 onward are the classic
    /// packs, and their levels are numbered from 1. The daily ignores pack unlocks (§3) -
    /// it is a tasting menu.
    static var classicLevelCount: Int {
        let setup = LevelPackSetup()
        return (2..<setup.numberOfLevels.count).reduce(0) { $0 + setup.numberOfLevels[$1] }
    }

    /// The day's challenge, computed - never stored, never fetched. Pure.
    ///
    /// What the reader sees is `rawChallenge` **stepped away from yesterday's** where the two
    /// would have read as the same idea twice: "consecutive days can currently both be, say, a
    /// single level with One Life, which reads as the generator repeating itself rather than
    /// as a challenge that changes daily" (play-test round 90).
    ///
    /// The look-back is exactly two days deep and no deeper, which is the whole trick. A rule
    /// that compared today with *yesterday's final answer*, itself compared with the day
    /// before, would recurse to the beginning of time on every draw; one that compared raw
    /// draws only would let an adjusted day collide with the day after it. Two days back,
    /// resolved bottom-up, is bounded, cheap, and identical on every device - which is the
    /// property the whole daily rests on (§2.1).
    static func challenge(forKey key: String) -> DailyChallenge {
        guard let yesterday = previousKey(of: key),
              let dayBefore = previousKey(of: yesterday) else {
            return rawChallenge(forKey: key)
        }
        let settledYesterday = stepped(rawChallenge(forKey: yesterday),
                                       from: rawChallenge(forKey: dayBefore))
        return stepped(rawChallenge(forKey: key), from: settledYesterday)
    }

    /// The day before, in the daily's own UTC calendar.
    static func previousKey(of key: String) -> String? {
        guard let date = DailyDay.date(forKey: key),
              let earlier = DailyDay.utcCalendar.date(byAdding: .day, value: -1, to: date)
        else { return nil }
        return DailyDay.key(for: earlier)
    }

    /// Whether two days read as the same idea.
    ///
    /// Precise rather than broad, and the precision is the point. The mode split is fixed at
    /// Classic 50, Endless 25, Mayhem 25 (§3), so consecutive days share a mode about a third
    /// of the time whatever this rule says - calling every such pair a repeat would have the
    /// generator forever stepping away from a coincidence it cannot avoid, and would bend the
    /// mode split out of shape trying.
    ///
    /// What actually reads as the generator repeating itself:
    /// - the same mode with **twists from the same family** two days running, which is the
    ///   play test's own example - "both a single level with One Life";
    /// - two plain days in an **endless** mode, which really are the same challenge twice,
    ///   since an endless day has no level to make it its own.
    ///
    /// What does not: two plain Classic days, because each names a different level; or a
    /// plain day beside a twisted one, which is a change of rules however familiar the mode.
    static func readsTheSame(_ a: DailyChallenge, _ b: DailyChallenge) -> Bool {
        guard a.mode == b.mode else { return false }
        let families = Set(a.twists.map(\.category))
        let others = Set(b.twists.map(\.category))
        if families.isEmpty && others.isEmpty { return a.mode != .classic }
        if families.isEmpty || others.isEmpty { return false }
        return families.intersection(others).isEmpty == false
    }

    /// The offsets a repeated day steps through, in order, until it finds one that does not
    /// read like yesterday. Golden-ratio odd constants, so each is far from its neighbours in
    /// the seed space and none is a multiple of another.
    static let repeatStepOffsets: [UInt64] = [0x9E37_79B9_7F4A_7C15,
                                              0xBF58_476D_1CE4_E5B9,
                                              0x94D0_49BB_1331_11EB,
                                              0xD6E8_FEB8_6659_FD93]

    /// Steps a day away from the one before it, when the two would have read as the same idea.
    ///
    /// The step is a fresh seed rather than a nudge to the result: re-rolling the whole day
    /// keeps every draw in the stream's own order, which is what stops a pool added later
    /// from shifting what an old date drew (§2.1).
    ///
    /// **Bounded rather than looping.** Four candidates, then the last one stands however it
    /// reads. A loop that kept drawing until it found something different would have no upper
    /// bound on its work, and - worse - would make each day depend on how hard the *previous*
    /// day had to look, which is a chain rather than a comparison. Measured over a year of
    /// draws: 38 days rhymed with no rule at all, 25 with one step, and **two** with four
    /// steps and the narrowed definition above - which is the "occasionally" the play test
    /// can live with, reached without touching the mode split.
    static func stepped(_ today: DailyChallenge, from yesterday: DailyChallenge) -> DailyChallenge {
        guard readsTheSame(today, yesterday) else { return today }
        var candidate = today
        for offset in repeatStepOffsets {
            candidate = rawChallenge(forKey: today.dateKey, seedOffset: offset)
            if readsTheSame(candidate, yesterday) == false { return candidate }
        }
        return candidate
    }

    /// The day exactly as the seed draws it, before the no-repeats rule looks at it.
    static func rawChallenge(forKey key: String, seedOffset: UInt64 = 0) -> DailyChallenge {
        var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: key) &+ seedOffset)

        // 1. The mode: Classic 50, Endless 25, Mayhem 25 (§3)
        let modeRoll = stream.roll(100)
        let mode: GameMode = modeRoll < 50 ? .classic : (modeRoll < 75 ? .endless : .endlessII)

        // 2. The level, drawn whether or not it is used - every draw always happens, in the
        // same order, so the *stream's layout* never depends on earlier outcomes (§2.1).
        //
        // That is the half this guarantees, and it is worth being exact about the other half.
        // `classicLevelCount` is derived live from the pack tables, so **adding a level pack
        // changes this roll's modulus and every past Classic day draws a different level** -
        // the fixed draw order protects the shape of the stream, not the outcome of a roll
        // whose range moved. A previous version of this comment said adding a pool "cannot
        // shift what an old date drew", which is true of a new *twist* (kept out of an old
        // day's pool by its `activationKey`) and untrue of a new level.
        //
        // Nothing here needs to change for it: `testTheDaysAlreadyPlayedStillReadExactlyTheSame`
        // pins thirty real days with their level numbers, so a pack added in a later release
        // fails that test by name rather than quietly rewriting history. This comment exists so
        // that whoever sees it fail knows immediately why, rather than re-pinning it.
        let levelRoll = stream.roll(max(1, classicLevelCount))
        let classicLevel: Int? = mode == .classic ? levelRoll + 1 : nil

        // 3. How many twists, and whether the day wears a look
        //
        // **The mix James asked for, from `twistMixKey` onward** (round 319): "the daily
        // challenge twists seem to cycle few the same few options quite frequently. There
        // should be different ones more often, more often days with multiple twists per day, a
        // theme or B&W pretty much every day or very frequently paired with another twist.
        // Vanilla should be quite rare, like once every 2 weeks."
        //
        // Four changes to one paragraph. A plain day drops from three in ten to one in
        // fourteen; the look category - which is exactly Monochromatic and Theme - is drawn
        // *deliberately* on most days rather than waiting to come up in a uniform category
        // roll; and the twists beside it are one or two far more often than none.
        //
        // **Behind a date, like everything else here.** The header's promise is that any past
        // date replays identically for ever, and this changes the shape of the draw rather than
        // the contents of a pool - so every day up to `twistMixKey` takes the old branch,
        // unchanged, roll for roll. `testTheDaysAlreadyPlayedStillReadExactlyTheSame` is what
        // says so, and it passes untouched.
        let newMix = key >= DailyChallengeGenerator.twistMixKey
        var twists: [DailyTwist] = []
        var categories = DailyTwist.Category.allCases.filter { $0.activationKey <= key }

        let twistCount: Int
        var plainDay = false
        if newMix {
            let plainRoll = stream.roll(100)
            if plainRoll < DailyChallengeGenerator.plainDayChance {
                plainDay = true
                twistCount = 0
            } else {
                // The look first, so a day that can only fit one twist spends it on the thing
                // the player sees the moment the field appears
                if stream.roll(100) < DailyChallengeGenerator.lookChance,
                   let look = DailyTwist.Category.look.activationKey <= key
                    ? DailyChallengeGenerator.draw(from: DailyTwist.allCases.filter {
                        $0.category == .look && $0.inPool(on: key, for: mode)
                            && $0.changesSomething(onClassicLevel: classicLevel) },
                        &stream) : nil {
                    twists.append(look)
                    categories.removeAll { $0 == .look }
                }
                // Then one or two beside it, and two nearly as often as one
                twistCount = stream.roll(100) < DailyChallengeGenerator.secondTwistChance ? 2 : 1
            }
        } else {
            // §3 as it stood: none 30, one 50, two 20
            let countRoll = stream.roll(100)
            twistCount = countRoll < 30 ? 0 : (countRoll < 80 ? 1 : 2)
        }

        // 4. The twists: a category first, then a twist inside it, both weighted - at most
        // one per category, so the set is legal by construction (§4.2)
        // Filtered before the roll, not after: the index this draws is taken against the
        // list's length, so a category the day cannot use must not be in the list at all
        for _ in 0..<twistCount {
            guard categories.isEmpty == false else { break }
            let category = categories.remove(at: stream.roll(categories.count))
            let pool = DailyTwist.allCases.filter { candidate in
                candidate.category == category && candidate.inPool(on: key, for: mode)
                    && twists.allSatisfy { $0.pairsWith(candidate) }
                    && candidate.changesSomething(onClassicLevel: classicLevel)
            }
            guard pool.isEmpty == false else { continue }
            // **And nothing already drawn refuses it** (round 286). At most one twist per
            // category was "legal by construction" for every pair the matrix rules out *within*
            // a family, and it says nothing at all about the four that cross families - a day
            // could be Extra Mayhem and Mirrored, or Extra Balls and Time Trial, both of which
            // the matrix marks as no. Filtered here rather than checked afterwards, for the
            // same reason the categories are filtered before their roll: the draw takes an
            // index against the pool's length, so a twist the day may not have must not be in
            // the pool to begin with. A category whose whole pool is refused simply yields no
            // second twist, which is a day with one - the outcome the count roll already
            // produces half the time

            if let twist = DailyChallengeGenerator.draw(from: pool, &stream) { twists.append(twist) }
        }

        if newMix, twists.isEmpty, plainDay == false {
            // **A day the rolls said was not plain must not end up plain.** Measured over a
            // year, the seven-in-a-hundred roll was producing eleven: the category the loop
            // drew could refuse everything - its pool empty for this mode, or every candidate
            // ruled out by the pairing matrix - and a day that drew nothing fell through as
            // Vanilla. That is the graceful failure the loop has always had, and it is the
            // right one for a *second* twist and the wrong one for the only one.
            //
            // So the day asks again, across every category still open at once rather than
            // inside the one it happened to pick. Tuning `plainDayChance` down to absorb the
            // difference would have hit the number and left the cause, and the cause moves
            // whenever a twist's pool rules do.
            let everything = DailyTwist.allCases.filter { candidate in
                categories.contains(candidate.category)
                    && candidate.inPool(on: key, for: mode)
                    && candidate.changesSomething(onClassicLevel: classicLevel)
            }
            if let twist = DailyChallengeGenerator.draw(from: everything, &stream) {
                twists.append(twist)
            }
        }

        return DailyChallenge(dateKey: key, mode: mode, classicLevel: classicLevel,
                              twists: twists)
    }

    /// One twist out of a pool, by weight. Nil for an empty pool.
    ///
    /// Pulled out in round 319 so the look draw and the category loop use the same arithmetic
    /// rather than two copies of it - a second copy of a decision is wrong the first time the
    /// decision changes, and this one had just been about to be copied.
    static func draw(from pool: [DailyTwist], _ stream: inout DailySeededGenerator) -> DailyTwist? {
        guard pool.isEmpty == false else { return nil }
        let total = pool.reduce(0) { $0 + $1.weight }
        var drawn = stream.roll(total)
        for twist in pool {
            drawn -= twist.weight
            if drawn < 0 { return twist }
        }
        return pool.last
    }

    /// The day the twist mix changes shape (round 319). Days before it draw exactly as they
    /// always did, which is the promise at the top of this file.
    static let twistMixKey = "2026-10-01"

    /// How often a day has no twists at all, in a hundred.
    ///
    /// **James: "Vanilla should be quite rare, like once every 2 weeks."** It was thirty -
    /// close to one day in three, which is much of what made the daily feel like it was cycling
    /// the same few ideas: a third of the time it was offering none of them.
    ///
    /// **Five rather than the seven that one-day-in-fourteen works out at**, because the roll
    /// is not the whole of it. A handful of days each year have no legal twist at all - every
    /// candidate ruled out by the mode, the level or the pairing matrix - and those land plain
    /// however the roll went. Measured over a year, five produces about one plain day in
    /// fourteen and seven produced one in eleven. The gap is real rather than noise, so the
    /// number compensates for it deliberately and says so here.
    static let plainDayChance = 5

    /// How often a day wears a look - Monochromatic or the day's Theme.
    ///
    /// **James: "a theme or B&W pretty much every day or very frequently paired with another
    /// twist."** These two are the `look` category and the only members of it, so drawing the
    /// category deliberately is the whole of it. Before this they waited to come up in a
    /// uniform roll across nine categories, which on a one-twist day is one chance in nine -
    /// so the thing the player sees the instant the field appears was the rarest thing on
    /// offer.
    ///
    /// Ninety rather than a hundred: "pretty much every day" is not every day, and a day that
    /// is *never* plain-looking has nothing to make the themed ones feel like anything. What
    /// reaches the player is lower again - a look still has to survive the pools - so ninety
    /// lands around three days in four.
    static let lookChance = 90

    /// How often a day that already has a look takes two more twists rather than one.
    ///
    /// **James: "more often days with multiple twists per day."** With the look counted, this
    /// makes two twists the common case and three a regular one. The category rules still
    /// decide what is *legal*, so a day whose second category refuses everything simply ends
    /// up shorter - which is the same graceful failure the draw has always had.
    static let secondTwistChance = 45

    /// What a Classic day is asking for, in the player's terms.
    ///
    /// One string, read by every screen that says it, so the briefing and anything added
    /// later cannot describe the same day two ways (play-test round 90).
    static let classicObjective = "High score on a single level"

    /// Which pack a catalogue level number lives in, for launching it.
    static func pack(forClassicLevel level: Int) -> Int {
        let setup = LevelPackSetup()
        var remaining = level
        for pack in 2..<setup.numberOfLevels.count {
            if remaining <= setup.numberOfLevels[pack] { return pack }
            remaining -= setup.numberOfLevels[pack]
        }
        return setup.numberOfLevels.count - 1
    }

    /// The level's number as the game knows it, from the catalogue number.
    static func levelNumber(forClassicLevel level: Int) -> Int {
        let setup = LevelPackSetup()
        let pack = pack(forClassicLevel: level)
        let before = (2..<pack).reduce(0) { $0 + setup.numberOfLevels[$1] }
        return setup.startLevelNumber[pack] + (level - before - 1)
    }
}

// MARK: - Attempts, records and boards (phase 3)

/// Everything the phone knows about one day's challenge (§10), keyed by the UTC date.
///
/// The record is created the moment the day's first play press happens - that is what
/// spends the attempt (§7): a force-quit later finds the record already there and the
/// run after it is practice. The result lands in the record when the run ends.
struct DailyChallengeRecord: Codable, Equatable {
    var dateKey: String
    /// What the scoring run finished on. Zero until it ends - and zero for ever if the
    /// player force-quit it, which is the attempt being spent with nothing to show.
    var firstAttemptScore: Int = 0
    /// Whether the first attempt finished inside the window and went to the daily board.
    var posted: Bool = false
    var bestPracticeScore: Int = 0
    var attemptCount: Int = 0
    /// What the overall board counts for this day (§7): Classic's score as it stands, an
    /// endless height × 100. Stored at posting time, so the total never re-derives a day
    /// under rules that may since have changed.
    var postedNormalisedScore: Int = 0
    /// Whether the day's score is still waiting to reach Game Center (§12.5): earned in
    /// the window, submission dispatched or due, not yet confirmed landed. Retried while
    /// the window is open; a window that closes first makes this a miss, and `posted`
    /// stays false for ever. Optional so older records decode.
    var pendingPost: Bool?

    var isPending: Bool { pendingPost ?? false }
}

extension DailyChallengeRecord {

    /// Two devices' histories, folded into one - the sync's merge rule.
    ///
    /// Union by date; where both sides know a day, everything is take-the-most: posted
    /// is OR-ed, the scores and counts take the higher. All of these only ever grow on a
    /// real device, so the rule is the same one every other synced stat uses.
    static func merged(_ a: [DailyChallengeRecord],
                       _ b: [DailyChallengeRecord]) -> [DailyChallengeRecord] {
        var byDate: [String: DailyChallengeRecord] = [:]
        for record in a { byDate[record.dateKey] = record }
        for record in b {
            guard var kept = byDate[record.dateKey] else {
                byDate[record.dateKey] = record
                continue
            }
            kept.firstAttemptScore = max(kept.firstAttemptScore, record.firstAttemptScore)
            kept.posted = kept.posted || record.posted
            kept.bestPracticeScore = max(kept.bestPracticeScore, record.bestPracticeScore)
            kept.attemptCount = max(kept.attemptCount, record.attemptCount)
            kept.postedNormalisedScore = max(kept.postedNormalisedScore,
                                             record.postedNormalisedScore)
            kept.pendingPost = (kept.isPending || record.isPending) && kept.posted == false
            // A pending post survives the merge unless either side already landed it
            byDate[record.dateKey] = kept
        }
        return byDate.values.sorted { $0.dateKey < $1.dateKey }
    }
}

enum DailyChallengePosting {

    /// What the player is told when the play press is about to start a *practice* run -
    /// nil when the run is the scoring attempt, which plays with nothing in its way.
    ///
    /// Shown as a pop-up on the press (play-test round 5), not as a standing label: the
    /// promise is still made *before* the run starts, never discovered after (§6), but
    /// it interrupts only the presses it applies to. Pure, so the promise the screen
    /// makes is a promise the tests can hold it to.
    static func practiceNotice(record: DailyChallengeRecord?, isToday: Bool,
                               mode: GameMode, closedOn: String? = nil) -> String? {
        guard isToday else {
            let when = closedOn.map { " on " + $0 } ?? ""
            return "This challenge closed\(when). Playing won't post a score."
        }
        guard let record, record.attemptCount > 0 else { return nil }
        if record.posted {
            return "You've already posted a score on the leaderboard for today's challenge of "
                + "\(scoreText(record.firstAttemptScore, mode: mode))."
                + " Playing again won't post a new score."
        }
        return "Today's attempt is spent.\nThis run won't post a score."
    }
    // **James's own words, round 306**, for the two the play test kept meeting. The closed one
    // now names the day it closed on, which is the thing a player browsing back through a
    // fortnight actually wants to know; `closedOn` is passed rather than derived here because
    // the screen already knows how it spells a date and two spellings of one date would be
    // worse than none

    // MARK: - Pending posts (§12.5)

    /// Settles the pending posts whose windows have closed: they become misses.
    ///
    /// Pure - the record keeps its scores and `posted` stays false for ever, which is
    /// what the briefing's "not posted" badge reads. Returns whether anything changed,
    /// so the caller knows whether to write.
    static func settlingMisses(in records: [DailyChallengeRecord],
                               today: String) -> (records: [DailyChallengeRecord],
                                                  changed: Bool) {
        var changed = false
        let settled = records.map { record -> DailyChallengeRecord in
            guard record.isPending, record.dateKey != today else { return record }
            var missed = record
            missed.pendingPost = false
            changed = true
            return missed
        }
        return (settled, changed)
    }

    /// Marks a day's post as landed, in the store itself.
    ///
    /// The confirmation arrives from Game Center after the scene that posted has gone,
    /// so this writes through the stats file rather than through anyone's loaded copy -
    /// and submits the overall total, which the day has only now joined.
    static func confirmPosted(dateKey: String) {
        guard let stats = loadStats() else { return }
        guard var record = stats.dailyRecord(forKey: dateKey), record.isPending else {
            return
        }
        record.posted = true
        record.pendingPost = false
        stats.upsertDailyRecord(record)
        save(stats)
        GameCenterHandler().submitDailyTotal(stats.dailyTotalPostedScore)
    }

    /// Carries anything still waiting: misses settled, today's pending post retried.
    ///
    /// Called at launch, on foregrounding and when the briefing screen opens - the
    /// moments a connection may have come back (§12.5). Oldest business first: windows
    /// that closed while offline become misses, then today's score tries again.
    static func retryPendingPosts() {
        guard let stats = loadStats() else { return }
        let today = DailyChallengeSession.shared.todayKey

        let settled = settlingMisses(in: stats.dailyRecords, today: today)
        if settled.changed {
            stats.dailyChallengeRecords = settled.records
            save(stats)
        }

        guard let record = stats.dailyRecord(forKey: today), record.isPending else {
            return
        }
        GameCenterHandler().submitDailyScores(dayScore: record.firstAttemptScore) {
            landed in
            if landed { confirmPosted(dateKey: today) }
        }
    }

    private static func loadStats() -> TotalStats? {
        guard let store = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first?
            .appendingPathComponent("totalStatsStore.plist"),
              let data = try? Data(contentsOf: store),
              let array = try? PropertyListDecoder().decode([TotalStats].self, from: data),
              let stats = array.first else { return nil }
        stats.makeStoredArraysConsistent()
        return stats
    }

    private static func save(_ stats: TotalStats) {
        guard let store = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first?
            .appendingPathComponent("totalStatsStore.plist"),
              let data = try? PropertyListEncoder().encode([stats]) else { return }
        try? data.write(to: store)
        CloudKitHandler().saveToiCloud()
        // The posted flag rides to iCloud like the attempt flag does (§10)
    }

    /// A score in the mode's own terms: heights wear their metres.
    static func scoreText(_ score: Int, mode: GameMode) -> String {
        mode == .classic ? String(score) : String(score) + "m"
    }
}

enum DailyChallengeBoards {
    /// The Game Center recurring leaderboard with a daily recurrence aligned to 00:00
    /// UTC (§7).
    ///
    /// **Both are live in App Store Connect** (confirmed round 314), inside
    /// `leaderboardSetDailyChallenge`, so submissions land rather than failing silently.
    /// These two are the whole of the daily's Game Center surface: a spec note claiming a
    /// third was in review had James looking for a board that does not exist.
    static let daily = "leaderboardDailyChallenge"
    /// The classic (non-recurring) board holding each player's running total of posted
    /// daily scores. Game Center keeps the highest submission, and a running total only
    /// grows, so resubmitting the whole total after every posting run is self-healing -
    /// including across days that could not post for want of a connection.
    static let total = "leaderboardDailyChallengeTotal"

    /// What the overall board counts a score as (§7): no one mode may dominate, and
    /// Classic scores (thousands) and endless heights (tens) are orders of magnitude
    /// apart. The factor is §13's open question; the daily board is immune either way.
    static func normalised(score: Int, mode: GameMode) -> Int {
        mode == .classic ? score : score*100
    }
}

/// Where a player stands on a board, and how many they stand among.
///
/// A place on its own says nothing about how hard it was won - 3rd of 4 and 3rd of 4,000
/// are different days (play-test round 126: "show the number of players e.g. 1st / 200").
/// So the two travel together, and the one place that turns them into words is here rather
/// than on each screen that prints them.
///
/// Written for the daily, and named `DailyStanding` until round 160 gave the endless and
/// classic game-overs the same line against their own boards. Nothing about a rank and a
/// field size was ever daily-specific; only the screen that first wanted them was.
struct LeaderboardStanding: Equatable {
    let rank: Int
    let players: Int
    /// The score at the top of the board, where Game Center knew one.
    ///
    /// Optional rather than zero: a board with no entries yet and a board whose leader
    /// happens to have nothing are different facts, and only the first should print nothing
    /// (James, round 185: "add global high score details to game over / completion screens
    /// alongside rank details").
    var best: Int? = nil

    /// The board's leading score, said the way the screen it appears on says numbers.
    ///
    /// - Parameter suffix: "m" for the endless boards, whose scores are heights, and nothing
    ///   for the ones whose scores are points. The caller knows which board it asked about;
    ///   this only knows how to group digits.
    func bestText(suffix: String = "") -> String? {
        best.map { "Best \(StatsPage.grouped($0))\(suffix)" }
    }

    /// "1st / 200", the position in the reader's own language.
    ///
    /// The field size is grouped and the place is not: one is a count, which is what
    /// separators are for, and the other is an ordinal, which has never worn one. A daily's
    /// field is small enough that this shows nowhere; the endless boards' fields are not.
    var text: String {
        "\(rank)/\(players)"
    }
    // **Plain, slashed, ungrouped** (James, round 306: "for the ranking once a score has been
    // posted show the player's ranking followed by the total number of posted scores in this
    // format 1/100 for rank 1 out of 100 players. Use this same format throughout the app").
    //
    // One property, so "throughout the app" is one change: the daily card, the daily's own
    // pause result and the endless boards' line all read this. The ordinal and the grouping
    // both went - "1st / 1,200" and "1/1200" say the same thing, and the second is the one
    // that reads at a glance beside a score.

    /// 1st, 2nd, 3rd - and whatever the reader's locale makes of them, since a formatter
    /// knows what English's exceptions are and what other languages do instead.
    static func ordinal(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

// MARK: - The session

/// The daily challenge currently being played, if one is.
///
/// A tiny singleton rather than state threaded through five view controllers: the scene
/// asks it what the twists are, the stats paths ask it whether to stand down, and it is
/// cleared the moment the player is back in the menus. Nothing in it persists.
final class DailyChallengeSession {
    static let shared = DailyChallengeSession()
    private init() {}

    /// The challenge in play, nil when the daily is not what is being played.
    var active: DailyChallenge?

    var isActive: Bool { active != nil }

    /// Whether the run in play is the day's scoring attempt (§7): today's challenge, and
    /// the play press that spent the attempt. Set by the briefing screen at launch,
    /// read at the run's end to decide between posting and practice. Everything after
    /// the first press is practice, labelled as such.
    var isScoringAttempt = false

    /// Whether the run that just ended posted to today's board - the game-over screen's
    /// question. Written by `recordDailyResult` as it settles the run, so the screen
    /// never has to re-derive what the scene already decided.
    var lastRunPosted = false

    /// Whether the run in play has forfeited its attempt by leaving the app.
    ///
    /// The No Breaks twist's second half (§4): "the pause button is disabled for the run.
    /// Backgrounding the app forfeits posting." Taking the pause button away and leaving the
    /// background route open would make the twist a suggestion - the app pauses itself when it
    /// goes to the background, so a player could get exactly what the twist withholds by
    /// switching apps. The run is not ended, because ending somebody's run from the outside is
    /// worse than not scoring it; it simply stops being the attempt.
    var forfeitedByLeaving = false

    /// Whether the run in play was resumed after its scoring window had closed.
    ///
    /// The run carries on - an interrupted daily is not a lost one - but it cannot post,
    /// and the player is told before the resume rather than after it (§12.5). The screens
    /// read this to say why a run that started as the scoring attempt is now practice.
    var resumedAfterDeadline = false

    /// Puts a saved run's daily back, or clears the session if the save is a campaign one.
    ///
    /// Called before the scene is built, because the twists are applied as the field is
    /// generated. The challenge itself is *recomputed* from the date key rather than
    /// restored from the save: the generator is a pure function of the key (§2), so this
    /// cannot disagree with what the briefing screen showed, and the save carries one
    /// short string instead of a copy of the rules.
    func restore(from save: SavedGame) {
        guard let key = save.dailyDateKey else {
            active = nil
            isScoringAttempt = false
            resumedAfterDeadline = false
            return
        }
        active = DailyChallengeGenerator.challenge(forKey: key)
        resumedAfterDeadline = key != todayKey
        closedDayNeedsAnnouncing = resumedAfterDeadline
        isScoringAttempt = (save.dailyWasScoringAttempt ?? false) && resumedAfterDeadline == false
        // A run resumed on a later day is practice from here, whatever it set out to be.
        // The window is the day, and the day has gone
    }

    /// Set when a run is restored into a day that has already closed, cleared by whoever
    /// says so. One shot, because the answer is announced once per resume and not once per
    /// pause: the splash used to carry it as a footnote, where it was read past on the way
    /// into the game (play-test round 18 asked for it to stop the game and offer a way out).
    var closedDayNeedsAnnouncing = false

    func has(_ twist: DailyTwist) -> Bool { active?.has(twist) ?? false }

    /// The date the daily screens consider "today".
    ///
    /// Real UTC now - unless the test clock has been set, which is the play-test rig the
    /// whole feature needs: days are the unit of content here, and waiting a real day per
    /// test is not a test plan. The simulated date persists across launches so a tester
    /// can stay on a day, and the briefing screen labels it loudly. Remove-before-release
    /// is tracked in the spec's build phases.
    var today: Date {
        let offset = testDayOffset
        guard offset != 0 else { return Date() }
        return DailyDay.utcCalendar.date(byAdding: .day, value: offset, to: Date())!
        // Through `testDayOffset`, which reads with `integer(forKey:)`, and not a raw
        // `object(forKey:) as? Int` - the two are not the same reader. Launching with
        // `-dailyChallengeTestDayOffset 45` puts a *String* in the argument domain, which
        // `integer` coerces and the cast rejects: the briefing header (which reads the
        // property) switched to date mode while the date itself (which read the object)
        // stayed put, and the rig looked broken in the strangest possible way (round 199).
        // The launch argument is now the way to drive the clock - it touches no stored
        // defaults, so there is nothing to forget to reset
    }

    static let testOffsetKey = "dailyChallengeTestDayOffset"

    /// How many days the test clock is wound forward or back. Zero is live.
    ///
    /// **Always zero in a release build** (round 298, closing the release-readiness item the
    /// daily spec's header has carried). No screen has written this since round 19 and only
    /// the tests set it, so a shipped app was already reading a default that nobody could move
    /// - but "nobody writes it" is a fact about today's code, and the thing standing between a
    /// stored integer and every player getting a different day was that fact rather than
    /// anything structural. The getter is compiled out of release entirely, so a value that
    /// arrived from anywhere at all - a future screen, a restored backup, a device somebody
    /// has been at - moves nothing.
    ///
    /// The setter is kept under the same flag rather than removed, because the tests that wind
    /// the clock are the reason the daily can be tested at all.
    var testDayOffset: Int {
        get {
            #if DEBUG
            return UserDefaults.standard.integer(forKey: DailyChallengeSession.testOffsetKey)
            #else
            return 0
            #endif
        }
        set {
            #if DEBUG
            UserDefaults.standard.set(newValue, forKey: DailyChallengeSession.testOffsetKey)
            #endif
            // The flag is inside each accessor rather than around them: Swift will not let
            // `#if` choose between two whole accessors of one property
        }
    }

    /// Whether walking out now would abandon a score that could still have counted.
    ///
    /// James, round 300: "quitting a daily should post the partial score - ask the user with a
    /// pop up, otherwise assume not." This is the question that decides whether the pop-up is
    /// worth asking, and all three parts of it matter: there has to *be* a daily running, it
    /// has to be the scoring attempt rather than free play, and the day has to still be open -
    /// a run that crossed midnight cannot post whatever the player answers (§1), so asking
    /// them would be offering something the boards will not take.
    var leavingWouldAbandonAScoringAttempt: Bool {
        guard let active, isScoringAttempt else { return false }
        return active.dateKey == todayKey
    }

    var todayKey: String { DailyDay.key(for: today) }
    var todaysChallenge: DailyChallenge { DailyChallengeGenerator.challenge(forKey: todayKey) }

    /// What a day's key is called on screen: "TODAY", "YESTERDAY", or its date.
    ///
    /// One answer for every screen that names a day - the briefing card, the pause
    /// summary, the level intro - so they cannot disagree about what today is called.
    func displayName(forKey key: String) -> String {
        if key == todayKey { return "TODAY" }
        if let date = DailyDay.date(forKey: key) {
            let yesterday = DailyDay.utcCalendar.date(byAdding: .day, value: -1, to: today)!
            if key == DailyDay.key(for: yesterday) { return "YESTERDAY" }

            let display = DateFormatter()
            display.dateStyle = .full
            display.timeZone = TimeZone(identifier: "UTC")
            display.locale = .autoupdatingCurrent
            return display.string(from: date).uppercased()
        }
        return key
    }
}
