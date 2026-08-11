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

        let glow = SKShapeNode(circleOfRadius: powerUp.size.width*0.42)
        glow.name = GameScene.powerUpGlowName
        glow.strokeColor = .clear
        glow.fillColor = GameScene.powerUpGlowColour(forIndex: index)
        glow.alpha = 0.30
        glow.glowWidth = powerUp.size.width*0.42
        glow.blendMode = .add
        glow.zPosition = -1
        powerUp.addChild(glow)
    }

    /// The colour a power-up's halo takes: the same green or red its icon is drawn in.
    ///
    /// Derived from the multiplier column, which is where the good/bad judgement already
    /// lives - a power-up that deducts is drawn in the harmful colour, and this reads the
    /// same fact rather than repeating it. Anything the column has nothing to say about
    /// takes the beneficial colour, which is what the icons do.
    static func powerUpGlowColour(forIndex index: Int) -> UIColor {
        let multipliers = LevelPackSetup().powerUpMultiplierArray
        guard multipliers.indices.contains(index) else { return PowerUpIcon.beneficial }
        return multipliers[index].hasPrefix("-") ? PowerUpIcon.harmful : PowerUpIcon.beneficial
    }

    static let powerUpGlowName = "powerUpGlow"
}
