//
//  GameSceneLayoutTests.swift
//  GigaBallTests
//
//  The play area holds the same shape on every device. That is a promise the game makes to
//  anybody who plays it on both a phone and an iPad, and to everybody whose high scores were
//  set on a layout the next release must not quietly change.
//
//  It was arithmetic buried in `computeLayoutMetrics`, where the only way to check it was to
//  run the game and look. Now that the background picker draws a scale model of the same
//  layout, the maths has somewhere to live that can be asked questions.
//

import XCTest
@testable import Giga_Ball

final class GameSceneLayoutTests: XCTestCase {

    /// A spread of real screens, small to large, plus a couple of awkward shapes.
    private let screens: [(name: String, size: CGSize, inset: CGFloat)] = [
        ("iPhone SE", CGSize(width: 375, height: 667), 0),
        ("iPhone 13 mini", CGSize(width: 375, height: 812), 34),
        ("iPhone 17 Pro", CGSize(width: 402, height: 874), 34),
        ("iPhone 17 Pro Max", CGSize(width: 440, height: 956), 34),
        ("iPad mini", CGSize(width: 744, height: 1133), 20),
        ("iPad Pro 12.9", CGSize(width: 1024, height: 1366), 20)
    ]

    func testThePlayAreaKeepsItsRatioOnEveryScreen() {
        for screen in screens {
            let layout = GameSceneLayout(screen: screen.size, bottomInset: screen.inset)
            let ratio = layout.playHeight/layout.gameWidth
            XCTAssertEqual(ratio, GameSceneLayout.playRatio, accuracy: 0.0001, screen.name)
        }
    }

    /// The height taken by the bar plus the play area is the height there was to give, which
    /// is what the closed-form solve in the initialiser is for.
    func testTheBarAndThePlayAreaFillTheScreen() {
        for screen in screens where screen.size.width <= 500 {
            // Wide screens are clamped to their width instead, and are checked below
            let layout = GameSceneLayout(screen: screen.size, bottomInset: screen.inset)
            let used = layout.topBarHeight + layout.playHeight + screen.inset
            XCTAssertEqual(used, screen.size.height, accuracy: 0.01, screen.name)
        }
    }

    func testAWideScreenFallsBackToTallerBordersRatherThanAWiderField() {
        // A short, wide window would otherwise ask for a play area wider than the screen. It
        // gives up height instead, because the ratio is the thing that cannot move
        let layout = GameSceneLayout(screen: CGSize(width: 400, height: 2000))
        XCTAssertLessThanOrEqual(layout.gameWidth, 400)
        XCTAssertEqual(layout.gameWidth, 400, accuracy: 0.01)
        XCTAssertEqual(layout.playHeight/layout.gameWidth, GameSceneLayout.playRatio,
                       accuracy: 0.0001)
    }

    func testTheEndlessIIBarBuysAWiderField() {
        // The ring HUD carries its timers around the icons rather than on bars beneath them,
        // so its bar is shorter - and a shorter bar makes the field both taller and wider,
        // which is the reason for having two figures at all
        let size = CGSize(width: 402, height: 874)
        let classic = GameSceneLayout(screen: size, bottomInset: 34)
        let endlessII = GameSceneLayout(screen: size, bottomInset: 34,
                                        hudUnits: GameSceneLayout.endlessIIHudUnits)

        XCTAssertGreaterThan(endlessII.gameWidth, classic.gameWidth)
        XCTAssertLessThan(endlessII.topBarHeight, classic.topBarHeight)
        XCTAssertEqual(endlessII.playHeight/endlessII.gameWidth, GameSceneLayout.playRatio,
                       accuracy: 0.0001)
    }

    func testTheWallsAreNeverThinnerThanAPhysicsBodyNeeds() {
        // A wall of zero width gets no physics body, and the line that configures one force
        // unwraps it. The surplus runs off the edge of the screen, which costs nothing
        for screen in screens {
            let layout = GameSceneLayout(screen: screen.size, bottomInset: screen.inset)
            XCTAssertGreaterThanOrEqual(layout.wallThickness,
                                        GameSceneLayout.minimumWallThickness, screen.name)
        }
    }

    func testABrickIsTwiceAsWideAsItIsTall() {
        let layout = GameSceneLayout(screen: CGSize(width: 402, height: 874), bottomInset: 34)
        XCTAssertEqual(layout.brickWidth, layout.brickHeight*2, accuracy: 0.0001)
        XCTAssertEqual(layout.brickWidth*CGFloat(GameSceneLayout.brickColumns),
                       layout.gameWidth, accuracy: 0.0001)
        XCTAssertEqual(layout.brickHeight*CGFloat(GameSceneLayout.brickRows),
                       layout.gameWidth, accuracy: 0.0001)
    }

