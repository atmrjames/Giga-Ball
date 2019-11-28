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
        
        print("State: Gameover")
        
//TODO: show game over label
//        scene.levelNumberLabel.text = "Game Over"
        
// Move to inbetween levels
        if scene.timerArray[0] == 1 {
            scene.timerArray[0] = scene.cumulativeTimerValue
        } else {
            scene.timerArray.append(scene.cumulativeTimerValue)
        }
        scene.timerArray.sort(by: <)
        if scene.timerArray.count > 10 {
            scene.timerArray.removeLast()
        }
        scene.dataStore.set(scene.timerArray, forKey: "TimerStore")
        if scene.timerArray.min()! < scene.bestCumulativeTime || scene.bestCumulativeTime == 0 {
            scene.bestCumulativeTime = scene.cumulativeTimerValue
        }
        // Save cumulative time if it is within the top 10
        
        if scene.scoreArray[0] == 1 {
            scene.scoreArray[0] = scene.cumulativeScore
        } else {
            scene.scoreArray.append(scene.cumulativeScore)
        }
        scene.scoreArray.sort(by: >)
        
        if scene.scoreArray.count > 10 {
            scene.scoreArray.removeLast()
        }
        scene.dataStore.set(scene.scoreArray, forKey: "ScoreStore")
        if scene.scoreArray.max()! > scene.highscore {
            scene.highscore = scene.cumulativeScore
        }
        // Save cumulative score if it is within the top 10
        
        scene.cumulativeScore = 0
        scene.cumulativeTimerValue = 0
        
        scene.moveToMainMenu()
        
    }
    // This function runs when this state is entered.
    
    override func willExit(to nextState: GKState) {
        
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is PreGame.Type
    }
}
