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
import SpriteKit
@testable import Giga_Ball

final class SavedGameTests: XCTestCase {

    private var defaults: InMemoryKeyValueStore!

    override func setUp() {
        super.setUp()
        defaults = InMemoryKeyValueStore()
        UserDefaults().removePersistentDomain(forName: GameScene.testSettingsSuite)
        // The scene tests below save through a scene, and a scene under tests keeps its save in
        // this suite (round 322b). Cleared first, so one test's save never answers another's
        // load - and so a killed run's leftovers are gone before anything reads them
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

    // MARK: - Whether there is a run to go back to

    /// Round 181, found on the simulator: force-quit a run, relaunch, and the app sits on
    /// the splash screen with the title showing and no way past it - for ever.
    ///
    /// `resumeGameToLoad` and the save are two different keys, and a quit taken between the
    /// two writes leaves the flag set with nothing behind it. The splash asked the flag
    /// alone, offered a resume, found no save to describe, correctly refused to draw a
    /// prompt it would have had to unwrap a nil for - and then never dismissed, because
    /// dismissal only ever ran on the no-resume path. The crash the save format was written
    /// to end had quietly become a hang, which is worse: a crash loop at least says so.
    func testAFlagWithNoSaveBehindItIsNotAResume() {
        defaults.set(true, forKey: SavedGame.resumeFlagKey)
        XCTAssertNil(SavedGame.load(from: defaults), "the state the force quit left")
        XCTAssertFalse(SavedGame.canResume(from: defaults),
                       "no save, no resume - whatever the flag says")
    }

    func testASaveWithNoFlagIsNotOfferedEither() {
        // The other direction: a finished run clears the flag and may leave the save behind
        // until the next write. Offering it would resume a game the player has ended
        sampleGame().save(to: defaults)
        XCTAssertFalse(SavedGame.canResume(from: defaults))
    }

    func testTheFlagAndTheSaveTogetherAreAResume() {
        sampleGame().save(to: defaults)
        defaults.set(true, forKey: SavedGame.resumeFlagKey)
        XCTAssertTrue(SavedGame.canResume(from: defaults))
    }

    func testAnUndecodableSaveWithTheFlagSetIsNotAResume() {
        // The original reason the guard existed: garbage in the save decodes to nil, and
        // the prompt that describes it would have trapped at launch
        defaults.set(true, forKey: SavedGame.resumeFlagKey)
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: SavedGame.defaultsKey)
        XCTAssertFalse(SavedGame.canResume(from: defaults))
    }

