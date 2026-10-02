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
            case .solid, .gradient, .glow, .clouds, .greenGradient:
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
        // artwork does - so the second must be on the other side, at the other height
        // (measured from the bottom, as the scene measures it), and quieter
        XCTAssertEqual(GameBackground.glowPools.count, 2)
        let (near, far) = (GameBackground.glowPools[0], GameBackground.glowPools[1])
        XCTAssertGreaterThan(far.centre.x, near.centre.x)
        XCTAssertGreaterThan(far.centre.y, near.centre.y)
        XCTAssertLessThan(far.strength, near.strength)
    }

    func testTheHazeIsLaidOutAsBlobsSoItCanBreathe() {
        // Split from the gradient in round 144, and into blobs of its own in round 299: on
        // nodes of their own the scene can swell and drift them, which a baked picture cannot
        let blobs = GameBackground.glowBlobs(in: CGSize(width: 60, height: 100), shuffle: 1)
        XCTAssertEqual(blobs.count,
                       GameBackground.glowPools.count*GameBackground.hazeBlobsPerPool)
        XCTAssertTrue(GameBackground.glowBlobs(in: .zero, shuffle: 1).isEmpty)
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

    func testTheCloudsAreTheSameCloudsForTheSameGame() {
        // Seeded by the game's own shuffle: a background that reshuffled itself on a resize
        // would change shape when the phone is rotated or an iPad window is dragged
        let size = CGSize(width: 70, height: 120)
        let first = GameBackground.cloudBlobs(in: size, shuffle: 42).map(\.centre)
        let again = GameBackground.cloudBlobs(in: size, shuffle: 42).map(\.centre)
        XCTAssertEqual(first, again)
        XCTAssertEqual(first.count, GameBackground.cloudLayers.map(\.blobs).reduce(0, +))
        XCTAssertTrue(GameBackground.cloudBlobs(in: .zero, shuffle: 42).isEmpty)
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

/// James, round 351: "New sunset background in File Sharing." His artwork replaces the seven
/// stops round 334 drew from his description of one.
final class SunsetBackgroundTests: XCTestCase {

    func testTheSunsetIsJamessPicture() {
        guard case .picture(let named) = GameBackground.sunset.paint else {
            return XCTFail("the sunset is drawn rather than James's artwork")
        }
        XCTAssertNotNil(UIImage(named: named))
    }
}

/// James, round 357: "Scrolling through the game backgrounds settings screen, the page dots
/// don't line up with the sequence of swiping through the backgrounds. The dots jump about
/// seemingly randomly."
final class BackgroundDotsTests: XCTestCase {
    func testSwipingThroughTheStripLightsTheDotsInOrder() {
        let dots = GameBackground.inDisplayOrder.map(BackgroundSelectViewController.dot(for:))
        XCTAssertEqual(dots, Array(0..<GameBackground.inDisplayOrder.count),
                       "each page lights the next dot along, not its raw value's")
    }
}

/// James, round 358: "Glow and clouds backgrounds look much better and they do move in-game
/// all be it very slowly, the images in the game backgrounds selection screen are of the
/// previous version, the starting point of the backgrounds in the game is the same each time,
/// is it possible to randomise the size and position of the blobs at the start?"
final class MovingBackgroundStartTests: XCTestCase {

    func testEachGameOpensOnADifferentGlow() {
        let size = CGSize(width: 300, height: 540)
        let one = GameBackground.glowBlobs(in: size, shuffle: 1)
        let two = GameBackground.glowBlobs(in: size, shuffle: 2)
        XCTAssertNotEqual(one.map(\.centre), two.map(\.centre), "the blobs start elsewhere")
        XCTAssertNotEqual(one.map(\.size.width), two.map(\.size.width), "and at other sizes")
    }

    func testEachGameOpensOnDifferentClouds() {
        let size = CGSize(width: 300, height: 540)
        let one = GameBackground.cloudBlobs(in: size, shuffle: 1)
        let two = GameBackground.cloudBlobs(in: size, shuffle: 2)
        XCTAssertNotEqual(one.map(\.centre), two.map(\.centre))
        XCTAssertNotEqual(one.map(\.size.width), two.map(\.size.width))
    }

    func testTheShuffleNeverSwapsThePoolsOver() {
        // The diagonal is the composition (round 144): whatever a game's shuffle, the green
        // stays on the left and below the violet
        let size = CGSize(width: 300, height: 540)
        for shuffle in UInt64(1)...60 {
            let blobs = GameBackground.glowBlobs(in: size, shuffle: shuffle)
            func middle(_ group: Int) -> CGPoint {
                let own = blobs.filter { $0.group == group }
                return CGPoint(x: own.map(\.centre.x).reduce(0, +)/CGFloat(own.count),
                               y: own.map(\.centre.y).reduce(0, +)/CGFloat(own.count))
            }
            XCTAssertLessThan(middle(0).x, middle(1).x, "shuffle \(shuffle)")
            XCTAssertLessThan(middle(0).y, middle(1).y, "shuffle \(shuffle)")
        }
    }

    func testThePickerShowsTheGreenWhereTheGameDoes() throws {
        // "The images in the game backgrounds selection screen are of the previous version":
        // the picker drew the old speckled haze, and measured the pools from the top while the
        // scene measures them from the bottom, so its green sat at the top of the preview and
        // the game's at the bottom. The scene's green pool is the lower one, so the picker's
        // extra green over the plain gradient has to be mostly in the lower half too
        let size = CGSize(width: 120, height: 216)
        let glow = try XCTUnwrap(GameBackground.glowImage(size: size, paddleFraction: 0.2))
        let plain = try XCTUnwrap(GameBackground.gradientImage(size: size, paddleFraction: 0.2))
        let added = zip(greens(glow), greens(plain)).map { Int($0) - Int($1) }
        let half = added.count/2
        let upper = added[..<half].reduce(0, +)
        let lower = added[half...].reduce(0, +)
        XCTAssertGreaterThan(lower, upper)
    }

    func testThePickerIsTheSamePictureEveryTime() {
        let size = CGSize(width: 60, height: 108)
        XCTAssertEqual(GameBackground.cloudsImage(size: size, paddleFraction: 0.2)?.pngData(),
                       GameBackground.cloudsImage(size: size, paddleFraction: 0.2)?.pngData())
    }

    func testTheStillBlobFadesAsTheShaderDoes() {
        // The picture draws `blobBody`, the scene's shader does the same sum on the GPU: full
        // at the middle, falling, and exactly nothing at the rim so there is no edge to find
        XCTAssertEqual(GameBackground.blobBody(at: 0), 1, accuracy: 0.0001)
        XCTAssertEqual(GameBackground.blobBody(at: 1), 0, accuracy: 0.0001)
        XCTAssertGreaterThan(GameBackground.blobBody(at: 0.3), GameBackground.blobBody(at: 0.6))
        XCTAssertEqual(GameBackground.blobBody(at: 0.5),
                       exp(-0.25*GameBackground.blobSoftness), accuracy: 0.0001,
                       "untouched by the rim's fade inside d = 0.55")
    }

    func testAPoolWandersOnlyAsFarAsItIsAllowed() {
        // Far enough that no two games open on the same light, never so far that the pool
        // leaves its corner - and both ways, or "wander" is a drift in one direction
        for index in GameBackground.glowPools.indices {
            let listed = GameBackground.glowPools[index].centre
            var lowest = CGPoint(x: 1, y: 1), highest = CGPoint(x: 0, y: 0)
            for shuffle in UInt64(1)...200 {
                let placed = GameBackground.poolPlacement(index, shuffle: shuffle)
                XCTAssertLessThanOrEqual(abs(placed.centre.x - listed.x),
                                         GameBackground.poolWander + 0.0001)
                XCTAssertLessThanOrEqual(abs(placed.centre.y - listed.y),
                                         GameBackground.poolWander + 0.0001)
                XCTAssertTrue(GameBackground.poolSizeRange.contains(placed.grown),
                              "grown \(placed.grown)")
                lowest = CGPoint(x: min(lowest.x, placed.centre.x), y: min(lowest.y, placed.centre.y))
                highest = CGPoint(x: max(highest.x, placed.centre.x), y: max(highest.y, placed.centre.y))
            }
            XCTAssertLessThan(lowest.x, listed.x - GameBackground.poolWander/2)
            XCTAssertGreaterThan(highest.x, listed.x + GameBackground.poolWander/2)
            XCTAssertLessThan(lowest.y, listed.y - GameBackground.poolWander/2)
            XCTAssertGreaterThan(highest.y, listed.y + GameBackground.poolWander/2)
        }
    }

    func testEveryCloudIsDrawnFromItsRanges() {
        // The shuffle moves the clouds about; it must not make one a sliver, a slab, a glare
        // or a cloud that sits under the paddle
        let size = CGSize(width: 300, height: 540)
        for shuffle in UInt64(1)...40 {
            for cloud in GameBackground.cloudBlobs(in: size, shuffle: shuffle) {
                let layer = GameBackground.cloudLayers[cloud.group]
                XCTAssertTrue((0.34*size.width...0.76*size.width).contains(cloud.size.width))
                XCTAssertTrue((0.34...0.54).contains(cloud.size.height/cloud.size.width))
                XCTAssertTrue((0.55*layer.strength...1.15*layer.strength).contains(cloud.alpha))
                XCTAssertTrue((0...2*size.width).contains(cloud.centre.x))
                XCTAssertTrue((0.12*size.height...0.88*size.height).contains(cloud.centre.y))
                XCTAssertTrue((0.8*layer.crossing...1.25*layer.crossing).contains(cloud.crossing))
            }
        }
    }

    func testAFieldWithNoWidthOrNoHeightHasNoBlobs() {
        for size in [CGSize(width: 0, height: 100), CGSize(width: 100, height: 0)] {
            XCTAssertTrue(GameBackground.glowBlobs(in: size, shuffle: 3).isEmpty, "\(size)")
            XCTAssertTrue(GameBackground.cloudBlobs(in: size, shuffle: 3).isEmpty, "\(size)")
        }
    }

    func testTheStillPictureAddsLightAndCoversNothing() throws {
        // Light added over the gradient, never painted over it: the top corner, which no pool
        // reaches, is the gradient's own colour, and the picture as a whole is brighter
        let size = CGSize(width: 120, height: 216)
        let glow = greens(try XCTUnwrap(GameBackground.glowImage(size: size, paddleFraction: 0.2)))
        let plain = greens(try XCTUnwrap(GameBackground.gradientImage(size: size,
                                                                      paddleFraction: 0.2)))
        let glowCorner = try XCTUnwrap(rgba(try XCTUnwrap(
            GameBackground.glowImage(size: size, paddleFraction: 0.2))).first)
        let plainCorner = try XCTUnwrap(rgba(try XCTUnwrap(
            GameBackground.gradientImage(size: size, paddleFraction: 0.2))).first)
        for channel in 0..<3 {
            XCTAssertEqual(Int(glowCorner[channel]), Int(plainCorner[channel]), accuracy: 2,
                           "channel \(channel): the corner is painted over")
        }
        // Every channel, not just green: the top of the gradient is the border's purple,
        // which has no green in it to lose
        let added = zip(glow, plain).map { Int($0) - Int($1) }.reduce(0, +)
        XCTAssertGreaterThan(added, glow.count, "on average more than a step of green a pixel")
    }

    /// Each pixel's green channel, top row first.
    private func greens(_ image: UIImage) -> [UInt8] {
        rgba(image).map { $0[1] }
    }

    /// Each pixel's four channels, top row first.
    private func rgba(_ image: UIImage) -> [[UInt8]] {
        let width = Int(image.size.width), height = Int(image.size.height)
        var pixels = [UInt8](repeating: 0, count: width*height*4)
        guard let cg = image.cgImage,
              let context = CGContext(data: &pixels, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width*4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return [] }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: pixels.count, by: 4).map { Array(pixels[$0..<$0 + 4]) }
    }
}
