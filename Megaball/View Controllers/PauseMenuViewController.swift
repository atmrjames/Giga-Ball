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
    // Properties to store passed over data
    
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
    var blurView: UIVisualEffectView?
    
    var endlessMode: Bool = false
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var containterView: UIView!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var scoreLabelTitle: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    @IBOutlet var buttonCollectionView: UICollectionView!
    @IBOutlet var titleLabel: UILabel!
    
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
        buttonCollectionView.reloadData()
        showAnimate()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 75
        cell.frame.size.width = cell.frame.size.height
        
        switch indexPath.row {
        case 0:
            cell.iconImage.image = UIImage(named:"ButtonClose.png")
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
            if self.hapticsSetting! {
                self.interfaceHaptic.impactOccurred()
            }
            showWarning(senderID: "pauseMenu")
        }
        if indexPath.row == 1 {
            if self.sender == "Pause" {
                if self.hapticsSetting! {
                    self.interfaceHaptic.impactOccurred()
                }
                removeAnimate(nextAction: .unpause)
            }
        }
        if indexPath.row == 2 {
            if self.hapticsSetting! {
                self.interfaceHaptic.impactOccurred()
            }
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
                cell.iconImage.image = UIImage(named:"ButtonCloseHighlighted.png")
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
                cell.iconImage.image = UIImage(named:"ButtonClose.png")
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
    
    func updateLabels() {
        if sender == "Pause" {
            titleLabel.text = "P A U S E D"
        } else if sender == "Game Over" {
            titleLabel.text = "G A M E   O V E R"
        } else if sender == "Complete" {
            titleLabel.text = "C O M P L E T E"
        }
    
        if endlessMode {
            levelNumberLabel.text = String(LevelPackSetup().levelNameArray[levelNumber])
            
            scoreLabelTitle.text = "Height"
            scoreLabel.text = "\(height) m"
            highscoreLabelTitle.text = "Best"
            
            var heightBest = 0
            if totalStatsArray[0].endlessModeHeight.count > 0 {
                heightBest = totalStatsArray[0].endlessModeHeight.max()!
                highscoreLabel.text = "\(heightBest) m"
            }
            
            if sender == "Pause" {
                if height > heightBest {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best Height"
                }
                highscoreLabel.text = "\(heightBest) m"
            } else {
                if totalStatsArray[0].endlessModeHeight.count <= 1 {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best Height"
                    highscoreLabel.text = "0 m"
                } else {
                    var heightsArray = totalStatsArray[0].endlessModeHeight
                    heightsArray.sort(by: >)
                    let previousBestHeight = heightsArray[1]
                    if height > previousBestHeight {
                        scoreLabelTitle.text = "New Best Height"
                        highscoreLabelTitle.text = "Previous Best Height"
                        highscoreLabel.text = "\(previousBestHeight) m"
                    }
                }
            }

        } else {
            if levelNumber == 100 {
                levelNumberLabel.text = "Tutorial"
            } else {
                if numberOfLevels > 1 {
                    levelNumberLabel.text = "\(LevelPackSetup().packTitles[packNumber]) - Level \(levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1) of \(LevelPackSetup().numberOfLevels[packNumber]) \n \(LevelPackSetup().levelNameArray[levelNumber])"
                } else {
                    levelNumberLabel.text = "\(LevelPackSetup().packTitles[packNumber]) - Level \(levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1) \n \(LevelPackSetup().levelNameArray[levelNumber])"
                }
            }
            
            scoreLabelTitle.text = "Score"
            scoreLabel.text = "\(score)"
            highscoreLabelTitle.text = "Highscore"
            
            var currentHighscore = score
            if numberOfLevels == 1 {
                if levelStatsArray[levelNumber].scores.count > 0 {
                    currentHighscore = levelStatsArray[levelNumber].scores.max()!
                }
            } else {
                if packStatsArray[packNumber].scores.count > 0 {
                    currentHighscore = packStatsArray[packNumber].scores.max()!
                }
            }
            // Get current highscore from level or pack
            
            highscoreLabel.text = String(currentHighscore)
            
            if sender == "Pause" {
                if score > currentHighscore {
                    scoreLabelTitle.text = "New Highscore"
                    highscoreLabelTitle.text = "Previous Highscore"
                }
            } else {
                
                if score == currentHighscore {
                // If the current score is the top score
                    scoreLabelTitle.text = "New Highscore"
                    highscoreLabelTitle.text = "Previous Highscore"
                    var previousHighscore = 0
                    if numberOfLevels == 1 && levelStatsArray[levelNumber].scores.count > 1 {
                        var scoresArray = levelStatsArray[levelNumber].scores
                        scoresArray.sort(by: >)
                        previousHighscore = scoresArray[1]
                    } else if packStatsArray[packNumber].scores.count > 1 {
                        var scoresArray = packStatsArray[packNumber].scores
                        scoresArray.sort(by: >)
                        previousHighscore = scoresArray[1]
                    }
                    highscoreLabel.text = String(previousHighscore)
                }
            }
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
                print("Error decoding pack stats array, \(error)")
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
    
    @objc func returnPauseNotificationKeyReceived(_ notification: Notification) {
        revealAnimate()
        userSettings()
        updateLabels()
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

//    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
//        if hapticsSetting! {
//            interfaceHaptic.impactOccurred()
//        }
//        removeAnimate(nextAction: .unpause)
//    }
}

extension Notification.Name {
    public static let returnPauseNotification = Notification.Name(rawValue: "returnPauseNotification")
    public static let killBallRemoveVC = Notification.Name(rawValue: "killBallRemoveVC")
}
// Notification setup for sending information from the pause menu popup to unpause the game
