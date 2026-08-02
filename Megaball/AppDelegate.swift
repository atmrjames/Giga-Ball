//
//  AppDelegate.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import AVFoundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        NotificationCenter.default.addObserver(self, selector: #selector(onUbiquitousKeyValueStoreDidChangeExternally(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
                
        NSUbiquitousKeyValueStore.default.synchronize()
        
        MusicHandler.sharedHelper.prepareSession()
        // Ambient by default so other apps' audio keeps playing. Configured off the main
        // thread by MusicHandler, which owns the audio session from here on

        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    // Scene lifecycle is handled in SceneDelegate

    @objc func onUbiquitousKeyValueStoreDidChangeExternally(notification:Notification) {
        CloudKitHandler().loadFromiCloud()
        NotificationCenter.default.post(name: .refreshViewForSync, object: nil)
    }
    // Runs when there's an update to the iCloud database
}
