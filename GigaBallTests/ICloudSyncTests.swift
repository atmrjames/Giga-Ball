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
        let stats = TotalStats()
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
        let stats = TotalStats()
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

        let stats = TotalStats()
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

    // MARK: - Merging rather than replacing (round 314)

    /// Three runs played on two devices, at three known times.
    private func moment(_ minutes: Int) -> Date {
        Date(timeIntervalSince1970: 1_700_000_000 + Double(minutes)*60)
    }

    private func run(_ height: Int, _ minutes: Int,
                     _ duration: Int? = nil) -> CloudKitHandler.Run {
        CloudKitHandler.Run(height: height, date: moment(minutes), duration: duration)
    }

    /// **The report this closes.** James, round 314: "yes, merge the lists".
    ///
    /// Until now a sync compared the two lists by total metres and the larger won outright,
    /// so a device that had played less lost every run it held. Both devices keep everything
    /// now, and neither ordering of the sync changes the answer.
    func testTwoDevicesRunsAreBothKept() {
        let mine = [run(80, 0), run(120, 10)]
        let theirs = [run(45, 5), run(300, 20)]

        let merged = CloudKitHandler.mergedRuns(mine, theirs)

        XCTAssertEqual(merged.map(\.height), [80, 45, 120, 300],
                       "every run either device played, oldest first")
        XCTAssertEqual(CloudKitHandler.mergedRuns(theirs, mine), merged,
                       "and the answer cannot depend on which device syncs first")
    }

    /// The device that had played less used to lose everything, which is the fault itself.
    func testTheSmallerListIsNoLongerThrownAway() {
        let busy = (0..<10).map { run(500, $0*10) }
        let quiet = [run(3, 5)]

        XCTAssertEqual(CloudKitHandler.mergedRuns(quiet, busy).count, 11,
                       "the quiet device's single run survives meeting a much larger list")
        XCTAssertTrue(CloudKitHandler.mergedRuns(busy, quiet).contains(quiet[0]))
    }

    /// The same run seen twice is one run, because a run's identity is when it was played.
    func testARunSyncedBackIsNotCountedTwice() {
        let shared = run(150, 30)
        let merged = CloudKitHandler.mergedRuns([shared, run(20, 0)], [shared])

        XCTAssertEqual(merged.count, 2, "the shared run is the same run, not two")
    }

    /// **A run is never separated from its own clock.**
    ///
    /// The durations used to travel as a whole array under their own "biggest total wins",
    /// matching how the heights moved - and `pushModeTimes` said in as many words that the
    /// two had to move under the same rule, or a device could end up with one device's
    /// heights and another's durations. Merged as a triple that cannot happen, and a run that
    /// predates round 111 keeps its nil rather than being handed a stranger's seconds.
    func testADurationTravelsWithItsOwnRun() {
        let merged = CloudKitHandler.mergedRuns([run(80, 0, 45)], [run(300, 10, 600)])

        XCTAssertEqual(merged.map(\.duration), [45, 600])
    }

    func testARunWithNoDurationTakesOneFromTheOtherCopy() {
        let merged = CloudKitHandler.mergedRuns([run(80, 0)], [run(80, 0, 45)])

        XCTAssertEqual(merged.map(\.duration), [45],
                       "one side predates round 111 and the other does not")
    }

    /// The arrays are read as far as they agree, and no further.
    ///
    /// A device with years of history has heights from 2020, dates added later and durations
    /// added in round 111, so the three are honestly different lengths. Reading past the
    /// shortest is the crash `padded` exists to stop, one field along.
    func testShorterArraysAreReadAsFarAsTheyGo() {
        XCTAssertNil(CloudKitHandler.runs(heights: [10, 20, 30],
                                          dates: [moment(0), moment(1)],
                                          durations: [99]),
                     "a run with no date cannot be identified, so this list says so rather "
                     + "than quietly dropping the third run")

        let dated = CloudKitHandler.runs(heights: [10, 20],
                                         dates: [moment(0), moment(1)],
                                         durations: [99])
        XCTAssertEqual(dated?.map(\.height), [10, 20])
        XCTAssertEqual(dated?.map(\.duration), [99, nil],
                       "the durations arrived in round 111 and may be shorter, which is "
                       + "honest rather than broken")
    }

    /// And an undateable list keeps the old rule rather than losing the runs.
    ///
    /// The worst thing this file could do is lose somebody's history to a sync, so a list
    /// that cannot be merged falls back to longer-list-wins, which is what it did before.
    func testAListWithNoDatesFallsBackRatherThanEmptying() {
        let store = InMemoryCloudStore()
        store.contents["endlessIIModeHeight"] = [50]

        let stats = TotalStats()
        stats.endlessIIModeHeight = [120, 340, 260]
        // No dates at all, which is what a device from before they existed carries

        let handler = self.handler(store: store, stats: stats)
        handler.updateToiCloud()

        XCTAssertEqual(store.array(forKey: "endlessIIModeHeight") as? [Int], [120, 340, 260],
                       "the longer list still wins when neither can be merged")
    }

    /// End to end, through the store: two devices, one account.
    func testAPhoneAndAnIPadEndUpWithTheSameRuns() {
        let store = InMemoryCloudStore()

        let phone = TotalStats()
        phone.endlessIIModeHeight = [120, 340]
        phone.endlessIIModeHeightDate = [moment(0), moment(10)]
        handler(store: store, stats: phone).updateToiCloud()

        let pad = TotalStats()
        pad.endlessIIModeHeight = [55]
        pad.endlessIIModeHeightDate = [moment(5)]
        let padHandler = handler(store: store, stats: pad)
        padHandler.updateToiCloud()
        padHandler.updateFromiCloud()

        XCTAssertEqual(padHandler.totalStatsArray[0].endlessIIModeHeight, [120, 55, 340],
                       "the iPad ends up with its own run and both of the phone's")
        XCTAssertEqual(store.array(forKey: "endlessIIModeHeight") as? [Int], [120, 55, 340],
                       "and the cloud holds the union rather than whichever synced last")
    }
}

