//
//  GameScene.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

let PaddleCategoryName = "paddle"
let BallCategoryName = "ball"
let BlockCategoryName = "block"
// Set up for categoryNames

let BallCategory   : UInt32 = 0x1 << 0
let BlockCategory  : UInt32 = 0x1 << 2
let PaddleCategory : UInt32 = 0x1 << 3
// Set up for categoryBitMask

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var paddle = SKSpriteNode()
    var ball = SKSpriteNode()
    var block = SKSpriteNode()
    var blockDouble = SKSpriteNode()
    var blockInvisible = SKSpriteNode()
    var blockNull = SKSpriteNode()
    // Define objects
    
    var livesLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var gameStateLabel = SKLabelNode()
    var blocksLeftLabel = SKLabelNode()
    var highScoreLabel = SKLabelNode()
    // Define labels
    
    var paddleWidth: CGFloat = 0
    var paddleHeight: CGFloat = 0
    var paddleGap: CGFloat = 0
    var ballSize: CGFloat = 0
    var ballStartingPositionY: CGFloat = 0
    var ballLaunchSpeed: Double = 8
    var ballLaunchAngleRad: Double = 0
    var ballLostHeight: CGFloat = 0
    var blockHeight: CGFloat = 0
    var blockWidth: CGFloat = 0
    var numberOfBlockRows: Int = 0
    var numberOfBlockColumns: Int = 0
    var totalBlocksWidth: CGFloat = 0
    var yBlockOffset: CGFloat = 0
    var xBlockOffset: CGFloat = 0
    // Object layout property defintion
    
    var dxBall: Double = 0
    var dyBall: Double = 0
    var speedBall: Double = 0
    var ballIsOnPaddle: Bool = true
    var numberOfLives: Int = 3
    var collisionLocation: Double = 0
    var minAngleDeg: Double = 20
    var maxAngleDeg: Double = 160
    var angleAdjustmentK: Double = 50
    // Effect of paddle position hit on ball angle. Larger number means more effect
    var blocksLeft: Int = 0
    var ballLinearDampening: CGFloat = -0.005
    var ballMaxSpeed: CGFloat = 1000
    // Setup game metrics
    
    var score: Int = 0
    var highscore: Int = 0
    var lifeLostScore: Int = -100
    var blockHitScore: Int = 5
    var blockDestroyScore: Int = 10
    var levelCompleteScore: Int = 100
    // Score for completing the level quickly
    // Score for power-ups
    // Setup score properties
    
    let blockTexture: SKTexture = SKTexture(imageNamed: "Block")
    let blockDouble1Texture: SKTexture = SKTexture(imageNamed: "BlockDouble1")
    let blockDouble2Texture: SKTexture = SKTexture(imageNamed: "BlockDouble2")
    let blockDouble3Texture: SKTexture = SKTexture(imageNamed: "BlockDouble3")
    let blockInvisibleTexture: SKTexture = SKTexture(imageNamed: "BlockInvisible")
    let blockNullTexture: SKTexture = SKTexture(imageNamed: "BlockNull")
    let blockIndestructibleTexture: SKTexture = SKTexture(imageNamed: "BlockIndestructible")
    // Block textures
    
    var touchBeganWhilstPlaying: Bool = false
    var paddleMoved: Bool = false
    var paddleMovedDistance: CGFloat = 0
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        PreGame(scene: self),
        Playing(scene: self),
        BallOnPaddle(scene: self),
        GameOver(scene: self)])
    // Sets up the game states
    
    let dataStore = UserDefaults.standard
    // Setup NSUserDefaults data store
    
    var scoreArray: [Int] = [1]
    
    override func didMove(to view: SKView) {
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        paddle = self.childNode(withName: "paddle") as! SKSpriteNode
        livesLabel = self.childNode(withName: "livesLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        gameStateLabel = self.childNode(withName: "gameStateLabel") as! SKLabelNode
        blocksLeftLabel = self.childNode(withName: "blocksLeftLabel") as! SKLabelNode
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        // Links objects to sprites
        
        paddleWidth = (self.frame.width/4)
        paddleHeight = paddleWidth/7.5
        paddleGap = paddleHeight*10
        ballSize = paddleHeight
        paddle.size.width = paddleWidth
        paddle.size.height = paddleHeight
        ball.size.width = ballSize
        ball.size.height = ballSize
        ballLostHeight = paddleHeight*8
        blockHeight = paddleHeight
        blockWidth = blockHeight*3
        // Object layout property initialisation and setting
        
        paddle.position.x = 0
        paddle.position.y = (-self.frame.height/2 + paddleGap)
        ball.position.x = 0
        ballStartingPositionY = paddle.position.y + paddleHeight/2 + ballSize/2
        ball.position.y = ballStartingPositionY
        livesLabel.position.y = self.frame.height/2 - 20
        livesLabel.position.x = self.frame.width/2 - 20
        scoreLabel.position.y = self.frame.height/2 - 20
        scoreLabel.position.x = -self.frame.width/2 + 20
        gameStateLabel.position.y = self.frame.height/2 - 20
        gameStateLabel.position.x = 0
        blocksLeftLabel.position.y = livesLabel.position.y - 40
        blocksLeftLabel.position.x = livesLabel.position.x
        highScoreLabel.position.y = scoreLabel.position.y - 40
        highScoreLabel.position.x = scoreLabel.position.x
        // Object position definition
        
        numberOfBlockRows = 9
        numberOfBlockColumns = 7
        totalBlocksWidth = blockWidth * CGFloat(numberOfBlockColumns)
        xBlockOffset = totalBlocksWidth/2
        // Define blocks
        
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody!.allowsRotation = false
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.physicsBody!.isDynamic = false
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        paddle.zPosition = 0
        // Define paddle properties
        
        ball.physicsBody!.allowsRotation = false
        ball.physicsBody!.friction = 0.0
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody!.isDynamic = true
        ball.name = BallCategoryName
        ball.physicsBody!.categoryBitMask = BallCategory
        ball.physicsBody?.linearDamping = ballLinearDampening
        ball.physicsBody?.angularDamping = 0
        ball.zPosition = 1
        // Define ball properties
        
        physicsWorld.contactDelegate = self
        // Sets the GameScene as the delegate in the physicsWorld
        
        ball.physicsBody!.categoryBitMask = BallCategory
        paddle.physicsBody!.categoryBitMask = PaddleCategory
        // Assigns the constants to the corresponding physics body’s categoryBitMask
        
        ball.physicsBody!.contactTestBitMask = PaddleCategory | BlockCategory
        // Sets up the contactTestBitMask for the blocks, ball and paddle
        
        ball.isHidden = true
        paddle.isHidden = true
        // Hide ball and paddle
        
        let xRangePaddle = SKRange(lowerLimit:-self.frame.width/2 + paddleWidth/2,upperLimit:self.frame.width/2 - paddleWidth/2)
        paddle.constraints = [SKConstraint.positionX(xRangePaddle)]
        // Define paddle position limitations
        
        let xRangeBall = SKRange(lowerLimit:-self.frame.width/2 + ballSize/2,upperLimit:self.frame.width/2 - ballSize/2)
        ball.constraints = [SKConstraint.positionX(xRangeBall)]
        // Stops the ball leaving the screen
        
        let boarder = SKPhysicsBody(edgeLoopFrom: self.frame)
        boarder.friction = 0
        boarder.restitution = 1
        self.physicsBody = boarder
        // Sets up the boarder to interact with the objects
        
        if let scoreStore = dataStore.array(forKey: "ScoreStore") as? [Int] {
            scoreArray = scoreStore
            // Setup array to store all scores
            // Change to saving to 10 scores
        }
        
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        
        gameState.enter(PreGame.self)
        // Tell the state machine to enter the waiting for tap state
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Defines actions for a dragged touch
        
        if gameState.currentState is Playing {
            // Only executes code below when game state is playing
        
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let previousLocation = touch!.previousLocation(in: self)
            // Define the current touch position and previous touch position
            
            var paddleX = CGFloat(0)
            // Define the property to store the x position of the paddle
            
            paddleMovedDistance = touchLocation.x - previousLocation.x
            
            paddleX = paddle.position.x + paddleMovedDistance
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
            // Sets the paddle to match the touch's x position
            
            if ballIsOnPaddle {
                if paddleMovedDistance != 0 {
                    paddleMoved = true
                }
                // Checks if the paddle has moved
                ball.position = CGPoint(x: paddleX, y: ballStartingPositionY)
                // Sets the ball to follow the paddle's position
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState.currentState {
        case is PreGame:
            gameState.enter(Playing.self)
        case is Playing:
            touchBeganWhilstPlaying = true
            paddleMoved = false
        case is GameOver:
            gameState.enter(PreGame.self)
        default:
            break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if speedBall == 0 && ballIsOnPaddle && touchBeganWhilstPlaying && paddleMoved == false && gameState.currentState is Playing {
            releaseBall()
        }
        touchBeganWhilstPlaying = false
        // Release the ball from the paddle only if the paddle has not been moved
    }
    
    func releaseBall() {
        
        if ball.hasActions() {
            ball.removeAllActions()
            // Stop animation actions on ball
            let fadeIn = SKAction.fadeIn(withDuration: 0)
            let scaleUp = SKAction.scale(to: 1, duration: 0)
            let resetGroup = SKAction.group([fadeIn, scaleUp])
            ball.run(resetGroup, completion: {
                self.ball.isHidden = false
            })
            // Reset ball on paddle immediately
        }
        
        dxBall = Double(ball.physicsBody!.velocity.dx)
        dyBall = Double(ball.physicsBody!.velocity.dy)
        speedBall = sqrt(dxBall*dxBall + dyBall*dyBall)
        ballLaunchAngleRad = Double.random(in: 30...150) * Double.pi / 180
        let dxLaunch = cos(ballLaunchAngleRad) * ballLaunchSpeed
        let dyLaunch = sin(ballLaunchAngleRad) * ballLaunchSpeed
        // Defines ball release metrics
        
        ball.physicsBody?.applyImpulse(CGVector(dx: dxLaunch, dy: dyLaunch))
        // Launches ball
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        ballIsOnPaddle = false
        // Resets ball on paddle status
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if gameState.currentState is Playing {
            if ball.position.y <= paddle.position.y - ballSize*2 {
                ballLostAnimation()
            }
            
            if ball.position.y <= paddle.position.y - ballLostHeight {
                ballLost()
            }
        }
        
        if gameState.currentState is Playing && ballIsOnPaddle == false {
            let xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
            let ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
            let speed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
            
            let randomKick = Double.random(in: (-2)...2)
            
            if xSpeed <= 25.0 {
                ball.physicsBody!.applyImpulse(CGVector(dx: randomKick, dy: 0.0))
            }
            if ySpeed <= 25.0 {
                ball.physicsBody!.applyImpulse(CGVector(dx: 0.0, dy: randomKick))
            }
            
            if speed > ballMaxSpeed {
                ball.physicsBody!.linearDamping = 0.1
            } else {
                ball.physicsBody!.linearDamping = ballLinearDampening
            }
            if speed < CGFloat(ballLaunchSpeed) {
                ball.physicsBody!.linearDamping = -0.1
            } else {
                ball.physicsBody!.linearDamping = ballLinearDampening
            }
        }
    }
    
    func ballLost() {
        self.ball.isHidden = true
        ball.position.x = paddle.position.x
        ball.position.y = ballStartingPositionY
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballIsOnPaddle = true
        paddleMoved = true
        // Reset ball position
        
        score = score + lifeLostScore
        scoreLabel.text = String(score)
        // Update score
        
        if numberOfLives == 0 {
            gameState.enter(GameOver.self)
            return
        }
        if numberOfLives > 0 {
            numberOfLives -= 1
            livesLabel.text = String(numberOfLives)
            // Update number of lives
            
            let fadeOut = SKAction.fadeIn(withDuration: 0)
            let scaleDown = SKAction.scale(to: 0, duration: 0)
            let waitTime = SKAction.wait(forDuration: 0.5)
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let scaleUp = SKAction.scale(to: 1, duration: 0.1)
            let resetGroup = SKAction.group([fadeOut, scaleDown, waitTime])
            let ballGroup = SKAction.group([fadeIn, scaleUp])
            ball.run(resetGroup, completion: {
                self.ball.isHidden = false
                self.ball.run(ballGroup)
            })
            // Animate ball back onto paddle
        }
    }
    
    func ballLostAnimation() {
        let scaleDown = SKAction.scale(to: 0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let ballLostGroup = SKAction.group([scaleDown, fadeOut])
        ball.run(ballLostGroup)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameState.currentState is Playing {
            // Only executes code below when game state is playing
        
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            // Local variables to hold the two physics bodies involved in a collision.
            
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            } else {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
            // Check the two bodies that collided to see which has the lower categoryBitmask. You then store them into the local variables, so that the body with the lower category is always stored in firstBody. This will save you quite some effort when reacting to contacts between specific categories.
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                hitBlock(node: secondBody.node!, sprite: secondBody.node! as! SKSpriteNode)
                
//                if isGameWon() {
//                    gameState.enter(GameOver.self)
//                }
//                // If there are no bricks left, the game state is changed to game over
            }
            
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == PaddleCategory {
                paddleHit()
            }
        }
    }
    
    func hitBlock(node: SKNode, sprite: SKSpriteNode) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        switch sprite.texture {
        case blockTexture:
            removeBlock(node: node)
            break
        case blockDouble1Texture:
            sprite.texture = blockDouble2Texture
            score = score + blockHitScore
            break
        case blockDouble2Texture:
            sprite.texture = blockDouble3Texture
            score = score + blockHitScore
            break
        case blockDouble3Texture:
            removeBlock(node: node)
            break
        case blockInvisibleTexture:
            if sprite.isHidden {
                
                let scaleDown = SKAction.scale(to: 0, duration: 0)
                let fadeOut = SKAction.fadeOut(withDuration: 0)
                let resetGroup = SKAction.group([scaleDown, fadeOut])
                let scaleUp = SKAction.scale(to: 1, duration: 0.1)
                let fadeIn = SKAction.fadeIn(withDuration: 0.1)
                let blockHitGroup = SKAction.group([scaleUp, fadeIn])
                sprite.run(resetGroup, completion: {
                    sprite.isHidden = false
                    sprite.run(blockHitGroup)
                })
                // Animate block in

                score = score + blockHitScore
                break
            }
            removeBlock(node: node)
            break
        default:
            break
        }
        scoreLabel.text = String(score)
        // Update score
    }
    // This method takes an SKNode. First, it creates an instance of SKEmitterNode from the BrokenPlatform.sks file, then sets it's position to the same position as the node. The emitter node's zPosition is set to 3, so that the particles appear above the remaining blocks. After the particles are added to the scene, the node (bamboo block) is removed.
    
    func removeBlock(node: SKNode) {
        let scaleDown = SKAction.scale(to: 0, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let blockGroup = SKAction.group([scaleDown, fadeOut])
        node.run(blockGroup, completion: {
            node.removeFromParent()
        })
            //With the remove from node running after the animation completes it is possible if the next block is hit vert quickly after the first block will never run the remove node code.
        // Animate and remove block
        
        blocksLeft -= 1
        blocksLeftLabel.text = String(blocksLeft)
        score = score + blockDestroyScore
        // Update number of blocks left and current score
        
        if blocksLeft == 0 {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            generator.impactOccurred()
            // Haptic feedback
            gameState.enter(GameOver.self)
        }
        // Ends the game if all blocks have been removed
    }
    
    func paddleHit() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        let collisionPercentage = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
        // Define collision position between the ball and paddle
        
        if collisionPercentage < 1 && collisionPercentage > -1 && ball.position.y > paddle.position.y {
        // Do not effect angle of ball if it hits near edge of paddle or is below the paddle
            
            var dx = Double(ball.physicsBody!.velocity.dx)
            var dy = Double(ball.physicsBody!.velocity.dy)
            let speed = sqrt(dx*dx + dy*dy)
            var angleRad = atan2(dy, dx)
            // Variables to hold the angle and speed of the ball
            
            angleRad = angleRad - ((angleAdjustmentK * Double.pi / 180) * collisionPercentage)
            // Angle adjustment formula
            
            if angleRad > 0 {
                angleRad = angleRad + Double.random(in: (-angleRad/10)...angleRad/10)
            } else {
                angleRad = angleRad + Double.random(in: angleRad/10...(-angleRad/10))
            }
            // Adds a small element of randomness into the ball's angle
            
            if angleRad < (minAngleDeg * Double.pi / 180) {
                angleRad = (minAngleDeg * Double.pi / 180)
            }
            if angleRad > (maxAngleDeg * Double.pi / 180) {
                angleRad = (maxAngleDeg * Double.pi / 180)
            }
            if angleRad >= (90 * Double.pi / 180) && angleRad <= (91 * Double.pi / 180) {
                angleRad = (91 * Double.pi / 180)
            }
            if angleRad < (90 * Double.pi / 180) && angleRad >= (89 * Double.pi / 180) {
                angleRad = (89 * Double.pi / 180)
            }
            // Changes the angle of the ball based on where it hits the paddle
            
            dx = cos(angleRad) * speed
            dy = sin(angleRad) * speed
            ball.physicsBody!.velocity.dx = CGFloat(dx)
            ball.physicsBody!.velocity.dy = CGFloat(dy)
            // Set the new speed and angle of the ball
        }
    }
    
/* To Do:
     > add gradiant mask on top of ball under paddle to make ball fade away as it drops below the paddle
     > extra life is 1000+ points is achieved on a level
     > control angle after hitting blocks - vertical and horziontal limits
     > prevent ball hitting underside of paddle
     > High score leaderboard with initials
     > Random ball starting direction
     > Random power-up drop
     > Lasers!
     > Lives represented by balls in top right
     > Set ball density
     > stagger brick build in brick by brick
     > First game high score doesn't exist or show up -
     > Size labels based on screen size
     > Setting to turn off haptics
     > App icon
     > Launchscreen
     > Increase minimum angle
     > Track top 10 highscores for each level/board
     > Highscore per level and overall highscore
     
     Today:
     > Pause button
     > New high score message
     > Reset high score to zero
 */
    
}
