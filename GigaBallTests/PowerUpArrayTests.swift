//
//  PowerUpArrayTests.swift
//  GigaBallTests
//
//  Everything about a power-up is stored in a different array, indexed by the same number: its
//  name in one, its icon in another, its description, its multiplier, its timer, the pack that
//  unlocks it, two descriptions of how to unlock it, the order the list shows them in, and the
//  weight it drops at. Eleven arrays, one index.
//
//  Adding the twenty-ninth means adding an entry to every one of them, and the failure mode if
//  a single one is missed is not a crash - it is every power-up after that point quietly
//  wearing the next one's name, or the wrong description, or somebody else's collection count.
//  On a screen nobody looks at twice.
//
//  So this is the guard rail that goes in before the entry does.
//
//  One array is deliberately **not** guarded here: `powerUpTextureArray`. It is filled in
//  `didMove(to:)`, which needs a presented `SKView`, so a bare scene has none of it and any
//  assertion about its length would either fail for the wrong reason or be skipped and pass
//  for the wrong reason. A test that silently returns is worse than no test - it is the
//  "very rare or never offered" problem in test form. Checking it needs a scene actually on
//  screen, which is a play-test job: a new power-up that falls wearing nothing is visible
//  the first time it drops.
//

import XCTest
@testable import Giga_Ball

final class PowerUpArrayTests: XCTestCase {

    private let setup = LevelPackSetup()

    /// How many power-ups the game has, taken from the list of names.
    private var count: Int { setup.powerUpNameArray.count }

    func testEveryPowerUpArrayIsTheSameLength() {
        XCTAssertEqual(setup.powerUpImageArray.count, count, "images")
        XCTAssertEqual(setup.powerUpDescriptionArray.count, count, "descriptions")
        XCTAssertEqual(setup.powerUpMultiplierArray.count, count, "multipliers")
        XCTAssertEqual(setup.powerUpTimerArray.count, count, "timers")
        XCTAssertEqual(setup.powerUpUnlockedDescriptionArray.count, count, "unlock text")
        XCTAssertEqual(setup.powerUpHiddenUnlockedDescriptionArray.count, count, "hidden text")
        XCTAssertEqual(setup.powerUpPackOrderArray.count, count, "pack order")
        XCTAssertEqual(setup.powerUpCorrectOrderArray.count, count, "display order")
    }

    func testTheStoredArraysCoverEveryPowerUp() {
        // These are the ones decoded from a player's file, and the ones that would be read
        // past the end of if a power-up were added without them growing
        let stats = TotalStats()
        XCTAssertEqual(stats.powerupsCollected.count, count, "collected")
        XCTAssertEqual(stats.powerupsGenerated.count, count, "generated")
        XCTAssertEqual(stats.powerUpUnlockedArray.count, count, "unlocked")
    }

    func testTheDropWeightsCoverEveryPowerUp() {
        // `powerUpProbArray` is indexed the same way, and a power-up past the end of it can
        // never be drawn - which looks exactly like one that is simply very rare
        let scene = GameScene()
        XCTAssertEqual(scene.powerUpProbArray.count, count, "weights")
    }

    func testTheDisplayOrderIsAPermutationOfEveryPowerUp() {
        // It maps a row in the list to a power-up. A repeat shows one twice and hides another
        // entirely, and the page looks plausible either way
        XCTAssertEqual(Set(setup.powerUpCorrectOrderArray).count, count,
                       "the display order repeats or skips an index")
        XCTAssertEqual(setup.powerUpCorrectOrderArray.sorted(), Array(0..<count))
    }

    func testEveryPowerUpIsNamedAndDescribed() {
        for index in 0..<count {
            XCTAssertFalse(setup.powerUpNameArray[index].isEmpty, "name \(index)")
            XCTAssertFalse(setup.powerUpDescriptionArray[index].isEmpty, "description \(index)")
        }
    }

    func testEveryPowerUpBelongsToAPack() {
        for (index, pack) in setup.powerUpPackOrderArray.enumerated() {
            XCTAssertGreaterThanOrEqual(pack, 0, "power-up \(index)")
            XCTAssertLessThan(pack, setup.levelPackNameArray.count, "power-up \(index)")
        }
    }

