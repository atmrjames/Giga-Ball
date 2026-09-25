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

    func testResetDataSaysWhatItTakesAndNothingAboutAShopThatIsGone() {
        // The one confirm that cannot be undone, so what it warns about has to stay said.
        //
        // **And the purchases line is gone** (round 328). It promised that in-app purchases
        // survive a reset, which was true when there were purchases; the monetisation
        // architecture came out before 1.3 and every StoreKit call in the app is commented
        // out, so the sentence was telling players about a shop the app does not have. This
        // asserts the promise that is still true and the sentence that must not come back.
        let message = GigaBallConfirm.resetData.message
        XCTAssertTrue(message.contains("irreversibly"), message)
        XCTAssertTrue(message.contains("progress, statistics and settings"), message)
        XCTAssertFalse(message.lowercased().contains("in-app"), message)
        XCTAssertFalse(message.lowercased().contains("purchase"), message)
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

    /// Level Score and Speed Bonus share a line, and the total is under both.
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
                       "Level Score and Speed Bonus should be on the same line")
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
        XCTAssertEqual(pause.dailyBonusTitle.text, "Speed Bonus")
        // James, round 332: "time bonus should be speed bonus"
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

        XCTAssertTrue(pause.packNameLabel.text?.hasPrefix("Daily Challenge\n") ?? false,
                      "the day is named, as the intro names it: \(pause.packNameLabel.text ?? "")")
        // On its own line since round 332, on both screens: "put the date on the line below
        // Daily Challenge to avoid any clipping on smaller devices"
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
        XCTAssertTrue(pause.packNameLabel.text?.hasPrefix("Daily Challenge\n") ?? false)
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

        let played = TotalStats()
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

/// **Every icon the app's pop-ups wear, drawn for review** (James, round 327b: "can you show me
/// all the icons that are used in the pop-up views throughout the app and what they're used for?
/// I'd like to review them and make sure I'm happy with them").
///
/// Rendered the way `GigaBallAlert` renders them - 30pt bold, the app's lime, on the pop-up's own
/// dark ground - so what is reviewed is what a player sees rather than an approximation of it.
/// The five questions come from `GigaBallConfirm` itself; the free-standing messages name their
/// symbol at the call site, so those are listed here with where they are raised.
final class PopUpIconSheetTests: XCTestCase {

    /// The messages that are not `GigaBallConfirm` cases, with where each is raised.
    private let messages: [(symbol: String, title: String, raised: String)] = [
        ("sparkles", "What's New in 1.3", "Main menu, first launch after an update"),
        ("calendar.badge.exclamationmark", "Challenge Closed",
         "Pause menu, resuming a daily whose day has ended"),
        ("dice.fill", "Today's Twists", "Pause menu and the Daily Challenge card"),
        ("dice.fill", "A twist's own explainer", "Daily Challenge card, tapping one twist"),
        ("arrow.up.circle.fill", "A power-up's explainer", "Pause menu, tapping a power-up"),
        ("gamecontroller.fill", "Free play", "Daily Challenge, after the scoring attempt"),
        ("hand.draw.fill", "Swipe Up To Pause", "Settings, turning the gesture on"),
    ]

    func testEverySymbolThePopUpsAskForExists() {
        for confirm in GigaBallConfirm.allCases {
            XCTAssertNotNil(UIImage(systemName: confirm.symbol),
                            "\(confirm.title) asks for \(confirm.symbol), which iOS does not have")
        }
        for message in messages {
            XCTAssertNotNil(UIImage(systemName: message.symbol),
                            "\(message.title) asks for \(message.symbol)")
        }
    }

    /// Each icon on its own, drawn as the pop-up draws it, for a page that lays them out itself.
    func testEachPopUpIconCanBeLookedAtOnItsOwn() throws {
        let lime = UIColor(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        let side: CGFloat = 96
        let folder = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pop-up-icons", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        var written = 0
        for symbol in Set(GigaBallConfirm.allCases.map(\.symbol) + messages.map(\.symbol)) {
            let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
                guard let drawn = UIImage(systemName: symbol,
                                          withConfiguration: UIImage.SymbolConfiguration(
                                            pointSize: 44, weight: .bold))?
                    .withTintColor(lime, renderingMode: .alwaysOriginal) else { return }
                drawn.draw(at: CGPoint(x: side/2 - drawn.size.width/2,
                                       y: side/2 - drawn.size.height/2))
            }
            let name = symbol.replacingOccurrences(of: ".", with: "-") + ".png"
            try XCTUnwrap(image.pngData()).write(to: folder.appendingPathComponent(name))
            written += 1
        }
        print("\n  Pop-up icons, one each: \(folder.path)\n  \(written) files\n")
        XCTAssertGreaterThan(written, 0)
    }

