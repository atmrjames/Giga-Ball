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

    /// Lengthens an array that came from iCloud to match the one this build uses.
    ///
    /// Every one of these arrays is one entry per power-up, per achievement, per level or per
    /// pack, and iCloud holds whatever the last version to write it had. Adding the
    /// twenty-ninth power-up made the local array longer than the stored one, and every merge
    /// loop walks the local length while reading the stored array - so the first launch after
    /// the update read one past the end and crashed, on the device of somebody with years of
    /// synced progress.
    ///
    /// `TotalStats.padded` does exactly this for the file on disk. The same hazard was in the
    /// cloud copy and was missed, because the file is the one that looks like a save.
    ///
    /// The new entries take their values from the local array, which is what a brand-new
    /// power-up should sync as: whatever this device thinks of something the cloud has never
    /// heard of.
    static func padded<T>(_ cloud: [T], toMatch local: [T]) -> [T] {
        guard cloud.count < local.count else { return cloud }
        return cloud + local[cloud.count...]
    }

    /// The daily records travel through the key-value store as one encoded blob rather
    /// than as parallel arrays, because their merge is by *date*, not by index - two
    /// devices that each played different days have records the other has never heard
    /// of, and index-wise merging would pair unrelated days. `DailyChallengeRecord.merged`
    /// is the arbiter; these two are just the wire format.
    static func decodedDailyRecords(_ data: Data?) -> [DailyChallengeRecord] {
        guard let data else { return [] }
        return (try? PropertyListDecoder().decode([DailyChallengeRecord].self, from: data))
            ?? []
    }

    static func encodedDailyRecords(_ records: [DailyChallengeRecord]) -> Data? {
        try? PropertyListEncoder().encode(records)
    }

    typealias CompletionBlock = (Error?) -> Void
    static let helper = CloudKitHandler()

    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
    
    let defaults = UserDefaults.standard
    // User settings
    var appOpenCount: Int = 0
    var resumeGameToLoad: Bool = false
    var firstPause: Bool = true
    
    var iCloudSetting: Bool = false

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
    
    static let containerIdentifier = "iCloud.com.atmrjames.Megaball"
    // Named explicitly rather than using CKContainer.default(), which raises an uncatchable
    // CKException ("containerIdentifier can not be nil") when the iCloud entitlement is absent,
    // as it is on Simulator builds

    func isiCloudContainerAvailable() {
        guard FileManager.default.ubiquityIdentityToken != nil else {
            iCloudSetting = false
            defaults.set(false, forKey: "iCloudSetting")
            return
        }
        // Touching CloudKit at all raises an uncatchable exception when the process has no
        // iCloud entitlement, or when iCloud is unavailable to the user. Nil token means
        // syncing could not work anyway, so treat it exactly as an unavailable account

        CKContainer(identifier: CloudKitHandler.containerIdentifier).accountStatus { (accountStatus, error) in
            if case .available = accountStatus {
                self.iCloudSetting = true
                self.defaults.set(self.iCloudSetting, forKey: "iCloudSetting")
            } else {
                self.iCloudSetting = false
                self.defaults.set(self.iCloudSetting, forKey: "iCloudSetting")
            }
        }
    }
    
    /// Whether this sync should merge as usual, or defer to a reset on one side.
    func statsSyncResolution(against iCloudStore: NSUbiquitousKeyValueStore) -> SyncResolution {
        StatsSync.resolve(
            localGeneration: defaults.integer(forKey: StatsSync.generationKey),
            cloudGeneration: Int(iCloudStore.longLong(forKey: StatsSync.generationKey)))
    }

    func saveToiCloud() {
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if iCloudSetting {
            updateToiCloud()
        }
    }
    
    func updateToiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default

        switch statsSyncResolution(against: iCloudStore) {
        case .adoptCloud:
            // Another device has reset since this one. Pushing would merge the
            // stats it cleared straight back into iCloud.
            loadDataReset()
            return
        case .pushLocal:
            // This device reset last, so its lower numbers are the current
            // ones and merging would restore what the reset cleared.
            pushLocalDataWholesale()
            return
        case .merge:
            break
        }

        appOpenCount = defaults.integer(forKey: "appOpenCount")
        let appOpenCountCloud = Int(iCloudStore.longLong(forKey: "appOpenCount"))
        if appOpenCount > appOpenCountCloud {
            iCloudStore.set(appOpenCount, forKey: "appOpenCount")
        }

        firstPause = defaults.bool(forKey: "firstPause")
        let firstPauseCloud = iCloudStore.bool(forKey: "firstPause")
        if firstPause == false || firstPause != firstPauseCloud {
            iCloudStore.set(false, forKey: "firstPause")
        } else {
            iCloudStore.set(true, forKey: "firstPause")
        }

        let dailyRecordsMergedUp = DailyChallengeRecord.merged(
            totalStatsArray[0].dailyRecords,
            CloudKitHandler.decodedDailyRecords(iCloudStore.data(forKey: "dailyChallengeRecords")))
        if let encodedDaily = CloudKitHandler.encodedDailyRecords(dailyRecordsMergedUp) {
            iCloudStore.set(encodedDaily, forKey: "dailyChallengeRecords")
        }
        // The daily's per-day records (daily spec §10). Carried in iCloud partly for the
        // usual reason and partly for honesty: the current day's attempt flag surviving
        // a delete-and-reinstall is what keeps first-attempt-only meaning something

        cumulativeScore = totalStatsArray[0].cumulativeScore
        let cumulativeScoreCloud = Int(iCloudStore.longLong(forKey: "cumulativeScore"))
        if cumulativeScore! > cumulativeScoreCloud {
            iCloudStore.set(cumulativeScore, forKey: "cumulativeScore")
        }
        
        levelsPlayed = totalStatsArray[0].levelsPlayed
        let levelsPlayedCloud = Int(iCloudStore.longLong(forKey: "levelsPlayed"))
        if levelsPlayed! > levelsPlayedCloud {
            iCloudStore.set(levelsPlayed, forKey: "levelsPlayed")
        }
        
        levelsCompleted = totalStatsArray[0].levelsCompleted
        let levelsCompletedCloud = Int(iCloudStore.longLong(forKey: "levelsCompleted"))
        if levelsCompleted! > levelsCompletedCloud {
            iCloudStore.set(levelsCompleted, forKey: "levelsCompleted")
        }
        
        ballHits = totalStatsArray[0].ballHits
        let ballHitsCloud = Int(iCloudStore.longLong(forKey: "ballHits"))
        if ballHits! > ballHitsCloud {
            iCloudStore.set(ballHits, forKey: "ballHits")
        }
        
        ballsLost = totalStatsArray[0].ballsLost
        let ballsLostCloud = Int(iCloudStore.longLong(forKey: "ballsLost"))
        if ballsLost! > ballsLostCloud {
            iCloudStore.set(ballsLost, forKey: "ballsLost")
        }
        
        powerupsCollected = totalStatsArray[0].powerupsCollected
        if let powerupsCollectedCloudCheck = iCloudStore.array(forKey: "powerupsCollected") as? [Int] {
            var powerupsCollectedCloud = powerupsCollectedCloudCheck
            powerupsCollectedCloud = CloudKitHandler.padded(powerupsCollectedCloud, toMatch: powerupsCollected!)
            for i in 0..<min(powerupsCollected!.count, powerupsCollectedCloud.count) {
                if powerupsCollected![i] > powerupsCollectedCloud[i] {
                    powerupsCollectedCloud[i] = powerupsCollected![i]
                }
            }
            iCloudStore.set(powerupsCollectedCloud, forKey: "powerupsCollected")
        } else {
            iCloudStore.set(powerupsCollected, forKey: "powerupsCollected")
        }
        
        
        powerupsGenerated = totalStatsArray[0].powerupsGenerated
        if let powerupsGeneratedCloudCheck = iCloudStore.array(forKey: "powerupsGenerated") as? [Int] {
            var powerupsGeneratedCloud = powerupsGeneratedCloudCheck
            powerupsGeneratedCloud = CloudKitHandler.padded(powerupsGeneratedCloud, toMatch: powerupsGenerated!)
            for i in 0..<min(powerupsGenerated!.count, powerupsGeneratedCloud.count) {
                if powerupsGenerated![i] > powerupsGeneratedCloud[i] {
                    powerupsGeneratedCloud[i] = powerupsGenerated![i]
                }
            }
            iCloudStore.set(powerupsGeneratedCloud, forKey: "powerupsGenerated")
        } else {
            iCloudStore.set(powerupsGenerated, forKey: "powerupsGenerated")
        }
        
        bricksHit = totalStatsArray[0].bricksHit
        if let bricksHitCloudCheck = iCloudStore.array(forKey: "bricksHit") as? [Int] {
            var bricksHitCloud = bricksHitCloudCheck
            bricksHitCloud = CloudKitHandler.padded(bricksHitCloud, toMatch: bricksHit!)
            for i in 0..<min(bricksHit!.count, bricksHitCloud.count) {
                if bricksHit![i] > bricksHitCloud[i] {
                    bricksHitCloud[i] = bricksHit![i]
                }
            }
            iCloudStore.set(bricksHitCloud, forKey: "bricksHit")
        } else {
            iCloudStore.set(bricksHit, forKey: "bricksHit")
        }
        
        bricksDestroyed = totalStatsArray[0].bricksDestroyed
        if let bricksDestroyedCloudCheck = iCloudStore.array(forKey: "bricksDestroyed") as? [Int] {
            var bricksDestroyedCloud = bricksDestroyedCloudCheck
            bricksDestroyedCloud = CloudKitHandler.padded(bricksDestroyedCloud, toMatch: bricksDestroyed!)
            for i in 0..<min(bricksDestroyed!.count, bricksDestroyedCloud.count) {
                if bricksDestroyed![i] > bricksDestroyedCloud[i] {
                    bricksDestroyedCloud[i] = bricksDestroyed![i]
                }
            }
            iCloudStore.set(bricksDestroyedCloud, forKey: "bricksDestroyed")
        } else {
            iCloudStore.set(bricksDestroyed, forKey: "bricksDestroyed")
        }

        lasersFired = totalStatsArray[0].lasersFired
        let lasersFiredCloud = Int(iCloudStore.longLong(forKey: "lasersFired"))
        if lasersFired! > lasersFiredCloud {
            iCloudStore.set(lasersFired, forKey: "lasersFired")
        }
        
        lasersHit = totalStatsArray[0].lasersHit
        let lasersHitCloud = Int(iCloudStore.longLong(forKey: "lasersHit"))
        if lasersHit! > lasersHitCloud {
            iCloudStore.set(lasersHit, forKey: "lasersHit")
        }
        
        playTimeSecs = totalStatsArray[0].playTimeSecs
        let playTimeSecsCloud = Int(iCloudStore.longLong(forKey: "playTimeSecs"))
        if playTimeSecs! > playTimeSecsCloud {
            iCloudStore.set(playTimeSecs, forKey: "playTimeSecs")
        }
        
        packsPlayed = totalStatsArray[0].packsPlayed
        let packsPlayedCloud = Int(iCloudStore.longLong(forKey: "packsPlayed"))
        if packsPlayed! > packsPlayedCloud {
            iCloudStore.set(packsPlayed, forKey: "packsPlayed")
        }
        
        packsCompleted = totalStatsArray[0].packsCompleted
        let packsCompletedCloud = Int(iCloudStore.longLong(forKey: "packsCompleted"))
        if packsCompleted! > packsCompletedCloud {
            iCloudStore.set(packsCompleted, forKey: "packsCompleted")
        }
        
        endlessModeHeight = totalStatsArray[0].endlessModeHeight
        if let endlessModeHeightCloud = iCloudStore.array(forKey: "endlessModeHeight") as? [Int] {
            if endlessModeHeight!.reduce(0, +) > endlessModeHeightCloud.reduce(0, +) {
                iCloudStore.set(endlessModeHeight, forKey: "endlessModeHeight")
            }
        } else {
            iCloudStore.set(endlessModeHeight, forKey: "endlessModeHeight")
        }
        
        levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray
        if let levelPackUnlockedArrayCloudCheck = iCloudStore.array(forKey: "levelPackUnlockedArray") as? [Bool] {
            var levelPackUnlockedArrayCloud = levelPackUnlockedArrayCloudCheck
            levelPackUnlockedArrayCloud = CloudKitHandler.padded(levelPackUnlockedArrayCloud, toMatch: levelPackUnlockedArray!)
            for i in 0..<min(levelPackUnlockedArray!.count, levelPackUnlockedArrayCloud.count) {
                if levelPackUnlockedArray![i] || levelPackUnlockedArray![i] != levelPackUnlockedArrayCloud[i] {
                    levelPackUnlockedArrayCloud[i] = true
                } else {
                    levelPackUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(levelPackUnlockedArrayCloud, forKey: "levelPackUnlockedArray")
        } else {
            iCloudStore.set(levelPackUnlockedArray, forKey: "levelPackUnlockedArray")
        }
        
        themeUnlockedArray = totalStatsArray[0].themeUnlockedArray
        if let themeUnlockedArrayCloudCheck = iCloudStore.array(forKey: "themeUnlockedArray") as? [Bool] {
            var themeUnlockedArrayCloud = themeUnlockedArrayCloudCheck
            themeUnlockedArrayCloud = CloudKitHandler.padded(themeUnlockedArrayCloud, toMatch: themeUnlockedArray!)
            for i in 0..<min(themeUnlockedArray!.count, themeUnlockedArrayCloud.count) {
                if themeUnlockedArray![i] || themeUnlockedArray![i] != themeUnlockedArrayCloud[i] {
                    themeUnlockedArrayCloud[i] = true
                } else {
                    themeUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(themeUnlockedArrayCloud, forKey: "themeUnlockedArray")
        } else {
            iCloudStore.set(themeUnlockedArray, forKey: "themeUnlockedArray")
        }
        
        appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray
        if let appIconUnlockedArrayCloudCheck = iCloudStore.array(forKey: "appIconUnlockedArray") as? [Bool] {
            var appIconUnlockedArrayCloud = appIconUnlockedArrayCloudCheck
            appIconUnlockedArrayCloud = CloudKitHandler.padded(appIconUnlockedArrayCloud, toMatch: appIconUnlockedArray!)
            for i in 0..<min(appIconUnlockedArray!.count, appIconUnlockedArrayCloud.count) {
                if appIconUnlockedArray![i] || appIconUnlockedArray![i] != appIconUnlockedArrayCloud[i] {
                    appIconUnlockedArrayCloud[i] = true
                } else {
                    appIconUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(appIconUnlockedArrayCloud, forKey: "appIconUnlockedArray")
        } else {
            iCloudStore.set(appIconUnlockedArray, forKey: "appIconUnlockedArray")
        }
        
        levelUnlockedArray = totalStatsArray[0].levelUnlockedArray
        if let levelUnlockedArrayCloudCheck = iCloudStore.array(forKey: "levelUnlockedArray") as? [Bool] {
            var levelUnlockedArrayCloud = levelUnlockedArrayCloudCheck
            levelUnlockedArrayCloud = CloudKitHandler.padded(levelUnlockedArrayCloud, toMatch: levelUnlockedArray!)
            for i in 0..<min(levelUnlockedArray!.count, levelUnlockedArrayCloud.count) {
                if levelUnlockedArray![i] || levelUnlockedArray![i] != levelUnlockedArrayCloud[i] {
                    levelUnlockedArrayCloud[i] = true
                } else {
                    levelUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(levelUnlockedArrayCloud, forKey: "levelUnlockedArray")
        } else {
            iCloudStore.set(levelUnlockedArray, forKey: "levelUnlockedArray")
        }
        
        powerUpUnlockedArray = totalStatsArray[0].powerUpUnlockedArray
        if let powerUpUnlockedArrayCloudCheck = iCloudStore.array(forKey: "powerUpUnlockedArray") as? [Bool] {
            var powerUpUnlockedArrayCloud = powerUpUnlockedArrayCloudCheck
            powerUpUnlockedArrayCloud = CloudKitHandler.padded(powerUpUnlockedArrayCloud, toMatch: powerUpUnlockedArray!)
            for i in 0..<min(powerUpUnlockedArray!.count, powerUpUnlockedArrayCloud.count) {
                if powerUpUnlockedArray![i] || powerUpUnlockedArray![i] != powerUpUnlockedArrayCloud[i] {
                    powerUpUnlockedArrayCloud[i] = true
                } else {
                    powerUpUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(powerUpUnlockedArrayCloud, forKey: "powerUpUnlockedArray")
        } else {
            iCloudStore.set(powerUpUnlockedArray, forKey: "powerUpUnlockedArray")
        }
        
        achievementsUnlockedArray = totalStatsArray[0].achievementsUnlockedArray
        if let achievementsUnlockedArrayCloudCheck = iCloudStore.array(forKey: "achievementsUnlockedArray") as? [Bool] {
            var achievementsUnlockedArrayCloud = achievementsUnlockedArrayCloudCheck
            achievementsUnlockedArrayCloud = CloudKitHandler.padded(achievementsUnlockedArrayCloud, toMatch: achievementsUnlockedArray!)
            for i in 0..<min(achievementsUnlockedArray!.count, achievementsUnlockedArrayCloud.count) {
                if achievementsUnlockedArray![i] || achievementsUnlockedArray![i] != achievementsUnlockedArrayCloud[i] {
                    achievementsUnlockedArrayCloud[i] = true
                } else {
                    achievementsUnlockedArrayCloud[i] = false
                }
            }
            iCloudStore.set(achievementsUnlockedArrayCloud, forKey: "achievementsUnlockedArray")
        } else {
            iCloudStore.set(achievementsUnlockedArray, forKey: "achievementsUnlockedArray")

        }
        
        achievementsPercentageCompleteArray = totalStatsArray[0].achievementsPercentageCompleteArray
        achievementDates = totalStatsArray[0].achievementDates
        if let achievementsPercentageCompleteArrayCloudCheck = iCloudStore.array(forKey: "achievementsUnlockedArray") as? [String] {
            var achievementsPercentageCompleteArrayCloud = achievementsPercentageCompleteArrayCloudCheck
            achievementsPercentageCompleteArrayCloud = CloudKitHandler.padded(achievementsPercentageCompleteArrayCloud, toMatch: achievementsPercentageCompleteArray!)
            var achievementDatesCloud = iCloudStore.array(forKey: "achievementDates") as? [Date]
            for i in 0..<min(achievementsPercentageCompleteArray!.count, achievementsPercentageCompleteArrayCloud.count) {
                if achievementsPercentageCompleteArray![i] != "" && achievementsPercentageCompleteArray![i] != "0.0%" {
                    achievementsPercentageCompleteArrayCloud[i] = achievementsPercentageCompleteArray![i]
                    achievementDatesCloud![i] = achievementDates![i]
                }
            }
            iCloudStore.set(achievementsPercentageCompleteArrayCloud, forKey: "achievementsPercentageCompleteArray")
            iCloudStore.set(achievementDatesCloud, forKey: "achievementDates")
        } else {
            iCloudStore.set(achievementsPercentageCompleteArray, forKey: "achievementsPercentageCompleteArray")
            iCloudStore.set(achievementDates, forKey: "achievementDates")
        }
        
        packHighScores = totalStatsArray[0].packHighScores
        if let packHighScoresCloudCheck = iCloudStore.array(forKey: "packHighScores") as? [Int] {
            var packHighScoresCloud = packHighScoresCloudCheck
            packHighScoresCloud = CloudKitHandler.padded(packHighScoresCloud, toMatch: packHighScores!)
            for i in 0..<min(packHighScores!.count, packHighScoresCloud.count) {
                if packHighScores![i] > packHighScoresCloud[i] {
                    packHighScoresCloud[i] = packHighScores![i]
                }
            }
            iCloudStore.set(packHighScoresCloud, forKey: "packHighScores")
        } else {
            iCloudStore.set(packHighScores, forKey: "packHighScores")
        }
  
        packBestTimes = totalStatsArray[0].packBestTimes
        if let packBestTimesCloudCheck = iCloudStore.array(forKey: "packBestTimes") as? [Int] {
            var packBestTimesCloud = packBestTimesCloudCheck
            packBestTimesCloud = CloudKitHandler.padded(packBestTimesCloud, toMatch: packBestTimes!)
            for i in 0..<min(packBestTimes!.count, packBestTimesCloud.count) {
                if packBestTimes![i] > packBestTimesCloud[i] {
                    packBestTimesCloud[i] = packBestTimes![i]
                }
            }
            iCloudStore.set(packBestTimesCloud, forKey: "packBestTimes")
        } else {
            iCloudStore.set(packBestTimes, forKey: "packBestTimes")
        }
        
        pack1LevelHighScores = totalStatsArray[0].pack1LevelHighScores
        if let pack1LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack1LevelHighScores") as? [Int] {
            var pack1LevelHighScoresCloud = pack1LevelHighScoresCloudCheck
            pack1LevelHighScoresCloud = CloudKitHandler.padded(pack1LevelHighScoresCloud, toMatch: pack1LevelHighScores!)
            for i in 0..<min(pack1LevelHighScores!.count, pack1LevelHighScoresCloud.count) {
                if pack1LevelHighScores![i] > pack1LevelHighScoresCloud[i] {
                    pack1LevelHighScoresCloud[i] = pack1LevelHighScores![i]
                }
            }
            iCloudStore.set(pack1LevelHighScoresCloud, forKey: "pack1LevelHighScores")
        } else {
            iCloudStore.set(pack1LevelHighScores, forKey: "pack1LevelHighScores")
        }
        
        pack2LevelHighScores = totalStatsArray[0].pack2LevelHighScores
        if let pack2LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack2LevelHighScores") as? [Int] {
        var pack2LevelHighScoresCloud = pack2LevelHighScoresCloudCheck
        pack2LevelHighScoresCloud = CloudKitHandler.padded(pack2LevelHighScoresCloud, toMatch: pack2LevelHighScores!)
            for i in 0..<min(pack2LevelHighScores!.count, pack2LevelHighScoresCloud.count) {
                if pack2LevelHighScores![i] > pack2LevelHighScoresCloud[i] {
                    pack2LevelHighScoresCloud[i] = pack2LevelHighScores![i]
                }
            }
            iCloudStore.set(pack2LevelHighScoresCloud, forKey: "pack2LevelHighScores")
        } else {
            iCloudStore.set(pack2LevelHighScores, forKey: "pack2LevelHighScores")
        }
        
        pack3LevelHighScores = totalStatsArray[0].pack3LevelHighScores
        if let pack3LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack3LevelHighScores") as? [Int] {
        var pack3LevelHighScoresCloud = pack3LevelHighScoresCloudCheck
        pack3LevelHighScoresCloud = CloudKitHandler.padded(pack3LevelHighScoresCloud, toMatch: pack3LevelHighScores!)
            for i in 0..<min(pack3LevelHighScores!.count, pack3LevelHighScoresCloud.count) {
                if pack3LevelHighScores![i] > pack3LevelHighScoresCloud[i] {
                    pack3LevelHighScoresCloud[i] = pack3LevelHighScores![i]
                }
            }
            iCloudStore.set(pack3LevelHighScoresCloud, forKey: "pack3LevelHighScores")
        } else {
            iCloudStore.set(pack3LevelHighScores, forKey: "pack3LevelHighScores")
        }
        
        pack4LevelHighScores = totalStatsArray[0].pack4LevelHighScores
        if let pack4LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack4LevelHighScores") as? [Int] {
        var pack4LevelHighScoresCloud = pack4LevelHighScoresCloudCheck
        pack4LevelHighScoresCloud = CloudKitHandler.padded(pack4LevelHighScoresCloud, toMatch: pack4LevelHighScores!)
            for i in 0..<min(pack4LevelHighScores!.count, pack4LevelHighScoresCloud.count) {
                if pack4LevelHighScores![i] > pack4LevelHighScoresCloud[i] {
                    pack4LevelHighScoresCloud[i] = pack4LevelHighScores![i]
                }
            }
            iCloudStore.set(pack4LevelHighScoresCloud, forKey: "pack4LevelHighScores")
        } else {
            iCloudStore.set(pack4LevelHighScores, forKey: "pack4LevelHighScores")
        }
        
        pack5LevelHighScores = totalStatsArray[0].pack5LevelHighScores
        if let pack5LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack5LevelHighScores") as? [Int] {
        var pack5LevelHighScoresCloud = pack5LevelHighScoresCloudCheck
        pack5LevelHighScoresCloud = CloudKitHandler.padded(pack5LevelHighScoresCloud, toMatch: pack5LevelHighScores!)
            for i in 0..<min(pack5LevelHighScores!.count, pack5LevelHighScoresCloud.count) {
                if pack5LevelHighScores![i] > pack5LevelHighScoresCloud[i] {
                    pack5LevelHighScoresCloud[i] = pack5LevelHighScores![i]
                }
            }
            iCloudStore.set(pack5LevelHighScoresCloud, forKey: "pack5LevelHighScores")
        } else {
            iCloudStore.set(pack5LevelHighScores, forKey: "pack5LevelHighScores")
        }
        
        pack6LevelHighScores = totalStatsArray[0].pack6LevelHighScores
        if let pack6LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack6LevelHighScores") as? [Int] {
        var pack6LevelHighScoresCloud = pack6LevelHighScoresCloudCheck
        pack6LevelHighScoresCloud = CloudKitHandler.padded(pack6LevelHighScoresCloud, toMatch: pack6LevelHighScores!)
            for i in 0..<min(pack6LevelHighScores!.count, pack6LevelHighScoresCloud.count) {
                if pack6LevelHighScores![i] > pack6LevelHighScoresCloud[i] {
                    pack6LevelHighScoresCloud[i] = pack6LevelHighScores![i]
                }
            }
            iCloudStore.set(pack6LevelHighScoresCloud, forKey: "pack6LevelHighScores")
        } else {
            iCloudStore.set(pack6LevelHighScores, forKey: "pack6LevelHighScores")
        }
        
        pack7LevelHighScores = totalStatsArray[0].pack7LevelHighScores
        if let pack7LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack7LevelHighScores") as? [Int] {
        var pack7LevelHighScoresCloud = pack7LevelHighScoresCloudCheck
        pack7LevelHighScoresCloud = CloudKitHandler.padded(pack7LevelHighScoresCloud, toMatch: pack7LevelHighScores!)
            for i in 0..<min(pack7LevelHighScores!.count, pack7LevelHighScoresCloud.count) {
                if pack7LevelHighScores![i] > pack7LevelHighScoresCloud[i] {
                    pack7LevelHighScoresCloud[i] = pack7LevelHighScores![i]
                }
            }
            iCloudStore.set(pack7LevelHighScoresCloud, forKey: "pack7LevelHighScores")
        } else {
            iCloudStore.set(pack7LevelHighScores, forKey: "pack7LevelHighScores")
        }
        
        pack8LevelHighScores = totalStatsArray[0].pack8LevelHighScores
        if let pack8LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack8LevelHighScores") as? [Int] {
        var pack8LevelHighScoresCloud = pack8LevelHighScoresCloudCheck
        pack8LevelHighScoresCloud = CloudKitHandler.padded(pack8LevelHighScoresCloud, toMatch: pack8LevelHighScores!)
            for i in 0..<min(pack8LevelHighScores!.count, pack8LevelHighScoresCloud.count) {
                if pack8LevelHighScores![i] > pack8LevelHighScoresCloud[i] {
                    pack8LevelHighScoresCloud[i] = pack8LevelHighScores![i]
                }
            }
            iCloudStore.set(pack8LevelHighScoresCloud, forKey: "pack8LevelHighScores")
        } else {
            iCloudStore.set(pack8LevelHighScores, forKey: "pack8LevelHighScores")
        }
        
        pack9LevelHighScores = totalStatsArray[0].pack9LevelHighScores
        if let pack9LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack9LevelHighScores") as? [Int] {
        var pack9LevelHighScoresCloud = pack9LevelHighScoresCloudCheck
        pack9LevelHighScoresCloud = CloudKitHandler.padded(pack9LevelHighScoresCloud, toMatch: pack9LevelHighScores!)
            for i in 0..<min(pack9LevelHighScores!.count, pack9LevelHighScoresCloud.count) {
                if pack9LevelHighScores![i] > pack9LevelHighScoresCloud[i] {
                    pack9LevelHighScoresCloud[i] = pack9LevelHighScores![i]
                }
            }
            iCloudStore.set(pack9LevelHighScoresCloud, forKey: "pack9LevelHighScores")
        } else {
            iCloudStore.set(pack9LevelHighScores, forKey: "pack9LevelHighScores")
        }
        
        pack10LevelHighScores = totalStatsArray[0].pack10LevelHighScores
        if let pack10LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack10LevelHighScores") as? [Int] {
        var pack10LevelHighScoresCloud = pack10LevelHighScoresCloudCheck
        pack10LevelHighScoresCloud = CloudKitHandler.padded(pack10LevelHighScoresCloud, toMatch: pack10LevelHighScores!)
            for i in 0..<min(pack10LevelHighScores!.count, pack10LevelHighScoresCloud.count) {
                if pack10LevelHighScores![i] > pack10LevelHighScoresCloud[i] {
                    pack10LevelHighScoresCloud[i] = pack10LevelHighScores![i]
                }
            }
            iCloudStore.set(pack10LevelHighScoresCloud, forKey: "pack10LevelHighScores")
        } else {
            iCloudStore.set(pack10LevelHighScores, forKey: "pack10LevelHighScores")
        }
        
        pack11LevelHighScores = totalStatsArray[0].pack11LevelHighScores
        if let pack11LevelHighScoresCloudCheck = iCloudStore.array(forKey: "pack11LevelHighScores") as? [Int] {
        var pack11LevelHighScoresCloud = pack11LevelHighScoresCloudCheck
        pack11LevelHighScoresCloud = CloudKitHandler.padded(pack11LevelHighScoresCloud, toMatch: pack11LevelHighScores!)
            for i in 0..<min(pack11LevelHighScores!.count, pack11LevelHighScoresCloud.count) {
                if pack11LevelHighScores![i] > pack11LevelHighScoresCloud[i] {
                    pack11LevelHighScoresCloud[i] = pack11LevelHighScores![i]
                }
            }
            iCloudStore.set(pack11LevelHighScoresCloud, forKey: "pack11LevelHighScores")
        } else {
            iCloudStore.set(pack11LevelHighScores, forKey: "pack11LevelHighScores")
        }
    
        iCloudStore.synchronize()
        saveLocalData()
    }
    
    func loadFromiCloud() {
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if iCloudSetting {
            updateFromiCloud()
        }
    }
    
    func updateFromiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default

        switch statsSyncResolution(against: iCloudStore) {
        case .adoptCloud:
            loadDataReset()
            return
        case .pushLocal:
            // A reset here has not reached iCloud yet. Pulling would merge the
            // stats it cleared back onto this device.
            pushLocalDataWholesale()
            return
        case .merge:
            break
        }

        appOpenCount = defaults.integer(forKey: "appOpenCount")
        let appOpenCountCloud = Int(iCloudStore.longLong(forKey: "appOpenCount"))
        if appOpenCountCloud > appOpenCount {
            self.defaults.set(appOpenCountCloud, forKey: "appOpenCount")
        }

        totalStatsArray[0].dailyChallengeRecords = DailyChallengeRecord.merged(
            totalStatsArray[0].dailyRecords,
            CloudKitHandler.decodedDailyRecords(iCloudStore.data(forKey: "dailyChallengeRecords")))
        // The daily records come down the same way they went up: merged by date, so a
        // day played on another device lands here without disturbing days played on this
        // one - and the attempt flag arrives with it
        
        firstPause = defaults.bool(forKey: "firstPause")
        let firstPauseCloud = iCloudStore.bool(forKey: "firstPause")
        if firstPause == false || firstPause != firstPauseCloud {
            firstPause = false
        } else {
            firstPause = true
        }
        self.defaults.set(self.firstPause, forKey: "firstPause")
    
        cumulativeScore = totalStatsArray[0].cumulativeScore
        let cumulativeScoreCloud = Int(iCloudStore.longLong(forKey: "cumulativeScore"))
        if cumulativeScoreCloud > cumulativeScore! {
            totalStatsArray[0].cumulativeScore = cumulativeScoreCloud
        }
        
        levelsPlayed = totalStatsArray[0].levelsPlayed
        let levelsPlayedCloud = Int(iCloudStore.longLong(forKey: "levelsPlayed"))
        if levelsPlayedCloud > levelsPlayed! {
            totalStatsArray[0].levelsPlayed = levelsPlayedCloud
        }
        
        levelsCompleted = totalStatsArray[0].levelsCompleted
        let levelsCompletedCloud = Int(iCloudStore.longLong(forKey: "levelsCompleted"))
        if levelsCompletedCloud > levelsCompleted! {
            totalStatsArray[0].levelsCompleted = levelsCompletedCloud
        }
        
        ballHits = totalStatsArray[0].ballHits
        let ballHitsCloud = Int(iCloudStore.longLong(forKey: "ballHits"))
        if ballHitsCloud > ballHits! {
            totalStatsArray[0].ballHits = ballHitsCloud
        }
        
        ballsLost = totalStatsArray[0].ballsLost
        let ballsLostCloud = Int(iCloudStore.longLong(forKey: "ballsLost"))
        if ballsLostCloud > ballsLost! {
            totalStatsArray[0].ballsLost = ballsLostCloud
        }
        
        powerupsCollected = totalStatsArray[0].powerupsCollected
        if let powerupsCollectedCloud = iCloudStore.array(forKey: "powerupsCollected") as? [Int] {
            for i in 0..<min(powerupsCollectedCloud.count, powerupsCollected!.count) {
                if powerupsCollectedCloud[i] > powerupsCollected![i] {
                    powerupsCollected![i] = powerupsCollectedCloud[i]
                }
            }
        }
        totalStatsArray[0].powerupsCollected = powerupsCollected!
        
        powerupsGenerated = totalStatsArray[0].powerupsGenerated
        if let powerupsGeneratedCloud = iCloudStore.array(forKey: "powerupsGenerated") as? [Int] {
            for i in 0..<min(powerupsGeneratedCloud.count, powerupsGenerated!.count) {
                if powerupsGeneratedCloud[i] > powerupsGenerated![i] {
                    powerupsGenerated![i] = powerupsGeneratedCloud[i]
                }
            }
        }
        totalStatsArray[0].powerupsGenerated = powerupsGenerated!
        
        bricksHit = totalStatsArray[0].bricksHit
        if let bricksHitCloud = iCloudStore.array(forKey: "bricksHit") as? [Int] {
            for i in 0..<min(bricksHitCloud.count, bricksHit!.count) {
                if bricksHitCloud[i] > bricksHit![i] {
                    bricksHit![i] = bricksHitCloud[i]
                }
            }
        }
        totalStatsArray[0].bricksHit = bricksHit!
        
        bricksDestroyed = totalStatsArray[0].bricksDestroyed
        if let bricksDestroyedCloud = iCloudStore.array(forKey: "bricksDestroyed") as? [Int] {
            for i in 0..<min(bricksDestroyedCloud.count, bricksDestroyed!.count) {
                if bricksDestroyedCloud[i] > bricksDestroyed![i] {
                    powerupsCollected![i] = bricksDestroyedCloud[i]
                }
            }
        }
        totalStatsArray[0].bricksDestroyed = bricksDestroyed!

        lasersFired = totalStatsArray[0].lasersFired
        let lasersFiredCloud = Int(iCloudStore.longLong(forKey: "lasersFired"))
        if lasersFiredCloud > lasersFired! {
            totalStatsArray[0].lasersFired = lasersFiredCloud
        }
        
        lasersHit = totalStatsArray[0].lasersHit
        let lasersHitCloud = Int(iCloudStore.longLong(forKey: "lasersHit"))
        if lasersHitCloud > lasersHit! {
            totalStatsArray[0].lasersHit = lasersHitCloud
        }
        
        playTimeSecs = totalStatsArray[0].playTimeSecs
        let playTimeSecsCloud = Int(iCloudStore.longLong(forKey: "playTimeSecs"))
        if playTimeSecsCloud > playTimeSecs! {
            totalStatsArray[0].playTimeSecs = playTimeSecsCloud
        }
        
        packsPlayed = totalStatsArray[0].packsPlayed
        let packsPlayedCloud = Int(iCloudStore.longLong(forKey: "packsPlayed"))
        if packsPlayedCloud > packsPlayed! {
            totalStatsArray[0].packsPlayed = packsPlayedCloud
        }
        
        packsCompleted = totalStatsArray[0].packsCompleted
        let packsCompletedCloud = Int(iCloudStore.longLong(forKey: "packsCompleted"))
        if packsCompletedCloud > packsCompleted! {
            totalStatsArray[0].packsCompleted = packsCompletedCloud
        }

        endlessModeHeight = totalStatsArray[0].endlessModeHeight
        if let endlessModeHeightCloud = iCloudStore.array(forKey: "endlessModeHeight") as? [Int] {
            if endlessModeHeightCloud.reduce(0, +) > endlessModeHeight!.reduce(0, +) {
                totalStatsArray[0].endlessModeHeight = endlessModeHeightCloud
            }
        }
        

        levelPackUnlockedArray = totalStatsArray[0].levelPackUnlockedArray
        if let levelPackUnlockedArrayCloud = iCloudStore.array(forKey: "levelPackUnlockedArray") as? [Bool] {
            for i in 0..<min(levelPackUnlockedArray!.count, levelPackUnlockedArrayCloud.count) {
                if levelPackUnlockedArrayCloud[i] || levelPackUnlockedArray![i] != levelPackUnlockedArrayCloud[i] {
                    levelPackUnlockedArray![i] = true
                } else {
                    levelPackUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].levelPackUnlockedArray = levelPackUnlockedArray!
        
        themeUnlockedArray = totalStatsArray[0].themeUnlockedArray
        if let themeUnlockedArrayCloud = iCloudStore.array(forKey: "themeUnlockedArray") as? [Bool] {
            for i in 0..<min(themeUnlockedArray!.count, themeUnlockedArrayCloud.count) {
                if themeUnlockedArrayCloud[i] || themeUnlockedArray![i] != themeUnlockedArrayCloud[i] {
                    themeUnlockedArray![i] = true
                } else {
                    themeUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].themeUnlockedArray = themeUnlockedArray!
        
        appIconUnlockedArray = totalStatsArray[0].appIconUnlockedArray
        if let appIconUnlockedArrayCloud = iCloudStore.array(forKey: "appIconUnlockedArray") as? [Bool] {
            for i in 0..<min(appIconUnlockedArray!.count, appIconUnlockedArrayCloud.count) {
                if appIconUnlockedArrayCloud[i] || appIconUnlockedArray![i] != appIconUnlockedArrayCloud[i] {
                    appIconUnlockedArray![i] = true
                } else {
                    appIconUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].appIconUnlockedArray = appIconUnlockedArray!
        
        levelUnlockedArray = totalStatsArray[0].levelUnlockedArray
        if let levelUnlockedArrayCloud = iCloudStore.array(forKey: "levelUnlockedArray") as? [Bool] {
            for i in 0..<min(levelUnlockedArray!.count, levelUnlockedArrayCloud.count) {
                if levelUnlockedArrayCloud[i] || levelUnlockedArray![i] != levelUnlockedArrayCloud[i] {
                    levelUnlockedArray![i] = true
                } else {
                    levelUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].levelUnlockedArray = levelUnlockedArray!
        
        powerUpUnlockedArray = totalStatsArray[0].powerUpUnlockedArray
        if let powerUpUnlockedArrayCloud = iCloudStore.array(forKey: "powerUpUnlockedArray") as? [Bool] {
            for i in 0..<min(powerUpUnlockedArray!.count, powerUpUnlockedArrayCloud.count) {
                if powerUpUnlockedArrayCloud[i] || powerUpUnlockedArray![i] != powerUpUnlockedArrayCloud[i] {
                    powerUpUnlockedArray![i] = true
                } else {
                    powerUpUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].powerUpUnlockedArray = powerUpUnlockedArray!
        
        achievementsUnlockedArray = totalStatsArray[0].achievementsUnlockedArray
        if let achievementsUnlockedArrayCloud = iCloudStore.array(forKey: "achievementsUnlockedArray") as? [Bool] {
            for i in 0..<min(achievementsUnlockedArray!.count, achievementsUnlockedArrayCloud.count) {
                if achievementsUnlockedArrayCloud[i] || achievementsUnlockedArray![i] != achievementsUnlockedArrayCloud[i] {
                    achievementsUnlockedArray![i] = true
                } else {
                    achievementsUnlockedArray![i] = false
                }
            }
        }
        totalStatsArray[0].achievementsUnlockedArray = achievementsUnlockedArray!

        packHighScores = totalStatsArray[0].packHighScores
        if let packHighScoresCloud = iCloudStore.array(forKey: "packHighScores") as? [Int] {
            for i in 0..<min(packHighScoresCloud.count, packHighScores!.count) {
                if packHighScoresCloud[i] > packHighScores![i] {
                    packHighScores![i] = packHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].packHighScores = packHighScores!
        
        packBestTimes = totalStatsArray[0].packBestTimes
        if let packBestTimesCloud = iCloudStore.array(forKey: "packBestTimes") as? [Int] {
            for i in 0..<min(packBestTimesCloud.count, packBestTimes!.count) {
                if packBestTimesCloud[i] > packBestTimes![i] {
                    packBestTimes![i] = packBestTimesCloud[i]
                }
            }
        }
        totalStatsArray[0].packBestTimes = packBestTimes!
        
        pack1LevelHighScores = totalStatsArray[0].pack1LevelHighScores
        if let pack1LevelHighScoresCloud = iCloudStore.array(forKey: "pack1LevelHighScores") as? [Int] {
            for i in 0..<min(pack1LevelHighScoresCloud.count, pack1LevelHighScores!.count) {
                if pack1LevelHighScoresCloud[i] > pack1LevelHighScores![i] {
                    pack1LevelHighScores![i] = pack1LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack1LevelHighScores = pack1LevelHighScores!
        
        pack2LevelHighScores = totalStatsArray[0].pack2LevelHighScores
        if let pack2LevelHighScoresCloud = iCloudStore.array(forKey: "pack2LevelHighScores") as? [Int] {
            for i in 0..<min(pack2LevelHighScoresCloud.count, pack2LevelHighScores!.count) {
                if pack2LevelHighScoresCloud[i] > pack2LevelHighScores![i] {
                    pack2LevelHighScores![i] = pack2LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack2LevelHighScores = pack2LevelHighScores!
        
        pack3LevelHighScores = totalStatsArray[0].pack3LevelHighScores
        if let pack3LevelHighScoresCloud = iCloudStore.array(forKey: "pack3LevelHighScores") as? [Int] {
            for i in 0..<min(pack3LevelHighScoresCloud.count, pack3LevelHighScores!.count) {
                if pack3LevelHighScoresCloud[i] > pack3LevelHighScores![i] {
                    pack3LevelHighScores![i] = pack3LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack3LevelHighScores = pack3LevelHighScores!
        
        pack4LevelHighScores = totalStatsArray[0].pack4LevelHighScores
        if let pack4LevelHighScoresCloud = iCloudStore.array(forKey: "pack4LevelHighScores") as? [Int] {
            for i in 0..<min(pack4LevelHighScoresCloud.count, pack4LevelHighScores!.count) {
                if pack4LevelHighScoresCloud[i] > pack4LevelHighScores![i] {
                    pack4LevelHighScores![i] = pack4LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack4LevelHighScores = pack4LevelHighScores!
        
        pack5LevelHighScores = totalStatsArray[0].pack5LevelHighScores
        if let pack5LevelHighScoresCloud = iCloudStore.array(forKey: "pack5LevelHighScores") as? [Int] {
            for i in 0..<min(pack5LevelHighScoresCloud.count, pack5LevelHighScores!.count) {
                if pack5LevelHighScoresCloud[i] > pack5LevelHighScores![i] {
                    pack5LevelHighScores![i] = pack5LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack5LevelHighScores = pack5LevelHighScores!
        
        pack6LevelHighScores = totalStatsArray[0].pack6LevelHighScores
        if let pack6LevelHighScoresCloud = iCloudStore.array(forKey: "pack6LevelHighScores") as? [Int] {
            for i in 0..<min(pack6LevelHighScoresCloud.count, pack6LevelHighScores!.count) {
                if pack6LevelHighScoresCloud[i] > pack6LevelHighScores![i] {
                    pack6LevelHighScores![i] = pack6LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack6LevelHighScores = pack6LevelHighScores!
        
        pack7LevelHighScores = totalStatsArray[0].pack7LevelHighScores
        if let pack7LevelHighScoresCloud = iCloudStore.array(forKey: "pack7LevelHighScores") as? [Int] {
            for i in 0..<min(pack7LevelHighScoresCloud.count, pack7LevelHighScores!.count) {
                if pack7LevelHighScoresCloud[i] > pack7LevelHighScores![i] {
                    pack7LevelHighScores![i] = pack7LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack7LevelHighScores = pack7LevelHighScores!
        
        pack8LevelHighScores = totalStatsArray[0].pack8LevelHighScores
        if let pack8LevelHighScoresCloud = iCloudStore.array(forKey: "pack8LevelHighScores") as? [Int] {
            for i in 0..<min(pack8LevelHighScoresCloud.count, pack8LevelHighScores!.count) {
                if pack8LevelHighScoresCloud[i] > pack8LevelHighScores![i] {
                    pack8LevelHighScores![i] = pack8LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack8LevelHighScores = pack8LevelHighScores!
        
        pack9LevelHighScores = totalStatsArray[0].pack9LevelHighScores
        if let pack9LevelHighScoresCloud = iCloudStore.array(forKey: "pack9LevelHighScores") as? [Int] {
            for i in 0..<min(pack9LevelHighScoresCloud.count, pack9LevelHighScores!.count) {
                if pack9LevelHighScoresCloud[i] > pack9LevelHighScores![i] {
                    pack9LevelHighScores![i] = pack9LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack9LevelHighScores = pack9LevelHighScores!
        
        pack10LevelHighScores = totalStatsArray[0].pack10LevelHighScores
        if let pack10LevelHighScoresCloud = iCloudStore.array(forKey: "pack10LevelHighScores") as? [Int] {
            for i in 0..<min(pack10LevelHighScoresCloud.count, pack10LevelHighScores!.count) {
                if pack10LevelHighScoresCloud[i] > pack10LevelHighScores![i] {
                    pack10LevelHighScores![i] = pack10LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack10LevelHighScores = pack10LevelHighScores!
        
        pack11LevelHighScores = totalStatsArray[0].pack11LevelHighScores
        if let pack11LevelHighScoresCloud = iCloudStore.array(forKey: "pack11LevelHighScores") as? [Int] {
            for i in 0..<min(pack11LevelHighScoresCloud.count, pack11LevelHighScores!.count) {
                if pack11LevelHighScoresCloud[i] > pack11LevelHighScores![i] {
                    pack11LevelHighScores![i] = pack11LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack11LevelHighScores = pack11LevelHighScores!
        
        saveLocalData()
    }
    
    func loadLocalData() {
        let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        
        if totalStatsArray.count == 0 {
            let totalStatsItem = TotalStats()
            totalStatsArray = Array(repeating: totalStatsItem, count: 1)
            totalStatsArray[0].dateSaved = Date()
            do {
                let data = try encoder.encode(totalStatsArray)
                try data.write(to: totalStatsStore!)
            } catch {
                Log.data.error("Error setting up total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        // Fill the empty array with 0s on first opening after app deleted and re-installed and don't save to allow icloud data to fill in
    }
    
    func saveLocalData() {
        let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
        // Save total stats changes
    }
    
    func saveDataReset () {
        loadLocalData()

        // Mark this state as superseding whatever is in iCloud. Without it the
        // zeros written below are just small numbers, and the next device to
        // sync merges its own larger ones back over them.
        //
        // This happens whether or not syncing is on. A player who resets with
        // iCloud off and turns it on later would otherwise still be at
        // generation zero, and the stats they cleared would flow straight back
        // down on the first sync.
        let iCloudStore = NSUbiquitousKeyValueStore.default
        let generation = StatsSync.generationAfterReset(
            localGeneration: defaults.integer(forKey: StatsSync.generationKey),
            cloudGeneration: Int(iCloudStore.longLong(forKey: StatsSync.generationKey)))
        defaults.set(generation, forKey: StatsSync.generationKey)

        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting {
            return
        }

        pushLocalDataWholesale()
        loadDataReset()
    }

    /// Writes local stats over iCloud without merging, so values that went
    /// down are not treated as losing to the larger ones already there.
    ///
    /// Assumes the caller has already run loadLocalData() and confirmed
    /// iCloudSetting, as the two sync paths do.
    func pushLocalDataWholesale() {
        let iCloudStore = NSUbiquitousKeyValueStore.default

        appOpenCount = defaults.integer(forKey: "appOpenCount")
        firstPause = defaults.bool(forKey: "firstPause")
        
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
        
        iCloudStore.set(appOpenCount, forKey: "appOpenCount")
        iCloudStore.set(firstPause, forKey: "firstPause")
        
        iCloudStore.set(dateSaved, forKey: "dateSaved")
        iCloudStore.set(cumulativeScore, forKey: "cumulativeScore")
        iCloudStore.set(levelsPlayed, forKey: "levelsPlayed")
        iCloudStore.set(levelsCompleted, forKey: "levelsCompleted")
        iCloudStore.set(ballHits, forKey: "ballHits")
        iCloudStore.set(ballsLost, forKey: "ballsLost")
        iCloudStore.set(powerupsCollected, forKey: "powerupsCollected")
        iCloudStore.set(powerupsGenerated, forKey: "powerupsGenerated")
        iCloudStore.set(bricksHit, forKey: "bricksHit")
        iCloudStore.set(bricksDestroyed, forKey: "bricksDestroyed")
        iCloudStore.set(lasersFired, forKey: "lasersFired")
        iCloudStore.set(lasersHit, forKey: "lasersHit")
        iCloudStore.set(playTimeSecs, forKey: "playTimeSecs")
        iCloudStore.set(packsPlayed, forKey: "packsPlayed")
        iCloudStore.set(packsCompleted, forKey: "packsCompleted")
        iCloudStore.set(endlessModeHeight, forKey: "endlessModeHeight")
        iCloudStore.set(endlessModeHeightDate, forKey: "endlessModeHeightDate")
        iCloudStore.set(levelPackUnlockedArray, forKey: "levelPackUnlockedArray")
        iCloudStore.set(themeUnlockedArray, forKey: "themeUnlockedArray")
        iCloudStore.set(appIconUnlockedArray, forKey: "appIconUnlockedArray")
        iCloudStore.set(levelUnlockedArray, forKey: "levelUnlockedArray")
        iCloudStore.set(powerUpUnlockedArray, forKey: "powerUpUnlockedArray")
        iCloudStore.set(achievementsUnlockedArray, forKey: "achievementsUnlockedArray")
        iCloudStore.set(achievementsPercentageCompleteArray, forKey: "achievementsPercentageCompleteArray")
        iCloudStore.set(achievementDates, forKey: "achievementDates")
        iCloudStore.set(packHighScores, forKey: "packHighScores")
        iCloudStore.set(packBestTimes, forKey: "packBestTimes")
        iCloudStore.set(pack1LevelHighScores, forKey: "pack1LevelHighScores")
        iCloudStore.set(pack2LevelHighScores, forKey: "pack2LevelHighScores")
        iCloudStore.set(pack3LevelHighScores, forKey: "pack3LevelHighScores")
        iCloudStore.set(pack4LevelHighScores, forKey: "pack4LevelHighScores")
        iCloudStore.set(pack5LevelHighScores, forKey: "pack5LevelHighScores")
        iCloudStore.set(pack6LevelHighScores, forKey: "pack6LevelHighScores")
        iCloudStore.set(pack7LevelHighScores, forKey: "pack7LevelHighScores")
        iCloudStore.set(pack8LevelHighScores, forKey: "pack8LevelHighScores")
        iCloudStore.set(pack9LevelHighScores, forKey: "pack9LevelHighScores")
        iCloudStore.set(pack10LevelHighScores, forKey: "pack10LevelHighScores")
        iCloudStore.set(pack11LevelHighScores, forKey: "pack11LevelHighScores")

        if let encodedDaily = CloudKitHandler.encodedDailyRecords(totalStatsArray[0].dailyRecords) {
            iCloudStore.set(encodedDaily, forKey: "dailyChallengeRecords")
        }
        // Wholesale means the daily records too: a reset clears the daily history with
        // the rest, and merging the cloud's old records back would resurrect it

        // iCloud now holds this device's state, so it holds its generation too.
        // Leaving the cloud behind would make every later sync push wholesale
        // again and never merge another device's play.
        iCloudStore.set(Int64(defaults.integer(forKey: StatsSync.generationKey)),
                        forKey: StatsSync.generationKey)

        iCloudStore.synchronize()
    }

    func loadDataReset() {
        
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting {
            return
        }
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        appOpenCount = Int(iCloudStore.longLong(forKey: "appOpenCount"))
        firstPause = iCloudStore.bool(forKey: "firstPause")
        
        dateSaved = iCloudStore.object(forKey: "dateSaved") as? Date
        cumulativeScore = Int(iCloudStore.longLong(forKey: "cumulativeScore"))
        levelsPlayed = Int(iCloudStore.longLong(forKey: "levelsPlayed"))
        levelsCompleted = Int(iCloudStore.longLong(forKey: "levelsCompleted"))
        ballHits = Int(iCloudStore.longLong(forKey: "ballHits"))
        ballsLost = Int(iCloudStore.longLong(forKey: "ballsLost"))
        powerupsCollected = iCloudStore.array(forKey: "powerupsCollected") as? [Int]
        powerupsGenerated = iCloudStore.array(forKey: "powerupsGenerated") as? [Int]
        bricksHit = iCloudStore.array(forKey: "bricksHit") as? [Int]
        bricksDestroyed = iCloudStore.array(forKey: "bricksDestroyed") as? [Int]
        lasersFired = Int(iCloudStore.longLong(forKey: "lasersFired"))
        lasersHit = Int(iCloudStore.longLong(forKey: "lasersHit"))
        playTimeSecs = Int(iCloudStore.longLong(forKey: "playTimeSecs"))
        packsPlayed = Int(iCloudStore.longLong(forKey: "packsPlayed"))
        packsCompleted = Int(iCloudStore.longLong(forKey: "packsCompleted"))
        endlessModeHeight = iCloudStore.array(forKey: "endlessModeHeight") as? [Int]
        endlessModeHeightDate = iCloudStore.array(forKey: "endlessModeHeightDate") as? [Date]
        levelPackUnlockedArray = iCloudStore.array(forKey: "levelPackUnlockedArray") as? [Bool]
        themeUnlockedArray = iCloudStore.array(forKey: "themeUnlockedArray") as? [Bool]
        appIconUnlockedArray = iCloudStore.array(forKey: "appIconUnlockedArray") as? [Bool]
        levelUnlockedArray = iCloudStore.array(forKey: "levelUnlockedArray") as? [Bool]
        powerUpUnlockedArray = iCloudStore.array(forKey: "powerUpUnlockedArray") as? [Bool]
        achievementsUnlockedArray = iCloudStore.array(forKey: "achievementsUnlockedArray") as? [Bool]
        achievementsPercentageCompleteArray = iCloudStore.array(forKey: "achievementsPercentageCompleteArray") as? [String]
        achievementDates = iCloudStore.array(forKey: "achievementDates") as? [Date]
        packHighScores = iCloudStore.array(forKey: "packHighScores") as? [Int]
        packBestTimes = iCloudStore.array(forKey: "packBestTimes") as? [Int]
        pack1LevelHighScores = iCloudStore.array(forKey: "pack1LevelHighScores") as? [Int]
        pack2LevelHighScores = iCloudStore.array(forKey: "pack2LevelHighScores") as? [Int]
        pack3LevelHighScores = iCloudStore.array(forKey: "pack3LevelHighScores") as? [Int]
        pack4LevelHighScores = iCloudStore.array(forKey: "pack4LevelHighScores") as? [Int]
        pack5LevelHighScores = iCloudStore.array(forKey: "pack5LevelHighScores") as? [Int]
        pack6LevelHighScores = iCloudStore.array(forKey: "pack6LevelHighScores") as? [Int]
        pack7LevelHighScores = iCloudStore.array(forKey: "pack7LevelHighScores") as? [Int]
        pack8LevelHighScores = iCloudStore.array(forKey: "pack8LevelHighScores") as? [Int]
        pack9LevelHighScores = iCloudStore.array(forKey: "pack9LevelHighScores") as? [Int]
        pack10LevelHighScores = iCloudStore.array(forKey: "pack10LevelHighScores") as? [Int]
        pack11LevelHighScores = iCloudStore.array(forKey: "pack11LevelHighScores") as? [Int]
        
        self.defaults.set(self.appOpenCount, forKey: "appOpenCount")
        self.defaults.set(self.firstPause, forKey: "firstPause")
        
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

        totalStatsArray[0].dailyChallengeRecords =
            CloudKitHandler.decodedDailyRecords(iCloudStore.data(forKey: "dailyChallengeRecords"))
        // Adopting a reset adopts its daily history too, lower or absent as it may be

        // Having taken the cloud state whole, this device is caught up. Without
        // recording that, every later sync would adopt it again and discard
        // anything played since.
        defaults.set(Int(iCloudStore.longLong(forKey: StatsSync.generationKey)),
                     forKey: StatsSync.generationKey)

        saveLocalData()
    }
}
