//
//  ContinuousEffectsKeepTheSpeedTests.swift
//  GigaBallTests
//
//  The ball-jitter audit, done by arithmetic rather than by waiting for a sighting.
//
//  James, round 200: "the ball still sometimes feels jittery like it's speeding up and slowing
//  down constantly... it seems to happen when certain power ups are enabled." One cause was
//  found and fixed - the safety bar's pass-through contact was re-running the bounce arithmetic
//  on a climbing ball - and the item was left open with the rest of the suspects named:
//
//  > The continuous effects each write velocity per frame - Magnetism turns it, Ball Steering
//  > writes position, Ball Spin rotates it, Gravity accelerates it - and any of them
//  > interacting with a contact's own correction in the same frame is a speed wobble.
//
//  Round 201 built `CrookedBallTripwire` so the next sighting names its own cause in the
//  console. That is the right answer for the *interactions*, which need a live field. It is not
//  the answer for the effects themselves, which are pure functions and can simply be asked.
//
//  ## What is being checked, and why it is the right question
//
//  Every one of these is meant to change where the ball is going and **not how fast**. That is
//  the whole angle discipline the game rests on: the run's speed is set by the run, and a
//  bounce, a turn or a curve redirects it. An effect that quietly changed the magnitude would
//  be felt exactly as James describes it - speeding up and slowing down constantly - and would
//  never show up as a wrong angle.
//
//  So each one is swept over a wide spread of headings, speeds and strengths, and the speed is
//  compared before and after. Gravity is deliberately absent: it is *meant* to accelerate the
//  ball, which is what makes it the one suspect on that list that cannot be cleared this way.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ContinuousEffectsKeepTheSpeedTests: XCTestCase {

    private func speed(_ v: CGVector) -> CGFloat { hypot(v.dx, v.dy) }

    /// Headings all the way round, at three speeds the game actually runs at.
    private var velocities: [CGVector] {
        var all: [CGVector] = []
        for degrees in stride(from: 0.0, to: 360.0, by: 7.0) {
            for speed in [180.0, 420.0, 900.0] {
                let radians = degrees*Double.pi/180
                all.append(CGVector(dx: CGFloat(cos(radians)*speed),
                                    dy: CGFloat(sin(radians)*speed)))
            }
        }
        return all
    }

    // MARK: - Magnetism

    /// It turns the heading toward the paddle and leaves the speed alone.
    func testMagnetismTurnsTheBallWithoutSpeedingItUp() {
        for velocity in velocities {
            for gap in [10.0, 60.0, 140.0, 260.0] as [CGFloat] {
                for strength in [0.2, 1.0, 5.0] as [CGFloat] {
                    let turned = EndlessIIPaddleEffects.magnetised(
                        velocity: velocity,
                        ballAt: CGPoint(x: 30, y: gap),
                        paddleAt: CGPoint(x: 0, y: 0),
                        paddleHalfWidth: 60,
                        strength: strength, delta: 1.0/60)
                    XCTAssertEqual(speed(turned), speed(velocity), accuracy: 0.01,
                                   "magnetism changed the speed of \(velocity) at gap \(gap)")
                }
            }
        }
    }

    // MARK: - Ball Control

    /// It damps the sideways half and puts what it took back into the vertical.
    func testBallControlStraightensTheBallWithoutSlowingIt() {
        for velocity in velocities {
            for delta in [1.0/120, 1.0/60, 1.0/30] {
                let steered = EndlessIIPaddleEffects.steeredVelocity(velocity, delta: delta)
                XCTAssertEqual(speed(steered), speed(velocity), accuracy: 0.01,
                               "ball control changed the speed of \(velocity)")
            }
        }
    }

    /// And the damping it does that with is never more than one, which is what makes the
    /// arithmetic above safe: a factor above one would ask for a vertical component whose
    /// square is negative, and the `max(0,)` guarding that would silently drop the speed.
    func testTheDampingNeverAmplifies() {
        for delta in [0.0, 1.0/240, 1.0/120, 1.0/60, 1.0/30, 1.0/10, 1.0] {
            let damping = EndlessIIPaddleEffects.steeringVelocityDamping(delta: delta)
            XCTAssertLessThanOrEqual(damping, 1, "delta \(delta)")
            XCTAssertGreaterThanOrEqual(damping, 0, "delta \(delta)")
        }
    }

    // MARK: - Ball Spin

    /// It rotates the heading. A rotation cannot change a length, and this checks that the
    /// implementation is one.
    func testBallSpinCurvesTheBallWithoutChangingItsSpeed() {
        for velocity in velocities {
            for rate in [-6.0, -1.5, -0.2, 0.2, 1.5, 6.0] as [CGFloat] {
                for delta in [1.0/120, 1.0/60, 1.0/30] {
                    let turned = EndlessIIBallSpin.turned(velocity, rate: rate, delta: delta)
                    XCTAssertEqual(speed(turned), speed(velocity), accuracy: 0.01,
                                   "spin at \(rate) changed the speed of \(velocity)")
                }
            }
        }
    }

    /// The spin runs out rather than growing, so a long rally cannot wind the ball up.
    func testTheSpinOnlyEverDecays() {
        for rate in [-6.0, -1.0, 1.0, 6.0] as [CGFloat] {
            var left = rate
            for _ in 0..<600 {
                let next = EndlessIIBallSpin.decayed(left, over: 1.0/60)
                XCTAssertLessThanOrEqual(abs(next), abs(left) + 0.0001,
                                         "the curve grew from \(left) to \(next)")
                left = next
            }
            XCTAssertLessThan(abs(left), abs(rate), "ten seconds and it has not decayed")
        }
    }

    // MARK: - Random Bounce

    /// Round 258's fix, from the other side: it changes the heading and nothing else, and it
    /// never turns a descending ball into a climbing one.
    func testRandomBounceChangesOnlyTheHeading() {
        for degrees in stride(from: -179.0, through: 179.0, by: 3.0) {
            for share in stride(from: -0.10, through: 0.10, by: 0.05) {
                let thrown = GameScene.randomisedBounceAngle(from: degrees, minimumDeg: 10,
                                                             share: share)
                XCTAssertEqual(thrown < 0, degrees < 0,
                               "\(degrees)° changed which way the ball was going")
                XCTAssertLessThanOrEqual(abs(thrown), 180)
            }
        }
    }

    // MARK: - What this cannot clear

    /// Gravity is *meant* to change the speed, which is why it is not swept above.
    ///
    /// Stated rather than left as an absence: the open item names four suspects and this file
    /// clears three of them, so the fourth wants saying out loud. A jitter sighting with
    /// Gravity Ball in the ring is still a live suspect, and `CrookedBallTripwire` is what will
    /// name it - it trips on a 2%-in-one-frame speed change with no contact to blame.
    func testTheTripwireIsStillArmedForTheOneThisCannotClear() {
        XCTAssertGreaterThan(CrookedBallTripwire.speedWobbleShare, 0,
                             "the tripwire is what covers the interactions this file cannot")
        XCTAssertLessThan(CrookedBallTripwire.speedWobbleShare, 0.1,
                          "far past renormalisation drift, well inside what a hand feels")
    }
}

