//
//  SavedGame.swift
//  Megaball
//
//  The in-progress game, as a versioned Codable value.
//
//  It replaces fourteen separate UserDefaults keys holding parallel arrays,
//  read back with force-casts:
//
//      saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
//
//  That runs at launch while restoring, so a corrupt or stale value is not a
//  degraded resume, it is a crash on every launch until the app is deleted.
//  Seventeen game properties were also packed positionally into one [Int], so
//  adding a field meant renumbering the read sites and nothing would catch a
//  mistake.
//
//  Decoding here throws instead, and `migrated(from:)` reads the old format so
//  players with a game in progress keep it.
//

import Foundation

/// The subset of UserDefaults the saved game needs.
///
/// It exists so tests can supply an in-memory double. UserDefaults(suiteName:)
/// is not isolation: its search list still includes the host application's own
/// domain, so a test using one reads whatever the app happens to have stored.
protocol KeyValueStore: AnyObject {
    func object(forKey defaultName: String) -> Any?
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
}

extension UserDefaults: KeyValueStore {}

/// A dictionary-backed store, for tests and for anywhere a real save would be
/// unwanted.
final class InMemoryKeyValueStore: KeyValueStore {
    private var values: [String: Any] = [:]

    init(_ initial: [String: Any] = [:]) { values = initial }

    func object(forKey defaultName: String) -> Any? { values[defaultName] }
    func data(forKey defaultName: String) -> Data? { values[defaultName] as? Data }
    func set(_ value: Any?, forKey defaultName: String) {
        if let value { values[defaultName] = value } else { values.removeValue(forKey: defaultName) }
    }
    func removeObject(forKey defaultName: String) { values.removeValue(forKey: defaultName) }
}

struct SavedGame: Codable, Equatable {

    /// Bumped when the shape changes. `load` refuses anything it does not know,
    /// which is a discarded save rather than a crash or a misread one.
    static let currentVersion = 1

    /// The key the encoded value lives under.
    static let defaultsKey = "savedGame"

    /// The fourteen keys the old format used. Cleared once migrated.
    static let legacyKeys = [
        "saveGameSaveArray", "saveMultiplier",
        "saveBrickTextureArray", "saveBrickColourArray",
        "saveBrickXPositionArray", "saveBrickYPositionArray",
        "saveBallPropertiesArray",
        "savePowerUpFallingXPositionArray", "savePowerUpFallingYPositionArray",
        "savePowerUpFallingArray",
        "savePowerUpActiveArray", "savePowerUpActiveDurationArray",
        "savePowerUpActiveTimerArray", "savePowerUpActiveMagnitudeArray"
    ]

    var version: Int = SavedGame.currentVersion

    // MARK: - Progress
    // Previously indices 0...16 of a single [Int], in this order.

    var levelNumber: Int
    var endLevelNumber: Int
    var packNumber: Int
    var levelScore: Int
    var totalScore: Int
    var numberOfLives: Int
    var endlessHeight: Int
    var numberOfLevels: Int
    var levelTimerValue: Int
    var packTimerValue: Int
    var deathsPerLevel: Int
    var deathsPerPack: Int
    var powerUpsGeneratedPerLevel: Int
    var powerUpsCollectedPerLevel: Int
    var powerUpsGeneratedPerPack: Int
    var powerUpsCollectedPerPack: Int
    var paddleHitsPerLevel: Int

    var multiplier: Double

    // MARK: - The brick field
    // Four arrays indexed together, one entry per surviving brick.

    var brickTextures: [Int]
    var brickColours: [Int]
    var brickXPositions: [Int]
    var brickYPositions: [Int]

    /// Ball position and velocity, flattened.
    var ballProperties: [Double]

    /// Every ball beyond the first, four values each: x, y, dx, dy.
    ///
    /// Endless 2.0 only, and only while a Multi-Ball is in play. Without it a run paused with
    /// four balls came back with one, which is a power-up quietly taken away by the pause
    /// button - and the longer the run, the more it cost.
    ///
    /// Optional so every save written before Multi-Ball existed still decodes. Those restore
    /// with no extras, which is exactly what they had.
    var extraBallProperties: [Double]? = nil

