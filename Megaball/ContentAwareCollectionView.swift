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

    override func layoutSubviews() {
        super.layoutSubviews()
        isScrollEnabled = contentSize.height > bounds.height + 0.5
        // A grid that fits does not scroll, so it cannot be dragged out from under its own
        // title and left hanging - the same bargain the tables make

        fade.apply(to: self)
    }
}
