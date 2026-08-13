//
//  StatsViewController.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class ItemsDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MenuNavigable, MenuNavigationPresenter {
    
    /// The mark on a power-up that only exists in Endless Mayhem.
    ///
    /// The mode's own logo is a glowing infinity with a ball above it, which does not survive
    /// being shrunk to the height of a line of text, so the badge is the plain infinity - the
    /// half of that logo that still reads at eleven points. A placeholder until §8.5 draws a
    /// small monochrome mark of its own, and deliberately a shape rather than a word: the state
    /// column already carries words on this screen, and a second one competes with them.
    ///
    /// Built as an attachment rather than as an image view so it uses the label the cell
    /// already has, and inherits its colour and its place in the row.
    static let mayhemBadge: NSAttributedString = {
        let mark = NSTextAttachment()
        mark.image = UIImage(systemName: "infinity",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 13,
                                                                            weight: .bold))?
            .withTintColor(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), renderingMode: .alwaysOriginal)
        return NSAttributedString(attachment: mark)
    }()

    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    var ballSetting: Int = 0
    var paddleSetting: Int = 0
    var brickSetting: Int = 0
    var appIconSetting: Int = 0
    // User settings
    
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    // UI property setup
    
    var senderID: Int?
    var navigatedFrom: String = "MainMenu"

    /// Whether the power-ups page carries the extra Recent section (play-test rounds 4
    /// and 6): opened from the pause menu, this run's sightings sit in their own section
    /// above the standard list - which keeps its ordinary order below, so the page is
    /// the reference it always was with the answer to "what was that" on top. No
    /// sightings, no section.
    var showsRecentsSection: Bool {
        navigatedFrom == "PauseMenu" && senderID == 2
            && InGameRecents.shared.powerUpIndices.isEmpty == false
    }

    /// The standard section's rows, with everything the Recent section already lists
    /// taken out (play-test round 7): one list per power-up, not the same one twice.
    var standardPowerUpRows: [Int] {
        let setup = LevelPackSetup()
        return InGameRecents.standardRows(
            rowCount: totalStatsArray[0].powerUpUnlockedArray.count,
            recents: showsRecentsSection ? InGameRecents.shared.powerUpIndices : [],
            powerUpIndex: { setup.powerUpCorrectOrderArray[$0] })
    }

    /// The power-up a row means. Recent rows carry indices directly, in recency order;
    /// the standard section goes through the display-order array, minus the recents.
    func powerUpIndex(at indexPath: IndexPath) -> Int {
        if showsRecentsSection, indexPath.section == 0,
           InGameRecents.shared.powerUpIndices.indices.contains(indexPath.row) {
            return InGameRecents.shared.powerUpIndices[indexPath.row]
        }
        let rows = standardPowerUpRows
        let row = rows.indices.contains(indexPath.row) ? rows[indexPath.row] : indexPath.row
        return LevelPackSetup().powerUpCorrectOrderArray[row]
    }

    /// Whether this row is in the Recent section, which is the only place the
    /// collected/missed/active note appears.
    func isRecentRow(_ indexPath: IndexPath) -> Bool {
        showsRecentsSection && indexPath.section == 0
    }
    // Key properties
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var itemsTableView: UITableView!
    @IBOutlet var itemsView: UIView!
    // UIViewController outlets
    
    @IBOutlet var backButtonCollectionView: UICollectionView!
    

    /// What this screen is showing, which depends on the list that opened it.
    private var detailTitle: String {
        switch senderID {
        case 0: return "APP ICONS"
        case 1: return "BALL & PADDLE"
        case 2: return "POWER-UPS"
        case 3: return "ACHIEVEMENTS"
        default: return "ITEM DETAILS"
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.returnItemStatsNotificationKeyReceived), name: .returnItemStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned from another view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.iAPcompleteNotificationKeyReceived), name: .iAPcompleteNotification, object: nil)
        // Sets up an observer to watch for notifications to check for in-app purchase success
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
        
        titleLabel.text = detailTitle
        // The outlet existed but was never assigned, so every one of the four lists this
        // screen serves showed the storyboard's placeholder, "ITEM DETAILS"

        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        // TableView setup
        
        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.clipsToBounds = false
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "iconCell")
        // Collection view setup
        
        
        buildGridIfWanted()

        itemsTableView.rowHeight = SettingsTableViewCell.glassRowHeight
        (itemsTableView as? ContentAwareTableView)?.stickyHeaderBand =
            showsRecentsSection ? 30 : 0
        // Keeps the pinned section headers out of the edge fade - see stickyHeaderBand

        userSettings()
        loadData()
        if parallaxSetting {
            addParallax()
        }
        itemsTableView.reloadData()
        grid?.reloadData()
        backButtonCollectionView.reloadData()
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        grid?.collectionViewLayout.invalidateLayout()
        // The square's size is worked out from the collection view's own width, and
        // `limitMenuContentSize` may have just changed it
    }

    // MARK: - The grid

    /// Which of this screen's four lists are squares rather than rows.
    ///
    /// The two that are a *choice between pictures* - which app icon you wear, which ball
    /// and paddle you play with. A grid shows eleven of them at once where a list showed
    /// four, and the thing being chosen is the picture, so the picture should be the cell
    /// (play-test round 77). The power-up and achievement lists stay rows for now: they are
    /// read rather than chosen from, and their words do not fit in a square.
    var usesGrid: Bool { senderID != nil }

    /// How big the name on a square is, which is not the same question on all four lists.
    ///
    /// Pack and theme names are one or two short words. Power-up and achievement names are
    /// phrases - "Clear And Retreat", "Endless Mode 1,000m Milestone" - and at the pack
    /// grid's size they either truncate or push the icon off the square.
    private var gridNameSize: CGFloat { senderID == 3 ? 10 : (senderID == 2 ? 11 : 13) }

    /// How many across. Achievements have the longest names and the least to look at, so
    /// they get more room per square by having fewer of them.
    private var gridColumns: CGFloat { senderID == 3 ? 2 : 3 }

    private var grid: UICollectionView?

    /// Builds the grid over the table, and takes the table out of the way.
    ///
    /// In code rather than in the storyboard, because the scene serves four lists and only
    /// two of them want this - a second collection view in the nib would be a view every
    /// screen carries and two use. It borrows the table's own frame, so the screen's layout
    /// stays the storyboard's business.
    private func buildGridIfWanted() {
        guard usesGrid else { return }

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = PackSelectViewController.gridGap
        layout.minimumLineSpacing = PackSelectViewController.gridGap

        let view = ContentAwareCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.register(PackGridCell.self, forCellWithReuseIdentifier: PackGridCell.reuseIdentifier)
        view.register(UICollectionReusableView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: "gridHeader")
        layout.sectionHeadersPinToVisibleBounds = true
        // Pinned, like the rows' were: on the in-game power-up page the heading is what
        // tells you whether you are looking at this run's power-ups or all of them, and a
        // heading that scrolls away stops answering that halfway down
        view.stickyHeaderBand = showsRecentsSection ? 30 : 0
        // Only the in-game power-up list has headings to keep clear of the fade
        itemsView.addSubview(view)
        grid = view

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: itemsTableView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: itemsTableView.trailingAnchor),
            view.topAnchor.constraint(equalTo: itemsTableView.topAnchor),
            view.bottomAnchor.constraint(equalTo: itemsTableView.bottomAnchor),
        ])
        itemsTableView.isHidden = true
    }

    /// What one square holds, whichever of the two lists it belongs to.
    ///
    /// Both are the same shape - a picture, a name, whether it is unlocked and whether it is
    /// the one in use - so they are answered together rather than in two branches that would
    /// drift apart.
    private func gridItem(at indexPath: IndexPath) -> (name: String, icon: UIImage?, unlocked: Bool, chosen: Bool) {
        let setup = LevelPackSetup()
        if senderID == 2 {
            let item = powerUpIndex(at: indexPath)
            let unlocked = totalStatsArray[0].powerUpUnlockedArray[item]
            return (unlocked ? setup.powerUpNameArray[item] : powerUpUnlockHint(item),
                    setup.powerUpImageArray[item], unlocked, false)
            // No tick: a power-up is not chosen, and the corner mark would be saying
            // something about it that is not true
        }
        if senderID == 3 {
            let done = totalStatsArray[0].achievementsUnlockedArray[indexPath.item]
            return (setup.achievementsNameArray[indexPath.item],
                    UIImage(named: done
                            ? setup.achievementsImageArray[indexPath.item]
                            : "AchivementBadgeIncomplete.png"),
                    true, done)
            // Always "unlocked": an achievement you have not earned is not hidden, it is
            // simply not done - it keeps its name, and the tick is what says which is which
        }

        let index = indexPath.item
        if senderID == 0 {
            let unlocked = totalStatsArray[0].appIconUnlockedArray[index]
            return (unlocked ? setup.appIconDisplayNameArray[index] : appIconUnlockHint(index),
                    setup.appIconImageArray[index], unlocked, appIconSetting == index)
        }
        let unlocked = totalStatsArray[0].themeUnlockedArray[index]
        return (unlocked ? setup.themeNameArray[index] : themeUnlockHint(index),
                setup.themeIconArray[index], unlocked, ballSetting == index)
    }

    /// The sentence a locked square says instead of its name.
    ///
    /// The pack's name only appears once that pack is somewhere the player can actually go -
    /// naming a pack they cannot reach is a spoiler and an instruction they cannot follow.
    private func appIconUnlockHint(_ index: Int) -> String {
        totalStatsArray[0].levelPackUnlockedArray.indices.contains(index+1)
            && totalStatsArray[0].levelPackUnlockedArray[index+1]
            ? LevelPackSetup().unlockedDescriptionArray[index]
            : "Complete Pack \(index) to unlock"
    }

    /// What a locked power-up says instead of its name.
    ///
    /// The two sentences the rows used: the one naming the pack, and the one that does not,
    /// chosen the same way - a pack the player cannot reach yet is not named at them.
    private func powerUpUnlockHint(_ item: Int) -> String {
        let setup = LevelPackSetup()
        let pack = setup.powerUpPackOrderArray[item] + 1
        return totalStatsArray[0].levelPackUnlockedArray.indices.contains(pack)
            && totalStatsArray[0].levelPackUnlockedArray[pack]
            ? setup.powerUpUnlockedDescriptionArray[item]
            : setup.powerUpHiddenUnlockedDescriptionArray[item]
    }

    private func themeUnlockHint(_ index: Int) -> String {
        totalStatsArray[0].levelPackUnlockedArray.indices.contains(index+1)
            && totalStatsArray[0].levelPackUnlockedArray[index+1]
            ? LevelPackSetup().unlockedDescriptionArray[index]
            : "Complete Pack \(index) to unlock"
    }

    
    override func viewWillAppear(_ animated: Bool) {
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        showsRecentsSection ? 2 : 1
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard showsRecentsSection else { return nil }
        let container = UIView()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = container.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(blur)
        // Its own blur backing, so rows sliding beneath the pinned header disappear
        // behind it instead of showing through the bare label - the header sits on top
        // of the scroll, it does not scroll under it (play-test round 10)

        let label = UILabel()
        label.text = section == 0 ? "  THIS RUN" : "  OTHER"
        // Shortened from "Recent this run" and "Other power-ups" (same round) - the
        // page's title already says power-ups
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        label.frame = container.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(label)
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        showsRecentsSection ? 30 : 0
    }

    // MARK: - The grid's data

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        collectionView == grid && showsRecentsSection ? 2 : 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        guard collectionView == grid else { return 1 }
        // One is the back button row's, which shares these delegate methods with the grid
        switch senderID {
        case 0: return totalStatsArray[0].appIconUnlockedArray.count
        case 1: return totalStatsArray[0].themeUnlockedArray.count
        case 2:
            if showsRecentsSection, section == 0 {
                return InGameRecents.shared.powerUpIndices.count
            }
            return standardPowerUpRows.count
        default: return LevelPackSetup().achievementsNameArray.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard collectionView == grid, showsRecentsSection else { return .zero }
        return CGSize(width: collectionView.bounds.width, height: 30)
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: "gridHeader", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        // Reused like a cell, so last time's label has to go or they stack up

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = header.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(blur)
        // Its own backing, so squares sliding under a pinned heading disappear behind it
        // rather than showing through the bare label - the same reason the rows' headers
        // have one

        let label = UILabel()
        label.text = indexPath.section == 0 ? "  THIS RUN" : "  OTHER"
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        label.frame = header.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(label)
        return header
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard collectionView == grid else { return CGSize(width: 50, height: 50) }
        let columns = gridColumns
        let taller: CGFloat = senderID == 3 ? 22 : 0
        // Achievement names are sentences - "Endless Mode 1,000m Milestone" - and want two
        // lines where a power-up's one word wants none. The square grows rather than the
        // type shrinking, because at ten points it was already as small as it should go
        // (play-test round 85)
        let gap = PackSelectViewController.gridGap
        let available = collectionView.bounds.width - 2*PackSelectViewController.gridInset
        let width = max(1, ((available - gap*(columns - 1))/columns).rounded(.down))
        return CGSize(width: width, height: width + taller)
        // Floored for the reason the pack screen's own comment gives -
        // an exact division silently drops to two columns, and a stretched card is just
        // more empty card
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        guard collectionView == grid else { return .zero }
        return UIEdgeInsets(top: UIViewController.menuListBreathingRoom.top,
                            left: PackSelectViewController.gridInset,
                            bottom: UIViewController.menuListBreathingRoom.bottom,
                            right: PackSelectViewController.gridInset)
        // The same air round 74 gave every list, which a collection view takes as a section
        // inset rather than as a content inset
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if senderID == 0 {
        // App icons
            return totalStatsArray[0].appIconUnlockedArray.count
        } else if senderID == 1 {
        // Theme
            return totalStatsArray[0].themeUnlockedArray.count
        } else if senderID == 2 {
        // Power-ups
            if showsRecentsSection, section == 0 {
                return InGameRecents.shared.powerUpIndices.count
            }
            return standardPowerUpRows.count
        } else if senderID == 3 {
        // Achievements
            return LevelPackSetup().achievementsNameArray.count
        } else {
        // default
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        cell.applyGlass()
        cell.blurView.isHidden = true
        cell.lockedImageView.isHidden = true
        
        cell.decriptionFullWidthConstraint.isActive = false
        cell.descriptionTickWidthConstraint.isActive = false
        cell.descriptionAndStateSharedWidthConstraint.isActive = true
        cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
        cell.settingDescription.font = cell.settingDescription.font.withSize(18)
        
        if senderID == 0 {
        // App icons
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = true
            
            cell.setIcon(LevelPackSetup().appIconImageArray[indexPath.row], recolour: false)
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.iconImage.layer.cornerRadius = 10
            cell.settingDescription.text =
                LevelPackSetup().appIconDisplayNameArray[indexPath.row]
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.tickImage.isHidden = true
            if cell.isGlass == false {
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            }
            // App Icons and Ball & Paddle were the two screens that repainted the card after
            // it had been glassed, which is why their rows looked so much more opaque than
            // everything else wearing the same material (round 65)
            if appIconSetting == indexPath.row {
                cell.tickImage.isHidden = false
            }
            if totalStatsArray[0].appIconUnlockedArray[indexPath.row] == false {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = true

                cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25))
                cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                
                if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+1] {
                    cell.settingDescription.text = LevelPackSetup().unlockedDescriptionArray[indexPath.row]
                } else {
                    cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
                }
                // Only show pack name in unlock description if that pack is available to play
                
                cell.settingState.text = ""
                cell.blurView.layer.cornerRadius = 10
                cell.lockedImageView.layer.cornerRadius = 10
                cell.blurView.layer.masksToBounds = true
                cell.lockedImageView.layer.masksToBounds = true
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked power-ups hidden until unlocked
        }
        
        if senderID == 1 {
        // Themes
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = true
            
            cell.setIcon(LevelPackSetup().themeIconArray[indexPath.row], recolour: false)
            cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15)
            cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.settingDescription.text = LevelPackSetup().themeNameArray[indexPath.row]
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            cell.tickImage.isHidden = true
            if cell.isGlass == false {
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705021739, green: 0.8706485629, blue: 0.870482862, alpha: 1)
            }
            // App Icons and Ball & Paddle were the two screens that repainted the card after
            // it had been glassed, which is why their rows looked so much more opaque than
            // everything else wearing the same material (round 65)
            if ballSetting == indexPath.row {
                cell.tickImage.isHidden = false
            }
            
            if totalStatsArray[0].themeUnlockedArray[indexPath.row] == false {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = true
                cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25))
                cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                
                if totalStatsArray[0].levelPackUnlockedArray[indexPath.row+1] {
                    cell.settingDescription.text = LevelPackSetup().unlockedDescriptionArray[indexPath.row]
                } else {
                    cell.settingDescription.text = "Complete Pack \(indexPath.row) to unlock"
                }
                // Only show pack name in unlock description if that pack is available to play
                
                cell.settingState.text = ""
                cell.blurView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.lockedImageView.layer.cornerRadius = cell.iconImage.frame.size.height/2
                cell.blurView.layer.masksToBounds = true
                cell.lockedImageView.layer.masksToBounds = true
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked balls hidden until unlocked
        }
        
        if senderID == 2 {
        // Power-ups
            let powerUpIndexCorrection = powerUpIndex(at: indexPath)

            cell.setIcon(LevelPackSetup().powerUpImageArray[powerUpIndexCorrection], recolour: false)
            cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
            cell.settingDescription.text = LevelPackSetup().powerUpNameArray[powerUpIndexCorrection]
            cell.centreLabel.text = ""
            cell.settingState.text = ""

            if LevelPackSetup().isEndlessIIPowerUp(powerUpIndexCorrection) {
                cell.settingState.attributedText = ItemsDetailViewController.mayhemBadge
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
            // §7.3, and the play-test's fourth-round request: say which power-ups only exist in
            // Endless Mayhem, the way the bricks page says NEW - so nobody goes hunting for a
            // Portal Paddle in a Classic pack

            if isRecentRow(indexPath) {
                cell.settingState.text = InGameRecents.shared.statusNote(at: indexPath.row)
                cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                cell.settingState.font = .boldSystemFont(ofSize: 11)
                cell.settingState.minimumScaleFactor = 0.5
                // Set after the badge, and deliberately: on the in-game recents list what
                // became of that appearance is the news, and the mode it belongs to is not -
                // you are playing it
                // What became of that appearance: caught, fell past, in a brick, or
                // running right now. Sized so COLLECTED fits the state column - at the
                // column's usual size it truncated (play-test round 8's screenshot)
            }
                        
            if totalStatsArray[0].powerupsGenerated.count < powerUpIndexCorrection-1 {
                totalStatsArray[0].powerupsGenerated.append(0)
            }
            if totalStatsArray[0].powerupsCollected.count < powerUpIndexCorrection-1 {
                totalStatsArray[0].powerupsCollected.append(0)
            }
            
            if totalStatsArray[0].powerUpUnlockedArray[powerUpIndexCorrection] == false {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = true
                cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25))
                cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                
                if totalStatsArray[0].levelPackUnlockedArray[LevelPackSetup().powerUpPackOrderArray[powerUpIndexCorrection]+1] {
                    cell.settingDescription.text = "\(LevelPackSetup().powerUpUnlockedDescriptionArray[powerUpIndexCorrection])"
                } else {
                    cell.settingDescription.text = "\(LevelPackSetup().powerUpHiddenUnlockedDescriptionArray[powerUpIndexCorrection])"
                }
                // Only show pack name in unlock description if that pack is available to play

                cell.settingState.text = ""
                cell.blurView.layer.cornerRadius = 8
                cell.lockedImageView.layer.cornerRadius = 8
                cell.blurView.layer.masksToBounds = true
                cell.lockedImageView.layer.masksToBounds = true
                cell.blurView.isHidden = false
                cell.lockedImageView.isHidden = false
            }
            // Locked power-ups hidden until unlocked
        }
        
        if senderID == 3 {
        // Achievements
            cell.descriptionAndStateSharedWidthConstraint.isActive = false
            cell.descriptionTickWidthConstraint.isActive = false
            cell.decriptionFullWidthConstraint.isActive = true
            
            cell.iconImage.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1483144264)
            cell.iconImage.layer.cornerRadius = cell.iconImage.frame.size.height/2
            cell.settingDescription.text = LevelPackSetup().achievementsNameArray[indexPath.row]
            cell.settingDescription.font = cell.settingDescription.font.withSize(15)
            cell.centreLabel.text = ""
            cell.settingState.text = ""
            if totalStatsArray[0].achievementsUnlockedArray[indexPath.row] {
                cell.descriptionAndStateSharedWidthConstraint.isActive = false
                cell.decriptionFullWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = true
                cell.tickImage.isHidden = false
                cell.setIcon(UIImage(named: LevelPackSetup().achievementsImageArray[indexPath.row])!, recolour: false)
            } else {
                cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.25))
                cell.settingDescription.font = cell.settingDescription.font.withSize(16)
                cell.tickImage.isHidden = true
                cell.setIcon(UIImage(named:"AchivementBadgeIncomplete.png")!, recolour: false)
            }
            if totalStatsArray[0].achievementsPercentageCompleteArray[indexPath.row] != "" && totalStatsArray[0].achievementsUnlockedArray[indexPath.row] == false {
                cell.decriptionFullWidthConstraint.isActive = false
                cell.descriptionTickWidthConstraint.isActive = false
                cell.descriptionAndStateSharedWidthConstraint.isActive = true

                cell.settingState.text = totalStatsArray[0].achievementsPercentageCompleteArray[indexPath.row]
            }
            // Show percentage complete if achievement has percentage complete and isn't complete
        }
        
        cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.2)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1), duration: 0.2)
        }
        
        if senderID == 0 {
        // App icon
            if totalStatsArray[0].appIconUnlockedArray[indexPath.row] {
                appIconSetting = indexPath.row
                defaults.set(appIconSetting, forKey: "appIconSetting")
                changeIcon(to: LevelPackSetup().appIconNameArray[indexPath.row])
            }
            // Don't allow selection if app icon is locked
        }
        
        if senderID == 1 {
        // Theme selection
            if totalStatsArray[0].themeUnlockedArray[indexPath.row] {
                ballSetting = indexPath.row
                paddleSetting = indexPath.row
                brickSetting = 0
                defaults.set(ballSetting, forKey: "ballSetting")
                defaults.set(paddleSetting, forKey: "paddleSetting")
                defaults.set(brickSetting, forKey: "brickSetting")

                
                if indexPath.row == 11 {
                    brickSetting = 1
                    defaults.set(brickSetting, forKey: "brickSetting")
                }
            }
            // Don't allow selection if theme is locked
        }
        
        if senderID == 2 {
        // Power-ups
            let powerUpIndexCorrection = powerUpIndex(at: indexPath)

            if totalStatsArray[0].powerUpUnlockedArray[powerUpIndexCorrection] {
                hideAnimate()
                moveToItemStats(passedIndex: powerUpIndexCorrection, sender: "Power-Ups")
            }
            // Don't allow into menu if power-up is locked
        }
        
        if senderID == 3 {
        // Achievements
            hideAnimate()
            moveToItemStats(passedIndex: indexPath.row, sender: "Achievements")
            // Don't allow into menu if power-up is locked
        }

        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1), duration: 0.1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.1)
        }
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == grid {
            let square = collectionView.dequeueReusableCell(
                withReuseIdentifier: PackGridCell.reuseIdentifier,
                for: indexPath) as! PackGridCell
            let item = gridItem(at: indexPath)
            square.show(name: item.name, icon: item.icon,
                        unlocked: item.unlocked, completed: item.chosen, recolour: false,
                        nameSize: gridNameSize)
            // Both of these lists are pictures - an app icon and a ball-and-paddle theme -
            // and the picture is the thing being chosen
            return square
        }

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
        if collectionView == grid {
            chooseGridItem(at: indexPath)
            collectionView.deselectItem(at: indexPath, animated: true)
            collectionView.reloadData()
            if closesOnChoice { menuNavigationGoBack() }
            return
        }

        menuNavigationGoBack()
        
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
    }

    /// Wears the chosen icon, or the chosen ball and paddle.
    ///
    /// Exactly what the rows did, moved rather than rewritten - including doing nothing at
    /// all for a locked square, which is the difference between a grid you can look at and
    /// one that lets you equip something you have not earned.
    /// Whether choosing one of these closes the screen.
    ///
    /// The app icon and theme grids are a *choice*: you came to pick one, and once you have
    /// there is nothing left to do here. The reference grids are a list to read, so they
    /// stay put (play-test round 85).
    private var closesOnChoice: Bool { senderID == 0 || senderID == 1 }

    private func chooseGridItem(at indexPath: IndexPath) {
        if senderID == 2 {
            hideAnimate()
            moveToItemStats(passedIndex: powerUpIndex(at: indexPath), sender: "Power-Ups")
            return
        }
        if senderID == 3 {
            hideAnimate()
            moveToItemStats(passedIndex: indexPath.item, sender: "Achievements")
            return
        }
        // **Both open their detail page, and both hide this one first.** The rows did the
        // second part and I left it out of the squares, which is why a detail page appeared
        // *over* a list still standing behind it (round 81) - these screens are children
        // added over their parent, so a parent that does not step aside stays visible.
        // Achievements opened a page from the rows too; the squares simply did nothing

        let index = indexPath.item
        if senderID == 0 {
            guard totalStatsArray[0].appIconUnlockedArray[index] else { return }
            appIconSetting = index
            defaults.set(appIconSetting, forKey: "appIconSetting")
            changeIcon(to: LevelPackSetup().appIconNameArray[index])
            return
        }
        guard totalStatsArray[0].themeUnlockedArray[index] else { return }
        ballSetting = index
        paddleSetting = index
        brickSetting = index == 11 ? 1 : 0
        // The eleventh theme brings its own bricks with it, which is the one exception the
        // row version carried and the only reason this is not a straight assignment to zero
        defaults.set(ballSetting, forKey: "ballSetting")
        defaults.set(paddleSetting, forKey: "paddleSetting")
        defaults.set(brickSetting, forKey: "brickSetting")
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard collectionView == backButtonCollectionView else {
            if hapticsSetting { interfaceHaptic.impactOccurred() }
            // The rows tapped the taptic engine when they lit up and the squares did not, so
            // a grid felt dead where the same list had felt alive (play-test round 83)
            (collectionView.cellForItem(at: indexPath) as? PackGridCell)?
                .setPressed(true)
            return
        }
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named:"ButtonCloseHighlighted.png"))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard collectionView == backButtonCollectionView else {
            (collectionView.cellForItem(at: indexPath) as? PackGridCell)?
                .setPressed(false)
            return
        }
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named:"ButtonClose.png"))
            }
        }
    }
    
    func moveToItemStats(passedIndex: Int, sender: String) {
        let itemStatsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsStatsView") as! ItemsStatsViewController
        itemStatsView.passedIndex = passedIndex
        itemStatsView.sender = sender
        self.addChild(itemStatsView)
        itemStatsView.view.frame = self.view.frame
        self.view.addSubview(itemStatsView.view)
        itemStatsView.didMove(toParent: self)
    }
    
    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
        brickSetting = defaults.integer(forKey: "brickSetting")
        appIconSetting = defaults.integer(forKey: "appIconSetting")
        // Load user settings
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
            itemsView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        itemsView.addMotionEffect(group!)
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
        if senderID == 0 || senderID == 1 {
            NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
        } else if senderID == 2 || senderID == 3 {
            NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
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
    
    /// Fades this screen out behind one it opened - or one being returned to by a forward
    /// swipe, which is the same thing seen from the other side.
    func menuNavigationHideBehindChild() {
        hideAnimate()
    }

    func hideAnimate() {
        UIView.animate(withDuration: 0.25, animations: {
            self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
            self.itemsView.alpha = 0.0
        })
    }
    
    func revealAnimate() {
        self.itemsView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        self.itemsView.alpha = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.itemsView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.itemsView.alpha = 1.0
        })
    }
    
    @objc func returnItemStatsNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        itemsTableView.reloadData()
        revealAnimate()
    }
    // Runs when returning from item stats view
    
    @objc func iAPcompleteNotificationKeyReceived(_ notification: Notification) {
        userSettings()
        loadData()
        itemsTableView.reloadData()
    }
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let returnItemStatsNotification = Notification.Name(rawValue: "returnItemStatsNotification")
}
// Notification setup