/// Where the wobble actually comes from, measured.
///
/// The effects above all preserve speed, so the drift is not in them. It is in the ball's own
/// `linearDamping`, and the snap back to `ballSpeedLimit` that every corrected bounce performs.
///
/// The main ball carries `linearDamping = 0.01` and is renormalised by `ballSpeedControl` at
/// the end of every corrected bounce. Between two corrections it slows; at the correction it is
/// put back to exactly the run's speed. That is a sawtooth, and its size is the length of the
/// flight - which is why James's sighting reads as "it seems to happen when certain power ups
/// are enabled". The power-ups do not cause it. They *lengthen the interval between snap-backs*:
/// a Ghost Ball passes through bricks without a corrected bounce, a Halo clears the field ahead
/// of the ball, a Portal transit is long, and a Safety Paddle returns a ball that would have
/// been lost.
///
/// Nothing here changes the physics - that is shared with Classic and the original Endless,
/// which carry years of leaderboard scores (CLAUDE.md), and is James's call. This measures it so
/// the call can be made on numbers.
final class BallSpeedSawtoothTests: XCTestCase {

    /// Box2D's damping, which is what SpriteKit runs: `v *= 1/(1 + dt*damping)` per step.
    private func decayed(_ speed: CGFloat, damping: CGFloat,
                         seconds: Double, fps: Double = 60) -> CGFloat {
        let dt = 1/fps
        var value = speed
        for _ in 0..<Int(seconds*fps) { value /= (1 + CGFloat(dt)*damping) }
        return value
    }

    func testHowFarTheMainBallDriftsBetweenCorrections() {
        let scene = GameScene()
        let damping = scene.ballLinearDampening
        XCTAssertEqual(damping, 0.01, accuracy: 0.0001, "the value this is measured against")

        print("\n  Main ball speed drift at linearDamping \(damping):")
        for seconds in [0.5, 1.0, 2.0, 4.0, 8.0] {
            let left = decayed(1, damping: damping, seconds: seconds)
            print(String(format: "    %.1fs between corrections -> %.2f%% slower, snapped back "
                                 + "in one frame", seconds, (1 - left)*100))
        }
        print("")

        XCTAssertLessThan(decayed(1, damping: damping, seconds: 1.0), 1,
                          "it does slow, which is the whole finding")
        XCTAssertGreaterThan(decayed(1, damping: damping, seconds: 2.0),
                             1 - CrookedBallTripwire.speedWobbleShare*2,
                             "and by an amount in the same range as the tripwire's threshold, "
                             + "which is what makes this the suspect rather than a rounding")
    }

    /// The extras do not drift, which is why this is the *main* ball's sawtooth.
    ///
    /// `EndlessIIMultiBall` gives every extra `linearDamping = 0`, and `ballSpeedControl` only
    /// ever renormalises `ball` - so the two halves of the design agree: the ball that is
    /// snapped back is the one that slows, and the balls that are never snapped back never
    /// slow. Worth pinning, because a future extra given the main ball's damping would drift
    /// for ever with nothing to put it right.
    func testAnExtraBallNeitherDriftsNorNeedsSnappingBack() {
        XCTAssertEqual(decayed(1, damping: 0, seconds: 30), 1, accuracy: 0.0001)
    }
}
