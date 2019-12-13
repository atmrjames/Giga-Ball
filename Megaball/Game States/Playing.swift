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
        
        if scene.gameoverStatus == true || scene.levelNumber == scene.endLevelNumber {
            scene.gameState.enter(GameOver.self)
        } else if previousState is PreGame || previousState is InbetweenLevels {
            reloadUI()
            loadNextLevel()
        } else if previousState is Paused {
        // Unpause game
            
            scene.countdownStarted = false
            scene.pauseButton.texture = scene.pauseTexture
            scene.directionMarker.isHidden = true
            
            scene.enumerateChildNodes(withName: PaddleCategoryName) { (node, _) in
                node.isPaused = false
            }
            scene.enumerateChildNodes(withName: BallCategoryName) { (node, _) in
                self.scene.ball.physicsBody!.velocity.dx = self.scene.pauseBallVelocityX
                self.scene.ball.physicsBody!.velocity.dy = self.scene.pauseBallVelocityY
                node.isPaused = false
            }
            scene.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
                node.isPaused = false
            }
            scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
                node.isPaused = false
            }
            scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
                node.isPaused = false
            }
            // Restart game, unpause all nodes
        }
    }
    // This function runs when this state is entered.

    
    func reloadUI() {
        scene.scoreLabel.isHidden = false
        scene.highScoreLabel.isHidden = false
        scene.multiplierLabel.isHidden = false
        scene.pauseButton.isHidden = false
        scene.livesLabel.isHidden = false
        scene.life.isHidden = false
        // Show game labels
        
        scene.livesLabel.text = "x\(scene.numberOfLives)"
        // Reset labels
    }
    
    func loadNextLevel() {
        
        scene.levelNumber += 1
        // Increment level number
        
        scene.brickRemovalCounter = 0
        
        scene.newLevelHighScore = false
        scene.newTotalHighScore = false
        // Reset level and total highscore booleans
        
        if scene.levelScoreArray.count < scene.levelNumber {
            scene.levelScoreArray.append(1)
        }
        // Check the level score item exists in the array for the new level, if not create a placeholder
        
        if scene.totalScoreArray.count < scene.levelNumber {
            scene.totalScoreArray.append(1)
        }
        // Check the total score item exists in the array for the new level, if not create a placeholder (value = 1)
        
        if scene.levelScoreArray[scene.levelNumber-1] != 1 {
            scene.levelHighscore = scene.levelScoreArray[scene.levelNumber-1]
            scene.highScoreLabel.text = String(scene.levelHighscore)
        } else {
            scene.highScoreLabel.text = ""
        }
        // Add level highscore to level highscore label, if no highscore exists (value = 1) show nothing
        
        scene.levelScore = 0
        scene.multiplier = 1
        scene.scoreLabel.text = String(scene.levelScore)
        scene.scoreFactorString = String(format:"%.1f", scene.multiplier)
        scene.multiplierLabel.text = "x\(scene.scoreFactorString)"
        // Update score
        // Reset level scores and label
        
        scene.livesLabel.text = "x\(self.scene.numberOfLives)"
        // Update number of lives label
        
        scene.contactCount = 0
        
        scene.ball.removeAllActions()
        scene.paddle.removeAllActions()

        scene.ballIsOnPaddle = true
        scene.paddle.position.x = 0
        scene.paddle.position.y = (-self.scene.frame.height/2 + scene.paddleGap)
        scene.paddle.size.width = scene.paddleWidth
        scene.ball.position.x = 0
        scene.ball.position.y = scene.ballStartingPositionY
        // Reset ball and paddle

        let startingScale = SKAction.scale(to: 0.8, duration: 0)
        let startingFade = SKAction.fadeOut(withDuration: 0)
        let scaleUp = SKAction.scale(to: 1, duration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: 0.25)
        let startingGroup = SKAction.group([startingScale, startingFade])
        let animationGroup = SKAction.group([scaleUp, fadeIn])
        let animationSequence = SKAction.group([wait, animationGroup])
        
        scene.ball.run(startingGroup)
        scene.ball.isHidden = false
        scene.ball.run(animationSequence, completion: {
            self.scene.ballStartingPositionY = self.scene.ball.position.y
            // Resets the ball's starting position incase it is moved during the animation in
        })
        scene.paddle.run(startingGroup)
        scene.paddle.isHidden = false
        scene.paddle.run(animationSequence)
        // Animate paddle and ball in
        
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
        // Load level in
        
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

