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

    // MARK: - A finished game must never be saved

    func testAGameOverIsNeverSaved() {
        // Play test: "When relaunching app a previously completed game can sometimes
        // pick back up. This needs to be fixed. When a game is over it mustn't be
        // saved - this could allow users to cheat."
        let scene = GameScene()
        scene.totalStatsArray = [TotalStats()]
        scene.gameoverStatus = true
        XCTAssertTrue(scene.runIsOver)

        UserDefaults.standard.set(true, forKey: "resumeGameToLoad")
        scene.saveCurrentGame()
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "resumeGameToLoad"),
                       "a finished game must never be offered for resume")
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
