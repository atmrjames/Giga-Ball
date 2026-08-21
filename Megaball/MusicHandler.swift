//
//  MusicHandler.swift
//  Megaball
//
//  Created by James Harding on 04/08/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import AVFoundation

final class MusicHandler: NSObject, AVAudioPlayerDelegate {
    typealias CompletionBlock = (Error?) -> Void
    static let sharedHelper = MusicHandler()
    
    let defaults = UserDefaults.standard
    var musicSetting: Bool = true
    var gameInProgress: Bool = false
    // User settings
    
    var player: AVAudioPlayer?
    var randomPlayerTrack: Int = 0
    // Setup game music
        
    var menuVolumeSet: Float = 0.50
    var gameVolumeSet: Float = 1.00

    private let sessionQueue = DispatchQueue(label: "com.atmrjames.Megaball.audioSession")
    // Audio session calls block while the route is established, which iOS warns about when
    // done on the main thread. They are serialised here instead, off the main thread.

    private func configureSession(_ category: AVAudioSession.Category, activate: Bool, then work: (() -> Void)? = nil) {
        sessionQueue.async {
            do {
                try AVAudioSession.sharedInstance().setCategory(category, mode: .default)
                if activate {
                    try AVAudioSession.sharedInstance().setActive(true)
                }
            } catch let error {
                Log.audio.error("Audio session setup failed: \(error.localizedDescription, privacy: .public)")
            }
            work?()
            // Playback runs here too. AVAudioPlayer implicitly activates the session, which
            // triggers the same hang warning if play() is called on the main thread
        }
    }

    func prepareSession() {
        configureSession(.ambient, activate: false)
        // Ambient by default so other apps' audio keeps playing when the game's music is off
    }

    /// How long one track takes to become another.
    ///
    /// James, round 210: "when the music goes from the main menu to a game, it abruptly
    /// changes. Can we make this transition smoother using fade out / fade in, or some
    /// crossover mixing of the tracks?"
    ///
    /// Long enough to be a mix rather than a cut, short enough that the game has not started
    /// before the menu's theme has finished leaving.
    static let crossfadeDuration: TimeInterval = 1.4

    /// Which track a caller is asking for.
    ///
    /// The menu has one theme and always has; everything else draws from the tracks the player
    /// left ticked (`MusicSelection`). Nil means the rotation is empty, which is the music
    /// being off in all but name - so nothing plays and nothing fades.
    private func trackURL(for sender: String?) -> URL? {
        sender == "Menu" ? MusicTrack.titleTheme.url : MusicSelection.drawATrack()?.url
    }

    private var wantedVolume: Float { gameInProgress ? gameVolumeSet : menuVolumeSet }

    /// Fades the current track out while the next one fades in.
    ///
    /// Both players run for the length of the fade, which is what makes it a crossover rather
    /// than a gap: `AVAudioPlayer.setVolume(_:fadeDuration:)` does the ramp itself, so nothing
    /// here has to run a timer against the audio thread. The outgoing player is captured by
    /// the closure that stops it, so it stays alive exactly as long as it is still audible.
    ///
    /// With nothing playing there is nothing to fade from, so this is an ordinary start.
    func crossfadeMusic(sender: String? = "") {
        userSettings()
        guard musicSetting else { return }
        guard let outgoing = player, outgoing.isPlaying else {
            playMusic(sender: sender)
            return
        }
        guard let trackURL = trackURL(for: sender) else { return }

        let duration = MusicHandler.crossfadeDuration
        let target = wantedVolume

        configureSession(.soloAmbient, activate: true) { [weak self] in
            guard let self = self else { return }
            do {
                let incoming = try AVAudioPlayer(contentsOf: trackURL)
                incoming.delegate = self
                incoming.numberOfLoops = -1
                incoming.volume = 0
                incoming.prepareToPlay()
                incoming.play()
                incoming.setVolume(target, fadeDuration: duration)
                outgoing.setVolume(0, fadeDuration: duration)
                DispatchQueue.main.async {
                    self.player = incoming
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        outgoing.stop()
                        // Stopped only once it is silent. Stopping it now is the hard cut
                        // this method exists to remove
                    }
                }
            } catch let error {
                Log.audio.error("Crossfade failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func playMusic(sender: String? = "") {
        userSettings()
        if musicSetting == false {
            return
        }
        // Check if music setting is on

        guard let selectedTrackURL = trackURL(for: sender) else { return }
        // **Only the tracks the player left ticked** (round 207), and the menu's own theme for
        // the menu - both decided in one place now, because the crossfade has to make exactly
        // the same choice this does
        
        configureSession(.soloAmbient, activate: true) { [weak self] in
            guard let self = self else { return }
            let trackURL = selectedTrackURL
            do {
                let player = try AVAudioPlayer(contentsOf: trackURL)
                player.delegate = self
                player.numberOfLoops = -1
                // Loop infinitely
                player.volume = self.gameInProgress ? self.gameVolumeSet : self.menuVolumeSet
                player.prepareToPlay()
                player.play()
                DispatchQueue.main.async { self.player = player }
                // Published back on the main queue, where every other method touches it
            } catch let error {
                Log.audio.error("Music track failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//    }
//    // What to do when a track ends
    
    func stopMusic() {
        player?.stop()
        player = nil
    }
    
    func pauseMusic() {
        userSettings()
        player?.pause()
        configureSession(.ambient, activate: false)
        // Drop back to ambient while paused so other apps' audio is not held silent
    }

    func resumeMusic() {
        configureSession(.soloAmbient, activate: true) { [weak self] in
            self?.player?.play()
        }
    }

    func menuVolume() {
        userSettings()
        if musicSetting {
            player?.volume = menuVolumeSet
        }
    }

    func gameVolume() {
        userSettings()
        if musicSetting {
            player?.volume = gameVolumeSet
        }
    }
    
    func userSettings() {
        musicSetting = defaults.bool(forKey: "musicSetting")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
    }
    
}
