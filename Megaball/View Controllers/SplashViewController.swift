//
//  SplashViewController.swift
//  Megaball
//
//  Created by James Harding on 18/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
    @IBOutlet var splashScreenLogo1: UIImageView!
    @IBOutlet var splashScreenLogo2: UIImageView!
    @IBOutlet var splashScreenLogo3: UIImageView!
    @IBOutlet var splashScreenLogo4: UIImageView!
    @IBOutlet var splashScreenLogo5: UIImageView!
    @IBOutlet var splashScreenLogo6: UIImageView!
    
    @IBOutlet var progressBarEmpty: UIImageView!
    @IBOutlet var progressBarFull: UIImageView!
    
    @IBOutlet var progressWidth: NSLayoutConstraint!
    
    @IBOutlet var creatorLabel: UILabel!
    
    @IBAction func tapGesture(_ sender: Any) {
        removeAnimate(duration: 0.1)
    }
    // Remove this function in final release
    
    var progressBarWidth: CGFloat = 0
    var progressBarHeight: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        progressBarEmpty.image = UIImage(named: "ProgressBarEmpty")!
        progressBarFull.image = UIImage(named: "ProgressBarFull")!
        
        progressBarWidth = progressBarEmpty.frame.size.width
        progressBarHeight = progressBarEmpty.frame.size.height
        
        progressWidth.constant = progressBarHeight
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fadeObjectsIn()
    }
    
    func fadeObjectsIn() {
        
        let totalDuration = 6.0
        
        UIView.animateKeyframes(withDuration: totalDuration, delay: 0, options: [.calculationModeLinear], animations: {
            // Add animations
            UIView.addKeyframe(withRelativeStartTime: 0.0/totalDuration, relativeDuration: 5.0/totalDuration, animations: {
                self.progressWidth.constant = self.progressBarEmpty.frame.size.width
//                 Not animating for some reason
            })

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
            self.removeAnimate(duration: 0.25)
        })
    }

    func removeAnimate(duration: Double) {
        UIView.animate(withDuration: duration, animations: {
            self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
                
                NotificationCenter.default.post(name: .splashScreenEndedNotification, object: nil)
                
//                GameCenterHandler.helper.viewController = self
                // show game center after view removed
            }
        }
    }
    
}
