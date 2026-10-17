//
//  EndlessIILockAndKeyTests.swift
//  GigaBallTests
//
//  §5.4's last two power-ups, and the only two whose eligibility is live game state rather
//  than a weight in a table:
//
//  - **Lock** freezes every active timed power-up; their timers stop. Only drops while at
//    least one timed power-up is active with enough time left to still be active when the
//    Lock reaches the paddle. Ends by itself, or by Key.
//  - **Key** ends the Lock; timers resume. Only drops while a Lock is active, so its weight
//    is set high inside that window - rare overall, reliably available while it is possible.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIILockAndKeyTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        return scene
    }

    // MARK: - The freeze

    func testALockStopsTheOtherClocksCountingDown() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.endlessIICollectLock()
        scene.endlessIIPaddleFrameDelta = 1

        let before = scene.endlessIIAuraClock.remaining
        scene.endlessIIAuraClock.run(down: scene.endlessIIClockDelta)

        XCTAssertEqual(scene.endlessIIAuraClock.remaining, before,
                       "a frozen clock does not lose time")
    }

    func testWithoutALockTheClocksRunAsUsual() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.endlessIIPaddleFrameDelta = 1

        scene.endlessIIAuraClock.run(down: scene.endlessIIClockDelta)
        XCTAssertEqual(scene.endlessIIAuraClock.remaining, 9, accuracy: 0.001)
    }

    /// James, round 218: "Lock shouldn't have a timer. It is only stopped by Key."
    ///
    /// It ran fifteen seconds and let go by itself, which made the Key a convenience rather
    /// than the answer to anything. A held Lock does not run down at all.
    func testALockDoesNotEndByItself() {
        let scene = mayhem()
        scene.endlessIICollectLock()

        for _ in 0..<600 { scene.tickEndlessIIFieldPowerUps() }
        XCTAssertTrue(scene.endlessIILocked, "the Lock let go without a Key")
        XCTAssertEqual(scene.endlessIIClockDelta, 0, "and the freeze went with it")
    }

    /// Its ring is full, always: there is no time left on it to draw, because time is not
    /// what ends it.
    func testALockedRingReadsAsFull() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        XCTAssertEqual(scene.endlessIILockClock.fraction, 1, accuracy: 0.001)
    }

    /// A second Lock while one is running changes nothing - there is nothing to extend.
    func testASecondLockChangesNothing() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        let held = scene.endlessIILockClock
        scene.endlessIICollectLock()

        XCTAssertEqual(scene.endlessIILockClock, held)
    }

    // MARK: - The Key

    func testAKeyEndsTheLockOutright() {
        // Not shortens it: a Key is the answer to a Lock, and an answer that only trimmed it
        // would leave the player still locked
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIITurnKey()

        XCTAssertFalse(scene.endlessIILocked)
        XCTAssertEqual(scene.endlessIILockClock.remaining, 0)
    }

    func testTheClocksRunAgainOnceTheKeyIsTurned() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.endlessIICollectLock()
        scene.endlessIIPaddleFrameDelta = 1
        scene.endlessIITurnKey()

        scene.endlessIIAuraClock.run(down: scene.endlessIIClockDelta)
        XCTAssertEqual(scene.endlessIIAuraClock.remaining, 9, accuracy: 0.001)
    }

    // MARK: - When they may drop

    func testALockDoesNotDropWithNothingToFreeze() {
        // It would land on an empty board, freeze nothing and read as a dud - which is worse
        // than a power-up that did not drop
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIILockMayDrop)
    }

    func testALockDropsWhileSomethingIsRunning() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        XCTAssertTrue(scene.endlessIILockMayDrop)
    }

    func testALockDoesNotDropForAClockThatWillHaveExpiredBeforeItLands() {
        // The drop has to fall to the paddle first
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(GameScene.endlessIILockLead/2)
        XCTAssertFalse(scene.endlessIILockMayDrop)
    }

    /// §12.0's descent-in-rows item, the half that lives here: the drop rule used to compare
    /// every clock's `remaining` against a lead measured in seconds, and Descent's clock
    /// counts rows now. A row does not decay while the Lock falls, so a running Descent is
    /// always worth freezing - even at one row left, where a seconds clock with the same
    /// number would have expired before the Lock landed.
    func testALockDropsForADescentDownToItsLastRow() {
        let scene = mayhem()
        scene.endlessIICollectDescent()
        for _ in 1..<GameScene.endlessIIDescentRows {
            scene.endlessIIDescentClock.spendTurn()
        }
        XCTAssertEqual(scene.endlessIIDescentClock.remaining, 1, accuracy: 0.001)
        XCTAssertLessThan(scene.endlessIIDescentClock.remaining,
                          GameScene.endlessIILockLead,
                          "fewer rows than the lead has seconds, which is the trap")
        XCTAssertTrue(scene.endlessIILockMayDrop,
                      "that row will still be there when the Lock lands")
    }

    func testALockStopsADescentSteppingAsWellAsCounting() {
        // The freeze reaches the cadence: a locked Descent takes no rows and spends none.
        // The raw frame delta used to leak into the pacing, which was free rows for the
        // length of every freeze
        let scene = mayhem()
        scene.totalStatsArray = [TotalStats()]
        scene.endlessIICollectDescent()
        scene.endlessIICollectLock()

        scene.endlessIIPaddleFrameDelta = GameScene.endlessIIDescentStep*3
        scene.tickEndlessIIDescent()

        XCTAssertEqual(scene.endlessHeight, 0, "no step while frozen")
        XCTAssertEqual(scene.endlessIIDescentClock.remaining,
                       TimeInterval(GameScene.endlessIIDescentRows), accuracy: 0.001)
    }

    func testALockDoesNotDropWhileOneIsAlreadyRunning() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.endlessIICollectLock()
        XCTAssertFalse(scene.endlessIILockMayDrop)
    }

    func testAKeyOnlyDropsWhileThereIsALockToUndo() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIKeyMayDrop, "nothing to unlock")

        scene.endlessIICollectLock()
        XCTAssertTrue(scene.endlessIIKeyMayDrop)

        scene.endlessIITurnKey()
        XCTAssertFalse(scene.endlessIIKeyMayDrop, "and not once it is undone")
    }

    func testNeitherDropsOutsideMayhem() {
        for mode in [GameMode.classic, .endless] {
            let scene = GameScene()
            scene.gameMode = mode
            scene.endlessIIAuraClock.collect(10)
            scene.endlessIICollectLock()

            XCTAssertFalse(scene.endlessIILockMayDrop, "\(mode)")
            XCTAssertFalse(scene.endlessIIKeyMayDrop, "\(mode)")
        }
    }

    // MARK: - The list the freeze and the drop rule share

    func testTheFrozenClocksAreTheOnesTheDropRuleLooksAt() {
        // One list, so the two cannot disagree about what "a timed power-up" means. If a
        // timed power-up is added and left out of it, a Lock will neither drop for it nor
        // freeze it - which from the outside looks like the Lock being broken
        let scene = mayhem()
        XCTAssertEqual(scene.endlessIITimedClocks.count,
                       GameScene.endlessIITimedClockPaths.count)
        // Counted off the list rather than written down beside it, because the number is not
        // the fact under test - that the two questions read one list is. It has been ten,
        // eleven, twelve, thirteen and now fourteen, and every one of those was a round where
        // somebody had to remember to change a number here as well.
        //
        // Ten since round 125: Randomised Bounce and Ghost Ball are both timed, so a Lock
        // freezes them and a Wipe clears them without either of those being edited. Eleven
        // since round 136, when Clear And Retreat stopped being instant, twelve since round
        // 143 and the Safety Paddle, thirteen since round 148 and Drift, fourteen since round
        // 219 and Quicksand's endless version. Double Paddle and Mirror Paddle visited in
        // rounds 151 and 168 and left in round 180, when both moved to paddle hits - a Lock
        // stops time, and they no longer spend any

        for path in GameScene.endlessIITimedClockPaths {
            let fresh = mayhem()
            fresh[keyPath: path].collect(10)
            // Through the key path rather than a switch over the indices: the list is the
            // thing under test, so the test should not carry its own second copy of it
            XCTAssertTrue(fresh.endlessIILockMayDrop,
                          "a running clock should make a Lock worth dropping")
        }
    }

    // MARK: - The arrays

    func testLockAndKeyAreNamedAndDescribedLikeEveryOtherPowerUp() {
        let setup = LevelPackSetup()
        XCTAssertEqual(setup.powerUpNameArray[48], "Lock")
        XCTAssertEqual(setup.powerUpNameArray[49], "Key")
        XCTAssertFalse(setup.powerUpDescriptionArray[48].isEmpty)
        XCTAssertFalse(setup.powerUpDescriptionArray[49].isEmpty)
    }

    // MARK: - Wipe

    /// §5.4: Wipe ends every power-up the player has running, at once.
    func testAWipeEndsEveryRunningPowerUp() {
        let scene = mayhem()
        for path in GameScene.endlessIIWipeableClockPaths {
            scene[keyPath: path].collect(10)
        }
        XCTAssertTrue(GameScene.endlessIIWipeableClockPaths
            .allSatisfy { scene[keyPath: $0].isRunning }, "the test set itself up wrong")

        scene.endlessIIWipe()

        for path in GameScene.endlessIIWipeableClockPaths {
            XCTAssertFalse(scene[keyPath: path].isRunning, "\(path)")
        }
    }

    /// **The rule the whole power-up hangs on** (§5.4): a Wipe does not remove a Lock.
    ///
    /// Otherwise Wipe does everything a Key does and takes your power-ups too, which makes
    /// Key worth nothing - and a power-up nobody wants to collect may as well not drop.
    func testAWipeDoesNotRemoveALock() {
        let scene = mayhem()
        scene.endlessIICollectLock()

        scene.endlessIIWipe()

        XCTAssertTrue(scene.endlessIILocked, "a Wipe is not a Key")
        XCTAssertEqual(scene.endlessIILockClock.fraction, 1, accuracy: 0.001)
    }

    /// And the freeze survives with it: a player who wipes while locked is still locked, and
    /// still needs the Key.
    func testTheFreezeSurvivesAWipe() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIIPaddleFrameDelta = 1

        scene.endlessIIWipe()

        XCTAssertEqual(scene.endlessIIClockDelta, 0)
    }

    /// The turn-based power-ups are wiped even though a Lock leaves them alone. A Lock stops
    /// time and they do not spend time; a Wipe ends power-ups and they are power-ups.
    func testAWipeReachesTheTurnBasedPowerUpsThatALockDoesNot() {
        let scene = mayhem()
        scene.endlessIIReversedControlsClock.collect(5)
        scene.endlessIIAutoAimClock.collect(5)

        XCTAssertFalse(scene.endlessIITimedClocks.contains { $0.isRunning },
                       "these two are deliberately not in the Lock's list")
        scene.endlessIIWipe()

        XCTAssertFalse(scene.endlessIIReversedControlsClock.isRunning)
        XCTAssertFalse(scene.endlessIIAutoAimClock.isRunning)
    }

    /// Every clock a Lock freezes is a clock a Wipe clears. The two lists are one list plus
    /// extras, and this is what says so - a timed power-up added to the Lock's list and left
    /// out of Wipe's would be frozen by one and ignored by the other.
    func testEveryClockALockFreezesIsOneAWipeClears() {
        for path in GameScene.endlessIITimedClockPaths {
            XCTAssertTrue(GameScene.endlessIIWipeableClockPaths.contains(path), "\(path)")
        }
        XCTAssertGreaterThan(GameScene.endlessIIWipeableClockPaths.count,
                             GameScene.endlessIITimedClockPaths.count)
    }

    /// The Lock's own clock is in neither list. In the Lock's, because a Lock that froze
    /// itself would never end; in Wipe's, because of the rule above.
    func testTheLocksOwnClockIsInNeitherList() {
        let lock: ReferenceWritableKeyPath<GameScene, EndlessIIClock> = \.endlessIILockClock
        XCTAssertFalse(GameScene.endlessIITimedClockPaths.contains(lock))
        XCTAssertFalse(GameScene.endlessIIWipeableClockPaths.contains(lock))
    }

    // MARK: - When a Wipe drops

    func testAWipeDoesNotDropWithNothingToTakeAway() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIWipeMayDrop,
                       "a bad power-up that takes nothing away is a gift, not a dud")

        scene.endlessIIAuraClock.collect(10)
        XCTAssertTrue(scene.endlessIIWipeMayDrop)
    }

    /// A turn-based power-up is worth wiping too, so it is worth dropping for.
    func testAWipeDropsForATurnBasedPowerUpAlone() {
        let scene = mayhem()
        scene.endlessIIInertPaddleClock.collect(3)
        XCTAssertTrue(scene.endlessIIWipeMayDrop)
    }

    func testAWipeNeverDropsOutsideMayhem() {
        let scene = GameScene()
        scene.gameMode = .endless
        scene.endlessIIAuraClock.collect(10)
        XCTAssertFalse(scene.endlessIIWipeMayDrop)

        scene.endlessIIWipe()
        XCTAssertTrue(scene.endlessIIAuraClock.isRunning,
                      "the original Endless has years of leaderboards and no Wipe in it")
    }
}

