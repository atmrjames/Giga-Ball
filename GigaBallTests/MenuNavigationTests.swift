//
//  MenuNavigationTests.swift
//  GigaBallTests
//
//  The rules a forward swipe follows. The gesture itself is verified by using it; what is
//  worth pinning down is when there is something to go forward *to*, because the wrong answer
//  there summons a screen from a path the player has left.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class MenuNavigationTests: XCTestCase {

    private var parent: UIViewController!
    private var child: UIViewController!

    override func setUp() {
        super.setUp()
        MenuNavigation.shared.forget()

        parent = UIViewController()
        parent.loadViewIfNeeded()
        child = UIViewController()
        child.loadViewIfNeeded()
        parent.addChild(child)
        child.didMove(toParent: parent)
    }

    override func tearDown() {
        MenuNavigation.shared.forget()
        super.tearDown()
    }

    func testThereIsNowhereToGoForwardUntilSomethingHasBeenGoneBackFrom() {
        XCTAssertFalse(MenuNavigation.shared.canGoForward(from: parent))
    }

    func testAScreenGoneBackFromCanBeReturnedTo() {
        MenuNavigation.shared.record(child)
        XCTAssertTrue(MenuNavigation.shared.canGoForward(from: parent))
    }

    func testOnlyTheScreenThatOpenedItCanGoForwardToIt() {
        // Swiping right on some unrelated menu should not summon this
        MenuNavigation.shared.record(child)
        XCTAssertFalse(MenuNavigation.shared.canGoForward(from: UIViewController()))
    }

    func testAScreenStillOnDisplayIsNotSomethingToGoForwardTo() {
        parent.view.addSubview(child.view)
        MenuNavigation.shared.record(child)
        XCTAssertFalse(MenuNavigation.shared.canGoForward(from: parent))
    }

    func testOpeningAnythingNewEndsTheWayForward() {
        // A push after a pop discards the forward history, which is what installing the
        // gestures on a newly loaded screen stands for
        MenuNavigation.shared.record(child)
        UIViewController().installMenuNavigationSwipes()
        XCTAssertFalse(MenuNavigation.shared.canGoForward(from: parent))
    }

    func testGoingForwardPutsTheScreenBackOnDisplay() {
        MenuNavigation.shared.record(child)
        MenuNavigation.shared.goForward(from: parent)

        XCTAssertTrue(child.view.superview === parent.view)
    }

    func testGoingForwardIsSpentOnce() {
        MenuNavigation.shared.record(child)
        MenuNavigation.shared.goForward(from: parent)
        child.view.removeFromSuperview()

        MenuNavigation.shared.goForward(from: parent)
        XCTAssertNil(child.view.superview, "the way forward should have been used up")
    }

    func testOnlyTheScreenOnTopIsTheFrontmostOne() {
        // "Back swipe in menus is going back to the first screen even if multiple layers
        // deep." Every screen is laid over the one that opened it, so one swipe reaches every
        // recogniser in the stack
        XCTAssertTrue(parent.menuNavigationIsFrontmost, "nothing is open over it")

        parent.view.addSubview(child.view)
        XCTAssertFalse(parent.menuNavigationIsFrontmost)
        XCTAssertTrue(child.menuNavigationIsFrontmost)

        child.view.removeFromSuperview()
        XCTAssertTrue(parent.menuNavigationIsFrontmost, "the screen it opened has gone back")
    }

    func testTheSwipeIsInstalledAndSharesTheTouch() {
        // Sharing matters for the *other recognisers*: menus scroll, and scrolling is driven
        // by a gesture recogniser rather than by touches in the view
        let screen = UIViewController()
        screen.loadViewIfNeeded()
        screen.installMenuNavigationSwipes()

        let pans = (screen.view.gestureRecognizers ?? [])
            .compactMap { $0 as? UIPanGestureRecognizer }
        XCTAssertEqual(pans.count, 1)
        XCTAssertTrue(pans.first?.delegate === MenuNavigation.shared)
        XCTAssertEqual(pans.first?.cancelsTouchesInView, true)
        // A swipe is not a tap: without this the touch carried on to whatever was under the
        // finger, and a swipe that started on a cell opened it
    }

    // MARK: - What a swipe means

    private let width: CGFloat = 400

    private func move(from x: CGFloat, by dx: CGFloat, dy: CGFloat = 0) -> MenuNavigation.Move {
        MenuNavigation.move(start: CGPoint(x: x, y: 400),
                            translation: CGPoint(x: dx, y: dy), width: width)
    }

    func testASwipeFromTheLeftEdgeGoesBack() {
        XCTAssertEqual(move(from: 0, by: 200), .back)
        XCTAssertEqual(move(from: MenuNavigation.edgeWidth, by: 200), .back)
    }

    func testASwipeFromTheRightEdgeGoesForward() {
        XCTAssertEqual(move(from: width, by: -200), .forward)
        XCTAssertEqual(move(from: width - MenuNavigation.edgeWidth, by: -200), .forward)
    }

    func testASwipeThatStartsInTheMiddleMeansNothing() {
        XCTAssertEqual(move(from: width/2, by: 200), MenuNavigation.Move.none)
        XCTAssertEqual(move(from: width/2, by: -200), MenuNavigation.Move.none)
    }

    func testASwipeMustTravelFarEnoughToHaveBeenMeant() {
        XCTAssertEqual(move(from: 0, by: MenuNavigation.travel), MenuNavigation.Move.none)
        XCTAssertEqual(move(from: 0, by: MenuNavigation.travel + 1), .back)
    }

    func testScrollingNearTheEdgeIsNotAPageTurn() {
        // Mostly downwards, with a bit of sideways drift
        XCTAssertEqual(move(from: 5, by: 90, dy: 300), MenuNavigation.Move.none)
        XCTAssertEqual(move(from: width, by: -90, dy: -300), MenuNavigation.Move.none)
    }

    func testTheDirectionHasToMatchTheEdge() {
        // Swiping left from the left edge is not a back gesture
        XCTAssertEqual(move(from: 0, by: -200), MenuNavigation.Move.none)
        XCTAssertEqual(move(from: width, by: 200), MenuNavigation.Move.none)
    }
}

/// The four confirms, after round 162 folded `WarningViewController` into `GigaBallAlert`.
///
/// They are the pop-ups that matter most - one of them throws away every score on the device -
/// and they used to be a storyboard sheet nobody could see from the alert's own code. What is
/// worth pinning is that the merge kept the words and the shape: a player who has learned that
/// the green button is the one that does the thing should not find that changed by a refactor.
final class GigaBallConfirmTests: XCTestCase {

