//
//  StatsSyncTests.swift
//  GigaBallTests
//
//  The reset-propagation rules. These matter because getting them wrong loses
//  a player's lifetime stats across every device at once, and because the
//  failure the generation number fixes was order-dependent - it showed up as
//  "my reset came back" or "my other device got wiped" depending on which
//  device synced first.
//

import XCTest
@testable import Giga_Ball

final class StatsSyncTests: XCTestCase {

    // MARK: - Resolution

    func testEqualGenerationsMerge() {
        XCTAssertEqual(StatsSync.resolve(localGeneration: 0, cloudGeneration: 0), .merge)
        XCTAssertEqual(StatsSync.resolve(localGeneration: 4, cloudGeneration: 4), .merge)
    }

    func testANewerCloudGenerationIsAdopted() {
        XCTAssertEqual(StatsSync.resolve(localGeneration: 0, cloudGeneration: 1), .adoptCloud)
        XCTAssertEqual(StatsSync.resolve(localGeneration: 2, cloudGeneration: 7), .adoptCloud)
    }

    func testANewerLocalGenerationIsPushed() {
        XCTAssertEqual(StatsSync.resolve(localGeneration: 1, cloudGeneration: 0), .pushLocal)
        XCTAssertEqual(StatsSync.resolve(localGeneration: 9, cloudGeneration: 3), .pushLocal)
    }

    func testDevicesThatHaveNeverResetAlwaysMerge() {
        // Nothing changes for anyone until a reset happens, which is what makes
        // this safe to ship to players mid-sync.
        XCTAssertEqual(
            StatsSync.resolve(localGeneration: StatsSync.initialGeneration,
                              cloudGeneration: StatsSync.initialGeneration),
            .merge)
    }

    // MARK: - Resetting

    func testResetSupersedesBothSides() {
        XCTAssertEqual(StatsSync.generationAfterReset(localGeneration: 0, cloudGeneration: 0), 1)
        XCTAssertEqual(StatsSync.generationAfterReset(localGeneration: 3, cloudGeneration: 3), 4)
    }

    func testResetSupersedesAnUnseenCloudGeneration() {
        // Resetting on a device that has not yet pulled another device's reset
        // must still win, or the two collide at the same generation and merge -
        // which resurrects whatever the newer reset cleared.
        XCTAssertEqual(StatsSync.generationAfterReset(localGeneration: 1, cloudGeneration: 5), 6)
    }

    func testResetAlwaysMovesForward() {
        for local in 0...5 {
            for cloud in 0...5 {
                let next = StatsSync.generationAfterReset(localGeneration: local, cloudGeneration: cloud)
                XCTAssertGreaterThan(next, local)
                XCTAssertGreaterThan(next, cloud)
            }
        }
    }

    // MARK: - The scenario that was broken

    func testAResetIsNotUndoneByAnotherDevicePushingStaleStats() {
        // Device A resets: generation 0 -> 1, zeros written to iCloud.
        let cloudGeneration = StatsSync.generationAfterReset(localGeneration: 0, cloudGeneration: 0)

        // Device B still holds the old stats at generation 0. Before, its push
        // merged those larger numbers back into iCloud and undid the reset.
        XCTAssertEqual(StatsSync.resolve(localGeneration: 0, cloudGeneration: cloudGeneration),
                       .adoptCloud,
                       "B must take the reset rather than pushing its stale stats over it")

        // And device A, pulling afterwards, is at the same generation as the
        // cloud, so it merges - with nothing to merge against.
        XCTAssertEqual(StatsSync.resolve(localGeneration: cloudGeneration,
                                         cloudGeneration: cloudGeneration),
                       .merge)
    }

    func testAResetMadeWithSyncingOffStillWinsWhenSyncingIsTurnedOn() {
        // The reset bumps the generation even though nothing is pushed, so when
        // the player enables iCloud later the cleared stats are not merged back
        // down from the copy that is still sitting there at generation zero.
        let local = StatsSync.generationAfterReset(localGeneration: 0, cloudGeneration: 0)
        XCTAssertEqual(StatsSync.resolve(localGeneration: local, cloudGeneration: 0), .pushLocal)
    }

    func testTwoDevicesResettingIndependentlyConverge() {
        // Both reset without seeing each other. A goes to 1 and pushes.
        let a = StatsSync.generationAfterReset(localGeneration: 0, cloudGeneration: 0)
        // B resets after pulling A's generation, so it goes to 2 and wins.
        let b = StatsSync.generationAfterReset(localGeneration: 0, cloudGeneration: a)

        XCTAssertGreaterThan(b, a)
        XCTAssertEqual(StatsSync.resolve(localGeneration: a, cloudGeneration: b), .adoptCloud)
    }

    // MARK: - The handler

    /// The rules above are only worth anything if saveDataReset actually
    /// applies them, and the easy mistake is to put the bump behind the
    /// iCloudSetting guard that everything else in that function sits behind.
    func testResettingBumpsTheStoredGenerationEvenWithSyncingOff() {
        let defaults = UserDefaults.standard
        let key = StatsSync.generationKey
        let original = defaults.object(forKey: key)
        defer {
            if let original { defaults.set(original, forKey: key) }
            else { defaults.removeObject(forKey: key) }
        }

        defaults.set(false, forKey: "iCloudSetting")
        defaults.set(7, forKey: key)

        CloudKitHandler().saveDataReset()

        XCTAssertGreaterThan(defaults.integer(forKey: key), 7,
                             "the reset has to be recorded whether or not it can be pushed")
    }
}
