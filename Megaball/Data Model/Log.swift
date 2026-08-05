//
//  Log.swift
//  Megaball
//
//  Diagnostics for the failure paths.
//
//  These were print() calls, which write to stdout whether or not anyone is
//  attached, ship in release builds, and are invisible on a real device once
//  it is unplugged - so the one place the messages would actually be useful,
//  a player hitting a decode failure in the wild, is the one place they could
//  never be read.
//
//  os.Logger goes to the unified log instead: off the hot path when nothing is
//  listening, readable in Console or `log collect` from a device, and filtered
//  by the categories below.
//
//  Everything logged here is diagnostic text - decode failures, Game Center
//  submission errors - with no player data in it, so it is marked public
//  rather than being redacted to <private> in release, which would leave only
//  the fact that something failed.
//

import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.atmrjames.Megaball"

    /// Saving and loading progress, stats and settings.
    static let data = Logger(subsystem: subsystem, category: "data")
    /// Leaderboard and achievement submission.
    static let gameCenter = Logger(subsystem: subsystem, category: "gameCenter")
    /// Music and sound effects.
    static let audio = Logger(subsystem: subsystem, category: "audio")
    /// View controllers and presentation.
    static let ui = Logger(subsystem: subsystem, category: "ui")
}
