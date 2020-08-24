//
//  StatsViewController.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ItemsDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var ballSetting: Int?
    var paddleSetting: Int?
    var brickSetting: Int?
    var appIconSetting: Int?
    var premiumSetting: Bool?
    // User settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    // UI property setup
    
    var senderID: Int?
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var itemsTableView: UITableView!
    @IBOutlet var itemsView: UIView!
    @IBOutlet var unlockedLabel: UILabel!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBOutlet var premiumTableView: UITableView!
    @IBOutlet var premiumTableCollapsed: NSLayoutConstraint!
    @IBOutlet var premiumTableExpanded: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnItemStatsNotificationKeyReceived), name: .returnItemStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        itemsTableView.rowHeight = 70.0
        
        userSettings()
        loadData()
        if parallaxSetting! {
            addParallax()
        }
        premiumTableViewHideShow()
        lockedCount()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        premiumTableViewHideShow()
    }
    
    func premiumTableViewHideShow() {
        premiumTableExpanded.isActive = false
        premiumTableView.isHidden = true
        premiumTableCollapsed.isActive = true
        
        var allPUsUnlockedBool = false
        if totalStatsArray[0].powerUpUnlockedArray.count == totalStatsArray[0].powerUpUnlockedArray.filter({$0 == true}).count {
            allPUsUnlockedBool = true
        }
        var allIconsUnlockedBool = false
        if totalStatsArray[0].appIconUnlockedArray.count == totalStatsArray[0].appIconUnlockedArray.filter({$0 == true}).count {
            allIconsUnlockedBool = true
        }
        var themeUnlockedArray = false
        if totalStatsArray[0].themeUnlockedArray.count == totalStatsArray[0].themeUnlockedArray.filter({$0 == true}).count {
            themeUnlockedArray = true
        }
        
        if premiumSetting! == false && senderID! <= 3 {
            if senderID == 0 && allIconsUnlockedBool == false {
                premiumTableView.isHidden = false
                premiumTableCollapsed.isActive = false
                premiumTableExpanded.isActive = true
                
            }
            if senderID == 1 && themeUnlockedArray == false {
                premiumTableView.isHidden = false
                premiumTableCollapsed.isActive = false
                premiumTableExpanded.isActive = true
                
            }
            if senderID == 2 && allPUsUnlockedBool == false {
                premiumTableView.isHidden = false
                premiumTableCollapsed.isActive = false
                premiumTableExpanded.isActive = true
            }
        }
    }
    
    func lockedCount() {
        var unlockedCount: Int = 0
        var arrayCount: Int = 0
        switch senderID {
        case 0:
            unlockedCount = totalStatsArray[0].appIconUnlockedArray.filter{$0 == true}.count
            arrayCount = totalStatsArray[0].appIconUnlockedArray.count
            titleLabel.text = "APP ICONS"
        case 1:
            unlockedCount = totalStatsArray[0].themeUnlockedArray.filter{$0 == true}.count
            arrayCount = totalStatsArray[0].themeUnlockedArray.count
            titleLabel.text = "BALL & PADDLE"
        case 2:
            unlockedCount = totalStatsArray[0].powerUpUnlockedArray.filter{$0 == true}.count
            arrayCount = totalStatsArray[0].powerUpUnlockedArray.count
            titleLabel.text = "POWER-UPS"
        case 3:
            unlockedCount = totalStatsArray[0].achievementsUnlockedArray.filter{$0 == true}.count
            arrayCount = totalStatsArray[0].achievementsUnlockedArray.count
            titleLabel.text = "ACHIEVEMENTS"
        default:
            break
        }
        if senderID == 5 {
            unlockedLabel.text = "COMPLETE: \(unlockedCount)/\(arrayCount)"
        } else {
            unlockedLabel.text = "UNLOCKED: \(unlockedCount)/\(arrayCount)"
        }
    }
    // Update locked/unlocked count
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.premiumTableView {
            return 1
        } else {
            if senderID == 0 {
            // App icons
                return totalStatsArray[0].appIconUnlockedArray.count
            } else if senderID == 1 {
            // Theme
                return totalStatsArray[0].themeUnlockedArray.count
            } else if senderID == 2 {
            // Power-ups
                return totalStatsArray[0].powerUpUnlockedArray.count
            } else if senderID == 3 {
            // Achievements
                return LevelPackSetup().achievementsNameArray.count
            } else {
            // default
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.premiumTableView {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "iAPCell", for: indexPath) as! IAPTableViewCell
            premiumTableView.rowHeight = 84.0
            cell.centreLabel.isHidden = true
            
            switch senderID {
                case 0:
                    cell.tagLine.text = "Unlock All App Icons"
                case 1:
                    cell.tagLine.text = "Unlock All Balls & Paddles"
                case 2:
                    cell.tagLine.text = "Unlock All Power-Ups"
            default:
                break
            }
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
            
            cell.decriptionFullWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = false
            cell.descriptionAndStateSharedWidthConstraint.isActive = true
            cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            cell.settingDescription.font = cell.settingDescription.font.withSize(18)
            
            if senderID == 0 {
            // App icons
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = true
                
                cell.iconImage.image = LevelPackSetup().appIconImageArray[indexPath.row]
                cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                cell.iconImage.layer.cornerRadius = 10
                cell.settingDescription.text = LevelPackSetup().appIconNameArray[indexPath.row]
                cell.centreLabel.text = ""
                cell.settingState.text = ""
                cell.tickImage.isHidden = true
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
                if appIconSetting == indexPath.row {
                    cell.tickImage.isHidden = false
                }
                if totalStatsArray[0].appIconUnlockedArray[indexPath.row] == false {
                    cell.descriptionAndStateSharedWidthConstraint.isActive = false
                    cell.descriptionTickWidthConstraint.isActive = false
                    cell.decriptionFullWidthConstraint.isActive = true

                    cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                    cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                    
                    if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+1] {
                        cell.settingDescription.text = LevelPackSetup().unlockedDescriptionArray[indexPath.row]
                    } else {
                        cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
                    }
                    // Only show pack name in unlock description if that pack is available to play
                    
                    cell.settingState.text = ""
                    cell.blurView.layer.cornerRadius = 10
                    cell.lockedImageView.layer.cornerRadius = 10
                    cell.blurView.layer.masksToBounds = true
                    cell.lockedImageView.layer.masksToBounds = true
                    cell.blurView.isHidden = false
                    cell.lockedImageView.isHidden = false
                }
                // Locked power-ups hidden until unlocked
            }
            
            if senderID == 1 {
            // Themes
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = true
                
                cell.iconImage.image = LevelPackSetup().themeIconArray[indexPath.row]
                cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
                cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.settingDescription.text = LevelPackSetup().themeNameArray[indexPath.row]
                cell.centreLabel.text = ""
                cell.settingState.text = ""
                cell.tickImage.isHidden = true
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
                if ballSetting == indexPath.row {
                    cell.tickImage.isHidden = false
                }
                
                if totalStatsArray[0].themeUnlockedArray[indexPath.row] == false {
                    cell.descriptionAndStateSharedWidthConstraint.isActive = false
                    cell.descriptionTickWidthConstraint.isActive = false
                    cell.decriptionFullWidthConstraint.isActive = true
                    cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                    cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                    
                    if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+1] {
                        cell.settingDescription.text = LevelPackSetup().unlockedDescriptionArray[indexPath.row]
                    } else {
                        cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
                    }
                    // Only show pack name in unlock description if that pack is available to play
                    
                    cell.settingState.text = ""
                    cell.blurView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                    cell.lockedImageView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                    cell.blurView.layer.masksToBounds = true
                    cell.lockedImageView.layer.masksToBounds = true
                    cell.blurView.isHidden = false
                    cell.lockedImageView.isHidden = false
                }
                // Locked balls hidden until unlocked
            }
            
            if senderID == 2 {
            // Power-ups
                let powerUpIndexCorrection = LevelPackSetup().powerUpCorrectOrderArray[indexPath.row]
                
                cell.iconImage.image = LevelPackSetup().powerUpImageArray[powerUpIndexCorrection]
                cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
                cell.settingDescription.text = LevelPackSetup().powerUpNameArray[powerUpIndexCorrection]
                cell.centreLabel.text = ""
                cell.settingState.text = ""
                            
                if totalStatsArray[0].powerupsGenerated.count < powerUpIndexCorrection-1 {
                    totalStatsArray[0].powerupsGenerated.append(0)
                }
                if totalStatsArray[0].powerupsCollected.count < powerUpIndexCorrection-1 {
                    totalStatsArray[0].powerupsCollected.append(0)
                }
                
                if totalStatsArray[0].powerUpUnlockedArray[powerUpIndexCorrection] == false {
                    cell.descriptionAndStateSharedWidthConstraint.isActive = false
                    cell.descriptionTickWidthConstraint.isActive = false
                    cell.decriptionFullWidthConstraint.isActive = true
                    cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                    cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                    
                    if totalStatsArray[0].levelPackUnlockedArray[LevelPackSetup().powerUpPackOrderArray[powerUpIndexCorrection]+1] {
                        cell.settingDescription.text = "\(LevelPackSetup().powerUpUnlockedDescriptionArray[powerUpIndexCorrection])"
                    } else {
                        cell.settingDescription.text = "\(LevelPackSetup().powerUpHiddenUnlockedDescriptionArray[powerUpIndexCorrection])"
                    }
                    // Only show pack name in unlock description if that pack is available to play

                    cell.settingState.text = ""
                    cell.blurView.layer.cornerRadius = 8
                    cell.lockedImageView.layer.cornerRadius = 8
                    cell.blurView.layer.masksToBounds = true
                    cell.lockedImageView.layer.masksToBounds = true
                    cell.blurView.isHidden = false
                    cell.lockedImageView.isHidden = false
                }
                // Locked power-ups hidden until unlocked
            }
            
            if senderID == 3 {
            // Achievements
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = true
                
                cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1483144264)
                cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.settingDescription.text = LevelPackSetup().achievementsNameArray[indexPath.row]
                cell.settingDescription.font = cell.settingDescription.font.withSize(15)
                cell.centreLabel.text = ""
                cell.settingState.text = ""
                if totalStatsArray[0].achievementsUnlockedArray[indexPath.row] {
                    cell.descriptionAndStateSharedWidthConstraint.isActive = false
                    cell.decriptionFullWidthConstraint.isActive = false
                    cell.descriptionTickWidthConstraint.isActive = true
                    
                    cell.tickImage.isHidden = false
                    cell.iconImage.image = UIImage(named: LevelPackSetup().achievementsImageArray[indexPath.row])!
    //                cell.settingState.isHidden = true
                } else {
                    cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                    cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                    cell.tickImage.isHidden = true
                    cell.iconImage.image = UIImage(named:"AchivementBadgeIncomplete.png")!
                }
                if totalStatsArray[0].achievementsPercentageCompleteArray[indexPath.row] != "" && totalStatsArray[0].achievementsUnlockedArray[indexPath.row] == false {
                    cell.decriptionFullWidthConstraint.isActive = false
                    cell.descriptionTickWidthConstraint.isActive = false
                    cell.descriptionAndStateSharedWidthConstraint.isActive = true

                    cell.settingState.text = totalStatsArray[0].achievementsPercentageCompleteArray[indexPath.row]
                }
                // Show percentage complete if achievement has percentage complete and isn't complete
            }
            
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == premiumTableView {
//            showPurchaseScreen()
//            IAPHandler().purchasePremium()
            IAPHandler().unlockPremiumContent() // Beta builds only
            
            UIView.animate(withDuration: 0.2) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
            
        } else {
            UIView.animate(withDuration: 0.2) {
                let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
            
            if senderID == 0 {
            // App icon
                if totalStatsArray[0].appIconUnlockedArray[indexPath.row] {
                    appIconSetting = indexPath.row
                    defaults.set(appIconSetting!, forKey: "appIconSetting")
                    changeIcon(to: LevelPackSetup().appIconNameArray[indexPath.row])
                }
                // Don't allow selection if app icon is locked
            }
            
            if senderID == 1 {
            // Theme selection
                if totalStatsArray[0].themeUnlockedArray[indexPath.row] {
                    ballSetting = indexPath.row
                    paddleSetting = indexPath.row
                    brickSetting = 0
                    defaults.set(ballSetting!, forKey: "ballSetting")
                    defaults.set(paddleSetting!, forKey: "paddleSetting")
                    defaults.set(brickSetting!, forKey: "brickSetting")

                    
                    if indexPath.row == 11 {
                        brickSetting = 1
                        defaults.set(brickSetting!, forKey: "brickSetting")
                    }
                }
                // Don't allow selection if theme is locked
            }
            
            if senderID == 2 {
            // Power-ups
                let powerUpIndexCorrection = LevelPackSetup().powerUpCorrectOrderArray[indexPath.row]
                
                if totalStatsArray[0].powerUpUnlockedArray[powerUpIndexCorrection] {
                    hideAnimate()
                    moveToItemStats(passedIndex: powerUpIndexCorrection, sender: "Power-Ups")
                }
                // Don't allow into menu if power-up is locked
            }
            
            if senderID == 3 {
            // Achievements
                hideAnimate()
                moveToItemStats(passedIndex: indexPath.row, sender: "Achievements")
                // Don't allow into menu if power-up is locked
            }

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
                let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
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
                let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
    }
    
    func changeIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        // Check app supports alternate icons

        UIApplication.shared.setAlternateIconName(iconName, completionHandler: { (error) in
        // Change the icon to an image with specific name
            if let error = error {
            print("App icon failed to change due to \(error.localizedDescription)")
            }
        })
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
//        if hapticsSetting! {
//            interfaceHaptic.impactOccurred()
//        }
        removeAnimate()
        if senderID == 0 || senderID == 1 {
            NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
        } else if senderID == 2 || senderID == 3 {
            NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
        }
        
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
    
    func moveToItemStats(passedIndex: Int, sender: String) {
        let itemStatsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsStatsView") as! ItemsStatsViewController
        itemStatsView.passedIndex = passedIndex
        itemStatsView.sender = sender
        self.addChild(itemStatsView)
        itemStatsView.view.frame = self.view.frame
        self.view.addSubview(itemStatsView.view)
        itemStatsView.didMove(toParent: self)
    }
    
    func showPurchaseScreen() {
        let iAPVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "iAPVC") as! InAppPurchaseViewController
        self.addChild(iAPVC)
        iAPVC.view.frame = self.view.frame
        self.view.addSubview(iAPVC.view)
        iAPVC.didMove(toParent: self)
    }
    // Show iAPVC as popup
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
        brickSetting = defaults.integer(forKey: "brickSetting")
        appIconSetting = defaults.integer(forKey: "appIconSetting")
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        // Load user settings
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
            itemsView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        itemsView.addMotionEffect(group!)
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
            self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.itemsView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.itemsView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.itemsView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.itemsView.alpha = 1.0
        })
    }
    
    @objc func returnItemStatsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        itemsTableView.reloadData()
        revealAnimate()
    }
    // Runs when returning from item stats view
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow()
        premiumTableView.reloadData()
        itemsTableView.reloadData()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow()
        lockedCount()
        premiumTableView.reloadData()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnItemStatsNotification = Notification.Name(rawValue: "returnItemStatsNotification")
}
// Notification setup
