//
//  GameCenterHandler.swift
//  Megaball
//
//  Created by James Harding on 24/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//a

import GameKit

final class GameCenterHandler: NSObject {
    typealias CompletionBlock = (Error?) -> Void
    
    static let helper = GameCenterHandler()
    static var isAuthenticated: Bool {
        return GKLocalPlayer.local.isAuthenticated
    }
    var viewController: UIViewController?
    
    override init() {
        
        super.init()
        GKLocalPlayer.local.authenticateHandler = { gcAuthVC, error in
            NotificationCenter.default.post(name: .authenticationChanged, object: GKLocalPlayer.local.isAuthenticated)
            
            if GKLocalPlayer.local.isAuthenticated {
                print("Authenticated to Game Center!")
            } else if let vc = gcAuthVC {
                self.viewController?.present(vc, animated: true)
            }
            else {
                print("Error authentication to GameCenter: " + "\(error?.localizedDescription ?? "none")")
            }
        }
    }
    
    let defaults = UserDefaults.standard
    var premiumSetting: Bool?
    var adsSetting: Bool?
    var soundsSetting: Bool?
    var musicSetting: Bool?
    var hapticsSetting: Bool?
    var parallaxSetting: Bool?
    var paddleSensitivitySetting: Int?
    var gameCenterSetting: Bool?
    var ballSetting: Int?
    var paddleSetting: Int?
    var brickSetting: Int?
    var appIconSetting: Int?
    var statsCollapseSetting: Bool?
    var swipeUpPause: Bool?
    var appOpenCount: Int?
    var gameInProgress: Bool?
    // User settings
    var saveGameSaveArray: [Int]?
    var saveMultiplier: Double?
    var saveBrickTextureArray: [Int]?
    var saveBrickColourArray: [Int]?
    var saveBrickXPositionArray: [Int]?
    var saveBrickYPositionArray: [Int]?
    var saveBallPropertiesArray: [Double]?
    var savePowerUpFallingXPositionArray: [Int]?
    var savePowerUpFallingYPositionArray: [Int]?
    var savePowerUpFallingArray: [Int]?
    var savePowerUpActiveArray: [String]?
    var savePowerUpActiveDurationArray: [Double]?
    var savePowerUpActiveTimerArray: [Double]?
    var savePowerUpActiveMagnitudeArray: [Int]?

    // Game save settings
    let userDefaultsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("userDefaultsStore.plist")
    // User defaults
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
//    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
//    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
//    var packStatsArray: [PackStats] = []
//    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
    var cloudTotalStore: Data?
    var cloudPackStore: Data?
    var cloudLevelStore: Data?
    var cloudUserDefaultsStore: Data?
        
    let localPlayer = GKLocalPlayer.local
    
    func gameCenterSave() {
        print("llama GC save")
        loadData()
        
        let totalScoreReporter = GKScore(leaderboardIdentifier: "leaderboardTotalScore")
        totalScoreReporter.value = Int64(totalStatsArray[0].cumulativeScore)
        let totalScoreArray: [GKScore] = [totalScoreReporter]
        GKScore.report(totalScoreArray, withCompletionHandler: nil)
        // Leaderboard Total Score
        
        if totalStatsArray[0].endlessModeHeight.count > 0 {
            let endlessBestReporter = GKScore(leaderboardIdentifier: "leaderboardBestHeight")
            endlessBestReporter.value = Int64(totalStatsArray[0].endlessModeHeight.max()!)
            let endlessBestArray: [GKScore] = [endlessBestReporter]
            GKScore.report(endlessBestArray, withCompletionHandler: nil)
        }
        // Leaderboard Endless Best Height
        
        if totalStatsArray[0].endlessModeHeight.count > 0 {
            let endlessTotalReporter = GKScore(leaderboardIdentifier: "leaderboardTotalHeight")
            endlessTotalReporter.value = Int64(totalStatsArray[0].endlessModeHeight.reduce(0, +))
            let endlessTotalArray: [GKScore] = [endlessTotalReporter]
            GKScore.report(endlessTotalArray, withCompletionHandler: nil)
        }
        // Leaderboard Endless Total Height
        // Endless mode leaderboards
        
        var arrayIndex = 0
        let leaderboardIdentifierArray = ["leaderboardClassicPackScore", "leaderboardSpacePackScore", "leaderboardNaturePackScore", "leaderboardUrbanPackScore", "leaderboardFoodPackScore", "leaderboardComputerPackScore", "leaderboardBodyPackScore", "leaderboardWorldPackScore", "leaderboardEmojiPackScore", "leaderboardNumbersPackScore", "leaderboardChallengePackScore"]
        while arrayIndex <= 10 {
            if totalStatsArray[0].packHighScores[arrayIndex] > 0 {
//            if packStatsArray[arrayIndex+2].scores.count > 0 {
                let scoreReporter = GKScore(leaderboardIdentifier: leaderboardIdentifierArray[arrayIndex])
                scoreReporter.value = Int64(totalStatsArray[0].packHighScores[arrayIndex])
                let scoreArray: [GKScore] = [scoreReporter]
                GKScore.report(scoreArray, withCompletionHandler: nil)
            }
            arrayIndex+=1
        }
        // Level pack total leaderboards
    }
    
