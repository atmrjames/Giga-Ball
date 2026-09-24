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
    /// the iPad. The window floor rides along with them.
    ///
    /// **Round 340: 320x568 is not an iPhone SE.** It was labelled one here for several rounds,
    /// and the app's deployment target is iOS 17, which the original SE cannot run - the
    /// smallest phone that can is the SE 2nd and 3rd generation at 375x667. The old number is
    /// still worth laying out, because `SceneDelegate.smallestWindow` lets a player pull an
    /// iPad or Mac window down to it, so it stays in the list under its real name.
    private let sizes: [(name: String, size: CGSize)] = [
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("smallest window", SceneDelegate.smallestWindow),
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
    ///
    /// **Balls, not lives** (James, round 339: "I noticed balls left and lives left on
    /// different screens - let's use balls instead of lives everywhere"). The game has never
    /// had lives in it.
    func testTheLivesAreSaidAboveTheTapLine() throws {
        let screen = try XCTUnwrap(self.screen(bonus: 300))
        screen.livesRemaining = 2
        let lives = try XCTUnwrap(
            screen.view.subviews.first?.subviews.compactMap { $0 as? UILabel }
                .first { ($0.text ?? "").contains("ball") }
                ?? screen.tapLabel.superview?.subviews.compactMap { $0 as? UILabel }
                    .first { ($0.text ?? "").contains("ball") },
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
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("smallest window", SceneDelegate.smallestWindow),
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

// MARK: - The gallery

/// Renders every screen the *game* shows, at two shapes, to be looked at side by side.
///
/// **James, round 338: "some of the new in game view layouts don't look great... some of the
/// intro splash screens now have too much information, and many of the screens have the game
/// mode logo and title too low - they should sit just below the Giga-Ball logo near the top of
/// the views. It looks like there's still lots of continuity between the different views that
/// can happen too."**
///
/// Three rounds of layout notes have been answered a screen at a time, from a screenshot of
/// that one screen, which is exactly how a family of screens drifts apart while each of them
/// improves. This writes all of them out at once so they can be judged as a set. The PNGs land
/// in /tmp/gb-gallery; nothing here asserts, because what it is for is looking.
final class InGameGalleryTests: XCTestCase {

    private var hosts: [UIView] = []
    private var screens: [UIViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        InGameRecents.shared.runSummary = nil
        hosts.removeAll()
        screens.removeAll()
        super.tearDown()
    }

    private static let shapes: [(name: String, size: CGSize, regular: Bool)] = [
        ("se", CGSize(width: 375, height: 667), false),
        ("16pro", CGSize(width: 402, height: 874), false),
        ("ipad", CGSize(width: 1032, height: 1376), true),
        ("slideover", CGSize(width: 320, height: 1024), false),
    ]

    /// Holds the screen so its width class can be overridden.
    ///
    /// **Without this the iPad renders are a lie.** A view controller built on its own and
    /// dropped into a plain view reports a *compact* width whatever size that view is, and
    /// `limitMenuContentSize` - which is what keeps an iPad's content off the edges of the
    /// screen - returns early on compact. So the first iPad renders of round 338 showed the
    /// button row spread into the far corners, which is not what an iPad does. It is the same
    /// trap round 191 found in the app itself, from the other side.
    private var parents: [UIViewController] = []

    private func host(_ screen: UIViewController, size: CGSize, regular: Bool) -> UIView {
        let parent = UIViewController()
        parent.view.frame = CGRect(origin: .zero, size: size)
        parent.view.backgroundColor = UIColor(red: 0.09, green: 0.03, blue: 0.12, alpha: 1)

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = parent
        window.isHidden = false
        windows.append(window)
        if regular, #available(iOS 17.0, *) {
            window.traitOverrides.horizontalSizeClass = .regular
        }
        // **In a real window, and told what width class it is.** A view controller built on its
        // own and dropped into a plain view reports a *compact* width whatever size that view
        // is, and `limitMenuContentSize` - which is what holds an iPad's content to a 460-point
        // column - returns early on compact. So round 338's first iPad renders showed the
        // button row spread into the far corners of a 1032-point screen, which is not what an
        // iPad does, and James reviewed a picture of something the app never draws.

        parent.addChild(screen)
        screen.view.frame = parent.view.bounds
        parent.view.addSubview(screen.view)
        screen.didMove(toParent: parent)
        parents.append(parent)
        hosts.append(parent.view)
        screens.append(screen)
        return parent.view
    }

    private var windows: [UIWindow] = []
    // The two phones a note is usually written against, and the two shapes that catch what a
    // phone cannot: an iPad, where there is more room than the layout knows what to do with,
    // and a Slide Over pane, which is a phone's width at an iPad's height

    /// Everything on these screens arrives through a fade, and two of them leave through one
    /// as well, so a render taken straight after `viewDidLoad` catches an empty stage. The
    /// animations are stripped the way the splash screen strips its own, and every view under
    /// the host is made opaque and untransformed.
    private func reveal(_ view: UIView) {
        view.layer.removeAllAnimations()
        view.alpha = 1
        view.transform = .identity
        view.subviews.forEach(reveal)
    }

    private func write(_ host: UIView, _ name: String) {
        reveal(host)
        // Several passes: these screens add constraints from `viewDidLayoutSubviews` - the
        // header's, and the twist box's measured height - so the first pass after a change is
        // laying out against last pass's rules.
        for _ in 0..<4 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
        let renderer = UIGraphicsImageRenderer(bounds: host.bounds)
        let png = renderer.image { context in
            host.layer.render(in: context.cgContext)
        }.pngData()!
        // `layer.render(in:)` rather than `drawHierarchy(in:afterScreenUpdates:)`. The second
        // wants a view that is in a window, and given one that is not it draws a hierarchy
        // that is **geometrically wrong**: round 338 spent half an hour on a wordmark whose
        // frame said 46 points and which drew at 110. The layer tree is the truth here, and
        // the only thing lost is the live blur behind the card, which these renders are not
        // for looking at anyway.
        let folder = URL(fileURLWithPath: "/tmp/gb-gallery")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? png.write(to: folder.appendingPathComponent("\(name).png"))
        print("GALLERY \(name)")
    }

    // MARK: The level intro and the between-levels card

    private func inbetween(size: CGSize, regular: Bool = false,
                           configure: (InbetweenViewController) -> Void) -> UIView? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        configure(screen)

        screen.loadViewIfNeeded()
        let host = self.host(screen, size: size, regular: regular)
        for _ in 0..<3 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
        screen.view.alpha = 1
        screen.view.transform = .identity
        screen.contentView?.alpha = 1

        // **The intro is the completion card with its numbers rubbed out.** There is only one
        // scene here: `removeAnimate` fades the finished level's card away, blanks every score
        // label by setting its text to "", switches the constraint and fades the next level's
        // name back in. That completion runs on the run loop, which a test does not spin, so a
        // render taken now would show a player the numbers they never see. Blanked here in the
        // same order, so the gallery shows the intro rather than the card behind it.
        if screen.firstLevel == false {
            screen.tapLabel.isHidden = false
            // The tally reveals it when it finishes counting, and a test does not spin the run
            // loop it counts on - so without this the render is missing the one line the card
            // ends with, which is exactly what James asked about in round 339
        }
        if screen.firstLevel {
            for label in [screen.completeLabel, screen.totalScoreTitle, screen.totalScoreLabel,
                          screen.levelScoreTitle, screen.levelScoreLabel,
                          screen.speedBonusTitle, screen.speedBonusLabel, screen.tapLabel] {
                label?.text = ""
            }
            screen.completeLabelConstraint.isActive = false
            screen.packAndLevelConstriant.isActive = true
            for _ in 0..<2 {
                host.setNeedsLayout()
                host.layoutIfNeeded()
            }
        }
        return host
    }

    private func pause(size: CGSize, regular: Bool = false,
                       configure: (PauseMenuViewController) -> Void) -> UIView? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController else { return nil }
        screen.totalStatsArray = [TotalStats()]
        configure(screen)

        screen.loadViewIfNeeded()
        let host = self.host(screen, size: size, regular: regular)
        screen.viewWillAppear(false)
        for _ in 0..<3 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
        return host
    }

    /// Where the header actually lands, printed, for when a render disagrees with the code.
    func testPrintTheHeaderGeometry() {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: DailyChallengeSession.shared.todayKey, mode: .classic,
            classicLevel: 0, twists: [.fogOfWar, .mirrored, .suddenDeath])
        guard let host = inbetween(size: CGSize(width: 320, height: 568), configure: {
            $0.levelNumber = 1
            $0.packNumber = 2
            $0.numberOfLevels = 1
            $0.firstLevel = true
        }) else { return XCTFail("no intro") }
        let screen = screens.last as! InbetweenViewController
        for _ in 0..<4 { host.setNeedsLayout(); host.layoutIfNeeded() }
        print("HEADER safeTop \(host.safeAreaInsets.top) viewSafeTop \(screen.view.safeAreaInsets.top)")
        for (name, view) in [("logo", host.subviews.compactMap { $0 as? UIImageView }.first),
                             ("icon", screen.view.subviews.compactMap { $0 as? UIImageView }
                                 .first { $0.bounds.width == $0.bounds.height })] {
            if let view { print("HEADER \(name) \(view.convert(view.bounds, to: host))") }
        }
        print("HEADER pack \(screen.packNameLabel.convert(screen.packNameLabel.bounds, to: host)) text=\(screen.packNameLabel.text ?? "nil")")
        print("HEADER drop \(UIViewController.inGameHeaderIconDrop)")
        print("HEADER addr pack \(Unmanaged.passUnretained(screen.packNameLabel).toOpaque()) level \(Unmanaged.passUnretained(screen.levelNumberLabel).toOpaque()) name \(Unmanaged.passUnretained(screen.levelNameLabel).toOpaque())")
        print("HEADER addr contentView \(Unmanaged.passUnretained(screen.contentView).toOpaque()) view \(Unmanaged.passUnretained(screen.view).toOpaque())")
        print("HEADER level \(screen.levelNumberLabel.convert(screen.levelNumberLabel.bounds, to: host)) text=\(screen.levelNumberLabel.text ?? "nil")")
        for constraint in screen.view.constraints where constraint.firstAttribute == .top || constraint.secondAttribute == .bottom {
            print("HEADER tie \(constraint)")
        }
        DailyChallengeSession.shared.active = nil
    }

    /// What the between-levels card measures on the smallest phone.
    func testPrintTheBetweenLevelsGeometry() {
        guard let host = inbetween(size: CGSize(width: 320, height: 568), configure: {
            $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
            $0.packNumber = 2
            $0.numberOfLevels = 10
            $0.firstLevel = false
            $0.levelScore = 4300
            $0.levelScoreBonus = 900
            $0.totalScore = 15200
            $0.livesRemaining = 2
        }) else { return XCTFail("no card") }
        let screen = screens.last as! InbetweenViewController
        for _ in 0..<4 { host.setNeedsLayout(); host.layoutIfNeeded() }
        func say(_ name: String, _ view: UIView?) {
            guard let view else { return print("BETWEEN \(name) nil") }
            print("BETWEEN \(name) \(view.convert(view.bounds, to: host))")
        }
        say("contentView", screen.contentView)
        say("packName", screen.packNameLabel)
        say("levelName", screen.levelNameLabel)
        say("complete", screen.completeLabel)
        say("totalTitle", screen.totalScoreTitle)
        say("totalLabel", screen.totalScoreLabel)
        say("tap", screen.tapLabel)
        print("BETWEEN tapHidden \(screen.tapLabel.isHidden)")
        for sub in (screen.tapLabel.superview?.subviews ?? []) where sub is UILabel {
            let label = sub as! UILabel
            if (label.text ?? "").contains("lives") || (label.text ?? "").contains("life") {
                say("lives", label)
                for c in (label.superview?.constraints ?? []) where c.firstItem === label || c.secondItem === label {
                    print("BETWEEN livesTie \(c)")
                }
            }
        }
        say("levelNumber", screen.levelNumberLabel)
    }

    /// The splash screen offering a saved run, which is where the family starts.
    private func resumeCard(size: CGSize, regular: Bool = false) -> UIView? {
        let store = UserDefaults(suiteName: "InGameGalleryTests.resume")!
        store.removePersistentDomain(forName: "InGameGalleryTests.resume")
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
        game.save(to: store)
        store.set(true, forKey: SavedGame.resumeFlagKey)

        let board = UIStoryboard(name: "Main", bundle: Bundle(for: SplashViewController.self))
        guard let splash = board.instantiateViewController(withIdentifier: "splashView")
                as? SplashViewController else { return nil }
        splash.defaults = store
        splash.gameToResume = true

        splash.loadViewIfNeeded()
        let host = self.host(splash, size: size, regular: regular)
        for _ in 0..<3 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
        return host
    }

    func testWriteTheWholeFamilyOut() {
        for (shape, size, regular) in Self.shapes {

            // The resume card, the screen the run is entered from
            if let host = resumeCard(size: size, regular: regular) { write(host, "resume-classic-\(shape)") }

            // The level intro, the four runs it can introduce
            if let host = inbetween(size: size, regular: regular, configure: {
                $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
                $0.packNumber = 2
                $0.numberOfLevels = 10
                $0.firstLevel = true
            }) { write(host, "intro-classic-\(shape)") }

            if let host = inbetween(size: size, regular: regular, configure: {
                $0.levelNumber = 0
                $0.packNumber = 1
                $0.numberOfLevels = 1
                $0.firstLevel = true
            }) { write(host, "intro-endless-\(shape)") }

            for (label, twists) in [("notwists", [DailyTwist]()),
                                    ("1twist", [.fogOfWar]),
                                    ("3twists", [.fogOfWar, .mirrored, .suddenDeath])] {
                DailyChallengeSession.shared.active = DailyChallenge(
                    dateKey: DailyChallengeSession.shared.todayKey, mode: .classic,
                    classicLevel: 0, twists: twists)
                if let host = inbetween(size: size, regular: regular, configure: {
                    $0.levelNumber = 1
                    $0.packNumber = 2
                    $0.numberOfLevels = 1
                    $0.firstLevel = true
                }) { write(host, "intro-daily-\(label)-\(shape)") }
                DailyChallengeSession.shared.active = nil
            }

            // The between-levels card, with and without a speed bonus
            if let host = inbetween(size: size, regular: regular, configure: {
                $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
                $0.packNumber = 2
                $0.numberOfLevels = 10
                $0.firstLevel = false
                $0.levelScore = 4300
                $0.levelScoreBonus = 900
                $0.totalScore = 15200
                $0.livesRemaining = 2
            }) { write(host, "between-bonus-\(shape)") }

            if let host = inbetween(size: size, regular: regular, configure: {
                $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
                $0.packNumber = 2
                $0.numberOfLevels = 10
                $0.firstLevel = false
                $0.levelScore = 4300
                $0.levelScoreBonus = 0
                $0.totalScore = 15200
                $0.livesRemaining = 2
            }) { write(host, "between-nobonus-\(shape)") }

            // Paused, in a pack and in an endless run
            if let host = pause(size: size, regular: regular, configure: {
                $0.sender = "Pause"
                $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
                $0.score = 3200
            }) { write(host, "pause-classic-\(shape)") }

            if let host = pause(size: size, regular: regular, configure: {
                $0.sender = "Pause"
                $0.levelNumber = 0
                $0.endlessMode = true
                $0.score = 3200
            }) { write(host, "pause-endless-\(shape)") }

            // And the end of a run
            InGameRecents.shared.runSummary = InGameRecents.RunSummary(
                height: 0, durationSeconds: 214, paddleHits: 132, bricksDestroyed: 410,
                ballsLost: 3, powerUpsSeen: 14, powerUpsCollected: 9,
                score: 15200, levelsCleared: 4, isEndless: false)
            if let host = pause(size: size, regular: regular, configure: {
                $0.sender = "Game Over"
                $0.levelNumber = LevelPackSetup().startLevelNumber[2] + 3
                $0.score = 15200
                $0.levelScore = 4300
                $0.levelTimerBonus = 900
            }) { write(host, "gameover-classic-\(shape)") }
            InGameRecents.shared.runSummary = nil
        }
    }
}

