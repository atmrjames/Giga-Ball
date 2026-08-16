//
//  EndlessIIFaces.swift
//  Megaball
//
//  Bricks that are not rectangles: Convex, Concave and Wedge (§12.0's "new brick
//  geometries").
//
//  Every brick in the game since 2020 has been a rectangle, so every bounce off the field
//  has been one of four answers. A shaped face changes that without changing anything else
//  about a brick: a Wedge is still a Standard brick worth a Standard score, it simply sends
//  the ball somewhere a rectangle never could. That is why these are styles rather than
//  behaviours - the axis for "what a brick does beyond being hit" (§4.0) already exists.
//
//  Three shapes, chosen because each answers a hit differently:
//
//      Convex   a dome. Off-centre hits are thrown wider than they arrived - it scatters
//      Concave  a notch. Hits near an edge are turned inward - it collects
//      Wedge    a right triangle. Everything reaching the slope leaves the same way
//
//  Two things make this harder than it looks, and both live in this file so the rest of the
//  scene never learns about them.
//
//  **The body has to be convex.** `SKPhysicsBody(polygonFrom:)` accepts convex paths only,
//  and a notch is not convex. So a face declares its *silhouette* (what is drawn, which may
//  be concave) separately from its *body pieces* (what the physics gets, always convex, and
//  assembled with `SKPhysicsBody(bodies:)` when there is more than one).
//
//  **The sprite has to hide inside the shape.** The face is drawn as a shape node filled
//  with the brick's own texture, exactly as Rounded does it - the sprite behind it keeps its
//  texture, because `endlessIIBehaviour(of:)` and every line in `hitBrick` identify a brick
//  by that texture and would be blinded by masking it. Rounded shrinks its sprite to 78% and
//  that is enough to hide a rectangle inside a rounded rectangle. It is not enough here: a
//  Wedge's hypotenuse passes through the node's own centre, so *no* centred rectangle fits
//  inside it at any scale. Each face therefore names the rectangle its sprite can hide in,
//  which the scene applies as a size and an anchor point - the Big brick's trick (§8.6),
//  used for the same reason: the node stays on its row centre and the drawing moves.
//
//  The geometry is a pure type so the two rules above can be tested rather than eyeballed:
//  every body piece is convex, and the hiding rectangle really is inside the silhouette.
//

import SpriteKit

/// A brick's shape, as the geometry thinks of it.
///
/// Its own small vocabulary rather than a subset of `EndlessIIStyle`, so the path maths
/// never has to answer for Portals and Spawners. The two are one-to-one and the bijection
/// is stated once, in `EndlessIIStyle.face` and `EndlessIIFace.style`, with a test that it
/// round-trips.
enum EndlessIIFace: String, CaseIterable {
    case convex, concave, wedge

    var style: EndlessIIStyle {
        switch self {
        case .convex: return .convex
        case .concave: return .concave
        case .wedge: return .wedge
        }
    }
}

/// The three shaped faces, and the paths that make them.
///
/// All paths are in the brick's own coordinates: the origin is the node, x runs right and
/// y runs up, and the shape fills the brick's full cell. Nothing here knows about SpriteKit.
enum EndlessIIFaceGeometry {

    /// How far the dome's shoulders sit below the brick's mid-line, as a fraction of height.
    ///
    /// Below the middle rather than at it, so the dome is most of the brick's face rather
    /// than a bump on top of a rectangle - the shape has to be obvious at a glance or the
    /// bounce it produces reads as a bug.
    static let convexShoulder: CGFloat = -0.10

    /// How deep the notch cuts, as a fraction of height above the mid-line.
    ///
    /// Deliberately shallow, and above the middle. A notch cut past the centre would leave
    /// the sprite nowhere to hide (see the file comment), and a deeper notch on a brick this
    /// size stops reading as a dish and starts reading as two bricks with a gap.
    static let concaveNotch: CGFloat = 0.10

    /// The outline the player sees. May be concave; is never used for physics.
    static func silhouette(_ face: EndlessIIFace, size: CGSize,
                           mirrored: Bool = false, flipped: Bool = false) -> CGPath {
        path(points(face, size: size, mirrored: mirrored, flipped: flipped))
    }

    /// The convex pieces the physics body is built from. One for the shapes that are already
    /// convex, two for the notch.
    static func bodyPieces(_ face: EndlessIIFace, size: CGSize,
                           mirrored: Bool = false, flipped: Bool = false) -> [CGPath] {
        let w = size.width, h = size.height
        switch face {
        case .convex, .wedge:
            return [silhouette(face, size: size, mirrored: mirrored, flipped: flipped)]
        case .concave:
            let notch = h*concaveNotch
            let halves = [
                [CGPoint(x: -w/2, y: -h/2), CGPoint(x: 0, y: -h/2),
                 CGPoint(x: 0, y: notch), CGPoint(x: -w/2, y: h/2)],
                [CGPoint(x: 0, y: -h/2), CGPoint(x: w/2, y: -h/2),
                 CGPoint(x: w/2, y: h/2), CGPoint(x: 0, y: notch)],
            ]
            return halves.map { path(reflected($0, mirrored: mirrored, flipped: flipped)) }
            // Split down the middle, where the notch bottoms out: each half is then a
            // quadrilateral with one sloped edge, which is convex. Both halves are reflected
            // by the same rule the silhouette uses, or a notch that faces down would be
            // drawn facing down and answer the ball facing up
        }
    }

