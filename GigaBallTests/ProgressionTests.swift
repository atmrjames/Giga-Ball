//
//  ProgressionTests.swift
//  GigaBallTests
//
//  The unlock chain, which until now was eleven near-identical blocks inside a
//  GKState and therefore untestable. These indices are written into TotalStats
//  and synced to iCloud; one wrong entry hands a player the wrong theme, or
//  strands a pack permanently out of reach with no crash to point at it.
//
//  The strongest assertions here are the coverage ones: every entry of every
//  unlock array is accounted for exactly once between the TotalStats defaults
//  and this table. That is what catches an off-by-one, a duplicate, or a
//  forgotten entry when a twelfth pack is added.
//

import XCTest
@testable import Giga_Ball

final class ProgressionTests: XCTestCase {

    // MARK: - Shape

    func testThereIsOneRewardPerContentPack() {
        XCTAssertEqual(Progression.packRewards.count, 11)
    }

    func testRewardsAreOrderedByFinalLevel() {
        let levels = Progression.packRewards.map(\.finalLevel)
        XCTAssertEqual(levels, [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110])
        XCTAssertEqual(levels, levels.sorted())
    }

    func testFinalLevelsMatchLevelPackSetup() {
        // The table is keyed on the last level of each pack, so it has to agree
        // with the pack boundaries the rest of the app uses.
        let setup = LevelPackSetup()
        for (offset, reward) in Progression.packRewards.enumerated() {
            let pack = offset + 2   // indices 0 and 1 are tutorial and endless
            let expected = setup.startLevelNumber[pack] + setup.numberOfLevels[pack] - 1
            XCTAssertEqual(reward.finalLevel, expected,
                           "Pack \(pack) ends at level \(expected)")
        }
    }

    func testLookupFindsOnlyPackEndings() {
        XCTAssertNotNil(Progression.reward(forLevel: 10))
        XCTAssertNotNil(Progression.reward(forLevel: 110))
        XCTAssertNil(Progression.reward(forLevel: 1))
        XCTAssertNil(Progression.reward(forLevel: 55))
        XCTAssertNil(Progression.reward(forLevel: 0),   "Tutorial")
        XCTAssertNil(Progression.reward(forLevel: 999), "Endless mode")
    }

    // MARK: - Coverage: nothing missed, nothing handed out twice

    func testEveryThemeIsUnlockedExactlyOnce() {
        let stats = TotalStats()
        let granted = Progression.packRewards.map(\.themeIndex)
        let free = stats.themeUnlockedArray.indices.filter { stats.themeUnlockedArray[$0] }

        XCTAssertEqual(Set(granted).count, granted.count, "A theme is granted twice")
        XCTAssertEqual(Set(granted).union(free), Set(stats.themeUnlockedArray.indices),
                       "Some theme can never be unlocked")
    }

    func testEveryAppIconIsUnlockedExactlyOnce() {
        let stats = TotalStats()
        let granted = Progression.packRewards.map(\.appIconIndex)
        let free = stats.appIconUnlockedArray.indices.filter { stats.appIconUnlockedArray[$0] }

        XCTAssertEqual(Set(granted).count, granted.count, "An icon is granted twice")
        XCTAssertEqual(Set(granted).union(free), Set(stats.appIconUnlockedArray.indices),
                       "Some app icon can never be unlocked")
    }

    func testEveryPowerUpIsUnlockedExactlyOnce() {
        let stats = TotalStats()
        let granted = Progression.packRewards.flatMap(\.powerUpIndexes)
        let free = stats.powerUpUnlockedArray.indices.filter { stats.powerUpUnlockedArray[$0] }

        XCTAssertEqual(Set(granted).count, granted.count, "A power-up is granted twice")
        XCTAssertTrue(Set(granted).isDisjoint(with: Set(free)),
                      "A power-up is both free and granted")
        XCTAssertEqual(Set(granted).union(free), Set(stats.powerUpUnlockedArray.indices),
                       "Some power-up can never be unlocked")
    }

    func testEveryPackBecomesReachable() {
        // Every pack must be opened by something: unlocked from the start,
        // granted by an earlier pack, or - for City - by the three-pack rule.
        let stats = TotalStats()
        let free = stats.levelPackUnlockedArray.indices.filter { stats.levelPackUnlockedArray[$0] }
        let granted = Progression.packRewards.compactMap(\.nextPackIndex)
        let reachable = Set(free).union(granted).union([Progression.cityPackIndex])

        XCTAssertEqual(Set(granted).count, granted.count, "A pack is granted twice")
        XCTAssertEqual(reachable, Set(stats.levelPackUnlockedArray.indices),
                       "Some pack can never be reached")
    }

    func testEveryAchievementIndexIsDistinctAndInRange() {
        let stats = TotalStats()
        let indices = Progression.packRewards.map(\.achievementIndex)
        XCTAssertEqual(Set(indices).count, indices.count)
        XCTAssertEqual(indices, Array(6...16), "Pack achievements occupy 6...16")
        XCTAssertTrue(indices.allSatisfy { $0 < stats.achievementsUnlockedArray.count })
    }

