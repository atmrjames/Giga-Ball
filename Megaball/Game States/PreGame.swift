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
        scene.gameStateLabel.text = "PreGame"
        resetGame()
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    func resetGame() {
        scene.numberOfLives = 3
        scene.score = 0
        scene.livesLabel.text = String(scene.numberOfLives)
        scene.scoreLabel.text = String(scene.score)
        scene.highScoreLabel.text = String(scene.highscore)
        scene.paddle.position.x = 0
        scene.ball.position.x = 0
        scene.paddle.isHidden = true
        scene.ball.isHidden = true
        scene.enumerateChildNodes(withName: BlockCategoryName) { (node, _) in
            node.removeFromParent()
        }
        scene.blocksLeft = 0
        scene.blocksLeftLabel.text = String(scene.blocksLeft)
        // Remove all remaining blocks
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

