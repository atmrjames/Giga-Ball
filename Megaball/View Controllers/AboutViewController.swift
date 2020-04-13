//
//  AboutViewController.swift
//  Megaball
//
//  Created by James Harding on 05/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var aboutView: UIView!
    // Background setup
    
    @IBOutlet var createdByLabel: UILabel!
    @IBOutlet var creatorLabel: UILabel!
    @IBOutlet var musicByLabel: UILabel!
    @IBOutlet var composerLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    // Label setup
    
    @IBOutlet var imageView: UIImageView!
    // Image view setup
    
    @IBOutlet var websiteButtonLabel: UIButton!
    @IBOutlet var reviewButtonLabel: UIButton!
    @IBOutlet var supportButtonLabel: UIButton!
    // Button outlets
    
    @IBAction func websiteButton(_ sender: Any) {
        // Website link
    }
    @IBAction func reviewButton(_ sender: Any) {
        // App store link
    }
    @IBAction func supportButton(_ sender: Any) {
        // Support link
    }
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBAction func tapGesture(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
    // Tap gesture setup
    
    @IBOutlet var websiteButton: UIButton!
    @IBOutlet var reviewButton: UIButton!
    @IBOutlet var supportButton: UIButton!
    // Button outlet setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        // Setup swipe gesture
        
        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallax()
        }
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        backButtonCollectionView.reloadData()
        fadeObjectsIn()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = 40
        cell.iconImage.image = UIImage(named:"ButtonClose.png")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            cell.iconImage.image = UIImage(named:"ButtonClose.png")
        }
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
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        }
    }
    
    func addParallax() {
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
            aboutView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        aboutView.addMotionEffect(group!)
    }
    
    func fadeObjectsIn() {
        
        let delay = 0.1
        var delayFactor: Double = 1.0
        let distance: CGFloat = 30
        
        createdByLabel.alpha = 0.0
        createdByLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        createdByLabel.center.y += distance
        
        creatorLabel.alpha = 0.0
        creatorLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        creatorLabel.center.y += distance
        
        musicByLabel.alpha = 0.0
        musicByLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        musicByLabel.center.y += distance
        
        composerLabel.alpha = 0.0
        composerLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        composerLabel.center.y += distance
        
        imageView.alpha = 0.0
        imageView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        imageView.center.y += distance
        
        descriptionLabel.alpha = 0.0
        descriptionLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        descriptionLabel.center.y += distance
        
        websiteButtonLabel.alpha = 0.0
        websiteButtonLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        websiteButtonLabel.center.y += distance
        
        reviewButtonLabel.alpha = 0.0
        reviewButtonLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        reviewButtonLabel.center.y += distance
        
        supportButtonLabel.alpha = 0.0
        supportButtonLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        supportButtonLabel.center.y += distance
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.createdByLabel.alpha = 1.0
            self.createdByLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.createdByLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.creatorLabel.alpha = 1.0
            self.creatorLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.creatorLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.musicByLabel.alpha = 1.0
            self.musicByLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.musicByLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.composerLabel.alpha = 1.0
            self.composerLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.composerLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.imageView.alpha = 1.0
            self.imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.imageView.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.descriptionLabel.alpha = 1.0
            self.descriptionLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.descriptionLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.websiteButtonLabel.alpha = 1.0
            self.websiteButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.websiteButtonLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.reviewButtonLabel.alpha = 1.0
            self.reviewButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.reviewButtonLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.supportButtonLabel.alpha = 1.0
            self.supportButtonLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.supportButtonLabel.center.y -= distance
            delayFactor+=1
        })
    }
    
    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
    
}
