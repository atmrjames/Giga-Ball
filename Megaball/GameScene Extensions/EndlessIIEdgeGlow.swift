//
//  EndlessIIEdgeGlow.swift
//  Megaball
//
//  The glow along an edge of the play area that has become a doorway.
//
//  Two power-ups turn a wall into a way through, and both had been saying so with a flat
//  colour. The top of the field is where a lone Portal brick and the Portal Paddle put the
//  ball, and it wore a five-point bar. Wrap-Around does the same to both side walls, and it
//  said so by tinting the walls themselves.
//
//  James delivered `PortalLength` for this: a strip that is white-hot along one edge, falls
//  away to the Giga-Ball green, and reaches nothing at all at the far side - a glow rather than
//  a line. One picture serves all three edges, which is the whole reason it is worth having a
//  file of its own rather than a sprite in each of two features.
//
//  ## What the artwork is, and why it needs no tiling
//
//  It is drawn bright along its **left** edge with the gradient running left to right, and it
//  is *uniform down its length* - every row of it is the same. So the length can simply be
//  stretched: a texture with nothing to distort along an axis cannot be distorted along that
//  axis, and stretching costs nothing where tiling would cost a seam to get wrong.
//
//  That leaves one transform per edge, and only one of them is interesting:
//
//  - **Left**: as drawn.
//  - **Right**: mirrored, which is a negative `xScale` and not a second picture.
//  - **Top**: turned a quarter turn anticlockwise, so the bright edge points up. The sprite's
//    *width* then runs down the screen and is the depth of the glow, and its *height* runs
//    across and is the length of the edge. Those two swapping over is the one thing here that
//    is easy to get backwards, so `size(along:)` is where it is done and nowhere else.
//
//  ## Shown as drawn, and what that costs
//
//  The obvious thing is to tint it: the top exit wore the far colour of whatever portal was in
//  play, and Wrap-Around's walls are blue on the left and yellow on the right because they are
//  the two ends of one pair. Tinting does not survive the attempt. The picture is white against
//  the wall and falls away through the green, and one hue over all of it is a coloured haze
//  rather than a glow - which is the thing being added.
//
//  So the artwork is shown as drawn. Wrap-Around still says which end is which by tinting the
//  *walls*, more lightly than before, since the glow beside them now carries most of the
//  message. The top has no wall to say it with, so a player with a blue Portal brick on screen
//  can no longer read which end the top is. That is a real thing given up for the effect, and
//  two drawn variants of the strip would give both back.
//

import SpriteKit

extension GameScene {

    /// Which edge a glow runs along.
    enum EndlessIIEdge: String {
        case top, left, right

        /// The node's name, so each edge has exactly one glow and finding it is a lookup.
        var glowName: String { "endlessIIEdgeGlow-\(rawValue)" }
    }

    /// How far the glow reaches in from its edge.
    ///
    /// **Not the artwork's own 58 points.** Drawn at its natural size the glow reaches a
    /// seventh of the way across the field and lies over the outermost column of bricks - which
    /// reads as a heavy vignette rather than as an edge that has opened. Twenty keeps the
    /// bright line hard against the wall and brings the falloff in tight behind it, which is
    /// the thing the picture is of.
    ///
    /// Its own number rather than the texture's, because the artwork is a *length* of an effect
    /// and how far it reaches is a decision about this field rather than about the file.
    static let endlessIIEdgeGlowDepth: CGFloat = 20

    /// The picture, loaded once. Nil in a build without it, which is the whole fallback: no
    /// artwork means no glow rather than a crash or a white rectangle.
    static let endlessIIEdgeGlowTexture: SKTexture? =
        UIImage(named: "PortalLength").map { SKTexture(image: $0) }

