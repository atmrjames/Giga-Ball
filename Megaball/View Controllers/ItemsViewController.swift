
//
//  ItemsViewController.swift
//  Megaball
//
//  Created by James Harding on 27/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class ItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate, MenuNavigable, MenuNavigationPresenter {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    var ballSetting: Int = 0
    var paddleSetting: Int = 0
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

    /// Which screen opened this one. "PauseMenu" when it is being used mid-run.
    var navigatedFrom: String = "MainMenu"

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var itemsView: UIView!
    @IBOutlet var itemsTableView: UITableView!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnItemDetailsNotificationKeyReceived), name: .returnItemDetailsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
                
        itemsTableView.rowHeight = 70.0
        
        userSettings()
        loadData()
        
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
        
        if parallaxSetting {
            addParallax()
        }
        setBlur()
        collectionViewLayout()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        collectionViewLayout()
    }

    

    /// The rows the information screen offers, already filtered to what is available.
    ///
    /// The screen used to number its rows by hand and blank out the ones it did not want
    /// - the removed Premium entry, and Game Center when it is switched off. A blanked
    /// cell still takes up a row, so there was a gap between Quick Start Guide and the
    /// SoundCloud link. Rows that are not offered are now simply not in the list.
    enum InfoRow {
        case powerUps, brickTypes, achievements, statistics, gameCenter, quickStart, soundCloud
        case rate, share, about

        var title: String {
            switch self {
            case .powerUps: return "Power-Ups"
            case .brickTypes: return "Bricks"
            case .achievements: return "Achievements"
            case .statistics: return "Statistics"
            case .gameCenter: return "Game Center"
            case .quickStart: return "Quick Start Guide"
            case .soundCloud: return "SoundCloud Link"
            case .rate: return "Rate Giga-Ball"
            case .share: return "Share"
            case .about: return "About"
            }
        }

        var iconName: String {
            switch self {
            case .powerUps: return "iconPowerUp.png"
            case .brickTypes: return "iconBricks.png"
            case .achievements: return "iconAchievements.png"
            case .statistics: return "iconStats.png"
            case .gameCenter: return "iconGameCenter.png"
            case .quickStart: return "iconTutorial.png"
            case .soundCloud: return "iconMusic.png"
            case .rate: return "iconReview.png"
            case .share: return "iconShare.png"
            case .about: return "iconAbout.png"
            }
        }
    }

    var infoRows: [InfoRow] {
        var rows: [InfoRow] = [.powerUps, .brickTypes, .achievements, .statistics]
        if gameCenterSetting { rows.append(.gameCenter) }

        guard navigatedFrom != "PauseMenu" else { return rows }
        // Opened over a paused game, this is a reference rather than a menu. What is left out
        // is everything that takes the player out of the app or out of the run: the tutorial
        // restarts on top of a live game, and Rate, Share, SoundCloud and About all lead
        // somewhere else entirely, which is not what somebody who paused to look something up
        // is after

        rows += [.quickStart, .soundCloud, .rate, .share, .about]
        return rows
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return infoRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        itemsTableView.rowHeight = 70.0
        
        cell.centreLabel.text = ""
        cell.settingState.text = ""
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        
        cell.descriptionAndStateSharedWidthConstraint.isActive = false
        cell.descriptionTickWidthConstraint.isActive = false
        cell.decriptionFullWidthConstraint.isActive = true
        
        let row = infoRows[indexPath.row]
        cell.settingDescription.text = row.title
        cell.iconImage.image = UIImage(named: row.iconName)

        return cell
    }
    // Add content to cells

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        switch infoRows[indexPath.row] {
        case .powerUps:
            moveToItemDetails(senderID: 2)
        case .brickTypes:
            moveToBrickTypes()
        case .achievements:
            moveToItemDetails(senderID: 3)
        case .statistics:
            moveToStats()
        case .gameCenter:
            showGameCenterLeaderboards()
        case .quickStart:
            moveToIntro()
        case .soundCloud:
            if let purchaseSoundTrackURL = URL(string: "https://soundcloud.com/user-371123791/sets/giga-ball-original-sound-track?ref=clipboard&p=i&c=1") {
                UIApplication.shared.open(purchaseSoundTrackURL)
            }
        case .rate:
            guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id1494628204?action=write-review")
                else { fatalError("Expected a valid URL") }
            UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
        case .share:
            let shareURL: [Any] = ["Check out Giga-Ball on the App Store", URL(string: "https://apps.apple.com/app/id1494628204")!]
            let shareSheet = UIActivityViewController(activityItems: shareURL, applicationActivities: nil)
            
            if ( UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ){
                let rectOfCellInTableView = tableView.rectForRow(at: indexPath)
                let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: tableView.backgroundView)
                let popUpPosition = rectOfCellInSuperview.origin.y + cell.cellView2.frame.height/2
                // Determine y poision of selected cell

                if let popoverController = shareSheet.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: popUpPosition, width: 0, height: 0)
                }
                // Show pop-up at selected cell position
            }
            // Determine where to display the share sheet on iPads
            
            self.present(shareSheet, animated: true, completion: nil)
        case .about:
            moveToAbout()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
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
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
             cell.iconImage.image = UIImage(named:"ButtonNull")
        case 2:
            cell.iconImage.image = UIImage(named:"ButtonNull")
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
                     cell.iconImage.image = UIImage(named:"ButtonNull")
                case 2:
                    cell.iconImage.image = UIImage(named:"ButtonNull")
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
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                case 2:
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func showGameCenterLeaderboards() {
        if gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController
        let gcViewController = GKGameCenterViewController(state: .leaderboards)
        gcViewController.gameCenterDelegate = self
//        gcViewController.viewState = GKGameCenterViewControllerState.leaderboards
        viewController?.present(gcViewController, animated: true, completion: nil)
    }
    // Show game center view controller
        
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
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
            itemsView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        itemsView.addMotionEffect(group!)
    }
    
    func moveToItemDetails(senderID: Int) {
        hideAnimate()
        let itemsDetailView = self.storyboard?.instantiateViewController(withIdentifier: "itemsDetailView") as! ItemsDetailViewController
        itemsDetailView.senderID = senderID
        itemsDetailView.navigatedFrom = navigatedFrom
        // Carried through so the power-ups page can lead with this run's recents when
        // the whole stack was opened from the pause menu (§12.0)
        self.addChild(itemsDetailView)
        itemsDetailView.view.frame = self.view.frame
        self.view.addSubview(itemsDetailView.view)
        itemsDetailView.didMove(toParent: self)
    }
    
    func moveToBrickTypes() {
        hideAnimate()
        let brickTypesView = self.storyboard?.instantiateViewController(withIdentifier: "brickTypesView") as! BrickTypesViewController
        brickTypesView.navigatedFrom = navigatedFrom
        self.addChild(brickTypesView)
        brickTypesView.view.frame = self.view.frame
        self.view.addSubview(brickTypesView.view)
        brickTypesView.didMove(toParent: self)
    }

    func moveToAbout() {
        hideAnimate()
        let aboutView = self.storyboard?.instantiateViewController(withIdentifier: "aboutVC") as! AboutViewController
        aboutView.sender = "Info"
        self.addChild(aboutView)
        aboutView.view.frame = self.view.frame
        self.view.addSubview(aboutView.view)
        aboutView.didMove(toParent: self)
    }
    
    func moveToStats() {
        hideAnimate()
        let statsView = self.storyboard?.instantiateViewController(withIdentifier: "statsView") as! StatsViewController
        statsView.sender = "Info"
        self.addChild(statsView)
        statsView.view.frame = self.view.frame
        self.view.addSubview(statsView.view)
        statsView.didMove(toParent: self)
    }
    
    func moveToIntro() {
        hideAnimate()
        let introView = self.storyboard?.instantiateViewController(withIdentifier: "introVC") as! IntroViewController
        introView.sender = "Info"
        self.addChild(introView)
        introView.view.frame = self.view.frame
        self.view.addSubview(introView.view)
        introView.didMove(toParent: self)
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
        if navigatedFrom == "PauseMenu" {
            NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
            // The pause menu hid itself to make room, and is watching for this to come back
        }
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
    
    /// Fades this screen out behind one it opened - or one being returned to by a forward
    /// swipe, which is the same thing seen from the other side.
    func menuNavigationHideBehindChild() {
        hideAnimate()
    }

    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.itemsView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.itemsView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.itemsView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.itemsView.alpha = 1.0
        })
    }
    
    func showGameCenterAchievements() {
        if gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController
        let gcViewController = GKGameCenterViewController(state: .achievements)
        gcViewController.gameCenterDelegate = self
//        gcViewController.viewState = GKGameCenterViewControllerState.achievements
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
    
    @objc func returnItemDetailsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        itemsTableView.reloadData()
        revealAnimate()
    }
    // Runs when returning from item stats view
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnItemDetailsNotification = Notification.Name(rawValue: "returnItemDetailsNotification")
}
// Notification setup

