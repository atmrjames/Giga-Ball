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
            failures += bricks.filter { brick in
                scene.endlessIISpinners.contains { $0.brick === brick } == false
                    && scene.endlessIIBreathers.contains { $0.brick === brick } == false
                    && scene.endlessIIStyles(on: brick).contains(.moving) == false
                    && scene.endlessIIStyles(on: brick).contains(.gravity) == false
            }.flatMap { compare($0, in: scene, "\(name), a moment later") }
            // Not a Spinning brick once it has turned - a turned picture's box takes in its
            // transparent corners - and not a Breathing one mid-breath, whose body is rebuilt in
            // steps behind a picture redrawn every frame, on purpose (round 235). Nor one that is
            // sliding or falling: it is moved in `update` and its body follows on the next step,
            // so mid-move the two are a frame apart - inside the allowance on an idle Mac, outside
            // it with four simulators sharing the processors. All of them were compared before
            // they started moving
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
        BrickSweep.brick(size, texture: texture, in: scene, rowY: rowY, column: 5)
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

/// Every kind of brick comes back from a save as it was left.
///
/// The bricks `BricksDrawnWhereSolidTests` builds - every style on every behaviour and size, every
/// shape with every action - laid out a batch at a time in a cleared Mayhem field, saved, and
/// resumed in a second scene. The save the second scene would write must say exactly what the
/// first one's did, field for field, and every brick must be drawn and solid where it was. Round
/// 386's bricks off their rows after a resume, round 174's Directional brick open on a new face
/// and round 150's Rounded brick shrinking on every resume were each one kind of brick at a time;
/// this asks it of all of them.
final class BricksSaveAndResumeTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        window = nil
        resumedWindow = nil
        super.tearDown()
    }

    func testEveryKindOfBrickComesBackFromASaveAsItWasLeft() throws {
        typealias Build = (name: String, make: (GameScene, CGFloat, Int) -> [SKSpriteNode]?)
        var builds: [Build] = []
        let behaviours: [(String, (GameScene) -> SKTexture)] = [
            ("standard", { $0.brickNormalTexture }), ("multi-hit", { $0.brickMultiHit3Texture }),
            ("indestructible", { $0.brickIndestructible2Texture }),
            ("invisible", { $0.brickInvisibleTexture })]
        func styled(_ size: String, _ texture: @escaping (GameScene) -> SKTexture,
                    _ styles: [EndlessIIStyle]) -> (GameScene, CGFloat, Int) -> [SKSpriteNode]? {
            { scene, rowY, column in
                let made = BrickSweep.brick(size, texture: texture(scene), in: scene, rowY: rowY,
                                            column: column)
                for style in styles {
                    guard scene.endlessIICanTake(style, made) else {
                        made.removeFromParent()
                        return nil
                    }
                    scene.applyEndlessIIStyle(style, to: made)
                }
                return [made]
            }
        }
        for (behaviour, texture) in behaviours {
            for size in ["normal", "square", "big"] {
                builds.append(("\(behaviour) \(size), plain", styled(size, texture, [])))
                for style in EndlessIIStyle.allCases {
                    builds.append(("\(behaviour) \(size), \(style)", styled(size, texture, [style])))
                }
            }
            builds.append(("\(behaviour) tiny", { scene, rowY, column in
                scene.makeTiny(BrickSweep.brick("normal", texture: texture(scene), in: scene,
                                                rowY: rowY, column: column))
            }))
        }
        for shape in EndlessIIStyle.allCases where shape.isShape {
            for action in EndlessIIStyle.allCases where action.isShape == false {
                builds.append(("\(shape) and \(action)",
                               styled("normal", { $0.brickNormalTexture }, [shape, action])))
            }
        }

        var failures: [String] = []
        var saved = 0
        var pending = builds[...]
        while pending.isEmpty == false {
            let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window)
            scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                node.removeFromParent()
            }
            PaddleFamilySweep.settle(0.1)
            scene.ball.position = CGPoint(x: -scene.gameWidth/2 + scene.brickWidth*2.5,
                                          y: scene.yBrickOffsetEndless - scene.brickHeight*16)
            scene.ball.physicsBody?.velocity = .zero
            // And still: the save carries its velocity too, and a ball moving through the
            // resumed scene's settling second flew into the batch (round 398b)
            // Out of every slot. The presenter parks the ball where a Big brick at row 9, column
            // 1 stands, which is harmless while this scene is frozen - but the save carries the
            // ball there, the resumed scene runs while it settles, and the ball struck that brick:
            // a Flashing brick gone, a multi-hit a hit down, an invisible one revealed, all on
            // the one spot. Column 2 is never used, and nothing falls down it
            var laid: [(name: String, bricks: [SKSpriteNode])] = []
            laid.append(("the brick holding the field", [
                BrickSweep.brick("normal", texture: scene.brickNormalTexture, in: scene,
                                 rowY: scene.finalBrickRowHeight, column: 0)]))
            // The field steps down whenever its bottom row is empty, and the resumed scene would
            // carry every brick here two rows lower while it settled. One brick in the bottom
            // row holds it, in both scenes
            let columns = GameSceneLayout.brickColumns
            slots: for row in [5, 9, 13] {
                let rowY = scene.yBrickOffsetEndless - scene.brickHeight*CGFloat(row)
                for column in stride(from: 1, to: columns, by: 3) {
                    var placed = false
                    while placed == false, let build = pending.popFirst() {
                        if let bricks = build.make(scene, rowY, column) {
                            laid.append((build.name, bricks))
                            placed = true
                        }
                    }
                    if placed == false { break slots }
                }
            }
            let found = try compareAcrossAResume(scene, laid)
            if found.isEmpty == false {
                failures += found + ["  in a batch of \(laid.map(\.name).joined(separator: ", "))"]
            }
            saved += laid.count
            scene.view?.presentScene(nil)
        }
        XCTAssertGreaterThan(saved, 150, "the sweep saved the bricks it set out to")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    private struct Look {
        let name: String
        let drawn: CGRect?
        let solid: CGRect?
        let position: CGPoint
    }

    private func looks(of bricks: [SKSpriteNode], named: (SKSpriteNode) -> String,
                       in scene: GameScene) -> [Look] {
        bricks.map { brick in
            let around = scene.endlessIIFieldRect(of: brick).insetBy(dx: -12, dy: -12)
            return Look(name: named(brick),
                        drawn: brick.isHidden ? nil : PaddleFamilySweep.drawnBox(of: brick, in: scene),
                        solid: brick.physicsBody.flatMap {
                            PaddleFamilySweep.solidBox(of: $0, in: scene, around: around)
                        },
                        position: brick.position)
        }
    }

    /// Whether a brick can look different a second later without anything being wrong: it
    /// moves, falls, turns, breathes or flashes, all of them driven from `update`.
    private func restless(_ brick: SKSpriteNode, in scene: GameScene) -> Bool {
        brick.endlessIIRole == .moving || brick.endlessIIRole == .gravity
            || scene.endlessIISpinners.contains { $0.brick === brick }
            || scene.endlessIIBreathers.contains { $0.brick === brick }
            || scene.endlessIIFlashers.contains { $0.brick === brick }
    }

    private func records(in scene: GameScene) throws -> [[String: Any]] {
        scene.saveCurrentGame()
        let saved = SavedGame.load(from: GameScene.settingsStore)?.endlessIIBricks ?? []
        return try saved.map {
            try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode($0))
                          as? [String: Any])
        }
    }

    /// Every field two saved bricks disagree on, as "field saved a, resumed b".
    private func differences(_ saved: [String: Any], _ resumed: [String: Any],
                             wanders: Bool) -> [String] {
        let plain = [0, 1].contains(saved["texture"] as? Int ?? -1)
            && saved["role"] as? String != EndlessIIRole.portal.rawValue
        var found: [String] = []
        for key in Set(saved.keys).union(resumed.keys).sorted() {
            if wanders, key == "x" || key == "y" { continue }
            // It wanders or falls on its own while the second scene settles
            if key == "colour", plain == false { continue }
            // Only a plain brick is drawn in its colour: every other picture carries its own, and
            // a Portal is coloured by its pair. The number is kept and means nothing
            let a = saved[key], b = resumed[key]
            if let a = a as? Double, let b = b as? Double {
                if abs(a - b) > 0.05 { found.append("\(key) saved \(a), resumed \(b)") }
            } else if "\(a ?? "nil")" != "\(b ?? "nil")" {
                found.append("\(key) saved \(a ?? "nil"), resumed \(b ?? "nil")")
            }
        }
        return found
    }

    private func compareAcrossAResume(_ scene: GameScene,
                                      _ laid: [(name: String, bricks: [SKSpriteNode])]) throws
        -> [String] {
        var failures: [String] = []
        var nameOf: [ObjectIdentifier: String] = [:]
        for (name, bricks) in laid { bricks.forEach { nameOf[ObjectIdentifier($0)] = name } }
        let all = laid.flatMap(\.bricks).filter { $0.parent != nil }
        let still = all.filter { restless($0, in: scene) == false }
        let before = looks(of: still, named: { nameOf[ObjectIdentifier($0)] ?? "?" }, in: scene)
        let restlessNames = Set(all.filter { restless($0, in: scene) }
            .map { nameOf[ObjectIdentifier($0)] ?? "?" })
        func name(near x: Double, _ y: Double) -> String {
            all.min { hypot($0.position.x - x, $0.position.y - y)
                < hypot($1.position.x - x, $1.position.y - y) }
                .flatMap { nameOf[ObjectIdentifier($0)] } ?? "?"
        }

        let savedRecords = try records(in: scene)
        if savedRecords.count < all.count {
            failures.append("\(laid.map(\.name)): \(all.count) bricks and only "
                            + "\(savedRecords.count) saved")
        }

        GameScene.settingsStore.set(true, forKey: SavedGame.resumeFlagKey)
        let resumed = try PaddleFamilySweep.present(theme: 0, keeping: &resumedWindow,
                                                    resuming: true)
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        defer {
            resumed.view?.presentScene(nil)
            resumedWindow = nil
        }
        var back: [SKSpriteNode] = []
        resumed.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            if let sprite = node as? SKSpriteNode { back.append(sprite) }
        }
        let after = looks(of: back, named: { _ in "" }, in: resumed)

        // Field for field: what the resumed scene would save must be what was saved
        var unmatched = try records(in: resumed)
        for record in savedRecords {
            let x = record["x"] as? Double ?? 0, y = record["y"] as? Double ?? 0
            let role = record["role"] as? String
            let wanders = role == EndlessIIRole.moving.rawValue
                || role == EndlessIIRole.gravity.rawValue
            let candidates = unmatched.indices.filter { unmatched[$0]["role"] as? String == role }
            func distance(_ other: [String: Any]) -> Double {
                hypot((other["x"] as? Double ?? 0) - x, (other["y"] as? Double ?? 0) - y)
            }
            guard let nearest = candidates.min(by: { a, b in
                let da = differences(record, unmatched[a], wanders: wanders).count
                let db = differences(record, unmatched[b], wanders: wanders).count
                return da != db ? da < db : distance(unmatched[a]) < distance(unmatched[b])
            }) else {
                failures.append("\(name(near: x, y)): saved, and nothing like it came back")
                continue
            }
            // The one most like it, and of those the nearest. Nearest alone paired a Moving
            // brick that had wandered with whichever brick it had wandered beside
            let other = unmatched.remove(at: nearest)
            for difference in differences(record, other, wanders: wanders) {
                failures.append("\(name(near: x, y)): \(difference)")
            }
        }

        // And drawn and solid where it was
        func near(_ a: CGRect?, _ b: CGRect?) -> Bool {
            guard let a, let b else { return a == nil && b == nil }
            return abs(a.minX - b.minX) < 1.5 && abs(a.maxX - b.maxX) < 1.5
                && abs(a.minY - b.minY) < 1.5 && abs(a.maxY - b.maxY) < 1.5
        }
        for look in before where restlessNames.contains(look.name) == false {
            guard after.contains(where: { near($0.drawn, look.drawn) && near($0.solid, look.solid) })
            else {
                let closest = after.min {
                    hypot($0.position.x - look.position.x, $0.position.y - look.position.y)
                        < hypot($1.position.x - look.position.x, $1.position.y - look.position.y)
                }
                failures.append("\(look.name): drawn \(look.drawn.map { PaddleFamilySweep.text($0) } ?? "-")"
                    + " solid \(look.solid.map { PaddleFamilySweep.text($0) } ?? "-") before; nearest after "
                    + "drawn \(closest?.drawn.map { PaddleFamilySweep.text($0) } ?? "-") "
                    + "solid \(closest?.solid.map { PaddleFamilySweep.text($0) } ?? "-")")
                continue
            }
        }
        return failures
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
        State(running: GameSnapshot.running(in: scene),
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

/// Every power-up still falling when the game is saved comes back as itself.
///
/// James, round 398b: "on resume after quitting both falling power ups turned into extra life
/// power-ups in endless mayhem mode. I then had 2 lives in Endless Mayhem mode which shouldn't be
/// possible." The save named a falling drop through a switch over the original twenty-eight and
/// left everything else at 0 - Get a Life. `EveryPowerUpShowsSavesAndEndsTests` saved power-ups
/// that had been *collected*; this saves them in the air, in all three modes, every one each
/// mode can drop, and asks for exactly the same drops back.
final class EveryFallingPowerUpSurvivesAResumeTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        window = nil
        resumedWindow = nil
        super.tearDown()
    }

    func testEveryFallingPowerUpComesBackAsItself() throws {
        let setup = LevelPackSetup.shared
        let names = setup.powerUpNameArray
        var failures: [String] = []
        var checked = 0
        let veteran = TotalStats()
        veteran.powerUpUnlockedArray = veteran.powerUpUnlockedArray.map { _ in true }

        for mode in [GameMode.endlessII, .classic, .endless] {
            let level = mode == .classic ? setup.startLevelNumber[2] : nil
            let pack = mode == .classic ? 2 : 1
            func fresh() throws -> GameScene {
                try PaddleFamilySweep.present(theme: 0, keeping: &window, mode: mode, level: level,
                                              pack: pack, stats: veteran)
            }
            let probe = try fresh()
            let droppable = probe.powerUpTextureArray.indices.filter { index in
                setup.retiredPowerUpIndices.contains(index) == false
                    && (mode == .endlessII ? probe.powerUpCanAppear(index)
                        : setup.isEndlessIIPowerUp(index) == false)
            }
            // Mayhem's own pool, and the original twenty-eight in the modes they belong to
            for batch in stride(from: 0, to: droppable.count, by: 8) {
                let indices = Array(droppable[batch..<min(batch + 8, droppable.count)])
                let scene = try fresh()
                scene.enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
                    node.removeFromParent()
                }
                for (slot, index) in indices.enumerated() {
                    let drop = SKSpriteNode(texture: scene.powerUpTextureArray[index])
                    drop.size = CGSize(width: scene.brickWidth*0.85, height: scene.brickWidth*0.85)
                    drop.name = PowerUpCategoryName
                    drop.zPosition = 2
                    drop.position = CGPoint(
                        x: -scene.gameWidth/2 + scene.brickWidth*(CGFloat(slot) + 1.5),
                        y: scene.yBrickOffset - scene.brickHeight*CGFloat(10 + slot))
                    scene.addChild(drop)
                    // As `powerUpGenerator` leaves one: the list's own texture, mid-fall
                }
                scene.saveCurrentGame()
                let livesBefore = scene.numberOfLives

                GameScene.settingsStore.set(true, forKey: SavedGame.resumeFlagKey)
                let resumed = try PaddleFamilySweep.present(theme: 0, keeping: &resumedWindow,
                                                            resuming: true, mode: mode,
                                                            level: level, pack: pack,
                                                            stats: veteran)
                GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
                var back: [Int] = []
                resumed.enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
                    guard let texture = (node as? SKSpriteNode)?.texture else { return }
                    back.append(resumed.powerUpTextureArray.firstIndex { $0 === texture } ?? -1)
                }
                let label = { (list: [Int]) in list.sorted().map {
                    names.indices.contains($0) ? names[$0] : "unknown \($0)" } }
                if back.sorted() != indices.sorted() {
                    failures.append("\(mode): saved falling \(label(indices)), resumed "
                                    + "\(label(back))")
                }
                if resumed.numberOfLives != livesBefore {
                    failures.append("\(mode): \(livesBefore) lives saved, \(resumed.numberOfLives) "
                                    + "resumed")
                }
                checked += indices.count
                resumed.view?.presentScene(nil)
                scene.view?.presentScene(nil)
            }
            probe.view?.presentScene(nil)
        }
        XCTAssertGreaterThan(checked, 60, "the sweep dropped the power-ups it set out to")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}

