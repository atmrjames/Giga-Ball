//
//  EndlessIIBallsTests.swift
//  GigaBallTests
//
//  The rule phase 7 exists for: the run continues while at least one ball is in play, and the
//  life is lost when the last one goes. It is one line of arithmetic and it decides whether a
//  run ends, so it is worth being able to see.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIBallsTests: XCTestCase {

    func testLosingOneOfSeveralCostsNothing() {
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 4), .carryOn)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 3), .carryOn)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 2), .carryOn)
    }

    func testLosingTheLastOneEndsTheLife() {
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 1), .lifeLost)
    }

    func testASingleBallBehavesExactlyAsItAlwaysHas() {
        // Classic and Endless never have more than one, so this is the only answer they can
        // ever get - which is what keeps them untouched by any of this
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 1), .lifeLost)
        XCTAssertEqual(EndlessIIBalls.losing(oneOf: 0), .lifeLost)
    }

    func testFourIsTheCeiling() {
        XCTAssertTrue(EndlessIIBalls.canAdd(inPlay: 1))
        XCTAssertTrue(EndlessIIBalls.canAdd(inPlay: 3))
        XCTAssertFalse(EndlessIIBalls.canAdd(inPlay: 4))
        XCTAssertFalse(EndlessIIBalls.canAdd(inPlay: 5))
    }

    // MARK: - Launching

    func testANewBallKeepsItsParentsSpeed() {
        // Ball speed is one shared value across every ball in play, so a ball added during a
        // Slow Ball arrives slow rather than at whatever it was created with
        let parent = CGVector(dx: 120, dy: 160)
        let expected = hypot(parent.dx, parent.dy)

        for index in 0..<4 {
            let launched = EndlessIIBalls.launchAngle(of: parent, index: index)
            XCTAssertEqual(hypot(launched.dx, launched.dy), expected, accuracy: 0.001)
        }
    }

    func testANewBallIsTurnedAwayFromTheOneItCameFrom() {
        // Two balls travelling as one is a Multi-Ball the player cannot see happen
        let parent = CGVector(dx: 0, dy: 200)
        let launched = EndlessIIBalls.launchAngle(of: parent, index: 0)

        let parentAngle = atan2(parent.dy, parent.dx)
        let launchedAngle = atan2(launched.dy, launched.dx)
        XCTAssertEqual(abs(launchedAngle - parentAngle), EndlessIIBalls.spreadAngle,
                       accuracy: 0.001)
    }

    func testSuccessiveBallsAlternateSides() {
        // So a pair opens the field up evenly rather than pushing everything one way
        let parent = CGVector(dx: 0, dy: 200)
        let first = EndlessIIBalls.launchAngle(of: parent, index: 0)
        let second = EndlessIIBalls.launchAngle(of: parent, index: 1)

        XCTAssertGreaterThan(first.dx*second.dx, -.infinity)
        XCTAssertEqual(first.dx, -second.dx, accuracy: 0.001)
        XCTAssertEqual(first.dy, second.dy, accuracy: 0.001)
    }

    func testANewBallStillGoesSomewhereWhenTheBallIsSittingStill() {
        // Collected before the launch, when the ball is on the paddle with no heading at all
        let launched = EndlessIIBalls.launchAngle(of: .zero, index: 0)
        XCTAssertGreaterThan(hypot(launched.dx, launched.dy), 0)
        XCTAssertGreaterThan(launched.dy, 0, "it has to leave the paddle upward")
    }

    func testANewBallIsPlacedClearOfItsParent() {
        // Created inside one another, the physics resolves the overlap by throwing both
        // somewhere arbitrary
        let parent = CGPoint(x: 10, y: 20)
        let heading = CGVector(dx: 100, dy: 0)
        let placed = EndlessIIBalls.launchPosition(from: parent, heading: heading,
                                                   clearance: 15)

        XCTAssertEqual(hypot(placed.x - parent.x, placed.y - parent.y), 15, accuracy: 0.001)
        XCTAssertGreaterThan(placed.x, parent.x, "clear along the way it is going")
    }

    func testAStationaryParentStillPlacesItsChildClear() {
        let placed = EndlessIIBalls.launchPosition(from: .zero, heading: .zero, clearance: 15)
        XCTAssertEqual(hypot(placed.x, placed.y), 15, accuracy: 0.001)
    }

    // MARK: - In the scene

    func testTheSceneReportsOneBallUntilOneIsAdded() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        XCTAssertEqual(scene.endlessIIBallsInPlay.count, 1)
        XCTAssertTrue(scene.endlessIICanAddBall)
    }

    func testOtherModesNeverAddABall() {
        // Classic and Endless keep a single ball. Nothing here is allowed to reach them
        for mode in [GameMode.classic, .endless] {
            let scene = GameScene()
            scene.gameMode = mode
            XCTAssertFalse(scene.endlessIICanAddBall, "\(mode)")
            XCTAssertFalse(scene.endlessIIAddBall(), "\(mode)")
            XCTAssertEqual(scene.endlessIIBallsInPlay.count, 1, "\(mode)")
        }
    }

    func testLosingABallInAnotherModeStillEndsTheLife() {
        // The early return in ballLostAnimation must never fire outside Endless 2.0
        let scene = GameScene()
        scene.gameMode = .classic
        XCTAssertFalse(scene.endlessIIBallWasLost(scene.ball))
    }
}
