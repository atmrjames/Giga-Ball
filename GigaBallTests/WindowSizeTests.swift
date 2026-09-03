//
//  WindowSizeTests.swift
//  GigaBallTests
//
//  **The iPad audit, as a test rather than a look** (round 301).
//
//  Removing `UIRequiresFullScreen` lets iPadOS hand the app window shapes no device has: a
//  Slide Over column, a third of a split, and anything down to `SceneDelegate`'s 420x640
//  floor. `GameSceneLayoutTests` already proves the *playfield* holds its ratio in all of
//  them - that was never the risk, because the ratio is solved from whatever size it is given.
//  The risk is the **menus**, which are constraint-driven UIKit and have only ever been laid
//  out at phone and full-iPad proportions.
//
//  A screenshot cannot be the check here. The shapes that matter are ones the simulator will
//  not hand you without driving Split View by hand, and "does that text fit" is exactly the
//  question an eye answers badly and a frame comparison answers exactly. So the audit is a
//  walk of the view tree looking for anything that carries information - a label, a button -
//  sitting outside the window it is supposed to be inside.
//
//  **The detector was proved to detect before it was believed.** A test that passes the moment
//  it is written has two explanations and only one of them is good news. Run with a
//  deliberately impossible 120x140 window, it fails and names the day pager's two arrows with
//  their frames - `◀ at {{-105, 59}, {30, 36}}` and the rest - so the walk, the convert and
//  the containment check all work. It found nothing at the real sizes because there is
//  nothing there to find.
//
//  That run also showed the *card* test is the weaker of the two: at 120x140 it still passed,
//  because a card's own labels stay inside the card while it is the container that clips them.
//  It is kept for the case it does cover - a card whose content outgrows itself - and the
//  screen test above is the one that catches a window too small for the layout.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class WindowSizeTests: XCTestCase {

    /// Every shape iPadOS can now give the app, plus the phones for a control.
    ///
    /// The floor is `SceneDelegate`'s minimum window, so nothing smaller has to work. Short
    /// and wide is included even though a portrait-only app should never be given it (James,
    /// round 301: "no landscape"): a layout that survives it survives anything, and if the
    /// orientation decision is ever revisited this row is already here.
    private let windows: [(name: String, size: CGSize)] = [
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("iPhone 17 Pro", CGSize(width: 402, height: 874)),
        ("the minimum window", CGSize(width: 420, height: 640)),
        ("iPad Slide Over", CGSize(width: 375, height: 1133)),
        ("iPad split, one third", CGSize(width: 375, height: 1366)),
        ("iPad split, half", CGSize(width: 507, height: 1366)),
        ("iPad split, two thirds", CGSize(width: 639, height: 1366)),
        ("iPad Pro 13, full screen", CGSize(width: 1032, height: 1376))
    ]

    /// Anything a player has to be able to read, that has ended up outside the window.
    ///
    /// Labels and buttons only. Containers, spacers and shadow-casting wrappers legitimately
    /// overhang - a shadow is drawn outside its own bounds by design - and flagging those
    /// would bury the one finding that matters in noise.
    ///
    /// The tolerance is a point, for the rounding that lands on `.5` at 2x and 3x scales.
    private func clipped(in root: UIView) -> [String] {
        var found: [String] = []
        func walk(_ view: UIView) {
            for child in view.subviews {
                if child.isHidden == false, child.alpha > 0.01,
                   child is UILabel || child is UIButton {
                    let frame = child.convert(child.bounds, to: root)
                    if frame.width > 0, frame.height > 0,
                       root.bounds.insetBy(dx: -1, dy: -1).contains(frame) == false {
                        let what = (child as? UILabel)?.text
                            ?? (child as? UIButton)?.title(for: .normal)
                            ?? String(describing: type(of: child))
                        found.append("\(what) at \(NSCoder.string(for: frame))")
                    }
                }
                walk(child)
            }
        }
        walk(root)
        return found
    }

    /// The daily's briefing is the densest screen in the app - a level picture, two lines of
    /// naming, a twist list that grows with the day, and a result block - so it is the one
    /// that runs out of room first. If it fits, the sparser screens fit.
    func testTheDailyBriefingFitsEveryWindowTheAppCanBeGiven() {
        for window in windows {
            let screen = DailyChallengeViewController()
            screen.view.frame = CGRect(origin: .zero, size: window.size)
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()

            let escaped = clipped(in: screen.view)
            XCTAssertTrue(escaped.isEmpty,
                          "\(window.name) (\(Int(window.size.width))x\(Int(window.size.height)))"
                          + " pushes something off screen: \(escaped.joined(separator: "; "))")
        }
    }

    /// The card on its own, at the same shapes.
    ///
    /// Separately from the screen above because the card is reused by the pager and sized by
    /// it - a card that only fits because its container clips it would pass the test above and
    /// still be wrong on the day a twist list runs long.
    func testTheDailyCardFitsEveryWindow() {
        let key = DailyChallengeSession.shared.todayKey
        for window in windows {
            let card = DailyCardView()
            card.frame = CGRect(origin: .zero, size: window.size)
            card.show(key: key, isToday: true, record: nil, standing: nil)
            card.setNeedsLayout()
            card.layoutIfNeeded()

            let escaped = clipped(in: card)
            XCTAssertTrue(escaped.isEmpty,
                          "\(window.name) clips the day's card: \(escaped.joined(separator: "; "))")
        }
    }
}