/// The header band, and the promise that it is the same band on every screen the game shows.
///
/// **James, round 338: "many of the screens have the game mode logo and title too low - they
/// should sit just below the Giga-Ball logo near the top of the views. It looks like there's
/// still lots of continuity between the different views that can happen too."**
///
/// The continuity is the point of these, not the individual numbers: a player goes intro,
/// pause, between-levels, game over within a minute, and the wordmark, the mode's badge and
/// the line naming the run should not move between them.
final class InGameHeaderSpineTests: XCTestCase {

    private var hosts: [UIView] = []
    private var screens: [UIViewController] = []

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        InGameRecents.shared.runSummary = nil
        hosts.removeAll()
        screens.removeAll()
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        super.tearDown()
    }

    private let shapes: [(name: String, size: CGSize, regular: Bool)] = [
        ("iPhone SE", CGSize(width: 375, height: 667), false),
        ("smallest window", SceneDelegate.smallestWindow, false),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874), false),
        ("iPhone 17 Pro Max", CGSize(width: 440, height: 956), false),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376), true),
        ("Slide Over", CGSize(width: 320, height: 1024), false),
    ]

    private var windows: [UIWindow] = []

    /// A real window, told what width class it is.
    ///
    /// Without one an iPad-sized screen reports a *compact* width and `limitMenuContentSize`
    /// stands down, so the content fills 1032 points instead of the 460-point column the app
    /// actually draws - and every measurement taken here is of a screen the app never shows.
    private func host(_ screen: UIViewController, size: CGSize, regular: Bool) -> UIView {
        let parent = UIViewController()
        parent.view.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = parent
        window.isHidden = false
        windows.append(window)
        if regular, #available(iOS 17.0, *) {
            window.traitOverrides.horizontalSizeClass = .regular
        }
        parent.addChild(screen)
        screen.view.frame = parent.view.bounds
        parent.view.addSubview(screen.view)
        screen.didMove(toParent: parent)
        hosts.append(parent.view)
        screens.append(screen)
        return parent.view
    }

    // MARK: Building the two screens

    private func intro(size: CGSize, regular: Bool = false,
                       firstLevel: Bool) -> (UIView, InbetweenViewController)? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screen.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
        screen.packNumber = 2
        screen.numberOfLevels = 10
        screen.firstLevel = firstLevel
        screen.levelScore = 4300
        screen.levelScoreBonus = 900
        screen.totalScore = 15200
        screen.livesRemaining = 2

        screen.loadViewIfNeeded()
        let host = self.host(screen, size: size, regular: regular)
        settle(host)
        return (host, screen)
    }

    private func pause(size: CGSize, regular: Bool = false,
                       sender: String) -> (UIView, PauseMenuViewController)? {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController else { return nil }
        screen.sender = sender
        screen.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
        screen.score = 3200
        screen.totalStatsArray = [TotalStats()]

        screen.loadViewIfNeeded()
        let host = self.host(screen, size: size, regular: regular)
        screen.viewWillAppear(false)
        settle(host)
        return (host, screen)
    }

    private func settle(_ host: UIView) {
        for _ in 0..<4 {
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }
    }

    /// The wordmark, wherever it is hosted: beside the intro, inside the pause screen.
    private func wordmark(_ host: UIView, _ screen: UIViewController) -> UIImageView? {
        let mine = host.subviews.compactMap { $0 as? UIImageView }
        if let found = mine.first(where: { $0.bounds.width > $0.bounds.height*2 }) {
            return found
        }
        return everyImageView(in: screen.view)
            .first { $0.bounds.width > $0.bounds.height*2 && $0.bounds.height > 10 }
    }

    /// The mode's badge, and not one of the round buttons.
    ///
    /// Both screens add it as a direct child of the view it is laid out against - the intro's
    /// own view, the pause screen's content box - so the search stays one level deep. Going
    /// deeper finds the 50-point glyphs inside the button row instead, which is how round
    /// 338's first run of this test reported the badge as being 700 points down the screen.
    private func badge(_ screen: UIViewController) -> UIImageView? {
        var candidates = screen.view.subviews.compactMap { $0 as? UIImageView }
        if let pause = screen as? PauseMenuViewController {
            candidates += pause.containterView.subviews.compactMap { $0 as? UIImageView }
        }
        return candidates
            .filter { $0.bounds.width == $0.bounds.height && $0.bounds.width > 30 }
            .max { $0.bounds.width < $1.bounds.width }
    }

    private func everyImageView(in view: UIView) -> [UIImageView] {
        view.subviews.flatMap { [$0 as? UIImageView].compactMap { $0 } + everyImageView(in: $0) }
    }

    // MARK: The band itself

    /// The badge hangs from the wordmark rather than from whatever text happens to be showing.
    func testTheBadgeSitsUnderTheWordmarkOnEveryScreen() throws {
        for (name, size, regular) in shapes {
            var seen = 0
            for (label, pair) in build(size, regular: regular) {
                guard let logo = wordmark(pair.0, pair.1), let icon = badge(pair.1) else { continue }
                seen += 1
                let mark = logo.convert(logo.bounds, to: pair.0)
                let disc = icon.convert(icon.bounds, to: pair.0)

                XCTAssertGreaterThanOrEqual(disc.minY, mark.maxY - 0.5,
                    "\(name), \(label): the badge is drawn into the wordmark - \(mark) against "
                    + "\(disc). Round 338's first gallery render of this read GIG(badge)ALL")
                XCTAssertGreaterThanOrEqual(disc.minY, -0.5,
                    "\(name), \(label): the badge is off the top of the screen")
                XCTAssertLessThan(disc.minY - mark.maxY, 60,
                    "\(name), \(label): the badge has drifted away from the wordmark, which is "
                    + "the 'too low' James reported - it is meant to hang from it")
            }
            XCTAssertGreaterThan(seen, 2, "\(name): too few screens built to judge anything")
        }
    }

    /// And every screen puts it in the *same* place, which is the continuity being asked for.
    func testTheBandIsInTheSamePlaceOnEveryScreen() throws {
        for (name, size, regular) in shapes {
            var places: [String: CGRect] = [:]
            for (label, pair) in build(size, regular: regular) {
                guard let icon = badge(pair.1) else { continue }
                places[label] = icon.convert(icon.bounds, to: pair.0)
            }
            guard let first = places.first else { return XCTFail("\(name): nothing built") }
            for (label, place) in places {
                XCTAssertEqual(place.minY, first.value.minY, accuracy: 1,
                    "\(name): the badge is at \(place.minY) on \(label) and "
                    + "\(first.value.minY) on \(first.key). A player sees these screens seconds "
                    + "apart and the badge must not jump between them")
                XCTAssertEqual(place.height, first.value.height, accuracy: 1,
                    "\(name): the badge is a different size on \(label)")
            }
        }
    }

    /// The wordmark clears the Home button in the pause screen's corner.
    func testTheWordmarkClearsTheHomeButton() throws {
        for (name, size, regular) in shapes {
            guard let (host, screen) = pause(size: size, regular: regular, sender: "Pause"),
                  let logo = wordmark(host, screen), let home = screen.homeButton
            else { continue }
            XCTAssertFalse(home.isHidden, "\(name): the paused screen shows Home")

            let mark = logo.convert(logo.bounds, to: host)
            let button = home.convert(home.bounds, to: host)
            XCTAssertFalse(mark.intersects(button),
                "\(name): the wordmark \(mark) is drawn under the Home button \(button)")
        }
    }

    private func build(_ size: CGSize, regular: Bool) -> [(String, (UIView, UIViewController))] {
        var built: [(String, (UIView, UIViewController))] = []
        if let pair = intro(size: size, regular: regular, firstLevel: true) {
            built.append(("the level intro", (pair.0, pair.1)))
        }
        if let pair = intro(size: size, regular: regular, firstLevel: false) {
            built.append(("the between-levels card", (pair.0, pair.1)))
        }
        if let pair = pause(size: size, regular: regular, sender: "Pause") {
            built.append(("the pause screen", (pair.0, pair.1)))
        }
        if let pair = pause(size: size, regular: regular, sender: "Game Over") {
            built.append(("the game-over card", (pair.0, pair.1)))
        }
        return built
    }
}

