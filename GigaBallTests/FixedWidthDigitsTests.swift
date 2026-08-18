//
//  FixedWidthDigitsTests.swift
//  GigaBallTests
//
//  Play-test round 18: "The score is dancing around a bit as it changes. I guess this font
//  that's being used is not a fixed width font."
//  Round 19: "Classic mode score is still dancing around and the space between the numbers
//  in the score and the multiplier looks weird."
//

import XCTest
import UIKit
import SpriteKit
@testable import Giga_Ball

final class FixedWidthDigitsTests: XCTestCase {

    /// The HUD's face, which is the one the report was about. Falls back to the system font
    /// so the tests still say something on a machine where the bundle font is not loaded.
    private var hudFont: UIFont {
        UIFont(name: "FugazOne-Regular", size: 24) ?? .systemFont(ofSize: 24)
    }

    func testTheDigitsAreNotTheSameWidthToStartWith() {
        // The premise of the fix. If this ever stops being true the columns are doing
        // nothing, and every test below would pass for the wrong reason
        let font = hudFont
        let plain = (0...9).map { digit in
            ("\(digit)" as NSString).size(withAttributes: [.font: font]).width
        }
        XCTAssertGreaterThan(Set(plain.map { ($0*100).rounded() }).count, 1,
                             "the HUD font's digits differ in width - that is the bug")
    }

    func testEveryDigitGetsTheSameColumn() {
        let font = hudFont
        let widths = (0...9).map { FixedWidthDigits.layout("\($0)", font: font).width }
        guard let widest = widths.max(), let narrowest = widths.min() else {
            return XCTFail("no digits measured")
        }
        XCTAssertEqual(widest, narrowest, accuracy: 0.01)
    }

    func testANumberIsAsWideAsItsDigitCountWhateverTheDigitsAre() {
        // The report in its own terms: a score ticking from 111 to 999 must not move
        let font = hudFont
        XCTAssertEqual(FixedWidthDigits.layout("111", font: font).width,
                       FixedWidthDigits.layout("999", font: font).width, accuracy: 0.01)
    }

    func testEveryDigitStaysWhereItWasWhenAnotherDigitChanges() {
        // The dancing itself: 100 becoming 199 must leave the leading 1 exactly where it is
        let font = hudFont
        let before = FixedWidthDigits.layout("100", font: font).centres
        let after = FixedWidthDigits.layout("199", font: font).centres
        XCTAssertEqual(before, after)
    }

    func testTheColumnsAreEvenlySpaced() {
        // Round 19 also called the gaps weird. Equal columns means equal gaps
        let font = hudFont
        let centres = FixedWidthDigits.layout("1234", font: font).centres
        let steps = zip(centres, centres.dropFirst()).map { $1 - $0 }
        for step in steps {
            XCTAssertEqual(step, steps[0], accuracy: 0.01)
        }
    }

    func testNonDigitsKeepTheirOwnWidth() {
        // Only the characters that change from frame to frame get a column. Giving the "m"
        // of a height or the "x" of a multiplier one would put a gap in the middle of it
        let font = hudFont
        let em = ("m" as NSString).size(withAttributes: [.font: font]).width
        let withUnit = FixedWidthDigits.layout("7m", font: font).width
        let digitOnly = FixedWidthDigits.layout("7", font: font).width
        XCTAssertEqual(withUnit - digitOnly, em, accuracy: 0.01)
    }

    func testACharacterIsCentredInItsOwnColumn() {
        let font = hudFont
        let column = FixedWidthDigits.columnWidth(in: font)
        XCTAssertEqual(FixedWidthDigits.layout("8", font: font).centres.first, column/2)
    }

    func testAnEmptyNumberIsEmptyRatherThanACrash() {
        let placed = FixedWidthDigits.layout("", font: hudFont)
        XCTAssertTrue(placed.centres.isEmpty)
        XCTAssertEqual(placed.width, 0)
    }
}

/// The strip of character nodes a HUD number is drawn with.
///
/// Round 122 reported a Classic pack showing two scores drawn over each other, and three
/// sessions failed to reproduce it. Round 184 gave it a repro at last - "I had paused and left
/// the app a number of times, but not quit" - and with it the mechanism: the strip kept a
/// stored array of its character nodes *beside* the children those nodes actually were, and
/// anything that restored the children without the array left `show` unable to see them.
final class FixedWidthNumberNodeTests: XCTestCase {

    private func strip() -> FixedWidthNumberNode {
        let node = FixedWidthNumberNode()
        node.show("1234", fontNamed: "Helvetica", fontSize: 20, colour: .white,
                  alignment: .center, verticalAlignment: .baseline)
        return node
    }

    func testItDrawsOneNodePerCharacter() {
        XCTAssertEqual(strip().children.count, 4)
    }

    func testWritingAgainReusesTheSameNodes() {
        let node = strip()
        node.show("5678", fontNamed: "Helvetica", fontSize: 20, colour: .white,
                  alignment: .center, verticalAlignment: .baseline)
        XCTAssertEqual(node.children.count, 4, "reused, not stacked")
    }

    func testAShorterNumberHidesTheSparesRatherThanStackingThem() {
        let node = strip()
        node.show("7", fontNamed: "Helvetica", fontSize: 20, colour: .white,
                  alignment: .center, verticalAlignment: .baseline)

        XCTAssertEqual(node.children.count, 4)
        let showing = node.children.compactMap { $0 as? SKLabelNode }.filter { !$0.isHidden }
        XCTAssertEqual(showing.count, 1, "one digit visible, three spares waiting")
    }

    /// The bug itself: a strip whose children exist but whose bookkeeping does not.
    ///
    /// Adding the children by hand is exactly the state a decode leaves behind - the nodes
    /// are there, the plain Swift array that used to track them is not. Before round 184 the
    /// next write built a second set on top of these and both drew the same digits.
    func testAStripThatFindsItsChildrenAlreadyThereDoesNotDoubleThem() {
        let node = FixedWidthNumberNode()
        for _ in 0..<4 {
            let label = SKLabelNode(fontNamed: "Helvetica")
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .baseline
            node.addChild(label)
        }

        node.show("1234", fontNamed: "Helvetica", fontSize: 20, colour: .white,
                  alignment: .center, verticalAlignment: .baseline)

        XCTAssertEqual(node.children.count, 4,
                       "four characters, four nodes - not eight in the same place")
    }

    func testTheRestoredNodesAreTheOnesThatGetTheDigits() {
        let node = FixedWidthNumberNode()
        let label = SKLabelNode(fontNamed: "Helvetica")
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .baseline
        node.addChild(label)

        node.show("9", fontNamed: "Helvetica", fontSize: 20, colour: .white,
                  alignment: .center, verticalAlignment: .baseline)

        XCTAssertEqual(label.text, "9", "written into what was already there")
        XCTAssertFalse(label.isHidden)
    }
}
