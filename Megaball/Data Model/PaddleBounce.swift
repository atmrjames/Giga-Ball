//
//  PaddleBounce.swift
//  Megaball
//
//  The angle a ball leaves the paddle at.
//
//  This is the single most characteristic number in the game - it is what makes the paddle a
//  control rather than a wall - and it was written out three times: in `paddleHit`, in the Portal
//  Paddle's re-entry, and again in the paddle-speed screen's practice field, where it was not
//  written out at all but left to the physics engine's own reflection. That last one is why
//  this file exists: a screen for choosing how the paddle feels was returning the ball at an
//  angle the game never would (James, play-test round 147).
//
//  So the arithmetic lives here once, with no SpriteKit in it, and everything that bounces a
//  ball off a paddle asks this.
//

import CoreGraphics
import Foundation
import SpriteKit
import UIKit

enum PaddleBounce {

    /// Where on the paddle the ball landed: -1 at the left edge, 0 at the middle, +1 at the
    /// right.
    ///
    /// Not clamped. A value outside -1...1 means the ball met the paddle's end rather than
    /// its face, and the callers use that to decide whether the bounce is a paddle bounce at
    /// all - so clamping here would quietly turn an edge hit into a face hit.
    static func collision(ballX: CGFloat, paddleX: CGFloat, paddleWidth: CGFloat) -> Double {
        guard paddleWidth > 0 else { return 0 }
        return Double((ballX - paddleX)/(paddleWidth/2))
    }

    /// The angle the ball leaves at, in degrees, measured anticlockwise from the +x axis with
    /// y upwards - so 90 is straight up, 10 is a shallow shot to the right.
    ///
    /// The arriving velocity decides the base angle, and *where* on the paddle it landed bends
    /// it: the further from the middle, the more it is turned toward that side. The vertical
    /// component is taken as an absolute, because the answer always travels up - a ball is
    /// only bounced by the paddle's top face.
    ///
    /// - Parameters:
    ///   - influence: 1 normally. Inert Paddle makes it 0 (the spot stops mattering) and
    ///     Flipped Angle makes it -1 (the spot matters backwards).
    ///   - minimumDeg: how flat a shot may be. Without it the paddle's edges return balls
    ///     that run along the field sideways for seconds at a time.
    static func angleDegrees(arriving: CGVector, collision: Double,
                             adjustmentK: Double, influence: Double,
                             minimumDeg: Double) -> Double {
        let base = atan2(Double(abs(arriving.dy)), Double(arriving.dx))*180/Double.pi
        let bent = base - adjustmentK*collision*influence
        return min(max(bent, minimumDeg), 180 - minimumDeg)
    }

    /// The same answer as a velocity, at whatever speed is asked for.
    static func velocity(arriving: CGVector, collision: Double, adjustmentK: Double,
                         influence: Double, minimumDeg: Double, speed: CGFloat) -> CGVector {
        let degrees = angleDegrees(arriving: arriving, collision: collision,
                                   adjustmentK: adjustmentK, influence: influence,
                                   minimumDeg: minimumDeg)
        let radians = degrees*Double.pi/180
        return CGVector(dx: CGFloat(cos(radians))*speed, dy: CGFloat(sin(radians))*speed)
    }

    /// The game's own numbers, so a screen that wants to feel like the game does not have to
    /// know them: 45 degrees of bend at the very edge, and never flatter than 10.
    static let adjustmentK: Double = 45
    static let minimumDeg: Double = 10

    // MARK: - Shaped faces

