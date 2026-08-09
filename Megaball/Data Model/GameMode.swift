//
//  GameMode.swift
//  Megaball
//
//  Which of the three modes is being played.
//
//  The game has told the difference between its modes by looking at numbers - level 0 is
//  endless, level 999 is its generated field, `numberOfLevels == 1` is a single level.
//  That worked while there were two modes and the numbers happened to be distinct. It
//  does not survive a third mode that plays like the second but scores separately, has
//  its own leaderboards, and offers power-ups the others must never see.
//
//  So the mode is a thing now, and the questions that used to be asked of level numbers
//  are asked of it instead.
//

import UIKit

enum GameMode: Int, CaseIterable {
    case classic = 0
    case endless = 1
    /// Endless 2.0. Same shape as endless - one life, height for score - and everything
    /// else about it is new.
    case endlessII = 2
    /// The Daily Challenge (DAILY-CHALLENGE-SPECIFICATION.md). A menu identity, not a
    /// scene identity: a daily *plays* one of the other three modes with the day's twists,
    /// so the scene never sees this case - DailyChallengeSession is how it knows.
    case daily = 3

    /// Where the mode is remembered between launches, so a resumed run knows what it is.
    static let defaultsKey = "gameMode"

    /// The app's own icon, as artwork *inside* the app - the About screen, the Vanilla
    /// twist's badge, and Classic mode's own icon, which is the app icon by design.
    ///
    /// Taken from the icon selector's preview art, which is drawn from the same source as
    /// the real icon and is the one copy of it the app can actually load: the `.icon`
    /// bundles Icon Composer produces are layered sources, not images, and nothing can
    /// read them at runtime.
    static let appIconArtwork = UIImage(named: "IconPreviewPurple")

    /// The icon this mode wears wherever it introduces itself: the main menu's row, the
    /// level intro splash, the pause and game-over screens, and the daily briefing.
    ///
    /// One definition, because play-testing kept asking for the icon in one more place and
    /// each place was choosing its own artwork - which is how the daily briefing and the
    /// main menu ended up able to disagree about what a Daily Challenge looks like.
    static func menuIcon(for mode: GameMode) -> UIImage? {
        switch mode {
        case .classic: return UIImage(named: "ClassicIcon.png")
        // Round rather than the app icon's rounded square (play-test round 15): the mode
        // rows are a set, and one of them wearing a different silhouette breaks the set.
        // The app icon still appears as itself on the About screen and the Vanilla badge
        case .endless, .endlessII: return UIImage(named: "EndlessIcon.png")
        // Endless 2.0 shares the endless icon until §8.5 draws it one of its own
        case .daily: return PowerUpIcon.dailyChallenge
        }
    }

    var name: String {
        switch self {
        case .classic: return "Classic Mode"
        case .endless: return "Endless Mode"
        case .endlessII: return "Endless Mayhem"
        // Renamed from "Endless 2.0" in play-testing - every screen reads this, so the
        // rename is this line
        case .daily: return "Daily Challenge"
        }
    }

    /// Whether the field descends and the score is height, rather than levels and points.
    var isEndless: Bool {
        self == .endless || self == .endlessII
    }

    /// Which power-ups this mode offers, which is what keeps Endless 2.0's additions out
    /// of the modes people already have scores in.
    var powerUpAvailability: PowerUpAvailability {
        self == .endlessII ? .endlessII : .allModes
    }

    /// Whether scores post to the same leaderboards as the original mode.
    ///
    /// They do not. Endless 2.0 is not comparable to Endless - different bricks, different
    /// power-ups - so it gets its own board rather than diluting one people have been
    /// climbing for years.
    var sharesLeaderboardsWithEndless: Bool { self == .endless }

    /// Endless 2.0's Game Center boards.
    ///
    /// These have to exist in App Store Connect before scores will post; until they do,
    /// submission fails silently, which is the same as not submitting.
    static let endlessIIBestHeightLeaderboard = "leaderboardEndless2BestHeight"
    static let endlessIITotalHeightLeaderboard = "leaderboardEndless2TotalHeight"

    /// The mode a run belongs to, as stored.
    static func current(in defaults: UserDefaults = .standard) -> GameMode {
        GameMode(rawValue: defaults.integer(forKey: defaultsKey)) ?? .classic
    }

    func makeCurrent(in defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: GameMode.defaultsKey)
    }
}