    func testAFreshInstallOffersNothing() {
        XCTAssertFalse(SavedGame.canResume(from: defaults))
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

    // MARK: - More than one ball

    func testASaveWrittenBeforeMultiBallStillLoads() {
        // Every save on every device in the world today was written without this field
        var game = sampleGame()
        game.extraBallProperties = nil
        game.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertNil(loaded?.extraBallProperties)
        XCTAssertTrue(EndlessIIBalls.unflattened(loaded?.extraBallProperties).isEmpty)
    }

    func testEveryExtraBallSurvivesTheRoundTrip() {
        var game = sampleGame()
        game.ballProperties = [1, 2, 3, 4, 5]
        game.extraBallProperties = EndlessIIBalls.flattened([
            .init(position: CGPoint(x: 10, y: 20), velocity: CGVector(dx: 30, dy: -40)),
            .init(position: CGPoint(x: -50, y: 60), velocity: CGVector(dx: -70, dy: 80)),
        ])
        game.save(to: defaults)

        let restored = EndlessIIBalls.unflattened(SavedGame.load(from: defaults)?.extraBallProperties)
        XCTAssertEqual(restored.count, 2)
        XCTAssertEqual(restored[0].position, CGPoint(x: 10, y: 20))
        XCTAssertEqual(restored[0].velocity, CGVector(dx: 30, dy: -40))
        XCTAssertEqual(restored[1].position, CGPoint(x: -50, y: 60))
        XCTAssertEqual(restored[1].velocity, CGVector(dx: -70, dy: 80))
    }

    func testARaggedExtraBallArrayIsRejected() {
        // Read in whole groups of four during resume, at launch, where a trap is a crash on
        // opening the app - the same shape of bug the ball guard above exists for
        for count in [1, 2, 3, 5, 7] {
            var game = sampleGame()
            game.ballProperties = [1, 2, 3, 4, 5]
            game.extraBallProperties = Array(repeating: 1.0, count: count)
            game.save(to: defaults)

            XCTAssertNil(SavedGame.load(from: defaults), "\(count) values should not load")
        }
    }

    func testExtraBallsWithoutAFirstBallAreRejected() {
        // The ball was on the paddle, so there is nothing for the others to be extra to
        var game = sampleGame()
        game.ballProperties = []
        game.extraBallProperties = [1, 2, 3, 4]
        game.save(to: defaults)

        XCTAssertNil(SavedGame.load(from: defaults))
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

    // MARK: - What the scene puts in the save

    /// **Every counter in the save comes from the right place in the scene.**
    ///
    /// Round 319e. The format above is covered thoroughly and the *mapping* is not: round 311's
    /// coverage pass put `saveCurrentGame` second on its risk list at complexity 164 and **3%
    /// covered**, and round 313c found the iPad's resume bug living in it. It builds a
    /// `SavedGame` through a forty-argument initialiser where every argument is a local named
    /// after the scene property it copies, which is the exact shape of thing a copy-paste gets
    /// wrong in a way nothing notices: swap `deathsPerLevel` and `deathsPerPack` and the save
    /// is still valid, still consistent, still loads, and quietly hands a resumed run the wrong
    /// numbers.
    ///
    /// So every value here is **distinct**, which is what makes the test able to see a swap at
    /// all - the same technique `testMigrationMapsEveryIndexToTheRightField` uses on the legacy
    /// format. Two of them are deliberately not straight copies and are asserted as what they
    /// are: the total is the running total *plus* this level's score, because a level in
    /// progress has not banked yet, and the multiplier survives only while the ball is alive.
    func testTheSaveCarriesEveryCounterFromWhereItBelongs() {
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.gameMode = .classic
        scene.gameState.enter(Playing.self)

        scene.levelNumber = 7
        scene.endLevelNumber = 19
        scene.packNumber = 3
        scene.levelScore = 1_234
        scene.totalScore = 56_789
        scene.numberOfLives = 4
        scene.numberOfLevels = 11
        scene.levelTimerValue = 41
        scene.packTimerValue = 313
        scene.deathsPerLevel = 2
        scene.deathsPerPack = 9
        scene.powerUpsGeneratedPerLevel = 14
        scene.powerUpsCollectedPerLevel = 6
        scene.powerUpsGeneratedPerPack = 77
        scene.powerUpsCollectedPerPack = 31
        scene.paddleHitsPerLevel = 58
        scene.multiplier = 1.6
        scene.ballLostBool = false
        scene.ballIsOnPaddle = true

        scene.saveCurrentGame()

        guard let saved = SavedGame.load(from: scene.defaults) else {
            return XCTFail("a run in play is a run that saves")
        }
        XCTAssertEqual(saved.levelNumber, 7)
        XCTAssertEqual(saved.endLevelNumber, 19)
        XCTAssertEqual(saved.packNumber, 3)
        XCTAssertEqual(saved.levelScore, 1_234)
        XCTAssertEqual(saved.totalScore, 58_023,
                       "the running total plus the level in progress, which has not banked")
        XCTAssertEqual(saved.numberOfLives, 4)
        XCTAssertEqual(saved.numberOfLevels, 11)
        XCTAssertEqual(saved.levelTimerValue, 41)
        XCTAssertEqual(saved.packTimerValue, 313)
        XCTAssertEqual(saved.deathsPerLevel, 2)
        XCTAssertEqual(saved.deathsPerPack, 9)
        XCTAssertEqual(saved.powerUpsGeneratedPerLevel, 14)
        XCTAssertEqual(saved.powerUpsCollectedPerLevel, 6)
        XCTAssertEqual(saved.powerUpsGeneratedPerPack, 77)
        XCTAssertEqual(saved.powerUpsCollectedPerPack, 31)
        XCTAssertEqual(saved.paddleHitsPerLevel, 58)
        XCTAssertEqual(saved.multiplier, 1.6, accuracy: 0.0001)
        XCTAssertEqual(saved.gameMode, GameMode.classic.rawValue)
    }

    /// **A lost ball banks nothing and takes the multiplier with it.**
    ///
    /// The two conditional values from the test above, asserted as conditions rather than as
    /// copies. `ballLostBool` means the ball is gone and the run is between serves, and the
    /// multiplier is a streak: a resume that handed back 1.6 would be handing back a streak the
    /// player had already lost.
    func testALostBallSavesTheMultiplierBackToOne() {
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.gameMode = .classic
        scene.gameState.enter(Playing.self)
        scene.numberOfLives = 3
        scene.levelNumber = 2
        scene.endLevelNumber = 10
        scene.numberOfLevels = 10
        scene.multiplier = 1.6
        scene.ballLostBool = true
        scene.ballIsOnPaddle = true

        scene.saveCurrentGame()

        XCTAssertEqual(SavedGame.load(from: scene.defaults)?.multiplier, 1.0,
                       "a streak the player has already lost must not come back with the run")
    }

    /// **The layout the save's points mean something in travels with it** (round 313).
    ///
    /// Everything else in the save is a cell or a counter and moves between layouts on its own.
    /// The ball, the paddle and Mayhem's brick records are *points*, and on an iPad the next
    /// launch is not always the same size or even the same way up - which is the bug round 313c
    /// found. The two fields that carry the frame are written from the scene, so they are worth
    /// the same distinctness treatment as the counters.
    func testTheSaveRecordsTheLayoutItsPointsWereMeasuredIn() {
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.gameMode = .classic
        scene.gameState.enter(Playing.self)
        scene.numberOfLives = 3
        scene.levelNumber = 2
        scene.endLevelNumber = 10
        scene.numberOfLevels = 10
        scene.gameWidth = 393
        scene.yBrickOffset = 612
        // Where row zero sits, which is what `resumedBrickTopRow` answers for a classic run -
        // set through the property it derives from rather than faked, so the test is asking the
        // same question the save asks
        scene.ballIsOnPaddle = true

        scene.saveCurrentGame()

        let saved = SavedGame.load(from: scene.defaults)
        XCTAssertEqual(saved?.savedGameWidth ?? 0, 393, accuracy: 0.001,
                       "the width the points were measured across")
        XCTAssertEqual(saved?.savedFieldTop ?? 0, 612, accuracy: 0.001,
                       "and where the top of the field was")
    }

    // MARK: - A finished game must never be saved

    func testAGameOverIsNeverSaved() {
        // Play test: "When relaunching app a previously completed game can sometimes
        // pick back up. This needs to be fixed. When a game is over it mustn't be
        // saved - this could allow users to cheat."
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.gameoverStatus = true
        XCTAssertTrue(scene.runIsOver)

        scene.defaults.set(true, forKey: "resumeGameToLoad")
        scene.saveCurrentGame()
        XCTAssertFalse(scene.defaults.bool(forKey: "resumeGameToLoad"),
                       "a finished game must never be offered for resume")
    }

    // MARK: - One Backstop per run

    /// **The limit survives a relaunch** (James, round 320: "backstop power up is very powerful.
    /// It should only be available once per game").
    ///
    /// The eligibility rule already refused a second Backstop while the first was out, which
    /// stops two overlapping and does nothing about catching one, spending it, and being
    /// offered another. A free save from the bottom of the field is the most valuable thing the
    /// mode gives away, so the limit has to hold across a pause and a force quit too: one that
    /// a relaunch clears is one a player learns to work around.
    func testASpentBackstopStaysSpentAcrossASave() {
        var game = sampleGame()
        game.backstopSpent = true
        game.save(to: defaults)

        XCTAssertEqual(SavedGame.load(from: defaults)?.backstopSpent, true)
    }

    /// A save written before the field existed reads as "not yet spent".
    ///
    /// Which gives a resumed older run one Backstop rather than none - the generous way round,
    /// because taking something away from a run already in progress is the worse surprise.
    func testASaveWrittenBeforeTheBackstopLimitStillLoads() {
        var game = sampleGame()
        game.backstopSpent = nil
        game.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertNotNil(loaded, "an older save still decodes")
        XCTAssertNil(loaded?.backstopSpent)
        XCTAssertFalse(loaded?.backstopSpent ?? false, "and reads as not yet spent")
    }

    // MARK: - The daily's own slot

    func testADailySaveRestoresItsChallengeFromTheDateKey() {
        // Play test: "When playing daily challenge and force quitting the app, it didn't
        // resume the level, it went back to the main menu. It should resume the level."
        // The key alone restores the challenge, because the generator is pure.
        var game = sampleGame()
        let key = DailyChallengeSession.shared.todayKey
        game.dailyDateKey = key
        game.dailyWasScoringAttempt = true

        DailyChallengeSession.shared.restore(from: game)
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertEqual(DailyChallengeSession.shared.active,
                       DailyChallengeGenerator.challenge(forKey: key))
        XCTAssertTrue(DailyChallengeSession.shared.isScoringAttempt,
                      "resumed inside its own day, it is still the scoring attempt")
        XCTAssertFalse(DailyChallengeSession.shared.resumedAfterDeadline)
    }

    func testADailyResumedAfterItsDeadlineBecomesPractice() {
        // "We need a method of dealing with paused or incomplete games that resume after
        // the deadline" - the run continues, the score does not post (spec §12.5).
        var game = sampleGame()
        game.dailyDateKey = "2020-01-01"
        game.dailyWasScoringAttempt = true

        DailyChallengeSession.shared.restore(from: game)
        defer { DailyChallengeSession.shared.active = nil }

        XCTAssertNotNil(DailyChallengeSession.shared.active, "the run still resumes")
        XCTAssertTrue(DailyChallengeSession.shared.resumedAfterDeadline)
        XCTAssertFalse(DailyChallengeSession.shared.isScoringAttempt,
                       "the window is the day, and the day has gone")
    }

    func testACampaignSaveClearsAnyDailyLeftInTheSession() {
        DailyChallengeSession.shared.active = DailyChallengeGenerator.challenge(
            forKey: DailyChallengeSession.shared.todayKey)
        DailyChallengeSession.shared.isScoringAttempt = true

        DailyChallengeSession.shared.restore(from: sampleGame())

        XCTAssertNil(DailyChallengeSession.shared.active,
                     "a campaign save must never resume into a twisted game")
        XCTAssertFalse(DailyChallengeSession.shared.isScoringAttempt)
    }

    func testTheLastLevelMidPlayStillSaves() {
        // The completion check must not fire while the final level is still being
        // played - a pause on the last level is an ordinary save.
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.levelNumber = 9
        scene.endLevelNumber = 9
        XCTAssertFalse(scene.runIsOver,
                       "the last level in play is not a finished run")
    }

    // MARK: - Where a run comes back

    /// A save written on the between-levels screen advances the level number, because the next
    /// level really is the one to build. What it must also say is that the player had not
    /// started it - a resume ran straight into the level, skipping the screen they were
    /// looking at when they quit (play-test round 40).
    func testASaveMadeBetweenLevelsSaysSo() {
        var game = sampleGame()
        game.pausedBetweenLevels = true
        XCTAssertTrue(game.resumesBetweenLevels)
    }

    /// Absent reads as false, which is how every save written before this field existed
    /// behaves - straight back into play, exactly as it always did.
    func testAnOlderSaveResumesStraightIntoPlay() {
        let game = sampleGame()
        XCTAssertNil(game.pausedBetweenLevels)
        XCTAssertFalse(game.resumesBetweenLevels)
    }
}
// MARK: - The Mayhem field, saved as itself

/// Play-test round 150: "on quitting the app and resuming Endless Mayhem, the bricks are
/// different. Some overlapping, some different types, some in different positions."
final class SavedMayhemFieldTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.gameWidth = 400
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// An empty save, for the two tests that only care about the Mayhem field.
    private func emptySave() -> SavedGame {
        SavedGame(
            levelNumber: 0, endLevelNumber: 0, packNumber: 0,
            levelScore: 0, totalScore: 0, numberOfLives: 1,
            endlessHeight: 0, numberOfLevels: 1,
            levelTimerValue: 0, packTimerValue: 0,
            deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0,
            paddleHitsPerLevel: 0,
            multiplier: 1,
            brickTextures: [], brickColours: [],
            brickXPositions: [], brickYPositions: [],
            ballProperties: [],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [],
            fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [],
            activePowerUpTimers: [], activePowerUpMagnitudes: []
        )
    }

    private func brick(in scene: GameScene, x: CGFloat, y: CGFloat,
                       size: CGSize? = nil) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = size ?? CGSize(width: scene.brickWidth, height: scene.brickHeight)
        brick.position = CGPoint(x: x, y: y)
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    func testATinySetSurvivesTheRoundTrip() {
        // The heart of it. Four quarter-cell bricks share one cell, so four *cell indices*
        // round to the same cell - and the old restore put four full-size bricks on one
        // spot: one brick you can see and four bodies to hit, which is the phantom brick
        let scene = mayhem()
        let quarter = CGSize(width: scene.brickWidth/2, height: scene.brickHeight/2)
        let offsets: [CGPoint] = [CGPoint(x: -10, y: 5), CGPoint(x: 10, y: 5),
                                  CGPoint(x: -10, y: -5), CGPoint(x: 10, y: -5)]
        let saved = offsets.map { offset -> SavedGame.SavedBrick in
            let node = brick(in: scene, x: offset.x, y: offset.y, size: quarter)
            return scene.savedBrick(for: node, texture: 0, colour: 100,
                                    restingY: node.position.y)
        }

        XCTAssertEqual(Set(saved.map(\.x)).count, 2, "two columns of quarters")
        XCTAssertEqual(Set(saved.map(\.y)).count, 2, "two rows of them")
        for record in saved {
            XCTAssertEqual(record.width, Double(quarter.width), accuracy: 0.001)
            XCTAssertEqual(record.height, Double(quarter.height), accuracy: 0.001)
        }
        // Four distinct positions and four quarter sizes, where the cell arrays could only
        // have said "four bricks in this one cell"
    }

    func testABigBricksAnchorAndSizeAreSaved() {
        // A Big brick keeps its node on a row centre and hangs its sprite off it (§8.6).
        // Restored on a centred anchor at cell size it would be a different brick entirely
        let scene = mayhem()
        let big = brick(in: scene, x: 0, y: 40,
                        size: CGSize(width: scene.brickWidth*2, height: scene.brickHeight*2))
        big.anchorPoint = CGPoint(x: 0.25, y: 0.75)

        let record = scene.savedBrick(for: big, texture: 0, colour: 100, restingY: 40)
        XCTAssertEqual(record.width, Double(scene.brickWidth*2), accuracy: 0.001)
        XCTAssertEqual(record.anchorX, 0.25, accuracy: 0.001)
        XCTAssertEqual(record.anchorY, 0.75, accuracy: 0.001)
    }

    func testEveryStyleAndRoleIsWrittenDown() {
        let scene = mayhem()
        let node = brick(in: scene, x: 0, y: 40)
        scene.applyEndlessIIStyle(.spinning, to: node)
        scene.applyEndlessIIStyle(.gravity, to: node)
        node.endlessIIIsAnchored = true

        let record = scene.savedBrick(for: node, texture: 0, colour: 100, restingY: 40)
        XCTAssertEqual(record.role, EndlessIIRole.gravity.rawValue)
        XCTAssertTrue(record.styles.contains(EndlessIIStyle.spinning.rawValue))
        XCTAssertTrue(record.anchored)
    }

    /// James, round 174: "after force quitting the app and restarting during endless mayhem,
    /// the open face on a directional brick had changed."
    ///
    /// The role came back and the side did not, so `makeDirectional` rolled a fresh one. A
    /// brick whose rules change while the player is not looking is worse than a hard brick.
    func testADirectionalBrickComesBackOpenOnTheSameSide() {
        let scene = mayhem()
        let node = brick(in: scene, x: 0, y: 40)
        scene.applyEndlessIIStyle(.directional, to: node)
        node.endlessIIVulnerableSide = .left
        let record = scene.savedBrick(for: node, texture: 0, colour: 100, restingY: 40)
        XCTAssertEqual(record.vulnerableSide, EndlessIISide.left.rawValue,
                       "written down, where it used to be left to chance")

        let resumed = mayhem()
        var save = emptySave()
        save.endlessIIBricks = [record]
        resumed.savedGame = save
        XCTAssertTrue(resumed.resumeEndlessIIBricks())

        var found: [SKSpriteNode] = []
        resumed.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { found.append(sprite) }
        }
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found[0].endlessIIRole, .directional)
        XCTAssertEqual(found[0].endlessIIVulnerableSide, .left,
                       "the same face open, not a freshly rolled one")
    }

    func testASaveWithoutASideStillRestoresADirectionalBrick() {
        // Optional, so saves written before round 174 restore as they did - with a rolled side
        let scene = mayhem()
        let node = brick(in: scene, x: 0, y: 40)
        scene.applyEndlessIIStyle(.directional, to: node)
        var record = scene.savedBrick(for: node, texture: 0, colour: 100, restingY: 40)
        record.vulnerableSide = nil

        let resumed = mayhem()
        var save = emptySave()
        save.endlessIIBricks = [record]
        resumed.savedGame = save
        XCTAssertTrue(resumed.resumeEndlessIIBricks())

        var found: [SKSpriteNode] = []
        resumed.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { found.append(sprite) }
        }
        XCTAssertEqual(found.count, 1)
        XCTAssertNotNil(found[0].endlessIIVulnerableSide, "open somewhere, which is the old best")
    }

    func testTheRestoreRebuildsWhatWasSaved() {
        let scene = mayhem()
        let node = brick(in: scene, x: -60, y: 40)
        scene.applyEndlessIIStyle(.flashing, to: node)
        let record = scene.savedBrick(for: node, texture: 0, colour: 100, restingY: 40)

        let resumed = mayhem()
        var save = emptySave()
        save.endlessIIBricks = [record]
        resumed.savedGame = save
        XCTAssertTrue(resumed.resumeEndlessIIBricks())

        var found: [SKSpriteNode] = []
        resumed.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { found.append(sprite) }
        }
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(Double(found[0].position.x), -60, accuracy: 0.001)
        XCTAssertEqual(Double(found[0].position.y), 40, accuracy: 0.001)
        XCTAssertTrue(resumed.endlessIIStyles(on: found[0]).contains(.flashing),
                      "restored flashing, and in the flashers list rather than merely tinted")
    }

    /// James, round 170: force-quitting mid-Mayhem and resuming brought the run back as a
    /// Classic one - the old tray, the score, the multiplier, and 0m at a real height.
    ///
    /// The mode was kept in a `UserDefaults` key written once when the run started, and a
    /// force quit can lose that write before it reaches disk. A missing key reads as zero,
    /// which is Classic. The save is the thing that survives, so the save carries the mode now.
    func testASaveKnowsWhichModeItsRunWas() {
        let defaults = InMemoryKeyValueStore()
        var game = emptySave()
        game.gameMode = GameMode.endlessII.rawValue
        game.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertEqual(loaded?.gameMode, GameMode.endlessII.rawValue)
        XCTAssertEqual(loaded?.gameMode.flatMap(GameMode.init(rawValue:)), .endlessII)
    }

    func testASaveWrittenBeforeTheModeFieldStillLoads() {
        // Optional, so every save written before round 170 decodes exactly as it did - and
        // falls back to the remembered key, which is what it was always doing
        let defaults = InMemoryKeyValueStore()
        var game = emptySave()
        game.gameMode = nil
        game.save(to: defaults)

        let loaded = SavedGame.load(from: defaults)
        XCTAssertNotNil(loaded)
        XCTAssertNil(loaded?.gameMode)
    }

    func testAMissingModeKeyReadsAsClassicWhichIsWhyTheSaveCarriesIt() {
        // The mechanism, pinned: this is what a lost write looks like to GameMode.current
        let empty = UserDefaults(suiteName: "round170.missingKey")!
        empty.removePersistentDomain(forName: "round170.missingKey")
        XCTAssertEqual(GameMode.current(in: empty), .classic,
                       "so a Mayhem run whose key did not survive comes back as Classic")
    }

    /// James, rounds 169 and 176, with a screenshot: "Endless Mayhem is still coming back from
    /// a force quit with Classic Mode score and ball lives container."
    ///
    /// Round 170 answered the half of this that was a lost `UserDefaults` write, and the HUD
    /// came back anyway - because a *resumed* run never goes through `Playing`'s
    /// `switch levelNumber`, so `resumeBrickCreation` is the only place a level-0 resume is
    /// dressed as endless, and Mayhem returned from it on its own brick path before reaching
    /// the line that does the dressing. Hence Classic's tray over a descending field, and
    /// hence James being unable to reproduce it in the original Endless, which falls through
    /// to the cell path and always got there.
    func testAResumedMayhemRunComesBackAsMayhemAndNotAsClassic() {
        let scene = mayhem()
        let node = brick(in: scene, x: 0, y: 0)
        let record = scene.savedBrick(for: node, texture: 0, colour: 100, restingY: 0)
        // In the bottom zone, holding the field up. The resume ends in `countBricks`, and a
        // field with nothing down there legitimately starts its next row on the spot - which
        // scores a metre and turns the 47 below into a 48, as the full suite duly reported

        let resumed = mayhem()
        resumed.levelNumber = 0
        var save = emptySave()
        save.endlessIIBricks = [record]
        save.endlessHeight = 47
        resumed.savedGame = save
        resumed.resumeBrickCreation()

        XCTAssertTrue(resumed.endlessMode, "an endless run, however its bricks were stored")
        XCTAssertTrue(resumed.livesRowSuppressed, "no ball container")
        XCTAssertTrue(resumed.multiplierLabel.isHidden, "no multiplier")
        XCTAssertEqual(resumed.endlessHeight, 47, "and the height it was actually at, not 0m")
    }

    func testAResumedMayhemRunCanStillDropPowerUps() {
        // The quieter half of the same early return: `powerUpProbAllocation` sat under it too,
        // so every weight stayed at zero and nothing fell out of a brick
        let scene = mayhem()
        let record = scene.savedBrick(for: brick(in: scene, x: 0, y: 40),
                                      texture: 0, colour: 100, restingY: 40)

        let resumed = mayhem()
        resumed.levelNumber = 0
        var save = emptySave()
        save.endlessIIBricks = [record]
        resumed.savedGame = save
        resumed.resumeBrickCreation()

        XCTAssertGreaterThan(resumed.powerUpProbArray.reduce(0, +), 0)
    }

    func testAResumedClassicRunIsStillClassic() {
        // The other direction, because the fix moved a line that had a level check on it
        let scene = mayhem()
        scene.gameMode = .classic
        scene.levelNumber = 3
        var save = emptySave()
        save.levelNumber = 3
        save.brickTextures = []
        save.brickColours = []
        save.brickXPositions = []
        save.brickYPositions = []
        scene.savedGame = save
        scene.resumeBrickCreation()

        XCTAssertFalse(scene.endlessMode)
    }

    /// **A resumed Mayhem run must come back to the field it left, rules and all.**
    ///
    /// The introduction schedule is drawn once at launch and decides which styles and
    /// power-ups this run has met (§6.3). It lived only on the scene, so a resume reshuffled
    /// it: the run came back stocked differently from the one that was paused. Round 150's
    /// lesson at the level of the rules rather than the bricks - and it matters more since
    /// round 192, where a run's opening set and its weighting vary too.
    func testAResumedRunKeepsTheScheduleItWasPlayingWith() throws {
        var save = emptySave()
        let played = EndlessIIProgression.make(powerUps: 40)
        save.endlessIIProgression = played

        let store = InMemoryKeyValueStore()
        save.save(to: store)
        let read = try XCTUnwrap(SavedGame.load(from: store))

        XCTAssertEqual(read.endlessIIProgression, played,
                       "the schedule has to survive the round trip exactly - a redrawn one "
                       + "is a differently stocked run under a player who paused")
    }

    func testASaveWrittenBeforeTheScheduleExistedStillLoads() throws {
        // Optional, like every field added since: an older save restores with a freshly drawn
        // schedule, which is the behaviour it already had
        var save = emptySave()
        save.endlessIIProgression = nil
        let store = InMemoryKeyValueStore()
        save.save(to: store)

        let read = try XCTUnwrap(SavedGame.load(from: store))
        XCTAssertNil(read.endlessIIProgression)
    }

    func testAResumedSceneAdoptsTheSavedSchedule() {
        // The scene half: restoring has to *apply* it, not merely carry it
        let resumed = mayhem()
        let played = EndlessIIProgression.make(powerUps: 40)
        var save = emptySave()
        save.endlessIIProgression = played

        resumed.adoptEndlessIISchedule(from: save)
        XCTAssertEqual(resumed.endlessIIProgression, played,
                       "the run resumes with the schedule it was playing with")
    }

    func testASaveWithNoScheduleLeavesTheOneDrawnAtLaunch() {
        let resumed = mayhem()
        let drawnAtLaunch = resumed.endlessIIProgression
        var save = emptySave()
        save.endlessIIProgression = nil

        resumed.adoptEndlessIISchedule(from: save)
        XCTAssertEqual(resumed.endlessIIProgression, drawnAtLaunch,
                       "an older save keeps the behaviour it always had")
    }

    // MARK: - Giga-Ball ends at zero (round 203)

    /// Round 200: "when the timer ends, they remain active until the next paddle hit. The
    /// idea for this was to prevent the ball getting stuck inside a brick... come up with
    /// something that allows them to end when their timer runs out but prevents any
    /// potential issues."
    ///
    /// The something: ask the stuck question directly. The deferral only survives while a
    /// ball is inside a brick's footprint, and the tick ends the power-up the frame it
    /// comes clear.
    func testADeferredGigaBallEndsTheFrameTheBallComesClear() {
        let scene = mayhem()
        scene.gigaBallDeactivate = true
        let brick = brick(in: scene, x: 0, y: 0)
        brick.size = CGSize(width: 60, height: 20)
        scene.ball.position = CGPoint(x: 0, y: 0)
        scene.ball.size = CGSize(width: 10, height: 10)

        scene.tickDeferredBallPowerUpEnds()
        XCTAssertTrue(scene.gigaBallDeactivate,
                      "inside the brick, so ending now would trap the ball - the one case "
                      + "the old next-paddle-hit rule existed for")

        scene.ball.position = CGPoint(x: 0, y: 300)
        scene.tickDeferredBallPowerUpEnds()
        XCTAssertFalse(scene.gigaBallDeactivate,
                       "clear of the field, so the power-up ends now - not at the next "
                       + "paddle hit, a whole climb away")
    }

    func testTheOverlapQuestionSeesEveryBallInPlay() {
        // A giga extra ball inside a brick when solidity returns is just as stuck as the
        // first one - Mayhem's multi-ball has to hold the deferral too
        let scene = mayhem()
        scene.gigaBallDeactivate = true
        let brick = brick(in: scene, x: 0, y: 0)
        brick.size = CGSize(width: 60, height: 20)
        scene.ball.position = CGPoint(x: 0, y: 300)
        scene.ball.size = CGSize(width: 10, height: 10)

        let extra = SKSpriteNode()
        extra.size = CGSize(width: 10, height: 10)
        extra.position = CGPoint(x: 10, y: 0)
        scene.addChild(extra)
        scene.endlessIIExtraBalls = [extra]

        scene.tickDeferredBallPowerUpEnds()
        XCTAssertTrue(scene.gigaBallDeactivate, "the extra ball is still inside the brick")
    }

    func testAnOlderSaveStillTakesTheCellPath() {
        // Widening, not a migration: a save written before round 150 has no rich field, and
        // must still load exactly as it always did
        let scene = mayhem()
        var save = emptySave()
        save.endlessIIBricks = nil
        scene.savedGame = save
        XCTAssertFalse(scene.resumeEndlessIIBricks())
    }
}

