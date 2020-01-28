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
let BrickCategoryName = "brick"
let BrickRemovalCategoryName = "brickRemoval"
let PowerUpCategoryName = "powerUp"
let LaserCategoryName = "laser"
let ScreenBlockCategoryName = "screenBlock"
let powerIconCategoryName = "powerUpIcon"
// Set up for categoryNames

enum CollisionTypes: UInt32 {
    case ballCategory = 1
    case brickCategory = 2
    case paddleCategory = 4
	case screenBlockCategory = 8
    case powerUpCategory = 16
    case laserCategory = 32
	case boarderCategory = 64
}
// Setup for collisionBitMask

//The categoryBitMask property is a number defining the type of object this is for considering collisions.
//The collisionBitMask property is a number defining what categories of object this node should collide with.
//The contactTestBitMask property is a number defining which collisions we want to be notified about.

//If you give a node a collision bitmask but not a contact test bitmask, it means they will bounce off each other but you won't be notified.
//If you give a node contact test but not collision bitmask it means they won't bounce off each other but you will be told when they overlap.

protocol GameViewControllerDelegate: class {
	func moveToMainMenu(currentHighscore: Int)
    func showEndLevelStats(levelNumber: Int, levelScore: Int, levelHighscore: Int, totalScore: Int, totalHighscore: Int, gameoverStatus: Bool)
	func showPauseMenu(levelNumber: Int, score: Int, highscore: Int)
	func createInterstitial()
	func loadInterstitial()
	var selectedLevel: Int? { get }
}
// Setup the protocol to return to the main menu from GameViewController

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var paddle = SKSpriteNode()
	var paddleLaser = SKSpriteNode()
	var paddleSticky = SKSpriteNode()
    var ball = SKSpriteNode()
    var brick = SKSpriteNode()
    var brickMultiHit = SKSpriteNode()
    var brickInvisible = SKSpriteNode()
    var brickNull = SKSpriteNode()
    var life = SKSpriteNode()
	var topScreenBlock = SKSpriteNode()
	var sideScreenBlockLeft = SKSpriteNode()
	var sideScreenBlockRight = SKSpriteNode()
	var background = SKSpriteNode()
	var directionMarker = SKSpriteNode()
    // Define objects
    
    var livesLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
	var multiplierLabel = SKLabelNode()
	var unpauseCountdownLabel = SKLabelNode()
	var buildLabel = SKLabelNode()
    // Define labels
    
    var pauseButton = SKSpriteNode()
	var pauseButtonSize: CGFloat = 0
	var pauseButtonTouch = SKSpriteNode()
    // Define buttons
	
	var paddleSizeIcon = SKSpriteNode()
	var ballSpeedIcon = SKSpriteNode()
	var stickyPaddleIcon = SKSpriteNode()
	var gravityIcon = SKSpriteNode()
	var lasersIcon = SKSpriteNode()
	var superballIcon = SKSpriteNode()
	var hiddenBricksIcon = SKSpriteNode()
	// Power-up icons
	
	var paddleSizeIconBar = SKSpriteNode()
	var ballSpeedIconBar = SKSpriteNode()
	var stickyPaddleIconBar = SKSpriteNode()
	var gravityIconBar = SKSpriteNode()
	var lasersIconBar = SKSpriteNode()
	var superballIconBar = SKSpriteNode()
	var hiddenBricksIconBar = SKSpriteNode()
	// Power-up progress bars
	
	var paddleSizeIconEmptyBar = SKSpriteNode()
	var ballSpeedIconEmptyBar = SKSpriteNode()
	var stickyPaddleIconEmptyBar = SKSpriteNode()
	var gravityIconEmptyBar = SKSpriteNode()
	var lasersIconEmptyBar = SKSpriteNode()
	var superballIconEmptyBar = SKSpriteNode()
	var hiddenBricksIconEmptyBar = SKSpriteNode()
	// Power-up empty progress bars
	
	var powerUpTray = SKSpriteNode()
	
	var screenBlockArray: [SKSpriteNode] = []

	var iconArray: [SKSpriteNode] = []
	var iconTextureArray: [SKTexture] = []
	var disabledIconTextureArray: [SKTexture] = []
	var iconTimerArray: [SKSpriteNode] = []
	var iconEmptyTimerArray: [SKSpriteNode] = []
	var iconTimerTextureArray: [SKTexture] = []
	var iconSize: CGFloat = 0
	
	var layoutUnit: CGFloat = 0
    var paddleWidth: CGFloat = 0
    var paddleGap: CGFloat = 0
	var minPaddleGap: CGFloat = 0
    var ballSize: CGFloat = 0
    var ballStartingPositionY: CGFloat = 0
    var ballLaunchSpeed: Double = 0
    var ballLaunchAngleRad: Double = 0
    var ballLostHeight: CGFloat = 0
	var ballLostAnimationHeight: CGFloat = 0
	var brickHeight: CGFloat = 0
    var brickWidth: CGFloat = 0
    var numberOfBrickRows: Int = 0
    var numberOfBrickColumns: Int = 0
    var totalBricksWidth: CGFloat = 0
	var totalBricksHeight: CGFloat = 0
    var yBrickOffset: CGFloat = 0
    var xBrickOffset: CGFloat = 0
    var powerUpSize: CGFloat = 0
	var screenBlockTopWidth: CGFloat = 0
	var topGap: CGFloat = 0
	var paddlePositionY: CGFloat = 0
	var screenBlockTopHeight: CGFloat = 0
	var screenBlockSideWidth: CGFloat = 0
	var gameWidth: CGFloat = 0
    // Object layout property defintion
    
    var ballIsOnPaddle: Bool = true
    var numberOfLives: Int = 0
    var collisionLocation: Double = 0
    var minAngleDeg: Double = 0
    var maxAngleDeg: Double = 0
    var angleAdjustmentK: Double = 0
        // Effect of paddle position hit on ball angle. Larger number means more effect
    var bricksLeft: Int = 0
    var ballLinearDampening: CGFloat = 0
	var ballSpeedSlow: CGFloat = 0
	var ballSpeedSlowest: CGFloat = 0
	var ballSpeedNominal: CGFloat = 0
	var ballSpeedFast: CGFloat = 0
	var ballSpeedFastest: CGFloat = 0
	var ballSpeedLimit: CGFloat = 0
    var xSpeed: CGFloat = 0
    var ySpeed: CGFloat = 0
    var currentSpeed: CGFloat = 0
	var paddleMovementFactor: CGFloat = 1.25
	var levelNumber: Int = 0
	var powerUpProbFactor: Int = 0
	var brickRemovalCounter: Int = 0
	var gravityActivated: Bool = false
	var pauseBallVelocityX: CGFloat = 0
	var pauseBallVelocityY: CGFloat = 0
    // Setup game metrics
    
    var lifeLostScore: Int = 0
    var brickDestroyScore: Int = 0
    var powerUpScore: Int = 0
	var powerUpMultiplierScore: Double = 0
	var levelCompleteScore: Int = 0
	var levelScore: Int = 0
	var levelHighscore: Int = 0
	var totalScore: Int = 0
	var totalHighscore: Int = 0
	var multiplier: Double = 0
	var scoreFactorString: String = ""
	var newLevelHighScore: Bool = false
	var newTotalHighScore: Bool = false
    // Setup score properties
	
	var showAd: Bool = true
    
    let brickNormalTexture: SKTexture = SKTexture(imageNamed: "BrickNormal")
	
	let brickInvisibleTexture: SKTexture = SKTexture(imageNamed: "BrickInvisible")
	
    let brickMultiHit1Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit1")
    let brickMultiHit2Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit2")
    let brickMultiHit3Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit3")
	let brickMultiHit4Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit4")
	
	let brickIndestructible1Texture: SKTexture = SKTexture(imageNamed: "BrickIndestructible1")
    let brickIndestructible2Texture: SKTexture = SKTexture(imageNamed: "BrickIndestructible2")
	
	let brickNullTexture: SKTexture = SKTexture(imageNamed: "BrickNull")
    // Brick textures
    
    let powerUpGetALife: SKTexture = SKTexture(imageNamed: "PowerUpGetALife")
    let powerUpDecreaseBallSpeed: SKTexture = SKTexture(imageNamed: "PowerUpReduceBallSpeed")
    let powerUpSuperBall: SKTexture = SKTexture(imageNamed: "PowerUpSuperBall")
    let powerUpStickyPaddle: SKTexture = SKTexture(imageNamed: "PowerUpStickyPaddle")
    let powerUpNextLevel: SKTexture = SKTexture(imageNamed: "PowerUpNextLevel")
    let powerUpIncreasePaddleSize: SKTexture = SKTexture(imageNamed: "PowerUpIncreasePaddleSize")
    let powerUpShowInvisibleBricks: SKTexture = SKTexture(imageNamed: "PowerUpShowInvisibleBricks")
    let powerUpLasers: SKTexture = SKTexture(imageNamed: "PowerUpLasers")
    let powerUpRemoveIndestructibleBricks: SKTexture = SKTexture(imageNamed: "PowerUpRemoveIndestructibleBricks")
    let powerUpMultiHitToNormalBricks: SKTexture = SKTexture(imageNamed: "PowerUpMultiHitToNormalBricks")
	let powerUpMystery: SKTexture = SKTexture(imageNamed: "PowerUpMystery")
    let powerUpLoseALife: SKTexture = SKTexture(imageNamed: "PowerUpLoseALife")
    let powerUpIncreaseBallSpeed: SKTexture = SKTexture(imageNamed: "PowerUpIncreaseBallSpeed")
    let powerUpUndestructiBall: SKTexture = SKTexture(imageNamed: "PowerUpUndestructiBall")
    let powerUpDecreasePaddleSize: SKTexture = SKTexture(imageNamed: "PowerUpDecreasePaddleSize")
    let powerUpMultiplier: SKTexture = SKTexture(imageNamed: "PowerUpMultiplier")
    let powerUpPointsBonus: SKTexture = SKTexture(imageNamed: "PowerUpPointsBonus")
    let powerUpPointsPenalty: SKTexture = SKTexture(imageNamed: "PowerUpPointsPenalty")
    let powerUpNormalToInvisibleBricks: SKTexture = SKTexture(imageNamed: "PowerUpNormalToInvisibleBricks")
    let powerUpMultiHitBricksReset: SKTexture = SKTexture(imageNamed: "PowerUpMultiHitBricksReset")
    let powerUpGravityBall: SKTexture = SKTexture(imageNamed: "PowerUpGravityBall")
	let powerUpMultiplierReset: SKTexture = SKTexture(imageNamed: "PowerUpMultiplierReset")
	let powerUpBricksDown: SKTexture = SKTexture(imageNamed: "PowerUpBricksDown")
    // Power up textures
	
    let ballTexture: SKTexture = SKTexture(imageNamed: "Ball")
    let superballTexture: SKTexture = SKTexture(imageNamed: "BallSuper")
    let undestructiballTexture: SKTexture = SKTexture(imageNamed: "BallUndestructi")
	let directionMarkerOuterTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerOuter")
	let directionMarkerInnerTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerInner")
	let directionMarkerOuterSuperTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerOuterSuper")
	let directionMarkerInnerSuperTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerInnerSuper")
	let directionMarkerOuterUndestructiTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerOuterUndestructi")
	let directionMarkerInnerUndestructiTexture: SKTexture = SKTexture(imageNamed: "DirectionMarkerInnerUndestructi")
    // Ball textures
	
	let paddleTexture: SKTexture = SKTexture(imageNamed: "regularPaddle")
	let laserPaddleTexture: SKTexture = SKTexture(imageNamed: "laserPaddle")
	let stickyPaddleTexture: SKTexture = SKTexture(imageNamed: "stickyPaddle")
    // Paddle textures
    
	let laserNormalTexture: SKTexture = SKTexture(imageNamed: "LaserNormal")
    let superLaserTexture: SKTexture = SKTexture(imageNamed: "LaserSuper")
    // Laser textures
	
	let plainBackgroundTexture: SKTexture = SKTexture(imageNamed: "plainBackground")
    
    var stickyPaddleCatches: Int = 0
	var stickyPaddleCatchesTotal: Int = 0
    var laserPowerUpIsOn: Bool = false
    var laserTimer: Timer?
    var laserSideLeft: Bool = true
	var powerUpProximity: Bool = false
    // Power up properties
    
    var ballPositionOnPaddle: Double = 0
    
    let playTexture: SKTexture = SKTexture(imageNamed: "PlayButton")
    let pauseTexture: SKTexture = SKTexture(imageNamed: "PauseButton")
    // Play/pause button textures
	
	let iconIncreasePaddleSizeTexture: SKTexture = SKTexture(imageNamed: "ExpandPaddleIcon")
	let iconDecreasePaddleSizeTexture: SKTexture = SKTexture(imageNamed: "ShrinkPaddleIcon")
	let iconDecreaseBallSpeedTexture: SKTexture = SKTexture(imageNamed: "SlowBallIcon")
	let iconIncreaseBallSpeedTexture: SKTexture = SKTexture(imageNamed: "FastBallIcon")
	let iconStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "StickyPaddleIcon")
	let iconGravityTexture: SKTexture = SKTexture(imageNamed: "GravityIcon")
	let iconLasersTexture: SKTexture = SKTexture(imageNamed: "LasersIcon")
	let iconUndestructiballTexture: SKTexture = SKTexture(imageNamed: "UndestructiBallIcon")
	let iconSuperballTexture: SKTexture = SKTexture(imageNamed: "SuperballIcon")
	let iconHiddenBlocksTexture: SKTexture = SKTexture(imageNamed: "HiddenBricksIcon")
	// Power-up icon textures
	
	let iconPaddleSizeDisabledTexture: SKTexture = SKTexture(imageNamed: "PaddleSizeIconDisabled")
	let iconBallSpeedDisabledTexture: SKTexture = SKTexture(imageNamed: "BallSpeedIconDisabled")
	let iconStickyPaddleDisabledTexture: SKTexture = SKTexture(imageNamed: "StickyPaddleIconDisabled")
	let iconGravityDisabledTexture: SKTexture = SKTexture(imageNamed: "GravityIconDisabled")
	let iconLasersDisabledTexture: SKTexture = SKTexture(imageNamed: "LasersIconDisabled")
	let iconSuperballDisabledTexture: SKTexture = SKTexture(imageNamed: "SuperballIconDisabled")
	let iconHiddenBlocksDisabledTexture: SKTexture = SKTexture(imageNamed: "HiddenBricksIconDisabled")
	// Power-up icon disabled textures
	
	let powerUpIconBarEmpty: SKTexture = SKTexture(imageNamed: "PowerUpTimerEmpty")
	let powerUpIconBarFull: SKTexture = SKTexture(imageNamed: "PowerUpTimerFull")
	// Power-up icon bar textures

    var touchBeganWhilstPlaying: Bool = false
    var paddleMoved: Bool = false
    var paddleMovedDistance: CGFloat = 0
	var ballRelativePositionOnPaddle: CGFloat = 0
    var gameoverStatus: Bool = false
    var endLevelNumber: Int = 0
	var mysteryPowerUp: Bool = false
	var ballLostBool: Bool = true
	var powerUpsOnScreen: Int = 0
	var powerUpLimit: Int = 0
	var brickBounceCounter: Int = 0
	var killBall: Bool = false
    // Game trackers
	
	let straightLaunchAngleRad = 90 * Double.pi / 180
	let minLaunchAngleRad = 10 * Double.pi / 180
	let maxLaunchAngleRad = 70 * Double.pi / 180
	var launchAngleMultiplier = 0
	// Ball launch
    
    var fontSize: CGFloat = 0
    var labelSpacing: CGFloat = 0
    // Label metrics
	
	var countdownStarted: Bool = false
	
	var screenRatio: CGFloat = 0.0
	var screenSize: String = ""
	
