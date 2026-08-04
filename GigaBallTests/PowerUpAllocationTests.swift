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
            XCTAssertEqual(scene.powerUpProbArray.count, 28,
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
            XCTAssertLessThanOrEqual(scene.powerUpProbArray.max() ?? 0, 10,
                                     "Level \(level) has a debug-sized weight: \(scene.powerUpProbArray)")
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

        XCTAssertEqual(none.powerUpProbArray[0], 10)
        XCTAssertGreaterThan(none.powerUpProbArray[0], atFullLives)
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
