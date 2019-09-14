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
let PowerUpCategoryName = "powerUp"
// Set up for categoryNames

enum CollisionTypes: UInt32 {
    case ballCategory = 1
    case blockCategory = 2
    case paddleCategory = 4
    case powerUpCategory = 8
}
// Setup for collisionBitMask

//The categoryBitMask property is a number defining the type of object this is for considering collisions.
//The collisionBitMask property is a number defining what categories of object this node should collide with.
//The contactTestBitMask property is a number defining which collisions we want to be notified about.

//If you give a node a collision bitmask but not a contact test bitmask, it means they will bounce off each other but you won't be notified.
//If you give a node contact test but not collision bitmask it means they won't bounce off each other but you will be told when they overlap.

protocol GameViewControllerDelegate: class {
    func moveToMainMenu()
    func showEndLevelStats(levelNumber: Int, levelScore: Int, levelTime: Double, cumulativeScore: Int, cumulativeTime: Double, levelHighscore: Int, levelBestTime: Double, bestScoreToLevel: Int, bestTimeToLevel: Double, cumulativeHighscore: Int, gameoverStatus: Bool)
}
// Setup the protocol to return to the main menu from GameViewController

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
    var levelNumberLabel = SKLabelNode()
    // Define labels
    
    var pausedButton = SKSpriteNode()
    var pauseButtonSize: CGFloat = 0
    // Define buttons

    var paddleWidth: CGFloat = 0
    var paddleHeight: CGFloat = 0
    var paddleGap: CGFloat = 0
    var ballSize: CGFloat = 0
    var ballStartingPositionY: CGFloat = 0
    var ballLaunchSpeed: Double = 0
    var ballLaunchAngleRad: Double = 0
    var ballLostHeight: CGFloat = 0
    var blockHeight: CGFloat = 0
    var blockWidth: CGFloat = 0
    var numberOfBlockRows: Int = 0
    var numberOfBlockColumns: Int = 0
    var totalBlocksWidth: CGFloat = 0
    var yBlockOffset: CGFloat = 0
    var xBlockOffset: CGFloat = 0
    var powerUpSize: CGFloat = 0
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
    var ballLinearDampening: CGFloat = 0
    var ballMaxSpeed: CGFloat = 0
    var ballMinSpeed: CGFloat = 0
    var reducedBallSpeed: CGFloat = 0
    var increasedBallSpeed: CGFloat = 0
    var xSpeed: CGFloat = 0
    var ySpeed: CGFloat = 0
    var currentSpeed: CGFloat = 0
    // Setup game metrics
    
