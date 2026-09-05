//
//  ResumeCardRenderTests.swift
//  GigaBallTests
//
//  Where the resuming screen puts things, round 310.
//
//  James: "Keep the spacing and style similar to the pause / end of game menu, but with
//  everything grouped towards the bottom."
//
//  The words are checked in `ResumeCardTests`; this is the arrangement. It exists because
//  hiding the detail line in the endless modes silently took the air above the score with it -
//  a stack view skips the custom spacing that follows a hidden arranged subview, so "1284m" sat
//  jammed under "Endless Mayhem". Nothing failed; it just looked wrong, and the only way to see
//  this screen by hand is to force-quit a game and relaunch.
//

import XCTest
import UIKit
@testable import Giga_Ball

final class ResumeCardRenderTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 393, height: 852)

    override func tearDown() {
        UserDefaults.standard.set(false, forKey: SavedGame.resumeFlagKey)
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    // MARK: - Fixtures

    private func base() -> SavedGame {
        SavedGame(
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
    }

    private func endlessGame() -> SavedGame {
        var game = base()
        game.levelNumber = 0
        game.numberOfLevels = 1
        game.endlessHeight = 1_284
        game.gameMode = GameMode.endlessII.rawValue
        return game
    }

    /// The screen, laid out, exactly as a relaunch into a saved run builds it.
    private func laidOut(_ game: SavedGame) -> SplashViewController {
        game.save(to: UserDefaults.standard)
        UserDefaults.standard.set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.gameToResume = true
        splash.view.frame = screen
        splash.view.layoutIfNeeded()
        return splash
    }

    /// The four labels, in the order they are on the screen.
    private func card(_ splash: SplashViewController) -> [UILabel] {
        [splash.resumingLabel, splash.packNameLabel,
         splash.levelNumberLabel, splash.scoreLabel]
    }

    private func disc(_ splash: SplashViewController) -> UIButton? {
        func search(_ view: UIView) -> UIButton? {
            for child in view.subviews {
                if let button = child as? UIButton { return button }
                if let found = search(child) { return found }
            }
            return nil
        }
        return search(splash.view)
    }

    // MARK: - Everything at the bottom

    /// "With everything grouped towards the bottom."
    func testTheWholeCardSitsInTheBottomThirdOfTheScreen() {
        let splash = laidOut(base())
        let top = card(splash).filter { $0.isHidden == false }
            .map { $0.convert($0.bounds, to: splash.view).minY }.min()!
        XCTAssertGreaterThan(top, screen.height * 0.6,
                             "the heading starts below the two-thirds line, so the logo above "
                             + "it has the room it has always had")
    }

    /// "Move the Resuming... label to just above the cancel button" - the card reads downwards
    /// in the order James listed it, and the button is under all of it.
    func testTheOrderIsHeadingModeDetailScoreThenTheButton() {
        let splash = laidOut(base())
        let shown = card(splash).filter { $0.isHidden == false }
        XCTAssertEqual(shown.count, 4, "a classic run says all four")

        let tops = shown.map { $0.convert($0.bounds, to: splash.view).minY }
        XCTAssertEqual(tops, tops.sorted(),
                       "heading, mode, detail, score - top to bottom, got \(tops)")

        let button = try! XCTUnwrap(disc(splash))
        let discFrame = button.convert(button.bounds, to: splash.view)
        let lowestLabel = shown.map { $0.convert($0.bounds, to: splash.view).maxY }.max()!
        XCTAssertGreaterThan(discFrame.minY, lowestLabel,
                             "the button is under the score, not beside it")
    }

    /// "Make the cancel button a big round x button in the centre at the bottom."
    func testTheButtonIsTheAppsLargeRoundOneCentredAtTheBottom() {
        let splash = laidOut(base())
        let button = try! XCTUnwrap(disc(splash))
        let frame = button.convert(button.bounds, to: splash.view)

        XCTAssertEqual(frame.width, MainMenuCollectionViewCell.largeButtonSize,
                       "the same disc every menu's centre button wears")
        XCTAssertEqual(frame.height, frame.width, "round, so square before the radius")
        XCTAssertEqual(button.layer.cornerRadius, frame.width/2, accuracy: 0.01)
        XCTAssertEqual(frame.midX, screen.midX, accuracy: 0.5, "centred")
        XCTAssertGreaterThan(frame.maxY, screen.height - 120,
                             "at the bottom, roughly where the Cancel capsule used to sit")
        XCTAssertLessThan(frame.maxY, screen.height,
                          "and on the screen rather than off the end of it")
    }

    /// The table view that used to be the Cancel row is gone, not merely hidden - a hidden view
    /// keeps its frame, and 70 points of it sat in the middle of the new layout.
    func testTheOldCancelRowIsOutOfTheHierarchy() {
        let splash = laidOut(base())
        XCTAssertNil(splash.cancelResumeButton.superview,
                     "removed rather than hidden")
    }

    // MARK: - The gap the endless modes lost

    /// An endless mode has nothing under its name to say, and the score still gets its air.
    ///
    /// The bug this was written for: `setCustomSpacing(_:after:)` is skipped when the view it
    /// names is hidden, so hiding the detail line closed the gap above the score.
    func testHidingTheDetailLineDoesNotCloseTheGapAboveTheScore() {
        let classic = laidOut(base())
        let classicGap = classic.scoreLabel.frame.minY - classic.levelNumberLabel.frame.maxY

        let endless = laidOut(endlessGame())
        XCTAssertTrue(endless.levelNumberLabel.isHidden,
                      "an endless mode's name has nothing under it")
        let endlessGap = endless.scoreLabel.frame.minY - endless.packNameLabel.frame.maxY

        XCTAssertGreaterThan(endlessGap, 8,
                             "the height must not sit jammed under the mode's name")
        XCTAssertEqual(endlessGap, classicGap, accuracy: 1,
                       "and it is the same gap the classic card puts above its score")
    }

    /// A daily's detail runs to two lines, and the card grows upwards rather than off the
    /// bottom - the button is pinned and everything hangs off it.
    func testATwoLineDetailPushesTheCardUpwardsAndNotOffTheBottom() {
        var game = base()
        game.dailyDateKey = DailyChallengeSession.shared.todayKey
        game.dailyWasScoringAttempt = true
        let daily = laidOut(game)

        let button = try! XCTUnwrap(disc(daily))
        let discFrame = button.convert(button.bounds, to: daily.view)
        let plain = laidOut(base())
        let plainDisc = try! XCTUnwrap(disc(plain)).convert(
            try! XCTUnwrap(disc(plain)).bounds, to: plain.view)

        XCTAssertEqual(discFrame.minY, plainDisc.minY, accuracy: 0.5,
                       "the button does not move when the detail gets longer")
        XCTAssertGreaterThan(daily.levelNumberLabel.frame.height,
                             plain.levelNumberLabel.frame.height,
                             "the competition line is a second line, so the label is taller")
        XCTAssertGreaterThan(daily.resumingLabel.convert(daily.resumingLabel.bounds,
                                                         to: daily.view).minY, 0,
                             "and the heading is still on the screen")
    }
}
