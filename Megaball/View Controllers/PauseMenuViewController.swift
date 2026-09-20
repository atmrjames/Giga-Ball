//
//  PauseMenuViewController.swift
//  Megaball
//
//  Created by James Harding on 17/10/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GameKit

class PauseMenuViewController: UIViewController, UICollectionViewDelegate,
                                UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, MenuNavigationPresenter {
    
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
    let dailyTotalTitle = UILabel()
    let dailyTotalLabel = UILabel()
    /// The daily breakdown's first line: Level Score and Time Bonus, side by side.
    ///
    /// James, round 241: "the level score and time bonus can be on the same line with total
    /// score underneath". They used to borrow the storyboard's score and high-score rows - two
    /// rows already sitting where they were needed - and three stacked rows plus a stats
    /// summary is what was pushing the bottom of this screen off the end of itself.
    ///
    /// Their own labels rather than the borrowed ones, because the borrowed pair is centred by
    /// the storyboard and a column is not: moving them would mean fighting constraints this
    /// file does not own. The storyboard rows are hidden instead, so the block keeps its slot
    /// and everything hanging below it still has an anchor.
    let dailyLevelTitle = UILabel()
    let dailyLevelLabel = UILabel()
    let dailyBonusTitle = UILabel()
    let dailyBonusLabel = UILabel()
    /// Where the total hangs from: under the borrowed rows, or under the two columns.
    var dailyTotalUnderHighscore: NSLayoutConstraint!
    var dailyTotalUnderColumns: NSLayoutConstraint!

    /// The two halves of a completed level's score, for the daily's breakdown (round 210).
    var levelScore: Int = 0
    var levelTimerBonus: Int = 0

    /// Whether this screen should count out the breakdown rather than one figure.
    ///
    /// **A finished daily on a single level, and nothing else.** James: "single levels on
    /// daily challenge need a time bonus on the complete screen at the end of the player
    /// finished the level. It should be broken down like the end of a pack in classic mode."
    /// A daily that ended in a game over has no time bonus to show - the level was not
    /// finished - and an endless daily has a height rather than a level score.
    var showsDailyBreakdown: Bool {
        isDailyChallenge && sender == "Complete" && levelTimerBonus > 0
    }

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
    private var livesCollapsed: NSLayoutConstraint!
    private var livesUnderHighscore: NSLayoutConstraint!
    private var livesUnderScore: NSLayoutConstraint!
    private var livesUnderDailyTotal: NSLayoutConstraint!
    private var statsUnderTheResult: NSLayoutConstraint!
    private var statsWellUnderTheResult: NSLayoutConstraint!
    private weak var activePowerUpHUD: PausedPowerUpHUD?
    // Added in code rather than the storyboard: the pause screen's labels are all wired
    // through outlets and constraints there, and adding one more by hand risks the
    // layout of a screen that is otherwise working

    let dailySummaryLabel = UILabel()
    // The day's rules at a glance while a daily is paused (play-test request, and §6's
    // "the pause menu shows a compact twist summary"): the day, then each twist by icon
    // and name - names only, because mid-run is when someone forgets what Flipped Angle
    // means, not when they want to read about it

    let resultLabel = UILabel()

    /// What the line under it is: the player's standing on a Game Center board.
    ///
    /// **James, round 332's layout notes: "move the global game centre leaderboards section
    /// below the stats section, moving the stats section up. Add a header label to make it more
    /// clear that it's game centre leaderboards."** The line says "7/102 on the Emoji Pack
    /// board" and never said where that came from, sitting between the run's score and the
    /// run's own numbers as though it were one of them.
    let leaderboardTitle = UILabel()
    /// The rules sit with the level they are the rules of; the title makes room for them.
    private var rulesUnderTheLevel: NSLayoutConstraint!
    /// The same, for a day whose level name is blank - see where these are built.
    private var rulesUnderTheNumber: NSLayoutConstraint!
    private var titleUnderTheRules: NSLayoutConstraint!
    // **The day's rules belong with the day's level** (play-test round 126: "twist info
    // should go near level info"). They used to float a third of the way down the screen,
    // under the score, with the result line stuck to the bottom of the same label - so the
    // twists were nowhere near the level they applied to, and what the run *scored* was
    // buried in the middle of them. Split in two: the rules go up beside the level, and
    // the result goes down with the run's numbers where a result belongs

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

        scoreLabel.font = UIViewController.gameScoreFont(ofSize: scoreLabel.font.pointSize)
        highscoreLabel.font = UIViewController.gameScoreFont(
            ofSize: highscoreLabel.font.pointSize)
        // **The game's own face for the game's own numbers** (James, round 312: "on the game
        // over / completion screen for the scores, use the same font as the game"). Sized from
        // whatever the storyboard set, so the layout is untouched and only the face changes -
        // and the two labels other rows copy their font from stay the single source they were

        var stats = AttributedString("Statistics")
        stats.font = .boldSystemFont(ofSize: 14)
        var moreStats = UIButton.Configuration.plain()
        moreStats.attributedTitle = markedWithTheStatsIcon(stats)
        moreStats.image = UIImage(systemName: "chevron.right",
                                  withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 12, weight: .bold))
        moreStats.imagePlacement = .trailing
        // **A chevron, on the right** (James, round 312: "remove the 3 dots and have a right
        // facing chevron instead to indicate a button to more information"). The ellipsis said
        // "there is more of this text"; a chevron says "this goes somewhere", which is what the
        // button does. An SF Symbol rather than the app's own mark, because it carries its own
        // point size - which is the trap round 308 caught this button in from the other side
        // **The app's own statistics mark** (James, round 306: "for the stats label icon, use
        // the same graphic as used elsewhere in the app for stats"). It was a filled star,
        // which is not what statistics look like anywhere else in this app - the information
        // screen's Statistics row has worn `iconStats` since it existed.
        //
        // **Drawn to a size** (James, round 308: "the stats icon on the game over screen is way
        // too large"), which is round 306's mistake and worth naming: the star it replaced was
        // an SF Symbol carrying `pointSize: 12`, and a `UIImage(named:)` carries no such thing -
        // it arrives at whatever the asset was drawn at, which here is an icon meant for a
        // 44pt table row. A symbol's size travels with it; a PNG's does not.
        moreStats.imagePadding = 4
        moreStats.baseForegroundColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        moreStatsButton.configuration = moreStats
        moreStatsButton.translatesAutoresizingMaskIntoConstraints = false
        moreStatsButton.isHidden = true
        moreStatsButton.addTarget(self, action: #selector(moreStatsTapped),
                                  for: .touchUpInside)
        containterView.addSubview(moreStatsButton)
        // The door to the run's detail, at the bottom of the stats list (play-test
        // round 11) - it replaces the rosette that sat unexplained in the button row

        let statsClearOfTheScore = moreStatsButton.topAnchor.constraint(
            greaterThanOrEqualTo: highscoreLabel.bottomAnchor, constant: 34)
