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
    /// Not `EndlessIIStyle`, which has thirty. Its own vocabulary, and as of round 262 it
    /// covers every face the game draws - James delivered Convex, Concave and Diamond for the
    /// classic theme, so `shapedArt(for:)` no longer has a case that returns nil.
    enum ShapedBrickArt: String {
        case rounded = "Rounded"
        case wedge = "Wedge"
        case convex = "Convex"
        case concave = "Concave"
        case diamond = "Diamond"
    }

    /// The suffix an orientation-specific picture carries.
    ///
    /// James, round 262: "I've appended 0, 90, 180 and 270 to these... The reason for this is
    /// that the lighting on these bricks wouldn't look right in the rotated / mirrored
    /// versions."
    ///
    /// Which is true, and is the thing a reflected node cannot fix: turning a picture over
    /// turns its highlight over with it, so a wedge lit from above is lit from below the
    /// moment it is flipped.
    ///
    /// **The number names the transform, not a rotation**, and how many there are depends on
    /// how many the shape has. Only the Wedge has a handedness worth varying - `makeFace`
    /// forces `mirrored` false for the others, because a mirrored dome is the same dome - so
    /// it is drawn four ways and everything else two: "the indestructible bricks have 0 and
    /// 180 appended as they can be right-side-up or upside-down".
    ///
    /// Worked out against the art rather than assumed. The base wedge in
    /// `EndlessIIFaceGeometry` is right-angled at the bottom right, which is exactly what
    /// `Wedge0` is drawn as, and `ShapedBrickArtOrientationTests` compares the alpha
    /// silhouettes, so the mapping is pinned to the pictures rather than to a reading of them.
    static func orientationSuffix(_ shape: ShapedBrickArt,
                                  mirrored: Bool, flipped: Bool) -> String {
        switch shape {
        case .wedge: return String((mirrored ? 180 : 0) + (flipped ? 90 : 0))
        case .convex, .concave, .diamond, .rounded: return flipped ? "180" : "0"
        }
    }

    /// The drawn face for a brick of this type in this shape, or nil where there is none.
    ///
    /// **The oriented picture first, the plain one after.** Only some of the set is drawn per
    /// orientation - every retro wedge and both Indestructibles are, the classic Multi-hits
    /// are not yet - so this asks for the specific one and falls back, which means a picture
    /// arriving later needs no code at all. `endlessIIArtIsOriented` is the same question
    /// asked by the caller that has to decide whether to un-reflect the sprite.
    func endlessIIShapedArt(for texture: SKTexture?, _ shape: ShapedBrickArt,
                            mirrored: Bool = false, flipped: Bool = false) -> SKTexture? {
        guard let name = endlessIIBrickTextureName(texture) else { return nil }
        let oriented = name + shape.rawValue
            + GameScene.orientationSuffix(shape, mirrored: mirrored, flipped: flipped)
        if UIImage(named: oriented) != nil { return SKTexture(imageNamed: oriented) }

        let plain = name + shape.rawValue
        guard UIImage(named: plain) != nil else { return nil }
        return SKTexture(imageNamed: plain)
        // **Asked of the catalogue, not of SpriteKit.** `SKTexture(imageNamed:)` does not
        // return nil for a name that is not there - it hands back a placeholder - so the
        // old code was safe only because it was asked about Rounded and Wedge, which every
        // type has. Round 262 opened it to Convex, Concave and Diamond, which the classic
        // theme now has and the retro theme does not yet ("the retro concave and convex
        // bricks will be the same, but they aren't ready yet"). Nil is the honest answer
        // there, and it is the answer §8.5 already describes: the face keeps stretching the
        // brick's own texture until the picture exists
    }

    /// Whether this brick's picture is drawn for its own orientation rather than reflected
    /// into it.
    ///
    /// The face's *path* is reflected by scaling the shape node, and a sprite inside it
    /// inherits that scale - which is right for a picture drawn one way up and wrong for one
    /// drawn four ways. Where the oriented art exists the sprite cancels the scale back out,
    /// so the outline is turned and the lighting is not.
    func endlessIIArtIsOriented(for texture: SKTexture?, _ shape: ShapedBrickArt,
                                mirrored: Bool, flipped: Bool) -> Bool {
        guard let name = endlessIIBrickTextureName(texture) else { return false }
        return UIImage(named: name + shape.rawValue
                       + GameScene.orientationSuffix(shape, mirrored: mirrored, flipped: flipped)) != nil
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

    /// Draws a face's art as a sprite the size of the cell, rather than as a shape node's
    /// fill.
    ///
    /// **`SKShapeNode.fillTexture` does not stretch its texture to the path.** It lays it in
    /// at the texture's own point size, so what a face shows is a *crop* of the picture, and
    /// how much of it depends on how big the file happens to be. That went unseen for as long
    /// as the art was plain: the classic brick is a white rectangle with a hairline edge, and
    /// a crop of a white rectangle is a white rectangle. The retro art has a bevel, so the
    /// day it arrived at full resolution (round 154) every shaped brick in the retro theme
    /// started showing a magnified corner of its own bevel - James, round 156: "some are 4
    /// times too big and some are 4 times too small". Four times is one doubling in each
    /// direction, which is exactly what the file's own size had done.
    ///
    /// So the art is drawn by a sprite that is *told* its size. Nothing has to line up by
    /// coincidence, and a texture drawn at any resolution lands the same.
    ///
    /// No clipping is needed: the drawn faces are silhouettes already, transparent where the
    /// shape is not. The shape node stays - it carries the name the style is identified by,
    /// and the physics is built from its path - but it stops trying to paint.
    @discardableResult
    func drawEndlessIIFaceArt(_ texture: SKTexture, on shape: SKShapeNode,
                              cell: CGSize) -> SKSpriteNode {
        shape.fillTexture = nil
        shape.fillColor = .clear
        let art = SKSpriteNode(texture: texture, size: cell)
        art.name = GameScene.faceArtName
        art.zPosition = 0.01
        shape.addChild(art)
        return art
    }

    static let faceArtName = "endlessIIFaceArt"

    /// The cell a face was built for, read back off its own path.
    ///
    /// The sprite behind a shaped face is shrunk into a hiding rectangle, so `brick.size` is
    /// no longer the cell by the time a refresh runs - and the face's path is the one thing
    /// that still is. Reading it back beats remembering it: a remembered number is a second
    /// copy of the cell, and the Breathing style changes the first one every frame.
    func endlessIIFaceCell(_ brick: SKSpriteNode, shape: SKShapeNode) -> CGSize {
        guard let path = shape.path else { return brick.size }
        let box = path.boundingBox
        return CGSize(width: box.width, height: box.height)
    }

    /// Keeps a drawn face showing what the brick is, as a Multi-hit brick steps down through
    /// its four textures. Returns whether it took the job - a face with no art still has its
    /// fill refreshed the old way.
    @discardableResult
    func refreshEndlessIIFaceArt(_ brick: SKSpriteNode, _ shape: SKShapeNode,
                                 _ art: ShapedBrickArt?, cell: CGSize) -> Bool {
        let mirrored = brick.endlessIIFaceMirrored ?? false
        let flipped = brick.endlessIIFaceFlipped ?? false

        guard let art, let texture = endlessIIShapedArt(for: brick.texture, art,
                                                        mirrored: mirrored, flipped: flipped)
        else {
            shape.childNode(withName: GameScene.faceArtName)?.removeFromParent()
            return false
        }

        let oriented = endlessIIArtIsOriented(for: brick.texture, art,
                                              mirrored: mirrored, flipped: flipped)
        let sprite = (shape.childNode(withName: GameScene.faceArtName) as? SKSpriteNode)
            ?? drawEndlessIIFaceArt(texture, on: shape, cell: cell)

        if sprite.texture != texture { sprite.texture = texture }
        if sprite.size != cell { sprite.size = cell }
        sprite.color = brick.color
        sprite.colorBlendFactor = brick.colorBlendFactor

        sprite.xScale = oriented && mirrored ? -1 : 1
        sprite.yScale = oriented && flipped ? -1 : 1
        // **A picture drawn for its own orientation is un-turned here** (round 262). The face's
        // path is reflected by scaling the shape node, and this sprite is inside it, so it
        // inherits the reflection - which is right for a picture drawn one way up and wrong
        // for one James has drawn four ways. Cancelling the parent's scale leaves the outline
        // turned and the lighting the way he drew it, which is the whole reason the four
        // exist: "the lighting on these bricks wouldn't look right in the rotated / mirrored
        // versions"
        return true
    }

    /// The drawn shape a face uses. All four have art as of round 262.
    static func shapedArt(for face: EndlessIIFace) -> ShapedBrickArt? {
        switch face {
        case .wedge: return .wedge
        case .convex: return .convex
        case .concave: return .concave
        case .diamond: return .diamond
        }
    }
}
