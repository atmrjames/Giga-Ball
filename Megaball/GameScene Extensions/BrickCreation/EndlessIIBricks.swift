//
//  EndlessIIBricks.swift
//  Megaball
//
//  The brick behaviours Endless 2.0 adds, applied on top of an ordinary brick rather than
//  replacing it.
//
//  The game identifies a brick's *type* by its texture - normal, multi-hit, indestructible,
//  invisible - and everything from scoring to destruction reads that. These three are not
//  types in that sense: a spinning brick is still a normal brick worth a normal score. So
//  they are applied as behaviour to a brick that already has its type, which means none of
//  the existing scoring, collision or destruction code needs to know they exist.
//
//  That is also what keeps them out of the other modes. Nothing calls this except the
//  Endless 2.0 generation path.
//
//  Note on why none of this uses SKActions. `countBricks()` decides whether a row move is
//  underway by asking every brick `hasActions()`, and a row is only generated once no brick
//  is moving. A brick running a repeating spin or flash would answer yes for ever, so the
//  field would descend once and then stop. These are driven from the scene's update instead,
//  which also means they stop when the game is paused without anything having to pause them.
//

import SpriteKit

/// A brick that comes and goes, and is only solid while it is there.
/// A brick that shrinks and swells where it stands.
///
/// It keeps its node exactly where it is and changes only its own size, which is what makes
/// it safe: `position.y` is how the rest of the game knows a brick's row (§8.6), and a brick
/// that breathed by moving would be in a different row twice a second.
///
/// The swell stops at the cell it was given. Growing past that would need the cells around it
/// kept clear the way a Spinning brick's are, and a brick that grew into an occupied cell
/// would be sitting inside its neighbour - so the room it breathes in is the room it owns.
struct EndlessIIBreather {
    let brick: SKSpriteNode
    /// The size it was created at, which is the largest it ever gets.
    ///
    /// The room it fills in the field, not its sprite's size - a shaped brick's sprite is
    /// tucked inside its own silhouette and is a third of a cell (`endlessIIFieldSize`).
    let full: CGSize
    /// Seconds for one full shrink and swell.
    let period: TimeInterval
    /// Seconds into that cycle. Staggered at birth, or a whole row would breathe in unison.
    var phase: TimeInterval
    /// The size the body was last built at, so it is only rebuilt when it is worth it.
    var bodyScale: CGFloat

    /// How large it may get, as a multiple of a cell.
    ///
    /// **A brick may breathe up through the size classes** (James, round 175: "breathing bricks
    /// can go from one size class to any other size class including down to nothing"), so the
    /// ceiling is no longer the size it was born at - it is whatever the space around it allows,
    /// worked out once when the breather is made and never larger than a Big brick.
    static let largest: CGFloat = 2

    /// How small it gets: nothing at all.
    ///
    /// It was half a cell - a Tiny brick's size, so a size the field already read as a brick.
    /// Round 175 took it to nothing, which is the other end of "any size class": the brick
    /// disappears for the moment at the bottom of the breath and comes back. Below
    /// `solidBelow` it carries no body, the same arrangement a Flashing brick has in its
    /// passable phase - and for one extra reason, that `SKPhysicsBody(rectangleOf:)` hands back
    /// nothing at all for an empty rectangle, which would be a brick you cannot see and cannot
    /// hit either.
    static let smallest: CGFloat = 0

    /// The scale below which the brick is a picture rather than a brick.
    static let solidBelow: CGFloat = 0.12

    /// How far the scale must travel before the body is rebuilt.
    ///
    /// The sprite changes every frame and the body follows in steps, because a body is
    /// rebuilt rather than resized and doing it sixty times a second for every breathing
    /// brick on the field is a lot of work to be a tenth of a brick more accurate.
    static let bodyStep: CGFloat = 0.08

    /// The largest this one may actually reach, in multiples of its birth size.
    ///
    /// One, unless there was room to grow. Held per breather rather than asked of the field each
    /// frame: the neighbours change constantly, and a brick that started breathing to twice its
    /// size should not stop halfway through a breath because something arrived beside it - it
    /// would look like the brick being interrupted rather than like the field being crowded.
    var ceiling: CGFloat = 1

    /// The scale at a moment in the cycle: smallest, up to its ceiling, and back.
    func scale(at moment: TimeInterval) -> CGFloat {
        let turn = moment/period*2*Double.pi
        let eased = (1 - cos(turn))/2
        // A cosine rather than a triangle: it pauses at each end, which is what makes it
        // read as breathing rather than as pumping
        return EndlessIIBreather.smallest
            + (ceiling - EndlessIIBreather.smallest)*CGFloat(eased)
    }
}

struct EndlessIIFlasher {
    let brick: SKSpriteNode
    let solidFor: TimeInterval
    let passableFor: TimeInterval
    /// Seconds into the cycle: solid, fade out, passable, fade back in.
    var phase: TimeInterval
    /// Seconds to leave the brick alone for. A new row fades itself in, and writing alpha
    /// every frame from the moment it appears would fight that - one brick popping into a
    /// row that is still arriving.
    var warmUp: TimeInterval = 0.6

    static let fade: TimeInterval = 0.2
    /// Not fully transparent. A brick you cannot see at all is one you cannot plan around.
    ///
    /// High enough that the green still shows. Lower than this and the brick goes muddy
    /// brown against the purple field, which reads as a different kind of brick rather than
    /// as this one ghosted.
    static let passableAlpha: CGFloat = 0.35
    /// Where the fade back in stops, short of solid.
    ///
    /// It has to stop short. Becoming solid is the one step that can be held - the brick
    /// waits rather than materialising around the ball - and if the fade had already
    /// finished, a held brick would sit there looking solid while the ball sailed through
    /// it. Ending here means full opacity and solidity always arrive together.
    static let returningAlpha: CGFloat = 0.75

    var cycle: TimeInterval { solidFor + EndlessIIFlasher.fade + passableFor + EndlessIIFlasher.fade }

    /// How the brick should look and behave part-way through its cycle.
    ///
    /// Solid only while it is fully opaque. It stops being solid the instant it starts
    /// fading, and does not become solid again until it has finished fading back - so at
    /// every moment in between, what the player sees is what the ball will do.
    func state(at phase: TimeInterval) -> (solid: Bool, alpha: CGFloat) {
        let fade = EndlessIIFlasher.fade
        let faded = EndlessIIFlasher.passableAlpha
        let fadingOutAt = solidFor
        let passableAt = fadingOutAt + fade
        let fadingInAt = passableAt + passableFor

        let returning = EndlessIIFlasher.returningAlpha

        switch phase {
        case ...fadingOutAt:
            return (true, 1)
        case ..<passableAt:
            return (false, 1 + (faded - 1)*CGFloat((phase - fadingOutAt)/fade))
        case ..<fadingInAt:
            return (false, faded)
        default:
            let progress = min(1, (phase - fadingInAt)/fade)
            return (false, faded + (returning - faded)*CGFloat(progress))
        }
    }
}

/// A brick that turns on the spot.
struct EndlessIISpinner {
    let brick: SKSpriteNode
    /// Radians per second, signed for direction.
    let rate: CGFloat
}

extension GameScene {

    /// How often an ordinary brick gains one of these behaviours instead of staying plain.
    ///
    /// Deliberately low. These are meant to punctuate a field rather than fill it, and the
    /// right number is a play-testing question.
    static let endlessIIBehaviourChance = 12

    /// Clamped so a frame the app spent in the background does not advance every flashing
    /// brick through several cycles at once.
    private static let maximumTickInterval: TimeInterval = 1.0/20.0

    // MARK: - The best so far

    /// The best this mode has seen, from the mode's own runs.
    ///
    /// Each endless mode keeps its own list. Reading the other one's would show an Endless 2.0
    /// player a best they set in a different game.
    var endlessBestHeight: Int? {
        guard let stats = totalStatsArray.first else { return nil }
        return gameMode == .endlessII
            ? stats.endlessIIHeights.max()
            : stats.endlessModeHeight.max()
    }