    func testThePopUpIconsCanBeLookedAt() throws {
        let entries: [(symbol: String, title: String, detail: String)] =
            GigaBallConfirm.allCases.map {
                ($0.symbol, $0.title, "Question - " + $0.message.replacingOccurrences(of: "\n", with: " "))
            } + messages.map { ($0.symbol, $0.title.uppercased(), "Message - " + $0.raised) }

        let rowHeight: CGFloat = 76
        let size = CGSize(width: 720, height: rowHeight*CGFloat(entries.count) + 24)
        let sheet = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.10, green: 0.02, blue: 0.16, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            for (index, entry) in entries.enumerated() {
                let top = 12 + CGFloat(index)*rowHeight
                let lime = UIColor(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
                if let image = UIImage(systemName: entry.symbol,
                                       withConfiguration: UIImage.SymbolConfiguration(
                                        pointSize: 30, weight: .bold))?
                    .withTintColor(lime, renderingMode: .alwaysOriginal) {
                    image.draw(at: CGPoint(x: 40 - image.size.width/2 + 20,
                                           y: top + rowHeight/2 - image.size.height/2 - 6))
                }
                (entry.title as NSString).draw(
                    at: CGPoint(x: 110, y: top + 12),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 17, weight: .bold),
                                     .foregroundColor: UIColor.white])
                (entry.symbol as NSString).draw(
                    at: CGPoint(x: 110, y: top + 34),
                    withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                                     .foregroundColor: UIColor(white: 1, alpha: 0.5)])
                let detail = entry.detail.count > 92
                    ? String(entry.detail.prefix(92)) + "..." : entry.detail
                (detail as NSString).draw(
                    at: CGPoint(x: 340, y: top + 22),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 13),
                                     .foregroundColor: UIColor(white: 1, alpha: 0.75)])
                UIColor(white: 1, alpha: 0.12).setFill()
                context.fill(CGRect(x: 24, y: top + rowHeight - 1, width: size.width - 48, height: 1))
            }
        }

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("pop-up-icons.png")
        try XCTUnwrap(sheet.pngData()).write(to: url)
        print("\n  Pop-up icons, drawn: \(url.path)\n  \(entries.count) icons\n")
        XCTAssertEqual(entries.count, GigaBallConfirm.allCases.count + messages.count)
    }
}

/// **What a screen reader hears on a menu** (round 328).
///
/// Every round button along the bottom of every screen is a picture of a glyph in a circle, so
/// until now VoiceOver had a bare "button" to offer for each of the three or four on screen -
/// which is the same as offering nothing. `setButton` is the one funnel they all come through,
/// so it is where the name is given.
final class RoundButtonVoiceOverTests: XCTestCase {

    private func cell() throws -> MainMenuCollectionViewCell {
        let nib = UINib(nibName: "MainMenuCollectionViewCell",
                        bundle: Bundle(for: MainMenuCollectionViewCell.self))
        return try XCTUnwrap(nib.instantiate(withOwner: nil).first as? MainMenuCollectionViewCell)
    }

    func testAButtonIsNamedForWhatItDoes() throws {
        for (artwork, spoken) in MainMenuCollectionViewCell.spokenName {
            let cell = try cell()
            cell.setButton(artwork + ".png")
            XCTAssertTrue(cell.isAccessibilityElement, artwork)
            XCTAssertEqual(cell.accessibilityLabel, spoken, artwork)
            XCTAssertTrue(cell.accessibilityTraits.contains(.button), artwork)
        }
    }

    /// The pressed artwork is the same button, so it keeps the same name.
    func testTheHighlightedArtworkKeepsTheName() throws {
        let cell = try cell()
        cell.setButton("ButtonLeaderboardHighlighted.png")
        XCTAssertEqual(cell.accessibilityLabel, "Leaderboards")
    }

    /// `ButtonNull` is the invisible spacer that keeps a three-cell row even. A reader that
    /// stops on it is a reader announcing a gap.
    func testTheSpacerIsNotSomethingToStopOn() throws {
        let cell = try cell()
        cell.setButton("ButtonNull")
        XCTAssertFalse(cell.isAccessibilityElement)
        XCTAssertNil(cell.accessibilityLabel)
    }

