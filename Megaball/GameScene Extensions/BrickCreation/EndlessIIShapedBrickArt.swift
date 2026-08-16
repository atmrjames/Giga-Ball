//
//  EndlessIIShapedBrickArt.swift
//  Megaball
//
//  Drawn faces for the shaped bricks. James's art, round 153.
//
//  Rounded and Wedge were built with a note attached - "there is no artwork for it, so the
//  face is drawn" - and what that meant in practice was a rectangular brick texture stretched
//  into a rounded or triangular path. It read correctly and it was never quite right: a
//  stretched rectangle has its highlight in the wrong place, and the shading runs off the
//  edge of the shape rather than following it. Now each brick type has a texture drawn *as*
//  that shape, and the face wears it.
//
//  Two things this file exists to protect.
//
//  **A brick is still identified by its own texture.** `hitBrick`, `endlessIIBehaviour(of:)`
//  and the row scans all ask what a brick is by comparing `texture` against the type
//  textures, so the sprite's texture is never touched here - exactly as the shape nodes never
//  touched it. The shaped art goes on the *face*, which is the node that does the showing.
//  This is the same rule the Wrecking Ball's spikes had to learn one round earlier: a picture
//  must not carry a rule, and the way to keep that true is to leave the picture that does
//  carry one alone.
//
//  **Art that does not exist is a real answer.** Convex and Concave have no drawn faces yet,
//  and neither does the retro theme's Indestructible - the retro theme has never had its own
//  Indestructible texture at all, so those bricks wear the classic one and now wear the
//  classic shaped one, which is right rather than a fallback. Everything else returns nil and
//  the face keeps the stretched texture it has had since it was built (§8.5).
//

import SpriteKit

extension GameScene {

    /// The shapes there is drawn art for.
    ///
    /// Not `EndlessIIFace`, which has three cases and two of them have no art, and not
    /// `EndlessIIStyle`, which has thirty. Its own two-case vocabulary, so the day Convex is
    /// drawn the change is one case here and one line in `shapedArtName`.
    enum ShapedBrickArt: String {
        case rounded = "Rounded"
        case wedge = "Wedge"
    }

    /// The drawn face for a brick of this type in this shape, or nil where there is none.
    func endlessIIShapedArt(for texture: SKTexture?, _ shape: ShapedBrickArt) -> SKTexture? {
        guard let name = endlessIIBrickTextureName(texture) else { return nil }
        return SKTexture(imageNamed: name + shape.rawValue)
    }

    /// The asset name of a brick type's plain texture.
    ///
    /// Asked of the *current* type textures rather than a remembered list, because the retro
    /// theme swaps six of them wholesale at set-up (`brickSetting == 1`) and the rest of the
    /// game compares against whatever they hold now. The two names that are not simply the
    /// classic name with "retro" in front are James's, from the original assets, and are
    /// spelled here as they are spelled there.
    func endlessIIBrickTextureName(_ texture: SKTexture?) -> String? {
        guard let texture else { return nil }
        let retro = brickSetting == 1

        if texture == brickNormalTexture { return retro ? "retroBrickNormal" : "BrickNormal" }
        if texture == brickInvisibleTexture {
            return retro ? "retroBrickInvisible" : "BrickInvisible"
        }
        if texture == brickMultiHit1Texture {
            return retro ? "RetroBrickMultiHit1" : "BrickMultiHit1"
        }
        if texture == brickMultiHit2Texture {
            return retro ? "RetroBrickMultiHit2" : "BrickMultiHit2"
        }
        if texture == brickMultiHit3Texture {
            return retro ? "RetroBrickMultiHit3" : "BrickMultiHit3"
        }
        if texture == brickMultiHit4Texture {
            return retro ? "RetroBrickMultiHit4" : "BrickMultiHit4"
        }
        if texture == brickIndestructible1Texture { return "BrickIndestructible1" }
        if texture == brickIndestructible2Texture { return "BrickIndestructible2" }
        // Not conditioned on the theme, because the retro theme has never had its own
        // Indestructible art - those two are the classic textures in both themes, so the
        // classic shaped art is the matching art rather than a substitute

        return nil
        // A power-up brick, a Null, or something dressed by a role. Those wear the texture
        // they wear, and the face keeps stretching it
    }

    /// What a face node should be filled with: the drawn art if it exists, the brick's own
    /// texture stretched into the path if it does not.
    ///
    /// One function so the four places that fill a face - two builders and their two
    /// refreshes - cannot disagree, which is how a Multi-hit brick ends up stepping down
    /// through the drawn set on its way in and the stretched set on its way through.
    func endlessIIFaceFill(_ brick: SKSpriteNode, _ shape: ShapedBrickArt?) -> SKTexture? {
        guard let shape else { return brick.texture }
        return endlessIIShapedArt(for: brick.texture, shape) ?? brick.texture
    }

    /// The drawn shape a face uses, if any. Convex and Concave have none yet (§8.5).
    static func shapedArt(for face: EndlessIIFace) -> ShapedBrickArt? {
        switch face {
        case .wedge: return .wedge
        case .convex, .concave: return nil
        }
    }
}
