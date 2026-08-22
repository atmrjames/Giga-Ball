//
//  EndlessIIBrickTests.swift
//  GigaBallTests
//
//  A flashing brick makes a promise: what you can see, you can hit. If the solid window and
//  the opaque window ever come apart, the brick lies - either the ball passes through
//  something that looks solid, or it bounces off something that looks like a gap. Neither
//  is a crash, so nothing else would catch it.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class EndlessIIBrickTests: XCTestCase {

    /// James, round 172: "if an invisible brick is the only brick on the bottom row of Endless
    /// Mayhem mode, it should briefly flash up when the ball hits the paddle. Copy the same
    /// existing interaction that happens in Classic mode when all bricks left are invisible."
    ///
    /// Classic flashes when there is nothing visible *anywhere*, because there a hidden brick
    /// is a brick you cannot find. Mayhem needs the question asked of the bottom zone as well:
    /// that is what the descent waits on, so a hidden brick down there stops the field, stops
    /// the height, and gives no reason for either.
    private func zoneScene() -> GameScene {
        let scene = GameScene()
        scene.gameMode = .endlessII
        scene.brickHeight = 20
        scene.finalBrickRowHeight = 0
        return scene
    }

    private func zoneBrick(on scene: GameScene, y: CGFloat, hidden: Bool) -> SKSpriteNode {
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: 40, height: scene.brickHeight)
        brick.position = CGPoint(x: 0, y: y)
        brick.name = BrickCategoryName
        brick.isHidden = hidden
        scene.addChild(brick)
        return brick
    }

    func testAHiddenBrickAloneInTheBottomZoneAsksForTheFlash() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)

        XCTAssertTrue(scene.endlessIIBottomZoneIsAllHidden)
    }

    /// James, round 215, narrowing round 210: "an invisible brick on the bottom row should
    /// flash on paddle hit if there's no other visible bricks on the same row in Endless
    /// modes."
    ///
    /// Round 210 read his earlier note as being about the whole field and required nothing
    /// visible anywhere. That is far stricter than the thing being explained: what stalls the
    /// descent is *this row*, so a row of nothing-but-hidden is worth a clue however busy the
    /// rest of the field looks.
    func testAVisibleBrickHigherUpDoesNotCallOffTheFlash() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)
        zoneBrick(on: scene, y: 200, hidden: false)

        XCTAssertTrue(scene.endlessIIBottomZoneIsAllHidden,
                      "the row is still held up by something nobody can see")
    }

    /// And a visible brick *on the row* is the thing that calls it off, because then there is
    /// something to hit and nothing to explain.
    func testAVisibleBrickOnTheSameRowCallsItOff() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)
        zoneBrick(on: scene, y: 0, hidden: false)

        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden)
    }

    /// An Indestructible in view is not a brick the player could go and hit, so it can never
    /// be the thing they are being pointed at, and it does not make the field look playable.
    func testAnIndestructibleInViewDoesNotCallOffTheFlash() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)
        let wall = zoneBrick(on: scene, y: 200, hidden: false)
        wall.texture = scene.brickIndestructible1Texture

        XCTAssertTrue(scene.endlessIIBottomZoneIsAllHidden)
    }

    /// James, round 184: after force-quitting and resuming a Mayhem run with Fog of War
    /// active, "hidden bricks are flashing on every paddle bounce even though there are other
    /// visible bricks."
    ///
    /// The zone rule exists to explain a brick the player cannot know about. On a fogged day
    /// every brick starts hidden by design, so the zone is nearly always all-hidden - and
    /// explaining the fog to the player who chose the fog is the twist being handed back.
    func testAFoggedDayAsksForNoFlashAtAll() {
        let scene = zoneScene()
        DailyChallengeSession.shared.active = DailyChallenge(
            dateKey: "t", mode: .endlessII, classicLevel: nil, twists: [.fogOfWar])
        defer { DailyChallengeSession.shared.active = nil }

        zoneBrick(on: scene, y: 0, hidden: true)
        XCTAssertTrue(scene.dailyFogIsOn, "the day this is about")
        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden,
                       "the fog is the reason, and the player was told it")
    }

    func testAVisibleBrickInTheZoneExplainsItself() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)
        zoneBrick(on: scene, y: 0, hidden: false)

        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden)
    }

    func testAnEmptyZoneAsksForNothing() {
        let scene = zoneScene()
        zoneBrick(on: scene, y: 200, hidden: true)

        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden,
                       "nothing is holding the field up, so nothing needs explaining")
    }

    func testAnAnchoredBrickIsNotWhatHoldsTheFieldUp() {
        // An anchored brick does not descend and does not block the descent either
        let scene = zoneScene()
        let anchored = zoneBrick(on: scene, y: 0, hidden: true)
        anchored.endlessIIIsAnchored = true

        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden)
    }

    func testTheClassicRuleIsNotAskedOfOtherModes() {
        let scene = zoneScene()
        scene.gameMode = .classic
        zoneBrick(on: scene, y: 0, hidden: true)

        XCTAssertFalse(scene.endlessIIBottomZoneIsAllHidden,
                       "Classic has its own rule and this is not it")
    }

    // MARK: - The flash itself

    /// James, round 177: "all of a sudden all the bricks flashed when the ball hit the paddle
    /// and then disappeared. I didn't have any power-ups at the time... It kept happening every
    /// so often after that when the ball hit the paddle."
    ///
    /// The trigger was round 173's, and legitimate - a hidden brick had descended into the
    /// bottom zone. The damage was the off-phase: it hid everything wearing the ordinary brick
    /// texture, an assumption safe only in Classic, where the interaction never fires while
    /// such a brick is visible. Mayhem's ordinary bricks wear exactly that texture, so one
    /// flash swallowed the field - and a field of freshly hidden bricks re-arms the Classic
    /// trigger, which is the "kept happening".
    func testTheFlashGivesBackOnlyWhatItBorrowed() {
        let scene = zoneScene()
        let lurker = zoneBrick(on: scene, y: 0, hidden: true)
        let field = (1...5).map { index -> SKSpriteNode in
            let wall = zoneBrick(on: scene, y: CGFloat(200 + 20*index), hidden: false)
            wall.texture = scene.brickIndestructible1Texture
            return wall
        }
        // Indestructible walls, since round 210: a *destructible* brick in view calls the
        // flash off altogether now, and what this test is about is the off-phase not taking
        // bricks it never revealed. Walls are also what really is left in view when a hidden
        // brick is the last thing holding the field up

        scene.invisibleBrickFlash()
        XCTAssertFalse(lurker.isHidden, "the lurker is what the flash is for")

        scene.invisibleBrickFlashOff()
        XCTAssertTrue(lurker.isHidden, "borrowed, and given back")
        for brick in field {
            XCTAssertFalse(brick.isHidden, "a visible brick is not the flash's to take")
            XCTAssertEqual(brick.alpha, 1, accuracy: 0.0001)
        }
    }

    func testAFlashedFieldDoesNotReArmTheTrigger() {
        // The second half of the report: once the field had been swallowed, every later paddle
        // hit flashed it again. After a full flash cycle the field must look untouched, so the
        // Classic all-hidden rule reads exactly as it did before the flash.
        let scene = zoneScene()
        zoneBrick(on: scene, y: 0, hidden: true)
        let field = zoneBrick(on: scene, y: 300, hidden: false)

        scene.invisibleBrickFlash()
        scene.invisibleBrickFlashOff()
        scene.invisibleBrickFlash()
        scene.invisibleBrickFlashOff()

        XCTAssertFalse(field.isHidden)
    }

    /// James, round 180: "the bricks flash then disappearing on paddle bounce happened
    /// again. And it isn't linked to the descent power up."
    ///
    /// The second cause, found where the first was: Classic's own trigger - "is everything
    /// you could still hit invisible" - was still being asked in Mayhem, and Mayhem's Fixed
    /// bricks wear the Indestructible texture that check deliberately ignores. A field whose
    /// only visible bricks were Fixed walls read as an empty one, and every paddle hit
    /// flashed the mode's ordinary hidden bricks on and straight off again.
    func testAFieldOfVisibleFixedWallsDoesNotFireClassicsRule() {
        let scene = zoneScene()
        let wall = SKSpriteNode(texture: scene.brickIndestructible2Texture)
        wall.size = CGSize(width: 40, height: 20)
        wall.position = CGPoint(x: 0, y: 300)
        wall.name = BrickCategoryName
        scene.addChild(wall)
        // A visible Fixed brick, high in the field - outside the zone, outside the checked
        // texture list

        let hidden = zoneBrick(on: scene, y: 300, hidden: true)
        // And a hidden ordinary brick beside it, also outside the zone - the brick the
        // spurious flash kept showing and taking away

        scene.invisibleBrickFlash()
        XCTAssertTrue(hidden.isHidden,
                      "no flash: Mayhem answers its zone rule and only its zone rule")
    }

    func testClassicsOwnRuleStillFiresInClassic() {
        let scene = zoneScene()
        scene.gameMode = .classic
        let hidden = zoneBrick(on: scene, y: 300, hidden: true)

        scene.invisibleBrickFlash()
        XCTAssertFalse(hidden.isHidden,
                       "everything hittable is invisible, which is Classic's whole trigger")
    }

    func testTheZoneRuleStillFlashesItsLurker() {
        // Scoping Classic's rule out of Mayhem must not take the round-173 feature with it
        let scene = zoneScene()
        let lurker = zoneBrick(on: scene, y: 0, hidden: true)
        let wall = zoneBrick(on: scene, y: 300, hidden: false)
        wall.texture = scene.brickIndestructible1Texture
        // A wall in view, not a brick: since round 210 anything the player could actually go
        // and hit calls the flash off, because then the field does not look broken

        scene.invisibleBrickFlash()
        XCTAssertFalse(lurker.isHidden)
    }

    /// And the lurker is the *only* thing the flash shows (James, round 210: "only the brick
    /// in the bottom row should flash in this instance"). A hidden brick further up is not
    /// what is holding the field, so showing it hands away information for nothing.
    func testOnlyTheBottomRowBrickFlashes() {
        let scene = zoneScene()
        let lurker = zoneBrick(on: scene, y: 0, hidden: true)
        let higherUp = zoneBrick(on: scene, y: 300, hidden: true)

        scene.invisibleBrickFlash()
        XCTAssertFalse(lurker.isHidden, "the one holding the field up is shown")
        XCTAssertTrue(higherUp.isHidden, "the one further up is not the answer")
    }

    func testOverlappingFlashesStillPutEveryBrickBack() {
        // A second flash replaces the first's pending action under its key, so the bricks the
        // first revealed must not be stranded visible - the list lives on the scene, not in
        // the action
        let scene = zoneScene()
        let first = zoneBrick(on: scene, y: 0, hidden: true)
        scene.invisibleBrickFlash()
        let second = zoneBrick(on: scene, y: 0, hidden: true)
        scene.invisibleBrickFlash()

        scene.invisibleBrickFlashOff()
        XCTAssertTrue(first.isHidden)
        XCTAssertTrue(second.isHidden)
    }

    private func flasher(solidFor: TimeInterval = 2, passableFor: TimeInterval = 2)
    -> EndlessIIFlasher {
        EndlessIIFlasher(brick: SKSpriteNode(), solidFor: solidFor,
                         passableFor: passableFor, phase: 0)
    }

    // MARK: - Breathing

    // Play-test round 126: "New brick type: it continually shrinks and expands."

    private func breather(period: TimeInterval = 3) -> EndlessIIBreather {
        EndlessIIBreather(brick: SKSpriteNode(),
                          full: CGSize(width: 40, height: 20),
                          period: period, phase: 0, bodyScale: 1)
    }

    private func range(of brick: EndlessIIBreather) -> (smallest: CGFloat, largest: CGFloat) {
        var smallest = CGFloat.greatestFiniteMagnitude
        var largest = -CGFloat.greatestFiniteMagnitude
        var moment: TimeInterval = 0
        while moment <= brick.period {
            let scale = brick.scale(at: moment)
            smallest = min(smallest, scale)
            largest = max(largest, scale)
            moment += brick.period/200
        }
        return (smallest, largest)
    }

    /// James, round 175: "breathing bricks can go from one size class to any other size class
    /// including down to nothing."
    func testItBreathesDownToNothing() {
        let measured = range(of: breather())
        XCTAssertEqual(measured.smallest, 0, accuracy: 0.01,
                       "the bottom of the breath is the brick not being there")
        XCTAssertEqual(EndlessIIBreather.smallest, 0)
    }

    func testAHemmedInBrickStillOnlyFillsItsOwnCell() {
        // Which is what every breathing brick did before round 175, so a crowded field looks
        // exactly as it did
        let measured = range(of: breather())
        XCTAssertEqual(measured.largest, 1, accuracy: 0.01,
                       "the room beyond belongs to its neighbours, and nothing reserves it")
    }

    func testABrickWithRoomBreathesUpThroughTheSizeClasses() {
        var roomy = breather()
        roomy.ceiling = 2
        let measured = range(of: roomy)
        XCTAssertEqual(measured.largest, 2, accuracy: 0.01)
        XCTAssertEqual(measured.smallest, 0, accuracy: 0.01,
                       "both ends, so one brick covers every class between nothing and Big")
    }

    func testItNeverBreathesPastABigBrick() {
        XCTAssertEqual(EndlessIIBreather.largest, 2,
                       "a Big brick is the largest thing the field has a name for")
    }

    func testTheCycleReturnsToWhereItStarted() {
        // Or a brick left to breathe for an hour would have drifted somewhere of its own
        let brick = breather()
        XCTAssertEqual(brick.scale(at: 0), brick.scale(at: brick.period), accuracy: 0.001)
    }

    func testItPausesAtEachEndRatherThanPumping() {
        // A cosine, not a triangle: the change is slowest where the brick is biggest and
        // smallest, which is what makes it read as breathing
        let brick = breather()
        let atEnd = abs(brick.scale(at: brick.period/2)
                        - brick.scale(at: brick.period/2 + brick.period/40))
        let atMiddle = abs(brick.scale(at: brick.period/4)
                           - brick.scale(at: brick.period/4 + brick.period/40))
        XCTAssertLessThan(atEnd, atMiddle)
    }

    func testTheStyleIsInAPoolAndSoCanHappenAtAll() {
        // §8.6: being in the enum, the grid, the reference page and the progression is not
        // enough - a style that is in no pool is never offered, and from the outside that
        // looks exactly like being very rare
        let scene = GameScene()
        scene.gameMode = .endlessII
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: 40, height: 20)
        scene.addChild(brick)

        scene.applyEndlessIIStyle(.breathing, to: brick)
        XCTAssertTrue(scene.endlessIIStyles(on: brick).contains(.breathing),
                      "the scene can build one, and knows it has")
    }

    func testABreathingBrickIsNotPlainAndSoTakesNoSecondRole() {
        let scene = GameScene()
        scene.gameMode = .endlessII
        let brick = SKSpriteNode(texture: scene.brickNormalTexture)
        brick.size = CGSize(width: 40, height: 20)
        scene.addChild(brick)
        scene.applyEndlessIIStyle(.breathing, to: brick)

        XCTAssertFalse(scene.endlessIIIsPlain(brick))
    }

    func testSolidExactlyWhileFullyOpaque() {
        // Both directions, so neither kind of lie is possible: a brick is never solid while
        // it is fading, and never fading while it is solid. It starts fading the instant it
        // stops being solid.
        let brick = flasher()

        var phase: TimeInterval = 0
        while phase < brick.cycle {
            let state = brick.state(at: phase)
            if state.solid {
                XCTAssertEqual(state.alpha, 1, "solid at \(phase) but not fully opaque")
            } else {
                XCTAssertLessThan(state.alpha, 1, "fully opaque at \(phase) but not solid")
            }
            phase += EndlessIIFlasher.fade/10
        }
    }

    func testItStartsSolidAndOpaque() {
        let state = flasher().state(at: 0)
        XCTAssertTrue(state.solid)
        XCTAssertEqual(state.alpha, 1, accuracy: 0.0001)
    }

    func testItStopsBeingSolidTheInstantItStartsFading() {
        let brick = flasher(solidFor: 2, passableFor: 2)
        XCTAssertTrue(brick.state(at: 1.999).solid)
        XCTAssertFalse(brick.state(at: 2.001).solid)
    }

    func testAHeldBrickDoesNotLookSolid() {
        // The tick only makes a brick solid again by wrapping its phase, and it refuses to
        // wrap while the ball is inside - so a brick can sit at the end of its cycle
        // indefinitely. If the fade had finished by then it would look solid the whole time
        // the ball was passing through it.
        let brick = flasher()
        let state = brick.state(at: brick.cycle - 0.001)
        XCTAssertFalse(state.solid)
        XCTAssertLessThanOrEqual(state.alpha, EndlessIIFlasher.returningAlpha + 0.0001)
    }

    func testAlphaNeverLeavesTheVisibleRange() {
        let brick = flasher(solidFor: 3, passableFor: 1.5)
        var phase: TimeInterval = 0
        while phase <= brick.cycle {
            let alpha = brick.state(at: phase).alpha
            XCTAssertGreaterThanOrEqual(alpha, EndlessIIFlasher.passableAlpha - 0.0001,
                                        "invisible at \(phase)")
            XCTAssertLessThanOrEqual(alpha, 1.0001, "over-bright at \(phase)")
            phase += 0.01
        }
    }

    func testAPassableBrickIsStillVisible() {
        // A brick that vanishes completely is one the player cannot plan around.
        XCTAssertGreaterThan(EndlessIIFlasher.passableAlpha, 0)
    }

    func testTheCycleIsBothHoldsPlusBothFades() {
        let brick = flasher(solidFor: 2.5, passableFor: 1.75)
        XCTAssertEqual(brick.cycle, 2.5 + 1.75 + EndlessIIFlasher.fade*2, accuracy: 0.0001)
    }
}
