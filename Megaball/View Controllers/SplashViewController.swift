//
//  SplashViewController.swift
//  Megaball
//
//  Created by James Harding on 18/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
    
   
    @IBOutlet var shadowLogo: UIImageView!
    @IBOutlet var glowLogo: UIImageView!
    @IBOutlet var megaballLogo: UIImageView!
    @IBOutlet var creatorLabel: UILabel!
    
    @IBAction func tapGesture(_ sender: Any) {
        removeAnimate(duration: 0.1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shadowLogo.image = UIImage(named:"MegaballShadow.png")!
        glowLogo.image = UIImage(named:"MegaballGlow.png")!
        megaballLogo.image = UIImage(named:"MegaballLogo.png")!
        shadowLogo.alpha = 1.0
        glowLogo.alpha = 0.0
        megaballLogo.alpha = 0.0
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
            UIView.addKeyframe(withRelativeStartTime: 0.0/totalDuration, relativeDuration: 0.5/totalDuration, animations: {
                self.glowLogo.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1.0/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.megaballLogo.alpha = 1.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1.0/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
                self.glowLogo.alpha = 0.0
            })
            UIView.addKeyframe(withRelativeStartTime: 1.5/totalDuration, relativeDuration: 1.0/totalDuration, animations: {
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
            }
        }
    }
    
}
