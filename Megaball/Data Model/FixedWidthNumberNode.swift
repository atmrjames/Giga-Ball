//
//  FixedWidthNumberNode.swift
//  Megaball
//
//  A number drawn one character at a time, so it holds its place while it changes.
//
//  It hangs off the label it replaces rather than replacing it: the HUD's labels come from
//  the scene file with their positions, sizes, colours and alignment already set, and the
//  milestone pulse scales them. A child node inherits all of that - including the scale -
//  so the pulse still works and nothing about the HUD's layout has to be re-derived here.
//

import SpriteKit

final class FixedWidthNumberNode: SKNode {

    private var characters: [SKLabelNode] = []

    /// Draws `text` in the dress of the label this node belongs to.
    ///
    /// Labels are reused between writes. The score changes several times a second, and
    /// building ten nodes each time would be work for no gain - only the ones that changed
    /// are touched.
    func show(_ text: String, fontNamed: String, fontSize: CGFloat, colour: UIColor,
              alignment: SKLabelHorizontalAlignmentMode,
              verticalAlignment: SKLabelVerticalAlignmentMode) {
        guard let font = UIFont(name: fontNamed, size: fontSize) else { return }
        let placed = FixedWidthDigits.layout(text, font: font)

        // Where the whole number starts, so it grows the way its label was aligned to grow
        let start: CGFloat
        switch alignment {
        case .left: start = 0
        case .right: start = -placed.width
        default: start = -placed.width/2
        }

        // Every character sits on the baseline, and the strip as a whole is moved to where
        // the label it replaces would have drawn. Letting each character answer the parent's
        // vertical alignment for itself put the multiplier's decimal point halfway up the
        // number - a full stop centred on its own box is a middle dot (play-test round 19)
        position.y = baselineOffset(for: verticalAlignment, font: font)

        while characters.count < text.count {
            let label = SKLabelNode(fontNamed: fontNamed)
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .baseline
            addChild(label)
            characters.append(label)
        }

        for (index, character) in text.enumerated() {
            let label = characters[index]
            label.isHidden = false
            label.text = String(character)
            label.fontSize = fontSize
            label.fontColor = colour
            label.position.x = start + placed.centres[index]
        }
        for spare in characters.dropFirst(text.count) { spare.isHidden = true }
    }

    /// How far the baseline sits from where the replaced label anchored itself.
    ///
    /// Measured from the digits rather than the font's own ascender and descender: a HUD
    /// number is all capitals and figures, and the font's descender belongs to letters that
    /// never appear in one.
    private func baselineOffset(for alignment: SKLabelVerticalAlignmentMode,
                                font: UIFont) -> CGFloat {
        switch alignment {
        case .top: return -font.capHeight
        case .center: return -font.capHeight/2
        case .bottom: return 0
        default: return 0
        }
    }
}
