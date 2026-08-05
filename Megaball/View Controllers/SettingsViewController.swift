//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import CoreHaptics

enum device {
    case Pad
    case X
    case Eight
    case SE
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var navigatedFrom: String?
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    var ballSetting: Int = 0
    var paddleSetting: Int = 0
    var brickSetting: Int = 0
    var appIconSetting: Int = 0
    var backgroundSetting: Int = 0
    var statsCollapseSetting: Bool = true
    var swipeUpPause: Bool = true
    var appOpenCount: Int = 0
    var firstPause: Bool = true
    // User settings
    var savedGame: SavedGame?
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
    
    var musicPausedBool: Bool = false
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetNotificiationKeyReceived), name: .resetNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has selected to reset the game data
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnNotificiationKeyReceived), name: .returnNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the warning pop-up
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reanimateNotificiationKeyReceived), name: .reanimateNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another screen
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        let screenRatio = self.view.frame.size.height/self.view.frame.size.width
        
        if screenRatio > 2 {
            screenSize = .X
        } else if screenRatio < 1.7  {
            screenSize = .Pad
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
        settingsTableView.isHidden = false
        // TableView setup
        
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        if navigatedFrom! == "MainMenu" {
            setBlur()
        }
        backButtonCollectionView.reloadData()
        settingsTableView.reloadData()
        DispatchQueue.main.async {
             self.settingsTableView.reloadData()
        }
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    
    /// Whether this device can produce haptics at all.
    ///
    /// iPads have no taptic engine, so the setting is offered and does nothing. Asked of
    /// CoreHaptics rather than inferred from the idiom, which would be a guess that goes
    /// stale the moment Apple ships an iPad that can.
    static let deviceHasHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    /// The app icon and the ball and paddle theme, which the pause menu does not offer.
    ///
    /// Both restyle a game already in progress, and both lead into a picker that does not
    /// belong over live gameplay. They are dropped from the front of the list rather than
    /// hidden in place, which would leave two blank rows where they used to be.
    /// The settings this screen offers, in order, already filtered to what applies.
    enum SettingRow: Int {
        case appIcon, theme, sounds, music, haptics, background, perspective
        case paddleSpeed, swipeUpToPause, reset
    }

    var settingRows: [SettingRow] {
        var rows: [SettingRow] = [.appIcon, .theme]
        if navigatedFrom == "PauseMenu" { rows = [] }
        // The app icon and the ball and paddle theme restyle a game already in progress,
        // and open a picker that does not belong over live gameplay

        rows += [.sounds, .music]
        if SettingsViewController.deviceHasHaptics { rows.append(.haptics) }
        rows += [.background, .perspective, .paddleSpeed, .swipeUpToPause]

        if navigatedFrom == "PauseMenu" { rows.append(.reset) }
        // Reset Ball from the pause menu, which works. From the main menu the same row is
        // Reset Game Data, which was never implemented

        return rows
    }



    /// The row as the switches below number them, which is the main menu's numbering.
    private func settingRow(for indexPath: IndexPath) -> Int {
        settingRows[indexPath.row].rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return settingRows.count
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    
            let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
            settingsTableView.rowHeight = 70.0
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.iconImage.isHidden = false
            
            switch settingRow(for: indexPath) {

            case 0:
            // App icon
//                if navigatedFrom! == "PauseMenu" {
//                    hideCell(cell: cell)
//                    cell.isHidden = true
//                } else {
                    cell.settingDescription.text = "App Icon"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconAppIcon.png")!
                    cell.settingState.text = ""
//                }
            case 1:
            // Theme
//                if navigatedFrom! == "PauseMenu" {
//                    hideCell(cell: cell)
//                } else {
                    cell.settingDescription.text = "Ball & Paddle Theme"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconTheme.png")!
                    cell.settingState.text = ""
//                }
            case 2:
            // Sounds
                cell.settingDescription.text = "Sounds"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconSound.png")!
                if soundsSetting {
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
                if musicSetting {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 4:
            // Haptics
//                if screenSize == .Pad || screenSize == .SE {
//                // No haptics engine
//                    hideCell(cell: cell)
//                } else {
                    cell.settingDescription.text = "Haptics"
                    cell.centreLabel.text = ""
                    cell.iconImage.image = UIImage(named:"iconHaptics.png")!
                    if hapticsSetting {
                        cell.settingState.text = "on"
                        cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                    } else {
                        cell.settingState.text = "off"
                        cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                    }
//                }
            case 5:
            // Game background
                cell.settingDescription.text = "Game Background"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconBackground.png")!
                cell.settingState.text = LevelPackSetup().backgroundNameArray[backgroundSetting]
                cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            case 6:
            // Parallax
                cell.settingDescription.text = "Perspective Zoom"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconParallax.png")!
                if parallaxSetting {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 7:
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
            case 8:
            // Swipe up to pause
                cell.settingDescription.text = "Swipe Up To Pause"
                cell.centreLabel.text = ""
                cell.iconImage.image = UIImage(named:"iconPause.png")!
                if swipeUpPause {
                    cell.settingState.text = "on"
                    cell.settingState.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                } else {
                    cell.settingState.text = "off"
                    cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            case 9:
//                if navigatedFrom! = "PauseMenu" {
                // Reset game data
//                    hideCell(cell: cell)
//                    cell.settingDescription.text = ""
//                    cell.centreLabel.text = "Reset All Game Data (developer)"
//                    cell.settingState.text = ""
//                    cell.iconImage.isHidden = true
//                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
//                } else {
                // Kill ball
                    cell.settingDescription.text = ""
                    cell.settingState.text = ""
                    cell.centreLabel.text = "Reset Ball"
                    cell.iconImage.isHidden = true
                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
//                }
            default:
                Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                break
            }
        
        cell.isHidden = false
        // Rows that are not offered are left out of the list instead - see
        // settingRows. Still reset here, or a cell reused from when this did hide rows
        // would come back invisible

        
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            return cell
//        }
    }
    // Add content to cells
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var rowHeight:CGFloat = 0

        if navigatedFrom! != "PauseMenu" {
            if (indexPath.row == 8) {
                rowHeight = 0
            } else {
                rowHeight = 70.0
            }
        }
//        }
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            switch settingRow(for: indexPath) {
            case 0:
            // App icon
                hideAnimate()
                moveToItemDetails(senderID: 0)
            case 1:
            // Theme
                hideAnimate()
                moveToItemDetails(senderID: 1)
            case 2:
            // Sounds
                soundsSetting = !soundsSetting
                defaults.set(soundsSetting, forKey: "soundsSetting")
            case 3:
            // Music
                musicSetting = !musicSetting
//                soundsSetting = musicSetting
                defaults.set(musicSetting, forKey: "musicSetting")
//                defaults.set(soundsSetting, forKey: "soundsSetting")
                if musicSetting {
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
            case 4:
            // Haptics
                hapticsSetting = !hapticsSetting
                defaults.set(hapticsSetting, forKey: "hapticsSetting")
            case 5:
            // Game background
                backgroundSetting = backgroundSetting + 1
                if backgroundSetting >= LevelPackSetup().backgroundNameArray.count {
                    backgroundSetting = 0
                }
                defaults.set(backgroundSetting, forKey: "backgroundSetting")
                NotificationCenter.default.post(name: .backgroundSettingChanged, object: nil)
                // The scene is live behind the pause menu, so it repaints rather than
                // waiting for the next level
            case 6:
            // Parallax
                parallaxSetting = !parallaxSetting
                defaults.set(parallaxSetting, forKey: "parallaxSetting")
                if parallaxSetting {
                    addParallaxToView()
                } else if parallaxSetting == false {
                    if group != nil {
                        backgroundView.removeMotionEffect(group!)
                    }
                }
            case 7:
            // Paddle sensitivity
                paddleSensitivitySetting = paddleSensitivitySetting+1
                if paddleSensitivitySetting > 4 {
                    paddleSensitivitySetting = 0
                }
                defaults.set(paddleSensitivitySetting, forKey: "paddleSensitivitySetting")
            case 8:
            // Swipe up pause
                swipeUpPause = !swipeUpPause
                defaults.set(swipeUpPause, forKey: "swipeUpPause")
            case 9:
                if navigatedFrom! != "PauseMenu" {
                // Reset game data
                    showWarning(senderID: "resetData")
                } else {
                // Kill ball
                    showWarning(senderID: "killBall")
                }
//            case 11:
//            // Restore purchases
//                showPurchaseScreen()
//                GigaBallProducts.store.restorePurchases()
//            case 12:
//            // Unlock all
//                unlockAllItems()
//            case 13:
//            // Re-lock all
//                relockAllItems()
            default:
                break
            }
            
            CloudKitHandler().saveToiCloud()
            // Save any changes to NSUbiquitousKeyValueStore
            
            if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
                UIView.animate(withDuration: 0.2) {
                    cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                    cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
//        }
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
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        CloudKitHandler().saveToiCloud()
    }
    
    func relockAllItems() {
        ballSetting = 0
        defaults.set(ballSetting, forKey: "ballSetting")
        paddleSetting = 0
        defaults.set(paddleSetting, forKey: "paddleSetting")
        brickSetting = 0
        defaults.set(brickSetting, forKey: "brickSetting")
        if appIconSetting != 0 {
            appIconSetting = 0
            defaults.set(appIconSetting, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[0])
        }
        
        totalStatsArray[0] = TotalStats()
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        CloudKitHandler().saveDataReset()
        // Save to iCloud
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            if settingRow(for: indexPath) != 4 {
                interfaceHaptic.impactOccurred()
            }
        } else {
            if settingRow(for: indexPath) == 4 {
                interfaceHaptic.impactOccurred()
            }
        }
        
        if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            if settingRow(for: indexPath) != 4 {
                interfaceHaptic.impactOccurred()
            }
        } else {
            if settingRow(for: indexPath) == 4 {
                interfaceHaptic.impactOccurred()
            }
        }
        if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
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
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.iconImage.image = UIImage(named:"ButtonClose.png")
            }
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
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
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
        backgroundSetting = defaults.integer(forKey: "backgroundSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
        swipeUpPause = defaults.bool(forKey: "swipeUpPause")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        firstPause = defaults.bool(forKey: "firstPause")
        // User settings
        
        savedGame = SavedGame.load()
        // Game save settings
    }
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeAchievementArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        // Load the total stats array from the NSCoder data store
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
        soundsSetting = true
        defaults.set(soundsSetting, forKey: "soundsSetting")
        musicSetting = true
        defaults.set(musicSetting, forKey: "musicSetting")
        hapticsSetting = true
        defaults.set(hapticsSetting, forKey: "hapticsSetting")
        parallaxSetting = true
        defaults.set(parallaxSetting, forKey: "parallaxSetting")
        if view.frame.size.width > 450 {
            paddleSensitivitySetting = 3
        } else {
            paddleSensitivitySetting = 2
        }
        defaults.set(paddleSensitivitySetting, forKey: "paddleSensitivitySetting")
        
        gameCenterSetting = false
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
        ballSetting = 0
        defaults.set(ballSetting, forKey: "ballSetting")
        paddleSetting = 0
        defaults.set(paddleSetting, forKey: "paddleSetting")
        brickSetting = 0
        defaults.set(brickSetting, forKey: "brickSetting")
        if appIconSetting != 0 {
            appIconSetting = 0
            defaults.set(appIconSetting, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[0])
        }
        statsCollapseSetting = true
        defaults.set(statsCollapseSetting, forKey: "statsCollapseSetting")
        swipeUpPause = true
        defaults.set(swipeUpPause, forKey: "swipeUpPause")
        appOpenCount = 0
        defaults.set(appOpenCount, forKey: "appOpenCount")
        firstPause = true
        defaults.set(firstPause, forKey: "firstPause")
        
        savedGame = nil
        SavedGame.clear()
        // Reset user settings to defaults
        
        totalStatsArray[0] = TotalStats()
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            totalStatsArray[0].dateSaved = Date()
            try data.write(to: totalStatsStore!)
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        CloudKitHandler().saveDataReset()
    }
    
    func changeIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        // Check app supports alternate icons

        UIApplication.shared.setAlternateIconName(iconName, completionHandler: { (error) in
        // Change the icon to an image with specific name
            if let error = error {
            Log.ui.error("App icon failed to change due to \(error.localizedDescription, privacy: .public)")
            }
        })
    }
    
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
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
    @objc func returnNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
    @objc func reanimateNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
        revealAnimate()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        settingsTableView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}

extension Notification.Name {
    public static let resetNotificiation = Notification.Name(rawValue: "resetNotificiation")
    public static let returnNotificiation = Notification.Name(rawValue: "returnNotificiation")
    public static let reanimateNotificiation = Notification.Name(rawValue: "reanimateNotificiation")
}
// Notification setup for sending information from the pause menu popup to unpause the game

