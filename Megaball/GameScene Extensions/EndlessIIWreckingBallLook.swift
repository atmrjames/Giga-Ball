//
//  EndlessIIWreckingBallLook.swift
//  Megaball
//
//  The spikes on the wrecking ball (§5.4). James's art, round 152.
//
//  Until now the Wrecking Ball was invisible: the ball destroyed whatever it touched and
//  looked exactly like a ball, so the only way to know it was running was the ring HUD. Now
//  it wears spikes, in whichever of the twelve ball themes the player chose, and in the
//  colour of whatever the ball is - normal, Giga-Ball or Undestructi-Ball.
//
//  **The spikes are a picture and nothing else.** The physics body is not touched, not
//  rebuilt and not resized: a ball that hit bricks from a spike's length away would be a
//  different power-up, and one the player could not aim. That is James's instruction and it
//  is also the only sane reading - the whole mechanic is "this hit destroys what it struck",
//  which needs the same hit as before.
//
//  Which forces the shape of this file. The spiked art is *bigger* than the ball (64pt of
//  texture for a 50pt ball, and 72 for the candy cane), so it cannot be the ball's own
//  texture at the ball's own size without shrinking the ball inside it. It is a child node
//  instead, sized from the texture's own proportions, sitting over a ball that has stopped
//  drawing itself. A child rather than a sibling because the ball-size power-ups work by
//  `xScale`, and a child inherits that for free - a scaled-up wrecking ball gets scaled-up
//  spikes without anyone arranging it.
//
//  The one thing that had to move to make that safe is in `ballPhysicsBodySet`, which decided
//  whether the Giga-Ball was running by comparing `ball.texture` to the Giga-Ball texture. A
//  picture was carrying a rule. `ballDress` now carries it, and the picture is free to change.
//

import SpriteKit

extension GameScene {

    /// What the ball is, as opposed to what it looks like.
    ///
    /// The distinction only matters because a cosmetic layer now exists, and it matters a
    /// lot: `ballPhysicsBodySet` reads this to decide whether the ball passes through bricks.
    enum BallDress {
        case normal, giga, undestructi
    }

    /// The texture this dress wears when nothing cosmetic is on top of it.
    func ballDressTexture(_ dress: BallDress) -> SKTexture {
        switch dress {
        case .normal: return ballTexture
        case .giga: return gigaBallTexture
        case .undestructi: return undestructiballTexture
        }
    }

    static let wreckingSpikesName = "endlessIIWreckingSpikes"

    /// The size every plain ball texture is drawn at, which is what makes the spiked ones
    /// measurable: a 64pt wrecking texture beside a 50pt ball is 28% of overhang, and the
    /// candy cane's 72 is 44%. Read off the art rather than written down as a factor, so a
    /// redrawn texture with longer spikes is longer-spiked in the game the day it lands.
    static let plainBallTexturePoints: CGFloat = 50

    /// The spiked texture for the current theme and dress.
    ///
    /// Optional, and it stays optional now that all twelve themes have art (James delivered
    /// the glass three on 16 August 2026, the round after the rest): a thirteenth theme
    /// would otherwise reach past the end of this list, and a ball that keeps its own look
    /// is a far better answer to missing art than one wearing somebody else's theme.
    func endlessIIWreckingTexture(for dress: BallDress) -> SKTexture? {
        let themes = ["", "3D", "Ice", "Outline", "Square", "Glass",
                      "Pixel", "Split", "Candy", "Glow", "Rainbow", "Retro"]
        // Same order as `ballTextureArray`, and the same length. Index 9 is the theme the
        // code calls the giga *look* and James calls Glow; the file names use his word

        guard themes.indices.contains(ballSetting) else { return nil }
        let theme = themes[ballSetting]

        let body: String
        switch dress {
        case .normal: body = "Normal"
        case .giga: body = "Giga"
        case .undestructi: body = "Undestructi"
        }
        return SKTexture(imageNamed: "ballWrecking\(body)\(theme)")
    }

    /// Puts the spikes on every ball in play, and takes them off again. Once a frame.
    func refreshEndlessIIWreckingBall() {
        let running = gameMode == .endlessII && endlessIIWreckingBallClock.isRunning
        let texture = running ? endlessIIWreckingTexture(for: ballDress) : nil

        for subject in endlessIIBallsInPlay {
            let spikes = subject.childNode(withName: GameScene.wreckingSpikesName) as? SKSpriteNode

            guard let texture else {
                guard spikes != nil else { continue }
                spikes?.removeFromParent()
                subject.texture = ballDressTexture(ballDress)
                subject.colorBlendFactor = 0
                continue
                // Back to being a ball, wearing whatever it is - which is read from the
                // dress, not remembered from before the spikes, so a Giga-Ball collected
                // *during* a wrecking ball is still a Giga-Ball when the spikes come off
            }

            let size = CGSize(
                width: ballSize*texture.size().width/GameScene.plainBallTexturePoints,
                height: ballSize*texture.size().height/GameScene.plainBallTexturePoints)

            if let spikes {
                if spikes.texture != texture { spikes.texture = texture }
                if spikes.size != size { spikes.size = size }
            } else {
                let node = SKSpriteNode(texture: texture, size: size)
                node.name = GameScene.wreckingSpikesName
                node.zPosition = 0.1
                subject.addChild(node)
            }

            if subject.texture != nil {
                subject.texture = nil
                subject.color = .clear
                subject.colorBlendFactor = 1
            }
            // The ball stops drawing itself while the spikes draw for it, and is checked
            // every frame because half a dozen places write `ball.texture` - the Giga-Ball,
            // the Undestructi-Ball, both of their expiries, the serve and the ball reset. Its
            // *size* is left alone throughout, because the sticky band, the paddle clamp and
            // the direction marker all measure themselves against it
        }
    }
}
