//
//  StatsPage.swift
//  Megaball
//
//  What the statistics screen says, worked out away from the screen that says it.
//
//  The page used to be one list of twenty-five rows built inside `cellForRowAt`, with each row
//  deciding for itself whether it had anything to show and blanking itself if not. That made
//  three problems. Rows for a mode you have never played still took up a line; the blanking
//  worked by setting the *table's* row height to zero, which is a property of the whole table
//  and not of one row; and there was nowhere to put a number without also picking where in a
//  fixed list of twenty-five it went.
//
//  So the page is a list of sections now - Overall plus one per mode (play-test round 11) - and
//  the rows are values rather than table cells, which means they can be checked without a
//  screen. A row that has nothing to say is not added, rather than added and then hidden.
//
//  **Which stat belongs to which tab is not a guess.** It is read off where the game writes it:
//  `InbewteenLevels` updates `cumulativeScore`, `levelsPlayed`, `levelsCompleted`, `packsPlayed`
//  and `packsCompleted` only on the branch that is not an endless run, so those are Classic's.
//  It updates `playTimeSecs`, the ball and brick counts, the power-up counts and the lasers on
//  every branch, so those are everybody's and live under Overall. The heights are already kept
//  in two separate arrays because Endless and Endless Mayhem are different games.
//

import Foundation

enum StatsPage {

    /// The sections, in the order their tabs appear.
    ///
    /// Overall first because it is the page that existed before this one, and the one a player
    /// arriving without a mode in mind wants.
    enum Tab: Int, CaseIterable {
        case overall, classic, endless, mayhem, daily

        /// Short enough for five of them to sit across a phone. "Mayhem" rather than "Endless
        /// Mayhem" for that reason, and because it sits next to Endless, which supplies the
        /// missing word.
        var title: String {
            switch self {
            case .overall: return "All"
            case .classic: return "Classic"
            case .endless: return "Endless"
            case .mayhem: return "Mayhem"
            case .daily: return "Daily"
            }
        }
    }

    struct Row: Equatable {
        let label: String
        let value: String

        /// The SF Symbol drawn to the left of the row, or nothing.
        ///
        /// Named beside the label it belongs to rather than kept in a second list keyed by
        /// label, which would be a list to keep in step every time a row is renamed.
        ///
        /// Every name here is from the first two SF Symbols releases. The app runs on iOS 15
        /// and a symbol added later resolves to nothing at all on an older phone - it does not
        /// fail, it simply draws an empty gutter, which is exactly the sort of thing that is
        /// invisible on a modern simulator.
        let icon: String?

        init(label: String, value: String, icon: String? = nil) {
            self.label = label
            self.value = value
            self.icon = icon
        }
    }

    /// Shown in place of a section's rows when that mode has never been played.
    ///
    /// The same sentence the page has always shown when there was nothing at all, rather than a
    /// new one: a player who has played Classic and not Mayhem should meet a familiar empty
    /// page, not a different kind of nothing.
    static let nothingYet = Row(label: "No statistics available", value: "")

    static func rows(for tab: Tab, stats: TotalStats) -> [Row] {
        let rows: [Row]
        switch tab {
        case .overall: rows = overallRows(stats)
        case .classic: rows = classicRows(stats)
        case .endless: rows = heightRows(stats.endlessModeHeight)
        case .mayhem: rows = heightRows(stats.endlessIIHeights)
        case .daily: rows = dailyRows(stats)
        }
        return rows.isEmpty ? [nothingYet] : rows
    }

    // MARK: - The sections

    private static func overallRows(_ stats: TotalStats) -> [Row] {
        guard hasPlayedAnything(stats) else { return [] }

        var rows = [Row(label: "Total play time", value: playTime(stats.playTimeSecs), icon: "clock")]

        rows.append(Row(label: "Ball hits", value: grouped(stats.ballHits), icon: "circle.fill"))
        rows.append(Row(label: "Balls lost", value: grouped(stats.ballsLost), icon: "arrow.down.circle"))
        rows.append(Row(label: "Bricks hit", value: grouped(stats.bricksHit.reduce(0, +)), icon: "rectangle"))
        rows.append(Row(label: "Bricks destroyed", value: grouped(stats.bricksDestroyed.reduce(0, +)), icon: "rectangle.fill"))

        let released = stats.powerupsGenerated.reduce(0, +)
        let collected = stats.powerupsCollected.reduce(0, +)
        rows.append(Row(label: "Power-ups released", value: grouped(released), icon: "arrow.up.circle"))
        rows.append(Row(label: "Power-ups collected", value: grouped(collected), icon: "checkmark.circle"))
        rows.append(Row(label: "Power-up collection rate",
                        value: percentage(collected, of: released), icon: "percent"))

        // The lasers only appear once one has been fired. They are a power-up rather than a
        // part of the game everybody meets, and a permanent "Lasers fired 0" reads as a broken
        // counter rather than as something not yet found
        if stats.lasersFired > 0 {
            rows.append(Row(label: "Lasers fired", value: grouped(stats.lasersFired), icon: "bolt.fill"))
            rows.append(Row(label: "Lasers hit", value: grouped(stats.lasersHit), icon: "scope"))
        }

        let unlockedItems = stats.appIconUnlockedArray.filter { $0 }.count
            + stats.powerUpUnlockedArray.filter { $0 }.count
            + stats.themeUnlockedArray.filter { $0 }.count
        let allItems = stats.appIconUnlockedArray.count
            + stats.powerUpUnlockedArray.count
            + stats.themeUnlockedArray.count
        rows.append(Row(label: "Items unlocked", value: fraction(unlockedItems, allItems), icon: "lock.open.fill"))
        rows.append(Row(label: "Achievements completed",
                        value: fraction(stats.achievementsUnlockedArray.filter { $0 }.count,
                                        stats.achievementsUnlockedArray.count),
                        icon: "rosette"))
        return rows
    }

