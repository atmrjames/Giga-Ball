//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds
import GameKit
import StoreKit

class MenuViewController: UIViewController, MenuViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    // Haptics setup
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Game view properties
    
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
    var gameInProgress: Bool?
    var resumeGameToLoad: Bool?
    var iCloudSetting: Bool?
    var firstPause: Bool?
    // User settings
    var saveGameSaveArray: [Int]?
    var saveMultiplier: Double?
    var saveBrickTextureArray: [Int]?
    var saveBrickColourArray: [Int]?
    var saveBrickXPositionArray: [Int]?
    var saveBrickYPositionArray: [Int]?
    var saveBallPropertiesArray: [Double]?
    var savePowerUpFallingXPositionArray: [Int]?
    var savePowerUpFallingYPositionArray: [Int]?
    var savePowerUpFallingArray: [Int]?
    var savePowerUpActiveArray: [String]?
    var savePowerUpActiveDurationArray: [Double]?
    var savePowerUpActiveTimerArray: [Double]?
    var savePowerUpActiveMagnitudeArray: [Int]?
    // Game save settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    @IBOutlet var modeSelectTableView: UITableView!
    @IBOutlet var iconCollectionView: UICollectionView!
    @IBOutlet var logoImage: UIImageView!
    
    @IBOutlet var bannerAdCollapsed: NSLayoutConstraint!
    @IBOutlet var bannerAdOpenSmall: NSLayoutConstraint!
    @IBOutlet var bannerAdOpenLarge: NSLayoutConstraint!
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var backgroundBlurView: UIView!
    
    @IBOutlet var tableViewContainer: UIView!
    
    var group: UIMotionEffectGroup?
    var blurViewLayer: UIVisualEffectView?
    
    var firstLaunch: Bool = false
    // Check if this is the first opening of the app since closing to know if to run splash screen
    
    @IBOutlet var bannerView: GADBannerView!
    // Ad banner view
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        logoImage.image = UIImage(named: "Logo")
        
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnSettingsNotificationKeyReceived), name: .returnSettingsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.splashScreenEndedNotificationKeyReceived), name: .splashScreenEndedNotification, object: nil)
        // Sets up an observer to watch for the end of the splash screen in order to load game center authentification
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.foregroundNotificationKeyReceived), name: .foregroundNotification, object: nil)
        // Sets up an observer to watch for the app returning from the background
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.cancelGameResumeNotificationKeyReceived), name: .cancelGameResume, object: nil)
        // Sets up an observer to watch for notifications to check game resume has been cancelled from splash screen
        
