//
//  PowerUpCatalogueTests.swift
//  GigaBallTests
//
//  The catalogue's job is to answer questions the activation switch could not: what
//  conflicts, what may drop, what a mode offers. These pin the answers - especially the
//  ones that would be silently wrong, like a conflict group quietly growing to include
//  power-ups that were meant to combine.
//

import XCTest
@testable import Giga_Ball

final class PowerUpCatalogueTests: XCTestCase {

    // MARK: - Shape

    func testEveryPowerUpHasADistinctID() {
        let ids = PowerUpCatalogue.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testTheExistingTwentyEightAreAllPresent() {
        XCTAssertEqual(PowerUpCatalogue.existing.count, 28)
    }

    func testEveryPowerUpCanBeLookedUpByID() {
        for powerUp in PowerUpCatalogue.all {
            XCTAssertEqual(PowerUpCatalogue.powerUp(id: powerUp.id)?.name, powerUp.name)
        }
    }

    // MARK: - Modes

    func testClassicAndEndlessOfferOnlyTheExistingPowerUps() {
        // The constraint the whole mode rests on: nothing new leaks into the modes people
        // already have scores in.
        let offered = PowerUpCatalogue.available(in: .allModes)
        XCTAssertTrue(offered.allSatisfy { $0.availability == .allModes })
        XCTAssertEqual(offered.count, PowerUpCatalogue.existing.count)
    }

    func testEndlessIIOffersBothItsOwnAndTheExistingOnes() {
        let offered = PowerUpCatalogue.available(in: .endlessII)
        XCTAssertEqual(offered.count, PowerUpCatalogue.all.count)
    }

    func testCompleteLevelAndExtraBallDoNotDropInEndlessII() {
        // Neither means anything where the field has no end and there is exactly one life.
        var context = PowerUpContext()
        context.mode = .endlessII
        let ids = PowerUpCatalogue.eligible(in: context).map(\.id)
        XCTAssertFalse(ids.contains("completeLevel"))
        XCTAssertFalse(ids.contains("extraBall"))
    }

    func testCompleteLevelAndExtraBallStillDropElsewhere() {
        let ids = PowerUpCatalogue.eligible(in: PowerUpContext()).map(\.id)
        XCTAssertTrue(ids.contains("completeLevel"))
        XCTAssertTrue(ids.contains("extraBall"))
    }

    // MARK: - Conflicts

    func testOnlyTwoConflictGroupsExist() {
        // Narrowness is the design. If a third group appears, it should be because someone
        // decided that, not because it crept in.
        let groups = Set(PowerUpCatalogue.all.compactMap(\.conflict))
        XCTAssertEqual(groups, [.ballHitBehaviour, .launchControl])
    }

    func testCollectingAConflictingPowerUpDisplacesTheOtherOne() {
        XCTAssertEqual(
            PowerUpCatalogue.displaced(byCollecting: "wreckingBall", whileActive: ["gigaBall"]),
            "gigaBall")
        XCTAssertEqual(
            PowerUpCatalogue.displaced(byCollecting: "aimedSticky", whileActive: ["stickyPaddle"]),
            "stickyPaddle")
    }

    func testPowerUpsThatShouldCombineDisplaceNothing() {
        // These pairings are the reason the model is conflicts rather than channels, so
        // they are worth asserting rather than trusting.
        let combinations = [
            ("magnetism", "inertPaddle"),
            ("flippedAngle", "magnetism"),
            ("aura", "wreckingBall"),
            ("portalPaddle", "wrapAround"),
            ("trajectoryLine", "landingMarker"),
        ]
        for (incoming, active) in combinations {
            XCTAssertNil(
                PowerUpCatalogue.displaced(byCollecting: incoming, whileActive: [active]),
                "\(incoming) should combine with \(active)")
        }
    }

    func testTheSteppedAxesAreNotConflicts() {
        // Ball speed, ball size and paddle size resolve themselves by stepping toward or
        // away from normal, which is existing behaviour and must not be turned into
        // mutual exclusion.
        for id in ["slowBall", "fastBall", "expandBall", "shrinkBall",
                   "expandPaddle", "shrinkPaddle"] {
            XCTAssertNil(PowerUpCatalogue.powerUp(id: id)?.conflict, id)
            XCTAssertEqual(PowerUpCatalogue.powerUp(id: id)?.stacking, .stepsAlongAxis, id)
        }
        XCTAssertNil(PowerUpCatalogue.displaced(byCollecting: "slowBall", whileActive: ["fastBall"]))
    }

    func testAPowerUpDoesNotDisplaceItself() {
        XCTAssertNil(PowerUpCatalogue.displaced(byCollecting: "gigaBall", whileActive: ["gigaBall"]))
    }

    // MARK: - Conditional drops

    func testLockDoesNotDropWithNothingToFreeze() {
        var context = PowerUpContext()
        context.mode = .endlessII
        XCTAssertFalse(PowerUpCatalogue.eligible(in: context).map(\.id).contains("lock"))
    }

    func testLockDropsOnlyWhenSomethingWouldStillBeRunningWhenItLands() {
        // Something timed being active is not enough - it has to still be active by the
        // time the Lock could be caught, or the Lock arrives with nothing left to freeze.
        var context = PowerUpContext()
        context.mode = .endlessII
        context.active = ["lasers"]
        XCTAssertFalse(PowerUpCatalogue.eligible(in: context).map(\.id).contains("lock"))

        context.timedWithTimeToSpare = ["lasers"]
        XCTAssertTrue(PowerUpCatalogue.eligible(in: context).map(\.id).contains("lock"))
    }

    func testKeyDropsOnlyWhileALockIsActive() {
        var context = PowerUpContext()
        context.mode = .endlessII
        XCTAssertFalse(PowerUpCatalogue.eligible(in: context).map(\.id).contains("key"))

        context.active = ["lock"]
        XCTAssertTrue(PowerUpCatalogue.eligible(in: context).map(\.id).contains("key"))
    }

    func testMultiBallStopsBeingOfferedAtTheCap() {
        var context = PowerUpContext()
        context.mode = .endlessII
        context.ballsInPlay = PowerUpContext.maximumBalls
        XCTAssertFalse(PowerUpCatalogue.eligible(in: context).map(\.id).contains("multiBall"))

        context.ballsInPlay = PowerUpContext.maximumBalls - 1
        XCTAssertTrue(PowerUpCatalogue.eligible(in: context).map(\.id).contains("multiBall"))
    }

    // MARK: - Classification

    func testEveryTimedPowerUpStacksInATimedWay() {
        // A timed power-up whose second collection "repeats" would silently restart rather
        // than extend, which is the behaviour this table exists to make explicit.
        for powerUp in PowerUpCatalogue.all where powerUp.isTimed {
            XCTAssertTrue([.extendsDuration, .extendsAndDeepens, .stepsAlongAxis]
                .contains(powerUp.stacking), powerUp.name)
        }
    }

    func testNoUntimedPowerUpClaimsToExtendADuration() {
        for powerUp in PowerUpCatalogue.all where !powerUp.isTimed {
            XCTAssertNotEqual(powerUp.stacking, .extendsDuration, powerUp.name)
        }
    }

    func testRarityWeightsFavourTheOrdinary() {
        XCTAssertGreaterThan(PowerUpRarity.common.weight, PowerUpRarity.uncommon.weight)
        XCTAssertGreaterThan(PowerUpRarity.uncommon.weight, PowerUpRarity.rare.weight)
    }

    func testTheRulesChangingPowerUpsAreTheRareOnes() {
        for id in ["wreckingBall", "portalPaddle", "wrapAround", "paddleHalo",
                   "ballSteering", "laserBeam", "lock"] {
            XCTAssertEqual(PowerUpCatalogue.powerUp(id: id)?.rarity, .rare, id)
        }
    }

    func testBadPowerUpsAreMarkedHarmfulSoTheyCanBeColouredAndScored() {
        for id in ["loseABall", "fastBall", "shrinkPaddle", "hideBricks", "inertBall",
                   "randomisedBounce", "inertPaddle", "flippedAngle", "wipe", "infill",
                   "reversedControls"] {
            XCTAssertEqual(PowerUpCatalogue.powerUp(id: id)?.valence, .harmful, id)
        }
    }
}

/// The pause reference pages' recents (§12.0's play-test request): "the Bricks and
/// Power-Ups pages, reached mid-run, list what was recently hit and recently seen first -
/// so a player can identify the thing that just happened. Unseen power-ups below,
/// alphabetical."
final class InGameRecentsTests: XCTestCase {

