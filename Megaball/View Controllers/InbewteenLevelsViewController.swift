//
//  InbewteenLevelsViewController.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class InbewteenLevelsViewController: UIViewController {
    
    var levelNumber: Int = 0
    var levelScore: Int = 0
    var levelHighscore: Int = 0
    var totalScore: Int = 0
    var totalHighscore: Int = 0
    var gameoverStatus: Bool = false
    // Properties to store passed over data

    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var levelCompleteLabel: UILabel!
    @IBOutlet weak var levelScoreLabel: UILabel!
    @IBOutlet weak var levelHighscoreLabel: UILabel!
    @IBOutlet weak var totalScoreLabel: UILabel!
    @IBOutlet weak var totalHighscoreLabel: UILabel!

    @IBOutlet weak var filledStar1: UIImageView!
    @IBOutlet weak var filledStar2: UIImageView!
    @IBOutlet weak var filledStar3: UIImageView!
    
    @IBOutlet weak var nextLevelButtonLabel: UIButton!
    @IBOutlet weak var restartButtonLabel: UIButton!
    
    @IBAction func nextLevelButton(_ sender: UIButton) {
        removeAnimate(nextAction: .continueToNextLevel)
        // Move game scene to playing
    }
    
    @IBAction func restartButton(_ sender: UIButton) {
        restart()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func removeAnimate(nextAction: Notification.Name) {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0
        }) { (finished: Bool) in
            if (finished) {
                let mainMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "menuView") as! MenuViewController
                mainMenuVC.currentHighscore = self.totalHighscore
                NotificationCenter.default.post(name: nextAction, object: nil)
                // Send notification to load the next level
                self.view.removeFromSuperview()
            }
        }
    }
    
    func updateLabels() {
        
        levelCompleteLabel.text = "G A M E  O V E R"
        nextLevelButtonLabel.setTitle("MAIN MENU", for: .normal)
        restartButtonLabel.isHidden = false
            
        if levelScore >= 0 {
            levelScoreLabel.text = "+\(levelScore)"
        } else {
            levelScoreLabel.text = String(levelScore)
        }
        
        if levelScore >= levelHighscore {
            levelHighscoreLabel.text = "New level \(levelNumber) highscore!"
        } else {
            levelHighscoreLabel.text = String(levelHighscore)
        }
        
        totalScoreLabel.text = String(totalScore)
        if totalScore >= totalHighscore {
            totalHighscoreLabel.text = "New total highscore"
        } else {
            totalHighscoreLabel.text = String(totalHighscore)
        }
    }
    
    func restart() {
        removeAnimate(nextAction: .restart)
        // move game scene to pregame
    }
    
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
        
        addParallaxToView(vw: popupView, ve: blurView)
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

