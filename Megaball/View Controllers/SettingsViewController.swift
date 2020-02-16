//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var navigatedFrom: String?
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    // User settings
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBOutlet var backgroundViewLeading: NSLayoutConstraint!
    @IBOutlet var backgroundViewTop: NSLayoutConstraint!
    
    @IBAction func backButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        if navigatedFrom! == "PauseMenu" {
            NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
        } else if navigatedFrom! == "MainMenu" {
            NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        }
    }
    
    @IBAction func settingsTitleButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        settingsTableView.setContentOffset(.zero, animated: true)
    }
    // UIViewController actions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        settingsTableView.separatorStyle = .none
        settingsTableView.rowHeight = 70.0
        // TableView setup
        
        if view.frame.size.width > 700 {
            ipadCompatibility()
        }
        
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load show ads status

        if parallaxSetting! {
            addParallaxToView()
        }
        if navigatedFrom! == "MainMenu" {
            setBlur()
        }
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if navigatedFrom! == "PauseMenu" {
            return 7
        } else {
            return 8
        }
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        switch indexPath.row {
        case 0:
        // Ads
            cell.settingDescription.text = "Ads"
            cell.centreLabel.text = ""
            if adsSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1411764706, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 1:
        // Sounds
            cell.settingDescription.text = "Sounds"
            cell.centreLabel.text = ""
            if soundsSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1411764706, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red:0.12, green:0.13, blue:0.14, alpha:1.0)
            }
            cell.settingDescription.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            
        case 2:
        // Music
            cell.settingDescription.text = "Music"
            cell.centreLabel.text = ""
            if musicSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1411764706, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 3:
        // Haptics
            cell.settingDescription.text = "Haptics"
            cell.centreLabel.text = ""
            if hapticsSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1411764706, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 4:
        // Parallax
            cell.settingDescription.text = "Parallax"
            cell.centreLabel.text = ""
            if parallaxSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1215686275, green: 0.1294117647, blue: 0.1411764706, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 5:
        // Paddle sensitivity
            cell.settingDescription.text = "Paddle Sensitivity"
            cell.centreLabel.text = ""
            if paddleSensitivitySetting == 0 {
                cell.settingState.text = "low"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            } else if paddleSensitivitySetting == 1 {
                cell.settingState.text = "medium"
                cell.settingState.textColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
            } else if paddleSensitivitySetting == 2 {
                cell.settingState.text = "high"
                cell.settingState.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            } else if paddleSensitivitySetting == 3 {
                cell.settingState.text = "extreme"
                cell.settingState.textColor = #colorLiteral(red:0.12, green:0.13, blue:0.14, alpha:1.0)
            } else if paddleSensitivitySetting == 4 {
                cell.settingState.text = "mega"
                cell.settingState.textColor = #colorLiteral(red: 0.4392156899, green: 0.01176470611, blue: 0.1921568662, alpha: 1)
            }

        case 6:
        // Reset game data or kill ball
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Reset Game Data"
            cell.settingState.text = ""
            if navigatedFrom! == "PauseMenu" {
                cell.centreLabel.text = "Reset Ball"
                cell.centreLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
            } else {
                cell.centreLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                
            }
        case 7:
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
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView.transform = .identity
            cell.settingDescription.transform = .identity
            cell.settingState.transform = .identity
            cell.centreLabel.transform = .identity
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
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
            if parallaxSetting! {
                addParallaxToView()
            } else if parallaxSetting! == false {
                backgroundView.removeMotionEffect(group!)
            }
        case 5:
        // Paddle sensitivity
            paddleSensitivitySetting = paddleSensitivitySetting!+1
            if paddleSensitivitySetting! > 4 {
                paddleSensitivitySetting = 0
            }
            defaults.set(paddleSensitivitySetting!, forKey: "paddleSensitivitySetting")
        case 6:
        // Reset game data or kill ball
            if navigatedFrom! == "PauseMenu" {
                removeAnimate()
                NotificationCenter.default.post(name: .killBallRemoveVC, object: nil)
            } else {
                print("Reset game data")
            }
        case 7:
        // Restore purchases
            print("Restore purchases")
        default:
            print("out of range")
            break
        }
        
        UIView.animate(withDuration: 0.2) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView.transform = .init(scaleX: 0.99, y: 0.99)
            cell.settingState.transform = .init(scaleX: 0.95, y: 0.95)
            cell.centreLabel.transform = .init(scaleX: 0.95, y: 0.95)
            cell.cellView.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView.transform = .identity
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
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

    func addParallaxToView() {
        let amount = 25
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundView.addMotionEffect(group!)
    }
    
    func setBlur() {
        settingsView.backgroundColor = .clear
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .dark)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .regular, and .prominent.
        blurView = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: settingsView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: settingsView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: settingsView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: settingsView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func ipadCompatibility() {
        
        backgroundViewLeading.isActive = false
        backgroundViewTop.isActive = false
        backgroundView.frame.size.height = 896
        backgroundView.frame.size.width = 414
        
    }
    
}
