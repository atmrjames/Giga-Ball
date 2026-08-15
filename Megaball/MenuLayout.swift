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

extension UIViewController {

    /// The most screen a menu should use, whatever it has been given.
    ///
    /// Roughly a large phone. Past this the rows stop reading as a list and start reading
    /// as a table of contents with the labels and values at opposite ends of the screen.
    static let menuMaximumSize = CGSize(width: 500, height: 820)

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

    /// **The one button-row arrangement.** Outer buttons this far in from the row's edges.
    ///
    /// Every menu screen used to work its own spacing out, and they disagreed: some spread
    /// three cells across the whole width, which put the close button hard against the edge,
    /// and others sat them close in. Mixed together the wide ones read as a different app
    /// (play-test round 128). The narrow arrangement is the one that stays.
    static let menuButtonRowInset: CGFloat = 55

    /// Lays a screen's button row out the shared way.
    ///
    /// - Parameter sizes: each button's width, in the order they appear. The row is always
    ///   three cells - some of them the invisible `ButtonNull` spacer - so what differs
    ///   between screens is only which of the three is the large one.
    ///
    /// The outer two land `menuButtonRowInset` from the row's own edges and the rest of the
    /// width is shared evenly between them, so a screen with a large centre button and a
    /// screen with three small ones still put their close buttons in the same place.
    func layoutMenuButtonRow(_ row: UICollectionView, sizes: [CGFloat]) {
        guard sizes.isEmpty == false else { return }
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = .zero
        // Self-sizing off: with an estimate set, a cell measures itself from its own
        // constraints and the delegate's large button never reaches the layout

        let fromScreen = row.superview?.convert(row.frame.origin, to: nil).x ?? 0
        let inset = max(0, UIViewController.menuButtonRowInset - fromScreen)
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
