//
//  Game Over.swift
//  Megaball
//
//  Created by James Harding on 22/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameOver: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if scene.isGameWon() {
            scene.livesLabel.text = "You Won"
//            scene.ball.isHidden = true
//            scene.paddle.isHidden = true
        } else {
            scene.livesLabel.text = "You Lost"
        }
        scene.gameStateLabel.text = "Game Over"
        
        if scene.score > scene.highscore || scene.highscore == 0  {
            scene.highscore = scene.score
            scene.highScoreLabel.text = String(scene.highscore)
        }
    
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PreGame.Type
    }
}
