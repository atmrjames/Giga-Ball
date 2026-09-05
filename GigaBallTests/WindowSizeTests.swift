//
//  WindowSizeTests.swift
//  GigaBallTests
//
//  **The iPad audit, as a test rather than a look** (round 301).
//
//  Removing `UIRequiresFullScreen` lets iPadOS hand the app window shapes no device has: a
//  Slide Over column, a third of a split, and anything down to `SceneDelegate`'s floor
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
        ("the minimum window", SceneDelegate.smallestWindow),
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
    /// **The flipped card picture, drawn.**
    ///
    /// Round 300 asserted the *orientation* - `.upMirrored` and `.downMirrored` - which is the
    /// contract and is not the same as having looked. James asked for the card to "reflect how
    /// the level will be presented", and whether it does is a question about a picture.
    ///
    /// A real level from the catalogue, three ways: as it is, mirrored, upside down.
    func testTheFlippedCardPicturesCanBeLookedAt() throws {
        let setup = LevelPackSetup()

        // Through the card's own path rather than by picking an index: these pictures are
        // only ever drawn for a *Classic* daily, and index 0 is the Endless Mode icon, which
        // is what an earlier version of this test flipped and looked at. A mode badge flips
        // fine and proves nothing about a level.
        // A level both flips change, asked of the same table the pool filters on rather than
        // judged by looking - which is the point of the table. Tunnel, the first that
        // qualifies, *reads* symmetric top to bottom at a glance and is not: measured off the
        // rendered panels, mirroring and turning it over each leave only about 45% of pixels
        // where they were. The eye compares the overall shape; the bar compares brick for
        // brick, and the bar is right.
        let level = try XCTUnwrap((1...110).first { level in
            [DailyTwist.mirrored, .upsideDown].allSatisfy {
                DailyTwist.levelsUnchangedBy[$0]?.contains(level) == false
            }
        }, "every level is symmetric both ways, which cannot be true")
        let number = DailyChallengeGenerator.levelNumber(forClassicLevel: level)
        let plain = setup.levelImageArray[number]

        let cases: [(String, [DailyTwist])] = [
            ("as it is", []), ("mirrored", [.mirrored]), ("upside down", [.upsideDown])
        ]
        let scale: CGFloat = 2
        let each = CGSize(width: plain.size.width, height: plain.size.height)
        let sheet = CGSize(width: each.width*CGFloat(cases.count) + 40,
                           height: each.height + 20)

        let image = UIGraphicsImageRenderer(size: sheet).image { context in
            UIColor(red: 0.09, green: 0, blue: 0.14, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: sheet))
            for (index, entry) in cases.enumerated() {
                let drawn = DailyTwist.presented(plain, under: entry.1)
                drawn?.draw(in: CGRect(x: 10 + (each.width + 10)*CGFloat(index), y: 10,
                                       width: each.width, height: each.height))
            }
        }
        _ = scale

        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("card-flips.png")
        try XCTUnwrap(image.pngData()).write(to: file)
        print("\n  Card pictures - \(setup.levelNameArray[number]) (level \(level)), "
              + "as it is / mirrored / upside down: \(file.path)\n")
    }

    /// **Deep Green's new purple top, drawn beside Deep Blue's.**
    ///
    /// James asked for the transition into the purple power-up tray to be "less dramatic",
    /// similar to Deep Blue. Whether it is, is a question about a picture: the numbers say the
    /// stops are where they should be and say nothing about whether the join reads as a join.
    func testTheDeepGreenPurpleTopCanBeLookedAt() throws {
        let size = CGSize(width: 300, height: 620)
        let paddleFraction: CGFloat = 0.18

        let image = UIGraphicsImageRenderer(size: CGSize(width: size.width*2 + 30,
                                                         height: size.height + 40)).image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: CGSize(width: size.width*2 + 30,
                                                        height: size.height + 40)))

            // The tray above both, in the purple the HUD actually uses
            GameBackground.borderPurple.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: size.width*2 + 30, height: 40))

            let stops = GameBackground.greenGradientStops(paddleFraction: paddleFraction)
            let space = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: space,
                                         colors: stops.colours.map(\.cgColor) as CFArray,
                                         locations: stops.locations) {
                ctx.cgContext.saveGState()
                ctx.cgContext.clip(to: CGRect(x: 10, y: 40, width: size.width, height: size.height))
                ctx.cgContext.drawLinearGradient(
                    gradient, start: CGPoint(x: 0, y: 40),
                    end: CGPoint(x: 0, y: 40 + size.height), options: [])
                ctx.cgContext.restoreGState()
            }

            UIImage(named: "BackgroundBlue")?.draw(in: CGRect(x: size.width + 20, y: 40,
                                                              width: size.width, height: size.height))
        }

        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("green-vs-blue.png")
        try XCTUnwrap(image.pngData()).write(to: file)
        print("\n  Deep Green (left) beside Deep Blue (right), tray above both: \(file.path)\n")
    }

    /// The stops stay in order whatever the paddle does, because a gradient with its stops out
    /// of order draws something arbitrary rather than failing.
    func testTheGreenGradientStopsAreAlwaysInOrder() {
        for fraction in stride(from: CGFloat(0), through: 1, by: 0.05) {
            let stops = GameBackground.greenGradientStops(paddleFraction: fraction)
            XCTAssertEqual(stops.colours.count, stops.locations.count)
            for (a, b) in zip(stops.locations, stops.locations.dropFirst()) {
                XCTAssertLessThanOrEqual(a, b,
                                         "paddleFraction \(fraction) puts the stops out of order")
            }
        }
    }

    /// The floor is the smallest phone the app supports, not a number picked by eye.
    ///
    /// James, round 311: "it's ok to make it smaller, so long as the game view maintains its
    /// height to width ratio." Round 310's 420x640 was wider than any phone the app runs on,
    /// which made it a guess rather than a rule - and a guess is what a window floor must not
    /// be, because it decides how small a player is allowed to make the game.
    func testTheWindowFloorIsTheSmallestPhoneTheAppSupports() {
        XCTAssertEqual(SceneDelegate.smallestWindow, CGSize(width: 320, height: 568),
                       "the iPhone SE, which is the smallest screen iOS 15 runs on")
    }

    /// And the play zone keeps its ratio there, which is the condition he attached to it.
    func testThePlayZoneKeepsItsRatioAtTheFloor() {
        let layout = GameSceneLayout(screen: SceneDelegate.smallestWindow)
        XCTAssertEqual(layout.playHeight/layout.gameWidth, GameSceneLayout.playRatio,
                       accuracy: 0.0001,
                       "the one constraint that never bends, at the smallest window allowed")
        XCTAssertLessThanOrEqual(layout.gameWidth, SceneDelegate.smallestWindow.width)
        XCTAssertGreaterThan(layout.gameWidth, 0, "and there is still a field to play on")
    }
}
