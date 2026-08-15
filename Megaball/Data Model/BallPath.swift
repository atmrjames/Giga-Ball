//
//  BallPath.swift
//  Megaball
//
//  Where a ball is about to go.
//
//  Two of Endless 2.0's new power-ups are the same question asked at different lengths: the
//  Trajectory Line draws the path ahead until it meets something, and the Landing Marker says
//  only where that path crosses the paddle's line. So they share one predictor, and the
//  predictor is arithmetic rather than physics - given where a ball is and how it is
//  travelling, it walks the path forward, turning at the walls and stopping at the first brick.
//
//  Pure on purpose. Everything here is testable without a scene, which matters more than usual:
//  a prediction that is subtly wrong is worse than none at all, because the player will aim
//  with it. A line that says "you will hit that brick" and does not is a lie the game told.
//
//  It predicts the ball the game actually simulates, which is not quite the ball a physicist
//  would: the scene nudges angles away from horizontal and vertical, and a bounce off two
//  bricks at once is resolved as one flat face. Those corrections are small and they are
//  applied *at* a bounce, so a path drawn to the first brick is honest and a path drawn
//  through several bounces of a busy field is not. That is why the line has a length limit
//  rather than running until it hits something.
//

import CoreGraphics

enum BallPath {

    /// The walls a predicted ball can turn on, and the line it is heading for.
    struct Bounds {
        /// The inside faces of the side walls.
        var left: CGFloat
        var right: CGFloat
        /// The inside face of the ceiling.
        var ceiling: CGFloat
        /// The height the paddle catches at.
        var paddleLine: CGFloat

        /// Whether the sides are doorways rather than walls.
        ///
        /// Wrap-Around does not move the walls - it answers a contact with a teleport to the
        /// far side instead of a bounce (§5.4) - so a prediction that reflects at the wall
        /// draws a path the ball will not take while it runs (play-test round 122).
        var sidesWrap: Bool = false
    }

    /// What a ball would do next.
    struct Prediction: Equatable {
        /// The path as a polyline, starting at the ball. Two points is a straight run; each
        /// extra point is a bounce off a wall.
        var points: [CGPoint]
        /// Where the path crosses the paddle's line, if it gets there.
        var landing: CGPoint?
        /// Whether the path stopped because a brick is in the way.
        var stoppedAtBrick: Bool
    }

    /// How many wall bounces a prediction will follow before giving up.
    ///
    /// A ball crossing a narrow field at a shallow angle can bounce many times in a short
    /// distance, and each bounce is a place the real ball's angle rules may nudge it - so a
    /// path that keeps going gets less true the longer it is. This is the point at which it
    /// stops being a prediction and starts being a guess.
    static let maximumBounces = 8

