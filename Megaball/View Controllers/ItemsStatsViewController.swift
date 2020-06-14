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
    
    var powerUpIndex: Int?
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var powerUpImage: UIImageView!
    @IBOutlet var powerUpActionImage: UIImageView!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var statsTableView: UITableView!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        
        statsTableView.rowHeight = 35.0
        
        switch indexPath.row {
        case 0:
            cell.statDescription.text = "Mutliplier"
            if LevelPackSetup().powerUpMultiplierArray[powerUpIndex!] == "" {
                hideCell(cell: cell)
                return cell
            } else {
                cell.statValue.text = LevelPackSetup().powerUpMultiplierArray[powerUpIndex!]
            }
            return cell
        case 1:
            cell.statDescription.text = "Duration"
            if LevelPackSetup().powerUpTimerArray[powerUpIndex!] == "" {
                hideCell(cell: cell)
                return cell
            }
            if LevelPackSetup().powerUpTimerArray[powerUpIndex!] == "5" {
                cell.statValue.text = LevelPackSetup().powerUpTimerArray[powerUpIndex!]+" catches"
            }
            if LevelPackSetup().powerUpTimerArray[powerUpIndex!] == "10" {
                cell.statValue.text = LevelPackSetup().powerUpTimerArray[powerUpIndex!]+" s"
            }
            return cell
        case 2:
            cell.statDescription.text = "Collected"
            cell.statValue.text = String(totalStatsArray[0].powerupsCollected[powerUpIndex!])
            return cell
        case 3:
            cell.statDescription.text = "Left"
            cell.statValue.text = String(totalStatsArray[0].powerupsGenerated[powerUpIndex!] - totalStatsArray[0].powerupsCollected[powerUpIndex!])
            return cell
        default:
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
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
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

        titleLabel.text = LevelPackSetup().powerUpNameArray[powerUpIndex!].uppercased()
        powerUpImage.image = LevelPackSetup().powerUpImageArray[powerUpIndex!]
//        powerUpActionImage.image = ""
        descriptionLabel.text = LevelPackSetup().powerUpDescriptionArray[powerUpIndex!]
        
        powerUpImage.layer.masksToBounds = false
        powerUpImage.layer.shadowColor = UIColor.black.cgColor
        powerUpImage.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        powerUpImage.layer.shadowRadius = 10.0
        powerUpImage.layer.shadowOpacity = 0.75
        
        powerUpActionImage.layer.masksToBounds = false
        powerUpActionImage.layer.shadowColor = UIColor.black.cgColor
        powerUpActionImage.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        powerUpActionImage.layer.shadowRadius = 10.0
        powerUpActionImage.layer.shadowOpacity = 0.75
    }
}
