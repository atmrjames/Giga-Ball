//
//  ItemsStatsViewController.swift
//  Megaball
//
//  Created by James Harding on 22/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ItemsStatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
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
    // UI property setup
    
    var passedIndex: Int?
    var sender: String?
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var powerUpImage: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var statsTableView: UITableView!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        userSettings()
        loadData()
        
        if parallaxSetting! {
            addParallax()
        }
        updateLabels()
        statsTableView.reloadData()
        backButtonCollectionView.reloadData()

        showAnimate()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if sender == "Power-Ups" {
            return 5
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        
        statsTableView.rowHeight = 35.0
        
        if sender == "Power-Ups" {
            switch indexPath.row {
            case 0:
                if LevelPackSetup().powerUpMultiplierArray[passedIndex!] == "" {
                    hideCell(cell: cell)
                    return cell
                } else {
                    cell.statValue.text = LevelPackSetup().powerUpMultiplierArray[passedIndex!]
                    if LevelPackSetup().powerUpMultiplierArray[passedIndex!] == "+0.1x" {
                        cell.statDescription.text = "Mutliplier bonus"
                    } else {
                        cell.statDescription.text = "Mutliplier penalty"
                    }
                }
                return cell
            case 1:
                cell.statDescription.text = "Duration"
                if LevelPackSetup().powerUpTimerArray[passedIndex!] == "" {
                    hideCell(cell: cell)
                    return cell
                }
                if LevelPackSetup().powerUpTimerArray[passedIndex!] == "5" {
                    cell.statValue.text = LevelPackSetup().powerUpTimerArray[passedIndex!]+" catches"
                }
                if LevelPackSetup().powerUpTimerArray[passedIndex!] == "10" {
                    cell.statValue.text = LevelPackSetup().powerUpTimerArray[passedIndex!]+"s"
                }
                return cell
            case 2:
                cell.statDescription.text = "Released"
                cell.statValue.text = String(totalStatsArray[0].powerupsGenerated[passedIndex!])
                return cell
            case 3:
                cell.statDescription.text = "Collected"
                cell.statValue.text = String(totalStatsArray[0].powerupsCollected[passedIndex!])
                return cell
            case 4:
                if totalStatsArray[0].powerupsGenerated[passedIndex!] == 0 {
                    hideCell(cell: cell)
                    return cell
                }
                // Only show if power-up has been seen
                cell.statDescription.text = "Collection rate"
                var collectionRate: Double = Double(totalStatsArray[0].powerupsCollected[passedIndex!])/Double(totalStatsArray[0].powerupsGenerated[passedIndex!])*100.0
                if collectionRate.isNaN || collectionRate.isInfinite {
                    collectionRate = 0.0
                }
                let collectionRateString = String(format:"%.0f", collectionRate)
                // Double to string conversion to 1 decimal place
                cell.statValue.text = String(collectionRateString)+"%"
                return cell
            default:
                return cell
            }
        } else {
            cell.statDescription.text = "Incomplete"
            cell.statValue.text = ""
            if totalStatsArray[0].achievementsPercentageCompleteArray[passedIndex!] != "" {
                cell.statDescription.text = "Percentage complete"
                cell.statValue.text = totalStatsArray[0].achievementsPercentageCompleteArray[passedIndex!]
            }
            if totalStatsArray[0].achievementsUnlockedArray[passedIndex!] {
                cell.statDescription.text = "Date completed"
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let inputDate = formatter.string(from: totalStatsArray[0].achievementDates[passedIndex!])
                let outputDate = formatter.date(from: inputDate)
                formatter.dateFormat = "dd/MM/yyyy"
                let convertedDate = formatter.string(from: outputDate!)
                // Date to string conversion
                cell.statValue.text = convertedDate
            }
            return cell
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
        NotificationCenter.default.post(name: .returnItemStatsNotification, object: nil)
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
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        statsTableView.rowHeight = 0.0
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
            backgroundView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundView.addMotionEffect(group!)
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
        
        if sender == "Power-Ups" {
            titleLabel.text = LevelPackSetup().powerUpNameArray[passedIndex!].uppercased()
            powerUpImage.image = LevelPackSetup().powerUpImageArray[passedIndex!]
            descriptionLabel.text = LevelPackSetup().powerUpDescriptionArray[passedIndex!]
        } else {
            titleLabel.text = LevelPackSetup().achievementsNameArray[passedIndex!].uppercased()
            if totalStatsArray[0].achievementsUnlockedArray[passedIndex!] {
                powerUpImage.image = UIImage(named: LevelPackSetup().achievementsImageArray[passedIndex!])!
            } else {
                powerUpImage.image = UIImage(named:"AchivementBadgeIncomplete.png")!
            }
            descriptionLabel.text = LevelPackSetup().achievementsPreEarnedDescriptionArray[passedIndex!]
            if totalStatsArray[0].achievementsUnlockedArray[passedIndex!] {
                descriptionLabel.text = LevelPackSetup().achievementsEarnedDescriptionArray[passedIndex!]
            }
        }
        
        powerUpImage.layer.masksToBounds = false
        powerUpImage.layer.shadowColor = #colorLiteral(red: 0.2159586251, green: 0.04048030823, blue: 0.3017641902, alpha: 1)
        powerUpImage.layer.shadowOffset = CGSize(width: 0, height: 0)
        powerUpImage.layer.shadowOpacity = 0.5
        powerUpImage.layer.shadowRadius = 4
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        updateLabels()
        statsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
    
}
