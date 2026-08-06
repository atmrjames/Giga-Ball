//
//  GameSceneMockView.swift
//  Megaball
//
//  A scale model of the game scene, drawn in UIKit.
//
//  The background setting used to be a name on a row - "Classic", "Solid", "Gradient" - and a
//  name is the one thing about a background that does not tell you anything. Three of the four
//  are shades of the same purple. Choosing between them meant leaving settings, starting a
//  level, going back, and doing it again.
//
//  So the picker shows them. Not a swatch of the colour, which would be no more use than the
//  name, but the scene as it will actually look: the walls, the brick field, the paddle and
//  the ball, in the proportions this device will give them. That is why the geometry comes
//  from `GameSceneLayout` rather than from anything invented here - the whole value of the
//  picture is that it is not an artist's impression.
//
//  Drawn rather than a real `SKScene`. Four live scenes in a scrolling row, each running its
//  own renderer to show a still image, is a lot of machinery for a picture that never moves -
//  and `GameScene` cannot be instantiated without a game to put in it.
//

import UIKit

final class GameSceneMockView: UIView {

    /// Which background this model is wearing.
    var background: GameBackground = .classic {
        didSet { if background != oldValue { setNeedsDisplay() } }
    }

    /// The screen being modelled, and the inset at the bottom of it.
    ///
    /// The device's own, so what the player is shown is the shape they will get. Set by the
    /// view controller once the window is known.
    var screen: CGSize = CGSize(width: 390, height: 844) {
        didSet { if screen != oldValue { setNeedsDisplay() } }
    }
    var bottomInset: CGFloat = 34 {
        didSet { if bottomInset != oldValue { setNeedsDisplay() } }
    }

    /// The ball and paddle the player has chosen, so the model is of their game.
    var themeIndex: Int = 0 {
        didSet { if themeIndex != oldValue { setNeedsDisplay() } }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        layer.masksToBounds = true
        contentMode = .redraw
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
        // The model is scaled to fit, so a change of size changes every part of the drawing
    }

    // MARK: - The field

    /// The level the model shows, eleven columns wide.
    ///
    /// A fixed arrangement rather than a real level or a random one. Every card in the picker
    /// has to differ only in its background, or the player is comparing two things at once.
    ///
    /// `.` empty, lower case a colour, `M` multi-hit, `X` indestructible.
    private static let field = [
        "ppppppppppp",
        ".bbbbbbbbb.",
        "..ggggggg..",
        "yyyMMMMMyyy",
        ".ooooooooo.",
        "....XXX...."
    ]

    private func colour(for character: Character) -> UIColor? {
        switch character {
        case "p": return #colorLiteral(red: 0.6156862745, green: 0.2352941176, blue: 0.8274509804, alpha: 1)
        case "b": return #colorLiteral(red: 0, green: 0.462745098, blue: 1, alpha: 1)
        case "g": return #colorLiteral(red: 0.1137254902, green: 0.6156862745, blue: 0.1058823529, alpha: 1)
        case "y": return #colorLiteral(red: 0.9725490196, green: 0.9058823529, blue: 0.1098039216, alpha: 1)
        case "o": return #colorLiteral(red: 0.9725490196, green: 0.4274509804, blue: 0.1098039216, alpha: 1)
        default: return nil
        }
    }
    // The scene's own brick colours. Copied rather than shared because they are instance
    // properties of `GameScene`, which needs a scene to exist before it has any

    private func artwork(for character: Character) -> UIImage? {
        switch character {
        case "M": return UIImage(named: "BrickMultiHit3")
        case "X": return UIImage(named: "BrickIndestructible2")
        case ".": return nil
        default: return UIImage(named: "BrickNormal")
        }
    }

    /// The colour of the bar above the playfield, as authored in `GameScene.sks`.
    private static let topBarColour = UIColor(red: 36/255, green: 0, blue: 52/255, alpha: 1)

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              bounds.width > 0, bounds.height > 0,
              screen.width > 0, screen.height > 0 else { return }

        let layout = GameSceneLayout(screen: screen, bottomInset: bottomInset)
        guard layout.gameWidth > 0 else { return }

