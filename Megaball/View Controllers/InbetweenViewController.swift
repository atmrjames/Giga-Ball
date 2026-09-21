//
//  InbetweenViewController.swift
//  Megaball
//
//  Created by James Harding on 11/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class InbetweenViewController: UIViewController, UITableViewDelegate {

    var levelNumber: Int = 0
    var packNumber: Int = 0
    var totalScore: Int = 0
    var levelScore: Int = 0
    var levelScoreBonus: Int = 0
    var levelScoreMinusTimerBonus: Int = 0
    var firstLevel: Bool = false
    var numberOfLevels: Int = 0
    var sender: String?
    // Properties to store passed over data
    
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    var levelNumberCorrected = 0
    var numberOfPackLevels = 0
    
    var showAnimateDuration = 0.25
    
    let defaults = UserDefaults.standard
    var soundsSetting: Bool = true
    var musicSetting: Bool = true
    var hapticsSetting: Bool = true
    var parallaxSetting: Bool = true
    var paddleSensitivitySetting: Int = 2
    // User settings
    
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var group: UIMotionEffectGroup?
    var blurView: UIVisualEffectView?
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var contentView: UIView!
    
    @IBOutlet var packNameLabel: UILabel!
    private var modeIconView: UIImageView?
    private var introLogoView: UIImageView?
    private var runKindLabel: UILabel?
    @IBOutlet var levelNumberLabel: UILabel!
    @IBOutlet var levelNameLabel: UILabel!
    @IBOutlet var completeLabel: UILabel!
    
    @IBOutlet var levelScoreTitle: UILabel!
    @IBOutlet var levelScoreLabel: UILabel!
    @IBOutlet var speedBonusTitle: UILabel!
    @IBOutlet var speedBonusLabel: UILabel!
    @IBOutlet var totalScoreTitle: UILabel!
    @IBOutlet var totalScoreLabel: UILabel!
    
    @IBOutlet var tapLabel: UILabel!

    /// How many balls are left, handed over with the rest of the run's numbers.
    var livesRemaining: Int = 0
    
    
    @IBOutlet var totalScoreNoSpeedBonus: NSLayoutConstraint!
    @IBOutlet var totalScoreSpeedBonus: NSLayoutConstraint!
    
    @IBOutlet var completeLabelConstraint: NSLayoutConstraint!
    @IBOutlet var packAndLevelConstriant: NSLayoutConstraint!
        
    @IBAction func tapGestureAction(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if finishScoreTallyIfRunning() { return }
        if skipIntroHoldIfRunning() { return }
        removeAnimate()
    }
    @IBAction func tapBackgroundGestureAction(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if finishScoreTallyIfRunning() { return }
        if skipIntroHoldIfRunning() { return }
        removeAnimate()
    }

    /// True while the next level's name is being held on screen before it fades.
    private var introHoldRunning = false

    /// Skips the hold and clears the intro now.
    ///
    /// The level summary already answers a tap twice - once to finish the score tally, once
    /// to dismiss - and then holds the *next* level's name for a second and a half with
    /// nothing to press (play-test round 11 asked for the intro to be skippable too). A tap
    /// during that hold now runs the dismissal it was going to run anyway.
    ///
    /// The notifications still go out in the same order, because the scene's opening field
    /// waits on `levelIntroWillClear` and its lives roll in on `levelIntroDidClear` - a skip
    /// that dropped either would leave a run with no bricks or no reserve balls.
    @discardableResult
    private func skipIntroHoldIfRunning() -> Bool {
        guard introHoldRunning else { return false }
        introHoldRunning = false
        view.layer.removeAllAnimations()
        // The hold's own completion is called with `finished: false` by this, and it is
        // guarded on `finished` - so it will not also run what is about to run here

        NotificationCenter.default.post(name: .levelIntroWillClear, object: nil)
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            self.view.alpha = 0.0
            self.fadeIntroLogo(to: 0)
        }) { finished in
            guard finished else { return }
            self.removeIntroLogo()
            self.view.removeFromSuperview()
            NotificationCenter.default.post(name: .levelIntroDidClear, object: nil)
        }
        return true
    }
    
    /// The total is the answer; the two above it are the working.
    ///
    /// James, round 307: "at the end of a classic mode level, with the level score, time bonus
    /// and total score, make the total score labels bigger than the other 2 to show a
    /// hierarchy." All three were the same size, so the row read as a list of three equal
    /// numbers when it is really two figures and their sum.
    ///
    /// Scaled from whatever the storyboard set rather than given a number of its own: the three
    /// labels are laid out together, and a hard-coded size here would be a second opinion about
    /// the first two the moment either was touched.
    ///
    /// **A third larger rather than a third again** (round 320). James, on the daily's own
    /// complete screen: "make the total score title and label larger than the level score and
    /// time bonus." The mechanism was already here and already running on that screen - it is
    /// the same view - so what he is reporting is that 1.35 does not read as a hierarchy at the
    /// sizes these labels actually are. A title at 13 points goes to 18 at 1.35 and to 20 at
    /// 1.5, and the second is the one that looks deliberate rather than like a rounding.
    private func raiseTheTotal() {
        totalScoreTitle.text = "Total Score"
        for label in [totalScoreTitle, totalScoreLabel] {
            guard let label, let font = label.font else { continue }
            label.font = font.withSize((font.pointSize*GameScene.betweenLevelsTotalScale).rounded())
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        SKPaymentQueue.default().add(self)
        
        loadData()
        userSettings()
        setBlur()
        raiseTheTotal()
        if parallaxSetting {
            addParallaxToView()
        }
        updateLabels()
        
        if levelScoreBonus <= 0 {
            speedBonusTitle.isHidden = true
            speedBonusLabel.isHidden = true
            totalScoreSpeedBonus.isActive = false
            totalScoreNoSpeedBonus.isActive = true
        } else {
            speedBonusTitle.isHidden = false
            speedBonusLabel.isHidden = false
            totalScoreNoSpeedBonus.isActive = false
            totalScoreSpeedBonus.isActive = true
            putTheScoreAndBonusOnOneLine()
        }
        
        packAndLevelConstriant.isActive = false
        completeLabelConstraint.isActive = true
        layOutTheThreeBands()
        showTheLivesLeft()
        keepTheScoresOffTheTapLine()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
                
        
        
        showAnimate()
        
        if (levelNumber == LevelPackSetup().startLevelNumber[packNumber] && firstLevel) || (levelNumber == 0 && firstLevel) || firstLevel {
            showAnimateDuration = 0
            levelNumber = levelNumber-1
            levelNumberCorrected = levelNumberCorrected-1

            removeAnimate()
        } else {
            startScoreTally()
        }
    }

    // MARK: - Score tally

    private var tallyLink: CADisplayLink?
    private var tallyStartedAt: CFTimeInterval = 0
    private var tallyLastTick = -1
    private var tallyTotalFrom = 0

    /// Three counts, one after another: the level score, then the speed bonus, then the
    /// total taking both on top of what it was when the level started.
    ///
    /// Each number stays where it lands. They used to drain back to zero once the total had
    /// taken them, which read as though the level had been worth nothing - you finished a
    /// level and the number showing beside it was 0.
    ///
    /// Short on purpose: this sits between finishing a level and playing the next one, so
    /// it should read as a flourish rather than something to sit through. A tap finishes
    /// it early.
    /// The timings and the arithmetic live in `ScoreTally` since round 210, because the
    /// daily's Complete screen counts the same three numbers and two copies of a curve are two
    /// curves the first time either is touched. The labels stay here: the two screens sit in
    /// quite different layouts.

    private var isTallying: Bool { tallyLink != nil }

    private func startScoreTally() {
        guard levelScore > 0 || levelScoreBonus > 0 || totalScore > 0 else { return }

        // totalScore already has this level's score and bonus in it by the time the
        // summary is shown, so the pre-level figure is what is left after taking them
        // back off. Clamped because a pack's end-of-pack lives bonus also lands in the
        // total, and that is not being counted out here.
        tallyTotalFrom = max(0, totalScore - levelScore - levelScoreBonus)

        levelScoreLabel.text = "0"
        speedBonusLabel.text = "0"
        totalScoreLabel.text = String(tallyTotalFrom)
        tapLabel.isHidden = true

        tallyStartedAt = CACurrentMediaTime()
        tallyLastTick = -1
        let link = CADisplayLink(target: self, selector: #selector(stepScoreTally))
        link.add(to: .main, forMode: .common)
        tallyLink = link
    }

    private var tallyValues: ScoreTally.Values {
        ScoreTally.Values(level: levelScore, bonus: levelScoreBonus,
                          from: tallyTotalFrom, to: totalScore)
    }

    @objc private func stepScoreTally() {
        let elapsed = CACurrentMediaTime() - tallyStartedAt
        guard elapsed < ScoreTally.duration else {
            finishScoreTally()
            return
        }

        let reading = ScoreTally.reading(at: elapsed, of: tallyValues)
        levelScoreLabel.text = String(reading.level)
        speedBonusLabel.text = String(reading.bonus)
        totalScoreLabel.text = String(reading.total)

        let tick = ScoreTally.tick(at: elapsed)
        if tick != tallyLastTick {
            tallyLastTick = tick
            if hapticsSetting {
                interfaceHaptic.impactOccurred(intensity: 0.5)
            }
        }
    }

    /// Snaps the numbers to their final values. Returns whether there was anything to
    /// finish, so a tap that lands mid-tally is spent on skipping rather than dismissing.
    @discardableResult
    private func finishScoreTallyIfRunning() -> Bool {
        guard isTallying else { return false }
        finishScoreTally()
        return true
    }

    private func finishScoreTally() {
        tallyLink?.invalidate()
        tallyLink = nil
        levelScoreLabel.text = String(levelScore)
        speedBonusLabel.text = String(levelScoreBonus)
        totalScoreLabel.text = String(totalScore)
        tapLabel.isHidden = false
    }

    func userSettings() {
        soundsSetting = defaults.bool(forKey: "soundsSetting")
        musicSetting = defaults.bool(forKey: "musicSetting")
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
        // Load user settings
    }

    func showAnimate() {
        showIntroLogo()
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        self.fadeIntroLogo(to: 0)
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.fadeIntroLogo(to: 1)
            // The wordmark arrives with the screen and holds still while it does - it is
            // outside the transform now, so only its alpha is animated
        }, completion: { _ in
            NotificationCenter.default.post(name: .levelIntroDidAppear, object: nil)
            // Only now is this actually covering anything. It fades in over a quarter
            // second, and the launch cover has to stay up for all of it - lifting when
            // the level finished building was too early and the level flashed through
        })
    }
    
    func removeAnimate() {
        finishScoreTallyIfRunning()
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            self.contentView.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.contentView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                self.levelNumber = self.levelNumber+1
                self.updateLabels()
                self.totalScoreLabel.text = ""
                self.completeLabel.text = ""
                self.totalScoreTitle.text = ""
                self.tapLabel.text = ""
                self.levelScoreTitle.text = ""
                self.levelScoreLabel.text = ""
                self.speedBonusTitle.text = ""
                self.speedBonusLabel.text = ""
                self.completeLabelConstraint.isActive = false
                self.packAndLevelConstriant.isActive = true
                NotificationCenter.default.post(name: .continueToNextLevel, object: nil)
                UIView.animate(withDuration: 0.25, animations: {
                    self.contentView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                    self.contentView.alpha = 1.0})
                { (finished: Bool) in
                    if (finished) {
                        self.introHoldRunning = true
                        UIView.animate(withDuration: 1.50, animations: {
                            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                            self.view.alpha = 1.0})
                        { (finished: Bool) in
                            if (finished) {
                                self.introHoldRunning = false
                                NotificationCenter.default.post(name: .levelIntroWillClear, object: nil)
                                // The final fade is about to run. The opening field starts
                                // on this rather than on .levelIntroDidClear, so its first
                                // bricks are already falling as the intro's last quarter
                                // second fades - the field is moving the moment the screen
                                // is readable
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                                    self.view.alpha = 0.0
                                    self.fadeIntroLogo(to: 0)})
                                { (finished: Bool) in
                                    if (finished) {
                                        self.removeIntroLogo()
                                        self.view.removeFromSuperview()
                                        NotificationCenter.default.post(name: .levelIntroDidClear, object: nil)
                                        // The scene waits for this before rolling the lives
                                        // in. .continueToNextLevel fires two seconds
                                        // earlier, at the start of this dismissal, so
                                        // anything keyed to that plays behind the overlay
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /// The rack, said where the eye already is.
    ///
    /// **James, round 332's layout notes: "show the lives left at the bottom near the tap to
    /// continue - move the tap to continue down, near where the play button would be on other
    /// views."** Between levels is the one screen in the run that never said how many balls
    /// were left, and it is the screen a player is on when they are deciding whether the next
    /// level is worth starting now.
    ///
    /// Built here rather than in the storyboard for the reason the pause card's own lives line
    /// is: a label added in code has no fixed height to run out of, and this one is hidden
    /// outright in the modes that have no rack.
    private func showTheLivesLeft() {
        guard livesLine == nil, let host = tapLabel.superview else { return }
        moveTheTapLineDown()

        let label = UILabel()
        label.textAlignment = .center
        label.font = tapLabel.font
        label.textColor = tapLabel.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = BallRackView.line(for: livesRemaining)
        label.isHidden = levelNumber == 0 || firstLevel
        // An endless run has one ball and no rack, and saying "0 lives left" on the one screen
        // it never reaches would be wrong twice over.
        //
        // **And not on the level intro either** (James, round 338: "some of the intro splash
        // screens now have too much information"). The rack belongs to the card that reports a
        // finished level: it is what you have left *after* it. The intro is the same scene with
        // its numbers rubbed out, so it inherited the line - and inherited it reading nought,
        // because the run has not started and nothing has counted the balls yet
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: tapLabel.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: tapLabel.topAnchor, constant: -10),
        ])
        livesLine = label

        // **And the balls above the words** (James, round 339: "add the balls graphic above the
        // x lives left remaining label"). The pause screen has drawn its rack since round 335a
        // and this card, which is the one that has just told you a ball was lost, said it in
        // words alone.
        let rack = BallRackView()
        rack.isHidden = label.isHidden
        host.addSubview(rack)
        NSLayoutConstraint.activate([
            rack.centerXAnchor.constraint(equalTo: label.centerXAnchor),
            rack.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -6),
        ])
        livesRack = rack
    }

    private weak var livesRack: BallRackView?

    /// Fills the rack, at the size the game draws its own.
    private func refreshTheLivesRack() {
        guard let rack = livesRack, livesLine?.isHidden == false else { return }
        rack.show(livesRemaining, on: view.bounds.size,
                  ball: BallRackView.chosenBall(in: defaults))
    }

    private weak var livesLine: UILabel?

    /// Puts the tap line where the play button sits on every other screen.
    ///
    /// The storyboard holds it 134 points off the bottom, which was the right place when it was
    /// the only thing down there. The pause and game-over screens put their button row at 92,
    /// and a player's thumb learns one place rather than two.
    private func moveTheTapLineDown() {
        guard let host = tapLabel.superview else { return }
        let scale = UIViewController.inGameHeaderScale(inside: view)
        for constraint in host.constraints
        where constraint.firstItem === host && constraint.secondItem === tapLabel
            && constraint.firstAttribute == .bottom {
            // **The host's bottom against the tap line's, and nothing else.** Without naming
            // the first item this also matches "the rack's bottom against the tap line's top",
            // which is a constraint this screen makes a few lines further down - and round 338
            // spent a while on a rack drawn 85 points below where its own constraint said it
            // was, because this loop had quietly rewritten that constraint to the bottom
            // inset. It was harmless only while this ran once, before the rack existed.
            constraint.constant = (UIViewController.inGameBottomRowInset*scale).rounded()
            // Scaled with the header, so a short screen gives back room at both ends rather
            // than holding a tall phone's margin under a card that does not fit
        }
    }

    private var sideBySideScores = false

    /// Puts the level score and the speed bonus beside each other rather than one under the
    /// other.
    ///
    /// **James, round 332's layout notes: "put level score and speed bonus on the same line
    /// next to one another."** Two numbers stacked read as a list; side by side they read as a
    /// pair, which is what they are - and the total underneath then has something to be the
    /// total *of*. The daily's breakdown on the pause card has been arranged this way since
    /// round 160 and this is the same arrangement, so the two screens agree.
    ///
    /// The storyboard gives all four labels the container's full width and centres them, which
    /// is what has to go: each pair takes half the width instead, with fourteen points either
    /// side of the middle. Found by walking the host's constraints rather than by outlets,
    /// because a constraint between siblings belongs to the view above them and there are four
    /// of these that nothing in code has ever needed a name for.
    ///
    /// Once per screen, and only where there is a bonus to show: a level with no speed bonus
    /// hides those two labels, and a lone column against an empty half reads worse than the
    /// stack it replaced.
    private func putTheScoreAndBonusOnOneLine() {
        guard sideBySideScores == false, levelScoreBonus > 0,
              let host = levelScoreTitle.superview else { return }
        sideBySideScores = true

        let left: [UILabel] = [levelScoreTitle, levelScoreLabel]
        let right: [UILabel] = [speedBonusTitle, speedBonusLabel]

        for constraint in host.constraints {
            guard let first = constraint.firstItem as? UILabel else { continue }
            if left.contains(first),
               constraint.firstAttribute == .centerX || constraint.firstAttribute == .leading {
                constraint.isActive = false
            }
            if right.contains(first),
               constraint.firstAttribute == .centerX || constraint.firstAttribute == .leading
                || constraint.firstAttribute == .trailing {
                constraint.isActive = false
            }
            if first === speedBonusTitle, constraint.firstAttribute == .top,
               constraint.secondItem === levelScoreLabel {
                constraint.isActive = false
                // The link that put the bonus under the score. Everything below still hangs
                // off the bonus's own label, which is now beside the score rather than under it
            }
        }

        let half = InbetweenViewController.scoreAndBonusGap/2
        for label in left + right {
            label.setContentHuggingPriority(UILayoutPriority(751), for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        // Hugging wanted, resistance required. Required hugging makes both lines of a column
        // demand their own width, and the two share edges - so "Level Score" and "0" pulled
        // against each other and the title lost, truncating to "...". Resistance required and
        // hugging merely high lets the wider of the two set the column and the other centre
        // inside it, which is the arrangement, rather than a fight.
        // **The labels hug their words** (James, round 339: "the level score and speed bonus are
        // too far apart - bring them together so there's a constant gap between the labels in
        // the centre, regardless of the screen's width"). Each of these was a full half of the
        // screen with its text centred in it, so the gap between the two readings was a
        // quarter of the screen at each side and grew with the device: close on a phone, an
        // arm's length apart on an iPad. Hugging makes each column as wide as its own widest
        // line, and the pair then sits a fixed distance either side of the middle.

        NSLayoutConstraint.activate([
            levelScoreTitle.trailingAnchor.constraint(equalTo: host.centerXAnchor,
                                                      constant: -half),
            levelScoreLabel.trailingAnchor.constraint(equalTo: host.centerXAnchor,
                                                      constant: -half),
            levelScoreLabel.leadingAnchor.constraint(equalTo: levelScoreTitle.leadingAnchor),
            levelScoreTitle.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor,
                                                     constant: 10),
            speedBonusTitle.leadingAnchor.constraint(equalTo: host.centerXAnchor, constant: half),
            speedBonusLabel.leadingAnchor.constraint(equalTo: speedBonusTitle.leadingAnchor),
            speedBonusLabel.trailingAnchor.constraint(equalTo: speedBonusTitle.trailingAnchor),
            speedBonusTitle.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor,
                                                      constant: -10),
            speedBonusTitle.topAnchor.constraint(equalTo: levelScoreTitle.topAnchor),
        ])
        // The two columns share a leading edge with their own number, so whichever of the two
        // lines is wider sets the column and the other centres inside it
    }

    /// The air between the level score and the speed bonus, which is the same on every device.
    static let scoreAndBonusGap: CGFloat = 34

    private var levelEmphasisSwapped = false

    private func swapTheLevelEmphasis() {
        guard levelEmphasisSwapped == false else { return }
        levelEmphasisSwapped = true
        let number = (levelNumberLabel.font, levelNumberLabel.textColor)
        levelNumberLabel.font = levelNameLabel.font
        levelNumberLabel.textColor = levelNameLabel.textColor
        levelNameLabel.font = number.0
        levelNameLabel.textColor = number.1
    }

    func updateLabels() {
        totalScoreLabel.text = String(totalScore)
        levelNumberCorrected = levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1
        numberOfPackLevels = LevelPackSetup().numberOfLevels[packNumber]
        speedBonusLabel.text = String(levelScoreBonus)
        levelScoreLabel.text = String(levelScore)
        if levelNumber == 0 {
            packNameLabel.text = ""
            levelNumberLabel.text = GameMode.current() == .endlessII
                ? GameMode.endlessII.name : GameMode.endless.name
            // The mode's own name, not levelNameArray[0]'s - which is how a Mayhem run's
            // intro kept saying "Endless Mode" (play-test rounds 10 and 11)
            levelNameLabel.text = ""
        }
        showModeIcon()
        if numberOfLevels == 1 && levelNumber > 0 {
            packNameLabel.text = "Single Level Mode"
            levelNumberLabel.text = LevelPackSetup().levelNameArray[self.levelNumber]
            levelNameLabel.text = ""
        }
        if numberOfLevels > 1 {
            packNameLabel.text = "\(LevelPackSetup().levelPackNameArray[packNumber])"
            levelNumberLabel.text = "Level \(self.levelNumberCorrected) of \(self.numberOfPackLevels)"
            swapTheLevelEmphasis()
            levelNameLabel.text = LevelPackSetup().levelNameArray[self.levelNumber]
        }

        if let challenge = DailyChallengeSession.shared.active {
            packNameLabel.numberOfLines = 2
            packNameLabel.text = "Daily Challenge\n"
                + DailyChallengeSession.shared.displayName(forKey: challenge.dateKey)
                    .capitalized
            // **The date goes on its own line** (James, round 332's layout notes, written
            // against five of the seven screens: "put the date on the line below Daily
            // Challenge to avoid any clipping on smaller devices"). "Daily Challenge,
            // Yesterday" is a long line for a label sized for "Classic Pack", and an iPhone SE
            // has fifty points less to put it in
            levelNumberLabel.text = challenge.mode == .classic
                ? LevelPackSetup().levelNameArray[levelNumber]
                : challenge.mode.name
            // Play-test request: the splash into the game says Daily Challenge, the
            // date, the mode, and the twists with their icons - the last look at the
            // rules before they apply

            let font = levelNameLabel.font ?? .boldSystemFont(ofSize: 17)
            let colour = levelNameLabel.textColor ?? .white
            let lines = NSMutableAttributedString()
            if challenge.twists.isEmpty {
                lines.append(DailyTwist.vanillaLine(font: font, colour: colour))
            } else {
                for (index, twist) in challenge.twists.enumerated() {
                    if index > 0 { lines.append(NSAttributedString(string: "\n")) }
                    lines.append(twist.titleLine(font: font, colour: colour,
                                                 dateKey: challenge.dateKey))
                }
            }
            showRunKind()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.paragraphSpacing = 2
            lines.addAttribute(.paragraphStyle, value: paragraph,
                               range: NSRange(location: 0, length: lines.length))
            levelNameLabel.numberOfLines = 0
            levelNameLabel.adjustsFontSizeToFitWidth = true
            levelNameLabel.attributedText = lines
            // One twist per line, the same as the pause summary (play-test round 3), and
            // a no-twist day says Vanilla with its own badge rather than saying nothing

            let lineCount = max(challenge.twists.count, 1)
            for constraint in levelNameLabel.constraints
            where constraint.firstAttribute == .height {
                constraint.constant = ceil(font.lineHeight)*CGFloat(lineCount)
                    + 2*CGFloat(lineCount - 1)
            }
            // The box grows a line per twist (James, round 177, with a screenshot: "on a day
            // where there's more than one twist, only one twist shows up there"). The
            // storyboard gives this label a fixed one-line height, so `numberOfLines = 0`
            // had nothing to grow into and every twist after the first was clipped away -
            // the same fixed-height trap that swallowed the run-kind line twice (rounds 14
            // and 15, `showRunKind` below). Resized rather than removed, because the PASSED
            // banner hangs off this label's bottom edge and still needs an edge to hang off.
            // The 2s are the paragraph spacing set just above
        }
    }

    /// Whether this daily run is the scoring attempt or free play, said before it starts.
    ///
    /// Its own label, because the splash's labels carry fixed height constraints from the
    /// storyboard - appending these words to the twists list simply clipped them, which is
    /// why the line was reported missing twice (play-test rounds 14 and 15). A label built
    /// here has no height to run out of.
    private func showRunKind() {
        guard runKindLabel == nil else { return }
        let scoring = DailyChallengeSession.shared.isScoringAttempt

        let label = UILabel()
        label.text = scoring ? "COMPETITION RUN" : "FREE PLAY"
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = scoring
            ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
            : UIColor(white: 1, alpha: 0.55)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        levelNameLabel.superview?.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: levelNameLabel.bottomAnchor, constant: 18),
            // **Air under the twists** (James, round 332's layout notes: "add more space
            // between twist section and free play / competition run label"). Ten points read
            // as a fourth twist line on a day with three of them
            label.centerXAnchor.constraint(equalTo: levelNameLabel.centerXAnchor),
        ])
        runKindLabel = label
    }

    /// The mode's icon above its name (play-test round 11) - the same artwork the main
    /// menu's rows wear. A child of the intro's own view, so every entrance and exit the
    /// intro plays carries the icon with the name for free.
    private func showModeIcon() {
        guard modeIconView == nil else { return }
        let icon = UIImageView()
        icon.image = GameMode.menuIcon(
            for: DailyChallengeSession.shared.active != nil ? .daily : GameMode.current())
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: packNameLabel.centerXAnchor),
            // Its size and its top are `layOutTheInGameHeader`'s, because both are measured
            // from the screen's height and have to be re-measured when that changes
            // Close under the icon (play-test round 12: "nearer the title"), at the gap the
            // pause menu uses - the two screens are seconds apart and were six and four. The
            // bottom is pinned in `viewDidLayoutSubviews` by `pinModeIcon`, which puts it above
            // the pack line where there is one and above the mode's own name where there is
            // not: an endless run leaves the pack line empty and an empty label still holds a
            // line's height, which is the gap James asked to close (round 332)
        ])
        modeIconView = icon
        showIntroLogo()
    }

    /// The Giga-Ball wordmark, where the pause screen puts it.
    ///
    /// James, round 312. The pause and game-over screens have carried it since play-test round
    /// 10 - "the only full-screen views without the game's name on them" - and the level intro
    /// is the third of that set and was missed. Same inset, same height, same halo, all three
    /// read from `MenuLayout` so the two screens cannot drift apart again.
    private func showIntroLogo() {
        let host = view.superview ?? view!
        guard introLogoView?.superview !== host else { return }
        introLogoView?.removeFromSuperview()
        // **Asked again once the intro has a parent.** `updateLabels` builds the mode icon,
        // and the wordmark beside it, from `viewDidLoad` - before the intro's view has been
        // added to anything, so there is no superview to host it in yet and it lands inside
        // the intro. `showAnimate` runs when the screen is on the way in, which is the first
        // moment the right host exists; asking there moves it out. Removing the old one takes
        // its constraints with it, since every one of them names it.
        // **Beside the intro rather than inside it** (James, round 313: "the Giga-Ball logo on
        // the level intro splash screen shouldn't animate along with the game mode title and
        // icon").
        //
        // The icon travelling with the name is deliberate and says so two functions up: "a
        // child of the intro's own view, so every entrance and exit the intro plays carries
        // the icon with the name for free". Round 312 added the wordmark the same way and
        // inherited that for free as well, without anyone deciding it should - and a wordmark
        // is chrome. It is the same fixed mark the pause and game-over screens wear at the top
        // of the screen, and those two do not swell and drift.
        //
        // Hosted one level out, where the intro's transforms cannot reach it. Its *fade* is
        // driven by hand below, so it still arrives and leaves with the screen it belongs to.

        let logo = UIImageView(image: UIImage(named: "Logo"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.applyGigaBallGlow()
        logo.alpha = view.alpha
        host.addSubview(logo)
        let logoTop = logo.topAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.topAnchor,
            constant: UIViewController.inGameLogoTopInset)
        // **The intro's own safe area, not the host's.** The mark is a child of the host so the
        // intro's entrance cannot drag it about (round 313), but it belongs to the intro's
        // layout - and on an iPad the intro insets itself into a 460-point column while the
        // host does not. Measured against the host, the wordmark stayed at the top of the
        // screen while the badge moved down into the column: 236 points apart on a 13-inch
        // iPad, on a band whose whole point is that the two are together.
        let logoHeight = logo.heightAnchor.constraint(
            equalToConstant: UIViewController.inGameLogoHeight)
        NSLayoutConstraint.activate([
            logoTop,
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoHeight,
            logo.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor,
                                          constant: UIViewController.inGameLogoSideInset),
            logo.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor,
                                           constant: -UIViewController.inGameLogoSideInset),
        ])
        header.logoTop = logoTop
        header.logoHeight = logoHeight
        // Held so the header can shrink the whole band together on a short screen
        introLogoView = logo
    }

    /// Cuts this screen into the three bands every in-game view now shares.
    ///
    /// **James, round 338**, on the family of screens the game shows between one level and the
    /// next: "many of the screens have the game mode logo and title too low - they should sit
    /// just below the Giga-Ball logo near the top of the views. It looks like there's still
    /// lots of continuity between the different views that can happen too."
    ///
    /// Everything on this screen used to be one rigid chain - pack name, level, level name,
    /// COMPLETE, the three scores, all pinned one under the next - and the chain hung off the
    /// content's vertical *centre*. That is a sound way to lay out a card and a poor way to lay
    /// out a family of cards, because where the top of it lands depends on how tall the rest of
    /// it is: a level with a speed bonus put the mode's name lower than one without, and the
    /// daily, whose twists can run to three lines, pushed it lower still.
    ///
    /// So the chain is cut in two. The header - badge, pack, level, name - hangs from the
    /// wordmark at the top, where `pinTheInGameHeader` puts it and where the pause and
    /// game-over screens put theirs. The result band - COMPLETE and the scores - keeps its
    /// centre tie, so it still sits in the middle of what is left. The tap line was already
    /// pinned to the bottom. Three bands, each anchored to the thing it belongs to.
    ///
    /// The join between them becomes a *minimum* rather than a fixed distance: the result band
    /// may sit lower than the header's bottom and may never ride up into it, which is what was
    /// happening on a 320 by 568 phone - round 338's gallery render has "Total Score" printed
    /// through the rack of lives.
    /// Takes the result band's type with the header, down on a short screen and up on a tall.
    ///
    /// The header alone is not enough: the band under it is PASSED, two score rows and a
    /// total, and at a 320 by 568 phone's full size that is two hundred points of type under a
    /// header that has only just been made to fit. Both ends are scaled by the same number, so
    /// the card reads as the same card drawn smaller - or larger, on an iPad, where a phone's
    /// type in the middle of a 1032 by 1376 screen reads as a stretched phone app.
    ///
    /// Scaled from whatever the storyboard set, and only once, for the same reason
    /// `raiseTheTotal` is: a hard-coded size here would be a second opinion about the first,
    /// and a second pass would shrink what the first pass had already shrunk.
    private func sizeTheResultBandForTheScreen() {
        // The three title lines as well as the result: they are the band the badge hangs over,
        // and the pause screen scales its own. A header grown for an iPad over lines that
        // stayed a phone's size is the render round 338 caught on the between-levels card
        let scale = UIViewController.inGameHeaderScale(inside: view)
        guard scale != resultBandScale else { return }
        resultBandScale = scale

        for label in [packNameLabel, levelNumberLabel, levelNameLabel,
                      completeLabel, levelScoreTitle, levelScoreLabel,
                      speedBonusTitle, speedBonusLabel,
                      totalScoreTitle, totalScoreLabel] {
            guard let label, let font = label.font else { continue }
            let key = ObjectIdentifier(label)
            let base = resultBandBaseSize[key] ?? font.pointSize
            resultBandBaseSize[key] = base
            label.font = font.withSize((base*scale).rounded())

            for constraint in label.constraints where constraint.firstAttribute == .height {
                let tie = ObjectIdentifier(constraint)
                let baseHeight = resultBandBaseHeight[tie] ?? constraint.constant
                resultBandBaseHeight[tie] = baseHeight
                constraint.constant = (baseHeight*scale).rounded()
            }
            // The heights come with the fonts: every one of these labels is given a fixed one
            // in the storyboard, and type inside a box that did not shrink with it is how the
            // twists came to be drawn outside their own label in round 333.
            //
            // Measured from what the storyboard set rather than from what is there now, so a
            // screen laid out many times - a rotation, an iPad window dragged narrower - lands
            // on the same size each pass rather than shrinking what it shrank last time.
        }
        view.setNeedsLayout()
    }

    /// The scale the band is currently drawn at, and what it was before any of this.
    private var resultBandScale: CGFloat = 1
    private var resultBandBaseSize: [ObjectIdentifier: CGFloat] = [:]
    private var resultBandBaseHeight: [ObjectIdentifier: CGFloat] = [:]

    /// The floor of the result band: it may never reach the furniture at the bottom.
    ///
    /// **Round 338, from the gallery.** On a 320 by 568 phone the total score was drawn
    /// straight through the rack of lives and the tap line - "Total Score" and "2 lives left"
    /// printed over one another, with the number below them running off the screen. The
    /// result band is positioned from the *top* by the air under the header and from the
    /// middle by its own centre tie, and neither of those knows the screen has a bottom.
    ///
    /// Required, and the air under the header is not: on a screen too short for both, the
    /// header's air is what gives way. A crowded header still reads; two blocks of text in
    /// the same place do not.
    private func keepTheScoresOffTheTapLine() {
        let floor = livesLine?.isHidden == false ? livesLine! : tapLabel!
        totalScoreLabel.bottomAnchor.constraint(
            lessThanOrEqualTo: floor.topAnchor,
            constant: -InbetweenViewController.resultToBottomGap).isActive = true
    }

    /// The air between the last number and whatever sits under it.
    static let resultToBottomGap: CGFloat = 14

    private var headerToResultGap: NSLayoutConstraint?

    private func layOutTheThreeBands() {
        guard let contentView else { return }

        for constraint in contentView.constraints
        where constraint.firstItem === completeLabel
            && constraint.firstAttribute == .top
            && constraint.secondItem === levelNameLabel {
            constraint.isActive = false
        }
        let gap = completeLabel.topAnchor.constraint(
            greaterThanOrEqualTo: levelNameLabel.bottomAnchor,
            constant: UIViewController.inGameHeaderToResultGap)
        gap.priority = UILayoutPriority(751)
        // Above the centre tie below, so the result band sits under the header rather than
        // through it - and below the tap line's own floor, so on a screen too short for both
        // it is the air under the header that gives way rather than the two blocks colliding
        gap.isActive = true
        headerToResultGap = gap

        // Below the two centre ties, so on a screen with room the result band centres and on
        // one without it the minimum above wins rather than the layout breaking.
        completeLabelConstraint.priority = .defaultHigh
        packAndLevelConstriant.priority = .defaultHigh
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        limitMenuContentSize()
        // **The same column every other screen uses on an iPad** (round 339). The pause and
        // game-over screens have held their content to 460 points since round 181; this card
        // and the level intro spread across all 1032 of a 13-inch iPad, so the badge sat at
        // 162 points on one screen and 320 on the next, at two different sizes. They are the
        // same header, and a header is only the same if the box it is measured in is.
        sizeTheResultBandForTheScreen()
        refreshTheLivesRack()
        moveTheTapLineDown()
        // Both measured from the screen's height, which `viewDidLoad` does not know: the view
        // still has the storyboard's 414 by 896 when it runs, so everything asked there came
        // out at a tall phone's size on every phone
        giveTheTwistsTheRoomTheyNeed()
        giveTheTitleTheLinesItNeeds()
        showIntroLogo()
        if let modeIconView {
            layOutTheInGameHeader(&header, logo: introLogoView, icon: modeIconView,
                                  above: packNameLabel, or: levelNumberLabel, in: view)
            headerToResultGap?.constant =
                (UIViewController.inGameHeaderToResultGap
                 * UIViewController.inGameHeaderScale(inside: view)).rounded()
        }
        // **The first moment the right host is known.** `viewDidLoad` calls `showAnimate`, and
        // `updateLabels` builds the mode icon and the wordmark beside it - all of that runs
        // when `GameViewController` first touches `.view`, which is the line *before* the one
        // that adds it to anything. There is no superview to host the wordmark in yet, so it
        // lands inside the intro; this is where it moves out. Idempotent, so every later
        // layout pass costs a pointer comparison.
    }

    /// Sizes the twist box to the twists that are actually in it.
    ///
    /// **James, round 332: "daily challenge has 3 twists but level intro splash screen only has
    /// room to show 2"**, and in his layout notes: "make space for more twists if there are more
    /// to be shown, just expand section and move free play / competition run label down as
    /// needed."
    ///
    /// The box did grow a line per twist, and the estimate it grew by was the *font's* line
    /// height - which is not what a twist line is. Every line leads with the twist's badge, and
    /// an image attachment is taller than the type beside it: three twists needed 72 points and
    /// were given 67, so the third was drawn outside its own label. Measured here instead of
    /// estimated, because this is the first moment the label knows how wide it is, and the
    /// width is what decides whether a long twist name takes one line or two.
    ///
    /// The run-kind label hangs off this label's bottom edge, so it follows on its own - which
    /// is the rest of what he asked for.
    /// The mode icon's bottom, kept against whichever title line is showing.
    private var header = UIViewController.InGameHeader()

    private func giveTheTwistsTheRoomTheyNeed() {
        guard let label = levelNameLabel, label.attributedText != nil,
              label.bounds.width > 0 else { return }

        lineTheTwistsUpWithEachOther()
        giveTheTwistsAirAboveThem()

        let needed = ceil(label.textRect(
            forBounds: CGRect(x: 0, y: 0, width: label.bounds.width,
                              height: .greatestFiniteMagnitude),
            limitedToNumberOfLines: 0).height)

        for constraint in label.constraints where constraint.firstAttribute == .height {
            guard abs(constraint.constant - needed) > 0.5 else { continue }
            constraint.constant = needed
            view.setNeedsLayout()
            // Changed only when it is actually wrong, or a layout pass that agrees with itself
            // would ask for another one for ever
        }
    }

    /// Grows the pack line to the number of lines it is actually set to show.
    ///
    /// **James, round 338: "some of the intro splash screens now have too much information."**
    /// The daily's pack line is two: "Daily Challenge" and the day it is, put on separate lines
    /// in round 333 so a long date could not clip on a small screen. It clipped anyway, worse -
    /// the storyboard gives this label a fixed one-line height, so the second line had nowhere
    /// to go and the *first* came out as "Daily Challenge..." with the day lost altogether. A
    /// screen that names the challenge you are about to play and then does not say which day it
    /// is has too much furniture and too little information at the same time.
    ///
    /// Measured rather than multiplied out: `textRect` knows what this label's own font does
    /// with this label's own width, which a line count times a line height does not.
    private func giveTheTitleTheLinesItNeeds() {
        guard let label = packNameLabel, label.numberOfLines != 1,
              (label.text ?? "").isEmpty == false, label.bounds.width > 0 else { return }

        let needed = ceil(label.textRect(
            forBounds: CGRect(x: 0, y: 0, width: label.bounds.width,
                              height: .greatestFiniteMagnitude),
            limitedToNumberOfLines: label.numberOfLines).height)

        for constraint in label.constraints where constraint.firstAttribute == .height {
            guard abs(constraint.constant - needed) > 0.5 else { continue }
            constraint.constant = needed
            view.setNeedsLayout()
        }
    }

    /// Air between the run's name and the rules it is played under.
    ///
    /// **James, round 339, on the daily's level intro: "make the gap between the level name and
    /// twists larger."** The storyboard chains this label straight onto the one above it with
    /// nothing between, which is right when it holds a level's name and wrong when it holds a
    /// list of rules: the two are different kinds of thing and were reading as one block.
    ///
    /// Only on a daily. Every other run has the level's name in this label, and a gap there
    /// would pull the three title lines apart.
    private func giveTheTwistsAirAboveThem() {
        guard DailyChallengeSession.shared.active != nil,
              let host = levelNameLabel.superview else { return }
        let wanted = (InbetweenViewController.twistsClearance
                      * UIViewController.inGameHeaderScale(inside: view)).rounded()
        for constraint in host.constraints
        where constraint.firstItem === levelNameLabel && constraint.firstAttribute == .top
            && constraint.secondItem === levelNumberLabel {
            guard abs(constraint.constant - wanted) > 0.5 else { continue }
            constraint.constant = wanted
            view.setNeedsLayout()
        }
    }

    /// How much of it.
    static let twistsClearance: CGFloat = 18

    /// Starts every twist on the same left edge, with the block as a whole still centred.
    ///
    /// **James, round 338: "looks like well laid out, logical, beautiful and functional."** The
    /// twists are one attributed string with a badge at the head of each line, centred - so
    /// three lines of different lengths put their badges in three different places and the
    /// column zig-zags. A list of rules should read as a list.
    ///
    /// Done with an indent rather than by left-aligning the label, because the label runs the
    /// full width of the screen: aligning it left would push the whole block against the edge.
    /// The widest line is measured, the slack either side of it is halved, and every line is
    /// indented by that - which centres the *block* and left-aligns the lines inside it.
    private func lineTheTwistsUpWithEachOther() {
        guard DailyChallengeSession.shared.active != nil else { return }
        // **Only when there are twists to line up.** `UILabel.attributedText` is never nil -
        // it returns an attributed version of whatever `text` holds - so a guard on it being
        // non-nil is no guard at all, and this ran on every screen: round 338 left the word
        // "Tunnel" indented off-centre on the between-levels card for exactly that reason.
        guard let label = levelNameLabel, let text = label.attributedText,
              label.bounds.width > 0 else { return }

        let full = NSRange(location: 0, length: text.length)
        var widest: CGFloat = 0
        text.enumerateAttribute(.paragraphStyle, in: full) { _, _, _ in }
        for line in text.string.components(separatedBy: "\n") {
            guard let range = text.string.range(of: line) else { continue }
            let piece = text.attributedSubstring(
                from: NSRange(range, in: text.string))
            widest = max(widest, ceil(piece.size().width))
        }
        guard widest > 0, widest < label.bounds.width else { return }

        let indent = ((label.bounds.width - widest)/2).rounded(.down)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.paragraphSpacing = 2
        paragraph.firstLineHeadIndent = indent
        paragraph.headIndent = indent
        // `headIndent` as well as the first line's, so a twist whose name wraps keeps its
        // second line under the first rather than under the badge

        let existing = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
            as? NSParagraphStyle
        guard existing?.firstLineHeadIndent != indent
                || existing?.alignment != .left else { return }
        // Only when it changes, for the same reason the height above is: a layout pass that
        // rewrites the label asks for another one

        let lined = NSMutableAttributedString(attributedString: text)
        lined.addAttribute(.paragraphStyle, value: paragraph, range: full)
        label.attributedText = lined
    }

    /// Fades the wordmark with the screen it belongs to, since it is no longer inside it.
    private func fadeIntroLogo(to alpha: CGFloat) {
        introLogoView?.alpha = alpha
    }

    /// And takes it away with that screen, so the next intro builds a fresh one.
    private func removeIntroLogo() {
        introLogoView?.removeFromSuperview()
        introLogoView = nil
    }
    
