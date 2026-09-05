//
//  PaddleWallClampTests.swift
//  GigaBallTests
//
//  **The wall clamp reaches all three modes, so all three are checked here** (round 302).
//
//  CLAUDE.md's rule: where a fix touches shared mechanics it applies to every mode, and
//  Classic and the original Endless deserve real scrutiny because those are the leaderboards
//  with years of scores on them. Round 300 rewrote the clamp and moved it to a different point
//  in the frame, and until now every test of it was written against Endless Mayhem - the one
//  mode whose leaderboards are new.
//
//  The clamp is deliberately mode-blind. `endlessIIPaddleHalfWidth` is `paddle.size.width/2`,
//  which is true everywhere, and `endlessIIWrapPaddleX` is a plain clamp unless Wrap-Around is
//  running, which needs `gameMode == .endlessII`. So Classic and Endless should behave exactly
//  as they always have, and *that* is the claim worth testing: not that the new code works, but
//  that the old modes cannot tell it changed.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class PaddleWallClampTests: XCTestCase {

    private func scene(_ mode: GameMode) -> GameScene {
        let scene = GameScene()
        scene.gameMode = mode
        scene.gameWidth = 400
        scene.paddle.size = CGSize(width: 100, height: 20)
        scene.totalStatsArray = [TotalStats()]
        return scene
    }

    private let modes: [(String, GameMode)] = [
        ("Classic", .classic), ("Endless", .endless), ("Endless Mayhem", .endlessII)
    ]

    /// The wall holds in every mode, from either side, whether or not the paddle was already
    /// outside it.
    func testThePaddleStopsAtTheWallInEveryMode() {
        for (name, mode) in modes {
            let game = scene(mode)

            for (pushed, expected) in [(CGFloat(500), CGFloat(150)), (-500, -150),
                                       (150, 150), (-150, -150), (0, 0), (100, 100)] {
                game.paddle.position.x = pushed
                game.didEvaluateActions()
                XCTAssertEqual(game.paddle.position.x, expected, accuracy: 0.01,
                               "\(name): a paddle at \(pushed) should sit at \(expected)")
            }
        }
    }

    /// **A paddle that grows at the wall is pulled in, in every mode.**
    ///
    /// This is round 293's report and round 300's fix. Expand animates `xScale` over 0.2s and
    /// SpriteKit evaluates actions *after* `update`, so the correction has to run in
    /// `didEvaluateActions` or it answers for the paddle as it was a frame ago. Expand exists
    /// in all three modes, so the drift did too - it was only ever *reported* in Mayhem
    /// because that is where the laser turrets are drawn on the paddle's ends.
    func testAPaddleThatGrowsAtTheWallIsPulledInInEveryMode() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 150
            // Hard against the wall at 100 wide

            game.paddle.size = CGSize(width: 200, height: 20)
            // What the Expand action will have done by the time actions have been evaluated

            game.didEvaluateActions()
            XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01,
                           "\(name): the grown paddle's end should sit on the wall")
            for (what, node) in [("laser", game.paddleLaser), ("sticky", game.paddleSticky),
                                 ("retro", game.paddleRetroTexture),
                                 ("retro sticky", game.paddleRetroStickyTexture)] {
                XCTAssertEqual(node.position.x, game.paddle.position.x, accuracy: 0.01,
                               "\(name): the \(what) dress should have come with the paddle, "
                               + "not a frame later")
            }
            // **Every strip, not just the lasers** (James, round 305: "sticky paddle graphic,
            // like the laser turrets graphic, is also moving away from the paddle a pixel or
            // two when the paddle is dragged against the edge"). They all hang off
            // `positionPaddleOverlays` and `positionRetroPaddleLayers`, so round 300's move to
            // `didEvaluateActions` fixed the lot - but only the laser was being asserted, which
            // is how a report about the sticky can arrive after the laser is fixed and leave
            // nobody sure whether it is the same bug
        }
    }

    /// **Only Mayhem can leave the walls.**
    ///
    /// Wrap-Around is a Mayhem power-up, and `endlessIIWrapIsRunning` asks the mode as well as
    /// the clock. A collected wrap must not make Classic's or Endless's walls porous - those
    /// are the runs with years of scores behind them, and a paddle that could leave the screen
    /// would be a scoring change, not a visual one.
    func testACollectedWrapCannotOpenTheWallsInTheOldModes() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.endlessIICollectWrapAround()

            game.paddle.position.x = 210
            game.didEvaluateActions()

            if mode == .endlessII {
                XCTAssertEqual(game.paddle.position.x, -190, accuracy: 0.01,
                               "Mayhem: the paddle wraps to the far side")
            } else {
                XCTAssertEqual(game.paddle.position.x, 150, accuracy: 0.01,
                               "\(name): the walls are still walls whatever the clock says")
            }
        }
    }

    /// The clamp is idempotent, which is what makes it safe to run every frame.
    ///
    /// It runs on every frame of every mode now. A clamp that moved the paddle a little each
    /// time it was asked would drag it off the wall over a few seconds of standing still, and
    /// the symptom would be a paddle that creeps - which is exactly the class of bug round 293
    /// and round 300 were both chasing.
    func testRunningTheClampRepeatedlyChangesNothing() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 500
            game.didEvaluateActions()
            let settled = game.paddle.position.x

            for _ in 0..<600 { game.didEvaluateActions() }
            XCTAssertEqual(game.paddle.position.x, settled, accuracy: 0.0001,
                           "\(name): ten seconds of frames at the wall moved the paddle")
        }
    }
    /// **A ball waiting on the paddle has to go where the paddle goes.**
    ///
    /// The clamp moves the paddle on frames where no touch is happening - that is the whole
    /// point of it, since Expand grows a paddle standing still at the wall. But the resting
    /// ball is only re-placed inside `touchesMoved`, so a clamp that nudges the paddle without
    /// carrying the ball leaves the ball behind: it ends up off-centre on the paddle, or in the
    /// worst case beyond its end, and the serve goes somewhere the player did not aim.
    ///
    /// Every mode, because Expand and the waiting ball both exist in all three.
    func testAWaitingBallIsCarriedWhenTheClampMovesThePaddle() {
        for (name, mode) in modes {
            let game = scene(mode)
            game.paddle.position.x = 150
            game.ballIsOnPaddle = true
            game.ballRelativePositionOnPaddle = 20
            game.ball.position.x = game.paddle.position.x + 20

            game.paddle.size = CGSize(width: 200, height: 20)
            game.didEvaluateActions()

            XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01, "\(name): paddle clamped")
            XCTAssertEqual(game.ball.position.x - game.paddle.position.x, 20, accuracy: 0.01,
                           "\(name): the ball kept its place on the paddle rather than being "
                           + "left where the paddle used to be")
        }
    }

    /// **And the aim point rides the paddle too.**
    ///
    /// Round 275: "when moving the paddle the aim arrow can snap down to a low angle." The aim
    /// is kept as the point the finger last pointed at and the angle is measured from the ball
    /// to it, so a ball that walks out from under a stationary point swings the arrow - and
    /// once the ball is nearly level with the point, the angle flattens to the clamp. The touch
    /// handler carries the point by however far the paddle actually went; a clamp that moves
    /// the paddle for a different reason has to do the same, or a resize at the wall does
    /// exactly what dragging used to.
    func testTheAimPointRidesAClampedPaddle() {
        let game = scene(.endlessII)
        game.paddle.position.x = 150
        game.endlessIIAimHold = true
        game.endlessIIAimTouched = true
        game.endlessIIAimTouchX = 160

        game.paddle.size = CGSize(width: 200, height: 20)
        game.didEvaluateActions()

        XCTAssertEqual(game.paddle.position.x, 100, accuracy: 0.01)
        XCTAssertEqual(game.endlessIIAimTouchX, 110, accuracy: 0.01,
                       "the aim point moved by the same 50 the paddle did, so the angle held")
    }

    /// A clamp that changes nothing must not drag the ball or the aim with it.
    ///
    /// The early return is what guarantees that, and it is worth a test of its own: the guard
    /// is the only thing standing between "runs every frame" and "writes to the ball every
    /// frame", and a later edit that moved work above it would be silent.
    func testAClampThatDoesNothingTouchesNothing() {
        let game = scene(.endlessII)
        game.paddle.position.x = 40
        game.ballIsOnPaddle = true
        game.ballRelativePositionOnPaddle = 20
        game.ball.position.x = 999
        // Somewhere the clamp would have to write over if it ran

        game.endlessIIAimHold = true
        game.endlessIIAimTouched = true
        game.endlessIIAimTouchX = 55

        game.didEvaluateActions()

        XCTAssertEqual(game.paddle.position.x, 40, accuracy: 0.01, "nothing to clamp")
        XCTAssertEqual(game.ball.position.x, 999, accuracy: 0.01,
                       "so the ball was not written to at all")
        XCTAssertEqual(game.endlessIIAimTouchX, 55, accuracy: 0.01, "nor the aim")
    }

}

