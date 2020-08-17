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
        
        print("llama llama entered playing")
        scene.gameInProgress = true
        scene.defaults.set(scene.gameInProgress!, forKey: "gameInProgress")
        
        scene.userSettings()
        // Set user settings
        
        if scene.musicSetting! {
            MusicHandler.sharedHelper.gameVolume()
        }
        
        if previousState is InbetweenLevels || previousState is Ad {
            scene.clearSavedGame()
            scene.levelNumber+=1
            // Increment level number
        }
        
        if previousState is PreGame {
            scene.newItemsBool = false
            
            if scene.packNumber > 1 {
                if scene.numberOfLevels == 1  {

                    print("llama llama 1")
                    scene.previousHighscore = scene.packLevelHighScoresArray![scene.packNumber-2][scene.levelNumber-LevelPackSetup().startLevelNumber[scene.packNumber]]
                } else {
                    print("llama llama 0")
                    scene.previousHighscore = scene.totalStatsArray[0].packHighScores[scene.packNumber-2]
                }
                print("llama llama previous highscore: ", scene.previousHighscore, scene.levelNumber, scene.packNumber, scene.numberOfLevels, scene.startLevelNumber, LevelPackSetup().startLevelNumber[scene.packNumber])
            }
        }
        
        if previousState is PreGame || previousState is InbetweenLevels || previousState is Ad {
            reloadUI()
            loadNextLevel()
        }
        
        if previousState is Paused {
        // Unpause game
            if scene.ballIsOnPaddle == false {
                scene.startLevelTimer()
            }
            scene.playFromPause()            
        }
    }
    // This function runs when this state is entered.

    func reloadUI() {
        let wait = SKAction.wait(forDuration: 0.35)
        self.scene.run(wait, completion: {
            self.scene.scoreLabel.isHidden = false
            self.scene.multiplierLabel.isHidden = false
            self.scene.pauseButton.isHidden = false
            self.scene.livesLabel.isHidden = false
            self.scene.life.isHidden = false
            if self.scene.endlessMode {
                self.scene.life.isHidden = true
                self.scene.livesLabel.isHidden = true
                self.scene.multiplierLabel.isHidden = true
            }
        })
        // Show game labels
        
        scene.multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        scene.livesLabel.text = "x\(scene.numberOfLives)"
        // Reset labels
        
        scene.powerUpIconReset(sender: "")
        // Reset power-up icons locked icon if power-up locked
    }
    
    func loadNextLevel() {
        
        if scene.levelNumber > scene.endLevelNumber {
            scene.levelNumber = scene.endLevelNumber
        }
        scene.brickRemovalCounter = 0
        scene.powerUpsOnScreen = 0
        scene.levelScore = 0
        // Reset counters & scores
        
        scene.ball.position.y = scene.ballStartingPositionY

        if scene.resumeGameToLoad! {
            print("llama resume game log: ", scene.saveGameSaveArray!, scene.saveMultiplier!, scene.saveBrickTextureArray!, scene.saveBrickColourArray!, scene.saveBrickXPositionArray!, scene.saveBrickYPositionArray!)
            scene.levelScore = scene.saveGameSaveArray![3]
            scene.totalScore = scene.saveGameSaveArray![4]
            scene.numberOfLives = scene.saveGameSaveArray![5]
            scene.multiplier = scene.saveMultiplier!
        }
        // If resuming a game, reset counters and scores to saved values
        
        scene.scoreLabel.text = String(scene.totalScore)
        scene.scoreFactorString = String(format:"%.1f", scene.multiplier)
        scene.multiplierLabel.text = "x\(scene.scoreFactorString)"
        scene.livesLabel.text = "x\(self.scene.numberOfLives)"
        // Update number of lives label

        scene.ball.removeAllActions()
        scene.paddle.removeAllActions()
        scene.paddleRetroTexture.removeAllActions()
        scene.ballIsOnPaddle = true
        scene.paddle.position.x = 0
        scene.paddle.position.y = scene.paddlePositionY
        scene.paddleLaser.position.x = scene.paddle.position.x
        scene.paddleLaser.position.y = scene.paddle.position.y - scene.paddleHeight/2
        scene.paddleSticky.position.x = scene.paddle.position.x
        scene.paddleSticky.position.y = scene.paddle.position.y - scene.paddleHeight/2
        scene.paddleRetroTexture.position.x = scene.paddle.position.x
        scene.paddleRetroTexture.position.y = scene.paddle.position.y
        scene.paddleRetroLaserTexture.position.x = scene.paddle.position.x
        scene.paddleRetroLaserTexture.position.y = scene.paddle.position.y
        scene.paddleRetroStickyTexture.position.x = scene.paddle.position.x
        scene.paddleRetroStickyTexture.position.y = scene.paddle.position.y + scene.paddleRetroStickyTexture.size.height/2 - scene.paddle.size.height/2
        scene.ball.position.x = 0
        scene.ball.position.y = scene.ballStartingPositionY
        // Reset ball and paddle

        if scene.resumeGameToLoad! == false {
            let startingScale = SKAction.scale(to: 0.8, duration: 0)
            let startingScalePaddle = SKAction.scaleX(to: 0.0, duration: 0)
            let startingFade = SKAction.fadeOut(withDuration: 0)
            let scaleUp = SKAction.scale(to: 1, duration: 0.2)
            let scaleUpPaddle = SKAction.scaleX(to: 1, duration: 0.2)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let wait = SKAction.wait(forDuration: 0.3)
            let startingGroup = SKAction.group([startingScale, startingFade])
            let startingGroupPaddle = SKAction.group([startingScalePaddle])
            let animationGroup = SKAction.group([scaleUp, fadeIn])
            let animationGroupPaddle = SKAction.group([scaleUpPaddle])
            let animationSequence = SKAction.sequence([wait, animationGroup])
            let animationSequencePaddle = SKAction.sequence([wait, animationGroupPaddle])
            
            scene.ball.run(startingGroup)
            scene.ball.isHidden = false
            scene.ball.run(animationSequence, completion: {
                self.scene.ballStartingPositionY = self.scene.ball.position.y
                // Resets the ball's starting position incase it is moved during the animation in
            })
            scene.paddle.run(startingGroupPaddle)
            scene.paddle.isHidden = false
            scene.paddle.run(animationSequencePaddle, completion: {
                self.scene.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            })
            
            if scene.paddleTexture == scene.retroPaddle {
                scene.paddleRetroTexture.run(startingGroupPaddle)
                scene.paddleRetroTexture.isHidden = false
                scene.paddleRetroTexture.run(animationSequencePaddle)
            }
            // Animate paddle and ball in
        // Don't animate if resuming from save
        } else if scene.resumeGameToLoad! {
            scene.ball.isHidden = false
            scene.paddle.isHidden = false
            if scene.paddleTexture == scene.retroPaddle {
                scene.paddleRetroTexture.isHidden = false
            }
            scene.totalScore = scene.totalScore - scene.levelScore
            
            if scene.saveBallPropertiesArray != [] {
                scene.pauseBallVelocityX = CGFloat(scene.saveBallPropertiesArray![2])
                scene.pauseBallVelocityY = CGFloat(scene.saveBallPropertiesArray![3])
                            
                if sqrt(scene.pauseBallVelocityX*scene.pauseBallVelocityX) + sqrt(scene.pauseBallVelocityY*scene.pauseBallVelocityY) == 0 {
                    scene.ballLaunchAngleRad = scene.straightLaunchAngleRad + scene.minLaunchAngleRad
                    scene.pauseBallVelocityX = cos(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
                    scene.pauseBallVelocityY = sin(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
                }
                // If ball velocity is zero, but shouldn't be, set a default launch speed when resuming
            }
        }
        // Reset total score to reflect pre-save value
            
        if scene.saveBrickXPositionArray != [] {
            scene.resumeBrickCreation()
            // Load saved level
        } else {
            scene.levelTimerBonus = 500
            scene.levelTimerValue = 0
            // reset level timer bonus
            
            if scene.levelNumber == LevelPackSetup().startLevelNumber[scene.packNumber] || scene.levelNumber == 0 || scene.numberOfLevels == 1 {
                scene.firstLevel = true
                scene.showInbetweenView()
                scene.firstLevel = false
            }
            // Show the level intro screen if the first level of the pack
            
            switch scene.levelNumber {
                
            // Endless mode
            case 0:
                scene.loadLevel999()
                
            // Classic Pack
            case 1:
                scene.loadLevel1()
            case 2:
                scene.loadLevel2()
            case 3:
                scene.loadLevel3()
            case 4:
                scene.loadLevel4()
            case 5:
                scene.loadLevel5()
            case 6:
                scene.loadLevel6()
            case 7:
                scene.loadLevel7()
            case 8:
                scene.loadLevel8()
            case 9:
                scene.loadLevel9()
            case 10:
                scene.loadLevel10()
                
            // Space Pack
            case 11:
                scene.loadLevel11()
            case 12:
                scene.loadLevel12()
            case 13:
                scene.loadLevel13()
            case 14:
                scene.loadLevel14()
            case 15:
                scene.loadLevel15()
            case 16:
                scene.loadLevel16()
            case 17:
                scene.loadLevel17()
            case 18:
                scene.loadLevel18()
            case 19:
                scene.loadLevel19()
            case 20:
                scene.loadLevel20()
                
            // Nature Pack
            case 21:
                scene.loadLevel21()
            case 22:
                scene.loadLevel22()
            case 23:
                scene.loadLevel23()
            case 24:
                scene.loadLevel24()
            case 25:
                scene.loadLevel25()
            case 26:
                scene.loadLevel26()
            case 27:
                scene.loadLevel27()
            case 28:
                scene.loadLevel28()
            case 29:
                scene.loadLevel29()
            case 30:
                scene.loadLevel30()
                
            // Nature Pack
            case 31:
                scene.loadLevel31()
            case 32:
                scene.loadLevel32()
            case 33:
                scene.loadLevel33()
            case 34:
                scene.loadLevel34()
            case 35:
                scene.loadLevel35()
            case 36:
                scene.loadLevel36()
            case 37:
                scene.loadLevel37()
            case 38:
                scene.loadLevel38()
            case 39:
                scene.loadLevel39()
            case 40:
                scene.loadLevel40()
                
            // Food Pack
            case 41:
                scene.loadLevel41()
            case 42:
                scene.loadLevel42()
            case 43:
                scene.loadLevel43()
            case 44:
                scene.loadLevel44()
            case 45:
                scene.loadLevel45()
            case 46:
                scene.loadLevel46()
            case 47:
                scene.loadLevel47()
            case 48:
                scene.loadLevel48()
            case 49:
                scene.loadLevel49()
            case 50:
                scene.loadLevel50()
                
            // Computer Pack
            case 51:
                scene.loadLevel51()
            case 52:
                scene.loadLevel52()
            case 53:
                scene.loadLevel53()
            case 54:
                scene.loadLevel54()
            case 55:
                scene.loadLevel55()
            case 56:
                scene.loadLevel56()
            case 57:
                scene.loadLevel57()
            case 58:
                scene.loadLevel58()
            case 59:
                scene.loadLevel59()
            case 60:
                scene.loadLevel60()
            
            // Body Pack
            case 61:
                scene.loadLevel61()
            case 62:
                scene.loadLevel62()
            case 63:
                scene.loadLevel63()
            case 64:
                scene.loadLevel64()
            case 65:
                scene.loadLevel65()
            case 66:
                scene.loadLevel66()
            case 67:
                scene.loadLevel67()
            case 68:
                scene.loadLevel68()
            case 69:
                scene.loadLevel69()
            case 70:
                scene.loadLevel70()
            
            // Geography Pack
            case 71:
                scene.loadLevel71()
            case 72:
                scene.loadLevel72()
            case 73:
                scene.loadLevel73()
            case 74:
                scene.loadLevel74()
            case 75:
                scene.loadLevel75()
            case 76:
                scene.loadLevel76()
            case 77:
                scene.loadLevel77()
            case 78:
                scene.loadLevel78()
            case 79:
                scene.loadLevel79()
            case 80:
                scene.loadLevel80()

            // Emoji Pack
            case 81:
                scene.loadLevel81()
            case 82:
                scene.loadLevel82()
            case 83:
                scene.loadLevel83()
            case 84:
                scene.loadLevel84()
            case 85:
                scene.loadLevel85()
            case 86:
                scene.loadLevel86()
            case 87:
                scene.loadLevel87()
            case 88:
                scene.loadLevel88()
            case 89:
                scene.loadLevel89()
            case 90:
                scene.loadLevel90()

            // Numbers Pack
            case 91:
                scene.loadLevel91()
            case 92:
                scene.loadLevel92()
            case 93:
                scene.loadLevel93()
            case 94:
                scene.loadLevel94()
            case 95:
                scene.loadLevel95()
            case 96:
                scene.loadLevel96()
            case 97:
                scene.loadLevel97()
            case 98:
                scene.loadLevel98()
            case 99:
                scene.loadLevel99()
            case 100:
                scene.loadLevel100()

            // Challenge Pack
            case 101:
                scene.loadLevel101()
            case 102:
                scene.loadLevel102()
            case 103:
                scene.loadLevel103()
            case 104:
                scene.loadLevel104()
            case 105:
                scene.loadLevel105()
            case 106:
                scene.loadLevel106()
            case 107:
                scene.loadLevel107()
            case 108:
                scene.loadLevel108()
            case 109:
                scene.loadLevel109()
            case 110:
                scene.loadLevel110()
                
            default:
                break
            }
            // Load level in
        }
    }
    
    override func willExit(to nextState: GKState) {
        scene.gameInProgress = false
        scene.defaults.set(scene.gameInProgress!, forKey: "gameInProgress")
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is GameOver.Type:
            return true
        case is InbetweenLevels.Type:
            return true
        case is Paused.Type:
            return true
        case is Ad.Type:
            return true
        default:
            return false
        }
    }
}

