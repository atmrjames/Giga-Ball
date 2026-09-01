//
//  BrickTypeIcons.swift
//  Megaball
//
//  Pictures of bricks for the reference page.
//
//  Everything new in Endless 2.0 is wearing a placeholder - an ordinary brick tinted a colour
//  nothing else uses, with a shape drawn over it saying what it does (§8.5). The reference page
//  wears the same placeholders, deliberately. A page showing finished artwork for a brick the
//  player meets as a tinted rectangle would be a page that makes bricks harder to recognise
//  rather than easier, and the artwork is last on the list precisely because these have already
//  changed shape twice.
//
//  So the colours and the glyph geometry here are the ones in `EndlessIIBehaviourBricks`,
//  read from the same constants where they are constants. When the real artwork arrives this
//  file is where the page starts using it.
//

import UIKit

enum BrickTypeIcons {

    /// The size every icon is drawn at.
    ///
    /// Wider than it is tall, because a brick is - drawing one into a square canvas and
    /// letting the row's image view fit it would waste half the height it has to play with,
    /// and the icons are only 40 points across to begin with. Not the brick's own 2:1 either,
    /// since a Big brick and a turning one both need room around them.
    static let canvas = CGSize(width: 120, height: 80)

    /// A brick that is the subject of its own picture, filling what the canvas will give it.
    private static let feature = CGSize(width: 104, height: 52)

    /// One ordinary cell, for the size pictures - where the whole point is how the three
    /// compare, so a Big one has to be drawn twice the size rather than fitted to the frame.
    private static let cell = CGSize(width: 52, height: 26)

    /// The turning brick, which has to fit its own swept circle rather than the canvas.
    private static let spinning = CGSize(width: 84, height: 42)

    static func image(for art: BrickTypeArt) -> UIImage {
        UIGraphicsImageRenderer(size: canvas).image { context in
            let cgContext = context.cgContext
            switch art {
            case .behaviour(let behaviour):
                draw(behaviour, in: cgContext)
            case .style(let style):
                draw(style, in: cgContext)
            case .size(let size):
                draw(size, in: cgContext)
            case .powerUpBrick:
                drawPowerUpBrick()
            }
        }
    }

    /// The picture the bricks page uses to mean "a power-up".
    ///
    /// **One particular power-up's icon, standing for all of them**, which is a deliberate
    /// choice and not an oversight. James, round 283, asked for "a generic power up graphic",
    /// and round 284 read that as the brick's own badge - `PowerUpBrick`, the yellow block a
    /// power-up brick wears before an icon is cut into it. Round 289: "rather than showing the
    /// power-up brick as a yellow block, use the PowerUpClearAndRetreat graphic as a generic
    /// power-up graphic."
    ///
    /// The block was the more literal answer and the worse one. A yellow rectangle beside eight
    /// other brick pictures reads as *another kind of brick* rather than as the thing a brick
    /// gives you, and it is the one entry on the page whose picture a player never actually
    /// meets - in the field the block always has an icon on it.
    ///
    /// Named here rather than written into the drawing, so the day a purpose-drawn generic
    /// badge exists (§8.5) this is the one line that changes.
    static let genericPowerUpArtName = "PowerUpClearAndRetreat"

    /// The power-up brick, drawn as the thing it hands over.
    ///
    /// Square, because the brick is: one cell across and two down (`BrickSize.square`), and the
    /// power-up icons are square too - so one side serves both and nothing is stretched.
    private static func drawPowerUpBrick() {
        let side = min(canvas.height, canvas.width)*0.82
        let frame = centred(CGSize(width: side, height: side))
        artwork(genericPowerUpArtName)?.draw(in: frame)
    }

    // MARK: - Behaviours