    private let all: [GigaBallConfirm] = [.resetBall, .resetData, .mainMenu, .swipeUpToPause]

    func testTheFourConfirmsAreTheOnesThePlayTestKnows() {
        // Round 89's note names them: MAIN MENU, RESET BALL, RESET DATA, SWIPE UP
        XCTAssertEqual(Set(all.map(\.title)),
                       ["MAIN MENU", "RESET BALL", "RESET DATA", "SWIPE UP"])
    }

    func testEveryConfirmSaysSomethingAndWearsAMark() {
        // Play-test round 85 asked for an icon above the title and the sheet had no slot for
        // one at all. Every one of the four has a mark now, and no two share it - the icon is
        // how a pop-up is recognised before it is read
        for confirm in all {
            XCTAssertFalse(confirm.message.isEmpty, confirm.title)
            XCTAssertFalse(confirm.symbol.isEmpty, confirm.title)
        }
        XCTAssertEqual(Set(all.map(\.symbol)).count, all.count,
                       "four questions, four marks")
    }

    func testAskingSomethingOffersCancelAndOK() {
        for confirm in [GigaBallConfirm.resetBall, .resetData, .mainMenu] {
            XCTAssertEqual(confirm.dismissTitle, "Cancel", confirm.title)
            XCTAssertEqual(confirm.confirmTitle, "OK", confirm.title)
        }
        // The pale button steps back and the green one does the thing, which is the pairing
        // every other pop-up in the app already uses
    }

    func testTheSwipeExplainerHasNothingToWeighUp() {
        // It tells the player how pausing works rather than asking them anything, so it takes
        // the single lime OK - which is what the old sheet's centre button was
        XCTAssertNil(GigaBallConfirm.swipeUpToPause.confirmTitle)
        XCTAssertEqual(GigaBallConfirm.swipeUpToPause.dismissTitle, "OK")
    }

    func testACardDriftsFurtherOnTheBiggerScreen() {
        // The figure sixteen screens have each written out for themselves since 2019, in one
        // place as of round 163 so the pop-ups could have it too. The iPad gets the bigger
        // travel because the drift is read against what surrounds it
        XCTAssertEqual(UIView.parallaxTravel(forWidth: 393), 25, "iPhone 17 Pro")
        XCTAssertEqual(UIView.parallaxTravel(forWidth: 430), 25, "the widest phone")
        XCTAssertEqual(UIView.parallaxTravel(forWidth: 834), 50, "iPad")
    }

    func testTheDriftIsReplacedRatherThanStacked() {
        // It is applied from viewDidLayoutSubviews, which runs many times. Each pass must
        // leave one group behind it, or the card drifts further every time the screen lays out
        let card = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        card.applyMenuParallax()
        card.applyMenuParallax()
        card.applyMenuParallax()
        XCTAssertEqual(card.motionEffects.count, 1)
    }

    func testAPopUpStillsEveryDriftingLayerBehindIt() {
        // Round 164: a confirm over a paused game had two drifting layers, because Settings
        // stood its own parallax down by hand and the pause menu did not. The screens hang
        // their drift off different views - containterView, backgroundView - so the pop-up
        // searches for it rather than being told where it is
        let screen = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        let card = UIView(frame: screen.bounds)
        let deeper = UIView(frame: screen.bounds)
        screen.addSubview(card)
        card.addSubview(deeper)
        card.applyMenuParallax()
        deeper.applyMenuParallax()

        let stoodDown = UIView.standDownParallax(under: screen)
        XCTAssertEqual(Set(stoodDown.map(ObjectIdentifier.init)),
                       [ObjectIdentifier(card), ObjectIdentifier(deeper)])
        XCTAssertTrue(card.motionEffects.isEmpty)
        XCTAssertTrue(deeper.motionEffects.isEmpty)

        stoodDown.forEach { $0.applyMenuParallax() }
        XCTAssertEqual(card.motionEffects.count, 1, "and it moves again afterwards")
        XCTAssertEqual(deeper.motionEffects.count, 1)
    }

    func testAGridThatSwallowedItsHeaderKeepsListening() {
        // Round 165: the pack grid spends the first part of a drag collapsing the mode logo,
        // and the room that frees is exactly what makes all eleven packs fit - at which point
        // the fits-so-it-does-not-scroll rule switched scrolling off, the drag stopped being
        // reported, and the logo could never grow back. Found by dragging down and watching
        // nothing happen
        let grid = ContentAwareCollectionView(frame: CGRect(x: 0, y: 0, width: 300, height: 600),
                                              collectionViewLayout: UICollectionViewFlowLayout())
        grid.layoutSubviews()
        XCTAssertFalse(grid.isScrollEnabled, "nothing in it, so nothing to scroll")

        grid.keepsTakingDrags = true
        grid.layoutSubviews()
        XCTAssertTrue(grid.isScrollEnabled, "the collapse has to be givable back")
        XCTAssertTrue(grid.alwaysBounceVertical,
                      "and with everything fitting, only a bounce reports a downward drag")
    }

    func testAStillScreenIsLeftAlone() {
        // Parallax off in settings means nothing to stand down, and nothing to hand back
        let screen = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        screen.addSubview(UIView(frame: screen.bounds))
        XCTAssertTrue(UIView.standDownParallax(under: screen).isEmpty)
    }

    func testResetDataStillSaysWhatSurvivesIt() {
        // The one confirm that cannot be undone. It has always promised that purchases are
        // kept, and a merge is exactly the kind of change that quietly drops a sentence
        let message = GigaBallConfirm.resetData.message
        XCTAssertTrue(message.contains("irreversibly"), message)
        XCTAssertTrue(message.contains("In-app purchases will remain."), message)
    }
}

/// Where the round buttons along the bottom of a menu land.
///
/// The promise is a distance from the *screen's* edge, the same on every screen and the same on
/// both sides, so a thumb learns one place. `layoutMenuButtonRow` keeps it by sharing the
/// leftover width between the buttons - which makes the row's own width an input, and a row
/// measured before it has been laid out is the way this goes wrong.
final class MenuButtonRowTests: XCTestCase {

    private let sizes = Array(repeating: MainMenuCollectionViewCell.smallButtonSize, count: 3)

    /// The pause menus these tests hang a screen off.
    ///
    /// Held here rather than in a local, because a view controller does not retain its parent:
    /// a pause menu that goes out of scope is deallocated at once, `parent` reads nil, and the
    /// screen stops looking like a paused one halfway through the test that says it is.
    private var pauseMenus: [PauseMenuViewController] = []

    override func tearDown() {
        pauseMenus = []
        super.tearDown()
    }

