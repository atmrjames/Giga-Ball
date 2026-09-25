//
//  SettingsViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import CoreHaptics

enum device {
    case Pad
    case X
    case Eight
    case SE
}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, MenuNavigable, MenuNavigationPresenter {
    
    var navigatedFrom: String?
    
    var defaults: UserDefaults = .standard
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
    var backgroundSetting: Int = 0
    var statsCollapseSetting: Bool = true
    var swipeUpPause: Bool = true
    var appOpenCount: Int = 0
    var firstPause: Bool = true
    // User settings
    var savedGame: SavedGame?
    // Game save settings
    
    
    var totalStatsStore: URL? = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    // Settable, with `defaults`, so Reset Data can be tested without wiping the real stats
    // (round 323) - the reset is the one action on this screen that cannot be undone
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    var screenSize: device?
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    var musicPausedBool: Bool = false
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.resetNotificiationKeyReceived), name: .resetNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has selected to reset the game data
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnNotificiationKeyReceived), name: .returnNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from the warning pop-up
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reanimateNotificiationKeyReceived), name: .reanimateNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another screen
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.clipsToBounds = false
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Levels tableView setup
        
        let screenRatio = self.view.frame.size.height/self.view.frame.size.width
        
        if screenRatio > 2 {
            screenSize = .X
        } else if screenRatio < 1.7  {
            screenSize = .Pad
        } else if self.view.frame.size.width <= 320 {
            screenSize = .SE
        }
        else {
            screenSize = .Eight
        }
        // Screen size and device detected
        
        settingsTableView.delegate = self
        settingsTableView.dataSource = self
        settingsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)
        watchTouchesOnSettingsTable()
        settingsTableView.separatorStyle = .none
        settingsTableView.rowHeight = SettingsTableViewCell.glassRowHeight
        settingsTableView.isHidden = false
        // TableView setup
        
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        if navigatedFrom! == "MainMenu" {
            setBlur()
        }
        backButtonCollectionView.reloadData()
        settingsTableView.reloadData()
        DispatchQueue.main.async {
             self.settingsTableView.reloadData()
        }
        installReturnToGameButton()
        // The way back into a paused run, from wherever this screen was reached
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        alignCloseButtonWithReturnToGame(backButtonCollectionView)
        // In to the narrow position when the big play is here (round 176) - see the helper
    }



    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    
    /// Whether this device can produce haptics at all.
    ///
    /// iPads have no taptic engine, so the setting is offered and does nothing. Asked of
    /// CoreHaptics rather than inferred from the idiom, which would be a guess that goes
    /// stale the moment Apple ships an iPad that can.
    static let deviceHasHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    /// The app icon and the ball and paddle theme, which the pause menu does not offer.
    ///
    /// Both restyle a game already in progress, and both lead into a picker that does not
    /// belong over live gameplay. They are dropped from the front of the list rather than
    /// hidden in place, which would leave two blank rows where they used to be.
    /// The settings this screen offers, in order, already filtered to what applies.
    enum SettingRow: Int {
        case appIcon, theme, sounds, music, haptics, background, perspective
        case paddleSpeed, swipeUpToPause, reset
        case interfaceSound
        // Last, so every row that already existed keeps the number the switches below read
    }

    /// Whether a row clicks the moment it lights up, before the tap has changed anything.
    ///
    /// Every row but UI Sound, which clicks in `didSelect` once it has flipped - so it is heard
    /// turning on and not turning off (James, round 342). Named so the rule can be tested.
    static func clicksAsItLightsUp(_ row: Int) -> Bool {
        row != SettingRow.interfaceSound.rawValue
    }

    var settingRows: [SettingRow] {
        var rows: [SettingRow] = [.appIcon, .theme]
        if navigatedFrom == "PauseMenu" { rows = [] }
        // The app icon and the ball and paddle theme restyle a game already in progress,
        // and open a picker that does not belong over live gameplay

        rows.append(.background)
        // Between the theme and the sounds (James, round 169). It belongs with the two rows
        // above it: all three are what the game *looks* like, and it had been sitting among
        // the rows that decide how it plays

        rows += [.sounds, .interfaceSound, .music]
        // **UI Sound under In-Game Sound** (James, round 341): the two sound switches together,
        // then the music
        if SettingsViewController.deviceHasHaptics { rows.append(.haptics) }
        rows += [.perspective, .paddleSpeed, .swipeUpToPause]

        if navigatedFrom == "PauseMenu" { rows.append(.reset) }
        // Reset Ball from the pause menu, which works. From the main menu the same row is
        // Reset Game Data, which was never implemented

        return rows
    }



    /// The row as the switches below number them, which is the main menu's numbering.
    private func settingRow(for indexPath: IndexPath) -> Int {
        settingRows[indexPath.row].rawValue
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return settingRows.count
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                    
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath) as! SettingsTableViewCell
            cell.applyGlass()
        
            settingsTableView.rowHeight = SettingsTableViewCell.glassRowHeight
            cell.contentView.viewWithTag(Self.swipeInfoTag)?.removeFromSuperview()
            // Every row, not just the one that adds it. Removing it only where it is
            // added meant a recycled cell carried the info button into whatever row it
            // was reused for - which is how one button became one on nearly every row
            // (play-test round 15)
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.iconImage.isHidden = false
            
            switch settingRow(for: indexPath) {

            case 0:
            // App icon
//                if navigatedFrom! == "PauseMenu" {
//                    hideCell(cell: cell)
//                    cell.isHidden = true
//                } else {
                    cell.settingDescription.text = "App Icon"
                    cell.centreLabel.text = ""
                    let icons = LevelPackSetup().appIconImageArray
                    cell.setIcon(icons.indices.contains(appIconSetting)
                        ? icons[appIconSetting]
                        : UIImage(named: "iconAppIcon.png")!, recolour: false)
                    // Not recoloured: this one is the app icon itself, a picture rather than
                    // a glyph, and a template render would flatten it to a white square
                    // The icon you are actually wearing, not a generic one (play-test
                    // round 13) - the row is about a choice, so it should show the choice
                    cell.settingState.text = ""
//                }
            case 1:
            // Theme
//                if navigatedFrom! == "PauseMenu" {
//                    hideCell(cell: cell)
//                } else {
                    cell.settingDescription.text = "Ball & Paddle Theme"
                    cell.centreLabel.text = ""
                    let themes = LevelPackSetup().themeIconArray
                    let hasArtwork = themes.indices.contains(ballSetting)
                    cell.setIcon(hasArtwork ? themes[ballSetting]
                                            : UIImage(named: "iconTheme.png")!,
                                 recolour: hasArtwork == false,
                                 roundedLikeTheCard: hasArtwork)
                    // The theme art is a picture with its own square edges, so it is cut to
                    // sit concentric with the row's rounded card (James, round 134). The
                    // fallback glyph is not - a template has no edges to cut
                    // The theme you are actually playing with, the way the App Icon row shows
                    // the icon you are wearing (play-test round 85). Recoloured only when it
                    // falls back to the generic glyph - a theme icon is a picture
                    cell.settingState.text = ""
//                }
            case SettingRow.interfaceSound.rawValue:
            // UI Sound
                let on = InterfaceSound.isOn(in: defaults)
                cell.settingDescription.text = "UI Sound"
                cell.centreLabel.text = ""
                cell.setIcon(UIImage(systemName: on ? "hand.tap.fill" : "hand.raised.slash.fill")!,
                             recolour: true)
                cell.settingState.text = on ? "on" : "off"
                cell.setStateColour(on ? #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
                                       : #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
            case 2:
            // Sounds
                cell.settingDescription.text = "In-Game Sound"
                cell.centreLabel.text = ""
                cell.setIcon(UIImage(named: soundsSetting ? "iconSound" : "iconSoundOff")!, recolour: true)
                if soundsSetting {
                    cell.settingState.text = "on"
                    cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                } else {
                    cell.settingState.text = "off"
                    cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                }
            case 3:
            // Music
                cell.settingDescription.text = "Music"
                cell.centreLabel.text = ""
                cell.setIcon(UIImage(named: musicSetting ? "iconMusic" : "iconMusicOff")!, recolour: true)
                if musicSetting {
                    cell.settingState.text = "on"
                    cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                } else {
                    cell.settingState.text = "off"
                    cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                }
                addRowChevron(to: cell, action: #selector(musicArrowTapped))
                // **The arrow opens the track list** (James, round 207). The row keeps its own
                // tap, which is still the master switch - the chevron beside the name is the
                // door, exactly as it is on Paddle Speed
            case 4:
            // Haptics
//                if screenSize == .Pad || screenSize == .SE {
//                // No haptics engine
//                    hideCell(cell: cell)
//                } else {
                    cell.settingDescription.text = "Haptics"
                    cell.centreLabel.text = ""
                    cell.setIcon(UIImage(named: hapticsSetting ? "iconHaptics" : "iconHapticsOff")!, recolour: true)
                    if hapticsSetting {
                        cell.settingState.text = "on"
                        cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                    } else {
                        cell.settingState.text = "off"
                        cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                    }
//                }
            case 5:
            // Game background
                cell.settingDescription.text = "Game Background"
                cell.centreLabel.text = ""
                cell.setIcon(GameBackgroundView.inTheSettingsFrame(
                    GameBackground.stored(backgroundSetting),
                    tinted: cell.isGlass ? SettingsTableViewCell.glassForeground : nil),
                             recolour: false)
                // `recolour: false` because the picture inside the frame is the answer: a glass
                // row's flat tint would turn the chosen background into a rectangle, so the
                // frame is tinted where it is drawn instead
                cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                cell.settingState.text = ""
                addRowChevron(to: cell, action: #selector(backgroundArrowTapped))
                // **The same arrow the other two rows use, built the same way, in the same
                // place** (James, rounds 332 and 339: "make the game background settings arrow
                // the same size and style as the other arrows on the settings page"). It was
                // drawn as a text attachment inside the *state* label at the right-hand end,
                // where Music's and Paddle Speed's are buttons beside their titles - same
                // glyph, same point size, and it still did not read as the same arrow because
                // it was not in the same place. One construction now, for all three.
            case 6:
            // Parallax
                cell.settingDescription.text = "Perspective Zoom"
                cell.centreLabel.text = ""
                cell.setIcon(UIImage(named: parallaxSetting ? "iconParallax" : "iconParallaxOff")!, recolour: true)
                if parallaxSetting {
                    cell.settingState.text = "on"
                    cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                } else {
                    cell.settingState.text = "off"
                    cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                }
            case 7:
            // Paddle sensitivity
                cell.settingDescription.text = "Paddle Speed"
                cell.centreLabel.text = ""
                let speed = PaddleSpeed.stored(defaults)
                cell.setIcon(UIImage(named: PaddleSpeed.iconName(for: speed))!, recolour: true)
                cell.settingState.text = PaddleSpeed.label(speed)
                cell.setStateColour(SettingsViewController.paddleSpeedColour(for: speed))
                addRowChevron(to: cell, action: #selector(paddleSpeedTryTapped))
                // The row cycles the setting as it always did (James, round 126); the
                // chevron beside the name is what opens the screen to feel it on
                // The row shows the number and opens the screen that lets it be felt
                // (play-test round 13). The five-step ramp of hard-coded greys is now a
                // ramp derived from where the value sits in the range, because the value
                // is a slider's now and no list of five colours can cover twenty-one
            case 8:
            // Swipe up to pause
                cell.settingDescription.text = "Swipe Up To Pause"
                cell.centreLabel.text = ""
                cell.setIcon(UIImage(named: swipeUpPause ? "iconPause" : "iconPauseOff")!, recolour: true)
                addSwipeInfoButton(to: cell)
                if swipeUpPause {
                    cell.settingState.text = "on"
                    cell.setStateColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
                } else {
                    cell.settingState.text = "off"
                    cell.setStateColour(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1))
                }
            case 9:
//                if navigatedFrom! = "PauseMenu" {
                // Reset game data
//                    hideCell(cell: cell)
//                    cell.settingDescription.text = ""
//                    cell.centreLabel.text = "Reset All Game Data (developer)"
//                    cell.settingState.text = ""
//                    cell.iconImage.isHidden = true
//                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
//                } else {
                // Kill ball
                    cell.settingDescription.text = ""
                    cell.settingState.text = ""
                    cell.centreLabel.text = "Reset Ball"
                    cell.iconImage.isHidden = true
                    cell.centreLabel.textColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 1)
//                }
            default:
                Log.ui.error("Row index out of range in \(#function, privacy: .public)")
                break
            }
        
        cell.isHidden = false
        // Rows that are not offered are left out of the list instead - see
        // settingRows. Still reset here, or a cell reused from when this did hide rows
        // would come back invisible

        
            cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.2)
            return cell
//        }
    }
    // Add content to cells
    
    private func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var rowHeight:CGFloat = 0

        if navigatedFrom! != "PauseMenu" {
            if (indexPath.row == 8) {
                rowHeight = 0
            } else {
                rowHeight = 70.0
            }
        }
