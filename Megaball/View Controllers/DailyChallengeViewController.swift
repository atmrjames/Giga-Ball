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

    var todayStanding: DailyStanding?
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard days.bounds.width > 0, landedOnOpening == false else { return }
        landedOnOpening = true
        days.reloadData()
        scrollToViewedDay(animated: false)
        // The pager opens on today, which is the last page - and it can only be put there
        // once the collection view knows how wide a page is. Once, hence the flag: doing
        // it on every layout pass would drag the screen back to today mid-browse
    }

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

        NSLayoutConstraint.activate([
            modeIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 16),
            modeIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeIcon.widthAnchor.constraint(equalToConstant: 48),
            modeIcon.heightAnchor.constraint(equalToConstant: 48),

            title.topAnchor.constraint(equalTo: modeIcon.bottomAnchor, constant: 6),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            signedOutLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            signedOutLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: 34),
            signedOutLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -34),

            days.topAnchor.constraint(equalTo: signedOutLabel.bottomAnchor, constant: 16),
            // Hung off the note rather than the title: hidden, the note has no height, so
            // the pager sits 22pt under the title exactly as it did before
            days.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            days.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            days.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -14),
            // Straight down to the date block now the rig has gone, so the card has the
            // room the rig used to take. Edge to edge, so a page is a whole screen and
            // paging lands on whole days; the card's own margins live on the cell

            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
            backArrow.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -150),
            forwardArrow.centerYAnchor.constraint(equalTo: dateBlockGuide.centerYAnchor),
            forwardArrow.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                  constant: 150),
            // Centred on the date-and-countdown pair as one block (play-test round 12),
            // via a layout guide spanning both

            countdownLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor,
                                                constant: 4),
            countdownLabel.bottomAnchor.constraint(equalTo: play.topAnchor, constant: -20),
            countdownLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: 34),
            countdownLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -34),
            // Under the date, where the play test put it: the day, then how long is left
            // of it - and the pair stands on the play row, which is what fixes them in
            // space

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 55),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -25),
            close.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            close.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            // 55pt in from the edge, where the collection-view rows on the other mode
            // menus put their outer buttons (play-test round 11: these sat wider)

            play.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            play.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),

            leaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                        constant: -55),
            leaderboardButton.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            leaderboardButton.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            leaderboardButton.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            // 40pt like every other menu's small buttons - only the play is big

        ])
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
    }

    /// The rank of today's posted score, asked of Game Center at most once per visit.
    private func askForTodaysRank() {
        guard viewedOffset == 0, todayStanding == nil, todayRankRequested == false,
              totalStatsArray[0].dailyRecord(forKey: viewedKey)?.posted == true
        else { return }
        todayRankRequested = true
        GameCenterHandler().loadDailyStanding { [weak self] standing in
            guard let self, let standing else { return }
            self.todayStanding = DailyStanding(rank: standing.rank, players: standing.players)
            self.days.reloadData()
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
        if viewedOffset == 0 {
            let session = DailyChallengeSession.shared
            let remaining = DailyDay.windowEnd(for: session.today)
                .timeIntervalSince(session.today)
            let hours = Int(remaining)/3600
            let minutes = (Int(remaining) % 3600)/60
            countdownLabel.text = "Closes in \(hours)h \(minutes)m"
        } else {
            countdownLabel.text = "Challenge closed, free play only"
            // A past day plays for ever and posts nothing (§8). One word under the date
            // is the whole of it now - the standing yellow banner it used to share the
            // screen with is gone (play-test round 5), and the pop-up on the play press
            // says the rest to exactly the presses it applies to
        }
    }

    // MARK: - Day browsing

    /// The arrows and the date-tap drive the pager rather than the day directly, so every
    /// way of changing day - swipe, arrow, tap - ends in the same place: a scroll, whose
    /// landing is what sets `viewedOffset`.
    @objc private func dayEarlier() { if canGoBack { turn(to: viewedOffset - 1) } }
    @objc private func dayLater() { if canGoForward { turn(to: viewedOffset + 1) } }

    private func turn(to offset: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset = offset
        scrollToViewedDay(animated: true)
        showChallenge()
    }

    // MARK: - Actions

    @objc private func playTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let challenge = DailyChallengeGenerator.challenge(forKey: viewedKey)

        if let notice = DailyChallengePosting.practiceNotice(
            record: totalStatsArray[0].dailyRecord(forKey: viewedKey),
            isToday: viewedOffset == 0,
            mode: challenge.mode) {
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
        DailyChallengeSession.shared.active = challenge

        var record = totalStatsArray[0].dailyRecord(forKey: viewedKey)
            ?? DailyChallengeRecord(dateKey: viewedKey)
        DailyChallengeSession.shared.isScoringAttempt =
            viewedOffset == 0 && record.attemptCount == 0
        record.attemptCount += 1
        totalStatsArray[0].upsertDailyRecord(record)
        saveData()
        // The press is what spends the attempt (§7): the record exists from this moment,
        // so a force-quit mid-run still finds the day spent - and every later press of
        // this button is practice, which the label above already said

        let underlying = challenge.mode
        underlying.makeCurrent(in: defaults)
        MenuViewController().clearSavedGame()
        // A daily is always a fresh run - it must never resume a campaign save into a
        // twisted game, or vice versa

        if let level = challenge.classicLevel {
            menu?.moveToGame(selectedLevel:
                                DailyChallengeGenerator.levelNumber(forClassicLevel: level),
                             numberOfLevels: 1, sender: "MainMenu",
                             levelPack: DailyChallengeGenerator.pack(forClassicLevel: level))
        } else {
            menu?.moveToGame(selectedLevel: 0, numberOfLevels: 1, sender: "MainMenu",
                             levelPack: 1)
        }
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
        // The tick every other close gives (play-test round 10: this one was silent)
        menuNavigationGoBack()
    }

    @objc private func leaderboardTapped() {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        if hapticsSetting { interfaceHaptic.impactOccurred() }
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
        showChallenge()
    }

    /// What a twist does, when its name is tapped (play-test round 15). The same words the
    /// card already shows, in a pop-up - so a twist met mid-run can be looked up rather
    /// than remembered.
    func explain(_ twist: DailyTwist) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        GigaBallAlert.show(on: self, title: twist.displayName, message: twist.blurb,
                           symbol: "dice.fill")
    }
}
