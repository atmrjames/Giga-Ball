//
//  SplashViewController.swift
//  Megaball
//
//  Created by James Harding on 18/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

/// Whether the splash screen is currently covering everything.
///
/// A game can be resumed or started while it is still up, and anything that animates in the
/// scene underneath is spent behind a full-screen cover - the player sees the end of it at
/// best. Read by `GameScene` so the opening field waits its turn.
var splashScreenIsShowing = false

/// What the resuming screen says, as the four lines round 310 asked for.
///
/// A type of its own rather than a run of assignments inside `viewDidLoad`, because the only
/// way to see this screen is to force-quit a game and relaunch, and there are nine shapes of
/// save that reach it: three modes, a single level, and a daily in either mode whose day may be
/// today's or long closed. Every one of them was being decided by an `if` nested inside the
/// unwrap of an optional save, and round 310 reordered and reworded all four lines at once.
///
/// The screen keeps the *look*; this owns the words, so the suite can read them.
enum ResumeCard {

    struct Lines: Equatable {

        /// The heading, in the face and colour a menu gives its own title.
        var heading = "RESUMING"

        /// Which mode is being resumed.
        var mode = ""

        /// What within it: the pack and level, or the day and its mode. Empty in the endless
        /// modes, which have nothing under their name to say.
        var detail = ""

        /// The score row, split so the screen can set two faces on one line.
        var scoreTitle = ""
        var scoreValue = ""

        /// What the rack has left, under the score. Empty where the mode has no rack to speak
        /// of - the endless modes are one ball, and saying so every time is not news.
        var lives = ""
    }

    /// How the rack is spoken about, which is the pause screen's own wording.
    static func livesLine(_ balls: Int) -> String {
        balls == 1 ? "Last ball" : "\(balls) balls left"
    }

    /// What the rack has left, or nothing at all.
    ///
    /// James, round 311: "the number of lives could come back underneath the score." It went in
    /// round 310 with the footnote it shared a label with, and it is worth having - a run
    /// resumed with one ball left is a different proposition from one resumed with three.
    ///
    /// The endless modes say nothing unless something granted them a rack, which is the rule
    /// the pause screen already follows: it is not news that an endless run has one ball, and
    /// it is news when a twist has given more.
    private static func livesRow(_ game: SavedGame, endless: Bool) -> String {
        if endless, game.numberOfLives <= 0 { return "" }
        return livesLine(game.numberOfLives + 1)
        // Plus the one on the paddle: `numberOfLives` is the *rack*, and a player counting
        // their balls counts the one they are about to serve as well (round 228's lesson,
        // written down in `dailyStartingLives`)
    }

