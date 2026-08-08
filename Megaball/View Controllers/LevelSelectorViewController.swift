//
//  LevelSelectorViewController.swift
//  Megaball
//
//  Created by James Harding on 12/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class LevelSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate, MenuNavigable, MenuNavigationPresenter {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    var statsCollapseSetting: Bool = true
    // User settings
    
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
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
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var levelSelectView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var statsTableView: UITableView!
    @IBOutlet var levelsTableView: UITableView!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBOutlet var statsTableViewHeight: NSLayoutConstraint!
    @IBOutlet var collapsedStatsTableViewHeight: NSLayoutConstraint!
    // Stats table view constraints
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
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
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        // Stats tableView setup
        
        levelsTableView.delegate = self
        levelsTableView.dataSource = self
        levelsTableView.register(UINib(nibName: "LevelSelectorTableViewCell", bundle: nil), forCellReuseIdentifier: "levelSelectorCell")
        // Levels tableView setup
        
        
        
        if parallaxSetting {
            addParallax()
        }
        updateLabels()
//        statsTableOpenClose(animated: false)
        collectionViewLayout()
        showAnimate()
        reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        collectionViewLayout()
    }

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.statsTableView {
            return 2
        } else {
            return numberOfLevels!
        }
    }
    // Set number of cells in table views
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        statsTableView.rowHeight = 35.0
        levelsTableView.rowHeight = 150.0
        
        if tableView == self.statsTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
            
            switch indexPath.row {
            case 0:
                cell.statDescription.text = "Pack Highscore"
                let highScore = totalStatsArray[0].packHighScores[packNumber!-2]
                if highScore > 0 {
                    cell.statValue.text = String(highScore)
                } else {
                    cell.statValue.text = "Not set"
                }
                return cell
            case 1:
                statsTableView.rowHeight = 35.0
                cell.statDescription.text = "Best time (mm:ss)"
                let bestTimeSeconds = totalStatsArray[0].packBestTimes[packNumber!-2]
                let displayMinutesString = String(format: "%02d", bestTimeSeconds/60)
                let displaySecondsString = String(format: "%02d", bestTimeSeconds%60)
                cell.statValue.text = "\(displayMinutesString):\(displaySecondsString)"
                if totalStatsArray[0].packBestTimes[packNumber!-2] == 0 {
                    cell.statValue.text = "Not set"
                }
                return cell
            default:
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "levelSelectorCell", for: indexPath) as! LevelSelectorTableViewCell
            cell.levelLabel.text = "Level "+String(indexPath.row+1)
            cell.levelNameLabel.text = LevelPackSetup().levelNameArray[startLevel!+indexPath.row]
            cell.highScoreTitleLabel.text = "Level Highscore"
            cell.blurView.isHidden = true
            cell.lockedImageView.isHidden = true
            cell.cellView3.tag = indexPath.row+1
            cell.levelImage.image = LevelPackSetup().levelImageArray[startLevel!+indexPath.row]
            cell.levelNameLabel.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            // Setup cell buttons

            installLevelPlayButton(on: cell)
            
            let packLevelHighScoresArray: [[Int]] = [
                totalStatsArray[0].pack1LevelHighScores, totalStatsArray[0].pack2LevelHighScores, totalStatsArray[0].pack3LevelHighScores, totalStatsArray[0].pack4LevelHighScores, totalStatsArray[0].pack5LevelHighScores, totalStatsArray[0].pack6LevelHighScores, totalStatsArray[0].pack7LevelHighScores, totalStatsArray[0].pack8LevelHighScores, totalStatsArray[0].pack9LevelHighScores, totalStatsArray[0].pack10LevelHighScores, totalStatsArray[0].pack11LevelHighScores
            ]
            
            let levelNumber = startLevel!+indexPath.row
            if packLevelHighScoresArray[packNumber!-2][levelNumber-startLevel!] > 0 {
                cell.highScoreLabel.text = String(packLevelHighScoresArray[packNumber!-2][levelNumber-startLevel!])
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
        
        if tableView == self.levelsTableView {
            
            if let cell = self.levelsTableView.cellForRow(at: indexPath) as? LevelSelectorTableViewCell {
                UIView.animate(withDuration: 0.1) {
                    cell.cellView3.transform = .init(scaleX: 0.99, y: 0.99)
                    cell.cellView3.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
                }
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
        
        if tableView == self.levelsTableView {
            if hapticsSetting {
                interfaceHaptic.impactOccurred()
            }
            if let cell = self.levelsTableView.cellForRow(at: indexPath) as? LevelSelectorTableViewCell {
                UIView.animate(withDuration: 0.1) {
                    cell.cellView3.transform = .init(scaleX: 0.98, y: 0.98)
                    cell.cellView3.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
       
        if tableView == self.levelsTableView {
            if hapticsSetting {
                interfaceHaptic.impactOccurred()
            }
            if let cell = self.levelsTableView.cellForRow(at: indexPath) as? LevelSelectorTableViewCell {
                UIView.animate(withDuration: 0.1) {
                    cell.cellView3.transform = .identity
                    cell.cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
                }
            }
        }
    }
    
    func collectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let cellWidth: CGFloat = 50
        let available = backButtonCollectionView.frame.size.width
        // Spread across the width the buttons actually occupy. This used to measure the
        // whole screen, or the container, neither of which is the row the buttons are in
        // once the content is capped - so on iPad they bunched to one side.
        let cellSpacing = max(0, (available - cellWidth*3)/3)
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        backButtonCollectionView.collectionViewLayout = layout
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
            if gameCenterSetting {
                cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull")
            }
        case 2:
            cell.iconImage.image = UIImage(named:"ButtonPlay")
        default:
            Log.ui.error("Row index out of range in \(#function, privacy: .public)")
            break
        }
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            menuNavigationGoBack()
        }
        if indexPath.row == 1 {
            if gameCenterSetting {
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
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
                switch indexPath.row {
                case 0:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted")
                case 1:
                    if self.gameCenterSetting {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboardHighlighted")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull")
                    }
                case 2:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted")
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
            
                switch indexPath.row {
                case 0:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonClose")
                case 1:
                    if self.gameCenterSetting {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull")
                    }
                case 2:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlay")
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    /// The straight-in button on every level row: skip the detail screen, play the level.
    func installLevelPlayButton(on cell: UITableViewCell) {
        cell.contentView.viewWithTag(9901)?.removeFromSuperview()

        let play = UIButton(type: .system)
        play.tag = 9901
        play.setImage(UIImage(systemName: "play.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                             weight: .heavy)),
                      for: .normal)
        play.tintColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        play.translatesAutoresizingMaskIntoConstraints = false
        play.addTarget(self, action: #selector(levelPlayTapped(_:)), for: .touchUpInside)
        cell.contentView.addSubview(play)
        NSLayoutConstraint.activate([
            play.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor,
                                           constant: -18),
            play.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 44),
            play.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc func levelPlayTapped(_ sender: UIButton) {
        var view: UIView? = sender
        while view != nil, (view as? UITableViewCell) == nil { view = view?.superview }
        guard let cell = view as? UITableViewCell,
              let indexPath = levelsTableView.indexPath(for: cell) else { return }

        if hapticsSetting { interfaceHaptic.impactOccurred() }
        MenuViewController().clearSavedGame()
        moveToGame(selectedLevel: startLevel! + indexPath.row, numberOfLevels: 1,
                   sender: levelSender, levelPack: packNumber!)
        // Single level mode, straight in - the same launch the mode-select screen's
        // "single level" choice performs
    }

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
    
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
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
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
        NotificationCenter.default.post(name: .returnPackSelectNotification, object: nil)
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
    
    func menuNavigationHideBehindChild() {
        hideAnimate()
    }
    // The same fade opening a child gives - the forward swipe says it too, or the screen
    // underneath stays readable through the one that came back (the play-test screenshot)

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
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        // Load the total stats array from the NSCoder data store
    }
    
    func moveToLevelStatsSetup(sender: Int) {
        hideAnimate()
        let levelNumber = startLevel! + Int(sender)
        moveToLevelStats(startLevel: startLevel!, levelNumber: levelNumber, packNumber: packNumber!)
    }
    
    func updateLabels() {
        titleLabel.text = LevelPackSetup().levelPackNameArray[packNumber!].uppercased()
        var numberOfUnlockedLevels = 0
        let packFirstLevel = LevelPackSetup().startLevelNumber[packNumber!]
        var levelIndex = packFirstLevel
        while levelIndex-packFirstLevel <= numberOfLevels!-1 {
            if totalStatsArray[0].levelUnlockedArray[levelIndex] {
                numberOfUnlockedLevels+=1
            }
            levelIndex+=1
        }
    }
    
    func reloadData() {
        statsTableView.reloadData()
        levelsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    
    func showGameCenterLeaderboards() {
        if gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController

        let packLeaderboardIDs = [2: "leaderboardClassicPackScore", 3: "leaderboardSpacePackScore", 4: "leaderboardNaturePackScore", 5: "leaderboardUrbanPackScore", 6: "leaderboardFoodPackScore", 7: "leaderboardComputerPackScore", 8: "leaderboardBodyPackScore", 9: "leaderboardWorldPackScore", 10: "leaderboardEmojiPackScore", 11: "leaderboardNumbersPackScore", 12: "leaderboardChallengePackScore"]
        // Show corresponding leaderboard for the current level pack

        let gcViewController: GKGameCenterViewController
        if let packNumber = packNumber, let leaderboardID = packLeaderboardIDs[packNumber] {
            gcViewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        } else {
            gcViewController = GKGameCenterViewController(state: .leaderboards)
        }
        gcViewController.gameCenterDelegate = self

        viewController?.present(gcViewController, animated: true, completion: nil)
    }
    // Show game center view controller
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
    }
    // Remove game center view contoller once dismissed
    
    @objc func returnFromGameNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        reloadData()
        updateLabels()
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
