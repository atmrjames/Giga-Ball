//
//  PowerUpCatalogue.swift
//  Megaball
//
//  What every power-up *is*, separately from what it does.
//
//  The game declares each power-up inline, in a switch case that sets its icon, shows its
//  bar, starts its timer and schedules its expiry - around sixty lines apiece, near enough
//  identical between them. That is workable for twenty-eight. Endless 2.0 adds twenty-two
//  more, and asks questions the switch cannot answer: which of these conflict, which are
//  timed, what happens if I collect one twice, which may drop right now, which are active.
//
//  Those are all properties of a power-up rather than steps in its activation, so they
//  live here as data. Adding the fiftieth power-up should cost what the third did: one row
//  in this table, plus its behaviour.
//
//  This type deliberately has no SpriteKit in it and knows nothing about activation. It
//  answers questions about power-ups; the scene still performs them.
//

import Foundation

/// Which mode a power-up belongs to. Existing modes must not gain new power-ups, so this
/// is what keeps Endless 2.0's additions out of Classic and Endless.
enum PowerUpAvailability {
    /// In every mode, including Classic and the original Endless.
    case allModes
    /// Endless 2.0 only.
    case endlessII
}

/// How often a power-up is eligible to drop, relative to the others.
///
/// This governs *which* power-up falls, never how often power-ups fall at all - the drop
/// rate itself is unchanged.
enum PowerUpRarity {
    /// Numeric. Changes a value.
    case common
    /// Behavioural. Changes how something behaves within the existing rules.
    case uncommon
    /// Rules-changing. Suspends or inverts a rule the player relies on.
    case rare

    /// Starting weights, to be tuned per power-up once they can be played.
    var weight: Int {
        switch self {
        case .common: return 60
        case .uncommon: return 30
        case .rare: return 10
        }
    }
}

/// Two power-ups that set the same single rule and cannot both be honoured.
///
/// Deliberately narrow. Power-ups combine by default - Magnetism with Inert Paddle, Aura
/// with Wrap-Around - because the combinations are most of the point. Only these genuinely
/// cannot coexist, and the later collection supersedes the earlier.
///
/// Note what is *not* here: ball speed, ball size and paddle size. Those are stepped axes
/// that already resolve themselves, where collecting the same one deepens the effect and
/// collecting its opposite steps back toward normal.
enum PowerUpConflict {
    /// One rule for what the ball does on contact with a brick.
    case ballHitBehaviour
    /// One thing can own the launch.
    case launchControl
}

/// What a second collection does while the first is still running.
enum PowerUpStacking {
    /// Not timed - it simply happens again.
    case repeats
    /// Adds to the time remaining rather than restarting it.
    case extendsDuration
    /// Adds to the time remaining, and deepens the effect.
    case extendsAndDeepens
    /// Deepens along a stepped axis; the opposite power-up steps back toward normal.
    case stepsAlongAxis
    /// Already at its limit, so a second collection changes nothing.
    case noFurtherEffect
    /// Adds another of whatever it added.
    case addsAnother
}

/// Whether a power-up is good or bad for the player, which decides its colour and whether
/// it awards or deducts points.
enum PowerUpValence {
    case beneficial
    case harmful
    /// Mystery, which is either.
    case unknown
}

struct PowerUp {
    let id: String
    let name: String
    let availability: PowerUpAvailability
    let rarity: PowerUpRarity
    let valence: PowerUpValence
    let conflict: PowerUpConflict?
    let isTimed: Bool
    let stacking: PowerUpStacking

    /// Whether this may drop given the state of the game.
    ///
    /// Almost all power-ups are always eligible and use the default. Lock and Key are not:
    /// Lock is pointless with nothing to freeze, and Key is pointless with no Lock - so
    /// their eligibility is a question about the game, which a static weight cannot ask.
    let isEligible: (PowerUpContext) -> Bool

    init(id: String,
         name: String,
         availability: PowerUpAvailability = .allModes,
         rarity: PowerUpRarity,
         valence: PowerUpValence,
         conflict: PowerUpConflict? = nil,
         isTimed: Bool,
         stacking: PowerUpStacking,
         isEligible: @escaping (PowerUpContext) -> Bool = { _ in true }) {
        self.id = id
        self.name = name
        self.availability = availability
        self.rarity = rarity
        self.valence = valence
        self.conflict = conflict
        self.isTimed = isTimed
        self.stacking = stacking
        self.isEligible = isEligible
    }
}

/// What the drop table is allowed to know about the game when deciding what may fall.
///
/// Kept to the few facts that actually gate something, so this stays testable and does not
/// become a second copy of the scene.
struct PowerUpContext {
    /// Power-up ids currently in effect.
    var active: Set<String> = []
    /// Ids of active power-ups that are timed and have enough time left to still be
    /// running by the time a newly dropped power-up could reach the paddle.
    var timedWithTimeToSpare: Set<String> = []
    /// How many balls are in play.
    var ballsInPlay: Int = 1
    /// The mode being played.
    var mode: PowerUpAvailability = .allModes

    static let maximumBalls = 4
}

enum PowerUpCatalogue {