// `statsAboveTheButtons` is built with the result line, further down: it ties the
        // *bottom* of this group to the button row, and since round 332 the bottom of the group
        // is the Game Center line, which is not in the hierarchy yet at this point
        // Anchored to the button row, which the storyboard has already put in the hierarchy.
        // It cannot be anchored to `signedOutLabel` from here, however much that reads
        // better: this method runs from viewDidLoad before that label is added, and
        // activating a constraint between two views with no common ancestor yet throws -
        // the game-over screen crashed on the first try. The 46 leaves the note its room
        // High rather than required: on a short screen the clearance above wins and the
        // block simply sits wherever it fits, rather than the layout breaking a constraint
        // it cannot honour

        NSLayoutConstraint.activate([
            runStatsLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            statsClearOfTheScore,
            moreStatsButton.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            runStatsLabel.topAnchor.constraint(equalTo: moreStatsButton.bottomAnchor,
                                               constant: 8),
            // The stats block sits just above the button row rather than tucked under the
            // score (play-test round 97: "the stats sit too close to the scores"). Hung
            // from the bottom, with the 34pt clearance above kept as a minimum, so the two
            // blocks read as two things - the run's result up there, its detail down here -
            // rather than one crowded column. Rounds 15 and 16 asked for that air; round 97
            // said where it should go
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
        modeIconView = modeIcon
        // The mode's icon above its name, the same order the level intro splash uses
        // (play-test round 13): icon, then which mode, then what happened

        titleLabel.applyGigaBallGlow(radius: GigaBallGlow.headingRadius)
        // PAUSED / GAME OVER / COMPLETE glow like the wordmark does

        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: containterView.safeAreaLayoutGuide.topAnchor,
                                      constant: UIViewController.inGameLogoTopInset),
            logo.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            logo.heightAnchor.constraint(equalToConstant: UIViewController.inGameLogoHeight),
            logo.leadingAnchor.constraint(greaterThanOrEqualTo: containterView.leadingAnchor,
                                          constant: 60),

            modeIcon.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            modeIcon.widthAnchor.constraint(equalToConstant: UIViewController.inGameModeIconSize),
            modeIcon.heightAnchor.constraint(equalToConstant: UIViewController.inGameModeIconSize),
            // Its bottom is pinned in `layoutSubviews` instead, by `pinModeIcon`: above the
            // *pack* line where there is one, because in Classic and the daily there is a
            // label above the one naming the mode and anchoring to the lower of the two put
            // the icon straight through it (play-test round 14's screenshots) - and above the
            // mode's own line in the endless modes, where the pack line is empty and was
            // holding a blank line's height between the icon and the name (round 332)
        ])
    }

    /// The mode icon, and its bottom, kept against whichever title line is showing.
    private weak var modeIconView: UIImageView?
    private var modeIconBottom: NSLayoutConstraint?

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
            statsUnderTheResult.isActive = false
            statsWellUnderTheResult.isActive = false
            return
        }
        moreStatsButton.isHidden = false
        showActivePowerUps()

        guard isDailyChallenge == false else {
            runStatsLabel.isHidden = true
            statsUnderTheResult.isActive = false
            statsWellUnderTheResult.isActive = false
            return
            // **A daily says none of it on the screen** (James, round 241: "perhaps the stats
            // summary isn't important in daily challenges. All stats can go under the more
            // stats button"). This is the one ending that has the most to fit - a score
            // breakdown, the day's twists, the leaderboard note - and the summary is four
            // lines of numbers that are all still one tap away. Nothing is lost, because the
            // button is what the detail screen was always for.
            //
            // The two spacing constraints go with it. They exist to keep the result line and
            // the stats block apart, and with no stats block there is nothing to keep apart -
            // left active they would hold a gap open under the result for a thing that is not
            // there, which is the crowding from the other direction
        }

        runStatsLabel.isHidden = false
        statsUnderTheResult.isActive = true
        statsWellUnderTheResult.isActive = true
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

    var standing: LeaderboardStanding?
    // Where the finished run stands on its board, once Game Center has answered - today's
    // board for a daily, the mode's own for an endless or classic run

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

    /// The same call every other menu screen makes, and this screen never did.
    ///
    /// Two things had to be true before it could: the content box had to be driven by its
    /// constraints rather than frozen at a storyboard size (round 191 removed the size-class
    /// variation that was excluding them on iPad), and the cap had to measure the window
    /// rather than this view. With both, the pause and game-over screens are shaped like the
    /// rest of the app on an iPad instead of stretching the full width of one.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        collectionViewLayout()
        if let modeIconView {
            pinModeIcon(modeIconView, above: packNameLabel, or: levelNumberLabel,
                        keeping: &modeIconBottom)
        }
        // Which of the two title lines the icon sits on depends on what they say, and what
        // they say is written after the icon is built (round 332)
        // The row's spacing is worked out from the container's width, so it has to be worked
        // out *again* whenever that width changes - which it now can, where before the
        // container was a fixed 414 box and one pass at load time was the whole story
    }

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
        buttonCollectionView.clipsToBounds = false
        buttonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        levelTitleLowerConstraint.isActive = false
        levelNameLabelNormalConstraint.isActive = true
        // Default constraints setting

        homeButton.isHidden = sender != "Pause"
        applyRoundGlass(to: homeButton, radius: 25, symbol: "house.fill",
                        pointSize: 20, rimmed: false)
        setUpGameCentreButton()
        // The last PNG button on this screen. No rim at 50pt, and the helper is a no-op the
        // second time round, so it does not matter that this runs on every appearance
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

        askForStanding()
    }

    /// The board this finished run stands on, if it stands on one.
    ///
    /// A daily answers with today's board and only when the run actually posted - free play
    /// left no entry to stand on. Everything else answers with its mode's own board, which
    /// for a classic run is the pack's: a pack total is what `gameCenterSave` keeps current,
    /// where the per-level boards have had nothing posted to them for years.
    ///
    /// Nil in Single Level Mode, where the run was one level out of a pack and did not move
    /// the pack total it would otherwise be quoting - and nil in Endless Mayhem in practice,
    /// because its board does not exist in App Store Connect yet, which the load discovers
    /// for itself.
    private var runBoard: (id: String, name: String)? {
        if isDailyChallenge {
            return DailyChallengeSession.shared.lastRunPosted
                ? (DailyChallengeBoards.daily, "today's")
                : nil
            // The name goes unused here: the daily's sentence is written whole in
            // `updateResultLine`, because it has a posted-or-not to say first
        }
        guard endlessMode || numberOfLevels > 1 else { return nil }
        return GameMode.current(in: defaults).runLeaderboard(packNumber: packNumber)
    }

    /// Where this run stands globally, asked of Game Center once as the screen goes up.
    ///
    /// Only at the end of a run: mid-pause there is no result to place. What comes back
    /// counts the run that has just finished, because `InbewteenLevels` submits the score
    /// immediately before this screen is built - subject to Game Center taking its own
    /// moment over it, which is why the daily's line says "submitted" until the placing
    /// arrives rather than claiming a place it does not have yet.
    private func askForStanding() {
        guard sender != "Pause", let board = runBoard else { return }
        GameCenterHandler().loadRank(leaderboardID: board.id) { [weak self] standing in
            guard let self, let standing else { return }
            self.standing = LeaderboardStanding(rank: standing.rank,
                                                players: standing.players,
                                                best: standing.best)
            self.updateResultLine()
        }
        // The placing joins the block when Game Center answers; a screen already
        // dismissed just ignores it
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

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0
        resultLabel.font = .systemFont(ofSize: 12)
        resultLabel.textColor = UIColor(white: 1, alpha: 0.55)
        resultLabel.isHidden = true
        leaderboardTitle.isHidden = true
        resultLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        // **This line is never squashed.** It sits between two blocks that both hang off
        // required constraints - the score above it, the stats below hung from the button
        // row - and when the two met on a classic game over, the label was what gave: its
        // frame came out about two thirds of a line tall and the words were sliced through
        // the middle (round 160's screenshot). A label with default resistance loses that
        // argument every time; the margins around it are what should bend, and below they do
        containterView.addSubview(resultLabel)

        leaderboardTitle.translatesAutoresizingMaskIntoConstraints = false
        leaderboardTitle.textAlignment = .center
        leaderboardTitle.font = .boldSystemFont(ofSize: 11)
        leaderboardTitle.textColor = UIColor(white: 1, alpha: 0.38)
        leaderboardTitle.text = "GAME CENTER"
        leaderboardTitle.isHidden = true
        containterView.addSubview(leaderboardTitle)
        // Shown and hidden with the line it heads - `updateResultLabel` owns both

        dailyTotalTitle.translatesAutoresizingMaskIntoConstraints = false
        dailyTotalTitle.textAlignment = .center
        dailyTotalTitle.font = highscoreLabelTitle.font
        dailyTotalTitle.textColor = highscoreLabelTitle.textColor
        dailyTotalTitle.isHidden = true
        containterView.addSubview(dailyTotalTitle)

        dailyTotalLabel.translatesAutoresizingMaskIntoConstraints = false
        dailyTotalLabel.textAlignment = .center
        dailyTotalLabel.font = highscoreLabel.font
        dailyTotalLabel.textColor = highscoreLabel.textColor
        dailyTotalLabel.isHidden = true
        containterView.addSubview(dailyTotalLabel)
        // **The third row, and only the third.** The daily's Complete screen already has two
        // rows sitting where they are needed: the score row, and the high-score row - which a
        // daily blanks, because "the level's campaign high score belongs to the campaign".
        // So the breakdown borrows those two for Level Score and Time Bonus and adds one row
        // for the total, rather than building three and arguing with a layout that has been
        // crushed once already (round 160)

        signedOutLabel.translatesAutoresizingMaskIntoConstraints = false
        signedOutLabel.textAlignment = .center
        signedOutLabel.numberOfLines = 0
        signedOutLabel.font = .systemFont(ofSize: 12)
        signedOutLabel.textColor = UIColor(white: 1, alpha: 0.38)
        signedOutLabel.text = GameCenterHandler.notSignedInNote
        signedOutLabel.isHidden = true
        containterView.addSubview(signedOutLabel)

        let statsAboveTheButtons = resultLabel.bottomAnchor.constraint(
            equalTo: buttonCollectionView.topAnchor, constant: -46)
        statsAboveTheButtons.priority = .defaultHigh
        // The bottom of the lower group against the button row, at the gap round 112 settled
        // on. High rather than required: on a short screen the clearances above win and the
        // group simply sits where it fits, rather than the layout breaking a constraint it
        // cannot honour

        statsUnderTheResult = leaderboardTitle.topAnchor.constraint(
            greaterThanOrEqualTo: runStatsLabel.bottomAnchor, constant: 8)
        statsWellUnderTheResult = leaderboardTitle.topAnchor.constraint(
            greaterThanOrEqualTo: runStatsLabel.bottomAnchor, constant: 20)
        statsWellUnderTheResult.priority = .defaultHigh
        // **Eight required, twenty wanted.** Twenty was required until round 160, and with
        // the 22 above the line that asked for 42pt of clearance inside the 34pt the layout
        // actually guarantees between the score block and the stats - which is why the line
        // was crushed rather than moved on the fullest screen the app has. Eight and eight
        // fit a 12pt line inside that 34 with room to spare, and where a screen has more to
        // give the high-priority pair still spread the two blocks apart as they always did
        // Switched on with the stats themselves: the result line and the stats block are
        // both in the lower half now, and only a screen showing both needs them kept apart

        livesUnderDailyTotal = livesLabel.topAnchor.constraint(
            equalTo: dailyTotalLabel.bottomAnchor, constant: 6)
        // A third place for the lives line to hang from, for the same reason there were two:
        // a label with no text still holds its place, so it has to hang off whatever is
        // actually the bottom of the block above it

        livesUnderHighscore = livesLabel.topAnchor.constraint(
            equalTo: highscoreLabel.bottomAnchor, constant: 6)
        livesUnderScore = livesLabel.topAnchor.constraint(
            equalTo: scoreLabel.bottomAnchor, constant: 6)
        // Which of the two applies is decided in updateLivesLabel: the daily prints no
        // high score, and a label with no text still holds its place, so hanging the
        // lives line off it left "Last ball" stranded a third of a screen below the
        // score it belongs to (play-test round 16's screenshot)

        for label in [dailyLevelTitle, dailyBonusTitle] {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = highscoreLabelTitle.font
            label.textColor = highscoreLabelTitle.textColor
            label.isHidden = true
            containterView.addSubview(label)
        }
        for label in [dailyLevelLabel, dailyBonusLabel] {
            label.translatesAutoresizingMaskIntoConstraints = false
            label.textAlignment = .center
            label.font = highscoreLabel.font
            label.textColor = highscoreLabel.textColor
            label.isHidden = true
            containterView.addSubview(label)
        }
        // The borrowed rows' own fonts and colours, so the breakdown reads as the block it
        // replaced rather than as something new that arrived in its place

        dailyTotalUnderHighscore = dailyTotalTitle.topAnchor.constraint(
            equalTo: highscoreLabel.bottomAnchor, constant: 8)
        dailyTotalUnderColumns = dailyTotalTitle.topAnchor.constraint(
            equalTo: dailyLevelLabel.bottomAnchor, constant: 8)
        dailyTotalUnderHighscore.isActive = true
        // Under the columns when there are columns. A label that is hidden still holds its
        // place, so the borrowed rows would otherwise have gone on pushing the total down the
        // screen while showing nothing - which is the crowding this round is undoing

        NSLayoutConstraint.activate([
            dailyLevelTitle.topAnchor.constraint(equalTo: scoreLabelTitle.topAnchor),
            dailyLevelTitle.trailingAnchor.constraint(equalTo: containterView.centerXAnchor,
                                                      constant: -14),
            dailyLevelLabel.topAnchor.constraint(equalTo: dailyLevelTitle.bottomAnchor),
            dailyLevelLabel.centerXAnchor.constraint(equalTo: dailyLevelTitle.centerXAnchor),

            dailyBonusTitle.topAnchor.constraint(equalTo: scoreLabelTitle.topAnchor),
            dailyBonusTitle.leadingAnchor.constraint(equalTo: containterView.centerXAnchor,
                                                     constant: 14),
            dailyBonusLabel.topAnchor.constraint(equalTo: dailyBonusTitle.bottomAnchor),
            dailyBonusLabel.centerXAnchor.constraint(equalTo: dailyBonusTitle.centerXAnchor),
            // Two columns either side of the middle with 28pt between them, each centred on
            // itself rather than on the screen - so a four-figure score and a two-figure bonus
            // still read as a pair rather than as one line drifting off the other

            dailyTotalTitle.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            dailyTotalLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            dailyTotalLabel.topAnchor.constraint(equalTo: dailyTotalTitle.bottomAnchor),

            statsAboveTheButtons,
            leaderboardTitle.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            resultLabel.topAnchor.constraint(equalTo: leaderboardTitle.bottomAnchor,
                                             constant: 2),
            // Activated here rather than with the stats block above, which runs from
            // `viewDidLoad` before this label is in the hierarchy: a constraint between two
            // views with no common ancestor throws, which is the trap the note under
            // `statsAboveTheButtons` already describes

            signedOutLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            signedOutLabel.topAnchor.constraint(greaterThanOrEqualTo:
                                                    resultLabel.bottomAnchor,
                                                constant: 14),
            signedOutLabel.bottomAnchor.constraint(equalTo: buttonCollectionView.topAnchor,
                                                   constant: -12),
            signedOutLabel.topAnchor.constraint(greaterThanOrEqualTo:
                                                    runStatsLabel.bottomAnchor,
                                                constant: 6),
            // Pinned to the button row rather than floating under whatever happens to be
            // above it. Round 112 moved the stats block down to sit just above the buttons,
            // and this note - which is two lines wide and often hidden - was still hanging
            // off the summary above, so it landed *on* the buttons. Everything in this
            // lower group now hangs upward from the button row: buttons, note, More Stats,
            // stats list
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
            dailySummaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo:
                                                        containterView.leadingAnchor,
                                                       constant: 30),
            dailySummaryLabel.trailingAnchor.constraint(lessThanOrEqualTo:
                                                        containterView.trailingAnchor,
                                                        constant: -30),

            resultLabel.centerXAnchor.constraint(equalTo: containterView.centerXAnchor),
            resultLabel.topAnchor.constraint(greaterThanOrEqualTo:
                                                    livesLabel.bottomAnchor, constant: 8),
            {
                let preferred = resultLabel.topAnchor.constraint(
                    equalTo: livesLabel.bottomAnchor, constant: 22)
                preferred.priority = .defaultHigh
                return preferred
            }(),
            // Under the run's numbers, which is what it is one of: the score, the balls,
            // and then whether the score reached the board. The 22 is the wanted gap and
            // the 8 is the one that must hold: see `statsUnderTheResult` for why the pair
            // of required 20s either side of this line could not both be honoured
            resultLabel.leadingAnchor.constraint(greaterThanOrEqualTo:
                                                        containterView.leadingAnchor,
                                                      constant: 30),
            resultLabel.trailingAnchor.constraint(lessThanOrEqualTo:
                                                        containterView.trailingAnchor,
                                                       constant: -30),
        ])

        rulesUnderTheLevel = dailySummaryLabel.topAnchor.constraint(
            equalTo: levelNameLabel.bottomAnchor, constant: 10)
        rulesUnderTheNumber = dailySummaryLabel.topAnchor.constraint(
            equalTo: levelNumberLabel.bottomAnchor, constant: 10)
        // **Whichever of the two actually says something** (James, round 308: "the twist detail
        // [is] too low. It should sit just under the game mode and level detail").
        //
        // An endless day writes the mode into `levelNumberLabel` and leaves `levelNameLabel`
        // empty, and an empty label is not a collapsed one - it keeps a full line of height,
        // which the rules were then hung below. So the twists sat a blank line lower on exactly
        // the days that have no level name to sit under. Classic days are unaffected: their
        // level name is the last thing above the rules, as it was.
        titleUnderTheRules = titleLabel.topAnchor.constraint(
            equalTo: dailySummaryLabel.bottomAnchor, constant: 16)
        // Switched on with the summary itself, in `updateDailySummary`, because they
        // replace the storyboard's own "title under the level name" - and outside the daily
        // that is still the right answer. One below required, like the storyboard's own
        // lowered constraint, so a screen too short to honour everything bends here
    }
    // Matches the "Previous Highscore" title's font and colour, so it reads as another
    // line of the same block rather than something bolted on

    /// Collapses the lives line to nothing while it is hidden.
    ///
    /// **A hidden label is not a removed one** (James, round 308: "the posted score detail
    /// should sit closer underneath the final score"). Everything below the lives line hangs
    /// from its bottom, so hiding it left a whole blank line plus its margin between the score
    /// and the result - and round 306 *started* hiding it on endless dailies, which is when the
    /// gap appeared. Auto Layout keeps a hidden view's frame; only a zero height takes it away.
    private func collapseLivesLineWhileHidden() {
        if livesCollapsed == nil {
            livesCollapsed = livesLabel.heightAnchor.constraint(equalToConstant: 0)
        }
        livesCollapsed.isActive = livesLabel.isHidden
    }

    func updateLivesLabel() {
        defer { collapseLivesLineWhileHidden() }
        // After whichever branch below decides, so there is one place that acts on the decision
        // rather than six that have to remember to
        // The daily leaves the high score blank, so the lives line follows the score
        // itself there and the "Best" block everywhere else
        livesUnderDailyTotal.isActive = showsDailyBreakdown
        livesUnderHighscore.isActive = !isDailyChallenge
        livesUnderScore.isActive = isDailyChallenge && showsDailyBreakdown == false
        // Three now: the breakdown fills the high-score row and adds a total under it, so on
        // a finished daily the lives line hangs from the bottom of that instead

        guard sender == "Pause" else {
            livesLabel.isHidden = true
            return
        }
        if isDailyChallenge {
            let balls = livesRemaining + 1
            guard endlessMode == false || balls > 1 else {
                livesLabel.isHidden = true
                return
            }
            // **An endless daily with no extra balls says nothing** (James, round 306: "there's
            // no need to show Last ball if it's not a day where there's no extra lives in play.
            // Endless modes only have a single life so this is unnecessary detail"). It is not
            // news that an endless run has one ball; it is only news when a twist has granted
            // more, which is exactly when this line survives
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
            symbol: "calendar.badge.exclamationmark",
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

        let body = DailyTwist.explainer(for: challenge.twists)
        // Built by `DailyTwist.explainer` since round 308, because the briefing card now shows
        // the same pop-up and two copies of this block would be two copies of a decision

        GigaBallAlert.show(on: self, title: "Today's Twists", attributed: body,
                           symbol: "dice.fill")
    }

    /// The one line under the run's numbers saying where the score went.
    ///
    /// The same sentence in every mode, which is why it is one method and not a daily one
    /// with an endless one beside it: a daily that posted names today's board, a daily that
    /// did not says so, and an endless or classic run names the board it stands on. Mid-run
    /// it says nothing - the score has not gone anywhere yet.
    ///
    /// Run twice: once as the labels are built, and again if Game Center answers. Before it
    /// answers a daily says "submitted", because the score is genuinely on its way, and
    /// every other mode says nothing at all - there the line *is* the placing, and a line
    /// that appears empty and then fills reads as a glitch.
    func updateResultLine() {
        guard sender != "Pause" else {
            resultLabel.isHidden = true
            leaderboardTitle.isHidden = true
            return
        }

        if isDailyChallenge {
            resultLabel.isHidden = false
            leaderboardTitle.isHidden = false
            if DailyChallengeSession.shared.lastRunPosted {
                resultLabel.text = standing.map { "\($0.text) on today's leaderboard" }
                // **The placing is the line** (James, round 308: it "should read: 1/100 on
                // today's leaderboard"). "Posted," led it, which repeated what the screen has
                // already said by showing a score at all, and pushed the two numbers a player
                // came back for into the middle of the sentence. Same figures, same place as
                // the briefing screen (play-test round 126); fewer words in front of them
                    ?? "Submitted to today's leaderboard"
                // The placing arrives asynchronously when Game Center answers. Until
                // then "submitted" is the honest word (§12.5): the score is on its way,
                // and if it cannot land - signed out, offline, board not yet in App
                // Store Connect - the retry loop carries it and the briefing screen's
                // badge tells the truth of where it got to
            } else {
                resultLabel.isHidden = true
                leaderboardTitle.isHidden = true
                // Nothing to place, and the kind of run is said under the twists now, which
                // is where James asked for it (round 320) - see `updateDailySummary`
            }
            return
        }

        guard let board = runBoard, let standing else {
            resultLabel.isHidden = true
            leaderboardTitle.isHidden = true
            return
            // No board, or no answer from it: a run in Single Level Mode or the Tutorial,
            // a player signed out or offline, or Endless Mayhem, whose board James has yet
            // to create. Every one of those is a run with nowhere to stand, and the screen
            // says nothing rather than explaining itself - the signed-out note below
            // already covers the one case a player can do something about
        }
        resultLabel.isHidden = false
        leaderboardTitle.isHidden = false
        let suffix = GameMode.current(in: defaults).leaderboardUnit
        let best = standing.bestText(suffix: suffix).map { " · \($0)" } ?? ""
        resultLabel.text = "\(standing.text) on the \(board.name) board\(best)"
        // "12th / 843 on the Endless Mode board · Best 1,204m" - the placing says where this
        // run stands and the leader says what standing higher would take (round 185). Only
        // when Game Center actually knew a leader: a board with no entries prints nothing
        // rather than "Best 0"
        // "12th / 843 on the Endless Mode board" - the daily's grammar, against the board
        // this run's mode actually posts to (play-test request, ninth round)
    }

    /// The compact daily block: what kind of run this is, then each twist by icon and name.
    ///
    /// Two labels, not one (play-test round 126). The rules sit with the level info at the
    /// top of the screen, because that is what they are the rules of; the result - posted,
    /// or free play - sits with the run's numbers lower down, because that is what it is.
    /// The result line itself belongs to `updateResultLine`, which every mode shares.
    func updateDailySummary() {
        guard isDailyChallenge, let challenge = DailyChallengeSession.shared.active else {
            dailySummaryLabel.isHidden = true
            rulesUnderTheLevel?.isActive = false
            rulesUnderTheNumber?.isActive = false
            titleUnderTheRules?.isActive = false
            return
        }
        dailySummaryLabel.isHidden = false

        levelNameLabelNormalConstraint.isActive = false
        levelTitleLowerConstraint.isActive = false
        let levelNameIsBlank = (levelNameLabel.text ?? "").isEmpty
        rulesUnderTheLevel.isActive = levelNameIsBlank == false
        rulesUnderTheNumber.isActive = levelNameIsBlank
        titleUnderTheRules.isActive = true
        // An endless day leaves the level name empty and puts the mode in the line above it,
        // so the rules follow that line instead - see where these two are built (round 308)
        // The rules stand between the level's name and PAUSED, so the storyboard's own
        // "title under the level" steps aside for them. Both of its versions are switched
        // off rather than only the active one: which of the two is running depends on
        // whether the level line is filled, and a daily can be either
        if dailySummaryLabel.gestureRecognizers?.isEmpty ?? true {
            dailySummaryLabel.isUserInteractionEnabled = true
            dailySummaryLabel.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(dailyTwistsTapped)))
        }

        packNameLabel.numberOfLines = 2
        packNameLabel.text = "Daily Challenge\n"
            + DailyChallengeSession.shared.displayName(forKey: challenge.dateKey).capitalized
        // **The date goes on its own line** (James, round 332's layout notes, written against
        // five of the seven screens: "put the date on the line below Daily Challenge to avoid
        // any clipping on smaller devices"). "Daily Challenge, Yesterday" is a long line for a
        // label sized for "Classic Pack", and an iPhone SE has fifty points less to put it in
        // **The day, named where the level intro names it** (James, round 320: "on the pause
        // menu view, this info is arranged differently with no date info and the twist and
        // challenge or free play info swapped. Please arrange it in the same way as the level
        // intro splash screen. Use the same layout for the game over, game complete view").
        // The same words `InbetweenViewController.updateLabels` builds, so screens seconds
        // apart read the same from the top: mode icon, Daily Challenge and the day, the mode
        // or level, the twists, then what kind of run it is. An endless day left this line
        // blank and a classic day said "Daily Challenge" with no day at all. Written here
        // rather than in the branches above because every one of them is a daily's branch

        let summary = NSMutableAttributedString()

        for (position, twist) in challenge.twists.enumerated() {
            if position > 0 { summary.append(NSAttributedString(string: "\n")) }
            summary.append(twist.titleLine(font: .boldSystemFont(ofSize: 14),
                                           colour: .white, dateKey: challenge.dateKey))
        }
        if challenge.twists.isEmpty {
            summary.append(DailyTwist.vanillaLine(font: .boldSystemFont(ofSize: 14),
                                                  colour: .white))
            // A no-twist day is Vanilla, badged like any other (play-test round 3)
        }

        let scoring = sender == "Pause"
            ? DailyChallengeSession.shared.isScoringAttempt
            : DailyChallengeSession.shared.lastRunPosted
        summary.append(NSAttributedString(string: "\n"))
        summary.append(NSAttributedString(
            string: scoring ? "COMPETITION RUN" : "FREE PLAY",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 13),
                         .foregroundColor: scoring
                            ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
                            : UIColor(white: 1, alpha: 0.55)]))
        // **Under the twists, on every face of the screen**, which is where the intro puts it.
        // Mid-run it is what is riding on this one (play-test round 13); on the end screens it
        // is whether the run posted, which `updateResultLine` used to say from down among the
        // numbers - "for some reason in this view the challenge or free play info moves to near
        // the bottom of the screen". A posted run keeps its placing down there, because a
        // standing on a board is one of the run's numbers rather than the kind of run it was

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4
        summary.addAttribute(.paragraphStyle, value: paragraph,
                             range: NSRange(location: 0, length: summary.length))
        dailySummaryLabel.attributedText = summary
    }

    func collectionViewLayout() {
        layoutMenuButtonRow(buttonCollectionView,
                            sizes: [MainMenuCollectionViewCell.smallButtonSize,
                                    MainMenuCollectionViewCell.largeButtonSize,
                                    MainMenuCollectionViewCell.smallButtonSize])
        // **The one arrangement, at last** (round 126's last loose end, closed in round 206).
        // This row and the main menu's were the two that built their own layouts, and the
        // reason given was that both sized their collection view by assigning to
        // `frame.size.width` - which autolayout overwrites on the next pass. Round 191 took
        // that assignment out of here to unpin the iPad's pause screen from a 414pt box, and
        // with it went the reason this row could not come through the shared helper.
        //
        // The second reason was the cells: three 75pt boxes holding 50pt icons, so the outer
        // *icon* carried 12.5pt of padding no other row's did, and the row's storyboard
        // leading was 42.5 rather than 0 to cancel it - the one number that had to be written
        // twice, because a storyboard cannot read a constant. The outer cells are 50pt boxes
        // now, like every other screen's, so the box edge and the icon edge are the same edge
        // and there is nothing left to cancel. That leading is 0 in the storyboard and this
        // method owns the inset outright.
        //
        // Which also fixes what the compensation was quietly doing on an iPad. There the
        // helper's `max(0, target - fromScreen)` is already 0 - the row starts well past 55pt
        // from the screen - so nothing absorbed the 42.5 and the pause row sat that much
        // further inside the content column than every other screen's. It sits on the column's
        // edge now, which is where round 181 found the rest of them.
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let side = indexPath.row == 1
            ? MainMenuCollectionViewCell.largeButtonSize
            : MainMenuCollectionViewCell.smallButtonSize
        return CGSize(width: side, height: side)
    }
    // The centre is the large one on both faces of this screen - the pause screen's play and
    // the game-over screen's replay-or-home - which is what tells the shared layout to draw
    // the outer two in to the narrow inset rather than out to the wide one

    // Set the spacing between collection view cells
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        // A game over reads the same in every mode (play-test round 10): the replay on
        // the left, the big Home in the centre - the way the mode menus centre their big
        // play - and the run's detail on the right: today's board for a daily, the run
        // stats for an endless run, nothing yet for classic. A daily has no replay slot
        // at all: the scoring attempt is spent, and another go is a deliberate trip back
        // through the briefing screen, labelled practice
        switch indexPath.row {
        case 0:
            if self.sender == "Pause" {
                cell.setButton("ButtonInfo.png")
            } else if isDailyChallenge {
                cell.setButton("ButtonNull.png")
            } else {
                cell.setButton(endlessGameOver ? "ButtonHome" : "ButtonRestart")
            }
            cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        case 1:
            cell.widthConstraint.constant = MainMenuCollectionViewCell.largeButtonSize
            if self.sender == "Pause" {
                cell.setButton("ButtonPlay.png", pointSize: MainMenuCollectionViewCell.bigGlyphPointSize, rimmed: true)
                // The large size here, so the same glyph size and the same rim as the return-to-game
                // play on the menus - two buttons that do the same thing should not be two
                // different materials
            } else {
                cell.setButton(endlessGameOver ? "ButtonRestart" : "ButtonHome",
                               pointSize: MainMenuCollectionViewCell.bigGlyphPointSize,
                               rimmed: true)
                // The game-over screen's centre button is the large size like the pause screen's play,
                // and was drawing a 20pt glyph on it - a small mark adrift in a big disc
                // (play-test round 85). It is also that screen's positive action, replay or
                // home, so the same `rimmed` flag gives it the lime the play buttons wear
            }
        case 2:
            if self.sender == "Pause" {
                cell.setButton("ButtonSettings.png")
            } else if dailyGameOver || gameCentreIsOffered {
                cell.setButton("ButtonLeaderboard.png")
                // **The Game Center door lives here now** (James, round 313: "the Game Center
                // button on the game over / complete screen is in the top right. Move it to
                // the bottom right to line up with the other buttons, using the small
                // right-side button position and style").
                //
                // It was a loose disc added over the container and pinned to `homeButton`'s
                // centre - and `homeButton` is hidden on this screen, sitting where the
                // storyboard leaves it, which is the top corner. So the button was mirrored
                // across the top rather than lining up with anything.
                //
                // This slot is the run's detail (play-test round 10) and it was already the
                // leaderboard for a daily; a classic or endless ending had nothing to put in
                // it, which is what left the door homeless. Same picture as the mode menus
                // use for the same door, same small right-hand size, same row.
            } else {
                cell.setButton("ButtonNull.png")
                // The endless run's detail moved to the More Stats… button under the
                // stats list (play-test round 11) - the rosette here said nothing
            }
            cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        default:
            Log.ui.error("Row index out of range in \(#function, privacy: .public)")
            break
        }

        cell.view.transform = .identity
        // Set, not animated (play-test round 21: the buttons animate on every page). A
        // dequeued cell can carry the 0.95 scale a highlight left on it, and animating back
        // from that meant the play and close buttons bounced every time this screen was
        // reloaded - which is every time a screen opened from it closes. Growing back after
        // a press is the unhighlight's job, and it still does it

        return cell
    }
    
    /// Back to the main menu from a finished run. No warning: it is already over, so there is
    /// nothing left to lose.
    private func goHomeFromGameOver() {
        MenuViewController().clearSavedGame()
        moveToMainMenu()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if sender == "Pause" {
                openInformation()
            } else if endlessGameOver {
                goHomeFromGameOver()
            } else if isDailyChallenge == false {
                removeAnimate(nextAction: .restartGameNotificiation)
            }
            // A daily's game over has no restart - the slot is a null button there
        }
        if indexPath.row == 1 {
            if self.sender == "Pause" {
                removeAnimate(nextAction: .unpause)
            } else if endlessGameOver {
                removeAnimate(nextAction: .restartGameNotificiation)
            } else {
                goHomeFromGameOver()
            }
        }
        // The two swap places when an endless run ends (play-test round 39): replay takes the
        // big centre slot and home the small one on the left, because after an endless run the
        // thing almost everybody wants next is another go. A classic game over keeps the old
        // arrangement - there, home is the likelier answer, since the pack is finished with.
        // Both the pictures above and the actions here ask `endlessGameOver`, so the button
        // and what it does cannot end up disagreeing
        if indexPath.row == 2 {
            if self.sender == "Pause" {
                hideAnimate()
                moveToSettings()
            } else if dailyGameOver {
                openDailyLeaderboard()
            } else if gameCentreIsOffered {
                gameCentreTapped()
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
                        cell.setButton("ButtonInfoHighlighted.png")
                    } else if self.isDailyChallenge {
                        cell.setButton("ButtonNull.png")
                    } else {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.setButton("ButtonRestartHighlighted.png")
                    }
                case 1:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.setButton(self.sender == "Pause"
                                   ? "ButtonPlayHighlighted.png" : "ButtonHomeHighlighted.png")
                case 2:
                    if self.sender == "Pause" {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.setButton("ButtonSettingsHighlighted.png")
                    } else if self.dailyGameOver {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.setButton("ButtonLeaderboardHighlighted.png")
                    } else {
                        cell.setButton("ButtonNull.png")
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
                        cell.setButton("ButtonInfo.png")
                    } else if self.isDailyChallenge {
                        cell.setButton("ButtonNull.png")
                    } else {
                        cell.setButton("ButtonRestart.png")
                    }
                case 1:
                    cell.setButton(self.sender == "Pause"
                                   ? "ButtonPlay.png" : "ButtonHome.png")
                case 2:
                    if self.sender == "Pause" {
                        cell.setButton("ButtonSettings.png")
                    } else if self.dailyGameOver {
                        cell.setButton("ButtonLeaderboard.png")
                    } else {
                        cell.setButton("ButtonNull.png")
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
            scoreLabel.text = String(height) + "m"
            // **A score is never grouped, wherever it is printed** (play-test round 126,
            // narrowing round 33): separators belong to counts and totals - bricks
            // destroyed, lasers fired, play time - and a score or a height is read as a
            // score, the same shape here as on the field. Round 108 grouped these too and
            // that was a step past what was asked for
            if sender != "Pause" { startTally(to: height, suffix: "m") }
            // Only at the end of a run. Pausing mid-run to watch your own height counted back
            // to you would be telling you something you already know
            highscoreLabelTitle.text = "Hi-Score"

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
                    scoreLabelTitle.text = "New Hi-Score"
                    highscoreLabelTitle.text = "Previous Hi-Score"
                }
                highscoreLabel.text = String(heightBest) + "m"
            } else {
                let heightBest = runs.max() ?? 0
                highscoreLabel.text = String(heightBest) + "m"
                if runs.count <= 1 {
                    scoreLabelTitle.text = "New Hi-Score"
                    highscoreLabelTitle.text = "Previous Hi-Score"
                    highscoreLabel.text = "0m"
                } else {
                    var heightsArray = runs
                    heightsArray.sort(by: >)
                    let previousBestHeight = heightsArray[1]
                    if height > previousBestHeight {
                        scoreLabelTitle.text = "New Hi-Score"
                        highscoreLabelTitle.text = "Previous Hi-Score"
                        highscoreLabel.text = String(previousBestHeight) + "m"
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
                    swapTheLevelEmphasis()
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

            if showsDailyBreakdown {
                scoreLabelTitle.text = "Level Score"
                dailyTotalTitle.isHidden = false
                dailyTotalLabel.isHidden = false
                dailyTotalTitle.text = "Total Score"

                dailyLevelTitle.text = "Level Score"
                dailyBonusTitle.text = "Speed Bonus"
                for label in [dailyLevelTitle, dailyLevelLabel,
                              dailyBonusTitle, dailyBonusLabel] {
                    label.isHidden = false
                }
                scoreLabelTitle.isHidden = true
                scoreLabel.isHidden = true
                highscoreLabelTitle.isHidden = true
                highscoreLabel.isHidden = true
                dailyTotalUnderHighscore.isActive = false
                dailyTotalUnderColumns.isActive = true
                // **Two lines where there were three** (James, round 241). The borrowed rows
                // go away and the two columns take their place, so the total moves up a whole
                // row and the block below it gets that row back

                startDailyBreakdownTally()
                // **The breakdown a pack's end gives** (James, round 210: "single levels on
                // daily challenge need a time bonus on the complete screen... broken down like
                // the end of a pack in classic mode - level score, time bonus and total score,
                // using the same tally animation"). The time bonus was already in the posted
                // score; what was missing was the player being shown where it came from
            } else {
                scoreLabelTitle.text = "Score"
                scoreLabel.text = String(score)
                dailyTotalTitle.isHidden = true
                dailyTotalLabel.isHidden = true
                for label in [dailyLevelTitle, dailyLevelLabel,
                              dailyBonusTitle, dailyBonusLabel] {
                    label.isHidden = true
                }
                scoreLabelTitle.isHidden = false
                scoreLabel.isHidden = false
                highscoreLabelTitle.isHidden = false
                highscoreLabel.isHidden = false
                dailyTotalUnderColumns.isActive = false
                dailyTotalUnderHighscore.isActive = true
                // Put back, because `updateLabels` runs again every time this screen is
                // returned to - from settings, from the reference pages - and the screen it
                // comes back to is not always the one it left
                if sender != "Pause" {
                    startTally(to: score, suffix: "")
                }
            }
            // Every ending, not only Single Level Mode (play-test round 16: "the game over
            // screen should tally like the other screens do"). A pack's total was held back
            // because a level inside a run is one of many and its score carries into the
            // next - but this screen is only reached when there is no next: the run is over,
            // or the pack is complete. Mid-run counting stays where it belongs, on the
            // level summary between levels

            if showsDailyBreakdown {
                highscoreLabelTitle.text = "Speed Bonus"
                // The row a daily leaves empty is exactly the row the breakdown needs, and it
                // is already sitting under the score where the second line belongs
            } else if isDailyChallenge {
                highscoreLabelTitle.text = ""
                highscoreLabel.text = ""
                // The level's campaign high score belongs to the campaign - a daily on
                // that level is a different game with today's board to answer to
            } else {
                highscoreLabelTitle.text = "Hi-Score"
                // Get current highscore from level or pack

                highscoreLabel.text = String(previousHighscore)
                if score > previousHighscore {
                    scoreLabelTitle.text = "New Hi-Score"
                    highscoreLabelTitle.text = "Previous Hi-Score"
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

        updateDailySummary()
        updateResultLine()
        // **Last, not first.** Every branch above decides which of the storyboard's two
        // "title under the level" constraints is running, and the daily's rules replace
        // both - so the rules have to be placed after the branch that would put them back.
        // Called first, it left two constraints of equal priority fighting over the title
        // and the block laid out where nothing could be read
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
    
    /// The forward swipe's way of saying what opening a screen says directly.
    ///
    /// Without this the pause menu conformed to nothing, so `MenuNavigation.goForward` had no
    /// one to tell - swiping forward back into Settings or the information pages put them on
    /// top of a pause menu that was still fully drawn, which is the same two-button-rows
    /// problem arriving by the other door.
    func menuNavigationHideBehindChild() {
        hideAnimate()
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
        guard UIView.motionEffectsAreWelcome else { return }
        
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
    /// Whether the Main Menu question should offer a third answer: start this run again.
    ///
    /// **Only where the screen behind has no Restart of its own** (James, round 329). The pause
    /// screen carries Info, Play and Settings; the replay button only appears once a run has
    /// ended, which is a screen that has its own. So the offer belongs to the pause, and
    /// nowhere else.
    ///
    /// **Never in a Daily Challenge.** The scoring attempt is spent the moment it starts, and
    /// the daily's own game over has no replay for the same reason - another go is a deliberate
    /// trip back through the briefing screen, labelled free play. A Restart here would look
    /// like a second attempt and would not be one.
    var offersRestartInTheConfirm: Bool {
        self.sender == "Pause" && isDailyChallenge == false
    }

    private var levelEmphasisSwapped = false

    private func swapTheLevelEmphasis() {
        guard levelEmphasisSwapped == false else { return }
        levelEmphasisSwapped = true
        let number = (levelNumberLabel.font, levelNumberLabel.textColor)
        levelNumberLabel.font = levelNameLabel.font
        levelNumberLabel.textColor = levelNameLabel.textColor
        levelNameLabel.font = number.0
        levelNameLabel.textColor = number.1
    }

    @IBAction func homeButton(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if self.sender == "Pause" {
            GigaBallConfirm.mainMenu.show(on: self, restart: offersRestartInTheConfirm
                                          ? { [weak self] in
                                              self?.removeAnimate(nextAction: .restartGameNotificiation)
                                          } : nil)
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
        fillSelf(with: itemsView.view)
        self.view.addSubview(itemsView.view)
        itemsView.didMove(toParent: self)
    }

    /// The finished run's detail (§12.0), over the game-over screen the way the
    /// reference pages sit over the pause menu.
    /// The app's statistics icon, drawn at a size a button can wear.
    ///
    /// `iconStats` is an asset built for the information screen's rows, so it comes back far
    /// larger than a label's cap height. Rendered down here rather than constrained in the
    /// layout, because a button's configuration sizes itself around its image and a constraint
    /// fights that rather than settling it.
    ///
    /// Templated so it takes the button's own lime rather than arriving in its drawn colours.
    static func statsMark(pointSize: CGFloat) -> UIImage? {
        guard let art = UIImage(named: "iconStats.png") else { return nil }
        let side = pointSize
        let size = CGSize(width: side, height: side)
        let drawn = UIGraphicsImageRenderer(size: size).image { _ in
            art.draw(in: CGRect(origin: .zero, size: size))
        }
        return drawn.withRenderingMode(.alwaysTemplate)
    }

    /// The app's statistics mark, drawn at the size of the words beside it.
    ///
    /// **James, round 332's layout notes: "add stats icon from info screen to sit just before
    /// statistics label correctly sized."** The information screen's Statistics row has worn
    /// `iconStats` since it existed and this button had only a chevron, so the one place a run's
    /// numbers are offered looked like nothing else that offers them.
    ///
    /// "Correctly sized" is the whole difficulty, and round 308 has the scar: an SF Symbol
    /// carries its point size with it and a `UIImage(named:)` does not - it arrives at whatever
    /// the asset was drawn at, which here is an icon meant for a 44 point table row. So it is
    /// redrawn to the line's own cap height before it is attached.
    private func markedWithTheStatsIcon(_ title: AttributedString) -> AttributedString {
        let font = UIFont.boldSystemFont(ofSize: 14)
        guard let icon = UIImage(named: "iconStats") else { return title }
        let side = ceil(font.capHeight)
        let drawn = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
            icon.withTintColor(#colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1), renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        let attachment = NSTextAttachment(image: drawn)
        attachment.bounds = CGRect(x: 0, y: 0, width: side, height: side)

        let line = NSMutableAttributedString(attachment: attachment)
        line.append(NSAttributedString(string: " "))
        line.append(NSAttributedString(title))
        return AttributedString(line)
    }

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
        fillSelf(with: statsView.view)
        self.view.addSubview(statsView.view)
        statsView.didMove(toParent: self)
        statsView.showAnimate()
    }

    /// Today's board, from the finished daily (play-test round 9) - the same sheet the
    /// The door to Game Center, on the game-over screen, opposite Home.
    ///
    /// **James, round 312: "on the game over / completion screen put a button to access Game
    /// Center in the bottom right opposite where the home button is."** The end of a run is when
    /// a player wants to know where the run put them, and until now the only way there was back
    /// out through two menus.
    ///
    /// Mirrored with a pair of layout guides rather than by copying Home's inset, which lives in
    /// the storyboard and would be a second copy of a number that can move. The two guides fill
    /// the gap between each button and its own edge and are told to be the same width, so the
    /// two buttons are symmetric about the middle whatever the storyboard says and whatever the
    /// window is.
    /// Whether this screen has a Game Center door to offer, and room to put it.
    ///
    /// Round 313. The rules the loose button carried, kept exactly: not while paused - that
    /// screen's right-hand slot is Settings and there is a run to go back to - not for a
    /// daily, whose own board takes the slot, and not for a player who is not signed in,
    /// because a button that opens an authentication sheet at the end of a run is a door
    /// nobody asked to be shown.
    var gameCentreIsOffered: Bool {
        sender != "Pause" && dailyGameOver == false && GKLocalPlayer.local.isAuthenticated
    }

    private func setUpGameCentreButton() {
        containterView.viewWithTag(PauseMenuViewController.gameCentreButtonTag)?
            .removeFromSuperview()
        // **The loose disc is gone** (round 313). It lived over the container, pinned to a
        // hidden `homeButton`'s centre, which put it in the top corner. Its job is slot two of
        // the button row now. Kept as a removal rather than deleted outright because this
        // screen is reused between runs and a disc built by an older layout pass would
        // otherwise stay on it.
    }

    static let gameCentreButtonTag = 909_312

    @objc func gameCentreTapped() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let boards = GKGameCenterViewController(state: .leaderboards)
        boards.gameCenterDelegate = self
        view.window?.rootViewController?.present(boards, animated: true)
    }

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

    /// The in-game power-up row, on the pause screen (play-test rounds 37-39).
    ///
    /// What is running is drawn on the scene behind this menu, and the menu covers it - so the
    /// question "what have I still got?" could only be answered by unpausing. The row is drawn
    /// again here, identically, and each icon opens the pop-up that says what it does.
    private func showActivePowerUps() {
        let rings = InGameRecents.shared.activePowerUpRings
        if activePowerUpHUD == nil, rings.isEmpty == false {
            let hud = PausedPowerUpHUD()
            hud.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hud)
            NSLayoutConstraint.activate([
                hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hud.topAnchor.constraint(equalTo: runStatsLabel.bottomAnchor, constant: 14),
                hud.heightAnchor.constraint(equalToConstant: 34),
                hud.widthAnchor.constraint(equalTo: view.widthAnchor),
            ])
            hud.onSelect = { [weak self] index in self?.explainPowerUp(index) }
            activePowerUpHUD = hud
        }

        let setup = LevelPackSetup()
        let items: [PausedPowerUpHUD.Item] = rings.compactMap { ring in
            guard setup.powerUpImageArray.indices.contains(ring.index) else { return nil }
            return PausedPowerUpHUD.Item(powerUpIndex: ring.index,
                                         icon: setup.powerUpImageArray[ring.index],
                                         remaining: ring.remaining,
                                         segments: ring.segments)
        }
        activePowerUpHUD?.isHidden = items.isEmpty
        activePowerUpHUD?.show(items)
    }

    /// What that power-up does, in the app's own pop-up.
    private func explainPowerUp(_ index: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let setup = LevelPackSetup()
        guard setup.powerUpNameArray.indices.contains(index) else { return }

        GigaBallAlert.show(on: self,
                           title: setup.powerUpNameArray[index],
                           message: setup.powerUpDescriptionArray[index],
                           symbol: "arrow.up.circle.fill")
        // The power-up mark, the same one the statistics page uses for "power-ups released" -
        // a pop-up opened from the row of running power-ups should look like it came from
        // there
        // Through the type's own presenter rather than by building one: it puts the pop-up on
        // as a child, sizes it, and keeps the parameter order that stops a trailing closure
        // binding to the wrong button (round 19)
    }

    func moveToSettings() {
        hideAnimate()
        // **This line is the whole bug** (play-test rounds 33 and 37, reported twice). Every
        // other screen the pause menu opens hides it first - moveToItems does, openRunStats
        // does - and Settings did not. So the pause menu stayed fully drawn underneath with
        // its own play and close buttons in the bottom row, while the settings screen's
        // identical button row animated in on top of them. Two rows of buttons in the same
        // place, each running its own entry animation, is precisely "the buttons animating
        // over the top of one another". Round 21 fixed a different screen with the same
        // symptom, which is why it was reported again

        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsView.navigatedFrom = "PauseMenu"
        self.addChild(settingsView)
        fillSelf(with: settingsView.view)
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
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
    // MARK: - The daily's breakdown

    private var breakdownLink: CADisplayLink?
    private var breakdownStartedAt: CFTimeInterval = 0
    private var breakdownLastTick = -1
    private var hasRunBreakdownTally = false

    private var breakdownValues: ScoreTally.Values {
        ScoreTally.Values(level: levelScore, bonus: levelTimerBonus,
                          from: max(0, score - levelScore - levelTimerBonus), to: score)
    }

    /// Counts the three numbers out, by the same rule and the same curve the between-levels
    /// screen uses - `ScoreTally` owns both, so the two screens cannot drift apart.
    private func startDailyBreakdownTally() {
        guard hasRunBreakdownTally == false else {
            showBreakdown(ScoreTally.reading(at: ScoreTally.duration, of: breakdownValues))
            return
        }
        // Once per screen, for the reason `startTally` is: `updateLabels` runs again every
        // time this menu is returned to, and each of those was starting the count over
        hasRunBreakdownTally = true

        showBreakdown(ScoreTally.reading(at: 0, of: breakdownValues))
        breakdownStartedAt = CACurrentMediaTime()
        breakdownLastTick = -1
        let link = CADisplayLink(target: self, selector: #selector(stepDailyBreakdownTally))
        link.add(to: .main, forMode: .common)
        breakdownLink = link
    }

    @objc private func stepDailyBreakdownTally() {
        let elapsed = CACurrentMediaTime() - breakdownStartedAt
        guard elapsed < ScoreTally.duration else {
            showBreakdown(ScoreTally.reading(at: ScoreTally.duration, of: breakdownValues))
            breakdownLink?.invalidate()
            breakdownLink = nil
            return
        }
        showBreakdown(ScoreTally.reading(at: elapsed, of: breakdownValues))

        let tick = ScoreTally.tick(at: elapsed)
        if tick != breakdownLastTick {
            breakdownLastTick = tick
            if hapticsSetting { interfaceHaptic.impactOccurred(intensity: 0.5) }
        }
    }

    private func showBreakdown(_ reading: ScoreTally.Reading) {
        dailyLevelLabel.text = String(reading.level)
        dailyBonusLabel.text = String(reading.bonus)
        dailyTotalLabel.text = String(reading.total)
    }

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
        scoreLabel.text = String(Int((Double(heightTallyTarget)*eased).rounded())) + heightTallySuffix

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
        scoreLabel.text = String(heightTallyTarget) + heightTallySuffix
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

    /// The player chose, on the way out of a daily, to post the score they had (round 300).
    /// Carried to the scene because the scene owns the score and the record-keeping.
    public static let postDailyPartialScore =
        Notification.Name(rawValue: "postDailyPartialScore")

    /// The level's *name* is the thing worth reading; its number is only the position.
    ///
    /// **James, round 332's layout notes: "make Level 1 of 10 label less prominent, and level
    /// name more prominent."** The storyboard has it the other way about - the count is bold 25
    /// and the name semibold 17 - which was right when a pack's levels were numbered and
    /// nothing else, and reads oddly now that every level has a name.
    ///
    /// The two swap their type rather than being given new numbers, so both screens still take
    /// their sizes from the storyboard and cannot drift apart. Once per screen, because it is
    /// called from a method that runs on every appearance.



}
// Notification setup for sending information from the pause menu popup to unpause the game