/// What a Lock does to the original twenty-eight's timers.
///
/// James's interaction matrix (round 221) lists Slow ball, Increase ball speed, Expand paddle,
/// Shrink paddle, Hide bricks, Sticky paddle, Gravity field, Giga-ball, Inert ball, Lasers,
/// Expand ball, Shrink ball and Backstop beside Lock and Key, along with Mayhem's own. Until
/// now a Lock froze Mayhem's clocks and left these running, so a player who locked a field full
/// of power-ups watched half of them expire anyway.
///
/// These are `SKAction` sequences on the scene rather than `EndlessIIClock`s, so freezing them
/// means setting the speed of the action and of the two that animate its icon to zero.
final class LockFreezesTheOldTimersTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// Stands in for a classic power-up's timer: the same shape, on the same key.
    private func startTimer(_ scene: GameScene, key: String) {
        scene.run(.sequence([.wait(forDuration: 10), .run {}]), withKey: key)
    }

    func testEveryOldTimerIsInTheTable() {
        let scene = mayhem()
        let keys = scene.endlessIIClassicTimers.map(\.key)
        for expected in ["powerUpDecreaseBallSpeed", "powerUpIncreaseBallSpeed",
                         "powerUpIncreasePaddleSize", "powerUpDecreasePaddleSize",
                         "powerUpGravityBall", "powerUpInvisibleBricks", "powerUpGigaBall",
                         "powerUpUndestructiBall", "powerUpLasers",
                         "powerUpIncreaseBallSize", "powerUpDecreaseBallSize"] {
            XCTAssertTrue(keys.contains(expected), "\(expected) is not frozen by a Lock")
        }
    }

    /// A locked timer stops counting, and starts again when the Key is turned.
    func testALockStopsAnOldTimerAndAKeyStartsItAgain() {
        let scene = mayhem()
        startTimer(scene, key: "powerUpGigaBall")

        scene.endlessIICollectLock()
        scene.tickEndlessIIFieldPowerUps()
        XCTAssertEqual(scene.action(forKey: "powerUpGigaBall")?.speed, 0,
                       "a Giga-Ball went on counting down inside a Lock")

        scene.endlessIITurnKey()
        scene.tickEndlessIIFieldPowerUps()
        XCTAssertEqual(scene.action(forKey: "powerUpGigaBall")?.speed, 1,
                       "the Key did not start it again")
    }

    /// And one collected *during* a Lock is frozen too.
    ///
    /// The freeze is written every frame rather than at each end of a Lock, which is the only
    /// way this can be true: a power-up collected while locked starts a fresh action at full
    /// speed, and nothing tells the Lock it has happened.
    func testAPowerUpCollectedInsideALockIsFrozenAsWell() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.tickEndlessIIFieldPowerUps()

        startTimer(scene, key: "powerUpLasers")
        XCTAssertEqual(scene.action(forKey: "powerUpLasers")?.speed, 1, "it starts at full speed")

        scene.tickEndlessIIFieldPowerUps()
        XCTAssertEqual(scene.action(forKey: "powerUpLasers")?.speed, 0,
                       "the next frame should have caught it")
    }

    /// The icon and its bar stop with it, so the bar keeps saying how much would be left.
    func testTheIconAndItsBarFreezeWithIt() {
        let scene = mayhem()
        scene.gigaBallIcon.run(.fadeOut(withDuration: 10), withKey: "powerUpGigaBallTimer")
        scene.gigaBallIconBar.run(.scaleX(to: 0, duration: 10), withKey: "gigaBallTimer")

        scene.endlessIICollectLock()
        scene.tickEndlessIIFieldPowerUps()

        XCTAssertEqual(scene.gigaBallIcon.action(forKey: "powerUpGigaBallTimer")?.speed, 0)
        XCTAssertEqual(scene.gigaBallIconBar.action(forKey: "gigaBallTimer")?.speed, 0)
    }

    /// A field with nothing but an old power-up running is worth dropping a Lock on.
    func testALockIsWorthDroppingForAnOldPowerUpAlone() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIILockMayDrop, "nothing is running")

        startTimer(scene, key: "powerUpGigaBall")
        XCTAssertTrue(scene.endlessIILockMayDrop,
                      "a Giga-Ball is exactly what a player wants a Lock for")
    }

    /// Nothing outside Endless Mayhem is touched.
    func testTheOtherModesAreLeftAlone() {
        let scene = mayhem()
        scene.gameMode = .classic
        startTimer(scene, key: "powerUpGigaBall")
        scene.endlessIIHoldClassicTimers(true)
        XCTAssertEqual(scene.action(forKey: "powerUpGigaBall")?.speed, 1,
                       "Classic has no Lock and must not be frozen by one")
    }
}

