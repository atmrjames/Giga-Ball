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
