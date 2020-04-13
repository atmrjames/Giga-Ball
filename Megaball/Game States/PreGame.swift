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
        
        print("llama llama entered pre game")
                
        self.resetGame()
        
        if scene.musicSetting! {
            scene.musicHandler()
        }
        // First time music setup
        
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
        scene.scoreLabel.isHidden = true
        scene.multiplierLabel.isHidden = true
        scene.pauseButton.isHidden = true
        scene.livesLabel.isHidden = true
        scene.life.isHidden = true
        scene.ballIsOnPaddle = true
        // Hide labels
        
        scene.ballStartingPositionY = scene.paddlePositionY + scene.paddle.size.height/2 + scene.ballSize/2 + 1
        // Redeclare ballStartingPositionY
                
        if let startingLevelNumber = scene.gameViewControllerDelegate?.selectedLevel {
            scene.startLevelNumber = startingLevelNumber
            scene.levelNumber = scene.startLevelNumber
        }
        if let endingingLevelNumber = scene.gameViewControllerDelegate?.numberOfLevels {
            scene.numberOfLevels = endingingLevelNumber
            scene.endLevelNumber = scene.levelNumber + endingingLevelNumber - 1
        }
        if let levelSender = scene.gameViewControllerDelegate?.levelSender {
            scene.levelSender = levelSender
        }
        if let levelPack = scene.gameViewControllerDelegate?.levelPack {
            scene.packNumber = levelPack
        }
        // Redeclare the game scene properties as passed in
        
        switch scene.packNumber {
        case 1:
            scene.background.texture = scene.endlessBackgroundTexture
        case 2:
            scene.background.texture = scene.starterBackgroundTexture
        case 3:
            scene.background.texture = scene.spaceBackgroundTexture
        
        default:
            scene.background.texture = scene.starterBackgroundTexture
        }
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
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

