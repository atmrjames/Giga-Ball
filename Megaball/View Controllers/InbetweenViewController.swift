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
        showTheLivesLeft()
        
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
        label.text = livesRemaining == 1 ? "1 life left" : "\(livesRemaining) lives left"
        label.isHidden = levelNumber == 0
        // An endless run has one ball and no rack, and saying "0 lives left" on the one screen
        // it never reaches would be wrong twice over
        host.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: tapLabel.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: tapLabel.topAnchor, constant: -10),
        ])
        livesLine = label
    }

    private weak var livesLine: UILabel?

    /// Puts the tap line where the play button sits on every other screen.
    ///
    /// The storyboard holds it 134 points off the bottom, which was the right place when it was
    /// the only thing down there. The pause and game-over screens put their button row at 92,
    /// and a player's thumb learns one place rather than two.
    private func moveTheTapLineDown() {
        guard let host = tapLabel.superview else { return }
        for constraint in host.constraints
        where constraint.secondItem === tapLabel && constraint.firstAttribute == .bottom {
            constraint.constant = UIViewController.inGameBottomRowInset
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
            if left.contains(first), constraint.firstAttribute == .centerX {
                constraint.isActive = false
            }
            if right.contains(first),
               constraint.firstAttribute == .centerX || constraint.firstAttribute == .leading {
                constraint.isActive = false
            }
            if first === speedBonusTitle, constraint.firstAttribute == .top,
               constraint.secondItem === levelScoreLabel {
                constraint.isActive = false
                // The link that put the bonus under the score. Everything below still hangs
                // off the bonus's own label, which is now beside the score rather than under it
            }
        }

        NSLayoutConstraint.activate([
            levelScoreTitle.trailingAnchor.constraint(equalTo: host.centerXAnchor, constant: -14),
            levelScoreLabel.trailingAnchor.constraint(equalTo: host.centerXAnchor, constant: -14),
            levelScoreLabel.leadingAnchor.constraint(equalTo: levelScoreTitle.leadingAnchor),
            speedBonusTitle.leadingAnchor.constraint(equalTo: host.centerXAnchor, constant: 14),
            speedBonusTitle.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -10),
            speedBonusLabel.leadingAnchor.constraint(equalTo: speedBonusTitle.leadingAnchor),
            speedBonusLabel.trailingAnchor.constraint(equalTo: speedBonusTitle.trailingAnchor),
            speedBonusTitle.topAnchor.constraint(equalTo: levelScoreTitle.topAnchor),
        ])
    }

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
            icon.widthAnchor.constraint(equalToConstant: UIViewController.inGameModeIconSize),
            icon.heightAnchor.constraint(equalToConstant: UIViewController.inGameModeIconSize),
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
        NSLayoutConstraint.activate([
            logo.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor,
                                      constant: UIViewController.inGameLogoTopInset),
            logo.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            logo.heightAnchor.constraint(equalToConstant: UIViewController.inGameLogoHeight),
            logo.leadingAnchor.constraint(greaterThanOrEqualTo: host.leadingAnchor,
                                          constant: 60),
            logo.trailingAnchor.constraint(lessThanOrEqualTo: host.trailingAnchor,
                                           constant: -60),
        ])
        introLogoView = logo
    }

    /// The storyboard constant each of those two ties started at, so a screen that is laid
    /// out many times cannot walk its labels down the screen one pass at a time.
    private var introBlockBaseConstant: [ObjectIdentifier: CGFloat] = [:]

    /// Moves the intro's text block down until the mode icon clears the wordmark.
    ///
    /// **James, round 332's layout notes: "move all labels down to prevent clipping with
    /// giga-ball logo", and "add more space between giga-ball logo and game mode logo".**
    ///
    /// Nothing in this screen's layout can express that as a constraint: the wordmark is a
    /// subview of the intro's *host*, added in `showIntroLogo`, so the two are in different
    /// subtrees and the icon is pinned upwards from the first line of text rather than
    /// downwards from anything. So it is measured instead. The tie that positions the block
    /// reads `container.centerY == label.bottom + constant`, which means the constant counts
    /// *upwards* - the block moves down when it shrinks, which is why round 332's first
    /// attempt at this drove the icon to -397 rather than on to the screen.
    private func keepTheModeIconClearOfTheWordmark() {
        guard let icon = modeIconView, let logo = introLogoView,
              let host = logo.superview, icon.window != nil || icon.superview != nil else { return }

        let mark = logo.convert(logo.bounds, to: host).maxY + UIViewController.inGameLogoToIconGap
        let badge = icon.convert(icon.bounds, to: host).minY
        let shortfall = mark - badge
        guard shortfall > 0.5 else { return }

        for constraint in [completeLabelConstraint, packAndLevelConstriant].compactMap({ $0 })
        where constraint.isActive {
            let key = ObjectIdentifier(constraint)
            let base = introBlockBaseConstant[key] ?? constraint.constant
            introBlockBaseConstant[key] = base
            // Never further than the block's own height from where the storyboard put it: a
            // clamp is cheaper than trusting that every future screen shape converges.
            constraint.constant = max(base - 160, constraint.constant - shortfall)
        }
        host.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        giveTheTwistsTheRoomTheyNeed()
        if let modeIconView {
            pinModeIcon(modeIconView, above: packNameLabel, or: levelNumberLabel,
                        keeping: &modeIconBottom)
        }
        showIntroLogo()
        keepTheModeIconClearOfTheWordmark()
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
    private var modeIconBottom: NSLayoutConstraint?

    private func giveTheTwistsTheRoomTheyNeed() {
        guard let label = levelNameLabel, label.attributedText != nil,
              label.bounds.width > 0 else { return }

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

