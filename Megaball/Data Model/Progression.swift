//
//  Progression.swift
//  Megaball
//
//  What completing a pack unlocks, lifted out of InbewteenLevels so it can be
//  tested. Pure data and arithmetic: no scene, no Game Center, no persistence.
//
//  This was eleven near-identical blocks differing only in their indices, which
//  is exactly the shape that hides an off-by-one. The indices matter: they are
//  written into TotalStats and synced to iCloud, and getting one wrong hands a
//  player the wrong theme or silently strands a pack out of reach. Between the
//  table below and the defaults in TotalStats, every entry of all four unlock
//  arrays is accounted for exactly once - which is what the tests assert.
//

import Foundation

enum Progression {

    /// What finishing a pack awards.
    struct PackReward {
        /// The final level of the pack, as a global level number.
        let finalLevel: Int
        /// Index into TotalStats.achievementsUnlockedArray, and its Game Center id.
        let achievementIndex: Int
        let achievementIdentifier: String
        /// Index into TotalStats.appIconUnlockedArray.
        let appIconIndex: Int
        /// Index into TotalStats.themeUnlockedArray.
        let themeIndex: Int
        /// Indices into TotalStats.powerUpUnlockedArray. Empty for the last four
        /// packs, by which point every power-up has been handed out.
        let powerUpIndexes: [Int]
        /// Index into TotalStats.levelPackUnlockedArray for the pack this one
        /// opens. Nil for the first three packs, whose successor is gated on all
        /// three being finished rather than on any one of them, and for the last
        /// pack, which opens nothing.
        let nextPackIndex: Int?
    }

    /// The eleven content packs, in play order.
    static let packRewards: [PackReward] = [
        PackReward(finalLevel: 10,  achievementIndex: 6,  achievementIdentifier: "classicPackComplete",
                   appIconIndex: 1,  themeIndex: 1,  powerUpIndexes: [6, 7],   nextPackIndex: nil),
        PackReward(finalLevel: 20,  achievementIndex: 7,  achievementIdentifier: "spacePackComplete",
                   appIconIndex: 2,  themeIndex: 2,  powerUpIndexes: [10, 11], nextPackIndex: nil),
        PackReward(finalLevel: 30,  achievementIndex: 8,  achievementIdentifier: "naturePackComplete",
                   appIconIndex: 3,  themeIndex: 3,  powerUpIndexes: [12, 13], nextPackIndex: nil),
        PackReward(finalLevel: 40,  achievementIndex: 9,  achievementIdentifier: "urbanPackComplete",
                   appIconIndex: 4,  themeIndex: 4,  powerUpIndexes: [20, 21], nextPackIndex: 6),
        PackReward(finalLevel: 50,  achievementIndex: 10, achievementIdentifier: "foodPackComplete",
                   appIconIndex: 5,  themeIndex: 5,  powerUpIndexes: [22, 23], nextPackIndex: 7),
        PackReward(finalLevel: 60,  achievementIndex: 11, achievementIdentifier: "computerPackComplete",
                   appIconIndex: 6,  themeIndex: 6,  powerUpIndexes: [24, 25], nextPackIndex: 8),
        PackReward(finalLevel: 70,  achievementIndex: 12, achievementIdentifier: "bodyPackComplete",
                   appIconIndex: 7,  themeIndex: 7,  powerUpIndexes: [26, 27], nextPackIndex: 9),
        PackReward(finalLevel: 80,  achievementIndex: 13, achievementIdentifier: "worldPackComplete",
                   appIconIndex: 8,  themeIndex: 8,  powerUpIndexes: [],       nextPackIndex: 10),
        PackReward(finalLevel: 90,  achievementIndex: 14, achievementIdentifier: "emojiPackComplete",
                   appIconIndex: 9,  themeIndex: 9,  powerUpIndexes: [],       nextPackIndex: 11),
        PackReward(finalLevel: 100, achievementIndex: 15, achievementIdentifier: "numbersPackComplete",
                   appIconIndex: 10, themeIndex: 10, powerUpIndexes: [],       nextPackIndex: 12),
        PackReward(finalLevel: 110, achievementIndex: 16, achievementIdentifier: "challengePackComplete",
                   appIconIndex: 11, themeIndex: 11, powerUpIndexes: [],       nextPackIndex: nil)
    ]

    /// Index into levelPackUnlockedArray for City, the first earned pack.
    static let cityPackIndex = 5

    /// The reward for finishing the pack that ends at `levelNumber`, if that
    /// level ends a pack.
    static func reward(forLevel levelNumber: Int) -> PackReward? {
        packRewards.first { $0.finalLevel == levelNumber }
    }

    /// City opens once the first three packs have all been finished, which is
    /// recorded as a best time rather than an achievement flag.
    ///
    /// It has to be a separate rule because the first three packs can be played
    /// in any order - all three start unlocked - so no single completion can
    /// know it was the last one. The per-pack blocks used to carry a check for
    /// this as well, but each tested its own achievement flag before setting it,
    /// so none of them could ever fire.
    static func unlocksCityPack(packBestTimes: [Int]) -> Bool {
        guard packBestTimes.count >= 3 else { return false }
        return packBestTimes[0] > 0 && packBestTimes[1] > 0 && packBestTimes[2] > 0
    }

    /// The level that finishing `levelNumber` opens, if it is not the last of
    /// its pack. Levels are globally numbered and levelUnlockedArray is indexed
    /// by that same number, offset by one for endless mode at index 0.
    static func nextLevelIndex(after levelNumber: Int, endLevelNumber: Int) -> Int? {
        levelNumber == endLevelNumber ? nil : levelNumber + 1
    }
}
