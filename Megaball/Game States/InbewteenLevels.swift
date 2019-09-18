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
print("State: Inbetween Levels")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToContinueReceived(_:)), name: .continueToNextLevel, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed continue on the end level popup
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToRestartReceived(_:)), name: .restart, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed restart on the end level, gameover popup
        
        inbetweenLevels()
    }
    // This function runs when this state is entered.
    
    func inbetweenLevels() {
        self.scene.removeAction(forKey: "levelTimer")
        self.scene.removeAllActions()
        // Stop timer and all actions
        
        scene.powerUpsReset()
        // Reset any power ups
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.1)
        let ballSequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
        let paddleSequence = SKAction.sequence([wait, scaleDown, fadeOut])
        let scaleReset = SKAction.scale(to: 1, duration: 0)
        let fadeReset = SKAction.fadeIn(withDuration: 0)
        let resetGroup = SKAction.group([scaleReset, fadeReset])
        // Setup ball and paddle animations
        
        scene.ball.physicsBody!.velocity.dx = 0
        scene.ball.physicsBody!.velocity.dy = 0
        // Stop ball
        
        scene.ball.run(ballSequence, completion: {
            self.scene.ball.isHidden = true
            self.scene.ball.run(resetGroup)
        })
        scene.paddle.run(paddleSequence, completion: {
            self.scene.paddle.isHidden = true
            self.scene.paddle.run(resetGroup)
        })
        // Animate paddle and ball out after level is won
        
        let scaleDown2 = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut2 = SKAction.fadeOut(withDuration: 0.2)
        let removeBlockGroup = SKAction.group([scaleDown2, fadeOut2])
        scene.enumerateChildNodes(withName: BlockCategoryName) { (node, _) in
            node.run(removeBlockGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.blocksLeft = 0
        // Remove any remaining blocks
        
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.run(removeBlockGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining powerups
        
        scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.run(removeBlockGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining lasers
        
        scene.cumulativeTimerValue = scene.cumulativeTimerValue + scene.levelTime
        scene.timeBonusPoints = scene.timeBonusPoints - Int(scene.levelTime)
        scene.levelScore = scene.levelScore + scene.levelCompleteScore + scene.timeBonusPoints
        scene.cumulativeScore = scene.cumulativeScore + scene.levelScore
        // Update score with time and level complete bonus
        
// TODO: update highscore and best time tables
// TODO: show stats table


        // Reset current level timer and score
        
        // Load up stats for previous board and so far
    
// Show game stats popup
        let waitScene = SKAction.wait(forDuration: 1)
        self.scene.run(waitScene, completion: {
            self.scene.showEndLevelStats()
// Pause game during wait and popup show
        })
        
    }
    
    @objc func notificationToContinueReceived(_ notification: Notification) {
        moveToNextLevel()
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    @objc func notificationToRestartReceived(_ notification: Notification) {
        scene.gameState.enter(PreGame.self)
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    func moveToNextLevel() {
        scene.gameState.enter(Playing.self)
    }
    
    override func willExit(to nextState: GKState) {
        scene.levelTime = 0
        scene.levelScore = 0
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is PreGame.Type:
            return true
        case is Playing.Type:
            return true
        case is GameOver.Type:
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    public static let continueToNextLevel = Notification.Name(rawValue: "continueToNextLevel")
}
// Notification setup for sending information from the end level popup to load the next level

extension Notification.Name {
    public static let restart = Notification.Name(rawValue: "restart")
}
// Notification setup for sending information from the end level game over popup to restart