    /// Puts the player's best height under the current one, or takes it away if there is none.
    ///
    /// Every place that used to hide this label in endless mode calls this instead. Showing it
    /// once at level load was not enough: the states show and hide the whole HUD row as play
    /// starts and as the pause menu closes, and each of those hid it again a third of a second
    /// after it appeared.
    ///
    /// It reuses the multiplier label, which endless mode hides because it has no multiplier -
    /// so this costs no new node and inherits a position that is already right. Smaller and
    /// dimmer than the live figure, because it is the thing you glance at rather than the
    /// thing you are watching.
    func showEndlessIIBest() {
        guard endlessMode else { return }
        // Both endless modes. A best height is the thing a run is measured against, and the
        // original mode wanted it for exactly the same reason - it was only ever here because
        // this is where it was written
        guard isDailyChallenge == false else {
            multiplierLabel.isHidden = true
            return
        }
        // A daily is measured against today's board, not the campaign's best - the figure
        // is a different game's (play-test note), and §9 keeps the two apart both ways
        guard let best = endlessBestHeight, best > 0 else {
            multiplierLabel.isHidden = true
            return
        }
        // No best yet - a first run has nothing to be measured against, and the label goes
        // back to being the one endless mode does not use

        multiplierLabel.isHidden = false
        clearPlacedDigits(from: multiplierLabel)
        multiplierLabel.text = "HI-SCORE \(best)m"
        multiplierLabel.fontSize = fontSize*0.7
        multiplierLabel.horizontalAlignmentMode = .right
        multiplierLabel.fontColor = UIColor(white: 1, alpha: 0.45)
        multiplierLabel.position.x = scoreLabel.position.x
        multiplierLabel.position.y = scoreLabel.position.y - fontSize*1.2

        refreshEndlessIIBest()
        // **And straight back to the news if the run has already beaten it** (James, round 312:
        // "when pausing and resuming with a New Best score, the New Best label returned to the
        // previous best"). This function is what a resume calls, and it writes the old figure
        // unconditionally - so the label reverted and stayed reverted until the next metre
        // ticked over and `refreshEndlessIIBest` fired again. Asking it here closes the gap
    }

    /// Clears it once the run passes it. Beating your best should feel like it happened.
    func refreshEndlessIIBest() {
        guard endlessMode, multiplierLabel.isHidden == false else { return }
        guard let best = endlessBestHeight else { return }
        guard endlessHeight > best || endlessBestBeaten else { return }
        endlessBestBeaten = true
        // **Sticky for the run** (round 312). Two things can make the live comparison stop
        // being true after it has once been true: a resume that restores the label before the
        // height, and the run's own figure reaching the stored bests - `endlessBestHeight` is
        // `runs.max()`, and an autosave that files this run puts its height in that list. Once
        // a run has beaten the best it has beaten it, and the HUD should not take that back

        clearPlacedDigits(from: multiplierLabel)
        multiplierLabel.text = "NEW HI-SCORE"
        multiplierLabel.fontColor = brickGreenGigaball
        // Left showing rather than removed - the run is now writing the number that will be
        // sitting there next time
    }

    // MARK: - Power-up schedule

    /// Takes back the introduction schedule the run was playing with.
    ///
    /// **Before anything reads it.** The schedule decides which styles and power-ups this run
    /// has met (§6.3), so a field rebuilt against a freshly drawn one would be stocked
    /// differently from the field the player left - round 150's lesson at the level of the
    /// rules rather than the bricks. It matters more since a run's opening set, its pace and
    /// its weighting vary too: a redraw is not a reordering, it is a different game.
    ///
    /// A save written before the schedule existed carries none, and keeps the one drawn at
    /// launch - which is exactly what those runs always did.
    /// The schedule a new run starts on.
    ///
    /// **A daily's is drawn from the day** (James, round 258: "Is there a way to make sure the
    /// endless mayhem in the daily challenge is still random for everyone, but the element
    /// introduction for that game's day is similar, so the challenge for everyone is similar
    /// so the leaderboard is fair?").
    ///
    /// Yes, and this is the whole of it, because the two halves were already separate. What a
    /// run *knows* is the schedule - which elements it has met, in what order, at what pace -
    /// and what a run *is* is the field, rolled brick by brick as it descends. Seeding the
    /// schedule from the date makes everybody's day the same shape without touching a single
    /// roll the field makes: two players on the same day meet the same things at the same
    /// depths, and neither one's field is the other's.
    ///
    /// It is the day's key that seeds it and nothing else, so practice runs are the same day
    /// as the scoring attempt. A player who practises is practising the day they will play.
    func endlessIIFreshSchedule() -> EndlessIIProgression {
        guard let day = DailyChallengeSession.shared.active?.dateKey else {
            return EndlessIIProgression.make()
        }
        var stream = DailySeededGenerator(seed: DailyDay.seed(forKey: day) &+ 0xE2E2)
        // Its own offset in the seed space, like every other stream the day draws - a shared
        // one would tie the schedule to whatever else that stream had already been asked for,
        // so adding a twist would silently redraw everybody's elements

        var schedule = EndlessIIProgression.make(using: &stream)
        let daily = DailyChallengeSession.shared.active
        schedule.everythingAtOnce = daily?.has(.fullDeck) == true
            || daily?.has(.levelPegging) == true
        schedule.flatRarity = daily?.has(.levelPegging) == true
        // The day's two disclosure twists, applied to the schedule rather than to the field:
        // Full Deck opens the whole queue at the first metre and leaves rarity alone, and
        // Level Pegging does that and levels the rarity too. The schedule is still drawn from
        // the day either way, so the run under the twist is the same run for everybody
        return schedule
    }

    func adoptEndlessIISchedule(from savedGame: SavedGame) {
        guard let schedule = savedGame.endlessIIProgression else { return }
        endlessIIProgression = schedule
    }

    /// Damps the power-ups a run has not been introduced to yet.
    ///
    /// Applied on top of whatever the allocation tables decided rather than replacing them,
    /// so every authored weight and every level-specific tweak still holds - this only says
    /// how much of that weight is available at this depth.
    ///
    /// Never to zero. A weight of one is the difference between a power-up somebody might
    /// meet in their first run and one they certainly will not.
    func applyEndlessIIPowerUpSchedule() {
        guard gameMode == .endlessII else { return }
        let progression = endlessIIProgression

        if progression.flatRarity {
            for index in powerUpProbArray.indices where powerUpProbArray[index] > 0 {
                powerUpProbArray[index] = 100
            }
            // **Level Pegging** (§4): "all elements have equal rarity". The authored weights
            // are the rarity - a Get A Life is written as a rare thing and a Points Bonus as a
            // common one - so levelling them is the twist, and it is done here rather than in
            // the schedule because here is where they are read.
            //
            // Only the ones already above zero: a weight of zero means "this power-up is not
            // in this mode at all", which is a different statement from "this one is rare",
            // and a twist about rarity must not put Classic's own drops into Mayhem
        }

        for index in powerUpProbArray.indices where powerUpProbArray[index] > 0 {
            let scale = progression.powerUpWeightScale(for: index, at: endlessHeight)
            guard scale < 1 else { continue }
            powerUpProbArray[index] = max(1, Int((Double(powerUpProbArray[index])*scale).rounded()))
        }
        powerUpProbSum = powerUpProbArray.reduce(0, +)
        // Recomputed here because the draw divides by this, and a sum left over from before
        // the damping would make every weight mean something slightly different
    }

    // MARK: - Generating

    /// Picks what a single cell of a new Endless 2.0 row holds.
    ///
    /// Two questions, in order: is there a brick here at all, and if so what kind. Density
    /// and composition are separate because they change at different rates - the field stops
    /// getting fuller around 500m, and carries on getting stranger for another 500 after
    /// that.
    func endlessIIBrickTexture() -> SKTexture {
        let progression = endlessIIProgression
        guard Double.random(in: 0..<1) < progression.density(at: endlessHeight,
                                                             phase: endlessIIPhase) else {
            return brickNullTexture
        }

        switch endlessIIPhaseBehaviour ?? progression.pickBehaviour(at: endlessHeight) {
        case .multiHit: return endlessIIMultiHitTexture()
        case .indestructibleOnce: return brickIndestructible1Texture
        case .indestructibleAlways: return brickIndestructible2Texture
        case .invisible: return brickInvisibleTexture
        case .standard: return brickNormalTexture
        }
    }

    /// How often a designed pattern starts, when nothing else has the generator busy.
    static let endlessIISetRowChance = 7

    /// How often a cluster starts, when nothing else has the generator busy.
    ///
    /// Higher than a set row's chance, because a cluster is a smaller event: a set row decides
    /// what the whole next row is, where a cluster is a thing sitting in a row that is
    /// otherwise whatever it was going to be.
    static let endlessIIClusterChance = 11

