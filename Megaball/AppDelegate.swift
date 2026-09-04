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
                
        guard GameCenterHandler.isRunningTests == false else { return true }
        // **The test runner needs neither iCloud nor an audio session** (round 306).
        //
        // Both of these reach outside the process at launch, and a simulator answers neither
        // quickly: `synchronize()` is a main-thread call into a key-value store with no
        // account behind it, and the audio session wants a server that may not answer at all -
        // which is CLAUDE.md's own audio-server trap, seen from the other side. The suite
        // launches the app once per batch, so every launch paid both.
        //
        // Measured, not assumed: Game Center's authentication was the first of these to be
        // caught doing it, at up to 207 seconds a launch, and the batches went on stalling
        // after it was guarded. Nothing under test wants either service - no test asserts on
        // iCloud sync or on audio - so the honest fix is not to start them.

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
        // Reads the key-value store into UserDefaults. No UI, so it stays on whichever
        // thread the notification arrived on

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .refreshViewForSync, object: nil)
        }
        // iCloud delivers didChangeExternallyNotification on a background thread, and
        // NotificationCenter runs observers synchronously on the posting thread. All
        // twelve observers of this refresh the UI - reloading table views, reapplying
        // motion effects, reading view frames - so posting from here without hopping to
        // main touched UIKit off the main thread every time a sync arrived
    }
    // Runs when there's an update to the iCloud database
}
