//
//  AimHoldControl.swift
//  Megaball
//
//  What a finger means while Aimed Sticky is holding a ball (§12.0, play-test round 33).
//
//  James's design, in his words: "with both running the player can aim *and* reposition.
//  Letting go of the screen leaves the ball on the paddle; the ball only launches on a tap.
//  A swipe on or below the paddle moves the paddle; a swipe above the paddle moves the aim
//  arrow."
//
//  Until now the hold took the whole screen: every drag was the aim, the paddle could not
//  move, and *any* release fired - so a player who caught a ball at the wrong end of the
//  field had to shoot from where they stood. That is the difference this file makes, and it
//  is why the queue put Auto-Aim and Aimed Sticky in the same row: they are one control.
//
//  It is a pure type because "which half of the screen was that?" is a rule, and a rule that
//  lives in `touchesMoved` beside a hundred lines of paddle arithmetic can only be checked by
//  playing the game and feeling for it.
//

import CoreGraphics

enum AimHoldControl {

    /// What a drag is doing.
    enum Intent {
        /// Above the paddle: the finger is pointing the shot.
        case aim
        /// On or below the paddle: the finger is carrying the paddle, ball and all.
        case paddle
    }

    /// Which of the two a touch at this height is asking for.
    ///
    /// The boundary is the paddle's own top edge, so "on the paddle" belongs to the paddle -
    /// a thumb resting on the thing it is dragging should drag it. Everything above it is
    /// aiming, including the whole empty field, because that is where a player looks when
    /// choosing where to shoot.
    static func intent(touchY: CGFloat, paddleTopY: CGFloat) -> Intent {
        touchY > paddleTopY ? .aim : .paddle
    }

    /// Whether lifting the finger should fire.
    ///
    /// Only a tap does. The rule reads backwards until you hold a ball: a release that fired
    /// would mean a player who moved the paddle to line the shot up has already taken it by
    /// the time they let go, and there would be no way to reposition at all. So the finger
    /// may wander as much as it likes; the shot is a separate, deliberate tap.
    ///
    /// - Parameter travelled: how far the touch moved in total, in points, not how far it
    ///   ended from where it began - a finger that goes out and comes back has still moved,
    ///   and treating that as a tap is how a shot goes off during an adjustment.
    static func launches(travelled: CGFloat, slop: CGFloat = tapSlop) -> Bool {
        travelled <= slop
    }

    /// How far a finger may wander and still be a tap.
    ///
    /// A touch never travels zero: fingers roll, and the paddle-speed multiplier means a
    /// couple of points of roll is a visible paddle move. Ten points is about a millimetre
    /// and a half, comfortably inside what reads as "I did not move".
    static let tapSlop: CGFloat = 10
}
