//
//  PaddleSpeedViewController.swift
//  Megaball
//
//  Choosing a paddle speed by feeling it (play-test round 13, and the largest item of that
//  round): tapping the Paddle Speed row used to cycle through five multipliers, so the only
//  way to know what "x2.00" meant was to start a level, play it, come back and cycle again.
//  Now the row opens this: a slider, and under it a live paddle and ball to try it on.
//
//  The practice scene is deliberately the real thing rather than a picture of it. The paddle
//  is moved by the same arithmetic `GameScene.touchesMoved` uses - the finger's travel times
//  the factor under test - so the number being chosen is the number that ships. A ball
//  bounces around it with no bricks to hit and nothing to lose: a ball that gets past the
//  paddle is simply served again, because a practice scene that can be failed is a game, and
//  this is a ruler.
//
//  Built programmatically, like the daily's screens - no storyboard scene, so adding it cost
//  one file rather than a hand-edited storyboard.
//

import UIKit
import SpriteKit

/// The paddle speed setting, and the only place that knows how it is stored.
///
/// **Why this is not just an Int any more.** The setting shipped as five fixed steps - an
/// index 0-4 into 1.00, 1.25, 1.50, 2.00, 3.00 - and the play test asked for a slider from
/// 1.0 to 3.0 in quarter steps, which no index can express. The stored value is now the factor
/// itself, and the old index is read once and converted, so a player who has been on x1.25
/// for years opens this screen already on x1.25 rather than being reset to a default.
///
/// The old key is still written on every save, holding the nearest of the five steps. Nothing
/// in the app reads it any more, but a settings file is a save format like any other, and one
/// that goes silently empty is the sort of thing that bites a downgrade or a restore.
enum PaddleSpeed {

    static let range: ClosedRange<CGFloat> = 1.0...3.0
    static let step: CGFloat = 0.25
    // Quarters rather than tenths (James, round 121): 1.00, 1.25, 1.50 ... 3.00. Nine steps
    // a thumb can actually land on, and every one of the five old settings is still exactly
    // reachable - x1.25 and x1.50 were two of them

    /// What the five old steps meant, in order. Index 2 was the default, hence 1.5 below.
    static let legacyFactors: [CGFloat] = [1.00, 1.25, 1.50, 2.00, 3.00]
    static let fallback: CGFloat = 1.50

    static let key = "paddleSpeedFactor"
    static let legacyKey = "paddleSensitivitySetting"

    /// The value rounded to the slider's own quarters, and held inside the range.
    static func snapped(_ value: CGFloat) -> CGFloat {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return (clamped/step).rounded()*step
    }

    /// How the speed reads on the settings row: the same "x1.50" the row has always shown.
    static func label(_ value: CGFloat) -> String {
        String(format: "x%.2f", Double(snapped(value)))
    }

    /// The nearest of the five old steps, for the legacy key.
    static func legacyIndex(for value: CGFloat) -> Int {
        let target = snapped(value)
        var best = 0
        for (index, factor) in legacyFactors.enumerated()
        where abs(factor - target) < abs(legacyFactors[best] - target) {
            best = index
        }
        return best
    }

    /// The stored speed: the player's own choice where they have made one, the old index
    /// converted where they have not, and the shipped default for a fresh install.
    static func stored(_ defaults: UserDefaults = .standard) -> CGFloat {
        if let saved = defaults.object(forKey: key) as? Double {
            return snapped(CGFloat(saved))
        }
        if let legacy = defaults.object(forKey: legacyKey) as? Int,
           legacyFactors.indices.contains(legacy) {
            return legacyFactors[legacy]
        }
        return fallback
        // `object(forKey:)` rather than `integer(forKey:)` on purpose: the old index's
        // first value is 0, so "absent" and "x1.00" are the same answer to `integer` and
        // a fresh install would silently get the slowest paddle instead of the default
    }

    static func store(_ value: CGFloat, in defaults: UserDefaults = .standard) {
        defaults.set(Double(snapped(value)), forKey: key)
        defaults.set(legacyIndex(for: value), forKey: legacyKey)
    }
}

final class PaddleSpeedViewController: UIViewController, MenuNavigable {