    /// Walks the ball forward from where it is.
    ///
    /// - Parameters:
    ///   - radius: the ball's radius. Everything is inset by it, so the path is the path of
    ///     the ball's *surface* against the walls and bricks rather than of its centre.
    ///   - bricks: the field, as rectangles. A brick is what stops the path.
    ///   - maximumLength: how far to follow it. Zero or less means as far as it goes.
    ///   - brickBounces: how many bricks the path may bounce off before stopping. Zero, the
    ///     default, stops at the first - which is what the Landing Marker wants and what the
    ///     Trajectory Line wanted before round 42.
    static func predict(from start: CGPoint, velocity: CGVector, radius: CGFloat,
                        bounds: Bounds, bricks: [CGRect],
                        maximumLength: CGFloat = 0,
                        brickBounces: Int = 0) -> Prediction {
        let speed = (velocity.dx*velocity.dx + velocity.dy*velocity.dy).squareRoot()
        guard speed > 0 else {
            return Prediction(points: [start], landing: nil, stoppedAtBrick: false)
        }

        var direction = CGVector(dx: velocity.dx/speed, dy: velocity.dy/speed)
        var point = start
        var points = [start]
        var travelled: CGFloat = 0
        var landing: CGPoint?
        var stoppedAtBrick = false
        var bricksLeft = brickBounces

        for _ in 0...maximumBounces {
            let toBrick = firstBrick(from: point, direction: direction,
                                     radius: radius, bricks: bricks)
            let toWall = sideWall(from: point, direction: direction, radius: radius,
                                  bounds: bounds)
            let toCeiling = ceiling(from: point, direction: direction, radius: radius,
                                    bounds: bounds)
            let toPaddle = paddleLine(from: point, direction: direction, radius: radius,
                                      bounds: bounds)

            let nearest = [toBrick?.distance, toWall, toCeiling, toPaddle]
                .compactMap { $0 }.min() ?? 0
            guard nearest > 0 else { break }

            // Cut short rather than overshooting, and stop: a length limit is a limit on the
            // line, not on the number of bounces it is allowed to draw before reaching it
            if maximumLength > 0, travelled + nearest >= maximumLength {
                let remaining = maximumLength - travelled
                points.append(CGPoint(x: point.x + direction.dx*remaining,
                                      y: point.y + direction.dy*remaining))
                return Prediction(points: points, landing: landing, stoppedAtBrick: false)
            }

            point = CGPoint(x: point.x + direction.dx*nearest, y: point.y + direction.dy*nearest)
            points.append(point)
            travelled += nearest

            if let brick = toBrick, nearest == brick.distance {
                guard bricksLeft > 0 else {
                    stoppedAtBrick = true
                    break
                }
                bricksLeft -= 1
                if brick.vertical { direction.dx = -direction.dx } else { direction.dy = -direction.dy }
                continue
                // A bounce off the face the ball actually meets. Each one spends a bounce from
                // the budget the caller set, because the scene applies its own corrections *at*
                // a bounce - the angle nudges off horizontal and vertical, the two-brick seam
                // resolved as one face - so every brick the prediction passes through is a
                // place this and the real ball may part company. Two is where the line stops
                // being useful and starts being a claim (play-test rounds 38 and 39); the
                // drawing fades with distance to say so
            }
            if nearest == toPaddle {
                landing = point
                break
            }
            if nearest == toCeiling {
                direction.dy = -direction.dy
                continue
            }
            if bounds.sidesWrap {
                // Out one side, in at the other, still travelling the same way. The polyline
                // gets a break rather than a corner: the two segments are drawn separately,
                // which is what the wrapped ball actually does
                let inset = radius + 1
                point.x = point.x > 0 ? bounds.left + inset : bounds.right - inset
                points.append(point)
                continue
            }
            direction.dx = -direction.dx
        }

        return Prediction(points: points, landing: landing, stoppedAtBrick: stoppedAtBrick)
    }

    // MARK: - How far to the next thing

    private static func sideWall(from point: CGPoint, direction: CGVector, radius: CGFloat,
                                 bounds: Bounds) -> CGFloat? {
        if direction.dx > 0 {
            return distance(to: bounds.right - radius - point.x, along: direction.dx)
        }
        if direction.dx < 0 {
            return distance(to: bounds.left + radius - point.x, along: direction.dx)
        }
        return nil
    }

    private static func ceiling(from point: CGPoint, direction: CGVector, radius: CGFloat,
                                bounds: Bounds) -> CGFloat? {
        guard direction.dy > 0 else { return nil }
        return distance(to: bounds.ceiling - radius - point.y, along: direction.dy)
    }

    private static func paddleLine(from point: CGPoint, direction: CGVector, radius: CGFloat,
                                   bounds: Bounds) -> CGFloat? {
        guard direction.dy < 0 else { return nil }
        return distance(to: bounds.paddleLine + radius - point.y, along: direction.dy)
    }

    private static func distance(to gap: CGFloat, along component: CGFloat) -> CGFloat? {
        let travel = gap/component
        return travel > 0.0001 ? travel : nil
        // Anything at or behind the current point is not ahead of it. Without the tolerance a
        // ball resting exactly against a wall reports a bounce every step and never moves
    }