    /// Every button that can become glass has a name, which is the list read the other way:
    /// a new button added to one table and not the other is a button with no name.
    func testEveryGlassButtonHasASpokenName() {
        for artwork in MainMenuCollectionViewCell.systemGlyph.keys {
            XCTAssertNotNil(MainMenuCollectionViewCell.spokenName[artwork],
                            "\(artwork) can be glassed but has nothing to say")
        }
    }
}

/// **Motion effects stand down when the system asks for less motion** (round 328).
///
/// The app has had a parallax setting of its own since long before this - the Settings row calls
/// it Perspective Zoom - and what it did not have was any regard for the setting a player makes
/// once, for every app on the phone. Apple's rule is that the app stops animating and leaves its
/// own setting alone, so nothing changes back when Reduce Motion is switched off again.
final class ReduceMotionTests: XCTestCase {

    func testTheAppAsksTheSystemRatherThanAssuming() {
        XCTAssertEqual(UIView.motionEffectsAreWelcome,
                       UIAccessibility.isReduceMotionEnabled == false,
                       "the answer is the system's, whatever the simulator is set to")
    }

    /// And the parallax helper every screen shares refuses to add one while that is true.
    func testNoMotionEffectIsAddedWhenMotionIsNotWelcome() throws {
        try XCTSkipUnless(UIAccessibility.isReduceMotionEnabled,
                          "Reduce Motion is off on this simulator, so there is nothing to assert "
                          + "- turn it on in Settings > Accessibility > Motion to run this")
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 393, height: 852))
        view.applyMenuParallax()
        XCTAssertTrue(view.motionEffects.isEmpty)
    }
}

/// **A way to start the level again without leaving it** (James, round 329: "yes, add a restart
/// button, that is a good idea! Restart only shows up at game over, so show restart in the pop-up
/// on occasions where it isn't already available in the main view").
///
/// The pause screen carries Info, Play and Settings; the replay button only appears once a run
/// has ended. So a player who paused, thought about quitting and changed their mind had no way to
/// start the level again short of doing it. The Main Menu question offers it as a third answer,
/// and only where the screen behind has none of its own.
final class RestartOnTheMainMenuConfirmTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func pauseScreen(sender: String) -> PauseMenuViewController {
        let screen = PauseMenuViewController()
        screen.sender = sender
        return screen
    }

    func testAnOrdinaryPauseOffersIt() {
        XCTAssertTrue(pauseScreen(sender: "Pause").offersRestartInTheConfirm)
    }

    /// A finished run has its own replay button, so the question does not repeat it.
    func testAFinishedRunDoesNot() {
        for sender in ["Game Over", "Complete"] {
            XCTAssertFalse(pauseScreen(sender: sender).offersRestartInTheConfirm, sender)
        }
    }

    /// **And never in a Daily Challenge**, where the scoring attempt is spent the moment it
    /// starts - which is why the daily's own game over has no replay either.
    func testADailyDoesNotOfferIt() {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-09-20", mode: .endlessII, classicLevel: nil, twists: [])
        XCTAssertFalse(pauseScreen(sender: "Pause").offersRestartInTheConfirm)
    }
}

/// **What a pop-up with three answers looks like** (round 329).
///
/// Two answers sit side by side and read as a choice. Three across a card this wide would be
/// three cramped words, so they stack: what was asked for first, the way out second, the way back
/// last. Every other pop-up in the app has two and is untouched.
final class PopUpWithAThirdAnswerTests: XCTestCase {

    private func buttons(in view: UIView) -> [UIButton] {
        view.subviews.flatMap { [$0].compactMap { $0 as? UIButton } + buttons(in: $0) }
    }

    private func stack(in view: UIView) -> UIStackView? {
        for subview in view.subviews {
            if let found = subview as? UIStackView,
               found.arrangedSubviews.contains(where: { $0 is UIButton }) { return found }
            if let deeper = stack(in: subview) { return deeper }
        }
        return nil
    }

    private func shown(third: Bool) -> UIViewController {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = host
        window.isHidden = false
        GigaBallAlert.show(on: host, title: "Main Menu", message: "Are you sure?",
                           symbol: "house.fill", dismissTitle: "Cancel", dismiss: {},
                           confirmTitle: "OK", confirm: {},
                           otherTitle: third ? "Restart" : nil,
                           other: third ? {} : nil)
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        return host
    }

    func testTwoAnswersStaySideBySide() throws {
        let host = shown(third: false)
        let row = try XCTUnwrap(stack(in: host.view))
        XCTAssertEqual(row.axis, .horizontal)
        XCTAssertEqual(row.arrangedSubviews.compactMap { $0 as? UIButton }.count, 2)
    }

