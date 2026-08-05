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
    }
//    // This function runs when this state is entered.
    
    func inbetweenLevels() {
        if scene.musicSetting {
            MusicHandler.sharedHelper.menuVolume()
        }
        
        resetGameScene()
        saveGameData()
        achievementsCheck()
        scene.saveGameStats()
        if scene.gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center

        showEndOfLevelView()
    }

    func showEndOfLevelView() {
        let waitScene = SKAction.wait(forDuration: 0.5)
        self.scene.run(waitScene, completion: {
            if self.scene.endlessMode || self.scene.gameoverStatus == true {
                self.scene.showPauseMenu(sender: "Game Over")
                // Show game over pop-up
            } else if self.scene.levelNumber == self.scene.endLevelNumber {
                self.scene.showPauseMenu(sender: "Complete")
                // Show game complete
            } else {
                self.scene.showInbetweenView()
                // Move to the next level after a delay
            }
        })
    }
    // Presents the end-of-level UI. This routing previously lived inside showAd(),
    // which was deleted with the ad code — taking the non-ad branch with it, which
    // was the only branch that ran once ads were switched off.
    
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
                    Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endBackstop achievement", privacy: .public)")
                }
            }
        }
        // Backstop active at end of level achievement
        
        scene.powerUpsReset()
        // Reset any power ups
        
        if scene.soundsSetting {
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
                if let next = Progression.nextLevelIndex(after: scene.levelNumber,
                                                        endLevelNumber: scene.endLevelNumber) {
                    scene.totalStatsArray[0].levelUnlockedArray[next] = true
                }
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
        
        scene.saveGameStats()
        // Save total stats
        if scene.gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
    }
    
//    func saveStatsArrayData() {
//        scene.totalStatsArray[0].dateSaved = Date()
//        do {
//            let data = try scene.encoder.encode(self.scene.totalStatsArray)
//            try data.write(to: scene.totalStatsStore!)
//        } catch {
//            print("Error encoding total stats, \(error)")
//        }
//        CloudKitHandler().saveToiCloud()
//        // Save total stats
//    }
    
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting fiveKPointsLevel achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenKPointsLevel achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting hundredKTotalScore achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting fiveHundredKTotalScore achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting millTotalScore achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting noBallsLost achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting threeBallsLost achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting allLevelPowerUps achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting noLevelPowerUps achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting oneLevelsComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenLevelsComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting hunderdLevelsComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting oneKLevelsComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenKLevelsComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting quickLevelComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenKPointsPack achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting twoFiveKPointsPack achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting fiftyKPointsPack achievement", privacy: .public)")
                    }
                }
            }
            // Pack score achievements
            
            if let reward = Progression.reward(forLevel: scene.levelNumber),
               scene.totalStatsArray[0].achievementsUnlockedArray[reward.achievementIndex] == false {
                scene.newItemsBool = true

                if let nextPack = reward.nextPackIndex {
                    scene.totalStatsArray[0].levelPackUnlockedArray[nextPack] = true
                }
                scene.totalStatsArray[0].appIconUnlockedArray[reward.appIconIndex] = true
                scene.totalStatsArray[0].themeUnlockedArray[reward.themeIndex] = true
                for powerUp in reward.powerUpIndexes {
                    scene.totalStatsArray[0].powerUpUnlockedArray[powerUp] = true
                }
                scene.totalStatsArray[0].achievementsUnlockedArray[reward.achievementIndex] = true
                scene.totalStatsArray[0].achievementDates[reward.achievementIndex] = Date()

                let achievementPack = GKAchievement(identifier: reward.achievementIdentifier)
                if achievementPack.isCompleted == false {
                    achievementPack.showsCompletionBanner = true
                    GKAchievement.report([achievementPack]) { (error) in
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting \(reward.achievementIdentifier) achievement", privacy: .public)")
                    }
                }
            }
            // Pack completion rewards. Was eleven near-identical blocks; the table now
            // lives in Progression so the indices can be tested. City is not opened here
            // - the first three packs can be played in any order, so it is gated on all
            // three best times below
            // Level pack complete achievements & pack unlocks

            if scene.deathsPerPack == 0 && scene.totalStatsArray[0].achievementsUnlockedArray[54] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[54] = true
                scene.totalStatsArray[0].achievementDates[54] = Date()
                let achievement = GKAchievement(identifier: "noBallsLostPack")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting noBallsLostPack achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenBallsLostPack achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting allPackPowerUps achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting noPackPowerUps achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting quickPackComplete achievement", privacy: .public)")
                    }
                }
            }
            // Pack speed achievement
            
            if Progression.unlocksCityPack(packBestTimes: scene.totalStatsArray[0].packBestTimes) {
                scene.totalStatsArray[0].levelPackUnlockedArray[Progression.cityPackIndex] = true
            }
                        
            if scene.totalStatsArray[0].packHighScores[scene.packNumber-2] > 0 && scene.totalStatsArray[0].achievementsUnlockedArray[62] == false {
                scene.totalStatsArray[0].achievementsUnlockedArray[62] = true
                scene.totalStatsArray[0].achievementDates[62] = Date()
                let achievement = GKAchievement(identifier: "onePacksComplete")
                if achievement.isCompleted == false {
                    achievement.showsCompletionBanner = true
                    GKAchievement.report([achievement]) { (error) in
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting onePacksComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenPacksComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting hundredPacksComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting thousandPacksComplete achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessFiveK achievement", privacy: .public)")
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
                        Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessTenK achievement", privacy: .public)")
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
        case is GameOver.Type:
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    public static let continueToNextLevel = Notification.Name(rawValue: "continueToNextLevel")
    public static let levelIntroDidClear = Notification.Name(rawValue: "levelIntroDidClear")
    /// The scene now has a level in it and is worth looking at.
    public static let levelDidBuild = Notification.Name(rawValue: "levelDidBuild")
}
// Notification setup for sending information from the end level popup to load the next level

extension Notification.Name {
    public static let restart = Notification.Name(rawValue: "restart")
}
// Notification setup for sending information from the end level game over popup to restart
