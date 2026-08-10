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

class SplashViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var splashScreenLogo1: UIImageView!
    @IBOutlet var splashScreenLogo2: UIImageView!
    @IBOutlet var splashScreenLogo3: UIImageView!
    @IBOutlet var splashScreenLogo4: UIImageView!
    @IBOutlet var splashScreenLogo5: UIImageView!
    @IBOutlet var splashScreenLogo6: UIImageView!
        
    @IBOutlet var creatorLabel: UILabel!
    @IBOutlet var resumingLabel: UILabel!
    
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

    let defaults = UserDefaults.standard
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
        
        cancelResumeButton.delegate = self
        cancelResumeButton.dataSource = self
        cancelResumeButton.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        
        scoreLabel.numberOfLines = 0
        // The storyboard has it at one line; the resume detail needs three

        if gameToResume == true {
            userSettings()
        }
        // userSettings loads savedGame, so it has to run before the save is bound below

        if gameToResume == true, let savedGame {
            // Both conditions matter. resumeGameToLoad is a separate flag from the save
            // itself, so a save that fails to decode leaves the flag true and nothing to
            // resume. Showing the prompt then unwrapping would trap at launch - the crash
            // loop this format was meant to end
            resumingLabel.isHidden = false
            cancelResumeButton.isHidden = false
            
            let currentLevelNumber = savedGame.levelNumber
            let currentPackNumber = savedGame.packNumber
            let score = savedGame.totalScore
            let height = savedGame.endlessHeight
            let numberOfLevels = savedGame.numberOfLevels
            
            if numberOfLevels > 1 {
                packNameLabel.text = "\(LevelPackSetup().levelPackNameArray[currentPackNumber])"
                levelNumberLabel.text = "Level \(currentLevelNumber-LevelPackSetup().startLevelNumber[currentPackNumber]+1) of \(LevelPackSetup().numberOfLevels[currentPackNumber])"
            } else {
                packNameLabel.text = "Single Level Mode"
                levelNumberLabel.text = "\(LevelPackSetup().levelNameArray[currentLevelNumber])"
            }
            let lives = savedGame.numberOfLives
            if currentLevelNumber == 0 {
                packNameLabel.text = ""
                levelNumberLabel.text = GameMode.current() == .endlessII
                    ? GameMode.endlessII.name : GameMode.endless.name
                // The save has no mode field; the remembered mode does, and a level-0
                // save can only be the mode that was being played when it was written
                scoreLabel.attributedText = resumeDetail(title: "Height", value: "\(height)m", footnote: nil)
                // Endless has a single life and no counter anywhere else
            } else {
                scoreLabel.attributedText = resumeDetail(
                    title: "Score",
                    value: "\(score)",
                    footnote: lives == 1 ? "1 life left" : "\(lives) lives left")
            }
            
            if let key = savedGame.dailyDateKey {
                let session = DailyChallengeSession.shared
                let challenge = DailyChallengeGenerator.challenge(forKey: key)
                packNameLabel.text = "Daily Challenge, "
                    + session.displayName(forKey: key).capitalized
                levelNumberLabel.text = challenge.mode == .classic
                    ? LevelPackSetup().levelNameArray[savedGame.levelNumber]
                    : challenge.mode.name

                let closed = key != session.todayKey
                let footnote = closed
                    ? "This challenge closed while you were away.\nThe run continues - the score will not be posted."
                    : ((savedGame.dailyWasScoringAttempt ?? false)
                        ? "Still your scoring attempt."
                        : "Free play.")
                scoreLabel.attributedText = resumeDetail(
                    title: challenge.mode == .classic ? "Score" : "Height",
                    value: challenge.mode == .classic
                        ? "\(savedGame.totalScore)" : "\(savedGame.endlessHeight)m",
                    footnote: footnote)
                // Said before the resume, never discovered after it (§12.5) - the same
                // rule the briefing screen follows for whether an attempt posts
            }

            packNameLabel.isHidden = false
            levelNumberLabel.isHidden = false
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
    

    private func resumeDetail(title: String, value: String, footnote: String?) -> NSAttributedString {
        // The score, its title and the life count go in one label rather than three.
        // The storyboard runs resuming -> pack -> level -> score -> cancel as a single
        // chain, and only its bottom is anchored, so a taller score label pushes the
        // block upwards - whereas splicing extra views into the chain fought constraints
        // that the nib reinstates, and silently flattened them to nothing.
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = scoreLabel.textAlignment

        let detail: [NSAttributedString.Key: Any] = [
            .font: packNameLabel.font as Any,
            .foregroundColor: packNameLabel.textColor as Any,
            .paragraphStyle: paragraph
        ]
        let headline: [NSAttributedString.Key: Any] = [
            .font: scoreLabel.font as Any,
            .foregroundColor: scoreLabel.textColor as Any,
            .paragraphStyle: paragraph
        ]

        let text = NSMutableAttributedString(string: title + "\n", attributes: detail)
        text.append(NSAttributedString(string: value, attributes: headline))
        if let footnote {
            text.append(NSAttributedString(string: "\n" + footnote, attributes: detail))
        }
        return text
    }
    // Says the same things the pause screen does, rather than showing a bare number

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fadeObjectsIn()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    // Set number of cells in table view
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customSettingCell", for: indexPath) as! SettingsTableViewCell
        
        cancelResumeButton.rowHeight = 70.0
        cell.iconImage.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        
        cell.settingDescription.text = ""
        cell.centreLabel.text = "Cancel"
        cell.settingState.text = ""
        
        cell.cellView2.layer.cornerRadius = 25
        cell.cellView2.layer.masksToBounds = false
        cell.cellView2.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.cellView2.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cell.cellView2.layer.shadowOpacity = 0.5
        cell.cellView2.layer.shadowRadius = 4
        
        UIView.animate(withDuration: 0.2) {
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
        }
        
        return cell
    }
    // Add content to cells
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        NotificationCenter.default.post(name: .cancelGameResume, object: nil)
        gameToResume = false        
        removeAnimate(duration: 0.25)
                
        if let cell = self.cancelResumeButton.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.2) {
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting {
            interfaceHaptic.impactOccurred()
        }
        
        NotificationCenter.default.post(name: .cancelGameResume, object: nil)
        gameToResume = false
        removeAnimate(duration: 0.25)
                
        if let cell = self.cancelResumeButton.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = self.cancelResumeButton.cellForRow(at: indexPath) as? SettingsTableViewCell {
            UIView.animate(withDuration: 0.1) {
                cell.cellView2.transform = .identity
                cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
            }
        }
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
        savedGame = SavedGame.load()
        // Load user settings
    }
}
