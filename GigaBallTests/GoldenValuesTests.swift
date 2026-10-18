//
//  GoldenValuesTests.swift
//  GigaBallTests
//
//  Classic and the original Endless, written down as they play.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

/// Nothing about Classic or the original Endless changes without somebody meaning it to.
///
/// CLAUDE.md's second constraint that never bends: existing leaderboards stay valid, and people
/// hold years of scores on them. Round 397 shared a lot of code between Mayhem and the old modes -
/// the paddle, the bounce, the power-ups, the save - and a change meant for Mayhem that reached
/// Classic would play differently without failing anything, because no test knew what Classic
/// was supposed to be. This is what it is: the speeds, sizes, angles and power-up odds each mode
/// starts with, the ball's and paddle's physics, the paddle's bounce across its width, and every
/// Classic level's bricks, all read off a running scene and compared with
/// `ClassicEndlessGolden.json` beside this file.
///
/// Lengths and speeds are written as fractions of the play zone's width, which is the same shape
/// on every device, so the record is the same wherever the suite runs.
///
/// **When a change to these modes is meant**, write the record again and commit it with the
/// change, so the difference is there to read in the diff:
///
///     TEST_RUNNER_GOLDEN_WRITE=1 tools/test.sh only GoldenValuesTests
final class GoldenValuesTests: XCTestCase {
    private var window: UIWindow?

