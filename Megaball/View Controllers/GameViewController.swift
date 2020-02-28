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
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Properties to store the correct level to load and the number of levels within the selection passed from the menu
    
    let defaults = UserDefaults.standard
    
    var interstitial: GADInterstitial!
    // Define interstitial ad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.saveGameProgressNotificationKeyNotificationReceived), name: .saveGameProgressNotificationKey, object: nil)
//        // Setup notification to check if the app has been quit
        
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
    
//    @objc func saveGameProgressNotificationKeyNotificationReceived() {
//    // Save Scene
//        do {
//            let sceneData = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
//            UserDefaults.standard.set(sceneData, forKey: "currentScene")
//        }
//        catch {
//            print("Error saving game data on app quit, \(error)")
//        }
//    }
    
    func createInterstitial() {
        print("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        interstitial.delegate = self
        interstitial.load(GADRequest())
    }
    
    func loadInterstitial() {
        if self.interstitial.isReady {
            self.interstitial.present(fromRootViewController: self)
        } else {
            createInterstitial()
            // Setup next ad when the current one is closed
            NotificationCenter.default.post(name: .closeAd, object: nil)
            // Load the next level if the ad didn't load up in time
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        createInterstitial()
        // Setup next ad when the current one is closed
        NotificationCenter.default.post(name: .closeAd, object: nil)
        // Send notification to move to Playing game state
    }
    
    func moveToMainMenu() {
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelSelectNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        navigationController?.popToRootViewController(animated: true)
    }
    // Segue to MenuViewController
    
    func showEndLevelStats(levelNumber: Int, score: Int, gameoverStatus: Bool, startLevel: Int, numberOfLevels: Int, scoresArray: [Int], depth: Int, depthArray: [Int]) {
        let endLevelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inbetweenLevelsVC") as! EndGameViewController
        endLevelVC.levelNumber = levelNumber
        endLevelVC.score = score
        endLevelVC.gameoverStatus = gameoverStatus
        endLevelVC.startLevel = selectedLevel!
        endLevelVC.numberOfLevels = numberOfLevels
        endLevelVC.scoresArray = scoresArray
        endLevelVC.depth = depth
        endLevelVC.depthArray = depthArray
        // Update popup view controller properties with function input values

        self.addChild(endLevelVC)
        endLevelVC.view.frame = self.view.frame
        self.view.addSubview(endLevelVC.view)
        endLevelVC.didMove(toParent: self)
    }
    // Show InbetweenLevelsViewController as popup
    
    func showPauseMenu(levelNumber: Int, score: Int, highScore: Int, packNumber: Int, depth: Int, depthBest: Int) {
        let pauseMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pauseMenuVC") as! PauseMenuViewController
        pauseMenuVC.levelNumber = levelNumber
        pauseMenuVC.score = score
        pauseMenuVC.highScore = highScore
        pauseMenuVC.packNumber = packNumber
        pauseMenuVC.depth = depth
        pauseMenuVC.depthBest = depthBest
        // Update pause menu view controller properties with function input values

        self.addChild(pauseMenuVC)
        pauseMenuVC.view.frame = self.view.frame
        self.view.addSubview(pauseMenuVC.view)
        pauseMenuVC.didMove(toParent: self)
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

//extension Notification.Name {
//    public static let saveGameProgressNotificationKey = Notification.Name(rawValue: "saveGameProgressNotificationKey")
//}
//// Setup for notifcations from AppDelegate
