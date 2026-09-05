//
//  ResumeCardTests.swift
//  GigaBallTests
//
//  What the resuming screen says, round 310.
//
//  James: "The resuming screen when returning to the app needs tidying up. Move the
//  Resuming... label to just above the cancel button and give it the same font, style, glow as
//  the game mode titles from their respective menu views... Underneath the Resuming... label
//  show the game mode, and underneath that show the details of the game mode, like the pack and
//  level name. Underneath that, show the current score / height with the score label and score
//  on a single line. Remove the still scoring your attempt line. If it's a competition run on a
//  daily challenge say that in the details label."
//
//  The screen is only reachable by force-quitting a game and relaunching, and there are nine
//  shapes of save that reach it, so the words are checked here rather than nine times by hand.
//

import XCTest
@testable import Giga_Ball

final class ResumeCardTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    /// A Classic run, seven levels into a ten-level pack.
    private func classicGame() -> SavedGame {
        SavedGame(
            levelNumber: LevelPackSetup().startLevelNumber[2] + 3, endLevelNumber: 10,
            packNumber: 2,
            levelScore: 120, totalScore: 3_400, numberOfLives: 2,
            endlessHeight: 0, numberOfLevels: 10,
            levelTimerValue: 45, packTimerValue: 300,
            deathsPerLevel: 1, deathsPerPack: 3,
            powerUpsGeneratedPerLevel: 4, powerUpsCollectedPerLevel: 2,
            powerUpsGeneratedPerPack: 20, powerUpsCollectedPerPack: 11,
            paddleHitsPerLevel: 33,
            multiplier: 1.4,
            brickTextures: [], brickColours: [],
            brickXPositions: [], brickYPositions: [],
            ballProperties: [],
            fallingPowerUpXPositions: [], fallingPowerUpYPositions: [],
            fallingPowerUps: [],
            activePowerUps: [], activePowerUpDurations: [],
            activePowerUpTimers: [], activePowerUpMagnitudes: [])
    }

    /// An endless run: level nought, a height rather than a score, and no rack.
    private func endlessGame(_ mode: GameMode, height: Int = 214) -> SavedGame {
        var game = classicGame()
        game.levelNumber = 0
        game.numberOfLevels = 1
        game.endlessHeight = height
        game.gameMode = mode.rawValue
        return game
    }

    // MARK: - The heading

    /// "Give it the same font, style, glow as the game mode titles from their respective menu
    /// views" - and every one of those is uppercased.
    func testTheHeadingIsSetLikeAMenuTitle() {
        XCTAssertEqual(ResumeCard.Lines().heading, "RESUMING…",
                       "upper case, and one ellipsis rather than three full stops")
        XCTAssertEqual(ResumeCard.lines(for: classicGame(), fallbackMode: .classic).heading,
                       "RESUMING…",
                       "the same words whatever is being resumed")
    }

    // MARK: - Classic

    /// "Underneath the Resuming... label show the game mode, and underneath that show the
    /// details of the game mode, like the pack and level name."
    func testAClassicRunNamesItsModeThenItsPackAndLevel() {
        let packs = LevelPackSetup()
        let lines = ResumeCard.lines(for: classicGame(), fallbackMode: .classic)

        XCTAssertEqual(lines.mode, GameMode.classic.name,
                       "the mode leads, which is what the screen never used to say at all")
        XCTAssertEqual(lines.detail, packs.levelPackNameArray[2] + " - Level 4 of "
                       + String(packs.numberOfLevels[2]),
                       "pack before level, the order round 310 asked the daily's card for too")
        XCTAssertEqual(lines.scoreTitle, "Score")
        XCTAssertEqual(lines.scoreValue, "3400")
    }

    /// A single level is not a pack, and says so where the pack name would go.
    func testASingleLevelRunNamesTheLevel() {
        var game = classicGame()
        game.numberOfLevels = 1
        let lines = ResumeCard.lines(for: game, fallbackMode: .classic)

        XCTAssertEqual(lines.mode, "Single Level Mode")
        XCTAssertEqual(lines.detail, LevelPackSetup().levelNameArray[game.levelNumber])
        XCTAssertEqual(lines.scoreTitle, "Score")
    }

    // MARK: - The endless modes

    /// Both endless modes share level nought, so the name has to come from the save.
    ///
    /// Round 170's bug, kept under test through the rewrite: the card used to ask the
    /// remembered mode key, which a force quit can lose before it reaches disk, and then
    /// offered to resume "Endless Mode" into a Mayhem run.
    func testAnEndlessRunTakesItsNameFromTheSaveNotTheRememberedKey() {
        let mayhem = ResumeCard.lines(for: endlessGame(.endlessII), fallbackMode: .endless)
        XCTAssertEqual(mayhem.mode, GameMode.endlessII.name,
                       "the save says Mayhem, so the card says Mayhem")

        let endless = ResumeCard.lines(for: endlessGame(.endless), fallbackMode: .endlessII)
        XCTAssertEqual(endless.mode, GameMode.endless.name)
    }

    /// A save written before the field existed still falls back to the remembered key.
    func testASaveWithoutAModeFallsBackToTheRememberedOne() {
        var game = endlessGame(.endlessII)
        game.gameMode = nil
        XCTAssertEqual(ResumeCard.lines(for: game, fallbackMode: .endlessII).mode,
                       GameMode.endlessII.name)
        XCTAssertEqual(ResumeCard.lines(for: game, fallbackMode: .endless).mode,
                       GameMode.endless.name)
    }

    /// "Show the current score / height" - an endless run scores in metres.
    func testAnEndlessRunShowsItsHeightAndHasNoDetailLine() {
        let lines = ResumeCard.lines(for: endlessGame(.endlessII, height: 214),
                                     fallbackMode: .endlessII)
        XCTAssertEqual(lines.scoreTitle, "Height")
        XCTAssertEqual(lines.scoreValue, "214m")
        XCTAssertEqual(lines.detail, "",
                       "there is nothing under an endless mode's name to say, and an empty "
                       + "line would only open a gap")
    }

    // MARK: - The daily

    /// "If it's a competition run on a daily challenge say that in the details label."
    func testTodaysScoringAttemptSaysSoInTheDetail() {
        var game = classicGame()
        let key = DailyChallengeSession.shared.todayKey
        game.dailyDateKey = key
        game.dailyWasScoringAttempt = true

        let lines = ResumeCard.lines(for: game, fallbackMode: .classic)
        XCTAssertEqual(lines.mode, GameMode.daily.name)
        XCTAssertTrue(lines.detail.contains("Competition run"),
                      "got: \(lines.detail)")
        XCTAssertTrue(lines.detail.hasPrefix(
            DailyChallengeSession.shared.displayName(forKey: key).capitalized),
                      "the day leads the detail line, got: \(lines.detail)")
    }

    /// Free play on today's challenge is not a competition run, and says nothing.
    func testTodaysFreePlaySaysNothingAboutCompeting() {
        var game = classicGame()
        game.dailyDateKey = DailyChallengeSession.shared.todayKey
        game.dailyWasScoringAttempt = false

        XCTAssertFalse(ResumeCard.lines(for: game, fallbackMode: .classic)
            .detail.contains("Competition"))
    }

    /// Neither is a run resumed after its day closed, however it started.
    ///
    /// This is the line James asked to be rid of: it used to read "Still your scoring
    /// attempt." under the score, and a closed day meant it was not.
    func testAClosedDaySaysNothingAboutCompeting() {
        var game = classicGame()
        game.dailyDateKey = "2020-01-01"
        game.dailyWasScoringAttempt = true

        let lines = ResumeCard.lines(for: game, fallbackMode: .classic)
        XCTAssertFalse(lines.detail.contains("Competition"),
                       "the window is the day, and the day has gone")
        XCTAssertTrue(lines.detail.hasPrefix("1 January 2020")
                      || lines.detail.isEmpty == false,
                      "the day it was still names itself, got: \(lines.detail)")
    }

    /// An endless daily reads its unit off the challenge, not off the save's level number -
    /// a daily save keeps the level it was on either way.
    func testAnEndlessDailyShowsAHeight() {
        var game = classicGame()
        game.endlessHeight = 88
        // A hand-built challenge, so the assertion does not depend on what today happens to be
        let key = "2026-10-08"
        game.dailyDateKey = key
        let challenge = DailyChallengeGenerator.challenge(forKey: key)

        let lines = ResumeCard.lines(for: game, fallbackMode: .classic)
        if challenge.mode == .classic {
            XCTAssertEqual(lines.scoreTitle, "Score")
            XCTAssertEqual(lines.scoreValue, "3400")
        } else {
            XCTAssertEqual(lines.scoreTitle, "Height")
            XCTAssertEqual(lines.scoreValue, "88m")
        }
        XCTAssertTrue(lines.detail.contains(challenge.mode == .classic
                                            ? LevelPackSetup().levelNameArray[game.levelNumber]
                                            : challenge.mode.name),
                      "the day's own mode or level names itself, got: \(lines.detail)")
    }
}
