//
//  MenuViewController.swift
//  Megaball
//
//  Created by James Harding on 07/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController, MenuViewControllerDelegate {

    var currentHighscore: Int = 0
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    @IBAction func playButtonPressed(_ sender: UIButton) {
        mediumHaptic.impactOccurred()
        moveToGame(selectedLevel: 1)
    }
    
    @IBAction func tutorialButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
    }
    
    @IBAction func selectLevelButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        moveToLevelSelector()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func moveToGame(selectedLevel: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self
        gameView.selectedLevel = selectedLevel
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController
    
    func moveToLevelSelector() {
        let levelSelectorView = self.storyboard?.instantiateViewController(withIdentifier: "levelSelectorView") as! LevelSelectorViewController
        self.navigationController?.pushViewController(levelSelectorView, animated: true)
    }
    // Segue to LevelSelectorViewController

}