    /// The states a behaviour passes through, in the order a player meets them.
    ///
    /// A brick that changes as it is hit is not one picture, it is the sequence - a Multi-Hit
    /// brick's whole identity is that it steps down, and an Indestructible ×1 is only
    /// interesting because of what it turns into. So they get one row each showing every
    /// state, rather than a row per state showing a brick with no explanation of where it came
    /// from.
    static func states(of behaviour: EndlessIIBehaviour) -> [String] {
        switch behaviour {
        case .standard: return ["BrickNormal"]
        case .multiHit: return ["BrickMultiHit1", "BrickMultiHit2",
                                "BrickMultiHit3", "BrickMultiHit4"]
        case .indestructibleOnce, .indestructibleAlways:
            return ["BrickIndestructible1", "BrickIndestructible2"]
        case .invisible: return ["BrickInvisible"]
        }
    }

    private static func draw(_ behaviour: EndlessIIBehaviour, in context: CGContext) {
        let states = states(of: behaviour)
        let frames = row(of: states.count)

        for (index, name) in states.enumerated() {
            let frame = frames[index]
            switch behaviour {
            case .standard:
                // White. A Standard brick is coloured by the level it is in rather than by
                // being a Standard brick, and the artwork is white before anything tints it
                artwork(name)?.tinted(standardColour).draw(in: frame)
            case .invisible:
                // Drawn as it looks once it has been struck, faded, because a picture of a
                // brick that is not drawn is an empty square
                artwork(name)?.draw(in: frame, blendMode: .normal, alpha: 0.5)
                outline(frame, in: context)
            default:
                artwork(name)?.draw(in: frame)
            }
        }
    }

    /// Where each of several states sits.
    ///
    /// One across, two side by side - and four in a two-by-two grid rather than a row of four.
    /// Four bricks across a forty-point icon leaves each one ten points wide, which is not a
    /// brick any more; stacked, they are twice that and the eye reads the sequence left to
    /// right and then down, which is the order they happen in anyway.
    private static func row(of count: Int) -> [CGRect] {
        guard count > 1 else { return [centred(feature)] }

        let columns = count > 2 ? 2 : count
        let rows = Int((Double(count)/Double(columns)).rounded(.up))

        let gap = canvas.width*0.04
        let width = (canvas.width - gap*CGFloat(columns - 1))/CGFloat(columns)
        let height = min(width/2, (canvas.height - gap*CGFloat(rows - 1))/CGFloat(rows))

        let blockHeight = height*CGFloat(rows) + gap*CGFloat(rows - 1)
        let top = (canvas.height - blockHeight)/2

        return (0..<count).map { index in
            CGRect(x: (width + gap)*CGFloat(index % columns),
                   y: top + (height + gap)*CGFloat(index/columns),
                   width: width, height: height)
        }
    }

    private static let standardColour = UIColor.white

    // MARK: - Styles

    private static func colour(of style: EndlessIIStyle) -> UIColor {
        switch style {
        case .gravity: return GameScene.gravityBrickColour
        case .moving: return GameScene.movingBrickColour
        case .directional: return GameScene.directionalBrickColour
        case .exploding: return GameScene.explodingBrickColour
        case .spawner: return GameScene.spawnerBrickColour
        case .portal: return GameScene.portalBrickColour
        case .fixed: return GameScene.fixedBrickColour
        case .flashing: return #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        case .breathing: return GameScene.breathingBrickColour
        case .rounded, .spinning, .convex, .concave, .wedge, .diamond: return standardColour
        }
    }
    // The six field-changing roles keep the scene's own constants. Rounded and Spinning are
    // not tinted in the game at all - they change a brick's shape and its motion, not its
    // colour - so they are shown in the colour an ordinary brick wears