    /// - Parameter fallbackMode: the remembered mode, for saves written before `gameMode`
    ///   existed. Passed in rather than read here so the suite is not asking `UserDefaults`
    ///   what the last player was doing.
    static func lines(for game: SavedGame, fallbackMode: GameMode) -> Lines {
        var lines = Lines()
        let packs = LevelPackSetup()

        if let key = game.dailyDateKey {
            let session = DailyChallengeSession.shared
            let challenge = DailyChallengeGenerator.challenge(forKey: key)
            lines.mode = GameMode.daily.name
            var detail = [challenge.mode == .classic
                          ? packs.levelNameArray[game.levelNumber]
                          : challenge.mode.name]
            detail.append(session.displayName(forKey: key).capitalized)
            // **The day on a line of its own, under what is being played** (James, round 311:
            // "for the Daily Challenge, put the date detail underneath the game mode and before
            // Competition run"). It used to share a line with the mode, joined by a comma, and
            // the two are different kinds of fact - one says what you are playing and the other
            // says which day's it is
            if key == session.todayKey, game.dailyWasScoringAttempt == true {
                detail.append("Competition run")
            }
            lines.detail = detail.joined(separator: "\n")
            lines.lives = livesRow(game, endless: challenge.mode.isEndless)
            // **The day's own word for what this run is** (James, round 310: "if it's a
            // competition run on a daily challenge say that in the details label"). It replaces
            // "Still your scoring attempt.", which said the same thing as a footnote under the
            // score and read as a warning rather than as a fact about the run.
            //
            // A closed day says nothing (play-test round 20): it has no attempt left to be, and
            // the pause menu stops the run and explains properly once the player is in it
            lines.scoreTitle = challenge.mode == .classic ? "Score" : "Height"
            lines.scoreValue = challenge.mode == .classic
                ? String(game.totalScore)
                : String(game.endlessHeight) + "m"
            return lines
        }

        if game.levelNumber == 0 {
            let saved = game.gameMode.flatMap(GameMode.init(rawValue:)) ?? fallbackMode
            lines.mode = saved == .endlessII ? GameMode.endlessII.name : GameMode.endless.name
            // **The save's own mode, where it has one** (round 170). It used to ask the
            // remembered key, which a force quit can lose before it reaches disk - and then this
            // card offered to resume "Endless Mode" into a Mayhem run. Saves written before the
            // field existed still fall back to the key, which is what they were always doing
            lines.scoreTitle = "Height"
            lines.scoreValue = String(game.endlessHeight) + "m"
            lines.lives = livesRow(game, endless: true)
            return lines
        }

        if game.numberOfLevels > 1 {
            lines.mode = GameMode.classic.name
            let within = game.levelNumber - packs.startLevelNumber[game.packNumber] + 1
            lines.detail = packs.levelPackNameArray[game.packNumber]
                + " - Level \(within) of \(packs.numberOfLevels[game.packNumber])"
                + "\n" + packs.levelNameArray[game.levelNumber]
            // Pack before level, the order James asked the daily's card for in the same round,
            // and **the level's own name under it** (James, round 311: "for the classic mode
            // level, can it also show the name of the level, maybe on another line
            // underneath"). Where it is in the pack and what it is called are two different
            // questions, and a player coming back after a day away wants the second one
        } else {
            lines.mode = "Single Level Mode"
            lines.detail = packs.levelNameArray[game.levelNumber]
        }
        lines.scoreTitle = "Score"
        lines.scoreValue = String(game.totalScore)
        lines.lives = livesRow(game, endless: false)
        return lines
    }
}

class SplashViewController: UIViewController {
    
    @IBOutlet var splashScreenLogo1: UIImageView!
    @IBOutlet var splashScreenLogo2: UIImageView!
    @IBOutlet var splashScreenLogo3: UIImageView!
    @IBOutlet var splashScreenLogo4: UIImageView!
    @IBOutlet var splashScreenLogo5: UIImageView!
    @IBOutlet var splashScreenLogo6: UIImageView!
        
    @IBOutlet var creatorLabel: UILabel!
    @IBOutlet var resumingLabel: UILabel!
    
    /// The Cancel row's table view, kept only because the storyboard scene owns it.
    ///
    /// Round 310 replaced it with the app's large round button, and `layOutResumeCard` takes it
    /// out of the hierarchy - a hidden view keeps its frame, and seventy points of it sat in
    /// the middle of the new card. The outlet stays because deleting a view from a storyboard
    /// scene means editing the XML by hand for no gain; the tests assert it has no superview.
    @IBOutlet var cancelResumeButton: UITableView!
    
    @IBOutlet var packNameLabel: UILabel!
    @IBOutlet var levelNumberLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!

    var skipInProgress = false

