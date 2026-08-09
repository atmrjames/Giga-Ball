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
    
    
    @IBOutlet var totalScoreNoSpeedBonus: NSLayoutConstraint!
    @IBOutlet var totalScoreSpeedBonus: NSLayoutConstraint!
    
    @IBOutlet var completeLabelConstraint: NSLayoutConstraint!
    @IBOutlet var packAndLevelConstriant: NSLayoutConstraint!
        
    @IBAction func tapGestureAction(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if finishScoreTallyIfRunning() { return }
        removeAnimate()
    }
    @IBAction func tapBackgroundGestureAction(_ sender: Any) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        if finishScoreTallyIfRunning() { return }
        removeAnimate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        SKPaymentQueue.default().add(self)
        
        loadData()
        userSettings()
        setBlur()
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
        }
        
        packAndLevelConstriant.isActive = false
        completeLabelConstraint.isActive = true
        
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
    private let tallyLevelDuration: CFTimeInterval = 0.28
    private let tallyBonusDuration: CFTimeInterval = 0.22
    private let tallyTotalDuration: CFTimeInterval = 0.36
    private var tallyBonusStart: CFTimeInterval { tallyLevelDuration }
    private var tallyTotalStart: CFTimeInterval { tallyBonusStart + tallyBonusDuration }
    private var tallyDuration: CFTimeInterval { tallyTotalStart + tallyTotalDuration }
    private let tallyHapticTicks = 10

    private var isTallying: Bool { tallyLink != nil }

    private func startScoreTally() {
        guard levelScore > 0 || levelScoreBonus > 0 || totalScore > 0 else { return }

        // totalScore already has this level's score and bonus in it by the time the
        // summary is shown, so the pre-level figure is what is left after taking them
        // back off. Clamped because a pack's end-of-pack lives bonus also lands in the
        // total, and that is not being counted out here.
        tallyTotalFrom = max(0, totalScore - levelScore - levelScoreBonus)

        levelScoreLabel.text = "0"
        speedBonusLabel.text = "+0"
        totalScoreLabel.text = String(tallyTotalFrom)
        tapLabel.isHidden = true

        tallyStartedAt = CACurrentMediaTime()
        tallyLastTick = -1
        let link = CADisplayLink(target: self, selector: #selector(stepScoreTally))
        link.add(to: .main, forMode: .common)
        tallyLink = link
    }

    @objc private func stepScoreTally() {
        let elapsed = CACurrentMediaTime() - tallyStartedAt
        guard elapsed < tallyDuration else {
            finishScoreTally()
            return
        }

        // Ease out, so each number decelerates into its value rather than stopping dead.
        // Whatever a phase has not reached yet reads zero, and whatever it has finished
        // stays at its full value - the sequence is the point, so nothing runs backwards.
        if elapsed < tallyBonusStart {
            let eased = easeOut(elapsed / tallyLevelDuration)
            levelScoreLabel.text = String(scaled(levelScore, by: eased))
            speedBonusLabel.text = "+0"
            totalScoreLabel.text = String(tallyTotalFrom)
        } else if elapsed < tallyTotalStart {
            let eased = easeOut((elapsed - tallyBonusStart) / tallyBonusDuration)
            levelScoreLabel.text = String(levelScore)
            speedBonusLabel.text = "+\(scaled(levelScoreBonus, by: eased))"
            totalScoreLabel.text = String(tallyTotalFrom)
        } else {
            let eased = easeOut((elapsed - tallyTotalStart) / tallyTotalDuration)
            levelScoreLabel.text = String(levelScore)
            speedBonusLabel.text = "+\(levelScoreBonus)"
            let gained = totalScore - tallyTotalFrom
            totalScoreLabel.text = String(tallyTotalFrom + scaled(gained, by: eased))
        }

        let tick = Int(elapsed / tallyDuration * Double(tallyHapticTicks))
        if tick != tallyLastTick {
            tallyLastTick = tick
            if hapticsSetting {
                interfaceHaptic.impactOccurred(intensity: 0.5)
            }
        }
    }

    private func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 3) }

    private func scaled(_ value: Int, by fraction: Double) -> Int {
        Int((Double(value) * fraction).rounded())
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
        speedBonusLabel.text = "+\(levelScoreBonus)"
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
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: showAnimateDuration, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
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
                        UIView.animate(withDuration: 1.50, animations: {
                            self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                            self.view.alpha = 1.0})
                        { (finished: Bool) in
                            if (finished) {
                                NotificationCenter.default.post(name: .levelIntroWillClear, object: nil)
                                // The final fade is about to run. The opening field starts
                                // on this rather than on .levelIntroDidClear, so its first
                                // bricks are already falling as the intro's last quarter
                                // second fades - the field is moving the moment the screen
                                // is readable
                                UIView.animate(withDuration: 0.25, animations: {
                                    self.view.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                                    self.view.alpha = 0.0})
                                { (finished: Bool) in
                                    if (finished) {
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
    
    
    func updateLabels() {
        totalScoreLabel.text = String(totalScore)
        levelNumberCorrected = levelNumber-LevelPackSetup().startLevelNumber[packNumber]+1
        numberOfPackLevels = LevelPackSetup().numberOfLevels[packNumber]
        speedBonusLabel.text = "+\(levelScoreBonus)"
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
            levelNameLabel.text = LevelPackSetup().levelNameArray[self.levelNumber]
        }

        if let challenge = DailyChallengeSession.shared.active {
            packNameLabel.text = "Daily Challenge — "
                + DailyChallengeSession.shared.displayName(forKey: challenge.dateKey)
                    .capitalized
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
                    lines.append(twist.titleLine(font: font, colour: colour))
                }
            }
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
        }
    }

    /// The mode's icon above its name (play-test round 11) - the same artwork the main
    /// menu's rows wear. A child of the intro's own view, so every entrance and exit the
    /// intro plays carries the icon with the name for free.
    private func showModeIcon() {
        guard modeIconView == nil else { return }
        let icon = UIImageView()
        if DailyChallengeSession.shared.active != nil {
            icon.image = PowerUpIcon.dailyChallenge
        } else {
            switch GameMode.current() {
            case .classic: icon.image = UIImage(named: "ClassicIcon.png")
            default: icon.image = UIImage(named: "EndlessIcon.png")
            }
        }
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(icon)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: packNameLabel.centerXAnchor),
            icon.bottomAnchor.constraint(equalTo: packNameLabel.topAnchor, constant: -6),
            // Close under the icon (play-test round 12: "nearer the title")
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),
        ])
        modeIconView = icon
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
}

