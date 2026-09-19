//
//  EndlessIIStyleTests.swift
//  GigaBallTests
//
//  A brick is a behaviour and a style, and the whole point is that they combine freely. The
//  few pairs that do not combine are the ones where the two contradict each other, and each
//  exclusion is a design decision worth being able to see - it is much easier to quietly
//  rule out half the grid than to notice afterwards that Multi-hit bricks never flash.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIStyleTests: XCTestCase {

    private let behaviours: [EndlessIIBehaviour] = [.standard, .multiHit, .indestructibleOnce,
                                                    .indestructibleAlways, .invisible]

    func testMostCombinationsAreAllowed() {
        // If this ever drops sharply, something has started excluding pairs wholesale.
        let total = EndlessIIStyle.allCases.count*behaviours.count
        let allowed = EndlessIIStyle.allCases
            .flatMap { style in behaviours.map { style.suits($0) } }
            .filter { $0 }.count
        XCTAssertGreaterThan(allowed, total/2, "\(allowed) of \(total)")
    }

    func testTheShapeAndMotionStylesFitEverything() {
        // The ones that only change how a brick looks or moves have nothing to contradict.
        for style in [EndlessIIStyle.rounded, .spinning, .gravity, .moving] {
            for behaviour in behaviours {
                XCTAssertTrue(style.suits(behaviour), "\(style) on \(behaviour)")
            }
        }
    }

    func testAnIndestructibleBrickCanStillSpin() {
        // The combination that prompted the split: an obstacle you cannot remove, showing a
        // different angle every time the ball reaches it.
        XCTAssertTrue(EndlessIIStyle.spinning.suits(.indestructibleAlways))
    }

    func testFlashingIsTheOneStyleInvisibleCannotTake() {
        // Both are about whether the brick can be seen.
        XCTAssertFalse(EndlessIIStyle.flashing.suits(.invisible))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.multiHit))
        XCTAssertTrue(EndlessIIStyle.flashing.suits(.indestructibleAlways))
    }

    func testDirectionalNeedsABrickThatCanBeDestroyed() {
        // Exploding and Spawner used to be here too. They are not any more: on a brick that
        // can never be destroyed they fire on every hit instead, which is a reading of the
        // same style rather than an exception to it. Directional has no such reading - it
        // describes how a brick is destroyed, and there is nothing to describe.
        XCTAssertFalse(EndlessIIStyle.directional.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.directional.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.directional.suits(.multiHit))
        // Indestructible x1 becomes x2 when hit, so it is destructible once
        XCTAssertTrue(EndlessIIStyle.directional.suits(.indestructibleOnce))
    }

    func testAPortalIsOnlyEverIndestructible() {
        // Struck rather than damaged, so its behaviour has to be the one that already means
        // a hit does nothing - which is what lets the bottom-row check ignore it and the
        // field keep generating.
        XCTAssertTrue(EndlessIIStyle.portal.suits(.indestructibleAlways))
        for behaviour in behaviours where behaviour != .indestructibleAlways {
            XCTAssertFalse(EndlessIIStyle.portal.suits(behaviour), "\(behaviour)")
        }
    }

    func testEveryStyleFitsSomething() {
        for style in EndlessIIStyle.allCases {
            XCTAssertTrue(behaviours.contains { style.suits($0) },
                          "\(style) fits nothing at all")
        }
    }

    func testEveryBehaviourCanTakeSomeStyle() {
        for behaviour in behaviours {
            XCTAssertTrue(EndlessIIStyle.allCases.contains { $0.suits(behaviour) },
                          "\(behaviour) can take nothing at all")
        }
    }
}

extension EndlessIIStyleTests {

    // MARK: - Stacking

    func testAStyleNeverStacksWithItself() {
        for style in EndlessIIStyle.allCases {
            XCTAssertFalse(style.stacksWith(style), "\(style)")
        }
    }

    func testStackingIsSymmetric() {
        // An asymmetry here would mean a pair that works in one generation order and not the
        // other, which would look like a bug that only happens sometimes.
        for a in EndlessIIStyle.allCases {
            for b in EndlessIIStyle.allCases {
                XCTAssertEqual(a.stacksWith(b), b.stacksWith(a), "\(a) / \(b)")
            }
        }
    }