    /// How far to the nearest brick along this heading.
    ///
    /// The brick is grown by the ball's radius and the ball treated as a point, which is the
    /// standard way to ask this and the only one that gets the corners right. A brick the ball
    /// is already inside is ignored - that is the brick it just hit, and stopping the path on
    /// it would draw no path at all.
    /// The nearest brick in the way, and which way its face points.
    ///
    /// The face matters once the path is allowed to bounce off bricks rather than stop at
    /// them: the slab test below already works out which pair of faces was crossed last on
    /// the way in, and that is the face struck. It simply was not asked for before.
    private static func firstBrick(from point: CGPoint, direction: CGVector, radius: CGFloat,
                                   bricks: [CGRect]) -> (distance: CGFloat, vertical: Bool)? {
        var nearest: (distance: CGFloat, vertical: Bool)?
        for brick in bricks {
            let grown = brick.insetBy(dx: -radius, dy: -radius)
            guard grown.contains(point) == false else { continue }
            guard let hit = entry(into: grown, from: point, direction: direction) else { continue }
            if nearest == nil || hit.distance < nearest!.distance { nearest = hit }
        }
        return nearest
    }

    /// Where a ray enters a rectangle, by the slab method.
    ///
    /// The near faces are crossed first and the far faces last, so the ray is inside the
    /// rectangle between the largest near crossing and the smallest far one. If that range is
    /// empty the ray misses.
    private static func entry(into rect: CGRect, from point: CGPoint,
                              direction: CGVector) -> (distance: CGFloat, vertical: Bool)? {
        var enter = -CGFloat.greatestFiniteMagnitude
        var leave = CGFloat.greatestFiniteMagnitude

        var enteredOnVerticalFace = false
        for (axis, origin, heading, low, high) in
                [(0, point.x, direction.dx, rect.minX, rect.maxX),
                 (1, point.y, direction.dy, rect.minY, rect.maxY)] {
            if abs(heading) < 0.000001 {
                guard origin >= low, origin <= high else { return nil }
                continue
                // Travelling parallel to this pair of faces: it either passes between them
                // for ever or misses them for ever
            }
            let first = (low - origin)/heading
            let second = (high - origin)/heading
            let near = min(first, second)
            if near > enter {
                enter = near
                enteredOnVerticalFace = axis == 0
                // The *last* near face crossed is the one entered through, which is the face
                // the ball meets - so whichever axis raises `enter` last owns the bounce
            }
            leave = min(leave, max(first, second))
        }

        guard leave >= enter, leave > 0 else { return nil }
        guard enter > 0.0001 else { return nil }
        return (enter, enteredOnVerticalFace)
    }
}

/// Proves a flight loop before anything is allowed to break it.
///
/// The old answer was a random kick on one bounce in ten, which broke loops by making
/// every rally slightly wrong (removed in round 98; James confirmed in round 100 that it
/// was nevertheless load-bearing, because a well-aligned Portal pair can cycle the ball
/// for ever). This is the targeted replacement: a loop is only called a loop when the
/// same bounce - same place, same heading - has happened three times with no paddle
/// contact between, and only then does the caller nudge anything. The bounces that were
/// never looping are never touched, which is what the kick got wrong.
///
/// **Lives in this file rather than its own** for the pbxproj reason `WhatsNew` gives.
struct BallLoopDetector {

    private var signatures: [Int] = []

    /// The same bounce seen this many times is a loop, not a coincidence.
    static let repeatsThatProveALoop = 3

    /// How much history is kept. A real loop repeats within a few bounces; anything that
    /// takes longer than this to come round is a rally, not a loop.
    static let capacity = 24

    /// Records a bounce, and reports whether it has just proved a loop.
    ///
    /// Proving one clears the history, so the caller's single nudge gets a chance to work
    /// before the same loop can be proved again.
    mutating func recordBounce(x: CGFloat, y: CGFloat, headingDegrees: Double,
                               cell: CGFloat) -> Bool {
        let signature = BallLoopDetector.signature(x: x, y: y,
                                                   headingDegrees: headingDegrees, cell: cell)
        signatures.append(signature)
        if signatures.count > BallLoopDetector.capacity { signatures.removeFirst() }
        guard signatures.filter({ $0 == signature }).count
                >= BallLoopDetector.repeatsThatProveALoop else { return false }
        signatures.removeAll()
        return true
    }

    /// The player touched the ball: whatever was repeating, they can change it now.
    mutating func playerIntervened() { signatures.removeAll() }

