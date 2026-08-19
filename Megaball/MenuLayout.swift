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

    /// The squarest a menu is allowed to be: width divided by height.
    ///
    /// **The shape is what is capped, not the size** (James, round 182: "for the iPad, it's
    /// not the overall size that should be capped, it's the ratio of width to height. It's ok
    /// to make the app slightly more square than the phone is, but not much more square").
    ///
    /// Phones run from 0.46 (iPhone 17 Pro) to 0.56 (the SE); a 13-inch iPad in portrait is
    /// 0.75, which is a different-shaped app rather than the same one bigger. This sits just
    /// past the squarest phone - recognisably the same layout, with the extra width an iPad
    /// has to spare, and none of the height given away.
    ///
    /// Round 180's `menuMaximumSize` of 500x820 capped both directions, which centred a
    /// phone-sized box in the middle of a 13-inch screen and left 40% of the height empty
    /// while the pack grid scrolled with two packs hidden. Its *ratio* was 0.61, so the shape
    /// was never the problem - only the absolute cap on height was.
    static let menuMaximumAspectRatio: CGFloat = 0.62

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

    /// Where a small button sits when there is no large one to group around.
    ///
    /// **The wide arrangement**, for the screens whose button row is small buttons only -
    /// Settings, Information, the pack grid, Statistics - and for the two screens that build a
    /// close button by hand rather than taking the shared row.
    ///
    /// It was only the second of those until round 169: `layoutMenuButtonRow` had put every
    /// row out to `menuButtonRowInset`, which round 157 asked for and round 169 took back for
    /// the rows with nothing in the middle. A close button pulled in to 55pt beside an empty
    /// centre reads as a button that has been moved rather than placed.
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
        let hasLargeButton = sizes.contains { $0 > MainMenuCollectionViewCell.smallButtonSize }
                             || carriesReturnToGameButton
        // **A big button on the screen counts, not only a big button in the row** (James, round
        // 176: "as the pause screen info and settings views (including child views) have a big
        // play button, the small buttons should adopt the narrower position. In the main menu
        // info and settings views, these buttons should adopt the wider position").
        //
        // Settings and Information are one screen each, reached from two places, and the pause
        // versions carry the 75pt play that `ReturnToGameButton` adds. That button is a subview
        // of the screen rather than a cell in this row, so `sizes` cannot see it - which is why
        // both versions had been taking the wide arrangement and the pause ones read as a close
        // button that had wandered away from the play beside it.
        //
        // Asked of the screen rather than passed in by each caller, so it holds for the child
        // views too - the reference pages go three deep, and `pausedGameBehind` is the same walk
        // up the chain that decides whether the play button is there in the first place
        let target = hasLargeButton ? UIViewController.menuButtonRowInset
                                    : UIViewController.menuButtonWideInset
        let inset = max(0, target - fromScreen)
        // **Two arrangements, chosen by what is in the row** (James, round 169: "only views
        // with a big centre button should have the narrower position small buttons").
        //
        // Round 135 had two and picked between them the same way; round 157 collapsed them
        // into one because the *wide* one was not a number at all - it was "the row's own
        // ends", which meant whatever each screen's container happened to be: 51pt on the
        // menus, 53 on the level list, 55 on the daily. Three values for one promise.
        //
        // So this is round 135's rule with round 157's fix kept: still two arrangements, but
        // both are now numbers measured from the *screen's* edge, which is what an inset is a
        // promise about - where the thumb lands. A row with a big centre button draws its
        // small ones in to sit with it; a row of only small buttons spreads to the wide inset,
        // because there is nothing in the middle for them to group around
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

    /// How far in a menu's contents sit, for a window of this size.
    ///
    /// The whole of the resize behaviour, as arithmetic: any width past what
    /// `menuMaximumAspectRatio` allows is split evenly either side, and a window already that
    /// shape or narrower keeps everything it has. Pulled out of `limitMenuContentSize` in
    /// round 181 so the iPad resize audit (§12.0) can be *tested* at the sizes iPadOS hands
    /// out rather than only eyeballed at the two or three a person thinks to try - and those
    /// are the sizes nobody can see: split view, slide over, and the two extremes.
    ///
    /// - Parameter inherited: the safe area the screen already has from its parent. Menus
    ///   open on top of one another as child view controllers filling their parent, so a
    ///   child inherits the inset its parent applied - adding the full amount again on top
    ///   halved the content at every level down. Subtracting what is already there is what
    ///   makes this idempotent however deep the stack goes.
    static func menuContentInsets(available: CGSize,
                                  inherited: UIEdgeInsets = .zero) -> UIEdgeInsets {
        let widest = available.height*menuMaximumAspectRatio
        let horizontal = max(0, (available.width - widest)/2)
        // **Width only, and only when the window is too square.** A window that is *taller*
        // than a phone's shape is not the thing being guarded against - a tall thin slide-over
        // is a narrow phone, which the menus were built for - so nothing is ever taken off the
        // height. That is also what stops the pack grid scrolling with room to spare on an
        // iPad, which capping the height was doing
        return UIEdgeInsets(top: 0,
                            left: max(0, horizontal - inherited.left),
                            bottom: 0,
                            right: max(0, horizontal - inherited.right))
    }

    /// Centres the menu's contents within `menuMaximumAspectRatio`, leaving its background alone.
    ///
    /// Call from `viewDidLayoutSubviews`: the inset depends on the size the view has been
    /// given, which is not known before then, and it must be recomputed if that changes.
    /// Sizes a child screen's view to fill this one, and keeps it filling it.
    ///
    /// **`bounds`, not `frame`.** A view's frame is its rect in its *superview's* coordinates,
    /// and every screen in this app is a child view added over another - so `self.view.frame`
    /// is measured in the grandparent's space and is the wrong rect to hand a child. It is
    /// also the wrong *size* the moment a transform is involved, because a frame is the
    /// transformed bounding box: the pause menu's parallax and the menus' 1.15 dismissal
    /// scale both make it lie. `MenuNavigation` learned this and said so in a comment; the six
    /// older presentation sites never got the fix, and round 188 found the result on an iPad -
    /// the pause screen laid out 420pt wide on a 1032pt screen, Home tucked against the title
    /// instead of in its corner, because `menuContentInsets` had been handed a view roughly
    /// half the screen's height and capped the width against that.
    ///
    /// The autoresizing mask is the other half. A frame assigned once is a frame that never
    /// changes, so nothing triggers the layout pass that would notice a bad one and correct
    /// it - which is why a wrong answer *stuck* rather than being fixed on the next pass. With
    /// the mask the child tracks the parent, on rotation and on an iPad window resize too.
    func fillSelf(with child: UIView) {
        child.transform = .identity
        child.frame = view.bounds
        child.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // The transform first: setting a frame on a transformed view garbles the bounds,
        // which is `MenuNavigation`'s own hard-won note
    }

    /// The size the aspect cap should measure itself against: the **window**, not this view.
    ///
    /// The cap is a shape - width against height - so it has to be given the shape the player
    /// is actually looking at. `view.bounds` is not reliably that: every screen here is a
    /// child view added over another, and a screen presented over the game view gets whatever
    /// rect that view had. Round 188 measured the result on a 13-inch iPad: the pause screen
    /// laid out **420pt wide on a 1032pt window**, which is the cap dividing by a height of
    /// about 677 rather than 1376 - so Home sat beside the title instead of in its corner and
    /// the button row bunched into the middle.
    ///
    /// The window rather than the screen, deliberately: iPadOS 26 hands this app windows it
    /// never asked for (§12.0's resize audit), and the shape to cap is the shape of the window
    /// it has been given. `view.bounds` remains the fallback for a view not yet in a window,
    /// where there is nothing better to ask and the answer is corrected on the next pass.
    var menuAvailableSize: CGSize {
        view.window?.bounds.size ?? view.bounds.size
    }

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

        let inherited = UIEdgeInsets(
            top: view.safeAreaInsets.top - additionalSafeAreaInsets.top,
            left: view.safeAreaInsets.left - additionalSafeAreaInsets.left,
            bottom: view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom,
            right: view.safeAreaInsets.right - additionalSafeAreaInsets.right)
        let wanted = UIViewController.menuContentInsets(available: menuAvailableSize,
                                                        inherited: inherited)

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

    /// How far a card drifts with the tilt of the device, at this width.
    ///
    /// Twenty-five points on a phone and fifty on an iPad, which is the figure sixteen screens
    /// have each written out for themselves since 2019. The bigger screen gets the bigger
    /// travel because the effect is read as a proportion of what is around it: 25 points on an
    /// 11-inch screen is a card that looks like it is not quite still.
    static func parallaxTravel(forWidth width: CGFloat) -> Int {
        width > 450 ? 50 : 25
    }

    /// Makes this view drift with the tilt of the device, replacing any drift it already has.
    ///
    /// **One recipe, at last.** Sixteen screens carry their own copy of these eight lines and
    /// this is the seventeenth caller, so it is written once here rather than once more there;
    /// the sixteen are a sweep for another round, and this is what they would call.
    ///
    /// The old group is removed first, because these screens re-apply on every appearance and
    /// motion effects stack - two groups on one card is a card that drifts twice as far as the
    /// one beside it.
    @discardableResult
    func applyMenuParallax() -> UIMotionEffectGroup {
        for existing in motionEffects where existing is UIMotionEffectGroup {
            removeMotionEffect(existing)
        }
        // All of them, not the first: this runs on every layout pass, and one missed group is
        // a card that drifts twice as far as the screen it is sitting on

        let amount = UIView.parallaxTravel(forWidth: window?.bounds.width ?? bounds.width)
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x",
                                                     type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount
        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y",
                                                   type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        // Measured against the *window*, not this view: the screens that wrote this out for
        // themselves each asked their own full-screen view how wide it was, and a card is a
        // few hundred points narrower than the screen it sits on - asking the card would put
        // an iPad on the phone's travel

        let group = UIMotionEffectGroup()
        group.motionEffects = [horizontal, vertical]
        addMotionEffect(group)
        return group
    }

    /// Every view under this one that is drifting with the tilt, including this one.
    ///
    /// The screens do not all hang their parallax off the same view - the pause menu drifts
    /// its `containterView`, Settings its `backgroundView`, the menus their own - so finding
    /// them is a search rather than a lookup.
    func viewsWithParallax() -> [UIView] {
        let mine = motionEffects.contains { $0 is UIMotionEffectGroup } ? [self] : []
        return mine + subviews.flatMap { $0.viewsWithParallax() }
    }

    /// Takes the drift off, and hands back what to put it back on.
    ///
    /// **A pop-up stands the screen behind it still** (James, round 164). Two layers both
    /// drifting read as one of them coming loose - which is why Settings had been doing this
    /// by hand since long before there was a second pop-up type to do it for. Now the pop-up
    /// does it for whatever raised it, so no screen has to remember.
    static func standDownParallax(under root: UIView) -> [UIView] {
        let drifting = root.viewsWithParallax()
        for view in drifting {
            for effect in view.motionEffects where effect is UIMotionEffectGroup {
                view.removeMotionEffect(effect)
            }
        }
        return drifting
    }
}

extension UICollectionView {

    /// The section inset this collection view's own layout was given.
    ///
    /// **What `insetForSectionAt` should answer for a collection view it is not about.** A
    /// screen with a grid *and* a button row has one delegate serving both, and each of the
    /// three screens that do wrote `guard collectionView == grid else { return .zero }` -
    /// which silently threw away the inset `layoutMenuButtonRow` had just set on the row,
    /// because a delegate's answer beats the layout's own property.
    ///
    /// That is why the pack screen's Game Center button sat 90pt from the right edge while
    /// its close button sat at 20 (James, round 165's screenshot), on a screen rounds 157 and
    /// 158 had supposedly moved out to 55: those rounds set the property, and this delegate
    /// method had been overruling it since long before them.
    ///
    /// Handing back the layout's own value is right for any row - where nothing set one it is
    /// `.zero`, which is what these were returning anyway.
    var ownSectionInset: UIEdgeInsets {
        (collectionViewLayout as? UICollectionViewFlowLayout)?.sectionInset ?? .zero
    }
}