/// Reading a save written in one layout into another.
///
/// James, round 313, from an iPad play test: the run "started by resuming an existing game,
/// but the game had misplaced bricks below the low level line and no ball in sight".
///
/// Almost none of a save is in points - a brick's cell, a falling power-up's cell, every
/// counter - which is why this survived four years on phones, where the layout is the same
/// size every launch. The parts that are in points are the ball, the paddle, and Mayhem's
/// brick records, which keep an exact position and size because those bricks drift, shrink and
/// sit between rows. An iPad opens at whatever size the window has, and since round 312a it
/// can be a different orientation from the one the save was written in.
final class ResumeGeometryTests: XCTestCase {

    /// A save from a narrower layout: 360 wide, its field starting 400 above the origin.
    private func saved(gameWidth: Double? = 360, fieldTop: Double? = 400) -> SavedGame {
        var game = SavedGame(
            levelNumber: 1, endLevelNumber: 1, packNumber: 1,
            levelScore: 0, totalScore: 0, numberOfLives: 3,
            endlessHeight: 0, numberOfLevels: 1,
            levelTimerValue: 0, packTimerValue: 0,
            deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0,
            paddleHitsPerLevel: 0, multiplier: 1,
            brickTextures: [], brickColours: [],
            brickXPositions: [], brickYPositions: [],
            ballProperties: [],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [],
            fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [],
            activePowerUpTimers: [], activePowerUpMagnitudes: [])
        game.savedGameWidth = gameWidth
        game.savedFieldTop = fieldTop
        return game
    }

