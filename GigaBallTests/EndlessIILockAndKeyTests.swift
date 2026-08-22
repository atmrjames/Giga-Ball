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
        XCTAssertEqual(scene.endlessIITimedClocks.count, 13)
        // Ten since round 125: Randomised Bounce and Ghost Ball are both timed, so a Lock
        // freezes them and a Wipe clears them without either of those being edited. Eleven
        // since round 136, when Clear And Retreat stopped being instant, twelve since round
        // 143 and the Safety Paddle, thirteen since round 148 and Drift. Double Paddle and
        // Mirror Paddle visited in rounds 151 and 168 and left in round 180, when both moved
        // to paddle hits - a Lock stops time, and they no longer spend any

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
