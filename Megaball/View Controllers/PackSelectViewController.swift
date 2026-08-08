//
//  PackSelectViewController.swift
//  Megaball
//
//  Created by James Harding on 10/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class PackSelectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource , MenuNavigable, MenuNavigationPresenter {
    
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
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    // UI property setup
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var packView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var packTableView: UITableView!
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnPackSelectNotificationKeyReceived), name: .returnPackSelectNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        userSettings()
        loadData()
        
        packTableView.delegate = self
        packTableView.dataSource = self
        packTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        packTableView.rowHeight = 70.0
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        
        
        setBlur()
        if parallaxSetting {
            addParallax()
        }
        showAnimate()
        packTableView.reloadData()
        backButtonCollectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
    }

    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 11
    }
    // Set number of cells in table views
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        cell.blurView.isHidden = true
        cell.lockedImageView.isHidden = true
        
        cell.centreLabel.text = ""
        cell.settingState.text = ""
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cell.settingDescription.text = LevelPackSetup().levelPackNameArray[indexPath.row+2]
        
        cell.descriptionAndStateSharedWidthConstraint.isActive = false
        cell.descriptionTickWidthConstraint.isActive = false
        cell.decriptionFullWidthConstraint.isActive = true
        cell.tickImage.isHidden = true
        
        if totalStatsArray[0].packBestTimes[indexPath.row] > 0 {
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = true
            cell.tickImage.isHidden = false
        }
        // Show tick if pack has been completed at least once
        
        cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cell.settingDescription.font = cell.settingDescription.font.withSize(18)
        
        switch indexPath.row+2 {
        case 2:
            cell.iconImage.image = UIImage(named:"iconClassicPack.png")!
        case 3:
            cell.iconImage.image = UIImage(named:"iconSpacePack.png")!
        case 4:
            cell.iconImage.image = UIImage(named:"iconNaturePack.png")!
        case 5:
            cell.iconImage.image = UIImage(named:"iconUrbanPack.png")!
        case 6:
            cell.iconImage.image = UIImage(named:"iconFoodPack.png")!
        case 7:
            cell.iconImage.image = UIImage(named:"iconComputerPack.png")!
        case 8:
            cell.iconImage.image = UIImage(named:"iconBodyPack.png")!
        case 9:
            cell.iconImage.image = UIImage(named:"iconWorldPack.png")!
        case 10:
            cell.iconImage.image = UIImage(named:"iconEmojiPack.png")!
        case 11:
            cell.iconImage.image = UIImage(named:"iconNumbersPack.png")!
        case 12:
            cell.iconImage.image = UIImage(named:"iconChallengePack.png")!
        default:
            cell.iconImage.image = nil
            break
        }
        
        installPackPlayButton(on: cell,
                              unlocked: totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2])

        if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2] == false {
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = true
            cell.settingDescription.textColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
            cell.settingDescription.font = cell.settingDescription.font.withSize(16)
            if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2-1] {
                cell.settingDescription.text = "Complete \(LevelPackSetup().levelPackNameArray[indexPath.row+1]) to unlock"
            } else {
                cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
            }
            if indexPath.row == 3 {
                cell.settingDescription.text = "Complete first 3 packs to unlock"
            }
            // For level pack 4 show this message
            cell.settingState.text = ""
            cell.blurView.isHidden = false
            cell.lockedImageView.isHidden = false
        }
        // Locked level packs until unlocked

        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = self.packTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
        }
        
        if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+2] {
            hideAnimate()
            moveToLevelSelector(packNumber: indexPath.row+2, numberOfLevels: LevelPackSetup().numberOfLevels[indexPath.row+2], startLevel: LevelPackSetup().startLevelNumber[indexPath.row+2])
        }
        // Don't allow selection if level pack is locked
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.packTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.packTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
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
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.iconImage.image = UIImage(named:"ButtonClose.png")
            }
        }
    }
    
    /// The straight-in button on every pack row: skip the level list, play the pack.
    func installPackPlayButton(on cell: UITableViewCell, unlocked: Bool) {
        cell.contentView.viewWithTag(9901)?.removeFromSuperview()
        guard unlocked else { return }

        let play = UIButton(type: .system)
        play.tag = 9901
        play.setImage(UIImage(systemName: "play.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 17,
                                                                             weight: .heavy)),
                      for: .normal)
        play.tintColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        play.translatesAutoresizingMaskIntoConstraints = false
        play.addTarget(self, action: #selector(packPlayTapped(_:)), for: .touchUpInside)
        cell.contentView.addSubview(play)
        NSLayoutConstraint.activate([
            play.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor,
                                           constant: -18),
            play.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 44),
            play.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc func packPlayTapped(_ sender: UIButton) {
        var view: UIView? = sender
        while view != nil, (view as? UITableViewCell) == nil { view = view?.superview }
        guard let cell = view as? UITableViewCell,
              let indexPath = packTableView.indexPath(for: cell) else { return }
        // The row is asked for at tap time rather than baked into the button, because
        // cells are reused and a stale tag starts the wrong pack

        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let pack = indexPath.row + 2
        MenuViewController().clearSavedGame()
        moveToGame(selectedLevel: LevelPackSetup().startLevelNumber[pack],
                   numberOfLevels: LevelPackSetup().numberOfLevels[pack],
                   sender: "MainMenu", levelPack: pack)
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
    // Straight into the pack, exactly as the level screens launch it

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
    
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
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
            packView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        packView.addMotionEffect(group!)
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
            self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.packView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.packView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.packView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.packView.alpha = 1.0
        })
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
    
    @objc func returnPackSelectNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        revealAnimate()
        packTableView.reloadData()
    }
    // Runs when returning from another menu view
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        packTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnPackSelectNotification = Notification.Name(rawValue: "returnPackSelectNotification")
}
// Notification setup
