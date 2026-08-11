//
//  PausedPowerUpHUD.swift
//  Megaball
//
//  The in-game power-up row, on the pause screen.
//
//  Pausing to look at what you have running was already possible - the icons are on the scene
//  behind the menu - but the menu covers them, so the answer to "what is still going?" required
//  unpausing to find out (play-test rounds 37-39). This puts the row on the pause screen
//  itself, and makes each icon tappable: tap one and the pop-up says what it does, which is the
//  other thing a paused player is usually wondering.
//
//  **It must look identical to the row in the game.** It does not share that row's code, and it
//  does not need to - the scene's HUD is SpriteKit, this is UIKit, and snapshotting a live scene
//  behind a menu to get a picture of it would be far more machinery than drawing the same thing
//  twice. So every number here is read from `PowerUpRingHUD` rather than copied: the colour, the
//  glow, the stroke widths, the inset and the arc are the same values the scene draws with, and
//  the arc itself is literally the same function. What is *not* shared is the animation - a
//  paused row has nothing to count down, so it is drawn once and left alone.
//

import UIKit
import SpriteKit

final class PausedPowerUpHUD: UIView {

    /// Tapped icon, by power-up index into `LevelPackSetup.powerUpNameArray`.
    var onSelect: ((Int) -> Void)?

    /// One power-up, as the pause screen needs to know it.
    struct Item {
        let powerUpIndex: Int
        let icon: UIImage
        /// How much is left, from one down to zero.
        let remaining: CGFloat
        /// Turns rather than seconds, for the ones that count catches.
        var segments: Int?
    }

    private static let iconSize: CGFloat = 30
    private static let spacing: CGFloat = 12
    // The scene's own numbers (`PowerUpRingHUD.iconSize`, `.spacing`), so a player glancing
    // between the two sees one row rather than two arrangements of the same icons

    private var buttons: [UIButton] = []

    /// Fills the row in, and reports whether there was anything to show.
    @discardableResult
    func show(_ items: [Item]) -> Bool {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        guard items.isEmpty == false else { return false }

        let step = PausedPowerUpHUD.iconSize + PausedPowerUpHUD.spacing
        let width = step*CGFloat(items.count) - PausedPowerUpHUD.spacing

        for (position, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(item.icon.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.tag = item.powerUpIndex
            button.addTarget(self, action: #selector(iconTapped(_:)), for: .touchUpInside)
            addSubview(button)
            buttons.append(button)

            addRing(remaining: item.remaining, segments: item.segments, to: button)

            let x = step*CGFloat(position) - width/2 + PausedPowerUpHUD.iconSize/2
            NSLayoutConstraint.activate([
                button.centerXAnchor.constraint(equalTo: centerXAnchor, constant: x),
                button.centerYAnchor.constraint(equalTo: centerYAnchor),
                button.widthAnchor.constraint(equalToConstant: PausedPowerUpHUD.iconSize),
                button.heightAnchor.constraint(equalToConstant: PausedPowerUpHUD.iconSize),
            ])
            // Laid out from the centre outwards, the way the scene's row is, so the row stays
            // centred whatever it happens to be holding
        }
        return true
    }

    /// The two-pass ring: a soft wide bloom underneath, a bright thin arc on top.
    ///
    /// The same construction the scene makes, for the reason its own comment gives - the thin
    /// ring carries the reading and stays crisp, and a blurred timer is a timer you squint at.
    private func addRing(remaining: CGFloat, segments: Int?, to button: UIButton) {
        let size = PausedPowerUpHUD.iconSize
        let radius = size/2 - size*0.05
        // `PowerUpRingHUD.ringInset` is 0.05 of the icon - private there, so it is written
        // once here rather than opened up for a second reader

        let arc = PowerUpRingHUD.ringPath(remaining: remaining, segments: segments,
                                          radius: radius)
        // Literally the scene's arc: the twelve-o'clock start, the clockwise sweep and the
        // gaps between a segmented ring's turns are one function, so the two rows cannot
        // disagree about what "half left" looks like

        var flipped = CGAffineTransform(scaleX: 1, y: -1)
            .concatenating(CGAffineTransform(translationX: size/2, y: size/2))
        // SpriteKit's y climbs and UIKit's falls, so the arc is mirrored into place rather
        // than redrawn by a second set of trigonometry that could drift from the first
        guard let path = arc.copy(using: &flipped) else { return }

        for (width, alpha, glow) in [(CGFloat(4), CGFloat(0.16), true),
                                     (CGFloat(2), CGFloat(1), false)] {
            let layer = CAShapeLayer()
            layer.path = path
            layer.strokeColor = PowerUpRingHUD.ringColour.cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = width
            layer.lineCap = .round
            layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
            if glow {
                layer.shadowColor = PowerUpRingHUD.ringColour.cgColor
                layer.shadowRadius = PowerUpRingHUD.ringGlow
                layer.shadowOpacity = 1
                layer.shadowOffset = .zero
                // A Core Animation shadow standing in for SpriteKit's `glowWidth`. Same
                // radius, and the same job: a bloom rather than a fatter line
            }
            layer.opacity = Float(alpha)
            button.layer.addSublayer(layer)
        }
    }

    @objc private func iconTapped(_ sender: UIButton) {
        onSelect?(sender.tag)
    }
}
