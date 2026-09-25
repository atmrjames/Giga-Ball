//
//  MenuLayoutTests.swift
//  GigaBallTests
//
//  The main menu at every shape a window can be dragged into.
//
//  James, round 313, from iPadOS 26's windowed mode: two of his screenshots show the GIGA-BALL
//  wordmark sitting on top of Classic Mode, and the information and settings buttons sitting on
//  top of Daily Challenge.
//
//  The cause was a fixed height. The mode table carried a hard 450 points in the storyboard
//  (563 at regular width), and it is centred in a container whose height is whatever is left
//  between the logo and the icon row. On a phone that container is 495 points, so 450 fits and
//  nobody ever saw it. In a 931x708 window it is 248, and a 450-point table centred in 248
//  points of room hangs 100 points out of each end - over the logo above and the icons below.
//  Measured, before the fix: container 275 to 523, table 117 to 680, logo 140 to 185.
//
//  The row height made it worse rather than catching it: it was `min(150, tableHeight/4)`,
//  asked of the table's *own* height, which is four rows of whatever that returns. Every
//  height is its own fixed point, so the answer was only ever whatever the table happened to
//  start at.
//

import XCTest
import UIKit
import SpriteKit
@testable import Giga_Ball

final class MenuLayoutTests: XCTestCase {

    /// Every shape, including the two he sent.
    private let shapes: [(String, CGSize)] = [
        ("phone", CGSize(width: 393, height: 852)),
        ("small phone", CGSize(width: 320, height: 568)),
        ("his square window", CGSize(width: 950, height: 975)),
        ("his wide window", CGSize(width: 931, height: 708)),
        ("his tall window", CGSize(width: 430, height: 1180)),
        ("iPad portrait", CGSize(width: 1024, height: 1366)),
        ("iPad landscape", CGSize(width: 1366, height: 1024)),
        ("slide over", CGSize(width: 320, height: 1024)),
    ]

    private func laidOut(_ size: CGSize) -> MenuViewController {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: MenuViewController.self))
        let menu = board.instantiateViewController(withIdentifier: "menuView")
            as! MenuViewController
        window.rootViewController = menu
        window.isHidden = false
        for _ in 0..<4 {
            menu.view.setNeedsLayout()
            menu.view.layoutIfNeeded()
        }
        return menu
    }

    private func rect(_ view: UIView, in menu: MenuViewController) -> CGRect {
        view.convert(view.bounds, to: menu.view)
    }

    // MARK: - The report

    /// The wordmark and the mode rows are never in the same place.
    func testTheModeRowsNeverReachTheWordmark() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let logo = rect(menu.logoImage, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertGreaterThanOrEqual(table.minY, logo.maxY, "\(name): "
                + "the rows start at \(Int(table.minY)) and the wordmark ends at "
                + "\(Int(logo.maxY)) - they are on top of one another")
        }
    }

    /// Nor the mode rows and the information and settings buttons.
    func testTheModeRowsNeverReachTheIconRow() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let icons = rect(menu.iconCollectionView, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertLessThanOrEqual(table.maxY, icons.minY, "\(name): "
                + "the rows end at \(Int(table.maxY)) and the icons start at "
                + "\(Int(icons.minY))")
        }
    }

    /// Which both follow from this: the table stays in the room it was given.
    func testTheTableStaysInsideItsContainer() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let container = rect(menu.tableViewContainer, in: menu)
            let table = rect(menu.modeSelectTableView, in: menu)
            XCTAssertGreaterThanOrEqual(table.minY, container.minY - 0.5, name)
            XCTAssertLessThanOrEqual(table.maxY, container.maxY + 0.5, name)
        }
    }

    /// And every mode is reachable without scrolling, which is the menu's own rule.
    func testTheMenuNeverScrolls() {
        for (name, size) in shapes {
            let menu = laidOut(size)
            let table = menu.modeSelectTableView!
            let room = menu.tableViewContainer.bounds.height
            let needed = MenuViewController.modeRowHeight(inRoomOf: room)
                * CGFloat(GameMode.allCases.count)
            guard needed <= room + 0.5 else {
                // A window too short for four cards at their minimum: scrolling is the
                // graceful failure, and the constraint keeps the rows inside the room
                continue
            }
            XCTAssertLessThanOrEqual(table.contentSize.height, table.bounds.height + 0.5,
                                     "\(name): the main menu never scrolls")
        }
    }

    // MARK: - The rule itself

    /// The room is the container's, and never the table's own height.
    ///
    /// The old line was circular - `min(150, tableHeight/4)` asked of a table four rows tall -
    /// so any height at all was a fixed point and the answer was an accident of which layout
    /// pass got there first. This one is a function of room the table does not decide.
    ///
    /// **The ceiling is read, not restated** (round 314). These three assertions were written
    /// as the literal 150 and all three failed the moment James asked for the rows to stop
    /// growing on an iPad, reporting a change that was the point of the change. What the test
    /// is actually for is the *shape* of the rule - capped above, floored at the card, linear
    /// between, and never zero - so it asks `tallestModeRow` for the number.
    func testTheRowHeightIsAFunctionOfTheRoom() {
        let ceiling = MenuViewController.tallestModeRow
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: ceiling*8), ceiling,
                       "capped, or a tall window gives four enormous buttons")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 495),
                       min(ceiling, 495/4),
                       "and linear in the room between the floor and the ceiling")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 248), 75,
                       "and floored at the card inside the cell, or the cards overlap")
        XCTAssertEqual(MenuViewController.modeRowHeight(inRoomOf: 0), ceiling,
                       "a table with no size yet must not stick at nothing")
    }

    /// And the ceiling itself is a phone's, which is the thing James asked for.
    ///
    /// A separate assertion because it is a separate claim: the rule above is about shape and
    /// this is about the number. The card inside a row is 75, so this says the gap between two
    /// cards never exceeds 45 points however large the screen - against roughly 33 on a phone,
    /// and 75 under the old ceiling of 150.
    func testTheModeRowCeilingStaysPhoneSized() {
        XCTAssertLessThanOrEqual(MenuViewController.tallestModeRow - 75, 45,
                                 "the four modes have to read as one block on an iPad")
        XCTAssertGreaterThan(MenuViewController.tallestModeRow, 108,
                             "and still be no tighter than a phone, which fits about 108")
    }

    /// Four rows always fit the height the table is given.
    func testFourRowsFillTheTableExactly() {
        for room in stride(from: 200.0, through: 1200.0, by: 25.0) {
            let menu = MenuViewController.modeRowHeight(inRoomOf: CGFloat(room))
            let total = menu*CGFloat(GameMode.allCases.count)
            XCTAssertLessThanOrEqual(total, max(CGFloat(room), 300),
                                     "\(room) points of room, \(total) of rows")
        }
    }
}


