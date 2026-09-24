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

/// The store these screens are laid out against: a suite of the tests' own, cleared before and
/// after every test (round 322b). These wrote a real save and the resume flag into the app's
/// standard defaults and put back only the flag - and a killed run did not even do that - so
/// the simulator's installed app was left offering to resume a fixture.
private let resumeCardSuite = "GigaBallTests.ResumeCard"
private func resumeCardStore() -> UserDefaults {
    UserDefaults(suiteName: resumeCardSuite) ?? .standard
}

    /// The bottom of the header band: the mode's badge where there is one, the wordmark where
/// there is not.
///
/// **Round 338 moved the header.** The wordmark used to sit near the middle of this screen
/// and the card hung a measured distance below it; now the wordmark is at the top of the
/// screen with the mode's badge under it, the same as the four screens the resume hands
/// over to. The relationship this caps is still the one round 313 named - how far the card
/// may drift from the furniture above it - so what changes here is where that furniture is,
/// not what is being asserted.
private func headerBottom(_ splash: SplashViewController) -> CGFloat {
    let root = splash.view!
    let badge = splash.view.subviews
        .flatMap { [$0] + $0.subviews }
        .compactMap { $0 as? UIImageView }
        .first { $0.bounds.width == $0.bounds.height && $0.bounds.width > 30 }
    if let badge { return badge.convert(badge.bounds, to: root).maxY }
    return wordmark(splash).maxY
}

/// The wordmark the resume card actually draws.
///
/// Not `splashScreenLogo1`: that is one of the six frames of the launch animation, and a
/// resume stands all six of them down and draws the game's own mark instead (round 338),
/// so asking the hidden frame where the wordmark is gives the launch's answer.
private func wordmark(_ splash: SplashViewController) -> CGRect {
    let root = splash.view!
    let drawn = root.subviews
        .flatMap { [$0] + $0.subviews }
        .compactMap { $0 as? UIImageView }
        .filter { $0.isHidden == false && $0.bounds.width > $0.bounds.height*2 }
        .max { $0.bounds.width < $1.bounds.width }
    guard let drawn else {
        return splash.splashScreenLogo1.convert(splash.splashScreenLogo1.bounds, to: root)
    }
    return drawn.convert(drawn.bounds, to: root)
}

