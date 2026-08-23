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

    func testAnOrdinaryExplosionReachesItsNeighboursAndTheRowBeyond() {
        // §4.9 asked for the eight neighbours; play-testing raised the vertical reach to two
        // rows each way. The eight are still the floor - and two rows is the new ceiling.
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
        XCTAssertFalse(reach.intersects(far), "two columns away is out of reach")

        let secondRow = CGRect(x: -cell.width/2, y: cell.height*2 - cell.height/2,
                               width: cell.width, height: cell.height)
        let thirdRow = CGRect(x: -cell.width/2, y: cell.height*3 - cell.height/2,
                              width: cell.width, height: cell.height)
        XCTAssertTrue(reach.intersects(secondRow), "two rows up is the new reach")
        XCTAssertFalse(reach.intersects(thirdRow), "three is not")
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

    /// A brick with Indestructibles above and below faces sideways rather than into one.
    func testASandwichedBrickReachesPastItsDepthSidesForAnOpenOne() {
        // "Directional bricks shouldn't have their open face next to an indestructible brick"
        // (James, round 233). Top and bottom are the only faces a shallow run offers, and the
        // old code kept that pool whenever none of it was reachable - so a brick with an
        // Indestructible above it and another below it was given one of those two anyway and
        // could never be destroyed, with both side faces standing open
        let scene = makeScene()
        let middle = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        wall(scene, at: CGPoint(x: 0, y: 200 + cell.height))
        wall(scene, at: CGPoint(x: 0, y: 200 - cell.height))

        XCTAssertEqual(Set(scene.endlessIIOpenSides(from: middle)), Set([.left, .right]))

        scene.gameMode = .endlessII
        scene.endlessHeight = 1
        // Shallow, so the depth pool is top and bottom only - the case that used to break
        for _ in 0..<20 {
            let brick = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
            scene.makeDirectional(brick)
            XCTAssertTrue([.left, .right].contains(brick.endlessIIVulnerableSide),
                          "the soft face was pressed against an Indestructible brick")
            brick.removeFromParent()
        }
    }

    /// And one walled in on all four sides is not offered the role at all.
    func testAPennedInBrickIsNotMadeDirectional() {
        // "Directional bricks shouldn't ... be penned in by them." A brick with no reachable
        // face is not a hard brick, it is a second Indestructible one wearing a bright bar
        // that promises otherwise
        let scene = makeScene()
        scene.gameMode = .endlessII
        let middle = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        for offset in [CGPoint(x: 0, y: cell.height), CGPoint(x: 0, y: -cell.height),
                       CGPoint(x: cell.width, y: 0), CGPoint(x: -cell.width, y: 0)] {
            wall(scene, at: CGPoint(x: offset.x, y: 200 + offset.y))
        }

        XCTAssertTrue(scene.endlessIIOpenSides(from: middle).isEmpty)
        XCTAssertFalse(scene.endlessIICanTake(.directional, middle),
                       "a brick with nowhere to be hit from was still given a soft face")
    }

    /// A face blocked by a row that arrived later is turned to one that is not.
    func testANewRowTurnsADirectionalBrickThatItBlocked() {
        // The check at birth cannot answer this one: the field descends and rows are generated
        // above it, so a brick is offered its top face over an empty cell and an Indestructible
        // brick is lowered into that cell afterwards. Enforced again where the block happens
        let scene = makeScene()
        scene.gameMode = .endlessII
        let brick = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        brick.endlessIIRole = .directional
        brick.endlessIIVulnerableSide = .top
        scene.endlessIIDrawVulnerableEdge(on: brick, side: .top)

        wall(scene, at: CGPoint(x: 0, y: 200 + cell.height))
        scene.endlessIIRepointBlockedDirectionals()

        XCTAssertNotEqual(brick.endlessIIVulnerableSide, .top,
                          "the brick kept a face nothing can reach any more")
        XCTAssertTrue(scene.endlessIISideIsReachable(brick.endlessIIVulnerableSide ?? .top,
                                                     from: brick))
        XCTAssertNotNil(brick.childNode(withName: GameScene.directionalEdgeName),
                        "the bar has to move with the face, or the brick lies about itself")
    }

    /// A face that is still open is left exactly where it was.
    func testTheSweepLeavesAReadableBrickAlone() {
        // Re-pointing a brick the player has been aiming at is a real cost, so it happens only
        // to bricks that have become impossible - never as a tidy-up
        let scene = makeScene()
        scene.gameMode = .endlessII
        let brick = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        brick.endlessIIRole = .directional
        brick.endlessIIVulnerableSide = .top
        wall(scene, at: CGPoint(x: 0, y: 200 - cell.height))

        scene.endlessIIRepointBlockedDirectionals()
        XCTAssertEqual(brick.endlessIIVulnerableSide, .top)
    }

    /// An Indestructible brick, for the tests above.
    @discardableResult
    private func wall(_ scene: GameScene, at point: CGPoint) -> SKSpriteNode {
        let brick = addBrick(scene, at: point, size: cell)
        brick.texture = scene.brickIndestructible1Texture
        return brick
    }

    // MARK: - Density

    func testEmptyRowsAreNotAllowedToRunOn() {
        // Height is gained by clearing the bottom row, and an empty row is cleared the moment
        // it arrives - so a run of them is height for free, and the player is deep before the
        // mode has shown them anything
        XCTAssertEqual(EndlessIIProgression.mostEmptyRowsInARow, 2,
                       "James's taste, round 99: two empty rows is fine, occasional threes too")

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

        let overdue = empty()
        scene.endlessIIFillEmptyRowIfOverdue(overdue)
        let filled = overdue.compactMap { $0 as? SKSpriteNode }
            .filter { $0.texture != scene.brickNullTexture }
        XCTAssertEqual(filled.count, 1, "the row past the cap gets one brick, and only one")
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

/// Which other players get a line behind the field.
///
/// The last item in §12.0's backlog, unblocked when the Endless Mayhem boards were approved on
/// 21 August 2026. The board itself cannot be tested - it needs other people to have played -
/// so everything that can be decided without it is decided here, in `EndlessIIRivals`, and the
/// scene does no arithmetic of its own.
final class EndlessIIRivalLineTests: XCTestCase {

    private let board = [EndlessIIRival(name: "Alex", height: 412),
                         EndlessIIRival(name: "Sam", height: 380),
                         EndlessIIRival(name: "Jo", height: 640),
                         EndlessIIRival(name: "Kit", height: 455)]

    /// Nearest first, so the lines that arrive are the ones about to be reached.
    func testTheNearestRivalsAboveAreTheOnesDrawn() {
        let lines = EndlessIIRivals.lines(from: board, playerBest: 300)
        XCTAssertEqual(lines.map(\.name), ["Sam", "Alex", "Kit"])
        XCTAssertEqual(lines.count, EndlessIIRivals.mostLines,
                       "the backdrop is furniture, not a scoreboard")
    }

    /// A rival already below the run is a line that would be created behind the player.
    func testARivalBelowWhereTheRunHasGotToIsDropped() {
        let lines = EndlessIIRivals.lines(from: board, playerBest: 0, startingAt: 450)
        XCTAssertEqual(lines.map(\.name), ["Kit", "Jo"])
    }

    /// The player's own best keeps its row - it is the more useful of the two.
    func testARivalStandingOnThePlayersBestDoesNotTakeItsRow() {
        let lines = EndlessIIRivals.lines(from: board, playerBest: 412)
        XCTAssertFalse(lines.contains { $0.height == 412 },
                       "a rival drew over the BEST line")
        XCTAssertEqual(lines.map(\.name), ["Sam", "Kit", "Jo"])
    }

    /// Two players on one height share a line, and the higher-ranked keeps it.
    func testTwoPlayersOnOneHeightDoNotStackTwoLabels() {
        let tied = [EndlessIIRival(name: "First", height: 500),
                    EndlessIIRival(name: "Second", height: 500)]
        XCTAssertEqual(EndlessIIRivals.lines(from: tied, playerBest: 0).map(\.name), ["First"])
    }

    /// Nobody above, nothing drawn - the ordinary case for a player at the top or signed out.
    func testAnEmptyBoardDrawsNothing() {
        XCTAssertTrue(EndlessIIRivals.lines(from: [], playerBest: 900).isEmpty)
        XCTAssertTrue(EndlessIIRivals.lines(from: board, playerBest: 0, startingAt: 9000).isEmpty)
    }

    /// The label is the name and the height, and the name cannot run under the bricks.
    func testALongNameIsTrimmedRatherThanLeftToRunUnderTheField() {
        let long = EndlessIIRival(name: "A Very Long Display Name Indeed", height: 412)
        let label = EndlessIIRivals.label(for: long)
        XCTAssertTrue(label.hasSuffix("412m"))
        XCTAssertTrue(label.hasPrefix("A VERY LONG DIS"), "trimmed from the wrong end")
        XCTAssertLessThanOrEqual(label.count, EndlessIIRivals.longestName + 6,
                                 "the label would reach into the field")
    }

    /// A player with no display name at all still gets a readable line.
    func testANamelessRivalStillReadsAsAHeight() {
        XCTAssertEqual(EndlessIIRivals.label(for: EndlessIIRival(name: "  ", height: 412)),
                       "412m")
    }
}
