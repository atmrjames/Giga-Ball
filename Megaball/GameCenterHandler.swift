//
//  GameCenterHandler.swift
//  Megaball
//
//  Created by James Harding on 24/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//a

import GameKit

final class GameCenterHandler: NSObject {

    /// Whether this process was launched by the test runner.
    ///
    /// Used to keep Game Center's authentication out of the suite - see `authGCPlayer`, where
    /// the measurement that made it necessary is written down. A runtime check rather than
    /// `#if DEBUG`, because the thing being asked is "am I being tested", not "is this a debug
    /// build": James plays debug builds every round and they should behave exactly as the
    /// shipped one does.
    static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

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
            submit(totalStatsArray[0].endlessModeHeight.max()!, to: GameMode.endlessBestHeightLeaderboard)
        }
        // Leaderboard Endless Best Height

        if totalStatsArray[0].endlessModeHeight.count > 0 {
            submit(totalStatsArray[0].endlessModeHeight.reduce(0, +), to: GameMode.endlessTotalHeightLeaderboard)
        }
        // Leaderboard Endless Total Height
        // Endless mode leaderboards

        if let best = totalStatsArray[0].endlessIIHeights.max(), best > 0 {
            submit(best, to: GameMode.endlessIIBestHeightLeaderboard)
            submit(totalStatsArray[0].endlessIIHeights.reduce(0, +), to: GameMode.endlessIITotalHeightLeaderboard)
        }
        // Endless 2.0's own boards. Not comparable to the originals, so not posted to them

        for (arrayIndex, leaderboardIdentifier) in LevelPackSetup.packScoreLeaderboards.enumerated()
        where totalStatsArray[0].packHighScores.indices.contains(arrayIndex) {
            if totalStatsArray[0].packHighScores[arrayIndex] > 0 {
                submit(totalStatsArray[0].packHighScores[arrayIndex], to: leaderboardIdentifier)
            }
        }
        // Level pack total leaderboards. The list of boards used to be written out here and
        // again in the level selector at a different offset; it lives in `LevelPackSetup`
        // now, beside the packs it names, and the index it is walked with is the one
        // `packHighScores` uses
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

    /// Where the local player stands on a board, and how big the field is.
    ///
    /// Nil when it cannot be known - signed out, offline, the board not existing in App
    /// Store Connect yet, or the player holding no entry on it - and the screen simply says
    /// nothing then.
    ///
    /// This used to add that Endless Mayhem needed no special handling because its boards did
    /// not exist. **They have existed since 21 August 2026**, when James created them, so that
    /// sentence had been describing a previous state of the world for a month: a Mayhem run
    /// now gets the same standing line as any other. The nil case still covers everything
    /// above, which is the part that was doing the work.
    ///
    /// The field size comes from the *global* entry load rather than the by-player one,
    /// which is the only call that reports it (play-test round 126: "show the number of
    /// players e.g. 1st / 200"). A range of one row is asked for because the rows are not
    /// wanted at all - only the count that comes back beside them and the local player's
    /// own entry, which this call returns as well.
    ///
    /// Written for the daily and generalised in round 160 for the endless and classic
    /// game-overs, which ask the same question of their own boards.
    func loadRank(leaderboardID: String,
                  completion: @escaping ((rank: Int, players: Int, best: Int?)?) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else { completion(nil); return }
        GKLeaderboard.loadLeaderboards(IDs: [leaderboardID]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            board.loadEntries(for: .global, timeScope: .allTime,
                              range: NSRange(location: 1, length: 1)) {
                localEntry, entries, players, _ in
                DispatchQueue.main.async {
                    guard let rank = localEntry?.rank else { completion(nil); return }
                    completion((rank: rank, players: max(players, rank),
                                best: entries?.first?.score))
                    // Never fewer players than there are places: a count that has not
                    // caught up with the entry would print "3rd / 2"
                    //
                    // The range asked for is the *first* place, so the entry that comes back
                    // beside the local player's is the board's leader - the global best was
                    // already being fetched and thrown away, and James asked for it in round
                    // 185. Optional because a board with no entries yet answers with none
                }
                // A recurring board's current occurrence is what loads by default, which
                // for the daily is exactly today's window; a classic board has only the
                // one occurrence and reads the same way
            }
        }
    }
    
    /// The players immediately above the local player on the Mayhem height board.
    ///
    /// For the lines Endless Mayhem draws behind its field (`EndlessIIRivals`). Two calls: the
    /// local player's rank, then the handful of places above it - the board cannot be asked
    /// "who is just above me" in one go, and asking for the top of the board instead would
    /// return either an unreachable number or, on a board this young, one already behind.
    ///
    /// Answers with an empty list rather than an error for every ordinary reason it can fail -
    /// not signed in, no board, nobody above, the network away. Nothing here is worth telling
    /// the player about: the lines are a decoration on a run that plays identically without
    /// them, and a run interrupted to explain their absence would be the worse outcome.
    func loadEndlessIIRivals(completion: @escaping ([EndlessIIRival]) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else { completion([]); return }
        let id = GameMode.endlessIIBestHeightLeaderboard

        GKLeaderboard.loadLeaderboards(IDs: [id]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            board.loadEntries(for: .global, timeScope: .allTime,
                              range: NSRange(location: 1, length: 1)) { localEntry, _, _, _ in
                let rank = localEntry?.rank ?? 0
                let above = max(1, rank - EndlessIIRivals.mostLines)
                let length = rank > 1 ? min(EndlessIIRivals.mostLines, rank - 1)
                                      : EndlessIIRivals.mostLines
                // Unranked - a player who has never posted a height - is given the *bottom* of
                // the board instead, which is the nearest thing to "just above you" that
                // exists for somebody who is not on it yet. `rank` of zero falls through to
                // the first places, and on a board with three entries those are the three
                // there are

                board.loadEntries(for: .global, timeScope: .allTime,
                                  range: NSRange(location: above, length: length)) {
                    _, entries, _, _ in
                    let rivals = (entries ?? [])
                        .filter { $0.player.gamePlayerID != GKLocalPlayer.local.gamePlayerID }
                        .map { EndlessIIRival(name: $0.player.displayName, height: $0.score) }
                    // The local player can appear in a global range that spans their own
                    // place, and a line saying "you, 412m" beside the BEST line saying the
                    // same is one line too many
                    DispatchQueue.main.async { completion(rivals) }
                }
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
