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


    /// **Retro is complete now** (round 261), which is what the fallback was covering for.
    ///
    /// It was the one theme with no shaped art at all - fifteen pictures - and every shape it
    /// was asked for came back as the regular theme's. James delivered the set, so it answers
    /// for itself, and its three overlay nodes (`retroPaddleTexture` and its laser and sticky)
    /// have shaped pictures too, which no other theme needs.
    func testRetroAnswersForItsOwnShapes() {
        guard let retro = GameScene.paddleThemePrefixes.firstIndex(of: "retro") else {
            return XCTFail("retro has left the theme list")
        }
        let scene = scene(theme: retro)
        for shape in ["Convex", "Concave", "Wave", "WedgeLeft", "WedgeRight"] {
            for kind in ["Paddle", "Lasers", "Sticky", "Grip"] {
                XCTAssertEqual(scene.endlessIIThemedShapeArt(kind, shape),
                               "retro\(kind)\(shape)",
                               "retro is still borrowing the regular theme's \(kind)\(shape)")
            }
            XCTAssertNotNil(UIImage(named: "retroPaddleTexture\(shape)"),
                            "retro's own overlay layer has no \(shape) picture")
        }
    }

    /// **The fallback is still there and there is nothing left for it to catch** (round 261).
    ///
    /// This used to name outline's concave sticky overlay as the missing picture, and James
    /// delivered it; round 258 rewrote it to *find* whichever picture was missing rather than
    /// name one, and it found retro's fifteen. James has now delivered those too, and the grip
    /// set arrived complete across all twelve themes - so there is no gap anywhere and the
    /// finding version had nothing left to assert.
    ///
    /// What is checked instead is the fallback itself, on a name that will never exist: a
    /// theme without a picture borrows the regular theme's rather than showing nothing. That
    /// is the property worth keeping, and it is now the only way to state it.
    func testAThemeWithoutAPictureBorrowsTheRegularOnes() {
        guard let outline = GameScene.paddleThemePrefixes.firstIndex(of: "outline") else {
            return XCTFail("outline has left the theme list")
        }
        let scene = scene(theme: outline)

        XCTAssertNil(UIImage(named: "outlineSpangleConvex"), "the point of the name")
        XCTAssertEqual(scene.endlessIIThemedShapeArt("Spangle", "Convex"),
                       "regularSpangleConvex",
                       "a picture a theme has not got is borrowed, not skipped")

        XCTAssertEqual(scene.endlessIIThemedShapeArt("Paddle", "Convex"), "outlinePaddleConvex",
                       "and everything it has got is still its own")
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