    func loadData() {
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
    
//    func saveCloudData() {
//
//        print("llama llama saveCloudData")
//
//        if let totalData = try? Data(contentsOf: totalStatsStore!) {
//            localPlayer.saveGameData(totalData, withName: "totalStatsCloudSave") { (GKSavedGame, error) -> Void in
//                if error != nil {
//                    print("Save cloud data error, totalStats \(error?.localizedDescription ?? "Error reporting save cloud data, totalStats")")
//                } else {
//                    print("Llama llama: Saved cloud data, totalStats: ", GKSavedGame!.name!, GKSavedGame!.deviceName!, GKSavedGame!.modificationDate!)
//                }
//            }
//        }
//        // Save total stats to iCloud
//
//        if let packData = try? Data(contentsOf: packStatsStore!) {
//            localPlayer.saveGameData(packData, withName: "packStatsCloudSave") { (GKSavedGame, error) -> Void in
//                if error != nil {
//                    print("Save cloud data error, packStats \(error?.localizedDescription ?? "Error reporting save cloud data, packStats")")
//                } else {
//                    print("Llama llama: Saved cloud data, packStats: ", GKSavedGame!.name!, GKSavedGame!.deviceName!, GKSavedGame!.modificationDate!)
//                }
//            }
//        }
//        // Save pack stats to iCloud
//
//        if let levelData = try? Data(contentsOf: levelStatsStore!) {
//            localPlayer.saveGameData(levelData, withName: "levelStatsCloudSave") { (GKSavedGame, error) -> Void in
//                if error != nil {
//                    print("Save cloud data error, levelStats \(error?.localizedDescription ?? "Error reporting save cloud data, levelStats")")
//                } else {
//                    print("Llama llama: Saved cloud data, levelStats: ", GKSavedGame!.name!, GKSavedGame!.deviceName!, GKSavedGame!.modificationDate!)
//                }
//            }
//        }
//        // Save level stats to iCloud
//
//        syncUserDefaults()
//
//        if let userDefaultsData = try? Data(contentsOf: userDefaultsStore!) {
//            localPlayer.saveGameData(userDefaultsData, withName: "userDefaultsCloudSave") { (GKSavedGame, error) -> Void in
//                if error != nil {
//                    print("Save cloud data error, userDefaults \(error?.localizedDescription ?? "Error reporting save cloud data, userDefaults")")
//                } else {
//                    print("Llama llama: Saved cloud data, userDefaults: ", GKSavedGame!.name!, GKSavedGame!.deviceName!, GKSavedGame!.modificationDate!)
//                }
//            }
//        }
//        // Save level stats to iCloud
//    }
    
//    func fetchCloudData() {
//
//        print("llama llama fetchCloudData")
//
//        loadData()
//        let previousSavedDate = totalStatsArray[0].dateSaved
//        print("Llama llama totalStatsSaveDate: \(previousSavedDate)")
//
//        localPlayer.fetchSavedGames { (GKSavedGames, error) -> Void in
//            if error != nil {
//                print("Error finding saved games \(error?.localizedDescription ?? "Error reporting load cloud data")")
//            } else {
//                print("Llama llama found \(GKSavedGames!.count) saved games in the cloud")
//                for savedGame in GKSavedGames! {
//                    print("Llama llama saved game found: ", savedGame.name!, savedGame.deviceName!, savedGame.modificationDate!)
//                    print("llama llama date", Date())
//
//                    if previousSavedDate > savedGame.modificationDate! {
//                        print("Local data is more up to date than cloud data")
//                        self.saveCloudData()
//                        return
//                    }
//                    // Check data of iCloud data against device data and use the latest
//
//                    savedGame.loadData { (loadedData, error) -> Void in
//                        if error != nil {
//                            print("Error loading saved game: \(savedGame.name ?? "Error reporting saved game") \(error?.localizedDescription ?? "Error reporting loading saved game data")")
//                        }
//                        else {
//                            switch savedGame.name! {
//                                case "totalStatsCloudSave":
//                                    self.cloudTotalStore = loadedData
//                                    do {
//                                        try self.cloudTotalStore?.write(to: self.totalStatsStore!)
//                                        print("Total stats loaded from cloud and saved")
//                                    } catch {
//                                        print("Error saving cloud loaded totalStats, \(error)")
//                                    }
//                                case "packStatsCloudSave":
//                                    self.cloudPackStore = loadedData
//                                    do {
//                                        try self.cloudPackStore?.write(to: self.packStatsStore!)
//                                        print("Pack stats loaded from cloud and saved")
//                                    } catch {
//                                        print("Error saving cloud loaded packStats, \(error)")
//                                    }
//                                case "levelStatsCloudSave":
//                                    self.cloudLevelStore = loadedData
//                                    do {
//                                        try self.cloudLevelStore?.write(to: self.levelStatsStore!)
//                                        print("Level stats loaded from cloud and saved")
//                                    } catch {
//                                        print("Error saving cloud loaded levelStats, \(error)")
//                                    }
//                                case "userDefaultsCloudSave":
//                                    self.cloudUserDefaultsStore = loadedData
//                                    do {
//                                        try self.cloudUserDefaultsStore?.write(to: self.userDefaultsStore!)
//                                        print("userDefaults loaded from cloud and saved")
//                                    } catch {
//                                        print("Error saving cloud loaded userDefaults, \(error)")
//                                    }
//                                default:
//                                    print("default")
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    func deleteCloudData() {
//        print("llama llama deleteCloudData")
//        localPlayer.deleteSavedGames(withName: "totalStatsCloudSave") { (error) -> Void in
//            if error != nil {
//                print("Error deleting saved game, totalStats \(error?.localizedDescription ?? "Error reporting save cloud data, totalStats")")
//            } else {
//                print("TotalStats cloud data deleted")
//            }
//        }
//        localPlayer.deleteSavedGames(withName: "packStatsCloudSave") { (error) -> Void in
//            if error != nil {
//                print("Error deleting saved game, packStats \(error?.localizedDescription ?? "Error reporting save cloud data, packStats")")
//            } else {
//                print("PackStats cloud data deleted")
//            }
//        }
//        localPlayer.deleteSavedGames(withName: "levelStatsCloudSave") { (error) -> Void in
//            if error != nil {
//                print("Error deleting saved game, levelStats \(error?.localizedDescription ?? "Error reporting save cloud data, levelStats")")
//            } else {
//                print("LevelStats cloud data deleted")
//            }
//        }
//        localPlayer.deleteSavedGames(withName: "userDefaultsCloudSave") { (error) -> Void in
//            if error != nil {
//                print("Error deleting saved game, userDefaults \(error?.localizedDescription ?? "Error reporting save cloud data, userDefaults")")
//            } else {
//                print("userDefaults cloud data deleted")
//            }
//        }
//    }
    
//    func syncUserDefaults() {
//        userSettings()
//
//        UserDefaultsCloudSave().premiumSetting = premiumSetting
//        UserDefaultsCloudSave().adsSetting = adsSetting
//        UserDefaultsCloudSave().soundsSetting = soundsSetting
//        UserDefaultsCloudSave().musicSetting = musicSetting
//        UserDefaultsCloudSave().hapticsSetting = hapticsSetting
//        UserDefaultsCloudSave().parallaxSetting = parallaxSetting
//
//        UserDefaultsCloudSave().statsCollapseSetting = statsCollapseSetting
//        UserDefaultsCloudSave().swipeUpPause = swipeUpPause
//        UserDefaultsCloudSave().appOpenCount = appOpenCount
//
//        UserDefaultsCloudSave().saveGameSaveArray = saveGameSaveArray
//        UserDefaultsCloudSave().saveMultiplier = saveMultiplier
//        UserDefaultsCloudSave().saveBrickTextureArray = saveBrickTextureArray
//        UserDefaultsCloudSave().saveBrickColourArray = saveBrickColourArray
//        UserDefaultsCloudSave().saveBrickXPositionArray = saveBrickXPositionArray
//        UserDefaultsCloudSave().saveBrickYPositionArray = saveBrickYPositionArray
//        UserDefaultsCloudSave().saveBallPropertiesArray = saveBallPropertiesArray
//        UserDefaultsCloudSave().savePowerUpFallingXPositionArray = savePowerUpFallingXPositionArray
//        UserDefaultsCloudSave().savePowerUpFallingYPositionArray = savePowerUpFallingYPositionArray
//        UserDefaultsCloudSave().savePowerUpFallingArray = savePowerUpFallingArray
//        UserDefaultsCloudSave().savePowerUpActiveArray = savePowerUpActiveArray
//        UserDefaultsCloudSave().savePowerUpActiveDurationArray = savePowerUpActiveDurationArray
//        UserDefaultsCloudSave().savePowerUpActiveTimerArray = savePowerUpActiveTimerArray
//        UserDefaultsCloudSave().savePowerUpActiveMagnitudeArray = savePowerUpActiveMagnitudeArray
//    }
    // Sync UserDefaultsCloudSave with current UserDefaults ahead of save
    
//    func loadUserDefaults() {
//
//    }
    
//    func userSettings() {
//        premiumSetting = defaults.bool(forKey: "premiumSetting")
//        adsSetting = defaults.bool(forKey: "adsSetting")
//        soundsSetting = defaults.bool(forKey: "soundsSetting")
//        musicSetting = defaults.bool(forKey: "musicSetting")
//        hapticsSetting = defaults.bool(forKey: "hapticsSetting")
//        parallaxSetting = defaults.bool(forKey: "parallaxSetting")
//        paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
//        gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
//        ballSetting = defaults.integer(forKey: "ballSetting")
//        paddleSetting = defaults.integer(forKey: "paddleSetting")
//        brickSetting = defaults.integer(forKey: "brickSetting")
//        appIconSetting = defaults.integer(forKey: "appIconSetting")
//        statsCollapseSetting = defaults.bool(forKey: "statsCollapseSetting")
//        swipeUpPause = defaults.bool(forKey: "swipeUpPause")
//        appOpenCount = defaults.integer(forKey: "appOpenCount")
//        gameInProgress = defaults.bool(forKey: "gameInProgress")
//        // User settings
//
//        saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
//        saveMultiplier = defaults.double(forKey: "saveMultiplier")
//        saveBrickTextureArray = defaults.object(forKey: "saveBrickTextureArray") as! [Int]?
//        saveBrickColourArray = defaults.object(forKey: "saveBrickColourArray") as! [Int]?
//        saveBrickXPositionArray = defaults.object(forKey: "saveBrickXPositionArray") as! [Int]?
//        saveBrickYPositionArray = defaults.object(forKey: "saveBrickYPositionArray") as! [Int]?
//        saveBallPropertiesArray = defaults.object(forKey: "saveBallPropertiesArray") as! [Double]?
//        savePowerUpFallingXPositionArray = defaults.object(forKey: "savePowerUpFallingXPositionArray") as! [Int]?
//        savePowerUpFallingYPositionArray = defaults.object(forKey: "savePowerUpFallingYPositionArray") as! [Int]?
//        savePowerUpFallingArray = defaults.object(forKey: "savePowerUpFallingArray") as! [Int]?
//        savePowerUpActiveArray = defaults.object(forKey: "savePowerUpActiveArray") as! [String]?
//        savePowerUpActiveDurationArray = defaults.object(forKey: "savePowerUpActiveDurationArray") as! [Double]?
//        savePowerUpActiveTimerArray = defaults.object(forKey: "savePowerUpActiveTimerArray") as! [Double]?
//        savePowerUpActiveMagnitudeArray = defaults.object(forKey: "savePowerUpActiveMagnitudeArray") as! [Int]?
//        // Game save settings
//
//    }
        
}

extension Notification.Name {
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    // Notifies the app of any Game Center authentication state changes
}
