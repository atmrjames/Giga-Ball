//
//  EndlessIIFrameCostTests.swift
//  GigaBallTests
//
//  What a frame of Endless Mayhem costs, measured.
//
//  James, round 258: "Game is stuttering whilst certain power ups are enabled... Drift, Shaped
//  paddles, Trajectory line, Quicksand."
//
//  Four power-ups, and the obvious move is to read all four and pick the one that looks
//  expensive. That is how the last two Randomised Bounce rounds went wrong: a plausible cause,
//  a narrowing, and the report unchanged. So this measures instead. It builds a field the size
//  a real one reaches and times each subsystem's per-frame work against a sixtieth of a second,
//  which is the whole budget a frame has for *everything*.
//
//  It is a tripwire rather than a benchmark: the thresholds are generous, in fractions of a
//  frame, and what they catch is a subsystem that has started costing a different order of
//  magnitude. The numbers are printed either way, because the point of the round was to find
//  out where the time goes.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIFrameCostTests: XCTestCase {

    /// A sixtieth of a second, which is the frame.
    private let frame = 1.0/60.0

    /// A field of the size a run reaches: eleven columns, eleven rows, all solid.
    private func loadedField() -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.numberOfBrickColumns = 11
        scene.brickWidth = 36
        scene.brickHeight = 18
        scene.gameWidth = 396
        scene.ballSize = 14

        for row in 0..<11 {
            for column in 0..<11 {
                let brick = SKSpriteNode(color: .white, size: CGSize(width: 36, height: 18))
                brick.name = BrickCategoryName
                brick.position = CGPoint(x: -198 + 18 + 36*CGFloat(column),
                                         y: 300 - 18*CGFloat(row))
                brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
                brick.physicsBody?.isDynamic = false
                scene.addChild(brick)
            }
        }
        return scene
    }

    /// Runs `work` sixty times - one second of play - and reports the average frame's share.
    @discardableResult
    private func cost(_ name: String, of work: () -> Void) -> Double {
        work()
        // One outside the clock, so a pool being filled for the first time is not counted as
        // the steady-state cost of using it

        let started = Date.timeIntervalSinceReferenceDate
        for _ in 0..<60 { work() }
        let each = (Date.timeIntervalSinceReferenceDate - started)/60

        print(String(format: "  %-28@ %7.3f ms   %5.1f%% of a frame",
                     name as NSString, each*1000, each/frame*100))
        return each
    }

    /// Draws the fading line to a file so it can be looked at.
    ///
    /// The trajectory stopped being forty-six glowing shape nodes and became forty-six sprites
    /// wearing one soft picture (round 258), and that is a change to something a player sees.
    /// The arithmetic is unchanged - the same thickness, blur and alpha go in - but "the same
    /// numbers" is not the same claim as "it still looks right", and §13's rule is that visual
    /// work gets looked at.
    func testTheFadingLineCanBeLookedAt() throws {
        let scene = SKScene(size: CGSize(width: 420, height: 160))
        scene.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        let points = [CGPoint(x: 20, y: 40), CGPoint(x: 200, y: 130), CGPoint(x: 400, y: 30)]
        let step: CGFloat = 12
        let total = zip(points, points.dropFirst())
            .reduce(CGFloat(0)) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }

        var travelled: CGFloat = 0
        for (from, to) in zip(points, points.dropFirst()) {
            let length = hypot(to.x - from.x, to.y - from.y)
            let pieces = max(Int((length/step).rounded(.up)), 1)
            for piece in 0..<pieces {
                let a = CGFloat(piece)/CGFloat(pieces), b = CGFloat(piece + 1)/CGFloat(pieces)
                let head = CGPoint(x: from.x + (to.x - from.x)*a, y: from.y + (to.y - from.y)*a)
                let tail = CGPoint(x: from.x + (to.x - from.x)*b, y: from.y + (to.y - from.y)*b)
                let along = (travelled + length*(a + b)/2)/total
                let certainty = pow(1 - along, 1.8 - 1*0.45)

                let segment = FadingLine.segment()
                FadingLine.lay(segment, from: head, to: tail,
                               thickness: 1.5 + (1 - certainty)*2,
                               blur: (1 - certainty)*(1 - certainty)*6,
                               alpha: max(0.04, 0.5*certainty))
                scene.addChild(segment)
            }
            travelled += length
        }
        // The same path, the same step and the same three numbers `endlessIIDrawFadingTrajectory`
        // uses, so what comes out is the line the game draws rather than a demonstration of it

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene),
                                    "no renderer here, so there is nothing to look at")
        let image = UIImage(cgImage: texture.cgImage())
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fading-line.png")
        try XCTUnwrap(image.pngData()).write(to: file)
        print("\n  The fading line, drawn: \(file.path)\n")
    }

    /// How often a shaped paddle retraces its body, and what one trace costs.
    ///
    /// The third of James's four. Its per-frame *arithmetic* is nothing; what it can be is
    /// `SKPhysicsBody(texture:size:)`, which walks the picture's alpha and builds a polygon,
    /// and which the paddle calls whenever its art or its width changes. Once is fine. Once a
    /// frame is a stutter, and the guard that decides which is a comparison against a number
    /// the paddle itself writes - exactly the shape of thing that can end up chasing itself.
    func testAShapedPaddleTracesItsBodyOnceAndNotEveryFrame() {
        let scene = loadedField()
        scene.paddle.size = CGSize(width: 75, height: 12)
        scene.paddle.texture = SKTexture(imageNamed: "regularPaddle")
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.paddleHeight = 12
        scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
        scene.endlessIIPaddleSurface = .convex
        scene.endlessIIPaddleSurfaceClock.collect(10)

        scene.refreshEndlessIIPaddleShapeArt()
        // The one that puts the shape on. Everything after this is a paddle already wearing it

        var traces = 0
        for _ in 0..<60 {
            let before = scene.paddle.physicsBody
            scene.refreshEndlessIIPaddleShapeArt()
            if scene.paddle.physicsBody !== before { traces += 1 }
        }

        print(String(format: "\n  A shaped paddle retraced its body %d times in 60 frames.",
                     traces))
        print("  What one trace costs, by picture - cold, then through the cache:")
        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                     "regularPaddleWave", "regularPaddleWedgeLeft"] {
            guard UIImage(named: name) != nil else { continue }
            let texture = SKTexture(imageNamed: name)

            TracedBodyCache.empty()
            let coldStart = Date.timeIntervalSinceReferenceDate
            _ = TracedBodyCache.body(texture: texture, size: scene.paddle.size)
            let cold = Date.timeIntervalSinceReferenceDate - coldStart

            let warmStart = Date.timeIntervalSinceReferenceDate
            for _ in 0..<20 { _ = TracedBodyCache.body(texture: texture, size: scene.paddle.size) }
            let warm = (Date.timeIntervalSinceReferenceDate - warmStart)/20

            print(String(format: "    %-24@ %6.3f ms cold  ->  %6.3f ms cached",
                         name as NSString, cold*1000, warm*1000))
            XCTAssertLessThan(warm, frame/10,
                              "\(name) is still costing a tenth of a frame after it has been "
                              + "traced once, so the cache is missing")
        }
        print("")

        XCTAssertEqual(traces, 0,
                       "a paddle whose shape and width have not changed must not retrace its "
                       + "body: the trace walks the picture's alpha, and doing it every frame "
                       + "is a hitch the player feels as the paddle stuttering")
    }

    /// The four James named, timed side by side.
    func testWhatAFrameOfMayhemSpendsItsTimeOn() {
        let scene = loadedField()
        print("\nEndless Mayhem, 121 bricks, cost per frame:")

        scene.endlessIIDriftClock.collect(10)
        scene.endlessIIDriftDirection = 1
        let before = scene.children.first { $0.name == BrickCategoryName }?.position.x ?? 0
        let drift = cost("Drift") {
            scene.endlessIIDriftMoved = 0
            scene.tickEndlessIIDrift(self.frame)
        }
        XCTAssertNotEqual(scene.children.first { $0.name == BrickCategoryName }?.position.x ?? 0,
                          before, "the drift moved nothing, so this timed its guards")

        let faces = cost("Shaped brick faces") { scene.refreshEndlessIIShapedFaces() }
        let rounded = cost("Rounded brick faces") { scene.refreshEndlessIIRoundedFaces() }

        scene.endlessIIQuicksandClock.collect(10)
        let shift = cost("Quicksand field shift") {
            scene.endlessIIFieldShift = 0
            scene.tickEndlessIIFieldShift(self.frame)
        }
        // Reset each pass, or the field arrives where it is going and the tick starts
        // returning at its first guard - which would time the guard rather than the work

        scene.endlessIITrajectoryRemaining = 5
        scene.endlessIITrajectoryLevel = 1
        if scene.ball.parent == nil { scene.addChild(scene.ball) }
        scene.ball.size = CGSize(width: 14, height: 14)
        scene.ball.position = CGPoint(x: 0, y: -200)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        scene.ball.physicsBody?.velocity = CGVector(dx: 120, dy: 320)
        let trajectory = cost("Ball Trajectory") { scene.tickEndlessIIVision(0) }

        XCTAssertGreaterThan(scene.endlessIITrajectoryLines.count, 1,
                             "the line drew nothing, so this timed a guard clause and not "
                             + "the work - which is how a measurement lies")

        let drawn = scene.endlessIITrajectoryLines.filter { $0.parent != nil }
        let textures = Set(drawn.compactMap { $0.texture.map(ObjectIdentifier.init) })
        print(String(format: "\n  Ball Trajectory lays %d segments a frame, per ball,",
                     drawn.count))
        print(String(format: "  across %d texture(s) - so one batch rather than %d draws.",
                     textures.count, drawn.count))
        print("  They were glowing SKShapeNodes until round 258, each re-tessellated and")
        print("  rendered through an offscreen pass, on the render thread where nothing")
        print("  above could see it.")
        print("")

        XCTAssertLessThanOrEqual(textures.count, 1,
                                 "the segments have to share one texture or SpriteKit cannot "
                                 + "batch them, which is most of what this bought")

        for (name, each) in [("Drift", drift), ("Shaped brick faces", faces),
                             ("Rounded brick faces", rounded),
                             ("Quicksand field shift", shift), ("Ball Trajectory", trajectory)] {
            XCTAssertLessThan(each, frame/2,
                              "\(name) alone is taking half a frame, and a frame has a whole "
                              + "game to fit in it")
        }
    }
}
