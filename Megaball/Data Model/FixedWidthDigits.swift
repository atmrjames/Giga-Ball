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

    /// The same columns as text a label or a drawn string can carry (James, 1.3 play test:
    /// "Used fixed width numbers in the leaderboard for the rank and score so the numbers
    /// align"). A board's places and scores are Fugaz One too, and a 1 is narrower than a 0, so
    /// 2263 over 2094 did not line up digit for digit.
    ///
    /// UIKit honours `.kern` where `SKLabelNode` did not (round 19), so here the columns are
    /// spacing: each digit is followed by the rest of its own column's spare width and the
    /// leading half of the next one's, which centres every digit in a column of the widest
    /// digit's width. The first digit's leading half has no character before it to follow, so
    /// it is the paragraph's indent - which keeps the string the number and nothing else, for
    /// anything that reads a label's text. Not for text set to the right, whose digits are placed
    /// from the right-hand end and need nothing in front of them; and measure left-set text with
    /// `layout(_:font:)`, because `size()` leaves the indent out.
    static func attributed(_ text: String,
                           attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        guard let font = attributes[.font] as? UIFont, text.isEmpty == false else {
            return NSAttributedString(string: text, attributes: attributes)
        }
        let column = columnWidth(in: font)
        let spare = text.map { $0.isNumber ? column - width(of: $0, in: font) : 0 }
        let paragraph = (attributes[.paragraphStyle] as? NSParagraphStyle)?
            .mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        if paragraph.alignment != .right { paragraph.firstLineHeadIndent += spare[0]/2 }
        let result = NSMutableAttributedString()
        for (index, character) in text.enumerated() {
            var these = attributes
            these[.paragraphStyle] = paragraph
            let next = index + 1 < spare.count ? spare[index + 1]/2 : 0
            these[.kern] = spare[index]/2 + next
            result.append(NSAttributedString(string: String(character), attributes: these))
        }
        return result
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
