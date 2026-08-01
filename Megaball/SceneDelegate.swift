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
    }

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
