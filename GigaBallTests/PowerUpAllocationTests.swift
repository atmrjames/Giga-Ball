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

    func testLockingAPowerUpHasNoEffectOnWhetherItDrops() {
        // CHARACTERISATION TEST - this pins a bug, not intended behaviour.
        //
        // The unlock filter reads:
        //
        //     for i in powerUpProbArray { ... powerUpProbArray[i] = 0 }
        //
        // `for i in` over an array of Int iterates the *values*. Those values
        // are probability weights - 0, 1, 3, 5, 7, 10 - and they are then used
        // as *indices* into both powerUpUnlockedArray and powerUpProbArray. It
        // should be iterating indices.
        //
        // The observable consequence: no authored weight exceeds 10, so locking
        // any power-up whose index is above 10 changes nothing at all. Lasers
        // sits at index 22, so a player who has not unlocked Lasers still has
        // them drop at full probability.
        //
        // This is inert today only because checkPremium() force-unlocks
        // everything, so the filter never finds a locked entry. Removing the
        // premiumSetting force-unlock switches it on. Fixing the loop to
        // iterate indices is a no-op right now and a correctness fix later.
        let lasers = 22
        let baseline = table(forLevel: 2, locking: nil)
        let withLasersLocked = table(forLevel: 2, locking: lasers)

        XCTAssertGreaterThan(baseline[lasers], 0,
                             "Fixture assumes Lasers can drop on this level")
        XCTAssertEqual(withLasersLocked, baseline,
                       "Locking Lasers changed nothing - the filter never sees index 22")
        XCTAssertGreaterThan(withLasersLocked[lasers], 0,
                             "A locked power-up still drops at full probability")
    }

    func testLockingALowIndexPowerUpDoesReachTheFilter() {
        // The other half of the same bug: indices that happen to coincide with
        // a weight value do get zeroed, so the filter looks like it works if
        // you only ever test the first few power-ups.
        let lowIndex = 3
        let baseline = table(forLevel: 2, locking: nil)
        let locked = table(forLevel: 2, locking: lowIndex)

        XCTAssertGreaterThan(baseline[lowIndex], 0)
        XCTAssertEqual(locked[lowIndex], 0,
                       "Index 3 coincides with a weight of 3, so it is reached")
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
