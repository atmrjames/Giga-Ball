//
//  MusicTrackTests.swift
//  GigaBallTests
//
//  James, round 207: "Arrow icon on music setting cell - opens a new page with another table
//  view. Each cell in the view is one of the tracks in the game. Users can preview the tracks
//  here, or untick one or all of them to play whilst playing the game. If the user unselects
//  all of them, the music setting is set to off. If the music setting is set to on, all tracks
//  are selected by default."
//
//  The two sentences at the end are the whole of the state model, and they are what these
//  pin: the master switch and the ticks are two views of one thing, so neither may be left
//  saying something the other contradicts.
//

import XCTest
@testable import Giga_Ball

final class MusicTrackTests: XCTestCase {

    private var store: InMemoryKeyValueStore!

    override func setUp() {
        super.setUp()
        store = InMemoryKeyValueStore()
        // In memory, not `UserDefaults(suiteName:)` - that looks like isolation and is not,
        // because its search list still includes the host app's own domain (SavedGameTests)
    }

    func testEveryTrackNamesAFileThatIsActuallyInTheBundle() {
        // The filenames were four string literals inside `playMusic`; deriving them from the
        // name means a typo shows up here rather than as silence in one track out of three
        for track in MusicTrack.allCases {
            XCTAssertNotNil(track.url, "\(track.name) has no file at \(track.fileName)")
        }
    }

    func testAFreshPlayerHasEveryGameTrackOn() {
        XCTAssertEqual(MusicSelection.enabled(in: store), MusicTrack.gameTracks)
    }

    /// The menu's theme is not part of a run's rotation, so it is not one of the things the
    /// screen can turn off - `playMusic(sender: "Menu")` plays it and nothing else, and
    /// unticking it would leave the main menu silent rather than change what a run plays.
    func testTheTitleThemeIsNotInTheRotationAndCannotBeUnticked() {
        XCTAssertFalse(MusicTrack.gameTracks.contains(.titleTheme))
        MusicSelection.set(.titleTheme, enabled: false, in: store)
        XCTAssertEqual(MusicSelection.enabled(in: store), MusicTrack.gameTracks)
    }

    func testUntickingATrackTakesItOutOfTheRotation() {
        MusicSelection.set(.theEscape, enabled: false, in: store)
        XCTAssertFalse(MusicSelection.isEnabled(.theEscape, in: store))
        XCTAssertTrue(MusicSelection.isEnabled(.theRebound, in: store))
        for _ in 0..<50 {
            XCTAssertNotEqual(MusicSelection.drawATrack(in: store), .theEscape,
                              "a run drew a track the player turned off")
        }
    }

    func testUntickingTheLastOneLeavesNothingToPlay() {
        for track in MusicTrack.gameTracks.dropLast() {
            XCTAssertTrue(MusicSelection.set(track, enabled: false, in: store),
                          "there is still something to play")
        }
        XCTAssertFalse(MusicSelection.set(MusicTrack.gameTracks.last!, enabled: false,
                                          in: store),
                       "the last one going off is what turns the music setting off")
        XCTAssertNil(MusicSelection.drawATrack(in: store))
    }

    func testTurningTheMusicBackOnTicksEverything() {
        for track in MusicTrack.gameTracks { MusicSelection.set(track, enabled: false, in: store) }
        MusicSelection.selectAll(in: store)
        XCTAssertEqual(MusicSelection.enabled(in: store), MusicTrack.gameTracks)
    }

    /// **A track added to the game later must play for people who already have a stored
    /// choice.** The stored value is the set that is *off* for exactly this reason: storing
    /// the "on" set would quietly exclude every new track from every existing player's
    /// rotation, and from the outside that looks identical to the track never shipping - which
    /// is the same shape as §8.6's "a style has to be in a pool to exist".
    func testATrackAddedLaterIsPlayingForSomeoneWhoAlreadyChose() {
        MusicSelection.set(.theEscape, enabled: false, in: store)
        let storedOff = store.object(forKey: MusicSelection.defaultsKey) as? [String]
        XCTAssertEqual(storedOff, [MusicTrack.theEscape.rawValue],
                       "only the deselected track is written down")

        // Whatever else the game grows, it is not in that list, so it is on
        for track in MusicTrack.gameTracks where track != .theEscape {
            XCTAssertTrue(MusicSelection.isEnabled(track, in: store))
        }
    }

    /// Nonsense in the store reads as "nothing is off", which is the safe direction: the
    /// player hears their music rather than silence they cannot explain.
    /// The crossfade has to make exactly the same choice `playMusic` does, or the menu could
    /// fade into a track the player turned off. Both ask `trackURL(for:)`, and this pins what
    /// that answers: the menu's own theme for the menu, and only ticked tracks otherwise.
    func testTheMenuAlwaysGetsItsOwnThemeAndARunNeverDoes() {
        XCTAssertNotNil(MusicTrack.titleTheme.url, "the menu's theme has to exist to be used")
        // Was `titleTheme.url == titleTheme.url`, which is true of anything (round 212's audit)
        var drawn = 0
        for _ in 0..<50 {
            guard let track = MusicSelection.drawATrack(in: store) else { continue }
            drawn += 1
            XCTAssertNotEqual(track, .titleTheme, "the menu's theme is not in a run's rotation")
        }
        XCTAssertGreaterThan(drawn, 0, "fifty draws and nothing came out")
    }

    /// And with every track off there is nothing to fade *to*, so the crossfade must decline
    /// rather than fade the current track out into silence.
    func testWithEveryTrackOffThereIsNothingToFadeTo() {
        for track in MusicTrack.gameTracks {
            MusicSelection.set(track, enabled: false, in: store)
        }
        XCTAssertNil(MusicSelection.drawATrack(in: store))
    }

    func testRubbishInTheStoreLeavesEveryTrackPlaying() {
        store.set(42, forKey: MusicSelection.defaultsKey)
        XCTAssertEqual(MusicSelection.enabled(in: store), MusicTrack.gameTracks)
    }
}
