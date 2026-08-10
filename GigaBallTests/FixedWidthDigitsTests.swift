//
//  FixedWidthDigitsTests.swift
//  GigaBallTests
//
//  Play-test round 18: "The score is dancing around a bit as it changes. I guess this font
//  that's being used is not a fixed width font."
//

import XCTest
import UIKit
@testable import Giga_Ball

final class FixedWidthDigitsTests: XCTestCase {

    /// The HUD's face, which is the one the report was about. Falls back to the system font
    /// so the tests still say something on a machine where the bundle font is not loaded.
    private var hudFont: UIFont {
        UIFont(name: "FugazOne-Regular", size: 24) ?? .systemFont(ofSize: 24)
    }

    func testEveryDigitEndsUpTheSameWidth() {
        let font = hudFont
        let widths = (0...9).map { digit -> CGFloat in
            let line = FixedWidthDigits.attributed("\(digit)", font: font, colour: .white)
            return line.size().width
        }
        guard let widest = widths.max(), let narrowest = widths.min() else {
            return XCTFail("no digits measured")
        }
        XCTAssertEqual(widest, narrowest, accuracy: 0.5,
                       "every digit should occupy the same column once padded")
    }

    func testTheDigitsWereNotTheSameWidthToStartWith() {
        // The premise of the fix. If this ever stops being true the padding is doing
        // nothing, and the test above would pass for the wrong reason
        let font = hudFont
        let plain = (0...9).map { digit in
            ("\(digit)" as NSString).size(withAttributes: [.font: font]).width
        }
        XCTAssertGreaterThan(Set(plain.map { ($0*100).rounded() }).count, 1,
                             "the HUD font's digits differ in width - that is the bug")
    }

    func testANumberIsAsWideAsItsDigitCountWhateverTheDigitsAre() {
        // The report in its own terms: a score ticking from 111 to 999 should not move
        let font = hudFont
        let ones = FixedWidthDigits.attributed("111", font: font, colour: .white).size().width
        let nines = FixedWidthDigits.attributed("999", font: font, colour: .white).size().width
        XCTAssertEqual(ones, nines, accuracy: 0.5)
    }

    func testTheTextItselfIsUnchanged() {
        let line = FixedWidthDigits.attributed("1234m", font: hudFont, colour: .white)
        XCTAssertEqual(line.string, "1234m")
    }

    func testNonDigitsAreLeftAlone() {
        // Only the characters that change from frame to frame are padded. Padding the "m"
        // or the "x" would put a gap in the middle of "x1.0" for no gain
        let font = hudFont
        let line = FixedWidthDigits.attributed("x1.0", font: font, colour: .white)
        var padded: [Int] = []
        line.enumerateAttribute(.kern, in: NSRange(location: 0, length: line.length)) {
            value, range, _ in
            if let kern = value as? CGFloat, kern > 0 { padded.append(range.location) }
        }
        XCTAssertFalse(padded.contains(0), "the x should not be padded")
        XCTAssertFalse(padded.contains(2), "the decimal point should not be padded")
    }
}
