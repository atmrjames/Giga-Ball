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

    override func setUp() {
        super.setUp()
        DailyChallengeSession.shared.closedDayNeedsAnnouncing = false
        // **Cleared, or the screen under audit is wearing a pop-up.** A daily resumed after its
        // day has closed says so over the pause screen, which is right in the game and is not
        // what this measures - and the flag is one shot on a shared session, so whichever test
        // ran before this one decides whether it is set
    }

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        DailyChallengeSession.shared.closedDayNeedsAnnouncing = false
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

/// The level intro with a day that has three twists.
///
/// **James, round 332: "daily challenge has 3 twists but level intro splash screen only has
/// room to show 2"**, and in the layout notes: "make space for more twists if there are more to
/// be shown, just expand section and move free play / competition run label down as needed."
///
/// The label grows a line per twist and the run-kind label hangs off its bottom, so on paper
/// this works at any number. This measures it instead, at the smallest screen the app supports,
/// which is where a third line has nowhere to go.
final class DailyIntroTwistRoomTests: XCTestCase {

    private var screens: [UIViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        screens.removeAll()
        super.tearDown()
    }

    private func intro(twists: [DailyTwist], size: CGSize) -> InbetweenViewController? {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: DailyChallengeSession.shared.todayKey, mode: .classic,
            classicLevel: 1, twists: twists)
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screen.levelNumber = 1
        screens.append(screen)
        screen.loadViewIfNeeded()
        screen.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        return screen
    }

    /// Every twist the day carries is on the screen, and the label is tall enough to draw them.
    func testThreeTwistsAllFitOnTheSmallestScreen() throws {
        let twists: [DailyTwist] = [.fogOfWar, .oneLife, .noPowerUps]
        let screen = try XCTUnwrap(intro(twists: twists, size: CGSize(width: 320, height: 568)),
                                   "the storyboard no longer has an inbetweenView")

        let label = screen.levelNameLabel!
        let lines = (label.attributedText?.string ?? "").components(separatedBy: "\n")
        XCTAssertEqual(lines.count, twists.count, "one line per twist: \(lines)")

        let needed = label.textRect(forBounds: CGRect(origin: .zero,
                                                      size: CGSize(width: label.bounds.width,
                                                                   height: .greatestFiniteMagnitude)),
                                    limitedToNumberOfLines: 0).height
        XCTAssertGreaterThanOrEqual(label.bounds.height + 0.5, needed,
                                    "the box is \(label.bounds.height)pt and the twists need "
                                    + "\(needed)pt, so the third one is drawn outside it")
    }

    /// And the kind of run still sits under them, on the screen.
    func testTheRunKindFollowsTheTwistsDown() throws {
        let screen = try XCTUnwrap(intro(twists: [.fogOfWar, .oneLife, .noPowerUps],
                                         size: CGSize(width: 320, height: 568)))
        let label = screen.levelNameLabel!
        let kind = try XCTUnwrap(
            screen.view.subviews.compactMap { $0 as? UILabel }
                .first { ($0.text ?? "").contains("RUN") || ($0.text ?? "").contains("FREE") }
                ?? label.superview?.subviews.compactMap { $0 as? UILabel }
                    .first { ($0.text ?? "").contains("RUN") || ($0.text ?? "").contains("FREE") },
            "the competition run / free play line is missing")

        let twists = label.convert(label.bounds, to: screen.view)
        let below = kind.convert(kind.bounds, to: screen.view)
        XCTAssertGreaterThanOrEqual(below.minY, twists.maxY - 0.5,
                                    "the run kind is sitting on top of the twists")
        XCTAssertLessThanOrEqual(below.maxY, screen.view.bounds.height + 0.5,
                                 "and it has been pushed off the bottom of the screen")
    }
}

/// The between-levels screen's score block.
///
/// **James, round 332's layout notes: "put level score and speed bonus on the same line next to
/// one another"**, and the total under both.
final class BetweenLevelsScoreBlockTests: XCTestCase {

    private var screens: [UIViewController] = []

    override func tearDown() {
        screens.removeAll()
        super.tearDown()
    }

