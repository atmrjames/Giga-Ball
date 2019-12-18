//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, MenuViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    @IBAction func playButtonPressed(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToGame(selectedLevel: 1)
    }
    
    @IBAction func levelSelectionButton(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToGame(selectedLevel: sender.tag)
    }
    
    func moveToGame(selectedLevel: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self
        gameView.selectedLevel = selectedLevel
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController

}
