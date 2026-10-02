//
//  PowerUpAllocationTests.swift
//  GigaBallTests
//
//  powerUpProbAllocation(levelNumber:) is an extension on GameScene rather
//  than a standalone type, so these tests drive a bare scene instance with its
//  two preconditions arranged by hand: a stats blob and a life count. Both are
//  normally set up in didMove, and the function crashes without the first -
//  worth knowing, because it means the allocation cannot be exercised without
//  a scene.
//
//  Several of these are characterisation tests. They pin what the code does
//  today, including one case where that is demonstrably wrong, so the
//  premiumSetting removal has something to diff against. Those are labelled.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class PowerUpAllocationTests: XCTestCase {

    /// The default table, before any per-level override or unlock filtering.
    private let defaultTable = [3, 3, 10, 10, 10, 10, 7, 7, 7, 7, 3, 3, 7, 7,
                                1, 5, 5, 5, 5, 5, 3, 3, 3, 7, 7, 3, 10, 10]

    /// A scene with no view, no .sks and no physics. `totalStatsArray` and
    /// `numberOfLives` are the only state the allocation reads; without the
    /// former it traps on `totalStatsArray[0]`.
    private func makeScene(stats: TotalStats = TotalStats(), lives: Int = 3) -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.totalStatsArray = [stats]
        scene.numberOfLives = lives
        return scene
    }

    /// Everything unlocked - the state the app actually runs in, because
    /// checkPremium() force-unlocks on every menu refresh.
    private func fullyUnlockedStats() -> TotalStats {
        let stats = TotalStats()
        stats.powerUpUnlockedArray = stats.powerUpUnlockedArray.map { _ in true }
        return stats
    }

    // MARK: - Coverage

    func testAllocationRunsForEveryRealLevel() {
        let scene = makeScene(stats: fullyUnlockedStats())
        for level in 0...110 {
            scene.powerUpProbAllocation(levelNumber: level)
            XCTAssertGreaterThanOrEqual(scene.powerUpProbFactor, 0,
                                        "Level \(level) produced a negative drop factor")
            XCTAssertEqual(scene.powerUpProbArray.count,
                           LevelPackSetup().powerUpNameArray.count,
                           "Level \(level) changed the size of the probability table")
        }
    }

    func testEndlessModeAllocationRuns() {
        let scene = makeScene(stats: fullyUnlockedStats())
        scene.powerUpProbAllocation(levelNumber: 999)
        XCTAssertGreaterThanOrEqual(scene.powerUpProbFactor, 0)
    }

    // MARK: - Production values

    func testProductionTablesAreNotDebugTables() {
        // Guards against the commented-out "Testing" block in
        // PowerUpAllocation.swift being re-enabled: it sets several entries to
        // 100 and the factor to 2. No authored level uses a weight above 10.
        let scene = makeScene(stats: fullyUnlockedStats())
        for level in 0...110 {
            scene.powerUpProbAllocation(levelNumber: level)
            XCTAssertLessThanOrEqual(scene.powerUpProbArray.max() ?? 0,
                                     10*GameScene.classicRarityScale,
                                     "Level \(level) has a debug-sized weight: \(scene.powerUpProbArray)")
            // Round 344 multiplied Classic's weights by the rarity scale, so the ceiling moved
            // with them; the debug block's 100 is still well above it
        }
    }

    func testEarlyLevelsIntroducePowerUpsGradually() {
        // Level 1 is the player's first real level and deliberately suppresses
        // most of the table - only the four speed and paddle-size power-ups and
        // the two ball-size ones drop. Pinned because it is authored intent
        // that reads like a mistake.
        let scene = makeScene(stats: fullyUnlockedStats())
        scene.powerUpProbAllocation(levelNumber: 1)

        let droppable = scene.powerUpProbArray.indices.filter { scene.powerUpProbArray[$0] > 0 }
        XCTAssertEqual(droppable, [2, 3, 4, 5, 26, 27])
        XCTAssertEqual(scene.powerUpProbFactor, 10)
    }

    func testProbabilitySumMatchesTheTable() {
        let scene = makeScene(stats: fullyUnlockedStats())
        scene.powerUpProbAllocation(levelNumber: 1)
        XCTAssertEqual(scene.powerUpProbSum, scene.powerUpProbArray.reduce(0, +),
                       "The cached sum is what the draw divides by")
    }

    func testNoProbabilityIsNegative() {
        let scene = makeScene(stats: fullyUnlockedStats())
        for level in 0...110 {
            scene.powerUpProbAllocation(levelNumber: level)
            XCTAssertFalse(scene.powerUpProbArray.contains { $0 < 0 },
                           "Level \(level) has a negative weight: \(scene.powerUpProbArray)")
        }
    }

    // MARK: - Life-count adjustment

    func testExtraLifeBecomesMoreLikelyWhenOutOfLives() {
        let plenty = makeScene(stats: fullyUnlockedStats(), lives: 3)
        plenty.powerUpProbAllocation(levelNumber: 1)
        let atFullLives = plenty.powerUpProbArray[0]

        let none = makeScene(stats: fullyUnlockedStats(), lives: 0)
        none.powerUpProbAllocation(levelNumber: 1)

        XCTAssertEqual(none.powerUpProbArray[0], 10*GameScene.classicRarityScale)
        XCTAssertGreaterThan(none.powerUpProbArray[0], atFullLives)
    }

    // MARK: - Round 344: Next Level and Get a Life, rare

    /// James's old task list: "Reduce likelihood of next level power up." A quarter as likely,
    /// against everything else, as each level asked for.
    func testNextLevelIsAQuarterAsLikelyAsTheLevelAskedFor() {
        let table = defaultTable
        let rebalanced = GameScene.classicOddsRebalanced(table, livesInReserve: 3)
        let before = Double(table[14])/Double(table.reduce(0, +))
        let after = Double(rebalanced[14])/Double(rebalanced.reduce(0, +))
        XCTAssertLessThan(after, before/3.5, "Next Level went from \(before) to \(after)")
        for index in table.indices where index != 14 && index != 0 {
            XCTAssertEqual(rebalanced[index], table[index]*GameScene.classicRarityScale,
                           "\(index): everything else keeps its proportions to everything else")
        }
    }

    /// "Reduce likelihood of extra ball power-up massively unless user has only 0 or 1 lives
    /// left."
    func testGetALifeIsMassivelyRarerWithTwoOrMoreBallsLeft() {
        for lives in 2...4 {
            let scene = makeScene(stats: fullyUnlockedStats(), lives: lives)
            scene.powerUpProbAllocation(levelNumber: 25)
            XCTAssertLessThanOrEqual(scene.powerUpProbArray[0], 1, "\(lives) balls left")
            let share = Double(scene.powerUpProbArray[0])/Double(scene.powerUpProbSum)
            XCTAssertLessThan(share, 0.01, "\(lives) balls left: under one drop in a hundred")
        }
        for lives in 0...1 {
            let scene = makeScene(stats: fullyUnlockedStats(), lives: lives)
            scene.powerUpProbAllocation(levelNumber: 25)
            XCTAssertGreaterThanOrEqual(scene.powerUpProbArray[0], 7*GameScene.classicRarityScale,
                                        "\(lives) left: still the likely rescue it always was")
        }
    }

    /// And the weight follows the balls as they are lost and won mid-level, on the same scale.
    func testTheWeightFollowsTheBallsLeftMidLevel() {
        let scene = makeScene(stats: fullyUnlockedStats(), lives: 3)
        scene.powerUpProbAllocation(levelNumber: 25)
        scene.numberOfLives = 1
        scene.setGetALifeWeightForTheBallsLeft()
        XCTAssertEqual(scene.powerUpProbArray[0], 7*GameScene.classicRarityScale)
        scene.numberOfLives = 2
        scene.setGetALifeWeightForTheBallsLeft()
        XCTAssertEqual(scene.powerUpProbArray[0], 1)
        scene.numberOfLives = 5
        scene.setGetALifeWeightForTheBallsLeft()
        XCTAssertEqual(scene.powerUpProbArray[0], 0)
    }

    /// Both endless modes are left exactly as they were: their rows write weights back in the
    /// unscaled numbers.
    func testEndlessIsNotRebalanced() {
        let scene = makeScene(stats: fullyUnlockedStats(), lives: 0)
        scene.endlessMode = true
        scene.powerUpProbAllocation(levelNumber: 0)
        XCTAssertLessThanOrEqual(scene.powerUpProbArray.max() ?? 0, 10)
    }

    // MARK: - Determinism

    func testAllocationIsDeterministicForAGivenLevel() {
        // The randomness belongs in the draw, not the table.
        for level in [1, 25, 57, 104, 999] {
            let first = makeScene(stats: fullyUnlockedStats())
            let second = makeScene(stats: fullyUnlockedStats())
            first.powerUpProbAllocation(levelNumber: level)
            second.powerUpProbAllocation(levelNumber: level)
            XCTAssertEqual(first.powerUpProbArray, second.powerUpProbArray,
                           "Level \(level) allocated a different table on a second run")
        }
    }

    func testReallocationDoesNotAccumulate() {
        // One scene plays every level of a pack run, so allocation is called
        // repeatedly on the same instance.
        let scene = makeScene(stats: fullyUnlockedStats())
        scene.powerUpProbAllocation(levelNumber: 1)
        let firstPass = scene.powerUpProbArray
        scene.powerUpProbAllocation(levelNumber: 57)
        scene.powerUpProbAllocation(levelNumber: 1)
        XCTAssertEqual(scene.powerUpProbArray, firstPass)
    }

    // MARK: - Unlock filtering

    /// Runs one level with exactly one power-up locked and returns the table,
    /// so the unlock filter can be isolated from the per-level overrides.
    private func table(forLevel level: Int, locking index: Int?) -> [Int] {
        let stats = fullyUnlockedStats()
        if let index { stats.powerUpUnlockedArray[index] = false }
        let scene = makeScene(stats: stats)
        scene.powerUpProbAllocation(levelNumber: level)
        return scene.powerUpProbArray
    }

    func testLockingAPowerUpStopsItDropping() {
        // Regression test for the unlock filter. It used to read
        //
        //     for i in powerUpProbArray { ... powerUpProbArray[i] = 0 }
        //
        // which walks the probability *values* - 0, 1, 3, 5, 7, 10 - and uses
        // them as indices. No authored weight exceeds 10, so locking anything
        // above index 10 did nothing at all: Lasers at index 22 still dropped
        // at full probability for a player who had not earned it.
        //
        // Index 22 is the case the old loop could never reach, so it is the one
        // worth pinning.
        let lasers = 22
        let baseline = table(forLevel: 2, locking: nil)
        let withLasersLocked = table(forLevel: 2, locking: lasers)

        XCTAssertGreaterThan(baseline[lasers], 0,
                             "Fixture assumes Lasers can drop on this level")
        XCTAssertEqual(withLasersLocked[lasers], 0,
                       "A locked power-up must not drop")
    }

    func testLockingAPowerUpAffectsOnlyThatPowerUp() {
        // The other half of the same bug: indices that coincided with a weight
        // value were zeroed whether or not they were locked.
        for locked in [0, 3, 10, 14, 22, 27] {
            let baseline = table(forLevel: 2, locking: nil)
            let filtered = table(forLevel: 2, locking: locked)

            var expected = baseline
            expected[locked] = 0
            XCTAssertEqual(filtered, expected,
                           "Locking index \(locked) changed some other power-up")
        }
    }

    func testEveryLockedPowerUpIsFilteredOnAFreshInstall() {
        // The state a player would be in once the premiumSetting force-unlock
        // is removed: several power-ups genuinely locked.
        let stats = TotalStats()
        let scene = makeScene(stats: stats)
        scene.powerUpProbAllocation(levelNumber: 2)

        let stillDroppable = stats.powerUpUnlockedArray.indices.filter {
            !stats.powerUpUnlockedArray[$0] && scene.powerUpProbArray[$0] > 0
        }
        XCTAssertTrue(stillDroppable.isEmpty,
                      "Locked power-ups can still drop: \(stillDroppable)")
    }

    func testSumIsRecalculatedAfterFiltering() {
        // The bounds check used to be a `return`, which skipped the sum and
        // left powerUpProbSum stale from the previous level. The draw divides
        // by that sum.
        let scene = makeScene(stats: TotalStats())
        scene.powerUpProbAllocation(levelNumber: 2)
        XCTAssertEqual(scene.powerUpProbSum, scene.powerUpProbArray.reduce(0, +))
    }

    func testUnlockFilterIsInertWhileEverythingIsUnlocked() {
        // Why none of the above is visible in the shipped app: with every
        // power-up unlocked the filter finds nothing to zero, so the table is
        // exactly what the level authored.
        for level in [0, 1, 2, 57, 110, 999] {
            let allUnlocked = table(forLevel: level, locking: nil)
            let alsoAllUnlocked = table(forLevel: level, locking: nil)
            XCTAssertEqual(allUnlocked, alsoAllUnlocked)
            XCTAssertFalse(allUnlocked.isEmpty)
        }
    }
}

