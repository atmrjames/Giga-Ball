//
//  EndlessIIRivals.swift
//  Megaball
//
//  The other players' heights, and which of them are worth drawing a line at.
//
//  Height in Endless Mayhem already has lines on it: one every hundred metres, and one at the
//  player's own best. This adds the people. A run that passes "ALEX 412m" on the way up has
//  been given something the hundred-metre lines cannot give it - the board made local, at the
//  exact moment it matters, rather than a table read afterwards.
//
//  Which players is the whole design question, and the answer is *the ones just above you*.
//  The board's leader is either unreachable or, on a board a day old, already behind - either
//  way it is a line that is never passed. The three players immediately above the local
//  player's rank are by definition within reach of the run being played.
//

import Foundation

/// One other player's best height, as a line to draw.
struct EndlessIIRival: Equatable {
    let name: String
    let height: Int
}

enum EndlessIIRivals {

    /// How many rival lines a run may carry at once.
    ///
    /// Three. The markers are furniture behind the field and there are already two kinds of
    /// them; a fourth and fifth name turns the backdrop into a scoreboard, and the whole point
    /// of these is that they are read in passing.
    static let mostLines = 3

    /// Which of the loaded entries become lines.
    ///
    /// - a rival at or below the height the run starts from is behind the player already, and
    ///   a line that is passed before the first row descends is never seen;
    /// - two players on the same height share a line rather than stacking two labels on one
    ///   row, and the first of them - the higher-ranked - keeps it;
    /// - a rival standing exactly on the player's own best would draw over that marker, and
    ///   the personal best is the more useful of the two;
    /// - and the list is capped, nearest first, so the lines that arrive are the ones about
    ///   to be reached rather than whichever three the board returned.
    ///
    /// Everything here is arithmetic on a list, which is the half of this feature that can be
    /// tested: the board itself cannot be, because it needs other people to have played.
    static func lines(from entries: [EndlessIIRival], playerBest: Int,
                      startingAt height: Int = 0) -> [EndlessIIRival] {
        var taken: Set<Int> = playerBest > 0 ? [playerBest] : []
        var lines: [EndlessIIRival] = []

        for rival in entries.sorted(by: { $0.height < $1.height }) {
            guard rival.height > height else { continue }
            guard taken.contains(rival.height) == false else { continue }
            taken.insert(rival.height)
            lines.append(rival)
            if lines.count == mostLines { break }
        }
        return lines
    }

    /// What a rival's line says.
    ///
    /// The name is trimmed rather than shrunk: the label shares a row with the field and is
    /// drawn at the same size as a hundred-metre line's, so a long display name would run
    /// under the bricks. Sixteen characters is what fits beside a four-digit height at that
    /// size on the narrowest device the game supports.
    static let longestName = 16

    static func label(for rival: EndlessIIRival) -> String {
        let name = rival.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let shown = name.count > longestName
            ? String(name.prefix(longestName - 1)) + "\u{2026}"
            : name
        return shown.isEmpty ? "\(rival.height)m" : "\(shown.uppercased()) \(rival.height)m"
    }
}
