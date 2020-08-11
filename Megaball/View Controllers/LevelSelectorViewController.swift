//
//  LevelSelectorViewController.swift
//  Megaball
//
//  Created by James Harding on 12/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class LevelSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var gameCenterSetting: Bool?
    var statsCollapseSetting: Bool?
    var premiumSetting: Bool?
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
    
    let formatter = DateFormatter()
    // Setup date formatter
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    // UI property setup
    
    var packNumber: Int?
    var numberOfLevels: Int?
    var startLevel: Int?
    var levelSender: String = "MainMenu"
    var numberOfAttempts = 0
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var levelSelectView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var statsTableView: UITableView!
    @IBOutlet var levelsTableView: UITableView!
    @IBOutlet var levelsHeaderLabel: UIButton!
    @IBOutlet var statsTableViewChevron: UIButton!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBOutlet var statsTableViewHeight: NSLayoutConstraint!
    @IBOutlet var statsTableViewHeightNoTime: NSLayoutConstraint!
    @IBOutlet var noStatsTableViewHeight: NSLayoutConstraint!
    @IBOutlet var collapsedStatsTableViewHeight: NSLayoutConstraint!
    // Stats table view constraints
    
    @IBOutlet var premiumTableView: UITableView!
    @IBOutlet var premiumTableCollapsed: NSLayoutConstraint!
    @IBOutlet var premiumTableExpanded: NSLayoutConstraint!
    
    @IBAction func levelsHeaderButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        levelsTableView.setContentOffset(.zero, animated: true)
    }
    // UIViewController actions
    @IBAction func statisticsHeaderButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        statsCollapseSetting = !statsCollapseSetting!
        defaults.set(statsCollapseSetting!, forKey: "statsCollapseSetting")
        statsTableOpenClose(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnFromGameNotificationKeyReceived), name: .returnFromGameNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from game
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnLevelSelectFromStatsNotificationKeyReceived), name: .returnLevelSelectFromStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup 
        
        userSettings()
        loadData()
        
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting!, forKey: "gameCenterSetting")
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        // Stats tableView setup
        
        levelsTableView.delegate = self
        levelsTableView.dataSource = self
        levelsTableView.register(UINib(nibName: "LevelSelectorTableViewCell", bundle: nil), forCellReuseIdentifier: "levelSelectorCell")
        // Levels tableView setup
        
        premiumTableView.delegate = self
        premiumTableView.dataSource = self
        premiumTableView.register(UINib(nibName: "IAPTableViewCell", bundle: nil), forCellReuseIdentifier: "iAPCell")
        
        premiumTableViewHideShow()
        
        if parallaxSetting! {
            addParallax()
        }
        updateLabels()
        statsTableOpenClose(animated: false)
        collectionViewLayout()
        showAnimate()
        reloadData()
    }
    
    func premiumTableViewHideShow() {
        var allUnlockedBool = false
        if totalStatsArray[0].levelUnlockedArray.count == totalStatsArray[0].levelUnlockedArray.filter({$0 == true}).count {
            allUnlockedBool = true
        }
        if premiumSetting! == false && allUnlockedBool == false {
            premiumTableView.isHidden = false
            premiumTableExpanded.isActive = true
            premiumTableCollapsed.isActive = false
        } else {
            premiumTableView.isHidden = true
            premiumTableExpanded.isActive = false
            premiumTableCollapsed.isActive = true
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.statsTableView {
            return 7
        } else if tableView == self.premiumTableView {
            return 1
        } else {
            return numberOfLevels!
        }
    }
    // Set number of cells in table views
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.premiumTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "iAPCell", for: indexPath) as! IAPTableViewCell
            premiumTableView.rowHeight = 84.0
            cell.centreLabel.isHidden = true
            cell.tagLine.text = "Unlock All Levels"
            cell.iconImage.image = UIImage(named:"iconPremium.png")!
            
            UIView.animate(withDuration: 0.2) {
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.showsVerticalScrollIndicator = false
            
            return cell
        }
        
        numberOfAttempts = packStatsArray[packNumber!].scores.count
        let scoreArraySum = packStatsArray[packNumber!].scores.reduce(0, +)
        
        statsTableView.rowHeight = 35.0
        levelsTableView.rowHeight = 150.0
        
        if tableView == self.statsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
            
            switch indexPath.row {
            case 0:
                if numberOfAttempts == 0 {
                    cell.statDescription.text = "No statistics available"
                    cell.statValue.text = ""
                } else {
                    cell.statDescription.text = "Highscore"
                    if let highScore = packStatsArray[packNumber!].scores.max() {
                        cell.statValue.text = String(highScore)
                    } else {
                        cell.statValue.text = ""
                    }
                }
                return cell
            case 1:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Highscore date"
                    
                    if let highScore = packStatsArray[packNumber!].scores.max() {
                        let highScoreIndex = packStatsArray[packNumber!].scores.firstIndex(of: highScore)
                        let highScoreDate = packStatsArray[packNumber!].scoreDates[highScoreIndex!]
                        // Find date of highscore
                        
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let inputDate = formatter.string(from: highScoreDate)
                        let outputDate = formatter.date(from: inputDate)
                        formatter.dateFormat = "dd/MM/yyyy"
                        let convertedDate = formatter.string(from: outputDate!)
                        // Date to string conversion
                        
                        cell.statValue.text = convertedDate
                    } else {
                        cell.statValue.text = ""
                    }
                }
                return cell
            case 2:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Plays"
                    cell.statValue.text = String(numberOfAttempts)
                }
                return cell
            case 3:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Completion rate"
                    
                    let completionRate: Double = Double(packStatsArray[packNumber!].numberOfCompletes)/Double(numberOfAttempts)*100.0

                    let completionRateString = String(format:"%.1f", completionRate)
                    // Double to string conversion to 1 decimal place
                    
                    cell.statValue.text = String(completionRateString)+"%"
                }
                return cell
            case 4:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Total score"
                    cell.statValue.text = String(scoreArraySum)
                }
                return cell
            case 5:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Average score"
                    let averageScore = scoreArraySum/numberOfAttempts
                    cell.statValue.text = String(averageScore)
                }
                return cell
            case 6:
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Best time (mm:ss)"
                    let bestTimeSeconds = packStatsArray[packNumber!].bestTime
                    let displayMinutesString = String(format: "%02d", bestTimeSeconds/60)
                    let displaySecondsString = String(format: "%02d", bestTimeSeconds%60)
                    cell.statValue.text = "\(displayMinutesString):\(displaySecondsString)"
                    if packStatsArray[packNumber!].numberOfCompletes <= 0 {
                        hideCell(cell: cell)
                        statsTableViewHeight.isActive = false
                        statsTableViewHeightNoTime.isActive = true
                    }
                }
                return cell
            default:
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "levelSelectorCell", for: indexPath) as! LevelSelectorTableViewCell
            cell.levelLabel.text = "Level "+String(indexPath.row+1)
            cell.levelNameLabel.text = LevelPackSetup().levelNameArray[startLevel!+indexPath.row]
            cell.highScoreTitleLabel.text = "Highscore"
            cell.blurView.isHidden = true
            cell.lockedImageView.isHidden = true
            cell.cellView3.tag = indexPath.row+1
            cell.levelImage.image = LevelPackSetup().levelImageArray[startLevel!+indexPath.row]
            cell.levelNameLabel.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            // Setup cell buttons
            let levelNumber = startLevel!+indexPath.row
            if levelStatsArray[levelNumber].scores.isEmpty == false {
                cell.highScoreLabel.text = String(levelStatsArray[levelNumber].scores.max()!)
            } else {
                cell.highScoreTitleLabel.text = ""
                cell.highScoreLabel.text = ""
            }

            if totalStatsArray[0].levelUnlockedArray[startLevel!+indexPath.row] == false {
                cell.levelNameLabel.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
                if totalStatsArray[0].levelUnlockedArray[startLevel!+indexPath.row-1] {
                    cell.levelNameLabel.text = "Complete \(LevelPackSetup().levelNameArray[startLevel!+indexPath.row-1]) level to unlock"
                } else {
                    cell.levelNameLabel.text = "Complete Level \(indexPath.row) to unlock"
                }
                cell.highScoreTitleLabel.text = ""
                cell.highScoreLabel.text = ""
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked levels until unlocked
            
            UIView.animate(withDuration: 0.1) {
                cell.cellView3.transform = .identity
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == premiumTableView {
            showPurchaseScreen()
            IAPHandler().purchasePremium()
            
            UIView.animate(withDuration: 0.2) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
            tableView.reloadData()
            tableView.deselectRow(at: indexPath, animated: true)
            // Update table view
            
        } else if tableView == self.levelsTableView {
            
            UIView.animate(withDuration: 0.1) {
                let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
                cell.cellView3.transform = .init(scaleX: 0.99, y: 0.99)
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
            }
            
            if totalStatsArray[0].levelUnlockedArray[startLevel!+indexPath.row] {
                moveToLevelStatsSetup(sender: indexPath.row)
            }
            // Don't allow selection if level is locked
            
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        } else if tableView == self.levelsTableView {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
                cell.cellView3.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if tableView == premiumTableView {
            UIView.animate(withDuration: 0.1) {
                let cell = self.premiumTableView.cellForRow(at: indexPath) as! IAPTableViewCell
                cell.cellView.transform = .identity
                cell.cellView.backgroundColor = #colorLiteral(red: 0.9019607843, green: 1, blue: 0.7019607843, alpha: 1)
            }
        } else if tableView == self.levelsTableView {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
                cell.cellView3.transform = .identity
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
    }
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        statsTableView.rowHeight = 0.0
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let viewWidth = levelSelectView.frame.size.width
        let cellWidth: CGFloat = 50
        let cellSpacing = (viewWidth - cellWidth*3)/3
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        backButtonCollectionView!.collectionViewLayout = layout
    }
    // Set the spacing between collection view cells
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        
        cell.widthConstraint.constant = 40
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonClose")
        case 1:
            if gameCenterSetting! {
                cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull")
            }
        case 2:
            cell.iconImage.image = UIImage(named:"ButtonPlay")
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
            removeAnimate()
            NotificationCenter.default.post(name: .returnPackSelectNotification, object: nil)
        }
        if indexPath.row == 1 {
            if gameCenterSetting! {
                showGameCenterLeaderboards()
            }
        }
        if indexPath.row == 2 {
            MenuViewController().clearSavedGame()
            moveToGame(selectedLevel: startLevel!, numberOfLevels: numberOfLevels!, sender: levelSender, levelPack: packNumber!)
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.1) {
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted")
            case 1:
                if self.gameCenterSetting! {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonLeaderboardHighlighted")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.1) {
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonClose")
            case 1:
                if self.gameCenterSetting! {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonPlay")
            default:
                print("Error: Out of range")
                break
            }
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
    
    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self as? MenuViewControllerDelegate
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        gameView.levelSender = sender
        gameView.levelPack = levelPack
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController with selected level
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
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
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
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
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        // Load user settings
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
            self.levelSelectView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.levelSelectView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.levelSelectView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.levelSelectView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.levelSelectView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.levelSelectView.alpha = 1.0
        })
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
            levelSelectView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        levelSelectView.addMotionEffect(group!)
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
    
    func moveToLevelStatsSetup(sender: Int) {
        hideAnimate()
        let levelNumber = startLevel! + Int(sender)
        moveToLevelStats(startLevel: startLevel!, levelNumber: levelNumber, packNumber: packNumber!)
    }
    
    func updateLabels() {
        titleLabel.text = LevelPackSetup().levelPackNameArray[packNumber!].uppercased()
        numberOfAttempts = packStatsArray[packNumber!].scores.count
        var numberOfUnlockedLevels = 0
        let packFirstLevel = LevelPackSetup().startLevelNumber[packNumber!]
        var levelIndex = packFirstLevel
        while levelIndex-packFirstLevel <= numberOfLevels!-1 {
            if totalStatsArray[0].levelUnlockedArray[levelIndex] {
                numberOfUnlockedLevels+=1
            }
            levelIndex+=1
        }
        
        // 3/10 levels
        
        if numberOfLevels! == 1 {
            levelsHeaderLabel.setTitle(String(numberOfLevels!)+" Level", for: .normal)
        } else {
            if numberOfUnlockedLevels == numberOfLevels {
                levelsHeaderLabel.setTitle(String(numberOfLevels!)+" Levels", for: .normal)
            } else {
                // 3/10 levels
                levelsHeaderLabel.setTitle(String(numberOfUnlockedLevels)+"/"+String(numberOfLevels!)+" Levels", for: .normal)
            }
        }
    }
    
    func reloadData() {
        statsTableView.reloadData()
        levelsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    
    func statsTableOpenClose(animated: Bool) {
        if statsCollapseSetting == false {
            collapsedStatsTableViewHeight.isActive = false
            if numberOfAttempts == 0 {
                statsTableViewHeight.isActive = false
                noStatsTableViewHeight.isActive = true
            } else {
                noStatsTableViewHeight.isActive = false
                statsTableViewHeight.isActive = true
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.statsTableViewChevron.transform = CGAffineTransform(rotationAngle: 0)
            })
        } else if statsCollapseSetting! {
            collapsedStatsTableViewHeight.isActive = true
            statsTableViewHeight.isActive = false
            noStatsTableViewHeight.isActive = false
            UIView.animate(withDuration: 0.25, animations: {
                self.statsTableViewChevron.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            })
        }
        updateLabels()
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func showGameCenterLeaderboards() {
        if gameCenterSetting! {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController
        let gcViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        gcViewController.viewState = GKGameCenterViewControllerState.leaderboards
        
        if packNumber == 2 {
            gcViewController.leaderboardIdentifier = "leaderboardClassicPackScore"
        }
        if packNumber == 3 {
            gcViewController.leaderboardIdentifier = "leaderboardSpacePackScore"
        }
        if packNumber == 4 {
            gcViewController.leaderboardIdentifier = "leaderboardNaturePackScore"
        }
        if packNumber == 5 {
            gcViewController.leaderboardIdentifier = "leaderboardUrbanPackScore"
        }
        if packNumber == 6 {
            gcViewController.leaderboardIdentifier = "leaderboardFoodPackScore"
        }
        if packNumber == 7 {
            gcViewController.leaderboardIdentifier = "leaderboardComputerPackScore"
        }
        if packNumber == 8 {
            gcViewController.leaderboardIdentifier = "leaderboardBodyPackScore"
        }
        if packNumber == 9 {
            gcViewController.leaderboardIdentifier = "leaderboardWorldPackScore"
        }
        if packNumber == 10 {
            gcViewController.leaderboardIdentifier = "leaderboardEmojiPackScore"
        }
        if packNumber == 11 {
            gcViewController.leaderboardIdentifier = "leaderboardNumbersPackScore"
        }
        if packNumber == 12 {
            gcViewController.leaderboardIdentifier = "leaderboardChallengePackScore"
        }
        // Show corresponding leaderboard for the current level pack
        
        viewController?.present(gcViewController, animated: true, completion: nil)
    }
    // Show game center view controller
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
    }
    // Remove game center view contoller once dismissed
    
    @objc func returnFromGameNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        reloadData()
        updateLabels()
        statsTableOpenClose(animated: false)
    }
    // Runs when returning from game
    
    @objc func returnLevelSelectFromStatsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        reloadData()
        updateLabels()
        revealAnimate()
    }
    // Runs when returning from another menu view
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        print("llama llama icloud update pushed - level select view")
        userSettings()
        loadData()
        updateLabels()
        reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}

extension Notification.Name {
    public static let returnFromGameNotification = Notification.Name(rawValue: "returnFromGameNotification")
    public static let returnLevelSelectFromStatsNotification = Notification.Name(rawValue: "returnLevelSelectFromStatsNotification")
}
// Notification setup
