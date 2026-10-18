//
//  GameSweepTests.swift
//  GigaBallTests
//
//  Two more sweeps of the kind `PaddleFamilySweepTests` began (round 395): every member of a
//  family asked the same question at once, so a fault in one of them is found here rather than in
//  a play test. James, round 395: "please run these new tests now and think about what other tests
//  we can implement to ensure there are no silly mistakes before launch."
//

import XCTest
import SpriteKit
@testable import Giga_Ball

/// Every brick is drawn where it is solid.
///
/// Every style on every behaviour, every shape with every action it can carry, and every size,
/// each built in a cleared field through the generator's own `applyEndlessIIStyle` - then its body
/// probed point by point and set against what it draws. The paddle family's sweep found pieces
/// drawn half as far out again as their bodies; this asks the same of the bricks, straight after
/// the style goes on and again a few frames later, because several of them move.
final class BricksDrawnWhereSolidTests: XCTestCase {
    private var window: UIWindow?

    func testEveryKindOfBrickIsDrawnWhereItIsSolid() throws {
        let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window)
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in node.removeFromParent() }
        PaddleFamilySweep.settle(0.1)
        let rowY = scene.yBrickOffsetEndless - scene.brickHeight*8
        // A clear stretch of field, half way down

        let behaviours: [(String, SKTexture)] = [
            ("standard", scene.brickNormalTexture), ("multi-hit", scene.brickMultiHit3Texture),
            ("indestructible", scene.brickIndestructible2Texture),
            ("invisible", scene.brickInvisibleTexture)]
        let shapes = EndlessIIStyle.allCases.filter { $0.isShape }
        let actions = EndlessIIStyle.allCases.filter { $0.isShape == false }

        var failures: [String] = []
        var checked = 0
        func check(_ name: String, build: () -> [SKSpriteNode]?) {
            guard let bricks = build() else { return }
            checked += 1
            failures += bricks.flatMap { compare($0, in: scene, name) }
            PaddleFamilySweep.settle(0.25)
            failures += bricks.filter { moving in
                scene.endlessIISpinners.contains { $0.brick === moving } == false
                    && scene.endlessIIBreathers.contains { $0.brick === moving } == false
            }.flatMap { compare($0, in: scene, "\(name), a moment later") }
            // Not a Spinning brick once it has turned - a turned picture's box takes in its
            // transparent corners - and not a Breathing one mid-breath, whose body is rebuilt in
            // steps behind a picture redrawn every frame, on purpose (round 235). Both were
            // compared before they started moving
            bricks.forEach { $0.removeFromParent() }
            scene.endlessIIPortalCooldown = 0
        }

        for (behaviour, texture) in behaviours {
            for size in ["normal", "square", "big"] {
                check("\(behaviour) \(size), plain") {
                    [brick(size, texture: texture, in: scene, rowY: rowY)]
                }
                for style in EndlessIIStyle.allCases {
                    check("\(behaviour) \(size), \(style)") {
                        let made = brick(size, texture: texture, in: scene, rowY: rowY)
                        guard scene.endlessIICanTake(style, made) else {
                            made.removeFromParent()
                            return nil
                        }
                        scene.applyEndlessIIStyle(style, to: made)
                        return [made]
                    }
                }
            }
            check("\(behaviour) tiny") {
                scene.makeTiny(brick("normal", texture: texture, in: scene, rowY: rowY))
            }
        }
        for shape in shapes {
            for action in actions {
                check("\(shape) and \(action)") {
                    let made = brick("normal", texture: scene.brickNormalTexture, in: scene, rowY: rowY)
                    guard scene.endlessIICanTake(shape, made) else {
                        made.removeFromParent()
                        return nil
                    }
                    scene.applyEndlessIIStyle(shape, to: made)
                    guard scene.endlessIICanTake(action, made) else {
                        made.removeFromParent()
                        return nil
                    }
                    scene.applyEndlessIIStyle(action, to: made)
                    return [made]
                }
            }
        }

        XCTAssertGreaterThan(checked, 100, "the sweep built the bricks it set out to")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    private func brick(_ size: String, texture: SKTexture, in scene: GameScene,
                       rowY: CGFloat) -> SKSpriteNode {
        let made: SKSpriteNode
        switch size {
        case "square": made = scene.endlessIIMakeSquare(column: 5, rowY: rowY)
        case "big": made = scene.endlessIIMakeBig(leftColumn: 4, rowY: rowY)
        default:
            made = SKSpriteNode(texture: texture)
            made.size = CGSize(width: scene.brickWidth, height: scene.brickHeight)
            made.position = CGPoint(x: -scene.gameWidth/2 + scene.brickWidth*5.5, y: rowY)
            made.zPosition = 1
            made.name = BrickCategoryName
            made.physicsBody = scene.brickBody(SKPhysicsBody(rectangleOf: made.size))
            scene.addChild(made)
        }
        made.texture = texture
        made.color = scene.brickWhite
        made.colorBlendFactor = texture == scene.brickNormalTexture ? 1 : 0
        made.isHidden = texture == scene.brickInvisibleTexture
        scene.refreshEndlessIIBrickArt(made)
        return made
    }

    private func compare(_ brick: SKSpriteNode, in scene: GameScene, _ name: String) -> [String] {
        guard brick.parent != nil, let body = brick.physicsBody else { return [] }
        let around = scene.endlessIIFieldRect(of: brick).insetBy(dx: -12, dy: -12)
        guard let solid = PaddleFamilySweep.solidBox(of: body, in: scene, around: around) else {
            if scene.endlessIIFlashers.contains(where: { $0.brick === brick }) { return [] }
            // A Flashing brick between flashes is passable, which is the whole of what it is
            return ["\(name): no body anywhere near its cell"]
        }
        guard brick.isHidden == false else { return [] }
        // An invisible brick draws nothing until it is found, on purpose
        guard let drawn = PaddleFamilySweep.drawnBox(of: brick, in: scene) else {
            return ["\(name): solid at \(PaddleFamilySweep.text(solid)) and drawn nowhere"]
        }
        let slack: CGFloat = brick.endlessIIFace != nil ? 2.5 : 1.5
        // A shaped brick's body is traced from its picture's outline, which is good to a couple
        // of points at a wedge's thin end
        if abs(solid.minX - drawn.minX) > slack || abs(solid.maxX - drawn.maxX) > slack
            || abs(solid.minY - drawn.minY) > slack || abs(solid.maxY - drawn.maxY) > slack {
            return ["\(name): solid \(PaddleFamilySweep.text(solid)), "
                    + "drawn \(PaddleFamilySweep.text(drawn))"]
        }
        return []
    }
}

