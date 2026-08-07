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
}

// MARK: - Twists

/// A named, self-describing rule change (§4). The raw value is the persistence and
/// pool-identity name - append-only, never renamed.
enum DailyTwist: String, CaseIterable, Codable {
    case oneLife, loaded, suddenDeath
    case noPowerUps, noGoodNews, noBadNews, powerShower, drought
    case fogOfWar

    /// §4.2's categories: a day draws at most one twist per category, which is what makes
    /// every combination the generator can produce legal by construction.
    enum Category: CaseIterable {
        case economy, lives, dress
    }

    var category: Category {
        switch self {
        case .oneLife, .loaded, .suddenDeath: return .lives
        case .noPowerUps, .noGoodNews, .noBadNews, .powerShower, .drought: return .economy
        case .fogOfWar: return .dress
        }
    }

    var displayName: String {
        switch self {
        case .oneLife: return "One Life"
        case .loaded: return "Loaded"
        case .suddenDeath: return "Sudden Death"
        case .noPowerUps: return "No Power-Ups"
        case .noGoodNews: return "No Good News"
        case .noBadNews: return "No Bad News"
        case .powerShower: return "Power Shower"
        case .drought: return "Drought"
        case .fogOfWar: return "Fog of War"
        }
    }

    var blurb: String {
        switch self {
        case .oneLife: return "One life. Make it count."
        case .loaded: return "Five lives. Spend them well."
        case .suddenDeath: return "Any ball lost ends the run - every ball, every mode."
        case .noPowerUps: return "Nothing drops. Just you and the bricks."
        case .noGoodNews: return "Only the bad power-ups drop. Don't catch them."
        case .noBadNews: return "Only the good power-ups drop. Catch everything."
        case .powerShower: return "Power-ups everywhere."
        case .drought: return "Power-ups are very rare today."
        case .fogOfWar: return "Every brick is invisible until it is first struck."
        }
    }

    /// Which modes the twist can be drawn for.
    func applies(to mode: GameMode) -> Bool {
        switch self {
        case .oneLife, .loaded:
            return mode == .classic
            // The endless modes already have exactly one life
        default:
            return true
        }
    }

    /// The date this twist may first be offered (§2.1). Append-only.
    var activationKey: String {
        "2026-08-01"
        // The launch pool activates together; later twists carry later dates
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
}

// MARK: - The challenge

/// A day's challenge, frozen: what the generator drew, and nothing that changes after.
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
    static func challenge(forKey key: String) -> DailyChallenge {
        var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: key))

        // 1. The mode: Classic 50, Endless 25, Mayhem 25 (§3)
        let modeRoll = stream.roll(100)
        let mode: GameMode = modeRoll < 50 ? .classic : (modeRoll < 75 ? .endless : .endlessII)

        // 2. The level, drawn whether or not it is used - every draw always happens, in the
        // same order, so the stream's layout never depends on earlier outcomes and adding a
        // pool later cannot shift what an old date drew (§2.1)
        let levelRoll = stream.roll(max(1, classicLevelCount))
        let classicLevel: Int? = mode == .classic ? levelRoll + 1 : nil

        // 3. How many twists: none 30, one 50, two 20 (§3)
        let countRoll = stream.roll(100)
        let twistCount = countRoll < 30 ? 0 : (countRoll < 80 ? 1 : 2)

        // 4. The twists: a category first, then a twist inside it, both weighted - at most
        // one per category, so the set is legal by construction (§4.2)
        var twists: [DailyTwist] = []
        var categories = DailyTwist.Category.allCases
        for _ in 0..<twistCount {
            guard categories.isEmpty == false else { break }
            let category = categories.remove(at: stream.roll(categories.count))
            let pool = DailyTwist.allCases.filter {
                $0.category == category && $0.applies(to: mode) && $0.activationKey <= key
            }
            guard pool.isEmpty == false else { continue }

            let total = pool.reduce(0) { $0 + $1.weight }
            var drawn = stream.roll(total)
            for twist in pool {
                drawn -= twist.weight
                if drawn < 0 { twists.append(twist); break }
            }
        }

        return DailyChallenge(dateKey: key, mode: mode, classicLevel: classicLevel,
                              twists: twists)
    }

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

    func has(_ twist: DailyTwist) -> Bool { active?.has(twist) ?? false }

    /// The date the daily screens consider "today".
    ///
    /// Real UTC now - unless the test clock has been set, which is the play-test rig the
    /// whole feature needs: days are the unit of content here, and waiting a real day per
    /// test is not a test plan. The simulated date persists across launches so a tester
    /// can stay on a day, and the briefing screen labels it loudly. Remove-before-release
    /// is tracked in the spec's build phases.
    var today: Date {
        if let offset = UserDefaults.standard.object(forKey: DailyChallengeSession.testOffsetKey) as? Int,
           offset != 0 {
            return DailyDay.utcCalendar.date(byAdding: .day, value: offset, to: Date())!
        }
        return Date()
    }

    static let testOffsetKey = "dailyChallengeTestDayOffset"

    /// How many days the test clock is wound forward or back. Zero is live.
    var testDayOffset: Int {
        get { UserDefaults.standard.integer(forKey: DailyChallengeSession.testOffsetKey) }
        set { UserDefaults.standard.set(newValue, forKey: DailyChallengeSession.testOffsetKey) }
    }

    var todayKey: String { DailyDay.key(for: today) }
    var todaysChallenge: DailyChallenge { DailyChallengeGenerator.challenge(forKey: todayKey) }
}