/// What a Wipe does to the original twenty-eight's timers.
///
/// The matrix's Wipe row names all eleven. Before round 222 it reached two of them - Gravity
/// and Inert Ball - and reached those by a second copy of what their ending blocks do, written
/// out by hand in the wipe. Two copies of a decision in the two places the game is oldest, and
/// the other nine simply were not wiped.
///
/// `runClassicPowerUpTimer` keeps each power-up's ending under the name its action runs under,
/// so a Wipe runs the very block the wait would have run.
final class WipeEndsTheOldTimersTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    /// The ending runs, the action goes, and the power-up is forgotten.
    func testAWipeRunsThePowerUpsOwnEnding() {
        let scene = mayhem()
        var ended = false
        scene.runClassicPowerUpTimer(key: "powerUpGigaBall",
                                     wait: .wait(forDuration: 10),
                                     ending: .run { ended = true })
        XCTAssertNotNil(scene.action(forKey: "powerUpGigaBall"))

        scene.endlessIIWipe()
        scene.run(.wait(forDuration: 0))   // let the ending's own run block land

        XCTAssertNil(scene.action(forKey: "powerUpGigaBall"), "the timer outlived the wipe")
        XCTAssertNil(scene.classicPowerUpEndings["powerUpGigaBall"],
                     "a wiped power-up is still remembered as running")
        _ = ended
        // The block itself lands on SpriteKit's own schedule, so what is asserted here is the
        // bookkeeping. That the ending *is* the power-up's own action is true by construction:
        // it is the same object, handed straight back
    }

    /// The icon and its bar are stopped too, or the ending fires again later and hides a bar
    /// that a power-up collected since might be using.
    func testAWipeStopsTheIconAnimationsAsWell() {
        let scene = mayhem()
        scene.runClassicPowerUpTimer(key: "powerUpLasers", wait: .wait(forDuration: 10),
                                     ending: .run {})
        scene.lasersIcon.run(.fadeOut(withDuration: 10), withKey: "powerUpLaserTimer")
        scene.lasersIconBar.run(.scaleX(to: 0, duration: 10), withKey: "laserTimer")

        scene.endlessIIWipe()

        XCTAssertNil(scene.lasersIcon.action(forKey: "powerUpLaserTimer"))
        XCTAssertNil(scene.lasersIconBar.action(forKey: "laserTimer"))
    }

    /// A Wipe is worth dropping when one of the old power-ups is all that is running.
    func testAWipeIsWorthDroppingForAnOldPowerUpAlone() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIWipeMayDrop)

        scene.runClassicPowerUpTimer(key: "powerUpIncreasePaddleSize",
                                     wait: .wait(forDuration: 10), ending: .run {})
        XCTAssertTrue(scene.endlessIIWipeMayDrop,
                      "a bad power-up with nothing to take away is a gift")
    }

    /// Every key in the freeze table is one a Wipe can reach, and the other way round.
    ///
    /// The two read one list, which is what stops a power-up being frozen by a Lock and left
    /// standing by a Wipe.
    func testTheLockAndTheWipeReadTheSameList() {
        let scene = mayhem()
        for (key, _) in scene.endlessIIClassicTimers {
            scene.runClassicPowerUpTimer(key: key, wait: .wait(forDuration: 10), ending: .run {})
        }
        XCTAssertTrue(scene.endlessIIClassicTimerRunning)

        scene.endlessIIWipe()
        for (key, _) in scene.endlessIIClassicTimers {
            XCTAssertNil(scene.action(forKey: key), "\(key) survived a Wipe")
        }
    }
}

