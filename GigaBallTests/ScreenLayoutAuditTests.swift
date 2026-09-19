//
//  ScreenLayoutAuditTests.swift
//  GigaBallTests
//
//  James, round 329: "review the layouts of the in-game pause, completion, game over, splash,
//  in between level screens - make sure the information is well laid out, there is continuity
//  between the screens, there is no clipping or overlapping across all the different game
//  modes."
//
//  Looking at them is how the fault is recognised; this is how it is *found*. Every one of these
//  screens is the same storyboard scene wearing a different set of answers - a pause, a game
//  over and a completion differ by which labels carry text - so a fault in one mode's version is
//  invisible in the others and nobody screenshots all twenty combinations. The rules asserted
//  here are the three a person would look for: nothing off the screen, nothing on top of
//  anything else, and nothing squashed to nothing.
//

import XCTest
import UIKit
@testable import Giga_Ball

private extension UILabel {

    /// Where the letters actually are, rather than where the label is.
    ///
    /// **A line of text is taller than its letters.** UIKit lays out a line box that runs from
    /// the font's ascender to its descender, and the capital letters occupy only the middle of
    /// it - so two labels stacked as tightly as a designer would stack them have line boxes
    /// that overlap by a few points while nothing a player can see is touching. The first run
    /// of this audit reported a four to five point overlap between every title and its own
    /// value on every screen at every size, and measuring the drawn text rather than the label
    /// only shrank the number: a line box is a line box wherever it is measured.
    ///
    /// So this trims each line box down to the band the ink is in - off the top, the leading
    /// above the capitals; off the bottom, the descender space. What is left is what a person
    /// would point at and call the text. Two of those meeting is a fault; two line boxes
    /// meeting is a layout with tight leading, which is most layouts.
    var inkRect: CGRect {
        let box = textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        guard let font else { return box }
        let above = max(0, font.ascender - font.capHeight)
        let below = max(0, -font.descender)
        guard box.height > above + below + 1 else { return box }
        return box.inset(by: UIEdgeInsets(top: above, left: 0, bottom: below, right: 0))
    }
}

final class ScreenLayoutAuditTests: XCTestCase {