    func testThreeAnswersStackInOrder() throws {
        let host = shown(third: true)
        let column = try XCTUnwrap(stack(in: host.view))
        XCTAssertEqual(column.axis, .vertical, "three across a card is three cramped words")

        let titles = column.arrangedSubviews.compactMap { ($0 as? UIButton)?.title(for: .normal) }
        XCTAssertEqual(titles, ["OK", "Restart", "Cancel"],
                       "what was asked for, then the way out, then the way back")
    }

    /// Every button is still reachable: a stacked card must not push one off the bottom.
    ///
    /// The three in the stack, not every `UIButton` in the hierarchy - the glass material behind
    /// each one carries its own, sized to nothing, and a test that measures those is measuring
    /// the decoration rather than the controls.
    func testAllThreeAnswersAreInsideTheCard() throws {
        let host = shown(third: true)
        let column = try XCTUnwrap(stack(in: host.view))
        for button in column.arrangedSubviews.compactMap({ $0 as? UIButton }) {
            let frame = button.convert(button.bounds, to: host.view)
            XCTAssertGreaterThanOrEqual(frame.minY, 0, "\(button.title(for: .normal) ?? "") is off the top")
            XCTAssertLessThanOrEqual(frame.maxY, host.view.bounds.height,
                                     "\(button.title(for: .normal) ?? "") is off the bottom")
            XCTAssertGreaterThan(frame.height, 30, "too short to tap")
        }
    }
}

/// **Nothing a run started may fire after the run has gone** (round 329, from James's device log:
/// `Fatal error: Attempted to read an unowned reference but the object was already destroyed`,
/// the moment a Daily Challenge started straight after a Mayhem run ended).
final class SceneTeardownTests: XCTestCase {

    private func scene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    func testLeavingCancelsTheScenesOwnActions() {
        let scene = self.scene()
        scene.run(.repeatForever(.sequence([.wait(forDuration: 1), .run {}])), withKey: "gameTimer")
        XCTAssertNotNil(scene.action(forKey: "gameTimer"))

        scene.endEverythingInFlight()

        XCTAssertNil(scene.action(forKey: "gameTimer"),
                     "a cancelled action runs no completion, which is the whole of the fix")
    }

    /// **The crash James could reproduce every time** (round 332: "app keeps crashing when
    /// exiting one game mode and starting another - this is a reliable and easily repeatable
    /// crash, it happens every time").
    ///
    /// A Mayhem run ends, Home takes the menus back, Classic starts - and the new run's level
    /// intro posts `continueToNextLevel` as it clears, which the *old* run's `InbetweenLevels`
    /// was still registered for. Its handler's first line reads `scene`, held `unowned`, and
    /// the old scene has gone. A state's `deinit` cannot be the answer: `GKStateMachine` holds
    /// its states and each state holds its machine back, so the pair outlives the scene that
    /// made them. Leaving the run has to take them off the notification centre.
    func testAStateStopsListeningWhenTheRunIsLeft() {
        let scene = self.scene()
        scene.gameState.enter(InbetweenLevels.self)
        XCTAssertTrue(scene.gameState.currentState is InbetweenLevels,
                      "the state the game-over card is shown from")

        scene.endEverythingInFlight()
        NotificationCenter.default.post(name: .continueToNextLevel, object: nil)

        XCTAssertTrue(scene.gameState.currentState is InbetweenLevels,
                      "a left run answered the next run's intro, which is the crash")
    }

    /// And the scene's own eight registrations go the same way.
    func testTheSceneStopsListeningWhenTheRunIsLeft() {
        let scene = self.scene()
        scene.gameState.enter(Playing.self)
        scene.endEverythingInFlight()

        NotificationCenter.default.post(name: .restartGameNotificiation, object: nil)

        XCTAssertFalse(scene.gameState.currentState is PreGame,
                       "a left run restarted itself from a notification meant for the next one")
    }

    func testLeavingCancelsWhatTheChildrenAreDoing() {
        let scene = self.scene()
        scene.addChild(scene.ball)
        scene.ball.run(.repeatForever(.rotate(byAngle: 1, duration: 1)), withKey: "spin")
        XCTAssertTrue(scene.ball.hasActions())

        scene.endEverythingInFlight()

        XCTAssertFalse(scene.ball.hasActions())
    }

