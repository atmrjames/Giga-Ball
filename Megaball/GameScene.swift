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
let PowerupCategoryName = "powerup"
// Set up for categoryNames

enum CollisionTypes: UInt32 {
    case ballCategory = 1
    case blockCategory = 2
    case paddleCategory = 4
    case powerupCategory = 8
}

//let BallCategory   : UInt32 = 0x1 << 0
//let BlockCategory  : UInt32 = 0x1 << 2
//let PaddleCategory : UInt32 = 0x1 << 3
//let PowerupCategory : UInt32 = 0x1 << 0
// Set up for categoryBitMask

//The categoryBitMask property is a number defining the type of object this is for considering collisions.
//The collisionBitMask property is a number defining what categories of object this node should collide with.
//The contactTestBitMask property is a number defining which collisions we want to be notified about.

//If you give a node a collision bitmask but not a contact test bitmask, it means they will bounce off each other but you won't be notified.
//If you give a node contact test but not collision bitmask it means they won't bounce off each other but you will be told when they overlap.


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var paddle = SKSpriteNode()
    var ball = SKSpriteNode()
    var block = SKSpriteNode()
    var blockDouble = SKSpriteNode()
    var blockInvisible = SKSpriteNode()
    var blockNull = SKSpriteNode()
    var life = SKSpriteNode()
    // Define objects
    
    var livesLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
    var gameStateLabel = SKLabelNode()
    var blocksLeftLabel = SKLabelNode()
    var highScoreLabel = SKLabelNode()
    var timerLabel = SKLabelNode()
    var bestTimeLabel = SKLabelNode()
    // Define labels
    
    var pausedButton = SKSpriteNode()
    var pauseButtonSize: CGFloat = 0
    // Define buttons

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
    var powerupSize: CGFloat = 0
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
    var bestTime: Double = 0
    var powerupScore: Int = 50
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
    
    let powerup1Texture: SKTexture = SKTexture(imageNamed: "Powerup1")
    let powerup2Texture: SKTexture = SKTexture(imageNamed: "Powerup2")
    let powerup3Texture: SKTexture = SKTexture(imageNamed: "Powerup3")
    let powerup4Texture: SKTexture = SKTexture(imageNamed: "Powerup4")
    let powerup5Texture: SKTexture = SKTexture(imageNamed: "Powerup5")
    let powerup6Texture: SKTexture = SKTexture(imageNamed: "Powerup6")
    // Powerup textures
    
    let playTexture: SKTexture = SKTexture(imageNamed: "PlayButton")
    let pauseTexture: SKTexture = SKTexture(imageNamed: "PauseButton")
    // Play/pause button textures
    
    var touchBeganWhilstPlaying: Bool = false
    var paddleMoved: Bool = false
    var paddleMovedDistance: CGFloat = 0
    // Game trackers
    
    var fontSize: CGFloat = 0
    var labelSpacing: CGFloat = 0
    // Label metrics
    
    var timerValue: Double = 0
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        PreGame(scene: self),
        Playing(scene: self),
        BallOnPaddle(scene: self),
        GameOver(scene: self),
        Paused(scene: self)])
    // Sets up the game states
    
    let dataStore = UserDefaults.standard
    // Setup NSUserDefaults data store
    
    var scoreArray: [Int] = [1]
    var timerArray: [Double] = [1]
    // Creates arrays to store highscores and times from NSUserDefauls
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        // Sets the GameScene as the delegate in the physicsWorld
        
        ball = self.childNode(withName: "ball") as! SKSpriteNode
        paddle = self.childNode(withName: "paddle") as! SKSpriteNode
        livesLabel = self.childNode(withName: "livesLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        gameStateLabel = self.childNode(withName: "gameStateLabel") as! SKLabelNode
        blocksLeftLabel = self.childNode(withName: "blocksLeftLabel") as! SKLabelNode
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        pausedButton = self.childNode(withName: "pauseButton") as! SKSpriteNode
        timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode
        bestTimeLabel = self.childNode(withName: "bestTimeLabel") as! SKLabelNode
        life = self.childNode(withName: "life") as! SKSpriteNode
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
        life.size.width = ballSize
        life.size.height = ballSize
        // Object layout property initialisation and setting
        
        pauseButtonSize = blockWidth*0.75
        pausedButton.size.width = pauseButtonSize
        pausedButton.size.height = pauseButtonSize
        pausedButton.texture = pauseTexture
        
        fontSize = 18
        labelSpacing = fontSize/1.5
        
        paddle.position.x = 0
        paddle.position.y = (-self.frame.height/2 + paddleGap)
        ball.position.x = 0
        ballStartingPositionY = paddle.position.y + paddleHeight/2 + ballSize/2
        ball.position.y = ballStartingPositionY
        life.position.y = -self.frame.height/2 + labelSpacing + life.size.height/2
        life.position.x = -self.frame.width/2 + labelSpacing  + life.size.width/2
        livesLabel.position.y = life.position.y
        livesLabel.position.x = life.position.x + labelSpacing
        livesLabel.fontSize = fontSize
        scoreLabel.position.y = self.frame.height/2 - labelSpacing
        scoreLabel.position.x = -self.frame.width/2 + labelSpacing
        scoreLabel.fontSize = fontSize
        gameStateLabel.position.y = self.frame.height/2 - labelSpacing
        gameStateLabel.position.x = -labelSpacing
        gameStateLabel.fontSize = fontSize
        gameStateLabel.isHidden = true
        blocksLeftLabel.position.y = livesLabel.position.y - labelSpacing*2
        blocksLeftLabel.position.x = livesLabel.position.x
        blocksLeftLabel.fontSize = fontSize
        blocksLeftLabel.isHidden = true
        highScoreLabel.position.y = scoreLabel.position.y - labelSpacing*2
        highScoreLabel.position.x = scoreLabel.position.x
        highScoreLabel.fontSize = fontSize
        pausedButton.position.y = self.frame.height/2 - labelSpacing - pauseButtonSize/2
        pausedButton.position.x = 0
        pausedButton.isUserInteractionEnabled = false
        timerLabel.position.y = self.frame.height/2 - labelSpacing
        timerLabel.position.x = self.frame.width/2 - labelSpacing
        timerLabel.fontSize = fontSize
        bestTimeLabel.position.y = timerLabel.position.y - labelSpacing*2
        bestTimeLabel.position.x = timerLabel.position.x
        bestTimeLabel.fontSize = fontSize
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
        paddle.physicsBody!.isDynamic = true
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = CollisionTypes.paddleCategory.rawValue
        paddle.physicsBody!.collisionBitMask = CollisionTypes.powerupCategory.rawValue
        paddle.zPosition = 2
        paddle.physicsBody!.contactTestBitMask = CollisionTypes.powerupCategory.rawValue
        // Define paddle properties
        
        ball.physicsBody!.allowsRotation = false
        ball.physicsBody!.friction = 0.0
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody!.isDynamic = true
        ball.name = BallCategoryName
        ball.physicsBody!.categoryBitMask = CollisionTypes.ballCategory.rawValue
        ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
        ball.physicsBody?.linearDamping = ballLinearDampening
        ball.physicsBody?.angularDamping = 0
        ball.zPosition = 2
        ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
        // Define ball properties
        
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
        }
        // Setup array to store all scores
        if let timerStore = dataStore.array(forKey: "TimerStore") as? [Double] {
            timerArray = timerStore
        }
        // Setup array to store all completed level timers
        
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationReceived(_:)), name: Notification.Name.myNotificationKey, object: nil)
        // Sets up an observer to watch for notifications from AppDelegate to check if the app has quit
        
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
        
        if gameState.currentState is Playing || gameState.currentState is Paused {
            let touch = touches.first
            let positionInScene = touch!.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            if let name = touchedNode.name
            {
                if name == "pauseButton"
                {
                    pauseGame()
                }
            }
        }
        // Pause the game if the pause button is pressed
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
        
        startTimer()
        
        ballIsOnPaddle = false
        // Resets ball on paddle status
    }
    
    func startTimer() {
        let wait = SKAction.wait(forDuration: 0.01) //change countdown speed here
        let block = SKAction.run({
            self.timerValue += 0.01
            self.timerLabel.text = String(format: "%.2f", self.timerValue)
        })
        let timerSequence = SKAction.sequence([wait,block])
        self.run(SKAction.repeatForever(timerSequence), withKey: "levelTimer")
        pausedButton.texture = pauseTexture
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
        
        self.removeAction(forKey: "levelTimer")
        // Stop timer
        
        if numberOfLives == 0 {
            gameState.enter(GameOver.self)
            return
        }
        if numberOfLives > 0 {
            
            let fadeOutLife = SKAction.fadeOut(withDuration: 0.25)
            let scaleDownLife = SKAction.scale(to: 0, duration: 0.25)
            let waitTimeLife = SKAction.wait(forDuration: 0.25)
            let fadeInLife = SKAction.fadeIn(withDuration: 0.25)
            let scaleUpLife = SKAction.scale(to: 1, duration: 0)
            let lifeLostGroup = SKAction.group([fadeOutLife, scaleDownLife, waitTimeLife])
            let wait = SKAction.sequence([waitTimeLife])
            let resetLifeGroup = SKAction.sequence([waitTimeLife, scaleUpLife, fadeInLife])
            // Setup life lost animation
            
            let fadeOutBall = SKAction.fadeOut(withDuration: 0)
            let scaleDownBall = SKAction.scale(to: 0, duration: 0)
            let waitTimeBall = SKAction.wait(forDuration: 0.25)
            let fadeInBall = SKAction.fadeIn(withDuration: 0.25)
            let scaleUpBall = SKAction.scale(to: 1, duration: 0.25)
            let resetBallGroup = SKAction.group([fadeOutBall, scaleDownBall, waitTimeBall])
            let ballGroup = SKAction.group([fadeInBall, scaleUpBall])
            // Setup ball animation
            
            self.life.run(wait, completion: {
                self.life.run(lifeLostGroup, completion: {
                    self.life.run(resetLifeGroup)
                    self.numberOfLives -= 1
                    self.livesLabel.text = "x\(self.numberOfLives)"
                })
            })
            // Update number of lives
            
            ball.run(resetBallGroup, completion: {
                self.ball.isHidden = false
                self.ball.run(ballGroup)
            })
            // Animate ball back onto paddle and loss of a life
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
            
            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.blockCategory.rawValue {
                hitBlock(node: secondBody.node!, sprite: secondBody.node! as! SKSpriteNode)
            }
            // Hit block if it makes contact with ball
            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.paddleCategory.rawValue {
                paddleHit()
            }
            // Hit ball if it makes contact with paddle
            if secondBody.categoryBitMask == CollisionTypes.powerupCategory.rawValue {
                applyPowerup(sprite: secondBody.node! as! SKSpriteNode)
                secondBody.node!.removeAllActions()
                secondBody.node!.removeFromParent()
                paddle.position.y = (-self.frame.height/2 + paddleGap)
            }
            // Collect powerup if it makes contact with paddle
        }
    }
    
    func hitBlock(node: SKNode, sprite: SKSpriteNode) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        let powerupProb = Int.random(in: 1...12)
        
        if powerupProb == 1 {
            powerupGenerator(sprite: sprite)
        }
        
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
        let scaleDown = SKAction.scale(to: 0, duration: 0.05)
        let fadeOut = SKAction.fadeOut(withDuration: 0.05)
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

    func pauseGame() {
        if pausedButton.texture == playTexture {
            pausedButton.texture = pauseTexture
        }
        if gameState.currentState is Playing {
            ball.isPaused = true
            paddle.isPaused = true
            physicsWorld.speed = 0
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Haptic feedback
            removeAction(forKey: "levelTimer")
            pausedButton.texture = playTexture
            // Stop timer
            gameState.enter(Paused.self)
        } else if gameState.currentState is Paused {
            ball.isPaused = false
            paddle.isPaused = false
            physicsWorld.speed = 1
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Haptic feedback
            if ballIsOnPaddle == false {
                startTimer()
            }
            // Restart timer if ball was paused whilst in play
            gameState.enter(Playing.self)
        }
    }
    
    @objc func notificationReceived(_ notification: Notification) {
        pauseGame()
    }
    // Pause the game if a notifcation from AppDelegate is received that the game will quit
    
    func powerupGenerator (sprite: SKSpriteNode) {
        
        let powerup = SKSpriteNode(imageNamed: "Powerup1")
        
        powerup.size.width = blockWidth
        powerup.size.height = powerup.size.width
        powerup.position = CGPoint(x: sprite.position.x, y: sprite.position.y)
        
        powerup.physicsBody = SKPhysicsBody(rectangleOf: powerup.frame.size)
        powerup.physicsBody!.allowsRotation = false
        powerup.physicsBody!.friction = 0.0
        powerup.physicsBody!.affectedByGravity = false
        powerup.physicsBody!.isDynamic = false
        powerup.name = PowerupCategoryName
        powerup.physicsBody!.categoryBitMask = CollisionTypes.powerupCategory.rawValue
        powerup.zPosition = 1
        addChild(powerup)
        
        let powerupProb = Int.random(in: 1...6)
        switch powerupProb {
        case 1:
            powerup.texture = powerup1Texture
        case 2:
            powerup.texture = powerup2Texture
        case 3:
            powerup.texture = powerup3Texture
        case 4:
            powerup.texture = powerup4Texture
        case 5:
            powerup.texture = powerup5Texture
        case 6:
            powerup.texture = powerup6Texture
        default:
            powerup.texture = powerup1Texture
        }
        
        let move = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 5)
        powerup.run(move, completion: {
            powerup.removeFromParent()
        })
    }
    
    func applyPowerup (sprite: SKSpriteNode) {
        
        score = score + powerupScore
        scoreLabel.text = String(score)
        // Update score
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        print("apply powerup")
        print(sprite.texture)
        
//        if paddle.size.width < paddleWidth * 2 {
//            paddle.size.width = paddle.size.width*1.5
//            paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
//            paddle.physicsBody!.allowsRotation = false
//            paddle.physicsBody!.friction = 0.0
//            paddle.physicsBody!.affectedByGravity = false
//            paddle.physicsBody!.isDynamic = true
//            paddle.name = PaddleCategoryName
//            paddle.physicsBody!.categoryBitMask = CollisionTypes.paddleCategory.rawValue
//            paddle.physicsBody!.collisionBitMask = CollisionTypes.powerupCategory.rawValue
//            paddle.zPosition = 2
//            paddle.physicsBody!.contactTestBitMask = CollisionTypes.powerupCategory.rawValue
//            //Redefine paddle properties
//        }
    
//        switch sprite.texture {
//        case blockTexture:
//            removeBlock(node: node)
//            break
        // Apply powerup based on which one was collected
    }
    
/* To Do:
     > extra life is 1000+ points is achieved on a level
     > High score leaderboard with initials
     > Random power-up drop
     > Lasers!
     > Lives represented by balls in top right
     > Set ball density
     > stagger brick build in brick by brick
     > Size labels based on screen size
     > Setting to turn off haptics
     > App icon
     > Launchscreen
     > Track top 10 highscores for each level/board
     > Time per level
     
     Today:
     > New high score message
     > New best time message
     > Superball powerup - turn off ball collision bit mask with blocks
     > No powerups if static block hit - only if block destroyed
     > If ball is lost current falling powerups disappear
     > powerups pause
 */
    
}

extension Notification.Name {
    public static let myNotificationKey = Notification.Name(rawValue: "myNotificationKey")
}
// Setup for notifcation from AppDelegate