/// Where the sticky band actually sits relative to the paddle, at the wall (round 310).
///
/// James has now reported this three times, and round 308's answer - "every strip hangs off the
/// same two functions, so round 300 fixed them all" - was checked by asserting that their
/// `position.x` values match. They do. So either the report is about something other than
/// position, or something outside those two functions moves one of them.
///
/// Measured rather than argued about.
final class StickyBandAlignmentTests: XCTestCase {

    private func scene() -> GameScene {
        let game = GameScene()
        game.gameMode = .endlessII
        game.gameWidth = 400
        game.ballSize = 10
        game.paddleWidth = 100
        game.paddle.size = CGSize(width: 100, height: 20)
        game.paddleSticky.size = CGSize(width: 100, height: 11)
        game.totalStatsArray = [TotalStats()]
        return game
    }

    func testTheBandAndThePaddleShareACentreAtTheWall() {
        let game = scene()
        game.paddle.position.x = 500
        game.didEvaluateActions()

        print(String(format: "\n  at the wall: paddle x %.2f w %.2f | sticky x %.2f w %.2f",
                     game.paddle.position.x, game.paddle.size.width,
                     game.paddleSticky.position.x, game.paddleSticky.size.width))
        print(String(format: "  paddle frame %@\n  sticky frame %@\n",
                     NSCoder.string(for: game.paddle.frame),
                     NSCoder.string(for: game.paddleSticky.frame)))

        XCTAssertEqual(game.paddleSticky.position.x, game.paddle.position.x, accuracy: 0.01)
        XCTAssertEqual(game.paddleSticky.frame.midX, game.paddle.frame.midX, accuracy: 0.01,
                       "the drawn band and the drawn paddle share a centre line")
    }