    /// This run's introduction schedule - which styles and power-ups it opens with, the order
    /// the rest arrive in, how fast, and how it weights each one (§6.3, round 192).
    ///
    /// **Saved, because it is drawn once and cannot be drawn again.** It used to live only on
    /// the scene, so a resumed Mayhem run reshuffled the lot: the styles being introduced
    /// changed, the power-ups being held back changed, and the field the player came back to
    /// was stocked differently from the one they left. That is round 150's lesson - a resumed
    /// field must be the field that was saved - one level up, at the rules rather than the
    /// bricks. It mattered less when everything merely differed in order; with a run's opening
    /// set and rarity varying too, a redraw would be a different game.
    ///
    /// Optional so every save written before it decodes, and those restore with a freshly
    /// drawn schedule - the behaviour they already had.
    var endlessIIProgression: EndlessIIProgression? = nil

    /// Time Trial's clock at the moment of the save, in seconds (round 197).
    ///
    /// Saved because it is the one thing that twist cannot give away: without it a pause and
    /// resume handed back a fresh ninety seconds. Optional so every earlier save decodes, and
    /// nil on any run that is not a Time Trial.
    var dailyTimeTrialRemaining: Double? = nil

    /// Which way a saved Drift was sliding the field (round 201). With one Drift the
    /// direction was a coin flip nobody needed to remember; with one per direction it is
    /// part of which power-up is running, and a resume that flipped it would visibly hand
    /// back a different power-up. Optional, and an older save restores rightward - the
    /// fallback those runs always had.
    var endlessIIDriftDirection: Int? = nil

    /// Which mode this run belongs to, as `GameMode.rawValue`.
    ///
    /// **The save used to have no mode field at all**, and the mode was read from a
    /// `UserDefaults` key written once when the run started. Those are two pieces of one fact
    /// kept in two places, and a force quit separates them: the key had not been flushed to
    /// disk yet, and a missing key reads as zero, which is Classic. So a Mayhem run resumed as
    /// a Classic one - the old tray, the score, the multiplier, and a height of 0m at forty
    /// metres up (James, round 170, reproduced by force-quitting mid-run).
    ///
    /// It only showed in Mayhem because Classic and the original Endless share a HUD: losing
    /// the key while playing Endless left a run that still looked and played like Endless,
    /// which is why it "couldn't be replicated in the classic endless mode".
    ///
    /// Optional, so every save written before this decodes exactly as it did - those fall back
    /// to the remembered key, which is what they were always doing.
    var gameMode: Int? = nil

    // MARK: - Power-ups in flight
    // Three arrays indexed together, one entry per falling power-up.

    var fallingPowerUpXPositions: [Int]
    var fallingPowerUpYPositions: [Int]
    var fallingPowerUps: [Int]

    // MARK: - Power-ups in effect
    // Four arrays indexed together, one entry per active power-up.

    var activePowerUps: [String]
    var activePowerUpDurations: [Double]
    var activePowerUpTimers: [Double]
    var activePowerUpMagnitudes: [Int]

    // MARK: - Lasers in flight
    // Two arrays indexed together, one entry per laser still travelling up the screen.
    //
    // Optional so saves written before lasers were kept still decode - those restore
    // with no lasers, which is what every save did before.

    var laserXPositions: [Int]?
    var laserYPositions: [Int]?

    /// What the sticky paddle's remaining catches count down from.
    ///
    /// Its catches start at `4 + multiplier`, so the total is 5, 6 or 7 depending on the
    /// multiplier when it was collected. Without it, resume had to guess - it assumed 6 -
    /// and the icon bar came back the wrong length. It sits outside the parallel active
    /// power-up arrays because only this one power-up has a total worth keeping.
    ///
    /// Optional so saves written before it existed still decode. Those fall back to the
    /// remaining count, which shows a full bar rather than a wrong one.
    var stickyPaddleCatchesTotal: Int?