/// **A Wipe brick is not built while there is nothing to wipe** (James, round 327: "Wipe power
/// up should only show when a power up is active").
///
/// The weights already answered this - `applyEndlessRowPowerUpWeights` zeroes Wipe while nothing
/// is running - and a brick outlives the row that built it, which is the hole. A row built while
/// a Lasers ran could hand a brick a Wipe, and the brick then sat in the field wearing its icon
/// long after the Lasers had ended, promising to take away something that was already gone.
final class WipeOnlyShowsWhileSomethingIsRunningTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.gameWidth = 400
        scene.endlessHeight = 5000
        // High enough that the kindness gate lets a brick hold a bad power-up: early bricks
        // hold good ones only (round 202), and a Wipe is not one
        scene.totalStatsArray[0].powerUpUnlockedArray = Array(
            repeating: true, count: scene.totalStatsArray[0].powerUpUnlockedArray.count)
        scene.powerUpProbArray = Array(repeating: 0, count: scene.powerUpProbArray.count)
        scene.powerUpProbArray[GameScene.wipePowerUpIndex] = 5
        // Only a Wipe on the table, so what comes back is the decision being tested rather
        // than the draw
        return scene
    }

    func testNoPowerUpBrickIsBuiltForAWipeWithNothingRunning() {
        let scene = mayhem()
        XCTAssertFalse(scene.endlessIIWipeMayDrop)

        XCTAssertNil(scene.endlessIIMakePowerUpBrick(column: 2, rowY: 100),
                     "a brick holding a Wipe with nothing to end is a gift wearing a threat")
        XCTAssertTrue(scene.endlessIIPowerUpBricksInPlay.isEmpty)
    }

    func testTheSameBrickIsBuiltOnceSomethingIsRunning() throws {
        let scene = mayhem()
        scene.runClassicPowerUpTimer(key: "powerUpLasers", wait: .wait(forDuration: 10),
                                     ending: .run {})
        XCTAssertTrue(scene.endlessIIWipeMayDrop)

        let brick = try XCTUnwrap(scene.endlessIIMakePowerUpBrick(column: 2, rowY: 100),
                                  "with a Lasers running there is something for it to take")
        XCTAssertEqual(brick.endlessIIPowerUpIndex, GameScene.wipePowerUpIndex)
    }
}