/// Every power-up is shown while it runs, comes back as it was from a save, and goes with a Wipe.
///
/// Each of Mayhem's power-ups applied in a real run, one at a time. Whatever it leaves running -
/// a clock, a classic timer, a twin, a split, a resize, more balls - must show its own ring in the
/// HUD, and a power-up that leaves nothing running must leave no ring. The run is then saved and
/// resumed in a second scene, which must have the same things running and the same rings; and a
/// Wipe, which ends every power-up in the mode, must leave the first scene with nothing running
/// and no ring at all.
final class EveryPowerUpShowsSavesAndEndsTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        // The test suite's own store, not the app's - and left as the next test expects it
        super.tearDown()
    }

    private struct State: Equatable {
        var running: [String]
        var rings: [String]
    }

    private func state(of scene: GameScene) -> State {
        var running: [String] = []
        for path in GameScene.endlessIIWipeableClockPaths where scene[keyPath: path].isRunning {
            let clock = scene[keyPath: path]
            running.append("\(path)" + (clock.countsTurns ? " \(Int(clock.remaining.rounded())) turns" : ""))
        }
        for timer in scene.endlessIIClassicTimers where scene.action(forKey: timer.key) != nil {
            running.append(timer.key)
        }
        if scene.childNode(withName: GameScene.endlessIIMirrorPaddleName) != nil { running.append("mirror") }
        if scene.childNode(withName: GameScene.endlessIISafetyPaddleName) != nil { running.append("safety bar") }
        if scene.paddle.childNode(withName: GameScene.endlessIISplitHolderName) != nil { running.append("split") }
        if abs(scene.paddle.xScale - 1) > 0.05 { running.append("paddle resized") }
        if scene.endlessIIBallsInPlay.count > 1 { running.append("\(scene.endlessIIBallsInPlay.count) balls") }
        if scene.stickyPaddleCatches > 0 { running.append("sticky \(scene.stickyPaddleCatches)") }
        if scene.backstopCatches > 0 { running.append("backstop") }
        if scene.endlessIILocked { running.append("locked") }
        if scene.endlessIITrajectoryRemaining > 0 {
            running.append("trajectory \(Int(scene.endlessIITrajectoryRemaining.rounded()))")
        }
        if scene.endlessIILandingRemaining > 0 {
            running.append("landing marker \(Int(scene.endlessIILandingRemaining.rounded()))")
        }
        // The two Vision power-ups keep counters of their own rather than a clock
        return State(running: running.sorted(),
                     rings: scene.activePowerUpEntries().map(\.id).sorted())
    }

    func testEveryPowerUpIsShownSurvivesAResumeAndEnds() throws {
        let names = LevelPackSetup.shared.powerUpNameArray
        let setup = LevelPackSetup.shared
        var failures: [String] = []
        var resumes = 0
        let count = try PaddleFamilySweep.present(theme: 0, keeping: &window).powerUpTextureArray.count

        for index in 0..<count
        where setup.retiredPowerUpIndices.contains(index) == false
            && index != 1 && index != 24 {
            // Lose a Life ends a Mayhem run, which has one; Mystery is a drop of another one
            let name = names.indices.contains(index) ? names[index] : "power-up \(index)"
            let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window)
            // A fresh run for each, so what one leaves is reported against that one alone
            guard scene.powerUpCanAppear(index) else { continue }
            // Only what this run could actually drop: the points, lives, multipliers and
            // Complete Level never appear in an endless mode
            let before = state(of: scene)
            let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[index])
            scene.addChild(carrier)
            scene.applyPowerUp(node: carrier, silently: true)
            PaddleFamilySweep.settle(0.3)

            let applied = state(of: scene)
            let lasting = applied.running != before.running
            let ringless = applied.running.filter { item in
                ["backstop", "locked"].contains(item) == false && item.hasSuffix(" balls") == false
            } == before.running
            // Three things run with no ring by design: the Backstop, which is drawn across the
            // field instead; a Lock, which shows itself by turning every other ring white; and
            // extra balls, which are balls
            if lasting {
                if applied.rings == before.rings, ringless == false {
                    failures.append("\(name): running \(applied.running) with no ring shown")
                } else if let ring = GameScene.ringID(forPowerUp: index),
                          applied.rings.contains(ring) == false {
                    failures.append("\(name): running, but its own ring \(ring) is not among "
                                    + "\(applied.rings)")
                }

                scene.saveCurrentGame()
                GameScene.settingsStore.set(true, forKey: SavedGame.resumeFlagKey)
                let resumed = try PaddleFamilySweep.present(theme: 0, keeping: &resumedWindow,
                                                            resuming: true)
                let back = state(of: resumed)
                resumes += 1
                if back.running != applied.running {
                    failures.append("\(name): saved \(applied.running), resumed \(back.running)")
                }
                if back.rings != applied.rings {
                    failures.append("\(name): saved rings \(applied.rings), resumed \(back.rings)")
                }
                resumed.view?.presentScene(nil)
                resumedWindow = nil
                GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
            } else if applied.rings != before.rings {
                failures.append("\(name): nothing running, and a ring left \(applied.rings)")
            }

            scene.endlessIIWipe()
            PaddleFamilySweep.settle(0.6)
            let after = state(of: scene)
            let kept = after.running.filter { $0.hasSuffix(" balls") == false && $0 != "locked" }
            // Extra balls are balls, not a power-up a Wipe takes away; and a Wipe leaves a Lock
            // where it is on purpose (§5.4), or it would be a better Key than the Key
            if kept != before.running || after.rings != before.rings {
                failures.append("\(name): after a Wipe, still running \(after.running), "
                                + "rings \(after.rings)")
            }
            scene.view?.presentScene(nil)
        }
        XCTAssertGreaterThan(resumes, 20, "the sweep saved and resumed the ones that last")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
