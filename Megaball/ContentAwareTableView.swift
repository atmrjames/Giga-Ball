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
        // Judge against the frame itself. Measuring against the frame less the adjusted
        // content inset counted the safe-area padding as content that did not fit, so a
        // list whose rows were all visible still had a few points of scroll in it - and
        // with alwaysBounceVertical set in the storyboard, that read as a list that
        // scrolls for no reason.
        let overflows = contentSize.height > bounds.height + 0.5

        isScrollEnabled = overflows
        showsVerticalScrollIndicator = overflows
        alwaysBounceVertical = overflows
        // Otherwise a list that fits still rubber-bands, which looks like it scrolls

        indicatorStyle = .white
        // The menus are dark, and the default indicator is nearly invisible on them
    }
}

final class ContentAwareTableView: UITableView {

    override func awakeFromNib() {
        super.awakeFromNib()
        contentInsetAdjustmentBehavior = .never
        // These tables sit inside a container that already keeps clear of the safe area,
        // so an adjusted inset on top of that is padding nothing and only muddies the
        // question of whether the content fits
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyScrollAffordance()
    }
}