/// Whether a power-up has anything to do right now (`powerUpCanAppear`), asked of every rule
/// in Classic and the original Endless. Round 358's coverage pass found half the function's
/// branches unrun: the drop generator has asked these questions since 2020 and the scoring
/// ones decide what can fall in modes with years of leaderboard scores on them.
final class PowerUpEligibilityTests: XCTestCase {

    private func scene(endless: Bool = false) -> GameScene {
        let scene = GameScene()
        scene.gameMode = endless ? .endless : .classic
        scene.endlessMode = endless
        scene.numberOfLives = 2
        scene.multiplier = 1.0
        return scene
    }

    @discardableResult
    private func bricks(_ scene: GameScene, _ count: Int, texture: SKTexture,
                        hidden: Bool = false, y: CGFloat = 200) -> [SKSpriteNode] {
        (0..<count).map { index in
            let brick = SKSpriteNode(texture: texture)
            brick.name = BrickCategoryName
            brick.isHidden = hidden
            brick.position = CGPoint(x: CGFloat(index)*40, y: y)
            scene.addChild(brick)
            return brick
        }
    }

    func testGetALifeStopsAtFiveAndNeverFallsInEndless() {
        let scene = scene()
        scene.numberOfLives = 4
        XCTAssertTrue(scene.powerUpCanAppear(0))
        scene.numberOfLives = 5
        XCTAssertFalse(scene.powerUpCanAppear(0))
        XCTAssertFalse(self.scene(endless: true).powerUpCanAppear(0), "one life by definition")
    }

