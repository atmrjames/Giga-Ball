//
//  PowerUpArrayTests.swift
//  GigaBallTests
//
//  Everything about a power-up is stored in a different array, indexed by the same number: its
//  name in one, its icon in another, its description, its multiplier, its timer, the pack that
//  unlocks it, two descriptions of how to unlock it, the order the list shows them in, and the
//  weight it drops at. Eleven arrays, one index.
//
//  Adding the twenty-ninth means adding an entry to every one of them, and the failure mode if
//  a single one is missed is not a crash - it is every power-up after that point quietly
//  wearing the next one's name, or the wrong description, or somebody else's collection count.
//  On a screen nobody looks at twice.
//
//  So this is the guard rail that goes in before the entry does.
//
//  One array is deliberately **not** guarded here: `powerUpTextureArray`. It is filled in
//  `didMove(to:)`, which needs a presented `SKView`, so a bare scene has none of it and any
//  assertion about its length would either fail for the wrong reason or be skipped and pass
//  for the wrong reason. A test that silently returns is worse than no test - it is the
//  "very rare or never offered" problem in test form. Checking it needs a scene actually on
//  screen, which is a play-test job: a new power-up that falls wearing nothing is visible
//  the first time it drops.
//

import XCTest
@testable import Giga_Ball

final class PowerUpArrayTests: XCTestCase {

    private let setup = LevelPackSetup()

    /// How many power-ups the game has, taken from the list of names.
    private var count: Int { setup.powerUpNameArray.count }

    func testEveryPowerUpArrayIsTheSameLength() {
        XCTAssertEqual(setup.powerUpImageArray.count, count, "images")
        XCTAssertEqual(setup.powerUpDescriptionArray.count, count, "descriptions")
        XCTAssertEqual(setup.powerUpMultiplierArray.count, count, "multipliers")
        XCTAssertEqual(setup.powerUpTimerArray.count, count, "timers")
        XCTAssertEqual(setup.powerUpUnlockedDescriptionArray.count, count, "unlock text")
        XCTAssertEqual(setup.powerUpHiddenUnlockedDescriptionArray.count, count, "hidden text")
        XCTAssertEqual(setup.powerUpPackOrderArray.count, count, "pack order")
        XCTAssertEqual(setup.powerUpCorrectOrderArray.count, count, "display order")
    }

    func testTheStoredArraysCoverEveryPowerUp() {
        // These are the ones decoded from a player's file, and the ones that would be read
        // past the end of if a power-up were added without them growing
        let stats = TotalStats()
        XCTAssertEqual(stats.powerupsCollected.count, count, "collected")
        XCTAssertEqual(stats.powerupsGenerated.count, count, "generated")
        XCTAssertEqual(stats.powerUpUnlockedArray.count, count, "unlocked")
    }

    func testTheDropWeightsCoverEveryPowerUp() {
        // `powerUpProbArray` is indexed the same way, and a power-up past the end of it can
        // never be drawn - which looks exactly like one that is simply very rare
        let scene = GameScene()
        XCTAssertEqual(scene.powerUpProbArray.count, count, "weights")
    }

    func testTheDisplayOrderIsAPermutationOfEveryPowerUp() {
        // It maps a row in the list to a power-up. A repeat shows one twice and hides another
        // entirely, and the page looks plausible either way
        XCTAssertEqual(Set(setup.powerUpCorrectOrderArray).count, count,
                       "the display order repeats or skips an index")
        XCTAssertEqual(setup.powerUpCorrectOrderArray.sorted(), Array(0..<count))
    }

    func testEveryPowerUpIsNamedAndDescribed() {
        for index in 0..<count {
            XCTAssertFalse(setup.powerUpNameArray[index].isEmpty, "name \(index)")
            XCTAssertFalse(setup.powerUpDescriptionArray[index].isEmpty, "description \(index)")
        }
    }

    func testEveryPowerUpBelongsToAPack() {
        for (index, pack) in setup.powerUpPackOrderArray.enumerated() {
            XCTAssertGreaterThanOrEqual(pack, 0, "power-up \(index)")
            XCTAssertLessThan(pack, setup.levelPackNameArray.count, "power-up \(index)")
        }
    }

    // MARK: - The two places a new power-up has to reach
    //
    // CLAUDE.md records this as a trap the project has already fallen into: "Adding a
    // power-up lengthens arrays in two places. The stats file *and*
    // `NSUbiquitousKeyValueStore`. Missing the second crashed the app on launch for a player
    // with years of synced data."
    //
    // Both sides now pad a short array from a longer template rather than trusting the two
    // to match, so the length is no longer the thing that has to be got right by hand. These
    // pin that, because the padding is the whole defence and it is four lines that look
    // deletable.