    // MARK: - The two places a new power-up has to reach
    //
    // CLAUDE.md records this as a trap the project has already fallen into: "Adding a
    // power-up lengthens arrays in two places. The stats file *and*
    // `NSUbiquitousKeyValueStore`. Missing the second crashed the app on launch for a player
    // with years of synced data."
    //
    // Both sides now pad a short array from a longer template rather than trusting the two
    // to match, so the length is no longer the thing that has to be got right by hand. These
    // pin that, because the padding is the whole defence and it is four lines that look
    // deletable.

    func testAShortStatsFileIsPaddedRatherThanTrusted() {
        // A file written before a power-up existed, opened by the build that added it
        let fresh = TotalStats()
        let older = Array(fresh.powerupsCollected.dropLast(2))

        let padded = TotalStats.padded(older, like: fresh.powerupsCollected)
        XCTAssertEqual(padded.count, fresh.powerupsCollected.count)
    }

    func testAStatsFileFromANewerBuildKeepsItsExtras() {
        // Only ever lengthens: throwing the extras away would lose that player's progress
        // the moment they opened an older build
        let fresh = TotalStats()
        let newer = fresh.powerupsCollected + [7, 7, 7]

        XCTAssertEqual(TotalStats.padded(newer, like: fresh.powerupsCollected), newer)
    }

    func testTheStatsFileIsMadeConsistentOnLoad() {
        // The padding is applied where a decoded file arrives, not only where it is declared
        var older = TotalStats()
        older.powerupsCollected = Array(older.powerupsCollected.dropLast(3))
        older.powerupsGenerated = Array(older.powerupsGenerated.dropLast(3))
        older.powerUpUnlockedArray = Array(older.powerUpUnlockedArray.dropLast(3))

        older.makeStoredArraysConsistent()

        XCTAssertEqual(older.powerupsCollected.count, count)
        XCTAssertEqual(older.powerupsGenerated.count, count)
        XCTAssertEqual(older.powerUpUnlockedArray.count, count)
    }

    func testAShortCloudArrayIsPaddedFromTheLocalOne() {
        // The half that crashed. A device that has not updated yet writes the shorter array,
        // and the updated device reads it back and indexes past the end
        let local = Array(repeating: 3, count: count)
        let cloud = Array(repeating: 1, count: count - 2)

        let padded = CloudKitHandler.padded(cloud, toMatch: local)
        XCTAssertEqual(padded.count, count)
        XCTAssertEqual(Array(padded.prefix(count - 2)), cloud, "what was there is kept")
    }

    func testALongerCloudArrayIsLeftAlone() {
        // Written by a newer build than this one, and none of it is ours to discard
        let local = Array(repeating: 3, count: count)
        let cloud = Array(repeating: 1, count: count + 4)
        XCTAssertEqual(CloudKitHandler.padded(cloud, toMatch: local).count, count + 4)
    }

    // MARK: - The falling halo

    func testAHarmfulPowerUpGlowsInTheHarmfulColour() {
        // Derived from the multiplier column rather than a second list of which drops are
        // good: a list would be wrong the first time that judgement changed
        let setup = LevelPackSetup()
        guard let bad = setup.powerUpMultiplierArray.firstIndex(where: { $0.hasPrefix("-") })
        else { return XCTFail("no harmful power-up to check") }

        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: bad), PowerUpIcon.harmful)
    }

    func testAGoodPowerUpGlowsInTheBeneficialColour() {
        let setup = LevelPackSetup()
        guard let good = setup.powerUpMultiplierArray.firstIndex(where: { $0.hasPrefix("+") })
        else { return XCTFail("no beneficial power-up to check") }

        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: good), PowerUpIcon.beneficial)
    }

    func testAnIndexOffTheEndStillGetsAColour() {
        // Asked at the moment a drop is built, and a crash there is worse than a green halo
        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: count + 5),
                       PowerUpIcon.beneficial)
    }

    func testEveryPowerUpHasAHalo() {
        for index in 0..<count {
            let colour = GameScene.powerUpGlowColour(forIndex: index)
            XCTAssertTrue(colour == PowerUpIcon.harmful || colour == PowerUpIcon.beneficial,
                          "power-up \(index) glows in neither colour")
        }
    }
}