/// Round 354's Lock: what it holds, what it lets run, and how the player gets out of it.
final class EndlessIILockHoldsEverythingTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        return scene
    }

    // MARK: - Turns

    /// James, round 354: "I had ball trajectory that ended and then collected sticky paddle
    /// that started counting down the uses. Any power up collected with lock active ... should
    /// remain on". The Lock stopped time, and the paddle-hit power-ups do not spend time.
    func testALockHoldsThePaddleHitPowerUpsAsWellAsTheTimedOnes() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIICollectPortalPaddle()
        scene.endlessIICollectTrajectoryLine()
        let portal = scene.endlessIIPortalPaddleClock.remaining
        let trajectory = scene.endlessIITrajectoryRemaining

        for _ in 0..<10 { scene.endlessIISpendPaddleTurns() }

        XCTAssertEqual(scene.endlessIIPortalPaddleClock.remaining, portal,
                       "a paddle hit under a Lock spent a Portal Paddle turn")
        XCTAssertEqual(scene.endlessIITrajectoryRemaining, trajectory,
                       "a paddle hit under a Lock spent a Trajectory turn - the reported one")
    }

    func testTheHitsStillDeliverWhatTheyBuyUnderALock() {
        // Held, not switched off: the owed turn is what makes a portal hit a portal hit
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIICollectPortalPaddle()
        scene.endlessIISpendPaddleTurns()
        XCTAssertTrue(scene.endlessIIPortalPaddleOwedTurn)
    }

    func testTheTurnsCountAgainOnceTheKeyLands() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIICollectPortalPaddle()
        let before = scene.endlessIIPortalPaddleClock.remaining
        scene.endlessIITurnKey()
        scene.endlessIISpendPaddleTurns()
        XCTAssertLessThan(scene.endlessIIPortalPaddleClock.remaining, before)
    }

    /// The reported power-up: Sticky Paddle's catches are the one turn count outside the clocks.
    func testALockHoldsTheStickyPaddlesCatches() {
        let scene = mayhem()
        scene.stickyPaddleCatches = 3
        scene.endlessIICollectLock()
        scene.spendStickyPaddleCatch()
        XCTAssertEqual(scene.stickyPaddleCatches, 3, "sticky paddle counted down under a Lock")

        scene.endlessIITurnKey()
        scene.spendStickyPaddleCatch()
        XCTAssertEqual(scene.stickyPaddleCatches, 2)
    }

    /// A Sticky Paddle *taken away* under a Lock still goes. Its ending spends every catch in a
    /// loop, and a catch held by the Lock would have kept that loop running for ever.
    func testAStickyPaddleEndedByAnotherPowerUpUnderALockStillEnds() {
        let scene = mayhem()
        scene.totalStatsArray = [TotalStats()]
        scene.stickyPaddleCatches = 3
        scene.stickyPaddleCatchesTotal = 3
        scene.endlessIICollectLock()
        scene.endlessIICollectBallSpin()
        XCTAssertEqual(scene.stickyPaddleCatches, 0, "Ball Spin ends a Sticky Paddle, Lock or no")
    }

    /// A Lock ends with the ball, like everything it was holding - found in round 354 when a
    /// replay started with the capsule still wearing the Lock's border and nothing inside it.
    func testALostBallTakesTheLockAndQuicksandWithIt() {
        let scene = mayhem()
        scene.endlessIICollectLock()
        scene.endlessIIQuicksandClock.collect(10)
        scene.endlessIIResetFieldPowerUps()
        XCTAssertFalse(scene.endlessIILocked, "a Lock outlived the ball, and then the run")
        XCTAssertFalse(scene.endlessIIQuicksandClock.isRunning)
    }

    // MARK: - The field

    /// James, round 354: "Lock power up with brick retreat power up enabled and bricks stopped
    /// descending when the bottom row was clear meant the game effectively broke once the
    /// board was totally clear" - and round 356, on how to answer it: "Retreat and quicksand
    /// can remain on during lock, so long as the bricks keep descending to the bottom row, even
    /// if that bottom row is higher or lower due to the power-up".
    func testALockFreezesRetreatAndQuicksandLikeEverythingElse() {
        for path: ReferenceWritableKeyPath<GameScene, EndlessIIClock>
                in [\.endlessIIClearAndRetreatClock, \.endlessIIQuicksandClock] {
            XCTAssertTrue(GameScene.endlessIITimedClockPaths.contains(path), "\(path)")
        }
    }

    func testUnderALockARetreatStaysOnAndTheFieldStillDescends() {
        // Round 356 let the field descend under a Lock; round 360 lets it descend always
        // (James: "Quicksand just moves the lowest row down ... It's the same with brick
        // retreat, that just raises the bottom row, but the same row rules apply")
        let scene = mayhem()
        scene.gameState.enter(Playing.self)
        scene.endlessIIClearAndRetreatClock.collect(1)
        XCTAssertFalse(scene.endlessIIFieldIsHeld,
                       "a settled field descends against the raised floor, Lock or no Lock")

        scene.endlessIICollectLock()
        XCTAssertFalse(scene.endlessIIFieldIsHeld,
                       "under a Lock the field must keep descending, or nothing ends the Lock")

        scene.endlessIIPaddleFrameDelta = 0.5
        for _ in 0..<8 { scene.tickEndlessIIFieldPowerUps() }
        XCTAssertTrue(scene.endlessIIClearAndRetreatClock.isRunning,
                      "the Retreat stays on while the Lock holds it")

        scene.endlessIITurnKey()
        XCTAssertFalse(scene.endlessIIFieldIsHeld, "and nothing changes once it is unlocked")
    }

    func testANewRowArrivesOnTheTopRowWhereverTheShiftHasPutIt() {
        let scene = mayhem()
        scene.yBrickOffsetEndless = 300
        scene.brickHeight = 20
        XCTAssertEqual(scene.endlessNewRowY, 300)
        scene.endlessIIFieldShift = 40
        XCTAssertEqual(scene.endlessNewRowY, 340,
                       "a lifted field's new row on the old top row lands on a lifted brick")
        scene.endlessIIFieldShift = -40
        XCTAssertEqual(scene.endlessNewRowY, 260)
    }

    // MARK: - The HUD

    /// "change the colour of the power-up progress bars to white - this indicates that all the
    /// power-ups are locked in"
    func testEveryRingIsMarkedHeldUnderALock() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.endlessIIClearAndRetreatClock.collect(10)
        XCTAssertTrue(scene.activePowerUpEntries().allSatisfy { $0.held == false })

        scene.endlessIICollectLock()
        let entries = scene.activePowerUpEntries()
        XCTAssertFalse(entries.isEmpty)
        XCTAssertTrue(entries.allSatisfy(\.held), "Retreat included, since round 356")
    }

    func testTheCapsuleWearsTheLimeBorderOnlyWhileLocked() {
        // Compared by alpha and green: SpriteKit hands the colour back in another colour space,
        // so the same lime is not `==` to the one it was given
        let hud = PowerUpRingHUD()
        let border = hud.lockBorderForTesting
        XCTAssertEqual(border.strokeColor.cgColor.alpha, 0)
        hud.locked = true
        var green: CGFloat = 0, alpha: CGFloat = 0
        border.strokeColor.getRed(nil, green: &green, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 1)
        XCTAssertEqual(green, 1, accuracy: 0.01)
        XCTAssertGreaterThan(border.glowWidth, 0)
        hud.locked = false
        XCTAssertEqual(border.strokeColor.cgColor.alpha, 0)
    }

    /// James, round 385c: "The lock glow around the power-up HUD overlaps the score labels a
    /// little bit - the glow could sit a bit closer to the power-up HUD icons." The border is
    /// drawn inside the capsule's edge now, so its glow reaches that much less far out, and the
    /// capsule itself is the size it always was.
    func testTheLockBorderSitsInsideTheCapsule() {
        let hud = PowerUpRingHUD()
        hud.update(with: [])
        hud.locked = true
        let capsule = try? XCTUnwrap(hud.containerForTesting.path?.boundingBox)
        let border = try? XCTUnwrap(hud.lockBorderForTesting.path?.boundingBox)
        XCTAssertEqual((capsule?.height ?? 0) - (border?.height ?? 0),
                       PowerUpRingHUD.lockBorderInset*2, accuracy: 0.01)
        XCTAssertEqual((capsule?.width ?? 0) - (border?.width ?? 0),
                       PowerUpRingHUD.lockBorderInset*2, accuracy: 0.01)
    }

    // MARK: - The way out

    /// "make the wipe and key power-ups more likely when lock is active"
    func testWipeAndKeyAreLikelierWhileLocked() {
        let scene = mayhem()
        scene.endlessIIAuraClock.collect(10)
        scene.applyEndlessIIConditionalWeights()
        let wipeBefore = scene.powerUpProbArray[GameScene.wipePowerUpIndex]
        XCTAssertGreaterThan(wipeBefore, 0)

        scene.endlessIICollectLock()
        XCTAssertGreaterThan(scene.powerUpProbArray[GameScene.wipePowerUpIndex], wipeBefore)
        XCTAssertGreaterThan(scene.powerUpProbArray[GameScene.keyPowerUpIndex], 0,
                             "the Key has to be droppable the moment the Lock lands, not a row later")

        scene.endlessIITurnKey()
        XCTAssertEqual(scene.powerUpProbArray[GameScene.wipePowerUpIndex], wipeBefore)
        XCTAssertEqual(scene.powerUpProbArray[GameScene.keyPowerUpIndex], 0)
    }
}