//        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
                
        backgroundImageView.image = UIImage(named:"mainMenuBackground.png")!
        
        defaultSettings()
        refreshView()
        collectionViewLayout()
        authGCPlayer()
        
        if musicSetting! {
            MusicHandler.sharedHelper.playMusic(sender: "Menu")
        }

        showSplashScreen()
        // Show splashscreen when first opening the app
    }

    override func viewWillAppear(_ animated: Bool) {
        refreshView()
    }
    
    func setBlur() {
        backgroundBlurView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0)
        let blurEffect = UIBlurEffect(style: .dark)
        blurViewLayer = UIVisualEffectView(effect: blurEffect)
        blurViewLayer!.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurView.insertSubview(blurViewLayer!, at: 0)

        NSLayoutConstraint.activate([
        blurViewLayer!.heightAnchor.constraint(equalTo: backgroundBlurView.heightAnchor),
        blurViewLayer!.widthAnchor.constraint(equalTo: backgroundBlurView.widthAnchor),
        blurViewLayer!.leadingAnchor.constraint(equalTo: backgroundBlurView.leadingAnchor),
        blurViewLayer!.trailingAnchor.constraint(equalTo: backgroundBlurView.trailingAnchor),
        blurViewLayer!.topAnchor.constraint(equalTo: backgroundBlurView.topAnchor),
        blurViewLayer!.bottomAnchor.constraint(equalTo: backgroundBlurView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func addParallaxToView() {
        var amount = 20
        if view.frame.width > 450 {
            amount = 25
            // iPad
        }
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            backgroundImageView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundImageView.addMotionEffect(group!)
    }
    
    func showSplashScreen() {
        if firstLaunch == false {
            firstLaunch = true
            let splashView = self.storyboard?.instantiateViewController(withIdentifier: "splashView") as! SplashViewController
            
            userSettings()
            if resumeGameToLoad! {
                splashView.gameToResume = true
            } else {
                splashView.gameToResume = false
            }
            
            self.addChild(splashView)
            splashView.view.frame = self.view.frame
            self.view.addSubview(splashView.view)
            splashView.didMove(toParent: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modeSelectCell", for: indexPath) as! ModeSelectTableViewCell
        
        modeSelectTableView.rowHeight = 150.0
        
        if view.frame.size.height > 1000 {
            modeSelectTableView.rowHeight = 150.0
        }
                
        switch indexPath.row {
        case 0:
            cell.modeImageIcon.image = UIImage(named:"ClassicIcon.png")
            cell.modeTextLabel.text = "Classic Mode"
            
        case 1:
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
        
        UIView.animate(withDuration: 0.1) {
            let cell = self.modeSelectTableView.cellForRow(at: indexPath) as! ModeSelectTableViewCell
            cell.cellView1.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
        }

        if indexPath.row == 0 {
        // Classic mode
            moveToPackSelector()
        }
        
        if indexPath.row == 1 {
        // Endless mode
            moveToLevelStats(startLevel: LevelPackSetup().startLevelNumber[1], levelNumber: LevelPackSetup().startLevelNumber[1], packNumber: 1)
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
        
        if view.frame.size.width <= 414 {
            tableViewContainer.frame.size.width = view.frame.size.width
            iconCollectionView.frame.size.width = tableViewContainer.frame.size.width-100
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
            cell.iconImage.image = UIImage(named:"ButtonInfo.png")
        case 1:
            if premiumSetting! {
                cell.iconImage.image = nil
            } else {
                cell.iconImage.image = UIImage(named:"ButtonPremium.png")
            }
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

        if indexPath.row == 0 {
            moveToItems()
        }
        if indexPath.row == 1 {
            if !premiumSetting! {
                moveToPremiumInfo()
            }
        }
        if indexPath.row == 2 {
            moveToSettings()
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
        UIView.animate(withDuration: 0.1) {
            let cell = self.iconCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonInfoHighlighted.png")
            case 1:
                if self.premiumSetting! {
                    cell.iconImage.image = nil
                } else {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPremiumHighlighted.png")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.1) {
            let cell = self.iconCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonInfo.png")
            case 1:
                if self.premiumSetting! {
                    cell.iconImage.image = nil
                } else {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPremium.png")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonSettings.png")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func defaultSettings() {
        defaults.register(defaults: ["premiumSetting": false])
        defaults.register(defaults: ["adsSetting": true])
        defaults.register(defaults: ["soundsSetting": true])
        defaults.register(defaults: ["musicSetting": true])
        defaults.register(defaults: ["hapticsSetting": true])
        defaults.register(defaults: ["parallaxSetting": true])
        if view.frame.size.width > 450 {
        // iPad
            defaults.register(defaults: ["paddleSensitivitySetting": 3])
        } else {
            defaults.register(defaults: ["paddleSensitivitySetting": 2])
        }
        defaults.register(defaults: ["gameCenterSetting": false])
        defaults.register(defaults: ["ballSetting": 0])
        defaults.register(defaults: ["paddleSetting": 0])
        defaults.register(defaults: ["brickSetting": 0])
        defaults.register(defaults: ["appIconSetting": 0])
        defaults.register(defaults: ["statsCollapseSetting": true])
        defaults.register(defaults: ["swipeUpPause": true])
        defaults.register(defaults: ["appOpenCount": 0])
        defaults.register(defaults: ["gameInProgress": false])
        defaults.register(defaults: ["resumeGameToLoad": false])
        defaults.register(defaults: ["iCloudSetting": false])
        defaults.register(defaults: ["firstPause": true])
        // User settings
        
        defaults.register(defaults: ["saveGameSaveArray": []])
        defaults.register(defaults: ["saveMultiplier": 1.0])
        defaults.register(defaults: ["saveBrickTextureArray": []])
        defaults.register(defaults: ["saveBrickColourArray": []])
        defaults.register(defaults: ["saveBrickXPositionArray": []])
        defaults.register(defaults: ["saveBrickYPositionArray": []])
        defaults.register(defaults: ["saveBallPropertiesArray": []])
        defaults.register(defaults: ["savePowerUpFallingXPositionArray": []])
        defaults.register(defaults: ["savePowerUpFallingYPositionArray": []])
        defaults.register(defaults: ["savePowerUpFallingArray": []])
        defaults.register(defaults: ["savePowerUpActiveArray": []])
        defaults.register(defaults: ["savePowerUpActiveDurationArray": []])
        defaults.register(defaults: ["savePowerUpActiveTimerArray": []])
        defaults.register(defaults: ["savePowerUpActiveMagnitudeArray": []])
        // Game save settings
        
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
    
    func moveToItems() {
        let itemsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsView") as! ItemsViewController
        self.addChild(itemsView)
        itemsView.view.frame = self.view.frame
        self.view.addSubview(itemsView.view)
        itemsView.didMove(toParent: self)
    }
    
    func moveToPremiumInfo() {
        let premiumInfoView = self.storyboard?.instantiateViewController(withIdentifier: "premiumInfoView") as! PremiumInfoViewController
        self.addChild(premiumInfoView)
        premiumInfoView.view.frame = self.view.frame
        self.view.addSubview(premiumInfoView.view)
        premiumInfoView.didMove(toParent: self)
    }
    
    func moveToIntro() {
        let introView = self.storyboard?.instantiateViewController(withIdentifier: "introVC") as! IntroViewController
        introView.sender = "Main"
        self.addChild(introView)
        introView.view.frame = self.view.frame
        self.view.addSubview(introView.view)
        introView.didMove(toParent: self)
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
            totalStatsArray[0].dateSaved = Date()
            do {
                let data = try encoder.encode(totalStatsArray)
                try data.write(to: totalStatsStore!)
            } catch {
                print("Error setting up total stats array, \(error)")
            }
            CloudKitHandler().saveToiCloud()
        }
        // Fill the empty array with 0s on first opening and re-save
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
        gameInProgress = defaults.bool(forKey: "gameInProgress")
        resumeGameToLoad = defaults.bool(forKey: "resumeGameToLoad")
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        firstPause = defaults.bool(forKey: "firstPause")
        // User settings
                
        saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
        saveMultiplier = defaults.double(forKey: "saveMultiplier")
        saveBrickTextureArray = defaults.object(forKey: "saveBrickTextureArray") as! [Int]?
        saveBrickColourArray = defaults.object(forKey: "saveBrickColourArray") as! [Int]?
        saveBrickXPositionArray = defaults.object(forKey: "saveBrickXPositionArray") as! [Int]?
        saveBrickYPositionArray = defaults.object(forKey: "saveBrickYPositionArray") as! [Int]?
        saveBallPropertiesArray = defaults.object(forKey: "saveBallPropertiesArray") as! [Double]?
        savePowerUpFallingXPositionArray = defaults.object(forKey: "savePowerUpFallingXPositionArray") as! [Int]?
        savePowerUpFallingYPositionArray = defaults.object(forKey: "savePowerUpFallingYPositionArray") as! [Int]?
        savePowerUpFallingArray = defaults.object(forKey: "savePowerUpFallingArray") as! [Int]?
        savePowerUpActiveArray = defaults.object(forKey: "savePowerUpActiveArray") as! [String]?
        savePowerUpActiveDurationArray = defaults.object(forKey: "savePowerUpActiveDurationArray") as! [Double]?
        savePowerUpActiveTimerArray = defaults.object(forKey: "savePowerUpActiveTimerArray") as! [Double]?
        savePowerUpActiveMagnitudeArray = defaults.object(forKey: "savePowerUpActiveMagnitudeArray") as! [Int]?
        // Game save settings
    }
    
    func checkPremium() {
        premiumSetting = true
        adsSetting = false
        defaults.set(premiumSetting!, forKey: "premiumSetting")
        defaults.set(adsSetting!, forKey: "adsSetting")
        
        totalStatsArray[0].levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray.map { _ in true }
        totalStatsArray[0].levelUnlockedArray = totalStatsArray[0].levelUnlockedArray.map { _ in true }
        totalStatsArray[0].powerUpUnlockedArray = totalStatsArray[0].powerUpUnlockedArray.map { _ in true }
        totalStatsArray[0].themeUnlockedArray = totalStatsArray[0].themeUnlockedArray.map { _ in true }
        totalStatsArray[0].appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray.map { _ in true }
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        
        CloudKitHandler().saveToiCloud()
        // Save total stats
    }
    
    func authGCPlayer() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { (view, error) in
            if view != nil {
                self.present(view!, animated: true, completion: {
                    self.updateGCAuth()
                })
            } else {
                self.updateGCAuth()
            }
        }
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting!, forKey: "gameCenterSetting")
    }
    // Sets up game center
    
    func updateGCAuth() {
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting!, forKey: "gameCenterSetting")
    }
    // Sets up game center
    
    func updateAds() {
        if defaults.bool(forKey: "adsSetting") {
            bannerView.isHidden = false
            bannerView.adUnitID = "ca-app-pub-3110131406973822/8913206996"
            bannerView.rootViewController = self
            // Configure banner ad
            
            bannerAdCollapsed.isActive = false
            bannerAdOpenSmall.isActive = true
            bannerAdOpenLarge.isActive = true

            bannerView.load(GADRequest())
        } else {
            bannerView.isHidden = true
            
            bannerAdOpenSmall.isActive = false
            bannerAdOpenLarge.isActive = false
            bannerAdCollapsed.isActive = true
        }
    }
    // Show or hide banner ad depending on setting
    
    
    
    func refreshView() {
        CloudKitHandler().loadFromiCloud()
        loadData()
        userSettings()
        if blurViewLayer == nil {
            setBlur()
        }
        if parallaxSetting! {
            addParallaxToView()
        }
        if premiumSetting! {
            checkPremium()
        }
        updateAds()
        modeSelectTableView.reloadData()
        iconCollectionView.reloadData()
    }
    
    @objc func returnSettingsNotificationKeyReceived(_ notification: Notification) {
        refreshView()
    }
    
    @objc func returnMenuNotificationKeyReceived(_ notification: Notification) {
        refreshView()
        MusicHandler.sharedHelper.stopMusic()
        if musicSetting! {
            MusicHandler.sharedHelper.playMusic(sender: "Menu")
        }
    }
    
    @objc private func splashScreenEndedNotificationKeyReceived(_ notification: Notification) {
        updateGCAuth()
        refreshView()
        
        if resumeGameToLoad! {
            loadSavedGame()
        } else {
            let rand = Int.random(in: 1...10)
            if appOpenCount! > 10 && totalStatsArray[0].playTimeSecs > 60*10 && rand == 1 {
                SKStoreReviewController.requestReview()
                // Show app rating pop-up when over 10 times opened the app and 10 minutes of play time with a 1 in 10 chance on launching the app
            }
        }
        
        if appOpenCount == 0 {
            moveToIntro()
        }
        appOpenCount!+=1
        defaults.set(appOpenCount!, forKey: "appOpenCount")
        CloudKitHandler().saveToiCloud()
        // Present onboarding screen if first time opening app
    }
    // Runs when the splash screen has ended
    
    @objc private func foregroundNotificationKeyReceived(_ notification: Notification) {
        authGCPlayer()
        refreshView()
        if musicSetting! {
            MusicHandler.sharedHelper.resumeMusic()
        }
    }
    // Runs when the splash screen has ended
    
    @objc private func cancelGameResumeNotificationKeyReceived(_ notification: Notification) {
        clearSavedGame()
    }
    // Runs when the splash screen has ended
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        refreshView()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
    func clearSavedGame() {
        userSettings()
        resumeGameToLoad = false
        defaults.set(resumeGameToLoad!, forKey: "resumeGameToLoad")
        saveGameSaveArray! = []
        saveMultiplier! = 1.0
        saveBrickTextureArray! = []
        saveBrickColourArray! = []
        saveBrickXPositionArray! = []
        saveBrickYPositionArray! = []
        saveBallPropertiesArray! = []
        savePowerUpFallingXPositionArray! = []
        savePowerUpFallingYPositionArray! = []
        savePowerUpFallingArray! = []
        savePowerUpActiveArray! = []
        savePowerUpActiveDurationArray! = []
        savePowerUpActiveTimerArray! = []
        savePowerUpActiveMagnitudeArray! = []

        defaults.set(saveGameSaveArray!, forKey: "saveGameSaveArray")
        defaults.set(saveMultiplier!, forKey: "saveMultiplier")
        defaults.set(saveBrickTextureArray!, forKey: "saveBrickTextureArray")
        defaults.set(saveBrickColourArray!, forKey: "saveBrickColourArray")
        defaults.set(saveBrickXPositionArray!, forKey: "saveBrickXPositionArray")
        defaults.set(saveBrickYPositionArray!, forKey: "saveBrickYPositionArray")
        defaults.set(saveBallPropertiesArray!, forKey: "saveBallPropertiesArray")
        defaults.set(savePowerUpFallingXPositionArray!, forKey: "savePowerUpFallingXPositionArray")
        defaults.set(savePowerUpFallingYPositionArray!, forKey: "savePowerUpFallingYPositionArray")
        defaults.set(savePowerUpFallingArray!, forKey: "savePowerUpFallingArray")
        defaults.set(savePowerUpActiveArray!, forKey: "savePowerUpActiveArray")
        defaults.set(savePowerUpActiveDurationArray!, forKey: "savePowerUpActiveDurationArray")
        defaults.set(savePowerUpActiveTimerArray!, forKey: "savePowerUpActiveTimerArray")
        defaults.set(savePowerUpActiveMagnitudeArray!, forKey: "savePowerUpActiveMagnitudeArray")
    }
    
    func loadSavedGame() {
        levelSender = "MainMenu"
        numberOfLevels = saveGameSaveArray![1] - saveGameSaveArray![0] + 1
        moveToGame(selectedLevel: saveGameSaveArray![0], numberOfLevels: numberOfLevels!, sender: levelSender!, levelPack: saveGameSaveArray![2])
    }
    
}

extension Notification.Name {
    public static let returnMenuNotification = Notification.Name(rawValue: "returnMenuNotification")
    public static let returnSettingsNotification = Notification.Name(rawValue: "returnSettingsNotification")
    public static let splashScreenEndedNotification = Notification.Name(rawValue: "splashScreenEndedNotification")
    public static let foregroundNotification = Notification.Name(rawValue: "foregroundNotification")
    public static let backgroundNotification = Notification.Name(rawValue: "backgroundNotification")
    public static let cancelGameResume = Notification.Name(rawValue: "cancelGameResume")
    public static let refreshViewForSync = Notification.Name(rawValue: "refreshViewForSync")
}
// Notification setup
