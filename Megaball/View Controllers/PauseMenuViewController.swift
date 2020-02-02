//
//  PauseMenuViewController.swift
//  Megaball
//
//  Created by James Harding on 17/10/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class PauseMenuViewController: UIViewController {
    
    var levelNumber: Int = 0
    var score: Int = 0
    var highscore: Int = 0
    // Properties to store passed over data
    
    let defaults = UserDefaults.standard
    
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleControlSetting: Bool?
    var paddleSensitivitySetting: Int?
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var group: UIMotionEffectGroup?

    @IBOutlet weak var pauseView: UIView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    
    @IBAction func returnToMainMenuButton(_ sender: UIButton) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToMainMenu()
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {        
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        removeAnimate(nextAction: .unpause)
    }
    
    @IBAction func settingsButton(_ sender: UIButton) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        hideAnimate()
        moveToSettings()
    }
    
    var blurView: UIVisualEffectView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnNotificationKeyReceived), name: .returnNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned to the pause menu from the settings menu
        NotificationCenter.default.addObserver(self, selector: #selector(self.killBallRemoveVCKeyReceived), name: .killBallRemoveVC, object: nil)
        // Sets up an observer to watch for notifications to check if the user has killed the ball from the settings menu to then remove the pause menu
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        // Setup swipe gesture
        userSettings()
        setBlur()
        showAnimate()
        updateLabels()
    }
    
    func setBlur() {
        pauseView.backgroundColor = .clear
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .extraLight)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .extraDark, .regular, and .prominent.
        blurView = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: pauseView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: pauseView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: pauseView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: pauseView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: pauseView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: pauseView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
        
        if parallaxSetting! {
            addParallaxToView(vw: pauseView, ve: blurView!)
        }
    }
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleControlSetting = defaults.bool(forKey: "paddleControlSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    func updateLabels() {
        levelNumberLabel.text = "Level \(levelNumber)"
        scoreLabel.text = String(score)
        if highscore <= 1 {
            highscore = 0
        }
        highscoreLabel.text = String(highscore)
    }
    
    func removeAnimate(nextAction: Notification.Name) {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
                NotificationCenter.default.post(name: nextAction, object: nil)
                // Send notification to unpause the game
            }
        }
    }
    
    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.pauseView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.pauseView.alpha = 0.0
            self.blurView!.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.blurView!.alpha = 0.0})
    }
    
    func revealAnimate() {
        self.pauseView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.pauseView.alpha = 0.0
        self.blurView!.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.blurView!.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.pauseView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.pauseView.alpha = 1.0
            self.blurView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.blurView!.alpha = 1.0})
    }
    
    func addParallaxToView(vw: UIView, ve: UIVisualEffectView) {
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
        ve.addMotionEffect(group!)
    }
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func moveToSettings() {
        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsView.navigatedFrom = "PauseMenu"
        settingsView.levelNumber = levelNumber
        settingsView.score = score
        settingsView.highscore = highscore
        self.addChild(settingsView)
        settingsView.view.frame = self.view.frame
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
    }
    
    @objc func returnNotificationKeyReceived(_ notification: Notification) {
        revealAnimate()
        userSettings()
        if group != nil {
            pauseView.removeMotionEffect(group!)
            blurView?.removeMotionEffect(group!)
        }
        if parallaxSetting! {
            addParallaxToView(vw: pauseView, ve: blurView!)
        }
    }
    
    @objc func killBallRemoveVCKeyReceived(_ notification: Notification) {
        NotificationCenter.default.post(name: .killBallNotification, object: nil)
        removeAnimate(nextAction: .unpause)
    }

    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        removeAnimate(nextAction: .unpause)
    }
}

extension Notification.Name {
    public static let returnNotification = Notification.Name(rawValue: "returnNotification")
    public static let killBallRemoveVC = Notification.Name(rawValue: "killBallRemoveVC")
}
// Notification setup for sending information from the pause menu popup to unpause the game
