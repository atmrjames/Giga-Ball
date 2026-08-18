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

    func testARowWithABigButtonDrawsTheSmallOnesIn() {
        var withPlay = sizes
        withPlay[1] = LevelStatsViewController.playButtonSize
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
/// a phone and no more, and no window ever has height taken off it.
final class MenuResizeTests: XCTestCase {

    private let ratio: Double = Double(UIViewController.menuMaximumAspectRatio)

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

    func testAFullScreenIPadIsNarrowedToTheShapeAndKeepsItsHeight() {
        let size = CGSize(width: 1032, height: 1376)   // 13-inch iPad Pro, portrait
        let insets = UIViewController.menuContentInsets(available: size)

        XCTAssertEqual(shape(size), ratio, accuracy: 0.001, "no squarer than the cap")
        XCTAssertEqual(insets.top, 0, "and not one point of height given away")
        XCTAssertEqual(insets.bottom, 0)
        XCTAssertEqual(insets.left, insets.right, accuracy: 0.001, "centred, not pushed aside")
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

    func testATallThinWindowIsNotTouched() {
        // Slide over: narrower than a phone in shape, which is the shape the menus were built
        // for. Round 180's size cap took 278pt off the height of a window like this
        let insets = UIViewController.menuContentInsets(available: CGSize(width: 420,
                                                                         height: 1376))
        XCTAssertEqual(insets, .zero)
    }

    func testAShortWideWindowLosesWidthNotHeight() {
        let size = CGSize(width: 1200, height: 640)   // a landscape half-split
        let insets = UIViewController.menuContentInsets(available: size)
        XCTAssertEqual(insets.top, 0)
        XCTAssertGreaterThan(insets.left, 0)
        XCTAssertEqual(shape(size), ratio, accuracy: 0.001)
    }

    func testNoWindowEverEarnsANegativeInsetOrLosesItsHeight() {
        // A negative additional safe area grows the content past the screen, which is how a
        // close button ends up off the bottom of a small window
        for width in stride(from: CGFloat(320), through: 1600, by: 40) {
            for height in stride(from: CGFloat(480), through: 2000, by: 40) {
                let insets = UIViewController.menuContentInsets(
                    available: CGSize(width: width, height: height))
                XCTAssertGreaterThanOrEqual(insets.left, 0, "\(width)x\(height)")
                XCTAssertGreaterThanOrEqual(insets.right, 0, "\(width)x\(height)")
                XCTAssertEqual(insets.top, 0, "\(width)x\(height)")
                XCTAssertEqual(insets.bottom, 0, "\(width)x\(height)")
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
}
