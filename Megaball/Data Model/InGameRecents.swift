//
//  InGameRecents.swift
//  Megaball
//
//  What this run has shown the player lately, for the reference pages reached mid-run.
//
//  The Bricks and Power-Ups pages exist to answer "what was that" - and the answer is
//  almost always about the thing that just happened, which a list in catalogue order
//  makes the player scan for. Opened from the pause menu, the pages lead with what was
//  recently seen instead (§12.0's play-test request): power-ups in recency order with
//  the unseen below, alphabetical; brick types recency-first within their sections.
//
//  The scene records; the pages ask. Ordering is pure functions on the recorded lists,
//  because ordering is the part worth pinning in tests.
//

import SpriteKit

final class InGameRecents {

    static let shared = InGameRecents()
    private init() {}

    /// One appearance of a power-up in play - a drop falling, or a power-up brick
    /// arriving. Each appearance is its own entry (play-test round 8: "if a power-up
    /// showed up multiple times show it multiple times"), newest first, with what became
    /// of that particular appearance.
    struct Sighting {
        let index: Int
        var fate: PowerUpFate
    }

    enum PowerUpFate { case seen, collected }

    private(set) var sightings: [Sighting] = []

    /// The indices in sighting order, duplicates and all - the pages' row source, and
    /// the dedupe set for the standard list below them.
    var powerUpIndices: [Int] { sightings.map(\.index) }

    /// What sat in a power-up brick when the pause menu opened - the same snapshot as
    /// the actives, marking those sightings BRICK.
    var brickHeldPowerUpIndices: Set<Int> = []

    /// What was running when the pause menu opened - the scene's snapshot, taken as the
    /// menu goes up, because "currently active" is a question about that moment and the
    /// reference pages have no scene to ask.
    var activePowerUpIndices: Set<Int> = []

    /// The same power-ups with their rings' readings, for the pause screen's copy of the HUD.
    ///
    /// Separate from the set above rather than replacing it, because the set answers "is this
    /// running" for the reference pages and this answers "how much is left" for a row of
    /// dials - and the first is asked far more often than the second.
    var activePowerUpRings: [(index: Int, remaining: CGFloat, segments: Int?)] = []

    /// What was still falling when the pause menu opened - the same snapshot. A drop
    /// mid-air is not missed, it is a decision the player has not made yet (play-test
    /// round 7).
    var fallingPowerUpIndices: Set<Int> = []

    /// Bricks destroyed this run, whichever path destroyed them - the game-over
    /// summary's count.
    private(set) var bricksDestroyedThisRun = 0

    func brickDestroyed() {
        bricksDestroyedThisRun += 1
    }

    /// The finished run's numbers, set by the scene as the game-over screen goes up -
    /// the screen and the detail page read, never compute. Grown to a proper record in
    /// round 8: the detail screen wants more than the game-over line shows.
    struct RunSummary {
        let height: Int
        let durationSeconds: Int
        let paddleHits: Int
        let bricksDestroyed: Int
        let ballsLost: Int
        let powerUpsSeen: Int
        let powerUpsCollected: Int

        /// What a classic run has instead of a height (play-test round 13): the score, and
        /// how far through the pack it got. Both are zero for an endless run, which is what
        /// the stats screen reads to decide which of the two headline figures it is showing.
        var score: Int = 0
        var levelsCleared: Int = 0
        var isEndless: Bool = true

        /// The most paddle hits one ball survived in this run (play-test round 37).
        var bestBallHits: Int = 0
    }
    var runSummary: RunSummary?

    /// Brick entry names (the catalogue's own), most recent first. Recorded on the strike,
    /// because a struck brick is the one the player is asking about.
    private(set) var brickNames: [String] = []

    func sawPowerUp(_ index: Int) {
        sightings.insert(Sighting(index: index, fate: .seen), at: 0)
    }

    func collectedPowerUp(_ index: Int) {
        if let position = sightings.firstIndex(where: { $0.index == index
                && $0.fate == .seen }) {
            sightings[position].fate = .collected
            // The newest uncaught appearance of it is the one that was caught
        } else {
            sightings.insert(Sighting(index: index, fate: .collected), at: 0)
        }
    }