/// Round 354, James: "Hitting a power up brick (which was multi-ball) with a laser didn't
/// activate the power-up (the extra ball never appear) it should". A laser can break a brick
/// while the ball is being lost, and `applyPowerUp` turns everything away then - so the
/// power-up was gone. It is held until the ball is back now.
final class HeldBrickPowerUpTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        // `didMove` fills this, and a power-up is known by its texture (`ApplyPowerUpTests`)
        return scene
    }

    private func powerUpBrick(in scene: GameScene, holding index: Int) -> SKSpriteNode {
        let brick = SKSpriteNode(color: .white, size: CGSize(width: 30, height: 15))
        brick.name = BrickCategoryName
        brick.endlessIIPowerUpIndex = index
        scene.addChild(brick)
        return brick
    }

    func testABrickBrokenWhileTheBallIsLostKeepsItsPowerUpForTheNextBall() {
        let scene = scene()
        scene.ballLostBool = true
        let brick = powerUpBrick(in: scene, holding: GameScene.lockPowerUpIndex)

        XCTAssertTrue(scene.endlessIITriggerPowerUpBrick(brick))
        XCTAssertNil(brick.parent, "the brick still breaks")
        XCTAssertEqual(scene.endlessIIHeldBrickPowerUps, [GameScene.lockPowerUpIndex])
        XCTAssertFalse(scene.endlessIILocked, "nothing is applied to a ball that is not there")

        scene.releaseEndlessIIHeldBrickPowerUps()
        XCTAssertFalse(scene.endlessIILocked, "still waiting: the ball has not come back")

        scene.ballLostBool = false
        scene.releaseEndlessIIHeldBrickPowerUps()
        XCTAssertTrue(scene.endlessIIHeldBrickPowerUps.isEmpty)
        XCTAssertTrue(scene.endlessIILocked, "the held power-up landed on the next ball")
    }

    func testARunEndingThrowsAwayWhatWasHeld() {
        let scene = scene()
        scene.endlessIIHeldBrickPowerUps = [GameScene.lockPowerUpIndex]
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.powerUpsReset()
        XCTAssertTrue(scene.endlessIIHeldBrickPowerUps.isEmpty,
                      "a power-up waiting for a lost ball does not outlive the run")
    }
}

