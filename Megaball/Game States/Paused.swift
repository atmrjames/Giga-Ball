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
print("State: Paused")

        scene.showPauseMenu()
        scene.pauseGame()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToUnpause(_:)), name: .unpause, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed unpause on the pause menu
        
// TODO:
//        Programatically position and size pause menu, labels, buttons and icon
//        Add count down when returning to game
//        Add blur behind popup
//        Disable buttons behind popup
//        Animate popup in and out like inbetweenlevels popup

    }
    // This function runs when this state is entered.
    
    @objc func notificationToUnpause(_ notification: Notification) {
        scene.unpauseGame()
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
