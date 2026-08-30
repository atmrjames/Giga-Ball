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

                let core = 1.5 + (1 - certainty)*3.5
                let blur = (1 - certainty)*(1 - certainty)*9

                let glowing = FadingLine.segment(glow: true)
                FadingLine.lay(glowing, from: head, to: tail, thickness: core,
                               blur: blur + core*1.6, alpha: max(0.05, 0.40*certainty))
                scene.addChild(glowing)

                let segment = FadingLine.segment()
                FadingLine.lay(segment, from: head, to: tail, thickness: core, blur: blur,
                               alpha: max(0.06, 0.55*certainty))
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

    /// Draws every shaped brick face to a file so the new art can be looked at.
    ///
    /// Round 262 opened the drawn set from two shapes to five and gave the Wedge four
    /// orientations of its own, and the mapping between "which way is this brick facing" and
    /// "which of James's four pictures" is the sort of thing that is checked by arithmetic and
    /// believed by eye. `ShapedBrickArtOrientationTests` does the arithmetic against the alpha
    /// silhouettes; this is the eye.
    func testEveryShapedBrickFaceCanBeLookedAt() throws {
        let cell = CGSize(width: 56, height: 28)
        let scene = SKScene(size: CGSize(width: cell.width*6 + 40,
                                         height: cell.height*8 + 60))
        scene.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        let game = GameScene(size: CGSize(width: 402, height: 874))
        game.gameMode = .endlessII
        game.brickWidth = cell.width
        game.brickHeight = cell.height

        let types = ["BrickNormal", "BrickMultiHit1", "BrickMultiHit4",
                     "BrickInvisible", "BrickIndestructible1", "BrickIndestructible2"]
        let orientations: [(String, Bool, Bool)] = [("", false, false), ("f", false, true),
                                                    ("m", true, false), ("mf", true, true)]

        var row = 0
        for shape in [GameScene.ShapedBrickArt.wedge, .convex, .concave, .diamond, .rounded] {
            for (_, mirrored, flipped) in orientations {
                guard shape == .wedge || mirrored == false else { continue }
                for (column, type) in types.enumerated() {
                    let name = type + shape.rawValue
                        + GameScene.orientationSuffix(shape, mirrored: mirrored,
                                                      flipped: flipped)
                    let picture = UIImage(named: name) ?? UIImage(named: type + shape.rawValue)
                    guard let picture else { continue }

                    let sprite = SKSpriteNode(texture: SKTexture(image: picture), size: cell)
                    sprite.position = CGPoint(x: 24 + cell.width*(CGFloat(column) + 0.5),
                                              y: scene.size.height - 30
                                                  - cell.height*(CGFloat(row) + 0.5))
                    scene.addChild(sprite)
                }
                row += 1
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("shaped-bricks.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Shaped brick faces, drawn: \(file.path)\n")
    }

    /// Draws a spinning brick through a half turn so the cross-fade can be looked at.
    ///
    /// James, round 266, asking for it: "so it looks like the light on the brick is changing as
    /// it spins". Whether it does is not something the arithmetic can answer.
    func testTheSpinningCrossFadeCanBeLookedAt() throws {
        let cell = CGSize(width: 112, height: 56)
        let steps = 9
        let scene = SKScene(size: CGSize(width: cell.width*CGFloat(steps) + 40,
                                         height: cell.height*2 + 60))
        scene.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (row, texture) in ["BrickIndestructible1", "BrickIndestructible2"].enumerated() {
            for step in 0..<steps {
                let game = GameScene(size: CGSize(width: 402, height: 874))
                game.gameMode = .endlessII
                game.brickWidth = cell.width
                game.brickHeight = cell.height
                let own = texture == "BrickIndestructible2"
                    ? game.brickIndestructible2Texture : game.brickIndestructible1Texture
                let brick = SKSpriteNode(texture: own, size: cell)
                brick.name = BrickCategoryName
                brick.endlessIIFaceMirrored = false
                brick.endlessIIFaceFlipped = false
                game.addChild(brick)
                game.makeFace(.wedge, on: brick)
                brick.zRotation = .pi*CGFloat(step)/CGFloat(steps - 1)
                game.refreshEndlessIIShapedFaces()

                guard let shape = brick.childNode(withName: GameScene.brickFaceName)
                        as? SKShapeNode else { continue }
                let holder = SKNode()
                holder.position = CGPoint(
                    x: 20 + cell.width*(CGFloat(step) + 0.5),
                    y: scene.size.height - 30 - cell.height*(CGFloat(row) + 0.5))
                holder.zRotation = brick.zRotation
                scene.addChild(holder)

                for child in shape.children.compactMap({ $0 as? SKSpriteNode }) {
                    let copy = SKSpriteNode(texture: child.texture, size: child.size)
                    copy.alpha = child.alpha
                    copy.xScale = child.xScale
                    copy.yScale = child.yScale
                    copy.zRotation = child.zRotation
                    copy.position = child.position
                    copy.zPosition = child.zPosition
                    holder.addChild(copy)
                    // Every transform the sprite carries, not the three I happened to think
                    // of - the first version copied all but `zRotation`, which is precisely
                    // the one the partner uses, so the render could not show the fix it was
                    // drawn to check
                }
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spinning-crossfade.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Spinning cross-fade, drawn: \(file.path)\n")
    }

    /// Draws the daily's result container so the free-play line can be looked at.
    ///
    /// §8's posted-score container gained its last clause in round 269 - "free play attempts
    /// played after the post get listed in the same container" - and a second line inside a
    /// label that had one is exactly the kind of change that reads fine as a string and wraps
    /// badly on screen. It read fine as a string and printed 8100m over 8100m on the card.
    ///
    /// **One card, not a row of them.** The first version laid three states out side by side
    /// and they all drew at the same place: `DailyCardView` lays itself out with constraints,
    /// so the frame a harness hands it is not where it goes. One card in its own host is the
    /// version that can be read.
    func testTheDailyResultContainerCanBeLookedAt() throws {
        let posted = DailyChallengeRecord(dateKey: "2026-03-02", firstAttemptScore: 12480,
                                          posted: true, bestPracticeScore: 15900,
                                          attemptCount: 4)

        let host = UIView(frame: CGRect(x: 0, y: 0, width: 380, height: 460))
        host.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        let card = DailyCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(card)
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 10),
            card.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -10),
            card.topAnchor.constraint(equalTo: host.topAnchor, constant: 10),
            card.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -10),
        ])
        card.show(key: posted.dateKey, isToday: true, record: posted, standing: nil)
        host.layoutIfNeeded()

        let image = UIGraphicsImageRenderer(bounds: host.bounds).image { _ in
            host.drawHierarchy(in: host.bounds, afterScreenUpdates: true)
        }
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("daily-result-card.png")
        try XCTUnwrap(image.pngData()).write(to: file)
        print("\n  Daily result container, drawn: \(file.path)\n")
    }

    /// Draws each shaped paddle with its overlays, placed by the scene's own code, so the
    /// alignment can be looked at.
    ///
    /// James, round 259: "shaped paddle laser and sticky graphics are sized so that the bottom
    /// of the graphic aligns with the bottom of the paddle graphic to ensure they line up
    /// properly with the paddle. Some of the graphics are currently not aligned properly."
    ///
    /// **Through `refreshEndlessIIPaddleShapeArt` and `positionPaddleOverlays`**, not through a
    /// re-implementation of them. The first version of this drew the three pictures against a
    /// shared bottom line by hand and they all looked right - which proved only that the *art*
    /// shares a bottom line, and missed the bug entirely, because the bug was in where the
    /// scene puts them.
    func testTheShapedPaddleOverlaysCanBeLookedAt() throws {
        let shapes: [PaddleBounce.Surface?] = [nil, .convex, .concave, .wavy,
                                               .wedgeLeft, .wedgeRight]
        let paddleWidth: CGFloat = 150, paddleHeight: CGFloat = 24
        let column = paddleWidth + 30, row: CGFloat = 100

        let scene = SKScene(size: CGSize(width: column*CGFloat(shapes.count) + 20,
                                         height: row*2 + 20))
        scene.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (index, surface) in shapes.enumerated() {
            for (line, wearing) in ["Lasers", "Sticky"].enumerated() {
                let game = GameScene(size: CGSize(width: 402, height: 874))
                game.gameMode = .endlessII
                game.totalStatsArray = [TotalStats()]
                game.ballSize = paddleHeight
                game.paddleHeight = paddleHeight
                game.paddleTexture = SKTexture(imageNamed: "regularPaddle")
                game.addChild(game.paddle)
                game.paddle.texture = game.paddleTexture
                game.paddle.size = CGSize(width: paddleWidth, height: paddleHeight)
                game.paddle.position = .zero
                game.addChild(game.paddleLaser)
                game.addChild(game.paddleSticky)
                game.paddleLaser.anchorPoint = CGPoint(x: 0.5, y: 0)
                game.paddleSticky.anchorPoint = CGPoint(x: 0.5, y: 0)

                if let surface { game.endlessIICollectPaddleSurface(surface) }
                game.refreshEndlessIIPaddleShapeArt()

                let worn = wearing == "Lasers" ? game.paddleLaser : game.paddleSticky
                let bottom = scene.size.height - row*(CGFloat(line) + 1)
                let x = 10 + column*(CGFloat(index) + 0.5)
                let lift = CGPoint(x: x - game.paddle.position.x,
                                   y: bottom - (game.paddle.position.y
                                                - game.paddle.size.height/2))

                for node in [game.paddle, worn] {
                    guard let texture = node.texture else { continue }
                    let copy = SKSpriteNode(texture: texture, size: node.size)
                    copy.anchorPoint = node.anchorPoint
                    copy.position = CGPoint(x: node.position.x + lift.x,
                                            y: node.position.y + lift.y)
                    copy.alpha = node === worn ? 0.75 : 1
                    scene.addChild(copy)
                }

                let mark = SKSpriteNode(color: .red, size: CGSize(width: column, height: 1))
                mark.position = CGPoint(x: x, y: bottom)
                scene.addChild(mark)
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("shaped-paddle-overlays.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Shaped paddle overlays, drawn: \(file.path)\n")
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
        XCTAssertEqual(drawn.count % 2, 0,
                       "the segments come in pairs - a glow and a core - so an odd count means "
                       + "one of a pair has been trimmed away from its partner")
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
