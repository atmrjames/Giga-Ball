//
//  PowerUpGlow.swift
//  Megaball
//
//  A halo behind a falling power-up, in the colour of its own icon.
//
//  Play-test request, thirteenth round. The drops are small, they fall against a dark field,
//  and in Endless Mayhem there can be several in the air at once - a little light around each
//  one is what separates "something is coming" from "something is on the screen somewhere".
//
//  The colour is *derived*, not listed. Every icon is already drawn in one of two colours by
//  the same rule the reference page prints - green awards points, red deducts - and that rule
//  lives in the multiplier column. Reading it here means a new power-up gets the right halo
//  the day it exists, and a power-up whose judgement changes gets the new one for free. A
//  second list of which drops are good would be wrong the first time that changed.
//

import SpriteKit

extension GameScene {

    /// Puts the halo behind a drop that is about to fall.
    ///
    /// A child of the drop, so it falls with it, is removed with it, and needs nothing to
    /// keep the two in step. Behind it in z, and additive, so it lights the field rather than
    /// tinting the icon.
    func addPowerUpGlow(to powerUp: SKSpriteNode, index: Int) {
        powerUp.childNode(withName: GameScene.powerUpGlowName)?.removeFromParent()
        // Drops are reused, and a second halo on one would be twice as bright as the rest

        let colour = GameScene.powerUpGlowColour(forIndex: index)
        let glow = SKSpriteNode(texture: GameScene.powerUpGlowTexture(for: colour))
        glow.size = GameScene.powerUpGlowSize(forDropWidth: powerUp.size.width)
        glow.name = GameScene.powerUpGlowName
        glow.alpha = GameScene.powerUpGlowAlpha
        glow.blendMode = .add
        glow.zPosition = -1
        powerUp.addChild(glow)
    }

    /// **A picture of a glow, not a shape that glows** (James, round 385b: "The power-up glow -
    /// make the change"). Until then each drop carried an `SKShapeNode` with a `glowWidth`,
    /// which SpriteKit draws through an offscreen pass of its own on every frame, one per drop
    /// in the air - a Power Shower or a Multi-Ball rush paid it several times over. The disc
    /// is now drawn once per colour, the first time that colour is asked for, and every drop
    /// wears it as an ordinary sprite: one textured quad, the cheapest thing SpriteKit draws.
    ///
    /// **The picture is what the shape actually drew, which was not a glow.** Rendered on the
    /// simulator side by side, the old node came out as a flat disc with a clean edge and no
    /// halo at all: `SKShapeNode` draws its glow in the *stroke* colour, and the stroke was
    /// clear. So the drops have worn a translucent disc since round 13, and this keeps exactly
    /// that - the look James has played with - while dropping the offscreen pass that drew an
    /// invisible glow every frame. Round 385c then gave the picture an actual glow - see the
    /// falloff below.
    static func powerUpGlowTexture(for colour: UIColor) -> SKTexture {
        let key = colour.description
        if let made = powerUpGlowTextures[key] { return made }
        let side: CGFloat = 256
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            let colours = powerUpGlowFalloff.map {
                UIColor(red: red, green: green, blue: blue, alpha: $0.1).cgColor
            } as CFArray
            let locations = powerUpGlowFalloff.map { $0.0 }
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colours, locations: locations) else { return }
            let centre = CGPoint(x: side/2, y: side/2)
            context.cgContext.drawRadialGradient(gradient, startCenter: centre, startRadius: 0,
                                                 endCenter: centre, endRadius: side/2, options: [])
        }
        let made = SKTexture(image: image)
        powerUpGlowTextures[key] = made
        return made
    }

    /// Where the glow's strength falls, as (share of its radius, strength): bright under the
    /// drop and easing out well past its edges, so it lights the field round the icon rather
    /// than hiding behind it.
    ///
    /// **James's pick, round 385c** ("Power-up glows look great. Let's go with Glow"), from four
    /// rendered side by side with real drops: the flat disc the drops had worn since round 13,
    /// a soft halo, this, and a stronger one. The disc showed nothing at all - it was smaller
    /// than the icon and hid behind it.
    static let powerUpGlowFalloff: [(CGFloat, CGFloat)] = [
        (0, 1), (0.3, 0.85), (0.5, 0.5), (0.7, 0.2), (0.85, 0.06), (1, 0)
    ]

    /// The glow's size round a drop: five of the old disc's radii across, 0.42 of the drop's
    /// width each - a little over twice the drop.
    static func powerUpGlowSize(forDropWidth width: CGFloat) -> CGSize {
        CGSize(width: width*0.42*5, height: width*0.42*5)
    }

    static let powerUpGlowAlpha: CGFloat = 0.45

    /// One picture per colour, of which there are three. Main-thread only, like the scene.
    private static var powerUpGlowTextures: [String: SKTexture] = [:]

    /// The colour a power-up's halo takes: the same green or red its icon is drawn in.
    ///
    /// Derived from the multiplier column, which is where the good/bad judgement already
    /// lives - a power-up that deducts is drawn in the harmful colour, and this reads the
    /// same fact rather than repeating it. Anything the column has nothing to say about
    /// takes the beneficial colour, which is what the icons do.
    static func powerUpGlowColour(forIndex index: Int) -> UIColor {
        let multipliers = LevelPackSetup.shared.powerUpMultiplierArray
        guard multipliers.indices.contains(index) else { return PowerUpIcon.beneficial }
        let names = LevelPackSetup.shared.powerUpNameArray
        if names.indices.contains(index), GameScene.neutralPowerUpNames.contains(names[index]) {
            return PowerUpIcon.neutral
        }
        // The yellow power-ups glow yellow (round 350), rather than whichever colour their old
        // multiplier sign gave them
        return multipliers[index].hasPrefix("-") ? PowerUpIcon.harmful : PowerUpIcon.beneficial
    }

    static let powerUpGlowName = "powerUpGlow"
}
