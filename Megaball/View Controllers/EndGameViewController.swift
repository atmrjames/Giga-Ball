//
//  InbewteenLevelsViewController.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class EndGameViewController: UIViewController {
    
    var levelNumber: Int = 0
    var score: Int = 0
    var highScore: Int = 0
    var gameoverStatus: Bool = false
    var startLevel: Int = 0
    var numberOfLevels: Int = 0
    var scoresArray: [Int] = []
    // Properties to store passed over data
    
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
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var scoreLabelTitle: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    @IBOutlet weak var endGameTitle: UILabel!
    
    @IBAction func exitButton(_ sender: UIButton) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToMainMenu()
        // Move game scene to playing
    }
    
    @IBAction func restartButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        
//        gameState.enter(PreGame.self)
        
//        navigationController?.popViewController(animated: true)
        
//        moveToGame(selectedLevel: startLevel, numberOfLevels: numberOfLevels)
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
        backgroundView.backgroundColor = .clear
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
        let amount = 25
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        popupView.addMotionEffect(group!)
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
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    func removeAnimate() {
        NotificationCenter.default.post(name: .restartGameNotificiation, object: nil)
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0
        })
    }

    func updateLabels() {
        
        if gameoverStatus {
            endGameTitle.text = "G A M E  O V E R"
        } else {
            endGameTitle.text = "C O M P L E T E"
        }
        
        scoreLabelTitle.text = "Score"
        scoreLabel.text = String(score)
        highscoreLabelTitle.text = "Highscore"
        highscoreLabel.text = String(highScore)
        
        if score >= highScore {
            if scoresArray.count > 1 {
                var highScoreArraySort = scoresArray
                highScoreArraySort.sort(by: >)
                let previousHighScore = highScoreArraySort[1]
                // Get second highest score in array
                highscoreLabel.text = String(previousHighScore)
            } else {
                highscoreLabel.text = "0"
            }
            scoreLabelTitle.text = "New Highscore"
            highscoreLabelTitle.text = "Previous Highscore"
        }
    }
    
    func moveToMainMenu() {
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelSelectNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        navigationController?.popToRootViewController(animated: true)
    }
    
    func moveToGame(selectedLevel: Int, numberOfLevels: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController
}
