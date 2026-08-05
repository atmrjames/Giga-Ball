//
//  ContentAwareTableView.swift
//  Megaball
//
//  A table view that only scrolls, and only shows a scroll indicator, when it actually
//  has more content than fits.
//
//  Every table in the app had its indicator switched off in the storyboard, which is
//  right for the ones whose content fits - a permanent scrollbar on a seven-row settings
//  list is noise - but wrong for the ones that overflow, where nothing on screen suggests
//  there is more below. The settings list crossing onto a second screen is what surfaced
//  it, and the level and pack lists have always had the same problem.
//
//  Deciding per screen would mean remembering to revisit it every time a row is added,
//  which is exactly the kind of thing that goes stale. This decides from the content, on
//  every layout pass, so it stays right as rows come and go and across device sizes.
//

import UIKit

extension UIScrollView {

    /// Matches scrolling and the scroll indicator to whether the content overflows.
    func applyScrollAffordance() {
        // A hair of tolerance: content that fits exactly should not count as overflowing,
        // and heights land on fractional values often enough to matter.
        let overflows = contentSize.height > bounds.height - adjustedContentInset.top
            - adjustedContentInset.bottom + 0.5

        isScrollEnabled = overflows
        showsVerticalScrollIndicator = overflows
        indicatorStyle = .white
        // The menus are dark, and the default indicator is nearly invisible on them
    }
}

final class ContentAwareTableView: UITableView {

    override func layoutSubviews() {
        super.layoutSubviews()
        applyScrollAffordance()
    }
}