    func testAchievementIdentifiersAreDistinct() {
        // These are Game Center identifiers; a duplicate reports the wrong
        // achievement and cannot be corrected retrospectively.
        let ids = Progression.packRewards.map(\.achievementIdentifier)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertTrue(ids.allSatisfy { !$0.isEmpty })
    }

    // MARK: - City, which is gated differently

    func testCityNeedsAllThreeStartingPacks() {
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: [0, 0, 0]))
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: [120, 0, 0]))
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: [120, 90, 0]))
        XCTAssertTrue(Progression.unlocksCityPack(packBestTimes: [120, 90, 200]))
    }

    func testCityIgnoresLaterPackTimes() {
        // Only the first three count, in any order of completion.
        var times = [Int](repeating: 0, count: 11)
        times[3] = 500
        times[7] = 500
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: times))
    }

    func testCityRuleToleratesAShortArray() {
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: []))
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: [120, 90]))
    }

    func testNoPackRewardOpensCityDirectly() {
        // The per-pack blocks used to carry their own three-pack check, but each
        // tested its own achievement flag before setting it, so none could fire.
        // City is opened by the best-times rule alone.
        XCTAssertFalse(Progression.packRewards.contains { $0.nextPackIndex == Progression.cityPackIndex })
    }

    // MARK: - Level to level

    func testFinishingALevelOpensTheNext() {
        XCTAssertEqual(Progression.nextLevelIndex(after: 1, endLevelNumber: 10), 2)
        XCTAssertEqual(Progression.nextLevelIndex(after: 9, endLevelNumber: 10), 10)
    }

    func testTheLastLevelOfAPackOpensNothing() {
        XCTAssertNil(Progression.nextLevelIndex(after: 10, endLevelNumber: 10))
        XCTAssertNil(Progression.nextLevelIndex(after: 110, endLevelNumber: 110))
    }

    func testNextLevelStaysInsideTheUnlockArray() {
        // levelUnlockedArray is indexed by global level number, offset by one
        // for endless mode at index 0. Walking every pack must stay in bounds.
        let stats = TotalStats()
        let setup = LevelPackSetup()
        for pack in 2..<setup.startLevelNumber.count {
            let first = setup.startLevelNumber[pack]
            let last = first + setup.numberOfLevels[pack] - 1
            for level in first...last {
                if let next = Progression.nextLevelIndex(after: level, endLevelNumber: last) {
                    XCTAssertLessThan(next, stats.levelUnlockedArray.count,
                                      "Level \(level) would unlock out of bounds")
                }
            }
        }
    }

    // MARK: - Playing the whole game

    func testCompletingEveryPackInOrderUnlocksEverything() {
        // Walks the progression the way a player does and checks the end state:
        // everything open, which is what an existing player already has
        // persisted from the old force-unlock.
        let stats = TotalStats()
        var bestTimes = [Int](repeating: 0, count: 11)

        for (offset, reward) in Progression.packRewards.enumerated() {
            stats.appIconUnlockedArray[reward.appIconIndex] = true
            stats.themeUnlockedArray[reward.themeIndex] = true
            for powerUp in reward.powerUpIndexes {
                stats.powerUpUnlockedArray[powerUp] = true
            }
            stats.achievementsUnlockedArray[reward.achievementIndex] = true
            if let next = reward.nextPackIndex {
                stats.levelPackUnlockedArray[next] = true
            }
            bestTimes[offset] = 100
            if Progression.unlocksCityPack(packBestTimes: bestTimes) {
                stats.levelPackUnlockedArray[Progression.cityPackIndex] = true
            }
        }

        XCTAssertTrue(stats.levelPackUnlockedArray.allSatisfy { $0 }, "A pack stayed locked")
        XCTAssertTrue(stats.themeUnlockedArray.allSatisfy { $0 }, "A theme stayed locked")
        XCTAssertTrue(stats.appIconUnlockedArray.allSatisfy { $0 }, "An icon stayed locked")
        XCTAssertTrue(stats.powerUpUnlockedArray.allSatisfy { $0 }, "A power-up stayed locked")
    }

    func testCityOpensOnTheThirdPackNotTheFourth() {
        // The ordering that matters: packBestTimes is written before the City
        // rule runs, so finishing the third pack opens City in the same pass
        // rather than leaving the player stranded until a fourth completion
        // they could not reach.
        var bestTimes = [Int](repeating: 0, count: 11)
        bestTimes[0] = 100
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: bestTimes))
        bestTimes[1] = 100
        XCTAssertFalse(Progression.unlocksCityPack(packBestTimes: bestTimes))
        bestTimes[2] = 100
        XCTAssertTrue(Progression.unlocksCityPack(packBestTimes: bestTimes),
                      "City must open on the third completion")
    }
}