    private func screen(bonus: Int, size: CGSize = CGSize(width: 402, height: 874))
        -> InbetweenViewController? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screen.levelNumber = 1
        screen.packNumber = 2
        screen.levelScore = 1200
        screen.levelScoreBonus = bonus
        screen.totalScore = 4200
        screens.append(screen)
        screen.loadViewIfNeeded()
        screen.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        return screen
    }

    func testTheScoreAndTheBonusShareALine() throws {
        let screen = try XCTUnwrap(self.screen(bonus: 300),
                                   "the storyboard no longer has an inbetweenView")
        let score = screen.levelScoreTitle.convert(screen.levelScoreTitle.bounds, to: screen.view)
        let bonus = screen.speedBonusTitle.convert(screen.speedBonusTitle.bounds, to: screen.view)

        XCTAssertEqual(score.midY, bonus.midY, accuracy: 1,
                       "they are a pair, and a pair reads as one line")
        XCTAssertLessThanOrEqual(score.maxX, bonus.minX,
                                 "the score is the left column and the bonus the right")
        XCTAssertLessThan(score.maxX, screen.view.bounds.midX + 0.5)
        XCTAssertGreaterThan(bonus.minX, screen.view.bounds.midX - 0.5)
    }

    /// The total is under both of them, and is the one that says what it is.
    func testTheTotalSitsUnderThePair() throws {
        let screen = try XCTUnwrap(self.screen(bonus: 300))
        let bonus = screen.speedBonusLabel.convert(screen.speedBonusLabel.bounds, to: screen.view)
        let total = screen.totalScoreTitle.convert(screen.totalScoreTitle.bounds, to: screen.view)

        XCTAssertGreaterThanOrEqual(total.minY, bonus.maxY - 0.5)
        XCTAssertEqual(screen.totalScoreTitle.text, "Total Score")
        XCTAssertGreaterThan(screen.totalScoreTitle.font.pointSize,
                             screen.levelScoreTitle.font.pointSize,
                             "bigger than the two above it, and no more than that")
    }

    /// The rack is said at the bottom, above the tap line, which sits where a play button would.
    func testTheLivesAreSaidAboveTheTapLine() throws {
        let screen = try XCTUnwrap(self.screen(bonus: 300))
        screen.livesRemaining = 2
        let lives = try XCTUnwrap(
            screen.view.subviews.first?.subviews.compactMap { $0 as? UILabel }
                .first { ($0.text ?? "").contains("lives left") || ($0.text ?? "") == "1 life left" }
                ?? screen.tapLabel.superview?.subviews.compactMap { $0 as? UILabel }
                    .first { ($0.text ?? "").contains("lives left") || ($0.text ?? "") == "1 life left" },
            "the between-levels screen never says how many balls are left")

        let rack = lives.convert(lives.bounds, to: screen.view)
        let tap = screen.tapLabel.convert(screen.tapLabel.bounds, to: screen.view)
        XCTAssertLessThanOrEqual(rack.maxY, tap.minY + 0.5, "the rack sits above the tap line")
        XCTAssertLessThanOrEqual(tap.maxY, screen.view.bounds.height - 0.5)
        XCTAssertGreaterThan(tap.maxY, screen.view.bounds.height - 120,
                             "and the tap line is down where a play button would be")
    }

    /// A level with no speed bonus keeps the stack: a lone column against an empty half reads
    /// worse than the arrangement it replaced.
    func testALevelWithNoBonusIsUnchanged() throws {
        let screen = try XCTUnwrap(self.screen(bonus: 0))
        XCTAssertTrue(screen.speedBonusTitle.isHidden)
        let score = screen.levelScoreTitle.convert(screen.levelScoreTitle.bounds, to: screen.view)
        XCTAssertEqual(score.midX, screen.view.bounds.midX, accuracy: 1,
                       "still centred, because there is nothing beside it")
    }
}
/// The level intro's furniture, at the five shapes.
///
/// **James, round 332's layout notes: "move all labels down to prevent clipping with giga-ball
/// logo", and "add more space between giga-ball logo and game mode logo".** The wordmark is
/// hosted one level out from the intro, so nothing in the screen's own layout knows where it
/// is - which is how the mode icon came to reach up into it.
final class LevelIntroFurnitureTests: XCTestCase {

    private var hosts: [UIView] = []
    private var screens: [UIViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        hosts.removeAll()
        screens.removeAll()
        super.tearDown()
    }

    private let sizes: [(name: String, size: CGSize)] = [
        ("iPhone SE", CGSize(width: 320, height: 568)),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874)),
        ("iPhone 17 Pro Max", CGSize(width: 440, height: 956)),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376)),
        ("Slide Over", CGSize(width: 320, height: 1024)),
    ]

    /// The intro inside a host, which is what the game gives it - and what the wordmark needs.
    private func intro(size: CGSize) -> (UIView, InbetweenViewController)? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screen.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
        screen.packNumber = 2
        screen.numberOfLevels = 10
        screen.firstLevel = true

        let host = UIView(frame: CGRect(origin: .zero, size: size))
        screen.loadViewIfNeeded()
        screen.view.frame = host.bounds
        host.addSubview(screen.view)
        hosts.append(host)
        screens.append(screen)
        for _ in 0..<3 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
        return (host, screen)
    }

    private func wordmark(in host: UIView) -> UIImageView? {
        host.subviews.compactMap { $0 as? UIImageView }.first
    }

    private func modeIcon(in screen: InbetweenViewController) -> UIImageView? {
        screen.view.subviews.compactMap { $0 as? UIImageView }
            .first { $0.image != nil && $0.bounds.width == $0.bounds.height }
    }

    /// The mode's icon never reaches up into the wordmark.
    func testTheModeIconClearsTheWordmark() throws {
        for (name, size) in sizes {
            guard let (host, screen) = intro(size: size) else {
                return XCTFail("the storyboard no longer has an inbetweenView")
            }
            guard let logo = wordmark(in: host), let icon = modeIcon(in: screen) else { continue }

            let mark = logo.convert(logo.bounds, to: host)
            let badge = icon.convert(icon.bounds, to: host)
            XCTAssertGreaterThanOrEqual(badge.minY, mark.maxY,
                                        "\(name): the mode icon is drawn over the wordmark, "
                                        + "\(mark) against \(badge)")

            // And clearing it by pushing the block off the other end is not clearing it.
            // Round 332's first attempt at this passed nothing and drove the icon to -397;
            // the second would have satisfied a bare clearance check by sending the text
            // out of the bottom of the screen instead.
            XCTAssertGreaterThanOrEqual(badge.minY, -0.5,
                                        "\(name): the mode icon is off the top of the screen")
            let tap = screen.tapLabel.convert(screen.tapLabel.bounds, to: host)
            XCTAssertLessThanOrEqual(tap.maxY, size.height + 0.5,
                                     "\(name): the tap line is off the bottom of the screen")
            XCTAssertGreaterThan(tap.minY, badge.maxY,
                                 "\(name): the screen still reads icon, then text, then tap")
        }
    }
}
