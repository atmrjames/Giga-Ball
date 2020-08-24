//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import StoreKit

enum device {
    case Pad
    case X
    case Eight
    case SE
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, SKPaymentTransactionObserver {
    
    var navigatedFrom: String?
    
    let defaults = UserDefaults.standard
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var gameCenterSetting: Bool?
    var ballSetting: Int?
    var paddleSetting: Int?
    var brickSetting: Int?
    var appIconSetting: Int?
    var statsCollapseSetting: Bool?
    var swipeUpPause: Bool?
    var appOpenCount: Int?
    var firstPause: Bool?
    // User settings
    var saveGameSaveArray: [Int]?
    var saveMultiplier: Double?
    var saveBrickTextureArray: [Int]?
    var saveBrickColourArray: [Int]?
    var saveBrickXPositionArray: [Int]?
    var saveBrickYPositionArray: [Int]?
    var saveBallPropertiesArray: [Double]?
    // Game save settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    var screenSize: device?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    var premiumTagLineArray: [String] = [
        "Support The App",
        "Unlock All Power-Ups",
        "Remove Ads",
        "Unlock All Levels & Packs",
        "Unlock All Customisations",
        "Unlock All Content"
    ]
    var tagline = ""
    
    var musicPausedBool: Bool = false
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBOutlet var backgroundViewLeading: NSLayoutConstraint!
    @IBOutlet var backgroundViewTop: NSLayoutConstraint!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBOutlet var premiumTableView: UITableView!
    @IBOutlet var premiumTableExpanded: NSLayoutConstraint!
    @IBOutlet var premiumTableCollapsed: NSLayoutConstraint!
    
