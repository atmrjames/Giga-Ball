//
//  GameScene.swift
//  Megaball
//
//  Created by James Harding on 18/08/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit
import GameKit
//import GameKit

let PaddleCategoryName = "paddle"
let BallCategoryName = "ball"
let BrickCategoryName = "brick"
let BrickRemovalCategoryName = "brickRemoval"
let PowerUpCategoryName = "powerUp"
let LaserCategoryName = "laser"
let PowerIconCategoryName = "powerUpIcon"
let BackstopCategoryName = "backStop"
// Set up for categoryNames

enum CollisionTypes: UInt32 {
    case ballCategory = 1
    case brickCategory = 2
    case paddleCategory = 4
	case screenBlockCategory = 8
    case powerUpCategory = 16
    case laserCategory = 32
	case boarderCategory = 64
	case bottomScreenBlockCategory = 128
	case backstopCategory = 256
}
// Setup for collisionBitMask

//The categoryBitMask property is a number defining the type of object this is for considering collisions.
//The collisionBitMask property is a number defining what categories of object this node should collide with.
//The contactTestBitMask property is a number defining which collisions we want to be notified about.

//If you give a node a collision bitmask but not a contact test bitmask, it means they will bounce off each other but you won't be notified.
//If you give a node contact test but not collision bitmask it means they won't bounce off each other but you will be told when they overlap.

protocol GameViewControllerDelegate: class {
	func moveToMainMenu()
	func showPauseMenu(levelNumber: Int, numberOfLevels: Int, score: Int, packNumber: Int, height: Int, sender: String, gameoverBool: Bool, newItemsBool: Bool, previousHighscore: Int)
	func showInbetweenView(levelNumber: Int, score: Int, packNumber: Int, levelTimerBonus: Int, firstLevel: Bool, numberOfLevels: Int, levelScore: Int)
	var selectedLevel: Int? { get set }
	var numberOfLevels: Int? { get set }
	var levelSender: String? { get set }
	var levelPack: Int? { get set }
	func showAd()
	func createInterstitial()
}
// Setup the protocol to return to the main menu from GameViewController

class GameScene: SKScene, SKPhysicsContactDelegate {
	
    var paddle = SKSpriteNode()
	var paddleLaser = SKSpriteNode()
	var paddleSticky = SKSpriteNode()
	var paddleRetroTexture = SKSpriteNode()
	var paddleRetroLaserTexture = SKSpriteNode()
	var paddleRetroStickyTexture = SKSpriteNode()

    var ball = SKSpriteNode()
    var brick = SKSpriteNode()
    var life = SKSpriteNode()
	var topScreenBlock = SKSpriteNode()
	var bottomScreenBlock = SKSpriteNode()
	var sideScreenBlockLeft = SKSpriteNode()
	var sideScreenBlockRight = SKSpriteNode()
	var background = SKSpriteNode()
	var directionMarker = SKSpriteNode()
	var backstop = SKSpriteNode()
    // Define objects
	
	let brickBlue: UIColor = #colorLiteral(red: 0.3137254902, green: 0.8352941176, blue: 0.8901960784, alpha: 1)
	let brickBlueDark: UIColor = #colorLiteral(red: 0, green: 0.462745098, blue: 1, alpha: 1)
	let brickBlueDarkExtra: UIColor = #colorLiteral(red: 0, green: 0.2274509804, blue: 0.4901960784, alpha: 1)
	let brickBlueLight: UIColor = #colorLiteral(red: 0.4941176471, green: 0.7254901961, blue: 1, alpha: 1)
	let brickBrown: UIColor = #colorLiteral(red: 0.6078431373, green: 0.2274509804, blue: 0, alpha: 1)
	let brickBrownLight: UIColor = #colorLiteral(red: 0.8509803922, green: 0.4784313725, blue: 0.2588235294, alpha: 1)
	let brickGreen: UIColor = #colorLiteral(red: 0.1137254902, green: 0.6156862745, blue: 0.1058823529, alpha: 1)
	let brickGreenDark: UIColor = #colorLiteral(red: 0.007843137255, green: 0.3843137255, blue: 0, alpha: 1)
	let brickGreenGigaball: UIColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
	let brickGreenLight: UIColor = #colorLiteral(red: 0.5215686275, green: 1, blue: 0.5137254902, alpha: 1)
	let brickGreenSI: UIColor = #colorLiteral(red: 0.02352941176, green: 1, blue: 0, alpha: 1)
	let brickGrey: UIColor = #colorLiteral(red: 0.4196078431, green: 0.4196078431, blue: 0.4196078431, alpha: 1)
	let brickGreyDark: UIColor = #colorLiteral(red: 0.2431372549, green: 0.2431372549, blue: 0.2431372549, alpha: 1)
	let brickGreyLight: UIColor = #colorLiteral(red: 0.6901960784, green: 0.6862745098, blue: 0.6862745098, alpha: 1)
	let brickOrange: UIColor = #colorLiteral(red: 0.9725490196, green: 0.4274509804, blue: 0.1098039216, alpha: 1)
	let brickOrangeDark: UIColor = #colorLiteral(red: 0.7764705882, green: 0.3098039216, blue: 0.03529411765, alpha: 1)
	let brickOrangeLight: UIColor = #colorLiteral(red: 1, green: 0.6392156863, blue: 0.4274509804, alpha: 1)
	let brickPink: UIColor = #colorLiteral(red: 1, green: 0.3921568627, blue: 0.5960784314, alpha: 1)
	let brickPurple: UIColor = #colorLiteral(red: 0.6156862745, green: 0.2352941176, blue: 0.8274509804, alpha: 1)
	let brickPurpleDark: UIColor = #colorLiteral(red: 0.2896767905, green: 0, blue: 0.4275261739, alpha: 1)
	let brickWhite: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
	let brickYellow: UIColor = #colorLiteral(red: 0.9725490196, green: 0.9058823529, blue: 0.1098039216, alpha: 1)
	let brickYellowDark: UIColor = #colorLiteral(red: 0.8901960784, green: 0.7411764706, blue: 0.05098039216, alpha: 1)
	let brickYellowLight: UIColor = #colorLiteral(red: 1, green: 0.968627451, blue: 0.5725490196, alpha: 1)
	// Brick colours
    
    var livesLabel = SKLabelNode()
    var scoreLabel = SKLabelNode()
	var multiplierLabel = SKLabelNode()
	var readyCountdown = SKSpriteNode()
	var goCountdown = SKSpriteNode()
	var timerLabel = SKLabelNode()
	
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
	var gigaBallIcon = SKSpriteNode()
	var hiddenBricksIcon = SKSpriteNode()
	var ballSizeIcon = SKSpriteNode()
	// Power-up icons
	
	var paddleSizeIconBar = SKSpriteNode()
	var ballSpeedIconBar = SKSpriteNode()
	var stickyPaddleIconBar = SKSpriteNode()
	var gravityIconBar = SKSpriteNode()
	var lasersIconBar = SKSpriteNode()
	var gigaBallIconBar = SKSpriteNode()
	var hiddenBricksIconBar = SKSpriteNode()
	var ballSizeIconBar = SKSpriteNode()
	// Power-up progress bars
	
	var paddleSizeIconEmptyBar = SKSpriteNode()
	var ballSpeedIconEmptyBar = SKSpriteNode()
	var stickyPaddleIconEmptyBar = SKSpriteNode()
	var gravityIconEmptyBar = SKSpriteNode()
	var lasersIconEmptyBar = SKSpriteNode()
	var gigaBallIconEmptyBar = SKSpriteNode()
	var hiddenBricksIconEmptyBar = SKSpriteNode()
	var ballSizeIconEmptyBar = SKSpriteNode()
	// Power-up empty progress bars
	
	var powerUpTray = SKSpriteNode()
	var scoreBacker = SKSpriteNode()
	
	var screenBlockArray: [SKSpriteNode] = []

	var iconArray: [SKSpriteNode] = []
	var iconTextureArray: [SKTexture] = []
	var disabledIconTextureArray: [SKTexture] = []
	var iconTimerArray: [SKSpriteNode] = []
	var iconEmptyTimerArray: [SKSpriteNode] = []
	var iconTimerTextureArray: [SKTexture] = []
	var iconUnlockedBool: [Bool] = []
	var iconSize: CGFloat = 0
	
	var layoutUnit: CGFloat = 0
    var paddleWidth: CGFloat = 0
	var paddleHeight: CGFloat = 0
    var paddleGap: CGFloat = 0
	var minPaddleGap: CGFloat = 0
    var ballSize: CGFloat = 0
	var ballSizeBig: CGFloat = 0
	var ballSizeBiggest: CGFloat = 0
	var ballSizeSmall: CGFloat = 0
	var ballSizeSmallest: CGFloat = 0
    var ballStartingPositionY: CGFloat = 0
    var ballLaunchSpeed: Double = 0
    var ballLaunchAngleRad: Double = 0
	var brickHeight: CGFloat = 0
    var brickWidth: CGFloat = 0
    var numberOfBrickRows: Int = 0
    var numberOfBrickColumns: Int = 0
    var totalBricksWidth: CGFloat = 0
	var totalBricksHeight: CGFloat = 0
    var yBrickOffset: CGFloat = 0
	var yBrickOffsetEndless: CGFloat = 0
    var xBrickOffset: CGFloat = 0
    var powerUpSize: CGFloat = 0
	var screenBlockTopWidth: CGFloat = 0
	var topGap: CGFloat = 0
	var paddlePositionY: CGFloat = 0
	var screenBlockTopHeight: CGFloat = 0
	var screenBlockSideWidth: CGFloat = 0
	var gameWidth: CGFloat = 0
	var backStopWidth: CGFloat = 0
	var backStopHeight: CGFloat = 0
    // Object layout property defintion
    
    var ballIsOnPaddle: Bool = true
    var numberOfLives: Int = 0
    var collisionLocation: Double = 0
    var minAngleDeg: Double = 0
    var angleAdjustmentK: Double = 0
        // Effect of paddle position hit on ball angle. Larger number means more effect
	var xSpeedLive: CGFloat = 0
	var ySpeedLive: CGFloat = 0
    var bricksLeft: Int = 0
    var ballLinearDampening: CGFloat = 0
	var ballSpeedSlow: CGFloat = 0
	var ballSpeedSlowest: CGFloat = 0
	var ballSpeedNominal: CGFloat = 0
	var ballSpeedFast: CGFloat = 0
	var ballSpeedFastest: CGFloat = 0
	var ballSpeedLimit: CGFloat = 0
	var paddleMovementFactor: CGFloat = 0
	var paddleTiltMagnitude: CGFloat = 0
	var minTilt: CGFloat = 0
	var maxTilt: CGFloat = 0
	var levelNumber: Int = 0
	var startLevelNumber: Int = 0
	var numberOfLevels: Int = 0
	var levelSender: String = ""
	var packNumber: Int = 0
	var brickRemovalCounter: Int = 0
	var gravityActivated: Bool = false
	var pauseBallVelocityX: CGFloat = 0
	var pauseBallVelocityY: CGFloat = 0
    // Setup game metrics
	
	var powerUpProbFactor: Int = 0
	var powerUpProbArray: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	var powerUpProbSum: Int = 0
	var powerUpGeneratorCycles: Int = 0
	var backstopHit: Bool = false
	// Power-up probabilities
    
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
	var levelTimerBonus: Int = 0
	var levelTimerValue: Int = 0 {
		didSet {
//			timerLabel.text = String(levelTimerValue)
			if endlessMode {
				endlessModeDurationCheck()
			}
		}
	}
	// Run every time levelTimerValue is updated (every second
	var firstLevel: Bool = false
    // Setup score properties
	
	var premiumSetting: Bool?
	var adsSetting: Bool?
	var soundsSetting: Bool?
	var musicSetting: Bool?
	var hapticsSetting: Bool?
	var parallaxSetting: Bool?
	var paddleSensitivitySetting: Int?
	var gameCenterSetting: Bool?
	var ballSetting: Int?
	var paddleSetting: Int?
	var brickSetting: Int?
    var appIconSetting: Int?
	var swipeUpPause: Bool?
	var gameInProgress: Bool?
	var resumeGameToLoad: Bool?
	// User settings
	var saveGameSaveArray: [Int]?
    var saveMultiplier: Double?
    var saveBrickTextureArray: [Int]?
    var saveBrickColourArray: [Int]?
    var saveBrickXPositionArray: [Int]?
    var saveBrickYPositionArray: [Int]?
	var saveBallPropertiesArray: [Double]?
	var savePowerUpFallingXPositionArray: [Int]?
	var savePowerUpFallingYPositionArray: [Int]?
	var savePowerUpFallingArray: [Int]?
	var savePowerUpActiveArray: [String]?
	var savePowerUpActiveDurationArray: [Double]?
	var savePowerUpActiveTimerArray: [Double]?
	var savePowerUpActiveMagnitudeArray: [Int]?
    // Game save settings
    
    var brickNormalTexture: SKTexture = SKTexture(imageNamed: "BrickNormal")
	var brickInvisibleTexture: SKTexture = SKTexture(imageNamed: "BrickInvisible")
    var brickMultiHit1Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit1")
    var brickMultiHit2Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit2")
    var brickMultiHit3Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit3")
	var brickMultiHit4Texture: SKTexture = SKTexture(imageNamed: "BrickMultiHit4")
	let brickIndestructible1Texture: SKTexture = SKTexture(imageNamed: "BrickIndestructible1")
    let brickIndestructible2Texture: SKTexture = SKTexture(imageNamed: "BrickIndestructible2")
	let brickNullTexture: SKTexture = SKTexture(imageNamed: "BrickNull")
    // brick textures
	
	let retroBrickNormalTexture: SKTexture = SKTexture(imageNamed: "retroBrickNormal")
	let retroBrickInvisibleTexture: SKTexture = SKTexture(imageNamed: "retroBrickInvisible")
    let retroBrickMultiHit1Texture: SKTexture = SKTexture(imageNamed: "RetroBrickMultiHit1")
    let retroBrickMultiHit2Texture: SKTexture = SKTexture(imageNamed: "RetroBrickMultiHit2")
    let retroBrickMultiHit3Texture: SKTexture = SKTexture(imageNamed: "RetroBrickMultiHit3")
	let retroBrickMultiHit4Texture: SKTexture = SKTexture(imageNamed: "RetroBrickMultiHit4")
	// retro brick textures
    
    let powerUpGetALife: SKTexture = SKTexture(imageNamed: "PowerUpGetALife")
    let powerUpDecreaseBallSpeed: SKTexture = SKTexture(imageNamed: "PowerUpReduceBallSpeed")
    let powerUpGigaBall: SKTexture = SKTexture(imageNamed: "PowerUpGigaBall")
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
	let powerUpPointsBonusSmall: SKTexture = SKTexture(imageNamed: "PowerUpPointsBonusSmall")
    let powerUpPointsPenaltySmall: SKTexture = SKTexture(imageNamed: "PowerUpPointsPenaltySmall")
    let powerUpPointsBonus: SKTexture = SKTexture(imageNamed: "PowerUpPointsBonus")
    let powerUpPointsPenalty: SKTexture = SKTexture(imageNamed: "PowerUpPointsPenalty")
    let powerUpNormalToInvisibleBricks: SKTexture = SKTexture(imageNamed: "PowerUpNormalToInvisibleBricks")
    let powerUpMultiHitBricksReset: SKTexture = SKTexture(imageNamed: "PowerUpMultiHitBricksReset")
    let powerUpGravityBall: SKTexture = SKTexture(imageNamed: "PowerUpGravityBall")
	let powerUpMultiplierReset: SKTexture = SKTexture(imageNamed: "PowerUpMultiplierReset")
	let powerUpBricksDown: SKTexture = SKTexture(imageNamed: "PowerUpBricksDown")
	let powerUpBackstop: SKTexture = SKTexture(imageNamed: "PowerUpBackstop")
	let powerUpIncreaseBallSize: SKTexture = SKTexture(imageNamed: "PowerUpIncreaseBallSize")
	let powerUpDecreaseBallSize: SKTexture = SKTexture(imageNamed: "PowerUpDecreaseBallSize")
	let powerUpPreSet: SKTexture = SKTexture(imageNamed: "PowerUpPreSet")
    // Power up textures
	
	var powerUpTextureArray: [SKTexture] = []
	
	let directionMarkerOuterTexture: SKTexture = SKTexture(imageNamed: "directionMarkerOuter")
	let directionMarkerInnerTexture: SKTexture = SKTexture(imageNamed: "directionMarkerInner")
	let directionMarkerOuterGigaTexture: SKTexture = SKTexture(imageNamed: "directionMarkerOuterGiga")
	let directionMarkerInnerGigaTexture: SKTexture = SKTexture(imageNamed: "directionMarkerInnerGiga")
	let directionMarkerOuterUndestructiTexture: SKTexture = SKTexture(imageNamed: "directionMarkerOuterUndestructi")
	let directionMarkerInnerUndestructiTexture: SKTexture = SKTexture(imageNamed: "directionMarkerInnerUndestructi")
	// direction marker textures
	
	var ballTexture: SKTexture = SKTexture(imageNamed: "ballNormal")
	let threeDBall: SKTexture = SKTexture(imageNamed: "3DBall")
	let outlineBall: SKTexture = SKTexture(imageNamed: "outlineBall")
	let squareBall: SKTexture = SKTexture(imageNamed: "squareBall")
	let candyBall: SKTexture = SKTexture(imageNamed: "candyBall")
	let splitBall: SKTexture = SKTexture(imageNamed: "splitBall")
	let iceBall: SKTexture = SKTexture(imageNamed: "iceBallNormal")
	let glassBall: SKTexture = SKTexture(imageNamed: "glassBallNormal")
	let pixelBall: SKTexture = SKTexture(imageNamed: "pixelBall")
	let gigaBallNormal: SKTexture = SKTexture(imageNamed: "ballGigaNormal")
	let rainbowBall: SKTexture = SKTexture(imageNamed: "rainbowBall")
	let retroBall: SKTexture = SKTexture(imageNamed: "retroBall")
	// regular ball texutes
	
	var gigaBallTexture: SKTexture = SKTexture(imageNamed: "ballGiga")
	let threeDBallGiga: SKTexture = SKTexture(imageNamed: "3DBallGiga")
	let outlineBallGiga: SKTexture = SKTexture(imageNamed: "outlineBallGiga")
	let squareBallGiga: SKTexture = SKTexture(imageNamed: "squareBallGiga")
	let candyBallGiga: SKTexture = SKTexture(imageNamed: "candyGiga")
	let splitBallGiga: SKTexture = SKTexture(imageNamed: "splitBallGiga")
	let iceBallGiga: SKTexture = SKTexture(imageNamed: "iceBallGiga")
	let glassBallGiga: SKTexture = SKTexture(imageNamed: "glassBallGiga")
	let pixelBallGiga: SKTexture = SKTexture(imageNamed: "pixelBallGiga")
	let rainbowBallGiga: SKTexture = SKTexture(imageNamed: "rainbowBallGiga")
	let retroBallGiga: SKTexture = SKTexture(imageNamed: "retroBallGiga")
	// giga ball texutes
	
	var undestructiballTexture: SKTexture = SKTexture(imageNamed: "ballUndestructi")
	let threeDBallUndestructi: SKTexture = SKTexture(imageNamed: "3DBallUndestructi")
	let outlineBallUndestructi: SKTexture = SKTexture(imageNamed: "outlineBallUndestructi")
	let squareBallUndestructi: SKTexture = SKTexture(imageNamed: "squareBallUndestructi")
	let candyBallUndestructi: SKTexture = SKTexture(imageNamed: "candyUndestructi")
	let splitBallUndestructi: SKTexture = SKTexture(imageNamed: "splitBallUndestructi")
	let iceBallUndestructi: SKTexture = SKTexture(imageNamed: "iceBallUndestructi")
	let glassBallUndestructi: SKTexture = SKTexture(imageNamed: "glassBallUndestructi")
	let pixelBallUndestructi: SKTexture = SKTexture(imageNamed: "pixelBallUndestructi")
	let rainbowBallUndestructi: SKTexture = SKTexture(imageNamed: "rainbowBallUndestructi")
	let retroBallUndestructi: SKTexture = SKTexture(imageNamed: "retroBallUndestructi")
	// undestructi-ball texutes
	
	var paddleTexture: SKTexture = SKTexture(imageNamed: "regularPaddle")
	let threeDPaddle: SKTexture = SKTexture(imageNamed: "3DPaddle")
	let outlinePaddle: SKTexture = SKTexture(imageNamed: "outlinePaddle")
	let squarePaddle: SKTexture = SKTexture(imageNamed: "squarePaddle")
	let icePaddle: SKTexture = SKTexture(imageNamed: "icePaddle")
	let glassPaddle: SKTexture = SKTexture(imageNamed: "glassPaddle")
	let pixelPaddle: SKTexture = SKTexture(imageNamed: "pixelPaddle")
	let gigaPaddle: SKTexture = SKTexture(imageNamed: "gigaPaddle")
	let candyPaddle: SKTexture = SKTexture(imageNamed: "candyPaddle")
	let splitPaddle: SKTexture = SKTexture(imageNamed: "splitPaddle")
	let rainbowPaddle: SKTexture = SKTexture(imageNamed: "rainbowPaddle")
	let retroPaddle: SKTexture = SKTexture(imageNamed: "retroPaddle")
	// paddle textures
	
	var laserPaddleTexture: SKTexture = SKTexture(imageNamed: "regularLasers")
	let threeDLaserTexture: SKTexture = SKTexture(imageNamed: "3DLasers")
	let outlineLaserTexture: SKTexture = SKTexture(imageNamed: "outlineLasers")
	let squareLaserTexture: SKTexture = SKTexture(imageNamed: "squareLasers")
	let iceLaserTexture: SKTexture = SKTexture(imageNamed: "iceLasers")
	let glassLaserTexture: SKTexture = SKTexture(imageNamed: "glassLasers")
	let pixelLaserTexture: SKTexture = SKTexture(imageNamed: "pixelLasers")
	let gigaLaserTexture: SKTexture = SKTexture(imageNamed: "gigaLasers")
	let candyLaserTexture: SKTexture = SKTexture(imageNamed: "stripyLasers")
	let splitLaserTexture: SKTexture = SKTexture(imageNamed: "splitLasers")
	let rainbowLaserTexture: SKTexture = SKTexture(imageNamed: "rainbowLasers")
	let retroLaserTexture: SKTexture = SKTexture(imageNamed: "retroLasers")
	// paddle laser textures
	