        let scale = min(bounds.width/screen.width, bounds.height/screen.height)
        let inset = CGPoint(x: (bounds.width - screen.width*scale)/2,
                            y: (bounds.height - screen.height*scale)/2)

        context.saveGState()
        context.translateBy(x: inset.x, y: inset.y)
        context.scaleBy(x: scale, y: scale)
        // Everything below is in the modelled screen's own points, so it reads the same way
        // as the scene it is a model of

        drawBackground(layout, in: context)
        drawWalls(layout)
        drawBricks(layout)
        drawPaddleAndBall(layout)
        drawTopBar(layout, in: context)

        context.restoreGState()
    }

    private func drawBackground(_ layout: GameSceneLayout, in context: CGContext) {
        UIColor.black.setFill()
        context.fill(CGRect(origin: .zero, size: screen))
        // Behind everything, including the borders where the walls do not reach

        // The scene's background node spans from the bottom of the top bar to the bottom of
        // the screen - past the play area proper, into the home indicator's strip
        let area = CGRect(x: (screen.width - layout.gameWidth)/2,
                          y: layout.topBarHeight,
                          width: layout.gameWidth,
                          height: screen.height - layout.topBarHeight)

        switch background.paint {
        case .artwork:
            UIImage(named: "gameBackground")?.draw(in: area)
        case .solid(let colour):
            colour.setFill()
            context.fill(area)
        case .gradient:
            // Measured from the bottom of the background, which is where the scene measures
            // it from - the fade turns at the paddle rather than at the halfway mark
            let fraction = (area.maxY - paddleCentreY(layout))/area.height
            GameBackground.gradientImage(size: area.size, paddleFraction: fraction)?
                .draw(in: area)
        }
    }

    private func drawWalls(_ layout: GameSceneLayout) {
        let thickness = layout.wallThickness
        let left = CGRect(x: (screen.width - layout.gameWidth)/2 - thickness, y: 0,
                          width: thickness, height: screen.height)
        let right = CGRect(x: (screen.width + layout.gameWidth)/2, y: 0,
                           width: thickness, height: screen.height)
        // A wall wider than the border it fills simply runs off the edge, exactly as it does
        // in the scene. The view clips, which is what the screen does
        UIImage(named: "sideBlockLeft")?.draw(in: left)
        UIImage(named: "sideBlockRight")?.draw(in: right)
    }

    private func drawBricks(_ layout: GameSceneLayout) {
        let fieldLeft = (screen.width - layout.gameWidth)/2
        let top = layout.topBarHeight + layout.topGap

        for (row, line) in GameSceneMockView.field.enumerated() {
            for (column, character) in line.enumerated() {
                guard let image = artwork(for: character) else { continue }
                let frame = CGRect(x: fieldLeft + CGFloat(column)*layout.brickWidth,
                                   y: top + CGFloat(row)*layout.brickHeight,
                                   width: layout.brickWidth,
                                   height: layout.brickHeight)
                if let tint = colour(for: character) {
                    image.tinted(tint).draw(in: frame)
                } else {
                    image.draw(in: frame)
                }
            }
        }
    }

    /// Where the paddle's middle sits, measured down from the top of the screen.
    ///
    /// Below all twenty-two rows, not below the bricks that happen to be filled - the gap the
    /// player has to work in is the same whether a level is full or nearly cleared.
    private func paddleCentreY(_ layout: GameSceneLayout) -> CGFloat {
        layout.topBarHeight + layout.topGap
            + CGFloat(GameSceneLayout.brickRows)*layout.brickHeight
            + layout.paddleGap + layout.paddleHeight/2
    }

    private func drawPaddleAndBall(_ layout: GameSceneLayout) {
        let setup = LevelPackSetup()
        let theme = min(max(themeIndex, 0), setup.paddleImageArray.count - 1)

        let paddle = CGRect(x: (screen.width - layout.paddleWidth)/2,
                            y: paddleCentreY(layout) - layout.paddleHeight/2,
                            width: layout.paddleWidth,
                            height: layout.paddleHeight)
        setup.paddleImageArray[theme].draw(in: paddle)

        // Resting on the paddle, as it does before a launch, and off centre so the model
        // reads as a game in progress rather than as a diagram
        let ball = CGRect(x: screen.width/2 + layout.gameWidth*0.14,
                          y: paddle.minY - layout.ballSize - layout.brickHeight*1.5,
                          width: layout.ballSize,
                          height: layout.ballSize)
        setup.ballImageArray[theme].draw(in: ball)

        drawLivesRow(layout, paddleBottom: paddle.maxY, ballImage: setup.ballImageArray[theme])
    }

    /// The pill of remaining lives below the paddle.
    ///
    /// Included because it sits in the strip the Gradient background fades through, so leaving
    /// it out would flatter that one option and nothing else.
    private func drawLivesRow(_ layout: GameSceneLayout, paddleBottom: CGFloat,
                              ballImage: UIImage) {
        let ballSize = layout.ballSize
        let spacing = ballSize*1.6
        let padding = ballSize*0.55
        let slots = 3

        let size = CGSize(width: CGFloat(slots - 1)*spacing + ballSize + padding*2,
                          height: ballSize + padding*2)
        let safeBottom = screen.height - bottomInset
        let centreY = paddleBottom + (safeBottom - paddleBottom)*0.6
        guard centreY + size.height/2 < screen.height else { return }

        let pill = CGRect(x: (screen.width - size.width)/2, y: centreY - size.height/2,
                          width: size.width, height: size.height)
        UIColor(white: 1, alpha: 0.10).setFill()
        UIBezierPath(roundedRect: pill, cornerRadius: size.height/2).fill()

        for slot in 0..<slots {
            let x = pill.minX + padding + CGFloat(slot)*spacing
            ballImage.draw(in: CGRect(x: x, y: centreY - ballSize/2,
                                      width: ballSize, height: ballSize),
                           blendMode: .normal, alpha: 0.775)
        }
    }

    private func drawTopBar(_ layout: GameSceneLayout, in context: CGContext) {
        let bar = CGRect(x: 0, y: 0, width: screen.width, height: layout.topBarHeight)
        GameSceneMockView.topBarColour.setFill()
        context.fill(bar)

        let clearance = GameSceneLayout.hudTopClearance
        let button = layout.layoutUnit*2
        let inner = max((screen.width - layout.gameWidth)/2, 0) + layout.layoutUnit/2

        UIImage(named: "ButtonPause")?.draw(in: CGRect(x: inner, y: clearance,
                                                       width: button, height: button))

        let score = "1200"
        let font = UIFont(name: "FugazOne-Regular", size: 16)
            ?? UIFont.systemFont(ofSize: 16, weight: .black)
        let attributes: [NSAttributedString.Key: Any] = [.font: font,
                                                         .foregroundColor: UIColor.white]
        let measured = score.size(withAttributes: attributes)
        score.draw(at: CGPoint(x: screen.width - inner - measured.width,
                               y: clearance + (button - measured.height)/2),
                   withAttributes: attributes)
    }
}

extension UIImage {

    /// The brick artwork in a brick's colour.
    ///
    /// Shared with `BrickTypeIcons`, which draws the same bricks for the reference page.
    ///
    /// Multiplied rather than replaced, because that is what `colorBlendFactor` does to a
    /// sprite: the texture modulates the colour, so the shading in the artwork survives and a
    /// yellow brick is a shaded yellow brick rather than a yellow rectangle.
    func tinted(_ colour: UIColor) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        return UIGraphicsImageRenderer(size: size).image { context in
            draw(in: rect)
            colour.setFill()
            context.cgContext.setBlendMode(.multiply)
            context.cgContext.fill(rect)
            draw(in: rect, blendMode: .destinationIn, alpha: 1)
            // The multiply covers the whole rectangle, so the artwork is drawn once more to
            // put its transparency back. Through `draw(in:blendMode:alpha:)`, because the
            // plain `draw(in:)` composites normally whatever the context's blend mode is -
            // which quietly put the untinted white brick back on top
        }
    }
}
