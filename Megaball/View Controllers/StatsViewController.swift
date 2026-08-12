//
//  StatsViewController.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, GKGameCenterControllerDelegate, MenuNavigable {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    // User settings
    
    var sender: String?
    
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
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var statsView: UIView!
    @IBOutlet var statsTableView: UITableView!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
                
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
        SettingsTableViewCell.addGlass(under: statsTableView, cornerRadius: 14, inset: 20)
        statsTableView.separatorStyle = .none
        // One panel for the whole table rather than a card per row - see
        // `StatsTableViewCell.awakeFromNib` for why
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.clipsToBounds = false
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        if parallaxSetting {
            addParallax()
        }
        
        if sender != "Info" {
            setBlur()
        }
        
        collectionViewLayout()
        installModePicker()
        reloadRows()
        backButtonCollectionView.reloadData()
        installReturnToGameButton()
        // The way back into a paused run, from wherever this screen was reached
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        SettingsTableViewCell.fitGlassPanel(under: statsTableView)
    }

    
    // MARK: - The tabs

    /// The section being shown. Not remembered between visits: a player opening the statistics
    /// is asking a question, and the answer to "how am I doing" starts at Overall.
    private var selectedTab: StatsPage.Tab = .overall

    private weak var modePicker: UISegmentedControl?

    /// The rows the page is currently showing.
    ///
    /// Held rather than asked for per cell, because building them reads several arrays and
    /// `cellForRowAt` is called once for every visible line - the old page did that work
    /// twenty-five times to draw twenty-five rows.
    private var rows: [StatsPage.Row] = []

    private func reloadRows() {
        rows = StatsPage.rows(for: selectedTab, stats: totalStatsArray[0])
        statsTableView.reloadData()
        SettingsTableViewCell.fitGlassPanel(under: statsTableView)
        // Each tab holds a different number of facts, so the panel is re-measured with them
        // rather than waiting for a layout pass that a tab change does not always cause
    }

    /// Puts the section picker between the title and the table.
    ///
    /// Built here rather than in the storyboard so that the way it is coloured sits next to the
    /// rest of the screen's appearance, and so the table's top constraint - the one it has to
    /// displace - is moved in the same place it is replaced. That constraint is found by the
    /// name given to it in the storyboard rather than by position in the array, and the label
    /// it hangs from is read off the constraint itself, so neither needs a second outlet that
    /// could point somewhere else after an edit in Interface Builder.
    private func installModePicker() {
        guard let container = statsTableView.superview else { return }
        guard let tableTop = container.constraints.first(where: { $0.identifier == "statsTableTop" }),
              let titleLabel = tableTop.secondItem as? UIView else { return }

        let picker = UISegmentedControl(items: StatsPage.Tab.allCases.map { $0.title })
        picker.selectedSegmentIndex = selectedTab.rawValue
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.selectedSegmentTintColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        picker.backgroundColor = UIColor(white: 1, alpha: 0.12)
        picker.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .normal)
        picker.setTitleTextAttributes([
            .foregroundColor: #colorLiteral(red: 0.2159586251, green: 0.04048030823, blue: 0.3017641902, alpha: 1),
            .font: UIFont.systemFont(ofSize: 13, weight: .bold)], for: .selected)
        picker.addTarget(self, action: #selector(tabChanged), for: .valueChanged)
        container.addSubview(picker)
        modePicker = picker

        tableTop.isActive = false
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            statsTableView.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 12),
        ])
    }

    @objc private func tabChanged(_ picker: UISegmentedControl) {
        guard let chosen = StatsPage.Tab(rawValue: picker.selectedSegmentIndex) else { return }
        selectedTab = chosen
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        reloadRows()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
        cell.showDivider(indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1)
        statsTableView.rowHeight = 35.0
        let row = rows[indexPath.row]
        cell.statDescription.text = row.label
        cell.statValue.text = row.value
        cell.showIcon(row.icon)
        return cell
    }

    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        var viewWidth = view.frame.size.width
        if view.frame.size.width > 414 {
            viewWidth = statsView.frame.size.width
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
        
        cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        
        switch indexPath.row {
        case 0:
            cell.setButton("ButtonClose")
        case 1:
            cell.setButton("ButtonNull")
        case 2:
            if gameCenterSetting {
                cell.setButton("ButtonLeaderboard")
            } else {
                cell.setButton("ButtonNull")
            }
            // Right-hand slot rather than the middle (round 68). The middle is where this
            // screen's *own* button would go if it had one, and the pack screen already puts
            // its leaderboard on the right - a control that means the same thing should not
            // move about between screens
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
        if indexPath.row == 2 && gameCenterSetting {
            showGameCenterLeaderboards()
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
                    cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted"))
                case 1:
                    cell.setButton("ButtonNull")
                case 2:
                    if self.gameCenterSetting {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.setButton("ButtonLeaderboardHighlighted")
                    } else {
                        cell.setButton("ButtonNull")
                    }
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
                    cell.setPressedArtwork(UIImage(named:"ButtonClose"))
                case 1:
                    cell.setButton("ButtonNull")
                case 2:
                    if self.gameCenterSetting {
                        cell.setButton("ButtonLeaderboard")
                    } else {
                        cell.setButton("ButtonNull")
                    }
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func userSettings() {
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
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
    }

    func removeAnimate() {
        NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
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
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
    }
    // Remove game center view contoller once dismissed
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        reloadRows()
        // Rebuilt rather than redrawn: a sync can bring a mode's first ever run with it, and
        // that changes which rows a section has, not only what they say
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}