    /// **The edges, not the centre** (round 310).
    ///
    /// James's fourth report says the band is "misaligning from the paddle graphic when hit
    /// against the side wall". Three rounds have answered the centre-line question and the
    /// centre lines match; what nobody had measured is the *edges*, and at the wall the edges
    /// are the only place an eye has a reference to judge against - a band a point or two wider
    /// than the paddle shows that difference against the wall and nowhere else.
    ///
    /// Expand and Shrink are `scaleX` actions run separately on the paddle and on each strip,
    /// so a mismatch could come from a size that did not follow a resize as well as from a
    /// scale that did not.
    func testTheBandAndThePaddleShareTheirEdgesAtTheWall() {
        for scale in [1.0, 1.5, 0.5] as [CGFloat] {
            let game = scene()
            game.paddle.xScale = scale
            game.paddleSticky.xScale = scale
            game.paddleLaser.xScale = scale
            game.paddle.position.x = 500
            game.didEvaluateActions()

            let paddle = game.paddle.frame
            let sticky = game.paddleSticky.frame
            print(String(format: "  scale %.2f | paddle %.2f...%.2f | sticky %.2f...%.2f",
                         scale, paddle.minX, paddle.maxX, sticky.minX, sticky.maxX))

            XCTAssertEqual(sticky.minX, paddle.minX, accuracy: 0.01,
                           "left edges, at scale \(scale)")
            XCTAssertEqual(sticky.maxX, paddle.maxX, accuracy: 0.01,
                           "right edges, at scale \(scale)")
        }
    }

    /// **The overlays follow a paddle that something else moved** (round 311).
    ///
    /// James, four reports running: the sticky band and the laser turrets sit a point or two off
    /// the paddle while it is held against a wall. Three rounds measured positions and found
    /// them identical, because every *writer* of `paddle.position.x` re-places the overlays in
    /// the same breath. The mover nobody had counted is the physics engine: the paddle is a
    /// dynamic body that collides with the border, so the solver pushes it out of the wall after
    /// `touchesMoved` and after `didEvaluateActions` have both had their say.
    ///
    /// The paddle is moved here the way the solver moves it - directly, behind everybody's back
    /// - and `didFinishUpdate` is the frame's last word before it is drawn.
    func testTheOverlaysFollowAPaddleMovedBehindTheirBack() {
        let game = scene()
        game.paddle.position.x = 120
        game.positionPaddleOverlays()
        XCTAssertEqual(game.paddleSticky.position.x, 120, accuracy: 0.01, "placed to begin with")

        game.paddle.position.x = 118.4
        // 1.6 points, which is the size of the penetration a solver resolves at a wall

        XCTAssertEqual(game.paddleSticky.position.x, 120, accuracy: 0.01,
                       "and this is the bug: the band is still where the paddle used to be")

        game.didFinishUpdate()
        XCTAssertEqual(game.paddleSticky.position.x, game.paddle.position.x, accuracy: 0.01,
                       "the band follows before the frame is drawn")
        XCTAssertEqual(game.paddleLaser.position.x, game.paddle.position.x, accuracy: 0.01,
                       "and so does the laser strip, which is the same report")
    }

