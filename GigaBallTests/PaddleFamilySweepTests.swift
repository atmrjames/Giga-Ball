//
//  PaddleFamilySweepTests.swift
//  GigaBallTests
//
//  Two sweeps across the paddle family - the paddle, the Mirror Paddle and the safety bar - in
//  every theme and the combinations of power-ups that reshape them.
//
//  James, round 395: "I feel a lot of these recent mistakes would be preventable with better and
//  more thorough checks and tests in place." He was right. Rounds 393 to 395 answered five reports
//  about these three surfaces - a Retro split bar drawn as slivers, a whole bar drawn under its
//  own pieces, a mirror that stayed whole, pieces drawn half as far out again as their bodies
//  under Expand, a halo across the gaps - and a sticky face left behind by a power-up that had
//  ended. Each was caught by eye, after a play test, because every test asked about the case it
//  was written for. These two ask about all of them at once, so the next one is caught here.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

/// What is drawn is what is solid.
///
/// For every theme, with the paddle whole, split, and split under Expand, each surface's body is
/// probed point by point along its line and set against the sprites it actually draws. Every
/// solid stretch must have one drawn stretch over it, ends within a point and a half, and nothing
/// may be drawn where nothing is solid - a gap with a picture in it, or a piece standing beside
/// its body, fails here. Retro's whole paddle draws its purple caps past its body on purpose
/// (James, round 391: "The purple end caps shouldn't have a physics body"), so its ends are
/// allowed the caps' width.
final class DrawnWhereSolidTests: XCTestCase {
    private var window: UIWindow?