    /// A save from before this existed asks for nothing, and gets nothing.
    func testASaveThatCannotSayWhatItWasWrittenInIsLeftAlone() {
        XCTAssertNil(ResumeGeometry(saved: saved(gameWidth: nil, fieldTop: nil),
                                    gameWidth: 720, fieldTop: 800))
        XCTAssertNil(ResumeGeometry(saved: saved(gameWidth: 0), gameWidth: 720, fieldTop: 800))
    }

    /// The phone case, which is every resume this app has ever done: nothing moves.
    func testTheSameLayoutIsTheIdentity() throws {
        let same = try XCTUnwrap(ResumeGeometry(saved: saved(), gameWidth: 360, fieldTop: 400))
        XCTAssertTrue(same.isIdentity)
        XCTAssertEqual(same.x(-137.5), -137.5, accuracy: 0.0001)
        XCTAssertEqual(same.y(112.25), 112.25, accuracy: 0.0001)
        XCTAssertEqual(same.length(40), 40, accuracy: 0.0001)
    }

    /// A wider layout: everything grows about the centre, which is where x is measured from.
    func testAWiderLayoutSpreadsThePlayfieldFromItsCentre() throws {
        let wider = try XCTUnwrap(ResumeGeometry(saved: saved(), gameWidth: 540, fieldTop: 600))
        XCTAssertEqual(wider.scale, 1.5, accuracy: 0.0001)
        XCTAssertEqual(wider.x(0), 0, accuracy: 0.0001, "the centre stays the centre")
        XCTAssertEqual(wider.x(-100), -150, accuracy: 0.0001)
        XCTAssertEqual(wider.length(20), 30, accuracy: 0.0001, "a brick is bigger too")
    }

    /// The vertical rule is the one that matters: distance below the top of the field, in
    /// bricks. A plain scale about the origin would put the field somewhere else entirely,
    /// because the top bar's height does not scale with the play area.
    func testHeightIsMeasuredDownFromTheTopOfTheField() throws {
        let taller = try XCTUnwrap(ResumeGeometry(saved: saved(), gameWidth: 540, fieldTop: 600))

        XCTAssertEqual(taller.y(400), 600, accuracy: 0.0001,
                       "a brick on the top row is still on the top row")
        XCTAssertEqual(taller.y(340), 510, accuracy: 0.0001,
                       "and one 60 below it - three bricks at the old size - is 90 below now, "
                       + "which is the same three bricks")
    }

    /// The report itself: a ball saved in a tall narrow layout, read into a short wide one.
    func testTheBallComesBackInsideThePlayArea() throws {
        let saveWidth: CGFloat = 360, saveTop: CGFloat = 700
        let nowWidth: CGFloat = 300, nowTop: CGFloat = 420
        let into = try XCTUnwrap(ResumeGeometry(saved: saved(gameWidth: Double(saveWidth),
                                                             fieldTop: Double(saveTop)),
                                                 gameWidth: nowWidth, fieldTop: nowTop))

        // Two thirds of the way down a 22-row field, a third of the way right
        let rows = CGFloat(GameSceneLayout.brickRows)
        let brickHeightThen = saveWidth/rows
        let ball = CGPoint(x: saveWidth/3, y: saveTop - brickHeightThen*14)
        let moved = into.point(ball)

        let brickHeightNow = nowWidth/rows
        XCTAssertEqual(moved.x, nowWidth/3, accuracy: 0.01,
                       "still a third of the way across")
        XCTAssertEqual(moved.y, nowTop - brickHeightNow*14, accuracy: 0.01,
                       "still fourteen rows down - not below the line the run is lost at")
        XCTAssertLessThan(abs(moved.x), nowWidth/2, "and inside the walls")
    }
}

/// **A resume, driven the way the game drives one** (§12.0's open item since round 319f: "nothing
/// in the suite can drive a level being built, which is why the resume path is 2% covered").
///
/// The path, as the game takes it: `PreGame` resets the run, `Playing.loadNextLevel` puts the
/// save's scores back and - because the save carries its field - rebuilds the bricks from it
/// rather than loading a level from the catalogue, and `resumeGame` restores the ball and paddle
/// and ends in `Paused`, where the player picks the run back up. Round 319g's fixture read
/// "savedGame is nil and resumeGameToLoad is false by the end" as the scores never arriving;
/// the flag being spent is the resume *working*, because a resumed run must never be resumable
/// a second time from the same moment. The one step skipped is `PreGame`'s one-second wait,
/// which is an action and never runs in a scene nothing presents - so the test takes the
/// transition that wait would have taken.
///
/// **Nothing here may outlive the process.** The scene's defaults are a suite of its own with
/// every key this path reads written into it (a suite still falls back to the app's domain for
/// anything it lacks, which is how an earlier version of these tests read a real game), and the
/// stats file it saves on pausing is a temporary one. Both are removed afterwards; a suite left
/// behind by a killed run is one the app never reads.
final class ResumeTransitionTests: XCTestCase {

