//
//  EndlessIIRescue.swift
//  Megaball
//
//  Getting a ball out of a loop it cannot get out of by itself.
//
//  Bounce angles already carry a little randomness, which breaks most loops before anybody
//  notices one. What it does not break is the geometrically clean case - a ball running a
//  perfectly vertical channel between two indestructible columns, or tracing the same
//  circuit round a pocket - where every bounce is the mirror of the last and the randomness
//  cancels rather than accumulates.
//
//  Detection is deliberately not clever. Rather than trying to recognise a loop, it watches
//  for the thing a loop actually costs the player: time passing with nothing being destroyed.
//  A ball that is genuinely stuck and a ball being played very badly look the same from here,
//  and the response is mild enough that it does not matter which it is.
//

import SpriteKit
import os

extension GameScene {

    /// How long the ball may be in play without destroying anything before it is nudged.
    ///
    /// Long enough that ordinary bad luck - a slow crawl through a sparse field, a stretch
    /// spent hitting indestructible bricks - never trips it. Short enough that a real loop is
    /// broken before it becomes a reason to quit.
    static let endlessIIStuckSeconds: TimeInterval = 14

    /// How far the nudge turns the ball, in radians.
    ///
    /// Small. The point is to break the symmetry that is holding the loop together, not to
    /// throw the ball somewhere the player did not expect - a large change would feel like
    /// the game taking a shot away from them.
    static let endlessIINudgeAngle: CGFloat = 0.14

    /// Advances the stuck timer and breaks the ball out if it has been too long.
    func tickEndlessIIRescue(_ delta: TimeInterval) {
        guard gameMode == .endlessII else { return }
        guard ballIsOnPaddle == false, gameState.currentState is Playing else {
            endlessIIStuckTimer = 0
            return
        }

        endlessIIStuckTimer += delta
        guard endlessIIStuckTimer >= GameScene.endlessIIStuckSeconds else { return }
        endlessIIStuckTimer = 0
        nudgeEndlessIIBall()
    }

    /// Called whenever a brick goes, because that is the definition of progress here.
    ///
    /// **And whenever the paddle is reached** (James, round 327b, with a device log: "the ball
    /// is still randomly changing angle mid flight near nothing"). His log named this function
    /// without meaning to - `CROOKED BALL, unexplained: bent 8.02 deg`, and 8.02 degrees is
    /// `endlessIINudgeAngle` to the last digit - so the ball he saw turn was not near anything
    /// because nothing was involved: fourteen seconds had passed without a brick breaking.
    ///
    /// That is not a stuck ball in this mode. A Mayhem field has stretches with nothing
    /// destructible in reach - a climb through indestructibles, a sparse field, a rally while
    /// the rows come down - and a player working through one was being turned every fourteen
    /// seconds for it. **A ball that keeps coming back to the paddle is being played**, which
    /// is the difference between a rally and a loop: the geometrically clean cases this exists
    /// for - a vertical channel between two indestructible columns, a circuit round a pocket -
    /// never reach the paddle at all, so the timer they run is untouched by this.
    func endlessIINotedProgress() {
        endlessIIStuckTimer = 0
    }

    /// Turns the ball slightly, keeping its speed.
    ///
    /// Rotating rather than re-aiming: the ball keeps its momentum and its rough heading, so
    /// what the player sees is a bounce that came off a little differently, not the game
    /// taking over.
    func nudgeEndlessIIBall() {
        guard let body = ball.physicsBody else { return }
        let speed = hypot(body.velocity.dx, body.velocity.dy)
        guard speed > 1 else { return }

        let turn = Bool.random() ? GameScene.endlessIINudgeAngle : -GameScene.endlessIINudgeAngle
        let angle = atan2(body.velocity.dy, body.velocity.dx) + turn
        body.velocity = CGVector(dx: cos(angle)*speed, dy: sin(angle)*speed)
        crookedBallNote(String(format: "stuck-rescue %.1f deg",
                               GameScene.endlessIINudgeAngle*180/CGFloat.pi))
        // **It says so now** (round 327b). This turned the ball with no contact, no clock and
        // no note, which is precisely the tripwire's definition of a sighting - so for three
        // rounds it was logged as the unexplained regression being hunted, by the instrument
        // built to find it. The loop-breaker learned the same lesson in round 190
    }

