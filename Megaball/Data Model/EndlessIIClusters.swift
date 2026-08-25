//
//  EndlessIIClusters.swift
//  Megaball
//
//  Small shapes, dropped into an ordinary field.
//
//  Set rows (EndlessIISetRows) are designed rows that span the field, and they are landmarks:
//  a wall with one gap in it is a shot to find. But a shape that always runs wall to wall can
//  only ever be a row, and the field is two-dimensional. A cluster is the same idea let off
//  the leash - a block, a ring, an arrow, a diamond - three or four columns wide, dropped at
//  a column the generator picks, with ordinary field either side of it.
//
//  That difference is the whole point. A set row says "the next row is this". A cluster says
//  "there is a thing over there", and the field around it carries on as normal - which is what
//  makes it read as an object in the field rather than as a change of subject.
//
//  ## The grid is not square
//
//  A cell is twice as wide as it is tall, because a brick is. So a shape that is square *in
//  cells* is a 2:1 rectangle on screen, and anything meant to read as a circle, a diamond or a
//  ring needs roughly twice as many rows as columns. Every shape here is drawn for that, which
//  is why they all look tall written down and correct in the game.
//

import Foundation

/// A small designed shape, placed somewhere in an otherwise ordinary field.
///
/// Written as text, top row first - the first row is the one that lands highest, which the
/// queue has only done since round 249 - exactly as a set row is, because that is the form a person
/// can read and edit, and being able to see the shape in the source is most of why these are
/// worth having.
///
///     .  empty              N  ordinary brick        M  multi-hit
///     i  indestructible x1  I  indestructible x2
///     ?  whatever the generator would have put there anyway
///
/// A `?` is what makes a cluster a *formation* rather than a picture: the shape is designed
/// and its contents are not, so the same ring is a different problem each time it appears.
struct EndlessIICluster {
    let name: String
    let rows: [String]
    /// The height below which this one does not appear.
    let minimumHeight: Int
    /// How likely this one is, relative to the others available.
    let weight: Int
    /// A scatter draws its rows fresh each time it is placed - see `Scatter`.
    let scatter: Scatter?
    /// What this cluster's own characters mean, for the shapes that need more than the six
    /// above (`EndlessIIBrickSpec`). Empty on every cluster written before round 238.
    let legend: [Character: EndlessIIBrickSpec]

    var height: Int { rows.count }
    var width: Int { rows.map(\.count).max() ?? 0 }

    init(name: String, rows: [String], minimumHeight: Int, weight: Int = 10,
         scatter: Scatter? = nil, legend: [Character: EndlessIIBrickSpec] = [:]) {
        self.name = name
        self.rows = rows
        self.minimumHeight = minimumHeight
        self.weight = weight
        self.scatter = scatter
        self.legend = legend
    }

    // MARK: - Scatters

    /// The third kind of formation §6.2.1 asks for: particular bricks in a *random*
    /// arrangement. A drawn cluster is a designed shape with undesigned contents; a scatter
    /// is the reverse - the contents are chosen and the shape is rolled, so the same handful
    /// of bricks is a different field every time it lands.
    struct Scatter {
        /// What is scattered - one of the characters the generator already reads.
        let character: Character
        /// How many of them land.
        let count: Int
        /// Over how many rows they are spread.
        let rows: Int
    }

    /// Draws a scatter's rows, using the caller's randomness.
    ///
    /// Full field width, all `?` except the scattered bricks, which land in distinct cells -
    /// `count` bricks means `count` bricks, not fewer where two rolls collided. Injected
    /// randomness so tests can pin the arrangement while the game rolls it.
    func materialised(fieldWidth: Int, pick: (Int) -> Int) -> EndlessIICluster {
        guard let scatter else { return self }

        var cells = (0..<scatter.rows).flatMap { row in
            (0..<fieldWidth).map { (row: row, column: $0) }
        }
        var grid = Array(repeating: Array(repeating: Character("?"), count: fieldWidth),
                         count: scatter.rows)
        for _ in 0..<min(scatter.count, cells.count) {
            let chosen = cells.remove(at: min(max(0, pick(cells.count)), cells.count - 1))
            grid[chosen.row][chosen.column] = scatter.character
        }

        return EndlessIICluster(name: name, rows: grid.map { String($0) },
                                minimumHeight: minimumHeight, weight: weight, legend: legend)
        // The legend travels with it: a scatter's *contents* are the designed half, so losing
        // the key on the way through would be losing the whole design
    }

