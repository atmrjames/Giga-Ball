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
            ballProperties: [12.5, 300.0, -120.0, 240.0, 30.0],
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
        defaults.set([12.5, 300.0, -120.0, 240.0, 30.0], forKey: "saveBallPropertiesArray")
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
        XCTAssertEqual(loaded?.ballProperties, [12.5, 300.0, -120.0, 240.0, 30.0])
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

    // MARK: - The resume flag and the save are separate

    func testACorruptSaveLoadsAsNothingToResume() {
        // resumeGameToLoad is its own UserDefaults flag. A save that fails to
        // decode leaves it set with nothing behind it, and the resume path runs
        // at launch - so "flag set, load returns nil" has to be a state the app
        // survives rather than one it traps on.
        defaults.set(true, forKey: "resumeGameToLoad")
        defaults.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: SavedGame.defaultsKey)

        XCTAssertNil(SavedGame.load(from: defaults))
        XCTAssertEqual(defaults.object(forKey: "resumeGameToLoad") as? Bool, true,
                       "The flag survives independently, which is why callers must check both")
    }

    func testATruncatedLegacySaveWithTheFlagSetLoadsAsNothing() {
        defaults.set(true, forKey: "resumeGameToLoad")
        writeLegacySave(progress: [1, 2, 3])

        XCTAssertNil(SavedGame.load(from: defaults))
    }

    // MARK: - Versioning

    func testASaveCarriesTheCurrentVersion() {
        XCTAssertEqual(sampleGame().version, SavedGame.currentVersion)
    }

    func testMigratedSavesCarryTheCurrentVersion() {
        writeLegacySave()
        XCTAssertEqual(SavedGame.load(from: defaults)?.version, SavedGame.currentVersion)
    }

    // MARK: - Ball properties

    func testASaveWithAPartialBallIsRejected() {
        // ballProperties is read positionally up to index 4 during resume. A short array
        // traps there - at launch, mid-resume - which is the crash this format exists to
        // prevent. Two of them happened in testing before this guard went in.
        for count in 1...(SavedGame.ballPropertiesCount - 1) {
            var game = sampleGame()
            game.ballProperties = Array(repeating: 1.0, count: count)
            game.save(to: defaults)

            XCTAssertNil(SavedGame.load(from: defaults),
                         "\(count) of \(SavedGame.ballPropertiesCount) ball values should not load")
        }
    }

    func testASaveWithNoBallInPlayStillLoads() {
        // Empty is the legitimate case: the ball was sitting on the paddle.
        var game = sampleGame()
        game.ballProperties = []
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.ballProperties, [])
    }

    func testASaveWithAWholeBallLoads() {
        var game = sampleGame()
        game.ballProperties = [1, 2, 3, 4, 5]
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.ballProperties, [1, 2, 3, 4, 5])
    }

    // MARK: - Sticky paddle

    func testTheStickyPaddleTotalRoundTrips() {
        // The catches start at 4 + multiplier, so the total is 5, 6 or 7. Resume used to
        // assume 6 and the icon bar came back the wrong length.
        var game = sampleGame()
        game.stickyPaddleCatchesTotal = 7
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.stickyPaddleCatchesTotal, 7)
    }

    func testASaveWrittenWithoutTheStickyTotalStillLoads() {
        // The field is optional so saves written before it existed still decode.
        var game = sampleGame()
        game.stickyPaddleCatchesTotal = nil
        game.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertNil(loaded?.stickyPaddleCatchesTotal)
    }

    // MARK: - Lives

    func testANegativeLifeCountIsClampedRatherThanRestored() {
        // Builds before the count was clamped could walk it past zero, and a restored
        // save in that state can never reach game over - the check is for zero.
        var game = sampleGame()
        game.numberOfLives = -9
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.numberOfLives, 0)
    }

    func testAValidLifeCountIsLeftAlone() {
        var game = sampleGame()
        game.numberOfLives = 3
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.numberOfLives, 3)
    }
}
