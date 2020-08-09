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
    
    var sender: String?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var aboutView: UIView!
    // Background setup
    
    @IBOutlet var logoIcon: UIImageView!
    @IBOutlet var logoTitle: UIImageView!
    @IBOutlet var creatorLabel: UILabel!
    @IBOutlet var composerLabel: UILabel!
    @IBOutlet var instagramLogo: UIButton!
    @IBOutlet var facebookLogo: UIButton!
    @IBOutlet var twitterLogo: UIButton!
    @IBOutlet var websiteLink: UIButton!
    @IBOutlet var brendanWebsiteLink: UIButton!
    
    @IBOutlet var buildLabel: UILabel!
    @IBOutlet var copyrightLabel: UILabel!
    
    @IBAction func instagramLogoTapped(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if let url = URL(string: "https://www.instagram.com/giga_ballapp/") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func facebookLogoTapped(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if let url = URL(string: "https://www.facebook.com/GigaBallApp/") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func twitterLogoTapped(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if let url = URL(string: "https://twitter.com/giga_ballapp") {
            UIApplication.shared.open(url)
        }
    }
    @IBAction func websiteLinkTapped(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if let url = URL(string: "https://www.giga-ball.app") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func brendanWebsiteLinkTapped(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if let url = URL(string: "https://www.giga-ball.app") {
            UIApplication.shared.open(url)
        }
    }
    
    
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        userSettings()
        
        if sender != "Info" {
            setBlur()
        }
        
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
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.5)
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
        NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
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

        logoIcon.alpha = 0.0
        logoIcon.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        logoIcon.center.y += distance

        logoTitle.alpha = 0.0
        logoTitle.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        logoTitle.center.y += distance

        creatorLabel.alpha = 0.0
        creatorLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        creatorLabel.center.y += distance

        composerLabel.alpha = 0.0
        composerLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        composerLabel.center.y += distance

        instagramLogo.alpha = 0.0
        instagramLogo.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        instagramLogo.center.y += distance

        facebookLogo.alpha = 0.0
        facebookLogo.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        facebookLogo.center.y += distance

        twitterLogo.alpha = 0.0
        twitterLogo.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        twitterLogo.center.y += distance

        websiteLink.alpha = 0.0
        websiteLink.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        websiteLink.center.y += distance
        
        brendanWebsiteLink.alpha = 0.0
        brendanWebsiteLink.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        brendanWebsiteLink.center.y += distance

        buildLabel.alpha = 0.0
        buildLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        buildLabel.center.y += distance
        
        copyrightLabel.alpha = 0.0
        copyrightLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        copyrightLabel.center.y += distance
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.logoIcon.alpha = 1.0
            self.logoIcon.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.logoIcon.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.logoTitle.alpha = 1.0
            self.logoTitle.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.logoTitle.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.creatorLabel.alpha = 1.0
            self.creatorLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.creatorLabel.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.composerLabel.alpha = 1.0
            self.composerLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.composerLabel.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.instagramLogo.alpha = 1.0
            self.instagramLogo.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.instagramLogo.center.y -= distance
            self.facebookLogo.alpha = 1.0
            self.facebookLogo.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.facebookLogo.center.y -= distance
            self.twitterLogo.alpha = 1.0
            self.twitterLogo.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.twitterLogo.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.websiteLink.alpha = 1.0
            self.websiteLink.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.websiteLink.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.brendanWebsiteLink.alpha = 1.0
            self.brendanWebsiteLink.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.brendanWebsiteLink.center.y -= distance
            delayFactor+=1
        })

        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.buildLabel.alpha = 1.0
            self.buildLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.buildLabel.center.y -= distance
            delayFactor+=1
        })
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.copyrightLabel.alpha = 1.0
            self.copyrightLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.copyrightLabel.center.y -= distance
            delayFactor+=1
        })
    }
}
