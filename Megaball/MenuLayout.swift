//
//  MenuLayout.swift
//  Megaball
//
//  Keeps the menu screens to a readable column on large screens.
//
//  The menus were built at a fixed 414x736 and centred, which is why they survived iPad
//  at all. Once that fixed size was removed so they could use the whole of an iPhone,
//  they filled an iPad too - full-width rows on an 11-inch screen, which is a lot of
//  nothing between an icon and its label.
//
//  Rather than constrain each screen's contents, this insets the safe area the contents
//  are already pinned to. Every menu lays its title, table and close button out against
//  the container's safe area guide, so insetting it moves all of them at once - and the
//  container itself, which carries the blurred backdrop, still fills the screen.
//

import UIKit

/// The heading that sits over a reference page's grid - BEHAVIOURS, CLASSIC GAME MODES.
///
/// One recipe, because there are two of these pages and they had drifted: the bricks page's
/// headings were 15pt black at a 24pt inset in a 34pt band, and the power-ups page's were 13pt
/// bold, indented with two spaces in the string itself, in a 30pt band (play-test round 145:
/// "the text on the power-ups and bricks info screen sticky headers is different - make them
/// the same"). Two screens showing the same kind of heading in two sizes reads as one of them
/// being wrong, which it was.
enum ReferenceHeading {

    /// How tall the band is, which is also how much of the top the scroll fade must leave
    /// alone - see `stickyHeaderBand`.
    static let height: CGFloat = 34

    /// Fills a dequeued supplementary view in: a dark blur, and the title over it.
    ///
    /// The blur is what lets the heading pin: squares travelling under it disappear behind it
    /// rather than showing through the bare label.
    static func fill(_ header: UICollectionReusableView, title: String) {
        header.subviews.forEach { $0.removeFromSuperview() }
        // Reused like a cell, so last time's label has to go or they stack up

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = header.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        header.addSubview(blur)

        let label = UILabel()
        label.text = title.uppercased()
        label.font = .systemFont(ofSize: 15, weight: .black)
        label.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor,
                                            constant: -24),
            label.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
    }
}

extension UIViewController {

    /// The most screen a menu should use, whatever it has been given.
    ///
    /// Roughly a large phone. Past this the rows stop reading as a list and start reading
    /// as a table of contents with the labels and values at opposite ends of the screen.
    static let menuMaximumSize = CGSize(width: 500, height: 820)

    /// How large a mode's own logo is at the head of its menu.
    ///
    /// The three mode menus are a set and their logos should be the same size (play-test
    /// round 126: the classic pack screen's "should match the size on the endless mode menu
    /// views"). The endless screens set it at 190 when a run list is under it, and this is
    /// that number, in one place, so the set stays a set.
    static let menuModeLogoSize: CGFloat = 190

    /// What that logo shrinks to when a list scrolls up under it.
    ///
    /// The pack grid is what the screen is for, and at rest the logo takes a third of it.
    /// Trading its size for the grid's room as the packs travel is the same bargain the
    /// large title in a navigation bar makes.
    static let menuModeLogoScrolledSize: CGFloat = 84

    /// How much air a menu's list gets above its first row and below its last.
    ///
    /// The screens were built with the table pinned close to the title above it and the
    /// button row below, and the play test read the whole app as compact because of it
    /// (round 74). This is deliberately a *content* inset rather than a constraint: the
    /// twelve menu screens share a nib and a navigation pattern but not a layout - each is
    /// its own storyboard scene - so a constraint would be twelve edits that can drift,
    /// where an inset is one number applied from the one method they all already call.
    static let menuListBreathingRoom = UIEdgeInsets(top: 32, left: 0, bottom: 40, right: 0)
    // Forty at the bottom (round 98). Ninety-six was round 94's answer to a list that
    // would not scroll at all - the real cause was the settings touch watcher, fixed in
    // round 97, so the margin comes back down to what the button row actually needs

    /// **How far in the outer buttons sit when the row has a large centre button.**
    ///
    /// Where every outer button sits, measured from the screen's edge.
    ///
    /// Round 135 had two arrangements, chosen by what was in the row: a big play button drew
    /// the small ones in to here, and a row of only small buttons went to the row's own ends.
    /// The second half is gone (James, round 157: "everything out to 55pt"), because "the
    /// row's own ends" was never one place - it was 51pt on the menus, 53 on the level list
    /// and 55 on the daily, depending on what each screen's container happened to be. A
    /// promise about where a thumb lands has to be one number.
    static let menuButtonRowInset: CGFloat = 55