    @IBOutlet var backButtonCollapsed: NSLayoutConstraint!
    @IBOutlet var backButtonExpanded: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetNotificiationKeyReceived), name: .resetNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has selected to reset the game data
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnNotificiationKeyReceived), name: .returnNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the warning pop-up
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reanimateNotificiationKeyReceived), name: .reanimateNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another screen
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        SKPaymentQueue.default().add(self)
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        let screenRatio = self.view.frame.size.height/self.view.frame.size.width
        
        if screenRatio > 2 {
            screenSize = .X
        } else if screenRatio < 1.7  {
            screenSize = .Pad
            ipadCompatibility()
        } else if self.view.frame.size.width <= 320 {
            screenSize = .SE
        }
        else {
            screenSize = .Eight
        }
        // Screen size and device detected
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        settingsTableView.separatorStyle = .none
        settingsTableView.rowHeight = 70.0
        // TableView setup
        
        userSettings()
        loadData()
        premiumTableViewHideShow(animated: false)
        if parallaxSetting! {
            addParallaxToView()
        }
        if navigatedFrom! == "MainMenu" {
            setBlur()
        }
        var allPacksUnlockedBool = false
        if totalStatsArray[0].levelPackUnlockedArray.count == totalStatsArray[0].levelPackUnlockedArray.filter({$0 == true}).count {
            allPacksUnlockedBool = true
        }
        var allCustomUnlockedBool = false
        if totalStatsArray[0].themeUnlockedArray.count == totalStatsArray[0].themeUnlockedArray.filter({$0 == true}).count && totalStatsArray[0].appIconUnlockedArray.count == totalStatsArray[0].appIconUnlockedArray.filter({$0 == true}).count {
            allCustomUnlockedBool = true
        }
        var allPUsUnlockedBool = false
        if totalStatsArray[0].powerUpUnlockedArray.count == totalStatsArray[0].powerUpUnlockedArray.filter({$0 == true}).count {
            allPUsUnlockedBool = true
        }
        
        if allCustomUnlockedBool {
            premiumTagLineArray.remove(at: 5)
        }
        if allPacksUnlockedBool {
            premiumTagLineArray.remove(at: 3)
        }
        if allPUsUnlockedBool {
            premiumTagLineArray.remove(at: 1)
        }
        tagline = premiumTagLineArray.randomElement()!

        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        premiumTableViewHideShow(animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.premiumTableView {
            return 1
        } else {
            if navigatedFrom! == "PauseMenu" {
                return 11
            } else {
                return 14
            }
        }
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.premiumTableView {
            
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
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
            settingsTableView.rowHeight = 70.0
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.iconImage.isHidden = false
            
            switch indexPath.row {
            case 0:
            // Premium
                hideCell(cell: cell)
                cell.settingDescription.text = "Premium"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconPremium.png")!
                if premiumSetting! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
//                hideCell(cell: cell)
            case 1:
            // Ads
                hideCell(cell: cell)
                cell.settingDescription.text = "Ads"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconAd.png")!
                if adsSetting! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 2:
            // App icon
                if navigatedFrom! == "PauseMenu" {
                    hideCell(cell: cell)
                } else {
                    cell.settingDescription.text = "App Icon"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconAppIcon.png")!
                    cell.settingState.text = ""
                }
            case 3:
            // Theme
                if navigatedFrom! == "PauseMenu" {
                    hideCell(cell: cell)
                } else {
                    cell.settingDescription.text = "Ball & Paddle"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconTheme.png")!
                    cell.settingState.text = ""
                }
            case 4:
            // Sounds
                hideCell(cell: cell)
                cell.settingDescription.text = "Sounds"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconSound.png")!
                if soundsSetting! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 5:
            // Music
                cell.settingDescription.text = "Sound"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconSound.png")!
                if musicSetting! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 6:
            // Haptics
                if screenSize == .Pad || screenSize == .SE {
                // No haptics' engine
                    hideCell(cell: cell)
                } else {
                    cell.settingDescription.text = "Haptics"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconHaptics.png")!
                    if hapticsSetting! {
                        cell.settingState.text = "on"
                        cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                    } else {
                        cell.settingState.text = "off"
                        cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                    }
                }
            case 7:
            // Parallax
                cell.settingDescription.text = "Perspective Zoom"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconParallax.png")!
                if parallaxSetting! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 8:
            // Paddle sensitivity
                cell.settingDescription.text = "Paddle Speed"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconPaddleSensitivity.png")!
                if paddleSensitivitySetting == 0 {
                    cell.settingState.text = "x1.00"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                } else if paddleSensitivitySetting == 1 {
                    cell.settingState.text = "x1.25"
                    cell.settingState.textColor = #colorLiteral(red: 0.370555222, green: 0.3705646992, blue: 0.3705595732, alpha: 1)
                } else if paddleSensitivitySetting == 2 {
                    cell.settingState.text = "x1.50"
                    cell.settingState.textColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
                } else if paddleSensitivitySetting == 3 {
                    cell.settingState.text = "x2.00"
                    cell.settingState.textColor = #colorLiteral(red: 0.12, green: 0.13, blue: 0.14, alpha: 1)
                } else if paddleSensitivitySetting == 4 {
                    cell.settingState.text = "x3.00"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                }
            case 9:
            // Swipe up to pause
                cell.settingDescription.text = "Swipe Up To Pause"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconPause.png")!
                if swipeUpPause! {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 10:
                if navigatedFrom! != "PauseMenu" {
                // Reset game data
                    cell.settingDescription.text = ""
                    cell.centreLabel.text = "Reset All Game Data (developer)"
                    cell.settingState.text = ""
                    cell.iconImage.isHidden = true
                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
                } else {
                // Kill ball
                    cell.settingDescription.text = ""
                    cell.settingState.text = ""
                    cell.centreLabel.text = "Reset Ball"
                    cell.iconImage.isHidden = true
                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
                }
            case 11:
            // Restore purchases
                if premiumSetting! == false {
                    cell.settingDescription.text = ""
                    cell.centreLabel.text = "Restore Purchase"
                    cell.settingState.text = ""
                    cell.iconImage.isHidden = true
                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
                } else {
                    hideCell(cell: cell)
                }
            case 12:
            // Unlock all
                cell.settingDescription.text = ""
                cell.centreLabel.text = "Unlock All Items (developer)"
                cell.settingState.text = ""
                cell.iconImage.isHidden = true
                cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
                
            case 13:
            // Re-lock all
                cell.settingDescription.text = ""
                cell.centreLabel.text = "Reset Locked Items (developer)"
                cell.settingState.text = ""
                cell.iconImage.isHidden = true
                cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
            default:
                print("Error: Out of range")
                break
            }
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            tableView.showsVerticalScrollIndicator = false
            return cell
        }
    }
    // Add content to cells
    
    func hideCell(cell: SettingsTableViewCell) {
        cell.settingDescription.text = ""
        cell.centreLabel.text = ""
        cell.settingState.text = ""
        settingsTableView.rowHeight = 0.0
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
            switch indexPath.row {
            case 0:
            // Premium
                premiumSetting = !premiumSetting!
                defaults.set(premiumSetting!, forKey: "premiumSetting")
                if premiumSetting! {
                    adsSetting = false
                } else {
                    adsSetting = true
                }
                defaults.set(adsSetting!, forKey: "adsSetting")
                premiumTableViewHideShow(animated: true)
            case 1:
            // Ads
                adsSetting = !adsSetting!
                defaults.set(adsSetting!, forKey: "adsSetting")
            case 2:
            // App icon
                hideAnimate()
                moveToItemDetails(senderID: 0)
            case 3:
            // Theme
                hideAnimate()
                moveToItemDetails(senderID: 1)
            case 4:
            // Sounds
                soundsSetting = !soundsSetting!
                defaults.set(soundsSetting!, forKey: "soundsSetting")
            case 5:
            // Music
                musicSetting = !musicSetting!
                soundsSetting = musicSetting
                defaults.set(musicSetting!, forKey: "musicSetting")
                defaults.set(soundsSetting!, forKey: "soundsSetting")
                if musicSetting! {
                    if musicPausedBool {
                        MusicHandler.sharedHelper.resumeMusic()
                    } else {
                        if navigatedFrom == "MainMenu" {
                            MusicHandler.sharedHelper.playMusic(sender: "Menu")
                        } else {
                            MusicHandler.sharedHelper.playMusic()
                        }
                    }
                } else {
                    musicPausedBool = true
                    MusicHandler.sharedHelper.pauseMusic()
                    // Stop music
                }
            case 6:
            // Haptics
                hapticsSetting = !hapticsSetting!
                defaults.set(hapticsSetting!, forKey: "hapticsSetting")
            case 7:
            // Parallax
                parallaxSetting = !parallaxSetting!
                defaults.set(parallaxSetting!, forKey: "parallaxSetting")
                if parallaxSetting! {
                    addParallaxToView()
                } else if parallaxSetting! == false {
                    if group != nil {
                        backgroundView.removeMotionEffect(group!)
                    }
                }
            case 8:
            // Paddle sensitivity
                paddleSensitivitySetting = paddleSensitivitySetting!+1
                if paddleSensitivitySetting! > 4 {
                    paddleSensitivitySetting = 0
                }
                defaults.set(paddleSensitivitySetting!, forKey: "paddleSensitivitySetting")
            case 9:
            // Swipe up pause
                swipeUpPause = !swipeUpPause!
                defaults.set(swipeUpPause!, forKey: "swipeUpPause")
            case 10:
                if navigatedFrom! != "PauseMenu" {
                // Reset game data
                    showWarning(senderID: "resetData")
                } else {
                // Kill ball
                    showWarning(senderID: "killBall")
                }
            case 11:
            // Restore purchases
                showPurchaseScreen()
                IAPHandler().restorePurchase()
            case 12:
            // Unlock all
                unlockAllItems()
            case 13:
            // Re-lock all
                relockAllItems()
            default:
                break
            }
            
            CloudKitHandler().saveUserDefaults()
            // Save any changes to NSUbiquitousKeyValueStore
            
            UIView.animate(withDuration: 0.2) {
                let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
        }
    }
    
    func moveToItemDetails(senderID: Int) {
        let itemsDetailView = self.storyboard?.instantiateViewController(withIdentifier: "itemsDetailView") as! ItemsDetailViewController
        itemsDetailView.senderID = senderID
        self.addChild(itemsDetailView)
        itemsDetailView.view.frame = self.view.frame
        self.view.addSubview(itemsDetailView.view)
        itemsDetailView.didMove(toParent: self)
    }
    
    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.backgroundView.alpha = 0.0
        })
    }
    
    func premiumTableViewHideShow(animated: Bool) {
        if premiumSetting! {
            premiumTableView.isHidden = true
            premiumTableExpanded.isActive = false
            backButtonExpanded.isActive = false
            premiumTableCollapsed.isActive = true
            backButtonCollapsed.isActive = true

        } else {
            premiumTableView.isHidden = false
            premiumTableCollapsed.isActive = false
            backButtonCollapsed.isActive = false
            premiumTableExpanded.isActive = true
            backButtonExpanded.isActive = true
        }
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
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
                    print("User payment failed/cancelled - settings: \(errorDescription)")
                }
                NotificationCenter.default.post(name: .iAPIncompleteNotification, object: nil)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            } else if transaction.transactionState == .restored {
                IAPHandler().unlockPremiumContent()
                SKPaymentQueue.default().finishTransaction(transaction)
            }
        }
    }
    
    func unlockAllItems() {
        totalStatsArray[0].levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray.map { _ in true }
        totalStatsArray[0].themeUnlockedArray = totalStatsArray[0].themeUnlockedArray.map { _ in true }
        totalStatsArray[0].appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray.map { _ in true }
        totalStatsArray[0].levelUnlockedArray = totalStatsArray[0].levelUnlockedArray.map { _ in true }
        totalStatsArray[0].powerUpUnlockedArray = totalStatsArray[0].powerUpUnlockedArray.map { _ in true }
        totalStatsArray[0].achievementsUnlockedArray = totalStatsArray[0].achievementsUnlockedArray.map { _ in true }
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        CloudKitHandler().saveTotalStats()
    }
    
    func relockAllItems() {
        ballSetting = 0
        defaults.set(ballSetting!, forKey: "ballSetting")
        paddleSetting = 0
        defaults.set(paddleSetting!, forKey: "paddleSetting")
        brickSetting = 0
        defaults.set(brickSetting!, forKey: "brickSetting")
        if appIconSetting != 0 {
            appIconSetting = 0
            defaults.set(appIconSetting!, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[0])
        }
        
        totalStatsArray[0] = TotalStats()
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        CloudKitHandler().saveUserDefaults()
        CloudKitHandler().saveTotalStats()
        // Save to iCloud
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            if indexPath.row != 6 {
                interfaceHaptic.impactOccurred()
            }
        } else {
            if indexPath.row == 6 {
                interfaceHaptic.impactOccurred()
            }
        }
        
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            if indexPath.row != 6 {
                interfaceHaptic.impactOccurred()
            }
        } else {
            if indexPath.row == 6 {
                interfaceHaptic.impactOccurred()
            }
        }
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
        } else {
            UIView.animate(withDuration: 0.1) {
                let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
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
        if navigatedFrom! == "PauseMenu" {
            NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
        } else if navigatedFrom! == "MainMenu" {
            NotificationCenter.default.post(name: .returnSettingsNotification, object: nil)
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
    
    func setBlur() {
        settingsView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
        // 1: change the superview transparent
        let blurEffect = UIBlurEffect(style: .dark)
        // 2 Create a blur with a style. Other options include .extraLight .light, .dark, .regular, and .prominent.
        blurView = UIVisualEffectView(effect: blurEffect)
        // 3 Create a UIVisualEffectView with the new blur
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        // 4 Disable auto-resizing into constrains. Constrains are setup manually.
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: settingsView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: settingsView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: settingsView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: settingsView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func userSettings() {
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
        brickSetting = defaults.integer(forKey: "brickSetting")
        appIconSetting = defaults.integer(forKey: "appIconSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
        swipeUpPause = defaults.bool(forKey: "swipeUpPause")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        firstPause = defaults.bool(forKey: "firstPause")
        // User settings
        
        saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
        saveMultiplier = defaults.double(forKey: "saveMultiplier")
        saveBrickTextureArray = defaults.object(forKey: "saveBrickTextureArray") as! [Int]?
        saveBrickColourArray = defaults.object(forKey: "saveBrickColourArray") as! [Int]?
        saveBrickXPositionArray = defaults.object(forKey: "saveBrickXPositionArray") as! [Int]?
        saveBrickYPositionArray = defaults.object(forKey: "saveBrickYPositionArray") as! [Int]?
        saveBallPropertiesArray = defaults.object(forKey: "saveBallPropertiesArray") as! [Double]?
        // Game save settings
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
    
    func ipadCompatibility() {
        backgroundViewLeading.isActive = false
        backgroundViewTop.isActive = false
        backgroundView.frame.size.height = 896
        backgroundView.frame.size.width = 414
    }
    
    func showWarning(senderID: String) {
        
        if group != nil {
            backgroundView.removeMotionEffect(group!)
        }
        // Remove parallax to prevent a double parallax in the layered views
        
        let warningView = self.storyboard?.instantiateViewController(withIdentifier: "warningView") as! WarningViewController
        warningView.senderID = senderID
        self.addChild(warningView)
        warningView.view.frame = self.view.frame
        self.view.addSubview(warningView.view)
        warningView.didMove(toParent: self)
    }
    
    func resetData() {
        premiumSetting = false
        defaults.set(premiumSetting!, forKey: "premiumSetting")
        adsSetting = true
        defaults.set(adsSetting!, forKey: "adsSetting")
        soundsSetting = true
        defaults.set(soundsSetting!, forKey: "soundsSetting")
        musicSetting = true
        defaults.set(musicSetting!, forKey: "musicSetting")
        hapticsSetting = true
        defaults.set(hapticsSetting!, forKey: "hapticsSetting")
        parallaxSetting = true
        defaults.set(parallaxSetting!, forKey: "parallaxSetting")
        if view.frame.size.width > 450 {
            paddleSensitivitySetting = 3
        } else {
            paddleSensitivitySetting = 2
        }
        defaults.set(paddleSensitivitySetting!, forKey: "paddleSensitivitySetting")
        
        gameCenterSetting = false
        defaults.set(gameCenterSetting!, forKey: "gameCenterSetting")
        ballSetting = 0
        defaults.set(ballSetting!, forKey: "ballSetting")
        paddleSetting = 0
        defaults.set(paddleSetting!, forKey: "paddleSetting")
        brickSetting = 0
        defaults.set(brickSetting!, forKey: "brickSetting")
        if appIconSetting != 0 {
            appIconSetting = 0
            defaults.set(appIconSetting!, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[0])
        }
        statsCollapseSetting = true
        defaults.set(statsCollapseSetting!, forKey: "statsCollapseSetting")
        swipeUpPause = true
        defaults.set(swipeUpPause!, forKey: "swipeUpPause")
        appOpenCount = 0
        defaults.set(appOpenCount!, forKey: "appOpenCount")
        firstPause = true
        defaults.set(firstPause!, forKey: "firstPause")
        
        saveGameSaveArray = []
        defaults.set(saveGameSaveArray!, forKey: "saveGameSaveArray")
        saveMultiplier = 1.0
        defaults.set(saveMultiplier!, forKey: "saveMultiplier")
        saveBrickTextureArray = []
        defaults.set(saveBrickTextureArray!, forKey: "saveBrickTextureArray")
        saveBrickColourArray = []
        defaults.set(saveBrickColourArray!, forKey: "saveBrickColourArray")
        saveBrickXPositionArray = []
        defaults.set(saveBrickXPositionArray!, forKey: "saveBrickXPositionArray")
        saveBrickYPositionArray = []
        defaults.set(saveBrickYPositionArray!, forKey: "saveBrickYPositionArray")
        saveBallPropertiesArray = []
        defaults.set(saveBallPropertiesArray!, forKey: "saveBallPropertiesArray")
        // Reset user settings to defaults
        
        totalStatsArray[0] = TotalStats()
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            totalStatsArray[0].dateSaved = Date()
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        CloudKitHandler().saveUserDefaults()
        CloudKitHandler().saveTotalStats()
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
    
    func showPurchaseScreen() {
        let iAPVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "iAPVC") as! InAppPurchaseViewController
        self.addChild(iAPVC)
        iAPVC.view.frame = self.view.frame
        self.view.addSubview(iAPVC.view)
        iAPVC.didMove(toParent: self)
    }
    // Show iAPVC as popup
    
    func revealAnimate() {
        self.backgroundView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.backgroundView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.backgroundView.alpha = 1.0
        })
    }
    
    @objc func resetNotificiationKeyReceived(_ notification: Notification) {
        resetData()
        userSettings()
        loadData()
        if parallaxSetting! {
            addParallaxToView()
        }
        premiumTableView.reloadData()
        settingsTableView.reloadData()
    }
    
    @objc func returnNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow(animated: false)
        if parallaxSetting! {
            addParallaxToView()
        }
        premiumTableView.reloadData()
        settingsTableView.reloadData()
    }
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow(animated: true)
        premiumTableView.reloadData()
        settingsTableView.reloadData()
    }
    
    @objc func reanimateNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow(animated: false)
        if parallaxSetting! {
            addParallaxToView()
        }
        premiumTableView.reloadData()
        settingsTableView.reloadData()
        revealAnimate()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        premiumTableViewHideShow(animated: true)
        premiumTableView.reloadData()
        settingsTableView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}

extension Notification.Name {
    public static let resetNotificiation = Notification.Name(rawValue: "resetNotificiation")
    public static let returnNotificiation = Notification.Name(rawValue: "returnNotificiation")
    public static let reanimateNotificiation = Notification.Name(rawValue: "reanimateNotificiation")
    public static let iAPcompleteNotification = Notification.Name(rawValue: "iAPcompleteNotification")
}
// Notification setup for sending information from the pause menu popup to unpause the game

