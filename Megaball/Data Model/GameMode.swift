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

import Foundation

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
