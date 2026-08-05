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

    /// Centres the menu's contents within `menuMaximumSize`, leaving its background alone.
    ///
    /// Call from `viewDidLayoutSubviews`: the inset depends on the size the view has been
    /// given, which is not known before then, and it must be recomputed if that changes.
    func limitMenuContentSize() {
        guard traitCollection.horizontalSizeClass == .regular else {
            // Phones are already smaller than the limit in width, and capping their
            // height only pushes a row below the fold. The limit is for iPad.
            if additionalSafeAreaInsets != .zero { additionalSafeAreaInsets = .zero }
            return
        }

        let available = view.bounds.size
        let horizontal = max(0, (available.width - UIViewController.menuMaximumSize.width)/2)
        let vertical = max(0, (available.height - UIViewController.menuMaximumSize.height)/2)

        let wanted = UIEdgeInsets(top: vertical, left: horizontal,
                                  bottom: vertical, right: horizontal)
        guard additionalSafeAreaInsets != wanted else { return }
        // Setting this triggers another layout pass, so assigning unconditionally would
        // loop for as long as the screen is on
        additionalSafeAreaInsets = wanted
    }
}
