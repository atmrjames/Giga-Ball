//
//  AppDelegate.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import UIKit
import GoogleMobileAds
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        NotificationCenter.default.addObserver(self, selector: #selector(onUbiquitousKeyValueStoreDidChangeExternally(notification:)), name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: NSUbiquitousKeyValueStore.default)
                
        NSUbiquitousKeyValueStore.default.synchronize()
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "495ff44867243016091130f00d511026" ] // Test ads
        // Initialize Google Mobile Ads SDK
        
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        // Ensure audio is played in background by default
                
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .pauseNotificationKey, object: nil)
        // Ensure game is paused when app is quit
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: .backgroundNotification, object: nil)
        // Save game state
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        NSUbiquitousKeyValueStore.default.synchronize()
        NotificationCenter.default.post(name: .foregroundNotification, object: nil)
        // Check game center auth
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }
        
    func applicationWillTerminate(_ application: UIApplication) {
        NotificationCenter.default.post(name: .backgroundNotification, object: nil)
        // Save game state
    }
    
    @objc func onUbiquitousKeyValueStoreDidChangeExternally(notification:Notification) {
        CloudKitHandler().loadFromiCloud()
        NotificationCenter.default.post(name: .refreshViewForSync, object: nil)
    }
    // Runs when there's an update to the iCloud database
}
