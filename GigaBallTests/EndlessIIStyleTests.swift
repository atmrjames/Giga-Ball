//
//  EndlessIIStyleTests.swift
//  GigaBallTests
//
//  A brick is a behaviour and a style, and the whole point is that they combine freely. The
//  few pairs that do not combine are the ones where the two contradict each other, and each
//  exclusion is a design decision worth being able to see - it is much easier to quietly
//  rule out half the grid than to notice afterwards that Multi-hit bricks never flash.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIStyleTests: XCTestCase {

    private let behaviours: [EndlessIIBehaviour] = [.standard, .multiHit, .indestructibleOnce,
                                                    .indestructibleAlways, .invisible]

    func testMostCombinationsAreAllowed() {
        // If this ever drops sharply, something has started excluding pairs wholesale.
        let total = EndlessIIStyle.allCases.count*behaviours.count
        let allowed = EndlessIIStyle.allCases
            .flatMap { style in behaviours.map { style.suits($0) } }
            .filter { $0 }.count
        XCTAssertGreaterThan(allowed, total/2, "\(allowed) of \(total)")
    }

    func testTheShapeAndMotionStylesFitEverything() {
        // The ones that only change how a brick looks or moves have nothing to contradict.
        for style in [EndlessIIStyle.rounded, .spinning, .gravity, .moving] {
            for behaviour in behaviours {
                XCTAssertTrue(style.suits(behaviour), "\(style) on \(behaviour)")
            }
        }
    }

    func testAnIndestructibleBrickCanStillSpin() {
        // The combination that prompted the split: an obstacle you cannot remove, showing a
        // different angle every time the ball reaches it.
        XCTAssertTrue(EndlessIIStyle.spinning.suits(.indestructibleAlways))
    }

    func testFlashingIsTheOneStyleInvisibleCannotTake() {
        // Both are about whether the brick can be seen.
        XCTAssertFalse(EndlessIIStyle.flashing.suits(.invisible))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.multiHit))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.indestructibleAlways))
    }

    func testDirectionalNeedsABrickThatCanBeDestroyed() {
        // Exploding and Spawner used to be here too. They are not any more: on a brick that
        // can never be destroyed they fire on every hit instead, which is a reading of the
        // same style rather than an exception to it. Directional has no such reading - it
        // describes how a brick is destroyed, and there is nothing to describe.
        XCTAssertFalse(EndlessIIStyle.directional.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.directional.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.directional.suits(.multiHit))
        // Indestructible x1 becomes x2 when hit, so it is destructible once
        XCTAssertTrue(EndlessIIStyle.directional.suits(.indestructibleOnce))
    }

    func testAPortalIsOnlyEverIndestructible() {
        // Struck rather than damaged, so its behaviour has to be the one that already means
        // a hit does nothing - which is what lets the bottom-row check ignore it and the
        // field keep generating.
        XCTAssertTrue(EndlessIIStyle.portal.suits(.indestructibleAlways))
        for behaviour in behaviours where behaviour != .indestructibleAlways {
            XCTAssertFalse(EndlessIIStyle.portal.suits(behaviour), "\(behaviour)")
        }
    }

    func testEveryStyleFitsSomething() {
        for style in EndlessIIStyle.allCases {
            XCTAssertTrue(behaviours.contains { style.suits($0) },
                          "\(style) fits nothing at all")
        }
    }

    func testEveryBehaviourCanTakeSomeStyle() {
        for behaviour in behaviours {
            XCTAssertTrue(EndlessIIStyle.allCases.contains { $0.suits(behaviour) },
                          "\(behaviour) can take nothing at all")
        }
    }
}

extension EndlessIIStyleTests {

    // MARK: - Stacking

    func testAStyleNeverStacksWithItself() {
        for style in EndlessIIStyle.allCases {
            XCTAssertFalse(style.stacksWith(style), "\(style)")
        }
    }

    func testStackingIsSymmetric() {
        // An asymmetry here would mean a pair that works in one generation order and not the
        // other, which would look like a bug that only happens sometimes.
        for a in EndlessIIStyle.allCases {
            for b in EndlessIIStyle.allCases {
                XCTAssertEqual(a.stacksWith(b), b.stacksWith(a), "\(a) / \(b)")
            }
        }
    }

