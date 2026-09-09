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
//  - **It goes round the sides, always.** Round 100 had it turn round at the wall instead, on
//    the reasoning that a field carrying on would have to lose the bricks that reached the
//    edge - and that is still true, which is why it wraps rather than carries on. What the
//    turn-round actually produced was not a sway but a shudder: *any* brick reaching a wall
//    turned the whole field round, and on a field that spans the width there is nearly always
//    a brick near an edge, so it reversed every second or two and travelled about half a cell
//    each way. Measured in play, round 167: direction flipping at 1-2 second intervals and the
//    field never moving more than 22 points. James asked for bricks that "slowly drift from
//    left to right or right to left", which is travel, and travel needs somewhere to go. So
//    the doorway Wrap-Around opened is now open whenever Drift runs.
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

    /// How often the field moves over by one column.
    ///
    /// **A column at a time, not a slide** (James, round 209: "Drift shouldn't move sideways
    /// smoothly, it should go one column at a time, similar to how the bricks descend in
    /// endless mode"). The old version moved every brick a fraction of a cell every frame,
    /// which meant the field spent nearly all of its time *between* columns - and the grid is
    /// how the generator, the crush, the neighbour rules and a Spinning brick's clearance all
    /// speak (§8.6, in the other axis). Stepping puts the field back on the grid at the end of
    /// every step and leaves it there until the next one, so the thing the player is reading
    /// and the thing the code is reasoning about are the same thing far more of the time.
    ///
    /// 2.2 seconds is the old speed of 0.45 cells a second, kept: this round changes how the
    /// field moves, not how far it gets, so what James is judging is the one thing that
    /// changed.
    static let endlessIIDriftColumnSeconds: TimeInterval = 2.2

    /// How long the move itself takes, once it starts.
    ///
    /// **The descent's own number** (James, round 214: "Drift to use same animation speed and
    /// haptics and endless mode brick row descent"). `moveEndlessModeRowDown` covers a whole
    /// row in 0.05 seconds - a snap rather than a glide - and round 209's first pass at
    /// stepping picked 0.28 by eye, which read as a slide with pauses in it rather than as the
    /// field moving the way the field moves.
    static let endlessIIDriftSlideSeconds: TimeInterval = 0.05

    /// Starts the slide, in the direction the collected power-up names - or ends one already
    /// running the other way.
    ///
    /// **Two Drifts, one per direction** (James, round 201: "one that moves everything left to
    /// right and another that moves everything right to left"). The direction used to be a
    /// coin flip on first collection; it is the power-up's own identity now.
    ///
    /// **The opposite one cancels it** (round 223's matrix: "Drift left x Drift right: cancels
    /// out). Round 201 made it reverse the field and extend the clock instead - a dial rather
    /// than two coats of the same paint - which was a good answer to a question the matrix has
    /// since answered differently, and cancelling is the more honest one: these two are each
    /// other's opposite the way Expand and Shrink are, and those have cancelled since 2020.
    func endlessIICollectDrift(direction: Int) {
        guard gameMode == .endlessII else { return }

        if endlessIIDriftClock.isRunning, endlessIIDriftDirection != 0,
           endlessIIDriftDirection != direction {
            endlessIIDriftClock.reset()
            return
            // The tick sees a stopped clock on the next frame and runs `endEndlessIIDrift`,
            // which is what puts the half-slid column back on its grid. Cancelling by hand
            // here would leave the field between columns, and a brick between columns is a
            // brick on no row at all (§8.6)
        }

        endlessIIDriftClock.collect(GameScene.endlessIIDriftDuration)
        endlessIIDriftDirection = direction
    }

    /// Slides the field, once a frame. Called from `tickEndlessIIBricks`, before the movers
    /// take their own step, so a wandering brick wanders from where the drift has left it.
    func tickEndlessIIDrift(_ delta: TimeInterval) {
        guard gameMode == .endlessII else { return }

        guard endlessIIDriftClock.isRunning else {
            if endlessIIDriftDirection != 0 { endEndlessIIDrift() }
            return
        }

        endlessIIDriftPhase += delta

        var travelled: CGFloat = 0
        if endlessIIDriftMoved < brickWidth {
            let rate = brickWidth/CGFloat(GameScene.endlessIIDriftSlideSeconds)
            travelled = min(rate*CGFloat(delta), brickWidth - endlessIIDriftMoved)
            endlessIIDriftMoved += travelled
        }
        // Clamped against what is left of the column rather than simply added, so the step
        // covers exactly one cell however the frames fall - a step that overshot by a rounding
        // error every time would walk the whole field off the grid over a ten-second drift

        if endlessIIDriftPhase >= GameScene.endlessIIDriftColumnSeconds {
            endlessIIDriftPhase -= GameScene.endlessIIDriftColumnSeconds
            endlessIIDriftMoved = 0
            if hapticsSetting { lightHaptic.impactOccurred() }
            playMayhemSound("drift")
            // The descent's own tap, on the step rather than on the frames between: a row
            // arriving and a column moving are the same event to a thumb
            // Subtracted rather than zeroed, so a long frame does not throw away the overshoot
            // and let the cadence wander - the lesson Descent learned in round 172
        }

        guard travelled != 0 else { return }
        // Between steps the field is still, and still exactly on its columns

        let step = CGFloat(endlessIIDriftDirection)*travelled

        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard self.endlessIIStaysPut(node) == false else { return }
            // The rule the descent uses: an anchored brick is the one thing the field moves
            // around

            var x = node.position.x + step
            let half = (node as? SKSpriteNode)?.size.width ?? self.brickWidth
            if x - half/2 > self.gameWidth/2 { x -= self.gameWidth }
            if x + half/2 < -self.gameWidth/2 { x += self.gameWidth }
            // Out one side and in at the other, still travelling the same way. Shifted by the
            // field's whole width, which is a whole number of columns - so a brick that goes
            // round the side lands on a column centre rather than between two, and the cells
            // the generator and the crush speak in stay the cells everything else means
            node.position.x = x
        }

        enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            node.position.x += step
        }
        // The drops drift too, which is most of what makes the power-up feel like weather
        // rather than like the bricks misbehaving. They are not wrapped: a power-up that
        // vanished off one side and reappeared at the other is a drop the player has already
        // decided whether to chase
    }

    /// Puts every brick back on a column centre and forgets the direction.
    func endEndlessIIDrift() {
        endlessIIDriftDirection = 0
        endlessIIDriftPhase = 0
        endlessIIDriftMoved = 0
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