    /// Where the sprite can hide so that no square corner shows outside the face.
    ///
    /// Given as a rectangle in the brick's coordinates rather than a scale factor, because
    /// the Wedge's is not centred on the node - it lives in the fat corner opposite the
    /// point.
    static func hidingRect(_ face: EndlessIIFace, size: CGSize,
                           mirrored: Bool = false, flipped: Bool = false) -> CGRect {
        let w = size.width, h = size.height
        let rect: CGRect
        switch face {
        case .convex:
            rect = CGRect(x: -w*0.275, y: -h*0.14, width: w*0.55, height: h*0.28)
        case .concave:
            rect = CGRect(x: -w*0.40, y: -h*0.08, width: w*0.80, height: h*0.16)
            // Wide and shallow: it has to stay under the notch at x = 0, which is the
            // lowest point of the face
        case .wedge:
            rect = CGRect(x: w*0.05, y: -h*0.45, width: w*0.40, height: h*0.40)
            // Tucked into the corner beneath the slope
        }
        return rect.offsetBy(dx: mirrored ? -rect.midX*2 : 0,
                             dy: flipped ? -rect.midY*2 : 0)
        // Reflected by its centre, which is what keeps it inside the face whichever way the
        // face is turned. The dome's and the notch's are centred on y already, so only the
        // Wedge's actually travels when the shape is turned upside down
    }

    /// The corners of each face, counterclockwise - which is the winding a polygon body
    /// wants.
    private static func points(_ face: EndlessIIFace, size: CGSize,
                               mirrored: Bool, flipped: Bool = false) -> [CGPoint] {
        let w = size.width, h = size.height
        let shape: [CGPoint]
        switch face {
        case .convex:
            let shoulder = h*convexShoulder
            shape = [CGPoint(x: -w/2, y: -h/2), CGPoint(x: w/2, y: -h/2),
                     CGPoint(x: w/2, y: shoulder), CGPoint(x: 0, y: h/2),
                     CGPoint(x: -w/2, y: shoulder)]
        case .concave:
            let notch = h*concaveNotch
            shape = [CGPoint(x: -w/2, y: -h/2), CGPoint(x: w/2, y: -h/2),
                     CGPoint(x: w/2, y: h/2), CGPoint(x: 0, y: notch),
                     CGPoint(x: -w/2, y: h/2)]
        case .wedge:
            shape = [CGPoint(x: -w/2, y: -h/2), CGPoint(x: w/2, y: -h/2),
                     CGPoint(x: w/2, y: h/2)]
        }
        return reflected(shape, mirrored: mirrored, flipped: flipped)
    }

    /// A shape turned over in one axis, the other, or both.
    ///
    /// **Flipping vertically is the interesting one** (James, round 154). Every shaped brick
    /// used to face up, and in a mode where the field comes down to meet the ball almost
    /// every hit lands on a brick's *underside* - so a field of domes and wedges was a field
    /// of flat undersides, and the shapes were doing far less than they read as doing.
    ///
    /// Reversed when exactly one reflection is applied: each one flips the winding on its
    /// own, and a clockwise path is one a polygon body reads inside out - but two reflections
    /// are a rotation, which does not.
    private static func reflected(_ shape: [CGPoint],
                                  mirrored: Bool, flipped: Bool) -> [CGPoint] {
        guard mirrored || flipped else { return shape }
        let turned = shape.map { CGPoint(x: mirrored ? -$0.x : $0.x,
                                         y: flipped ? -$0.y : $0.y) }
        return mirrored == flipped ? turned : turned.reversed()
    }

    private static func path(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return path
    }

    /// Whether a path's corners turn the same way all the way round - which is what
    /// `SKPhysicsBody(polygonFrom:)` means by convex. Used by the tests, and cheap enough to
    /// be worth having rather than trusting the arithmetic above.
    static func isConvex(_ points: [CGPoint]) -> Bool {
        guard points.count >= 3 else { return false }
        var sign = 0
        for index in points.indices {
            let a = points[index]
            let b = points[(index + 1) % points.count]
            let c = points[(index + 2) % points.count]
            let cross = (b.x - a.x)*(c.y - b.y) - (b.y - a.y)*(c.x - b.x)
            guard abs(cross) > 0.0001 else { continue }
            let thisSign = cross > 0 ? 1 : -1
            if sign == 0 { sign = thisSign } else if sign != thisSign { return false }
        }
        return sign != 0
    }

