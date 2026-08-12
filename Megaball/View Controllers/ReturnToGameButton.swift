//
//  ReturnToGameButton.swift
//  Megaball
//
//  The big play, on every screen reached from a paused game.
//
//  The pause menu has one. Everything opened from it - settings, the information menu, the
//  reference pages, the statistics - had only a small close, so getting back into a run meant
//  retracing every screen you had opened (play-test round 11). This puts the same button in
//  the same place on all of them, so the way back to the game is one tap from anywhere.
//
//  Written once, as an extension, rather than added to eight view controllers by hand: those
//  screens are storyboard-built and share no base class, and eight copies of a button is
//  eight chances for one of them to be different.
//

import UIKit

extension UIViewController {

    /// The paused game behind this screen, if there is one.
    ///
    /// Walked up the child chain rather than passed in: the reference pages can be three
    /// screens deep by the time anyone asks, and each of those screens would otherwise have
    /// to carry the answer down to the next.
    var pausedGameBehind: PauseMenuViewController? {
        var above = parent
        while let candidate = above {
            if let pause = candidate as? PauseMenuViewController, pause.sender == "Pause" {
                return pause
            }
            above = candidate.parent
        }
        return nil
    }

    /// Puts the big play on this screen if a paused game is behind it.
    ///
    /// Deliberately does nothing where there is no run to go back to, so the same call can sit
    /// in every screen's `viewDidLoad` without each one having to know where it was opened
    /// from. Returns whether it added anything, for callers that want to lay out around it.
    @discardableResult
    func installReturnToGameButton() -> Bool {
        guard pausedGameBehind != nil else { return false }
        removeReturnToGameButtonsBehind()
        // **One button, on the frontmost screen.** Every screen in the stack installs its own,
        // and a screen opened from a screen is a *subview* of it - so opening three deep left
        // three of these alive at once, in the same place, each running its own screen's entry
        // and exit animations. That is the play button "animating over the top of itself"
        // between pause pages, reported in rounds 33, 37 and 39 (round 38 fixed the *other*
        // button row, the round icons, which is why this survived that fix).
        //
        // It is also why the backgrounds view still showed one: that screen calls
        // `hideReturnToGameButton`, which removed the button from its own view - and the
        // button being seen belonged to the settings screen underneath it.
        guard view.viewWithTag(Self.returnToGameTag) == nil else { return true }

        let play = UIButton(type: .system)
        play.tag = Self.returnToGameTag
        play.translatesAutoresizingMaskIntoConstraints = false
        play.layer.cornerRadius = 37.5
        play.setImage(UIImage(systemName: "play.fill",
                              withConfiguration: UIImage.SymbolConfiguration(
                                  pointSize: 27, weight: .heavy)), for: .normal)
        play.addTarget(self, action: #selector(returnToGameTapped), for: .touchUpInside)
        view.addSubview(play)
        applyRoundGlass(to: play, radius: 37.5)

        NSLayoutConstraint.activate([
            play.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            play.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                         constant: -12),
            play.widthAnchor.constraint(equalToConstant: 75),
            play.heightAnchor.constraint(equalToConstant: 75),
            // The same size and place the pause menu's own play has, so it reads as the same
            // button rather than as this screen's version of one
        ])
        return true
    }

    /// Keeps the big play on top of whatever the screen has added since.
    ///
    /// Installed in `viewDidLoad`, the button starts frontmost - but these screens go on
    /// adding views after that (blur layers, reloaded tables, the settings screen's own
    /// furniture), and a transparent view over the button eats its taps without covering it
    /// visually. That is a button that "doesn't always work" (play-test round 36): it looks
    /// present and ignores some taps, depending on what happened to be laid over which part
    /// of it. Called from `limitMenuContentSize`, which every one of these screens already
    /// runs on every layout pass - so the button is re-fronted whenever anything moves.
    func keepReturnToGameButtonFrontmost() {
        guard pausedGameBehind != nil, wantsReturnToGameButton else { return }

        if children.contains(where: { $0.view.superview != nil }) {
            view.viewWithTag(Self.returnToGameTag)?.removeFromSuperview()
            return
        }
        // A screen with something open on top of it is not the frontmost screen, so its button
        // is one of the duplicates. Removing it here rather than only when the child is opened
        // means the rule holds however the stack got into this shape

        if view.viewWithTag(Self.returnToGameTag) == nil {
            installReturnToGameButton()
            return
            // And it comes back when the screen on top goes away, without the child having to
            // tell it. Going back would otherwise leave every screen behind the deepest one
            // permanently without a play button
        }
        if let play = view.viewWithTag(Self.returnToGameTag) {
            view.bringSubviewToFront(play)
        }
        // Frontmost among its own subviews too: these screens go on adding views after
        // `viewDidLoad` - blur layers, reloaded tables - and a transparent view over the
        // button eats its taps without covering it visually, which is a button that "doesn't
        // always work" (play-test round 36)
    }

