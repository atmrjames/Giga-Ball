//
//  GigaBallAlert.swift
//  Megaball
//
//  The app's own pop-up.
//
//  Giga-Ball has always had two kinds of message: the game's own - the pause menu's
//  warning sheet, dark and purple and blurred like every other screen - and
//  `UIAlertController`, which is white, rounded and unmistakably somebody else's. The
//  newer screens reached for the system one because it is one line of code, and the play
//  test noticed immediately: half the app's messages look like the app and half look like
//  iOS (round 16).
//
//  So this is the app's alert, in one place, with the same call shape the system one had
//  so a screen can swap to it without rearranging itself. It is deliberately small: a
//  title, a message, and one button that dismisses. Anything needing a choice still wants
//  a considered screen rather than a pop-up.
//

import UIKit

enum GigaBallAlert {

    /// Puts a message on top of `presenter`, in the game's own dress.
    ///
    /// Presented as a child view controller rather than modally, the way every other
    /// screen in this app is presented - which is what lets it sit inside the pause
    /// menu's own blur instead of sliding a white card over the top of it.
    static func show(on presenter: UIViewController, title: String, message: String,
                     dismissTitle: String = "Got it",
                     confirmTitle: String? = nil,
                     confirm: (() -> Void)? = nil,
                     dismiss: (() -> Void)? = nil) {
        show(on: presenter, title: title,
             attributed: NSAttributedString(string: message),
             dismissTitle: dismissTitle, confirmTitle: confirmTitle,
             confirm: confirm, dismiss: dismiss)
    }

    /// The same pop-up, for a message that carries more than words - the twists explainer
    /// wants each twist's badge in front of its name, the way every other screen names a
    /// twist (play-test round 17).
    static func show(on presenter: UIViewController, title: String,
                     attributed message: NSAttributedString,
                     dismissTitle: String = "Got it",
                     confirmTitle: String? = nil,
                     confirm: (() -> Void)? = nil,
                     dismiss: (() -> Void)? = nil) {
        let alert = GigaBallAlertViewController(title: title, message: message,
                                                dismissTitle: dismissTitle,
                                                confirmTitle: confirmTitle,
                                                confirm: confirm, dismiss: dismiss)
        presenter.addChild(alert)
        alert.view.frame = presenter.view.bounds
        alert.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presenter.view.addSubview(alert.view)
        alert.didMove(toParent: presenter)
        alert.appear()
    }
}

final class GigaBallAlertViewController: UIViewController {

    private let heading: String
    private let body: NSAttributedString
    private let dismissTitle: String
    private let confirmTitle: String?
    private let confirm: (() -> Void)?
    private let dismiss: (() -> Void)?
    private let card = UIView()

    private let hapticsSetting = UserDefaults.standard.bool(forKey: "hapticsSetting")
    private let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)

    init(title: String, message: NSAttributedString, dismissTitle: String,
         confirmTitle: String? = nil, confirm: (() -> Void)? = nil,
         dismiss: (() -> Void)? = nil) {
        self.heading = title.uppercased()
        // Every pop-up wears the app's heading in capitals (play-test round 17), decided
        // here so no caller has to remember to shout
        self.body = message
        self.dismissTitle = dismissTitle
        self.confirmTitle = confirmTitle
        self.confirm = confirm
        self.dismiss = dismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0.1607843137, green: 0, blue: 0.2352941176,
                                       alpha: 0.45)
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = view.bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blur, at: 0)

        if dismiss == nil {
            view.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(dismissTapped)))
        }
        // Tapping outside closes it, the way the app's other overlays behave - unless both
        // buttons *do* something, in which case there is no harmless answer to give on the
        // player's behalf and the choice has to be made on the card

        card.backgroundColor = UIColor(white: 1, alpha: 0.08)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.text = heading
        titleLabel.font = .systemFont(ofSize: 22, weight: .black)
        titleLabel.textColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.applyGigaBallGlow(radius: 10, opacity: 0.35)

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 15)
        bodyLabel.textColor = UIColor(white: 1, alpha: 0.8)
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.attributedText = body
        // Set after the font and colour, not before: a plain-string message arrives with no
        // attributes of its own and would otherwise land as unstyled black text

        let button = UIButton(type: .system)
        button.setTitle(dismissTitle, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 17)
        button.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1), for: .normal)
        button.backgroundColor = UIColor(white: 0.92, alpha: 1)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        let buttons = UIStackView(arrangedSubviews: [button])
        buttons.axis = .horizontal
        buttons.spacing = 10
        buttons.distribution = .fillEqually

        if let confirmTitle {
            let go = UIButton(type: .system)
            go.setTitle(confirmTitle, for: .normal)
            go.titleLabel?.font = .boldSystemFont(ofSize: 17)
            go.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1), for: .normal)
            go.backgroundColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            go.layer.cornerRadius = 22
            go.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
            buttons.addArrangedSubview(go)
            // The green one is the one that does the thing; the pale one steps back. Two
            // is the most this pop-up offers - a choice with three answers wants a screen
        }

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel, buttons])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(22, after: bodyLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                          constant: 34),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 420),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 26),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
            buttons.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    func appear() {
        view.alpha = 0
        card.transform = CGAffineTransform(scaleX: 1.12, y: 1.12)
        UIView.animate(withDuration: 0.22) {
            self.view.alpha = 1
            self.card.transform = .identity
        }
    }

    @objc private func confirmTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let action = confirm
        close { action?() }
    }

    @objc private func dismissTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let action = dismiss
        close { action?() }
    }

    private func close(then next: (() -> Void)?) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }) { _ in
            self.willMove(toParent: nil)
            self.view.removeFromSuperview()
            self.removeFromParent()
            next?()
            // After the pop-up has gone, so a screen it pushes is not fighting this one
            // for the window
        }
    }
}
