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
        return brickCounts.count == 1 && fallingCounts.count == 1 && activeCounts.count == 1
            && ballIsWholeOrAbsent && lasersAgree
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
