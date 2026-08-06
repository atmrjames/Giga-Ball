//
//  EndlessIIStickyPaddle.swift
//  Megaball
//
//  A sticky paddle that holds more than one ball, in Endless 2.0 only.
//
//  The paddle has always held exactly one ball, because there has only ever been one. With
//  Multi-Ball there may be four, and a paddle that catches the first and bounces the rest is
//  a power-up that quietly stops working the moment another power-up is collected.
//
//  So the paddle holds a queue rather than a ball. Every ball that lands in the sticky band is
//  caught and sits where it landed; each launch tap sends the *oldest* one on its way, which is
//  the order they were caught in and the only order a player can predict. The rest keep waiting.
//
//  The first ball is in the queue too, rather than being handled beside it. It is the one the
//  rest of the game holds and the one `releaseBall` launches, but for the purpose of whose turn
//  it is it is simply the ball that was caught whenever it was caught - so a first ball caught
//  after an extra goes second, which is what "first caught goes first" has to mean.
//

import SpriteKit

extension GameScene {

    /// Whether the sticky paddle is holding anything beyond the first ball.
    var endlessIIHasHeldExtras: Bool {
        endlessIIHeldBalls.contains { $0 !== ball && $0.parent != nil }
    }

    /// Whose turn it is to launch.
    ///
    /// The head of the queue, skipping anything that has left the scene - a ball can be lost
    /// while the paddle is holding it if the paddle is driven out from under it by a portal or
    /// a wrap.
    var endlessIINextHeldBall: SKSpriteNode? {
        endlessIIHeldBalls.first { $0.parent != nil }
    }

    /// Whether a tap should launch a held extra rather than the first ball.
    ///
    /// The first ball resting on the paddle at the start of a life is not in the queue, so it
    /// launches as it always has. Once the queue has something in it, the queue decides.
    var endlessIITapLaunchesHeldBall: Bool {
        guard gameMode == .endlessII else { return false }
        guard let next = endlessIINextHeldBall else { return false }
        return next !== ball
    }

    /// Catches an extra ball on the sticky paddle.
    ///
    /// Returns whether it was caught, so the caller knows not to bounce it.
    @discardableResult
    func endlessIICatchExtraBall(_ extra: SKSpriteNode) -> Bool {
        guard gameMode == .endlessII, stickyPaddleCatches != 0 else { return false }
        guard endlessIIHeldBalls.contains(where: { $0 === extra }) == false else { return true }

        extra.physicsBody?.velocity = .zero
        extra.position.y = ballStartingPositionY
        endlessIIHeldBalls.append(extra)
        endlessIIHeldOffsets.append(extra.position.x - paddle.position.x)
        // Where on the paddle it landed, kept as an offset so it rides the paddle rather than
        // sitting still while the paddle moves out from under it - and so it launches at the
        // angle its own landing spot earns, exactly as the first ball does

        if paddleTexture == retroPaddle {
            paddleRetroStickyTexture.isHidden = false
        }
        return true
    }

    /// Notes that the first ball has been caught, so it takes its place in the queue.
    func endlessIIFirstBallWasCaught() {
        guard gameMode == .endlessII else { return }
        guard endlessIIHeldBalls.contains(where: { $0 === ball }) == false else { return }
        endlessIIHeldBalls.append(ball)
        endlessIIHeldOffsets.append(ball.position.x - paddle.position.x)
    }

    /// Takes a ball out of the queue as it launches.
    func endlessIIReleasedFromPaddle(_ launched: SKSpriteNode) {
        guard let index = endlessIIHeldBalls.firstIndex(where: { $0 === launched }) else { return }
        endlessIIHeldBalls.remove(at: index)
        endlessIIHeldOffsets.remove(at: index)
        endlessIIRefreshStickyPaddleLook()
    }

    /// Launches the oldest held extra.
    ///
    /// The launch angle comes from where it is sitting on the paddle, by the same rule the
    /// first ball's does - a ball caught at the edge leaves steeply and one caught in the
    /// middle leaves near enough straight up.
    func endlessIILaunchHeldBall() {
        guard let extra = endlessIINextHeldBall, extra !== ball else { return }

        let offset = Double((extra.position.x - paddle.position.x)/(paddle.size.width/2))
        let angle = endlessIILaunchAngle(atPaddleOffset: offset)
        extra.physicsBody?.velocity = CGVector(dx: cos(angle)*Double(ballSpeedLimit),
                                               dy: sin(angle)*Double(ballSpeedLimit))
        endlessIIReleasedFromPaddle(extra)
        spendStickyPaddleCatch()

        if soundsSetting { run(ballReleaseSound) }
        if hapticsSetting { lightHaptic.impactOccurred() }
    }

    /// The launch angle for a ball sitting at this fraction across the paddle.
    ///
    /// The same arithmetic `releaseBall` does for the first ball, written once so the two
    /// cannot drift apart - a held extra that launched by a different rule would be a
    /// different power-up depending on which ball you were watching.
    func endlessIILaunchAngle(atPaddleOffset offset: Double) -> Double {
        let clamped = min(max(offset, -1), 1)
        guard clamped != 0 else {
            return Bool.random()
                ? straightLaunchAngleRad + minLaunchAngleRad
                : straightLaunchAngleRad - minLaunchAngleRad
        }
        let multiplier: Double = clamped < 0 ? 1 : -1
        return straightLaunchAngleRad
            - ((maxLaunchAngleRad - minLaunchAngleRad)*clamped)
            + (minLaunchAngleRad*multiplier)
    }

    /// Keeps every held ball on the paddle as it moves.
    ///
    /// Per frame, because the paddle is under the player's finger. The first ball is left
    /// alone - the existing code has moved it with the paddle since 2020, and two things
    /// writing the same position is how a ball ends up jittering between them.
    func tickEndlessIIHeldBalls() {
        guard gameMode == .endlessII, endlessIIHeldBalls.isEmpty == false else { return }

        for (index, held) in endlessIIHeldBalls.enumerated() where held !== ball {
            guard held.parent != nil else { continue }
            let offset = endlessIIHeldOffsets.indices.contains(index) ? endlessIIHeldOffsets[index] : 0
            held.position.x = paddle.position.x + offset
            held.position.y = ballStartingPositionY
            held.physicsBody?.velocity = .zero
        }

        endlessIIDropHeldBallsThatLeft()
    }

    /// Forgets any held ball that is no longer in the scene.
    private func endlessIIDropHeldBallsThatLeft() {
        var index = 0
        while index < endlessIIHeldBalls.count {
            if endlessIIHeldBalls[index].parent == nil {
                endlessIIHeldBalls.remove(at: index)
                if endlessIIHeldOffsets.indices.contains(index) {
                    endlessIIHeldOffsets.remove(at: index)
                }
            } else {
                index += 1
            }
        }
    }

    /// Hides the sticky look once the paddle is holding nothing.
    private func endlessIIRefreshStickyPaddleLook() {
        guard endlessIIHasHeldExtras == false, ballIsOnPaddle == false else { return }
        if paddleTexture == retroPaddle {
            paddleRetroStickyTexture.isHidden = true
        }
    }

    /// Empties the paddle. For losing the life, resetting, and starting again.
    func endlessIIClearHeldBalls() {
        endlessIIHeldBalls.removeAll()
        endlessIIHeldOffsets.removeAll()
    }
}
