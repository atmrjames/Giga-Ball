//
//  ScoringTests.swift
//  GigaBallTests
//
//  Scoring holds the rules lifted out of GameScene. The extraction was meant
//  to be inert, so these tests pin the arithmetic as it shipped - including
//  the parts that look wrong. Anything here that reads oddly is called out;
//  changing it changes what players score and breaks comparability with the
//  scores already on the leaderboards.
//

import XCTest
@testable import Giga_Ball

final class ScoringTests: XCTestCase {

    // MARK: - Base values

    func testBaseValuesAreUnchanged() {
        XCTAssertEqual(Scoring.brickDestroyed, 10)
        XCTAssertEqual(Scoring.levelCompleted, 100)
        XCTAssertEqual(Scoring.timerBonusStart, 500)
        XCTAssertEqual(Scoring.multiplierBase, 1.0)
        XCTAssertEqual(Scoring.multiplierCap, 2.0)
        XCTAssertEqual(Scoring.multiplierStep, 0.1)
        XCTAssertEqual(Scoring.bricksPerMultiplierStep, 20)
    }

    // MARK: - Awards

    func testAwardScalesByMultiplier() {
        XCTAssertEqual(Scoring.award(10, multiplier: 1.0), 10)
        XCTAssertEqual(Scoring.award(10, multiplier: 2.0), 20)
        XCTAssertEqual(Scoring.award(100, multiplier: 1.5), 150)
        XCTAssertEqual(Scoring.award(1000, multiplier: 2.0), 2000)
    }

    func testAwardTruncatesRatherThanRounds() {
        // Int(Double) truncates. A half-point award rounds down, not to
        // nearest, and every score on the leaderboards was computed this way.
        XCTAssertEqual(Scoring.award(10, multiplier: 1.05), 10, "10.5 truncates to 10")
        XCTAssertEqual(Scoring.award(10, multiplier: 1.5), 15)
        XCTAssertEqual(Scoring.award(10, multiplier: 1.7), 17)
    }

    func testAwardTruncatesBinaryDriftDownwards() {
        // Where a product lands fractionally short of an integer, the player
        // loses the point. 100 x 1.005 is 100.49999999999999 in double.
        XCTAssertEqual(Scoring.award(100, multiplier: 1.005), 100)
    }

    func testNegativeAwardsTruncateTowardZeroToo() {
        // The penalty power-ups are -100 and -1000. Truncation toward zero
        // makes a penalty very slightly smaller in the player's favour, never
        // larger - -10.5 becomes -10, not -11.
        XCTAssertEqual(Scoring.award(-10, multiplier: 1.05), -10)
        XCTAssertEqual(Scoring.award(-100, multiplier: 1.0), -100)
        XCTAssertEqual(Scoring.award(-100, multiplier: 1.5), -150)
        XCTAssertEqual(Scoring.award(-1000, multiplier: 2.0), -2000)
    }

    func testLevelCompletionIsNotMultiplied() {
        // The specification says every award is multiplied. GameScene adds the
        // level-completion bonus flat, at both of its call sites. Preserved.
        XCTAssertEqual(Scoring.levelCompletionAward(), 100)
    }

    // MARK: - Timer bonus

