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

    func testSuperlativesAreTheMostsNotTheDiary() {
        // Round 9: "rather than showing all the power-ups in order, just show the most
        // collected, most missed, etc."
        let recents = InGameRecents.shared
        recents.reset()
        recents.sawPowerUp(4)                 // one miss of 4
        recents.sawPowerUp(7)
        recents.sawPowerUp(7)
        recents.collectedPowerUp(7)           // 7: seen twice, one caught, one missed
        recents.sawPowerUp(2)
        recents.collectedPowerUp(2)
        recents.sawPowerUp(2)
        recents.collectedPowerUp(2)           // 2: seen twice, both caught
        recents.sawPowerUp(4)                 // 4: seen twice, both missed

        let highlights = recents.superlatives
        XCTAssertEqual(highlights.map(\.title),
                       ["Most seen", "Most collected", "Most missed"])
        XCTAssertEqual(highlights.first { $0.title == "Most seen" }.map { [$0.index, $0.count] },
                       [2, 2], "a three-way tie on two sightings reads to the lowest index")
        XCTAssertEqual(highlights.first { $0.title == "Most collected" }.map { [$0.index, $0.count] },
                       [2, 2])
        XCTAssertEqual(highlights.first { $0.title == "Most missed" }.map { [$0.index, $0.count] },
                       [4, 2])
        recents.reset()
    }

    func testASingleEventEarnsNoRosette() {
        // A count of one is just "a thing that happened once" - no superlative below two
        let recents = InGameRecents.shared
        recents.reset()
        recents.sawPowerUp(4)
        recents.sawPowerUp(7)
        recents.collectedPowerUp(7)
        XCTAssertTrue(recents.superlatives.isEmpty,
                      "one miss and one catch make no mosts")
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

    // MARK: - The reference page's list and this catalogue's

    /// The list the game ships is `powerUpNameArray`: the save file counts in it, the cloud
    /// store counts in it, and the drop probabilities are set by index into it. This catalogue
    /// describes the same power-ups separately, and the two are allowed to differ in exactly
    /// one direction.
    ///
    /// **The catalogue may describe a power-up that is designed and not yet built.** Randomised
    /// Bounce is the only one, and it is queued (§12.0). **The catalogue may never miss one the
    /// game has** - that direction is a bug, and it was one: Cull and Auto-Aim were both built,
    /// both Mayhem's, and absent from here, so the Mayhem badge would have skipped them if it
    /// had been taken from `availability` rather than from the index.
    ///
    /// Wipe was in the first list until round 31 built it, which is the shape this is meant to
    /// have: entries leave that list by being built, and nothing ever joins the second.
    func testTheCatalogueMayRunAheadOfTheGameButNeverBehindIt() {
        let shipped = Set(LevelPackSetup().powerUpNameArray)
        let catalogued = Set(PowerUpCatalogue.all.map(\.name))

        XCTAssertEqual(catalogued.subtracting(shipped), ["Randomised Bounce"],
                       "designed and not yet built - anything else here needs a queue row")
        XCTAssertTrue(shipped.subtracting(catalogued).isEmpty,
                      "the game has a power-up this file has never heard of")
    }

    /// The part the two do agree on, which is the part anything is safe to read: the original
    /// twenty-eight, in the same order, under the same names.
    func testTheOriginalTwentyEightAgree() {
        let shipped = Array(LevelPackSetup().powerUpNameArray.prefix(
            LevelPackSetup.firstEndlessIIPowerUp))
        XCTAssertEqual(shipped, PowerUpCatalogue.existing.map(\.name))
    }

    // MARK: - Which power-ups belong to Endless Mayhem

    /// The boundary is load-bearing: everything from it on is Mayhem's, and the badge on the
    /// power-ups page is drawn from exactly this. Pinned by the names either side of it, so
    /// moving a power-up across the line has to be a decision rather than an accident.
    func testTheMayhemPowerUpsStartWhereTheOriginalsEnd() {
        let names = LevelPackSetup().powerUpNameArray
        let boundary = LevelPackSetup.firstEndlessIIPowerUp

        XCTAssertEqual(boundary, 28)
        XCTAssertEqual(names[boundary-1], "Shrink Ball", "the last of the original set")
        XCTAssertEqual(names[boundary], "Multi-Ball", "the first of Mayhem's")
        XCTAssertEqual(names.count - boundary, 23, "Mayhem's own, Wipe included")
        XCTAssertEqual(boundary, PowerUpCatalogue.existing.count)
    }

    func testTheBadgeGoesOnMayhemsPowerUpsAndNoOthers() {
        let setup = LevelPackSetup()

        // The ones a player would otherwise go hunting for in a Classic pack
        for name in ["Portal Paddle", "Wrecking Ball", "Cull", "Auto-Aim", "Lock", "Key"] {
            let index = setup.powerUpNameArray.firstIndex(of: name)
            XCTAssertNotNil(index, name)
            XCTAssertTrue(setup.isEndlessIIPowerUp(index ?? 0), name)
        }
        for name in ["Extra Ball", "Lasers", "Mystery", "Shrink Ball"] {
            let index = setup.powerUpNameArray.firstIndex(of: name)
            XCTAssertNotNil(index, name)
            XCTAssertFalse(setup.isEndlessIIPowerUp(index ?? 0), name)
        }
    }

    /// An index off the end of the list is not Mayhem's - it is nothing, and a screen asking
    /// about one should not get a badge for its trouble.
    func testAnIndexOffTheEndIsNotAMayhemPowerUp() {
        let setup = LevelPackSetup()
        XCTAssertFalse(setup.isEndlessIIPowerUp(setup.powerUpNameArray.count))
        XCTAssertFalse(setup.isEndlessIIPowerUp(-1))
    }
}
