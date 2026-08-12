//
//  BrickTypesViewController.swift
//  Megaball
//
//  The reference page for bricks, built the way the power-ups page is built.
//
//  One difference, and it is the reason this is its own screen rather than another sender on
//  `ItemsDetailViewController`: bricks come in three lists, not one. A brick is a behaviour, a
//  style and a size at the same time, and a flat list of eighteen rows would hide exactly the
//  thing worth knowing - that the three combine. So the table has sections, which nothing else
//  in the app has, and that is the whole of what is new here.
//
//  Nothing is locked. The power-ups page hides what has not been unlocked yet because power-ups
//  arrive with packs; brick types are not earned, they are met, and a player looking one up has
//  almost certainly just been hit by it.
//

import UIKit

class BrickTypesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                                UICollectionViewDelegate, UICollectionViewDataSource,
                                MenuNavigable, MenuNavigationPresenter {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    // User settings

    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    var group: UIMotionEffectGroup?
    // UI property setup

    var navigatedFrom: String = "MainMenu"

    /// The sections as shown: the catalogue's own order from the menus; recently struck
    /// entries first within each section when reached from the pause menu (§12.0) -
    /// mid-run, the brick being looked up is the one that just did something.
    private var sections: [BrickTypeCatalogue.Section] = []
    /// Each shown row's position in `BrickTypeCatalogue.allEntries`, which is what the
    /// detail page is handed - reordering the display must not reorder the reference.
    private var flatIndices: [[Int]] = []

    private func buildSections() {
        sections = []
        flatIndices = []
        var flatBase = 0
        for section in BrickTypeCatalogue.sections {
            let order = navigatedFrom == "PauseMenu"
                ? InGameRecents.entryOrder(names: section.entries.map(\.name),
                                           recents: InGameRecents.shared.brickNames)
                : Array(section.entries.indices)
            sections.append(BrickTypeCatalogue.Section(
                title: section.title,
                entries: order.map { section.entries[$0] }))
            flatIndices.append(order.map { flatBase + $0 })
            flatBase += section.entries.count
        }
    }

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var itemsTableView: UITableView!
    @IBOutlet var itemsView: UIView!
    @IBOutlet var backButtonCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        // Back from the left edge, forward from the right - see MenuNavigation

        buildSections()
        // After navigatedFrom is set and before the table asks for anything

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.returnItemStatsNotificationKeyReceived),
                                               name: .returnItemStatsNotification, object: nil)
        // Sets up an observer to watch for notifications to check if the user has returned
        // from another view

        titleLabel.text = "BRICKS"

        itemsTableView.delegate = self
        itemsTableView.dataSource = self
        itemsTableView.register(UINib(nibName: "SettingsTableViewCell", bundle: nil),
                                forCellReuseIdentifier: "customSettingCell")
        itemsTableView.rowHeight = SettingsTableViewCell.glassRowHeight
        itemsTableView.sectionHeaderHeight = 34.0
        itemsTableView.sectionFooterHeight = 0.0
        itemsTableView.backgroundColor = .clear
        itemsTableView.sectionHeaderTopPadding = 0
        itemsTableView.estimatedSectionHeaderHeight = 0
        itemsTableView.estimatedSectionFooterHeight = 0
        // Estimated heights turn a header into a self-sizing one, and a plain UIView with a
        // label in it does not size itself - the first section's heading collapsed to nothing
        // while the other two happened to keep theirs
        // TableView setup. Grouped rather than plain, which every other table in the app is,
        // because a plain table pins its section headers to the top - and a header floating
        // over the rows, through the fade this table draws at its edges, reads as a glitch
        // rather than as a heading

        backButtonCollectionView.delegate = self
        backButtonCollectionView.dataSource = self
        backButtonCollectionView.register(UINib(nibName: "MainMenuCollectionViewCell", bundle: nil),
                                          forCellWithReuseIdentifier: "iconCell")
        // Collection view setup

        userSettings()
        if parallaxSetting {
            addParallax()
        }
        itemsTableView.reloadData()
        backButtonCollectionView.reloadData()
        installReturnToGameButton()
        // The way back into a paused run, from wherever this screen was reached
        showAnimate()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
    }

    // MARK: - The list

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].entries.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        34
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // The gap between sections comes from the header above the next one, so a footer as
        // well would double it. `.leastNormalMagnitude` rather than zero, which a grouped
        // table reads as "use the default"
        .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear

        let label = UILabel()
        label.text = sections[section].title.uppercased()
        label.font = .systemFont(ofSize: 15, weight: .black)
        label.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -24),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -6)
        ])
        return header
    }
    // Built here rather than as a nib. It is a label, and the app has no section headers
    // anywhere else to take a style from

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell",
                                                 for: indexPath) as! SettingsTableViewCell
        let entry = sections[indexPath.section].entries[indexPath.row]

        cell.applyGlass()
        cell.blurView.isHidden = true
        cell.lockedImageView.isHidden = true
        cell.tickImage.isHidden = true
        cell.centreLabel.text = ""

        cell.decriptionFullWidthConstraint.isActive = false
        cell.descriptionTickWidthConstraint.isActive = false
        cell.descriptionAndStateSharedWidthConstraint.isActive = true

        cell.setLabelColour(#colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1))
        cell.settingDescription.font = cell.settingDescription.font.withSize(18)
        cell.settingDescription.text = entry.name

        cell.setIcon(BrickTypeIcons.image(for: entry.art), recolour: false)
        // Brick art carries its own colours - that is the whole point of the page
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cell.iconImage.layer.cornerRadius = 0

        cell.settingState.text = entry.isNew ? "NEW" : ""
        cell.settingState.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        // §7.3 asks for the Endless 2.0 material to be marked as exclusive to it, so a player
        // does not go looking for a Portal in a Classic pack. The state column is sized for
        // "on" and "x1.50", and the mode's full name truncated to "Endless..." in it - the
        // number is the part that identifies it, and the detail page says it in full

        cell.setPressed(false, colour: #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1), duration: 0.2)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.itemsTableView.cellForRow(at: indexPath) as? SettingsTableViewCell {
            cell.setPressed(true, colour: #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1), duration: 0.2)
        }

        hideAnimate()
        moveToItemStats(entry: flatIndex(of: indexPath))

        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }

    /// Where a row sits in `BrickTypeCatalogue.allEntries`, which is what the detail page is
    /// handed - it takes an index, as it does for a power-up or an achievement.
    private func flatIndex(of indexPath: IndexPath) -> Int {
        flatIndices.indices.contains(indexPath.section)
            && flatIndices[indexPath.section].indices.contains(indexPath.row)
            ? flatIndices[indexPath.section][indexPath.row]
            : sections[..<indexPath.section].reduce(0) { $0 + $1.entries.count }
                + indexPath.row
        // Through the display order's map, because the displayed rows may lead with the
        // recents - counting positions would hand the detail page the wrong entry
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

    // MARK: - The close button

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "iconCell",
                                                      for: indexPath) as! MainMenuCollectionViewCell

        cell.frame.size.height = 50
        cell.frame.size.width = cell.frame.size.height
        cell.widthConstraint.constant = 40
        cell.iconImage.image = UIImage(named: "ButtonClose.png")
        cell.applyGlass(symbol: "xmark")

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
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .init(scaleX: 0.95, y: 0.95)
                cell.setPressedArtwork(UIImage(named: "ButtonCloseHighlighted.png"))
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = self.backButtonCollectionView.cellForItem(at: indexPath) as? MainMenuCollectionViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.view.transform = .identity
                cell.setPressedArtwork(UIImage(named: "ButtonClose.png"))
            }
        }
    }

    // MARK: - Housekeeping

    func moveToItemStats(entry index: Int) {
        let itemStatsView = self.storyboard?.instantiateViewController(withIdentifier: "itemsStatsView") as! ItemsStatsViewController
        itemStatsView.passedIndex = index
        itemStatsView.sender = ItemsStatsViewController.brickTypesSender
        self.addChild(itemStatsView)
        itemStatsView.view.frame = self.view.frame
        self.view.addSubview(itemStatsView.view)
        itemStatsView.didMove(toParent: self)
    }

    func userSettings() {
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        // Load user settings
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
        self.view.alpha = 0.0
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
        NotificationCenter.default.post(name: .returnItemDetailsNotification, object: nil)
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
        itemsTableView.reloadData()
        revealAnimate()
    }
    // Runs when returning from the detail view
}