    // MARK: - The Daily Challenge

    /// The UTC date key of the daily this save belongs to, or nil for a campaign run.
    ///
    /// The key alone restores the whole challenge, because the generator is a pure
    /// function of it (daily spec §2) - so nothing about the twists, the mode or the
    /// level needs saving, and a save can never disagree with the challenge it claims
    /// to be. It is also the guard that stops a daily resuming into the campaign or the
    /// other way round: a key that is not the run being started is not this save.
    var dailyDateKey: String?

    /// Whether the run being saved was the day's scoring attempt.
    ///
    /// Kept rather than recomputed, because "was this the first attempt" is a question
    /// about the moment the play button was pressed, and the answer changes the instant
    /// the record is written. Optional so older saves decode.
    var dailyWasScoringAttempt: Bool?

    /// Everything about one Endless Mayhem brick, so a resumed field is the field that was
    /// left rather than a field that merely resembles it.
    ///
    /// The four legacy arrays store a texture, a colour and a *cell index*, which is all
    /// Classic and the original Endless have ever needed. Mayhem needs more, and the play
    /// test found out how much (round 150: "on quitting the app and resuming, the bricks are
    /// different - some overlapping, some different types, some in different positions").
    /// A Tiny set is four quarter-cell bricks sharing one cell, and four cell indices that
    /// round to the same cell restore as four full-size bricks stacked on one another: one
    /// brick you can see and four bodies to hit, which is a very good description of the
    /// phantom brick bounce this project has been chasing since round 128.
    ///
    /// So Mayhem saves the brick itself: where it is to the point, how big it is, what it is
    /// and what it is wearing.
    struct SavedBrick: Codable, Equatable {
        var texture: Int
        var colour: Int
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        /// A Big brick's sprite hangs off its node, so the anchor has to come back with it.
        var anchorX: Double
        var anchorY: Double
        var hidden: Bool
        /// `EndlessIIRole`'s raw value, when it has one.
        var role: String?
        /// `EndlessIIFace`'s raw value, when it is shaped.
        var face: String?
    /// Which way the face was turned. Optional so a save written before round 154 restores
    /// as it always did, with the shape the right way up.
    var faceMirrored: Bool?
    var faceFlipped: Bool?
        /// The styles tracked by identity rather than by the sprite - spinning, flashing,
        /// breathing, rounded.
        var styles: [String]
        var portalBlue: Bool
        var anchored: Bool
        /// The power-up a power-up brick is holding.
        var powerUpIndex: Int?
        var staysPlain: Bool

        /// Which face a Directional brick may be destroyed from - `EndlessIISide`'s raw value.
        ///
        /// The role came back and the side did not, so `makeDirectional` rolled a fresh one and
        /// a resumed brick was open somewhere else (James, round 174: "after force quitting the
        /// app and restarting during endless mayhem, the open face on a directional brick had
        /// changed"). A brick whose rules change while the player is not looking is worse than
        /// a hard brick.
        ///
        /// Optional, so saves written before this restore as they did - with a rolled side,
        /// which is what they have always had.
        var vulnerableSide: String? = nil
    }

    /// The Mayhem field, saved properly. Absent in every other mode and in every save written
    /// before round 150, which is what keeps this a widening rather than a migration.
    var endlessIIBricks: [SavedBrick]?

    /// Each surviving brick's hidden state, indexed with the brick arrays.
    ///
    /// The texture indices encode hidden for normal and invisible bricks, but not for
    /// multi-hits and Indestructibles - and a Fog of War day fogs those too, so a resume
    /// re-fogged the whole field and everything the run had revealed went dark again
    /// (play-test round 8). Declared down here rather than with its siblings because the
    /// memberwise initialiser follows declaration order, and the older callers list
    /// these newcomers last. Optional so older saves decode.
    var brickHidden: [Bool]?

