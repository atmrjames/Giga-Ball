//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GameKit
import StoreKit

class MenuViewController: UIViewController, MenuViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    // Haptics setup
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Game view properties
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    var ballSetting: Int = 0
    var paddleSetting: Int = 0
    var brickSetting: Int = 0
    var appIconSetting: Int = 0
    var statsCollapseSetting: Bool = true
    var swipeUpPause: Bool = true
    var appOpenCount: Int = 0
    var gameInProgress: Bool = false
    var resumeGameToLoad: Bool = false
    var iCloudSetting: Bool = false
    var firstPause: Bool = true
    // User settings
    var savedGame: SavedGame?
    // Game save settings
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    
    var localCurrency: String?
    // IAP
    
    @IBOutlet var modeSelectTableView: UITableView!
    @IBOutlet var iconCollectionView: UICollectionView!
    @IBOutlet var logoImage: UIImageView!
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var backgroundBlurView: UIView!
    
    @IBOutlet var tableViewContainer: UIView!
    
    var group: UIMotionEffectGroup?
    var blurViewLayer: UIVisualEffectView?
    
    var firstLaunch: Bool = false
    // Check if this is the first opening of the app since closing to know if to run splash screen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
//        SKPaymentQueue.default().add(self)
                
        NSLayoutConstraint.activate([
            modeSelectTableView.topAnchor.constraint(
                greaterThanOrEqualTo: tableViewContainer.topAnchor),
            modeSelectTableView.bottomAnchor.constraint(
                lessThanOrEqualTo: tableViewContainer.bottomAnchor),
        ])

        let rows = modeSelectTableView.heightAnchor.constraint(equalToConstant: 0)
        rows.isActive = true
        modeRowsHeight = rows
        // **Said outright rather than left to the content** (round 313). Without this the
        // table's height is its intrinsic content size, and that does not update inside the
        // same layout pass that changes the row height - `reloadData` does not invalidate it -
        // so the table spent a pass at four rows of the *previous* height. On a phone that
        // left 495 points of rows in 450 points of table: a main menu that scrolls, which is
        // the one thing this menu is not allowed to do.
        // **The rows cannot leave the room they were given** (James, round 313). The row
        // height above is what decides how tall the table wants to be, and getting that
        // arithmetic right is what makes it fit - but the table is centred in its container
        // with nothing pinning its ends, so a wrong answer does not crowd the rows, it hangs
        // them out of both ends of the container and over the two things either side.
        //
        // Within rather than equal to, so the rows stay *centred* in the room by the
        // storyboard's `centerY` when there is more of it than they need. A tall thin window
        // gives the container 823 points and the rows are capped at `tallestModeRow` apiece,
        // so 480 of table has 343 to spare - pinned to both ends it would sit that gap under
        // the last mode instead of splitting it, and the four buttons would bunch at the top.
        // There is more spare room since round 314 lowered that ceiling, so the centring
        // matters more than it did, not less.
        //
        // A table's height comes from its content at the ordinary compression-resistance
        // priority, so these two win over it when the room runs out. In a window too short
        // for four cards the rows scroll rather than escaping, which is the graceful way for
        // "the main menu never scrolls" to fail: the player can still reach every mode.
        //
        // In code rather than in the storyboard because the storyboard's own three
        // constraints for this table are size-class variations of each other and adding a
        // fourth by hand there is how that set stops being readable.

        logoImage.image = UIImage(named: "Logo")
        logoImage.applyGigaBallGlow(radius: GigaBallGlow.wordmarkRadius)
        // Radiating evenly rather than downward (play-test round 13): the offset version
        // read as motion blur on a wordmark this wide - see GigaBallGlow

        modeSelectTableView.delegate = self
        modeSelectTableView.dataSource = self
        modeSelectTableView.register(UINib(nibName: "ModeSelectTableViewCell", bundle: nil), forCellReuseIdentifier: "modeSelectCell")
        // Levels tableView setup
        
        iconCollectionView.delegate = self
        iconCollectionView.dataSource = self
        iconCollectionView.clipsToBounds = false
        iconCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnMenuNotificationKeyReceived), name: .returnMenuNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnSettingsNotificationKeyReceived), name: .returnSettingsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the settings menu
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.splashScreenEndedNotificationKeyReceived), name: .splashScreenEndedNotification, object: nil)
        // Sets up an observer to watch for the end of the splash screen in order to load game center authentification
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.foregroundNotificationKeyReceived), name: .foregroundNotification, object: nil)
        // Sets up an observer to watch for the app returning from the background
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.cancelGameResumeNotificationKeyReceived), name: .cancelGameResume, object: nil)
        // Sets up an observer to watch for notifications to check game resume has been cancelled from splash screen
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePurchaseNotification(_:)), name: .IAPHelperPurchaseNotification, object: nil)
        
