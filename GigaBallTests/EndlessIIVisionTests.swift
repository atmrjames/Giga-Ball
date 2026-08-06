//
//  EndlessIIVisionTests.swift
//  GigaBallTests
//
//  The vision power-ups' clocks and stacking. The geometry they draw is BallPath's and is
//  tested there; what belongs here is that collecting, ticking and expiring behave like the
//  game's other timed power-ups - extend on a second collection, freeze while paused, and
//  leave nothing behind when they run out.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIVisionTests: XCTestCase {

    private func visionScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.ballSize = 10
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    // MARK: - Collecting

    func testCollectingStartsTheClock() {
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()
        XCTAssertEqual(scene.endlessIITrajectoryRemaining, GameScene.endlessIIVisionDuration)
    }

    func testASecondCollectionExtendsRatherThanRestarts() {
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()
        scene.endlessIITrajectoryRemaining = 4
        scene.endlessIICollectTrajectoryLine()

        XCTAssertEqual(scene.endlessIITrajectoryRemaining,
                       4 + GameScene.endlessIIVisionDuration)
    }

    func testAThirdCollectionLengthensTheLine() {
        // §5.4: extends, then lengthens
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()
        XCTAssertEqual(scene.endlessIITrajectoryLevel, 0, "first collection is base length")

        scene.endlessIICollectTrajectoryLine()
        XCTAssertEqual(scene.endlessIITrajectoryLevel, 1)

        scene.endlessIICollectTrajectoryLine()
        XCTAssertEqual(scene.endlessIITrajectoryLevel,
                       GameScene.endlessIITrajectoryReach.count - 1,
                       "the reach table is the whole ladder - it never runs off the end")
    }

    func testTheLandingMarkerExtendsToo() {
        let scene = visionScene()
        scene.endlessIICollectLandingMarker()
        scene.endlessIICollectLandingMarker()
        XCTAssertEqual(scene.endlessIILandingRemaining, GameScene.endlessIIVisionDuration*2)
    }

    // MARK: - The clock

    func testTheClockOnlyRunsDuringPlay() {
        // Pausing freezes these like any other power-up timer. The state machine is not
        // Playing in a bare scene, so ticking must not drain anything
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()

        scene.tickEndlessIIVision(10)
        scene.tickEndlessIIVision(20)
        XCTAssertEqual(scene.endlessIITrajectoryRemaining, GameScene.endlessIIVisionDuration)
    }

    func testExpiryTakesTheDrawingWithIt() {
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()
        scene.endlessIITrajectoryRemaining = 0
        scene.tickEndlessIIVision(1)

        XCTAssertTrue(scene.endlessIITrajectoryLines.isEmpty)
        XCTAssertEqual(scene.endlessIITrajectoryLevel, 0, "the next collection starts over")
    }

    func testResetClearsEverything() {
        let scene = visionScene()
        scene.endlessIICollectTrajectoryLine()
        scene.endlessIICollectLandingMarker()
        scene.endlessIIResetVision()

        XCTAssertEqual(scene.endlessIITrajectoryRemaining, 0)
        XCTAssertEqual(scene.endlessIILandingRemaining, 0)
        XCTAssertTrue(scene.endlessIITrajectoryLines.isEmpty)
        XCTAssertTrue(scene.endlessIILandingMarkers.isEmpty)
    }

    // MARK: - The ring

    func testActiveVisionPowerUpsReportThemselvesToTheRing() {
        // They have no tray slot for the ring to read, so they have to speak up
        let scene = visionScene()
        XCTAssertTrue(scene.endlessIIVisionRingEntries().isEmpty)

        scene.endlessIICollectTrajectoryLine()
        scene.endlessIICollectLandingMarker()
        let entries = scene.endlessIIVisionRingEntries()

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.first?.remaining, 1)
    }

    func testTheRingShowsTheFractionRemaining() {
        let scene = visionScene()
        scene.endlessIICollectLandingMarker()
        scene.endlessIILandingRemaining = GameScene.endlessIIVisionDuration/2

        XCTAssertEqual(scene.endlessIIVisionRingEntries().first?.remaining ?? 0, 0.5,
                       accuracy: 0.001)
    }

    // MARK: - The mode boundary

    func testOtherModesNeverTick() {
        let scene = visionScene()
        scene.gameMode = .classic
        scene.endlessIICollectTrajectoryLine()
        // Collecting outside Endless 2.0 cannot happen - the weights are endless II's - but
        // the tick guard is what keeps the drawing out of Classic even if something slips
        scene.tickEndlessIIVision(1)
        XCTAssertTrue(scene.endlessIITrajectoryLines.isEmpty)
    }

    // MARK: - The mode boundary, from the other side

    func testTheOriginalEndlessNeverOffersTheVisionPowerUps() {
        // buildNewEndlessRow serves both endless modes, and its weights are written per row.
        // A flat weight there would quietly add these to a mode whose leaderboards hold
        // years of scores - the constraint that never bends
        let scene = visionScene()
        scene.gameMode = .endless
        scene.applyEndlessRowPowerUpWeights()

        XCTAssertEqual(scene.powerUpProbArray[29], 0)
        XCTAssertEqual(scene.powerUpProbArray[30], 0)
    }

    func testEndlessIIOffersThem() {
        let scene = visionScene()
        scene.applyEndlessRowPowerUpWeights()

        XCTAssertGreaterThan(scene.powerUpProbArray[29], 0)
        XCTAssertGreaterThan(scene.powerUpProbArray[30], 0)
    }

    // MARK: - The bounds

    func testThePredictorSeesTheFieldTheBallPlaysIn() {
        let scene = visionScene()
        scene.gameWidth = 400
        let bounds = scene.endlessIIVisionBounds()

        XCTAssertEqual(bounds.left, -200)
        XCTAssertEqual(bounds.right, 200)
        XCTAssertEqual(bounds.paddleLine, scene.paddle.position.y)
    }
}