    private final class Host: GameViewControllerDelegate {
        var selectedLevel: Int? = 1
        var numberOfLevels: Int? = 1
        var levelSender: String? = "Level Selector"
        var levelPack: Int? = 1
        var pauseMenus: [String] = []
        func moveToMainMenu() {}
        func showPauseMenu(levelNumber: Int, numberOfLevels: Int, score: Int, packNumber: Int,
                           height: Int, sender: String, gameoverBool: Bool, newItemsBool: Bool,
                           previousHighscore: Int, livesRemaining: Int, levelScore: Int,
                           levelTimerBonus: Int) {
            pauseMenus.append(sender)
        }
        func showConfirm(_ confirm: GigaBallConfirm) {}
        func showInbetweenView(levelNumber: Int, score: Int, packNumber: Int,
                               levelTimerBonus: Int, firstLevel: Bool, numberOfLevels: Int,
                               levelScore: Int) {}
    }

    private let suiteName = "GigaBallTests.ResumeTransitionTests"
    // **One name, cleared at both ends**, rather than a fresh one per test. Removing a domain
    // empties it and leaves its file, so unique names left a plist behind for every test ever
    // run; a fixed one is at most one file, and clearing it in `setUp` as well tidies after a
    // killed run instead of reading what it left
    private var statsFile: URL!
    private var host: Host!

    /// The bottom row's height in these fixtures.
    ///
    /// **A saved Mayhem field always has a brick on it.** Play steps the field down the moment
    /// the bottom row empties, and `countBricks` - which the resume runs - does the same, so a
    /// field saved with nothing low comes back a row lower and a metre higher. That is the game
    /// closing a gap, not the resume adding height, and a save written in play never has one.
    static let bottomRow: CGFloat = 100

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        statsFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName + ".totalStats.plist")
        try? FileManager.default.removeItem(at: statsFile)
        DailyChallengeSession.shared.active = nil
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: statsFile)
        host = nil
        super.tearDown()
    }

    /// A Classic run left mid-level: three bricks, the ball in flight, a level part-scored.
    private func leftMidLevel() -> SavedGame {
        SavedGame(
            levelNumber: 1, endLevelNumber: 1, packNumber: 2,
            levelScore: 120, totalScore: 3_400, numberOfLives: 2,
            endlessHeight: 0, numberOfLevels: 1,
            levelTimerValue: 45, packTimerValue: 45,
            deathsPerLevel: 1, deathsPerPack: 1,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0,
            paddleHitsPerLevel: 12,
            multiplier: 1.4,
            brickTextures: [0, 4, 8], brickColours: [0, 1, 2],
            brickXPositions: [0, 1, 2], brickYPositions: [0, 0, 1],
            ballProperties: [12.5, 300.0, -120.0, 240.0, 30.0],
            fallingPowerUpXPositions: [2], fallingPowerUpYPositions: [5],
            fallingPowerUps: [4],
            activePowerUps: [], activePowerUpDurations: [], activePowerUpTimers: [],
            activePowerUpMagnitudes: [])
        // One Expand Paddle on its way down, which the resume has to put back in the air. In
        // cells, like the legacy bricks: the save rounds a drop to the column and row it is
        // nearest, and the resume puts it back on that cell
    }

    /// An Endless Mayhem run left at 37m, its field saved brick by brick (round 150's format):
    /// a plain brick, a Spinning one, an anchored Fixed one and a hidden Multi-Hit.
    private func mayhemLeftAtHeight() -> SavedGame {
        var game = SavedGame(
            levelNumber: 0, endLevelNumber: 0, packNumber: 1,
            levelScore: 0, totalScore: 0, numberOfLives: 0,
            endlessHeight: 37, numberOfLevels: 1,
            levelTimerValue: 90, packTimerValue: 90,
            deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0,
            paddleHitsPerLevel: 20,
            multiplier: 1,
            brickTextures: [0, 0, 0, 4], brickColours: [3, 3, 3, 0],
            brickXPositions: [0, 1, 2, 4], brickYPositions: [0, 0, 1, 1],
            ballProperties: [-40.0, 120.0, 180.0, 260.0, -20.0],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [], fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [], activePowerUpTimers: [],
            activePowerUpMagnitudes: [])
        // The legacy arrays ride along as the game writes them, and they are also what sends
        // `loadNextLevel` down the resume branch at all - an empty field loads a level
        func brick(x: Double, y: Double, texture: Int = 0, hidden: Bool = false,
                   role: String? = nil, styles: [String] = [], anchored: Bool = false,
                   plain: Bool = false) -> SavedGame.SavedBrick {
            SavedGame.SavedBrick(texture: texture, colour: 3, x: x, y: y, width: 40, height: 20,
                                 anchorX: 0.5, anchorY: 0.5, hidden: hidden, role: role,
                                 face: nil, faceMirrored: nil, faceFlipped: nil, styles: styles,
                                 portalBlue: false, anchored: anchored, powerUpIndex: nil,
                                 staysPlain: plain)
        }
        game.endlessIIBricks = [
            brick(x: -160, y: Double(ResumeTransitionTests.bottomRow), plain: true),
            // On the bottom row, as the lowest brick of any field saved in play is
            brick(x: -120, y: 200, styles: [EndlessIIStyle.spinning.rawValue]),
            brick(x: -80, y: 180, role: EndlessIIRole.fixed.rawValue, anchored: true),
            brick(x: 0, y: 180, texture: 4, hidden: true),
        ]
        return game
    }

    private func resumedScene(from save: SavedGame? = nil, mode: GameMode = .classic,
                              level: Int = 1, levels: Int = 1,
                              resuming: Bool = true) throws -> GameScene {
        let saved = save ?? leftMidLevel()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        for key in ["musicSetting", "soundsSetting", "hapticsSetting", "firstPause",
                    "swipeUpPause", "gameInProgress", "iCloudSetting", "gameCenterSetting"] {
            defaults.set(false, forKey: key)
        }
        if resuming {
            saved.save(to: defaults)
            defaults.set(true, forKey: SavedGame.resumeFlagKey)
        }
        // Not resuming is a run started fresh, which is how a test gets a level to finish

        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.defaults = defaults
        scene.totalStatsStore = statsFile
        scene.totalStatsArray = [TotalStats()]
        scene.gameMode = mode
        // What `didMove` takes from the save's own mode on a resume
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        // What `didMove` fills, and what a falling power-up is put back by index into
        scene.gameWidth = 360
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.ballSize = 12
        scene.paddleWidth = 90
        scene.ballSpeedSlowest = 200
        scene.ballSpeedSlow = 280
        scene.ballSpeedNominal = 360
        scene.ballSpeedFast = 460
        scene.ballSpeedFastest = 560
        scene.ballSpeedLimit = scene.ballSpeedNominal
        // Five different speeds, because `didMove` sets them and a bare scene holds all five at
        // zero - where "the limit is the fast one" is true of every limit there is
        scene.finalBrickRowHeight = ResumeTransitionTests.bottomRow
        // Where the field's lowest row sits, which `didMove` works out from the screen
        scene.packLevelHighScoresArray = Array(repeating: Array(repeating: 0, count: 10),
                                               count: LevelPackSetup().numberOfLevels.count - 2)
        // One row of level bests per campaign pack, as `didMove` builds it from the stats -
        // a finished level compares itself against its own, indexed from pack 2
        scene.addChild(scene.ball)
        // **On the field.** Round 322b's bottom-row edit replaced this line rather than going
        // after it, and every resume test ran for a round with a ball that was never in the
        // scene - positions written to a detached node still read back, so nothing failed.
        // The ball-centring test found it by asking the one question the others did not
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.paddle.size = CGSize(width: 90, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.addChild(scene.paddle)
        scene.backstop.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 360, height: 12))
        // The scene file gives the backstop its body, and a resumed Backstop sets its masks

        host = Host()
        host.selectedLevel = level
        host.numberOfLevels = levels
        host.levelPack = level == 0 ? 1 : 2
        // Pack 1 is Endless Mode and pack 2 the Classic Pack, levels 1 to 10 -
        // `LevelPackSetup` numbers the tutorial as pack 0
        // What `MenuViewController.loadSavedGame` hands the game for a resume: the save's own
        // level, and the levels from there to the end of the run
        scene.gameViewControllerDelegate = host

        scene.resumeGameToLoad = resuming && defaults.bool(forKey: SavedGame.resumeFlagKey)
        scene.savedGame = resuming ? SavedGame.load(from: defaults) : nil
        // What `didMove` reads, read from the same place
        if resuming {
            XCTAssertNotNil(scene.savedGame,
                            "the fixture's save should load, or nothing below means anything")
        }

        scene.gameState.enter(PreGame.self)
        scene.gameState.enter(Playing.self)
        return scene
    }

    func testAResumedRunLandsPausedWithItsOwnScoresAndLives() throws {
        let scene = try resumedScene()

        XCTAssertTrue(scene.gameState.currentState is Paused,
                      "a resume hands the run back paused, for the player to pick up")
        XCTAssertEqual(host.pauseMenus, ["Pause"], "and shows the pause menu to do it from")

        XCTAssertEqual(scene.levelScore, 120)
        XCTAssertEqual(scene.totalScore, 3_400 - 120,
                       "the banked total, without the level in progress counted twice (round 319f)")
        XCTAssertEqual(scene.numberOfLives, 2,
                       "the save's two, not the three a fresh Classic rack starts with")
        XCTAssertEqual(scene.multiplier, 1.4, accuracy: 0.0001)
    }

    /// "Started by resuming an existing game, but the game had misplaced bricks below the low
    /// level line and no ball in sight" (James, round 313c).
    func testTheFieldAndTheBallComeBackWhereTheyWereLeft() throws {
        let scene = try resumedScene()

        var bricks: [SKNode] = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in bricks.append(node) }
        XCTAssertEqual(bricks.count, 3, "every saved brick, and no level loaded over them")
        let rows = Set(bricks.map { ($0.position.y*100).rounded() })
        XCTAssertEqual(rows.count, 2, "on the two rows they were saved on")

        XCTAssertFalse(scene.ball.isHidden, "the ball is in sight")
        XCTAssertEqual(scene.ball.position.x, 12.5, accuracy: 0.01)
        XCTAssertEqual(scene.ball.position.y, 300, accuracy: 0.01)
        XCTAssertFalse(scene.ballIsOnPaddle, "and in flight, as it was")
        XCTAssertEqual(scene.paddle.position.x, 30, accuracy: 0.01)

        var drops: [SKSpriteNode] = []
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { drops.append(sprite) }
        }
        XCTAssertEqual(drops.count, 1, "the power-up that was falling is falling again")
        XCTAssertEqual(drops.first?.position.x ?? 0,
                       scene.gameWidth/2 - scene.brickWidth/2 - scene.brickWidth*2, accuracy: 0.01,
                       "in the third column, where it was saved")
        XCTAssertEqual(drops.first?.position.y ?? 0,
                       scene.yBrickOffset - scene.brickHeight*5, accuracy: 0.01,
                       "and the sixth row")
        XCTAssertTrue(drops.first?.texture === scene.powerUpTexturesInOrder[4],
                      "and it is the same power-up, Expand Paddle")
    }

    /// Resumed once, and never again from the same moment - but pausing the resumed run saves it
    /// afresh, and that save has to say what the run is now rather than doubling the level.
    func testTheResumeIsSpentAndThePauseSavesTheRunAsItStands() throws {
        let scene = try resumedScene()
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))

        XCTAssertTrue(scene.resumeGameToLoad,
                      "`resumeGame` spends the flag and the pause it ends in sets it again - every "
                      + "pause saves, and this one is the run's new resume point")
        XCTAssertTrue(defaults.bool(forKey: SavedGame.resumeFlagKey),
                      "and the store agrees with the scene, which is round 181's whole lesson")

        let resaved = try XCTUnwrap(SavedGame.load(from: defaults))
        XCTAssertEqual(resaved.totalScore, 3_400,
                       "a save writes total plus level, so it must match the save it came from")
        XCTAssertEqual(resaved.levelScore, 120)
        XCTAssertEqual(resaved.numberOfLives, 2)
        XCTAssertEqual(resaved.brickXPositions.count, 3)
        XCTAssertEqual(resaved.fallingPowerUps, [4])
    }

    /// **A Mayhem field comes back brick for brick** (play-test round 150: "on quitting the app
    /// and resuming, the bricks are different - some overlapping, some different types, some in
    /// different positions").
    func testAMayhemRunComesBackAtItsHeightWithEveryBrickAsItself() throws {
        let scene = try resumedScene(from: mayhemLeftAtHeight(), mode: .endlessII, level: 0)

        XCTAssertTrue(scene.gameState.currentState is Paused)
        XCTAssertTrue(scene.endlessMode)
        XCTAssertEqual(scene.endlessHeight, 37, "back at the height it was left at")

        var bricks: [SKSpriteNode] = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { bricks.append(sprite) }
        }
        XCTAssertEqual(bricks.count, 4,
                       "four records, four bricks - none rebuilt twice from the legacy arrays")
        XCTAssertEqual(Set(bricks.map { "\($0.position.x),\($0.position.y)" }).count, 4,
                       "and none on top of another")

        func brick(atX x: CGFloat) -> SKSpriteNode? {
            bricks.first { abs($0.position.x - x) < 0.01 }
        }
        let plain = try XCTUnwrap(brick(atX: -160), "the plain brick is where it was")
        XCTAssertEqual(plain.position.y, ResumeTransitionTests.bottomRow, accuracy: 0.01)
        XCTAssertTrue(scene.endlessIIStyles(on: plain).isEmpty, "and is still plain")

        let spinner = try XCTUnwrap(brick(atX: -120))
        XCTAssertTrue(scene.endlessIIStyles(on: spinner).contains(.spinning),
                      "the Spinning brick still spins")

        let fixed = try XCTUnwrap(brick(atX: -80))
        XCTAssertEqual(fixed.position.y, 180, accuracy: 0.01)
        XCTAssertTrue(scene.endlessIIStyles(on: fixed).contains(.fixed))
        XCTAssertTrue(fixed.endlessIIIsAnchored, "a Fixed brick that had been struck stays struck")

        let hidden = try XCTUnwrap(brick(atX: 0))
        XCTAssertTrue(hidden.isHidden, "a brick nobody had found is still hidden")
        XCTAssertTrue(hidden.texture === scene.brickMultiHit1Texture, "and still a Multi-Hit")

        XCTAssertEqual(scene.ball.position.x, -40, accuracy: 0.01)
        XCTAssertEqual(scene.ball.position.y, 120, accuracy: 0.01)
        XCTAssertFalse(scene.ballIsOnPaddle)
    }
}

