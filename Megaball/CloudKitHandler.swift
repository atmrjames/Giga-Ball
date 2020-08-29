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
    // NSCoder data store & encoder setup
    
    let defaults = UserDefaults.standard
    // User settings
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var appOpenCount: Int?
    var resumeGameToLoad: Bool?
    var firstPause: Bool?
    
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
    
    func isiCloudContainerAvailable() {
        CKContainer.default().accountStatus { (accountStatus, error) in
            if case .available = accountStatus {
                self.iCloudSetting = true
                self.defaults.set(self.iCloudSetting!, forKey: "iCloudSetting")
            } else {
                self.iCloudSetting = false
                self.defaults.set(self.iCloudSetting!, forKey: "iCloudSetting")
            }
        }
    }
    
    func saveToiCloud() {
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if iCloudSetting! {
            updateToiCloud()
        }
    }
    
    func updateToiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        let premiumSettingCloud = iCloudStore.bool(forKey: "premiumSetting")
        if premiumSetting! || premiumSetting! != premiumSettingCloud {
            iCloudStore.set(true, forKey: "premiumSetting")
        } else {
            iCloudStore.set(false, forKey: "premiumSetting")
        }
        
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        let appOpenCountCloud = Int(iCloudStore.longLong(forKey: "appOpenCount"))
        if appOpenCount! > appOpenCountCloud {
            iCloudStore.set(appOpenCount, forKey: "appOpenCount")
        }
        
        firstPause = defaults.bool(forKey: "firstPause")
        let firstPauseCloud = iCloudStore.bool(forKey: "firstPause")
        if firstPause! == false || firstPause! != firstPauseCloud {
            iCloudStore.set(false, forKey: "firstPause")
        } else {
            iCloudStore.set(true, forKey: "firstPause")
        }
        
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
            for i in 0..<powerupsCollected!.count {
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
            for i in 0..<powerupsGenerated!.count {
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
            for i in 0..<bricksHit!.count {
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
            for i in 0..<bricksDestroyed!.count {
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
            for i in 0..<levelPackUnlockedArray!.count {
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
            for i in 0..<themeUnlockedArray!.count {
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
            for i in 0..<appIconUnlockedArray!.count {
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
            for i in 0..<levelUnlockedArray!.count {
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
            for i in 0..<powerUpUnlockedArray!.count {
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
            for i in 0..<achievementsUnlockedArray!.count {
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
            var achievementDatesCloud = iCloudStore.array(forKey: "achievementDates") as? [Date]
            for i in 0..<achievementsPercentageCompleteArray!.count {
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
            for i in 0..<packHighScores!.count {
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
            for i in 0..<packBestTimes!.count {
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
            for i in 0..<pack1LevelHighScores!.count {
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
            for i in 0..<pack2LevelHighScores!.count {
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
            for i in 0..<pack3LevelHighScores!.count {
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
            for i in 0..<pack4LevelHighScores!.count {
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
            for i in 0..<pack5LevelHighScores!.count {
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
            for i in 0..<pack6LevelHighScores!.count {
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
            for i in 0..<pack7LevelHighScores!.count {
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
            for i in 0..<pack8LevelHighScores!.count {
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
            for i in 0..<pack9LevelHighScores!.count {
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
            for i in 0..<pack10LevelHighScores!.count {
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
            for i in 0..<pack11LevelHighScores!.count {
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
        if iCloudSetting! {
            updateFromiCloud()
        }
    }
    
    func updateFromiCloud() {
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        premiumSetting = defaults.bool(forKey: "premiumSetting")
        let premiumSettingCloud = iCloudStore.bool(forKey: "premiumSetting")
        if premiumSetting! || premiumSetting! != premiumSettingCloud {
            premiumSetting = true
        } else {
            premiumSetting = false
        }
        if self.premiumSetting != nil {
            adsSetting = !premiumSetting!
            self.defaults.set(self.premiumSetting!, forKey: "premiumSetting")
            self.defaults.set(self.adsSetting!, forKey: "adsSetting")
        }
        
        appOpenCount = defaults.integer(forKey: "appOpenCount")
        let appOpenCountCloud = Int(iCloudStore.longLong(forKey: "appOpenCount"))
        if appOpenCountCloud > appOpenCount! {
            self.defaults.set(appOpenCountCloud, forKey: "appOpenCount")
        }
        
        firstPause = defaults.bool(forKey: "firstPause")
        let firstPauseCloud = iCloudStore.bool(forKey: "firstPause")
        if firstPause! == false || firstPause! != firstPauseCloud {
            firstPause = false
        } else {
            firstPause = true
        }
        if self.firstPause != nil {
            self.defaults.set(self.firstPause!, forKey: "firstPause")
        }
        
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
            for i in 0..<powerupsCollectedCloud.count {
                if powerupsCollectedCloud[i] > powerupsCollected![i] {
                    powerupsCollected![i] = powerupsCollectedCloud[i]
                }
            }
        }
        totalStatsArray[0].powerupsCollected = powerupsCollected!
        
        powerupsGenerated = totalStatsArray[0].powerupsGenerated
        if let powerupsGeneratedCloud = iCloudStore.array(forKey: "powerupsGenerated") as? [Int] {
            for i in 0..<powerupsGeneratedCloud.count {
                if powerupsGeneratedCloud[i] > powerupsGenerated![i] {
                    powerupsGenerated![i] = powerupsGeneratedCloud[i]
                }
            }
        }
        totalStatsArray[0].powerupsGenerated = powerupsGenerated!
        
        bricksHit = totalStatsArray[0].bricksHit
        if let bricksHitCloud = iCloudStore.array(forKey: "bricksHit") as? [Int] {
            for i in 0..<bricksHitCloud.count {
                if bricksHitCloud[i] > bricksHit![i] {
                    bricksHit![i] = bricksHitCloud[i]
                }
            }
        }
        totalStatsArray[0].bricksHit = bricksHit!
        
        bricksDestroyed = totalStatsArray[0].bricksDestroyed
        if let bricksDestroyedCloud = iCloudStore.array(forKey: "bricksDestroyed") as? [Int] {
            for i in 0..<bricksDestroyedCloud.count {
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
            for i in 0..<levelPackUnlockedArray!.count {
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
            for i in 0..<themeUnlockedArray!.count {
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
            for i in 0..<appIconUnlockedArray!.count {
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
            for i in 0..<levelUnlockedArray!.count {
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
            for i in 0..<powerUpUnlockedArray!.count {
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
            for i in 0..<achievementsUnlockedArray!.count {
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
            for i in 0..<packHighScoresCloud.count {
                if packHighScoresCloud[i] > packHighScores![i] {
                    packHighScores![i] = packHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].packHighScores = packHighScores!
        
        packBestTimes = totalStatsArray[0].packBestTimes
        if let packBestTimesCloud = iCloudStore.array(forKey: "packBestTimes") as? [Int] {
            for i in 0..<packBestTimesCloud.count {
                if packBestTimesCloud[i] > packBestTimes![i] {
                    packBestTimes![i] = packBestTimesCloud[i]
                }
            }
        }
        totalStatsArray[0].packBestTimes = packBestTimes!
        
        pack1LevelHighScores = totalStatsArray[0].pack1LevelHighScores
        if let pack1LevelHighScoresCloud = iCloudStore.array(forKey: "pack1LevelHighScores") as? [Int] {
            for i in 0..<pack1LevelHighScoresCloud.count {
                if pack1LevelHighScoresCloud[i] > pack1LevelHighScores![i] {
                    pack1LevelHighScores![i] = pack1LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack1LevelHighScores = pack1LevelHighScores!
        
        pack2LevelHighScores = totalStatsArray[0].pack2LevelHighScores
        if let pack2LevelHighScoresCloud = iCloudStore.array(forKey: "pack2LevelHighScores") as? [Int] {
            for i in 0..<pack2LevelHighScoresCloud.count {
                if pack2LevelHighScoresCloud[i] > pack2LevelHighScores![i] {
                    pack2LevelHighScores![i] = pack2LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack2LevelHighScores = pack2LevelHighScores!
        
        pack3LevelHighScores = totalStatsArray[0].pack3LevelHighScores
        if let pack3LevelHighScoresCloud = iCloudStore.array(forKey: "pack3LevelHighScores") as? [Int] {
            for i in 0..<pack3LevelHighScoresCloud.count {
                if pack3LevelHighScoresCloud[i] > pack3LevelHighScores![i] {
                    pack3LevelHighScores![i] = pack3LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack3LevelHighScores = pack3LevelHighScores!
        
        pack4LevelHighScores = totalStatsArray[0].pack4LevelHighScores
        if let pack4LevelHighScoresCloud = iCloudStore.array(forKey: "pack4LevelHighScores") as? [Int] {
            for i in 0..<pack4LevelHighScoresCloud.count {
                if pack4LevelHighScoresCloud[i] > pack4LevelHighScores![i] {
                    pack4LevelHighScores![i] = pack4LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack4LevelHighScores = pack4LevelHighScores!
        
        pack5LevelHighScores = totalStatsArray[0].pack5LevelHighScores
        if let pack5LevelHighScoresCloud = iCloudStore.array(forKey: "pack5LevelHighScores") as? [Int] {
            for i in 0..<pack5LevelHighScoresCloud.count {
                if pack5LevelHighScoresCloud[i] > pack5LevelHighScores![i] {
                    pack5LevelHighScores![i] = pack5LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack5LevelHighScores = pack5LevelHighScores!
        
        pack6LevelHighScores = totalStatsArray[0].pack6LevelHighScores
        if let pack6LevelHighScoresCloud = iCloudStore.array(forKey: "pack6LevelHighScores") as? [Int] {
            for i in 0..<pack6LevelHighScoresCloud.count {
                if pack6LevelHighScoresCloud[i] > pack6LevelHighScores![i] {
                    pack6LevelHighScores![i] = pack6LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack6LevelHighScores = pack6LevelHighScores!
        
        pack7LevelHighScores = totalStatsArray[0].pack7LevelHighScores
        if let pack7LevelHighScoresCloud = iCloudStore.array(forKey: "pack7LevelHighScores") as? [Int] {
            for i in 0..<pack7LevelHighScoresCloud.count {
                if pack7LevelHighScoresCloud[i] > pack7LevelHighScores![i] {
                    pack7LevelHighScores![i] = pack7LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack7LevelHighScores = pack7LevelHighScores!
        
        pack8LevelHighScores = totalStatsArray[0].pack8LevelHighScores
        if let pack8LevelHighScoresCloud = iCloudStore.array(forKey: "pack8LevelHighScores") as? [Int] {
            for i in 0..<pack8LevelHighScoresCloud.count {
                if pack8LevelHighScoresCloud[i] > pack8LevelHighScores![i] {
                    pack8LevelHighScores![i] = pack8LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack8LevelHighScores = pack8LevelHighScores!
        
        pack9LevelHighScores = totalStatsArray[0].pack9LevelHighScores
        if let pack9LevelHighScoresCloud = iCloudStore.array(forKey: "pack9LevelHighScores") as? [Int] {
            for i in 0..<pack9LevelHighScoresCloud.count {
                if pack9LevelHighScoresCloud[i] > pack9LevelHighScores![i] {
                    pack9LevelHighScores![i] = pack9LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack9LevelHighScores = pack9LevelHighScores!
        
        pack10LevelHighScores = totalStatsArray[0].pack10LevelHighScores
        if let pack10LevelHighScoresCloud = iCloudStore.array(forKey: "pack10LevelHighScores") as? [Int] {
            for i in 0..<pack10LevelHighScoresCloud.count {
                if pack10LevelHighScoresCloud[i] > pack10LevelHighScores![i] {
                    pack10LevelHighScores![i] = pack10LevelHighScoresCloud[i]
                }
            }
        }
        totalStatsArray[0].pack10LevelHighScores = pack10LevelHighScores!
        
        pack11LevelHighScores = totalStatsArray[0].pack11LevelHighScores
        if let pack11LevelHighScoresCloud = iCloudStore.array(forKey: "pack11LevelHighScores") as? [Int] {
            for i in 0..<pack11LevelHighScoresCloud.count {
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
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                print("Error decoding total stats array, \(error)")
            }
        }
    }
    
    func saveLocalData() {
        let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
        do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
        // Save total stats changes
    }
    
    func saveDataReset () {
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            return
        }
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        premiumSetting = defaults.bool(forKey: "premiumSetting")
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
        
        iCloudStore.set(premiumSetting, forKey: "premiumSetting")
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
        
        iCloudStore.synchronize()
        loadDataReset()
    }

    func loadDataReset() {
        
        loadLocalData()
        isiCloudContainerAvailable()
        iCloudSetting = defaults.bool(forKey: "iCloudSetting")
        if !iCloudSetting! {
            return
        }
        let iCloudStore = NSUbiquitousKeyValueStore.default
        
        premiumSetting = iCloudStore.bool(forKey: "premiumSetting")
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
        
        if self.premiumSetting != nil {
            adsSetting = !premiumSetting!
            self.defaults.set(self.premiumSetting!, forKey: "premiumSetting")
            self.defaults.set(self.adsSetting!, forKey: "adsSetting")
        }
        if self.appOpenCount != nil {
            self.defaults.set(self.appOpenCount!, forKey: "appOpenCount")
        }
        if self.firstPause != nil {
            self.defaults.set(self.firstPause!, forKey: "firstPause")
        }
        
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

        saveLocalData()
    }
}