    /// Whether the run was sitting on the between-levels screen when it was saved.
    ///
    /// The save advances `levelNumber` at that moment, because the between-levels screen is
    /// the doorway to the next level and the save records where the player is *going*. That is
    /// right about the level and wrong about the moment: a resume started the next level
    /// outright, skipping the screen the player was actually looking at (play-test round 40).
    ///
    /// So the level number still advances - the next level really is the one to build - and
    /// this says the player had not started it yet. Optional so older saves decode, and absent
    /// reads as false, which is the behaviour every save written before this had.
    var pausedBetweenLevels: Bool?

    /// Whether the run should come back on the between-levels screen rather than in play.
    var resumesBetweenLevels: Bool { pausedBetweenLevels ?? false }

    // MARK: - Consistency

    /// The five values `ballProperties` carries when a ball is in play:
    /// x, y, dx, dy, and the paddle's x.
    static let ballPropertiesCount = 5

    /// Whether the arrays hold the shapes the resume path reads them at.
    ///
    /// Nothing enforced this before. A brick array one entry short of the
    /// others meant an out-of-range trap while rebuilding the field, again
    /// during resume.
    var isConsistent: Bool {
        let brickCounts = Set([brickTextures.count, brickColours.count,
                               brickXPositions.count, brickYPositions.count])
        let fallingCounts = Set([fallingPowerUpXPositions.count,
                                 fallingPowerUpYPositions.count,
                                 fallingPowerUps.count])
        let activeCounts = Set([activePowerUps.count, activePowerUpDurations.count,
                                activePowerUpTimers.count, activePowerUpMagnitudes.count])
        // ballProperties is either absent - the ball was sitting on the paddle when the
        // game was saved - or all five values. Anything between is read positionally up
        // to index 4 during resume, which traps at launch.
        let ballIsWholeOrAbsent = ballProperties.isEmpty
            || ballProperties.count == SavedGame.ballPropertiesCount
        let lasersAgree = (laserXPositions?.count ?? 0) == (laserYPositions?.count ?? 0)
        // The extras are read in whole groups of four, so a ragged array is a save that was
        // written by something other than this game. They also cannot outlive the ball they
        // are extra to: a save with no primary ball but three secondary ones has nothing to
        // restore them alongside
        let extrasAreWholeGroups = (extraBallProperties?.count ?? 0)
            .isMultiple(of: EndlessIIBalls.savedPropertiesCount)
        let extrasHaveABall = (extraBallProperties?.isEmpty ?? true) || ballProperties.isEmpty == false
        return brickCounts.count == 1 && fallingCounts.count == 1 && activeCounts.count == 1
            && ballIsWholeOrAbsent && lasersAgree && extrasAreWholeGroups && extrasHaveABall
    }

    // MARK: - Legacy migration