/// Found by `ResumeIsTheSameGameTests`, round 398b: Show Bricks ends Hide Bricks by hiding its
/// bar, and the bar's countdown ran on underneath - so the save wrote Hide Bricks as still
/// running, and the resume hid the whole field again for whatever time that hidden bar had left.
final class ShowBricksStaysShownAcrossAResumeTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        super.tearDown()
    }

    func testBricksShownAgainStayShownAfterAResume() throws {
        for mode in [GameMode.classic, .endless] {
            let level = mode == .classic ? LevelPackSetup.shared.startLevelNumber[2] : nil
            let pack = mode == .classic ? 2 : 1
            let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window, mode: mode,
                                                      level: level, pack: pack)
            for index in [16, 15] {
                // Hide Bricks, then Show Bricks
                let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[index])
                scene.addChild(carrier)
                scene.applyPowerUp(node: carrier, silently: true)
                PaddleFamilySweep.settle(0.5)
            }
            scene.saveCurrentGame()
            XCTAssertFalse(SavedGame.load(from: GameScene.settingsStore)?.activePowerUps
                            .contains("invisibleBricksTimer") ?? false,
                           "\(mode): Hide Bricks saved as running after Show Bricks ended it")

            GameScene.settingsStore.set(true, forKey: SavedGame.resumeFlagKey)
            let resumed = try PaddleFamilySweep.present(theme: 0, keeping: &resumedWindow,
                                                        resuming: true, mode: mode,
                                                        level: level, pack: pack)
            GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
            PaddleFamilySweep.settle(0.5)
            var hidden = 0
            resumed.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
                if node.isHidden, (node as? SKSpriteNode)?.texture === resumed.brickNormalTexture {
                    hidden += 1
                }
            }
            XCTAssertEqual(hidden, 0, "\(mode): \(hidden) bricks hidden again after the resume")
            resumed.view?.presentScene(nil)
            scene.view?.presentScene(nil)
        }
    }
}

