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
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
//    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
//    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    var packStatsArray: [PackStats] = []
    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
    let defaults = UserDefaults.standard
    // User settings
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var appOpenCount: Int?
    var resumeGameToLoad: Bool?

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
    
    func saveUserDefaults() {
        print("llama llama icloud save user defaults")
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        adsSetting = defaults.bool(forKey: "adsSetting")
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        
        NSUbiquitousKeyValueStore.default.set(premiumSetting, forKey: "premiumSetting")
        NSUbiquitousKeyValueStore.default.set(adsSetting, forKey: "adsSetting")
        NSUbiquitousKeyValueStore.default.set(appOpenCount, forKey: "appOpenCount")
    }
    
    func loadUserDefaults() {
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
        print("llama llama icloud save total stats")
        loadTotalData()
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
    }
    
    func loadTotalStats() {
        print("llama llama icloud load total stats")
        loadTotalData()
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
        
        do {
            print("llama llama icloud save total stats updates")
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        // Save total stats changes
    }
    
//    var powerUpUnlockedArray: [Bool]?
//    var achievementsUnlockedArray: [Bool]?
//    var achievementsPercentageCompleteArray: [String]?
//    var achievementDates: [Date]?

    func loadDataToSync() {
        let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
        let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            savePackData = packData as NSData
        }

        if let levelData = try? Data(contentsOf: levelStatsStore!) {
            saveLevelData = levelData as NSData
        }
    }
    
    func saveRecords() {
        print("llama llama iCloud save records")
        let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
        let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            savePackData = packData as NSData
        }

        if let levelData = try? Data(contentsOf: levelStatsStore!) {
            saveLevelData = levelData as NSData
        }
        // Load data to sync
        
        // User Settings
        let levelAndPackRecord = CKRecord(recordType: "LevelAndPackRecord")

        levelAndPackRecord["packData"] = savePackData! as CKRecordValue
        levelAndPackRecord["levelData"] = saveLevelData! as CKRecordValue

        let myContainer = CKContainer.default()
        let privateDatabase = myContainer.privateCloudDatabase
        privateDatabase.save(levelAndPackRecord) { (record, error) in
            if let error = error {
                print("llama llama iCloud Error with iCloud Sync: \(error.localizedDescription)")
                return
            }
            print("llama llama iCloud Successful sync")
        }
    }

    func loadRecords() {
        print("llama llama iCloud load records")
        let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
        let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
        
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "LevelAndPackRecord", predicate: predicate)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = ["packData", "levelData"]
        operation.resultsLimit = 1
        // What data to retrieve

        operation.recordFetchedBlock = { record in
            self.savePackData = record["packData"]
            self.saveLevelData = record["levelData"]
        }
        // Store retrieved data as its downloading

        operation.queryCompletionBlock = { (cursor, error) in
            DispatchQueue.main.async {
                if error == nil {

                    if self.savePackData != nil {
                        do {
                            let data = self.savePackData
                            try data!.write(to: packStatsStore!)
                            print("llama llama iCloud packs data loaded")
                        } catch {
                            print("Error encoding pack stats array, \(error)")
                        }
                    }
                    if self.saveLevelData != nil {
                        do {
                            let data = self.saveLevelData
                            try data!.write(to: levelStatsStore!)
                            print("llama llama iCloud level data loaded")
                        } catch {
                            print("Error encoding level stats array, \(error)")
                        }
                    }

                    print("llama llama iCloud Successful Load")
                } else {
                    print("llama llama iCloud Error with iCloud Load: \(error!.localizedDescription)")
                }
            }
        }
        // What to do once the data has successfully been retrieved

        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func loadTotalData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
        // Load the total stats array from the NSCoder data store
        
//        if let packData = try? Data(contentsOf: packStatsStore!) {
//            do {
//                packStatsArray = try decoder.decode([PackStats].self, from: packData)
//            } catch {
//                print("Error decoding pack stats array, \(error)")
//            }
//        }
//        // Load the pack stats array from the NSCoder data store
//
//        if let levelData = try? Data(contentsOf: levelStatsStore!) {
//            do {
//                levelStatsArray = try decoder.decode([LevelStats].self, from: levelData)
//            } catch {
//                print("Error decoding level stats array, \(error)")
//            }
//        }
//        // Load the level stats array from the NSCoder data store
    }
    
    
    

    
    
    
    
    
    
    
    
}

//
//do {
//    let data = try scene.encoder.encode(self.scene.totalStatsArray)
//    try data.write(to: scene.totalStatsStore!)
//} catch {
//    print("Error encoding total stats, \(error)")
//}
//// Save total stats
    
// Things to sync across devices
    
        
//var saveGameSaveArray: [Int]?
//var saveMultiplier: Double?
//var saveBrickTextureArray: [Int]?
//var saveBrickColourArray: [Int]?
//var saveBrickXPositionArray: [Int]?
//var saveBrickYPositionArray: [Int]?
//var saveBallPropertiesArray: [Double]?
//
//var savePowerUpFallingXPositionArray: [Int]?
//var savePowerUpFallingYPositionArray: [Int]?
//var savePowerUpFallingArray: [Int]?
//var savePowerUpActiveArray: [String]?
//var savePowerUpActiveDurationArray: [Double]?
//var savePowerUpActiveTimerArray: [Double]?
//var savePowerUpActiveMagnitudeArray: [Int]?
    
//    TotalStats
//    var dateSaved: Date
//    var cumulativeScore: Int
//    var levelsPlayed: Int
//    var levelsCompleted: Int
//    var ballHits: Int
//    var ballsLost: Int
//    var powerupsCollected: [Int]
//    var powerupsGenerated: [Int]
//    var bricksHit: [Int]
//    var bricksDestroyed: [Int]
//    var lasersFired: Int
//    var lasersHit: Int
//    var playTimeSecs: Int
//    var packsPlayed: Int
//    var packsCompleted: Int
//    var endlessModeHeight: [Int]
//    var endlessModeHeightDate: [Date]
//    var levelPackUnlockedArray: [Bool]
//    var themeUnlockedArray: [Bool]
//    var appIconUnlockedArray: [Bool]
//    var levelUnlockedArray: [Bool]
//    var powerUpUnlockedArray: [Bool]
//    var achievementsUnlockedArray: [Bool]
//    var achievementsPercentageCompleteArray: [String]
//    var achievementDates: [Date]
