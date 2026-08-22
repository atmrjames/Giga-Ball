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
            case .wavy: return "Wave Paddle"
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
