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
//  The first attempt padded the digits with kerning inside an attributed string.
//  `SKLabelNode` does not honour `.kern`, so nothing changed on screen and the gaps that
//  did appear looked wrong (round 19). So the digits are placed rather than described: this
//  works out where each character's centre belongs, and `FixedWidthNumberNode` puts a label
//  there. Nothing is left for the text engine to ignore.
//

import UIKit

enum FixedWidthDigits {

    /// Where each character of `text` should sit, measured from the left edge of the whole
    /// number, and how wide the whole number comes to.
    ///
    /// Every digit is given a column the width of the widest digit and centred in it, which
    /// is what tabular figures would have done. Everything else - the "m" of a height, the
    /// "x" and the point of a multiplier - keeps its own width, because those do not change
    /// from one frame to the next.
    static func layout(_ text: String, font: UIFont) -> (centres: [CGFloat], width: CGFloat) {
        let column = columnWidth(in: font)
        var centres: [CGFloat] = []
        var x: CGFloat = 0

        for character in text {
            let cell = character.isNumber ? column : width(of: character, in: font)
            centres.append(x + cell/2)
            x += cell
        }
        return (centres, x)
    }

    /// The width of the widest digit, which is the column every digit gets.
    static func columnWidth(in font: UIFont) -> CGFloat {
        cached(font).values.max() ?? 0
    }

    private static func width(of character: Character, in font: UIFont) -> CGFloat {
        if character.isNumber, let known = cached(font)[character] { return known }
        return (String(character) as NSString).size(withAttributes: [.font: font]).width
    }

    /// The ten digit widths in a given font, worked out once per font rather than per frame.
    ///
    /// The score is rewritten on almost every brick, and measuring ten strings each time was
    /// measurable work for an answer that cannot change while the font does not.
    private static func cached(_ font: UIFont) -> [Character: CGFloat] {
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
