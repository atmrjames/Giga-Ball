//
//  AboutViewController.swift
//  Megaball
//
//  Created by James Harding on 05/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MenuNavigable {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    
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
    @IBOutlet var buildLabel: UILabel!
    @IBOutlet var copyrightLabel: UILabel!
    @IBOutlet var rightsLabel: UILabel!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.clipsToBounds = false
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        userSettings()
        
        if sender != "Info" {
            setBlur()
        }
        
        if parallaxSetting {
            addParallax()
        }
        addContactLinks()
        backButtonCollectionView.reloadData()
        installReturnToGameButton()
        // The way back into a paused run, from wherever this screen was reached
        showAnimate()
    }

    /// The website and the email address, under the small print.
    ///
    /// The About screen said who made the game and gave no way of reaching them (play-test
    /// round 18). Written out in full rather than labelled, and tappable, so the same line
    /// serves whether somebody wants to visit or to write it down.
    private func addContactLinks() {
        let links = UIStackView()
        links.axis = .vertical
        links.alignment = .center
        links.spacing = 2
        links.translatesAutoresizingMaskIntoConstraints = false
        aboutView.addSubview(links)
        contactLinks = links

        for (text, action) in [("giga-ball.app", #selector(openWebsite)),
                               ("contact@giga-ball.app", #selector(openMail))] {
            let link = UILabel()
            link.text = text
            link.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            link.font = composerLabel.font
            link.textAlignment = .center
            link.isUserInteractionEnabled = true
            link.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
            links.addArrangedSubview(link)
        }
        // Labels rather than buttons (play-test round 20): a button carries its own padding,
        // which put more air between the two lines than any other pair on this screen has.
        // Same face as the credits above them, so the block reads as one list

        NSLayoutConstraint.activate([
            links.centerXAnchor.constraint(equalTo: aboutView.centerXAnchor),
            links.bottomAnchor.constraint(equalTo: buildLabel.topAnchor, constant: -18),
            // Above the build number, not below it (play-test round 19): the build is the
            // last line of the small print, and a way of getting in touch is not small print
            links.leadingAnchor.constraint(greaterThanOrEqualTo: aboutView.leadingAnchor,
                                           constant: 20),
        ])
    }

    /// Kept so the fade-in can include it, in its place in the order.
    private var contactLinks: UIStackView?

    @objc private func openWebsite() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        if let site = URL(string: "https://giga-ball.app") { UIApplication.shared.open(site) }
    }

    @objc private func openMail() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        if let mail = URL(string: "mailto:contact@giga-ball.app?subject=Giga-Ball") {
            UIApplication.shared.open(mail)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
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
        cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        cell.setButton("ButtonClose.png")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        menuNavigationGoBack()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
            }
        }
    }
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.5)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
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
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
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
        
        contactLinks?.alpha = 0.0
        contactLinks?.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        contactLinks?.center.y += distance

        buildLabel.alpha = 0.0
        buildLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        buildLabel.center.y += distance
        
        copyrightLabel.alpha = 0.0
        copyrightLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        copyrightLabel.center.y += distance
        
        rightsLabel.alpha = 0.0
        rightsLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        rightsLabel.center.y += distance

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
            self.contactLinks?.alpha = 1.0
            self.contactLinks?.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.contactLinks?.center.y -= distance
            delayFactor+=1
        })
        // In its place in the cascade rather than simply present (play-test round 20) - it
        // sits between the credits and the build number on screen, so it arrives there too

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
        
        UIView.animate(withDuration: 0.5, delay: delay*delayFactor, options: .curveEaseInOut, animations: {
            self.rightsLabel.alpha = 1.0
            self.rightsLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
            self.rightsLabel.center.y -= distance
            delayFactor+=1
        })
    }
}