    let defaults = UserDefaults.standard
    var hapticsSetting: Bool = true
    private let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)

    /// Told when the speed changes, so the settings row behind this screen redraws.
    var onChange: ((CGFloat) -> Void)?

    private let valueLabel = UILabel()
    private let slider = UISlider()
    private let sceneView = SKView()
    private let field = UIView()
    private let backdrop = GameBackgroundView()
    private var practice: PaddleSpeedScene?
    private var fieldAspect: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        installMenuNavigationSwipes()
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")

        view.backgroundColor = UIColor(red: 0.1607843137, green: 0, blue: 0.2352941176,
                                       alpha: 0.25)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blur, at: 0)
        // The same dark blur every menu screen stands on

        buildLayout()
        slider.value = Float(PaddleSpeed.stored(defaults))
        refreshValueLabel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shapeFieldToThePlayArea()
        guard sceneView.bounds.width > 0 else { return }
        if practice == nil {
            let scene = PaddleSpeedScene(size: sceneView.bounds.size)
            scene.scaleMode = .resizeFill
            scene.speedFactor = PaddleSpeed.snapped(CGFloat(slider.value))
            scene.themeIndex = defaults.integer(forKey: "ballSetting")
            sceneView.presentScene(scene)
            practice = scene
        } else if practice?.size != sceneView.bounds.size {
            practice?.size = sceneView.bounds.size
        }
        // Only when it has actually changed: assigning the size re-lays the scene, and doing
        // that on every layout pass is half of why the first cut looked jittery
    }

    /// Makes the practice field the shape of the player's own play area.
    ///
    /// `GameBackgroundView` draws a *model of the whole screen*, letterboxed inside whatever
    /// bounds it is given - so a field of some other shape gets the background painted down
    /// its middle with dead space either side, and a ball that leaves the painted part while
    /// still inside the field. The background chooser solved this already: ask the view what
    /// it is modelling and make the container that shape (`refreshMockShape`). Same here, so
    /// the field, the picture and the physics are one rectangle.
    private func shapeFieldToThePlayArea() {
        let screen = view.window?.bounds.size ?? view.bounds.size
        let inset = view.window?.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom
        backdrop.screen = screen
        backdrop.bottomInset = inset

        let modelled = backdrop.modelledSize
        let ratio = modelled.width/max(modelled.height, 1)
        guard abs((fieldAspect?.multiplier ?? 0) - ratio) > 0.001 else { return }
        fieldAspect?.isActive = false
        let aspect = field.widthAnchor.constraint(equalTo: field.heightAnchor,
                                                  multiplier: ratio)
        aspect.isActive = true
        fieldAspect = aspect
    }

    private func buildLayout() {
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "PADDLE SPEED"
        title.font = UIFont(name: "HelveticaNeue-Bold", size: 40) ?? .boldSystemFont(ofSize: 40)
        title.adjustsFontSizeToFitWidth = true
        title.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        title.textAlignment = .center
        view.addSubview(title)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        valueLabel.textColor = UIColor(white: 0.95, alpha: 1)
        valueLabel.textAlignment = .center
        view.addSubview(valueLabel)

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = Float(PaddleSpeed.range.lowerBound)
        slider.maximumValue = Float(PaddleSpeed.range.upperBound)
        slider.minimumTrackTintColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        slider.maximumTrackTintColor = UIColor(white: 1, alpha: 0.2)
        slider.thumbTintColor = UIColor(white: 0.95, alpha: 1)
        slider.addTarget(self, action: #selector(sliderMoved), for: .valueChanged)
        slider.addTarget(self, action: #selector(sliderSettled),
                         for: [.touchUpInside, .touchUpOutside])
        view.addSubview(slider)

        let hint = UILabel()
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.text = "Drag in the field to try it"
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = UIColor(white: 1, alpha: 0.45)
        hint.textAlignment = .center
        view.addSubview(hint)

        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.cornerRadius = 22
        field.layer.masksToBounds = true
        view.addSubview(field)

        backdrop.translatesAutoresizingMaskIntoConstraints = false
        backdrop.background = GameBackground.stored(defaults.integer(forKey: "backgroundSetting"))
        field.addSubview(backdrop)
        // The player's own background behind the practice field, the way the background
        // chooser shows it (James, round 121: "should look how they look in the main game
        // view, including adopting the background and theme selected")

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .clear
        sceneView.allowsTransparency = true
        field.addSubview(sceneView)

        let close = UIButton(type: .system)
        close.translatesAutoresizingMaskIntoConstraints = false
        close.backgroundColor = UIColor(white: 0.92, alpha: 1)
        close.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        close.layer.cornerRadius = MainMenuCollectionViewCell.smallButtonSize/2
        close.setImage(UIImage(systemName: "xmark",
                               withConfiguration: UIImage.SymbolConfiguration(
                                pointSize: 18, weight: .heavy)), for: .normal)
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)
        applyRoundGlass(to: close, radius: MainMenuCollectionViewCell.smallButtonSize/2,
                        symbol: "xmark", pointSize: 18, rimmed: false)
        // 55pt in from the edge, where the daily's close sits

        let fillsTheRoom = field.bottomAnchor.constraint(equalTo: valueLabel.topAnchor,
                                                         constant: -20)
        fillsTheRoom.priority = .defaultHigh

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 24),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            hint.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            field.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 12),
            field.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            field.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                           constant: 24),
            field.bottomAnchor.constraint(lessThanOrEqualTo: valueLabel.topAnchor,
                                          constant: -20),
            fillsTheRoom,
            // Centred, as tall as the room allows and as wide as that height makes it - the
            // shape comes from `shapeFieldToThePlayArea`, so these only say where it sits.
            // `fillsTheRoom` is the one that makes it *grow*: with only a top, a maximum
            // width and a maximum bottom, autolayout satisfies everything by collapsing the
            // field to nothing, which is exactly what the first build did

            backdrop.topAnchor.constraint(equalTo: field.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: field.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: field.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: field.trailingAnchor),

            sceneView.topAnchor.constraint(equalTo: field.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: field.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: field.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: field.trailingAnchor),

            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            valueLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -8),

            slider.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -28),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),
            // The slider sits *under* the field it controls (James, round 121), where the
            // thumb already is - reaching over the thing being judged to change it put a
            // hand across the only part of the screen worth looking at

            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 55),
            close.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -25),
            close.widthAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
            close.heightAnchor.constraint(equalToConstant: MainMenuCollectionViewCell.smallButtonSize),
        ])
    }

    private func refreshValueLabel() {
        valueLabel.text = PaddleSpeed.label(CGFloat(slider.value))
    }

    @objc private func sliderMoved() {
        let snapped = PaddleSpeed.snapped(CGFloat(slider.value))
        let changed = PaddleSpeed.label(CGFloat(slider.value)) != valueLabel.text
        slider.value = Float(snapped)
        practice?.speedFactor = snapped
        refreshValueLabel()
        if changed && hapticsSetting { interfaceHaptic.impactOccurred() }
        // A tick per tenth, so the slider is felt as steps rather than as a smear - and
        // only when the number actually changes, or a slow drag buzzes continuously
    }

    @objc private func sliderSettled() {
        let value = PaddleSpeed.snapped(CGFloat(slider.value))
        PaddleSpeed.store(value, in: defaults)
        onChange?(value)
        // Written when the finger lifts rather than on every tenth: the setting is saved
        // to disk and to iCloud's neighbours, and a drag across the range is twenty values
        // nobody chose on the way to the one they did
    }

    @objc private func closeTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        menuNavigationGoBack()
    }

    // MARK: - Menu plumbing

    func menuNavigationGoBack() {
        MenuNavigation.shared.record(self)
        // Remembered, so a swipe from the right edge brings this screen back
        removeAnimate()
        NotificationCenter.default.post(name: .reanimateNotificiation, object: nil)
        // How every child screen tells the one underneath to come back out of the fade
        // it went into when this opened - without it Settings stays dimmed behind nothing
    }

    func showAnimate() {
        view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
            self.view.transform = .identity
        }
    }

    func removeAnimate() {
        practice?.isPaused = true
        // The scene is a live physics simulation; a screen on its way out should not be
        // running one behind the screen it is uncovering
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.view.alpha = 0
        }) { finished in
            if finished {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        }
    }
}

