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
    ///   - absorbers: bricks the path **ends at** rather than bounces off, whatever the bounce
    ///     budget says. Portals (play-test round 128): the ball does not come back off one, it
    ///     goes in - and where it comes out is chosen at the moment of entry, so a line that
    ///     bounced off a portal would draw a wall and a line that carried on through would
    ///     draw a hole. Ending at the mouth is the only honest one of the three.
    static func predict(from start: CGPoint, velocity: CGVector, radius: CGFloat,
                        bounds: Bounds, bricks: [CGRect],
                        maximumLength: CGFloat = 0,
                        brickBounces: Int = 0,
                        absorbers: [CGRect] = []) -> Prediction {
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
                if absorbers.contains(where: { $0 == brick.rect }) {
                    stoppedAtBrick = true
                    break
                }
                // Swallowed rather than reflected - see `absorbers`
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
                                   bricks: [CGRect])
    -> (distance: CGFloat, vertical: Bool, rect: CGRect)? {
        var nearest: (distance: CGFloat, vertical: Bool, rect: CGRect)?
        for brick in bricks {
            let grown = brick.insetBy(dx: -radius, dy: -radius)
            guard grown.contains(point) == false else { continue }
            guard let hit = entry(into: grown, from: point, direction: direction) else { continue }
            if nearest == nil || hit.distance < nearest!.distance {
                nearest = (hit.distance, hit.vertical, brick)
            }
        }
        return nearest
        // The rectangle comes back with the hit so the caller can ask whether *that* brick is
        // one the path ends at rather than bounces off - see `absorbers`
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

    /// How near each other those repeats have to be.
    ///
    /// **This is the round-190 fix, and it is why James kept seeing the ball turn.** The count
    /// used to be taken across the whole 24-bounce history, which is far too generous in
    /// Endless Mayhem: the field is dense and descending, the ball rattles among the bottom
    /// rows, and a perfectly ordinary rally revisits the same half-brick cell at a similar
    /// heading three times inside two dozen bounces without ever being stuck. The loop-breaker
    /// then fired on a rally and kicked the ball 5 to 8 degrees - "still seeing the ball change
    /// angle in mid air, around the low brick level line, by about 5deg".
    ///
    /// A genuine loop repeats *immediately*: the ball is retracing one short cycle, so its
    /// repeats are a fixed few bounces apart. Nine is the room a four-bounce cycle needs to
    /// show the same bounce three times (at 1, 5 and 9) and no more than that - a cell a rally
    /// revisits every eighth bounce can only ever reach two inside it. The longer history is
    /// still kept, because it costs nothing and a future rule may want it.
    static let windowThatProvesALoop = 9

    /// How far the heading is nudged the first time a loop is proved, in degrees.
    ///
    /// One degree, on James's own suggestion - "perhaps we should also change the 5deg
    /// adjustment to a 1deg adjustment to make it less of an issue when it does happen like
    /// this". A single degree is invisible to a player and is still enough to break a loop
    /// that is balanced on a knife edge, which most are.
    static let firstNudgeDegrees: Double = 1

    /// The most it will ever nudge by, in degrees.
    static let hardestNudgeDegrees: Double = 8

    /// How many times in a row this loop has been proved without the ball getting free.
    private var provings = 0

    /// Records a bounce, and reports the nudge that should break it - nil when there is no
    /// loop to break.
    ///
    /// **The nudge escalates**, which is what lets the first one be as small as a degree. A
    /// false positive on a rally costs a degree nobody sees; a loop that really is a loop
    /// proves itself again on the next cycle and gets twice as much, until it comes free. The
    /// old flat 5-to-8 was sized for the worst case and charged it to every case.
    ///
    /// Proving one clears the history, so the nudge gets a chance to work before the same
    /// loop can be proved again.
    mutating func recordBounce(x: CGFloat, y: CGFloat, headingDegrees: Double,
                               cell: CGFloat) -> Double? {
        let signature = BallLoopDetector.signature(x: x, y: y,
                                                   headingDegrees: headingDegrees, cell: cell)
        signatures.append(signature)
        if signatures.count > BallLoopDetector.capacity { signatures.removeFirst() }

        let window = signatures.suffix(BallLoopDetector.windowThatProvesALoop)
        guard window.filter({ $0 == signature }).count
                >= BallLoopDetector.repeatsThatProveALoop else { return nil }
        signatures.removeAll()
        provings += 1
        return min(BallLoopDetector.firstNudgeDegrees*pow(2, Double(provings - 1)),
                   BallLoopDetector.hardestNudgeDegrees)
    }

    /// The player touched the ball: whatever was repeating, they can change it now.
    mutating func playerIntervened() {
        signatures.removeAll()
        provings = 0
        // The escalation resets too. A paddle hit is a new rally, and starting it at eight
        // degrees because a loop was broken two rallies ago is the old bug with extra steps
    }

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

    /// A frame that needs explaining: the heading bent, the position jumped, the speed
    /// wobbled, or any mix of the three.
    struct Trip {
        var bendDegrees: Double?
        var jumpDistance: CGFloat?
        var speedDelta: CGFloat?
    }

    /// How much the speed may drift between frames before it needs explaining, as a share
    /// of the speed itself.
    ///
    /// Round 201's addition for the jitter hunt (round 200: "the ball still sometimes feels
    /// jittery like it's speeding up and slowing down constantly... it seems to happen when
    /// certain power ups are enabled"). The whole game protects the ball's speed as a single
    /// value, so between contacts it should not move at all - two percent in one frame is
    /// far past renormalisation drift and well inside what a hand feels as a stutter.
    static let speedWobbleShare: CGFloat = 0.02

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

        let wobble = abs(speed - last.speed)
        if last.speed > 0, wobble > last.speed*CrookedBallTripwire.speedWobbleShare {
            trip.speedDelta = wobble
        }
        // The jitter James described is exactly this: speed changing with no contact to
        // blame. The bend check cannot see it - a straight-line ball can still surge

        return trip.bendDegrees != nil || trip.jumpDistance != nil
            || trip.speedDelta != nil ? trip : nil
    }

    /// The smaller way round the circle: 179° to -179° is a 2° bend, not 358°.
    static func bendDegrees(from a: Double, to b: Double) -> Double {
        let raw = abs(b - a).truncatingRemainder(dividingBy: 360)
        return min(raw, 360 - raw)
    }
}
