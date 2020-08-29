//
//  PauseMenuViewController.swift
//  Megaball
//
//  Created by James Harding on 17/10/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class PauseMenuViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var levelNumber: Int = 0
    var numberOfLevels: Int = 0
    var score: Int = 0
    var packNumber: Int = 0
    var height: Int = 0
    var sender: String = ""
    var gameoverBool: Bool = false
    var newItemsBool: Bool = false
    var previousHighscore: Int = 0
    // Properties to store passed over data
    
    let defaults = UserDefaults.standard
    var premiumSetting: Bool?
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
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    var endlessMode: Bool = false
    
    var packLevelHighScoresArray: [[Int]]?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var containterView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var scoreLabelTitle: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    @IBOutlet var buttonCollectionView: UICollectionView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var packNameLabel: UILabel!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var newItemsLabel: UILabel!
    
    @IBOutlet var levelTitleLowerConstraint: NSLayoutConstraint!
    @IBOutlet var levelNameLabelNormalConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnPauseNotificationKeyReceived), name: .returnPauseNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned to the pause menu from the settings menu
        NotificationCenter.default.addObserver(self, selector: #selector(self.killBallRemoveVCKeyReceived), name: .killBallRemoveVC, object: nil)
        // Sets up an observer to watch for notifications to check if the user has killed the ball from the settings menu to then remove the pause menu
        
        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        buttonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        levelTitleLowerConstraint.isActive = false
        levelNameLabelNormalConstraint.isActive = true
        // Default constraints setting
        
        if levelNumber == 0 {
            endlessMode = true
        } else {
            endlessMode = false
        }
        
        userSettings()
        setBlur()
        if parallaxSetting! {
            addParallaxToView()
        }
        loadData()
        updateLabels()
        collectionViewLayout()
        buttonCollectionView.reloadData()
        showAnimate()
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        if view.frame.size.width <= 414 {
            containterView.frame.size.width = view.frame.size.width
        } else {
            containterView.frame.size.width = 414
        }
        buttonCollectionView.frame.size.width = containterView.frame.size.width-100
        // Ensures the collection view is the correct size
        
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: 75, height: 75)
        let spacing = (buttonCollectionView.frame.size.width-(75*3))/2
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        buttonCollectionView!.collectionViewLayout = layout
    }
    // Set the spacing between collection view cells
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 75
        cell.frame.size.width = cell.frame.size.height
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonHome.png")
            cell.widthConstraint.constant = 40
        case 1:
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonPlay.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
            }
            cell.widthConstraint.constant = 75
        case 2:
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonSettings.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonRestart.png")
            }
            cell.widthConstraint.constant = 40
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
            if sender == "Pause" {
                showWarning(senderID: "pauseMenu")
            } else {
                MenuViewController().clearSavedGame()
                moveToMainMenu()
                // return to main menu
            }
            // Don't show warning if game over or complete
        }
        if indexPath.row == 1 {
            if self.sender == "Pause" {
                removeAnimate(nextAction: .unpause)
            }
        }
        if indexPath.row == 2 {
            if self.sender == "Pause" {
                hideAnimate()
                moveToSettings()
            } else {
                removeAnimate(nextAction: .restartGameNotificiation)
            }
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.1) {
            let cell = self.buttonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonHomeHighlighted.png")
            case 1:
                if self.sender == "Pause" {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted.png")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull.png")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                if self.sender == "Pause" {
                    cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonRestartHighlighted.png")
                }
            default:
                print("Error: Out of range")
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        
        UIView.animate(withDuration: 0.1) {
            let cell = self.buttonCollectionView.cellForItem(at: indexPath) as! MainMenuCollectionViewCell
            cell.view.transform = .identity
            
            
            switch indexPath.row {
            case 0:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                cell.iconImage.image = UIImage(named:"ButtonHome.png")
            case 1:
                if self.sender == "Pause" {
                    if self.hapticsSetting! {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = UIImage(named:"ButtonPlay.png")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonNull.png")
                }
            case 2:
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                if self.sender == "Pause" {
                    cell.iconImage.image = UIImage(named:"ButtonSettings.png")
                } else {
                    cell.iconImage.image = UIImage(named:"ButtonRestart.png")
                }
            default:
                print("Error: Out of range")
                break
            }
        }
    }

    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.33)
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
    
    func userSettings() {
        premiumSetting = defaults.bool(forKey: "premiumSetting")
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
    
    func updateLabels() {
        newItemsLabel.isHidden = true
        if sender == "Pause" {
            titleLabel.text = "P A U S E D"
        } else if sender == "Game Over" {
            titleLabel.text = "G A M E   O V E R"
        } else if sender == "Complete" {
            titleLabel.text = "C O M P L E T E"
            if newItemsBool && premiumSetting! == false {
                newItemsLabel.isHidden = false
            }
        }
    
        if endlessMode {
            levelNameLabelNormalConstraint.isActive = false
            levelTitleLowerConstraint.isActive = true
            
            packNameLabel.text = ""
            levelNumberLabel.text = String(LevelPackSetup().levelNameArray[levelNumber])
            levelNameLabel.text = ""
            
            scoreLabelTitle.text = "Height"
            scoreLabel.text = "\(height)m"
            highscoreLabelTitle.text = "Best"
            
            var heightBest = 0
            if totalStatsArray[0].endlessModeHeight.count > 0 {
                heightBest = totalStatsArray[0].endlessModeHeight.max()!
                highscoreLabel.text = "\(heightBest)m"
            }
            
            if sender == "Pause" {
                if height > heightBest {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best"
                }
                highscoreLabel.text = "\(heightBest)m"
            } else {
                if totalStatsArray[0].endlessModeHeight.count <= 1 {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best"
                    highscoreLabel.text = "0m"
                } else {
                    var heightsArray = totalStatsArray[0].endlessModeHeight
                    heightsArray.sort(by: >)
                    let previousBestHeight = heightsArray[1]
                    if height > previousBestHeight {
                        scoreLabelTitle.text = "New Best Height"
                        highscoreLabelTitle.text = "Previous Best"
                        highscoreLabel.text = "\(previousBestHeight)m"
                    }
                }
            }

        } else {
            if levelNumber == 100 {
                levelNameLabelNormalConstraint.isActive = false
                levelTitleLowerConstraint.isActive = true
                
                packNameLabel.text = ""
                levelNumberLabel.text = "Tutorial"
                levelNameLabel.text = ""
            } else {
                if numberOfLevels > 1 {
                    packNameLabel.text = "\(LevelPackSetup().levelPackNameArray[packNumber])"
                    levelNumberLabel.text = "Level \(levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1) of \(LevelPackSetup().numberOfLevels[packNumber])"
                    levelNameLabel.text = "\(LevelPackSetup().levelNameArray[levelNumber])"
                } else {
                    levelNameLabelNormalConstraint.isActive = false
                    levelTitleLowerConstraint.isActive = true
                    
                    packNameLabel.text = "Single Level Mode"
                    levelNumberLabel.text = "\(LevelPackSetup().levelNameArray[levelNumber])"
                    levelNameLabel.text = ""
                }
            }
            
            scoreLabelTitle.text = "Score"
            scoreLabel.text = "\(score)"
            highscoreLabelTitle.text = "Highscore"
            // Get current highscore from level or pack
            
            highscoreLabel.text = String(previousHighscore)
            if score > previousHighscore {
                scoreLabelTitle.text = "New Highscore"
                highscoreLabelTitle.text = "Previous Highscore"
            }
        }
        
        if sender == "Complete" && !endlessMode && numberOfLevels != 1 {
            levelNameLabelNormalConstraint.isActive = false
            levelTitleLowerConstraint.isActive = true
            
            packNameLabel.text = ""
            levelNumberLabel.text = "\(LevelPackSetup().levelPackNameArray[packNumber])"
            levelNameLabel.text = ""
        }
    }
    
    func removeAnimate(nextAction: Notification.Name) {
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
                NotificationCenter.default.post(name: nextAction, object: nil)
                // Send notification to unpause the game
            }
        }
    }
    
    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.containterView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.containterView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.containterView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.containterView.alpha = 1.0
        })
    }
    
    func addParallaxToView() {
        
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
            containterView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        containterView.addMotionEffect(group!)
    }
    
    func moveToSettings() {
        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsView.navigatedFrom = "PauseMenu"
        self.addChild(settingsView)
        settingsView.view.frame = self.view.frame
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
    }
    
    func showWarning(senderID: String) {
        let warningView = self.storyboard?.instantiateViewController(withIdentifier: "warningView") as! WarningViewController
        warningView.senderID = senderID
        self.addChild(warningView)
        warningView.view.frame = self.view.frame
        self.view.addSubview(warningView.view)
        warningView.didMove(toParent: self)
    }
    
    func moveToMainMenu() {
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
        NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        navigationController?.popToRootViewController(animated: true)
    }
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        
        packLevelHighScoresArray = [
            totalStatsArray[0].pack1LevelHighScores, totalStatsArray[0].pack2LevelHighScores, totalStatsArray[0].pack3LevelHighScores, totalStatsArray[0].pack4LevelHighScores, totalStatsArray[0].pack5LevelHighScores, totalStatsArray[0].pack6LevelHighScores, totalStatsArray[0].pack7LevelHighScores, totalStatsArray[0].pack8LevelHighScores, totalStatsArray[0].pack9LevelHighScores, totalStatsArray[0].pack10LevelHighScores, totalStatsArray[0].pack11LevelHighScores
        ]
    }
    
    @objc func returnPauseNotificationKeyReceived(_ notification: Notification) {
        revealAnimate()
        userSettings()
        updateLabels()
        collectionViewLayout()
        if parallaxSetting! {
            addParallaxToView()
        } else if group != nil {
            containterView.removeMotionEffect(group!)
        }
    }
    
    @objc func killBallRemoveVCKeyReceived(_ notification: Notification) {
        NotificationCenter.default.post(name: .killBallNotification, object: nil)
        removeAnimate(nextAction: .unpause)
    }
}

extension Notification.Name {
    public static let returnPauseNotification = Notification.Name(rawValue: "returnPauseNotification")
    public static let killBallRemoveVC = Notification.Name(rawValue: "killBallRemoveVC")
}
// Notification setup for sending information from the pause menu popup to unpause the game
