//
//  ContentAwareTableView.swift
//  Megaball
//
//  A table view that only scrolls when it has more content than fits, and says so — with
//  a scroll indicator while the finger is down, and a soft fade at whichever edge has
//  content beyond it.
//
//  Every table in the app had its indicator switched off in the storyboard, which is
//  right for the ones whose content fits - a permanent scrollbar on a seven-row settings
//  list is noise - but wrong for the ones that overflow, where nothing on screen suggests
//  there is more below. The indicator alone only helps while the list is being touched;
//  a list sitting still still looked like it ended where the screen did.
//
//  Deciding per screen would mean remembering to revisit it every time a row is added,
//  which is exactly the kind of thing that goes stale. This decides from the content, on
//  every layout pass and every scroll, so it stays right as rows come and go and across
//  device sizes.
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

    /// How far the content fades at an edge that has more beyond it.
    ///
    /// Deliberately more than half a row, so the fade lands across a cell rather than in
    /// the gap between two - a partly faded row reads as "there is more" without the list
    /// having to move.
    private static let fadeLength: CGFloat = 48

    /// The height of a pinned section header at the top, kept out of the fade.
    ///
    /// The fade masks the table's whole layer, and a plain-style table pins its section
    /// headers inside that layer - so the header faded with the rows it was supposed to
    /// preside over (play-test round 10: the sticky headings were "slightly hidden under
    /// the scrolling blur"). A screen with pinned headers declares their height here and
    /// the top fade starts below them instead.
    var stickyHeaderBand: CGFloat = 0

    private let fadeMask = CAGradientLayer()

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        configure()
    }
    // Both births: the storyboard tables arrive through awakeFromNib, and the endless
    // run history is built in code - which used to mean an unconfigured fade mask, and a
    // gradient layer with no colours masks everything away

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func configure() {
        contentInsetAdjustmentBehavior = .never
        // These tables sit inside a container that already keeps clear of the safe area,
        // so an adjusted inset on top of that is padding nothing and only muddies the
        // question of whether the content fits

        fadeMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor,
                           UIColor.black.cgColor, UIColor.clear.cgColor]
        fadeMask.startPoint = CGPoint(x: 0.5, y: 0)
        fadeMask.endPoint = CGPoint(x: 0.5, y: 1)
        // Masking the content itself rather than laying a coloured overlay on top, so the
        // fade works over whatever background the screen happens to have
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyScrollAffordance()
        updateEdgeFades()
    }

    /// Fades the content at whichever edge has more beyond it.
    ///
    /// A scroll indicator only appears while the list is being touched, so a list sitting
    /// still gave no clue that it continued past the bottom of the screen. This does,
    /// without taking any space or needing a control.
    private func updateEdgeFades() {
        guard isScrollEnabled else {
            layer.mask = nil
            return
        }
        layer.mask = fadeMask

        let travelled = contentOffset.y
        let remaining = contentSize.height - bounds.height - contentOffset.y

        // Ease each fade in over its own length rather than switching it on, so nothing
        // pops as the list reaches an end. Bouncing gives negative values; clamping means
        // an overscrolled edge simply reads as fully arrived.
        let top = min(max(travelled, 0), ContentAwareTableView.fadeLength)
        let bottom = min(max(remaining, 0), ContentAwareTableView.fadeLength)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        // The mask follows the content offset every frame, and an implicit animation on
        // that would leave it lagging behind the scroll

        fadeMask.frame = bounds
        // A scroll view's bounds origin is its content offset, so the mask tracks the
        // visible area for free

        let height = max(bounds.height, 1)
        let band = min(stickyHeaderBand, height/2)
        if band > 0 {
            fadeMask.colors = [UIColor.black.cgColor, UIColor.black.cgColor,
                               UIColor.clear.cgColor, UIColor.black.cgColor,
                               UIColor.black.cgColor, UIColor.clear.cgColor]
            fadeMask.locations = [0,
                                  NSNumber(value: Double(band/height)),
                                  NSNumber(value: Double(band/height)),
                                  NSNumber(value: Double((band + top)/height)),
                                  NSNumber(value: Double(1 - bottom/height)),
                                  1]
            // The band stays solid for the pinned header; the rows fade in below it,
            // sliding "under" the header rather than through it. With nothing scrolled
            // the middle stops collapse to one point and there is no top fade at all
        } else {
            fadeMask.colors = [UIColor.clear.cgColor, UIColor.black.cgColor,
                               UIColor.black.cgColor, UIColor.clear.cgColor]
            fadeMask.locations = [0,
                                  NSNumber(value: Double(top/height)),
                                  NSNumber(value: Double(1 - bottom/height)),
                                  1]
        }
        CATransaction.commit()
    }
}