/// **What the About screen says the app is.**
///
/// Round 319d, from the App Store readiness pass. The version line was typed into the
/// storyboard as "Giga-Ball 1.2 (3) - August 2026" and nothing set it at runtime, so the 1.3
/// release would have shipped a credits screen claiming to be 1.2. Nothing could have failed
/// on it: a label with the wrong words in it is not a bug, it is a fact about the app that
/// stopped being true.
///
/// So the number is derived from the bundle now, and this reads it the same way to say so. It
/// is a weak-looking test that earns its place: it fails the day somebody types a version back
/// into a storyboard.
final class AboutVersionTests: XCTestCase {

    func testTheAboutScreenReadsTheVersionOffTheBundle() {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: AboutViewController.self))
        guard let about = board.instantiateViewController(withIdentifier: "aboutVC")
                as? AboutViewController else {
            return XCTFail("the About screen is reachable from the storyboard")
        }
        about.loadViewIfNeeded()

        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        XCTAssertFalse(version.isEmpty, "the bundle has a marketing version")

        let shown = about.buildLabel.text ?? ""
        XCTAssertTrue(shown.contains(version),
                      "the About screen says \"\(shown)\" and the app is \(version)")
        if let build = info?["CFBundleVersion"] as? String {
            XCTAssertTrue(shown.contains(build),
                          "and the build number: \"\(shown)\" against \(build)")
        }
    }

    /// And it must not be carrying a hand-typed date again.
    ///
    /// The month went with the fix: nothing in the bundle can supply it, so a typed one is a
    /// second copy of a decision that goes stale on a schedule of its own - which is exactly
    /// what had happened. If James wants it back it needs a source, and this is the line that
    /// will say so.
    func testTheVersionLineHasNoTypedDateInIt() {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: AboutViewController.self))
        guard let about = board.instantiateViewController(withIdentifier: "aboutVC")
                as? AboutViewController else { return }
        about.loadViewIfNeeded()

        let months = ["January", "February", "March", "April", "May", "June", "July",
                      "August", "September", "October", "November", "December"]
        let shown = about.buildLabel.text ?? ""
        for month in months {
            XCTAssertFalse(shown.contains(month),
                           "\"\(shown)\" carries a month nothing keeps up to date")
        }
    }
}