    /// Whether this screen wants the button at all.
    ///
    /// The background selector does not: it is a full-bleed picture of the playfield, and a
    /// button floating over it reads as part of the picture (play-test round 21). It says so
    /// by calling `hideReturnToGameButton`, and this remembers - otherwise the layout pass
    /// above would put back what that call had just taken away, every frame.
    var wantsReturnToGameButton: Bool {
        get { (objc_getAssociatedObject(self, &Self.wantsButtonKey) as? Bool) ?? true }
        set { objc_setAssociatedObject(self, &Self.wantsButtonKey, newValue,
                                       .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    private static var wantsButtonKey: UInt8 = 0

    /// Takes the big play off this screen.
    ///
    /// For the screens that are pictures of the playfield rather than menus over it: the
    /// background selector shows the game at a scale model's size, and a button floating on
    /// top of that reads as part of the picture (play-test round 21).
    func hideReturnToGameButton() {
        wantsReturnToGameButton = false
        view.viewWithTag(Self.returnToGameTag)?.removeFromSuperview()
        removeReturnToGameButtonsBehind()
        // The ancestors' too, or a screen that wants no play button gets the one belonging to
        // whatever opened it, showing through from underneath
    }

    /// Takes the button off every screen this one was opened from.
    ///
    /// Walks the parent chain rather than the view hierarchy, because that is the chain
    /// `pausedGameBehind` already trusts to find the paused game - and it stops at the pause
    /// menu, whose own play button is its own affair and must not be removed.
    func removeReturnToGameButtonsBehind() {
        var above = parent
        while let candidate = above {
            if candidate is PauseMenuViewController { return }
            candidate.view.viewWithTag(Self.returnToGameTag)?.removeFromSuperview()
            above = candidate.parent
        }
    }

    @objc private func returnToGameTapped() {
        guard let pause = pausedGameBehind else { return }
        if UserDefaults.standard.bool(forKey: "hapticsSetting") {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        for screen in pause.children {
            screen.willMove(toParent: nil)
            screen.view.removeFromSuperview()
            screen.removeFromParent()
        }
        // Everything the pause menu opened comes off, however deep it went: a page opened
        // from a page is a subview of it, so taking the outermost one off takes the rest

        pause.removeAnimate(nextAction: .unpause)
        // And then the pause menu leaves exactly as its own play button makes it leave
    }

    /// Gives a round button the Liquid Glass look, or the flat one it has always had.
    ///
    /// **The first of these in the app** (James's 1.3 scope call), and deliberately on the one
    /// round button that already draws its own circle with a symbol on top. Every other round
    /// button in the game is a PNG with the circle *and* the glyph baked into it, and glass
    /// cannot go behind a glyph that is welded to an opaque disc - so rolling this out further
    /// is an asset job (template glyphs) before it is a code one. That is what
    /// FUTURE-RELEASES.md means by "in-app icons updated to Liquid Glass versions", and it is
    /// worth knowing before the rest is quoted as a code change.
    ///
    /// Below iOS 26 it is the pale disc it has always been, which is not a compromise: the
    /// app supports iOS 15, and a button that is invisible on an older phone would be a
    /// regression dressed as a feature.
    func applyRoundGlass(to button: UIButton, radius: CGFloat) {
        if #available(iOS 26.0, *) {
            button.tintColor = .white
            button.setImage(UIImage(systemName: "play.fill",
                                    withConfiguration: UIImage.SymbolConfiguration(
                                        pointSize: 25, weight: .black)), for: .normal)
            // Pure white and a heavier weight at a slightly smaller size. Off-white on a clear
            // material picked up the material's own tint and went muddy; white has nothing to
            // dilute. The extra weight is what makes a glyph read as *drawn* on glass rather
            // than floating behind it
            // **The glyph goes light on glass, and dark on the disc.** Glass over these dark
            // menus settles dark and translucent, so the deep purple the button has always
            // worn all but disappeared into it (play-test round 53). This is the off-white the
            // *disc* used to be - the contrast simply moves from the circle to the mark on it,
            // which is what a glass control is: the shape stops being the thing you read and
            // the glyph starts being it
            let effect = UIGlassEffect(style: .clear)
            effect.isInteractive = true
            // `.clear` rather than `.regular`: the regular material is frosted, and frosting a
            // 75pt disc over a dark menu is most of what read as blur (play-test round 54).
            // Clear keeps the refraction and the edge light and drops the diffusion, which is
            // the crisp half of the look. Interactive because it *is* a control - it should
            // respond to a press the way every other glass control on the system does

            let glass = UIVisualEffectView(effect: effect)
            glass.isUserInteractionEnabled = false
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.cornerConfiguration = .capsule()
            // **Shaped, not clipped.** A corner radius plus `clipsToBounds` cuts the material
            // off at the boundary - and the boundary is where glass does its specular edge, so
            // clipping it leaves the highlight sheared and smeared instead of tracing the rim.
            // `cornerConfiguration` tells the effect what shape it *is*, so it lights its own
            // edge. On a square view a capsule is a circle, which is what this button is
            button.insertSubview(glass, at: 0)
            NSLayoutConstraint.activate([
                glass.topAnchor.constraint(equalTo: button.topAnchor),
                glass.bottomAnchor.constraint(equalTo: button.bottomAnchor),
                glass.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            ])
            // Behind the glyph and not in the way of a touch: the button is still the control,
            // and the glass is only how it looks
        } else {
            button.backgroundColor = UIColor(white: 0.92, alpha: 1)
            button.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
            // The old pair, unchanged: a pale disc needs a dark glyph, and inverting only the
            // glass path means an iOS 15 phone is not handed white-on-white
        }
    }

    private static var returnToGameTag: Int { 909_001 }
}
