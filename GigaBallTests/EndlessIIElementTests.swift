//
//  EndlessIIElementTests.swift
//  GigaBallTests
//
//  One queue for everything new, and the two daily twists that empty it at once.
//

import XCTest
@testable import Giga_Ball

final class EndlessIIElementTests: XCTestCase {

    private func schedule() -> EndlessIIProgression { EndlessIIProgression.make() }

    // MARK: - One queue

    /// **The five clocks are one clock.**
    ///
    /// James, round 258: "In Endless Mayhem don't introduce new elements too quickly. Perhaps a
    /// new element every game view of bricks, so 22m."
    ///
    /// Every kind of new thing already arrived on a schedule that was sensible for itself - a
    /// style every 35m, a power-up every 14m, a set row every 30m, a phase every 30m - and
    /// nobody had added them up. A player meets all of them at once, so something new arrived
    /// about every seven metres. This is the sum being checked rather than the parts.
    func testNothingNewArrivesFasterThanAScreenfulUntilTheQuickeningStarts() {
        let schedule = schedule()
        let queue = try! XCTUnwrap(schedule.releaseOrder)
        XCTAssertFalse(queue.isEmpty)

        let first = schedule.arrivalHeight(of: queue[0])
        let second = schedule.arrivalHeight(of: queue[1])
        XCTAssertGreaterThanOrEqual(second - first,
                                    Int(Double(schedule.elementSpacing)*0.9),
                                    "the first gap is a screenful, before the quickening has "
                                    + "had a chance to shorten anything")
        XCTAssertGreaterThanOrEqual(first, Int(Double(schedule.elementSpacing)*0.9),
                                    "and nothing arrives before the first screen has gone")
    }

    /// The queue is one queue: heights rise along it and never repeat a metre backwards.
    func testTheQueueArrivesInOrder() {
        let schedule = schedule()
        let queue = try! XCTUnwrap(schedule.releaseOrder)
        var last = 0
        for element in queue {
            let height = schedule.arrivalHeight(of: element)
            XCTAssertGreaterThanOrEqual(height, last, "\(element) arrives before its turn")
            last = height
        }
    }

    /// Every kind is in it, which is the point - "that may be a new brick type, a new
    /// power-up, and new brick shape" is one queue rather than three.
    func testEveryKindOfElementIsInTheOneQueue() {
        let queue = try! XCTUnwrap(schedule().releaseOrder)
        var kinds: Set<String> = []
        for element in queue {
            switch element {
            case .style: kinds.insert("style")
            case .powerUp: kinds.insert("powerUp")
            case .multiHit: kinds.insert("multiHit")
            case .setRow: kinds.insert("setRow")
            case .phase: kinds.insert("phase")
            }
        }
        XCTAssertEqual(kinds, ["style", "powerUp", "multiHit", "setRow", "phase"])
    }

    /// And they are shuffled together rather than queued kind by kind.
    ///
    /// Five blocks in a row would still be one queue and would still pace correctly, and would
    /// mean a run that met nothing but power-ups for two hundred metres.
    func testTheKindsAreShuffledTogetherAndNotStacked() {
        var changes = 0
        let queue = try! XCTUnwrap(schedule().releaseOrder)
        for (a, b) in zip(queue, queue.dropFirst()) where kind(a) != kind(b) { changes += 1 }
        XCTAssertGreaterThan(changes, queue.count/4,
                             "the kinds come in blocks, so a run meets one kind at a time")
    }

    private func kind(_ element: EndlessIIElement) -> String {
        switch element {
        case .style: return "style"
        case .powerUp: return "powerUp"
        case .multiHit: return "multiHit"
        case .setRow: return "setRow"
        case .phase: return "phase"
        }
    }

    // MARK: - What is never held back

    /// "All the classic game mode power-ups... always available from the start."
    func testTheClassicPowerUpsAreNeverQueued() {
        let schedule = schedule()
        for index in 0..<LevelPackSetup.firstEndlessIIPowerUp {
            XCTAssertEqual(schedule.powerUpIntroductionHeight(of: index), 0, "power-up \(index)")
            XCTAssertFalse(schedule.releaseOrder?.contains(.powerUp(index)) ?? false,
                           "power-up \(index) is one the player already knows")
        }
    }

    /// "The standard brick type" - and the two-hit multi-hit brick, which is what Mayhem's
    /// multi-hit brick has always been.
    func testTheOpeningBricksAreNotElements() {
        let queue = try! XCTUnwrap(schedule().releaseOrder)
        XCTAssertFalse(queue.contains(.multiHit(hits: 2)),
                       "two hits is what a Mayhem multi-hit brick already was")
        XCTAssertTrue(queue.contains(.multiHit(hits: 3)))
        XCTAssertTrue(queue.contains(.multiHit(hits: 4)))
    }