    /// The note for one sighting (play-test request): active, still falling, sitting in
    /// a brick, collected, or missed - each earlier state the more current fact. The
    /// live states only apply to the newest appearance of an index; an older duplicate
    /// reads as the history it is.
    func statusNote(at position: Int) -> String {
        guard sightings.indices.contains(position) else { return "" }
        let sighting = sightings[position]
        let newest = sightings.firstIndex { $0.index == sighting.index } == position

        if sighting.fate == .collected {
            return newest && activePowerUpIndices.contains(sighting.index)
                ? "ACTIVE" : "COLLECTED"
        }
        if newest {
            if fallingPowerUpIndices.contains(sighting.index) { return "FALLING" }
            if brickHeldPowerUpIndices.contains(sighting.index) { return "BRICK" }
        }
        return "MISSED"
    }

    /// The note the run-stats page shows for a sighting given in oldest-first order.
    func statusNoteOldestFirst(at position: Int) -> String {
        statusNote(at: sightings.count - 1 - position)
    }

    /// The run's power-up highlights (play-test round 9): the superlatives, not the
    /// whole diary - most seen, most collected, most missed, each the index with the
    /// highest count and only where the count says something (two or more, or it is
    /// just "a thing that happened once" wearing a rosette).
    struct Superlative {
        let title: String
        let index: Int
        let count: Int
    }

    var superlatives: [Superlative] {
        var seen: [Int: Int] = [:]
        var collected: [Int: Int] = [:]
        var missed: [Int: Int] = [:]
        for sighting in sightings {
            seen[sighting.index, default: 0] += 1
            if sighting.fate == .collected {
                collected[sighting.index, default: 0] += 1
            } else {
                missed[sighting.index, default: 0] += 1
            }
        }

        var highlights: [Superlative] = []
        for (title, counts) in [("Most seen", seen), ("Most collected", collected),
                                ("Most missed", missed)] {
            if let top = counts.max(by: { $0.value < $1.value || ($0.value == $1.value
                    && $0.key > $1.key) }),
               top.value >= 2 {
                highlights.append(Superlative(title: title, index: top.key,
                                              count: top.value))
            }
            // Ties break to the lower index, so the same run always reads the same
        }
        return highlights
    }

    func struckBrick(named name: String) {
        brickNames.removeAll { $0 == name }
        brickNames.insert(name, at: 0)
    }

    /// A new run starts with nothing seen. Called as the run is set up, so a list opened
    /// mid-run never carries the last run's memory.
    func reset() {
        sightings = []
        activePowerUpIndices = []
        fallingPowerUpIndices = []
        brickHeldPowerUpIndices = []
        bricksDestroyedThisRun = 0
        runSummary = nil
        brickNames = []
    }

    /// The standard section's rows, with everything the Recent section already lists
    /// taken out (play-test round 7) - one list per power-up, not two.
    static func standardRows(rowCount: Int, recents: [Int],
                             powerUpIndex: (Int) -> Int) -> [Int] {
        let listed = Set(recents)
        return (0..<rowCount).filter { listed.contains(powerUpIndex($0)) == false }
    }

    // MARK: - Ordering

    /// The power-up page's row order: rows whose power-up was seen this run first, in
    /// recency order, then the rest alphabetical by name - "unseen power-ups below,
    /// alphabetical" is the request verbatim.
    static func rowOrder(rowCount: Int, recents: [Int],
                         powerUpIndex: (Int) -> Int, name: (Int) -> String) -> [Int] {
        let rows = Array(0..<rowCount)
        let byIndex = Dictionary(uniqueKeysWithValues:
                                    rows.map { (powerUpIndex($0), $0) })

        let seen = recents.compactMap { byIndex[$0] }
        let seenSet = Set(seen)
        let unseen = rows.filter { seenSet.contains($0) == false }
            .sorted { name($0) < name($1) }
        return seen + unseen
    }

    /// A section's entry order: recently struck first, the rest in the order the
    /// catalogue gives them - a reference keeps its own order where recency has nothing
    /// to say.
    static func entryOrder(names: [String], recents: [String]) -> [Int] {
        let seen = recents.compactMap { name in names.firstIndex(of: name) }
        let seenSet = Set(seen)
        return seen + names.indices.filter { seenSet.contains($0) == false }
    }
}

extension GameScene {

