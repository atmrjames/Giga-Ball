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
    // MARK: - Every array is read back from its own key

    /// **A key that names the wrong array is invisible until a player loses data** (round 302).
    ///
    /// `saveToiCloud` read the achievement *percentages* out of the key holding the
    /// *unlocked flags* and cast the result to `[String]`. That key holds `[Bool]`, so the cast
    /// could never succeed, the merge branch had never once run, and every sync fell through to
    /// the else that pushes this device's arrays over the cloud's wholesale - which is how a
    /// second device could overwrite years of achievement dates with its own empties.
    ///
    /// Nothing crashed, nothing warned, and no test failed, because the code *reads* fine: the
    /// variable is named after the array it wants and only the string literal disagrees.
    ///
    /// So the check is mechanical rather than clever: for every place the handler reads an
    /// array out of the key-value store into a variable, the key has to be the variable's own
    /// name. That is the convention the file already follows everywhere else, and this asserts
    /// it rather than trusting it.
    func testEveryICloudArrayIsReadFromTheKeyNamedAfterIt() throws {
        let source = try String(contentsOf: URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Megaball/CloudKitHandler.swift"), encoding: .utf8)

        // Both forms, because they fail the same way and only one of them was ever checked:
        //   `let somethingArrayCloudCheck = iCloudStore.array(forKey: "somethingArray")`  - save
        //   `somethingArray = iCloudStore.array(forKey: "somethingArray")`                - load
        //
        // The load path is the one with more at stake, since a wrong key there reads another
        // array's contents straight into a player's stats. It was clean when this was written;
        // it was also unguarded, which is the same position the save path was in.
        let pattern = #"(?:(?:let|var)\s+|\b)([A-Za-z]+?)(?:Cloud|CloudCheck)?\s*=\s*iCloudStore\.array\(forKey:\s*"([A-Za-z]+)"\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let range = NSRange(source.startIndex..., in: source)
        let matches = regex.matches(in: source, range: range)

        XCTAssertGreaterThan(matches.count, 20,
                             "the pattern stopped matching the file, so this test is asleep - "
                             + "it should be seeing both the save path's reads and the load "
                             + "path's assignments, and there are around thirty of those alone")

        var wrong: [String] = []
        for match in matches {
            guard let v = Range(match.range(at: 1), in: source),
                  let k = Range(match.range(at: 2), in: source) else { continue }
            let variable = String(source[v]), key = String(source[k])
            if variable.hasPrefix(key) == false { wrong.append("\(variable) reads \(key)") }
        }

        XCTAssertEqual(wrong, [],
                       "an array is being read out of another array's iCloud key, which is "
                       + "silent until two devices disagree: \(wrong.joined(separator: "; "))")
    }

}
