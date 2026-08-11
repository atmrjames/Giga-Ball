//
//  EdgeFade.swift
//  Megaball
//
//  The soft fade at whichever edge of a scrolling list has more content beyond it.
//
//  A scroll indicator only appears while the list is being touched, so a list sitting still
//  gave no clue that it continued past the bottom of the screen. This does, without taking any
//  space or needing a control.
//
//  Extracted from `ContentAwareTableView` when the pack grid needed the same thing. Two copies
//  of a fade is two fade lengths to keep in step, and a player moving between a list and a grid
//  on adjacent screens would see the difference before they could name it.
//

import UIKit

final class EdgeFade {

    /// How far the content fades at an edge that has more beyond it.
    ///
    /// Deliberately more than half a row, so the fade lands across a cell rather than in the
    /// gap between two - a partly faded row reads as "there is more" without the list having
    /// to move.
    static let length: CGFloat = 48

    /// The height of a pinned section header at the top, kept out of the fade.
    ///
    /// The fade masks the whole layer, and a plain-style table pins its section headers inside
    /// that layer - so the header faded with the rows it was supposed to preside over
    /// (play-test round 10: the sticky headings were "slightly hidden under the scrolling
    /// blur"). A screen with pinned headers declares their height and the top fade starts
    /// below them instead.
    var stickyHeaderBand: CGFloat = 0

    private let mask = CAGradientLayer()

    init() {
        mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor,
                       UIColor.black.cgColor, UIColor.clear.cgColor]
        mask.startPoint = CGPoint(x: 0.5, y: 0)
        mask.endPoint = CGPoint(x: 0.5, y: 1)
        // Masking the content itself rather than laying a coloured overlay on top, so the fade
        // works over whatever background the screen happens to have
    }

    /// Fades whichever edge of this scroll view has more beyond it. Call from `layoutSubviews`.
    func apply(to scrollView: UIScrollView) {
        guard scrollView.isScrollEnabled else {
            scrollView.layer.mask = nil
            return
        }
        scrollView.layer.mask = mask

        let travelled = scrollView.contentOffset.y
        let remaining = scrollView.contentSize.height - scrollView.bounds.height
            - scrollView.contentOffset.y

        // Ease each fade in over its own length rather than switching it on, so nothing pops as
        // the list reaches an end. Bouncing gives negative values; clamping means an
        // overscrolled edge simply reads as fully arrived.
        let top = min(max(travelled, 0), EdgeFade.length)
        let bottom = min(max(remaining, 0), EdgeFade.length)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // The mask follows the content offset every frame, and an implicit animation on that
        // would leave it lagging behind the scroll

        mask.frame = scrollView.bounds
        // A scroll view's bounds origin is its content offset, so the mask tracks the visible
        // area for free

        let height = max(scrollView.bounds.height, 1)
        let band = min(stickyHeaderBand, height/2)
        if band > 0 {
            mask.colors = [UIColor.black.cgColor, UIColor.black.cgColor,
                           UIColor.clear.cgColor, UIColor.black.cgColor,
                           UIColor.black.cgColor, UIColor.clear.cgColor]
            mask.locations = [0,
                              NSNumber(value: Double(band/height)),
                              NSNumber(value: Double(band/height)),
                              NSNumber(value: Double((band + top)/height)),
                              NSNumber(value: Double(1 - bottom/height)),
                              1]
            // The band stays solid for the pinned header; the rows fade in below it, sliding
            // "under" the header rather than through it. With nothing scrolled the middle stops
            // collapse to one point and there is no top fade at all
        } else {
            mask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor,
                           UIColor.black.cgColor, UIColor.clear.cgColor]
            mask.locations = [0,
                              NSNumber(value: Double(top/height)),
                              NSNumber(value: Double(1 - bottom/height)),
                              1]
        }
        CATransaction.commit()
    }
}
