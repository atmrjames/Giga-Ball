//
//  PauseSwipeTests.swift
//  GigaBallTests
//
//  James, round 313: "Swipe up to pause is no longer working at all."
//
//  It had not worked since round 312, which added the distance check he asked for - "make the
//  swipe up to pause feature slightly less sensitive. I seem to be accidentally triggering it
//  a lot" - and measured that distance from the gesture recogniser. A discrete recogniser
//  reports where the gesture *began*, so the measured travel was always exactly zero and the
//  guard could never pass. The line meant to tune the feature switched it off, and nothing
//  failed: there was no test here, because there was nothing here a test could hold.
//
//  These tests exist because of the numbers that finding cost. Reproducing it took an
//  instrumented build, a device and a log: a 450-point swipe reported `here` and `start` equal
//  to six decimal places, and the scene's own tracking stopped at **forty points**, because
//  the recogniser cancelled the touch the moment it recognised. Neither party could see the
//  whole gesture. `PauseSwipe` is the rule pulled out where it can be asked without a finger.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class PauseSwipeTests: XCTestCase {

    /// Six ball-widths on the iPad this was measured on.
    private let minimum: CGFloat = 118.6

    // MARK: - The report

    /// A long flick pauses. This is the case that was broken.
    func testALongFlickAsksForThePauseMenu() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        swipe.recognisedAFlick()
        // UIKit recognises about forty points in, well short of the threshold
        swipe.moved(to: -422)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "forty points is not a swipe yet")

        swipe.moved(to: -300)
        swipe.moved(to: -12)
        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum),
                      "and the rest of the flick is what the recogniser never saw")
    }

    /// The other half of round 312's request: a short one does not.
    func testAShortFlickDoesNotPause() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        swipe.recognisedAFlick()
        swipe.moved(to: -422)
        swipe.moved(to: -402)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "sixty points is the accidental trigger he asked to be rid of")
    }

    /// And a long *drag* does not, however far it goes - only a flick counts.
    func testADragThatIsNeverAFlickNeverPauses() {
        var swipe = PauseSwipe()
        swipe.began(at: -462)
        for y in stride(from: -462.0, through: 0.0, by: 20.0) { swipe.moved(to: CGFloat(y)) }

        XCTAssertGreaterThan(swipe.travel, minimum, "it went far enough")
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "but the paddle is moved by dragging, and dragging must not pause")
    }

    // MARK: - The rule

    func testItAsksOncePerTouch() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)

        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum))
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "or every later move of the same finger pauses again")
    }

    /// Downward travel is not travel.
    func testGoingDownIsNotGoingUp() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: -300)

        XCTAssertEqual(swipe.travel, 0)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum))
    }

    /// The distance is the furthest the finger reached, not where it happened to be.
    ///
    /// A flick that overshoots and settles back is still a flick, and the recogniser has
    /// already agreed it was one.
    func testTheDistanceIsTheFurthestItGot() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)
        swipe.moved(to: 250)

        XCTAssertEqual(swipe.travel, 300)
        XCTAssertTrue(swipe.shouldPause(travellingAtLeast: minimum))
    }

    /// A new touch starts from nothing, or the next tap inherits the last swipe's distance.
    func testEachTouchStartsAgain() {
        var swipe = PauseSwipe()
        swipe.began(at: 0)
        swipe.recognisedAFlick()
        swipe.moved(to: 300)
        _ = swipe.shouldPause(travellingAtLeast: minimum)
        swipe.ended()

        XCTAssertEqual(swipe.travel, 0)

        swipe.began(at: 0)
        swipe.moved(to: 300)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum),
                       "the flick belonged to the touch before this one")
    }

    /// A touch the scene never saw begin has no distance to measure from.
    func testATouchWithNoBeginningIsNotASwipe() {
        var swipe = PauseSwipe()
        swipe.recognisedAFlick()
        swipe.moved(to: 300)

        XCTAssertEqual(swipe.travel, 0)
        XCTAssertFalse(swipe.shouldPause(travellingAtLeast: minimum))
    }
}