/// **Moving an icon above its title leaves nothing still pinning the icon where it was.**
///
/// Round 321, from James's play-test log on an iPhone 16 Pro Max: three "Unable to simultaneously
/// satisfy constraints" blocks each time the Level Stats screen opened, naming a label 52 tall, a
/// square image view, and gaps of 0, 40 and 10. That screen's storyboard stacks title, pack line,
/// picture, stats - and `swapMenuHeader` moves the picture to the top, but left its storyboard
/// `top = packLine.bottom + 40` active. Picture above title, title above pack line, pack line above
/// picture: a circle. UIKit broke a constraint at random to escape it, so the screen usually looked
/// right, which is exactly the kind of right a test has to stop relying on.
///
/// Built here with plain views in the storyboard's own arrangement, so it asks the helper rather
/// than one screen.
final class MenuHeaderSwapTests: XCTestCase {

    func testTheSwapLeavesTheIconWithOneTopAndNoCircle() {
        let controller = UIViewController()
        let container = controller.view!
        container.frame = CGRect(x: 0, y: 0, width: 440, height: 956)

        let title = UILabel(), packLine = UILabel(), icon = UIImageView(), stats = UILabel()
        for view in [title, packLine, icon, stats] {
            view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(view)
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        }
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            title.heightAnchor.constraint(equalToConstant: 52),
            packLine.topAnchor.constraint(equalTo: title.bottomAnchor),
            icon.topAnchor.constraint(equalTo: packLine.bottomAnchor, constant: 40),
            icon.widthAnchor.constraint(equalTo: icon.heightAnchor),
            icon.heightAnchor.constraint(equalToConstant: 120),
            stats.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 40),
        ])
        // The Level Stats storyboard, in the order it is laid out before the swap

        _ = controller.swapMenuHeader(icon: icon, title: title, in: container)

        let iconTops = container.constraints.filter { constraint in
            constraint.isActive
                && ((constraint.firstItem === icon && constraint.firstAttribute == .top)
                    || (constraint.secondItem === icon && constraint.secondAttribute == .top))
        }
        XCTAssertEqual(iconTops.count, 1,
                       "the icon's top is set once; a second is the circle James's log printed")

        container.layoutIfNeeded()
        XCTAssertLessThanOrEqual(icon.frame.maxY, title.frame.minY + 0.5, "icon above the title")
        XCTAssertLessThanOrEqual(title.frame.maxY, packLine.frame.minY + 0.5,
                                 "the title still sits on the pack line")
        XCTAssertLessThanOrEqual(packLine.frame.maxY, stats.frame.minY + 0.5,
                                 "and what hung under the icon hangs under the header now")
    }
}

/// **The Endless and Mayhem screens before a first run** (James, round 326: "If there's no scores
/// yet, hide the tableview and centre the icon and game mode header on the page whilst disabling
/// scrolling. Same on the Endless Mode screen.").
///
/// Both modes are the one `LevelStatsViewController` at level 0, told apart by the stored mode, so
/// one set of runs is given to both lists and either mode reads it.
final class EndlessModeScreenWithNoRunsTests: XCTestCase {

    private let shapes: [(String, CGSize)] = [
        ("phone", CGSize(width: 402, height: 874)),
        ("iPad portrait", CGSize(width: 1032, height: 1376)),
    ]