/// Every power-up is heard when it is collected: its own recording, or the general chime.
///
/// James, round 397: "For any power-ups without a specific sound, they should play the general
/// power-up sound." Round 334 took the chime away from the ones that say something of their own,
/// and that rule asks for the file - so a power-up whose recording never arrived still chimes.
/// This collects every one an endless run can drop, the way a catch does, and listens for either.
final class EveryPowerUpIsHeardTests: XCTestCase {
    private var window: UIWindow?

    func testEveryPowerUpIsHeardWhenItIsCollected() throws {
        let names = LevelPackSetup.shared.powerUpNameArray
        let setup = LevelPackSetup.shared
        let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window)
        scene.soundsSetting = true
        var failures: [String] = []
        var heard = 0

        for index in scene.powerUpTextureArray.indices
        where setup.retiredPowerUpIndices.contains(index) == false
            && index != 1 && scene.powerUpCanAppear(index) {
            let name = names.indices.contains(index) ? names[index] : "power-up \(index)"
            PaddleFamilySweep.settle(0.12)
            // Past the gap that keeps one sound from playing twice at once
            let chime = scene.powerUpChimedAt
            let mayhem = scene.mayhemSoundLastPlayed
            let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[index])
            scene.addChild(carrier)
            scene.applyPowerUp(node: carrier)
            if scene.powerUpChimedAt != chime || scene.mayhemSoundLastPlayed != mayhem {
                heard += 1
            } else {
                failures.append("\(name): collected in silence")
            }
            scene.endlessIIWipe()
        }
        XCTAssertGreaterThan(heard, 30)
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}

