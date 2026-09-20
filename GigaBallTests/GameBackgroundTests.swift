//
//  GameBackgroundTests.swift
//  GigaBallTests
//
//  The background a player chose has to still be the background they chose after an update.
//  The setting is stored as a bare integer in `UserDefaults`, so the order of these cases is
//  part of the save format whether anybody meant it to be or not.
//

import XCTest
@testable import Giga_Ball

final class GameBackgroundTests: XCTestCase {

    func testTheStoredOrderNeverChanges() {
        // These numbers are in every player's UserDefaults. Reordering the enum would move
        // somebody who chose Gradient onto Solid
        XCTAssertEqual(GameBackground.classic.rawValue, 0)
        XCTAssertEqual(GameBackground.solid.rawValue, 1)
        XCTAssertEqual(GameBackground.gradient.rawValue, 2)
        XCTAssertEqual(GameBackground.black.rawValue, 3)
    }

    func testAnUnrecognisedSettingFallsBackToClassic() {
        // What a removed background looks like from an older build's saved setting, and what
        // a defaults value that was never written looks like at any time
        XCTAssertEqual(GameBackground.stored(-1), .classic)
        XCTAssertEqual(GameBackground.stored(99), .classic)
        XCTAssertEqual(GameBackground.stored(0), .classic)
        XCTAssertEqual(GameBackground.stored(2), .gradient)
    }

    func testEveryBackgroundHasAName() {
        for background in GameBackground.allCases {
            XCTAssertFalse(background.name.isEmpty, "\(background)")
            XCTAssertFalse(background.summary.isEmpty, "\(background)")
        }
    }

    func testTheSettingsRowListsExactlyWhatThePickerOffers() {
        // Two lists of backgrounds that could disagree is the thing this was refactored to
        // stop happening. In the picker's order since round 329d, which is the order a player
        // sees rather than the order the artwork was drawn in
        XCTAssertEqual(LevelPackSetup().backgroundNameArray,
                       GameBackground.inDisplayOrder.map(\.name))
    }

    /// The picker's order holds every background exactly once.
    ///
    /// **A second list of the same things is the trap this whole type exists to avoid**, and
    /// `inDisplayOrder` is one - it has to be, because `rawValue` is a stored setting and
    /// cannot be renumbered. So the one thing a second list can get wrong is asserted here: a
    /// background left out of it would simply never be offered, which from the outside looks
    /// exactly like a background that was removed.
    func testThePickersOrderHoldsEveryBackgroundOnce() {
        XCTAssertEqual(Set(GameBackground.inDisplayOrder), Set(GameBackground.allCases))
        XCTAssertEqual(GameBackground.inDisplayOrder.count, GameBackground.allCases.count)
        for background in GameBackground.allCases {
            XCTAssertEqual(GameBackground.inDisplayOrder[background.displayIndex], background,
                           "\(background) does not sit where it says it sits")
        }
    }

    /// James's order, round 329d, written out as he wrote it - with round 334's Sunset in the
    /// place the reasoning behind that order puts it: with the other deep colours, after the
    /// green, before the pictures.
    func testTheOrderIsTheOneJamesAskedFor() {
        XCTAssertEqual(GameBackground.inDisplayOrder.map(\.name),
                       ["Classic", "Solid", "Black", "Deep Purple", "Deep Blue", "Deep Green",
                        "Sunset", "Starry Sky", "Glow", "Clouds", "Prism"])
    }

    func testOnlyClassicWearsTheScenesOwnArtwork() {
        // Classic *is* the background node's texture, so the scene paints it by leaving the
        // node alone. The drawn ones sit at whatever size the playfield turns out to be, and
        // round 131's two are pictures of their own drawn over the top - which is why
        // `picture` carries a name and `artwork` does not
        for background in GameBackground.allCases {
            switch background.paint {
            case .artwork:
                XCTAssertEqual(background, .classic)
            case .picture(let named):
                XCTAssertNotEqual(background, .classic)
                XCTAssertNotNil(UIImage(named: named),
                                "\(background.name) names an asset that is not in the bundle")
            case .solid, .gradient, .glow, .clouds, .greenGradient, .sunsetGradient:
                XCTAssertNotEqual(background, .classic)
            }
        }
    }

