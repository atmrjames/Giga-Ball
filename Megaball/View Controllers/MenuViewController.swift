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
    
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleControlSetting: Bool?
    var paddleSensitivitySetting: Int?
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToGame(selectedLevel: 1)
    }
    
    @IBAction func tutorialButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
    }
    
    @IBAction func selectLevelButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToLevelSelector()
    }
    
    @IBAction func settingsButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToSettings()
    }
    
    @IBOutlet var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        defaultSettings()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        
        if defaults.bool(forKey: "adsSetting") {
            bannerView.isHidden = false
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            bannerView.rootViewController = self
            // Configure banner ad
            
            bannerView.load(GADRequest())
            // Load banner ad
        } else {
            bannerView.isHidden = true
        }
        // Show or hide banner ad depending on setting
    }
    
    func defaultSettings() {
        defaults.register(defaults: ["adsSetting" : true])
        defaults.register(defaults: ["soundsSetting" : true])
        defaults.register(defaults: ["musicSetting" : true])
        defaults.register(defaults: ["hapticsSetting" : true])
        defaults.register(defaults: ["parallaxSetting" : true])
        defaults.register(defaults: ["paddleControlSetting" : true])
        defaults.register(defaults: ["paddleSensitivitySetting" : 1])
    }
    // Set default settings

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
        settingsView.navigatedFrom = "MainMenu"
        self.navigationController?.pushViewController(settingsView, animated: true)
    }
    // Segue to LevelSelectorViewController

}
