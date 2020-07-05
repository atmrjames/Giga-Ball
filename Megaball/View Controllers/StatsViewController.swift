//
//  StatsViewController.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate {
    
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
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var statsView: UIView!
    @IBOutlet var statsTableView: UITableView!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userSettings()
        loadData()
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        collectionViewLayout()
        
        if parallaxSetting! {
            addParallax()
        }
        setBlur()
        statsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 25
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        
        let numberOfAttempts = totalStatsArray[0].levelsPlayed
        let numberOfEndlessModeAttempts = totalStatsArray[0].endlessModeHeight.count
        let heightArraySum = totalStatsArray[0].endlessModeHeight.reduce(0, +)
        let unlockedItemCount = totalStatsArray[0].appIconUnlockedArray.filter{$0 == true}.count + totalStatsArray[0].powerUpUnlockedArray.filter{$0 == true}.count + totalStatsArray[0].ballUnlockedArray.filter{$0 == true}.count + totalStatsArray[0].paddleUnlockedArray.filter{$0 == true}.count + totalStatsArray[0].brickUnlockedArray.filter{$0 == true}.count
        let lockedItemCount = totalStatsArray[0].appIconUnlockedArray.count + totalStatsArray[0].powerUpUnlockedArray.count + totalStatsArray[0].ballUnlockedArray.count + totalStatsArray[0].paddleUnlockedArray.count
        let unlockedLevelCount = totalStatsArray[0].levelUnlockedArray.filter{$0 == true}.count-1
        let lockedLevelCount = totalStatsArray[0].levelUnlockedArray.count-1
        let unlockedPackCount = totalStatsArray[0].levelPackUnlockedArray.filter{$0 == true}.count-2
        let lockedPackCount = totalStatsArray[0].levelPackUnlockedArray.count-2
        let unlockedAchievementCount = totalStatsArray[0].achievementsUnlockedArray.filter{$0 == true}.count
        let lockedAchievementCount = totalStatsArray[0].achievementsUnlockedArray.count
            
        statsTableView.rowHeight = 35.0
        
        switch indexPath.row {
        case 0:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                cell.statDescription.text = "No statistics available"
                cell.statValue.text = ""
            } else {
                cell.statDescription.text = "Total play time"
                if totalStatsArray[0].playTimeSecs <= 120 {
                    cell.statValue.text = "1 minute"
                } else if totalStatsArray[0].playTimeSecs <= 3600 {
                    let numberMinutes = Int(totalStatsArray[0].playTimeSecs/60)
                    cell.statValue.text = String(numberMinutes)+" minutes"
                } else {
                    let numberHours = Double(totalStatsArray[0].playTimeSecs/3600)
                    let numberHoursString = String(format:"%.1f", numberHours)
                    // Double to string conversion to 1 decimal place
                    cell.statValue.text = String(numberHoursString)+" hours"
                }
            }
            return cell
        case 1:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Total score"
                cell.statValue.text = String(totalStatsArray[0].cumulativeScore)
            }
            return cell
        case 2:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Items unlocked"
                cell.statValue.text = String(unlockedItemCount)+"/"+String(lockedItemCount)
            }
            return cell
        case 3:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Achievements completed"
                cell.statValue.text = String(unlockedAchievementCount)+"/"+String(lockedAchievementCount)
            }
            return cell
        case 4:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Packs unlocked"
                cell.statValue.text = String(unlockedPackCount)+"/"+String(lockedPackCount)
            }
            return cell
        case 5:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Packs played"
                cell.statValue.text = String(totalStatsArray[0].packsPlayed)
            }
            return cell
        case 6:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Packs completed"
                cell.statValue.text = String(totalStatsArray[0].packsCompleted)
            }
            return cell
        case 7:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Pack completion rate"
                var completionRate: Double = Double(totalStatsArray[0].packsCompleted)/Double(totalStatsArray[0].packsPlayed)*100.0
                if completionRate.isNaN || completionRate.isInfinite {
                    completionRate = 0.0
                }
                let completionRateString = String(format:"%.1f", completionRate)
                // Double to string conversion to 1 decimal place
                cell.statValue.text = String(completionRateString)+"%"
            }
            return cell
        case 8:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Levels unlocked"
                cell.statValue.text = String(unlockedLevelCount)+"/"+String(lockedLevelCount)
            }
            return cell
        case 9:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Levels played"
                cell.statValue.text = String(totalStatsArray[0].levelsPlayed)
            }
            return cell
        case 10:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Levels completed"
                cell.statValue.text = String(totalStatsArray[0].levelsCompleted)
            }
            return cell
        case 11:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Level completion rate"
                var completionRate: Double = Double(totalStatsArray[0].levelsCompleted)/Double(totalStatsArray[0].levelsPlayed)*100.0
                if completionRate.isNaN || completionRate.isInfinite {
                    completionRate = 0.0
                }
                let completionRateString = String(format:"%.1f", completionRate)
                // Double to string conversion to 1 decimal place
                cell.statValue.text = String(completionRateString)+"%"
            }
            return cell
        case 12:
            if numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Endless mode plays"
                cell.statValue.text = String(numberOfEndlessModeAttempts)
            }
            return cell
        case 13:
            if numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Endless mode best height"
                if let bestHeight = totalStatsArray[0].endlessModeHeight.max() {
                    cell.statValue.text = String(bestHeight) + " m"
                } else {
                    cell.statValue.text = ""
                }
            }
            return cell
        case 14:
            if numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Endless mode total height"
                cell.statValue.text = String(heightArraySum)+" m"
            }
            return cell
        case 15:
            if numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Endless mode average height"
                let averageScore = heightArraySum/numberOfEndlessModeAttempts
                cell.statValue.text = String(averageScore)+" m"
            }
            return cell
        case 16:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Ball hits"
                cell.statValue.text = String(totalStatsArray[0].ballHits)
            }
            return cell
        case 17:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Balls lost"
                cell.statValue.text = String(totalStatsArray[0].ballsLost)
            }
            return cell
        case 18:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Bricks hit"
                cell.statValue.text = String(totalStatsArray[0].bricksHit.reduce(0, +))
            }
            return cell
        case 19:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Bricks destroyed"
                cell.statValue.text = String(totalStatsArray[0].bricksDestroyed.reduce(0, +))
            }
            return cell
        case 20:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Power-ups collected"
                cell.statValue.text = String(totalStatsArray[0].powerupsCollected.reduce(0, +))
            }
            return cell
        case 21:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Power-ups left"
                let powerupsMissed = totalStatsArray[0].powerupsGenerated.reduce(0, +) - totalStatsArray[0].powerupsCollected.reduce(0, +)
                cell.statValue.text = String(powerupsMissed)
            }
            return cell
        case 22:
            if numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Power-ups collection rate"
                var collectionRate: Double = Double(totalStatsArray[0].powerupsCollected.reduce(0, +))/Double(totalStatsArray[0].powerupsGenerated.reduce(0, +))*100.0
                if collectionRate.isNaN || collectionRate.isInfinite {
                    collectionRate = 0.0
                }
                let collectionRateString = String(format:"%.1f", collectionRate)
                // Double to string conversion to 1 decimal place
                cell.statValue.text = String(collectionRateString)+"%"
            }
            return cell
        case 23:
            if (numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0) || totalStatsArray[0].lasersFired == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Lasers fired"
                cell.statValue.text = String(totalStatsArray[0].lasersFired)
            }
            return cell
        case 24:
            if (numberOfAttempts == 0 && numberOfEndlessModeAttempts == 0) || totalStatsArray[0].lasersFired == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Lasers hit"
                cell.statValue.text = String(totalStatsArray[0].lasersHit)
            }
            return cell
        default:
            return cell
        }
    }
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        statsTableView.rowHeight = 0.0
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
            cell.iconImage.image = UIImage(named:"ButtonNull")
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
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            removeAnimate()
        }
        if indexPath.row == 1 && gameCenterSetting! {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            showGameCenterLeaderboards()
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
                cell.iconImage.image = UIImage(named:"ButtonNull")
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
                cell.iconImage.image = UIImage(named:"ButtonNull")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
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
            statsView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        statsView.addMotionEffect(group!)
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
    
    func showGameCenterLeaderboards() {
        if gameCenterSetting! {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController
        let gcViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        gcViewController.viewState = GKGameCenterViewControllerState.leaderboards
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
    
}
