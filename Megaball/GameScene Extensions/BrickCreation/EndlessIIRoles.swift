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
/// Codable because the run's introduction schedule is drawn once and carried in the save
/// (round 192): a resumed run that redrew it would change what is available under the
/// player, which is round 150's lesson one level up.
enum EndlessIIStyle: String, CaseIterable, Codable {
    case rounded, spinning, flashing
    /// Shrinks and swells where it stands, between half a cell and the whole of it (§4.12).
    case breathing
    case gravity, moving, directional, exploding, spawner, portal
    /// Anchors itself where it is when first struck (§4.11a).
    case fixed
    /// The shaped faces (§12.0's brick geometries) - a dome, a notch, a right triangle and
    /// a rhombus. They change where the ball goes and nothing else about the brick.
    case convex, concave, wedge, diamond

    /// The shape this style is, if it is one. See EndlessIIFaces.
    var face: EndlessIIFace? {
        switch self {
        case .convex: return .convex
        case .concave: return .concave
        case .wedge: return .wedge
        case .diamond: return .diamond
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
        case .convex, .concave, .wedge, .diamond:
            // Any behaviour but Invisible. An invisible brick is not drawn until it is
            // struck, so a shaped one would be answering hits with a slope nobody can see -
            // and the whole appeal of a shaped brick is aiming off it deliberately
            return behaviour != .invisible
        }
    }

