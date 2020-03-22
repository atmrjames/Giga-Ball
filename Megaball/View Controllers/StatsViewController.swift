//
//  StatsViewController.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
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
    
    
    @IBAction func statsTitleButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        statsTableView.setContentOffset(.zero, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userSettings()
        loadData()
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        statsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        if parallaxSetting! {
            addParallax()
        }
        setBlur()
        statsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 14
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        let numberOfAttempts = totalStatsArray[0].levelsPlayed + totalStatsArray[0].endlessModeDepth.count
        
        statsTableView.rowHeight = 35.0
        
        switch indexPath.row {
        case 0:
            statsTableView.rowHeight = 70.0
            settingsCell.centreLabel.text = ""
            settingsCell.settingState.text = ""
            settingsCell.settingDescription.text = "Game Center Leaderboards"
            settingsCell.settingDescription.textColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
            return settingsCell
        case 1:
            if numberOfAttempts == 0 {
                cell.statDescription.text = "No statistics available"
                cell.statValue.text = ""
            } else {
                cell.statDescription.text = "Cumulative score"
                cell.statValue.text = String(totalStatsArray[0].cumulativeScore)
            }
            return cell
        case 2:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Levels played"
                cell.statValue.text = String(totalStatsArray[0].levelsPlayed)
            }
            return cell
        case 3:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Levels completed"
                cell.statValue.text = String(totalStatsArray[0].levelsCompleted)
            }
            return cell
        case 4:
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
        case 5:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Time playing"
                cell.statValue.text = "00:00:00"
            }
            return cell
        case 6:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Ball hits"
                cell.statValue.text = String(totalStatsArray[0].ballHits)
            }
            return cell
        case 7:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Balls lost"
                cell.statValue.text = String(totalStatsArray[0].ballsLost)
            }
            return cell
        case 8:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Bricks hit"
                cell.statValue.text = String(totalStatsArray[0].bricksHit.reduce(0, +))
            }
            return cell
        case 9:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Bricks destroyed"
                cell.statValue.text = String(totalStatsArray[0].bricksDestroyed.reduce(0, +))
            }
            return cell
        case 10:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Power-ups collected"
                cell.statValue.text = String(totalStatsArray[0].powerupsCollected.reduce(0, +))
            }
            return cell
        case 11:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Power-ups left"
                let powerupsMissed = totalStatsArray[0].powerupsGenerated.reduce(0, +) - totalStatsArray[0].powerupsCollected.reduce(0, +)
                cell.statValue.text = String(powerupsMissed)
            }
            return cell
        case 12:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Lasers fired"
                cell.statValue.text = String(totalStatsArray[0].lasersFired)
            }
            return cell
        case 13:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Lasers hit"
                cell.statValue.text = String(totalStatsArray[0].lasersHit)
            }
            return cell
        case 14:
            if numberOfAttempts == 0 {
                hideCell(cell: cell)
            } else {
                cell.statDescription.text = "Cumulative depth"
                cell.statValue.text = String(totalStatsArray[0].endlessModeDepth.reduce(0, +))+" m"
            }
            return cell
        default:
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.99, y: 0.99)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.statsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            UIView.animate(withDuration: 0.1) {
                let cell = self.statsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
    }
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        statsTableView.rowHeight = 0.0
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
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
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
}
