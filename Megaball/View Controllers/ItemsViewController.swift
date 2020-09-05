
//
//  ItemsViewController.swift
//  Megaball
//
//  Created by James Harding on 27/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class ItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var gameCenterSetting: Bool?
    var ballSetting: Int?
    var paddleSetting: Int?
    var premiumSetting: Bool?
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
    @IBOutlet var itemsView: UIView!
    @IBOutlet var itemsTableView: UITableView!
    
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        defaults.set(gameCenterSetting!, forKey: "gameCenterSetting")
        
        if parallaxSetting! {
            addParallax()
        }
        setBlur()
        collectionViewLayout()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
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
        
        switch indexPath.row {
        case 0:
            cell.settingDescription.text = "Power-Ups"
            cell.iconImage.image = UIImage(named:"iconPowerUp.png")!
        case 1:
            cell.settingDescription.text = "Achievements"
            cell.iconImage.image = UIImage(named:"iconAchievements.png")!
        case 2:
            cell.settingDescription.text = "Statistics"
            cell.iconImage.image = UIImage(named:"iconStats.png")!
        case 3:
            if gameCenterSetting! {
                cell.settingDescription.text = "Game Center"
                cell.iconImage.image = UIImage(named:"iconGameCenter.png")!
            } else {
                hideCell(cell: cell)
                return cell
            }
        case 4:
            cell.settingDescription.text = "Quick Start Guide"
            cell.iconImage.image = UIImage(named:"iconTutorial.png")!
        case 5:
            if premiumSetting! {
                hideCell(cell: cell)
                return cell
            } else {
                cell.settingDescription.text = "Giga-Ball Premium"
                cell.iconImage.image = UIImage(named:"iconPremium.png")!
            }
        case 6:
            cell.settingDescription.text = "Purchase Soundtrack"
            cell.iconImage.image = UIImage(named:"iconMusic.png")!
            hideCell(cell: cell)
            return cell
        case 7:
            cell.settingDescription.text = "Rate Giga-Ball"
            cell.iconImage.image = UIImage(named:"iconReview.png")!
        case 8:
            cell.settingDescription.text = "Share"
            cell.iconImage.image = UIImage(named:"iconShare.png")!
        case 9:
            cell.settingDescription.text = "About"
            cell.iconImage.image = UIImage(named:"iconAbout.png")!
        
        default:
            break
        }
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    
    func hideCell(cell: SettingsTableViewCell) {
        cell.centreLabel.text = ""
        cell.settingState.text = ""
        cell.settingDescription.text = ""
        cell.iconImage.image = nil
        itemsTableView.rowHeight = 0.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        switch indexPath.row {
        case 0:
        // Power-ups
            moveToItemDetails(senderID: 2)
        case 1:
        // Achievements
            moveToItemDetails(senderID: 3)
        case 2:
        // Stats
            moveToStats()
        case 3:
        // Game Center
            showGameCenterLeaderboards()
        case 4:
        // Tutorial
            moveToIntro()
        case 5:
        // Premium
            moveToPremiumInfo()
        case 6:
        // Purchase soundtrack
            if let purchaseSoundTrackURL = URL(string: "https://www.giga-ball.app") {
                UIApplication.shared.open(purchaseSoundTrackURL)
            }
        case 7:
        // Review
            guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id1494628204?action=write-review")
                else { fatalError("Expected a valid URL") }
            UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
        case 8:
        // Share
            let shareURL: [Any] = ["Check out Giga-Ball on the App Store", URL(string: "https://apps.apple.com/app/id1494628204")!]
            let shareSheet = UIActivityViewController(activityItems: shareURL, applicationActivities: nil)
            
            if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad ){
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
        case 9:
        // About
            moveToAbout()
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.itemsTableView.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        var viewWidth = view.frame.size.width
        if view.frame.size.width > 414 {
            viewWidth = itemsView.frame.size.width
        }
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
             cell.iconImage.image = UIImage(named:"ButtonNull")
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
            removeAnimate()
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
                 cell.iconImage.image = UIImage(named:"ButtonNull")
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
                cell.iconImage.image = UIImage(named:"ButtonNull")
            case 2:
                cell.iconImage.image = UIImage(named:"ButtonNull")
            default:
                print("Error: Out of range")
                break
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
        
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
        premiumSetting = defaults.bool(forKey: "premiumSetting")
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
        self.addChild(itemsDetailView)
        itemsDetailView.view.frame = self.view.frame
        self.view.addSubview(itemsDetailView.view)
        itemsDetailView.didMove(toParent: self)
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
    
    func moveToPremiumInfo() {
        hideAnimate()
        let premiumInfoView = self.storyboard?.instantiateViewController(withIdentifier: "premiumInfoView") as! PremiumInfoViewController
        premiumInfoView.sender = "Info"
        self.addChild(premiumInfoView)
        premiumInfoView.view.frame = self.view.frame
        self.view.addSubview(premiumInfoView.view)
        premiumInfoView.didMove(toParent: self)
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
        if gameCenterSetting! {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController
        let gcViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        gcViewController.viewState = GKGameCenterViewControllerState.achievements
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

