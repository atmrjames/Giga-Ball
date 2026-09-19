//
//  GameViewController.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

protocol MenuViewControllerDelegate: AnyObject {
    func moveToGame(selectedLevel: Int, numberOfLevels: Int, sender: String, levelPack: Int)
}
// Setup the protocol to return to the main menu from GameViewController

class GameViewController: UIViewController, GameViewControllerDelegate {
    
    weak var menuViewControllerDelegate:MenuViewControllerDelegate?
    // Create the delegate property for the MenuViewController
    
    
    var selectedLevel: Int?
    var numberOfLevels: Int?
    var levelSender: String?
    var levelPack: Int?
    // Properties to store the correct level to load and the number of levels within the selection passed from the menu
    
    let defaults = UserDefaults.standard
        
    private var hasPresentedScene = false

    private var launchCover: UIView?
    // The scene is drawn as soon as the view has a size, but nothing is put in it until
    // the Playing state runs - so the empty playfield, and then the level building
    // itself, were visible before the intro arrived on top. This covers that gap.
    //
    // It lifts on whichever comes first: the intro finishing its fade in, or the level
    // finishing building. The intro is the usual case and is what the cover is really
    // waiting for - it is semi-transparent by design, so it only hides anything once it
    // is fully faded in. The level-built signal is the fallback for resuming a saved
    // game, where there is no intro at all and the cover would otherwise never lift.

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard hasPresentedScene == false else { return }
        hasPresentedScene = true
        addLaunchCover()
        presentGameScene()
        // Presented here rather than in viewDidLoad so the view is in a window with its
        // safe area resolved. GameScene reads the insets during didMove to lay itself out
    }

    private var levelHasBuilt = false
    private var introHasAppeared = false

    private func addLaunchCover() {
        let cover = UIView(frame: view.bounds)
        cover.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(cover)
        launchCover = cover

        NotificationCenter.default.addObserver(
            self, selector: #selector(levelDidBuildReceived), name: .levelDidBuild, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(introDidAppearReceived), name: .levelIntroDidAppear, object: nil)

        // Resuming a saved game has no intro at all, so the level building is the only
        // signal that will ever arrive. Without this the cover would sit there forever.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.introHasAppeared = true
            self?.liftLaunchCoverIfReady()
        }
    }

    @objc func levelDidBuildReceived() {
        levelHasBuilt = true
        liftLaunchCoverIfReady()
    }

    @objc func introDidAppearReceived() {
        introHasAppeared = true
        liftLaunchCoverIfReady()
    }

    /// Fades the cover away once there is something worth seeing behind it.
    ///
    /// Both signals matter, and lifting on the first one was the flash. The level starts
    /// building a tenth of a second in, well before the intro has finished fading in - so
    /// removing the cover then showed the bricks arriving through a half-faded,
    /// semi-transparent intro. Waiting for both, then crossfading rather than cutting,
    /// is what makes it read as intentional.
    private func liftLaunchCoverIfReady() {
        guard levelHasBuilt, introHasAppeared, let cover = launchCover else { return }
        launchCover = nil
        NotificationCenter.default.removeObserver(self, name: .levelDidBuild, object: nil)
        NotificationCenter.default.removeObserver(self, name: .levelIntroDidAppear, object: nil)

        UIView.animate(withDuration: 0.4, delay: 0.15, options: [.curveEaseInOut]) {
            cover.alpha = 0
        } completion: { _ in
            cover.removeFromSuperview()
        }
        // The short delay lets the brick build animation settle before it is revealed
    }

    func presentGameScene() {
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                
                let gameScene = scene as! GameScene
                gameScene.gameViewControllerDelegate = self
                // Set the GameViewController as the delegate for the gameViewControllerDelegate in GameScene
                
                scene.scaleMode = .aspectFit
                scene.size = view.bounds.size
                // **Fit, not fill** (James, round 313: on an iPad in windowed mode, "the top
                // and bottom were cut off when the app was more square and the sides were cut
                // off when the app was more tall and thin").
                //
                // Those are the two halves of what `aspectFill` *is*: it scales the scene
                // until it covers the view and throws away whatever hangs over the edge. The
                // scene's size is taken once, here, from the window the app opened in - so on
                // a phone, where that window never changes shape, fill and fit are the same
                // picture and this went unnoticed for five years. iPadOS 26 lets a window be
                // dragged into any shape at all, and every drag away from the shape the scene
                // was built at cropped it, on the axis that had grown: squarer took the HUD
                // and the paddle, thinner took the walls.
                //
                // `aspectFit` letterboxes instead, which is the right answer for this game
                // rather than merely the safe one. The play zone holds a fixed 1.8236 ratio on
                // every device by design - it is the promise that a run plays identically
                // across a player's devices - so there is no shape of window in which more of
                // the scene could honestly be shown. What fill was doing was not using the
                // extra room, it was hiding the game.
                view.presentScene(scene)
            }
            view.backgroundColor = #colorLiteral(red: 0.1607843137, green: 0, blue: 0.2352941176, alpha: 1)
            // The letterbox `aspectFit` leaves on a window the scene's shape does not fill.
            // The app's own deep purple rather than black, and the same literal the launch
            // cover above uses, so the bands read as the app's own margin rather than as the
            // game having been cut out and pasted onto the desktop

            view.ignoresSiblingOrder = true
            view.showsFPS = false
            view.showsNodeCount = false
            view.preferredFramesPerSecond = 120
            // ProMotion screens draw the game at their own refresh rate rather than at 60
            // (1.3 scope). A device without one is unaffected - the number is a ceiling, not
            // a demand - and `Info.plist` carries the entitlement that lets iPhone honour it.
            // Everything time-based in the scene already measures its own delta; the one
            // place that assumed a sixtieth was the sticky catch's lookahead, now measured
        }
        
    }
    
    func moveToMainMenu() {
        (view as? SKView)?.scene.flatMap { $0 as? GameScene }?.endEverythingInFlight()
        // **Before the view goes** (round 329). This path removes the view from its superview
        // rather than presenting another scene, so nothing else tells the scene it is finished:
        // its laser `Timer` would keep it - and its whole node tree - alive for ever, and an
        // action still in flight could fire a completion into a run that has ended. James's log
        // caught the second of those as a crash when a daily started after a Mayhem run

        CloudKitHandler().saveToiCloud()
        NotificationCenter.default.post(name: .returnMenuNotification, object: nil,
                                        userInfo: ["packNumber": levelPack ?? 0])
        // The pack rides along so the menus can reopen the screen the run was launched
        // from - every game returns to its own mode's menu, and for Classic that means
        // the played pack's level list
        NotificationCenter.default.post(name: .returnFromGameNotification, object: nil)
        NotificationCenter.default.post(name: .returnLevelStatsNotification, object: nil)
        self.view.removeFromSuperview()
    }
    // Segue to MenuViewController
    
    func showPauseMenu(levelNumber: Int, numberOfLevels: Int, score: Int, packNumber: Int, height: Int, sender: String, gameoverBool: Bool, newItemsBool: Bool, previousHighscore: Int, livesRemaining: Int, levelScore: Int, levelTimerBonus: Int) {
        let pauseMenuVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "pauseMenuVC") as! PauseMenuViewController
        pauseMenuVC.levelNumber = levelNumber
        pauseMenuVC.numberOfLevels = numberOfLevels
        pauseMenuVC.score = score
        pauseMenuVC.packNumber = packNumber
        pauseMenuVC.height = height
        pauseMenuVC.sender = sender
        pauseMenuVC.gameoverBool = gameoverBool
        pauseMenuVC.newItemsBool = newItemsBool
        pauseMenuVC.livesRemaining = livesRemaining
        pauseMenuVC.previousHighscore = previousHighscore
        pauseMenuVC.levelScore = levelScore
        pauseMenuVC.levelTimerBonus = levelTimerBonus
        // Update pause menu view controller properties with function input values
        self.addChild(pauseMenuVC)
        fillSelf(with: pauseMenuVC.view)
        self.view.addSubview(pauseMenuVC.view)
        pauseMenuVC.didMove(toParent: self)
    }
    // Show PauseMenuViewController as popup
    
    func showInbetweenView(levelNumber: Int, score: Int, packNumber: Int, levelTimerBonus: Int, firstLevel: Bool, numberOfLevels: Int, levelScore: Int) {
        let inbetweenView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "inbetweenView") as! InbetweenViewController
        inbetweenView.levelNumber = levelNumber
        inbetweenView.packNumber = packNumber
        inbetweenView.totalScore = score
        inbetweenView.levelScore = levelScore
        inbetweenView.levelScoreBonus = levelTimerBonus
        inbetweenView.firstLevel = firstLevel
        inbetweenView.numberOfLevels = numberOfLevels
        // Update pause menu view controller properties with function input values
        self.addChild(inbetweenView)
        fillSelf(with: inbetweenView.view)
        self.view.addSubview(inbetweenView.view)
        inbetweenView.didMove(toParent: self)
    }
    
    func showConfirm(_ confirm: GigaBallConfirm) {
        confirm.show(on: self)
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return [.bottom]
    }
    // Disable home bar on 1st swipe
}