extension ResumeTransitionTests {

    /// **Quit on the between-levels screen, come back to it, and carry on to the level it leads
    /// to** (play-test round 40, recorded where it was built in `Playing.loadNextLevel`: "The
    /// player quit looking at the between-levels screen, so that is where the run comes back.
    /// The level number in the save has already been advanced to the level this screen leads
    /// to, so the screen and the level that follows it are both the ones they left").
    ///
    /// Played for real rather than written by hand: the first scene finishes a level and lands
    /// on the screen, which writes the save the game writes, and the second resumes from it.
    /// Round 322b's first version of this test found that the resume skipped the next level
    /// and counted the finished one twice.
    func testAResumeBetweenLevelsCarriesOnToTheLevelTheScreenLeadsTo() throws {
        let setup = LevelPackSetup()
        let pack = 2
        let first = setup.startLevelNumber[pack]
        let levels = setup.numberOfLevels[pack]

        let playing = try resumedScene(level: first, levels: levels, resuming: false)
        XCTAssertTrue(playing.gameState.currentState is Playing)
        playing.levelScore = 300
        playing.levelTimerBonus = 200
        playing.gameState.enter(InbetweenLevels.self)
        // The first level, finished, and the screen after it
        XCTAssertEqual(playing.totalStatsArray[0].levelsCompleted, 1, "counted once, as it ends")

        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let save = try XCTUnwrap(SavedGame.load(from: defaults), "the screen is a resume point")
        XCTAssertTrue(save.resumesBetweenLevels)
        XCTAssertEqual(save.levelNumber, first + 1, "saved as the level the screen leads to")

        let resumed = try resumedScene(from: save, level: save.levelNumber,
                                       levels: save.endLevelNumber - save.levelNumber + 1)
        XCTAssertTrue(resumed.gameState.currentState is InbetweenLevels,
                      "back on the screen they quit on")
        XCTAssertEqual(resumed.levelNumber, first, "the screen for the level they finished")
        XCTAssertEqual(resumed.totalScore, playing.totalScore,
                       "with the total the screen showed, bonus and all")
        XCTAssertEqual(resumed.numberOfLives, playing.numberOfLives,
                       "and the extra ball a finished level gives")
        XCTAssertEqual(resumed.levelTimerBonus, 200, "and the time bonus it showed")
        XCTAssertEqual(resumed.totalStatsArray[0].levelsCompleted, 0,
                       "the level was counted when it was finished - coming back to its screen "
                       + "is not finishing it again")
        XCTAssertEqual(resumed.totalStatsArray[0].levelsPlayed, 0)

        let again = try XCTUnwrap(SavedGame.load(from: defaults),
                                  "and it is still the resume point, if they quit here again")
        XCTAssertEqual(again.levelNumber, first + 1)
        XCTAssertEqual(again.totalScore, save.totalScore)

        resumed.gameState.enter(Playing.self)
        // Continue, which is all `InbetweenLevels.notificationToContinueReceived` does
        XCTAssertEqual(resumed.levelNumber, first + 1,
                       "the level this screen leads to, not the one after it")
    }
}

extension ResumeTransitionTests {

    /// A run left with power-ups still running comes back with them running: the effect, its
    /// icon, its bar and its timer.
    ///
    /// Expand Paddle is the one worth pinning, because round 322 changed how a paddle's size is
    /// tracked - `paddleSizeTarget`, set by `runPaddleSizeScale` - and the resume goes through
    /// that same function. A resumed Expand that did not record its target would leave the next
    /// Expand or Shrink stepping from the wrong size, which is James's round 320 report again.
    func testPowerUpsInEffectComeBackRunning() throws {
        var save = leftMidLevel()
        save.activePowerUps = ["paddleSizeTimer", "ballSpeedTimer"]
        save.activePowerUpDurations = [4.0, 6.0]
        save.activePowerUpTimers = [10.0, 10.0]
        save.activePowerUpMagnitudes = [2, 2]
        // An Expand to 1.5 and a Speed Up to fast, each part-way through

        let scene = try resumedScene(from: save)
        XCTAssertTrue(scene.gameState.currentState is Paused)

        XCTAssertEqual(scene.paddleSizeTarget, 1.5, accuracy: 0.0001,
                       "the paddle is heading for its expanded size, as the next Expand or Shrink "
                       + "will read it")
        XCTAssertTrue(scene.paddleSizeIcon.texture === scene.iconIncreasePaddleSizeTexture,
                      "the tray says Expand")
        XCTAssertFalse(scene.paddleSizeIconBar.isHidden, "with its bar showing")
        XCTAssertNotNil(scene.action(forKey: "powerUpIncreasePaddleSize"),
                        "and its timer is running again, so it ends")

        XCTAssertEqual(scene.ballSpeedLimit, scene.ballSpeedFast, accuracy: 0.0001,
                       "the ball is held at the fast speed it was left at")
        XCTAssertNotEqual(scene.ballSpeedLimit, scene.ballSpeedNominal,
                          "which is not where a fresh run starts")
        XCTAssertFalse(scene.ballSpeedIconBar.isHidden)
    }
}

