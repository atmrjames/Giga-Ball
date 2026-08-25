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
import SpriteKit
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
        // The deep end is exact. The opening end is a floor rather than an exact value,
        // because the ramp is eased rather than linear - it lifts away from the opening figure
        // immediately, which is the whole point of easing it. What must hold is that it never
        // starts *below* what was asked for and never overshoots what it is heading to.
        let p = progression

        XCTAssertGreaterThanOrEqual(p.styleChance(at: 1), EndlessIIProgression.openingStyleChance)
        XCTAssertLessThan(p.styleChance(at: 1), EndlessIIProgression.deepStyleChance)
        XCTAssertEqual(p.styleChance(at: 10_000), EndlessIIProgression.deepStyleChance)

        XCTAssertGreaterThanOrEqual(p.stackChance(at: 1), EndlessIIProgression.openingStackChance)
        XCTAssertLessThan(p.stackChance(at: 1), EndlessIIProgression.deepStackChance)
        XCTAssertEqual(p.stackChance(at: 10_000), EndlessIIProgression.deepStackChance)
    }

    func testMostOfTheVarietyArrivesEarly() {
        // The reason for easing the ramp. A straight line to a thousand metres put a hundred
        // metres a tenth of the way there, and a run that is still nine parts plain bricks by
        // then has shown a player almost nothing of the mode - which is exactly what §2 says
        // rarity must not do.
        let p = progression
        let opening = EndlessIIProgression.openingStyleChance
        let deep = EndlessIIProgression.deepStyleChance
        let atHundred = Double(p.styleChance(at: 100) - opening)/Double(deep - opening)

        XCTAssertGreaterThan(atHundred, 0.25, "a hundred metres should be well on its way")
        XCTAssertLessThan(atHundred, 0.6, "and still leave the climb somewhere to go")
    }

    func testAnOrdinaryBrickIsNotMostOfTheFieldByAHundredMetres() {
        // The play-test report: by 100m the majority of bricks were still plain white
        let p = progression
        let weights = p.behaviourWeights(at: 100)
        let total = weights.reduce(0) { $0 + $1.1 }
        let standard = weights.first { $0.0 == .standard }?.1 ?? 0

        XCTAssertLessThan(Double(standard)/Double(total), 0.7)
        XCTAssertGreaterThan(Double(standard)/Double(total), 0.4,
                             "still the commonest brick, though - it is the baseline")
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

    func testTheOpeningSetIsInPlayAtOnceAndTheRestComeInInOrder() {
        // Round 192: a run opens with several styles already in play, not one, and how many
        // varies per run. Everything after that set still arrives strictly in turn.
        let p = progression
        for index in 0..<p.openingStyles {
            XCTAssertEqual(p.introductionHeight(of: order[index]), 0,
                           "\(order[index]) is in the opening set")
        }
        for index in (p.openingStyles + 1)..<order.count {
            XCTAssertGreaterThan(p.introductionHeight(of: order[index]),
                                 p.introductionHeight(of: order[index - 1]))
        }
    }

    // MARK: - What differs between runs (round 192)
    //
    // James: "Each game, what is and isn't available at the start is different so each game
    // feels very unique... The number of items available at the start should also differ
    // between games, and the timing and speed at which they are introduced should also
    // differ."

    private func drawnRuns(_ count: Int = 60) -> [EndlessIIProgression] {
        (0..<count).map { _ in EndlessIIProgression.make(powerUps: 40) }
    }

    func testTwoRunsOpenWithDifferentAmountsAndFillUpAtDifferentSpeeds() {
        let runs = drawnRuns()
        XCTAssertGreaterThan(Set(runs.map(\.openingStyles)).count, 1,
                             "every run opening with the same number of styles is the "
                             + "staleness this is meant to fix")
        XCTAssertGreaterThan(Set(runs.map(\.openingPowerUps)).count, 1)
        XCTAssertGreaterThan(Set(runs.map(\.styleSpacing)).count, 1,
                             "the speed things arrive at has to differ too")
        XCTAssertGreaterThan(Set(runs.map(\.powerUpSpacing)).count, 1)
    }

    func testEveryRunStaysInsideTheRangesTheDesignAllows() {
        for run in drawnRuns() {
            XCTAssertTrue(EndlessIIProgression.openingStyleRange.contains(run.openingStyles))
            XCTAssertTrue(EndlessIIProgression.openingPowerUpRange.contains(run.openingPowerUps))
            XCTAssertTrue(EndlessIIProgression.styleSpacingRange.contains(run.styleSpacing))
            XCTAssertTrue(EndlessIIProgression.powerUpSpacingRange.contains(run.powerUpSpacing))
            for tweak in run.rarityTweak {
                XCTAssertTrue(EndlessIIProgression.rarityTweakRange.contains(tweak))
            }
        }
    }

    /// **The one rule the rarity tweak must never break.**
    ///
    /// James: "Although a generally rare power up shouldn't all of a sudden become the most
    /// common one." The luckiest a run can be to a rare one still has to leave it rarer than
    /// the unluckiest a run can be to a common one - which is a property of the range, so it
    /// is checked as one rather than by sampling and hoping.
    func testTheLuckiestRareStaysRarerThanTheUnluckiestCommon() {
        let most = EndlessIIProgression.rarityTweakRange.upperBound
        let least = EndlessIIProgression.rarityTweakRange.lowerBound
        let widestSwing = most/least

        // The authored tiers, as the allocation tables actually space them
        let rare = 2.0, uncommon = 8.0, common = 30.0
        XCTAssertLessThan(rare*most, uncommon*least, "a Rare must not out-draw an Uncommon")
        XCTAssertLessThan(uncommon*most, common*least, "nor an Uncommon a Common")
        XCTAssertLessThan(widestSwing, 2.0,
                          "a swing wider than the gap between neighbouring tiers is a "
                          + "reweighting rather than a tweak")
    }

    func testAHeldBackPowerUpIsStillRarerThanAnIntroducedOneHoweverTheTweakFalls() {
        // The tweak multiplies the introduction damping rather than replacing it, so the
        // damping cannot be cancelled out by a lucky draw
        let most = EndlessIIProgression.rarityTweakRange.upperBound
        let least = EndlessIIProgression.rarityTweakRange.lowerBound
        XCTAssertLessThan(EndlessIIProgression.powerUpEarlyScale*most, 1*least,
                          "being introduced has to beat being lucky")
    }

    func testTheOpeningPowerUpsAreAvailableFromTheFirstMetre() {
        let run = EndlessIIProgression.make(powerUps: 40)
        for place in 0..<run.openingPowerUps {
            let index = run.powerUpOrder[place]
            XCTAssertEqual(run.powerUpIntroductionHeight(of: index), 0)
            XCTAssertEqual(run.powerUpWeightScale(for: index, at: 0), run.tweak(for: index),
                           accuracy: 0.0001, "in play, at this run's own weighting")
        }
    }

    func testAPowerUpAddedSinceTheSaveWasWrittenCountsAsAvailable() {
        // A schedule restored from an older save has a shorter order. The safe answer for an
        // index it has never heard of is "in play" - the opposite of held back, which would
        // hide a power-up the player already owns
        var run = EndlessIIProgression.make(powerUps: 10)
        run.rarityTweak = []
        XCTAssertEqual(run.powerUpIntroductionHeight(of: 99), 0)
        XCTAssertEqual(run.tweak(for: 99), 1)
        XCTAssertEqual(run.powerUpWeightScale(for: 99, at: 0), 1, accuracy: 0.0001)
    }

    // MARK: - Introductions quicken with depth (round 193)

    /// James: "new item introduction should also rise with height."
    func testThingsArriveMoreOftenTheDeeperARunGets() {
        let spacing = 35
        var gaps: [Int] = []
        var previous = 0
        for step in 1...12 {
            let here = EndlessIIProgression.introductionDistance(steps: step, spacing: spacing)
            gaps.append(here - previous)
            previous = here
        }
        for index in 1..<gaps.count {
            XCTAssertLessThanOrEqual(gaps[index], gaps[index - 1],
                                     "gap \(index) is wider than the one before it, so the "
                                     + "rate of new things is falling rather than rising")
        }
        XCTAssertLessThan(gaps.last!, gaps.first!,
                          "and over a run it has to actually shorten, not merely not grow")
    }

    func testTheGapsNeverShrinkToAFlood() {
        let spacing = 35
        let floor = Int((Double(spacing)*EndlessIIProgression.shortestGapShare).rounded(.down))
        var previous = 0
        for step in 1...200 {
            let here = EndlessIIProgression.introductionDistance(steps: step, spacing: spacing)
            XCTAssertGreaterThanOrEqual(here - previous, floor,
                                        "a gap under the floor is something new every few "
                                        + "metres, which is a flood rather than a rise")
            previous = here
        }
    }

    func testIntroductionHeightsAlwaysClimb() {
        // Whatever the quickening does, the n-th thing must never arrive before the n-1th
        for spacing in [9, 14, 24, 35, 50] {
            var previous = -1
            for step in 0...30 {
                let here = EndlessIIProgression.introductionDistance(steps: step,
                                                                     spacing: spacing)
                XCTAssertGreaterThan(here, previous, "spacing \(spacing), step \(step)")
                previous = here
            }
        }
    }

    // MARK: - Sequences join the schedule (round 193)

    /// James listed what should be held back: "brick types and power ups and **brick
    /// sequences** and combinations of things."
    func testTwoRunsMeetDifferentShapesAtTheSameDepth() {
        let runs = (0..<40).map { _ in EndlessIIProgression.make(powerUps: 40) }
        let atFifty = runs.map { Set($0.setRows(at: 50).map(\.name)) }
        XCTAssertGreaterThan(Set(atFifty.map { $0.sorted().joined() }).count, 1,
                             "every run meeting the same set rows at 50m is the staleness "
                             + "this is meant to fix")

        let phasesAtFifty = runs.map { run in
            Set(EndlessIIPhase.allCases.filter { 50 >= run.phaseAvailableHeight(of: $0) }
                .map(\.rawValue))
        }
        XCTAssertGreaterThan(Set(phasesAtFifty.map { $0.sorted().joined() }).count, 1)
    }

    /// **The one rule the sequence schedule must never break.**
    ///
    /// An authored minimum height is a design statement about what a shape does to a field.
    /// The schedule may push something later; it may never bring it forward.
    func testAnAuthoredGateIsNeverUndercutByALuckyShuffle() {
        for run in (0..<40).map({ _ in EndlessIIProgression.make(powerUps: 40) }) {
            for index in EndlessIISetRow.all.indices {
                let row = EndlessIISetRow.all[index]
                XCTAssertGreaterThanOrEqual(run.setRowAvailableHeight(of: index),
                                            row.minimumHeight,
                                            "\(row.name) is gated at \(row.minimumHeight)m "
                                            + "for a reason and a shuffle must not move it up")
            }
            for phase in EndlessIIPhase.allCases {
                XCTAssertGreaterThanOrEqual(run.phaseAvailableHeight(of: phase),
                                            phase.minimumHeight, "\(phase)")
            }
        }
    }

    func testEveryShapeIsStillReachableEventually() {
        // Held back is not locked out: a deep run has to be able to meet all of them, or the
        // schedule has quietly deleted content
        for run in (0..<10).map({ _ in EndlessIIProgression.make(powerUps: 40) }) {
            XCTAssertEqual(run.setRows(at: 10_000).count, EndlessIISetRow.all.count)
            let phases = EndlessIIPhase.allCases.filter { 10_000 >= run.phaseAvailableHeight(of: $0) }
            XCTAssertEqual(phases.count, EndlessIIPhase.allCases.count)
        }
    }

    /// James: "The standard brick types and power ups are always available."
    ///
    /// This caught a real flaw before it shipped. With the opening set shuffled, a run could
    /// draw an opening whose every phase was gated above zero by its authored minimum - so
    /// nothing at all was available at the start and `pickPhase` fell back to Standard on
    /// every draw, silently. Standard is the baseline mix rather than a set piece, so it is
    /// exempt from the schedule outright.
    func testStandardIsAlwaysAvailableAndSoIsSomethingElseToDrawWith() {
        for run in (0..<40).map({ _ in EndlessIIProgression.make(powerUps: 40) }) {
            XCTAssertEqual(run.phaseAvailableHeight(of: .standard), 0)
            let openAtZero = EndlessIIPhase.allCases.filter { 0 >= run.phaseAvailableHeight(of: $0) }
            XCTAssertFalse(openAtZero.isEmpty, "a run has to open with some phase available")
        }
    }

    func testTheStandardPowerUpsAreNeverHeldBack() {
        // The other half of the same rule: the vocabulary a player already knows from the
        // original game is the floor a run is playable on before it has been taught anything
        for run in (0..<20).map({ _ in EndlessIIProgression.make(powerUps: 63) }) {
            for index in 0..<LevelPackSetup.firstEndlessIIPowerUp {
                XCTAssertEqual(run.powerUpIntroductionHeight(of: index), 0,
                               "power-up \(index) is one of the standard ones")
            }
        }
    }

    func testASetRowCatalogueChangeCannotHideAShape() {
        // A schedule restored from an older save has a shorter order. An index it has never
        // heard of falls back to the authored gate - available, not hidden
        var run = EndlessIIProgression.make(powerUps: 40)
        run.setRowOrder = []
        run.releaseOrder = run.releaseOrder?.filter {
            if case .setRow = $0 { return false } else { return true }
        }
        // Both lists, since round 258: a schedule names its set rows in the release queue now
        // and the old per-kind order is only read by a run saved before that. "Has never heard
        // of this index" means neither knows it
        for index in EndlessIISetRow.all.indices {
            XCTAssertEqual(run.setRowAvailableHeight(of: index),
                           EndlessIISetRow.all[index].minimumHeight)
        }
    }

    // MARK: - The power-up brick kindness gate (round 202)

    /// James: "good power ups only, then introduce bad power ups higher up, but not really
    /// bad ones, then worse ones can be added even higher up."
    func testABrickHoldsKinderGiftsThanTheSkyDrops() {
        var run = EndlessIIProgression.make(powerUps: 64)
        run.brickBadFromHeight = 80
        run.brickDisastrousFromHeight = 200

        XCTAssertTrue(run.brickMayHold(20, at: 0), "Giga-Ball is good, and good is always in")
        XCTAssertTrue(run.brickMayHold(3, at: 0), "Fast Ball is a nuisance, not a run-turner")
        XCTAssertFalse(run.brickMayHold(54, at: 79), "Drift is bad, and 79m is before its day")
        XCTAssertTrue(run.brickMayHold(54, at: 80))
        XCTAssertFalse(run.brickMayHold(38, at: 199),
                       "Reversed Controls is disastrous - a brick's gift goes off in your "
                       + "hand, so it waits longest")
        XCTAssertTrue(run.brickMayHold(38, at: 200))
    }

    func testTheDisastrousTierCanNeverArriveBeforeTheBadOne() {
        // Whatever the two draws land on - the ranges overlap nothing today, but a rule the
        // numbers happen to satisfy is not a rule
        var run = EndlessIIProgression.make(powerUps: 64)
        run.brickBadFromHeight = 300
        run.brickDisastrousFromHeight = 100
        XCTAssertFalse(run.brickMayHold(38, at: 250),
                       "disastrous waits for bad even when its own height has passed")
        XCTAssertTrue(run.brickMayHold(38, at: 300))
    }

    func testTheGateHeightsDifferBetweenRunsAndStayInRange() {
        let runs = (0..<50).map { _ in EndlessIIProgression.make(powerUps: 64) }
        XCTAssertGreaterThan(Set(runs.map(\.badPowerUpBricksFrom)).count, 1,
                             "every run gating at the same height is the staleness the "
                             + "note is aimed at")
        XCTAssertGreaterThan(Set(runs.map(\.disastrousPowerUpBricksFrom)).count, 1)
        for run in runs {
            XCTAssertTrue(EndlessIIProgression.brickBadRange.contains(run.badPowerUpBricksFrom))
            XCTAssertTrue(EndlessIIProgression.brickDisastrousRange
                .contains(run.disastrousPowerUpBricksFrom))
        }
    }

    func testAScheduleSavedBeforeTheGateStillDecodesAndGates() throws {
        // Round 192's saves carry no gate heights. Optionals decode as nil, and nil reads
        // as the range midpoints - close to what those runs would have drawn
        var old = EndlessIIProgression.make(powerUps: 64)
        old.brickBadFromHeight = nil
        old.brickDisastrousFromHeight = nil
        let data = try JSONEncoder().encode(old)
        let back = try JSONDecoder().decode(EndlessIIProgression.self, from: data)

        XCTAssertEqual(back.badPowerUpBricksFrom,
                       EndlessIIProgression.midpoint(of: EndlessIIProgression.brickBadRange))
        XCTAssertFalse(back.brickMayHold(38, at: 0), "and the gate still stands")
    }

    func testEverySeverityEntryNamesARealPowerUp() {
        let count = LevelPackSetup().powerUpNameArray.count
        for index in EndlessIIProgression.powerUpSeverity.keys {
            XCTAssertTrue((0..<count).contains(index),
                          "\(index) is not a power-up - a stale entry gates nothing")
        }
    }

    func testBothDriftsCarryTheSameSeverity() {
        // One power-up in two directions must not be kinder one way round
        XCTAssertEqual(EndlessIIProgression.powerUpSeverity[54],
                       EndlessIIProgression.powerUpSeverity[63])
    }

    func testAScheduleSurvivesBeingWrittenAndReadBack() {
        // It rides in the save, so it has to round-trip exactly: a resumed run that redrew
        // it would be stocked differently from the one the player left
        let run = EndlessIIProgression.make(powerUps: 40)
        let data = try! JSONEncoder().encode(run)
        let back = try! JSONDecoder().decode(EndlessIIProgression.self, from: data)
        XCTAssertEqual(back, run)
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

extension EndlessIIProgressionTests {

    // MARK: - The power-up schedule

    /// A schedule over Mayhem's own power-ups.
    ///
    /// **From `firstEndlessIIPowerUp` up**, because round 193 exempted the standard ones on
    /// James's rule that they are always available - a schedule written over indices 0..<28
    /// is now a schedule over things that are never held back, which would make every test
    /// below quietly vacuous.
    private var mayhemsOwn: Range<Int> {
        LevelPackSetup.firstEndlessIIPowerUp..<LevelPackSetup().powerUpNameArray.count
    }

    private var withPowerUps: EndlessIIProgression {
        EndlessIIProgression(introductionOrder: order, powerUpOrder: Array(mayhemsOwn))
    }

    func testNoPowerUpIsEverLockedOut() {
        // The same rule the styles follow: being introduced late makes something unlikely,
        // never impossible. Somebody's first run should still be able to surprise them.
        let p = withPowerUps
        for index in mayhemsOwn {
            XCTAssertGreaterThan(p.powerUpWeightScale(for: index, at: 0), 0, "\(index)")
        }
    }

    func testRarityIsRestoredRatherThanReplaced() {
        // Being introduced does not make something common - it gives back the weight it was
        // authored with, whatever that was.
        let p = withPowerUps
        let last = mayhemsOwn.upperBound - 1
        let deep = p.powerUpIntroductionHeight(of: last)
        XCTAssertEqual(p.powerUpWeightScale(for: last, at: deep), 1, accuracy: 0.0001)
        XCTAssertEqual(p.powerUpWeightScale(for: last, at: deep + 500), 1, accuracy: 0.0001)
    }

    func testAnUnintroducedPowerUpIsDampedButPresent() {
        let p = withPowerUps
        let last = mayhemsOwn.upperBound - 1
        let scale = p.powerUpWeightScale(for: last, at: 0)
        XCTAssertLessThan(scale, 1)
        XCTAssertGreaterThan(scale, 0)
    }

    func testTheFirstPowerUpIsAvailableImmediately() {
        XCTAssertEqual(withPowerUps.powerUpIntroductionHeight(of: mayhemsOwn.lowerBound), 0)
    }

    func testTheWholeSetIsIntroducedWithinAReasonableRun() {
        // All of them should be in play well before the ramp ends, or the second half of a
        // long run would still be meeting basics.
        let p = withPowerUps
        let latest = mayhemsOwn.map { p.powerUpIntroductionHeight(of: $0) }.max() ?? 0
        XCTAssertLessThan(latest, EndlessIIProgression.rampMetres)
    }

    func testThePowerUpOrderDiffersBetweenRuns() {
        let first = EndlessIIProgression.make().powerUpOrder
        let anyDifferent = (0..<20).contains { _ in
            EndlessIIProgression.make().powerUpOrder != first
        }
        XCTAssertTrue(anyDifferent)
    }

    func testEveryPowerUpAppearsInTheOrderExactlyOnce() {
        // Derived from the array the drop actually reads, not written out - a new power-up
        // that is missing from this shuffle is introduced at 0m, the opposite of introduced
        let expected = LevelPackSetup().powerUpNameArray.count
        let made = EndlessIIProgression.make().powerUpOrder
        XCTAssertEqual(made.count, expected)
        XCTAssertEqual(Set(made).count, expected)
    }

    func testAnIndexOutsideTheOrderIsTreatedAsAvailable() {
        // If the probability array ever grows past what the schedule was built for, the extra
        // entries must keep working rather than silently vanishing from the draw.
        XCTAssertEqual(withPowerUps.powerUpWeightScale(for: 999, at: 0), 1, accuracy: 0.0001)
    }
}

/// Density rising in steps behind the introductions.
///
/// James, round 212: "Density should increase with height in general, but new things should
/// come first. So new things added -> increase density -> new things added -> increase
/// density, and so on. Of course there should be randomised aspects to how dense, when it is
/// increased, how it overlaps and interweaves with new items being added."
///
/// The two halves of that are the thing to pin: the ordering (a new style is met before the
/// field thickens around it) and the coupling (a run that introduces quickly also thickens
/// quickly), with the randomness never carrying either of them away.
final class EndlessIIDensityStepTests: XCTestCase {

    func testDensityStillStartsThinAndReachesItsCap() {
        let run = EndlessIIProgression.make()
        XCTAssertEqual(run.density(at: 0), EndlessIIProgression.firstScreenDensity,
                       accuracy: 0.0001)
        XCTAssertEqual(run.density(at: EndlessIIProgression.densityCapMetres),
                       EndlessIIProgression.cappedDensity, accuracy: 0.0001)
        XCTAssertEqual(run.density(at: 4000), EndlessIIProgression.cappedDensity,
                       accuracy: 0.0001, "past the cap what changes is what the bricks are")
    }

    func testItNeverGoesBackwards() {
        for _ in 0..<20 {
            let run = EndlessIIProgression.make()
            var last = 0.0
            for height in stride(from: 0, through: 600, by: 1) {
                let now = run.density(at: height)
                XCTAssertGreaterThanOrEqual(now, last - 0.0001,
                                            "the field thinned out at \(height)m")
                last = now
            }
        }
    }

    /// **The new thing comes first.** At the metre a style is introduced, the field must be no
    /// fuller than it was the metre before - the style arrives into the field it was drawn
    /// for, and the thickening follows once the player has met it.
    func testAStyleIsMetBeforeTheFieldThickensAroundIt() {
        for _ in 0..<20 {
            let run = EndlessIIProgression.make()
            let steps = Set(run.densityStepHeights())
            for style in run.introductionOrder {
                let arrives = run.introductionHeight(of: style)
                guard arrives > 0, arrives < EndlessIIProgression.densityCapMetres else { continue }
                XCTAssertFalse(steps.contains(arrives),
                               "density stepped on the very metre \(style) arrived")
            }
        }
    }

    /// **The coupling.** A run that introduces its styles quickly should also do its
    /// thickening early - that is what "keyed to the schedule" buys over a second ramp that
    /// merely looks similar.
    func testAQuickerRunThickensEarlier() {
        var quick = EndlessIIProgression.make()
        quick.elementSpacing = EndlessIIProgression.elementSpacingRange.lowerBound
        var slow = quick
        slow.elementSpacing = EndlessIIProgression.elementSpacingRange.upperBound
        // `elementSpacing` rather than `styleSpacing` since round 258: one queue for every
        // kind means one number saying how fast a run meets things, and the old per-kind
        // spacings are only read by a run saved before the queue existed

        let atHalfway = EndlessIIProgression.densityCapMetres/2
        XCTAssertGreaterThan(quick.density(at: atHalfway), slow.density(at: atHalfway),
                             "the run meeting more new things is not the fuller one")
    }

    /// The randomness moves where a run does its thickening, never where it ends up.
    func testTheTweaksNeverChangeWhereARunFinishes() {
        for _ in 0..<20 {
            let run = EndlessIIProgression.make()
            XCTAssertEqual(run.densityProgress(at: EndlessIIProgression.densityCapMetres), 1,
                           accuracy: 0.0001)
        }
    }

    func testTwoRunsAreRarelyAsFullAsEachOther() {
        let runs = (0..<12).map { _ in EndlessIIProgression.make() }
        let readings = Set(runs.map { String(format: "%.4f", $0.density(at: 200)) })
        XCTAssertGreaterThan(readings.count, 1, "every run thickens on the same metres")
    }
}

/// The two phases §6.2 described and nobody had built.
///
/// Both are a stretch of ordinary field with one thing turned up, which is the cheapest kind of
/// phase there is - and the kind most easily got wrong in a way nobody sees, because a phase
/// that never fires and a phase that fires and does nothing look identical from outside.
final class WindfallAndStaticPhaseTests: XCTestCase {

    /// A Windfall halves the gap between drops, and nothing else does.
    ///
    /// "Normal density, noticeably more power-ups" (§6.2). The lever is the *gap* rather than
    /// the table: it makes whatever the level allocated rainier, instead of overruling what is
    /// in it - so a pack with its own odd weighting stays that pack, only wetter.
    func testOnlyAWindfallChangesTheDropRate() {
        for phase in EndlessIIPhase.allCases {
            let expected = phase == .windfall ? 0.5 : 1.0
            XCTAssertEqual(phase.powerUpGapFactor, expected, "\(phase)")
        }
    }

    /// And it does not change the density, which is the half of it that stays ordinary.
    func testAWindfallIsAnOrdinaryFieldWithMoreFallingOutOfIt() {
        XCTAssertEqual(EndlessIIPhase.windfall.densityFactor,
                       EndlessIIPhase.standard.densityFactor,
                       "the *density* is normal - it is the drops that are not")
        XCTAssertTrue(EndlessIIPhase.windfall.favours.isEmpty,
                      "and it leans on no style, or it would be two phases at once")
    }

    /// A Static phase is the only one whose flashers blink together.
    ///
    /// Everywhere else they are staggered on purpose - "or a whole row would breathe in
    /// unison" - and this is that sentence turned round.
    func testOnlyAStaticPhaseFlashesInStep() {
        for phase in EndlessIIPhase.allCases {
            XCTAssertEqual(phase.flashesInStep, phase == .static, "\(phase)")
        }
        XCTAssertEqual(EndlessIIPhase.static.favours, [.flashing],
                       "and it has to actually produce flashers to be about them")
    }

    /// Every Flashing brick built during a Static phase agrees with the others.
    ///
    /// All three numbers, not just the start: a field that begins in step and holds each brick
    /// solid for a different length drifts apart within a few blinks, which is a phase that
    /// looks right for two seconds.
    func testAStaticPhaseGivesEveryFlasherTheSameRhythm() {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.endlessIIPhase = .static

        for index in 0..<8 {
            let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                     size: CGSize(width: 40, height: 20))
            brick.position = CGPoint(x: CGFloat(index)*40, y: 100)
            brick.name = BrickCategoryName
            scene.addChild(brick)
            scene.makeFlashing(brick)
        }

        let phases = Set(scene.endlessIIFlashers.map(\.phase))
        let solid = Set(scene.endlessIIFlashers.map(\.solidFor))
        let passable = Set(scene.endlessIIFlashers.map(\.passableFor))
        XCTAssertEqual(phases.count, 1, "they should start together")
        XCTAssertEqual(solid.count, 1, "and stay solid for as long as each other")
        XCTAssertEqual(passable.count, 1, "and be passable for as long as each other")
    }

    /// And an ordinary phase still staggers them, or this is a change to every field.
    func testAnOrdinaryPhaseStillStaggersItsFlashers() {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.gameMode = .endlessII
        scene.endlessIIPhase = .standard

        for index in 0..<24 {
            let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                     size: CGSize(width: 40, height: 20))
            brick.position = CGPoint(x: CGFloat(index)*10, y: 100)
            brick.name = BrickCategoryName
            scene.addChild(brick)
            scene.makeFlashing(brick)
        }
        XCTAssertGreaterThan(Set(scene.endlessIIFlashers.map(\.phase)).count, 1,
                             "a whole row breathing in unison is what the stagger prevents")
    }

    /// Both are gated where §6.2 puts them, and neither is gated out of existence.
    ///
    /// A phase that cannot be drawn looks exactly like a phase that is very rare, which is the
    /// trap §8.6 keeps a whole section for.
    func testBothArrivePartWayThroughARunRatherThanNever() {
        for phase in [EndlessIIPhase.windfall, .static] {
            XCTAssertGreaterThan(phase.minimumHeight, 0, "\(phase) is not an opening phase")
            XCTAssertLessThan(phase.minimumHeight, 400,
                              "\(phase) has to be reachable in a run somebody actually plays")
            XCTAssertGreaterThan(phase.weight, 0, "\(phase) must be offered at all")
        }
        XCTAssertLessThan(EndlessIIPhase.windfall.minimumHeight,
                          EndlessIIPhase.static.minimumHeight,
                          "§6.2 gates Static High and Windfall not at all")
    }
}