    func testLoseALifeNeedsALifeToLoseAndIsNeverAMystery() {
        let scene = scene()
        XCTAssertTrue(scene.powerUpCanAppear(1))
        scene.numberOfLives = 0
        XCTAssertFalse(scene.powerUpCanAppear(1))
        scene.numberOfLives = 2
        scene.mysteryPowerUp = true
        XCTAssertFalse(scene.powerUpCanAppear(1))
        XCTAssertFalse(self.scene(endless: true).powerUpCanAppear(1))
    }

    func testPointsOnlyFallWhereThereIsAScore() {
        for index in [8, 10] {
            XCTAssertTrue(scene().powerUpCanAppear(index))
            XCTAssertFalse(scene(endless: true).powerUpCanAppear(index), "height is the score")
        }
    }

    func testLosingPointsNeedsTwiceTheLossToTakeFrom() {
        for (index, loss) in [(9, 100), (11, 1000)] {
            let scene = scene()
            scene.levelScore = loss*2
            XCTAssertFalse(scene.powerUpCanAppear(index), "\(index) at exactly twice the loss")
            scene.levelScore = loss*2 + 1
            XCTAssertTrue(scene.powerUpCanAppear(index))
            scene.mysteryPowerUp = true
            XCTAssertFalse(scene.powerUpCanAppear(index))
            let endless = self.scene(endless: true)
            endless.levelScore = loss*10
            XCTAssertFalse(endless.powerUpCanAppear(index))
        }
    }

