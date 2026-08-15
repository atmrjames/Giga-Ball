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
enum EndlessIIStyle: String, CaseIterable {
    case rounded, spinning, flashing
    /// Shrinks and swells where it stands, between half a cell and the whole of it (§4.12).
    case breathing
    case gravity, moving, directional, exploding, spawner, portal
    /// Anchors itself where it is when first struck (§4.11a).
    case fixed
    /// The shaped faces (§12.0's brick geometries) - a dome, a notch and a right triangle.
    /// They change where the ball goes and nothing else about the brick.
    case convex, concave, wedge

    /// The shape this style is, if it is one. See EndlessIIFaces.
    var face: EndlessIIFace? {
        switch self {
        case .convex: return .convex
        case .concave: return .concave
        case .wedge: return .wedge
        default: return nil
        }
    }

    var isFace: Bool { face != nil }

    /// Whether this style contradicts a behaviour, rather than merely being strange with it.
    func suits(_ behaviour: EndlessIIBehaviour) -> Bool {
        switch self {
        case .flashing:
            // Both are about whether the brick can be seen; together there is no readable
            // state
            return behaviour != .invisible
        case .directional:
            // Says how a brick is destroyed. On one that never is, there is nothing for it
            // to describe
            return behaviour != .indestructibleAlways
        case .exploding, .spawner:
            // These two fire on destruction everywhere else, and on an Indestructible brick
            // they fire on every hit instead - a turret that clears its own neighbourhood,
            // or a well that keeps refilling it. Both are self-limiting: once the cells
            // around them are empty, or full, hitting them again does nothing
            return true
        case .portal:
            // Struck rather than damaged, so its behaviour has to be the one that already
            // means a hit does nothing
            return behaviour == .indestructibleAlways
        case .rounded, .spinning, .gravity:
            return true
        case .breathing:
            // Any behaviour but Invisible, for the reason the shaped faces give: a brick
            // that is not drawn until it is struck has nothing to show, and the whole of
            // this one is watching it change
            return behaviour != .invisible
        case .moving:
            return true
        case .fixed:
            // It needs a first hit to anchor it and a second to destroy it, so a behaviour
            // that never takes damage would leave it as an ordinary brick that never fixes
            return behaviour != .indestructibleAlways
        case .convex, .concave, .wedge:
            // Any behaviour but Invisible. An invisible brick is not drawn until it is
            // struck, so a shaped one would be answering hits with a slope nobody can see -
            // and the whole appeal of a shaped brick is aiming off it deliberately
            return behaviour != .invisible
        }
    }

    /// Whether this style fires when the brick is hit rather than when it is destroyed.
    ///
    /// The same style, read differently depending on what it is attached to. A brick that
    /// can never be destroyed would never fire an on-destruction effect at all, so it fires
    /// on contact instead.
    func firesOnHit(with behaviour: EndlessIIBehaviour) -> Bool {
        (self == .exploding || self == .spawner) && behaviour == .indestructibleAlways
    }

    /// Whether two styles can share one brick.
    ///
    /// What decides it is what each one takes control of. Two that both say where the brick
    /// is, or both decide whether it is solid, or both answer for what a hit does, cannot be
    /// combined - the second would only undo the first. Everything else can, and an
    /// Indestructible brick that is rounded and spinning is the reason for having this at
    /// all. See §4.0.2 of the specification.
    func stacksWith(_ other: EndlessIIStyle) -> Bool {
        guard self != other else { return false }

        if isFace || other.isFace {
            guard isFace != other.isFace else { return false }
            // Two shapes are two answers to the same question
            return EndlessIIStyle.refusedByAFace.contains(isFace ? other : self) == false
        }

        let pair: Set<EndlessIIStyle> = [self, other]
        return EndlessIIStyle.incompatiblePairs.contains(pair) == false
    }

