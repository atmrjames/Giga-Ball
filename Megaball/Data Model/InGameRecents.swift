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

    /// Power-up indices, most recent first. Recorded when one enters play - falling from
    /// a brick, or released by Mayhem's power-up brick - because "seen" is the question
    /// the page answers, not "caught".
    private(set) var powerUpIndices: [Int] = []

    /// What became of each seen power-up: caught, or fell past. The latest event wins -
    /// a fresh drop of something caught earlier reads as the drop it is.
    enum PowerUpFate { case seen, collected }
    private(set) var powerUpFates: [Int: PowerUpFate] = [:]

    /// What was running when the pause menu opened - the scene's snapshot, taken as the
    /// menu goes up, because "currently active" is a question about that moment and the
    /// reference pages have no scene to ask.
    var activePowerUpIndices: Set<Int> = []

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

    /// The finished run's headline numbers, set by the scene as the game-over screen
    /// goes up - the screen and the detail page read, never compute.
    var runSummary: (paddleHits: Int, bricksDestroyed: Int, powerUpsCollected: Int)?

    /// Brick entry names (the catalogue's own), most recent first. Recorded on the strike,
    /// because a struck brick is the one the player is asking about.
    private(set) var brickNames: [String] = []

    func sawPowerUp(_ index: Int) {
        powerUpIndices.removeAll { $0 == index }
        powerUpIndices.insert(index, at: 0)
        powerUpFates[index] = .seen
    }

    func collectedPowerUp(_ index: Int) {
        powerUpIndices.removeAll { $0 == index }
        powerUpIndices.insert(index, at: 0)
        powerUpFates[index] = .collected
        // A collection is also the most recent thing that happened to it
    }

    /// The recents section's note for a power-up (play-test request): active, still
    /// falling, collected, or missed - in that order of precedence, because each earlier
    /// state is the more current fact about it.
    func statusNote(for index: Int) -> String {
        if activePowerUpIndices.contains(index) { return "ACTIVE" }
        if fallingPowerUpIndices.contains(index) { return "FALLING" }
        return powerUpFates[index] == .collected ? "COLLECTED" : "MISSED"
    }

    func struckBrick(named name: String) {
        brickNames.removeAll { $0 == name }
        brickNames.insert(name, at: 0)
    }

    /// A new run starts with nothing seen. Called as the run is set up, so a list opened
    /// mid-run never carries the last run's memory.
    func reset() {
        powerUpIndices = []
        powerUpFates = [:]
        activePowerUpIndices = []
        fallingPowerUpIndices = []
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

        guard gameMode == .endlessII else { return active }
        let clocks: [(EndlessIIClock, Int)] = [
            (endlessIIAimedStickyClock, 31), (endlessIIMagnetismClock, 32),
            (endlessIIPortalPaddleClock, 33), (endlessIIPaddleHaloClock, 34),
            (endlessIIBallSteeringClock, 35), (endlessIIInertPaddleClock, 36),
            (endlessIIFlippedAngleClock, 37), (endlessIIReversedControlsClock, 38),
            (endlessIIWreckingBallClock, 42), (endlessIIAuraClock, 43),
            (endlessIIDescentClock, 45), (endlessIIAutoAimClock, 46),
            (endlessIIWrapAroundClock, 47),
        ]
        for (clock, index) in clocks where clock.isRunning { active.insert(index) }
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
