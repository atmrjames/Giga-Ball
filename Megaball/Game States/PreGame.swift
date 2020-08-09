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
        
        if scene.musicSetting! {
            MusicHandler.sharedHelper.stopMusic()
            MusicHandler.sharedHelper.playMusic(sender: "PreGame")
        }
        
        print("llama llama entered pre game")
                        
        self.resetGame()
        
        let wait = SKAction.wait(forDuration: 1.0)
        // Add slight delay when moving in from main menu
        scene.self.run(wait, completion: {
            self.scene.gameState.enter(Playing.self)
        })
        
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func resetGame() {
        
        if scene.musicSetting! {
            MusicHandler.sharedHelper.menuVolume()
        }
        
        scene.scoreLabel.isHidden = true
        scene.multiplierLabel.isHidden = true
        scene.multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        scene.pauseButton.isHidden = true
        scene.livesLabel.isHidden = true
        scene.life.isHidden = true
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
        if scene.startLevelNumber == 0 {
            scene.numberOfLives = 0
        } else {
            scene.numberOfLives = 3
        }
        // 0 lives for endless mode, 3 for all other levels
        scene.multiplier = 1.0
        scene.gameoverStatus = false
        
        scene.deathsPerLevel = 0
        scene.deathsPerPack = 0
        scene.powerUpsCollectedPerLevel = 0
        scene.powerUpsGeneratedPerLevel = 0
        scene.paddleHitsPerLevel = 0
        scene.powerUpsCollectedPerPack = 0
        scene.powerUpsGeneratedPerPack = 0
        scene.packTimerValue = 0
        // Reset trackers
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