    func testAScreenWithNoRoomProducesNothingRatherThanSomethingNegative() {
        // The mock-up asks for a layout before the view has been given a size
        let layout = GameSceneLayout(screen: .zero)
        XCTAssertEqual(layout.gameWidth, 0)
        XCTAssertEqual(layout.playHeight, 0)
    }
}

/// Which plane each part of the scene draws in.
///
/// James, round 207, with a screenshot: "with clear and retreat I can see bricks in the power
/// up HUD area. These should be out of view."
///
/// The strip across the top of the screen is opaque and exists to be the thing bricks go
/// behind, but the loop that gives the three strips their physics bodies also set their
/// zPosition to 1 - the same plane bricks are created in, in all five places that create one.
/// SpriteKit breaks a tie by which node was added first, and the strips come from the scene
/// file while bricks are added during play, so the bricks were always in front. Nothing put a
/// brick in the strip until Clear And Retreat lifted the field two rows, which is why it took
/// this long to see.
///
/// These are ordering facts rather than geometry, so they are checked as arithmetic: the
/// numbers themselves can move, and what must not is which side of which the planes are on.
final class ScenePlaneTests: XCTestCase {

    /// The tallest thing the field can draw: a brick at 1 wearing a child at 4 - a power-up
    /// brick's icon (`EndlessIIPowerUpBricks`), the deepest of them. A child's zPosition is
    /// relative to its parent, so what the strip has to clear is the sum, not the brick.
    private let tallestThingInTheField: CGFloat = 1 + 4

    func testTheScreenMaskCoversEverythingTheFieldCanDraw() {
        XCTAssertGreaterThan(GameScene.screenMaskPlane, tallestThingInTheField,
                             "a lifted brick draws over the strip that is meant to hide it")
    }

    func testTheHudClearsTheMaskThatWouldOtherwiseCoverIt() {
        for plane in [GameScene.hudTrayPlane, GameScene.hudIconPlane, GameScene.hudTimerPlane] {
            XCTAssertGreaterThan(plane, GameScene.screenMaskPlane,
                                 "the strip is opaque - the HUD has to be in front of it")
        }
    }

    /// James, round 210: "the power-up HUD container in Endless Mayhem has disappeared. The
    /// area above the game view is now just solid purple."
    ///
    /// The ring bar's capsule is a child at `zPosition = -1`, so it sits a whole plane below
    /// the node that owns it - and round 207 raised the HUD without counting that, leaving the
    /// container under the mask. The rings themselves were never affected, which is why an
    /// empty Mayhem strip looked right: with nothing running there are no rings to notice were
    /// still there. What the HUD's *deepest* part clears is the thing to assert.
    func testEvenTheDeepestPartOfTheHudClearsTheMask() {
        for plane in [GameScene.hudTrayPlane, GameScene.hudIconPlane, GameScene.hudTimerPlane] {
            XCTAssertGreaterThan(plane + GameScene.hudLowestChildOffset,
                                 GameScene.screenMaskPlane,
                                 "a HUD child drawn behind its own parent falls under the strip")
        }
    }

    func testTheHudKeepsItsOwnOrder() {
        // Tray behind icons behind timer bars, which is what it was at 2, 3 and 4
        XCTAssertLessThan(GameScene.hudTrayPlane, GameScene.hudIconPlane)
        XCTAssertLessThan(GameScene.hudIconPlane, GameScene.hudTimerPlane)
    }

    /// An empty bar still has to be drawn: "the container never narrows past this, so an empty
    /// one still reads as the place power-ups appear rather than as nothing at all."
    func testTheMayhemBarIsDrawnEvenWithNothingRunning() {
        let hud = PowerUpRingHUD()
        hud.iconSize = 30
        hud.spacing = 12
        hud.update(with: [])
        XCTAssertNotNil(hud.containerForTesting.path,
                        "an empty Mayhem HUD draws no bar at all")
    }

    /// And the bar is drawn *behind* the node that owns it, which is exactly why round 207's
    /// raise buried it under the mask. The constant the planes leave room for has to keep
    /// matching the real child, or the headroom is arithmetic about nothing.
    func testTheBarSitsBehindTheRingsByTheAmountThePlanesAllowFor() {
        XCTAssertEqual(PowerUpRingHUD().containerForTesting.zPosition,
                       GameScene.hudLowestChildOffset)
    }

    func testNothingReachesTheLabelsAndTheAimMarker() {
        // The pause button, the score, the lives and the aim marker sit at 9 and 10 and have
        // always been in front of everything. The score and the pause button share the strip
        // with the HUD, so this is the one that would show if a plane were raised too far
        XCTAssertLessThan(GameScene.hudTimerPlane, 9)
    }
}