//MARK: - Animation Setup
	
	let timerScaleUp = SKAction.scale(to: 1.25, duration: 0.05)
	let timerScaleDown = SKAction.scale(to: 1, duration: 0.05)
	let pointsScaleDown = SKAction.scale(to: 0.75, duration: 0.05)
	// Setup timer icon animation
	
//MARK: - Sound and Haptic Definition
    
    var lightHaptic = UIImpactFeedbackGenerator(style: .light)
	// use for UI interactions
	// use for ball hitting bricks and paddle
    var mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
	//
    var heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
	//
	var softHaptic = UIImpactFeedbackGenerator(style: .heavy)
	// use for lost ball
	var rigidHaptic = UIImpactFeedbackGenerator(style: .heavy)
	// use for power-ups collected
	
	// Haptics defined
	
//MARK: - State Machine Defintion

    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        PreGame(scene: self),
        Playing(scene: self),
        InbetweenLevels(scene: self),
        GameOver(scene: self),
        Paused(scene: self),
		Ad(scene: self)])
    // Sets up the game states
    
    weak var gameViewControllerDelegate:GameViewControllerDelegate?
    // Create the delegate property for the GameViewController
	
//MARK: - NSCoder Data Store Setup
    
    let dataStore = UserDefaults.standard
    // Setup NSUserDefaults data store
    
    var levelScoreArray: [Int] = [1]
    // Creates arrays to store level highscores from NSUserDefauls
	
	var totalScoreArray: [Int] = [1]
    // Creates arrays to store total highscores from NSUserDefauls
    
    override func didMove(to view: SKView) {
		
//MARK: - Scene Setup
		
		if #available(iOS 13.0, *) {
			softHaptic = UIImpactFeedbackGenerator(style: .soft)
			// use for lost ball
			rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
			// use for power-ups collected
		}
		// Haptics redefined for iOS13
	
        physicsWorld.contactDelegate = self
        // Sets the GameScene as the delegate in the physicsWorld
        
        let boarder = SKPhysicsBody(edgeLoopFrom: frame)
        boarder.friction = 0
        boarder.restitution = 1
		boarder.categoryBitMask = CollisionTypes.boarderCategory.rawValue
		boarder.collisionBitMask = CollisionTypes.ballCategory.rawValue
		boarder.contactTestBitMask = CollisionTypes.ballCategory.rawValue
        self.physicsBody = boarder
        // Sets up the boarder to interact with the objects
		
		physicsWorld.gravity = CGVector(dx: 0, dy: 0)
		// Setup gravity
		
//MARK: - Object Initialisation

        ball = self.childNode(withName: "ball") as! SKSpriteNode
        paddle = self.childNode(withName: "paddle") as! SKSpriteNode
		paddleLaser = self.childNode(withName: "paddleLaser") as! SKSpriteNode
		paddleSticky = self.childNode(withName: "paddleSticky") as! SKSpriteNode
        pauseButton = self.childNode(withName: "pauseButton") as! SKSpriteNode
		pauseButtonTouch = self.childNode(withName: "pauseButtonTouch") as! SKSpriteNode
        life = self.childNode(withName: "life") as! SKSpriteNode
		topScreenBlock = self.childNode(withName: "topScreenBlock") as! SKSpriteNode
		sideScreenBlockLeft = self.childNode(withName: "sideScreenBlockLeft") as! SKSpriteNode
		sideScreenBlockRight = self.childNode(withName: "sideScreenBlockRight") as! SKSpriteNode
		background = self.childNode(withName: "background") as! SKSpriteNode
		directionMarker = self.childNode(withName: "directionMarker") as! SKSpriteNode
        // Links objects to nodes
		
		paddleSizeIcon = self.childNode(withName: "paddleSizeIcon") as! SKSpriteNode
		ballSpeedIcon = self.childNode(withName: "ballSpeedIcon") as! SKSpriteNode
		stickyPaddleIcon = self.childNode(withName: "stickyPaddleIcon") as! SKSpriteNode
		gravityIcon = self.childNode(withName: "gravityIcon") as! SKSpriteNode
		lasersIcon = self.childNode(withName: "lasersIcon") as! SKSpriteNode
		superballIcon = self.childNode(withName: "superballIcon") as! SKSpriteNode
		hiddenBricksIcon = self.childNode(withName: "hiddenBricksIcon") as! SKSpriteNode
		// Power-up icon creation
		
		paddleSizeIconBar = self.childNode(withName: "paddleSizeIconBar") as! SKSpriteNode
		ballSpeedIconBar = self.childNode(withName: "ballSpeedIconBar") as! SKSpriteNode
		stickyPaddleIconBar = self.childNode(withName: "stickyPaddleIconBar") as! SKSpriteNode
		gravityIconBar = self.childNode(withName: "gravityIconBar") as! SKSpriteNode
		lasersIconBar = self.childNode(withName: "lasersIconBar") as! SKSpriteNode
		superballIconBar = self.childNode(withName: "superballIconBar") as! SKSpriteNode
		hiddenBricksIconBar = self.childNode(withName: "hiddenBricksIconBar") as! SKSpriteNode
		// Power-up icon timer bar creation
		
		paddleSizeIconEmptyBar = self.childNode(withName: "paddleSizeIconEmptyBar") as! SKSpriteNode
		ballSpeedIconEmptyBar = self.childNode(withName: "ballSpeedIconEmptyBar") as! SKSpriteNode
		stickyPaddleIconEmptyBar = self.childNode(withName: "stickyPaddleIconEmptyBar") as! SKSpriteNode
		gravityIconEmptyBar = self.childNode(withName: "gravityIconEmptyBar") as! SKSpriteNode
		lasersIconEmptyBar = self.childNode(withName: "lasersIconEmptyBar") as! SKSpriteNode
		superballIconEmptyBar = self.childNode(withName: "superballIconEmptyBar") as! SKSpriteNode
		hiddenBricksIconEmptyBar = self.childNode(withName: "hiddenBricksIconEmptyBar") as! SKSpriteNode
		// Power-up icon timer bar creation
		
		powerUpTray = self.childNode(withName: "powerUpTray") as! SKSpriteNode
		// Power-up area
		
		screenRatio = frame.size.height/frame.size.width
        
		if screenRatio > 2 {
			screenSize = "X"
		} else if screenRatio < 1.7  {
			screenSize = "Pad"
			
		} else {
			screenSize = "8"
		}
		// Screen size and device detected
		
		screenBlockSideWidth = 1
		gameWidth = frame.size.width - screenBlockSideWidth*2
		
		sideScreenBlockLeft.isHidden = true
		sideScreenBlockRight.isHidden = true
		sideScreenBlockLeft.position.x = -frame.size.width
		sideScreenBlockRight.position.x = frame.size.width
		numberOfBrickRows = 22
        numberOfBrickColumns = numberOfBrickRows/2
		layoutUnit = (gameWidth)/CGFloat(numberOfBrickRows)
		pauseButtonSize = layoutUnit*2
		iconSize = layoutUnit*1.5
		brickWidth = layoutUnit*2
		brickHeight = layoutUnit
		paddleGap = layoutUnit*7
		fontSize = 16
		
		if screenSize == "X" {
			screenBlockTopHeight = layoutUnit*7.4
		} else if screenSize == "Pad" {
			screenBlockSideWidth = frame.size.width/10
			gameWidth = frame.size.width - screenBlockSideWidth*2
			layoutUnit = (gameWidth)/CGFloat(numberOfBrickRows)
			sideScreenBlockLeft.isHidden = false
			sideScreenBlockRight.isHidden = false
			pauseButtonSize = layoutUnit*1.5
			brickWidth = layoutUnit*2
			brickHeight = (gameWidth*0.87)/CGFloat(numberOfBrickRows-1)
			paddleGap = layoutUnit*7
			iconSize = layoutUnit
			screenBlockTopHeight = iconSize*2
			sideScreenBlockLeft.position.x = -frame.size.width/2+screenBlockSideWidth/2
			sideScreenBlockRight.position.x = frame.size.width/2-screenBlockSideWidth/2
		} else {
			screenBlockTopHeight = layoutUnit*3
			brickHeight = (gameWidth*0.87)/CGFloat(numberOfBrickRows-1)
		}
		
		sideScreenBlockLeft.size.width = screenBlockSideWidth
		sideScreenBlockRight.size.width = screenBlockSideWidth
		
		labelSpacing = fontSize/1.5
		minPaddleGap = brickHeight*4
		ballLostAnimationHeight = paddle.size.height
		ballLostHeight = ballLostAnimationHeight*4
		
		totalBricksWidth = CGFloat(numberOfBrickColumns) * (brickWidth)
		totalBricksHeight = CGFloat(numberOfBrickRows) * (brickHeight)
		
		ballSize = layoutUnit*0.67
		ball.size.width = ballSize
        ball.size.height = ballSize
		life.size.width = ballSize*1.15
		life.size.height = ballSize*1.15
		
		paddleWidth = layoutUnit*5
		paddle.size.width = paddleWidth
		paddle.size.height = ballSize
		paddleLaser.size.width = paddleWidth
		paddleLaser.size.height = ballSize*1.6
		paddleSticky.size.width = paddleWidth
		paddleSticky.size.height = ballSize*1.1
		paddle.centerRect = CGRect(x: 0.0/80.0, y: 0.0/10.0, width: 80.0/80.0, height: 10.0/10.0)
		paddleLaser.centerRect = CGRect(x: 0.0/80.0, y: 0.0/16.0, width: 80.0/80.0, height: 16.0/16.0)
		paddleSticky.centerRect = CGRect(x: 0.0/80.0, y: 0.0/11.0, width: 80.0/80.0, height: 11.0/11.0)
		
		topScreenBlock.size.height = screenBlockTopHeight
		topScreenBlock.size.width = frame.size.width
		sideScreenBlockLeft.size.height = frame.size.height - screenBlockTopHeight
		sideScreenBlockRight.size.height = frame.size.height - screenBlockTopHeight
		sideScreenBlockLeft.position.y = -frame.size.height/2+sideScreenBlockLeft.size.height/2
		sideScreenBlockLeft.zPosition = 1
		sideScreenBlockRight.position.y = -frame.size.height/2+sideScreenBlockRight.size.height/2
		sideScreenBlockRight.zPosition = 1
		
		topGap = brickHeight*3
		// Object size definition
		
		ballLinearDampening = -0.02

		topScreenBlock.position.x = 0
		topScreenBlock.position.y = frame.height/2 - screenBlockTopHeight/2
		yBrickOffset = frame.height/2 - topScreenBlock.size.height - topGap - brickHeight/2
		paddle.position.x = 0
		paddlePositionY = frame.height/2 - topScreenBlock.size.height - topGap - totalBricksHeight - paddleGap - paddle.size.height/2
		paddle.position.y = paddlePositionY
		ball.position.x = 0
		ballStartingPositionY = paddlePositionY + paddle.size.height/2 + ballSize/2 + 1
		ball.position.y = ballStartingPositionY
		directionMarker.zPosition = 10
		// Object positioning definition
		
		background.texture = plainBackgroundTexture
		background.size.height = frame.size.height - screenBlockTopHeight
		background.size.width = gameWidth
		background.position.x = 0
		background.position.y = -frame.size.height/2
		background.zPosition = 0
		
		ball.texture = ballTexture
		ball.physicsBody = SKPhysicsBody(circleOfRadius: ballSize/2)
        ball.physicsBody!.allowsRotation = false
        ball.physicsBody!.friction = 0.0
        ball.physicsBody!.affectedByGravity = false
        ball.physicsBody!.isDynamic = true
        ball.name = BallCategoryName
        ball.physicsBody!.categoryBitMask = CollisionTypes.ballCategory.rawValue
        ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
		ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
        ball.zPosition = 2
		ball.physicsBody!.usesPreciseCollisionDetection = true
		ball.physicsBody!.linearDamping = ballLinearDampening
        ball.physicsBody!.angularDamping = 0
		ball.physicsBody!.restitution = 1
		ball.physicsBody!.density = 2
