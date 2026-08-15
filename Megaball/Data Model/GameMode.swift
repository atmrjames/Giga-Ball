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

    /// Classic mode's row icon, as drawn.
    ///
    /// It used to be *made* here - the app icon's artwork clipped to a circle with a pale rim
    /// stroked round it - so it could never fall out of step with the app icon itself. James
    /// has drawn one instead (round 131), and a supplied icon goes in as supplied: the rim
    /// the code added was a border he never asked for, and reading the asset is how the other
    /// three mode icons already work.
    static let classicIcon: UIImage? = UIImage(named: "ClassicIcon")

    /// The Daily Challenge's row icon, as drawn.
    ///
    /// Drawn in code until round 131 for the same reason and with the same result - the
    /// calendar on an olive disc was a stand-in for artwork that did not exist yet. It does
    /// now.
    static let dailyIcon: UIImage? = UIImage(named: "DailyIcon")

    /// The icon this mode wears wherever it introduces itself: the main menu's row, the
    /// level intro splash, the pause and game-over screens, and the daily briefing.
    ///
    /// One definition, because play-testing kept asking for the icon in one more place and
    /// each place was choosing its own artwork - which is how the daily briefing and the
    /// main menu ended up able to disagree about what a Daily Challenge looks like.
    static func menuIcon(for mode: GameMode) -> UIImage? {
        switch mode {
        case .classic: return classicIcon
        // Round rather than the app icon's rounded square (play-test round 15): the mode
        // rows are a set, and one of them wearing a different silhouette breaks the set
        case .endless: return UIImage(named: "EndlessIcon.png")
        case .endlessII: return UIImage(named: "Endless2Icon.png")
        // Mayhem has one of its own now (§8.5, drawn by James in round 130) - the two modes
        // shared the endless icon until it existed, which is why the daily card and the
        // menus all ask this one function rather than naming an asset each
        case .daily: return dailyIcon
        // Round like the rest of the set, not the power-up badge it used to borrow
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
