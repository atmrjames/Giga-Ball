//
//  DailyChallengeViewController.swift
//  Megaball
//
//  The briefing screen (§6 of the daily spec): what a day's challenge is, before it is
//  played. Mode, the level's picture and name if Classic, each twist by name with its
//  icon and one line, the countdown to the window closing, and one play button.
//
//  Since the first play test the screen also *browses*: swipe anywhere (or the arrows
//  beside the date) to move between days - back through every daily there has been,
//  never forward past today. The date rides above the card and animates with it; the
//  arrows hold still. Today and yesterday say so in words; older days give their date.
//  A past day is playable as practice, which is §8 arriving early because the browsing
//  UI made it nearly free.
//
//  Built programmatically rather than in the storyboard - it is the first screen since the
//  storyboard era, and runtime-built views have served the recent screens well.
//
//  The test clock at the bottom steps the *simulated today* back and forward so a tester
//  can see many days' generations in one sitting - it is the play-test rig, distinct from
//  the day browsing above it, loud on purpose, and removed before release (the spec's
//  status header tracks it).
//

import UIKit
import GameKit

class DailyChallengeViewController: UIViewController, MenuNavigable {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    weak var menu: MenuViewController?

    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,
                                                   in: .userDomainMask).first?
        .appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // The same stats store every menu screen reads - here it holds the daily records
    // (§10), which are what the posting line and the play button consult

    /// Which day the card is showing, in days behind the session's today. Zero is today;
    /// the browsing is never allowed forward of it.
    var viewedOffset = 0

    let dateBlockGuide = UILayoutGuide()

    /// Whether the pager has been put on today yet - see viewDidLayoutSubviews.
    private var landedOnOpening = false

    var todayStanding: LeaderboardStanding?
    var todayRankRequested = false
    // Where today's posted score stands, once Game Center has answered - asked for at
    // most once per visit to the screen, because the answer barely moves and the ask
    // is a network round trip

    /// The days on offer, oldest first - one page each. The last is today, which is where
    /// the screen opens.
    private var dayKeys: [String] = []
    private var days: UICollectionView!

    private let dateLabel = UILabel()
    private let backArrow = UIButton(type: .system)
    private let forwardArrow = UIButton(type: .system)
    private let countdownLabel = UILabel()
    // The standing posting banner is gone (play-test round 5): the countdown line under
    // the date says Practice when it applies, and the play press itself warns when a run
    // will not post
    private let leaderboardButton = UIButton(type: .custom)
    private let signedOutLabel = UILabel()
    private var countdownTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")

        view.backgroundColor = UIColor(red: 0.1607843137, green: 0, blue: 0.2352941176,
                                       alpha: 0.25)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blur, at: 0)
        // The same dark blur every menu screen stands on

        DailyChallengePosting.retryPendingPosts()
        // One of §12.5's retry moments: opening this screen is when a player comes
        // looking for their score, which is the best time to have just carried it

        loadData()
        buildLayout()
        showChallenge()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in self?.refreshCountdown()
        }
    }

    /// The badge's two size constraints, and the height they were last measured against.
    private var modeLogoSize: [NSLayoutConstraint] = []
    private var modeLogoHeightSeen: CGFloat = 0

    /// Shrinks the mode's badge on a screen too short to wear it at full size.
    ///
    /// **James, round 339: "reduce the size of the game mode logo as needed to allow content
    /// to fit better when the window is small."** On a 320 by 568 phone this badge was 190
    /// points of a 568-point screen and the card under it was clipped to its own icon.
    private func sizeTheModeLogoForTheScreen() {
        let height = view.safeAreaLayoutGuide.layoutFrame.height
        guard height > 0, abs(height - modeLogoHeightSeen) > 0.5 else { return }
        modeLogoHeightSeen = height
        let side = UIViewController.menuModeLogoSize(forHeight: height)
        for constraint in modeLogoSize where abs(constraint.constant - side) > 0.5 {
            constraint.constant = side
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        sizeTheModeLogoForTheScreen()
        // **Before the pass, not after it.** Changing a constraint from `viewDidLayoutSubviews`
        // asks for another pass, and this screen's pager opens itself on today in the *first*
        // one - reloading its cards and jumping to the far end. Split across two passes, the
        // cards it built at the near end were still attached when the first pass ended, ten
        // thousand points to the left of the window. Sized before the pass, there is one pass.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyMenuParallaxToContent()
        limitMenuContentSize()
        // **The iPad cap reaches this screen too, as of round 319b.** James, round 314: "for
        // the iPad, can we limit how tall and wide the UI elements become. It should really
        // just look like the phone app with everything centred on the larger background."
        // Fourteen menu screens took that; this one did not, and it is the screen he opens
        // most. A 13-inch iPad drew the day's card as a band 1032 points wide with its
        // contents huddled in the middle of it, which is the phone app stretched across a
        // bigger background rather than centred on one.
        //
        // Before the guard below, not after: the cap changes the width, the width changes a
        // page, and the repaging this method already does is what reacts to that. Called
        // ahead of it so the two agree on the same pass rather than a pass apart.
        guard days.bounds.width > 0 else { return }

        if landedOnOpening == false {
            landedOnOpening = true
            pagedAt = days.bounds.size
            days.reloadData()
            scrollToViewedDay(animated: false)
            return
        }
        // The pager opens on today, which is the last page - and it can only be put there
        // once the collection view knows how wide a page is. Once, hence the flag: doing
        // it on every layout pass would drag the screen back to today mid-browse

        guard days.bounds.size != pagedAt else { return }
        pagedAt = days.bounds.size
        days.collectionViewLayout.invalidateLayout()
        days.layoutIfNeeded()
        scrollToViewedDay(animated: false)
        // **A page is the viewport, so a resized viewport is a resized page** (James, round
        // 313: on an iPad in windowed mode the day's card was cut off down its right-hand
        // edge, and in a smaller window its middle was missing altogether).
        //
        // `sizeForItemAt` already answers `collectionView.bounds.size`, which is what makes
        // paging land on whole days - but a flow layout works from the sizes it has cached,
        // and the scroll offset it is holding is a number of points, not a day. Change the
        // width underneath it and that offset stops naming the day it named: the card sits
        // part way between two pages, showing the right-hand edge of one and the left of the
        // next, which is exactly the two pictures he sent.
        //
        // Re-snapped to the day being *viewed* rather than to today, so a resize while
        // browsing an older day does not throw the browse away - which is the same thing the
        // flag above is protecting.
    }

    /// The size the pages were last laid out at.
    ///
    /// A size rather than a bool, because the question is not "has this happened" but "is what
    /// is on screen still built for the screen it is on". Compared rather than assigned every
    /// pass, because re-snapping the offset triggers another layout pass and two of those in a
    /// row is a loop.
    private var pagedAt: CGSize = .zero

    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
                    .map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        if totalStatsArray.isEmpty {
            totalStatsArray = [TotalStats()]
        }
        awardHistoryAchievements()
    }

    /// The eight achievements the daily's own history earns, checked whenever this screen
    /// reads it (round 310, from James's workbook).
    ///
    /// Here rather than at the moment a score posts, and that is deliberate: the history is
    /// merged from iCloud as well as written locally, so a player who posted their tenth day on
    /// another device earns Serial Daily Challenger on this one the first time they open the
    /// screen. A check that only ran at posting time would miss every one of those.
    ///
    /// Cheap enough to run on every load - the counts and the streak are one pass over the
    /// records, and the twists are one generator call per day played, which is arithmetic on a
    /// seed rather than anything stored.
    private func awardHistoryAchievements() {
        let earned = DailyAchievements.earned(from: totalStatsArray[0].dailyRecords,
                                              on: DailyChallengeSession.shared.todayKey)
        guard AchievementCatalogue.award(earned, in: &totalStatsArray[0]).isEmpty == false
        else { return }
        saveData()
    }

    func saveData() {
        do {
            let data = try encoder.encode(totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        CloudKitHandler().saveToiCloud()
        // The attempt flag rides to iCloud straight away (§10): first-attempt state must
        // survive a reinstall well enough to keep the honest honest
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - The days on offer

    /// The UTC date the card is showing.
    var viewedDate: Date {
        DailyDay.utcCalendar.date(byAdding: .day, value: viewedOffset,
                                  to: DailyChallengeSession.shared.today)!
    }

    var viewedKey: String { DailyDay.key(for: viewedDate) }

    /// The oldest day the card may reach: the first daily there ever was, or thirty days
    /// back, whichever is nearer. Thirty is §8's product choice - a list, not an archive.
    var earliestKey: String {
        let thirtyBack = DailyDay.utcCalendar.date(byAdding: .day, value: -29,
                                                   to: DailyChallengeSession.shared.today)!
        return max(DailyTwist.firstActivationKey, DailyDay.key(for: thirtyBack))
    }

    var canGoBack: Bool {
        let previous = DailyDay.utcCalendar.date(byAdding: .day, value: viewedOffset - 1,
                                                 to: DailyChallengeSession.shared.today)!
        return DailyDay.key(for: previous) >= earliestKey
        // Key comparison is date comparison - the keys are built to sort
    }

    var canGoForward: Bool { viewedOffset < 0 }

    // MARK: - Layout

    private func buildLayout() {
        view.addLayoutGuide(dateBlockGuide)

        let modeIcon = UIImageView(image: GameMode.menuIcon(for: .daily))
        modeIcon.contentMode = .scaleAspectFit
        modeIcon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modeIcon)
        // The mode's icon above its title (play-test round 12): icon, then title, then
        // everything else - the order every mode menu is heading for

        let title = UILabel()
        title.text = "DAILY CHALLENGE"
        title.font = .systemFont(ofSize: 35, weight: .black)
        // The same face and size the storyboard gives every other mode menu's title
        // (play-test round 9) - this screen is runtime-built, but it should not look it
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        // The date lives above the card, centred on the screen (play-test round 2: inside
        // the card's stack it sat skewed left). It animates with the swipe; the arrows
        // hold still at fixed offsets, which is why they are not in a stack with it
        dateLabel.font = .boldSystemFont(ofSize: 16)
        dateLabel.textColor = UIColor(white: 1, alpha: 0.55)
        dateLabel.textAlignment = .center
        dateLabel.adjustsFontSizeToFitWidth = true
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dateTapped)))
        // Tapping the date is the way home (play-test round 12): from any browsed day,
        // one tap turns the page back to today
        view.addSubview(dateLabel)

        for arrow in [backArrow, forwardArrow] {
            arrow.setTitleColor(.white, for: .normal)
            arrow.setTitleColor(UIColor(white: 1, alpha: 0.2), for: .disabled)
            arrow.titleLabel?.font = .boldSystemFont(ofSize: 20)
            arrow.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(arrow)
        }
        backArrow.setTitle("◀", for: .normal)
        forwardArrow.setTitle("▶", for: .normal)
        backArrow.addTarget(self, action: #selector(dayEarlier), for: .touchUpInside)
        forwardArrow.addTarget(self, action: #selector(dayLater), for: .touchUpInside)

        countdownLabel.textAlignment = .center
        countdownLabel.numberOfLines = 0
        countdownLabel.font = .boldSystemFont(ofSize: 15)
        countdownLabel.textColor = UIColor(white: 1, alpha: 0.7)

        // The days, as pages. A horizontal paging collection view with one card per day -
        // which is what makes the next day visible *during* the swipe and makes it snap,
        // and is what three rounds of animating a single card could never do (play-test
        // rounds 11-15). The same shape as the background picker's strip
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        days = UICollectionView(frame: .zero, collectionViewLayout: layout)
        days.isPagingEnabled = true
        days.showsHorizontalScrollIndicator = false
        days.backgroundColor = .clear
        days.contentInsetAdjustmentBehavior = .never
        days.dataSource = self
        days.delegate = self
        days.register(DailyCardCell.self,
                      forCellWithReuseIdentifier: DailyCardCell.reuseID)
        days.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(days)

        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countdownLabel)

        signedOutLabel.translatesAutoresizingMaskIntoConstraints = false
        signedOutLabel.textAlignment = .center
        signedOutLabel.numberOfLines = 0
        signedOutLabel.font = .systemFont(ofSize: 12)
        signedOutLabel.textColor = UIColor(white: 1, alpha: 0.38)
        signedOutLabel.text = GameCenterHandler.notSignedInNote
        signedOutLabel.isHidden = true
        view.addSubview(signedOutLabel)
        // Under the title, where a subtitle would go. The leaderboard button is already
        // missing from the bottom row for a signed-out player, and its absence explains
        // nothing (play-test round 16) - this is the screen's whole point being quietly
        // qualified, so it belongs with the heading and not in an alert

        let close = UIButton(type: .custom)
        close.setImage(UIImage(named: "ButtonClose"), for: .normal)
        close.setImage(UIImage(named: "ButtonCloseHighlighted"), for: .highlighted)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        // The same artwork and size every other menu's close wears (play-test round 10:
        // this screen's were bigger and drawn by hand)
        let play = roundButton(system: "play.fill", action: #selector(playTapped), size: 75)
        view.addSubview(close)
        view.addSubview(play)

        applyRoundGlass(to: close, radius: MainMenuCollectionViewCell.smallButtonSize/2,
                        symbol: "xmark",
                        pointSize: 20, rimmed: false)
        applyRoundGlass(to: play, radius: 37.5)
        // The same helper the menus' return-to-game play uses, at its own defaults, so this
        // screen's play is the one the rest of the app draws rather than a second attempt at
        // it. Below iOS 26 both keep exactly the buttons they had

        leaderboardButton.setImage(UIImage(named: "ButtonLeaderboard"), for: .normal)
        leaderboardButton.setImage(UIImage(named: "ButtonLeaderboardHighlighted"),
                                   for: .highlighted)
        leaderboardButton.translatesAutoresizingMaskIntoConstraints = false
        leaderboardButton.addTarget(self, action: #selector(leaderboardTapped),
                                    for: .touchUpInside)
        view.addSubview(leaderboardButton)
        applyRoundGlass(to: leaderboardButton,
                        radius: MainMenuCollectionViewCell.smallButtonSize/2,
                        symbol: "trophy.fill",
                        pointSize: 20, rimmed: false)
        // The bottom row every other screen has (play-test round 2): close on the left,
        // the big play in the centre, Game Center on the right - the same artwork the
        // level screens' leaderboard button wears

        // The developer rig is gone (play-test round 19). It was debug-gated in round 18,
        // which took it out of release builds but left it on screen in every build James
        // actually plays, so it kept being reported. The simulated day it drove lives on as
        // `DailyChallengeSession.testDayOffset`, backed by a user default - the tests set it
        // directly, and a future day can still be reached without a control on the menu.

        let content = view.safeAreaLayoutGuide
        // **Everything horizontal hangs off the safe area rather than the view's own edges.**
        // That is the half that makes `limitMenuContentSize` mean anything here: it works by
        // adding to `additionalSafeAreaInsets`, so a screen pinned to `view.leadingAnchor`
        // ignores it completely - which is why this one stayed full width while the other
        // fourteen narrowed. Nothing moves on a phone, where the portrait safe area has no
        // left or right inset to give.
        //
        // The pager included. It is still edge to edge *within* the column, so a page is
        // still a whole viewport and paging still lands on whole days; the column is simply
        // narrower than the window on an iPad.

        let modeLogoWidth = modeIcon.widthAnchor.constraint(
            equalToConstant: UIViewController.menuModeLogoSize)
        let modeLogoHeight = modeIcon.heightAnchor.constraint(
            equalToConstant: UIViewController.menuModeLogoSize)
        modeLogoSize = [modeLogoWidth, modeLogoHeight]
        // Held so the badge can shrink on a screen with no room for it - see
        // `sizeTheModeLogoForTheScreen`

        NSLayoutConstraint.activate([
            modeIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 16),
            modeIcon.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            modeLogoWidth,
            modeLogoHeight,
            // The mode logo's own size (James, round 211: "Daily Challenge should be made the
            // same"). It was 48 - a badge beside a title rather than the artwork above one -
            // and this screen is the fourth of a set of four

            title.topAnchor.constraint(equalTo: modeIcon.bottomAnchor,
                                       constant: UIViewController.menuHeaderIconGap),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -34),

            signedOutLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            signedOutLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor,
                                                    constant: 34),
            signedOutLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor,
                                                     constant: -34),

            days.topAnchor.constraint(equalTo: signedOutLabel.bottomAnchor, constant: 16),
            // Hung off the note rather than the title: hidden, the note has no height, so
            // the pager sits 22pt under the title exactly as it did before
            days.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            days.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            days.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -14),
            // Straight down to the date block now the rig has gone, so the card has the
            // room the rig used to take. Edge to edge, so a page is a whole screen and
            // paging lands on whole days; the card's own margins live on the cell

            dateLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            dateLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 230),
            dateLabel.heightAnchor.constraint(equalToConstant: 26),
            // The date row hangs from the bottom now, not from the card (play-test round
            // 11): anchored above the play row, so the controls sit in the same place on
            // every screen whatever the card holds. The fixed height is what pins the
            // arrows - the date's font changes size between today and other days, and
            // arrows centred on a label that breathes were bobbing with it

            dateBlockGuide.topAnchor.constraint(equalTo: dateLabel.topAnchor),
            dateBlockGuide.bottomAnchor.constraint(equalTo: countdownLabel.bottomAnchor),
            backArrow.centerYAnchor.constraint(equalTo: dateBlockGuide.centerYAnchor),
            forwardArrow.centerYAnchor.constraint(equalTo: dateBlockGuide.centerYAnchor),
            backArrow.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor,
                                               constant: 10),
            forwardArrow.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor,
                                                   constant: -10),
            // Centred on the date-and-countdown pair as one block (play-test round 12),
            // via a layout guide spanning both.
            //
            // **The 150 is a preference now, not a rule** (round 311). Pinned at exactly
            // ±150 from the centre, a 30pt arrow on a 320pt screen sat at -5 and 325 - five
            // points off each edge - which is what `testTheDailyBriefingFitsEveryWindow`
            // found the moment the iPad's window floor came down to the smallest phone the
            // app supports. The offset still decides where they sit on every screen wide
            // enough for it; the two inequalities above only bite below about 340

            countdownLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor,
                                                constant: 4),
            countdownLabel.bottomAnchor.constraint(equalTo: play.topAnchor, constant: -20),
            countdownLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor,
                                                    constant: 34),
            countdownLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor,
                                                     constant: -34),
            // Under the date, where the play test put it: the day, then how long is left
            // of it - and the pair stands on the play row, which is what fixes them in
            // space

            close.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 55),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -25),
            close.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            close.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            // 55pt in from the edge, where the collection-view rows on the other mode
            // menus put their outer buttons (play-test round 11: these sat wider)

            play.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            play.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),

            leaderboardButton.trailingAnchor.constraint(equalTo: content.trailingAnchor,
                                                        constant: -55),
            leaderboardButton.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            leaderboardButton.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            leaderboardButton.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            // 40pt like every other menu's small buttons - only the play is big

        ])

        for (arrow, offset) in [(backArrow, CGFloat(-150)), (forwardArrow, CGFloat(150))] {
            let preferred = arrow.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor, constant: offset)
            preferred.priority = .defaultHigh
            preferred.isActive = true
        }
        // Separated from the block above because a constraint's priority has to be set before
        // it is activated, and `NSLayoutConstraint.activate` gives no chance to
    }

    private func roundButton(system: String, action: Selector, size: CGFloat = 50) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(white: 0.92, alpha: 1)
        button.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        button.layer.cornerRadius = size/2
        button.setImage(UIImage(systemName: system,
                                withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: size*0.36, weight: .heavy)), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - The challenge on screen

    /// Rebuilds the day list and refreshes everything outside the cards.
    ///
    /// The cards themselves are the pager's business - they configure from `dayKeys` when
    /// the collection view asks. This is the furniture around them: the date, the arrows,
    /// the countdown, the leaderboard button and the test clock's readout.
    func showChallenge() {
        rebuildDayKeys()

        dateLabel.text = headerDateText
        if viewedOffset == 0 {
            dateLabel.font = .systemFont(ofSize: 20, weight: .black)
            dateLabel.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            // The app's own heading face, scaled down (play-test round 13) - TODAY is a
            // heading for the day, so it should read like one
        } else {
            dateLabel.font = .boldSystemFont(ofSize: 16)
            dateLabel.textColor = UIColor(white: 1, alpha: 0.55)
        }
        // Today wears the Giga-Ball colour and a size up (play-test round 3): of all the
        // days you can browse, one is the one that counts
        backArrow.isEnabled = canGoBack
        forwardArrow.isEnabled = canGoForward

        leaderboardButton.isHidden = GKLocalPlayer.local.isAuthenticated == false
        signedOutLabel.isHidden = GKLocalPlayer.local.isAuthenticated
        // The same rule the level screens use: no Game Center, no leaderboard button - and
        // now a line saying why, because the button's absence said nothing.
        // The boards themselves are App Store Connect work (James's side, §7)

        refreshCountdown()
        askForTodaysRank()
    }

    /// Every day the pager can reach, oldest first, ending with today.
    private func rebuildDayKeys() {
        var keys: [String] = []
        var offset = 0
        while true {
            let date = DailyDay.utcCalendar.date(byAdding: .day, value: offset,
                                                 to: DailyChallengeSession.shared.today)!
            let key = DailyDay.key(for: date)
            guard key >= earliestKey else { break }
            keys.append(key)
            offset -= 1
        }
        dayKeys = keys.reversed()
        // Oldest first so scrolling right moves forward in time, which is the direction a
        // list of dates is read in
    }

    /// Which page a day sits on, and the reverse - the pager counts up from the oldest day,
    /// the rest of the screen counts back from today.
    private var pageForViewedOffset: Int { max(0, dayKeys.count - 1 + viewedOffset) }

    private func viewedOffset(forPage page: Int) -> Int { page - (dayKeys.count - 1) }

    /// Puts the pager on a day. Without animation while the screen is being built, so the
    /// first thing shown is today rather than the oldest day scrolling past.
    func scrollToViewedDay(animated: Bool) {
        guard dayKeys.isEmpty == false, days.bounds.width > 0 else { return }

        let x = CGFloat(pageForViewedOffset)*days.bounds.width
        days.setContentOffset(CGPoint(x: x, y: 0), animated: animated)
        // **Deliberately not clamped to the content.** An offset past the last card is always
        // wrong, and a clamp here reads as the obvious guard - but the offset and the content
        // size are measured at different moments during a resize, so clamping against a stale
        // content size lands the pager between two days, which is the thing round 313 fixed.
        // The misalignment James reported in round 339 turned out to be a layout pass split in
        // two (see `viewWillLayoutSubviews`); the arithmetic here was never the fault.
    }

    /// The rank of today's posted score, asked of Game Center at most once per visit.
    private func askForTodaysRank() {
        guard viewedOffset == 0, todayStanding == nil, todayRankRequested == false,
              totalStatsArray[0].dailyRecord(forKey: viewedKey)?.posted == true
        else { return }
        todayRankRequested = true
        GameCenterHandler().loadRank(leaderboardID: DailyChallengeBoards.daily) {
            [weak self] standing in
            guard let self, let standing else { return }
            self.todayStanding = LeaderboardStanding(rank: standing.rank, players: standing.players)
            self.days.reloadData()

            let placings = DailyAchievements.earned(fromStanding: self.todayStanding!)
            if AchievementCatalogue.award(placings, in: &self.totalStatsArray[0]).isEmpty == false {
                self.saveData()
            }
            // **Top 10 Finish and Top Of The Charts, taken when the answer arrives** (round 310,
            // from James's workbook). The daily board is a *recurring* leaderboard: it resets at
            // each deadline, so a placing that is not read while the day is open cannot be asked
            // for again. Nothing is stored beyond the achievement flag itself, because there is
            // nothing to store - the rank is gone by tomorrow either way
            // The placing joins the card when Game Center answers; the recurring board
            // resets at the deadline, so only today has one to ask for
        }
    }

    /// The date the header shows for the viewed day.
    ///
    /// TODAY and YESTERDAY in words when the clock is live - but the *actual date* once
    /// the test clock is wound, because a wound clock whose header still said TODAY read
    /// as the developer buttons doing nothing (play-test rounds 4 and 5).
    var headerDateText: String {
        if DailyChallengeSession.shared.testDayOffset == 0 {
            return DailyChallengeSession.shared.displayName(forKey: viewedKey)
        }
        let stamp = DateFormatter()
        stamp.dateStyle = .full
        stamp.timeZone = TimeZone(identifier: "UTC")
        stamp.locale = .autoupdatingCurrent
        return stamp.string(from: viewedDate).uppercased()
    }

    func refreshCountdown() {
        guard viewedOffset == 0 else {
            countdownLabel.text = "Free play only"
            // A past day plays for ever and posts nothing (§8), and three words under the date
            // are the whole of it (James, round 306: "for past daily challenges under the date
            // just say Free play only. No need to say Challenge closed"). That it closed is
            // already said by the date being in the past, and the pop-up on the play press
            // says the rest to exactly the presses it applies to
            return
        }

        let session = DailyChallengeSession.shared
        let remaining = DailyDay.windowEnd(for: session.today).timeIntervalSince(session.today)
        let hours = Int(remaining)/3600
        let minutes = (Int(remaining) % 3600)/60

        let spent = (totalStatsArray[0].dailyRecord(forKey: viewedKey)?.attemptCount ?? 0) > 0
        countdownLabel.text = spent
            ? "Next challenge in \(hours)h \(minutes)m"
            : "Closes in \(hours)h \(minutes)m"
        // **Once the attempt is spent the deadline stops being a deadline** (James, round 306:
        // "once a player has completed a paint challenge, the note on the daily challenge menu
        // view under the date should say 'Next challenge in ...time' to let them know how long
        // until the next daily challenge is available").
        //
        // The same instant either way - the window's end is both when this one closes and when
        // the next one opens - so it is the *wording* that changes rather than the arithmetic.
        // A player with nothing left to post is being told when they can come back, not being
        // hurried
    }

    // MARK: - Day browsing

    /// The arrows and the date-tap drive the pager rather than the day directly, so every
    /// way of changing day - swipe, arrow, tap - ends in the same place: a scroll, whose
    /// landing is what sets `viewedOffset`.
    @objc private func dayEarlier() { if canGoBack { turn(to: viewedOffset - 1) } }
    @objc private func dayLater() { if canGoForward { turn(to: viewedOffset + 1) } }

    private func turn(to offset: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        viewedOffset = offset
        scrollToViewedDay(animated: true)
        showChallenge()
    }

    // MARK: - Actions

    @objc private func playTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        let challenge = DailyChallengeGenerator.challenge(forKey: viewedKey)

        if let notice = DailyChallengePosting.practiceNotice(
            record: totalStatsArray[0].dailyRecord(forKey: viewedKey),
            isToday: viewedOffset == 0,
            mode: challenge.mode,
            closedOn: DailyChallengeSession.shared.displayName(forKey: viewedKey).capitalized) {
            // **In the pop-up's own case** (James, round 312: "on the free play daily challenge
            // pop up warning, show the date format in a case that matches the rest of the
            // pop up's text"). `displayName` is the *header's* format and is upper case on
            // purpose - TODAY, YESTERDAY, SUNDAY, 30 AUGUST 2026 - which reads as shouting
            // inside a sentence. The resume card already capitalises it for the same reason
            GigaBallAlert.show(on: self, title: "Free play", message: notice,
                               symbol: "gamecontroller.fill",
                                dismissTitle: "Cancel", confirmTitle: "Play",
                                confirm: { [weak self] in self?.startRun(challenge) })
            // The promise is still made before the run starts (§6) - but as a pop-up on
            // exactly the presses it applies to, instead of a banner shouting at all of
            // them (play-test round 5). A scoring attempt goes straight through
            return
        }
        startRun(challenge)
    }

    private func startRun(_ challenge: DailyChallenge) {
        let launch = DailyChallengeSession.shared.beginRun(
            challenge, key: viewedKey, isToday: viewedOffset == 0,
            stats: totalStatsArray[0], defaults: defaults)
        saveData()
        MenuViewController().clearSavedGame()
        menu?.moveToGame(selectedLevel: launch.level, numberOfLevels: 1, sender: "MainMenu",
                         levelPack: launch.pack)
        removeAnimate()
    }

    @objc private func dateTapped() {
        guard viewedOffset != 0 else { return }
        turn(to: 0)
        // Straight back to today however many days out - the browse was one gesture, the
        // way back is one tap
    }

    @objc private func closeTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        // The tick every other close gives (play-test round 10: this one was silent)
        menuNavigationGoBack()
    }

    @objc private func leaderboardTapped() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        let boards = GKGameCenterViewController(leaderboardID: DailyChallengeBoards.daily,
                                                playerScope: .global, timeScope: .allTime)
        boards.gameCenterDelegate = self
        view.window?.rootViewController?.present(boards, animated: true)
    }

    // The test rig's four handlers - RESET ATTEMPTS, and the day stepper's back, forward and
    // live - were removed with the controls that called them (round 19). They had sat here
    // wired to nothing since, which reads to anyone opening this file as though the rig is
    // still on the screen. `DailyChallengeSession.testDayOffset` is what survives, and it is
    // set by the tests directly rather than by anything a player can reach.

    // MARK: - Menu plumbing

    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        removeAnimate()
    }

    func showAnimate() {
        view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }

    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0
        }) { finished in
            if finished {
                self.view.removeFromSuperview()
            }
        }
    }
}

