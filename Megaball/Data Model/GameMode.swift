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

    /// Classic mode's row icon: the app's own artwork, cut to a circle with the same pale
    /// rim the other mode icons wear.
    ///
    /// Drawn rather than shipped as a second asset, so it cannot fall out of step with the
    /// app icon it is made from - when the icon changes, this changes with it. Round
    /// because the mode rows are a set (play-test round 15) and the app icon's own
    /// silhouette is a rounded square (round 16 asked for this exact compromise).
    static let classicIcon: UIImage? = {
        guard let source = appIconArtwork else { return UIImage(named: "ClassicIcon.png") }
        let side: CGFloat = 180
        let rim: CGFloat = 5
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
            let bounds = CGRect(x: 0, y: 0, width: side, height: side)
            let inner = bounds.insetBy(dx: rim, dy: rim)

            ctx.cgContext.saveGState()
            ctx.cgContext.addEllipse(in: inner)
            ctx.cgContext.clip()
            source.draw(in: inner)
            ctx.cgContext.restoreGState()
            // The icon is drawn *inside* the rim so the artwork is not cropped by it -
            // the ball and paddle stay whole, which they would not if the rim were laid
            // over a full-bleed drawing

            ctx.cgContext.setStrokeColor(UIColor(white: 0.92, alpha: 0.85).cgColor)
            ctx.cgContext.setLineWidth(rim)
            ctx.cgContext.strokeEllipse(in: inner)
        }
    }()

    /// The Daily Challenge's row icon: its calendar, drawn on the same disc the endless
    /// icon wears.
    ///
    /// The daily was showing its power-up badge here - a green rounded square, which is
    /// what every twist and pickup in the game looks like. Beside three round mode icons it
    /// read as a power-up that had wandered into the menu (play-test round 16). Drawn to
    /// match `EndlessIcon`: an olive disc, a pale sage rim, and the glyph in the same pale
    /// yellow with the same green glow behind it.
    static let dailyIcon: UIImage = {
        let side: CGFloat = 180
        let rim: CGFloat = 8
        let glyphColour = UIColor(red: 0.96, green: 1, blue: 0.85, alpha: 1)
        let glow = UIColor(red: 0.82, green: 1, blue: 0, alpha: 0.9)

        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { ctx in
            let c = ctx.cgContext
            let disc = CGRect(x: 0, y: 0, width: side, height: side).insetBy(dx: rim/2,
                                                                             dy: rim/2)
            let middle = CGPoint(x: side/2, y: side/2)

            c.saveGState()
            c.addEllipse(in: disc)
            c.clip()
            let shades = [UIColor(red: 0.28, green: 0.32, blue: 0.09, alpha: 1).cgColor,
                          UIColor(red: 0.42, green: 0.47, blue: 0.19, alpha: 1).cgColor]
            if let fill = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: shades as CFArray, locations: [0, 1]) {
                c.drawRadialGradient(fill, startCenter: middle, startRadius: 0,
                                     endCenter: middle, endRadius: side/2, options: [])
            }
            c.restoreGState()

            c.setStrokeColor(UIColor(red: 0.51, green: 0.55, blue: 0.42, alpha: 1).cgColor)
            c.setLineWidth(rim)
            c.strokeEllipse(in: disc)

            c.setShadow(offset: .zero, blur: side*0.09, color: glow.cgColor)
            c.setStrokeColor(glyphColour.cgColor)
            c.setFillColor(glyphColour.cgColor)
            c.setLineWidth(side*0.05)
            c.setLineJoin(.round)
            c.setLineCap(.round)

            let card = CGRect(x: side*0.28, y: side*0.34, width: side*0.44, height: side*0.38)
            c.stroke(card)
            c.move(to: CGPoint(x: card.minX, y: card.minY + card.height*0.3))
            c.addLine(to: CGPoint(x: card.maxX, y: card.minY + card.height*0.3))
            c.strokePath()
            for x in [card.minX + card.width*0.3, card.maxX - card.width*0.3] {
                c.move(to: CGPoint(x: x, y: card.minY))
                c.addLine(to: CGPoint(x: x, y: side*0.26))
                c.strokePath()
            }
            c.fillEllipse(in: CGRect(x: card.midX - side*0.065,
                                     y: card.midY + card.height*0.1 - side*0.065,
                                     width: side*0.13, height: side*0.13))
            // Today, burning in the middle of the month - the one mark that says this
            // calendar is about a particular day rather than about dates in general
        }
    }()

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
