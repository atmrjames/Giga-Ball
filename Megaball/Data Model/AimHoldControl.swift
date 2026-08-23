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
    ///
    /// **Unless the paddle may not be carried at all**, which is the ordinary case (James,
    /// round 172: "moving the paddle when aimed sticky is active is not good, it should just
    /// be the arrow angle - unless sticky paddle is also active, then the paddle movement
    /// should be allowed too"). Aimed Sticky freezes the world so the shot can be chosen; a
    /// drag that also slides the paddle is two decisions on one finger, and the aim is the one
    /// the power-up is for. Sticky Paddle running underneath is what buys the second decision
    /// back: that power-up's whole promise is that the ball comes with the paddle.
    /// **The paddle may always be carried now** (James, round 215: "drag below the paddle
    /// moves the paddle. Drag above the paddle moves the arrow relative to the drag. Tap
    /// releases the ball. The game doesn't pause. It acts more like the existing sticky power
    /// up").
    ///
    /// `paddleMayMove` was round 172's answer to a different complaint - that a drag doing two
    /// jobs at once was one decision too many for a finger - and it made the paddle immovable
    /// unless Sticky Paddle happened to be running underneath. With the world no longer
    /// stopping while a ball is aimed, a paddle that cannot be moved is a paddle that cannot
    /// answer a field that is still descending. Above aims, on or below carries, always.
    static func intent(touchY: CGFloat, paddleTopY: CGFloat,
                       paddleMayMove: Bool = true) -> Intent {
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

    /// What lifting the finger should do.
    ///
    /// **Three outcomes, not two**, and the third is the one that went missing. `launches`
    /// answers a yes/no question, and the caller read "no" as "this touch is not mine" and let
    /// it fall through to the ordinary paddle release - which launched the ball at the angle
    /// for where it happened to be sitting, ignoring the arrow entirely, and returned without
    /// ever ending the freeze the catch had put the world into.
    ///
    /// James, round 209: "Aimed sticky is broken. The ball isn't going where the arrow is
    /// aimed, the game scene then gets stuck paused but the ball is moving, the ball can go
    /// below the paddle and vibrate around." All three of those are that one fall-through.
    ///
    /// It has been reachable since round 172 stopped the aim drag carrying the paddle: before
    /// that, dragging moved the paddle and set `paddleMoved`, and the ordinary release checks
    /// that flag - so the very change that made aiming feel right removed the thing that had
    /// been guarding the door.
    static func release(travelled: CGFloat, aiming: Bool, intent: Intent = .paddle,
                        slop: CGFloat = tapSlop) -> Release {
        guard aiming else { return .notAiming }
        guard launches(travelled: travelled, slop: slop) else { return .keepAiming }
        return intent == .paddle ? .aimedLaunch : .keepAiming
        // **Where the tap was decides what it means** (James, round 232: "a tap above the
        // paddle moves the arrow to the tap position. A tap below the paddle launches the
        // ball"). A tap used to fire wherever it landed, which made the two things a player
        // wants to do with a held ball - point it, and then shoot it - the same gesture, so
        // every attempt to adjust the aim took the shot instead.
        //
        // Split by the same line that already divides aiming from carrying the paddle, so
        // there is one boundary on screen rather than two: above it points, below it fires.
    }

    /// The three things a release can mean while Aimed Sticky is holding a ball.
    enum Release {
        /// A tap: fire the held ball along the arrow.
        case aimedLaunch
        /// The end of an adjustment: the ball stays put and keeps the angle it was given.
        /// **Nothing else may have this touch** - the aim owns the launch while it runs
        /// (§5.4's launchControl group), so a release it declines is a release that does
        /// nothing at all, not one that falls through to the paddle.
        case keepAiming
        /// Nothing is being aimed; the touch belongs to whatever else wanted it.
        case notAiming
    }

    /// How far a finger may wander and still be a tap.
    ///
    /// A touch never travels zero: fingers roll, and the paddle-speed multiplier means a
    /// couple of points of roll is a visible paddle move. Ten points is about a millimetre
    /// and a half, comfortably inside what reads as "I did not move".
    static let tapSlop: CGFloat = 10
}
