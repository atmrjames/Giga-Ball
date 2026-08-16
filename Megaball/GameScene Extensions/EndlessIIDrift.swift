//
//  EndlessIIDrift.swift
//  Megaball
//
//  Drift (§5.4): while it runs, the whole field slides sideways - bricks and falling
//  power-ups together.
//
//  James's idea from the tenth play test, pulled into 1.3 in round 100. What it is for is
//  simple: a field that will not hold still is a field you have to keep re-reading, and every
//  shot has to lead its target.
//
//  Three decisions the note left open, taken here and worth arguing with:
//
//  - **At the wall it turns round.** A field that carried on would have to lose the bricks
//    that reached the edge, and a power-up that quietly destroys part of the field is a
//    different power-up. So it sways: out to the wall, then back. Under Wrap-Around it does
//    carry on, because there the wall is a doorway and coming back in the other side is what
//    everything else does (§5.4, and the note asked for exactly this).
//  - **Anchored bricks stay put**, the same ones the descent leaves alone. A Fixed brick's
//    whole meaning is that it stopped where it was struck.
//  - **Everything lands back on a column centre.** The grid is how the generator, the crush
//    and the neighbour rules all speak; a field left half a column out would keep working by
//    rounding, and then one day it would not. When the clock stops, every brick snaps.
//

import SpriteKit

extension GameScene {

    /// How long the field drifts for.
    static let endlessIIDriftDuration: TimeInterval = 10

    /// How fast it slides, in cells a second.
    ///
    /// Slow. The point is that a shot has to lead its target by a little, not that the field
    /// is a moving walkway - at half a cell a second a brick has moved most of its own width
    /// by the time a ball crosses the field and back.
    static let endlessIIDriftSpeed: CGFloat = 0.45

    func endlessIICollectDrift() {
        guard gameMode == .endlessII else { return }
        endlessIIDriftClock.collect(GameScene.endlessIIDriftDuration)
        if endlessIIDriftDirection == 0 { endlessIIDriftDirection = Bool.random() ? 1 : -1 }
        // A second collection extends the drift rather than reversing it: the direction is
        // only chosen when there is no drift to join
    }

    /// Slides the field, once a frame. Called from `tickEndlessIIBricks`, before the movers
    /// take their own step, so a wandering brick wanders from where the drift has left it.
    func tickEndlessIIDrift(_ delta: TimeInterval) {
        guard gameMode == .endlessII else { return }

        guard endlessIIDriftClock.isRunning else {
            if endlessIIDriftDirection != 0 { endEndlessIIDrift() }
            return
        }

        let step = CGFloat(endlessIIDriftDirection)*GameScene.endlessIIDriftSpeed*brickWidth*CGFloat(delta)
        var turnAround = false

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard self.endlessIIStaysPut(node) == false else { return }
            // The rule the descent uses: an anchored brick is the one thing the field moves
            // around

            var x = node.position.x + step
            let half = (node as? SKSpriteNode)?.size.width ?? self.brickWidth
            if self.endlessIIWrapIsRunning {
                if x - half/2 > self.gameWidth/2 { x -= self.gameWidth }
                if x + half/2 < -self.gameWidth/2 { x += self.gameWidth }
                // Out one side and in at the other, still travelling the same way
            } else if x + half/2 > self.gameWidth/2 || x - half/2 < -self.gameWidth/2 {
                turnAround = true
                return
                // Held where it is this frame; the whole field turns round below, so the
                // ones that had room do not slide out of step with the one that did not
            }
            node.position.x = x
        }

        enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            node.position.x += step
        }
        // The drops drift too, which is most of what makes the power-up feel like weather
        // rather than like the bricks misbehaving

        if turnAround { endlessIIDriftDirection = -endlessIIDriftDirection }
    }

    /// Puts every brick back on a column centre and forgets the direction.
    func endEndlessIIDrift() {
        endlessIIDriftDirection = 0
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            node.position.x = self.endlessIIColumnCentre(nearest: node.position.x)
        }
        // Snapped rather than left where the clock stopped. Everything else in the mode
        // speaks in cells - the generator, the crush, a Spinning brick's clearance - and a
        // field sitting half a column out would keep working by rounding until the day it
        // did not (§8.6's own warning, in the other axis)
    }

    /// The centre of the column nearest a given x, which is where every brick belongs.
    func endlessIIColumnCentre(nearest x: CGFloat) -> CGFloat {
        guard brickWidth > 0 else { return x }
        let left = -gameWidth/2 + brickWidth/2
        let columns = ((x - left)/brickWidth).rounded()
        return left + columns*brickWidth
    }
}
