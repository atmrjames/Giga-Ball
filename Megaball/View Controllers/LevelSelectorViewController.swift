//
//  LevelSelectorViewController.swift
//  Megaball
//
//  Created by James Harding on 12/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class LevelSelectorViewController: UIViewController, MenuViewControllerDelegate {
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    @IBAction func returnToMainMenuButton(_ sender: Any) {
        mediumHaptic.impactOccurred()
        navigationController?.popToRootViewController(animated: true)
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
    // Segue to GameViewController with selected level
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    
    
    
    
    

}