//    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//        for transaction in transactions {
//            if transaction.transactionState == .purchased {
//                IAPHandler().unlockPremiumContent()
//                SKPaymentQueue.default().finishTransaction(transaction)
//                
//            } else if transaction.transactionState == .failed {
//                if let error = transaction.error {
//                    let errorDescription = error.localizedDescription
//                    print("User payment failed/cancelled: \(errorDescription)")
//                }
//                SKPaymentQueue.default().finishTransaction(transaction)
//                NotificationCenter.default.post(name: .iAPIncompleteNotification, object: nil)
//                // Send notification to the app that the IAP was successful
//                
//            } else if transaction.transactionState == .restored {
//                IAPHandler().unlockPremiumContent()
//                SKPaymentQueue.default().finishTransaction(transaction)
//            } else {
//            }
//        }
//    }
    
    func setBlur() {
        backgroundView.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 0.33)
        let blurEffect = UIBlurEffect(style: .dark)
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView!.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blurView!, at: 0)

        NSLayoutConstraint.activate([
        blurView!.heightAnchor.constraint(equalTo: backgroundView.heightAnchor),
        blurView!.widthAnchor.constraint(equalTo: backgroundView.widthAnchor),
        blurView!.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
        blurView!.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        blurView!.topAnchor.constraint(equalTo: backgroundView.topAnchor),
        blurView!.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        // Keep the frame of the blurView consistent with that of the associated view.
    }
    
    func addParallaxToView() {
        guard UIView.motionEffectsAreWelcome else { return }
        var amount = 25
        if view.frame.width > 450 {
            amount = 50
            // iPad
        }
        
        let horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        horizontal.minimumRelativeValue = -amount
        horizontal.maximumRelativeValue = amount

        let vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        vertical.minimumRelativeValue = -amount
        vertical.maximumRelativeValue = amount
        
        if group != nil {
            contentView.removeMotionEffect(group!)
        }
        // Remove parallax before reapplying

        group = UIMotionEffectGroup()
        group!.motionEffects = [horizontal, vertical]
        contentView.addMotionEffect(group!)
    }
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        // Load the total stats array from the NSCoder data store
    }
    
    
    @objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        userSettings()
        loadData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes

    /// The level's *name* is the thing worth reading; its number is only the position.
    ///
    /// **James, round 332's layout notes: "make Level 1 of 10 label less prominent, and level
    /// name more prominent."** The storyboard has it the other way about - the count is bold 25
    /// and the name semibold 17 - which was right when a pack's levels were numbered and
    /// nothing else, and reads oddly now that every level has a name.
    ///
    /// The two swap their type rather than being given new numbers, so both screens still take
    /// their sizes from the storyboard and cannot drift apart. Once per screen, because it is
    /// called from a method that runs on every appearance.



}

