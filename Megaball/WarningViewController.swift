//
//  WarningViewController.swift
//  Megaball
//
//  Created by James Harding on 18/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class WarningViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var firstPause: Bool?
    // User settings
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    var senderID: String = ""
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var warningView: UIView!
    @IBOutlet var warningTitleLabel: UILabel!
    @IBOutlet var warningTextLabel: UILabel!
    @IBOutlet var centerButton: UIButton!
    @IBOutlet var rightButton: UIButton!
    @IBOutlet var leftButton: UIButton!
    
    @IBAction func cancelButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        NotificationCenter.default.post(name: .returnNotificiation, object: nil)
    }
    @IBAction func okButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if senderID == "killBall" {
            removeAnimate()
            NotificationCenter.default.post(name: .killBallRemoveVC, object: nil)
        }
        if senderID == "resetData" {
            removeAnimate()
            NotificationCenter.default.post(name: .resetNotificiation, object: nil)
        }
        if senderID == "pauseMenu" {
            MenuViewController().clearSavedGame()
            moveToMainMenu()
        }
    }
    @IBAction func centerButton(_ sender: Any) {
        if senderID == "firstPause" {
            firstPause = false
            defaults.set(firstPause!, forKey: "firstPause")
            CloudKitHandler().saveUserDefaults()
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            removeAnimate()
            NotificationCenter.default.post(name: .returnNotificiation, object: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallaxToView()
        }
        updateLabels()
        showAnimate()
    }
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.33)
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .dark)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .regular, and .prominent.
        blurView = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        view.insertSubview(blurView!, at: 0)
        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: backgroundView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func addParallaxToView() {
        var amount = 25
        if view.frame.width > 450 {
            amount = 50
            // iPad
        }
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            warningView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying
        
        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        warningView.addMotionEffect(group!)
    }
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        firstPause = defaults.bool(forKey: "firstPause")
        // Load user settings
    }
    
    func updateLabels() {
        centerButton.isHidden = true
        leftButton.isHidden = false
        rightButton.isHidden = false
        if senderID == "killBall" {
            warningTitleLabel.text = "R E S E T   B A L L"
            warningTextLabel.text = "Only reset if the ball becomes stuck."
        }
        if senderID == "resetData" {
            warningTitleLabel.text = "R E S E T   D A T A"
            warningTextLabel.text = "Are you sure you want to reset the game data? You will irreversibly lose all game progress, statistics and settings.\nIn-app purchases will remain."
        }
        if senderID == "pauseMenu" {
            warningTitleLabel.text = "M A I N   M E N U"
            warningTextLabel.text = "Are you sure?\nCurrent progress will be lost."
        }
        if senderID == "firstPause" {
            centerButton.isHidden = false
            leftButton.isHidden = true
            rightButton.isHidden = true
            warningTitleLabel.text = "S W I P E   U P"
            warningTextLabel.text = "Swipe up anywhere to pause.\nDisable in Settings."
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
    
    func moveToMainMenu() {
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        navigationController?.popToRootViewController(animated: true)
    }


}
