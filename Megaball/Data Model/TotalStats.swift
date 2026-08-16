//
//  TotalStats.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import GameKit

/// Whether to greet a player who has just updated, and what to say.
///
/// **Lives in this file rather than its own** for the reason the glass helpers do: a new file
/// means four hand-edits to `project.pbxproj`, and this is thirty lines. Both moves are
/// queued together.
enum WhatsNew {

    /// Where the last version the player was shown is kept.
    static let seenKey = "lastSeenAppVersion"

    /// The release this note is about. Compared as a string on purpose - the note is written
    /// for one release, and the next one will want different words anyway.
    static let version = "1.3"

    /// Whether this launch should show the note.
    ///
    /// - Parameters:
    ///   - seen: the version last shown, or nil.
    ///   - current: the version running now.
    ///   - hasPlayedBefore: whether there is any progress on this device.
    ///
    /// **The awkward case is the one that matters.** Version 1.2 never wrote this key, so a
    /// player updating from it arrives with nothing stored - exactly like a fresh install.
    /// The two are told apart by whether they have played: somebody with levels behind them
    /// updated, somebody with none has just arrived and has nothing to be told is new.
    static func shouldShow(seen: String?, current: String, hasPlayedBefore: Bool) -> Bool {
        guard current == version else { return false }
        // Only for the release it was written about. A 1.4 build must not show 1.3's note
        // just because the key still says 1.2

        guard let seen else { return hasPlayedBefore }
        return seen != current
    }

    /// What it says.
    static let title = "What's New in 1.3"
    static let message = """
        Endless Mayhem, a second endless mode with twenty-three power-ups of its own and         bricks that move, spin, explode and send the ball elsewhere.

        A Daily Challenge that changes every day, with its own leaderboard.

        Statistics worth reading, split by mode, and a new look throughout.
        """
}

class TotalStats: Codable {
    
    var dateSaved: Date = Date(timeIntervalSinceReferenceDate: 0.0) // Seconds since 00:00:00 UTC on 01/01/2001
    var cumulativeScore: Int = 0
    var levelsPlayed: Int = 0
    var levelsCompleted: Int = 0
    var ballHits: Int = 0
    var ballsLost: Int = 0

    /// The most paddle hits a single ball has ever survived.
    ///
    /// The *average* needs no storage - `ballHits/ballsLost` is it - but a maximum cannot be
    /// derived from totals, so it has to be kept. Optional for the same decode-safety reason
    /// the Endless 2.0 and daily fields are: this file is decoded with the synthesised
    /// initialiser, and a stats file written before this existed would fail to decode
    /// outright, which is every player's history gone.
    var bestBallHits: Int?

    /// The best run of hits on one ball, with the absent-means-none case handled.
    var longestBallRun: Int { bestBallHits ?? 0 }
    var powerupsCollected: [Int] = Array(repeating: 0, count: 59)
    var powerupsGenerated: [Int] = Array(repeating: 0, count: 59)
    // One slot per power-up, in power-up order. Sized by count rather than written out,
    // because the literal was miscounted once already - and every new power-up grows this,
    // the unlock array below, and the iCloud copies in CloudKitHandler together
    /// Metres climbed while each power-up was running, one slot per power-up, per endless
    /// mode. The stats page has a tab each, so they are counted apart.
    ///
    /// **Every power-up active at the moment a metre is scored gets the whole metre**, so
    /// these sum to more than the height climbed. That is deliberate and James's call: the
    /// page says *while active*, not *because of*, which is honest about it being
    /// correlation - splitting a metre between three running power-ups would invent a
    /// precision the measurement does not have.
    ///
    /// The instant power-ups - Cull, Infill, Wipe - score nothing, and need no rule to make
    /// that happen: they are never *running*, so they are never in the active set this counts
    /// from. Clear And Retreat runs now (round 136) and still scores nothing, for a reason of
    /// its own: it holds the field, and a field that is not descending is not climbing either,
    /// so there are no metres to attribute while it lasts.
    ///
    /// Optional for the same decode-safety reason `bestBallHits` is: a stats file written
    /// before this existed must still decode, or it is every player's history gone.
    var endlessPowerUpMetres: [Int]?
    var endlessIIPowerUpMetres: [Int]?