    static let all: [EndlessIICluster] = [

        // MARK: The first one written with a legend (round 239)
        //
        // Everything below this is drawn from the six shared characters, which is four kinds of
        // brick. A legend lets a formation reach the rest of what the game builds - the shapes,
        // the actions, the four types - without inventing a letter for every combination.
        // `EndlessIIBrickSpec` is the format and its tests are the check.

        EndlessIICluster(name: "Millrace", rows: ["WWWWW",
                                                  ".???.",
                                                  "wwwww"], minimumHeight: 160, weight: 6,
                         legend: ["W": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                          mirrored: true, flipped: true),
                                  "w": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                          mirrored: false, flipped: false)]),
        // Two rows of wedges with the field's own bricks between them. Both slopes run the same
        // way, so a ball that gets inside is passed along the channel rather than out of it -
        // the shape does what a funnel does without being drawn as one, which is the thing a
        // shape can say and a wall cannot.
        //
        // The orientations are named rather than rolled. Every wedge in the game turns over on
        // a coin (round 154), because a field of them all facing up is a field of flat
        // undersides - but here the point *is* that they agree, and a coin would have produced
        // a mixture and no channel at all. That is the first thing a legend buys which the six
        // characters could not express at all


        // MARK: Scatters - chosen contents, rolled shape (§6.2.1's third kind)

        EndlessIICluster(name: "Buckshot", rows: [], minimumHeight: 80, weight: 8,
                         scatter: Scatter(character: "N", count: 9, rows: 3)),
        // A spray of ordinary bricks with holes everywhere - the anti-wall

        EndlessIICluster(name: "Ghost Field", rows: [], minimumHeight: 140, weight: 6,
                         scatter: Scatter(character: "i", count: 7, rows: 3)),
        // Seven bricks that are not there until struck, scattered so no memory of the last
        // one helps with this one

        EndlessIICluster(name: "Shrapnel", rows: [], minimumHeight: 220, weight: 5,
                         scatter: Scatter(character: "I", count: 5, rows: 3)),
        // Five indestructibles thrown across three rows: not a wall to breach but debris to
        // play around, and every arrangement asks differently


        // MARK: Blocks - the plain ones, and the ones that arrive first

        EndlessIICluster(name: "Block", rows: ["??",
                                               "??"], minimumHeight: 0, weight: 16),
        // Two by two of whatever the field is already making. The simplest thing a cluster
        // can be, and the one that teaches a player that clusters exist

        EndlessIICluster(name: "Slab", rows: ["????",
                                              "????"], minimumHeight: 40, weight: 12),

        EndlessIICluster(name: "Tower", rows: ["??",
                                               "??",
                                               "??",
                                               "??"], minimumHeight: 60, weight: 10),

        EndlessIICluster(name: "Chequer", rows: ["N.N",
                                                 ".N.",
                                                 "N.N"], minimumHeight: 50, weight: 10),
        // Solid enough to matter, open enough to be threaded

        // MARK: Shapes - drawn for a grid whose cells are twice as wide as they are tall

        EndlessIICluster(name: "Diamond", rows: ["..N..",
                                                 ".NNN.",
                                                 "NNNNN",
                                                 ".NNN.",
                                                 "..N.."], minimumHeight: 80, weight: 9),

        EndlessIICluster(name: "Hoop", rows: [".NNN.",
                                              "N...N",
                                              "N...N",
                                              "N...N",
                                              ".NNN."], minimumHeight: 110, weight: 8),
        // A ring with nothing in it. The inside is reachable and worth nothing, which makes
        // the shape itself the obstacle rather than a wrapper around a prize

        EndlessIICluster(name: "Vault", rows: [".III.",
                                               "I???I",
                                               "I???I",
                                               ".III."], minimumHeight: 220, weight: 5),
        // The same ring with something in it, and walls that cannot be broken. The way in is
        // the gaps at the corners

        EndlessIICluster(name: "Circle", rows: ["..NN..",
                                                ".NNNN.",
                                                "N....N",
                                                "N....N",
                                                ".NNNN.",
                                                "..NN.."], minimumHeight: 150, weight: 6),

        EndlessIICluster(name: "Wedge", rows: ["N....",
                                               "NN...",
                                               "NNN..",
                                               "NNNN.",
                                               "NNNNN"], minimumHeight: 70, weight: 9),
        // A slope. Everything that hits it is sent the same way, which is the point

        EndlessIICluster(name: "Arrowhead", rows: ["..N..",
                                                   ".NNN.",
                                                   "NN.NN",
                                                   "N...N"], minimumHeight: 130, weight: 7),

        EndlessIICluster(name: "Cross", rows: [".N.",
                                               ".N.",
                                               "NNN",
                                               ".N.",
                                               ".N."], minimumHeight: 90, weight: 8),

        EndlessIICluster(name: "Staircase", rows: ["NN....",
                                                   "NN....",
                                                   "..NN..",
                                                   "..NN..",
                                                   "....NN",
                                                   "....NN"], minimumHeight: 170, weight: 6),
        // Two rows per step, so the steps are square on screen rather than long and flat

        // MARK: The ones made of something in particular

        EndlessIICluster(name: "Anvil", rows: ["IIIII",
                                               ".???.",
                                               ".???."], minimumHeight: 190, weight: 6),
        // An indestructible lid with the field's own bricks underneath it, so it has to be
        // played around rather than through

        EndlessIICluster(name: "Core", rows: [".MMM.",
                                              "M?N?M",
                                              ".MMM."], minimumHeight: 240, weight: 5),
        // Multi-hit all the way round something ordinary. Slow to open and quick to finish

        // MARK: Shapes that say something a wall cannot (round 240)
        //
        // Everything above is drawn from the four brick kinds the six shared characters reach.
        // These use a legend, so what a cell *is* can be part of the drawing: a slope that
        // points somewhere, a face that only opens one way, a brick that will not sit still.

        EndlessIICluster(name: "Keepsake", rows: ["?B.?",
                                                  "?..?",
                                                  "MMMM"], minimumHeight: 200, weight: 5,
                         legend: ["B": EndlessIIBrickSpec(behaviour: .indestructibleAlways,
                                                          size: .big)]),
        // A Big Indestructible brick sitting on a multi-hit floor, with the field's own bricks
        // either side of it. The block cannot be broken and the floor under it takes four hits
        // a brick, so what is worth having here is the room *beside* it - and the block is in
        // the way of the shot that gets there.
        //
        // **Its own three cells are drawn empty**, which is the rule every Big brick in a
        // formation follows: only the top-left cell carries the spec, and the other three have
        // to be left for it or the field builds two bricks in one place

        EndlessIICluster(name: "Weir", rows: ["V.V.V",
                                              ".V.V.",
                                              "V.V.V"], minimumHeight: 100, weight: 8,
                         legend: ["V": EndlessIIBrickSpec(behaviour: .standard, shape: .convex,
                                                          flipped: true)]),
        // Domes hanging point-down in a chequer. A ball entering from below is scattered by
        // whichever one it meets first and then meets another, so the shape spreads a shot
        // rather than returning it - the opposite of what the same chequer of flat bricks does

        EndlessIICluster(name: "Gullet", rows: ["C.C",
                                                "C?C",
                                                "C.C"], minimumHeight: 120, weight: 7,
                         legend: ["C": EndlessIIBrickSpec(behaviour: .standard,
                                                          shape: .concave)]),
        // Two columns of dishes facing across a gap. Each one turns a hit back toward the
        // middle, so a ball that gets into the channel is kept there for a while

        EndlessIICluster(name: "Turbine", rows: [".S.",
                                                 "S?S",
                                                 ".S."], minimumHeight: 180, weight: 6,
                         legend: ["S": EndlessIIBrickSpec(behaviour: .multiHit,
                                                          actions: [.spinning])]),
        // Four turning multi-hit bricks around something ordinary. The middle is easy and
        // getting at it is not: the angle each one presents is different every time round, and
        // they take four hits each

        EndlessIICluster(name: "Portcullis", rows: ["DDDDD",
                                                    ".....",
                                                    "?????"], minimumHeight: 140, weight: 7,
                         legend: ["D": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.directional],
                                                          side: .bottom)]),
        // A row that only opens downward, with a row of ordinary bricks beneath it. The bricks
        // under it are the reason to be there and the gate is what makes it a shot rather than
        // a rally: every hit on the lid has to arrive from below, which is where the ball
        // already is - and the row underneath is in the way of exactly that

        EndlessIICluster(name: "Shoalwater", rows: ["ttttt",
                                                    "?????"], minimumHeight: 90, weight: 8,
                         legend: ["t": EndlessIIBrickSpec(behaviour: .standard, size: .tiny)]),
        // A shelf of quarter-cell bricks over ordinary ones. Four times as many hits and each
        // one opens a gap a quarter the size, so it comes apart gradually and what is behind
        // it is visible the whole way through

        EndlessIICluster(name: "Grit", rows: [], minimumHeight: 130, weight: 7,
                         scatter: Scatter(character: "t", count: 10, rows: 3),
                         legend: ["t": EndlessIIBrickSpec(behaviour: .standard, size: .tiny)]),
        // Ten quarter-cell bricks thrown across three rows - forty bricks, none of them worth
        // aiming at and all of them in the way. A scatter of Tiny is the densest thing this
        // catalogue can produce without being a wall

        EndlessIICluster(name: "Shuttle", rows: ["mmm"], minimumHeight: 110, weight: 7,
                         legend: ["m": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.moving])]),
        // Three wanderers side by side. They set off the moment there is room, so the shape
        // this leaves is never the shape it arrived as - and it is one row, so it reads as
        // something loose in the field rather than as a structure

        EndlessIICluster(name: "Cairn", rows: [".g.",
                                               "ggg",
                                               "?.?"], minimumHeight: 160, weight: 6,
                         legend: ["g": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.gravity])]),
        // A pile that falls as it is cleared. Take the bottom out and the rest comes down into
        // whatever the field left below it, so what the shape becomes is decided by where it
        // happened to land

        EndlessIICluster(name: "Keystone", rows: ["?F?",
                                                  "FFF",
                                                  "?F?"], minimumHeight: 210, weight: 5,
                         legend: ["F": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.fixed])]),
        // A cross of anchors with ordinary bricks in the corners. Hit one and it stops where it
        // is for good - and anything that runs into it afterwards is destroyed by it, so where
        // the player chooses to strike decides what the next twenty rows do here

        EndlessIICluster(name: "Sawtooth", rows: ["WwWwW"], minimumHeight: 130, weight: 7,
                         legend: ["W": EndlessIIBrickSpec(behaviour: .standard, shape: .wedge,
                                                          mirrored: true),
                                  "w": EndlessIIBrickSpec(behaviour: .standard,
                                                          shape: .wedge)]),
        // Slopes alternating along a single row, so neighbouring bricks throw a ball opposite
        // ways. One row of it is a surface nothing comes off predictably - and unlike the
        // Jagged paddle it retired with, this one can be cleared

        EndlessIICluster(name: "Rimshot", rows: ["OOO",
                                                 "O?O",
                                                 "OOO"], minimumHeight: 70, weight: 8,
                         legend: ["O": EndlessIIBrickSpec(behaviour: .standard,
                                                          shape: .rounded)]),
        // A ring of rounded bricks around one ordinary cell. Every corner in the shape is a
        // corner a ball glances off, so getting to the middle is luck the first time and aim
        // the second

        EndlessIICluster(name: "Nest", rows: [".DDD.",
                                              "D???D",
                                              ".DDD."], minimumHeight: 230, weight: 5,
                         legend: ["D": EndlessIIBrickSpec(behaviour: .multiHit,
                                                          actions: [.directional])]),
        // A multi-hit shell where every brick opens on a face the generator chose - and it
        // chooses one the ball can reach (round 233), so the way in exists and has to be found

        EndlessIICluster(name: "Hatchery", rows: [".p.",
                                                  "p?p",
                                                  ".p."], minimumHeight: 250, weight: 4,
                         legend: ["p": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.spawner])]),
        // Four spawners around a hole. Each one fills between one and eight of the cells around
        // it as it goes, so clearing this makes more field than it removes - the one shape here
        // that is worse to start than to leave alone

        EndlessIICluster(name: "Powderkeg", rows: ["?x?",
                                                   "xxx",
                                                   "?x?"], minimumHeight: 190, weight: 5,
                         legend: ["x": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.exploding])]),
        // The opposite of the Hatchery, and deliberately the same shape. One hit anywhere on
        // the cross takes the lot and two rows of whatever was around it

        EndlessIICluster(name: "Lantern", rows: [".f.",
                                                 "f?f",
                                                 ".f."], minimumHeight: 100, weight: 7,
                         legend: ["f": EndlessIIBrickSpec(behaviour: .standard,
                                                          actions: [.flashing])]),
        // A shape that is only there half the time. What is inside can be reached whenever the
        // walls are in their passable phase, which is a timing problem rather than an aiming
        // one - and the four are staggered, so it is never open all the way round at once

        EndlessIICluster(name: "Studs", rows: ["i.i.i",
                                               ".N.N.",
                                               "i.i.i"], minimumHeight: 200, weight: 6),
        // Spaced posts that each take a hit to become permanent. What this leaves behind is
        // decided by which ones the player chose to hit.
        //
        // **The two bricks in the middle row are not decoration** (round 238). Studs was six
        // indestructibles and nothing else, and the catalogue-wide rule caught it the first
        // time it ran: "mazes of indestructible bricks dotted with normal bricks so they don't
        // just fly by" (James, round 190). It is the same fault the Comb had and the same fix.
        // A brick that turns permanent when struck is a decision, but a shape with nothing
        // breakable in it is still a shape with nothing to earn - so going in there is worth
        // something now, and the posts are no harder to thread than they were
    ]

    /// The ones allowed at this height.
    static func available(at height: Int) -> [EndlessIICluster] {
        all.filter { height >= $0.minimumHeight }
    }

    /// Picks one, by weight, from what this height offers.
    ///
    /// Weighted rather than uniform so the plain blocks stay the common case and the set
    /// pieces stay set pieces - the same reason the uniform phases carry the lowest weights.
    static func pick(at height: Int, roll: (Int) -> Int) -> EndlessIICluster? {
        let choices = available(at: height)
        guard choices.isEmpty == false else { return nil }

        let total = choices.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return choices.first }

        var drawn = roll(total)
        for cluster in choices {
            drawn -= cluster.weight
            if drawn < 0 { return cluster }
        }
        return choices.last
    }

    /// The columns a cluster could start at, in a field this wide.
    ///
    /// It has to fit whole. A shape half off the side of the field is not the shape, and the
    /// wall would be doing the part of the work the design was supposed to do.
    static func placements(width: Int, in columns: Int) -> [Int] {
        guard width > 0, columns >= width else { return [] }
        return Array(0...(columns - width))
    }

    /// The cluster written out as full-width rows, ready to go through the set-row pipeline.
    ///
    /// Everything outside the shape is `?` - what the generator would have put there anyway -
    /// so the field carries on either side of it. That is the difference between a cluster and
    /// a set row, and it is one character.
    func expanded(atColumn column: Int, fieldWidth: Int) -> [String] {
        rows.map { row in
            let characters = Array(row)
            return String((0..<fieldWidth).map { index -> Character in
                let inside = index - column
                guard inside >= 0, inside < characters.count else { return "?" }
                return characters[inside]
            })
        }
    }
}
