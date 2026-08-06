//
//  EndlessIINeighbourTests.swift
//  GigaBallTests
//
//  Four bricks in Endless 2.0 are defined entirely by what is next to them, and all four read
//  a grid of whole cells. That is exactly right until a brick is a quarter of a cell, at which
//  point most of a Tiny brick's neighbours are inside its own cell and the grid cannot see any
//  of them.
//
//  Every test here is a play-test report. An Exploding Tiny brick that took nothing with it. A
//  Moving Tiny brick that slid through the bricks beside it going left and was stopped by the
//  same ones coming back. A Spawner that filled the space a Spinning brick needed to turn. A
//  ball that came out of a Portal beside the wall and left the game.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIINeighbourTests: XCTestCase {

    private let cell = CGSize(width: 40, height: 20)

    /// A scene with the field geometry filled in, which is all any of this reads.
    private func makeScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 500, height: 900))
        scene.gameWidth = 440
        scene.brickWidth = cell.width
        scene.brickHeight = cell.height
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffsetEndless = 300
        scene.finalBrickRowHeight = 300 - cell.height*21
        scene.ballSize = 12
        scene.screenBlockTopHeight = 100
        return scene
    }

    private func addBrick(_ scene: GameScene, at point: CGPoint, size: CGSize) -> SKSpriteNode {
        let brick = SKSpriteNode(color: .white, size: size)
        brick.position = point
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    // MARK: - Explosions

    func testAnOrdinaryExplosionStillReachesExactlyItsEightNeighbours() {
        // The rule §4.9 asks for, and the thing the geometric reach must not change.
        let scene = makeScene()
        let centre = addBrick(scene, at: .zero, size: cell)
        let reach = scene.endlessIIBlastReach(of: centre)

        for row in -1...1 {
            for column in -1...1 {
                let neighbour = CGPoint(x: cell.width*CGFloat(column),
                                        y: cell.height*CGFloat(row))
                let frame = CGRect(x: neighbour.x - cell.width/2, y: neighbour.y - cell.height/2,
                                   width: cell.width, height: cell.height)
                XCTAssertTrue(reach.intersects(frame), "\(column),\(row)")
            }
        }
    }

    func testAnExplosionDoesNotReachTwoCellsAway() {
        let scene = makeScene()
        let centre = addBrick(scene, at: .zero, size: cell)
        let reach = scene.endlessIIBlastReach(of: centre)

        let far = CGRect(x: cell.width*2 - cell.width/2, y: -cell.height/2,
                         width: cell.width, height: cell.height)
        XCTAssertFalse(reach.intersects(far))
    }

    func testAnExplodingTinyBrickTakesTheTinyBricksBesideIt() {
        // The report: an Exploding Tiny brick was hit and its neighbours - three of which
        // share its own cell - were untouched. A blast worked out from the eight cells around
        // it never looked inside the one it was in.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)
        let step = CGPoint(x: cell.width/4, y: cell.height/4)

        let bottomLeft = addBrick(scene, at: CGPoint(x: -step.x, y: -step.y), size: quarter)
        let bottomRight = addBrick(scene, at: CGPoint(x: step.x, y: -step.y), size: quarter)
        let topLeft = addBrick(scene, at: CGPoint(x: -step.x, y: step.y), size: quarter)

        let reach = scene.endlessIIBlastReach(of: bottomLeft)
        XCTAssertTrue(reach.intersects(bottomRight.frame), "the quarter beside it")
        XCTAssertTrue(reach.intersects(topLeft.frame), "the quarter above it")
    }

    func testATinyExplosionStaysSmall() {
        // It reaches what is touching it, not a whole cell in every direction - or a quarter
        // of a brick would clear more field than a full one.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)
        let tiny = addBrick(scene, at: CGPoint(x: -cell.width/4, y: -cell.height/4),
                            size: quarter)

        let reach = scene.endlessIIBlastReach(of: tiny)
        let twoCellsRight = CGRect(x: cell.width*1.5, y: -cell.height/2,
                                   width: cell.width, height: cell.height)
        XCTAssertFalse(reach.intersects(twoCellsRight))
    }

    // MARK: - Moving

    func testAMovingTinyBrickIsStoppedByTheQuarterBesideIt() {
        // The report: a Moving Tiny brick passed through other Tiny bricks arriving from the
        // left and was blocked by the same ones from the right. The cell either side held
        // whichever of its four bricks was enumerated last, so the answer depended on
        // enumeration order rather than on the field.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)
        let y = -cell.height/4

        let mover = addBrick(scene, at: CGPoint(x: -cell.width/4, y: y), size: quarter)
        let blocker = addBrick(scene, at: CGPoint(x: cell.width/4, y: y), size: quarter)

        let limits = scene.endlessIIWanderLimits(for: mover)
        XCTAssertEqual(limits.right, blocker.frame.minX - quarter.width/2, accuracy: 0.001)
        XCTAssertLessThan(limits.right, blocker.frame.minX)
    }

    func testAMovingTinyBrickIsStoppedTheSameFromEitherSide() {
        // The asymmetry is the bug. Whichever way it is travelling, the same brick stops it
        // at the same place.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)
        let y = -cell.height/4

        let left = addBrick(scene, at: CGPoint(x: -cell.width*0.75, y: y), size: quarter)
        let mover = addBrick(scene, at: CGPoint(x: -cell.width/4, y: y), size: quarter)
        let right = addBrick(scene, at: CGPoint(x: cell.width/4, y: y), size: quarter)

        let limits = scene.endlessIIWanderLimits(for: mover)
        XCTAssertEqual(mover.position.x - limits.left,
                       limits.right - mover.position.x, accuracy: 0.001)
        XCTAssertGreaterThan(limits.left, left.frame.maxX - 0.001)
        XCTAssertLessThan(limits.right, right.frame.minX + 0.001)
    }

    func testAMovingBrickIgnoresWhatIsAboveAndBelowIt() {
        // A Tiny brick on the bottom of a cell is stopped by the one beside it, not by the
        // one diagonally above - which it would slide harmlessly under.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)

        let mover = addBrick(scene, at: CGPoint(x: -cell.width/4, y: -cell.height/4),
                             size: quarter)
        _ = addBrick(scene, at: CGPoint(x: cell.width/4, y: cell.height/4), size: quarter)

        let limits = scene.endlessIIWanderLimits(for: mover)
        XCTAssertEqual(limits.right, scene.gameWidth/2 - quarter.width/2, accuracy: 0.001)
    }

    func testAMovingBrickStopsAtTheWalls() {
        let scene = makeScene()
        let mover = addBrick(scene, at: .zero, size: cell)
        let limits = scene.endlessIIWanderLimits(for: mover)

        XCTAssertEqual(limits.left, -scene.gameWidth/2 + cell.width/2, accuracy: 0.001)
        XCTAssertEqual(limits.right, scene.gameWidth/2 - cell.width/2, accuracy: 0.001)
    }

    // MARK: - Occupancy

    func testACellReportsEveryBrickInIt() {
        // One brick per cell was the whole trouble: three quarters of a Tiny set did not
        // exist as far as anything asking the grid was concerned.
        let scene = makeScene()
        let quarter = CGSize(width: cell.width/2 - 1, height: cell.height/2 - 1)
        for x in [-cell.width/4, cell.width/4] {
            for y in [-cell.height/4, cell.height/4] {
                _ = addBrick(scene, at: CGPoint(x: x, y: y), size: quarter)
            }
        }

        let occupied = scene.endlessIIOccupancy()
        let cell = scene.endlessIIGeometry.cell(at: .zero)
        XCTAssertEqual(occupied[cell]?.count, 4)
    }

    func testABigBrickIsListedInAllFourOfItsCellsButOnlyOnceInTheField() {
        let scene = makeScene()
        let big = SKSpriteNode(color: .white,
                               size: CGSize(width: cell.width*2, height: cell.height*2))
        big.anchorPoint = CGPoint(x: 0.25, y: 0.75)
        big.position = CGPoint(x: -scene.gameWidth/2 + cell.width/2, y: 300)
        big.name = BrickCategoryName
        scene.addChild(big)

        let occupied = scene.endlessIIOccupancy()
        let listings = occupied.values.reduce(0) { $0 + $1.count }
        XCTAssertEqual(listings, 4)
        XCTAssertEqual(scene.endlessIIBricks().count, 1)
    }

    // MARK: - Portals

    func testABallLeavingAPortalStaysInPlay() {
        // The report: the far Portal sat against a side wall, the ball was pushed clear along
        // its heading, and the heading pointed through the wall. The run ended on a jump the
        // player had set up correctly.
        let scene = makeScene()
        let playable = scene.endlessIIPlayableRect

        for column in [0, 5, 10] {
            let x = -scene.gameWidth/2 + cell.width/2 + cell.width*CGFloat(column)
            let portal = addBrick(scene, at: CGPoint(x: x, y: 200), size: cell)

            for heading in [CGVector(dx: 300, dy: 0), CGVector(dx: -300, dy: 0),
                            CGVector(dx: 300, dy: 200), CGVector(dx: -300, dy: -200),
                            CGVector(dx: 0, dy: 300), CGVector(dx: 0, dy: -300)] {
                let exit = scene.endlessIIPortalExit(from: portal, heading: heading).point
                XCTAssertTrue(playable.contains(exit),
                              "column \(column), heading \(heading): \(exit)")
            }
            portal.removeFromParent()
        }
    }

    func testABallLeavingAPortalWithRoomKeepsItsHeading() {
        // The fallbacks are for the edges. In the middle of the field it still comes out the
        // way it went in, which is what makes a pair a doorway rather than a lottery.
        let scene = makeScene()
        let portal = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)

        let exit = scene.endlessIIPortalExit(from: portal, heading: CGVector(dx: 300, dy: 0))
        XCTAssertGreaterThan(exit.point.x, portal.position.x)
        XCTAssertEqual(exit.point.y, portal.position.y, accuracy: 0.001)
        XCTAssertEqual(exit.heading.dx, 300, accuracy: 0.001, "it carries on the way it went in")
        XCTAssertEqual(exit.heading.dy, 0, accuracy: 0.001)
    }

    func testABallLeavingAPortalIsClearOfTheBrick() {
        let scene = makeScene()
        let portal = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)

        for heading in [CGVector(dx: 300, dy: 0), CGVector(dx: 0, dy: -300),
                        CGVector(dx: -200, dy: 200)] {
            let exit = scene.endlessIIPortalExit(from: portal, heading: heading).point
            XCTAssertFalse(portal.frame.insetBy(dx: -scene.ballSize/2,
                                                dy: -scene.ballSize/2).contains(exit),
                           "\(heading)")
        }
    }

    func testABallBouncesOutOfAPortalOnlyWhenCarryingOnWouldLoseIt() {
        // A pair is a doorway: what goes in one end comes out of the other going the same way,
        // and the player can aim through it. The exception is a far end against a wall, where
        // carrying on would put the ball outside the field - there it turns round instead,
        // which is a thing that can be read where vanishing is not
        let scene = makeScene()
        let middle = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        let heading = CGVector(dx: 300, dy: 120)

        let clear = scene.endlessIIPortalExit(from: middle, heading: heading)
        XCTAssertEqual(clear.heading.dx, heading.dx, accuracy: 0.001)
        XCTAssertEqual(clear.heading.dy, heading.dy, accuracy: 0.001)
        middle.removeFromParent()

        let atTheWall = addBrick(scene, at: CGPoint(x: scene.gameWidth/2 - cell.width/2, y: 200),
                                 size: cell)
        let bounced = scene.endlessIIPortalExit(from: atTheWall, heading: heading)
        XCTAssertLessThan(bounced.heading.dx, 0, "turned back into the field")
        XCTAssertTrue(scene.endlessIIPlayableRect.contains(bounced.point))
        XCTAssertEqual(hypot(bounced.heading.dx, bounced.heading.dy),
                       hypot(heading.dx, heading.dy), accuracy: 0.5,
                       "a bounce is a change of direction, not of speed")
    }

    // MARK: - Directional bricks and the walls

    func testASoftSideNeverFacesAWall() {
        // A wall is not something the ball can get behind, so a brick in the outermost column
        // with its soft side facing outward can never be destroyed - which is not a hard brick,
        // it is a broken one
        let scene = makeScene()
        let leftEdge = addBrick(scene, at: CGPoint(x: -scene.gameWidth/2 + cell.width/2, y: 200),
                                size: cell)
        XCTAssertFalse(scene.endlessIISideIsReachable(.left, from: leftEdge))
        XCTAssertTrue(scene.endlessIISideIsReachable(.right, from: leftEdge))
        XCTAssertTrue(scene.endlessIISideIsReachable(.top, from: leftEdge))

        let rightEdge = addBrick(scene, at: CGPoint(x: scene.gameWidth/2 - cell.width/2, y: 200),
                                 size: cell)
        XCTAssertFalse(scene.endlessIISideIsReachable(.right, from: rightEdge))
        XCTAssertTrue(scene.endlessIISideIsReachable(.left, from: rightEdge))
    }

    func testABrickInTheMiddleCanFaceEitherWay() {
        let scene = makeScene()
        let middle = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        XCTAssertTrue(scene.endlessIISideIsReachable(.left, from: middle))
        XCTAssertTrue(scene.endlessIISideIsReachable(.right, from: middle))
    }

    // MARK: - Density

    func testEmptyRowsAreNotAllowedToRunOn() {
        // Height is gained by clearing the bottom row, and an empty row is cleared the moment
        // it arrives - so a run of them is height for free, and the player is deep before the
        // mode has shown them anything
        XCTAssertEqual(EndlessIIProgression.mostEmptyRowsInARow, 2)

        let scene = makeScene()
        scene.gameMode = .endlessII

        let empty = { () -> [SKNode] in
            (0..<11).map { column -> SKSpriteNode in
                let brick = SKSpriteNode(texture: scene.brickNullTexture)
                brick.position = CGPoint(x: -scene.gameWidth/2 + self.cell.width/2
                                            + self.cell.width*CGFloat(column),
                                         y: scene.yBrickOffsetEndless)
                brick.name = BrickCategoryName
                return brick
            }
        }

        for pass in 1...EndlessIIProgression.mostEmptyRowsInARow {
            let row = empty()
            scene.endlessIIFillEmptyRowIfOverdue(row)
            let filled = row.compactMap { $0 as? SKSpriteNode }
                .filter { $0.texture != scene.brickNullTexture }
            XCTAssertTrue(filled.isEmpty, "row \(pass) is allowed to be empty")
        }

        let third = empty()
        scene.endlessIIFillEmptyRowIfOverdue(third)
        let filled = third.compactMap { $0 as? SKSpriteNode }
            .filter { $0.texture != scene.brickNullTexture }
        XCTAssertEqual(filled.count, 1, "the third empty row gets one brick, and only one")
    }

    func testARowWithSomethingInItResetsTheRun() {
        let scene = makeScene()
        scene.gameMode = .endlessII

        let occupied = [SKSpriteNode(texture: scene.brickNormalTexture)]
        occupied[0].name = BrickCategoryName
        scene.endlessIIEmptyRowRun = 2
        scene.endlessIIFillEmptyRowIfOverdue(occupied)
        XCTAssertEqual(scene.endlessIIEmptyRowRun, 0)
    }

    // MARK: - Markers

    func testAMarkerIsMadeAFieldsDepthBeforeTheHeightItNames() {
        // It marks where a height *was*, and where a height is is the bottom of the field. A
        // line created at the height it names appears at the top of the screen at the moment
        // the player is told they have reached it.
        //
        // A full field's depth, not one less. Counted from the height after the row carrying
        // it was generated, one less put the 100m line at the bottom row at 101m - so it was
        // still on screen after the player had passed it.
        XCTAssertEqual(GameScene.endlessIIMarkerLead, GameSceneLayout.brickRows)
    }

    func testAMarkerIsClearedOnceItIsBelowTheField() {
        let scene = makeScene()
        XCTAssertEqual(scene.endlessIIMarkerFloor,
                       scene.finalBrickRowHeight - scene.brickHeight/2, accuracy: 0.001)
        XCTAssertGreaterThan(scene.endlessIIMarkerFloor, -scene.frame.height/2,
                             "it used to run on to the bottom of the screen")
    }
}