    /// Every background the picker offers has to be one the game can actually paint - a name
    /// in the list with no picture behind it is a black screen with a title.
    func testEveryBackgroundNamesSomethingAndIsListedOnce() {
        let names = GameBackground.allCases.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "two backgrounds share a name")
        XCTAssertTrue(names.contains("Deep Blue"))
        XCTAssertTrue(names.contains("Starry Sky"))
    }

    func testTheGradientTurnsAtThePaddle() {
        // Three stops, and the middle one is pinned to where the paddle sits rather than to
        // the halfway mark - the field is lifted above it and falls away below
        let stops = GameBackground.gradientStops(paddleFraction: 0.25)
        XCTAssertEqual(stops.colours.count, 3)
        XCTAssertEqual(stops.locations, [0, 0.75, 1])

        XCTAssertEqual(stops.colours[0], GameBackground.borderPurple)
        XCTAssertEqual(stops.colours[1], GameBackground.purple)
        XCTAssertEqual(stops.colours[2], GameBackground.deepPurple)
    }

    func testTheGradientSurvivesAPaddleOutsideTheBackground() {
        // The mock-up works the fraction out for a screen it is not being shown on, and a
        // gradient with stops out of order does not draw at all
        for fraction in [CGFloat(-3), -0.001, 0, 1, 1.5] {
            let stops = GameBackground.gradientStops(paddleFraction: fraction)
            XCTAssertEqual(stops.locations.count, stops.colours.count)
            XCTAssertEqual(stops.locations, stops.locations.sorted(), "\(fraction)")
            XCTAssertGreaterThanOrEqual(stops.locations[1], 0, "\(fraction)")
            XCTAssertLessThanOrEqual(stops.locations[1], 1, "\(fraction)")
        }
    }

    func testTheGradientRefusesToDrawAtNoSize() {
        XCTAssertNil(GameBackground.gradientImage(size: .zero, paddleFraction: 0.3))
        XCTAssertNil(GameBackground.gradientImage(size: CGSize(width: 10, height: 0),
                                                  paddleFraction: 0.3))
    }

    func testTheGlowSitsHighAndOffCentre() {
        // Play-test round 21 asked for it in the top half and not centred: a haze in the
        // middle of the field reads as a vignette and sits under every brick equally
        let first = GameBackground.glowPools[0]
        XCTAssertLessThan(first.centre.y, 0.5, "it belongs in the upper half")
        XCTAssertNotEqual(first.centre.x, 0.5, "and not down the middle")
    }

    func testTheGlowIsTwoPoolsOnADiagonal() {
        // Play-test round 126 asked for the Glow to be improved. One pool lit a corner and
        // left the rest flat; two put a diagonal across the field, the way the Classic
        // artwork does - so the second must be on the other side and lower, and quieter
        XCTAssertEqual(GameBackground.glowPools.count, 2)
        let (near, far) = (GameBackground.glowPools[0], GameBackground.glowPools[1])
        XCTAssertGreaterThan(far.centre.x, near.centre.x)
        XCTAssertGreaterThan(far.centre.y, near.centre.y)
        XCTAssertLessThan(far.strength, near.strength)
    }

    func testTheHazeIsDrawnOnItsOwnSoItCanBreathe() {
        // Split from the gradient in round 144: on a node of its own the scene can swell and
        // settle it, which a baked picture cannot do
        XCTAssertNotNil(GameBackground.hazeImage(size: CGSize(width: 60, height: 100)))
        XCTAssertNil(GameBackground.hazeImage(size: .zero))
        XCTAssertGreaterThan(GameBackground.glowBreath, 4,
                             "slow enough to be felt rather than watched")
        XCTAssertLessThan(GameBackground.glowBreathDepth, 0.35, "and shallow")
    }

    // MARK: - Clouds

    // Play-test round 126: "Dynamic cloud game background".

    func testCloudsAreTwoLayersAtTwoSpeeds() {
        // Parallax is what makes a flat picture read as depth, and the nearer, faster layer
        // is the fainter one or it becomes the thing you are looking at
        XCTAssertEqual(GameBackground.cloudLayers.count, 2)
        let (far, near) = (GameBackground.cloudLayers[0], GameBackground.cloudLayers[1])
        XCTAssertLessThan(near.crossing, far.crossing)
        XCTAssertLessThan(near.strength, far.strength)
    }

    func testACloudLayerIsTheSameStripEveryTime() {
        // Seeded, like the haze: a background that reshuffled itself on a resize would
        // change shape when the phone is rotated
        let size = CGSize(width: 70, height: 120)
        let layer = GameBackground.cloudLayers[0]
        let first = GameBackground.cloudImage(size: size, seed: layer.seed,
                                              blobs: layer.blobs, tint: layer.colour,
                                              strength: layer.strength)
        let again = GameBackground.cloudImage(size: size, seed: layer.seed,
                                              blobs: layer.blobs, tint: layer.colour,
                                              strength: layer.strength)
        XCTAssertEqual(first?.pngData(), again?.pngData())
        XCTAssertNil(GameBackground.cloudImage(size: .zero, seed: layer.seed,
                                               blobs: layer.blobs, tint: layer.colour,
                                               strength: layer.strength))
    }

    func testCloudsHaveAStillPictureForThePicker() {
        // Nothing on the picker moves, so it draws one frame of the drift - a cloud
        // background shown there as a plain gradient would be a picker lying about what you
        // are choosing
        XCTAssertNotNil(GameBackground.cloudsImage(size: CGSize(width: 50, height: 90),
                                                   paddleFraction: 0.3))
    }

    func testTheGlowIsTheSamePictureEveryTimeItIsDrawn() {
        // The scatter is seeded, not random. A background that reshuffled itself whenever
        // the scene resized would twinkle when the phone is rotated
        let first = GameBackground.glowImage(size: CGSize(width: 80, height: 140),
                                             paddleFraction: 0.3)
        let again = GameBackground.glowImage(size: CGSize(width: 80, height: 140),
                                             paddleFraction: 0.3)
        XCTAssertEqual(first?.pngData(), again?.pngData())
    }

    func testTheGlowStillDrawsWhereTheGradientWould() {
        XCTAssertNotNil(GameBackground.glowImage(size: CGSize(width: 40, height: 70),
                                                 paddleFraction: 0.25))
        XCTAssertNil(GameBackground.glowImage(size: .zero, paddleFraction: 0.25))
    }
}

