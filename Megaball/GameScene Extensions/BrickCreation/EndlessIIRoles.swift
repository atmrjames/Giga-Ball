//
//  EndlessIIRoles.swift
//  Megaball
//
//  What a phase 5 brick is, recorded on the brick itself.
//
//  Phases 3 and 4 could get away without this. A spinning brick is in the spinners list, a
//  Big brick is the size it is - the scene held the knowledge. Phase 5 cannot: `hitBrick`
//  and `removeBrick` are handed a node and nothing else, and a Directional brick has to know
//  which way it faces at the moment the ball arrives.
//
//  So the role lives in the node's `userData`, which travels with the brick, survives every
//  action, and disappears when the brick does. Reading it is a dictionary lookup on the one
//  node already in hand.
//

import SpriteKit

/// What a hit does to a brick - the axis the game has always had.
///
/// Read from the texture, because that is where the rest of the game keeps it. Nothing here
/// changes that; this only gives it a name so style compatibility can be reasoned about.
enum EndlessIIBehaviour {
    case standard
    case multiHit
    case indestructibleOnce
    case indestructibleAlways
    case invisible
}

/// What a brick does beyond being hit - the axis Endless 2.0 adds.
///
/// Independent of behaviour, so a spinning Indestructible brick is a thing that can exist:
/// an obstacle you cannot remove, presenting a different angle every time the ball reaches
/// it. See §4.0 of the specification for the full grid.
enum EndlessIIStyle: CaseIterable {
    case rounded, spinning, flashing
    case gravity, moving, directional, exploding, spawner, portal

    /// Whether this style contradicts a behaviour, rather than merely being strange with it.
    func suits(_ behaviour: EndlessIIBehaviour) -> Bool {
        switch self {
        case .flashing:
            // Both are about whether the brick can be seen; together there is no readable
            // state
            return behaviour != .invisible
        case .directional, .exploding, .spawner:
            // Each fires when the brick is destroyed, or says how it is destroyed. On one
            // that never is, they never happen
            return behaviour != .indestructibleAlways
        case .portal:
            // Struck rather than damaged, so its behaviour has to be the one that already
            // means a hit does nothing
            return behaviour == .indestructibleAlways
        case .rounded, .spinning, .gravity, .moving:
            return true
        }
    }
}

enum EndlessIIRole: String {
    /// Falls into empty cells below it (§4.6).
    case gravity
    /// Wanders within a reserved region (§4.8).
    case moving
    /// Destroyed from one side only (§4.7).
    case directional
    /// Takes its eight neighbours with it (§4.9).
    case exploding
    /// Refills its empty neighbours when destroyed (§4.10).
    case spawner
    /// Sends the ball to the top; cannot be destroyed (§4.11).
    case portal
}

/// Which face of a Directional brick can be hurt.
enum EndlessIISide: String {
    case top, bottom, left, right
}

extension SKNode {

    private static let roleKey = "endlessIIRole"
    private static let sideKey = "endlessIISide"

    /// What this brick does, if it does anything. Nil for every brick in every other mode,
    /// which is what keeps the phase 5 hooks inert outside Endless 2.0.
    var endlessIIRole: EndlessIIRole? {
        get {
            guard let raw = userData?[SKNode.roleKey] as? String else { return nil }
            return EndlessIIRole(rawValue: raw)
        }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?[SKNode.roleKey] = newValue?.rawValue
        }
    }

    /// The side a Directional brick can be destroyed from.
    var endlessIIVulnerableSide: EndlessIISide? {
        get {
            guard let raw = userData?[SKNode.sideKey] as? String else { return nil }
            return EndlessIISide(rawValue: raw)
        }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?[SKNode.sideKey] = newValue?.rawValue
        }
    }
}

/// Which face of a rectangle a point struck.
///
/// Worked out from where the ball is relative to the brick rather than from the contact
/// normal, whose sign depends on which body the physics engine happened to list first. The
/// comparison is scaled by the brick's half-extents, or a brick twice as wide as it is tall
/// would report a top hit for anything even slightly off centre.
enum EndlessIIImpact {
    static func side(ballAt ball: CGPoint, brickAt brick: CGPoint,
                     brickSize: CGSize) -> EndlessIISide {
        let dx = (ball.x - brick.x)/max(brickSize.width/2, 0.0001)
        let dy = (ball.y - brick.y)/max(brickSize.height/2, 0.0001)

        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        }
        return dy > 0 ? .top : .bottom
    }
}
