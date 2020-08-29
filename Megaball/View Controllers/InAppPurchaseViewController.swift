//
//  InAppPurchaseViewController.swift
//  Megaball
//
//  Created by James Harding on 11/07/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class InAppPurchaseViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    // User settings
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotificationView, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPIncompleteNotificationKeyReceived), name: .iAPIncompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase failure

        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallaxToView()
        }
        statusLabel.text = "Processing..."
        showAnimate()
    }
    
    func setBlur() {
        contentView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.33)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView!, at: 0)
        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: contentView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: contentView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: contentView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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
            backgroundView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying
        
        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundView.addMotionEffect(group!)
    }
    
    func userSettings() {
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
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
        UIView.animate(withDuration: 2.0, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.01, y: 1.01)
            self.view.alpha = 1.0})
        { (finished: Bool) in
            if (finished) {
                UIView.animate(withDuration: 0.25, animations: {
                    self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                    self.view.alpha = 0.0})
                { (finished: Bool) in
                    if (finished) {
                        self.view.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        removeAnimate()
    }
    // IAP complete
    @objc func iAPIncompleteNotificationKeyReceived(_ notification: Notification) {
        statusLabel.text = "Purchase unsuccessful"
        statusLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
        removeAnimate()
    }
    // IAP incomplete
}

extension Notification.Name {
    public static let iAPcompleteNotificationView = Notification.Name(rawValue: "iAPcompleteNotification")
    public static let iAPIncompleteNotification = Notification.Name(rawValue: "iAPIncompleteNotification")
}