    // MARK: - A run saved before this

    /// A schedule with no queue keeps the five-clock arithmetic it was given.
    ///
    /// A schedule is a promise made to a run in progress. Rewriting it under a player mid-run
    /// would move things they had already been shown, which is round 150's lesson at the level
    /// of the rules rather than the bricks.
    func testARunSavedBeforeTheQueueKeepsItsOwnSchedule() {
        var old = schedule()
        old.releaseOrder = nil

        let style = old.introductionOrder[old.openingStyles]
        XCTAssertEqual(old.introductionHeight(of: style),
                       EndlessIIProgression.introductionDistance(steps: 1,
                                                                 spacing: old.styleSpacing))
    }

    // MARK: - The daily is the same day for everybody

    /// **Two players on the same day meet the same elements at the same depths.**
    ///
    /// James, round 258: "Is there a way to make sure the endless mayhem in the daily challenge
    /// is still random for everyone, but the element introduction for that game's day is
    /// similar, so the challenge for everyone is similar so the leaderboard is fair?"
    ///
    /// The two halves were already separate, which is the whole reason the answer is short.
    /// What a run *knows* is the schedule; what a run *is* is the field, rolled brick by brick
    /// as it descends. Seeding the schedule from the date makes everybody's day the same shape
    /// without touching a single roll the field makes.
    func testEveryonePlayingADayGetsTheSameSchedule() {
        var first = DailySeededGenerator(seed: DailyDay.seed(forKey: "2026-12-25") &+ 0xE2E2)
        var second = DailySeededGenerator(seed: DailyDay.seed(forKey: "2026-12-25") &+ 0xE2E2)
        XCTAssertEqual(EndlessIIProgression.make(using: &first),
                       EndlessIIProgression.make(using: &second))
    }

    /// And a different day is a different one, or the daily would be the same puzzle for ever.
    func testADifferentDayIsADifferentSchedule() {
        var boxing = DailySeededGenerator(seed: DailyDay.seed(forKey: "2026-12-26") &+ 0xE2E2)
        var christmas = DailySeededGenerator(seed: DailyDay.seed(forKey: "2026-12-25") &+ 0xE2E2)
        XCTAssertNotEqual(EndlessIIProgression.make(using: &boxing),
                          EndlessIIProgression.make(using: &christmas))
    }

    /// An ordinary run is still its own, which is what the mode is for.
    func testAnOrdinaryRunIsStillItsOwn() {
        XCTAssertNotEqual(EndlessIIProgression.make(), EndlessIIProgression.make())
    }

    // MARK: - The two daily twists

    /// Full Deck: "All elements in endless mayhem are immediately introduced - rarity is still
    /// respected, density still ramps."
    func testFullDeckOpensTheWholeQueueAndLeavesRarityAlone() {
        var schedule = schedule()
        schedule.everythingAtOnce = true

        for element in try! XCTUnwrap(schedule.releaseOrder) {
            XCTAssertEqual(schedule.arrivalHeight(of: element), 0, "\(element)")
        }

        let weights = schedule.behaviourWeights(at: 300)
        XCTAssertNotEqual(weights.map(\.1), Array(repeating: weights[0].1, count: weights.count),
                          "rarity is still respected, so the mix is still a mix")
    }

    /// Level Pegging: "All elements are immediately introduced and all elements have equal
    /// rarity."
    func testLevelPeggingLevelsTheOddsAsWell() {
        var schedule = schedule()
        schedule.everythingAtOnce = true
        schedule.flatRarity = true

        let weights = schedule.behaviourWeights(at: 300).map(\.1)
        XCTAssertEqual(Set(weights).count, 1, "every brick behaviour as likely as every other")

        let styles = EndlessIIStyle.allCases.map { schedule.weight(for: $0, at: 0) }
        XCTAssertEqual(Set(styles).count, 1, "and every style, from the first metre")

        XCTAssertEqual(schedule.powerUpWeightScale(for: 40, at: 300),
                       schedule.powerUpWeightScale(for: 41, at: 300), accuracy: 0.0001,
                       "and this run's own weighting of one power-up over another is dropped")
    }

    /// Neither twist is drawn for a mode that has nothing to disclose.
    func testTheDisclosureTwistsAreMayhemsAlone() {
        for twist in [DailyTwist.fullDeck, .levelPegging] {
            XCTAssertTrue(twist.applies(to: .endlessII), "\(twist)")
            XCTAssertFalse(twist.applies(to: .classic), "\(twist)")
            XCTAssertFalse(twist.applies(to: .endless), "\(twist)")
        }
    }

    /// And a day never draws both, because they are the same dial at two settings.
    func testADayNeverDrawsBothDisclosureTwists() {
        XCTAssertEqual(DailyTwist.fullDeck.category, DailyTwist.levelPegging.category)
    }
}
