//
//  FadingLine.swift
//  Megaball
//
//  The soft line the predictions are drawn with, and why it stopped being a shape node.
//
//  Two effects draw a path that fades and blurs as it goes: the Ball Trajectory, and the Aimed
//  Sticky's aim. Both said so with a run of short `SKShapeNode` segments, each carrying its own
//  `glowWidth`, each handed a fresh `CGPath` every frame.
//
//  James, round 258: "Game is stuttering whilst certain power ups are enabled... Trajectory
//  line". Counted rather than guessed at (`EndlessIIFrameCostTests`): a full-length trajectory
//  is **forty-six glowing shape nodes, per ball, rebuilt every frame** - and Multi Ball puts
//  four balls on the field, so nearly two hundred. The arithmetic that positions them is
//  nothing, a fiftieth of a frame; the cost is not there and never was. An `SKShapeNode`
//  re-tessellates its path when you assign one, and a *glowing* one is rendered through an
//  offscreen pass of its own. Neither shows up in a timer around the tick, which is why this
//  needed counting rather than timing.
//
//  ## One picture, stretched
//
//  A segment is a straight bar with soft edges, and that is a *picture* rather than a shape:
//  drawn once, it can be stretched to any length and any thickness. So each segment is an
//  `SKSpriteNode` wearing the same texture - which means no path to tessellate, no offscreen
//  pass, and, because they all share one texture, SpriteKit draws the whole line in a single
//  batch instead of forty-six.
//
//  **The blur comes from the stretch.** The picture is a solid core with a falloff either
//  side, so a segment scaled thin has its soft edges squeezed under a pixel and reads as a
//  crisp line, and the same segment scaled thick spreads them and reads as a blur. That is
//  exactly what `glowWidth` was being asked for - "a wide faint line is what the eye reads as
//  fuzz", from the round that tuned it - said with a scale instead of a render pass.
//
//  The same file serves both effects, because they were already the same drawing written
//  twice.
//

import SpriteKit

enum FadingLine {

    /// How much of the picture's height is solid before the falloff starts.
    private static let coreShare: CGFloat = 0.34

    /// The picture: a horizontal bar, solid down the middle, fading to nothing top and bottom.
    ///
    /// Tall enough that the falloff has room to be smooth and no taller - it is only ever
    /// stretched, so its own size is a question about the gradient's resolution rather than
    /// about anything on screen.
    static let texture: SKTexture = {
        let size = CGSize(width: 4, height: 96)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let middle = size.height/2
            let core = size.height*coreShare/2

            for y in stride(from: CGFloat(0), to: size.height, by: 1) {
                let distance = abs(y + 0.5 - middle)
                let alpha: CGFloat
                if distance <= core {
                    alpha = 1
                } else {
                    let out = (distance - core)/(middle - core)
                    alpha = max(0, 1 - out*out)
                    // Squared, so the falloff leaves the core gently and reaches nothing
                    // decisively - a linear ramp reads as a band with an edge on it
                }
                cg.setFillColor(UIColor(white: 1, alpha: alpha).cgColor)
                cg.fill(CGRect(x: 0, y: y, width: size.width, height: 1))
            }
        }
        return SKTexture(image: image)
    }()

    /// Dresses one segment: a sprite stretched between two points.
    ///
    /// - Parameters:
    ///   - thickness: how thick the *solid* core should be. The sprite is made taller than
    ///     this so the falloff has somewhere to live, which is where the blur comes from.
    ///   - blur: how far past the core the fade should reach, in points.
    static func lay(_ segment: SKSpriteNode, from head: CGPoint, to tail: CGPoint,
                    thickness: CGFloat, blur: CGFloat, alpha: CGFloat) {
        let length = hypot(tail.x - head.x, tail.y - head.y)
        let height = (thickness + blur*2)/coreShare
        // Divided by the core's share, because that is the fraction of the picture the solid
        // part occupies - asking for a two-point core means a picture six points tall

        segment.size = CGSize(width: length, height: height)
        // **Abutting, not overlapping.** The obvious answer to the small step where two
        // segments of different widths meet - the thing the shape node's round cap used to
        // hide - is to make each one longer so they overlap. Drawn and looked at, that is
        // worse: two soft bars laid over each other add up, so every join becomes a bright
        // band and the line reads as a ladder. Ends that met exactly came out smooth, so they
        // meet exactly. What is left is a faint scalloping at the far end, where the widths
        // change fastest and the line is nearly invisible anyway

        segment.position = CGPoint(x: (head.x + tail.x)/2, y: (head.y + tail.y)/2)
        segment.zRotation = atan2(tail.y - head.y, tail.x - head.x)
        segment.alpha = alpha
    }

    /// A segment node, made the same way wherever one is needed.
    static func segment() -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture)
        node.color = .white
        node.colorBlendFactor = 0
        node.blendMode = .add
        // Added rather than blended: these are light drawn over a dark field, and where two
        // segments meet at a corner the overlap should brighten rather than darken
        node.zPosition = 3
        return node
    }
}
