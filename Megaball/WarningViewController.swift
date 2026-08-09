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
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var firstPause: Bool = true
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
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        NotificationCenter.default.post(name: .returnNotificiation, object: nil)
    }
    @IBAction func okButton(_ sender: Any) {
        if hapticsSetting {
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
            defaults.set(firstPause, forKey: "firstPause")
            CloudKitHandler().saveToiCloud()
            if hapticsSetting {
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
        if parallaxSetting {
            addParallaxToView()
        }
        updateLabels()
        wearTheGameDress()
        showAnimate()
    }

    /// Dresses the storyboard's warning sheet as a `GigaBallAlert`.
    ///
    /// The play test asked for one pop-up style across the app (round 16), and this screen
    /// was the other one: a pale grey card with pink and blue system buttons. Restyled here
    /// rather than replaced, because everything it does - resetting the ball, resetting the
    /// data, quitting to the menu - hangs off storyboard actions and notifications that
    /// work. What it looks like is the only thing that was wrong with it.
    private func wearTheGameDress() {
        warningView.backgroundColor = UIColor(white: 1, alpha: 0.08)
        warningView.layer.cornerRadius = 20
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor

        warningTitleLabel.font = .systemFont(ofSize: 22, weight: .black)
        warningTitleLabel.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        warningTitleLabel.applyGigaBallGlow(radius: 10, opacity: 0.35)

        warningTextLabel.font = .systemFont(ofSize: 15)
        warningTextLabel.textColor = UIColor(white: 1, alpha: 0.8)

        let ink = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        for button in [leftButton, centerButton] {
            button?.setTitleColor(ink, for: .normal)
            button?.backgroundColor = UIColor(white: 0.92, alpha: 1)
            button?.titleLabel?.font = .boldSystemFont(ofSize: 17)
        }
        rightButton.setTitleColor(ink, for: .normal)
        rightButton.backgroundColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        rightButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        // Green does the thing, pale steps back - the same pairing the new alert uses, so
        // the OK on this sheet and the Play on that one read as the same button
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for button in [leftButton, centerButton, rightButton] {
            guard let button, button.isHidden == false else { continue }
            button.layer.cornerRadius = button.bounds.height/2
        }
        // Pills, worked out from the height the storyboard gives them rather than assumed -
        // the buttons on this sheet are not the same height on every device
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
        if let pauseMenu = parent as? PauseMenuViewController {
            pauseMenu.moveToMainMenu()
            return
        }
        // The quit-confirm is a child of the pause menu, whose own return carries the
        // pack number the menus need to reopen the right level list - this used to post
        // a bare copy of the same notifications, and a quit-while-paused was the one
        // path that landed on the pack list instead of the played pack's levels

        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        navigationController?.popToRootViewController(animated: true)
    }


}