// MARK: - The menus

/// The same treatment for the screens outside the game: rendered at four shapes, to be looked at.
///
/// **James, round 339: "can we do the same UI assessment of various non-game scene views from
/// the app on different devices?"** and, from an iPad play test, a list of screens whose
/// content ran to the edges of the window or changed width as he dragged its corner.
///
/// The PNGs land in /tmp/gb-menus. Nothing here asserts; `MenuGalleryAuditTests` below is the
/// part that does.
final class MenuGalleryTests: XCTestCase {

    private var windows: [UIWindow] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        super.tearDown()
    }

    static let shapes: [(name: String, size: CGSize, regular: Bool)] = [
        ("se", CGSize(width: 375, height: 667), false),
        ("16pro", CGSize(width: 402, height: 874), false),
        ("ipad", CGSize(width: 1032, height: 1376), true),
        ("ipad-wide", CGSize(width: 1194, height: 834), true),
        ("window-480", CGSize(width: 480, height: 900), false),
        ("window-520", CGSize(width: 520, height: 900), true),
    ]
    // The last two are the pair either side of the width class changing, which is where the
    // cells were stepping from one width to another.

    /// Every screen the menus can show, built the way the app builds it.
    static func everyScreen() -> [(String, UIViewController)] {
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: MenuViewController.self))
        var built: [(String, UIViewController)] = []

        func fromBoard(_ id: String, _ name: String) {
            guard let screen = board.instantiateViewController(withIdentifier: id)
                    as UIViewController? else { return }
            (screen as? SettingsViewController)?.navigatedFrom = "MainMenu"
            if let modes = screen as? ModeSelectViewController {
                modes.levelPack = 2
                modes.selectedLevel = 1
                modes.numberOfLevels = 10
                modes.levelSender = "PackSelect"
            }
            if let levels = screen as? LevelSelectorViewController {
                levels.packNumber = 2
                levels.numberOfLevels = 10
                levels.startLevel = 1
            }
            // Force-unwrapped in `viewDidLoad`, and set by whoever opens the screen. A screen
            // built outside the app has nobody to set it, and the unwrap takes the whole test
            // bundle down rather than the one screen.
            built.append((name, screen))
        }
        fromBoard("menuView", "main-menu")
        fromBoard("settingsVC", "settings")
        fromBoard("backgroundSelectView", "background-select")
        fromBoard("modeSelectView", "mode-select")
        fromBoard("packSelectorView", "pack-select")
        fromBoard("levelSelectorView", "level-select")
        fromBoard("statsView", "stats")
        fromBoard("itemsView", "items")
        fromBoard("brickTypesView", "brick-types")
        fromBoard("aboutVC", "about")

        built.append(("music", MusicViewController()))
        built.append(("paddle-speed", PaddleSpeedViewController()))
        built.append(("daily-challenge", DailyChallengeViewController()))
        return built
    }

    func host(_ screen: UIViewController, size: CGSize, regular: Bool) -> UIView {
        let parent = UIViewController()
        parent.view.frame = CGRect(origin: .zero, size: size)
        parent.view.backgroundColor = UIColor(red: 0.09, green: 0.03, blue: 0.12, alpha: 1)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = parent
        window.isHidden = false
        windows.append(window)
        if regular, #available(iOS 17.0, *) {
            window.traitOverrides.horizontalSizeClass = .regular
        }
        parent.addChild(screen)
        screen.view.frame = parent.view.bounds
        screen.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(screen.view)
        screen.didMove(toParent: parent)
        standDownTheSplash(over: screen)
        for _ in 0..<4 {
            parent.view.setNeedsLayout()
            parent.view.layoutIfNeeded()
        }
        return parent.view
    }

    /// Takes the launch animation off the main menu, so the render is of the menu.
    ///
    /// **James, round 340: "the main menu screenshot is just the splash animation."** It was:
    /// `MenuViewController` adds a `SplashViewController` over itself on its first launch and
    /// the gallery photographs what is in front, which on that one screen is a full-screen
    /// wordmark on its opening frame. Six pictures of a logo, every round, in place of the
    /// screen James actually wanted to look at.
    ///
    /// Stood down here rather than by asking the menu not to show it: the menu *should* show
    /// it, and what is wrong is only that a photograph taken a tenth of a second into the app's
    /// life is not a photograph of the main menu.
    func standDownTheSplash(over screen: UIViewController) {
        for child in screen.children where child is SplashViewController {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }

    func testWriteTheMenusOut() {
        let folder = URL(fileURLWithPath: "/tmp/gb-menus")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for (shape, size, regular) in Self.shapes {
            for (name, screen) in Self.everyScreen() {
                let host = self.host(screen, size: size, regular: regular)
                let renderer = UIGraphicsImageRenderer(bounds: host.bounds)
                let png = renderer.image { context in
                    host.layer.render(in: context.cgContext)
                }.pngData()!
                try? png.write(to: folder.appendingPathComponent("\(name)-\(shape).png"))
            }
            print("MENUS \(shape)")
        }
    }
}