/// James, round 388: "For an always on or locked power-up, give it a full white glowing ring in
/// the power-up HUD instead of the Giga-Ball green/yellow to signify it's always on. For paddle
/// hit power-ups with the segmented rings, make them solid whilst they are always on or locked.
/// If they become unlocked, revert to the standard look for the respective power-up."
final class RingHUDStandingTests: XCTestCase {

    private func white(_ colour: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        colour.getRed(&r, green: &g, blue: &b, alpha: &a)
        return r > 0.99 && g > 0.99 && b > 0.99
    }

    func testAHeldRingIsFullSolidAndWhiteAndGoesBackWhenLetGo() throws {
        let hud = PowerUpRingHUD()
        let radius = PowerUpRingHUD.ringRadius(iconSize: hud.iconSize)
        var entry = PowerUpRingHUD.Entry(id: "turns", texture: SKTexture(),
                                         remaining: 1, segments: 5)
        hud.update(with: [entry])
        let ring = try XCTUnwrap(hud.ringForTesting("turns"))
        let segmented = PowerUpRingHUD.ringPath(remaining: 1, segments: 5, radius: radius)
        let solid = PowerUpRingHUD.ringPath(remaining: 1, segments: nil, radius: radius)
        XCTAssertEqual(ring.path, segmented, "five marks for five paddle hits")
        XCTAssertFalse(white(ring.strokeColor))

        entry.held = true
        hud.update(with: [entry])
        XCTAssertEqual(ring.path, solid, "solid while it is held")
        XCTAssertTrue(white(ring.strokeColor), "and white")

        entry.held = false
        hud.update(with: [entry])
        XCTAssertEqual(ring.path, segmented,
                       "let go, it is the segmented ring again, though nothing has been spent")
        XCTAssertFalse(white(ring.strokeColor))
    }

