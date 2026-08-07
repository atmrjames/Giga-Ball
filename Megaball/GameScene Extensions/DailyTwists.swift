//
//  DailyTwists.swift
//  Megaball
//
//  Where the day's twists reach the scene.
//
//  The scene never knows it is playing a daily - it plays Classic or an endless mode
//  exactly as ever, and asks `DailyChallengeSession` at a handful of named points whether
//  the day says otherwise. Keeping the hooks few and listed here is what keeps the daily
//  from becoming a fourth copy of the game: it is the same game, asked politely to differ.
//
//  The other half of this file is the standing-down: a daily run must never touch the
//  campaign's saves, heights, or high scores (§9 of the daily spec). Those gates live at
//  the write sites, but the questions they ask are defined here.
//

import SpriteKit

extension GameScene {

    var isDailyChallenge: Bool {
        DailyChallengeSession.shared.isActive
    }

    /// The day's word on how many lives Classic starts with. Nil means the mode's own.
    var dailyStartingLives: Int? {
        guard isDailyChallenge else { return nil }
        if DailyChallengeSession.shared.has(.oneLife) { return 1 }
        if DailyChallengeSession.shared.has(.loaded) { return 5 }
        if DailyChallengeSession.shared.has(.suddenDeath) { return 1 }
        // Sudden Death in Classic is One Life by another name; in the endless modes it
        // has its own teeth (see endlessIIBallWasLost's gate)
        return nil
    }

    /// Whether losing any ball ends the run today, whatever the mode's own rules say.
    var dailySuddenDeath: Bool {
        isDailyChallenge && DailyChallengeSession.shared.has(.suddenDeath)
    }

    /// Applies the day's economy to the power-up tables.
    ///
    /// Called at the end of both allocation paths - the classic per-level one and the
    /// endless per-row one - so whatever they decided, the day has the last word.
    func applyDailyEconomyTwists() {
        guard isDailyChallenge else { return }
        let session = DailyChallengeSession.shared

        if session.has(.noPowerUps) {
            for index in powerUpProbArray.indices { powerUpProbArray[index] = 0 }
        }
        if session.has(.noGoodNews) {
            for index in powerUpProbArray.indices
            where GameScene.endlessIIHarmfulPowerUps.contains(index) == false {
                powerUpProbArray[index] = 0
            }
        }
        if session.has(.noBadNews) {
            for index in powerUpProbArray.indices
            where GameScene.endlessIIHarmfulPowerUps.contains(index) {
                powerUpProbArray[index] = 0
            }
        }
        if session.has(.powerShower) {
            powerUpProbFactor = 3
            // The drop roll is one-in-factor per destroyed brick, so smaller is rainier
        }
        if session.has(.drought) {
            powerUpProbFactor = 30
        }
    }

    /// Hides the day's bricks, where Fog of War is on.
    ///
    /// Only the bricks that know how to come back: the reveal machinery answers a *hit*,
    /// and Portals, power-up bricks and Indestructibles have hit rules of their own that
    /// never pass through it - a fogged Indestructible would stay invisible for ever.
    func applyDailyFog(to bricks: [SKNode]) {
        guard isDailyChallenge, DailyChallengeSession.shared.has(.fogOfWar) else { return }
        for node in bricks {
            guard let brick = node as? SKSpriteNode else { continue }
            guard brick.endlessIIRole != .portal else { continue }
            guard brick.endlessIIPowerUpIndex == nil else { continue }
            guard brick.texture != brickIndestructible1Texture,
                  brick.texture != brickIndestructible2Texture,
                  brick.texture != brickNullTexture else { continue }
            brick.isHidden = true
        }
    }
}
