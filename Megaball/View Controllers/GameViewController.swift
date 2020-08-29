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
import GoogleMobileAds

protocol MenuViewControllerDelegate: class {
    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int)
}
// Setup the protocol to return to the main menu from GameViewController

class GameViewController: UIViewController, GameViewControllerDelegate, GADInterstitialDelegate {
    
    weak var menuViewControllerDelegate:MenuViewControllerDelegate?
    // Create the delegate property for the MenuViewController
    
    var interstitial: GADInterstitial!
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Properties to store the correct level to load and the number of levels within the selection passed from the menu
    
    let defaults = UserDefaults.standard
        
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
            view.showsFPS = false
            view.showsNodeCount = false
        }
        
        interstitial = createInterstitialAd()
    }
    
    func loadInterstitial(interstitial: GADInterstitial) {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            // Setup next ad when the current one is closed
            NotificationCenter.default.post(name: .closeAd, object: nil)
            // Load the next level if the ad didn't load up in time
        }
    }
    
    func moveToMainMenu() {
        CloudKitHandler().saveToiCloud()
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        self.view.removeFromSuperview()
    }
    // Segue to MenuViewController
    
    func showPauseMenu(levelNumber: Int, numberOfLevels: Int, score: Int, packNumber: Int, height: Int, sender: String, gameoverBool: Bool, newItemsBool: Bool, previousHighscore: Int) {
        let pauseMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pauseMenuVC") as! PauseMenuViewController
        pauseMenuVC.levelNumber = levelNumber
        pauseMenuVC.numberOfLevels = numberOfLevels
        pauseMenuVC.score = score
        pauseMenuVC.packNumber = packNumber
        pauseMenuVC.height = height
        pauseMenuVC.sender = sender
        pauseMenuVC.gameoverBool = gameoverBool
        pauseMenuVC.newItemsBool = newItemsBool
        pauseMenuVC.previousHighscore = previousHighscore
        // Update pause menu view controller properties with function input values
        self.addChild(pauseMenuVC)
        pauseMenuVC.view.frame = self.view.frame
        self.view.addSubview(pauseMenuVC.view)
        pauseMenuVC.didMove(toParent: self)
    }
    // Show PauseMenuViewController as popup
    
    func showInbetweenView(levelNumber: Int, score: Int, packNumber: Int, levelTimerBonus: Int, firstLevel: Bool, numberOfLevels: Int, levelScore: Int) {
        let inbetweenView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inbetweenView") as! InbetweenViewController
        inbetweenView.levelNumber = levelNumber
        inbetweenView.packNumber = packNumber
        inbetweenView.totalScore = score
        inbetweenView.levelScore = levelScore
        inbetweenView.levelScoreBonus = levelTimerBonus
        inbetweenView.firstLevel = firstLevel
        inbetweenView.numberOfLevels = numberOfLevels
        // Update pause menu view controller properties with function input values
        self.addChild(inbetweenView)
        inbetweenView.view.frame = self.view.frame
        self.view.addSubview(inbetweenView.view)
        inbetweenView.didMove(toParent: self)
    }
    
    func showWarning(senderID: String) {
        let warningView = self.storyboard?.instantiateViewController(withIdentifier: "warningView") as! WarningViewController
        warningView.senderID = senderID
        self.addChild(warningView)
        warningView.view.frame = self.view.frame
        self.view.addSubview(warningView.view)
        warningView.didMove(toParent: self)
    }
    
    func createInterstitial() {
        interstitial = createInterstitialAd()
    }
    
    func createInterstitialAd() -> GADInterstitial {
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3110131406973822/7277792086")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func showAd() {
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            interstitial = createInterstitialAd()
            NotificationCenter.default.post(name: .closeAd, object: nil)
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createInterstitialAd()
        NotificationCenter.default.post(name: .closeAd, object: nil)
    }

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
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    // Disable home bar on 1st swipe
}
