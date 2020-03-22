//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MenuViewController: UIViewController, MenuViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    // Haptics setup
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Game view properties
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
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
    
    @IBOutlet var modeSelectTableView: UITableView!
    @IBOutlet var iconCollectionView: UICollectionView!
    @IBOutlet var logoButton: UIButton!
    
    var firstLaunch: Bool = false
    // Check if this is the first opening of the app since closing to know if to run splash screen
    
    @IBAction func logoButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToAbout()
    }
    
    @IBOutlet var bannerView: GADBannerView!
    // Ad banner view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modeSelectTableView.delegate = self
        modeSelectTableView.dataSource = self
        modeSelectTableView.register(UINib(nibName: "ModeSelectTableViewCell", bundle: nil), forCellReuseIdentifier: "modeSelectCell")
        // Levels tableView setup
        
        iconCollectionView.delegate = self
        iconCollectionView.dataSource = self
        iconCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnMenuNotificationKeyReceived), name: .returnMenuNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        
        logoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        collectionViewLayout()
        
        defaultSettings()
        
        loadData()
        modeSelectTableView.reloadData()
        iconCollectionView.reloadData()
        // Load in NSCoder data stores
        
        userSettings()
        updateAds()
        // Update user settings
        
        showSplashScreen()
        // Show splashscreen when first opening the app
    }

    override func viewWillAppear(_ animated: Bool) {
        loadData()
        modeSelectTableView.reloadData()
        iconCollectionView.reloadData()
        // Load in NSCoder data stores
        
        userSettings()
        updateAds()
        // Update user settings
    }
    
    func showSplashScreen() {
        if firstLaunch == false {
            firstLaunch = true
            let splashView = self.storyboard?.instantiateViewController(withIdentifier: "splashView") as! SplashViewController
            self.addChild(splashView)
            splashView.view.frame = self.view.frame
            self.view.addSubview(splashView.view)
            splashView.didMove(toParent: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modeSelectCell", for: indexPath) as! ModeSelectTableViewCell
                
        switch indexPath.row {
        case 0:
            cell.modeImageIcon.image = UIImage(named:"TutorialIcon.png")
            cell.modeTextLabel.text = "Tutorial"
            
        case 1:
            cell.modeImageIcon.image = UIImage(named:"ClassicIcon.png")
            cell.modeTextLabel.text = "Classic Mode"
            
        case 2:
            cell.modeImageIcon.image = UIImage(named:"EndlessIcon.png")
            cell.modeTextLabel.text = "Endless Mode"

        default:
            print("Error: Out of range")
            break
        }
        
        UIView.animate(withDuration: 0.1) {
            cell.cellView1.transform = .identity
            cell.cellView1.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        UIView.animate(withDuration: 0.1) {
            let cell = self.modeSelectTableView.cellForRow(at: indexPath) as! ModeSelectTableViewCell
            cell.cellView1.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
        }
        
        if indexPath.row == 0 {
        // Tutorial
            levelSender = "MainMenu"
            moveToGame(selectedLevel: LevelPackSetup().startLevelNumber[0], numberOfLevels: LevelPackSetup().numberOfLevels[0], sender: levelSender!, levelPack: 0)
        }
        
        if indexPath.row == 1 {
        // Level packs
            moveToPackSelector()
        }
        
        if indexPath.row == 2 {
        // Endless mode
            moveToLevelStats(startLevel: LevelPackSetup().startLevelNumber[5], levelNumber: LevelPackSetup().startLevelNumber[5], packNumber: 5)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update collection view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.modeSelectTableView.cellForRow(at: indexPath) as! ModeSelectTableViewCell
            cell.cellView1.transform = .init(scaleX: 0.95, y: 0.95)
            cell.cellView1.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.modeSelectTableView.cellForRow(at: indexPath) as! ModeSelectTableViewCell
            cell.cellView1.transform = .identity
            cell.cellView1.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        if view.frame.size.width <= 414 && iconCollectionView.frame.size.width != view.frame.size.width-100 {
            iconCollectionView.frame.size.width = view.frame.size.width-100
        }
        // Ensures the collection view is the correct size
        
        let spacing = (iconCollectionView.frame.size.width-(50*3))/2
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing

        iconCollectionView!.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        
        cell.widthConstraint.constant = 50
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonStats.png")
        case 1:
            cell.iconImage.image = UIImage(named:"ButtonRewards.png")
        case 2:
            cell.iconImage.image = UIImage(named:"ButtonSettings.png")
        default:
            print("Error: Out of range")
            break
        }
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        
        return cell        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        if indexPath.row == 0 {
            moveToStats()
        }
        if indexPath.row == 1 {
            moveToItems()
        }
        if indexPath.row == 2 {
            moveToSettings()
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.iconCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonStatsHighlighted.png")
            case 1:
                cell.iconImage.image = UIImage(named:"ButtonRewardsHighlighted.png")
            case 2:
                cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.iconCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonStats.png")
            case 1:
                cell.iconImage.image = UIImage(named:"ButtonRewards.png")
            case 2:
                cell.iconImage.image = UIImage(named:"ButtonSettings.png")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func defaultSettings() {
        defaults.register(defaults: ["adsSetting" : true])
        defaults.register(defaults: ["soundsSetting" : true])
        defaults.register(defaults: ["musicSetting" : true])
        defaults.register(defaults: ["hapticsSetting" : true])
        defaults.register(defaults: ["parallaxSetting" : true])
        defaults.register(defaults: ["paddleSensitivitySetting" : 2])
    }
    // Set default settings

    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        gameView.levelSender = sender
        gameView.levelPack = levelPack
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController
    
    func moveToPackSelector() {
        let packSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "packSelectorView") as! PackSelectViewController
        self.addChild(packSelectorView)
        packSelectorView.view.frame = self.view.frame
        self.view.addSubview(packSelectorView.view)
        packSelectorView.didMove(toParent: self)
    }
    
    func moveToLevelStats(startLevel: Int, levelNumber: Int, packNumber: Int) {
        let levelStatsView = self.storyboard?.instantiateViewController(withIdentifier: "levelStatsView") as! LevelStatsViewController
        levelStatsView.startLevel = startLevel
        levelStatsView.levelNumber = levelNumber
        levelStatsView.packNumber = packNumber
        self.addChild(levelStatsView)
        levelStatsView.view.frame = self.view.frame
        self.view.addSubview(levelStatsView.view)
        levelStatsView.didMove(toParent: self)
    }
    // Segue to LevelStatsViewController
    
    func moveToSettings() {
        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsView.navigatedFrom = "MainMenu"
        self.addChild(settingsView)
        settingsView.view.frame = self.view.frame
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
    }
    // Segue to Settings
    
    func moveToAbout() {
        let aboutView = self.storyboard?.instantiateViewController(withIdentifier: "aboutVC") as! AboutViewController
        self.addChild(aboutView)
        aboutView.view.frame = self.view.frame
        self.view.addSubview(aboutView.view)
        aboutView.didMove(toParent: self)
    }
    
    func moveToItems() {
        let itemsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsView") as! ItemsViewController
        self.addChild(itemsView)
        itemsView.view.frame = self.view.frame
        self.view.addSubview(itemsView.view)
        itemsView.didMove(toParent: self)
    }
    
    func moveToStats() {
        let statsView = self.storyboard?.instantiateViewController(withIdentifier: "statsView") as! StatsViewController
        self.addChild(statsView)
        statsView.view.frame = self.view.frame
        self.view.addSubview(statsView.view)
        statsView.didMove(toParent: self)
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
        
        if totalStatsArray.count == 0 {
            let totalStatsItem = TotalStats()
            totalStatsArray = Array(repeating: totalStatsItem, count: 1)
            do {
                let data = try encoder.encode(totalStatsArray)
                try data.write(to: totalStatsStore!)
            } catch {
                print("Error setting up total stats array, \(error)")
            }
        }
        // Fill the empty array with 0s on first opening and re-save
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            do {
                packStatsArray = try decoder.decode([PackStats].self, from: packData)
            } catch {
                print("Error decoding high score array, \(error)")
            }
        }
        // Load the pack stats array from the NSCoder data store
        
        if packStatsArray.count == 0 {
            let packStatsItem = PackStats()
            packStatsArray = Array(repeating: packStatsItem, count: 100)
            do {
                let data = try encoder.encode(packStatsArray)
                try data.write(to: packStatsStore!)
            } catch {
                print("Error setting up pack stats array, \(error)")
            }
        }
        // Fill the empty array with 0s on first opening and re-save
        
        if let levelData = try? Data(contentsOf: levelStatsStore!) {
            do {
                levelStatsArray = try decoder.decode([LevelStats].self, from: levelData)
            } catch {
                print("Error decoding level stats array, \(error)")
            }
        }
        // Load the level stats array from the NSCoder data store
        
        if levelStatsArray.count == 0 {
            let levelStatsItem = LevelStats()
            levelStatsArray = Array(repeating: levelStatsItem, count: 500)
            do {
                let data = try encoder.encode(levelStatsArray)
                try data.write(to: levelStatsStore!)
            } catch {
                print("Error setting up level stats array, \(error)")
            }
        }
        // Fill the empty array with blank items on first opening and re-save
    }
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
    }
    
    func updateAds() {
        if defaults.bool(forKey: "adsSetting") {
            bannerView.isHidden = false
            bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
            bannerView.rootViewController = self
            // Configure banner ad
            
//            settingsButtonNoAds.priority = UILayoutPriority(rawValue: 250)
//            settingsButtonAds.priority = UILayoutPriority(rawValue: 999)
//            settingsButtonNoAds.isActive = false
//            settingsButtonAds.isActive = true
            bannerView.load(GADRequest())
            // Load banner ad
        } else {
            bannerView.isHidden = true
            
//            settingsButtonAds.priority = UILayoutPriority(rawValue: 250)
//            settingsButtonNoAds.priority = UILayoutPriority(rawValue: 999)
//            settingsButtonAds.isActive = false
//            settingsButtonNoAds.isActive = true
        }
    }
    // Show or hide banner ad depending on setting
    
    @objc func returnMenuNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        updateAds()
        modeSelectTableView.reloadData()
        iconCollectionView.reloadData()
    }
}

extension Notification.Name {
    public static let returnMenuNotification = Notification.Name(rawValue: "returnMenuNotification")
}
// Notification setup
