//
//  Playing.swift
//  Megaball
//
//  Created by James Harding on 22/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

class Playing: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
print("State: Playing")
        if scene.gameoverStatus == true || scene.levelNumber == scene.endLevelNumber {
            scene.gameState.enter(GameOver.self)
        } else if previousState is PreGame || previousState is InbetweenLevels {
            reloadUI()
            loadNextLevel()
        }
    }
    // This function runs when this state is entered.
    
    func reloadUI() {
//        scene.levelNumberLabel.isHidden = false
        scene.scoreLabel.isHidden = false
        scene.highScoreLabel.isHidden = false
        scene.pausedButton.isHidden = false
        scene.timerLabel.isHidden = false
        scene.bestTimeLabel.isHidden = false
        scene.livesLabel.isHidden = false
        scene.life.isHidden = false
        // Show game labels
        
        scene.livesLabel.text = "x\(scene.numberOfLives)"
        scene.scoreLabel.text = String(scene.cumulativeScore)
        scene.highScoreLabel.text = String(scene.highscore)
        scene.timerLabel.text = String(format: "%.2f", scene.cumulativeTimerValue)
        scene.bestTimeLabel.text = String(format: "%.2f", scene.bestCumulativeTime)
        // Reset labels
    }
    
    func loadNextLevel() {
        scene.levelNumber += 1
        // Increment level number
        
        scene.livesLabel.text = "x\(self.scene.numberOfLives)"
        
        scene.contactCount = 0
        
        scene.ball.removeAllActions()
        scene.paddle.removeAllActions()
        scene.ball.isHidden = false
        scene.paddle.isHidden = false
        scene.ballIsOnPaddle = true
        scene.paddle.position.x = 0
        scene.paddle.position.y = (-self.scene.frame.height/2 + scene.paddleGap)
        scene.paddle.size.width = scene.paddleWidth
        scene.ball.position.x = 0
        scene.ball.position.y = scene.ballStartingPositionY
        // Reset ball and paddle
        
        scene.powerUpsReset()
        
        let startingScale = SKAction.scale(to: 0, duration: 0)
        let startingFade = SKAction.fadeIn(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        let ballSequence = SKAction.sequence([startingScale, startingFade, scaleUp])
        let paddleSequence = SKAction.sequence([startingScale, startingFade, scaleUp])
        scene.ball.run(ballSequence, completion: {
            self.scene.ballStartingPositionY = self.scene.ball.position.y
            // Resets the ball's starting position to its current position to prevent it jumping up and down when sliding the paddle
        })
        scene.paddle.run(paddleSequence)
        // Animate paddle and ball in
        
        // load new best time for board
        // load new highscore for board
        // reset number of lives
        
        // load new board
        switch scene.levelNumber {
        case 1:
            scene.loadLevel1()
        case 2:
            scene.loadLevel2()
        case 3:
            scene.loadLevel3()
        default:
            break
        }
    }
    
    override func willExit(to nextState: GKState) {

    }
    // This function runs when this state is exited.
        
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is GameOver.Type:
            return true
        case is InbetweenLevels.Type:
            return true
        case is Paused.Type:
            return true
        default:
            return false
        }
    }
}

