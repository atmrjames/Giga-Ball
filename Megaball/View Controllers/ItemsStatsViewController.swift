//
//  ItemsStatsViewController.swift
//  Megaball
//
//  Created by James Harding on 22/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ItemsStatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, MenuNavigable {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
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
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
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
        
        if parallaxSetting {
            addParallax()
        }
        updateLabels()
        statsTableView.reloadData()
        backButtonCollectionView.reloadData()

        installReturnToGameButton()
        // The way back into a paused run, from wherever this screen was reached
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        alignDescription()
    }

    /// Whether a description belongs centred under the icon and the name.
    ///
    /// A short one reads as the last line of the heading, and centring it finishes the column
    /// the icon and the title start. A long one does not: a paragraph centred on both edges is
    /// harder to read than the same words set flush left, because every line starts somewhere
    /// new. The brick types write paragraphs where the power-ups write a phrase, so the page
    /// decides per item rather than choosing one alignment and being wrong on half of them.
    ///
    /// Two lines is the boundary because two ragged starts still scan as a heading; three is
    /// where it starts reading as body text.
    static func descriptionIsCentred(_ text: String, font: UIFont, width: CGFloat) -> Bool {
        guard width > 0, font.lineHeight > 0 else { return true }
        let height = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil).height
        return Int((height/font.lineHeight).rounded()) <= 2
    }

    private func alignDescription() {
        guard let text = descriptionLabel.text, let font = descriptionLabel.font else { return }
        descriptionLabel.textAlignment = ItemsStatsViewController.descriptionIsCentred(
            text, font: font, width: descriptionLabel.bounds.width) ? .center : .natural
    }


    /// What `sender` is set to when this screen is showing a brick type.
    ///
    /// The brick types page reuses this screen rather than growing one of its own: an icon, a
    /// name, a description and a short list of facts is exactly what it already draws, and a
    /// second copy of it would be a second copy to keep looking the same.
    static let brickTypesSender = "Brick Types"

    private var brickTypeEntry: BrickTypeCatalogue.Entry? {
        guard sender == ItemsStatsViewController.brickTypesSender, let index = passedIndex else {
            return nil
        }
        let entries = BrickTypeCatalogue.allEntries
        guard entries.indices.contains(index) else { return nil }
        return entries[index]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let entry = brickTypeEntry {
            return entry.facts.count
        }
        if sender == "Power-Ups" {
            return mayhemOnlyPowerUp ? 6 : 5
            // The sixth row is the "Found in" line, and it only exists for the power-ups that
            // are not found everywhere. Counted rather than added and hidden, because a hidden
            // row on this screen works by zeroing the whole table's row height
        } else {
            return 1
        }
    }

    /// Whether the power-up being shown only exists in Endless Mayhem.
    ///
    /// The list page marks these with the mode's mark; this page has room to say it in words,
    /// which is the division the brick types page already draws - a badge in the list, the
    /// sentence on the page you open.
    private var mayhemOnlyPowerUp: Bool {
        guard sender == "Power-Ups", let index = passedIndex else { return false }
        return LevelPackSetup().isEndlessIIPowerUp(index)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        
        statsTableView.rowHeight = 35.0

        if let entry = brickTypeEntry {
            let fact = entry.facts[indexPath.row]
            cell.statDescription.text = fact.label
            cell.statValue.text = fact.value

            // These values are sentences where a power-up's are numbers, and the two labels
            // share the row's width - a long one pushed its own label out of the row and left
            // a stat with no name on it
            cell.statDescription.setContentCompressionResistancePriority(.required, for: .horizontal)
            cell.statValue.adjustsFontSizeToFitWidth = true
            cell.statValue.minimumScaleFactor = 0.6
            return cell
        }

        if sender == "Power-Ups" {
            switch indexPath.row {
            case 0:
                if LevelPackSetup().powerUpMultiplierArray[passedIndex!] == "" {
                    hideCell(cell: cell)
                    return cell
                } else {
                    cell.statValue.text = LevelPackSetup().powerUpMultiplierArray[passedIndex!]
                    if LevelPackSetup().powerUpMultiplierArray[passedIndex!].hasPrefix("+") {
                        cell.statDescription.text = "Multiplier bonus"
                    } else {
                        cell.statDescription.text = "Multiplier penalty"
                    }
                    // By the sign, not by matching one exact string - the old comparison
                    // looked for "+0.1x", the array holds "+0.1", so every bonus in the
                    // game has been labelled a penalty (and "Mutliplier" a typo) since
                    // whenever that x was dropped
                }
                return cell
            case 1:
                cell.statDescription.text = "Duration"
                if LevelPackSetup().powerUpTimerArray[passedIndex!] == "" {
                    hideCell(cell: cell)
                    return cell
                }
                cell.statValue.text = LevelPackSetup().powerUpTimerArray[passedIndex!]
                // The array carries its own units now - seconds, catches or paddle hits -
                // so this page stops guessing the unit from the number
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
            case 5:
                cell.statDescription.text = "Found in"
                cell.statValue.text = GameMode.endlessII.name
                // The mode's name is asked of GameMode rather than written here, so this line
                // was already correct on the day "Endless 2.0" became "Endless Mayhem"
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
        cell.applyGlass(symbol: "xmark")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        menuNavigationGoBack()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
            }
        }
    }
    
    func hideCell(cell: StatsTableViewCell) {
        cell.statValue.text = ""
        cell.statDescription.text = ""
        statsTableView.rowHeight = 0.0
    }
    
    func userSettings() {
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
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
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
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
        NotificationCenter.default.post(name: .returnItemStatsNotification, object: nil)
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

        if let entry = brickTypeEntry {
            titleLabel.text = entry.name.uppercased()
            powerUpImage.image = BrickTypeIcons.image(for: entry.art)
            descriptionLabel.text = entry.description
            powerUpImage.layer.masksToBounds = false
            return
            // No shadow. The power-up icons are rounded squares that sit on the background,
            // and a shadow lifts them off it; a brick is drawn with room around it, so the
            // same shadow lands under nothing
        }

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