    /// Every strip, not only the two the report named.
    func testEveryStripFollows() {
        let game = scene()
        game.paddle.position.x = 60
        game.positionPaddleOverlays()
        game.positionRetroPaddleLayers()

        game.paddle.position.x = 57.5
        game.didFinishUpdate()

        for (name, node) in [("sticky", game.paddleSticky), ("laser", game.paddleLaser),
                             ("retro", game.paddleRetroTexture),
                             ("retro laser", game.paddleRetroLaserTexture),
                             ("retro sticky", game.paddleRetroStickyTexture)] {
            XCTAssertEqual(node.position.x, game.paddle.position.x, accuracy: 0.01, name)
        }
    }

    /// And a frame where nothing moved costs one comparison and writes nothing.
    ///
    /// Worth a test of its own: this runs on every frame of every mode, so a version of it that
    /// re-placed the strips unconditionally would put `refreshEndlessIISplitDress` on the hot
    /// path for the whole game rather than for the frames where the paddle actually moved.
    func testAStillPaddleCostsNothing() {
        let game = scene()
        game.paddle.position.x = 42
        game.positionPaddleOverlays()
        let before = game.paddleSticky.position
        game.didFinishUpdate()
        XCTAssertEqual(game.paddleSticky.position.x, before.x, accuracy: 0.0001)
        XCTAssertEqual(game.paddleSticky.position.y, before.y, accuracy: 0.0001)
    }

    /// **What the retro paddle's six scale factors actually are** (round 310).
    ///
    /// Expand and Shrink run six `scaleX` actions. The plain paddle and its two strips go to
    /// 0.5, 0.75, 1.0, 1.5, 2.0, 2.5; the three retro layers go to 0.59, 0.79, 1.0, 1.42, 1.82,
    /// 2.24. Those look eyeballed and are not: with `paddleRetroTexture.size.width` set to
    /// `paddleWidth*1.22`, every one of them is `(plainScale + 0.22)/1.22` to within 0.01, which
    /// is the rule "the retro artwork is the paddle's width plus a fixed margin, and the margin
    /// does not grow with it".
    ///
    /// **Written down because it took an hour to work out twice.** The numbers read like a
    /// mistake, the fourth report of a misaligned sticky band pointed straight at them, and the
    /// conclusion "the retro paddle is drawn too narrow when expanded" is wrong. What is left is
    /// the rounding: the retro layers are set to two decimal places rather than computed, which
    /// is up to 0.011 of scale - **about a point and a half on a hundred-point paddle** at the
    /// widest step, and the largest single misalignment anyone has measured on this paddle.
    /// Whether that is what James is seeing is his to say; it is the right size for "a pixel or
    /// two" and it is not enough to act on alone.
    func testTheRetroScaleFactorsFollowTheFixedMarginRule() {
        let margin: CGFloat = 0.22
        let steps: [(plain: CGFloat, retro: CGFloat)] =
            [(0.5, 0.59), (0.75, 0.79), (1.0, 1.0), (1.5, 1.42), (2.0, 1.82), (2.5, 2.24)]

        var worst: CGFloat = 0
        for step in steps {
            let wanted = (step.plain + margin)/(1 + margin)
            let drift = abs(step.retro - wanted)
            worst = max(worst, drift)
            print(String(format: "  plain %.2f | retro %.2f | rule %.4f | out by %.4f "
                         + "(%.2fpt on a 100pt paddle)",
                         step.plain, step.retro, wanted, drift, drift*100*(1 + margin)))
            XCTAssertEqual(step.retro, wanted, accuracy: 0.012,
                           "the retro factor for \(step.plain) follows the fixed-margin rule")
        }
        XCTAssertLessThan(worst*100*(1 + margin), 2.0,
                          "and no step is more than two points out on a hundred-point paddle")
    }