    /// The shape of the paddle's top, which is a family of bad power-ups (§12.0, James's
    /// play-test idea from the fourth round, pulled into 1.3 at round 100).
    ///
    /// Every one of them works the same way: the paddle's face is no longer flat, so *where*
    /// the ball landed no longer maps to the outgoing angle in a straight line. They cost a
    /// curve rather than a physics body, which is the whole reason four of them are
    /// affordable - the bounce already asks one question ("how far from the middle?") and a
    /// shape is an answer to that question with a bend in it.
    enum Surface: String, CaseIterable {
        /// A dome. The middle is steeper than a flat paddle, so small differences near the
        /// centre matter more than they should - the safest part of the paddle stops being
        /// safe.
        case convex
        /// A dish. The middle is flatter and the ends are sharper, so a ball landing anywhere
        /// near the centre comes back almost straight and the edges throw it away hard.
        case concave
        /// Three shallow waves across the face. The angle rises and falls with the landing
        /// spot rather than climbing steadily, so two landings a ball's width apart can send
        /// it opposite ways.
        case wavy
        /// Sawtoothed. The angle climbs, reverses at a corner, climbs again - five turns
        /// across the face - so two landings a ball's width apart can be at opposite ends of
        /// the range. The least predictable of the four, and the only one that is
        /// *un*readable rather than merely harder to read.
        case jagged
        /// Sloped one way: the whole face tilts, so every landing sends the ball leftward,
        /// harder the further out it lands. Unlike the others it has no symmetry at all -
        /// which is the point of having two of them.
        case wedgeLeft
        /// The same slope, mirrored.
        case wedgeRight

        var displayName: String {
            switch self {
            case .convex: return "Convex Paddle"
            case .concave: return "Concave Paddle"
            case .wavy: return "Wavy Paddle"
            case .jagged: return "Jagged Paddle"
            case .wedgeLeft: return "Wedge Left Paddle"
            case .wedgeRight: return "Wedge Right Paddle"
            }
        }

        /// **The number this shape is written down as. These are on disk - never move one.**
        ///
        /// A paused run saves the shape it is wearing, and it comes back from a file written
        /// by whatever build the player paused in. Spelled out rather than taken from
        /// `allCases`, because `allCases` follows the order the cases happen to be declared
        /// in, and a tidy-up that groups the two wedges together would silently turn every
        /// saved Wave into a Jagged.
        ///
        /// Zero is deliberately not used: a clock's magnitude defaults to zero, so a shape
        /// starting at one means "no shape recorded" and "convex" cannot be confused.
        var savedCode: Int {
            switch self {
            case .convex: return 1
            case .concave: return 2
            case .wavy: return 3
            case .jagged: return 4
            case .wedgeLeft: return 5
            case .wedgeRight: return 6
            }
        }

        init?(savedCode: Int) {
            guard let match = Surface.allCases.first(where: { $0.savedCode == savedCode })
            else { return nil }
            self = match
        }

        /// The largest code a save can legitimately hold, for the clamp on the way back in.
        static var highestSavedCode: Int { allCases.map(\.savedCode).max() ?? 0 }

        /// This face seen in a mirror.
        ///
        /// James, round 233: "the mirror paddle should be a mirror of the original paddle,
        /// that includes the paddle's shape. e.g. if the original paddle is wedge left, the
        /// mirror paddle should be wedge right."
        ///
        /// Only the wedges change, and that is not a shortcut. Convex and concave are
        /// symmetrical about their middle, so each one *is* its own reflection and swapping it
        /// for anything else would be wrong rather than economical. Wave and Jagged are not
        /// symmetrical, and their reflections were never drawn - a mirrored Wave would need a
        /// sixth picture and a seventh case for a face nobody has asked to see - so they wear
        /// themselves, which is what the mirror did for every shape until this round.
        var mirrored: Surface {
            switch self {
            case .wedgeLeft: return .wedgeRight
            case .wedgeRight: return .wedgeLeft
            case .convex, .concave, .wavy, .jagged: return self
            }
        }
    }