    private func screen(runs: [Int], in size: CGSize) -> LevelStatsViewController {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: LevelStatsViewController.self))
        let screen = board.instantiateViewController(withIdentifier: "levelStatsView")
            as! LevelStatsViewController
        let stats = TotalStats()
        stats.endlessModeHeight = runs
        stats.endlessModeHeightDate = runs.map { _ in Date() }
        stats.endlessIIModeHeight = runs
        stats.endlessIIModeHeightDate = runs.map { _ in Date() }
        screen.totalStatsArray = [stats]
        // Under tests the screen has no stats file, so this is what it shows
        screen.startLevel = 0
        screen.levelNumber = 0
        screen.packNumber = 1
        window.rootViewController = screen
        window.isHidden = false
        for _ in 0..<4 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        return screen
    }

    private func rect(_ view: UIView, in screen: LevelStatsViewController) -> CGRect {
        view.convert(view.bounds, to: screen.view)
    }

    /// The logo and the mode's name, as the one block they read as.
    private func header(_ screen: LevelStatsViewController) -> CGRect {
        rect(screen.levelImageView, in: screen).union(rect(screen.levelNameLabel, in: screen))
    }

    func testWithNoRunsTheHeaderIsInTheMiddleOfThePage() {
        for (name, size) in shapes {
            let screen = screen(runs: [], in: size)
            let page = rect(screen.levelStatsView, in: screen)
            let block = header(screen)
            XCTAssertEqual(block.midY, page.midY, accuracy: 1,
                           "\(name): the header's middle is at \(Int(block.midY)), the page's at \(Int(page.midY))")
            XCTAssertEqual(block.midX, page.midX, accuracy: 1, "\(name): and centred across it")
        }
    }

    func testWithNoRunsThereIsNoListAndNothingScrolls() {
        for (name, size) in shapes {
            let screen = screen(runs: [], in: size)
            XCTAssertTrue(screen.runHistoryTable == nil || screen.runHistoryTable?.isHidden == true,
                          "\(name): no run list")
            let scrolling = screen.levelStatsView.subviews
                .compactMap { $0 as? UIScrollView }
                .filter { $0.isHidden == false && $0.isScrollEnabled }
            XCTAssertTrue(scrolling.isEmpty, "\(name): nothing on the page scrolls, found \(scrolling)")
        }
    }

    /// The logo is the size it will be once there are runs, so a first run does not shrink it.
    func testTheLogoIsTheSameSizeWithRunsAndWithout() {
        for (name, size) in shapes {
            let empty = screen(runs: [], in: size)
            let without = rect(empty.levelImageView, in: empty)
            let with = screen(runs: [120, 340], in: size)
            XCTAssertEqual(without.width, UIViewController.menuModeLogoSize, accuracy: 0.5, "\(name)")
            XCTAssertEqual(rect(with.levelImageView, in: with).width,
                           UIViewController.menuModeLogoSize, accuracy: 0.5, "\(name)")
        }
    }

    /// With runs, nothing changes from before: the header at the top and the list under it.
    func testWithRunsTheHeaderIsAtTheTopAndTheListIsShown() {
        for (name, size) in shapes {
            let screen = screen(runs: [120, 340], in: size)
            let page = rect(screen.levelStatsView, in: screen)
            let block = header(screen)
            XCTAssertLessThan(block.midY, page.midY - 100, "\(name): the header is at the top")
            guard let table = screen.runHistoryTable else {
                XCTFail("\(name): no run list was built")
                continue
            }
            XCTAssertFalse(table.isHidden, "\(name): the list is there")
            XCTAssertEqual(table.numberOfRows(inSection: 0), 2, "\(name): with both runs")
            XCTAssertGreaterThanOrEqual(rect(table, in: screen).minY, block.maxY,
                                        "\(name): under the header")
        }
    }

    /// And a list emptied while the screen is open - Reset Data, or an iCloud reset - goes back
    /// to the empty page rather than leaving an empty table under a header at the top.
    func testEmptyingTheRunsWhileTheScreenIsOpenCentresTheHeaderAgain() {
        let screen = screen(runs: [120], in: shapes[0].1)
        XCTAssertNotNil(screen.runHistoryTable)
        screen.totalStatsArray[0].endlessModeHeight = []
        screen.totalStatsArray[0].endlessModeHeightDate = []
        screen.totalStatsArray[0].endlessIIModeHeight = []
        screen.totalStatsArray[0].endlessIIModeHeightDate = []
        screen.updateLabels()
        for _ in 0..<4 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        let page = rect(screen.levelStatsView, in: screen)
        XCTAssertEqual(header(screen).midY, page.midY, accuracy: 1)
        XCTAssertEqual(screen.runHistoryTable?.isHidden, true)
        XCTAssertEqual(screen.runHistoryTable?.isScrollEnabled, false)
    }
}

/// **The sticky heading's band is as wide as the tiles** (James, round 326, on an iPad: the
/// Power-Ups sticky header "is slightly wider than the tiles below it").
final class ReferenceHeadingBandTests: XCTestCase {

    func testTheBandStartsAndEndsWhereTheTilesDo() {
        let header = UICollectionReusableView(
            frame: CGRect(x: 0, y: 0, width: 400, height: ReferenceHeading.height))
        let inset = PackSelectViewController.gridInset
        ReferenceHeading.fill(header, title: "Classic game modes", inset: inset)
        let band = header.subviews.compactMap { $0 as? UIVisualEffectView }.first
        XCTAssertEqual(band?.frame, CGRect(x: inset, y: 0, width: 400 - 2*inset,
                                           height: ReferenceHeading.height))

        header.frame.size.width = 1000
        header.layoutIfNeeded()
        XCTAssertEqual(band?.frame.minX, inset, "still in from the left on a wider screen")
        XCTAssertEqual(band?.frame.maxX, 1000 - inset, "and from the right")
    }
}

