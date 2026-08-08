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

    let dailySummaryLabel = UILabel()
    // The day's rules at a glance while a daily is paused (play-test request, and §6's
    // "the pause menu shows a compact twist summary"): the day, then each twist by icon
    // and name - names only, because mid-run is when someone forgets what Flipped Angle
    // means, not when they want to read about it

    var isDailyChallenge: Bool { DailyChallengeSession.shared.isActive }

    /// A finished daily: no replay, no restart, one way out - so Home takes the middle.
    var dailyGameOver: Bool { isDailyChallenge && sender != "Pause" }

    /// A finished endless run outside the daily: the one screen with a stats button
    /// (§12.0's game-over stats), in the centre slot a game over otherwise leaves empty.
    var endlessGameOver: Bool {
        endlessMode && sender != "Pause" && isDailyChallenge == false
    }

    let runStatsLabel = UILabel()
    // Code-built like livesLabel, and for the same reason: the storyboard's labels are
    // wired and working, and one more by hand risks none of them

    func setUpRunStatsLabel() {
        runStatsLabel.translatesAutoresizingMaskIntoConstraints = false
        runStatsLabel.textAlignment = .center
        runStatsLabel.font = .systemFont(ofSize: 14)
        runStatsLabel.textColor = UIColor(white: 1, alpha: 0.7)
        runStatsLabel.numberOfLines = 0
        runStatsLabel.isHidden = true
        containterView.addSubview(runStatsLabel)
        NSLayoutConstraint.activate([
            runStatsLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            runStatsLabel.topAnchor.constraint(equalTo: highscoreLabel.bottomAnchor,
                                               constant: 16),
        ])
    }

    /// The finished run's numbers, in one line under the height (§12.0: balls hit,
    /// bricks destroyed, power-ups collected). The detail is behind the stats button.
    func updateRunStatsLabel() {
        guard endlessMode, sender != "Pause",
              let summary = InGameRecents.shared.runSummary else {
            runStatsLabel.isHidden = true
            return
        }
        runStatsLabel.isHidden = false
        let line = NSMutableAttributedString()
        let items: [(String, Int)] = [("rectangle.fill", summary.paddleHits),
                                      ("square.grid.3x2.fill", summary.bricksDestroyed),
                                      ("arrow.down.circle.fill", summary.powerUpsCollected)]
        for (position, item) in items.enumerated() {
            if position > 0 { line.append(NSAttributedString(string: "    ")) }
            let badge = NSTextAttachment()
            badge.image = UIImage(systemName: item.0)?
                .withTintColor(UIColor(white: 1, alpha: 0.45),
                               renderingMode: .alwaysOriginal)
            badge.bounds = CGRect(x: 0, y: -2, width: 15, height: 13)
            line.append(NSAttributedString(attachment: badge))
            line.append(NSAttributedString(
                string: " \(item.1)",
                attributes: [.font: UIFont.systemFont(ofSize: 14),
                             .foregroundColor: UIColor(white: 1, alpha: 0.7)]))
        }
        runStatsLabel.attributedText = line
        // Small subtle icons beside each number (play-test round 8): the paddle, the
        // field, the drop - placeholders in SF symbols until §8.5 draws its own
    }
    // Asked of the session, which outlives the scene until the menus return

    var dailyRank: Int?
    // Where the posted run stands on today's board, once Game Center has answered

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

        homeButton.isHidden = sender != "Pause"
        // Home is in the top-left corner *while paused*, where it is out of the way: it ends
        // the run, and it sat beside Play where it was the one press nobody wants to make by
        // accident. The row below is then Information, Play and Settings - two small buttons
        // either side of the large one.
        //
        // On the game-over screen there is no run left to end, so it goes back to the bottom
        // left where it balances Replay
        
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
        setUpRunStatsLabel()
        loadData()
        updateLabels()
        collectionViewLayout()
        buttonCollectionView.reloadData()
        showAnimate()

        if isDailyChallenge, sender != "Pause", DailyChallengeSession.shared.lastRunPosted {
            GameCenterHandler().loadDailyRank { [weak self] rank in
                guard let self, let rank else { return }
                self.dailyRank = rank
                self.updateDailySummary()
            }
            // The placing joins the summary when Game Center answers; a screen already
            // dismissed just ignores it
        }
    }
    
    func setUpLivesLabel() {
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        livesLabel.textAlignment = .center
        livesLabel.font = highscoreLabelTitle.font
        livesLabel.textColor = highscoreLabelTitle.textColor
        livesLabel.isHidden = true
        containterView.addSubview(livesLabel)

        dailySummaryLabel.translatesAutoresizingMaskIntoConstraints = false
        dailySummaryLabel.textAlignment = .center
        dailySummaryLabel.numberOfLines = 0
        dailySummaryLabel.isHidden = true
        containterView.addSubview(dailySummaryLabel)

        NSLayoutConstraint.activate([
            livesLabel.centerXAnchor.constraint(equalTo: highscoreLabel.centerXAnchor),
            livesLabel.topAnchor.constraint(equalTo: highscoreLabel.bottomAnchor, constant: 16),
            dailySummaryLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            dailySummaryLabel.topAnchor.constraint(equalTo: livesLabel.bottomAnchor,
                                                   constant: 18),
            dailySummaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo:
                                                        containterView.leadingAnchor,
                                                       constant: 30),
            dailySummaryLabel.trailingAnchor.constraint(lessThanOrEqualTo:
                                                        containterView.trailingAnchor,
                                                        constant: -30),
        ])
        // The daily summary hangs under the lives line - a hidden label still holds its
        // position, so the summary sits in the same place whether lives are shown or not
    }
    // Matches the "Previous Highscore" title's font and colour, so it reads as another
    // line of the same block rather than something bolted on

    func updateLivesLabel() {
        guard sender == "Pause" else {
            livesLabel.isHidden = true
            return
        }
        if isDailyChallenge {
            let balls = livesRemaining + 1
            livesLabel.isHidden = false
            livesLabel.text = balls == 1 ? "Last ball" : "\(balls) balls left"
            // The daily counts balls, not the rack: the one in play plus the reserves.
            // "1 life left" while holding the only ball read as one more to come - the
            // play test counted lives the twist did not grant
            return
        }
        guard !endlessMode else {
            livesLabel.isHidden = true
            return
        }
        livesLabel.isHidden = false
        livesLabel.text = livesRemaining == 1 ? "1 life left" : "\(livesRemaining) lives left"
    }
    // Only while paused mid-game. On game over the count is zero and saying so is just
    // rubbing it in, and endless mode has a single life and no counter anywhere else

    /// The compact daily block: the day, then each twist by icon and name.
    func updateDailySummary() {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active else {
            dailySummaryLabel.isHidden = true
            return
        }
        dailySummaryLabel.isHidden = false

        let summary = NSMutableAttributedString(
            string: "DAILY CHALLENGE — "
                + DailyChallengeSession.shared.displayName(forKey: challenge.dateKey),
            attributes: [.font: UIFont.boldSystemFont(ofSize: 13),
                         .foregroundColor: UIColor(white: 1, alpha: 0.55)])

        for twist in challenge.twists {
            summary.append(NSAttributedString(string: "\n"))
            summary.append(twist.titleLine(font: .boldSystemFont(ofSize: 14),
                                           colour: .white))
        }
        if challenge.twists.isEmpty {
            summary.append(NSAttributedString(string: "\n"))
            summary.append(DailyTwist.vanillaLine(font: .boldSystemFont(ofSize: 14),
                                                  colour: .white))
            // A no-twist day is Vanilla, badged like any other (play-test round 3)
        }

        if sender != "Pause" {
            let result: String
            if DailyChallengeSession.shared.lastRunPosted {
                result = dailyRank.map { "Posted — #\($0) on today's board" }
                    ?? "Submitted to today's board"
                // The placing arrives asynchronously when Game Center answers. Until
                // then "submitted" is the honest word (§12.5): the score is on its way,
                // and if it cannot land - signed out, offline, board not yet in App
                // Store Connect - the retry loop carries it and the briefing screen's
                // badge tells the truth of where it got to
            } else {
                result = "Practice run — practice never posts"
            }
            summary.append(NSAttributedString(
                string: "\n\n\(result)",
                attributes: [.font: UIFont.systemFont(ofSize: 12),
                             .foregroundColor: UIColor(white: 1, alpha: 0.55)]))
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4
        summary.addAttribute(.paragraphStyle, value: paragraph,
                             range: NSRange(location: 0, length: summary.length))
        dailySummaryLabel.attributedText = summary
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
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonInfo.png")
            } else if dailyGameOver {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonHome.png")
            }
            cell.widthConstraint.constant = 40
        case 1:
            cell.widthConstraint.constant = 75
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonPlay.png")
            } else if dailyGameOver {
                cell.iconImage.image = UIImage(named:"ButtonHome.png")
                // Home is the only thing a finished daily offers, so it takes the middle
                // and the full size - the way every other screen's one button does
                // (play-test round 3)
            } else if endlessGameOver {
                cell.iconImage.image = UIImage(named:"ButtonAchievements.png")
                cell.widthConstraint.constant = 40
                // The run's stats detail (§12.0), in the slot a game over leaves empty.
                // The achievements rosette stands in until §8.5 has a stats button of
                // its own
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
            }
        case 2:
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonSettings.png")
            } else if isDailyChallenge {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
                // No play-again on a daily's game over (play-test rule): the scoring
                // attempt is spent, and replaying from here would blur what first-attempt
                // tracking makes precise. Another go is a deliberate trip back through the
                // briefing screen, labelled practice
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
            } else if dailyGameOver == false {
                MenuViewController().clearSavedGame()
                moveToMainMenu()
                // No warning: the run is already over, so there is nothing to lose
            }
        }
        if indexPath.row == 1 {
            if self.sender == "Pause" {
                removeAnimate(nextAction: .unpause)
            } else if dailyGameOver {
                MenuViewController().clearSavedGame()
                moveToMainMenu()
                // The big centred Home, which is the whole of a finished daily's exit
            } else if endlessGameOver {
                openRunStats()
            }
        }
        if indexPath.row == 2 {
            if self.sender == "Pause" {
                hideAnimate()
                moveToSettings()
            } else if isDailyChallenge == false {
                removeAnimate(nextAction: .restartGameNotificiation)
            }
            // A daily's game over has no restart - the slot is a null button there
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
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = self.sender == "Pause"
                        ? UIImage(named:"ButtonInfoHighlighted.png")
                        : (self.dailyGameOver
                            ? UIImage(named:"ButtonNull.png")
                            : UIImage(named:"ButtonHomeHighlighted.png"))
                case 1:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonPlayHighlighted.png")
                    } else if self.dailyGameOver {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonHomeHighlighted.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 2:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
                    } else if self.isDailyChallenge {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    } else {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
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
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = self.sender == "Pause"
                        ? UIImage(named:"ButtonInfo.png")
                        : (self.dailyGameOver
                            ? UIImage(named:"ButtonNull.png")
                            : UIImage(named:"ButtonHome.png"))
                case 1:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonPlay.png")
                    } else if self.dailyGameOver {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonHome.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    }
                case 2:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonSettings.png")
                    } else if self.isDailyChallenge {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    } else {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
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
        updateRunStatsLabel()
        updateDailySummary()

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

            if isDailyChallenge {
                highscoreLabelTitle.text = ""
                highscoreLabel.text = ""
                // The endless modes' best heights are a different game's numbers (play-test
                // note): a daily is measured against today's board, not against a best set
                // under different rules. §9 keeps the daily out of those arrays; this keeps
                // their figures out of the daily
            } else if sender == "Pause" {
                let heightBest = runs.max() ?? 0
                if height > heightBest {
                    scoreLabelTitle.text = "New Best Height"
                    highscoreLabelTitle.text = "Previous Best"
                }
                highscoreLabel.text = "\(heightBest)m"
            } else {
                let heightBest = runs.max() ?? 0
                highscoreLabel.text = "\(heightBest)m"
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

                    packNameLabel.text = isDailyChallenge ? "Daily Challenge"
                                                          : "Single Level Mode"
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

            if isDailyChallenge {
                highscoreLabelTitle.text = ""
                highscoreLabel.text = ""
                // The level's campaign high score belongs to the campaign - a daily on
                // that level is a different game with today's board to answer to
            } else {
                highscoreLabelTitle.text = "Highscore"
                // Get current highscore from level or pack

                highscoreLabel.text = String(previousHighscore)
                if score > previousHighscore {
                    scoreLabelTitle.text = "New Highscore"
                    highscoreLabelTitle.text = "Previous Highscore"
                }
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

    /// The finished run's detail (§12.0), over the game-over screen the way the
    /// reference pages sit over the pause menu.
    func openRunStats() {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        hideAnimate()
        let statsView = RunStatsViewController()
        self.addChild(statsView)
        statsView.view.frame = self.view.frame
        self.view.addSubview(statsView.view)
        statsView.didMove(toParent: self)
        statsView.showAnimate()
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
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil,
                                        userInfo: ["packNumber": packNumber])
        // The pack rides along for the same reason GameViewController sends it: the
        // menus reopen the played pack's level list for a Classic run
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
