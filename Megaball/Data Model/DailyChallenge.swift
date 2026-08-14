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

    /// §4.2's categories: a day draws at most one twist per category, which is what makes
    /// every combination the generator can produce legal by construction.
    enum Category: CaseIterable {
        case economy, lives, dress
    }

    var category: Category {
        switch self {
        case .oneLife, .loaded, .suddenDeath, .spareBalls: return .lives
        case .noPowerUps, .noGoodNews, .noBadNews, .powerShower, .drought: return .economy
        case .fogOfWar: return .dress
        }
    }

    var displayName: String {
        switch self {
        case .oneLife: return "One Life"
        case .loaded: return "Loaded"
        case .suddenDeath: return "Sudden Death"
        case .spareBalls: return "Spare Balls"
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
        case .spareBalls: return "Two balls in reserve - the run survives losing one."
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
        case .spareBalls:
            return mode == .endless || mode == .endlessII
            // The generous day for the modes whose baseline is a single ball - James's
            // suggestion from the first daily play test
        case .suddenDeath:
            return false
            // Parked, on the same play test: in the endless modes it was One Life said
            // twice, and in Classic (no Multi-Ball there) it is One Life by another name.
            // It comes back when a twist can put several balls in a Classic level -
            // Mayhem Rules (§4) - at which point "any ball lost ends the run" means
            // something One Life does not. The scene keeps its teeth ready either way
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

    /// The earliest day any pool entry activates - the first daily there ever was, and
    /// therefore the far end of the briefing screen's day browsing.
    static var firstActivationKey: String {
        allCases.map(\.activationKey).min() ?? "2026-08-01"
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
                               mode: GameMode) -> String? {
        guard isToday else {
            return "This challenge has closed.\nFree play scores are never posted."
        }
        guard let record, record.attemptCount > 0 else { return nil }
        if record.posted {
            return "Your score of \(scoreText(record.firstAttemptScore, mode: mode))"
                + " is on today's board.\nPlaying again won't post a new score."
        }
        return "Today's attempt is spent.\nThis run won't post a score."
    }

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
        mode == .classic ? StatsPage.grouped(score) : StatsPage.grouped(score) + "m"
    }
}

enum DailyChallengeBoards {
    /// The Game Center recurring leaderboard with a daily recurrence aligned to 00:00
    /// UTC (§7). Both boards are James's App Store Connect side; until they exist there,
    /// submissions fail silently - the same standing state as the Endless Mayhem boards.
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
