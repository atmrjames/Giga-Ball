//
//  LevelSelectorViewController.swift
//  Megaball
//
//  Created by James Harding on 12/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class LevelSelectorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let defaults = UserDefaults.standard
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    // User settings
    
    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var packStatsArray: [PackStats] = []
    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
    let formatter = DateFormatter()
    // Setup date formatter
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    // UI property setup
    
    var packNumber: Int?
    var numberOfLevels: Int?
    var startLevel: Int?
    var levelSender: String = "MainMenu"
    var statRows: Int = 6
    var numberOfAttempts = 0
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var levelSelectView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var statsTableView: UITableView!
    @IBOutlet var levelsTableView: UITableView!
    @IBOutlet var levelsHeaderLabel: UIButton!
    @IBOutlet var statsTableViewChevron: UIButton!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    @IBOutlet var statsTableViewHeight: NSLayoutConstraint!
    @IBOutlet var noStatsTableViewHeight: NSLayoutConstraint!
    @IBOutlet var collapsedStatsTableViewHeight: NSLayoutConstraint!
    // Stats table view constraints
    
    @IBAction func levelsHeaderButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        levelsTableView.setContentOffset(.zero, animated: true)
    }
    // UIViewController actions
    @IBAction func statisticsHeaderButton(_ sender: Any) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        statsTableOpenClose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnFromGameNotificationKeyReceived), name: .returnFromGameNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from game
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnLevelSelectFromStatsNotificationKeyReceived), name: .returnLevelSelectFromStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        collectionViewLayout()
        // Collection view setup
        
        userSettings()
        loadData()
        
        statsTableView.delegate = self
        statsTableView.dataSource = self
        statsTableView.register(UINib(nibName: "StatsTableViewCell", bundle: nil), forCellReuseIdentifier: "customStatCell")
        // Stats tableView setup
        
        levelsTableView.delegate = self
        levelsTableView.dataSource = self
        levelsTableView.register(UINib(nibName: "LevelSelectorTableViewCell", bundle: nil), forCellReuseIdentifier: "levelSelectorCell")
        // Levels tableView setup
        
        if parallaxSetting! {
            addParallax()
        }
        updateLabels()
        showAnimate()
        reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.statsTableView {
            return statRows
        } else {
            return numberOfLevels!
        }
    }
    // Set number of cells in table views
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        numberOfAttempts = packStatsArray[packNumber!].scores.count
        let scoreArraySum = packStatsArray[packNumber!].scores.reduce(0, +)
        
        statsTableView.rowHeight = 35.0
        levelsTableView.rowHeight = 150.0
        
        if tableView == self.statsTableView {
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    cell.statDescription.text = "No statistics available"
                    cell.statValue.text = ""
                } else {
                    cell.statDescription.text = "Highscore"
                    if let highScore = packStatsArray[packNumber!].scores.max() {
                        cell.statValue.text = String(highScore)
                    } else {
                        cell.statValue.text = ""
                    }
                }
                return cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Highscore date"
                    
                    if let highScore = packStatsArray[packNumber!].scores.max() {
                        let highScoreIndex = packStatsArray[packNumber!].scores.firstIndex(of: highScore)
                        let highScoreDate = packStatsArray[packNumber!].scoreDates[highScoreIndex!]
                        // Find date of highscore
                        
                        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let inputDate = formatter.string(from: highScoreDate)
                        let outputDate = formatter.date(from: inputDate)
                        formatter.dateFormat = "dd/MM/yyyy"
                        let convertedDate = formatter.string(from: outputDate!)
                        // Date to string conversion
                        
                        cell.statValue.text = convertedDate
                    } else {
                        cell.statValue.text = ""
                    }
                }
                return cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Plays"
                    cell.statValue.text = String(numberOfAttempts)
                }
                return cell
            case 3:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Completion rate"
                    
                    let completionRate: Double = Double(packStatsArray[packNumber!].numberOfCompletes)/Double(numberOfAttempts)*100.0

                    let completionRateString = String(format:"%.1f", completionRate)
                    // Double to string conversion to 1 decimal place
                    
                    cell.statValue.text = String(completionRateString)+"%"
                }
                return cell
            case 4:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Cumulative score"
                    cell.statValue.text = String(scoreArraySum)
                }
                return cell
            case 5:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                if numberOfAttempts == 0 {
                    hideCell(cell: cell)
                } else {
                    statsTableView.rowHeight = 35.0
                    cell.statDescription.text = "Average score"
                    let averageScore = scoreArraySum/numberOfAttempts
                    cell.statValue.text = String(averageScore)
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell", for: indexPath) as! StatsTableViewCell
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "levelSelectorCell", for: indexPath) as! LevelSelectorTableViewCell
            cell.levelLabel.text = "Level "+String(indexPath.row+1)
            cell.levelNameLabel.text = LevelPackSetup().levelNameArray[startLevel!+indexPath.row]
            cell.highScoreTitleLabel.text = "Highscore"
            cell.statsButton.tag = indexPath.row+1
            cell.cellView3.tag = indexPath.row+1
            cell.levelImage.image = LevelPackSetup().levelImageArray[startLevel!+indexPath.row]
            cell.statsButton.addTarget(self, action:#selector(cellStatsButtonClicked(sender:)), for: UIControl.Event.touchUpInside)
            // Setup cell buttons
            let levelNumber = startLevel!+indexPath.row
            if levelStatsArray[levelNumber].scores.isEmpty == false {
                cell.highScoreLabel.text = String(levelStatsArray[levelNumber].scores.max()!)
            } else {
                cell.highScoreTitleLabel.text = ""
                cell.highScoreLabel.text = ""
            }
            UIView.animate(withDuration: 0.1) {
                cell.cellView3.transform = .identity
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.levelsTableView {
            if hapticsSetting! {
                interfaceHaptic.impactOccurred()
            }
            
            UIView.animate(withDuration: 0.1) {
                let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
                cell.cellView3.transform = .init(scaleX: 0.99, y: 0.99)
                cell.cellView3.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
            }
            
            let levelNumber = startLevel!-1 + Int(indexPath.row+1)
            moveToGame(selectedLevel: levelNumber, numberOfLevels: 1, sender: levelSender, levelPack: packNumber!)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
            cell.cellView3.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView3.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.levelsTableView.cellForRow(at: indexPath) as! LevelSelectorTableViewCell
            cell.cellView3.transform = .identity
            cell.cellView3.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
        let cellSpacing = (viewWidth - cellWidth*2)/2
        layout.minimumInteritemSpacing = cellSpacing
        layout.minimumLineSpacing = cellSpacing
        backButtonCollectionView!.collectionViewLayout = layout
    }
    // Set the spacing between collection view cells
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        
        cell.widthConstraint.constant = 40
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonClose.png")
        case 1:
            cell.iconImage.image = UIImage(named:"ButtonPlay.png")
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
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        if indexPath.row == 0 {
            removeAnimate()
            NotificationCenter.default.post(name: .returnPackSelectNotification, object: nil)
        }
        if indexPath.row == 1 {
            moveToGame(selectedLevel: startLevel!, numberOfLevels: numberOfLevels!, sender: levelSender, levelPack: packNumber!)
        }
        
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
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
            case 1:
                cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted.png")
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            switch indexPath.row {
            case 0:
                cell.iconImage.image = UIImage(named:"ButtonClose.png")
            case 1:
                cell.iconImage.image = UIImage(named:"ButtonPlay.png")
            default:
                print("Error: Out of range")
                break
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
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    func moveToLevelStats(startLevel: Int, levelNumber: Int, packNumber: Int) {
        let levelStatsView = self.storyboard?.instantiateViewController(withIdentifier: "levelStatsView") as! LevelStatsViewController
        levelStatsView.startLevel = startLevel
        levelStatsView.levelNumber = levelNumber
        levelStatsView.packNumber = packNumber
        self.addChild(levelStatsView)
        levelStatsView.view.frame = self.view.frame
        self.view.addSubview(levelStatsView.view)
        levelStatsView.didMove(toParent: self)
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
    
    func userSettings() {
        adsSetting = defaults.bool(forKey: "adsSetting")
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
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
            self.levelSelectView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.levelSelectView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.levelSelectView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.levelSelectView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.levelSelectView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.levelSelectView.alpha = 1.0
        })
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
            levelSelectView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        levelSelectView.addMotionEffect(group!)
    }
    
    func loadData() {
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
    
    func moveToLevelStatsSetup(sender: Int) {
        hideAnimate()
        let levelNumber = startLevel! + Int(sender)
        moveToLevelStats(startLevel: startLevel!, levelNumber: levelNumber, packNumber: packNumber!)
    }
    
    func updateLabels() {
        titleLabel.text = LevelPackSetup().packTitles[packNumber!].uppercased()
        numberOfAttempts = packStatsArray[packNumber!].scores.count
        if numberOfAttempts == 0 {
            statsTableViewHeight.isActive = false
            noStatsTableViewHeight.isActive = true
        } else {
            noStatsTableViewHeight.isActive = false
            statsTableViewHeight.isActive = true
        }
        if numberOfLevels! == 1 {
            levelsHeaderLabel.setTitle(String(numberOfLevels!)+" Level", for: .normal)
        } else {
            levelsHeaderLabel.setTitle(String(numberOfLevels!)+" Levels", for: .normal)
        }
        
//        playButtonLabel.setTitle("Play " + LevelPackSetup().packTitles[packNumber!], for: .normal)
    }
    
    func reloadData() {
        statsTableView.reloadData()
        levelsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    
    func statsTableOpenClose() {
        if statsTableView.frame.size.height > 0 {
            statsTableViewHeight.isActive = false
            collapsedStatsTableViewHeight.isActive = true
            UIView.animate(withDuration: 0.25, animations: {
                self.statsTableViewChevron.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
            })
        } else {
            collapsedStatsTableViewHeight.isActive = false
            UIView.animate(withDuration: 0.25, animations: {
                self.statsTableViewChevron.transform = CGAffineTransform(rotationAngle: 0)
            })
            updateLabels()
            
        }
        UIView.animate(withDuration: 0.25) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func cellStatsButtonClicked(sender:UIButton) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        moveToLevelStatsSetup(sender: sender.tag-1)
    }
    
    @objc func returnFromGameNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        reloadData()
        updateLabels()
    }
    // Runs when returning from game
    
    @objc func returnLevelSelectFromStatsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        reloadData()
        updateLabels()
        revealAnimate()
    }
    // Runs when returning from another menu view
    
    
}

extension Notification.Name {
    public static let returnFromGameNotification = Notification.Name(rawValue: "returnFromGameNotification")
    public static let returnLevelSelectFromStatsNotification = Notification.Name(rawValue: "returnLevelSelectFromStatsNotification")
}
// Notification setup