    /// Where a lone small button sits when there is no large one to group around.
    ///
    /// The wide arrangement, in points, for the two screens that build a close button by hand
    /// rather than taking the shared row - `layoutMenuButtonRow` gets the same answer from the
    /// row's own edges, and these have no row to ask.
    static let menuButtonWideInset: CGFloat = 24

    /// Lays a screen's button row out the shared way.
    ///
    /// - Parameter sizes: each button's width, in the order they appear. The row is always
    ///   three cells - some of them the invisible `ButtonNull` spacer - so what differs
    ///   between screens is only whether one of the three is large.
    ///
    /// Every row's outer buttons land `menuButtonRowInset` from the screen's edge, whatever
    /// is in it. The rest of the width is shared evenly, so the middle of three always lands
    /// on the row's centre.
    ///
    /// **Two rows do not come through here yet**: the main menu and the in-game pause row
    /// build their own layouts, and both size their collection view by assigning to
    /// `frame.size.width` - which autolayout overwrites on the next pass, so widening them in
    /// code moves nothing (tried and measured, round 157). Reaching 55pt on those two means
    /// changing the storyboard's width constraint, and the pause row additionally needs
    /// per-cell sizing: its three cells are 75pt boxes holding 50pt icons, so its outer icon
    /// carries 12.5pt of padding the other rows have not got. That is why it sits at 63pt.
    func layoutMenuButtonRow(_ row: UICollectionView, sizes: [CGFloat]) {
        guard sizes.isEmpty == false else { return }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .zero
        // Self-sizing off: with an estimate set, a cell measures itself from its own
        // constraints and the delegate's large button never reaches the layout

        let fromScreen = row.superview?.convert(row.frame.origin, to: nil).x ?? 0
        let inset = max(0, UIViewController.menuButtonRowInset - fromScreen)
        // **One arrangement now** (James, round 157: "everything out to 55pt"). Round 135
        // had two - a row with a big button pulled its small ones in to 55, a row of only
        // small ones went to its own ends - and the second one turned out to mean whatever
        // each screen's container happened to be: 51pt on the menus, 53 on the level list,
        // 55 on the daily. Three values for one promise. Measured from the *screen's* edge,
        // because that is what 55pt is a promise about: where the thumb lands
        let available = row.frame.width - inset*2
        // Measured from the *screen's* edge, not the row's. Some of these rows are inset by
        // their own container and some are not, so insetting each row by the same amount put
        // their close buttons in different places - which is the thing being fixed
        let gaps = max(sizes.count - 1, 1)
        let spacing = max(0, (available - sizes.reduce(0, +))/CGFloat(gaps))

        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        row.collectionViewLayout = layout

        for constraint in row.constraints where constraint.firstAttribute == .height {
            constraint.constant = sizes.max() ?? MainMenuCollectionViewCell.smallButtonSize
        }
        // The row grows to hold its tallest button, which is how a 75pt play button fits a
        // storyboard row built for 50s
    }

