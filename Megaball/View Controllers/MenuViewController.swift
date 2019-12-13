//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    @IBAction func playButtonPressed(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToGame()
    }
    
    @IBAction func hapticTestingButton(_ sender: UIButton) {
        
        var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
        
        switch sender.tag {
        case 1:
            hapticStyle = .light
            // use for ball hitting bricks and paddle
        case 2:
            hapticStyle = .medium
            // use for UI interactions
        case 3:
            hapticStyle = .heavy
        case 4:
            hapticStyle = .soft
            // use for lost ball
        case 5:
            hapticStyle = .rigid
            // use for power-ups collected
        default:
            hapticStyle = .light
        }
        
        let hapticFeedback = UIImpactFeedbackGenerator(style: hapticStyle)
        hapticFeedback.impactOccurred()
        
    }
    
    func moveToGame() {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController

}