//    var score: Int = 0
    var highscore: Int = 0
    var lifeLostScore: Int = -100
    var blockHitScore: Int = 5
    var blockDestroyScore: Int = 10
    var levelCompleteScore: Int = 100
    var bestCumulativeTime: Double = 0
    var powerUpScore: Int = 0
    var levelNumber: Int = 0
    // Setup score properties
    
    var timeBonusPoints: Int = 0
    var level1TimeBonus: Int = 0
    var level2TimeBonus: Int = 0
    // Level time bonuses
    
    var cumulativeScore: Int = 0
    var levelScore: Int = 0
    // Level score properties
    
    let blockTexture: SKTexture = SKTexture(imageNamed: "Block")
    let blockDouble1Texture: SKTexture = SKTexture(imageNamed: "BlockDouble1")
    let blockDouble2Texture: SKTexture = SKTexture(imageNamed: "BlockDouble2")
    let blockDouble3Texture: SKTexture = SKTexture(imageNamed: "BlockDouble3")
    let blockInvisibleTexture: SKTexture = SKTexture(imageNamed: "BlockInvisible")
    let blockNullTexture: SKTexture = SKTexture(imageNamed: "BlockNull")
    let blockIndestructibleTexture: SKTexture = SKTexture(imageNamed: "BlockIndestructible")
    // Block textures
    
    let powerUp00Texture: SKTexture = SKTexture(imageNamed: "PowerUp00")
    let powerUp01Texture: SKTexture = SKTexture(imageNamed: "PowerUp01")
    let powerUp02Texture: SKTexture = SKTexture(imageNamed: "PowerUp02")
    let powerUp03Texture: SKTexture = SKTexture(imageNamed: "PowerUp03")
    let powerUp04Texture: SKTexture = SKTexture(imageNamed: "PowerUp04")
    let powerUp05Texture: SKTexture = SKTexture(imageNamed: "PowerUp05")
    let powerUp06Texture: SKTexture = SKTexture(imageNamed: "PowerUp06")
    let powerUp07Texture: SKTexture = SKTexture(imageNamed: "PowerUp07")
    let powerUp08Texture: SKTexture = SKTexture(imageNamed: "PowerUp08")
    let powerUp09Texture: SKTexture = SKTexture(imageNamed: "PowerUp09")
    let powerUp90Texture: SKTexture = SKTexture(imageNamed: "PowerUp90")
    let powerUp91Texture: SKTexture = SKTexture(imageNamed: "PowerUp91")
    let powerUp92Texture: SKTexture = SKTexture(imageNamed: "PowerUp92")
    let powerUp93Texture: SKTexture = SKTexture(imageNamed: "PowerUp93")
    let powerUp94Texture: SKTexture = SKTexture(imageNamed: "PowerUp94")
    let powerUp95Texture: SKTexture = SKTexture(imageNamed: "PowerUp95")
    let powerUp96Texture: SKTexture = SKTexture(imageNamed: "PowerUp96")
    let powerUp97Texture: SKTexture = SKTexture(imageNamed: "PowerUp97")
    let powerUp98Texture: SKTexture = SKTexture(imageNamed: "PowerUp98")
    let powerUp99Texture: SKTexture = SKTexture(imageNamed: "PowerUp99")
    // Power up textures
    
    var stickyPaddleCatches: Int = 0
    // Power up properties
    
    var contactCount: Int = 0
    var ballPositionOnPaddle: Double = 0
    
    let playTexture: SKTexture = SKTexture(imageNamed: "PlayButton")
    let pauseTexture: SKTexture = SKTexture(imageNamed: "PauseButton")
    // Play/pause button textures
    
    var touchBeganWhilstPlaying: Bool = false
    var paddleMoved: Bool = false
    var paddleMovedDistance: CGFloat = 0
    var gameoverStatus: Bool = false
    var endLevelNumber: Int = 0
    // Game trackers
    
    var fontSize: CGFloat = 0
    var labelSpacing: CGFloat = 0
    // Label metrics
    
    var cumulativeTimerValue: Double = 0
    var levelTime: Double = 0
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        PreGame(scene: self),
        Playing(scene: self),
        InbetweenLevels(scene: self),
        GameOver(scene: self),
        Paused(scene: self)])
    // Sets up the game states
    
    weak var gameViewControllerDelegate:GameViewControllerDelegate?
    // Create the delegate property for the GameViewController
    
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
        pausedButton = self.childNode(withName: "pauseButton") as! SKSpriteNode
        life = self.childNode(withName: "life") as! SKSpriteNode
        // Links objects to nodes
        
        livesLabel = self.childNode(withName: "livesLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
        gameStateLabel = self.childNode(withName: "gameStateLabel") as! SKLabelNode
        blocksLeftLabel = self.childNode(withName: "blocksLeftLabel") as! SKLabelNode
        highScoreLabel = self.childNode(withName: "highScoreLabel") as! SKLabelNode
        timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode
        bestTimeLabel = self.childNode(withName: "bestTimeLabel") as! SKLabelNode
        levelNumberLabel = self.childNode(withName: "levelNumberLabel") as! SKLabelNode
        // Links objects to labels
        
        paddleWidth = (self.frame.width/4)
        paddleHeight = paddleWidth/7.5
        paddleGap = paddleHeight*10
        ballSize = paddleHeight
        paddle.size.width = paddleWidth
        paddle.size.height = paddleHeight
        ball.size.width = ballSize
        ball.size.height = ballSize
        ballLostHeight = paddleHeight*8
        blockHeight = paddleHeight*1.2
        blockWidth = paddleHeight*3
        life.size.width = ballSize
        life.size.height = ballSize
        // Object layout property initialisation and setting
        
        ballMaxSpeed = 750
        ballMinSpeed = 200
        ballLinearDampening = -0.005
        
        pauseButtonSize = blockWidth*0.75
        pausedButton.size.width = pauseButtonSize
        pausedButton.size.height = pauseButtonSize
        pausedButton.texture = pauseTexture
        
        fontSize = 16
        labelSpacing = fontSize/1.5
        
        paddle.position.x = 0
        paddle.position.y = (-self.frame.height/2 + paddleGap)
        ball.position.x = 0
        ballStartingPositionY = paddle.position.y + paddleHeight/2 //+ ballSize/2
        ball.position.y = ballStartingPositionY
        pausedButton.position.y = self.frame.height/2 - labelSpacing - pauseButtonSize/2
        pausedButton.position.x = 0
        pausedButton.isUserInteractionEnabled = false
        life.position.y = -self.frame.height/2 + labelSpacing + life.size.height/2
        life.position.x = -self.frame.width/2 + labelSpacing  + life.size.width/2
        // Object position definition
        
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
        timerLabel.position.y = self.frame.height/2 - labelSpacing
        timerLabel.position.x = self.frame.width/2 - labelSpacing
        timerLabel.fontSize = fontSize
        bestTimeLabel.position.y = timerLabel.position.y - labelSpacing*2
        bestTimeLabel.position.x = timerLabel.position.x
        bestTimeLabel.fontSize = fontSize
        levelNumberLabel.position.y = pausedButton.position.y - labelSpacing*2
        levelNumberLabel.position.x = 0
        levelNumberLabel.fontSize = fontSize
        // Label position definition
        
        numberOfBlockRows = 9 // 9
        numberOfBlockColumns = 7 // 7
        totalBlocksWidth = blockWidth * CGFloat(numberOfBlockColumns)
        xBlockOffset = totalBlocksWidth/2
        // Define blocks
        
        definePaddleProperties()
        
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
        
        ballLaunchSpeed = 6
        xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        currentSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        level1TimeBonus = 200
        level2TimeBonus = 2000
        // Definition of level time bonus points
        
        endLevelNumber = 2
        
        ball.isHidden = true
        paddle.isHidden = true
        // Hide ball and paddle
        
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
            // Define the property to store the x position of the paddle and ball
            
            paddleMovedDistance = touchLocation.x - previousLocation.x
            
            ballPositionOnPaddle = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
            // Define the relative position between the ball and paddle
            
            paddleX = paddle.position.x + paddleMovedDistance
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
            // Sets the paddle to match the touch's x position
            
            if ballIsOnPaddle && paddleMovedDistance != 0 {
                if paddle.position.x < (self.frame.width/2 - paddle.size.width/2) && paddle.position.x > (-self.frame.width/2 + paddle.size.width/2) {
                // Check that paddle isn't beyond the boundary of the screen
                    ball.position.x = (CGFloat(ballPositionOnPaddle) * (paddle.size.width/2)) + paddle.position.x
                    ball.position.y = ballStartingPositionY
                    paddleMoved = true
                }
            }
            // Ball matches paddle position
            
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
        case is Playing:
            touchBeganWhilstPlaying = true
            paddleMoved = false
        default:
            break
        }
        
        if gameState.currentState is Playing || gameState.currentState is Paused {
            let touch = touches.first
            let positionInScene = touch!.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            if let name = touchedNode.name {
                if name == "pauseButton" && gameState.currentState is Playing {
                    pauseGame()
                } else if name == "pauseButton" && gameState.currentState is Paused {
                    unpauseGame()
                }
            }
        }
        // Pause the game if the pause button is pressed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if currentSpeed < 1 && ballIsOnPaddle && touchBeganWhilstPlaying && paddleMoved == false && gameState.currentState is Playing {
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
        
        if stickyPaddleCatches != 0 {
            stickyPaddleCatches-=1
        }
        
        let straightLaunchAngleRad = 90 * Double.pi / 180
        let minLaunchAngleRad = 10 * Double.pi / 180
        let maxLaunchAngleRad = 60 * Double.pi / 180
        var launchAngleMultiplier = 1
        
        ballPositionOnPaddle = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
        // Define the relative position between the ball and paddle
        
        if ballPositionOnPaddle < 0 {
            launchAngleMultiplier = -1
        }
        // Determin which angle the ball will launch and modify the multiplier accordingly
        
        if ballPositionOnPaddle > 1 {
            ballPositionOnPaddle = 1
        } else if ballPositionOnPaddle < -1 {
            ballPositionOnPaddle = -1
        }
        // Limit ball position to bounds of paddle
        
        if ballPositionOnPaddle == 0 {
            let randomLaunchDirection = Bool.random()
            if randomLaunchDirection {
                ballLaunchAngleRad = straightLaunchAngleRad + minLaunchAngleRad
            } else {
                ballLaunchAngleRad = straightLaunchAngleRad - minLaunchAngleRad
            }
            // Randomise which direction the ball leaves the paddle if its in the middle
        } else {
            ballLaunchAngleRad = straightLaunchAngleRad - ((maxLaunchAngleRad - minLaunchAngleRad) * ballPositionOnPaddle + (minLaunchAngleRad * Double(launchAngleMultiplier)))
            // Determine the launch angle based on the location of the ball on the paddle
        }
        
        let dxLaunch = cos(ballLaunchAngleRad) * ballLaunchSpeed
        let dyLaunch = sin(ballLaunchAngleRad) * ballLaunchSpeed
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
            self.levelTime += 0.01
            self.timerLabel.text = String(format: "%.2f", self.levelTime)
        })
        let timerSequence = SKAction.sequence([wait,block])
        self.run(SKAction.repeatForever(timerSequence), withKey: "levelTimer")
        pausedButton.texture = pauseTexture
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        xSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx)
        ySpeed = sqrt(ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        currentSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
        
        if gameState.currentState is Playing {
            if ball.position.y <= paddle.position.y - ballSize*2 {
                ballLostAnimation()
            }
            if ball.position.y <= paddle.position.y - ballLostHeight {
                ballLost()
            }
        }
        // Determine if ball has been lost below paddle
        
        if gameState.currentState is Playing && ballIsOnPaddle == false {
            if currentSpeed > ballMaxSpeed {
                ball.physicsBody!.linearDamping = 1
            } else if currentSpeed < ballMinSpeed {
                ball.physicsBody!.linearDamping = -1
            } else {
                ball.physicsBody!.linearDamping = ballLinearDampening
            }
        }
        // Regulate ball's speed
    }
    
    func ballLost() {
        self.ball.isHidden = true
        ball.position.x = paddle.position.x
        ball.position.y = ballStartingPositionY
        ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        ballIsOnPaddle = true
        paddleMoved = true
        // Reset ball position
        
        levelScore = levelScore + lifeLostScore
        scoreLabel.text = String(levelScore)
        // Update score
        
        self.removeAction(forKey: "levelTimer")
        // Stop timer
        
        powerUpsReset()
        
        if numberOfLives == 0 {
            gameoverStatus = true
            gameState.enter(InbetweenLevels.self)
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
        
        if gameState.currentState is Playing && ballIsOnPaddle == false {
            // Only executes code below when game state is playing
            
            contactCount+=1
            
            let ySpeedMin: CGFloat = 100
            let xSpeedMin: CGFloat = 1
            var xDirectionMultiplier: Int = 1
            var yDirectionMultiplier: Int = 1
            
            xSpeed = ball.physicsBody!.velocity.dx
            ySpeed = ball.physicsBody!.velocity.dy
            currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
            
            if xSpeed < 0 {
                xDirectionMultiplier = -1
            }
            if ySpeed < 0 {
                yDirectionMultiplier = -1
            }
            
            if ySpeed < ySpeedMin && ySpeed > 0 {
                ySpeed = ySpeedMin
                xSpeed = sqrt(currentSpeed*currentSpeed + ySpeed*ySpeed)*CGFloat(xDirectionMultiplier)
            } else if ySpeed > -ySpeedMin && ySpeed <= 0 {
                ySpeed = -ySpeedMin
                xSpeed = sqrt(currentSpeed*currentSpeed + ySpeed*ySpeed)*CGFloat(xDirectionMultiplier)
            } else if xSpeed < xSpeedMin && xSpeed > 0 {
                xSpeed = xSpeedMin
                ySpeed = sqrt(currentSpeed*currentSpeed + xSpeed*xSpeed)*CGFloat(yDirectionMultiplier)
            } else if xSpeed > -xSpeedMin && xSpeed <= 0 {
                xSpeed = -xSpeedMin
                ySpeed = sqrt(currentSpeed*currentSpeed + xSpeed*xSpeed)*CGFloat(yDirectionMultiplier)
            }
            // Adjust ball direction whilst preserving speed if angle in x or y is too shallow
            
            ball.physicsBody!.velocity.dx = xSpeed
            ball.physicsBody!.velocity.dy = ySpeed
            
        }
            
        if gameState.currentState is Playing {
        
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
            
            if secondBody.categoryBitMask == CollisionTypes.powerUpCategory.rawValue {
                applyPowerUp(sprite: secondBody.node! as! SKSpriteNode)
                secondBody.node!.removeAllActions()
                secondBody.node!.removeFromParent()
                paddle.position.y = (-self.frame.height/2 + paddleGap)
            }
            // Collect power up if it makes contact with paddle
        }
    }
    
    func hitBlock(node: SKNode, sprite: SKSpriteNode) {
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        switch sprite.texture {
        case blockTexture:
            removeBlock(node: node, sprite: sprite)
            break
        case blockDouble1Texture:
            sprite.texture = blockDouble2Texture
            levelScore = levelScore + blockHitScore
            break
        case blockDouble2Texture:
            sprite.texture = blockDouble3Texture
            levelScore = levelScore + blockHitScore
            break
        case blockDouble3Texture:
            removeBlock(node: node, sprite: sprite)
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

                levelScore = levelScore + blockHitScore
                break
            }
            removeBlock(node: node, sprite: sprite)
            break
        default:
            break
        }
        scoreLabel.text = String(levelScore)
        // Update score
    }
    // This method takes an SKNode. First, it creates an instance of SKEmitterNode from the BrokenPlatform.sks file, then sets it's position to the same position as the node. The emitter node's zPosition is set to 3, so that the particles appear above the remaining blocks. After the particles are added to the scene, the node (bamboo block) is removed.
    
    func removeBlock(node: SKNode, sprite: SKSpriteNode) {
        
        node.removeFromParent()
        // Remove block
        
        let powerUpProb = Int.random(in: 1...2)
        if powerUpProb == 1 {
            powerUpGenerator(sprite: sprite)
        }
        // 1 in 10 probability of getting a power up if block is removed
        
        blocksLeft -= 1
        blocksLeftLabel.text = String(blocksLeft)
        levelScore = levelScore + blockDestroyScore
        scoreLabel.text = String(levelScore)
        // Update number of blocks left and current score
        
        if blocksLeft == 0 {
            if levelNumber == endLevelNumber {
                gameoverStatus = true
            }
            gameState.enter(InbetweenLevels.self)
        }
        // Loads the next level or ends the game if all blocks have been removed
    }
    
    func paddleHit() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        // Haptic feedback
        
        contactCount = 0
        
        if stickyPaddleCatches != 0 {
            ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
// reposition ball within boundries of paddle
            ballIsOnPaddle = true
            paddleMoved = true
            ball.position.y = ballStartingPositionY
            
        } else {
        
            let collisionPercentage = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
            // Define collision position between the ball and paddle
            
            if collisionPercentage < 1 && collisionPercentage > -1 && ball.position.y > paddle.position.y {
            // Do not effect angle of ball if it hits near edge of paddle or is below the paddle
                
    //            var dx = Double(ball.physicsBody!.velocity.dx)
    //            var dy = Double(ball.physicsBody!.velocity.dy)
    //            let speed = sqrt(dx*dx + dy*dy)
                var angleRad = atan2(Double(ySpeed), Double(xSpeed))
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
                
                xSpeed = CGFloat(cos(angleRad)) * currentSpeed
                ySpeed = CGFloat(sin(angleRad)) * currentSpeed
                ball.physicsBody!.velocity.dx = xSpeed
                ball.physicsBody!.velocity.dy = ySpeed
                // Set the new speed and angle of the ball
            }
        }
    }

    func pauseGame() {
        if gameState.currentState is Playing {
            pausedButton.texture = playTexture
            ball.isPaused = true
            paddle.isPaused = true
            enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
                node.isPaused = true
            }
            physicsWorld.speed = 0
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            // Haptic feedback
            removeAction(forKey: "levelTimer")
            pausedButton.texture = playTexture
            // Stop timer
            gameState.enter(Paused.self)
        }
    }
    
    func unpauseGame() {
        if gameState.currentState is Paused {
            pausedButton.texture = pauseTexture
            ball.isPaused = false
            paddle.isPaused = false
            enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
                node.isPaused = false
            }
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
    
    func powerUpGenerator (sprite: SKSpriteNode) {
        
        let powerUp = SKSpriteNode(imageNamed: "PowerUp00")
        
        powerUp.size.width = blockWidth
        powerUp.size.height = powerUp.size.width
        powerUp.position = CGPoint(x: sprite.position.x, y: sprite.position.y)
        
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.frame.size)
        powerUp.physicsBody!.allowsRotation = false
        powerUp.physicsBody!.friction = 0.0
        powerUp.physicsBody!.affectedByGravity = false
        powerUp.physicsBody!.isDynamic = false
        powerUp.name = PowerUpCategoryName
        powerUp.physicsBody!.categoryBitMask = CollisionTypes.powerUpCategory.rawValue
        powerUp.zPosition = 1
        addChild(powerUp)
        
        let powerUpProb = Int.random(in: 9...9)
        switch powerUpProb {
        case 0:
            powerUp.texture = powerUp00Texture
        case 1:
            powerUp.texture = powerUp01Texture
        case 2:
            powerUp.texture = powerUp02Texture
        case 3:
            powerUp.texture = powerUp03Texture
        case 4:
            powerUp.texture = powerUp04Texture
        case 5:
            powerUp.texture = powerUp05Texture
        case 6:
            powerUp.texture = powerUp90Texture
        case 7:
            powerUp.texture = powerUp91Texture
        case 8:
            powerUp.texture = powerUp92Texture
        case 9:
            powerUp.texture = powerUp93Texture
//        case 10:
//            powerUp.texture = powerUp90Texture
//        case 11:
//            powerUp.texture = powerUp91Texture
//        case 12:
//            powerUp.texture = powerUp92Texture
//        case 13:
//            powerUp.texture = powerUp93Texture
//        case 14:
//            powerUp.texture = powerUp94Texture
//        case 15:
//            powerUp.texture = powerUp95Texture
//        case 16:
//            powerUp.texture = powerUp96Texture
//        case 17:
//            powerUp.texture = powerUp97Texture
//        case 18:
//            powerUp.texture = powerUp98Texture
//        case 19:
//            powerUp.texture = powerUp99Texture
        default:
            break
        }
        
        let move = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 5)
        powerUp.run(move, completion: {
            powerUp.removeFromParent()
        })
    }
    
    func applyPowerUp (sprite: SKSpriteNode) {
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        // Haptic feedback

        switch sprite.texture {
            
        case powerUp00Texture:
        // Get a life
            numberOfLives+=1
            livesLabel.text = "x\(numberOfLives)"
            powerUpScore = 100
            
        case powerUp90Texture:
        // Lose a life
            ballLostAnimation()
            self.run(SKAction.wait(forDuration: 0.2),completion: {
                self.ballLost()
            })
            powerUpScore = 0
            
        case powerUp01Texture:
        // Reduce ball speed
            if currentSpeed < ballMaxSpeed {
                ball.physicsBody!.velocity.dx = (ball.physicsBody?.velocity.dx)!*0.75
                ball.physicsBody!.velocity.dy = (ball.physicsBody?.velocity.dy)!*0.75
                self.removeAction(forKey: "powerUpWait")
                startPowerUpTimer(duration: 10)
            } else {
                break
            }
            powerUpScore = 50
            // Power up set
// Power up reverted
            
        case powerUp91Texture:
        // Increase ball speed
            if currentSpeed > ballMinSpeed {
                ball.physicsBody!.velocity.dx = (ball.physicsBody?.velocity.dx)!*1.25
                ball.physicsBody!.velocity.dy = (ball.physicsBody?.velocity.dy)!*1.25
                self.removeAction(forKey: "powerUpWait")
                startPowerUpTimer(duration: 10)
            } else {
                break
            }
            powerUpScore = 50
            // Power up set
// Power up reverted
            
        case powerUp02Texture:
        // Superball
            ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
            // Reset no block destruction power up
            ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue
            powerUpScore = 100
            // Power up set
            let powerUp02Timer: Double = 10
            self.run(SKAction.wait(forDuration: powerUp02Timer), completion: {
                self.ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
            })
            // Power up reverted
            
        case powerUp92Texture:
        // No block destruction
            ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
            // Reset superball power up
            ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue
            powerUpScore = -100
            // Power up set
            let powerUp92Timer: Double = 10
            self.run(SKAction.wait(forDuration: powerUp92Timer), completion: {
                self.ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
            })
            // Power up reverted

        case powerUp03Texture:
        // Sticky paddle
            stickyPaddleCatches = stickyPaddleCatches + 5
            powerUpScore = 100
            // Power up set and limit number of catches per power up
            
        case powerUp04Texture:
        // Next level
            powerUpScore = 100
            if levelNumber == endLevelNumber {
                gameoverStatus = true
            }
            gameState.enter(InbetweenLevels.self)
        // Power up set and limit number of catches per power up
            
        case powerUp05Texture:
        // Increase paddle size
            powerUpScore = 50
            if paddle.size.width <= frame.size.width/2 {
                paddle.size.width = paddle.size.width * 1.5
// Animate paddle increasing in size
                definePaddleProperties()
                // Power up set
                let powerUp05Timer: Double = 10
                self.run(SKAction.wait(forDuration: powerUp05Timer), completion: {
                    self.paddle.size.width = self.paddle.size.width * 0.67
// Animate paddle decreasing in size
                    self.definePaddleProperties()
                })
                // Power up reverted
            }
        case powerUp93Texture:
            // Increase paddle size
            powerUpScore = -50
            if paddle.size.width >= frame.size.width/8 {
                paddle.size.width = paddle.size.width * 0.67
// Animate paddle decreasing in size
                definePaddleProperties()
                // Power up set
                let powerUp93Timer: Double = 10
                self.run(SKAction.wait(forDuration: powerUp93Timer), completion: {
                    self.paddle.size.width = self.paddle.size.width * 1.5
// Animate paddle increasing in size
                    self.definePaddleProperties()
                })
                // Power up reverted
            }
            
            
        default:
            break
        }
        // Identify power up and perform action
        
        levelScore = levelScore + powerUpScore
        scoreLabel.text = String(levelScore)
        // Update score
    }
    
    func startPowerUpTimer(duration: Double) {
        let powerUpWait = SKAction.wait(forDuration: duration)
        self.run(powerUpWait, completion: {
            self.powerUpsReset()
        })
    }
    
    
    func powerUpsReset() {
        self.removeAllActions()
        // Stop all timers
        ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
        ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.blockCategory.rawValue
        stickyPaddleCatches = 0
        paddle.size.width = paddleWidth
        definePaddleProperties()
        // reset ball speed
    }
    
