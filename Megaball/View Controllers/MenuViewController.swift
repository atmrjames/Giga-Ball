//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds

class MenuViewController: UIViewController, MenuViewControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    @IBOutlet var levelPackCollectionView: UICollectionView!
    // Collection view
    
    var firstLaunch: Bool = false
    // Check if this is the first opening of the app since closing to know if to run splash screen
    
    var cellSize: CGFloat?
    var cellSpacing: CGFloat?
    var layout: UICollectionViewFlowLayout?
    var currentPage: Float = 0
    // Collection view handlers

    var tutorialImage: UIImage?
    var starterImage: UIImage?
    var spaceImage: UIImage?
    // Collection view images
    
    @IBAction func settingsButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToSettings()
    }
    @IBAction func megaballLogoButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToAbout()
    }
    @IBAction func itemsButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToItems()
    }
    @IBAction func statsButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToStats()
    }
    // Button setup
    
    @IBOutlet var settingsButtonNoAds: NSLayoutConstraint!
    @IBOutlet var settingsButtonAds: NSLayoutConstraint!
    // Constraints
    
    @IBOutlet var bannerView: GADBannerView!
    // Ad banner view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        levelPackCollectionView.delegate = self
        levelPackCollectionView.dataSource = self
        // Setup collection view delegates
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnMenuNotificationKeyReceived), name: .returnMenuNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        levelPackCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "customMainCell")
        cellSize = view.frame.width*0.67
        cellSpacing = 0
        collectionViewCellSetup()
        // Setup custom cells
        
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        
        defaultSettings()
        
        loadData()
        levelPackCollectionView.reloadData()
        // Load in NSCoder data stores
        
        userSettings()
        updateAds()
        // Update user settings
        
        showSplashScreen()
        // Show splashscreen when first opening the app
    }

    override func viewWillAppear(_ animated: Bool) {
        loadData()
        levelPackCollectionView.reloadData()
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
    
    func collectionViewCellSetup() {
        layout = levelPackCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        layout!.itemSize = CGSize(width: cellSize!, height: cellSize!)
        layout!.minimumLineSpacing = cellSpacing!
        layout!.scrollDirection = .horizontal
        layout!.headerReferenceSize = CGSize(width: view.frame.width * 0.33/2, height: 0)
        layout!.footerReferenceSize = CGSize(width: view.frame.width * 0.33/2, height: 0)
        levelPackCollectionView!.collectionViewLayout = layout!
        levelPackCollectionView?.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        let pageWidth = Float(levelPackCollectionView!.frame.size.width)
        let xCurrentOffset = Float(levelPackCollectionView!.contentOffset.x)
        currentPage = floor((xCurrentOffset - pageWidth / 2) / pageWidth) + 1
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        let pageWidth = Float(cellSize! + cellSpacing!)
        let targetXContentOffset = Float(targetContentOffset.pointee.x)
        let newPage = roundf(targetXContentOffset / pageWidth)
        let targetOffsetX = CGFloat(newPage * pageWidth)
        let point = CGPoint (x: targetOffsetX, y: targetContentOffset.pointee.y)
        targetContentOffset.pointee = point
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customMainCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.highscoreLabel.isHidden = false
        cell.purchaseLabel.isHidden = false
        
        switch indexPath.row {
        case 0:
            cell.purchaseLabel.isHidden = true
            
        case 1:
            cell.purchaseLabel.isHidden = true
        case 2:
            cell.purchaseLabel.isHidden = true
        case 3:
            cell.purchaseLabel.isHidden = true
        case 4:
            cell.purchaseLabel.isHidden = true
        case 5:
            if totalStatsArray[0].endlessModeDepth.count > 0 {
                cell.purchaseLabel.text = "Depth: " + String(totalStatsArray[0].endlessModeDepth.max()!) + " m"
            } else {
                cell.purchaseLabel.text = "Depth: 0 m"
            }

        default:
            print("Error: Out of range")
            break
        }
        
        cell.cellLabel.text = LevelPackSetup().packTitles[indexPath.row]
        cell.subView.tag = indexPath.row
        // Identify the cells
        
        if packStatsArray[indexPath.row].scores.count != 0 {
            cell.highscoreLabel.text = String(packStatsArray[indexPath.row].scores.max()!)
        } else {
            cell.highscoreLabel.text = "0"
        }
        // Display the corresponding highscore
        
        UIView.animate(withDuration: 0.1) {
            cell.subView.transform = .identity
            cell.subView.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        UIView.animate(withDuration: 0.1) {
            let cell = self.levelPackCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.subView.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
        }
        
        if indexPath.row == 0 {
        // Tutorial
            levelSender = "MainMenu"
            moveToGame(selectedLevel: LevelPackSetup().startLevelNumber[indexPath.row], numberOfLevels: LevelPackSetup().numberOfLevels[indexPath.row], sender: levelSender!, levelPack: indexPath.row)
        }
        
        if indexPath.row > 0 && indexPath.row <= 2 {
        // Level packs
            moveToLevelSelector(packNumber: indexPath.row, numberOfLevels: LevelPackSetup().numberOfLevels[indexPath.row], startLevel: LevelPackSetup().startLevelNumber[indexPath.row])
        }
        
        if indexPath.row == 5 {
        // Endless mode
            moveToLevelStats(startLevel: LevelPackSetup().startLevelNumber[indexPath.row], levelNumber: LevelPackSetup().startLevelNumber[indexPath.row], packNumber: indexPath.row)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
        // Update collection view
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.levelPackCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.subView.transform = .init(scaleX: 0.95, y: 0.95)
            cell.subView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.levelPackCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.subView.transform = .identity
            cell.subView.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
            
            settingsButtonNoAds.priority = UILayoutPriority(rawValue: 250)
            settingsButtonAds.priority = UILayoutPriority(rawValue: 999)
            settingsButtonNoAds.isActive = false
            settingsButtonAds.isActive = true
            bannerView.load(GADRequest())
            // Load banner ad
        } else {
            bannerView.isHidden = true
            
            settingsButtonAds.priority = UILayoutPriority(rawValue: 250)
            settingsButtonNoAds.priority = UILayoutPriority(rawValue: 999)
            settingsButtonAds.isActive = false
            settingsButtonNoAds.isActive = true
        }
    }
    // Show or hide banner ad depending on setting
    
    @objc func returnMenuNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        updateAds()
        levelPackCollectionView.reloadData()
    }
}

extension Notification.Name {
    public static let returnMenuNotification = Notification.Name(rawValue: "returnMenuNotification")
}
// Notification setup
