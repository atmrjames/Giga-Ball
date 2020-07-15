//
//  InbetweenViewController.swift
//  Megaball
//
//  Created by James Harding on 11/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import StoreKit

class InbetweenViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SKPaymentTransactionObserver {

    var levelNumber: Int = 0
    var packNumber: Int = 0
    var totalScore: Int = 0
    var levelScoreBonus: Int = 0
    var levelScoreMinusTimerBonus: Int = 0
    var firstLevel: Bool = false
    var numberOfLevels: Int = 0
    // Properties to store passed over data
    
    var levelNumberCorrected = 0
    var numberOfPackLevels = 0
    
    var showAnimateDuration = 0.25
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var premiumSetting: Bool?
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
    @IBOutlet var premiumTableView: UITableView!
    
    @IBOutlet var unlockedImage: UIImageView!
    
    @IBAction func tapGestureAction(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SKPaymentQueue.default().add(self)
        
        unlockedImage.isHidden = true
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotificationInbetween, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
                
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        
        if premiumSetting! {
            premiumTableView.isHidden = true
        } else {
            premiumTableView.isHidden = false
        }
        
        showAnimate()
        
        if levelNumber == LevelPackSetup().startLevelNumber[packNumber] && firstLevel == true {
            premiumTableView.isHidden = true
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
        premiumSetting = defaults.bool(forKey: "premiumSetting")
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
        premiumTableView.isHidden = true
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.contentView.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                if self.numberOfLevels == 1 {
                    self.levelNumberLabel.text = LevelPackSetup().levelNameArray[self.levelNumber+1]
                    self.levelNameLabel.text = "Single Level Mode"
                } else {
                    self.levelNumberLabel.text = "Level \(self.levelNumberCorrected+1) of \(self.numberOfPackLevels)"
                    self.levelNameLabel.text = LevelPackSetup().levelNameArray[self.levelNumber+1]
                }
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        premiumTableView.rowHeight = 84
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cell.iconImage.isHidden = false
        
        let premiumTagLineArray: [String] = [
            "Support The App \nGet Giga-Ball Premium",
            "Unlock All Power-Ups \nGet Giga-Ball Premium",
            "Remove Ads \nGet Giga-Ball Premium",
            "Unlock All Level Packs \nGet Giga-Ball Premium"
        ]

        cell.centreLabel.text = premiumTagLineArray.randomElement()!
        cell.settingDescription.text = ""
        cell.iconImage.image = UIImage(named:"iconPremium.png")!
        cell.settingState.text = ""
        
        cell.cellView2.layer.cornerRadius = 30
        cell.cellView2.layer.masksToBounds = false
        cell.cellView2.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.cellView2.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cell.cellView2.layer.shadowOpacity = 0.2
        cell.cellView2.layer.shadowRadius = 4
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
        
        return cell
    }
    // Add content to cells
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if hapticsSetting! {
//            interfaceHaptic.impactOccurred()
//        }
    
        print("llama llama premium selected")
        showPurchaseScreen()
        IAPHandler().purchasePremium()
        
        UIView.animate(withDuration: 0.2) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
                
        UIView.animate(withDuration: 0.1) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
    }
    
    func updateLabels() {
        levelScoreMinusTimerBonus = totalScore - levelScoreBonus
        scoreLabel.text = String(levelScoreMinusTimerBonus)
        levelNumberCorrected = levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1
        numberOfPackLevels = LevelPackSetup().numberOfLevels[packNumber]
        levelNumberLabel.text = "Level \(levelNumberCorrected) of \(numberOfPackLevels)"
        levelNameLabel.text = LevelPackSetup().levelNameArray[levelNumber]
        packNameLabel.text = LevelPackSetup().levelPackNameArray[packNumber]
        timeBonusScore.text = "+\(levelScoreBonus)"
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                print("User payment successful - inbetween")
                IAPHandler().unlockPremiumContent()
                SKPaymentQueue.default().finishTransaction(transaction)
                
            } else if transaction.transactionState == .failed {
                if let error = transaction.error {
                    let errorDescription = error.localizedDescription
                    print("User payment failed/cancelled - inbetween: \(errorDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: .iAPIncompleteNotification, object: nil)
                // Send notification to the app that the IAP was successful
                
            } else if transaction.transactionState == .restored {
                print("User purchase restored - inbetween")
                IAPHandler().unlockPremiumContent()
                SKPaymentQueue.default().finishTransaction(transaction)
            } else {
                print("llama other - inbetween")
            }
        }
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
    
    func showPurchaseScreen() {
        let iAPVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "iAPVC") as! InAppPurchaseViewController
        self.addChild(iAPVC)
        iAPVC.view.frame = self.view.frame
        self.view.addSubview(iAPVC.view)
        iAPVC.didMove(toParent: self)
    }
    // Show iAPVC as popup
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        removeAnimate()
    }
}

extension Notification.Name {
    public static let iAPcompleteNotificationInbetween = Notification.Name(rawValue: "iAPcompleteNotification")
}