    /// What a shaped face cannot share a brick with, and why - stated as a rule rather than
    /// as thirty pairs, because it is one rule.
    ///
    /// A face rebuilds three things at once: the outline that is drawn, the physics body,
    /// and where the sprite hides. So it cannot live with anything that redraws the outline
    /// (Rounded), turns the brick (Spinning), decides where it sits (Gravity, Moving,
    /// Fixed), reads a hit against a rectangle (Directional), or replaces what a hit means
    /// entirely (Portal). What is left - Flashing, Exploding, Spawner - touches colour,
    /// alpha and neighbours, none of which the shape cares about.
    static let refusedByAFace: Set<EndlessIIStyle> = [
        .rounded, .spinning, .gravity, .moving, .fixed, .directional, .portal, .breathing,
    ]
    // Breathing joins them because it rebuilds the body as a rectangle every time it
    // crosses a size, which is precisely the thing a shaped face owns

    static let incompatiblePairs: [Set<EndlessIIStyle>] = [
        [.spinning, .moving],       // both want to say where the brick is
        [.gravity, .moving],        // the same
        [.spinning, .directional],  // a vulnerable side has to stay findable
        [.moving, .directional],    // the same
        [.flashing, .directional],  // a brick that keeps vanishing cannot also be read
        [.exploding, .spawner],     // opposite answers to the same question
        [.portal, .flashing],       // a Portal is never not solid
        [.portal, .directional],    // nor ever damaged
        [.portal, .exploding],      // one big thing per hit, or nobody can follow it
        [.portal, .spawner],
        [.fixed, .moving],       // one says stay put, the other says do not
        [.fixed, .gravity],      // the same argument
        [.fixed, .portal],       // a Portal is never damaged, so it never anchors
        [.breathing, .spinning], // both redraw the brick's own geometry every frame
        [.breathing, .rounded],  // Rounded's drawn face is built once, at one size
        [.breathing, .moving],   // the room a mover looks for is measured in whole cells
        [.breathing, .portal],   // a Portal's mouth is a fixed target or it cannot be aimed at
    ]
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
    /// Anchors itself where it is when struck, and destroys what descends onto it (§4.11a).
    case fixed
}

/// Which face of a Directional brick can be hurt.
enum EndlessIISide: String {
    case top, bottom, left, right
}

extension SKNode {

    private static let roleKey = "endlessIIRole"
    private static let sideKey = "endlessIISide"
    private static let plainKey = "endlessIIStaysPlain"

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

    /// Whether this brick must never be given a style.
    ///
    /// Endless 2.0's starting brick is the one the first ball is aimed at. Whatever else the
    /// field does, that one has to be a brick and nothing else - a run that opens on a
    /// Portal, or on something that flashes out of the way, opens on a puzzle instead of on
    /// a shot.
    var endlessIIStaysPlain: Bool {
        get { userData?[SKNode.plainKey] as? Bool ?? false }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?[SKNode.plainKey] = newValue
        }
    }

    /// The shape this brick was given, if it was given one. Recorded rather than measured:
    /// the silhouette is a child node whose path could be read back, but a stored answer is
    /// what lets `endlessIIStyles(on:)` name the shape without doing geometry.
    var endlessIIFace: EndlessIIFace? {
        get {
            guard let raw = userData?["endlessIIFace"] as? String else { return nil }
            return EndlessIIFace(rawValue: raw)
        }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?["endlessIIFace"] = newValue?.rawValue
        }
    }

    /// Whether a Fixed brick has been struck and anchored itself.
    var endlessIIIsAnchored: Bool {
        get { userData?["endlessIIAnchored"] as? Bool ?? false }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?["endlessIIAnchored"] = newValue
        }
    }

    /// Which end of a Portal pair this brick is - the blue one or the yellow one.
    ///
    /// A label, not a direction. The link works both ways: the ball comes out of whichever
    /// end it did not go into, so blue to yellow and yellow to blue are the same journey.
    /// The two colours exist so a player can tell at a glance where a jump will land them,
    /// not to say which end is the way in.
    var endlessIIPortalIsBlue: Bool {
        get { userData?["endlessIIPortalBlue"] as? Bool ?? false }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?["endlessIIPortalBlue"] = newValue
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
