//
//  InbewteenLevels.swift
//  Megaball
//
//  Created by James Harding on 05/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit

class InbetweenLevels: GKState {
    unowned let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
                        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToContinueReceived(_:)), name: .continueToNextLevel, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed continue on the end level popup
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationToRestartReceived(_:)), name: .restart, object: nil)
        // Sets up an observer to watch for notifications to check if the user has pressed restart on the end level, gameover popup
        
        if previousState is Playing {
            scene.saveCurrentGame()
            inbetweenLevels()
        }
        
        if previousState is Ad {
            if scene.endlessMode || scene.gameoverStatus {
                scene.showPauseMenu(sender: "Game Over")
            } else {
                scene.showPauseMenu(sender: "Complete")
            }
        }
    }
//    // This function runs when this state is entered.
    
    func inbetweenLevels() {
        if scene.musicSetting! {
            MusicHandler.sharedHelper.menuVolume()
        }
        
        resetGameScene()
        saveGameData()
        achievementsCheck()
        saveStatsArrayData()
        if scene.gameCenterSetting! {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        showAd()
    }
    
    func resetGameScene() {
        
        let scaleUp = SKAction.scale(by: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let scaleDownPaddle = SKAction.scaleX(to: 0.0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: 0.1)
        let ballSequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
        let paddleSequence = SKAction.sequence([wait, scaleDownPaddle])
        let scaleReset = SKAction.scale(to: 1, duration: 0)
        let scaleResetPaddle = SKAction.scaleX(to: 1, duration: 0)
        let fadeReset = SKAction.fadeIn(withDuration: 0)
        let resetGroup = SKAction.group([scaleReset, fadeReset])
        let resetGroupPaddle = SKAction.group([scaleResetPaddle])
        // Setup ball and paddle animations
        
        scene.ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
        // Stop ball
        
        scene.ball.run(ballSequence, completion: {
            self.scene.ball.run(resetGroup, completion: {
                self.scene.ball.isHidden = true
            })
        })
        scene.paddle.run(paddleSequence, completion: {
            self.scene.paddle.run(resetGroupPaddle, completion: {
                self.scene.paddle.isHidden = true
                self.scene.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            })
        })
        scene.paddleRetroTexture.run(paddleSequence, completion: {
            self.scene.paddleRetroTexture.run(resetGroupPaddle, completion: {
                self.scene.paddleRetroTexture.isHidden = true
            })
        })
        // Animate retro paddle and ball out after level is won
        
        if scene.backstop.isHidden == false && scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[26] == false {
            scene.totalStatsArray[0].achievementsUnlockedArray[26] = true
            scene.totalStatsArray[0].achievementDates[26] = Date()
            let achievement = GKAchievement(identifier: "endBackstop")
            if achievement.isCompleted == false {
                achievement.showsCompletionBanner = true
                GKAchievement.report([achievement]) { (error) in
                    print(error?.localizedDescription ?? "Error reporting endBackstop achievement")
                }
            }
        }
        // Backstop active at end of level achievement
        
        scene.powerUpsReset()
        // Reset any power ups
        
        if scene.soundsSetting! {
            if scene.gameoverStatus || scene.endlessMode {
                self.scene.run(scene.gameOverSound)
            } else {
                self.scene.run(scene.levelCompleteSound)
            }
        }
        
        let scaleDown2 = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut2 = SKAction.fadeOut(withDuration: 0.2)
        let removeItemGroup = SKAction.group([scaleDown2, fadeOut2])
        scene.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.bricksLeft = 0
        // Remove any remaining bricks
        
        scene.enumerateChildNodes(withName: BrickRemovalCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining bricks being removed
        
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        scene.powerUpsOnScreen = 0
        // Remove any remaining power-ups
        
        scene.enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining lasers
        
        let waitEndScene = SKAction.wait(forDuration: 1.0)
        self.scene.run(waitEndScene, completion: {
            self.scene.removeAllActions()
            self.scene.ballIsOnPaddle = true
        })
        // Remove any remaining actions after short delay
        
    }
    
    func saveGameData() {
        if scene.endlessMode {
            scene.totalStatsArray[0].endlessModeHeight.append(scene.endlessHeight)
            scene.totalStatsArray[0].endlessModeHeightDate.append(Date())
        } else {
            var packEndLivesBonus = 0
            if scene.levelNumber == scene.endLevelNumber && scene.gameoverStatus == false && scene.numberOfLevels != 1 {
                packEndLivesBonus = scene.numberOfLives*100
                // Additional lives remaining equal 100 bonus points each
            }
            scene.totalScore = scene.totalScore + scene.levelScore + scene.levelTimerBonus + packEndLivesBonus
            
            scene.totalStatsArray[0].cumulativeScore = scene.totalStatsArray[0].cumulativeScore + scene.levelScore + scene.levelTimerBonus
            // Update total and cumulative scores
            scene.totalStatsArray[0].levelsPlayed+=1
        }

        if scene.gameoverStatus == false && scene.endlessMode == false && scene.numberOfLevels != 1 {
            if scene.levelNumber != scene.endLevelNumber {
                scene.totalStatsArray[0].levelUnlockedArray[scene.levelNumber+1] = true
                scene.numberOfLives+=1
            }
            // Unlock next level and add extra life if next level exists
            scene.totalStatsArray[0].levelsCompleted+=1
        }
        scene.totalStatsArray[0].playTimeSecs = scene.totalStatsArray[0].playTimeSecs + scene.levelTimerValue
        if scene.endlessMode == false && (scene.gameoverStatus == true || scene.levelNumber == self.scene.endLevelNumber) && scene.numberOfLevels != 1 {
            scene.totalStatsArray[0].packsPlayed+=1
        }
        if scene.gameoverStatus == false && scene.levelNumber == scene.endLevelNumber && scene.numberOfLevels != 1 && scene.endlessMode == false {
            scene.totalStatsArray[0].packsCompleted+=1
        }
        // Update total stats
        
        scene.totalStatsArray[0].dateSaved = Date()
        
        if scene.endlessMode == false {
            
            if (scene.levelScore + scene.levelTimerBonus) > scene.packLevelHighScoresArray![scene.packNumber-2][scene.levelNumber-LevelPackSetup().startLevelNumber[scene.packNumber]] {
                scene.packLevelHighScoresArray![scene.packNumber-2][scene.levelNumber-LevelPackSetup().startLevelNumber[scene.packNumber]] = (scene.levelScore + scene.levelTimerBonus)
            }
        }
        // Update level stats
        
        scene.packTimerValue = scene.packTimerValue + scene.levelTimerValue
        if (scene.levelNumber == scene.endLevelNumber || scene.gameoverStatus) && scene.numberOfLevels != 1 && scene.endlessMode == false {
            if scene.totalScore > scene.totalStatsArray[0].packHighScores[scene.packNumber-2] {
                scene.totalStatsArray[0].packHighScores[scene.packNumber-2] = scene.totalScore
            }
            if scene.gameoverStatus == false {
                if scene.totalStatsArray[0].packBestTimes[scene.packNumber-2] == 0 || scene.packTimerValue < scene.totalStatsArray[0].packBestTimes[scene.packNumber-2] {
                    scene.totalStatsArray[0].packBestTimes[scene.packNumber-2] = scene.packTimerValue
                }
            }
        }
    
        scene.totalStatsArray[0].pack1LevelHighScores = scene.packLevelHighScoresArray![0]
        scene.totalStatsArray[0].pack2LevelHighScores = scene.packLevelHighScoresArray![1]
        scene.totalStatsArray[0].pack3LevelHighScores = scene.packLevelHighScoresArray![2]
        scene.totalStatsArray[0].pack4LevelHighScores = scene.packLevelHighScoresArray![3]
        scene.totalStatsArray[0].pack5LevelHighScores = scene.packLevelHighScoresArray![4]
        scene.totalStatsArray[0].pack6LevelHighScores = scene.packLevelHighScoresArray![5]
        scene.totalStatsArray[0].pack7LevelHighScores = scene.packLevelHighScoresArray![6]
        scene.totalStatsArray[0].pack8LevelHighScores = scene.packLevelHighScoresArray![7]
        scene.totalStatsArray[0].pack9LevelHighScores = scene.packLevelHighScoresArray![8]
        scene.totalStatsArray[0].pack10LevelHighScores = scene.packLevelHighScoresArray![9]
        scene.totalStatsArray[0].pack11LevelHighScores = scene.packLevelHighScoresArray![10]
        
        saveStatsArrayData()
        // Save total stats
        if scene.gameCenterSetting! {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
    }
    
    func saveStatsArrayData() {
        scene.totalStatsArray[0].dateSaved = Date()
        do {
            let data = try scene.encoder.encode(self.scene.totalStatsArray)
            try data.write(to: scene.totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        CloudKitHandler().saveToiCloud()
        // Save total stats
    }
    
    func showAd() {
        let waitScene = SKAction.wait(forDuration: 0.5)
        self.scene.run(waitScene, completion: {
            if self.scene.adsSetting! {
                self.scene.gameState.enter(Ad.self)
                self.scene.gameViewControllerDelegate?.showAd()
                // Show ad
            } else {
                if self.scene.endlessMode || self.scene.gameoverStatus == true  {
                    self.scene.showPauseMenu(sender: "Game Over")
                    // Show game over pop-up
                } else if self.scene.levelNumber == self.scene.endLevelNumber {
                    self.scene.showPauseMenu(sender: "Complete")
                    // Show game complete
                } else {
                    self.scene.showInbetweenView()
                    // Move to the next level after a delay
                }
            }
        })
    }
    
    func achievementsCheck() {
    
        if scene.endlessMode == false {
        // End of level
            let levelAchievementScore = scene.levelScore + scene.levelTimerBonus
            if levelAchievementScore >= 5000 && scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[43] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[43] = true
                scene.totalStatsArray[0].achievementDates[43] = Date()
                let achievement = GKAchievement(identifier: "fiveKPointsLevel")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting fiveKPointsLevel achievement")
                    }
                }
            }
            if levelAchievementScore >= 10000 && scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[44] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[44] = true
                scene.totalStatsArray[0].achievementDates[44] = Date()
                let achievement = GKAchievement(identifier: "tenKPointsLevel")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenKPointsLevel achievement")
                    }
                }
            }
            // Level score achievements
            
            if scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[51] == false {
                let percentComplete = Double(scene.totalStatsArray[0].cumulativeScore)/100000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[51] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[51] = true
                    scene.totalStatsArray[0].achievementDates[51] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[51] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "hundredKTotalScore")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting hundredKTotalScore achievement")
                    }
                }
            }
            if scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[52] == false {
                let percentComplete = Double(scene.totalStatsArray[0].cumulativeScore)/500000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[52] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[52] = true
                    scene.totalStatsArray[0].achievementDates[52] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[52] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "fiveHundredKTotalScore")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting fiveHundredKTotalScore achievement")
                    }
                }
            }
            if scene.endlessMode == false && scene.totalStatsArray[0].achievementsUnlockedArray[53] == false {
                let percentComplete = Double(scene.totalStatsArray[0].cumulativeScore)/1000000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[53] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[53] = true
                    scene.totalStatsArray[0].achievementDates[53] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[53] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "millTotalScore")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting millTotalScore achievement")
                    }
                }
            }
            // Total score achievements
        }
            
        if scene.endlessMode == false && scene.gameoverStatus == false {
        // End of level and not game over
            if scene.deathsPerLevel == 0 && scene.totalStatsArray[0].achievementsUnlockedArray[36] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[36] = true
                scene.totalStatsArray[0].achievementDates[36] = Date()
                let achievement = GKAchievement(identifier: "noBallsLost")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting noBallsLost achievement")
                    }
                }
            }
            if scene.deathsPerLevel >= 3 && scene.totalStatsArray[0].achievementsUnlockedArray[37] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[37] = true
                scene.totalStatsArray[0].achievementDates[37] = Date()
                let achievement = GKAchievement(identifier: "threeBallsLost")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting threeBallsLost achievement")
                    }
                }
            }
            scene.deathsPerPack = scene.deathsPerPack + scene.deathsPerLevel
            scene.deathsPerLevel = 0
            // Level death achievements
            
            if scene.powerUpsCollectedPerLevel >= 5 && scene.powerUpsCollectedPerLevel == scene.powerUpsGeneratedPerLevel && scene.totalStatsArray[0].achievementsUnlockedArray[38] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[38] = true
                scene.totalStatsArray[0].achievementDates[38] = Date()
                let achievement = GKAchievement(identifier: "allLevelPowerUps")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting allLevelPowerUps achievement")
                    }
                }
            }
            if scene.powerUpsGeneratedPerLevel >= 5 && scene.powerUpsCollectedPerLevel == 0 && scene.endlessMode == false && scene.gameoverStatus == false && scene.totalStatsArray[0].achievementsUnlockedArray[39] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[39] = true
                scene.totalStatsArray[0].achievementDates[39] = Date()
                let achievement = GKAchievement(identifier: "noLevelPowerUps")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting noLevelPowerUps achievement")
                    }
                }
            }
            scene.powerUpsCollectedPerPack = scene.powerUpsCollectedPerPack + scene.powerUpsCollectedPerLevel
            scene.powerUpsGeneratedPerPack = scene.powerUpsGeneratedPerPack + scene.powerUpsGeneratedPerLevel
            scene.powerUpsCollectedPerLevel = 0
            // Level power-up achievements
            
            if scene.totalStatsArray[0].levelsCompleted == 1 && scene.totalStatsArray[0].achievementsUnlockedArray[45] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[45] = true
                scene.totalStatsArray[0].achievementDates[45] = Date()
                let achievement = GKAchievement(identifier: "oneLevelsComplete")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting oneLevelsComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[46] == false {
                let percentComplete = Double(scene.totalStatsArray[0].levelsCompleted)/10.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[46] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[46] = true
                    scene.totalStatsArray[0].achievementDates[46] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[46] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "tenLevelsComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenLevelsComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[47] == false {
                let percentComplete = Double(scene.totalStatsArray[0].levelsCompleted)/100.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[47] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[47] = true
                    scene.totalStatsArray[0].achievementDates[47] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[47] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "hunderdLevelsComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting hunderdLevelsComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[48] == false {
                let percentComplete = Double(scene.totalStatsArray[0].levelsCompleted)/1000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[48] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[48] = true
                    scene.totalStatsArray[0].achievementDates[48] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[48] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "oneKLevelsComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting oneKLevelsComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[49] == false {
                let percentComplete = Double(scene.totalStatsArray[0].levelsCompleted)/10000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[49] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[49] = true
                    scene.totalStatsArray[0].achievementDates[49] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[49] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "tenKLevelsComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenKLevelsComplete achievement")
                    }
                }
            }
            // Levels compeleted achievements
            
            if scene.levelTimerValue <= 60 && scene.totalStatsArray[0].achievementsUnlockedArray[40] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[40] = true
                scene.totalStatsArray[0].achievementDates[40] = Date()
                let achievement = GKAchievement(identifier: "quickLevelComplete")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting quickLevelComplete achievement")
                    }
                }
            }
            // Level speed achievements
        }
        
        if (scene.levelNumber == scene.endLevelNumber) && scene.numberOfLevels != 1 && scene.endlessMode == false && scene.gameoverStatus == false {
        // End of pack and complete
            if scene.totalScore >= 10000 && scene.totalStatsArray[0].achievementsUnlockedArray[59] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[59] = true
                scene.totalStatsArray[0].achievementDates[59] = Date()
                let achievement = GKAchievement(identifier: "tenKPointsPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenKPointsPack achievement")
                    }
                }
            }
            if scene.totalScore >= 25000 && scene.totalStatsArray[0].achievementsUnlockedArray[60] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[60] = true
                scene.totalStatsArray[0].achievementDates[60] = Date()
                let achievement = GKAchievement(identifier: "twoFiveKPointsPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting twoFiveKPointsPack achievement")
                    }
                }
            }
            if scene.totalScore >= 50000 && scene.totalStatsArray[0].achievementsUnlockedArray[61] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[61] = true
                scene.totalStatsArray[0].achievementDates[61] = Date()
                let achievement = GKAchievement(identifier: "fiftyKPointsPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting fiftyKPointsPack achievement")
                    }
                }
            }
            // Pack score achievements
            
            if scene.levelNumber == 10 && scene.totalStatsArray[0].achievementsUnlockedArray[6] == false {
                scene.newItemsBool = true
                
                if scene.totalStatsArray[0].achievementsUnlockedArray[8] && scene.totalStatsArray[0].achievementsUnlockedArray[7] && scene.totalStatsArray[0].achievementsUnlockedArray[6] {
                    scene.totalStatsArray[0].levelPackUnlockedArray[5] = true
                }
                // Only unlock pack 4[5] if first 3 packs have been completed
                scene.totalStatsArray[0].appIconUnlockedArray[1] = true
                scene.totalStatsArray[0].themeUnlockedArray[1] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[6] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[7] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[6] = true
                scene.totalStatsArray[0].achievementDates[6] = Date()
                let achievementPack = GKAchievement(identifier: "classicPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting classicPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 20 && scene.totalStatsArray[0].achievementsUnlockedArray[7] == false {
                scene.newItemsBool = true
                
                if scene.totalStatsArray[0].achievementsUnlockedArray[8] && scene.totalStatsArray[0].achievementsUnlockedArray[7] && scene.totalStatsArray[0].achievementsUnlockedArray[6] {
                    scene.totalStatsArray[0].levelPackUnlockedArray[5] = true
                }
                // Only unlock pack 4[5] if first 3 packs have been completed
                scene.totalStatsArray[0].appIconUnlockedArray[2] = true
                scene.totalStatsArray[0].themeUnlockedArray[2] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[10] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[11] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[7] = true
                scene.totalStatsArray[0].achievementDates[7] = Date()
                let achievementPack = GKAchievement(identifier: "spacePackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting spacePackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 30 && scene.totalStatsArray[0].achievementsUnlockedArray[8] == false {
                scene.newItemsBool = true
                
                if scene.totalStatsArray[0].achievementsUnlockedArray[8] && scene.totalStatsArray[0].achievementsUnlockedArray[7] && scene.totalStatsArray[0].achievementsUnlockedArray[6] {
                    scene.totalStatsArray[0].levelPackUnlockedArray[5] = true
                }
                // Only unlock pack 4[5] if first 3 packs have been completed
                scene.totalStatsArray[0].appIconUnlockedArray[3] = true
                scene.totalStatsArray[0].themeUnlockedArray[3] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[12] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[13] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[8] = true
                scene.totalStatsArray[0].achievementDates[8] = Date()
                let achievementPack = GKAchievement(identifier: "naturePackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting naturePackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 40 && scene.totalStatsArray[0].achievementsUnlockedArray[9] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[6] = true
                scene.totalStatsArray[0].appIconUnlockedArray[4] = true
                scene.totalStatsArray[0].themeUnlockedArray[4] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[20] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[21] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[9] = true
                scene.totalStatsArray[0].achievementDates[9] = Date()
                let achievementPack = GKAchievement(identifier: "urbanPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting urbanPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 50 && scene.totalStatsArray[0].achievementsUnlockedArray[10] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[7] = true
                scene.totalStatsArray[0].appIconUnlockedArray[5] = true
                scene.totalStatsArray[0].themeUnlockedArray[5] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[22] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[23] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[10] = true
                scene.totalStatsArray[0].achievementDates[10] = Date()
                let achievementPack = GKAchievement(identifier: "foodPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting foodPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 60 && scene.totalStatsArray[0].achievementsUnlockedArray[11] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[8] = true
                scene.totalStatsArray[0].appIconUnlockedArray[6] = true
                scene.totalStatsArray[0].themeUnlockedArray[6] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[24] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[25] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[11] = true
                scene.totalStatsArray[0].achievementDates[11] = Date()
                let achievementPack = GKAchievement(identifier: "computerPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting computerPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 70 && scene.totalStatsArray[0].achievementsUnlockedArray[12] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[9] = true
                scene.totalStatsArray[0].appIconUnlockedArray[7] = true
                scene.totalStatsArray[0].themeUnlockedArray[7] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[26] = true
                scene.totalStatsArray[0].powerUpUnlockedArray[27] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[12] = true
                scene.totalStatsArray[0].achievementDates[12] = Date()
                let achievementPack = GKAchievement(identifier: "bodyPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting bodyPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 80 && scene.totalStatsArray[0].achievementsUnlockedArray[13] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[10] = true
                scene.totalStatsArray[0].appIconUnlockedArray[8] = true
                scene.totalStatsArray[0].themeUnlockedArray[8] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[13] = true
                scene.totalStatsArray[0].achievementDates[13] = Date()
                let achievementPack = GKAchievement(identifier: "worldPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting worldPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 90 && scene.totalStatsArray[0].achievementsUnlockedArray[14] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[11] = true
                scene.totalStatsArray[0].appIconUnlockedArray[9] = true
                scene.totalStatsArray[0].themeUnlockedArray[9] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[14] = true
                scene.totalStatsArray[0].achievementDates[14] = Date()
                let achievementPack = GKAchievement(identifier: "emojiPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting emojiPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 100 && scene.totalStatsArray[0].achievementsUnlockedArray[15] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].levelPackUnlockedArray[12] = true
                scene.totalStatsArray[0].appIconUnlockedArray[10] = true
                scene.totalStatsArray[0].themeUnlockedArray[10] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[15] = true
                scene.totalStatsArray[0].achievementDates[15] = Date()
                let achievementPack = GKAchievement(identifier: "numbersPackComplete")
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting numbersPackComplete achievement")
                    }
                }
            }
            if scene.levelNumber == 110 && scene.totalStatsArray[0].achievementsUnlockedArray[16] == false {
                scene.newItemsBool = true
                scene.totalStatsArray[0].appIconUnlockedArray[11] = true
                scene.totalStatsArray[0].themeUnlockedArray[11] = true
                scene.totalStatsArray[0].achievementsUnlockedArray[16] = true
                scene.totalStatsArray[0].achievementDates[16] = Date()
                let achievementPack = GKAchievement(identifier: "challengePackComplete")
                if achievementPack.isCompleted == false {
                                        achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting challengePackComplete achievement")
                    }
                }
            }
            // Level pack complete achievements & pack unlocks

            if scene.deathsPerPack == 0 && scene.totalStatsArray[0].achievementsUnlockedArray[54] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[54] = true
                scene.totalStatsArray[0].achievementDates[54] = Date()
                let achievement = GKAchievement(identifier: "noBallsLostPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting noBallsLostPack achievement")
                    }
                }
            }
            if scene.deathsPerPack >= 10 && scene.totalStatsArray[0].achievementsUnlockedArray[55] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[55] = true
                scene.totalStatsArray[0].achievementDates[55] = Date()
                let achievement = GKAchievement(identifier: "tenBallsLostPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenBallsLostPack achievement")
                    }
                }
            }
            // Pack death achievements
            
            if scene.powerUpsCollectedPerPack >= 5 && scene.powerUpsCollectedPerPack == scene.powerUpsGeneratedPerPack && scene.totalStatsArray[0].achievementsUnlockedArray[56] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[56] = true
                scene.totalStatsArray[0].achievementDates[56] = Date()
                let achievement = GKAchievement(identifier: "allPackPowerUps")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting allPackPowerUps achievement")
                    }
                }
            }
            if scene.powerUpsGeneratedPerLevel >= 5 && scene.powerUpsCollectedPerPack == 0 && scene.totalStatsArray[0].achievementsUnlockedArray[57] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[57] = true
                scene.totalStatsArray[0].achievementDates[57] = Date()
                let achievement = GKAchievement(identifier: "noPackPowerUps")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting noPackPowerUps achievement")
                    }
                }
            }
            // Pack power-up achievements
            
            if scene.packTimerValue <= 600 && scene.totalStatsArray[0].achievementsUnlockedArray[58] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[58] = true
                scene.totalStatsArray[0].achievementDates[58] = Date()
                let achievement = GKAchievement(identifier: "quickPackComplete")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting quickPackComplete achievement")
                    }
                }
            }
            // Pack speed achievement
            
            if scene.totalStatsArray[0].packBestTimes[0] > 0 && scene.totalStatsArray[0].packBestTimes[1] > 0 && scene.totalStatsArray[0].packBestTimes[2] > 0 {
                scene.totalStatsArray[0].levelPackUnlockedArray[5] = true
            }
                        
            if scene.totalStatsArray[0].packHighScores[scene.packNumber-2] > 0 && scene.totalStatsArray[0].achievementsUnlockedArray[62] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[62] = true
                scene.totalStatsArray[0].achievementDates[62] = Date()
                let achievement = GKAchievement(identifier: "onePacksComplete")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting onePacksComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[63] == false {
                let percentComplete = Double(scene.totalStatsArray[0].packsCompleted)/10.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[63] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[63] = true
                    scene.totalStatsArray[0].achievementDates[63] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[63] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "tenPacksComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting tenPacksComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].packsCompleted <= 100 {
                let percentComplete = Double(scene.totalStatsArray[0].packsCompleted)/100.0*100.0
                if percentComplete >= 100.0 && scene.totalStatsArray[0].achievementsUnlockedArray[64] == false {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[64] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[64] = true
                    scene.totalStatsArray[0].achievementDates[64] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[64] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "hundredPacksComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting hundredPacksComplete achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].packsCompleted <= 1000 {
                let percentComplete = Double(scene.totalStatsArray[0].packsCompleted)/1000.0*100.0
                if percentComplete >= 100.0 && scene.totalStatsArray[0].achievementsUnlockedArray[65] == false {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[65] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[65] = true
                    scene.totalStatsArray[0].achievementDates[65] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[65] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "thousandPacksComplete")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting thousandPacksComplete achievement")
                    }
                }
            }
            // Pack complete achievements
        }
        
        if scene.endlessMode {
            if scene.totalStatsArray[0].achievementsUnlockedArray[4] == false {
                let percentComplete = Double(scene.totalStatsArray[0].endlessModeHeight.reduce(0, +))/5000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[4] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[4] = true
                    scene.totalStatsArray[0].achievementDates[4] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[4] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "achievementEndlessFiveK")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting achievementEndlessFiveK achievement")
                    }
                }
            }
            if scene.totalStatsArray[0].achievementsUnlockedArray[5] == false {
                let percentComplete = Double(scene.totalStatsArray[0].endlessModeHeight.reduce(0, +))/10000.0*100.0
                if percentComplete >= 100.0 {
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[5] = "100%"
                    scene.totalStatsArray[0].achievementsUnlockedArray[5] = true
                    scene.totalStatsArray[0].achievementDates[5] = Date()
                } else if percentComplete < 100.0 {
                    let percentCompleteString = String(format:"%.1f", percentComplete)
                    scene.totalStatsArray[0].achievementsPercentageCompleteArray[5] = String(percentCompleteString)+"%"
                }
                let achievement = GKAchievement(identifier: "achievementEndlessTenK")
                if achievement.isCompleted == false {
                    achievement.percentComplete = percentComplete
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        print(error?.localizedDescription ?? "Error reporting achievementEndlessTenK achievement")
                    }
                }
            }
        }
        // Endless mode total height achievements
    }
    
    @objc func notificationToContinueReceived(_ notification: Notification) {
        scene.gameState.enter(Playing.self)
    }
    // Call the function to load the next level if a notification from the end level popup is received
    
    @objc func notificationToRestartReceived(_ notification: Notification) {
        scene.gameState.enter(PreGame.self)
    }
    // Call the function...
    
    override func willExit(to nextState: GKState) {
    }
    // This function runs when this state is exited.
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
        case is PreGame.Type:
            return true
        case is Playing.Type:
            return true
        case is Ad.Type:
            return true
        case is GameOver.Type:
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    public static let continueToNextLevel = Notification.Name(rawValue: "continueToNextLevel")
}
// Notification setup for sending information from the end level popup to load the next level

extension Notification.Name {
    public static let restart = Notification.Name(rawValue: "restart")
}
// Notification setup for sending information from the end level game over popup to restart
