//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let defaults = UserDefaults.standard
    
    var navigatedFrom: String?
    
    @IBOutlet var settingsView: UIView!
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleControlSetting: Bool?
    var paddleSensitivitySetting: Int?
    
    var levelNumber: Int = 0
    var score: Int = 0
    var highscore: Int = 0
    // Properties to store passed over data
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var group: UIMotionEffectGroup?
    
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBAction func backButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        if navigatedFrom! == "PauseMenu" {
            removeAnimate()
            NotificationCenter.default.post(name: .returnNotification, object: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBOutlet var viewObject: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        // Setup swipe gesture to return to main menu
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        // Setup table view delegates
        
        settingsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        settingsTableView.separatorStyle = .none
        // Setup custom cell
        
        settingsTableView.rowHeight = 70.0
        
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleControlSetting = defaults.bool(forKey: "paddleControlSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load show ads status
        
        if navigatedFrom! == "PauseMenu" {
        // Custom setup for settings screen
            showAnimate()
            settingsView.backgroundColor? = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            settingsTableView.backgroundColor? = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            if parallaxSetting! {
                addParallaxToView(vw: settingsView)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if navigatedFrom! == "PauseMenu" {
            return 8
        } else {
            return 9
        }
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        if navigatedFrom! == "PauseMenu" {
            cell.viewBackground.backgroundColor? = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            cell.layer.backgroundColor = UIColor.clear.cgColor
        }
        
        switch indexPath.row {
        case 0:
        // Ads
            cell.settingDescription.text = "Ads"
            cell.centreLabel.text = ""
            if adsSetting! {
                cell.settingState.text = "on"
            } else {
                cell.settingState.text = "off"
            }
        case 1:
        // Sounds
            cell.settingDescription.text = "Sounds"
            cell.centreLabel.text = ""
            if soundsSetting! {
                cell.settingState.text = "on"
            } else {
                cell.settingState.text = "off"
            }
            cell.settingDescription.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        case 2:
        // Music
            cell.settingDescription.text = "Music"
            cell.centreLabel.text = ""
            if musicSetting! {
                cell.settingState.text = "on"
            } else {
                cell.settingState.text = "off"
            }
        case 3:
        // Haptics
            cell.settingDescription.text = "Haptics"
            cell.centreLabel.text = ""
            if hapticsSetting! {
                cell.settingState.text = "on"
            } else {
                cell.settingState.text = "off"
            }
        case 4:
        // Parallax
            cell.settingDescription.text = "Parallax"
            cell.centreLabel.text = ""
            if parallaxSetting! {
                cell.settingState.text = "on"
            } else {
                cell.settingState.text = "off"
            }
        case 5:
        // Paddle control
            cell.settingDescription.text = "Paddle Control"
            cell.centreLabel.text = ""
            if paddleControlSetting! {
                cell.settingState.text = "touch"
            } else {
                cell.settingState.text = "tilt"
            }
        case 6:
        // Paddle sensitivity
            cell.settingDescription.text = "Paddle Sensitivity"
            cell.centreLabel.text = ""
            if paddleSensitivitySetting == 0 {
                cell.settingState.text = "high"
            } else if paddleSensitivitySetting == 1 {
                cell.settingState.text = "medium"
            } else if paddleSensitivitySetting == 2 {
                cell.settingState.text = "low"
            }
        case 7:
        // Reset game data or kill ball
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Reset Game Data"
            cell.settingState.text = ""
            if navigatedFrom! == "PauseMenu" {
                cell.centreLabel.text = "Reset Ball"
            } else {
                cell.centreLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                
            }
        case 8:
        // Restore purchases
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Restore Purchases"
            cell.settingState.text = ""
            cell.centreLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        default:
            print("Error: Out of range")
            break
        }
        tableView.showsVerticalScrollIndicator = false
        return cell
    }
    // Add content to cells
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
        // Ads
            adsSetting = !adsSetting!
            defaults.set(adsSetting!, forKey: "adsSetting")
        case 1:
        // Sounds
            soundsSetting = !soundsSetting!
            defaults.set(soundsSetting!, forKey: "soundsSetting")
        case 2:
        // Music
            musicSetting = !musicSetting!
            defaults.set(musicSetting!, forKey: "musicSetting")
        case 3:
        // Haptics
            hapticsSetting = !hapticsSetting!
            defaults.set(hapticsSetting!, forKey: "hapticsSetting")
        case 4:
        // Parallax
            parallaxSetting = !parallaxSetting!
            defaults.set(parallaxSetting!, forKey: "parallaxSetting")
            if parallaxSetting! && navigatedFrom! == "PauseMenu" {
                addParallaxToView(vw: settingsView)
            } else if parallaxSetting! == false && navigatedFrom! == "PauseMenu" {
                settingsView.removeMotionEffect(group!)
            }
        case 5:
        // Paddle control
            paddleControlSetting = !paddleControlSetting!
            defaults.set(paddleControlSetting!, forKey: "paddleControlSetting")
        case 6:
        // Paddle sensitivity
            paddleSensitivitySetting = paddleSensitivitySetting!+1
            if paddleSensitivitySetting! > 2 {
                paddleSensitivitySetting = 0
            }
            defaults.set(paddleSensitivitySetting!, forKey: "paddleSensitivitySetting")
        case 7:
        // Reset game data or kill ball
            if navigatedFrom! == "PauseMenu" {
                removeAnimate()
                NotificationCenter.default.post(name: .killBallRemoveVC, object: nil)
            } else {
                print("Reset game data")
            }
        case 8:
        // Restore purchases
            print("Restore purchases")
        default:
            print("out of range")
            break
        }
        
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        }
    }
    
    func showPauseMenu() {
        let pauseMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pauseMenuVC") as! PauseMenuViewController
        pauseMenuVC.levelNumber = levelNumber
        pauseMenuVC.score = score
        pauseMenuVC.highscore = highscore
        // Update pause menu view controller properties with function input values

        self.addChild(pauseMenuVC)
        pauseMenuVC.view.frame = self.view.frame
        self.view.addSubview(pauseMenuVC.view)
        pauseMenuVC.didMove(toParent: self)
    }
    // Show PauseMenuViewController as popup
    
    func addParallaxToView(vw: UIView) {
        let amount = 25
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group!)
    }
    
    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if navigatedFrom! == "PauseMenu" {
            return
        } else {
            if hapticsSetting! {
                mediumHaptic.impactOccurred()
            }
            navigationController?.popViewController(animated: true)
        }
    }
    // Setup swipe gesture to return to main menu
    
}