    /// The corners of a face, for the tests and for the reference page's artwork.
    static func corners(_ face: EndlessIIFace, size: CGSize,
                        mirrored: Bool = false, flipped: Bool = false) -> [CGPoint] {
        points(face, size: size, mirrored: mirrored, flipped: flipped)
    }
}

extension GameScene {

    /// The drawn silhouette of a shaped brick. Named so the per-frame refresh can find it,
    /// and kept distinct from Rounded's outline so `endlessIIStyles(on:)` can still tell
    /// which of the two a brick is wearing.
    static let brickFaceName = "endlessIIBrickFace"

    /// Gives a brick a shaped face: a new body, a new outline, and the sprite tucked out of
    /// sight behind it.
    ///
    /// The sprite is not hidden, shrunk to nothing, or re-textured - every one of those
    /// would blind `hitBrick`, which knows what a brick is only from `texture`. It is moved
    /// and resized into the rectangle the face says is safely inside itself, where it goes
    /// on quietly being the brick's identity while the shape node does the showing.
    func makeFace(_ face: EndlessIIFace, on brick: SKSpriteNode) {
        let cell = brick.size
        let mirrored = face == .wedge ? (brick.endlessIIFaceMirrored ?? Bool.random()) : false
        let flipped = brick.endlessIIFaceFlipped ?? Bool.random()
        // Only the Wedge has a handedness worth varying - a mirrored dome is the same dome -
        // but all three have a *way up*, and turning it over is what James asked for in round
        // 154. It matters more than it sounds: the field descends to meet the ball, so most
        // hits land on a brick's underside, and a face that always pointed up presented a
        // flat one. Half of them now point down, where the ball actually arrives
        brick.endlessIIFaceMirrored = mirrored
        brick.endlessIIFaceFlipped = flipped
        // Recorded, because a resumed game rebuilds the brick and would otherwise re-roll
        // the orientation - the round-150 lesson, one level further in

        let pieces = EndlessIIFaceGeometry.bodyPieces(face, size: cell, mirrored: mirrored,
                                                      flipped: flipped)
            .map { SKPhysicsBody(polygonFrom: $0) }
        brick.physicsBody = brickBody(pieces.count == 1 ? pieces[0]
                                                        : SKPhysicsBody(bodies: pieces))
        // One convex polygon where the shape allows it, a compound of two where it does not

        let shape = SKShapeNode(path: EndlessIIFaceGeometry.silhouette(face, size: cell))
        shape.xScale = mirrored ? -1 : 1
        shape.yScale = flipped ? -1 : 1
        // The path is built the right way up and the *node* is turned, which is the same
        // geometry - each reflection is a pure one - and unlike a reflected path it takes the
        // fill texture with it. A drawn wedge inside a mirrored path would have had its
        // shading running the wrong way up the slope, and an upside-down one would have been
        // lit from below
        shape.fillColor = brick.colorBlendFactor > 0.5 ? brick.color : .white
        shape.strokeColor = .clear
        shape.zPosition = 0.1
        shape.name = GameScene.brickFaceName
        brick.addChild(shape)

        if refreshEndlessIIFaceArt(brick, shape, GameScene.shapedArt(for: face),
                                   cell: cell) == false {
            shape.fillTexture = endlessIIFaceFill(brick, nil)
        }

        let hide = EndlessIIFaceGeometry.hidingRect(face, size: cell, mirrored: mirrored,
                                                   flipped: flipped)
        brick.size = hide.size
        brick.anchorPoint = CGPoint(x: 0.5 - hide.midX/hide.width,
                                    y: 0.5 - hide.midY/hide.height)
        // The anchor is what moves the drawing without moving the node - the node stays on
        // its row centre, which is the one thing the descent and the bottom-row check read
        // (§8.6). For the dome and the notch this is the anchor it already had; only the
        // Wedge's sprite has to go and sit in a corner
        brick.endlessIIFace = face
    }

    /// Keeps a shaped brick's face showing what the brick is.
    ///
    /// The same job `refreshEndlessIIRoundedFaces` does for Rounded, and for the same
    /// reason: a Multi-hit brick steps down through four textures as it is hit, and the
    /// face is a separate node that would otherwise still be showing the first.
    func refreshEndlessIIShapedFaces() {
        enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode,
                  let shape = brick.childNode(withName: GameScene.brickFaceName)
                    as? SKShapeNode else { return }
            let wantedColour = brick.colorBlendFactor > 0.5 ? brick.color : UIColor.white
            let art = brick.endlessIIFace.flatMap { GameScene.shapedArt(for: $0) }
            let cell = self.endlessIIFaceCell(brick, shape: shape)
            if self.refreshEndlessIIFaceArt(brick, shape, art, cell: cell) == false {
                let wanted = self.endlessIIFaceFill(brick, nil)
                if shape.fillTexture !== wanted { shape.fillTexture = wanted }
            }
            if shape.fillColor != wantedColour, shape.fillTexture != nil {
                shape.fillColor = wantedColour
            }
        }
    }
}