    /// The laser timer retains the scene, so a run quit mid-Lasers kept the whole scene - and
    /// everything it owns - alive for ever, still generating lasers nobody could see.
    func testLeavingInvalidatesTheLaserTimer() {
        let scene = self.scene()
        scene.laserTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in }
        XCTAssertEqual(scene.laserTimer?.isValid, true)

        scene.endEverythingInFlight()

        XCTAssertNil(scene.laserTimer)
    }
}

/// The bottom button row, at every width a window can be dragged to.
///
/// **James, round 339, from an iPad with the window dragged narrow: "it's possible to resize
/// the window to a point where the UI buttons at the bottom aren't symmetrical any more - the
/// settings button is too narrow and the info button is too wide - it's also possible that the
/// settings button disappears when the window is particularly narrow."**
final class MenuButtonRowFitTests: XCTestCase {

    /// A row of two small buttons, the arrangement the main menu uses.
    private let smalls = [MainMenuCollectionViewCell.smallButtonSize,
                          MainMenuCollectionViewCell.smallButtonSize]

    /// A row with a big play button in the middle, the pause screen's.
    private let withPlay = [MainMenuCollectionViewCell.smallButtonSize,
                            MainMenuCollectionViewCell.largeButtonSize,
                            MainMenuCollectionViewCell.smallButtonSize]

    private func laidOut(width: CGFloat, sizes: [CGFloat]) -> UICollectionViewFlowLayout {
        let screen = UIViewController()
        screen.view.frame = CGRect(x: 0, y: 0, width: width, height: 700)
        let row = UICollectionView(frame: CGRect(x: 0, y: 600, width: width, height: 75),
                                   collectionViewLayout: UICollectionViewFlowLayout())
        screen.view.addSubview(row)
        screen.layoutMenuButtonRow(row, sizes: sizes)
        return row.collectionViewLayout as! UICollectionViewFlowLayout
    }

    /// Everything in the row fits inside the row, however narrow the window gets.
    func testEveryButtonStaysInsideTheRow() {
        for width in stride(from: 300.0, through: 1100.0, by: 20.0) {
            // From 300: the narrowest window iOS hands an app is a 320-point Slide Over pane,
            // and a row holding a 75-point play button between two 50s cannot be made to fit
            // anything much under that however the inset gives way. The promise is about every
            // window a player can actually make, not about every number.
            for (what, sizes) in [("two small buttons", smalls), ("a play button", withPlay)] {
                let layout = laidOut(width: CGFloat(width), sizes: sizes)
                let content = layout.sectionInset.left + layout.sectionInset.right
                    + sizes.reduce(0, +)
                    + layout.minimumInteritemSpacing*CGFloat(max(sizes.count - 1, 1))

                XCTAssertLessThanOrEqual(content, CGFloat(width) + 0.5,
                    "\(what) at \(Int(width))pt: the row needs \(Int(content))pt and has "
                    + "\(Int(width)). The flow layout does not shrink a cell - it pushes the "
                    + "last one out of the visible row, which is the settings button James "
                    + "watched disappear")
            }
        }
    }

    /// And what is left of the inset is left of it on both sides.
    func testTheRowStaysSymmetric() {
        for width in stride(from: 300.0, through: 1100.0, by: 20.0) {
            let layout = laidOut(width: CGFloat(width), sizes: smalls)
            XCTAssertEqual(layout.sectionInset.left, layout.sectionInset.right, accuracy: 0.5,
                           "at \(Int(width))pt the row is inset \(layout.sectionInset.left) on "
                           + "the left and \(layout.sectionInset.right) on the right")
            XCTAssertGreaterThanOrEqual(layout.sectionInset.left, 0,
                                        "a negative inset hangs the row off the screen")
        }
    }

    /// The gap never closes to nothing, so two buttons never touch.
    func testTwoButtonsNeverTouch() {
        for width in stride(from: 200.0, through: 1100.0, by: 20.0) {
            let layout = laidOut(width: CGFloat(width), sizes: smalls)
            XCTAssertGreaterThanOrEqual(layout.minimumInteritemSpacing,
                                        UIViewController.menuButtonLeastGap - 0.5,
                                        "at \(Int(width))pt the buttons are "
                                        + "\(layout.minimumInteritemSpacing)pt apart")
        }
    }
}

/// How wide the content is allowed to be, at every window width.
///
/// **James, round 339: "the cell views expand with the window until a point, then snap back to
/// a set width once the window is wide enough. Can we just make this set width the maximum
/// width of the cell views so there's no need for them to snap back?"**
final class MenuContentWidthTests: XCTestCase {

