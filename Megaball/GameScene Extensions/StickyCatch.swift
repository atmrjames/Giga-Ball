//
//  StickyCatch.swift
//  Megaball
//
//  Catching the ball on the sticky paddle *before* the physics step, rather than after it.
//
//  The catch used to be made in `paddleHit`, which runs from `didBegin(_:)`. The ball and the
//  paddle collide as well as report contact, so by the time that contact arrived SpriteKit had
//  already resolved the bounce and moved the ball - and the catch then zeroed the velocity and
//  snapped the ball back down onto the paddle. The snap was visible: the play-test saw the ball
//  "bounce off a fraction after it hits the paddle, before snapping back into position".
//
//  It is §8.6's first trap in a new place. A contact reports the state *after* the engine has
//  acted, so anything that needs the approach - which face was struck, which way a portal sends
//  a ball, and now whether a ball was about to land on the paddle - has to be sampled in
//  `update`, before physics. `ballStateBeforeStep` is that sample and this reads it.
//
//  Doing it here means no bounce happens at all: the ball is stopped on the frame it would have
//  crossed the paddle's surface, so there is nothing to snap back from.
//

import SpriteKit

extension GameScene {

    /// How far ahead the catch looks: one frame at sixty.
    ///
    /// A fixed step rather than the frame's measured delta, because the only measured delta in
    /// the scene is `endlessIIPaddleFrameDelta`, which is set under a `gameMode == .endlessII`
    /// guard and stays zero everywhere else - and the sticky paddle is one of the original
    /// twenty-eight, so this has to work in Classic and the original Endless first of all.
    ///
    /// Being a frame or two eager costs nothing: the catch puts the ball on
    /// `ballStartingPositionY` whatever it was doing, so an early catch sticks it in exactly
    /// the same place a late one would, and a hair early is invisible where a bounce was not.
    static let stickyLookahead: TimeInterval = 1.0/60.0

    /// Catches the ball on the sticky paddle if this step would land it there.
    ///
    /// Called from `update`, after `recordBallStatesBeforeStep` and before physics runs.
    ///
    /// Deliberately only the main ball. The extra balls of Multi-Ball are caught by
    /// `endlessIICatchExtraBall` on contact, and they are held in a queue rather than stopped
    /// dead - that path has its own ordering to preserve and is not what was reported.
    func catchStickyBallBeforeStep() {
        let delta = GameScene.stickyLookahead
        guard stickyPaddleCatches != 0, ballIsOnPaddle == false else { return }
        guard let body = ball.physicsBody, body.velocity.dy < 0 else { return }
        // Descending only: a ball on its way up through the paddle's line is leaving, not
        // arriving, and catching it would take it back

        guard let before = ballStateBeforeStep[ObjectIdentifier(ball)] else { return }

        let paddleTop = paddle.position.y + paddleHeight/2
        let ballBottom = before.position.y - ball.size.height/2
        guard ballBottom > paddleTop else { return }
        // Already at or past the surface: this step is not the one that arrives, and the
        // ordinary contact path can have it

        let fall = -before.velocity.dy*CGFloat(delta)
        guard ballBottom - fall <= paddleTop else { return }
        // Not landing this step

        // Where it lands, rather than where it is now: at speed the ball crosses a good part of
        // its own width in a frame, and the band it is judged against is only a paddle wide
        let share = (ballBottom - paddleTop)/max(fall, 0.0001)
        let landingX = before.position.x + before.velocity.dx*CGFloat(delta)*share

        let paddleX = gameMode == .endlessII
            ? endlessIIPaddleXNearest(to: landingX) : paddle.position.x
        // The paddle copy this ball is landing on: the paddle itself, or its wrap-around
        // ghost on the far side, exactly as `paddleHit` decides it

        guard landingX > paddleX - paddle.size.width/2 + ball.size.width/3,
              landingX < paddleX + paddle.size.width/2 - ball.size.width/3 else { return }
        // The same band `paddleHit` judges a catch by, so a ball caught here and a ball caught
        // there are caught in the same places - the band is narrower than the paddle, and a
        // ball outside it must still bounce

        if endlessIIAimedStickyClock.isRunning || endlessIIAimedStickyOwedTurn {
            return
        }
        // Aimed Sticky owns the launch while it runs and catches anywhere on the top surface,
        // not just in the band. Its catch is a different thing and it happens on contact

        ball.position.x = landingX
        performStickyCatch()
        // Moved to where it was going before it is stopped, so it sticks where it would have
        // landed rather than where it happened to be when the frame began

        if soundsSetting {
            self.run(stickyPaddleHitSound)
        }
        // The contact never happens now, so the sound `paddleHit` would have played has to be
        // played here or the catch lands in silence
    }
}
