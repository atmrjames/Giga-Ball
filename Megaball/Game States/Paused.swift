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
        
        if scene.musicSetting! {
            MusicHandler.sharedHelper.menuVolume()
        }
                
        scene.userSettings()
        // Set user settings
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.killBallNotificationKeyReceived), name: .killBallNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.unpauseNotificationKeyReceived), name: .unpause, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu
        
        if scene.saveBallPropertiesArray == [] {
            
            scene.pauseBallVelocityX = scene.ball.physicsBody!.velocity.dx
            scene.pauseBallVelocityY = scene.ball.physicsBody!.velocity.dy
            // Record the speed of the ball so it can be reapplied later
            
            if sqrt(scene.pauseBallVelocityX*scene.pauseBallVelocityX) + sqrt(scene.pauseBallVelocityY*scene.pauseBallVelocityY) == 0 && scene.ballIsOnPaddle == false {
                scene.ballLaunchAngleRad = scene.straightLaunchAngleRad + scene.minLaunchAngleRad
                scene.pauseBallVelocityX = cos(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
                scene.pauseBallVelocityY = sin(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
            }
            // If ball velocity is zero, but shouldn't be, set a default launch speed when resuming
        }
        
        scene.pauseButton.texture = scene.pauseHighlightedTexture
        scene.pauseButton.size.width = scene.pauseButtonSize*0.9
        scene.pauseButton.size.height = scene.pauseButtonSize*0.9
        scene.pauseAllNodes()
        scene.isPaused = true
        // Pause game, pause all nodes and scene
        
        if scene.hapticsSetting! {
            scene.interfaceHaptic.impactOccurred()
        }
        scene.saveCurrentGame()
        scene.showPauseMenu(sender: "Pause")
    }
    // This function runs when this state is entered.
    
    @objc func killBallNotificationKeyReceived(_ notification: Notification) {
        scene.killBall = true
    }
    
    @objc func unpauseNotificationKeyReceived(_ notification: Notification) {
                        
        scene.userSettings()
        // Set user settings
        
        if scene.multiplier >= 2 {
            scene.multiplierLabel.fontColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        } else {
            scene.multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        }
        
        scene.powerUpProbAllocation(levelNumber: scene.levelNumber)
        // Re-check power-up allocation
        
        scene.scoreLabel.isHidden = false
        scene.multiplierLabel.isHidden = false
        scene.pauseButton.isHidden = false
        scene.livesLabel.isHidden = false
        scene.life.isHidden = false
        if scene.endlessMode {
            scene.life.isHidden = true
            scene.livesLabel.isHidden = true
            scene.multiplierLabel.isHidden = true
        }
        
        scene.powerUpIconReset(sender: "Pause")
        // Reset power-up icons locked icon if power-up locked
        
        if scene.ballIsOnPaddle || scene.killBall || scene.ball.position.y + scene.ballSize/2 < scene.paddle.position.y - scene.paddle.size.height/2 {
//            scene.isPaused = false
            scene.gameState.enter(Playing.self)
            // Restart playing
        } else {
        // Only run countdown if the ball is not on the paddle or above paddle
            scene.resumeFromPauseCountdown()
        }
    }
    // Call the function to unpause the game if a notification from the pause menu popup is received
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}

extension Notification.Name {
    public static let unpause = Notification.Name(rawValue: "unpause")
    public static let killBallNotification = Notification.Name(rawValue: "killBallNotification")
}
// Notification setup for sending information from the pause menu popup to unpause the game
