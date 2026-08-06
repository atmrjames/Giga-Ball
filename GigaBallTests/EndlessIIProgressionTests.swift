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

    func testTheRampReachesTheDepthsPeopleActuallyPlayTo() {
        // The original Endless leaderboard tops out around a thousand metres and plenty of
        // runs pass a hundred. A ramp that finished early would mean the mode stopped
        // developing in the first minute of a good run.
        let p = progression
        XCTAssertGreaterThanOrEqual(EndlessIIProgression.rampMetres, 1000)
        XCTAssertLessThan(p.styleChance(at: 100), p.styleChance(at: 500))
        XCTAssertLessThan(p.styleChance(at: 500), p.styleChance(at: 900))
        XCTAssertLessThan(p.stackChance(at: 100), p.stackChance(at: 500))
        XCTAssertLessThan(p.stackChance(at: 500), p.stackChance(at: 900))
    }

    func testThereIsStillSomethingNewToMeetWellIntoARun() {
        // Introductions have to outlast the opening, or everything is known within a minute
        // and the rest of the ramp is only about frequency.
        let p = progression
        let last = order[order.count - 1]
        XCTAssertGreaterThan(p.introductionHeight(of: last), 150)
    }

    func testTheRampsNeverGoBackwards() {
        let p = progression
        for height in 1...1200 {
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
        // From the first metre, not from zero - the very first screen is a special case and
        // has nothing unusual on it at all.
        let p = progression
        XCTAssertEqual(p.styleChance(at: 1), EndlessIIProgression.openingStyleChance)
        XCTAssertEqual(p.styleChance(at: 10_000), EndlessIIProgression.deepStyleChance)
        XCTAssertEqual(p.stackChance(at: 1), EndlessIIProgression.openingStackChance)
        XCTAssertEqual(p.stackChance(at: 10_000), EndlessIIProgression.deepStackChance)
    }

    func testStacksStayRarerThanSinglesAtEveryDepth() {
        // A second style is rolled only on a brick that already cleared the first roll, so
        // the real rate is the product - but the stack roll itself must not overtake the
        // first, or deep fields would be mostly doubles.
        let p = progression
        for height in stride(from: 0, through: 1200, by: 10) {
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

extension EndlessIIProgressionTests {

    // MARK: - Density

    func testARunOpensNearlyEmpty() {
        // The complaint this fixes: a first row with several kinds of brick in it teaches a
        // player nothing, because everything arrives at once and none of it is legible.
        XCTAssertLessThan(progression.density(at: 0), 0.12)
    }

    func testDensityClimbsAndThenStops() {
        let p = progression
        XCTAssertLessThan(p.density(at: 0), p.density(at: 100))
        XCTAssertLessThan(p.density(at: 100), p.density(at: 400))
        XCTAssertEqual(p.density(at: EndlessIIProgression.densityCapMetres),
                       p.density(at: 5000), accuracy: 0.0001)
    }

    func testTheFieldNeverFillsUp() {
        // Past the cap what changes is what the bricks are, not how many. A field that kept
        // filling would end as a wall.
        let p = progression
        for height in stride(from: 0, through: 2000, by: 25) {
            for phase in EndlessIIPhase.allCases {
                XCTAssertLessThanOrEqual(p.density(at: height, phase: phase), 0.6,
                                         "\(height) / \(phase)")
            }
        }
    }

    func testDensityStopsClimbingLongBeforeTheRestOfTheRampDoes() {
        // Deliberate: the field stops getting fuller around 500m and carries on getting
        // stranger for another 500 after that.
        XCTAssertLessThan(EndlessIIProgression.densityCapMetres, EndlessIIProgression.rampMetres)
    }

    func testAQuietPhaseIsThinnerAndABusyOneIsFuller() {
        let p = progression
        let plain = p.density(at: 300, phase: .standard)
        XCTAssertLessThan(p.density(at: 300, phase: .quiet), plain)
        XCTAssertGreaterThan(p.density(at: 300, phase: .fortress), plain)
    }

    func testAQuietPhaseIsStillWorthPlaying() {
        // Lower density and easier bricks, not an empty screen - a sparse field would just
        // fly past.
        XCTAssertGreaterThan(progression.density(at: 300, phase: .quiet), 0.1)
    }

    // MARK: - What the bricks are

    func testTheOpeningIsAlmostAllPlainBricks() {
        let weights = progression.behaviourWeights(at: 0)
        let standard = weights.first { $0.0 == .standard }?.1 ?? 0
        let rest = weights.filter { $0.0 != .standard }.reduce(0) { $0 + $1.1 }
        XCTAssertGreaterThan(standard, rest*5)
    }

    func testByAThousandMetresAPlainBrickIsTheMinority() {
        let weights = progression.behaviourWeights(at: 1000)
        let standard = weights.first { $0.0 == .standard }?.1 ?? 0
        let rest = weights.filter { $0.0 != .standard }.reduce(0) { $0 + $1.1 }
        XCTAssertLessThan(standard, rest)
    }

    func testTheVeryFirstScreenIsPlainAndSparse() {
        // The only screen somebody sees before deciding what this mode is. It has to read as
        // an invitation, not a wall - so no styles at all, ordinary bricks only, and thinner
        // than the opening proper. Everything starts arriving the moment the height moves.
        let p = progression
        XCTAssertEqual(p.styleChance(at: 0), 0)
        XCTAssertEqual(p.stackChance(at: 0), 0)
        XCTAssertEqual(p.behaviourWeights(at: 0).count, 1)
        XCTAssertEqual(p.behaviourWeights(at: 0).first?.0, .standard)
        XCTAssertLessThan(p.density(at: 0), p.density(at: 1))
        XCTAssertGreaterThan(p.styleChance(at: 30), 0)
    }

    func testEveryBehaviourIsReachableAtEveryDepth() {
        let p = progression
        for height in [50, 500, 1500] {
            for (_, weight) in p.behaviourWeights(at: height) {
                XCTAssertGreaterThan(weight, 0, "at \(height)")
            }
        }
    }

    // MARK: - Phases

    func testTheOpeningOnlyOffersThePlainPhases() {
        // Nothing with a character of its own until a player has seen an ordinary field.
        for phase in EndlessIIPhase.allCases where phase.minimumHeight == 0 {
            XCTAssertTrue([.standard, .quiet].contains(phase), "\(phase)")
        }
    }

    func testBreathersAreTheMostLikelySinglePhase() {
        // Weighted rather than scheduled, so breaks arrive often without being predictable.
        let others = EndlessIIPhase.allCases.filter { $0 != .quiet }
        for phase in others {
            XCTAssertGreaterThanOrEqual(EndlessIIPhase.quiet.weight, phase.weight, "\(phase)")
        }
    }

    func testAPhasePickedIsAlwaysOneAllowedAtThatHeight() {
        let p = progression
        for height in [0, 30, 100, 300, 900] {
            for roll in [0, 3, 17, 61, 250] {
                let phase = p.pickPhase(at: height, roll: { _ in roll })
                XCTAssertLessThanOrEqual(phase.minimumHeight, height, "\(height)/\(roll)")
            }
        }
    }

    // MARK: - Motion

    func testMovingPartsStartSlowAndSpeedUp() {
        let p = progression
        XCTAssertLessThan(p.motionRate(at: 0), 1.0)
        XCTAssertLessThan(p.motionRate(at: 0), p.motionRate(at: 500))
        XCTAssertGreaterThan(p.motionRate(at: 1000), 1.0)
    }
}

extension EndlessIIProgressionTests {

    // MARK: - Phases that fix what the field is made of

    func testTheUniformPhasesAreTheRarestOnes() {
        // They are the strongest flavour available, and a run that kept serving them would
        // be a run of set pieces rather than a field.
        let uniform = EndlessIIPhase.allCases.filter { $0.isUniform }
        let varied = EndlessIIPhase.allCases.filter { $0.isUniform == false }
        XCTAssertFalse(uniform.isEmpty)
        for one in uniform {
            for other in varied {
                XCTAssertLessThan(one.weight, other.weight, "\(one) vs \(other)")
            }
        }
    }

    func testNoUniformPhaseAppearsInTheOpening() {
        // A player has to know what an ordinary field looks like before one made entirely
        // of one thing means anything.
        for phase in EndlessIIPhase.allCases where phase.isUniform {
            XCTAssertGreaterThan(phase.minimumHeight, 100, "\(phase)")
        }
    }

    func testAMotifWaitsUntilStackingIsFamiliar() {
        // It is two styles on every brick, so it should not be where somebody first meets
        // the idea of two styles at all.
        XCTAssertGreaterThan(EndlessIIPhase.motif.minimumHeight,
                             EndlessIIPhase.monoculture.minimumHeight)
    }

    func testAPhaseOfBigBricksIsThinnerAndOneOfTinyOnesIsDenser() {
        // Same number of cells means something different when the bricks are four times the
        // size, so the density has to move with it.
        XCTAssertLessThan(EndlessIIPhase.giants.densityFactor,
                          EndlessIIPhase.standard.densityFactor)
        XCTAssertGreaterThan(EndlessIIPhase.miniatures.densityFactor,
                             EndlessIIPhase.standard.densityFactor)
    }

    func testEveryPhaseStillHasSomewhereItCanAppear() {
        let p = progression
        for phase in EndlessIIPhase.allCases {
            let allowed = EndlessIIPhase.allCases.filter { phase.minimumHeight >= $0.minimumHeight }
            XCTAssertTrue(allowed.contains(phase), "\(phase)")
            XCTAssertGreaterThan(phase.weight, 0, "\(phase)")
            _ = p.pickPhase(at: phase.minimumHeight)
        }
    }
}
