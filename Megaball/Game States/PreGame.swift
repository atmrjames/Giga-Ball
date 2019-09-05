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
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func resetGame() {
        scene.numberOfLives = 3
        scene.score = 0
        scene.livesLabel.text = "x\(scene.numberOfLives)"
        scene.life.isHidden = false
        
        if scene.scoreArray.max() != 1 {
            scene.highscore = scene.scoreArray.max()!
            scene.highScoreLabel.text = String(scene.highscore)
        } else {
            scene.highScoreLabel.text = ""
        }
        // Add highscore to highscore label
        
        if scene.timerArray.min() != 1 {
            scene.bestTime = scene.timerArray.min()!
            scene.bestTimeLabel.text = String(format: "%.2f", scene.bestTime)
        } else {
            scene.bestTimeLabel.text = ""
        }
        // Add best time to best time label
        
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