    /// A pause menu with a screen opened from it, as `ReturnToGameButton` recognises the pair.
    private func screenOpenedFromAPausedGame() -> UIViewController {
        let pause = PauseMenuViewController()
        pause.sender = "Pause"
        pauseMenus.append(pause)
        let screen = UIViewController()
        pause.addChild(screen)
        screen.didMove(toParent: pause)
        return screen
    }

    /// A row of the given width, hung in a container the way a menu's is, and laid out.
    ///
    /// `pausedBehind` puts the screen where the pause menu opened it, which is the whole
    /// difference between the two versions of Settings and Information.
    private func laidOutRow(width: CGFloat, leading: CGFloat = 20,
                            sizes: [CGFloat]? = nil,
                            pausedBehind: Bool = false) -> UICollectionViewFlowLayout {
        let host = pausedBehind ? screenOpenedFromAPausedGame() : UIViewController()
        let container = UIView(frame: CGRect(x: 0, y: 0, width: leading*2 + width, height: 200))
        let row = UICollectionView(frame: CGRect(x: leading, y: 0, width: width, height: 50),
                                  collectionViewLayout: UICollectionViewFlowLayout())
        container.addSubview(row)
        host.view.addSubview(container)
        host.layoutMenuButtonRow(row, sizes: sizes ?? self.sizes)
        return row.collectionViewLayout as! UICollectionViewFlowLayout
    }

    func testTheRowIsInsetTheSameOnBothSides() {
        let layout = laidOutRow(width: 362)
        XCTAssertEqual(layout.sectionInset.left, layout.sectionInset.right)
    }

    /// James, round 176, with a screenshot: "Game Centre button on stats screen is too narrow."
    ///
    /// The arithmetic shares `row.frame.width` out, so the three buttons only reach the row's
    /// far end if the width they were shared out of is the one the row ends up with. The stats
    /// screen laid its row out from `viewDidLoad` only - at the storyboard's width - and its
    /// right-hand button, the one screen where that is Game Center, stopped short of the close
    /// button's mirror image. What this pins is the arithmetic being width-dependent at all,
    /// which is why the call has to be repeated once the width is known.
    func testTheButtonsSpanExactlyTheRowTheyWereMeasuredAgainst() {
        for width in [362, 393, 402, 500] as [CGFloat] {
            let layout = laidOutRow(width: width)
            let inset = layout.sectionInset.left
            let spanned = inset*2 + sizes.reduce(0, +)
                        + layout.minimumInteritemSpacing*CGFloat(sizes.count - 1)
            XCTAssertEqual(spanned, width, accuracy: 0.001,
                           "the last button lands \(width - spanned)pt short at width \(width)")
        }
    }

    func testARowLaidOutTwiceEndsUpAtTheSecondWidth() {
        // Which is the fix: `viewDidLayoutSubviews` runs after the width is real
        let narrow = laidOutRow(width: 375).minimumInteritemSpacing
        let wide = laidOutRow(width: 402).minimumInteritemSpacing
        XCTAssertNotEqual(narrow, wide, accuracy: 0.001,
                          "a row laid out at the wrong width cannot be right at the real one")
    }

    func testARowOfSmallButtonsTakesTheWideArrangement() {
        // Round 169: only a row with a big centre button draws its small ones in
        let layout = laidOutRow(width: 362, leading: 0)
        XCTAssertEqual(layout.sectionInset.left, UIViewController.menuButtonWideInset,
                       accuracy: 0.001)
    }

    /// James, round 176: "as the pause screen info and settings views (including child views)
    /// have a big play button, the small buttons should adopt the narrower position. In the main
    /// menu info and settings views, these buttons should adopt the wider position."
    ///
    /// One screen each, reached from two places. The play button is `ReturnToGameButton`'s, and
    /// it is a subview rather than a cell, so the row's own contents cannot tell the two apart.
    func testTheSameScreenOpenedFromAPausedGameDrawsItsButtonsIn() {
        let fromMenu = laidOutRow(width: 362, leading: 0)
        let fromPause = laidOutRow(width: 362, leading: 0, pausedBehind: true)

        XCTAssertEqual(fromMenu.sectionInset.left, UIViewController.menuButtonWideInset,
                       accuracy: 0.001)
        XCTAssertEqual(fromPause.sectionInset.left, UIViewController.menuButtonRowInset,
                       accuracy: 0.001, "grouped around the play button that is on the screen")
    }

    func testAScreenWithNoPausedGameBehindItCarriesNoPlayButton() {
        // The question the row now asks, on its own: this is what makes the two versions differ
        let plain = UIViewController()
        XCTAssertFalse(plain.carriesReturnToGameButton)

        XCTAssertTrue(screenOpenedFromAPausedGame().carriesReturnToGameButton)
    }

    func testAScreenThatTurnsThePlayButtonDownKeepsTheWideArrangement() {
        // The background selector hides the button because it is a picture of the playfield -
        // so there is nothing on screen for its close button to group around
        let picture = screenOpenedFromAPausedGame()
        picture.wantsReturnToGameButton = false
        XCTAssertFalse(picture.carriesReturnToGameButton)
    }

    /// The pause row came through the shared arrangement in round 206, and what it must not
    /// lose in the move is where its outer icons land.
    ///
    /// It used to get there its own way: three 75pt boxes holding 50pt icons, so the icon
    /// carried 12.5pt of padding, so the row started 12.5pt further out than every other
    /// screen's - `pauseButtonRowInset`, 42.5, written a second time as the storyboard's
    /// leading constraint because a storyboard cannot read a constant. The boxes are 50pt now,
    /// that leading is 0, and the shared helper owns the inset outright. Two different routes,
    /// and this pins that they arrive at the same place: 55pt, the one number the whole app
    /// promises about where a thumb lands.
    func testThePauseRowsOuterIconsLandOnTheSharedInset() {
        let storyboardLeading: CGFloat = 0
        let screenWidth: CGFloat = 393
        let sizes = [MainMenuCollectionViewCell.smallButtonSize,
                     MainMenuCollectionViewCell.largeButtonSize,
                     MainMenuCollectionViewCell.smallButtonSize]
        let layout = laidOutRow(width: screenWidth - storyboardLeading*2,
                                leading: storyboardLeading, sizes: sizes)

        XCTAssertEqual(storyboardLeading + layout.sectionInset.left,
                       UIViewController.menuButtonRowInset, accuracy: 0.001,
                       "the pause screen's close button has wandered off the shared inset")
        XCTAssertEqual(layout.sectionInset.left, layout.sectionInset.right, accuracy: 0.001)
    }

