//
//  InbewteenLevelsViewController.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class InbewteenLevelsViewController: UIViewController {
    
    var levelScore: Int = 0
    var levelTime: Double = 0.0
    var cumulativeScore: Int = 0
    var cumulativeTime: Double = 0.0
    var levelHighscore: Int = 0
    var levelBestTime: Double = 0.0
    var bestScoreToLevel: Int = 0
    var bestTimeToLevel: Double = 0.0
    var cumulativeHighscore: Int = 0
    var levelNumber: Int = 0
    var gameoverStatus: Bool = false
    // Properties to store passed over data

    @IBOutlet weak var boardCompleteTitleLabel: UILabel!
    @IBOutlet weak var previousBoardScoreLabel: UILabel!
    @IBOutlet weak var previousBoardTimeScore: UILabel!
    @IBOutlet weak var cumulativeScoreLabel: UILabel!
    @IBOutlet weak var cumulativeTimeLabel: UILabel!
    @IBOutlet weak var previousBoardHighscoreLabel: UILabel!
    @IBOutlet weak var previousBoardBestTime: UILabel!
    @IBOutlet weak var previousBestScoreToThisPointLabel: UILabel!
    @IBOutlet weak var previousBestTimeToThisPointLabel: UILabel!
    @IBOutlet weak var cumulativeHighscoreLabel: UILabel!
    @IBOutlet weak var startNextBoardButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    
    @IBAction func startNextBoardButton(_ sender: UIButton) {
        removeAnimate(nextAction: .continueToNextLevel)
        // move game scene to playing
    }
    
    @IBAction func restartButton(_ sender: UIButton) {
        restart()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAnimate()
        updateLabels()
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            })
    }
    
    func removeAnimate(nextAction: Notification.Name) {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.view.alpha = 0.0
        }) { (finished: Bool) in
            if (finished) {
                NotificationCenter.default.post(name: nextAction, object: nil)
                // Send notification to load the next level
                self.view.removeFromSuperview()
            }
        }
    }
    
    func updateLabels() {
        
        if gameoverStatus {
            boardCompleteTitleLabel.text = "GAME OVER"
            startNextBoardButton.setTitle("MAIN MENU", for: .normal)
            restartButton.isHidden = false
// Add replay button
        } else {
            boardCompleteTitleLabel.text = "LEVEL \(levelNumber) COMPLETE"
            previousBoardScoreLabel.text = String(levelScore)
            previousBoardTimeScore.text = String(format: "%.2f", levelTime)
            cumulativeScoreLabel.text = String(cumulativeScore)
            cumulativeTimeLabel.text = String(format: "%.2f", cumulativeTime)
            previousBoardHighscoreLabel.text = String(levelHighscore)
            previousBoardBestTime.text = String(format: "%.2f", levelBestTime)
            previousBestScoreToThisPointLabel.text = String(bestScoreToLevel)
            previousBestTimeToThisPointLabel.text = String(format: "%.2f", bestTimeToLevel)
            cumulativeHighscoreLabel.text = String(cumulativeHighscore)
            startNextBoardButton.setTitle("NEXT LEVEL", for: .normal)
            restartButton.isHidden = true
        }
    }
    
    func restart() {
        removeAnimate(nextAction: .restart)
        // move game scene to pregame
    }
}

