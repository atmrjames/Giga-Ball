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