    /// And the centre one stays on the row's centre, which is the other half of what
    /// `layoutMenuButtonRow` promises - the pause screen's play button is the thing the other
    /// two are drawn in to group around, so it being off-centre would be visible immediately.
    func testThePauseRowsPlayButtonSitsOnTheRowsCentre() {
        let leading: CGFloat = 0
        let width: CGFloat = 393
        let sizes = [MainMenuCollectionViewCell.smallButtonSize,
                     MainMenuCollectionViewCell.largeButtonSize,
                     MainMenuCollectionViewCell.smallButtonSize]
        let layout = laidOutRow(width: width, leading: leading, sizes: sizes)

        let playStarts = layout.sectionInset.left + sizes[0] + layout.minimumInteritemSpacing
        let playCentre = playStarts + sizes[1]/2
        XCTAssertEqual(playCentre, width/2, accuracy: 0.001)
    }

    func testARowWithABigButtonDrawsTheSmallOnesIn() {
        var withPlay = sizes
        withPlay[1] = MainMenuCollectionViewCell.largeButtonSize
        let layout = laidOutRow(width: 362, leading: 0, sizes: withPlay)
        XCTAssertEqual(layout.sectionInset.left, UIViewController.menuButtonRowInset,
                       accuracy: 0.001)
    }
}

/// How the menus answer being resized.
///
/// §12.0's iPad audit, as arithmetic. iPadOS 26 resizes every app and ignores
/// `UIRequiresFullScreen`, so a window this app never asked for is handed to it anyway - and
/// the sizes that matter are exactly the ones nobody thinks to check by hand: slide over, a
/// half-width split, and the tall-thin and short-wide extremes. `SceneDelegate` sets a
/// 420x640 floor so the window can never be narrower than a phone; there is no API to cap the
/// maximum or the ratio, so everything above that floor is this method's problem.
///
/// **What is capped is the shape** (James, round 182): the menus may be slightly squarer than
/// a phone and no more. **And, since round 322, the size** (James, round 320: "it also needs a
/// height limit"): no wider than `menuMaximumWidth` and no taller than `menuMaximumHeight`,
/// a Pro Max's box with a little air, while nothing phone-sized loses a point.
final class MenuResizeTests: XCTestCase {

    private let ratio: Double = Double(UIViewController.menuMaximumAspectRatio)

    /// Held for the duration, because a view controller does not retain its parent and a
    /// pause menu that goes out of scope is deallocated mid-test - the same trap the button
    /// row tests fell into.
    private var pauseMenus: [PauseMenuViewController] = []

    override func tearDown() {
        pauseMenus = []
        super.tearDown()
    }

    /// The shape the menu is left with: its content width over the window's height.
    private func shape(_ size: CGSize) -> Double {
        let insets = UIViewController.menuContentInsets(available: size)
        return Double((size.width - insets.left - insets.right)/size.height)
    }

    func testTheCapIsSquarerThanAPhoneButNotByMuch() {
        // Phones run 0.46 (17 Pro) to 0.56 (SE); a 13-inch iPad in portrait is 0.75
        XCTAssertGreaterThan(ratio, 0.562, "there would be no point capping tighter than a phone")
        XCTAssertLessThan(ratio, 0.70, "and a 13-inch iPad's own 0.75 is the shape being refused")
    }

    /// **The absolute width is what binds on a large iPad, not the shape** (round 314).
    ///
    /// This asserted the shape cap exactly, and the shape cap alone leaves a 13-inch iPad 853
    /// points of content: narrower than its window and still twice a phone. James, seeing it:
    /// "can we limit how tall and wide the UI elements become. It should really just look like
    /// the phone app with everything centred on the larger background." So the two ceilings are
    /// taken together and the lower wins, which here is the width.
    ///
    /// The half that has not changed is the half round 181 cared about: not one point of
    /// height is given away, so the pack grid still cannot be made to scroll with room to
    /// spare.
    func testAFullScreenIPadIsNarrowedAndShortenedToAPhonesSize() {
        let size = CGSize(width: 1032, height: 1376)   // 13-inch iPad Pro, portrait
        let insets = UIViewController.menuContentInsets(available: size)
        let content = size.width - insets.left - insets.right

        XCTAssertEqual(content, UIViewController.menuMaximumWidth, accuracy: 0.001,
                       "the width ceiling binds here, being lower than the shape's 853")
        XCTAssertLessThan(shape(size), ratio, "and so the result is narrower than the shape cap")
        XCTAssertEqual(size.height - insets.top - insets.bottom,
                       UIViewController.menuMaximumHeight, accuracy: 0.001,
                       "James, round 320: \"it also needs a height limit\"")
        XCTAssertEqual(insets.top, insets.bottom, accuracy: 0.001, "centred top to bottom")
        XCTAssertEqual(insets.left, insets.right, accuracy: 0.001, "centred, not pushed aside")
    }

    /// "To match similar to the largest iPhone, or maybe slightly larger" (James, round 320).
    func testTheHeightCeilingIsJustAboveTheLargestPhone() {
        XCTAssertGreaterThan(UIViewController.menuMaximumHeight, 956,
                             "or a Pro Max would lose height to a cap meant for iPads")
        XCTAssertLessThan(UIViewController.menuMaximumHeight, 1100,
                          "slightly larger, not an iPad's height with a margin")
    }

    /// No phone is touched by the width ceiling, which is what makes it safe to add.
    ///
    /// The widest phone the app supports is about 440 across. If the ceiling ever drops to or
    /// below that, every large phone starts losing width, and this is the assertion that
    /// notices rather than a play test.
    func testTheWidthCeilingIsAboveEveryPhone() {
        XCTAssertGreaterThan(UIViewController.menuMaximumWidth, 440,
                             "or a 17 Pro Max would be clamped by a cap meant for iPads")
    }

    /// A window narrower than the ceiling keeps every point it has.
    func testAWindowNarrowerThanTheCeilingIsUntouched() {
        for width in stride(from: CGFloat(320), through: UIViewController.menuMaximumWidth,
                            by: 20) {
            let size = CGSize(width: width, height: width*3)
            // Tall enough that the shape cap cannot be what binds
            let insets = UIViewController.menuContentInsets(available: size)
            XCTAssertEqual(insets.left, 0, "\(width) wide")
            XCTAssertEqual(insets.right, 0, "\(width) wide")
            // Width only: three times the width is taller than `menuMaximumHeight` for most of
            // these, and the height ceiling has its own tests (round 322)
        }
    }

