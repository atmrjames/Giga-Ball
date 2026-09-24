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
        XCTAssertEqual(ResumeCard.Lines().heading, "RESUMING",
                       "upper case, and one ellipsis rather than three full stops")
        XCTAssertEqual(ResumeCard.lines(for: classicGame(), fallbackMode: .classic).heading,
                       "RESUMING",
                       "the same words whatever is being resumed")
    }

    // MARK: - Classic

    /// "Underneath the Resuming... label show the game mode, and underneath that show the
    /// details of the game mode, like the pack and level name."
    func testAClassicRunNamesItsModeThenItsPackAndLevel() {
        let packs = LevelPackSetup()
        let lines = ResumeCard.lines(for: classicGame(), fallbackMode: .classic)

        XCTAssertEqual(lines.mode, packs.levelPackNameArray[2] + "\nLevel 4 of "
                       + String(packs.numberOfLevels[2]),
                       "**the pause screen's order** (James, round 341): the pack, then where "
                       + "in it - the badge says Classic, as it does on the pause screen")
        XCTAssertEqual(lines.detail, packs.levelNameArray[classicGame().levelNumber],
                       "and the level's own name under them")
        XCTAssertEqual(lines.badge, .classic)
        XCTAssertEqual(lines.scoreTitle, "Score")
        XCTAssertEqual(lines.scoreValue, "3400")
        XCTAssertEqual(lines.lives, "3 balls left",
                       "two in the rack and the one on the paddle")
    }

    /// "For the classic mode level, can it also show the name of the level, maybe on another
    /// line underneath" (James, round 311).
    func testAClassicRunNamesTheLevelItIsOn() {
        let lines = ResumeCard.lines(for: classicGame(), fallbackMode: .classic)
        let name = LevelPackSetup().levelNameArray[classicGame().levelNumber]
        XCTAssertEqual(lines.detail, name, "what it is called, under where it is")
        XCTAssertFalse(name.isEmpty)
    }

    /// "The number of lives could come back underneath the score" (James, round 311).
    func testTheRackIsCountedWithTheBallOnThePaddle() {
        XCTAssertEqual(ResumeCard.livesLine(1), "Last ball")
        XCTAssertEqual(ResumeCard.livesLine(3), "3 balls left")

        var game = classicGame()
        game.numberOfLives = 0
        XCTAssertEqual(ResumeCard.lines(for: game, fallbackMode: .classic).lives, "Last ball",
                       "an empty rack still has the ball about to be served")
    }

    /// An endless run says nothing about its single life, the rule the pause screen follows.
    func testAnEndlessRunWithNoRackSaysNothingAboutIt() {
        var game = endlessGame(.endlessII)
        game.numberOfLives = 0
        XCTAssertEqual(ResumeCard.lines(for: game, fallbackMode: .endlessII).lives, "",
                       "it is not news that an endless run has one ball")

        game.numberOfLives = 2
        XCTAssertEqual(ResumeCard.lines(for: game, fallbackMode: .endlessII).lives,
                       "3 balls left",
                       "and it is news when a twist has granted more")
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
        XCTAssertEqual(lines.mode, GameMode.daily.name + "\n"
                       + DailyChallengeSession.shared.displayName(forKey: key).capitalized,
                       "**\"Daily Challenge\" and the day, as the pause screen has them** "
                       + "(James, round 341)")

        XCTAssertEqual(lines.detail.components(separatedBy: "\n").count, 1,
                       "what is being played")
        XCTAssertEqual(lines.runKind, "COMPETITION RUN",
                       "and that it counts, on its own line in the pause screen's words "
                       + "(round 341)")
    }

    /// Free play on today's challenge is not a competition run, and says nothing.
    func testTodaysFreePlaySaysNothingAboutCompeting() {
        var game = classicGame()
        game.dailyDateKey = DailyChallengeSession.shared.todayKey
        game.dailyWasScoringAttempt = false

        let lines = ResumeCard.lines(for: game, fallbackMode: .classic)
        XCTAssertFalse(lines.detail.contains("Competition"))
        XCTAssertEqual(lines.detail.components(separatedBy: "\n").count, 1,
                       "what is being played - and nothing else, the day being above it")
        XCTAssertEqual(lines.runKind, "FREE PLAY", "the pause screen's words for it")
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
        XCTAssertEqual(lines.runKind, "", "and a closed day says nothing about competing")
        XCTAssertEqual(lines.detail.components(separatedBy: "\n").count, 1,
                       "what was played, with the day above it, got: \(lines.detail)")
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
        XCTAssertEqual(lines.detail.components(separatedBy: "\n").first,
                       challenge.mode == .classic
                       ? LevelPackSetup().levelNameArray[game.levelNumber]
                       : challenge.mode.name,
                       "the day's own mode or level leads, got: \(lines.detail)")
    }
}