    /// The metres array for a mode, absent-means-none handled, always full length.
    func powerUpMetres(inMayhem: Bool) -> [Int] {
        let stored = inMayhem ? endlessIIPowerUpMetres : endlessPowerUpMetres
        return TotalStats.padded(stored ?? [], like: TotalStats.freshPowerUpMetres)
    }

    /// Credits one metre to every power-up in `indices`, for one mode.
    func creditMetre(to indices: some Sequence<Int>, inMayhem: Bool) {
        var metres = powerUpMetres(inMayhem: inMayhem)
        for index in indices where metres.indices.contains(index) {
            metres[index] += 1
        }
        if inMayhem { endlessIIPowerUpMetres = metres } else { endlessPowerUpMetres = metres }
    }

    /// An empty set of slots, sized off the same count everything else here is.
    static var freshPowerUpMetres: [Int] { Array(repeating: 0, count: TotalStats().powerupsCollected.count) }

    /// How long has been spent in each mode, in seconds.
    ///
    /// `playTimeSecs` has counted the whole game since 2020 and still does; these split the
    /// same seconds four ways, so a player can see where their hours actually went (play-test
    /// round 85). Credited from the one place that already knew a level had ended and how
    /// long it took, so the four always sum to what the total would have counted.
    ///
    /// Optional for the decode-safety reason `endlessPowerUpMetres` gives above: a stats file
    /// written before these existed must still decode. A mode that has never been played is
    /// `nil` rather than zero, which is also what lets the page leave its row out rather than
    /// print a play time of none.
    var classicPlayTimeSecs: Int?
    var endlessPlayTimeSecs: Int?
    var endlessIIPlayTimeSecs: Int?
    var dailyPlayTimeSecs: Int?

    /// How long each endless run lasted, in seconds, in the order the runs were played.
    ///
    /// Beside the heights rather than inside them, and read the same way the dates are: paired
    /// from the **end**, because a player from before this existed has more heights than
    /// durations and the runs missing a duration are the old ones (the round-21 date bug, and
    /// its fix, are the standing lesson here - see `LevelStatsViewController.pair`).
    var endlessModeDurations: [Int]?
    var endlessIIDurations: [Int]?

    /// Adds a run's seconds to the mode that was being played.
    func creditPlayTime(_ seconds: Int, mode: GameMode, isDailyChallenge: Bool) {
        guard seconds > 0 else { return }
        if isDailyChallenge {
            dailyPlayTimeSecs = (dailyPlayTimeSecs ?? 0) + seconds
            return
            // A daily is its own game whatever field it borrows (daily spec §9), so its
            // seconds are its own rather than the mode it was generated from
        }
        switch mode {
        case .endless: endlessPlayTimeSecs = (endlessPlayTimeSecs ?? 0) + seconds
        case .endlessII: endlessIIPlayTimeSecs = (endlessIIPlayTimeSecs ?? 0) + seconds
        default: classicPlayTimeSecs = (classicPlayTimeSecs ?? 0) + seconds
        }
    }

    /// Notes how long an endless run lasted, against the mode it was run in.
    func recordRunDuration(_ seconds: Int, inMayhem: Bool) {
        if inMayhem {
            endlessIIDurations = (endlessIIDurations ?? []) + [seconds]
        } else {
            endlessModeDurations = (endlessModeDurations ?? []) + [seconds]
        }
    }

    var bricksHit: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var bricksDestroyed: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var lasersFired: Int = 0
    var lasersHit: Int = 0
    var playTimeSecs: Int = 0
    var packsPlayed: Int = 0
    var packsCompleted: Int = 0
    
