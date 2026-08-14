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
/// 1.0 to 3.0 in tenths, which no index can express. The stored value is now the factor
/// itself, and the old index is read once and converted, so a player who has been on x1.25
/// for years opens this screen already on x1.25 rather than being reset to a default.
///
/// The old key is still written on every save, holding the nearest of the five steps. Nothing
/// in the app reads it any more, but a settings file is a save format like any other, and one
/// that goes silently empty is the sort of thing that bites a downgrade or a restore.
enum PaddleSpeed {

    static let range: ClosedRange<CGFloat> = 1.0...3.0
    static let step: CGFloat = 0.1

    /// What the five old steps meant, in order. Index 2 was the default, hence 1.5 below.
    static let legacyFactors: [CGFloat] = [1.00, 1.25, 1.50, 2.00, 3.00]
    static let fallback: CGFloat = 1.50

    static let key = "paddleSpeedFactor"
    static let legacyKey = "paddleSensitivitySetting"

    /// The value rounded to the slider's own tenths, and held inside the range.
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

    /// The stored speed: the player's own tenths where they have set them, the old index
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
    private var practice: PaddleSpeedScene?

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
        guard sceneView.bounds.width > 0 else { return }
        if practice == nil {
            let scene = PaddleSpeedScene(size: sceneView.bounds.size)
            scene.scaleMode = .resizeFill
            scene.speedFactor = CGFloat(slider.value)
            sceneView.presentScene(scene)
            practice = scene
        } else {
            practice?.size = sceneView.bounds.size
        }
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
        hint.text = "Drag below to try it"
        hint.font = .systemFont(ofSize: 13)
        hint.textColor = UIColor(white: 1, alpha: 0.45)
        hint.textAlignment = .center
        view.addSubview(hint)

        sceneView.translatesAutoresizingMaskIntoConstraints = false
        sceneView.backgroundColor = .clear
        sceneView.allowsTransparency = true
        sceneView.layer.cornerRadius = 22
        sceneView.layer.masksToBounds = true
        view.addSubview(sceneView)

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

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 24),
            title.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            title.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            valueLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
            valueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            valueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            slider.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 12),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            hint.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 24),
            hint.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),
            hint.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            sceneView.topAnchor.constraint(equalTo: hint.bottomAnchor, constant: 10),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            sceneView.bottomAnchor.constraint(equalTo: close.topAnchor, constant: -24),

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
/// moves - and every other thing the game does would only get in the way of the answer.
final class PaddleSpeedScene: SKScene {

    /// The multiplier under test. The paddle moves the finger's travel times this, which is
    /// `GameScene.touchesMoved`'s own line (`paddleX0 + paddleMovedDistance*paddleMovementFactor`).
    var speedFactor: CGFloat = PaddleSpeed.fallback

    private let paddle = SKSpriteNode()
    private let ball = SKShapeNode(circleOfRadius: 7)
    private var ballVelocity = CGVector(dx: 150, dy: -190)
    private var lastUpdate: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        removeAllChildren()

        paddle.color = UIColor(white: 0.95, alpha: 1)
        paddle.size = CGSize(width: 78, height: 11)
        paddle.position = CGPoint(x: size.width/2, y: 46)
        addChild(paddle)

        ball.fillColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        ball.strokeColor = .clear
        ball.position = CGPoint(x: size.width/2, y: size.height*0.6)
        addChild(ball)

        let frame = SKShapeNode(rect: CGRect(origin: .zero, size: size), cornerRadius: 22)
        frame.strokeColor = UIColor(white: 1, alpha: 0.12)
        frame.lineWidth = 1
        frame.fillColor = UIColor(white: 1, alpha: 0.03)
        frame.zPosition = -1
        addChild(frame)
    }

    /// Moved by hand rather than by the physics engine, so this scene needs no bodies, no
    /// contact delegate and no collision masks - and cannot inherit a rule from the real
    /// game by accident. What it borrows is the one line that matters, below.
    override func update(_ currentTime: TimeInterval) {
        let delta = lastUpdate == 0 ? 1/60 : min(currentTime - lastUpdate, 1/20)
        lastUpdate = currentTime

        var next = CGPoint(x: ball.position.x + ballVelocity.dx*CGFloat(delta),
                           y: ball.position.y + ballVelocity.dy*CGFloat(delta))

        let radius: CGFloat = 7
        if next.x < radius { next.x = radius; ballVelocity.dx = abs(ballVelocity.dx) }
        if next.x > size.width - radius {
            next.x = size.width - radius
            ballVelocity.dx = -abs(ballVelocity.dx)
        }
        if next.y > size.height - radius {
            next.y = size.height - radius
            ballVelocity.dy = -abs(ballVelocity.dy)
        }

        let paddleTop = paddle.position.y + paddle.size.height/2
        if next.y - radius <= paddleTop, ballVelocity.dy < 0,
           abs(next.x - paddle.position.x) <= paddle.size.width/2 + radius {
            next.y = paddleTop + radius
            ballVelocity.dy = abs(ballVelocity.dy)
            let offset = (next.x - paddle.position.x)/(paddle.size.width/2)
            ballVelocity.dx += offset*60
            let speed = hypot(ballVelocity.dx, ballVelocity.dy)
            ballVelocity = CGVector(dx: ballVelocity.dx/speed*240,
                                    dy: ballVelocity.dy/speed*240)
            // Bent by where it lands and renormalised, which is the game's bounce in
            // miniature - enough that catching it feels like catching it
        }

        if next.y < -radius*4 {
            next = CGPoint(x: size.width/2, y: size.height*0.6)
            ballVelocity = CGVector(dx: ballVelocity.dx < 0 ? -150 : 150, dy: -190)
            // Served again rather than lost. Nothing here is a game, so nothing here can
            // be failed - a player trying speeds out should not be punished for trying
        }

        ball.position = next
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
