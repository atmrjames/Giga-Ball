//
//  MusicTrack.swift
//  Megaball
//
//  The game's music, as a list rather than four filenames written into `playMusic`.
//

import Foundation

/// One piece of music in the game.
///
/// The tracks were four `Bundle.main.url(forResource:)` calls inside `playMusic`, three of
/// them gathered into an array on every call. A player who wants to choose between them needs
/// them to be a thing that can be listed, named and remembered, so they are a type - and the
/// screen that lists them reads its rows off `allCases` rather than carrying its own copy,
/// which is this project's rule about second copies of a decision.
enum MusicTrack: String, CaseIterable, Codable {
    case titleTheme
    case theEscape
    case theRebound
    case theStrategy

    /// What the player is shown.
    var name: String {
        switch self {
        case .titleTheme: return "Title Theme"
        case .theEscape: return "The Escape"
        case .theRebound: return "The Rebound"
        case .theStrategy: return "The Strategy"
        }
    }

    /// The file in the bundle, without its extension.
    var fileName: String { "Giga-Ball - \(name) - Loop" }

    static let fileExtension = "mp3"

    var url: URL? {
        Bundle.main.url(forResource: fileName, withExtension: MusicTrack.fileExtension)
    }

    /// The tracks a run draws from first: everything but the menu's theme.
    ///
    /// **Every track is choosable since round 346** (James: "can the theme music be selectable
    /// and deselectable like the other tracks. If it's deselected, other tracks are used on the
    /// menu pages"). It used to be listed but not tickable, because the menu played it and
    /// nothing else and unticking it would have silenced the main menu. Now the menu falls back
    /// to the other ticked tracks (`MusicSelection.menuTrack`), and a run falls back to the
    /// theme only when it is the one track left ticked - so no ticked list is ever silent.
    static var gameTracks: [MusicTrack] { allCases.filter { $0 != .titleTheme } }
}

/// Which tracks a run may draw from, and the rules that keep that in step with the master
/// music switch.
///
/// **The stored value is the set that is *off*, not the set that is on.** A track added to the
/// game later is then playing by default for everyone who already has a stored value, with no
/// migration and no version check - where storing the "on" set would silently exclude it from
/// every existing player's rotation and look exactly like the new track never shipping. That is
/// the same trap the power-up arrays hit from the other side, and `CloudKitHandler.padded(_:toMatch:)`
/// exists because of it.
enum MusicSelection {
    static let defaultsKey = "musicTracksOff"

    /// Every track the player has left ticked, the menu's theme included.
    static func enabled(in store: KeyValueStore = UserDefaults.standard) -> [MusicTrack] {
        let off = Set(storedOff(in: store))
        return MusicTrack.allCases.filter { off.contains($0.rawValue) == false }
    }

    static func isEnabled(_ track: MusicTrack, in store: KeyValueStore = UserDefaults.standard) -> Bool {
        enabled(in: store).contains(track)
    }

    /// Turns one track on or off and reports whether any are left.
    ///
    /// **Unticking the last one turns the music off** (James, round 207: "if the user
    /// unselects all of them, the music setting is set to off"), which is the honest reading -
    /// a rotation with nothing in it is silence, and silence with the switch still saying "on"
    /// is a setting that lies. The caller does the switching, because it also has to stop what
    /// is playing; this owns what the two states mean.
    @discardableResult
    static func set(_ track: MusicTrack, enabled: Bool,
                    in store: KeyValueStore = UserDefaults.standard) -> Bool {
        var off = Set(storedOff(in: store))
        if enabled { off.remove(track.rawValue) } else { off.insert(track.rawValue) }
        store.set(Array(off), forKey: defaultsKey)
        return anyEnabled(in: store)
    }

    /// The stored off-set, read defensively.
    ///
    /// `object(forKey:)` answers whatever is there, and what is there is whatever an older
    /// build - or a corrupted write - left behind. Anything that is not a list of strings is
    /// read as "nothing is off", which is the safe direction: the player hears their music.
    private static func storedOff(in store: KeyValueStore) -> [String] {
        store.object(forKey: defaultsKey) as? [String] ?? []
    }

    static func anyEnabled(in store: KeyValueStore = UserDefaults.standard) -> Bool {
        enabled(in: store).isEmpty == false
    }

    /// **Everything back on** (James: "if the music setting is set to on, all tracks are
    /// selected by default").
    ///
    /// Called when the master switch is turned on, so the two can never disagree: the switch
    /// being on and every track being unticked would be the same lie from the other direction.
    static func selectAll(in store: KeyValueStore = UserDefaults.standard) {
        store.set([String](), forKey: defaultsKey)
    }

    /// One track for a run to play, or nil if the player has turned them all off.
    ///
    /// The ticked game tracks; the Title Theme only when it is the one track still ticked.
    static func drawATrack(in store: KeyValueStore = UserDefaults.standard) -> MusicTrack? {
        let ticked = enabled(in: store)
        return ticked.filter { $0 != .titleTheme }.randomElement()
            ?? (ticked.contains(.titleTheme) ? .titleTheme : nil)
    }

    /// What the menus play: the Title Theme while it is ticked, and otherwise one of the other
    /// ticked tracks (James, round 346). Nil only when nothing is ticked, which is the music
    /// being off.
    static func menuTrack(in store: KeyValueStore = UserDefaults.standard) -> MusicTrack? {
        let ticked = enabled(in: store)
        return ticked.contains(.titleTheme) ? .titleTheme : ticked.randomElement()
    }
}