    func testEveryAppearanceIsItsOwnEntry() {
        // Round 8: "if a power-up showed up multiple times show it on the list multiple
        // times. Each time is a new entry."
        let recents = InGameRecents.shared
        recents.reset()
        recents.sawPowerUp(4)
        recents.sawPowerUp(7)
        recents.sawPowerUp(4)
        XCTAssertEqual(recents.powerUpIndices, [4, 7, 4],
                       "newest first, duplicates and all")
        recents.reset()
        XCTAssertTrue(recents.powerUpIndices.isEmpty, "a new run has seen nothing")
    }

    func testACollectionMarksTheNewestUncaughtAppearance() {
        let recents = InGameRecents.shared
        recents.reset()
        recents.sawPowerUp(4)
        recents.sawPowerUp(4)
        recents.collectedPowerUp(4)
        XCTAssertEqual(recents.statusNote(at: 0), "COLLECTED",
                       "the newest appearance is the one that was caught")
        XCTAssertEqual(recents.statusNote(at: 1), "MISSED",
                       "the earlier appearance stays the miss it was")
        recents.reset()
    }

    func testRowOrderLeadsWithRecentsAndAlphabetisesTheRest() {
        // Four rows whose power-up indices are 10, 11, 12, 13 and whose names reverse
        // the row order alphabetically. 12 then 10 were seen, 12 most recently.
        let names = ["Delta", "Charlie", "Bravo", "Alpha"]
        let order = InGameRecents.rowOrder(rowCount: 4, recents: [12, 10],
                                           powerUpIndex: { 10 + $0 },
                                           name: { names[$0] })
        XCTAssertEqual(order, [2, 0, 3, 1],
                       "seen rows first in recency order, unseen below, alphabetical")
    }