    /// What the content is left with once the insets are taken off.
    private func contentWidth(_ width: CGFloat, height: CGFloat, regular: Bool) -> CGFloat {
        let insets = UIViewController.menuContentInsets(
            available: CGSize(width: width, height: height), widthOnly: regular == false)
        return width - insets.left - insets.right
    }

    /// Never wider than the cap, whatever the window is doing.
    func testTheContentNeverExceedsItsMaximum() {
        for width in stride(from: 320.0, through: 1400.0, by: 20.0) {
            for height in [700.0, 1000.0, 1376.0] {
                for regular in [true, false] {
                    let content = contentWidth(CGFloat(width), height: CGFloat(height),
                                               regular: regular)
                    XCTAssertLessThanOrEqual(content,
                                             UIViewController.menuMaximumWidth + 0.5,
                        "\(Int(width))x\(Int(height)), regular \(regular): content is "
                        + "\(Int(content))pt")
                }
            }
        }
    }

    /// And it does not jump when the window crosses from compact to regular.
    ///
    /// That crossing is what James was watching: the same window, one point wider, suddenly
    /// laid out to a different width. Both sides of it now answer with the cap.
    func testThereIsNoStepWhenTheWidthClassChanges() {
        for width in stride(from: 480.0, through: 900.0, by: 10.0) {
            let compact = contentWidth(CGFloat(width), height: 1376, regular: false)
            let regular = contentWidth(CGFloat(width), height: 1376, regular: true)
            XCTAssertEqual(compact, regular, accuracy: 0.5,
                "at \(Int(width))pt a compact window lays out \(Int(compact))pt of content and "
                + "a regular one \(Int(regular)) - which is the snap")
        }
    }

    /// A phone is untouched: none of them is as wide as the cap.
    func testAPhoneIsNotInsetAtAll() {
        for width in [320.0, 375.0, 390.0, 402.0, 430.0, 440.0] {
            let insets = UIViewController.menuContentInsets(
                available: CGSize(width: width, height: 874), widthOnly: true)
            XCTAssertEqual(insets.left, 0, accuracy: 0.01, "\(Int(width))pt wide")
            XCTAssertEqual(insets.right, 0, accuracy: 0.01)
            XCTAssertEqual(insets.top, 0, accuracy: 0.01,
                           "and a compact window keeps its full height")
        }
    }
}

/// The main menu's own button row, dragged narrower after it has been laid out.
///
/// **James, round 341, from an iPad: "the settings icon on the main menu is still disappearing
/// when the screen is narrow."** Round 339's `MenuButtonRowFitTests` checks the shared
/// `layoutMenuButtonRow`, which every other screen uses - and the main menu does not. Its row
/// has its own arithmetic, which ran once as the screen loaded, so the spacing between the
/// cells was whatever the window's width was then. This drives the real screen through a
/// resize, which is the thing James did.
final class MainMenuButtonRowResizeTests: XCTestCase {

    private var windows: [UIWindow] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        super.tearDown()
    }

    func testEveryButtonIsStillInTheRowAfterTheWindowNarrows() throws {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: MenuViewController.self))
        let menu = try XCTUnwrap(board.instantiateViewController(withIdentifier: "menuView")
                                    as? MenuViewController)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 820, height: 1000))
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = menu
        window.isHidden = false
        windows.append(window)

        func settle() {
            for _ in 0..<4 {
                window.setNeedsLayout()
                window.layoutIfNeeded()
                menu.iconCollectionView.layoutIfNeeded()
            }
        }
        settle()

        for width in [600, 480, 420, 380, 340] as [CGFloat] {
            window.frame = CGRect(x: 0, y: 0, width: width, height: 1000)
            settle()

            let row = try XCTUnwrap(menu.iconCollectionView)
            let placed = (0..<row.numberOfItems(inSection: 0)).compactMap {
                row.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: $0, section: 0))
            }
            XCTAssertEqual(placed.count, 3, "\(Int(width))pt: the row lost a cell")
            for cell in placed {
                XCTAssertLessThanOrEqual(cell.frame.maxX, row.bounds.width + 0.5,
                    "\(Int(width))pt: a button is laid out at \(Int(cell.frame.minX)) in a row "
                    + "\(Int(row.bounds.width)) wide, which is off its end - the settings "
                    + "button James watched disappear")
                XCTAssertEqual(cell.frame.minY, placed[0].frame.minY, accuracy: 0.5,
                    "\(Int(width))pt: a button has been pushed onto a second line")
            }
        }
    }
}


