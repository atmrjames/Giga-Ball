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

    private let dayCard = UIView()
    private let cardStack = UIStackView()
    private let dateLabel = UILabel()
    private let backArrow = UIButton(type: .system)
    private let forwardArrow = UIButton(type: .system)
    private let modeLabel = UILabel()
    private let levelImageView = UIImageView()
    private let levelLabel = UILabel()
    private let twistsStack = UIStackView()
    private let countdownLabel = UILabel()
    private let postingLabel = UILabel()
    private let leaderboardButton = UIButton(type: .custom)
    private let testClockLabel = UILabel()
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
        let title = UILabel()
        title.text = "DAILY CHALLENGE"
        title.font = UIFont(name: "HelveticaNeue-Bold", size: 40) ?? .boldSystemFont(ofSize: 40)
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

        for label in [modeLabel, levelLabel, countdownLabel, postingLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        modeLabel.font = .boldSystemFont(ofSize: 30)
        modeLabel.textColor = .white
        levelLabel.font = .systemFont(ofSize: 17)
        levelLabel.textColor = UIColor(white: 1, alpha: 0.8)
        countdownLabel.font = .boldSystemFont(ofSize: 15)
        countdownLabel.textColor = UIColor(white: 1, alpha: 0.7)
        postingLabel.font = .boldSystemFont(ofSize: 13)
        postingLabel.textColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.20, alpha: 1)
        // Its text is the posting status, set per viewed day in showChallenge()

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
        twistsStack.spacing = 10
        twistsStack.alignment = .center

        cardStack.axis = .vertical
        cardStack.spacing = 12
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        [modeLabel, levelImageView, levelLabel, twistsStack, countdownLabel]
            .forEach { cardStack.addArrangedSubview($0) }
        dayCard.addSubview(cardStack)

        // Day browsing answers a swipe anywhere on the screen (play-test round 2), not
        // just on the card - measured the same way MenuNavigation measures its edge
        // swipes, and standing down for starts inside the edge strips, which belong to
        // back and forward
        let daySwipe = UIPanGestureRecognizer(target: self, action: #selector(daySwiped(_:)))
        daySwipe.delegate = MenuNavigation.shared
        // The shared delegate's only job is allowing simultaneous recognition, which is
        // exactly what lets this live beside the edge swipe on the same view
        view.addGestureRecognizer(daySwipe)

        postingLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(postingLabel)

        let close = roundButton(system: "xmark", action: #selector(closeTapped))
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
        testClockLabel.font = .systemFont(ofSize: 12)
        testClockLabel.textColor = UIColor(white: 1, alpha: 0.5)
        testClockLabel.textAlignment = .center

        let clockRow = UIStackView(arrangedSubviews: [back, live, forward])
        clockRow.axis = .horizontal
        clockRow.distribution = .equalCentering
        clockRow.translatesAutoresizingMaskIntoConstraints = false
        testClockLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clockRow)
        view.addSubview(testClockLabel)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 34),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            dateLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 230),

            backArrow.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            backArrow.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -150),
            forwardArrow.centerYAnchor.constraint(equalTo: dateLabel.centerYAnchor),
            forwardArrow.centerXAnchor.constraint(equalTo: view.centerXAnchor,
                                                  constant: 150),

            dayCard.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12),
            dayCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
            dayCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),

            cardStack.topAnchor.constraint(equalTo: dayCard.topAnchor, constant: 18),
            cardStack.leadingAnchor.constraint(equalTo: dayCard.leadingAnchor, constant: 16),
            cardStack.trailingAnchor.constraint(equalTo: dayCard.trailingAnchor,
                                                constant: -16),
            cardStack.bottomAnchor.constraint(equalTo: dayCard.bottomAnchor, constant: -18),

            levelImageView.heightAnchor.constraint(equalToConstant: 72),

            postingLabel.topAnchor.constraint(equalTo: dayCard.bottomAnchor, constant: 16),
            postingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            postingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -34),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -20),
            close.widthAnchor.constraint(equalToConstant: 50),
            close.heightAnchor.constraint(equalToConstant: 50),

            play.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            play.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),

            leaderboardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                        constant: -44),
            leaderboardButton.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            leaderboardButton.widthAnchor.constraint(equalToConstant: 50),
            leaderboardButton.heightAnchor.constraint(equalToConstant: 50),

            clockRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            clockRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            clockRow.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -26),
            testClockLabel.topAnchor.constraint(equalTo: clockRow.bottomAnchor, constant: 2),
            testClockLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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

        dateLabel.text = DailyChallengeSession.shared.displayName(forKey: viewedKey)
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
        if challenge.twists.isEmpty {
            let pure = UILabel()
            pure.text = "No twists - a pure run."
            pure.font = .systemFont(ofSize: 16)
            pure.textColor = .white
            twistsStack.addArrangedSubview(pure)
        } else {
            for twist in challenge.twists {
                let name = UILabel()
                name.attributedText = twist.titleLine(font: .boldSystemFont(ofSize: 16),
                                                      colour: .white)
                name.textAlignment = .center

                let blurb = UILabel()
                blurb.text = twist.blurb
                blurb.font = .systemFont(ofSize: 14)
                blurb.textColor = UIColor(white: 1, alpha: 0.7)
                blurb.textAlignment = .center
                blurb.numberOfLines = 0

                let pair = UIStackView(arrangedSubviews: [name, blurb])
                pair.axis = .vertical
                pair.spacing = 2
                pair.alignment = .center
                twistsStack.addArrangedSubview(pair)
            }
        }

        leaderboardButton.isHidden = GKLocalPlayer.local.isAuthenticated == false
        // The same rule the level screens use: no Game Center, no leaderboard button.
        // The boards themselves are App Store Connect work (James's side, §7)

        postingLabel.text = DailyChallengePosting.statusLine(
            record: totalStatsArray[0].dailyRecord(forKey: viewedKey),
            isToday: viewedOffset == 0,
            mode: challenge.mode,
            gameCenterOn: GKLocalPlayer.local.isAuthenticated)
        // Whether this run posts or is practice - stated before the run starts (§6)

        let offset = DailyChallengeSession.shared.testDayOffset
        testClockLabel.text = offset == 0
            ? "TEST CLOCK: LIVE"
            : "TEST CLOCK: \(offset > 0 ? "+" : "")\(offset) day\(abs(offset) == 1 ? "" : "s")"
        refreshCountdown()
    }

    func refreshCountdown() {
        if viewedOffset == 0 {
            let session = DailyChallengeSession.shared
            let remaining = DailyDay.windowEnd(for: session.today)
                .timeIntervalSince(session.today)
            let hours = Int(remaining)/3600
            let minutes = (Int(remaining) % 3600)/60
            countdownLabel.text = "Challenge changes in \(hours)h \(minutes)m"
        } else {
            let closed = DateFormatter()
            closed.dateStyle = .medium
            closed.timeZone = TimeZone(identifier: "UTC")
            closed.locale = .autoupdatingCurrent
            countdownLabel.text = "Practice - this challenge closed "
                + closed.string(from: viewedDate)
            // A past day plays for ever and posts nothing (§8) - said before the run,
            // never discovered after
        }
    }

    // MARK: - Day browsing

    @objc private func dayEarlier() { if canGoBack { step(by: -1) } }
    @objc private func dayLater() { if canGoForward { step(by: 1) } }

    /// The whole-screen day swipe, measured the way MenuNavigation measures its edge
    /// swipes: the true start is worked back from the translation, because a pan only
    /// begins after the touch has travelled its slop.
    @objc private func daySwiped(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else { return }
        guard menuNavigationIsFrontmost else { return }
        let moved = gesture.translation(in: view)
        let now = gesture.location(in: view)
        let startX = now.x - moved.x

        guard abs(moved.x) > MenuNavigation.travel, abs(moved.x) > abs(moved.y)*2 else {
            return
        }
        guard startX > MenuNavigation.edgeWidth,
              startX < view.bounds.width - MenuNavigation.edgeWidth else { return }
        // The edge strips belong to back and forward - a day swipe starting there would
        // fire alongside the navigation swipe and do two things with one finger

        if moved.x > 0 { dayEarlier() } else { dayLater() }
        // Dragging right pulls the older day in from the left, like turning back a page
    }

    /// Moves the card and the date a day back or forward, sliding them the way the days
    /// are ordered - older days come in from the left, newer from the right. The arrows
    /// stay put (play-test round 2): they are the rail, not the page.
    private func step(by delta: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        viewedOffset += delta
        let exitX: CGFloat = delta < 0 ? 70 : -70

        UIView.animate(withDuration: 0.13, animations: {
            for page in [self.dayCard, self.dateLabel] {
                page.transform = CGAffineTransform(translationX: exitX, y: 0)
                page.alpha = 0
            }
        }) { _ in
            self.showChallenge()
            for page in [self.dayCard, self.dateLabel] {
                page.transform = CGAffineTransform(translationX: -exitX, y: 0)
            }
            UIView.animate(withDuration: 0.13) {
                for page in [self.dayCard, self.dateLabel] {
                    page.transform = .identity
                    page.alpha = 1
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func playTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let challenge = DailyChallengeGenerator.challenge(forKey: viewedKey)
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

    @objc private func closeTapped() {
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
