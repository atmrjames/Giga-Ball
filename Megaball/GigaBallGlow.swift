//
//  GigaBallGlow.swift
//  Megaball
//
//  The green halo the game's own words wear.
//
//  A layer shadow in the Giga-Ball green, offset nowhere. The offset is the whole
//  difference between a glow and a shadow: the first version carried the pause screen's
//  downward offset onto the main menu's wordmark, and on a word that wide a one-directional
//  blur reads as motion blur - the logo looks like it is sliding sideways rather than
//  lighting up. Centred, it radiates evenly and reads as light coming off the letters.
//
//  Kept in one place because it is applied to five different things - the two logos and the
//  PAUSED / GAME OVER / COMPLETE headings - and five copies of the same four numbers is four
//  chances for them to drift apart.
//

import UIKit

extension UIView {

    /// The Giga-Ball green glow, radiating evenly from whatever it is applied to.
    ///
    /// `radius` is in points and scales with the thing glowing: a 35pt heading wants less
    /// spread than a full-width wordmark, or the halo stops belonging to the letters.
    func applyGigaBallGlow(radius: CGFloat = 14, opacity: Float = 0.45) {
        layer.shadowColor = GigaBallGlow.colour.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
        // A label or image view that clips has nowhere to put a halo
    }
}

enum GigaBallGlow {
    /// The same green the mode uses for everything of its own.
    static let colour = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)

    /// What a full-width wordmark wants - the main menu's logo is the width of the screen,
    /// and a tight radius on something that big is invisible at the ends and heavy in the
    /// middle.
    static let wordmarkRadius: CGFloat = 22

    /// What a heading wants: PAUSED, GAME OVER, COMPLETE.
    static let headingRadius: CGFloat = 12
}