    private static func draw(_ style: EndlessIIStyle, in context: CGContext) {
        let frame = centred(feature)
        let tint = colour(of: style)

        switch style {
        case .wedge:
            // **The drawn face, the same one the game wears** (James, round 164: "update the
            // info pages with the new textures"). It is a silhouette already - transparent
            // where the shape is not - so it needs no clipping, and the highlight sits where
            // it was drawn to sit rather than where a stretched rectangle happens to put it
            artwork(shapedArtwork("BrickNormal", .wedge))?.tinted(tint).draw(in: frame)
            return

        case .convex, .concave, .diamond:
            // No drawn art for these three yet (§8.5), so they keep the approximation: an
            // ordinary brick clipped to the very path the game builds the body and the outline
            // from, so the picture cannot drift from the shape. `EndlessIIFaceGeometry` draws
            // in scene coordinates (y up) about the shape's own centre, which is what the
            // transform below undoes.
            //
            // The day that art lands, these join the case above and this branch goes.
            // Diamond needs it least: its silhouette is four straight edges, so the clipped
            // approximation is the shape rather than a flat-sided guess at a curve
            guard let face = style.face else { return }
            context.saveGState()
            context.translateBy(x: frame.midX, y: frame.midY)
            context.scaleBy(x: 1, y: -1)
            context.addPath(EndlessIIFaceGeometry.silhouette(face, size: frame.size))
            context.clip()
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: -frame.midX, y: -frame.midY)
            artwork("BrickNormal")?.tinted(tint).draw(in: frame)
            context.restoreGState()
            return

        case .rounded:
            artwork(shapedArtwork("BrickNormal", .rounded))?.tinted(tint).draw(in: frame)
            return

        case .spinning:
            // Drawn part-way round, and nothing else. An arrow was added on the theory that a
            // still picture cannot show turning; a brick sitting at an angle when every other
            // brick in the app is square-on already says it, and the arrow was one more thing
            // to read in a forty-point icon.
            //
            // Smaller than the others, because a brick twice as wide as it is tall needs the
            // room to get round - which is the same reason the generator leaves the cells
            // beside a spinner empty
            context.saveGState()
            context.translateBy(x: canvas.width/2, y: canvas.height/2)
            context.rotate(by: -.pi/9)
            let turning = CGRect(x: -BrickTypeIcons.spinning.width/2,
                                 y: -BrickTypeIcons.spinning.height/2,
                                 width: BrickTypeIcons.spinning.width,
                                 height: BrickTypeIcons.spinning.height)
            artwork("BrickNormal")?.tinted(tint).draw(in: turning)
            context.restoreGState()
            return

        case .flashing:
            // Half-way through fading out, which is the state that says what it does
            artwork("BrickNormal")?.tinted(tint).draw(in: frame, blendMode: .normal, alpha: 0.55)
            outline(frame, in: context)
            return

        case .breathing:
            // Caught mid-breath, with the cell it came from drawn round it: a brick smaller
            // than the space it owns is the whole idea, and a shrunken brick alone in a
            // frame would just read as a Tiny one
            outline(frame, in: context)
            let breath = frame.insetBy(dx: frame.width*0.22, dy: frame.height*0.22)
            artwork("BrickNormal")?.tinted(tint).draw(in: breath)
            return

        case .portal:
            if let drawn = artwork(GameScene.portalBrickArtName) {
                drawn.draw(in: frame)
                return
            }
            // James's picture since round 273, which has the rings in it - so the page shows
            // what the field shows rather than a second drawing of the same idea. The two
            // lines below are what a Portal was before it and what it still is anywhere the
            // picture is missing: left untinted, as in the game, because the Indestructible
            // artwork is dark and any colour put through it comes out muddy
            artwork("BrickIndestructible2")?.draw(in: frame)
            drawPortalRings(in: frame, context: context)
            return

        case .directional:
            artwork("BrickNormal")?.tinted(standardColour).draw(in: frame)
            artwork("BrickDirectionalBottomOpen")?.draw(in: frame)
            // The *ordinary* brick under the panel, not a grey one. The grey was the old
            // identity and round 284 took it off the brick in the field for the reason the
            // page has to follow: what shows through the open side is what kind of brick it is
            // **James's panel, the same one the field wears** (round 283: "update the
            // directional graphic"). The page drew its own white bar across the bottom, which
            // was a fair picture of the old mark and no picture at all of the one round 271
            // replaced it with - the panel darkens the three hard sides and leaves the soft one
            // clear, so what a player sees on the page is now what they will meet.
            //
            // Facing down, which is the common case: the ball spends most of its time
            // travelling up and down, so above and below are the sides a player can plan for
            return

        case .gravity, .moving, .exploding, .spawner, .fixed:
            artwork("BrickNormal")?.tinted(tint).draw(in: frame)
            stroke(glyph(for: style, in: frame), in: context, width: max(1.5, frame.height*0.08))
            return
        }
    }

    /// The shapes drawn over the tinted bricks, at the proportions `EndlessIIBehaviourBricks`
    /// draws them.
    private static func glyph(for style: EndlessIIStyle, in frame: CGRect) -> CGPath {
        let centre = CGPoint(x: frame.midX, y: frame.midY)
        let path = CGMutablePath()

        switch style {
        case .gravity:
            let unit = frame.height*0.28
            // Downward in UIKit is a larger y, so the chevron is the scene's flipped
            path.move(to: CGPoint(x: centre.x - unit, y: centre.y - unit/2))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y + unit/2))
            path.addLine(to: CGPoint(x: centre.x + unit, y: centre.y - unit/2))

        case .moving:
            let unit = frame.height*0.26
            path.move(to: CGPoint(x: centre.x - unit*1.6, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x + unit*1.6, y: centre.y))
            for direction in [CGFloat(-1), 1] {
                let tip = CGPoint(x: centre.x + direction*unit*1.6, y: centre.y)
                path.move(to: tip)
                path.addLine(to: CGPoint(x: centre.x + direction*unit*0.8, y: centre.y - unit*0.7))
                path.move(to: tip)
                path.addLine(to: CGPoint(x: centre.x + direction*unit*0.8, y: centre.y + unit*0.7))
            }

        case .exploding:
            let unit = frame.height*0.3
            for step in 0..<4 {
                let angle = CGFloat(step)*(.pi/4)
                path.move(to: CGPoint(x: centre.x - cos(angle)*unit, y: centre.y - sin(angle)*unit))
                path.addLine(to: CGPoint(x: centre.x + cos(angle)*unit, y: centre.y + sin(angle)*unit))
            }

        case .spawner:
            let unit = frame.height*0.28
            path.move(to: CGPoint(x: centre.x - unit, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x + unit, y: centre.y))
            path.move(to: CGPoint(x: centre.x, y: centre.y - unit))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y + unit))

        case .fixed:
            let unit = frame.height*0.28
            path.move(to: CGPoint(x: centre.x - unit, y: centre.y + unit*0.7))
            path.addLine(to: CGPoint(x: centre.x + unit, y: centre.y + unit*0.7))
            path.move(to: CGPoint(x: centre.x, y: centre.y + unit*0.7))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y - unit*0.9))
            // **Turned over with the game's** (round 273, James: "flip it upside down so the
            // top of the T is at the bottom of the brick"). The signs are the opposite of
            // `makeFixed`'s and always have been: this is drawn into a `UIGraphicsImageRenderer`
            // where y runs down the page, and the scene's y runs up it

        default:
            break
        }
        return path
    }

    private static func drawPortalRings(in frame: CGRect, context: CGContext) {
        let radius = min(frame.width, frame.height)*0.3
        let centre = CGPoint(x: frame.midX, y: frame.midY)

        context.saveGState()
        context.setStrokeColor(GameScene.portalBlueColour.cgColor)
        context.setLineWidth(max(1.5, frame.height*0.1))
        context.strokeEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                         width: radius*2, height: radius*2))
        context.strokeEllipse(in: CGRect(x: centre.x - radius*0.5, y: centre.y - radius*0.5,
                                         width: radius, height: radius))
        // Two rings, so it cannot be mistaken for a Rounded brick's single one
        context.restoreGState()
    }

    // MARK: - Sizes

    private static func draw(_ size: BrickSize, in context: CGContext) {
        // One cell, dashed, so the three pictures can be compared - a brick on its own says
        // nothing about how much room it takes
        let reference = centred(cell)
        context.saveGState()
        context.setStrokeColor(UIColor(white: 0.55, alpha: 0.9).cgColor)
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.stroke(reference)
        // Solid enough to survive being drawn at forty points across, which is all the row
        // gives it - a one-point hairline at a third opacity disappeared entirely, and with
        // it the only thing saying what a Tiny brick is small compared to
        context.restoreGState()

        let brick = centred(CGSize(width: cell.width*size.scaleWide,
                                   height: cell.height*size.scaleTall))
        // Per axis, since round 247: a Square brick is one cell across and two down, and a
        // single scale would have drawn it as a Big one

        let drawn = size == .square ? "BrickNormal" + GameScene.squareArtSuffix : "BrickNormal"
        let picture = artwork(drawn) ?? artwork("BrickNormal")
        picture?.tinted(standardColour).draw(in: brick)
        // **The picture drawn for those proportions where there is one** (round 270). The
        // reference page had the same stretch the field had - one oblong brick pulled to twice
        // its height - which made the page a picture of the bug rather than of the brick
    }

    // MARK: - Drawing helpers

    private static func centred(_ size: CGSize) -> CGRect {
        CGRect(x: (canvas.width - size.width)/2, y: (canvas.height - size.height)/2,
               width: size.width, height: size.height)
    }

    private static func outline(_ frame: CGRect, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(UIColor(white: 1, alpha: 0.45).cgColor)
        context.setLineWidth(1)
        context.stroke(frame)
        context.restoreGState()
    }

    private static func stroke(_ path: CGPath, in context: CGContext, width: CGFloat) {
        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(UIColor(white: 0, alpha: 0.75).cgColor)
        context.setLineWidth(width)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.strokePath()
        context.restoreGState()
    }

    /// The artwork, in whichever brick set the player has chosen.
    ///
    /// The Retro theme swaps the brick textures out in the scene, so a reference page still
    /// showing the standard ones is a page of bricks the player does not have. It swaps
    /// exactly what the scene swaps - Normal, Invisible and the four Multi-Hit stages - and
    /// leaves the rest, because there is no Retro Indestructible artwork and inventing a
    /// substitute here would be the page disagreeing with the game again.
    private static func artwork(_ named: String) -> UIImage? {
        UIImage(named: retroName(for: named) ?? named)
    }

    /// What a brick's drawn face for a shape is called.
    ///
    /// The scene's own rule - the plain texture's name with the shape's name after it - read
    /// off `GameScene.ShapedBrickArt` rather than spelled again here, so the page cannot end
    /// up naming an asset the game does not use.
    ///
    /// The theme is resolved on the *base* name and the shape appended after, because
    /// `retroName(for:)` knows the six plain bricks and not their shaped faces: given
    /// "BrickNormalRounded" it would find nothing and a Retro player would be shown the
    /// classic face on a page that is otherwise entirely their theme.
    private static func shapedArtwork(_ base: String,
                                      _ shape: GameScene.ShapedBrickArt) -> String {
        (retroName(for: base) ?? base) + shape.rawValue
    }

    /// What the Retro theme calls a brick, if it has its own.
    static func retroName(for named: String) -> String? {
        guard UserDefaults.standard.integer(forKey: "brickSetting") == 1 else { return nil }
        switch named {
        case "BrickNormal": return "retroBrickNormal"
        case "BrickInvisible": return "retroBrickInvisible"
        case "BrickMultiHit1": return "RetroBrickMultiHit1"
        case "BrickMultiHit2": return "RetroBrickMultiHit2"
        case "BrickMultiHit3": return "RetroBrickMultiHit3"
        case "BrickMultiHit4": return "RetroBrickMultiHit4"
        default: return nil
        }
    }
}