/// The resume card reads like the screens it hands over to.
///
/// **James, round 332's layout notes: "use the same label layout, font size and style as the
/// level intro, pause, game over screens for game mode, game detail, score, score number, balls
/// left. Move giga-ball glowing animation logo up to allow for more space."**
final class ResumeCardMatchesTheInGameScreensTests: XCTestCase {

    private let suite = "GigaBallTests.ResumeCardMatches"

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private func store() -> UserDefaults {
        UserDefaults(suiteName: suite) ?? .standard
    }

    private func splash() -> SplashViewController? {
        let game = SavedGame(
            levelNumber: LevelPackSetup().startLevelNumber[2] + 3, endLevelNumber: 10,
            packNumber: 2, levelScore: 120, totalScore: 34_210, numberOfLives: 2,
            endlessHeight: 0, numberOfLevels: 10,
            levelTimerValue: 45, packTimerValue: 300,
            deathsPerLevel: 1, deathsPerPack: 3,
            powerUpsGeneratedPerLevel: 4, powerUpsCollectedPerLevel: 2,
            powerUpsGeneratedPerPack: 20, powerUpsCollectedPerPack: 11,
            paddleHitsPerLevel: 33, multiplier: 1.4,
            brickTextures: [], brickColours: [], brickXPositions: [], brickYPositions: [],
            ballProperties: [], fallingPowerUpXPositions: [], fallingPowerUpYPositions: [],
            fallingPowerUps: [], activePowerUps: [], activePowerUpDurations: [],
            activePowerUpTimers: [], activePowerUpMagnitudes: [])
        game.save(to: store())
        store().set(true, forKey: SavedGame.resumeFlagKey)

        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        guard let splash = board.instantiateViewController(withIdentifier: "splashView")
                as? SplashViewController else { return nil }
        splash.defaults = store()
        splash.gameToResume = true
        splash.view.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        splash.view.layoutIfNeeded()
        return splash
    }

    /// The score is a title with the number under it, not a word beside it.
    func testTheScoreIsATitleOverANumber() throws {
        let splash = try XCTUnwrap(self.splash(), "the storyboard no longer has a splashView")
        let text = splash.scoreLabel.attributedText?.string ?? ""
        XCTAssertTrue(text.contains("\n"),
                      "the in-game screens put the word above the number: \(text)")

        var faces: [UIFont] = []
        splash.scoreLabel.attributedText?.enumerateAttribute(
            .font, in: NSRange(location: 0, length: splash.scoreLabel.attributedText!.length)) {
                value, _, _ in
                if let font = value as? UIFont { faces.append(font) }
            }
        XCTAssertEqual(Set(faces.map(\.pointSize)).count, 2,
                       "two sizes, the title's and the number's")
    }

    /// The wordmark floats above the card, pulled towards the middle of the screen.
    ///
    /// Round 336 lifted the storyboard's centred wordmark forty points to make room for the
    /// card. Round 338 took it all the way to the top, where the four screens the game shows
    /// keep theirs. **Round 339 settled it between the two** (James: "keep the Giga-Ball logo
    /// more towards the centre of the screen where possible - it should always sit above",
    /// and "start from the close button and work up rather than the giga-ball logo and working
    /// down"). So it is neither at the top nor at the middle: it is pulled towards the middle
    /// and pushed up by whatever the card needs.
    ///
    /// The launch animation's six frames stay stood down either way, which is the half of
    /// round 338 that survives here.
    func testTheWordmarkFloatsAboveTheCard() throws {
        let splash = try XCTUnwrap(self.splash())
        let drawn = splash.view.subviews
            .flatMap { [$0] + $0.subviews }
            .compactMap { $0 as? UIImageView }
            .filter { $0.isHidden == false && $0.bounds.width > $0.bounds.height*2 }
            .max { $0.bounds.width < $1.bounds.width }
        let logo = try XCTUnwrap(drawn, "the resume card draws no wordmark")
        let place = logo.convert(logo.bounds, to: splash.view)

        let card = splash.resumingLabel.convert(splash.resumingLabel.bounds, to: splash.view)
        XCTAssertLessThanOrEqual(place.maxY, card.minY + 0.5,
                                 "the wordmark must always sit above the card")
        XCTAssertGreaterThan(place.minY, UIViewController.inGameLogoTopInset + 20,
                             "the wordmark is at \(place.minY), back at the top of the screen "
                             + "rather than towards the middle of it")
        XCTAssertTrue(splash.splashScreenLogo1.isHidden,
                      "the launch animation's frames are stood down for a resume, or the "
                      + "screen draws two wordmarks")
    }
}
