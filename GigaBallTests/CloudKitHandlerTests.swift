//
//  CloudKitHandlerTests.swift
//  GigaBallTests
//
//  CloudKitHandler reads and writes NSUbiquitousKeyValueStore and UserDefaults
//  directly, both of which are process-wide singletons. There is no seam to
//  inject a store, so a test that exercised the real save/load paths would
//  scribble over the host app's defaults and leave the simulator in a dirty
//  state - and would still not assert much, because the iCloud side is
//  unavailable in a test run.
//
//  So this file covers what can be tested without that seam: the availability
//  check, which is the one piece of decision logic, and the shape of the data
//  the sync moves. Round-tripping the real save/load paths needs the store
//  behind a protocol first; that is worth doing as part of the save-format
//  work, not before it.
//

import XCTest
@testable import Giga_Ball

final class CloudKitHandlerTests: XCTestCase {

    func testAvailabilityCheckDoesNotThrow() {
        // isiCloudContainerAvailable() reads ubiquityIdentityToken first and
        // treats nil as "unavailable", specifically to avoid touching
        // CKContainer without the entitlement - which raises an uncatchable
        // exception. This test exists to prove that ordering holds: in a test
        // run there is no iCloud account, so the nil path is the one taken.
        let handler = CloudKitHandler()
        handler.isiCloudContainerAvailable()
    }

    func testAvailabilityCheckIsRepeatable() {
        // Called on most screen appearances, so it has to be safe to call over
        // and over with no account present.
        let handler = CloudKitHandler()
        for _ in 0..<5 {
            handler.isiCloudContainerAvailable()
        }
    }

    func testStatsPayloadSurvivesAPropertyListRoundTrip() {
        // The sync mirrors TotalStats key-by-key into the key-value store. Any
        // value it moves has to be a property-list type, or the write silently
        // does nothing. This checks the encoded form contains only such types.
        let stats = TotalStats()
        stats.cumulativeScore = 987
        stats.endlessModeHeight = [1, 2, 3]
        stats.endlessModeHeightDate = [Date(timeIntervalSinceReferenceDate: 0)]

        do {
            let data = try PropertyListEncoder().encode(stats)
            let plist = try PropertyListSerialization.propertyList(
                from: data, options: [], format: nil)
            XCTAssertTrue(PropertyListSerialization.propertyList(
                plist, isValidFor: .binary),
                "TotalStats encodes to something the key-value store cannot carry")
        } catch {
            XCTFail("TotalStats failed to encode: \(error)")
        }
    }

    func testKeyValueStoreQuotaIsNotObviouslyExceeded() {
        // NSUbiquitousKeyValueStore caps a single value at 1 MB and the whole
        // store at 1 MB. Endless mode appends a height and a date per session
        // forever, so the stats blob grows without bound. This does not test
        // the sync, it flags the ceiling: a very long-lived player's stats
        // should still fit.
        let stats = TotalStats()
        for i in 0..<5_000 {
            stats.endlessModeHeight.append(i)
            stats.endlessModeHeightDate.append(Date(timeIntervalSinceReferenceDate: Double(i)))
        }

        do {
            let data = try PropertyListEncoder().encode(stats)
            XCTAssertLessThan(data.count, 1_024 * 1_024,
                              "5,000 endless sessions already exceed the 1 MB iCloud limit")
        } catch {
            XCTFail("TotalStats failed to encode: \(error)")
        }
    }
}