    /// Every power-up in the game.
    ///
    /// The first twenty-eight already exist and behave exactly as they do today; their
    /// classification here is what is new. The rest are Endless 2.0's.
    static let all: [PowerUp] = existing + endlessII

    // MARK: - The existing twenty-eight

    static let existing: [PowerUp] = [
        PowerUp(id: "extraBall", name: "Extra Ball", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .repeats,
                // A life, in a mode that has exactly one and no other way to earn another.
                isEligible: { $0.mode != .endlessII }),
        PowerUp(id: "loseABall", name: "Lose A Ball", rarity: .uncommon, valence: .harmful,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "slowBall", name: "Slow Ball", rarity: .common, valence: .beneficial,
                isTimed: true, stacking: .stepsAlongAxis),
        PowerUp(id: "fastBall", name: "Fast Ball", rarity: .common, valence: .harmful,
                isTimed: true, stacking: .stepsAlongAxis),
        PowerUp(id: "expandPaddle", name: "Expand Paddle", rarity: .common, valence: .beneficial,
                isTimed: true, stacking: .stepsAlongAxis),
        PowerUp(id: "shrinkPaddle", name: "Shrink Paddle", rarity: .common, valence: .harmful,
                isTimed: true, stacking: .stepsAlongAxis),
        PowerUp(id: "stickyPaddle", name: "Sticky Paddle", rarity: .uncommon, valence: .beneficial,
                conflict: .launchControl, isTimed: false, stacking: .extendsAndDeepens),
        PowerUp(id: "gravityField", name: "Gravity Field", rarity: .uncommon, valence: .harmful,
                isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "plus100", name: "+100 Points", rarity: .common, valence: .beneficial,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "minus100", name: "-100 Points", rarity: .common, valence: .harmful,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "plus1000", name: "+1000 Points", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "minus1000", name: "-1000 Points", rarity: .uncommon, valence: .harmful,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "maxMultiplier", name: "Max Multiplier", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .noFurtherEffect),
        PowerUp(id: "resetMultiplier", name: "Reset Multiplier", rarity: .uncommon, valence: .harmful,
                isTimed: false, stacking: .noFurtherEffect),
        PowerUp(id: "completeLevel", name: "Complete Level", rarity: .rare, valence: .beneficial,
                isTimed: false, stacking: .repeats,
                // There is no next level in a field with no end.
                isEligible: { $0.mode != .endlessII }),
        PowerUp(id: "showBricks", name: "Show Bricks", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "hideBricks", name: "Hide Bricks", rarity: .uncommon, valence: .harmful,
                isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "clearMultiHit", name: "Clear Multi-Hit Bricks", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "resetMultiHit", name: "Reset Multi-Hit Bricks", rarity: .uncommon, valence: .harmful,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "zapIndestructible", name: "Zap Indestructible Bricks", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "gigaBall", name: "Giga-Ball", rarity: .rare, valence: .beneficial,
                conflict: .ballHitBehaviour, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "inertBall", name: "Inert Ball", rarity: .uncommon, valence: .harmful,
                conflict: .ballHitBehaviour, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "lasers", name: "Lasers", rarity: .uncommon, valence: .beneficial,
                isTimed: true, stacking: .extendsAndDeepens),
        PowerUp(id: "quicksand", name: "Quicksand", rarity: .uncommon, valence: .harmful,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "mystery", name: "Mystery", rarity: .uncommon, valence: .unknown,
                isTimed: false, stacking: .repeats),
        PowerUp(id: "backstop", name: "Backstop", rarity: .uncommon, valence: .beneficial,
                isTimed: false, stacking: .extendsAndDeepens),
        PowerUp(id: "expandBall", name: "Expand Ball", rarity: .common, valence: .beneficial,
                isTimed: true, stacking: .stepsAlongAxis),
        PowerUp(id: "shrinkBall", name: "Shrink Ball", rarity: .common, valence: .harmful,
                isTimed: true, stacking: .stepsAlongAxis),
    ]

    // MARK: - Endless 2.0