//		let xRangeBall = SKRange(lowerLimit:-gameWidth/2 + ballSize/2,upperLimit:gameWidth/2 - ballSize/2)
//        ball.constraints = [SKConstraint.positionX(xRangeBall)]
		// Define ball properties

		paddle.physicsBody = SKPhysicsBody(texture: paddle.texture!, size: CGSize(width: paddle.size.width, height: paddle.size.height))
		if paddle.physicsBody == nil {
			paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
		}
        paddle.physicsBody!.allowsRotation = false
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.physicsBody!.isDynamic = true
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = CollisionTypes.paddleCategory.rawValue
		paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue
        paddle.zPosition = 2
		paddleLaser.zPosition = 3
		paddleSticky.zPosition = 4
		paddle.physicsBody!.usesPreciseCollisionDetection = true
		paddle.physicsBody!.restitution = 1
		// Define paddle properties
		
		ball.isHidden = true
        paddle.isHidden = true
		paddleLaser.isHidden = true
		paddleSticky.isHidden = true
		directionMarker.isHidden = true
        // Hide ball and paddle
		
		screenBlockArray = [topScreenBlock, sideScreenBlockLeft, sideScreenBlockRight]
		
		for i in 1...screenBlockArray.count {
			let index = i-1
			screenBlockArray[index].physicsBody = SKPhysicsBody(rectangleOf: screenBlockArray[index].frame.size)
			screenBlockArray[index].physicsBody!.allowsRotation = false
			screenBlockArray[index].physicsBody!.friction = 0.0
			screenBlockArray[index].physicsBody!.affectedByGravity = false
			screenBlockArray[index].physicsBody!.isDynamic = false
			screenBlockArray[index].zPosition = 7
			screenBlockArray[index].name = ScreenBlockCategoryName
			screenBlockArray[index].physicsBody!.categoryBitMask = CollisionTypes.screenBlockCategory.rawValue
			screenBlockArray[index].physicsBody!.collisionBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.laserCategory.rawValue
			screenBlockArray[index].physicsBody!.contactTestBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.laserCategory.rawValue
		}
		// Define all screen block properties
		