    func testEveryThemeDrawsEachSurfaceWhereItIsSolid() throws {
        var failures: [String] = []
        for (theme, name) in GameScene.paddleThemePrefixes.enumerated() {
            let scene = try PaddleFamilySweep.present(theme: theme, keeping: &window)
            scene.endlessIICollectSafetyPaddle()
            scene.endlessIICollectMirrorPaddle()
            scene.paddle.position.x = -90
            // Off the middle, so the mirror and the paddle are each on their own

            PaddleFamilySweep.settle(0.4)
            failures += check(scene, "\(name) whole", retroWhole: name == "retro")

            scene.endlessIICollectDoublePaddle()
            PaddleFamilySweep.settle(0.4)
            failures += check(scene, "\(name) split", retroWhole: false)

            scene.applyPowerUp(node: SKSpriteNode(texture: scene.powerUpIncreasePaddleSize),
                               silently: true)
            PaddleFamilySweep.settle(1.0)
            // Long enough for Expand's animation to finish
            failures += check(scene, "\(name) split and expanded", retroWhole: false)

            scene.endlessIICollectPortalPaddle()
            PaddleFamilySweep.settle(0.3)
            failures += checkGlows(scene, "\(name) split with a Portal")
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    private func check(_ scene: GameScene, _ state: String, retroWhole: Bool) -> [String] {
        var failures: [String] = []
        let surfaces: [(String, SKNode?, CGFloat, UInt32)] = [
            ("paddle", scene.paddle, scene.paddle.position.y, CollisionTypes.paddleCategory.rawValue),
            ("mirror", scene.childNode(withName: GameScene.endlessIIMirrorPaddleName),
             scene.paddle.position.y, CollisionTypes.mirrorPaddleCategory.rawValue),
            ("safety bar", scene.childNode(withName: GameScene.endlessIISafetyPaddleName),
             scene.endlessIISafetyPaddleY, CollisionTypes.safetyPaddleCategory.rawValue)
        ]
        let slack: CGFloat = retroWhole ? 14 : 1.5
        for (name, node, y, category) in surfaces {
            guard let node else {
                failures.append("\(state): no \(name) at all")
                continue
            }
            let solid = PaddleFamilySweep.solid(in: scene, y: y, category: category)
            let drawn = PaddleFamilySweep.drawn(node, in: scene)
            guard solid.count == drawn.count else {
                failures.append("\(state), \(name): solid \(solid.map(PaddleFamilySweep.text)) "
                                + "but drawn \(drawn.map(PaddleFamilySweep.text))")
                continue
            }
            for (body, picture) in zip(solid, drawn)
            where abs(body.lowerBound - picture.lowerBound) > slack
                || abs(body.upperBound - picture.upperBound) > slack {
                failures.append("\(state), \(name): solid \(PaddleFamilySweep.text(body)) "
                                + "drawn \(PaddleFamilySweep.text(picture))")
            }
        }
        return failures
    }

    /// A halo round each piece of the paddle and of the mirror, and none across a gap (James,
    /// round 395).
    private func checkGlows(_ scene: GameScene, _ state: String) -> [String] {
        var failures: [String] = []
        let paddleGlows = ([scene.endlessIIPaddleGlowNode].compactMap { $0 }
                           + scene.endlessIIPaddlePieceGlows).map { $0.position.x }.sorted()
        let pieces = scene.endlessIISplitSegmentCentres.sorted()
        if paddleGlows.count != pieces.count
            || zip(paddleGlows, pieces).contains(where: { abs($0 - $1) > 0.5 }) {
            failures.append("\(state): paddle halos at \(paddleGlows.map { Int($0) }) "
                            + "for pieces at \(pieces.map { Int($0) })")
        }
        if let mirror = scene.childNode(withName: GameScene.endlessIIMirrorPaddleName) {
            let offsets = pieces.map { $0 - scene.paddle.position.x + mirror.position.x }.sorted()
            let mirrorGlows = scene.endlessIIMirrorGlows.map { $0.position.x }.sorted()
            if mirrorGlows.count != offsets.count
                || zip(mirrorGlows, offsets).contains(where: { abs($0 - $1) > 0.5 }) {
                failures.append("\(state): mirror halos at \(mirrorGlows.map { Int($0) }) "
                                + "for pieces at \(offsets.map { Int($0) })")
            }
        }
        return failures
    }
}

/// Whatever the paddle power-ups put on the paddle, they take off again.
///
/// Every pair of them, collected together and run out the way play runs them out - turns spent
/// by landings, the goodbye second let pass, and a Wipe for the ones measured in time - and then
/// nothing they dressed the paddle family in may be left: no sticky face, no pieces or holders,
/// no strips, no halos, no twin, no aim still held or owed. Round 392's sticky face after Ball
/// Spin was a debt left owing in exactly this way, and only one ordering of two power-ups with a
/// ball held between them showed it; with Aimed Sticky in a pair the ball is caught first, so
/// that ordering is one of these.
final class PaddlePowerUpsEndCleanlyTests: XCTestCase {
    private var window: UIWindow?

    private typealias PowerUp = (name: String, collect: (GameScene) -> Void)

    private let powerUps: [PowerUp] = [
        ("Sticky", { $0.applyPowerUp(node: SKSpriteNode(texture: $0.powerUpStickyPaddle), silently: true) }),
        ("Aimed Sticky", { scene in
            scene.endlessIICollectAimedSticky()
            _ = scene.endlessIIAimedCatch(scene.ball, isExtra: false)
        }),
        ("Ball Spin", { $0.endlessIICollectBallSpin() }),
        ("Lasers", { $0.applyPowerUp(node: SKSpriteNode(texture: $0.powerUpLasers), silently: true) }),
        ("Split", { $0.endlessIICollectDoublePaddle() }),
        ("Mirror", { $0.endlessIICollectMirrorPaddle() }),
        ("Safety", { $0.endlessIICollectSafetyPaddle() }),
        ("Portal", { $0.endlessIICollectPortalPaddle() }),
        ("Magnetism", { $0.endlessIICollectMagnetism() }),
        ("Halo", { $0.endlessIICollectPaddleHalo() }),
        ("Expand", { $0.applyPowerUp(node: SKSpriteNode(texture: $0.powerUpIncreasePaddleSize), silently: true) }),
        ("Shrink", { $0.applyPowerUp(node: SKSpriteNode(texture: $0.powerUpDecreasePaddleSize), silently: true) }),
        ("Convex", { $0.endlessIICollectPaddleSurface(.convex) }),
        ("Wedge", { $0.endlessIICollectPaddleSurface(.wedgeLeft) })
    ]

    func testEveryPairOfPaddlePowerUpsLeavesNothingBehind() throws {
        try sweep(themes: [0, GameScene.paddleThemePrefixes.firstIndex(of: "retro") ?? 11])
    }

    private func sweep(themes: [Int]) throws {
        var failures: [String] = []
        for theme in themes {
            let scene = try PaddleFamilySweep.present(theme: theme, keeping: &window)
            for first in powerUps.indices {
                for second in powerUps.indices where second >= first {
                    let pair = first == second ? powerUps[first].name
                        : "\(powerUps[first].name) then \(powerUps[second].name)"
                    powerUps[first].collect(scene)
                    PaddleFamilySweep.settle(0.1)
                    powerUps[second].collect(scene)
                    PaddleFamilySweep.settle(0.1)
                    runOut(scene)
                    failures += leftovers(scene).map { "theme \(theme), \(pair): \($0)" }
                    reset(scene)
                }
            }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// The way play ends them: every turn spent by a landing, the goodbye second, the held balls
    /// let go by their tap, and a Wipe for the ones counted in seconds.
    private func runOut(_ scene: GameScene) {
        for _ in 0..<20 {
            scene.endlessIISpendPaddleTurns()
            scene.stickyPaddleCatches = max(0, scene.stickyPaddleCatches - 1)
        }
        scene.runEndlessIILingeringClocks(EndlessIIClock.lingerSeconds + 0.1)
        PaddleFamilySweep.settle(0.1)
        scene.endlessIIWipe()
        PaddleFamilySweep.settle(0.1)
        if scene.endlessIIAimHold { _ = scene.endlessIIAimLaunch() }
        // The tap that launches a ball being aimed
        scene.endlessIIReleaseRemainingHeldBalls()
        PaddleFamilySweep.settle(0.5)
        // Long enough for the twins' fades (0.2s) and the size power-ups' animations back
    }

    private func leftovers(_ scene: GameScene) -> [String] {
        var found: [String] = []
        if scene.paddleSticky.isHidden == false { found.append("the sticky face is still on") }
        if scene.paddleRetroStickyTexture.isHidden == false, scene.paddleTexture == scene.retroPaddle {
            found.append("Retro's sticky band is still on")
        }
        if scene.endlessIIAimHold { found.append("an aim is still held") }
        if scene.endlessIIAimOwedHold { found.append("an aim is still owed") }
        if scene.endlessIIWearsGrip { found.append("the grip is still on") }
        if scene.paddle.childNode(withName: GameScene.endlessIISplitHolderName) != nil {
            found.append("the paddle is still in pieces")
        }
        if scene.paddle.texture == nil { found.append("the paddle draws nothing") }
        if scene.endlessIISplitOverlays.values.contains(where: { $0.isEmpty == false }) {
            found.append("split strip pieces are still drawn")
        }
        if scene.endlessIIPaddleGlowNode != nil || scene.endlessIIPaddlePieceGlows.isEmpty == false {
            found.append("the paddle still glows")
        }
        if scene.endlessIIMirrorGlows.isEmpty == false { found.append("a mirror glow is left") }
        if scene.childNode(withName: GameScene.endlessIIMirrorPaddleName) != nil {
            found.append("the mirror is still standing")
        }
        if scene.childNode(withName: GameScene.endlessIISafetyPaddleName) != nil {
            found.append("the safety bar is still standing")
        }
        let strips = scene.endlessIIMirrorOverlayNames
        if scene.children.contains(where: { node in
            strips.contains { node.name == $0 || node.name?.hasPrefix($0 + "#") == true }
        }) {
            found.append("a mirror strip is left")
        }
        if scene.paddleLaser.alpha < 0.99 { found.append("the laser strip was left at alpha 0") }
        if abs(scene.paddle.xScale - 1) > 0.01 { found.append("the paddle is still resized") }
        return found
    }

    /// Back to a plain paddle for the next pair, whatever this one left - a leftover is reported
    /// once, not inherited by every pair after it.
    private func reset(_ scene: GameScene) {
        scene.endlessIIWipe()
        scene.endlessIIEndAim()
        scene.endlessIIAimHold = false
        scene.stickyPaddleCatches = 0
        PaddleFamilySweep.settle(0.3)
    }
}

/// What the two sweeps share: a laid-out scene, frames to let it run, and the measuring.
enum PaddleFamilySweep {

    static func present(theme: Int, keeping window: inout UIWindow?,
                        resuming: Bool = false, mode: GameMode = .endlessII,
                        frozen: Bool = true, level: Int? = nil,
                        pack: Int = 1, stats: TotalStats = TotalStats()) throws -> GameScene {
        if resuming == false {
            GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
            SavedGame.clear(from: GameScene.settingsStore)
            mode.makeCurrent(in: GameScene.settingsStore)
        }
        // Resuming, the save and the flag the last scene left are the whole point
        GameScene.settingsStore.set(theme, forKey: "paddleSetting")
        let board = UIStoryboard(name: "Main", bundle: Bundle(for: GameViewController.self))
        let game = try XCTUnwrap(board.instantiateViewController(withIdentifier: "gameView")
                                 as? GameViewController)
        game.selectedLevel = level ?? LevelPackSetup.shared.startLevelNumber[1]
        game.numberOfLevels = 1
        game.levelSender = "MainMenu"
        game.levelPack = pack
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let made = UIWindow(windowScene: windowScene)
        let host = UIViewController()
        let view = SKView(frame: made.bounds)
        host.view = view
        made.rootViewController = host
        made.makeKeyAndVisible()
        window = made
        let scene = try XCTUnwrap(GameScene(fileNamed: "GameScene"))
        scene.totalStatsArray = [stats]
        scene.gameViewControllerDelegate = game
        scene.scaleMode = .aspectFit
        scene.size = view.bounds.size
        view.presentScene(scene)
        settle(1.5)
        for _ in 0..<45 where scene.gameState.currentState is Playing == false {
            settle(0.1)
        }
        // **Into play by itself where it can** (round 398). A level's intro reveals its bricks on
        // the way into `Playing`, and forcing the state below skips that: the daily sweep met a
        // whole field solid and hidden, from the run's first frame, on a Mac busy enough that
        // a second and a half was not long enough. Usually it is, and this waits for nothing
        for _ in 0..<3 where scene.finishEndlessIIBuildIn() {}
        if !(scene.gameState.currentState is Playing) { scene.gameState.enter(Playing.self) }
        if resuming == false { scene.releaseBall() }
        // A resumed run is looked at as it came back; serving its ball would spend a Sticky
        // catch on the way in
        settle(0.1)
        guard frozen else { return scene }
        scene.physicsWorld.speed = 0
        scene.ball.position = CGPoint(x: -190, y: 150)
        // Launched and still, high in the field: nothing the ball does can be on the lines
        // being probed, and it neither breaks bricks nor is lost while the sweep runs
        return scene
    }

    static func settle(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// The stretches along a line where a body of this category is, at half-point steps.
    static func solid(in scene: GameScene, y: CGFloat, category: UInt32) -> [ClosedRange<CGFloat>] {
        var found: [ClosedRange<CGFloat>] = []
        var start: CGFloat?
        let edge = scene.size.width/2
        var x = -edge
        while x <= edge {
            let hit = scene.physicsWorld.body(at: CGPoint(x: x, y: y))
                .map { $0.categoryBitMask & category != 0 } ?? false
            if hit, start == nil { start = x }
            if hit == false, let from = start {
                found.append(from...(x - 0.5))
                start = nil
            }
            x += 0.5
        }
        if let from = start { found.append(from...edge) }
        return found
    }

    /// The stretches a node draws across, merged where its sprites touch: every visible sprite
    /// with a picture, the node itself and everything under it.
    static func drawn(_ node: SKNode, in scene: GameScene) -> [ClosedRange<CGFloat>] {
        var spans: [ClosedRange<CGFloat>] = []
        func walk(_ current: SKNode) {
            guard current.isHidden == false, current.alpha > 0.01 else { return }
            if let sprite = current as? SKSpriteNode, sprite.texture != nil {
                let frame = sprite.frame
                let parent = sprite.parent ?? scene
                let left = scene.convert(CGPoint(x: frame.minX, y: frame.midY), from: parent).x
                let right = scene.convert(CGPoint(x: frame.maxX, y: frame.midY), from: parent).x
                spans.append(min(left, right)...max(left, right))
            }
            current.children.forEach(walk)
        }
        walk(node)
        var merged: [ClosedRange<CGFloat>] = []
        for span in spans.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            if let last = merged.last, span.lowerBound <= last.upperBound + 1 {
                merged[merged.count - 1] = last.lowerBound...max(last.upperBound, span.upperBound)
            } else {
                merged.append(span)
            }
        }
        return merged
    }

    /// The box a body covers near a point, probed every half point; nil where it is nowhere.
    static func solidBox(of body: SKPhysicsBody, in scene: GameScene, around: CGRect) -> CGRect? {
        var box: CGRect?
        var y = around.minY
        while y <= around.maxY {
            var x = around.minX
            while x <= around.maxX {
                if scene.physicsWorld.body(at: CGPoint(x: x, y: y)) === body {
                    let point = CGRect(x: x, y: y, width: 0, height: 0)
                    box = box?.union(point) ?? point
                }
                x += 0.5
            }
            y += 0.5
        }
        return box
    }

    /// The box a node draws across, in the scene: every visible sprite with a picture under it,
    /// leaving out the halos, which are drawn bigger than the thing they light on purpose.
    static func drawnBox(of node: SKNode, in scene: GameScene) -> CGRect? {
        var box: CGRect?
        func walk(_ current: SKNode) {
            guard current.isHidden == false, current.alpha > 0.01 else { return }
            if (current.name ?? "").lowercased().contains("glow") { return }
            if let sprite = current as? SKSpriteNode, sprite.texture != nil {
                let frame = sprite.frame
                let parent = sprite.parent ?? scene
                let corners = [CGPoint(x: frame.minX, y: frame.minY), CGPoint(x: frame.maxX, y: frame.maxY),
                               CGPoint(x: frame.minX, y: frame.maxY), CGPoint(x: frame.maxX, y: frame.minY)]
                    .map { scene.convert($0, from: parent) }
                let xs = corners.map(\.x), ys = corners.map(\.y)
                let drawn = CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!,
                                   height: ys.max()! - ys.min()!)
                box = box?.union(drawn) ?? drawn
            }
            current.children.forEach(walk)
        }
        walk(node)
        return box
    }

    static func text(_ box: CGRect) -> String {
        "\(Int(box.minX.rounded()))...\(Int(box.maxX.rounded())) x \(Int(box.minY.rounded()))...\(Int(box.maxY.rounded()))"
    }

    static func text(_ span: ClosedRange<CGFloat>) -> String {
        "\(Int(span.lowerBound.rounded()))...\(Int(span.upperBound.rounded()))"
    }
}
