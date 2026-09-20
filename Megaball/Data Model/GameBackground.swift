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
    case clouds = 7
    /// James's diamond artwork (round 297), the same size and shape of thing as Deep Blue.
    case prism = 8
    /// The gradient in Giga-Ball green rather than purple - drawn, like the gradient it is a
    /// sibling of, so it fits any screen without an asset per device.
    case deepGreen = 9
    /// James's sunset (round 334): "goes from dark purple to dark blue to lighter blue to
    /// white to orange, pink and red, just like a sunset."
    case sunset = 10

    /// The order the picker offers them in.
    ///
    /// **Separate from `allCases`, and it has to be** (James, round 329d: "put game backgrounds
    /// in a more logical order"). `allCases` is in `rawValue` order, the raw value is what
    /// `backgroundSetting` stores, and a stored setting can never be renumbered - so the list
    /// had grown in the order the artwork was drawn rather than in any order a player would
    /// look for it in: Deep Purple before Black, Deep Green last of all because it was newest.
    ///
    /// His order, and the reasoning is visible in it: the three plain grounds first, then the
    /// three deep colours together, then the pictures.
    static let inDisplayOrder: [GameBackground] = [
        .classic, .solid, .black,
        .gradient, .deepBlue, .deepGreen, .sunset,
        .starrySky, .glow, .clouds, .prism,
    ]

    /// Where this one sits in the picker.
    var displayIndex: Int {
        GameBackground.inDisplayOrder.firstIndex(of: self) ?? rawValue
    }

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
        case .gradient: return "Deep Purple"
        case .black: return "Black"
        case .glow: return "Glow"
        case .deepBlue: return "Deep Blue"
        case .starrySky: return "Starry Sky"
        case .clouds: return "Clouds"
        case .prism: return "Prism"
        case .deepGreen: return "Deep Green"
        case .sunset: return "Sunset"
        }
    }

    /// A line for the selection screen, saying what the player is looking at.
    var summary: String {
        switch self {
        case .classic: return "The original artwork, as the game has always looked"
        case .solid: return "One flat colour, so nothing competes with the bricks"
        case .gradient: return "Deep purple at the top, falling away below the paddle"
        case .black: return "Black, for the most contrast the screen can give"
        case .glow: return "The gradient, with a haze of Giga-Ball green above the field"
        case .deepBlue: return "A deep blue night, darkening towards the paddle"
        case .starrySky: return "A black sky scattered with stars"
        case .clouds: return "Slow cloud, drifting behind the field"
        case .prism: return "Cut glass, catching the light down the field"
        case .deepGreen: return "Giga-Ball green at the top, black below the paddle"
        case .sunset: return "Night at the top of the field, the last of the light below it"
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
        /// A vertical fade like `gradient`, in Giga-Ball green rather than purple.
        case greenGradient
        /// The sky at sunset: night at the top, the last of the light at the paddle line.
        case sunsetGradient
        /// The fade with cloud drifting across it - two layers at two speeds.
        ///
        /// The only background that moves, which is the whole of it: everything else here is
        /// one picture, and this is a picture plus the scene's own slow drift (§12.0, round
        /// 126: "dynamic cloud game background").
        case clouds
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
        case .clouds: return .clouds
        case .prism: return .picture("backgroundPrism")
        case .deepGreen: return .greenGradient
        case .sunset: return .sunsetGradient
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

    /// The sunset's seven stops, pinned to the paddle the way the other two gradients are.
    ///
    /// **James, round 334: "new sunset game background that goes from dark purple to dark blue
    /// to lighter blue to white to orange, pink and red, just like a sunset."** That order is
    /// his, top to bottom, and the only decision left is *where* the light band falls.
    ///
    /// **It falls at the paddle, and it has to.** The bricks in this game are white, and the
    /// field fills the upper two thirds of the screen: a sky that turns pale up there is a sky
    /// that hides the bricks. So everything above the paddle line is night - the purple, then
    /// the two blues, each dark enough to leave a white brick reading as a white brick - and
    /// the horizon's glare sits just above the paddle, where no brick ever reaches. Below it,
    /// the orange and the pink fall away to a deep red, so the white paddle still has
    /// something dark to sit against.
    ///
    /// Pinning the band to `paddleFraction` rather than to a fixed fraction is the same trick
    /// the purple gradient has used since it was drawn: the paddle is in a different place on
    /// every screen shape, and a horizon that drifted up into the field on a short phone would
    /// take the bricks with it.
    ///
    /// **The glare sits a little above the paddle rather than behind it**, which the first
    /// version got wrong and a screenshot showed: a white paddle on the palest band of the sky
    /// is the one piece of this that has to be read at a glance, so the haze is pulled up into
    /// the empty strip under the field and the paddle is left sitting against the orange.
    static func sunsetStops(paddleFraction: CGFloat) -> (colours: [UIColor],
                                                         locations: [CGFloat]) {
        let paddle = min(max(1 - paddleFraction, 0.35), 0.95)
        let colours = [sunsetNight, sunsetDeepBlue, sunsetBlue, sunsetHaze,
                       sunsetOrange, sunsetPink, sunsetRed]
        let locations: [CGFloat] = [0,
                                    paddle*0.42,
                                    paddle*0.74,
                                    max(0, paddle - 0.12),
                                    max(0, paddle - 0.02),
                                    min(1, paddle + 0.09),
                                    1]
        return (colours, locations.sorted())
        // Sorted because the two clamps above can cross on an unusually short screen, and a
        // `CGGradient` given locations out of order draws nothing at all
    }

    static let sunsetNight = UIColor(red: 20/255, green: 10/255, blue: 40/255, alpha: 1)
    static let sunsetDeepBlue = UIColor(red: 16/255, green: 32/255, blue: 63/255, alpha: 1)
    static let sunsetBlue = UIColor(red: 36/255, green: 71/255, blue: 110/255, alpha: 1)
    static let sunsetHaze = UIColor(red: 214/255, green: 193/255, blue: 160/255, alpha: 1)
    static let sunsetOrange = UIColor(red: 196/255, green: 86/255, blue: 31/255, alpha: 1)
    static let sunsetPink = UIColor(red: 142/255, green: 34/255, blue: 70/255, alpha: 1)
    static let sunsetRed = UIColor(red: 42/255, green: 7/255, blue: 16/255, alpha: 1)
    // The haze is a warm off-white rather than white: the ball is white, the paddle is white
    // and the bricks are white, and the one place this background is bright is the one place
    // all three of them meet

    /// The Giga-Ball green, which the glow is made of.
    static let glowGreen = UIColor(red: 210/255, green: 1, blue: 0, alpha: 1)

    /// Deep Green's three stops.
    ///
    /// James, round 297: "similar in vein to the gradient and deep blue backgrounds but with the
    /// giga-ball yellow/green colour. It should be dark so it doesn't clash with the game's
    /// colours, and fade to black below the paddle."
    ///
    /// **Dark is the whole difficulty.** `glowGreen` is a near-fluorescent 210,255,0 - it is the
    /// ball, the paddle's grip, the halo and half the power-up badges, and a background anywhere
    /// near it would put the brightest colour in the game behind the brightest objects in the
    /// game. So the hue is kept and almost all of the light taken out: the top is that green at
    /// about a twelfth of its brightness, which reads as green without being able to compete
    /// with anything, and it is already darker than the purple gradient's own top.
    ///
    /// The stops are placed exactly as the purple gradient's are - the middle pinned to the
    /// paddle rather than to halfway - so the two read as the same background in two colours,
    /// which is what "in the vein of" asks for.
    static let deepGreenTop = UIColor(red: 20/255, green: 28/255, blue: 2/255, alpha: 1)
    static let deepGreenMiddle = UIColor(red: 10/255, green: 15/255, blue: 1/255, alpha: 1)
    static let deepGreenBottom = UIColor(red: 0, green: 0, blue: 0, alpha: 1)

    /// How far down the purple reaches before the green takes over.
    ///
    /// **Measured off Deep Blue rather than guessed** (James, round 305: "for the deep green
    /// game background, add a purple gradient to the top section similar to how it is on the
    /// deep blue game background to make the transition with the purple power up hud area less
    /// dramatic"). Deep Blue is a picture, so the only way to be "similar to" it is to read it:
    /// sampled down its centre column it starts at rgb(24,0,26) - within a couple of points of
    /// `purple` - and has become its own blue by about a quarter of the way down.
    static let greenPurpleReach: CGFloat = 0.25

    static func greenGradientStops(paddleFraction: CGFloat)
    -> (colours: [UIColor], locations: [CGFloat]) {
        let fraction = min(max(paddleFraction, 0), 1)
        let paddle = 1 - fraction
        let reach = min(greenPurpleReach, paddle)
        // Clamped under the paddle stop so the locations stay in order. A paddle sitting in the
        // top quarter of the background is not a layout this game produces, but a gradient with
        // its stops out of order draws something arbitrary rather than failing, which is the
        // kind of thing that is only ever found by looking
        return ([purple, deepGreenTop, deepGreenMiddle, deepGreenBottom],
                [0, reach, paddle, 1])
        // The purple is the *same* purple the Classic background and the side borders use, so
        // the join with the power-up tray above is a continuation rather than a meeting
    }

    // Where the haze sits is `glowPools` below. Off-centre on purpose (play-test round 21):
    // a glow in the middle of the field reads as a vignette and sits under every brick
    // equally, which is the one thing it must not do - it is there to give the field some
    // depth, not to light it.

    /// The haze on its own, on a transparent ground.
    ///
    /// Split out of `glowImage` in round 144 so the scene can put it on a node of its own and
    /// breathe it - a haze that swells and settles over about eight seconds, which is slow
    /// enough to be felt rather than watched. The still picture below still composites the
    /// two, because the picker draws one image and nothing there moves.
    ///
    /// Speckle rather than a clean radial fade: a smooth circle of green over a smooth purple
    /// gradient bands badly on an OLED screen at these very low alphas. Scattering it into a
    /// few hundred soft dots breaks the bands up, and at this size and blur they read as one
    /// hazy cloud rather than as dots.
    ///
    /// The scatter is generated from a fixed seed, so the same background is the same picture
    /// every time it is drawn. A background that reshuffled itself whenever the scene resized
    /// would be a background that twinkles when you rotate the phone.
    ///
    /// **Two pools since round 144** (play-test round 126: "improve existing glow
    /// background"). One green and high on the left as before, and a second, smaller and
    /// cooler one low on the right - the single pool lit one corner and left the rest of the
    /// field flat, and a picture with one bright corner reads as a mistake rather than as
    /// light. The pair gives the field a diagonal, which is what the Classic artwork has.
    /// How each pool drifts, once it is a node of its own.
    ///
    /// James, round 297: "is it possible to make the giga-ball yellow/green fuzzy hue dynamic,
    /// so it moves and evolves slowly behind the game, almost like a lava lamp."
    ///
    /// **Two periods that do not divide into each other.** A pool moved on one loop retraces
    /// the same line for ever, and the eye finds a repeat however slow it is. Moving x on one
    /// period and y on another draws a Lissajous figure whose path only closes when the two
    /// periods do - at 37 and 53 seconds that is half an hour, which is longer than a run, so
    /// the haze never visibly repeats. The scale is a third period again.
    ///
    /// The distances are small on purpose: a few per cent of the field, over most of a minute.
    /// A background that can be *watched* moving is a background competing with the game.
    static let hazeDrift: [(x: CGFloat, y: CGFloat, across: TimeInterval,
                            down: TimeInterval, swell: TimeInterval)] = [
        (0.055, 0.045, 37, 53, 61),
        (0.075, 0.035, 43, 29, 47),
    ]

    static func hazeImage(size: CGSize, only: Int? = nil) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.setBlendMode(.plusLighter)
            // Added to what is beneath rather than painted over it, so the purple still shows
            // through and the haze lifts it instead of covering it

            var seed: UInt64 = 0x9E3779B97F4A7C15
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 100_000)/100_000
            }

            for (index, pool) in glowPools.enumerated() {
                if let only, index != only { continue }
                // One pool per node when the scene asks for them separately, so each can drift
                // on its own path - as one baked picture they could only move together, which
                // is a picture sliding about rather than two lights in a lamp
                let centre = CGPoint(x: size.width*pool.centre.x,
                                     y: size.height*pool.centre.y)
                let reach = size.width*pool.radius

                for _ in 0..<pool.dots {
                    // Polar, with the radius square-rooted so the dots do not bunch in the
                    // middle
                    let angle = next()*2*CGFloat.pi
                    let distance = reach*sqrt(next())
                    let spot = CGPoint(x: centre.x + cos(angle)*distance,
                                       y: centre.y + sin(angle)*distance*0.72)
                    // Squashed vertically, so a pool lies across the field rather than
                    // sitting in it as a ball

                    let fade = 1 - distance/reach
                    let alpha = pool.strength*fade*fade*(0.4 + next()*0.6)
                    let dot = reach*(0.10 + next()*0.22)

                    let colours = [pool.colour.withAlphaComponent(alpha).cgColor,
                                   pool.colour.withAlphaComponent(0).cgColor] as CFArray
                    guard let haze = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                                colors: colours,
                                                locations: [0, 1]) else { continue }
                    cg.drawRadialGradient(haze, startCenter: spot, startRadius: 0,
                                          endCenter: spot, endRadius: dot,
                                          options: [])
                }
            }
        }
    }

    /// One soft blob: a radial fade from the colour at its middle to nothing at its edge.
    ///
    /// **The unit both moving backgrounds are now made of** (James, round 299: "what I want is
    /// the glow / cloud parts of the background to shift and move as natural shapes, floating
    /// around in space gently and randomly, shifting positions and shapes gradually over time,
    /// kind of like a lava lamp").
    ///
    /// Round 297 moved the *whole baked picture* instead, which is what he saw and rightly
    /// rejected: every dot in it travelled together, so the haze slid about as one rigid object
    /// and its shape never changed. A lava lamp is not one shape moving - it is several shapes
    /// moving *independently*, and what makes it hypnotic is the merging and parting, which is
    /// a property of the gaps between them rather than of any one blob.
    ///
    /// So the layers are built from these instead, a handful of nodes each, drifting on their
    /// own paths. They are drawn once per colour and shared: a sprite can be scaled and tinted,
    /// and re-rendering a gradient per blob would be a texture upload per blob for no
    /// difference on screen (round 291's lesson about `SKTexture(image:)`).
    static func softBlobImage(diameter: CGFloat, colour: UIColor) -> UIImage? {
        guard diameter > 1 else { return nil }
        let size = CGSize(width: diameter, height: diameter)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let centre = CGPoint(x: diameter/2, y: diameter/2)
            let colours = [colour.withAlphaComponent(1).cgColor,
                           colour.withAlphaComponent(0.55).cgColor,
                           colour.withAlphaComponent(0).cgColor] as CFArray
            guard let fade = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colours, locations: [0, 0.35, 1]) else { return }
            context.cgContext.drawRadialGradient(fade, startCenter: centre, startRadius: 0,
                                                 endCenter: centre, endRadius: diameter/2,
                                                 options: [])
            // Three stops rather than two: a straight linear fade to nothing reads as a disc
            // with a soft edge, where holding most of the strength through the middle third and
            // then falling away reads as light
        }
    }

    /// A blob's own drift, worked out from its index so no two share a rhythm.
    ///
    /// **Everything here is derived rather than listed**, because the count is a knob: the
    /// alternative is a table that has to grow whenever a layer gains a blob, and a table
    /// somebody has to keep irrational-looking by hand.
    ///
    /// The three periods are seeded off the index by three different primes, so any two blobs
    /// differ in all three and the whole field has no common cycle. Nothing lines up twice
    /// inside a run, which is the only thing standing between "drifting" and "looping".
    /// How many blobs each pool is made of, and how big each is against the pool's reach.
    ///
    /// Five is enough for the gaps between them to keep making new shapes and few enough that
    /// the pool still reads as one light rather than as a handful of spots. They are drawn
    /// wider than the spacing between them on purpose - a lamp is blobs that overlap.
    static let hazeBlobsPerPool = 5
    static let hazeBlobShare: CGFloat = 1.15
    /// Each blob carries a share of the pool's strength, since several overlap everywhere.
    ///
    /// **A share, not a multiple.** The blobs blend additively, so three or four of them
    /// overlap through the middle of a pool and their strengths sum - the first attempt gave
    /// each one more than the whole pool used to have and produced a bright green mass rather
    /// than a haze. About a third of the pool's figure puts the *summed* peak back where the
    /// baked picture's was, which is where two hundred rounds of play-testing left it.
    /// **Matched to the picture it replaces rather than chosen** (round 299). The baked haze
    /// averaged 0.037 alpha across the field; five blobs at this figure average the same, which
    /// is how the change keeps two hundred rounds of play-testing on the brightness while
    /// changing everything about how it moves. 3.4 was tried first and made a bright green
    /// mass, then 0.36 and made nothing at all - two guesses that the measurement would have
    /// saved.
    static let hazeBlobStrength: CGFloat = 1.55

    static func blobDrift(index: Int, seed: UInt64) -> (across: TimeInterval, down: TimeInterval,
                                                        swell: TimeInterval, phase: TimeInterval) {
        var state = seed &+ UInt64(index) &* 0x9E3779B97F4A7C15
        func next(_ range: ClosedRange<Double>) -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let unit = Double((state >> 33) % 100_000)/100_000
            return range.lowerBound + unit*(range.upperBound - range.lowerBound)
        }
        return (next(29...53), next(31...61), next(37...67), next(0...20))
    }

    /// The pools the haze is made of: where each sits, how far it reaches, and how strong.
    static let glowPools: [(centre: CGPoint, radius: CGFloat, strength: CGFloat,
                            dots: Int, colour: UIColor, seed: UInt64)] = [
        (CGPoint(x: 0.34, y: 0.24), 0.62, 0.085, 340, glowGreen, 0x9E3779B97F4A7C15),
        (CGPoint(x: 0.78, y: 0.62), 0.40, 0.05, 180,
         UIColor(red: 120/255, green: 90/255, blue: 1, alpha: 1), 0xBF58476D1CE4E5B9),
        // The second is violet rather than more green: the same colour twice reads as one
        // pool that has been smeared, where two colours read as two lights
    ]

    /// How long one breath of the haze takes, and how far it dips.
    ///
    /// Eight seconds and a fifth, which is slow and shallow enough that it is noticed at the
    /// edge of the eye rather than watched - a background that pulses visibly is a background
    /// competing with the ball.
    static let glowBreath: TimeInterval = 8
    static let glowBreathDepth: CGFloat = 0.2

    /// The gradient with the haze over it: one still picture, for the picker and the mock-up.
    static func glowImage(size: CGSize, paddleFraction: CGFloat) -> UIImage? {
        guard let base = gradientImage(size: size, paddleFraction: paddleFraction) else {
            return nil
        }
        guard let haze = hazeImage(size: size) else { return base }

        return UIGraphicsImageRenderer(size: size).image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            haze.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// One layer of cloud, on a transparent ground, tileable left to right.
    ///
    /// Drawn twice as wide as the field and moved by the scene, so a layer can travel a whole
    /// field's width and start again without a seam: every blob that crosses the right-hand
    /// edge is drawn again on the left, which is what makes the two halves identical at the
    /// join.
    ///
    /// Soft, wide and very faint. Cloud in this game is weather behind a field of bricks, not
    /// a picture of the sky - anything with an edge on it would compete with the ball.
    static func cloudImage(size: CGSize, seed startingSeed: UInt64, blobs: Int,
                           tint: UIColor, strength: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.setBlendMode(.plusLighter)

            var seed = startingSeed
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 100_000)/100_000
            }

            for _ in 0..<blobs {
                let x = next()*size.width
                let y = next()*size.height
                let width = size.width*(0.18 + next()*0.26)
                let height = width*(0.22 + next()*0.18)
                // Wider than they are tall, like weather

                let alpha = strength*(0.35 + next()*0.65)
                let colours = [tint.withAlphaComponent(alpha).cgColor,
                               tint.withAlphaComponent(0).cgColor] as CFArray
                guard let puff = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colours, locations: [0, 1]) else { continue }

                for wrap in [CGFloat(0), -size.width, size.width] {
                    cg.saveGState()
                    cg.translateBy(x: x + wrap, y: y)
                    cg.scaleBy(x: 1, y: height/width)
                    cg.drawRadialGradient(puff, startCenter: .zero, startRadius: 0,
                                          endCenter: .zero, endRadius: width,
                                          options: [])
                    cg.restoreGState()
                }
                // Three passes: where it is, and a copy either side. A blob near an edge is
                // then whole on both sides of the join, which is the whole trick to a strip
                // that can be scrolled for ever
            }
        }
    }

    /// The two cloud layers: how fast each crosses the field, and what it is made of.
    ///
    /// Two speeds rather than one, because parallax is what makes a flat picture read as
    /// depth - and the near layer is the fainter of the two, or it would be the thing you
    /// were looking at.
    static let cloudLayers: [(seed: UInt64, blobs: Int, strength: CGFloat,
                              crossing: TimeInterval, evolving: TimeInterval,
                              colour: UIColor)] = [
        (0xD1B54A32D192ED03, 16, 0.26, 210, 67,
         UIColor(red: 120/255, green: 70/255, blue: 165/255, alpha: 1)),
        (0x2545F4914F6CDD1D, 10, 0.13, 130, 41,
         UIColor(red: 165/255, green: 120/255, blue: 1, alpha: 1)),
    ]
    // `evolving` is how long each layer takes to swell and thin once (round 297). Neither
    // divides into its own crossing time or into the other's, so the two layers are never in
    // the same state twice in a run - which is what stops a drift on a loop reading as a loop
    // The colours are lifted well off the background's own purple. Added light on a very
    // dark ground is nearly nothing: the first pass used the border's purple at a tenth
    // alpha and drew cloud nobody could see, which is the same as no cloud at all

    /// The still picture of it, for the picker and the mock-up - one frame of the drift.
    static func cloudsImage(size: CGSize, paddleFraction: CGFloat) -> UIImage? {
        guard let base = gradientImage(size: size, paddleFraction: paddleFraction) else {
            return nil
        }
        return UIGraphicsImageRenderer(size: size).image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            for layer in cloudLayers {
                cloudImage(size: size, seed: layer.seed, blobs: layer.blobs,
                           tint: layer.colour, strength: layer.strength)?
                    .draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }

    /// The gradient drawn out at a given size.
    ///
    /// UIKit's y runs down the image, so the stops above - measured from the top - are used
    /// as they are, and the paddle's fraction is what gets flipped.
    /// Which of the three fades to draw. Was a `green: Bool` until the sunset made it three.
    enum Flavour { case purple, green, sunset }

    static func gradientImage(size: CGSize, paddleFraction: CGFloat,
                              flavour: Flavour = .purple) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let stops: (colours: [UIColor], locations: [CGFloat])
        switch flavour {
        case .purple: stops = gradientStops(paddleFraction: paddleFraction)
        case .green: stops = greenGradientStops(paddleFraction: paddleFraction)
        case .sunset: stops = sunsetStops(paddleFraction: paddleFraction)
        }
        // One builder for both, because they are the same picture in two colours - a second
        // copy would be a second place to fix the day the stops move
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
