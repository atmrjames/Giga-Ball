//
//  GameCenterHandler.swift
//  Megaball
//
//  Created by James Harding on 24/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

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
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let packStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("packStatsStore.plist")
    let levelStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("levelStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    var packStatsArray: [PackStats] = []
    var levelStatsArray: [LevelStats] = []
    // NSCoder data store & encoder setup
    
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
        
//        if  {
//            let endlessDurationReporter = GKScore(leaderboardIdentifier: "leaderboardEndlessDuration")
//            endlessDurationReporter.value =
//            let endlessDurationArray: [GKScore] = [endlessDurationReporter]
//            GKScore.report(endlessDurationArray, withCompletionHandler: nil)
//        }
//        // Leaderboard Endless Mode Duration TBC
        
        if packStatsArray[1].scores.count > 0 {
            let classicScoreReporter = GKScore(leaderboardIdentifier: "leaderboardClassicPackScore")
            classicScoreReporter.value = Int64(packStatsArray[1].scores.max()!)
            let classicScoreArray: [GKScore] = [classicScoreReporter]
            GKScore.report(classicScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Classic Pack
        
        if packStatsArray[2].scores.count > 0 {
            let spaceScoreReporter = GKScore(leaderboardIdentifier: "leaderboardSpacePackScore")
            spaceScoreReporter.value = Int64(packStatsArray[2].scores.max()!)
            let spaceScoreArray: [GKScore] = [spaceScoreReporter]
            GKScore.report(spaceScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Space Pack
        
        if levelStatsArray[1].scores.count > 0 {
            let level01ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel01Score")
            level01ScoreReporter.value = Int64(levelStatsArray[1].scores.max()!)
            let level01ScoreArray: [GKScore] = [level01ScoreReporter]
            GKScore.report(level01ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 01
        
        if levelStatsArray[2].scores.count > 0 {
            let level02ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel02Score")
            level02ScoreReporter.value = Int64(levelStatsArray[2].scores.max()!)
            let level02ScoreArray: [GKScore] = [level02ScoreReporter]
            GKScore.report(level02ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 02
        
        
        if levelStatsArray[3].scores.count > 0 {
            let level03ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel03Score")
            level03ScoreReporter.value = Int64(levelStatsArray[3].scores.max()!)
            let level03ScoreArray: [GKScore] = [level03ScoreReporter]
            GKScore.report(level03ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 03
        
        
        if levelStatsArray[4].scores.count > 0 {
            let level04ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel04Score")
            level04ScoreReporter.value = Int64(levelStatsArray[4].scores.max()!)
            let level04ScoreArray: [GKScore] = [level04ScoreReporter]
            GKScore.report(level04ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 04
        
        if levelStatsArray[5].scores.count > 0 {
            let level05ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel05Score")
            let level05ScoreArray: [GKScore] = [level05ScoreReporter]
            GKScore.report(level05ScoreArray, withCompletionHandler: nil)
            level05ScoreReporter.value = Int64(levelStatsArray[5].scores.max()!)
        }
        // Leaderboard Level 05
        
        if levelStatsArray[6].scores.count > 0 {
            let level06ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel06Score")
            level06ScoreReporter.value = Int64(levelStatsArray[6].scores.max()!)
            let level06ScoreArray: [GKScore] = [level06ScoreReporter]
            GKScore.report(level06ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 06
        
        if levelStatsArray[7].scores.count > 0 {
            let level07ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel07Score")
            level07ScoreReporter.value = Int64(levelStatsArray[7].scores.max()!)
            let level07ScoreArray: [GKScore] = [level07ScoreReporter]
            GKScore.report(level07ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 07
        
        if levelStatsArray[8].scores.count > 0 {
            let level08ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel08Score")
            level08ScoreReporter.value = Int64(levelStatsArray[8].scores.max()!)
            let level08ScoreArray: [GKScore] = [level08ScoreReporter]
            GKScore.report(level08ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 08
        
        if levelStatsArray[9].scores.count > 0 {
            let level09ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel09Score")
            level09ScoreReporter.value = Int64(levelStatsArray[9].scores.max()!)
            let level09ScoreArray: [GKScore] = [level09ScoreReporter]
            GKScore.report(level09ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 09
        
        if levelStatsArray[10].scores.count > 0 {
            let level10ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel10Score")
            level10ScoreReporter.value = Int64(levelStatsArray[10].scores.max()!)
            let level10ScoreArray: [GKScore] = [level10ScoreReporter]
            GKScore.report(level10ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 10
        
        if levelStatsArray[11].scores.count > 0 {
            let level11ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel11Score")
            level11ScoreReporter.value = Int64(levelStatsArray[11].scores.max()!)
            let level11ScoreArray: [GKScore] = [level11ScoreReporter]
            GKScore.report(level11ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 11
        
        if levelStatsArray[12].scores.count > 0 {
            let level12ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel12Score")
            level12ScoreReporter.value = Int64(levelStatsArray[12].scores.max()!)
            let level12ScoreArray: [GKScore] = [level12ScoreReporter]
            GKScore.report(level12ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 12
        
        if levelStatsArray[13].scores.count > 0 {
            let level13ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel13Score")
            level13ScoreReporter.value = Int64(levelStatsArray[13].scores.max()!)
            let level13ScoreArray: [GKScore] = [level13ScoreReporter]
            GKScore.report(level13ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 13
        
        if levelStatsArray[14].scores.count > 0 {
            let level14ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel14Score")
            level14ScoreReporter.value = Int64(levelStatsArray[14].scores.max()!)
            let level14ScoreArray: [GKScore] = [level14ScoreReporter]
            GKScore.report(level14ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 14
        
        if levelStatsArray[15].scores.count > 0 {
            let level15ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel15Score")
            level15ScoreReporter.value = Int64(levelStatsArray[15].scores.max()!)
            let level15ScoreArray: [GKScore] = [level15ScoreReporter]
            GKScore.report(level15ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 15
        
        if levelStatsArray[16].scores.count > 0 {
            let level16ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel16Score")
            level16ScoreReporter.value = Int64(levelStatsArray[16].scores.max()!)
            let level16ScoreArray: [GKScore] = [level16ScoreReporter]
            GKScore.report(level16ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 16
        
        if levelStatsArray[17].scores.count > 0 {
            let level17ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel17Score")
            level17ScoreReporter.value = Int64(levelStatsArray[17].scores.max()!)
            let level17ScoreArray: [GKScore] = [level17ScoreReporter]
            GKScore.report(level17ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 17
        
        if levelStatsArray[18].scores.count > 0 {
            let level18ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel18Score")
            level18ScoreReporter.value = Int64(levelStatsArray[18].scores.max()!)
            let level18ScoreArray: [GKScore] = [level18ScoreReporter]
            GKScore.report(level18ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 18
        
        if levelStatsArray[19].scores.count > 0 {
            let level19ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel19Score")
            level19ScoreReporter.value = Int64(levelStatsArray[19].scores.max()!)
            let level19ScoreArray: [GKScore] = [level19ScoreReporter]
            GKScore.report(level19ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 19
        
        if levelStatsArray[20].scores.count > 0 {
            let level20ScoreReporter = GKScore(leaderboardIdentifier: "leaderboardLevel20Score")
            level20ScoreReporter.value = Int64(levelStatsArray[20].scores.max()!)
            let level20ScoreArray: [GKScore] = [level20ScoreReporter]
            GKScore.report(level20ScoreArray, withCompletionHandler: nil)
        }
        // Leaderboard Level 20
        
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
        
        if let packData = try? Data(contentsOf: packStatsStore!) {
            do {
                packStatsArray = try decoder.decode([PackStats].self, from: packData)
            } catch {
                print("Error decoding high score array, \(error)")
            }
        }
        // Load the pack stats array from the NSCoder data store
        
        if let levelData = try? Data(contentsOf: levelStatsStore!) {
            do {
                levelStatsArray = try decoder.decode([LevelStats].self, from: levelData)
            } catch {
                print("Error decoding level stats array, \(error)")
            }
        }
        // Load the level stats array from the NSCoder data store
    }
}

extension Notification.Name {
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    // Notifies the app of any Game Center authentication state changes
}