    func testAPhoneIsLeftAloneEntirely() {
        // Every phone is already narrower than the cap, so nothing is taken from any of them
        for size in [CGSize(width: 402, height: 874),    // iPhone 17 Pro
                     CGSize(width: 375, height: 667),    // SE
                     CGSize(width: 440, height: 956)] {  // 17 Pro Max
            XCTAssertEqual(UIViewController.menuContentInsets(available: size), .zero,
                           "\(size)")
        }
    }

    func testTheSmallestWindowKeepsEverythingItHas() {
        // The floor `SceneDelegate` sets: 420/640 is 0.66, a shade squarer than the cap, so a
        // little width goes - and the height, which it has least of, is untouched
        let size = CGSize(width: 420, height: 640)
        let insets = UIViewController.menuContentInsets(available: size)
        XCTAssertEqual(insets.top, 0)
        XCTAssertEqual(insets.bottom, 0)
        XCTAssertLessThan(insets.left, 12, "and barely any width either")
    }

    func testATallThinWindowKeepsItsWidth() {
        // Slide over: narrower than a phone in shape, which is the shape the menus were built
        // for. Its height is over the ceiling like any iPad's, but it never reaches the helper
        // in the app - a slide-over is a compact width, and `limitMenuContentSize` stops there
        let insets = UIViewController.menuContentInsets(available: CGSize(width: 420,
                                                                         height: 1376))
        XCTAssertEqual(insets.left, 0)
        XCTAssertEqual(insets.right, 0)
    }

    func testAShortWideWindowLosesWidthNotHeight() {
        let size = CGSize(width: 1200, height: 640)   // a landscape half-split
        let insets = UIViewController.menuContentInsets(available: size)
        XCTAssertEqual(insets.top, 0)
        XCTAssertGreaterThan(insets.left, 0)
        XCTAssertEqual(shape(size), ratio, accuracy: 0.001)
    }

    func testNoWindowEverEarnsANegativeInsetOrLosesHeightBelowTheCeiling() {
        // A negative additional safe area grows the content past the screen, which is how a
        // close button ends up off the bottom of a small window
        for width in stride(from: CGFloat(320), through: 1600, by: 40) {
            for height in stride(from: CGFloat(480), through: 2000, by: 40) {
                let insets = UIViewController.menuContentInsets(
                    available: CGSize(width: width, height: height))
                XCTAssertGreaterThanOrEqual(insets.left, 0, "\(width)x\(height)")
                XCTAssertGreaterThanOrEqual(insets.right, 0, "\(width)x\(height)")
                XCTAssertGreaterThanOrEqual(insets.top, 0, "\(width)x\(height)")
                XCTAssertEqual(height - insets.top - insets.bottom,
                               min(height, UIViewController.menuMaximumHeight),
                               accuracy: 0.001,
                               "\(width)x\(height): the ceiling, and not a point more taken")
            }
        }
    }

    func testNothingIsEverLeftSquarerThanTheCap() {
        for width in stride(from: CGFloat(320), through: 1600, by: 40) {
            for height in stride(from: CGFloat(480), through: 2000, by: 40) {
                let size = CGSize(width: width, height: height)
                XCTAssertLessThanOrEqual(shape(size), ratio + 0.001, "\(width)x\(height)")
            }
        }
    }

    /// The nesting rule: menus open on top of one another as child view controllers filling
    /// their parent, so a child inherits the inset its parent already applied. Adding the
    /// full amount again at every level is what halved the content three screens deep.
    func testAChildOnlyMakesUpTheDifferenceItsParentLeft() {
        let size = CGSize(width: 1032, height: 1376)
        let parent = UIViewController.menuContentInsets(available: size)
        let child = UIViewController.menuContentInsets(available: size, inherited: parent)

        XCTAssertEqual(child, .zero,
                       "the parent has already inset it - a second full helping is the bug")
    }

    func testAPartlyInsetParentIsToppedUpRatherThanDoubled() {
        let size = CGSize(width: 1032, height: 1376)
        let half = UIViewController.menuContentInsets(available: size).left/2
        let child = UIViewController.menuContentInsets(
            available: size, inherited: UIEdgeInsets(top: 0, left: half, bottom: 0, right: half))

        XCTAssertEqual(child.left, half, accuracy: 0.001, "topped up to the same total")
    }

    // MARK: - The pause screen's content box

