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
    
    override func didEnter(from previousState: GKState?) {
        if let musicPlaying = scene.backgroundMusic {
            musicPlaying.run(SKAction.stop())
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToCloseAd(_:)), name: .closeAd, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed continue on the end level popup

    }
    // This function runs when this state is entered.
    
    @objc func notificationToCloseAd(_ notification: Notification) {
        if scene.endlessMode || scene.gameoverStatus == true || scene.levelNumber == scene.endLevelNumber {
            scene.gameState.enter(InbetweenLevels.self)
            // Show game over pop-up
        } else {
            scene.gameState.enter(Playing.self)
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
        default:
            return false
        }
    }
}

extension Notification.Name {
    public static let closeAd = Notification.Name(rawValue: "closeAd")
}
// Notification setup for sending information between view controllers
