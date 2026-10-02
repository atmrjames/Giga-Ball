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
        case .sunset: return .picture("backgroundSunset")
        // **James's own artwork since round 351**, replacing the seven stops round 334 drew
        // from his description. A picture like Deep Blue, so it scales to the field the way
        // Deep Blue does
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

    // **Two pools since round 144** (play-test round 126: "improve existing glow
    // background"): one green, one smaller and cooler on the other side of the field. The
    // single pool lit one corner and left the rest flat, and a picture with one bright corner
    // reads as a mistake rather than as light. The pair gives the field a diagonal, which is
    // what the Classic artwork has.
    //
    // The baked haze of a few hundred speckled dots that this used to be went in round 358:
    // the scene had drawn the glow from drifting blobs since round 299, and the picker was
    // still showing the old picture - upside down, too, because the picture measured a pool's
    // height from the top and the scene measures it from the bottom. Both now read
    // `glowBlobs`, so they cannot disagree again.

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
        (0.09, 0.07, 37, 53, 61),
        (0.10, 0.06, 43, 29, 47),
    ]
    // Wider than round 299's 0.055 and 0.075 (James, round 351: "make them a bit more random
    // and disperse within the backgrounds"). Still most of a minute each way

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
    static let hazeBlobsPerPool = 7
    static let hazeBlobShare: CGFloat = 1.15

    /// How far from its pool's centre a blob may start, as a share of the pool's reach.
    static let hazeBlobScatter: CGFloat = 0.9

    /// Where each of a pool's blobs starts, how big it is and how much of the light it carries.
    ///
    /// **Scattered rather than set round a ring** (James, round 351: "make them a bit more
    /// random and disperse within the backgrounds"). Round 299 put five blobs evenly round a
    /// circle, which is a shape an eye finds; seven at seeded random places and sizes read as
    /// weather. Seeded, so a pool is the same pool every time it is built - a background that
    /// reshuffled on a rotation would twinkle.
    static func hazeBlobs(seed: UInt64) -> [(offset: CGPoint, scale: CGFloat, share: CGFloat)] {
        var state = seed ^ 0x5851F42D4C957F2D
        func next() -> CGFloat {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((state >> 33) % 100_000)/100_000
        }
        return (0..<hazeBlobsPerPool).map { _ in
            let angle = next()*2*CGFloat.pi
            let distance = hazeBlobScatter*sqrt(next())
            return (CGPoint(x: cos(angle)*distance, y: sin(angle)*distance*0.8),
                    0.6 + next()*0.7,
                    0.6 + next()*0.8)
        }
        // The share averages one, so `hazeBlobStrength` still sets the pool's brightness
    }

    /// How soft the drawn blobs are, and how much grain runs through them (round 351).
    ///
    /// **James: "make the glow and cloud backgrounds higher quality. They look a bit bad. Make
    /// the glow and clouds sections in the background more diffuse so they fade in and out.
    /// Add a noise texture to the colour on top of the purple to give it a grainy effect."**
    /// The blobs were a 256-pixel picture stretched to half a screen, at an alpha of about a
    /// tenth: an 8-bit channel has perhaps thirty steps left at that strength, and stretched
    /// that far each step is a visible ring. They are drawn by a shader now - a gaussian that
    /// falls smoothly to nothing, so there is no edge to find - and the grain is the other half
    /// of the cure: a light scatter of per-pixel noise breaks up whatever banding is left, which
    /// is what film grain is for.
    ///
    /// `blobSoftness` is the gaussian's rate over the unit disc: at three and a half the light
    /// is half gone a third of the way out, so a blob is mostly haze and hardly any core.
    /// `blobGrain` is how far each pixel may stray either side of the smooth value.
    static let blobSoftness: CGFloat = 3.5
    static let blobGrain: CGFloat = 0.4

    /// How far a blob fades on its own slow cycle: down to this share of its brightness.
    static let blobFadeLow: CGFloat = 0.3

    /// A tile of the same grain, for the still pictures the picker draws (round 351).
    ///
    /// The scene draws its grain on the GPU, per pixel; a still picture has no shader, so the
    /// grain is a small seeded tile laid over it with `destinationIn` - each pixel keeps some
    /// share of its light, which is the same effect as the shader's, drawn once.
    static let grainTile: UIImage? = {
        let side = 96
        var state: UInt64 = 0xA0761D6478BD642F
        var alpha = [UInt8](repeating: 255, count: side*side)
        for index in alpha.indices {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let unit = CGFloat((state >> 33) % 100_000)/100_000
            alpha[index] = UInt8(255*(1 - blobGrain*unit))
        }
        guard let provider = CGDataProvider(data: Data(alpha) as CFData),
              let image = CGImage(width: side, height: side, bitsPerComponent: 8,
                                  bitsPerPixel: 8, bytesPerRow: side,
                                  space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.alphaOnly.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false,
                                  intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: image, scale: 3, orientation: .up)
    }()

    /// A still layer with the grain run through it.
    static func grained(_ image: UIImage) -> UIImage {
        guard let tile = grainTile else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            image.draw(at: .zero)
            context.cgContext.setBlendMode(.destinationIn)
            UIColor(patternImage: tile).setFill()
            context.cgContext.fill(CGRect(origin: .zero, size: image.size))
        }
    }
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
    static let hazeBlobStrength: CGFloat = 1.55*5/7
    // Five blobs' worth of light shared among seven (round 351), so the scatter spreads the
    // haze rather than brightening it

    static func blobDrift(index: Int, seed: UInt64) -> (across: TimeInterval, down: TimeInterval,
                                                        swell: TimeInterval, phase: TimeInterval,
                                                        fade: TimeInterval) {
        var state = seed &+ UInt64(index) &* 0x9E3779B97F4A7C15
        func next(_ range: ClosedRange<Double>) -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            let unit = Double((state >> 33) % 100_000)/100_000
            return range.lowerBound + unit*(range.upperBound - range.lowerBound)
        }
        return (next(29...53), next(31...61), next(37...67), next(0...20), next(17...41))
        // `fade` (round 351) is how long each blob takes to dim to `blobFadeLow` and come back
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
        stillPicture(size: size, paddleFraction: paddleFraction,
                     blobs: glowBlobs(in: size, shuffle: stillShuffle))
    }

    /// The two cloud layers: how fast each crosses the field, and what it is made of.
    ///
    /// Two speeds rather than one, because parallax is what makes a flat picture read as
    /// depth - and the near layer is the fainter of the two, or it would be the thing you
    /// were looking at.
    static let cloudLayers: [(seed: UInt64, blobs: Int, strength: CGFloat,
                              crossing: TimeInterval, evolving: TimeInterval,
                              colour: UIColor)] = [
        (0xD1B54A32D192ED03, 22, 0.21, 210, 67,
         UIColor(red: 120/255, green: 70/255, blue: 165/255, alpha: 1)),
        (0x2545F4914F6CDD1D, 14, 0.10, 130, 41,
         UIColor(red: 165/255, green: 120/255, blue: 1, alpha: 1)),
    ]
    // More clouds, each fainter (round 351: "more random and disperse"), so the same amount of
    // weather is spread over more of the field rather than gathered in a few banks
    // `evolving` is how long each layer takes to swell and thin once (round 297). Neither
    // divides into its own crossing time or into the other's, so the two layers are never in
    // the same state twice in a run - which is what stops a drift on a loop reading as a loop
    // The colours are lifted well off the background's own purple. Added light on a very
    // dark ground is nearly nothing: the first pass used the border's purple at a tenth
    // alpha and drew cloud nobody could see, which is the same as no cloud at all

    /// The still picture of it, for the picker and the mock-up - one frame of the drift.
    static func cloudsImage(size: CGSize, paddleFraction: CGFloat) -> UIImage? {
        stillPicture(size: size, paddleFraction: paddleFraction,
                     blobs: cloudBlobs(in: size, shuffle: stillShuffle))
    }

    // MARK: - One layout for the scene and the picker

    /// One blob of a moving background, where it starts and how it moves.
    ///
    /// **Measured from the background's bottom-left corner, in points, the scene's way up.**
    /// The scene is what James plays against, so the scene's convention wins; the still
    /// picture flips it once, in `stillPicture`.
    struct PlacedBlob {
        let centre: CGPoint
        let size: CGSize
        let alpha: CGFloat
        let colour: UIColor
        /// Which pool or cloud layer it belongs to, for the drift that goes with it.
        let group: Int
        let rhythm: (across: TimeInterval, down: TimeInterval, swell: TimeInterval,
                     phase: TimeInterval, fade: TimeInterval)
        /// How long a cloud takes to cross the span. Nothing for a glow blob, which wanders.
        let crossing: TimeInterval
    }

    /// The shuffle the picker draws with. Any fixed value would do: what matters is that it
    /// is fixed, so the preview does not change every time the screen lays itself out.
    static let stillShuffle: UInt64 = 0

    /// A seed and a shuffle made into one seed, mixed well enough that shuffles one apart
    /// give layouts nothing alike (splitmix64's finaliser).
    static func mixed(_ seed: UInt64, _ shuffle: UInt64) -> UInt64 {
        var z = seed &+ shuffle &* 0x9E3779B97F4A7C15
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// How far a pool's centre may wander from where `glowPools` puts it, each way, as a
    /// share of the field, and how much bigger or smaller the whole pool may start.
    ///
    /// James, round 358: "the starting point of the backgrounds in the game is the same each
    /// time, is it possible to randomise the size and position of the blobs at the start?"
    /// Not so far that the two pools can swap sides - the diagonal is the composition - but
    /// far enough that no two games open on the same light.
    static let poolWander: CGFloat = 0.12
    static let poolSizeRange: ClosedRange<CGFloat> = 0.85...1.2

    /// Where a game's shuffle puts one pool, as a share of the field, how much it has grown,
    /// and the seed its blobs are drawn from.
    static func poolPlacement(_ index: Int, shuffle: UInt64)
    -> (centre: CGPoint, grown: CGFloat, seed: UInt64) {
        let pool = glowPools[index]
        let seed = mixed(pool.seed, shuffle)
        var state = seed
        func next() -> CGFloat {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((state >> 33) % 100_000)/100_000
        }
        let centre = CGPoint(x: pool.centre.x + (next()*2 - 1)*poolWander,
                             y: pool.centre.y + (next()*2 - 1)*poolWander)
        let grown = poolSizeRange.lowerBound
            + next()*(poolSizeRange.upperBound - poolSizeRange.lowerBound)
        return (centre, grown, seed)
    }

    /// Every blob of the Glow, laid out for a background of this size.
    ///
    /// `shuffle` is the run's own number: the scene picks a new one each game, and keeps it
    /// for the whole game so that a resize or a rotation lays the same blobs out again rather
    /// than reshuffling them in front of the player.
    static func glowBlobs(in size: CGSize, shuffle: UInt64) -> [PlacedBlob] {
        guard size.width > 0, size.height > 0 else { return [] }
        return glowPools.enumerated().flatMap { group, pool -> [PlacedBlob] in
            let (centre, grown, seed) = poolPlacement(group, shuffle: shuffle)
            let reach = size.width*pool.radius*grown
            let diameter = reach*hazeBlobShare

            return hazeBlobs(seed: seed).enumerated().map { index, placed in
                PlacedBlob(centre: CGPoint(x: size.width*centre.x + placed.offset.x*reach,
                                           y: size.height*centre.y - placed.offset.y*reach),
                           size: CGSize(width: diameter*placed.scale,
                                        height: diameter*0.78*placed.scale),
                           // Squashed, so a pool lies across the field rather than sitting
                           // in it as a ball
                           alpha: pool.strength*hazeBlobStrength*placed.share,
                           colour: pool.colour, group: group,
                           rhythm: blobDrift(index: index, seed: seed), crossing: 0)
            }
        }
    }

    /// Every cloud, laid out for a background of this size.
    ///
    /// Spread across a span one field wider than the field, so the gaps between them arrive
    /// as varied as the clouds do; the scene slides each one across that span and back.
    static func cloudBlobs(in size: CGSize, shuffle: UInt64) -> [PlacedBlob] {
        guard size.width > 0, size.height > 0 else { return [] }
        return cloudLayers.enumerated().flatMap { group, layer -> [PlacedBlob] in
            let seed = mixed(layer.seed, shuffle)
            return (0..<layer.blobs).map { index in
                var state = seed &+ UInt64(index) &* 0xD6E8FEB86659FD93
                func next() -> CGFloat {
                    state = state &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat((state >> 33) % 100_000)/100_000
                }
                let width = size.width*(0.34 + next()*0.42)
                let height = width*(0.34 + next()*0.20)
                let alpha = layer.strength*(0.55 + next()*0.6)
                let centre = CGPoint(x: next()*size.width*2,
                                     y: size.height*(0.12 + next()*0.76))
                return PlacedBlob(centre: centre, size: CGSize(width: width, height: height),
                                  alpha: alpha, colour: layer.colour, group: group,
                                  rhythm: blobDrift(index: index, seed: seed),
                                  crossing: layer.crossing*(0.8 + next()*0.45))
            }
        }
    }

    /// How bright the scene's blob shader is at a distance from the middle, `r` running from
    /// 0 at the centre to 1 at the rim - the same sum `backgroundBlobShaderSource` does, so a
    /// still picture is lit the way the game is.
    static func blobBody(at r: CGFloat) -> CGFloat {
        let d = r*r
        let t = min(max((d - 0.55)/0.45, 0), 1)
        return exp(-d*blobSoftness)*(1 - t*t*(3 - 2*t))
    }

    /// The gradient with these blobs over it, drawn as the scene would draw its first frame.
    static func stillPicture(size: CGSize, paddleFraction: CGFloat,
                             blobs: [PlacedBlob]) -> UIImage? {
        guard let base = gradientImage(size: size, paddleFraction: paddleFraction) else {
            return nil
        }
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        let light = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            cg.setBlendMode(.plusLighter)
            // Added to what is beneath, as the scene's `.add` blend is
            let stops = (0...24).map { CGFloat($0)/24 }
            for blob in blobs {
                let colours = stops.map {
                    blob.colour.withAlphaComponent(blobBody(at: $0)*blob.alpha).cgColor
                } as CFArray
                guard let fade = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colours, locations: stops) else { continue }
                cg.saveGState()
                cg.translateBy(x: blob.centre.x, y: size.height - blob.centre.y)
                cg.scaleBy(x: 1, y: blob.size.height/blob.size.width)
                cg.drawRadialGradient(fade, startCenter: .zero, startRadius: 0,
                                      endCenter: .zero, endRadius: blob.size.width/2,
                                      options: [])
                cg.restoreGState()
            }
        }
        return UIGraphicsImageRenderer(size: size).image { _ in
            base.draw(in: CGRect(origin: .zero, size: size))
            grained(light).draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// The gradient drawn out at a given size.
    ///
    /// UIKit's y runs down the image, so the stops above - measured from the top - are used
    /// as they are, and the paddle's fraction is what gets flipped.
    /// Which of the two fades to draw.
    enum Flavour { case purple, green }

    static func gradientImage(size: CGSize, paddleFraction: CGFloat,
                              flavour: Flavour = .purple) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let stops: (colours: [UIColor], locations: [CGFloat])
        switch flavour {
        case .purple: stops = gradientStops(paddleFraction: paddleFraction)
        case .green: stops = greenGradientStops(paddleFraction: paddleFraction)
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
