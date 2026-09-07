//
//  PauseSwipeTests.swift
//  GigaBallTests
//
//  James, round 313: "Swipe up to pause is no longer working at all."
//
//  It had not worked since round 312, which added the distance check he asked for - "make the
//  swipe up to pause feature slightly less sensitive. I seem to be accidentally triggering it
//  a lot" - and measured that distance from the gesture recogniser. A discrete recogniser
//  reports where the gesture *began*, so the measured travel was always exactly zero and the
//  guard could never pass. The line meant to tune the feature switched it off, and nothing
//  failed: there was no test here, because there was nothing here a test could hold.
//
//  These tests exist because of the numbers that finding cost. Reproducing it took an
//  instrumented build, a device and a log: a 450-point swipe reported `here` and `start` equal
//  to six decimal places, and the scene's own tracking stopped at **forty points**, because
//  the recogniser cancelled the touch the moment it recognised. Neither party could see the
//  whole gesture. `PauseSwipe` is the rule pulled out where it can be asked without a finger.
//

import XCTest
@testable import Giga_Ball

final class PauseSwipeTests: XCTestCase {

    /// Six ball-widths on the iPad this was measured on.
    private let minimum: CGFloat = 118.6

    // MARK: - The report

    /// A long flick pauses. This is the case that was broken.
    func testALongFlickAsksForThePauseMenu() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        swipe.recognisedAFlick()
        // UIKit recognises about forty points in, well short of the threshold
        swipe.moved(to: -422)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "forty points is not a swipe yet")

        swipe.moved(to: -300)
        swipe.moved(to: -12)
        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum),
                      "and the rest of the flick is what the recogniser never saw")
    }

    /// The other half of round 312's request: a short one does not.
    func testAShortFlickDoesNotPause() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        swipe.recognisedAFlick()
        swipe.moved(to: -422)
        swipe.moved(to: -402)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "sixty points is the accidental trigger he asked to be rid of")
    }

    /// And a long *drag* does not, however far it goes - only a flick counts.
    func testADragThatIsNeverAFlickNeverPauses() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        for y in stride(from: -462.0, through: 0.0, by: 20.0) { swipe.moved(to: CGFloat(y)) }

        XCTAssertGreaterThan(swipe.travel, minimum, "it went far enough")
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "but the paddle is moved by dragging, and dragging must not pause")
    }

    // MARK: - The rule

    func testItAsksOncePerTouch() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)

        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum))
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "or every later move of the same finger pauses again")
    }

    /// Downward travel is not travel.
    func testGoingDownIsNotGoingUp() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: -300)

        XCTAssertEqual(swipe.travel, 0)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum))
    }

    /// The distance is the furthest the finger reached, not where it happened to be.
    ///
    /// A flick that overshoots and settles back is still a flick, and the recogniser has
    /// already agreed it was one.
    func testTheDistanceIsTheFurthestItGot() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)
        swipe.moved(to: 250)

        XCTAssertEqual(swipe.travel, 300)
        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum))
    }

    /// A new touch starts from nothing, or the next tap inherits the last swipe's distance.
    func testEachTouchStartsAgain() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)
        _ = swipe.shouldPause(travellingAtLeast: minimum)
        swipe.ended()

        XCTAssertEqual(swipe.travel, 0)

        swipe.began(at: 0)
        swipe.moved(to: 300)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "the flick belonged to the touch before this one")
    }

    /// A touch the scene never saw begin has no distance to measure from.
    func testATouchWithNoBeginningIsNotASwipe() {
        var swipe = PauseSwipe()
        swipe.recognisedAFlick()
        swipe.moved(to: 300)

        XCTAssertEqual(swipe.travel, 0)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum))
    }
}
