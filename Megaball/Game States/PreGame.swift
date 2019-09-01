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
        self.scene.ball.isHidden = true
        // Hide ball

        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let resetGroup = SKAction.group([scaleDown, fadeOut])
        scene.paddle.run(resetGroup, completion: {
            self.scene.paddle.position.x = 0
            self.scene.paddle.isHidden = true
            
        })
        // Reset paddle position
        
        self.scene.enumerateChildNodes(withName: BlockCategoryName) { (node, _) in
            node.run(resetGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove all remaining blocks
        
        scene.timerValue = 0
        scene.timerLabel.text = String(format: "%.2f", scene.timerValue)
        // Reset timer
        
        scene.numberOfLives = 3
        scene.score = 0
        scene.livesLabel.text = "x\(scene.numberOfLives)"
        scene.life.isHidden = false
        scene.scoreLabel.text = String(scene.score)
        scene.blocksLeft = 0
        scene.blocksLeftLabel.text = String(scene.blocksLeft)
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
        // Reset labels
        
        scene.ball.position.x = 0
        scene.ball.position.y = scene.ballStartingPositionY
        // Reset ball
        
        /* TODO
         > Which level to load up next
         */
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

