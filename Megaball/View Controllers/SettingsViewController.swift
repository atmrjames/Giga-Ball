//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

enum device {
    case Pad
    case X
    case Eight
    case SE
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
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
    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    var packStatsArray: [PackStats] = []
    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
    var screenSize: device?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBOutlet var backgroundViewLeading: NSLayoutConstraint!
    @IBOutlet var backgroundViewTop: NSLayoutConstraint!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetNotificiationKeyReceived), name: .resetNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has selected to reset the game data
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnNotificiationKeyReceived), name: .returnNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the warning pop-up
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup

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
        if parallaxSetting! {
            addParallaxToView()
        }
        if navigatedFrom! == "MainMenu" {
            setBlur()
        }
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if navigatedFrom! == "PauseMenu" {
            return 9
        } else {
            return 12
        }
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        settingsTableView.rowHeight = 70.0
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cell.iconImage.isHidden = false
        
        switch indexPath.row {
        case 0:
        // Premium
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
        case 1:
        // Ads
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
        // Sounds
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
        case 3:
        // Music
            cell.settingDescription.text = "Music"
            cell.centreLabel.text = ""
            cell.iconImage.image = UIImage(named:"iconMusic.png")!
            if musicSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 4:
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
        case 5:
        // Parallax
            cell.settingDescription.text = "Parallax"
            cell.centreLabel.text = ""
            cell.iconImage.image = UIImage(named:"iconParallax.png")!
            if parallaxSetting! {
                cell.settingState.text = "on"
                cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            } else {
                cell.settingState.text = "off"
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
        case 6:
        // Paddle sensitivity
            cell.settingDescription.text = "Paddle Sensitivity"
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
        case 7:
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
        case 8:
            if navigatedFrom! != "PauseMenu" {
            // Reset game data
                cell.settingDescription.text = ""
                cell.centreLabel.text = "Reset Game Data"
                cell.settingState.text = ""
                cell.iconImage.isHidden = true
                cell.centreLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
            } else {
            // Kill ball
                cell.settingDescription.text = ""
                cell.settingState.text = ""
                cell.centreLabel.text = "Reset Ball"
                cell.iconImage.isHidden = true
                cell.centreLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
            }
        case 9:
        // Restore purchases
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Restore Purchases"
            cell.settingState.text = ""
            cell.iconImage.isHidden = true
            cell.centreLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        
        case 10:
        // Unlock all
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Unlock All Items"
            cell.settingState.text = ""
            cell.iconImage.isHidden = true
            cell.centreLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
            
        case 11:
        // Re-lock all
            cell.settingDescription.text = ""
            cell.centreLabel.text = "Reset All Unlocked Items"
            cell.settingState.text = ""
            cell.iconImage.isHidden = true
            cell.centreLabel.textColor = #colorLiteral(red: 0.9936862588, green: 0.3239051104, blue: 0.3381963968, alpha: 1)
        default:
            print("Error: Out of range")
            break
        }
        tableView.showsVerticalScrollIndicator = false
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    // Add content to cells
    
    func hideCell(cell: SettingsTableViewCell) {
        cell.settingDescription.text = ""
        cell.centreLabel.text = ""
        cell.settingState.text = ""
        settingsTableView.rowHeight = 0.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
        // Premium
            premiumSetting = !premiumSetting!
            defaults.set(adsSetting!, forKey: "premiumSetting")
            if premiumSetting == true {
                adsSetting = false
            } else {
                adsSetting = true
            }
            defaults.set(adsSetting!, forKey: "adsSetting")
        case 1:
        // Ads
            adsSetting = !adsSetting!
            defaults.set(adsSetting!, forKey: "adsSetting")
        case 2:
        // Sounds
            soundsSetting = !soundsSetting!
            defaults.set(soundsSetting!, forKey: "soundsSetting")
        case 3:
        // Music
            musicSetting = !musicSetting!
            defaults.set(musicSetting!, forKey: "musicSetting")
        case 4:
        // Haptics
            hapticsSetting = !hapticsSetting!
            defaults.set(hapticsSetting!, forKey: "hapticsSetting")
        case 5:
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
        case 6:
        // Paddle sensitivity
            paddleSensitivitySetting = paddleSensitivitySetting!+1
            if paddleSensitivitySetting! > 4 {
                paddleSensitivitySetting = 0
            }
            defaults.set(paddleSensitivitySetting!, forKey: "paddleSensitivitySetting")
        case 7:
        // Swipe up pause
            swipeUpPause = !swipeUpPause!
            defaults.set(swipeUpPause!, forKey: "swipeUpPause")
        case 8:
            if navigatedFrom! != "PauseMenu" {
            // Reset game data
                showWarning(senderID: "resetData")
            } else {
            // Kill ball
                showWarning(senderID: "killBall")
            }
        case 9:
        // Restore purchases
            print("Restore purchases")
        case 10:
        // Unlock all
            unlockAllItems()
        case 11:
        // Re-lock all
            relockAllItems()
        default:
            print("out of range")
            break
        }
        
        UIView.animate(withDuration: 0.2) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func unlockAllItems() {
        totalStatsArray[0].levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray.map { _ in true }
        totalStatsArray[0].ballUnlockedArray = totalStatsArray[0].ballUnlockedArray.map { _ in true }
        totalStatsArray[0].paddleUnlockedArray = totalStatsArray[0].paddleUnlockedArray.map { _ in true }
        totalStatsArray[0].appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray.map { _ in true }
        totalStatsArray[0].brickUnlockedArray = totalStatsArray[0].brickUnlockedArray.map { _ in true }
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
        print("unlock all items")
        GameCenterHandler().saveCloudData()
        // Save to iCloud
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
        print("relock all items)")
        GameCenterHandler().saveCloudData()
        // Save to iCloud
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.settingsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        if navigatedFrom! == "PauseMenu" {
            NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
        } else if navigatedFrom! == "MainMenu" {
            NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
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
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            do {
                packStatsArray = try decoder.decode([PackStats].self, from: packData)
            } catch {
                print("Error decoding pack stats array, \(error)")
            }
        }
        // Load the pack stats array from the NSCoder data store
        
        if let levelData = try? Data(contentsOf: levelStatsStore!) {
            do {
                levelStatsArray = try decoder.decode([LevelStats].self, from: levelData)
            } catch {
                print("Error decoding level stats array, \(error)")
            }
        }
        // Load the level stats array from the NSCoder data store
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
        statsCollapseSetting = false
        defaults.set(statsCollapseSetting!, forKey: "statsCollapseSetting")
        swipeUpPause = true
        defaults.set(swipeUpPause!, forKey: "swipeUpPause")
        
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
        
        for i in 1...packStatsArray.count {
            let index = i-1
            packStatsArray[index].scores.removeAll()
            packStatsArray[index].scoreDates.removeAll()
            packStatsArray[index].numberOfCompletes = 0
            packStatsArray[index].bestTime = 0
        }
        do {
            let data = try encoder.encode(self.packStatsArray)
            try data.write(to: packStatsStore!)
        } catch {
            print("Error encoding pack stats array, \(error)")
        }
        
        for i in 1...levelStatsArray.count {
            let index = i-1
            levelStatsArray[index].scores.removeAll()
            levelStatsArray[index].scoreDates.removeAll()
            levelStatsArray[index].numberOfCompletes = 0
        }
        do {
            let data = try encoder.encode(self.levelStatsArray)
            try data.write(to: levelStatsStore!)
        } catch {
            print("Error encoding level stats array, \(error)")
        }
        // Reset game data
        
        GameCenterHandler().deleteCloudData()
        // Delete cloud data
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
            } else {
            print("App icon changed successfully")
            }
            // Print success or error
        })
    }
    
    @objc func resetNotificiationKeyReceived(_ notification: Notification) {
        resetData()
        userSettings()
        loadData()
        if parallaxSetting! {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
    @objc func returnNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        if parallaxSetting! {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
}

extension Notification.Name {
    public static let resetNotificiation = Notification.Name(rawValue: "resetNotificiation")
    public static let returnNotificiation = Notification.Name(rawValue: "returnNotificiation")
}
// Notification setup for sending information from the pause menu popup to unpause the game
