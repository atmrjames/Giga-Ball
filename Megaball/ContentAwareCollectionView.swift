//
//  ContentAwareCollectionView.swift
//  Megaball
//
//  What `ContentAwareTableView` is, for a grid.
//
//  The pack screen became a grid of squares (play-test round 29) and immediately wanted the
//  two things every scrolling list on these menus already has: a scroll indicator that is
//  visible against a dark menu, and a soft fade at whichever edge has more content beyond it.
//  A grid that continues past the bottom of the screen and gives no sign of it is worse than a
//  list that does, because a grid *looks* like it was laid out to fit.
//
//  The fade itself lives in `EdgeFade`, shared with the table, so the two cannot drift into
//  fading by different amounts on screens a player moves between.
//

import UIKit

final class ContentAwareCollectionView: UICollectionView {

    private let fade = EdgeFade()

    /// The height of a pinned section header, kept out of the edge fade.
    ///
    /// The fade masks the whole layer, and a pinned header lives inside that layer - so
    /// without this the heading fades along with the squares it is presiding over, which is
    /// the play test's "sticky headers going under blur when scrolled" (round 81). The
    /// tables have carried the same property since the power-up rows first pinned theirs.
    var stickyHeaderBand: CGFloat {
        get { fade.stickyHeaderBand }
        set { fade.stickyHeaderBand = newValue }
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        contentInsetAdjustmentBehavior = .never
        indicatorStyle = .white
        showsVerticalScrollIndicator = true
        // The container already keeps clear of the safe area, so an adjusted inset on top of
        // that pads nothing and only muddies the question of whether the content fits
    }

    /// Whether this grid must keep taking drags even when everything fits.
    ///
    /// **For a grid that made itself fit.** The pack screen spends the first part of a drag
    /// collapsing its logo, and the room that frees is exactly what lets all eleven packs fit -
    /// at which point the rule below switches scrolling off, the drag stops being reported, and
    /// the logo can never grow back (round 165, found by dragging back down and watching
    /// nothing happen). A grid that has swallowed a header has to keep listening, or the
    /// gesture is a one-way door.
    var keepsTakingDrags = false {
        didSet { setNeedsLayout() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isScrollEnabled = keepsTakingDrags || contentSize.height > bounds.height + 0.5
        alwaysBounceVertical = keepsTakingDrags
        // Bounce as well as scroll: with the content fitting there is nowhere to scroll *to*,
        // and without the bounce a downward drag reports nothing at all
        // A grid that fits does not scroll, so it cannot be dragged out from under its own
        // title and left hanging - the same bargain the tables make

        fade.apply(to: self)
    }
}
