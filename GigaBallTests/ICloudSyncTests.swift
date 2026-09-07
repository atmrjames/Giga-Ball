//
//  ICloudSyncTests.swift
//  GigaBallTests
//
//  James, round 313: "I think the Endless Mode and Endless Mayhem scores should be synced
//  between devices on the same iCloud account. On my iPad, there were no scores on the Endless
//  Mayhem mode as I'd only played it on my phone."
//
//  He was right, and the reason is worth writing down: of the fifty-four fields in the stats
//  file, fifty-three reached the key-value store. The one that did not was Endless Mayhem's
//  own list of runs - so from the inside nothing looked broken, and from the iPad the mode
//  looked unplayed.
//
//  These are the first tests the sync has ever had. The CRAP pass in round 313 put
//  `updateToiCloud` and `updateFromiCloud` fourth and fifth in the whole app - around a
//  hundred branches apiece, at zero coverage - which is a bad place for the code that decides
//  which of a player's two devices keeps its years of scores.
//

import XCTest
@testable import Giga_Ball

/// An iCloud key-value store that never leaves the process.
///
/// Named apart from `InMemoryKeyValueStore`, which the app already has: that one stands in for
/// `UserDefaults` behind the `KeyValueStore` protocol, and this file's store answers questions
/// that protocol does not ask - `array(forKey:)`, `longLong(forKey:)`, `bool(forKey:)`.
///
/// `CloudKitHandler` reads and writes `NSUbiquitousKeyValueStore` through one property now, so
/// a test can hand it this instead of the account-backed one - which on a simulator has no
/// account at all and answers every read with nothing.
final class InMemoryCloudStore: NSUbiquitousKeyValueStore {

    var contents: [String: Any] = [:]

    override func object(forKey aKey: String) -> Any? { contents[aKey] }
    override func array(forKey aKey: String) -> [Any]? { contents[aKey] as? [Any] }
    override func data(forKey aKey: String) -> Data? { contents[aKey] as? Data }
    override func string(forKey aKey: String) -> String? { contents[aKey] as? String }
    override func bool(forKey aKey: String) -> Bool { contents[aKey] as? Bool ?? false }
    override func double(forKey aKey: String) -> Double { contents[aKey] as? Double ?? 0 }

    override func longLong(forKey aKey: String) -> Int64 {
        if let value = contents[aKey] as? Int64 { return value }
        if let value = contents[aKey] as? Int { return Int64(value) }
        return 0
    }

    override func set(_ anObject: Any?, forKey aKey: String) { contents[aKey] = anObject }
    override func set(_ aString: String?, forKey aKey: String) { contents[aKey] = aString }
    override func set(_ aData: Data?, forKey aKey: String) { contents[aKey] = aData }
    override func set(_ anArray: [Any]?, forKey aKey: String) { contents[aKey] = anArray }
    override func set(_ value: Int64, forKey aKey: String) { contents[aKey] = value }
    override func set(_ value: Double, forKey aKey: String) { contents[aKey] = value }
    override func set(_ value: Bool, forKey aKey: String) { contents[aKey] = value }
    override func set(_ aDictionary: [String: Any]?, forKey aKey: String) {
        contents[aKey] = aDictionary
    }

    override func removeObject(forKey aKey: String) { contents.removeValue(forKey: aKey) }
    override func synchronize() -> Bool { true }
}

final class ICloudSyncTests: XCTestCase {

    private func handler(store: InMemoryCloudStore,
                         stats: TotalStats) -> CloudKitHandler {
        let handler = CloudKitHandler()
        handler.iCloudStore = store
        handler.totalStatsArray = [stats]
        // The two sides of a sync both defer to a reset on the other device, and a test that
        // did not match the generations would only ever exercise that path
        store.contents[StatsSync.generationKey] =
            UserDefaults.standard.integer(forKey: StatsSync.generationKey)
        return handler
    }

