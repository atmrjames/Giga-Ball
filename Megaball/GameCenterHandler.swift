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
            } else if let vc = gcAuthVC {
                self.viewController?.present(vc, animated: true)
            }
            else {
                print("Error authentication to GameCenter: " + "\(error?.localizedDescription ?? "none")")
            }
        }
    }
    
    let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
    let encoder = PropertyListEncoder()
    let decoder = PropertyListDecoder()
    var totalStatsArray: [TotalStats] = []
    // NSCoder data store & encoder setup
        
    let localPlayer = GKLocalPlayer.local
    
    func gameCenterSave() {
        loadData()
        
        if totalStatsArray[0].cumulativeScore > 0 {
            let totalScoreReporter = GKScore(leaderboardIdentifier: "leaderboardTotalScore")
            totalScoreReporter.value = Int64(totalStatsArray[0].cumulativeScore)
            let totalScoreArray: [GKScore] = [totalScoreReporter]
            GKScore.report(totalScoreArray, withCompletionHandler: nil)
        }
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
    }
        
}

extension Notification.Name {
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    // Notifies the app of any Game Center authentication state changes
}