    func testTheCombinationTheSplitWasBuiltFor() {
        // Indestructible, rounded and spinning: you cannot remove it, it shows a different
        // angle every time, and the angles are ones a rectangle never gives.
        XCTAssertTrue(EndlessIIStyle.rounded.stacksWith(.spinning))
        XCTAssertTrue(EndlessIIStyle.rounded.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spinning.suits(.indestructibleAlways))
    }

    func testTwoStylesThatBothMoveABrickCannotShareIt() {
        XCTAssertFalse(EndlessIIStyle.spinning.stacksWith(.moving))
        XCTAssertFalse(EndlessIIStyle.gravity.stacksWith(.moving))
    }

    func testAVulnerableSideHasToStayFindable() {
        for style in [EndlessIIStyle.spinning, .moving, .flashing] {
            XCTAssertFalse(EndlessIIStyle.directional.stacksWith(style), "\(style)")
        }
    }

    func testOppositeAnswersToTheSameQuestionCannotShareABrick() {
        // One clears the neighbourhood, the other fills it.
        XCTAssertFalse(EndlessIIStyle.exploding.stacksWith(.spawner))
    }

    func testRoundedGoesWithEverythingElse() {
        // It only changes the brick's outline, so it has nothing to fight over.
        for style in EndlessIIStyle.allCases where style != .rounded {
            XCTAssertTrue(EndlessIIStyle.rounded.stacksWith(style), "\(style)")
        }
    }

    // MARK: - Firing on hit

    func testTheDestructionStylesFireOnHitWhenTheBrickCannotBeDestroyed() {
        XCTAssertTrue(EndlessIIStyle.exploding.firesOnHit(with: .indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spawner.firesOnHit(with: .indestructibleAlways))
    }

    func testEverywhereElseTheyStillFireOnDestruction() {
        for behaviour in [EndlessIIBehaviour.standard, .multiHit,
                          .indestructibleOnce, .invisible] {
            XCTAssertFalse(EndlessIIStyle.exploding.firesOnHit(with: behaviour), "\(behaviour)")
            XCTAssertFalse(EndlessIIStyle.spawner.firesOnHit(with: behaviour), "\(behaviour)")
        }
    }

    func testNothingElseFiresOnHit() {
        for style in EndlessIIStyle.allCases where style != .exploding && style != .spawner {
            XCTAssertFalse(style.firesOnHit(with: .indestructibleAlways), "\(style)")
        }
    }

    func testAnIndestructibleBrickCanNowCarryThemAtAll() {
        // The point of the on-hit reading: they used to be excluded here entirely.
        XCTAssertTrue(EndlessIIStyle.exploding.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spawner.suits(.indestructibleAlways))
    }
}

extension EndlessIIStyleTests {

    // MARK: - Fixed

    func testAFixedBrickNeedsToBeDestructible() {
        // It spends its first hit anchoring and its second dying. On a brick that never takes
        // damage it would simply never anchor.
        XCTAssertFalse(EndlessIIStyle.fixed.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.multiHit))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.invisible))
    }

    func testFixedCannotShareABrickWithAnythingThatMovesIt() {
        // One says stay exactly here, the others say do not.
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.moving))
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.gravity))
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.portal))
    }

    func testFixedStillCombinesWithTheHarmlessStyles() {
        // Anchoring says nothing about a brick's shape or what it does when destroyed.
        for style in [EndlessIIStyle.rounded, .spinning, .flashing, .exploding, .spawner] {
            XCTAssertTrue(EndlessIIStyle.fixed.stacksWith(style), "\(style)")
        }
    }

    func testAnAnchorFlagTravelsWithItsBrick() {
        let brick = SKSpriteNode()
        XCTAssertFalse(brick.endlessIIIsAnchored)
        brick.endlessIIIsAnchored = true
        XCTAssertTrue(brick.endlessIIIsAnchored)

        brick.endlessIIRole = .fixed
        XCTAssertTrue(brick.endlessIIIsAnchored, "setting a role must not clear the anchor")
    }
}