/// A player's whole record comes through the update from 1.2.
///
/// **The first of CLAUDE.md's two constraints that never bend: "Existing progress and Game Center
/// leaderboards stay valid... People hold years of scores."** `Stats-1.2.plist` is a stats file in
/// 1.2's own format - written by 1.2's `TotalStats` (commit 800c48b8, "1.2 (81)"), compiled on its
/// own, every one of its 38 fields set to a value nothing would produce by default, and read back
/// by 1.2's code to be sure (round 398). This decodes it the way 1.3 does on launch and requires
/// every 1.2 value to have arrived unchanged: scalars equal, dates equal, arrays the same from the
/// start and only ever longer, with the new tail what a fresh record holds. A field renamed,
/// retyped or dropped since 1.2 - the way a player's history goes missing - fails here.
final class UpgradeFromOnePointTwoTests: XCTestCase {

    func testEveryValueInA1Point2StatsFileSurvivesTheUpdate() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Stats-1.2",
                                                             withExtension: "plist"))
        let data = try Data(contentsOf: url)
        let old = try XCTUnwrap(
            (try PropertyListSerialization.propertyList(from: data, format: nil) as? [[String: Any]])?
                .first)

        let decoded = try PropertyListDecoder().decode([TotalStats].self, from: data)
            .map { $0.makeStoredArraysConsistent(); return $0 }
        // The load `GameScene.loadGameData` does on launch
        let stats = try XCTUnwrap(decoded.first)
        let now = try XCTUnwrap(
            (try PropertyListSerialization.propertyList(
                from: PropertyListEncoder().encode([stats]), format: nil) as? [[String: Any]])?
                .first)
        let fresh = try XCTUnwrap(
            (try PropertyListSerialization.propertyList(
                from: PropertyListEncoder().encode([TotalStats()]), format: nil) as? [[String: Any]])?
                .first)

        var failures: [String] = []
        for (key, was) in old {
            guard let is_ = now[key] else {
                failures.append("\(key): gone")
                continue
            }
            if let wasList = was as? [Any] {
                guard let isList = is_ as? [Any] else {
                    failures.append("\(key): was a list, now \(type(of: is_))")
                    continue
                }
                if isList.count < wasList.count {
                    failures.append("\(key): \(wasList.count) entries became \(isList.count)")
                    continue
                }
                for (index, (a, b)) in zip(wasList, isList).enumerated()
                where (a as AnyObject).isEqual(b) == false {
                    failures.append("\(key)[\(index)]: \(a) became \(b)")
                    break
                }
                if isList.count > wasList.count, let freshList = fresh[key] as? [Any],
                   freshList.count == isList.count {
                    let tail = Array(isList[wasList.count...])
                    let freshTail = Array(freshList[wasList.count...])
                    if zip(tail, freshTail).contains(where: { ($0 as AnyObject).isEqual($1) == false }) {
                        failures.append("\(key): grown with something other than a fresh record's values")
                    }
                }
            } else if (was as AnyObject).isEqual(is_) == false {
                failures.append("\(key): \(was) became \(is_)")
            }
        }
        XCTAssertEqual(old.count, 38, "the fixture is the whole of 1.2's record")
        XCTAssertTrue(failures.isEmpty, failures.sorted().joined(separator: "\n"))
    }
}

/// The game left to play itself for a while, in every mode, and watched.
///
/// The reports nobody could make happen on demand - a phantom brick, a crooked ball, a ball that
/// left the field (rounds 128, 372, 387) - are the ones a long, busy run turns up. This plays one:
/// the paddle follows the lowest ball, a power-up from the run's own pool lands every second and a
/// half in a seeded order (so a failure can be replayed exactly), and several times a second it
/// asks what must always be true - every ball inside the field, moving, and a number; no brick
/// solid and unseen for more than a moment; and the scene's node count not climbing without end,
/// which is how a leak shows from the outside. A run that ends is started again.
final class LongPlaySessionTests: XCTestCase {
    private var window: UIWindow?

