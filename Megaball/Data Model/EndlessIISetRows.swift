//
//  EndlessIISetRows.swift
//  Megaball
//
//  Rows somebody designed, among rows nobody did.
//
//  Everything else about the field is drawn from weights, and weighted randomness is very
//  good at producing fields that are different from each other and bad at producing fields
//  that mean anything. A row that was arranged on purpose reads completely differently: a
//  wall with one gap in it is a shot to find, where the same number of bricks scattered is
//  just a number of bricks.
//
//  They are rare and short for exactly the reason phases are - the moment a designed shape
//  becomes the norm it stops being a landmark and starts being the wallpaper.
//

import Foundation

/// One designed run of one to three rows.
///
/// Written out as text because that is the form a person can actually read and edit. Each
/// character is a column, top row first.
///
///     .  empty        N  ordinary brick     M  multi-hit
///     i  indestructible x1                  I  indestructible x2
///     ?  whatever the generator would have put there anyway
struct EndlessIISetRow {
    let name: String
    let rows: [String]
    /// The height below which this one does not appear.
    let minimumHeight: Int

    /// How wide the patterns are written for. A field of a different width is padded with
    /// empties rather than being stretched, so a shape stays the shape it was drawn as.
    static let designedForColumns = 11

    static let all: [EndlessIISetRow] = [
        EndlessIISetRow(name: "Comb", rows: ["I.I.I.I.I.I"], minimumHeight: 150),
        // The alternating indestructible row that already existed, written down. Pushed
        // deep after play-testing: it is one of the hardest shapes in the pool, and it was
        // arriving in the opening minutes

        EndlessIISetRow(name: "Gate", rows: ["NNNNN.NNNNN"], minimumHeight: 30),
        // A wall with one way through. The whole row is one shot

        EndlessIISetRow(name: "Funnel", rows: ["NN.......NN",
                                               ".NN.....NN.",
                                               "..NN...NN.."], minimumHeight: 90),
        // Opens downward, so the way in gets easier the longer you leave it

        EndlessIISetRow(name: "Pillars", rows: ["I..I..I..I.",
                                                "N..N..N..N."], minimumHeight: 120),
        // Indestructible posts with ordinary bricks hanging off them

        EndlessIISetRow(name: "Chequer", rows: ["N.N.N.N.N.N",
                                                ".N.N.N.N.N."], minimumHeight: 60),

        EndlessIISetRow(name: "Vault", rows: ["IIIIIIIIIII",
                                              "..MMMMMMM..",
                                              "....NNN...."], minimumHeight: 200),
        // An indestructible lid over something worth getting at

        EndlessIISetRow(name: "Split", rows: ["NNNNN.NNNNN",
                                              "....I.I...."], minimumHeight: 150),
        // The gap from the row above is guarded once you are through it

        EndlessIISetRow(name: "Steps", rows: ["N.........N",
                                              ".N.......N.",
                                              "..N.....N.."], minimumHeight: 70),

        EndlessIISetRow(name: "Shoal", rows: ["?.?.?.?.?.?"], minimumHeight: 0),
        // The opening set row now the Comb has gone deep - designed spacing, undesigned
        // contents, and nothing about it punishes a new player
        // Designed spacing, undesigned contents - a shape that still varies

        EndlessIISetRow(name: "Keep", rows: ["..IIIII....",
                                             "..I???I....",
                                             "..IIIII...."], minimumHeight: 250),
        // Something walled in. Reachable only once the walls have been dealt with
    ]

    /// The ones allowed at this height.
    static func available(at height: Int) -> [EndlessIISetRow] {
        all.filter { height >= $0.minimumHeight }
    }

    /// What belongs in a column of one of this pattern's rows.
    ///
    /// Anything outside the written width is empty, so a narrower or wider field leaves the
    /// shape alone rather than distorting it.
    static func character(in row: String, column: Int) -> Character {
        let characters = Array(row)
        guard column >= 0, column < characters.count else { return "." }
        return characters[column]
    }
}
