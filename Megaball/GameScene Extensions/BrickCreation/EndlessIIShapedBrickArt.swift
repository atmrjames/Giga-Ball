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
    enum ShapedBrickArt: String, CaseIterable {
        case rounded = "Rounded"
        case wedge = "Wedge"
        case convex = "Convex"
        case concave = "Concave"
        case diamond = "Diamond"

        /// The style this shape is, which is what carries the rules about it - what sizes it
        /// fits, what it stacks with. `shapedArt(for:)` is the other direction, from a face to
        /// its picture; Rounded has no `EndlessIIFace` at all, which is why the pair does not
        /// go through one.
        var style: EndlessIIStyle {
            switch self {
            case .rounded: return .rounded
            case .wedge: return .wedge
            case .convex: return .convex
            case .concave: return .concave
            case .diamond: return .diamond
            }
        }
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
                            mirrored: Bool = false, flipped: Bool = false,
                            suffix: String = "", named: String? = nil) -> SKTexture? {
        guard let name = named ?? endlessIIBrickTextureName(texture) else { return nil }
        // **The name may be given rather than looked up.** A Portal is built on the
        // Indestructible artwork and is not an Indestructible brick, so asked by texture alone
        // it would wear `BrickIndestructible2Rounded` and never find `BrickPortalRounded`

        if suffix.isEmpty == false {
            let sized = name + shape.rawValue + suffix
            if UIImage(named: sized) != nil { return SKTexture(imageNamed: sized) }
        }
        // **The size comes after the shape**, which is how James delivered them:
        // `BrickNormalRoundedSquare`. A Square brick is one cell wide and two tall, so the
        // ordinary picture stretched into it is stretched to twice its height - the same
        // wrongness the shaped faces were built to end, one axis over

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
                                mirrored: Bool, flipped: Bool, suffix: String = "",
                                named: String? = nil) -> Bool {
        guard let name = named ?? endlessIIBrickTextureName(texture) else { return false }
        if suffix.isEmpty == false, UIImage(named: name + shape.rawValue + suffix) != nil {
            return false
        }
        // A square picture is drawn one way up and there is only one of it, so it is not the
        // four-way art this question is about - answering yes would un-turn a sprite that was
        // never turned
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
        return endlessIIShapedArt(for: brick.texture, shape,
                                  named: endlessIIArtName(for: brick))
            ?? endlessIIShapedArt(for: brick.texture, shape)
            ?? brick.texture
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

    /// Where that cell sits, read back off the same path.
    ///
    /// Zero for every face drawn about its node, which is all of them but one: a rounded
    /// Square brick's outline is built around the *sprite*, which hangs a cell below the node
    /// (§8.6, the rule that a brick's `position.y` is its row). The art has to hang with it.
    func endlessIIFaceCentre(shape: SKShapeNode) -> CGPoint {
        guard let path = shape.path else { return .zero }
        let box = path.boundingBox
        return CGPoint(x: box.midX, y: box.midY)
    }

    /// How much of the half-turn partner shows at this rotation.
    ///
    /// James, round 266: "when a brick with multiple variants is spinning, is it possible to
    /// fade in and out the corresponding variants so it looks like the light on the brick is
    /// changing as it spins? Each brick will have a maximum of 2 variants it can fade between
    /// as the 90 and 180 are mirrors of 0 and 270, so not the same shape."
    ///
    /// Which is exactly right, and the reason is worth writing down. The four pictures are a
    /// base and three *reflections* of it, and a spin is a **rotation** - so a turning brick
    /// only ever passes through the two of them a rotation can reach. Half a turn inverts both
    /// flags, so the pairs are {0, 270} and {180, 90}: 90 and 180 are the mirrors, and a
    /// spinning brick never looks like its own mirror.
    ///
    /// A cosine, so the two cross-fade smoothly and are equal at the quarter turns, where the
    /// brick is on its side and neither lighting is the right one. Zero at no rotation and at
    /// a full turn, one at half.
    static func spinningFaceBlend(zRotation: CGFloat) -> CGFloat {
        (1 - cos(zRotation))/2
    }

    /// Cross-fades a spinning brick's face between its own picture and its half-turn partner.
    ///
    /// **Only where both pictures exist.** The oriented sets are the ones James has drawn per
    /// orientation - the Indestructibles, all of retro's wedges, the retro convex pair - and
    /// everything else keeps one picture that turns with the brick, exactly as it did.
    ///
    /// The partner sprite carries the same counter-scale as the main one: both pictures are
    /// drawn to be seen the right way up, and the shape node they sit in is reflected to make
    /// the *outline*, so both have to cancel it.
    ///
    /// Driven from the frame like everything else that moves on a brick (§8.6) - the spin
    /// itself is a `zRotation` written in `tickEndlessIIRoles`, never an action.
    func refreshEndlessIISpinningFaceArt(_ brick: SKSpriteNode, _ shape: SKShapeNode,
                                         _ art: ShapedBrickArt, cell: CGSize,
                                         mirrored: Bool, flipped: Bool, main: SKSpriteNode) {
        let partnerNode = shape.childNode(withName: GameScene.facePartnerName) as? SKSpriteNode

        guard brick.zRotation != 0,
              endlessIIArtIsOriented(for: brick.texture, art,
                                     mirrored: !mirrored, flipped: !flipped),
              let partnerArt = endlessIIShapedArt(for: brick.texture, art,
                                                  mirrored: !mirrored, flipped: !flipped)
        else {
            partnerNode?.removeFromParent()
            if main.alpha != 1 { main.alpha = 1 }
            return
        }

        let partner = partnerNode ?? {
            let node = SKSpriteNode(texture: partnerArt, size: cell)
            node.name = GameScene.facePartnerName
            node.zPosition = main.zPosition + 0.01
            shape.addChild(node)
            return node
        }()

        if partner.texture != partnerArt { partner.texture = partnerArt }
        if partner.size != cell { partner.size = cell }
        if partner.position != main.position { partner.position = main.position }
        partner.color = brick.color
        partner.colorBlendFactor = brick.colorBlendFactor
        partner.xScale = mirrored ? -1 : 1
        partner.yScale = flipped ? -1 : 1
        partner.zRotation = .pi
        // **Turned half a circle inside the brick, which is the whole of why it works.**
        //
        // The partner is the picture drawn for a brick already standing at half a turn, so its
        // *silhouette* is the base shape rotated 180 degrees. Laid in unturned it draws a wedge
        // pointing the other way to the one the brick actually is - two triangles crossing,
        // which is what the render showed and what no amount of checking the alphas would have.
        //
        // Turned back by 180, its outline lands exactly on the brick's own at every angle, and
        // what is left showing through is the lighting it was drawn with: the world-correct one
        // for the far end of the turn. Which is the effect asked for - the light staying put
        // while the brick goes round.

        let blend = GameScene.spinningFaceBlend(zRotation: brick.zRotation)
        partner.alpha = blend
        main.alpha = 1
        // **The one underneath stays solid** (James, round 312: "when a rotating brick with
        // multiple textures is transitioning between its textures so its lighting looks right,
        // it can go semi transparent for some time. Make sure the 2 textures layered on top of
        // one another ensure the brick stays opaque").
        //
        // This was a symmetric cross-fade - `main.alpha = 1 - blend` against the partner's
        // `blend` - and two half-opaque layers do not make a whole one. They composite to
        // `1 - (1-a)(1-b)`, so at the halfway point the brick was three-quarters opaque and the
        // field showed through it, for the several seconds either side of a quarter turn.
        //
        // Dissolving the top layer over an opaque bottom one gives the same picture at both
        // ends and full opacity throughout. The partner takes a hair of zPosition so which one
        // is on top is stated rather than left to sibling order
    }

    static let facePartnerName = "endlessIIFacePartner"

    /// Keeps a drawn face showing what the brick is, as a Multi-hit brick steps down through
    /// its four textures. Returns whether it took the job - a face with no art still has its
    /// fill refreshed the old way.
    @discardableResult
    /// Whose pictures this brick's face should be drawn from.
    ///
    /// The brick's own name where there is a picture under it, and the texture it is built on
    /// where there is not. That second half is what keeps a Portal looking like a Portal only
    /// as far as James has drawn one: he delivered plain, Rounded and a square Diamond, and a
    /// Portal may also wear a Wedge, a dome or a notch (`takenByAPortal`) - so those keep the
    /// Indestructible shaped art they have always worn rather than losing their face entirely.
    ///
    /// Asked once and used for both questions below, because "which picture" and "is that
    /// picture drawn for its own orientation" have to be asked of the *same* picture - the two
    /// falling back independently is how a sprite ends up un-turning art that was never turned.
    func endlessIIFaceArtName(for brick: SKSpriteNode, _ art: ShapedBrickArt?,
                              mirrored: Bool, flipped: Bool, suffix: String) -> String? {
        guard let art else { return nil }
        if let named = endlessIIArtName(for: brick),
           endlessIIShapedArt(for: brick.texture, art, mirrored: mirrored, flipped: flipped,
                              suffix: suffix, named: named) != nil {
            return named
        }
        return endlessIIBrickTextureName(brick.texture)
    }

    func refreshEndlessIIFaceArt(_ brick: SKSpriteNode, _ shape: SKShapeNode,
                                 _ art: ShapedBrickArt?, cell: CGSize) -> Bool {
        let mirrored = brick.endlessIIFaceMirrored ?? false
        let flipped = brick.endlessIIFaceFlipped ?? false
        let suffix = GameScene.artSuffix(for: endlessIISizeOf(brick))
        // Asked of the size rather than of the cell's shape. Square is the one size taller than
        // it is wide, so its cell can be recognised by its aspect - and a Big brick's is 2:1
        // exactly like an ordinary brick's, so that trick never worked for the second one.
        // `endlessIISizeOf` reads the face's own path (`endlessIIFieldSize`), which is what
        // still knows the cell after the sprite behind it has been shrunk away

        let source = endlessIIFaceArtName(for: brick, art,
                                          mirrored: mirrored, flipped: flipped, suffix: suffix)
        guard let art, let source, let texture = endlessIIShapedArt(
            for: brick.texture, art,
            mirrored: mirrored, flipped: flipped, suffix: suffix, named: source)
        else {
            shape.childNode(withName: GameScene.faceArtName)?.removeFromParent()
            shape.childNode(withName: GameScene.facePartnerName)?.removeFromParent()
            return false
        }

        let oriented = endlessIIArtIsOriented(for: brick.texture, art,
                                              mirrored: mirrored, flipped: flipped,
                                              suffix: suffix, named: source)
        let sprite = (shape.childNode(withName: GameScene.faceArtName) as? SKSpriteNode)
            ?? drawEndlessIIFaceArt(texture, on: shape, cell: cell)

        let centre = endlessIIFaceCentre(shape: shape)
        let shown = endlessIIShown(texture, on: brick)
        if sprite.texture != shown { sprite.texture = shown }
        if sprite.size != cell { sprite.size = cell }
        if sprite.position != centre { sprite.position = centre }
        sprite.color = brick.color
        sprite.colorBlendFactor = brick.colorBlendFactor

        sprite.xScale = oriented && mirrored ? -1 : 1
        sprite.yScale = oriented && flipped ? -1 : 1
        refreshEndlessIISpinningFaceArt(brick, shape, art, cell: cell,
                                        mirrored: mirrored, flipped: flipped, main: sprite)
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

    // MARK: - Monochrome

    /// The same picture with the colour taken out of it.
    ///
    /// James, round 274: "For the portal brick cooling, can we make the brick monochrome during
    /// this period." Which is the right instrument and the one `colorBlendFactor` cannot play:
    /// blending towards grey flattens a picture towards *one* grey and takes the shading with
    /// it, where desaturating keeps every light and dark exactly where it was and only stops
    /// them being green. A cooling Portal reads as the same brick, waiting.
    ///
    /// **Computed once per picture and kept**, the way `TracedBodyCache` keeps a traced body.
    /// A Core Image pass is far too expensive to run on a frame, and there are only ever a
    /// handful of distinct portal pictures in a run - so the cache is bounded by the art rather
    /// than by anything that happens in play.
    func endlessIIMonochrome(of texture: SKTexture) -> SKTexture {
        let key = texture.description
        if let kept = GameScene.monochromeArt[key] { return kept }
        guard let filter = CIFilter(name: "CIColorControls",
                                    parameters: [kCIInputSaturationKey: 0]) else { return texture }
        let drained = texture.applying(filter)
        GameScene.monochromeArt[key] = drained
        return drained
    }

    private static var monochromeArt: [String: SKTexture] = [:]

    /// The picture a brick should actually be showing, given what is happening to it.
    ///
    /// One place, so the overlay and the shaped face cannot disagree - and so the cooling state
    /// survives the per-frame refresh, which is where the first version of it went wrong. A
    /// tint written onto the art is wiped off by the next frame's copy of the brick's colour; a
    /// *texture* chosen here is chosen again every frame, for as long as the reason holds.
    func endlessIIShown(_ texture: SKTexture, on brick: SKSpriteNode) -> SKTexture {
        guard brick.endlessIIRole == .portal, endlessIIPortalCooldown > 0 else { return texture }
        return endlessIIMonochrome(of: texture)
    }

    // MARK: - Square

    /// The suffix a picture drawn for a Square brick carries.
    ///
    /// James, round 270: "by square, I just mean 2x2" - one cell wide and two tall, which is
    /// square on screen because a cell is twice as wide as it is high.
    static let squareArtSuffix = "Square"

    /// And the one a picture drawn for a Big brick carries: two cells by two, so it is 2:1 like
    /// an ordinary brick and four times the area. Round 274.
    static let bigArtSuffix = "Big"

    /// What a picture drawn for this size is called.
    ///
    /// Nothing for Tiny, deliberately: a Tiny brick is a quarter cell wearing the ordinary
    /// picture *scaled* into it, which is right - the stretch these suffixes exist to end is a
    /// change of proportion, and a Tiny brick has none.
    /// The eight styles that wear a drawn overlay instead of a tint or a glyph.
    ///
    /// James, round 321: "semi transparent overlays for the different brick types: spinning,
    /// flashing, breathing, moving, gravity, fixed, exploding, spawner - add these over the top
    /// of these bricks as an overlay. Remove any existing tints or icons from these bricks."
    ///
    /// An overlay rather than a picture per brick, which is round 315d's costing arriving at its
    /// own conclusion: a tint lands on whatever brick is underneath and so needed 274 drawn
    /// combinations to replace, while a semi-transparent layer lets the brick's own artwork -
    /// multi-hit, indestructible, retro - show through and needs one picture per silhouette.
    static let endlessIIOverlaidStyles: [EndlessIIStyle] = []
    // **Empty since round 327b, and the delivery above is why it could be** (James, having
    // played with them: "removed the brick overlay graphics for spinning, flashing, breathing,
    // moving and gravity bricks as their actions are obvious, so there's no need for additional
    // graphics. For fixed, exploding and spawner, I think we should return to the old icons we
    // had previous: upside down T for fixed, which goes bold once the brick is fixed in place
    // after being hit, asterisks for exploding and plus for spawner").
    //
    // The five motions say what they are by moving, which is the same argument round 320 made
    // for Gravity and Moving losing their marks a round before the overlays arrived. The three
    // on-hit styles look like any other brick until struck, so they still have to be marked -
    // and the marks they had are still here, because round 321 kept them as the fallback for
    // every silhouette it had no picture for. Emptying this list is therefore the whole change:
    // `endlessIIDressStyleMarks` draws no overlay and falls through to the glyph, and a Fixed
    // brick's T still thickens when it locks, which the overlay could only do by being drawn
    // twice.
    //
    // A list rather than a deleted branch, because the artwork exists and the decision is
    // James's to take back. What must not drift is the tint: the eight styles stopped tinting
    // in round 321 and still do not, which `endlessIIUntintedStyles` now says on its own.

    /// The styles that wear no tint, whether or not they wear a picture.
    ///
    /// Round 321 took the colour off all eight, and a resume restores a saved colour before it
    /// re-applies the styles - so an older save's green Flashing or pink Breathing brick has to
    /// be cleared by something. That used to be a side effect of this list, which is now empty.
    static let endlessIIUntintedStyles: [EndlessIIStyle] = [
        .spinning, .flashing, .breathing, .moving, .gravity, .fixed, .exploding, .spawner,
    ]

    /// What the overlay for a style on a given silhouette is called.
    ///
    /// **The portal glow's order**: the base name, then the shape, then the size, then what the
    /// picture is - `BrickPortalDiamondSquareGlow` is that rule, and so is the delivery, whose
    /// plain Normal overlays come out as `BrickNormalSpinningOverlay` with the shape and size
    /// empty. A Square Gravity brick asks for `BrickNormalSquareGravityOverlay` and a Wedge
    /// Fixed one for `BrickNormalWedgeFixedOverlay`, so the names James draws for the other
    /// silhouettes are already the names the game looks for.
    ///
    /// A Tiny brick shares the Normal picture, because it is the same shape at a quarter of the
    /// area - the same bargain the Directional panel makes, and for the same reason.
    static func endlessIIStyleOverlayArtName(_ style: EndlessIIStyle, shape: String = "",
                                              size: BrickSize = .normal) -> String {
        "BrickNormal" + shape + artSuffix(for: size) + style.rawValue.capitalized + "Overlay"
    }

    static func artSuffix(for size: BrickSize) -> String {
        switch size {
        case .normal, .tiny: return ""
        case .square: return squareArtSuffix
        case .big: return bigArtSuffix
        }
    }

    static let brickArtName = "endlessIIBrickArt"

    /// The portal brick's own picture. James, round 271: "Portal bricks - these come in just
    /// the square size and a single theme", and round 273: "Portal is just 1 colour now. Both
    /// bricks will just be one colour."
    ///
    /// Named like a brick type rather than like a role, because that is what it now is to the
    /// lookup: `BrickPortalRounded`, `BrickPortalSquare` and the rest fall out of the same
    /// builder every other type uses.
    static let portalBrickArtName = "BrickPortal"

    /// What this brick's pictures are called.
    ///
    /// Two bricks are not the texture they are built on. A power-up brick and a Portal are both
    /// built on the Indestructible artwork - the look of a brick a hit does not simply destroy -
    /// and that texture stays theirs, because it is read in a dozen places for the score, the
    /// particle colour, the sound and the clearing rules. What they *show* is their own.
    func endlessIIArtName(for brick: SKSpriteNode) -> String? {
        if brick.endlessIIPowerUpIndex != nil { return GameScene.powerUpBrickArtName }
        if brick.endlessIIRole == .portal { return GameScene.portalBrickArtName }
        return endlessIIBrickTextureName(brick.texture)
    }

    /// The power-up brick's own picture. James, round 271: "this is the same shape as a
    /// power-up graphic. Add the power-up graphic to the brick. Power-up bricks only come in
    /// this shape and style."
    ///
    /// So the brick is the badge and the power-up's own icon goes on it. One name, with no
    /// theme and no shape after it, because there is one of these and it never varies.
    static let powerUpBrickArtName = "PowerUpBrick"

    /// The picture this brick should be showing, where that is not the texture it wears.
    ///
    /// Three cases, and they are the same case: the brick's own texture is not the picture.
    /// A Square brick's texture is an oblong that would be stretched to twice its height; a
    /// power-up brick's and a Portal's is the Indestructible artwork they are built on. Nil for
    /// every other brick, which is already showing the right thing and needs nothing put over
    /// it.
    func endlessIIOwnArt(for brick: SKSpriteNode) -> SKTexture? {
        guard let name = endlessIIArtName(for: brick) else { return nil }
        if name == GameScene.powerUpBrickArtName { return nil }
        // **Nothing under the icon at all** (James, round 280: "the edge of the power-up brick
        // doesn't quite cover the edges of the placeholder graphics below, I can see a few
        // pixels of yellow at the corners. Can you make the placeholder graphic below
        // transparent?").
        //
        // Round 274 put the icon over the whole brick and left the yellow badge behind it, so
        // the two rounded squares had to agree on their corner radius to the pixel - and they
        // do not, so the badge showed as a yellow fringe at each corner. There is nothing for
        // the badge to do: the icon *is* the brick at that size, and the Indestructible sprite
        // it is all built on was already shrunk out of sight behind it by
        // `hidePowerUpBrickSprite`. `PowerUpBrick` stays in the catalogue as the shape the
        // icons are cut to.

        let suffix = GameScene.artSuffix(for: endlessIISizeOf(brick))
        guard suffix.isEmpty == false
                || name != endlessIIBrickTextureName(brick.texture) else { return nil }
        // Nothing to put on an ordinary brick that is already wearing its own picture

        let wanted = name + suffix
        guard UIImage(named: wanted) != nil else { return nil }
        return SKTexture(imageNamed: wanted)
        // Asked of the catalogue for the same reason the shaped lookup is: a missing name gets
        // a placeholder back from SpriteKit, not nil
    }

    /// Keeps a plain Square brick wearing the picture drawn for its proportions.
    ///
    /// **An overlay, not the brick's texture**, which is the rule at the top of this file:
    /// `hitBrick` and the row scans ask what a brick is by comparing `texture` against the
    /// type textures, so a Square brick that wore `BrickNormalSquare` would stop being a
    /// Normal brick. A shaped brick has a face node to draw on and a rounded one has its
    /// outline; a plain Square brick has neither, so it gets a child of its own.
    ///
    /// Anchored like its parent and sized to it, so it covers the stretched texture exactly.
    /// A child is positioned from the parent's origin rather than from its anchor, so the two
    /// agreeing on both is what puts them in the same place - and a Square brick's anchor is
    /// off centre on purpose (§8.6: the node stays on a row centre and the drawing hangs off
    /// it).
    func refreshEndlessIIBrickArt(_ brick: SKSpriteNode) {
        let worn = brick.childNode(withName: GameScene.brickArtName) as? SKSpriteNode
        guard brick.childNode(withName: GameScene.brickFaceName) == nil,
              brick.childNode(withName: GameScene.roundedBrickOutlineName) == nil,
              let texture = endlessIIOwnArt(for: brick) else {
            worn?.removeFromParent()
            return
            // Removed rather than left hidden, because the two nodes that draw a face do the
            // showing themselves once one is there - and a brick that has just been rounded
            // would otherwise wear both pictures
        }

        let sprite: SKSpriteNode
        if let worn {
            sprite = worn
        } else {
            sprite = SKSpriteNode(texture: texture)
            sprite.name = GameScene.brickArtName
            sprite.zPosition = 0.01
            brick.addChild(sprite)
        }
        let cell = endlessIIFieldSize(of: brick)
        let centre = endlessIIBrickCentre(of: brick)
        let shown = endlessIIShown(texture, on: brick)
        if sprite.texture != shown { sprite.texture = shown }
        if sprite.size != cell { sprite.size = cell }
        if sprite.anchorPoint != CGPoint(x: 0.5, y: 0.5) {
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        }
        if sprite.position != centre { sprite.position = centre }
        // **Off the cell and the drawn centre**, not off `brick.size` and the brick's anchor.
        // They are the same thing for most bricks and not for a power-up brick, whose sprite is
        // shrunk away behind its badge the way a rounded brick's is (round 274) - so the
        // picture has to be measured against what the brick *occupies* rather than against
        // what is left of the sprite underneath it
        if sprite.color != brick.color { sprite.color = brick.color }
        if sprite.colorBlendFactor != brick.colorBlendFactor {
            sprite.colorBlendFactor = brick.colorBlendFactor
        }
        // Refreshed rather than set once: a Multi-hit brick steps down through four textures
        // as it is hit, and a role tints the brick after it was built
    }
}