    var packHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0,0]
    var packBestTimes: [Int] = [0,0,0,0,0,0,0,0,0,0,0]
    
    var pack1LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack2LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack3LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack4LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack5LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack6LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack7LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack8LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack9LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack10LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    var pack11LevelHighScores: [Int] = [0,0,0,0,0,0,0,0,0,0]
    
    var endlessModeHeight: [Int] = []
    var endlessModeHeightDate: [Date] = []

    /// Endless 2.0's runs, kept apart from the original mode's.
    ///
    /// A different game - different bricks, different power-ups - so mixing its heights
    /// into the array above would rewrite the history of a mode people have been playing
    /// for years, and make the average meaningless.
    ///
    /// Optional because this file is decoded with the synthesised initialiser, which
    /// requires every non-optional key to be present. A stats file written before these
    /// existed would fail to decode outright, which is every player's stats gone.
    var endlessIIModeHeight: [Int]?
    var endlessIIModeHeightDate: [Date]?

    /// Endless 2.0's runs, with the absent-means-none case already handled.
    var endlessIIHeights: [Int] { endlessIIModeHeight ?? [] }

    /// The Daily Challenge's per-day records (daily spec §10), one per UTC date played.
    /// Optional for the same decode-safety reason as the Endless 2.0 fields above.
    var dailyChallengeRecords: [DailyChallengeRecord]?

    /// The records with the absent-means-none case already handled.
    var dailyRecords: [DailyChallengeRecord] { dailyChallengeRecords ?? [] }

    func dailyRecord(forKey key: String) -> DailyChallengeRecord? {
        dailyRecords.first { $0.dateKey == key }
    }

    /// Writes a day's record in place, or adds it. One record per date, always.
    func upsertDailyRecord(_ record: DailyChallengeRecord) {
        var records = dailyRecords
        if let index = records.firstIndex(where: { $0.dateKey == record.dateKey }) {
            records[index] = record
        } else {
            records.append(record)
            records.sort { $0.dateKey < $1.dateKey }
        }
        dailyChallengeRecords = records
    }

    /// The overall board's source of truth (daily spec §7): the running total of every
    /// posted day's normalised score. Derived, never stored - a second copy of a total
    /// is wrong the first time a record changes.
    ///
    /// Only days that actually *landed* count (§12.5): a pending day joins the moment
    /// its post is confirmed, and a missed one never does.
    var dailyTotalPostedScore: Int {
        dailyRecords.reduce(0) { $0 + ($1.posted ? $1.postedNormalisedScore : 0) }
    }
    
    var levelPackUnlockedArray: [Bool] = [
        true, // Tutorial
        true, // Endless Mode
        true, // Classic
        true, // Space
        true, // Nature
        false, // City
        false, // Food
        false, // Computer
        false, // Body
        false, // World
        false, // Emoji
        false, // Numbers
        false // Challenge
    ]
        
    var themeUnlockedArray: [Bool] = [
        true, // Classic
        false, // 3D
        false, // Ice
        false, // Outline
        false, // Square
        false, // Glass
        false, // Pixel
        false, // Split
        false, // Candy
        false, // Giga
        false, // Rainbow
        false // Retro
    ]
    
    var appIconUnlockedArray: [Bool] = [
        true, // Purple
        false, // White
        false, // Yellow
        false, // Orange
        false, // Green
        false, // Blue
        false, // Brown
        false, // Black
        false, // Pink
        false, // Giga-Ball
        false, // Rainbow
        false // Retro
    ]
    
    var levelUnlockedArray: [Bool] = [
        
        true, // Endless mode
        
        // Classic Pack
        true, // Checkers
        false, // Electric Fence
        false, // Gateway
        false, // Surfer's Paradise
        false, // Chevron
        false, // Vignette
        false, // Cluster
        false, // Vertical Challenge
        false, // Horizontal Challenge
        false, // X Marks The Spot
        
        // Space Pack
        true, // Cresent Moon
        false, // Invader
        false, // Constellation
        false, // Star
        false, // Rocket
        false, // Galaxy
        false, // Meteor Shower
        false, // Neptune
        false, // Saturn
        false, // Meteorite

        // Nature Pack
        true, // Leaf
        false, // Rainbow
        false, // Egg
        false, // Tree
        false, // Sunset
        false, // Apple
        false, // Flower
        false, // Birds
        false, // Germ
        false, // Butterfly
        
        // City Pack
        false, // City Map
        false, // Skyscraper
        false, // Subway
        false, // Cottage
        false, // Traffic Light
        false, // Finance
        false, // Apartments
        false, // City Hall
        false, // Bridge
        false, // Cityscape Reflection
        
        // Food Pack
        false, // Hotdog
        false, // Piece of Cake
        false, // Wine Glass
        false, // Fried Egg
        false, // BBQ
        false, // Kebabs
        false, // Ice Cream
        false, // Burger
        false, // Pudding
        false, // Chocolate Bar
        
        // Computer Pack
        false, // Command
        false, // Save
        false, // @
        false, // Mail
        false, // Watch
        false, // Trash
        false, // Bug
        false, // Zoom
        false, // Battery
        false, // Hour Glass
        
        // Body Pack
        false, // Heart
        false, // Brain
        false, // Skull
        false, // Intestine
        false, // Lips
        false, // Eye
        false, // Kidney
        false, // Tooth
        false, // Lungs
        false, // Face
        
        // World Pack
        false, // Globe
        false, // Pyramid
        false, // Union Jack
        false, // Compass
        false, // Mountain
        false, // Africa
        false, // Island
        false, // Partly Cloudy
        false, // Maple Leaf
        false, // Volcano
        
        // Emoji Pack
        false, // Smiling Face
        false, // Eyes
        false, // Fire
        false, // Weird Fish
        false, // Winking Face
        false, // Peach
        false, // Ghost
        false, // Augerbene / Eggplant
        false, // Crying Face
        false, // Poo
        
        // Numbers Pack
        false, // One
        false, // Two
        false, // Three
        false, // Four
        false, // Five
        false, // Six
        false, // Seven
        false, // Eight
        false, // Nine
        false, // Zero
        
        // Challenge Pack
        false, // Lonesome Brick
        false, // Kerplunk
        false, // Gradient
        false, // Restriction
        false, // Barricade
        false, // Minefield
        false, // Split Screen
        false, // Pimple
        false, // Ringfence
        false // Finish Line
    ]
    
    var powerUpUnlockedArray: [Bool] = [
        true, // Get a Life
        true, // Lose a Life
        true, // Decrease Ball Speed
        true, // Increase Ball Speed
        true, // Increase Paddle Size
        true, // Decrease Paddle Size
        false, // Sticky Paddle
        false, // Gravity
        true, // +100 Points
        true, // -100 Points Small
        false, // +1000 Points
        false, // -1000 Points
        false, // x2 Multiplier
        false, // Reset Multiplier
        true, // Next Level
        true, // Show All Bricks
        true, // Hide Bricks
        true, // Clear Multi-Hit Bricks
        true, // Reset Multi-Hit Bricks
        true, // Remove Indestructible Bricks
        false, // Giga-Ball
        false, // Undestructi-Ball
        false, // Lasers
        false, // Quicksand
        false, // Mystery
        false, // Backstop
        false, // Increase Ball Size
        false, // Decrease Ball Size
        true, // Multi-Ball - Endless 2.0 only, and never locked behind a pack
        true, // Trajectory Line - the same
        true, // Landing Marker - the same
        true, true, true, true, true, true, true, true, // The paddle batch - the same
        true, true, true, true, true, true, true, true, true,
        true, true, true, true, true, true, true, true, true, true, true // The field batch
        // and after, Lock, Key, Wipe, Randomised Bounce, Ghost Ball, Safety Paddle, Drift and
        // the four shaped paddle faces included - never locked
    ]
    
    var achievementsUnlockedArray: [Bool] = [
        false, // 0 achievementEndlessTen
        false, // 1 achievementEndlessHundred
        false, // 2 achievementEndlessFiveHundred
        false, // 3 achievementEndlessOneK
        false, // 4 achievementEndlessFiveK
        false, // 5 achievementEndlessTenK
        false, // 6 classicPackComplete
        false, // 7 spacePackComplete
        false, // 8 naturePackComplete
        false, // 9 urbanPackComplete
        false, // 10 foodPackComplete
        false, // 11 computerPackComplete
        false, // 12 bodyPackComplete
        false, // 13 worldPackComplete
        false, // 14 emojiPackComplete
        false, // 15 numbersPackComplete
        false, // 16 challengePackComplete
        false, // 17 endlessOneMins
        false, // 18 endlessFiveMins
        false, // 19 endlessTenMins
        false, // 20 endlessThirtyMins
        false, // 21 endlessSixtyMins
        false, // 22 endlessCleared
        false, // 23 mysteryPowerUp
        false, // 24 firstPowerUp
        false, // 25 gigaLasers
        false, // 26 endBackstop
        false, // 27 favouritePowerUp
        false, // 28 powerUpCollectorHundred
        false, // 29 powerUpCollectorThousand
        false, // 30 powerUpLeaverHundred
        false, // 31 powerUpLeaverThousand
        false, // 32 maxPaddleSize
        false, // 33 minPaddleSize
        false, // 34 maxBallSize
        false, // 35 minBallSize
        false, // 36 noBallsLost
        false, // 37 threeBallsLost
        false, // 38 allLevelPowerUps
        false, // 39 noLevelPowerUps
        false, // 40 quickLevelComplete
        false, // 41 fivePaddleHits
        false, // 42 tenPaddleHits
        false, // 43 fiveKPointsLevel
        false, // 44 tenKPointsLevel
        false, // 45 oneLevelsComplete
        false, // 46 tenLevelsComplete
        false, // 47 hunderdLevelsComplete
        false, // 48 oneKLevelsComplete
        false, // 49 tenKLevelsComplete
        false, // 50 paddleSpeed
        false, // 51 hundredKTotalScore
        false, // 52 fiveHundredKTotalScore
        false, // 53 millTotalScore
        false, // 54 noBallsLostPack
        false, // 55 tenBallsLostPack
        false, // 56 allPackPowerUps
        false, // 57 noPackPowerUps
        false, // 58 quickPackComplete
        false, // 59 tenKPointsPack
        false, // 60 twoFiveKPointsPack
        false, // 61 fiftyKPointsPack
        false, // 62 onePacksComplete
        false, // 63 tenPacksComplete
        false, // 64 hundredPacksComplete
        false // 65 thousandPacksComplete
    ]

    var achievementsPercentageCompleteArray: [String] = [
        "", // 0 achievementEndlessTen
        "", // 1 achievementEndlessHundred
        "", // 2 achievementEndlessFiveHundred
        "", // 3 achievementEndlessOneK
        "0.0%", // 4 achievementEndlessFiveK
        "0.0%", // 5 achievementEndlessTenK
        "", // 6 classicPackComplete
        "", // 7 spacePackComplete
        "", // 8 naturePackComplete
        "", // 9 urbanPackComplete
        "", // 10 foodPackComplete
        "", // 11 computerPackComplete
        "", // 12 bodyPackComplete
        "", // 13 worldPackComplete
        "", // 14 emojiPackComplete
        "", // 15 numbersPackComplete
        "", // 16 challengePackComplete
        "", // 17 endlessOneMins
        "", // 18 endlessFiveMins
        "", // 19 endlessTenMins
        "", // 20 endlessThirtyMins
        "", // 21 endlessSixtyMins
        "", // 22 endlessCleared
        "", // 23 mysteryPowerUp
        "", // 24 firstPowerUp
        "", // 25 gigaLasers
        "", // 26 endBackstop
        "0.0%", // 27 favouritePowerUp
        "0.0%", // 28 powerUpCollectorHundred
        "0.0%", // 29 powerUpCollectorThousand
        "0.0%", // 30 powerUpLeaverHundred
        "0.0%", // 31 powerUpLeaverThousand
        "", // 32 maxPaddleSize
        "", // 33 minPaddleSize
        "", // 34 maxBallSize
        "", // 35 minBallSize
        "", // 36 noBallsLost
        "", // 37 threeBallsLost
        "", // 38 allLevelPowerUps
        "", // 39 noLevelPowerUps
        "", // 40 quickLevelComplete
        "", // 41 fivePaddleHits
        "", // 42 tenPaddleHits
        "", // 43 fiveKPointsLevel
        "", // 44 tenKPointsLevel
        "", // 45 oneLevelsComplete
        "0.0%", // 46 tenLevelsComplete
        "0.0%", // 47 hunderdLevelsComplete
        "0.0%", // 48 oneKLevelsComplete
        "0.0%", // 49 tenKLevelsComplete
        "", // 50 paddleSpeed
        "0.0%", // 51 hundredKTotalScore
        "0.0%", // 52 fiveHundredKTotalScore
        "0.0%", // 53 millTotalScore
        "", // 54 noBallsLostPack
        "", // 55 tenBallsLostPack
        "", // 56 allPackPowerUps
        "", // 57 noPackPowerUps
        "", // 58 quickPackComplete
        "", // 59 tenKPointsPack
        "", // 60 twoFiveKPointsPack
        "", // 61 fiftyKPointsPack
        "", // 62 onePacksComplete
        "0.0%", // 63 tenPacksComplete
        "0.0%", // 64 hundredPacksComplete
        "0.0%" // 65 thousandPacksComplete
    ]
    var achievementDates: [Date] = [
        Date(), // 0 achievementEndlessTen
        Date(), // 1 achievementEndlessHundred
        Date(), // 2 achievementEndlessFiveHundred
        Date(), // 3 achievementEndlessOneK
        Date(), // 4 achievementEndlessFiveK
        Date(), // 5 achievementEndlessTenK
        Date(), // 6 classicPackComplete
        Date(), // 7 spacePackComplete
        Date(), // 8 naturePackComplete
        Date(), // 9 urbanPackComplete
        Date(), // 10 foodPackComplete
        Date(), // 11 computerPackComplete
        Date(), // 12 bodyPackComplete
        Date(), // 13 worldPackComplete
        Date(), // 14 emojiPackComplete
        Date(), // 15 numbersPackComplete
        Date(), // 16 challengePackComplete
        Date(), // 17 endlessOneMins
        Date(), // 18 endlessFiveMins
        Date(), // 19 endlessTenMins
        Date(), // 20 endlessThirtyMins
        Date(), // 21 endlessSixtyMins
        Date(), // 22 endlessCleared
        Date(), // 23 mysteryPowerUp
        Date(), // 24 firstPowerUp
        Date(), // 25 gigaLasers
        Date(), // 26 endBackstop
        Date(), // 27 favouritePowerUp
        Date(), // 28 powerUpCollectorHundred
        Date(), // 29 powerUpCollectorThousand
        Date(), // 30 powerUpLeaverHundred
        Date(), // 31 powerUpLeaverThousand
        Date(), // 32 maxPaddleSize
        Date(), // 33 minPaddleSize
        Date(), // 34 maxBallSize
        Date(), // 35 minBallSize
        Date(), // 36 noBallsLost
        Date(), // 37 threeBallsLost
        Date(), // 38 allLevelPowerUps
        Date(), // 39 noLevelPowerUps
        Date(), // 40 quickLevelComplete
        Date(), // 41 fivePaddleHits
        Date(), // 42 tenPaddleHits
        Date(), // 43 fiveKPointsLevel
        Date(), // 44 tenKPointsLevel
        Date(), // 45 oneLevelsComplete
        Date(), // 46 tenLevelsComplete
        Date(), // 47 hunderdLevelsComplete
        Date(), // 48 oneKLevelsComplete
        Date(), // 49 tenKLevelsComplete
        Date(), // 50 paddleSpeed
        Date(), // 51 hundredKTotalScore
        Date(), // 52 fiveHundredKTotalScore
        Date(), // 53 millTotalScore
        Date(), // 54 noBallsLostPack
        Date(), // 55 tenBallsLostPack
        Date(), // 56 allPackPowerUps
        Date(), // 57 noPackPowerUps
        Date(), // 58 quickPackComplete
        Date(), // 59 tenKPointsPack
        Date(), // 60 twoFiveKPointsPack
        Date(), // 61 fiftyKPointsPack
        Date(), // 62 onePacksComplete
        Date(), // 63 tenPacksComplete
        Date(), // 64 hundredPacksComplete
        Date() // 65 thousandPacksComplete
    ]
}