/// The settings rows, tapped (round 345).
///
/// The CRAP pass ranked `SettingsViewController.tableView(_:didSelectRowAt:)` second in the app:
/// thirty-one decisions and not one line run by a test. Each switch is tapped here against a
/// settings store of the test's own, and what it wrote is read back.
final class SettingsRowTapTests: XCTestCase {

    private let suiteName = "SettingsRowTapTests"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName + ".plist"))
        super.tearDown()
    }

    private func settings() throws -> (SettingsViewController, UserDefaults) {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        for key in ["soundsSetting", "musicSetting", "hapticsSetting", "parallaxSetting",
                    "swipeUpPause", InterfaceSound.settingKey] {
            defaults.set(true, forKey: key)
        }
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SettingsViewController.self))
        let screen = try XCTUnwrap(board.instantiateViewController(withIdentifier: "settingsVC")
                                    as? SettingsViewController)
        screen.defaults = defaults
        screen.totalStatsStore = FileManager.default.temporaryDirectory
            .appendingPathComponent(suiteName + ".plist")
        screen.navigatedFrom = "MainMenu"
        screen.loadViewIfNeeded()
        return (screen, defaults)
    }

    private func tap(_ row: SettingsViewController.SettingRow,
                     on screen: SettingsViewController) throws {
        let index = try XCTUnwrap(screen.settingRows.firstIndex(of: row), "\(row) is offered")
        screen.tableView(screen.settingsTableView, didSelectRowAt: IndexPath(row: index, section: 0))
    }

    func testInGameSoundTurnsOffAndOn() throws {
        let (screen, defaults) = try settings()
        try tap(.sounds, on: screen)
        XCTAssertFalse(defaults.bool(forKey: "soundsSetting"))
        try tap(.sounds, on: screen)
        XCTAssertTrue(defaults.bool(forKey: "soundsSetting"))
    }

    /// James, round 341: "a new on/off setting for UI Sound ... separately from the game sounds."
    func testUISoundIsItsOwnSwitch() throws {
        let (screen, defaults) = try settings()
        try tap(.interfaceSound, on: screen)
        XCTAssertFalse(InterfaceSound.isOn(in: defaults))
        XCTAssertTrue(defaults.bool(forKey: "soundsSetting"), "the game's sound is untouched")
        try tap(.interfaceSound, on: screen)
        XCTAssertTrue(InterfaceSound.isOn(in: defaults))
    }

    /// James, round 342: "When turning the UI sound off via the settings screen it shouldn't
    /// make a UI sound button click. When turning it on, it should." The row lights up before it
    /// flips, so it is the one row that does not click on the way down.
    func testOnlyTheUISoundRowStaysQuietAsItLightsUp() {
        typealias Row = SettingsViewController.SettingRow
        XCTAssertFalse(SettingsViewController.clicksAsItLightsUp(Row.interfaceSound.rawValue))
        for row in [Row.appIcon, .theme, .sounds, .music, .haptics, .background, .perspective,
                    .paddleSpeed, .swipeUpToPause, .reset] {
            XCTAssertTrue(SettingsViewController.clicksAsItLightsUp(row.rawValue), "\(row)")
        }
    }

    func testPerspectiveZoomTurnsOffAndOn() throws {
        let (screen, defaults) = try settings()
        try tap(.perspective, on: screen)
        XCTAssertFalse(defaults.bool(forKey: "parallaxSetting"))
        try tap(.perspective, on: screen)
        XCTAssertTrue(defaults.bool(forKey: "parallaxSetting"))
    }

    func testSwipeUpToPauseTurnsOff() throws {
        let (screen, defaults) = try settings()
        try tap(.swipeUpToPause, on: screen)
        XCTAssertFalse(defaults.bool(forKey: "swipeUpPause"))
    }

    /// The row itself cycles the speed, as it always has; the chevron opens the practice field.
    func testThePaddleSpeedRowCyclesTheSpeed() throws {
        let (screen, defaults) = try settings()
        let before = PaddleSpeed.stored(defaults)
        try tap(.paddleSpeed, on: screen)
        XCTAssertNotEqual(PaddleSpeed.stored(defaults), before)
    }

    /// From the main menu there is no Reset row at all - Reset Game Data was never built - and
    /// from the pause menu it is Reset Ball.
    func testResetIsOnlyOfferedMidGame() throws {
        let (screen, _) = try settings()
        XCTAssertFalse(screen.settingRows.contains(.reset))
        screen.navigatedFrom = "PauseMenu"
        XCTAssertTrue(screen.settingRows.contains(.reset))
        XCTAssertFalse(screen.settingRows.contains(.appIcon), "nothing that restyles a live game")
        XCTAssertFalse(screen.settingRows.contains(.theme))
    }
}

