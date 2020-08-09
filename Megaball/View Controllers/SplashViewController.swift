//
//  SplashViewController.swift
//  Megaball
//
//  Created by James Harding on 18/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

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
    
    @IBAction func tapGesture(_ sender: Any) {
        if self.resumeInProgress == false {
            removeAnimate(duration: 0.1)
        }
    }
    // Remove this function in final release
    
    let defaults = UserDefaults.standard
    var hapticsSetting: Bool?
    var saveGameSaveArray: [Int]?
    let interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
    // User settings
    
    var gameToResume: Bool?
    
    var resumeInProgress: Bool = false
    
    override func viewDidLoad() {
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
        // Pre animation setup
        
        cancelResumeButton.delegate = self
        cancelResumeButton.dataSource = self
        cancelResumeButton.register(UINib(nibName: "SettingsTableViewCell", bundle: nil), forCellReuseIdentifier: "customSettingCell")
        
        if gameToResume! {
            userSettings()
            resumingLabel.isHidden = false
            cancelResumeButton.isHidden = false
            
            let currentLevelNumber = saveGameSaveArray![0]
            let currentPackNumber = saveGameSaveArray![2]
            let score = saveGameSaveArray![4]
            let height = saveGameSaveArray![6]
            let numberOfLevels = saveGameSaveArray![7]
            
            if numberOfLevels > 1 {
                packNameLabel.text = "\(LevelPackSetup().levelPackNameArray[currentPackNumber])"
                levelNumberLabel.text = "Level \(currentLevelNumber-LevelPackSetup().startLevelNumber[currentPackNumber]+1) of \(LevelPackSetup().numberOfLevels[currentPackNumber])"
            } else {
                packNameLabel.text = "Single Level Mode"
                levelNumberLabel.text = "\(LevelPackSetup().levelNameArray[currentLevelNumber])"
            }
            scoreLabel.text = "\(score)"
            
            if currentLevelNumber == 0 {
                packNameLabel.text = ""
                levelNumberLabel.text = "Endless Mode"
                scoreLabel.text = "\(height) m"
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
        cell.centreLabel.text = "Cancel Resume"
        cell.settingState.text = ""
        
        cell.cellView2.layer.cornerRadius = 25
        cell.cellView2.layer.masksToBounds = false
        cell.cellView2.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.cellView2.layer.shadowColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cell.cellView2.layer.shadowOpacity = 0.2
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
                
        UIView.animate(withDuration: 0.2) {
            let cell = self.cancelResumeButton.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.6978054643, green: 0.6936593652, blue: 0.7009937763, alpha: 1)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadData()
        // Update table view
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        
        NotificationCenter.default.post(name: .cancelGameResume, object: nil)
        gameToResume = false
        removeAnimate(duration: 0.25)
                
        UIView.animate(withDuration: 0.1) {
            let cell = self.cancelResumeButton.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .init(scaleX: 0.98, y: 0.98)
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8335226774, green: 0.9983789325, blue: 0.5007104874, alpha: 1)
        }
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if hapticsSetting! {
            interfaceHaptic.impactOccurred()
        }
        UIView.animate(withDuration: 0.1) {
            let cell = self.cancelResumeButton.cellForRow(at: indexPath) as! SettingsTableViewCell
            cell.cellView2.transform = .identity
            cell.cellView2.backgroundColor = #colorLiteral(red: 0.8705882353, green: 0.8705882353, blue: 0.8705882353, alpha: 1)
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
            if self.resumeInProgress == false {
                self.removeAnimate(duration: 0.25)
            }
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
                    NotificationCenter.default.post(name: .splashScreenEndedNotification, object: nil)
                }
            }
        } else {
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
        saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
        // Load user settings
    }
}
