//
//  PauseMenuViewController.swift
//  Megaball
//
//  Created by James Harding on 17/10/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GameKit

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
    let signedOutLabel = UILabel()
    private var livesUnderHighscore: NSLayoutConstraint!
    private var livesUnderScore: NSLayoutConstraint!
    private var summaryUnderStats: NSLayoutConstraint!
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
    let moreStatsButton = UIButton(type: .system)
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

        var stats = AttributedString("More Stats…")
        stats.font = .boldSystemFont(ofSize: 14)
        var moreStats = UIButton.Configuration.plain()
        moreStats.attributedTitle = stats
        moreStats.image = UIImage(systemName: "star.fill",
                                  withConfiguration: UIImage.SymbolConfiguration(
                                      pointSize: 12, weight: .bold))
        moreStats.imagePadding = 6
        moreStats.baseForegroundColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        moreStatsButton.configuration = moreStats
        moreStatsButton.translatesAutoresizingMaskIntoConstraints = false
        moreStatsButton.isHidden = true
        moreStatsButton.addTarget(self, action: #selector(moreStatsTapped),
                                  for: .touchUpInside)
        containterView.addSubview(moreStatsButton)
        // The door to the run's detail, at the bottom of the stats list (play-test
        // round 11) - it replaces the rosette that sat unexplained in the button row

        NSLayoutConstraint.activate([
            runStatsLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            runStatsLabel.topAnchor.constraint(equalTo: highscoreLabel.bottomAnchor,
                                               constant: 34),
            moreStatsButton.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            moreStatsButton.topAnchor.constraint(equalTo: runStatsLabel.bottomAnchor,
                                                 constant: 8),
            // Room between the blocks (play-test rounds 15 and 16 both asked for it): the
            // score, the stats list and the daily summary each get air, rather than the
            // stats being squeezed against the height above them
        ])
    }

    /// The Giga-Ball logo at the top of the screen (play-test round 10) - the pause and
    /// game-over screens were the only full-screen views without the game's name on them.
    func setUpPauseLogo() {
        let logo = UIImageView(image: UIImage(named: "Logo"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.applyGigaBallGlow()
        // The subtle Giga-Ball green glow around it (play-test rounds 11 and 13)
        containterView.addSubview(logo)

        let modeIcon = UIImageView(image: GameMode.menuIcon(for: currentMode))
        modeIcon.contentMode = .scaleAspectFit
        modeIcon.translatesAutoresizingMaskIntoConstraints = false
        containterView.addSubview(modeIcon)
        // The mode's icon above its name, the same order the level intro splash uses
        // (play-test round 13): icon, then which mode, then what happened

        titleLabel.applyGigaBallGlow(radius: GigaBallGlow.headingRadius)
        // PAUSED / GAME OVER / COMPLETE glow like the wordmark does

        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: containterView.safeAreaLayoutGuide.topAnchor,
                                      constant: 46),
            logo.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            logo.heightAnchor.constraint(equalToConstant: 36),
            logo.leadingAnchor.constraint(greaterThanOrEqualTo: containterView.leadingAnchor,
                                          constant: 60),

            modeIcon.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            modeIcon.bottomAnchor.constraint(equalTo: packNameLabel.topAnchor,
                                             constant: -4),
            modeIcon.widthAnchor.constraint(equalToConstant: 42),
            modeIcon.heightAnchor.constraint(equalToConstant: 42),
            // Above the *pack* line, not the level line: in Classic and the daily there
            // is a label above the one naming the mode, and anchoring to the lower of
            // the two put the icon straight through it (play-test round 14's screenshots).
            // Endless leaves the pack line empty, so the icon simply sits a little higher
            // there rather than needing a rule of its own
        ])
    }

    /// Which mode this screen belongs to. The daily is a menu identity rather than a scene
    /// one, so it is asked of the session first and the remembered mode second.
    var currentMode: GameMode {
        isDailyChallenge ? .daily : GameMode.current(in: defaults)
    }

    /// The finished run's numbers under the height, one labelled row per stat
    /// (play-test round 11: "the icons alone are not enough"), with the door to the
    /// detail screen as a small labelled button at the bottom of the list.
    func updateRunStatsLabel() {
        guard sender != "Pause",
              let summary = InGameRecents.shared.runSummary else {
            runStatsLabel.isHidden = true
            moreStatsButton.isHidden = true
            summaryUnderStats.isActive = false
            return
        }
        runStatsLabel.isHidden = false
        moreStatsButton.isHidden = false
        summaryUnderStats.isActive = true
        let text = NSMutableAttributedString()
        var items: [(String, String, Int)] = [
            ("rectangle.fill", "Paddle hits", summary.paddleHits),
            ("square.grid.3x2.fill", "Bricks destroyed", summary.bricksDestroyed),
            ("arrow.down.circle.fill", "Power-ups collected", summary.powerUpsCollected)]
        if summary.isEndless == false {
            items.insert(("flag.fill", "Levels cleared", summary.levelsCleared), at: 0)
        }
        // Every game over carries its run's numbers now, not only the endless ones
        // (play-test round 13) - and a classic run leads with how far it got, which is the
        // thing an endless run says with its height
        for (position, item) in items.enumerated() {
            if position > 0 { text.append(NSAttributedString(string: "\n")) }
            let badge = NSTextAttachment()
            badge.image = UIImage(systemName: item.0)?
                .withTintColor(UIColor(white: 1, alpha: 0.45),
                               renderingMode: .alwaysOriginal)
            badge.bounds = CGRect(x: 0, y: -2, width: 15, height: 13)
            text.append(NSAttributedString(attachment: badge))
            text.append(NSAttributedString(
                string: "  \(item.1)  ",
                attributes: [.font: UIFont.systemFont(ofSize: 14),
                             .foregroundColor: UIColor(white: 1, alpha: 0.55)]))
            text.append(NSAttributedString(
                string: "\(item.2)",
                attributes: [.font: UIFont.boldSystemFont(ofSize: 14),
                             .foregroundColor: UIColor(white: 1, alpha: 0.85)]))
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.paragraphSpacing = 3
        text.addAttribute(.paragraphStyle, value: paragraph,
                          range: NSRange(location: 0, length: text.length))
        runStatsLabel.attributedText = text
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
        setUpRunStatsLabel()
        setUpLivesLabel()
        // In this order: the daily summary's constraints reference the More Stats button
        setUpPauseLogo()
        loadData()
        updateLabels()
        collectionViewLayout()
        buttonCollectionView.reloadData()
        showAnimate()
        announceClosedDayIfNeeded()

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

        signedOutLabel.translatesAutoresizingMaskIntoConstraints = false
        signedOutLabel.textAlignment = .center
        signedOutLabel.numberOfLines = 0
        signedOutLabel.font = .systemFont(ofSize: 12)
        signedOutLabel.textColor = UIColor(white: 1, alpha: 0.38)
        signedOutLabel.text = GameCenterHandler.notSignedInNote
        signedOutLabel.isHidden = true
        containterView.addSubview(signedOutLabel)

        summaryUnderStats = dailySummaryLabel.topAnchor.constraint(
            greaterThanOrEqualTo: moreStatsButton.bottomAnchor, constant: 20)

        livesUnderHighscore = livesLabel.topAnchor.constraint(
            equalTo: highscoreLabel.bottomAnchor, constant: 6)
        livesUnderScore = livesLabel.topAnchor.constraint(
            equalTo: scoreLabel.bottomAnchor, constant: 6)
        // Which of the two applies is decided in updateLivesLabel: the daily prints no
        // high score, and a label with no text still holds its place, so hanging the
        // lives line off it left "Last ball" stranded a third of a screen below the
        // score it belongs to (play-test round 16's screenshot)

        NSLayoutConstraint.activate([
            signedOutLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            signedOutLabel.topAnchor.constraint(equalTo: dailySummaryLabel.bottomAnchor,
                                                constant: 14),
            signedOutLabel.leadingAnchor.constraint(greaterThanOrEqualTo:
                                                        containterView.leadingAnchor,
                                                    constant: 30),
            signedOutLabel.trailingAnchor.constraint(lessThanOrEqualTo:
                                                        containterView.trailingAnchor,
                                                     constant: -30),
            // Last line of the score block, under everything else it belongs with. The
            // summary above it is hidden outside the daily, and a hidden label still holds
            // its place, so this lands under the stats either way

            livesLabel.centerXAnchor.constraint(equalTo: highscoreLabel.centerXAnchor),
            // Tight to the score it belongs with (play-test round 16) - the air goes
            // below it, between the run's numbers and the day's rules
            dailySummaryLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            dailySummaryLabel.topAnchor.constraint(
                greaterThanOrEqualTo: livesLabel.bottomAnchor, constant: 34),
            {
                let preferred = dailySummaryLabel.topAnchor.constraint(
                    equalTo: livesLabel.bottomAnchor, constant: 34)
                preferred.priority = .defaultHigh
                return preferred
            }(),
            // A gap under the lives line, then the day's rules (play-test round 16). Where
            // there are run stats they sit in between and push this down - but only where
            // there are: the constraint that makes room for them is switched on with them,
            // because hidden labels still hold their place and this screen was leaving a
            // third of itself blank for a stats list the daily never shows
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
        // The daily leaves the high score blank, so the lives line follows the score
        // itself there and the "Best" block everywhere else
        livesUnderHighscore.isActive = !isDailyChallenge
        livesUnderScore.isActive = isDailyChallenge

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

    /// Tells a signed-out player, once their run is over, that the figure above them went
    /// no further than this device (play-test round 16).
    ///
    /// Only at the end of a run, and only where there was a board to miss. Mid-pause it
    /// would be nagging about something that has not happened yet, and a player who has
    /// never signed in and never intends to should not read it on every screen - so it
    /// appears exactly where the score would otherwise have been posted.
    func updateSignedOutNote() {
        signedOutLabel.isHidden = sender == "Pause" || GameCenterHandler.isAuthenticated
    }

    /// Explains a twist, tapped on the pause screen.
    ///
    /// Says, once, that the day this run belongs to has closed - and offers the way out.
    ///
    /// The message used to be a line on the resume splash, which is exactly where a player
    /// is not reading (play-test round 18). Here it stops the game, on top of the pause
    /// screen, with the two answers there are: carry on for the practice, or leave.
    func announceClosedDayIfNeeded() {
        guard DailyChallengeSession.shared.closedDayNeedsAnnouncing else { return }
        DailyChallengeSession.shared.closedDayNeedsAnnouncing = false
        // Cleared first: this screen can be built again on the way back from settings, and
        // the answer has not changed since it was given

        GigaBallAlert.show(
            on: self,
            title: "Challenge Closed",
            message: "This challenge closed while you were away.\n\n"
                + "You can carry on playing it, but the score will not be posted.",
            dismissTitle: "Main Menu",
            dismiss: { [weak self] in
                MenuViewController().clearSavedGame()
                self?.moveToMainMenu()
                // The same pair of steps quitting from the pause menu takes: the save goes
                // first, or the run this player just abandoned is offered back to them
            },
            confirmTitle: "Continue",
            confirm: { [weak self] in
                self?.removeAnimate(nextAction: .unpause)
            })
    }

    /// Here rather than on the briefing card (play-test round 16): the briefing prints
    /// each twist's blurb underneath it already, and this screen shows only an icon and a
    /// name - which is exactly where "what does Fog of War do again" gets asked.
    @objc func dailyTwistsTapped() {
        guard let challenge = DailyChallengeSession.shared.active else { return }
        if hapticsSetting { interfaceHaptic.impactOccurred() }

        let centred = NSMutableParagraphStyle()
        centred.alignment = .center

        // A twistless day is a Vanilla day, and it explains itself like any other
        // (play-test round 18): "Vanilla" says nothing to somebody who has not read the
        // rest of the game, and it was the one badge on this screen that did not answer
        // a tap. Named and blurbed from the same constants the briefing prints
        let named: [(icon: UIImage, name: String, blurb: String)] =
            challenge.twists.isEmpty
            ? [(PowerUpIcon.twistVanilla, DailyTwist.vanillaName, DailyTwist.vanillaBlurb)]
            : challenge.twists.map { ($0.icon, $0.displayName, $0.blurb) }

        let body = NSMutableAttributedString()
        for (position, twist) in named.enumerated() {
            if position > 0 { body.append(NSAttributedString(string: "\n\n")) }
            body.append(DailyTwist.badgedLine(icon: twist.icon, name: twist.name,
                                              font: .boldSystemFont(ofSize: 16),
                                              colour: .white))
            body.append(NSAttributedString(
                string: "\n\(twist.blurb)",
                attributes: [.font: UIFont.systemFont(ofSize: 15),
                             .foregroundColor: UIColor(white: 1, alpha: 0.75)]))
        }
        body.addAttribute(.paragraphStyle, value: centred,
                          range: NSRange(location: 0, length: body.length))
        // The badge in front of the name, as every other screen that names a twist does
        // (play-test round 17) - the briefing, the pause summary and the level intro all
        // read icon-then-name, and the explainer was the one place that did not

        GigaBallAlert.show(on: self, title: "Today's Twists", attributed: body)
    }

    /// The compact daily block: the day, then each twist by icon and name.
    func updateDailySummary() {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active else {
            dailySummaryLabel.isHidden = true
            return
        }
        dailySummaryLabel.isHidden = false
        if dailySummaryLabel.gestureRecognizers?.isEmpty ?? true {
            dailySummaryLabel.isUserInteractionEnabled = true
            dailySummaryLabel.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(dailyTwistsTapped)))
        }

        let summary = NSMutableAttributedString(
            string: "DAILY CHALLENGE, "
                + DailyChallengeSession.shared.displayName(forKey: challenge.dateKey),
            attributes: [.font: UIFont.boldSystemFont(ofSize: 13),
                         .foregroundColor: UIColor(white: 1, alpha: 0.55)])

        if sender == "Pause" {
            let scoring = DailyChallengeSession.shared.isScoringAttempt
            summary.append(NSAttributedString(
                string: "\n" + (scoring ? "COMPETITION RUN" : "FREE PLAY"),
                attributes: [.font: UIFont.boldSystemFont(ofSize: 13),
                             .foregroundColor: scoring
                                ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
                                : UIColor(white: 1, alpha: 0.55)]))
            // Mid-run, what is riding on this one (play-test round 13). On the game-over
            // screen the posted-or-not line below already says it, and better
        }

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
                result = dailyRank.map { "Posted, #\($0) on today's board" }
                    ?? "Submitted to today's board"
                // The placing arrives asynchronously when Game Center answers. Until
                // then "submitted" is the honest word (§12.5): the score is on its way,
                // and if it cannot land - signed out, offline, board not yet in App
                // Store Connect - the retry loop carries it and the briefing screen's
                // badge tells the truth of where it got to
            } else {
                result = "Free play, which never posts"
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
        
        // A game over reads the same in every mode (play-test round 10): the replay on
        // the left, the big Home in the centre - the way the mode menus centre their big
        // play - and the run's detail on the right: today's board for a daily, the run
        // stats for an endless run, nothing yet for classic. A daily has no replay slot
        // at all: the scoring attempt is spent, and another go is a deliberate trip back
        // through the briefing screen, labelled practice
        switch indexPath.row {
        case 0:
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonInfo.png")
            } else if isDailyChallenge {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonRestart.png")
            }
            cell.widthConstraint.constant = 40
        case 1:
            cell.widthConstraint.constant = 75
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonPlay.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonHome.png")
            }
        case 2:
            if self.sender == "Pause" {
                cell.iconImage.image = UIImage(named:"ButtonSettings.png")
            } else if dailyGameOver {
                cell.iconImage.image = UIImage(named:"ButtonLeaderboard.png")
            } else {
                cell.iconImage.image = UIImage(named:"ButtonNull.png")
                // The endless run's detail moved to the More Stats… button under the
                // stats list (play-test round 11) - the rosette here said nothing
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
            } else if isDailyChallenge == false {
                removeAnimate(nextAction: .restartGameNotificiation)
            }
            // A daily's game over has no restart - the slot is a null button there
        }
        if indexPath.row == 1 {
            if self.sender == "Pause" {
                removeAnimate(nextAction: .unpause)
            } else {
                MenuViewController().clearSavedGame()
                moveToMainMenu()
                // No warning: the run is already over, so there is nothing to lose
            }
        }
        if indexPath.row == 2 {
            if self.sender == "Pause" {
                hideAnimate()
                moveToSettings()
            } else if dailyGameOver {
                openDailyLeaderboard()
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
                    } else if self.isDailyChallenge {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    } else {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonRestartHighlighted.png")
                    }
                case 1:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.iconImage.image = self.sender == "Pause"
                        ? UIImage(named:"ButtonPlayHighlighted.png")
                        : UIImage(named:"ButtonHomeHighlighted.png")
                case 2:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonSettingsHighlighted.png")
                    } else if self.dailyGameOver {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboardHighlighted.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
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
                        cell.iconImage.image = UIImage(named:"ButtonInfo.png")
                    } else if self.isDailyChallenge {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonRestart.png")
                    }
                case 1:
                    cell.iconImage.image = self.sender == "Pause"
                        ? UIImage(named:"ButtonPlay.png")
                        : UIImage(named:"ButtonHome.png")
                case 2:
                    if self.sender == "Pause" {
                        cell.iconImage.image = UIImage(named:"ButtonSettings.png")
                    } else if self.dailyGameOver {
                        cell.iconImage.image = UIImage(named:"ButtonLeaderboard.png")
                    } else {
                        cell.iconImage.image = UIImage(named:"ButtonNull.png")
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
        updateSignedOutNote()

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
            if sender != "Pause" {
                startTally(to: score, suffix: "")
            }
            // Every ending, not only Single Level Mode (play-test round 16: "the game over
            // screen should tally like the other screens do"). A pack's total was held back
            // because a level inside a run is one of many and its score carries into the
            // next - but this screen is only reached when there is no next: the run is over,
            // or the pack is complete. Mid-run counting stays where it belongs, on the
            // level summary between levels

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
    @objc private func moreStatsTapped() {
        openRunStats()
    }

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

    /// Today's board, from the finished daily (play-test round 9) - the same sheet the
    /// briefing screen's leaderboard button shows, so the two doors open the same room.
    func openDailyLeaderboard() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        let boards = GKGameCenterViewController(leaderboardID: DailyChallengeBoards.daily,
                                                playerScope: .global, timeScope: .allTime)
        boards.gameCenterDelegate = self
        view.window?.rootViewController?.present(boards, animated: true)
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

extension PauseMenuViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        if hapticsSetting { interfaceHaptic.impactOccurred() }
    }
}

extension Notification.Name {
    public static let returnPauseNotification = Notification.Name(rawValue: "returnPauseNotification")
    public static let killBallRemoveVC = Notification.Name(rawValue: "killBallRemoveVC")
}
// Notification setup for sending information from the pause menu popup to unpause the game