    func testAShortStatsFileIsPaddedRatherThanTrusted() {
        // A file written before a power-up existed, opened by the build that added it
        let fresh = TotalStats()
        let older = Array(fresh.powerupsCollected.dropLast(2))

        let padded = TotalStats.padded(older, like: fresh.powerupsCollected)
        XCTAssertEqual(padded.count, fresh.powerupsCollected.count)
    }

    func testAStatsFileFromANewerBuildKeepsItsExtras() {
        // Only ever lengthens: throwing the extras away would lose that player's progress
        // the moment they opened an older build
        let fresh = TotalStats()
        let newer = fresh.powerupsCollected + [7, 7, 7]

        XCTAssertEqual(TotalStats.padded(newer, like: fresh.powerupsCollected), newer)
    }

    func testTheStatsFileIsMadeConsistentOnLoad() {
        // The padding is applied where a decoded file arrives, not only where it is declared
        var older = TotalStats()
        older.powerupsCollected = Array(older.powerupsCollected.dropLast(3))
        older.powerupsGenerated = Array(older.powerupsGenerated.dropLast(3))
        older.powerUpUnlockedArray = Array(older.powerUpUnlockedArray.dropLast(3))

        older.makeStoredArraysConsistent()

        XCTAssertEqual(older.powerupsCollected.count, count)
        XCTAssertEqual(older.powerupsGenerated.count, count)
        XCTAssertEqual(older.powerUpUnlockedArray.count, count)
    }

    func testAShortCloudArrayIsPaddedFromTheLocalOne() {
        // The half that crashed. A device that has not updated yet writes the shorter array,
        // and the updated device reads it back and indexes past the end
        let local = Array(repeating: 3, count: count)
        let cloud = Array(repeating: 1, count: count - 2)

        let padded = CloudKitHandler.padded(cloud, toMatch: local)
        XCTAssertEqual(padded.count, count)
        XCTAssertEqual(Array(padded.prefix(count - 2)), cloud, "what was there is kept")
    }

    func testALongerCloudArrayIsLeftAlone() {
        // Written by a newer build than this one, and none of it is ours to discard
        let local = Array(repeating: 3, count: count)
        let cloud = Array(repeating: 1, count: count + 4)
        XCTAssertEqual(CloudKitHandler.padded(cloud, toMatch: local).count, count + 4)
    }

    // MARK: - The falling halo

    func testAHarmfulPowerUpGlowsInTheHarmfulColour() {
        // Derived from the multiplier column rather than a second list of which drops are
        // good: a list would be wrong the first time that judgement changed
        let setup = LevelPackSetup()
        guard let bad = setup.powerUpMultiplierArray.firstIndex(where: { $0.hasPrefix("-") })
        else { return XCTFail("no harmful power-up to check") }

        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: bad), PowerUpIcon.harmful)
    }

    func testAGoodPowerUpGlowsInTheBeneficialColour() {
        let setup = LevelPackSetup()
        guard let good = setup.powerUpMultiplierArray.firstIndex(where: { $0.hasPrefix("+") })
        else { return XCTFail("no beneficial power-up to check") }

        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: good), PowerUpIcon.beneficial)
    }

    func testAnIndexOffTheEndStillGetsAColour() {
        // Asked at the moment a drop is built, and a crash there is worse than a green halo
        XCTAssertEqual(GameScene.powerUpGlowColour(forIndex: count + 5),
                       PowerUpIcon.beneficial)
    }

    func testEveryPowerUpHasAHalo() {
        for index in 0..<count {
            let colour = GameScene.powerUpGlowColour(forIndex: index)
            XCTAssertTrue(colour == PowerUpIcon.harmful || colour == PowerUpIcon.beneficial,
                          "power-up \(index) glows in neither colour")
        }
    }
}

/// Which power-ups are wearing James's artwork.
///
/// `PowerUpIcon.artwork` falls back to a drawn placeholder when the catalogue has no image under
/// the name it is given - which is what lets the art arrive one piece at a time, and also means a
/// misspelled asset name is invisible: the icon looks exactly as it did the day before the art
/// was drawn. The two are told apart by size. A placeholder is drawn on a 120pt canvas; the
/// artwork is 250px square, so anything bigger than the canvas came out of the catalogue.
final class PowerUpArtworkTests: XCTestCase {

