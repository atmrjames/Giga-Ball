//
//  MenuHeaderCollapse.swift
//  Megaball
//
//  The mode logo trading its size for the list's room as the list is dragged up.
//

import CoreGraphics

/// How far a menu's header has been collapsed, and how a drag is shared between the header and
/// the list under it.
///
/// This was `PackSelectViewController`'s alone until round 210, when James asked for the same
/// header on every mode menu and on Information and Settings. The *state* has to be per screen,
/// so this is a small object each screen owns rather than a free function - but the rule it
/// encodes is one rule, and it is the rule that took three rounds to get right.
///
/// **The drag is spent on the header first, and the list does not move until it is done**
/// (James, round 165: "the packs shouldn't start scrolling until the logo has shrunk down to
/// its smallest size"). The first version read the collapse straight off `contentOffset`, so
/// the two happened at once - and because the list is pinned to the header's bottom, the list
/// then travelled at the finger's speed *plus* the speed the header was giving room back at,
/// about 1.8 points for every one dragged. A list that outruns the thumb pushing it is what
/// "doesn't work well" meant.
struct MenuHeaderCollapse {

    /// The logo's size when nothing has been dragged, and when the header is fully collapsed.
    let restSize: CGFloat
    let scrolledSize: CGFloat

    /// How far it has collapsed, in points, out of `travel`.
    private(set) var collapsed: CGFloat = 0

    init(restSize: CGFloat, scrolledSize: CGFloat) {
        self.restSize = restSize
        self.scrolledSize = scrolledSize
    }

    /// The height the header has to give.
    var travel: CGFloat { max(0, restSize - scrolledSize) }

    /// What the logo should be right now.
    var size: CGFloat { restSize - collapsed }

    /// Whether the header is holding any of the list's room open.
    var isCollapsing: Bool { collapsed > 0 }

    /// Takes a drag and reports whether the list should be held at its top.
    ///
    /// - Parameter tried: how far past the top of the list the drag has asked to go. Positive
    ///   is dragging up, negative is pulling back down.
    /// - Returns: true while the header is still absorbing the drag, which is the caller's
    ///   signal to put `contentOffset` back. The gesture keeps pushing, so the collapse keeps
    ///   advancing, and it unwinds the same way when the drag comes back down.
    mutating func absorb(tried: CGFloat) -> Bool {
        if tried > 0, collapsed < travel {
            collapsed = min(travel, collapsed + tried)
            return true
        }
        if tried < 0, collapsed > 0 {
            collapsed = max(0, collapsed + tried)
            return true
        }
        return false
    }

    /// Back to full size, for a screen being shown again.
    mutating func reset() { collapsed = 0 }
}