/// The sunset, and the one thing it has to get right.
///
/// **James, round 334: "new sunset game background that goes from dark purple to dark blue to
/// lighter blue to white to orange, pink and red, just like a sunset."** The order is his. What
/// the game adds is where the bright part falls: the bricks are white and the field fills the
/// upper two thirds, so a sky that turns pale up there is a sky that hides the bricks.
final class SunsetBackgroundTests: XCTestCase {

    private func luminance(_ colour: UIColor) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.2126*red + 0.7152*green + 0.0722*blue
    }

    func testTheStopsAreSevenAndInOrder() {
        let stops = GameBackground.sunsetStops(paddleFraction: 0.22)
        XCTAssertEqual(stops.colours.count, 7, "purple, two blues, the haze, orange, pink, red")
        XCTAssertEqual(stops.locations.count, stops.colours.count)
        XCTAssertEqual(stops.locations, stops.locations.sorted(),
                       "a gradient given locations out of order draws nothing at all")
        XCTAssertEqual(stops.locations.first, 0)
        XCTAssertEqual(stops.locations.last, 1)
    }

    /// Everything the field is drawn against holds a white brick at three to one or better.
    ///
    /// Three to one is the bar for large shapes, and a brick is a large shape. Measured as a
    /// contrast ratio rather than against a brightness somebody picked: the question is whether
    /// a white brick reads, and that is what a ratio answers.
    func testTheSkyBehindTheBricksHoldsAWhiteBrick() {
        for fraction in [0.14, 0.22, 0.3] as [CGFloat] {
            let stops = GameBackground.sunsetStops(paddleFraction: fraction)
            let paddle = 1 - fraction
            for (colour, location) in zip(stops.colours, stops.locations)
            where location < paddle - 0.14 {
                let ratio = (1 + 0.05)/(luminance(colour) + 0.05)
                XCTAssertGreaterThanOrEqual(ratio, 3,
                    "a white brick \(location) of the way down is drawn against this, at "
                    + String(format: "%.2f", ratio) + " to one")
            }
        }
    }

    /// And the glare sits above the paddle rather than behind it.
    func testTheBrightestBandIsAboveThePaddle() {
        let fraction: CGFloat = 0.22
        let stops = GameBackground.sunsetStops(paddleFraction: fraction)
        let paddle = 1 - fraction
        guard let brightest = zip(stops.colours, stops.locations)
            .max(by: { luminance($0.0) < luminance($1.0) }) else {
            return XCTFail("no stops")
        }
        XCTAssertLessThan(brightest.1, paddle,
                          "the paddle is white, and a white paddle on the palest band of the "
                          + "sky is the one thing here that has to be read at a glance")
    }

    /// What the white ball costs at the horizon, written down on purpose.
    ///
    /// The paddle has a test of its own above: the glare never sits behind it. The ball has no
    /// such guarantee - it goes wherever it is hit - so it crosses the palest band of the sky
    /// several times a run, and for those moments a white ball is a white ball on light sand.
    ///
    /// That is why the haze is 214, 193, 160 rather than the white James named: pure white
    /// would be a ratio of 1.00, which is not low contrast but no contrast. This pins the
    /// number the compromise landed on, so the day somebody brightens the sunset they find out
    /// here rather than in a play test.
    func testTheHazeKeepsTheBallVisibleCrossingIt() {
        func contrast(_ a: UIColor, _ b: UIColor) -> CGFloat {
            func channel(_ c: CGFloat) -> CGFloat {
                c <= 0.03928 ? c/12.92 : pow((c + 0.055)/1.055, 2.4)
            }
            func relative(_ colour: UIColor) -> CGFloat {
                var r: CGFloat = 0, g: CGFloat = 0, bl: CGFloat = 0, al: CGFloat = 0
                colour.getRed(&r, green: &g, blue: &bl, alpha: &al)
                return 0.2126*channel(r) + 0.7152*channel(g) + 0.0722*channel(bl)
            }
            let one = relative(a), two = relative(b)
            return (max(one, two) + 0.05) / (min(one, two) + 0.05)
        }

        let ratio = contrast(.white, GameBackground.sunsetHaze)
        XCTAssertGreaterThan(ratio, 1.6,
                             "the ball would be invisible crossing the horizon")
        XCTAssertLessThan(ratio, 2.2,
                          "if this has risen, the haze is no longer the warm glare James asked "
                          + "for and the sunset has lost its sun")
    }

    /// A short screen still gets a gradient rather than a black rectangle.
    func testAnUnusuallyShortScreenStillDraws() {
        for fraction in [0.0, 0.5, 0.9, 1.0] as [CGFloat] {
            let stops = GameBackground.sunsetStops(paddleFraction: fraction)
            XCTAssertEqual(stops.locations, stops.locations.sorted(), "\(fraction)")
            XCTAssertNotNil(GameBackground.gradientImage(size: CGSize(width: 40, height: 80),
                                                         paddleFraction: fraction,
                                                         flavour: .sunset))
        }
    }
}