    /// A bounce, quantised to half-brick cells and five-degree headings - coarse enough
    /// that a loop's tiny frame-to-frame drift still reads as the same bounce, fine enough
    /// that two different rallies do not.
    static func signature(x: CGFloat, y: CGFloat, headingDegrees: Double,
                          cell: CGFloat) -> Int {
        let step = max(cell, 1)
        let xq = Int((x/step).rounded())
        let yq = Int((y/step).rounded())
        let hq = Int((headingDegrees/5).rounded())
        return xq &* 73_856_093 ^ yq &* 19_349_663 ^ hq &* 83_492_791
        // Deterministic mixing rather than Hasher, which reseeds per launch - a saved
        // comparison must not depend on which run of the app produced it
    }
}

/// A vector turned through an angle, for the portal drift.
func rotated(_ vector: CGVector, byDegrees degrees: Double) -> CGVector {
    let radians = degrees * .pi / 180
    let dx = Double(vector.dx), dy = Double(vector.dy)
    return CGVector(dx: dx*cos(radians) - dy*sin(radians),
                    dy: dx*sin(radians) + dy*cos(radians))
}

/// The crooked-ball tripwire's pure half: does this frame's motion need explaining?
///
/// The play test keeps seeing the ball change direction mid-scene with no brick, no wall
/// and no power-up anywhere near it, and it started only a few builds ago - a regression
/// to trace, not a behaviour to tune (§12.0). Every legitimate velocity writer is known,
/// so the instrument is a frame-to-frame comparison: the scene records each writer as it
/// fires, and a heading that bends - or a position that jumps - on a frame with no writer
/// recorded is the bug showing itself. This struct is only the comparison; the recording,
/// the excuses and the logging live in `GameScene`, because they read scene state.
///
/// DEBUG builds only at the scene end - but the arithmetic lives here unconditionally,
/// because pure logic gets tested and the wrap-around at ±180° is exactly the kind of
/// thing a test catches and an eyeball does not.
struct CrookedBallTripwire {

    /// A frame that needs explaining: the heading bent, the position jumped, or both.
    struct Trip {
        var bendDegrees: Double?
        var jumpDistance: CGFloat?
    }

    /// Half a degree, per the §12.0 design: small enough to catch the sightings, large
    /// enough that floating-point drift in the speed renormalisation never fires it.
    static let bendThresholdDegrees: Double = 0.5

    private var last: (position: CGPoint, headingDegrees: Double, speed: CGFloat)?

    /// Forget the last frame. Called whenever the ball is not in free flight - on the
    /// paddle, held, aim-frozen, dead - so the first flying frame only records.
    mutating func reset() {
        last = nil
    }

    /// Records this frame and reports whether it needs explaining.
    mutating func recordFrame(position: CGPoint, velocity: CGVector) -> Trip? {
        let speed = hypot(velocity.dx, velocity.dy)
        let heading = atan2(Double(velocity.dy), Double(velocity.dx))*180/Double.pi
        defer { last = (position, heading, speed) }
        guard let last else { return nil }

        var trip = Trip()
        let bend = CrookedBallTripwire.bendDegrees(from: last.headingDegrees, to: heading)
        if bend > CrookedBallTripwire.bendThresholdDegrees {
            trip.bendDegrees = bend
        }

        let travelled = hypot(position.x - last.position.x, position.y - last.position.y)
        let expected = max(last.speed, speed)/60
        if travelled > max(expected*3, 12) {
            trip.jumpDistance = travelled
        }
        // The most a frame of flight can cover is a frame of speed - measured generously,
        // because frame rates vary and a false alarm teaches the reader to ignore the
        // real one. A teleport (wrap, portal, handover) is far past any of it

        return trip.bendDegrees != nil || trip.jumpDistance != nil ? trip : nil
    }

    /// The smaller way round the circle: 179° to -179° is a 2° bend, not 358°.
    static func bendDegrees(from a: Double, to b: Double) -> Double {
        let raw = abs(b - a).truncatingRemainder(dividingBy: 360)
        return min(raw, 360 - raw)
    }
}