    /// Reads the fourteen-key format. Returns nil when there is no saved game,
    /// or when what is there cannot be trusted.
    ///
    /// Every read is optional. The old code force-cast all fourteen, so a value
    /// of the wrong type - written by an older build, or corrupted - crashed
    /// rather than being discarded.
    static func migrated(from defaults: KeyValueStore) -> SavedGame? {
        guard let progress = defaults.object(forKey: "saveGameSaveArray") as? [Int],
              progress.count == 17 else { return nil }

        let game = SavedGame(
            levelNumber: progress[0],
            endLevelNumber: progress[1],
            packNumber: progress[2],
            levelScore: progress[3],
            totalScore: progress[4],
            numberOfLives: progress[5],
            endlessHeight: progress[6],
            numberOfLevels: progress[7],
            levelTimerValue: progress[8],
            packTimerValue: progress[9],
            deathsPerLevel: progress[10],
            deathsPerPack: progress[11],
            powerUpsGeneratedPerLevel: progress[12],
            powerUpsCollectedPerLevel: progress[13],
            powerUpsGeneratedPerPack: progress[14],
            powerUpsCollectedPerPack: progress[15],
            paddleHitsPerLevel: progress[16],
            multiplier: defaults.object(forKey: "saveMultiplier") as? Double ?? 1.0,
            brickTextures: defaults.object(forKey: "saveBrickTextureArray") as? [Int] ?? [],
            brickColours: defaults.object(forKey: "saveBrickColourArray") as? [Int] ?? [],
            brickXPositions: defaults.object(forKey: "saveBrickXPositionArray") as? [Int] ?? [],
            brickYPositions: defaults.object(forKey: "saveBrickYPositionArray") as? [Int] ?? [],
            ballProperties: defaults.object(forKey: "saveBallPropertiesArray") as? [Double] ?? [],
            fallingPowerUpXPositions: defaults.object(forKey: "savePowerUpFallingXPositionArray") as? [Int] ?? [],
            fallingPowerUpYPositions: defaults.object(forKey: "savePowerUpFallingYPositionArray") as? [Int] ?? [],
            fallingPowerUps: defaults.object(forKey: "savePowerUpFallingArray") as? [Int] ?? [],
            activePowerUps: defaults.object(forKey: "savePowerUpActiveArray") as? [String] ?? [],
            activePowerUpDurations: defaults.object(forKey: "savePowerUpActiveDurationArray") as? [Double] ?? [],
            activePowerUpTimers: defaults.object(forKey: "savePowerUpActiveTimerArray") as? [Double] ?? [],
            activePowerUpMagnitudes: defaults.object(forKey: "savePowerUpActiveMagnitudeArray") as? [Int] ?? []
        )
        return game.isConsistent ? game : nil
    }

    // MARK: - Storage

    /// The saved game, or nil if there is none or it cannot be read.
    ///
    /// Prefers the current format, falls back to migrating the old one, and
    /// never throws out to the caller - a save that cannot be read is a save
    /// that is not there, which loses a game in progress but not the app.
    /// The key the app sets when a run is left in progress, alongside the save itself.
    static let resumeFlagKey = "resumeGameToLoad"

    /// Whether there is genuinely a run to go back to.
    ///
    /// **The flag and the save are two different keys, and they can come apart** - a quit
    /// taken between the two writes leaves the flag set with nothing behind it. Asking the
    /// flag alone is what hung the splash screen for ever in round 181: it offered a resume,
    /// found no save to describe, refused to draw the prompt (correctly - drawing it would
    /// have unwrapped a nil and trapped at launch), and then never dismissed, because
    /// dismissal only ever ran on the no-resume path.
    ///
    /// So the question is asked once, here, where both halves are in reach, rather than at
    /// the three or four call sites that each know only one of them.
    static func canResume(from defaults: KeyValueStore = UserDefaults.standard) -> Bool {
        (defaults.object(forKey: resumeFlagKey) as? Bool ?? false) && load(from: defaults) != nil
    }

    static func load(from defaults: KeyValueStore = UserDefaults.standard) -> SavedGame? {
        if let data = defaults.data(forKey: defaultsKey) {
            if var game = try? PropertyListDecoder().decode(SavedGame.self, from: data),
               game.version == currentVersion, game.isConsistent {
                game.numberOfLives = max(0, game.numberOfLives)
                // Builds before the life count was clamped could walk it past zero, and
                // such a save can never reach game over once restored. Rejecting it would
                // throw away the game; clamping lets the next lost ball end it.
                return game
            }
            return nil
        }
        return migrated(from: defaults)
    }

    /// Writes the current format and removes the old keys.
    func save(to defaults: KeyValueStore = UserDefaults.standard) {
        guard let data = try? PropertyListEncoder().encode(self) else { return }
        defaults.set(data, forKey: SavedGame.defaultsKey)
        SavedGame.legacyKeys.forEach { defaults.removeObject(forKey: $0) }
    }

    /// Removes the saved game in both formats.
    static func clear(from defaults: KeyValueStore = UserDefaults.standard) {
        defaults.removeObject(forKey: defaultsKey)
        legacyKeys.forEach { defaults.removeObject(forKey: $0) }
    }
}
