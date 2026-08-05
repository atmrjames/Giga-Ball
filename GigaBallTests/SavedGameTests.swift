//
//  SavedGameTests.swift
//  GigaBallTests
//
//  The save format is the most dangerous thing in the app: it is read at
//  launch while restoring, so a bad value is a crash loop, not a lost game.
//  These tests care most about what happens when the stored data is wrong -
//  truncated, the wrong type, inconsistent, from a future version - because
//  the old code force-cast all of it and trapped.
//
//  Every test uses an in-memory store. UserDefaults(suiteName:) looks like
//  isolation but is not - its search list still includes the host app's own
//  domain, so a suite-based test reads whatever the running app has saved. That
//  is how the first version of these tests picked up a real game from the
//  simulator.
//

import XCTest
@testable import Giga_Ball

final class SavedGameTests: XCTestCase {

    private var defaults: InMemoryKeyValueStore!

    override func setUp() {
        super.setUp()
        defaults = InMemoryKeyValueStore()
    }

    override func tearDown() {
        defaults = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func sampleGame() -> SavedGame {
        SavedGame(
            levelNumber: 7, endLevelNumber: 10, packNumber: 2,
            levelScore: 120, totalScore: 3_400, numberOfLives: 2,
            endlessHeight: 0, numberOfLevels: 10,
            levelTimerValue: 45, packTimerValue: 300,
            deathsPerLevel: 1, deathsPerPack: 3,
            powerUpsGeneratedPerLevel: 4, powerUpsCollectedPerLevel: 2,
            powerUpsGeneratedPerPack: 20, powerUpsCollectedPerPack: 11,
            paddleHitsPerLevel: 33,
            multiplier: 1.4,
            brickTextures: [1, 2, 3], brickColours: [0, 1, 2],
            brickXPositions: [10, 20, 30], brickYPositions: [40, 50, 60],
            ballProperties: [12.5, 300.0, -120.0, 240.0],
            fallingPowerUpXPositions: [15], fallingPowerUpYPositions: [200],
            fallingPowerUps: [7],
            activePowerUps: ["laserTimer"], activePowerUpDurations: [4.2],
            activePowerUpTimers: [10.0], activePowerUpMagnitudes: [0]
        )
    }

    /// The old format: seventeen ints plus thirteen loose arrays.
    private func writeLegacySave(progress: [Int]? = nil) {
        defaults.set(progress ?? [7, 10, 2, 120, 3_400, 2, 0, 10, 45, 300,
                                  1, 3, 4, 2, 20, 11, 33],
                     forKey: "saveGameSaveArray")
        defaults.set(1.4, forKey: "saveMultiplier")
        defaults.set([1, 2, 3], forKey: "saveBrickTextureArray")
        defaults.set([0, 1, 2], forKey: "saveBrickColourArray")
        defaults.set([10, 20, 30], forKey: "saveBrickXPositionArray")
        defaults.set([40, 50, 60], forKey: "saveBrickYPositionArray")
        defaults.set([12.5, 300.0, -120.0, 240.0], forKey: "saveBallPropertiesArray")
        defaults.set([15], forKey: "savePowerUpFallingXPositionArray")
        defaults.set([200], forKey: "savePowerUpFallingYPositionArray")
        defaults.set([7], forKey: "savePowerUpFallingArray")
        defaults.set(["laserTimer"], forKey: "savePowerUpActiveArray")
        defaults.set([4.2], forKey: "savePowerUpActiveDurationArray")
        defaults.set([10.0], forKey: "savePowerUpActiveTimerArray")
        defaults.set([0], forKey: "savePowerUpActiveMagnitudeArray")
    }

    // MARK: - Round trip

    func testRoundTripsThroughDefaults() {
        let original = sampleGame()
        original.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertEqual(loaded, original)
    }

    func testEveryFieldSurvives() {
        // Equatable covers this, but a field added to the struct and forgotten
        // in the encoder would still compare equal if both sides were default.
        // Spot-check the ones a player would notice losing.
        let original = sampleGame()
        original.save(to: defaults)
        let loaded = SavedGame.load(from: defaults)

        XCTAssertEqual(loaded?.levelNumber, 7)
        XCTAssertEqual(loaded?.totalScore, 3_400)
        XCTAssertEqual(loaded?.numberOfLives, 2)
        XCTAssertEqual(loaded?.multiplier, 1.4)
        XCTAssertEqual(loaded?.brickTextures, [1, 2, 3])
        XCTAssertEqual(loaded?.activePowerUps, ["laserTimer"])
        XCTAssertEqual(loaded?.ballProperties, [12.5, 300.0, -120.0, 240.0])
    }

    func testNoSavedGameLoadsAsNil() {
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    func testClearRemovesTheSave() {
        sampleGame().save(to: defaults)
        XCTAssertNotNil(SavedGame.load(from: defaults))
        SavedGame.clear(from: defaults)
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    // MARK: - Migration from the old format

    func testMigratesALegacySave() {
        writeLegacySave()
        let loaded = SavedGame.load(from: defaults)

        XCTAssertEqual(loaded, sampleGame(),
                       "A game in progress must survive the format change")
    }

    func testSavingAfterMigrationClearsTheOldKeys() {
        writeLegacySave()
        guard let migrated = SavedGame.load(from: defaults) else {
            return XCTFail("Expected a migrated save")
        }
        migrated.save(to: defaults)

        for key in SavedGame.legacyKeys {
            XCTAssertNil(defaults.object(forKey: key), "\(key) should be gone")
        }
        XCTAssertEqual(SavedGame.load(from: defaults), migrated)
    }

    func testClearRemovesLegacyKeysToo() {
        writeLegacySave()
        SavedGame.clear(from: defaults)
        XCTAssertNil(SavedGame.load(from: defaults))
        for key in SavedGame.legacyKeys {
            XCTAssertNil(defaults.object(forKey: key))
        }
    }

    func testTheNewFormatWinsOverLeftoverLegacyKeys() {
        // If both are somehow present - an interrupted migration - the current
        // format is the truth.
        writeLegacySave()
        var current = sampleGame()
        current.totalScore = 999
        defaults.set(try! PropertyListEncoder().encode(current), forKey: SavedGame.defaultsKey)

        XCTAssertEqual(SavedGame.load(from: defaults)?.totalScore, 999)
    }

    // MARK: - Bad data, which used to crash

    func testTruncatedLegacyProgressIsDiscarded() {
        // Sixteen entries instead of seventeen. The old code indexed [16] and
        // trapped; this is a lost save instead.
        writeLegacySave(progress: Array(repeating: 1, count: 16))
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    func testOverlongLegacyProgressIsDiscarded() {
        writeLegacySave(progress: Array(repeating: 1, count: 20))
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    func testLegacyProgressOfTheWrongTypeIsDiscarded() {
        // `as! [Int]?` on a [String] is a crash. This is not.
        defaults.set(["not", "ints"], forKey: "saveGameSaveArray")
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    func testLegacyArraysOfTheWrongTypeFallBackToEmpty() {
        // A bad brick array should not take the whole save with it, but the
        // result has to stay self-consistent.
        writeLegacySave()
        defaults.set("not an array", forKey: "saveBrickTextureArray")
        XCTAssertNil(SavedGame.load(from: defaults),
                     "Bricks that no longer line up must not load")
    }

    func testGarbageInTheCurrentFormatIsDiscarded() {
        defaults.set(Data([0x00, 0x01, 0x02, 0x03]), forKey: SavedGame.defaultsKey)
        XCTAssertNil(SavedGame.load(from: defaults))
    }

    func testAFutureVersionIsDiscarded() {
        // A save written by a newer build. Refusing it loses a game; reading it
        // as though it were this version could restore nonsense.
        var future = sampleGame()
        future.version = SavedGame.currentVersion + 1
        defaults.set(try! PropertyListEncoder().encode(future), forKey: SavedGame.defaultsKey)

        XCTAssertNil(SavedGame.load(from: defaults))
    }

    // MARK: - Parallel array consistency

    func testMismatchedBrickArraysAreRejected() {
        var game = sampleGame()
        game.brickColours = [0, 1]      // one short
        XCTAssertFalse(game.isConsistent)

        defaults.set(try! PropertyListEncoder().encode(game), forKey: SavedGame.defaultsKey)
        XCTAssertNil(SavedGame.load(from: defaults),
                     "Rebuilding the field from these would index out of range")
    }

    func testMismatchedFallingPowerUpArraysAreRejected() {
        var game = sampleGame()
        game.fallingPowerUps = [7, 8]
        XCTAssertFalse(game.isConsistent)
    }

    func testMismatchedActivePowerUpArraysAreRejected() {
        var game = sampleGame()
        game.activePowerUpDurations = []
        XCTAssertFalse(game.isConsistent)
    }

    func testEmptyArraysAreConsistent() {
        // A level with every brick cleared and nothing in flight.
        var game = sampleGame()
        game.brickTextures = []; game.brickColours = []
        game.brickXPositions = []; game.brickYPositions = []
        game.fallingPowerUpXPositions = []; game.fallingPowerUpYPositions = []
        game.fallingPowerUps = []
        game.activePowerUps = []; game.activePowerUpDurations = []
        game.activePowerUpTimers = []; game.activePowerUpMagnitudes = []

        XCTAssertTrue(game.isConsistent)
        game.save(to: defaults)
        XCTAssertEqual(SavedGame.load(from: defaults), game)
    }

    // MARK: - Index mapping

    func testMigrationMapsEveryIndexToTheRightField() {
        // The old format packed these seventeen values positionally. Getting one
        // pair the wrong way round would restore the score as the life count,
        // silently, on every existing player's next launch.
        defaults.set(Array(0..<17), forKey: "saveGameSaveArray")
        guard let g = SavedGame.load(from: defaults) else { return XCTFail("no save") }

        XCTAssertEqual(g.levelNumber, 0)
        XCTAssertEqual(g.endLevelNumber, 1)
        XCTAssertEqual(g.packNumber, 2)
        XCTAssertEqual(g.levelScore, 3)
        XCTAssertEqual(g.totalScore, 4)
        XCTAssertEqual(g.numberOfLives, 5)
        XCTAssertEqual(g.endlessHeight, 6)
        XCTAssertEqual(g.numberOfLevels, 7)
        XCTAssertEqual(g.levelTimerValue, 8)
        XCTAssertEqual(g.packTimerValue, 9)
        XCTAssertEqual(g.deathsPerLevel, 10)
        XCTAssertEqual(g.deathsPerPack, 11)
        XCTAssertEqual(g.powerUpsGeneratedPerLevel, 12)
        XCTAssertEqual(g.powerUpsCollectedPerLevel, 13)
        XCTAssertEqual(g.powerUpsGeneratedPerPack, 14)
        XCTAssertEqual(g.powerUpsCollectedPerPack, 15)
        XCTAssertEqual(g.paddleHitsPerLevel, 16)
    }

    // MARK: - Versioning

    func testASaveCarriesTheCurrentVersion() {
        XCTAssertEqual(sampleGame().version, SavedGame.currentVersion)
    }

    func testMigratedSavesCarryTheCurrentVersion() {
        writeLegacySave()
        XCTAssertEqual(SavedGame.load(from: defaults)?.version, SavedGame.currentVersion)
    }
}