    /// Where the ball *behaves* as though it landed, given the shape of the face.
    ///
    /// The bounce is unchanged: it still turns a position into an angle in one line. A shape
    /// only decides which position that line is given, which is why these four cost four
    /// functions rather than four physics bodies - and why Inert Paddle still flattens them
    /// (it sets the influence to zero, so nothing the shape says is heard) and Auto-Aim still
    /// beats them (it replaces the angle afterwards).
    ///
    /// Every shape is odd - f(-x) = -f(x) - so no shape has a bias to one side, and every one
    /// stays inside -1...1 so a shaped paddle can never send a ball flatter than a flat one.
    static func shaped(_ collision: Double, by surface: Surface?) -> Double {
        guard let surface else { return collision }
        let clamped = min(max(collision, -1), 1)

        switch surface {
        case .convex:
            // Steeper in the middle, and levelling off toward the ends
            return sin(clamped*Double.pi/2)
        case .concave:
            // Flat in the middle, steep at the ends
            return clamped*clamped*clamped
        case .wavy:
            let waves = sin(clamped*Double.pi*3)*0.45
            return min(max(clamped*0.55 + waves, -1), 1)
        case .jagged:
            return 2/Double.pi*asin(sin(clamped*Double.pi*2.5))
            // A triangle wave: straight ramps meeting at corners, five of them across the
            // face. The first attempt built it out of flat facets and a sawtooth, which was
            // neither odd nor continuous - it favoured one side and jumped at every seam,
            // and a paddle with a bias is a paddle that is wrong rather than tricky
        case .wedgeLeft:
            return min(max(clamped*0.6 - 0.4, -1), 1)
        case .wedgeRight:
            return min(max(clamped*0.6 + 0.4, -1), 1)
            // **A bias on purpose**, which is the one thing every other face here avoids. The
            // whole slope tilts, so the middle of the paddle no longer returns the ball
            // straight up and the player has to aim from somewhere other than under the ball.
            // Kept shallow - a shift of four tenths on a face that runs from -1 to 1 - because
            // a wedge steep enough to be obvious is a paddle that can only send the ball one
            // way, and these still have to be playable rather than merely survivable.
            //
            // These two are the fallback: with the shaped art in play the *silhouette* decides
            // the bounce (round 213) and this function is not consulted. It matters where the
            // art has not been drawn for a theme yet, and it is what the reference page's
            // profile drawing samples, so it still has to describe the same face.
        }
    }
}


/// A shaped paddle's outline, computed from its picture rather than traced from it.
///
/// **Why not just trace it.** `SKPhysicsBody(texture:size:)` walks the artwork's alpha at the
/// size the body is built for - about 75 points across - and returns a polygon that follows the
/// *pixels*. Round 277 measured what that leaves the ball: 20 steps across the dome, 26 across
/// the dish, 32 across the wave, each up to two points high, where the plain paddle's flat top
/// has none. A ball 12 points wide meeting a two-point step gets the step's normal rather than
/// the curve's, so a shaped paddle answers some hits with the shape it is drawn as and others
/// with the corner of a pixel.
///
/// The staircase is a sampling artefact, not the shape. This finds the same edge to *sub-pixel*
/// precision - where the alpha crosses half, interpolated between two rows - smooths what is
/// left, and hands back a curve. The picture still decides the shape, which is James's round-213
/// requirement ("the paddle physics body should match the shape of the new paddle textures"):
/// this is the same silhouette, read properly.
///
/// **Vertical strips, because two of the five are not convex.** A dome and the two wedges are
/// convex and could each be one polygon; a dish and a wave are not, and `SKPhysicsBody` will
/// only take convex ones. Every shape is cut into strips instead, each a quadrilateral and so
/// convex by construction, and handed over as a compound body - the same answer
/// `EndlessIIFaceGeometry` gives the concave brick, at a finer grain because the paddle is the
/// surface the game is played on.
enum PaddleOutline {

    /// How many strips a paddle is cut into.
    ///
    /// Twenty across seventy-five points is under four points a strip, which is a third of a
    /// ball - fine enough that the ball meets the curve rather than the cut, and coarse enough
    /// that the body is twenty fixtures rather than seventy-five.
    static let strips = 20

