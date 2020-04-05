//
//  Ad.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class Ad: GKState {
    
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    var notificationCounter = 0
    
    override func didEnter(from previousState: GKState?) {
        
        print("llama llama entered ad")
        
        notificationCounter = 0
        
        if let musicPlaying = scene.backgroundMusic {
            musicPlaying.run(SKAction.stop())
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToCloseAd(_:)), name: .closeAd, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed continue on the end level popup

    }
    // This function runs when this state is entered.
    
    @objc func notificationToCloseAd(_ notification: Notification) {
        notificationCounter+=1
        
        if notificationCounter <= 1 {
            if scene.endlessMode || scene.gameoverStatus == true {
                scene.gameState.enter(InbetweenLevels.self)
            } else if scene.levelNumber < scene.endLevelNumber {
                scene.gameState.enter(Playing.self)
            } else {
                scene.gameState.enter(InbetweenLevels.self)
            }
        }
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is Playing.Type:
            return true
        case is InbetweenLevels.Type:
            return true
        case is PreGame.Type:
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    public static let closeAd = Notification.Name(rawValue: "closeAd")
}
// Notification setup for sending information between view controllers
