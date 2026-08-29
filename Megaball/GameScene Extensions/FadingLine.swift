//
//  FadingLine.swift
//  Megaball
//
//  The soft line the predictions are drawn with.
//
//  Two effects draw a path that fades as it goes: the Ball Trajectory, and the Aimed Sticky's
//  aim. Both said so with a run of short `SKShapeNode` segments, each carrying its own
//  `glowWidth`, each handed a fresh `CGPath` every frame - forty-six of them per ball, and Multi
//  Ball puts four balls on the field. An `SKShapeNode` re-tessellates when it is handed a path,
//  and a glowing one is rendered through an offscreen pass of its own; neither shows up in a
//  timer around the tick, which is why round 258 counted them rather than timing them.
//
//  ## One picture, stretched
//
//  A segment is a straight bar with soft edges, and that is a *picture* rather than a shape:
//  drawn once, it can be stretched to any length and any thickness. So each segment is an
//  `SKSpriteNode` wearing the same texture - no path to tessellate, no offscreen pass, and,
//  because they share one texture, SpriteKit draws the whole line in a single batch.
//
//  ## Why the ends are soft, and why that is the whole trick
//
//  James, round 260: "The line currently isn't consistent, it's a bit dotty. I'd prefer it to be
//  more consistent / get more faded the further it is from the ball."
//
//  A segment is a rotated rectangle, and consecutive segments are different widths - that is
//  what the widening *is*. Butt them together and every join shows a step; overlap them and, on
//  an additive blend, every overlap shows a bright band. Round 258 drew both and looked at both.
//
//  The answer is neither: the picture ramps to nothing across its **ends** as well as its edges,
//  the ramp is held at a fixed size by `centerRect` while the middle stretches, and consecutive
//  segments overlap by exactly one ramp. A ramp fading out laid over a ramp fading in sums to
//  one, which is a crossfade - so the join is neither a step nor a band, and the line is
//  continuous however fast its width changes.
//
//  ## White core, green glow
//
//  James: "The line itself should be a blurry white with a giga-ball yellow/green glow - similar
//  to some other glowing style graphics in the game." So each segment is drawn twice: a wide,
//  faint one in the mode's own yellow-green, and a narrow white one over it. Same texture, same
//  blend mode, so it is still two batches rather than two draws per segment - and the glow being
//  a *stretch of the same picture* is what makes it grow with the blur for free.
//

import SpriteKit

enum FadingLine {

    /// How much of the picture's height is solid before the falloff starts.
    private static let coreShare: CGFloat = 0.34

    /// How much of the picture's width each end ramp takes.
    ///
    /// Held at its drawn size by `centerRect`, so this is a fraction of the *texture* and a
    /// fixed number of points on screen. `overlap` is that number.
    private static let rampShare: CGFloat = 0.25

    /// The picture's own width, in points, of which a quarter is ramp at each end.
    private static let drawnWidth: CGFloat = 32

    /// How far each segment reaches past the end of its own stretch, which must equal one ramp
    /// exactly.
    ///
    /// **Past its tail only, not both ends.** Reaching past *both* ends by a ramp makes the
    /// overlap two ramps long, and two linear ramps only sum to one across a *single* ramp - so
    /// the middle of every join had both segments at full strength and the line came out
    /// striped, twice as bright at every joint. Drawn and looked at, round 260. Extended at the
    /// tail alone, this segment's fade-out lies exactly over the next one's fade-in and the sum
    /// is one all the way along.
    static var overlap: CGFloat { drawnWidth*rampShare }

    /// The picture: a horizontal bar, solid down the middle, fading to nothing on all four
    /// sides - top and bottom for the blur, left and right for the crossfade.
    static let texture: SKTexture = {
        let size = CGSize(width: drawnWidth, height: 96)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let middle = size.height/2
            let core = size.height*coreShare/2
            let ramp = size.width*rampShare

            for y in stride(from: CGFloat(0), to: size.height, by: 1) {
                let distance = abs(y + 0.5 - middle)
                let across: CGFloat
                if distance <= core {
                    across = 1
                } else {
                    let out = (distance - core)/(middle - core)
                    across = max(0, 1 - out*out)
                    // Squared, so the falloff leaves the core gently and reaches nothing
                    // decisively - a linear ramp reads as a band with an edge on it
                }

                for x in stride(from: CGFloat(0), to: size.width, by: 1) {
                    let along: CGFloat
                    if x + 0.5 < ramp {
                        along = (x + 0.5)/ramp
                    } else if x + 0.5 > size.width - ramp {
                        along = (size.width - x - 0.5)/ramp
                    } else {
                        along = 1
                    }
                    // **Linear along the length, on purpose.** The end ramps are one half of a
                    // crossfade and the other half is the next segment's; two linear ramps sum
                    // to exactly one, and two curved ones do not

                    cg.setFillColor(UIColor(white: 1, alpha: across*along).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
        return SKTexture(image: image)
    }()

    /// Dresses one segment: a sprite stretched between two points, overlapping its neighbours
    /// by one ramp at each end.
    ///
    /// - Parameters:
    ///   - thickness: how thick the *solid* core should be. The sprite is made taller than this
    ///     so the falloff has somewhere to live, which is where the blur comes from.
    ///   - blur: how far past the core the fade should reach, in points.
    static func lay(_ segment: SKSpriteNode, from head: CGPoint, to tail: CGPoint,
                    thickness: CGFloat, blur: CGFloat, alpha: CGFloat) {
        let length = hypot(tail.x - head.x, tail.y - head.y)

        guard length > 0 else { return }

        segment.centerRect = CGRect(x: rampShare, y: 0, width: 1 - rampShare*2, height: 1)
        segment.size = CGSize(width: length + overlap, height: (thickness + blur*2)/coreShare)
        // Divided by the core's share, because that is the fraction of the picture the solid
        // part occupies - asking for a two-point core means a picture six points tall.
        //
        // One ramp longer than the gap it fills, and the extra is spent past the *tail*

        let heading = atan2(tail.y - head.y, tail.x - head.x)
        segment.position = CGPoint(x: (head.x + tail.x)/2 + cos(heading)*overlap/2,
                                   y: (head.y + tail.y)/2 + sin(heading)*overlap/2)
        // Shifted half the extra length along its own heading, so the sprite covers
        // [head, tail + one ramp] rather than sitting centred and reaching back past the head
        segment.zRotation = heading
        segment.alpha = alpha
    }

    /// A segment node, made the same way wherever one is needed.
    ///
    /// - Parameter glow: true for the wide coloured one that sits under the white core.
    static func segment(glow: Bool = false) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture)
        node.color = glow ? GameScene.endlessIIHaloColour : .white
        node.colorBlendFactor = 1
        node.blendMode = .add
        // Added rather than blended: these are light drawn over a dark field, so the glow and
        // the core sum into one bright line rather than the core hiding the glow
        node.zPosition = glow ? 2.9 : 3
        return node
    }
}
