//
//  AchievementCatalogue.swift
//  Megaball
//
//  Which mode each achievement belongs to, so the achievements page can be read the way
//  the statistics page is - one section per mode (play-test round 126: "use tab bar in
//  achievements view").
//
//  The answer is not a matter of taste: an achievement belongs to the modes it can actually
//  be *earned* in, and that is written down already in the checks that award them. This file
//  is that reading, made once, with the guard that decides it named beside every entry - so a
//  future reader can confirm an entry against the check rather than against an opinion.
//
//  Three rules cover all sixty-six:
//
//  - A check guarded by `endlessMode` belongs to **both** endless modes. `endlessMode` is
//    true in Endless and in Endless Mayhem; only `gameMode == .endlessII` separates them, and
//    none of these checks asks that.
//  - A check guarded by `endlessMode == false`, or one living in the between-levels pass that
//    only a campaign run reaches, belongs to **Classic**.
//  - A check with no mode guard at all - the power-up and paddle ones, which happen wherever
//    the ball is - belongs to **all three**.
//
//  The daily has none, and that is a rule rather than an oversight: `achievementsCheck()`
//  returns early for a daily, because a daily played on a level someone has not earned must
//  not unlock what earning it would have (daily spec §9). Its own set arrives with phase 5.
//

import Foundation

enum AchievementCatalogue {

    /// The modes an achievement can be earned in.
    ///
    /// A set rather than a single mode, because most of them are honestly more than one:
    /// "Beach Ball" is a power-up on a paddle and does not care which mode the paddle is in.
    static func modes(for index: Int) -> Set<GameMode> {
        if endlessOnly.contains(index) { return [.endless, .endlessII] }
        if classicOnly.contains(index) { return [.classic] }
        return [.classic, .endless, .endlessII]
    }

    /// Whether an achievement is offered under a tab.
    ///
    /// `.daily` is answered false for every achievement, from the one rule above rather than
    /// from a list of exceptions.
    static func belongs(_ index: Int, to mode: GameMode) -> Bool {
        mode == .daily ? false : modes(for: index).contains(mode)
    }

    /// The indices shown under a mode, in the order the arrays hold them.
    static func indices(for mode: GameMode?, count: Int) -> [Int] {
        guard let mode else { return Array(0..<count) }
        return (0..<count).filter { belongs($0, to: mode) }
    }

    /// Earned only in an endless run: the height and duration milestones, and clearing the
    /// field. Guarded by `endlessHeight`, `endlessModeDurationCheck` or `endlessMode` in
    /// `GameScene`, and by `scene.endlessMode` in the between-levels pass for the two totals.
    static let endlessOnly: Set<Int> = [
        0, 1, 2, 3,   // 10m, 100m, 500m, 1,000m - endlessHeight, either endless mode
        4, 5,         // 5,000m and 10,000m total height
        17, 18, 19, 20, 21,  // the duration milestones
        22,           // Tidying Up - `endlessMode && bricksLeft == 0`
    ]

    /// Earned only in a campaign run: everything about levels and packs, and the four checks
    /// that name `endlessMode == false` outright.
    static let classicOnly: Set<Int> = [
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,  // the eleven pack completions
        26,                       // Didn't Even Need It - `endlessMode == false`
        36, 37,                   // balls lost across a level
        38, 39,                   // every power-up on a level, and none
        40,                       // Giga-Speedy - a level under a minute
        41, 42,                   // paddle hits on a level - `endlessMode == false`
        43, 44,                   // points on one level
        45, 46, 47, 48, 49,       // levels completed
        51, 52, 53,               // total score - `endlessMode == false`
        54, 55, 56, 57, 58,       // a pack's balls, power-ups and time
        59, 60, 61,               // points on one pack
        62, 63, 64, 65,           // packs completed
    ]

    /// The tabs the page offers, in the statistics page's order and words.
    ///
    /// Nil is the "All" tab. The daily is included deliberately even though nothing is filed
    /// under it: the page says why, which is worth more than a missing tab that reads as an
    /// oversight.
    static let tabs: [(title: String, mode: GameMode?)] = [
        ("All", nil), ("Classic", .classic), ("Endless", .endless),
        ("Mayhem", .endlessII), ("Daily", .daily),
    ]

    /// What an empty tab says, in its own words rather than a shrug.
    static func emptyNote(for mode: GameMode?) -> String {
        mode == .daily
            ? "The daily challenge has no achievements of its own yet - a day played on a "
                + "level you have not earned must not unlock what earning it would have."
            : "Nothing here yet."
    }
}