    func testMayhemPlaysForAMinuteWithoutBreakingAnything() throws {
        let failures = try PlayWatch.watch(seconds: 60, seed: 398, label: "Mayhem") {
            try PaddleFamilySweep.present(theme: 0, keeping: &self.window, mode: .endlessII,
                                          frozen: false)
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// James's device log, round 391: on Lonesome Brick a ball crossed the field dead flat,
    /// "heading exactly 180 and then 0 degrees", turned about ten degrees at each wall by
    /// something that left no note. A level of one brick is mostly walls and open air, which
    /// is where a flat ball has nothing to knock it out of it.
    func testLonesomeBrickNeverRunsFlat() throws {
        var failures: [String] = []
        for seed: UInt64 in 1...3 {
            failures += try PlayWatch.watch(seconds: 40, seed: seed, label: "Lonesome Brick",
                                            powerUps: seed != 1) {
                try PaddleFamilySweep.present(theme: 0, keeping: &self.window, mode: .classic,
                                              frozen: false, level: 101, pack: 12)
            }
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    func testClassicAndEndlessPlayWithoutBreakingAnything() throws {
        var failures = try PlayWatch.watch(seconds: 25, seed: 1, label: "Classic") {
            try PaddleFamilySweep.present(theme: 0, keeping: &self.window, mode: .classic,
                                          frozen: false)
        }
        failures += try PlayWatch.watch(seconds: 25, seed: 2, label: "Endless") {
            try PaddleFamilySweep.present(theme: 0, keeping: &self.window, mode: .endless,
                                          frozen: false)
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}

/// James, round 397, on what should be checked before launch: every daily twist, played. A
/// twist is a change to the scene that only a daily makes, so ordinary play never reaches it,
/// and the daily is the one mode whose whole field changes every day.
///
/// Each twist is played alone, for three seconds, in every mode it can be drawn for - and then
/// the next three weeks of real days, as the generator will hand them out, twists combined.
/// The checks are `PlayWatch`'s: balls inside, moving and numbers, nothing solid and unseen,
/// nothing piling up.
final class EveryDailyTwistPlaysTests: XCTestCase {
    private var window: UIWindow?

    override func tearDown() {
        DailyChallengeSession.shared.active = nil
        window = nil
        super.tearDown()
    }

    func testEveryTwistPlaysAloneInEveryModeItIsDrawnFor() throws {
        var failures: [String] = []
        var played = 0
        for (index, twist) in DailyTwist.allCases.enumerated() {
            for mode in [GameMode.classic, .endless, .endlessII] where twist.applies(to: mode) {
                let level = mode == .classic
                    ? (index*37) % DailyChallengeGenerator.classicLevelCount + 1 : nil
                // Numbered from 1, as the generator draws them: a catalogue level of 0 is
                // level -1 of the first pack
                let day = DailyChallenge(dateKey: "2026-10-18", mode: mode,
                                         classicLevel: level, twists: [twist])
                failures += try play(day, label: "\(twist) in \(mode)", seed: UInt64(index + 1))
                played += 1
            }
        }
        XCTAssertGreaterThan(played, DailyTwist.allCases.count)
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    func testTheNextThreeWeeksOfDailiesPlay() throws {
        var failures: [String] = []
        let calendar = DailyDay.utcCalendar
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<21 {
            let date = try XCTUnwrap(calendar.date(byAdding: .day, value: offset, to: today))
            let key = DailyDay.key(for: date)
            let day = DailyChallengeGenerator.challenge(forKey: key)
            failures += try play(day, label: "\(key) (\(day.mode), \(day.twists))",
                                 seed: UInt64(offset + 100))
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    private func play(_ day: DailyChallenge, label: String, seed: UInt64) throws -> [String] {
        try PlayWatch.watch(seconds: 3, seed: seed, label: label,
                            powerUps: day.has(.noPowerUps) == false) {
            DailyChallengeSession.shared.active = day
            let level = day.classicLevel.map(DailyChallengeGenerator.levelNumber(forClassicLevel:))
            let pack = day.classicLevel.map(DailyChallengeGenerator.pack(forClassicLevel:)) ?? 1
            return try PaddleFamilySweep.present(theme: 0, keeping: &self.window, mode: day.mode,
                                                 frozen: false, level: level, pack: pack)
        }
    }
}

/// A ball the engine presses flat against a brick's underside leaves downward, at once.
///
/// James's device log, round 391, on Lonesome Brick: "CROOKED BALL, unexplained: bent 10.85 deg
/// at (137, -31) heading 180.0 deg", and three more like it - a Classic ball turned dead flat in
/// mid-flight with no writer's note. A ball that clips a brick's corner from below can leave still
/// climbing and slide into the underside while it is touching the brick, and the engine takes the
/// slow push across the face away rather than bouncing it. The escape then picked up or down at
/// random, so half the time it went back into the brick and was flattened again.
final class AFlatBallLeavesTheWayItCameTests: XCTestCase {
    private var window: UIWindow?

    func testABallFlattenedUnderABrickLeavesDownward() throws {
        let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window, mode: .classic,
                                                  frozen: false, level: 101, pack: 12)
        let brick = BrickSweep.brick("normal", texture: scene.brickIndestructible2Texture,
                                     in: scene, rowY: -31, column: 5)
        // Indestructible, so it is the same underside every time and breaking it cannot end
        // the level - Lonesome Brick's own brick stays where it is
        var failures: [String] = []
        var flattened = 0
        for speed in [scene.ballSpeedNominal, scene.ballSpeedSlowest] {
            scene.ballSpeedLimit = speed
            for tenths in stride(from: 60, through: 160, by: 5) {
                let angle = Double(tenths)/10*Double.pi/180
                scene.ball.position = CGPoint(x: brick.frame.maxX + 5,
                                              y: brick.frame.minY - scene.ballSize/2 - 3)
                scene.ball.physicsBody?.velocity = CGVector(dx: -CGFloat(cos(angle))*speed,
                                                            dy: CGFloat(sin(angle))*speed)
                var flatFrames = 0, worst = 0
                var last = CGVector.zero
                for _ in 0..<20 {
                    PaddleFamilySweep.settle(1.0/60)
                    last = scene.ball.physicsBody?.velocity ?? .zero
                    if abs(last.dy) < 0.5, abs(last.dx) > 1 {
                        flatFrames += 1
                        worst = max(worst, flatFrames)
                    } else {
                        flatFrames = 0
                    }
                }
                if worst > 0 { flattened += 1 }
                let name = String(format: "in at %.1f deg, %.0f pt/s", Double(tenths)/10, speed)
                if worst > 1 { failures.append("\(name): dead flat for \(worst) frames running") }
                if last.dy > 0 { failures.append("\(name): still climbing into the brick") }
            }
        }
        print("FLATTENED \(flattened) of 42 approaches by the engine")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}

/// What a game is, as far as a player could tell: the facts a save and resume must carry.
///
/// Shared by the power-up sweep, which asks what is running, and `ResumeIsTheSameGameTests`, which
/// asks everything.
enum GameSnapshot {

    /// Every power-up effect running, by name - clocks, the original twenty-eight's timers, and
    /// the effects that are things on the field rather than clocks.
    static func running(in scene: GameScene) -> [String] {
        var running: [String] = []
        for path in GameScene.endlessIIWipeableClockPaths where scene[keyPath: path].isRunning {
            let clock = scene[keyPath: path]
            running.append("\(path)" + (clock.countsTurns ? " \(Int(clock.remaining.rounded())) turns" : ""))
        }
        for timer in scene.endlessIIClassicTimers where scene.action(forKey: timer.key) != nil
            && timer.timers.contains(where: { $0.key.hasPrefix("powerUp") == false
                && $0.node.isHidden == false && $0.node.action(forKey: $0.key) != nil }) {
            running.append(timer.key)
        }
        // One of the original twenty-eight runs while its bar shows, as the rings and the save
        // both read it: a power-up cancelled by its opposite leaves a timer behind that ends
        // nothing, under a hidden bar
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
        return running.sorted()
    }

    /// The scene's textures by the name of the property holding each.
    static func textureNames(in scene: GameScene) -> [ObjectIdentifier: String] {
        var names: [ObjectIdentifier: String] = [:]
        for child in Mirror(reflecting: scene).children {
            guard let texture = child.value as? SKTexture, let label = child.label else { continue }
            let id = ObjectIdentifier(texture)
            if let held = names[id], held < label { continue }
            names[id] = label
        }
        return names
    }

    /// Every brick a player could meet: what it is, how it looks and where it is.
    ///
    /// An empty cell's placeholder is not a brick - hidden, bodiless and on its way out - so it
    /// is left out; one that came back from a save as a real brick is exactly what this is for.
    static func bricks(in scene: GameScene) -> [String] {
        let names = textureNames(in: scene)
        var found: [String] = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode else { return }
            if brick.texture === scene.brickNullTexture, brick.physicsBody == nil { return }
            let styles = scene.endlessIIStyles(on: brick)
            let wanders = brick.endlessIIRole == .moving || brick.endlessIIRole == .gravity
            let breathing = scene.endlessIIBreathers.first { $0.brick === brick }
            let cell = breathing?.full ?? scene.endlessIIFieldSize(of: brick)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            brick.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let tinted = brick.colorBlendFactor > 0.01 && brick.texture === scene.brickNormalTexture
                && (r < 0.99 || g < 0.99 || b < 0.99)
            let tint = tinted ? String(format: " tint %.2f,%.2f,%.2f", r, g, b) : ""
            // White on a white picture is no tint at all, whichever way it is written
            let place = wanders ? "wandering" : String(format: "at %.0f,%.0f",
                scene.endlessIICanonicalRestingX(of: brick),
                scene.endlessIICanonicalRestingY(brick.descentRestingY ?? brick.position.y))
            found.append([
                brick.texture.flatMap { names[ObjectIdentifier($0)] } ?? "no picture",
                brick.isHidden ? "hidden" : "shown",
                breathing != nil ? "breathing body" : brick.physicsBody == nil ? "bodiless" : "solid",
                // A Breathing brick lets its body go below a size on purpose (`solidBelow`), so
                // whether it is solid is a question about the instant, not the brick
                brick.endlessIIRole?.rawValue ?? "",
                styles.map(\.rawValue).sorted().joined(separator: "+"),
                brick.endlessIIPowerUpIndex.map { "holding \($0)" } ?? "",
                brick.endlessIIVulnerableSide.map { "open \($0.rawValue)" } ?? "",
                String(format: "%.0fx%.0f", cell.width, cell.height),
                place].filter { $0.isEmpty == false }.joined(separator: " ") + tint)
        }
        return found.sorted()
    }

    /// Every power-up in the air, by name.
    static func drops(in scene: GameScene) -> [String] {
        let names = LevelPackSetup.shared.powerUpNameArray
        var found: [String] = []
        scene.enumerateChildNodes(withName: PowerUpCategoryName) { node, _ in
            guard let sprite = node as? SKSpriteNode, sprite.zPosition != 1,
                  let texture = sprite.texture else { return }
            let index = scene.powerUpTextureArray.firstIndex { $0 === texture }
            found.append(index.map { names.indices.contains($0) ? names[$0] : "\($0)" } ?? "unknown")
        }
        return found.sorted()
    }

    /// The run's own numbers.
    static func numbers(in scene: GameScene) -> [String] {
        ["mode \(scene.gameMode)", "lives \(scene.numberOfLives)", "height \(scene.endlessHeight)",
         "score \(scene.totalScore + scene.levelScore)",
         String(format: "multiplier %.2f", scene.multiplier),
         "level \(scene.levelNumber)"]
    }
}

/// A game saved at any moment comes back as the same game.
///
/// James, round 398b, after the third save fault in one evening - placeholder bricks after a
/// resume, falling power-ups turned into extra lives, and a Breathing brick that shrank on every
/// pause: "Another silly mistake and a regression... I'm worried about all the things that have
/// been previously checked and play tested that might now be broken. We still need more thorough
/// checking and testing in place."
///
/// Each of those was found by a sweep of one kind of thing, or by James. This asks the whole
/// question at once. A run is played by itself for a while chosen by the seed, with power-ups
/// arriving, then frozen, saved, and resumed in a second scene - and everything a player could
/// tell apart is compared: every brick (what it is, its picture, whether it is shown and solid,
/// its role, styles, power-up, open side, cell size and resting place), every power-up in the air,
/// what is running and which rings show, and the run's lives, height, score and multiplier. Many
/// seeds, all three modes.
final class ResumeIsTheSameGameTests: XCTestCase {
    private var window: UIWindow?
    private var resumedWindow: UIWindow?

    override func tearDown() {
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        SavedGame.clear(from: GameScene.settingsStore)
        window = nil
        resumedWindow = nil
        super.tearDown()
    }

    func testMayhemComesBackTheSame() throws {
        try compare(.endlessII, seeds: 1...10)
    }

    func testClassicAndEndlessComeBackTheSame() throws {
        try compare(.classic, seeds: 1...4)
        try compare(.endless, seeds: 1...4)
    }

    private func compare(_ mode: GameMode, seeds: ClosedRange<UInt64>) throws {
        var failures: [String] = []
        for seed in seeds {
            failures += try ResumeCheck.run(mode: mode, seed: seed, window: &window,
                                            resumedWindow: &resumedWindow)
        }
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}

/// One game played, frozen, saved, resumed and compared - `ResumeIsTheSameGameTests`' question for
/// one seed, shared with the soak (`SoakTests`), which asks it of hundreds.
enum ResumeCheck {

    static func run(mode: GameMode, seed: UInt64, theme: Int = 0, startHeight: Int? = nil,
                    daily: DailyChallenge? = nil, playFor chosen: TimeInterval? = nil,
                    window: inout UIWindow?, resumedWindow: inout UIWindow?) throws -> [String] {
        var failures: [String] = []
        let setup = LevelPackSetup.shared
        defer {
            GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
            DailyChallengeSession.shared.active = nil
        }
        var random = PlayWatch.Seeded(state: seed &* 7919)
        let level: Int?
        let pack: Int
        if let classic = daily?.classicLevel {
            level = DailyChallengeGenerator.levelNumber(forClassicLevel: classic)
            pack = DailyChallengeGenerator.pack(forClassicLevel: classic)
        } else if mode == .classic {
            pack = 2 + Int(seed % UInt64(setup.numberOfLevels.count - 2))
            level = setup.startLevelNumber[pack] + Int((seed / 11) % UInt64(setup.numberOfLevels[pack]))
        } else {
            level = nil
            pack = 1
        }
        DailyChallengeSession.shared.active = daily
        let scene = try PaddleFamilySweep.present(theme: theme, keeping: &window, mode: mode,
                                                  frozen: false, level: level, pack: pack)
        if mode == .endlessII {
            scene.endlessHeight = startHeight ?? Int.random(in: 40...400, using: &random)
        }
        // Deep enough for the field to hold the kinds a deep run meets
        let playFor = chosen ?? Double.random(in: 3...9, using: &random)
        var clock = 0.0, nextPowerUp = 0.7
        while clock < playFor, scene.gameState.currentState is Playing {
            if scene.ballIsOnPaddle, scene.endlessIIHeldBalls.isEmpty { scene.releaseBall() }
            if scene.endlessIIAimHold { _ = scene.endlessIIAimLaunch() }
            if let lowest = scene.endlessIIBallsInPlay.min(by: { $0.position.y < $1.position.y }) {
                let reach = scene.gameWidth/2 - scene.paddle.size.width/2
                scene.paddle.position.x = min(max(lowest.position.x, -reach), reach)
            }
            if clock >= nextPowerUp {
                nextPowerUp += 0.7
                let pool = scene.powerUpTextureArray.indices.filter {
                    $0 != 1 && setup.retiredPowerUpIndices.contains($0) == false
                        && scene.powerUpCanAppear($0)
                        && (mode == .endlessII || scene.powerUpProbArray[$0] > 0)
                }
                if let index = pool.randomElement(using: &random) {
                    let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[index])
                    scene.addChild(carrier)
                    scene.applyPowerUp(node: carrier, silently: true)
                }
                // And one left in the air, as a brick would drop it
                if let index = pool.randomElement(using: &random) {
                    let drop = SKSpriteNode(texture: scene.powerUpTextureArray[index])
                    drop.size = CGSize(width: scene.brickWidth*0.85, height: scene.brickWidth*0.85)
                    drop.name = PowerUpCategoryName
                    drop.zPosition = 2
                    drop.position = CGPoint(x: CGFloat.random(in: -150...150, using: &random),
                                            y: CGFloat.random(in: -100...200, using: &random))
                    scene.addChild(drop)
                }
            }
            PaddleFamilySweep.settle(1.0/30)
            clock += 1.0/30
        }
        guard scene.gameState.currentState is Playing else {
            scene.view?.presentScene(nil)
            return []
        }
        // A run that ended has nothing to save; another seed will play on

        scene.physicsWorld.speed = 0
        PaddleFamilySweep.settle(0.3)
        scene.isPaused = true
        // The same still moment the resumed game is given below, so a field that was about
        // to step down into an empty bottom row does it here rather than there
        let label = "\(mode)\(daily.map { " daily \($0.dateKey) \($0.twists)" } ?? "") theme \(theme) seed \(seed) after \(String(format: "%.1f", clock))s"
        let before = (bricks: GameSnapshot.bricks(in: scene), drops: GameSnapshot.drops(in: scene),
                      running: GameSnapshot.running(in: scene),
                      rings: scene.activePowerUpEntries().map(\.id).sorted(),
                      numbers: GameSnapshot.numbers(in: scene))
        scene.saveCurrentGame()
        let wrote = SavedGame.load(from: GameScene.settingsStore)?.activePowerUps ?? []

        GameScene.settingsStore.set(true, forKey: SavedGame.resumeFlagKey)
        let resumed = try PaddleFamilySweep.present(theme: theme, keeping: &resumedWindow,
                                                    resuming: true, mode: mode, level: level,
                                                    pack: pack, intoPlay: false)
        GameScene.settingsStore.set(false, forKey: SavedGame.resumeFlagKey)
        resumed.physicsWorld.speed = 0
        resumed.gameState.enter(Playing.self)
        PaddleFamilySweep.settle(0.3)
        resumed.isPaused = true
        // Into play for a still moment, as the READY countdown ends: a resumed game waits
        // paused, and some of what it restores - a paddle's size, a timer begun in an
        // animation's completion - only lands once the scene runs. The physics stays
        // stopped, so nothing is struck while it does
        let after = (bricks: GameSnapshot.bricks(in: resumed), drops: GameSnapshot.drops(in: resumed),
                     running: GameSnapshot.running(in: resumed),
                     rings: resumed.activePowerUpEntries().map(\.id).sorted(),
                     numbers: GameSnapshot.numbers(in: resumed))

        func differ(_ what: String, _ a: [String], _ b: [String]) {
            guard a != b else { return }
            var lost = a, gained = b
            for item in a where gained.contains(item) {
                gained.remove(at: gained.firstIndex(of: item)!)
                lost.remove(at: lost.firstIndex(of: item)!)
            }
            failures.append("\(label): \(what) - lost \(lost.prefix(6)), gained \(gained.prefix(6))")
        }
        differ("bricks", before.bricks, after.bricks)
        differ("power-ups in the air", before.drops, after.drops)
        differ("running (of \(before.running), saved as \(wrote))", before.running,
               after.running)
        differ("rings", before.rings, after.rings)
        differ("the run", before.numbers, after.numbers)
        resumed.view?.presentScene(nil)
        scene.view?.presentScene(nil)
        return failures
    }
}

/// Plays a run by itself and watches it: what `LongPlaySessionTests` and the daily sweep share.
///
/// The paddle follows the lowest ball - a player who never misses - a power-up from the run's own
/// pool lands every second and a half in a seeded order, so a failure replays exactly, and held
/// balls are launched as a tap would. Ten times a second it asks what must always be true: every
/// ball inside the field, moving and a number; no brick solid and unseen for more than two
/// seconds; and the scene's node count not running away. A run that ends is started again.
enum PlayWatch {

    struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    static func watch(seconds: TimeInterval, seed: UInt64, label: String,
                      powerUps: Bool = true,
                      present: () throws -> GameScene) throws -> [String] {
        var random = Seeded(state: seed)
        var scene = try present()
        let setup = LevelPackSetup.shared
        var failures: [String] = []
        var restarts = 0
        var nextPowerUp: TimeInterval = 1.5
        var stillFor: [ObjectIdentifier: TimeInterval] = [:]
        var flatFor: [ObjectIdentifier: TimeInterval] = [:]
        var livesNoted = false
        var phantomFor: TimeInterval = 0
        var peakNodes = 0
        let startNodes = nodeCount(scene)
        let step = 1.0/60
        var clock: TimeInterval = 0
        var recent: [(TimeInterval, String)] = []
        func lately() -> [String] {
            recent.filter { $0.0 > clock - 5 }.map { "\($0.1) at \(String(format: "%.1f", $0.0))s" }
        }
        func note(_ what: String) {
            failures.append("\(label) \(String(format: "%.1f", clock))s: \(what)")
        }

        while clock < seconds, failures.count < 12 {
            if scene.gameState.currentState is GameOver
                || scene.gameState.currentState is InbetweenLevels {
                restarts += 1
                scene = try present()
                continue
            }
            if scene.gameState.currentState is Paused { scene.gameState.enter(Playing.self) }
            if scene.ballIsOnPaddle, scene.endlessIIHeldBalls.isEmpty { scene.releaseBall() }
            if scene.endlessIIAimHold { _ = scene.endlessIIAimLaunch() }
            scene.endlessIIReleaseRemainingHeldBalls()

            if let lowest = scene.endlessIIBallsInPlay.min(by: { $0.position.y < $1.position.y }) {
                let reach = scene.gameWidth/2 - scene.paddle.size.width/2
                scene.paddle.position.x = min(max(lowest.position.x, -reach), reach)
            }

            if powerUps, clock >= nextPowerUp {
                nextPowerUp += 1.5
                let pool = scene.powerUpTextureArray.indices.filter {
                    $0 != 1 && setup.retiredPowerUpIndices.contains($0) == false
                        && scene.powerUpCanAppear($0)
                        && (scene.gameMode == .endlessII || scene.powerUpProbArray[$0] > 0)
                }
                // What this run could actually drop. `powerUpCanAppear` answers Mayhem's own
                // conditions, and in Classic it let a Wipe through - a Mayhem power-up, which a
                // Classic level never offers and which does nothing there
                if let index = pool.randomElement(using: &random) {
                    let carrier = SKSpriteNode(texture: scene.powerUpTextureArray[index])
                    scene.addChild(carrier)
                    scene.applyPowerUp(node: carrier)
                    recent.append((clock, setup.powerUpNameArray[index]))
                }
            }

            PaddleFamilySweep.settle(step)
            clock += step
            guard Int((clock/step).rounded()) % 6 == 0 else { continue }

            let edgeX = scene.gameWidth/2 + scene.ballSize*3
            let edgeY = scene.size.height/2 + scene.ballSize*3
            for ball in scene.endlessIIBallsInPlay where ball.parent != nil {
                let p = ball.position
                let v = ball.physicsBody?.velocity ?? .zero
                guard p.x.isFinite, p.y.isFinite, v.dx.isFinite, v.dy.isFinite else {
                    note("a ball at \(p) moving \(v)")
                    continue
                }
                if abs(p.x) > edgeX || p.y > edgeY { note("a ball outside the field at \(p)") }
                let id = ObjectIdentifier(ball)
                let held = (scene.ballIsOnPaddle && ball === scene.ball)
                    || scene.endlessIIHeldBalls.contains { $0 === ball }
                let speed = hypot(v.dx, v.dy)
                let flat = speed > 5 && held == false && scene.gameState.currentState is Playing
                    && abs(v.dy) < CGFloat(sin(scene.minAngleDeg*Double.pi/180))*speed*0.9
                if flat {
                    flatFor[id, default: 0] += step*6
                    if (flatFor[id] ?? 0) > 0.25 {
                        note(String(format: "a ball running flat at (%.0f, %.0f), heading %.1f deg",
                                    p.x, p.y, atan2(v.dy, v.dx)*180/CGFloat.pi))
                        flatFor[id] = -100
                    }
                } else if (flatFor[id] ?? 0) > 0 {
                    flatFor[id] = 0
                }
                // **Never flatter than the minimum for long** (James's device log, round 391: a
                // Classic ball crossed Lonesome Brick heading exactly 180 degrees and then 0).
                // `breakHorizontalRuns` lifts a flat ball off horizontal within a frame, so a
                // quarter of a second flat means something is putting it back
                if held || speed > 5 || scene.gameState.currentState is Playing == false {
                    stillFor[id] = 0
                } else {
                    stillFor[id, default: 0] += step*6
                    if (stillFor[id] ?? 0) > 2 {
                        note("a ball stopped dead at \(p)")
                        stillFor[id] = -100
                    }
                }
            }
            if scene.phantomBrickPositions().isEmpty {
                phantomFor = 0
            } else {
                phantomFor += step*6
                if phantomFor > 2 {
                    note("bricks solid and unseen for two seconds: \(scene.phantomBrickReasons()); "
                         + "power-ups in the last five seconds: \(lately())")
                    phantomFor = -100
                }
            }
            if scene.gameMode == .endlessII, scene.numberOfLives > 0, livesNoted == false,
               DailyChallengeSession.shared.active?.has(.spareBalls) != true {
                note("Endless Mayhem holding \(scene.numberOfLives) spare lives")
                livesNoted = true
            }
            // **Mayhem has one life** (James, round 398b: "I then had 2 lives in Endless Mayhem
            // mode which shouldn't be possible"). Only a Spare Balls day gives it a rack
            peakNodes = max(peakNodes, nodeCount(scene))
        }
        let endNodes = nodeCount(scene)
        if endNodes > startNodes*3 + 400 {
            failures.append("\(label): the scene grew from \(startNodes) nodes to \(endNodes) "
                            + "(peak \(peakNodes)) - something is left behind")
        }
        if failures.isEmpty == false { failures.insert("\(label): \(restarts) restarts", at: 0) }
        return failures
    }

    static func nodeCount(_ node: SKNode) -> Int {
        node.children.reduce(node.children.count) { $0 + nodeCount($1) }
    }
}

/// Bricks built the way the generator builds them, for the sweeps that need every kind.
enum BrickSweep {

    static func brick(_ size: String, texture: SKTexture, in scene: GameScene,
                      rowY: CGFloat, column: Int) -> SKSpriteNode {
        let made: SKSpriteNode
        switch size {
        case "square": made = scene.endlessIIMakeSquare(column: column, rowY: rowY)
        case "big": made = scene.endlessIIMakeBig(leftColumn: max(0, column - 1), rowY: rowY)
        default:
            made = SKSpriteNode(texture: texture)
            made.size = CGSize(width: scene.brickWidth, height: scene.brickHeight)
            made.position = CGPoint(x: -scene.gameWidth/2 + scene.brickWidth*(CGFloat(column) + 0.5), y: rowY)
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
}