    /// The pause screen, loaded from the storyboard and laid out at a real iPad's size.
    ///
    /// Round 188 measured this off a screenshot and could not explain it by reading; this is
    /// the measurement brought into the suite so the numbers are available without a console.
    /// The screen's whole content lives in `containterView`, whose width is meant to follow
    /// the view's, and in the running app on a 13-inch iPad it came out about 422pt of 1032.
    ///
    /// **These passed even while the app was wrong, and that was the clue.** Laid out here the
    /// box fills its width, because a detached view controller has no `widthClass=regular` to
    /// trip the storyboard's size-class variation and nothing has called
    /// `collectionViewLayout()` to set the width by hand. Those two together were the bug
    /// (round 191, see §12.0); these tests are the shape it must keep, and the phone-sized one
    /// is the guard against a fix for the iPad moving the screen everyone else uses.
    private func laidOutPauseScreen(width: CGFloat, height: CGFloat) -> PauseMenuViewController? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let pause = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController
        else { return nil }
        pause.sender = "Pause"
        pause.levelNumber = 0
        pause.totalStatsArray = [TotalStats()]
        pauseMenus.append(pause)
        pause.loadViewIfNeeded()
        pause.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        pause.view.setNeedsLayout()
        pause.view.layoutIfNeeded()
        return pause
    }

    /// **The content box must be as wide as the screen allows it to be.**
    ///
    /// It is pinned leading to the safe area and centred on the background view, so on any
    /// window with no side safe-area inset it should be the full width. Round 188 found it at
    /// roughly 40% of that on an iPad, which is what put Home beside the title instead of in
    /// its corner and bunched the button row into the middle of the screen.
    func testThePauseScreensContentBoxFillsTheWidthItIsGiven() throws {
        let pause = try XCTUnwrap(laidOutPauseScreen(width: 1032, height: 1376),
                                  "the storyboard no longer has a pauseMenuVC")
        let box = try XCTUnwrap(pause.containterView)

        XCTAssertEqual(box.bounds.width, 1032, accuracy: 1,
                       "the content box is \(box.bounds.width)pt of 1032 - everything on this "
                       + "screen is placed against it, so a narrow box is a screen laid out "
                       + "for a phone on an iPad")
    }

    /// And Home in the corner, which is the symptom a player actually sees.
    func testHomeSitsInTheCornerOnAnIPadToo() throws {
        let pause = try XCTUnwrap(laidOutPauseScreen(width: 1032, height: 1376))
        let home = try XCTUnwrap(pause.homeButton)
        let inView = home.convert(home.bounds, to: pause.view)

        XCTAssertLessThan(inView.minX, 120,
                          "Home is \(inView.minX)pt from the left edge. Its own note says it "
                          + "belongs in the top-left corner while paused, out of the way - at "
                          + "a third of the way across it reads as tucked against the title")
    }

    /// A phone must be unaffected, whatever the fix for the above turns out to be.
    func testAPhoneSizedWindowStillFillsItsWidth() throws {
        let pause = try XCTUnwrap(laidOutPauseScreen(width: 402, height: 874))
        let box = try XCTUnwrap(pause.containterView)
        XCTAssertEqual(box.bounds.width, 402, accuracy: 1)
    }

    // MARK: - The reference grids

    /// The width a grid actually has on a window this size, insets already taken off.
    private func gridWidth(_ size: CGSize) -> CGFloat {
        let menu = UIViewController.menuContentInsets(available: size)
        return size.width - menu.left - menu.right - 2*PackSelectViewController.gridInset
    }

    /// The card `columns` across a grid this wide leaves.
    private func card(_ available: CGFloat, base: CGFloat) -> CGFloat {
        let columns = PackSelectViewController.columns(fitting: available, base: base)
        return (available - PackSelectViewController.gridGap*(columns - 1))/columns
    }

    /// **No phone may change.** The grids were drawn three across a phone and every icon,
    /// name and status note is sized for the card that produces; the count adapting is an
    /// iPad answer and must be invisible everywhere else.
    func testEveryPhoneKeepsTheColumnCountItsGridWasDrawnFor() {
        for width in [CGFloat(320), 375, 390, 393, 402, 430, 440] {
            let available = width - 2*PackSelectViewController.gridInset
            XCTAssertEqual(PackSelectViewController.columns(fitting: available, base: 3), 3,
                           "\(width)pt wide is a phone, and a phone is three across")
            XCTAssertEqual(PackSelectViewController.columns(fitting: available, base: 2), 2,
                           "and two across where the names are sentences")
        }
    }

    /// An iPad, with the aspect cap already applied - the only screen this rule is for.
    func testAnIPadGetsMoreCardsRatherThanBiggerOnes() {
        let phone = card(CGFloat(393) - 2*PackSelectViewController.gridInset, base: 3)
        let pad = card(gridWidth(CGSize(width: 1032, height: 1376)), base: 3)

        XCTAssertGreaterThan(
            PackSelectViewController.columns(
                fitting: gridWidth(CGSize(width: 1032, height: 1376)), base: 3), 3)
        XCTAssertEqual(pad, phone, accuracy: 30,
                       "a card on a 13-inch iPad is the size of a card on a phone, not "
                       + "two and a half times it - the count is what grew")
    }

    /// Across every window iPadOS 26 can hand this app, from the 420pt floor upward.
    ///
    /// Each grid is judged against **its own** phone card, not against a shared number: two
    /// across a phone is already half again the size of three across, and holding a
    /// sentence-named achievement to a power-up's square would be measuring the wrong thing.
    ///
    /// The bound is what rounding to the nearest count allows. A grid takes `n` columns for
    /// any width up to half a card past `n`, so the widest card the rule can leave is about
    /// `(1 + 0.5/n)` of the reference - a quarter over at two across, a fifth at three. 1.35
    /// is that with room, and it is a real ceiling rather than a restatement of the code:
    /// dropping the `.rounded()` for a floor would breach it at once.
    func testNoWindowEverProducesACardMuchBiggerThanAPhones() {
        for base in [CGFloat(2), 3] {
            let phone = card(CGFloat(393) - 2*PackSelectViewController.gridInset, base: base)
            for width in stride(from: CGFloat(420), through: 1400, by: 20) {
                for height in [CGFloat(640), 1024, 1376] {
                    let available = gridWidth(CGSize(width: width, height: height))
                    guard available > 0 else { continue }
                    XCTAssertLessThan(card(available, base: base), phone*1.35,
                                      "\(width)x\(height), base \(base): a card should "
                                      + "stay near the size it was drawn at")
                }
            }
        }
    }

    func testANonsenseWidthFallsBackToTheGridsOwnCount() {
        XCTAssertEqual(PackSelectViewController.columns(fitting: 0, base: 3), 3)
        XCTAssertEqual(PackSelectViewController.columns(fitting: -100, base: 2), 2)
        // A collection view asked to lay out before it has a width answers zero, and the
        // answer has to be a count rather than a crash
    }
}

/// The daily challenge's end screen, which is the fullest screen the app has.
///
/// James, round 241: "the daily challenge end screen is now too crowded so items are getting
/// clipped." It carries a score breakdown, the day's result, a stats summary, a more-stats
/// button, the leaderboard note and the button row - and the breakdown was three stacked rows
/// where two would do.
///
/// Laid out at a real phone size, because that is where it ran out of room. Anything asserted
/// about a screen that was never laid out is asserted about a view with no frame.
final class DailyEndScreenLayoutTests: XCTestCase {

    private var pauseMenus: [PauseMenuViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        InGameRecents.shared.runSummary = nil
        pauseMenus.removeAll()
        super.tearDown()
    }

    /// A finished daily on a single level: the one ending that shows the breakdown.
    private func dailyCompleteScreen(sender: String = "Complete") -> PauseMenuViewController? {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .classic, classicLevel: 0, twists: [])

        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let pause = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController
        else { return nil }
        pause.sender = sender
        pause.levelNumber = 1
        // Not zero. `viewWillAppear` reads a level number of zero as an endless run, and an
        // endless ending has a height where this one has a score - so the whole classic score
        // block, breakdown included, is skipped
        pause.levelTimerBonus = 300
        pause.levelScore = 1200
        pause.score = 1500
        pause.totalStatsArray = [TotalStats()]
        InGameRecents.shared.runSummary = InGameRecents.RunSummary(
            height: 0, durationSeconds: 90, paddleHits: 40, bricksDestroyed: 60,
            ballsLost: 1, powerUpsSeen: 4, powerUpsCollected: 3,
            score: 1500, levelsCleared: 1, isEndless: false)
        // Without one, `updateRunStatsLabel` hides the summary *and* the button at its first
        // guard - so the screen a test looks at would be missing the block the change is about
        // and would agree with the change for the wrong reason

