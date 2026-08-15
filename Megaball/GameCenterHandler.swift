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

    /// What a screen says when it would have posted a score and could not (play-test round
    /// 16: a player who is not signed in has no way of knowing their runs are going nowhere).
    ///
    /// Deliberately a sentence rather than a warning. Nothing is broken and nothing is lost -
    /// the game plays and the numbers are kept - so this belongs in the same quiet grey as
    /// the rest of the small print, not behind an alert. Written once here so the game-over
    /// screen and the daily briefing cannot end up phrasing it two different ways.
    static let notSignedInNote = "Not signed in to Game Center · scores stay on this device"
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

    /// A daily run's score, on its way to the recurring daily board - Game Center's own
    /// daily reset is the 24-hour window.
    ///
    /// The completion says whether it *landed* (§12.5): signed out, offline, or the
    /// board not existing yet all come back false, and the caller keeps the post
    /// pending for the retry loop. Deliberately not part of `gameCenterSave()`, which
    /// resubmits standing bests on every save - the daily board's entry is one run's
    /// result, made once, confirmed once.
    func submitDailyScores(dayScore: Int, completion: ((Bool) -> Void)? = nil) {
        guard GKLocalPlayer.local.isAuthenticated else { completion?(false); return }
        GKLeaderboard.submitScore(dayScore, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [DailyChallengeBoards.daily]) { error in
            DispatchQueue.main.async { completion?(error == nil) }
        }
    }

    /// The overall board's running total (§7), submitted whole after a day's post is
    /// confirmed. Always the whole total, so it is safe to resubmit and self-heals: a
    /// day that lands late still reaches it.
    func submitDailyTotal(_ total: Int) {
        guard total > 0 else { return }
        submit(total, to: DailyChallengeBoards.total)
    }

    /// Where the local player stands on today's board, and how big the field is.
    ///
    /// Nil when it cannot be known - signed out, offline, or the board not existing in
    /// App Store Connect yet - and the screen simply says nothing then.
    ///
    /// The field size comes from the *global* entry load rather than the by-player one,
    /// which is the only call that reports it (play-test round 126: "show the number of
    /// players e.g. 1st / 200"). A range of one row is asked for because the rows are not
    /// wanted at all - only the count that comes back beside them and the local player's
    /// own entry, which this call returns as well.
    func loadDailyStanding(completion: @escaping ((rank: Int, players: Int)?) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else { completion(nil); return }
        GKLeaderboard.loadLeaderboards(IDs: [DailyChallengeBoards.daily]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            board.loadEntries(for: .global, timeScope: .allTime,
                              range: NSRange(location: 1, length: 1)) {
                localEntry, _, players, _ in
                DispatchQueue.main.async {
                    guard let rank = localEntry?.rank else { completion(nil); return }
                    completion((rank: rank, players: max(players, rank)))
                    // Never fewer players than there are places: a count that has not
                    // caught up with the entry would print "3rd / 2"
                }
                // A recurring board's current occurrence is what loads by default,
                // which is exactly today's window
            }
        }
    }
    
    func loadData() {
        if let totalData = try? Data(contentsOf: totalStatsStore!) {
            do {
                totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
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