/// And the part that asserts: no menu screen runs its content to the edge of a large window.
///
/// **James, round 339, across five screens at once: "bring the UI elements in to a maximum
/// width and height like other views", "prevent clipping of elements", "run checks and tests
/// where possible to review these issues and prevent them from happening going forwards".**
final class MenuGalleryAuditTests: XCTestCase {

    private var windows: [UIWindow] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        super.tearDown()
    }

    private func host(_ screen: UIViewController, size: CGSize, regular: Bool) -> UIView {
        let parent = UIViewController()
        parent.view.frame = CGRect(origin: .zero, size: size)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = parent
        window.isHidden = false
        windows.append(window)
        if regular, #available(iOS 17.0, *) {
            window.traitOverrides.horizontalSizeClass = .regular
        }
        parent.addChild(screen)
        screen.view.frame = parent.view.bounds
        screen.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        parent.view.addSubview(screen.view)
        screen.didMove(toParent: parent)
        for _ in 0..<4 {
            parent.view.setNeedsLayout()
            parent.view.layoutIfNeeded()
        }
        return parent.view
    }

    /// Anything a player reads or presses, and where it is.
    private func furniture(in view: UIView, to root: UIView) -> [(UIView, CGRect)] {
        var found: [(UIView, CGRect)] = []
        for subview in view.subviews {
            guard subview.isHidden == false, subview.alpha > 0.05 else { continue }
            let interesting = subview is UILabel || subview is UIButton || subview is UISlider
                || subview is UITableView || subview is UICollectionView
            if interesting, subview.bounds.width > 1, subview.bounds.height > 1 {
                found.append((subview, subview.convert(subview.bounds, to: root)))
            }
            if subview is UITableView || subview is UICollectionView { continue }
            found += furniture(in: subview, to: root)
        }
        return found
    }

    /// On a window wider than the column, nothing reaches the window's own edge.
    ///
    /// The column is `menuMaximumWidth`; a screen that has not asked for it lays its content
    /// out across the whole window, which on a 13-inch iPad is a slider a foot long and a close
    /// button in the far corner.
    func testNoMenuRunsItsContentToTheEdgeOfALargeWindow() {
        let size = CGSize(width: 1032, height: 1376)
        let leastMargin = (size.width - UIViewController.menuMaximumWidth)/2 - 40
        // Forty points of slack: a background view is allowed to fill the window, and so is
        // anything the column's own inset does not apply to

        for (name, screen) in MenuGalleryTests.everyScreen() {
            let root = host(screen, size: size, regular: true)
            for (view, frame) in furniture(in: root, to: root) {
                guard frame.width < size.width - 1 else { continue }
                // A view that *is* the window - a background, a full-width table - is not what
                // this is about; what it holds is measured on its own
                XCTAssertGreaterThan(frame.minX, leastMargin,
                    "\(name): a \(type(of: view)) starts \(Int(frame.minX))pt from the left of "
                    + "a \(Int(size.width))pt window. Everything here should sit inside the "
                    + "\(Int(UIViewController.menuMaximumWidth))pt column")
                XCTAssertLessThan(frame.maxX, size.width - leastMargin,
                    "\(name): a \(type(of: view)) ends \(Int(size.width - frame.maxX))pt from "
                    + "the right of the window")
            }
        }
    }

    /// And the content is the same width either side of the width class changing.
    func testNoScreenChangesWidthWhenTheWindowCrossesTheWidthClass() {
        for (name, _) in MenuGalleryTests.everyScreen() {
            var widths: [CGFloat] = []
            for (size, regular) in [(CGSize(width: 480, height: 900), false),
                                    (CGSize(width: 520, height: 900), true)] {
                guard let screen = MenuGalleryTests.everyScreen()
                    .first(where: { $0.0 == name })?.1 else { continue }
                let root = host(screen, size: size, regular: regular)
                let insets = screen.additionalSafeAreaInsets
                widths.append(size.width - insets.left - insets.right)
            }
            guard widths.count == 2 else { continue }
            XCTAssertLessThanOrEqual(widths[1], widths[0] + 41,
                "\(name): a 480pt window lays out \(Int(widths[0]))pt of content and a 520pt "
                + "one \(Int(widths[1])) - the content should never *shrink* as the window "
                + "grows, which is the snap James watched")
        }
    }
}

