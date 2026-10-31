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

    /// Sends achievements to Game Center, when there is a signed-in player to send them for.
    ///
    /// **Not at all while signed out** (round 384, from James's Mac log, signed out of Game
    /// Center: "<GKAchievement> has a nil or invalid internal player" and "The requested
    /// operation could not be completed because local player has not been authenticated", for
    /// every achievement a run earned). GameKit cannot take a report then and keeps nothing to
    /// send later, so asking only filled the log; the award itself is already kept in the
    /// player's own stats, which is what the achievements page reads. Every report in the app
    /// goes through here, sixty-one of them.
    static func reportAchievements(_ achievements: [GKAchievement],
                                   withCompletionHandler completion: ((Error?) -> Void)? = nil) {
        guard isAuthenticated else { return }
        GKAchievement.report(achievements, withCompletionHandler: completion)
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
        // **No authentication handler here** (round 384, from James's Mac log: the sign-in was
        // attempted and failed again at the start and end of every run). Setting
        // `authenticateHandler` is what asks GameKit to authenticate, and this initialiser set
        // it - so every `GameCenterHandler()` a score submission built started a new sign-in,
        // nineteen call sites of them. It also replaced the main menu's handler, the one that
        // presents Game Center's sign-in and tells the menus how it went, with this one, whose
        // `viewController` nothing ever set and whose notification nothing ever observed.
        // `MenuViewController.authGCPlayer` is the one owner now, once at launch and once per
        // return to the foreground
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
            submit(totalStatsArray[0].cumulativeScore, to: GameMode.classicTotalScoreLeaderboard)
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

    /// Whether a closed day's score is actually on the daily board.
    ///
    /// **Round 331, for the pending post that outlived its window** (James: "relax the guard
    /// and fix the pending-post bug"). The app can be killed between submitting a score and
    /// recording that it landed, and after midnight there is no safe way to *resubmit* - the
    /// daily board recurs, so yesterday's score would go into today's window. Asking is the
    /// honest alternative: if the player holds an entry on the occurrence that has just closed,
    /// the submission landed, whatever the phone wrote down.
    ///
    /// `loadPreviousOccurrence` is why this only works for yesterday. A recurring leaderboard
    /// hands back exactly one closed occurrence, the one that ended last, and the caller
    /// (`DailyChallengePosting.dayToVerify`) knows it.
    ///
    /// Answers false for every ordinary reason it cannot know - signed out, offline, no such
    /// board, no entry - because the record is already written off as a miss by then and false
    /// simply leaves it there. Only a yes changes anything.
    func dailyScoreLanded(on dateKey: String, completion: @escaping (Bool) -> Void) {
        guard GKLocalPlayer.local.isAuthenticated else { completion(false); return }
        GKLeaderboard.loadLeaderboards(IDs: [DailyChallengeBoards.daily]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            board.loadPreviousOccurrence { previous, _ in
                guard let previous else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                previous.loadEntries(for: [GKLocalPlayer.local],
                                     timeScope: .allTime) { localEntry, _, _ in
                    let landed = localEntry != nil
                    Log.gameCenter.notice("""
                        DAILY \(dateKey, privacy: .public) on the closed board: \
                        \(landed ? "found" : "not found", privacy: .public)
                        """)
                    DispatchQueue.main.async { completion(landed) }
                    // An entry at all is the answer, not a score comparison. The only thing
                    // this app ever submits to the daily board is that day's attempt, so an
                    // entry on that occurrence *is* the attempt - and a score posted from the
                    // player's other device is just as landed as one posted from this one
                }
            }
        }
    }

    /// The top score on the daily board for a day, where Game Center can still say (round 350).
    ///
    /// The daily board recurs, so only two occurrences exist to ask: today's, which is open, and
    /// the one that closed last - yesterday's. Any older day answers nil, as does a player who is
    /// signed out or offline, or a board with nobody on it yet. The top place is read whether or
    /// not the local player has an entry, which `loadRank` cannot do: it answers only for a
    /// player on the board.
    func loadDailyBoardBest(forKey key: String, completion: @escaping (Int?) -> Void) {
        let session = DailyChallengeSession.shared
        guard GKLocalPlayer.local.isAuthenticated,
              let occurrence = DailyChallengeSession.boardOccurrence(forKey: key,
                                                                    todayKey: session.todayKey)
        else { completion(nil); return }
        func top(of board: GKLeaderboard) {
            board.loadEntries(for: .global, timeScope: .allTime,
                              range: NSRange(location: 1, length: 1)) { _, entries, _, _ in
                DispatchQueue.main.async { completion(entries?.first?.score) }
            }
        }
        GKLeaderboard.loadLeaderboards(IDs: [DailyChallengeBoards.daily]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            switch occurrence {
            case .current: top(of: board)
            case .previous:
                board.loadPreviousOccurrence { previous, _ in
                    guard let previous else {
                        DispatchQueue.main.async { completion(nil) }
                        return
                    }
                    top(of: previous)
                }
            }
        }
    }

    /// The leading places on a day's board, and the local player's own (round 354).
    ///
    /// The same two occurrences `loadDailyBoardBest` can reach, and nil for the same reasons:
    /// an older day, a signed-out player, no network, no board. An empty board answers with
    /// no leaders rather than nil, so the caller can tell "nobody yet" from "cannot know".
    ///
    /// One request answers both halves: `loadEntries(for: .global ...)` hands back the local
    /// player's entry beside the range asked for, which is the call `loadRank` already relies
    /// on.
    ///
    /// It is also everything the daily result pop-up needs about a closed day (round 358b), so
    /// that asks here too. The entries of a closed day can be read; the day itself cannot be
    /// *shown* in Game Center, which is `dailyBoardScreen()`'s story.
    func loadDailyBoardTop(forKey key: String, count: Int,
                           completion: @escaping ((leaders: [DailyBoardRow],
                                                   local: DailyBoardRow?, players: Int)?) -> Void) {
        let me = GKLocalPlayer.local.gamePlayerID
        func row(_ entry: GKLeaderboard.Entry) -> DailyBoardRow {
            DailyBoardRow(rank: entry.rank, name: entry.player.displayName, score: entry.score,
                          isLocalPlayer: entry.player.gamePlayerID == me)
        }
        loadDailyBoardOccurrence(forKey: key) { board in
            guard let board else { completion(nil); return }
            board.loadEntries(for: .global, timeScope: .allTime,
                              range: NSRange(location: 1, length: max(1, count))) {
                localEntry, entries, players, error in
                let answer = error == nil || entries != nil
                    ? (leaders: (entries ?? []).filter { $0.rank > 0 }.map(row),
                       local: localEntry.flatMap { $0.rank > 0 ? row($0) : nil },
                       players: players)
                    : nil
                // **Rank nought is not a place** (round 385c). Game Center answers with an
                // entry for the local player on a board they have never posted to, ranked 0
                // with a score of 0, and every screen that read it showed "0 atmrjames 0" -
                // the menu since round 361 had been told to look past it, the end screen had
                // not. Taken out here, where the answer is made, so no screen has to know
                DispatchQueue.main.async { completion(answer) }
            }
        }
    }

    /// Game Center on the daily board, **always by its identifier**, which shows today's day.
    ///
    /// Round 360 opened yesterday's closed day instead, by handing
    /// `GKGameCenterViewController(leaderboard:playerScope:)` the previous occurrence, which
    /// GameKit's header says recurring boards may do. On James's phone it does not (round 361:
    /// "Yesterday's card, posted score and leaderboard button opened Game Center, but not on
    /// yesterday's daily challenge leaderboard, just on the main giga-ball game center page").
    /// Given a closed occurrence, Game Center falls back to the game's front page, which is
    /// further from the day than the daily board is. There is no other call that names an
    /// occurrence - `GKAccessPoint`'s triggers take an identifier too - so every daily button
    /// opens the board, and what a closed day held is shown in the app, where its entries can
    /// still be read.
    static func dailyBoardScreen() -> GKGameCenterViewController {
        GKGameCenterViewController(leaderboardID: DailyChallengeBoards.daily,
                                   playerScope: .global, timeScope: .allTime)
    }

    /// A day's own occurrence of the recurring daily board - today's, or yesterday's closed
    /// one - answered on the main queue, or nil where Game Center cannot say: an older day, a
    /// signed-out player, no network. Read for its entries; see `dailyBoardScreen()` for why it
    /// is never shown.
    func loadDailyBoardOccurrence(forKey key: String,
                                  completion: @escaping (GKLeaderboard?) -> Void) {
        let session = DailyChallengeSession.shared
        guard GKLocalPlayer.local.isAuthenticated,
              let occurrence = DailyChallengeSession.boardOccurrence(forKey: key,
                                                                    todayKey: session.todayKey)
        else { completion(nil); return }
        GKLeaderboard.loadLeaderboards(IDs: [DailyChallengeBoards.daily]) { boards, _ in
            guard let board = boards?.first else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            switch occurrence {
            case .current:
                GameCenterHandler.noteTheOccurrence(board, forKey: key)
                DispatchQueue.main.async { completion(board) }
            case .previous:
                board.loadPreviousOccurrence { previous, _ in
                    previous.map { GameCenterHandler.noteTheOccurrence($0, forKey: key) }
                    DispatchQueue.main.async { completion(previous) }
                }
            }
        }
    }

    /// Says so in the log when the board's window is not the day the app thinks it is.
    ///
    /// **James, 1.3 play test: "Endless mode daily challenge score is showing as >1000m which is
    /// wrong"** - his run had reached "more like 100m". Every daily, whatever its mode, posts to
    /// the one recurring board, and Game Center keeps each player's best within a window; the
    /// board he saw held 2,348 and 1,998, two Classic-sized scores on an Endless day. A window
    /// that began anywhere but the day's UTC midnight would do exactly that - it spans the end of
    /// one day and the start of the next, and a Classic run posted before the app's day turned
    /// out-scores the Endless run after it. The app cannot move the window, which is set in App
    /// Store Connect; it can say when one does not match, in Console under
    /// `subsystem:com.atmrjames.Megaball category:gameCenter`.
    static func noteTheOccurrence(_ board: GKLeaderboard, forKey key: String) {
        guard let start = board.startDate else { return }
        if DailyChallengeSession.occurrence(starting: start, isTheDay: key) {
            Log.gameCenter.info("daily board window for \(key, privacy: .public) starts \(start, privacy: .public), as it should")
        } else {
            Log.gameCenter.error("daily board window for \(key, privacy: .public) starts \(start, privacy: .public), not at that day's 00:00 UTC - its scores span two days")
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
                    guard let rank = localEntry?.rank, rank > 0 else { completion(nil); return }
                    // Rank nought is an entry for a player with no score on the board, the
                    // same answer the daily board has to look past (round 385c) - "0th"
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
