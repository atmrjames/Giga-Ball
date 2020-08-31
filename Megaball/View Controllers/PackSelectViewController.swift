//
//  PackSelectViewController.swift
//  Megaball
//
//  Created by James Harding on 10/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class PackSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var premiumSetting: Bool?
    // User settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    // UI property setup
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var packView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var packTableView: UITableView!
    @IBOutlet var backButtonCollectionView: UICollectionView!
    @IBOutlet var unlockedLabel: UILabel!
    
    @IBOutlet var premiumTableView: UITableView!
    @IBOutlet var premiumTableCollapsed: NSLayoutConstraint!
    @IBOutlet var premiumTableExpanded: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnPackSelectNotificationKeyReceived), name: .returnPackSelectNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        userSettings()
        loadData()
        
        packTableView.delegate = self
        packTableView.dataSource = self
        packTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        packTableView.rowHeight = 70.0
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        premiumTableViewHideShow()
        
        setBlur()
        if parallaxSetting! {
            addParallax()
        }
        showAnimate()
        packTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        premiumTableViewHideShow()
    }
    
    func premiumTableViewHideShow() {
        var allUnlockedBool = false
        if totalStatsArray[0].levelPackUnlockedArray.count == totalStatsArray[0].levelPackUnlockedArray.filter({$0 == true}).count {
            allUnlockedBool = true
        }
        if premiumSetting! == false && allUnlockedBool == false {
            premiumTableView.isHidden = false
            premiumTableCollapsed.isActive = false
            premiumTableExpanded.isActive = true
        } else {
            premiumTableView.isHidden = true
            premiumTableExpanded.isActive = false
            premiumTableCollapsed.isActive = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.premiumTableView {
            return 1
        } else {
            return 11
        }
    }
    // Set number of cells in table views
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.premiumTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "iAPCell", for: indexPath) as! IAPTableViewCell
            premiumTableView.rowHeight = 84.0
            cell.centreLabel.isHidden = true
            cell.tagLine.text = "Unlock All Level Packs"
            cell.iconImage.image = UIImage(named:"iconPremium.png")!
            
            UIView.animate(withDuration: 0.2) {
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.showsVerticalScrollIndicator = false
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
            
            cell.blurView.isHidden = true
            cell.lockedImageView.isHidden = true
            
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.settingDescription.text = LevelPackSetup().levelPackNameArray[indexPath.row+2]
            
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = true
            cell.tickImage.isHidden = true
            
            if totalStatsArray[0].packBestTimes[indexPath.row] > 0 {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = true
                cell.tickImage.isHidden = false
            }
            // Show tick if pack has been completed at least once
            
            cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            cell.settingDescription.font = cell.settingDescription.font.withSize(18)
            
            switch indexPath.row+2 {
            case 2:
                cell.iconImage.image = UIImage(named:"iconClassicPack.png")!
            case 3:
                cell.iconImage.image = UIImage(named:"iconSpacePack.png")!
            case 4:
                cell.iconImage.image = UIImage(named:"iconNaturePack.png")!
            case 5:
                cell.iconImage.image = UIImage(named:"iconUrbanPack.png")!
            case 6:
                cell.iconImage.image = UIImage(named:"iconFoodPack.png")!
            case 7:
                cell.iconImage.image = UIImage(named:"iconComputerPack.png")!
            case 8:
                cell.iconImage.image = UIImage(named:"iconBodyPack.png")!
            case 9:
                cell.iconImage.image = UIImage(named:"iconWorldPack.png")!
            case 10:
                cell.iconImage.image = UIImage(named:"iconEmojiPack.png")!
            case 11:
                cell.iconImage.image = UIImage(named:"iconNumbersPack.png")!
            case 12:
                cell.iconImage.image = UIImage(named:"iconChallengePack.png")!
            default:
                cell.iconImage.image = nil
                break
            }
            
            if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2] == false {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = true
                cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2-1] {
                    cell.settingDescription.text = "Complete \(LevelPackSetup().levelPackNameArray[indexPath.row+1]) to unlock"
                } else {
                    cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
                }
                if indexPath.row == 3 {
                    cell.settingDescription.text = "Complete first 3 packs to unlock"
                }
                // For level pack 4 show this message
                cell.settingState.text = ""
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked level packs until unlocked

            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == premiumTableView {
            showPurchaseScreen()
            IAPHandler().purchasePremium()
//            IAPHandler().unlockPremiumContent() // Beta builds only
            
            UIView.animate(withDuration: 0.2) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.reloadData()
            tableView.deselectRow(at: indexPath, animated: true)
            // Update table view
            
        } else {
            UIView.animate(withDuration: 0.2) {
                let cell = self.packTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
            
            if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2] {
                hideAnimate()
                moveToLevelSelector(packNumber: indexPath.row+2, numberOfLevels: LevelPackSetup().numberOfLevels[indexPath.row+2], startLevel: LevelPackSetup().startLevelNumber[indexPath.row+2])
            }
            // Don't allow selection if level pack is locked
            
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                let cell = self.packTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                let cell = self.packTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
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
    
    func showPurchaseScreen() {
        let iAPVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "iAPVC") as! InAppPurchaseViewController
        self.addChild(iAPVC)
        iAPVC.view.frame = self.view.frame
        self.view.addSubview(iAPVC.view)
        iAPVC.didMove(toParent: self)
    }
    // Show iAPVC as popup
    
    func moveToLevelSelector(packNumber: Int, numberOfLevels: Int, startLevel: Int) {
        let levelSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "levelSelectorView") as! LevelSelectorViewController
        levelSelectorView.packNumber = packNumber
        levelSelectorView.numberOfLevels = numberOfLevels
        levelSelectorView.startLevel = startLevel
        self.addChild(levelSelectorView)
        levelSelectorView.view.frame = self.view.frame
        self.view.addSubview(levelSelectorView.view)
        levelSelectorView.didMove(toParent: self)
    }
    // Segue to LevelSelectorViewController
    
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
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
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
            packView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        packView.addMotionEffect(group!)
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
    
    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.packView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.packView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.packView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.packView.alpha = 1.0
        })
    }
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        // Load the total stats array from the NSCoder data store
        
        let unlockedPackCount = totalStatsArray[0].levelPackUnlockedArray.filter{$0 == true}.count-2
        let lockedPackCount = totalStatsArray[0].levelPackUnlockedArray.count-2
        unlockedLabel.text = "UNLOCKED: \(unlockedPackCount)/\(lockedPackCount)"
    }
    
    @objc func returnPackSelectNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        revealAnimate()
        packTableView.reloadData()
    }
    // Runs when returning from another menu view
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow()
        premiumTableView.reloadData()
        packTableView.reloadData()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow()
        premiumTableView.reloadData()
        packTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnPackSelectNotification = Notification.Name(rawValue: "returnPackSelectNotification")
}
// Notification setup
