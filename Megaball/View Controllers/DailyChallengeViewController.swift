//
//  DailyChallengeViewController.swift
//  Megaball
//
//  The briefing screen (§6 of the daily spec): what today's challenge is, before it is
//  played. Mode, level if Classic, each twist by name with its one line, the countdown to
//  the window closing, and one play button.
//
//  Built programmatically rather than in the storyboard - it is the first screen since the
//  storyboard era, and runtime-built views have served the recent screens well.
//
//  This build is the play-test rig: scores do not post yet (phase 3), the screen says so,
//  and the test clock at the bottom steps the simulated day back and forward so a tester
//  can see many days' generations in one sitting. The clock is loud on purpose and is
//  removed before release - the spec's build phases track it.
//

import UIKit

class DailyChallengeViewController: UIViewController, MenuNavigable {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    weak var menu: MenuViewController?

    private let contentStack = UIStackView()
    private let dateLabel = UILabel()
    private let modeLabel = UILabel()
    private let levelLabel = UILabel()
    private let twistsLabel = UILabel()
    private let countdownLabel = UILabel()
    private let postingLabel = UILabel()
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

        buildLayout()
        showChallenge()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
            [weak self] _ in self?.refreshCountdown()
        }
    }

    deinit {
        countdownTimer?.invalidate()
    }

    // MARK: - Layout

    private func buildLayout() {
        let title = UILabel()
        title.text = "DAILY CHALLENGE"
        title.font = UIFont(name: "HelveticaNeue-Bold", size: 40) ?? .boldSystemFont(ofSize: 40)
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true

        for label in [dateLabel, modeLabel, levelLabel, twistsLabel, countdownLabel,
                      postingLabel] {
            label.textAlignment = .center
            label.numberOfLines = 0
        }
        dateLabel.font = .boldSystemFont(ofSize: 16)
        dateLabel.textColor = UIColor(white: 1, alpha: 0.55)
        modeLabel.font = .boldSystemFont(ofSize: 30)
        modeLabel.textColor = .white
        levelLabel.font = .systemFont(ofSize: 17)
        levelLabel.textColor = UIColor(white: 1, alpha: 0.8)
        twistsLabel.font = .systemFont(ofSize: 16)
        twistsLabel.textColor = .white
        countdownLabel.font = .boldSystemFont(ofSize: 15)
        countdownLabel.textColor = UIColor(white: 1, alpha: 0.7)
        postingLabel.font = .boldSystemFont(ofSize: 13)
        postingLabel.textColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.20, alpha: 1)
        postingLabel.text = "TEST BUILD — SCORES ARE NOT POSTED YET"

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        [title, dateLabel, modeLabel, levelLabel, twistsLabel, countdownLabel,
         postingLabel].forEach { contentStack.addArrangedSubview($0) }
        view.addSubview(contentStack)

        let close = roundButton(system: "xmark", action: #selector(closeTapped))
        let play = roundButton(system: "play.fill", action: #selector(playTapped), size: 75)
        view.addSubview(close)
        view.addSubview(play)

        // The test clock: yesterday / today / tomorrow, loudly labelled
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
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                              constant: 34),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                   constant: -34),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -20),
            close.widthAnchor.constraint(equalToConstant: 50),
            close.heightAnchor.constraint(equalToConstant: 50),

            play.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            play.centerYAnchor.constraint(equalTo: close.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),

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
        let session = DailyChallengeSession.shared
        let challenge = session.todaysChallenge

        let display = DateFormatter()
        display.dateStyle = .full
        display.timeZone = TimeZone(identifier: "UTC")
        dateLabel.text = display.string(from: session.today).uppercased()

        modeLabel.text = challenge.mode.name.uppercased()
        if let level = challenge.classicLevel {
            let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
            levelLabel.text = "Level \(number), single level - clear it for the score"
        } else {
            levelLabel.text = "How high can you get?"
        }

        if challenge.twists.isEmpty {
            twistsLabel.text = "No twists today - a pure run."
        } else {
            twistsLabel.text = challenge.twists
                .map { "★ \($0.displayName)\n\($0.blurb)" }
                .joined(separator: "\n\n")
        }

        let offset = session.testDayOffset
        testClockLabel.text = offset == 0
            ? "TEST CLOCK: LIVE"
            : "TEST CLOCK: \(offset > 0 ? "+" : "")\(offset) day\(abs(offset) == 1 ? "" : "s")"
        refreshCountdown()
    }

    func refreshCountdown() {
        let session = DailyChallengeSession.shared
        let remaining = DailyDay.windowEnd(for: session.today)
            .timeIntervalSince(session.today)
        let hours = Int(remaining)/3600
        let minutes = (Int(remaining) % 3600)/60
        countdownLabel.text = "Challenge changes in \(hours)h \(minutes)m"
    }

    // MARK: - Actions

    @objc private func playTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let challenge = DailyChallengeSession.shared.todaysChallenge
        DailyChallengeSession.shared.active = challenge

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

    @objc private func dayBack() {
        DailyChallengeSession.shared.testDayOffset -= 1
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        showChallenge()
    }

    @objc private func dayForward() {
        DailyChallengeSession.shared.testDayOffset += 1
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        showChallenge()
    }

    @objc private func dayLive() {
        DailyChallengeSession.shared.testDayOffset = 0
        if hapticsSetting { interfaceHaptic.impactOccurred() }
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
