//
//  FixedWidthDigits.swift
//  Megaball
//
//  Numbers that stay still while they change.
//
//  The HUD is set in Fugaz One, which is a display face and has no tabular figures: its
//  digits run from 506 units for a "1" to 661 for a "0", a thirty per cent swing. A score
//  ticking upward therefore shuffles sideways on almost every change, which the play test
//  described as the score dancing around (round 18).
//
//  The usual fix is the font's own tabular-figures feature. Fugaz One has no GSUB table at
//  all, so there is nothing to switch on. What is left is to pad each digit out to the
//  width of the widest one, which is what this does - the number is drawn in the same face
//  it always was, and every digit occupies the same column.
//

import UIKit

enum FixedWidthDigits {

    /// `text` in `font`, with each digit padded to the width of the widest digit.
    ///
    /// Only digits are padded. A "m", an "x" or a decimal point keeps its natural width,
    /// because those do not change from one frame to the next and padding them would put
    /// gaps in the middle of "x1.0" for no gain.
    static func attributed(_ text: String, font: UIFont,
                           colour: UIColor) -> NSAttributedString {
        let line = NSMutableAttributedString(
            string: text, attributes: [.font: font, .foregroundColor: colour])

        let widths = widthsOfDigits(in: font)
        guard let widest = widths.values.max() else { return line }

        for (position, character) in text.enumerated() where character.isNumber {
            guard let own = widths[character] else { continue }
            line.addAttribute(.kern, value: widest - own,
                              range: NSRange(location: position, length: 1))
            // Kerning is trailing space, so a narrow digit sits at the left of its column
            // rather than centred in it. At the sizes the HUD uses the difference is under
            // a point, and a number that holds its place is worth more than that
        }
        return line
    }

    /// The ten digit widths in a given font, worked out once per font rather than per frame.
    ///
    /// The score is rewritten on almost every brick, and measuring ten strings each time
    /// was measurable work for an answer that never changes while the font does not.
    private static func widthsOfDigits(in font: UIFont) -> [Character: CGFloat] {
        let key = "\(font.fontName)-\(font.pointSize)"
        if let known = cache[key] { return known }

        var widths: [Character: CGFloat] = [:]
        for digit in "0123456789" {
            widths[digit] = (String(digit) as NSString)
                .size(withAttributes: [.font: font]).width
        }
        cache[key] = widths
        return widths
    }

    private static var cache: [String: [Character: CGFloat]] = [:]
}
