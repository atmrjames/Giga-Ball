//
//  RunStatsViewController.swift
//  Megaball
//
//  The finished endless run, in detail (§12.0's game-over stats): the headline numbers
//  the game-over screen summarises, and the run's power-up superlatives - most seen,
//  most collected, most missed (play-test round 9: the highlights, not the diary).
//
//  Runtime-built like the daily briefing, and deliberately small: it reads what
//  InGameRecents recorded and the scene snapshotted - the screen computes nothing, so
//  there is nothing here to disagree with the run.
//

import UIKit

class RunStatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)

    /// The run's power-up highlights - the superlatives, not the whole diary (play-test
    /// round 9: the full in-order list did not justify the screen).
    private let highlights = InGameRecents.shared.superlatives

    /// The run's facts, in the stats page's own row shape: a symbol, a label, a value.
    private var factRows: [(icon: String, label: String, value: String)] = []
    private let facts = UITableView(frame: .zero, style: .plain)
    private var factsHeight: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")

        view.backgroundColor = UIColor(red: 0.1607843137, green: 0, blue: 0.2352941176,
                                       alpha: 0.25)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blur, at: 0)
        // The same dark blur every menu screen stands on

        buildLayout()
    }

    private func buildLayout() {
        let title = UILabel()
        title.text = "RUN STATS"
        title.font = UIFont(name: "HelveticaNeue-Bold", size: 40) ?? .boldSystemFont(ofSize: 40)
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        title.adjustsFontSizeToFitWidth = true
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        if let summary = InGameRecents.shared.runSummary {
            let minutes = summary.durationSeconds/60
            let seconds = summary.durationSeconds % 60
            let caught = summary.powerUpsSeen > 0
                ? Int((Double(summary.powerUpsCollected)/Double(summary.powerUpsSeen)*100)
                    .rounded())
                : 0
            let bricksPerMetre = summary.height > 0
                ? String(format: "%.1f", Double(summary.bricksDestroyed)/Double(summary.height))
                : "-"
            // Derived figures the game-over line has no room for - the detail screen is
            // where a run's texture lives (play-test round 8 asked it to earn its keep)

            // The headline is whatever the run was measured in. An endless run has a height
            // and metres to divide by; a classic one has a score and a count of levels, and
            // was being shown "0m" and a dash where its own result should have been
            // (play-test round 13)
            let headline: [(String, String, String)] = summary.isEndless
                ? [("arrow.up", "Height", "\(summary.height)m")]
                : [("star.fill", "Score", String(summary.score)),
                   ("flag.fill", "Levels cleared", "\(summary.levelsCleared)")]

            let lines: [(String, String, String)] = headline + [
                ("clock", "Time", String(format: "%d:%02d", minutes, seconds)),
                ("rectangle.fill", "Paddle hits", "\(summary.paddleHits)"),
                ("square.grid.3x2.fill", "Bricks destroyed", "\(summary.bricksDestroyed)"),
            ] + (summary.isEndless
                 ? [("ruler", "Bricks per metre", bricksPerMetre)] : []) + [
                ("circle.slash", "Balls lost", "\(summary.ballsLost)"),
                ("trophy", "Most hits on a single ball", "\(summary.bestBallHits)"),
                ("arrow.down.circle.fill", "Power-ups seen", "\(summary.powerUpsSeen)"),
                ("checkmark.circle.fill", "Power-ups collected",
                 "\(summary.powerUpsCollected) (\(caught)%)"),
            ]
            factRows = lines.map { (icon: $0.0, label: $0.1, value: $0.2) }
            // The same facts, now as rows for the table below rather than as one centred
            // block of text (play-test round 85: "the game-over More Stats view should use
            // the stats page's table style")
        }

        facts.translatesAutoresizingMaskIntoConstraints = false
        facts.backgroundColor = .clear
        facts.separatorStyle = .none
        facts.rowHeight = 42
        facts.isScrollEnabled = false
        facts.dataSource = self
        facts.delegate = self
        facts.allowsSelection = false
        facts.register(UINib(nibName: "StatsTableViewCell", bundle: nil),
                       forCellReuseIdentifier: "customStatCell")
        view.addSubview(facts)
        SettingsTableViewCell.addGlass(under: facts, cornerRadius: 14, inset: 20)
        // One panel with hairlines inside it, which is what the statistics page settled on
        // in round 70 - a card per row read as "too many edges" there and would here too.
        // Never scrolls: the list is a fixed dozen facts and the screen is sized for them.
        //
        // The numbers are the statistics page's own, not numbers that look similar: its table
        // spans its container edge to edge with the panel inset 20 *inside* that, so the panel
        // lands 20-odd points from the screen edge and every row's icon and label start where
        // the other page's do. Round 117 built this table two points narrower on each side and
        // its panel flush to it, and the two screens did not line up (James, round 121)

        let header = UILabel()
        header.text = "POWER-UP HIGHLIGHTS"
        header.font = .boldSystemFont(ofSize: 13)
        header.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        header.isHidden = highlights.isEmpty
        view.addSubview(header)

        let table = ContentAwareTableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorColor = UIColor(white: 1, alpha: 0.12)
        table.separatorInset = .zero
        table.rowHeight = 56
        // Roomier rows (play-test round 10: the icons were crowding each other)
        table.dataSource = self
        table.delegate = self
        table.allowsSelection = false
        view.addSubview(table)

        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.backgroundColor = UIColor(white: 0.92, alpha: 1)
        close.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        close.layer.cornerRadius = 25
        close.setImage(UIImage(systemName: "xmark",
                               withConfiguration: UIImage.SymbolConfiguration(
                                   pointSize: 18, weight: .heavy)), for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        applyRoundGlass(to: close,
                        radius: MainMenuCollectionViewCell.smallButtonSize/2,
                        symbol: "xmark", pointSize: 20, rimmed: false)
        // The one close button in the app that was still a pale disc - this screen builds its
        // own rather than taking the shared button row, so the round-66 sweep never reached
        // it (play-test round 94)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 34),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            facts.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
            facts.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            facts.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),

            header.topAnchor.constraint(equalTo: facts.bottomAnchor, constant: 28),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            table.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            table.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -20),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -20),
            close.widthAnchor.constraint(equalToConstant: 50),
            close.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let wanted = facts.contentSize.height
        if let factsHeight {
            if abs(factsHeight.constant - wanted) > 0.5 { factsHeight.constant = wanted }
        } else if wanted > 0 {
            let height = facts.heightAnchor.constraint(equalToConstant: wanted)
            height.isActive = true
            factsHeight = height
        }
        SettingsTableViewCell.fitGlassPanel(under: facts)
        // The table is exactly as tall as its rows - it is a fixed list, so it sizes to the
        // content rather than the page (play-test round 85 asked for that on every detail
        // table). The panel behind it is measured after, or it fits last layout's height
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView == facts ? factRows.count : highlights.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == facts {
            let cell = tableView.dequeueReusableCell(withIdentifier: "customStatCell",
                                                     for: indexPath) as! StatsTableViewCell
            let row = factRows[indexPath.row]
            cell.statDescription.text = row.label
            cell.statValue.text = row.value
            cell.showIcon(row.icon)
            cell.showDivider(indexPath.row < factRows.count - 1)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "highlight")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "highlight")
        cell.backgroundColor = .clear
        let highlight = highlights[indexPath.row]
        let setup = LevelPackSetup()

        cell.textLabel?.text = setup.powerUpNameArray.indices.contains(highlight.index)
            ? "\(highlight.title): \(setup.powerUpNameArray[highlight.index])" : highlight.title
        cell.textLabel?.font = .boldSystemFont(ofSize: 15)
        cell.textLabel?.textColor = .white
        if setup.powerUpImageArray.indices.contains(highlight.index) {
            let icon = setup.powerUpImageArray[highlight.index]
            let size = CGSize(width: 34, height: 34)
            cell.imageView?.image = UIGraphicsImageRenderer(size: size).image { _ in
                icon.draw(in: CGRect(origin: .zero, size: size))
            }
            // Drawn down to a fixed 34pt: the raw icon fills the whole row and the rows
            // read as touching (play-test round 10 asked for air between them)
        } else {
            cell.imageView?.image = nil
        }

        cell.detailTextLabel?.text = "×\(highlight.count)"
        cell.detailTextLabel?.font = .boldSystemFont(ofSize: 15)
        cell.detailTextLabel?.textColor = UIColor(white: 1, alpha: 0.7)
        return cell
    }

    @objc private func closeTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        removeAnimate()
        NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
        // The game-over screen underneath comes back the way it does from settings
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
