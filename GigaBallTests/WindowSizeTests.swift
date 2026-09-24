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
    /// The floor is `SceneDelegate`'s minimum window, so nothing smaller has to work.
    ///
    /// **The short-and-wide rows are live now** (round 312). They were here on the reasoning
    /// that "a layout that survives it survives anything, and if the orientation decision is
    /// ever revisited this row is already here" - and it has been: the app declares all four
    /// orientations on iPad, because iPadOS ignores `sizeRestrictions` for a single-orientation
    /// app and that was the whole of why James's window would not shrink. So these are no
    /// longer hypothetical shapes; they are shapes a player can make.
    private let windows: [(name: String, size: CGSize)] = [
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("iPhone 17 Pro", CGSize(width: 402, height: 874)),
        ("the minimum window", SceneDelegate.smallestWindow),
        ("iPad Slide Over", CGSize(width: 375, height: 1133)),
        ("iPad split, one third", CGSize(width: 375, height: 1366)),
        ("iPad split, half", CGSize(width: 507, height: 1366)),
        ("iPad split, two thirds", CGSize(width: 639, height: 1366)),
        ("iPad Pro 13, full screen", CGSize(width: 1032, height: 1376)),
        ("iPad Pro 11, landscape", CGSize(width: 1194, height: 834)),
        ("iPad Pro 13, landscape", CGSize(width: 1376, height: 1032)),
        ("a short, wide window", CGSize(width: 900, height: 420)),
        ("the floor, on its side", CGSize(width: 568, height: 320))
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
        XCTAssertEqual(SceneDelegate.smallestWindow, CGSize(width: 375, height: 667),
                       "the floor a player may pull an iPad or Mac window down to")
        // **Round 342: the smallest phone iOS 17 runs on, again.** Round 340 kept 320x568 as
        // a window size after it had stopped being a phone - the original SE cannot run the
        // deployment target - because it was also the narrowest a Slide Over panel could make
        // the app. James: "Let's raise the smallest size to 375 by 667", knowing it applies to
        // iPad and Mac windows as well.
    }

    /// **The play zone keeps its ratio and stays inside the window at every shape** (round 312).
    ///
    /// The condition James attached to landscape: "it's ok to make it smaller, so long as the
    /// game view maintains its height to width ratio." `GameSceneLayout` takes the smaller of
    /// what the height allows and what the width allows, so a short, wide window binds on height
    /// and the field simply becomes a narrow column with a lot of border - which is the right
    /// answer and worth pinning, because the obvious wrong one is to derive the width from the
    /// window's width and let the field run off the bottom.
    func testThePlayZoneFitsEveryWindowAndKeepsItsRatio() {
        for window in windows {
            let layout = GameSceneLayout(screen: window.size)
            XCTAssertEqual(layout.playHeight/layout.gameWidth, GameSceneLayout.playRatio,
                           accuracy: 0.0001, window.name)
            XCTAssertLessThanOrEqual(layout.gameWidth, window.size.width, window.name)
            XCTAssertLessThanOrEqual(layout.playHeight + layout.topBarHeight,
                                     window.size.height + 0.5,
                                     "\(window.name): the field and the bar above it have to fit")
            XCTAssertGreaterThan(layout.gameWidth, 0, "\(window.name): still a field to play on")
        }
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

/// What a window resize does to the scene already on screen.
///
/// James, round 313, playing in iPadOS 26's windowed mode and dragging the window into every
/// shape he could: "In the game view, yes the top and bottom were cut off when the app was
/// more square and the sides were cut off when the app was more tall and thin."
///
/// Those are the two halves of what `SKSceneScaleMode.aspectFill` is. It scales the scene
/// until it *covers* the view and discards whatever hangs over the edge, and the scene's size
/// is taken once, when it is presented, from the window the app opened in. On a phone that
/// window never changes shape, so fill and fit draw the same picture and this went unseen for
/// five years.
final class GameSceneFitsTheWindowTests: XCTestCase {

    /// The shape the scene was presented at: a portrait phone, which is what the layout solves
    /// for and what every scene starts life as.
    private let presented = CGSize(width: 393, height: 852)

    /// The shapes a window can be dragged into on an iPad.
    private let dragged: [(String, CGSize)] = [
        ("square", CGSize(width: 950, height: 975)),
        ("wide", CGSize(width: 1280, height: 975)),
        ("tall and thin", CGSize(width: 430, height: 1180)),
        ("very thin", CGSize(width: 320, height: 1366)),
        ("short and wide", CGSize(width: 1366, height: 420)),
        ("unchanged", CGSize(width: 393, height: 852)),
    ]

    /// How much of the scene survives, as a fraction of its area, under a scale mode.
    ///
    /// Pure arithmetic against SpriteKit's own definitions: fill takes the larger of the two
    /// ratios and crops, fit takes the smaller and letterboxes.
    private func visibleShare(of scene: CGSize, in view: CGSize, fill: Bool) -> CGFloat {
        let scale = fill ? max(view.width/scene.width, view.height/scene.height)
                         : min(view.width/scene.width, view.height/scene.height)
        let drawn = CGSize(width: scene.width*scale, height: scene.height*scale)
        let shown = CGSize(width: min(drawn.width, view.width),
                           height: min(drawn.height, view.height))
        return (shown.width*shown.height)/(drawn.width*drawn.height)
    }

    /// The report, as arithmetic: fill loses the top and bottom on a squarer window and the
    /// sides on a thin one.
    func testFillIsWhatWasCuttingTheGameOff() {
        let square = visibleShare(of: presented, in: CGSize(width: 950, height: 975), fill: true)
        XCTAssertLessThan(square, 0.5,
                          "more than half the scene gone on a square window - the HUD and the "
                          + "paddle are the two ends it takes")

        let thin = visibleShare(of: presented, in: CGSize(width: 320, height: 1366), fill: true)
        XCTAssertLessThan(thin, 0.75, "and the walls go on a tall thin one")
    }

    /// The fix: at every shape, all of it is on screen.
    func testFitShowsTheWholeSceneAtEveryShape() {
        for (name, view) in dragged {
            XCTAssertEqual(visibleShare(of: presented, in: view, fill: false), 1,
                           accuracy: 0.0001,
                           "\(name): James asked that the game view is always fully visible, "
                           + "including the power-up HUD and the buttons at the top, "
                           + "regardless of the size or shape of the app")
        }
    }

    /// And nothing is lost by fitting, because there was never more to show.
    ///
    /// The play zone holds a fixed 1.8236 ratio on every device - the promise that a run plays
    /// identically across a player's devices - so a window of a different shape has no more of
    /// the game to reveal. What fill was doing was not using the extra room; it was hiding the
    /// game and leaving the room where it was.
    func testTheScenesShapeIsTheRatioTheGamePromises() {
        let layout = GameSceneLayout(screen: presented)
        XCTAssertEqual(layout.playHeight/layout.gameWidth, GameSceneLayout.playRatio,
                       accuracy: 0.0001)
    }
}

/// A screen that was already open when the window changed shape.
///
/// James, round 313: "This was during windowed mode on the iPad so I was pulling the window
/// into all sorts of shapes." Every other test in this file lays a screen out *at* a size,
/// which is a different question and the one that already passed: what broke on his iPad was
/// a screen laid out at one size and then given another.
final class ResizedWhileOpenTests: XCTestCase {

    private let shapes: [(String, CGSize)] = [
        ("phone", CGSize(width: 393, height: 852)),
        ("half an iPad", CGSize(width: 507, height: 1366)),
        ("square", CGSize(width: 950, height: 975)),
        ("wide", CGSize(width: 1280, height: 975)),
        ("narrow", CGSize(width: 430, height: 1180)),
    ]

    /// The daily's pager holds an offset in points, and a page is the width of the viewport.
    ///
    /// Change the width underneath it and that offset stops naming the day it named: the card
    /// sits part way between two pages, showing the right-hand edge of one and the left of the
    /// next. That is the picture he sent - "CLASSIC" and "Food Pack" running off the right
    /// edge of the window - and in a smaller window the middle of the card was missing
    /// altogether, which is the same offset landing further out.
    func testTheDailyPagerStillLandsOnAWholeDayAfterAResize() {
        for (fromName, from) in shapes {
            for (toName, to) in shapes where to != from {
                let screen = DailyChallengeViewController()
                screen.view.frame = CGRect(origin: .zero, size: from)
                screen.view.setNeedsLayout()
                screen.view.layoutIfNeeded()

                screen.view.frame = CGRect(origin: .zero, size: to)
                screen.view.setNeedsLayout()
                screen.view.layoutIfNeeded()

                guard let pager = pager(in: screen.view) else {
                    return XCTFail("the pager has moved")
                }
                let page = pager.bounds.width
                guard page > 0 else { continue }
                let offset = pager.contentOffset.x
                let landed = (offset/page).rounded()

                XCTAssertEqual(offset, landed*page, accuracy: 1,
                               "\(fromName) -> \(toName): the card is \(offset) into pages of "
                               + "\(page), which is part way between two days")
            }
        }
    }

    private func pager(in view: UIView) -> UICollectionView? {
        for child in view.subviews {
            if let collection = child as? UICollectionView,
               collection.isPagingEnabled { return collection }
            if let found = pager(in: child) { return found }
        }
        return nil
    }
}

/// The game view following the window after the level is built.
///
/// James, round 342: "iPad game view not filling the window - is it not possible to make those
/// purple side bars dynamic so their width can adjust as the window adjusts, ensuring the game
/// view fills the vertical space without being clipped."
final class GameViewFollowsTheWindowTests: XCTestCase {

    /// An iPad laid out at full screen: the play zone is height-bound, with wide purple borders.
    private let laidOut = CGSize(width: 1024, height: 1366)
    private let playWidth: CGFloat = 656

    /// A narrower window keeps the height and loses border, so nothing is letterboxed.
    func testANarrowerWindowKeepsTheHeightAndLosesBorder() {
        let view = CGSize(width: 700, height: 1366)
        let size = GameScene.sizeFilling(view, laidOut: laidOut, narrowest: playWidth)
        XCTAssertEqual(size.height, laidOut.height, "the play zone keeps the window's height")
        XCTAssertEqual(size.width/size.height, view.width/view.height, accuracy: 0.0001,
                       "the scene is the window's shape, so aspectFit has nothing to band")
    }

    /// A wider or shorter window fills too - the border grows instead.
    func testAWiderWindowGrowsTheBorder() {
        for view in [CGSize(width: 1366, height: 1024), CGSize(width: 1280, height: 975),
                     CGSize(width: 950, height: 975)] {
            let size = GameScene.sizeFilling(view, laidOut: laidOut, narrowest: playWidth)
            XCTAssertEqual(size.height, laidOut.height, "\(view)")
            XCTAssertEqual(size.width/size.height, view.width/view.height, accuracy: 0.0001,
                           "\(view): fills the window")
            XCTAssertGreaterThanOrEqual(size.width, playWidth, "\(view): the field is all there")
        }
    }

    /// Thinner than the game itself is the one shape that cannot be filled without clipping,
    /// and James's own condition rules clipping out - so there the scene stops narrowing.
    func testAWindowThinnerThanTheGameIsNeverClipped() {
        let view = CGSize(width: 375, height: 1366)
        let size = GameScene.sizeFilling(view, laidOut: laidOut, narrowest: playWidth)
        XCTAssertEqual(size.width, playWidth, "the walls and the field stay on screen")
        XCTAssertEqual(size.height, laidOut.height, "and the height every body was built at")
    }

    /// The scene itself: its size changes, its height and play zone never do.
    func testTheSceneFollowsTheWindowAndBackAgain() {
        let scene = GameScene(size: laidOut)
        scene.gameWidth = playWidth
        scene.laidOutSceneSize = laidOut

        scene.fitTheWindow(CGSize(width: 700, height: 1366))
        XCTAssertEqual(scene.size.width, 700, accuracy: 0.5)
        XCTAssertEqual(scene.size.height, laidOut.height)
        var painted: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var wall: (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        scene.backgroundColor.getRed(&painted.0, green: &painted.1, blue: &painted.2,
                                     alpha: &painted.3)
        GameScene.borderColour.getRed(&wall.0, green: &wall.1, blue: &wall.2, alpha: &wall.3)
        for (a, b) in [(painted.0, wall.0), (painted.1, wall.1), (painted.2, wall.2)] {
            XCTAssertEqual(a, b, accuracy: 0.002,
                           "past the walls is the walls' purple, not the scene's grey")
        }

        scene.fitTheWindow(CGSize(width: 1024, height: 1366))
        XCTAssertEqual(scene.size, laidOut, "dragged back, it is the scene it was built as")
    }

    /// The HUD sets the limit when it was hung off the screen's edges (a compact width).
    func testTheHUDIsNeverCutOff() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameWidth = 380
        scene.labelSpacing = 10
        scene.laidOutSceneSize = scene.size
        scene.pauseButton.size = CGSize(width: 30, height: 30)
        scene.pauseButton.position.x = -201 + 20 + 15
        scene.addChild(scene.pauseButton)

        scene.fitTheWindow(CGSize(width: 300, height: 874))
        XCTAssertGreaterThanOrEqual(scene.size.width/2, 201 - 20 + 20 - 0.5,
                                    "the pause button keeps the margin it was built with")
        XCTAssertLessThanOrEqual(scene.size.width, 402, "never wider than it was built")
    }
}