    /// Takes the next row of a designed pattern, starting one if it is time.
    ///
    /// Returns nil for an ordinary generated row, which is most of them.
    ///
    /// Clusters and set rows share this queue and everything downstream of it. A cluster is
    /// written as a small shape and expanded here into full-width rows whose every other
    /// column is `?` - "whatever the generator would have put there" - so the field carries on
    /// either side of it. That one character is the whole difference between the two, and it
    /// is why a cluster needs no new pipeline: the reservation guard, the height gating and
    /// the row-to-texture mapping all already do the right thing.
    /// **Queued last row first, so a shape appears the way it is written** (round 249).
    ///
    /// The field descends: `moveEndlessModeRowDown` takes everything down a row and the new one
    /// is built at a fixed y at the top. So the row emitted *first* ends up *lowest*, and a
    /// queue drained from the front was laying every formation out upside down.
    ///
    /// It went unnoticed because most of the catalogue is symmetrical - a ring, a cross, a
    /// diamond and a chequer look the same either way up - and because the shapes that are not
    /// still looked deliberate. What gave it away is that six of them say which way up they go
    /// and were all saying the opposite of what the field drew: the Anvil's "indestructible lid
    /// with the field's own bricks underneath it" had its lid at the bottom, the Vault's lid
    /// was under the thing it was meant to be lidding, and Pillars had bricks hanging off the
    /// tops of its posts rather than below them.
    ///
    /// Both catalogues have always said "top row first" in their own documentation, so the
    /// shapes were authored correctly and the queue was reading them backwards.
    func endlessIINextSetRow(reservationPending: Bool) -> String? {
        guard gameMode == .endlessII else { return nil }

        if endlessIISetRowQueue.isEmpty {
            guard reservationPending == false else { return nil }
            // A Big brick or a spinner is already shaping this row and the next. Two things
            // arranging the same cells would leave neither shape intact

            if Int.random(in: 1...100) <= GameScene.endlessIIClusterChance,
               let queued = endlessIIStartCluster() {
                endlessIIQueueFormation(rows: queued.rows, legend: queued.legend)
            } else {
                guard Int.random(in: 1...100) <= GameScene.endlessIISetRowChance else {
                    return nil
                }
                let choices = endlessIIProgression.setRows(at: endlessHeight)
                // This run's shapes, not every shape gated at this height: set rows join the
                // introduction schedule like the styles and power-ups do (round 193), so two
                // runs to the same depth meet different landmarks
                guard let pattern = choices.randomElement() else { return nil }
                endlessIIQueueFormation(rows: pattern.rows, legend: pattern.legend)
            }
        }
        let row = endlessIISetRowQueue.removeFirst()
        endlessIIBookFormationShape()
        if endlessIISetRowQueue.isEmpty { endlessIISetRowLegend = [:] }
        // Cleared as the last row goes out, so a legend can never be read by the formation
        // after this one - the character `A` means something different in every shape
        return row
    }

    /// Puts a formation in the queue, in the order the field has to emit it.
    ///
    /// **This is the one place the reversal happens, and it is a function so that it can be
    /// tested through.** Round 249's bug was that the queue was filled in written order and
    /// drained from the front, which drew every formation upside down; the fix was two
    /// `.reversed()` calls at two assignment sites, and a test that seeds the queue itself
    /// cannot tell whether either of them is still there. A test can call this.
    ///
    /// The rule it carries: **the row written first is emitted last.** The field descends -
    /// everything moves down a row and the new one is built at a fixed y at the top - so the
    /// row emitted first ends up lowest, and the top row of a drawn shape has to go out last
    /// to land at the top.
    func endlessIIQueueFormation(rows: [String], legend: [Character: EndlessIIBrickSpec]) {
        endlessIISetRowQueue = rows.reversed()
        endlessIISetRowLegend = legend
    }

    /// Books a two-row brick that the *next* row of this formation asks for.
    ///
    /// A Big brick spans two rows and a Square brick spans two, so neither can be built when
    /// its turn comes: one row leaves the cells empty and the next builds down into them. Rows
    /// are emitted bottom-first (round 249), so the row that reserves is emitted *before* the
    /// row the brick is drawn on - which means the booking has to be made by looking one row
    /// ahead in the queue.
    ///
    /// That the queue holds the whole formation is what makes this possible at all: a rolled
    /// shape has to guess a row in advance, and a drawn one is already written down.
    ///
    /// **Square was the size that could be asked for and never arrived** (round 253). Round
    /// 250 taught this to book a Big brick and round 251 wrote two formations out of squares,
    /// and nothing in between joined them up: a cell asking for `.square` validated, built,
    /// and came out as an ordinary oblong. It is the same sequence and the same slot, so it is
    /// the same function - which is why this one asks about *size* rather than about Big.
    ///
    /// **Only when nothing else is pending.** A row either reserves or builds, and the
    /// generator's own roll for this row has already happened by the time a formation row is
    /// asked for. Where the two collide the formation's brick is simply not built and its cell
    /// is left empty - one brick missing from a shape, rather than two shapes arranging the
    /// same cells and neither surviving.
    func endlessIIBookFormationShape() {
        guard endlessIIPendingBookings.isEmpty,
              let next = endlessIISetRowQueue.first else { return }

        var taken: Set<Int> = []
        for column in 0..<numberOfBrickColumns {
            let spec = endlessIISetRowSpec(next, column: column)
            let build: EndlessIITwoRowBuild
            switch spec.size {
            case .big:
                guard EndlessIIBigBrick.fits(leftColumn: column,
                                             columns: numberOfBrickColumns) else { continue }
                build = .big(leftColumn: column)
            case .square:
                build = .square(column: column)
            case .tiny, .normal, nil:
                continue
                // A Tiny brick needs none of this - it is one brick split where it already
                // stands - and the other two are what a cell is by default
            }

            let wanted = build.columnsToReserve(in: numberOfBrickColumns)
            guard wanted.isDisjoint(with: taken) else { continue }
            taken.formUnion(wanted)
            endlessIIPendingBookings.append(EndlessIIBooking(build, spec: spec))
            // **All of them, not the first** (round 254). A row held one shape until the
            // booking became a list, so a formation drawn with three posts across it built one
            // and drew the other two as ordinary bricks. Overlapping cells are still refused,
            // because two bricks in one place is the one thing the reservation exists to stop
        }
    }

    /// Picks a cluster and a column for it, and writes it out as rows.
    func endlessIIStartCluster() -> (rows: [String], legend: [Character: EndlessIIBrickSpec])? {
        guard let picked = EndlessIICluster.pick(at: endlessHeight,
                                                 roll: { Int.random(in: 0..<$0) }) else {
            return nil
        }
        let cluster = picked.materialised(fieldWidth: numberOfBrickColumns,
                                          pick: { Int.random(in: 0..<$0) })
        // A scatter rolls its arrangement here, at placement - the same one is a different
        // field every time it lands. A drawn cluster passes through unchanged
        let places = EndlessIICluster.placements(width: cluster.width,
                                                 in: numberOfBrickColumns)
        guard let column = places.randomElement() else { return nil }
        return (cluster.expanded(atColumn: column, fieldWidth: numberOfBrickColumns),
                cluster.legend)
    }

    /// Gives a two-row brick whatever the formation that booked it asked for.
    ///
    /// A Big or Square brick is built by its own function from the field's own mix, which is
    /// right for the generator's rolls and wrong for a drawn one: a formation asking for a
    /// multi-hit Big brick was getting a standard one, with nothing to say it had not.
    ///
    /// **The size is already right** - the booking is what made the brick two rows tall - so
    /// what is left is the behaviour and the styles, and those go through the same pass every
    /// other designed brick uses. `endlessIIStaysPlain` keeps the generator's own styling off
    /// it, exactly as for the ordinary cells of the same shape.
    ///
    /// Does nothing when no formation booked the shape, which is most rows.
    func endlessIIDressBookedShape(_ brick: SKSpriteNode, as spec: EndlessIIBrickSpec?) {
        guard let spec else { return }

        brick.texture = endlessIIBrickTexture(for: spec)
        brick.colorBlendFactor = brick.texture == brickNormalTexture ? 1 : 0
        brick.isHidden = brick.texture == brickInvisibleTexture
        brick.endlessIIStaysPlain = true
        if spec.isPlain == false { endlessIIDesignedSpecs.append((brick, spec)) }
        // The spec keeps its size and that is safe: the only size the styling pass acts on
        // is `.tiny`, which it splits into four, and a brick that reached here was booked
        // because it was Big or Square
    }

    /// What a designed row asks for in one of its columns.
    ///
    /// The formation's own key first and the shared alphabet after, which is the whole of what
    /// a legend is (`EndlessIIBrickSpec`).
    func endlessIISetRowSpec(_ row: String, column: Int) -> EndlessIIBrickSpec {
        EndlessIIBrickSpec.spec(for: EndlessIISetRow.character(in: row, column: column),
                                legend: endlessIISetRowLegend)
    }

    /// The texture a spec's behaviour calls for.
    ///
    /// Nil behaviour is `?` - the field's own mix - which is the one case that draws rather
    /// than reads. An empty cell is the null texture, which the row cleanup removes.
    func endlessIIBrickTexture(for spec: EndlessIIBrickSpec) -> SKTexture {
        guard spec.isEmpty == false else { return brickNullTexture }
        switch spec.behaviour {
        case .standard: return brickNormalTexture
        case .multiHit: return endlessIIMultiHitTexture()
        case .indestructibleOnce: return brickIndestructible1Texture
        case .indestructibleAlways: return brickIndestructible2Texture
        case .invisible: return brickInvisibleTexture
        case nil: return endlessIIBrickTexture()
        }
    }