    func testTheCombinationTheSplitWasBuiltFor() {
        // Indestructible, rounded and spinning: you cannot remove it, it shows a different
        // angle every time, and the angles are ones a rectangle never gives.
        XCTAssertTrue(EndlessIIStyle.rounded.stacksWith(.spinning))
        XCTAssertTrue(EndlessIIStyle.rounded.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spinning.suits(.indestructibleAlways))
    }

    func testTwoStylesThatBothMoveABrickCannotShareIt() {
        XCTAssertFalse(EndlessIIStyle.spinning.stacksWith(.moving))
        XCTAssertFalse(EndlessIIStyle.gravity.stacksWith(.moving))
    }

    func testAVulnerableSideMayBeHardToReachButNotImpossible() {
        // **The reverse of what this used to assert.** Spinning, Moving and Flashing were all
        // refused with Directional on one reasoning - "a vulnerable side has to stay findable"
        // - and the 2026 brick workbook's matrix takes the other view: "spinning plus
        // directional should be allowed" (James), and the other two follow from it. A soft
        // side that turns, wanders or blinks is a shot you have to *time*, which is what
        // Directional is for rather than a failure of it
        for style in [EndlessIIStyle.spinning, .moving, .flashing] {
            XCTAssertTrue(EndlessIIStyle.directional.stacksWith(style), "\(style)")
        }

        // What is still refused is the shapes, and that is James's own line: "directional
        // bricks are always the standard shape". It is the one pair that would have needed
        // hit detection against something other than a rectangle
        for face in EndlessIIFace.allCases {
            XCTAssertFalse(EndlessIIStyle.directional.stacksWith(face.style), "\(face)")
        }
    }

    func testOppositeAnswersToTheSameQuestionCannotShareABrick() {
        // One clears the neighbourhood, the other fills it.
        XCTAssertFalse(EndlessIIStyle.exploding.stacksWith(.spawner))
    }

    func testRoundedGoesWithEverythingThatIsNotItselfAShapeOrASize() {
        // It only changes the brick's outline, so it has nothing to fight over - until the
        // shaped faces arrived, which change the outline too. Two answers to "what shape is
        // this brick" is the one argument Rounded can have.
        //
        // Breathing joined them in round 142 for the same reason a size away: Rounded draws
        // its face once, at the size the brick was, and a brick that then shrinks would wear
        // a rounded face bigger than itself
        for style in EndlessIIStyle.allCases where style != .rounded {
            let expected = style.isFace == false && style != .breathing
            XCTAssertEqual(EndlessIIStyle.rounded.stacksWith(style), expected, "\(style)")
        }
    }

    // MARK: - Firing on hit

    func testTheDestructionStylesFireOnHitWhenTheBrickCannotBeDestroyed() {
        XCTAssertTrue(EndlessIIStyle.exploding.firesOnHit(with: .indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spawner.firesOnHit(with: .indestructibleAlways))
    }

    func testEverywhereElseTheyStillFireOnDestruction() {
        for behaviour in [EndlessIIBehaviour.standard, .multiHit,
                          .indestructibleOnce, .invisible] {
            XCTAssertFalse(EndlessIIStyle.exploding.firesOnHit(with: behaviour), "\(behaviour)")
            XCTAssertFalse(EndlessIIStyle.spawner.firesOnHit(with: behaviour), "\(behaviour)")
        }
    }

    func testNothingElseFiresOnHit() {
        for style in EndlessIIStyle.allCases where style != .exploding && style != .spawner {
            XCTAssertFalse(style.firesOnHit(with: .indestructibleAlways), "\(style)")
        }
    }

    func testAnIndestructibleBrickCanNowCarryThemAtAll() {
        // The point of the on-hit reading: they used to be excluded here entirely.
        XCTAssertTrue(EndlessIIStyle.exploding.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.spawner.suits(.indestructibleAlways))
    }
}

extension EndlessIIStyleTests {

    // MARK: - Fixed