    /// James, round 176: "you'll find a load more power-up icons on the Desktop. Some to replace
    /// the exist ones, many new."
    private let drawn: [(String, UIImage)] = [
        ("Aimed Sticky", PowerUpIcon.aimedSticky),
        ("Ball Aura", PowerUpIcon.aura),
        ("Auto Aim", PowerUpIcon.autoAim),
        ("Ball Control", PowerUpIcon.ballSteering),
        ("Clear And Retreat", PowerUpIcon.clearAndRetreat),
        ("Cluster", PowerUpIcon.cluster),
        ("Brick Cull", PowerUpIcon.cull),
        ("Brick Descent", PowerUpIcon.descent),
        ("Double Paddle", PowerUpIcon.doublePaddle),
        ("Drift", PowerUpIcon.drift),
        ("Flipped Bounce Angle", PowerUpIcon.flippedAngle),
        ("Ghost Ball", PowerUpIcon.ghostBall),
        ("Inert Paddle", PowerUpIcon.inertPaddle),
        ("Brick Infill", PowerUpIcon.infill),
        ("Key", PowerUpIcon.key),
        ("Landing Marker", PowerUpIcon.landingMarker),
        ("Laser Beam", PowerUpIcon.laserBeam),
        ("Magnetism", PowerUpIcon.magnetism),
        ("Mirror Paddle", PowerUpIcon.mirrorPaddle),
        ("Multi-Ball", PowerUpIcon.multiBall),
        ("Halo", PowerUpIcon.paddleHalo),
        ("Random Bounce", PowerUpIcon.randomisedBounce),
        ("Reversed Paddle Control", PowerUpIcon.reversedControls),
        ("Safety Paddle", PowerUpIcon.safetyPaddle),
        ("Ball Trajectory", PowerUpIcon.trajectoryLine),
        ("Wipe", PowerUpIcon.wipe),
        ("Wrecking Ball", PowerUpIcon.wreckingBall),
    ]

    func testEveryDrawnPowerUpFindsItsArtwork() {
        for (name, icon) in drawn {
            XCTAssertGreaterThan(icon.size.width, PowerUpIcon.canvas.width,
                                 "\(name) is still drawing its placeholder - the artwork is not "
                                 + "in the catalogue under the name the icon asks for")
        }
    }

    func testTheOnesWithNoArtworkYetStillDrawThemselves() {
        // The other half of the same rule: §8.5 still lists these, and they must keep looking
        // like something until it does arrive
        for (name, icon) in [("Portal", PowerUpIcon.portalPaddle),
                             ("Wrap Around", PowerUpIcon.wrapAround),
                             ("Ball Spin", PowerUpIcon.ballSpin)] {
            XCTAssertEqual(icon.size, PowerUpIcon.canvas, name)
        }
    }

    func testTheArtworkIsSquare() {
        // The badge is drawn square and the reference pages lay it out as one
        for (name, icon) in drawn {
            XCTAssertEqual(icon.size.width, icon.size.height, accuracy: 0.001, name)
        }
    }
}

/// What a retired power-up is allowed to be part of.
///
/// James, round 217: "remove jagged paddle from the power-ups list." Round 213 retired it -
/// no mode offers it and its drop weight is zero - but retiring only stopped it being *given*.
/// It was still a square on the reference page and still a slot in "Items unlocked", so from
/// the player's side it was a power-up that existed and could never be had.
final class RetiredPowerUpsAreNotListedTests: XCTestCase {

    func testTheRetiredSlotsAreFoundThroughTheCatalogue() {
        let setup = LevelPackSetup()
        let jagged = setup.powerUpNameArray.firstIndex(of: "Jagged Paddle")
        XCTAssertNotNil(jagged, "the slot has to stay, or every later index shifts")
        XCTAssertEqual(setup.retiredPowerUpIndices, Set([jagged].compactMap { $0 }),
                       "the retired set is not what the catalogue says it is")
    }

    /// The reference page lists every power-up except the retired ones, once each.
    func testTheReferenceOrderIsTheDisplayOrderMinusTheRetired() {
        let setup = LevelPackSetup()
        let order = setup.powerUpReferenceOrder

        XCTAssertEqual(order.count,
                       setup.powerUpNameArray.count - setup.retiredPowerUpIndices.count,
                       "the page shows a different number of squares than it has power-ups")
        XCTAssertEqual(Set(order).count, order.count, "a power-up is listed twice")
        for index in setup.retiredPowerUpIndices {
            XCTAssertFalse(order.contains(index),
                           "\(setup.powerUpNameArray[index]) is still on the reference page")
        }
        XCTAssertEqual(order, setup.powerUpCorrectOrderArray
                                .filter { setup.retiredPowerUpIndices.contains($0) == false },
                       "the order of what is left has moved")
    }

    /// The raw display order still names every power-up, retired ones included.
    ///
    /// The two lists do different jobs and both matter: the raw one is the guard against a
    /// power-up being dropped from the game's own bookkeeping by accident, and the reference
    /// one is what a reader sees. Deriving the second from the first is what keeps them honest.
    func testTheRawDisplayOrderStillCoversEveryIndex() {
        let setup = LevelPackSetup()
        XCTAssertEqual(setup.powerUpCorrectOrderArray.sorted(),
                       Array(setup.powerUpNameArray.indices))
    }
}

