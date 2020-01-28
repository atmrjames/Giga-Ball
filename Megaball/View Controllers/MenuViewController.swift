//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MenuViewController: UIViewController, MenuViewControllerDelegate {

    var currentHighscore: Int = 0
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    let defaults = UserDefaults.standard
    
    
    
    


    @IBAction func playButtonPressed(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToGame(selectedLevel: 1)
    }
    
    @IBAction func tutorialButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
    }
    
    @IBAction func selectLevelButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        moveToLevelSelector()
    }
    
    @IBAction func settingsButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
//        moveToSettings()
    }
    
    @IBAction func adSwitch(_ sender: Any) {
        
        var showAds = defaults.bool(forKey: "ShowAds")
        // Load show ads status
        
        if showAds {
            showAds = false
            print(showAds)
        } else {
            showAds = true
            print(showAds)
        }
        // Change show ads status
        
        defaults.set(showAds, forKey: "ShowAds")
        // Save show ads status
    }
    
    @IBOutlet var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        defaults.set(true, forKey: "ShowAds")
    }

    override func viewWillAppear(_ animated: Bool) {
        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        // Configure banner ad
        
        bannerView.load(GADRequest())
        // Load banner ad
    }

    func moveToGame(selectedLevel: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self
        gameView.selectedLevel = selectedLevel
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController
    
    func moveToLevelSelector() {
        let levelSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "levelSelectorView") as! LevelSelectorViewController
        self.navigationController?.pushViewController(levelSelectorView, animated: true)
    }
    // Segue to LevelSelectorViewController
    
    func moveToSettings() {
        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        self.navigationController?.pushViewController(settingsView, animated: true)
    }
    // Segue to LevelSelectorViewController

}
