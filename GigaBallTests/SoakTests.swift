//
//  SoakTests.swift
//  GigaBallTests
//
//  The overnight soak: the whole-game checks, asked of hundreds of seeds.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

/// The checks that find what a play test finds, run for hours rather than minutes.
///
/// James, round 398b, leaving for a day at work: "the suite has >8 hours to run, so make it as
/// robust and thorough as possible." `ResumeIsTheSameGameTests`, `LongPlaySessionTests` and
/// `EveryDailyTwistPlaysTests` each ask their question of a handful of seeds so that a full run
/// stays under an hour; a fault that lives in one game in two hundred passes them by. These ask
/// the same questions of a range of seeds the driver chooses (`tools/soak.sh`), and every failure
/// names its seed, theme, mode and day so it can be replayed exactly.
///
/// Skipped unless `SOAK_FROM` and `SOAK_COUNT` are set (as `TEST_RUNNER_SOAK_FROM` and
/// `TEST_RUNNER_SOAK_COUNT` on the `xcodebuild` line), so the ordinary tiers never run them.
final class SoakTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        DailyChallengeSession.shared.active = nil
        window = nil
        resumedWindow = nil
        super.tearDown()
    }

    private func seeds() throws -> Range<UInt64> {
        let environment = ProcessInfo.processInfo.environment
        guard let from = environment["SOAK_FROM"].flatMap(UInt64.init),
              let count = environment["SOAK_COUNT"].flatMap(UInt64.init) else {
            throw XCTSkip("the soak runs only from tools/soak.sh")
        }
        return from..<(from + count)
    }

    private func day(_ offset: UInt64) -> DailyChallenge {
        let calendar = DailyDay.utcCalendar
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: Int(offset), to: today) ?? today
        return DailyChallengeGenerator.challenge(forKey: DailyDay.key(for: date))
    }

    private var themes: Int { LevelPackSetup.shared.themeNameArray.count }

    /// Played, saved at a seeded moment, resumed, compared - in every mode, theme and depth, and
    /// in dailies drawn from the next year and a bit.
    func testResumeSoak() throws {
        let range = try seeds()
        let themeCount = max(1, themes)
        var failures: [String] = []
        for seed in range {
            var random = PlayWatch.Seeded(state: seed &* 104729)
            let theme = Int(seed % UInt64(themeCount))
            let playFor = Double.random(in: 1.5...20, using: &random)
            let found: [String]
            switch seed % 10 {
            case 0...4:
                found = try ResumeCheck.run(mode: .endlessII, seed: seed, theme: theme,
                                            startHeight: Int.random(in: 0...900, using: &random),
                                            playFor: playFor, window: &window,
                                            resumedWindow: &resumedWindow)
            case 5, 6:
                found = try ResumeCheck.run(mode: .classic, seed: seed, theme: theme,
                                            playFor: playFor, window: &window,
                                            resumedWindow: &resumedWindow)
            case 7:
                found = try ResumeCheck.run(mode: .endless, seed: seed, theme: theme,
                                            playFor: playFor, window: &window,
                                            resumedWindow: &resumedWindow)
            default:
                let challenge = day(seed % 400)
                found = try ResumeCheck.run(mode: challenge.mode, seed: seed, theme: theme,
                                            daily: challenge, playFor: playFor, window: &window,
                                            resumedWindow: &resumedWindow)
            }
            print("SOAK resume seed \(seed) \(found.isEmpty ? "ok" : "FAILED")")
            failures += found
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// Long games under `PlayWatch`: every Classic level in turn, the original Endless, Mayhem from
    /// a range of depths, and dailies - half a minute to a minute each.
    func testPlaySoak() throws {
        let range = try seeds()
        let themeCount = max(1, themes)
        let levels = DailyChallengeGenerator.classicLevelCount
        var failures: [String] = []
        for seed in range {
            var random = PlayWatch.Seeded(state: seed &* 15485863)
            let theme = Int(seed % UInt64(themeCount))
            let seconds = Double.random(in: 30...60, using: &random)
            let found: [String]
            switch seed % 6 {
            case 0, 1:
                let catalogue = Int(seed % UInt64(levels)) + 1
                let level = DailyChallengeGenerator.levelNumber(forClassicLevel: catalogue)
                let pack = DailyChallengeGenerator.pack(forClassicLevel: catalogue)
                found = try PlayWatch.watch(seconds: seconds, seed: seed,
                                            label: "Classic level \(level) theme \(theme) seed \(seed)") {
                    try PaddleFamilySweep.present(theme: theme, keeping: &self.window, mode: .classic,
                                                  frozen: false, level: level, pack: pack)
                }
            case 2:
                found = try PlayWatch.watch(seconds: seconds, seed: seed,
                                            label: "Endless theme \(theme) seed \(seed)") {
                    try PaddleFamilySweep.present(theme: theme, keeping: &self.window, mode: .endless,
                                                  frozen: false)
                }
            case 3, 4:
                let height = Int.random(in: 0...1200, using: &random)
                found = try PlayWatch.watch(seconds: seconds, seed: seed,
                                            label: "Mayhem from \(height)m theme \(theme) seed \(seed)") {
                    let scene = try PaddleFamilySweep.present(theme: theme, keeping: &self.window,
                                                              frozen: false)
                    scene.endlessHeight = height
                    return scene
                }
            default:
                let challenge = day(seed % 400)
                found = try PlayWatch.watch(seconds: seconds, seed: seed,
                                            label: "daily \(challenge.dateKey) \(challenge.mode) \(challenge.twists) seed \(seed)",
                                            powerUps: challenge.has(.noPowerUps) == false) {
                    DailyChallengeSession.shared.active = challenge
                    let level = challenge.classicLevel.map(DailyChallengeGenerator.levelNumber(forClassicLevel:))
                    let pack = challenge.classicLevel.map(DailyChallengeGenerator.pack(forClassicLevel:)) ?? 1
                    return try PaddleFamilySweep.present(theme: theme, keeping: &self.window,
                                                         mode: challenge.mode, frozen: false,
                                                         level: level, pack: pack)
                }
                DailyChallengeSession.shared.active = nil
            }
            print("SOAK play seed \(seed) \(found.isEmpty ? "ok" : "FAILED")")
            failures += found
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// Every day of the coming year as the generator will deal it, played for eight seconds.
    func testDailyYearSoak() throws {
        let range = try seeds()
        var failures: [String] = []
        for offset in range {
            let challenge = day(offset)
            let found = try PlayWatch.watch(seconds: 8, seed: offset + 500,
                                            label: "daily \(challenge.dateKey) \(challenge.mode) \(challenge.twists)",
                                            powerUps: challenge.has(.noPowerUps) == false) {
                DailyChallengeSession.shared.active = challenge
                let level = challenge.classicLevel.map(DailyChallengeGenerator.levelNumber(forClassicLevel:))
                let pack = challenge.classicLevel.map(DailyChallengeGenerator.pack(forClassicLevel:)) ?? 1
                return try PaddleFamilySweep.present(theme: 0, keeping: &self.window,
                                                     mode: challenge.mode, frozen: false,
                                                     level: level, pack: pack)
            }
            DailyChallengeSession.shared.active = nil
            print("SOAK daily \(challenge.dateKey) \(found.isEmpty ? "ok" : "FAILED")")
            failures += found
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