    @IBAction func tapGesture(_ sender: Any) {
        if self.resumeInProgress == false && self.skipInProgress == false {
            skipInProgress = true
            func stripAnimations(_ subject: UIView) {
                subject.layer.removeAllAnimations()
                subject.subviews.forEach(stripAnimations)
            }
            stripAnimations(view)
            // Recursive, because the logos sit inside a container view - stripping only
            // the first level left their layers still playing the keyframes, which is
            // why the first fix showed no end state at all: the animation simply carried
            // on over the values set below, and the hold faded out mid-sequence
            // (play-test round 10, "still isn't right")
            splashScreenLogo2.alpha = 0
            splashScreenLogo3.alpha = 0
            splashScreenLogo4.alpha = 0
            splashScreenLogo5.alpha = 0
            splashScreenLogo6.alpha = 1
            creatorLabel.alpha = 1
            creatorLabel.transform = .identity
            // A skip jumps to the animation's *end state* and holds it for a second
            // (play-test round 9) - the finished logo and the credit, not the tail of
            // the animation playing itself out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self, self.resumeInProgress == false else { return }
                self.removeAnimate(duration: 0.25)
            }
        }
    }
    // Tap to dismiss splash screen. With a resume prompt waiting this fast-forwards *to*
    // the prompt, never past it - the prompt only answers its own Resume and Cancel
    // buttons, so an accidental tap cannot spend a saved run
    
    /// The music credit, under the author's line exactly as the About screen has it: same
    /// font, same colour, five points below.
    ///
    /// A second label rather than a second line in the first one. Putting both in
    /// `creatorLabel` made it two lines tall, and the label is centred - so growing it
    /// downwards pushed James's name *up* off its mark (play-test round 14). This leaves
    /// that label exactly the size and place it has always been.
    ///
    /// It is added as a child of `creatorLabel` so it inherits the alpha and the transform
    /// the splash animation applies - the credit fades in with the name, for free, without
    /// the keyframes needing to know it exists. Constrained below the parent's own bottom,
    /// which draws fine because a label does not clip its children.
    private func setUpCreatorCredit() {
        let music = UILabel()
        music.text = "Music by Brendan Lawton"
        music.font = creatorLabel.font
        music.textColor = creatorLabel.textColor
        music.textAlignment = .center
        music.translatesAutoresizingMaskIntoConstraints = false
        creatorLabel.addSubview(music)
        NSLayoutConstraint.activate([
            music.topAnchor.constraint(equalTo: creatorLabel.bottomAnchor, constant: 5),
            music.centerXAnchor.constraint(equalTo: creatorLabel.centerXAnchor),
        ])
    }

    var defaults: UserDefaults = .standard
    var hapticsSetting: Bool = true
    var savedGame: SavedGame?
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    // User settings
    
    var gameToResume: Bool?
    
    var resumeInProgress: Bool = false
    
    override func viewDidLoad() {
        splashScreenIsShowing = true
        // Set here rather than by whoever presents it, so it cannot be forgotten at a call site

        super.viewDidLoad()
                
        splashScreenLogo1.image = UIImage(named: "SplashScreenLogo1")!
        splashScreenLogo2.image = UIImage(named: "SplashScreenLogo2")!
        splashScreenLogo3.image = UIImage(named: "SplashScreenLogo3")!
        splashScreenLogo4.image = UIImage(named: "SplashScreenLogo4")!
        splashScreenLogo5.image = UIImage(named: "SplashScreenLogo5")!
        splashScreenLogo6.image = UIImage(named: "SplashScreenLogo6")!

        splashScreenLogo1.alpha = 1.0
        splashScreenLogo2.alpha = 0.0
        splashScreenLogo3.alpha = 0.0
        splashScreenLogo4.alpha = 0.0
        splashScreenLogo5.alpha = 0.0
        splashScreenLogo6.alpha = 0.0
        creatorLabel.alpha = 0.0
        creatorLabel.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        setUpCreatorCredit()
        // Pre animation setup
        

        scoreLabel.numberOfLines = 0
        // The storyboard has it at one line; the resume detail needs three

        if gameToResume == true {
            userSettings()
        }
        // userSettings loads savedGame, so it has to run before the save is bound below

        if gameToResume == true, SavedGame.canResume(from: defaults) == false {
            gameToResume = false
            defaults.set(false, forKey: SavedGame.resumeFlagKey)
        }
        // **A flag with no save behind it used to hang the app on this screen, for ever**
        // (round 181, found by force-quitting mid-run and relaunching). `resumeGameToLoad`
        // is a separate key from the save itself, so the two can come apart - a quit taken
        // between the flag being written and the save being written leaves the flag true
        // and nothing to resume. The guard below then correctly refuses to build a prompt
        // it has no data for... and `removeAnimate` is only ever called on the
        // `gameToResume == false` path, so the splash sat there with the title showing and
        // no way past it. The crash this format was meant to end had become a hang.
        //
        // The question itself lives on `SavedGame`, where both halves are in reach; what
        // belongs here is the *answer to it* being applied before the animation's completion
        // asks `gameToResume` and decides whether to leave. The stale key is cleared as well
        // as the local answer, so the state cannot outlive one launch

        if gameToResume == true, let savedGame {
            // Both conditions matter. resumeGameToLoad is a separate flag from the save
            // itself, so a save that fails to decode leaves the flag true and nothing to
            // resume. Showing the prompt then unwrapping would trap at launch - the crash
            // loop this format was meant to end
            layOutResumeCard()
            let lines = ResumeCard.lines(for: savedGame,
                                         fallbackMode: GameMode.current(in: defaults))
            resumingLabel.text = lines.heading
            modeLabel.text = lines.mode
            detailLabel.text = lines.detail
            detailLabel.isHidden = lines.detail.isEmpty
            resumeStack?.setCustomSpacing(
                lines.detail.isEmpty ? SplashViewController.groupGap : 0, after: modeLabel)
            // **The air above the score has to move with the line that carries it.** A stack
            // skips the custom spacing after a hidden arranged view, so hiding the detail line
            // in the endless modes - where a mode's name has nothing under it to say - took the
            // ten points above the score with it and left the height jammed under "Endless
            // Mayhem". Caught by rendering the three cards and looking at them
            scoreLabel.attributedText = resumeScoreLine(title: lines.scoreTitle,
                                                        value: lines.scoreValue)
            livesLabel.text = lines.lives
            livesLabel.isHidden = lines.lives.isEmpty
            // Said before the resume, never discovered after it (§12.5) - the same rule the
            // briefing screen follows for whether an attempt posts

            resumingLabel.isHidden = false
            modeLabel.isHidden = false
            scoreLabel.isHidden = false
        } else {
            resumingLabel.isHidden = true
            cancelResumeButton.isHidden = true
            packNameLabel.isHidden = true
            levelNumberLabel.isHidden = true
            scoreLabel.isHidden = true
        }
        // Show or hide resume label to reflect if a previous saved game is being loaded
    }
    

    /// The mode's name, and the pack and level under it.
    ///
    /// Two of the storyboard's three labels, renamed at the point of use rather than in the
    /// nib: round 310 reordered what the screen says, and `packNameLabel` now carries the mode
    /// while `levelNumberLabel` carries the pack and level it used to sit above. Renaming the
    /// outlets would mean re-wiring the scene, and an alias here is the same change with
    /// nothing to get wrong in the storyboard.
    private var modeLabel: UILabel { packNameLabel }
    private var detailLabel: UILabel { levelNumberLabel }

    /// The resume card: heading, mode, detail, score, and the round button under them, all
    /// grouped at the bottom of the screen.
    ///
    /// James, round 310: "move the Resuming... label to just above the cancel button and give
    /// it the same font, style, glow as the game mode titles from their respective menu views.
    /// Make the cancel button a big round x button in the centre at the bottom instead of
    /// saying cancel... Keep the spacing and style similar to the pause / end of game menu, but
    /// with everything grouped towards the bottom."
    ///
    /// The four labels come out of the storyboard's constraint chain and into a stack view.
    /// That chain ran heading -> pack -> level -> score -> cancel with only its *bottom*
    /// anchored, so it was already bottom-grouped, but every gap in it was a separate
    /// storyboard constant and the new order needed three of them changed. A stack owns the
    /// spacing in one place, and taking the labels out of the chain retires those constraints
    /// with them - a view removed from its superview takes the constraints that mention it.
    ///
    /// The table view that used to be the Cancel row goes entirely. It was one row in a list
    /// control drawn as a capsule, and what round 310 asked for is the app's own large round
    /// button - the same disc, at the same size, as the centre button on every menu's row.
    private func layOutResumeCard() {
        guard let container = resumingLabel.superview else { return }

        cancelResumeButton.removeFromSuperview()

        resumingLabel.font = UIViewController.menuTitleFont
        resumingLabel.textColor = GigaBallGlow.colour
        resumingLabel.adjustsFontSizeToFitWidth = true
        resumingLabel.minimumScaleFactor = 0.6
        resumingLabel.applyGigaBallGlow(radius: GigaBallGlow.wordmarkRadius, opacity: 0.8)
        // The face, colour and halo every menu screen's title wears - `menuTitleFont` is the
        // one place those 35 black points are written down (round 212 found two screens that
        // had drifted off it).
        //
        // **A wider, brighter halo than a heading's** (James, round 311: "can we also add a glow
        // to the resuming... header like some of the other headers"). It had one already, at
        // `headingRadius` and 0.6, which is what PAUSED and GAME OVER wear - and those sit on a
        // busy screen where a tight halo is enough to lift them off it. This one sits alone on
        // an empty field with nothing near it to be lifted off, so the same halo reads as
        // almost nothing. The wordmark's radius is the one the logo uses for exactly that
        // reason: a word with space around it needs the light to travel

        modeLabel.font = .systemFont(ofSize: 25, weight: .bold)
        modeLabel.textColor = UIColor(white: 0.871, alpha: 1)
        modeLabel.adjustsFontSizeToFitWidth = true
        modeLabel.minimumScaleFactor = 0.6
        detailLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        detailLabel.textColor = UIColor(white: 0.667, alpha: 1)
        for label in [resumingLabel, modeLabel, detailLabel, scoreLabel] {
            label!.textAlignment = .center
            label!.numberOfLines = 0
        }
        // The pause screen's own vocabulary, borrowed rather than invented: 25 bold at 0.871
        // white is its level line, 17 semibold at 0.667 its pack line. They swap places here
        // because round 310 asked for the mode first and its detail under it, so the larger of
        // the two is on top

        livesLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        livesLabel.textColor = UIColor(white: 0.667, alpha: 1)
        livesLabel.textAlignment = .center
        livesLabel.numberOfLines = 1
        livesLabel.translatesAutoresizingMaskIntoConstraints = false
        // The pause screen's own detail face, so the rack reads as a footnote to the score
        // rather than as a second number competing with it

        let carded = [resumingLabel, modeLabel, detailLabel, scoreLabel, livesLabel]
            .compactMap { $0 }
        for label in carded {
            var node: UIView? = label
            while let view = node {
                for constraint in view.constraints
                where constraint.firstItem === label || constraint.secondItem === label {
                    constraint.isActive = false
                }
                node = view.superview
            }
        }
        // **Up the whole chain, not just the one view** (round 329, from James's device log).
        // Round 312 cleared `container.constraints`, which is where a constraint between a
        // label and that container lives - and is not where every one of them lives. A
        // constraint is held by the nearest common ancestor of the two views it names, so a
        // label pinned inside some intermediate view of the storyboard keeps its tie somewhere
        // this never looked, and a label's own width or height sits on the label itself.
        //
        // Six conflicts were still being logged on every launch that offered a resume - the
        // stack's `UISV-alignment` and `UISV-canvas-connection` against storyboard leading and
        // centreX ties, and its `UISV-spacing` of 14 against a storyboard 10. UIKit broke one
        // of each pair to recover, silently, which is why the card still looked right; what it
        // broke was usually the stack's, so the spacing James asked for in round 311 was being
        // drawn at the storyboard's old numbers on a real device.
        // **The storyboard's chain has to go, not just be replaced** (round 312, found in James's
        // iPad log rather than by looking).
        //
        // Putting a view into a stack reparents it, and a constraint that mentions a view which
        // has left its superview dies with it - which is why this looked finished. But every one
        // of these constraints names *two* of the card's labels, or a label and the container,
        // and the labels all moved together into a stack that is itself a child of the same
        // container. Nothing was orphaned, so nothing was retired, and the scene shipped with
        // two sets of vertical spacing fighting:
        //
        //     V:[UILabel]-(10)-[UILabel]              the storyboard's
        //     'UISV-spacing' V:[UILabel]-(14)-[UILabel]   the stack's
        //
        // UIKit breaks one of them to recover, and the one it broke was the stack's - so the
        // four groups of air James asked for were being drawn at the old 10 and -5 on the
        // device, while the simulator's render tests, which build the same card, agreed with
        // each other and showed the new spacing. A conflict resolved silently in one direction
        // is not a thing a render test can see.
        //
        // Cleared by identity rather than by outlet name, so a constraint the storyboard grows
        // later is retired too.

        let stack = UIStackView(arrangedSubviews: [resumingLabel, modeLabel,
                                                   detailLabel, scoreLabel, livesLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setCustomSpacing(SplashViewController.groupGap, after: resumingLabel)
        stack.setCustomSpacing(SplashViewController.groupGap, after: detailLabel)
        stack.setCustomSpacing(SplashViewController.groupGap, after: scoreLabel)
        resumeStack = stack
        // **Four groups rather than five lines** (James, round 311: "add a gap between the
        // Resuming header and the game mode / level information, and then another gap between
        // the level information and score and then another gap to the balls remaining. Not
        // huge gaps, just big enough to provide some separation and grouping"). The mode and
        // its detail keep no gap between them, because they are one group - what a run is and
        // where in it you are
        // Nothing between the mode and its detail, which is how the pause screen sets its two,
        // and air either side of that pair: the heading is a heading and the score is the
        // number the player came back for
        container.addSubview(stack)

        let size = MainMenuCollectionViewCell.largeButtonSize
        let cancel = UIButton(type: .system)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        cancel.backgroundColor = UIColor(white: 0.92, alpha: 1)
        cancel.tintColor = UIColor(red: 0.16, green: 0, blue: 0.24, alpha: 1)
        cancel.layer.cornerRadius = size/2
        cancel.setImage(UIImage(systemName: "xmark",
                                withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 28, weight: .heavy)), for: .normal)
        cancel.addTarget(self, action: #selector(cancelResumeTapped), for: .touchUpInside)
        container.addSubview(cancel)
        applyRoundGlass(to: cancel, radius: size/2,
                        symbol: "xmark", pointSize: 28, rimmed: false)
        // The pale disc first and the glass over it, in that order, because `applyRoundGlass`
        // only draws the glass on iOS 26 and leaves an older phone whatever the caller set -
        // which is the pattern every other round button here follows (round 94's sweep).
        //
        // **Unrimmed** (James, round 311: "the close button shouldn't be coloured. It should be
        // a big version of the other close / back buttons in the app"). `rimmed: true` is the
        // lime prominent tint the app gives the *positive* action in a row - the play, the
        // confirm - and cancelling a resume is not that. Every close and back button in the app
        // is the plain purple glass, and this is that button at `largeButtonSize` because it is
        // the only one on the screen
        let sitsAtTheBottom = cancel.bottomAnchor.constraint(
            equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -26)
        sitsAtTheBottom.priority = .defaultHigh
        // Wanted, not required, so the cap below can lift the card off the bottom without the
        // two of them conflicting

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor,
                                           constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor,
                                            constant: -24),
            stack.widthAnchor.constraint(
                lessThanOrEqualToConstant: SplashViewController.resumeCardMaximumWidth),
            cancel.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 26),
            cancel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            cancel.widthAnchor.constraint(equalToConstant: size),
            cancel.heightAnchor.constraint(equalToConstant: size),
            cancel.bottomAnchor.constraint(
                lessThanOrEqualTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -26),
            sitsAtTheBottom,
            stack.topAnchor.constraint(
                lessThanOrEqualTo: splashScreenLogo1.bottomAnchor,
                constant: SplashViewController.resumeCardMaximumDrop),
        ])
        // The button is pinned to the *bottom* and the stack hangs off its top, so the whole
        // card grows upwards out of the corner it is anchored in however long the detail runs.
        // Twenty-six under the safe area puts the disc where the Cancel row's capsule sat, and
        // twenty-six above it is the pause screen's gap between its result and its button row
        //
        // **And it stops following the bottom on a tall screen** (James, round 313: the iPad
        // "layouts need work with resizing"; this screen is the one a resume opens on, and it
        // is where he was when he reported the bad resume). A phone is short enough that the
        // card sits a comfortable distance under the wordmark on its own. A 13-inch iPad is
        // 1366 points tall, and the same two anchors put the logo in the middle of the screen
        // and the card a third of a screen below it, with nothing in between - four lines and
        // a button spread over a distance that reads as two unrelated screens rather than one
        // card.
        //
        // The cap is a distance from the *logo* rather than a size for the screen, for the
        // same reason `menuMaximumAspectRatio` caps a shape rather than a size: what is wrong
        // on the iPad is the relationship between the two things, not how big either is. On
        // every phone the natural gap is already inside the cap, so the required constraint
        // never binds and the wanted one holds - the card is exactly where it was, to the point
    }

    /// How far below the wordmark the resuming card may sit before it stops following the
    /// bottom of the screen.
    ///
    /// Measured rather than chosen: a 393x852 phone lays the card out about 250 points under
    /// the logo, and the tallest phone the app supports is not far past that, so this sits
    /// clear of every one of them and binds only on an iPad.
    static let resumeCardMaximumDrop: CGFloat = 300

    /// And how wide its lines may run, for the same reason the menus cap theirs.
    static let resumeCardMaximumWidth: CGFloat = 420

    /// The card's stack, kept so the spacing can be adjusted once the words are known.
    private weak var resumeStack: UIStackView?

    /// The air between the card's four groups.
    ///
    /// One number, used three times, because the point of it is *rhythm* - three different gaps
    /// would read as three unrelated decisions rather than as a card in four parts. Fourteen is
    /// "just big enough to provide some separation" rather than the 8 and 10 it replaced, which
    /// were small enough that the five lines read as one block (James, round 311: "it still
    /// seems quite overwhelming").
    static let groupGap: CGFloat = 14

    /// What the rack has left, under the score (round 311).
    ///
    /// Built in code rather than added to the storyboard scene: the card is a stack now, so a
    /// fifth row costs one `arrangedSubviews` entry, where a fifth outlet would mean editing
    /// the scene's XML by hand and wiring a connection that only this screen uses.
    private let livesLabel = UILabel()

    @objc private func cancelResumeTapped() {
        if hapticsSetting { interfaceHaptic.impactOccurred() }
        NotificationCenter.default.post(name: .cancelGameResume, object: nil)
        gameToResume = false
        removeAnimate(duration: 0.25)
        // Exactly what the Cancel row did, minus the table view's highlight dance. The
        // notification goes first: `removeAnimate` tears the screen down, and posting after it
        // has run once left the run resumed behind a screen that was already gone
    }

    /// The score and its title on **one line**, in the pause screen's own two faces.
    ///
    /// James, round 310: "underneath that, show the current score / height with the score
    /// label and score on a single line. Remove the still scoring your attempt line."
    ///
    /// It was three lines - title, number, then a footnote carrying either the life count or
    /// whether the run was still the day's scoring attempt - and stacked under a heading and
    /// two detail lines it made the block taller than the screen had room for. The two faces
    /// are the pause screen's `scoreLabelTitle` and `scoreLabel`, 20 semibold grey and 35 black
    /// white, so the line reads as the same row that screen shows.
    /// The face the in-game score is drawn in.
    ///
    /// James, round 311: "can the score use the same font as the in game score?" That is Fugaz
    /// One - the one custom face the app registers, and the one the HUD's score, height and
    /// multiplier are all set in. The number on this screen is the same number the HUD was
    /// showing a moment before the app was quit, so it should look like it.
    ///
    /// Falls back to the black system face if the font ever fails to load, because a resume
    /// screen with no score on it would be worse than one in the wrong face.
    static var scoreFace: UIFont { UIViewController.gameScoreFont(ofSize: 30) }
    // Thirty rather than thirty-five (James, round 311: "perhaps the score could get a little
    // bit smaller"). Fugaz One sets larger on the body than the system face does at the same
    // point size - it is a display face with a tall x-height - so the 35 that was right for
    // `systemFont(.black)` reads as a size up in this one

    /// The face the word beside it wears - the pause screen's score title.
    static let scoreTitleFace = UIFont.systemFont(ofSize: 20, weight: .semibold)

    private func resumeScoreLine(title: String, value: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let number = SplashViewController.scoreFace
        let word = SplashViewController.scoreTitleFace
        let lift = (number.capHeight - word.capHeight)/2
        // **Centred on the number, not sat on its baseline** (James, round 311: "can we also
        // align the score label so it's vertically centred with the score"). Two faces on one
        // line share a baseline unless told otherwise, which puts the small word level with the
        // big number's *feet*. Raising it by half the difference in cap heights puts the middle
        // of the word level with the middle of the digits - measured off the fonts rather than
        // nudged by eye, so it stays right if either size changes

        let line = NSMutableAttributedString(
            string: title + "  ",
            attributes: [.font: word,
                         .foregroundColor: UIColor(white: 0.667, alpha: 1),
                         .baselineOffset: lift,
                         .paragraphStyle: paragraph])
        line.append(NSAttributedString(
            string: value,
            attributes: [.font: number,
                         .foregroundColor: UIColor.white,
                         .paragraphStyle: paragraph]))
        return line
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fadeObjectsIn()
    }

    func fadeObjectsIn() {
        
        let totalDuration = 6.0
        
        UIView.animateKeyframes(withDuration: totalDuration, delay: 0, options: [.calculationModeLinear], animations: {
            // Add animations

            UIView.addKeyframe(withRelativeStartTime: 0.0/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo2.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1.0/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo3.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo4.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 2.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo5.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 3.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo6.alpha = 1.0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 3.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo2.alpha = 0.0
            })
            UIView.addKeyframe(withRelativeStartTime: 3.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo3.alpha = 0.0
            })
            UIView.addKeyframe(withRelativeStartTime: 3.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo4.alpha = 0.0
            })
            UIView.addKeyframe(withRelativeStartTime: 4.0/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.splashScreenLogo5.alpha = 0.0
            })
            
            UIView.addKeyframe(withRelativeStartTime: 4.5/totalDuration, relativeDuration: 0.5/totalDuration, animations: {
                self.creatorLabel.alpha = 1.0
                self.creatorLabel.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
        }, completion:{ _ in
            if self.resumeInProgress == false && self.skipInProgress == false {
                self.removeAnimate(duration: 0.25)
            }
            // A skip removes the animations, which fires this completion early - the
            // skip owns the dismissal then, after its one-second hold
        })
    }

    func removeAnimate(duration: Double) {
        
        resumeInProgress = true
        
        if self.gameToResume == false {
            UIView.animate(withDuration: duration, animations: {
                self.view.alpha = 0.0})
            { (finished: Bool) in
                if (finished) {
                    self.view.removeFromSuperview()
                    splashScreenIsShowing = false
            NotificationCenter.default.post(name: .splashScreenEndedNotification, object: nil)
                }
            }
        } else {
            splashScreenIsShowing = false
            NotificationCenter.default.post(name: .splashScreenEndedNotification, object: nil)
            
            UIView.animate(withDuration: duration, animations: {
                self.view.alpha = 100.0})
            { (finished: Bool) in
                if (finished) {
                    self.view.removeFromSuperview()
                }
            }
            // Delay removal of splash screen when resuming game
        }
    }
    
    func userSettings() {
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        savedGame = SavedGame.load(from: defaults)
        // Load user settings
    }
}
