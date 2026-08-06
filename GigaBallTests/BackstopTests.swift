//
//  BackstopTests.swift
//  GigaBallTests
//
//  The Backstop catches a ball that got past the paddle and sends it back up. It could not
//  actually do that: the paddle is solid from below as well as above, so a player who moved
//  the paddle over the rescued ball had it bounced straight back down off the underside and
//  lost the life the Backstop had just saved.
//
//  There was already an attempt at this in the scene - a flag set when the ball hit the
//  backstop and cleared a quarter of a second later. It was never read by anything, so it
//  never did anything, and a window of time was the wrong shape for the problem anyway: what
//  matters is where the ball is, not how long ago it was rescued.
//

import XCTest
import SpriteKit
@testable import Giga_Ball

final class BackstopTests: XCTestCase {

    private func makeScene() -> GameScene {
        let scene = GameScene(size: CGSize(width: 400, height: 800))
        scene.ballSize = 12
        scene.paddleHeight = 12
        scene.paddle.size = CGSize(width: 90, height: 12)
        scene.paddle.position = CGPoint(x: 0, y: -300)
        scene.ball.size = CGSize(width: 12, height: 12)
        scene.ball.physicsBody = SKPhysicsBody(circleOfRadius: 6)
        return scene
    }

    private func paddleBit(_ ball: SKSpriteNode) -> Bool {
        let bit = CollisionTypes.paddleCategory.rawValue
        return (ball.physicsBody?.collisionBitMask ?? 0) & bit != 0
    }

    func testAPaddleAboveTheBallIsNotInTheWay() {
        // The bug, stated. The ball is under the paddle after a Backstop save, and if the
        // paddle is solid from below it goes straight back down
        let scene = makeScene()
        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y - 30)

        XCTAssertTrue(scene.ballIsUnderPaddle(scene.ball))
        scene.refreshPaddleReachability()
        XCTAssertFalse(paddleBit(scene.ball), "the paddle must not be there from below")
    }

    func testTheBallStillLandsOnThePaddleFromAbove() {
        // The fix must not cost the game its only control
        let scene = makeScene()
        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y + 12)

        XCTAssertFalse(scene.ballIsUnderPaddle(scene.ball))
        scene.refreshPaddleReachability()
        XCTAssertTrue(paddleBit(scene.ball))
    }

    func testACatchSitsWellClearOfTheThreshold() {
        // A legitimate catch happens with the ball resting on the paddle's top surface, which
        // is a whole radius above the paddle's centre - so the threshold can never take a real
        // hit away
        let scene = makeScene()
        let resting = scene.paddle.position.y + scene.paddleHeight/2 + scene.ballSize/2
        scene.ball.position = CGPoint(x: 0, y: resting)

        XCTAssertFalse(scene.ballIsUnderPaddle(scene.ball))
        XCTAssertGreaterThan(resting - scene.paddle.position.y, scene.ballSize/2)
    }

    func testThePaddleComesBackAsSoonAsTheBallIsAboveItAgain() {
        // The ball passes up through the paddle and resumes ordinary play. Stated as a
        // condition, so there is no window to expire at the wrong moment
        let scene = makeScene()

        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y - 30)
        scene.refreshPaddleReachability()
        XCTAssertFalse(paddleBit(scene.ball))

        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y + 30)
        scene.refreshPaddleReachability()
        XCTAssertTrue(paddleBit(scene.ball))
    }

    func testMovingThePaddleOverTheBallTakesThePaddleAway() {
        // The exact move that lost the life: the ball is rescued and rising, and the player
        // slides the paddle over the top of it
        let scene = makeScene()
        scene.ball.position = CGPoint(x: 0, y: -280)

        scene.paddle.position.y = -320
        scene.refreshPaddleReachability()
        XCTAssertTrue(paddleBit(scene.ball), "the paddle is below the ball, so it is in play")

        scene.paddle.position.y = -250
        scene.refreshPaddleReachability()
        XCTAssertFalse(paddleBit(scene.ball), "the paddle is now over the ball")
    }

    func testTheContactMaskFollowsTheCollisionMask() {
        // Both, or the ball passes through the paddle and still reports having hit it - which
        // would run the launch angle maths on a ball that never touched anything
        let scene = makeScene()
        let bit = CollisionTypes.paddleCategory.rawValue

        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y - 30)
        scene.refreshPaddleReachability()
        XCTAssertEqual((scene.ball.physicsBody?.contactTestBitMask ?? 0) & bit, 0)

        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y + 30)
        scene.refreshPaddleReachability()
        XCTAssertNotEqual((scene.ball.physicsBody?.contactTestBitMask ?? 0) & bit, 0)
    }

    func testEverythingElseAboutTheBodyIsLeftAlone() {
        // Only the paddle bit moves. Clearing the rest would drop the ball through the bricks
        let scene = makeScene()
        scene.ballPhysicsBodySet()
        let before = scene.ball.physicsBody?.collisionBitMask ?? 0

        scene.ball.position = CGPoint(x: 0, y: scene.paddle.position.y - 30)
        scene.refreshPaddleReachability()
        let after = scene.ball.physicsBody?.collisionBitMask ?? 0

        let paddle = CollisionTypes.paddleCategory.rawValue
        XCTAssertEqual(before & ~paddle, after & ~paddle)
        XCTAssertNotEqual(before & paddle, after & paddle)
    }
}
