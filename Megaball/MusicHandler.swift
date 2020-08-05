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
    
    var menuVolumeSet: Float = 0.35
    var gameVolumeSet: Float = 1.00
    
    func playMusic(sender: String? = "") {        
        userSettings()
        if musicSetting == false {
            return
        }
        // Check if music setting is on
        
        let theEspace = Bundle.main.url(forResource: "Gigaball - The Escape", withExtension: "mp3")
        let theRebound = Bundle.main.url(forResource: "Gigaball - The Rebound", withExtension: "mp3")
        let theStrategy = Bundle.main.url(forResource: "Gigaball - The Strategy", withExtension: "mp3")
        let titleTheme = Bundle.main.url(forResource: "Gigaball - Title Theme", withExtension: "mp3")
        let gameMusicArray = [theEspace, theRebound, theStrategy, titleTheme]
        
        var newRandomPlayerTrack = Int.random(in: 1...gameMusicArray.count)
        while newRandomPlayerTrack == randomPlayerTrack {
            newRandomPlayerTrack = Int.random(in: 1...gameMusicArray.count)
        }
        randomPlayerTrack = newRandomPlayerTrack
        // Don't allow same track to play twice in a row
        
        var selectedTrackURL = gameMusicArray[randomPlayerTrack-1]
        if sender == "Menu" {
            selectedTrackURL = titleTheme
        }
        // Only play title theme in main menu
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: selectedTrackURL!)
            player!.delegate = self
            player!.prepareToPlay()
            player!.play()
            print("llama llama music volume check: ", gameInProgress)
            if gameInProgress! {
                player!.volume = gameVolumeSet
            } else {
                player!.volume = menuVolumeSet
            }
            print("play music success")
        } catch let error {
            print("play music error")
            print(error.localizedDescription)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playMusic()
    }
    // Play another music track once background audio has ended
    
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
        // Set the background music to menu volume
    }
    
    func gameVolume() {
        userSettings()
        if musicSetting! {
            player!.volume = gameVolumeSet
        }
        // Set the background music to game volume
    }
    
    func userSettings() {
        musicSetting = defaults.bool(forKey: "musicSetting")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
    }
    
}
