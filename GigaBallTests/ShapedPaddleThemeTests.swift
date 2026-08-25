//
//  ShapedPaddleThemeTests.swift
//  GigaBallTests
//
//  A shaped paddle wears the theme the player chose, and the ways that goes wrong are all
//  quiet. A prefix out of step with `paddleSetting` dresses the paddle as a theme they are not
//  using - which reads as the power-up changing the theme. A name with no artwork behind it
//  gives an invisible paddle. Neither crashes, and neither is obvious in one screenshot of one
//  theme.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class ShapedPaddleThemeTests: XCTestCase {

    private let shapes = ["Convex", "Concave", "Wave", "WedgeLeft", "WedgeRight"]
    private let kinds = ["Paddle", "Lasers", "Sticky"]

    private func scene(theme: Int) -> GameScene {
        let scene = GameScene(size: CGSize(width: 402, height: 874))
        scene.gameMode = .endlessII
        scene.paddleSetting = theme
        return scene
    }

    /// Every theme in the list is a theme the game actually has.
    ///
    /// The prefixes mirror the order `paddleSetting` indexes `paddleTextureArray` by, and that
    /// array is built inside a method where a test cannot reach it. So this asks the next best
    /// thing and the thing that would actually break: that each prefix names a paddle in the
    /// catalogue, and that there are as many of them as there are themes.
    func testEveryThemePrefixNamesARealPaddle() {
        XCTAssertEqual(GameScene.paddleThemePrefixes.count, 12,
                       "twelve themes, and the prefixes are indexed by the same setting")
        XCTAssertEqual(Set(GameScene.paddleThemePrefixes).count, 12, "a prefix is listed twice")

        for prefix in GameScene.paddleThemePrefixes {
            XCTAssertNotNil(UIImage(named: "\(prefix)Paddle"),
                            "\(prefix)Paddle is not in the catalogue, so \(prefix) is not a "
                            + "theme the game has")
        }
    }

    /// Every theme, every shape, every overlay resolves to artwork that exists.
    ///
    /// This is the whole point: 12 x 5 x 3 is 180 names, and one of them missing is a paddle
    /// that draws nothing on one theme with one power-up running.
    func testEveryThemeAndShapeResolvesToArtworkThatExists() {
        for theme in GameScene.paddleThemePrefixes.indices {
            let scene = scene(theme: theme)
            for kind in kinds {
                for shape in shapes {
                    let name = scene.endlessIIThemedShapeArt(kind, shape)
                    XCTAssertNotNil(UIImage(named: name),
                                    "\(GameScene.paddleThemePrefixes[theme]) \(kind) \(shape) "
                                    + "resolved to \(name), which is not in the catalogue")
                }
            }
        }
    }

    /// A theme with its own art uses it, rather than falling back.
    ///
    /// The fallback is what makes a missing picture safe, and it is also what would hide the
    /// whole feature failing: if every theme fell back, every paddle would look right and none
    /// of them would be themed.
    func testAThemeWithItsOwnArtUsesIt() {
        for (index, prefix) in GameScene.paddleThemePrefixes.enumerated() where prefix != "retro" {
            let scene = scene(theme: index)
            XCTAssertEqual(scene.endlessIIThemedShapeArt("Paddle", "Convex"),
                           "\(prefix)PaddleConvex",
                           "\(prefix) has its own shaped paddles and should be wearing them")
        }
    }

    /// Retro has no shaped art yet, and falls back to the plain theme's.
    ///
    /// James, round 248: "I have yet to do retro." A paddle with no texture is an invisible
    /// paddle, so the honest answer is the regular theme's picture rather than nothing.
    func testRetroFallsBackUntilItsArtIsDrawn() {
        guard let retro = GameScene.paddleThemePrefixes.firstIndex(of: "retro") else {
            return XCTFail("retro has left the theme list")
        }
        let scene = scene(theme: retro)
        for shape in shapes {
            for kind in kinds {
                XCTAssertEqual(scene.endlessIIThemedShapeArt(kind, shape),
                               "regular\(kind)\(shape)")
            }
        }
    }

    /// And so does any single picture that is not drawn.
    ///
    /// One is missing from the delivery - outline's concave sticky overlay - and the fallback
    /// is per *picture* rather than per theme for exactly this: outline keeps its own shaped
    /// paddles and borrows one overlay, instead of losing the lot over one file.
    func testASingleMissingPictureFallsBackOnItsOwn() {
        guard let outline = GameScene.paddleThemePrefixes.firstIndex(of: "outline") else {
            return XCTFail("outline has left the theme list")
        }
        let scene = scene(theme: outline)
        XCTAssertEqual(scene.endlessIIThemedShapeArt("Paddle", "Concave"), "outlinePaddleConcave",
                       "the paddle itself is drawn and should be used")
        XCTAssertEqual(scene.endlessIIThemedShapeArt("Sticky", "Concave"), "regularStickyConcave",
                       "and only the one that is missing borrows")
    }

    /// The shaped paddle's own lookup goes through the themed one.
    func testTheShapesTextureNameIsThemedToo() {
        guard let candy = GameScene.paddleThemePrefixes.firstIndex(of: "candy") else {
            return XCTFail("candy has left the theme list")
        }
        let scene = scene(theme: candy)
        XCTAssertEqual(scene.endlessIIPaddleShapeTextureName(.convex), "candyPaddleConvex")
        XCTAssertEqual(scene.endlessIIPaddleShapeTextureName(.wedgeLeft), "candyPaddleWedgeLeft")
        XCTAssertNil(scene.endlessIIPaddleShapeTextureName(.jagged),
                     "Jagged is retired and has no art in any theme")
    }

    /// A setting outside the list is answered rather than trapped.
    ///
    /// `paddleSetting` comes from a user default, which a synced file from a future build could
    /// carry past the end of this list - and a crash on launch for a player who has more themes
    /// than this build does is the worst version of that.
    func testASettingBeyondTheListFallsBackRatherThanCrashing() {
        for setting in [-1, 99] {
            let scene = scene(theme: setting)
            XCTAssertEqual(scene.endlessIIThemedShapeArt("Paddle", "Convex"),
                           "regularPaddleConvex")
        }
    }
}
