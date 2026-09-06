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
    private func laidOut(_ game: SavedGame,
                         in size: CGSize? = nil) -> SplashViewController {
        game.save(to: UserDefaults.standard)
        UserDefaults.standard.set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.gameToResume = true
        splash.view.frame = CGRect(origin: .zero, size: size ?? screen.size)
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

    /// Writes the three cards out as PNGs so they can be looked at.
    ///
    /// Not an assertion - a render. The project's rule is that visual work gets verified on the
    /// simulator, and this screen is only reachable by force-quitting a game, so the cheapest
    /// way to see all three cases is to draw them. Run it on an iOS 26 device to see the glass
    /// button the way a player does.
    func testWriteTheThreeCardsOutToBeLookedAt() {
        var daily = base()
        daily.dailyDateKey = DailyChallengeSession.shared.todayKey
        daily.dailyWasScoringAttempt = true

        for (name, game) in [("classic", base()), ("endless", endlessGame()), ("daily", daily)] {
            let splash = laidOut(game)
            splash.view.setNeedsLayout()
            splash.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: splash.view.bounds)
            let png = renderer.image { _ in
                splash.view.drawHierarchy(in: splash.view.bounds, afterScreenUpdates: true)
            }.pngData()!
            try? png.write(to: URL(fileURLWithPath: "/tmp/gb2-\(name).png"))
            print("SHOT \(name)")
        }
    }

    // MARK: - Everything at the bottom

    /// "With everything grouped towards the bottom."
    func testTheWholeCardSitsInTheBottomThirdOfTheScreen() {
        let splash = laidOut(base())
        let top = card(splash).filter { $0.isHidden == false }
            .map { $0.convert($0.bounds, to: splash.view).minY }.min()!
        XCTAssertGreaterThan(top, screen.height * 0.55,
                             "the heading starts in the bottom half, so the logo above it has "
                             + "the room it has always had")
        // 0.55 rather than 0.6 since round 311 gave the card its four groups of air: the block
        // is taller by design now, and the assertion is about it being *grouped at the bottom*
        // rather than about a line it must not cross
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

    /// **The button is the app's plain close button, not its confirm button** (James, round
    /// 311: "the close button shouldn't be coloured. It should be a big version of the other
    /// close / back buttons in the app").
    ///
    /// Round 310 built it `rimmed: true`, which is the lime prominent tint the app gives the
    /// *positive* action in a row - the play, the confirm. Cancelling a resume is not that.
    ///
    /// Asserted on the pale-disc fallback, which is what every close button in the app paints
    /// before `applyRoundGlass` puts glass over it on iOS 26 - the same two colours as the
    /// music screen's and the run-stats screen's, and nothing lime anywhere.
    func testTheButtonWearsTheSameColoursAsEveryOtherCloseButton() {
        let splash = laidOut(base())
        let button = try! XCTUnwrap(disc(splash))

        var white: CGFloat = 0, alpha: CGFloat = 0
        XCTAssertTrue(button.backgroundColor?.getWhite(&white, alpha: &alpha) ?? false,
                      "the pale disc is a grey, as the other close buttons paint it")
        XCTAssertEqual(white, 0.92, accuracy: 0.01)

        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, a: CGFloat = 0
        button.tintColor.getRed(&red, green: &green, blue: &blue, alpha: &a)
        XCTAssertEqual(red, 0.16, accuracy: 0.01, "the app's deep purple")
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.24, accuracy: 0.01)
        XCTAssertFalse(green > 0.9 && red > 0.7 && blue < 0.2,
                       "and emphatically not the lime that means confirm")
    }

    /// **Nothing from the storyboard still has an opinion about the card's labels** (round 312).
    ///
    /// Found in James's iPad log, not by looking:
    ///
    ///     V:[UILabel]-(10)-[UILabel]                    the storyboard's chain
    ///     'UISV-spacing' V:[UILabel]-(14)-[UILabel]     the stack's
    ///
    /// Putting a view into a stack reparents it, and a constraint naming a view that has left
    /// its superview dies with it - which is why this looked finished. But these name *two* of
    /// the card's labels, and all four moved together into a stack that is a child of the same
    /// container, so nothing was orphaned and nothing was retired. UIKit breaks one of the pair
    /// to recover, and on the device it broke the stack's: the four groups of air were being
    /// drawn at the old spacing.
    ///
    /// **Asserted structurally rather than by measuring the gaps**, because which of two
    /// conflicting constraints UIKit breaks is not something to rely on - the simulator resolved
    /// it the other way, which is exactly why every render test agreed with itself and the phone
    /// still looked wrong.
    func testTheStoryboardKeepsNoConstraintsOnTheCardsLabels() {
        let splash = laidOut(base())
        let container = try! XCTUnwrap(splash.resumingLabel.superview?.superview,
                                       "the stack's own superview is the storyboard container")
        let carded = card(splash)

        let leftovers = container.constraints.filter { constraint in
            let first = constraint.firstItem as? UIView
            let second = constraint.secondItem as? UIView
            return carded.contains { $0 === first || $0 === second }
        }
        XCTAssertTrue(leftovers.isEmpty,
                      "the stack owns this card's spacing and alignment now, and a second "
                      + "opinion is resolved by UIKit breaking one of them silently: "
                      + leftovers.map(\.description).joined(separator: "\n"))
    }

    /// The table view that used to be the Cancel row is gone, not merely hidden - a hidden view
    /// keeps its frame, and 70 points of it sat in the middle of the new layout.
    func testTheOldCancelRowIsOutOfTheHierarchy() {
        let splash = laidOut(base())
        XCTAssertNil(splash.cancelResumeButton.superview,
                     "removed rather than hidden")
    }

    /// **The card still fits the smallest window the app allows** (round 311).
    ///
    /// Two changes this round pull against each other: the card grew a group of air between each
    /// of its four parts, and the iPad floor came down from 420x640 to 320x568. Either alone is
    /// fine. Together they are the shape of a bug that would only ever be seen by somebody
    /// resuming a game in a small window on an iPad, which is nobody until it is somebody.
    func testTheWholeCardFitsTheSmallestWindowTheAppAllows() {
        var daily = base()
        daily.dailyDateKey = DailyChallengeSession.shared.todayKey
        daily.dailyWasScoringAttempt = true
        // The tallest of the three: mode, what is being played, the day, the competition line,
        // the score and the rack

        let small = SceneDelegate.smallestWindow
        let splash = laidOut(daily, in: small)

        let button = try! XCTUnwrap(disc(splash))
        let parts = card(splash).filter { $0.isHidden == false } + [button]
        for part in parts {
            let frame = part.convert(part.bounds, to: splash.view)
            XCTAssertGreaterThanOrEqual(frame.minY, 0,
                                        "\(part) has been pushed off the top at \(small)")
            XCTAssertLessThanOrEqual(frame.maxY, small.height,
                                     "\(part) hangs off the bottom at \(small)")
            XCTAssertGreaterThanOrEqual(frame.minX, 0)
            XCTAssertLessThanOrEqual(frame.maxX, small.width)
        }
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

        XCTAssertGreaterThan(endlessGap, SplashViewController.groupGap - 1,
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