final class ResumeCardRenderTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 393, height: 852)

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
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
        game.save(to: resumeCardStore())
        resumeCardStore().set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.defaults = resumeCardStore()
        splash.gameToResume = true
        splash.view.frame = CGRect(origin: .zero, size: size ?? screen.size)
        splash.view.layoutIfNeeded()
        return splash
    }

    /// The four labels, in the order they are on the screen.
    private func card(_ splash: SplashViewController) -> [UILabel] {
        [splash.packNameLabel, splash.levelNumberLabel,
         splash.resumingLabel, splash.scoreLabel]
        // Top to bottom, in the pause screen's order since round 341: what is being played and
        // where in it, then RESUMING where the pause screen says PAUSED, then the score
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
    /// The card is built from the button up, and sits in the lower half of the screen.
    ///
    /// Round 310: "everything grouped towards the bottom". Round 338 hung it from the header
    /// at the top instead, and round 339 put it back - **James: "start from the close button
    /// and work up rather than the giga-ball logo and working down."** The wordmark floats
    /// above whatever height the card turns out to need.
    func testTheCardIsBuiltFromTheButtonUp() {
        let splash = laidOut(base())
        let top = card(splash).filter { $0.isHidden == false }
            .map { $0.convert($0.bounds, to: splash.view).minY }.min()!
        XCTAssertGreaterThan(top, screen.height*0.40,
                             "the card starts at \(top) of \(screen.height) - it is anchored "
                             + "to the button at the bottom, not to the mark at the top")
    }

    /// The card reads downwards in the pause screen's order, and the button is under all of it.
    ///
    /// **James, round 341: "use the order of information from the pause screen and replicate
    /// it on the resume screen to ensure continuity."** Mode and detail, then the headline,
    /// then the score - which replaces round 310's heading-first order.
    func testTheOrderIsModeDetailHeadingScoreThenTheButton() {
        let splash = laidOut(base())
        let shown = card(splash).filter { $0.isHidden == false }
        XCTAssertEqual(shown.count, 4, "a classic run says all four")

        let tops = shown.map { $0.convert($0.bounds, to: splash.view).minY }
        XCTAssertEqual(tops, tops.sorted(),
                       "mode, detail, heading, score - top to bottom, got \(tops)")

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
    /// The bottom of whatever the stack draws immediately above the score.
    private func lineAboveTheScore(_ splash: SplashViewController) -> CGFloat {
        guard let stack = splash.scoreLabel.superview as? UIStackView,
              let index = stack.arrangedSubviews.firstIndex(of: splash.scoreLabel) else {
            return splash.scoreLabel.frame.minY
        }
        let above = stack.arrangedSubviews[..<index].last { $0.isHidden == false }
        return above?.frame.maxY ?? splash.scoreLabel.frame.minY
    }

    func testHidingTheDetailLineDoesNotCloseTheGapAboveTheScore() {
        let classic = laidOut(base())
        let classicGap = classic.scoreLabel.frame.minY - lineAboveTheScore(classic)

        let endless = laidOut(endlessGame())
        XCTAssertTrue(endless.levelNumberLabel.isHidden,
                      "an endless mode's name has nothing under it")
        let endlessGap = endless.scoreLabel.frame.minY - lineAboveTheScore(endless)
        // Measured from whatever is directly above the score in each case, which since round
        // 339 is the detail line on a classic card and the badge's row on an endless one: the
        // badge sits between the mode's name and the detail line now

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
        let kind = try! XCTUnwrap(
            allLabels(in: daily.view).first { $0.text == "COMPETITION RUN" && !$0.isHidden },
            "the competition line is on the card")
        let kindFrame = kind.convert(kind.bounds, to: daily.view)
        let heading = daily.resumingLabel.convert(daily.resumingLabel.bounds, to: daily.view)
        XCTAssertLessThanOrEqual(kindFrame.maxY, heading.minY + 0.5,
                                 "on its own line above RESUMING, where the pause screen puts it "
                                 + "above PAUSED (round 341)")
        XCTAssertGreaterThan(kindFrame.height, 0)
        XCTAssertGreaterThan(daily.resumingLabel.convert(daily.resumingLabel.bounds,
                                                         to: daily.view).minY, 0,
                             "and the heading is still on the screen")
    }
}

/// The resuming card on a screen much taller than a phone.
///
/// James, round 313: the iPad's "layouts need work with resizing". This screen is the one a
/// resume opens on, and it is where he was standing when he reported the bad resume, so it is
/// the first thing an iPad player sees.
///
/// The card is anchored to the bottom of the screen so it grows upwards however long the
/// detail line runs (round 310: "everything grouped towards the bottom"). On a phone that
/// leaves it a comfortable distance under the wordmark. On a 1366-point iPad the same two
/// anchors put the logo in the middle and the card a third of a screen below it, with nothing
/// in between.
final class ResumeCardOnATallScreenTests: XCTestCase {

    private let phone = CGSize(width: 393, height: 852)
    private let iPadPortrait = CGSize(width: 1024, height: 1366)
    private let iPadLandscape = CGSize(width: 1366, height: 1024)

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func game() -> SavedGame {
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

    private func laidOut(in size: CGSize) -> SplashViewController {
        game().save(to: resumeCardStore())
        resumeCardStore().set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.defaults = resumeCardStore()
        splash.gameToResume = true
        splash.view.frame = CGRect(origin: .zero, size: size)
        splash.view.layoutIfNeeded()
        return splash
    }

    /// How far the top of the card sits below the bottom of the wordmark.
    private func drop(_ splash: SplashViewController) -> CGFloat {
        let root = splash.view!
        let card = splash.resumingLabel.convert(splash.resumingLabel.bounds, to: root)
        return card.minY - headerBottom(splash)
    }



    /// The wordmark is six stacked frames, and the resume screen lifts it.
    ///
    /// Found by looking at the simulator after round 336: the lift moved the frame it was
    /// written against and left the other five behind, so the finished, lit word sat forty
    /// points below a ghost of its own outline. Every frame is the same word in the same
    /// place; nothing may move one of them alone.
    func testEveryFrameOfTheWordmarkIsLiftedTogether() {
        let splash = laidOut(in: phone)
        let root = splash.view!
        let frames = [splash.splashScreenLogo1, splash.splashScreenLogo2, splash.splashScreenLogo3,
                      splash.splashScreenLogo4, splash.splashScreenLogo5, splash.splashScreenLogo6]
            .compactMap { $0 }
        XCTAssertEqual(frames.count, 6)
        let first = frames[0].convert(frames[0].bounds, to: root)
        for frame in frames.dropFirst() {
            let here = frame.convert(frame.bounds, to: root)
            XCTAssertEqual(here.minY, first.minY, accuracy: 0.5,
                           "a frame of the wordmark has been left behind by the resume lift")
            XCTAssertEqual(here.minX, first.minX, accuracy: 0.5)
        }
    }

    /// The lines the card is made of, found rather than named: three of the five labels are
    /// private to the screen, and what this test is about is the shape of the block.
    private func cardLines(_ splash: SplashViewController) -> [UILabel] {
        guard let stack = splash.resumingLabel.superview as? UIStackView else {
            return [splash.resumingLabel]
        }
        return stack.arrangedSubviews.compactMap { $0 as? UILabel }
    }

    /// Every line of the card is on the screen, with the button clear of it.
    func testTheWholeCardFitsUnderItsHeader() {
        for size in [phone, CGSize(width: 320, height: 568), iPadPortrait] {
            let splash = laidOut(in: size)
            let root = splash.view!
            let lines = cardLines(splash).filter { $0.isHidden == false }
                .map { $0.convert($0.bounds, to: root) }
            guard let lowest = lines.map({ $0.maxY }).max() else { continue }
            XCTAssertLessThan(lowest, size.height,
                              "\(size): the card runs off the bottom of the screen")

            guard let button = root.subviews.flatMap({ [$0] + $0.subviews })
                .compactMap({ $0 as? UIButton }).first(where: { $0.isHidden == false })
            else { continue }
            let place = button.convert(button.bounds, to: root)
            XCTAssertLessThanOrEqual(lowest, place.minY + 0.5,
                                     "\(size): the last line of the card is drawn into the "
                                     + "button - round 338's render has \"3 balls left\" "
                                     + "half behind the disc on a 320 by 568 phone")
        }
    }

    func testTheCardStaysWithTheLogoOnAnIPad() throws {
        for size in [iPadPortrait, iPadLandscape] {
            let splash = laidOut(in: size)
            let badge = try XCTUnwrap(everyImageView(in: splash.view)
                .first { $0.isHidden == false && $0.bounds.width == $0.bounds.height
                            && $0.bounds.width > 30 })
            let card = badge.convert(badge.bounds, to: splash.view)
                .insetBy(dx: 0, dy: -SplashViewController.badgeRowInset)
            // The top of the card, which is its badge since round 341 put the card in the pause
            // screen's order - RESUMING used to be the first line and is now under the title block
            XCTAssertLessThanOrEqual(card.minY,
                                     size.height/2 + SplashViewController.resumeCardMaximumDrop + 1,
                                     "\(size): four lines and a button a third of a screen "
                                     + "below everything else read as two screens, not one card")
        }
    }

    /// The mode's badge is on this screen at all, and it heads the card.
    ///
    /// Round 338 put it here for the first time: this was the only one of the five screens
    /// that named the mode in words alone, so a Mayhem run was resumed from a card with no
    /// badge into a countdown and then a pause screen wearing one.
    ///
    /// **Over the name, as the pause screen has it** (James, round 341: "use the order of
    /// information from the pause screen and replicate it on the resume screen to ensure
    /// continuity"). Round 339 had put it under the name, when RESUMING was the card's heading;
    /// RESUMING now sits where PAUSED does, so the badge heads the card as it heads that screen.
    func testTheBadgeHeadsTheCardAsOnThePauseScreen() throws {
        let splash = laidOut(in: phone)
        let root = splash.view!
        let discs = everyImageView(in: root)
            .filter { $0.isHidden == false && $0.bounds.width == $0.bounds.height
                        && $0.bounds.width > 30 }
        let disc = try XCTUnwrap(discs.first, "the resume card has no mode badge")

        let place = disc.convert(disc.bounds, to: root)
        let name = splash.packNameLabel.convert(splash.packNameLabel.bounds, to: root)
        let heading = splash.resumingLabel.convert(splash.resumingLabel.bounds, to: root)
        XCTAssertLessThanOrEqual(place.maxY, name.minY + 0.5,
                                 "the badge heads the card, over what is being played")
        XCTAssertLessThan(place.maxY, heading.minY, "and over RESUMING")
        XCTAssertLessThan(place.minY, root.bounds.height,
                          "and on the screen")
    }

    private func everyImageView(in view: UIView) -> [UIImageView] {
        view.subviews.flatMap { [$0 as? UIImageView].compactMap { $0 } + everyImageView(in: $0) }
    }

    /// It still sits low rather than centred, which is the arrangement James asked for.
    /// And the button is still at the bottom, where a thumb expects it.
    ///
    /// The other half of round 310's "everything grouped towards the bottom": the card moved
    /// up to its header in round 338, the button did not move at all.
    func testTheButtonIsStillAtTheBottom() {
        let splash = laidOut(in: iPadPortrait)
        let root = splash.view!
        guard let button = root.subviews.flatMap({ [$0] + $0.subviews })
            .compactMap({ $0 as? UIButton }).first(where: { $0.isHidden == false }) else {
            return XCTFail("the resume card has no button")
        }
        let place = button.convert(button.bounds, to: root)
        XCTAssertGreaterThan(place.minY, root.bounds.height*0.75,
                             "the close button has come up off the bottom of the screen")

        let card = splash.resumingLabel.convert(splash.resumingLabel.bounds, to: root)
        XCTAssertLessThan(card.maxY, place.minY,
                          "the card is drawn into the button")
    }

    /// And the lines do not run the full width of a 13-inch iPad.
    func testTheLinesDoNotRunTheWidthOfTheScreen() {
        let splash = laidOut(in: iPadLandscape)
        let root = splash.view!
        let card = splash.resumingLabel.convert(splash.resumingLabel.bounds, to: root)
        XCTAssertLessThanOrEqual(card.width,
                                 SplashViewController.resumeCardMaximumWidth + 1)
        XCTAssertLessThan(card.width, root.bounds.width/2)
    }
}

/// The two faces the resume card's score line is set in.
///
/// **James, round 340: "the score heading font is a bit too large."** It was eighteen points
/// too large, and not because of the number chosen for it. `UILabel.attributedText` is never
/// nil: before the card's own score line is built, the label answers with the storyboard's
/// plain text wearing the storyboard's 35-point face, and the pass that remembers each run's
/// natural size so it can scale the line for the screen was filing that 35 as the heading's.
/// From then on every screen drew a 35-point heading over a 30-point number.
///
/// Measured as a proportion rather than as two point sizes, because the line is scaled for the
/// screen it is on and the proportion is the thing that was wrong.
final class ResumeScoreLineFacesTests: XCTestCase {

    private let shapes: [(String, CGSize)] = [
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874)),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376)),
        ("smallest window", SceneDelegate.smallestWindow),
    ]

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: resumeCardSuite)
        super.tearDown()
    }

    private func laidOut(in size: CGSize) -> SplashViewController {
        let game = SavedGame(
            levelNumber: LevelPackSetup().startLevelNumber[2] + 2, endLevelNumber: 10,
            packNumber: 2, levelScore: 4300, totalScore: 15_200, numberOfLives: 2,
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
        game.save(to: resumeCardStore())
        resumeCardStore().set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.defaults = resumeCardStore()
        splash.gameToResume = true
        splash.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            splash.view.setNeedsLayout()
            splash.view.layoutIfNeeded()
        }
        return splash
    }

    /// The heading is read against the number under it, and it is the smaller of the two.
    func testTheHeadingIsSmallerThanTheNumberOnEveryScreen() throws {
        let wanted = SplashViewController.scoreTitleFace.pointSize
            / SplashViewController.scoreFace.pointSize
        XCTAssertLessThan(wanted, 1, "the heading is set larger than the number it titles")

        for (name, size) in shapes {
            let splash = laidOut(in: size)
            let text = try XCTUnwrap(splash.scoreLabel.attributedText)
            var faces: [CGFloat] = []
            text.enumerateAttribute(.font, in: NSRange(location: 0, length: text.length)) {
                value, _, _ in
                if let font = value as? UIFont { faces.append(font.pointSize) }
            }
            XCTAssertEqual(faces.count, 2,
                           "\(name): the score line should be a heading and a number, and it is "
                           + "\(faces.count) faces - which is what assigning `font` to a label "
                           + "holding attributed text does to it")
            let heading = try XCTUnwrap(faces.first)
            let number = try XCTUnwrap(faces.last)
            XCTAssertLessThan(heading, number,
                              "\(name): the heading is \(heading)pt over a \(number)pt number")
            XCTAssertEqual(heading/number, wanted, accuracy: 0.06,
                           "\(name): the heading is \(heading)pt and the number \(number)pt, a "
                           + "proportion of \(heading/number) rather than \(wanted) - the sizes "
                           + "remembered for scaling came from a line other than this one")
        }
    }
}

/// Every label under a view, however deep.
private func allLabels(in view: UIView) -> [UILabel] {
    view.subviews.flatMap { sub -> [UILabel] in
        (sub as? UILabel).map { [$0] } ?? [] + allLabels(in: sub)
    }
}
