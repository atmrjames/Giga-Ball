//
//  EndlessIIElement.swift
//  Megaball
//
//  One thing a run has yet to show the player.
//
//  James, round 258: "In Endless Mayhem don't introduce new elements too quickly. Perhaps a new
//  element every game view of bricks, so 22m. So that may be a new brick type, a new power-up,
//  and new brick shape. Once the elements are added they are then in the rotation of things
//  always available for that game from then on. Rarity is still applied... The order in which
//  elements are introduced should be randomised."
//
//  ## What was wrong with five schedules
//
//  Every kind of new thing already arrived on a schedule of its own, and each one was sensibly
//  paced *for itself*: a style every 35m, a power-up every 14m, a set row every 30m, a phase
//  every 30m. Nobody had ever added them up. A player meets all five at once, so what the mode
//  actually did was introduce something new **about every seven metres** - a third of a screen -
//  which is the flood James is describing. Each clock was reasonable and the sum was not.
//
//  So there is one clock now, and one queue. An element is a style, a power-up, a multi-hit
//  tier, a set row or a phase; the run shuffles them **together**; and one of them arrives
//  every `EndlessIIProgression.elementSpacing` metres, whatever kind it happens to be. That is
//  what makes "a new brick type, a new power-up, and new brick shape" one sentence rather than
//  three - they are the same queue, and which comes next is the shuffle's business.
//
//  ## What is never in the queue
//
//  "Certain things should always be available from the start. All the classic game mode
//  power-ups and the standard brick type." Both were already true and stay true: a power-up
//  below `firstEndlessIIPowerUp` is the vocabulary a player brought with them, and Standard is
//  what a field is made of before it is made of anything else.
//
//  ## The multi-hit tiers
//
//  "Multi bricks should start from level 2 (2 hits to destroy). Level 3 and level 4 (3 and 4
//  hits to destroy) should be considered new elements."
//
//  Mayhem's multi-hit brick has always been exactly one brick: two hits, drawn as `MultiHit3`,
//  because the textures count *up* to destruction rather than down. Three and four hits existed
//  in Classic and had never reached this mode at all. They are elements now, which is both what
//  James asked for and the only way they arrive at all.
//

import Foundation

/// One of the things a run introduces as it goes.
///
/// `Codable` because the run's queue rides in the save with the rest of its schedule, and
/// `Hashable` because "has this been introduced yet" is a set membership question.
enum EndlessIIElement: Hashable, Codable {

    /// A style: a shape, or something the brick does.
    case style(EndlessIIStyle)

    /// A power-up, by its index in the probability array - the same index everything else in
    /// the mode identifies a power-up by.
    case powerUp(Int)

    /// A multi-hit brick that takes more than two hits.
    case multiHit(hits: Int)

    /// A designed full-width row, by its index in `EndlessIISetRow.all`.
    case setRow(Int)

    /// A stretch of field with a character of its own.
    case phase(EndlessIIPhase)

    /// How many hits the deeper multi-hit tiers take. Two is not here: it is what a Mayhem
    /// multi-hit brick has always been, and it stays available from the first metre.
    static let multiHitTiers = [3, 4]
}
