//
//  PauseSwipe.swift
//  Megaball
//
//  Whether a finger has asked for the pause menu.
//
//  James, round 313: "Swipe up to pause is no longer working at all." It had not worked since
//  round 312, which added the distance check he asked for ("make the swipe up to pause feature
//  slightly less sensitive. I seem to be accidentally triggering it a lot") and measured that
//  distance from `UISwipeGestureRecognizer.location(in:)`.
//
//  **A discrete recogniser reports where the gesture began, not where it got to.** Measured on
//  a 450-point swipe: `here` and `start` came back equal to six decimal places, so the travel
//  was always exactly zero and the guard could never pass. The feature was switched off by the
//  line meant to tune it, and nothing failed - there is no test that can watch a finger.
//
//  The second half of the finding is why the obvious repair does not work either. UIKit
//  recognises the swipe about **forty points** in and then cancels the touch, so the scene's
//  own tracking stops there too: at the moment the recogniser fires, *neither* party knows how
//  far the finger is going to travel. So the recogniser is left to do the one thing it is good
//  at - saying "that was a flick, upwards" - and the distance is measured by the scene, which
//  keeps following the finger because the recogniser no longer cancels its touches. The pause
//  happens the moment the two are both true.
//

import CoreGraphics

/// The state of the swipe-up-to-pause gesture within one touch.
///
/// Pure, so the rule can be tested without a finger - which is the whole reason this exists as
/// a type rather than as three variables on the scene.
struct PauseSwipe: Equatable {

    /// Where this touch began, in scene coordinates.
    private(set) var startY: CGFloat?
    /// The highest it has reached since.
    private(set) var reachedY: CGFloat?
    /// Whether UIKit has called this touch an upward flick.
    private(set) var flicked = false
    /// Whether this touch has already asked for the pause menu, so it asks once.
    private(set) var spent = false

    /// How far up the finger has travelled, at most, so far.
    var travel: CGFloat {
        guard let startY, let reachedY else { return 0 }
        return max(0, reachedY - startY)
    }

    mutating func began(at y: CGFloat) {
        startY = y
        reachedY = y
        flicked = false
        spent = false
    }

    mutating func moved(to y: CGFloat) {
        guard startY != nil else { return }
        // A touch the scene never saw begin has no distance to measure from
        reachedY = max(reachedY ?? y, y)
    }

    /// UIKit has recognised an upward flick in this touch.
    mutating func recognisedAFlick() {
        flicked = true
    }

    mutating func ended() {
        startY = nil
        reachedY = nil
        flicked = false
        spent = false
    }

    /// Whether the pause menu should open now, and marks the answer as given.
    ///
    /// Asked from both sides - by the recogniser when it fires, in case the finger has already
    /// gone far enough, and by every later touch move, for the far more common case where it
    /// has not yet. Whichever asks first gets the yes, and `spent` stops the other from asking
    /// again for the same touch.
    mutating func shouldPause(travellingAtLeast minimum: CGFloat) -> Bool {
        guard flicked, spent == false, travel >= minimum else { return false }
        spent = true
        return true
    }
}