    private static func classicRows(_ stats: TotalStats) -> [Row] {
        guard stats.levelsPlayed > 0 else { return [] }

        // The two subtractions are the page's oldest arithmetic and they are not off-by-one
        // errors: the level array carries a leading entry that is not a level, and the pack
        // array two that are not packs
        let unlockedLevels = stats.levelUnlockedArray.filter { $0 }.count - 1
        let allLevels = stats.levelUnlockedArray.count - 1
        let unlockedPacks = stats.levelPackUnlockedArray.filter { $0 }.count - 2
        let allPacks = stats.levelPackUnlockedArray.count - 2

        return [
            Row(label: "Total score", value: grouped(stats.cumulativeScore), icon: "star.fill"),
            Row(label: "Packs unlocked", value: fraction(unlockedPacks, allPacks), icon: "lock.open.fill"),
            Row(label: "Packs played", value: grouped(stats.packsPlayed), icon: "square.stack.fill"),
            Row(label: "Packs completed", value: grouped(stats.packsCompleted), icon: "checkmark.seal.fill"),
            Row(label: "Pack completion rate",
                value: percentage(stats.packsCompleted, of: stats.packsPlayed), icon: "percent"),
            Row(label: "Levels unlocked", value: fraction(unlockedLevels, allLevels), icon: "lock.open"),
            Row(label: "Levels played", value: grouped(stats.levelsPlayed), icon: "square.stack"),
            Row(label: "Levels completed", value: grouped(stats.levelsCompleted), icon: "checkmark.circle.fill"),
            Row(label: "Level completion rate",
                value: percentage(stats.levelsCompleted, of: stats.levelsPlayed), icon: "percent"),
        ]
    }

    /// Endless and Endless Mayhem keep the same four numbers about different arrays.
    ///
    /// One function rather than two sections written out twice: they are the same questions,
    /// and the moment they are two copies one of them gets a fifth row and the other does not.
    private static func heightRows(_ heights: [Int]) -> [Row] {
        guard heights.isEmpty == false else { return [] }
        let total = heights.reduce(0, +)
        return [
            Row(label: "Runs played", value: grouped(heights.count), icon: "play.circle.fill"),
            Row(label: "Best height", value: grouped(heights.max() ?? 0) + " m", icon: "arrow.up"),
            Row(label: "Total height", value: grouped(total) + " m", icon: "sum"),
            Row(label: "Average height", value: grouped(total/heights.count) + " m", icon: "chart.bar.fill"),
        ]
    }

    private static func dailyRows(_ stats: TotalStats) -> [Row] {
        let records = stats.dailyRecords
        guard records.isEmpty == false else { return [] }

        var rows = [
            Row(label: "Days played", value: grouped(records.count), icon: "calendar"),
            Row(label: "Days posted", value: grouped(records.filter { $0.posted }.count), icon: "arrow.up.circle.fill"),
            Row(label: "Attempts", value: grouped(records.reduce(0) { $0 + $1.attemptCount }), icon: "arrow.clockwise"),
        ]

        // The counting attempt is the first one, so the best day is the best first attempt -
        // a practice score is higher more often than not and would flatter the number
        if let best = records.map({ $0.firstAttemptScore }).max(), best > 0 {
            rows.append(Row(label: "Best day score", value: grouped(best), icon: "star.fill"))
        }
        rows.append(Row(label: "Total posted score", value: grouped(stats.dailyTotalPostedScore), icon: "sum"))
        return rows
    }

    // MARK: - Formatting

    static func hasPlayedAnything(_ stats: TotalStats) -> Bool {
        stats.levelsPlayed > 0
            || stats.endlessModeHeight.isEmpty == false
            || stats.endlessIIHeights.isEmpty == false
            || stats.dailyRecords.isEmpty == false
    }

    /// Play time in the units it has always been shown in.
    ///
    /// Minutes until an hour, then whole hours - and anything under two minutes reads "1
    /// minute" rather than "0 minutes", because a first level takes less than sixty seconds and
    /// being told you have played for no time at all is wrong in the way that matters.
    static func playTime(_ seconds: Int) -> String {
        if seconds <= 120 { return "1 minute" }
        if seconds <= 3600 { return String(seconds/60) + " minutes" }
        let hours = seconds/3600
        return String(hours) + (hours == 1 ? " hour" : " hours")
    }

    /// A whole-number percentage, with nothing-out-of-nothing reading as 0% rather than as the
    /// word "nan" - which is what a plain division prints when a mode has been played zero times
    static func percentage(_ part: Int, of whole: Int) -> String {
        guard whole > 0 else { return "0%" }
        return String(format: "%.0f", Double(part)/Double(whole)*100.0) + "%"
    }

    static func fraction(_ part: Int, _ whole: Int) -> String {
        String(part) + "/" + String(whole)
        // Not grouped: a fraction is two small numbers read as one thing, and separators in
        // "38/74" would be dividing something already divided
    }

    /// A count, with the reader's own thousands separator in it.
    ///
    /// **This page only.** A lifetime brick count runs to six or seven digits and "1234567" has
    /// to be counted rather than read. The score in the game does *not* get this treatment and
    /// must not: it is a number that changes several times a second, and a separator appearing
    /// and disappearing as it crosses a thousand is movement in a place the eye is already
    /// watching. The scene draws its numbers through `FixedWidthNumberNode` and knows nothing
    /// about this function.
    ///
    /// The separator is the reader's, not a comma: a German player's thousands separator is a
    /// full stop, and hard-coding a comma would print a decimal point in the middle of their
    /// brick count.
    static func grouped(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
