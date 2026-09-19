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

/// The four questions the app stops to ask.
///
/// **These were the app's other pop-up** (round 89's note, and §12.0's "two pop-up types, and
/// only one of them is `GigaBallAlert`"). MAIN MENU, RESET BALL, RESET DATA and SWIPE UP were a
/// storyboard sheet, `WarningViewController`, with its own card, its own three buttons and its
/// own copy of the blur, the parallax and the show/hide animation. Every improvement to the
/// pop-ups therefore had to be made twice, and three rounds of play-test feedback - round 82's
/// icons above titles, round 89's coloured glass on the confirm, round 85's "the main menu
/// pop-up needs a home icon" - landed on a different screen than the one they looked like they
/// were about. Round 162 made them one type, which is why this is an enum of *what is asked*
/// rather than another view controller.
///
/// The wiring is untouched: each answer posts the notification it always posted, to the same
/// observer. What went is the second card.
enum GigaBallConfirm: CaseIterable {
    /// Settings, mid-game: put a stuck ball back on the paddle.
    case resetBall
    /// Settings: throw away every score, statistic and setting on the device.
    case resetData
    /// The pause menu: end the run and go back to the menus.
    case mainMenu
    /// The first pause of all: how pausing works, and where to turn it off.
    case swipeUpToPause
    /// Leaving a daily mid-run: post the score so far, or walk away with nothing.
    ///
    /// James, round 300: "quitting a daily should post the partial score - ask the user with a
    /// pop up, otherwise assume not." Until now quitting burned the attempt and posted
    /// nothing, which the daily spec called honest but not the recommendation: the run was
    /// really played, and an attempt is spent whether or not the score is offered. Both
    /// buttons leave - the player has already said they are going - and only the green one
    /// posts, which is what "otherwise assume not" means when it is written as a control.
    case postDailyScore

    var title: String {
        switch self {
        case .resetBall: return "RESET BALL"
        case .resetData: return "RESET DATA"
        case .mainMenu: return "MAIN MENU"
        case .swipeUpToPause: return "SWIPE UP"
        case .postDailyScore: return "END ATTEMPT"
        }
    }

    var message: String {
        switch self {
        case .resetBall:
            return "Only reset if the ball becomes stuck."
        case .resetData:
            return "Are you sure you want to reset the game data? You will irreversibly lose "
                + "all game progress, statistics and settings."
            // **The line about in-app purchases went in round 328.** It had outlived the
            // purchases: the monetisation architecture came out before 1.3 (FUTURE-RELEASES,
            // "finish removing the monetisation architecture"), every StoreKit call in the app
            // is commented out, and there is nothing a player can buy - so the one sentence
            // still mentioning purchases was the app telling them about a shop that is not
            // there. Nothing else in the message changes: what it warns about is still true
        case .mainMenu:
            return "Are you sure?\nCurrent progress will be lost."
        case .swipeUpToPause:
            return "Swipe up anywhere to pause.\nDisable in Settings."
        case .postDailyScore:
            return "Leaving ends today's attempt.\n\nPost the score you have so far, or "
                + "leave without posting?"
        }
    }

    /// The mark above the title (play-test round 85, "the main menu pop-up needs a home icon").
    var symbol: String {
        switch self {
        case .resetBall: return "arrow.clockwise"
        case .resetData: return "trash.fill"
        case .mainMenu: return "house.fill"
        case .swipeUpToPause: return "hand.draw.fill"
        case .postDailyScore: return "trophy.fill"
        }
    }

    /// What the green button says, or nil where there is nothing to weigh up.
    ///
    /// The swipe-up explainer is the one of the four that asks nothing - it is telling the
    /// player something - so it gets the single lime OK a one-button pop-up already takes,
    /// which is exactly what the old sheet did with its centre button.
    var confirmTitle: String? {
        switch self {
        case .swipeUpToPause: return nil
        case .postDailyScore: return "Post"
        default: return "OK"
        }
    }

    /// What the pale button says. "Cancel" everywhere there is something to cancel.
    var dismissTitle: String {
        switch self {
        case .swipeUpToPause: return "OK"
        case .postDailyScore: return "Don't Post"
        // Not "Cancel": this pop-up cannot be cancelled, because the leaving was already
        // agreed to on the pop-up before it. Both buttons go home and only one of them posts
        default: return "Cancel"
        }
    }

