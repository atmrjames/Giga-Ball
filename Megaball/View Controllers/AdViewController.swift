//
//  AdViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class AdViewController: UIViewController {
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    
    @IBAction func closeButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        closeAd(nextAction: .closeAd)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showAnimate()
    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0;
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 1.0
            self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        })
    }
    
    func closeAd(nextAction: Notification.Name) {
        self.view.removeFromSuperview()
        NotificationCenter.default.post(name: .closeAd, object: nil)
        // Send notification to unpause the game
    }
    
}
