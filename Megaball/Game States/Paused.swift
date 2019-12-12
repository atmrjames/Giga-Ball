//
//  Paused.swift
//  Megaball
//
//  Created by James Harding on 31/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class Paused: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {

        self.scene.pauseBallVelocityX = self.scene.ball.physicsBody!.velocity.dx
        self.scene.pauseBallVelocityY = self.scene.ball.physicsBody!.velocity.dy
        // Record the speed of the ball so it can be reapplied later
        
        scene.pauseButton.texture = scene.playTexture
        pauseAllNodes()
        scene.isPaused = true
        // Pause game, pause all nodes and scene
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback

        scene.showPauseMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.unpauseNotificationKeyReceived), name: .unpause, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu
        
// TODO:
//        Programatically position and size pause menu, labels, buttons and icon
//        Add count down when returning to game
//        Add blur behind popup
//        Disable buttons behind popup
//        Animate popup in and out like inbetweenlevels popup

    }
    // This function runs when this state is entered.
    
    func pauseAllNodes() {
        scene.enumerateChildNodes(withName: PaddleCategoryName) { (node, _) in
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: BallCategoryName) { (node, _) in
            self.scene.ball.physicsBody!.velocity.dx = 0
            self.scene.ball.physicsBody!.velocity.dy = 0
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.isPaused = true
        }
    }
    // Pause all nodes
    
    @objc func unpauseNotificationKeyReceived(_ notification: Notification) {
        
        scene.isPaused = false
        pauseAllNodes()
        // Unpause scene to allow for animation ensuring all other nodes remain paused for now
        
        let startScale = SKAction.scale(to: 2, duration: 0)
        let startFade = SKAction.fadeOut(withDuration: 0)
        let scaleIn = SKAction.scale(to: 1, duration: 0.25)
        let scaleOut = SKAction.scale(to: 0.5, duration: 0.25)
        let fadeIn = SKAction.fadeIn(withDuration: 0.25)
        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let wait = SKAction.wait(forDuration: 0.75)
        // Setup animation properties

        let startGroup = SKAction.group([startScale, startFade])
        // Prep label ahead of animation
        let animationIn1 = SKAction.group([scaleIn, fadeIn, wait])
        // Animate in with pause
        let animationIn2 = SKAction.group([scaleIn, fadeIn])
        // Animate in
        let animationOut = SKAction.group([scaleOut, fadeOut])
        // Animate out
        
        var unpauseCountdownText = "R E A D Y"
        scene.unpauseCountdownLabel.text = String(unpauseCountdownText)
        scene.unpauseCountdownLabel.run(startGroup, completion: {
            self.scene.unpauseCountdownLabel.isHidden = false
            self.scene.unpauseCountdownLabel.run(animationIn1, completion: {
                self.scene.unpauseCountdownLabel.run(animationOut, completion: {
                    unpauseCountdownText = "G O"
                    self.scene.unpauseCountdownLabel.text = String(unpauseCountdownText)
                    self.scene.unpauseCountdownLabel.run(startGroup, completion: {
                        self.scene.unpauseCountdownLabel.run(animationIn2, completion: {
                            self.scene.gameState.enter(Playing.self)
                            // Restart playing
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            // Haptic feedback
                            self.scene.unpauseCountdownLabel.run(animationOut, completion: {
                                self.scene.unpauseCountdownLabel.isHidden = true
                            })
                        })
                    })
                })
            })
        })
        // Animate countdown
    }
    // Call the function to unpause the game if a notification from the pause menu popup is received
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

extension Notification.Name {
    public static let unpause = Notification.Name(rawValue: "unpause")
}
// Notification setup for sending information from the pause menu popup to unpause the game