extension DailyChallengeViewController: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
    }
}

// MARK: - The days, as pages

extension DailyChallengeViewController: UICollectionViewDataSource,
                                        UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        dayKeys.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DailyCardCell.reuseID, for: indexPath) as! DailyCardCell
        let key = dayKeys[indexPath.item]
        let isToday = key == DailyChallengeSession.shared.todayKey
        cell.card.show(key: key, isToday: isToday,
                       record: totalStatsArray[0].dailyRecord(forKey: key),
                       standing: isToday ? todayStanding : nil)
        cell.card.twistTapped = { [weak self] twist in self?.explain(twist) }
        cell.card.twistsExplainerTapped = { [weak self] in self?.explainTheDaysTwists(on: key) }
        // The card lists the day's twists by icon and name only since round 308, so the block
        // answers a tap with the same pop-up the pause menu shows
        cell.card.postedScoreTapped = { [weak self] in self?.leaderboardTapped() }
        // The posted score is the board's own figure, so the row showing it opens the board
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.bounds.size
        // A page is the whole viewport, which is what makes paging land on whole days
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) { dayDidLand() }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) { dayDidLand() }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false { dayDidLand() }
    }

    /// The pager has settled on a day: that day becomes the viewed one, and everything
    /// outside the cards catches up.
    ///
    /// The scroll position is the source of truth now, rather than something kept in step
    /// with `viewedOffset` - which is what stops the two disagreeing after a fast swipe.
    private func dayDidLand() {
        guard days.bounds.width > 0 else { return }
        let page = Int((days.contentOffset.x/days.bounds.width).rounded())
        let landed = viewedOffset(forPage: max(0, min(dayKeys.count - 1, page)))
        guard landed != viewedOffset else { return }
        viewedOffset = landed
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        showChallenge()
    }

    /// What a twist does, when its name is tapped (play-test round 15). The same words the
    /// card already shows, in a pop-up - so a twist met mid-run can be looked up rather
    /// than remembered.
    func explain(_ twist: DailyTwist) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        GigaBallAlert.show(on: self, title: twist.displayName, message: twist.blurb,
                           symbol: "dice.fill")
    }

    /// Every twist the shown day has, badged and blurbed - the pause menu's pop-up, here.
    ///
    /// Asked of the *browsed* day rather than the active session, because this screen pages
    /// through a fortnight and the day on screen is usually not one being played.
    func explainTheDaysTwists(on key: String) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        let challenge = DailyChallengeGenerator.challenge(forKey: key)
        GigaBallAlert.show(on: self, title: "Today's Twists",
                           attributed: DailyTwist.explainer(for: challenge.twists),
                           symbol: "dice.fill")
    }
}