//        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
                
        backgroundImageView.image = UIImage(named:"mainMenuBackground.png")!
        
        defaultSettings()
        refreshView()
        collectionViewLayout()
        authGCPlayer()
        
        if musicSetting {
            MusicHandler.sharedHelper.playMusic(sender: "Menu")
        }

        showSplashScreen()
        // Show splashscreen when first opening the app
    }

    override func viewWillAppear(_ animated: Bool) {
        refreshView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWhatsNewIfDue()
    }

    /// Greets a player who has just updated, once.
    ///
    /// From `viewDidAppear` rather than `viewDidLoad`, because a pop-up presented before the
    /// menu is on screen has nothing to sit on. The version is written whether or not the
    /// note is shown, so a fresh install is quietly marked as having seen 1.3 and is never
    /// told about an update it did not have.
    private func showWhatsNewIfDue() {
        let defaults = UserDefaults.standard
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? ""
        let seen = defaults.string(forKey: WhatsNew.seenKey)
        let played = (totalStatsArray.first?.levelsPlayed ?? 0) > 0
            || (totalStatsArray.first?.endlessModeHeight.isEmpty == false)

        defaults.set(current, forKey: WhatsNew.seenKey)
        guard WhatsNew.shouldShow(seen: seen, current: current, hasPlayedBefore: played) else {
            return
        }
        GigaBallAlert.show(on: self, title: WhatsNew.title, message: WhatsNew.message,
                           symbol: "sparkles")
    }

    /// Tells the player how yesterday's daily went, once, on the first launch after it closed.
    ///
    /// **James, round 358b:** "When opening the app for the first time after a played daily
    /// challenge has closed, a pop-up should appear that tells the user how they did with
    /// respect to the Game Center leaderboard ... If the user is the top scorer, the pop up
    /// should show that, be more bold and colourful." Which day, and the words, are
    /// `DailyResultReport`'s; this is only the when and the where.
    ///
    /// Only onto a menu with nothing in front of it - not over a resume, a game, a screen the
    /// player has already opened, or another pop-up such as What's New. A day that cannot be
    /// shown now is not marked as told, so the next launch on the same day tries again.
    func reportYesterdaysDailyIfDue() {
        guard GameCenterHandler.isRunningTests == false, splashScreenIsShowing == false,
              DailyResultReport.isOn(in: defaults),
              resumeGameToLoad == false, askingForTheDailyReport == false,
              GKLocalPlayer.local.isAuthenticated, somethingIsInFront == false,
              let stats = totalStatsArray.first,
              let key = DailyResultReport.dayToReport(
                in: stats.dailyRecords, today: DailyChallengeSession.shared.todayKey,
                lastReported: defaults.string(forKey: DailyResultReport.reportedKey))
        else { return }

        askingForTheDailyReport = true
        let unit = DailyChallengeGenerator.challenge(forKey: key).mode == .classic ? "" : "m"
        GameCenterHandler().loadDailyBoardTop(forKey: key,
                                              count: DailyResultReport.leadersShown) {
            [weak self] answer in
            guard let self else { return }
            self.askingForTheDailyReport = false
            guard let answer,
                  let report = DailyResultReport(leaders: answer.leaders, local: answer.local,
                                                 players: answer.players, unit: unit),
                  self.somethingIsInFront == false, splashScreenIsShowing == false
            else { return }
            // Asked again after the answer: it is a network round trip, and the player may
            // have opened something in the meantime

            self.defaults.set(key, forKey: DailyResultReport.reportedKey)
            GigaBallAlert.show(on: self, title: report.title, attributed: report.body(),
                               symbol: report.symbol, celebrating: report.won,
                               dismissTitle: "Close", confirmTitle: "Leaderboard",
                               confirm: { [weak self] in self?.openDailyBoard() })
        }
    }

    /// Whether the daily report is out asking Game Center, so a second trigger does not ask
    /// twice and show two pop-ups.
    private var askingForTheDailyReport = false

    /// A screen, a game or a pop-up over the menu. A child screen's view leaves the window
    /// when it closes, so a child still on screen is one still in front.
    private var somethingIsInFront: Bool {
        presentedViewController != nil
            || children.contains { $0.viewIfLoaded?.superview != nil }
    }

    /// Game Center on the daily board. Today's day rather than the one reported: Game Center
    /// cannot show a closed day (round 361, `GameCenterHandler.dailyBoardScreen()`), and the
    /// pop-up has just shown its top places.
    private func openDailyBoard() {
        let boards = GameCenterHandler.dailyBoardScreen()
        boards.gameCenterDelegate = self
        present(boards, animated: true)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        fitTheMenuToTheWindow()
    }

    /// The storyboard's four vertical gaps: over the logo, under it, under the rows and under
    /// the button row.
    ///
    /// Looked up on every pass rather than kept: a size-class change swaps which of the
    /// storyboard's constraints are active, and an inactive constraint is not in the list.
    private var menuGaps: (overLogo: [NSLayoutConstraint], underLogo: [NSLayoutConstraint],
                           underRows: [NSLayoutConstraint],
                           underButtons: [NSLayoutConstraint]) {
        let all = view.constraints
        func find(_ test: (NSLayoutConstraint) -> Bool) -> [NSLayoutConstraint] {
            all.filter(test)
        }
        return (
            find { $0.firstItem === self.logoImage && $0.firstAttribute == .top },
            find { $0.firstItem === self.tableViewContainer && $0.firstAttribute == .top
                && $0.secondItem === self.logoImage },
            find { $0.firstItem === self.iconCollectionView && $0.firstAttribute == .top
                && $0.secondItem === self.tableViewContainer },
            find { $0.secondItem === self.iconCollectionView && $0.secondAttribute == .bottom }
        )
    }

    /// Sets the menu's vertical gaps for the room the window gives it.
    ///
    /// **James, round 351, from an iPad in a window: "main menu cells not centred between bottom
    /// icons and giga-ball logo".** The storyboard fixes the gaps - 140 over the logo on an
    /// iPad, 90 under it, 50 under the rows and 85 under the buttons - which is 365 points of
    /// air before a row is drawn, and a short window has not got it: the rows were squeezed to
    /// two and a half. And 90 above against 50 below put the rows low in whatever room was left.
    ///
    /// Now the space above and below the rows is the same, and every gap gives way together,
    /// down to a quarter of itself, once the window cannot hold the four rows at a phone's
    /// spacing. A constant, not a new constraint: UIKit re-applies a size-class variation's
    /// constraints on every trait change (see `StoryboardConstraintChoices`), and a constant
    /// set on those same constraints survives that where a replacement would not.
    func fitTheMenuToTheWindow() {
        let height = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom
        let base = MenuViewController.menuGaps(height: height)
        let scale = MenuViewController.gapScale(height: height)
        let gaps = menuGaps
        for (constraints, wanted) in [(gaps.overLogo, base.overLogo),
                                      (gaps.underLogo, base.aroundRows),
                                      (gaps.underRows, base.aroundRows),
                                      (gaps.underButtons, base.underButtons)] {
            for constraint in constraints where abs(constraint.constant - wanted*scale) > 0.5 {
                constraint.constant = wanted*scale
            }
        }
        // Only when it has changed: assigning a constant marks the layout dirty, and this runs
        // inside a layout pass
    }

    /// The gaps at full size: the storyboard's, with the two either side of the rows evened out.
    ///
    /// **Chosen by the room, not the size class** (James, round 370, dragging a Mac window
    /// wider: "the Giga-Ball logo and bottom buttons pop out further at a certain width"). The
    /// phone's gaps and the iPad's were picked by the width class, so a window crossing the
    /// width where it turns regular - about 680 points on his Mac - dropped the logo 80 points
    /// in one step with nothing about its height having changed. The iPad's gaps are for a
    /// tall screen, so the height decides: a phone's up to the tallest phone, the iPad's from a
    /// little above it, and a blend between, so no drag of any edge makes a step.
    static func menuGaps(height: CGFloat) -> (overLogo: CGFloat, aroundRows: CGFloat,
                                              underButtons: CGFloat) {
        let phone: (CGFloat, CGFloat, CGFloat) = (62, 57.5, 85)
        let tall: (CGFloat, CGFloat, CGFloat) = (140, 70, 85)
        let along = min(1, max(0, (height - tallestPhoneRoom)/(tallRoom - tallestPhoneRoom)))
        return (phone.0 + (tall.0 - phone.0)*along,
                phone.1 + (tall.1 - phone.1)*along,
                phone.2 + (tall.2 - phone.2)*along)
    }

    /// The menu's room on the tallest phone: an iPhone Pro Max is 956 points, less its 62 and 34
    /// of safe area. Every phone is at or under it, so every phone keeps the gaps it always had.
    static let tallestPhoneRoom: CGFloat = 860

    /// Where the iPad's gaps are reached in full - a 13-inch iPad's room once the menu's height
    /// cap has had its say, and a little under it so landscape gets them too.
    static let tallRoom: CGFloat = 960

    /// How much of their full size the gaps keep in a window this tall.
    ///
    /// Full size while the four rows still get a full card each; below that the gaps give up
    /// what the rows need, and never go under a quarter. A phone keeps its gaps.
    static func gapScale(height: CGFloat) -> CGFloat {
        let gaps = menuGaps(height: height)
        let full = gaps.overLogo + gaps.aroundRows*2 + gaps.underButtons
        let fixed: CGFloat = 45 + 50
        // The logo and the button row, which do not shrink
        let rows = ModeSelectTableViewCell.fullCard*CGFloat(GameMode.allCases.count)
        guard full > 0 else { return 1 }
        return min(1, max(0.25, (height - fixed - rows)/full))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        capMenuContentSize()
        if let row = iconCollectionView, row.bounds.width > 0,
           abs(row.bounds.width - buttonRowLaidOutAt) > 0.5 {
            collectionViewLayout()
        }
        // The button row follows the window (round 341) - see `buttonRowLaidOutAt`
        // **The main menu was the one screen that never asked for the column** (James, round
        // 339, from an iPad: "the cell views expand with the window until a point, then snap
        // back to a set width once the window is wide enough"). Every other menu holds its
        // content to `menuMaximumWidth`; this one filled whatever window it was given, so the
        // rows were a different width on every drag of the corner.
        let room = menuRoomForModeRows
        guard room > 0 else { return }
        let fitted = MenuViewController.modeRowHeight(inRoomOf: room)
        let wanted = min(room, fitted*CGFloat(GameMode.allCases.count))

        if modeSelectTableView.rowHeight != fitted {
            modeSelectTableView.rowHeight = fitted
            modeSelectTableView.reloadData()
        }
        if let modeRowsHeight, abs(modeRowsHeight.constant - wanted) > 0.5 {
            modeRowsHeight.constant = wanted
        }
        if modeSelectTableView.contentOffset != .zero {
            modeSelectTableView.contentOffset = .zero
        }
        // The menu never scrolls, so its rows always start at the top - whatever a rotation or
        // a resize left the offset at (round 350, below)
        // The first cells can be asked for before the table has its size, and a row height
        // computed from a zero-height table would stick. Re-fitted here once the layout is
        // real, and only when it actually changed - reloadData in a layout pass loops, and so
        // does assigning a constraint's constant
    }

    /// The height of the four rows together, so the table is exactly as tall as they are.
    private var modeRowsHeight: NSLayoutConstraint?

    /// The height the four mode rows have to share.
    ///
    /// **The container's, not the table's** (James, round 313: the iPad's "layouts need work
    /// with resizing", and two of his screenshots show the wordmark sitting on top of Classic
    /// Mode and the information and settings buttons sitting on top of Daily Challenge).
    ///
    /// The old line asked `modeSelectTableView.bounds.height`, and that is circular: a table
    /// with no vertical pin takes its height from its content, and its content is four rows of
    /// whatever this returns. Every height is its own fixed point, so the answer was simply
    /// whatever the table happened to start at - 150 a row, 600 points of table - and in a
    /// windowed iPad the container it is centred in is 248 points tall. The table then hangs
    /// 158 points out of each end of it: over the logo above, and over the icon row below.
    /// Measured, in a 931x708 window: container 275 to 523, table 117 to 680, logo 140 to 185.
    ///
    /// The container's height is the room that actually exists, and it is not defined in terms
    /// of the answer, so there is nothing circular left.
    private var menuRoomForModeRows: CGFloat { tableViewContainer.bounds.height }

    /// Re-fits the mode rows once a rotation or a window resize has finished.
    ///
    /// **James, round 350, with two iPad screenshots: "iPad landscape layout of main menu changes
    /// when going to portrait and back."** Back in landscape the table was two rows tall, with
    /// Mayhem and the Daily Challenge gone below its edge. The rows are fitted in
    /// `viewDidLayoutSubviews` from the room they have, and a pass taken part-way through the
    /// rotation's animation measures a room that is neither the old window nor the new one. A
    /// window resize on the simulator lands correctly every time (`MenuLayoutTests`); the
    /// rotation's in-between pass is the one thing a test here cannot make, so the fit is taken
    /// again once the rotation has finished, from the window it finished in.
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self else { return }
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.modeSelectTableView.reloadData()
        }
    }

    /// Every mode fits on screen at once - the main menu never scrolls (play-test rule).
    ///
    /// Four rows at the old fixed 150 overflowed the 450pt table and the fourth mode was below
    /// the fold. The card inside the cell is 75pt, so rows can bunch to a quarter of the room
    /// and the gap between the cards is what gives.
    static func modeRowHeight(inRoomOf room: CGFloat) -> CGFloat {
        guard room > 0 else { return tallestModeRow }
        return max(ModeSelectTableViewCell.smallestRow,
                   min(tallestModeRow, room/CGFloat(GameMode.allCases.count)))
        // Never below the smallest the card can be, or the cards start overlapping each other
        // instead. Below a full card's height the card shrinks with its row (round 351,
        // `ModeSelectTableViewCell.fitCard`)
    }

    /// The most room a mode row may take, however tall the window is.
    ///
    /// **120, down from 150** (James, round 314: "limit how tall and wide the UI elements
    /// become"). The card inside a row is 75 points and never changes, so all a taller row
    /// buys is a bigger gap between cards. A phone has room for about 108 a row, which is a
    /// gap of 33; the old ceiling of 150 was only ever reached on a large iPad, where it made
    /// the gap 75 - more than twice the phone's, and the four modes drifted apart down the
    /// screen instead of reading as one block.
    ///
    /// This is a ceiling and not a fixed height: every phone is still below it and so is
    /// unchanged, to the point.
    static let tallestModeRow: CGFloat = 120
    
    func setBlur() {
        backgroundBlurView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0)
        let blurEffect = UIBlurEffect(style: .dark)
        blurViewLayer = UIVisualEffectView(effect: blurEffect)
        blurViewLayer!.translatesAutoresizingMaskIntoConstraints = false
        backgroundBlurView.insertSubview(blurViewLayer!, at: 0)

        NSLayoutConstraint.activate([
        blurViewLayer!.heightAnchor.constraint(equalTo: backgroundBlurView.heightAnchor),
        blurViewLayer!.widthAnchor.constraint(equalTo: backgroundBlurView.widthAnchor),
        blurViewLayer!.leadingAnchor.constraint(equalTo: backgroundBlurView.leadingAnchor),
        blurViewLayer!.trailingAnchor.constraint(equalTo: backgroundBlurView.trailingAnchor),
        blurViewLayer!.topAnchor.constraint(equalTo: backgroundBlurView.topAnchor),
        blurViewLayer!.bottomAnchor.constraint(equalTo: backgroundBlurView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func addParallaxToView() {
        guard UIView.motionEffectsAreWelcome else { return }
        var amount = 20
        if view.frame.width > 450 {
            amount = 25
            // iPad
        }
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            backgroundImageView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundImageView.addMotionEffect(group!)
    }
    
    func showSplashScreen() {
        if firstLaunch == false {
            firstLaunch = true
            let splashView = self.storyboard?.instantiateViewController(withIdentifier: "splashView") as! SplashViewController
            
            userSettings()
            if resumeGameToLoad {
                splashView.gameToResume = true
            } else {
                splashView.gameToResume = false
            }
            
            self.addChild(splashView)
            fillSelf(with: splashView.view)
            self.view.addSubview(splashView.view)
            splashView.didMove(toParent: self)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GameMode.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modeSelectCell", for: indexPath) as! ModeSelectTableViewCell

        modeSelectTableView.rowHeight =
            MenuViewController.modeRowHeight(inRoomOf: menuRoomForModeRows)
        // The same rule as the layout pass, from the same place. Asked here too because the
        // first cells can be built before any layout has happened

        cell.fitCard(toRow: modeSelectTableView.rowHeight)
        let mode = GameMode(rawValue: indexPath.row) ?? .classic
        cell.modeTextLabel.text = mode.name
        cell.modeImageIcon.image = GameMode.menuIcon(for: mode)
        cell.onPlay = { [weak self] in self?.playStraightIn(mode) }
        cell.showsNotification = mode == .daily && totalStatsArray.isEmpty == false
            && DailyChallengeSession.shared.todayIsUnplayed(in: totalStatsArray[0])
        // Straight into a game from the main menu, and a dot for a daily not yet played
        // (James, round 346) - see `ModeSelectTableViewCell.onPlay`
        
        UIView.animate(withDuration: 0.1) {
            cell.cellView1.transform = .identity
            if cell.isGlass == false {
                cell.cellView1.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? ModeSelectTableViewCell {
            UIView.animate(withDuration: 0.1) {
                if cell.isGlass == false {
                    cell.cellView1.backgroundColor = #colorLiteral(red: 0.5015605688, green: 0.4985827804, blue: 0.503851831, alpha: 1)
                }
            }
        }

        let mode = GameMode(rawValue: indexPath.row) ?? .classic
        if mode != .daily {
            mode.makeCurrent(in: defaults)
        }
        // Recorded before the run starts, so the scene and the stats know which mode this
        // is without having to infer it from a level number. The daily is a menu identity,
        // not a scene one - the briefing records the *underlying* mode when play is pressed,
        // and recording .daily here would leave a resumed campaign save reading the wrong
        // mode after a browse-and-close

        switch mode {
        case .classic:
            moveToPackSelector()
        case .endless, .endlessII:
            moveToLevelStats(startLevel: LevelPackSetup.shared.startLevelNumber[1],
                             levelNumber: LevelPackSetup.shared.startLevelNumber[1],
                             packNumber: 1)
            // Endless 2.0 plays the endless field for now, and differs only in what it
            // records and where it posts. The new bricks and power-ups come in later
            // phases
        case .daily:
            moveToDailyChallenge()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update collection view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        InterfaceSound.click()
        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? ModeSelectTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView1.transform = .init(scaleX: 0.95, y: 0.95)
                if cell.isGlass == false {
                    cell.cellView1.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = self.modeSelectTableView.cellForRow(at: indexPath) as? ModeSelectTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView1.transform = .identity
                if cell.isGlass == false {
                    cell.cellView1.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
                }
            }
        }
    }
    
    func collectionViewLayout() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        
        if view.frame.size.width <= 414 {
            tableViewContainer.frame.size.width = view.frame.size.width
        }
        // Ensures the container is the correct size

        let rowWidth = tableViewContainer.frame.size.width
            - UIViewController.menuButtonRowInset*2
        // **The width is the storyboard's now** (round 157). This used to assign
        // `iconCollectionView.frame.size.width` here, which autolayout overwrote on the next
        // pass - so the row was never the width this line thought it was, and the spacing
        // below was computed from a number that never existed. The row's leading and
        // trailing constraints are `menuButtonRowInset`, and this is the same arithmetic
        // read off the same constant, so the two cannot drift

        let measured = iconCollectionView.bounds.width > 0 ? iconCollectionView.bounds.width
                                                           : rowWidth
        let slack: CGFloat = 1
        let spacing = max(0, ((measured - slack - 50*3)/2).rounded(.down))
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        let spare = max(0, measured - slack - 50*3 - spacing*2)
        layout.sectionInset = UIEdgeInsets(top: 0, left: spare/2, bottom: 0, right: spare/2)
        // **A point short of the row, on purpose** (James, round 370, from a Mac window: the
        // settings button "can also disappear"). The three cells and their gaps used to add up
        // to the row's width exactly, and a flow layout puts a cell that does not fit on a line
        // of its own - below this one-line row, where nobody sees it. A row a part-point
        // narrower than the one this was worked out for, which is what a Mac's 77% scale makes
        // of most window sizes and what the half-point re-layout threshold below lets stand,
        // was enough to push the settings button off. A point to spare is centred like the
        // rest of the spare, so nothing moves that anyone could see
        // **Centred, to the point** (James, round 351: "info and settings buttons not always
        // centred horizontally on screen"). The spacing is rounded down so the three always fit
        // one line, and whatever the rounding leaves is shared either side rather than left
        // at the end
        buttonRowLaidOutAt = measured

        iconCollectionView!.collectionViewLayout = layout
    }

    /// The width the button row's spacing was last worked out for.
    ///
    /// **James, round 341, from an iPad with the window dragged narrow: "on iPad the settings
    /// icon on the main menu is still disappearing when the screen is narrow."** Round 339 made
    /// every *other* screen's row give way when it runs short (`layoutMenuButtonRow`); this one
    /// has its own arithmetic and it ran once, from `viewDidLoad`. The spacing between the three
    /// cells was fixed at whatever width the window had when the app opened, so dragging the
    /// window narrower left a gap too wide for the row, and a flow layout does not shrink its
    /// cells - it pushes the last one onto a line nobody can see. The settings button was the
    /// last one. Worked out again whenever the row's width changes, from the row's own width
    /// rather than the container's frame, which the storyboard's constraints overwrite.
    private var buttonRowLaidOutAt: CGFloat = 0
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        
        cell.widthConstraint.constant = 50
        
        switch indexPath.row {
        case 0:
            cell.setButton("ButtonInfo.png")
        case 1:
            cell.iconImage.image = nil
        case 2:
            cell.setButton("ButtonSettings.png")
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
            moveToItems()
        }
        if indexPath.row == 2 {
            moveToSettings()
        }
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        
        if let cell = self.iconCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
            
                switch indexPath.row {
                case 0:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                        InterfaceSound.click()
                    }
                    cell.setButton("ButtonInfoHighlighted.png")
                case 1:
                    cell.iconImage.image = nil
                case 2:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                        InterfaceSound.click()
                    }
                    cell.setButton("ButtonSettingsHighlighted.png")
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.iconCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
            
                switch indexPath.row {
                case 0:
                    cell.setButton("ButtonInfo.png")
                case 1:
                    cell.iconImage.image = nil
                case 2:
                    cell.setButton("ButtonSettings.png")
                default:
                    Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                    break
                }
            }
        }
    }
    
    func defaultSettings() {
        defaults.register(defaults: ["backgroundSetting": 0])
        defaults.register(defaults: ["soundsSetting": true])
        defaults.register(defaults: ["musicSetting": true])
        defaults.register(defaults: ["hapticsSetting": true])
        defaults.register(defaults: ["parallaxSetting": true])
        defaults.register(defaults: [PaddleSpeed.legacyKey:
                                        PaddleSpeed.legacyIndex(for: PaddleSpeed.fallback)])
        // **x2.00 on every device** (James, round 361: "Let's set the default paddle speed to
        // x2.00 on all devices"). It was x1.50 on a phone and x2.00 on an iPad, chosen by the
        // menu's width. Registered rather than written, so it is only ever a default: a player
        // who has picked a speed keeps it, and one who never has gets x2.00 from now on
        defaults.register(defaults: ["gameCenterSetting": false])
        defaults.register(defaults: ["ballSetting": 0])
        defaults.register(defaults: ["paddleSetting": 0])
        defaults.register(defaults: ["brickSetting": 0])
        defaults.register(defaults: ["appIconSetting": 0])
        defaults.register(defaults: ["statsCollapseSetting": true])
        defaults.register(defaults: ["swipeUpPause": true])
        defaults.register(defaults: ["appOpenCount": 0])
        defaults.register(defaults: ["gameInProgress": false])
        defaults.register(defaults: ["resumeGameToLoad": false])
        defaults.register(defaults: ["iCloudSetting": false])
        defaults.register(defaults: ["firstPause": true])
        // User settings
        
        // Game save settings
        
    }
    // Set default settings

    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        gameView.levelSender = sender
        gameView.levelPack = levelPack
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController
    
    // MARK: - Straight in (round 346)

    /// Starts a game of `mode` from the main menu, skipping the mode's own menu.
    ///
    /// Endless and Mayhem start their run; Classic starts the pack `Progression.quickPlayPack`
    /// picks; the Daily Challenge starts today's, through the Free Play pop-up if today's
    /// attempt is spent - the same pop-up and the same start (`DailyChallengeSession.beginRun`)
    /// its own screen uses, so the two buttons cannot disagree about what a press means.
    func playStraightIn(_ mode: GameMode) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        loadData()
        guard totalStatsArray.isEmpty == false else { return }
        let setup = LevelPackSetup.shared

        switch mode {
        case .classic:
            guard let pack = Progression.quickPlayPack(
                unlocked: totalStatsArray[0].levelPackUnlockedArray,
                bestTimes: totalStatsArray[0].packBestTimes) else { return }
            mode.makeCurrent(in: defaults)
            clearSavedGame()
            moveToGame(selectedLevel: setup.startLevelNumber[pack],
                       numberOfLevels: setup.numberOfLevels[pack],
                       sender: "MainMenu", levelPack: pack)
        case .endless, .endlessII:
            mode.makeCurrent(in: defaults)
            clearSavedGame()
            moveToGame(selectedLevel: setup.startLevelNumber[1], numberOfLevels: 1,
                       sender: "MainMenu", levelPack: 1)
        case .daily:
            playTodaysDaily()
        }
    }

    private func playTodaysDaily() {
        let session = DailyChallengeSession.shared
        let key = session.todayKey
        let challenge = DailyChallengeGenerator.challenge(forKey: key)
        let start = { [weak self] in
            guard let self, self.totalStatsArray.isEmpty == false else { return }
            let launch = session.beginRun(challenge, key: key, isToday: true,
                                          stats: self.totalStatsArray[0],
                                          defaults: self.defaults)
            self.saveStats()
            self.clearSavedGame()
            self.moveToGame(selectedLevel: launch.level, numberOfLevels: 1, sender: "MainMenu",
                            levelPack: launch.pack)
        }
        if let notice = DailyChallengePosting.practiceNotice(
            record: totalStatsArray[0].dailyRecord(forKey: key), isToday: true,
            mode: challenge.mode,
            closedOn: session.displayName(forKey: key).capitalized) {
            GigaBallAlert.show(on: self, title: "Free play", message: notice,
                               symbol: "gamecontroller.fill",
                               dismissTitle: "Cancel", confirmTitle: "Play",
                               confirm: start)
            return
        }
        start()
    }

    /// Writes the stats file, as the Daily Challenge screen's `saveData` does: the attempt a
    /// press spends has to be on disk before the run starts, and in iCloud soon after.
    private func saveStats() {
        do {
            let data = try PropertyListEncoder().encode(totalStatsArray)
            if let store = totalStatsStore { try data.write(to: store) }
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        CloudKitHandler().saveToiCloud()
    }

    func moveToPackSelector() {
        let packSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "packSelectorView") as! PackSelectViewController
        self.addChild(packSelectorView)
        fillSelf(with: packSelectorView.view)
        self.view.addSubview(packSelectorView.view)
        packSelectorView.didMove(toParent: self)
    }
    
    func moveToLevelStats(startLevel: Int, levelNumber: Int, packNumber: Int) {
        let levelStatsView = self.storyboard?.instantiateViewController(withIdentifier: "levelStatsView") as! LevelStatsViewController
        levelStatsView.startLevel = startLevel
        levelStatsView.levelNumber = levelNumber
        levelStatsView.packNumber = packNumber
        self.addChild(levelStatsView)
        fillSelf(with: levelStatsView.view)
        self.view.addSubview(levelStatsView.view)
        levelStatsView.didMove(toParent: self)
    }
    // Segue to LevelStatsViewController
    
    func moveToSettings() {
        let settingsView = self.storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
        settingsView.navigatedFrom = "MainMenu"
        self.addChild(settingsView)
        fillSelf(with: settingsView.view)
        self.view.addSubview(settingsView.view)
        settingsView.didMove(toParent: self)
    }
    // Segue to Settings
    
    func moveToItems() {
        let itemsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsView") as! ItemsViewController
        self.addChild(itemsView)
        fillSelf(with: itemsView.view)
        self.view.addSubview(itemsView.view)
        itemsView.didMove(toParent: self)
    }
    
    func moveToDailyChallenge() {
        let daily = DailyChallengeViewController()
        daily.menu = self
        self.addChild(daily)
        fillSelf(with: daily.view)
        self.view.addSubview(daily.view)
        daily.didMove(toParent: self)
        daily.showAnimate()
    }

    func moveToIntro() {
        let introView = self.storyboard?.instantiateViewController(withIdentifier: "introVC") as! IntroViewController
        introView.sender = "Main"
        self.addChild(introView)
        fillSelf(with: introView.view)
        self.view.addSubview(introView.view)
        introView.didMove(toParent: self)
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
        
        if totalStatsArray.count == 0 {
            let totalStatsItem = TotalStats()
            totalStatsArray = Array(repeating: totalStatsItem, count: 1)
            totalStatsArray[0].dateSaved = Date()
            do {
                let data = try encoder.encode(totalStatsArray)
                try data.write(to: totalStatsStore!)
            } catch {
                Log.data.error("Error setting up total stats array, \(String(describing: error), privacy: .public)")
            }
            CloudKitHandler().saveToiCloud()
        }
        // Fill the empty array with 0s on first opening and re-save
    }
    
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
        brickSetting = defaults.integer(forKey: "brickSetting")
        appIconSetting = defaults.integer(forKey: "appIconSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
        swipeUpPause = defaults.bool(forKey: "swipeUpPause")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        gameInProgress = defaults.bool(forKey: "gameInProgress")
        resumeGameToLoad = defaults.bool(forKey: "resumeGameToLoad")
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        firstPause = defaults.bool(forKey: "firstPause")
        // User settings
                
        savedGame = SavedGame.load()
        // Game save settings
    }
    
    func authGCPlayer() {
        guard GameCenterHandler.isRunningTests == false else { return }
        // **Never under the test runner** (round 306, measured rather than suspected).
        //
        // A simulator cannot sign in to Game Center, and GameKit does not say so quickly: the
        // suite's own logs show `reportAuthenticationFailedForPlayer` taking **30, 65, 81 and
        // once 207 seconds** to give up. Every batch launches the app, every launch called
        // this, and every one of those stalls was charged to the batch - which is why a suite
        // of fast tests took the best part of an hour and why batches appeared to hang after
        // their last test had already passed.
        //
        // Nothing under test loses anything: authentication fails in the simulator either way,
        // so this skips the *waiting* for a failure rather than any behaviour. The guard is a
        // runtime check, so the shipped binary carries it and never takes it - `XCTestCase`
        // does not exist in an App Store build.

        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { (view, error) in
            if view != nil {
                self.present(view!, animated: true, completion: {
                    self.updateGCAuth()
                })
            } else {
                self.updateGCAuth()
            }
        }
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
    }
    // Sets up game center
    
    func updateGCAuth() {
        if GKLocalPlayer.local.isAuthenticated {
            gameCenterSetting = true
        } else {
            gameCenterSetting = false
        }
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
        if gameCenterSetting, let stats = totalStatsArray.first {
            AchievementCatalogue.reportRenamed(earned: stats.achievementsUnlockedArray,
                                               store: defaults)
        }
        // The four Mayhem achievements whose names were corrected in round 377, sent once to a
        // player who earned them under the old names - see `owedAfterRename`
        reportYesterdaysDailyIfDue()
        // Signing in can finish after the splash has gone, and the report needs Game Center -
        // so it is asked again here, and its own guards decide whether now is the moment
    }
    // Sets up game center
    
    func refreshView() {
        CloudKitHandler().loadFromiCloud()
        loadData()
        userSettings()
        if blurViewLayer == nil {
            setBlur()
        }
        if parallaxSetting {
            addParallaxToView()
        }
        modeSelectTableView.reloadData()
        iconCollectionView.reloadData()
    }

