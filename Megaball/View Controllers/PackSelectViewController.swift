//
//  PackSelectViewController.swift
//  Megaball
//
//  Created by James Harding on 10/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GameKit

class PackSelectViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, GKGameCenterControllerDelegate, MenuNavigable, MenuNavigationPresenter {

    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var gameCenterSetting: Bool = false
    // User settings
    
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    // UI property setup
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var packView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var packCollectionView: UICollectionView!
    @IBOutlet var backButtonCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnPackSelectNotificationKeyReceived), name: .returnPackSelectNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        userSettings()
        loadData()
        
        packCollectionView.delegate = self
        packCollectionView.dataSource = self
        packCollectionView.clipsToBounds = false
        packCollectionView.register(PackGridCell.self,
                                    forCellWithReuseIdentifier: PackGridCell.reuseIdentifier)
        if let grid = packCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            grid.minimumInteritemSpacing = PackSelectViewController.gridGap
            grid.minimumLineSpacing = PackSelectViewController.gridGap
            grid.estimatedItemSize = .zero
        }
        // The gap is set here as well as used in the size calculation, from one constant, so
        // the two cannot disagree - if the layout's idea of the gap is wider than the one the
        // widths were worked out against, three cells stop fitting and it quietly draws two
        // The packs are a grid of squares rather than a list of rows, so all eleven are on the
        // screen at once and the mode's title and logo have somewhere to be
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.clipsToBounds = false
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        
        
        setBlur()
        if parallaxSetting {
            addParallax()
        }
        installModeLogo()
        showAnimate()
        packCollectionView.reloadData()
        backButtonCollectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        collectionViewLayout()
    }

    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    
    /// The mode's name and its logo above the grid, the way the two endless screens carry
    /// theirs (play-test request).
    ///
    /// The three mode menus are a set, and this one was the odd member: it was headed "Level
    /// Packs", which describes what is on the screen rather than which mode you are in, and it
    /// wore no logo at all. The icon is asked of `GameMode` rather than named here, so the
    /// screen shows whatever the main menu's Classic row shows - one icon, one decision.
    private func installModeLogo() {
        titleLabel.text = GameMode.classic.name.uppercased()

        guard let container = packCollectionView.superview,
              let gridTop = container.constraints.first(where: { $0.identifier == "packGridTop" }),
              let image = GameMode.menuIcon(for: .classic) else { return }

        let logo = UIImageView(image: image)
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(logo)

        gridTop.isActive = false

        let titleTop = container.constraints.first {
            ($0.firstItem === titleLabel && $0.firstAttribute == .top)
                || ($0.secondItem === titleLabel && $0.secondAttribute == .top)
        }
        let titleTopInset = titleTop?.constant ?? 20
        titleTop?.isActive = false
        // **The icon goes above the name** (James, round 210: "I do think the icons and titles
        // should be swapped, with the icon at the top, then using the classic mode menu view
        // style where the icon shrinks when the page is scrolled"). The title's own top
        // constraint is the storyboard's, so it is found and stood down rather than fought -
        // the same move `setupRunHistory` makes on the endless menus. Its inset is reused as
        // the logo's, so the block starts exactly where the title used to.

        let width = logo.widthAnchor.constraint(equalToConstant: PackSelectViewController.logoRestSize)
        logoWidth = width
        modeLogo = logo
        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: container.topAnchor, constant: titleTopInset),
            logo.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            width,
            logo.heightAnchor.constraint(equalTo: logo.widthAnchor),
            titleLabel.topAnchor.constraint(equalTo: logo.bottomAnchor,
                                            constant: UIViewController.menuHeaderIconGap),
            packCollectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                    constant: 26),
        ])
        // More air under the name than beside it (play-test round 36), and the logo gives that
        // air back when it is needed: see scrollViewDidScroll. The name now travels up with
        // the logo as it collapses, because it hangs from the logo's bottom - which is what
        // makes the whole header shrink rather than just the picture inside it
    }

    private weak var modeLogo: UIImageView?
    private var logoWidth: NSLayoutConstraint?
    static let logoRestSize = UIViewController.menuModeLogoSize
    static let logoScrolledSize = UIViewController.menuModeLogoScrolledSize
    // The endless menus' own size, read from the one place that holds it (round 141): the
    // three mode menus are a set, and this one was wearing a logo less than half the size
    // of its siblings'

    /// The collapse, shared with every other menu that wears a mode logo since round 210.
    private var header = MenuHeaderCollapse(restSize: logoRestSize,
                                            scrolledSize: logoScrolledSize)

    /// The height the logo has to give: full size down to the size it wears when scrolled.
    static var logoTravel: CGFloat { UIViewController.menuModeLogoSize
                                     - UIViewController.menuModeLogoScrolledSize }

    /// The logo trades its size for the grid's room as the packs scroll up (play-test round
    /// 36), and **the packs do not move until it has finished** (James, round 165: "the packs
    /// shouldn't start scrolling until the logo has shrunk down to its smallest size").
    ///
    /// The old version read the collapse straight off `contentOffset`, which meant the two
    /// happened at once - and because the grid is pinned to the logo's bottom, the packs then
    /// travelled at the finger's speed *plus* the speed the logo was giving room back at,
    /// about 1.8 points for every one dragged. That is what "doesn't work well" was: a list
    /// that outruns the thumb pushing it.
    ///
    /// So the first hundred-odd points of the drag are spent on the logo and the list is held
    /// at its top while they are. The offset is put back each frame and the distance it tried
    /// to move is added to the collapse instead - the gesture keeps pushing, so the collapse
    /// keeps advancing, and it unwinds the same way when the drag comes back down. Once the
    /// logo is at its smallest the offset is left alone and the packs scroll normally.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == packCollectionView, logoWidth != nil else { return }

        let top = -scrollView.adjustedContentInset.top
        if header.absorb(tried: scrollView.contentOffset.y - top) {
            scrollView.contentOffset.y = top
            // Held at the top while the header is still taking the drag - see the rule itself
        }
        applyLogoCollapse()
    }

    /// Sets the logo to whatever `logoCollapsed` says, and lets the grid have the difference.
    private func applyLogoCollapse() {
        logoWidth?.constant = header.size
        (packCollectionView as? ContentAwareCollectionView)?.keepsTakingDrags = header.isCollapsing
        // While the logo is down, the grid keeps listening even though everything now fits -
        // the room that made it fit is the logo's, and it has to be givable back
    }

    // MARK: - The pack grid

    /// The eleven packs. The two entries before them in `levelPackNameArray` are the tutorial
    /// and Endless Mode, which is where the +2 in every index below comes from - it is the
    /// oldest arithmetic on this screen and it is not an off-by-one.
    private var packCount: Int { LevelPackSetup().levelPackNameArray.count - 2 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        collectionView == packCollectionView ? packCount : 3
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard collectionView == packCollectionView else {
            return backButtonCell(for: indexPath)
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PackGridCell.reuseIdentifier, for: indexPath) as! PackGridCell
        let pack = indexPath.item + 2
        let setup = LevelPackSetup()
        let unlocked = totalStatsArray[0].levelPackUnlockedArray[pack]

        cell.show(name: unlocked ? setup.levelPackNameArray[pack] : unlockHint(for: pack),
                  icon: setup.packIcon(pack),
                  unlocked: unlocked,
                  completed: totalStatsArray[0].packBestTimes[indexPath.item] > 0)
        // Completed means the pack has a best time, which it only gets by being finished

        cell.onOpenList = { [weak self] in self?.openLevelList(for: pack) }
        return cell
    }

    /// What a locked pack says instead of its name.
    ///
    /// The name is withheld on purpose - a locked pack is a thing to be earned, and listing it
    /// gives away what is coming - so the square carries the requirement instead.
    private func unlockHint(for pack: Int) -> String {
        if pack == 5 { return "Complete first 3 packs to unlock" }
        // Pack 5 is the one that needs three rather than the one before it
        if totalStatsArray[0].levelPackUnlockedArray[pack-1] {
            return "Complete \(LevelPackSetup().levelPackNameArray[pack-1]) to unlock"
        }
        return "Complete Pack \(pack-2) to unlock"
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == packCollectionView else {
            backButtonSelected(indexPath)
            return
        }
        let pack = indexPath.item + 2
        (collectionView.cellForItem(at: indexPath) as? PackGridCell)?.setPressed(false)
        guard totalStatsArray[0].levelPackUnlockedArray[pack] else { return }
        // A locked pack is not a door that rattles

        play(pack: pack)
        // The cell plays the pack; the small list button on it opens the levels inside. That
        // is the way round the play-test asked for (round 33), and the right way round: the
        // common thing is to play, so it gets the whole cell, and picking a level inside is
        // what earns a control of its own
    }

    /// Opens the pack's list of levels - what the whole cell used to do.
    private func openLevelList(for pack: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        hideAnimate()
        moveToLevelSelector(packNumber: pack,
                            numberOfLevels: LevelPackSetup().numberOfLevels[pack],
                            startLevel: LevelPackSetup().startLevelNumber[pack])
    }

    /// Starts a pack without going through its level list - the straight-in button the rows
    /// used to carry, now a badge in the corner of the square.
    private func play(pack: Int) {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        MenuViewController().clearSavedGame()
        moveToGame(selectedLevel: LevelPackSetup().startLevelNumber[pack],
                   numberOfLevels: LevelPackSetup().numberOfLevels[pack],
                   sender: "MainMenu", levelPack: pack)
    }

    /// Three across, square, as many rows as that takes - and it scrolls when that is more
    /// rows than fit.
    ///
    /// Worked out from the collection view's own width every layout pass, because this screen
    /// is the same on a small phone and an iPad, where the menus' aspect cap has already
    /// narrowed the container by the time this runs.
    ///
    /// **Three whatever the width, deliberately** - unlike the reference grids, which take
    /// `columns(fitting:base:)` and hold their cards to a phone's size (round 186). This is a
    /// front door with eleven cards on it, not a catalogue with fifty: seven small packs
    /// across an iPad would be a sparse screen where three large ones are a clear one. The
    /// glyph scales with the card, so a big card is a big mark rather than more empty card.
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard collectionView == packCollectionView else { return CGSize(width: 50, height: 50) }
        let columns: CGFloat = 3
        let gap = PackSelectViewController.gridGap
        let available = collectionView.bounds.width - 2*PackSelectViewController.gridInset
        let width = max(1, ((available - gap*(columns - 1))/columns).rounded(.down))
        // **Floored, and that is the whole bug fix.** An exact division leaves three cells
        // whose total is a hair *over* the width available once the flow layout adds its
        // spacing back, and a flow layout that cannot fit three across silently fits two and
        // spreads them out. That is what the play-test screenshot showed: a two-column grid
        // with a canyon down the middle, on a screen where the arithmetic said three fitted.
        // A floor costs at most two points of width and can never overflow

        // Square, and left square. Stretching the cells to fill whatever height was going made
        // the grid look pressed into the page (play-test round 34), because the icon and the
        // name are the same size whatever the card does - a taller card is just more empty
        // card. Scrolling is the better answer, and this screen scrolls properly now, with the
        // same edge fade every other list on these menus has.
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard collectionView == packCollectionView else {
            return collectionView.ownSectionInset
            // The button row keeps what `layoutMenuButtonRow` gave it. Returning `.zero`
            // here is what had been overruling that row's 55pt since long before rounds
            // 157 and 158 set it (James, round 165: the Game Center icon is in the wrong
            // spot) - two collection views, one delegate, and this method answers for both
        }

        // No vertical inset any more: the cells stretch to fill the height, so there is
        // nothing left over to centre, and on a screen too small for that the grid runs past
        // the bottom and scrolls - with the same edge fade every other list on these menus has
        return UIEdgeInsets(top: 0, left: PackSelectViewController.gridInset,
                            bottom: 0, right: PackSelectViewController.gridInset)
    }

    static let gridInset: CGFloat = 20
    static let gridGap: CGFloat = 10

    /// The screen these grids were drawn against - a current phone, in points.
    ///
    /// Not a device check, a *reference*: the card size three across produces here is the
    /// card size the icons, the names and the status notes were all sized for, and it is
    /// what `columns(fitting:base:)` tries to hold on to elsewhere.
    static let referenceScreenWidth: CGFloat = 393

    /// How many cards should go across a grid this wide.
    ///
    /// **The count grows on a big screen; the cards do not.** Three across a phone is a
    /// 111pt square with a 12pt name under a picture. Three across an iPad - even with the
    /// menus' aspect cap already applied, which leaves about 830pt - is a 270pt square with
    /// the *same* 12pt name under the same picture scaled up: the phone's layout enlarged
    /// rather than an iPad's layout, and the name reads as an afterthought on a coaster.
    /// So the arithmetic asks how many reference-sized cards fit instead.
    ///
    /// `max(base, …)` is what keeps every phone exactly as it is, including the small ones
    /// where the sum would otherwise argue for two: this may only ever add columns to a
    /// screen wider than the one the grid was drawn for.
    ///
    /// - Parameters:
    ///   - available: the width left for cards, insets already taken off.
    ///   - base: the count this grid uses on a phone - three for most, two where the names
    ///     are sentences rather than words.
    static func columns(fitting available: CGFloat, base: CGFloat) -> CGFloat {
        let reference = (referenceScreenWidth - 2*gridInset - gridGap*(base - 1))/base
        guard reference > 0, available > 0 else { return base }
        return max(base, ((available + gridGap)/(reference + gridGap)).rounded())
        // The gap is added to both sides of the division because n cards carry n-1 gaps;
        // adding one imaginary trailing gap to each makes it a plain division
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard collectionView == packCollectionView else {
            backButtonHighlighted(indexPath)
            return
        }
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        (collectionView.cellForItem(at: indexPath) as? PackGridCell)?.setPressed(true)
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard collectionView == packCollectionView else {
            backButtonUnhighlighted(indexPath)
            return
        }
        (collectionView.cellForItem(at: indexPath) as? PackGridCell)?.setPressed(false)
    }

    
    private var buttonRowWidened = false

    func collectionViewLayout() {
        if buttonRowWidened == false, let container = backButtonCollectionView.superview {
            buttonRowWidened = true
            for constraint in backButtonCollectionView.constraints
            where constraint.firstAttribute == .width {
                constraint.isActive = false
            }
            // The storyboard sized this row for the lone close button it used to hold:
            // width 50, square. Three buttons need the whole row (play-test request:
            // big play button in the centre, like the other views), so the fixed width
            // and the aspect pin go, and the row spans the container instead. Leading
            // and bottom pins stay the nib's own
            NSLayoutConstraint.activate([
                backButtonCollectionView.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor, constant: -20),
                backButtonCollectionView.heightAnchor.constraint(equalToConstant: 50),
            ])
            // Full width, but the ordinary 50pt height: with no big play button on this
            // screen (round 5 removed it - eleven packs, no pack to choose), the two
            // small buttons sit back down where the settings and info screens keep
            // theirs, spread to the row's ends
        }

        layoutMenuButtonRow(backButtonCollectionView,
                            sizes: Array(repeating: MainMenuCollectionViewCell.smallButtonSize,
                                         count: 3))
        // Close, an empty middle, Game Center - and pulled in from the ends rather than
        // pushed to them (play-test round 128): this row spanning the whole width while
        // the reference screens' rows sat close in is what made the two read as different
        // apps. `layoutMenuButtonRow` is the one arrangement now
    }


    /// The row of round buttons along the bottom. Its data source lives here rather than in
    /// the grid's methods above, which route to these by asking which collection view is
    /// calling - two collection views on one screen share one delegate.
    func backButtonCell(for indexPath: IndexPath) -> UICollectionViewCell {
        let collectionView = backButtonCollectionView!
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell", for: indexPath) as! MainMenuCollectionViewCell

        cell.widthConstraint.constant = MainMenuCollectionViewCell.smallButtonSize
        // The layout owns the cell's frame - see LevelStatsViewController's note

        switch indexPath.row {
        case 0:
            cell.setButton("ButtonClose.png")
        case 1:
            cell.setButton("ButtonNull.png")
            // Empty on purpose, for the second time. A play button here was tried in round
            // 3 and taken back on sight; round 33 brought it back as Play Next Pack with a
            // real pack to play; round 36 took it back again - the cells themselves play
            // now, so the bottom button was a second way of doing the most obvious thing.
            // If it is ever proposed a third time, this comment is the history
        case 2:
            if gameCenterSetting {
                cell.setButton("ButtonLeaderboard.png")
            } else {
                cell.setButton("ButtonNull.png")
            }
            // The Game Center button on the right (play-test request), opening the full
            // leaderboards sheet - the packs each have a board, and this screen is all
            // of them
        default:
            Log.ui.error("Row index out of range in \(#function, privacy: .public)")
            break
        }

        UIView.animate(withDuration: 0.1) {
            cell.view.transform = .identity
        }

        return cell
    }

    func backButtonSelected(_ indexPath: IndexPath) {
        let collectionView = backButtonCollectionView!
        if indexPath.row == 0 {
            menuNavigationGoBack()
        }
        if indexPath.row == 2, gameCenterSetting {
            showGameCenterLeaderboards()
        }
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }

    func showGameCenterLeaderboards() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        GameCenterHandler().gameCenterSave()
        // Standing bests go up first, the same as every other leaderboard button
        let boards = GKGameCenterViewController(state: .leaderboards)
        boards.gameCenterDelegate = self
        view.window?.rootViewController?.present(boards, animated: true)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
    }

    func backButtonHighlighted(_ indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                switch indexPath.row {
                case 0:
                    if self.hapticsSetting {
                        self.interfaceHaptic.impactOccurred()
                    }
                    cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
                case 1:
                    cell.setButton("ButtonNull.png")
                case 2:
                    if self.gameCenterSetting {
                        if self.hapticsSetting {
                            self.interfaceHaptic.impactOccurred()
                        }
                        cell.setButton("ButtonLeaderboardHighlighted.png")
                    } else {
                        cell.setButton("ButtonNull.png")
                    }
                default:
                    cell.setButton("ButtonNull.png")
                }
            }
        }
    }

    func backButtonUnhighlighted(_ indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                switch indexPath.row {
                case 0:
                    cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
                case 1:
                    cell.setButton("ButtonNull.png")
                case 2:
                    if self.gameCenterSetting {
                        cell.setButton("ButtonLeaderboard.png")
                    } else {
                        cell.setButton("ButtonNull.png")
                    }
                default:
                    cell.setButton("ButtonNull.png")
                }
            }
        }
    }
    
    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self as? MenuViewControllerDelegate
        gameView.selectedLevel = selectedLevel
        gameView.numberOfLevels = numberOfLevels
        gameView.levelSender = sender
        gameView.levelPack = levelPack
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Straight into the pack, exactly as the level screens launch it

    func moveToLevelSelector(packNumber: Int, numberOfLevels: Int, startLevel: Int) {
        let levelSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "levelSelectorView") as! LevelSelectorViewController
        levelSelectorView.packNumber = packNumber
        levelSelectorView.numberOfLevels = numberOfLevels
        levelSelectorView.startLevel = startLevel
        self.addChild(levelSelectorView)
        levelSelectorView.view.frame = self.view.frame
        self.view.addSubview(levelSelectorView.view)
        levelSelectorView.didMove(toParent: self)
    }
    // Segue to LevelSelectorViewController
    
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
        // Load user settings
    }
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: backgroundView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func addParallax() {
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
            packView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        packView.addMotionEffect(group!)
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
    
    func menuNavigationHideBehindChild() {
        hideAnimate()
    }
    // The same fade opening a child gives - the forward swipe says it too, or the screen
    // underneath stays readable through the one that came back (the play-test screenshot)

    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.packView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.packView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.packView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.packView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.packView.alpha = 1.0
        })
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
    
    @objc func returnPackSelectNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        revealAnimate()
        packCollectionView.reloadData()
    }
    // Runs when returning from another menu view
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        packCollectionView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnPackSelectNotification = Notification.Name(rawValue: "returnPackSelectNotification")
}
// Notification setup
