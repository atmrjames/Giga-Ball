//
//  LevelStatsViewController.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class LevelStatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var gameCenterSetting: Bool?
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
    
    var startLevel: Int?
    var levelNumber: Int?
    var packNumber: Int?
    var levelSender: String = "MainMenu"
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var levelStatsView: UIView!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var packNameAndLevelNumberLabel: UILabel!
    @IBOutlet var levelImageView: UIImageView!
    @IBOutlet var levelTableView: UITableView!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnLevelStatsNotificationKeyReceived), name: .returnLevelStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        levelTableView.delegate = self
        levelTableView.dataSource = self
        levelTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        levelTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        collectionViewLayout()
        // Collection view setup
        
        userSettings()
        loadData()
        
        if levelNumber == 0 {
            setBlur()
        } else if blurView != nil {
            blurView = nil
        }
        // Only set blur when entering from endless mode otherwise, remove it
        
        if parallaxSetting! {
            addParallax()
        }
        updateLabels()
        levelTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        
        levelTableView.rowHeight = 35.0
        
        let numberOfAttempts = levelStatsArray[levelNumber!].scores.count
        let scoreArraySum = levelStatsArray[levelNumber!].scores.reduce(0, +)
        let heightArraySum = totalStatsArray[0].endlessModeHeight.reduce(0, +)
        
        switch indexPath.row {
        case 0:
            if numberOfAttempts == 0 {
                cell.statDescription.text = "No statistics available"
                cell.statValue.text = ""
            } else {
                if levelNumber == 0 {
                    cell.statDescription.text = "Best height"
                    if let bestHeight = totalStatsArray[0].endlessModeHeight.max() {
                        cell.statValue.text = String(bestHeight) + " m"
                    } else {
                        cell.statValue.text = ""
                    }
                } else {
                    cell.statDescription.text = "Highscore"
                    if let highScore = levelStatsArray[levelNumber!].scores.max() {
                        cell.statValue.text = String(highScore)
                    } else {
                        cell.statValue.text = ""
                    }
                }
            }
            return cell
        case 1:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                if levelNumber == 0 {
                    cell.statDescription.text = "Best height date"
                    
                    if let bestHeight = totalStatsArray[0].endlessModeHeight.max() {
                        let bestHeightIndex = totalStatsArray[0].endlessModeHeight.firstIndex(of: bestHeight)
                        let bestHeightDate = levelStatsArray[levelNumber!].scoreDates[bestHeightIndex!]
                        // Find date of highscore
                    
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let inputDate = formatter.string(from: bestHeightDate)
                        let outputDate = formatter.date(from: inputDate)
                        formatter.dateFormat = "dd/MM/yyyy"
                        let convertedDate = formatter.string(from: outputDate!)
                        // Date to string conversion
                        
                        cell.statValue.text = convertedDate
                    } else {
                        cell.statValue.text = ""
                    }
                    
                } else {
                    cell.statDescription.text = "Highscore date"
                    
                    if let highScore = levelStatsArray[levelNumber!].scores.max() {
                        let highScoreIndex = levelStatsArray[levelNumber!].scores.firstIndex(of: highScore)
                        let highScoreDate = levelStatsArray[levelNumber!].scoreDates[highScoreIndex!]
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
            }
            return cell
        case 2:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Plays"
                cell.statValue.text = String(numberOfAttempts)
            }
            return cell
        case 3:
            if numberOfAttempts == 0 || levelNumber == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Completion rate"
                let completionRate: Double = Double(levelStatsArray[levelNumber!].numberOfCompletes)/Double(numberOfAttempts)*100.0

                let completionRateString = String(format:"%.1f", completionRate)
                // Double to string conversion to 1 decimal place
                
                cell.statValue.text = String(completionRateString)+"%"
            }
            return cell
        case 4:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                if levelNumber == 0 {
                    cell.statDescription.text = "Total height"
                    cell.statValue.text = String(heightArraySum)+" m"
                } else {
                    cell.statDescription.text = "Total score"
                    cell.statValue.text = String(scoreArraySum)
                }
            }
            return cell
        
        case 5:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                if levelNumber == 0 {
                    cell.statDescription.text = "Average height"
                    let averageScore = heightArraySum/numberOfAttempts
                    cell.statValue.text = String(averageScore)+" m"
                } else {
                    cell.statDescription.text = "Average score"
                    let averageScore = scoreArraySum/numberOfAttempts
                    cell.statValue.text = String(averageScore)
                }
            }
            return cell
        default:
            return cell
        }
    }
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        levelTableView.rowHeight = 0.0
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        let viewWidth = backButtonCollectionView.frame.size.width
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
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        if indexPath.row == 0 {
            removeAnimate()
            NotificationCenter.default.post(name: .returnLevelSelectFromStatsNotification, object: nil)
        }
        if indexPath.row == 1 {
            if gameCenterSetting! {
                showGameCenterLeaderboards()
            }
        }
        if indexPath.row == 2 {
            moveToGame(selectedLevel: levelNumber!, numberOfLevels: 1, sender: levelSender, levelPack: packNumber!)
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
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted")
            case 1:
                if self.gameCenterSetting! {
                    cell.iconImage.image = UIImage(named:"ButtonLeaderboardHighlighted")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                }
            case 2:
                cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted")
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
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonClose")
            case 1:
                if self.gameCenterSetting! {
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
        }
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
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
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
    
    func setBlur() {
        backgroundView.backgroundColor = .clear
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
    
    func addParallax() {
        let amount = 25
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            levelStatsView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        levelStatsView.addMotionEffect(group!)
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
    
    func updateLabels() {
        levelNameLabel.text = LevelPackSetup().levelNameArray[levelNumber!].uppercased()
        if levelNumber == 0 {
            packNameAndLevelNumberLabel.text = ""
            // No sub-heading in endless mode
        } else {
            packNameAndLevelNumberLabel.text = LevelPackSetup().packTitles[packNumber!]+" - Level "+String(levelNumber!-startLevel!+1)
        }
        levelImageView.image = LevelPackSetup().levelImageArray[levelNumber!]
        levelImageView.layer.masksToBounds = false
        levelImageView.layer.shadowColor = UIColor.black.cgColor
        levelImageView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        levelImageView.layer.shadowRadius = 10.0
        levelImageView.layer.shadowOpacity = 0.75
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
        
        gcViewController.leaderboardIdentifier = LevelPackSetup().levelLeaderboardsArray[levelNumber!]
        // Show corresponding leaderboard for the current level
            
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
    
    @objc func returnLevelStatsNotificationKeyReceived(_ notification: Notification) {
            userSettings()
            loadData()
            levelTableView.reloadData()
    }
    // Runs when returning from game
    
}

extension Notification.Name {
    public static let returnLevelStatsNotification = Notification.Name(rawValue: "returnLevelStatsNotification")
}
// Notification setup