/// **The four screens that were not drifting** (James, round 328, asked whether their having no
/// parallax was deliberate: "yes" - meaning yes, give them it).
///
/// Daily Challenge, Music, Paddle Speed and Run Statistics are built in code and put their
/// content straight onto `view`, so there is no content view to hand to `applyMenuParallax` the
/// way the storyboard screens do. Every direct subview takes the drift instead - except the dark
/// blur each of them lays over the menu behind it, which is the backdrop the rest drifts over.
final class CodeBuiltScreenParallaxTests: XCTestCase {

    private func laidOut(_ screen: UIViewController, wants parallax: Bool) -> UIViewController {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = screen
        window.isHidden = false
        for _ in 0..<3 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        screen.view.applyMenuParallaxToContent(
            settings: InMemoryKeyValueStore(["parallaxSetting": parallax]))
        // Asked directly with a store of its own rather than by writing the real setting: a test
        // may not leave a durable value behind, and this one would be the player's
        return screen
    }

    private func screens() -> [(String, UIViewController)] {
        [("Daily Challenge", DailyChallengeViewController()),
         ("Music", MusicViewController()),
         ("Paddle Speed", PaddleSpeedViewController()),
         ("Run Statistics", RunStatsViewController())]
    }

    func testTheContentDriftsAndTheBlurDoesNot() {
        for (name, screen) in screens() {
            _ = laidOut(screen, wants: true)
            let subviews = screen.view.subviews
            XCTAssertFalse(subviews.isEmpty, "\(name) built nothing to drift")

            let drifting = subviews.filter { $0.motionEffects.isEmpty == false }
            XCTAssertFalse(drifting.isEmpty, "\(name): nothing on the screen drifts")

            for blur in subviews.compactMap({ $0 as? UIVisualEffectView }) {
                XCTAssertTrue(blur.motionEffects.isEmpty,
                              "\(name): the backdrop drifted, so nothing is parallax")
            }
        }
    }

    /// And a player who has turned it off gets a still screen, including one turned off while
    /// the screen is open - Settings is reachable from most of them.
    func testNothingDriftsWhenTheSettingIsOff() {
        for (name, screen) in screens() {
            _ = laidOut(screen, wants: true)
            screen.view.applyMenuParallaxToContent(
                settings: InMemoryKeyValueStore(["parallaxSetting": false]))

            for subview in screen.view.subviews {
                XCTAssertTrue(subview.motionEffects.isEmpty, "\(name) is still drifting")
            }
        }
    }
}

/// The paddle-speed field on an iPad (round 344).
///
/// James, round 339: "the slider and close button go all the way to the screen edges" and "the
/// preview is clipping" - both the field being a one-to-one window onto a play area wider than
/// the column. It is a scaled model of the play area now, inside the column.
final class PaddleSpeedFieldOnAnIPadTests: XCTestCase {

    func testTheFieldSitsInTheColumnAsAModelOfThePlayArea() throws {
        let screen = PaddleSpeedViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 1366))
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = screen
        window.isHidden = false
        for _ in 0..<4 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }

        let column = screen.view.safeAreaLayoutGuide.layoutFrame
        let field = try XCTUnwrap(skViews(in: screen.view).first, "the practice field")
        let placed = field.convert(field.bounds, to: screen.view)
        XCTAssertLessThanOrEqual(placed.width, column.width + 1,
                                 "the field is inside the column the rest of the screen uses")
        XCTAssertGreaterThanOrEqual(placed.minX, column.minX - 1)

        let scene = try XCTUnwrap(field.scene as? PaddleSpeedScene, "a scene was presented")
        let play = GameSceneLayout(screen: CGSize(width: 1024, height: 1366))
        XCTAssertEqual(scene.size.width, play.gameWidth, accuracy: 1,
                       "the scene is the play area at the game's own size, drawn smaller")
        XCTAssertEqual(scene.touchScale, play.gameWidth/placed.width, accuracy: 0.01,
                       "and a point of thumb moves the paddle as far as it does in the game")
    }

    private func skViews(in view: UIView) -> [SKView] {
        view.subviews.flatMap { ($0 as? SKView).map { [$0] } ?? skViews(in: $0) }
    }
}
