//
//  LevelSelectorViewController.swift
//  Megaball
//
//  Created by James Harding on 12/01/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import UIKit

class LevelSelectorViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    var hapticsSetting: Bool?
    
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    @IBAction func returnToMainMenuButton(_ sender: Any) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func levelSelectionButton(_ sender: UIButton) {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        moveToGame(selectedLevel: sender.tag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
        // Setup swipe gesture to return to main menu
        
        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
    }
    
    func moveToGame(selectedLevel: Int) {
        let gameView = self.storyboard?.instantiateViewController(withIdentifier: "gameView") as! GameViewController
        gameView.menuViewControllerDelegate = self as? MenuViewControllerDelegate
        gameView.selectedLevel = selectedLevel
        self.navigationController?.pushViewController(gameView, animated: true)
    }
    // Segue to GameViewController with selected level
    
    func moveToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
        if hapticsSetting! {
            mediumHaptic.impactOccurred()
        }
        navigationController?.popToRootViewController(animated: true)
    }
    // Setup swipe gesture to return to main menu

}
