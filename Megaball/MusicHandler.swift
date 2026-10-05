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
        GameScene.noteForHitchWatch("audio session \(category.rawValue.split(separator: ".").last ?? "")")
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
    /// The menu plays the Title Theme while it is ticked and another ticked track when it is
    /// not (round 346); a run draws from the ticked tracks (`MusicSelection`). Nil means the rotation is empty, which is the music
    /// being off in all but name - so nothing plays and nothing fades.
    private func trackURL(for sender: String?) -> URL? {
        sender == "Menu" ? MusicSelection.menuTrack()?.url : MusicSelection.drawATrack()?.url
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
        let playing = player
        sessionQueue.async { playing?.pause() }
        configureSession(.ambient, activate: false)
        // Paused on the audio queue, ahead of the session change queued behind it - see
        // `setVolume` for why nothing here talks to a player from the main thread
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
            setVolume(menuVolumeSet)
        }
    }

    func gameVolume() {
        userSettings()
        if musicSetting {
            setVolume(gameVolumeSet)
        }
    }

    /// Changes the volume on the audio queue rather than on the main thread.
    ///
    /// **The first launch of a run was waiting on the music** (round 372, from James's "At the
    /// start of the game the first brick hit ... can make the frame rate drop"). The ball's first
    /// launch turns the music up to the game's volume, and the player it turns up is the one the
    /// crossfade started a moment earlier on `sessionQueue` - still starting, or still ramping its
    /// fade. Setting `volume` on it from the main thread made the main thread ask the audio queue
    /// where it was and wait for the answer: 130 milliseconds in the simulator's log, a call to
    /// `GetCurrentQueueTime` on the main thread with the queue's start resolving just after it,
    /// in the frame the ball left the paddle. Everything else that touches a player already runs
    /// on this queue, for the same reason (`configureSession`); these were the two left over.
    private func setVolume(_ volume: Float) {
        guard let playing = player else { return }
        sessionQueue.async { playing.volume = volume }
    }
    
    func userSettings() {
        musicSetting = defaults.bool(forKey: "musicSetting")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
    }
    
}