//    func getProducts() {
//        let productID = NSSet(objects: self.iAPProductID)
//        request = SKProductsRequest(productIdentifiers: productID as! Set<String>)
//        request.delegate = self
//        request.start()
//    }
    
    @objc func returnSettingsNotificationKeyReceived(_ notification: Notification) {
        refreshView()
    }
    
    @objc func returnMenuNotificationKeyReceived(_ notification: Notification) {
        let playedDaily = DailyChallengeSession.shared.isActive
        DailyChallengeSession.shared.active = nil
        // Read before it is cleared - which mode menu to return to depends on it.
        // Back in the menus, the daily is over - whatever happens next is not it
        refreshView()
        if musicSetting {
            MusicHandler.sharedHelper.crossfadeMusic(sender: "Menu")
            // The way back is the same journey (round 210): the run's track fades down as the
            // title theme comes up, rather than the game going silent at the moment the menu
            // appears. With the music off there is nothing playing and nothing to stop
        } else {
            MusicHandler.sharedHelper.stopMusic()
        }
        returnToModeMenu(playedDaily: playedDaily,
                         packNumber: notification.userInfo?["packNumber"] as? Int ?? 0)
    }

    /// Puts the player back on the menu of the mode they just played (play-test rule:
    /// every game returns to its own mode's menu, not the main menu - and for Classic,
    /// to the played pack's own level list, James's call from the third round).
    ///
    /// Rebuilt fresh rather than resurrected: the screens the run was launched from may
    /// or may not still be children here depending on the path taken - the daily
    /// briefing removes itself on play, the mode screens do not - and a fresh present
    /// behaves the same from every path and reads the latest stats by construction.
    func returnToModeMenu(playedDaily: Bool, packNumber: Int) {
        for child in children {
            child.viewIfLoaded?.removeFromSuperview()
            child.willMove(toParent: nil)
            child.removeFromParent()
        }
        MenuNavigation.shared.forget()
        // The forward history pointed into the screens just removed

        if playedDaily {
            moveToDailyChallenge()
            arriveWithoutAnimating(children.last)
            return
        }
        switch GameMode.current(in: defaults) {
        case .classic:
            moveToPackSelector()
            arriveWithoutAnimating(children.last)
            let setup = LevelPackSetup.shared
            if packNumber >= 2, packNumber < setup.numberOfLevels.count,
               let packScreen = children.last as? PackSelectViewController {
                packScreen.hideAnimate()
                packScreen.moveToLevelSelector(
                    packNumber: packNumber,
                    numberOfLevels: setup.numberOfLevels[packNumber],
                    startLevel: setup.startLevelNumber[packNumber])
                arriveWithoutAnimating(packScreen.children.last)
            }
            // The level list of the pack just played, stacked over the pack list the
            // way navigating there stacks it - so back goes pack list, then main menu.
            // A run without a classic pack (the tutorial) stops at the pack list
        case .endless, .endlessII:
            moveToLevelStats(startLevel: LevelPackSetup.shared.startLevelNumber[1],
                             levelNumber: LevelPackSetup.shared.startLevelNumber[1],
                             packNumber: 1)
            arriveWithoutAnimating(children.last)
        case .daily:
            moveToDailyChallenge()
            arriveWithoutAnimating(children.last)
            // The scene never records .daily as current (see didSelectRowAt) - the flag
            // above is how a daily is known - but a switch with a hole in it is a bug
            // waiting for the day that changes
        }
    }

    /// Puts a just-presented screen on now, without the entry animation it started.
    ///
    /// Every menu screen fades and scales itself in over a quarter of a second, which is
    /// right when you have chosen to open it and wrong on the way back from a game: the
    /// main menu is what sits behind, so a quarter second of it showing through is the
    /// flash the play test reported (round 21). Coming back from a run is a return to where
    /// you were, not an arrival somewhere new.
    ///
    /// The animation is cancelled rather than prevented. `showAnimate` runs from the
    /// screen's own `viewDidLoad`, which has already happened by the time a caller has a
    /// reference to it - and UIKit sets the final values on the model layer as the animation
    /// is created, so removing it leaves the screen exactly where the animation was going.
    private func arriveWithoutAnimating(_ screen: UIViewController?) {
        guard let arrived = screen?.viewIfLoaded else { return }
        arrived.layer.removeAllAnimations()
        arrived.alpha = 1
        arrived.transform = .identity
    }
    
    @objc private func splashScreenEndedNotificationKeyReceived(_ notification: Notification) {
        updateGCAuth()
        DailyChallengePosting.retryPendingPosts()
        // Launch is the third of §12.5's retry moments
        refreshView()
        
        if resumeGameToLoad {
            if GameCenterHandler.isRunningTests == false {
                loadSavedGame()
            }
        } else {
            askForAReviewIfItIsTime()
            reportYesterdaysDailyIfDue()
        }
        // **The test host does not resume the simulator's saved game** (round 325). The suite
        // launches the app, and the app reads its own settings, so a save left by playing on
        // that simulator was resumed six seconds in, behind the tests, as a real game. It was
        // laid out the next time a test waited on the run loop and trapped in `loadGameData`,
        // which under tests has no stats file - the run relaunched and named an innocent test.
        // A suite that passes or crashes depending on what was last played on the simulator
        // is the round 322b leak read the other way round, so it is closed the round 306 way:
        // "am I being tested". The resume itself is driven by `ResumeTransitionTests`
        
        guard GameCenterHandler.isRunningTests == false else { return }
        // **A test run is not an app opening** (round 328, closing the note round 325c left).
        // The suite launches the app once a batch, and this line counted every one of them into
        // the player's own settings - 63 to 66 in a single session's runs. What it decides is
        // when the intro is shown and when a review is asked for, so a machine that has run the
        // suite a few hundred times is a machine that would never be asked for a review, and
        // the count is durable: it outlives the process, which is exactly what CLAUDE.md says a
        // test may not leave behind. The intro is skipped with it, because showing the
        // onboarding screen over a test run is the other half of the same mistake

        if appOpenCount == 0 {
            moveToIntro()
        }
        appOpenCount+=1
        defaults.set(appOpenCount, forKey: "appOpenCount")
        CloudKitHandler().saveToiCloud()
        // Present onboarding screen if first time opening app
    }
    // Runs when the splash screen has ended

    /// Asks for a review, if this is somebody who has played it enough and has not been
    /// asked lately.
    ///
    /// Three gates, and the reason for each:
    ///
    /// - **Ten launches and two minutes of play.** Somebody who opened it once has nothing to
    ///   review, and being asked on the way in is the fastest way to a one-star. Ten minutes
    ///   was the original bar and it is a long time in a game played in short bursts
    ///   (play-test round 21); ten separate launches is the gate that means "plays this".
    /// - **One launch in ten.** Even a qualifying player is not asked every time; the point is
    ///   to catch somebody on an ordinary day rather than to keep trying until they answer.
    /// - **Not within four months of the last ask** (play-test round 20). iOS caps this at
    ///   three prompts a year by itself and shows nothing to somebody who has already reviewed
    ///   the current version, so this is not the only guard - but the system's allowance
    ///   resets with each new version, and without a memory of our own a player who updates
    ///   regularly could be asked again within days of the last time.
    private func askForAReviewIfItIsTime() {
        guard appOpenCount > 10, totalStatsArray[0].playTimeSecs > 60*2 else { return }
        guard Int.random(in: 1...10) == 1 else { return }

        let lastAsked = defaults.double(forKey: MenuViewController.lastReviewAskKey)
        let sinceLastAsk = Date().timeIntervalSince1970 - lastAsked
        guard lastAsked == 0 || sinceLastAsk > MenuViewController.reviewAskCooldown else {
            return
        }

        guard let windowScene = view.window?.windowScene else { return }
        defaults.set(Date().timeIntervalSince1970, forKey: MenuViewController.lastReviewAskKey)
        AppStore.requestReview(in: windowScene)
        // Recorded whether or not iOS actually draws it: the app cannot tell, and an ask that
        // was swallowed is still an ask as far as not pestering is concerned
        //
        // **One path since round 301**, when the deployment target went to iOS 17 (James:
        // "go with iOS 17"). The `#available(iOS 16)` branch and its `SKStoreReviewController`
        // fallback could not be reached any more, and a dead fallback around a *review prompt*
        // is worse than dead code elsewhere: it is a deprecated StoreKit call sitting in a
        // binary that goes to App Review
    }

    private static let lastReviewAskKey = "lastReviewAsk"
    private static let reviewAskCooldown: TimeInterval = 60*60*24*120

    @objc private func foregroundNotificationKeyReceived(_ notification: Notification) {
        authGCPlayer()
        DailyChallengePosting.retryPendingPosts()
        // Foregrounding is when a connection is likeliest to have come back (§12.5)
        refreshView()
        if musicSetting {
            MusicHandler.sharedHelper.resumeMusic()
        }
    }
    // Runs when the splash screen has ended
    
    @objc private func cancelGameResumeNotificationKeyReceived(_ notification: Notification) {
        clearSavedGame()
    }
    // Runs when the splash screen has ended
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        refreshView()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
    func clearSavedGame() {
        userSettings()
        resumeGameToLoad = false
        defaults.set(resumeGameToLoad, forKey: "resumeGameToLoad")
        savedGame = nil
        SavedGame.clear()
    }
    
    func loadSavedGame() {
        guard let savedGame else { return }
        // Reached from the resume prompt, so there is always a save - but returning
        // quietly beats trapping if the prompt is ever shown without one

        DailyChallengeSession.shared.restore(from: savedGame)
        // Before the scene is built, because the twists are applied as the field is
        // generated. A save with no date key clears the session, which is what stops a
        // campaign run resuming into whatever daily was last played

        levelSender = "MainMenu"
        numberOfLevels = savedGame.endLevelNumber - savedGame.levelNumber + 1
        moveToGame(selectedLevel: savedGame.levelNumber, numberOfLevels: numberOfLevels!, sender: levelSender!, levelPack: savedGame.packNumber)
    }
    
}

extension Notification.Name {
    public static let returnMenuNotification = Notification.Name(rawValue: "returnMenuNotification")
    public static let returnSettingsNotification = Notification.Name(rawValue: "returnSettingsNotification")
    public static let splashScreenEndedNotification = Notification.Name(rawValue: "splashScreenEndedNotification")
    public static let foregroundNotification = Notification.Name(rawValue: "foregroundNotification")
    public static let backgroundNotification = Notification.Name(rawValue: "backgroundNotification")
    public static let cancelGameResume = Notification.Name(rawValue: "cancelGameResume")
    public static let refreshViewForSync = Notification.Name(rawValue: "refreshViewForSync")
    /// The game background was changed in settings, possibly over a live scene.
    public static let backgroundSettingChanged = Notification.Name(rawValue: "backgroundSettingChanged")
    public static let iAPcompleteNotification = Notification.Name(rawValue: "iAPcompleteNotification")
    public static let iAPIncompleteNotification = Notification.Name(rawValue: "iAPIncompleteNotification")
}
// Notification setup

extension MenuViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
