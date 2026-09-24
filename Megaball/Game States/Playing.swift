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
        scene.defaults.set(scene.gameInProgress, forKey: "gameInProgress")
        
        scene.userSettings()
        // Set user settings
        
        if scene.musicSetting {
            if scene.ballIsOnPaddle == false {
                MusicHandler.sharedHelper.gameVolume()
            } else {
                MusicHandler.sharedHelper.menuVolume()
            }
        }
        
        if previousState is InbetweenLevels {
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
        
        if previousState is PreGame || previousState is InbetweenLevels {
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
        scene.livesAwaitingRollIn = scene.resumeGameToLoad != true
        // Held hidden until the level intro clears and the roll-in takes over - but only
        // where an intro is actually coming. A resumed game goes straight to the pause
        // menu with no intro, so .levelIntroDidClear never arrives; holding the row there
        // would leave it empty until something else happened to show it

        let wait = SKAction.wait(forDuration: 0.35)
        self.scene.run(wait, completion: { [weak self] in
            guard let self else { return }
            self.scene.scoreLabel.isHidden = false
            self.scene.multiplierLabel.isHidden = false
            self.scene.pauseButton.isHidden = false
            self.scene.setLivesRowHidden(false)
            if self.scene.endlessMode {
                self.scene.showEndlessIIBest()
            }
            // The multiplier has no meaning in endless mode, so the label carries the best
            // height instead - and hides itself when there is not one yet
        })
        // Show game labels
        
        scene.setMultiplierColour(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        
        scene.refreshLivesRow()
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
        
        if scene.resumeGameToLoad == true, let saved = scene.savedGame {
            scene.levelScore = saved.levelScore
            scene.totalScore = saved.totalScore
            scene.numberOfLives = saved.numberOfLives
            scene.multiplier = saved.multiplier
        }
        // The flag and the save are separate, so a save that fails to decode leaves the
        // flag set with nothing behind it
        // If resuming a game, reset counters and scores to saved values
        //
        // **`totalScore` is corrected further down, and it has to be.** A save writes its
        // `totalScore` as `totalScore + levelScore`, because a level in progress has not
        // banked yet and the resuming screen has to be able to show a number. Assigning both
        // straight back therefore puts the level's running score inside `totalScore` *and* in
        // `levelScore`, and everything that draws the score adds the two together - so the
        // scene would read high by a level's worth until the level ended, and then bank it
        // twice. `scene.totalScore = scene.totalScore - scene.levelScore` in the
        // `resumeGameToLoad` branch below is what takes it back out.
        //
        // Said here because that line is thirty lines away, inside a branch otherwise about
        // whether the ball animates in, under a comment of four words. Round 319f read this
        // assignment, worked out what it implied, and went looking for a scoring bug that is
        // not there. The next person should not have to.
        
        scene.scoreLabel.text = String(scene.totalScore)
        scene.scoreFactorString = String(format:"%.1f", scene.multiplier)
        scene.showMultiplier()
        scene.refreshLivesRow()
        // Update number of lives label

        scene.ball.removeAllActions()
        scene.paddle.removeAllActions()
        scene.paddleRetroTexture.removeAllActions()
        scene.ballIsOnPaddle = true
        scene.ballRelativePositionOnPaddle = 0
        // **Every level starts with the ball in the middle of the paddle** (James, round 323,
        // with a screenshot: "at the start of levels, the ball was sometimes off centre from
        // the paddle"). The ball and paddle were both put at zero here, but the offset the
        // waiting ball is held at was left as the last level ended it - a level cleared with
        // the ball caught off-centre on a sticky paddle - and `holdTheWaitingBallStill` pins the
        // ball to paddle plus offset every frame, so it was back off-centre before it was drawn
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

        if scene.resumeGameToLoad == false {
            let startingScale = SKAction.scale(to: 0.8, duration: 0)
            let startingScalePaddle = SKAction.scaleX(to: 0.0, duration: 0)
            let startingFade = SKAction.fadeOut(withDuration: 0)
            let scaleUp = scene.settleBallToItsSize(duration: 0.2)
            let scaleUpPaddle = scene.settlePaddleToItsSize(duration: 0.2)
            // To the size each is meant to be when the animation gets there, not to 1 (James,
            // round 341: an Always On Shrink Ball lit its tray bar and left the ball full size).
            // The twist collects its power-up as play begins, which is inside this animation,
            // and a size written down before that happened was the size that won
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
            scene.ball.run(animationSequence, completion: { [weak self] in
                guard let self else { return }
                self.scene.ballStartingPositionY = self.scene.ball.position.y
                // Resets the ball's starting position incase it is moved during the animation in
            })
            scene.paddle.run(startingGroupPaddle)
            scene.paddle.isHidden = false
            scene.paddle.run(animationSequencePaddle, completion: { [weak self] in
                guard let self else { return }
                self.scene.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            })
            
            if scene.paddleTexture == scene.retroPaddle {
                scene.paddleRetroTexture.run(startingGroupPaddle)
                scene.paddleRetroTexture.isHidden = false
                scene.paddleRetroTexture.run(animationSequencePaddle)
            }
            // Animate paddle and ball in
        // Don't animate if resuming from save
        } else if scene.resumeGameToLoad {
            scene.ball.isHidden = false
            scene.paddle.isHidden = false
            if scene.paddleTexture == scene.retroPaddle {
                scene.paddleRetroTexture.isHidden = false
            }
            scene.totalScore = scene.totalScore - scene.levelScore
            // The correction the restore above depends on: a save's `totalScore` already
            // includes `levelScore`, and both were just assigned, so this takes the overlap
            // back out. Moving or removing it double-counts the level in progress, silently
            
            if (scene.savedGame?.ballProperties.isEmpty == false) {
                scene.pauseBallVelocityX = CGFloat(scene.savedGame?.ballProperties[2] ?? 0)
                scene.pauseBallVelocityY = CGFloat(scene.savedGame?.ballProperties[3] ?? 0)
                            
                if sqrt(scene.pauseBallVelocityX*scene.pauseBallVelocityX) + sqrt(scene.pauseBallVelocityY*scene.pauseBallVelocityY) == 0 {
                    scene.ballLaunchAngleRad = scene.straightLaunchAngleRad + scene.minLaunchAngleRad
                    scene.pauseBallVelocityX = cos(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
                    scene.pauseBallVelocityY = sin(CGFloat(scene.ballLaunchAngleRad)) * CGFloat(scene.ballSpeedLimit)
                }
                // If ball velocity is zero, but shouldn't be, set a default launch speed when resuming
            }
        }
        // Reset total score to reflect pre-save value
            
        if scene.savedGame?.resumesBetweenLevels == true {
            if let bonus = scene.savedGame?.levelTimerBonus {
                scene.levelTimerBonus = bonus
            }
            scene.savedGame = nil
            scene.clearSavedGame()
            scene.levelNumber -= 1
            scene.resumingBetweenLevels = true
            scene.gameState.enter(InbetweenLevels.self)
            return
            // **Back to the level whose screen this is, and marked as a resume** (round 322b,
            // found by `ResumeTransitionTests`). The save's level is the one the screen leads
            // to, and the scene was launched at it - so the screen said the wrong level, and
            // Continue, which moves the level on by one, skipped the level the player was
            // about to play. And `InbetweenLevels` ran its whole ending again from a resume:
            // the finished level was counted a second time, played and completed, with its
            // unlock and its best score written against the level after it. The flag is how
            // that state tells a level ending from a player coming back to one that already
            // ended
            // The player quit looking at the between-levels screen, so that is where the run
            // comes back (play-test round 40). The level number in the save has already been
            // advanced to the level this screen leads to, so the screen and the level that
            // follows it are both the ones they left - and starting it is theirs to do again.
            //
            // The save is cleared here rather than kept, for the reason the anti-cheat work
            // established: a run that has been resumed must not be resumable a second time
            // from the same moment
        }

        if (scene.savedGame?.brickXPositions.isEmpty == false) {
            scene.resumeBrickCreation()
            // Load saved level
            NotificationCenter.default.post(name: .levelDidBuild, object: nil)
        } else {
            scene.levelTimerBonus = 500
            scene.levelTimerValue = 0
            scene.powerUpsCollectedPerLevel = 0
            scene.powerUpsGeneratedPerLevel = 0
            scene.paddleHitsPerLevel = 0
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
            self.scene.run(wait, completion: { [weak self] in
                guard let self else { return }
            // Add slight delay for loading first level to allow blur view to cover brick build animation properly
                
                self.scene.loadLevel(self.scene.levelNumber)
                // Load level in
                NotificationCenter.default.post(name: .levelDidBuild, object: nil)
            })
        }
    }
    
    override func willExit(to nextState: GKState) {
        scene.gameInProgress = false
        scene.defaults.set(scene.gameInProgress, forKey: "gameInProgress")
    }
    
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