    /// Brings back any ball that has got outside the walls.
    ///
    /// James, round 387, with a device log: "I lost a ball and the game didn't end." The log's
    /// last line is the ball being handed over to a survivor at (-234, 73918), climbing straight
    /// up. That extra ball was past the left wall, and the walls are edges: a ball the far side
    /// of one is kept out by it as firmly as one inside is kept in, and nothing above the field
    /// turns it round. So it climbed for the rest of the run. The handover takes the highest
    /// survivor, and an escaped ball is always the highest, so when the last ball in the field
    /// went, play passed to a ball that could never come down - and the run could not end.
    ///
    /// Two of the ways out are closed where they happen (a new ball born on a paddle that
    /// overhangs a wall, and the Portal Paddle's exit at a brick drifting round the side), but
    /// the log could not say which one this was, because the crooked-ball watch only follows the
    /// first ball. Ball placement is written in a dozen places, and any of them missing a wall
    /// costs a whole run, so this is the net under all of them: a ball outside is put back,
    /// heading into the field, and the log says so in words that will name the next way out.
    ///
    /// A ball held on a paddle that overhangs a wall while Wrap-Around runs is not lost, it is
    /// on the part of the paddle drawn at the other side, so it is carried round to there and
    /// left otherwise alone. Run from `didSimulatePhysics`, after every other writer.
    func returnEndlessIIBallsToTheField() {
        guard gameMode == .endlessII, gameWidth > 0, frame.height > 0 else { return }
        // Not before there is a field: a scene that has not been laid out has no walls to be
        // outside, and every ball in it would read as escaped
        let wall = gameWidth/2
        let top = frame.height/2
        for subject in endlessIIBallsInPlay where subject.parent != nil {
            let was = subject.position
            guard abs(was.x) > wall || was.y > top else { continue }

            let held = (subject === ball && ballIsOnPaddle)
                || endlessIIHeldBalls.contains(where: { $0 === subject })
            let wrapping = endlessIIWrapIsRunning && abs(was.x) > wall
            var x = was.x
            if wrapping { x += was.x > 0 ? -gameWidth : gameWidth }
            let kept = endlessIIKeptInPlay(CGPoint(x: x, y: was.y))
            subject.position = CGPoint(x: kept.x, y: min(was.y, kept.y))
            // Not lifted: a ball below the field's floor is on its way to being lost, which is
            // the bottom's business and not this
            if subject === ball { crookedBallNote(held ? "held round the wall" : "returned to the field") }
            guard held == false, let body = subject.physicsBody else { continue }

            var velocity = body.velocity
            if abs(was.x) > wall, wrapping == false {
                velocity.dx = was.x > 0 ? -abs(velocity.dx) : abs(velocity.dx)
            }
            if was.y > top { velocity.dy = -abs(velocity.dy) }
            body.velocity = velocity
            // Wrapped, a ball keeps its heading, because that is what passing through a wall
            // means while the walls are doorways. Otherwise whatever was taking it out is turned
            // round, as the wall it should have met would have done

            let which = subject === ball ? "the first ball" : "an extra ball"
            let heading = atan2(velocity.dy, velocity.dx)*180/CGFloat.pi
            Log.play.error("BALL OUTSIDE THE FIELD: \(which, privacy: .public) at (\(Int(was.x)), \(Int(was.y))) put back, heading \(String(format: "%.1f", heading), privacy: .public) deg, wrap \(self.endlessIIWrapIsRunning ? "on" : "off", privacy: .public), drift \(self.endlessIIDriftDirection == 0 ? "off" : "on", privacy: .public)")
        }
    }
}