extension DailyChallengeSession {

    /// Starts a daily run: makes it the active challenge, decides whether it is the scoring
    /// attempt, spends the day's attempt in `stats`, and records the mode it is played in.
    /// Returns the level and pack to launch. The caller saves `stats` and starts the game.
    ///
    /// **One start for the daily, wherever it is pressed** (round 346): the Daily Challenge
    /// screen's play button and the main menu's both come through here. The bookkeeping is the
    /// part that must not differ - which run posts, and that a press spends the attempt - so it
    /// lives in one place rather than in each button.
    func beginRun(_ challenge: DailyChallenge, key: String, isToday: Bool, stats: TotalStats,
                  defaults: UserDefaults) -> (level: Int, pack: Int) {
        active = challenge

        var record = stats.dailyRecord(forKey: key) ?? DailyChallengeRecord(dateKey: key)
        isScoringAttempt = isToday && record.attemptCount == 0
        forfeitedByLeaving = false
        // A forfeit belongs to the run that earned it. Cleared as a run starts as well as as
        // one ends, because the session outlives both and a stale one would quietly unpost a
        // run that never left the app
        record.attemptCount += 1
        stats.upsertDailyRecord(record)
        // The press is what spends the attempt (§7): the record exists from this moment, so a
        // force-quit mid-run still finds the day spent - and every later press is practice

        challenge.mode.makeCurrent(in: defaults)
        // A daily is always a fresh run; the caller clears any campaign save, so it never
        // resumes into a twisted game or the other way round

        if let level = challenge.classicLevel {
            return (DailyChallengeGenerator.levelNumber(forClassicLevel: level),
                    DailyChallengeGenerator.pack(forClassicLevel: level))
        }
        return (0, 1)
    }

    /// Whether today's challenge is still unplayed on this device - the main menu's red dot
    /// (James, round 346).
    func todayIsUnplayed(in stats: TotalStats) -> Bool {
        (stats.dailyRecord(forKey: todayKey)?.attemptCount ?? 0) == 0
    }
}