        pauseMenus.append(pause)
        pause.loadViewIfNeeded()
        pause.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        pause.viewWillAppear(false)
        // The labels are written on the way in, not in `viewDidLoad` - and everything here is
        // about what they say and where they end up
        pause.view.setNeedsLayout()
        pause.view.layoutIfNeeded()
        return pause
    }

    /// Level Score and Time Bonus share a line, and the total is under both.
    func testTheBreakdownIsTwoLinesRatherThanThree() throws {
        let pause = try XCTUnwrap(dailyCompleteScreen(),
                                  "the storyboard no longer has a pauseMenuVC")
        XCTAssertTrue(pause.showsDailyBreakdown, "this is the screen the change is about")

        let level = pause.dailyLevelTitle
        let bonus = pause.dailyBonusTitle
        XCTAssertFalse(level.isHidden)
        XCTAssertFalse(bonus.isHidden)

        let levelFrame = level.convert(level.bounds, to: pause.view)
        let bonusFrame = bonus.convert(bonus.bounds, to: pause.view)
        XCTAssertEqual(levelFrame.midY, bonusFrame.midY, accuracy: 1,
                       "Level Score and Time Bonus should be on the same line")
        XCTAssertLessThan(levelFrame.maxX, bonusFrame.minX,
                          "and side by side, with the level score on the left")

        let total = pause.dailyTotalTitle
        let totalFrame = total.convert(total.bounds, to: pause.view)
        XCTAssertGreaterThan(totalFrame.minY, levelFrame.maxY,
                             "the total belongs under both of them")
    }

    /// The rows it borrowed are out of the way, and the total hangs off the columns instead.
    ///
    /// A hidden label still holds its place, so leaving the borrowed pair in the chain would
    /// have kept the total exactly where it was and saved nothing at all - which is the whole
    /// point of the change.
    func testTheBorrowedRowsAreHiddenAndNoLongerHoldTheTotalDown() throws {
        let pause = try XCTUnwrap(dailyCompleteScreen())
        XCTAssertTrue(pause.scoreLabelTitle.isHidden)
        XCTAssertTrue(pause.highscoreLabelTitle.isHidden)
        XCTAssertTrue(pause.dailyTotalUnderColumns.isActive)
        XCTAssertFalse(pause.dailyTotalUnderHighscore.isActive)

        let columns = pause.dailyLevelLabel.convert(pause.dailyLevelLabel.bounds, to: pause.view)
        let total = pause.dailyTotalTitle.convert(pause.dailyTotalTitle.bounds, to: pause.view)
        XCTAssertLessThan(total.minY - columns.maxY, 20,
                          "the total should follow the columns closely - a bigger gap than "
                          + "that means it is still hanging off the rows that were hidden")
    }

    /// And the breakdown counts into its own labels, not the ones it used to borrow.
    func testTheTallyWritesIntoTheColumns() throws {
        let pause = try XCTUnwrap(dailyCompleteScreen())
        XCTAssertEqual(pause.dailyLevelTitle.text, "Level Score")
        XCTAssertEqual(pause.dailyBonusTitle.text, "Time Bonus")
        XCTAssertEqual(pause.dailyTotalTitle.text, "Total Score")
        XCTAssertFalse(pause.dailyLevelLabel.text?.isEmpty ?? true,
                       "the tally should have written a figure by now")
    }

    /// **The end screen reads in the level intro's order** (James, round 320: "on the daily
    /// challenge level intro splash screen, the order of information is good: Game mode icon,
    /// Daily challenge & date info, game mode info, twist info, challenge or free play info...
    /// Use the same layout for the game over, game complete view. For some reason in this view
    /// the challenge or free play info moves to near the bottom of the screen").
    func testTheCompleteScreenSaysTheDayThenTheTwistsThenTheKindOfRun() throws {
        DailyChallengeSession.shared.lastRunPosted = false
        let pause = try XCTUnwrap(dailyCompleteScreen())

        XCTAssertTrue(pause.packNameLabel.text?.hasPrefix("Daily Challenge, ") ?? false,
                      "the day is named, as the intro names it: \(pause.packNameLabel.text ?? "")")
        let lines = (pause.dailySummaryLabel.attributedText?.string ?? "")
            .components(separatedBy: "\n")
        XCTAssertEqual(lines.last, "FREE PLAY", "the kind of run comes after the twists")
        XCTAssertTrue(pause.resultLabel.isHidden,
                      "and is no longer said again down among the numbers")

        let pack = pause.packNameLabel.convert(pause.packNameLabel.bounds, to: pause.view)
        let mode = pause.levelNumberLabel.convert(pause.levelNumberLabel.bounds, to: pause.view)
        let rules = pause.dailySummaryLabel.convert(pause.dailySummaryLabel.bounds, to: pause.view)
        XCTAssertLessThanOrEqual(pack.maxY, mode.minY + 1, "the day above the level")
        XCTAssertLessThanOrEqual(mode.maxY, rules.minY + 1, "and the level above the rules")
    }

    /// The pause menu the same way, where the line had been above the twists.
    func testThePauseMenuPutsTheKindOfRunUnderTheTwists() throws {
        let wasScoring = DailyChallengeSession.shared.isScoringAttempt
        defer { DailyChallengeSession.shared.isScoringAttempt = wasScoring }
        DailyChallengeSession.shared.isScoringAttempt = true
        let pause = try XCTUnwrap(dailyCompleteScreen(sender: "Pause"))
        // Built as a pause screen from the start, the way the game builds a fresh one for every
        // pause. Re-presenting a "Complete" screen as a pause is not something the game does,
        // and it left the first pass's words in place

        let lines = (pause.dailySummaryLabel.attributedText?.string ?? "")
            .components(separatedBy: "\n")
        XCTAssertEqual(lines.last, "COMPETITION RUN")
        XCTAssertTrue(lines.first?.hasSuffix("Vanilla") ?? false,
                      "a no-twist day's badge first, as the intro has it: \(lines)")
        // A suffix, because the line leads with the badge's image attachment
        XCTAssertTrue(pause.packNameLabel.text?.hasPrefix("Daily Challenge, ") ?? false)
    }

    /// A daily says its numbers under the button rather than on the screen.
    ///
    /// "Perhaps the stats summary isn't important in daily challenges. All stats can go under
    /// the more stats button." Nothing is lost - the button is what the detail screen was
    /// always for - and this is the ending with the most competing for the space.
    func testADailyShowsNoStatsSummaryButKeepsTheButton() throws {
        let pause = try XCTUnwrap(dailyCompleteScreen())
        XCTAssertTrue(pause.runStatsLabel.isHidden,
                      "the four lines of numbers are all one tap away")
        XCTAssertFalse(pause.moreStatsButton.isHidden,
                       "and the way to them has to stay")
        // The two spacing constraints go with it - they keep the result line and the stats
        // block apart, and with no stats block there is nothing to keep apart. Asserted through
        // what a player would see rather than through the constraints, which are private: the
        // result line should be able to sit close to the buttons with nothing between them
    }

    /// Everything on the screen stays inside it.
    ///
    /// The symptom James reported was clipping, so this is the assertion that speaks to it
    /// directly rather than to the arrangement that caused it.
    func testNothingOnTheDailyEndScreenIsPushedOffTheBottom() throws {
        let pause = try XCTUnwrap(dailyCompleteScreen())
        let bounds = pause.view.bounds

        for (name, view) in [("total", pause.dailyTotalLabel as UIView),
                             ("more stats", pause.moreStatsButton as UIView),
                             ("buttons", pause.buttonCollectionView as UIView)]
        where view.isHidden == false {
            let frame = view.convert(view.bounds, to: pause.view)
            XCTAssertLessThanOrEqual(frame.maxY, bounds.maxY,
                                     "\(name) runs \(frame.maxY - bounds.maxY)pt off the "
                                     + "bottom of a \(Int(bounds.height))pt screen")
            XCTAssertGreaterThanOrEqual(frame.minY, 0, "\(name) runs off the top")
        }
    }
}