    /// How finely the picture is read, per strip.
    ///
    /// The edge is found in the artwork's own pixels and then averaged down, so the number that
    /// matters is how many samples each strip is the average of. Four is enough to place the
    /// edge well inside a pixel and cheap enough to do at build time.
    static let samplesPerStrip = 4

    /// How far either side of a boundary the average reaches, in strips.
    ///
    /// One, so each boundary is the average of two strips' worth of samples and shares half of
    /// them with each neighbour. Less than that and neighbouring boundaries see disjoint sets
    /// of pixels, which is sampling rather than smoothing - and measurably worse than not
    /// bothering, which is how this number came to be chosen rather than assumed.
    static let reach: CGFloat = 1

    /// Where the top and bottom edges are, per sample, in fractions of the picture's height
    /// measured from its bottom. Nil where the column is empty.
    ///
    /// **Sub-pixel by interpolation.** A column's edge is not the first opaque row, it is where
    /// the alpha crosses a half *between* two rows - so a curve that rises by a third of a pixel
    /// per column is read as rising by a third of a pixel rather than as flat, flat, flat, jump.
    /// That single change is the whole difference between a staircase and a curve.
    static func edges(of image: CGImage, samples: Int) -> [(top: CGFloat, bottom: CGFloat)?] {
        let width = image.width, height = image.height
        guard width > 0, height > 0, samples > 0 else { return [] }

        var pixels = [UInt8](repeating: 0, count: width*height*4)
        guard let context = CGContext(data: &pixels, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width*4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return [] }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        func alpha(_ x: Int, _ y: Int) -> CGFloat {
            CGFloat(pixels[(y*width + x)*4 + 3])/255
        }

        return (0..<samples).map { sample in
            let x = min(width - 1, Int((CGFloat(sample) + 0.5)/CGFloat(samples)*CGFloat(width)))

            var first: Int?, last: Int?
            for y in 0..<height where alpha(x, y) >= 0.5 {
                if first == nil { first = y }
                last = y
            }
            guard let first, let last else { return nil }

            // Row indices run down the image and the answer runs up it, so the *first* opaque
            // row is the top edge and the flip happens at the end
            let top = crossing(from: first, towards: -1, x: x, height: height, alpha: alpha)
            let bottom = crossing(from: last, towards: 1, x: x, height: height, alpha: alpha)
            return (top: 1 - top/CGFloat(height), bottom: 1 - bottom/CGFloat(height))
        }
    }

    /// Where the alpha crosses a half, walking one row out from a known opaque one.
    private static func crossing(from row: Int, towards step: Int, x: Int, height: Int,
                                 alpha: (Int, Int) -> CGFloat) -> CGFloat {
        let inside = alpha(x, row)
        let neighbour = row + step
        guard neighbour >= 0, neighbour < height else { return CGFloat(row) }
        let outside = alpha(x, neighbour)
        guard inside > outside else { return CGFloat(row) }
        let share = (inside - 0.5)/(inside - outside)
        return CGFloat(row) + CGFloat(step)*share
        // The edge sits `share` of the way from the last opaque row towards the first clear
        // one. A hard-edged picture answers 0.5 and a soft-edged one answers wherever the ramp
        // actually reaches half, which is the point
    }
}

extension PaddleOutline {

