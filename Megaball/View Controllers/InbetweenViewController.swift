//
//  InbetweenViewController.swift
//  Megaball
//
//  Created by James Harding on 11/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class InbetweenViewController: UIViewController {

    var levelNumber: Int = 0
    var packNumber: Int = 0
    var totalScore: Int = 0
    var levelScoreBonus: Int = 0
    var levelScoreMinusTimerBonus: Int = 0
    var firstLevel: Bool = false
    // Properties to store passed over data
    
    var levelNumberCorrected = 0
    var numberOfLevels = 0
    
    var showAnimateDuration = 0.25
    
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
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var packNameLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var levelNumberLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var completeLabel: UILabel!
    @IBOutlet var scoreAmountLabel: UILabel!
    @IBOutlet var timeBonusLabel: UILabel!
    @IBOutlet var timeBonusScore: UILabel!
    @IBOutlet var tapLabel: UILabel!
    
    @IBAction func tapGesture(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallaxToView()
        }
        updateLabels()
        
        if levelScoreBonus <= 0 {
            timeBonusLabel.isHidden = true
            timeBonusScore.isHidden = true
        } else {
            timeBonusLabel.isHidden = false
            timeBonusScore.isHidden = false
        }
        
        showAnimate()
        
        if levelNumber == LevelPackSetup().startLevelNumber[packNumber] && firstLevel == true {
            showAnimateDuration = 0
            levelNumber = levelNumber-1
            levelNumberCorrected = levelNumberCorrected-1
            removeAnimate()
        }
    }

    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
    }

    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    func removeAnimate() {
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.contentView.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                self.levelNumberLabel.text = "Level \(self.levelNumberCorrected+1) of \(self.numberOfLevels)"
                self.levelNameLabel.text = LevelPackSetup().levelNameArray[self.levelNumber+1]
                self.packNameLabel.text = LevelPackSetup().levelPackNameArray[self.packNumber]
                self.scoreLabel.text = ""
                self.completeLabel.text = ""
                self.scoreAmountLabel.text = ""
                self.tapLabel.text = ""
                self.timeBonusLabel.text = ""
                self.timeBonusScore.text = ""
                NotificationCenter.default.post(name: .continueToNextLevel, object: nil)
                UIView.animate(withDuration: 0.25, animations: {
                    self.contentView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.contentView.alpha = 1.0})
                { (finished: Bool) in
                    if (finished) {
                        UIView.animate(withDuration: 1.50, animations: {
                            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                            self.view.alpha = 1.0})
                        { (finished: Bool) in
                            if (finished) {
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                                    self.view.alpha = 0.0})
                                { (finished: Bool) in
                                    if (finished) {
                                        self.view.removeFromSuperview()
                                        // Send notification to unpause the game
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateLabels() {
        levelScoreMinusTimerBonus = totalScore - levelScoreBonus
        scoreLabel.text = String(levelScoreMinusTimerBonus)
        levelNumberCorrected = levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1
        numberOfLevels = LevelPackSetup().numberOfLevels[packNumber]
        levelNumberLabel.text = "Level \(levelNumberCorrected) of \(numberOfLevels)"
        levelNameLabel.text = LevelPackSetup().levelNameArray[levelNumber]
        packNameLabel.text = LevelPackSetup().levelPackNameArray[packNumber]
        timeBonusScore.text = "+\(levelScoreBonus)"
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
            print("frame width: ", view.frame.width)
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
            contentView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        contentView.addMotionEffect(group!)
    }
}