/// What the reference page tells a player a power-up lasts.
///
/// Round 218 took the names, descriptions and durations from James's workbook
/// (Giga-Ball 2026.xlsx, Power-Up Details). The durations became uniform there: ten seconds
/// for anything timed, five paddle hits for anything spent by a bounce, and the workbook
/// exposed four places where the page was simply telling players the wrong thing.
final class PowerUpDurationTextTests: XCTestCase {

    private let setup = LevelPackSetup()

    private func index(_ name: String) -> Int {
        setup.powerUpNameArray.firstIndex(of: name) ?? -1
    }

    /// Every duration the page prints is one of the four the game has.
    func testThePageOnlySpeaksOfDurationsTheGameHas() {
        let allowed: Set<String> = ["", "10s", "5 paddle hits", "1 backstop hit", "Until a Key"]
        let retired = setup.retiredPowerUpIndices
        for (i, timer) in setup.powerUpTimerArray.enumerated() where retired.contains(i) == false {
            XCTAssertTrue(allowed.contains(timer),
                          "\(setup.powerUpNameArray[i]) says it lasts \(timer)")
        }
        // Retired slots are skipped rather than rewritten: nothing prints them, and their
        // entries are the file's furniture rather than the game's copy (round 217)
    }

    /// And "10s" is the number the code actually uses.
    func testTenSecondsIsTheDurationTheCodeRunsOn() {
        XCTAssertEqual(GameScene.endlessIIPaddlePowerUpDuration, 10)
        XCTAssertEqual(GameScene.endlessIIPaddlePowerUpTurns, 5)
        XCTAssertEqual(GameScene.endlessIIClearAndRetreatDuration,
                       GameScene.endlessIIPaddlePowerUpDuration)
        XCTAssertEqual(GameScene.endlessIIRandomisedBounceDuration,
                       GameScene.endlessIIPaddlePowerUpDuration)
        XCTAssertEqual(GameScene.endlessIIGhostBallDuration,
                       GameScene.endlessIIPaddlePowerUpDuration)
        XCTAssertEqual(GameScene.endlessIISafetyPaddleDuration,
                       GameScene.endlessIIPaddlePowerUpDuration)
    }

    /// The four the page had wrong, named one at a time so a regression says which.
    ///
    /// Landing Marker was printed as ten seconds and has counted paddle hits since round 215.
    /// Ball Control was printed as five hits and has run on seconds since round 15. Retreat
    /// and Backstop printed nothing at all, one of them an eight-second power-up and the other
    /// the one power-up in the game measured in saves.
    func testTheFourTheReferencePageHadWrong() {
        XCTAssertEqual(setup.powerUpTimerArray[index("Landing Marker")], "5 paddle hits")
        XCTAssertEqual(setup.powerUpTimerArray[index("Ball Control")], "10s")
        XCTAssertEqual(setup.powerUpTimerArray[index("Brick Retreat")], "10s")
        XCTAssertEqual(setup.powerUpTimerArray[index("Backstop")], "1 backstop hit")
    }

    /// A Lock is ended by a Key and by nothing else, so it prints no time at all.
    func testTheLockPrintsNoTime() {
        XCTAssertEqual(setup.powerUpTimerArray[index("Lock")], "Until a Key")
        XCTAssertEqual(setup.powerUpMultiplierArray[index("Lock")], "",
                       "a Lock is worth no multiplier")
        XCTAssertEqual(setup.powerUpMultiplierArray[index("Key")], "")
    }

    /// The three that act between bounces are timed, and the page says so.
    func testTheContinuousThreeArePrintedInSeconds() {
        for name in ["Ball Control", "Magnetism", "Halo"] {
            XCTAssertEqual(setup.powerUpTimerArray[index(name)], "10s", name)
        }
    }

    /// Nothing anywhere still carries a name the workbook renamed.
    func testNoRenamedNameSurvives() {
        let gone = ["Fast Ball", "Trajectory Line", "Portal Paddle", "Paddle Halo",
                    "Ball Steering", "Flipped Angle", "Reversed Controls", "Cull", "Retreat",
                    "Aura", "Infill", "Descent", "Randomised Bounce", "Wave Paddle"]
        for name in gone {
            XCTAssertFalse(setup.powerUpNameArray.contains(name),
                           "\(name) is still the name in the array")
            XCTAssertNil(PowerUpCatalogue.powerUp(named: name),
                         "\(name) is still the name in the catalogue")
        }
    }
}