	var stickyPaddleTexture: SKTexture = SKTexture(imageNamed: "regularSticky")
	let threeDStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "3DSticky")
	let glassStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "glassSticky")
	let outlineStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "outlineSticky")
	let pixelStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "pixelSticky")
	let rainbowStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "rainbowSticky")
	let retroStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "retroSticky")
	let splitStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "splitSticky")
	let squareStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "squareSticky")
	let gigaStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "gigaSticky")
	let candyStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "candySticky")
	// paddle sticky textures

	let backStopTexture: SKTexture = SKTexture(imageNamed: "backStopTexture")
	// backstop texture
    
	var laserNormalTexture: SKTexture = SKTexture(imageNamed: "laserNormal")
	let laser3D: SKTexture = SKTexture(imageNamed: "laser3D")
	let laserOutline: SKTexture = SKTexture(imageNamed: "laserOutline")
	let laserSquare: SKTexture = SKTexture(imageNamed: "laserSquare")
	let laserIce: SKTexture = SKTexture(imageNamed: "laserIce")
	let laserGlass: SKTexture = SKTexture(imageNamed: "laserGlass")
	let laserPixel: SKTexture = SKTexture(imageNamed: "laserPixel")
	let laserSplit: SKTexture = SKTexture(imageNamed: "laserSplit")
	let laserRed: SKTexture = SKTexture(imageNamed: "laserRed")
	let laserOrange: SKTexture = SKTexture(imageNamed: "laserOrange")
	let laserYellow: SKTexture = SKTexture(imageNamed: "laserYellow")
	let laserGreen: SKTexture = SKTexture(imageNamed: "laserGreen")
	let laserBlue: SKTexture = SKTexture(imageNamed: "laserBlue")
	let laserIndigo: SKTexture = SKTexture(imageNamed: "laserIndigo")
	let laserViolet: SKTexture = SKTexture(imageNamed: "laserViolet")
	let laserRetroPink: SKTexture = SKTexture(imageNamed: "laserRetroPink")
	let laserRetroBlue: SKTexture = SKTexture(imageNamed: "laserRetroBlue")
	let laserGigaNormal: SKTexture = SKTexture(imageNamed: "laserGigaNormal")
	// regular laser textures
	
    var laserGigaTexture: SKTexture = SKTexture(imageNamed: "laserGiga")
	let laser3DGiga: SKTexture = SKTexture(imageNamed: "laserGiga3D")
	let laserOutlineGiga: SKTexture = SKTexture(imageNamed: "laserGigaOutline")
	let laserSquareGiga: SKTexture = SKTexture(imageNamed: "laserGigaSquare")
	let laserGlassGiga: SKTexture = SKTexture(imageNamed: "laserGigaGlass")
	let laserPixelGiga: SKTexture = SKTexture(imageNamed: "laserGigaPixel")
	let laserSplitGiga: SKTexture = SKTexture(imageNamed: "laserGigaSplit")
    // giga laser textures
	
	var rainbowLaserArray: [SKTexture] = []
	var rainbowLaserIndex = 0
	
	var stripyLaserArray: [SKTexture] = []
	var stripyLaserIndex = 0
	
	var retroLaserArray: [SKTexture] = []
	var retroLaserIndex = 0
	
	let gameBackground: SKTexture = SKTexture(imageNamed: "gameBackground")
    
    var stickyPaddleCatches: Int = 0
	var stickyPaddleCatchesTotal: Int = 0
	var backstopCatches: Int = 0
	var backstopCatchesTotal: Int = 0
    var laserPowerUpIsOn: Bool = false
    var laserTimer: Timer?
    var laserSideLeft: Bool = true
	var powerUpProximity: Bool = false
    // Power up properties
    
    var ballPositionOnPaddle: Double = 0
    
    let pauseHighlightedTexture: SKTexture = SKTexture(imageNamed: "ButtonPauseHighlighted")
    let pauseTexture: SKTexture = SKTexture(imageNamed: "ButtonPause")
    // Play/pause button textures
	
	let iconIncreasePaddleSizeTexture: SKTexture = SKTexture(imageNamed: "ExpandPaddleIcon")
	let iconDecreasePaddleSizeTexture: SKTexture = SKTexture(imageNamed: "ShrinkPaddleIcon")
	let iconDecreaseBallSpeedTexture: SKTexture = SKTexture(imageNamed: "SlowBallIcon")
	let iconIncreaseBallSpeedTexture: SKTexture = SKTexture(imageNamed: "FastBallIcon")
	let iconStickyPaddleTexture: SKTexture = SKTexture(imageNamed: "StickyPaddleIcon")
	let iconGravityTexture: SKTexture = SKTexture(imageNamed: "GravityIcon")
	let iconLasersTexture: SKTexture = SKTexture(imageNamed: "LasersIcon")
	let iconUndestructiballTexture: SKTexture = SKTexture(imageNamed: "UndestructiBallIcon")
	let iconGigaBallTexture: SKTexture = SKTexture(imageNamed: "GigaBallIcon")
	let iconHiddenBlocksTexture: SKTexture = SKTexture(imageNamed: "HiddenBricksIcon")
	let iconBallSizeBigTexture: SKTexture = SKTexture(imageNamed: "BallSizeBigIcon")
	let iconBallSizeSmallTexture: SKTexture = SKTexture(imageNamed: "BallSizeSmallIcon")
	let iconLockedTexture: SKTexture = SKTexture(imageNamed: "LockedIconDisabled")
	// Power-up icon textures
	
	let iconPaddleSizeDisabledTexture: SKTexture = SKTexture(imageNamed: "PaddleSizeIconDisabled")
	let iconBallSpeedDisabledTexture: SKTexture = SKTexture(imageNamed: "BallSpeedIconDisabled")
	let iconStickyPaddleDisabledTexture: SKTexture = SKTexture(imageNamed: "StickyPaddleIconDisabled")
	let iconGravityDisabledTexture: SKTexture = SKTexture(imageNamed: "GravityIconDisabled")
	let iconLasersDisabledTexture: SKTexture = SKTexture(imageNamed: "LasersIconDisabled")
	let iconGigaBallDisabledTexture: SKTexture = SKTexture(imageNamed: "GigaBallIconDisabled")
	let iconHiddenBlocksDisabledTexture: SKTexture = SKTexture(imageNamed: "HiddenBricksIconDisabled")
	let iconBallSizeDisabledTexture: SKTexture = SKTexture(imageNamed: "BallSizeIconDisabled")
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
	
	var brickBounceCounter: Int = 0 {
		didSet {
			if brickBounceCounter > 100 {
				ballStuck()
			}
		}
		// Property observer to release stuck ball
	}
	
	var killBall: Bool = false
	var endlessMode: Bool = false
	var gigaBallDeactivate: Bool = false
	var gravityDeactivate: Bool = false
	var deathsPerLevel: Int = 0
	var deathsPerPack: Int = 0
	var powerUpsCollectedPerLevel: Int = 0
	var powerUpsCollectedPerPack: Int = 0
	var powerUpsGeneratedPerLevel: Int = 0
	var powerUpsGeneratedPerPack: Int = 0
	var paddleHitsPerLevel: Int = 0
	var packTimerValue: Int = 0
	var newItemsBool: Bool = false
	var previousHighscore: Int = 0
	var packLevelHighScoresArray: [[Int]]?
    // Game trackers
	
	let straightLaunchAngleRad = 90 * Double.pi / 180
	let minLaunchAngleRad = 10 * Double.pi / 180
	let maxLaunchAngleRad = 70 * Double.pi / 180
	var launchAngleMultiplier = 0
	// Ball launch
    
    var fontSize: CGFloat = 0
    var labelSpacing: CGFloat = 0
    // Label metrics
	
	var totalStatsArray: [TotalStats] = []
	// Stats trackers
	
	var finalBrickRowHeight: CGFloat = 0
	var endlessHeight: Int = 0
	var endlessMoveInProgress: Bool = false
	var endlessBrickMode01: Int?
	var endlessBrickMode02: Int?
	var endlessBrickMode03: Int?
	var endlessBrickMode04: Int?
	var height01: Int?
	var height02: Int?
	var height03: Int?
	var height04: Int?
	var height05: Int?
	var height06: Int?
	var height07: Int?
	var height08: Int?
	var height09: Int?
	var height10: Int?
	var height11: Int?
	var height12: Int?
	var height13: Int?
	var height14: Int?
	var height15: Int?
	var height16: Int?
	var height17: Int?
	var height18: Int?
	var height19: Int?
	var height20: Int?
	// Endless mode properties
		
	var countdownStarted: Bool = false
	
	var screenRatio: CGFloat = 0.0
	var screenSize: String = ""
	
//MARK: - Animation Setup
	
	let timerScaleUp = SKAction.scale(to: 1.25, duration: 0.05)
	let timerScaleDown = SKAction.scale(to: 1, duration: 0.05)
	let pointsScaleDown = SKAction.scale(to: 0.75, duration: 0.05)
	// Setup timer icon animation
	
//MARK: - Sound and Haptic Definition
	
	let ballLostSound = SKAction.playSoundFileNamed("ballLostSound.mp3", waitForCompletion: true)
	let ballPaddleHitSound = SKAction.playSoundFileNamed("ballPaddleHit.mp3", waitForCompletion: true)
	let ballReleaseSound = SKAction.playSoundFileNamed("ballRelease.mp3", waitForCompletion: true)
	let brickHitNormalSound = SKAction.playSoundFileNamed("brickHit.mp3", waitForCompletion: true)
	let endlessRowDownSound = SKAction.playSoundFileNamed("endlessRowDown.mp3", waitForCompletion: true)
	let gameOverSound = SKAction.playSoundFileNamed("gameOverSound.mp3", waitForCompletion: true)
	let laserFiredSound = SKAction.playSoundFileNamed("laserFired.mp3", waitForCompletion: true)
	let levelCompleteSound = SKAction.playSoundFileNamed("levelComplete.mp3", waitForCompletion: true)
	let powerUpSound = SKAction.playSoundFileNamed("powerUpSound.mp3", waitForCompletion: true)
	let stickyPaddleHitSound = SKAction.playSoundFileNamed("stickyPaddleHit.mp3", waitForCompletion: true)
	// Sounds defined - pre-loaded to prevent game lag
    
    var lightHaptic = UIImpactFeedbackGenerator(style: .light)
	// use for ball hitting bricks and paddle
    var interfaceHaptic = UIImpactFeedbackGenerator(style: .light)
	// use for UI interactions
	var mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    var heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
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
	
//MARK: - User Defaults & NSCoder Setup
	
	var defaults = UserDefaults.standard
	// User settings  setup
	
	let totalStatsStore = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first?.appendingPathComponent("totalStatsStore.plist")
	let encoder = PropertyListEncoder()
	let decoder = PropertyListDecoder()
	// NSCoder data store & encoder setup
	
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
		
		userSettings()
		// Load user settings
		
//MARK: - Object Initialisation
		
		let ballTextureArray = [ballTexture, threeDBall, iceBall, outlineBall, squareBall, glassBall, pixelBall, splitBall, candyBall, gigaBallNormal, rainbowBall, retroBall]
		let ballGigaTextureArray = [gigaBallTexture, threeDBallGiga, iceBallGiga, outlineBallGiga, squareBallGiga, glassBallGiga, pixelBallGiga, splitBallGiga, candyBallGiga, gigaBallTexture, rainbowBallGiga, retroBallGiga]
		let ballUndestructiTextureArray = [undestructiballTexture, threeDBallUndestructi, iceBallUndestructi, outlineBallUndestructi, squareBallUndestructi, glassBallUndestructi, pixelBallUndestructi, splitBallUndestructi, candyBallUndestructi, undestructiballTexture, rainbowBallUndestructi, retroBallUndestructi]
		// ball texture arrays
		
		ballTexture = ballTextureArray[ballSetting!]
		gigaBallTexture = ballGigaTextureArray[ballSetting!]
		undestructiballTexture = ballUndestructiTextureArray[ballSetting!]
		// ball texture set
		
		let paddleTextureArray = [paddleTexture, threeDPaddle, icePaddle, outlinePaddle, squarePaddle, glassPaddle, pixelPaddle, splitPaddle, candyPaddle, gigaPaddle, rainbowPaddle, retroPaddle]
		let laserPaddleTextureArray = [laserPaddleTexture, threeDLaserTexture, iceLaserTexture, outlineLaserTexture, squareLaserTexture, glassLaserTexture, pixelLaserTexture, splitLaserTexture, candyLaserTexture, gigaLaserTexture, rainbowLaserTexture, retroLaserTexture]
		let stickyPaddleTextureArray = [stickyPaddleTexture, threeDStickyPaddleTexture, glassStickyPaddleTexture, outlineStickyPaddleTexture, squareStickyPaddleTexture, glassStickyPaddleTexture, pixelStickyPaddleTexture, splitStickyPaddleTexture, candyStickyPaddleTexture, gigaStickyPaddleTexture, rainbowStickyPaddleTexture, retroStickyPaddleTexture]
		// paddle texture arrays
		
		paddleTexture = paddleTextureArray[paddleSetting!]
		laserPaddleTexture = laserPaddleTextureArray[paddleSetting!]
		stickyPaddleTexture = stickyPaddleTextureArray[paddleSetting!]
		// paddle texture set
		
		// classic, 3d, ice, outline, square, glass, pixel, split, candy, giga, rainbow, retro
		
		let laserTextureArray = [laserNormalTexture, laser3D, laserIce, laserOutline, laserSquare, laserGlass, laserPixel, laserSplit, laserRed, laserGigaNormal, laserRed, laserRetroPink]
		let laserGigaTextureArray = [laserGigaTexture, laser3DGiga, laserGlassGiga, laserOutlineGiga, laserSquareGiga, laserGlassGiga, laserPixelGiga, laserSplitGiga, laserGigaTexture, laserGigaTexture, laserGigaTexture, laserGigaTexture]
		
		rainbowLaserArray = [laserRed, laserOrange, laserYellow, laserGreen, laserBlue, laserIndigo, laserViolet]
		stripyLaserArray = [laserRed, laserNormalTexture]
		retroLaserArray = [laserRetroPink, laserRetroBlue]
		
		laserNormalTexture = laserTextureArray[paddleSetting!]
		laserGigaTexture = laserGigaTextureArray[paddleSetting!]
		// laser texture set
		
		if brickSetting! == 1 {
			brickNormalTexture = retroBrickNormalTexture
			brickInvisibleTexture = retroBrickInvisibleTexture
			brickMultiHit1Texture = retroBrickMultiHit1Texture
			brickMultiHit2Texture = retroBrickMultiHit2Texture
			brickMultiHit3Texture = retroBrickMultiHit3Texture
			brickMultiHit4Texture = retroBrickMultiHit4Texture
		}

        ball = self.childNode(withName: "ball") as! SKSpriteNode
        paddle = self.childNode(withName: "paddle") as! SKSpriteNode
		paddleLaser = self.childNode(withName: "paddleLaser") as! SKSpriteNode
		paddleSticky = self.childNode(withName: "paddleSticky") as! SKSpriteNode
		paddleRetroTexture = self.childNode(withName: "retroPaddleTexture") as! SKSpriteNode
		paddleRetroLaserTexture = self.childNode(withName: "retroLasersTexture") as! SKSpriteNode
		paddleRetroStickyTexture = self.childNode(withName: "retroStickyTexture") as! SKSpriteNode
        pauseButton = self.childNode(withName: "pauseButton") as! SKSpriteNode
		pauseButtonTouch = self.childNode(withName: "pauseButtonTouch") as! SKSpriteNode
        life = self.childNode(withName: "life") as! SKSpriteNode
		topScreenBlock = self.childNode(withName: "topScreenBlock") as! SKSpriteNode
		bottomScreenBlock = self.childNode(withName: "bottomScreenBlock") as! SKSpriteNode
		sideScreenBlockLeft = self.childNode(withName: "sideScreenBlockLeft") as! SKSpriteNode
		sideScreenBlockRight = self.childNode(withName: "sideScreenBlockRight") as! SKSpriteNode
		background = self.childNode(withName: "background") as! SKSpriteNode
		directionMarker = self.childNode(withName: "directionMarker") as! SKSpriteNode
		backstop = self.childNode(withName: "backStop") as! SKSpriteNode
        // Links objects to nodes
		
		paddleSizeIcon = self.childNode(withName: "paddleSizeIcon") as! SKSpriteNode
		ballSpeedIcon = self.childNode(withName: "ballSpeedIcon") as! SKSpriteNode
		stickyPaddleIcon = self.childNode(withName: "stickyPaddleIcon") as! SKSpriteNode
		gravityIcon = self.childNode(withName: "gravityIcon") as! SKSpriteNode
		lasersIcon = self.childNode(withName: "lasersIcon") as! SKSpriteNode
		gigaBallIcon = self.childNode(withName: "gigaBallIcon") as! SKSpriteNode
		hiddenBricksIcon = self.childNode(withName: "hiddenBricksIcon") as! SKSpriteNode
		ballSizeIcon = self.childNode(withName: "ballSizeIcon") as! SKSpriteNode
		// Power-up icon creation
		
		paddleSizeIconBar = self.childNode(withName: "paddleSizeIconBar") as! SKSpriteNode
		ballSpeedIconBar = self.childNode(withName: "ballSpeedIconBar") as! SKSpriteNode
		stickyPaddleIconBar = self.childNode(withName: "stickyPaddleIconBar") as! SKSpriteNode
		gravityIconBar = self.childNode(withName: "gravityIconBar") as! SKSpriteNode
		lasersIconBar = self.childNode(withName: "lasersIconBar") as! SKSpriteNode
		gigaBallIconBar = self.childNode(withName: "gigaBallIconBar") as! SKSpriteNode
		hiddenBricksIconBar = self.childNode(withName: "hiddenBricksIconBar") as! SKSpriteNode
		ballSizeIconBar = self.childNode(withName: "ballSizeIconBar") as! SKSpriteNode
		// Power-up icon timer bar creation
		
		paddleSizeIconEmptyBar = self.childNode(withName: "paddleSizeIconEmptyBar") as! SKSpriteNode
		ballSpeedIconEmptyBar = self.childNode(withName: "ballSpeedIconEmptyBar") as! SKSpriteNode
		stickyPaddleIconEmptyBar = self.childNode(withName: "stickyPaddleIconEmptyBar") as! SKSpriteNode
		gravityIconEmptyBar = self.childNode(withName: "gravityIconEmptyBar") as! SKSpriteNode
		lasersIconEmptyBar = self.childNode(withName: "lasersIconEmptyBar") as! SKSpriteNode
		gigaBallIconEmptyBar = self.childNode(withName: "gigaBallIconEmptyBar") as! SKSpriteNode
		hiddenBricksIconEmptyBar = self.childNode(withName: "hiddenBricksIconEmptyBar") as! SKSpriteNode
		ballSizeIconEmptyBar = self.childNode(withName: "ballSizeIconEmptyBar") as! SKSpriteNode
		// Power-up icon timer bar creation
		
		powerUpTextureArray = [powerUpGetALife, powerUpLoseALife, powerUpDecreaseBallSpeed, powerUpIncreaseBallSpeed, powerUpIncreasePaddleSize, powerUpDecreasePaddleSize, powerUpStickyPaddle, powerUpGravityBall, powerUpPointsBonusSmall, powerUpPointsPenaltySmall, powerUpPointsBonus, powerUpPointsPenalty, powerUpMultiplier, powerUpMultiplierReset, powerUpNextLevel, powerUpShowInvisibleBricks, powerUpNormalToInvisibleBricks, powerUpMultiHitToNormalBricks, powerUpMultiHitBricksReset, powerUpRemoveIndestructibleBricks, powerUpGigaBall, powerUpUndestructiBall, powerUpLasers, powerUpBricksDown, powerUpMystery, powerUpBackstop, powerUpIncreaseBallSize, powerUpDecreaseBallSize]
		// Power up texture array
		
		powerUpTray = self.childNode(withName: "powerUpTray") as! SKSpriteNode
		scoreBacker = self.childNode(withName: "scoreBacker") as! SKSpriteNode
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
		
		if screenSize == "X" {
			gameWidth = frame.size.height/2.16
		} else {
			gameWidth = (frame.size.height/2.16) * 1.1
		}

		//
		screenBlockSideWidth = (frame.size.width - gameWidth)/2
		// Same aspect ratio as the iPhone X size phones
		
		sideScreenBlockLeft.isHidden = false
		sideScreenBlockRight.isHidden = false
		sideScreenBlockLeft.size.width = screenBlockSideWidth
		sideScreenBlockRight.size.width = screenBlockSideWidth
		sideScreenBlockLeft.position.x = -gameWidth/2-screenBlockSideWidth/2
		sideScreenBlockRight.position.x = gameWidth/2+screenBlockSideWidth/2
		
		numberOfBrickRows = 22
        numberOfBrickColumns = numberOfBrickRows/2
		layoutUnit = (gameWidth)/CGFloat(numberOfBrickRows)
		brickWidth = layoutUnit*2
		brickHeight = layoutUnit
		paddleGap = layoutUnit*7
		
		pauseButtonSize = layoutUnit*2
		iconSize = layoutUnit*1.5
		fontSize = 16
		screenBlockTopHeight = layoutUnit*3
		
		if screenSize == "X" {
			screenBlockTopHeight = layoutUnit*7.4
		} else if screenSize == "Pad" {
			pauseButtonSize = layoutUnit*1.5
			fontSize = fontSize*1.5
		}
		
		labelSpacing = fontSize/1.5
		minPaddleGap = brickHeight*4
		
		totalBricksWidth = CGFloat(numberOfBrickColumns) * (brickWidth)
		totalBricksHeight = CGFloat(numberOfBrickRows) * (brickHeight)
		
		ballSize = layoutUnit*0.67
		ball.size.width = ballSize
        ball.size.height = ballSize
		life.texture = ballTexture
		life.size.width = ballSize*1.5
		life.size.height = ballSize*1.5
		
		paddleWidth = ballSize*7.5
		paddleHeight = ballSize
		paddle.size.width = paddleWidth
		paddle.size.height = paddleHeight
		paddleLaser.texture = laserPaddleTexture
		paddleLaser.size.width = paddleWidth
		paddleLaser.size.height = ballSize*1.6
		paddleSticky.texture = stickyPaddleTexture
		paddleSticky.size.width = paddleWidth
		paddleSticky.size.height = ballSize*1.1
		paddleCenterRectZero()
		paddleRetroTexture.isHidden = true
		paddleRetroLaserTexture.isHidden = true
		paddleRetroStickyTexture.isHidden = true
		
		if paddleTexture == retroPaddle {
			paddleRetroTexture.size.width = paddleWidth*1.22
			paddleRetroTexture.size.height = paddleHeight*2.6
			paddleRetroLaserTexture.size.width = paddleRetroTexture.size.width
			paddleRetroLaserTexture.size.height = paddleRetroTexture.size.height
			paddleRetroStickyTexture.size.width = paddleRetroTexture.size.width
			paddleRetroStickyTexture.size.height = paddleRetroTexture.size.width/3.8
		}
		// Size paddle, lasers and sticky for retro paddle

		topScreenBlock.size.height = screenBlockTopHeight
		topScreenBlock.size.width = frame.size.width
		sideScreenBlockLeft.size.height = frame.size.height
		sideScreenBlockRight.size.height = frame.size.height
		sideScreenBlockLeft.position.y = -frame.size.height/2+sideScreenBlockLeft.size.height/2
		sideScreenBlockRight.position.y = -frame.size.height/2+sideScreenBlockRight.size.height/2
		
		topGap = brickHeight*2
		// Object size definition
		
		ballLinearDampening = -0.02

		topScreenBlock.position.x = 0
		topScreenBlock.position.y = frame.height/2 - screenBlockTopHeight/2
		yBrickOffset = frame.height/2 - topScreenBlock.size.height - topGap - brickHeight/2
		yBrickOffsetEndless = frame.height/2 - topScreenBlock.size.height - brickHeight/2
		finalBrickRowHeight = yBrickOffsetEndless - (brickHeight*(CGFloat(numberOfBrickRows)-1))
		paddle.position.x = 0
		paddlePositionY = frame.height/2 - topScreenBlock.size.height - topGap - totalBricksHeight - paddleGap - paddleHeight/2
		paddle.position.y = paddlePositionY
		paddleRetroTexture.position.x = paddle.position.x
		paddleRetroTexture.position.y = paddle.position.y
		paddleRetroLaserTexture.position.x = paddle.position.x
		paddleRetroLaserTexture.position.y = paddle.position.y
		paddleRetroStickyTexture.position.x = paddle.position.x
		paddleRetroStickyTexture.position.y = paddle.position.y + paddleRetroStickyTexture.size.height/2 - paddle.size.height/2
		ball.position.x = 0
		ballStartingPositionY = paddlePositionY + paddleHeight/2 + ball.size.height/2 + 1
		ball.position.y = ballStartingPositionY
		directionMarker.zPosition = 9
		// Object positioning definition
		
		bottomScreenBlock.size.height = frame.size.height/8
		bottomScreenBlock.size.width = frame.size.width
		bottomScreenBlock.position.x = 0
		bottomScreenBlock.position.y = paddlePositionY - paddleHeight/2 - brickWidth*0.85
	
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
        ballPhysicsBodySet()
        ball.zPosition = 3
		ball.physicsBody!.usesPreciseCollisionDetection = true
		ball.physicsBody!.linearDamping = ballLinearDampening
        ball.physicsBody!.angularDamping = 0
		ball.physicsBody!.restitution = 1
		ball.physicsBody!.density = 2
		// Define ball properties

		paddle.texture = paddleTexture
		paddle.physicsBody = SKPhysicsBody(texture: paddle.texture!, size: CGSize(width: paddle.size.width, height: paddle.size.height))
		var counter = 0
		while paddle.physicsBody == nil {
			counter+=1
			paddle.physicsBody = SKPhysicsBody(rectangleOf: paddle.frame.size)
			if paddle.physicsBody == nil {
				paddle.physicsBody = SKPhysicsBody(texture: paddle.texture!, size: CGSize(width: paddle.size.width, height: paddle.size.height))
			}
			if counter > 10 {
				print("llama llama no paddle physics body")
				break
			}
		}
		// Ensure paddle physics body is created
        paddle.physicsBody!.allowsRotation = false
        paddle.physicsBody!.friction = 0.0
        paddle.physicsBody!.affectedByGravity = false
        paddle.physicsBody!.isDynamic = true
        paddle.name = PaddleCategoryName
        paddle.physicsBody!.categoryBitMask = CollisionTypes.paddleCategory.rawValue
		paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
        paddle.zPosition = 3
		paddleLaser.zPosition = 2
		paddleSticky.zPosition = 4
		paddleRetroTexture.zPosition = 4
		paddleRetroLaserTexture.zPosition = 5
		paddleRetroStickyTexture.zPosition = 2
		paddle.physicsBody!.usesPreciseCollisionDetection = true
		paddle.physicsBody!.restitution = 1
		// Define paddle properties
		
		backstop.size.height = paddleHeight
		backstop.size.width = gameWidth-2
		backstop.position.x = 0
		backstop.position.y = paddle.position.y - paddleHeight - backstop.size.height/2
		backstop.texture = backStopTexture
		
		backstop.physicsBody = SKPhysicsBody(rectangleOf: backstop.frame.size)
		backstop.physicsBody!.allowsRotation = false
        backstop.physicsBody!.friction = 0.0
        backstop.physicsBody!.affectedByGravity = false
        backstop.physicsBody!.isDynamic = true
		backstop.physicsBody!.pinned = true
        backstop.name = BackstopCategoryName
        backstop.physicsBody!.categoryBitMask = 0
		backstop.physicsBody!.collisionBitMask = 0
		backstop.physicsBody!.contactTestBitMask = 0
        backstop.zPosition = 1
		backstop.physicsBody!.usesPreciseCollisionDetection = true
		backstop.physicsBody!.restitution = 1
		backstop.isHidden = true
		// Define backstop properties
		
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
			screenBlockArray[index].zPosition = 1
			screenBlockArray[index].physicsBody!.categoryBitMask = CollisionTypes.screenBlockCategory.rawValue
			screenBlockArray[index].physicsBody!.collisionBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.laserCategory.rawValue
			screenBlockArray[index].physicsBody!.contactTestBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.laserCategory.rawValue
		}
		// Define all screen block properties
		
		
		let centerPoint = CGPoint(x:bottomScreenBlock.size.width / 2 - (bottomScreenBlock.size.width * bottomScreenBlock.anchorPoint.x), y:bottomScreenBlock.size.height / 2 - (bottomScreenBlock.size.height * bottomScreenBlock.anchorPoint.y))
		bottomScreenBlock.physicsBody = SKPhysicsBody(rectangleOf: bottomScreenBlock.frame.size, center: centerPoint)
		bottomScreenBlock.physicsBody!.allowsRotation = false
		bottomScreenBlock.physicsBody!.friction = 0.0
		bottomScreenBlock.physicsBody!.affectedByGravity = false
		bottomScreenBlock.physicsBody!.isDynamic = true
		bottomScreenBlock.physicsBody!.pinned = true
		bottomScreenBlock.zPosition = 1
		
		bottomScreenBlock.physicsBody!.categoryBitMask = CollisionTypes.bottomScreenBlockCategory.rawValue
		bottomScreenBlock.physicsBody!.collisionBitMask = 0
		bottomScreenBlock.physicsBody!.contactTestBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
		
