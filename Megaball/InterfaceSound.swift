//
//  InterfaceSound.swift
//  Giga-Ball
//
//  The quiet click a button makes.
//

import Foundation
import AVFoundation

/// The app's interface tap, played wherever a button reports itself pressed.
///
/// **James, round 340: "UI button clicks for when user presses buttons in the UI - should be
/// relatively quiet."**
///
/// A single player rather than an action, because the menus are UIKit and have no scene to run
/// one on - and a single *shared* player because a tap can be answered in any of sixteen
/// screens and loading a file per press is a file read on the main thread.
///
/// **Its own setting, not the haptics one and not the game's** (round 341). The eighty-nine
/// places that fire the tap haptic are split between guarding it on `hapticsSetting` and
/// firing it unconditionally, and a sound that inherited either of those would be a sound the
/// player cannot turn off with the control that says so.
enum InterfaceSound {

    /// How loud, against the game's own effects.
    ///
    /// A click under every press is heard far more often than anything in a level, so it is
    /// mixed well below them: present when you are listening for it, invisible when you are
    /// not.
    static let clickVolume: Float = 0.25

    private static var player: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "buttonClick", withExtension: "m4a"),
              let made = try? AVAudioPlayer(contentsOf: url) else { return nil }
        made.volume = clickVolume
        made.prepareToPlay()
        return made
        // Nil leaves every press silent, which is what a build without the recording should
        // do - the same rule `GameScene.mayhemSound` follows for the scene's own effects
    }()

    /// The setting that turns it off, which is not the game's.
    ///
    /// **James, round 341: "in settings, create a new on/off setting for UI Sound that turns on
    /// and off the button click sound separately from the game sounds. Rename the sounds button
    /// to In-Game Sound."** A player who plays with the sound down in a quiet room wants to
    /// hear the ball and not the menus, or the other way round, and one switch could not say
    /// either.
    static let settingKey = "interfaceSoundSetting"

    /// Whether it is on. A player who has never touched the new switch has it on: `bool(forKey:)`
    /// answers false for a key that was never written, which would have silenced every
    /// existing player's menus on the day the setting arrived.
    static func isOn(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: settingKey) as? Bool ?? true
    }

    /// Plays it, if the player has interface sound on.
    static func click(in defaults: UserDefaults = .standard) {
        guard GameCenterHandler.isRunningTests == false,
              isOn(in: defaults), let player else { return }
        player.currentTime = 0
        player.play()
        // Restarted rather than overlapped: two taps a frame apart are one press as far as a
        // player is concerned, and two copies of one short recording comb filter (round 334)
    }
}
