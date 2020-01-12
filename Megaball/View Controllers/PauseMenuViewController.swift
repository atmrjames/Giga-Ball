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
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    
    @IBAction func returnToMainMenuButton(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToMainMenu()
    }
    
    @IBAction func playButtonPressed(_ sender: UIButton) {        
        mediumHaptic.impactOccurred()
        removeAnimate(nextAction: .unpause)
    }
    
    @IBAction func settingsButton(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
    }
    
    @IBAction func killBall(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        NotificationCenter.default.post(name: .killBallNotification, object: nil)
        removeAnimate(nextAction: .unpause)
    }
    // Defining object properties
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        // Setup swipe gesture
        setBlur()
        showAnimate()
        updateLabels()
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
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
        mediumHaptic.impactOccurred()
        removeAnimate(nextAction: .unpause)
    }
    
    // Segue to MenuViewController
    
    //    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
    //        return []
    //    }
    //    // Re-enable home bar on 1st swipe
}
