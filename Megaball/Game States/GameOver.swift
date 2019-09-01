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
        scene.gameStateLabel.text = "Game Over"
        
        self.scene.removeAction(forKey: "levelTimer")
        // Stop timer
        
        var timeBonusPoints: Int = 200
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.1)
        let ballSequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
        let paddleSequence = SKAction.sequence([wait, scaleDown, fadeOut])
        // Setup ball and paddle animations
        
        if scene.blocksLeft == 0 {
            scene.livesLabel.text = "Board passed"
            
            self.scene.ball.physicsBody!.velocity.dx = 0
            self.scene.ball.physicsBody!.velocity.dy = 0
            // Stop ball
            
            scene.ball.run(ballSequence, completion: {
                self.scene.ball.isHidden = true
            })
            scene.paddle.run(paddleSequence, completion: {
                self.scene.paddle.isHidden = true
            })
            // Animate paddle and ball out after level is won

            if scene.timerArray[0] == 1 {
                scene.timerArray[0] = scene.timerValue
            } else {
                scene.timerArray.append(scene.timerValue)
            }
            scene.timerArray.sort(by: <)
            if scene.timerArray.count > 10 {
                scene.timerArray.removeLast()
            }
            scene.dataStore.set(scene.timerArray, forKey: "TimerStore")
            if scene.timerArray.min()! < scene.bestTime || scene.bestTime == 0 {
                scene.bestTime = scene.timerValue
            }
            // Save completed level timer if it is within the top 10
            
            timeBonusPoints = timeBonusPoints - Int(scene.timerValue)
            scene.score = scene.score + scene.levelCompleteScore + timeBonusPoints
            // Update score with time and level complete bonus
            
        } else {
            scene.livesLabel.text = "You Lost"
            scene.ball.isHidden = true
            scene.life.isHidden = true
        }
        
        scene.scoreLabel.text = String(scene.score)
    
        if scene.scoreArray[0] == 1 {
            scene.scoreArray[0] = scene.score
        } else {
            scene.scoreArray.append(scene.score)
        }
        scene.scoreArray.sort(by: >)
        
        if scene.scoreArray.count > 10 {
            scene.scoreArray.removeLast()
        }
        scene.dataStore.set(scene.scoreArray, forKey: "ScoreStore")
        if scene.scoreArray.max()! > scene.highscore {
            scene.highscore = scene.score
        }
        // Save score if it is within the top 10
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PreGame.Type
    }
}