    /// Asks it, on top of whatever is on screen.
    ///
    /// - Parameter restart: what a third button should do, where the screen behind has no
    ///   button of its own for it. **The pause screen shows Info, Play and Settings and no
    ///   Restart** - the replay only appears once a run has ended - so a player who has paused
    ///   and decided against going home has no way to start the level again without doing it.
    ///   James, round 329: "yes, add a restart button, that is a good idea! Restart only shows
    ///   up at game over, so show restart in the pop-up on occasions where it isn't already
    ///   available in the main view." Passed by the caller rather than decided here, because
    ///   "is it already on screen" is a question about the screen, not about the question.
    func show(on presenter: UIViewController, restart: (() -> Void)? = nil) {
        GigaBallAlert.show(on: presenter, title: title, message: message, symbol: symbol,
                           dismissTitle: dismissTitle,
                           dismiss: { GigaBallConfirm.stepBack(self, from: presenter) },
                           confirmTitle: confirmTitle,
                           confirm: confirmTitle == nil ? nil : { self.go(from: presenter) },
                           otherTitle: restart == nil ? nil : "Restart",
                           other: restart)
        // `dismiss` is never nil, which is what keeps a tap outside the card from answering
        // for the player: `GigaBallAlert` only offers tap-to-close where the pale button does
        // nothing, and none of these four are that. The old sheet could not be dismissed by
        // tapping past it either
    }

    /// The pale button: nothing happens, but the screen underneath is told to refresh.
    ///
    /// Settings redraws its rows on `returnNotificiation` - it is the screen a cancel returns
    /// to, and the row that opened the question may have been mid-change. Posted for all four,
    /// as the sheet posted it, rather than reasoned about per case: it is a refresh, and a
    /// screen that is not listening does not hear it.
    private static func stepBack(_ confirm: GigaBallConfirm, from presenter: UIViewController) {
        if confirm == .postDailyScore {
            leave(from: presenter)
            return
            // The pale button here is an answer, not a cancel - "leave without posting" - so
            // it does the leaving and posts nothing. Returning early also keeps the refresh
            // below from firing at a screen that is on its way out
        }
        if confirm == .swipeUpToPause {
            UserDefaults.standard.set(false, forKey: "firstPause")
            CloudKitHandler().saveToiCloud()
            // The explainer is shown once. Its only button is the pale one, so this is where
            // "seen it" is recorded - and it goes to iCloud, so a second device does not
            // explain the same gesture again
        }
        NotificationCenter.default.post(name: .returnNotificiation, object: nil)
    }

    /// The green button: the thing the pop-up exists to ask about.
    private func go(from presenter: UIViewController) {
        switch self {
        case .resetBall:
            NotificationCenter.default.post(name: .killBallRemoveVC, object: nil)
        case .resetData:
            NotificationCenter.default.post(name: .resetNotificiation, object: nil)
        case .postDailyScore:
            NotificationCenter.default.post(name: .postDailyPartialScore, object: nil)
            // The scene owns the score and the record-keeping, so it does the posting - this
            // only carries the player's answer to it. Sent before leaving, because the scene
            // is torn down on the way out
            GigaBallConfirm.leave(from: presenter)

        case .mainMenu:
            if DailyChallengeSession.shared.leavingWouldAbandonAScoringAttempt {
                GigaBallConfirm.postDailyScore.show(on: presenter)
                return
                // One question at a time: this one has already been answered "yes, leave",
                // and the next one is what to do with the score on the way out
            }
            GigaBallConfirm.leave(from: presenter)

        case .swipeUpToPause:
            break
            // No green button, so nothing reaches here
        }
    }

    /// Out of the run and back to the menus.
    ///
    /// Its own method since round 300, because three answers now end here - the main-menu
    /// confirm, and both buttons of the daily's post-or-not question - and the ordering
    /// inside it is the part that has been got wrong before.
    private static func leave(from presenter: UIViewController) {
        MenuViewController().clearSavedGame()
        // The save goes first, or the run just abandoned is offered back on the splash
        if let pauseMenu = presenter as? PauseMenuViewController {
            pauseMenu.moveToMainMenu()
            // The pause menu's own return carries the pack number the menus need to
            // reopen the right level list. Posting a bare copy of the same notifications
            // was how a quit-while-paused used to land on the pack list rather than on
            // the played pack's levels
        } else {
            NotificationCenter.default.post(name: .returnMenuNotification, object: nil)
            NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
            NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        }
    }
}

