//
//  CloudKitHandler.swift
//  Megaball
//
//  Created by James Harding on 08/08/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import CloudKit

final class CloudKitHandler: NSObject {
    typealias CompletionBlock = (Error?) -> Void
    static let helper = CloudKitHandler()

    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
//    var packStatsArray: [PackStats] = []
//    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
    let defaults = UserDefaults.standard
    // User settings
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var appOpenCount: Int?
    var resumeGameToLoad: Bool?
    var iCloudSetting: Bool?

    // Total Stats
    var dateSaved: Date?
    var cumulativeScore: Int?
    var levelsPlayed: Int?
    var levelsCompleted: Int?
    var ballHits: Int?
    var ballsLost: Int?
    var powerupsCollected: [Int]?
    var powerupsGenerated: [Int]?
    var bricksHit: [Int]?
    var bricksDestroyed: [Int]?
    var lasersFired: Int?
    var lasersHit: Int?
    var playTimeSecs: Int?
    var packsPlayed: Int?
    var packsCompleted: Int?
    var endlessModeHeight: [Int]?
    var endlessModeHeightDate: [Date]?
    var levelPackUnlockedArray: [Bool]?
    var themeUnlockedArray: [Bool]?
    var appIconUnlockedArray: [Bool]?
    var levelUnlockedArray: [Bool]?
    var powerUpUnlockedArray: [Bool]?
    var achievementsUnlockedArray: [Bool]?
    var achievementsPercentageCompleteArray: [String]?
    var achievementDates: [Date]?
    var packHighScores: [Int]?
    var packBestTimes: [Int]?
    var pack1LevelHighScores: [Int]?
    var pack2LevelHighScores: [Int]?
    var pack3LevelHighScores: [Int]?
    var pack4LevelHighScores: [Int]?
    var pack5LevelHighScores: [Int]?
    var pack6LevelHighScores: [Int]?
    var pack7LevelHighScores: [Int]?
    var pack8LevelHighScores: [Int]?
    var pack9LevelHighScores: [Int]?
    var pack10LevelHighScores: [Int]?
    var pack11LevelHighScores: [Int]?
    
    // PackStats
    var savePackData: NSData?
    var packScores: [Int]?
    var packScoreDates: [Date]?
    var packNumberOfCompletes: Int?
    var packBestTime: Int?

    // LevelStats
    var saveLevelData: NSData?
    var levelScores: [Int]?
    var levelScoreDates: [Date]?
    var levelNumberOfCompletes: Int?
    
    func isICloudContainerAvailable() {
        CKContainer.default().accountStatus { (accountStatus, error) in
            if case .available = accountStatus {
                print("llama llama icloud on")
                self.iCloudSetting = true
                self.defaults.set(self.iCloudSetting!, forKey: "iCloudSetting")
            } else {
                print("llama llama icloud off")
                self.iCloudSetting = false
                self.defaults.set(self.iCloudSetting!, forKey: "iCloudSetting")
            }
        }
    }

