//
//  EndlessIIProgressionTests.swift
//  GigaBallTests
//
//  The progression is the difference between "Endless with extra bricks" and a mode that
//  opens simply and gets stranger. It is also the easiest thing in the project to get
//  quietly wrong: an opening that is too busy is only obvious next to an opening that is
//  not, and a style that never appears looks exactly like one that is merely rare.
//

import XCTest
@testable import Giga_Ball

final class EndlessIIProgressionTests: XCTestCase {

    private let order = EndlessIIStyle.allCases
    private var progression: EndlessIIProgression {
        EndlessIIProgression(introductionOrder: order)
    }

    // MARK: - The ramps

    func testTheOpeningIsQuieterThanTheDeepField() {
        let p = progression
        XCTAssertLessThan(p.styleChance(at: 0), p.styleChance(at: 200))
        XCTAssertLessThan(p.stackChance(at: 0), p.stackChance(at: 200))
    }

    func testTheRampsNeverGoBackwards() {
        let p = progression
        for height in 1...400 {
            XCTAssertGreaterThanOrEqual(p.styleChance(at: height), p.styleChance(at: height - 1),
                                        "style at \(height)")
            XCTAssertGreaterThanOrEqual(p.stackChance(at: height), p.stackChance(at: height - 1),
                                        "stack at \(height)")
        }
    }

    func testTheRampsLevelOffRatherThanClimbingForEver() {
        // A run that keeps getting denser stops being hard and starts being unplayable.
        let p = progression
        XCTAssertEqual(p.styleChance(at: EndlessIIProgression.rampMetres),
                       p.styleChance(at: 5000))
        XCTAssertEqual(p.stackChance(at: EndlessIIProgression.rampMetres),
                       p.stackChance(at: 5000))
    }

    func testTheEndsOfTheRampAreTheValuesAsked() {
        let p = progression
        XCTAssertEqual(p.styleChance(at: 0), EndlessIIProgression.openingStyleChance)
        XCTAssertEqual(p.styleChance(at: 10_000), EndlessIIProgression.deepStyleChance)
        XCTAssertEqual(p.stackChance(at: 0), EndlessIIProgression.openingStackChance)
        XCTAssertEqual(p.stackChance(at: 10_000), EndlessIIProgression.deepStackChance)
    }

    func testStacksStayRarerThanSinglesAtEveryDepth() {
        // A second style is rolled only on a brick that already cleared the first roll, so
        // the real rate is the product - but the stack roll itself must not overtake the
        // first, or deep fields would be mostly doubles.
        let p = progression
        for height in stride(from: 0, through: 400, by: 10) {
            XCTAssertLessThanOrEqual(p.stackChance(at: height), p.styleChance(at: height)*2,
                                     "at \(height)")
        }
    }

    // MARK: - Introduction

    func testTheFirstStyleIsAvailableImmediately() {
        // A run that opened with nothing unusual for twelve metres would just be Endless.
        XCTAssertEqual(progression.introductionHeight(of: order[0]), 0)
    }

    func testEachStyleComesInAfterTheOneBeforeIt() {
        let p = progression
        for index in 1..<order.count {
            XCTAssertGreaterThan(p.introductionHeight(of: order[index]),
                                 p.introductionHeight(of: order[index - 1]))
        }
    }

    func testNothingIsEverLockedOut() {
        // The whole point of the early weight: somebody who never passes 20m should still
        // meet a Portal, rarely, rather than never.
        let p = progression
        for style in EndlessIIStyle.allCases {
            XCTAssertGreaterThan(p.weight(for: style, at: 0), 0, "\(style)")
        }
    }

    func testAnIntroducedStyleOutweighsOneThatIsNotYet() {
        let p = progression
        let last = order[order.count - 1]
        let deep = p.introductionHeight(of: last)
        XCTAssertGreaterThan(p.weight(for: last, at: deep), p.weight(for: last, at: deep - 1))
        XCTAssertEqual(p.weight(for: last, at: deep), EndlessIIProgression.introducedWeight)
        XCTAssertEqual(p.weight(for: last, at: 0), EndlessIIProgression.earlyWeight)
    }

    func testTheOrderDiffersBetweenRuns() {
        // Shuffled per run, so two runs to the same height meet a different subset. With
        // nine styles, twenty identical shuffles would be a broken shuffle, not luck.
        let first = EndlessIIProgression.make().introductionOrder
        let anyDifferent = (0..<20).contains { _ in
            EndlessIIProgression.make().introductionOrder != first
        }
        XCTAssertTrue(anyDifferent)
    }

    func testEveryStyleIsInTheOrderExactlyOnce() {
        let made = EndlessIIProgression.make().introductionOrder
        XCTAssertEqual(made.count, EndlessIIStyle.allCases.count)
        XCTAssertEqual(Set(made).count, EndlessIIStyle.allCases.count)
    }

    // MARK: - Picking

    func testPickingRespectsTheWeights() {
        // Deep enough that everything is introduced, so the roll maps straight onto the
        // pool in order.
        let p = progression
        let pool: [EndlessIIStyle] = [.rounded, .flashing, .gravity]
        XCTAssertEqual(p.pickStyle(from: pool, at: 1000, roll: { _ in 0 }), .rounded)
        XCTAssertEqual(p.pickStyle(from: pool, at: 1000, roll: { _ in 100 }), .flashing)
        XCTAssertEqual(p.pickStyle(from: pool, at: 1000, roll: { _ in 200 }), .gravity)
    }

    func testAnUnintroducedStyleCanStillBeDrawn() {
        // At height 0 only the first style is introduced, but the others keep a small
        // weight - so the last one in the order is reachable on the right roll.
        let p = progression
        let last = order[order.count - 1]
        let pool: [EndlessIIStyle] = [order[0], last]
        let total = EndlessIIProgression.introducedWeight + EndlessIIProgression.earlyWeight
        XCTAssertEqual(p.pickStyle(from: pool, at: 0, roll: { _ in total - 1 }), last)
    }

    func testPickingFromNothingGivesNothing() {
        XCTAssertNil(progression.pickStyle(from: [], at: 100))
    }

    func testPickingAlwaysReturnsSomethingFromANonEmptyPool() {
        let p = progression
        for height in [0, 20, 90, 400] {
            for roll in [0, 1, 37, 999] {
                XCTAssertNotNil(p.pickStyle(from: EndlessIIStyle.allCases, at: height,
                                            roll: { _ in roll }), "\(height)/\(roll)")
            }
        }
    }
}
