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
                Log.gameCenter.error("Error authenticating to Game Center: \(error?.localizedDescription ?? "none", privacy: .public)")
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
            submit(totalStatsArray[0].cumulativeScore, to: "leaderboardTotalScore")
        }
        // Leaderboard Total Score

        if totalStatsArray[0].endlessModeHeight.count > 0 {
            submit(totalStatsArray[0].endlessModeHeight.max()!, to: "leaderboardBestHeight")
        }
        // Leaderboard Endless Best Height

        if totalStatsArray[0].endlessModeHeight.count > 0 {
            submit(totalStatsArray[0].endlessModeHeight.reduce(0, +), to: "leaderboardTotalHeight")
        }
        // Leaderboard Endless Total Height
        // Endless mode leaderboards

        if let best = totalStatsArray[0].endlessIIHeights.max(), best > 0 {
            submit(best, to: GameMode.endlessIIBestHeightLeaderboard)
            submit(totalStatsArray[0].endlessIIHeights.reduce(0, +), to: GameMode.endlessIITotalHeightLeaderboard)
        }
        // Endless 2.0's own boards. Not comparable to the originals, so not posted to them

        var arrayIndex = 0
        let leaderboardIdentifierArray = ["leaderboardClassicPackScore", "leaderboardSpacePackScore", "leaderboardNaturePackScore", "leaderboardUrbanPackScore", "leaderboardFoodPackScore", "leaderboardComputerPackScore", "leaderboardBodyPackScore", "leaderboardWorldPackScore", "leaderboardEmojiPackScore", "leaderboardNumbersPackScore", "leaderboardChallengePackScore"]
        while arrayIndex <= 10 {
            if totalStatsArray[0].packHighScores[arrayIndex] > 0 {
                submit(totalStatsArray[0].packHighScores[arrayIndex], to: leaderboardIdentifierArray[arrayIndex])
            }
            arrayIndex+=1
        }
        // Level pack total leaderboards
    }

    private func submit(_ score: Int, to leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID], completionHandler: { _ in })
    }
    // Replaces GKScore.report, deprecated in iOS 14
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
            } catch {
                Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
            }
        }
        // Load the total stats array from the NSCoder data store
    }
        
}

extension Notification.Name {
    static let authenticationChanged = Notification.Name(rawValue: "authenticationChanged")
    // Notifies the app of any Game Center authentication state changes
}