    /// How many hits a multi-hit brick should take, and the picture that says so.
    ///
    /// **The textures count up, not down.** `BrickMultiHit4` is one hit from gone and
    /// `BrickMultiHit1` is four, because a hit steps the picture *forward* until the brick is
    /// destroyed. So a brick that takes n hits starts at `MultiHit(5 - n)`, and Mayhem's
    /// multi-hit brick starting at `MultiHit3` has always meant **two hits**.
    ///
    /// James, round 258: "Multi bricks should start from level 2 (2 hits to destroy). Level 3
    /// and level 4 (3 and 4 hits to destroy) should be considered new elements." So two hits
    /// is what the mode opens with, as it always has, and three and four arrive from the
    /// introduction queue like anything else - which is also the first time either has existed
    /// in this mode at all.
    ///
    /// Rarity is applied on top, and deliberately falls away with the tier: a field of
    /// four-hit bricks is a wall, and the point of the deeper tiers is that one of them in a
    /// row is a brick worth thinking about.
    func endlessIIMultiHitTexture() -> SKTexture {
        var offered: [(hits: Int, weight: Int)] = [(2, 100)]
        for (index, hits) in EndlessIIElement.multiHitTiers.enumerated() {
            guard endlessIIProgression.hasArrived(.multiHit(hits: hits),
                                                  at: endlessHeight) else { continue }
            offered.append((hits, index == 0 ? 45 : 20))
        }

        let total = offered.reduce(0) { $0 + $1.weight }
        var remaining = Int.random(in: 0..<max(1, total))
        var hits = 2
        for tier in offered {
            remaining -= tier.weight
            if remaining < 0 { hits = tier.hits; break }
        }

        switch hits {
        case 4: return brickMultiHit1Texture
        case 3: return brickMultiHit2Texture
        default: return brickMultiHit3Texture
        }
    }

    /// Gives every designed brick built this row exactly what its legend asked for.
    ///
    /// **Run after the generator's own styling passes, and reaching bricks those passes will
    /// not touch.** A designed brick carries `endlessIIStaysPlain`, so `applyEndlessIIStyles`
    /// skips it - which is the point rather than an obstacle to work around. A shape somebody
    /// arranged should not then be handed a random spinner, and the styles it *does* wear are
    /// the ones written beside it in the catalogue.
    ///
    /// Nothing here asks `endlessIICanTake`. The legend was put to the compatibility rules when
    /// it was authored (`EndlessIIBrickSpecTests`), which is the right moment: a brick refused
    /// here would leave a hole in a shape somebody drew, silently, at some depth in some run.
    func applyEndlessIIDesignedSpecs(to bricks: inout [SKNode]) {
        guard gameMode == .endlessII else { return }
        defer { endlessIIDesignedSpecs.removeAll() }

        for (brick, spec) in endlessIIDesignedSpecs where brick.parent != nil {
            if spec.size == .tiny {
                bricks.append(contentsOf: Array(makeTiny(brick).dropFirst()) as [SKNode])
                continue
                // **Split first and last.** `makeTiny` turns the brick into the bottom-left
                // quarter and builds three more beside it, and the three join the row so the
                // count and the arrival animation see them - exactly as a Tiny brick the
                // generator made. Nothing else on the spec is applied: every style a
                // quarter-cell brick cannot carry is refused when the legend is authored
                // (`styleRefusesSize`), and the ones it *can* carry would have to be put on
                // all four quarters or on none, which is a decision this format has not been
                // asked to make yet. A formation asking for a Tiny brick gets four Tiny bricks
            }
            if let mirrored = spec.mirrored { brick.endlessIIFaceMirrored = mirrored }
            if let flipped = spec.flipped { brick.endlessIIFaceFlipped = flipped }
            if let side = spec.side { brick.endlessIIVulnerableSide = side }
            // Written on before the styles that read them. `makeFace` keeps an orientation the
            // brick already carries rather than rolling one, and `makeDirectional` keeps a side
            // - both bargains made for the resume path (rounds 154 and 174), and both exactly
            // what a legend needs: this is a shape being told which way it faces

            if let shape = spec.shape { applyEndlessIIStyle(shape, to: brick) }
            for action in spec.actions { applyEndlessIIStyle(action, to: brick) }
            // Shape first. It rewrites the sprite's size and anchor, and every action drawn
            // over it measures itself against the room the brick fills - which is a question
            // `endlessIIFieldSize` can only answer once the face is on
        }
    }

    /// Moves the run on to the next phase when the current one has run its length.
    ///
    /// A uniform phase settles what it is made of once, here, rather than per brick - that
    /// is the whole point of it. Everything else clears those choices so the ordinary mix
    /// resumes.
    func advanceEndlessIIPhase() {
        guard gameMode == .endlessII else { return }
        guard endlessHeight >= endlessIIPhaseEndsAt else { return }

        let phase = endlessIIProgression.pickPhase(at: endlessHeight)
        endlessIIPhase = phase
        endlessIIPhaseEndsAt = endlessHeight
            + Int.random(in: EndlessIIPhase.shortest...EndlessIIPhase.longest)

        endlessIIPhaseBehaviour = nil
        endlessIIPhaseStyles = []
        guard phase.isUniform else { return }

        switch phase {
        case .monoculture:
            endlessIIPhaseBehaviour = endlessIIProgression.pickBehaviour(at: endlessHeight)
        case .motif:
            // A pair that can actually share a brick, drawn from what this depth offers
            let first = endlessIIProgression.pickStyle(from: EndlessIIStyle.allCases,
                                                       at: endlessHeight)
            let partners = EndlessIIStyle.allCases.filter { first?.stacksWith($0) == true }
            let second = endlessIIProgression.pickStyle(from: partners, at: endlessHeight)
            endlessIIPhaseStyles = [first, second].compactMap { $0 }
        default:
            break
        }
    }


    // MARK: - Applying

    /// What a brick is, as the rest of the game understands it.
    ///
    /// Read from the texture rather than stored, because the texture is where every other
    /// part of the game keeps this and two copies of the same fact would eventually differ.
    func endlessIIBehaviour(of brick: SKSpriteNode) -> EndlessIIBehaviour? {
        switch brick.texture {
        case brickNormalTexture: return .standard
        case brickMultiHit1Texture, brickMultiHit2Texture,
             brickMultiHit3Texture, brickMultiHit4Texture: return .multiHit
        case brickIndestructible1Texture: return .indestructibleOnce
        case brickIndestructible2Texture: return .indestructibleAlways
        case brickInvisibleTexture: return .invisible
        default: return nil
        }
    }

    /// At most two. Three is not ruled out by the compatibility grid, but a brick doing
    /// three things is one nobody can read at a glance, and legibility is what makes the
    /// combinations fun rather than noisy.
    static let endlessIIMaximumStyles = 2

    /// Which size class a brick belongs to, by the room it fills.
    ///
    /// The field size rather than the sprite's, so a shaped brick is the ordinary cell it fills
    /// rather than the third of one its sprite hides in (`endlessIIFieldSize`).
    func endlessIISizeOf(_ brick: SKSpriteNode) -> BrickSize {
        let size = endlessIIFieldSize(of: brick)
        if size.width > brickWidth*1.5 { return .big }
        if size.height > brickHeight*1.5 { return .square }
        if size.width < brickWidth*0.75 { return .tiny }
        return .normal
        // **Width first, then height.** A Big brick is two cells on both axes, so asking about
        // its height first would call it Square - and Square is the one size that is taller
        // than it is wide, which is exactly what the old width-only test could not see
    }

    /// Whether a brick sits in exactly one cell - true of an ordinary brick and of a Tiny
    /// one, false of a Big one.
    func occupiesOneCell(_ brick: SKSpriteNode) -> Bool {
        let size = endlessIIGeometry.footprint(of: endlessIIFieldSize(of: brick))
        return size.columns == 1 && size.rows == 1
    }
    // The *field* size, not the sprite's: a shaped brick's sprite is tucked inside its own
    // silhouette and is about a third of a cell across