    func testAFixedBrickNeedsToBeDestructible() {
        // It spends its first hit anchoring and its second dying. On a brick that never takes
        // damage it would simply never anchor.
        XCTAssertFalse(EndlessIIStyle.fixed.suits(.indestructibleAlways))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.standard))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.multiHit))
        XCTAssertTrue(EndlessIIStyle.fixed.suits(.invisible))
    }

    func testFixedCannotShareABrickWithAnythingThatMovesIt() {
        // One says stay exactly here, the others say do not.
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.moving))
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.gravity))
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.portal))
    }

    func testFixedStillCombinesWithTheHarmlessStyles() {
        // Anchoring says nothing about a brick's shape or what it does when destroyed - and
        // since round 235 it says nothing about its *outline* either, so an anchored dome is
        // now a brick that can exist
        for style in [EndlessIIStyle.rounded, .flashing, .exploding, .spawner,
                      .convex, .concave, .wedge, .diamond] {
            XCTAssertTrue(EndlessIIStyle.fixed.stacksWith(style), "\(style)")
        }

        // Spinning left this list on the workbook's matrix: one style anchors a brick where it
        // stands and the other never lets it stand still, which is the argument Fixed already
        // made against Moving and Gravity
        XCTAssertFalse(EndlessIIStyle.fixed.stacksWith(.spinning))
    }

    /// James, round 172: "at one point I had a big brick overlapping a fixed brick. In this
    /// case, the fixed brick should destroy the big brick."
    ///
    /// The crush rule answers "is this brick descending onto an anchor", which is the other way
    /// into an overlap. This one needs no descent at all: a Fixed brick anchors when it is
    /// *struck*, and a Big brick's other half may already be over the cell it anchors in.
    private func overlapScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.totalStatsArray = [TotalStats()]
        scene.brickWidth = 40
        scene.brickHeight = 20
        return scene
    }

    private func brick(on scene: GameScene, at x: CGFloat, wide: Bool,
                       anchored: Bool = false) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: wide ? scene.brickWidth*2 : scene.brickWidth,
                            height: scene.brickHeight)
        brick.position = CGPoint(x: x, y: 100)
        brick.name = BrickCategoryName
        brick.endlessIIIsAnchored = anchored
        scene.addChild(brick)
        return brick
    }

    func testAnAnchorDestroysABigBrickSharingItsSpace() {
        let scene = overlapScene()
        let anchor = brick(on: scene, at: 0, wide: false, anchored: true)
        let big = brick(on: scene, at: 20, wide: true)
        // The Big brick's left half sits over the anchor

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNil(big.parent, "the fixed brick destroys the big brick")
        XCTAssertNotNil(anchor.parent, "and outlives it, which is what being fixed means")
    }

    func testAnAnchorLeavesTheBrickBesideItAlone() {
        // Every pair of neighbours touches; touching is not overlapping
        let scene = overlapScene()
        _ = brick(on: scene, at: 0, wide: false, anchored: true)
        let big = brick(on: scene, at: scene.brickWidth*2, wide: true)

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNotNil(big.parent)
    }

    func testWithNothingAnchoredNothingIsDestroyed() {
        let scene = overlapScene()
        let plain = brick(on: scene, at: 0, wide: false)
        let big = brick(on: scene, at: 20, wide: true)

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNotNil(plain.parent)
        XCTAssertNotNil(big.parent, "an overlap with an ordinary brick is a different bug")
    }

    func testAnAnchoredBigBrickIsNotDestroyedByAnotherAnchor() {
        let scene = overlapScene()
        _ = brick(on: scene, at: 0, wide: false, anchored: true)
        let big = brick(on: scene, at: 20, wide: true, anchored: true)

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNotNil(big.parent, "an anchored brick stopped where it was struck")
    }

    /// An ordinary brick that ends up inside an anchor is destroyed too.
    ///
    /// "A Fixed brick destroys any brick that runs into it" (the 2026 brick workbook). The
    /// sweep was restricted to Big bricks, because they were the only ones that could end up
    /// sharing a cell - the generator never puts two ordinary bricks in one. A Moving brick can
    /// walk into an anchor now, so that stopped being true.
    func testAnAnchorDestroysAnOrdinaryBrickThatRunsIntoIt() {
        let scene = overlapScene()
        let anchor = brick(on: scene, at: 0, wide: false, anchored: true)
        let walker = brick(on: scene, at: 8, wide: false)
        // A fifth of a cell in - which is a brick that has walked into it, not one beside it

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNil(walker.parent, "an anchor is a hazard, not a wall")
        XCTAssertNotNil(anchor.parent)
    }

    /// And a near miss is still a near miss.
    ///
    /// The inset is what does that work, and it always did - it is why the Big-brick-only
    /// restriction could be lifted safely. Two bricks in touching cells, each inset by a
    /// quarter of a cell, leave half a cell of daylight between them.
    func testAnAnchorLeavesTheOrdinaryBrickInTheNextCellAlone() {
        let scene = overlapScene()
        _ = brick(on: scene, at: 0, wide: false, anchored: true)
        let neighbour = brick(on: scene, at: scene.brickWidth, wide: false)

        scene.endlessIIResolveAnchorOverlaps()
        XCTAssertNotNil(neighbour.parent, "a brick the player was owed")
    }

    /// A Moving brick no longer treats an anchor as a wall to turn round at.
    ///
    /// Which is the whole of how it comes to run into one: left in the list of things that
    /// stop a wanderer, an anchor would have turned it round a hair's breadth short - the
    /// opposite of running into something.
    func testAWandererIsNotStoppedByAnAnchor() {
        let scene = overlapScene()
        scene.gameWidth = 440
        scene.numberOfBrickColumns = 11
        let wanderer = brick(on: scene, at: 0, wide: false)
        let anchor = brick(on: scene, at: scene.brickWidth, wide: false, anchored: true)

        let stopped = scene.endlessIIWanderLimits(for: wanderer)
        XCTAssertEqual(stopped.right, scene.gameWidth/2 - scene.brickWidth/2, accuracy: 0.5,
                       "the anchor should not be a wall")

        anchor.endlessIIIsAnchored = false
        let blocked = scene.endlessIIWanderLimits(for: wanderer)
        XCTAssertLessThan(blocked.right, stopped.right,
                          "and an ordinary brick still is one, or this test proves nothing")
    }

    // MARK: - What a Spawner draws

    func testASpawnerFillsBetweenOneAndAllOfItsEmptyNeighbours() {
        // "Spawner bricks when hit create between 1 and 8 bricks in the adjacent cells. This
        // number and the position of the new bricks around the spawner should be randomised"
        // (James, on the 2026 brick workbook). It used to fill every cell it could reach,
        // which made it the most predictable brick in the mode
        let room = (0..<8).map { EndlessIICell(column: $0, row: 0) }

        XCTAssertEqual(GameScene.endlessIISpawnChoice(from: room, count: { _ in 3 },
                                                      order: { $0 }).count, 3)
        XCTAssertEqual(GameScene.endlessIISpawnChoice(from: room, count: { _ in 8 },
                                                      order: { $0 }).count, 8)
    }

    func testASpawnerAlwaysMakesAtLeastOne() {
        // A hit that visibly produces nothing reads as a brick that failed rather than as one
        // that rolled low - so the floor is one, and the ceiling is however many cells are
        // actually free rather than eight
        let one = [EndlessIICell(column: 0, row: 0)]
        XCTAssertEqual(GameScene.endlessIISpawnChoice(from: one, count: { _ in 8 }).count, 1)
        XCTAssertEqual(GameScene.endlessIISpawnChoice(from: one, count: { _ in 0 }).count, 1)
        XCTAssertTrue(GameScene.endlessIISpawnChoice(from: [], count: { _ in 4 }).isEmpty,
                      "and a Spawner with nowhere to put anything puts nothing")
    }

    func testASpawnerDrawsWhichCellsAsWellAsHowMany() {
        // Trimmed after the shuffle, not before. Taking the first n of the neighbour list in
        // its natural order would have given a count that varied and a shape that never did
        let room = (0..<8).map { EndlessIICell(column: $0, row: 0) }
        let picked = GameScene.endlessIISpawnChoice(from: room, count: { _ in 2 },
                                                    order: { $0.reversed() })
        XCTAssertEqual(picked, [EndlessIICell(column: 7, row: 0),
                                EndlessIICell(column: 6, row: 0)])
    }

    func testAnAnchorFlagTravelsWithItsBrick() {
        let brick = SKSpriteNode()
        XCTAssertFalse(brick.endlessIIIsAnchored)
        brick.endlessIIIsAnchored = true
        XCTAssertTrue(brick.endlessIIIsAnchored)

        brick.endlessIIRole = .fixed
        XCTAssertTrue(brick.endlessIIIsAnchored, "setting a role must not clear the anchor")
    }
}
