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

    func testResetDataStillSaysWhatSurvivesIt() {
        // The one confirm that cannot be undone. It has always promised that purchases are
        // kept, and a merge is exactly the kind of change that quietly drops a sentence
        let message = GigaBallConfirm.resetData.message
        XCTAssertTrue(message.contains("irreversibly"), message)
        XCTAssertTrue(message.contains("In-app purchases will remain."), message)
    }
}