    /// A strip whose scale was not taken along by a resize is the other half of that question.
    ///
    /// Expand runs six separate `scaleX` actions - the paddle, the two strips and the three
    /// retro layers - and the retro three deliberately go to a different number. What must
    /// never happen is the *visible* pair disagreeing: a plain paddle at 1.5 with a band still
    /// at 1.0 is a band two thirds the width of what it is meant to be covering.
    func testAStripLeftBehindByAResizeIsCaught() {
        let game = scene()
        game.paddle.xScale = 1.5
        game.paddleSticky.xScale = 1.0
        game.paddle.position.x = 500
        game.didEvaluateActions()

        XCTAssertNotEqual(game.paddleSticky.frame.width, game.paddle.frame.width,
                          accuracy: 0.01,
                          "the check has to be able to see a mismatch, or it proves nothing")
    }

    /// And after an Expand, which is when the clamp actually does something.
    func testTheBandFollowsThroughAResizeAtTheWall() {
        let game = scene()
        game.paddle.position.x = 150

        game.paddle.size = CGSize(width: 200, height: 20)
        game.paddleSticky.size = CGSize(width: 200, height: 11)
        game.didEvaluateActions()

        print(String(format: "\n  after expand: paddle x %.2f | sticky x %.2f | midX %.2f vs %.2f\n",
                     game.paddle.position.x, game.paddleSticky.position.x,
                     game.paddle.frame.midX, game.paddleSticky.frame.midX))

        XCTAssertEqual(game.paddleSticky.frame.midX, game.paddle.frame.midX, accuracy: 0.01,
                       "a grown paddle takes its band with it")
    }
    /// **Draw it, because three rounds of arithmetic have said it is fine.**
    ///
    /// The frames are concentric and the positions match, so whatever James is seeing is not
    /// where these nodes *are*. The remaining candidates are all about what is inside them -
    /// the art, the nine-slice, the relative widths - and none of those can be reasoned about
    /// from numbers. Each theme's paddle with its sticky band over it, at the wall.
    func testTheStickyBandOverThePaddleCanBeLookedAt() throws {
        let themes = ["regularPaddle", "3DPaddle", "outlinePaddle"]
        let stickies = ["regularSticky", "3DSticky", "outlineSticky"]
        // The asset names, taken from the `SKTexture(imageNamed:)` lines rather than guessed -
        // the first version of this test guessed and rendered SpriteKit's missing-texture
        // placeholder, which looks enough like art to be believed for a moment
        let width: CGFloat = 150, height: CGFloat = 44

        let scene = SKScene(size: CGSize(width: width + 40,
                                         height: (height + 10)*CGFloat(themes.count) + 10))
        scene.backgroundColor = UIColor(red: 0.09, green: 0, blue: 0.14, alpha: 1)

        for (row, (paddleArt, stickyArt)) in zip(themes, stickies).enumerated() {
            let y = scene.size.height - (height + 10)*CGFloat(row) - height/2 - 10

            let paddle = SKSpriteNode(texture: SKTexture(imageNamed: paddleArt))
            paddle.size = CGSize(width: width, height: 14)
            paddle.centerRect = GameScene.paddleCapRect
            paddle.position = CGPoint(x: 20 + width/2, y: y)
            paddle.zPosition = 1
            scene.addChild(paddle)

            let band = SKSpriteNode(texture: SKTexture(imageNamed: stickyArt))
            band.size = CGSize(width: width, height: 11)
            band.centerRect = GameScene.paddleStickyCapRect
            band.anchorPoint = CGPoint(x: 0.5, y: 0)
            band.position = CGPoint(x: paddle.position.x, y: y - 7)
            band.zPosition = 4
            scene.addChild(band)
            // Exactly what `positionPaddleOverlays` does: same x, the band anchored at its
            // bottom on the paddle's underside
        }

        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        let texture = try XCTUnwrap(view.texture(from: scene),
                                    "no renderer here, so there is nothing to look at")
        let file = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("sticky-band.png")
        try XCTUnwrap(UIImage(cgImage: texture.cgImage()).pngData()).write(to: file)
        print("\n  Paddle with its sticky band, three themes: \(file.path)\n")
    }

}
