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
}
