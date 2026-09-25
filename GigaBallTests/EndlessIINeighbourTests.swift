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

    /// James, round 342: "Spawner bricks and exploding bricks should activate every time that
    /// they are hit, not just when the brick is destroyed."
    ///
    /// A Multi-Hit Exploding brick, struck once: it survives the hit and still goes off. Before,
    /// it only ever went off on the fourth.
    func testAnExplodingBrickGoesOffOnAHitItSurvives() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let centre = addBrick(scene, at: .zero, size: cell)
        centre.texture = scene.brickMultiHit1Texture
        scene.makeExploding(centre)
        let neighbour = addBrick(scene, at: CGPoint(x: cell.width, y: 0), size: cell)
        neighbour.texture = scene.brickNormalTexture

        scene.hitBrick(node: centre, sprite: centre)

        XCTAssertNotNil(centre.parent, "a Multi-Hit brick survives its first hit")
        XCTAssertEqual(centre.texture, scene.brickMultiHit2Texture)
        XCTAssertNil(neighbour.parent, "and the hit it survived still set it off")
    }

    /// And the one-hit kind is not set off twice: the hit that destroys it is the hit.
    func testAnExplodingBrickThatIsDestroyedGoesOffOnce() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let centre = addBrick(scene, at: .zero, size: cell)
        centre.texture = scene.brickNormalTexture
        scene.makeExploding(centre)

        let before = scene.children.count
        scene.hitBrick(node: centre, sprite: centre)
        let rings = scene.children.filter { $0 is SKShapeNode }.count
        XCTAssertEqual(rings, 1, "one blast ring, not one for the hit and one for the "
                       + "destruction (\(before) children before)")
    }

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

    // MARK: - A Fixed brick has teeth

    /// A falling brick is destroyed by the anchor it lands on.
    ///
    /// "A Fixed brick destroys any brick that runs into it, so an anchor becomes a hazard to
    /// the field rather than only to the player" (the 2026 brick workbook). The descent's own
    /// crush rule already did this for rows coming down; a Gravity brick falls under its own
    /// power and simply came to rest on top of one.
    ///
    /// It lands first and dies on arrival rather than vanishing in mid-air: the brick has to be
    /// seen to run into the anchor, or a faller stopping short and disappearing reads as a
    /// brick that failed rather than as one that was struck.
    func testAFallingBrickIsDestroyedByTheAnchorItLandsOn() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]

        let anchor = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        anchor.endlessIIIsAnchored = true
        let faller = addBrick(scene, at: CGPoint(x: 0, y: 200 + cell.height*3), size: cell)
        faller.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        guard let fall = scene.endlessIIFallers[ObjectIdentifier(faller)] else {
            return XCTFail("it should be falling at all")
        }
        XCTAssertTrue(fall.crushes, "it is falling onto an anchor and does not survive it")
        XCTAssertEqual(fall.targetY, 200 + cell.height, accuracy: 0.5,
                       "and it stops on top of the anchor rather than inside it")

        scene.tickEndlessIIRoles(1)
        XCTAssertNil(faller.parent, "the anchor destroyed it")
        XCTAssertNotNil(anchor.parent, "and outlived it, which is what being fixed means")
    }

    /// One landing on an ordinary brick still just lands on it.
    func testAFallingBrickRestsOnAnOrdinaryBrick() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]

        _ = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        let faller = addBrick(scene, at: CGPoint(x: 0, y: 200 + cell.height*3), size: cell)
        faller.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        XCTAssertEqual(scene.endlessIIFallers[ObjectIdentifier(faller)]?.crushes, false)

        scene.tickEndlessIIRoles(1)
        XCTAssertNotNil(faller.parent)
        XCTAssertEqual(faller.position.y, 200 + cell.height, accuracy: 0.5)
    }

    /// And one already resting on an anchor is destroyed where it stands.
    ///
    /// It has nowhere to fall to, so the "did it move?" guard used to send it away untouched -
    /// which would have left every faller that came to rest on a Fixed brick before this round
    /// sitting there for ever.
    func testABrickAlreadyRestingOnAnAnchorIsDestroyedAnyway() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]

        let anchor = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        anchor.endlessIIIsAnchored = true
        let resting = addBrick(scene, at: CGPoint(x: 0, y: 200 + cell.height), size: cell)
        resting.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        scene.tickEndlessIIRoles(1)
        XCTAssertNil(resting.parent)
    }

    // MARK: - Big and Tiny against the movement actions

    /// A Big brick, built the way the generator builds one: node on a row centre, sprite
    /// hanging off it (§8.6).
    private func bigBrick(_ scene: GameScene, atCell origin: EndlessIICell) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: cell.width*2, height: cell.height*2))
        brick.anchorPoint = CGPoint(x: 0.25, y: 0.75)
        brick.position = scene.endlessIIGeometry.centre(of: origin)
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    /// A Big Gravity brick falls, and asks about both of the columns it stands in.
    ///
    /// It could not take the style at all before: the fall asked whether the cell one row below
    /// the *node* was free, and for a Big brick that cell is part of the brick itself - never
    /// free, so it never moved. Asking one column would have been worse than not falling: it
    /// would have settled with its other half inside a neighbour.
    func testABigBrickFallsByWholeRowsAndClearsBothColumns() {
        let scene = fieldScene()
        let big = bigBrick(scene, atCell: EndlessIICell(column: 4, row: 3))
        XCTAssertTrue(scene.endlessIICanTake(.gravity, big),
                      "any size can take any motion (the 2026 brick workbook)")
        big.endlessIIRole = .gravity
        // Asked before the role is written on, not after: a brick already wearing a style
        // cannot be offered it again, so the other order tests nothing

        scene.settleEndlessIIGravityBricks()
        guard let fall = scene.endlessIIFallers[ObjectIdentifier(big)] else {
            return XCTFail("a Big brick with nothing under it should fall")
        }
        XCTAssertLessThan(fall.targetY, big.position.y)
    }

    /// And it stops on whatever is under either half of it.
    func testABigBrickStopsOnABrickUnderItsFarHalf() {
        let scene = fieldScene()
        let big = bigBrick(scene, atCell: EndlessIICell(column: 4, row: 3))
        big.endlessIIRole = .gravity

        // Under the brick's *right* column, three rows down. Its node is in column 4, so a
        // check that only looked at the node's column would not see this at all
        let floor = EndlessIICell(column: 5, row: 8)
        _ = addBrick(scene, at: scene.endlessIIGeometry.centre(of: floor), size: cell)

        scene.settleEndlessIIGravityBricks()
        let target = scene.endlessIIFallers[ObjectIdentifier(big)]?.targetY
        XCTAssertEqual(target ?? 0,
                       scene.endlessIIGeometry.centre(of: EndlessIICell(column: 4, row: 6)).y,
                       accuracy: 0.5,
                       "it should come to rest with its lower row on top of the floor")
    }

    /// An anchored Big brick holds all four of its cells.
    ///
    /// A Big brick can be Fixed since round 237. An anchor claiming only the cell its node sits
    /// in would let the field descend into the other three.
    func testAnAnchoredBigBrickHoldsEveryCellItFills() {
        let scene = fieldScene()
        let big = bigBrick(scene, atCell: EndlessIICell(column: 4, row: 3))
        big.endlessIIIsAnchored = true

        XCTAssertEqual(scene.endlessIIAnchoredCells(),
                       [EndlessIICell(column: 4, row: 3), EndlessIICell(column: 5, row: 3),
                        EndlessIICell(column: 4, row: 4), EndlessIICell(column: 5, row: 4)])
    }

    /// A Tiny brick can fall now, and every other motion was already open to it.
    ///
    /// It was the one size Gravity refused, because the fall walked the occupancy map a row at
    /// a time and that map can say how full a cell is but never *where* in it the space is.
    /// The fall measures frames since round 244, and a frame is a frame at any size.
    func testATinyBrickCanTakeEveryMotion() {
        let scene = fieldScene()
        let tiny = tinyBrick(scene, at: CGPoint(x: 0, y: 200))

        XCTAssertTrue(scene.endlessIICanTake(.gravity, tiny))
        XCTAssertTrue(scene.endlessIICanTake(.moving, tiny))
        XCTAssertTrue(scene.endlessIICanTake(.fixed, tiny))
    }

    /// **And it lands on its own sibling rather than through it.**
    ///
    /// This is the failure the old restriction existed to avoid, and the reason the fix had to
    /// be a rewrite rather than a relaxation: four quarter-cell bricks share one cell, so a
    /// faller dropped by a whole row passes straight through the three it shares with.
    func testATinyBrickLandsOnTheOneBelowItRatherThanThroughIt() {
        let scene = fieldScene()
        let quarter = cell.height/2

        // One resting in the lower half of its cell, and one falling down the same column
        let below = tinyBrick(scene, at: CGPoint(x: -cell.width/4, y: 200 - quarter/2))
        let faller = tinyBrick(scene, at: CGPoint(x: -cell.width/4, y: 200 + cell.height*3))
        faller.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        scene.tickEndlessIIRoles(1)

        XCTAssertNotNil(faller.parent)
        XCTAssertGreaterThan(faller.frame.minY, below.frame.maxY - 0.5,
                             "it came to rest inside the brick it landed on")
        XCTAssertLessThan(faller.frame.minY, below.frame.maxY + quarter,
                          "and it should be resting on it, not hovering a row above")
    }

    /// A Tiny brick keeps its own quarter of the cell rather than being snapped to a row.
    ///
    /// Everything else comes to rest on a row centre, because a brick's `position.y` is its row
    /// (§8.6). A Tiny brick is a quarter of a cell and lives off those centres by design, so
    /// snapping one would move it by half a cell - into whatever it just landed on.
    func testATinyBrickIsNotSnappedToARowCentre() {
        let scene = fieldScene()
        let floorTop = 200 + cell.height/2

        let ground = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        let faller = tinyBrick(scene, at: CGPoint(x: -cell.width/4, y: 200 + cell.height*4))
        faller.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        scene.tickEndlessIIRoles(1)

        XCTAssertEqual(faller.frame.minY, floorTop, accuracy: 0.5,
                       "its underside should be on the brick it landed on")
        XCTAssertNotEqual(faller.position.y, ground.position.y + cell.height, accuracy: 0.5,
                          "and it should not have been rounded onto the row centre above")
    }

    /// An ordinary brick landing on a Tiny one is rounded *up* to the row above.
    ///
    /// It has come to rest half a cell off the grid, and its `position.y` has to be a row or
    /// the descent and the bottom-row check disagree about where it is. Rounding down would
    /// push it into the brick it just landed on, so it sits a little high instead.
    func testAnOrdinaryBrickRestingOnATinyOneIsRoundedUpwards() {
        let scene = fieldScene()
        let geometry = scene.endlessIIGeometry

        tinyBrick(scene, at: CGPoint(x: 0, y: 200 - cell.height/4))
        let faller = addBrick(scene, at: CGPoint(x: 0, y: 200 + cell.height*4), size: cell)
        faller.endlessIIRole = .gravity

        scene.settleEndlessIIGravityBricks()
        scene.tickEndlessIIRoles(1)

        let row = geometry.cell(at: faller.position).row
        XCTAssertEqual(faller.position.y, geometry.centre(of: EndlessIICell(column: 5, row: row)).y,
                       accuracy: 0.5, "it has to come to rest on a row centre (§8.6)")
        XCTAssertGreaterThan(faller.frame.minY, 200 - cell.height/4 + cell.height/4 - 0.5,
                             "and above the Tiny brick rather than inside it")
    }

    /// A quarter-cell brick, built the way `makeTiny` builds one.
    @discardableResult
    private func tinyBrick(_ scene: GameScene, at point: CGPoint) -> SKSpriteNode {
        let gap = scene.endlessIITinyGap
        let brick = SKSpriteNode(texture: scene.brickNormalTexture,
                                 size: CGSize(width: cell.width/2 - gap,
                                              height: cell.height/2 - gap))
        brick.position = point
        brick.name = BrickCategoryName
        scene.addChild(brick)
        return brick
    }

    /// A scene with the field geometry filled in and a Mayhem mode, for the tests above.
    private func fieldScene() -> GameScene {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        return scene
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

    // MARK: - James's round 339 gameplay notes

    /// "Can gravity bricks slowly accelerate as they fall - not like full gravity - not
    /// starting super slow either - and ensure there's a top speed."
    func testAGravityBrickSpeedsUpToALimit() {
        XCTAssertGreaterThanOrEqual(EndlessIIFall.startSpeed, 2, "not starting super slow")
        var speed = EndlessIIFall.startSpeed
        var previous = speed
        for _ in 0..<12 {
            speed = EndlessIIFall.accelerated(speed, over: 1.0/60)
            XCTAssertGreaterThanOrEqual(speed, previous, "it only ever speeds up")
            previous = speed
        }
        XCTAssertGreaterThan(speed, EndlessIIFall.startSpeed, "and it does speed up")
        XCTAssertEqual(EndlessIIFall.accelerated(speed, over: 10), EndlessIIFall.topSpeed,
                       "with a top speed")
    }

    /// And a fall that loses its support again keeps the speed it had built up.
    func testAFallingBrickThatIsDroppedAgainKeepsItsSpeed() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let faller = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        faller.endlessIIRole = .gravity
        scene.settleEndlessIIGravityBricks()
        scene.tickEndlessIIRoles(0.1)
        let built = scene.endlessIIFallers[ObjectIdentifier(faller)]?.speed ?? 0
        XCTAssertGreaterThan(built, EndlessIIFall.startSpeed)

        scene.settleEndlessIIGravityBricks()
        XCTAssertEqual(scene.endlessIIFallers[ObjectIdentifier(faller)]?.speed ?? 0, built,
                       accuracy: 0.001, "the same fall, going further")
    }

    /// "During the drift power-up, if any direction bricks with their side face open end up
    /// with the open side against the wall when the drift power-up ends, remove those bricks
    /// automatically."
    func testDriftEndingRemovesADirectionalBrickFacingTheWall() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        let leftmost = -scene.gameWidth/2 + cell.width/2
        let rightmost = scene.gameWidth/2 - cell.width/2

        func directional(_ x: CGFloat, facing side: EndlessIISide) -> SKSpriteNode {
            let brick = addBrick(scene, at: CGPoint(x: x, y: 200), size: cell)
            brick.endlessIIRole = .directional
            brick.endlessIIVulnerableSide = side
            return brick
        }
        let intoTheLeftWall = directional(leftmost, facing: .left)
        let intoTheRightWall = directional(rightmost, facing: .right)
        let upAtTheWall = directional(leftmost, facing: .top)
        let leftInTheMiddle = directional(0, facing: .left)

        scene.endEndlessIIDrift()

        XCTAssertNotEqual(intoTheLeftWall.name, BrickCategoryName, "no ball can reach that face")
        XCTAssertNotEqual(intoTheRightWall.name, BrickCategoryName, "nor that one")
        XCTAssertEqual(upAtTheWall.name, BrickCategoryName, "a face the ball can reach stays")
        XCTAssertEqual(leftInTheMiddle.name, BrickCategoryName, "and so does one away from it")
    }

    /// "Be a bit more fair with the directional bricks - the corner of the open face can be hit
    /// and the brick isn't destroyed - we should count this as a hit."
    func testTheCornerOfTheOpenFaceIsAHit() {
        let rect = CGRect(x: -20, y: -10, width: 40, height: 20)
        let corner = CGPoint(x: 23, y: 12)
        XCTAssertEqual(EndlessIIImpact.faces(ballAt: corner, brick: rect), [.top, .right],
                       "a ball on the corner is touching both faces")
        XCTAssertEqual(EndlessIIImpact.faces(ballAt: CGPoint(x: 0, y: 15), brick: rect), [.top],
                       "flat on, only the one")

        let scene = makeScene()
        let brick = addBrick(scene, at: .zero, size: cell)
        brick.endlessIIRole = .directional
        brick.endlessIIVulnerableSide = .top
        let primary = EndlessIIImpact.side(ballAt: CGPoint(x: 24, y: 11), brickAt: .zero,
                                           brickSize: cell)
        XCTAssertEqual(primary, .right, "the one-face reading calls this corner the armour")
        XCTAssertTrue(scene.endlessIIAcceptsHit(brick, from: primary,
                                                touching: [.top, .right]),
                      "and the open face it also touched makes it a hit")
        XCTAssertFalse(scene.endlessIIAcceptsHit(brick, from: .right, touching: [.right]),
                       "the armour alone is still armour")
    }

    /// "For the portal animation, remove the purple circle that shows up where the ball
    /// contacts the brick."
    func testAPortalJumpDrawsNoRings() {
        let scene = makeScene()
        scene.endlessIIShowPortalJump(from: .zero, to: CGPoint(x: 0, y: 200))
        let rings = scene.children.compactMap { $0 as? SKShapeNode }
            .filter { $0.strokeColor == GameScene.portalBrickColour }
        XCTAssertTrue(rings.isEmpty, "the line between the two ends is the whole of it now")
    }

    /// "Following a quicksand power-up in endless mayhem mode, with bricks on the lowest rows
    /// destroyed during the power-up, when returning to the regular brick position, the bricks
    /// didn't descend to the lowest row until another brick was destroyed."
    func testTheFieldStepsDownAsSoonAsQuicksandHasLetGo() {
        let scene = makeScene()
        scene.gameMode = .endlessII
        scene.endlessMode = true
        scene.totalStatsArray = [TotalStats()]
        _ = addBrick(scene, at: CGPoint(x: 0, y: 200), size: cell)
        // High in the field: the bottom row is empty, as it is after the rows Quicksand pushed
        // down were cleared while it held the field
        scene.endlessIIFieldShift = -cell.height*2
        let before = scene.endlessHeight

        scene.tickEndlessIIFieldShift(10)

        XCTAssertEqual(scene.endlessIIFieldShift, 0, "the field is back where it belongs")
        XCTAssertGreaterThan(scene.endlessHeight, before,
                             "and it stepped down on landing rather than waiting for a brick")
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

/// What a contact sets off, driven through `handleContact` (round 345).
///
/// The CRAP pass put `didBegin` at the top of the app: seventy-three decisions and none of them
/// run by a test, because an `SKPhysicsContact` cannot be made outside the engine. The handler
/// takes the two bodies now, and bodies can be made.
final class ContactRoutingTests: XCTestCase {

    private let cell = CGSize(width: 40, height: 20)

    private func scene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 500, height: 900))
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.gameWidth = 440
        scene.brickWidth = cell.width
        scene.brickHeight = cell.height
        scene.numberOfBrickColumns = 11
        scene.numberOfBrickRows = 22
        scene.yBrickOffsetEndless = 300
        scene.finalBrickRowHeight = 300 - cell.height*21
        scene.ballSize = 12
        scene.ball.size = CGSize(width: 12, height: 12)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        scene.ball.physicsBody?.categoryBitMask = CollisionTypes.ballCategory.rawValue
        scene.ball.physicsBody?.velocity = CGVector(dx: 120, dy: 300)
        scene.addChild(scene.ball)
        return scene
    }

    private func brick(in scene: GameScene, at point: CGPoint = .zero) -> SKSpriteNode {
        let brick = SKSpriteNode(color: .white, size: cell)
        brick.texture = scene.brickNormalTexture
        brick.position = point
        brick.name = BrickCategoryName
        brick.physicsBody = SKPhysicsBody(rectangleOf: cell)
        brick.physicsBody?.categoryBitMask = CollisionTypes.brickCategory.rawValue
        scene.addChild(brick)
        return brick
    }

    func testABallMeetingABrickBreaksIt() {
        let scene = scene()
        let target = brick(in: scene)
        scene.ball.position = CGPoint(x: 0, y: -cell.height/2 - 6)

        scene.handleContact(between: scene.ball.physicsBody!, and: target.physicsBody!)
        XCTAssertNotEqual(target.name, BrickCategoryName, "an ordinary brick goes on one hit")
    }

    /// The order the engine hands the bodies over in does not matter.
    func testEitherOrderIsTheSameContact() {
        let scene = scene()
        let target = brick(in: scene)
        scene.ball.position = CGPoint(x: 0, y: -cell.height/2 - 6)

        scene.handleContact(between: target.physicsBody!, and: scene.ball.physicsBody!)
        XCTAssertNotEqual(target.name, BrickCategoryName)
    }

    /// James, round 339: "the corner of the open face can be hit and the brick isn't destroyed
    /// - we should count this as a hit." Through the contact, where the faces are worked out.
    func testTheCornerOfADirectionalBricksOpenFaceBreaksIt() {
        let scene = scene()
        let target = brick(in: scene)
        target.endlessIIRole = .directional
        target.endlessIIVulnerableSide = .top
        scene.ball.position = CGPoint(x: cell.width/2 + 4, y: cell.height/2 + 2)
        // Past the top-right corner, and further along x than y by the brick's own proportions,
        // so the one-face reading calls it the armoured right side

        scene.handleContact(between: scene.ball.physicsBody!, and: target.physicsBody!)
        XCTAssertNotEqual(target.name, BrickCategoryName, "the open face's corner is a hit")
    }

    func testAnArmouredFaceStillBouncesTheBall() {
        let scene = scene()
        let target = brick(in: scene)
        target.endlessIIRole = .directional
        target.endlessIIVulnerableSide = .top
        scene.ball.position = CGPoint(x: 0, y: -cell.height/2 - 6)

        scene.handleContact(between: scene.ball.physicsBody!, and: target.physicsBody!)
        XCTAssertEqual(target.name, BrickCategoryName, "the underside is armour")
    }

    func testALaserBreaksABrickAndIsCounted() {
        let scene = scene()
        let target = brick(in: scene)
        let laser = SKSpriteNode(color: .red, size: CGSize(width: 3, height: 12))
        laser.name = LaserCategoryName
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.categoryBitMask = CollisionTypes.laserCategory.rawValue
        scene.addChild(laser)

        scene.handleContact(between: laser.physicsBody!, and: target.physicsBody!)
        XCTAssertNotEqual(target.name, BrickCategoryName)
        XCTAssertEqual(scene.totalStatsArray[0].lasersHit, 1)
    }

    /// Round 200's crash in the wild: a Cluster ball that met two bricks in one frame arrived
    /// at the second contact already removed, and the handler force-unwrapped its node.
    func testALaserAlreadyGoneIsNotACrash() {
        let scene = scene()
        let target = brick(in: scene)
        let orphan = SKPhysicsBody(rectangleOf: CGSize(width: 3, height: 12))
        orphan.categoryBitMask = CollisionTypes.laserCategory.rawValue
        // A body on no node at all, which is what a removed node's contact carries

        scene.handleContact(between: orphan, and: target.physicsBody!)
        XCTAssertEqual(target.name, BrickCategoryName, "nothing to do, and nothing done")
    }
}