    func saveUserDefaults() {
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            print("llama llama icloud off")
            return
        }
        // Check iCloud status and end function if not
        print("llama llama icloud save user defaults")
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        adsSetting = defaults.bool(forKey: "adsSetting")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        
        NSUbiquitousKeyValueStore.default.set(premiumSetting, forKey: "premiumSetting")
        NSUbiquitousKeyValueStore.default.set(adsSetting, forKey: "adsSetting")
        NSUbiquitousKeyValueStore.default.set(appOpenCount, forKey: "appOpenCount")
    }
    
    func loadUserDefaults() {
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            print("llama llama icloud off")
            return
        }
        // Check iCloud status and end function if not
        print("llama llama icloud load user defaults")
        premiumSetting = NSUbiquitousKeyValueStore.default.bool(forKey: "premiumSetting")
        adsSetting = NSUbiquitousKeyValueStore.default.bool(forKey: "adsSetting")
        appOpenCount = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "appOpenCount"))
        
        if self.premiumSetting != nil {
            self.defaults.set(self.premiumSetting!, forKey: "premiumSetting")
        }
        if self.adsSetting != nil {
            self.defaults.set(self.adsSetting!, forKey: "adsSetting")
        }
        if self.appOpenCount != nil {
            self.defaults.set(self.appOpenCount!, forKey: "appOpenCount")
        }
    }
    
    func saveTotalStats() {
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            print("llama llama icloud off")
            return
        }
        // Check iCloud status and end function if not
        print("llama llama icloud save total stats")
        let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        dateSaved = totalStatsArray[0].dateSaved
        cumulativeScore = totalStatsArray[0].cumulativeScore
        levelsPlayed = totalStatsArray[0].levelsPlayed
        levelsCompleted = totalStatsArray[0].levelsCompleted
        ballHits = totalStatsArray[0].ballHits
        ballsLost = totalStatsArray[0].ballsLost
        powerupsCollected = totalStatsArray[0].powerupsCollected
        powerupsGenerated = totalStatsArray[0].powerupsGenerated
        bricksHit = totalStatsArray[0].bricksHit
        bricksDestroyed = totalStatsArray[0].bricksDestroyed
        lasersFired = totalStatsArray[0].lasersFired
        lasersHit = totalStatsArray[0].lasersHit
        playTimeSecs = totalStatsArray[0].playTimeSecs
        packsPlayed = totalStatsArray[0].packsPlayed
        packsCompleted = totalStatsArray[0].packsCompleted
        endlessModeHeight = totalStatsArray[0].endlessModeHeight
        endlessModeHeightDate = totalStatsArray[0].endlessModeHeightDate
        levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray
        themeUnlockedArray = totalStatsArray[0].themeUnlockedArray
        appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray
        levelUnlockedArray = totalStatsArray[0].levelUnlockedArray
        powerUpUnlockedArray = totalStatsArray[0].powerUpUnlockedArray
        achievementsUnlockedArray = totalStatsArray[0].achievementsUnlockedArray
        achievementsPercentageCompleteArray = totalStatsArray[0].achievementsPercentageCompleteArray
        achievementDates = totalStatsArray[0].achievementDates
        packHighScores = totalStatsArray[0].packHighScores
        packBestTimes = totalStatsArray[0].packBestTimes
        pack1LevelHighScores = totalStatsArray[0].pack1LevelHighScores
        pack2LevelHighScores = totalStatsArray[0].pack2LevelHighScores
        pack3LevelHighScores = totalStatsArray[0].pack3LevelHighScores
        pack4LevelHighScores = totalStatsArray[0].pack4LevelHighScores
        pack5LevelHighScores = totalStatsArray[0].pack5LevelHighScores
        pack6LevelHighScores = totalStatsArray[0].pack6LevelHighScores
        pack7LevelHighScores = totalStatsArray[0].pack7LevelHighScores
        pack8LevelHighScores = totalStatsArray[0].pack8LevelHighScores
        pack9LevelHighScores = totalStatsArray[0].pack9LevelHighScores
        pack10LevelHighScores = totalStatsArray[0].pack10LevelHighScores
        pack11LevelHighScores = totalStatsArray[0].pack11LevelHighScores
        
        NSUbiquitousKeyValueStore.default.set(dateSaved, forKey: "dateSaved")
        NSUbiquitousKeyValueStore.default.set(cumulativeScore, forKey: "cumulativeScore")
        NSUbiquitousKeyValueStore.default.set(levelsPlayed, forKey: "levelsPlayed")
        NSUbiquitousKeyValueStore.default.set(levelsCompleted, forKey: "levelsCompleted")
        NSUbiquitousKeyValueStore.default.set(ballHits, forKey: "ballHits")
        NSUbiquitousKeyValueStore.default.set(ballsLost, forKey: "ballsLost")
        NSUbiquitousKeyValueStore.default.set(powerupsCollected, forKey: "powerupsCollected")
        NSUbiquitousKeyValueStore.default.set(powerupsGenerated, forKey: "powerupsGenerated")
        NSUbiquitousKeyValueStore.default.set(bricksHit, forKey: "bricksHit")
        NSUbiquitousKeyValueStore.default.set(bricksDestroyed, forKey: "bricksDestroyed")
        NSUbiquitousKeyValueStore.default.set(lasersFired, forKey: "lasersFired")
        NSUbiquitousKeyValueStore.default.set(lasersHit, forKey: "lasersHit")
        NSUbiquitousKeyValueStore.default.set(playTimeSecs, forKey: "playTimeSecs")
        NSUbiquitousKeyValueStore.default.set(packsPlayed, forKey: "packsPlayed")
        NSUbiquitousKeyValueStore.default.set(packsCompleted, forKey: "packsCompleted")
        NSUbiquitousKeyValueStore.default.set(endlessModeHeight, forKey: "endlessModeHeight")
        NSUbiquitousKeyValueStore.default.set(endlessModeHeightDate, forKey: "endlessModeHeightDate")
        NSUbiquitousKeyValueStore.default.set(levelPackUnlockedArray, forKey: "levelPackUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(themeUnlockedArray, forKey: "themeUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(appIconUnlockedArray, forKey: "appIconUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(levelUnlockedArray, forKey: "levelUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(powerUpUnlockedArray, forKey: "powerUpUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(achievementsUnlockedArray, forKey: "achievementsUnlockedArray")
        NSUbiquitousKeyValueStore.default.set(achievementsPercentageCompleteArray, forKey: "achievementsPercentageCompleteArray")
        NSUbiquitousKeyValueStore.default.set(achievementDates, forKey: "achievementDates")
        NSUbiquitousKeyValueStore.default.set(packHighScores, forKey: "packHighScores")
        NSUbiquitousKeyValueStore.default.set(packBestTimes, forKey: "packBestTimes")
        NSUbiquitousKeyValueStore.default.set(pack1LevelHighScores, forKey: "pack1LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack2LevelHighScores, forKey: "pack2LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack3LevelHighScores, forKey: "pack3LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack4LevelHighScores, forKey: "pack4LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack5LevelHighScores, forKey: "pack5LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack6LevelHighScores, forKey: "pack6LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack7LevelHighScores, forKey: "pack7LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack8LevelHighScores, forKey: "pack8LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack9LevelHighScores, forKey: "pack9LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack10LevelHighScores, forKey: "pack10LevelHighScores")
        NSUbiquitousKeyValueStore.default.set(pack11LevelHighScores, forKey: "pack11LevelHighScores")
    }
    
    func loadTotalStats() {
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            print("llama llama icloud off")
            return
        }
        // Check iCloud status and end function if not
        print("llama llama icloud load total stats")
        let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        dateSaved = NSUbiquitousKeyValueStore.default.object(forKey: "dateSaved") as? Date
        cumulativeScore = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "cumulativeScore"))
        levelsPlayed = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "levelsPlayed"))
        levelsCompleted = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "levelsCompleted"))
        ballHits = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "ballHits"))
        ballsLost = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "ballsLost"))
        powerupsCollected = NSUbiquitousKeyValueStore.default.array(forKey: "powerupsCollected") as? [Int]
        powerupsGenerated = NSUbiquitousKeyValueStore.default.array(forKey: "powerupsGenerated") as? [Int]
        bricksHit = NSUbiquitousKeyValueStore.default.array(forKey: "bricksHit") as? [Int]
        bricksDestroyed = NSUbiquitousKeyValueStore.default.array(forKey: "bricksDestroyed") as? [Int]
        lasersFired = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "lasersFired"))
        lasersHit = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "lasersHit"))
        playTimeSecs = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "playTimeSecs"))
        packsPlayed = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "packsPlayed"))
        packsCompleted = Int(NSUbiquitousKeyValueStore.default.longLong(forKey: "packsCompleted"))
        endlessModeHeight = NSUbiquitousKeyValueStore.default.array(forKey: "endlessModeHeight") as? [Int]
        endlessModeHeightDate = NSUbiquitousKeyValueStore.default.array(forKey: "endlessModeHeightDate") as? [Date]
        levelPackUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "levelPackUnlockedArray") as? [Bool]
        themeUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "themeUnlockedArray") as? [Bool]
        appIconUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "appIconUnlockedArray") as? [Bool]
        levelUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "levelUnlockedArray") as? [Bool]
        powerUpUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "powerUpUnlockedArray") as? [Bool]
        achievementsUnlockedArray = NSUbiquitousKeyValueStore.default.array(forKey: "achievementsUnlockedArray") as? [Bool]
        achievementsPercentageCompleteArray = NSUbiquitousKeyValueStore.default.array(forKey: "achievementsPercentageCompleteArray") as? [String]
        achievementDates = NSUbiquitousKeyValueStore.default.array(forKey: "achievementDates") as? [Date]
        packHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "packHighScores") as? [Int]
        packBestTimes = NSUbiquitousKeyValueStore.default.array(forKey: "packBestTimes") as? [Int]
        pack1LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack1LevelHighScores") as? [Int]
        pack2LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack2LevelHighScores") as? [Int]
        pack3LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack3LevelHighScores") as? [Int]
        pack4LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack4LevelHighScores") as? [Int]
        pack5LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack5LevelHighScores") as? [Int]
        pack6LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack6LevelHighScores") as? [Int]
        pack7LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack7LevelHighScores") as? [Int]
        pack8LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack8LevelHighScores") as? [Int]
        pack9LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack9LevelHighScores") as? [Int]
        pack10LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack10LevelHighScores") as? [Int]
        pack11LevelHighScores = NSUbiquitousKeyValueStore.default.array(forKey: "pack11LevelHighScores") as? [Int]
        
        if self.dateSaved != nil {
            totalStatsArray[0].dateSaved = dateSaved!
        }
        if self.cumulativeScore != nil {
            totalStatsArray[0].cumulativeScore = cumulativeScore!
        }
        if self.levelsPlayed != nil {
            totalStatsArray[0].levelsPlayed = levelsPlayed!
        }
        if self.levelsCompleted != nil {
            totalStatsArray[0].levelsCompleted = levelsCompleted!
        }
        if self.ballHits != nil {
            totalStatsArray[0].ballHits = ballHits!
        }
        if self.ballsLost != nil {
            totalStatsArray[0].ballsLost = ballsLost!
        }
        if self.powerupsCollected != nil {
            totalStatsArray[0].powerupsCollected = powerupsCollected!
        }
        if self.powerupsGenerated != nil {
            totalStatsArray[0].powerupsGenerated = powerupsGenerated!
        }
        if self.bricksHit != nil {
            totalStatsArray[0].bricksHit = bricksHit!
        }
        if self.bricksDestroyed != nil {
            totalStatsArray[0].bricksDestroyed = bricksDestroyed!
        }
        if self.lasersFired != nil {
            totalStatsArray[0].lasersFired = lasersFired!
        }
        if self.lasersHit != nil {
            totalStatsArray[0].lasersHit = lasersHit!
        }
        if self.playTimeSecs != nil {
            totalStatsArray[0].playTimeSecs = playTimeSecs!
        }
        if self.packsPlayed != nil {
            totalStatsArray[0].packsPlayed = packsPlayed!
        }
        if self.packsCompleted != nil {
            totalStatsArray[0].packsCompleted = packsCompleted!
        }
        if self.endlessModeHeight != nil {
            totalStatsArray[0].endlessModeHeight = endlessModeHeight!
        }
        if self.endlessModeHeightDate != nil {
            totalStatsArray[0].endlessModeHeightDate = endlessModeHeightDate!
        }
        if self.levelPackUnlockedArray != nil {
            totalStatsArray[0].levelPackUnlockedArray = levelPackUnlockedArray!
        }
        if self.themeUnlockedArray != nil {
            totalStatsArray[0].themeUnlockedArray = themeUnlockedArray!
        }
        if self.appIconUnlockedArray != nil {
            totalStatsArray[0].appIconUnlockedArray = appIconUnlockedArray!
        }
        if self.levelUnlockedArray != nil {
            totalStatsArray[0].levelUnlockedArray = levelUnlockedArray!
        }
        if self.powerUpUnlockedArray != nil {
            totalStatsArray[0].powerUpUnlockedArray = powerUpUnlockedArray!
        }
        if self.achievementsUnlockedArray != nil {
            totalStatsArray[0].achievementsUnlockedArray = achievementsUnlockedArray!
        }
        if self.achievementsPercentageCompleteArray != nil {
            totalStatsArray[0].achievementsPercentageCompleteArray = achievementsPercentageCompleteArray!
        }
        if self.achievementDates != nil {
            totalStatsArray[0].achievementDates = achievementDates!
        }
        if self.packHighScores != nil {
            totalStatsArray[0].packHighScores = packHighScores!
        }
        if self.packBestTimes != nil {
            totalStatsArray[0].packBestTimes = packBestTimes!
        }
        if self.pack1LevelHighScores != nil {
            totalStatsArray[0].pack1LevelHighScores = pack1LevelHighScores!
        }
        if self.pack2LevelHighScores != nil {
            totalStatsArray[0].pack2LevelHighScores = pack2LevelHighScores!
        }
        if self.pack3LevelHighScores != nil {
            totalStatsArray[0].pack3LevelHighScores = pack3LevelHighScores!
        }
        if self.pack4LevelHighScores != nil {
            totalStatsArray[0].pack4LevelHighScores = pack4LevelHighScores!
        }
        if self.pack5LevelHighScores != nil {
            totalStatsArray[0].pack5LevelHighScores = pack5LevelHighScores!
        }
        if self.pack6LevelHighScores != nil {
            totalStatsArray[0].pack6LevelHighScores = pack6LevelHighScores!
        }
        if self.pack7LevelHighScores != nil {
            totalStatsArray[0].pack7LevelHighScores = pack7LevelHighScores!
        }
        if self.pack8LevelHighScores != nil {
            totalStatsArray[0].pack8LevelHighScores = pack8LevelHighScores!
        }
        if self.pack9LevelHighScores != nil {
            totalStatsArray[0].pack9LevelHighScores = pack9LevelHighScores!
        }
        if self.pack10LevelHighScores != nil {
            totalStatsArray[0].pack10LevelHighScores = pack10LevelHighScores!
        }
        if self.pack11LevelHighScores != nil {
            totalStatsArray[0].pack11LevelHighScores = pack11LevelHighScores!
        }
        
        do {
            print("llama llama icloud save total stats updates")
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        // Save total stats changes
    }
}
