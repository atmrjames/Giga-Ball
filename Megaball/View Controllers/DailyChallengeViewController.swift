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

    var todayRank: Int?
    var todayRankRequested = false
    // Where today's posted score stands, once Game Center has answered - asked for at
    // most once per visit to the screen, because the answer barely moves and the ask
    // is a network round trip

    private let dayCard = UIView()
    private let cardStack = UIStackView()
    private let dateLabel = UILabel()
    private let backArrow = UIButton(type: .system)
    private let forwardArrow = UIButton(type: .system)
    private let modeLabel = UILabel()
    private let levelImageView = UIImageView()
    private let levelLabel = UILabel()
    private let twistsStack = UIStackView()
    private let resultLabel = UILabel()
    private let countdownLabel = UILabel()
    // The standing posting banner is gone (play-test round 5): the countdown line under
    // the date says Practice when it applies, and the play press itself warns when a run
    // will not post
    private let leaderboardButton = UIButton(type: .custom)
    private let testClockLabel = UILabel()
    private var developerResetButton: UIButton?
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

        // The card the day's details swipe through - a subtle container, so what animates
        // between days reads as one object rather than a page of loose labels
        dayCard.backgroundColor = UIColor(white: 1, alpha: 0.07)
        dayCard.layer.cornerRadius = 18
        dayCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dayCard)

        for label in [modeLabel, levelLabel, countdownLabel, resultLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        modeLabel.font = .boldSystemFont(ofSize: 30)
        modeLabel.textColor = .white
        levelLabel.font = .systemFont(ofSize: 17)
        levelLabel.textColor = UIColor(white: 1, alpha: 0.8)
        countdownLabel.font = .boldSystemFont(ofSize: 15)
        countdownLabel.textColor = UIColor(white: 1, alpha: 0.7)

        levelImageView.contentMode = .scaleAspectFit
        levelImageView.layer.masksToBounds = false
        levelImageView.layer.shadowOffset = .zero
        levelImageView.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1).cgColor
        levelImageView.layer.shadowOpacity = 0.5
        levelImageView.layer.shadowRadius = 6
        // A small picture of the day's level (play-test request) - the same artwork the
        // level screens use, so an unseen pack's level is genuinely a preview. Endless
        // days wear the mode's icon instead

        twistsStack.axis = .vertical
        twistsStack.spacing = 16
        twistsStack.alignment = .center

        resultLabel.textAlignment = .center
        resultLabel.numberOfLines = 0

        cardStack.axis = .vertical
        cardStack.spacing = 18
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        [modeLabel, levelImageView, levelLabel, twistsStack, resultLabel]
            .forEach { cardStack.addArrangedSubview($0) }
        dayCard.addSubview(cardStack)
        // Roomier throughout (play-test round 3 asked for the details spaced out), and the
        // countdown has left the card for its place under the date

        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countdownLabel)

        // Day browsing answers a swipe anywhere on the screen (play-test round 2), not
        // just on the card - measured the same way MenuNavigation measures its edge
        // swipes, and standing down for starts inside the edge strips, which belong to
        // back and forward
        let daySwipe = UIPanGestureRecognizer(target: self, action: #selector(daySwiped(_:)))
        daySwipe.delegate = MenuNavigation.shared
        // The shared delegate's only job is allowing simultaneous recognition, which is
        // exactly what lets this live beside the edge swipe on the same view
        view.addGestureRecognizer(daySwipe)

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

        leaderboardButton.setImage(UIImage(named: "ButtonLeaderboard"), for: .normal)
        leaderboardButton.setImage(UIImage(named: "ButtonLeaderboardHighlighted"),
                                   for: .highlighted)
        leaderboardButton.translatesAutoresizingMaskIntoConstraints = false
        leaderboardButton.addTarget(self, action: #selector(leaderboardTapped),
                                    for: .touchUpInside)
        view.addSubview(leaderboardButton)
        // The bottom row every other screen has (play-test round 2): close on the left,
        // the big play in the centre, Game Center on the right - the same artwork the
        // level screens' leaderboard button wears

        // The test clock: winds the simulated *today*, loudly labelled
        let back = UIButton(type: .system)
        back.setTitle("◀ DAY", for: .normal)
        let forward = UIButton(type: .system)
        forward.setTitle("DAY ▶", for: .normal)
        let live = UIButton(type: .system)
        live.setTitle("LIVE", for: .normal)
        for (button, action) in [(back, #selector(dayBack)), (live, #selector(dayLive)),
                                 (forward, #selector(dayForward))] {
            button.setTitleColor(#colorLiteral(red: 1.0, green: 0.85, blue: 0.20, alpha: 1), for: .normal)
            button.titleLabel?.font = .boldSystemFont(ofSize: 14)
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        testClockLabel.font = .boldSystemFont(ofSize: 12)
        testClockLabel.textColor = UIColor(white: 1, alpha: 0.85)
        testClockLabel.textAlignment = .center
        // Bright enough to read where it now sits: half-white over the lighter part of
        // the blur was invisible, which made the clock look like it had no readout

        let reset = UIButton(type: .system)
        reset.setTitle("RESET ATTEMPTS", for: .normal)
        reset.setTitleColor(#colorLiteral(red: 1.0, green: 0.85, blue: 0.20, alpha: 1), for: .normal)
        reset.titleLabel?.font = .boldSystemFont(ofSize: 14)
        reset.addTarget(self, action: #selector(resetAttempts), for: .touchUpInside)
        reset.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reset)
        // The other half of the play-test rig: wipes every daily record so the same day
        // can be played first-attempt again. Goes out with the test clock before release

        let clockRow = UIStackView(arrangedSubviews: [back, live, forward])
        clockRow.axis = .horizontal
        clockRow.distribution = .equalCentering
        clockRow.translatesAutoresizingMaskIntoConstraints = false
        testClockLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockRow)
        view.addSubview(testClockLabel)
        developerResetButton = reset

        NSLayoutConstraint.activate([
            modeIcon.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: 16),
            modeIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeIcon.widthAnchor.constraint(equalToConstant: 48),
            modeIcon.heightAnchor.constraint(equalToConstant: 48),

            title.topAnchor.constraint(equalTo: modeIcon.bottomAnchor, constant: 6),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            dayCard.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 22),
            dayCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            dayCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),

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

            cardStack.topAnchor.constraint(equalTo: dayCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: dayCard.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: dayCard.trailingAnchor,
                                                constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: dayCard.bottomAnchor, constant: -18),

            levelImageView.heightAnchor.constraint(equalToConstant: 72),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 55),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -25),
            close.widthAnchor.constraint(equalToConstant: 40),
            close.heightAnchor.constraint(equalToConstant: 40),
            // 55pt in from the edge, where the collection-view rows on the other mode
            // menus put their outer buttons (play-test round 11: these sat wider)

            play.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            play.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),

            leaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                        constant: -55),
            leaderboardButton.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            leaderboardButton.widthAnchor.constraint(equalToConstant: 40),
            leaderboardButton.heightAnchor.constraint(equalToConstant: 40),
            // 40pt like every other menu's small buttons - only the play is big

            clockRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            clockRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            testClockLabel.topAnchor.constraint(equalTo: clockRow.bottomAnchor, constant: 2),
            testClockLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reset.topAnchor.constraint(equalTo: testClockLabel.bottomAnchor, constant: 2),
            reset.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reset.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -8),
            // The developer rig stacks above the date block now (play-test round 11) -
            // it goes out with the test clock before release, so the real controls get
            // the reachable spot
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

    func showChallenge() {
        let challenge = DailyChallengeGenerator.challenge(forKey: viewedKey)

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

        modeLabel.text = challenge.mode.name.uppercased()
        if let level = challenge.classicLevel {
            let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
            let pack = DailyChallengeGenerator.pack(forClassicLevel: level)
            let setup = LevelPackSetup()
            levelImageView.image = setup.levelImageArray[number]
            levelLabel.text = "\(setup.levelNameArray[number]) - \(setup.levelPackNameArray[pack])"
                + "\nA single level - clear it for the score"
            // The level by its name, home and picture, not its number (play-test notes):
            // a number says nothing, and a glimpse of a level from a pack you have not
            // opened is the tasting menu
        } else {
            levelImageView.image = UIImage(named: "EndlessIcon.png")
            levelLabel.text = "How high can you get?"
        }

        twistsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let listed: [(NSAttributedString, String)] = challenge.twists.isEmpty
            ? [(DailyTwist.vanillaLine(font: .boldSystemFont(ofSize: 16), colour: .white),
                DailyTwist.vanillaBlurb)]
            : challenge.twists.map {
                ($0.titleLine(font: .boldSystemFont(ofSize: 16), colour: .white), $0.blurb)
            }
        // A day with no twists is Vanilla, named and badged like any other (play-test
        // round 3) - the baseline day is a kind of day, not the absence of one
        for (title, blurbText) in listed {
            let name = UILabel()
            name.attributedText = title
            name.textAlignment = .center

            let blurb = UILabel()
            blurb.text = blurbText
            blurb.font = .systemFont(ofSize: 14)
            blurb.textColor = UIColor(white: 1, alpha: 0.7)
            blurb.textAlignment = .center
            blurb.numberOfLines = 0

            let pair = UIStackView(arrangedSubviews: [name, blurb])
            pair.axis = .vertical
            pair.spacing = 3
            pair.alignment = .center
            twistsStack.addArrangedSubview(pair)
        }

        showResult(for: totalStatsArray[0].dailyRecord(forKey: viewedKey),
                   mode: challenge.mode)

        leaderboardButton.isHidden = GKLocalPlayer.local.isAuthenticated == false
        // The same rule the level screens use: no Game Center, no leaderboard button.
        // The boards themselves are App Store Connect work (James's side, §7)

        let offset = DailyChallengeSession.shared.testDayOffset
        testClockLabel.text = offset == 0
            ? "TEST CLOCK: LIVE"
            : "TEST CLOCK: \(offset > 0 ? "+" : "")\(offset) day\(abs(offset) == 1 ? "" : "s")"
        refreshCountdown()
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

    /// The day's own result, with a badge saying whether it reached the live board.
    ///
    /// Play-test request: an icon beside the score depicting whether it is posted. Three
    /// states, because there are three - posted, played but not posted (practice, or a
    /// scoring run that could not reach Game Center), and not played at all.
    func showResult(for record: DailyChallengeRecord?, mode: GameMode) {
        guard let record, record.attemptCount > 0 else {
            resultLabel.attributedText = nil
            resultLabel.isHidden = true
            return
        }
        resultLabel.isHidden = false

        let unit = mode == .classic ? "" : "m"
        let headline = record.posted
            ? "Posted: \(record.firstAttemptScore)\(unit)   "
            : "Your best: \(max(record.firstAttemptScore, record.bestPracticeScore))\(unit)   "
        // Once a score is on the board, the board's number is the day's number - a
        // practice best beside it made no sense (play-test round 5). Before then the
        // best of whatever was played is the honest summary
        let line = NSMutableAttributedString(
            string: headline,
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16),
                         .foregroundColor: UIColor.white])

        let pendingToday = record.isPending && viewedOffset == 0
        let symbol: String
        let caption: String
        let tint: UIColor
        if record.posted {
            symbol = "checkmark.seal.fill"
            if viewedOffset == 0, let rank = todayRank {
                caption = "  #\(rank) on the board"
            } else {
                caption = "  on the board"
            }
            tint = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            if viewedOffset == 0, todayRank == nil, todayRankRequested == false {
                todayRankRequested = true
                GameCenterHandler().loadDailyRank { [weak self] rank in
                    guard let self, let rank else { return }
                    self.todayRank = rank
                    self.showResult(for: record, mode: mode)
                }
                // The placing joins the badge when Game Center answers - and only
                // today's, because the recurring board resets at the deadline and a
                // past day's rank no longer exists to ask for
            }
        } else if pendingToday {
            symbol = "hourglass"
            caption = "  waiting to post"
            tint = UIColor(white: 1, alpha: 0.6)
            // Earned in the window, not yet landed (§12.5) - the retry loop is carrying
            // it, and this badge flips to the green check the moment it does
        } else {
            symbol = "clock.badge.xmark"
            caption = "  not posted"
            tint = UIColor(white: 1, alpha: 0.45)
        }

        let badge = NSTextAttachment()
        badge.image = UIImage(systemName: symbol)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        badge.bounds = CGRect(x: 0, y: -2, width: 17, height: 15)
        line.append(NSAttributedString(attachment: badge))

        line.append(NSAttributedString(
            string: caption,
            attributes: [.font: UIFont.systemFont(ofSize: 13),
                         .foregroundColor: tint]))
        resultLabel.attributedText = line
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

    @objc private func dayEarlier() { if canGoBack { step(by: -1) } }
    @objc private func dayLater() { if canGoForward { step(by: 1) } }

    /// Everything that turns with the day. The arrows are not in it - they are the rail,
    /// not the page (play-test round 2).
    private var pageViews: [UIView] { [dateLabel, countdownLabel, dayCard] }

    /// Whether this swipe is one the page should follow, decided once at `.began` and
    /// held for the gesture.
    private var daySwipeIsOurs = false

    /// The whole-screen day swipe, following the finger.
    ///
    /// A standard page swipe (play-test round 3 - the old one jumped at the end of the
    /// gesture instead of moving with the finger): the page tracks the drag, resists at
    /// the ends of the range, and on release either completes the turn or springs back.
    ///
    /// The start is worked back from the translation, because a pan only begins after the
    /// touch has travelled its slop - the same correction MenuNavigation makes.
    @objc private func daySwiped(_ gesture: UIPanGestureRecognizer) {
        let moved = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            let now = gesture.location(in: view)
            let startX = now.x - moved.x
            daySwipeIsOurs = menuNavigationIsFrontmost
                && startX > MenuNavigation.edgeWidth
                && startX < view.bounds.width - MenuNavigation.edgeWidth
            // The edge strips belong to back and forward - a day swipe starting there
            // would fire alongside the navigation swipe and do two things with one finger

        case .changed:
            guard daySwipeIsOurs, abs(moved.x) > abs(moved.y) else { return }
            let wanted = moved.x > 0 ? canGoBack : canGoForward
            let travel = wanted ? moved.x : moved.x*0.2
            // Rubber-banding at the ends of the range: today refuses to turn forward, and
            // the oldest day refuses to turn back, but the page still gives a little so
            // the refusal is something you feel rather than a dead screen
            for page in pageViews {
                page.transform = CGAffineTransform(translationX: travel, y: 0)
                page.alpha = 1 - min(0.6, abs(travel)/view.bounds.width)
            }

        case .ended, .cancelled, .failed:
            defer { daySwipeIsOurs = false }
            guard daySwipeIsOurs else { return }
            let velocity = gesture.velocity(in: view).x
            let far = abs(moved.x) > view.bounds.width*0.25 || abs(velocity) > 600
            let wanted = moved.x > 0 ? canGoBack : canGoForward

            if far, wanted, abs(moved.x) > abs(moved.y) {
                step(by: moved.x > 0 ? -1 : 1, from: moved.x)
            } else {
                settlePage()
            }

        default:
            break
        }
    }

    /// Springs the page back to where it was, for a swipe that did not go far enough.
    private func settlePage() {
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.4) {
            for page in self.pageViews {
                page.transform = .identity
                page.alpha = 1
            }
        }
    }

    /// Turns the page a day back or forward, carrying on from wherever the finger left
    /// it - older days leave to the right, newer to the left.
    ///
    /// The outgoing day leaves as a snapshot so the incoming one can enter *while* it
    /// goes (play-test round 9: the next day should appear soon after the swipe starts,
    /// not wait its turn) - and it enters from just past the edge rather than a full
    /// screen away, which is what closes the gap between days.
    private func step(by delta: Int, from offset: CGFloat = 0) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset += delta
        let width = view.bounds.width
        let exitX: CGFloat = delta < 0 ? width : -width

        var ghosts: [UIView] = []
        for page in pageViews {
            guard let ghost = page.snapshotView(afterScreenUpdates: false),
                  let holder = page.superview else { continue }
            ghost.frame = view.convert(page.frame, from: holder)
            ghost.alpha = page.alpha
            view.addSubview(ghost)
            ghosts.append(ghost)
            // The frame is read with the drag's translation still applied, so the ghost
            // carries on from wherever the finger left the real page
        }

        showChallenge()
        for page in pageViews {
            page.transform = CGAffineTransform(translationX: -exitX*0.3, y: 0)
            page.alpha = 0.2
        }
        // From barely past the edge, already faintly visible (round 10: the gap between
        // days was "still far too big" at half a screen) - the next day is adjacent, not
        // somewhere else

        let remaining = max(0.1, min(0.22, Double(abs(exitX - offset)/width)*0.22))
        // The rest of the way out takes the time the rest of the way deserves, so a page
        // flicked most of the way across does not then travel slowly

        UIView.animate(withDuration: remaining, delay: 0, options: .curveEaseOut, animations: {
            for ghost in ghosts {
                ghost.transform = CGAffineTransform(translationX: exitX - offset, y: 0)
                ghost.alpha = 0
            }
            for page in self.pageViews {
                page.transform = .identity
                page.alpha = 1
            }
        }) { _ in
            ghosts.forEach { $0.removeFromSuperview() }
        }
    }

    // MARK: - Actions

    @objc private func playTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let challenge = DailyChallengeGenerator.challenge(forKey: viewedKey)

        if let notice = DailyChallengePosting.practiceNotice(
            record: totalStatsArray[0].dailyRecord(forKey: viewedKey),
            isToday: viewedOffset == 0,
            mode: challenge.mode) {
            let alert = UIAlertController(title: "Free play", message: notice,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Play", style: .default) { [weak self] _ in
                self?.startRun(challenge)
            })
            present(alert, animated: true)
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
        step(by: -viewedOffset)
        // One page turn, however many days out - the browse was one gesture, the way
        // back is one tap
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

    @objc private func resetAttempts() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        totalStatsArray[0].dailyChallengeRecords = []
        saveData()
        showChallenge()
        // Every day playable first-attempt again. The whole record set, because a
        // half-wiped history is a state a real device can never be in and not worth
        // testing against - and the overall total is derived from these, so it goes with
        // them rather than needing its own reset
    }

    @objc private func dayBack() {
        DailyChallengeSession.shared.testDayOffset -= 1
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset = 0
        showChallenge()
        // The test clock moves today itself, so browsing starts over from the new today
    }

    @objc private func dayForward() {
        DailyChallengeSession.shared.testDayOffset += 1
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset = 0
        showChallenge()
    }

    @objc private func dayLive() {
        DailyChallengeSession.shared.testDayOffset = 0
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset = 0
        showChallenge()
    }

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