//MARK: - Label & UI Initialisation
		
        livesLabel = self.childNode(withName: "livesLabel") as! SKLabelNode
        scoreLabel = self.childNode(withName: "scoreLabel") as! SKLabelNode
		multiplierLabel = self.childNode(withName: "multiplierLabel") as! SKLabelNode
		readyCountdown = self.childNode(withName: "readyCountdown") as! SKSpriteNode
		goCountdown = self.childNode(withName: "goCountdown") as! SKSpriteNode
		buildLabel = self.childNode(withName: "buildLabel") as! SKLabelNode
		timerLabel = self.childNode(withName: "timerLabel") as! SKLabelNode
        // Links objects to label
		
		readyCountdown.size.height = 85.56
		readyCountdown.size.width = 320
		readyCountdown.position.x = 0
		readyCountdown.position.y = 0
		readyCountdown.isHidden = true
		readyCountdown.zPosition = 10
		
		goCountdown.size.height = 85.56
		goCountdown.size.width = 320
		goCountdown.position.x = 0
		goCountdown.position.y = 0
		goCountdown.isHidden = true
		goCountdown.zPosition = 10

        pauseButton.size.width = pauseButtonSize
        pauseButton.size.height = pauseButtonSize
        pauseButton.texture = pauseTexture
		pauseButton.position.x = -frame.size.width/2 + labelSpacing*2 + pauseButton.size.width/2
		pauseButton.position.y = frame.size.height/2 - labelSpacing*0.75 - pauseButton.size.height*1.25

		pauseButton.zPosition = 10
        pauseButton.isUserInteractionEnabled = false
		
		powerUpTray.zPosition = 2
		powerUpTray.size.width = gameWidth
		powerUpTray.size.height = iconSize*2
		powerUpTray.position.x = 0
		
		scoreBacker.isHidden = true
		
		if screenSize == "X" {
			powerUpTray.position.y = pauseButton.position.y - pauseButton.size.height/2 - powerUpTray.size.height/2 - labelSpacing/2
		} else {
			powerUpTray.position.y = frame.size.height/2 - powerUpTray.size.height/2
			pauseButton.position.y = frame.size.height/2 - screenBlockTopHeight - labelSpacing/2 - pauseButton.size.height/2
		}
		
		scoreBacker.zPosition = 9
		scoreBacker.size.width = gameWidth
		scoreBacker.size.height = pauseButtonSize*2
		scoreBacker.position.x = 0
		scoreBacker.position.y = powerUpTray.position.y - powerUpTray.size.height/2 - scoreBacker.size.height/2
		
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
		multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		life.position.x = -life.size.width/3
		life.position.y = pauseButton.position.y
		life.zPosition = 10
		life.isHidden = false
		livesLabel.position.x = life.size.width/3
		livesLabel.position.y = life.position.y
        livesLabel.fontSize = fontSize
		livesLabel.horizontalAlignmentMode = .left
		livesLabel.zPosition = 10
		buildLabel.position.x = -gameWidth/2 + labelSpacing
		buildLabel.position.y = -frame.size.height/2 + labelSpacing*2
		buildLabel.fontSize = fontSize/3*2
		buildLabel.zPosition = 10
		timerLabel.position.x = -gameWidth/2 + labelSpacing
		timerLabel.position.y = buildLabel.position.y + buildLabel.fontSize + labelSpacing
		timerLabel.fontSize = fontSize/3*2
		timerLabel.zPosition = 10
		timerLabel.isHidden = true
		// Label size & position definition
		
		buildLabel.text = "Build Number 0.0.0(0) - TBC - 00/00/0000"
		buildLabel.isHidden = true
	
		pauseButtonTouch.size.width = pauseButtonSize*2.75
		pauseButtonTouch.size.height = pauseButtonSize*2.75
		pauseButtonTouch.position.y = pauseButton.position.y
		pauseButtonTouch.position.x = pauseButton.position.x
		pauseButtonTouch.zPosition = 10
        pauseButtonTouch.isUserInteractionEnabled = false
		// Pause button size and position
		
		// speed, paddle size, hide, sticky, gravity, giga, laser, size
		iconArray = [ballSpeedIcon, paddleSizeIcon, hiddenBricksIcon, stickyPaddleIcon, gravityIcon, gigaBallIcon, lasersIcon, ballSizeIcon]
		disabledIconTextureArray = [iconBallSpeedDisabledTexture, iconPaddleSizeDisabledTexture, iconHiddenBlocksDisabledTexture, iconStickyPaddleDisabledTexture, iconGravityDisabledTexture, iconGigaBallDisabledTexture, iconLasersDisabledTexture, iconBallSizeDisabledTexture]
		iconTimerArray = [ballSpeedIconBar, paddleSizeIconBar, hiddenBricksIconBar, stickyPaddleIconBar, gravityIconBar, gigaBallIconBar, lasersIconBar, ballSizeIconBar]
		iconEmptyTimerArray = [ballSpeedIconEmptyBar, paddleSizeIconEmptyBar, hiddenBricksIconEmptyBar, stickyPaddleIconEmptyBar, gravityIconEmptyBar, gigaBallIconEmptyBar, lasersIconEmptyBar, ballSizeIconEmptyBar]
		iconUnlockedBool = [false, false, false, false, false, false, false, false]
		
		// paddle size, speed, sticky, gravity, laser, giga, hide, ball size
//		iconArray = [paddleSizeIcon, ballSpeedIcon, stickyPaddleIcon, gravityIcon, lasersIcon, gigaBallIcon, hiddenBricksIcon, ballSizeIcon]
//		disabledIconTextureArray = [iconPaddleSizeDisabledTexture, iconBallSpeedDisabledTexture, iconStickyPaddleDisabledTexture, iconGravityDisabledTexture, iconLasersDisabledTexture, iconGigaBallDisabledTexture, iconHiddenBlocksDisabledTexture, iconBallSizeDisabledTexture]
//		iconTimerArray = [paddleSizeIconBar, ballSpeedIconBar, stickyPaddleIconBar, gravityIconBar, lasersIconBar, gigaBallIconBar, hiddenBricksIconBar, ballSizeIconBar]
//		iconEmptyTimerArray = [paddleSizeIconEmptyBar, ballSpeedIconEmptyBar, stickyPaddleIconEmptyBar, gravityIconEmptyBar, lasersIconEmptyBar, gigaBallIconEmptyBar, hiddenBricksIconEmptyBar, ballSizeIconEmptyBar]
//		iconUnlockedBool = [true, true, false, false, false, false, false, false]
		
		
		for i in 1...iconArray.count {
			let index = i-1
			let iconSpacing = ((gameWidth-iconSize*2) - iconSize*(CGFloat(iconArray.count)-1)) / (CGFloat(iconArray.count)-1)
			iconArray[index].size.width = iconSize
			iconArray[index].size.height = iconSize
			iconArray[index].texture = iconLockedTexture
			iconArray[index].position.x = -gameWidth/2 + iconSize + (iconSize+iconSpacing)*CGFloat(index)
			iconArray[index].position.y = powerUpTray.position.y + labelSpacing/2
			iconArray[index].zPosition = 3
			iconArray[index].name = PowerIconCategoryName
			iconEmptyTimerArray[index].size.width = iconSize
			iconEmptyTimerArray[index].size.height = iconSize/6.67
			iconEmptyTimerArray[index].texture = powerUpIconBarEmpty
			iconEmptyTimerArray[index].position.x = iconArray[index].position.x - iconEmptyTimerArray[index].size.width/2
			iconEmptyTimerArray[index].position.y = iconArray[index].position.y - iconSize/2 - iconEmptyTimerArray[index].size.height/2 - labelSpacing/2
			iconEmptyTimerArray[index].zPosition = 3
			iconTimerArray[index].size.width = iconEmptyTimerArray[index].size.width
			iconTimerArray[index].size.height = iconEmptyTimerArray[index].size.height
			iconTimerArray[index].texture = powerUpIconBarFull
			iconTimerArray[index].position.x = iconEmptyTimerArray[index].position.x
			iconTimerArray[index].position.y = iconEmptyTimerArray[index].position.y
			iconTimerArray[index].zPosition = 4
			iconTimerArray[index].isHidden = true
			iconTimerArray[index].centerRect = CGRect(x: 2.0/25.0, y: 0.0/2.5, width: 21.0/25.0, height: 2.5/2.5)
			iconTimerArray[index].scale(to:CGSize(width: iconEmptyTimerArray[index].size.width, height: iconEmptyTimerArray[index].size.height))
		}
		// Power-up progress icon definition and setup

//MARK: - Game Properties Initialisation
        
		ballSpeedNominal = ballSize * 37.5
		ballSpeedSlow = ballSize * 32.5
		ballSpeedSlowest = ballSize * 27.5
		ballSpeedFast = ballSize * 45
		ballSpeedFastest = ballSize * 55
		ballSpeedLimit = ballSpeedNominal
		// Ball speed parameters
		
		minAngleDeg = 10
		angleAdjustmentK = 45
		// Ball angle parameters
		
		powerUpLimit = 2
		powerUpProbFactor = 10
		
		powerUpProbArray[0] = 3 // Get a Life
		powerUpProbArray[1] = 3 // Lose a Life
		powerUpProbArray[2] = 10 // Decrease Ball Speed
		powerUpProbArray[3] = 10 // Increase Ball Speed
		powerUpProbArray[4] = 10 // Increase Paddle Size
		powerUpProbArray[5] = 10 // Decrease Paddle Size
		powerUpProbArray[6] = 7 // Sticky Paddle
		powerUpProbArray[7] = 7 // Gravity
		powerUpProbArray[8] = 7 // +100 Points
		powerUpProbArray[9] = 7 // -100 Points
		powerUpProbArray[10] = 3 // +1000 Points
		powerUpProbArray[11] = 3 // -1000 Points
		powerUpProbArray[12] = 7 // x2 Multiplier
		powerUpProbArray[13] = 7 // Reset Multiplier
		powerUpProbArray[14] = 1 // Next Level
		powerUpProbArray[15] = 5 // Show All Bricks
		powerUpProbArray[16] = 5 // Hide Bricks
		powerUpProbArray[17] = 5 // Clear Multi-Hit Bricks
		powerUpProbArray[18] = 5 // Reset Multi-Hit Bricks
		powerUpProbArray[19] = 5 // Remove Indestructible Bricks
		powerUpProbArray[20] = 3 // Giga-Ball
		powerUpProbArray[21] = 3 // Undestructi-Ball
		powerUpProbArray[22] = 3 // Lasers
		powerUpProbArray[23] = 7 // Quicksand
		powerUpProbArray[24] = 7 // Mystery
		powerUpProbArray[25] = 7 // Backstop
		powerUpProbArray[26] = 10 // Increase Ball Size
		powerUpProbArray[27] = 10 // Decrease Ball Size
		// Set default probabilities
		// Power-up parameters
		
		brickDestroyScore = 10
		levelCompleteScore = 100
		// Score properties
		