    /// Opens that gap on every list in the screen.
    ///
    /// **Spacer views, not a content inset** (round 96). The inset version pinned
    /// `contentOffset` to minus the top inset so the padding would be visible, and that is
    /// the only line in the app that *moves* a scroll view - the settings list stopped
    /// scrolling the round it was added and no amount of work on the affordance, the
    /// gesture, `delaysContentTouches` or the fade brought it back, because none of those
    /// was ever the problem. A header and a footer are inert: they are content, so the list
    /// scrolls exactly as it did before any of this, and the gap comes for free.
    func giveMenuListsBreathingRoom() {
        for table in view.menuLists() {
            defer { table.applyScrollAffordance() }

            table.delaysContentTouches = true
            table.canCancelContentTouches = true
            // The storyboard sets `delaysContentTouches` to NO on these tables, which hands a
            // touch straight to the row it landed on instead of holding it briefly to see
            // whether it becomes a drag. Set here because twelve scenes would each need the
            // same tick, and this is the one place they all pass through

            if table.contentInset != .zero {
                table.contentInset = .zero
                table.contentOffset.y = 0
            }
            // Undoing rounds 74 to 94 on any table that still carries them

            guard table.wantsBreathingRoom, table.wearsGlassPanel == false else { continue }
            // Not the tables that wear a panel: a panel stays put while its rows move, so
            // padding inside one only slides the rows down inside the card

            let top = UIViewController.menuListBreathingRoom.top
            let bottom = UIViewController.menuListBreathingRoom.bottom
            if table.tableHeaderView == nil {
                table.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: top))
            }
            if table.tableFooterView == nil {
                table.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: bottom))
            }
            // Sized by frame rather than by constraint, which is what a table header wants -
            // an autolayout header needs a self-sizing pass this does not need to spend
        }
    }

    /// Centres the menu's contents within `menuMaximumSize`, leaving its background alone.
    ///
    /// Call from `viewDidLayoutSubviews`: the inset depends on the size the view has been
    /// given, which is not known before then, and it must be recomputed if that changes.
    func limitMenuContentSize() {
        keepReturnToGameButtonFrontmost()
        giveMenuListsBreathingRoom()
        // Every menu screen calls this from viewDidLayoutSubviews, which makes it the one
        // place that runs on every layout of every screen - so it carries the return-to-game
        // button's re-fronting too. See keepReturnToGameButtonFrontmost for why it needs one

        guard traitCollection.horizontalSizeClass == .regular else {
            // Phones are already smaller than the limit in width, and capping their
            // height only pushes a row below the fold. The limit is for iPad.
            if additionalSafeAreaInsets != .zero { additionalSafeAreaInsets = .zero }
            return
        }

        let available = view.bounds.size
        let horizontal = max(0, (available.width - UIViewController.menuMaximumSize.width)/2)
        let vertical = max(0, (available.height - UIViewController.menuMaximumSize.height)/2)

        // Only make up the difference. Menus open on top of one another as child view
        // controllers filling their parent, so a child inherits the inset its parent
        // already applied - and adding the full amount again on top halved the content at
        // every level down. Subtracting what is already there makes this idempotent
        // however deep the stack goes.
        let inherited = UIEdgeInsets(
            top: view.safeAreaInsets.top - additionalSafeAreaInsets.top,
            left: view.safeAreaInsets.left - additionalSafeAreaInsets.left,
            bottom: view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom,
            right: view.safeAreaInsets.right - additionalSafeAreaInsets.right)

        let wanted = UIEdgeInsets(top: max(0, vertical - inherited.top),
                                  left: max(0, horizontal - inherited.left),
                                  bottom: max(0, vertical - inherited.bottom),
                                  right: max(0, horizontal - inherited.right))

        guard additionalSafeAreaInsets != wanted else { return }
        // Setting this triggers another layout pass, so assigning unconditionally would
        // loop for as long as the screen is on
        additionalSafeAreaInsets = wanted
    }
}

extension UIView {

    /// Every table in this screen, however deep it is nested.
    ///
    /// Tables only. The round buttons along the bottom are a collection view and want no
    /// padding at all - they are a row of three, not a list - and the daily's pager is a
    /// collection view whose whole point is that a page fills it.
    /// Whether this list may scroll at all.
    ///
    /// Off for a table sized to hold everything it will ever have - the two-item Mode Select
    /// chooser - where any give at all is a list wobbling for no reason (round 96).
    var wantsScrolling: Bool {
        get { (objc_getAssociatedObject(self, &UIView.scrollingKey) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &UIView.scrollingKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private static var scrollingKey = 0

    /// Whether this list wants the menus' padding.
    ///
    /// Off for a table whose height is worked out from its rows: padding it makes it
    /// overflow the height that was calculated to hold it exactly, which is how the two-item
    /// Mode Select chooser grew a scroll bar, and then - once its height counted the padding
    /// too - climbed 144 points up the screen into the sentence above it (round 95).
    var wantsBreathingRoom: Bool {
        get { (objc_getAssociatedObject(self, &UIView.breathingRoomKey) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &UIView.breathingRoomKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private static var breathingRoomKey = 0

    /// Whether a `addGlass(under:)` panel is sitting behind this view.
    var wearsGlassPanel: Bool {
        superview?.subviews.contains {
            $0 is UIVisualEffectView && $0.tag == SettingsTableViewCell.glassPanelTag
        } ?? false
    }

    func menuLists() -> [UITableView] {
        if let table = self as? UITableView { return [table] }
        return subviews.flatMap { $0.menuLists() }
    }
}
