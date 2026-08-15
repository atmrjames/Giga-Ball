//
//  GameBackground.swift
//  Megaball
//
//  What the playfield is painted with, as data.
//
//  The scene has always known how to paint these, and until now that was the only place the
//  knowledge lived: three colours and a pair of gradient stops written inline in
//  `applyBackgroundSetting`. That was fine while the only thing that ever showed a background
//  was the game.
//
//  The selection screen shows all four at once, in miniature, and it has to show them
//  *correctly* - a picker whose Gradient is a different gradient from the one you get when you
//  play is worse than a picker that only lists names. So the definitions move here, and both
//  the scene and the mock-up read them from the same place.
//

import UIKit

/// One of the backgrounds the playfield can wear.
///
/// The raw value is what `backgroundSetting` stores in `UserDefaults`, so the order is fixed -
/// a player who chose Gradient must still have Gradient after an update. New backgrounds go on
/// the end.
enum GameBackground: Int, CaseIterable {
    case classic = 0
    case solid = 1
    case gradient = 2
    case black = 3
    case glow = 4
    case deepBlue = 5
    case starrySky = 6

    /// The setting as it is stored, falling back to Classic for a value that no longer names
    /// anything - which is what an older build's setting looks like after a background is
    /// removed, and what a corrupted default looks like at any time.
    static func stored(_ setting: Int) -> GameBackground {
        GameBackground(rawValue: setting) ?? .classic
    }

    var name: String {
        switch self {
        case .classic: return "Classic"
        case .solid: return "Solid"
        case .gradient: return "Gradient"
        case .black: return "Black"
        case .glow: return "Glow"
        case .deepBlue: return "Deep Blue"
        case .starrySky: return "Starry Sky"
        }
    }

    /// A line for the selection screen, saying what the player is looking at.
    var summary: String {
        switch self {
        case .classic: return "The original artwork, as the game has always looked"
        case .solid: return "One flat colour, so nothing competes with the bricks"
        case .gradient: return "Light at the top, falling away below the paddle"
        case .black: return "Black, for the most contrast the screen can give"
        case .glow: return "The gradient, with a haze of Giga-Ball green above the field"
        case .deepBlue: return "A deep blue night, darkening towards the paddle"
        case .starrySky: return "A black sky scattered with stars"
        }
    }

    /// How this background is drawn.
    ///
    /// Only Classic is an image. The rest are drawn at runtime from the colour sampled off the
    /// top of that image, so they sit at whatever size the playfield is rather than needing an
    /// asset per device.
    enum Paint {
        /// The artwork on the scene's own background node.
        case artwork
        /// A full-height picture of its own, by asset name.
        ///
        /// Separate from `artwork` because that one *is* the background node's own texture -
        /// the scene paints Classic simply by leaving the node alone. Anything else needs
        /// drawing over it, and needs to say which picture (round 131's two).
        case picture(String)
        /// One flat colour.
        case solid(UIColor)
        /// A vertical fade, top to bottom.
        case gradient
        /// The same fade with a speckled green haze over the upper part of it.
        case glow
    }

    var paint: Paint {
        switch self {
        case .classic: return .artwork
        case .solid: return .solid(GameBackground.purple)
        case .gradient: return .gradient
        case .black: return .solid(.black)
        case .glow: return .glow
        case .deepBlue: return .picture("BackgroundBlue")
        case .starrySky: return .picture("BackgroundSpacePack")
        }
    }

    /// The purple at the top of the Classic background, which the drawn backgrounds match.
    static let purple = UIColor(red: 22/255, green: 0, blue: 32/255, alpha: 1)
    /// The side borders' purple, which the gradient starts from.
    static let borderPurple = UIColor(red: 41/255, green: 0, blue: 60/255, alpha: 1)
    /// Where the gradient ends up, below the paddle.
    static let deepPurple = UIColor(red: 2/255, green: 0, blue: 3/255, alpha: 1)