// MARK: - The scene's own touch handling (round 382)

/// A finger the test puts exactly where it wants, and where it was a moment before.
private final class PlacedTouch: UITouch {
    private let now: CGPoint
    private let before: CGPoint
    init(at now: CGPoint, from before: CGPoint? = nil) {
        self.now = now
        self.before = before ?? now
        super.init()
    }
    override func location(in node: SKNode) -> CGPoint { now }
    override func previousLocation(in node: SKNode) -> CGPoint { before }
}

/// `touchesBegan`, `touchesMoved` and `touchesEnded` on a real, presented scene.
///
/// **From the CRAP pass** (rounds 381 and 382): the three were among the riskiest code in the app
/// - complex, and not reached by a single test - and every paddle movement, launch and pause in
/// all three modes goes through them. `PauseSwipe` above pins the swipe's arithmetic; these pin
/// what the scene does with a finger. A Classic level, because that is the mode with years of
/// scores on it.
final class SceneTouchTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        forgetAnyPausedRun()
        super.tearDown()
    }

    /// Clears the save a pause leaves behind.
    ///
    /// **A paused run is saved so it can be resumed**, and under tests it is saved to the tests'
    /// own settings suite - so the next scene built resumed it. Found in round 383: a Mayhem test
    /// that followed `testASwipeUpPausesWhenItIsOn` was handed that Classic run back, had no Aimed
    /// Sticky to catch with, and failed at its first line. Cleared before every scene and after
    /// every test, so the order the runner chooses cannot decide the result.
    private func forgetAnyPausedRun() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
    }

    private func playing(_ mode: GameMode = .classic) throws -> GameScene {
        forgetAnyPausedRun()
        mode.makeCurrent(in: GameScene.settingsStore)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: GameViewController.self))
        let game = try XCTUnwrap(board.instantiateViewController(withIdentifier: "gameView")
                                 as? GameViewController)
        game.selectedLevel = LevelPackSetup.shared.startLevelNumber[1]
        game.numberOfLevels = 1
        game.levelSender = "MainMenu"
        game.levelPack = 1
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: windowScene)
        let host = UIViewController()
        let view = SKView(frame: window.bounds)
        host.view = view
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        let scene = try XCTUnwrap(GameScene(fileNamed: "GameScene"))
        scene.totalStatsArray = [TotalStats()]
        scene.gameViewControllerDelegate = game
        scene.scaleMode = .aspectFit
        scene.size = view.bounds.size
        view.presentScene(scene)
        RunLoop.main.run(until: Date().addingTimeInterval(2.5))
        for _ in 0..<3 where scene.finishEndlessIIBuildIn() {}
        // Until there is nothing left to skip: a level waiting on its intro is *started* by the
        // first call, and a fixture that stopped there handed every test's first tap to the
        // build-in rather than to the thing being tested
        if !(scene.gameState.currentState is Playing) { scene.gameState.enter(Playing.self) }
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        return scene
    }

    private func drag(_ scene: GameScene, from start: CGPoint, by dx: CGFloat, dy: CGFloat = 0) {
        scene.touchesBegan([PlacedTouch(at: start)], with: nil)
        let end = CGPoint(x: start.x + dx, y: start.y + dy)
        scene.touchesMoved([PlacedTouch(at: end, from: start)], with: nil)
        scene.touchesEnded([PlacedTouch(at: end)], with: nil)
    }

    /// A drag moves the paddle by the finger's travel times the sensitivity, the waiting ball
    /// rides with it, and lifting a finger that dragged does not serve the ball.
    func testADragMovesThePaddleAndTheWaitingBallAndDoesNotServe() throws {
        let scene = try playing()
        XCTAssertTrue(scene.ballIsOnPaddle, "a level starts with the ball on the paddle")
        let before = scene.paddle.position.x
        let offset = scene.ball.position.x - scene.paddle.position.x
        drag(scene, from: CGPoint(x: 70, y: scene.paddle.position.y + 60), by: 20)
        // Off the centre line on purpose: from x = 0, the finger's travel and the sum of where
        // it was and where it went are the same number, and mutation testing found a test that
        // could not tell subtraction from addition (round 382)

        XCTAssertEqual(scene.paddle.position.x, before + 20*scene.paddleMovementFactor,
                       accuracy: 0.01)
        XCTAssertEqual(scene.ball.position.x - scene.paddle.position.x, offset, accuracy: 0.01,
                       "the ball rides the paddle")
        XCTAssertTrue(scene.ballIsOnPaddle, "a drag is not a serve")
    }

    /// A tap that does not move serves the ball.
    func testATapServesTheBall() throws {
        let scene = try playing()
        let spot = CGPoint(x: 0, y: scene.paddle.position.y + 120)
        scene.touchesBegan([PlacedTouch(at: spot)], with: nil)
        scene.touchesEnded([PlacedTouch(at: spot)], with: nil)
        XCTAssertFalse(scene.ballIsOnPaddle, "served")
    }

    /// However far the finger goes, the paddle stays inside the walls.
    func testThePaddleStaysInsideTheWalls() throws {
        let scene = try playing()
        drag(scene, from: CGPoint(x: 0, y: scene.paddle.position.y + 60), by: 2_000)
        let reach = scene.gameWidth/2 - scene.paddle.size.width/2
        XCTAssertLessThanOrEqual(scene.paddle.position.x, reach + 0.5, "right wall")
        drag(scene, from: CGPoint(x: 0, y: scene.paddle.position.y + 60), by: -4_000)
        XCTAssertGreaterThanOrEqual(scene.paddle.position.x, -reach - 0.5, "left wall")
    }

    /// A tap while the level is still building in is spent finishing it, not serving.
    func testATapDuringTheBuildInFinishesItRatherThanServing() throws {
        let scene = try playing()
        scene.endlessIIBuildingIn = true
        let spot = CGPoint(x: 0, y: scene.paddle.position.y + 120)
        scene.touchesBegan([PlacedTouch(at: spot)], with: nil)
        scene.touchesEnded([PlacedTouch(at: spot)], with: nil)
        XCTAssertFalse(scene.endlessIIBuildingIn, "the build-in finished")
        XCTAssertTrue(scene.ballIsOnPaddle, "and the ball waits for a tap of its own")
    }

    /// A long enough swipe up pauses, when swipe-to-pause is on.
    func testASwipeUpPausesWhenItIsOn() throws {
        let scene = try playing()
        let start = CGPoint(x: 0, y: scene.paddle.position.y + 40)
        scene.touchesBegan([PlacedTouch(at: start)], with: nil)
        scene.swipeUpPause = true
        // After the touch goes down, which re-reads the settings: the setting is asked as the
        // finger moves, and writing the player's preferences from a test is not allowed
        scene.pauseSwipe.recognisedAFlick()
        let end = CGPoint(x: 0, y: start.y + scene.pauseSwipeMinimumTravel + 20)
        scene.touchesMoved([PlacedTouch(at: end, from: start)], with: nil)
        XCTAssertTrue(scene.gameState.currentState is Paused, "the swipe paused the run")
    }

    /// And never on a day that takes pausing away.
    func testASwipeUpDoesNothingWhenItIsOff() throws {
        let scene = try playing()
        let start = CGPoint(x: 0, y: scene.paddle.position.y + 40)
        scene.touchesBegan([PlacedTouch(at: start)], with: nil)
        scene.swipeUpPause = false
        // After the touch goes down, which re-reads the settings: the setting is asked as the
        // finger moves, and writing the player's preferences from a test is not allowed
        scene.pauseSwipe.recognisedAFlick()
        let end = CGPoint(x: 0, y: start.y + scene.pauseSwipeMinimumTravel + 20)
        scene.touchesMoved([PlacedTouch(at: end, from: start)], with: nil)
        XCTAssertTrue(scene.gameState.currentState is Playing, "switched off, it is a drag")
    }

    /// A flick of more than a hundred points in one move, with the ball in play, earns Paddle
    /// Speed - and with the ball still waiting on the paddle it does not.
    func testAFastFlickWithTheBallInPlayEarnsPaddleSpeed() throws {
        let scene = try playing()
        let paddleSpeed = 50
        let start = CGPoint(x: -60, y: scene.paddle.position.y + 60)
        scene.touchesBegan([PlacedTouch(at: start)], with: nil)
        scene.touchesMoved([PlacedTouch(at: CGPoint(x: start.x + 150, y: start.y), from: start)],
                           with: nil)
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[paddleSpeed],
                       "not while the ball waits on the paddle")

        scene.releaseBall()
        XCTAssertFalse(scene.ballIsOnPaddle)
        scene.touchesMoved([PlacedTouch(at: CGPoint(x: start.x + 60, y: start.y), from: start)],
                           with: nil)
        XCTAssertFalse(scene.totalStatsArray[0].achievementsUnlockedArray[paddleSpeed],
                       "sixty points is not fast")
        scene.touchesMoved([PlacedTouch(at: CGPoint(x: start.x + 150, y: start.y), from: start)],
                           with: nil)
        XCTAssertTrue(scene.totalStatsArray[0].achievementsUnlockedArray[paddleSpeed],
                      "a hundred and fifty points in one move, with the ball in play")
    }

    /// The pause button does nothing on a day that takes pausing away (No Breaks, round 350).
    func testThePauseButtonDoesNothingOnANoBreaksDay() throws {
        let scene = try playing()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: DailyChallengeSession.shared.todayKey, mode: .classic, classicLevel: 0,
            twists: [.noPausing])
        defer { DailyChallengeSession.shared.active = nil }
        scene.touchesBegan([PlacedTouch(at: scene.pauseButton.position)], with: nil)
        XCTAssertTrue(scene.gameState.currentState is Playing, "no breaks means no breaks")
    }

    // MARK: Aimed Sticky (round 383)
    //
    // James's rules for a ball held by Aimed Sticky, from three rounds of play-testing:
    // round 215, "drag below the paddle moves the paddle. Drag above the paddle moves the arrow
    // relative to the drag. Tap releases the ball"; round 232, "a tap above the paddle moves
    // the arrow to the tap position. A tap below the paddle launches the ball"; and round 275,
    // "if I let my finger go after the ball lands on the paddle, the ball releases. In this
    // case, it should stay on the paddle. It should only release on a tap". All of it lives in
    // the touch handlers, which until now were only driven in Classic.

    /// A Mayhem run with the first ball caught by Aimed Sticky and held for aiming.
    private func aimedHold() throws -> GameScene {
        let scene = try playing(.endlessII)
        scene.releaseBall()
        scene.endlessIICollectAimedSticky()
        scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -300)
        scene.ball.position = CGPoint(x: scene.paddle.position.x, y: scene.paddleTopY + 8)
        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false), "the ball was caught")
        XCTAssertTrue(scene.endlessIIAimHold, "and is held for aiming")
        return scene
    }

    private func tap(_ scene: GameScene, at point: CGPoint) {
        scene.touchesBegan([PlacedTouch(at: point)], with: nil)
        scene.touchesEnded([PlacedTouch(at: point)], with: nil)
    }

    /// "A tap below the paddle launches the ball."
    func testATapBelowThePaddleFiresTheHeldBall() throws {
        let scene = try aimedHold()
        tap(scene, at: CGPoint(x: scene.paddle.position.x, y: scene.paddle.position.y - 30))
        XCTAssertFalse(scene.endlessIIAimHold, "fired")
        XCTAssertFalse(scene.ballIsOnPaddle)
        XCTAssertGreaterThan(scene.ball.physicsBody?.velocity.dy ?? 0, 0, "and upwards")
    }

    /// "A tap above the paddle moves the arrow to the tap position" - and the ball stays, until
    /// a tap below sends it there.
    func testATapAboveThePaddleAimsAndTheNextTapBelowFiresThere() throws {
        let scene = try aimedHold()
        let aim = CGPoint(x: scene.paddle.position.x + 120, y: scene.paddle.position.y + 260)
        tap(scene, at: aim)
        XCTAssertTrue(scene.endlessIIAimHold, "still held")
        XCTAssertTrue(scene.ballIsOnPaddle)
        XCTAssertTrue(scene.endlessIIAimTouched)
        XCTAssertEqual(scene.endlessIIAimTouchX, aim.x, accuracy: 0.01, "the arrow points at the tap")
        XCTAssertEqual(scene.endlessIIAimTouchY, aim.y, accuracy: 0.01)

        tap(scene, at: CGPoint(x: scene.paddle.position.x, y: scene.paddle.position.y - 30))
        let velocity = try XCTUnwrap(scene.ball.physicsBody?.velocity)
        XCTAssertGreaterThan(velocity.dx, 0, "towards the right, where the arrow pointed")
        XCTAssertGreaterThan(velocity.dy, 0)
    }

    /// "Drag below the paddle moves the paddle" - with the held ball on it, still held.
    func testADragBelowThePaddleCarriesItAndTheHeldBall() throws {
        let scene = try aimedHold()
        let before = scene.paddle.position.x
        let offset = scene.ball.position.x - scene.paddle.position.x
        let start = CGPoint(x: 40, y: scene.paddle.position.y - 30)
        scene.touchesBegan([PlacedTouch(at: start)], with: nil)
        scene.touchesMoved([PlacedTouch(at: CGPoint(x: start.x + 30, y: start.y), from: start)],
                           with: nil)
        scene.touchesEnded([PlacedTouch(at: CGPoint(x: start.x + 30, y: start.y))], with: nil)
        XCTAssertEqual(scene.paddle.position.x, before + 30*scene.paddleMovementFactor,
                       accuracy: 0.01)
        XCTAssertEqual(scene.ball.position.x - scene.paddle.position.x, offset, accuracy: 0.5,
                       "the ball comes with it")
        XCTAssertTrue(scene.endlessIIAimHold, "a drag is not a tap, so it is still held")
    }

    /// "If I let my finger go after the ball lands on the paddle ... it should stay on the
    /// paddle. It should only release on a tap."
    func testAFingerAlreadyDownWhenTheBallLandsDoesNotFireOnLift() throws {
        let scene = try playing(.endlessII)
        scene.releaseBall()
        scene.endlessIICollectAimedSticky()
        let finger = CGPoint(x: scene.paddle.position.x, y: scene.paddle.position.y - 30)
        scene.touchesBegan([PlacedTouch(at: finger)], with: nil)
        scene.ball.physicsBody?.velocity = CGVector(dx: 0, dy: -300)
        scene.ball.position = CGPoint(x: scene.paddle.position.x, y: scene.paddleTopY + 8)
        XCTAssertTrue(scene.endlessIIAimedCatch(scene.ball, isExtra: false))
        scene.touchesEnded([PlacedTouch(at: finger)], with: nil)
        XCTAssertTrue(scene.endlessIIAimHold, "the lift ended a paddle move, not a tap")
        XCTAssertTrue(scene.ballIsOnPaddle)
    }

    /// Touching the pause button pauses.
    func testThePauseButtonPauses() throws {
        let scene = try playing()
        let button = scene.pauseButton.position
        scene.touchesBegan([PlacedTouch(at: button)], with: nil)
        XCTAssertTrue(scene.gameState.currentState is Paused)
    }
}