    func testTheMultiplierUpsAndDownsRespectTheirLimits() {
        let scene = scene()
        scene.multiplier = 1.9
        XCTAssertTrue(scene.powerUpCanAppear(12))
        scene.multiplier = 2.0
        XCTAssertFalse(scene.powerUpCanAppear(12), "already at the cap")

        scene.multiplier = 1.1
        XCTAssertFalse(scene.powerUpCanAppear(13), "nothing to take away")
        scene.multiplier = 1.2
        XCTAssertTrue(scene.powerUpCanAppear(13))
        scene.mysteryPowerUp = true
        XCTAssertFalse(scene.powerUpCanAppear(13))
        XCTAssertFalse(self.scene(endless: true).powerUpCanAppear(12))
    }

    func testCompleteLevelIsClassicsAndNeverAMystery() {
        XCTAssertTrue(scene().powerUpCanAppear(14))
        XCTAssertFalse(scene(endless: true).powerUpCanAppear(14), "no next level to skip to")
        let mystery = scene()
        mystery.mysteryPowerUp = true
        XCTAssertFalse(mystery.powerUpCanAppear(14))
    }

    func testShowBricksNeedsThreeHidden() {
        let scene = scene()
        bricks(scene, 2, texture: scene.brickNormalTexture, hidden: true)
        XCTAssertFalse(scene.powerUpCanAppear(15))
        bricks(scene, 1, texture: scene.brickNormalTexture, hidden: true)
        XCTAssertTrue(scene.powerUpCanAppear(15))
    }