/// Where the day's twists sit on the level intro, across every shape the app runs on.
///
/// **James, round 340: "centre the twists including the icon and labels - at the moment the
/// icons look centred but the labels are to the right. It looks right on the iPhone 16 Pro but
/// not on some of the other devices. Use how they are laid out on the Daily Challenge main menu
/// view."**
///
/// The phrase that matters is "on some of the other devices": round 338's block was centred by
/// measuring the widest line, so it was true wherever the measurement matched what was drawn and
/// off-centre everywhere else. A test that looks at one screen would have passed. This one lays
/// the label's own attributed text out through TextKit at each device width and checks the slack
/// either side of every line, which is the thing James was looking at.
final class DailyIntroTwistCentringTests: XCTestCase {

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private func intro(size: CGSize) -> InbetweenViewController? {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: DailyChallengeSession.shared.todayKey, mode: .classic,
            classicLevel: 1, twists: [.fogOfWar, .oneLife, .noPowerUps])
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: InbetweenViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "inbetweenView")
                as? InbetweenViewController else { return nil }
        screen.levelNumber = 1
        screen.loadViewIfNeeded()
        screen.view.frame = CGRect(origin: .zero, size: size)
        for _ in 0..<3 {
            screen.view.setNeedsLayout()
            screen.view.layoutIfNeeded()
        }
        return screen
    }

    /// Every shape: the SE's width, the 16 Pro's (where it always looked right), the Max's, and
    /// both iPads, whose menu column is wider than any phone.
    private let shapes: [(String, CGSize)] = [
        ("iPhone SE", CGSize(width: 375, height: 667)),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874)),
        ("iPhone 16 Pro Max", CGSize(width: 440, height: 956)),
        ("iPad 11-inch", CGSize(width: 834, height: 1210)),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376)),
    ]

    /// No line is indented, and the paragraph centres itself the way the daily card's rows do.
    func testTheTwistsAreCentredRatherThanIndented() throws {
        for (name, size) in shapes {
            let screen = try XCTUnwrap(intro(size: size), "the storyboard no longer has an "
                                       + "inbetweenView")
            let text = try XCTUnwrap(screen.levelNameLabel?.attributedText)
            let style = text.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
                as? NSParagraphStyle
            XCTAssertEqual(style?.alignment, .center,
                           "\(name): the twists are laid out \(String(describing: style?.alignment)) "
                           + "rather than centred")
            XCTAssertEqual(style?.firstLineHeadIndent ?? 0, 0, accuracy: 0.5,
                           "\(name): the twists are indented \(style?.firstLineHeadIndent ?? 0)pt, "
                           + "which is round 338's measured block coming back")
        }
    }

    /// And each drawn line has the same slack to its left as to its right.
    func testEachTwistLineHasTheSameSlackEitherSide() throws {
        for (name, size) in shapes {
            let screen = try XCTUnwrap(intro(size: size))
            let label = try XCTUnwrap(screen.levelNameLabel)
            let text = try XCTUnwrap(label.attributedText)
            XCTAssertGreaterThan(label.bounds.width, 0, "\(name): the twists label has no width")

            let storage = NSTextStorage(attributedString: text)
            let manager = NSLayoutManager()
            let container = NSTextContainer(size: CGSize(width: label.bounds.width,
                                                         height: .greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = 0
            storage.addLayoutManager(manager)
            manager.addTextContainer(container)
            manager.ensureLayout(for: container)

            var index = 0
            var lines = 0
            while index < manager.numberOfGlyphs {
                var range = NSRange(location: 0, length: 0)
                let used = manager.lineFragmentUsedRect(forGlyphAt: index, effectiveRange: &range)
                let left = used.minX
                let right = label.bounds.width - used.maxX
                XCTAssertEqual(left, right, accuracy: 1,
                               "\(name): a twist line is drawn \(left)pt from the left of the "
                               + "label and \(right)pt from the right, so the block is not centred")
                index = NSMaxRange(range)
                lines += 1
            }
            XCTAssertGreaterThanOrEqual(lines, 3, "\(name): only \(lines) twist lines were laid out")
        }
    }
}

/// Where the Game Center line ends up on the screens that show one.
///
/// **James, round 340: "game centre info is missing from iPhone SE."** It was not hidden, it
/// was laid out below the button row: everything that placed the block was a minimum measured
/// downwards from whatever was above it, and the only thing holding the block up was a wanted
/// constraint, which a short screen is free to break. This checks the block is on the screen
/// and above the buttons, on every shape, which is the claim rather than the constraint.
final class GameCentreLineOnEveryScreenTests: XCTestCase {

    private var windows: [UIWindow] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows.removeAll()
        DailyChallengeSession.shared.active = nil
        super.tearDown()
    }

    private let shapes: [(String, CGSize, Bool)] = [
        ("iPhone SE", CGSize(width: 375, height: 667), false),
        ("iPhone 16 Pro", CGSize(width: 402, height: 874), false),
        ("iPhone 16 Pro Max", CGSize(width: 440, height: 956), false),
        ("iPad 13-inch", CGSize(width: 1032, height: 1376), true),
        ("smallest window", SceneDelegate.smallestWindow, false),
    ]

    private func gameOver(size: CGSize, regular: Bool) -> PauseMenuViewController? {
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: DailyChallengeSession.shared.todayKey, mode: .classic,
            classicLevel: 1, twists: [])
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: PauseMenuViewController.self))
        guard let screen = board.instantiateViewController(withIdentifier: "pauseMenuVC")
                as? PauseMenuViewController else { return nil }
        screen.sender = "GameOver"
        screen.levelNumber = LevelPackSetup().startLevelNumber[2] + 2
        screen.score = 3200
        screen.totalStatsArray = [TotalStats()]
        screen.loadViewIfNeeded()

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.traitOverrides.horizontalSizeClass = regular ? .regular : .compact
        window.rootViewController = screen
        window.isHidden = false
        windows.append(window)
        screen.viewWillAppear(false)

        // Game Center does not answer in a test, so the line is put up by hand: what is under
        // test is where it lands, not whether it is asked for.
        screen.leaderboardTitle.isHidden = false
        screen.resultLabel.isHidden = false
        screen.resultLabel.text = "7/102 on today's leaderboard"
        for _ in 0..<4 {
            window.setNeedsLayout()
            window.layoutIfNeeded()
        }
        return screen
    }

    /// The block is above the row of buttons, and on the screen, at every size.
    func testTheLeaderboardLineIsNeverPushedOffTheBottom() throws {
        for (name, size, regular) in shapes {
            let screen = try XCTUnwrap(gameOver(size: size, regular: regular),
                                       "the storyboard no longer has a pauseMenuVC")
            let root = screen.view!
            let buttons = screen.buttonCollectionView.convert(
                screen.buttonCollectionView.bounds, to: root)
            for (what, label) in [("GAME CENTER", screen.leaderboardTitle),
                                  ("the placing", screen.resultLabel)] {
                let place = label.convert(label.bounds, to: root)
                XCTAssertGreaterThan(place.height, 0, "\(name): \(what) has no height")
                XCTAssertLessThanOrEqual(place.maxY, buttons.minY + 0.5,
                                         "\(name): \(what) is drawn at \(place.maxY) and the "
                                         + "button row starts at \(buttons.minY), so it is "
                                         + "behind the buttons")
                XCTAssertLessThanOrEqual(place.maxY, root.bounds.height + 0.5,
                                         "\(name): \(what) is off the bottom of the screen")
                XCTAssertGreaterThanOrEqual(place.minY, 0,
                                            "\(name): \(what) is off the top of the screen")
            }
        }
    }
}
