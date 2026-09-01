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
import CoreImage
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

    /// Draws the Square bricks, plain and Rounded, in both themes, so the new art can be
    /// looked at where the scene puts it.
    ///
    /// **Reparented, not copied.** Round 266's copy harness rebuilt each node by hand and
    /// forgot `zRotation`, so it re-rendered the broken picture unchanged and said nothing.
    /// Moving the real node into the display scene brings its whole subtree - the overlay, the
    /// rounded outline, the art inside it - with every transform the scene actually gave it.
    ///
    /// Two rows per theme: the brick as built, and the same brick with its overlay taken off,
    /// which is what a Square brick looked like until this delivery - one oblong texture pulled
    /// to twice its height.
    func testTheSquareBricksCanBeLookedAt() throws {
        let cell = CGSize(width: 56, height: 28)
        let column: CGFloat = 90, row: CGFloat = 90
        let labels = ["Normal", "MultiHit1", "MultiHit4", "Indestr.1", "Invisible"]

        let display = SKScene(size: CGSize(width: column*CGFloat(labels.count) + 20,
                                           height: row*7 + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (line, mode) in [(0, "classic plain"), (1, "classic rounded"),
                             (2, "classic diamond"), (3, "retro plain"),
                             (4, "retro rounded"), (5, "retro diamond"),
                             (6, "classic oblong rounded")] {
            let retro = mode.hasPrefix("retro")
            let rounded = mode.hasSuffix("rounded")

            for (index, _) in labels.enumerated() {
                let game = GameScene(size: CGSize(width: 402, height: 874))
                game.gameMode = .endlessII
                game.brickSetting = retro ? 1 : 0
                game.brickWidth = cell.width
                game.brickHeight = cell.height
                game.gameWidth = 402
                if retro {
                    game.brickNormalTexture = game.retroBrickNormalTexture
                    game.brickInvisibleTexture = game.retroBrickInvisibleTexture
                    game.brickMultiHit1Texture = game.retroBrickMultiHit1Texture
                    game.brickMultiHit4Texture = game.retroBrickMultiHit4Texture
                }
                let types = [game.brickNormalTexture, game.brickMultiHit1Texture,
                             game.brickMultiHit4Texture, game.brickIndestructible1Texture,
                             game.brickInvisibleTexture]

                let brick: SKSpriteNode
                if mode.contains("oblong") {
                    brick = SKSpriteNode(texture: game.brickNormalTexture, size: cell)
                    game.addChild(brick)
                    // An ordinary rounded brick beside them, so anything showing through the
                    // Square ones can be told from what rounded bricks have always done
                } else {
                    brick = game.endlessIIMakeSquare(column: 0, rowY: 0)
                }
                brick.texture = types[index]
                brick.isHidden = false
                brick.colorBlendFactor = 0
                // Uncoloured, so what shows is the picture rather than the level's tint
                game.refreshEndlessIIBrickArt(brick)
                if rounded || mode.contains("oblong") { game.makeRounded(brick) }
                if mode.contains("diamond") { game.applyEndlessIIStyle(.diamond, to: brick) }

                brick.removeFromParent()
                brick.position = CGPoint(x: 10 + column*(CGFloat(index) + 0.5),
                                         y: display.size.height - row*(CGFloat(line) + 0.5))
                display.addChild(brick)
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("square-bricks.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Square bricks, drawn: \(file.path)")
        print("  rows: classic plain/rounded/diamond, retro plain/rounded/diamond, "
              + "then an ordinary rounded brick")
        print("  columns: \(labels.joined(separator: ", "))\n")
    }

    /// Draws the on-hit marks - the four directional overlays at both proportions, the Fixed
    /// brick before and after it locks, and the power-up brick wearing its badge.
    ///
    /// James, round 271, is explicit about what each should read as, and none of it is a thing
    /// a test can check: "I think this better denotes it stopping", "the open side... has been
    /// left open/transparent so the brick below can be seen".
    func testTheOnHitMarksCanBeLookedAt() throws {
        let cell = CGSize(width: 56, height: 28)
        let column: CGFloat = 140, row: CGFloat = 80
        // Wide enough for a Big brick, which is two cells across - at the old spacing the four
        // of them ran into one another and the row said nothing

        let display = SKScene(size: CGSize(width: column*5 + 20, height: row*5 + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        func game() -> GameScene {
            let scene = GameScene(size: CGSize(width: 402, height: 874))
            scene.gameMode = .endlessII
            scene.brickWidth = cell.width
            scene.brickHeight = cell.height
            scene.gameWidth = 402
            scene.totalStatsArray = [TotalStats()]
            return scene
        }
        func place(_ brick: SKSpriteNode, _ x: Int, _ line: Int) {
            brick.removeFromParent()
            brick.position = CGPoint(x: 10 + column*(CGFloat(x) + 0.5),
                                     y: display.size.height - row*(CGFloat(line) + 0.5))
            display.addChild(brick)
        }

        for (index, side) in EndlessIISide.allCases.enumerated() {
            for (line, square) in [(0, false), (1, true)] {
                let scene = game()
                let brick: SKSpriteNode
                if square {
                    brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
                    brick.texture = scene.brickNormalTexture
                    brick.isHidden = false
                    scene.refreshEndlessIIBrickArt(brick)
                } else {
                    brick = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
                    scene.addChild(brick)
                }
                brick.endlessIIVulnerableSide = side
                scene.makeDirectional(brick)
                scene.refreshEndlessIIBrickArt(brick)
                // Through `makeDirectional` rather than by setting the role and the tint by
                // hand: since round 284 the tint is *conditional* on there being no panel, and
                // a harness that painted it anyway would be drawing the one thing the change
                // was about
                // Tinted as `makeDirectional` tints it, because what shows through the open
                // side is the brick underneath and the whole question is whether that reads
                place(brick, index, line)
            }
        }

        for (index, locked) in [(0, false), (1, true)] {
            let scene = game()
            let brick = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
            scene.addChild(brick)
            scene.makeFixed(brick)
            if locked {
                brick.endlessIIIsAnchored = true
                scene.endlessIIDrawFixedPin(on: brick)
            }
            place(brick, index, 2)
        }

        for (index, side) in EndlessIISide.allCases.enumerated() {
            let scene = game()
            let brick = scene.endlessIIMakeBig(leftColumn: 0, rowY: 0)
            brick.endlessIIVulnerableSide = side
            scene.makeDirectional(brick)
            scene.refreshEndlessIIBrickArt(brick)
            place(brick, index, 3)
        }

        for (index, powerUp) in [0, 3].enumerated() {
            let scene = game()
            let brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
            brick.texture = scene.brickIndestructible2Texture
            brick.isHidden = false
            brick.endlessIIPowerUpIndex = powerUp
            let plan = EndlessIITallBrick(cell: cell)
            scene.hidePowerUpBrickSpriteForTesting(brick, plan: plan)
            scene.refreshEndlessIIBrickArt(brick)
            // Built by hand rather than through `endlessIIMakePowerUpBrick`, which rolls
            // against a schedule an unstarted run does not have and answers nil

            let icon = SKSpriteNode(texture: scene.endlessIIPowerUpTexture(powerUp))
            icon.size = plan.size
            icon.position = CGPoint(x: 0, y: -scene.brickHeight/2)
            icon.zPosition = 1
            brick.addChild(icon)
            place(brick, 3 + index, 2)
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("on-hit-marks.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  On-hit marks, drawn: \(file.path)")
        print("  row 1: directional top, bottom, left, right (2:1)")
        print("  row 2: the same, square")
        print("  row 3: Fixed loose, Fixed locked, then two power-up bricks")
        print("  row 4: the directional Big bricks\n")
    }

    /// Draws the Portal - plain, Rounded and square, and greyed out while it is cooling - plus
    /// the reference page's own picture of one and of a Fixed brick, which are drawn by
    /// different code and have to agree with the field.
    func testThePortalBricksCanBeLookedAt() throws {
        let cell = CGSize(width: 56, height: 28)
        let column: CGFloat = 100, row: CGFloat = 90

        let display = SKScene(size: CGSize(width: column*4 + 20, height: row*3 + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        func game() -> GameScene {
            let scene = GameScene(size: CGSize(width: 402, height: 874))
            scene.gameMode = .endlessII
            scene.brickWidth = cell.width
            scene.brickHeight = cell.height
            scene.gameWidth = 402
            return scene
        }

        let kinds = ["plain", "rounded", "square", "square diamond"]
        for (index, kind) in kinds.enumerated() {
            for (line, cooling) in [(0, false), (1, true)] {
                let scene = game()
                let brick: SKSpriteNode
                if kind.hasPrefix("square") {
                    brick = scene.endlessIIMakeSquare(column: 0, rowY: 0)
                    brick.isHidden = false
                } else {
                    brick = SKSpriteNode(texture: scene.brickNormalTexture, size: cell)
                    scene.addChild(brick)
                }
                brick.texture = scene.brickIndestructible2Texture
                if kind == "rounded" { scene.makeRounded(brick) }
                if kind == "square diamond" { scene.applyEndlessIIStyle(.diamond, to: brick) }
                scene.makePortal(brick)
                scene.endlessIIShowPortal(brick, cooling: cooling)

                brick.removeFromParent()
                brick.position = CGPoint(x: 10 + column*(CGFloat(index) + 0.5),
                                         y: display.size.height - row*(CGFloat(line) + 0.5))
                display.addChild(brick)
            }
        }

        for (index, art) in [BrickTypeArt.style(.portal), .style(.fixed)].enumerated() {
            let picture = SKTexture(image: BrickTypeIcons.image(for: art))
            let node = SKSpriteNode(texture: picture, size: BrickTypeIcons.canvas)
            node.position = CGPoint(x: 10 + column*(CGFloat(index) + 0.5),
                                    y: display.size.height - row*2.5)
            display.addChild(node)
        }
        // The reference page's own drawings, beside the field's. They are separate code and
        // the Fixed one is drawn into a flipped coordinate space, which is exactly the kind of
        // thing that gets turned over in one place and not the other

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("portal-bricks.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Portal bricks, drawn: \(file.path)")
        print("  row 1: \(kinds.joined(separator: ", ")) - ready")
        print("  row 2: the same, cooling")
        print("  row 3: the reference page's Portal, then its Fixed brick\n")
    }

    /// The field keeps descending while Aimed Sticky runs.
    ///
    /// James, play-test round 275: "The bricks stopped descending down, even with the bottom
    /// row empty. I had to pause and unpause the game for them to start descending properly
    /// again."
    ///
    /// `endlessIISpendPaddleTurns` sets `endlessIIAimedStickyOwedTurn` on every landing while
    /// the clock runs, as a snapshot for the one contact it belongs to - and only the catch
    /// that found the clock already stopped cleared it. `endlessIIFieldIsHeld` reads it, so one
    /// landing stopped the field for the rest of the power-up. It read as a pause bug for the
    /// reason round 169's did: resuming resets the ball, and the reset clears the flag.
    func testTheFieldStillDescendsBetweenAimedStickyCatches() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.endlessIIAimedStickyClock.collect(5)
        XCTAssertTrue(scene.endlessIIAimedStickyClock.isRunning)

        scene.endlessIISpendPaddleTurns()
        XCTAssertTrue(scene.endlessIIAimedStickyOwedTurn,
                      "the snapshot is taken, which is what it is for")

        scene.endlessIIAimedStickyOwedTurn = false
        // What the contact now does with it, whichever way the catch went

        XCTAssertFalse(scene.endlessIIAimHold)
        XCTAssertFalse(scene.endlessIIFieldIsHeld,
                       "nobody is aiming, so nothing is holding the field")
    }

    /// And the hold that *should* stop it still does.
    func testAimingStillHoldsTheField() {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.endlessIIAimHold = true
        XCTAssertTrue(scene.endlessIIFieldIsHeld,
                      "a field that descended while the player was aiming would move the "
                      + "target out from under the shot")
    }

    /// Draws the aim line three ways, so "more similar to what was there previously" can be
    /// judged rather than asserted.
    ///
    /// James, play-test round 275: "the new line looks bad. Let's go back to something more
    /// similar to what was there previously, but with no arrow head."
    ///
    /// Left is the line as it was up to round 260 - glowing `SKShapeNode` segments and a head -
    /// rebuilt here from that version because it no longer exists in the code, and it is the
    /// thing being compared *to*. Middle is round 260's, the trajectory's white core inside a
    /// wide green glow. Right is what the scene draws now, through `tickEndlessIIAim` itself.
    func testTheAimLineCanBeLookedAt() throws {
        let ballSize: CGFloat = 12
        let length: CGFloat = 420
        let column: CGFloat = 150

        let display = SKScene(size: CGSize(width: column*2 + 40, height: length + 80))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        func certainty(_ along: CGFloat) -> CGFloat { pow(1 - along, 1.8) }
        func pieces(_ body: (CGFloat, CGFloat, CGFloat) -> Void) {
            let step = max(ballSize*0.9, 1)
            let count = max(Int((length/step).rounded(.up)), 1)
            for piece in 0..<count {
                let a = length*CGFloat(piece)/CGFloat(count)
                let b = length*CGFloat(piece + 1)/CGFloat(count)
                body(a, b, certainty((a + b)/2/length))
            }
        }

        // 1. As it was, up to round 260
        let before = SKNode()
        pieces { a, b, certain in
            let segment = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: a, y: 0))
            path.addLine(to: CGPoint(x: b, y: 0))
            segment.path = path
            segment.strokeColor = GameScene.endlessIIHaloColour
                .withAlphaComponent(max(0.3, 0.95*certain))
            segment.lineWidth = 2 + (1 - certain)*2
            segment.glowWidth = (1 - certain)*(1 - certain)*6
            segment.lineCap = .round
            before.addChild(segment)
        }
        let head = SKShapeNode()
        let headPath = CGMutablePath()
        headPath.move(to: CGPoint(x: length - ballSize*0.7, y: ballSize*0.55))
        headPath.addLine(to: CGPoint(x: length, y: 0))
        headPath.addLine(to: CGPoint(x: length - ballSize*0.7, y: -ballSize*0.55))
        head.path = headPath
        head.strokeColor = GameScene.endlessIIHaloColour.withAlphaComponent(0.55)
        head.lineWidth = 2.5
        head.glowWidth = 3
        head.lineCap = .round
        before.addChild(head)

        // 2. Candidate widths, to pick between. The far end is what is being chosen: an
        // `SKShapeNode`'s glow reads much narrower than its nominal `glowWidth`, so carrying the
        // old numbers across arithmetically made a wedge where the old line was nearly parallel
        // The candidates each round drew here are gone once they have been chosen between,
        // and what they settled is written where the choice lives, in `tickEndlessIIAim`.
        // Round 276 picked a width and an alpha floor against the line on the left; round 280
        // picked the soft picture and a lower floor against three of its own. Both times the
        // arithmetic answer and the one that looked right were different answers, which is the
        // whole reason this draws them side by side rather than asserting a number

        // 3. What the scene draws now, through its own code
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.ballSize = ballSize
        scene.brickHeight = 28
        scene.finalBrickRowHeight = 200
        let target = SKSpriteNode(color: .white, size: CGSize(width: ballSize, height: ballSize))
        target.position = CGPoint(x: 0, y: -220)
        scene.addChild(target)
        scene.endlessIIHeldBalls.append(target)
        scene.endlessIIAimedStickyClock.collect(5)
        scene.endlessIIAimHold = true
        XCTAssertNotNil(scene.endlessIIAimTarget, "the aim has something to point at")
        scene.tickEndlessIIAim()
        let now = try XCTUnwrap(scene.endlessIIAimArrow)
        now.removeFromParent()

        for (index, line) in [before, now].enumerated() {
            line.zRotation = .pi/2
            line.position = CGPoint(x: 20 + column*(CGFloat(index) + 0.5), y: 40)
            line.zPosition = 1
            display.addChild(line)

            let ball = SKSpriteNode(color: .white,
                                    size: CGSize(width: ballSize, height: ballSize))
            ball.position = line.position
            display.addChild(ball)
            // The held ball at the foot of each, because how the line meets it is half of what
            // is being judged
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("aim-line.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Aim line, drawn: \(file.path)")
        print("  left: the line as it was before round 260   right: what the scene draws\n")
    }

    /// What a shaped paddle costs per frame **while it is moving**, which is the case the
    /// round-258 test does not cover.
    ///
    /// James, play-test rounds 258 and 275: "the ball gets stuttery when there's a shaped paddle
    /// active." Round 258 cached the body trace and this stayed on the list, so the trace is not
    /// it - and the test that says so calls `refreshEndlessIIPaddleShapeArt` on a *stationary*
    /// paddle, in isolation. In play the paddle is being dragged and the whole of
    /// `tickEndlessIIPaddlePowerUps` runs, so this measures that.
    func testWhatAMovingShapedPaddleCostsPerFrame() {
        let scene = loadedField()
        scene.paddleHeight = 12
        scene.paddleWidth = 75
        scene.ballSize = 12
        scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
        scene.paddle.texture = scene.paddleTexture
        scene.paddle.size = CGSize(width: 75, height: 12)
        scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
        scene.endlessIIPaddleSurface = .convex
        scene.endlessIIPaddleSurfaceClock.collect(10)
        scene.refreshEndlessIIPaddleShapeArt()
        XCTAssertEqual(scene.paddle.texture?.description,
                       SKTexture(imageNamed: "regularPaddleConvex").description,
                       "or this is measuring a plain paddle and proving nothing")

        var traces = 0, sizeWrites = 0
        var lastSize = scene.paddle.size
        let start = Date.timeIntervalSinceReferenceDate
        for step in 0..<120 {
            scene.paddle.position.x = sin(Double(step)/6)*80
            // Dragged, the way a finger drags it - the stationary case is the one already
            // covered, and a paddle that only costs something while it moves is exactly what
            // "stuttery" describes

            let bodyBefore = scene.paddle.physicsBody
            scene.tickEndlessIIPaddlePowerUps(Double(step)/60)
            if scene.paddle.physicsBody !== bodyBefore { traces += 1 }
            if scene.paddle.size != lastSize { sizeWrites += 1; lastSize = scene.paddle.size }
        }
        let each = (Date.timeIntervalSinceReferenceDate - start)/120

        print(String(format: "\n  A moving shaped paddle, 120 frames:"))
        print(String(format: "    body retraces:      %d", traces))
        print(String(format: "    paddle size writes: %d", sizeWrites))
        print(String(format: "    tick:               %6.3f ms  (%4.1f%% of a frame)",
                     each*1000, each/frame*100))
        print("")

        XCTAssertEqual(traces, 0,
                       "a paddle whose shape and width have not changed must not retrace its "
                       + "body just because it moved")
        XCTAssertLessThan(each, frame/4,
                          "the paddle tick is taking a quarter of a frame on its own")
    }

    /// How ragged the surface a traced paddle body gives the ball is.
    ///
    /// The remaining candidate for "the ball gets stuttery when there's a shaped paddle
    /// active", once the per-frame cost has been measured and found to be 3% of a frame. A
    /// shaped paddle's body is traced from the *picture's alpha* at the size it is drawn -
    /// about 75 points across - so the dome the ball rolls along is a staircase of roughly
    /// point-high steps rather than a curve. A flat paddle's staircase is a straight line and
    /// costs nothing; a curved one's is not.
    ///
    /// Measured off the artwork rather than off the body, because `SKPhysicsBody` will not say
    /// what its outline is. This walks the same alpha the tracer walks, at the same resolution.
    func testHowRaggedATracedPaddleSurfaceIs() throws {
        let width = 75, drawnHeight: CGFloat = 18

        for name in ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                     "regularPaddleWave"] {
            guard let art = UIImage(named: name), let source = art.cgImage else { continue }

            let height = Int(drawnHeight.rounded())
            var pixels = [UInt8](repeating: 0, count: width*height*4)
            let context = CGContext(data: &pixels, width: width, height: height,
                                    bitsPerComponent: 8, bytesPerRow: width*4,
                                    space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            // Redrawn at the size the body is traced at, which is the whole point: the steps
            // are a consequence of the resolution the tracer works at

            var top: [Int] = []
            for x in 0..<width {
                var found = height
                for y in 0..<height where pixels[(y*width + x)*4 + 3] > 128 {
                    found = y
                    break
                }
                top.append(found)
            }

            let steps = zip(top, top.dropFirst()).map { abs($1 - $0) }
            let jumps = steps.filter { $0 > 0 }
            print(String(format: "    %-24@ %2d steps, biggest %d point(s)",
                         name as NSString, jumps.count, steps.max() ?? 0))
        }
        print("")
        // Printed rather than asserted: what counts as ragged is a judgement about how a ball
        // feels, and the number is here to be read beside the shapes it comes from
    }

    /// The paddle tick's frame times, as a distribution rather than a mean.
    ///
    /// A stutter is not a slow average, it is a few frames that arrive late - so a mean of 3%
    /// of a frame says almost nothing on its own. This runs the tick over a shaped paddle and
    /// over a plain one and prints the worst frames of each, which is where a stutter would be
    /// if the tick were causing it.
    func testTheShapedPaddleTicksFrameTimes() {
        func times(shaped: Bool) -> [Double] {
            let scene = loadedField()
            scene.paddleHeight = 12
            scene.paddleWidth = 75
            scene.ballSize = 12
            scene.paddleTexture = SKTexture(imageNamed: "regularPaddle")
            scene.paddle.texture = scene.paddleTexture
            scene.paddle.size = CGSize(width: 75, height: 12)
            scene.paddle.physicsBody = SKPhysicsBody(rectangleOf: scene.paddle.size)
            if shaped {
                scene.endlessIIPaddleSurface = .wavy
                scene.endlessIIPaddleSurfaceClock.collect(10)
            }
            scene.refreshEndlessIIPaddleShapeArt()

            var each: [Double] = []
            for step in 0..<240 {
                scene.paddle.position.x = sin(Double(step)/6)*80
                let start = Date.timeIntervalSinceReferenceDate
                scene.tickEndlessIIPaddlePowerUps(Double(step)/60)
                each.append(Date.timeIntervalSinceReferenceDate - start)
            }
            return each.sorted()
        }

        for (label, each) in [("plain", times(shaped: false)),
                              ("shaped (wave)", times(shaped: true))] {
            let median = each[each.count/2]
            let ninetyNine = each[Int(Double(each.count)*0.99)]
            print(String(format: "\n  %@: median %6.3f ms, 99th %6.3f ms, worst %6.3f ms",
                         label as NSString, median*1000, ninetyNine*1000,
                         (each.last ?? 0)*1000))
            XCTAssertLessThan(ninetyNine, frame/2,
                              "\(label): all but the worst 1% of frames must leave the "
                              + "physics and the drawing half a frame to work in")
        }
        print("")
    }

    /// What the power-up timer rings cost per frame, and how much of it is spent redrawing a
    /// path that has not visibly changed.
    ///
    /// The lead the shaped paddle's own numbers pointed at. James listed four power-ups
    /// together - "Drift, Shaped paddles, Trajectory line, Quicksand" - and what those four
    /// share is not what they do to the field, it is that each is *timed* and so each wears a
    /// ring in the HUD. `PowerUpTrayRings.update` runs every frame and hands a freshly built
    /// `CGPath` to two `SKShapeNode`s per running power-up, one of them glowing: an
    /// `SKShapeNode` re-tessellates when it is handed a path, and a glowing one is rendered
    /// through an offscreen pass of its own. That is round 258's finding about the trajectory
    /// line, in the one place round 258 did not look.
    func testWhatThePowerUpTimerRingsCostPerFrame() {
        let radius: CGFloat = 12

        for running in [1, 4, 8] {
            var built = 0
            let start = Date.timeIntervalSinceReferenceDate
            for frame in 0..<600 {
                for slot in 0..<running {
                    let left = 1 - CGFloat(frame)/600 - CGFloat(slot)*0.01
                    _ = PowerUpRingHUD.ringPath(remaining: max(0, left), segments: nil,
                                                radius: radius)
                    built += 1
                }
            }
            let each = (Date.timeIntervalSinceReferenceDate - start)/600
            print(String(format: "  %d running: %5d paths in 600 frames, %6.4f ms per frame",
                         running, built, each*1000))
        }

        // What the skip saves, counted rather than timed - which is the only way this kind of
        // cost has ever shown itself here. Building a path is cheap; *handing* one to an
        // SKShapeNode re-tessellates it, and the glowing copy under it is an offscreen pass
        for (label, segments) in [("a plain ring", Int?.none), ("a five-segment ring", 5)] {
            for seconds in [10, 30] {
                let frames = seconds*60
                var drawn = 0
                var last: CGFloat = -1
                for frame in 0...frames {
                    let left = 1 - CGFloat(frame)/CGFloat(frames)
                    guard PowerUpRingHUD.hasTurned(from: last, to: left,
                                                   segments: segments, radius: radius)
                    else { continue }
                    last = left
                    drawn += 1
                }
                print(String(format: "  %@ over %2ds: %4d redraws instead of %4d  (%.0f%% saved)",
                             label as NSString, seconds, drawn, frames + 1,
                             (1 - Double(drawn)/Double(frames + 1))*100))
                XCTAssertLessThan(drawn, frames/2,
                                  "\(label) over \(seconds)s is still redrawing on most frames")
            }
        }
        print("")
        // Two nodes per running power-up, so the frames saved are twice this in
        // re-tessellations and the same again in offscreen passes avoided
    }

    /// Draws each shaped paddle's computed outline over the picture it was computed from.
    ///
    /// The check that matters and the only one there is. `PaddleOutline` claims to find the
    /// same silhouette `SKPhysicsBody(texture:)` traces, without the staircase - and a
    /// silhouette that has drifted off the art is a paddle that bounces the ball off something
    /// the player cannot see, which is the exact failure round 213 set out to fix. Numbers
    /// cannot say whether it sits on the picture; this can.
    func testTheComputedPaddleOutlinesCanBeLookedAt() throws {
        let drawn = CGSize(width: 300, height: 72)
        let shapes = ["regularPaddle", "regularPaddleConvex", "regularPaddleConcave",
                      "regularPaddleWave", "regularPaddleWedgeLeft"]
        let row: CGFloat = 110

        let display = SKScene(size: CGSize(width: drawn.width + 40,
                                           height: row*CGFloat(shapes.count) + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (index, name) in shapes.enumerated() {
            guard let art = UIImage(named: name), let image = art.cgImage else { continue }
            let centre = CGPoint(x: display.size.width/2,
                                 y: display.size.height - row*(CGFloat(index) + 0.5))

            let picture = SKSpriteNode(texture: SKTexture(imageNamed: name), size: drawn)
            picture.position = centre
            picture.alpha = 0.55
            display.addChild(picture)
            // Faded, so the outline drawn over it is the thing being read

            for piece in PaddleOutline.pieces(of: image, size: drawn) {
                let shape = SKShapeNode(path: piece)
                shape.position = centre
                shape.strokeColor = UIColor.cyan.withAlphaComponent(0.9)
                shape.lineWidth = 1
                shape.fillColor = UIColor.cyan.withAlphaComponent(0.12)
                shape.zPosition = 1
                display.addChild(shape)
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("paddle-outlines.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Paddle outlines, drawn: \(file.path)")
        print("  \(shapes.joined(separator: ", ")) - picture faded, computed strips over it\n")
    }

    /// A spinning shaped brick through its turn, and a still one beside it.
    ///
    /// James, round 280, with a screenshot: "concave brick had a weird graphic issue". What the
    /// picture shows is a peak standing above the brick's top edge with diagonals running down
    /// to both corners - two silhouettes crossing, which is exactly what round 266's
    /// cross-fading partner looked like before it was turned the right way round. That was
    /// found by rendering it and it is being looked for the same way.
    ///
    /// The still brick in the left column is the control: if it is wrong too, the partner is
    /// innocent and the art is the wrong way up.
    func testASpinningShapedBrickCanBeLookedAt() throws {
        let cell = CGSize(width: 56, height: 28)
        let column: CGFloat = 90, row: CGFloat = 90
        let turns: [CGFloat] = [0, .pi/4, .pi/2, .pi*0.75, .pi]

        let faces: [EndlessIIFace] = [.concave, .convex, .wedge, .diamond]
        let display = SKScene(size: CGSize(width: column*CGFloat(turns.count) + 20,
                                           height: row*CGFloat(faces.count) + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (line, face) in faces.enumerated() {
            for (index, turn) in turns.enumerated() {
                let scene = GameScene(size: CGSize(width: 402, height: 874))
                scene.gameMode = .endlessII
                scene.brickWidth = cell.width
                scene.brickHeight = cell.height

                let brick = SKSpriteNode(texture: scene.brickIndestructible1Texture, size: cell)
                scene.addChild(brick)
                brick.endlessIIFaceMirrored = false
                brick.endlessIIFaceFlipped = false
                scene.makeFace(face, on: brick)
                brick.zRotation = turn
                scene.refreshEndlessIIShapedFaces()
                // Through the per-frame sweep, which is what puts the partner on and decides
                // how much of it shows

                brick.removeFromParent()
                brick.position = CGPoint(x: 10 + column*(CGFloat(index) + 0.5),
                                         y: display.size.height - row*(CGFloat(line) + 0.5))
                display.addChild(brick)
            }
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("spinning-faces.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Spinning faces, drawn: \(file.path)")
        print("  rows: concave, convex, wedge, diamond")
        print("  columns: 0, 45, 90, 135 and 180 degrees of turn\n")
    }

    /// A concave brick pulled apart: the silhouette, the picture, and what the scene builds.
    ///
    /// The still brick in `testASpinningShapedBrickCanBeLookedAt` shows the crossing at *zero*
    /// rotation, where round 266's partner is provably absent, so the partner is innocent. This
    /// draws the three things that could be doing it, one per column, large enough to read.
    func testAConcaveBrickPulledApartCanBeLookedAt() throws {
        let cell = CGSize(width: 168, height: 84)
        let column: CGFloat = 200, row: CGFloat = 120

        let display = SKScene(size: CGSize(width: column*3 + 20, height: row*2 + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (line, face) in [EndlessIIFace.concave, .convex].enumerated() {
            let y = display.size.height - row*(CGFloat(line) + 0.5)

            // 1. The silhouette the geometry says
            let outline = SKShapeNode(path: EndlessIIFaceGeometry.silhouette(face, size: cell))
            outline.position = CGPoint(x: 10 + column*0.5, y: y)
            outline.fillColor = UIColor.cyan.withAlphaComponent(0.35)
            outline.strokeColor = .cyan
            display.addChild(outline)

            // 2. The picture on its own
            let art = GameScene.shapedArt(for: face).map {
                "BrickIndestructible1" + $0.rawValue + "0"
            } ?? ""
            if UIImage(named: art) != nil {
                let picture = SKSpriteNode(texture: SKTexture(imageNamed: art), size: cell)
                picture.position = CGPoint(x: 10 + column*1.5, y: y)
                display.addChild(picture)
            }

            // 3. What the scene builds
            let scene = GameScene(size: CGSize(width: 402, height: 874))
            scene.gameMode = .endlessII
            scene.brickWidth = cell.width
            scene.brickHeight = cell.height
            let brick = SKSpriteNode(texture: scene.brickIndestructible1Texture, size: cell)
            scene.addChild(brick)
            brick.endlessIIFaceMirrored = false
            brick.endlessIIFaceFlipped = false
            scene.makeFace(face, on: brick)
            brick.removeFromParent()
            brick.position = CGPoint(x: 10 + column*2.5, y: y)
            display.addChild(brick)
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("concave-apart.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Concave pulled apart: \(file.path)")
        print("  rows: concave, convex   columns: silhouette, picture, what the scene builds\n")
    }

    /// How deep the concave brick's notch actually is, measured off James's artwork.
    ///
    /// James, round 282: "match the concave body to the graphic of the concave brick I
    /// supplied... the geometry needs to deepen to match the art." So the number has to come
    /// from the pictures rather than from a judgement about how a dish should look - which is
    /// where the old tenth came from, and it is the reason the two drifted apart.
    ///
    /// Read with `PaddleOutline.edges`, which finds an edge to sub-pixel precision - built for
    /// the paddle in round 280 and exactly the tool for this.
    func testHowDeepTheConcaveArtCutsItsNotch() throws {
        let names = ["BrickNormalConcave", "BrickIndestructible1Concave0",
                     "BrickMultiHit1Concave", "retroBrickNormalConcave0"]
        print("\n  The notch, as a fraction of the picture's height above its middle:")
        for name in names {
            guard let art = UIImage(named: name), let image = art.cgImage else {
                print("    \(name): not in the catalogue")
                continue
            }
            let edges = PaddleOutline.edges(of: image, samples: 120)
            let tops = edges.compactMap { $0?.top }
            guard let lowest = tops.min(), let highest = tops.max() else { continue }
            // `top` runs 0 at the picture's bottom to 1 at its top, so the notch is the lowest
            // the top edge gets - at the middle, where the V bottoms out
            print(String(format: "    %-30@ notch %.3f, shoulders %.3f  ->  %+.3f of height "
                         + "above the middle", name as NSString, lowest, highest, lowest - 0.5))
        }
        print("")
    }

    /// What Ball Spin and Random Bounce actually do, in degrees.
    ///
    /// James, round 283: "ball spin isn't curving the ball - what is actually happening?" and
    /// "randomised bounce now isn't doing anything. There's no discernible randomness to the
    /// bounce." Both are wired correctly - the clocks are separate, the grip is taken at the
    /// bounce, the curve is applied from `didSimulatePhysics`, and the randomiser is called from
    /// every corrected bounce. So the question is not whether they run but how much they do,
    /// which is a number neither of them has ever been made to state.
    func testWhatBallSpinAndRandomBounceActuallyDo() {
        print("\n  Ball Spin: how far the heading turns over a whole flight")
        print("    (the play area is about 400 points wide, so a fast swipe is 600-900 pt/s)")
        for speed in [100, 200, 400, 600, 900, 1400] as [CGFloat] {
            let rate = EndlessIIBallSpin.turnRate(paddleSpeed: speed)

            // Integrated the way the frames apply it: the rate decays continuously, so the
            // whole turn is rate / ln(1/decay), and what the player sees near the paddle is
            // the part spent in the first quarter second
            let whole = rate/log(1/EndlessIIBallSpin.decayPerSecond)
            let early = whole*(1 - pow(EndlessIIBallSpin.decayPerSecond, 0.25))
            print(String(format: "    %4.0f pt/s -> %5.1f deg/s, %5.1f deg in all, "
                         + "%4.1f deg in the first quarter second",
                         speed, rate*180/CGFloat.pi, whole*180/CGFloat.pi,
                         early*180/CGFloat.pi))
        }

        print("\n  Random Bounce: how far a bounce can be nudged, at spread "
              + "\(GameScene.endlessIIRandomisedBounceSpread)")
        let spread = GameScene.endlessIIRandomisedBounceSpread
        for angle in [20.0, 45.0, 70.0, 90.0] {
            let full = GameScene.randomisedBounceAngle(from: angle, minimumDeg: 10, share: spread)
            let none = GameScene.randomisedBounceAngle(from: angle, minimumDeg: 10,
                                                       share: -spread)
            // `share` is the *fraction*, and the fraction is drawn from -spread...spread - so
            // the extremes are +/-spread, not +/-1. Measured with +/-1 the first time, which
            // reported a 45-degree bounce landing anywhere from 10 to 80 and made the power-up
            // look ten times wilder than it is
            print(String(format: "    a %2.0f deg bounce lands between %5.1f and %5.1f "
                         + "- a spread of %4.1f deg", angle, none, full, full - none))
        }
        print("")
    }

    /// The two reference-page icons James asked to be brought up to date.
    ///
    /// Round 283: "power-up - use a generic power up graphic" and "update the directional
    /// graphic". Both were drawn by the page's own hand rather than from the field's art - the
    /// power-up brick borrowed a *rounded brick's* picture, and the directional one drew a white
    /// bar that round 271 replaced with a panel.
    func testTheUpdatedReferenceIconsCanBeLookedAt() throws {
        let art: [BrickTypeArt] = [.powerUpBrick, .style(.directional), .style(.fixed),
                                   .style(.exploding), .style(.spawner)]
        let column: CGFloat = 140, row: CGFloat = 110

        let display = SKScene(size: CGSize(width: column*CGFloat(art.count) + 20, height: row + 20))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (index, entry) in art.enumerated() {
            let picture = SKTexture(image: BrickTypeIcons.image(for: entry))
            let node = SKSpriteNode(texture: picture, size: BrickTypeIcons.canvas)
            node.position = CGPoint(x: 10 + column*(CGFloat(index) + 0.5),
                                    y: display.size.height/2)
            display.addChild(node)
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("reference-icons.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Reference icons, drawn: \(file.path)")
        print("  power-up, directional, fixed, exploding, spawner\n")
    }
    /// What a scaled sprite says about its own size, and how far the Aura's picture reaches.
    ///
    /// Two numbers the Aura's rewrite turns on, and neither was worth guessing (§8.6, "an
    /// unmeasured number drifts"). James, round 284: "Aura should be bigger and should be
    /// behind the ball not on top of it. Also, it lags behind the ball too far. And it should
    /// grow and shrink with the ball if those power ups are active."
    ///
    /// The Increase Ball Size power-up works by `ball.run(SKAction.scale(to: 1.5))`, so
    /// whether `size` already carries that scale decides whether the aura has to multiply by
    /// it or would be doubling it. And `endlessIIAuraVisibleShare` - the fraction of the
    /// picture that reads as glow - was set to 0.76 by eye, which is exactly the kind of
    /// number a play-test note about size is evidence against.
    func testWhatAScaledSpriteSaysAndHowFarTheAuraArtReaches() {
        let sprite = SKSpriteNode(color: .white, size: CGSize(width: 10, height: 10))
        sprite.setScale(2)
        print("AURA scale 2: size=\(sprite.size) frame=\(sprite.frame.size) xScale=\(sprite.xScale)")

        let child = SKSpriteNode(color: .white, size: CGSize(width: 4, height: 4))
        sprite.addChild(child)
        print("AURA child of a x2 parent: frame=\(child.frame.size) (scene units)")

        guard let image = UIImage(named: "BallAura"), let cg = image.cgImage else {
            print("AURA no artwork in this bundle")
            return
        }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width*height*4)
        let context = CGContext(data: &pixels, width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: width*4,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let midY = height/2
        var profile: [(CGFloat, CGFloat)] = []
        for x in (width/2)..<width {
            let alpha = CGFloat(pixels[(midY*width + x)*4 + 3])/255
            let radius = CGFloat(x - width/2)/CGFloat(width/2)
            profile.append((radius, alpha))
        }
        let peak = profile.map(\.1).max() ?? 0
        print("AURA art \(width)x\(height), peak alpha \(peak)")
        for threshold in [CGFloat(0.02), 0.05, 0.10, 0.25, 0.5] {
            let last = profile.last { $0.1 >= peak*threshold }?.0 ?? 0
            print("AURA alpha >= \(threshold) of peak out to \(last) of the half-width")
        }
        for step in stride(from: 0, through: 10, by: 1) {
            let want = CGFloat(step)/10
            let sample = profile.min { abs($0.0 - want) < abs($1.0 - want) }
            print("AURA at r=\(want): alpha \(sample?.1 ?? 0)")
        }
    }

    /// The Aura and a directional brick, drawn so somebody can look at them.
    ///
    /// Round 284's two visual answers, and both are the kind that only a picture settles: a
    /// glow that is behind the ball rather than over it, and a directional brick that still
    /// looks like the brick it is.
    func testTheAuraAndTheDirectionalBricksCanBeLookedAt() throws {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickWidth = 100
        scene.brickHeight = 50
        scene.ballSize = 30
        scene.ball.size = CGSize(width: 30, height: 30)
        scene.totalStatsArray = [TotalStats()]

        let display = SKScene(size: CGSize(width: 700, height: 420))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        // Top row: a directional brick over four different brick types
        let faces: [(String, SKTexture)] = [("normal", scene.brickNormalTexture),
                                            ("multi-hit", scene.brickMultiHit1Texture),
                                            ("multi-hit 3", scene.brickMultiHit3Texture),
                                            ("indestructible", scene.brickIndestructible2Texture)]
        for (index, face) in faces.enumerated() {
            let brick = SKSpriteNode(texture: face.1, size: CGSize(width: 100, height: 50))
            brick.name = BrickCategoryName
            scene.addChild(brick)
            brick.endlessIIVulnerableSide = .bottom
            scene.makeDirectional(brick)
            brick.removeFromParent()
            brick.position = CGPoint(x: 110 + 150*CGFloat(index), y: 330)
            display.addChild(brick)
        }

        // Bottom row: the ball at three scales, each wearing its aura
        for (index, ballScale) in [CGFloat(0.5), 1, 1.5].enumerated() {
            let sample = GameScene()
            sample.gameMode = .endlessII
            sample.ballSize = 30
            sample.ball.size = CGSize(width: 30, height: 30)
            sample.ball.texture = SKTexture(imageNamed: "ballNormal")
            sample.ball.color = .white
            sample.ball.colorBlendFactor = 0
            // **The ball's own picture.** The first version of this took the texture from
            // another bare `GameScene`, which has none - the sprite is loaded from
            // `GameScene.sks` at run time and a scene built with `GameScene()` never loads it -
            // so SpriteKit drew a plain white rectangle and the render showed a square ball.
            // James asked whether the square theme was on; it was not, the harness simply had
            // no ball to draw
            sample.totalStatsArray = [TotalStats()]
            sample.addChild(sample.ball)
            sample.ball.setScale(ballScale)
            sample.endlessIICollectAura()
            sample.tickEndlessIIAura()

            sample.ball.removeFromParent()
            sample.ball.position = CGPoint(x: 150 + 200*CGFloat(index), y: 130)
            display.addChild(sample.ball)
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("round-284.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Round 284, drawn: \(file.path)")
        print("  top: directional over normal, multi-hit, multi-hit 3, indestructible")
        print("  bottom: the aura at ball scale 0.5, 1 and 1.5\n")
    }

    /// What Blackout would cost to draw, since James asked for it measured before deciding.
    ///
    /// The daily's Monochrome twist is specified as a grayscale `CIFilter` on an `SKEffectNode`
    /// wrapping the scene, with a performance gate on it: if it cannot hold frame rate it ships
    /// as a desaturated palette swap instead. Nobody had ever put a number to the gate. James,
    /// round 284: "Blackout, measure first. For the HUD, leave it, it doesn't need the filter."
    ///
    /// **What this can and cannot say.** It times `SKView.texture(from:)`, which is a real
    /// render of a real layer through the real filter, so the *ratio* between a filtered field
    /// and the same field unfiltered is meaningful. It is not a device frame: this runs on a
    /// Mac's GPU through the simulator, and the oldest supported iPhone is a different machine.
    /// A ratio near one is evidence the gate can be passed; a ratio of several would settle it
    /// the other way without needing a device at all.
    ///
    /// The HUD is deliberately outside the filtered node, which is James's call in the same
    /// note and also the cheaper arrangement - a filter's cost goes with the *area* it covers.
    func testWhatBlackoutWouldCostToDraw() throws {
        func field(filtered: Bool) -> SKScene {
            let scene = SKScene(size: CGSize(width: 402, height: 874))
            scene.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

            let host: SKNode
            if filtered {
                let effect = SKEffectNode()
                effect.filter = CIFilter(name: "CIPhotoEffectMono")
                effect.shouldEnableEffects = true
                scene.addChild(effect)
                host = effect
            } else {
                host = scene
            }

            for row in 0..<11 {
                for column in 0..<11 {
                    let brick = SKSpriteNode(color: .systemPink,
                                             size: CGSize(width: 34, height: 16))
                    brick.position = CGPoint(x: 21 + 36*CGFloat(column),
                                             y: 600 + 18*CGFloat(row))
                    host.addChild(brick)
                }
            }
            for index in 0..<4 {
                let ball = SKSpriteNode(color: .white, size: CGSize(width: 14, height: 14))
                ball.position = CGPoint(x: 60 + 90*CGFloat(index), y: 300)
                host.addChild(ball)
            }
            let paddle = SKSpriteNode(color: .cyan, size: CGSize(width: 105, height: 14))
            paddle.position = CGPoint(x: 201, y: 120)
            host.addChild(paddle)
            return scene
        }

        let plainScene = field(filtered: false)
        let blackoutScene = field(filtered: true)
        let view = SKView(frame: CGRect(origin: .zero, size: plainScene.size))

        let plain = cost("field, as it is") { _ = view.texture(from: plainScene) }
        let blackout = cost("field, through the filter") { _ = view.texture(from: blackoutScene) }

        print(String(format: "\n  Blackout costs %.2fx an ordinary field to draw\n",
                     blackout/plain))

        XCTAssertGreaterThan(plain, 0)
        XCTAssertGreaterThan(blackout, 0)
        // No threshold. This is a number for a decision James is making, not a tripwire - and
        // a bar invented here would be a bar invented here
    }

    /// A split paddle wearing its lasers, drawn so somebody can look at it.
    ///
    /// Round 285's visual half: the laser dress used to be one strip across the whole span,
    /// which said "armed" about the gaps as well - the one place a laser certainly does not
    /// come from. The marks below each origin are where the shots actually start.
    func testTheSplitPaddlesLasersCanBeLookedAt() throws {
        let display = SKScene(size: CGSize(width: 700, height: 300))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (index, span) in [CGFloat(120), 240, 360].enumerated() {
            // Two turrets at every width, however many pieces the span makes (round 286)
            let scene = GameScene()
            scene.gameMode = .endlessII
            scene.totalStatsArray = [TotalStats()]
            scene.layoutUnit = 40
            scene.ballSize = 14
            scene.paddleWidth = 120
            scene.paddle.size = CGSize(width: span, height: 12)
            scene.paddle.position = .zero
            scene.addChild(scene.paddle)
            scene.endlessIICollectDoublePaddle()
            scene.refreshEndlessIIDoublePaddle()

            let layout = GameScene.endlessIIDoublePaddleLayout(span: span,
                                                               standardWidth: 120,
                                                               ballSize: 14)
            let pitch = layout.segment + layout.gap
            let first = -span/2 + layout.segment/2
            let y = 240 - 80*CGFloat(index)

            for piece in 0..<layout.count {
                let bar = SKSpriteNode(color: .white,
                                       size: CGSize(width: layout.segment, height: 10))
                bar.position = CGPoint(x: 350 + first + pitch*CGFloat(piece), y: y)
                display.addChild(bar)
            }
            for centre in scene.endlessIISplitLaserTurrets {
                let turret = SKSpriteNode(color: UIColor(white: 1, alpha: 0.35),
                                          size: CGSize(width: layout.segment, height: 6))
                turret.position = CGPoint(x: 350 + centre, y: y + 9)
                display.addChild(turret)
            }
            let inset = scene.layoutUnit/4
            for origin in [-span/2 + inset, span/2 - inset] {
                let shot = SKSpriteNode(color: .systemPink, size: CGSize(width: 6, height: 22))
                shot.position = CGPoint(x: 350 + origin, y: y + 24)
                display.addChild(shot)
            }
            // The turret across the outermost piece and the shot where it actually leaves,
            // drawn separately: the first version of this marked the piece's *centre* and so
            // showed the turret in the middle of a piece the answer puts on its outer edge
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("round-285.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Round 285, drawn: \(file.path)")
        print("  a split paddle at 120, 240 and 360 wide, with a shot over each turret\n")
    }

    /// The beam and the burn it leaves, drawn so somebody can look at them.
    func testTheLaserBurnCanBeLookedAt() throws {
        let scene = GameScene(size: CGSize(width: 402, height: 500))
        scene.gameMode = .endlessII
        scene.layoutUnit = 18
        scene.ballSize = scene.normalBallSize

        let display = SKScene(size: CGSize(width: 402, height: 500))
        display.backgroundColor = UIColor(red: 0.15, green: 0.04, blue: 0.24, alpha: 1)

        for (index, stage) in ["beam", "burn", "burn, half gone"].enumerated() {
            let node: SKSpriteNode
            switch index {
            case 0: node = scene.endlessIILaserBeamNode()
            default:
                node = scene.endlessIILaserAfterGlowNode()
                if index == 2 { node.alpha *= 0.5 }
            }
            node.size.height = 400
            node.position = CGPoint(x: 90 + 110*CGFloat(index), y: 250)
            node.zPosition = 0
            display.addChild(node)
            _ = stage
        }

        let view = SKView(frame: CGRect(origin: .zero, size: display.size))
        let texture = try XCTUnwrap(view.texture(from: display))
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("round-288.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Round 288, drawn: \(file.path)")
        print("  the beam, the burn it leaves, and the burn half faded\n")
    }

}
