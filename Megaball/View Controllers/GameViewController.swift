//
//  GameViewController.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController, GameViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                
                let gameScene = scene as! GameScene
                gameScene.gameViewControllerDelegate = self
                // Set the GameViewController as the delegate for the gameViewControllerDelegate in GameScene
                
                scene.scaleMode = .aspectFill
                scene.size = view.bounds.size
                // Scales the size of the GameView to the size of the device
                // Present the scene
                view.presentScene(scene)
            }
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: false)
    }
    // Segue to MenuViewController
    
    func showEndLevelStats(levelNumber: Int, levelScore: Int, levelTime: Double, cumulativeScore: Int, cumulativeTime: Double, levelHighscore: Int, levelBestTime: Double, bestScoreToLevel: Int, bestTimeToLevel: Double, cumulativeHighscore: Int, gameoverStatus: Bool) {
        let popoverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inbetweenLevelsVC") as! InbewteenLevelsViewController
        popoverVC.levelNumber = levelNumber
        popoverVC.levelScore = levelScore
        popoverVC.levelTime = levelTime
        popoverVC.cumulativeScore = cumulativeScore
        popoverVC.cumulativeTime = cumulativeTime
        popoverVC.levelHighscore = levelHighscore
        popoverVC.levelBestTime = levelBestTime
        popoverVC.bestScoreToLevel = bestScoreToLevel
        popoverVC.bestTimeToLevel = bestTimeToLevel
        popoverVC.cumulativeHighscore = cumulativeHighscore
        popoverVC.gameoverStatus = gameoverStatus
        // Update popup view controller properties with function input values

        self.addChild(popoverVC)
        popoverVC.view.frame = self.view.frame
        self.view.addSubview(popoverVC.view)
        popoverVC.didMove(toParent: self)
    }
    // Show InbetweenLevelsViewController as popup

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
