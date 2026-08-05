//
//  EndlessIIBrickTests.swift
//  GigaBallTests
//
//  A flashing brick makes a promise: what you can see, you can hit. If the solid window and
//  the opaque window ever come apart, the brick lies - either the ball passes through
//  something that looks solid, or it bounces off something that looks like a gap. Neither
//  is a crash, so nothing else would catch it.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIBrickTests: XCTestCase {

    private func flasher(solidFor: TimeInterval = 2, passableFor: TimeInterval = 2)
    -> EndlessIIFlasher {
        EndlessIIFlasher(brick: SKSpriteNode(), solidFor: solidFor,
                         passableFor: passableFor, phase: 0)
    }

    func testSolidExactlyWhileFullyOpaque() {
        // Both directions, so neither kind of lie is possible: a brick is never solid while
        // it is fading, and never fading while it is solid. It starts fading the instant it
        // stops being solid.
        let brick = flasher()

        var phase: TimeInterval = 0
        while phase < brick.cycle {
            let state = brick.state(at: phase)
            if state.solid {
                XCTAssertEqual(state.alpha, 1, "solid at \(phase) but not fully opaque")
            } else {
                XCTAssertLessThan(state.alpha, 1, "fully opaque at \(phase) but not solid")
            }
            phase += EndlessIIFlasher.fade/10
        }
    }

    func testItStartsSolidAndOpaque() {
        let state = flasher().state(at: 0)
        XCTAssertTrue(state.solid)
        XCTAssertEqual(state.alpha, 1, accuracy: 0.0001)
    }

    func testItStopsBeingSolidTheInstantItStartsFading() {
        let brick = flasher(solidFor: 2, passableFor: 2)
        XCTAssertTrue(brick.state(at: 1.999).solid)
        XCTAssertFalse(brick.state(at: 2.001).solid)
    }

    func testAHeldBrickDoesNotLookSolid() {
        // The tick only makes a brick solid again by wrapping its phase, and it refuses to
        // wrap while the ball is inside - so a brick can sit at the end of its cycle
        // indefinitely. If the fade had finished by then it would look solid the whole time
        // the ball was passing through it.
        let brick = flasher()
        let state = brick.state(at: brick.cycle - 0.001)
        XCTAssertFalse(state.solid)
        XCTAssertLessThanOrEqual(state.alpha, EndlessIIFlasher.returningAlpha + 0.0001)
    }

    func testAlphaNeverLeavesTheVisibleRange() {
        let brick = flasher(solidFor: 3, passableFor: 1.5)
        var phase: TimeInterval = 0
        while phase <= brick.cycle {
            let alpha = brick.state(at: phase).alpha
            XCTAssertGreaterThanOrEqual(alpha, EndlessIIFlasher.passableAlpha - 0.0001,
                                        "invisible at \(phase)")
            XCTAssertLessThanOrEqual(alpha, 1.0001, "over-bright at \(phase)")
            phase += 0.01
        }
    }

    func testAPassableBrickIsStillVisible() {
        // A brick that vanishes completely is one the player cannot plan around.
        XCTAssertGreaterThan(EndlessIIFlasher.passableAlpha, 0)
    }

    func testTheCycleIsBothHoldsPlusBothFades() {
        let brick = flasher(solidFor: 2.5, passableFor: 1.75)
        XCTAssertEqual(brick.cycle, 2.5 + 1.75 + EndlessIIFlasher.fade*2, accuracy: 0.0001)
    }
}
