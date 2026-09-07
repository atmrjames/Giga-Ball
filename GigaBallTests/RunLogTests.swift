//
//  RunLogTests.swift
//  GigaBallTests
//
//  The run log's own bugs, found in round 313 by reading a log James sent from his phone.
//  Three lines of that log were wrong about a run he had just played, which is the one way
//  a log can be worse than no log at all.
//

import XCTest
@testable import Giga_Ball

final class RunLogTests: XCTestCase {

    // "RUN Classic Mode, rack 0" printed at the start of an Endless Mayhem run.
    //
    // The line asked the scene's `endlessMode`, which the pause menu sets and which is
    // therefore still false at pre-game. `rack 0` in the same line is the tell: the rack
    // branch had already read `startLevelNumber == 0` and taken the endless path.
    func testAMayhemRunDoesNotLogItselfAsClassic() {
        let defaults = UserDefaults(suiteName: "RunLogTests.mayhem")!
        defaults.removePersistentDomain(forName: "RunLogTests.mayhem")
        GameMode.endlessII.makeCurrent(in: defaults)

        let mode = GameMode.forRun(isDailyChallenge: false, startLevelNumber: 0,
                                   defaults: defaults)
        XCTAssertEqual(mode, .endlessII)
        XCTAssertNotEqual(mode.name, GameMode.classic.name)
    }

    func testAnEndlessRunLogsTheEndlessModeItIs() {
        let defaults = UserDefaults(suiteName: "RunLogTests.endless")!
        defaults.removePersistentDomain(forName: "RunLogTests.endless")
        GameMode.endless.makeCurrent(in: defaults)

        XCTAssertEqual(GameMode.forRun(isDailyChallenge: false, startLevelNumber: 0,
                                       defaults: defaults), .endless)
    }

    // A pack run starts at a level, so it is Classic whatever the stored mode says.
    func testAPackRunIsClassicWhateverWasPlayedLast() {
        let defaults = UserDefaults(suiteName: "RunLogTests.pack")!
        defaults.removePersistentDomain(forName: "RunLogTests.pack")
        GameMode.endlessII.makeCurrent(in: defaults)

        XCTAssertEqual(GameMode.forRun(isDailyChallenge: false, startLevelNumber: 3,
                                       defaults: defaults), .classic)
    }

    // The daily wins over both, including an endless daily, which starts at level zero.
    func testADailyIsADailyEvenWhenItIsAnEndlessOne() {
        let defaults = UserDefaults(suiteName: "RunLogTests.daily")!
        defaults.removePersistentDomain(forName: "RunLogTests.daily")
        GameMode.endlessII.makeCurrent(in: defaults)

        XCTAssertEqual(GameMode.forRun(isDailyChallenge: true, startLevelNumber: 0,
                                       defaults: defaults), .daily)
        XCTAssertEqual(GameMode.forRun(isDailyChallenge: true, startLevelNumber: 5,
                                       defaults: defaults), .daily)
    }

    // "RUN ENDED 5033 pts in 96s, 0 paddle hits, 130 bricks" - a completed Classic level,
    // played with the paddle, reporting that the paddle was never touched.
    //
    // The summary read `paddleHitsPerLevel`, and the level-completion achievement block
    // zeroes that counter a few lines before the summary is built. The per-level count has
    // to keep resetting - two achievements ask "in one level" - so the run keeps its own.
    func testTheRunsPaddleHitsSurviveTheLevelCounterBeingZeroed() {
        let recents = InGameRecents.shared
        recents.reset()

        for _ in 0..<130 { recents.paddleHit() }
        XCTAssertEqual(recents.paddleHitsThisRun, 130)

        // The level completes: `paddleHitsPerLevel = 0` runs in the scene. Nothing here
        // resets, because the run has not ended.
        for _ in 0..<44 { recents.paddleHit() }
        XCTAssertEqual(recents.paddleHitsThisRun, 174,
                       "a completed level must not take its paddle hits out of the run's total")
    }

    func testANewRunStartsWithNoPaddleHits() {
        let recents = InGameRecents.shared
        for _ in 0..<12 { recents.paddleHit() }
        recents.reset()
        XCTAssertEqual(recents.paddleHitsThisRun, 0)
    }
}
