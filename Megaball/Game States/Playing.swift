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
        
        scene.gameInProgress = true
        scene.defaults.set(scene.gameInProgress!, forKey: "gameInProgress")
        
        scene.userSettings()
        // Set user settings
        
        if scene.musicSetting! {
            if scene.ballIsOnPaddle == false {
                MusicHandler.sharedHelper.gameVolume()
            } else {
                MusicHandler.sharedHelper.menuVolume()
            }
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
                    scene.previousHighscore = scene.packLevelHighScoresArray![scene.packNumber-2][scene.levelNumber-LevelPackSetup().startLevelNumber[scene.packNumber]]
                } else {
                    scene.previousHighscore = scene.totalStatsArray[0].packHighScores[scene.packNumber-2]
                }
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
        
//        scene.ball.position.y = scene.ballStartingPositionY

        if scene.resumeGameToLoad! {
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
            
            var waitDuration = 0.0
            
            if scene.levelNumber == LevelPackSetup().startLevelNumber[scene.packNumber] || scene.levelNumber == 0 || scene.numberOfLevels == 1 {
                scene.firstLevel = true
                scene.showInbetweenView()
                scene.firstLevel = false
                waitDuration = 0.10
            }
            // Show the level intro screen if the first level of the pack
            
            
            let wait = SKAction.wait(forDuration: waitDuration)
            self.scene.run(wait, completion: {
            // Add slight delay for loading first level to allow blur view to cover brick build animation properly
                
                switch self.scene.levelNumber {
                    
                // Endless mode
                case 0:
                    self.scene.loadLevel999()
                    
                // Classic Pack
                case 1:
                    self.scene.loadLevel1()
                case 2:
                    self.scene.loadLevel2()
                case 3:
                    self.scene.loadLevel3()
                case 4:
                    self.scene.loadLevel4()
                case 5:
                    self.scene.loadLevel5()
                case 6:
                    self.scene.loadLevel6()
                case 7:
                    self.scene.loadLevel7()
                case 8:
                    self.scene.loadLevel8()
                case 9:
                    self.scene.loadLevel9()
                case 10:
                    self.scene.loadLevel10()
                    
                // Space Pack
                case 11:
                    self.scene.loadLevel11()
                case 12:
                    self.scene.loadLevel12()
                case 13:
                    self.scene.loadLevel13()
                case 14:
                    self.scene.loadLevel14()
                case 15:
                    self.scene.loadLevel15()
                case 16:
                    self.scene.loadLevel16()
                case 17:
                    self.scene.loadLevel17()
                case 18:
                    self.scene.loadLevel18()
                case 19:
                    self.scene.loadLevel19()
                case 20:
                    self.scene.loadLevel20()
                    
                // Nature Pack
                case 21:
                    self.scene.loadLevel21()
                case 22:
                    self.scene.loadLevel22()
                case 23:
                    self.scene.loadLevel23()
                case 24:
                    self.scene.loadLevel24()
                case 25:
                    self.scene.loadLevel25()
                case 26:
                    self.scene.loadLevel26()
                case 27:
                    self.scene.loadLevel27()
                case 28:
                    self.scene.loadLevel28()
                case 29:
                    self.scene.loadLevel29()
                case 30:
                    self.scene.loadLevel30()
                    
                // Nature Pack
                case 31:
                    self.scene.loadLevel31()
                case 32:
                    self.scene.loadLevel32()
                case 33:
                    self.scene.loadLevel33()
                case 34:
                    self.scene.loadLevel34()
                case 35:
                    self.scene.loadLevel35()
                case 36:
                    self.scene.loadLevel36()
                case 37:
                    self.scene.loadLevel37()
                case 38:
                    self.scene.loadLevel38()
                case 39:
                    self.scene.loadLevel39()
                case 40:
                    self.scene.loadLevel40()
                    
                // Food Pack
                case 41:
                    self.scene.loadLevel41()
                case 42:
                    self.scene.loadLevel42()
                case 43:
                    self.scene.loadLevel43()
                case 44:
                    self.scene.loadLevel44()
                case 45:
                    self.scene.loadLevel45()
                case 46:
                    self.scene.loadLevel46()
                case 47:
                    self.scene.loadLevel47()
                case 48:
                    self.scene.loadLevel48()
                case 49:
                    self.scene.loadLevel49()
                case 50:
                    self.scene.loadLevel50()
                    
                // Computer Pack
                case 51:
                    self.scene.loadLevel51()
                case 52:
                    self.scene.loadLevel52()
                case 53:
                    self.scene.loadLevel53()
                case 54:
                    self.scene.loadLevel54()
                case 55:
                    self.scene.loadLevel55()
                case 56:
                    self.scene.loadLevel56()
                case 57:
                    self.scene.loadLevel57()
                case 58:
                    self.scene.loadLevel58()
                case 59:
                    self.scene.loadLevel59()
                case 60:
                    self.scene.loadLevel60()
                
                // Body Pack
                case 61:
                    self.scene.loadLevel61()
                case 62:
                    self.scene.loadLevel62()
                case 63:
                    self.scene.loadLevel63()
                case 64:
                    self.scene.loadLevel64()
                case 65:
                    self.scene.loadLevel65()
                case 66:
                    self.scene.loadLevel66()
                case 67:
                    self.scene.loadLevel67()
                case 68:
                    self.scene.loadLevel68()
                case 69:
                    self.scene.loadLevel69()
                case 70:
                    self.scene.loadLevel70()
                
                // Geography Pack
                case 71:
                    self.scene.loadLevel71()
                case 72:
                    self.scene.loadLevel72()
                case 73:
                    self.scene.loadLevel73()
                case 74:
                    self.scene.loadLevel74()
                case 75:
                    self.scene.loadLevel75()
                case 76:
                    self.scene.loadLevel76()
                case 77:
                    self.scene.loadLevel77()
                case 78:
                    self.scene.loadLevel78()
                case 79:
                    self.scene.loadLevel79()
                case 80:
                    self.scene.loadLevel80()

                // Emoji Pack
                case 81:
                    self.scene.loadLevel81()
                case 82:
                    self.scene.loadLevel82()
                case 83:
                    self.scene.loadLevel83()
                case 84:
                    self.scene.loadLevel84()
                case 85:
                    self.scene.loadLevel85()
                case 86:
                    self.scene.loadLevel86()
                case 87:
                    self.scene.loadLevel87()
                case 88:
                    self.scene.loadLevel88()
                case 89:
                    self.scene.loadLevel89()
                case 90:
                    self.scene.loadLevel90()

                // Numbers Pack
                case 91:
                    self.scene.loadLevel91()
                case 92:
                    self.scene.loadLevel92()
                case 93:
                    self.scene.loadLevel93()
                case 94:
                    self.scene.loadLevel94()
                case 95:
                    self.scene.loadLevel95()
                case 96:
                    self.scene.loadLevel96()
                case 97:
                    self.scene.loadLevel97()
                case 98:
                    self.scene.loadLevel98()
                case 99:
                    self.scene.loadLevel99()
                case 100:
                    self.scene.loadLevel100()

                // Challenge Pack
                case 101:
                    self.scene.loadLevel101()
                case 102:
                    self.scene.loadLevel102()
                case 103:
                    self.scene.loadLevel103()
                case 104:
                    self.scene.loadLevel104()
                case 105:
                    self.scene.loadLevel105()
                case 106:
                    self.scene.loadLevel106()
                case 107:
                    self.scene.loadLevel107()
                case 108:
                    self.scene.loadLevel108()
                case 109:
                    self.scene.loadLevel109()
                case 110:
                    self.scene.loadLevel110()
                    
                default:
                    break
                }
                // Load level in
            })
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

