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
        guard view.viewWithTag(Self.returnToGameTag) == nil else { return true }

        let play = UIButton(type: .system)
        play.tag = Self.returnToGameTag
        play.translatesAutoresizingMaskIntoConstraints = false
        play.backgroundColor = UIColor(white: 0.92, alpha: 1)
        play.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        play.layer.cornerRadius = 37.5
        play.setImage(UIImage(systemName: "play.fill",
                              withConfiguration: UIImage.SymbolConfiguration(
                                  pointSize: 27, weight: .heavy)), for: .normal)
        play.addTarget(self, action: #selector(returnToGameTapped), for: .touchUpInside)
        view.addSubview(play)

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
        if let play = view.viewWithTag(Self.returnToGameTag) {
            view.bringSubviewToFront(play)
        }
    }

    /// Takes the big play off this screen.
    ///
    /// For the screens that are pictures of the playfield rather than menus over it: the
    /// background selector shows the game at a scale model's size, and a button floating on
    /// top of that reads as part of the picture (play-test round 21).
    func hideReturnToGameButton() {
        view.viewWithTag(Self.returnToGameTag)?.removeFromSuperview()
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

    private static var returnToGameTag: Int { 909_001 }
}
