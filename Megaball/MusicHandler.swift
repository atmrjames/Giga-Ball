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
    
    func playMusic(sender: String? = "") {        
        userSettings()
        if musicSetting == false {
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
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: selectedTrackURL!)
            player!.delegate = self
            player!.numberOfLoops = -1
            // Loop infinitely
            player!.prepareToPlay()
            player!.play()
            if gameInProgress! {
                player!.volume = gameVolumeSet
            } else {
                player!.volume = menuVolumeSet
            }
        } catch let error {
            print(error.localizedDescription)
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
        musicSetting = false
        player?.pause()
    }
    
    func resumeMusic() {
        player?.play()
    }
    
    func menuVolume() {
        userSettings()
        if musicSetting! {
            player!.volume = menuVolumeSet
        }
    }
    
    func gameVolume() {
        userSettings()
        if musicSetting! {
            player!.volume = gameVolumeSet
        }
    }
    
    func userSettings() {
        musicSetting = defaults.bool(forKey: "musicSetting")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
    }
    
}
