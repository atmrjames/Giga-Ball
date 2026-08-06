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
    var livesRemaining: Int = 0
    // Properties to store passed over data
    
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
    
    var endlessMode: Bool = false
    
    var packLevelHighScoresArray: [[Int]]?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var containterView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet var scoreLabelTitle: UILabel!
    @IBOutlet weak var highscoreLabel: UILabel!
    @IBOutlet weak var highscoreLabelTitle: UILabel!
    @IBOutlet var buttonCollectionView: UICollectionView!
    @IBOutlet var homeButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var packNameLabel: UILabel!
    @IBOutlet weak var levelNumberLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var newItemsLabel: UILabel!
    
    let livesLabel = UILabel()
    // Added in code rather than the storyboard: the pause screen's labels are all wired
    // through outlets and constraints there, and adding one more by hand risks the
    // layout of a screen that is otherwise working

    @IBOutlet var levelTitleLowerConstraint: NSLayoutConstraint!
    @IBOutlet var levelNameLabelNormalConstraint: NSLayoutConstraint!
    
    private var heightTallyLink: CADisplayLink?
    private var heightTallyStartedAt: CFTimeInterval = 0
    private var heightTallyTarget = 0
    static let heightTallyDuration: CFTimeInterval = 0.7
    static let heightTallyTicks = 10
    private var heightTallyLastTick = -1
    private var hasRunHeightTally = false
    /// What the figure being counted up is measured in - metres for a run, nothing for a score.
    private var heightTallySuffix = "m"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnPauseNotificationKeyReceived), name: .returnPauseNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned to the pause menu from the settings menu
        NotificationCenter.default.addObserver(self, selector: #selector(self.killBallRemoveVCKeyReceived), name: .killBallRemoveVC, object: nil)
        // Sets up an observer to watch for notifications to check if the user has killed the ball from the settings menu to then remove the pause menu
        
        let skipTally = UITapGestureRecognizer(target: self,
                                              action: #selector(tapToSkipHeightTally))
        skipTally.cancelsTouchesInView = false
        view.addGestureRecognizer(skipTally)
        // Added here rather than in the storyboard, and deliberately not cancelling touches:
        // every button on this screen must keep working, so this only listens

        buttonCollectionView.delegate = self
        buttonCollectionView.dataSource = self
        buttonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        levelTitleLowerConstraint.isActive = false
        levelNameLabelNormalConstraint.isActive = true
        // Default constraints setting

        // Home is in the top-left corner rather than in the row of buttons, where it sat
        // beside Play and was the one press nobody wants to make by accident - it ends the
        // run. The row below is Information, Play and Settings: two small buttons either side
        // of the large one, which is what makes it read as a row rather than a list
        
        if levelNumber == 0 {
            endlessMode = true
        } else {
            endlessMode = false
        }
        
        userSettings()
        setBlur()
        if parallaxSetting {
            addParallaxToView()
        }
        setUpLivesLabel()
        loadData()
        updateLabels()
        collectionViewLayout()
        buttonCollectionView.reloadData()
        showAnimate()
    }
    
    func setUpLivesLabel() {
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        livesLabel.textAlignment = .center
        livesLabel.font = highscoreLabelTitle.font
        livesLabel.textColor = highscoreLabelTitle.textColor
        livesLabel.isHidden = true
        containterView.addSubview(livesLabel)

        NSLayoutConstraint.activate([
            livesLabel.centerXAnchor.constraint(equalTo: highscoreLabel.centerXAnchor),
            livesLabel.topAnchor.constraint(equalTo: highscoreLabel.bottomAnchor, constant: 16)
        ])
    }
    // Matches the "Previous Highscore" title's font and colour, so it reads as another
    // line of the same block rather than something bolted on

    func updateLivesLabel() {
        guard sender == "Pause", !endlessMode else {
            livesLabel.isHidden = true
            return
        }
        livesLabel.isHidden = false
        livesLabel.text = livesRemaining == 1 ? "1 life left" : "\(livesRemaining) lives left"
    }
    // Only while paused mid-game. On game over the count is zero and saying so is just
    // rubbing it in, and endless mode has a single life and no counter anywhere else

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
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonInfo.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
            }
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
            if sender == "Pause" {
                openInformation()
            }
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
        if let cell = self.buttonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
                switch indexPath.row {
                case 0:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonInfoHighlighted.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 1:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 2:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    if self.sender == "Pause" {
                        cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonRestartHighlighted.png")
                    }
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        
        if let cell = self.buttonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
            
            
                switch indexPath.row {
                case 0:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonInfo.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 1:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonPlay.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 2:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    if self.sender == "Pause" {
                        cell.iconImage.image = UIImage(named:"ButtonSettings.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonRestart.png")
                    }
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
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
        updateLivesLabel()

        newItemsLabel.isHidden = true
        if sender == "Pause" {
            titleLabel.text = "P A U S E D"
        } else if sender == "Game Over" {
            titleLabel.text = "G A M E   O V E R"
        } else if sender == "Complete" {
            titleLabel.text = "C O M P L E T E"
            if newItemsBool {
                newItemsLabel.isHidden = false
            }
            // Previously also required premiumSetting to be false, which it never was,
            // so this never showed. Now that pack completion genuinely unlocks a theme,
            // an icon and two power-ups again, announcing it is the intended behaviour
        }
    
        if endlessMode {
            levelNameLabelNormalConstraint.isActive = false
            levelTitleLowerConstraint.isActive = true
            
            let mode = GameMode.current(in: defaults)
            let runs = mode == .endlessII
                ? totalStatsArray[0].endlessIIHeights
                : totalStatsArray[0].endlessModeHeight
            // Each endless mode's own runs. Reading the original mode's array here showed
            // an Endless 2.0 player a best height they set in a different game

            packNameLabel.text = ""
            levelNumberLabel.text = mode.isEndless
                ? mode.name
                : String(LevelPackSetup().levelNameArray[levelNumber])
            levelNameLabel.text = ""
            
            scoreLabelTitle.text = "Height"
            scoreLabel.text = "\(height)m"
            if sender != "Pause" { startTally(to: height, suffix: "m") }
            // Only at the end of a run. Pausing mid-run to watch your own height counted back
            // to you would be telling you something you already know
            highscoreLabelTitle.text = "Best"
            
            var heightBest = 0
            if runs.count > 0 {
                heightBest = runs.max()!
                highscoreLabel.text = "\(heightBest)m"
            }
            
            if sender == "Pause" {
                if height > heightBest {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best"
                }
                highscoreLabel.text = "\(heightBest)m"
            } else {
                if runs.count <= 1 {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best"
                    highscoreLabel.text = "0m"
                } else {
                    var heightsArray = runs
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
            if sender != "Pause" && numberOfLevels <= 1 {
                startTally(to: score, suffix: "")
            }
            // Single Level Mode only. A level inside a pack is one of many and its score is
            // carried into the next one, so counting it up would be counting up a running
            // total that has not finished running - where a single level is the whole result,
            // the same as a run's height is
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
    
    /// Opens the reference pages over the paused game.
    ///
    /// The power-ups page and the brick types page answer questions that only come up while
    /// playing - what was that brick, what does this power-up do - and until now they were
    /// three screens away behind quitting the run. Reaching them from the pause menu is the
    /// difference between a reference a player uses and one they know exists.
    ///
    /// Every mode, because the question is the same in all of them.
    @IBAction func homeButton(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if self.sender == "Pause" {
            showWarning(senderID: "pauseMenu")
        } else {
            MenuViewController().clearSavedGame()
            moveToMainMenu()
        }
        // Don't show warning if game over or complete
    }

    func openInformation() {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        hideAnimate()

        let itemsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsView") as! ItemsViewController
        itemsView.navigatedFrom = "PauseMenu"
        self.addChild(itemsView)
        itemsView.view.frame = self.view.frame
        self.view.addSubview(itemsView.view)
        itemsView.didMove(toParent: self)
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
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
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
        if parallaxSetting {
            addParallaxToView()
        } else if group != nil {
            containterView.removeMotionEffect(group!)
        }
    }
    
    @objc func killBallRemoveVCKeyReceived(_ notification: Notification) {
        NotificationCenter.default.post(name: .killBallNotification, object: nil)
        removeAnimate(nextAction: .unpause)
    }
    // MARK: - Height tally

    /// Runs the final height up from zero, the way the level summary runs a score up.
    ///
    /// The number is the whole result of an endless run, and arriving at it is worth more
    /// than being handed it. Short, because this sits between one run and the next.
    private func startTally(to target: Int, suffix: String) {
        guard target > 0 else { return }
        guard hasRunHeightTally == false else { return }
        hasRunHeightTally = true
        heightTallySuffix = suffix
        // Once per screen. `updateLabels` runs again every time this menu is returned to -
        // from settings, from the information pages - and each of those was starting the
        // tally over: ten haptic ticks, mid-run, with no number counting anywhere. Whether
        // the count is wanted depends on how the screen was opened, which is decided once,
        // so running it is a thing that happens once too
        heightTallyTarget = target
        heightTallyStartedAt = CACurrentMediaTime()
        heightTallyLastTick = -1
        scoreLabel.text = "0" + heightTallySuffix

        let link = CADisplayLink(target: self, selector: #selector(stepHeightTally))
        link.add(to: .main, forMode: .common)
        heightTallyLink = link
    }

    @objc private func stepHeightTally() {
        let elapsed = CACurrentMediaTime() - heightTallyStartedAt
        guard elapsed < PauseMenuViewController.heightTallyDuration else {
            finishHeightTally()
            return
        }
        // Eased, so it decelerates into the figure rather than stopping dead
        let progress = elapsed/PauseMenuViewController.heightTallyDuration
        let eased = 1 - pow(1 - progress, 3)
        scoreLabel.text = "\(Int((Double(heightTallyTarget)*eased).rounded()))" + heightTallySuffix

        // The same ticking the level summary gives a score, for the same reason: a number
        // climbing in silence is a number, and a number you can feel climbing is a result
        let tick = Int(progress*Double(PauseMenuViewController.heightTallyTicks))
        if tick != heightTallyLastTick {
            heightTallyLastTick = tick
            if hapticsSetting { interfaceHaptic.impactOccurred(intensity: 0.5) }
        }
    }

    @objc private func tapToSkipHeightTally() {
        finishHeightTally()
    }

    private func finishHeightTally() {
        guard heightTallyLink != nil else { return }
        heightTallyLink?.invalidate()
        heightTallyLink = nil
        scoreLabel.text = "\(heightTallyTarget)" + heightTallySuffix
    }
}

extension Notification.Name {
    public static let returnPauseNotification = Notification.Name(rawValue: "returnPauseNotification")
    public static let killBallRemoveVC = Notification.Name(rawValue: "killBallRemoveVC")
}
// Notification setup for sending information from the pause menu popup to unpause the game