    /// Which styles a brick is already wearing.
    ///
    /// Worked out from the brick and the lists that drive it rather than kept as a separate
    /// record, so there is no second copy of the truth to fall out of step with the first.
    func endlessIIStyles(on brick: SKSpriteNode) -> [EndlessIIStyle] {
        var found: [EndlessIIStyle] = []
        if brick.childNode(withName: GameScene.roundedBrickOutlineName) != nil {
            found.append(.rounded)
        }
        if let face = brick.endlessIIFace { found.append(face.style) }
        if endlessIISpinners.contains(where: { $0.brick === brick }) { found.append(.spinning) }
        if endlessIIFlashers.contains(where: { $0.brick === brick }) { found.append(.flashing) }
        if endlessIIBreathers.contains(where: { $0.brick === brick }) { found.append(.breathing) }
        switch brick.endlessIIRole {
        case .gravity: found.append(.gravity)
        case .moving: found.append(.moving)
        case .directional: found.append(.directional)
        case .exploding: found.append(.exploding)
        case .spawner: found.append(.spawner)
        case .portal: found.append(.portal)
        case .fixed: found.append(.fixed)
        case nil: break
        }
        return found
    }

    /// How many bricks on the field currently wear this style.
    ///
    /// Walks the field on purpose - see `endlessIICanTake`'s Fixed case for why a counter
    /// would be the wrong shape. Asked only when a style with a cap is being considered, which
    /// is rare, and the field is at most a few hundred nodes.
    func endlessIIBricksCarrying(_ style: EndlessIIStyle) -> Int {
        var count = 0
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            if self.endlessIIStyles(on: brick).contains(style) { count += 1 }
        }
        return count
    }

    /// Whether a brick can take a style on top of what it already is.
    ///
    /// Three separate questions. Whether the style suits the behaviour is a design rule and
    /// lives in `EndlessIIStyle.suits`. Whether it stacks with what the brick already wears
    /// is another, in `stacksWith`. Whether this particular sprite can carry it is a
    /// mechanical one: Rounded and Spinning both assume a sprite centred on its node, which
    /// a Big brick's is not.
    func endlessIICanTake(_ style: EndlessIIStyle, _ brick: SKSpriteNode) -> Bool {
        guard brick.endlessIIStaysPlain == false else { return false }
        guard let behaviour = endlessIIBehaviour(of: brick) else { return false }

        let worn = endlessIIStyles(on: brick)
        guard worn.count < GameScene.endlessIIMaximumStyles else { return false }
        guard worn.allSatisfy({ $0.stacksWith(style) }) else { return false }

        if style == .portal, endlessIIHasPortal() { return false }
        if style == .portal {
            // Portal does not need to find an Indestructible brick, it makes one: it takes
            // the behaviour over, because "a hit does nothing" is part of what a Portal is.
            // Everything else has to fit the behaviour already there.
            return behaviour != .invisible
        }
        guard style.suits(behaviour) else { return false }
        guard style.suits(endlessIISizeOf(brick)) else { return false }
        // The size half, asked of `EndlessIIStyle` rather than restated here - so the reference
        // page and the generator can never give different answers (round 240)

        let centred = brick.endlessIIFace != nil
            || (abs(brick.anchorPoint.x - 0.5) < 0.01
                && abs(brick.anchorPoint.y - 0.5) < 0.01)
        // **A shaped brick counts as centred**, and it is the one exception worth making. The
        // question this asks is "does the drawing sit on the node", because a Big brick's
        // does not - and a shaped brick's anchor is off-centre for the opposite reason: the
        // sprite has been moved *into* the silhouette, which is itself centred on the node.
        // The Wedge is the only face that actually moves it, and a Wedge that could not turn
        // would be the one shape excluded from spinning by an accident of where its sprite
        // hides (round 235)
        switch style {
        case .rounded, .diamond: return centred || endlessIISizeOf(brick) == .square
            // **And a Square one**, since round 270 - James drew a rounded picture of every
            // brick type at Square proportions, and `suits(_ size:)` has always said Rounded
            // fits any size. All that stood in the way was this mechanical question, and the
            // answer changed when `makeRounded` learned to build its face around the sprite.
            // A Big brick is still out: its drawing is two cells wide as well as tall, and
            // there is no picture of it
        case .convex, .concave, .wedge, .spinning, .breathing:
            return centred
            // The size these three demand is answered above, by the rule they share with the
            // reference page. What is left is whether the drawing sits on the node, which is a
            // question about a *particular* brick rather than about its size class - a Big
            // one's sprite hangs off its node on purpose (§8.6)
        case .fixed:
            return endlessIIBricksCarrying(.fixed) < GameScene.endlessIIFixedBrickCap
            // **At most three on screen at once** (James, round 305: "the number of fixed
            // bricks on screen at any time should be limited. Let's say 3 is the maximum. If
            // there are 3 on screen, then no more can be added at that time").
            //
            // A Fixed brick anchors where it stands and destroys whatever descends onto it, so
            // each one is a hole punched in the field's descent. Three is a hazard; a dozen is
            // a wall the field cannot get past, and the run stops being about the ball.
            //
            // Counted from the field rather than tracked in a counter, because a brick can
            // leave in more ways than it can arrive - destroyed, exploded by a neighbour,
            // Culled, Wiped, cleared with its row - and a counter that missed one of those
            // would drift until it forbade the fourth Fixed brick for the rest of the run.
        case .gravity:
            // And never in a column a spinner is in. A falling brick stops on whatever is
            // below it, and a spinner's cell reads as empty to that check because the spinner
            // is not *in* the cells it sweeps - so the faller would come to rest inside a
            // turning brick. The spinner's clearance is kept clear of arrivals from the side
            // already; this is the same rule for arrivals from above
            let column = endlessIICell(of: brick).column
            return endlessIISpinners.contains {
                $0.brick.parent != nil && endlessIICell(of: $0.brick).column == column
            } == false
        case .directional:
            // **Never a brick with no way in** (James, round 233: a directional brick should
            // not "be penned in" by Indestructible bricks). A soft face needs somewhere the
            // ball can reach it from, and a brick walled in on all four sides has nowhere at
            // all - so it stays the plain brick it already is rather than becoming a second
            // Indestructible that looks destructible. The role is declined here rather than
            // fudged in `makeDirectional`, because a brick that cannot carry a style should
            // not carry it: refusing leaves the brick free to draw a different one
            return endlessIIOpenSides(from: brick).isEmpty == false
        case .moving: return true
        default: return true
        }
    }

    /// Gives each new brick one of the appearance styles, sometimes.
    ///
    /// Any behaviour can take any of these now, so a Multi-hit brick can flash and an
    /// Indestructible one can turn. Spinning is applied by the generator instead, because
    /// it is the one style that needs cells reserved around it.
    ///
    /// Called after the row's arrival animation has been set up, because that animation
    /// resets the colour blend on every normal brick and would undo the tinting here.
    func applyEndlessIIBehaviours(to bricks: [SKNode]) {
        applyEndlessIIStyles([.rounded, .flashing, .breathing], to: bricks)
        // A style has to be in a pool to exist at all (§8.6), which is the trap this line
        // exists to avoid. The shapes used to be in this one, beside Rounded
    }

    /// Gives each new brick a shaped face, sometimes - its own pass, because shape is its own
    /// axis.
    ///
    /// **This is what "two axes" actually means** (James, on the 2026 brick workbook). Shrinking
    /// `refusedByAFace` says a shaped brick *may* also fall, wander, anchor, turn or breathe;
    /// it does not make one. `applyEndlessIIStyles` offers a brick one style from the pool it
    /// is handed, so while the shapes sat in the appearance pool a brick could have a shape
    /// *or* be Breathing and never both - the combination would have been legal, unreachable,
    /// and indistinguishable from very rare.
    ///
    /// First of the three passes, so the shape is the thing a brick is offered while it is
    /// still plain. The two-style cap then leaves it room for exactly one more, which is the
    /// point of the cap: a brick doing three things is one nobody can read at a glance.
    ///
    /// **This does make shaped bricks more common**, and that is not a side effect to be
    /// tuned away - they had been sharing one roll with Rounded, Flashing and Breathing, and
    /// an axis that has to win a raffle against the other axis is not a separate axis.
    func applyEndlessIIShapes(to bricks: [SKNode]) {
        applyEndlessIIStyles([.convex, .concave, .wedge, .diamond], to: bricks)
    }

    /// Offers each brick a style from a pool, at whatever rate the run's depth calls for.
    ///
    /// The depth ramp lives here rather than in each style, so the two pools - the ones that
    /// change how a brick looks and the ones that change what it does to the field - get the
    /// same treatment without agreeing on anything.
    func applyEndlessIIStyles(_ pool: [EndlessIIStyle], to bricks: [SKNode]) {
        guard gameMode == .endlessII else { return }

        let progression = endlessIIProgression
        let height = endlessHeight

        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }

            // A brick already carrying something has to clear the stacking roll as well.
            // Both are chances rather than gates, so a stack is possible from the first
            // metre and simply unlikely
            let alreadyStyled = endlessIIStyles(on: brick).isEmpty == false
            var chance = alreadyStyled
                ? progression.stackChance(at: height)
                : dailyStyledChance(progression.styleChance(at: height))
            // A Extra Mayhem day multiplies the *first* style's chance and leaves stacking
            // alone - the twist is more bricks doing something, not more bricks doing two
            // things at once
            if endlessIIPhaseStyles.isEmpty == false { chance = 85 }
            // A motif phase is the motif. Running it at the ordinary rate would produce a
            // stretch of plain bricks with the occasional themed one, which is not a phase
            guard Int.random(in: 1...100) <= chance else { continue }

            let offered = endlessIIPhaseStyles.isEmpty
                ? pool
                : pool.filter { endlessIIPhaseStyles.contains($0) }
            // A motif phase only offers what the motif is, so a whole stretch wears the same
            // pair rather than each brick drawing its own
            guard offered.isEmpty == false else { continue }

            guard let wanted = progression.pickStyle(from: offered, at: height),
                  endlessIICanTake(wanted, brick) else { continue }
            applyEndlessIIStyle(wanted, to: brick)
        }
    }

    func applyEndlessIIStyle(_ style: EndlessIIStyle, to brick: SKSpriteNode) {
        switch style {
        case .rounded: makeRounded(brick)
        case .spinning: makeSpinning(brick)
        case .flashing: makeFlashing(brick)
        case .breathing: makeBreathing(brick)
        case .gravity: makeGravity(brick)
        case .moving: makeMoving(brick)
        case .directional: makeDirectional(brick)
        case .exploding: makeExploding(brick)
        case .spawner: makeSpawner(brick)
        case .portal: makePortal(brick)
        case .fixed: makeFixed(brick)
        case .convex, .concave, .wedge, .diamond:
            if let face = style.face { makeFace(face, on: brick) }
        }
        endlessIIDressStyleMarks(on: brick)
        // After every style rather than inside each: styles stack in either order, and the
        // overlay a brick wears depends on everything it now is (round 321)
    }

    /// Sets a brick turning, at the shape and size it already is.
    ///
    /// A static body follows its node's rotation, so the bounce genuinely changes with the
    /// angle - which is the whole point, and only interesting because the thing turning is
    /// oblong. It used to shrink to a square so its corners could not reach the rows above
    /// and below, and that read as a different, smaller kind of brick rather than as a
    /// familiar one behaving strangely. The room it needs comes from the generator leaving
    /// its four neighbouring cells empty instead - see `endlessIISpinnerClearance`.
    func makeSpinning(_ brick: SKSpriteNode) {
        let direction: CGFloat = Bool.random() ? 1 : -1
        let secondsPerTurn = CGFloat.random(in: 2.5...4.5)
        endlessIISpinners.append(EndlessIISpinner(brick: brick,
                                                  rate: direction*(.pi*2)/secondsPerTurn))
    }

    /// How far a turning brick reaches, in cells.
    ///
    /// A brick twice as wide as it is tall sweeps a circle of radius √5/2 ≈ 1.12 cell
    /// heights, so the cell above, the cell below and both side cells have to be empty.
    static let endlessIISpinnerClearance = 1

    /// Fades a brick out and back, solid only while it is visible.
    ///
    /// Each state is held for a couple of seconds with a quick transition between, so it
    /// reads as a brick that comes and goes rather than one that flickers ambiguously.
    /// Tinted with the Giga-Ball glow so it is recognisable while it is still solid.
    func makeFlashing(_ brick: SKSpriteNode) {
        // **No green tint** (round 321): its overlay says Flashing now, and it was the Giga-Ball
        // green so it could be recognised while solid, which is the job the overlay has taken

        let inStep = endlessIIPhase.flashesInStep
        endlessIIFlashers.append(EndlessIIFlasher(brick: brick,
                                                  solidFor: inStep ? 2.5
                                                      : .random(in: 2.0...3.0),
                                                  passableFor: inStep ? 2.0
                                                      : .random(in: 1.5...2.5),
                                                  phase: inStep ? 0 : .random(in: 0...2)))
        // Staggered starts, or a whole row would breathe in unison.
        //
        // **Which is exactly what a Static phase wants** (§6.2). The stagger is three numbers -
        // when it starts, how long it is solid, how long it is passable - and all three have to
        // agree or the field drifts back out of step within a few blinks. So a Static phase
        // fixes the two durations as well as the phase, and the field opens and closes as one
        // thing: a rhythm to play to rather than a field to read
    }

    static let breathingBrickColour = UIColor(red: 0.95, green: 0.45, blue: 0.85, alpha: 1)

    /// Sets a brick breathing: shrinking to half a cell and swelling back, for ever.
    ///
    /// The interest is in the gap it opens and closes. A shot that was blocked a second ago
    /// goes through now, and a ball that would have missed is caught on the way back out -
    /// so it is a brick you time rather than one you aim at.
    func makeBreathing(_ brick: SKSpriteNode) {
        // No pink tint (round 321) - its overlay says Breathing now
        endlessIIBreathers.append(
            EndlessIIBreather(brick: brick, full: endlessIIFieldSize(of: brick),
                              period: .random(in: 2.2...3.2),
                              phase: .random(in: 0...3.2),
                              bodyScale: 1,
                              ceiling: endlessIIBreathingCeiling(for: brick)))
        // Staggered starts and slightly different periods, so a row of them ripples rather
        // than pulsing as one animal
    }

    /// How far a breathing brick may grow without ending up inside a neighbour.
    ///
    /// **"Ensure there is enough space around the brick so it doesn't overlap a neighbouring
    /// brick when it grows"** (James, round 175). A brick that swells into the cell beside it
    /// leaves two bricks in one place, which is the phantom-brick shape this project has spent
    /// rounds chasing: one picture and two bodies.
    ///
    /// Asked of the cells around it rather than of frames, because the cell is what the field
    /// speaks in - and asked once, at birth, so a breath is not interrupted halfway by a row
    /// arriving beside it (see `ceiling`).
    ///
    /// One when it is hemmed in, which is what every breathing brick did before this - so a
    /// crowded field looks exactly as it did, and only a brick with room takes it.
    func endlessIIBreathingCeiling(for brick: SKSpriteNode) -> CGFloat {
        guard gameMode == .endlessII else { return 1 }
        guard brickWidth > 0, brickHeight > 0, numberOfBrickColumns > 0 else { return 1 }
        // No grid yet, so no neighbours to measure against - and asking anyway divides by a
        // zero cell size, which reaches `Int(_:)` as an infinity and traps. A brick built
        // before the field has proportions keeps to its own cell, which is the old behaviour
        let cell = endlessIICell(of: brick)
        let occupied = endlessIIOccupancy()

        for step in stride(from: CGFloat(2), to: 1, by: -0.5) {
            let reach = Int((step - 1).rounded(.up))
            var clear = true
            for column in (cell.column - reach)...(cell.column + reach) {
                for row in (cell.row - reach)...(cell.row + reach)
                where !(column == cell.column && row == cell.row) {
                    let neighbours = occupied[EndlessIICell(column: column, row: row)] ?? []
                    if neighbours.contains(where: { $0 !== brick }) { clear = false }
                }
            }
            if clear { return min(step, EndlessIIBreather.largest) }
        }
        return 1
    }

    /// Rounds a brick's corners - the same oblong shape, not a circle.
    ///
    /// It was a circle, and a circle is a different brick: it reads as something new sitting
    /// where a brick should be, and it throws the ball off even on a square-on hit along
    /// what looks like a flat edge. Rounded corners keep every straight hit exactly as it
    /// has always been and change only the glancing ones near a corner, which is the
    /// interesting part.
    ///
    /// The face is a rounded-rectangle shape filled with the brick's own colour and, since
    /// round 153, with a texture drawn as that shape (`endlessIIFaceFill`) - so a Multi-hit
    /// or Indestructible brick keeps its own look and only loses its corners. Before the art
    /// existed the fill was the brick's rectangular texture stretched into the path, which is
    /// still what happens for any brick with no drawn face. The sprite behind it is shrunk
    /// rather than hidden - hiding it would hide the face too, since that is its child - and
    /// shrunk by `size` rather than by scale, which children would inherit.
    func makeRounded(_ brick: SKSpriteNode) {
        let face = brick.size
        let radius = min(face.width, face.height)*GameScene.roundedBrickCornerFraction
        let centre = CGPoint(x: (0.5 - brick.anchorPoint.x)*face.width,
                             y: (0.5 - brick.anchorPoint.y)*face.height)
        let path = CGPath(roundedRect: CGRect(x: centre.x - face.width/2,
                                              y: centre.y - face.height/2,
                                              width: face.width, height: face.height),
                          cornerWidth: radius, cornerHeight: radius, transform: nil)
        // **Built around the drawing, not around the node** (round 270). The two are the same
        // point for an ordinary brick and a cell apart for a Square one, whose sprite hangs
        // below its node so the node can stay on a row centre. The body is made from this
        // path as well, so getting it wrong would have moved the brick you hit away from the
        // brick you see

        brick.physicsBody = brickBody(SKPhysicsBody(polygonFrom: path))
        // A rounded rectangle is convex, which is all a polygon body asks for

        let shape = SKShapeNode(path: path)
        shape.fillColor = brick.colorBlendFactor > 0.5 ? brick.color : .white
        shape.strokeColor = .clear
        shape.zPosition = 0.1
        shape.name = GameScene.roundedBrickOutlineName
        brick.addChild(shape)
        refreshEndlessIIBrickArt(brick)
        // Takes the Square overlay off in the same breath as putting the face on. It would
        // come off at the next refresh anyway, and a frame of a brick wearing both pictures is
        // a frame of the thing this is here to prevent

        if refreshEndlessIIFaceArt(brick, shape, .rounded, cell: face) == false {
            shape.fillTexture = endlessIIFaceFill(brick, nil)
        }
        // Drawn art goes on as a sprite that is told its size; anything with none falls back
        // to the shape's own fill, which lays the texture in at whatever size the file is
        // (see `drawEndlessIIFaceArt` - that is the bug this replaced)

        let fit = min(GameScene.roundedBrickHidingFraction,
                      GameScene.largestFraction(hidingInside: face, radius: radius)*0.99)
        // A hair inside rather than exactly on it. `largestFraction` answers where the corner
        // *touches* the arc, and a corner drawn on its own edge is a corner antialiasing shows
        // a pixel of. It costs an ordinary brick nothing - 0.8 less a hundredth is still above
        // the 0.78 it has always used, so that shape is untouched
        brick.size = CGSize(width: face.width*fit, height: face.height*fit)
        if brick.size.width > 0, brick.size.height > 0 {
            brick.anchorPoint = CGPoint(x: 0.5 - centre.x/brick.size.width,
                                        y: 0.5 - centre.y/brick.size.height)
        }
        // Small enough to sit entirely inside the rounded face, so no square corner shows -
        // and **shrunk about the drawing rather than about the anchor**, which is the second
        // half of the same bug. A sprite shrinks *towards* its anchor point, and a Square
        // brick's is on its top edge, so shrinking it walked the picture up out of the circle
        // and the corners came out through the top of the ring. Moving the anchor by the same
        // factor keeps `(0.5 - anchorPoint) * size` where it was, which is the expression the
        // face, the multi-hit bar and the resumed field all read the drawn centre off
    }

    /// How much of a brick's short side is taken up by each rounded corner.
    ///
    /// A half, so the two short ends are full semicircles and the brick is a stadium - round
    /// at the sides rather than merely softened at the corners.
    static let roundedBrickCornerFraction: CGFloat = 0.5

    /// How far the sprite behind a rounded face is shrunk, at most.
    ///
    /// It was this number on its own, and it was chosen for the stadium an ordinary brick makes
    /// - where it happens to be just inside the largest rectangle that fits. A Square brick's
    /// face is a **circle**, because the radius is half the short side and its sides are equal,
    /// and 0.78 of a square does not fit inside the circle around it: the render showed four
    /// corners of brick poking out through the ring.
    static let roundedBrickHidingFraction: CGFloat = 0.78

    /// The largest fraction of `face` that still sits entirely inside a rounded rectangle of
    /// that size with that corner radius.
    ///
    /// The corner of the shrunk rectangle is the only point that can escape, and it escapes
    /// through the corner arc - so this is where that corner meets the arc, which is one
    /// quadratic. Derived rather than tabulated, because the alternative is a second number to
    /// keep in step with `roundedBrickCornerFraction`, and the shape is the thing that decides.
    ///
    /// An ordinary 2:1 brick answers 0.8, which is why 0.78 was never wrong there and looked
    /// like a general number. A square one answers 1/√2.
    static func largestFraction(hidingInside face: CGSize, radius: CGFloat) -> CGFloat {
        let a = face.width/2, b = face.height/2
        let insetX = max(0, a - radius), insetY = max(0, b - radius)
        let square = a*a + b*b
        guard square > 0 else { return 1 }

        let linear = a*insetX + b*insetY
        let constant = insetX*insetX + insetY*insetY - radius*radius
        let discriminant = linear*linear - square*constant
        guard discriminant >= 0 else { return 1 }
        return (linear + sqrt(discriminant))/square
    }

    /// Keeps a rounded brick's face showing what the brick is.
    ///
    /// A Multi-hit brick steps down through four textures as it is hit, and the face is a
    /// separate node that would otherwise still be showing the first one.
    func refreshEndlessIIRoundedFaces() {
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode,
                  let shape = brick.childNode(withName: GameScene.roundedBrickOutlineName)
                    as? SKShapeNode else { return }
            let wantedColour = brick.colorBlendFactor > 0.5 ? brick.color : UIColor.white
            let cell = self.endlessIIFaceCell(brick, shape: shape)
            if self.refreshEndlessIIFaceArt(brick, shape, .rounded, cell: cell) == false {
                let wanted = self.endlessIIFaceFill(brick, nil)
                if shape.fillTexture !== wanted { shape.fillTexture = wanted }
            }
            if shape.fillColor != wantedColour, shape.fillTexture != nil {
                shape.fillColor = wantedColour
                // Colour as well as texture: a rounded brick that also picked up a role is
                // tinted after its face was built, and the face has to follow
            }
        }
    }

    /// The collision settings every brick body shares, so a replacement body behaves exactly
    /// like the one the generator built.
    func brickBody(_ body: SKPhysicsBody) -> SKPhysicsBody {
        body.allowsRotation = false
        body.friction = 0.0
        body.affectedByGravity = false
        body.isDynamic = false
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = CollisionTypes.brickCategory.rawValue
        body.collisionBitMask = CollisionTypes.laserCategory.rawValue
        body.contactTestBitMask = CollisionTypes.laserCategory.rawValue
        return body
    }

    // MARK: - Driving

    /// Advances the breathing bricks, **including while the aim is held**.
    ///
    /// James, twice: "during aimed sticky with the ball on the paddle, the breathing brick
    /// animation is still pausing." The aim hold freezes the world from `update` - the descent,
    /// the spinners, the movers and the timed clocks - because the play test caught the field
    /// stepping past a ball that was sitting on the paddle, and a player releasing into bricks
    /// that had moved since they aimed.
    ///
    /// Breathing is the exception, and it is the exception on the brick's own terms: "the
    /// interest is in the gap it opens and closes... a brick you time rather than one you aim
    /// at" (`makeBreathing`). Freezing it while the player lines up a shot removes the whole of
    /// what the brick is for, and a pulse that stops dead reads as the game having hung.
    ///
    /// A clock of its own rather than `endlessIILastTick`, which the hold pins to now every
    /// frame so that everything else resumes where it stopped. This one is allowed to keep
    /// running, and because each caller stamps it, the two cannot advance it twice in a frame.
    func tickEndlessIIBreathing(_ currentTime: TimeInterval) {
        guard gameMode == .endlessII else { return }

        let elapsed = currentTime - endlessIIBreathLastTick
        endlessIIBreathLastTick = currentTime
        guard gameState.currentState is Playing else { return }
        let delta = min(max(elapsed, 0), GameScene.maximumTickInterval)
        guard delta > 0 else { return }

        endlessIIBreathers.removeAll { $0.brick.parent == nil }
        for index in endlessIIBreathers.indices {
            advanceBreather(at: index, by: delta)
        }
    }

    /// Advances the spinning and flashing bricks. Called once a frame.
    func tickEndlessIIBricks(_ currentTime: TimeInterval) {
        guard gameMode == .endlessII else { return }

        let elapsed = currentTime - endlessIILastTick
        endlessIILastTick = currentTime
        guard gameState.currentState is Playing else { return }
        let delta = min(max(elapsed, 0), GameScene.maximumTickInterval)
        guard delta > 0 else { return }

        endlessIISpinners.removeAll { $0.brick.parent == nil }
        for spinner in endlessIISpinners {
            spinner.brick.zRotation += spinner.rate*CGFloat(delta)
        }

        endlessIIFlashers.removeAll { $0.brick.parent == nil }
        for index in endlessIIFlashers.indices {
            advanceFlasher(at: index, by: delta)
        }

        tickEndlessIIBreathing(currentTime)
        // Driven from here in the ordinary case, and from `update` directly while the aim is
        // held - see `tickEndlessIIBreathing` for why it is the one thing the hold does not
        // freeze. Its own clock, so the two callers cannot advance it twice in a frame

        endlessIIResolveAnchorOverlaps()
        // Before the drift and the roles move anything: a brick sharing space with an anchor
        // should not get another step out of it first

        tickEndlessIIDrift(delta)
        // Before the roles, so a wandering brick wanders from where the drift left it -
        // and both write the same x, so the order is the whole of their agreement
        tickEndlessIIRoles(delta)
        tickEndlessIIRescue(delta)
        refreshEndlessIIRoundedFaces()
        refreshEndlessIIShapedFaces()
        refreshEndlessIIAutoAimMarker()
        // Driven from the frame, never from an action on a brick (§8.6)
    }

    /// Clears the tracked bricks. For starting a run, not for a brick being destroyed -
    /// those drop out of the lists on their own once they leave the scene.
    func resetEndlessIIBricks() {
        endlessIISpinners.removeAll()
        endlessIIFlashers.removeAll()
        endlessIIBreathers.removeAll()
        endlessIIPendingBookings = []
        endlessIIMonolithRoute = nil
        endlessIIProgression = endlessIIFreshSchedule()
        clearEndlessIIMarkers()
        endlessIISetRowQueue = []
        endlessIISetRowLegend = [:]
        endlessIIPhase = .standard
        endlessIIPhaseEndsAt = 0
        endlessIIPhaseBehaviour = nil
        endlessIIPhaseStyles = []
        endlessIILastTick = 0
        resetEndlessIIRoles()
        endlessIIClearExtraBalls()
        // A run starts on one ball, whatever the last one ended on
    }

    private func advanceBreather(at index: Int, by delta: TimeInterval) {
        var breather = endlessIIBreathers[index]
        let brick = breather.brick

        let wasScale = breather.scale(at: breather.phase)
        var phase = breather.phase + delta
        if phase >= breather.period { phase -= breather.period }
        let scale = breather.scale(at: phase)

        if scale > wasScale, ballOverlaps(brick) {
            // Never grow into a ball. The flashing brick has the same rule for the same
            // reason: a body that arrives around a ball leaves the ball inside a brick, and
            // the physics answers that by flinging it somewhere arbitrary. Shrinking is
            // always allowed - a brick getting out of the ball's way harms nobody
            endlessIIBreathers[index] = breather
            return
        }

        breather.phase = phase
        let cell = CGSize(width: breather.full.width*scale,
                          height: breather.full.height*scale)
        let shaped = brick.endlessIIFace != nil
        if shaped {
            redrawEndlessIIFace(brick, to: cell)
            // A shaped brick breathes by rebuilding its silhouette rather than by having its
            // sprite resized: the sprite is only the marker hiding inside the shape, and
            // stretching *that* would have left a brick whose picture grew and whose outline
            // did not. The drawn half is cheap enough for every frame; the body below is not
        } else {
            brick.size = cell
        }

        if abs(scale - breather.bodyScale) >= EndlessIIBreather.bodyStep
            || (scale < EndlessIIBreather.solidBelow) != (brick.physicsBody == nil) {
            breather.bodyScale = scale
            let solid = scale >= EndlessIIBreather.solidBelow
            if shaped {
                rebuildEndlessIIFaceBody(brick, to: cell, solid: solid)
            } else {
                brick.physicsBody = solid ? brickBody(SKPhysicsBody(rectangleOf: brick.size))
                                          : nil
            }
            // Rebuilt in steps rather than every frame: a body cannot be resized, only
            // replaced, and the sprite is the thing the player is reading.
            //
            // **Nothing at the bottom of the breath.** A brick breathing down to nothing is a
            // brick that is not there for a moment, the way a Flashing brick is not there in
            // its passable phase - and `SKPhysicsBody(rectangleOf:)` returns nothing for an
            // empty rectangle anyway, so the alternative was a brick you cannot see and cannot
            // hit. The second half of the condition is what makes the body come *back* the
            // instant the breath rises past the line, whatever the step arithmetic says
        }
        endlessIIBreathers[index] = breather

    }

    private func advanceFlasher(at index: Int, by delta: TimeInterval) {
        var flasher = endlessIIFlashers[index]

        if flasher.warmUp > 0 {
            flasher.warmUp -= delta
            endlessIIFlashers[index] = flasher
            return
        }

        var phase = flasher.phase + delta

        if phase >= flasher.cycle {
            // About to become solid again. Not while the ball is inside it: turning the body
            // on underneath the ball leaves the ball buried in a brick, and the physics
            // resolves that by flinging it somewhere arbitrary. Holding just short of the
            // end of the cycle keeps it passable until the ball has gone.
            if ballOverlaps(flasher.brick) {
                phase = flasher.cycle - 0.001
            } else {
                phase -= flasher.cycle
            }
        }
        flasher.phase = phase
        endlessIIFlashers[index] = flasher

        let state = flasher.state(at: phase)
        flasher.brick.alpha = state.alpha
        setBrickSolid(flasher.brick, state.solid)
    }

    /// Whether the ball is close enough to the brick that making it solid would trap it.
    private func ballOverlaps(_ brick: SKSpriteNode) -> Bool {
        brick.frame.insetBy(dx: -ballSize/2, dy: -ballSize/2).contains(ball.position)
    }

    /// Turns a brick's collisions on and off without disturbing anything else about it.
    ///
    /// The name is left alone deliberately - the row descent and the brick count both find
    /// bricks by name, and a brick that is briefly passable is still part of the field.
    func setBrickSolid(_ brick: SKSpriteNode, _ solid: Bool) {
        guard let body = brick.physicsBody else { return }
        let wanted = solid ? CollisionTypes.brickCategory.rawValue : 0
        guard body.categoryBitMask != wanted else { return }
        body.categoryBitMask = wanted
        body.collisionBitMask = solid ? CollisionTypes.laserCategory.rawValue : 0
        body.contactTestBitMask = solid ? CollisionTypes.laserCategory.rawValue : 0
    }

    static let roundedBrickOutlineName = "endlessIIRoundedOutline"
}