    // MARK: - The phone, which has played Mayhem

    func testAPhonesMayhemRunsReachTheCloud() {
        let store = InMemoryCloudStore()
        var stats = TotalStats()
        stats.endlessIIModeHeight = [120, 340, 260]
        stats.endlessIIModeHeightDate = [Date(), Date(), Date()]

        handler(store: store, stats: stats).updateToiCloud()

        XCTAssertEqual(store.array(forKey: "endlessIIModeHeight") as? [Int], [120, 340, 260],
                       "the mode's runs were the one field that never left the device")
        XCTAssertEqual((store.array(forKey: "endlessIIModeHeightDate") as? [Date])?.count, 3,
                       "and their dates travel with them, or the run list reads out of step")
    }

    func testTheOriginalEndlessStillReachesTheCloudToo() {
        let store = InMemoryCloudStore()
        var stats = TotalStats()
        stats.endlessModeHeight = [80, 95]
        stats.endlessModeHeightDate = [Date(), Date()]

        handler(store: store, stats: stats).updateToiCloud()

        XCTAssertEqual(store.array(forKey: "endlessModeHeight") as? [Int], [80, 95])
        XCTAssertEqual((store.array(forKey: "endlessModeHeightDate") as? [Date])?.count, 2)
    }

    // MARK: - The iPad, which has not

    func testAnIPadWithNoMayhemRunsTakesThePhones() {
        let store = InMemoryCloudStore()
        store.contents["endlessIIModeHeight"] = [120, 340, 260]
        store.contents["endlessIIModeHeightDate"] = [Date(), Date(), Date()]

        let stats = TotalStats()
        XCTAssertTrue(stats.endlessIIHeights.isEmpty, "this is James's iPad")

        let handler = self.handler(store: store, stats: stats)
        handler.updateFromiCloud()

        XCTAssertEqual(handler.totalStatsArray[0].endlessIIHeights, [120, 340, 260])
        XCTAssertEqual(handler.totalStatsArray[0].endlessIIModeHeightDate?.count, 3)
    }

    /// The rule is the original mode's: the larger total wins and replaces. A device that has
    /// played more keeps what it has rather than having a shorter list pushed onto it.
    func testTheDeviceThatHasPlayedMoreKeepsItsRuns() {
        let store = InMemoryCloudStore()
        store.contents["endlessIIModeHeight"] = [50]

        var stats = TotalStats()
        stats.endlessIIModeHeight = [120, 340, 260]

        let handler = self.handler(store: store, stats: stats)
        handler.updateFromiCloud()

        XCTAssertEqual(handler.totalStatsArray[0].endlessIIHeights, [120, 340, 260])
    }

    /// The audit that found it, kept so the next field added to the stats file is asked the
    /// same question. Reading the source is the only way to ask it: the sync is a hundred
    /// hand-written pairs of lines, and a field is missing by being absent.
    func testEveryStatsFieldIsMentionedByTheSync() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
        let stats = try String(contentsOf: root.appendingPathComponent(
            "Megaball/Data Model/TotalStats.swift"), encoding: .utf8)
        let sync = try String(contentsOf: root.appendingPathComponent(
            "Megaball/CloudKitHandler.swift"), encoding: .utf8)

        var missing: [String] = []
        for line in stats.split(separator: "\n") {
            let text = String(line)
            guard text.hasPrefix("    var ") else { continue }
            guard text.contains("{") == false else { continue }
            // A computed property is derived from the stored ones, so it has nothing to sync
            let name = text.dropFirst("    var ".count).prefix { $0.isLetter || $0.isNumber }
            guard name.isEmpty == false else { continue }
            if sync.contains(String(name)) == false { missing.append(String(name)) }
        }

        XCTAssertEqual(missing, [],
                       "these are in the stats file and never reach iCloud, which is how "
                       + "Endless Mayhem's heights went missing on James's iPad")
    }
}
