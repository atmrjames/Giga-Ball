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
}