    /// Whether this style can be carried by a brick of a given size.
    ///
    /// **The size half of `endlessIICanTake`, said once.** It used to live in that method as a
    /// handful of `isOrdinaryCellSized` checks and *again* in the reference page as a sentence
    /// somebody typed, and round 237 changed the rules and only moved one of them: the page has
    /// been telling players that Fixed is Normal-only and Moving is Tiny-and-Normal ever since,
    /// when both take any size now. A decision written down twice is wrong the first time it
    /// changes, and this one changed.
    ///
    /// Only the size question. Whether the brick is *centred*, whether a spinner is in the
    /// column, whether a Directional brick has a face the ball can reach - those need a live
    /// brick in a live field and stay where they are.
    func suits(_ size: BrickSize) -> Bool {
        switch self {
        case .convex, .concave, .wedge, .diamond:
            // The silhouette is built from the brick's own size and drawn about its node, which
            // only holds for a brick that is one ordinary cell sitting centred
            return size == .normal
        case .spinning:
            // Four quarter-cell bricks each turning about their own centre sweep straight
            // through one another, and a Big one sweeps a circle wider than the clearance the
            // generator reserves for it
            return size == .normal
        case .breathing:
            // It changes size about its own middle, which a Big brick's off-centre sprite would
            // do around a corner - and a Tiny one shrinking to half of a quarter-cell is a
            // brick nobody can hit
            return size == .normal
        case .gravity:
            // Any size but Tiny. Four quarters share a cell, so "is the space below free" is a
            // question the occupancy map cannot answer for one of them, and a whole-row drop
            // would put it through its own siblings (round 237)
            return size != .tiny
        case .rounded, .flashing, .moving, .fixed,
             .directional, .exploding, .spawner, .portal:
            return true
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

        if self == .portal || other == .portal {
            return EndlessIIStyle.takenByAPortal.contains(self == .portal ? other : self)
        }
        // Asked before the shapes, because a Portal may wear one and `takenByAPortal` is the
        // whole of what it takes - two rules answering the same pair is how they drift apart

        if isFace || other.isFace {
            guard isFace != other.isFace else { return false }
            // Two shapes are two answers to the same question
            return EndlessIIStyle.refusedByAFace.contains(isFace ? other : self) == false
        }

        let pair: Set<EndlessIIStyle> = [self, other]
        return EndlessIIStyle.incompatiblePairs.contains(pair) == false
    }

    /// The whole of what a Portal will share a brick with, named rather than refused.
    ///
    /// James, on the brick workbook's Portal row: "figure out what actions portal is
    /// compatible with and allow those. Disallow the others." Stated as what it *takes*
    /// because that is the shorter list and the honest one - a Portal is the most particular
    /// brick in the mode, and seven scattered refusals read as seven separate arguments rather
    /// than as the two it actually has:
    ///
    /// **It is struck, never damaged.** So everything that answers damage has nothing to
    /// attach to. Directional describes which side destroys it; Fixed anchors on the hit that
    /// hurts; Exploding and Spawner fire on destruction, and on a brick that is never
    /// destroyed they fire on every hit instead - a doorway that clears or refills its own
    /// neighbourhood each time you use it, which is two big things per hit and one too many to
    /// follow. Flashing goes for the same reason from the other end: a Portal is never *not*
    /// solid.
    ///
    /// **Its mouth is a fixed target, or it cannot be aimed at.** That rules out Moving, which
    /// wanders, and Breathing, which changes size and vanishes altogether at the bottom of a
    /// breath. It does not rule out Gravity - a faller comes to rest and is a fixed target
    /// again - and it does not rule out Spinning, which never leaves its cell and whose angle
    /// nothing reads, since a Portal absorbs the ball rather than bouncing it.
    ///
    /// Neither of those two arguments touches a *shape*, which is why all four faces are here.
    static let takenByAPortal: Set<EndlessIIStyle> = [.rounded, .spinning, .gravity,
                                                     .convex, .concave, .wedge, .diamond]
    // **The shapes are on the list**, on the workbook rather than on the argument round 235
    // made against them. "Brick type and state is fixed. Can take on a different shape, size,
    // action" is what the New Brick Types row says, and it is right where round 235 was wrong:
    // a shaped Portal is not showing a bounce it will not give, it is a doorway with a
    // differently shaped mouth, and where the silhouette is decides where the ball goes in

    /// What a shaped face cannot share a brick with, and why - stated as a rule rather than
    /// as thirty pairs, because it is one rule.
    ///
    /// **Shape and action are two axes** (James, on the 2026 brick workbook: "this was always
    /// the intention, I just didn't have it mapped out until now"). A face used to refuse
    /// eight styles; it refuses three, and each of the three is a genuine contradiction
    /// rather than a cost:
    ///
    /// - **Rounded** is itself an outline. Two outlines are two answers to one question, the
    ///   same reason two faces cannot share a brick.
    /// - **Directional** reads a hit against a rectangle's four sides and draws a bright bar
    ///   along one of them. On James's call it is refused outright rather than taught about
    ///   slopes: "directional bricks are always the standard shape".
    /// - **Portal** replaces what a hit *means*. It is struck rather than damaged, and the
    ///   angle a shaped face gives is an answer to a bounce that never happens.
    ///
    /// The five that left - Spinning, Gravity, Moving, Fixed and Breathing - all turned out to
    /// be about *where the brick is* rather than what its outline is, and a shaped brick
    /// answers that with its node exactly as a rectangular one does. What they needed was not
    /// new geometry but one honest answer to "how much room does this brick take up", because
    /// a shaped brick's sprite is a third of a cell and every one of them was asking the
    /// sprite. `endlessIIFieldSize` is that answer.
    static let refusedByAFace: Set<EndlessIIStyle> = [.rounded, .directional]
    // Portal left this list in round 237: the workbook's New Brick Types row says a Portal
    // "can take on a different shape, size, action" in as many words, and `takenByAPortal` is
    // where its answer lives now

    static let incompatiblePairs: [Set<EndlessIIStyle>] = [
        [.spinning, .moving],       // both want to say where the brick is
        [.gravity, .moving],        // the same
        [.exploding, .spawner],     // opposite answers to the same question
        // **Spinning and Directional now go together, and Moving and Flashing with it**
        // (James, on the brick workbook's matrix). All three were refused on the same
        // reasoning - "a vulnerable side has to stay findable" - and the workbook's answer is
        // that a soft side which turns, wanders or blinks is a shot you have to *time* rather
        // than one you cannot take. "Spinning plus Directional should be allowed" was the
        // instruction, and the other two follow from it: a brick whose open face is harder to
        // reach is the point of Directional, not a failure of it
        [.spinning, .fixed],        // one anchors where it stands, the other never stands still
        [.spinning, .gravity],      // the same argument, falling
        [.spinning, .exploding],    // a blast measured in cells, thrown from a brick that
        [.spinning, .spawner],      // is between them - the workbook refuses both
        [.breathing, .gravity],     // what holds a faller up cannot be a brick that vanishes
        [.breathing, .spawner],     // nor can what a spawn measures its empty cells against
        [.moving, .spawner],        // a well that walks fills a different cell each time
        // The workbook's seven new refusals. Every one is a pair where one style answers a
        // question in *cells* and the other has left the cell grid behind - which is the same
        // objection `[.spinning, .moving]` has always made, applied consistently
        [.fixed, .moving],       // one says stay put, the other says do not
        [.fixed, .gravity],      // the same argument
        // Every Portal pair used to be listed here. They are `takenByAPortal` now, which says
        // the same thing in one direction instead of seven
        // **Spinning and Breathing go together** - the matrix says Yes, and the objection this
        // line used to make ("both redraw the brick's own geometry every frame") was never
        // quite true: Spinning turns the *node* and touches no geometry at all, and a static
        // body follows its node's rotation on its own. A brick that swells while it turns is
        // two cheap things at once rather than two expensive ones
        [.breathing, .rounded],  // Rounded's drawn face is built once, at one size
        [.breathing, .moving],   // the room a mover looks for is measured in whole cells
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
enum EndlessIISide: String, CaseIterable {
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

    /// Which way up, and which way round, a shaped brick's face was turned.
    ///
    /// Stored beside the face for the same reason the face is stored: a resumed game rebuilds
    /// the brick, and an orientation that was re-rolled would give the player back a field
    /// that answers the ball differently from the one they left (round 150's bug, one level
    /// further in).
    /// Optional rather than defaulting to false, and that is the whole mechanism: `makeFace`
    /// rolls an orientation only when it is *not* already set, so a resumed brick that
    /// carries one is rebuilt facing the way it faced, while a new brick rolls and records.
    var endlessIIFaceMirrored: Bool? {
        get { userData?["endlessIIFaceMirrored"] as? Bool }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?["endlessIIFaceMirrored"] = newValue
        }
    }

    var endlessIIFaceFlipped: Bool? {
        get { userData?["endlessIIFaceFlipped"] as? Bool }
        set {
            if userData == nil { userData = NSMutableDictionary() }
            userData?["endlessIIFaceFlipped"] = newValue
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
