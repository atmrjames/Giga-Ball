//
//  ScreenPresentationTests.swift
//  GigaBallTests
//
//  How a screen is put on top of another, and the one line that must not come back.
//
//  James, round 313, playing in iPadOS 26's windowed mode and dragging the window into every
//  shape it would take: "iPad layouts need work with resizing as there's quite a few issues".
//
//  There is no navigation controller here: a screen is a child view controller whose view is
//  added over the one that opened it. `fillSelf(with:)` is how that view is sized, and it was
//  written in round 188 to replace `child.view.frame = self.view.frame`, which carries two
//  bugs. The frame is measured in the *grandparent's* coordinates, because every screen here
//  is already a subview of another - round 188 measured the result on a 13-inch iPad, a pause
//  screen laid out 420 points wide on a 1032-point window. And a frame assigned once is a
//  frame nothing ever revisits, so a wrong answer sticks rather than being corrected on the
//  next layout pass.
//
//  Round 188 wrote the function and converted one caller. Eighteen were still doing it by
//  hand five rounds later, which is why this test reads the source rather than any one screen:
//  the bug is a line, it can be written again at any time, and on a phone nothing it breaks is
//  ever visible.
//

import XCTest
@testable import Giga_Ball

final class ScreenPresentationTests: XCTestCase {

    private func viewControllerSources() throws -> [(name: String, text: String)] {
        let directory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Megaball/View Controllers")
        let names = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".swift") }.sorted()
        XCTAssertGreaterThan(names.count, 20, "the screens should all be here")
        return try names.map {
            ($0, try String(contentsOf: directory.appendingPathComponent($0), encoding: .utf8))
        }
    }

    /// No screen sizes a child by hand.
    func testEveryScreenIsPresentedThroughFillSelf() throws {
        var byHand: [String] = []
        for file in try viewControllerSources() {
            for (index, line) in file.text.split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated() {
                let text = line.trimmingCharacters(in: .whitespaces)
                guard text.hasPrefix("//") == false else { continue }
                guard text.contains(".view.frame = ") else { continue }
                // `bounds` is the right side of the first bug, and the two sites that use it
                // set the mask themselves - which the next test checks
                guard text.hasSuffix(".bounds") == false else { continue }
                byHand.append("\(file.name):\(index + 1) \(text)")
            }
        }

        XCTAssertEqual(byHand, [],
                       "a child view sized by hand is laid out in the wrong coordinate space "
                       + "and never revisited when the window changes shape - use "
                       + "fillSelf(with:): \n" + byHand.joined(separator: "\n"))
    }

    /// And the two that size a child directly still let it follow the window.
    func testASizedChildAlwaysFollowsItsParent() throws {
        var unmasked: [String] = []
        for file in try viewControllerSources() {
            let lines = file.text.split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
            for (index, line) in lines.enumerated() {
                guard line.contains(".view.frame = "), line.contains(".bounds") else { continue }
                let nextFew = lines[index..<min(index + 3, lines.count)].joined()
                if nextFew.contains("autoresizingMask") == false {
                    unmasked.append("\(file.name):\(index + 1)")
                }
            }
        }

        XCTAssertEqual(unmasked, [],
                       "a frame assigned once is a frame that never changes, and on an iPad "
                       + "the window changes shape under a screen that is already open: "
                       + unmasked.joined(separator: ", "))
    }

    /// `fillSelf` itself, so the three lines that matter cannot be quietly reduced to two.
    func testFillSelfStillDoesAllThreeThings() throws {
        let source = try String(
            contentsOf: URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent().deletingLastPathComponent()
                .appendingPathComponent("Megaball/MenuLayout.swift"), encoding: .utf8)
        guard let body = source.range(of: "func fillSelf(with child: UIView) {") else {
            return XCTFail("fillSelf has gone")
        }
        let text = String(source[body.upperBound...].prefix(400))

        XCTAssertTrue(text.contains("child.transform = .identity"),
                      "a frame set on a transformed view garbles the bounds")
        XCTAssertTrue(text.contains("child.frame = view.bounds"),
                      "bounds, because a frame is measured in the grandparent's coordinates")
        XCTAssertTrue(text.contains("autoresizingMask"),
                      "or the child never follows a window that changes shape")
    }
}