/// The practice field: one paddle, one ball, four walls and nothing to lose.
///
/// Small on purpose. It answers one question - how far does the paddle go when my thumb
/// moves - and everything else the game does would get in the way of the answer.
///
/// **It is the game's own physics, not an imitation.** The first cut moved the ball by hand
/// in `update` and drew a white bar for a paddle; it read as jittery and as somebody else's
/// game (James, round 121). The ball is a physics body now, with the same restitution,
/// friction and damping the real ball has, so SpriteKit interpolates it exactly as it does
/// in play - and the ball and paddle wear the player's own chosen theme.
final class PaddleSpeedScene: SKScene {

    /// The multiplier under test. The paddle moves the finger's travel times this, which is
    /// `GameScene.touchesMoved`'s own line (`paddleX0 + paddleMovedDistance*paddleMovementFactor`).
    var speedFactor: CGFloat = PaddleSpeed.fallback

    /// The ball and paddle the player has chosen, by index into the theme arrays.
    var themeIndex: Int = 0

    private let paddle = SKSpriteNode()
    private let ball = SKSpriteNode()
    private var built = false

    /// How fast the practice ball travels. Slower than the game's own, because this field is
    /// a fraction of the height and a ball at full speed would cross it faster than a thumb
    /// can answer - which would make the screen a test of reflexes rather than of the number.
    private let ballSpeed: CGFloat = 260

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        physicsWorld.gravity = .zero
        build()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard built, size.width > 0 else { return }
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        physicsBody?.friction = 0
        physicsBody?.restitution = 1
        paddle.position.y = 40
        paddle.position.x = min(max(paddle.position.x, paddle.size.width/2),
                                size.width - paddle.size.width/2)
        // The walls move with the view. Rebuilt rather than scaled, because an edge loop is
        // built from a rectangle and cannot be resized in place
    }

    private func build() {
        guard built == false, size.width > 0 else { return }
        built = true
        let setup = LevelPackSetup()

        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        physicsBody?.friction = 0
        physicsBody?.restitution = 1

        let index = setup.paddleImageArray.indices.contains(themeIndex) ? themeIndex : 0
        paddle.texture = SKTexture(image: setup.paddleImageArray[index])
        paddle.size = CGSize(width: 78, height: 12)
        paddle.position = CGPoint(x: size.width/2, y: 40)
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.size)
        paddle.physicsBody?.isDynamic = false
        paddle.physicsBody?.friction = 0
        paddle.physicsBody?.restitution = 1
        addChild(paddle)

        ball.texture = SKTexture(image: setup.ballImageArray[index])
        ball.size = CGSize(width: 14, height: 14)
        ball.position = CGPoint(x: size.width/2, y: size.height*0.55)
        ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        ball.physicsBody?.friction = 0
        ball.physicsBody?.restitution = 1
        ball.physicsBody?.linearDamping = 0
        ball.physicsBody?.angularDamping = 0
        ball.physicsBody?.allowsRotation = false
        ball.physicsBody?.affectedByGravity = false
        ball.physicsBody?.velocity = CGVector(dx: ballSpeed*0.6, dy: -ballSpeed*0.8)
        addChild(ball)
        // The same body settings the game gives its ball - perfectly elastic, frictionless
        // and undamped - so a bounce here is a bounce there
    }

    /// Keeps the speed constant and serves the ball again when it gets past the paddle.
    ///
    /// `ballSpeedControl`'s job, in miniature: an elastic bounce off a moving paddle can add
    /// or lose a little speed, and the game renormalises every frame rather than trusting the
    /// engine to conserve it.
    override func update(_ currentTime: TimeInterval) {
        guard let body = ball.physicsBody else { return }
        let speed = hypot(body.velocity.dx, body.velocity.dy)
        if speed > 1 {
            body.velocity = CGVector(dx: body.velocity.dx/speed*ballSpeed,
                                     dy: body.velocity.dy/speed*ballSpeed)
        }

        if ball.position.y < 0 {
            ball.position = CGPoint(x: size.width/2, y: size.height*0.55)
            body.velocity = CGVector(dx: body.velocity.dx < 0 ? -ballSpeed*0.6 : ballSpeed*0.6,
                                     dy: -ballSpeed*0.8)
            // Served again rather than lost. Nothing here is a game, so nothing here can be
            // failed - a player trying speeds out should not be punished for trying
        }

        let floor = CGFloat(0.25)*ballSpeed
        if abs(body.velocity.dy) < floor {
            let sign: CGFloat = body.velocity.dy < 0 ? -1 : 1
            body.velocity = CGVector(dx: body.velocity.dx, dy: sign*floor)
        }
        // The game's own refusal to let a ball run flat (`breakHorizontalRuns`), because a
        // ball crossing this little field sideways for ever answers no question at all
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let travelled = touch.location(in: self).x - touch.previousLocation(in: self).x
        let half = paddle.size.width/2
        paddle.position.x = min(max(paddle.position.x + travelled*speedFactor, half),
                                size.width - half)
        // `GameScene.touchesMoved`'s line, clamped at the walls the way the game clamps at
        // its own: the finger's travel times the factor, never the finger's position - which
        // is why a fast paddle outruns the thumb rather than teleporting to it
    }
}
