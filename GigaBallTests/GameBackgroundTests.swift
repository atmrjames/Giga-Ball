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
        // stop happening
        XCTAssertEqual(LevelPackSetup().backgroundNameArray,
                       GameBackground.allCases.map(\.name))
    }

    func testOnlyClassicUsesArtwork() {
        // The rest are drawn at runtime, which is what lets them sit at whatever size the
        // playfield turns out to be rather than needing an asset per device
        for background in GameBackground.allCases {
            switch background.paint {
            case .artwork:
                XCTAssertEqual(background, .classic)
            case .solid, .gradient, .glow:
                XCTAssertNotEqual(background, .classic)
            }
        }
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
        XCTAssertLessThan(GameBackground.glowCentre.y, 0.5, "it belongs in the upper half")
        XCTAssertNotEqual(GameBackground.glowCentre.x, 0.5, "and not down the middle")
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