    /// The silhouette as a run of strip boundaries: top and bottom, in points, about the
    /// paddle's centre.
    ///
    /// Averaged down from the fine samples rather than sampled again coarsely, so every pixel
    /// of the picture has a say in where the curve goes - which is what makes the result smooth
    /// rather than merely finer-grained.
    static func boundaries(of image: CGImage, size: CGSize)
        -> [(x: CGFloat, top: CGFloat, bottom: CGFloat)] {
        let fine = edges(of: image, samples: strips*samplesPerStrip)
        guard fine.isEmpty == false else { return [] }

        var run: [(x: CGFloat, top: CGFloat, bottom: CGFloat)] = []
        for boundary in 0...strips {
            let centre = CGFloat(boundary)/CGFloat(strips)
            let window = (0..<fine.count).filter { sample in
                abs((CGFloat(sample) + 0.5)/CGFloat(fine.count) - centre) <= reach/CGFloat(strips)
            }
            // **A moving average, overlapping its neighbours.** The first version took a window
            // exactly one strip wide, so neighbouring boundaries shared no samples at all -
            // which is not smoothing, it is just sampling in blocks, and it measured *rougher*
            // than the plain trace it was meant to beat. Overlapping windows are what make one
            // boundary's answer constrain the next one's.

            let weighted: [(weight: CGFloat, edge: (top: CGFloat, bottom: CGFloat))] =
                window.compactMap { sample in
                    guard let edge = fine[sample] else { return nil }
                    let offset = abs((CGFloat(sample) + 0.5)/CGFloat(fine.count) - centre)
                    return (weight: max(0.05, 1 - offset*CGFloat(strips)/reach), edge: edge)
                }
            guard weighted.isEmpty == false else { continue }
            let total = weighted.map(\.weight).reduce(0, +)

            let top = weighted.map { $0.weight*$0.edge.top }.reduce(0, +)/total
            let bottom = weighted.map { $0.weight*$0.edge.bottom }.reduce(0, +)/total
            // **Weighted towards the middle of the window, not a flat average of it.** A box
            // filter smooths by flattening, and what it flattens hardest is the extremes: the
            // dish's shoulders came out nearly two points below the picture, which is the body
            // sitting inside the art - the very thing round 213 fixed. A triangular kernel
            // removes the same sampling noise and keeps the peaks, because the sample at the
            // boundary itself carries most of the answer
            run.append((x: (centre - 0.5)*size.width,
                        top: (top - 0.5)*size.height,
                        bottom: (bottom - 0.5)*size.height))
        }
        return run
    }

    /// The convex pieces a body is built from - **as few as the shape allows**.
    ///
    /// Round 280 emitted one quadrilateral per strip: twenty pieces, and therefore *nineteen
    /// internal seams* running from the paddle's floor to the surface the ball rolls along.
    /// Two convex boxes that share a face still meet as two bodies, and a ball crossing the
    /// join can catch on the vertical edge of the next one - the ghost-collision problem every
    /// physics engine has with decomposed geometry, and a very good way to make a ball stutter
    /// along a paddle (James, three play tests running).
    ///
    /// The outline does not change. What changes is how much of it each piece covers: the run
    /// is walked once, extending the current piece while the polygon it makes is still convex,
    /// and cut only where it stops being. A dome and both wedges are convex outright and come
    /// out as **one** piece with no seam anywhere; a dish and a wave genuinely need more than
    /// one, and get the fewest their own curvature allows rather than a fixed twenty.
    static func pieces(of image: CGImage, size: CGSize) -> [CGPath] {
        let measured = boundaries(of: image, size: size)
        guard measured.count > 1 else { return [] }

        let run = simplified(measured)
        // **Noise reads as concavity, and concavity forces a cut.** A stretch of paddle that is
        // straight to within a tenth of a point still turns very slightly one way and then the
        // other, and a strict convexity test counts every one of those as a corner - which is
        // why the first version of this cut a *wedge*, whose top is one straight slope, into
        // nine pieces. Flattening what is already flat leaves the real corners and nothing else.

        var pieces: [CGPath] = []
        var start = 0
        while start < run.count - 1 {
            var end = start + 1
            while end + 1 < run.count,
                  EndlessIIFaceGeometry.isConvex(corners(run, from: start, to: end + 1)) {
                end += 1
            }
            // Greedy: take as much as stays convex, then cut. `isConvex` ignores collinear
            // triples, so a flat stretch of floor or surface costs nothing

            if let path = polygon(run, from: start, to: end) { pieces.append(path) }
            start = end
        }
        return pieces
    }

