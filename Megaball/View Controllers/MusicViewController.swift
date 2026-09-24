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
                                 UIGestureRecognizerDelegate, MenuNavigable {

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
        // **Everything here is pinned to the safe area, not to the view** (round 339). The
        // column every menu lays itself out in is applied as an `additionalSafeAreaInsets`, so
        // a view pinned to the view's own edges never sees it: on a 1032-point iPad this
        // screen's rows ran from 24 points to 1008, where the rest of the app holds a
        // 460-point column. `limitMenuContentSize` was already being called; nothing was
        // listening to it.
        view.applyMenuParallaxToContent()
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
        title.text = "MUSIC"
        title.font = UIViewController.menuTitleFont
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.5
        // **The storyboard's own title face** (James, round 212: "title header font and style
        // needs to match other views"). Round 210 copied `PaddleSpeedViewController`, which
        // turned out to be the odd one out - it wears Helvetica Neue Bold at 40 where every
        // storyboard title is the system face, black weight, at 35. Both code-built screens
        // read the number from one place now, so the next screen cannot pick a third
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        view.addSubview(title)

        let hint = UILabel()
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.text = "Play a track to hear it. Tick the ones to play during a game."
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
        tableView.rowHeight = SettingsTableViewCell.glassRowHeight
        watchTouches()
        // **A button inside this cell does not get its own touch.** The glass card sits over
        // the content and swallows it, which is why the settings list decides what was pressed
        // from *where the finger landed* rather than from a button's own action - see
        // `SettingsViewController.selectionCameFromInfoButton`. The first build of this screen
        // used two plain buttons and neither of them ever fired; only pressing them found it.
        tableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil),
                           forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        // The settings screen's own cell, so a row here is the same object as a row there -
        // it already carries the icon, the label, the state text and the tick
        view.addSubview(tableView)

        let credit = UILabel()
        credit.translatesAutoresizingMaskIntoConstraints = false
        credit.text = "Music by Brendan Lawton"
        credit.font = .systemFont(ofSize: 17, weight: .semibold)
        credit.textColor = UIViewController.menuCreditColour
        // The About view's own line, to the point (James, round 212: "music by Brendan Lawton
        // should take on the same style that it has on the about view") - semibold 17 in the
        // near-white the credits wear there, rather than the small grey aside this had
        credit.textAlignment = .center
        credit.isUserInteractionEnabled = true
        credit.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                           action: #selector(creditTapped)))
        view.addSubview(credit)
        // The same line the splash screen carries, where the music lives (James, round 210),
        // and a tap opens the same SoundCloud set the information screen links to - one URL,
        // in `soundCloudSet`, rather than the address written down twice

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
            title.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            hint.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            hint.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 44),
            hint.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -44),

            tableView.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            // **No inset of its own** (James, round 210: "make the cells the same size, shape,
            // width as other table views. They seem too narrow"). The card is drawn by
            // `applyGlass` inside the cell and already carries the margin every settings row
            // has; insetting the table as well was that margin applied twice
            tableView.bottomAnchor.constraint(equalTo: credit.topAnchor, constant: -12),

            credit.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -18),
            credit.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            credit.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),

            close.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
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
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SettingsTableViewCell.reuseIdentifier,
            for: indexPath) as! SettingsTableViewCell
        cell.applyGlass()
        // The settings list's own card, so a row here is the same object as a row there
        let track = MusicTrack.allCases[indexPath.row]

        cell.settingDescription.text = track.name
        cell.centreLabel.text = ""
        cell.setIcon(UIImage(named: "iconMusic")!, recolour: true)
        cell.accessoryView = nil
        for tag in [Self.playTag, Self.tickTag] {
            cell.contentView.viewWithTag(tag)?.removeFromSuperview()
        }
        // Cleared on every row, not only where they are added: a recycled cell carries
        // whatever the last row put on it, which is how one information button became one on
        // nearly every row (play-test round 15)

        addPlayButton(to: cell, row: indexPath.row, playing: previewing == track)

        if track.isChoosable {
            cell.settingState.text = ""
            // **The tick is the state.** Saying "on" as well put the word behind the tick,
            // which is where the row's state label lives - two answers to one question, one
            // of them half hidden by the other. Every other settings row uses the word
            // because it has nothing else; this one has the thing itself
            addTickButton(to: cell, row: indexPath.row,
                          on: MusicSelection.isEnabled(track))
        } else {
            cell.settingState.text = "menu"
            cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            // The Title Theme is listed because a player looking for the tune from the menu
            // should find it where the music lives - but it is the menu's, not a run's, so it
            // says what it is instead of offering a tick that would silence the main menu
        }
        return cell
    }

    private static let playTag = 8901
    private static let tickTag = 8902

    /// The play glyph beside a track's name.
    ///
    /// Placed exactly where the settings list puts a door - just past the end of the written
    /// name - so the two screens read the same way.
    private func addPlayButton(to cell: SettingsTableViewCell, row: Int, playing: Bool) {
        let play = UIButton(type: .system)
        play.tag = Self.playTag
        play.setImage(UIImage(systemName: playing ? "stop.circle" : "play.circle",
                              withConfiguration: UIImage.SymbolConfiguration(
                                  pointSize: 20, weight: .regular)), for: .normal)
        play.tintColor = SettingsTableViewCell.glassForeground.withAlphaComponent(playing ? 1 : 0.7)
        play.translatesAutoresizingMaskIntoConstraints = false
        play.isUserInteractionEnabled = false
        // Drawn, not pressed: the glass swallows its touch, so the row's selection and this
        // button's frame are what decide - see `watchTouches`
        cell.contentView.addSubview(play)
        cell.contentView.bringSubviewToFront(play)

        let title = cell.settingDescription.text ?? ""
        let font = cell.settingDescription.font ?? .systemFont(ofSize: 17)
        let written = (title as NSString).size(withAttributes: [.font: font]).width

        NSLayoutConstraint.activate([
            play.leadingAnchor.constraint(equalTo: cell.settingDescription.leadingAnchor,
                                          constant: written + 2),
            play.centerYAnchor.constraint(equalTo: cell.settingDescription.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 56),
            play.heightAnchor.constraint(equalToConstant: 56),
            // 56, not Apple's 44: the settings list found 44 still too easy to miss inside a
            // cell (play-test round 21), and the glyph is unchanged - it simply catches more
        ])
    }

    /// The tick at the end of a track's row: whether a run may play it.
    private func addTickButton(to cell: SettingsTableViewCell, row: Int, on: Bool) {
        let tick = UIButton(type: .system)
        tick.tag = Self.tickTag
        tick.setImage(UIImage(systemName: on ? "checkmark.circle.fill" : "circle",
                              withConfiguration: UIImage.SymbolConfiguration(
                                  pointSize: 22, weight: .semibold)), for: .normal)
        tick.tintColor = on ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
                            : SettingsTableViewCell.glassForeground.withAlphaComponent(0.45)
        tick.translatesAutoresizingMaskIntoConstraints = false
        tick.isUserInteractionEnabled = false
        cell.contentView.addSubview(tick)
        cell.contentView.bringSubviewToFront(tick)

        NSLayoutConstraint.activate([
            tick.centerXAnchor.constraint(equalTo: cell.settingState.centerXAnchor),
            // Centred on the row's state position rather than hung off its trailing edge
            // (James, round 210: "centre the checkmark within the cell") - that is where every
            // other settings row puts its answer, so the column reads straight down the list
            tick.centerYAnchor.constraint(equalTo: cell.settingDescription.centerYAnchor),
            // Centred on the name, not on `contentView` (James, round 212: "the checkmarks
            // should be vertically centred in the cells"). The glass card does not fill the
            // row - it is inset, and not evenly - so the row's centre is a little below the
            // card's. The name is centred *in the card*, which is what the eye reads as the
            // middle, and it is the anchor the play glyph beside it already uses
            tick.widthAnchor.constraint(equalToConstant: 56),
            tick.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    /// Where the last touch on the list landed, in the list's own coordinates.
    private var lastTouch: CGPoint = .init(x: -1, y: -1)

    /// Records every touch without taking any of them.
    ///
    /// A zero-duration long press fires the moment a finger lands. **All four flags matter**:
    /// a recognised gesture blocks every other recogniser on the same view by default, which
    /// includes the table's own pan - and that is what stopped the settings list scrolling for
    /// eighteen rounds (rounds 78 to 96). `cancelsTouchesInView` false keeps taps working,
    /// which is exactly what hid the cause back then, because a tap never needs the pan. The
    /// delegate below is the part that actually fixes it: recognise *alongside* everything
    /// else, and record only.
    private func watchTouches() {
        let watcher = UILongPressGestureRecognizer(target: self,
                                                   action: #selector(listTouched(_:)))
        watcher.minimumPressDuration = 0
        watcher.cancelsTouchesInView = false
        watcher.delaysTouchesBegan = false
        watcher.delaysTouchesEnded = false
        watcher.delegate = self
        tableView.addGestureRecognizer(watcher)
    }

    @objc private func listTouched(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        lastTouch = gesture.location(in: tableView)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    /// Which of the row's two controls the finger was inside, if either.
    private func controlHit(_ tag: Int, at indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell,
              let control = cell.contentView.viewWithTag(tag) else { return false }
        return control.convert(control.bounds, to: tableView).contains(lastTouch)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let track = MusicTrack.allCases[indexPath.row]

        if controlHit(Self.playTag, at: indexPath) {
            if previewing == track { stopPreview() } else { startPreview(track) }
            tableView.reloadData()
            return
        }
        if controlHit(Self.tickTag, at: indexPath) {
            toggle(track)
            return
        }
        // A press on the rest of the row does nothing. Both of this row's answers are
        // deliberate ones, and guessing which was meant is how a player auditioning the
        // tracks silently rewrites what a run plays
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

    /// The album the information screen links to, named once.
    static let soundCloudSet =
        "https://soundcloud.com/user-371123791/sets/giga-ball-original-sound-track?ref=clipboard&p=i&c=1"

    @objc private func creditTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        guard let url = URL(string: MusicViewController.soundCloudSet) else { return }
        UIApplication.shared.open(url)
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