//MARK: - Label & UI Initialisation
		
        livesLabel = self.childNode(withName: "livesLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
		multiplierLabel = self.childNode(withName: "multiplierLabel") as! SKLabelNode
		unpauseCountdownLabel = self.childNode(withName: "unpauseCountdownLabel") as! SKLabelNode
		buildLabel = self.childNode(withName: "buildLabel") as! SKLabelNode
        // Links objects to label
		
		unpauseCountdownLabel.position.x = 0
		unpauseCountdownLabel.position.y = 0
		unpauseCountdownLabel.fontSize = fontSize*4
		unpauseCountdownLabel.isHidden = true
		unpauseCountdownLabel.zPosition = 10
		
        pauseButton.size.width = pauseButtonSize
        pauseButton.size.height = pauseButtonSize
        pauseButton.texture = pauseTexture
		pauseButton.position.x = -frame.size.width/2 + labelSpacing*2 + pauseButton.size.width/2
		pauseButton.position.y = frame.size.height/2 - labelSpacing*0.75 - pauseButton.size.height*1.25

		pauseButton.zPosition = 10
        pauseButton.isUserInteractionEnabled = false
		
		powerUpTray.zPosition = 8
		powerUpTray.size.width = gameWidth
		powerUpTray.size.height = iconSize*2
		powerUpTray.centerRect = CGRect(x: 5.0/40.0, y: 5.0/40.0, width: 30.0/40.0, height: 30.0/40.0)
		powerUpTray.scale(to:CGSize(width: gameWidth, height: iconSize*2))
		powerUpTray.position.x = 0
		
		if screenSize == "X" {
			powerUpTray.position.y = pauseButton.position.y - pauseButton.size.height/2 - powerUpTray.size.height/2 - labelSpacing/2
		} else {
			powerUpTray.position.y = frame.size.height/2 - powerUpTray.size.height/2
			pauseButton.position.y = frame.size.height/2 - screenBlockTopHeight - labelSpacing/2 - pauseButton.size.height/2
		}
		
		scoreLabel.position.x = frame.size.width/2 - labelSpacing*2
		scoreLabel.position.y = pauseButton.position.y + fontSize/4 + labelSpacing/2
		scoreLabel.fontSize = fontSize
		scoreLabel.zPosition = 10
		
		if screenSize == "Pad" {
			pauseButton.position.x = sideScreenBlockLeft.position.x + sideScreenBlockLeft.size.width/2 + pauseButton.size.width/2 + layoutUnit/2
			scoreLabel.position.x = sideScreenBlockRight.position.x - sideScreenBlockRight.size.width/2 - layoutUnit/2
		}
		
		multiplierLabel.position.x = scoreLabel.position.x
		multiplierLabel.position.y = scoreLabel.position.y - labelSpacing - fontSize/2
		multiplierLabel.fontSize = fontSize
		multiplierLabel.zPosition = 10
		life.position.x = -life.size.width/3
		life.position.y = pauseButton.position.y
		life.zPosition = 10
		livesLabel.position.x = life.size.width/3
		livesLabel.position.y = life.position.y
        livesLabel.fontSize = fontSize
		livesLabel.zPosition = 10
		buildLabel.position.x = -gameWidth/2 + labelSpacing
		buildLabel.position.y = -frame.size.height/2 + labelSpacing*2
		buildLabel.fontSize = fontSize/3*2
		buildLabel.zPosition = 10
		buildLabel.text = "99f3f5c, 26012020, \(frame.size.height)x\(frame.size.width)" //GitHub ID, Date & Time, Frame Height x Frame Width
        // Label size & position definition
		
		pauseButtonTouch.size.width = pauseButtonSize*2.75
		pauseButtonTouch.size.height = pauseButtonSize*2.75
		pauseButtonTouch.position.y = pauseButton.position.y
		pauseButtonTouch.position.x = pauseButton.position.x
		pauseButtonTouch.zPosition = 10
        pauseButtonTouch.isUserInteractionEnabled = false
		// Pause button size and position
		
		iconArray = [paddleSizeIcon, ballSpeedIcon, stickyPaddleIcon, gravityIcon, lasersIcon, superballIcon, hiddenBricksIcon]
		disabledIconTextureArray = [iconPaddleSizeDisabledTexture, iconBallSpeedDisabledTexture, iconStickyPaddleDisabledTexture, iconGravityDisabledTexture, iconLasersDisabledTexture, iconSuperballDisabledTexture, iconHiddenBlocksDisabledTexture]
		iconTextureArray = [iconIncreasePaddleSizeTexture, iconDecreasePaddleSizeTexture, iconDecreaseBallSpeedTexture, iconIncreaseBallSpeedTexture, iconStickyPaddleTexture, iconGravityTexture, iconLasersTexture, iconUndestructiballTexture, iconSuperballTexture, iconHiddenBlocksTexture]
		iconTimerArray = [paddleSizeIconBar, ballSpeedIconBar, stickyPaddleIconBar, gravityIconBar, lasersIconBar, superballIconBar, hiddenBricksIconBar]
		iconEmptyTimerArray = [paddleSizeIconEmptyBar, ballSpeedIconEmptyBar, stickyPaddleIconEmptyBar, gravityIconEmptyBar, lasersIconEmptyBar, superballIconEmptyBar, hiddenBricksIconEmptyBar]
		
		for i in 1...iconArray.count {
			let index = i-1
			let iconSpacing = ((gameWidth-iconSize*2) - iconSize*(CGFloat(iconArray.count)-1)) / (CGFloat(iconArray.count)-1)
			iconArray[index].size.width = iconSize
			iconArray[index].size.height = iconSize
			iconArray[index].texture = disabledIconTextureArray[index]
			iconArray[index].position.x = -gameWidth/2 + iconSize + (iconSize+iconSpacing)*CGFloat(index)
			iconArray[index].position.y = powerUpTray.position.y + labelSpacing/2
			iconArray[index].zPosition = 10
			iconArray[index].name = powerIconCategoryName
			iconEmptyTimerArray[index].size.width = iconSize
			iconEmptyTimerArray[index].size.height = iconSize/6.67
			iconEmptyTimerArray[index].texture = powerUpIconBarEmpty
			iconEmptyTimerArray[index].position.x = iconArray[index].position.x - iconEmptyTimerArray[index].size.width/2
			iconEmptyTimerArray[index].position.y = iconArray[index].position.y - iconSize/2 - iconEmptyTimerArray[index].size.height/2 - labelSpacing/2
			iconEmptyTimerArray[index].zPosition = 9
			iconTimerArray[index].size.width = iconEmptyTimerArray[index].size.width
			iconTimerArray[index].size.height = iconEmptyTimerArray[index].size.height
			iconTimerArray[index].texture = powerUpIconBarFull
			iconTimerArray[index].position.x = iconEmptyTimerArray[index].position.x
			iconTimerArray[index].position.y = iconEmptyTimerArray[index].position.y
			iconTimerArray[index].zPosition = 10
			iconTimerArray[index].isHidden = true
			iconTimerArray[index].centerRect = CGRect(x: 2.0/25.0, y: 0.0/2.5, width: 21.0/25.0, height: 2.5/2.5)
			iconTimerArray[index].scale(to:CGSize(width: iconEmptyTimerArray[index].size.width, height: iconEmptyTimerArray[index].size.height))
		}
		// Power-up progress icon definition and setup

//MARK: - Game Properties Initialisation
        
		ballSpeedNominal = ballSize * 30
		ballSpeedSlow = ballSize * 25
		ballSpeedSlowest = ballSize * 20
		ballSpeedFast = ballSize * 35
		ballSpeedFastest = ballSize * 40
		ballSpeedLimit = ballSpeedNominal
		// Ball speed parameters
		
		minAngleDeg = 7.5
		maxAngleDeg = 180-minAngleDeg
		angleAdjustmentK = 45
		// Ball angle parameters
		
		powerUpProbFactor = 10
		powerUpLimit = 2
		// Power-up parameters
		
		brickDestroyScore = 10
		lifeLostScore = -100
		levelCompleteScore = 100
		multiplier = 1.0
		// Score properties
        
        endLevelNumber = 10
		// Define number of levels
		
		brickBounceCounter = 0
		
//MARK: - Score Database Setup
        
        if let levelScoreStore = dataStore.array(forKey: "LevelScoreStore") as? [Int] {
            levelScoreArray = levelScoreStore
        }
        // Setup array to store level highscores
		
		if let totalScoreStore = dataStore.array(forKey: "TotalScoreStore") as? [Int] {
            totalScoreArray = totalScoreStore
        }
        // Setup array to store total highscores
        
        print(NSHomeDirectory())
        // Prints the location of the NSUserDefaults plist (Library>Preferences)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.pauseNotificationKeyReceived), name: Notification.Name.pauseNotificationKey, object: nil)
        // Sets up an observer to watch for notifications from AppDelegate to check if the app has quit
		
		let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
		swipeUp.direction = .up
		view.addGestureRecognizer(swipeUp)
		// Setup swipe gesture
		
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
            
			var paddleX0 = CGFloat(0)
            var paddleX1 = CGFloat(0)
            // Define the property to store the x position of the paddle
			
			paddleMovedDistance = touchLocation.x - previousLocation.x
			paddleX0 = paddle.position.x
			paddleX1 = paddleX0 + (paddleMovedDistance*paddleMovementFactor)
			
			if paddleX1 > (gameWidth/2 - paddle.size.width/2) {
				paddleX1 = gameWidth/2 - paddle.size.width/2
			}
			if paddleX1 < -(gameWidth/2 - paddle.size.width/2) {
				paddleX1 = -(gameWidth/2 - paddle.size.width/2)
			}
			// Check paddle position isn't outside the frame
			
			paddle.position = CGPoint(x: paddleX1, y: paddle.position.y)
			// Sets the paddle to match the new calculated position
				
			if ballIsOnPaddle && paddleMovedDistance != 0 {
				ball.position.x = paddle.position.x + ballRelativePositionOnPaddle				
				ball.position.y = ballStartingPositionY
				paddleMoved = true
				
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
		
		if ballIsOnPaddle {
			ballRelativePositionOnPaddle = ball.position.x - paddle.position.x
		}
		// Define the current position of the ball relative to the paddle
        
        if gameState.currentState is Playing || gameState.currentState is Paused {
            let touch = touches.first
            let positionInScene = touch!.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            if let name = touchedNode.name {
                if name == "pauseButton" || name == "pauseButtonTouch" && gameState.currentState is Playing {
					gameState.enter(Paused.self)
                }
            }
        }
        // Pause the game if the pause button is pressed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if ballIsOnPaddle && touchBeganWhilstPlaying && paddleMoved == false && gameState.currentState is Playing {
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
		
		brickBounceCounter = 0
		ballIsOnPaddle = false
		ballLostBool = false
        // Resets ball on paddle status
		
		ballRelativePositionOnPaddle = 0
        
        if stickyPaddleCatches != 0 {
            stickyPaddleCatches-=1
			let iconBarLength: CGFloat = (CGFloat(stickyPaddleCatches)/CGFloat(stickyPaddleCatchesTotal))
			stickyPaddleIconBar.run(SKAction.scaleX(to: iconBarLength, duration: 0.05))
			// Size icon timer based on number of catches remaining
            if stickyPaddleCatches == 0 {
				paddleSticky.isHidden = true
				stickyPaddleCatchesTotal = 0
				stickyPaddleIcon.texture = iconStickyPaddleDisabledTexture
				stickyPaddleIconBar.isHidden = true
				stickyPaddleIconBar.xScale = 0
				// Sticky paddle reset
            }
        }

        ballPositionOnPaddle = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
        // Define the relative position between the ball and paddle

		if ballPositionOnPaddle < 0 {
            launchAngleMultiplier = 1
		} else {
			launchAngleMultiplier = -1
		}
        // Determines which angle the ball will launch and modify the multiplier accordingly
        
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
            ballLaunchAngleRad = straightLaunchAngleRad - ((maxLaunchAngleRad - minLaunchAngleRad) * ballPositionOnPaddle) + (minLaunchAngleRad * Double(launchAngleMultiplier))
            // Determine the launch angle based on the location of the ball on the paddle
        }
        
        let dxLaunch = cos(ballLaunchAngleRad) * Double(ballSpeedLimit)
        let dyLaunch = sin(ballLaunchAngleRad) * Double(ballSpeedLimit)
		ball.physicsBody!.velocity = CGVector(dx: dxLaunch, dy: dyLaunch)
        // Launches ball

        lightHaptic.impactOccurred()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
		
		recentreBall()
		
		if gameState.currentState is Paused && self.isPaused == false && countdownStarted == false {
			self.isPaused = true
		}
		// Ensures game is paused when returning from background

        if gameState.currentState is Playing {
			
			powerUpsOnScreen = 0

			enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
				
				self.powerUpsOnScreen+=1
				// Track number of power-ups to limit number on screen
				
				if node.position.y < self.paddle.position.y - self.paddle.size.height - self.brickWidth/2 {
					let sprite = node as! SKSpriteNode
					if sprite.texture == self.powerUpMystery {
						self.powerUpsOnScreen-=1
						self.powerUpGenerator (sprite: sprite)
						node.removeFromParent()
					}
				}
				// If mystery power-up, replace with another power-up
				
				if node.position.y < self.paddle.position.y - self.paddle.size.height - self.brickWidth {
					let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
					let fadeOut = SKAction.fadeOut(withDuration: 0.2)
					let removeItemGroup = SKAction.group([scaleDown, fadeOut])
					// Setup power-up removal animation
					node.run(removeItemGroup, completion: {
						node.removeFromParent()
					})
				}
			}
			// Remove power-ups once they reach the bottom
			
			paddle.position.y = paddlePositionY
			// Ensure paddle remains at its set height
			
			paddleLaser.position.x = paddle.position.x
			paddleLaser.position.y = paddle.position.y - paddle.size.height/2
			paddleSticky.position.x = paddle.position.x
			paddleSticky.position.y = paddle.position.y - paddle.size.height/2
			// Keep the different paddle textures together
			
			if ballIsOnPaddle {
				ball.position.y = ballStartingPositionY
			}
			// Ensure ball remains on paddle
		}
		// Code to run continuously whilst playing
		
		if gameState.currentState is Playing && ballIsOnPaddle == false {
			
			xSpeed = ball.physicsBody!.velocity.dx
			ySpeed = ball.physicsBody!.velocity.dy
			currentSpeed = sqrt(ball.physicsBody!.velocity.dx * ball.physicsBody!.velocity.dx + ball.physicsBody!.velocity.dy * ball.physicsBody!.velocity.dy)
			// Calculate ball speed
			
            if ball.position.y <= paddle.position.y - ballLostAnimationHeight {
                ballLostAnimation()
            }
            if ball.position.y <= paddle.position.y - ballLostHeight {
                ballLost()
            }
			// Determine if ball has been lost below paddle
			
			if brickBounceCounter == 100 {
				enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
					let temporarySprite = node as! SKSpriteNode
					if temporarySprite.texture == self.brickIndestructible1Texture || temporarySprite.texture == self.brickIndestructible2Texture {
						node.removeFromParent()
					}
				}
			}
			// Remove indestructible bricks if the ball hits them a certain number of times consecutively
			
        }
		// Code to run continuously whilst playing when the ball is off the paddle
        
        if gameState.currentState is Playing && ballIsOnPaddle == false && gravityActivated == false {
            
			var angleRad = Double(atan2(ySpeed, xSpeed))
			var angleDeg = Double(angleRad)/Double.pi*180
				
			if ball.position.x >= 0 {
				// ball is on right side of screen

				if angleDeg > 85 && angleDeg < 90 {
					angleDeg = 85
				}
				else if angleDeg < 95 && angleDeg >= 90 {
					angleDeg = 95
				}
				else if angleDeg > -95 && angleDeg <= -90 {
					angleDeg = -95
				}
				else if angleDeg < -85 && angleDeg > -90 {
					angleDeg = -85
				}
				
			} else {
				// ball is on left side of screen
				if angleDeg > 85 && angleDeg <= 90 {
					angleDeg = 85
				}
				else if angleDeg < 95 && angleDeg > 90 {
					angleDeg = 95
				}
				else if angleDeg > -95 && angleDeg < -90 {
					angleDeg = -95
				}
				else if angleDeg < -85 && angleDeg >= -90 {
					angleDeg = -85
				}
			}
			
			angleRad = (angleDeg*Double.pi/180)
			xSpeed = CGFloat(cos(angleRad)) * currentSpeed
			ySpeed = CGFloat(sin(angleRad)) * currentSpeed
			ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
			// Set the new angle of the ball

			// check y-angle - stops the ball getting trapped on the wall
			
			if (angleDeg <= minAngleDeg/2 && angleDeg >= -minAngleDeg/2) || (angleDeg > 180-minAngleDeg/2 && angleDeg <= 180) || (angleDeg < -180+minAngleDeg/2 && angleDeg >= -180) {
				correctBallAngle(correctedAngle: minAngleDeg/2)
			}
			
			if currentSpeed > ballSpeedLimit + currentSpeed/10 {
				ball.physicsBody!.linearDamping = 0.5
            } else if currentSpeed < ballSpeedLimit {
				ball.physicsBody!.linearDamping = -0.5
            } else {
                ball.physicsBody!.linearDamping = ballLinearDampening
            }
			// Set the new speed of the ball and ensure it stays within the boundary
        }
		// Code to run continuously whilst playing when the ball is off the paddle and gravity power-up is off
		
		if gameState.currentState is Playing && gravityActivated == true {
			
			if ball.position.y < paddle.position.y + ballSize*4 {
				ball.physicsBody?.affectedByGravity = false
			} else {
				ball.physicsBody?.affectedByGravity = true
			}
			
			if currentSpeed > ballSpeedLimit + currentSpeed/10 {
				ball.physicsBody!.linearDamping = 0.5
            } else {
                ball.physicsBody!.linearDamping = ballLinearDampening
            }
			// Set the new speed of the ball and ensure it stays within the boundary
			
		}
		// Code to run coninuously when gravity is acitvated
    }
    
    func ballLost() {
		softHaptic.impactOccurred()
        self.ball.isHidden = true
		brickBounceCounter = 0
		ballRelativePositionOnPaddle = 0
        ball.position.x = paddle.position.x
        ball.position.y = ballStartingPositionY
        ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
        ballIsOnPaddle = true
        paddleMoved = true
		ballLostBool = true
        // Reset ball position
		
		brickRemovalCounter = 0
		// Reset brick removal counter

        powerUpsReset()
		// Reset any gained power-ups
		
		let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let removeItemGroup = SKAction.group([scaleDown, fadeOut])
		// Setup power-up removal animation
		
		enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining power-ups
		
		enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.removeAllActions()
            node.run(removeItemGroup, completion: {
                node.removeFromParent()
            })
        }
        // Remove any remaining power-ups
		
		levelScore = levelScore + lifeLostScore
        scoreLabel.text = String(totalScore + levelScore)
		// Update score
		
		multiplier = 1
		scoreFactorString = String(format:"%.1f", multiplier)
		multiplierLabel.text = "x\(scoreFactorString)"
		// Reset score multiplier
		
        if numberOfLives > 0 {
			
			life.removeAllActions()
            
            let fadeOutLife = SKAction.fadeOut(withDuration: 0.25)
            let scaleDownLife = SKAction.scale(to: 0, duration: 0.25)
            let waitTimeLife = SKAction.wait(forDuration: 0.25)
            let fadeInLife = SKAction.fadeIn(withDuration: 0.5)
			let scaleUpLife = SKAction.scale(to: 1, duration: 0.5)
			let largeLife = SKAction.scale(to: 1.5, duration: 0)
            let lifeLostGroup = SKAction.group([fadeOutLife, scaleDownLife, waitTimeLife])
            let resetLifeGroup = SKAction.group([scaleUpLife, fadeInLife])
            // Setup life lost animation
            
            let fadeOutBall = SKAction.fadeOut(withDuration: 0)
            let scaleDownBall = SKAction.scale(to: 0, duration: 0)
            let waitTimeBall = SKAction.wait(forDuration: 0.25)
            let fadeInBall = SKAction.fadeIn(withDuration: 0.25)
            let scaleUpBall = SKAction.scale(to: 1, duration: 0.25)
            let resetBallGroup = SKAction.group([fadeOutBall, scaleDownBall, waitTimeBall])
            let ballGroup = SKAction.group([fadeInBall, scaleUpBall])
            // Setup ball animation
            
            self.life.run(waitTimeLife, completion: {
                self.life.run(lifeLostGroup, completion: {
					self.life.run(waitTimeLife, completion: {
						self.life.run(largeLife, completion: {
							self.life.run(resetLifeGroup)
							self.numberOfLives -= 1
							self.livesLabel.text = "x\(self.numberOfLives)"
						})
					})
                })
            })
            // Update number of lives
            
            ball.run(resetBallGroup, completion: {
                self.ball.isHidden = false
                self.ball.run(ballGroup)
            })
            // Animate ball back onto paddle and loss of a life
        }
		
        if numberOfLives == 0 {
            gameoverStatus = true
            gameState.enter(InbetweenLevels.self)
            return
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
            // Stores the 2 bodies, with the body with the lower category being first
			
			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.boarderCategory.rawValue {
				
				if ball.position.x < 0 && xSpeed < 0 {
					xSpeed = -xSpeed
				}
				if ball.position.x > 0 && xSpeed > 0 {
					xSpeed = -xSpeed
				}
				// Ensure the xSpeed is calculated in the correct direction based on the ball position
				
				ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
				// Set the new speed in the x direction
				
				correctBallAngle(correctedAngle: minAngleDeg)
				
			}
			// Ball hits Frame - ensure proper bounce angle (SpriteKit bug means ball slides rather than bounces at shallow angle)

			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.screenBlockCategory.rawValue {
				
				let frameBlockNode = secondBody.node
				let frameBlockSprite = frameBlockNode as! SKSpriteNode
				
				if frameBlockSprite.size.width > frameBlockSprite.size.height {
				// Ball hits top block
					if ySpeed > 0 {
						ySpeed = -ySpeed
					}
					// Ensure the ySpeed is downwards

					ball.physicsBody!.velocity.dy = ySpeed
					// Set the new speed in the y direction
				} else {
				// Ball hits side blocks
					if ball.position.x < 0 && xSpeed < 0 {
						xSpeed = -xSpeed
					}
					if ball.position.x > 0 && xSpeed > 0 {
						xSpeed = -xSpeed
					}
					// Ensure the xSpeed is calculated in the correct direction based on the ball position
					ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
					// Set the new speed in the x direction
					correctBallAngle(correctedAngle: minAngleDeg)
				}
				
			}
		   // Ball hits screenblock - ensure proper bounce angle (SpriteKit bug means ball slides rather than bounces at shallow angle)

            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.brickCategory.rawValue {
                if let brickNode = secondBody.node {
                    hitBrick(node: brickNode, sprite: brickNode as! SKSpriteNode)
                }
            }
            // Ball hits Brick
            
            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.paddleCategory.rawValue {
                paddleHit()
            }
            // Ball hits Paddle
            
            if firstBody.categoryBitMask == CollisionTypes.brickCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.laserCategory.rawValue {
                if let brickNode = firstBody.node {
					hitBrick(node: brickNode, sprite: brickNode as! SKSpriteNode, laserNode: secondBody.node!, laserSprite: (secondBody.node as! SKSpriteNode))
                }
            }
            // Laser hits Brick
			
			if firstBody.categoryBitMask == CollisionTypes.screenBlockCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.laserCategory.rawValue {
				if let laserNode = secondBody.node {
					laserNode.removeFromParent()
                }
            }
            // Laser hits Top
            
            if firstBody.categoryBitMask == CollisionTypes.paddleCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.powerUpCategory.rawValue {
				
				let sprite = secondBody.node! as! SKSpriteNode
				
				applyPowerUp(sprite: sprite)
				
				let scaleUp = SKAction.scale(to: 1.25, duration: 0.05)
				let scaleDown = SKAction.scale(to: 0.5, duration: 0.1)
				let fadeOut = SKAction.fadeOut(withDuration: 0.15)
				let mysteryWait = SKAction.wait(forDuration: 0.1)
				
				var powerupSequence = SKAction.sequence([scaleUp, scaleDown])
				let powerupGroup = SKAction.group([fadeOut, powerupSequence])
				if mysteryPowerUp && sprite.texture != powerUpMystery {
					powerupSequence = SKAction.sequence([mysteryWait, powerupGroup])
				}
				// If the power-up is a mystery power-up, leave the power-up icon lingering for a moment
				
				if sprite.texture == powerUpMystery {
					secondBody.node!.removeFromParent()
				} else {
					secondBody.node!.removeAllActions()
					secondBody.node!.run(powerupGroup, completion: {
						self.mysteryPowerUp = false
						secondBody.node!.removeFromParent()
					})
				}
            }
            // Power-up hits Paddle
        }
    }
    
    func hitBrick(node: SKNode, sprite: SKSpriteNode, laserNode: SKNode? = nil, laserSprite: SKSpriteNode? = nil) {
		
        lightHaptic.impactOccurred()

		if  laserSprite?.texture == laserNormalTexture {
            laserNode?.removeFromParent()
        }
        // Remove laser if super-ball power up isn't activated
		
		if sprite.texture == brickIndestructible2Texture {
			brickBounceCounter+=1
		} else {
			brickBounceCounter = 0
		}
        
        switch sprite.texture {
        case brickNormalTexture:
			if sprite.isHidden {
				let scaleDown = SKAction.scale(to: 1, duration: 0)
                let fadeOut = SKAction.fadeOut(withDuration: 0)
                let resetGroup = SKAction.group([scaleDown, fadeOut])
                let scaleUp = SKAction.scale(to: 1, duration: 0)
                let fadeIn = SKAction.fadeIn(withDuration: 0.2)
                let brickHitGroup = SKAction.group([scaleUp, fadeIn])
                sprite.run(resetGroup, completion: {
                    sprite.isHidden = false
                    sprite.run(brickHitGroup)
                })
			} else {
				removeBrick(node: node, sprite: sprite)
			}
            break
        case brickMultiHit1Texture:
            sprite.texture = brickMultiHit2Texture
            break
        case brickMultiHit2Texture:
            sprite.texture = brickMultiHit3Texture
            break
		case brickMultiHit3Texture:
            sprite.texture = brickMultiHit4Texture
            break
        case brickMultiHit4Texture:
            removeBrick(node: node, sprite: sprite)
            break
		case brickIndestructible1Texture:
			removeBrick(node: node, sprite: sprite)
			sprite.texture = brickIndestructible2Texture
            break
        case brickInvisibleTexture:
            if sprite.isHidden {
                let scaleDown = SKAction.scale(to: 1, duration: 0)
                let fadeOut = SKAction.fadeOut(withDuration: 0)
                let resetGroup = SKAction.group([scaleDown, fadeOut])
                let scaleUp = SKAction.scale(to: 1, duration: 0)
                let fadeIn = SKAction.fadeIn(withDuration: 0.2)
                let brickHitGroup = SKAction.group([scaleUp, fadeIn])
                sprite.run(resetGroup, completion: {
                    sprite.isHidden = false
                    sprite.run(brickHitGroup)
                })
                // Animate bricks in
                break
			} else {
				removeBrick(node: node, sprite: sprite)
			}
            break
        default:
            break
        }
    }
    
    func removeBrick(node: SKNode, sprite: SKSpriteNode) {
		
		bricksLeft = 0
		enumerateChildNodes(withName: BrickCategoryName) { (nodeBrick, _) in
			let spriteBrick = nodeBrick as! SKSpriteNode
			if spriteBrick.texture == self.brickNormalTexture || spriteBrick.texture == self.brickInvisibleTexture || spriteBrick.texture == self.brickMultiHit1Texture || spriteBrick.texture == self.brickMultiHit2Texture || spriteBrick.texture == self.brickMultiHit3Texture || spriteBrick.texture == self.brickMultiHit4Texture || spriteBrick.texture == self.brickIndestructible1Texture || spriteBrick.texture == self.brickMultiHit2Texture {
				self.bricksLeft+=1
			}
		}
		self.bricksLeft-=1 // Don't count this brick as it hasn't been removed yet
		// Count number of removable bricks
		
		powerUpProximity = false
		
		enumerateChildNodes(withName: PowerUpCategoryName) { (nodePowerUp, stop) in
			if sprite.position.y > nodePowerUp.position.y-self.brickWidth*2 && sprite.position.y < nodePowerUp.position.y+self.brickWidth*2 {
				self.powerUpProximity = true
				stop.initialize(to: true)
			}
		}
		
		if powerUpProximity == false {
			let powerUpProb = Int.random(in: 1...powerUpProbFactor)
			if powerUpProb == 1 && bricksLeft > 1 {
				powerUpGenerator(sprite: sprite)
			}
			// probability of getting a power up if brick is removed
		}

		if sprite.texture != brickIndestructible1Texture {
			let waitBrickRemove = SKAction.wait(forDuration: 0.0167*2)
			node.name = BrickRemovalCategoryName
			node.isHidden = true
			node.run(waitBrickRemove, completion: {
				node.removeFromParent()
			})
			// Wait before removing brick to allow ball to bounce off brick correctly - 0.0167 = ~1 frame at 60 fps
		}
		
		if brickRemovalCounter == 9 {
			if multiplier < 10.0 {
				multiplier = multiplier + 0.1
			}
			brickRemovalCounter = 0
		} else {
			brickRemovalCounter+=1
		}
		// Update multiplier
		
        levelScore = levelScore + Int(Double(brickDestroyScore) * multiplier)
        scoreLabel.text = String(totalScore + levelScore)
		scoreFactorString = String(format:"%.1f", multiplier)
		multiplierLabel.text = "x\(scoreFactorString)"
		// Update score
        
        if bricksLeft == 0 {
			levelScore = levelScore + levelCompleteScore
			scoreLabel.text = String(totalScore + levelScore)
            if levelNumber == endLevelNumber {
                gameoverStatus = true
            }
            gameState.enter(InbetweenLevels.self)
			return
        }
        // Loads the next level or ends the game if all bricks have been removed
    }
    
    func paddleHit() {
        lightHaptic.impactOccurred()
        
		brickBounceCounter = 0
		ballRelativePositionOnPaddle = ball.position.x - paddle.position.x
        
		let paddleLeftEdgePosition = paddle.position.x - paddle.size.width/2
		let paddleRightEdgePosition = paddle.position.x + paddle.size.width/2
		
		if ball.position.x > paddleLeftEdgePosition + ball.size.width/2 && ball.position.x < paddleRightEdgePosition - ball.size.width/2 && stickyPaddleCatches != 0 {
			// Catch the ball if the sticky paddle power up is applied and the ball hits the centre of the paddle
            ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
			// Reposition ball within boundries of paddle
            ballIsOnPaddle = true
            paddleMoved = true
            ball.position.y = ballStartingPositionY
            
        } else if ball.position.y - ball.size.width/3 >= paddle.position.y + paddle.size.height/3 && ball.position.x > paddleLeftEdgePosition + ball.size.width/3 && ball.position.x < paddleRightEdgePosition - ball.size.width/3 {
            // Only apply if the ball hits the paddles top flat surface
				
			let collisionPercentage = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
			// Define collision position between the ball and paddle
			let ySpeedCorrected: Double = sqrt(Double(ySpeed*ySpeed))
			// Assumes the ball's ySpeed is always positive
			var angleRad = atan2(Double(ySpeedCorrected), Double(xSpeed))
			// Angle of the ball
			
			angleRad = angleRad - ((angleAdjustmentK*Double.pi/180)*collisionPercentage)
			// Angle adjustment formula - the ball's angle can change up to angleAdjustmentK deg depending on where the ball hits the paddle
 
			angleRad = angleRad + Double.random(in: (-5*Double.pi/180)...5*Double.pi/180)
			// Adds a small element of randomness into the ball's angle - between -5 and 5 degrees
			
			if angleRad < (minAngleDeg*2 * Double.pi / 180) {
				angleRad = (minAngleDeg*2 * Double.pi / 180)
			}
			if angleRad > (maxAngleDeg*2 * Double.pi / 180) {
				angleRad = (maxAngleDeg*2 * Double.pi / 180)
			}
			// Limits the angle off of the paddle to 2* the min & max ball angles
						   
			xSpeed = CGFloat(cos(angleRad)) * currentSpeed
			ySpeed = CGFloat(sin(angleRad)) * currentSpeed
			ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
			// Set the new speed and angle of the ball
        }
    }
    
    func powerUpGenerator (sprite: SKSpriteNode) {
		
		if powerUpsOnScreen >= powerUpLimit {
			return
		}
		// Limit number of power-ups available at once
        
        let powerUp = SKSpriteNode(imageNamed: "PowerUpPreSet")
        
		powerUp.size.width = brickWidth*0.85
        powerUp.size.height = powerUp.size.width
        powerUp.position = CGPoint(x: sprite.position.x, y: sprite.position.y)
        powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.frame.size)
        powerUp.physicsBody!.allowsRotation = false
        powerUp.physicsBody!.friction = 0.0
        powerUp.physicsBody!.affectedByGravity = false
        powerUp.physicsBody!.isDynamic = false
		powerUp.physicsBody!.mass = 0
        powerUp.name = PowerUpCategoryName
        powerUp.physicsBody!.categoryBitMask = CollisionTypes.powerUpCategory.rawValue
		powerUp.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
		powerUp.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
        powerUp.zPosition = 2
        addChild(powerUp)
        
		let powerUpProb = Int.random(in: 0...22)
        switch powerUpProb {
        case 0:
		// Get a life			
            powerUp.texture = powerUpGetALife
        case 1:
		// Decrease ball speed
            powerUp.texture = powerUpDecreaseBallSpeed
        case 2:
		// Superball
            powerUp.texture = powerUpSuperBall
        case 3:
		// Sticky paddle
            powerUp.texture = powerUpStickyPaddle
        case 4:
		// Next level
            powerUp.texture = powerUpNextLevel
        case 5:
		// Increase paddle size
            powerUp.texture = powerUpIncreasePaddleSize
        case 6:
		// Invisible bricks become visible
			powerUp.texture = self.powerUpShowInvisibleBricks
			var hiddenNodeFound = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				if node.isHidden == true {
					hiddenNodeFound = true
					stop.initialize(to: true)
				}
			}
			if hiddenNodeFound == false {
				powerUpsOnScreen-=1
				self.powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if no invisible/hidden bricks
        case 7:
			// Lasers
            powerUp.texture = powerUpLasers
			
		case 8:
		// Remove indestructible bricks
			powerUp.texture = powerUpRemoveIndestructibleBricks
			var indestructibleNodeFound = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickIndestructible2Texture || sprite.texture == self.brickIndestructible1Texture {
					indestructibleNodeFound = true
					stop.initialize(to: true)
				}
			}
			if indestructibleNodeFound == false {
				powerUpsOnScreen-=1
				self.powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if no indestructible bricks
		case 9:
		// Multi-hit bricks become normal bricks
			powerUp.texture = powerUpMultiHitToNormalBricks
			var multiNodeFound = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickMultiHit1Texture || sprite.texture == self.brickMultiHit2Texture {
					multiNodeFound = true
					stop.initialize(to: true)
				}
			}
			if multiNodeFound == false {
				powerUpsOnScreen-=1
				self.powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if no multi-hit bricks
        case 10:
		// Lose a life
			if numberOfLives > 0 {
				powerUp.texture = powerUpLoseALife
			} else {
				powerUpsOnScreen-=1
				powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if on last life
        case 11:
		// Increase ball speed
            powerUp.texture = powerUpIncreaseBallSpeed
        case 12:
		// Undestructi-ball
            powerUp.texture = powerUpUndestructiBall
		case 13:
		// Decrease paddle size
			powerUp.texture = powerUpDecreasePaddleSize
		case 14:
		// x2 multiplier
			if multiplier < 10 {
				powerUp.texture = powerUpMultiplier
			} else {
				powerUpsOnScreen-=1
				powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if multiplier at 10 or above
		case 15:
		// Bonus points
			powerUp.texture = powerUpPointsBonus
		case 16:
		// Penalty points
			if levelScore >= 0 {
				powerUp.texture = powerUpPointsPenalty
			} else {
				powerUpsOnScreen-=1
				powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if score is less than 0
		case 17:
		// Normal bricks become invisble bricks
			powerUp.texture = powerUpNormalToInvisibleBricks
			var normalNodeFound = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickNormalTexture {
					normalNodeFound = true
					stop.initialize(to: true)
				}
			}
			if normalNodeFound == false {
				powerUpsOnScreen-=1
				self.powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if no normal bricks
		case 18:
		// Multi-hit bricks reset
			powerUp.texture = powerUpMultiHitBricksReset
			var multiHitBrickFound = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickMultiHit2Texture || sprite.texture == self.brickMultiHit3Texture || sprite.texture == self.brickMultiHit4Texture {
					multiHitBrickFound = true
					stop.initialize(to: true)
				}
			}
			if multiHitBrickFound == false {
				powerUpsOnScreen-=1
				self.powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if no multi-hit bricks that have been hit
		case 19:
		// Gravity ball
			powerUp.texture = powerUpGravityBall
		case 20:
		// Mystery power-up
			powerUp.texture = powerUpMystery
		case 21:
		// Multiplier reset
			if multiplier <= 1 {
				powerUpsOnScreen-=1
				powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			} else {
				powerUp.texture = powerUpMultiplierReset
			}
			// Don't show if multiplier is 1
		case 22:
		// Move all bricks down 2 rows
			powerUp.texture = powerUpBricksDown
			var bricksAtBottom = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				if node.position.y < self.paddle.position.y + self.minPaddleGap {
					bricksAtBottom = true
					stop.initialize(to: true)
				}
			}
			if bricksAtBottom {
				powerUpsOnScreen-=1
				powerUpGenerator (sprite: sprite)
				powerUp.removeFromParent()
			}
			// Don't show if bricks are already at lowest point
        default:
            break
        }
        
        let move = SKAction.moveBy(x: 0, y: -frame.height, duration: 10)
		powerUp.run(move)
    }
    
    func applyPowerUp (sprite: SKSpriteNode) {
		
		if ballLostBool {
			return
		}
        
		rigidHaptic.impactOccurred()
		
        switch sprite.texture {
            
        case powerUpGetALife:
        // Get a life
            numberOfLives+=1
            livesLabel.text = "x\(numberOfLives)"
			
			life.removeAllActions()
			
			let scaleUp = SKAction.scale(to: 1.75, duration: 0.1)
			let scaleDown = SKAction.scale(to: 1, duration: 0.15)
			let newLifeSequence = SKAction.sequence([scaleUp, scaleDown])
			life.run(newLifeSequence)
            powerUpScore = 50
			powerUpMultiplierScore = 0.1
            
        case powerUpLoseALife:
        // Lose a life
			ball.physicsBody!.linearDamping = 2
            ballLostAnimation()
            self.run(SKAction.wait(forDuration: 0.2), completion: {
                self.ballLost()
            })
            powerUpScore = 0
			powerUpMultiplierScore = 0
            
        case powerUpDecreaseBallSpeed:
        // Decrease ball speed
			removeAction(forKey: "powerUpDecreaseBallSpeed")
			removeAction(forKey: "powerUpIncreaseBallSpeed")
			removeAction(forKey: "powerUpDecreaseBallSpeedTimer")
			removeAction(forKey: "ballSpeedTimer")
			// Remove any current ball speed power up timers
			ballSpeedIcon.texture = self.iconDecreaseBallSpeedTexture
			ballSpeedIconBar.isHidden = false
			// Show power-up icon timer
			if ballSpeedLimit == ballSpeedNominal {
				ballSpeedLimit = ballSpeedSlow
			} else if ballSpeedLimit < ballSpeedNominal {
				ballSpeedLimit = ballSpeedSlowest
			} else if ballSpeedLimit > ballSpeedNominal {
				ballSpeedLimit = ballSpeedNominal
				ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				ballSpeedIconBar.isHidden = true
			}
            powerUpScore = 50
			powerUpMultiplierScore = 0.1
			// Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.ballSpeedLimit = self.ballSpeedNominal
				self.ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				self.ballSpeedIconBar.isHidden = true
				// Hide power-up icons
            }
			ballSpeedIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.ballSpeedIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "ballSpeedTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			ballSpeedIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpDecreaseBallSpeedTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpDecreaseBallSpeed")
            // Power up reverted
            
        case powerUpIncreaseBallSpeed:
        // Increase ball speed
			removeAction(forKey: "powerUpDecreaseBallSpeed")
			removeAction(forKey: "powerUpIncreaseBallSpeed")
			removeAction(forKey: "powerUpDecreaseBallSpeedTimer")
			removeAction(forKey: "ballSpeedTimer")
			// Remove any current ball speed power up timers
			ballSpeedIcon.texture = self.iconIncreaseBallSpeedTexture
			ballSpeedIconBar.isHidden = false
			// Show power-up icon timer
			if ballSpeedLimit == ballSpeedNominal {
				ballSpeedLimit = ballSpeedFast
			} else if ballSpeedLimit > ballSpeedNominal {
				ballSpeedLimit = ballSpeedFastest
			} else if ballSpeedLimit < ballSpeedNominal {
				ballSpeedLimit = ballSpeedNominal
				ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				ballSpeedIconBar.isHidden = true
			}
            powerUpScore = -50
			powerUpMultiplierScore = -0.1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.ballSpeedLimit = self.ballSpeedNominal
				self.ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				self.ballSpeedIconBar.isHidden = true
				// Hide power-up icons
            }
			ballSpeedIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.ballSpeedIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "ballSpeedTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			ballSpeedIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpDecreaseBallSpeedTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpIncreaseBallSpeed")
            // Power up reverted

        case powerUpSuperBall:
        // Superball
			removeAction(forKey: "powerUpSuperBall")
			removeAction(forKey: "powerUpUndestructiBall")
			removeAction(forKey: "powerUpSuperBallTimer")
			removeAction(forKey: "superballTimer")
			// Remove any animations and timers
			superballIcon.texture = self.iconSuperballTexture
			superballIconBar.isHidden = false
			// Show power-up icon timer
            ball.texture = superballTexture
            ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            // Reset undestructi-ball power up
            ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            powerUpScore = 50
			powerUpMultiplierScore = 0.1
			powerUpLimit = 4
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				self.ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				self.ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
                self.ball.texture = self.ballTexture
				self.powerUpLimit = 2
				self.superballIcon.texture = self.iconSuperballDisabledTexture
				self.superballIconBar.isHidden = true
				// Hide power-up icons
            }
			superballIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.superballIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "superballTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			superballIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpSuperBallTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpSuperBall")
            // Power up reverted
            
        case powerUpUndestructiBall:
        // Undestructi-ball
            removeAction(forKey: "powerUpSuperBall")
			removeAction(forKey: "powerUpUndestructiBall")
			removeAction(forKey: "powerUpSuperBallTimer")
			removeAction(forKey: "superballTimer")
			// Remove any animations and timers
			superballIcon.texture = self.iconUndestructiballTexture
			superballIconBar.isHidden = false
			// Show power-up icon timer
            ball.texture = undestructiballTexture
            ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
            // Reset super-ball power up
            ball.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
			powerUpLimit = 2
            powerUpScore = -50
			powerUpMultiplierScore = -0.1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
                self.ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue
                self.ball.texture = self.ballTexture
				self.superballIcon.texture = self.iconSuperballDisabledTexture
				self.superballIconBar.isHidden = true
				// Hide power-up icons
            }
			superballIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.superballIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "superballTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			superballIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpSuperBallTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpUndestructiBall")
            // Power up reverted

        case powerUpStickyPaddle:
        // Sticky paddle
			stickyPaddleIcon.texture = self.iconStickyPaddleTexture
			stickyPaddleIconBar.isHidden = false
			// Show power-up icon timer
			stickyPaddleIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05))
            stickyPaddleCatches = 5 + Int(Double(multiplier))
			stickyPaddleCatchesTotal = stickyPaddleCatches
            powerUpScore = 50
			powerUpMultiplierScore = 0.1
			paddleSticky.isHidden = false
            // Power up set and limit number of catches per power up
            
        case powerUpNextLevel:
        // Next level
            powerUpScore = 50
			powerUpMultiplierScore = 0
			levelScore = levelScore + Int(Double(powerUpScore) * multiplier)
			scoreLabel.text = String(totalScore + levelScore)
            if levelNumber == endLevelNumber {
                gameoverStatus = true
            }
            gameState.enter(InbetweenLevels.self)
			return

        case powerUpIncreasePaddleSize:
        // Increase paddle size
			removeAction(forKey: "powerUpIncreasePaddleSize")
			removeAction(forKey: "powerUpDecreasePaddleSize")
			removeAction(forKey: "powerUpPaddleSizeTimer")
			removeAction(forKey: "paddleSizeTimer")
			// Remove any current ball speed power up timers
			paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
			paddleSizeIconBar.isHidden = false
			// Show power-up icon timer
			paddle.centerRect = CGRect(x: 10.0/80.0, y: 0.0/10.0, width: 60.0/80.0, height: 10.0/10.0)
			paddleLaser.centerRect = CGRect(x: 10.0/80.0, y: 0.0/16.0, width: 60.0/80.0, height: 16.0/16.0)
			paddleSticky.centerRect = CGRect(x: 10.0/80.0, y: 0.0/11.0, width: 60.0/80.0, height: 11.0/11.0)
			// Ensure good scaling of paddles
			if paddle.xScale < 1.0 {
				paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				paddleSizeIconBar.isHidden = true
				paddle.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleLaser.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.0, duration: 0.2))
			} else if paddle.xScale == 1.0 {
				paddle.run(SKAction.scaleX(to: 1.5, duration: 0.2))
				paddleLaser.run(SKAction.scaleX(to: 1.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.5, duration: 0.2))
			} else if paddle.xScale == 1.5 {
				paddle.run(SKAction.scaleX(to: 2.0, duration: 0.2))
				paddleLaser.run(SKAction.scaleX(to: 2.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 2.0, duration: 0.2))
			} else if paddle.xScale == 2.0 || paddle.xScale == 2.5 {
				paddle.run(SKAction.scaleX(to: 2.5, duration: 0.2))
				paddleLaser.run(SKAction.scaleX(to: 2.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 2.5, duration: 0.2))
			}
			// Resize paddle based on its current size
            powerUpScore = 50
			powerUpMultiplierScore = 0.1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				self.paddle.centerRect = CGRect(x: 10.0/80.0, y: 0.0/10.0, width: 60.0/80.0, height: 10.0/10.0)
				self.paddleLaser.centerRect = CGRect(x: 10.0/80.0, y: 0.0/16.0, width: 60.0/80.0, height: 16.0/16.0)
				self.paddleSticky.centerRect = CGRect(x: 10.0/80.0, y: 0.0/11.0, width: 60.0/80.0, height: 11.0/11.0)
                self.rigidHaptic.impactOccurred()
				self.paddle.run(SKAction.scaleX(to: 1, duration: 0.2), completion: {
					self.recentreBall()
				})
				self.paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				self.paddleSizeIconBar.isHidden = true
				// Hide power-up icons
            }
			paddleSizeIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.paddleSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "paddleSizeTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			paddleSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpPaddleSizeTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpIncreasePaddleSize")
            // Power up reverted
            
        case powerUpDecreasePaddleSize:
        // Decrease paddle size
			removeAction(forKey: "powerUpDecreasePaddleSize")
			removeAction(forKey: "powerUpIncreasePaddleSize")
			removeAction(forKey: "powerUpPaddleSizeTimer")
			removeAction(forKey: "paddleSizeTimer")
			// Remove any current ball speed power up timers
			paddleSizeIcon.texture = self.iconDecreasePaddleSizeTexture
			paddleSizeIconBar.isHidden = false
			// Show power-up icon timer
			paddle.centerRect = CGRect(x: 10.0/80.0, y: 0.0/10.0, width: 60.0/80.0, height: 10.0/10.0)
			paddleLaser.centerRect = CGRect(x: 10.0/80.0, y: 0.0/16.0, width: 60.0/80.0, height: 16.0/16.0)
			paddleSticky.centerRect = CGRect(x: 10.0/80.0, y: 0.0/11.0, width: 60.0/80.0, height: 11.0/11.0)
			// Ensure good scaling of paddles
			if paddle.xScale < 1.0 {
				paddle.run(SKAction.scaleX(to: 0.5, duration: 0.2), completion: {
					self.recentreBall()
				})
				paddleLaser.run(SKAction.scaleX(to: 0.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 0.5, duration: 0.2))
			} else if paddle.xScale == 1.0 {
				paddle.run(SKAction.scaleX(to: 0.75, duration: 0.2), completion: {
					self.recentreBall()
				})
				paddleLaser.run(SKAction.scaleX(to: 0.75, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 0.75, duration: 0.2))
			} else if paddle.xScale > 1.0 {
				paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				paddleSizeIconBar.isHidden = true
				paddle.run(SKAction.scaleX(to: 1.0, duration: 0.2), completion: {
					self.recentreBall()
				})
				paddleLaser.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.0, duration: 0.2))
			}
			// Resize paddle based on its current size
			
            powerUpScore = -50
			powerUpMultiplierScore = -0.1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				self.paddle.centerRect = CGRect(x: 10.0/80.0, y: 0.0/10.0, width: 60.0/80.0, height: 10.0/10.0)
				self.paddleLaser.centerRect = CGRect(x: 10.0/80.0, y: 0.0/16.0, width: 60.0/80.0, height: 16.0/16.0)
				self.paddleSticky.centerRect = CGRect(x: 10.0/80.0, y: 0.0/11.0, width: 60.0/80.0, height: 11.0/11.0)
                self.rigidHaptic.impactOccurred()
                self.paddle.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				self.paddleSizeIconBar.isHidden = true
				// Hide power-up icons
            }
			paddleSizeIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.paddleSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "paddleSizeTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			paddleSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpPaddleSizeTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpDecreasePaddleSize")
            // Power up reverted
			
        case powerUpLasers:
        // Lasers
			removeAction(forKey: "powerUpLasers")
			removeAction(forKey: "powerUpLaserTimer")
			removeAction(forKey: "laserTimer")
			laserTimer?.invalidate()
			// Remove any current animations and timers
			lasersIcon.texture = self.iconLasersTexture
			lasersIconBar.isHidden = false
			// Show power-up icon timer
            laserPowerUpIsOn = true
			paddleLaser.isHidden = false
            laserTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(laserGenerator), userInfo: nil, repeats: true)
			powerUpScore = 50
			powerUpMultiplierScore = 0.1
			powerUpLimit = 4
            // Power up set - lasers will fire every 0.1s
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
                self.laserTimer?.invalidate()
				self.paddleLaser.isHidden = true
				self.laserPowerUpIsOn = false
				self.powerUpLimit = 2
				self.lasersIcon.texture = self.iconLasersDisabledTexture
				self.lasersIconBar.isHidden = true
				// Hide power-up icons
            }
			lasersIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.lasersIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "laserTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			lasersIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpLaserTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpLasers")
            // Power up reverted - lasers will fire for 10s
			
		case powerUpShowInvisibleBricks:
		// Invisible bricks become visible
			removeAction(forKey: "powerUpInvisibleBricks")
			removeAction(forKey: "invisibleBricksTimer")
			// Remove any animations and timers
			hiddenBricksIcon.texture = iconHiddenBlocksDisabledTexture
			hiddenBricksIconBar.isHidden = true
			// Show power-up icon timer for invisible bricks
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				if node.isHidden == true {
					let startingScale = SKAction.scale(to: 1, duration: 0)
					let startingFade = SKAction.fadeOut(withDuration: 0)
					let scaleUp = SKAction.scale(to: 1, duration: 0)
					let fadeIn = SKAction.fadeIn(withDuration: 0.2)
					let startingGroup = SKAction.group([startingFade, startingScale])
					let brickGroup = SKAction.group([scaleUp, fadeIn])
					node.run(startingGroup, completion: {
						node.isHidden = false
						node.run(brickGroup)
					})
				}
			}
			powerUpScore = 50
			powerUpMultiplierScore = 0.1
			// Power up set
			
		case powerUpRemoveIndestructibleBricks:
		// Remove indestructible bricks
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickIndestructible2Texture || temporarySprite.texture == self.brickIndestructible1Texture {
					node.removeFromParent()
				}
			}
			powerUpScore = 50
			powerUpMultiplierScore = 0.1
			// Power up set
			bricksLeft = 0
			enumerateChildNodes(withName: BrickCategoryName) { (nodeBrick, _) in
				let spriteBrick = nodeBrick as! SKSpriteNode
				if spriteBrick.texture == self.brickNormalTexture || spriteBrick.texture == self.brickInvisibleTexture || spriteBrick.texture == self.brickMultiHit1Texture || spriteBrick.texture == self.brickMultiHit2Texture || spriteBrick.texture == self.brickMultiHit3Texture || spriteBrick.texture == self.brickMultiHit4Texture || spriteBrick.texture == self.brickIndestructible1Texture || spriteBrick.texture == self.brickMultiHit2Texture {
					self.bricksLeft+=1
				}
			}
			if bricksLeft == 0 {
				levelScore = levelScore + levelCompleteScore
				scoreLabel.text = String(totalScore + levelScore)
				if levelNumber == endLevelNumber {
					gameoverStatus = true
				}
				gameState.enter(InbetweenLevels.self)
				return
			}
			// If the last active brick has been removed, end the level
			
		case powerUpMultiHitToNormalBricks:
		// Multi-hit bricks become normal bricks
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickMultiHit1Texture || temporarySprite.texture == self.brickMultiHit2Texture || temporarySprite.texture == self.brickMultiHit3Texture {
					temporarySprite.texture = self.brickMultiHit4Texture
				}
			}
			powerUpScore = 50
			powerUpMultiplierScore = 0.1
			// Power up set
		
		case powerUpMultiplier:
		// Multiplier
			removeAction(forKey: "multiplierAnimation")
			multiplier = multiplier*2
			powerUpScore = 50
			powerUpMultiplierScore = 0
			multiplierLabel.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "multiplierAnimation")
			// Power up set
			
		case powerUpPointsBonus:
		// 100 points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = 1000
			powerUpMultiplierScore = 0.1
			scoreLabel.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpPointsPenalty:
		// -100 points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = -1000
			powerUpMultiplierScore = -0.1
			scoreLabel.run(SKAction.sequence([pointsScaleDown, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpNormalToInvisibleBricks:
		// Normal bricks become invisble bricks
			removeAction(forKey: "powerUpInvisibleBricks")
			removeAction(forKey: "invisibleBricksTimer")
			removeAction(forKey: "powerUpHiddenBricksTimer")
			// Remove any animations and timers
			hiddenBricksIcon.texture = self.iconHiddenBlocksTexture
			hiddenBricksIconBar.isHidden = false
			// Show power-up icon timer
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickNormalTexture || temporarySprite.texture == self.brickInvisibleTexture {
					temporarySprite.isHidden = true
				}
			}
			powerUpScore = -50
			powerUpMultiplierScore = -0.1
			// Power up set
			let timer: Double = 10 * multiplier
			let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
					let temporarySprite = node as! SKSpriteNode
					if node.isHidden == true && temporarySprite.texture == self.brickNormalTexture {
						let startingScale = SKAction.scale(to: 1, duration: 0)
						let startingFade = SKAction.fadeOut(withDuration: 0)
						let scaleUp = SKAction.scale(to: 1, duration: 0)
						let fadeIn = SKAction.fadeIn(withDuration: 0.2)
						let startingGroup = SKAction.group([startingFade, startingScale])
						let brickGroup = SKAction.group([scaleUp, fadeIn])
						node.run(startingGroup, completion: {
							node.isHidden = false
							node.run(brickGroup)
						})
					}
				}
				self.hiddenBricksIcon.texture = self.iconHiddenBlocksDisabledTexture
				self.hiddenBricksIconBar.isHidden = true
			}
			hiddenBricksIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.hiddenBricksIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "invisibleBricksTimer")
			})
			let sequence = SKAction.sequence([waitDuration, completionBlock])
			hiddenBricksIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpHiddenBricksTimer")
			// Setup timer animation
			self.run(sequence, withKey: "powerUpInvisibleBricks")
			// Power up reverted
			
		case powerUpMultiHitBricksReset:
		// Multi-hit bricks reset
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickMultiHit2Texture || temporarySprite.texture == self.brickMultiHit3Texture || temporarySprite.texture == self.brickMultiHit4Texture {
					temporarySprite.texture = self.brickMultiHit1Texture
				}
			}
			powerUpScore = -50
			powerUpMultiplierScore = -0.1
			// Power up set
			
		case powerUpGravityBall:
		// Gravity ball
			removeAction(forKey: "powerUpGravityBall")
			removeAction(forKey: "gravityTimer")
			removeAction(forKey: "powerUpGravityTimer")
			// Remove any current ball speed power up timers
			gravityIcon.texture = self.iconGravityTexture
			gravityIconBar.isHidden = false
			// Show power-up icon timer
			physicsWorld.gravity = CGVector(dx: 0, dy: -1)
			ball.physicsBody!.affectedByGravity = true
			gravityActivated = true
			powerUpScore = -50
			powerUpMultiplierScore = -0.1
			// Power up set
			let timer: Double = 10 * multiplier
			let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
				self.ball.physicsBody!.affectedByGravity = false
				self.gravityActivated = false
				self.gravityIcon.texture = self.iconGravityDisabledTexture
				self.gravityIconBar.isHidden = true
				// Hide power-up icons
			}
			gravityIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.gravityIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "gravityTimer")
			})
			let sequence = SKAction.sequence([waitDuration, completionBlock])
			gravityIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpGravityTimer")
			// Setup timer animation
			self.run(sequence, withKey: "powerUpGravityBall")
			// Power up reverted
			
		case powerUpMystery:
		// Mystery power-up
			powerUpScore = 0
			powerUpMultiplierScore = 0
			powerUpsOnScreen-=1
			mysteryPowerUp = true
			powerUpGenerator (sprite: sprite)
			
		case powerUpMultiplierReset:
		// Mutliplier reset to 1
			removeAction(forKey: "multiplierAnimation")
			multiplier = 1
			brickRemovalCounter = 0
			powerUpScore = -50
			powerUpMultiplierScore = 0
			multiplierLabel.run(SKAction.sequence([pointsScaleDown, timerScaleDown]), withKey: "multiplierAnimation")
			
		case powerUpBricksDown:
		// Move all bricks down
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let brickSprite = node as! SKSpriteNode
				let moveBricksDown = SKAction.moveBy(x: 0, y: -brickSprite.size.height*2, duration: 0.5)
				moveBricksDown.timingMode = .easeInEaseOut
				node.run(moveBricksDown)
			}
			powerUpScore = -50
			powerUpMultiplierScore = -0.1

        default:
            break
        }
        // Identify power up and perform action

        levelScore = levelScore + Int(Double(powerUpScore) * multiplier)
		multiplier = multiplier + powerUpMultiplierScore
		if multiplier < 1 {
			multiplier = 1
		} else if multiplier > 10 {
			multiplier = 10
		}
		// Ensure multiplier never goes below 1 or above 10
        scoreLabel.text = String(totalScore + levelScore)
		scoreFactorString = String(format:"%.1f", multiplier)
		multiplierLabel.text = "x\(scoreFactorString)"
        // Update score
    }
    
    func powerUpsReset() {
        self.removeAllActions()
        // Stop all timers and animations
       
        
		ball.physicsBody!.linearDamping = ballLinearDampening
		powerUpLimit = 2
		
		ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
		ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
		ball.texture = ballTexture
		superballIcon.texture = iconSuperballDisabledTexture
		superballIconBar.isHidden = true
		// Superball/Undestructiball reset
		
		paddle.centerRect = CGRect(x: 0.0/80.0, y: 0.0/10.0, width: 80.0/80.0, height: 10.0/10.0)
		paddleLaser.centerRect = CGRect(x: 0.0/80.0, y: 0.0/16.0, width: 80.0/80.0, height: 16.0/16.0)
		paddleSticky.centerRect = CGRect(x: 0.0/80.0, y: 0.0/11.0, width: 80.0/80.0, height: 11.0/11.0)
		// Ensure good scaling of paddles
		paddle.run(SKAction.scaleX(to: 1, duration: 0.2))
		paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
		paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
		paddleSizeIcon.texture = iconPaddleSizeDisabledTexture
		paddleSizeIconBar.isHidden = true
		// Paddle size reset
		
		ballSpeedLimit = ballSpeedNominal
		ballSpeedIcon.texture = iconBallSpeedDisabledTexture
		ballSpeedIconBar.isHidden = true
		// Ball speed reset
		
		laserTimer?.invalidate()
		lasersIcon.texture = iconLasersDisabledTexture
		paddleLaser.isHidden = true
		lasersIconBar.isHidden = true
		laserPowerUpIsOn = false
		// Laser reset
		
		physicsWorld.gravity = CGVector(dx: 0, dy: 0)
		ball.physicsBody!.affectedByGravity = false
		gravityActivated = false
		gravityIcon.texture = iconGravityDisabledTexture
		gravityIconBar.isHidden = true
		// Gravity reset
		
		paddleSticky.isHidden = true
		stickyPaddleCatches = 0
		stickyPaddleCatchesTotal = 0
		stickyPaddleIcon.texture = iconStickyPaddleDisabledTexture
		stickyPaddleIconBar.isHidden = true
		stickyPaddleIconBar.xScale = 0
		// Sticky paddle reset
		
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			let temporarySprite = node as! SKSpriteNode
			if node.isHidden == true && temporarySprite.texture == self.brickNormalTexture {
				let startingScale = SKAction.scale(to: 1, duration: 0)
				let startingFade = SKAction.fadeOut(withDuration: 0)
				let scaleUp = SKAction.scale(to: 1, duration: 0)
				let fadeIn = SKAction.fadeIn(withDuration: 0.2)
				let startingGroup = SKAction.group([startingFade, startingScale])
				let brickGroup = SKAction.group([scaleUp, fadeIn])
				node.run(startingGroup, completion: {
					node.isHidden = false
					node.run(brickGroup)
				})
			}
		}
		hiddenBricksIcon.texture = iconHiddenBlocksDisabledTexture
		hiddenBricksIconBar.isHidden = true
		// Invisible bricks reset
		
		// Remove any existing power-up icons and timers
    }
    
    func moveToMainMenu() {
		gameViewControllerDelegate?.moveToMainMenu(currentHighscore: totalScoreArray.max()!)
    }
    // Function to return to the MainViewController from the GameViewController, run as a delegate from GameViewController
    
    func showEndLevelStats() {
        gameViewControllerDelegate?.showEndLevelStats(levelNumber: levelNumber, levelScore: levelScore, levelHighscore: levelHighscore, totalScore: totalScore, totalHighscore: totalHighscore, gameoverStatus: gameoverStatus)
    }
	
	func showPauseMenu() {
		let pauseMenuScore = totalScore + levelScore
		totalHighscore = totalScoreArray.max()!
		gameViewControllerDelegate?.showPauseMenu(levelNumber: levelNumber, score: pauseMenuScore, highscore: totalHighscore)
    }
	
	func createInterstitial() {
		gameViewControllerDelegate?.createInterstitial()
	}
	// Setup interstitial ad
	
	func loadInterstitial() {
		gameViewControllerDelegate?.loadInterstitial()
	}
	// Show interstitial ad

	func recentreBall() {
		if ballIsOnPaddle {
			if ball.position.x - ball.size.width/2 < paddle.position.x - paddle.size.width/2 {
				ball.position.x = paddle.position.x - paddle.size.width/2 + ball.size.width/2
			} else if ball.position.x + ball.size.width/2 > paddle.position.x + paddle.size.width/2 {
				ball.position.x = paddle.position.x + paddle.size.width/2 - ball.size.width/2
			}
		}
	}
	// Recentre ball if it isn't on smaller paddle
	
	func correctBallAngle(correctedAngle: Double) {
		
		var angleRad = Double(atan2(ySpeed, xSpeed))
		var angleDeg = Double(angleRad)/Double.pi*180
		
		if correctedAngle < minAngleDeg {
			if angleDeg < correctedAngle && angleDeg > -correctedAngle {
				angleDeg = -correctedAngle
			}
			else if angleDeg > 180-correctedAngle || angleDeg < -180+correctedAngle {
				angleDeg = -180+correctedAngle
			}
		} else {
			if angleDeg < correctedAngle && angleDeg > 0 {
				angleDeg = correctedAngle
			}
			else if angleDeg > 180-correctedAngle && angleDeg <= 180 {
				angleDeg = 180-correctedAngle
			}
			else if angleDeg < -180+correctedAngle && angleDeg >= -180 {
				angleDeg = -180+correctedAngle
			}
			else if angleDeg > -correctedAngle && angleDeg <= 0 {
				angleDeg = -correctedAngle
			}
		}
		
		if ((angleDeg <= correctedAngle && angleDeg >= -correctedAngle) || (angleDeg > 180-correctedAngle && angleDeg <= 180) || (angleDeg < -180+correctedAngle && angleDeg >= -180)) && ball.position.y < paddle.position.y + ballSize*2 {
			angleDeg = minAngleDeg
		}
		
		// check ball x-angle
		angleRad = (angleDeg*Double.pi/180)
		xSpeed = CGFloat(cos(angleRad)) * currentSpeed
		ySpeed = CGFloat(sin(angleRad)) * currentSpeed
		ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
		// Set the new angle of the ball
	}
    // Ensure ball angle when hitting off of wals
	
    @objc func laserGenerator() {
		
		if gameState.currentState is Playing {
        
			let laser = SKSpriteNode(imageNamed: "LaserNormal")
			
			laser.size.width = layoutUnit/4
			laser.size.height = laser.size.width*4
			
			if laserSideLeft {
				laser.position = CGPoint(x: paddle.position.x - paddle.size.width/2 + laser.size.width, y: paddle.position.y + paddleLaser.size.height/2 + laser.size.height/2)
				laser.texture = laserNormalTexture
				laserSideLeft = false
				// Left position
			} else {
				laser.position = CGPoint(x: paddle.position.x + paddle.size.width/2  - laser.size.width, y: paddle.position.y + paddleLaser.size.height/2 + laser.size.height/2)
				laser.texture = laserNormalTexture
				laserSideLeft = true
				// Right position
			}
			// Alternate position of laser on paddle
			
			laser.physicsBody = SKPhysicsBody(rectangleOf: laser.frame.size)
			laser.physicsBody!.allowsRotation = false
			laser.physicsBody!.friction = 0.0
			laser.physicsBody!.affectedByGravity = false
			laser.physicsBody!.isDynamic = true
			laser.name = LaserCategoryName
			laser.physicsBody!.categoryBitMask = CollisionTypes.laserCategory.rawValue
			laser.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue
			laser.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue
			laser.zPosition = 2
			// Define laser properties
			
			if ball.texture == superballTexture {
				laser.physicsBody!.collisionBitMask = 0
				laser.texture = superLaserTexture
			}
			// if super-ball power up is activated, allow laser to pass through bricks
			
			addChild(laser)
			
			let move = SKAction.moveBy(x: 0, y: frame.height, duration: 2)
			laser.run(move, completion: {
				laser.removeFromParent()
			})
			// Define laser movement
		}
    }
    
    @objc func pauseNotificationKeyReceived() {
        gameState.enter(Paused.self)
    }
    // Pause the game if a notifcation from AppDelegate is received that the game will quit
	
//	@objc func doubleTapped() {
//		gameState.enter(Paused.self)
//	}
//	// Function to perform when double tap gesture recognised
	
	@objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
		gameState.enter(Paused.self)
	}

}

extension Notification.Name {
    public static let pauseNotificationKey = Notification.Name(rawValue: "pauseNotificationKey")
}
// Setup for notifcation from AppDelegate

//MARK: - Action List
/***************************************************************/

//TODO: - [Name Of To Do]

//FIXME: - [Name Of Fix Me]

//ERROR: [Name Of Error]

//!!!: - [Name Of Issue]

//???: - [Name Of Issue]


