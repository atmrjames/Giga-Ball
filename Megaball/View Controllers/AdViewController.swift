//
//  AdViewController.swift
//  Megaball
//
//  Created by James Harding on 26/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds

class AdViewController: UIViewController, GADInterstitialDelegate {
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    
    @IBAction func closeButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        closeAd(nextAction: .closeAd)
    }
    
    var interstitial: GADInterstitial!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Google Mobile Ads SDK version: \(GADRequest.sdkVersion())")
        
//        interstitial = createAndLoadInterstitial()
        
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        // Configure interstitial ad
        
        let request = GADRequest()
        interstitial.load(request)
        // Load interstitial ad
        
        interstitial.delegate = self

        showAnimate()
    }
    
//    func createAndLoadInterstitial() -> GADInterstitial {
//      var interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
//      interstitial.delegate = self
//      interstitial.load(GADRequest())
//      return interstitial
//    }
    
//    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
//      interstitial = createAndLoadInterstitial()
//    }
    
    func showAnimate() {
        self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        self.view.alpha = 0.0
        UIView.animate(withDuration: 1, animations: {self.view.alpha = 1.0; self.view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)})
        { (finished: Bool) in
            if (finished) {
                if self.interstitial.isReady {
                    self.interstitial.present(fromRootViewController: self)
                } else {
                  print("Interstitial ad wasn't ready")
                }
            }
        }
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        closeAd(nextAction: .closeAd)
    }
    
    func closeAd(nextAction: Notification.Name) {
        UIView.animate(withDuration: 0.25, animations: {self.view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15); self.view.alpha = 0.0})
        { (finished: Bool) in
            if (finished) {
                self.view.removeFromSuperview()
                NotificationCenter.default.post(name: .closeAd, object: nil)
                // Send notification to close the ad
            }
        }
    }
}