enum GigaBallAlert {

    /// Puts a message on top of `presenter`, in the game's own dress.
    ///
    /// Presented as a child view controller rather than modally, the way every other
    /// screen in this app is presented - which is what lets it sit inside the pause
    /// menu's own blur instead of sliding a white card over the top of it.
    static func show(on presenter: UIViewController, title: String, message: String,
                     symbol: String? = nil,
                     dismissTitle: String = "OK",
                     dismiss: (() -> Void)? = nil,
                     confirmTitle: String? = nil,
                     confirm: (() -> Void)? = nil,
                     otherTitle: String? = nil,
                     other: (() -> Void)? = nil) {
        show(on: presenter, title: title,
             attributed: NSAttributedString(string: message), symbol: symbol,
             dismissTitle: dismissTitle, dismiss: dismiss,
             confirmTitle: confirmTitle, confirm: confirm,
             otherTitle: otherTitle, other: other)
    }
    // `confirm` is deliberately the *last* parameter, so a trailing closure means the green
    // button - the one that does the thing. When `dismiss` was added after it, the daily's
    // free-play prompt silently rebound its trailing closure to the pale button and Cancel
    // started the run (play-test round 19). The order is the guard against that

    /// The same pop-up, for a message that carries more than words - the twists explainer
    /// wants each twist's badge in front of its name, the way every other screen names a
    /// twist (play-test round 17).
    /// - Parameter symbol: an SF Symbol drawn above the title, in the app's green with the
    ///   same glow the title wears (play-test round 39). Optional, and absent means no icon
    ///   rather than a placeholder - a pop-up with nothing to illustrate should not invent
    ///   something.
    static func show(on presenter: UIViewController, title: String,
                     attributed message: NSAttributedString,
                     symbol: String? = nil,
                     dismissTitle: String = "OK",
                     dismiss: (() -> Void)? = nil,
                     confirmTitle: String? = nil,
                     confirm: (() -> Void)? = nil,
                     otherTitle: String? = nil,
                     other: (() -> Void)? = nil) {
        let alert = GigaBallAlertViewController(title: title, message: message,
                                                symbol: symbol,
                                                dismissTitle: dismissTitle,
                                                confirmTitle: confirmTitle,
                                                confirm: confirm, dismiss: dismiss,
                                                otherTitle: otherTitle, other: other)
        alert.stoodDown = UIView.standDownParallax(under: presenter.view)
        // Before the alert's own view goes in, so the search finds the screen behind it and
        // not the card about to sit on top. Put back when the pop-up closes
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
    private let symbol: String?
    private let body: NSAttributedString
    private let dismissTitle: String
    private let confirmTitle: String?
    private let confirm: (() -> Void)?
    private let dismiss: (() -> Void)?
    /// A third answer, offered only where the screen behind has no button for it - see
    /// `GigaBallConfirm.show(on:restart:)`.
    private let otherTitle: String?
    private let other: (() -> Void)?
    private let card = UIView()

    /// The views behind this pop-up whose drift was taken off while it is up, to be handed
    /// back when it closes. Empty when the player has parallax off, or when whatever raised
    /// this never had any.
    var stoodDown: [UIView] = []

    private let hapticsSetting = UserDefaults.standard.bool(forKey: "hapticsSetting")
    private let parallaxSetting = UserDefaults.standard.bool(forKey: "parallaxSetting")
    private let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)

