//
//  EndlessIIFormations.swift
//  Megaball
//
//  One view over everything somebody designed.
//
//  There are two tiers and they are genuinely different things - a set row says "the next row
//  is this", a cluster says "there is a thing over there" - but they are written the same way,
//  built by the same pipeline, and wrong in exactly the same ways. So the checks want one list
//  to walk, and adding a shape to the game should not mean remembering to add it to a test.
//
//  This is that list, and it is *derived* rather than kept: it reads the two catalogues rather
//  than repeating them, so a formation that exists is a formation that is checked. A second
//  copy of the catalogue would be wrong the first time either changed, which is the failure
//  every derived list in this project exists to avoid.
//

import Foundation

/// A designed shape, whichever tier it belongs to.
struct EndlessIIFormation {

    /// What kind of designed thing this is - which is a question about *scope*, not about
    /// contents. Both are drawn the same way and built by the same code.
    enum Tier: String {
        /// Full width. Decides what the whole next row is.
        case setRow
        /// A shape at a column, with the ordinary field either side of it.
        case cluster
    }

    let name: String
    let tier: Tier
    /// The grid, top row first, one character per column.
    let rows: [String]
    /// What this formation's own characters mean. The shared alphabet
    /// (`EndlessIIBrickSpec.classic`) answers anything this does not.
    let legend: [Character: EndlessIIBrickSpec]
    let minimumHeight: Int
    let weight: Int

    /// The spec for one cell, this formation's key first and the shared alphabet after.
    func spec(atRow row: Int, column: Int) -> EndlessIIBrickSpec {
        guard row >= 0, row < rows.count else { return .nothing }
        let characters = Array(rows[row])
        guard column >= 0, column < characters.count else { return .nothing }
        return EndlessIIBrickSpec.spec(for: characters[column], legend: legend)
    }
}

enum EndlessIIFormationCatalogue {

    /// Every designed shape in the game, both tiers.
    ///
    /// Scatters appear with empty `rows`, because a scatter has no drawn grid - its shape is
    /// rolled when it lands. There is nothing to check about a grid that does not exist yet,
    /// and its legend is checked like everybody else's.
    static var all: [EndlessIIFormation] { setRows + clusters }

    static var setRows: [EndlessIIFormation] {
        EndlessIISetRow.all.map {
            EndlessIIFormation(name: $0.name, tier: .setRow, rows: $0.rows,
                               legend: $0.legend, minimumHeight: $0.minimumHeight,
                               weight: 10)
            // Set rows carry no weight of their own - they are drawn uniformly from what the
            // run's schedule has released - so they are all listed as equal here rather than
            // having a number invented for them
        }
    }

    static var clusters: [EndlessIIFormation] {
        (EndlessIICluster.all + EndlessIICluster.pendingLegendSupport).map {
            // The pending ones too. A shape authored today and built in three rounds' time
            // should fail its validation today, while somebody is still looking at it
            EndlessIIFormation(name: $0.name, tier: .cluster, rows: $0.rows,
                               legend: $0.legend, minimumHeight: $0.minimumHeight,
                               weight: $0.weight)
        }
    }
}
