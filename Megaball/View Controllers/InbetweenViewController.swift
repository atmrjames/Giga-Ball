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
    var levelScore: Int = 0
    var levelScoreBonus: Int = 0
    var levelScoreMinusTimerBonus: Int = 0
    var firstLevel: Bool = false
    var numberOfLevels: Int = 0
    var sender: String?
    // Properties to store passed over data
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
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
    
    var premiumTagLineArray: [String] = [
        "Unlock All Power-Ups",
        "Remove Ads",
    ]
    var allPUsUnlockedBool = false
    var tagline = ""

    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var packNameLabel: UILabel!
    @IBOutlet var levelNumberLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var completeLabel: UILabel!
    
    @IBOutlet var levelScoreTitle: UILabel!
    @IBOutlet var levelScoreLabel: UILabel!
    @IBOutlet var speedBonusTitle: UILabel!
    @IBOutlet var speedBonusLabel: UILabel!
    @IBOutlet var totalScoreTitle: UILabel!
    @IBOutlet var totalScoreLabel: UILabel!
    
    @IBOutlet var tapLabel: UILabel!
    
    @IBOutlet var premiumTableView: UITableView!
    
    @IBOutlet var totalScoreNoSpeedBonus: NSLayoutConstraint!
    @IBOutlet var totalScoreSpeedBonus: NSLayoutConstraint!
    
    @IBOutlet var completeLabelConstraint: NSLayoutConstraint!
    @IBOutlet var packAndLevelConstriant: NSLayoutConstraint!
        
    @IBAction func tapGestureAction(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
    @IBAction func tapBackgroundGestureAction(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SKPaymentQueue.default().add(self)
        
        loadData()
        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallaxToView()
        }
        updateLabels()
        
        if levelScoreBonus <= 0 {
            speedBonusTitle.isHidden = true
            speedBonusLabel.isHidden = true
            totalScoreSpeedBonus.isActive = false
            totalScoreNoSpeedBonus.isActive = true
        } else {
            speedBonusTitle.isHidden = false
            speedBonusLabel.isHidden = false
            totalScoreNoSpeedBonus.isActive = false
            totalScoreSpeedBonus.isActive = true
        }
        
        packAndLevelConstriant.isActive = false
        completeLabelConstraint.isActive = true

        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotificationInbetween, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
                
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        if premiumSetting! {
            premiumTableView.isHidden = true
        } else {
            premiumTableView.isHidden = false
        }
        
        if totalStatsArray[0].powerUpUnlockedArray.count == totalStatsArray[0].powerUpUnlockedArray.filter({$0 == true}).count {
            allPUsUnlockedBool = true
        }
        if allPUsUnlockedBool {
            premiumTagLineArray.remove(at: 0)
        }
        tagline = premiumTagLineArray.randomElement()!
        // Don't show premium tags if packs or power-ups all unlocked
        
        showAnimate()
        
        if (levelNumber == LevelPackSetup().startLevelNumber[packNumber] && firstLevel) || (levelNumber == 0 && firstLevel) || firstLevel {
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
                self.levelNumber = self.levelNumber+1
                self.updateLabels()
                self.totalScoreLabel.text = ""
                self.completeLabel.text = ""
                self.totalScoreTitle.text = ""
                self.tapLabel.text = ""
                self.levelScoreTitle.text = ""
                self.levelScoreLabel.text = ""
                self.speedBonusTitle.text = ""
                self.speedBonusLabel.text = ""
                self.completeLabelConstraint.isActive = false
                self.packAndLevelConstriant.isActive = true
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "iAPCell", for: indexPath) as! IAPTableViewCell
        premiumTableView.rowHeight = 84.0
        cell.centreLabel.isHidden = true
        
        cell.tagLine.text = tagline
        cell.iconImage.image = UIImage(named:"iconPremium.png")!
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView.transform = .identity
            cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
        tableView.showsVerticalScrollIndicator = false
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        showPurchaseScreen()
//        IAPHandler().purchasePremium()
        IAPHandler().unlockPremiumContent() // Beta builds only

        UIView.animate(withDuration: 0.2) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
            cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
            cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
            cell.cellView.transform = .identity
            cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
        }
    }
    
    func updateLabels() {
        totalScoreLabel.text = String(totalScore)
        levelNumberCorrected = levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1
        numberOfPackLevels = LevelPackSetup().numberOfLevels[packNumber]
        speedBonusLabel.text = "+\(levelScoreBonus)"
        levelScoreLabel.text = String(levelScore)
        if levelNumber == 0 {
            packNameLabel.text = ""
            levelNumberLabel.text = String(LevelPackSetup().levelNameArray[0])
            levelNameLabel.text = ""
        }
        if numberOfLevels == 1 && levelNumber > 0 {
            packNameLabel.text = "Single Level Mode"
            levelNumberLabel.text = LevelPackSetup().levelNameArray[self.levelNumber]
            levelNameLabel.text = ""
        }
        if numberOfLevels > 1 {
            packNameLabel.text = "\(LevelPackSetup().levelPackNameArray[packNumber])"
            levelNumberLabel.text = "Level \(self.levelNumberCorrected) of \(self.numberOfPackLevels)"
            levelNameLabel.text = LevelPackSetup().levelNameArray[self.levelNumber]
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.transactionState == .purchased {
                IAPHandler().unlockPremiumContent()
                SKPaymentQueue.default().finishTransaction(transaction)
                
            } else if transaction.transactionState == .failed {
                if let error = transaction.error {
                    let errorDescription = error.localizedDescription
                    print("User payment failed/cancelled: \(errorDescription)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: .iAPIncompleteNotification, object: nil)
                // Send notification to the app that the IAP was successful
                
            } else if transaction.transactionState == .restored {
                IAPHandler().unlockPremiumContent()
                SKPaymentQueue.default().finishTransaction(transaction)
            } else {
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
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        // Load the total stats array from the NSCoder data store
    }
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        removeAnimate()
    }
}

extension Notification.Name {
    public static let iAPcompleteNotificationInbetween = Notification.Name(rawValue: "iAPcompleteNotification")
}
