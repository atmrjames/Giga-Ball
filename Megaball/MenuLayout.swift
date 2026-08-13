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
    static let menuListBreathingRoom = UIEdgeInsets(top: 32, left: 0, bottom: 96, right: 0)
    // **Ninety-six at the bottom** (round 94). A table's frame stops above the button row, so
    // twenty-four points of padding left a last row that could only just be reached - and a
    // list with less than a row's worth of travel reads as one that does not scroll at all.
    // The bottom inset is the one lever that adds travel without needing a constraint in
    // twelve storyboard scenes, and James's call was to err towards more scrolling: the last
    // row now comes up well clear of the buttons instead of stopping under them

    /// Opens that gap on every list in the screen.
    ///
    /// More at the bottom than the top, because the bottom has the round buttons sitting
    /// under it and the top only has a title.
    func giveMenuListsBreathingRoom() {
        for table in view.menuLists() {
            defer { table.applyScrollAffordance() }

            table.delaysContentTouches = true
            table.canCancelContentTouches = true
            // **The last thing between a finger and a scroll.** The storyboard sets
            // `delaysContentTouches` to NO on these tables, which hands a touch straight to
            // the row it landed on instead of holding it briefly to see whether it becomes a
            // drag - so a drag that *starts on a cell*, which is every drag on a list of
            // full-width cells, can be owned by the cell rather than by the scroll view.
            // Set here rather than in the storyboard because twelve scenes would each need
            // the same tick, and this is the one place they all pass through (round 89).
            //
            // The gesture was ruled out first, with a log: the back swipe is asked whether
            // to begin on a vertical drag and correctly answers no.
            // **Every pass, for every list.** The affordance decides whether a table may
            // scroll, and judging it once - at the moment the inset was set, before the rows
            // existed - decided "it fits" and switched scrolling off for good on any table
            // that is not a `ContentAwareTableView` recomputing it for itself. That is the
            // Settings screen unable to reach Reset Ball (round 78)

            guard table.wearsGlassPanel == false,
                  table.contentInset != UIViewController.menuListBreathingRoom else { continue }
            // **Not the tables that wear a panel.** A content inset moves the rows *within*
            // the table, which is the whole point on a list of separate cards - and exactly
            // wrong where the table has one glass panel behind it, because the panel stays
            // put and the rows slide down inside it. Worse on a table sized for a fixed
            // number of rows, like the pack header's two, where the padding pushed the
            // second row out of the frame altogether (round 76). Those screens get their
            // air from the panel instead, which `fitGlassPanel` moves
            table.contentInset = UIViewController.menuListBreathingRoom
            if table.contentOffset.y <= 0 {
                table.contentOffset.y = -UIViewController.menuListBreathingRoom.top
            }
            // **The offset has to move with the inset.** These tables set
            // `contentInsetAdjustmentBehavior = .never`, and a scroll view left at offset
            // zero simply gains scrollable room above the content rather than moving it -
            // so the padding was there and invisible. Only when the list is at the top: a
            // list already scrolled must stay where the finger left it
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