    func testHideBricksNeedsThreeOrdinaryBricks() {
        let scene = scene()
        for texture in [scene.brickMultiHit1Texture, scene.brickMultiHit2Texture,
                        scene.brickMultiHit3Texture, scene.brickMultiHit4Texture,
                        scene.brickInvisibleTexture, scene.brickIndestructible1Texture,
                        scene.brickIndestructible2Texture] {
            bricks(scene, 3, texture: texture)
        }
        XCTAssertFalse(scene.powerUpCanAppear(16), "none of those can be hidden")
        bricks(scene, 3, texture: scene.brickNormalTexture)
        XCTAssertTrue(scene.powerUpCanAppear(16))
    }

    func testTheMultiHitPowerUpsNeedTheBricksTheyWorkOn() {
        let clear = scene()
        bricks(clear, 2, texture: clear.brickMultiHit1Texture)
        bricks(clear, 2, texture: clear.brickMultiHit3Texture)
        XCTAssertFalse(clear.powerUpCanAppear(17), "two it can clear, two it cannot")
        bricks(clear, 1, texture: clear.brickMultiHit2Texture)
        XCTAssertTrue(clear.powerUpCanAppear(17))

        let reset = scene()
        bricks(reset, 5, texture: reset.brickMultiHit1Texture)
        XCTAssertFalse(reset.powerUpCanAppear(18), "none of them has been hit yet")
        bricks(reset, 1, texture: reset.brickMultiHit2Texture)
        bricks(reset, 1, texture: reset.brickMultiHit3Texture)
        bricks(reset, 1, texture: reset.brickMultiHit4Texture)
        XCTAssertTrue(reset.powerUpCanAppear(18))
    }

    func testZapIndestructibleNeedsThreeToZap() {
        let scene = scene()
        bricks(scene, 1, texture: scene.brickIndestructible1Texture)
        bricks(scene, 1, texture: scene.brickIndestructible2Texture)
        XCTAssertFalse(scene.powerUpCanAppear(19))
        bricks(scene, 1, texture: scene.brickIndestructible2Texture)
        XCTAssertTrue(scene.powerUpCanAppear(19))
    }

    func testClassicQuicksandStopsWhenTheFieldReachesThePaddle() {
        let scene = scene()
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.minPaddleGap = 40
        bricks(scene, 3, texture: scene.brickNormalTexture, y: -200)
        XCTAssertTrue(scene.powerUpCanAppear(23))
        bricks(scene, 1, texture: scene.brickNormalTexture, y: -261)
        XCTAssertFalse(scene.powerUpCanAppear(23), "the field is already at the bottom")
        XCTAssertFalse(self.scene(endless: true).powerUpCanAppear(23),
                       "the original Endless comes down by itself")
    }

    func testMysteryAndBackstopOnlyOnceAtATime() {
        let scene = scene()
        XCTAssertTrue(scene.powerUpCanAppear(24))
        scene.mysteryPowerUp = true
        XCTAssertFalse(scene.powerUpCanAppear(24))

        XCTAssertTrue(scene.powerUpCanAppear(25))
        scene.backstopCatches = 1
        XCTAssertFalse(scene.powerUpCanAppear(25), "one is already out")
        scene.backstopCatches = 0
        scene.backstopSpentThisRun = true
        XCTAssertFalse(scene.powerUpCanAppear(25), "once per run (round 320)")
    }

    func testEverythingElseCanAlwaysFall() {
        let scene = scene()
        for index in [2, 3, 4, 5, 6, 7, 20, 21, 22, 26, 27] {
            XCTAssertTrue(scene.powerUpCanAppear(index), "\(index)")
        }
    }
}
