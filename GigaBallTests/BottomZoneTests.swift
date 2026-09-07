//
//  BottomZoneTests.swift
//  GigaBallTests
//
//  James, round 313: "A square brick was over the low brick line by one brick height. It
//  should stop at the bottom of the brick."
//
//  `brickHasReachedTheBottomZone` decides where a descending brick stops, and it asked
//  `sprite.frame`. A styled brick's sprite is not its cell: `makeFace` and `makeRounded` both
//  shrink it and tuck it behind the picture they draw, so its frame is smaller than the room
//  it occupies and its bottom edge reads higher than it is. That is the same trap round 270
//  closed for `endlessIIFieldSize`, met again a function along.
//
//  It shows on a Square brick because a Square brick is two rows tall - so the shrink is worth
//  most of a row, which is exactly how far past the line James saw one go - and because its
//  node sits on the *upper* row's centre, half a cell above the middle of its own cell.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class BottomZoneTests: XCTestCase {

    private let cell = CGSize(width: 40, height: 20)

    private func fieldScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 500, height: 900))
        scene.gameMode = .endlessII
        scene.gameWidth = 440
        scene.brickWidth = cell.width
        scene.brickHeight = cell.height
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffsetEndless = 300
        scene.finalBrickRowHeight = 300 - cell.height*21
        scene.ballSize = 12
        return scene
    }

    /// The line the field may not draw past, which is where the marker is drawn.
    private func line(_ scene: GameScene) -> CGFloat {
        scene.finalBrickRowHeight - scene.brickHeight/2
    }

    /// Walks a brick down a row at a time and returns where it was told to stop.
    private func restingBottom(_ scene: GameScene, _ brick: SKSpriteNode) -> CGFloat {
        for _ in 0..<40 {
            if scene.brickHasReachedTheBottomZone(brick) { break }
            brick.position.y -= scene.brickHeight
        }
        return scene.endlessIIFieldRect(of: brick).minY
    }

    // MARK: - The report

    func testAPlainSquareBrickStopsWithItsBottomOnTheLine() {
        let scene = fieldScene()
        let brick = scene.endlessIIMakeSquare(column: 0, rowY: scene.yBrickOffsetEndless)
        brick.texture = scene.brickNormalTexture
        brick.isHidden = false

        XCTAssertEqual(restingBottom(scene, brick), line(scene), accuracy: 1,
                       "a Square brick is two rows tall and its bottom is what has to stop")
    }

    /// The one he saw: a Square brick wearing a style, whose sprite has been shrunk behind it.
    func testAStyledSquareBrickStopsInTheSamePlace() {
        for wearing in ["rounded", "art"] {
            let scene = fieldScene()
            let brick = scene.endlessIIMakeSquare(column: 0, rowY: scene.yBrickOffsetEndless)
            brick.texture = scene.brickNormalTexture
            brick.isHidden = false
            if wearing == "rounded" { scene.makeRounded(brick) }
            scene.refreshEndlessIIBrickArt(brick)

            XCTAssertLessThan(brick.size.height, cell.height*2 + 0.5,
                              "\(wearing): the sprite really is smaller than its cell")

            XCTAssertEqual(restingBottom(scene, brick), line(scene), accuracy: 1,
                           "\(wearing): it went a brick height past the line, because the "
                           + "check was reading the shrunken sprite rather than the cell")
        }
    }

    // MARK: - What must not change

    func testAnOrdinaryBrickStillStopsOnTheFinalRow() {
        let scene = fieldScene()
        let brick = SKSpriteNode(color: .white, size: cell)
        brick.name = BrickCategoryName
        brick.position = CGPoint(x: 0, y: scene.yBrickOffsetEndless)
        scene.addChild(brick)

        XCTAssertEqual(restingBottom(scene, brick), line(scene), accuracy: 1)
    }

    /// The Big brick this check was written for in play-test round 10, whose sprite genuinely
    /// hangs off its node - the case `brick.frame` was right about, and still is.
    func testABigBrickStillStopsOneRowAboveTheLine() {
        let scene = fieldScene()
        let brick = scene.endlessIIMakeBig(leftColumn: 0, rowY: scene.yBrickOffsetEndless)

        XCTAssertEqual(restingBottom(scene, brick), line(scene), accuracy: 1,
                       "its lower half must not sit below the kill line")
    }
}
