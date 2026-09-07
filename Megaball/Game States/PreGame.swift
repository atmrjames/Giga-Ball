//
//  Pre Game.swift
//  Megaball
//
//  Created by James Harding on 22/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class PreGame: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
                                        
        self.resetGame()
        
        let wait = SKAction.wait(forDuration: 1.0)
        // Add slight delay when moving in from main menu
        scene.self.run(wait, completion: {
            if self.scene.musicSetting {
                MusicHandler.sharedHelper.crossfadeMusic(sender: "PreGame")
                // **Mixed, not cut** (James, round 210: "when the music goes from the main menu
                // to a game, it abruptly changes"). This was a stop followed immediately by a
                // start, which is the title theme ending mid-bar and a game track beginning at
                // full volume in the same instant
            }
            self.scene.gameState.enter(Playing.self)
        })
        
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func resetGame() {
        
        if scene.musicSetting {
            MusicHandler.sharedHelper.menuVolume()
        }
        
        scene.scoreLabel.isHidden = true
        scene.multiplierLabel.isHidden = true
        scene.setMultiplierColour(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        scene.pauseButton.isHidden = true
        scene.endlessGameIcon.isHidden = true
        scene.setLivesRowHidden(true)
        scene.ballIsOnPaddle = true
        // Hide labels
        
        scene.powerUpIconReset(sender: "")
        // Reset power-up icons locked icon if power-up locked
        
        scene.ballStartingPositionY = scene.paddlePositionY + scene.paddle.size.height/2 + scene.ballSize/2 + 1
        // Redeclare ballStartingPositionY
            
        if let startingLevelNumber = scene.gameViewControllerDelegate!.selectedLevel {
            scene.startLevelNumber = startingLevelNumber
            scene.levelNumber = scene.startLevelNumber
        }
        if let endingingLevelNumber = scene.gameViewControllerDelegate!.numberOfLevels {
            scene.numberOfLevels = endingingLevelNumber
            scene.endLevelNumber = scene.levelNumber + endingingLevelNumber - 1
        }
        if let levelSender = scene.gameViewControllerDelegate!.levelSender {
            scene.levelSender = levelSender
        }
        if let levelPack = scene.gameViewControllerDelegate!.levelPack {
            scene.packNumber = levelPack
        }
        // Redeclare the game scene properties as passed in
        
        scene.background.texture = scene.gameBackground
        // Set the background texture
        
        scene.totalScore = 0
        scene.endlessBestBeaten = false
        // A new run has not beaten anything yet - see `refreshEndlessIIBest`, where the flag is
        // sticky *within* a run so a resume cannot take the news back
        InGameRecents.shared.reset()
        // A new run starts with nothing seen - the pause reference pages' recents are
        // this run's, never the last one's

        if scene.startLevelNumber == 0 {
            scene.numberOfLives = scene.dailyStartingLives ?? 0
            // The day's word first (Extra Balls racks reserves in an endless daily),
            // the mode's own empty rack otherwise
        } else {
            scene.numberOfLives = scene.dailyStartingLives ?? GameScene.classicStartingRack
            // The day's word first, the mode's own rack otherwise - the same constant
            // `dailyStartingLives` adds its two to, so the two cannot drift apart
        }
        // The count is the rack of reserve balls - the ball on the paddle is on top of it
        scene.multiplier = Scoring.multiplierBase
        logTheRun()
        scene.gameoverStatus = false
        
        scene.deathsPerLevel = 0
        scene.deathsPerPack = 0
        scene.powerUpsCollectedPerLevel = 0
        scene.powerUpsGeneratedPerLevel = 0
        scene.paddleHitsPerLevel = 0
        scene.powerUpsCollectedPerPack = 0
        scene.powerUpsGeneratedPerPack = 0
        scene.levelTimerValue = 0
        scene.packTimerValue = 0
        // Reset trackers
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }

    /// One line saying what is about to be played.
    ///
    /// Round 312, from James's question about what a log should carry. A play-test report is
    /// always about *a run* - "Endless Mayhem with no power-ups and fog of war, from the 30th" -
    /// and until now a log said nothing about which run it was watching, so every report had to
    /// carry that context by hand and a log on its own could not be read at all.
    private func logTheRun() {
        let mode = GameMode.forRun(isDailyChallenge: scene.isDailyChallenge,
                                   startLevelNumber: scene.startLevelNumber).name
        // Round 313: this asked `scene.endlessMode`, and a Mayhem run logged itself as
        // "Classic Mode". Nothing has set that flag yet at pre-game - the pause menu sets it,
        // from `levelNumber == 0`, and the pause menu has not been built. `startLevelNumber`
        // is the same test made against a value the scene already holds, and the choice now
        // lives on GameMode where a test can reach it.

        var detail = ""
        if let challenge = DailyChallengeSession.shared.active {
            let twists = challenge.twists.map(\.rawValue).joined(separator: ", ")
            detail = " \(challenge.dateKey) \(challenge.mode.name)"
                + (twists.isEmpty ? " no twists" : " twists: \(twists)")
        } else if scene.startLevelNumber > 0 {
            let packs = LevelPackSetup()
            detail = " \(packs.levelPackNameArray[scene.packNumber])"
                + " / \(packs.levelNameArray[scene.levelNumber])"
        }

        Log.play.notice("""
            RUN \(mode, privacy: .public)\(detail, privacy: .public),             rack \(self.scene.numberOfLives, privacy: .public)
            """)
    }
}
