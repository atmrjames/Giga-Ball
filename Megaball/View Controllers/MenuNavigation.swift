//
//  MenuNavigation.swift
//  Megaball
//
//  Edge swipes through the menus: back from the left, forward from the right.
//
//  The menus are not a navigation controller. Each screen is a child view controller whose
//  view is added over the one that opened it, and each has its own back button - which is why
//  the swipe every other iOS app answers to did nothing here. It is the gesture people reach
//  for before they look for the button.
//
//  Back is straightforward: the swipe does exactly what the back button does, by calling the
//  same method rather than by repeating it, so the two can never drift apart.
//
//  Forward is the other half of the same idea, and the part that is easy to get wrong. A
//  screen you returned from is remembered, and the right-edge swipe puts it back - the same
//  instance, where you left it. Opening anything new discards it, which is what a navigation
//  stack does when you push after popping: the forward history belonged to the path you left.
//

import UIKit

/// A menu screen that can be gone back from.
protocol MenuNavigable: UIViewController {
    /// Does exactly what tapping the back button does, including telling whoever opened this
    /// screen to come back.
    func menuNavigationGoBack()
}

/// A menu screen that fades its own content out while something it opened is on top.
///
/// The screens that do this look wrong without it: their content is drawn behind the screen
/// above, and both are readable at once. Opening a screen calls `hideAnimate` directly; going
/// forward to one had no way to say the same thing.
protocol MenuNavigationPresenter: UIViewController {
    func menuNavigationHideBehindChild()
}

/// The one screen a forward swipe would return to.
///
/// One deep, deliberately. The menus are shallow, and a stack of screens that were swiped away
/// several steps ago is a thing nobody remembers well enough to want back.
final class MenuNavigation: NSObject, UIGestureRecognizerDelegate {

    static let shared = MenuNavigation()

    /// How near the edge a swipe has to start, and how far it has to travel.
    ///
    /// A screen-edge recogniser would say the first of these for us, but it also refuses any
    /// touch the system has an interest in, and half of these screens carry a scroll view that
    /// wants the same finger. Measuring it here is a few lines and behaves the same on every
    /// screen.
    static let edgeWidth: CGFloat = 40
    static let travel: CGFloat = 60

    /// Storage for the in-progress swipe's starting point, which has to hang off the screen
    /// rather than off this - two screens can be mid-gesture at once while one animates away.
    fileprivate static var startKey: UInt8 = 0

    /// What a swipe means.
    enum Move {
        case back, forward, none
    }

    /// Reads a finished swipe.
    ///
    /// Separated from the gesture so the rules can be stated on their own: it has to start at
    /// an edge, travel far enough to have been meant, and be more sideways than not - a list
    /// being scrolled near the edge moves mostly downwards and is not a page turn.
    static func move(start: CGPoint, translation: CGPoint, width: CGFloat) -> Move {
        guard abs(translation.x) > travel, abs(translation.x) > abs(translation.y)*2 else {
            return .none
        }
        if translation.x > 0, start.x <= edgeWidth { return .back }
        if translation.x < 0, start.x >= width - edgeWidth { return .forward }
        return .none
    }

    /// Weak: if the screen is gone, so is the way forward to it. Nothing here should keep a
    /// menu alive that the menus themselves have finished with.
    private weak var screen: UIViewController?

    private override init() { super.init() }

    /// Lets a swipe share the touch with whatever is underneath it.
    ///
    /// Menus scroll. Without this the two recognisers fight and one of them loses, which
    /// shows up as a list that will not scroll near the edge - a worse bug than the one this
    /// gesture fixes.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }

    /// Remembers a screen as it goes back, so a forward swipe can return to it.
    func record(_ screen: UIViewController) {
        self.screen = screen
    }

    /// Forgets the way forward. Called when any screen is opened - a new path replaces the
    /// one that was left.
    func forget() {
        screen = nil
    }

    /// Whether there is anything to go forward to from here.
    ///
    /// Only from the screen that opened it: swiping right on some unrelated menu should not
    /// summon a screen from a path the player has left.
    func canGoForward(from current: UIViewController) -> Bool {
        guard let screen, screen.view.superview == nil else { return false }
        return screen.parent === current
    }

    /// Puts the remembered screen back, where it was left.
    func goForward(from current: UIViewController) {
        guard canGoForward(from: current), let screen, let parent = screen.parent else { return }

        (parent as? MenuNavigationPresenter)?.menuNavigationHideBehindChild()
        // The same thing opening it would have done. Without it the screen underneath stays
        // where it was and both are visible at once

        screen.view.frame = parent.view.frame
        parent.view.addSubview(screen.view)
        screen.menuNavigationFadeIn()
        self.screen = nil
    }
}

extension UIViewController {

    /// Adds the two edge swipes to this menu screen.
    ///
    /// Called from `viewDidLoad`, which is also where the forward history is dropped: a screen
    /// being loaded is a screen being opened, and opening something new is what ends the path
    /// you could have gone forward along.
    func installMenuNavigationSwipes() {
        MenuNavigation.shared.forget()

        let swipe = UIPanGestureRecognizer(target: self,
                                          action: #selector(menuNavigationEdgeSwipe(_:)))
        swipe.delegate = MenuNavigation.shared
        swipe.cancelsTouchesInView = true
        // A swipe is not a tap. Without this the touch carried on to whatever was under the
        // finger, so a swipe that started on a cell opened it
        view.addGestureRecognizer(swipe)
    }

    /// The fade the menus arrive with, so a screen returned to looks like a screen opened.
    func menuNavigationFadeIn() {
        view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }

    @objc private func menuNavigationEdgeSwipe(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            let moved = gesture.translation(in: view)
            let now = gesture.location(in: view)
            menuNavigationSwipeStart = CGPoint(x: now.x - moved.x, y: now.y - moved.y)
            // Where the finger went down, not where it was by the time the pan was recognised.
            // A pan only begins after the touch has travelled its slop - about thirty points -
            // so reading the location here put the start a third of the way across the edge
            // strip, and a swipe from the very edge of the screen was reported as starting
            // outside it
        case .ended:
            defer { menuNavigationSwipeStart = nil }
            guard let start = menuNavigationSwipeStart else { return }
            guard menuNavigationIsFrontmost else { return }
            // Only the screen on top acts. Every screen is laid over the one that opened it,
            // so a swipe on a screen three deep is delivered to all three recognisers - and
            // all three went back, which landed the player on the first screen however deep
            // they were
            let moved = gesture.translation(in: view)

            switch MenuNavigation.move(start: start, translation: moved,
                                       width: view.bounds.width) {
            case .back:
                (self as? MenuNavigable)?.menuNavigationGoBack()
                // The root menu has nowhere to go back to and does not conform, so its left
                // edge does nothing rather than something arbitrary
            case .forward:
                MenuNavigation.shared.goForward(from: self)
            case .none:
                break
            }
        default:
            break
        }
    }

    /// Whether this screen is the one on top.
    ///
    /// A menu screen is on top when none of the screens it opened are still on display. Their
    /// views are removed as they go back, and the view controllers stay as children - so this
    /// asks about the view rather than about the child.
    var menuNavigationIsFrontmost: Bool {
        children.allSatisfy { $0.viewIfLoaded?.superview == nil }
    }

    /// Where the swipe in progress began, if there is one.
    private var menuNavigationSwipeStart: CGPoint? {
        get { objc_getAssociatedObject(self, &MenuNavigation.startKey) as? CGPoint }
        set { objc_setAssociatedObject(self, &MenuNavigation.startKey, newValue,
                                       .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