/// **A scene under tests keeps its writes to itself** (round 322b: the simulator's installed app
/// was found holding a test's saved game, the resume flag and `gameInProgress`).
final class TestScenesKeepToThemselvesTests: XCTestCase {

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: GameScene.testSettingsSuite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: GameScene.testSettingsSuite)
        super.tearDown()
    }

    func testASceneUnderTestHasNeitherTheAppsSettingsNorItsStatsFile() {
        let scene = GameScene()
        XCTAssertFalse(scene.defaults === UserDefaults.standard,
                       "a test scene writing `.standard` writes the installed app's own settings")
        XCTAssertNil(scene.totalStatsStore,
                     "and one with the real stats file would overwrite the player's stats")
    }

    /// The write that was actually found: entering play sets `gameInProgress`, and a test never
    /// leaves play to set it back.
    func testEnteringPlayWritesTheScenesStoreAndNotTheApps() {
        let before = UserDefaults.standard.object(forKey: "gameInProgress") as? Bool

        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        scene.addChild(scene.ball)
        scene.gameState.enter(Playing.self)

        XCTAssertTrue(scene.defaults.bool(forKey: "gameInProgress"), "the scene's own store has it")
        XCTAssertEqual(UserDefaults.standard.object(forKey: "gameInProgress") as? Bool, before,
                       "and the app's settings are exactly as they were")
    }

    /// **A game laid out under tests reads no stats file rather than trapping on one** (round
    /// 325). Round 322b gave a test scene no stats file and `loadGameData` still unwrapped it.
    /// Nothing noticed until the suite ran on a simulator whose app held a real save: the host
    /// resumed it behind the tests, and the game trapped in `didMove` the next time a test
    /// waited, so a full run relaunched twice and named a frame-cost test that had only waited.
    func testLoadingGameDataWithNoStatsFileKeepsTheStatsTheSceneWasGiven() {
        let scene = GameScene()
        XCTAssertNil(scene.totalStatsStore)
        let given = TotalStats()
        scene.totalStatsArray = [given]

        scene.loadGameData()

        XCTAssertTrue(scene.totalStatsArray.first === given, "nothing read over the scene's own record")
        XCTAssertEqual(scene.packLevelHighScoresArray?.count, 11,
                       "and the pack bests are still built from it, one list a pack")
    }

    /// And a scene given no record at all, which is what a presented game under tests has.
    func testLoadingGameDataWithNoStatsFileAndNoRecordLeavesTheSceneAlone() {
        let scene = GameScene()
        scene.totalStatsArray = []

        scene.loadGameData()

        XCTAssertTrue(scene.totalStatsArray.isEmpty)
        XCTAssertNil(scene.packLevelHighScoresArray, "no record, so no pack bests to build")
    }
}

extension ResumeTransitionTests {

    /// **Every level starts with the ball in the middle of the paddle** (James, round 323, with a
    /// screenshot: "at the start of levels, the ball was sometimes off centre from the paddle. It
    /// should be in the centre at the start of each level").
    ///
    /// A level that ends with the ball caught off-centre - a sticky catch lands it where it hit -
    /// left that offset behind, and the waiting ball is pinned to the paddle plus its offset
    /// every frame. So the next level put the ball in the middle and the pin moved it straight
    /// back out.
    func testTheNextLevelStartsWithTheBallInTheMiddleOfThePaddle() throws {
        let setup = LevelPackSetup()
        let pack = 2
        let first = setup.startLevelNumber[pack]

        let scene = try resumedScene(level: first, levels: setup.numberOfLevels[pack],
                                     resuming: false)
        XCTAssertNotNil(scene.ball.parent, "on the field when the level starts")
        scene.levelScore = 300
        scene.ballRelativePositionOnPaddle = 30
        // The level ends with the ball held thirty points right of centre, as a sticky catch
        // near the paddle's end leaves it
        scene.gameState.enter(InbetweenLevels.self)
        XCTAssertNotNil(scene.ball.parent, "on the field on the between-levels screen")
        scene.gameState.enter(Playing.self)
        // Continue

        XCTAssertEqual(scene.levelNumber, first + 1, "on the next level")
        XCTAssertTrue(scene.ballIsOnPaddle)
        XCTAssertEqual(scene.ballRelativePositionOnPaddle, 0, accuracy: 0.0001,
                       "with nothing left of where the last level's ball was held")

        XCTAssertNotNil(scene.ball.parent, "the ball is still on the field")
        XCTAssertNotNil(scene.ball.physicsBody, "with its body")
        scene.paddle.position.x = 40
        scene.holdTheWaitingBallStill()
        XCTAssertEqual(scene.ball.position.x, scene.paddle.position.x, accuracy: 0.01,
                       "and the waiting ball sits in the middle of the paddle, wherever it moves")
    }
}

extension ResumeTransitionTests {

    /// Mayhem's own power-ups, left running, come back running with the time they had.
    func testMayhemPowerUpsInEffectComeBackRunning() throws {
        var save = mayhemLeftAtHeight()
        save.activePowerUps = ["endlessIIMagnetism", "endlessIIDrift"]
        save.activePowerUpDurations = [5.0, 7.0]
        save.activePowerUpTimers = [10.0, 10.0]
        save.activePowerUpMagnitudes = [1, 0]
        save.endlessIIDriftDirection = -1
        // A second-level Magnetism half spent, and a leftward Drift with seven seconds to go

        let scene = try resumedScene(from: save, mode: .endlessII, level: 0)
        XCTAssertTrue(scene.gameState.currentState is Paused)

        XCTAssertTrue(scene.endlessIIMagnetismClock.isRunning, "Magnetism is still on")
        XCTAssertEqual(scene.endlessIIMagnetismClock.remaining, 5, accuracy: 0.01,
                       "with the time it had, not a fresh ten seconds")
        XCTAssertEqual(scene.endlessIIMagnetismClock.level, 1, "at the strength it had reached")

        XCTAssertTrue(scene.endlessIIDriftClock.isRunning, "the field is still drifting")
        XCTAssertEqual(scene.endlessIIDriftClock.remaining, 7, accuracy: 0.01)
        XCTAssertEqual(scene.endlessIIDriftDirection, -1, "and still drifting left")
    }

    /// A Multi-Ball's extra balls, and a laser on its way up, are where they were.
    func testExtraBallsAndLasersInFlightComeBack() throws {
        var save = mayhemLeftAtHeight()
        save.extraBallProperties = [60, 150, 200, 300,
                                    -60, 160, -150, 250]
        // Two extra balls, each travelling: position then heading
        save.laserXPositions = [30]
        save.laserYPositions = [50]

        let scene = try resumedScene(from: save, mode: .endlessII, level: 0)

        XCTAssertEqual(scene.endlessIIExtraBalls.count, 2, "both extra balls are back")
        XCTAssertEqual(scene.endlessIIExtraBalls.map(\.position.x).sorted(), [-60, 60],
                       "where they were")
        XCTAssertTrue(scene.endlessIIExtraBalls.allSatisfy { $0.parent === scene },
                      "and on the field")
        XCTAssertEqual(scene.pauseExtraBallVelocities.count, 2,
                       "each with its heading kept for when play resumes")

        var lasers: [SKNode] = []
        scene.enumerateChildNodes(withName: LaserCategoryName) { node, _ in lasers.append(node) }
        XCTAssertEqual(lasers.count, 1, "the laser that was travelling is travelling again")
        XCTAssertEqual(lasers.first?.position.x ?? 0, 30, accuracy: 0.01)
        XCTAssertEqual(lasers.first?.position.y ?? 0, 50, accuracy: 0.01)
    }

    /// A daily comes back as the day it was, with a Time Trial's clock where it stopped - "the
    /// one thing a Time Trial cannot give away" (round 197) - and a day that has closed comes
    /// back as practice.
    func testADailyComesBackWithItsDayAndItsClock() throws {
        let key = "2026-09-05"
        var save = leftMidLevel()
        save.dailyDateKey = key
        save.dailyWasScoringAttempt = true
        save.dailyTimeTrialRemaining = 42

        let session = DailyChallengeSession.shared
        let wasScoring = session.isScoringAttempt
        defer {
            session.active = nil
            session.isScoringAttempt = wasScoring
            session.resumedAfterDeadline = false
        }
        session.restore(from: save)
        // What `MenuViewController.loadSavedGame` does before the scene is built

        let scene = try resumedScene(from: save)
        XCTAssertTrue(scene.gameState.currentState is Paused)
        XCTAssertEqual(session.active?.dateKey, key, "the day it was")
        XCTAssertEqual(scene.dailyTimeTrialRemaining, 42, accuracy: 0.001,
                       "and the Time Trial's clock where it stopped, not a fresh ninety seconds")
        XCTAssertFalse(session.isScoringAttempt,
                       "a day that has closed since comes back as practice")
    }

    /// The original Endless mode, which keeps its field in the older arrays rather than Mayhem's
    /// brick records.
    func testAnEndlessRunComesBackAtItsHeightWithItsRows() throws {
        var save = leftMidLevel()
        save.levelNumber = 0
        save.endLevelNumber = 0
        save.packNumber = 1
        save.numberOfLevels = 1
        save.endlessHeight = 120
        save.gameMode = GameMode.endless.rawValue
        save.fallingPowerUpXPositions = []
        save.fallingPowerUpYPositions = []
        save.fallingPowerUps = []

        let scene = try resumedScene(from: save, mode: .endless, level: 0)
        XCTAssertTrue(scene.gameState.currentState is Paused)
        XCTAssertTrue(scene.endlessMode)
        XCTAssertEqual(scene.endlessHeight, 120, "back at the height it was left at")

        var bricks: [SKNode] = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in bricks.append(node) }
        XCTAssertEqual(bricks.count, 3)
        let expected = Set(zip(save.brickXPositions, save.brickYPositions).map { column, row in
            "\(scene.gameWidth/2 - scene.brickWidth/2 - scene.brickWidth*CGFloat(column)),"
                + "\(scene.resumedBrickTopRow - scene.brickHeight*CGFloat(row))"
        })
        XCTAssertEqual(Set(bricks.map { "\($0.position.x),\($0.position.y)" }), expected,
                       "every brick on the cell it was saved in")
    }
}

