//
//  InbewteenLevelsViewController.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class EndGameViewController: UIViewController {
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    let defaults = UserDefaults.standard
    
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    
    var levelNumber: Int = 0
    var levelScore: Int = 0
    var levelHighscore: Int = 0
    var totalScore: Int = 0
    var totalHighscore: Int = 0
    var gameoverStatus: Bool = false
    // Properties to store passed over data

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var scoreLabelTitle: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    @IBOutlet weak var endGameTitle: UILabel!
    
    @IBAction func exitButton(_ sender: UIButton) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToMainMenu()
        // Move game scene to playing
    }
    
    @IBAction func restartButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToGame(selectedLevel: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        setBlur()
        showAnimate()
        updateLabels()
    }

    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func updateLabels() {
        if totalHighscore <= 1 {
            totalHighscore = 0
        }
        if totalScore >= totalHighscore && totalHighscore > 1 {
            scoreLabelTitle.text = "New Highscore"
            highscoreLabelTitle.text = "Previous Highscore"
        } else {
            scoreLabelTitle.text = "Score"
            highscoreLabelTitle.text = "Highscore"
        }
        
        scoreLabel.text = String(totalScore)
        highscoreLabel.text = String(totalHighscore)
        
        if gameoverStatus {
            endGameTitle.text = "G A M E  O V E R"
        } else {
            endGameTitle.text = "C O M P L E T E"
        }
    }
    
    func moveToGame(selectedLevel: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self as? MenuViewControllerDelegate
        gameView.selectedLevel = selectedLevel
        self.navigationController?.pushViewController(gameView, animated: false)
    }
    // Segue to GameViewController
    
    func setBlur() {
        popupView.backgroundColor = .clear
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .extraLight)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .extraDark, .regular, and .prominent.
        let blurView = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurView.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        view.insertSubview(blurView, at: 0)

        NSLayoutConstraint.activate([
        blurView.heightAnchor.constraint(equalTo: popupView.heightAnchor),
        blurView.widthAnchor.constraint(equalTo: popupView.widthAnchor),
        blurView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
        blurView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
        blurView.topAnchor.constraint(equalTo: popupView.topAnchor),
        blurView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
        
        if parallaxSetting! {
            addParallaxToView(vw: popupView, ve: blurView)
        }
    }
    
    func addParallaxToView(vw: UIView, ve: UIVisualEffectView) {
        let amount = 25

        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        vw.addMotionEffect(group)
        ve.addMotionEffect(group)
    }
}