    static let endlessII: [PowerUp] = [
        PowerUp(id: "descent", name: "Descent", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "trajectoryLine", name: "Trajectory Line", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true, stacking: .extendsAndDeepens),
        PowerUp(id: "aimedSticky", name: "Aimed Sticky", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, conflict: .launchControl,
                isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "magnetism", name: "Magnetism", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true, stacking: .extendsAndDeepens),
        PowerUp(id: "lock", name: "Lock", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: true, stacking: .extendsDuration,
                // Nothing to freeze, or nothing that would still be running by the time it
                // could be caught, means a Lock that does nothing at all.
                isEligible: { !$0.timedWithTimeToSpare.isEmpty }),
        PowerUp(id: "key", name: "Key", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: false, stacking: .repeats,
                // The only window in which a Key means anything. Its weight is set high
                // within that window so it is reliably available while it is possible,
                // and rare overall because the window is.
                isEligible: { $0.active.contains("lock") }),
        PowerUp(id: "laserBeam", name: "Laser Beam", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: false, stacking: .repeats),
        PowerUp(id: "portalPaddle", name: "Portal Paddle", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "wrapAround", name: "Wrap-Around", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "landingMarker", name: "Landing Marker", availability: .endlessII,
                rarity: .common, valence: .beneficial, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "wreckingBall", name: "Wrecking Ball", availability: .endlessII,
                rarity: .rare, valence: .beneficial, conflict: .ballHitBehaviour,
                isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "aura", name: "Aura", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true, stacking: .extendsAndDeepens),
        PowerUp(id: "randomisedBounce", name: "Randomised Bounce", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "convexPaddle", name: "Convex Paddle", availability: .endlessII,
                rarity: .rare, valence: .harmful, isTimed: true,
                stacking: .extendsDuration),
        PowerUp(id: "concavePaddle", name: "Concave Paddle", availability: .endlessII,
                rarity: .rare, valence: .harmful, isTimed: true,
                stacking: .extendsDuration),
        PowerUp(id: "wavyPaddle", name: "Wavy Paddle", availability: .endlessII,
                rarity: .rare, valence: .harmful, isTimed: true,
                stacking: .extendsDuration),
        PowerUp(id: "jaggedPaddle", name: "Jagged Paddle", availability: .endlessII,
                rarity: .rare, valence: .harmful, isTimed: true,
                stacking: .extendsDuration),
        // The four shaped faces. One at a time - a paddle cannot be domed and dished at
        // once - and no conflict rule against the rest of the paddle group is needed: a
        // shape only says where the ball behaves as though it landed, so Inert flattens it,
        // Flipped mirrors it and Auto-Aim overrides it, all for free
        PowerUp(id: "drift", name: "Drift", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true,
                stacking: .extendsDuration),
        // Bad because a field that will not hold still is a field you have to keep
        // re-reading - not because it takes anything away
        PowerUp(id: "safetyPaddle", name: "Safety Paddle", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true,
                stacking: .extendsDuration),
        // Deliberately double-edged, like Gravity: it keeps the ball up in the field, and it
        // stops the ball reaching the bricks from below while it is there
        PowerUp(id: "ghostBall", name: "Ghost Ball", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "inertPaddle", name: "Inert Paddle", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "flippedAngle", name: "Flipped Angle", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "multiBall", name: "Multi-Ball", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: false, stacking: .addsAnother,
                // Stops being offered at the cap rather than being collected for nothing.
                isEligible: { $0.ballsInPlay < PowerUpContext.maximumBalls }),
        PowerUp(id: "wipe", name: "Wipe", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: false, stacking: .repeats),
        PowerUp(id: "paddleHalo", name: "Paddle Halo", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: true, stacking: .extendsAndDeepens),
        PowerUp(id: "reversedControls", name: "Reversed Controls", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "ballSteering", name: "Ball Steering", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: true, stacking: .extendsDuration),
        PowerUp(id: "clearAndRetreat", name: "Clear And Retreat", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true,
                stacking: .extendsDuration),
        // Timed since round 136. Instant, the retreat it clears was taken straight back by
        // the cadence, which exists to close exactly that gap - so the power-up's own effect
        // undid itself in under a second
        PowerUp(id: "cull", name: "Cull", availability: .endlessII,
                rarity: .rare, valence: .beneficial, isTimed: false, stacking: .repeats),
        // Destroys half the remaining bricks at random. Rare because it is the largest single
        // thing a power-up does to the field, and instant because there is nothing left to run
        PowerUp(id: "autoAim", name: "Auto-Aim", availability: .endlessII,
                rarity: .uncommon, valence: .beneficial, isTimed: true,
                stacking: .extendsDuration),
        // Counted in paddle hits rather than seconds, like Aimed Sticky - `isTimed` is about
        // whether it ends on its own rather than about the unit it counts in.
        //
        // No conflict with Aimed Sticky, though the two look like they should have one: Aimed
        // Sticky owns the *launch* from a held ball and Auto-Aim redirects an ordinary
        // *bounce*, and the scene lets both run. Declaring a conflict here that the game does
        // not enforce is how this file drifted from the game in the first place
        PowerUp(id: "infill", name: "Infill", availability: .endlessII,
                rarity: .uncommon, valence: .harmful, isTimed: false, stacking: .repeats),
    ]

    // MARK: - Questions

    static func powerUp(id: String) -> PowerUp? {
        all.first { $0.id == id }
    }

    /// The power-ups a mode offers at all, before the state of the game is considered.
    static func available(in mode: PowerUpAvailability) -> [PowerUp] {
        all.filter { $0.availability == .allModes || $0.availability == mode }
    }

    /// What may drop right now.
    static func eligible(in context: PowerUpContext) -> [PowerUp] {
        available(in: context.mode).filter { $0.isEligible(context) }
    }

    /// The active power-up a newly collected one would displace, if any.
    ///
    /// Only the two conflict groups displace anything. Everything else combines, which is
    /// the default answer and why this returns nil so often.
    static func displaced(byCollecting id: String, whileActive active: Set<String>) -> String? {
        guard let incoming = powerUp(id: id), let group = incoming.conflict else { return nil }
        return active.first { other in
            other != id && powerUp(id: other)?.conflict == group
        }
    }
}