/// Another device's reset, adopted (round 323). `loadDataReset` was the riskiest untested function
/// in the app; its adoption is `adoptCloudStatsAfterReset` now, so a test can reach it.
final class ICloudResetAdoptionTests: XCTestCase {

    private let suite = "GigaBallTests.ICloudReset"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func handler(store: InMemoryCloudStore, stats: TotalStats) throws -> CloudKitHandler {
        let handler = CloudKitHandler()
        handler.iCloudStore = store
        handler.totalStatsArray = [stats]
        handler.defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        // Its own suite: adopting a reset writes the generation and two settings
        return handler
    }

    /// **A reset made on an older build does not shorten a newer device's arrays.** An older
    /// build has fewer power-ups, levels and achievements, so its arrays are shorter - and a
    /// shorter array read past its end is the crash `CloudKitHandler.padded` was written for.
    func testAResetFromAnOlderBuildKeepsEveryArrayItsFullLength() throws {
        let local = TotalStats()
        let store = InMemoryCloudStore()
        store.contents["powerupsCollected"] = Array(repeating: 0, count: local.powerupsCollected.count - 5)
        store.contents["powerUpUnlockedArray"] = Array(repeating: true, count: local.powerUpUnlockedArray.count - 5)
        store.contents["achievementsUnlockedArray"] = Array(repeating: false, count: local.achievementsUnlockedArray.count - 10)
        store.contents["levelUnlockedArray"] = Array(repeating: true, count: local.levelUnlockedArray.count - 10)
        // A phone a few rounds behind: five fewer power-ups, ten fewer achievements and levels

        let handler = try self.handler(store: store, stats: local)
        handler.adoptCloudStatsAfterReset()
        let adopted = handler.totalStatsArray[0]

        XCTAssertEqual(adopted.powerupsCollected.count, local.powerupsCollected.count,
                       "a power-up the older phone has never heard of still has a tally")
        XCTAssertEqual(adopted.powerUpUnlockedArray.count, local.powerUpUnlockedArray.count)
        XCTAssertEqual(adopted.achievementsUnlockedArray.count, local.achievementsUnlockedArray.count)
        XCTAssertEqual(adopted.levelUnlockedArray.count, local.levelUnlockedArray.count)
        XCTAssertTrue(adopted.powerUpUnlockedArray.prefix(local.powerUpUnlockedArray.count - 5)
                        .allSatisfy { $0 }, "and the entries the phone did send are the phone's")
    }

    /// And otherwise the reset is taken whole: counts, runs and the generation that says this
    /// device has caught up.
    func testAResetIsTakenWhole() throws {
        let local = TotalStats()
        local.levelsPlayed = 50
        local.cumulativeScore = 123_456
        local.endlessModeHeight = [80, 95]
        local.endlessModeHeightDate = [Date(), Date()]

        let store = InMemoryCloudStore()
        store.contents["levelsPlayed"] = Int64(0)
        store.contents["cumulativeScore"] = Int64(0)
        store.contents["endlessModeHeight"] = [Int]()
        store.contents["endlessModeHeightDate"] = [Date]()
        store.contents[StatsSync.generationKey] = Int64(4)

        let handler = try self.handler(store: store, stats: local)
        handler.adoptCloudStatsAfterReset()
        let adopted = handler.totalStatsArray[0]

        XCTAssertEqual(adopted.levelsPlayed, 0, "the other device reset, so this one does too")
        XCTAssertEqual(adopted.cumulativeScore, 0)
        XCTAssertEqual(adopted.endlessModeHeight, [], "and its runs are cleared, not padded back in")
        XCTAssertEqual(handler.defaults.integer(forKey: StatsSync.generationKey), 4,
                       "and it records the reset it has caught up with, or it adopts it again")
    }
}
