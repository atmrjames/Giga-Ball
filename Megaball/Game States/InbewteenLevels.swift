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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToContinueReceived(_:)), name: .continueToNextLevel, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed continue on the end level popup
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToRestartReceived(_:)), name: .restart, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed restart on the end level, gameover popup
        
        inbetweenLevels()
    }
    // This function runs when this state is entered.
    
    func inbetweenLevels() {
        self.scene.removeAllActions()
        // Stop all actions
        scene.powerUpsReset()
        // Reset any power ups
        
        if scene.adsSetting! {
            scene.createInterstitial()
        }
        // Only load next ad if user has ads enabled
        
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
        
        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
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
        let removeItemGroup = SKAction.group([scaleDown2, fadeOut2])
        scene.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.bricksLeft = 0
        // Remove any remaining bricks
        
        scene.enumerateChildNodes(withName: BrickRemovalCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining bricks being removed
        
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.powerUpsOnScreen = 0
        // Remove any remaining power-ups
        
        scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining lasers
        
        scene.totalScore = scene.totalScore + scene.levelScore
        // Update level and total scores
        
        scene.totalStatsArray[0].cumulativeScore = scene.cumulativeScore + scene.levelScore
        scene.levelsPlayed+=1
        scene.totalStatsArray[0].levelsPlayed = scene.levelsPlayed
        if scene.gameoverStatus == false {
            scene.levelsCompleted+=1
            scene.totalStatsArray[0].levelsCompleted = scene.levelsCompleted
        }
        scene.totalStatsArray[0].ballHits = scene.ballHits
        scene.totalStatsArray[0].ballsLost = scene.ballsLost
        scene.totalStatsArray[0].powerupsCollected = scene.powerupsCollected
        scene.totalStatsArray[0].powerupsGenerated = scene.powerupsGenerated
        scene.totalStatsArray[0].playTime = scene.playTime
        scene.totalStatsArray[0].bricksHit = scene.bricksHit
        scene.totalStatsArray[0].bricksDestroyed = scene.bricksDestroyed
        scene.totalStatsArray[0].lasersFired = scene.lasersFired
        scene.totalStatsArray[0].lasersHit = scene.lasersHit
        // Update total stats
        
        do {
            let data = try scene.encoder.encode(self.scene.totalStatsArray)
            try data.write(to: scene.totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        // Save total stats only at the end of the game
        
        scene.levelStatsArray[scene.levelNumber].scores.append(scene.levelScore)
        scene.levelStatsArray[scene.levelNumber].scoreDates.append(Date())
        if scene.gameoverStatus == false {
            scene.levelStatsArray[scene.levelNumber].numberOfCompletes+=1
        }
        // Update level stats
        
        do {
            let data = try scene.encoder.encode(self.scene.levelStatsArray)
            try data.write(to: scene.levelStatsStore!)
        } catch {
            print("Error encoding level stats array, \(error)")
        }
        // Save level stats after each level
        
        if scene.levelNumber == scene.endLevelNumber || scene.gameoverStatus {
            scene.packStatsArray[scene.packNumber].scores.append(scene.totalScore)
            scene.packStatsArray[scene.packNumber].scoreDates.append(Date())
            if scene.gameoverStatus == false {
                scene.packStatsArray[scene.packNumber].numberOfCompletes+=1
            }
            do {
                let data = try scene.encoder.encode(self.scene.packStatsArray)
                try data.write(to: scene.packStatsStore!)
            } catch {
                print("Error encoding pack stats array, \(error)")
            }
            // Save pack stats only at the end of the game
            
            scene.gameoverStatus = true
        }
        // Save total stats only at the end of the game

        if scene.gameoverStatus {
            
            let waitScene = SKAction.wait(forDuration: 1)
            self.scene.run(waitScene, completion: {
                self.scene.showEndLevelStats()
            })
            // Show game over pop-up
            
        } else {
            let waitScene = SKAction.wait(forDuration: 1)
            self.scene.run(waitScene, completion: {
                if self.scene.adsSetting! {
                    self.scene.gameState.enter(Ad.self)
                    self.scene.loadInterstitial()
                } else {
                    self.scene.gameState.enter(Playing.self)
                }
            })
            // Move to the next level after a delay
        }
    }
    
    @objc func notificationToContinueReceived(_ notification: Notification) {
        scene.gameState.enter(Playing.self)
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    @objc func notificationToRestartReceived(_ notification: Notification) {
        scene.gameState.enter(PreGame.self)
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    override func willExit(to nextState: GKState) {
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is PreGame.Type:
            return true
        case is Playing.Type:
            return true
        case is Ad.Type:
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