    func testAHeldTimerIsDrawnFullWhateverItHasLeft() throws {
        let hud = PowerUpRingHUD()
        let radius = PowerUpRingHUD.ringRadius(iconSize: hud.iconSize)
        var entry = PowerUpRingHUD.Entry(id: "timed", texture: SKTexture(), remaining: 0.4)
        entry.held = true
        hud.update(with: [entry])
        XCTAssertEqual(hud.ringForTesting("timed")?.path,
                       PowerUpRingHUD.ringPath(remaining: 1, segments: nil, radius: radius),
                       "a Lock's ring is full, not frozen at four tenths")
    }

    /// The Always On twist finds its own ring by the name in the clock table; a typo there
    /// would leave the day's power-up lime with nothing to say so.
    func testEveryClocksRingIsDrawnUnderTheNameTheTableGivesIt() {
        for row in GameScene.endlessIIClocksByPowerUp {
            let scene = GameScene()
            scene.gameMode = .endlessII
            scene[keyPath: row.clock].collect(turns: 3)
            XCTAssertTrue(scene.activePowerUpEntries().contains { $0.id == row.ring },
                          "power-up \(row.index) is drawn as \(row.ring)")
        }
    }

    func testAShapeOrALeftwardDriftFindsTheRingItShares() {
        let setup = LevelPackSetup()
        XCTAssertEqual(GameScene.ringID(forPowerUp: setup.powerUpNameArray.firstIndex(of: "Concave Paddle")!),
                       "endlessIIPaddleSurface")
        XCTAssertEqual(GameScene.ringID(forPowerUp: setup.powerUpNameArray.firstIndex(of: "Drift Left")!),
                       "endlessIIDrift")
        let shrinkBall = setup.powerUpNameArray.firstIndex(of: "Shrink Ball")!
        let slot = GameScene.trayPowerUpFamilies.firstIndex { $0.contains(shrinkBall) }!
        XCTAssertEqual(GameScene.ringID(forPowerUp: shrinkBall), "tray\(slot)")
    }
}

/// James, before submitting 1.3: "Don't show the lock power-up if there are no active timed or
/// paddle hit based power-ups - make sure there's enough time / hits left on the active
/// power-ups that they will still be active when the lock power-up is collected."
final class LockOnlyWhenItHoldsSomethingTests: XCTestCase {

    private func mayhem() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.brickWidth = 40
        scene.brickHeight = 20
        scene.powerUpTextureArray = scene.powerUpTexturesInOrder
        scene.powerUpProbArray = Array(repeating: 0, count: scene.powerUpTexturesInOrder.count)
        return scene
    }

    func testAPaddleHitPowerUpOnItsLastHitIsNothingForALockToHold() {
        var clock = EndlessIIClock()
        clock.collect(turns: 5)
        XCTAssertTrue(clock.outlastsALockDrop(lead: GameScene.endlessIILockLead))
        for _ in 0..<3 { clock.spendTurn(thenLingerFor: 1) }
        XCTAssertTrue(clock.outlastsALockDrop(lead: GameScene.endlessIILockLead), "two hits left")
        clock.spendTurn(thenLingerFor: 1)
        XCTAssertFalse(clock.outlastsALockDrop(lead: GameScene.endlessIILockLead),
                       "one hit left is spent by the bounce before the Lock is caught")
        clock.spendTurn(thenLingerFor: 1)
        XCTAssertFalse(clock.outlastsALockDrop(lead: GameScene.endlessIILockLead),
                       "nor is the second of goodbye after the last")
    }

    func testAnOldTimerNearlyRunOutIsNothingForALockToHold() {
        let scene = mayhem()
        scene.addChild(scene.gravityIconBar)
        scene.run(.wait(forDuration: 60), withKey: "powerUpGravityBall")
        scene.gravityIconBar.xScale = 0.9
        XCTAssertTrue(scene.endlessIILockMayDrop, "nine seconds of Gravity Ball left")
        scene.gravityIconBar.xScale = 0.1
        XCTAssertFalse(scene.endlessIILockMayDrop, "one second left, gone before a Lock lands")
    }

    func testALockBrickOutlivingWhatItWouldFreezeHoldsSomethingElse() {
        let scene = mayhem()
        for name in ["Magnetism", "Halo", "Ball Control"] {
            if let index = LevelPackSetup.shared.powerUpNameArray.firstIndex(of: name) {
                scene.powerUpProbArray[index] = 5
            }
        }
        scene.powerUpProbArray[GameScene.lockPowerUpIndex] = 3
        let brick = SKSpriteNode(color: .white, size: CGSize(width: 40, height: 40))
        brick.name = BrickCategoryName
        brick.endlessIIPowerUpIndex = GameScene.lockPowerUpIndex
        scene.addChild(brick)

        scene.endlessIIAuraClock.collect(10)
        XCTAssertFalse(scene.keepEndlessIIPowerUpBrickWorthHaving(brick),
                       "while the Aura has time left the Lock is worth having")
        XCTAssertEqual(brick.endlessIIPowerUpIndex, GameScene.lockPowerUpIndex)

        scene.endlessIIAuraClock.reset()
        XCTAssertTrue(scene.keepEndlessIIPowerUpBrickWorthHaving(brick))
        XCTAssertNotEqual(brick.endlessIIPowerUpIndex, GameScene.lockPowerUpIndex,
                          "nothing left to freeze, so the brick no longer shows a Lock")
        XCTAssertNotNil(brick.childNode(withName: GameScene.powerUpBrickName),
                        "and wears the icon of what it holds now")
    }
}