/* To Do:
     > extra life is 1000+ points is achieved on a level
     > High score leaderboard with initials
     > Random power-up drop
     > Lasers!
     > Set ball density
     > stagger brick build in brick by brick
     > Setting to turn off haptics
     > Replace the word level with board
 */
    
    func moveToMainMenu() {
        gameViewControllerDelegate?.moveToMainMenu()
    }
    // Function to return to the MainViewController from the GameViewController, run as a delegate from GameViewController
    
    func showEndLevelStats() {
        gameViewControllerDelegate?.showEndLevelStats(levelNumber: levelNumber, levelScore: levelScore, levelTime: levelTime, cumulativeScore: cumulativeScore, cumulativeTime: cumulativeTimerValue, levelHighscore: 5, levelBestTime: 6.0, bestScoreToLevel: 7, bestTimeToLevel: 8.0, cumulativeHighscore: 9, gameoverStatus: gameoverStatus)
    }
    
    func definePaddleProperties() {
        paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
        paddle.physicsBody!.allowsRotation = false
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.physicsBody!.isDynamic = true
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = CollisionTypes.paddleCategory.rawValue
        paddle.physicsBody!.collisionBitMask = CollisionTypes.powerUpCategory.rawValue
        paddle.zPosition = 2
        paddle.physicsBody!.contactTestBitMask = CollisionTypes.powerUpCategory.rawValue
        // Define paddle properties
    }
    
}

extension Notification.Name {
    public static let myNotificationKey = Notification.Name(rawValue: "myNotificationKey")
}
// Setup for notifcation from AppDelegate

//MARK: - Pragma mark
/***************************************************************/