/// The Quick Start Guide shows every page that has been drawn for it.
///
/// The guide is pictures, named `IntroView1` upwards, and listed by hand in
/// `IntroPageViewController.populateItems`. Round 322 imported three of James's 1.3 pages, and a
/// picture imported and never listed is a page nobody sees - with nothing anywhere to say so.
final class QuickStartGuideTests: XCTestCase {

    func testEveryDrawnPageIsInTheGuideOnce() {
        var drawn: [String] = []
        var number = 1
        while UIImage(named: "IntroView\(number)") != nil {
            drawn.append("IntroView\(number)")
            number += 1
        }
        // Read off the asset catalogue rather than written down: the names run unbroken from
        // 1, so the first one missing is the end of the set
        XCTAssertGreaterThanOrEqual(drawn.count, 8, "James's three 1.3 pages are imported")

        let guide = IntroPageViewController()
        guide.populateItems()
        let shown = guide.items.compactMap { ($0.view as? IntroContainerView)?.introImage.image }
        XCTAssertEqual(shown.count, guide.items.count, "every page has its picture")
        XCTAssertEqual(guide.items.count, drawn.count,
                       "one page for every picture drawn, no more and no fewer")
        for name in drawn {
            let image = UIImage(named: name)
            XCTAssertEqual(shown.filter { $0.pngData() == image?.pngData() }.count, 1,
                           "\(name) should appear exactly once")
        }
    }
}

/// **Reset Data resets everything it says it does** (round 323's coverage pass: the Settings
/// screen had none of its 1,020 lines run under test, and this is the one action on it that
/// cannot be undone).
///
/// It could not be tested before without wiping the simulator app's real stats: the screen's
/// settings store, stats file and save were all fixed to the app's own. They are the screen's to
/// be told now, and a test hands it a suite and a temporary file.
final class SettingsResetDataTests: XCTestCase {

    private let suiteName = "GigaBallTests.SettingsReset"
    private var statsFile: URL!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
        statsFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName + ".totalStats.plist")
        try? FileManager.default.removeItem(at: statsFile)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: statsFile)
        super.tearDown()
    }

    func testResetDataPutsEverySettingBackAndForgetsTheRun() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(false, forKey: "soundsSetting")
        defaults.set(false, forKey: "musicSetting")
        defaults.set(false, forKey: "swipeUpPause")
        defaults.set(7, forKey: "ballSetting")
        defaults.set(1, forKey: "brickSetting")
        defaults.set(42, forKey: "appOpenCount")
        // A player who has played a while and changed things

        let save = SavedGame(
            levelNumber: 3, endLevelNumber: 10, packNumber: 2, levelScore: 10, totalScore: 900,
            numberOfLives: 2, endlessHeight: 0, numberOfLevels: 10, levelTimerValue: 1,
            packTimerValue: 1, deathsPerLevel: 0, deathsPerPack: 0,
            powerUpsGeneratedPerLevel: 0, powerUpsCollectedPerLevel: 0,
            powerUpsGeneratedPerPack: 0, powerUpsCollectedPerPack: 0, paddleHitsPerLevel: 0,
            multiplier: 1, brickTextures: [], brickColours: [], brickXPositions: [],
            brickYPositions: [], ballProperties: [], fallingPowerUpXPositions: [],
            fallingPowerUpYPositions: [], fallingPowerUps: [], activePowerUps: [],
            activePowerUpDurations: [], activePowerUpTimers: [], activePowerUpMagnitudes: [])
        save.save(to: defaults)
        XCTAssertNotNil(SavedGame.load(from: defaults), "a run left to resume")

        var played = TotalStats()
        played.levelsPlayed = 120
        played.cumulativeScore = 98_765

        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SettingsViewController.self))
        let settings = try XCTUnwrap(board.instantiateViewController(withIdentifier: "settingsVC")
                                        as? SettingsViewController)
        settings.defaults = defaults
        settings.totalStatsStore = statsFile
        settings.navigatedFrom = "PauseMenu"
        // Told before its view loads, because loading reads all three - and unwraps the last
        settings.loadViewIfNeeded()
        settings.totalStatsArray = [played]
        // After, in case loading read the (absent) file over it

        settings.resetData()

        XCTAssertTrue(defaults.bool(forKey: "soundsSetting"), "sounds back on")
        XCTAssertTrue(defaults.bool(forKey: "musicSetting"), "music back on")
        XCTAssertTrue(defaults.bool(forKey: "swipeUpPause"), "swipe up to pause back on")
        XCTAssertEqual(defaults.integer(forKey: "ballSetting"), 0, "the first ball")
        XCTAssertEqual(defaults.integer(forKey: "brickSetting"), 0, "the standard bricks")
        XCTAssertEqual(defaults.integer(forKey: "appOpenCount"), 0)

        XCTAssertNil(SavedGame.load(from: defaults),
                     "the run is forgotten - a reset that left a resume behind would bring back "
                     + "a game from before it")
        XCTAssertEqual(settings.totalStatsArray[0].levelsPlayed, 0, "the stats start again")
        XCTAssertEqual(settings.totalStatsArray[0].cumulativeScore, 0)

        let written = try PropertyListDecoder().decode([TotalStats].self,
                                                       from: Data(contentsOf: statsFile))
        XCTAssertEqual(written.first?.levelsPlayed, 0, "and the file on disk says so too")
    }
}
