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

    func testTheStylesThatFireOnDestructionNeedABrickThatCanBeDestroyed() {
        for style in [EndlessIIStyle.directional, .exploding, .spawner] {
            XCTAssertFalse(style.suits(.indestructibleAlways), "\(style)")
            XCTAssertTrue(style.suits(.standard), "\(style)")
            XCTAssertTrue(style.suits(.multiHit), "\(style)")
            // Indestructible x1 becomes x2 when hit, so it is destructible once
            XCTAssertTrue(style.suits(.indestructibleOnce), "\(style)")
        }
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
