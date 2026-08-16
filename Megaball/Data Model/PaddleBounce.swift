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
}
