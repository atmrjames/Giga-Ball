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
        
        if scene.ballIsOnPaddle == false && scene.pauseBallVelocityX == 0 && (scene.ball.position.x >= (scene.frame.size.width/2 - scene.ball.size.width/2) || scene.ball.position.x <= -(scene.frame.size.width/2 - scene.ball.size.width/2)) {
        // The the ball is not on the paddle, on the edge or top of the frame and its x velocity is 0, then give it some x velocity
            
            if scene.ball.position.x > 0 {
                scene.ball.physicsBody!.velocity.dx = -sqrt(scene.ball.physicsBody!.velocity.dy*scene.ball.physicsBody!.velocity.dy)
            }
            else {
                scene.ball.physicsBody!.velocity.dx = sqrt(scene.ball.physicsBody!.velocity.dy*scene.ball.physicsBody!.velocity.dy)
            }
            // Give the ball a boost to the right or left depending on where it is
        }
        
        self.scene.pauseBallVelocityX = self.scene.ball.physicsBody!.velocity.dx
        self.scene.pauseBallVelocityY = self.scene.ball.physicsBody!.velocity.dy
        // Record the speed of the ball so it can be reapplied later
        
        scene.pauseButton.texture = scene.playTexture
        pauseAllNodes()
        scene.isPaused = true
        // Pause game, pause all nodes and scene
        
        scene.mediumHaptic.impactOccurred()
        scene.showPauseMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.killBallNotificationKeyReceived), name: .killBallNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.unpauseNotificationKeyReceived), name: .unpause, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu

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
        scene.enumerateChildNodes(withName: BrickRemovalCategoryName) { (node, _) in
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.isPaused = true
        }
        scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.isPaused = true
        }
        // Pause all nodes individually
        
        scene.ball.physicsBody!.affectedByGravity = false
        // Ensure the ball won't fall under gravity if the gameScene is unpaused
        
        if scene.ballIsOnPaddle == false && scene.ball.position.y >= scene.paddle.position.y - scene.ballLostAnimationHeight {
            
            let angleRad = atan2(Double(self.scene.pauseBallVelocityY), Double(self.scene.pauseBallVelocityX))
            let angleDeg = Double(angleRad)/Double.pi*180
            let rotationAngle = CGFloat(angleRad)
            scene.directionMarker.zRotation = rotationAngle
            scene.directionMarker.position.x = scene.ball.position.x
            scene.directionMarker.position.y = scene.ball.position.y
            // Set direction marker rotation to match the ball's direction of travel and position
            
            if scene.ball.texture == scene.superballTexture {
                scene.directionMarker.texture = scene.directionMarkerOuterSuperTexture
            } else if scene.ball.texture == scene.undestructiballTexture {
                scene.directionMarker.texture = scene.directionMarkerOuterUndestructiTexture
            } else {
                scene.directionMarker.texture = scene.directionMarkerOuterTexture
            }
            // Set direction marker outer texture if the ball is near either edge of frame
            
            if scene.directionMarker.position.x > 0 + scene.frame.size.width/2 - scene.directionMarker.size.width/2 {
                if angleDeg > -90 && angleDeg < 90 {
                    if scene.ball.texture == scene.superballTexture {
                        scene.directionMarker.texture = scene.directionMarkerInnerSuperTexture
                    } else if scene.ball.texture == scene.undestructiballTexture {
                        scene.directionMarker.texture = scene.directionMarkerInnerUndestructiTexture
                    } else {
                        scene.directionMarker.texture = scene.directionMarkerInnerTexture
                    }
                    // Set texture of direction marker based on ball texture
                }
            }
            else if scene.directionMarker.position.x < 0 - scene.frame.size.width/2 + scene.directionMarker.size.width/2 {
                if angleDeg < -90 || angleDeg > 90 {
                    if scene.ball.texture == scene.superballTexture {
                        scene.directionMarker.texture = scene.directionMarkerInnerSuperTexture
                    } else if scene.ball.texture == scene.undestructiballTexture {
                        scene.directionMarker.texture = scene.directionMarkerInnerUndestructiTexture
                    } else {
                        scene.directionMarker.texture = scene.directionMarkerInnerTexture
                    }
                    // Set texture of direction marker based on ball texture
                }
            }
            // Set direction marker inner texture if the ball is near either edge of frame
    
            scene.directionMarker.isHidden = false
            // Show ball direction marker
        }
    }
    // Pause all nodes
    
    @objc func killBallNotificationKeyReceived(_ notification: Notification) {
        scene.killBall = true
    }
    
    @objc func unpauseNotificationKeyReceived(_ notification: Notification) {
        
        if scene.ballIsOnPaddle || scene.killBall {
            scene.isPaused = false
            scene.gameState.enter(Playing.self)
            // Restart playing
        } else {
        // Only run countdown if the ball is not on the paddle
        
            scene.countdownStarted = true
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
            scene.unpauseCountdownLabel.removeAllActions()
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
                                self.scene.lightHaptic.impactOccurred()
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
    public static let killBallNotification = Notification.Name(rawValue: "killBallNotification")
}
// Notification setup for sending information from the pause menu popup to unpause the game