//        }
        return rowHeight
    }
    
    private static let swipeInfoTag = 8801

    /// A real, finger-sized info button on the swipe-up row.
    ///
    /// It began as a glyph drawn into the label's text, which put it exactly after the
    /// words but made it part of a label - nothing to tap (play-test round 14 asked for
    /// something bigger and easier to hit). This is a 44-point button, the size Apple
    /// asks for, sitting just left of the on/off state where the row has room. The image
    /// inside it is smaller than its touch area, which is what makes it easy to hit
    /// without looking heavy.
    ///
    /// Cells are reused, so any previous one is removed before a new one is added -
    /// otherwise scrolling would stack them up on rows that never asked for one.
    func addSwipeInfoButton(to cell: SettingsTableViewCell) {
        let info = UIButton(type: .system)
        info.tag = Self.swipeInfoTag
        info.setImage(UIImage(systemName: "info.circle",
                              withConfiguration: UIImage.SymbolConfiguration(
                                  pointSize: 20, weight: .regular)), for: .normal)
        info.tintColor = cell.isGlass
            ? SettingsTableViewCell.glassForeground.withAlphaComponent(0.7)
            : #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1).withAlphaComponent(0.6)
        // The row's own purple would be a dark mark on a dark row - the one thing on this
        // screen that is drawn by the screen rather than by the cell, so it has to ask
        info.translatesAutoresizingMaskIntoConstraints = false
        info.addTarget(self, action: #selector(swipeInfoTapped), for: .touchUpInside)
        info.addTarget(self, action: #selector(swipeInfoTouchedDown), for: .touchDown)
        // **Stamped on the way down, not on the way up** (play-test round 39, the second
        // report of this). The guard below ignores a row toggle arriving in the same instant
        // as the button's own press - but it only worked when the button's `touchUpInside`
        // was delivered *first*. That ordering is not guaranteed: when the row's selection
        // won the race the stamp was still stale, the guard passed, and the setting flipped
        // before the pop-up appeared, which is exactly what was reported. A touch-down
        // always precedes both, so the stamp is fresh whichever order the ups arrive in
        cell.contentView.addSubview(info)
        cell.contentView.bringSubviewToFront(info)
        // In front of everything else in the cell, or a touch near its edge reaches the row
        // underneath and flips the setting the player was only asking about

        let title = cell.settingDescription.text ?? ""
        let font = cell.settingDescription.font ?? .systemFont(ofSize: 17)
        let written = (title as NSString).size(withAttributes: [.font: font]).width
        // Measured rather than anchored: the description and state labels share a width
        // constraint, so the description's *frame* ends near the middle of the row while
        // its words end wherever they end. Anchoring to either edge put the button in
        // open space (play-test round 16's screenshot); measuring the text puts it
        // immediately after the last letter, which is where a footnote belongs

        NSLayoutConstraint.activate([
            info.leadingAnchor.constraint(equalTo: cell.settingDescription.leadingAnchor,
                                          constant: written + 2),
            info.centerYAnchor.constraint(equalTo: cell.settingDescription.centerYAnchor),
            info.widthAnchor.constraint(equalToConstant: 56),
            info.heightAnchor.constraint(equalToConstant: 56),
            // Wider than Apple's 44 (play-test round 21: still too easy to miss). The glyph
            // inside is unchanged, so it looks the same and simply catches more
        ])
    }

    /// The chevron beside a row's name: the door to the screen behind it.
    ///
    /// Shares the information button's tag and guards deliberately - one row can carry one
    /// of these, and everything that makes the button survivable inside a cell (the 56pt
    /// target, the touch-down stamp, `selectionCameFromInfoButton`) is machinery that only
    /// works if there is exactly one of them *per row* to find.
    ///
    /// **Two rows carry one now**: Paddle Speed, and Music since round 209. The Music row's
    /// first build hung the arrow off the cell's `accessoryView`, which is outside the glass
    /// card - so that one row's card was shorter than every other row's and the arrow floated
    /// in the margin beside it. Inside the card, beside the name, is where this app puts a
    /// door, and it only took looking at it to see that.
    /// The right-hand side of a row that opens a screen: an arrow in a circle rather than the
    /// name of whatever is chosen.
    ///
    /// **James, round 329d, with a screenshot of a row reading "Deep Pu...": "game background
    /// selection on cell is truncated. Maybe don't bother showing the selection here - just use
    /// the arrow in a circle on the right side of the cell to show there's a selection
    /// screen."** The names are as long as "Starry Sky" and the state label is sized for "on",
    /// so the longer half of the list could not fit however the row was laid out.
    ///
    /// Drawn into the state label rather than added as another subview, so it inherits the
    /// place, the alignment and the colour every other row's answer already has - and a reused
    /// cell that becomes an ordinary row writes plain text over it in the usual way.
    func showSelectionArrow(in cell: SettingsTableViewCell) {
        let colour = cell.isGlass
            ? SettingsTableViewCell.glassForeground.withAlphaComponent(0.7)
            : #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1).withAlphaComponent(0.6)
        guard let arrow = UIImage(systemName: "chevron.forward.circle",
                                  withConfiguration: UIImage.SymbolConfiguration(
                                      pointSize: 20, weight: .regular))?
            .withTintColor(colour, renderingMode: .alwaysOriginal) else {
            cell.settingState.text = ""
            return
        }
        let attachment = NSTextAttachment(image: arrow)
        cell.settingState.attributedText = NSAttributedString(attachment: attachment)
        cell.settingState.accessibilityLabel = "Opens a selection screen"
    }

    func addRowChevron(to cell: SettingsTableViewCell, action: Selector) {
        let chevron = UIButton(type: .system)
        chevron.tag = Self.swipeInfoTag
        chevron.setImage(UIImage(systemName: "chevron.forward.circle",
                                 withConfiguration: UIImage.SymbolConfiguration(
                                     pointSize: 20, weight: .regular)), for: .normal)
        chevron.tintColor = cell.isGlass
            ? SettingsTableViewCell.glassForeground.withAlphaComponent(0.7)
            : #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1).withAlphaComponent(0.6)
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.addTarget(self, action: action, for: .touchUpInside)
        chevron.addTarget(self, action: #selector(swipeInfoTouchedDown), for: .touchDown)
        cell.contentView.addSubview(chevron)
        cell.contentView.bringSubviewToFront(chevron)

        let title = cell.settingDescription.text ?? ""
        let font = cell.settingDescription.font ?? .systemFont(ofSize: 17)
        let written = (title as NSString).size(withAttributes: [.font: font]).width

        NSLayoutConstraint.activate([
            chevron.leadingAnchor.constraint(equalTo: cell.settingDescription.leadingAnchor,
                                             constant: written + 2),
            chevron.centerYAnchor.constraint(equalTo: cell.settingDescription.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 56),
            chevron.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    /// The chevron on the Game Background row, which opens the picker the row opens.
    @objc func backgroundArrowTapped() {
        hideAnimate()
        moveToBackgroundSelect()
    }

    @objc func paddleSpeedTryTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        infoTappedAt = Date().timeIntervalSince1970
        moveToPaddleSpeed()
    }

    @objc func swipeInfoTouchedDown() {
        infoTappedAt = Date().timeIntervalSince1970
    }

    @objc func swipeInfoTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        infoTappedAt = Date().timeIntervalSince1970
        // Stamped again on the way up, so a slow press - finger down, held, lifted after the
        // window - still shields the row toggle that follows it
        explainSwipeUpToPause()
    }

    /// When the information button was last pressed.
    ///
    /// A `UIButton` inside a cell normally swallows its own touch, and normally that is the
    /// end of it. It was not: a press landing just off the glyph reached the row and flipped
    /// the setting, which is the opposite of what somebody asking what it does wants
    /// (play-test round 21). The button is bigger now, and this is the belt to that pair of
    /// braces - a row toggle arriving in the same instant as the button's own press is the
    /// same press, and is ignored.
    private var infoTappedAt: TimeInterval = 0

    private var infoWasJustTapped: Bool {
        Date().timeIntervalSince1970 - infoTappedAt < 0.4
    }

    /// Where the last touch on the settings table landed, in the table's own coordinates.
    ///
    /// The timestamp guard above assumed the button gets the touch and the row's selection
    /// arrives afterwards. It does not always: the play test reported the pop-up appearing
    /// *and* the setting flipping, and reported the button doing nothing at all when the
    /// setting was already on - which is the same fault seen from both sides, because the
    /// row's own toggle shows the pop-up when it switches something on. So the guard no
    /// longer depends on the button being touched. It asks where the finger was.
    private var lastTouchInTable: CGPoint = .init(x: -1, y: -1)

    /// Whether a selection came from a finger inside the row's information button.
    func selectionCameFromInfoButton(_ tableView: UITableView, at indexPath: IndexPath) -> Bool {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell,
              let info = cell.contentView.viewWithTag(Self.swipeInfoTag) else { return false }
        return info.convert(info.bounds, to: tableView).contains(lastTouchInTable)
    }

    /// Records every touch on the table without taking any of them.
    ///
    /// A zero-duration long press fires on touch-down and, with these three flags, changes
    /// nothing else about how the table behaves - the row still highlights and selects
    /// exactly as it did.
    func watchTouchesOnSettingsTable() {
        let watcher = UILongPressGestureRecognizer(target: self,
                                                   action: #selector(settingsTableTouched(_:)))
        watcher.minimumPressDuration = 0
        watcher.cancelsTouchesInView = false
        watcher.delegate = self
        // **This line is why the settings list would not scroll** (rounds 78-96). A
        // zero-duration long press recognises the moment a finger lands, and a recognised
        // gesture blocks every other recogniser on the same view by default - including the
        // table's own pan, so a drag could never become a scroll. `cancelsTouchesInView`
        // being false kept taps working, which is exactly what hid the cause: a tap never
        // needs the pan. Settings is the only screen wearing this watcher, which is why it
        // was the only list that would not scroll while Information, built identically,
        // would. The delegate below allows the watcher to recognise *alongside* everything
        // else, which is all it ever needed to do - it only records where the finger landed
        watcher.delaysTouchesBegan = false
        watcher.delaysTouchesEnded = false
        settingsTableView.addGestureRecognizer(watcher)
    }

    @objc func settingsTableTouched(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        lastTouchInTable = gesture.location(in: settingsTableView)
    }

    /// What the swipe-up gesture is for, said in the words the play test asked for.
    func explainSwipeUpToPause() {
        GigaBallAlert.show(
            on: self, title: "Swipe Up To Pause",
            message: "Swipe up in game to pause for a breather, or to reach settings and the reference pages.",
            symbol: "hand.draw.fill")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
            switch settingRow(for: indexPath) {
            case 0:
            // App icon
                hideAnimate()
                moveToItemDetails(senderID: 0)
            case 1:
            // Theme
                hideAnimate()
                moveToItemDetails(senderID: 1)
            case SettingRow.interfaceSound.rawValue:
            // UI Sound
                defaults.set(!InterfaceSound.isOn(in: defaults), forKey: InterfaceSound.settingKey)
                InterfaceSound.click(in: defaults)
                // Clicks as it comes on, which is the one way to say what it just turned on
            case 2:
            // Sounds
                soundsSetting = !soundsSetting
                defaults.set(soundsSetting, forKey: "soundsSetting")
            case 3:
            // Music
                if infoWasJustTapped { break }
                if selectionCameFromInfoButton(tableView, at: indexPath) {
                    musicArrowTapped()
                    break
                }
                // A press inside the chevron opens the track list; a press anywhere else on
                // the row is still the master switch. The same pair of guards Paddle Speed
                // and the swipe-up row use, for the same reason: a touch just off the glyph
                // reaches the row underneath
                musicSetting = !musicSetting
//                soundsSetting = musicSetting
                defaults.set(musicSetting, forKey: "musicSetting")
                if musicSetting { MusicSelection.selectAll() }
                // **Switching the music on ticks every track** (James, round 207: "if the
                // music setting is set to on, all tracks are selected by default"). Without
                // it, a player who turned the music off by unticking the last track would
                // switch it back on to silence - the switch would say on, the rotation would
                // still be empty, and nothing on this screen would explain why
//                defaults.set(soundsSetting, forKey: "soundsSetting")
                if musicSetting {
                    if musicPausedBool {
                        MusicHandler.sharedHelper.resumeMusic()
                    } else {
                        if navigatedFrom == "MainMenu" {
                            MusicHandler.sharedHelper.playMusic(sender: "Menu")
                        } else {
                            MusicHandler.sharedHelper.playMusic()
                        }
                    }
                } else {
                    musicPausedBool = true
                    MusicHandler.sharedHelper.pauseMusic()
                    // Stop music
                }
            case 4:
            // Haptics
                hapticsSetting = !hapticsSetting
                defaults.set(hapticsSetting, forKey: "hapticsSetting")
                if hapticsSetting { interfaceHaptic.impactOccurred() }
                // Switching haptics on answers with one tick - the demonstration.
                // Switching them off answers with the silence it just bought
                // (play-test round 12: the release path fired on the *old* value,
                // so turning them off buzzed)
            case 5:
            // Game background
                hideAnimate()
                moveToBackgroundSelect()
                // The row used to cycle to the next background on each tap. Three of the four
                // are shades of the same purple, so the name it left behind said nothing about
                // what had been chosen - the picker shows the scene in each of them instead
            case 6:
            // Parallax
                parallaxSetting = !parallaxSetting
                defaults.set(parallaxSetting, forKey: "parallaxSetting")
                if parallaxSetting {
                    addParallaxToView()
                } else if parallaxSetting == false {
                    if group != nil {
                        backgroundView.removeMotionEffect(group!)
                    }
                }
            case 7:
            // Paddle speed
                if infoWasJustTapped { break }
                if selectionCameFromInfoButton(tableView, at: indexPath) {
                    moveToPaddleSpeed()
                    break
                }
                // A press inside the chevron opens the try-out screen; a press anywhere else
                // on the row cycles, which is what this row has always done and what round
                // 126 asked for back. The same pair of guards the swipe-up row uses, and for
                // the same reason: a touch just off the glyph reaches the row underneath
                PaddleSpeed.cycle(in: defaults)
            case 8:
            // Swipe up pause
                if infoWasJustTapped { break }
                if selectionCameFromInfoButton(tableView, at: indexPath) {
                    explainSwipeUpToPause()
                    break
                }
                // The button's own action may or may not have run - what is certain is that
                // the finger was inside it, and a finger inside the information button is
                // asking what the setting does, never to change it
                swipeUpPause = !swipeUpPause
                defaults.set(swipeUpPause, forKey: "swipeUpPause")
                if swipeUpPause { explainSwipeUpToPause() }
                // Explained when it is switched *on* (play-test round 13), which is the
                // moment the gesture starts existing and the only moment the explanation
                // is news. Switching it off needs no essay
            case 9:
                if navigatedFrom! != "PauseMenu" {
                // Reset game data
                    showWarning(.resetData)
                } else {
                // Kill ball
                    showWarning(.resetBall)
                }
            // **Rows 11 to 13 are gone with the shop** (round 330c). Restore Purchases
            // belonged to the monetisation architecture that came out before 1.3, and Unlock
            // All and Re-Lock All were the two developer rows beside it. Nothing reached any
            // of the three - the rows themselves had been commented out for rounds - and
            // `relockAllItems` was a second, worse copy of `resetData` below, which is the
            // live path and the one the Reset Data pop-up runs. Recoverable from git if a
            // development cheat is ever wanted again
            default:
                break
            }
            
            CloudKitHandler().saveToiCloud()
            // Save any changes to NSUbiquitousKeyValueStore
            
            if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
                cell.setPressed(true, colour: #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1), duration: 0.2)
            }
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
            // Update table view
//        }
    }
    
    func moveToItemDetails(senderID: Int) {
        let itemsDetailView = self.storyboard?.instantiateViewController(withIdentifier: "itemsDetailView") as! ItemsDetailViewController
        itemsDetailView.senderID = senderID
        self.addChild(itemsDetailView)
        fillSelf(with: itemsDetailView.view)
        self.view.addSubview(itemsDetailView.view)
        itemsDetailView.didMove(toParent: self)
    }

    /// The ramp behind the paddle-speed row's number: pale at the slow end, the app's dark
    /// purple at the fast one, interpolated rather than listed.
    static func paddleSpeedColour(for value: CGFloat) -> UIColor {
        let span = PaddleSpeed.range.upperBound - PaddleSpeed.range.lowerBound
        let along = min(max((value - PaddleSpeed.range.lowerBound)/span, 0), 1)
        return UIColor(red: 0.6 + (0.1607843137 - 0.6)*along,
                       green: 0.6 + (0 - 0.6)*along,
                       blue: 0.6 + (0.2352941176 - 0.6)*along,
                       alpha: 1)
    }

    @objc func musicArrowTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        InterfaceSound.click()
        hideAnimate()
        moveToMusic()
    }

    func moveToMusic() {
        let musicView = MusicViewController()
        musicView.onChange = { [weak self] in
            self?.musicSetting = self?.defaults.bool(forKey: "musicSetting") ?? true
            self?.settingsTableView.reloadData()
            // The screen can turn the master switch off by unticking the last track, so the
            // row behind it has to be told rather than left showing "on" over silence
        }
        addChild(musicView)
        fillSelf(with: musicView.view)
        view.addSubview(musicView.view)
        musicView.didMove(toParent: self)
        musicView.showAnimate()
        // Opened the way every menu screen opens one (see moveToPaddleSpeed)
    }

    func moveToPaddleSpeed() {
        let paddleSpeedView = PaddleSpeedViewController()
        paddleSpeedView.onChange = { [weak self] _ in
            self?.settingsTableView.reloadData()
        }
        addChild(paddleSpeedView)
        fillSelf(with: paddleSpeedView.view)
        view.addSubview(paddleSpeedView.view)
        paddleSpeedView.didMove(toParent: self)
        paddleSpeedView.showAnimate()
        hideAnimate()
        // Opened the way every menu screen opens one: a child whose view is added over the
        // one that opened it, with this screen fading behind it (see MenuNavigation)
    }

    func moveToBackgroundSelect() {
        let backgroundSelectView = self.storyboard?.instantiateViewController(withIdentifier: "backgroundSelectView") as! BackgroundSelectViewController
        self.addChild(backgroundSelectView)
        fillSelf(with: backgroundSelectView.view)
        self.view.addSubview(backgroundSelectView.view)
        backgroundSelectView.didMove(toParent: self)
    }
    
    func menuNavigationHideBehindChild() {
        hideAnimate()
    }
    // The same fade opening a child gives - the forward swipe says it too, or the screen
    // underneath stays readable through the one that came back (the play-test screenshot)

    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.backgroundView.alpha = 0.0
        })
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if SettingsViewController.clicksAsItLightsUp(settingRow(for: indexPath)) {
            InterfaceSound.click()
        }
        // **Except the UI Sound row, which speaks for itself in didSelect** (James, round 342:
        // "When turning the UI sound off via the settings screen it shouldn't make a UI sound
        // button click. When turning it on, it should."). The row lights up on the touch, before
        // the setting has flipped, so a click here was the old setting's - heard when turning it
        // off, and doubled with didSelect's when turning it on.
        //
        // With haptics off, every press is silent - including the haptics row itself
        // (play-test round 12: turning haptics *off* was firing one). The tick that
        // demonstrates the toggle lives in didSelect, after the setting has flipped

        if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1), duration: 0.1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        // Releases are silent (play-test rounds 11 and 12) - the toggle's demonstration
        // tick lives in didSelect, where the flipped setting is already the truth
        if let cell = self.settingsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell
        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        cell.setButton("ButtonClose.png")
        
        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        menuNavigationGoBack()
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        InterfaceSound.click()
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
            }
        }
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    /// Does exactly what tapping the back button does.
    ///
    /// The left-edge swipe calls this, so the gesture and the button can never drift apart.
    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
        if navigatedFrom! == "PauseMenu" {
            NotificationCenter.default.post(name: .returnPauseNotification, object: nil)
        } else if navigatedFrom! == "MainMenu" {
            NotificationCenter.default.post(name: .returnSettingsNotification, object: nil)
        }
    }

    func removeAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
            }
        }
    }
    
    func addParallaxToView() {
        guard UIView.motionEffectsAreWelcome else { return }
        var amount = 25
        if view.frame.width > 450 {
            amount = 50
            // iPad
        }
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            backgroundView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        backgroundView.addMotionEffect(group!)
    }
    
    func setBlur() {
        settingsView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: settingsView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: settingsView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: settingsView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: settingsView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: settingsView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: settingsView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
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
        backgroundSetting = defaults.integer(forKey: "backgroundSetting")
        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
        swipeUpPause = defaults.bool(forKey: "swipeUpPause")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        firstPause = defaults.bool(forKey: "firstPause")
        // User settings
        
        savedGame = SavedGame.load()
        // Game save settings
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
    }
    
    /// Asks one of the app's confirms.
    ///
    /// This screen used to stand its own parallax down first, because two layers both drifting
    /// with the tilt read as one of them coming loose. Round 164 moved that into the pop-up,
    /// which now stills whatever raised it and hands the drift back on the way out - so every
    /// screen gets what Settings had been doing by hand, including the pause menu, which was
    /// the one that showed the problem again.
    func showWarning(_ confirm: GigaBallConfirm) {
        confirm.show(on: self)
    }
    
    func resetData() {
        soundsSetting = true
        defaults.set(soundsSetting, forKey: "soundsSetting")
        defaults.set(true, forKey: InterfaceSound.settingKey)
        musicSetting = true
        defaults.set(musicSetting, forKey: "musicSetting")
        hapticsSetting = true
        defaults.set(hapticsSetting, forKey: "hapticsSetting")
        parallaxSetting = true
        defaults.set(parallaxSetting, forKey: "parallaxSetting")
        if view.frame.size.width > 450 {
            paddleSensitivitySetting = 3
        } else {
            paddleSensitivitySetting = 2
        }
        defaults.set(paddleSensitivitySetting, forKey: "paddleSensitivitySetting")
        
        gameCenterSetting = false
        defaults.set(gameCenterSetting, forKey: "gameCenterSetting")
        ballSetting = 0
        defaults.set(ballSetting, forKey: "ballSetting")
        paddleSetting = 0
        defaults.set(paddleSetting, forKey: "paddleSetting")
        brickSetting = 0
        defaults.set(brickSetting, forKey: "brickSetting")
        if appIconSetting != 0 {
            appIconSetting = 0
            defaults.set(appIconSetting, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[0])
        }
        statsCollapseSetting = true
        defaults.set(statsCollapseSetting, forKey: "statsCollapseSetting")
        swipeUpPause = true
        defaults.set(swipeUpPause, forKey: "swipeUpPause")
        appOpenCount = 0
        defaults.set(appOpenCount, forKey: "appOpenCount")
        firstPause = true
        defaults.set(firstPause, forKey: "firstPause")
        
        savedGame = nil
        SavedGame.clear(from: defaults)
        // Reset user settings to defaults
        
        totalStatsArray[0] = TotalStats()
        totalStatsArray[0].dateSaved = Date()
        do {
            let data = try encoder.encode(self.totalStatsArray)
            totalStatsArray[0].dateSaved = Date()
            if let totalStatsStore { try data.write(to: totalStatsStore) }
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        if GameCenterHandler.isRunningTests == false {
            CloudKitHandler().saveDataReset()
        }
        // Never under tests: it reads the real stats file and writes the app's own settings,
        // and `StatsSyncTests` already drives the reset's generation bump on a store of its own
    }
    
    func changeIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }
        // Check app supports alternate icons

        UIApplication.shared.setAlternateIconName(iconName, completionHandler: { (error) in
        // Change the icon to an image with specific name
            if let error = error {
            Log.ui.error("App icon failed to change due to \(error.localizedDescription, privacy: .public)")
            }
        })
    }
    
    func revealAnimate() {
        self.backgroundView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.backgroundView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.backgroundView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.backgroundView.alpha = 1.0
        })
    }
    
    @objc func resetNotificiationKeyReceived(_ notification: Notification) {
        resetData()
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
    @objc func returnNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
    }
    
    @objc func reanimateNotificiationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        if parallaxSetting {
            addParallaxToView()
        }
        settingsTableView.reloadData()
        revealAnimate()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        settingsTableView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
    
}

extension Notification.Name {
    public static let resetNotificiation = Notification.Name(rawValue: "resetNotificiation")
    public static let returnNotificiation = Notification.Name(rawValue: "returnNotificiation")
    public static let reanimateNotificiation = Notification.Name(rawValue: "reanimateNotificiation")
}
// Notification setup for sending information from the pause menu popup to unpause the game

extension SettingsViewController: UIGestureRecognizerDelegate {

    /// The touch watcher observes; it must never exclude.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}