    /// Everything running right now, as recents indices - the pause menu's snapshot.
    ///
    /// The tray bars answer for the original power-ups: a lit bar means its *family* is
    /// running (each slot covers a good-and-bad pair), and the family member seen most
    /// recently is the one that was caught. Mayhem's own power-ups answer precisely,
    /// through their clocks.
    func activeRecentPowerUpIndices() -> Set<Int> {
        var active: Set<Int> = []

        let families: [[Int]] = [[2, 3], [4, 5], [15, 16], [6], [7], [20, 21], [22],
                                 [26, 27]]
        // Tray slot order: ball speed, paddle size, hidden bricks, sticky, gravity,
        // Giga/Undestructi-Ball, lasers, ball size - the same order iconArray holds
        for (slot, bar) in iconTimerArray.enumerated()
        where bar.isHidden == false && bar.xScale > 0.001
            && families.indices.contains(slot) {
            if let seen = InGameRecents.shared.powerUpIndices
                .first(where: { families[slot].contains($0) }) {
                active.insert(seen)
            } else if families[slot].count == 1 {
                active.insert(families[slot][0])
            }
        }

        if backstopCatches > 0 { active.insert(25) }
        // The Backstop has no tray bar - the wall itself is the indicator - so the
        // catches it has left are the only place "still in play" is written down
        // (play-test round 9: it read as COLLECTED while visibly standing there)

        guard gameMode == .endlessII else { return active }
        let clocks: [(EndlessIIClock, Int)] = [
            (endlessIIAimedStickyClock, 31), (endlessIIMagnetismClock, 32),
            (endlessIIPortalPaddleClock, 33), (endlessIIPaddleHaloClock, 34),
            (endlessIIBallSteeringClock, 35), (endlessIIInertPaddleClock, 36),
            (endlessIIFlippedAngleClock, 37), (endlessIIReversedControlsClock, 38),
            (endlessIIWreckingBallClock, 42), (endlessIIAuraClock, 43),
            (endlessIIDescentClock, 45), (endlessIIAutoAimClock, 46),
            (endlessIIWrapAroundClock, 47), (endlessIIRandomisedBounceClock, 51),
            (endlessIIGhostBallClock, 52), (endlessIIClearAndRetreatClock, 40),
            (endlessIISafetyPaddleClock, 53),
            (endlessIIDriftClock, 54), (endlessIIPaddleSurfaceClock, 55),
            (endlessIIDoublePaddleClock, 59),
        ]
        for (clock, index) in clocks where clock.isRunning { active.insert(index) }
        InGameRecents.shared.activePowerUpRings = clocks
            .filter { $0.0.isRunning }
            .map { (index: $0.1, remaining: $0.0.fraction, segments: nil) }
        // The rings the pause screen redraws. Mayhem's clocks carry a fraction already; the
        // original tray power-ups are added by the caller from their bars, which is the only
        // place that reading exists
        if endlessIITrajectoryRemaining > 0 { active.insert(29) }
        if endlessIILandingRemaining > 0 { active.insert(30) }
        return active
    }

    /// Tells the recents what kind of brick was just struck, in the catalogue's names.
    ///
    /// Behaviour from the texture, styles from the brick's own list, size from the
    /// sprite's geometry - the sizes are baked into the node at creation (an anchor and
    /// an offset body, §8.6), so geometry is the one place a node still says which it is.
    func recordBrickRecents(_ brick: SKSpriteNode) {
        guard brick.texture != brickNullTexture else { return }

        let behaviour: EndlessIIBehaviour
        switch brick.texture {
        case brickMultiHit1Texture, brickMultiHit2Texture,
             brickMultiHit3Texture, brickMultiHit4Texture:
            behaviour = .multiHit
        case brickIndestructible1Texture:
            behaviour = .indestructibleOnce
        case brickIndestructible2Texture:
            behaviour = .indestructibleAlways
        case brickInvisibleTexture:
            behaviour = .invisible
        default:
            behaviour = .standard
        }
        InGameRecents.shared.struckBrick(named: BrickTypeCatalogue.name(of: behaviour))

        for style in endlessIIStyles(on: brick) {
            InGameRecents.shared.struckBrick(named: BrickTypeCatalogue.name(of: style))
        }

        if brick.size.width > brickWidth*1.5 {
            InGameRecents.shared.struckBrick(named: BrickTypeCatalogue.name(of: .big))
        } else if brick.size.width < brickWidth*0.75 {
            InGameRecents.shared.struckBrick(named: BrickTypeCatalogue.name(of: .tiny))
        }
        // The normal size goes unrecorded on purpose: "you just hit an ordinary-sized
        // brick" identifies nothing
    }
}
