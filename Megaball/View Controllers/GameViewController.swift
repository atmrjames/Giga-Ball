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

protocol MenuViewControllerDelegate: class {
    func moveToGame(selectedLevel: Int)
}
// Setup the protocol to return to the main menu from GameViewController

class GameViewController: UIViewController, GameViewControllerDelegate {
    
    weak var menuViewControllerDelegate:MenuViewControllerDelegate?
    // Create the delegate property for the MenuViewController
    
    var selectedLevel: Int?
    // Property to store the correct level to load
    
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
//            view.showsNodeCount = true
        }
    }
    
    func moveToMainMenu(currentHighscore: Int) {
        let mainMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "menuView") as! MenuViewController
        mainMenuVC.currentHighscore = currentHighscore
        navigationController?.popToRootViewController(animated: true)
    }
    // Segue to MenuViewController
    
    func showEndLevelStats(levelNumber: Int, levelScore: Int, levelHighscore: Int, totalScore: Int, totalHighscore: Int, gameoverStatus: Bool) {
        let popoverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inbetweenLevelsVC") as! InbewteenLevelsViewController
        popoverVC.levelNumber = levelNumber
        popoverVC.levelScore = levelScore
        popoverVC.levelHighscore = levelHighscore
        popoverVC.totalScore = totalScore
        popoverVC.totalHighscore = totalHighscore
        popoverVC.gameoverStatus = gameoverStatus
        // Update popup view controller properties with function input values

        self.addChild(popoverVC)
        popoverVC.view.frame = self.view.frame
        self.view.addSubview(popoverVC.view)
        popoverVC.didMove(toParent: self)
    }
    // Show InbetweenLevelsViewController as popup
    
    func showPauseMenu(levelNumber: Int, score: Int, highscore: Int) {
        let popoverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pauseMenuVC") as! PauseMenuViewController
        popoverVC.levelNumber = levelNumber
        popoverVC.score = score
        popoverVC.highscore = highscore
        
        // Update pause menu view controller properties with function input values

        self.addChild(popoverVC)
        popoverVC.view.frame = self.view.frame
        self.view.addSubview(popoverVC.view)
        popoverVC.didMove(toParent: self)
    }
    // Show PauseMenuViewController as popup

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
    
//    override func viewDidLayoutSubviews() {
//        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
//    }
//    // Setup controlling home bar status on other view controllers
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    // Disable home bar on 1st swipe
    
//    override var childForScreenEdgesDeferringSystemGestures: UIViewController? {
//        return children.first { type(of: $0) == PauseMenuViewController.self }
//    }
//    // Allow re-enabling of home bar on 1st swipe in child view controllers
    
}
