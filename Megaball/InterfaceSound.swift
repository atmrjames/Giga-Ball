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
        guard GameCenterHandler.isRunningTests == false, isOn(in: defaults) else { return }
        InterfaceSound.queue.async {
            guard let player else { return }
            player.currentTime = 0
            player.play()
        }
        // Restarted rather than overlapped: two taps a frame apart are one press as far as a
        // player is concerned, and two copies of one short recording comb filter (round 334)
    }

    /// Where the interface's players are rewound and started - never the main thread.
    ///
    /// **Round 372, chasing James's "At the start of the game the first brick hit ... can make
    /// the frame rate drop".** The simulator's log put a 128-millisecond frame at the start of a
    /// run directly behind a main-thread `GetCurrentQueueTime` on this player's audio queue:
    /// rewinding a player whose queue is still settling - the press that started the run had
    /// started it two seconds earlier, and the game music's session change was landing at the
    /// same moment - makes the caller wait for the queue. `MusicHandler` learned this for the
    /// music and moved its players to a queue of their own; the click and the tally never had.
    /// The first press also builds the player here rather than in the frame that pressed.
    static let queue = DispatchQueue(label: "com.atmrjames.Megaball.interfaceSound")
}

/// The beeps a result screen makes while its numbers count up.
///
/// **James, round 360:** "On the game over / complete screen make a subtle sound effect that
/// plays when the tally animation is happening on the scores. It should be a rapid sequence of
/// beeps similar to the 3, 2, 1 beeps but in faster succession."
///
/// The countdown's own recording, one beep on each of the tally's ticks - the same ten the
/// haptic has always marked - so what is heard and what is felt land together. Each beep a
/// little higher than the last, the way a counter climbing sounds, and quieter than the
/// countdown, because the countdown is an instruction and this is decoration.
enum TallySound {

    static let volume: Float = 0.3

    /// How far the last beep is pitched above the first.
    static let climb: Float = 0.45

    /// The pitch for one tick of a tally that has `ticks` of them.
    static func rate(forTick tick: Int, of ticks: Int) -> Float {
        let share = ticks > 1 ? Float(min(max(tick, 0), ticks - 1))/Float(ticks - 1) : 0
        return 1 + climb*share
    }

    private static var player: AVAudioPlayer? = {
        guard let url = Bundle.main.url(forResource: "countdownTick", withExtension: "m4a"),
              let made = try? AVAudioPlayer(contentsOf: url) else { return nil }
        made.volume = volume
        made.enableRate = true
        made.prepareToPlay()
        return made
    }()

    /// One beep, if the player has the game's sound on - this is the game's result talking,
    /// not a button, so it answers to In-Game Sound rather than to UI Sound.
    static func beep(tick: Int, of ticks: Int, in defaults: UserDefaults = .standard) {
        guard GameCenterHandler.isRunningTests == false,
              defaults.bool(forKey: "soundsSetting") else { return }
        let pitch = rate(forTick: tick, of: ticks)
        InterfaceSound.queue.async {
            guard let player else { return }
            player.rate = pitch
            player.currentTime = 0
            player.play()
        }
        // On the interface's own audio queue, for the click's reason
        // Restarted rather than overlapped, as the click is: the beeps are seventy
        // milliseconds apart and each is fifty long, so they never needed to overlap
    }
}
