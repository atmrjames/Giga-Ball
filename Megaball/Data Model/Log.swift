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
import UIKit

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

    /// **What the game itself is doing.** The session it launched into, the run it started, how
    /// that run ended, and the tripwires that fire when something is wrong.
    ///
    /// Added in round 312, from James: "for future logs, is it worth wiring up any other
    /// metrics/tests/outputs so the information that's captured is a detailed log of what's
    /// happening in the app." The answer turned out to be less about *more* and more about
    /// **findable**. His iPad log was four hundred lines, nearly all of it UIKit complaining
    /// about constraints, with about twenty lines of ours buried in it - and the ones that
    /// mattered were `print()`s, which carry no subsystem and so cannot be filtered to.
    ///
    /// Everything the game has to say goes through here now, so one filter in Console -
    /// `subsystem:com.atmrjames.Megaball` - is the whole story with none of the noise. And the
    /// story is worth telling in order: what was launched, what was played, what went wrong,
    /// what the run came to.
    static let play = Logger(subsystem: subsystem, category: "play")

    /// One line saying what this launch is, written before anything else can go wrong.
    ///
    /// Every question a play-test report raises starts with "on what?" - which build, which
    /// device, how big the window was. Round 312 spent an afternoon on an iPad window question
    /// that one line of this would have answered.
    static func session(window: CGSize, screen: CGSize) {
        let bundle = Bundle.main.infoDictionary
        let version = bundle?["CFBundleShortVersionString"] as? String ?? "?"
        let build = bundle?["CFBundleVersion"] as? String ?? "?"
        var systemInfo = utsname()
        uname(&systemInfo)
        let model = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        play.notice("""
            SESSION Giga-Ball \(version, privacy: .public) (\(build, privacy: .public))             on \(model, privacy: .public)             \(UIDevice.current.systemName, privacy: .public)             \(UIDevice.current.systemVersion, privacy: .public),             window \(Int(window.width), privacy: .public)x\(Int(window.height), privacy: .public)             of screen \(Int(screen.width), privacy: .public)x\(Int(screen.height), privacy: .public)
            """)
    }
}
