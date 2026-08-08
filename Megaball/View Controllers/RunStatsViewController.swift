//
//  RunStatsViewController.swift
//  Megaball
//
//  The finished endless run, in detail (§12.0's game-over stats): the headline numbers
//  the game-over screen summarises, and every power-up the run met, in the order it met
//  them, each with what became of it.
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

    /// The power-ups the run met, in the order it met them - InGameRecents keeps them
    /// newest first, and a story reads from the start.
    private let seenPowerUps: [Int] = InGameRecents.shared.powerUpIndices.reversed()

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

        let numbers = UILabel()
        numbers.translatesAutoresizingMaskIntoConstraints = false
        numbers.textAlignment = .center
        numbers.numberOfLines = 0
        if let summary = InGameRecents.shared.runSummary {
            let lines = [("Paddle hits", summary.paddleHits),
                         ("Bricks destroyed", summary.bricksDestroyed),
                         ("Power-ups collected", summary.powerUpsCollected)]
            let text = NSMutableAttributedString()
            for (index, line) in lines.enumerated() {
                if index > 0 { text.append(NSAttributedString(string: "\n")) }
                text.append(NSAttributedString(
                    string: "\(line.0)  ",
                    attributes: [.font: UIFont.systemFont(ofSize: 17),
                                 .foregroundColor: UIColor(white: 1, alpha: 0.7)]))
                text.append(NSAttributedString(
                    string: "\(line.1)",
                    attributes: [.font: UIFont.boldSystemFont(ofSize: 17),
                                 .foregroundColor: UIColor.white]))
            }
            numbers.attributedText = text
        }
        view.addSubview(numbers)

        let header = UILabel()
        header.text = "POWER-UPS SEEN, IN ORDER"
        header.font = .boldSystemFont(ofSize: 13)
        header.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        header.textAlignment = .center
        header.translatesAutoresizingMaskIntoConstraints = false
        header.isHidden = seenPowerUps.isEmpty
        view.addSubview(header)

        let table = ContentAwareTableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorColor = UIColor(white: 1, alpha: 0.12)
        table.separatorInset = .zero
        table.rowHeight = 44
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

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 34),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            numbers.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
            numbers.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 34),
            numbers.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -34),

            header.topAnchor.constraint(equalTo: numbers.bottomAnchor, constant: 28),
            header.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            table.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
            table.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -20),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -20),
            close.widthAnchor.constraint(equalToConstant: 50),
            close.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        seenPowerUps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "seen")
            ?? UITableViewCell(style: .value1, reuseIdentifier: "seen")
        cell.backgroundColor = .clear
        let index = seenPowerUps[indexPath.row]
        let setup = LevelPackSetup()

        cell.textLabel?.text = setup.powerUpNameArray.indices.contains(index)
            ? setup.powerUpNameArray[index] : "?"
        cell.textLabel?.font = .boldSystemFont(ofSize: 15)
        cell.textLabel?.textColor = .white
        cell.imageView?.image = setup.powerUpImageArray.indices.contains(index)
            ? setup.powerUpImageArray[index] : nil

        cell.detailTextLabel?.text = InGameRecents.shared.statusNote(for: index)
        cell.detailTextLabel?.font = .systemFont(ofSize: 13)
        cell.detailTextLabel?.textColor = UIColor(white: 1, alpha: 0.55)
        // The same collected/missed/falling/active note the pause reference page shows
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
