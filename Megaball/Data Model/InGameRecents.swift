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

    /// Brick entry names (the catalogue's own), most recent first. Recorded on the strike,
    /// because a struck brick is the one the player is asking about.
    private(set) var brickNames: [String] = []

    func sawPowerUp(_ index: Int) {
        powerUpIndices.removeAll { $0 == index }
        powerUpIndices.insert(index, at: 0)
    }

    func struckBrick(named name: String) {
        brickNames.removeAll { $0 == name }
        brickNames.insert(name, at: 0)
    }

    /// A new run starts with nothing seen. Called as the run is set up, so a list opened
    /// mid-run never carries the last run's memory.
    func reset() {
        powerUpIndices = []
        brickNames = []
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
