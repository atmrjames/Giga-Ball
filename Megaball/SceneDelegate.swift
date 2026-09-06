//
//  SceneDelegate.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
        // Build the window from the main storyboard, replacing the pre-iOS 13 UIMainStoryboardFile path

        Log.session(window: window.bounds.size, screen: windowScene.screen.bounds.size)

        if let restrictions = windowScene.sizeRestrictions {
            restrictions.minimumSize = SceneDelegate.smallestWindow
            Log.ui.info("""
                window floor asked for \(SceneDelegate.smallestWindow.debugDescription,                 privacy: .public), restrictions now                 \(restrictions.minimumSize.debugDescription, privacy: .public),                 scene is \(windowScene.screen.bounds.size.debugDescription, privacy: .public)
                """)
        } else {
            Log.ui.info("window scene offers no sizeRestrictions - the floor is the system's")
        }
        // **The log is the point of the `if`** (round 311). James: "this is the smallest the app
        // runs on my iPad Pro 11 in both landscape and portrait, which is basically full screen
        // and much bigger than it runs on an iPhone" - and the app has been *asking* for a
        // phone-sized floor since round 310, so something above it is refusing.
        //
        // Two things could be, and one line tells them apart on a real iPad. Either
        // `sizeRestrictions` is nil, in which case this code has never had a say and the floor
        // is entirely the system's; or it is set and read back as something larger than asked
        // for, in which case iPadOS is clamping it. Neither can be reproduced on this Mac - the
        // iPadOS 26 simulators here refuse to boot - so it is asked on the device instead.
        //
        // The likeliest answer, worth knowing before reading the log: the app declares
        // **portrait only** on iPad, and iPadOS 26's windowing keeps a single-orientation app's
        // window at close to the screen's height because it has been told the app cannot lay
        // out in any other shape. James's two screenshots fit that exactly - in landscape the
        // window is portrait-shaped and full height, and in portrait it is nearly full screen -
        // and if that is it, the fix is a product decision about landscape rather than a number
        // in this file.
        // iPad multitasking arrived uninvited: iPadOS 26 resizes every app and ignores
        // UIRequiresFullScreen, so the app is resizable whether it opts in or not. The play
        // zone keeps its fixed 1.8236 aspect whatever the window does - GameSceneLayout owns
        // that - so a resize squeezes the *menus*, and below roughly a phone's width they
        // have not been designed to answer. There is no API to cap the ratio or the maximum,
        // so tall-and-thin and short-and-wide extremes above this floor still need the UI
        // audit in §12.0.
    }

    /// The smallest window the app will let itself be made.
    ///
    /// **The smallest phone it already supports**, rather than a number chosen by eye. James,
    /// round 311: "it's working well on the iPad, but the minimum size is basically full screen.
    /// It's ok to make it smaller, so long as the game view maintains its height to width
    /// ratio." The ratio is not at risk - `GameSceneLayout` owns the 1.8236 and asserts it - so
    /// the only question is how small the *menus* can be asked to be, and the honest answer is
    /// the size they are already laid out for.
    ///
    /// 320 by 568 is the iPhone SE's screen, which is the smallest device iOS 15 runs on and so
    /// the smallest the menus have ever had to work at. Round 310's floor was 420 by 640, which
    /// was a guess at "roughly a phone" and is wider than any phone the app supports.
    ///
    /// **It was being ignored outright until round 312, and James's iPad log said so:**
    ///
    ///     window floor asked for (320.0, 568.0), restrictions now (0.0, 0.0)
    ///     Update the Info.plist: Support for all orientations will soon be required.
    ///
    /// Read back, `minimumSize` was zero - the assignment never took. iPadOS ignores
    /// `sizeRestrictions` for an app that declares a single orientation, so the floor was
    /// entirely the system's and no number here was ever going to move it. The app declares all
    /// four orientations on iPad as of round 312, which is what makes this line mean anything.
    static let smallestWindow = CGSize(width: 320, height: 568)

    func sceneWillResignActive(_ scene: UIScene) {
        NotificationCenter.default.post(name: .pauseNotificationKey, object: nil)
        // Ensure game is paused when app is quit
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        NotificationCenter.default.post(name: .backgroundNotification, object: nil)
        // Save game state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        NSUbiquitousKeyValueStore.default.synchronize()
        NotificationCenter.default.post(name: .foregroundNotification, object: nil)
        // Check game center auth
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.post(name: .backgroundNotification, object: nil)
        // Save game state. Replaces applicationWillTerminate, which is not called for scene-based apps
    }
}