extension GameScene {

    /// Puts something in a row that would otherwise be the third empty one in a row.
    ///
    /// Height in this mode is gained by clearing the bottom row, and a row with nothing in it
    /// is cleared the moment it arrives. So a run of empty rows is height for free - which
    /// sounds generous and is the opposite of it. The field rushes past, the player is deep
    /// before the mode has shown them anything, and the density that was meant to arrive
    /// gradually arrives all at once, because it is keyed to a height they reached in seconds.
    ///
    /// This is a floor rather than a change to the density curve. The opening is meant to be
    /// sparse and stays sparse; what it cannot be is *absent*, and one brick is the difference
    /// between a row that has to be played and a row that is not there.
    func endlessIIFillEmptyRowIfOverdue(_ row: [SKNode], reserved: Set<Int> = [],
                                        shapeComing: Bool = false) {
        guard gameMode == .endlessII else { return }

        guard shapeComing == false else {
            endlessIIEmptyRowRun = 0
            return
        }
        // A Big or power-up brick is about to be built into this row. It is added after this
        // runs, so the row looks empty from here and is not - filling it would put an ordinary
        // brick inside the shape's own footprint, which is what was found underneath a Big
        // brick after it broke

        let bricks = row.compactMap { $0 as? SKSpriteNode }
            .filter { $0.texture != brickNullTexture }

        guard bricks.isEmpty else {
            endlessIIEmptyRowRun = 0
            return
        }

        endlessIIEmptyRowRun += 1
        guard endlessIIEmptyRowRun > EndlessIIProgression.mostEmptyRowsInARow else { return }

        // One brick, somewhere in the middle two thirds. Against a wall it is easy to leave
        // alone, and leaving it alone is the thing this exists to stop
        let columns = max(1, numberOfBrickColumns)
        let margin = columns/6
        let candidates = row.compactMap { $0 as? SKSpriteNode }.filter { brick in
            let column = endlessIICell(of: brick).column
            guard reserved.contains(column) == false else { return false }
            // A cell kept clear is kept clear. These are the gap a shape from the next row
            // comes down into, or a spinner's clearance - a brick here is either buried
            // inside something else or in the way of something that turns
            return column >= margin && column < columns - margin
        }

        guard let chosen = candidates.randomElement()
                ?? row.compactMap({ $0 as? SKSpriteNode })
                      .first(where: { reserved.contains(endlessIICell(of: $0).column) == false })
        else { return }
        chosen.texture = endlessIIBrickTexture()
        if chosen.texture == brickNullTexture { chosen.texture = brickNormalTexture }
        // The mix this height would have produced, and an ordinary brick if that came up empty
        // as well - the point is that the row is not empty, not which brick it is

        chosen.color = brickWhite
        chosen.colorBlendFactor = 1.0
        endlessIIEmptyRowRun = 0
    }
}