extension TotalStats {

    /// Brings the fixed-length arrays back up to the length the game indexes them at.
    ///
    /// These are decoded from a file written by whichever version of the app last saved it.
    /// Every release that adds an achievement leaves each older file one entry short, and
    /// the achievement code indexes these arrays directly - `achievementsUnlockedArray[41]`
    /// and so on. The first time a player earned an achievement past the end of their file's
    /// array, the app would go out of bounds and stop dead, at the exact moment of doing
    /// something well.
    ///
    /// Padded from a freshly built TotalStats rather than from a hard-coded length, so
    /// adding an achievement or a power-up needs nothing here changed to stay safe.
    ///
    /// The power-up arrays are here for the same reason the achievement ones are, and they are
    /// the ones about to matter: one entry per power-up, decoded from a file written by
    /// whichever version the player last ran, and Endless 2.0 adds twenty-two. A stats file
    /// written before those existed is shorter than the arrays this build indexes into, and
    /// the first read past the end takes the app down - on the device of somebody who has been
    /// playing for years, which is exactly whose file is shortest.
    ///
    /// So this is what has to be right *before* a new power-up can be offered, rather than a
    /// tidy-up afterwards.
    func makeStoredArraysConsistent() {
        let fresh = TotalStats()
        achievementsUnlockedArray = TotalStats.padded(achievementsUnlockedArray,
                                                      like: fresh.achievementsUnlockedArray)
        achievementDates = TotalStats.padded(achievementDates,
                                             like: fresh.achievementDates)
        achievementsPercentageCompleteArray =
            TotalStats.padded(achievementsPercentageCompleteArray,
                              like: fresh.achievementsPercentageCompleteArray)

        if let stored = endlessPowerUpMetres {
            endlessPowerUpMetres = TotalStats.padded(stored, like: TotalStats.freshPowerUpMetres)
        }
        if let stored = endlessIIPowerUpMetres {
            endlessIIPowerUpMetres = TotalStats.padded(stored, like: TotalStats.freshPowerUpMetres)
        }
        // Only when there is something stored. Padding a `nil` into an array of zeroes would
        // turn "never played an endless run" into "played and scored nothing", and the stats
        // page tells those two apart

        powerupsCollected = TotalStats.padded(powerupsCollected, like: fresh.powerupsCollected)
        powerupsGenerated = TotalStats.padded(powerupsGenerated, like: fresh.powerupsGenerated)
        powerUpUnlockedArray = TotalStats.padded(powerUpUnlockedArray,
                                                 like: fresh.powerUpUnlockedArray)
        // A power-up nobody has met is one nobody has collected, and a new one is unlocked from
        // the start - which is what a fresh TotalStats already says. Padding from one rather
        // than from a literal is the whole trick: the defaults are declared once, where the
        // property is
    }

    /// Only ever lengthens. A file with more entries than this build knows about was written
    /// by a newer version, and throwing the extras away would lose that player's progress
    /// the moment they opened an older build.
    static func padded<T>(_ value: [T], like template: [T]) -> [T] {
        guard value.count < template.count else { return value }
        return value + template[value.count...]
    }
}