    /// How far a boundary may sit off the line between its neighbours and still be dropped.
    ///
    /// A sixth of a point. Small enough that no corner of any of the five shapes is lost -
    /// their gentlest is the dome's crown, which turns far more than this across one strip -
    /// and large enough to absorb the wobble left by reading an edge off pixels.
    static let flatEnough: CGFloat = 1/6

    /// Drops boundaries that say nothing: the ones lying on the line between their neighbours.
    static func simplified(_ run: [(x: CGFloat, top: CGFloat, bottom: CGFloat)])
        -> [(x: CGFloat, top: CGFloat, bottom: CGFloat)] {
        guard run.count > 2 else { return run }

        var kept = [run[0]]
        for index in 1..<(run.count - 1) {
            let previous = kept[kept.count - 1], next = run[index + 1]
            let span = next.x - previous.x
            guard span > 0.01 else { continue }

            let along = (run[index].x - previous.x)/span
            let onTop = previous.top + (next.top - previous.top)*along
            let onFloor = previous.bottom + (next.bottom - previous.bottom)*along
            if abs(run[index].top - onTop) > flatEnough
                || abs(run[index].bottom - onFloor) > flatEnough {
                kept.append(run[index])
            }
            // Measured from the last *kept* boundary rather than from the neighbour, so a long
            // straight stretch collapses to its two ends rather than to every other point
        }
        kept.append(run[run.count - 1])
        return kept
    }

    /// A run of boundaries as a closed outline, wound counterclockwise: along the floor
    /// left to right, then back along the surface.
    private static func corners(_ run: [(x: CGFloat, top: CGFloat, bottom: CGFloat)],
                                from: Int, to: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        for index in from...to { points.append(CGPoint(x: run[index].x, y: run[index].bottom)) }
        for index in stride(from: to, through: from, by: -1) {
            points.append(CGPoint(x: run[index].x, y: run[index].top))
        }
        return points
    }

    private static func polygon(_ run: [(x: CGFloat, top: CGFloat, bottom: CGFloat)],
                                from: Int, to: Int) -> CGPath? {
        guard run[to].x - run[from].x > 0.01 else { return nil }
        let tall = (from...to).contains { run[$0].top - run[$0].bottom > 0.5 }
        guard tall else { return nil }
        // The rounded ends taper to nothing, and a degenerate piece is not a small body but an
        // undefined one

        let path = CGMutablePath()
        path.addLines(between: corners(run, from: from, to: to))
        path.closeSubpath()
        return path
    }

    /// The body itself, or nil where the picture says nothing useful.
    static func body(for texture: SKTexture, size: CGSize) -> SKPhysicsBody? {
        guard size.width > 1, size.height > 1 else { return nil }
        let key = Key(texture: ObjectIdentifier(texture),
                      width: Int((size.width*10).rounded()),
                      height: Int((size.height*10).rounded()))
        if let kept = cache[key] { return kept.copy() as? SKPhysicsBody }

        guard let image = UIImage(named: texture.description.name)?.cgImage
                ?? texture.cgImage() as CGImage? else { return nil }
        let pieces = pieces(of: image, size: size)
        guard pieces.isEmpty == false else { return nil }

        let bodies = pieces.map { SKPhysicsBody(polygonFrom: $0) }
        let body = bodies.count == 1 ? bodies[0] : SKPhysicsBody(bodies: bodies)
        cache[key] = body
        return body.copy() as? SKPhysicsBody
        // Kept and copied, the way `TracedBodyCache` keeps a traced one: reading the picture and
        // cutting it into twenty polygons is a build-time cost, and a run collects the same five
        // shapes over and over
    }

