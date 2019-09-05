//
//  InbewteenLevels.swift
//  Megaball
//
//  Created by James Harding on 05/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class InbetweenLevels: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
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
        
        scene.livesLabel.text = "Board passed"
        
        scene.ball.physicsBody!.velocity.dx = 0
        scene.ball.physicsBody!.velocity.dy = 0
        // Stop ball
        
        scene.ball.run(ballSequence, completion: {
            self.scene.ball.isHidden = true
        })
        scene.paddle.run(paddleSequence, completion: {
            self.scene.paddle.isHidden = true
        })
        // Animate paddle and ball out after level is won
        
        let scaleDown2 = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut2 = SKAction.fadeOut(withDuration: 0.2)
        let resetGroup = SKAction.group([scaleDown2, fadeOut2])
        scene.enumerateChildNodes(withName: BlockCategoryName) { (node, _) in
            node.run(resetGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.blocksLeft = 0
        // Remove any remaining blocks
        
        timeBonusPoints = timeBonusPoints - Int(scene.timerValue)
        scene.score = scene.score + scene.levelCompleteScore + timeBonusPoints
        // Update score with time and level complete bonus
        
        scene.timerValue = 0
        scene.timerLabel.text = String(format: "%.2f", scene.timerValue)
        // Reset timer
        
        // update level specific highscore and best times from previous level
        
        scene.nextLevelReady = true
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}