//MARK: - Score Database Setup
		
		loadGameData()
		
        NotificationCenter.default.addObserver(self, selector: #selector(self.pauseNotificationKeyReceived), name: Notification.Name.pauseNotificationKey, object: nil)
        // Sets up an observer to watch for notifications from AppDelegate to check if the app has quit
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.restartGameNotificiationKeyReceived), name: .restartGameNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has restarted the game
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
        // Sets up an observer to watch for changes to the NSUbiquitousKeyValueStore pushed by the main menu screen
		
		let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture))
		swipeUp.direction = .up
		view.addGestureRecognizer(swipeUp)
		// Setup swipe gesture
		
		gameState.enter(PreGame.self)
        // Tell the state machine to enter the waiting for tap state
    }
	
	func loadGameData() {
		if let totalData = try? Data(contentsOf: totalStatsStore!) {
			do {
				totalStatsArray = try decoder.decode([TotalStats].self, from: totalData)
			} catch {
				print("Error decoding total stats array, \(error)")
			}
		}
		
		packLevelHighScoresArray = [
			totalStatsArray[0].pack1LevelHighScores, totalStatsArray[0].pack2LevelHighScores, totalStatsArray[0].pack3LevelHighScores, totalStatsArray[0].pack4LevelHighScores, totalStatsArray[0].pack5LevelHighScores, totalStatsArray[0].pack6LevelHighScores, totalStatsArray[0].pack7LevelHighScores, totalStatsArray[0].pack8LevelHighScores, totalStatsArray[0].pack9LevelHighScores, totalStatsArray[0].pack10LevelHighScores, totalStatsArray[0].pack11LevelHighScores
		]
		
		// Load the total stats array from the NSCoder data store
	}
	
	func startLevelTimer() {
		let timerInterval = SKAction.wait(forDuration: 1.0)
		let timerAction = SKAction.run({
			[unowned self] in
			self.levelTimerValue+=1
		})
		let timerSequence = SKAction.sequence([timerInterval, timerAction])
		run(SKAction.repeatForever(timerSequence), withKey: "gameTimer")
	}
	// Setup game timer
		
	func endlessModeDurationCheck() {
		if levelTimerValue >= 60 && totalStatsArray[0].achievementsUnlockedArray[17] == false {
			totalStatsArray[0].achievementsUnlockedArray[17] = true
			totalStatsArray[0].achievementDates[17] = Date()
			let achievement = GKAchievement(identifier: "endlessOneMins")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessOneMins")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessOneMins achievement")
				}
			}
		}
		if levelTimerValue >= 300 && totalStatsArray[0].achievementsUnlockedArray[18] == false {
			totalStatsArray[0].achievementsUnlockedArray[18] = true
			totalStatsArray[0].achievementDates[18] = Date()
			let achievement = GKAchievement(identifier: "endlessFiveMins")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessFiveMins")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessFiveMins achievement")
				}
			}
		}
		if levelTimerValue >= 600 && totalStatsArray[0].achievementsUnlockedArray[19] == false {
			totalStatsArray[0].achievementsUnlockedArray[19] = true
			totalStatsArray[0].achievementDates[19] = Date()
			let achievement = GKAchievement(identifier: "endlessTenMins")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessTenMins")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessTenMins achievement")
				}
			}
		}
		if levelTimerValue >= 1800 && totalStatsArray[0].achievementsUnlockedArray[20] == false {
			totalStatsArray[0].achievementsUnlockedArray[20] = true
			totalStatsArray[0].achievementDates[20] = Date()
			let achievement = GKAchievement(identifier: "endlessThirtyMins")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessThirtyMins")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessThirtyMins achievement")
				}
			}
		}
		if levelTimerValue >= 3600 && totalStatsArray[0].achievementsUnlockedArray[21] == false {
			totalStatsArray[0].achievementsUnlockedArray[21] = true
			totalStatsArray[0].achievementDates[21] = Date()
			let achievement = GKAchievement(identifier: "endlessSixtyMins")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessSixtyMins")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessSixtyMins achievement")
				}
			}
		}
	}
	// Check for endless mode time achivements
    
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
			
			var touchDistance = paddleMovedDistance
			if touchDistance < 0 {
				touchDistance = touchDistance*(-1)
			}
			if touchDistance > 100 && ballIsOnPaddle == false && totalStatsArray[0].achievementsUnlockedArray[50] == false {
				totalStatsArray[0].achievementsUnlockedArray[50] = true
				totalStatsArray[0].achievementDates[50] = Date()
				let achievement = GKAchievement(identifier: "paddleSpeed")
				if achievement.isCompleted == false {
					print("llama llama achievement paddleSpeed")
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						print(error?.localizedDescription ?? "Error reporting paddleSpeed achievement")
					}
				}
			}
			// High speed paddle achievement
			
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
			
			paddleLaser.position.x = paddle.position.x
			paddleLaser.position.y = paddle.position.y - paddleHeight/2
			paddleSticky.position.x = paddle.position.x
			paddleSticky.position.y = paddle.position.y - paddleHeight/2
			paddleRetroTexture.position.x = paddle.position.x
			paddleRetroTexture.position.y = paddle.position.y
			paddleRetroLaserTexture.position.x = paddle.position.x
			paddleRetroLaserTexture.position.y = paddle.position.y
			paddleRetroStickyTexture.position.x = paddle.position.x
			paddleRetroStickyTexture.position.y = paddle.position.y + paddleRetroStickyTexture.size.height/2 - paddle.size.height/2
			// Keep the different paddle textures together
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
			userSettings()
            let touch = touches.first
            let positionInScene = touch!.location(in: self)
            let touchedNode = self.atPoint(positionInScene)
            
            if let name = touchedNode.name {
                if name == "pauseButton" || name == "pauseButtonTouch" && gameState.currentState is Playing {
					if endlessMoveInProgress == false {
						clearSavedGame()
						// Clear current saved game before re-saving
						gameState.enter(Paused.self)
					}
					// Don't allow pause if brick down animation is in progress
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
			if paddleTexture == retroPaddle {
				paddleRetroStickyTexture.isHidden = true
			}
			// show retro sticky paddle
            if stickyPaddleCatches == 0 {
				paddleSticky.isHidden = true
				paddleRetroStickyTexture.isHidden = true
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
		
		if soundsSetting! {
			self.run(ballReleaseSound)
		}
		
		startLevelTimer()
		// restart timer

		if hapticsSetting! {
			lightHaptic.impactOccurred()
		}
		if musicSetting! {
			MusicHandler.sharedHelper.gameVolume()
		}
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
		
		if gameState.currentState is Paused {
			if self.isPaused == false && countdownStarted == false {
				self.isPaused = true
			}
		}
		// Ensures game is paused when returning from background

        if gameState.currentState is Playing {
			
			paddleLaser.position.x = paddle.position.x
			paddleLaser.position.y = paddle.position.y - paddleHeight/2
			paddleSticky.position.x = paddle.position.x
			paddleSticky.position.y = paddle.position.y - paddleHeight/2
			paddleRetroTexture.position.x = paddle.position.x
			paddleRetroTexture.position.y = paddle.position.y
			paddleRetroLaserTexture.position.x = paddle.position.x
			paddleRetroLaserTexture.position.y = paddle.position.y
			paddleRetroStickyTexture.position.x = paddle.position.x
			paddleRetroStickyTexture.position.y = paddle.position.y + paddleRetroStickyTexture.size.height/2 - paddle.size.height/2
			// Keep the different paddle textures together
			
			xSpeedLive = ball.physicsBody!.velocity.dx
			ySpeedLive = ball.physicsBody!.velocity.dy
		
			if gravityActivated {
				if ball.position.y < paddle.position.y + ballSize*4 {
					ball.physicsBody?.affectedByGravity = false
				} else {
					ball.physicsBody?.affectedByGravity = true
					// Stop the ball being effected by gravity near the paddle
				}
			}
			// Sets the ball's gravity control

			if ballIsOnPaddle {
				ball.position.y = ballStartingPositionY
				// Ensure ball remains on paddle
			} else {
				ballSpeedControl()
				// Ensure ball speed remains within limits
			}
		}
    }
    
    func ballLost() {
		if hapticsSetting! {
			softHaptic.impactOccurred()
		}
		totalStatsArray[0].ballsLost+=1
		deathsPerLevel+=1
        self.ball.isHidden = true
		ball.texture = ballTexture
		ballRelativePositionOnPaddle = 0
        ball.position.x = paddle.position.x
        ball.position.y = ballStartingPositionY
        ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
        ballIsOnPaddle = true
        paddleMoved = true
		ballLostBool = true
		endlessMoveInProgress = false
        // Reset ball position
		
		brickRemovalCounter = 0
		// Reset brick removal counter
		
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			node.removeAllActions()
			node.alpha = 1.0
		}
		// Reset bricks and re-hide invisible bricks

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
        // Remove any remaining lasers
		
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		// Update score

		multiplier = 1.0
		scoreFactorString = String(format:"%.1f", multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight) m"
		}
		multiplierLabel.text = "x\(scoreFactorString)"
		multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		// Reset score multiplier
		
		if numberOfLives >= 5 {
			powerUpProbArray[0] = 0 // Get a Life
		}
		if numberOfLives <= 2 {
            if powerUpProbArray[0] < 5 {
                powerUpProbArray[0] = 5 // Get a Life
            }
        }
        if numberOfLives <= 1 {
            if powerUpProbArray[0] < 7 {
                powerUpProbArray[0] = 7 // Get a Life
            }
        }
        if numberOfLives <= 0 {
            powerUpProbArray[0] = 10 // Get a Life
        }
		powerUpProbSum = powerUpProbArray.reduce(0, +)
		// Increase probability of extra life if low on lives
		
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
			self.removeAction(forKey: "gameTimer")
			// Stop the level timer
			levelTimerBonus = 0
            gameState.enter(InbetweenLevels.self)
            return
		} else {
			saveCurrentGame()
		}
    }
    
    func ballLostAnimation() {
		if soundsSetting! {
			if numberOfLives > 0 {
				self.run(ballLostSound)
			} else {
				self.run(gameOverSound)
			}
		}
		// Ball lost sound
		if musicSetting! {
			MusicHandler.sharedHelper.menuVolume()
		}
		ballLostBool = true
		saveCurrentGame()
        let scaleDown = SKAction.scale(to: 0, duration: 0.1)
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let ballLostGroup = SKAction.group([scaleDown, fadeOut])
		ball.run(ballLostGroup, completion: {
			self.ballLost()
		})
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
				
				frameBallControl(xSpeed: -xSpeedLive)

			}
			// Ball hits Frame
			
			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.backstopCategory.rawValue {
				
				if hapticsSetting! {
					lightHaptic.impactOccurred()
				}
				if gigaBallDeactivate {
					deactivateGigaBall()
				}
				// Deactivate giga-ball power-up
				if gravityDeactivate {
					deactivateGravity()
				}
				// Deactivate gravity power-up
				
				backstopCatches-=1
				// Size icon timer based on number of catches remaining
				if backstopCatches == 0 {
					if hapticsSetting! {
						heavyHaptic.impactOccurred()
					}
					self.run(SKAction.wait(forDuration: 0.025), completion: {
						self.backstop.run(SKAction.scaleX(by: 0.25, y: 1, duration: 0.1), completion: {
							self.backstop.isHidden = true
							self.backstopCatches = 0
							self.backstopCatchesTotal = 0
							self.backstop.physicsBody!.categoryBitMask = 0
							self.backstop.physicsBody!.collisionBitMask = 0
							self.backstop.physicsBody!.contactTestBitMask = 0
							self.backstop.run(SKAction.scaleX(by: 4, y: 1, duration: 0.0))
						})
					})
					// Backstop paddle reset
				} else if backstopCatches < 0 {
					backstopCatches = 0
				}
				ballBackstopHit()
				// Determine ball's angle after hitting backstop to prevent too shallow angle
				
				backstopHit = true
				paddle.physicsBody!.isDynamic = false
				ballPhysicsBodySet()
				self.run(SKAction.wait(forDuration: 0.5), completion: {
					self.backstopHit = false
					self.paddle.physicsBody!.isDynamic = true
					self.ballPhysicsBodySet()
				})
				// Paddle cannot hit ball for some time after ball hits backstop
			}
			// Ball hits backstop

			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.screenBlockCategory.rawValue {
				
				let frameBlockNode = secondBody.node
				let frameBlockSprite = frameBlockNode as! SKSpriteNode
				
				if frameBlockSprite.size.width < frameBlockSprite.size.height {
				// Ball hits side block
					frameBallControl(xSpeed: -xSpeedLive)
				} else {
				// Ball hits top block
					if endlessMode == false {
						if gigaBallDeactivate {
							deactivateGigaBall()
						}
						// Deactivate giga-ball power-up
						if gravityDeactivate {
							deactivateGravity()
						}
						// Deactivate gravity power-up
					}
					
					if ySpeedLive < 0 {
						ball.physicsBody!.velocity = CGVector(dx: xSpeedLive, dy: ySpeedLive)
					} else {
						ball.physicsBody!.velocity = CGVector(dx: xSpeedLive, dy: -ySpeedLive)
					}
					let angleDeg = Double(atan2(Double(ball.physicsBody!.velocity.dy), Double(ball.physicsBody!.velocity.dx)))/Double.pi*180
					ballHorizontalControl(angleDegInput: angleDeg)
					// Ensure the ySpeed is downwards
				}
			}
		   // Ball hits screenblock

            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.brickCategory.rawValue {
                if let brickNode = secondBody.node {
                    hitBrick(node: brickNode, sprite: brickNode as! SKSpriteNode)
                }
				let angleDeg = Double(atan2(Double(ball.physicsBody!.velocity.dy), Double(ball.physicsBody!.velocity.dx)))/Double.pi*180
				
				if ball.texture != gigaBallTexture {
					ballHorizontalControl(angleDegInput: angleDeg)
					ballVerticalControl()
				}
				// Only apply ball angle correct when hitting bricks with giga-ball power off
            }
            // Ball hits Brick
            
            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.paddleCategory.rawValue {
				
				if gigaBallDeactivate {
					deactivateGigaBall()
				}
				// Deactivate giga-ball power-up
				if gravityDeactivate {
					deactivateGravity()
				}
				// Deactivate gravity power-up
				
                paddleHit()
            }
            // Ball hits Paddle
            
            if firstBody.categoryBitMask == CollisionTypes.brickCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.laserCategory.rawValue {
                if let brickNode = firstBody.node {
					totalStatsArray[0].lasersHit+=1
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

				let powerUpNode = secondBody.node
				powerUpNode!.removeAllActions()
				if powerUpNode!.zPosition == 2 {
					powerUpNode!.zPosition = 1
					powerUpNode!.physicsBody!.collisionBitMask = 0
					powerUpNode!.physicsBody!.contactTestBitMask = 0
					applyPowerUp(node: secondBody.node!)
				} else {
					return
				}
				// Use zPosition to track if power-up has aleady been collected to prevent double hits
				
            }
            // Power-up hits Paddle
			
			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.bottomScreenBlockCategory.rawValue {
				ballLostAnimation()
			}
			// Ball hits bottom screen block
		
			if firstBody.categoryBitMask == CollisionTypes.powerUpCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.bottomScreenBlockCategory.rawValue {
				
				powerUpsOnScreen-=1
				let powerUpNode = firstBody.node
				let powerUpSprite = powerUpNode as! SKSpriteNode
				
				powerUpNode?.zPosition = 1
				
				if powerUpSprite.texture == self.powerUpMystery {
					self.powerUpGenerator (sprite: powerUpSprite)
					powerUpNode!.removeFromParent()
					// If mystery power-up, remove and generate a new power-up in its position
				} else {
					let startingFade = SKAction.fadeAlpha(to: 0.75, duration: 0.25)
					let scaleDown = SKAction.scale(to: 0.25, duration: 1)
					let fadeOut = SKAction.fadeOut(withDuration: 1)
					let removeItemGroup = SKAction.group([scaleDown, fadeOut])
					removeItemGroup.timingMode = .easeIn
					let removeItemSequence = SKAction.sequence([startingFade, removeItemGroup])
					powerUpSprite.run(removeItemSequence, completion: {
						powerUpNode!.removeFromParent()
					})
					// Otherwise animate the power-up out
				}
				
				if totalStatsArray[0].achievementsUnlockedArray[30] == false {
					let percentComplete = Double(totalStatsArray[0].powerupsGenerated.reduce(0, +) - totalStatsArray[0].powerupsCollected.reduce(0, +))/100.0*100.0
					if percentComplete >= 100.0 {
						totalStatsArray[0].achievementsPercentageCompleteArray[30] = "100%"
						totalStatsArray[0].achievementsUnlockedArray[30] = true
						totalStatsArray[0].achievementDates[30] = Date()
					} else if percentComplete < 100.0 {
						let percentCompleteString = String(format:"%.1f", percentComplete)
						totalStatsArray[0].achievementsPercentageCompleteArray[30] = String(percentCompleteString)+"%"
					}
					let achievement = GKAchievement(identifier: "powerUpLeaverHundred")
					if achievement.isCompleted == false {
						print("llama llama achievement powerUpLeaverHundred: ", percentComplete)
						achievement.percentComplete = percentComplete
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting powerUpLeaverHundred achievement")
						}
					}
				}
				if totalStatsArray[0].achievementsUnlockedArray[31] == false {
					let percentComplete = Double(totalStatsArray[0].powerupsGenerated.reduce(0, +) - totalStatsArray[0].powerupsCollected.reduce(0, +))/1000.0*100.0
					if percentComplete >= 100.0 {
						totalStatsArray[0].achievementsPercentageCompleteArray[31] = "100%"
						totalStatsArray[0].achievementsUnlockedArray[31] = true
						totalStatsArray[0].achievementDates[31] = Date()
					} else if percentComplete < 100.0 {
						let percentCompleteString = String(format:"%.1f", percentComplete)
						totalStatsArray[0].achievementsPercentageCompleteArray[31] = String(percentCompleteString)+"%"
					}
					let achievement = GKAchievement(identifier: "powerUpLeaverThousand")
					if achievement.isCompleted == false {
						print("llama llama achievement powerUpLeaverThousand: ", percentComplete)
						achievement.percentComplete = percentComplete
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting powerUpLeaverThousand achievement")
						}
					}
				}
				// Power-up leave achievements
			}
			// Power-up hits bottom screen block
        }
    }
	
	func deactivateGigaBall() {
		gigaBallDeactivate = false
		gigaBallIcon.texture = iconGigaBallDisabledTexture
		ball.texture = ballTexture
		ballPhysicsBodySet()
		powerUpLimit = 2
	}
	
	func deactivateGravity() {
		gravityDeactivate = false
		gravityIcon.texture = iconGravityDisabledTexture
		physicsWorld.gravity = CGVector(dx: 0, dy: 0)
		ball.physicsBody!.affectedByGravity = false
		gravityActivated = false
	}
	
    func hitBrick(node: SKNode, sprite: SKSpriteNode, laserNode: SKNode? = nil, laserSprite: SKSpriteNode? = nil) {
		
        if hapticsSetting! {
			lightHaptic.impactOccurred()
		}

		if  laserSprite?.texture != laserGigaTexture {
            laserNode?.removeFromParent()
        }
        // Remove laser if giga-ball power up isn't activated
		
		if sprite.texture == brickIndestructible2Texture {
			brickBounceCounter+=1
		} else {
			brickBounceCounter = 0
		}
		
		if sprite.texture == brickMultiHit1Texture || sprite.texture == brickMultiHit2Texture || sprite.texture == brickMultiHit3Texture || sprite.isHidden {
			levelScore = levelScore + Int(Double(brickDestroyScore) * multiplier)
			if endlessMode == false {
				scoreLabel.text = String(totalScore + levelScore)
			}
		}
        		
        switch sprite.texture {
        case brickMultiHit1Texture:
			totalStatsArray[0].bricksHit[1]+=1
            sprite.texture = brickMultiHit2Texture
        case brickMultiHit2Texture:
			totalStatsArray[0].bricksHit[2]+=1
            sprite.texture = brickMultiHit3Texture
		case brickMultiHit3Texture:
			totalStatsArray[0].bricksHit[3]+=1
            sprite.texture = brickMultiHit4Texture
        case brickMultiHit4Texture:
			totalStatsArray[0].bricksHit[4]+=1
			totalStatsArray[0].bricksDestroyed[4]+=1
            removeBrick(node: node, sprite: sprite)
		case brickIndestructible1Texture:
			totalStatsArray[0].bricksHit[5]+=1
			sprite.texture = brickIndestructible2Texture
			removeBrick(node: node, sprite: sprite)
		case brickIndestructible2Texture:
			totalStatsArray[0].bricksHit[6]+=1
			countBricks()
        case brickInvisibleTexture:
			totalStatsArray[0].bricksHit[7]+=1
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
			} else {
				totalStatsArray[0].bricksHit[7]+=1
				totalStatsArray[0].bricksDestroyed[7]+=1
				removeBrick(node: node, sprite: sprite)
			}
        default:
		// Normal bricks
            totalStatsArray[0].bricksHit[0]+=1
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
				totalStatsArray[0].bricksHit[0]+=1
				totalStatsArray[0].bricksDestroyed[0]+=1
				removeBrick(node: node, sprite: sprite)
			}
        }
		if self.soundsSetting! {
			self.run(brickHitNormalSound)
		}
		// Brick hit sound
    }
    
    func removeBrick(node: SKNode, sprite: SKSpriteNode) {
		
		if sprite.texture == brickNullTexture {
			node.removeFromParent()
			countBricks()
			return
		}
		
		if ball.texture == undestructiballTexture {
			countBricks()
			return
		}
		// Don't allow removal of bricks during undestructi-ball
		
		powerUpProximity = false
		enumerateChildNodes(withName: PowerUpCategoryName) { (nodePowerUp, stop) in
			if sprite.position.y > nodePowerUp.position.y-self.brickWidth*2 && sprite.position.y < nodePowerUp.position.y+self.brickWidth*2 {
				self.powerUpProximity = true
				stop.initialize(to: true)
			}
		}
		
		if powerUpProximity == false {
			var powerUpProb: Int = 0
			if powerUpProbFactor > 0 {
				powerUpProb = Int.random(in: 1...powerUpProbFactor)
			}
			if powerUpProb == 1 && bricksLeft > 1 {
				powerUpGeneratorCycles = 0
				powerUpGenerator(sprite: sprite)
			}
			// probability of getting a power up if brick is removed
		}
		// Generate power-up only if not too close to another power-up or if hitting an indestructible 2 brick

		if sprite.texture != brickIndestructible1Texture && sprite.texture != brickIndestructible2Texture  {
			let waitBrickRemove = SKAction.wait(forDuration: 0.0167*2)
			node.name = BrickRemovalCategoryName
			node.isHidden = true
			node.run(waitBrickRemove, completion: {
				node.removeFromParent()
			})
			// Wait before removing brick to allow ball to bounce off brick correctly - 0.0167 = ~1 frame at 60 fps
		}
		
		countBricks()
		
		if sprite.texture != brickIndestructible2Texture && sprite.texture != brickIndestructible1Texture {
			
			if brickRemovalCounter == 19 && endlessMode == false {
				if multiplier < 2.0 {
					multiplier+=0.1
				}
				brickRemovalCounter = 0
			} else {
				brickRemovalCounter+=1
			}
			// Update multiplier
			
			levelScore = levelScore + Int(Double(brickDestroyScore) * multiplier)
		}
		
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		scoreFactorString = String(format:"%.1f", multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight) m"
		}
		if multiplier >= 2 {
			multiplierLabel.fontColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
		} else {
			multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		multiplierLabel.text = "x\(scoreFactorString)"
		// Update score
        
        if bricksLeft == 0 && endlessMode == false {
			if soundsSetting! {
				self.run(levelCompleteSound)
			}
			clearSavedGame()
			checkPaddleHitsAchievement()
			self.removeAction(forKey: "gameTimer")
			// Stop the level timer
			levelTimerBonus = levelTimerBonus - levelTimerValue
			if levelTimerBonus < 0 {
				levelTimerBonus = 0
			}
			levelTimerBonus = Int(Double(levelTimerBonus)*multiplier)
			levelScore = levelScore + levelCompleteScore
			scoreLabel.text = String(totalScore + levelScore)
            gameState.enter(InbetweenLevels.self)
			return
        }
        // Loads the next level or ends the game if all bricks have been removed
    }
	
	func checkPaddleHitsAchievement() {
		if gameoverStatus == false && endlessMode == false  {
			if paddleHitsPerLevel <= 5 && totalStatsArray[0].achievementsUnlockedArray[41] == false {
				totalStatsArray[0].achievementsUnlockedArray[41] = true
                totalStatsArray[0].achievementDates[41] = Date()
				let achievement = GKAchievement(identifier: "fivePaddleHits")
				if achievement.isCompleted == false {
					print("llama llama achievement fivePaddleHits: ", paddleHitsPerLevel)
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						print(error?.localizedDescription ?? "Error reporting fivePaddleHits achievement")
					}
				}
			}
			if paddleHitsPerLevel <= 10 && totalStatsArray[0].achievementsUnlockedArray[42] == false {
				totalStatsArray[0].achievementsUnlockedArray[42] = true
                totalStatsArray[0].achievementDates[42] = Date()
				let achievement = GKAchievement(identifier: "tenPaddleHits")
				if achievement.isCompleted == false {
					print("llama llama achievement tenPaddleHits: ", paddleHitsPerLevel)
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						print(error?.localizedDescription ?? "Error reporting tenPaddleHits achievement")
					}
				}
			}
			paddleHitsPerLevel = 0
		}
	}
	
	
	func countBricks() {
		bricksLeft = 0
		var endlessModeBricks = 0
		
		enumerateChildNodes(withName: BrickCategoryName) { (nodeBrick, _) in
			let spriteBrick = nodeBrick as! SKSpriteNode
			if spriteBrick.texture != self.brickIndestructible2Texture {
				self.bricksLeft+=1
				// Count the number of active bricks remaining
				
				if self.endlessMode && spriteBrick.position.y <= self.finalBrickRowHeight + self.brickHeight/2 {
					endlessModeBricks+=1
				}
				// Count number of active bricks in bottom row of bricks in endless mode
				
				if self.endlessMode && spriteBrick.hasActions() {
					self.endlessMoveInProgress = true
				} else {
					self.endlessMoveInProgress = false
				}
				// Checks if brick move is already in progress in endless mode
			}
		}
							
		if endlessMode && endlessMoveInProgress == false && endlessModeBricks == 0 {
			moveEndlessModeRowDown()
		}
		// If there's no other bricks in the bottom row and a move isn't currently in progress, move to the row with the next lowest bricks
		
		if endlessMode && endlessModeBricks == 0 && totalStatsArray[0].achievementsUnlockedArray[22] == false {
			totalStatsArray[0].achievementsUnlockedArray[22] = true
			totalStatsArray[0].achievementDates[22] = Date()
			let achievement = GKAchievement(identifier: "endlessCleared")
			if achievement.isCompleted == false {
				print("llama llama achievement endlessCleared")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting endlessCleared achievement")
				}
			}
		}
		// Check achievement for clearing endless mode screen of active bricks
	}
	
	func moveEndlessModeRowDown() {
				
		endlessMoveInProgress = true
						
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			let brickSprite = node as! SKSpriteNode
			
			if node.position.y <= self.finalBrickRowHeight + self.brickHeight/2 {
				node.removeFromParent()
			}
			// Count number of active bricks in bottom row of bricks in endless mode
			
			let moveBricksDown = SKAction.moveBy(x: 0, y: -brickSprite.size.height, duration: 0.05)
			node.run(moveBricksDown)
		}
		// Move bricks down
		
		if soundsSetting! {
			self.run(endlessRowDownSound)
		}
		
		if gameState.currentState is Playing {
			buildNewEndlessRow()
		}

		endlessHeight+=1
		
		if endlessHeight >= 10 && totalStatsArray[0].achievementsUnlockedArray[0] == false {
			totalStatsArray[0].achievementsUnlockedArray[0] = true
			totalStatsArray[0].achievementDates[0] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessTen")
			if achievement.isCompleted == false {
				print("llama llama achievement achievementEndlessTen")
								achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting achievementEndlessTen achievement")
				}
			}
		}
		if endlessHeight >= 100 && totalStatsArray[0].achievementsUnlockedArray[1] == false {
			totalStatsArray[0].achievementsUnlockedArray[1] = true
			totalStatsArray[0].achievementDates[1] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessHundred")
			if achievement.isCompleted == false {
				print("llama llama achievement achievementEndlessHundred")
								achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting achievementEndlessHundred achievement")
				}
			}
		}
		if endlessHeight >= 500 && totalStatsArray[0].achievementsUnlockedArray[2] == false {
			totalStatsArray[0].achievementsUnlockedArray[2] = true
			totalStatsArray[0].achievementDates[2] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessFiveHundred")
			if achievement.isCompleted == false {
				print("llama llama achievement achievementEndlessFiveHundred")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting achievementEndlessFiveHundred achievement")
				}
			}
		}
		if endlessHeight >= 1000 && totalStatsArray[0].achievementsUnlockedArray[3] == false {
			totalStatsArray[0].achievementsUnlockedArray[3] = true
			totalStatsArray[0].achievementDates[3] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessOneK")
			if achievement.isCompleted == false {
				print("llama llama achievement achievementEndlessOneK")
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting achievementEndlessOneK achievement")
				}
			}
		}
		// Check for endless mode height achivements
		
		if multiplier < 2.0 {
			multiplier = multiplier + 0.1
			multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
			if multiplier >= 2.0 {
				multiplier = 2.0
				multiplierLabel.fontColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
			}
		}
		
		levelScore = levelScore + Int(100 * multiplier)
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		
		scoreFactorString = String(format:"%.1f", multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight) m"
		}
		
		multiplierLabel.text = "x\(scoreFactorString)"
		// Update multiplier & score

		let wait = SKAction.wait(forDuration: 0.075)
        self.run(wait, completion: {
            self.countBricks()
        })
        // To run once the new row is inserted - slight delay to allow frame to move forward before executing
	}
	
	func ballBackstopHit() {
		if soundsSetting! {
			self.run(ballPaddleHitSound)
		}
		// Play paddle hit sound
		let xSpeed = ball.physicsBody!.velocity.dx
		let ySpeed = ball.physicsBody!.velocity.dy
		let ySpeedCorrected: Double = sqrt(Double(ySpeed*ySpeed))
		// Assumes the ball's ySpeed is always positive
		var angleDeg = Double(atan2(Double(ySpeedCorrected), Double(xSpeed)))/Double.pi*180
		// Angle of the ball
		let minBackstopAngle = minAngleDeg*2
		if angleDeg < 0+minBackstopAngle {
			angleDeg = minBackstopAngle
		}
		// Travelling up and right alternative
		if angleDeg > 180-minBackstopAngle {
			angleDeg = 180-minBackstopAngle
		}
		// Travelling up and left alternative
		// Prevents the new angle from over correting to a downward angle
		ballHorizontalControl(angleDegInput: angleDeg)
	}
    
    func paddleHit() {
        if hapticsSetting! {
			lightHaptic.impactOccurred()
		}
		
		setBallStartingPositionY()
		
		paddleHitsPerLevel+=1
		
        totalStatsArray[0].ballHits+=1
		brickBounceCounter = 0
		ballRelativePositionOnPaddle = ball.position.x - paddle.position.x
        
		let xSpeed = ball.physicsBody!.velocity.dx
		let ySpeed = ball.physicsBody!.velocity.dy
		let paddleLeftEdgePosition = paddle.position.x - paddle.size.width/2
		let paddleRightEdgePosition = paddle.position.x + paddle.size.width/2
		let collisionPercentage = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
		// Define collision position between the ball and paddle
		let ySpeedCorrected: Double = sqrt(Double(ySpeed*ySpeed))
		// Assumes the ball's ySpeed is always positive
		var angleDeg = Double(atan2(Double(ySpeedCorrected), Double(xSpeed)))/Double.pi*180
		// Angle of the ball
		
//		print("Llama collision: ", collisionPercentage, angleDeg, (ball.position.x-paddle.position.x))
		
		if soundsSetting! {
			if ball.position.x > paddleLeftEdgePosition + ball.size.width/3 && ball.position.x < paddleRightEdgePosition - ball.size.width/3 && stickyPaddleCatches != 0 {
				self.run(stickyPaddleHitSound)
			} else {
				self.run(ballPaddleHitSound)
			}
		}
		
		if ball.position.x > paddleLeftEdgePosition + ball.size.width/3 && ball.position.x < paddleRightEdgePosition - ball.size.width/3 {
		// Only apply if the ball hits the centre of the paddle

			if stickyPaddleCatches != 0 {
			// Catch the ball
				
				self.removeAction(forKey: "gameTimer")
				// Stop the level timer
				
				if paddleTexture == retroPaddle {
					paddleRetroStickyTexture.isHidden = false
				}
				// show retro sticky paddle
				
				ballIsOnPaddle = true
				ball.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
				paddleMoved = true
				ball.position.y = ballStartingPositionY
				invisibleBrickFlash()
				
				if musicSetting! {
					MusicHandler.sharedHelper.menuVolume()
				}
				return
				// Don't try to adjust the ball's angle if it is on the paddle
			
			} else if ballIsOnPaddle == false && ball.position.y >= paddle.position.y + paddleHeight/2 {
			// Only applies if the ball hits the top surface of the paddle

				angleDeg = angleDeg - angleAdjustmentK*collisionPercentage
				// Angle adjustment formula - the ball's angle can change up to angleAdjustmentK deg depending on where the ball hits the paddle
				
//				print("Angle correction: ", angleDeg)
				
				if angleDeg < 0+minAngleDeg {
//					print("Angle correction 5")
					angleDeg = minAngleDeg
				}
				// Travelling up and right alternative
				if angleDeg > 180-minAngleDeg {
//					print("Angle correction 6")
					angleDeg = 180-minAngleDeg
				}
				// Travelling up and left alternative
				// Prevents the new angle from over correting to a downward angle
			}
		}
		
		if ballIsOnPaddle == false && ball.position.y >= paddle.position.y {
		// Only control the ball's angle if it is above the centre of the paddle
			ballHorizontalControl(angleDegInput: angleDeg)
		}
		
		invisibleBrickFlash()
		
		let waitPaddleHitSave = SKAction.wait(forDuration: 0.1)
		paddle.run(waitPaddleHitSave, completion: {
//			self.saveCurrentGame()
		})
		
    }
	
	func invisibleBrickFlash() {
		var nonHiddenNodeFound = false
		enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
			let sprite = node as! SKSpriteNode
			if node.isHidden == false && (sprite.texture == self.brickNormalTexture || sprite.texture == self.brickInvisibleTexture || sprite.texture == self.brickMultiHit1Texture || sprite.texture == self.brickMultiHit2Texture || sprite.texture == self.brickMultiHit3Texture || sprite.texture == self.brickMultiHit4Texture) {
				nonHiddenNodeFound = true
				stop.initialize(to: true)
			}
		}
		// Check to see if there are any non-hidden destructible bricks left
		
		if nonHiddenNodeFound == false {
		// Only run if there are only hidden destructible and indestructible bricks left
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickNormalTexture || sprite.texture == self.brickInvisibleTexture {
					if sprite.texture == self.brickNormalTexture {
						node.alpha = 0.75
					} else {
						node.alpha = 0.75
					}
					node.isHidden = false
				}
			}
			// Flash bricks on
			let waitDuration = SKAction.wait(forDuration: 0.2)
			let completionBlock = SKAction.run {
				self.enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
					let sprite = node as! SKSpriteNode
					if sprite.texture == self.brickNormalTexture || sprite.texture == self.brickInvisibleTexture {
						node.isHidden = true
						node.alpha = 1.0
					}
				}
			}
			// Flash bricks off
			let sequence = SKAction.sequence([waitDuration, completionBlock])
			self.run(sequence, withKey: "invisibleBrickFlash")
		}
		// Show hidden bricks if there are no noraml or invisible bricks showing
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
		powerUp.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
		powerUp.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
        powerUp.zPosition = 2
		
        addChild(powerUp)
		
		var powerUpOnScreenArray: [SKTexture] = []
		enumerateChildNodes(withName: PowerUpCategoryName) { (node, stop) in
			let sprite = node as! SKSpriteNode
			powerUpOnScreenArray.append(sprite.texture!)
		}
		// Put all textures from current on-screen power-ups in an array
		
		powerUpProbSum = powerUpProbArray.reduce(0, +)
		
		let powerUpProb = Int.random(in: 0...powerUpProbSum-1)
		// Select power-up at random based on weighting

		var powerUpSelection: Int = 0
		var lowerRange: Int = 0
		var upperRange: Int = 1
		var selectionComplete: Bool = false
		
		powerUpGeneratorCycles+=1
		// Keep track of how many times the power-up generator has run to generate a valid power-up
		
		if powerUpGeneratorCycles > 10 {
			powerUp.removeFromParent()
			return
		}
		// Prevent the power-up generator cycling too many times when not many power-ups are available
		
		while selectionComplete == false {
			if powerUpProb > powerUpProbSum-powerUpProbArray[lowerRange...].reduce(0, +) && powerUpProb <= powerUpProbSum-powerUpProbArray[upperRange...].reduce(0, +) {
				powerUpSelection = lowerRange
				selectionComplete = true
				if totalStatsArray[0].powerUpUnlockedArray[powerUpSelection] == false {
					removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
					return
				}
				// Remove power-up if locked
			} else {
				lowerRange+=1
				upperRange+=1
				if lowerRange > powerUpProbArray.count-1 {
					removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
					return
				}
				// Stop once range reaches the end of powerUpProbArray
			}
		}
		// Power-up selection based on probability
		
        switch powerUpSelection {
        case 0:
		// 0 - Get a life
			if numberOfLives >= 5 || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpGetALife
			}
			// Don't show if number of lives is 5 or more or power-up already falling or endless mode or locked
		case 1:
		// 1 - Lose a life
			if numberOfLives <= 0 || mysteryPowerUp || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpLoseALife
			}
			// Don't show if on last life or in place of mystery power-up or power-up already falling or endless mode or locked
		case 2:
		// 2 - Decrease ball speed
			powerUp.texture = powerUpDecreaseBallSpeed
		case 3:
		// 3 - Increase ball speed
			powerUp.texture = powerUpIncreaseBallSpeed
        case 4:
		// 4 - Increase paddle size
			powerUp.texture = powerUpIncreasePaddleSize
		case 5:
		// 5 - Decrease paddle size
			powerUp.texture = powerUpDecreasePaddleSize
		case 6:
		// 6 - Sticky paddle
			powerUp.texture = powerUpStickyPaddle
		case 7:
		// 7 - Gravity ball
			powerUp.texture = powerUpGravityBall
		case 8:
		// 8 - +100 points
			if endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpPointsBonusSmall
			}
			// Don't show if power-up already falling or in endless mode or locked
		case 9:
		// 9 - -100 points
			if levelScore <= Int(100*multiplier) || mysteryPowerUp || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpPointsPenaltySmall
			}
			// Don't show if score is less than penalty points amount or in place of mystery power-up or power-up already falling or in endless mode or locked
		case 10:
		// 10 - +1000 points
			if endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpPointsBonus
			}
			// Don't show if power-up already falling or in endless mode or locked
		case 11:
		// 11 - -1000 points
			if levelScore <= Int(1000*multiplier) || mysteryPowerUp || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpPointsPenalty
			}
			// Don't show if score is less than penalty points amount or in place of mystery power-up or power-up already falling or in endless mode or locked
		case 12:
		// 12 - x2 multiplier
			if multiplier >= 2.0 || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpMultiplier
			}
			// Don't show if multiplier at 2.5 or above or power-up already falling or in endless mode or locked
		case 13:
		// 13 - Multiplier reset
			if multiplier <= 1.1 || mysteryPowerUp || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpMultiplierReset
			}
			// Don't show if multiplier is 1.5 or in place of mystery power-up or power-up already falling or in endless mode or locked
        case 14:
		// 14 - Next level
			if mysteryPowerUp || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpNextLevel
			}
			// Don't show in place of mystery power-up or power-up already falling or endless mode or locked
        case 15:
		// 15 - Invisible bricks become visible
			powerUp.texture = self.powerUpShowInvisibleBricks
			var hiddenNodeFound = 0
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				if node.isHidden == true {
					hiddenNodeFound+=1
				}
			}
			if hiddenNodeFound < 3 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if no invisible/hidden bricks or power-up already falling or locked
        case 16:
		// 16 - Normal bricks become invisble bricks
			powerUp.texture = powerUpNormalToInvisibleBricks
			var normalNodeFound = 0
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture != self.brickMultiHit1Texture && sprite.texture != self.brickMultiHit2Texture && sprite.texture != self.brickMultiHit3Texture && sprite.texture != self.brickMultiHit4Texture && sprite.texture != self.brickInvisibleTexture && sprite.texture != self.brickIndestructible1Texture && sprite.texture != self.brickIndestructible2Texture {
					normalNodeFound+=1
				}
			}
			if normalNodeFound < 3 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if no normal bricks or power-up already falling or locked
		case 17:
		// 17 - Multi-hit bricks become normal bricks
			powerUp.texture = powerUpMultiHitToNormalBricks
			var multiNodeFound = 0
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickMultiHit1Texture || sprite.texture == self.brickMultiHit2Texture {
					multiNodeFound+=1
				}
			}
			if multiNodeFound < 3 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if no multi-hit bricks or power-up already falling or locked
		case 18:
		// 18 - Multi-hit bricks reset
			powerUp.texture = powerUpMultiHitBricksReset
			var multiHitBrickFound = 0
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickMultiHit2Texture || sprite.texture == self.brickMultiHit3Texture || sprite.texture == self.brickMultiHit4Texture {
					multiHitBrickFound+=1
				}
			}
			if multiHitBrickFound < 3 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if no multi-hit bricks that have been hit or power-up already falling or locked
		case 19:
		// 19 - Remove indestructible bricks
			powerUp.texture = powerUpRemoveIndestructibleBricks
			var indestructibleNodeFound = 0
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				let sprite = node as! SKSpriteNode
				if sprite.texture == self.brickIndestructible2Texture || sprite.texture == self.brickIndestructible1Texture {
					indestructibleNodeFound+=1
				}
			}
			if indestructibleNodeFound < 3 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if no indestructible bricks or power-up already falling or locked
		case 20:
		// 20 - Giga-ball
			powerUp.texture = powerUpGigaBall
        case 21:
		// 21 - Undestructi-ball
			powerUp.texture = powerUpUndestructiBall
		case 22:
		// 22 - Lasers
			powerUp.texture = powerUpLasers
		case 23:
		// 23 - Move all bricks down 2 rows
			powerUp.texture = powerUpBricksDown
			var bricksAtBottom = false
			enumerateChildNodes(withName: BrickCategoryName) { (node, stop) in
				if node.position.y < self.paddle.position.y + self.minPaddleGap {
					bricksAtBottom = true
					stop.initialize(to: true)
				}
			}
			if bricksAtBottom || endlessMode {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			}
			// Don't show if bricks are already at lowest point or power-up already falling or endless mode or locked
		case 24:
		// 24 - Mystery power-up
			if mysteryPowerUp {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpMystery
			}
			// Don't show in place of mystery power-up or power-up already falling or locked
		case 25:
		// 25 - Backstop power-up
			if backstopCatches > 0 {
				removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
				return
			} else {
				powerUp.texture = powerUpBackstop
				if totalStatsArray[0].powerupsGenerated.count < 24 {
					totalStatsArray[0].powerupsGenerated.append(0)
				}
			}
			// Don't show power-up if already falling or in action or locked
		case 26:
		// 26 - Increase ball size
			powerUp.texture = powerUpIncreaseBallSize
		case 27:
		// 27 - Decrease ball size
			powerUp.texture = powerUpDecreaseBallSize
        default:
            break
        }

		if powerUpOnScreenArray.contains(powerUp.texture!) {
			removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
			return
		}
		// Check if new power-up is already falling and remove if so
        
		let move = SKAction.moveBy(x: 0, y: -frame.height, duration: 5)
		powerUp.run(move, withKey: "PowerUpDrop")
		powerUpsOnScreen+=1
		totalStatsArray[0].powerupsGenerated[powerUpSelection]+=1
        powerUpsGeneratedPerLevel+=1
    }
    
	func applyPowerUp (node: SKNode) {
		
		let sprite = node as! SKSpriteNode
		
		if ballLostBool {
			return
		}
		// Don't apply the power up if the ball has been lost
		
		if hapticsSetting! {
			rigidHaptic.impactOccurred()
		}
		
		if soundsSetting! {
			self.run(powerUpSound)
		}
		// Power-up applied sound
		
		powerUpsOnScreen-=1
		// Remove the power up from the power-up on screen tracker
		
		let scaleUp = SKAction.scale(to: 1.5, duration: 0.01)
		let startingFade = SKAction.fadeAlpha(to: 0.75, duration: 0.01)
		let scaleDown = SKAction.scale(to: 0.75, duration: 1)
		let fadeOut = SKAction.fadeOut(withDuration: 0.75)
		let moveUp = SKAction.moveBy(x: 0, y: sprite.size.height*2, duration: 0.75)
		let startingGroup = SKAction.group([scaleUp, startingFade])
		let powerupGroup = SKAction.group([moveUp, fadeOut, scaleDown])
		powerupGroup.timingMode = .easeIn
		let powerupSequence = SKAction.sequence([startingGroup, powerupGroup])
		node.removeAllActions()
		// Animation setup
		if sprite.texture == powerUpMystery {
			node.removeFromParent()
		} else {
			node.run(powerupSequence, completion: {
				self.mysteryPowerUp = false
				node.removeFromParent()
			})
		}
		// Power-up collection animation
		
		powerUpScore = 0
		
		if totalStatsArray[0].achievementsUnlockedArray[24] == false {
			totalStatsArray[0].achievementsUnlockedArray[24] = true
			totalStatsArray[0].achievementDates[24] = Date()
			let achievementPowerUp = GKAchievement(identifier: "firstPowerUp")
			if achievementPowerUp.isCompleted == false {
				print("llama llama achievement firstPowerUp")
				achievementPowerUp.showsCompletionBanner = true
				GKAchievement.report([achievementPowerUp]) { (error) in
					print(error?.localizedDescription ?? "Error reporting firstPowerUp achievement")
				}
			}
		}
		// First power-up achievement
		
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
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[0]+=1
			
			if numberOfLives >= 5 {
				powerUpProbArray[0] = 0 // Get a Life
			}
			if numberOfLives > 2 {
				powerUpProbArray[0] = 3 // Get a Life
			}
			if numberOfLives <= 2 {
				if powerUpProbArray[0] < 5 {
					powerUpProbArray[0] = 5 // Get a Life
				}
			}
			if numberOfLives <= 1 {
				if powerUpProbArray[0] < 7 {
					powerUpProbArray[0] = 7 // Get a Life
				}
			}
			if numberOfLives <= 0 {
				powerUpProbArray[0] = 10 // Get a Life
			}
			powerUpProbSum = powerUpProbArray.reduce(0, +)
			// Increase probability of extra life if low on lives
            
        case powerUpLoseALife:
        // Lose a life
			ball.physicsBody!.linearDamping = 2
            ballLostAnimation()
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[1]+=1
            
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
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[2]+=1
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
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[3]+=1
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
			paddleCenterRectPlus()
			// Ensure good scaling of paddles
			if paddle.xScale < 1.0 {
				paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				paddleSizeIconBar.isHidden = true
				paddle.run(SKAction.scaleX(to: 1.0, duration: 0.2), completion: {
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				paddleLaser.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleCenterRectZero()
			} else if paddle.xScale == 1.0 {
				paddle.run(SKAction.scaleX(to: 1.5, duration: 0.2), completion: {
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				paddleLaser.run(SKAction.scaleX(to: 1.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.5, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 1.42, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 1.42, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 1.42, duration: 0.2))
			} else if paddle.xScale == 1.5 {
				paddle.run(SKAction.scaleX(to: 2.0, duration: 0.2), completion: {
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				paddleLaser.run(SKAction.scaleX(to: 2.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 2.0, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 1.82, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 1.82, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 1.82, duration: 0.2))
			} else if paddle.xScale == 2.0 || paddle.xScale == 2.5 {
				paddle.run(SKAction.scaleX(to: 2.5, duration: 0.2), completion: {
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				paddleLaser.run(SKAction.scaleX(to: 2.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 2.5, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 2.24, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 2.24, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 2.24, duration: 0.2))
				if totalStatsArray[0].achievementsUnlockedArray[32] == false {
					totalStatsArray[0].achievementsUnlockedArray[32] = true
					totalStatsArray[0].achievementDates[32] = Date()
					let achievement = GKAchievement(identifier: "maxPaddleSize")
					if achievement.isCompleted == false {
						print("llama llama achievement maxPaddleSize")
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting maxPaddleSize achievement")
						}
					}
				}
				// Maximum paddle size achievement
			}
			// Resize paddle based on its current size
			if paddle.position.x + paddle.size.width/2 > gameWidth/2 {
				paddle.position.x = gameWidth/2 - paddle.size.width/2
			}
			if paddle.position.x - paddle.size.width/2 < -gameWidth/2 {
				paddle.position.x = -gameWidth/2 + paddle.size.width/2
			}
			// Ensure the paddle stays within the game's bounds
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[4]+=1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				self.paddleCenterRectPlus()
				if self.hapticsSetting! {
					self.rigidHaptic.impactOccurred()
				}
				self.paddle.run(SKAction.scaleX(to: 1, duration: 0.2), completion: {
					self.recentreBall()
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				self.paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroLaserTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroStickyTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleCenterRectZero()
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
			paddleCenterRectPlus()
			// Ensure good scaling of paddles
			if paddle.xScale < 1.0 {
				paddle.run(SKAction.scaleX(to: 0.5, duration: 0.2), completion: {
					self.recentreBall()
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue

				})
				paddleLaser.run(SKAction.scaleX(to: 0.5, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 0.5, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 0.59, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 0.59, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 0.59, duration: 0.2))
				
				if totalStatsArray[0].achievementsUnlockedArray[33] == false {
					totalStatsArray[0].achievementsUnlockedArray[33] = true
					totalStatsArray[0].achievementDates[33] = Date()
					let achievement = GKAchievement(identifier: "minPaddleSize")
					if achievement.isCompleted == false {
						print("llama llama achievement minPaddleSize")
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting minPaddleSize achievement")
						}
					}
				}
				// Minimum paddle size achievement
			} else if paddle.xScale == 1.0 {
				paddle.run(SKAction.scaleX(to: 0.75, duration: 0.2), completion: {
					self.recentreBall()
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue

				})
				paddleLaser.run(SKAction.scaleX(to: 0.75, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 0.75, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 0.79, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 0.79, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 0.79, duration: 0.2))
			} else if paddle.xScale > 1.0 {
				paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
				paddleSizeIconBar.isHidden = true
				paddle.run(SKAction.scaleX(to: 1.0, duration: 0.2), completion: {
					self.recentreBall()
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue

				})
				paddleLaser.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleSticky.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroLaserTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleRetroStickyTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
				paddleCenterRectZero()
			}
			// Resize paddle based on its current size

			if paddle.position.x + paddle.size.width/2 > gameWidth/2 {
				paddle.position.x = gameWidth/2 - paddle.size.width/2
			}
			if paddle.position.x - paddle.size.width/2 < -gameWidth/2 {
				paddle.position.x = -gameWidth/2 + paddle.size.width/2
			}
			// Ensure the paddle stays within the game's bounds
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[5]+=1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				self.paddleCenterRectPlus()
                if self.hapticsSetting! {
					self.rigidHaptic.impactOccurred()
				}
				self.paddle.run(SKAction.scaleX(to: 1, duration: 0.2), completion: {
					self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
				})
				self.paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroLaserTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleRetroStickyTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
				self.paddleCenterRectZero()
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
			
		case powerUpStickyPaddle:
        // Sticky paddle
			stickyPaddleIcon.texture = self.iconStickyPaddleTexture
			stickyPaddleIconBar.isHidden = false
			// Show power-up icon timer
			stickyPaddleIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05))
            stickyPaddleCatches = 4 + Int(Double(multiplier))
			stickyPaddleCatchesTotal = stickyPaddleCatches
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[6]+=1
			paddleSticky.isHidden = false
			if paddleTexture == retroPaddle {
				paddleSticky.isHidden = true
			}
            // Power up set and limit number of catches per power up
			
		case powerUpGravityBall:
		// Gravity ball
			removeAction(forKey: "powerUpGravityBall")
			removeAction(forKey: "gravityTimer")
			removeAction(forKey: "powerUpGravityTimer")
			// Remove any current ball speed power up timers
			gravityIcon.texture = self.iconGravityTexture
			gravityIconBar.isHidden = false
			// Show power-up icon timer
			physicsWorld.gravity = CGVector(dx: 0, dy: -1.5)
			ball.physicsBody!.affectedByGravity = true
			gravityActivated = true
			gravityDeactivate = false
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[7]+=1
			// Power up set
			let timer: Double = 10 * multiplier
			let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				if self.ballIsOnPaddle {
					self.deactivateGravity()
				} else {
					self.gravityDeactivate = true
				}
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
			
		case powerUpPointsBonusSmall:
		// 100 points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = 100
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[8]+=1
			scoreLabel.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpPointsPenaltySmall:
		// -100 points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = -100
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[9]+=1
			scoreLabel.run(SKAction.sequence([pointsScaleDown, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpPointsBonus:
		// 1k points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = 1000
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[10]+=1
			scoreLabel.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpPointsPenalty:
		// -1k points
			removeAction(forKey: "pointsAnimation")
			powerUpScore = -1000
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[11]+=1
			scoreLabel.run(SKAction.sequence([pointsScaleDown, timerScaleDown]), withKey: "pointsAnimation")
			// Power up set
			
		case powerUpMultiplier:
		// Multiplier
			removeAction(forKey: "multiplierAnimation")
			multiplier = 2.0
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[12]+=1
			multiplierLabel.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "multiplierAnimation")
			// Power up set
			
		case powerUpMultiplierReset:
		// Mutliplier reset to 1
			removeAction(forKey: "multiplierAnimation")
			multiplier = 1.0
			brickRemovalCounter = 0
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[13]+=1
			multiplierLabel.run(SKAction.sequence([pointsScaleDown, timerScaleDown]), withKey: "multiplierAnimation")
			
		case powerUpNextLevel:
        // Next level
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[14]+=1
			clearSavedGame()
			self.removeAction(forKey: "gameTimer")
			// Stop the level timer
			levelTimerBonus = levelTimerBonus - levelTimerValue
			if levelTimerBonus < 0 {
				levelTimerBonus = 0
			}
			levelTimerBonus = Int(Double(levelTimerBonus)*multiplier)
			if soundsSetting! {
				self.run(levelCompleteSound)
			}
            gameState.enter(InbetweenLevels.self)
			return
			
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
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[15]+=1
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
				if temporarySprite.texture != self.brickMultiHit1Texture && temporarySprite.texture != self.brickMultiHit2Texture && temporarySprite.texture != self.brickMultiHit3Texture && temporarySprite.texture != self.brickMultiHit4Texture && temporarySprite.texture != self.brickIndestructible1Texture && temporarySprite.texture != self.brickIndestructible2Texture {
					temporarySprite.isHidden = true
				}
			}
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[16]+=1
			// Power up set
			let timer: Double = 10 * multiplier
			let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
					let temporarySprite = node as! SKSpriteNode
					if node.isHidden == true && temporarySprite.texture != self.brickInvisibleTexture {
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
			
		case powerUpMultiHitToNormalBricks:
		// Multi-hit bricks become normal bricks
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickMultiHit1Texture || temporarySprite.texture == self.brickMultiHit2Texture || temporarySprite.texture == self.brickMultiHit3Texture {
					temporarySprite.texture = self.brickMultiHit4Texture
				}
			}
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[17]+=1
			// Power up set
			
		case powerUpMultiHitBricksReset:
		// Multi-hit bricks reset
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickMultiHit2Texture || temporarySprite.texture == self.brickMultiHit3Texture || temporarySprite.texture == self.brickMultiHit4Texture {
					temporarySprite.texture = self.brickMultiHit1Texture
				}
			}
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[18]+=1
			// Power up set
			
		case powerUpRemoveIndestructibleBricks:
		// Remove indestructible bricks
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let temporarySprite = node as! SKSpriteNode
				if temporarySprite.texture == self.brickIndestructible2Texture || temporarySprite.texture == self.brickIndestructible1Texture {
					temporarySprite.isHidden = true
					if temporarySprite.texture == self.brickIndestructible1Texture {
						self.totalStatsArray[0].bricksDestroyed[5]+=1
					} else if temporarySprite.texture == self.brickIndestructible2Texture {
						self.totalStatsArray[0].bricksDestroyed[6]+=1
					}
					temporarySprite.texture = self.brickNullTexture
					self.removeBrick(node: node, sprite: temporarySprite)
				}
			}
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[19]+=1
			// Power up set
			if bricksLeft == 0 && endlessMode == false {
				checkPaddleHitsAchievement()
				levelScore = levelScore + levelCompleteScore
				if endlessMode == false {
					scoreLabel.text = String(totalScore + levelScore)
				}
				self.removeAction(forKey: "gameTimer")
				// Stop the level timer
				levelTimerBonus = levelTimerBonus - levelTimerValue
				if levelTimerBonus < 0 {
					levelTimerBonus = 0
				}
				levelTimerBonus = Int(Double(levelTimerBonus)*multiplier)
				if soundsSetting! {
					self.run(levelCompleteSound)
				}
				gameState.enter(InbetweenLevels.self)
				return
			}
			// If the last active brick has been removed, end the level

        case powerUpGigaBall:
        // giga-ball
			removeAction(forKey: "powerUpGigaBall")
			removeAction(forKey: "powerUpUndestructiBall")
			removeAction(forKey: "powerUpGigaBallTimer")
			removeAction(forKey: "gigaBallTimer")
			// Remove any animations and timers
			gigaBallIcon.texture = self.iconGigaBallTexture
			gigaBallIconBar.isHidden = false
			// Show power-up icon timer
			gigaBallDeactivate = false
            ball.texture = gigaBallTexture
            ballPhysicsBodySet()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[20]+=1
			powerUpLimit = 4
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
				if self.ballIsOnPaddle {
					self.deactivateGigaBall()
				} else {
					self.gigaBallDeactivate = true
				}
				self.gigaBallIconBar.isHidden = true
				// Hide power-up icons
            }
			gigaBallIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.gigaBallIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "gigaBallTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			gigaBallIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpGigaBallTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpGigaBall")
            // Power up reverted
            
        case powerUpUndestructiBall:
        // Undestructi-ball
            removeAction(forKey: "powerUpGigaBall")
			removeAction(forKey: "powerUpUndestructiBall")
			removeAction(forKey: "powerUpGigaBallTimer")
			removeAction(forKey: "gigaBallTimer")
			// Remove any animations and timers
			gigaBallIcon.texture = self.iconUndestructiballTexture
			gigaBallIconBar.isHidden = false
			// Show power-up icon timer
			gigaBallDeactivate = false
			ball.texture = undestructiballTexture
			ballPhysicsBodySet()
			powerUpLimit = 2
			totalStatsArray[0].powerupsCollected[21]+=1
			powerUpMultiplierScore = -0.1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
                self.ball.texture = self.ballTexture
				self.ballPhysicsBodySet()
				self.gigaBallIcon.texture = self.iconGigaBallDisabledTexture
				self.gigaBallIconBar.isHidden = true
				// Hide power-up icons
            }
			gigaBallIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.gigaBallIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "gigaBallTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			gigaBallIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpGigaBallTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpUndestructiBall")
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
			if paddleTexture == retroPaddle {
				paddleRetroLaserTexture.isHidden = false
				paddleRetroTexture.isHidden = true
				paddleLaser.isHidden = true
			}
			// retro lasers
			laserTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(laserGenerator), userInfo: nil, repeats: true)
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[22]+=1
			powerUpLimit = 4
            // Power up set - lasers will fire every 0.1s
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
                self.laserTimer?.invalidate()
				self.paddleLaser.isHidden = true
				self.paddleRetroLaserTexture.isHidden = true
				if self.paddleTexture == self.retroPaddle {
					self.paddleRetroTexture.isHidden = false
				}
				self.laserPowerUpIsOn = false
				self.powerUpLimit = 2
				self.lasersIcon.texture = self.iconLasersDisabledTexture
				self.lasersIconBar.isHidden = true
				self.paddle.isHidden = false
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
		
		case powerUpBricksDown:
		// Move all bricks down
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let brickSprite = node as! SKSpriteNode
				let moveBricksDown = SKAction.moveBy(x: 0, y: -brickSprite.size.height*2, duration: 0.5)
				moveBricksDown.timingMode = .easeInEaseOut
				node.run(moveBricksDown)
			}
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[23]+=1
			
		case powerUpMystery:
		// Mystery power-up
			if totalStatsArray[0].achievementsUnlockedArray[23] == false {
				totalStatsArray[0].achievementsUnlockedArray[23] = true
				totalStatsArray[0].achievementDates[23] = Date()
				let achievementMystery = GKAchievement(identifier: "mysteryPowerUp")
				if achievementMystery.isCompleted == false {
					print("llama llama achievement mysteryPowerUp")
					achievementMystery.showsCompletionBanner = true
					GKAchievement.report([achievementMystery]) { (error) in
						print(error?.localizedDescription ?? "Error reporting mysteryPowerUp achievement")
					}
				}
			}
			// Mystery power-up achievement
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[24]+=1
			mysteryPowerUp = true
			powerUpGenerator (sprite: sprite)
			
		case powerUpBackstop:
		// Backstop power
			if backstopCatches == 0 {
				backstop.size.height = self.paddleHeight
				backstop.size.width = self.gameWidth-2
				backstop.run(SKAction.scaleX(by: 0.25, y: 1, duration: 0.0), completion: {
					self.backstop.isHidden = false
					self.backstop.run(SKAction.scaleX(by: 4, y: 1, duration: 0.1), completion: {
						self.backstopCatches = 1
						self.backstopCatchesTotal = self.backstopCatches
						self.powerUpMultiplierScore = 0.1
						self.totalStatsArray[0].powerupsCollected[25]+=1
						self.backstop.physicsBody!.categoryBitMask = CollisionTypes.backstopCategory.rawValue
						self.backstop.physicsBody!.collisionBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
						self.backstop.physicsBody!.contactTestBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
						self.ballPhysicsBodySet()
						// Power up set and limit number of catches per power up
					})
				})
			}
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[25]+=1
			// don't do anything if power-up already in place
            
		case powerUpIncreaseBallSize:
        // Increase ball size
			removeAction(forKey: "powerUpIncreaseBallSize")
			removeAction(forKey: "powerUpDecreaseBallSize")
			removeAction(forKey: "powerUpBallSizeTimer")
			removeAction(forKey: "ballSizeTimer")
			// Remove any current ball size power up timers
			
			ballSizeIcon.texture = self.iconBallSizeBigTexture
			ballSizeIconBar.isHidden = false
			// Show power-up icon timer
		
			if ball.xScale == 1.0 {
				ball.run(SKAction.scale(to: 1.5, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
			} else if ball.xScale > 1.0 {
				ball.run(SKAction.scale(to: 2.0, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				
				if totalStatsArray[0].achievementsUnlockedArray[34] == false {
					totalStatsArray[0].achievementsUnlockedArray[34] = true
					totalStatsArray[0].achievementDates[34] = Date()
					let achievement = GKAchievement(identifier: "maxBallSize")
					if achievement.isCompleted == false {
						print("llama llama achievement maxBallSize")
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting maxBallSize achievement")
						}
					}
				}
				// Maximum ball size achievement
			} else if ball.xScale < 1.0 {
				ball.run(SKAction.scale(to: 1.0, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				ballSizeIcon.texture = self.iconBallSizeDisabledTexture
				ballSizeIconBar.isHidden = true
			}

			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[26]+=1
			// Power up set

            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				if self.hapticsSetting! {
					self.rigidHaptic.impactOccurred()
				}
				self.ball.run(SKAction.scale(to: 1, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				self.ballSizeIcon.texture = self.iconBallSizeDisabledTexture
				self.ballSizeIconBar.isHidden = true
				// Hide power-up icons
            }
			ballSizeIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.ballSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "ballSizeTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			ballSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpBallSizeTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpIncreaseBallSize")
            // Power up reverted
            
        case powerUpDecreaseBallSize:
        // Decrease ball size
			removeAction(forKey: "powerUpIncreaseBallSize")
			removeAction(forKey: "powerUpDecreaseBallSize")
			removeAction(forKey: "powerUpBallSizeTimer")
			removeAction(forKey: "ballSizeTimer")
			// Remove any current ball speed power up timers
			
			ballSizeIcon.texture = self.iconBallSizeSmallTexture
			ballSizeIconBar.isHidden = false
			// Show power-up icon timer
			
			if ball.xScale == 1.0 {
				ball.run(SKAction.scale(to: 0.75, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
			} else if ball.xScale < 1.0 {
				ball.run(SKAction.scale(to: 0.5, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				
				if totalStatsArray[0].achievementsUnlockedArray[35] == false {
					totalStatsArray[0].achievementsUnlockedArray[35] = true
					totalStatsArray[0].achievementDates[35] = Date()
					let achievement = GKAchievement(identifier: "minBallSize")
					if achievement.isCompleted == false {
						print("llama llama achievement minBallSize")
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting minBallSize achievement")
						}
					}
				}
				// Minimum ball size achievement
			} else if ball.xScale > 1.0 {
				ball.run(SKAction.scale(to: 1.0, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				ballSizeIcon.texture = self.iconBallSizeDisabledTexture
				ballSizeIconBar.isHidden = true
			}
			
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[27]+=1
            // Power up set
			
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				if self.hapticsSetting! {
					self.rigidHaptic.impactOccurred()
				}
				self.ball.run(SKAction.scale(to: 1, duration: 0.2), completion: {
					self.setBallStartingPositionY()
				})
				self.ballSizeIcon.texture = self.iconBallSizeDisabledTexture
				self.ballSizeIconBar.isHidden = true
				// Hide power-up icons
            }
			ballSizeIconBar.run(SKAction.scaleX(to: 1.0, duration: 0.05), completion: {
				self.ballSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: timer), withKey: "ballSizeTimer")
			})
            let sequence = SKAction.sequence([waitDuration, completionBlock])
			ballSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpBallSizeTimer")
			// Setup timer animation
            self.run(sequence, withKey: "powerUpDecreaseBallSize")
            // Power up reverted
		
        default:
            break
        }
        // Identify power up and perform action
		
		
		if totalStatsArray[0].achievementsUnlockedArray[27] == false {
			let percentComplete = Double(totalStatsArray[0].powerupsCollected.max() ?? 0)/100.0*100.0
			if percentComplete >= 100.0 {
				totalStatsArray[0].achievementsPercentageCompleteArray[27] = "100%"
				totalStatsArray[0].achievementsUnlockedArray[27] = true
				totalStatsArray[0].achievementDates[27] = Date()
			} else if percentComplete < 100.0 {
				let percentCompleteString = String(format:"%.1f", percentComplete)
				totalStatsArray[0].achievementsPercentageCompleteArray[27] = String(percentCompleteString)+"%"
			}
			let achievement = GKAchievement(identifier: "favouritePowerUp")
			if achievement.isCompleted == false {
				print("llama llama achievement favouritePowerUp: ", percentComplete)
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting favouritePowerUp achievement")
				}
			}
		}
		
		
		if totalStatsArray[0].achievementsUnlockedArray[28] == false {
			let percentComplete = Double(totalStatsArray[0].powerupsCollected.reduce(0, +))/100.0*100.0
			if percentComplete >= 100.0 {
				totalStatsArray[0].achievementsPercentageCompleteArray[28] = "100%"
				totalStatsArray[0].achievementsUnlockedArray[28] = true
				totalStatsArray[0].achievementDates[28] = Date()
			} else if percentComplete < 100.0 {
				let percentCompleteString = String(format:"%.1f", percentComplete)
				totalStatsArray[0].achievementsPercentageCompleteArray[28] = String(percentCompleteString)+"%"
			}
			let achievement = GKAchievement(identifier: "powerUpCollectorHundred")
			if achievement.isCompleted == false {
				print("llama llama achievement powerUpCollectorHundred: ", percentComplete)
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting powerUpCollectorHundred achievement")
				}
			}
		}
		if totalStatsArray[0].achievementsUnlockedArray[29] == false {
			let percentComplete = Double(totalStatsArray[0].powerupsCollected.reduce(0, +))/1000.0*100.0
			if percentComplete >= 100.0 {
				totalStatsArray[0].achievementsPercentageCompleteArray[29] = "100%"
				totalStatsArray[0].achievementsUnlockedArray[29] = true
				totalStatsArray[0].achievementDates[29] = Date()
			} else if percentComplete < 100.0 {
				let percentCompleteString = String(format:"%.1f", percentComplete)
				totalStatsArray[0].achievementsPercentageCompleteArray[29] = String(percentCompleteString)+"%"
			}
			let achievement = GKAchievement(identifier: "powerUpCollectorThousand")
			if achievement.isCompleted == false {
				print("llama llama achievement powerUpCollectorThousand: ", percentComplete)
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					print(error?.localizedDescription ?? "Error reporting powerUpCollectorThousand achievement")
				}
			}
		}
		// Power-up collection achievements

		powerUpsCollectedPerLevel+=1
        levelScore = levelScore + Int(Double(powerUpScore) * multiplier)
		multiplier = multiplier + powerUpMultiplierScore
		if multiplier < 1.0 {
			multiplier = 1.0
			multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
		}
		if multiplier >= 2.0 {
			multiplier = 2.0
			multiplierLabel.fontColor = #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1)
		}
		// Ensure multiplier never goes below 1 or above 2
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		scoreFactorString = String(format:"%.1f", multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight) m"
		}
		multiplierLabel.text = "x\(scoreFactorString)"
        // Update score
    }
	
	func removePowerUp(sprite: SKSpriteNode, powerUp: SKSpriteNode, powerUpSelection: Int) {
		powerUp.removeFromParent()
		self.powerUpGenerator (sprite: sprite)
	}
	
	func setBallStartingPositionY() {
		ballStartingPositionY = paddlePositionY + paddleHeight/2 + ball.size.height/2 + 1
		if ballIsOnPaddle {
			ball.position.y = ballStartingPositionY
			// Ensure ball remains on paddle
		}
	}
	
	func paddleCenterRectZero() {
		paddle.centerRect = CGRect(x: 0.0/80.0, y: 0.0/10.0, width: 80.0/80.0, height: 10.0/10.0)
		paddleLaser.centerRect = CGRect(x: 0.0/80.0, y: 0.0/16.0, width: 80.0/80.0, height: 16.0/16.0)
		paddleSticky.centerRect = CGRect(x: 0.0/80.0, y: 0.0/11.0, width: 80.0/80.0, height: 11.0/11.0)
		paddleRetroTexture.centerRect = CGRect(x: 0.0/91.0, y: 0.0/26.0, width: 91.0/91.0, height: 26.0/26.0)
		paddleRetroLaserTexture.centerRect = CGRect(x: 0.0/91.0, y: 0.0/26.0, width: 91.0/91.0, height: 26.0/26.0)
		paddleRetroStickyTexture.centerRect = CGRect(x: 20.0/91.0, y: 0.0/24.0, width: 51.0/91.0, height: 24.0/24.0)
	}
	
	func paddleCenterRectPlus() {
		paddle.centerRect = CGRect(x: 10.0/80.0, y: 0.0/10.0, width: 60.0/80.0, height: 10.0/10.0)
		paddleLaser.centerRect = CGRect(x: 10.0/80.0, y: 0.0/16.0, width: 60.0/80.0, height: 16.0/16.0)
		paddleSticky.centerRect = CGRect(x: 10.0/80.0, y: 0.0/11.0, width: 60.0/80.0, height: 11.0/11.0)
		paddleRetroTexture.centerRect = CGRect(x: 15.0/91.0, y: 0.0/26.0, width: 61.0/91.0, height: 26.0/26.0)
		paddleRetroLaserTexture.centerRect = CGRect(x: 25.0/91.0, y: 0.0/26.0, width: 41.0/91.0, height: 26.0/26.0)
		paddleRetroStickyTexture.centerRect = CGRect(x: 20.0/91.0, y: 0.0/24.0, width: 51.0/91.0, height: 24.0/24.0)
	}
	
	func powerUpIconReset(sender: String) {
		// speed[2], paddle size[4], hide[16], sticky[6], gravity[7], giga[20], laser[22], size[26]
		if premiumSetting! {
			totalStatsArray[0].powerUpUnlockedArray[2] = true
			totalStatsArray[0].powerUpUnlockedArray[4] = true
			totalStatsArray[0].powerUpUnlockedArray[16] = true
			totalStatsArray[0].powerUpUnlockedArray[6] = true
			totalStatsArray[0].powerUpUnlockedArray[7] = true
			totalStatsArray[0].powerUpUnlockedArray[20] = true
			totalStatsArray[0].powerUpUnlockedArray[22] = true
			totalStatsArray[0].powerUpUnlockedArray[26] = true
		}
		iconUnlockedBool = [totalStatsArray[0].powerUpUnlockedArray[2], totalStatsArray[0].powerUpUnlockedArray[4], totalStatsArray[0].powerUpUnlockedArray[16], totalStatsArray[0].powerUpUnlockedArray[6], totalStatsArray[0].powerUpUnlockedArray[7], totalStatsArray[0].powerUpUnlockedArray[20], totalStatsArray[0].powerUpUnlockedArray[22], totalStatsArray[0].powerUpUnlockedArray[26]]
		for i in 1...iconArray.count {
            let index = i-1
			if sender == "Pause" {
				if iconArray[index].texture == iconLockedTexture {
					if iconUnlockedBool[index] {
						iconArray[index].texture = disabledIconTextureArray[index]
					} else {
						iconArray[index].texture = iconLockedTexture
					}
				}
			} else {
				if iconUnlockedBool[index] {
					iconArray[index].texture = disabledIconTextureArray[index]
				} else {
					iconArray[index].texture = iconLockedTexture
				}
			}
        }
        // Show locked icon if power-up locked
	}
    
    func powerUpsReset() {
        self.removeAllActions()
        // Stop all timers and animations
		powerUpsOnScreen = 0
		multiplier = 1.0
		multiplierLabel.fontColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
		ball.physicsBody!.linearDamping = ballLinearDampening
		powerUpLimit = 2
		ball.texture = ballTexture
		ballPhysicsBodySet()
		gigaBallIconBar.isHidden = true
		deactivateGigaBall()
		// Giga-Ball/Undestructiball reset
		
		paddleCenterRectZero()
		paddle.run(SKAction.scaleX(to: 1.0, duration: 0.2), completion: {
			self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
		})
		paddleLaser.run(SKAction.scaleX(to: 1.0, duration: 0.2))
		paddleSticky.run(SKAction.scaleX(to: 1.0, duration: 0.2))
		paddleRetroTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
		paddleRetroLaserTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
		paddleRetroStickyTexture.run(SKAction.scaleX(to: 1.0, duration: 0.2))
		paddleSizeIconBar.isHidden = true
		// Paddle size reset
		
		ballSpeedLimit = ballSpeedNominal
		ballSpeedIconBar.isHidden = true
		// Ball speed reset
		
		laserTimer?.invalidate()
		paddleLaser.isHidden = true
		paddleRetroLaserTexture.isHidden = true
		if paddleTexture == retroPaddle {
			paddleRetroTexture.isHidden = false
		}
		lasersIconBar.isHidden = true
		laserPowerUpIsOn = false
		paddle.isHidden = false
		// Laser reset
		
		deactivateGravity()
		physicsWorld.gravity = CGVector(dx: 0, dy: 0)
		ball.physicsBody!.affectedByGravity = false
		gravityActivated = false
		gravityIconBar.isHidden = true
		// Gravity reset
		
		paddleSticky.isHidden = true
		paddleRetroStickyTexture.isHidden = true
		stickyPaddleCatches = 0
		stickyPaddleCatchesTotal = 0
		stickyPaddleIconBar.isHidden = true
		stickyPaddleIconBar.xScale = 0
		// Sticky paddle reset
		
		backstop.run(SKAction.scaleX(by: 0.25, y: 1, duration: 0.1),completion: {
			self.backstop.isHidden = true
			self.backstopCatches = 0
			self.backstopCatchesTotal = 0
			self.backstop.physicsBody!.categoryBitMask = 0
			self.backstop.physicsBody!.collisionBitMask = 0
			self.backstop.physicsBody!.contactTestBitMask = 0
			self.backstop.run(SKAction.scaleX(by: 4, y: 1, duration: 0.0))
		})
		backstopHit = false
		paddle.physicsBody!.isDynamic = true
		// Backstop paddle reset
		
		ballSizeIconBar.isHidden = true
		ball.run(SKAction.scale(to: 1.0, duration: 0.2), completion: {
			self.setBallStartingPositionY()
		})
		// Ball size reset
		
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			let temporarySprite = node as! SKSpriteNode
			if node.isHidden == true && temporarySprite.texture != self.brickInvisibleTexture {
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
		hiddenBricksIconBar.isHidden = true
		// Invisible bricks reset
		
		powerUpIconReset(sender: "")
		// Remove any existing power-up icons
    }
	
	func ballPhysicsBodySet() {
		if backstopHit && ball.texture != gigaBallTexture {
			ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
			ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
		}
		else if backstopHit && ball.texture == gigaBallTexture {
			ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue
			ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
		}
		else if ball.texture == gigaBallTexture {
		// Giga-Ball power-up
			ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue | CollisionTypes.backstopCategory.rawValue
			// Reset undestructi-ball power-up
			ball.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.backstopCategory.rawValue
			// Set giga-ball power-up
		} else {
			ball.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.backstopCategory.rawValue
			ball.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue | CollisionTypes.backstopCategory.rawValue
			// Set ball physics body
		}
	}
	// Set ball's physics bodies
    
    func moveToMainMenu() {
		gameViewControllerDelegate?.moveToMainMenu()
    }
    // Function to return to the MainViewController from the GameViewController, run as a delegate from GameViewController
	
	func showPauseMenu(sender: String) {
		
		self.removeAction(forKey: "gameTimer")
		// Stop the level timer
		
		readyCountdown.isHidden = true
		goCountdown.isHidden = true
		
		var score = totalScore
		if sender == "Pause" {
			score = totalScore + levelScore
			// Update score for pause menu
		} else {
            scoreLabel.isHidden = true
            multiplierLabel.isHidden = true
            pauseButton.isHidden = true
            livesLabel.isHidden = true
            life.isHidden = true
			// Hide UI
		}
				
		gameViewControllerDelegate?.showPauseMenu(levelNumber: levelNumber, numberOfLevels: numberOfLevels, score: score, packNumber: packNumber, height: endlessHeight, sender: sender, gameoverBool: gameoverStatus, newItemsBool: newItemsBool, previousHighscore: previousHighscore)
		// Pass over highscore data to pause menu
    }
	
	func showInbetweenView() {
		gameViewControllerDelegate?.showInbetweenView(levelNumber: levelNumber, score: totalScore, packNumber: packNumber, levelTimerBonus: levelTimerBonus, firstLevel: firstLevel, numberOfLevels: numberOfLevels, levelScore: levelScore)
		// Pass over data to inbetween view
	}

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
	
	func userSettings() {
		premiumSetting = defaults.bool(forKey: "premiumSetting")
		adsSetting = defaults.bool(forKey: "adsSetting")
		soundsSetting = defaults.bool(forKey: "soundsSetting")
		musicSetting = defaults.bool(forKey: "musicSetting")
		hapticsSetting = defaults.bool(forKey: "hapticsSetting")
		parallaxSetting = defaults.bool(forKey: "parallaxSetting")
		paddleSensitivitySetting = defaults.integer(forKey: "paddleSensitivitySetting")
		gameCenterSetting = defaults.bool(forKey: "gameCenterSetting")
		ballSetting = defaults.integer(forKey: "ballSetting")
        paddleSetting = defaults.integer(forKey: "paddleSetting")
		brickSetting = defaults.integer(forKey: "brickSetting")
        appIconSetting = defaults.integer(forKey: "appIconSetting")
		swipeUpPause = defaults.bool(forKey: "swipeUpPause")
		gameInProgress = defaults.bool(forKey: "gameInProgress")
		resumeGameToLoad = defaults.bool(forKey: "resumeGameToLoad")
		// User settings
		
		saveGameSaveArray = defaults.object(forKey: "saveGameSaveArray") as! [Int]?
        saveMultiplier = defaults.double(forKey: "saveMultiplier")
        saveBrickTextureArray = defaults.object(forKey: "saveBrickTextureArray") as! [Int]?
        saveBrickColourArray = defaults.object(forKey: "saveBrickColourArray") as! [Int]?
        saveBrickXPositionArray = defaults.object(forKey: "saveBrickXPositionArray") as! [Int]?
        saveBrickYPositionArray = defaults.object(forKey: "saveBrickYPositionArray") as! [Int]?
		saveBallPropertiesArray = defaults.object(forKey: "saveBallPropertiesArray") as! [Double]?
		savePowerUpFallingXPositionArray = defaults.object(forKey: "savePowerUpFallingXPositionArray") as! [Int]?
		savePowerUpFallingYPositionArray = defaults.object(forKey: "savePowerUpFallingYPositionArray") as! [Int]?
		savePowerUpFallingArray = defaults.object(forKey: "savePowerUpFallingArray") as! [Int]?
		savePowerUpActiveArray = defaults.object(forKey: "savePowerUpActiveArray") as! [String]?
		savePowerUpActiveDurationArray = defaults.object(forKey: "savePowerUpActiveDurationArray") as! [Double]?
		savePowerUpActiveTimerArray = defaults.object(forKey: "savePowerUpActiveTimerArray") as! [Double]?
		savePowerUpActiveMagnitudeArray = defaults.object(forKey: "savePowerUpActiveMagnitudeArray") as! [Int]?
        // Game save settings
		
		paddle.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
		if ballIsOnPaddle {
			ball.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
		}
		// Stop paddle and ball tilt
		
		if paddleSensitivitySetting == 0 {
			paddleMovementFactor = 1.00
		} else if paddleSensitivitySetting == 1 {
			paddleMovementFactor = 1.25
		} else if paddleSensitivitySetting == 2 {
			paddleMovementFactor = 1.50
		} else if paddleSensitivitySetting == 3 {
			paddleMovementFactor = 2.00
		} else if paddleSensitivitySetting == 4 {
			paddleMovementFactor = 3.00
		}
		// Reset paddle sensitivity
	}
	// Set user settings
	
	func ballStuck() {
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			let temporarySprite = node as! SKSpriteNode
			if temporarySprite.texture == self.brickIndestructible1Texture || temporarySprite.texture == self.brickIndestructible2Texture {
				temporarySprite.texture = self.brickNullTexture
				self.removeBrick(node: node, sprite: temporarySprite)
			}
		}
		brickBounceCounter = 0
	}

	func ballHorizontalControl(angleDegInput: Double) {
		
		if gravityActivated && ball.position.y > paddle.position.y + ballSize*4 {
			return
		}
		// Do not run ball angle correction if gravity is activated and the ball is above the non-gravity area
		
		var xSpeed = ball.physicsBody!.velocity.dx
		var ySpeed = ball.physicsBody!.velocity.dy
		let currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
		var angleDeg = angleDegInput
		
//		print("Llama start horizontal angle: ", angleDeg)
		
		if angleDeg <= minAngleDeg && angleDeg > 0 {
//			print("Horizontal correction 1")
			angleDeg = minAngleDeg
		}
		// Up and right
		if angleDeg >= -minAngleDeg && angleDeg <= 0 {
//			print("Horizontal correction 2")
			angleDeg = -minAngleDeg
		}
		// Down and right
		if angleDeg <= 180+minAngleDeg && angleDeg >= 180-minAngleDeg {
//			print("Horizontal correction 3")
			angleDeg = 180-minAngleDeg
		}
		// Up and left
		if angleDeg >= -180-minAngleDeg && angleDeg <= -180+minAngleDeg {
//			print("Horizontal correction 4")
			angleDeg = -180+minAngleDeg
		}
		// Down and left

//		print("Llama new horizontal angle: ", angleDeg)
		
		let angleRad = (angleDeg*Double.pi/180)
		xSpeed = CGFloat(cos(angleRad)) * currentSpeed
		ySpeed = CGFloat(sin(angleRad)) * currentSpeed
		ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
		// Set the new angle of the ball
	}
	
	func ballVerticalControl() {
		
		if gravityActivated && ball.position.y > paddle.position.y + ballSize*4 {
			return
		}
		// Do not run ball angle correction if gravity is activated and the ball is above the non-gravity area
		
		var xSpeed = ball.physicsBody!.velocity.dx
		var ySpeed = ball.physicsBody!.velocity.dy
		let currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
		var angleDeg = Double(atan2(ySpeed, xSpeed))/Double.pi*180
		let verticalMinAngle = minAngleDeg/2
		
//		print("Llama start vertical angle: ", angleDeg)
		
		// Vertical Control
		if ball.position.x >= 0 {
			// ball is on right side of screen
			if angleDeg > 90-verticalMinAngle && angleDeg <= 90 {
//				print("Vertical correction R1")
				angleDeg = 90-verticalMinAngle
			}
			// Travelling up and right
			if angleDeg <= 90+verticalMinAngle && angleDeg > 90 {
//				print("Vertical correction R2")
				angleDeg = 90+verticalMinAngle
			}
			// Travelling up and left
			if angleDeg >= -90 && angleDeg < -90+verticalMinAngle {
//				print("Vertical correction R3")
				angleDeg = -90+verticalMinAngle
			}
			// Travelling down and right
			if angleDeg < -90 && angleDeg >= -90-verticalMinAngle {
//				print("Vertical correction R4")
				angleDeg = -90-verticalMinAngle
			}
			// Travelling down and left
		} else {
			// ball is on left side of screen
			if angleDeg >= 90-verticalMinAngle && angleDeg < 90 {
//				print("Vertical correction L1")
				angleDeg = 90-verticalMinAngle
			}
			// Travelling up and right
			if angleDeg < 90+verticalMinAngle && angleDeg >= 90 {
//				print("Vertical correction L2")
				angleDeg = 90+verticalMinAngle
			}
			// Travelling up and left
			if angleDeg > -90 && angleDeg <= -90+verticalMinAngle {
//				print("Vertical correction L3")
				angleDeg = -90+verticalMinAngle
			}
			// Travelling down and right
			if angleDeg <= -90 && angleDeg > -90-verticalMinAngle {
//				print("Vertical correction L4")
				angleDeg = -90-verticalMinAngle
			}
			// Travelling down and left
		}
		
//		print("Llama new vertical angle: ", angleDeg)
		
		let angleRad = (angleDeg*Double.pi/180)
		xSpeed = CGFloat(cos(angleRad)) * currentSpeed
		ySpeed = CGFloat(sin(angleRad)) * currentSpeed
		ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
		// Set the new angle of the ball
	}
	
	func ballSpeedControl() {
		let xSpeed = ball.physicsBody!.velocity.dx
		let ySpeed = ball.physicsBody!.velocity.dy
		let currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
		if currentSpeed > ballSpeedLimit + currentSpeed/10 {
			ball.physicsBody!.linearDamping = 1.0
		} else if currentSpeed < ballSpeedLimit {
			if gravityActivated == false || ball.position.y < paddle.position.y + ballSize*4 {
				ball.physicsBody!.linearDamping = -1.0
			}
		} else {
			ball.physicsBody!.linearDamping = ballLinearDampening
		}
	}
	// Set the new speed of the ball and ensure it stays within the boundary
	
	func frameBallControl(xSpeed: CGFloat) {
		let ySpeed = ball.physicsBody!.velocity.dy
		var newXSpeed = xSpeed
		if (ball.position.x > 0 && xSpeed > 0) || (ball.position.x < 0 && xSpeed < 0) {
			newXSpeed = -xSpeed
		}
		ball.physicsBody!.velocity = CGVector(dx: newXSpeed, dy: ySpeed)
		// Ensure the ball bounces off the wall correctly]
//		print("Frame control")
		
		let angleDeg = Double(atan2(Double(ball.physicsBody!.velocity.dy), Double(ball.physicsBody!.velocity.dx)))/Double.pi*180
		ballHorizontalControl(angleDegInput: angleDeg)
	}
	
    @objc func laserGenerator() {
		
		if gameState.currentState is Playing {
        
			let laser = SKSpriteNode(imageNamed: "LaserNormal")
			
			laser.texture = laserNormalTexture
			
			
			if paddleTexture == rainbowPaddle {
				if rainbowLaserIndex > rainbowLaserArray.count-1 {
					rainbowLaserIndex = 0
				}
				laserNormalTexture = rainbowLaserArray[rainbowLaserIndex]
				rainbowLaserIndex+=1
			}
			// rainbow lasers
			
			if paddleTexture == candyPaddle {
				if stripyLaserIndex > stripyLaserArray.count-1 {
					stripyLaserIndex = 0
				}
				laserNormalTexture = stripyLaserArray[stripyLaserIndex]
				stripyLaserIndex+=1
			}
			// stripy lasers
			
			if paddleTexture == retroPaddle {
				if retroLaserIndex > retroLaserArray.count-1 {
					retroLaserIndex = 0
				}
				laserNormalTexture = retroLaserArray[retroLaserIndex]
				retroLaserIndex+=1
			}
			// retro lasers
			
			laser.size.width = layoutUnit/4
			laser.size.height = laser.size.width*4
			
			if laserSideLeft {
				laser.position = CGPoint(x: paddle.position.x - paddle.size.width/2 + laser.size.width, y: paddle.position.y + paddleLaser.size.height/2 + laser.size.height/2)
				
				if paddleTexture == retroPaddle {
					laser.position = CGPoint(x: paddleRetroLaserTexture.position.x - paddleRetroLaserTexture.size.width/2 + laser.size.width, y: paddleRetroLaserTexture.position.y + paddleRetroLaserTexture.size.height/2 + laser.size.height/2)
				}
				// adjust laser position when using retro paddle
				
				laser.texture = laserNormalTexture
				laserSideLeft = false
				// Left position
			} else {
				laser.position = CGPoint(x: paddle.position.x + paddle.size.width/2  - laser.size.width, y: paddle.position.y + paddleLaser.size.height/2 + laser.size.height/2)
				
				if paddleTexture == retroPaddle {
					laser.position = CGPoint(x: paddleRetroLaserTexture.position.x + paddleRetroLaserTexture.size.width/2 - laser.size.width, y: paddleRetroLaserTexture.position.y + paddleRetroLaserTexture.size.height/2 + laser.size.height/2)
				}
				// adjust laser position when using retro paddle
				
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
			
			if ball.texture == gigaBallTexture {
				laser.physicsBody!.collisionBitMask = 0
				laser.texture = laserGigaTexture
				
				if totalStatsArray[0].achievementsUnlockedArray[25] == false {
					totalStatsArray[0].achievementsUnlockedArray[25] = true
                    totalStatsArray[0].achievementDates[25] = Date()
					let achievement = GKAchievement(identifier: "gigaLasers")
					if achievement.isCompleted == false {
						print("llama llama achievement gigaLasers")
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							print(error?.localizedDescription ?? "Error reporting gigaLasers achievement")
						}
					}
				}
				// Giga-lasers achievement
			}
			// If giga-ball power up is activated, allow laser to pass through bricks
			
			addChild(laser)
			totalStatsArray[0].lasersFired+=1
			
			if soundsSetting! {
				self.run(laserFiredSound)
			}
			// Laser fired sound
			
			let move = SKAction.moveBy(x: 0, y: frame.height, duration: 2)
			laser.run(move, completion: {
				laser.removeFromParent()
			})
			// Define laser movement
		}
    }
    
    @objc func pauseNotificationKeyReceived() {
		
		if self.gameState.currentState is Paused {
			// do nothing
		} else if self.gameState.currentState is Playing {
			clearSavedGame()
			// Clear current saved game before re-saving
			self.gameState.enter(Paused.self)
		}
    }
    // Pause the game if a notifcation from AppDelegate is received that the game will quit
	
	@objc func restartGameNotificiationKeyReceived() {
				
		if numberOfLevels > 1 {
			startLevelNumber = LevelPackSetup().startLevelNumber[packNumber]
			numberOfLevels = LevelPackSetup().numberOfLevels[packNumber]

			gameViewControllerDelegate?.selectedLevel = startLevelNumber
			gameViewControllerDelegate?.numberOfLevels = numberOfLevels
			gameViewControllerDelegate?.levelSender = levelSender
			gameViewControllerDelegate?.levelPack = packNumber
		}
		
		clearSavedGame()
		// If restarting after resuming, make sure the correct level is selected
		
        gameState.enter(PreGame.self)
    }
    // Pause the game if a notifcation from AppDelegate is received that the game will quit
	
	@objc func swipeGesture(gesture: UISwipeGestureRecognizer) -> Void {
		if endlessMoveInProgress == false && gameState.currentState is Playing && swipeUpPause! {
			clearSavedGame()
			gameState.enter(Paused.self)
		}
		// Don't allow pause if brick down animation is in progress
	}
	
	func saveGameStats() {
		totalStatsArray[0].dateSaved = Date()
		do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            print("Error encoding total stats, \(error)")
        }
		CloudKitHandler().saveTotalStats()
        // Save total stats
	}
	
	func saveCurrentGame() {
		
		print("llama llama save current game")
		
		if numberOfLives == 0 && ballLostBool && ballIsOnPaddle == false {
			clearSavedGame()
			return
		}
		// If number of lives is 0 and ball lost animtion has started, don't save current game
		
		saveGameStats()
		// Save total, pack and level stats arrays
				
		var currentLevelNumber = levelNumber
		let currentEndLevelNumber = endLevelNumber
		let currentPackNumber = packNumber
		let currentLevelScore = levelScore
		let currentTotalScore = totalScore + levelScore
		var currentNumberOfLives = numberOfLives
		let currentHeight = endlessHeight
		let currentNumberOfLevels = numberOfLevels
		let currentLevelTimerValue = levelTimerValue
		let currentPackTimerValue = packTimerValue

		if (gameState.currentState is InbetweenLevels || gameState.currentState is Ad) && gameoverStatus == false {
			if numberOfLevels > 1 {
				currentLevelNumber+=1
			} else {
				clearSavedGame()
				return
			}
		}
		// If inbetween levels but only playing 1 level at a time don't save
		
		let gameSaveArray = [currentLevelNumber, currentEndLevelNumber, currentPackNumber, currentLevelScore, currentTotalScore, currentNumberOfLives, currentHeight, currentNumberOfLevels, currentLevelTimerValue, currentPackTimerValue]
		
		var currentMultiplier = multiplier
		
		if ballLostBool {
			currentNumberOfLives-=1
		}
		// If ball is lost on pause, update properties to reflect that when reloading the game
		
		if ballLostBool || gameState.currentState is InbetweenLevels || gameState.currentState is Ad {
			currentMultiplier = 1.0
		}
		// If ball is lost or inbetween levels or ads, reset the multiplier
		
		var brickTextureArray: [Int]? = []
		var brickColourArray: [Int]? = []
		var brickXPositionArray: [Int]? = []
		var brickYPositionArray: [Int]? = []
		var ballPropertiesArray: [Double]? = []
		
		var powerUpFallingXPositionArray: [Int]? = []
		var powerUpFallingYPositionArray: [Int]? = []
		var powerUpFallingArray: [Int]? = []
		
		var powerUpActiveArray: [String]? = []
		var powerUpActiveDurationArray: [Double]? = []
		var powerUpActiveTimerArray: [Double]? = []
		var powerUpActiveMagnitudeArray: [Int]? = []
		
		if gameState.currentState is Playing || gameState.currentState is Paused {
			
			if let ballSpeedPowerUp = self.ballSpeedIconBar.action(forKey: "ballSpeedTimer") {
				if ballSpeedLimit != ballSpeedNominal {
					let remainingTime = Double(ballSpeedPowerUp.duration) * Double(ballSpeedIconBar.xScale)
					powerUpActiveArray?.append("ballSpeedTimer")
					powerUpActiveDurationArray?.append(remainingTime)
					powerUpActiveTimerArray?.append(Double(ballSpeedPowerUp.duration))
					var magnitude: Int?
					if ballSpeedLimit < ballSpeedNominal {
						if ballSpeedLimit < ballSpeedSlow {
							magnitude = 0 // Slowest
						} else {
							magnitude = 1 // Slow
						}
					} else {
						if ballSpeedLimit < ballSpeedFastest {
							magnitude = 2 // Fast
						} else {
							magnitude = 3 // Fastest
						}
					}
					powerUpActiveMagnitudeArray?.append(magnitude!)
				}
			}
			if let paddleSizePowerUp = self.paddleSizeIconBar.action(forKey: "paddleSizeTimer") {
				if paddle.xScale != 1.0 {
					let remainingTime = Double(paddleSizePowerUp.duration) * Double(paddleSizeIconBar.xScale)
					powerUpActiveArray?.append("paddleSizeTimer")
					powerUpActiveDurationArray?.append(remainingTime)
					powerUpActiveTimerArray?.append(Double(paddleSizePowerUp.duration))
					var magnitude: Int?
					if paddle.xScale < 1.0 {
						if paddle.xScale < 0.75 {
							magnitude = 0 // 0.5
						} else {
							magnitude = 1 // 0.75
						}
					} else {
						if paddle.xScale < 2.0 {
							magnitude = 2 // 1.5
						} else if paddle.xScale < 2.5 {
							magnitude = 3 // 2.0
						} else {
							magnitude = 4 // 2.5
						}
					}
					powerUpActiveMagnitudeArray?.append(magnitude!)
				}
			}
			if let gravityPowerUp = self.gravityIconBar.action(forKey: "gravityTimer") {
				let remainingTime = Double(gravityPowerUp.duration) * Double(gravityIconBar.xScale)
				powerUpActiveArray?.append("gravityTimer")
				powerUpActiveDurationArray?.append(remainingTime)
				powerUpActiveTimerArray?.append(Double(gravityPowerUp.duration))
				powerUpActiveMagnitudeArray?.append(0)
			}
			
			if let invisiblePowerUp = self.hiddenBricksIconBar.action(forKey: "invisibleBricksTimer") {
				let remainingTime = Double(invisiblePowerUp.duration) * Double(hiddenBricksIconBar.xScale)
				powerUpActiveArray?.append("invisibleBricksTimer")
				powerUpActiveDurationArray?.append(remainingTime)
				powerUpActiveTimerArray?.append(Double(invisiblePowerUp.duration))
				powerUpActiveMagnitudeArray?.append(0)
			}
			if let gigaBallPowerUp = self.gigaBallIconBar.action(forKey: "gigaBallTimer") {
				let remainingTime = Double(gigaBallPowerUp.duration) * Double(gigaBallIconBar.xScale)
				powerUpActiveArray?.append("gigaBallTimer")
				powerUpActiveDurationArray?.append(remainingTime)
				powerUpActiveTimerArray?.append(Double(gigaBallPowerUp.duration))
				var magnitude: Int?
				if ball.texture == gigaBallTexture {
					magnitude = 0 // giga-ball
				} else {
					magnitude = 1 // undestructi-ball
				}
				powerUpActiveMagnitudeArray?.append(magnitude!)
			}
			if let laserPowerUp = self.lasersIconBar.action(forKey: "laserTimer") {
				let remainingTime = Double(laserPowerUp.duration) * Double(lasersIconBar.xScale)
				powerUpActiveArray?.append("laserTimer")
				powerUpActiveDurationArray?.append(remainingTime)
				powerUpActiveTimerArray?.append(Double(laserPowerUp.duration))
				powerUpActiveMagnitudeArray?.append(0)
			}
			if let ballSizePowerUp = self.ballSizeIconBar.action(forKey: "ballSizeTimer") {
				if ball.xScale != 1.0 {
					let remainingTime = Double(ballSizePowerUp.duration) * Double(ballSizeIconBar.xScale)
					powerUpActiveArray?.append("ballSizeTimer")
					powerUpActiveDurationArray?.append(remainingTime)
					powerUpActiveTimerArray?.append(Double(ballSizePowerUp.duration))
					var magnitude: Int?
					if ball.xScale < 1.0 {
						if ball.xScale < 0.75 {
							magnitude = 0 // Smallest
						} else {
							magnitude = 1 // Small
						}
					} else {
						if ball.xScale < 2.0 {
							magnitude = 2 // Big
						} else {
							magnitude = 3 // Biggest
						}
					}
					powerUpActiveMagnitudeArray?.append(magnitude!)
				}
			}
			if stickyPaddleCatches != 0 {
				powerUpActiveArray?.append("stickyPaddle")
				powerUpActiveDurationArray?.append(0)
				powerUpActiveTimerArray?.append(0)
				powerUpActiveMagnitudeArray?.append(stickyPaddleCatches)
			}
			if backstopCatches != 0 {
				powerUpActiveArray?.append("backstop")
				powerUpActiveDurationArray?.append(0)
				powerUpActiveTimerArray?.append(0)
				powerUpActiveMagnitudeArray?.append(backstopCatches)
			}
			
			enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
				let sprite = node as! SKSpriteNode
				var spriteTextureIndex: Int?
				switch sprite.texture {
				case self.brickNormalTexture:
					if sprite.isHidden == false {
						spriteTextureIndex = 0
					} else {
						spriteTextureIndex = 1
					}
				case self.brickInvisibleTexture:
					if sprite.isHidden == false {
						spriteTextureIndex = 2
					} else {
						spriteTextureIndex = 3
					}
				case self.brickMultiHit1Texture:
					spriteTextureIndex = 4
				case self.brickMultiHit2Texture:
					spriteTextureIndex = 5
				case self.brickMultiHit3Texture:
					spriteTextureIndex = 6
				case self.brickMultiHit4Texture:
					spriteTextureIndex = 7
				case self.brickIndestructible1Texture:
					spriteTextureIndex = 8
				case self.brickIndestructible2Texture:
					spriteTextureIndex = 9
				case self.brickNullTexture:
					spriteTextureIndex = 10
				default:
					spriteTextureIndex = 0
				}
				
				var spriteColourIndex: Int?
				switch sprite.color {
				case self.brickBlue:
					spriteColourIndex = 0
				case self.brickBlueDark:
					spriteColourIndex = 1
				case self.brickBlueDarkExtra:
					spriteColourIndex = 2
				case self.brickBlueLight:
					spriteColourIndex = 3
				case self.brickGreenGigaball:
					spriteColourIndex = 4
				case self.brickGreenSI:
					spriteColourIndex = 5
				case self.brickGrey:
					spriteColourIndex = 6
				case self.brickGreyDark:
					spriteColourIndex = 7
				case self.brickGreyLight:
					spriteColourIndex = 8
				case self.brickOrange:
					spriteColourIndex = 9
				case self.brickOrangeDark:
					spriteColourIndex = 10
				case self.brickOrangeLight:
					spriteColourIndex = 11
				case self.brickPink:
					spriteColourIndex = 12
				case self.brickPurple:
					spriteColourIndex = 13
				case self.brickWhite:
					spriteColourIndex = 14
				case self.brickYellow:
					spriteColourIndex = 15
				case self.brickYellowLight:
					spriteColourIndex = 16
					
				case self.brickBrown:
					spriteColourIndex = 17
				case self.brickBrownLight:
					spriteColourIndex = 18
				case self.brickGreen:
					spriteColourIndex = 19
				case self.brickGreenDark:
					spriteColourIndex = 20
				case self.brickGreenLight:
					spriteColourIndex = 21
				case self.brickPurpleDark:
					spriteColourIndex = 22
				case self.brickYellowDark:
					spriteColourIndex = 23
					
				default:
					spriteColourIndex = 100
				}
				
				let currentBrickTexture = spriteTextureIndex
				let currentBrickColour = spriteColourIndex
				brickTextureArray!.append(currentBrickTexture!)
				brickColourArray!.append(currentBrickColour!)
				
				var currentBrickXIndex = Double((self.gameWidth/2 - self.brickWidth/2 - sprite.position.x)/self.brickWidth)
				var currentBrickYIndex = Double((self.yBrickOffset - sprite.position.y)/self.brickHeight)
				if self.endlessMode {
					currentBrickYIndex = Double((self.yBrickOffsetEndless - sprite.position.y)/self.brickHeight)
				}
				
				currentBrickXIndex = round(currentBrickXIndex)
				currentBrickYIndex = round(currentBrickYIndex)
				// Round to the nearest integer
				
				brickXPositionArray!.append(Int(currentBrickXIndex))
				brickYPositionArray!.append(Int(currentBrickYIndex))
			}
			// Brick save
				
			if ballIsOnPaddle == false && self.ballLostBool == false && (gameState.currentState is Playing || gameState.currentState is Paused) {
				let ballXPosition = Double(ball.position.x)
				let ballYPosition = Double(ball.position.y)
				let ballDXVelocity = Double(pauseBallVelocityX)
				let ballDYVelocity = Double(pauseBallVelocityY)
				let paddleXPosition = Double(paddle.position.x)
				ballPropertiesArray = [ballXPosition, ballYPosition, ballDXVelocity, ballDYVelocity, paddleXPosition]
			}
			// Only save ball properties if ball is in play and not on paddle
			
			enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
				let sprite = node as! SKSpriteNode
				var powerUpTextureIndex: Int = 0
				
				if sprite.zPosition == 1 {
					return
				}
				// Don't save power-ups that are animating out after collection
								
				switch sprite.texture {
				case self.powerUpGetALife:
					powerUpTextureIndex = 0
				case self.powerUpLoseALife:
					powerUpTextureIndex = 1
				case self.powerUpDecreaseBallSpeed:
					powerUpTextureIndex = 2
				case self.powerUpIncreaseBallSpeed:
					powerUpTextureIndex = 3
				case self.powerUpIncreasePaddleSize:
					powerUpTextureIndex = 4
				case self.powerUpDecreasePaddleSize:
					powerUpTextureIndex = 5
				case self.powerUpStickyPaddle:
					powerUpTextureIndex = 6
				case self.powerUpGravityBall:
					powerUpTextureIndex = 7
				case self.powerUpPointsBonusSmall:
					powerUpTextureIndex = 8
				case self.powerUpPointsPenaltySmall:
					powerUpTextureIndex = 9
				case self.powerUpPointsBonus:
					powerUpTextureIndex = 10
				case self.powerUpPointsPenalty:
					powerUpTextureIndex = 11
				case self.powerUpMultiplier:
					powerUpTextureIndex = 12
				case self.powerUpMultiplierReset:
					powerUpTextureIndex = 13
				case self.powerUpNextLevel:
					powerUpTextureIndex = 14
				case self.powerUpShowInvisibleBricks:
					powerUpTextureIndex = 15
				case self.powerUpNormalToInvisibleBricks:
					powerUpTextureIndex = 16
				case self.powerUpMultiHitToNormalBricks:
					powerUpTextureIndex = 17
				case self.powerUpMultiHitBricksReset:
					powerUpTextureIndex = 18
				case self.powerUpRemoveIndestructibleBricks:
					powerUpTextureIndex = 19
				case self.powerUpGigaBall:
					powerUpTextureIndex = 20
				case self.powerUpUndestructiBall:
					powerUpTextureIndex = 21
				case self.powerUpLasers:
					powerUpTextureIndex = 22
				case self.powerUpBricksDown:
					powerUpTextureIndex = 23
				case self.powerUpMystery:
					powerUpTextureIndex = 24
				case self.powerUpBackstop:
					powerUpTextureIndex = 25
				case self.powerUpIncreaseBallSize:
					powerUpTextureIndex = 26
				case self.powerUpDecreaseBallSize:
					powerUpTextureIndex = 27
				default:
					break
				}
				
				var currentPowerUpXIndex = Double((self.gameWidth/2 - self.brickWidth/2 - sprite.position.x)/self.brickWidth)
				var currentPowerUpYIndex = Double((self.yBrickOffset - sprite.position.y)/self.brickHeight)
//				if self.endlessMode {
//					currentPowerUpYIndex = Double((self.yBrickOffsetEndless - sprite.position.y)/self.brickHeight)
//				}
				
				currentPowerUpXIndex = round(currentPowerUpXIndex)
				currentPowerUpYIndex = round(currentPowerUpYIndex)
				// Round to the nearest integer
				
				powerUpFallingXPositionArray!.append(Int(currentPowerUpXIndex))
				powerUpFallingYPositionArray!.append(Int(currentPowerUpYIndex))
				powerUpFallingArray!.append(powerUpTextureIndex)
			}
		}
		// Save bricks, ball and power-ups if playing or paused

		saveGameSaveArray! = gameSaveArray
		saveMultiplier! = currentMultiplier
		
		if brickXPositionArray != [] {
			saveBrickTextureArray! = brickTextureArray!
			saveBrickColourArray! = brickColourArray!
			saveBrickXPositionArray! = brickXPositionArray!
			saveBrickYPositionArray! = brickYPositionArray!
		}
		
		if ballPropertiesArray != [] {
			saveBallPropertiesArray! = ballPropertiesArray!
		}
		
		if powerUpFallingXPositionArray != [] {
			savePowerUpFallingXPositionArray! = powerUpFallingXPositionArray!
			savePowerUpFallingYPositionArray! = powerUpFallingYPositionArray!
			savePowerUpFallingArray! = powerUpFallingArray!
		}
		
		if powerUpActiveArray != [] {
			savePowerUpActiveArray! = powerUpActiveArray!
			savePowerUpActiveDurationArray! = powerUpActiveDurationArray!
			savePowerUpActiveTimerArray! = powerUpActiveTimerArray!
			savePowerUpActiveMagnitudeArray! = powerUpActiveMagnitudeArray!
		}
		
		defaults.set(saveGameSaveArray!, forKey: "saveGameSaveArray")
		defaults.set(saveMultiplier!, forKey: "saveMultiplier")
		defaults.set(saveBrickTextureArray!, forKey: "saveBrickTextureArray")
		defaults.set(saveBrickColourArray!, forKey: "saveBrickColourArray")
		defaults.set(saveBrickXPositionArray!, forKey: "saveBrickXPositionArray")
		defaults.set(saveBrickYPositionArray!, forKey: "saveBrickYPositionArray")
		defaults.set(saveBallPropertiesArray!, forKey: "saveBallPropertiesArray")
		defaults.set(savePowerUpFallingXPositionArray!, forKey: "savePowerUpFallingXPositionArray")
		defaults.set(savePowerUpFallingYPositionArray!, forKey: "savePowerUpFallingYPositionArray")
		defaults.set(savePowerUpFallingArray!, forKey: "savePowerUpFallingArray")
		defaults.set(savePowerUpActiveArray!, forKey: "savePowerUpActiveArray")
		defaults.set(savePowerUpActiveDurationArray!, forKey: "savePowerUpActiveDurationArray")
		defaults.set(savePowerUpActiveTimerArray!, forKey: "savePowerUpActiveTimerArray")
		defaults.set(savePowerUpActiveMagnitudeArray!, forKey: "savePowerUpActiveMagnitudeArray")
		
		resumeGameToLoad = true
		defaults.set(resumeGameToLoad!, forKey: "resumeGameToLoad")
	}
	
	func clearSavedGame() {
		userSettings()
		resumeGameToLoad = false
		defaults.set(resumeGameToLoad!, forKey: "resumeGameToLoad")
		saveGameSaveArray! = []
		saveMultiplier! = 1.0
		saveBrickTextureArray! = []
		saveBrickColourArray! = []
		saveBrickXPositionArray! = []
		saveBrickYPositionArray! = []
		saveBallPropertiesArray! = []
		savePowerUpFallingXPositionArray! = []
		savePowerUpFallingYPositionArray! = []
		savePowerUpFallingArray! = []
		savePowerUpActiveArray! = []
		savePowerUpActiveDurationArray! = []
		savePowerUpActiveTimerArray! = []
		savePowerUpActiveMagnitudeArray! = []
		
		defaults.set(saveGameSaveArray!, forKey: "saveGameSaveArray")
		defaults.set(saveMultiplier!, forKey: "saveMultiplier")
		defaults.set(saveBrickTextureArray!, forKey: "saveBrickTextureArray")
		defaults.set(saveBrickColourArray!, forKey: "saveBrickColourArray")
		defaults.set(saveBrickXPositionArray!, forKey: "saveBrickXPositionArray")
		defaults.set(saveBrickYPositionArray!, forKey: "saveBrickYPositionArray")
		defaults.set(saveBallPropertiesArray!, forKey: "saveBallPropertiesArray")
		defaults.set(savePowerUpFallingXPositionArray!, forKey: "savePowerUpFallingXPositionArray")
		defaults.set(savePowerUpFallingYPositionArray!, forKey: "savePowerUpFallingYPositionArray")
		defaults.set(savePowerUpFallingArray!, forKey: "savePowerUpFallingArray")
		defaults.set(savePowerUpActiveArray!, forKey: "savePowerUpActiveArray")
		defaults.set(savePowerUpActiveDurationArray!, forKey: "savePowerUpActiveDurationArray")
		defaults.set(savePowerUpActiveTimerArray!, forKey: "savePowerUpActiveTimerArray")
		defaults.set(savePowerUpActiveMagnitudeArray!, forKey: "savePowerUpActiveMagnitudeArray")
	}
	
	func resumeGame() {
		if resumeGameToLoad! {
			if saveBallPropertiesArray != [] {
				ballIsOnPaddle = false
				ballLostBool = false
				ball.position.x = CGFloat(saveBallPropertiesArray![0])
				ball.position.y = CGFloat(saveBallPropertiesArray![1])
				paddle.position.x = CGFloat(saveBallPropertiesArray![4])
				paddleLaser.position.x = paddle.position.x
				paddleLaser.position.y = paddle.position.y - paddleHeight/2
				paddleSticky.position.x = paddle.position.x
				paddleSticky.position.y = paddle.position.y - paddleHeight/2
				paddleRetroTexture.position.x = paddle.position.x
				paddleRetroTexture.position.y = paddle.position.y
				paddleRetroLaserTexture.position.x = paddle.position.x
				paddleRetroLaserTexture.position.y = paddle.position.y
				paddleRetroStickyTexture.position.x = paddle.position.x
				paddleRetroStickyTexture.position.y = paddle.position.y + paddleRetroStickyTexture.size.height/2 - paddle.size.height/2
				numberOfLevels = saveGameSaveArray![7]
				levelTimerValue = saveGameSaveArray![8]
				packTimerValue = saveGameSaveArray![9]
				levelTimerBonus = 500
			} else {
				saveCurrentGame()
			}
			// Load ball position and velocity if it has been saved
			
			if savePowerUpFallingArray != [] {
				for i in 0..<savePowerUpFallingArray!.count {
					
					let powerUpPositionX = savePowerUpFallingXPositionArray![i]
					let powerUpPositionY = savePowerUpFallingYPositionArray![i]

					let powerUp = SKSpriteNode(imageNamed: "PowerUpPreSet")
					powerUp.size.width = brickWidth*0.85
					powerUp.size.height = powerUp.size.width
					powerUp.position = CGPoint(x: gameWidth/2 - brickWidth/2 - brickWidth*CGFloat(powerUpPositionX), y: yBrickOffset - brickHeight*CGFloat(powerUpPositionY))
					powerUp.physicsBody = SKPhysicsBody(rectangleOf: powerUp.frame.size)
					powerUp.physicsBody!.allowsRotation = false
					powerUp.physicsBody!.friction = 0.0
					powerUp.physicsBody!.affectedByGravity = false
					powerUp.physicsBody!.isDynamic = false
					powerUp.physicsBody!.mass = 0
					powerUp.name = PowerUpCategoryName
					powerUp.physicsBody!.categoryBitMask = CollisionTypes.powerUpCategory.rawValue
					powerUp.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
					powerUp.physicsBody!.contactTestBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue
					powerUp.zPosition = 2
					addChild(powerUp)
					
					powerUp.texture = powerUpTextureArray[savePowerUpFallingArray![i]]
					let move = SKAction.moveBy(x: 0, y: -frame.height, duration: 5)
					powerUp.run(move, withKey: "PowerUpDrop")
					powerUpsOnScreen+=1
				}
			// Load power-up position and texture if it has been saved
				if endlessMode && screenSize != "X" {
					scoreBacker.isHidden = false
				}
			}
			
			if savePowerUpActiveArray != [] {
				for i in 0..<savePowerUpActiveArray!.count {
					
					let remainingTime: Double = savePowerUpActiveDurationArray![i]
					let totalTime: Double = savePowerUpActiveTimerArray![i]
					let scale: CGFloat = CGFloat(remainingTime/totalTime)
					
					switch savePowerUpActiveArray![i] {
					case "ballSpeedTimer":
						switch savePowerUpActiveMagnitudeArray![i] {
						case 0:
							ballSpeedLimit = ballSpeedSlowest
							ballSpeedIcon.texture = self.iconDecreaseBallSpeedTexture
						case 1:
							ballSpeedLimit = ballSpeedSlow
							ballSpeedIcon.texture = self.iconDecreaseBallSpeedTexture
						case 2:
							ballSpeedLimit = ballSpeedFast
							ballSpeedIcon.texture = self.iconIncreaseBallSpeedTexture
						case 3:
							ballSpeedLimit = ballSpeedFastest
							ballSpeedIcon.texture = self.iconIncreaseBallSpeedTexture
						default:
							break
						}
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.ballSpeedLimit = self.ballSpeedNominal
							self.ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
							self.ballSpeedIconBar.isHidden = true
						}
						ballSpeedIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.ballSpeedIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "ballSpeedTimer")
						})
						ballSpeedIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						ballSpeedIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpDecreaseBallSpeedTimer")
						self.run(sequence, withKey: "powerUpDecreaseBallSpeed")
						
					case "paddleSizeTimer":
						var setScale: CGFloat?
						switch savePowerUpActiveMagnitudeArray![i] {
						case 0:
							setScale = 0.5
							paddleSizeIcon.texture = self.iconDecreasePaddleSizeTexture
						case 1:
							setScale = 0.75
							paddleSizeIcon.texture = self.iconDecreasePaddleSizeTexture
						case 2:
							setScale = 1.5
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						case 3:
							setScale = 2.0
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						case 4:
							setScale = 2.5
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						default:
							break
						}
						paddleCenterRectPlus()
						paddle.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
						paddleLaser.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						paddleSticky.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						paddleRetroTexture.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						paddleRetroLaserTexture.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						paddleRetroStickyTexture.run(SKAction.scaleX(to: setScale!, duration: 0.0))
						
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.paddleCenterRectPlus()
							if self.hapticsSetting! {
								self.rigidHaptic.impactOccurred()
							}
							self.paddle.run(SKAction.scaleX(to: 1, duration: 0.2), completion: {
								self.recentreBall()
								self.paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
							})
							self.paddleLaser.run(SKAction.scaleX(to: 1, duration: 0.2))
							self.paddleSticky.run(SKAction.scaleX(to: 1, duration: 0.2))
							self.paddleRetroTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
							self.paddleRetroLaserTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
							self.paddleRetroStickyTexture.run(SKAction.scaleX(to: 1, duration: 0.2))
							self.paddleCenterRectZero()
							self.paddleSizeIcon.texture = self.iconPaddleSizeDisabledTexture
							self.paddleSizeIconBar.isHidden = true
						}
						paddleSizeIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.paddleSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "paddleSizeTimer")
						})
						paddleSizeIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						paddleSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpPaddleSizeTimer")
						self.run(sequence, withKey: "powerUpIncreasePaddleSize")
						
					case "gravityTimer":
						gravityIcon.texture = self.iconGravityTexture
						physicsWorld.gravity = CGVector(dx: 0, dy: -1.5)
						ball.physicsBody!.affectedByGravity = true
						gravityActivated = true
						gravityDeactivate = false

						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							if self.ballIsOnPaddle {
								self.deactivateGravity()
							} else {
								self.gravityDeactivate = true
							}
							self.gravityIconBar.isHidden = true
						}
						gravityIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.gravityIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "gravityTimer")
						})
						gravityIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						gravityIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpGravityTimer")
						self.run(sequence, withKey: "powerUpGravityBall")
						
					case "invisibleBricksTimer":
						hiddenBricksIcon.texture = self.iconHiddenBlocksTexture
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
								let temporarySprite = node as! SKSpriteNode
								if node.isHidden == true && temporarySprite.texture != self.brickInvisibleTexture {
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
						hiddenBricksIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.hiddenBricksIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "invisibleBricksTimer")
						})
						hiddenBricksIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						hiddenBricksIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpHiddenBricksTimer")
						self.run(sequence, withKey: "powerUpInvisibleBricks")
						
					case "gigaBallTimer":
						gigaBallDeactivate = false
						switch savePowerUpActiveMagnitudeArray![i] {
						case 0:
							gigaBallIcon.texture = self.iconGigaBallTexture
							ball.texture = gigaBallTexture
							powerUpLimit = 4
						case 1:
							gigaBallIcon.texture = self.iconUndestructiballTexture
							ball.texture = undestructiballTexture
							powerUpLimit = 2
							// Power up set
						default:
							break
						}
						ballPhysicsBodySet()
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							if self.ball.texture == self.gigaBallTexture {
								if self.ballIsOnPaddle {
									self.deactivateGigaBall()
								} else {
									self.gigaBallDeactivate = true
								}
								self.gigaBallIconBar.isHidden = true
								// Hide power-up icons
							} else {
								self.ball.texture = self.ballTexture
								self.ballPhysicsBodySet()
								self.gigaBallIcon.texture = self.iconGigaBallDisabledTexture
								self.gigaBallIconBar.isHidden = true
							}
						}
						gigaBallIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.gigaBallIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "gigaBallTimer")
						})
						gigaBallIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						gigaBallIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpGigaBallTimer")
						self.run(sequence, withKey: "powerUpGigaBall")
						
					case "laserTimer":
						lasersIcon.texture = self.iconLasersTexture
						laserPowerUpIsOn = true
						paddleLaser.isHidden = false
						if paddleTexture == retroPaddle {
							paddleRetroLaserTexture.isHidden = false
							paddleRetroTexture.isHidden = true
							paddleLaser.isHidden = true
						}
						laserTimer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(laserGenerator), userInfo: nil, repeats: true)
						powerUpLimit = 4
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.laserTimer?.invalidate()
							self.paddleLaser.isHidden = true
							self.paddleRetroLaserTexture.isHidden = true
							if self.paddleTexture == self.retroPaddle {
								self.paddleRetroTexture.isHidden = false
							}
							self.laserPowerUpIsOn = false
							self.powerUpLimit = 2
							self.lasersIcon.texture = self.iconLasersDisabledTexture
							self.lasersIconBar.isHidden = true
							self.paddle.isHidden = false
						}
						lasersIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.lasersIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "laserTimer")
						})
						lasersIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						lasersIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpLaserTimer")
						self.run(sequence, withKey: "powerUpLasers")
						
					case "ballSizeTimer":
						ballSizeIconBar.isHidden = false
						var setScale: CGFloat?
						switch savePowerUpActiveMagnitudeArray![i] {
						case 0:
							setScale = 0.5
							ballSizeIcon.texture = self.iconBallSizeSmallTexture
						case 1:
							setScale = 0.75
							ballSizeIcon.texture = self.iconBallSizeSmallTexture
						case 2:
							setScale = 1.5
							ballSizeIcon.texture = self.iconBallSizeBigTexture
						case 3:
							setScale = 2.0
							ballSizeIcon.texture = self.iconBallSizeBigTexture
						default:
							break
						}
						ball.xScale = setScale!
						ball.yScale = setScale!
						self.setBallStartingPositionY()
						
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							if self.hapticsSetting! {
								self.rigidHaptic.impactOccurred()
							}
							self.ball.run(SKAction.scale(to: 1, duration: 0.2), completion: {
								self.setBallStartingPositionY()
							})
							self.ballSizeIcon.texture = self.iconBallSizeDisabledTexture
							self.ballSizeIconBar.isHidden = true
							// Hide power-up icons
						}
						ballSizeIconBar.run(SKAction.scaleX(to: scale, duration: 0.00), completion: {
							self.ballSizeIconBar.run(SKAction.scaleX(to: 0.0, duration: remainingTime), withKey: "ballSizeTimer")
						})
						ballSizeIconBar.isHidden = false
						let sequence = SKAction.sequence([waitDuration, completionBlock])
						ballSizeIcon.run(SKAction.sequence([timerScaleUp, timerScaleDown]), withKey: "powerUpBallSizeTimer")
						self.run(sequence, withKey: "powerUpIncreaseBallSize")
						
					case "stickyPaddle":
						stickyPaddleCatches = savePowerUpActiveMagnitudeArray![i]
						stickyPaddleCatchesTotal = 6
						let scale: CGFloat = CGFloat(stickyPaddleCatches/stickyPaddleCatchesTotal)
						stickyPaddleIcon.texture = self.iconStickyPaddleTexture
						stickyPaddleIconBar.isHidden = false
						stickyPaddleIconBar.run(SKAction.scaleX(to: scale, duration: 0.01))
						paddleSticky.isHidden = false
						if paddleTexture == retroPaddle {
							paddleSticky.isHidden = true
						}
						
					case "backstop":
						backstop.size.height = self.paddleHeight
						backstop.size.width = self.gameWidth-2
						self.backstop.run(SKAction.scaleX(by: 0.25, y: 1, duration: 0.0))
						self.backstop.run(SKAction.scaleX(by: 4, y: 1, duration: 0.0))
						self.backstop.isHidden = false
						self.backstopCatches = 1
						self.backstopCatchesTotal = self.backstopCatches
						self.backstop.physicsBody!.categoryBitMask = CollisionTypes.backstopCategory.rawValue
						self.backstop.physicsBody!.collisionBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
						self.backstop.physicsBody!.contactTestBitMask = CollisionTypes.ballCategory.rawValue | CollisionTypes.powerUpCategory.rawValue
						self.ballPhysicsBodySet()
						
					default:
						break
					}
				}
			}
			// Load active power-ups if any saved
			resumeGameToLoad = false
			defaults.set(resumeGameToLoad!, forKey: "resumeGameToLoad")
			self.gameState.enter(Paused.self)
		}
	}
	
	func resumeFromPauseCountdown() {
		countdownStarted = true
		isPaused = false
		pauseAllNodes()
		pauseButton.texture = pauseHighlightedTexture
		pauseButton.size.width = pauseButtonSize*0.9
		pauseButton.size.height = pauseButtonSize*0.9
		// Unpause scene to allow for animation ensuring all other nodes remain paused for now
		
		let startScale = SKAction.scale(to: 2, duration: 0)
		let startFade = SKAction.fadeOut(withDuration: 0)
		let scaleIn = SKAction.scale(to: 1, duration: 0.25)
		let scaleOut = SKAction.scale(to: 0.5, duration: 0.25)
		let fadeIn = SKAction.fadeIn(withDuration: 0.25)
		let fadeOut = SKAction.fadeOut(withDuration: 0.25)
		let wait = SKAction.wait(forDuration: 0.75)
		readyCountdown.removeAllActions()
		goCountdown.removeAllActions()
		// Setup animation properties

		let startGroup = SKAction.group([startScale, startFade])
		// Prep label ahead of animation
		let animationIn1 = SKAction.group([scaleIn, fadeIn, wait])
		// Animate in with pause
		let animationIn2 = SKAction.group([scaleIn, fadeIn])
		// Animate in
		let animationOut = SKAction.group([scaleOut, fadeOut])
		// Animate out
		
		readyCountdown.run(startGroup, completion: {
			self.readyCountdown.isHidden = false
			self.readyCountdown.run(animationIn1, completion: {
				self.readyCountdown.run(animationOut, completion: {
					self.readyCountdown.isHidden = true
					self.goCountdown.run(startGroup, completion: {
						self.goCountdown.isHidden = false
						self.goCountdown.run(animationIn2, completion: {
							self.gameState.enter(Playing.self)
							// Restart playing
							if self.hapticsSetting! {
								self.lightHaptic.impactOccurred()
							}
							self.goCountdown.run(animationOut, completion: {
								self.goCountdown.isHidden = true
							})
						})
					})
				})
			})
		})
		// Animate countdown
	}
	
	func pauseAllNodes() {
        enumerateChildNodes(withName: PaddleCategoryName) { (node, _) in
            node.isPaused = true
        }
        enumerateChildNodes(withName: BallCategoryName) { (node, _) in
            self.ball.physicsBody!.velocity.dx = 0
            self.ball.physicsBody!.velocity.dy = 0
            node.isPaused = true
        }
        enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
            node.isPaused = true
        }
        enumerateChildNodes(withName: BrickRemovalCategoryName) { (node, _) in
            node.isPaused = true
        }
        enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
			node.removeAction(forKey: "PowerUpDrop")
        }
        enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
            node.isPaused = true
        }
        // Pause all nodes individually
        
        ball.physicsBody!.affectedByGravity = false
        // Ensure the ball won't fall under gravity if the gameScene is unpaused
        
        if ballIsOnPaddle == false && ballLostBool == false {
            
            let angleRad = atan2(Double(self.pauseBallVelocityY), Double(self.pauseBallVelocityX))
            let angleDeg = Double(angleRad)/Double.pi*180
            let rotationAngle = CGFloat(angleRad)
            directionMarker.zRotation = rotationAngle
            directionMarker.size.width = ball.size.width*3.5
            directionMarker.size.height = ball.size.height*3.5
            directionMarker.position.x = ball.position.x
            directionMarker.position.y = ball.position.y
            // Set direction marker rotation to match the ball's direction of travel and position
            
            if ball.texture == gigaBallTexture {
                directionMarker.texture = directionMarkerOuterGigaTexture
            } else if ball.texture == undestructiballTexture {
                directionMarker.texture = directionMarkerOuterUndestructiTexture
            } else {
                directionMarker.texture = directionMarkerOuterTexture
            }
            // Set direction marker outer texture if the ball is near either edge of frame
            
            if directionMarker.position.x > 0 + frame.size.width/2 - directionMarker.size.width/2 {
                if angleDeg > -90 && angleDeg < 90 {
                    if ball.texture == gigaBallTexture {
                        directionMarker.texture = directionMarkerInnerGigaTexture
                    } else if ball.texture == undestructiballTexture {
                        directionMarker.texture = directionMarkerInnerUndestructiTexture
                    } else {
                        directionMarker.texture = directionMarkerInnerTexture
                    }
                    // Set texture of direction marker based on ball texture
                }
            }
            else if directionMarker.position.x < 0 - frame.size.width/2 + directionMarker.size.width/2 {
                if angleDeg < -90 || angleDeg > 90 {
                    if ball.texture == gigaBallTexture {
                        directionMarker.texture = directionMarkerInnerGigaTexture
                    } else if ball.texture == undestructiballTexture {
                        directionMarker.texture = directionMarkerInnerUndestructiTexture
                    } else {
                        directionMarker.texture = directionMarkerInnerTexture
                    }
                    // Set texture of direction marker based on ball texture
                }
            }
            // Set direction marker inner texture if the ball is near either edge of frame
    
            directionMarker.isHidden = false
            // Show ball direction marker
        }
    }
    // Pause all nodes
	
	func playFromPause() {
		
		clearSavedGame()
		countdownStarted = false
		pauseButton.texture = pauseTexture
		pauseButton.size.width = pauseButtonSize
        pauseButton.size.height = pauseButtonSize
		directionMarker.isHidden = true
		isPaused = false
		
		enumerateChildNodes(withName: PaddleCategoryName) { (node, _) in
			node.isPaused = false
		}
		enumerateChildNodes(withName: BallCategoryName) { (node, _) in
			self.ball.physicsBody!.velocity = CGVector(dx: self.pauseBallVelocityX, dy: self.pauseBallVelocityY)
			node.isPaused = false
		}
		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			node.isPaused = false
		}
		enumerateChildNodes(withName: BrickRemovalCategoryName) { (node, _) in
			node.isPaused = false
		}
		enumerateChildNodes(withName: PowerUpCategoryName) { (node, _) in
			let move = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 7.5)
			node.run(move, withKey: "PowerUpDrop")
		}
		enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
			node.isPaused = false
		}
		// Restart game, unpause all nodes
		
		ball.physicsBody!.affectedByGravity = true
		// Enusre the ball is affected by gravity
		
		if killBall {
			
			if numberOfLives == 0 {
				numberOfLives = 1
			}
			ballLost()
		}
		killBall = false
		
		if endlessMode {
			countBricks()
		}
	}
		
	@objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
        print("llama llama icloud update pushed - game scene")
        userSettings()
        loadGameData()
    }
    // Runs when the NSUbiquitousKeyValueStore changes
}

extension Notification.Name {
    public static let pauseNotificationKey = Notification.Name(rawValue: "pauseNotificationKey")
	public static let restartGameNotificiation = Notification.Name(rawValue: "restartGameNotificiation")
}
// Setup for notifcations from AppDelegate
