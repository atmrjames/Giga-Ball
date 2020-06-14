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
    // User settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    var packStatsArray: [PackStats] = []
    var levelStatsArray: [LevelStats] = []
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
    
    
//    @IBAction func itemsTitleButton(_ sender: Any) {
//        if hapticsSetting! {
//            interfaceHaptic.impactOccurred()
//        }
//        itemsTableView.setContentOffset(.zero, animated: true)
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnItemStatsNotificationKeyReceived), name: .returnItemStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        var unlockedCount: Int = 0
        var arrayCount: Int = 0
        
        switch senderID {
        case 0:
            unlockedCount = LevelPackSetup().appIconUnlockedArray.filter{$0 == true}.count
            arrayCount = LevelPackSetup().appIconUnlockedArray.count
            titleLabel.text = "APP ICONS"
        case 1:
            unlockedCount = LevelPackSetup().powerUpUnlockedArray.filter{$0 == true}.count
            arrayCount = LevelPackSetup().powerUpUnlockedArray.count
            titleLabel.text = "POWER-UPS"
        case 2:
            unlockedCount = LevelPackSetup().ballUnlockedArray.filter{$0 == true}.count
            arrayCount = LevelPackSetup().ballUnlockedArray.count
            titleLabel.text = "BALLS"
        case 3:
            unlockedCount = LevelPackSetup().paddleUnlockedArray.filter{$0 == true}.count
            arrayCount = LevelPackSetup().paddleUnlockedArray.count
            titleLabel.text = "PADDLES"
        case 4:
            unlockedCount = LevelPackSetup().brickUnlockedArray.filter{$0 == true}.count
            arrayCount = LevelPackSetup().brickUnlockedArray.count
            titleLabel.text = "BRICKS"
        case 5:
            unlockedCount = 0
            arrayCount = 0
            titleLabel.text = "ACHIEVEMENTS"
        default:
            break
        }
        
        unlockedLabel.text = "UNLOCKED: \(unlockedCount)/\(arrayCount)"
        
        itemsTableView.rowHeight = 70.0
        
        userSettings()
        loadData()
        if parallaxSetting! {
            addParallax()
        }
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if senderID == 0 {
        // App icons
            return LevelPackSetup().appIconUnlockedArray.count
        } else if senderID == 1 {
        // Power-ups
            return LevelPackSetup().powerUpUnlockedArray.count
        } else if senderID == 2 {
        // Balls
            return LevelPackSetup().ballUnlockedArray.count
        } else if senderID == 3 {
        // Paddles
            return LevelPackSetup().paddleUnlockedArray.count
        } else if senderID == 4 {
        // Bricks
            return LevelPackSetup().brickUnlockedArray.count
        } else if senderID == 4 {
        // Achievements
            return 2
        } else {
        // default
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        cell.blurView.isHidden = true
        cell.lockedImageView.isHidden = true
        
        if senderID == 0 {
        // App icons
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
            if LevelPackSetup().appIconUnlockedArray[indexPath.row] == false {
                cell.settingDescription.text = "Locked"
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
        // Power-ups
            cell.iconImage.image = LevelPackSetup().powerUpImageArray[indexPath.row]
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.settingDescription.text = LevelPackSetup().powerUpNameArray[indexPath.row]
            cell.centreLabel.text = ""
                        
            if totalStatsArray[0].powerupsGenerated.count < indexPath.row-1 {
                totalStatsArray[0].powerupsGenerated.append(0)
            }
            if totalStatsArray[0].powerupsCollected.count < indexPath.row-1 {
                totalStatsArray[0].powerupsCollected.append(0)
            }

            if totalStatsArray[0].powerupsGenerated[indexPath.row] > 0 {
                let powerUpCollectionRate: Double = Double(totalStatsArray[0].powerupsCollected[indexPath.row]) / Double(totalStatsArray[0].powerupsGenerated[indexPath.row])
                cell.settingState.text = String(format:"%.0f", (powerUpCollectionRate * 100)) + "%"
                cell.settingState.textColor = #colorLiteral(red: 0.6039215686, green: 0.6039215686, blue: 0.6039215686, alpha: 1)
            } else {
                cell.settingState.text = ""
            }
            // Shows collection percentage stat
            
            if LevelPackSetup().powerUpUnlockedArray[indexPath.row] == false {
                cell.settingDescription.text = "Locked"
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
        
        if senderID == 2 {
        // Balls
            cell.iconImage.image = LevelPackSetup().ballIconArray[indexPath.row]
            cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
            cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.settingDescription.text = LevelPackSetup().ballNameArray[indexPath.row]
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.tickImage.isHidden = true
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            if ballSetting == indexPath.row {
                cell.tickImage.isHidden = false
            }
            
            if LevelPackSetup().ballUnlockedArray[indexPath.row] == false {
                cell.settingDescription.text = "Locked"
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
        
        if senderID == 3 {
        // Paddles
            cell.iconImage.image = LevelPackSetup().paddleIconArray[indexPath.row]
            cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
            cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.settingDescription.text = LevelPackSetup().paddleNameArray[indexPath.row]
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.tickImage.isHidden = true
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            if paddleSetting == indexPath.row {
                cell.tickImage.isHidden = false
            }
            
            if LevelPackSetup().paddleUnlockedArray[indexPath.row] == false {
                cell.settingDescription.text = "Locked"
                cell.settingState.text = ""
                cell.blurView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.lockedImageView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.blurView.layer.masksToBounds = true
                cell.lockedImageView.layer.masksToBounds = true
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked paddles hidden until unlocked
            
        }
        
        if senderID == 4 {
        // Bricks
            cell.iconImage.image = LevelPackSetup().brickIconArray[indexPath.row]
            cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
            cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.settingDescription.text = LevelPackSetup().brickNameArray[indexPath.row]
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.blurView.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.lockedImageView.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.blurView.layer.masksToBounds = true
            cell.lockedImageView.layer.masksToBounds = true
            cell.tickImage.isHidden = true
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            if brickSetting == indexPath.row {
                cell.tickImage.isHidden = false
            }
                        
            if LevelPackSetup().brickUnlockedArray[indexPath.row] == false {
                cell.settingDescription.text = "Locked"
                cell.settingState.text = ""
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked paddles hidden until unlocked
        }
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
//            if cell.tickImage.isHidden == false {
//                cell.cellView2.backgroundColor = #colorLiteral(red: 0.7702723742, green: 1, blue: 0, alpha: 1)
//            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        UIView.animate(withDuration: 0.2) {
            let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        if senderID == 0 {
        // App icon
            if LevelPackSetup().appIconUnlockedArray[indexPath.row] {
                appIconSetting = indexPath.row
                defaults.set(appIconSetting!, forKey: "appIconSetting")
                changeIcon(to: LevelPackSetup().appIconNameArray[indexPath.row])
            }
            // Don't allow selection if app icon is locked
        }
        
        if senderID == 1 {
        // Power-ups
            if LevelPackSetup().powerUpUnlockedArray[indexPath.row] {
                hideAnimate()
                moveToItemStats(powerUpIndex: indexPath.row)
            }
            // Don't allow into menu if power-up is locked
        }
        
        if senderID == 2 {
        // Ball selection
            if LevelPackSetup().ballUnlockedArray[indexPath.row] {
                ballSetting = indexPath.row
                defaults.set(ballSetting!, forKey: "ballSetting")
            }
            // Don't allow selection if ball is locked
        }
        
        if senderID == 3 {
        // Paddle selection
            paddleSetting = indexPath.row
            defaults.set(paddleSetting!, forKey: "paddleSetting")
        }
        
        if senderID == 4 {
        // Brick selection
            brickSetting = indexPath.row
            defaults.set(brickSetting!, forKey: "brickSetting")
        }

        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
            } else {
            print("App icon changed successfully")
            }
            // Print success or error
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
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        removeAnimate()
        NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
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
    
    func moveToItemStats(powerUpIndex: Int) {
        let itemStatsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsStatsView") as! ItemsStatsViewController
        itemStatsView.powerUpIndex = powerUpIndex
        self.addChild(itemStatsView)
        itemStatsView.view.frame = self.view.frame
        self.view.addSubview(itemStatsView.view)
        itemStatsView.didMove(toParent: self)
    }
    
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
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            do {
                packStatsArray = try decoder.decode([PackStats].self, from: packData)
            } catch {
                print("Error decoding high score array, \(error)")
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
}

extension Notification.Name {
    public static let returnItemStatsNotification = Notification.Name(rawValue: "returnItemStatsNotification")
}
// Notification setup