    init(title: String, message: NSAttributedString, symbol: String? = nil,
         dismissTitle: String, confirmTitle: String? = nil,
         confirm: (() -> Void)? = nil, dismiss: (() -> Void)? = nil,
         otherTitle: String? = nil, other: (() -> Void)? = nil) {
        self.heading = title.uppercased()
        self.symbol = symbol
        // Every pop-up wears the app's heading in capitals (play-test round 17), decided
        // here so no caller has to remember to shout
        self.body = message
        self.dismissTitle = dismissTitle
        self.confirmTitle = confirmTitle
        self.confirm = confirm
        self.dismiss = dismiss
        self.otherTitle = otherTitle
        self.other = other
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

        card.layer.cornerRadius = 20
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 0.34)
            let glass = UIVisualEffectView(effect: effect)
            glass.isUserInteractionEnabled = false
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.cornerConfiguration = .corners(radius: .fixed(20))
            card.insertSubview(glass, at: 0)
            NSLayoutConstraint.activate([
                glass.topAnchor.constraint(equalTo: card.topAnchor),
                glass.bottomAnchor.constraint(equalTo: card.bottomAnchor),
                glass.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            ])
            // The card is glass (play-test round 59). Same recipe as the round buttons -
            // `.regular` tinted with the app's purple, shaped rather than clipped - with the
            // tint a little heavier than a button's, because a card is a surface to read words
            // off rather than a mark to spot. Not interactive: the *buttons* on the card are
            // the controls, and a whole panel that responds to a press reads as a mistake.
            //
            // No border either. The hairline the flat card wore was standing in for an edge it
            // could not otherwise have; glass lights its own, and drawing both gives a card
            // two rims
        } else {
            card.backgroundColor = UIColor(white: 1, alpha: 0.08)
            card.layer.borderWidth = 1
            card.layer.borderColor = UIColor(white: 1, alpha: 0.12).cgColor
        }

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
        if confirmTitle == nil {
            SettingsTableViewCell.addColouredGlass(
                behind: button, cornerRadius: 22,
                tint: SettingsTableViewCell.prominentTint)
            button.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1),
                                 for: .normal)
        }
        // **Lime when it is the only button.** A pop-up with one button has no choice in it -
        // that button *is* the positive action, so it takes the colour the confirm button
        // takes. Where there are two, this one is the step-back and stays pale, or the pair
        // would be two shouts rather than a choice (round 91)
        if SettingsTableViewCell.addGlass(behind: button, cornerRadius: 22) != nil {
            button.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1),
                                 for: .normal)
        }
        // Only the pale one. The green button is the one that does the thing, and its colour
        // is how the pop-up says so - putting both behind the same material would make a
        // choice out of two identical shapes
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)

        var third: UIButton?
        if let otherTitle {
            let extra = UIButton(type: .system)
            extra.setTitle(otherTitle, for: .normal)
            extra.titleLabel?.font = .boldSystemFont(ofSize: 17)
            extra.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1), for: .normal)
            extra.backgroundColor = UIColor(white: 0.92, alpha: 1)
            extra.layer.cornerRadius = 22
            _ = SettingsTableViewCell.addGlass(behind: extra, cornerRadius: 22)
            extra.addTarget(self, action: #selector(otherTapped), for: .touchUpInside)
            third = extra
        }
        // **The third answer wears the pale material, like the step-back** (round 329). There is
        // one green button in a pop-up and it is the thing the pop-up was raised to ask about -
        // going to the main menu, here. Restart is a way out of the question rather than the
        // answer to it, so it reads as a second pale option rather than a rival shout

        var go: UIButton?
        if let confirmTitle {
            let confirmButton = UIButton(type: .system)
            confirmButton.setTitle(confirmTitle, for: .normal)
            confirmButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
            confirmButton.setTitleColor(UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1),
                                        for: .normal)
            confirmButton.backgroundColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            confirmButton.layer.cornerRadius = 22
            SettingsTableViewCell.addColouredGlass(
                behind: confirmButton, cornerRadius: 22,
                tint: SettingsTableViewCell.prominentTint)
            // Coloured glass rather than flat lime (round 89, James's request after seeing the
            // same idea in another app's picker). The green button is the one that does the
            // thing, so it is the right first place to try a material that is meant to be
            // noticed - and the pale one beside it stays plain glass, which is what keeps the
            // pair a choice rather than two shouts. Below iOS 26 both keep the flat colours
            // they have always had
            confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
            go = confirmButton
        }

        let ordered: [UIButton]
        let buttons: UIStackView
        if let third {
            ordered = [go, third, button].compactMap { $0 }
            buttons = UIStackView(arrangedSubviews: ordered)
            buttons.axis = .vertical
            buttons.distribution = .fillEqually
            for control in ordered {
                control.heightAnchor.constraint(equalToConstant: 44).isActive = true
            }
        } else {
            ordered = [button, go].compactMap { $0 }
            buttons = UIStackView(arrangedSubviews: ordered)
            buttons.axis = .horizontal
            buttons.distribution = .fillEqually
        }
        buttons.spacing = 10
        // **Three answers stack rather than squeeze** (round 329, James: "yes, add a restart
        // button, that is a good idea ... show restart in the pop-up on occasions where it isn't
        // already available in the main view"). Two sit side by side and read as a choice;
        // three across a card this wide would be three cramped words, and the order carries
        // more than the row does - what was asked for first, the way out second, the way back
        // last. A stacked row needs its own height, because a horizontal `fillEqually` takes
        // the tallest button's and a vertical one has nothing to take

        var pieces: [UIView] = [titleLabel, bodyLabel, buttons]
        if let symbol,
           let image = UIImage(systemName: symbol,
                               withConfiguration: UIImage.SymbolConfiguration(
                                   pointSize: 30, weight: .bold)) {
            let icon = UIImageView(image: image)
            icon.contentMode = .center
            icon.tintColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            icon.layer.shadowColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            icon.layer.shadowOpacity = 0.55
            icon.layer.shadowRadius = 10
            icon.layer.shadowOffset = .zero
            icon.layer.masksToBounds = false
            pieces.insert(icon, at: 0)
            // The app's green and the same glow the title wears, so the pair read as one
            // heading rather than as a picture with a caption. `.center` and no clipping,
            // for the reason the round buttons learned the hard way: aspect-fit would blow a
            // 30pt symbol up to fill whatever the stack gave it, and a masked layer cannot
            // draw the glow outside its own bounds
        }

        let stack = UIStackView(arrangedSubviews: pieces)
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(22, after: bodyLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        let wideEnoughToRead = card.widthAnchor.constraint(equalTo: view.widthAnchor,
                                                            constant: -68)
        wideEnoughToRead.priority = .defaultHigh
        // The card had only a maximum width and a minimum margin, so it hugged its own text:
        // a two-line message came out barely half the screen wide and read as cramped (James,
        // round 121, on the free-play pop-up). It now takes the width it is allowed, with the
        // 420 cap still required so an iPad gets a card rather than a banner, and high rather
        // than required priority so the cap wins when the two disagree

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                          constant: 34),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
            wideEnoughToRead,

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 26),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -22),
            buttons.heightAnchor.constraint(
                equalToConstant: buttons.axis == .vertical
                    ? 44*CGFloat(buttons.arrangedSubviews.count)
                        + buttons.spacing*CGFloat(max(0, buttons.arrangedSubviews.count - 1))
                    : 44),
            // **A row is one button tall; a column is as tall as it holds** (round 329). This
            // said 44 flat, which was right for every pop-up in the app until one of them had
            // three answers and stacked them - and a stack of three inside 44 points is three
            // buttons eight points tall, which is what the test caught. Derived from the
            // buttons rather than typed, so it cannot drift from what is in the stack
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyParallax()
    }
    // Here rather than in `viewDidLoad`, because the travel is measured from the window and
    // the card has no window until it is in one. Re-applying is harmless: the helper takes the
    // old group off before adding the new, so a rotation gets the iPad's travel rather than
    // two groups' worth of the phone's

    /// The card drifts with the tilt of the device, if the player has left that on.
    ///
    /// **The card, not the whole overlay** (round 163, James's call after the merge): the
    /// storyboard sheet this replaced drifted the same way and the app's screens all do, so a
    /// pop-up that sat perfectly still was the odd one out. The blurred backing stays put -
    /// what drifts is the thing being read, which is what makes it read as lifted off the
    /// screen rather than as the screen wobbling.
    ///
    /// Every pop-up in the app gets it from here: the twists explainer, the closed challenge,
    /// free play, a power-up's description and the four confirms. That is the point of there
    /// being one pop-up type.
    private func applyParallax() {
        guard parallaxSetting, UIView.motionEffectsAreWelcome else {
            card.motionEffects.forEach { card.removeMotionEffect($0) }
            return
            // A player who has turned it off may have turned it off while this was on screen -
            // Settings is one of the places a pop-up is raised from. The system's Reduce Motion
            // is asked here too (round 328), for the same reason and with the same answer
        }
        card.applyMenuParallax()
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

    @objc private func otherTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        let action = other
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
            self.stoodDown.forEach { $0.applyMenuParallax() }
            // The screen behind moves again. Re-applied rather than remembered as objects,
            // because the helper is the one recipe and hands back the same 25 or 50 the
            // screen had - and it takes any group off first, so a screen that has already
            // put its own back is not given a second
            next?()
            // After the pop-up has gone, so a screen it pushes is not fighting this one
            // for the window
        }
    }
}