    /// The shapes worth checking: the smallest phone the app supports, two current phones, a
    /// 13-inch iPad, and an iPad Slide Over - which is narrower than any phone and as tall as
    /// the iPad.
    private let sizes: [(name: String, size: CGSize)] = [
        ("iPhone SE", CGSize(width: 320, height: 568)),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874)),
        ("iPhone 17 Pro Max", CGSize(width: 440, height: 956)),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376)),
        ("Slide Over", CGSize(width: 320, height: 1024)),
    ]

    private var screens: [UIViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        screens.removeAll()
        super.tearDown()
    }

    // MARK: - Reading a laid-out screen

    /// Every label a player can actually read: on screen, not hidden, not transparent, and
    /// carrying text. A hidden label is a label this state does not use, and the storyboard is
    /// full of them by design.
    private func readableLabels(in root: UIView) -> [(label: UILabel, frame: CGRect)] {
        var found: [(UILabel, CGRect)] = []
        func walk(_ view: UIView, visible: Bool) {
            let showing = visible && view.isHidden == false && view.alpha > 0.05
            if showing, let label = view as? UILabel,
               let text = label.text, text.isEmpty == false,
               label.bounds.width > 0, label.bounds.height > 0 {
                found.append((label, label.convert(label.inkRect, to: root)))
            }
            for subview in view.subviews { walk(subview, visible: showing) }
        }
        walk(root, visible: true)
        return found.map { (label: $0.0, frame: $0.1) }
    }

    private func describe(_ label: UILabel) -> String {
        let text = label.text ?? ""
        return text.count > 24 ? String(text.prefix(24)) + "..." : text
    }

    /// The three rules, asked of any screen in any state.
    private func audit(_ screen: UIViewController, _ what: String, _ where_: String) {
        let root = screen.view!
        let labels = readableLabels(in: root)
        XCTAssertFalse(labels.isEmpty, "\(what) on \(where_) shows no text at all")

        for (label, frame) in labels {
            XCTAssertGreaterThanOrEqual(frame.minX, -0.5,
                "\(what) on \(where_): '\(describe(label))' runs off the left edge")
            XCTAssertLessThanOrEqual(frame.maxX, root.bounds.width + 0.5,
                "\(what) on \(where_): '\(describe(label))' runs off the right edge")
            XCTAssertGreaterThanOrEqual(frame.minY, -0.5,
                "\(what) on \(where_): '\(describe(label))' is above the top of the screen")
            XCTAssertLessThanOrEqual(frame.maxY, root.bounds.height + 0.5,
                "\(what) on \(where_): '\(describe(label))' is below the bottom of the screen")
        }

        for (index, first) in labels.enumerated() {
            for second in labels.dropFirst(index + 1) {
                let overlap = first.frame.intersection(second.frame)
                guard overlap.isNull == false else { continue }
                // A point or a hairline of shared edge is rounding, not an overlap
                guard overlap.width > 1, overlap.height > 1 else { continue }
                XCTFail("\(what) on \(where_): '\(describe(first.label))' and "
                        + "'\(describe(second.label))' overlap by "
                        + "\(Int(overlap.width))x\(Int(overlap.height))pt")
            }
        }
    }

    // MARK: - The pause screen, in every state it has

    private func pauseScreen(sender: String, mode: GameMode, size: CGSize)
        -> PauseMenuViewController? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let pause = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController else { return nil }
        pause.sender = sender
        pause.gameoverBool = sender == "Game Over"
        pause.endlessMode = mode == .endless || mode == .endlessII
        pause.levelNumber = mode == .classic ? 3 : 0
        pause.numberOfLevels = mode == .classic ? 10 : 1
        pause.packNumber = 2
        pause.score = 12_340
        pause.height = 478
        pause.totalStatsArray = [TotalStats()]
        screens.append(pause)
        pause.loadViewIfNeeded()
        pause.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            pause.view.setNeedsLayout()
            pause.view.layoutIfNeeded()
        }
        return pause
    }

    func testThePauseScreenIsTidyInEveryModeAndSize() throws {
        for (deviceName, size) in sizes {
            for mode in [GameMode.classic, .endless, .endlessII] {
                let screen = try XCTUnwrap(pauseScreen(sender: "Pause", mode: mode, size: size))
                audit(screen, "Paused, \(mode)", deviceName)
            }
        }
    }

    func testTheGameOverScreenIsTidyInEveryModeAndSize() throws {
        for (deviceName, size) in sizes {
            for mode in [GameMode.classic, .endless, .endlessII] {
                let screen = try XCTUnwrap(pauseScreen(sender: "Game Over", mode: mode,
                                                       size: size))
                audit(screen, "Game over, \(mode)", deviceName)
            }
        }
    }

    func testTheLevelCompleteScreenIsTidyAtEverySize() throws {
        for (deviceName, size) in sizes {
            let screen = try XCTUnwrap(pauseScreen(sender: "Complete", mode: .classic,
                                                   size: size))
            audit(screen, "Level complete", deviceName)
        }
    }

    /// A daily wears the same screens with a twist row and no replay, which is the state most
    /// likely to be laid out for the wrong mode.
    func testTheDailysPauseAndGameOverAreTidy() throws {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "2026-09-20", mode: .endlessII, classicLevel: nil,
            twists: [.fogOfWar, .oneLife])
        for (deviceName, size) in sizes {
            for sender in ["Pause", "Game Over"] {
                let screen = try XCTUnwrap(pauseScreen(sender: sender, mode: .endlessII,
                                                       size: size))
                audit(screen, "Daily \(sender)", deviceName)
            }
        }
    }

    // MARK: - Between levels

    private func betweenLevels(size: CGSize) -> InbetweenViewController? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screens.append(screen)
        screen.loadViewIfNeeded()
        screen.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        return screen
    }

    // MARK: - The resume card, for each kind of run

    private static let auditSuite = "GigaBallTests.ScreenLayoutAudit"

    private func auditStore() -> UserDefaults {
        UserDefaults(suiteName: ScreenLayoutAuditTests.auditSuite) ?? .standard
    }

    /// A saved run of each kind, which is what decides how many lines the card carries - and
    /// the card growing a line is how it gets too tall for a small phone.
    private func savedRun(mode: GameMode) -> SavedGame {
        var game = SavedGame(
            levelNumber: mode == .classic ? LevelPackSetup().startLevelNumber[2] + 3 : 0,
            endLevelNumber: 10, packNumber: 2, levelScore: 120, totalScore: 34_210,
            numberOfLives: 2, endlessHeight: mode == .classic ? 0 : 1_284,
            numberOfLevels: mode == .classic ? 10 : 1,
            levelTimerValue: 45, packTimerValue: 300, deathsPerLevel: 1, deathsPerPack: 3,
            powerUpsGeneratedPerLevel: 4, powerUpsCollectedPerLevel: 2,
            powerUpsGeneratedPerPack: 20, powerUpsCollectedPerPack: 11,
            paddleHitsPerLevel: 33, multiplier: 1.4,
            brickTextures: [], brickColours: [], brickXPositions: [], brickYPositions: [],
            ballProperties: [], fallingPowerUpXPositions: [], fallingPowerUpYPositions: [],
            fallingPowerUps: [], activePowerUps: [], activePowerUpDurations: [],
            activePowerUpTimers: [], activePowerUpMagnitudes: [])
        game.gameMode = mode.rawValue
        return game
    }

    private func resumeCard(mode: GameMode, size: CGSize) -> SplashViewController {
        let store = auditStore()
        savedRun(mode: mode).save(to: store)
        store.set(true, forKey: SavedGame.resumeFlagKey)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        let splash = board.instantiateViewController(withIdentifier: "splashView")
            as! SplashViewController
        splash.defaults = store
        splash.gameToResume = true
        screens.append(splash)
        splash.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            splash.view.setNeedsLayout()
            splash.view.layoutIfNeeded()
        }
        return splash
    }

    func testTheResumeCardIsTidyForEveryKindOfRun() {
        defer { UserDefaults().removePersistentDomain(forName: ScreenLayoutAuditTests.auditSuite) }
        for (deviceName, size) in sizes {
            for mode in [GameMode.classic, .endless, .endlessII] {
                audit(resumeCard(mode: mode, size: size), "Resume, \(mode)", deviceName)
            }
        }
    }

    /// And the splash with nothing to resume, which is what most launches show.
    ///
    /// The resume card is the interesting half of this screen and the reason the audit came
    /// here, but James's list said "splash" rather than "the resume card" - and the plain one
    /// carries its own furniture: the logo, the version, the play button's label and whatever
    /// the day has to say. It costs one more pass to know that all of it fits on an iPhone SE
    /// and in a Slide Over.
    func testTheSplashIsTidyWithNothingToResume() {
        defer { UserDefaults().removePersistentDomain(forName: ScreenLayoutAuditTests.auditSuite) }
        for (deviceName, size) in sizes {
            let store = auditStore()
            store.set(false, forKey: SavedGame.resumeFlagKey)
            let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
            let splash = board.instantiateViewController(withIdentifier: "splashView")
                as! SplashViewController
            splash.defaults = store
            splash.gameToResume = false
            screens.append(splash)
            splash.view.frame = CGRect(origin: .zero, size: size)
            splash.beginAppearanceTransition(true, animated: false)
            splash.endAppearanceTransition()
            // **The credit fades in rather than being there**, so a splash that is only loaded
            // has nothing on it to measure: every label on this screen starts at alpha zero and
            // is brought up in `viewDidAppear`. Driving the appearance is what puts the screen
            // into the state a player sees
            for _ in 0..<3 {
                splash.view.setNeedsLayout()
                splash.view.layoutIfNeeded()
            }
            audit(splash, "Splash", deviceName)
        }
    }

    func testTheBetweenLevelsScreenIsTidyAtEverySize() throws {
        for (deviceName, size) in sizes {
            guard let screen = betweenLevels(size: size) else {
                XCTFail("the storyboard no longer has an inbetweenView")
                return
            }
            audit(screen, "Between levels", deviceName)
        }
    }
}