    /// The gradient's colours and the stops they sit at, measured from the top.
    ///
    /// Two fades rather than one. The upper half lifts the brick field slightly and ties it to
    /// the side borders, and only below the paddle does it fall away - which is how the
    /// Classic artwork reads. So the middle colour is pinned to the paddle rather than to the
    /// halfway mark, and `paddleFraction` is how far up the background the paddle sits.
    static func gradientStops(paddleFraction: CGFloat) -> (colours: [UIColor],
                                                           locations: [CGFloat]) {
        let fraction = min(max(paddleFraction, 0), 1)
        return ([borderPurple, purple, deepPurple], [0, 1 - fraction, 1])
    }

    /// The Giga-Ball green, which the glow is made of.
    static let glowGreen = UIColor(red: 210/255, green: 1, blue: 0, alpha: 1)

    /// Where the haze sits, as fractions of the background: left of centre and high up.
    ///
    /// Off-centre on purpose (play-test round 21). A glow in the middle of the field reads as
    /// a vignette and sits under every brick equally, which is the one thing it must not do -
    /// it is there to give the top of the field some depth, not to light it.
    static let glowCentre = CGPoint(x: 0.34, y: 0.24)
    static let glowRadius: CGFloat = 0.62

    /// The gradient with the haze over it.
    ///
    /// Speckle rather than a clean radial fade: a smooth circle of green over a smooth purple
    /// gradient bands badly on an OLED screen at these very low alphas. Scattering it into a
    /// few hundred soft dots breaks the bands up, and at this size and blur they read as one
    /// hazy cloud rather than as dots.
    ///
    /// The scatter is generated from a fixed seed, so the same background is the same picture
    /// every time it is drawn. A background that reshuffled itself whenever the scene resized
    /// would be a background that twinkles when you rotate the phone.
    static func glowImage(size: CGSize, paddleFraction: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        guard let base = gradientImage(size: size, paddleFraction: paddleFraction) else {
            return nil
        }

        return UIGraphicsImageRenderer(size: size).image { context in
            base.draw(in: CGRect(origin: .zero, size: size))

            let cg = context.cgContext
            cg.setBlendMode(.plusLighter)
            // Added to what is beneath rather than painted over it, so the purple still shows
            // through and the haze lifts it instead of covering it

            let centre = CGPoint(x: size.width*glowCentre.x, y: size.height*glowCentre.y)
            let reach = size.width*glowRadius
            var seed: UInt64 = 0x9E3779B97F4A7C15

            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 100_000)/100_000
            }

            for _ in 0..<340 {
                // Polar, with the radius square-rooted so the dots do not bunch in the middle
                let angle = next()*2*CGFloat.pi
                let distance = reach*sqrt(next())
                let spot = CGPoint(x: centre.x + cos(angle)*distance,
                                   y: centre.y + sin(angle)*distance*0.72)
                // Squashed vertically, so the haze lies across the top of the field rather
                // than sitting in it as a ball

                let fade = 1 - distance/reach
                let alpha = 0.075*fade*fade*(0.4 + next()*0.6)
                let dot = reach*(0.10 + next()*0.22)

                let colours = [glowGreen.withAlphaComponent(alpha).cgColor,
                               glowGreen.withAlphaComponent(0).cgColor] as CFArray
                guard let haze = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colours,
                                            locations: [0, 1]) else { continue }
                cg.drawRadialGradient(haze, startCenter: spot, startRadius: 0,
                                      endCenter: spot, endRadius: dot,
                                      options: [])
            }
        }
    }

    /// The gradient drawn out at a given size.
    ///
    /// UIKit's y runs down the image, so the stops above - measured from the top - are used
    /// as they are, and the paddle's fraction is what gets flipped.
    static func gradientImage(size: CGSize, paddleFraction: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let stops = gradientStops(paddleFraction: paddleFraction)
        return UIGraphicsImageRenderer(size: size).image { context in
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: stops.colours.map(\.cgColor) as CFArray,
                                            locations: stops.locations) else { return }
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: 0, y: size.height),
                                                 options: [])
        }
    }
}