    /// Puts a glow along an edge, or takes it away.
    ///
    /// Called every frame by whichever feature owns the edge, and does nothing on almost all of
    /// them: the node is made once and then only followed.
    ///
    /// **Shown as drawn, not tinted.** The top exit used to wear the far colour of whatever
    /// portal was in play - a blue brick's exit is yellow - and the obvious thing was to carry
    /// that on by tinting this. It does not survive the attempt: the artwork is white against
    /// the wall and falls away through the Giga-Ball green, and a `colorBlendFactor` of 1 flattens
    /// all of that into one hue, so the glow stops being a glow and becomes a coloured haze.
    /// What is lost is the colour coding at the top, and what is kept is the effect James drew.
    /// Wrap-Around still says which end is which by tinting the walls themselves.
    /// How strongly the edge glows while a wrap or a portal is running.
    ///
    /// **James, round 312: "make the wrap around and portal graphics on the edges and side of
    /// the game view slightly more transparent."** It faded to full opacity, which on a field
    /// with a ball and bricks to watch is a band of colour competing with the play rather than
    /// framing it. Seven tenths is "slightly", and the walls behind it are already carrying
    /// their share at a blend of 0.35.
    static let endlessIIEdgeGlowAlpha: CGFloat = 0.7

    func showEndlessIIEdgeGlow(_ edge: EndlessIIEdge, wanted: Bool) {
        let existing = childNode(withName: edge.glowName) as? SKSpriteNode

        guard wanted, let texture = GameScene.endlessIIEdgeGlowTexture else {
            existing?.removeFromParent()
            return
        }

        let glow = existing ?? {
            let node = SKSpriteNode(texture: texture)
            node.name = edge.glowName
            node.zPosition = 4
            node.alpha = 0
            node.zRotation = edge == .top ? -.pi/2 : 0
            node.xScale = edge == .right ? -1 : 1
            // A quarter turn anticlockwise puts the bright edge at the top; a negative scale
            // puts it against the right-hand wall. Neither needs a second picture
            addChild(node)
            node.run(.fadeAlpha(to: GameScene.endlessIIEdgeGlowAlpha, duration: 0.2))
            return node
        }()

        glow.size = endlessIIEdgeGlowSize(along: edge)
        glow.position = endlessIIEdgeGlowPosition(along: edge)
        // Followed every frame rather than placed once: the play area's height is read off the
        // scene's own frame, and a scene that has not been laid out yet gives a different one
    }

    /// The sprite's own size for an edge, before it is turned.
    ///
    /// **Width is always the depth and height is always the length**, because that is what the
    /// artwork is - the gradient runs across its width. The top edge is turned a quarter turn
    /// after this, which is what swaps them over on screen.
    func endlessIIEdgeGlowSize(along edge: EndlessIIEdge) -> CGSize {
        let depth = GameScene.endlessIIEdgeGlowDepth
        switch edge {
        case .top: return CGSize(width: depth, height: gameWidth)
        case .left, .right: return CGSize(width: depth, height: endlessIIPlayAreaHeight)
        }
    }

    /// Where its centre sits, which is half its depth in from the edge it hugs.
    func endlessIIEdgeGlowPosition(along edge: EndlessIIEdge) -> CGPoint {
        let depth = GameScene.endlessIIEdgeGlowDepth
        switch edge {
        case .top:
            return CGPoint(x: 0, y: endlessIIPlayAreaTop - depth/2)
        case .left:
            return CGPoint(x: -gameWidth/2 + depth/2, y: endlessIIPlayAreaMidY)
        case .right:
            return CGPoint(x: gameWidth/2 - depth/2, y: endlessIIPlayAreaMidY)
        }
    }

    /// The line the play area starts at, under the HUD block.
    ///
    /// The same figure the flat strip was placed against before this, kept as its own name so
    /// the three edges agree about where the field is.
    var endlessIIPlayAreaTop: CGFloat {
        frame.height/2 - topScreenBlock.size.height
    }

    /// How tall the play area is: the top line down to the bottom of the view.
    var endlessIIPlayAreaHeight: CGFloat {
        endlessIIPlayAreaTop + frame.height/2
    }

    var endlessIIPlayAreaMidY: CGFloat {
        endlessIIPlayAreaTop - endlessIIPlayAreaHeight/2
    }
}