    /// **How high the surface stands, across the paddle.** The other half of a shape.
    ///
    /// `shaped(_:by:)` answers where a ball behaves as though it landed - the *angle* half of
    /// a shaped face - and until round 313 there was no answer to the matching question, which
    /// is how high the face is at that point. A held ball was placed at
    /// `paddle.position.y + paddle.size.height/2`: the top of the sprite's box, which on a
    /// curve is the single highest point of the curve and nothing else.
    ///
    /// **Measured before it was built** (`testHowFarAHeldBallFloatsAboveAShapedPaddle`), and
    /// the queue's estimate of "a fraction of a ball at the extreme ends of two of the six
    /// shapes" was badly out. Against a twelve-point ball: a dome's ends are **8.96 points
    /// low, three quarters of a ball**; a wave's are 6.38; and both wedges' low ends are
    /// **11.07, ninety-two per cent of a ball** - the whole ball hanging in the air beside the
    /// slope. The dish is the one that breaks the estimate's shape as well as its size, being
    /// worst **half way out** at 6.08 rather than at its ends at 1.82, because a dish turns up
    /// into its corners. Five shapes, not two, and most of a ball, not a fraction of one.
    ///
    /// The run is the same silhouette the body is cut from, so the ball rests on the surface
    /// it will bounce off rather than on a second opinion about where that surface is - and it
    /// costs nothing extra, because it is read from the same measurement and cached beside it.
    static func profile(for texture: SKTexture, size: CGSize) -> [(x: CGFloat, top: CGFloat)]? {
        guard size.width > 1, size.height > 1 else { return nil }
        let key = Key(texture: ObjectIdentifier(texture),
                      width: Int((size.width*10).rounded()),
                      height: Int((size.height*10).rounded()))
        if let kept = profiles[key] { return kept }

        guard let image = UIImage(named: texture.description.name)?.cgImage
                ?? texture.cgImage() as CGImage? else { return nil }
        let run = boundaries(of: image, size: size).map { (x: $0.x, top: $0.top) }
        guard run.count > 1 else { return nil }
        profiles[key] = run
        return run
    }

    /// Where the surface is, at one distance from the paddle's centre, in points about the
    /// paddle's own centre.
    ///
    /// **Interpolated between boundaries rather than snapped to the nearest one.** The run is
    /// twenty-one points across seventy-five, so snapping would step the ball by up to a third
    /// of its own width as it slid along - which is the staircase `PaddleOutline` exists to
    /// get rid of, reintroduced one layer up.
    ///
    /// Past either end it holds the end's height. A ball is only ever placed within the
    /// paddle's own width, so this is a guard rather than a case: the alternative is
    /// extrapolating a curve beyond the picture it was read from, and a dome extrapolated
    /// far enough goes underground.
    static func top(for texture: SKTexture, size: CGSize,
                    atOffsetFromCentre offset: CGFloat) -> CGFloat? {
        guard let run = profile(for: texture, size: size) else { return nil }
        guard let first = run.first, let last = run.last else { return nil }
        if offset <= first.x { return first.top }
        if offset >= last.x { return last.top }

        for (left, right) in zip(run, run.dropFirst()) where offset <= right.x {
            let span = right.x - left.x
            guard span > 0.0001 else { return left.top }
            let share = (offset - left.x)/span
            return left.top + (right.top - left.top)*share
        }
        return last.top
    }

    private struct Key: Hashable {
        let texture: ObjectIdentifier
        let width: Int
        let height: Int
    }

    private static var cache: [Key: SKPhysicsBody] = [:]
    private static var profiles: [Key: [(x: CGFloat, top: CGFloat)]] = [:]

    /// For the tests, which must be able to measure a cold build.
    static func empty() { cache.removeAll(); profiles.removeAll() }
}

private extension String {
    /// The asset name inside an `SKTexture`'s description, which reads
    /// `<SKTexture> 'regularPaddleConvex' (225 x 45)`.
    var name: String {
        guard let start = firstIndex(of: "'"),
              let end = self[index(after: start)...].firstIndex(of: "'") else { return self }
        return String(self[index(after: start)..<end])
    }
}