    func testTimerBonusLosesAPointPerSecond() {
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 0, multiplier: 1.0), 500)
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 100, multiplier: 1.0), 400)
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 499, multiplier: 1.0), 1)
    }

    func testTimerBonusFloorsAtZeroBeforeMultiplying() {
        // A slow level scores zero, not a negative bonus - and the floor is
        // applied before the multiplier, so a high multiplier cannot turn an
        // overrun into a larger penalty.
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 500, multiplier: 2.0), 0)
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 900, multiplier: 2.0), 0)
    }

    func testTimerBonusIsMultiplied() {
        // This is what makes finishing quickly on a high multiplier worth more
        // than the brick score alone.
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 100, multiplier: 2.0), 800)
        XCTAssertEqual(Scoring.timerBonus(from: 500, elapsed: 0, multiplier: 2.0), 1000)
    }

    // MARK: - Multiplier: the brick path

    func testBrickStepRaisesByOneTenth() {
        XCTAssertEqual(Scoring.steppedForBrick(1.0), 1.1, accuracy: 1e-9)
        XCTAssertEqual(Scoring.steppedForBrick(1.5), 1.6, accuracy: 1e-9)
    }

    func testBrickStepStopsAtTheCap() {
        XCTAssertEqual(Scoring.steppedForBrick(2.0), 2.0)
        XCTAssertEqual(Scoring.steppedForBrick(2.5), 2.5, accuracy: 1e-9)
    }

    func testBrickStepDoesNotSnapToTheCap() {
        // CHARACTERISATION: the brick path has no snap, so ten steps from 1.0
        // do not land on exactly 2.0. The other two paths do snap. Preserved
        // because snapping would change scores by a point here and there.
        var multiplier = 1.0
        for _ in 0..<10 {
            multiplier = Scoring.steppedForBrick(multiplier)
        }
        XCTAssertNotEqual(multiplier, 2.0,
                          "Expected floating-point drift, not an exact 2.0")
        XCTAssertEqual(multiplier, 2.0, accuracy: 1e-9)
        XCTAssertTrue(Scoring.isAtCap(multiplier),
                      "Drift must still read as capped, or the label never turns")
    }

    func testBrickStepCannotRunAwayPastTheCap() {
        // Even without a snap, the guard stops it: once at or above the cap it
        // stays put, so drift can never compound into a third decimal place.
        var multiplier = 1.0
        for _ in 0..<200 {
            multiplier = Scoring.steppedForBrick(multiplier)
        }
        XCTAssertLessThan(multiplier, 2.1)
    }

    // MARK: - Multiplier: the bonus path

    func testBonusStepSnapsToTheCap() {
        var multiplier = 1.0
        for _ in 0..<10 {
            multiplier = Scoring.steppedForBonus(multiplier)
        }
        XCTAssertEqual(multiplier, 2.0, "The bonus path snaps exactly")
    }

    func testBonusStepHoldsAtTheCap() {
        XCTAssertEqual(Scoring.steppedForBonus(2.0), 2.0)
    }

    // MARK: - Multiplier: the power-up path

    func testPowerUpDeltasMoveTheMultiplier() {
        XCTAssertEqual(Scoring.adjusted(1.5, by: 0.1), 1.6, accuracy: 1e-9)
        XCTAssertEqual(Scoring.adjusted(1.5, by: -0.1), 1.4, accuracy: 1e-9)
        XCTAssertEqual(Scoring.adjusted(1.5, by: 0.0), 1.5, accuracy: 1e-9)
    }

    func testPowerUpDeltasClampToBothBounds() {
        XCTAssertEqual(Scoring.adjusted(1.0, by: -0.1), 1.0, "Never below the base")
        XCTAssertEqual(Scoring.adjusted(1.95, by: 0.1), 2.0, "Never above the cap")
        XCTAssertEqual(Scoring.adjusted(1.0, by: -5.0), 1.0)
        XCTAssertEqual(Scoring.adjusted(1.0, by: 5.0), 2.0)
    }

    func testLosingAndRegainingReturnsToTheSameValue() {
        // Away from the bounds the two deltas should cancel, so a bad power-up
        // followed by a good one is not a net loss.
        let there = Scoring.adjusted(1.5, by: -0.1)
        let back = Scoring.adjusted(there, by: 0.1)
        XCTAssertEqual(back, 1.5, accuracy: 1e-9)
    }

    // MARK: - Display

    func testDisplayStringIsOneDecimalPlace() {
        XCTAssertEqual(Scoring.displayString(1.0), "1.0")
        XCTAssertEqual(Scoring.displayString(2.0), "2.0")
        XCTAssertEqual(Scoring.displayString(1.5), "1.5")
    }

    func testDisplayStringHidesFloatingPointDrift() {
        // The drift from the brick path must not surface as "1.9000000000004"
        // in the HUD.
        var multiplier = 1.0
        for _ in 0..<9 {
            multiplier = Scoring.steppedForBrick(multiplier)
        }
        XCTAssertEqual(Scoring.displayString(multiplier), "1.9")
    }

    func testCapDetectionUsesGreaterThanOrEqual() {
        // Has to be >= rather than ==, because the brick path can land just
        // above 2.0.
        XCTAssertTrue(Scoring.isAtCap(2.0))
        XCTAssertTrue(Scoring.isAtCap(2.0000000000000004))
        XCTAssertFalse(Scoring.isAtCap(1.9))
    }

    // MARK: - A whole level

    func testATypicalLevelScoresTheSameAsBefore() {
        // End-to-end arithmetic for a level: 60 bricks destroyed, stepping the
        // multiplier every twentieth, then completion and a timer bonus. Pins
        // the interaction between the rules rather than each in isolation.
        var multiplier = Scoring.multiplierBase
        var score = 0
        var bricksSinceStep = 0

        for _ in 0..<60 {
            if bricksSinceStep == Scoring.bricksPerMultiplierStep - 1 {
                multiplier = Scoring.steppedForBrick(multiplier)
                bricksSinceStep = 0
            } else {
                bricksSinceStep += 1
            }
            score += Scoring.award(Scoring.brickDestroyed, multiplier: multiplier)
        }
        score += Scoring.levelCompletionAward()
        score += Scoring.timerBonus(from: Scoring.timerBonusStart,
                                    elapsed: 120,
                                    multiplier: multiplier)

        // 19 bricks at 1.0, then the 20th steps to 1.1 and so on: 663 from
        // bricks, 100 flat for completion, and (500 - 120) x 1.3 = 494 from the
        // timer.
        XCTAssertEqual(multiplier, 1.3, accuracy: 1e-9, "Three steps in 60 bricks")
        XCTAssertEqual(score, 1_257)
    }
}
