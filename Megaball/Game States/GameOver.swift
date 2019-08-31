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
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.1)
        let ballSequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
        let paddleSequence = SKAction.sequence([wait, scaleDown, fadeOut])
        
        if scene.blocksLeft == 0 {
            scene.livesLabel.text = "Level passed"
            
            self.scene.ball.physicsBody!.velocity.dx = 0
            self.scene.ball.physicsBody!.velocity.dy = 0
            
            scene.ball.run(ballSequence, completion: {
                self.scene.ball.isHidden = true
            })
            scene.paddle.run(paddleSequence, completion: {
                self.scene.paddle.isHidden = true
            })
            // Animate paddle and ball out after level is won

        } else {
            scene.livesLabel.text = "You Lost"
            scene.ball.isHidden = true
            
        }
        scene.gameStateLabel.text = "Game Over"
        
        if scene.scoreArray[0] == 1 {
            scene.scoreArray[0] = scene.score
        } else {
            self.scene.scoreArray.append(scene.score)
        }
        
        scene.scoreArray.sort(by: >)
        
        if scene.scoreArray.count > 10 {
            scene.scoreArray.removeLast()
        }

        scene.dataStore.set(scene.scoreArray, forKey: "ScoreStore")
        
        if scene.scoreArray.max()! > scene.highscore {
            scene.highscore = scene.score
            print("new highscore")
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