/// **James, round 346: "Pausing the game, closing the app (not quitting) then re-entering the
/// app, causes some of the items on the pause view to move down. I noticed the same thing
/// happening with the game over view too. Please check all the in game views for the same
/// issue."** His screenshots have the gap between "Endless Mayhem" and PAUSED about forty points
/// wider after the return.
///
/// What going to the background does to a screen is lay it out again under other traits, for
/// the app switcher's snapshots, and then under its own. A view whose storyboard constraints
/// carry a size-class variation has its whole constraint list re-applied on each change, which
/// switched back on a tie the pause screen had cut in round 338. These tests make the same
/// round trip, horizontal size class regular and back, and ask that nothing moved.
final class InGameScreensAfterTheAppSwitcherTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    /// Shows `screen` full-window, as `GameViewController` does, in a real window so trait
    /// changes reach it.
    private func show(_ screen: UIViewController) {
        let host = UIViewController()
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow()
        }
        window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        window.rootViewController = host
        window.isHidden = false
        self.window = window
        host.addChild(screen)
        screen.view.frame = host.view.bounds
        host.view.addSubview(screen.view)
        screen.didMove(toParent: host)
        window.layoutIfNeeded()
        screen.view.layoutIfNeeded()
    }

    /// The app switcher's round trip, as far as the layout can tell.
    private func visitTheAppSwitcher(_ screen: UIViewController) {
        screen.traitOverrides.horizontalSizeClass = .regular
        screen.view.setNeedsLayout()
        screen.view.layoutIfNeeded()
        screen.traitOverrides.horizontalSizeClass = .compact
        screen.view.setNeedsLayout()
        screen.view.layoutIfNeeded()
    }

    private func top(of view: UIView, in screen: UIViewController) -> CGFloat {
        view.convert(view.bounds, to: screen.view).minY
    }

    func testPausedStaysWhereItWasAfterTheAppComesBack() throws {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        let pause = try XCTUnwrap(board.instantiateViewController(withIdentifier: "pauseMenuVC")
                                    as? PauseMenuViewController)
        pause.sender = "Pause"
        pause.levelNumber = 0
        pause.totalStatsArray = [TotalStats()]
        show(pause)

        let title = try XCTUnwrap(pause.titleLabel)
        let before = top(of: title, in: pause)
        visitTheAppSwitcher(pause)

        XCTAssertEqual(top(of: title, in: pause), before, accuracy: 1,
                       "PAUSED moved from \(before) to \(top(of: title, in: pause)) after the "
                       + "traits changed and changed back - James's report, reproduced")
    }

    func testTheBetweenLevelsCardStaysWhereItWasAfterTheAppComesBack() throws {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        let card = try XCTUnwrap(board.instantiateViewController(withIdentifier: "inbetweenView")
                                   as? InbetweenViewController)
        show(card)
        card.view.transform = .identity
        card.view.alpha = 1
        card.view.layoutIfNeeded()

        let complete = try XCTUnwrap(card.completeLabel)
        let total = try XCTUnwrap(card.totalScoreLabel)
        let before = (top(of: complete, in: card), top(of: total, in: card))
        visitTheAppSwitcher(card)

        XCTAssertEqual(top(of: complete, in: card), before.0, accuracy: 1)
        XCTAssertEqual(top(of: total, in: card), before.1, accuracy: 1)
    }

    /// The mechanism on its own: a choice UIKit undid is put back, and one it left alone is not
    /// counted.
    func testAChoiceUndoneFromOutsideIsPutBack() {
        let parent = UIView()
        let child = UIView()
        parent.addSubview(child)
        let tie = child.topAnchor.constraint(equalTo: parent.topAnchor)
        tie.isActive = true

        var choices = StoryboardConstraintChoices()
        choices.set(tie, active: false)
        XCTAssertFalse(choices.reassert(), "nothing had been undone")

        tie.isActive = true
        // What the storyboard's re-application does
        XCTAssertTrue(choices.reassert())
        XCTAssertFalse(tie.isActive)

        choices.set(tie, active: true)
        XCTAssertFalse(choices.reassert(), "the later choice replaces the earlier one")
        XCTAssertTrue(tie.isActive)
    }
}
