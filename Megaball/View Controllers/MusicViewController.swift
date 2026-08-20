//
//  MusicViewController.swift
//  Megaball
//
//  James, round 207: "Arrow icon on music setting cell - opens a new page with another table
//  view. Each cell in the view is one of the tracks in the game. Users can preview the tracks
//  here, or untick one or all of them to play whilst playing the game. If the user unselects
//  all of them, the music setting is set to off. If the music setting is set to on, all tracks
//  are selected by default."
//

import UIKit
import AVFoundation

/// The music screen: which tracks a run may play, and what each one sounds like.
///
/// **Built in code rather than as a storyboard scene.** `Main.storyboard` is hand-edited here
/// (there is no file-system-synchronised group), and a new scene means a new set of outlets,
/// constraints and size-class variations written by hand into XML - which is exactly where the
/// iPad pause screen's 414pt box came from. `PaddleSpeedViewController` is the precedent: a
/// menu screen that is its own layout, opened the same way as every other.
final class MusicViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                 MenuNavigable {

    let defaults = UserDefaults.standard
    private var hapticsSetting = true
    private let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)

    /// Told when the rotation changes, so the settings row behind this screen redraws - the
    /// row's "on"/"off" is the same state these ticks are, seen from further away.
    var onChange: (() -> Void)?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private weak var closeButton: UIButton?

    /// The track being previewed, if any.
    ///
    /// Its own player rather than `MusicHandler`'s: the menu theme is still playing behind
    /// this screen and has to come back untouched when the preview stops. Borrowing the
    /// shared player would mean rebuilding the menu's music on the way out, and getting that
    /// wrong is silence on a screen the player has just left.
    private var previewPlayer: AVAudioPlayer?
    private var previewing: MusicTrack?

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let closeButton { alignCloseButtonWithReturnToGame(closeButton) }
        // In to the narrow position when the pause screen's play button is on screen behind
        // this one (round 176) - Settings is reached from the pause menu as well as the main
        limitMenuContentSize()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPreview()
    }

    private func buildLayout() {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "M U S I C"
        title.font = .boldSystemFont(ofSize: 28)
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        view.addSubview(title)

        let hint = UILabel()
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.text = "Tap a track to hear it. Tick the ones to play during a game."
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = UIColor(white: 1, alpha: 0.55)
        hint.numberOfLines = 0
        hint.textAlignment = .center
        view.addSubview(hint)
        // Two jobs on one row needs saying once: the tap previews, the tick chooses. Without
        // it a tick looks like the only thing a row does and the preview is never found

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "settingsCell")
        // The settings screen's own cell, so a row here is the same object as a row there -
        // it already carries the icon, the label, the state text and the tick
        view.addSubview(tableView)

        let close = UIButton(type: .system)
        closeButton = close
        close.translatesAutoresizingMaskIntoConstraints = false
        close.backgroundColor = UIColor(white: 0.92, alpha: 1)
        close.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        close.layer.cornerRadius = MainMenuCollectionViewCell.smallButtonSize/2
        close.setImage(UIImage(systemName: "xmark",
                               withConfiguration: UIImage.SymbolConfiguration(
                                pointSize: 18, weight: .heavy)), for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        applyRoundGlass(to: close, radius: MainMenuCollectionViewCell.smallButtonSize/2,
                        symbol: "xmark", pointSize: 18, rimmed: false)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 24),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            hint.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            tableView.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tableView.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -20),

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                           constant: UIViewController.menuButtonWideInset),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -25),
            close.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            close.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
        ])
    }

    // MARK: - The list

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MusicTrack.allCases.count
        // Read off the type, not counted out here - a track added to the game appears on this
        // screen without anybody remembering to come and change a number
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell",
                                                 for: indexPath) as! SettingsTableViewCell
        let track = MusicTrack.allCases[indexPath.row]

        cell.settingDescription.text = track.name
        cell.centreLabel.text = ""
        cell.setIcon(UIImage(named: previewing == track ? "iconMusic" : "iconMusicOff")!,
                     recolour: true)
        // The icon is the preview's own state: which row is making the noise right now

        if track.isChoosable {
            let on = MusicSelection.isEnabled(track)
            cell.settingState.text = on ? "on" : "off"
            cell.setStateColour(on ? #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                                   : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
        } else {
            cell.settingState.text = "menu"
            cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            // The Title Theme is listed because a player looking for the tune from the menu
            // should find it where the music lives - but it is the menu's, not a run's, so it
            // says what it is instead of offering a tick that would silence the main menu
        }
        cell.accessoryView = track.isChoosable ? tickButton(for: indexPath.row) : nil
        // The tick is its own control, so the row has two answers that cannot be confused:
        // anywhere on the row previews, the tick chooses. A single tap doing both would mean
        // a player auditioning the tracks silently rewrites what a run plays
        return cell
    }

    /// The tick beside a row, drawn from whether that track is in the rotation.
    private func tickButton(for row: Int) -> UIButton {
        let track = MusicTrack.allCases[row]
        let on = MusicSelection.isEnabled(track)
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: on ? "checkmark.circle.fill" : "circle",
                                withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 22, weight: .semibold)), for: .normal)
        button.tintColor = on ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
                              : UIColor(white: 1, alpha: 0.4)
        button.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        button.tag = row
        button.addTarget(self, action: #selector(tickTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func tickTapped(_ sender: UIButton) {
        guard MusicTrack.allCases.indices.contains(sender.tag) else { return }
        toggle(MusicTrack.allCases[sender.tag])
    }

    /// A tap plays the track. The tick is the accessory beside it.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let track = MusicTrack.allCases[indexPath.row]
        if previewing == track { stopPreview() } else { startPreview(track) }
        tableView.reloadData()
    }

    // MARK: - Choosing

    private func toggle(_ track: MusicTrack) {
        guard track.isChoosable else { return }
        if hapticsSetting { interfaceHaptic.impactOccurred() }

        let anyLeft = MusicSelection.set(track, enabled: !MusicSelection.isEnabled(track))

        if anyLeft {
            if defaults.bool(forKey: "musicSetting") == false {
                defaults.set(true, forKey: "musicSetting")
                MusicHandler.sharedHelper.playMusic(sender: "Menu")
            }
            // Ticking one back on with the switch off turns the switch on - the pair are one
            // state, and leaving the switch off while a track is ticked would be the same lie
            // from the other side
        } else {
            defaults.set(false, forKey: "musicSetting")
            MusicHandler.sharedHelper.stopMusic()
            // **The last one going off turns the music off** (James, round 207). A rotation
            // with nothing in it is silence, and silence with the switch still saying "on" is
            // a setting that lies
        }
        tableView.reloadData()
        onChange?()
    }

    // MARK: - The preview

    private func startPreview(_ track: MusicTrack) {
        stopPreview()
        guard let url = track.url else { return }
        MusicHandler.sharedHelper.pauseMusic()
        // The menu's theme steps aside rather than playing underneath - two tunes at once is
        // not a preview of either
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1
            player.prepareToPlay()
            player.play()
            previewPlayer = player
            previewing = track
        } catch {
            Log.audio.error("Preview failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func stopPreview() {
        guard previewing != nil else { return }
        previewPlayer?.stop()
        previewPlayer = nil
        previewing = nil
        if defaults.bool(forKey: "musicSetting") { MusicHandler.sharedHelper.resumeMusic() }
        // Only if the music is still on - the player may have turned the last track off while
        // a preview was running, and resuming then would be the setting undoing itself
    }

    // MARK: - Navigation

    @objc private func closeTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        menuNavigationGoBack()
    }

    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        stopPreview()
        removeAnimate()
        NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
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
                self.removeFromParent()
            }
        }
    }
}
