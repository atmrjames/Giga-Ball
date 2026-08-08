//
//  LevelStatsViewController.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class LevelStatsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GKGameCenterControllerDelegate, MenuNavigable, UITableViewDataSource, UITableViewDelegate {
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
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
    var blurView: UIVisualEffectView?
    // UI property setup
    
    var startLevel: Int?
    var levelNumber: Int?
    var packNumber: Int?
    var levelSender: String = "MainMenu"
    // Key properties
    
    var packLevelHighScoresArray: [[Int]]?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var levelStatsView: UIView!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var packNameAndLevelNumberLabel: UILabel!
    @IBOutlet var levelImageView: UIImageView!
    @IBOutlet var highscoreTitleLabel: UILabel!
    @IBOutlet var highscoreLabel: UILabel!
    
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!

    /// The endless modes' run history: every attempt, most recent first - see
    /// `setupRunHistory`. Nil on the classic level screens, which have no runs to list.
    var runHistoryTable: UITableView?
    /// The rows, newest first: height, and when - `nil` for runs recorded before dates were.
    var runHistory: [(height: Int, date: Date?)] = []
    /// Whether the list is ordered by height instead of by date. Height is the default -
    /// James's call from the play test: a best-scores list leads with the best scores,
    /// and a tap flips it to "what have I done lately".
    var runHistorySortsByHeight = true
    var runHistorySortButton: UIButton?
    var runHistoryCountLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnLevelStatsNotificationKeyReceived), name: .returnLevelStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
                
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        userSettings()
        loadData()
        
        if levelNumber == 0 {
            setBlur()
        } else if blurView != nil {
            blurView = nil
        }
        // Only set blur when entering from endless mode otherwise, remove it
        
        if parallaxSetting {
            addParallax()
        }
        updateLabels()
        collectionViewLayout()
        backButtonCollectionView.reloadData()
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        collectionViewLayout()
    }

    
    func collectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let available = backButtonCollectionView.frame.size.width
        // Spread across the width the buttons actually occupy. This used to measure the
        // whole screen, or the container, neither of which is the row the buttons are in
        // once the content is capped - so on iPad they bunched to one side.
        let cellSpacing = max(0, (available - 50*2 - LevelStatsViewController.playButtonSize)/3)
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        layout.estimatedItemSize = .zero
        // Self-sizing off: with an estimate set, a cell measures itself from its own
        // constraints and the delegate's 75pt play button never reaches the layout - the
        // cell stays 50 and the button is cropped square (see MainMenuCollectionViewCell)
        layout.sectionInset = UIEdgeInsets(top: 0, left: cellSpacing/2, bottom: 0,
                                           right: cellSpacing/2)
        // Half a gap each end: with equal gaps between the three, that puts the middle
        // button's centre exactly on the row's centre - without it the whole row leans left
        backButtonCollectionView.collectionViewLayout = layout

        for constraint in backButtonCollectionView.constraints
        where constraint.firstAttribute == .height {
            constraint.constant = LevelStatsViewController.playButtonSize
        }
        // The storyboard's row is 50 tall, which is the button size this screen used to
        // have everywhere. The play button now matches the pause menu's, so the row grows
        // to hold it - in code, because the row is shared furniture in the storyboard
    }
    // Set the spacing between collection view cells

    /// The pause menu's play button size, which play-testing asked this screen to match -
    /// the button that starts the run should be the biggest thing on the row.
    static let playButtonSize: CGFloat = 75

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        indexPath.row == 1
            ? CGSize(width: LevelStatsViewController.playButtonSize,
                     height: LevelStatsViewController.playButtonSize)
            : CGSize(width: 50, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.widthConstraint.constant = 40
        // No writing to cell.frame here: the flow layout owns the cell's size, and a
        // manual 50 fought the 75 the delegate gives the play cell - the frame snapped
        // to 50 on every reload and back to 75 on the next layout pass, which is the
        // play-test's "the play button is moving when another button is pressed"
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonClose")
        case 1:
            cell.iconImage.image = UIImage(named:"ButtonPlay")
            cell.widthConstraint.constant = LevelStatsViewController.playButtonSize
            // The big play button belongs in the middle - X left, leaderboard right, the
            // same order the pause menu reads in
        case 2:
            if packNumber == 1 {
                if gameCenterSetting {
                    cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull")
                }
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull")
            }
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
        if indexPath.row == 2 {
            if gameCenterSetting && packNumber == 1 {
                showGameCenterLeaderboards()
            }
            // Only show leaderboard button for endless mode
        }
        if indexPath.row == 1 {
            if levelNumber! == 0 {
            // Endless mode - go straight to level
                MenuViewController().clearSavedGame()
                moveToGame(selectedLevel: levelNumber!, numberOfLevels: 1, sender: levelSender, levelPack: packNumber!)
            } else {
                moveToModeSelect(selectedLevel: levelNumber!, numberOfLevels: 1, sender: levelSender, levelPack: packNumber!)
            }
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
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted")
                case 2:
                    if self.gameCenterSetting && self.packNumber == 1 {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboardHighlighted")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull")
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
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonClose")
                case 1:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlay")
                case 2:
                    if self.gameCenterSetting && self.packNumber == 1 {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboard")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull")
                    }
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
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
    
    func moveToModeSelect(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let modeSelectView = self.storyboard?.instantiateViewController(withIdentifier: "modeSelectView") as! ModeSelectViewController
        modeSelectView.selectedLevel = selectedLevel
        modeSelectView.numberOfLevels = numberOfLevels
        modeSelectView.levelSender = sender
        modeSelectView.levelPack = levelPack
        self.addChild(modeSelectView)
        modeSelectView.view.frame = self.view.frame
        self.view.addSubview(modeSelectView.view)
        modeSelectView.didMove(toParent: self)
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
        
        packLevelHighScoresArray = [
            totalStatsArray[0].pack1LevelHighScores, totalStatsArray[0].pack2LevelHighScores, totalStatsArray[0].pack3LevelHighScores, totalStatsArray[0].pack4LevelHighScores, totalStatsArray[0].pack5LevelHighScores, totalStatsArray[0].pack6LevelHighScores, totalStatsArray[0].pack7LevelHighScores, totalStatsArray[0].pack8LevelHighScores, totalStatsArray[0].pack9LevelHighScores, totalStatsArray[0].pack10LevelHighScores, totalStatsArray[0].pack11LevelHighScores
        ]
        
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
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
        NotificationCenter.default.post(name: .returnLevelSelectFromStatsNotification, object: nil)
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
            levelNameLabel.text = GameMode.current(in: defaults).name.uppercased()
            // Both endless modes share level 0, so the name comes from the mode
            packNameAndLevelNumberLabel.text = ""
            // No sub-heading in endless mode
        } else {
            packNameAndLevelNumberLabel.text = LevelPackSetup().levelPackNameArray[packNumber!]+" - Level "+String(levelNumber!-startLevel!+1)
        }
        levelImageView.image = LevelPackSetup().levelImageArray[levelNumber!]
        levelImageView.layer.masksToBounds = false
        
        levelImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        levelImageView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        levelImageView.layer.shadowOpacity = 0.5
        levelImageView.layer.shadowRadius = 10
        
        if levelNumber == 0 {
            let mode = GameMode.current(in: defaults)
            highscoreTitleLabel.text = ""
            highscoreLabel.text = ""
            // The big Best Height figure came off this screen (play-test call): the run
            // list below already leads with the best, so the headline was the same number
            // said twice. The best row in the table wears the emphasis instead
            let runs = mode == .endlessII
                ? totalStatsArray[0].endlessIIHeights
                : totalStatsArray[0].endlessModeHeight

            let dates = mode == .endlessII
                ? (totalStatsArray[0].endlessIIModeHeightDate ?? [])
                : totalStatsArray[0].endlessModeHeightDate
            runHistory = runs.enumerated().map { index, height in
                (height, dates.indices.contains(index) ? dates[index] : nil)
            }.reversed()
            // Dates align with heights by index, but heights synced from another device can
            // outnumber the dates - a run without one still shows, it just cannot say when
            setupRunHistory()
        } else {
            highscoreTitleLabel.text = "Highscore"
            if packLevelHighScoresArray![packNumber!-2][levelNumber!-startLevel!] > 0 {
                let highScore = packLevelHighScoresArray![packNumber!-2][levelNumber!-startLevel!]
                highscoreLabel.text = String(highScore)
            } else {
                highscoreLabel.text = "0"
            }
        }
    }
    
    // MARK: - The run history

    /// Puts every previous attempt on the screen, newest first, between the mode's logo and
    /// the buttons - which means taking some of the logo's room: it is re-pinned smaller so
    /// the list has somewhere to live.
    func setupRunHistory() {
        guard runHistory.isEmpty == false else { return }
        // Nothing to list yet: the table waits for a first run, and the logo keeps the room
        guard runHistoryTable == nil else {
            runHistoryCountLabel?.text = runHistory.count == 1
                ? "1 run" : "\(runHistory.count) runs"
            runHistoryTable?.reloadData()
            return
        }

        for constraint in levelStatsView.constraints {
            let involves = constraint.firstItem === levelImageView
                || constraint.secondItem === levelImageView
            let horizontal = [NSLayoutConstraint.Attribute.leading, .trailing]
                .contains(constraint.firstAttribute)
            if involves && horizontal { constraint.isActive = false }
        }
        NSLayoutConstraint.activate([
            levelImageView.centerXAnchor.constraint(equalTo: levelStatsView.centerXAnchor),
            levelImageView.widthAnchor.constraint(equalToConstant: 190),
        ])
        // The logo was pinned wall to wall and sized by its 1:1 aspect. Cutting it loose
        // horizontally and giving it a width leaves the aspect doing the height, and the
        // labels below follow it up because they were pinned to its bottom all along

        let sort = UIButton(type: .system)
        sort.translatesAutoresizingMaskIntoConstraints = false
        sort.setTitle("HEIGHT ▾", for: .normal)
        sort.setTitleColor(UIColor(white: 1, alpha: 0.55), for: .normal)
        sort.titleLabel?.font = .boldSystemFont(ofSize: 12)
        sort.addTarget(self, action: #selector(toggleRunHistorySort), for: .touchUpInside)
        levelStatsView.addSubview(sort)
        NSLayoutConstraint.activate([
            sort.topAnchor.constraint(equalTo: highscoreLabel.bottomAnchor, constant: 6),
            sort.centerXAnchor.constraint(equalTo: levelStatsView.centerXAnchor),
        ])
        runHistorySortButton = sort
        // One small word, centred over the list where a column header would be (the
        // play test asked for it centred at the top of the table) - the list leads with
        // the best heights until the player asks it the other question

        let count = UILabel()
        count.translatesAutoresizingMaskIntoConstraints = false
        count.font = .systemFont(ofSize: 12)
        count.textColor = UIColor(white: 1, alpha: 0.4)
        count.text = runHistory.count == 1 ? "1 run" : "\(runHistory.count) runs"
        levelStatsView.addSubview(count)
        NSLayoutConstraint.activate([
            count.centerYAnchor.constraint(equalTo: sort.centerYAnchor),
            count.trailingAnchor.constraint(equalTo: levelStatsView.trailingAnchor,
                                            constant: -44),
        ])
        runHistoryCountLabel = count
        // Small and subtle, at the end of the header row (play-test request): how many
        // times the mode has been played, without making the list say it

        let table = ContentAwareTableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorColor = UIColor(white: 1, alpha: 0.12)
        table.separatorInset = .zero
        table.rowHeight = 34
        table.dataSource = self
        table.delegate = self
        table.allowsSelection = false
        levelStatsView.addSubview(table)
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: sort.bottomAnchor, constant: 4),
            table.bottomAnchor.constraint(equalTo: backButtonCollectionView.topAnchor,
                                          constant: -20),
            table.leadingAnchor.constraint(equalTo: levelStatsView.leadingAnchor,
                                           constant: 44),
            table.trailingAnchor.constraint(equalTo: levelStatsView.trailingAnchor,
                                            constant: -44),
        ])
        runHistoryTable = table
        // ContentAwareTableView rather than a plain table (play-test request): when the
        // list has more runs than fit, the content fades at whichever edge continues,
        // and the extra clearance keeps the fade from crowding the buttons below
    }

    /// Flips between the two orders a run list can answer for: when, and how high.
    @objc func toggleRunHistorySort() {
        runHistorySortsByHeight.toggle()
        runHistorySortButton?.setTitle(runHistorySortsByHeight ? "HEIGHT ▾" : "DATE ▾",
                                       for: .normal)
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        runHistoryTable?.reloadData()
    }

    /// The rows in the order the toggle asks for.
    ///
    /// By date is the stored order - newest first. By height sorts descending, ties newest
    /// first, so equal runs keep their recency order rather than shuffling.
    var sortedRunHistory: [(height: Int, date: Date?)] {
        guard runHistorySortsByHeight else { return runHistory }
        return runHistory.enumerated()
            .sorted { a, b in
                a.element.height != b.element.height
                    ? a.element.height > b.element.height
                    : a.offset < b.offset
            }
            .map(\.element)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        runHistory.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "run")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "run")
        cell.backgroundColor = .clear
        let entry = sortedRunHistory[indexPath.row]

        cell.textLabel?.text = "\(entry.height)m"
        let isBest = entry.height == runHistory.map(\.height).max()
        cell.textLabel?.font = .boldSystemFont(ofSize: isBest ? 19 : 15)
        cell.textLabel?.textColor = isBest
            ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            : .white
        // The best run wears the Giga-Ball green and a size up: with the headline Best
        // Height figure gone, this row is where the best lives now (play-test call)

        if let date = entry.date {
            cell.detailTextLabel?.text = LevelStatsViewController.runDateFormat.string(from: date)
        } else {
            cell.detailTextLabel?.text = "—"
        }
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = UIColor(white: 1, alpha: 0.55)
        return cell
    }

    static let runDateFormat: DateFormatter = {
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .short
        format.locale = .autoupdatingCurrent
        // The phone's own settings decide how a date and time read - region and 12/24
        // hour clock both. Styles rather than a format string, for the same reason
        return format
    }()

    func showGameCenterLeaderboards() {
        if gameCenterSetting {
            GameCenterHandler().gameCenterSave()
        }
        // Save scores to game center
        let viewController = self.view.window?.rootViewController

        let gcViewController = GKGameCenterViewController(leaderboardID: LevelPackSetup().levelLeaderboardsArray[levelNumber!], playerScope: .global, timeScope: .allTime)
        gcViewController.gameCenterDelegate = self
        // Show corresponding leaderboard for the current level

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
    
    @objc func returnLevelStatsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        updateLabels()
    }
    // Runs when returning from game
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        updateLabels()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}

extension Notification.Name {
    public static let returnLevelStatsNotification = Notification.Name(rawValue: "returnLevelStatsNotification")
}
// Notification setup