    func testStatusNotesReadTheMostCurrentFact() {
        // Round 7: "A falling power-up shouldn't be considered missed - maybe put
        // falling as an option." Round 8 adds BRICK for one still sitting in a power-up
        // brick. Active beats falling beats brick beats collected beats missed, and the
        // live states only speak for the newest appearance.
        let recents = InGameRecents.shared
        recents.reset()
        recents.sawPowerUp(5)
        XCTAssertEqual(recents.statusNote(at: 0), "MISSED")
        recents.fallingPowerUpIndices = [5]
        XCTAssertEqual(recents.statusNote(at: 0), "FALLING")
        recents.fallingPowerUpIndices = []
        recents.brickHeldPowerUpIndices = [5]
        XCTAssertEqual(recents.statusNote(at: 0), "BRICK")
        recents.brickHeldPowerUpIndices = []
        recents.collectedPowerUp(5)
        XCTAssertEqual(recents.statusNote(at: 0), "COLLECTED")
        recents.activePowerUpIndices = [5]
        XCTAssertEqual(recents.statusNote(at: 0), "ACTIVE")
        XCTAssertEqual(recents.statusNoteOldestFirst(at: 0), "ACTIVE",
                       "the run-stats page reads the same note from the other end")
        recents.reset()
    }

    func testTheStandardListDropsWhatTheRecentsAlreadyShow() {
        // Round 7: "Remove any power-ups that are in the recent list from the standard
        // power-up list below" - one list per power-up, not the same one twice.
        let rows = InGameRecents.standardRows(rowCount: 4, recents: [12, 10],
                                              powerUpIndex: { 10 + $0 })
        XCTAssertEqual(rows, [1, 3], "rows whose power-ups are listed above are gone")

        let untouched = InGameRecents.standardRows(rowCount: 4, recents: [],
                                                   powerUpIndex: { 10 + $0 })
        XCTAssertEqual(untouched, [0, 1, 2, 3], "no recents, the full list as ever")
    }

    func testEntryOrderLeadsWithRecentsAndKeepsTheCatalogueOrderForTheRest() {
        let names = ["Spinning", "Flashing", "Portal", "Fixed"]
        let order = InGameRecents.entryOrder(names: names,
                                             recents: ["Portal", "Missing", "Spinning"])
        XCTAssertEqual(order, [2, 0, 1, 3],
                       "recently struck first; the rest stay as the catalogue gives them")
    }
}