extension ResumeTransitionTests {

    /// **Every one of the original power-ups a resume restores, restored** (round 323, the gap
    /// round 322b's note left: "a resume for every one of `resumeGame`'s power-up cases").
    ///
    /// `resumeGame` is a switch written case by case, and a case that restored the icon but not
    /// the effect - or the effect but not the timer that ends it - would read as a power-up that
    /// quietly stops working, or never stops, after a player comes back to a run.
    func testEveryOriginalPowerUpInEffectComesBack() throws {
        var save = leftMidLevel()
        let running: [(key: String, magnitude: Int)] = [
            ("gravityTimer", 0), ("invisibleBricksTimer", 0), ("gigaBallTimer", 0),
            ("laserTimer", 2), ("ballSizeTimer", 2), ("stickyPaddle", 3), ("backstop", 1),
            ("endlessIITrajectory", 1), ("endlessIILanding", 0)]
        save.activePowerUps = running.map(\.key)
        save.activePowerUpDurations = running.map { _ in 6.0 }
        save.activePowerUpTimers = running.map { _ in 10.0 }
        save.activePowerUpMagnitudes = running.map(\.magnitude)

        let scene = try resumedScene(from: save)
        defer { scene.laserTimer?.invalidate() }
        // The resumed Lasers start a real repeating timer on the scene; stopped here so it does
        // not outlive the test
        XCTAssertTrue(scene.gameState.currentState is Paused)

        XCTAssertTrue(scene.gravityActivated, "Gravity is pulling again")
        XCTAssertFalse(scene.gravityIconBar.isHidden)
        XCTAssertNotNil(scene.action(forKey: "powerUpGravityBall"), "and will end")

        XCTAssertFalse(scene.hiddenBricksIconBar.isHidden, "Hide Bricks is still counting down")
        XCTAssertNotNil(scene.action(forKey: "powerUpInvisibleBricks"))

        XCTAssertEqual(scene.ballDress, .giga, "the ball is still a Giga-Ball")
        XCTAssertTrue(scene.ball.texture === scene.gigaBallTexture, "and looks it")
        XCTAssertNotNil(scene.action(forKey: "powerUpGigaBall"))

        XCTAssertTrue(scene.laserPowerUpIsOn, "the lasers are still firing")
        XCTAssertEqual(scene.laserStacks, min(2, GameScene.laserMaxStacks), "at the stack they had")
        XCTAssertFalse(scene.paddleLaser.isHidden, "from the turrets")
        XCTAssertNotNil(scene.laserTimer, "on a timer")
        XCTAssertNotNil(scene.action(forKey: "powerUpLasers"))

        XCTAssertEqual(scene.ball.xScale, 1.5, accuracy: 0.001, "the ball is still big")
        XCTAssertEqual(scene.ballSizeTarget, 1.5, accuracy: 0.001,
                       "and heading nowhere else, as the next Grow or Shrink will read it")
        XCTAssertNotNil(scene.action(forKey: "powerUpIncreaseBallSize"))

        XCTAssertEqual(scene.stickyPaddleCatches, 3, "the sticky paddle has its catches left")
        XCTAssertFalse(scene.stickyPaddleIconBar.isHidden)

        XCTAssertFalse(scene.backstop.isHidden, "the backstop is back under the field")
        XCTAssertEqual(scene.backstopCatches, 1)

        XCTAssertEqual(scene.endlessIITrajectoryRemaining, 6, accuracy: 0.01,
                       "the trajectory line has the time it had")
        XCTAssertEqual(scene.endlessIILandingRemaining, 6, accuracy: 0.01,
                       "and so does the landing marker")
    }

    /// Giga-Ball's other form, which the save tells apart by magnitude.
    func testAnUndestructiBallComesBackAsItself() throws {
        var save = leftMidLevel()
        save.activePowerUps = ["gigaBallTimer"]
        save.activePowerUpDurations = [5.0]
        save.activePowerUpTimers = [10.0]
        save.activePowerUpMagnitudes = [1]

        let scene = try resumedScene(from: save)
        XCTAssertEqual(scene.ballDress, .undestructi, "an Undestructi-Ball, not a Giga-Ball")
        XCTAssertTrue(scene.ball.texture === scene.undestructiballTexture)
    }
}

// MARK: - A Classic level ending, played for real

/// **What finishing a level records** (round 325's coverage pass: the between-levels ending had
/// 41% of its lines run, and it writes the Classic stats and the scores behind the pack
/// leaderboards - the scores CLAUDE.md says must stay valid). Driven through the same fixture as
/// the resume tests, from `Playing` into `InbetweenLevels` as a level really ends.
extension ResumeTransitionTests {

    private var classicPack: (pack: Int, first: Int, levels: Int) {
        let setup = LevelPackSetup()
        return (2, setup.startLevelNumber[2], setup.numberOfLevels[2])
    }

    func testFinishingALevelMidPackCountsItUnlocksTheNextAndGivesABall() throws {
        let (_, first, levels) = classicPack
        let scene = try resumedScene(level: first, levels: levels, resuming: false)
        let livesBefore = scene.numberOfLives
        scene.levelScore = 300
        scene.levelTimerBonus = 200
        scene.levelTimerValue = 40

        scene.gameState.enter(InbetweenLevels.self)
        let stats = scene.totalStatsArray[0]

        XCTAssertEqual(scene.totalScore, 500, "the level and its time bonus are banked")
        XCTAssertEqual(scene.numberOfLives, livesBefore + 1, "a finished level gives a ball")
        XCTAssertEqual(stats.levelsPlayed, 1)
        XCTAssertEqual(stats.levelsCompleted, 1)
        let next = try XCTUnwrap(Progression.nextLevelIndex(after: first, endLevelNumber: scene.endLevelNumber))
        XCTAssertTrue(stats.levelUnlockedArray[next], "and the next level opens")
        XCTAssertEqual(stats.pack1LevelHighScores[0], 500,
                       "the level's best is its score and time bonus, against that level")
        XCTAssertEqual(stats.packsPlayed, 0, "a pack is not played until it ends")
        XCTAssertEqual(stats.packsCompleted, 0)
    }

    func testFinishingThePacksLastLevelCompletesThePack() throws {
        let (_, first, levels) = classicPack
        let scene = try resumedScene(level: first, levels: levels, resuming: false)
        scene.levelNumber = scene.endLevelNumber
        // The run has reached the last level of the pack
        scene.numberOfLives = 2
        scene.levelScore = 300
        scene.levelTimerBonus = 200
        scene.levelTimerValue = 40

        scene.gameState.enter(InbetweenLevels.self)
        let stats = scene.totalStatsArray[0]

        XCTAssertEqual(scene.totalScore, 300 + 200 + 2*100,
                       "the level, its time bonus, and a hundred for every ball left")
        XCTAssertEqual(scene.numberOfLives, 2, "no extra ball after the last level")
        XCTAssertEqual(stats.packsPlayed, 1)
        XCTAssertEqual(stats.packsCompleted, 1, "the pack is complete")
        XCTAssertEqual(stats.packHighScores[0], 700, "and its total is the pack's best")
        XCTAssertEqual(stats.packBestTimes[0], 40, "with its time the best time")
        XCTAssertEqual(stats.pack1LevelHighScores[levels - 1], 500,
                       "the last level's own best leaves the lives bonus out")
        XCTAssertEqual(first + levels - 1, scene.endLevelNumber, "the fixture is on the last level")
    }

    func testAGameOverMidPackRecordsThePackAsPlayedButNotCompleted() throws {
        let (_, first, levels) = classicPack
        let scene = try resumedScene(level: first, levels: levels, resuming: false)
        scene.levelNumber = first + 2
        scene.gameoverStatus = true
        scene.levelScore = 300
        scene.levelTimerBonus = 0
        scene.levelTimerValue = 40

        scene.gameState.enter(InbetweenLevels.self)
        let stats = scene.totalStatsArray[0]

        XCTAssertEqual(stats.packsPlayed, 1, "a pack that ended in a game over was played")
        XCTAssertEqual(stats.packsCompleted, 0, "but not completed")
        XCTAssertEqual(stats.packHighScores[0], 300, "its score still counts as the pack's best so far")
        XCTAssertEqual(stats.packBestTimes[0], 0, "and no best time, for a pack not finished")
        XCTAssertEqual(stats.levelsCompleted, 0, "the level it ended on was not completed")
        XCTAssertEqual(stats.levelsPlayed, 1, "though it was played")
        XCTAssertNil(SavedGame.load(from: try XCTUnwrap(UserDefaults(suiteName: suiteName))),
                     "and a finished game is never left to resume")
    }

    func testALowerScoreNeverReplacesALevelsBest() throws {
        let (_, first, levels) = classicPack
        let scene = try resumedScene(level: first, levels: levels, resuming: false)
        scene.packLevelHighScoresArray?[0][0] = 9_000
        scene.levelScore = 300
        scene.levelTimerBonus = 200

        scene.gameState.enter(InbetweenLevels.self)
        XCTAssertEqual(scene.totalStatsArray[0].pack1LevelHighScores[0], 9_000,
                       "a player's best stays their best")
    }
}
