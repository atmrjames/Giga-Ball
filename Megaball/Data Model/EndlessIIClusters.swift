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
/// Written as text, top row first, exactly as a set row is - because that is the form a person
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

    var height: Int { rows.count }
    var width: Int { rows.map(\.count).max() ?? 0 }

    init(name: String, rows: [String], minimumHeight: Int, weight: Int = 10,
         scatter: Scatter? = nil) {
        self.name = name
        self.rows = rows
        self.minimumHeight = minimumHeight
        self.weight = weight
        self.scatter = scatter
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
                                minimumHeight: minimumHeight, weight: weight)
    }

    static let all: [EndlessIICluster] = [

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

        EndlessIICluster(name: "Studs", rows: ["i.i.i",
                                               ".....",
                                               "i.i.i"], minimumHeight: 200, weight: 6),
        // Spaced posts that each take a hit to become permanent. What this leaves behind is
        // decided by which ones the player chose to hit
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
