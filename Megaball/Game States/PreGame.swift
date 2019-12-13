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
        resetGame()
        scene.gameState.enter(Playing.self)
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func resetGame() {
        scene.scoreLabel.isHidden = true
        scene.highScoreLabel.isHidden = true
        scene.multiplierLabel.isHidden = true
        scene.pauseButton.isHidden = true
        scene.livesLabel.isHidden = true
        scene.life.isHidden = true
        // Hide labels
        
        scene.levelNumber = 0
        scene.totalScore = 0
        scene.numberOfLives = 3
        scene.gameoverStatus = false
        
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