    private var recordURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("ClassicEndlessGolden.json")
    }

    func testClassicAndEndlessPlayAsTheyAlwaysHave() throws {
        let now = try measure()
        if ProcessInfo.processInfo.environment["GOLDEN_WRITE"] == "1" {
            let data = try JSONSerialization.data(withJSONObject: now,
                                                  options: [.prettyPrinted, .sortedKeys])
            try data.write(to: recordURL)
            print("GOLDEN written to \(recordURL.path)")
            return
        }
        let data = try Data(contentsOf: recordURL)
        let record = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
        var differences: [String] = []
        for key in Set(record.keys).union(now.keys).sorted() where record[key] != now[key] {
            differences.append("\(key): was \(record[key] ?? "absent"), now \(now[key] ?? "absent")")
        }
        XCTAssertTrue(differences.isEmpty, "Classic or Endless no longer plays as it did. If that "
                      + "is meant, write the record again (see this test's comment):\n"
                      + differences.joined(separator: "\n"))
    }

    /// Everything the record holds, as text: a number is written to six figures, so the
    /// arithmetic of a different processor cannot move it.
    private func measure() throws -> [String: String] {
        var values: [String: String] = [:]
        func put(_ key: String, _ number: Double) {
            values[key] = String(format: "%.6g", number)
        }
        let setup = LevelPackSetup.shared

        let veteran = TotalStats()
        veteran.powerUpUnlockedArray = veteran.powerUpUnlockedArray.map { _ in true }
        // The odds a level starts with are allocated from the player's unlocks, so they are
        // written for a new player and for one who has everything - the second is the whole table
        for mode in [GameMode.classic, .endless] {
            let level = mode == .classic ? setup.startLevelNumber[2] : nil
            let unlocked = try PaddleFamilySweep.present(theme: 0, keeping: &window, mode: mode,
                                                         level: level,
                                                         pack: mode == .classic ? 2 : 1,
                                                         stats: veteran)
            values["\(mode).everythingUnlocked.powerUpProbArray"] = unlocked.powerUpProbArray
                .map(String.init).joined(separator: ",")
            unlocked.view?.presentScene(nil)

            let scene = try PaddleFamilySweep.present(theme: 0, keeping: &window, mode: mode,
                                                      level: level, pack: mode == .classic ? 2 : 1)
            let unit = Double(scene.gameWidth)
            let name = "\(mode)"
            for (key, length) in [
                ("ballSize", scene.ballSize), ("ballSizeBig", scene.ballSizeBig),
                ("ballSizeBiggest", scene.ballSizeBiggest), ("ballSizeSmall", scene.ballSizeSmall),
                ("ballSizeSmallest", scene.ballSizeSmallest), ("paddleWidth", scene.paddleWidth),
                ("paddleHeight", scene.paddleHeight), ("brickWidth", scene.brickWidth),
                ("brickHeight", scene.brickHeight), ("ballSpeedSlowest", scene.ballSpeedSlowest),
                ("ballSpeedSlow", scene.ballSpeedSlow), ("ballSpeedNominal", scene.ballSpeedNominal),
                ("ballSpeedFast", scene.ballSpeedFast), ("ballSpeedFastest", scene.ballSpeedFastest),
                ("ballSpeedLimit", scene.ballSpeedLimit)] {
                put("\(name).\(key)", Double(length)/unit)
            }
            put("\(name).minAngleDeg", scene.minAngleDeg)
            put("\(name).angleAdjustmentK", scene.angleAdjustmentK)
            put("\(name).powerUpLimit", Double(scene.powerUpLimit))
            put("\(name).powerUpProbFactor", Double(scene.powerUpProbFactor))
            values["\(name).powerUpProbArray"] = scene.powerUpProbArray.map(String.init)
                .joined(separator: ",")
            put("\(name).numberOfLives", Double(scene.numberOfLives))
            put("\(name).gravity.dy", Double(scene.physicsWorld.gravity.dy))
            for (part, body) in [("ball", scene.ball.physicsBody),
                                 ("paddle", scene.paddle.physicsBody)] {
                let body = try XCTUnwrap(body, "\(name): the \(part) has no body")
                put("\(name).\(part).restitution", Double(body.restitution))
                put("\(name).\(part).friction", Double(body.friction))
                put("\(name).\(part).linearDamping", Double(body.linearDamping))
                put("\(name).\(part).angularDamping", Double(body.angularDamping))
                put("\(name).\(part).isDynamic", body.isDynamic ? 1 : 0)
                put("\(name).\(part).affectedByGravity", body.affectedByGravity ? 1 : 0)
                put("\(name).\(part).allowsRotation", body.allowsRotation ? 1 : 0)
                put("\(name).\(part).categoryBitMask", Double(body.categoryBitMask))
                put("\(name).\(part).collisionBitMask", Double(body.collisionBitMask))
                put("\(name).\(part).contactTestBitMask", Double(body.contactTestBitMask))
            }

            // The bounce off the paddle, everywhere along it and for every way in
            for arriving in stride(from: 20.0, through: 160.0, by: 20.0) {
                let radians = arriving*Double.pi/180
                let incoming = CGVector(dx: cos(radians), dy: -sin(radians))
                for step in -6...6 {
                    let collision = Double(step)/5
                    let out = PaddleBounce.angleDegrees(arriving: incoming, collision: collision,
                                                        adjustmentK: scene.angleAdjustmentK,
                                                        influence: 1,
                                                        minimumDeg: scene.minAngleDeg)
                    put("\(name).bounce.\(Int(arriving)).\(step)", out)
                }
            }

            if mode == .classic {
                let textures = textureNames(in: scene)
                for pack in 2..<setup.numberOfLevels.count {
                    let first = setup.startLevelNumber[pack]
                    for number in first..<(first + setup.numberOfLevels[pack]) {
                        values[String(format: "classic.level.%03d", number)]
                            = fingerprint(of: number, in: scene, textures: textures)
                    }
                }
            }
            scene.view?.presentScene(nil)
        }
        return values
    }

    /// A Classic level's bricks - where, what and what colour - as a count and a hash.
    private func fingerprint(of level: Int, in scene: GameScene,
                             textures: [ObjectIdentifier: String]) -> String {
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in node.removeFromParent() }
        scene.bricksLeft = 0
        scene.levelNumber = level
        scene.loadLevel(level)
        var cells: [String] = []
        scene.enumerateChildNodes(withName: BrickCategoryName) { node, _ in
            guard let brick = node as? SKSpriteNode,
                  brick.texture != scene.brickNullTexture else { return }
            let column = Int(((brick.position.x + scene.gameWidth/2)/scene.brickWidth - 0.5)
                .rounded())
            let row = Int(((scene.yBrickOffset - brick.position.y)/scene.brickHeight).rounded())
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            brick.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let texture = brick.texture.flatMap { textures[ObjectIdentifier($0)] } ?? "?"
            cells.append(String(format: "%d,%d,%@,%.3f,%.3f,%.3f,%.2f,%d", row, column,
                                texture as NSString, r, g, b, brick.colorBlendFactor,
                                brick.isHidden ? 1 : 0))
        }
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in cells.sorted().joined(separator: ";").utf8 {
            hash = (hash ^ UInt64(byte)) &* 0x100000001b3
        }
        return "\(cells.count) bricks, \(String(hash, radix: 16))"
    }

    /// The scene's textures by the name of the property holding each, so a level's record says
    /// "brickMultiHit2Texture" rather than an address that changes every launch.
    private func textureNames(in scene: GameScene) -> [ObjectIdentifier: String] {
        var names: [ObjectIdentifier: String] = [:]
        for child in Mirror(reflecting: scene).children {
            guard let texture = child.value as? SKTexture, let label = child.label else { continue }
            let id = ObjectIdentifier(texture)
            if let held = names[id], held < label { continue }
            names[id] = label
        }
        return names
    }
}
