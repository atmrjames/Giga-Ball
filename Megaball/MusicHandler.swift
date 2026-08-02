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
    var musicSetting: Bool?
    var gameInProgress: Bool?
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
                print("Audio session setup failed: ", error.localizedDescription)
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

    func playMusic(sender: String? = "") {
        userSettings()
        if musicSetting! == false {
            return
        }
        // Check if music setting is on

        let titleTheme = Bundle.main.url(forResource: "Giga-Ball - Title Theme - Loop", withExtension: "mp3")
        
        let theEspace = Bundle.main.url(forResource: "Giga-Ball - The Escape - Loop", withExtension: "mp3")
        let theRebound = Bundle.main.url(forResource: "Giga-Ball - The Rebound - Loop", withExtension: "mp3")
        let theStrategy = Bundle.main.url(forResource: "Giga-Ball - The Strategy - Loop", withExtension: "mp3")
        let gameMusicArray = [theEspace, theRebound, theStrategy]
        // Set up tracks
        
        var selectedTrackURL = gameMusicArray.randomElement()!
        if sender == "Menu" {
            selectedTrackURL = titleTheme
        }
        // Only play title theme in main menu
        
        configureSession(.soloAmbient, activate: true) { [weak self] in
            guard let self = self, let trackURL = selectedTrackURL else { return }
            do {
                let player = try AVAudioPlayer(contentsOf: trackURL)
                player.delegate = self
                player.numberOfLoops = -1
                // Loop infinitely
                player.volume = (self.gameInProgress ?? false) ? self.gameVolumeSet : self.menuVolumeSet
                player.prepareToPlay()
                player.play()
                DispatchQueue.main.async { self.player = player }
                // Published back on the main queue, where every other method touches it
            } catch let error {
                print("Music track failed: ", error.localizedDescription)
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
        if musicSetting! {
            player?.volume = menuVolumeSet
        }
    }

    func gameVolume() {
        userSettings()
        if musicSetting! {
            player?.volume = gameVolumeSet
        }
    }
    
    func userSettings() {
        musicSetting = defaults.bool(forKey: "musicSetting")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
    }
    
}
