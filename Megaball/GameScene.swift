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

protocol GameViewControllerDelegate: AnyObject {
	func moveToMainMenu()
	func showPauseMenu(levelNumber: Int, numberOfLevels: Int, score: Int, packNumber: Int, height: Int, sender: String, gameoverBool: Bool, newItemsBool: Bool, previousHighscore: Int, livesRemaining: Int)
	func showWarning(senderID: String)
	func showInbetweenView(levelNumber: Int, score: Int, packNumber: Int, levelTimerBonus: Int, firstLevel: Bool, numberOfLevels: Int, levelScore: Int)
	var selectedLevel: Int? { get set }
	var numberOfLevels: Int? { get set }
	var levelSender: String? { get set }
	var levelPack: Int? { get set }
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
	/// Where each ball was before the physics step, for the seam correction below.
	var ballStateBeforeStep: [ObjectIdentifier: BallState] = [:]
	/// The bricks each ball touched during the step, as the frames they had at the time.
	var brickSeamStrikes: [ObjectIdentifier: [CGRect]] = [:]

	/// The balls beyond the first, in Endless 2.0 only.
	///
	/// `ball` stays the ball the rest of the game holds; these sit beside it. See
	/// EndlessIIMultiBall for why it is done that way round.
	var endlessIIExtraBalls: [SKSpriteNode] = []
	/// Every ball the sticky paddle is holding, oldest first - see EndlessIIStickyPaddle.
	var endlessIIHeldBalls: [SKSpriteNode] = []
	/// Where each held ball sits across the paddle, so it rides the paddle rather than
	/// waiting where it landed.
	var endlessIIHeldOffsets: [CGFloat] = []
	/// One direction marker per extra ball, while the resume countdown runs.
	var endlessIIExtraDirectionMarkers: [SKSpriteNode] = []
	/// The extra ball that is about to hand its place to the first ball, once the step that
	/// lost the first ball has finished resolving.
	var endlessIIPendingHandover: SKSpriteNode?

	// The vision power-ups' clocks and drawing - see EndlessIIVision
	var endlessIITrajectoryRemaining: TimeInterval = 0
	var endlessIITrajectoryTotal: TimeInterval = 0
	var endlessIITrajectoryLevel = 0
	var endlessIILandingRemaining: TimeInterval = 0
	var endlessIILandingTotal: TimeInterval = 0
	var endlessIIVisionLastTick: TimeInterval = 0
	var endlessIITrajectoryLines: [SKShapeNode] = []
	var endlessIILandingMarkers: [SKShapeNode] = []

	// The paddle batch's clocks and state - see EndlessIIPaddlePowerUps
	var endlessIIAimedStickyClock = EndlessIIClock()
	var endlessIIMagnetismClock = EndlessIIClock()
	var endlessIIPortalPaddleClock = EndlessIIClock()
	var endlessIIPaddleHaloClock = EndlessIIClock()
	var endlessIIBallSteeringClock = EndlessIIClock()
	var endlessIIInertPaddleClock = EndlessIIClock()
	var endlessIIFlippedAngleClock = EndlessIIClock()
	var endlessIIReversedControlsClock = EndlessIIClock()
	var endlessIIPaddleLastTick: TimeInterval = 0
	var endlessIIPaddleFrameDelta: TimeInterval = 0
	var endlessIIPendingPaddlePortals: [SKSpriteNode] = []
	var endlessIIPaddleHaloNode: SKShapeNode?
	var endlessIIPaddleHaloDrawnReach: CGFloat = 0
	var endlessIISteeringLastPaddleX: CGFloat = 0
	var endlessIISteeringPending: CGFloat = 0
	var endlessIITopExitStrip: SKSpriteNode?
	var endlessIIPullLines: [SKShapeNode] = []
	var endlessIILowerLimitLine: SKSpriteNode?
	var endlessIIAutoAimClock = EndlessIIClock()
	var endlessIIWrapAroundClock = EndlessIIClock()
	var endlessIIPendingWraps: [SKSpriteNode] = []
	var endlessIIWrapDressed = false
	var endlessIIBackdropTiles: [SKSpriteNode] = []
	var endlessIIBackdropScroll: CGFloat = 0
	var endlessIIAimDefaultAngles: [ObjectIdentifier: Double] = [:]
	var endlessIIAimDrag: CGFloat = 0
	var endlessIIAimArrow: SKShapeNode?
	/// Whether the world is frozen while an aim is chosen - see EndlessIIAimedSticky.
	var endlessIIAimHold = false

	// The field batch's clocks and drawing - see EndlessIIFieldPowerUps
	var endlessIIWreckingBallClock = EndlessIIClock()
	var endlessIIAuraClock = EndlessIIClock()
	var endlessIIAuraNodes: [SKShapeNode] = []
	var endlessIIDescentClock = EndlessIIClock()
	var endlessIIDescentAccumulated: TimeInterval = 0
    var brick = SKSpriteNode()
    var life = SKSpriteNode()
	var lifeIcons: [SKSpriteNode] = []
	var livesAwaitingRollIn = false
	// Set while a level intro is on screen. The intro fades out over its last quarter
	// second, so without this the settled balls are visible through the fade and then
	// jump back to the start of the roll-in
	var livesContainer = SKShapeNode()
	static let maxLivesShown = 10
	// The lives row sits below the paddle rather than in the HUD. The HUD's centre is
	// where a notch or Dynamic Island lives, and an expanded Live Activity would draw
	// straight over a counter placed beside it. Below the paddle it is always visible,
	// and it reads better - the balls you have left, next to the one in play.
	//
	// Capped because the row has to fit the play width. Past ten, the exact count is not
	// something a player is tracking.
	var topScreenBlock = SKSpriteNode()
	var bottomScreenBlock = SKSpriteNode()
	var sideScreenBlockLeft = SKSpriteNode()
	var sideScreenBlockRight = SKSpriteNode()
	var background = SKSpriteNode()
	/// Carries the Solid, Gradient and Black backgrounds. Created on demand rather than
	/// living in the scene file, so it is ours to set.
	var backgroundOverlay: SKSpriteNode?
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
	var endlessGameIcon = SKSpriteNode()
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
	/// Endless 2.0's power-up display. The tray above is left untouched for the modes that
	/// already use it.
	let powerUpRings = PowerUpRingHUD()
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
	var ballLinearDampening: CGFloat = 0.01
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
	/// Every extra ball's velocity, held across a pause the way the first ball's is.
	///
	/// Pausing takes the velocities off the field, so each ball needs somewhere to keep its
	/// own. Without this the extras came back stationary and dropped straight down, which is
	/// three balls lost to opening the pause menu.
	var pauseExtraBallVelocities: [CGVector] = []
    // Setup game metrics
	
	var powerUpProbFactor: Int = 0
	var powerUpProbArray: [Int] = Array(repeating: 0, count: 48)
	// One weight per power-up, in power-up order - sized by count so a new power-up cannot
	// leave it one short, which is exactly the mistake a literal this long invites
	var powerUpProbSum: Int = 0
	var powerUpGeneratorCycles: Int = 0
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
	// Run every time levelTimerValue is updated (every second)
	var firstLevel: Bool = false
    // Setup score properties
	
	var soundsSetting: Bool = true
	var musicSetting: Bool = true
	var hapticsSetting: Bool = true
	var parallaxSetting: Bool = true
	var paddleSensitivitySetting: Int = 2
	var gameCenterSetting: Bool = false
	var ballSetting: Int = 0
	var paddleSetting: Int = 0
	var brickSetting: Int = 0
    var appIconSetting: Int = 0
	var swipeUpPause: Bool = true
	var gameInProgress: Bool = false
	var resumeGameToLoad: Bool = false
	var firstPause: Bool = true
	// User settings
	var savedGame: SavedGame?
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
    /// How many times the laser power-up has been collected while it was already running.
    ///
    /// Each one halves the gap between shots, so collecting it again is worth something
    /// rather than just resetting the clock. Capped so the rate stays a rate.
    var laserStacks: Int = 0
    static let laserBaseInterval: TimeInterval = 0.25
    static let laserMaxStacks = 2
    /// The fastest the lasers may ever fire, however much is stacked on them.
    ///
    /// Two stacks and a slow ball put this at about a shot every twenty milliseconds, which
    /// with Giga-Ball on top stopped being powerful and started being a screen-clearing
    /// button. The floor leaves the first stack worth as much as it ever was and takes most
    /// of the second one back.
    static let laserFastestInterval: TimeInterval = 0.11
    var laserInterval: TimeInterval {
        let stacked = GameScene.laserBaseInterval / pow(2, Double(min(laserStacks, GameScene.laserMaxStacks)))
        return max(GameScene.laserFastestInterval, stacked * ballSpeedPowerUpFactor)
    }

    /// How the ball-speed power-ups lean on everything else that is timed.
    ///
    /// Slow ball is the good one and fast ball is the bad one, which is the opposite of
    /// what the names suggest - so slow ball makes lasers fire faster, and fast ball makes
    /// them fire slower. Below 1 means "sooner".
    var ballSpeedPowerUpFactor: Double {
        if ballSpeedLimit == ballSpeedSlow { return 0.85 }
        if ballSpeedLimit == ballSpeedSlowest { return 0.75 }
        if ballSpeedLimit == ballSpeedFast { return 1.15 }
        if ballSpeedLimit == ballSpeedFastest { return 1.25 }
        return 1.0
    }
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
	/// Whether a lost ball's life has been counted yet.
	///
	/// The count drops 0.75s after the ball is lost, so a save taken inside that window
	/// would record a life that is about to go. saveCurrentGame used to compensate by
	/// checking ballLostBool - but that flag also means "the ball is sitting on the
	/// paddle", which is true from the moment a level starts and stays true until the
	/// player launches. So every save taken before launching wrote one life fewer, and
	/// quitting and resuming repeatedly walked the count down.
	var lifeLossPending: Bool = false
	var ballIsReturning: Bool = false
	/// How long the ball stays away after being lost, before it reappears on the paddle.
	///
	/// Long enough to register as a beat rather than a flicker - losing a ball should land.
	/// A tap cuts it short for anyone who would rather get on with it.
	static let ballReturnPause: TimeInterval = 0.65
	var powerUpsOnScreen: Int = 0
	var powerUpLimit: Int = 0
	
	var brickBounceCounter: Int = 0 {
		didSet {
			if brickBounceCounter > 100 {
				ballStuck()
			}
		}
	}
	// Property observer to release stuck ball

	/// Each extra ball's own bounce count, so a stuck fourth ball is noticed even while the
	/// first is bouncing normally - one shared counter was reset by whichever ball did
	/// anything, which with four in play is nearly always
	var endlessIIExtraBounceCounters: [ObjectIdentifier: Int] = [:]

	/// Counts a fruitless bounce against the ball that actually made it.
	func noteBrickBounce(for subject: SKSpriteNode?) {
		guard let subject, subject !== ball, gameMode == .endlessII else {
			brickBounceCounter += 1
			return
		}
		let id = ObjectIdentifier(subject)
		endlessIIExtraBounceCounters[id, default: 0] += 1
		if endlessIIExtraBounceCounters[id]! > 100 {
			endlessIIExtraBounceCounters[id] = 0
			ballStuck()
		}
	}

	/// A ball did something useful, so its own count starts over.
	func resetBrickBounce(for subject: SKSpriteNode?) {
		guard let subject, subject !== ball, gameMode == .endlessII else {
			brickBounceCounter = 0
			return
		}
		endlessIIExtraBounceCounters[ObjectIdentifier(subject)] = 0
	}
	
	var killBall: Bool = false
	var endlessMode: Bool = false
	/// Which mode this run belongs to.
	///
	/// Read from the stored setting rather than inferred from the level number, which is
	/// how the two existing modes were told apart and cannot distinguish a third that
	/// plays the same and scores separately.
	var gameMode: GameMode = .classic
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
	var ballSpeedZeroTracker: Int = 0
	var ballHitBackstop: Bool = false
	var verticalBallControlFlipper: Bool = false
	var horizontalBallControlFlipper: Bool = false
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
	var endlessIISpinners: [EndlessIISpinner] = []
	var endlessIIFlashers: [EndlessIIFlasher] = []
	var endlessIILastTick: TimeInterval = 0
	// Endless 2.0's spinning and flashing bricks, driven from update rather than by actions
	var endlessIIWanderers: [EndlessIIWander] = []
	var endlessIIFallers: [ObjectIdentifier: EndlessIIFall] = [:]
	var endlessIIPortalCooldown: TimeInterval = 0
	var endlessIIPendingPortalExit: CGPoint?
	var endlessIIPortalKeepsHeading = false
	/// Which ball is waiting to be moved to a portal's exit. Not always the first one.
	weak var endlessIIPortalTraveller: SKSpriteNode?
	/// What it should be travelling at when it gets there - the heading it arrived with,
	/// turned round only if carrying on would have taken it out of the field.
	var endlessIIPortalExitVelocity: CGVector?
	var endlessIIProgression = EndlessIIProgression.make()
	var endlessIIPhase: EndlessIIPhase = .standard
	var endlessIIPhaseEndsAt = 0
	var endlessIIBuildingIn = false
	/// The opening field, held above where it belongs until the build-in runs.
	var endlessIIBuildInBricks: [SKSpriteNode] = []
	/// Whether the opening field is still waiting for a clear screen to arrive on.
	var endlessIIBuildInWaiting = false
	/// Where each waiting brick is going, while it sits on the top row waiting its turn.
	var endlessIIBuildInFinalY: [ObjectIdentifier: CGFloat] = [:]
	/// Whether the level intro is covering the scene.
	///
	/// The other thing in front of the opening field, and the one that was actually hiding it:
	/// the app's splash screen is only up on a cold launch, where the level intro is there
	/// every time a run starts.
	var endlessIILevelIntroShowing = false
	/// When the field may start building in, once the splash has reported itself gone.
	var endlessIIBuildInReadyAt: TimeInterval?
	/// Set by the level intro's final fade beginning: start on the next frame.
	var endlessIIBuildInStartNow = false
	var endlessIIStuckTimer: TimeInterval = 0
	var endlessIISetRowQueue: [String] = []
	// The rows of a designed pattern still to come, one per generated row
	var endlessIIPhaseBehaviour: EndlessIIBehaviour?
	var endlessIIPhaseStyles: [EndlessIIStyle] = []
	// What a uniform phase settled on when it started, so every brick in it matches
	// Shuffled once per run, so two runs to the same height meet a different subset
	// Endless 2.0's phase 5 bricks, driven from update for the same reason as phase 3's
	var endlessIIPendingBigColumn: Int?
	var endlessIIPendingSpinColumn: Int?
	var endlessIIPendingClearColumn: Int?
	/// The column a two-cell-tall power-up brick is due to be built in.
	var endlessIIPendingPowerUpColumn: Int?
	/// How many rows have arrived empty in a row.
	var endlessIIEmptyRowRun = 0
	// A spinning brick needs the cells above, below and either side of it empty, and rows
	// arrive one at a time, so it takes three of them: leave the cell below, place the
	// spinner with its sides clear, leave the cell above
	// A Big brick reserved by one row and built by the next, which is the only way a brick
	// two rows tall can be made when rows arrive one at a time from the top
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
	
//MARK: - Animation Setup
	
	let timerScaleUp = SKAction.scale(to: 1.25, duration: 0.05)
	let timerScaleDown = SKAction.scale(to: 1, duration: 0.05)
	let pointsScaleDown = SKAction.scale(to: 0.75, duration: 0.05)
	// Setup timer icon animation
	
//MARK: - Sound and Haptic Definition
	
	/// Multi-Ball's icon, drawn rather than loaded - see PowerUpIcon.
	let powerUpMultiBall = SKTexture(image: PowerUpIcon.multiBall)
	let powerUpTrajectoryLine = SKTexture(image: PowerUpIcon.trajectoryLine)
	let powerUpLandingMarker = SKTexture(image: PowerUpIcon.landingMarker)
	let powerUpAimedSticky = SKTexture(image: PowerUpIcon.aimedSticky)
	let powerUpMagnetism = SKTexture(image: PowerUpIcon.magnetism)
	let powerUpPortalPaddle = SKTexture(image: PowerUpIcon.portalPaddle)
	let powerUpPaddleHalo = SKTexture(image: PowerUpIcon.paddleHalo)
	let powerUpBallSteering = SKTexture(image: PowerUpIcon.ballSteering)
	let powerUpInertPaddle = SKTexture(image: PowerUpIcon.inertPaddle)
	let powerUpFlippedAngle = SKTexture(image: PowerUpIcon.flippedAngle)
	let powerUpReversedControls = SKTexture(image: PowerUpIcon.reversedControls)
	let powerUpCull = SKTexture(image: PowerUpIcon.cull)
	let powerUpClearAndRetreat = SKTexture(image: PowerUpIcon.clearAndRetreat)
	let powerUpLaserBeam = SKTexture(image: PowerUpIcon.laserBeam)
	let powerUpWreckingBall = SKTexture(image: PowerUpIcon.wreckingBall)
	let powerUpAura = SKTexture(image: PowerUpIcon.aura)
	let powerUpInfill = SKTexture(image: PowerUpIcon.infill)
	let powerUpDescent = SKTexture(image: PowerUpIcon.descent)
	let powerUpAutoAim = SKTexture(image: PowerUpIcon.autoAim)
	let powerUpWrapAround = SKTexture(image: PowerUpIcon.wrapAround)
	/// How often Multi-Ball is offered, relative to the rest of the table.
	///
	/// Uncommon (§5.4). It is not rules-changing, but it is the one power-up that changes how
	/// many things the player is watching at once.
	static let multiBallWeight = 5

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
    
    var lightHaptic = UIImpactFeedbackGenerator(style: .light) // use for ball hitting bricks and paddle
    var interfaceHaptic = UIImpactFeedbackGenerator(style: .light) // use for UI interactions
	var mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    var heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
	var softHaptic = UIImpactFeedbackGenerator(style: .heavy) // use for lost ball
	var rigidHaptic = UIImpactFeedbackGenerator(style: .heavy) // use for power-ups collected
	// Haptics defined
	
//MARK: - State Machine Defintion

    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        PreGame(scene: self),
        Playing(scene: self),
        InbetweenLevels(scene: self),
        GameOver(scene: self),
        Paused(scene: self),
	])
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

		gameMode = GameMode.current(in: defaults)
		// Set by whichever menu launched the run, and remembered so a resumed one knows
		// what it is
		
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
		
		ballTexture = ballTextureArray[ballSetting]
		gigaBallTexture = ballGigaTextureArray[ballSetting]
		undestructiballTexture = ballUndestructiTextureArray[ballSetting]
		// ball texture set
		
		let paddleTextureArray = [paddleTexture, threeDPaddle, icePaddle, outlinePaddle, squarePaddle, glassPaddle, pixelPaddle, splitPaddle, candyPaddle, gigaPaddle, rainbowPaddle, retroPaddle]
		let laserPaddleTextureArray = [laserPaddleTexture, threeDLaserTexture, iceLaserTexture, outlineLaserTexture, squareLaserTexture, glassLaserTexture, pixelLaserTexture, splitLaserTexture, candyLaserTexture, gigaLaserTexture, rainbowLaserTexture, retroLaserTexture]
		let stickyPaddleTextureArray = [stickyPaddleTexture, threeDStickyPaddleTexture, glassStickyPaddleTexture, outlineStickyPaddleTexture, squareStickyPaddleTexture, glassStickyPaddleTexture, pixelStickyPaddleTexture, splitStickyPaddleTexture, candyStickyPaddleTexture, gigaStickyPaddleTexture, rainbowStickyPaddleTexture, retroStickyPaddleTexture]
		// paddle texture arrays
		
		paddleTexture = paddleTextureArray[paddleSetting]
		laserPaddleTexture = laserPaddleTextureArray[paddleSetting]
		stickyPaddleTexture = stickyPaddleTextureArray[paddleSetting]
		// paddle texture set
				
		let laserTextureArray = [laserNormalTexture, laser3D, laserIce, laserOutline, laserSquare, laserGlass, laserPixel, laserSplit, laserRed, laserGigaNormal, laserRed, laserRetroPink]
		let laserGigaTextureArray = [laserGigaTexture, laser3DGiga, laserGlassGiga, laserOutlineGiga, laserSquareGiga, laserGlassGiga, laserPixelGiga, laserSplitGiga, laserGigaTexture, laserGigaTexture, laserGigaTexture, laserGigaTexture]
		
		rainbowLaserArray = [laserRed, laserOrange, laserYellow, laserGreen, laserBlue, laserIndigo, laserViolet]
		stripyLaserArray = [laserRed, laserNormalTexture]
		retroLaserArray = [laserRetroPink, laserRetroBlue]
		
		laserNormalTexture = laserTextureArray[paddleSetting]
		laserGigaTexture = laserGigaTextureArray[paddleSetting]
		// laser texture set
		
		if brickSetting == 1 {
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
		endlessGameIcon = self.childNode(withName: "endlessGameIcon") as! SKSpriteNode
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
		
		powerUpTextureArray = [powerUpGetALife, powerUpLoseALife, powerUpDecreaseBallSpeed, powerUpIncreaseBallSpeed, powerUpIncreasePaddleSize, powerUpDecreasePaddleSize, powerUpStickyPaddle, powerUpGravityBall, powerUpPointsBonusSmall, powerUpPointsPenaltySmall, powerUpPointsBonus, powerUpPointsPenalty, powerUpMultiplier, powerUpMultiplierReset, powerUpNextLevel, powerUpShowInvisibleBricks, powerUpNormalToInvisibleBricks, powerUpMultiHitToNormalBricks, powerUpMultiHitBricksReset, powerUpRemoveIndestructibleBricks, powerUpGigaBall, powerUpUndestructiBall, powerUpLasers, powerUpBricksDown, powerUpMystery, powerUpBackstop, powerUpIncreaseBallSize, powerUpDecreaseBallSize, powerUpMultiBall, powerUpTrajectoryLine, powerUpLandingMarker, powerUpAimedSticky, powerUpMagnetism, powerUpPortalPaddle, powerUpPaddleHalo, powerUpBallSteering, powerUpInertPaddle, powerUpFlippedAngle, powerUpReversedControls, powerUpCull, powerUpClearAndRetreat, powerUpLaserBeam, powerUpWreckingBall, powerUpAura, powerUpInfill, powerUpDescent, powerUpAutoAim, powerUpWrapAround]
		// Power up texture array
		
		powerUpTray = self.childNode(withName: "powerUpTray") as! SKSpriteNode
		scoreBacker = self.childNode(withName: "scoreBacker") as! SKSpriteNode
		// Power-up area
		
		computeLayoutMetrics()
		// All size-dependent maths lives in one place so it can be re-run when the safe
		// area or bounds change. Node positioning still happens inline below.

		sideScreenBlockLeft.isHidden = false
		sideScreenBlockRight.isHidden = false
		let wallThickness = max(screenBlockSideWidth, GameScene.minimumWallThickness)
		sideScreenBlockLeft.size.width = wallThickness
		sideScreenBlockRight.size.width = wallThickness
		sideScreenBlockLeft.position.x = -gameWidth/2 - wallThickness/2
		sideScreenBlockRight.position.x = gameWidth/2 + wallThickness/2
		// Only the inner edge matters. It sits on the play area's edge either way, so a wall
		// wider than the border it fills simply extends off the screen - which is what lets
		// the play area run right to the edge and still have something to bounce off. A wall
		// of zero width gets no physics body at all, and the line that configures it
		// force-unwraps one

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
		
		ballLinearDampening = 0.01

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
		
		buildLivesRow()
		// After the paddle is positioned, since the row is placed relative to it

		bottomScreenBlock.size.height = frame.size.height/8
		bottomScreenBlock.size.width = frame.size.width
		bottomScreenBlock.position.x = 0
		bottomScreenBlock.position.y = paddlePositionY - paddleHeight/2 - brickWidth*0.85
	
		background.size.height = frame.size.height - screenBlockTopHeight
		background.size.width = gameWidth
		background.position.x = 0
		background.position.y = -frame.size.height/2
		background.zPosition = 0
		applyBackgroundSetting()
		
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
		endlessIIHideExtraDirectionMarkers()
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
		// Authored visible in GameScene.sks, so it has to be hidden explicitly. It was a
		// 20%-black scrim over the top of the playfield, shown on everything except
		// notched iPhones to separate the HUD from the field. The safe-area rewrite gives
		// every device the same top chrome, and the darkening is no longer wanted anywhere

		let safeTopEdge = frame.size.height/2 - GameScene.hudTopClearance
		// Measured from the physical top edge, not the safe area inset - see
		// hudTopClearance. The HUD row must stay clear of the centre for this to be safe
		pauseButton.position.y = safeTopEdge - pauseButton.size.height/2
		powerUpTray.position.y = pauseButton.position.y - pauseButton.size.height/2 - labelSpacing/2 - powerUpTray.size.height/2
		// HUD sits directly below the safe area, tray below it, playfield below both.
		// One arrangement for every device. Both are measured from safeAreaInsets rather
		// than the screen edge, so nothing can overhang into the playfield
		
		scoreLabel.position.x = frame.size.width/2 - labelSpacing*2
		scoreLabel.position.y = pauseButton.position.y + fontSize/4 + labelSpacing/2
		scoreLabel.fontSize = fontSize
		scoreLabel.zPosition = 10
		
		if isRegularWidth {
			pauseButton.position.x = sideScreenBlockLeft.position.x + sideScreenBlockLeft.size.width/2 + pauseButton.size.width/2 + layoutUnit/2
			scoreLabel.position.x = sideScreenBlockRight.position.x - sideScreenBlockRight.size.width/2 - layoutUnit/2
		}
		// Anchor the HUD to the playfield edge rather than the screen edge where the side
		// borders are wide, so it does not drift out into the border

		multiplierLabel.position.x = scoreLabel.position.x
		multiplierLabel.position.y = scoreLabel.position.y - labelSpacing - fontSize/2
		multiplierLabel.fontSize = fontSize
		multiplierLabel.zPosition = 10
		setMultiplierColour(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
		life.isHidden = true
		livesLabel.isHidden = true
		// Both retired in favour of the lives row below the paddle. They are authored in
		// GameScene.sks so they have to be hidden explicitly, and it has to happen here -
		// the earlier sizing block runs before livesLabel is bound, so hiding it there
		// only hides the placeholder
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
		
		endlessGameIcon.isHidden = true
		// Authored visible in GameScene.sks, so it needs hiding explicitly. It sat in the
		// centre of the HUD row, directly under the notch, and carried no information the
		// player did not already have from choosing the mode
		
		iconArray = [ballSpeedIcon, paddleSizeIcon, hiddenBricksIcon, stickyPaddleIcon, gravityIcon, gigaBallIcon, lasersIcon, ballSizeIcon]
		disabledIconTextureArray = [iconBallSpeedDisabledTexture, iconPaddleSizeDisabledTexture, iconHiddenBlocksDisabledTexture, iconStickyPaddleDisabledTexture, iconGravityDisabledTexture, iconGigaBallDisabledTexture, iconLasersDisabledTexture, iconBallSizeDisabledTexture]
		iconTimerArray = [ballSpeedIconBar, paddleSizeIconBar, hiddenBricksIconBar, stickyPaddleIconBar, gravityIconBar, gigaBallIconBar, lasersIconBar, ballSizeIconBar]
		iconEmptyTimerArray = [ballSpeedIconEmptyBar, paddleSizeIconEmptyBar, hiddenBricksIconEmptyBar, stickyPaddleIconEmptyBar, gravityIconEmptyBar, gigaBallIconEmptyBar, lasersIconEmptyBar, ballSizeIconEmptyBar]
		iconUnlockedBool = [false, false, false, false, false, false, false, false]
		
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

		powerUpRings.iconSize = iconSize
		powerUpRings.spacing = iconSize*0.4
		let ringGapTop = pauseButton.position.y - pauseButton.size.height/2
		let ringGapBottom = frame.size.height/2 - screenBlockTopHeight
		powerUpRings.position = CGPoint(x: 0, y: (ringGapTop + ringGapBottom)/2)
		// Centred in the space between the pause button and the top of the play area, rather
		// than hung off the button and left to reach wherever it reaches. Whatever slack
		// there is now sits evenly above and below it instead of all above
		powerUpRings.zPosition = 3
		powerUpRings.isHidden = gameMode != .endlessII
		if powerUpRings.parent == nil { addChild(powerUpRings) }

		if gameMode == .endlessII {
			powerUpTray.isHidden = true
			// Made invisible rather than hidden. isHidden on the timer bars is what the
			// activation code sets to mean "this power-up is running", and it is what the
			// rings read - hiding them here would have switched off the very signal the
			// new display depends on.
			iconArray.forEach { $0.alpha = 0 }
			iconEmptyTimerArray.forEach { $0.alpha = 0 }
			iconTimerArray.forEach { $0.alpha = 0 }
		}
		// Endless 2.0 shows only what is running, as rings. Forty-six power-ups will not
		// fit a fixed row of eight, and most of that row would be empty anyway

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
		
		brickDestroyScore = Scoring.brickDestroyed
		levelCompleteScore = Scoring.levelCompleted
		// Score properties
		
//MARK: - Score Database Setup
		
		loadGameData()
		
        NotificationCenter.default.addObserver(self, selector: #selector(self.pauseNotificationKeyReceived), name: Notification.Name.pauseNotificationKey, object: nil)
        // Sets up an observer to watch for notifications from AppDelegate to check if the app has quit
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.restartGameNotificiationKeyReceived), name: .restartGameNotificiation, object: nil)
        // Sets up an observer to watch for notifications to check if the user has restarted the game
		
		NotificationCenter.default.addObserver(self, selector: #selector(self.refreshViewForSyncNotificationKeyReceived), name: .refreshViewForSync, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.levelIntroDidClearReceived), name: .levelIntroDidClear, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(self.levelIntroDidAppearReceived), name: .levelIntroDidAppear, object: nil)
		// So the opening field knows it is being covered, rather than only knowing when it
		// stops being

		NotificationCenter.default.addObserver(self, selector: #selector(self.levelIntroWillClearReceived), name: .levelIntroWillClear, object: nil)
		// And when the cover is *about* to go, so the field can start falling behind the
		// last quarter second of the fade rather than after it
		NotificationCenter.default.addObserver(self, selector: #selector(self.backgroundSettingChangedNotificationReceived), name: .backgroundSettingChanged, object: nil)
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
				totalStatsArray = try decoder.decode([TotalStats].self, from: totalData).map { $0.makeStoredArraysConsistent(); return $0 }
			} catch {
				Log.data.error("Error decoding total stats array, \(String(describing: error), privacy: .public)")
			}
		}
		
		packLevelHighScoresArray = [
			totalStatsArray[0].pack1LevelHighScores, totalStatsArray[0].pack2LevelHighScores, totalStatsArray[0].pack3LevelHighScores, totalStatsArray[0].pack4LevelHighScores, totalStatsArray[0].pack5LevelHighScores, totalStatsArray[0].pack6LevelHighScores, totalStatsArray[0].pack7LevelHighScores, totalStatsArray[0].pack8LevelHighScores, totalStatsArray[0].pack9LevelHighScores, totalStatsArray[0].pack10LevelHighScores, totalStatsArray[0].pack11LevelHighScores
		]
	}
	// Load the total stats array from the NSCoder data store
	
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
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessOneMins achievement", privacy: .public)")
				}
			}
		}
		if levelTimerValue >= 300 && totalStatsArray[0].achievementsUnlockedArray[18] == false {
			totalStatsArray[0].achievementsUnlockedArray[18] = true
			totalStatsArray[0].achievementDates[18] = Date()
			let achievement = GKAchievement(identifier: "endlessFiveMins")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessFiveMins achievement", privacy: .public)")
				}
			}
		}
		if levelTimerValue >= 600 && totalStatsArray[0].achievementsUnlockedArray[19] == false {
			totalStatsArray[0].achievementsUnlockedArray[19] = true
			totalStatsArray[0].achievementDates[19] = Date()
			let achievement = GKAchievement(identifier: "endlessTenMins")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessTenMins achievement", privacy: .public)")
				}
			}
		}
		if levelTimerValue >= 1800 && totalStatsArray[0].achievementsUnlockedArray[20] == false {
			totalStatsArray[0].achievementsUnlockedArray[20] = true
			totalStatsArray[0].achievementDates[20] = Date()
			let achievement = GKAchievement(identifier: "endlessThirtyMins")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessThirtyMins achievement", privacy: .public)")
				}
			}
		}
		if levelTimerValue >= 3600 && totalStatsArray[0].achievementsUnlockedArray[21] == false {
			totalStatsArray[0].achievementsUnlockedArray[21] = true
			totalStatsArray[0].achievementDates[21] = Date()
			let achievement = GKAchievement(identifier: "endlessSixtyMins")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessSixtyMins achievement", privacy: .public)")
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

			if endlessIIAimHold {
				endlessIIAimDragged(by: paddleMovedDistance)
				return
			}
			// While the aim hold is on, the drag is the aim and nothing else moves - the
			// world is frozen, and lifting the finger is what fires and unfreezes

			paddleMovedDistance *= endlessIIControlDirection
			// Reversed Controls, and otherwise one - the whole power-up is this line
			
			var touchDistance = paddleMovedDistance
			if touchDistance < 0 {
				touchDistance = touchDistance*(-1)
			}
			if touchDistance > 100 && ballIsOnPaddle == false && totalStatsArray[0].achievementsUnlockedArray[50] == false {
				totalStatsArray[0].achievementsUnlockedArray[50] = true
				totalStatsArray[0].achievementDates[50] = Date()
				let achievement = GKAchievement(identifier: "paddleSpeed")
				if achievement.isCompleted == false {
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting paddleSpeed achievement", privacy: .public)")
					}
				}
			}
			// High speed paddle achievement
			
			paddleX0 = paddle.position.x
			paddleX1 = paddleX0 + (paddleMovedDistance*paddleMovementFactor)
			
			paddleX1 = endlessIIWrapPaddleX(paddleX1)
			// Clamped at the walls, unless Wrap-Around has made the walls not walls - then a
			// centre pushed past an edge comes back in from the other one
			
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
        if finishEndlessIIBuildIn() {
            touchBeganWhilstPlaying = false
            return
        }
        // A tap during the opening cascade puts the field up now. Spent on that rather than
        // on launching the ball, so nobody launches into a field that is still arriving

        if ballIsReturning && gameState.currentState is Playing {
            finishBallReturn()
            touchBeganWhilstPlaying = false
            return
        }
        // A tap while the ball is coming back is spent bringing it back now, not launching
        // it. The pause after losing a ball is there to be felt, but a player who does not
        // want it should not have to spend the skip and the launch on the same tap

        if touchBeganWhilstPlaying && gameState.currentState is Playing && endlessIIAimLaunch() {
            touchBeganWhilstPlaying = false
            return
        }
        // Aimed Sticky owns the launch while it runs (§5.4's launchControl group), whether
        // the finger dragged or only tapped

        if endlessIITapLaunchesHeldBall && touchBeganWhilstPlaying && paddleMoved == false && gameState.currentState is Playing {
            endlessIILaunchHeldBall()
            touchBeganWhilstPlaying = false
            return
        }
        // The sticky paddle may be holding several balls, and they leave in the order they
        // were caught. Only once the queue is empty does a tap belong to the first ball again

        if ballIsOnPaddle && touchBeganWhilstPlaying && paddleMoved == false && gameState.currentState is Playing {
            releaseBall()
        }
        touchBeganWhilstPlaying = false
        // Release the ball from the paddle only if the paddle has not been moved
    }

    /// Puts the ball on the paddle immediately, wherever its return animation had got to.
    func finishBallReturn() {
        ballIsReturning = false
        ball.removeAllActions()
        ball.isHidden = false
        ball.alpha = 1
        ball.setScale(1)
        ball.position.x = paddle.position.x
        setBallStartingPositionY()
        ball.position.y = ballStartingPositionY

        if let icon = lifeIcons.first, icon.hasActions() {
            icon.removeAllActions()
            icon.isHidden = true
        }
        // The spent life was flying to meet the ball, so it arrives now too
    }
    
    /// Spends one of the sticky paddle's catches, and puts it away once they run out.
    ///
    /// Every launch off a sticky paddle costs one, whichever ball it was - so with Multi-Ball
    /// a set of catches is spent across the balls rather than being renewed by each of them.
    /// Paints the multiplier's label, in the modes that have a multiplier.
    ///
    /// Every place that used to set this colour asks here instead. Endless mode has no
    /// multiplier: its label carries the best height, in its own dimmer white, and was being
    /// repainted white and Giga-Ball green as though thresholds it does not have were being
    /// crossed.
    func setMultiplierColour(_ colour: UIColor) {
        guard endlessMode == false else { return }
        multiplierLabel.fontColor = colour
    }

    /// Pulses the multiplier's label when it changes, in the modes that have a multiplier.
    ///
    /// Same reason as the colour: the Max Multiplier and Reset Multiplier power-ups carry no
    /// weight in endless mode today, and if that ever changed the best height would jump
    /// about as though it were a multiplier.
    func animateMultiplierLabel(_ action: SKAction) {
        guard endlessMode == false else { return }
        multiplierLabel.run(action, withKey: "multiplierAnimation")
    }

    /// Writes the multiplier into its label, in the modes that have one.
    ///
    /// Endless mode has no multiplier, and its label carries the best height instead. Four
    /// places wrote the multiplier straight into it, so the best height appeared at the start
    /// of a run and was replaced by "x1.0" by the first brick.
    func showMultiplier() {
        guard endlessMode == false else { return }
        multiplierLabel.text = "x\(scoreFactorString)"
    }

    func spendStickyPaddleCatch() {
        guard stickyPaddleCatches != 0 else { return }

        stickyPaddleCatches -= 1
        let iconBarLength: CGFloat = (CGFloat(stickyPaddleCatches)/CGFloat(max(1, stickyPaddleCatchesTotal)))
        stickyPaddleIconBar.run(SKAction.scaleX(to: iconBarLength, duration: 0.05))
        // Size icon timer based on number of catches remaining
        if paddleTexture == retroPaddle && endlessIIHasHeldExtras == false {
            paddleRetroStickyTexture.isHidden = true
        }
        // The paddle keeps its sticky look while it is still holding something

        if stickyPaddleCatches == 0 {
            paddleSticky.isHidden = true
            paddleRetroStickyTexture.isHidden = true
            stickyPaddleCatchesTotal = 0
            stickyPaddleIcon.texture = iconStickyPaddleDisabledTexture
            stickyPaddleIconBar.isHidden = true
            stickyPaddleIconBar.xScale = 0
            // Sticky paddle reset

            endlessIIReleaseRemainingHeldBalls()
            // The last catch was just spent on a launch, and with Multi-Ball another ball
            // can still be sitting on the paddle - held by a power-up that no longer
            // exists. It leaves now rather than waiting for a tap it has no claim to
        }
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
        
        spendStickyPaddleCatch()
        endlessIIReleasedFromPaddle(ball)
        // Out of the sticky queue, so the next tap belongs to whatever was caught after it

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
		
		if soundsSetting {
			self.run(ballReleaseSound)
		}
		
		startLevelTimer()
		// restart timer

		if hapticsSetting {
			lightHaptic.impactOccurred()
		}
		if musicSetting {
			MusicHandler.sharedHelper.gameVolume()
		}
    }
    
    override func didSimulatePhysics() {
        applyEndlessIIBallHandover()
        applyEndlessIIPaddlePhysics()
        applyEndlessIIWraps()
        applyEndlessIIPortalExit()
        resolveBrickSeamBounces()
    }
    // The one place a physics body can be moved from. Anything written to one during contact
    // resolution is undone by the rest of the step

    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered

		if gameMode == .endlessII {
			powerUpRings.update(with: activePowerUpEntries())
			tickEndlessIIBricks(currentTime)
			tickEndlessIIExtraBalls()
			tickEndlessIIHeldBalls()
			tickEndlessIIVision(currentTime)
			tickEndlessIIPaddlePowerUps(currentTime)
			tickEndlessIIFieldPowerUps()
			tickEndlessIIWrapAround()
			tickEndlessIIAim()
			tickEndlessIIBuildIn(currentTime)
		}
		
		if gameState.currentState is Paused {
			if self.isPaused == false && countdownStarted == false {
				self.isPaused = true
			}
		}
		// Ensures game is paused when returning from background

        if gameState.currentState is Playing {
			
			xSpeedLive = ball.physicsBody!.velocity.dx
			ySpeedLive = ball.physicsBody!.velocity.dy

			refreshPaddleReachability()
			// The paddle moves under the player's finger, so whether a ball is beneath it is
			// a question with a new answer every frame

			recordBallStatesBeforeStep()
			// Before the physics runs, because how a ball arrived is the only thing that says
			// which face it hit - and by the time a contact is reported that is already gone

			breakHorizontalRuns()
		
			if gravityActivated {
				if ball.position.y < paddle.position.y + ballSize*4 {
					ball.physicsBody?.affectedByGravity = false
				} else {
					ball.physicsBody?.affectedByGravity = true
					// Stop the ball being effected by gravity near the paddle
				}
			}
			// Sets the ball's gravity control
			
			if ball.physicsBody!.velocity.dx == 0 && ball.physicsBody!.velocity.dy == 0 && ballIsOnPaddle == false {
				ballSpeedZeroTracker+=1
				if ballSpeedZeroTracker >= 50 {
					ballSpeedZeroTracker = 0
					ballIsOnPaddle = true
					ball.position.x = paddle.position.x
					setBallStartingPositionY()
					ball.position.y = ballStartingPositionY
				}
			}
			// Check if ball has stopped and reset to paddle

			if ballIsOnPaddle {
				ball.position.y = ballStartingPositionY
				// Ensure ball remains on paddle
			}
		}
    }
    
    func ballLost() {
		if hapticsSetting {
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

		multiplier = Scoring.multiplierBase
		scoreFactorString = Scoring.displayString(multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight)m"
		}
		showMultiplier()
		setMultiplierColour(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
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
			
			flyLifeToPaddle()
			// The spent life travels to the paddle as the replacement ball appears there
			
            let fadeOutBall = SKAction.fadeOut(withDuration: 0)
            let scaleDownBall = SKAction.scale(to: 0, duration: 0)
            let waitTimeBall = SKAction.wait(forDuration: GameScene.ballReturnPause)
            let fadeInBall = SKAction.fadeIn(withDuration: 0.25)
            let scaleUpBall = SKAction.scale(to: 1, duration: 0.25)
            let resetBallGroup = SKAction.group([fadeOutBall, scaleDownBall, waitTimeBall])
            let ballGroup = SKAction.group([fadeInBall, scaleUpBall])
            // Setup ball animation

            ballIsReturning = true
            // A tap during this lands the ball on the paddle rather than launching it
            
            lifeLossPending = true
            self.run(SKAction.wait(forDuration: 0.75), completion: {
                self.livesAwaitingRollIn = false
                self.numberOfLives = max(0, self.numberOfLives - 1)
                self.lifeLossPending = false
                self.refreshLivesRow()
            })
            // Unchanged 0.75s before the count drops - other code reads numberOfLives
            // synchronously around here and the timing is load-bearing.
            //
            // The count is clamped because the drop is delayed but the game-over check
            // below is not: two losses inside the same 0.75s each schedule a decrement
            // while the check still sees the old count, so the count walks past zero and
            // "== 0" never matches again. A save with negative lives can then never
            // reach game over - the resume screen was reading back "-9 lives left".
            
            ball.run(resetBallGroup, completion: {
                self.ball.isHidden = false
                self.ball.run(ballGroup) {
                    self.ballIsReturning = false
                }
            })
            // Animate ball back onto paddle and loss of a life
        }
		
        if numberOfLives <= 0 {
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
    
    func ballLostAnimation(_ lost: SKSpriteNode? = nil) {
		if endlessIIBallWasLost(lost ?? ball) { return }
		// In Endless 2.0 the run continues while any ball is still in play. Losing one of
		// several costs nothing and never reaches the rest of this - which is the whole of
		// what phase 7 changes, and why it is asked before anything else happens

		if soundsSetting {
			if numberOfLives > 0 {
				self.run(ballLostSound)
			} else {
				self.run(gameOverSound)
			}
		}
		// Ball lost sound
		if musicSetting {
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

			let struckBall = firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue
				? (firstBody.node as? SKSpriteNode ?? ball)
				: ball
			let struckVelocity = struckBall.physicsBody?.velocity ?? .zero
			// Which ball this contact is about. With one in play it is always `ball` and
			// nothing below behaves differently; with more it is the only way to tell.
			// `xSpeedLive` is sampled from the first ball once a frame, so an extra ball
			// needs its own velocity rather than that one

			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.boarderCategory.rawValue {

				if endlessIIWrapTook(struckBall) == false {
					frameBallControl(xSpeed: -struckVelocity.dx, for: struckBall)
				}
				// While Wrap-Around runs the side is not a wall: the ball passes through and
				// re-enters opposite, from didSimulatePhysics

			}
			// Ball hits Frame
			
			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.backstopCategory.rawValue {

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
					if hapticsSetting {
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
				
				ballBackstopHit(struckBall)
				// Determine ball's angle after hitting backstop to prevent too shallow angle
				
				// The ball coming off the backstop is under the paddle, and the paddle is not
				// there while that is true - see `refreshPaddleReachability`. It used to be a
				// quarter-second window here instead, which was both the wrong shape for the
				// problem and never actually applied: the flag it set was never read
			}
			// Ball hits backstop

			if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.screenBlockCategory.rawValue {
				
				let frameBlockNode = secondBody.node
				let frameBlockSprite = frameBlockNode as! SKSpriteNode
				
				if frameBlockSprite.size.width < frameBlockSprite.size.height {
				// Ball hits side block
					if endlessIIWrapTook(struckBall) == false {
						frameBallControl(xSpeed: -struckVelocity.dx, for: struckBall)
					}
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
					
					// The velocity the ball arrived with. Read from the contact, it has already
					// been through the engine's own bounce off the ceiling - so negating it
					// sent the ball back *up* into the ceiling, where it hit again, and again,
					// and ran along the top of the screen horizontally until something else
					// knocked it out of it. Every bounce off the top was doing this; it only
					// showed when the ball arrived shallow enough to stay up there
					let incoming = ballStateBeforeStep[ObjectIdentifier(struckBall)]?.velocity
						?? struckVelocity

					struckBall.physicsBody!.velocity = CGVector(dx: incoming.dx,
																dy: -abs(incoming.dy))
					// Ensure the ySpeed is downwards - stated as "downwards" rather than as
					// "turned round", so it is true however the ball got here

					let angleDeg = Double(atan2(Double(struckBall.physicsBody!.velocity.dy), Double(struckBall.physicsBody!.velocity.dx)))/Double.pi*180
					ballHorizontalControl(angleDegInput: angleDeg, for: struckBall)
				}
			}
		   // Ball hits screenblock

            if firstBody.categoryBitMask == CollisionTypes.ballCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.brickCategory.rawValue {
				var brickNodeShare: SKNode?
                if let brickNode = secondBody.node {
					let struckSprite = brickNode as! SKSpriteNode
					noteBrickStrike(ball: struckBall, brick: struckSprite)
					// Two bricks touched in one step is the seam between them, and the ball
					// should leave it as though it were one long brick

					let struckSide = EndlessIIImpact.side(ballAt: struckBall.position,
														 brickAt: struckSprite.position,
														 brickSize: struckSprite.size)
					// Worked out here, where the ball's position is still the one it had on
					// contact, rather than inside hitBrick which is also reached by lasers
                    hitBrick(node: brickNode, sprite: struckSprite, hitFrom: struckSide,
							 struckBy: struckBall)
					brickNodeShare = brickNode
                }
				let angleDeg = Double(atan2(Double(struckBall.physicsBody!.velocity.dy), Double(struckBall.physicsBody!.velocity.dx)))/Double.pi*180

				if ball.texture != gigaBallTexture {
					ballHorizontalControl(angleDegInput: angleDeg, brickNode: brickNodeShare,
										  for: struckBall)
					ballVerticalControl(brickNode: brickNodeShare, for: struckBall)
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
				
                paddleHit(struckBall)
            }
            // Ball hits Paddle
            
            if firstBody.categoryBitMask == CollisionTypes.brickCategory.rawValue && secondBody.categoryBitMask == CollisionTypes.laserCategory.rawValue {
                if let brickNode = firstBody.node {
					totalStatsArray[0].lasersHit+=1
					hitBrick(node: brickNode, sprite: brickNode as! SKSpriteNode, laserNode: secondBody.node!, laserSprite: (secondBody.node as! SKSpriteNode), hitFrom: .bottom)
					// Lasers only ever arrive from underneath
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
				if powerUpNode!.zPosition == 2 {
					powerUpNode!.removeAllActions()
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
				ballLostAnimation(firstBody.node as? SKSpriteNode)
				// Which ball reached the bottom, not "the ball" - with more than one in play
				// they are not the same question
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
						achievement.percentComplete = percentComplete
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting powerUpLeaverHundred achievement", privacy: .public)")
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
						achievement.percentComplete = percentComplete
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting powerUpLeaverThousand achievement", privacy: .public)")
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
	
    func hitBrick(node: SKNode, sprite: SKSpriteNode, laserNode: SKNode? = nil, laserSprite: SKSpriteNode? = nil, hitFrom: EndlessIISide? = nil, struckBy: SKSpriteNode? = nil) {

		let gigaLaser = laserNode != nil && laserSprite?.texture == laserGigaTexture
		// A Giga-Ball laser passes through whatever it meets and carries on. Every `return`
		// below stops the laser as well as the brick, which is right for an ordinary one and
		// exactly wrong for this - a laser that is stopped by the first Directional brick it
		// meets is not going through anything
		let stopLaser = { if gigaLaser == false { laserNode?.removeFromParent() } }

		if sprite.endlessIIRole == .portal {
			stopLaser()
			if laserNode == nil {
				endlessIIEnterPortal(sprite, entering: struckBy ?? ball)
			}
			// A Portal takes the ball somewhere. A laser is not the ball, and firing one into
			// a Portal teleported the ball from wherever it happened to be - so the jump is
			// the one thing here that only the ball can set off. The laser still stops, as it
			// does on any brick it cannot destroy
			return
		}
		// A Portal is struck rather than damaged, so it never reaches the type switch

		if endlessIITriggerPowerUpBrick(sprite) {
			stopLaser()
			if hapticsSetting { lightHaptic.impactOccurred() }
			countBricks()
			return
		}
		// A power-up brick is spent the moment it breaks, whatever broke it - the ball, a
		// laser, an explosion. It never reaches the type switch below because it is not a type

		if endlessIIWreckingHit(struckBy: struckBy, laser: laserNode != nil) {
			stopLaser()
			totalStatsArray[0].bricksHit[0] += 1
			totalStatsArray[0].bricksDestroyed[0] += 1
			resetBrickBounce(for: struckBy)
			removeBrick(node: node, sprite: sprite)
			return
		}
		// A Wrecking Ball hit wins whatever it struck - Fixed, Directional, Multi-Hit,
		// Indestructible - and still bounces, which the collision does on its own. Through
		// the ordinary destroy path, so it scores, rolls and counts like any hit

		if endlessIIAnchorIfNeeded(sprite) {
			stopLaser()
			if hapticsSetting { lightHaptic.impactOccurred() }
			if soundsSetting { self.run(brickHitNormalSound) }
			return
		}
		// A Fixed brick spends its first hit anchoring itself. The second one destroys it

		if endlessIIAcceptsHit(sprite, from: hitFrom) == false {
			stopLaser()
			if sprite.isHidden {
				sprite.run(.fadeIn(withDuration: 0.2))
				sprite.isHidden = false
			}
			// An invisible Directional brick still appears on its first hit, whichever face
			// was struck - being hidden is about knowing it is there, being armoured is
			// about how it dies, and a hit answers the first question from any side
			if hapticsSetting {
				lightHaptic.impactOccurred()
			}
			if soundsSetting {
				self.run(brickHitNormalSound)
			}
			noteBrickBounce(for: struckBy)
			return
		}
		// Directional brick struck on one of its armoured sides: it bounces, nothing else

        if hapticsSetting {
			lightHaptic.impactOccurred()
		}

		stopLaser()
        // Remove laser if giga-ball power up isn't activated
		
		if sprite.texture == brickIndestructible2Texture {
			noteBrickBounce(for: struckBy)
		} else {
			resetBrickBounce(for: struckBy)
		}
		
		if sprite.texture == brickMultiHit1Texture || sprite.texture == brickMultiHit2Texture || sprite.texture == brickMultiHit3Texture || sprite.isHidden {
			levelScore = levelScore + Scoring.award(brickDestroyScore, multiplier: multiplier)
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
			endlessIIBrickStruck(sprite)
			// An Endless 2.0 brick that can never be destroyed fires its style here instead
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
		if self.soundsSetting {
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

		endlessIIBrickDestroyed(sprite)
		// Endless 2.0's Exploding and Spawner bricks act now, and anything that falls
		// settles into the space this brick just left. Run before the count, so the count
		// sees the field as it ends up rather than as it was mid-change

		countBricks()
		
		if sprite.texture != brickIndestructible2Texture && sprite.texture != brickIndestructible1Texture {
			
			if brickRemovalCounter == Scoring.bricksPerMultiplierStep - 1 && endlessMode == false {
				multiplier = Scoring.steppedForBrick(multiplier)
				brickRemovalCounter = 0
			} else {
				brickRemovalCounter+=1
			}
			// Update multiplier
			
			levelScore = levelScore + Scoring.award(brickDestroyScore, multiplier: multiplier)
		}
		
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		scoreFactorString = Scoring.displayString(multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight)m"
		}
		setMultiplierColour(multiplier >= 2 ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
		showMultiplier()
		// Update score
        
        if bricksLeft == 0 && endlessMode == false {
			if soundsSetting {
				self.run(levelCompleteSound)
			}
			clearSavedGame()
			checkPaddleHitsAchievement()
			self.removeAction(forKey: "gameTimer")
			// Stop the level timer
			levelTimerBonus = Scoring.timerBonus(from: levelTimerBonus, elapsed: levelTimerValue, multiplier: multiplier)
			levelScore = levelScore + Scoring.levelCompletionAward()
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
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting fivePaddleHits achievement", privacy: .public)")
					}
				}
			}
			if paddleHitsPerLevel <= 10 && totalStatsArray[0].achievementsUnlockedArray[42] == false {
				totalStatsArray[0].achievementsUnlockedArray[42] = true
                totalStatsArray[0].achievementDates[42] = Date()
				let achievement = GKAchievement(identifier: "tenPaddleHits")
				if achievement.isCompleted == false {
					achievement.showsCompletionBanner = true
					GKAchievement.report([achievement]) { (error) in
						Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting tenPaddleHits achievement", privacy: .public)")
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
				
				if self.endlessMode && spriteBrick.position.y <= self.finalBrickRowHeight + self.brickHeight/2
					&& spriteBrick.endlessIIIsAnchored == false {
					endlessModeBricks+=1
				}
				// An anchored brick does not descend, so one anchored low would sit in the
				// bottom row for ever and no row would ever be generated again. It is still
				// destructible by the player, by an explosion, or by Zap - it simply does
				// not hold the field up while it waits
				// Count number of active bricks in bottom row of bricks in endless mode
				
				if self.endlessMode && spriteBrick.hasActions() {
					self.endlessMoveInProgress = true
				} else {
					self.endlessMoveInProgress = false
				}
				// Checks if brick move is already in progress in endless mode
			}
		}
		
		if endlessMode && bricksLeft == 0 && totalStatsArray[0].achievementsUnlockedArray[22] == false {
			totalStatsArray[0].achievementsUnlockedArray[22] = true
			totalStatsArray[0].achievementDates[22] = Date()
			let achievement = GKAchievement(identifier: "endlessCleared")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting endlessCleared achievement", privacy: .public)")
				}
			}
		}
		// Check achievement for clearing endless mode screen of active bricks
							
		if endlessMode && endlessMoveInProgress == false && endlessModeBricks == 0
			&& endlessIIDescentSuspendsCadence == false {
			moveEndlessModeRowDown()
		}
		// If there's no other bricks in the bottom row and a move isn't currently in progress,
		// move to the row with the next lowest bricks - unless Descent owns the field's
		// movement right now, where both at once would double-step (§5.4)
	}
	
	func moveEndlessModeRowDown() {
				
		endlessMoveInProgress = true
						
		let moveBricksDown = SKAction.moveBy(x: 0, y: -brickHeight, duration: 0.05)
		let anchored = endlessIIAnchoredCells()

		enumerateChildNodes(withName: BrickCategoryName) { (node, _) in
			if node.position.y <= self.finalBrickRowHeight + self.brickHeight/2 {
				node.removeFromParent()
				return
			}
			// Count number of active bricks in bottom row of bricks in endless mode

			if self.endlessIIStaysPut(node) { return }
			// An anchored brick is the one thing the field descends around

			if self.endlessIICrushedByAnchor(node, anchored: anchored) {
				if let brick = node as? SKSpriteNode { self.endlessIIDestroy(brick) }
				return
			}
			// Anything descending onto an anchored brick is destroyed by it, which is what
			// carves a channel up through everything arriving above it

			node.run(moveBricksDown)
		}
		// Move bricks down. By a row, not by each brick's own height - those were the same
		// number while every brick was exactly one cell, but a brick that is any other size
		// would drift out of step with the field it belongs to
		
		if soundsSetting {
			self.run(endlessRowDownSound)
		}
		
		if gameState.currentState is Playing {
			buildNewEndlessRow()
		}

		endlessHeight+=1
		refreshEndlessIIBest()
		moveEndlessIIMarkersDown()
		addEndlessIIMarkerIfDue()
		addEndlessIITickIfDue()
		// Existing markers move first, then the new one is placed - otherwise the line just
		// added would immediately travel a row and sit against the wrong height
		
		if endlessHeight >= 10 && totalStatsArray[0].achievementsUnlockedArray[0] == false {
			totalStatsArray[0].achievementsUnlockedArray[0] = true
			totalStatsArray[0].achievementDates[0] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessTen")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessTen achievement", privacy: .public)")
				}
			}
		}
		if endlessHeight >= 100 && totalStatsArray[0].achievementsUnlockedArray[1] == false {
			totalStatsArray[0].achievementsUnlockedArray[1] = true
			totalStatsArray[0].achievementDates[1] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessHundred")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessHundred achievement", privacy: .public)")
				}
			}
		}
		if endlessHeight >= 500 && totalStatsArray[0].achievementsUnlockedArray[2] == false {
			totalStatsArray[0].achievementsUnlockedArray[2] = true
			totalStatsArray[0].achievementDates[2] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessFiveHundred")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessFiveHundred achievement", privacy: .public)")
				}
			}
		}
		if endlessHeight >= 1000 && totalStatsArray[0].achievementsUnlockedArray[3] == false {
			totalStatsArray[0].achievementsUnlockedArray[3] = true
			totalStatsArray[0].achievementDates[3] = Date()
			let achievement = GKAchievement(identifier: "achievementEndlessOneK")
			if achievement.isCompleted == false {
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting achievementEndlessOneK achievement", privacy: .public)")
				}
			}
		}
		// Check for endless mode height achievements
		
		if multiplier < Scoring.multiplierCap {
			multiplier = Scoring.steppedForBonus(multiplier)
			setMultiplierColour(Scoring.isAtCap(multiplier) ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
		}
		
		levelScore = levelScore + Scoring.award(100, multiplier: multiplier)
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		
		scoreFactorString = Scoring.displayString(multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight)m"
		}
		
		showMultiplier()
		// Update multiplier & score

		let wait = SKAction.wait(forDuration: 0.075)
        self.run(wait, completion: {
            self.countBricks()
        })
        // To run once the new row is inserted - slight delay to allow frame to move forward before executing
	}
	
	func ballBackstopHit(_ subject: SKSpriteNode) {
		let ball = subject
		if soundsSetting {
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
		ballHorizontalControl(angleDegInput: angleDeg, for: subject)
	}
    
    /// The paddle was hit by a ball. Which ball is not optional: everything below writes a
    /// velocity, and doing that to the first ball whichever one landed is how hitting the
    /// paddle with one ball made another turn.
    func paddleHit(_ subject: SKSpriteNode) {
		let ball = subject
		let isExtra = subject !== self.ball
		let isOnPaddle = isExtra ? false : ballIsOnPaddle
		// An extra ball is never the one resting on the paddle, and it must not be stopped
		// from bouncing because the first one is. Shadowing `ball` with the one that was
		// actually in the contact is what lets the rest of this read unchanged

		if isOnPaddle {
			return
		}

		if ballIsUnderPaddle(ball) {
			return
		}

		endlessIISpendPaddleTurns()
		// This contact is a turn for every running paddle power-up, whatever the paddle
		// does with it below - a catch, a swallow or a bounce all count the same one
		// A contact reported while the ball's centre is below the paddle's is not a landing.
		// The paddle is taken out of a ball's way while it is underneath (see
		// `refreshPaddleReachability`) and handed back the moment it is not, and a ball still
		// overlapping the paddle when that happens is reported as a fresh hit - a bounce off
		// nothing, in the empty space between the paddle and the field. One ball rarely
		// lingers there; four do it constantly

        if hapticsSetting {
			lightHaptic.impactOccurred()
		}

		if isExtra == false {
			setBallStartingPositionY()
		}

		paddleHitsPerLevel+=1

        totalStatsArray[0].ballHits+=1
		resetBrickBounce(for: ball)
		if isExtra == false {
			ballRelativePositionOnPaddle = ball.position.x - paddle.position.x
		}
		// Where on the paddle the ball sits is about the ball that can be caught, which is
		// the first one - a Sticky Paddle holds one ball, not whichever arrived last

		let xSpeed = ball.physicsBody!.velocity.dx
		let ySpeed = ball.physicsBody!.velocity.dy
		let paddleLeftEdgePosition = paddle.position.x - paddle.size.width/2
		let paddleRightEdgePosition = paddle.position.x + paddle.size.width/2
		var collisionPercentage = Double((ball.position.x - paddle.position.x)/(paddle.size.width/2))
		// Define collision position between the ball and paddle
		let ySpeedCorrected: Double = sqrt(Double(ySpeed*ySpeed))
		// Assumes the ball's ySpeed is always positive
		var angleDeg = Double(atan2(Double(ySpeedCorrected), Double(xSpeed)))/Double.pi*180
		// Angle of the ball
		
		if paddleTexture == squarePaddle && ball.position.y >= paddle.position.y + paddleHeight/2 {
			if collisionPercentage < -1.0 {
				collisionPercentage = -1.0
			}
			if collisionPercentage > 1.0 {
				collisionPercentage = 1.0
			}
		}
		// Paddle bounce angle rules are slightly different for square paddle due to lack of round edges
				
		if soundsSetting {
			if ball.position.x > paddleLeftEdgePosition + ball.size.width/3 && ball.position.x < paddleRightEdgePosition - ball.size.width/3 && stickyPaddleCatches != 0 {
				self.run(stickyPaddleHitSound)
			} else {
				self.run(ballPaddleHitSound)
			}
		}
		
		let inTheStickyBand = ball.position.x > paddleLeftEdgePosition + ball.size.width/3
			&& ball.position.x < paddleRightEdgePosition - ball.size.width/3
			&& collisionPercentage < 1.0 && collisionPercentage > -1.0
			&& stickyPaddleCatches != 0

		if isOnPaddle == false && ball.position.y >= paddle.position.y + paddleHeight/2
			&& endlessIIAimedCatch(ball, isExtra: isExtra) {
			return
		}
		// Aimed Sticky catches any ball landing on the top surface, wherever it lands - it
		// owns the launch while it runs, and costs no sticky catches

		if isExtra && inTheStickyBand && endlessIICatchExtraBall(ball) {
			return
		}
		// An extra ball is caught and held like any other. It waits its turn in the queue and
		// leaves on its own tap - a paddle that caught the first ball and bounced the rest
		// would be a power-up that stopped working the moment Multi-Ball was collected

		if isExtra == false && inTheStickyBand {
		// Catch the ball
		// Only apply if the ball hits the centre of the paddle.
						
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
			endlessIIFirstBallWasCaught()
			// Takes its place in the queue behind anything caught before it
			invisibleBrickFlash()
			
			if musicSetting {
				MusicHandler.sharedHelper.menuVolume()
			}
			return
			// Don't try to adjust the ball's angle if it is on the paddle
		}
		
		if isOnPaddle == false && endlessIIPaddlePortalTook(ball) {
			return
		}
		// A Portal Paddle swallows the ball instead of bouncing it; it re-enters at the top
		// after the step resolves. Past the catches, so a held ball is held first

		if isOnPaddle == false && ball.position.y >= paddle.position.y + paddleHeight/2 && (collisionPercentage < 1.0 && collisionPercentage > -1.0) {
		// Only applies if the ball hits the top surface of the paddle
			
			angleDeg = angleDeg - angleAdjustmentK*collisionPercentage*endlessIIPaddleAngleInfluence
			// Angle adjustment formula - the ball's angle can change up to angleAdjustmentK deg depending on where the ball hits the paddle
			
			if angleDeg < 0+minAngleDeg {
				angleDeg = minAngleDeg
			}
			// Travelling up and right alternative
			if angleDeg > 180-minAngleDeg {
				angleDeg = 180-minAngleDeg
			}
			// Travelling up and left alternative
			// Prevents the new angle from over correting to a downward angle
		}

		if isOnPaddle == false && collisionPercentage < 1.0 && collisionPercentage > -1.0 {
		// Only control the ball's angle if it in the centre of the paddle
			if ball.position.y > paddle.position.y {
				ballHorizontalControl(angleDegInput: angleDeg, for: ball)
			}
			// Only control is the ball is above the paddle - and for the ball that was
			// actually caught by it. This is where the paddle's angle is applied, and without
			// the subject it was applied to the first ball whichever ball had landed: hitting
			// the paddle with one made another one turn
		}
		
		invisibleBrickFlash()
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

		// Centred on the brick, but never over the wall. A power-up is nearly a cell wide and
		// a Tiny brick is a quarter of one, so a Tiny brick in the outermost column drops a
		// power-up whose outer half is behind the border - visible enough to be seen and cut
		// in half. Shifted inside instead, which costs nothing: it still falls from the brick
		// that dropped it
		let inset = powerUp.size.width/2
		let x = min(max(sprite.position.x, -gameWidth/2 + inset), gameWidth/2 - inset)
        powerUp.position = CGPoint(x: x, y: sprite.position.y)
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
		
        guard powerUpCanAppear(powerUpSelection) else {
            removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
            return
        }
        // Whether this one has anything to do lives in `powerUpCanAppear`, where the power-up
        // brick can ask the same question. It used to be a condition inside each case of the
        // switch below, which meant a brick could hold a Show Bricks with nothing to show

        guard powerUpTextureArray.indices.contains(powerUpSelection) else {
            removePowerUp(sprite: sprite, powerUp: powerUp, powerUpSelection: powerUpSelection)
            return
        }
        powerUp.texture = powerUpTextureArray[powerUpSelection]
        // The textures are held in power-up order, so the switch that assigned twenty-nine of
        // them one case at a time was a second copy of that order - and it had 28 listed
        // between 25 and 26

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
		
		if hapticsSetting {
			rigidHaptic.impactOccurred()
		}
		
		if soundsSetting {
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
				achievementPowerUp.showsCompletionBanner = true
				GKAchievement.report([achievementPowerUp]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting firstPowerUp achievement", privacy: .public)")
				}
			}
		}
		// First power-up achievement
		
        switch sprite.texture {
            
        case powerUpGetALife:
        // Get a life
            numberOfLives+=1
            rollInGainedLife()
			
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
				refreshLaserFiringRate()
			} else if ballSpeedLimit < ballSpeedNominal {
				ballSpeedLimit = ballSpeedSlowest
				refreshLaserFiringRate()
			} else if ballSpeedLimit > ballSpeedNominal {
				ballSpeedLimit = ballSpeedNominal
				refreshLaserFiringRate()
				ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				ballSpeedIconBar.isHidden = true
			}
			ballSpeedControl()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[2]+=1
			// Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.ballSpeedLimit = self.ballSpeedNominal
				self.refreshLaserFiringRate()
				self.ballSpeedControl()
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
				refreshLaserFiringRate()
			} else if ballSpeedLimit > ballSpeedNominal {
				ballSpeedLimit = ballSpeedFastest
				refreshLaserFiringRate()
			} else if ballSpeedLimit < ballSpeedNominal {
				ballSpeedLimit = ballSpeedNominal
				refreshLaserFiringRate()
				ballSpeedIcon.texture = self.iconBallSpeedDisabledTexture
				ballSpeedIconBar.isHidden = true
			}
			ballSpeedControl()
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[3]+=1
            // Power up set
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
			let completionBlock = SKAction.run {
				self.ballSpeedLimit = self.ballSpeedNominal
				self.refreshLaserFiringRate()
				self.ballSpeedControl()
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
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting maxPaddleSize achievement", privacy: .public)")
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
				if self.hapticsSetting {
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
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting minPaddleSize achievement", privacy: .public)")
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
                if self.hapticsSetting {
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
			multiplier = Scoring.multiplierCap
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[12]+=1
			animateMultiplierLabel(.sequence([timerScaleUp, timerScaleDown]))
			// Power up set
			
		case powerUpMultiplierReset:
		// Mutliplier reset to 1
			removeAction(forKey: "multiplierAnimation")
			multiplier = Scoring.multiplierBase
			brickRemovalCounter = 0
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[13]+=1
			animateMultiplierLabel(.sequence([pointsScaleDown, timerScaleDown]))
			
		case powerUpNextLevel:
        // Next level
			powerUpMultiplierScore = 0
			totalStatsArray[0].powerupsCollected[14]+=1
			clearSavedGame()
			self.removeAction(forKey: "gameTimer")
			// Stop the level timer
			levelTimerBonus = Scoring.timerBonus(from: levelTimerBonus, elapsed: levelTimerValue, multiplier: multiplier)
			if soundsSetting {
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
				guard node.endlessIIRole != .portal else { return }
				// A Portal is built on the Indestructible texture but it is not one of them.
				// It is never destroyed by anything - clearing the indestructibles would
				// take the way out of the field with them
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
				levelScore = levelScore + Scoring.levelCompletionAward()
				if endlessMode == false {
					scoreLabel.text = String(totalScore + levelScore)
				}
				self.removeAction(forKey: "gameTimer")
				// Stop the level timer
				levelTimerBonus = Scoring.timerBonus(from: levelTimerBonus, elapsed: levelTimerValue, multiplier: multiplier)
				if soundsSetting {
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
			laserStacks = laserPowerUpIsOn ? min(laserStacks + 1, GameScene.laserMaxStacks) : 0
			// Collecting lasers while they are already firing speeds them up
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
			laserTimer = Timer.scheduledTimer(timeInterval: laserInterval, target: self, selector: #selector(laserGenerator), userInfo: nil, repeats: true)
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[22]+=1
			powerUpLimit = 4
            // Power up set - every 0.25s, halving with each stack
            let timer: Double = 10 * multiplier
            let waitDuration = SKAction.wait(forDuration: timer)
            let completionBlock = SKAction.run {
                self.laserTimer?.invalidate()
				self.laserStacks = 0
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
					achievementMystery.showsCompletionBanner = true
					GKAchievement.report([achievementMystery]) { (error) in
						Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting mysteryPowerUp achievement", privacy: .public)")
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
//						self.ballPhysicsBodySet()
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
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting maxBallSize achievement", privacy: .public)")
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
				if self.hapticsSetting {
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
            
		case powerUpTrajectoryLine:
		// 29 - Trajectory Line
			endlessIICollectTrajectoryLine()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[29] += 1

		case powerUpLandingMarker:
		// 30 - Landing Marker
			endlessIICollectLandingMarker()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[30] += 1

		case powerUpAimedSticky:
		// 31 - Aimed Sticky
			endlessIICollectAimedSticky()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[31] += 1

		case powerUpMagnetism:
		// 32 - Magnetism
			endlessIICollectMagnetism()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[32] += 1

		case powerUpPortalPaddle:
		// 33 - Portal Paddle
			endlessIICollectPortalPaddle()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[33] += 1

		case powerUpPaddleHalo:
		// 34 - Paddle Halo
			endlessIICollectPaddleHalo()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[34] += 1

		case powerUpBallSteering:
		// 35 - Ball Steering
			endlessIICollectBallSteering()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[35] += 1

		case powerUpInertPaddle:
		// 36 - Inert Paddle. Bad
			endlessIICollectInertPaddle()
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[36] += 1

		case powerUpFlippedAngle:
		// 37 - Flipped Angle. Bad
			endlessIICollectFlippedAngle()
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[37] += 1

		case powerUpReversedControls:
		// 38 - Reversed Controls. Bad
			endlessIICollectReversedControls()
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[38] += 1

		case powerUpCull:
		// 39 - Cull
			endlessIICull()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[39] += 1

		case powerUpClearAndRetreat:
		// 40 - Clear And Retreat
			endlessIIClearAndRetreat()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[40] += 1

		case powerUpLaserBeam:
		// 41 - Laser Beam
			endlessIIFireLaserBeams()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[41] += 1

		case powerUpWreckingBall:
		// 42 - Wrecking Ball
			endlessIICollectWreckingBall()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[42] += 1

		case powerUpAura:
		// 43 - Aura
			endlessIICollectAura()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[43] += 1

		case powerUpInfill:
		// 44 - Infill. Bad
			endlessIIInfill()
			powerUpMultiplierScore = -0.1
			totalStatsArray[0].powerupsCollected[44] += 1

		case powerUpDescent:
		// 45 - Descent
			endlessIICollectDescent()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[45] += 1

		case powerUpAutoAim:
		// 46 - Auto-Aim
			endlessIICollectAutoAim()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[46] += 1

		case powerUpWrapAround:
		// 47 - Wrap-Around
			endlessIICollectWrapAround()
			powerUpMultiplierScore = 0.1
			totalStatsArray[0].powerupsCollected[47] += 1

		case powerUpMultiBall:
		// Multi-Ball
			endlessIIAddBall()
			// The whole effect. Everything that makes an extra ball work - its contacts, its
			// share of the speed and size, the run continuing while any of them survives - is
			// the collection the scene already holds, so collecting this is one call

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
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting minBallSize achievement", privacy: .public)")
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
				if self.hapticsSetting {
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
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting favouritePowerUp achievement", privacy: .public)")
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
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting powerUpCollectorHundred achievement", privacy: .public)")
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
				achievement.percentComplete = percentComplete
				achievement.showsCompletionBanner = true
				GKAchievement.report([achievement]) { (error) in
					Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting powerUpCollectorThousand achievement", privacy: .public)")
				}
			}
		}
		// Power-up collection achievements

		powerUpsCollectedPerLevel+=1
        levelScore = levelScore + Scoring.award(powerUpScore, multiplier: multiplier)
		multiplier = Scoring.adjusted(multiplier, by: powerUpMultiplierScore)
		setMultiplierColour(Scoring.isAtCap(multiplier) ? #colorLiteral(red: 0.8235294118, green: 1, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
		// Ensure multiplier never goes below 1 or above 2
		if endlessMode == false {
			scoreLabel.text = String(totalScore + levelScore)
		}
		scoreFactorString = Scoring.displayString(multiplier)
		if endlessMode {
			scoreLabel.text = "\(endlessHeight)m"
		}
		showMultiplier()
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
		endlessIIResetVision()
		endlessIIResetPaddlePowerUps()
		endlessIIResetFieldPowerUps()
		endlessIIResetWrapAround()
		// Endless 2.0's own power-ups keep their own clocks, so the removeAllActions above
		// does not reach them
		powerUpsOnScreen = 0
		multiplier = Scoring.multiplierBase
		setMultiplierColour(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        
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
		laserStacks = 0
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
		for subject in endlessIIBallsInPlay {
			guard let body = subject.physicsBody else { continue }

			if ball.texture == gigaBallTexture {
			// Giga-Ball power-up
				body.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue | CollisionTypes.backstopCategory.rawValue
				// Reset undestructi-ball power-up
				body.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.backstopCategory.rawValue
				// Set giga-ball power-up
			} else {
				body.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.backstopCategory.rawValue
				body.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.paddleCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue | CollisionTypes.boarderCategory.rawValue | CollisionTypes.bottomScreenBlockCategory.rawValue | CollisionTypes.backstopCategory.rawValue
				// Set ball physics body
			}
		}
		// Every ball in play, from the first ball's state. A power-up is collected by the
		// paddle and belongs to the run rather than to whichever ball happened to knock it
		// down - so all four wear the Giga-Ball texture, and until this loop existed only one
		// of them actually passed through anything

		refreshPaddleReachability()
		// Applied last, because everything above hands the paddle back
	}
	// Set ball's physics bodies

	/// Whether a ball is underneath the paddle rather than in front of it.
	///
	/// Measured against the paddle's centre. A catch happens with the ball sitting on the
	/// paddle's top surface, a whole radius above this, so there is no legitimate hit this can
	/// take away - and a ball whose centre is below the paddle's is one that has got past.
	func ballIsUnderPaddle(_ subject: SKSpriteNode) -> Bool {
		subject.position.y < paddle.position.y
	}

	/// Takes the paddle out of a ball's way while the ball is underneath it.
	///
	/// The Backstop's whole purpose is to send a ball that got past the paddle back up. It
	/// could not do that: the paddle is solid from below as well as above, so a player who
	/// moved the paddle over the rescued ball had it bounced straight back down off the
	/// underside and lost the life the Backstop had just saved.
	///
	/// Stated as a condition rather than as a window of time, because that is what it is - the
	/// paddle is not in the way until the ball is in front of it. It costs nothing in ordinary
	/// play, where a ball below the paddle is already gone, and it applies in every mode.
	func refreshPaddleReachability() {
		for subject in endlessIIBallsInPlay {
			setPaddleReachable(ballIsUnderPaddle(subject) == false, for: subject)
		}
	}

	func setPaddleReachable(_ reachable: Bool, for subject: SKSpriteNode) {
		guard let body = subject.physicsBody else { return }
		let paddleBit = CollisionTypes.paddleCategory.rawValue

		let collision = reachable ? body.collisionBitMask | paddleBit
								  : body.collisionBitMask & ~paddleBit
		let contact = reachable ? body.contactTestBitMask | paddleBit
								: body.contactTestBitMask & ~paddleBit

		if body.collisionBitMask != collision { body.collisionBitMask = collision }
		if body.contactTestBitMask != contact { body.contactTestBitMask = contact }
	}

    func moveToMainMenu() {
		gameViewControllerDelegate?.moveToMainMenu()
    }
    // Function to return to the MainViewController from the GameViewController, run as a delegate from GameViewController
	
	// The playfield's proportions live in `GameSceneLayout`, which works them out for any
	// screen without needing a scene - the background selection screen draws a scale model
	// of this one and has to get the same answers. These are the names the scene has always
	// used for them.
	static let playRatio = GameSceneLayout.playRatio
	static let hudUnits = GameSceneLayout.hudUnits
	/// The same bar in Endless 2.0, which does not carry the eight-slot tray.
	///
	/// The rings show only what is running, and carry their timers around the icons rather
	/// than on a bar beneath them, so the row costs a little over an icon's height instead of
	/// an icon plus a bar plus the gap between. The height that buys goes to the playfield:
	/// the play area holds a fixed ratio, so a shorter bar makes it both taller and wider,
	/// and the side borders shrink to match.
	/// Sized so the ring row clears the play area on every device. The gap the rings have to
	/// fit in is `layoutUnit*(hudUnits - 2)` and the rings need `layoutUnit*1.5 + 16`, and
	/// the 16 is fixed padding that does not shrink with the unit - so on a large phone 4.3
	/// came up 0.2pt short and the container crossed the top of the field.
	static let endlessIIHudUnits = GameSceneLayout.endlessIIHudUnits

	static let hudTopClearance = GameSceneLayout.hudTopClearance
	/// How solid each wall is, when the border it fills is thinner than this.
	///
	/// Costs nothing on screen - the surplus is off the edge - and it means the play area
	/// never has to leave a margin behind just to keep its walls.
	static let minimumWallThickness = GameSceneLayout.minimumWallThickness
	// Clearance from the physical top edge to the HUD, in points, used instead of
	// safeAreaInsets.top.
	//
	// The inset is a full-width reservation for the notch or Dynamic Island, but the HUD
	// only occupies the two top corners - pause button and lives on the left, score and
	// multiplier on the right - and those are horizontally clear of the housing on every
	// iPhone. Reserving the full inset therefore cost about 44pt of height on a Dynamic
	// Island phone, which came straight back as wider side borders, for no benefit.
	//
	// 20pt keeps the row clear of the rounded display corners: at y=20 a 55pt corner
	// radius permits content from x=12.6, and the leftmost HUD element starts at 21pt.
	// Nothing may be placed in the centre of this row - that is what the inset was
	// protecting, and it is why the endless-mode logo was removed

	var isRegularWidth: Bool {
		self.view?.traitCollection.horizontalSizeClass == .regular
	}
	// iPad-class width. Replaces the old screenRatio device-class guess: it is the
	// supported signal for this, and unlike a ratio test it reports .compact for a
	// narrow multitasking slot, which is what the HUD placement below actually wants

	var livesRowSpacing: CGFloat { ballSize*1.6 }
	var livesRowPadding: CGFloat { ballSize*0.55 }

	var livesSlots: Int { max(3, min(numberOfLives, GameScene.maxLivesShown)) }
	// The container holds at least the three lives a pack starts with, so an empty one
	// reads as "no lives left" rather than as a missing element. It grows past three when
	// lives are gained and never shrinks back below it

	var livesContainerSize: CGSize { livesContainerSize(forSlots: CGFloat(livesSlots)) }

	func livesContainerSize(forSlots slots: CGFloat) -> CGSize {
		CGSize(width: (slots - 1)*livesRowSpacing + ballSize + livesRowPadding*2,
			   height: ballSize + livesRowPadding*2)
	}
	// Takes a fractional slot count so the container can be animated between two sizes
	// rather than snapping when a life is spent

	static let lifeIconAlpha: CGFloat = 0.775
	/// How long the row takes to close up after a life is spent. Matches the flight to the
	/// paddle so the two read as one movement.
	static let livesGapCloseDuration: TimeInterval = 0.25
	static let livesKnockStagger: TimeInterval = 0.03
	// Dimmer than the ball in play, so the row reads as a counter rather than as balls
	// sitting in the play area, but still bright enough to read at a glance

	var livesRowY: CGFloat {
		let paddleBottom = paddle.position.y - paddleHeight/2
		let safeBottom = -frame.size.height/2 + (self.view?.safeAreaInsets.bottom ?? 0)
		return paddleBottom + (safeBottom - paddleBottom)*0.6
	}
	// Sixty per cent of the way from the paddle down to the safe area, rather than a
	// fixed gap below the paddle. Close to the paddle the row read as playable - another
	// row of balls just under the one in play - so it sits nearer the bottom edge, well
	// clear of the paddle and still above the home indicator on every device

	func buildLivesRow() {
		livesContainer.removeFromParent()
		livesContainer = SKShapeNode()
		livesContainer.fillColor = UIColor(white: 1.0, alpha: 0.10)
		livesContainer.strokeColor = .clear
		livesContainer.zPosition = 9
		livesContainer.isHidden = true
		addChild(livesContainer)

		lifeIcons.forEach { $0.removeFromParent() }
		lifeIcons = (0..<GameScene.maxLivesShown).map { _ in
			let icon = SKSpriteNode(texture: ballTexture)
			icon.size = CGSize(width: ballSize, height: ballSize)
			icon.zPosition = 10
			icon.isHidden = true
			addChild(icon)
			return icon
		}
		layoutLivesRow()
	}
	// One sprite per displayable life, reused rather than created per ball lost so the
	// flight animation always has a node to move

	func layoutLivesRow() {
		layoutLivesContainer()
		for (index, icon) in lifeIcons.enumerated() {
			icon.size = CGSize(width: ballSize, height: ballSize)
			icon.position = livesRowHome(index: index)
		}
	}

	func layoutLivesContainer() {
		setLivesContainerPath(size: livesContainerSize)
		livesContainer.position = CGPoint(x: 0, y: livesRowY)
	}

	func setLivesContainerPath(size: CGSize) {
		let rect = CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height)
		livesContainer.path = CGPath(roundedRect: rect,
									 cornerWidth: size.height/2,
									 cornerHeight: size.height/2,
									 transform: nil)
	}
	// Rebuilt rather than scaled: scaling an SKShapeNode would stretch the rounded ends
	// along with it

	func livesRowHome(index: Int) -> CGPoint {
		livesRowHome(index: index, containerWidth: livesContainerSize.width)
	}

	func livesRowHome(index: Int, containerWidth: CGFloat) -> CGPoint {
		let firstX = -containerWidth/2 + livesRowPadding + ballSize/2
		return CGPoint(x: firstX + CGFloat(index)*livesRowSpacing, y: livesRowY)
	}
	// Filled from the left of a centred container. The ball that is spent is taken from
	// the left too - it is the one nearest the paddle - and the rest close up behind it

	func refreshLivesRow() {
		let shown = min(numberOfLives, GameScene.maxLivesShown)
		layoutLivesContainer()
		livesContainer.isHidden = endlessMode
		for (index, icon) in lifeIcons.enumerated() {
			icon.removeAllActions()
			icon.position = livesRowHome(index: index)
			icon.setScale(1)
			icon.alpha = GameScene.lifeIconAlpha
			icon.texture = ballTexture
			icon.isHidden = endlessMode || index >= shown || livesAwaitingRollIn
		}
	}
	// Endless mode has a single life and no counter, so the row is hidden there

	func setLivesRowHidden(_ hidden: Bool) {
		if hidden {
			livesContainer.isHidden = true
			lifeIcons.forEach { $0.isHidden = true }
		} else {
			refreshLivesRow()
		}
	}
	// Follows the same lifecycle as the rest of the HUD: hidden during the level intro,
	// shown while playing and paused

	@objc func levelIntroDidAppearReceived(notification: Notification) {
		endlessIILevelIntroShowing = true
	}

	@objc func levelIntroWillClearReceived(notification: Notification) {
		endlessIILevelIntroShowing = false
		endlessIIBuildInStartNow = true
	}

	@objc func levelIntroDidClearReceived(notification: Notification) {
		endlessIILevelIntroShowing = false
		rollInLivesRow()
	}
	// The level intro posts this when its view is finally removed. Keying the roll-in to
	// .continueToNextLevel instead would fire two seconds early, while the overlay is
	// still dismissing, and the whole animation would play behind it

	func rollInLivesRow() {
		livesAwaitingRollIn = false
		let shown = min(numberOfLives, GameScene.maxLivesShown)
		guard shown > 0, !endlessMode else { refreshLivesRow(); return }
		for index in 0..<shown {
			rollInLife(at: index, delay: Double(index)*0.11)
		}
	}
	// Every ball rolls in at the start of a level. The leftmost sets off first and
	// travels furthest, so they arrive in order and appear to stack up against each
	// other rather than landing at random

	func rollInGainedLife() {
		livesAwaitingRollIn = false
		let shown = min(numberOfLives, GameScene.maxLivesShown)
		guard shown > 0, !endlessMode else { refreshLivesRow(); return }

		layoutLivesContainer()
		livesContainer.isHidden = false
		for index in 0..<max(0, shown-1) {
			let icon = lifeIcons[index]
			icon.removeAllActions()
			icon.isHidden = false
			icon.alpha = GameScene.lifeIconAlpha
			icon.setScale(1)
			icon.run(SKAction.move(to: livesRowHome(index: index), duration: 0.18))
		}
		for index in shown..<lifeIcons.count {
			lifeIcons[index].isHidden = true
		}
		rollInLife(at: shown-1, delay: 0)
	}
	// A gained life rolls into the free slot on the right. Past three the container grows,
	// which shifts the balls already there, so those slide across rather than jumping

	func rollInLife(at index: Int, delay: TimeInterval) {
		guard index < lifeIcons.count else { return }
		let icon = lifeIcons[index]
		let home = livesRowHome(index: index)

		icon.removeAllActions()
		icon.isHidden = false
		icon.alpha = GameScene.lifeIconAlpha
		icon.setScale(1)
		icon.zRotation = 0
		icon.position = CGPoint(x: home.x + ballSize*1.4, y: home.y)

		let arrive = SKAction.moveTo(x: home.x - ballSize*0.30, duration: 0.16)
		arrive.timingMode = .easeOut
		let rebound = SKAction.moveTo(x: home.x + ballSize*0.13, duration: 0.10)
		rebound.timingMode = .easeInEaseOut
		let settle = SKAction.moveTo(x: home.x, duration: 0.08)
		settle.timingMode = .easeOut
		// Rolls in a short way from the right, knocks against the ball ahead and rocks to
		// a stop. Enough to read as rolling without travelling across the screen

		let spin = SKAction.rotate(byAngle: -ballSize*1.7/(ballSize/2), duration: 0.34)
		spin.timingMode = .easeOut
		// Reads as rolling on themes whose ball texture has detail

		icon.run(SKAction.sequence([
			SKAction.wait(forDuration: delay),
			SKAction.group([SKAction.sequence([arrive, rebound, settle]), spin])
		]))
	}

	func flyLifeToPaddle() {
		let shown = min(numberOfLives, GameScene.maxLivesShown)
		guard shown > 0, shown <= lifeIcons.count else { return }

		let icon = lifeIcons[0]
		icon.removeAllActions()
		icon.isHidden = false

		let target = CGPoint(x: paddle.position.x, y: ballStartingPositionY)
		let flightTime: TimeInterval = 0.25
		let fly = SKAction.move(to: target, duration: flightTime)
		fly.timingMode = .easeIn
		let shrink = SKAction.scale(to: 0.6, duration: flightTime)
		let leadIn = SKAction.wait(forDuration: max(0, GameScene.ballReturnPause - flightTime))
		icon.run(SKAction.sequence([leadIn, .group([fly, shrink])])) {
			icon.isHidden = true
		}

		closeLivesRowGap(remaining: shown - 1)
	}
	// The life being spent travels to where the replacement ball appears, which is what
	// the ball animation is already doing at the same moment. It waits out most of the
	// ball's pause first so that it still lands exactly as the ball fades in, however long
	// that pause is. The lives count itself is decremented later, on the existing 0.75s
	// timing, so nothing about the game state moves.
	//
	// It is the leftmost ball that goes, not the rightmost - it is the one nearest the
	// paddle, so the gap it leaves closes in the direction of travel

	/// Slides the remaining lives left into the gap, and shrinks the container to match.
	///
	/// The container used to snap to its new size when the count dropped, three quarters
	/// of a second after the ball had already left. Both now move together, over the same
	/// window as the flight.
	func closeLivesRowGap(remaining: Int) {
		let fromSlots = CGFloat(livesSlots)
		let toSlots = CGFloat(max(3, min(remaining, GameScene.maxLivesShown)))
		let toWidth = livesContainerSize(forSlots: toSlots).width

		if fromSlots != toSlots {
			let duration = GameScene.livesGapCloseDuration
			livesContainer.run(SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
				guard let self else { return }
				let t = min(1, elapsed/CGFloat(duration))
				let eased = 1 - pow(1 - t, 3)
				let slots = fromSlots + (toSlots - fromSlots)*eased
				self.setLivesContainerPath(size: self.livesContainerSize(forSlots: slots))
			})
		}
		// Only when the container actually changes size - it never shrinks below three

		guard remaining > 0 else { return }
		for slot in 0..<remaining {
			let icon = lifeIcons[slot + 1]
			guard icon.isHidden == false else { continue }
			icon.removeAllActions()

			// Each ball starts a little after the one to its left, and overshoots by a
			// fraction of a ball before settling - so the row closes up as a series of
			// small knocks rather than as one block sliding.
			let home = livesRowHome(index: slot, containerWidth: toWidth)
			let overshoot = CGPoint(x: home.x - ballSize*0.12, y: home.y)
			let delay = SKAction.wait(forDuration: Double(slot)*GameScene.livesKnockStagger)
			let slide = SKAction.move(to: overshoot, duration: GameScene.livesGapCloseDuration*0.7)
			slide.timingMode = .easeIn
			let settle = SKAction.move(to: home, duration: GameScene.livesGapCloseDuration*0.3)
			settle.timingMode = .easeOut
			icon.run(SKAction.sequence([delay, slide, settle]))
		}
	}

	func computeLayoutMetrics() {
		let insets = self.view?.safeAreaInsets ?? .zero
		let hudUnits = gameMode == .endlessII ? GameScene.endlessIIHudUnits : GameScene.hudUnits
		let layout = GameSceneLayout(screen: frame.size,
									 bottomInset: insets.bottom,
									 sideInsets: insets.left + insets.right,
									 hudUnits: hudUnits)
		gameWidth = layout.gameWidth
		// Play area sized from the space actually available, holding a fixed ratio.
		//
		// The border is not decoration - the side blocks are the walls the ball bounces off,
		// and a wall of zero width has no physics body at all. This used to clamp to the
		// full available width, which was survivable only because the height-derived figure
		// never reached it; a shorter HUD bar reaches it immediately.
		// Clamped to width so short, wide layouts fall back to taller borders rather
		// than a reshaped playfield. Solved in closed form because the top bar height
		// depends on layoutUnit, which depends on gameWidth, which depends on it

		screenBlockSideWidth = layout.borderWidth

		numberOfBrickRows = GameSceneLayout.brickRows
		numberOfBrickColumns = GameSceneLayout.brickColumns
		layoutUnit = layout.layoutUnit
		brickWidth = layout.brickWidth
		brickHeight = layout.brickHeight
		paddleGap = layout.paddleGap

		pauseButtonSize = layoutUnit*2
		iconSize = layoutUnit*1.5
		fontSize = 16
		screenBlockTopHeight = layout.topBarHeight
		// The bar is the HUD and power-up tray, sitting below the real inset rather than
		// a fixed multiple guessed from screen height

		if isRegularWidth {
			pauseButtonSize = layoutUnit*1.5
			fontSize = fontSize*1.5
		}

		labelSpacing = fontSize/1.5
		minPaddleGap = brickHeight*4
	}
	// Every size-dependent value derived from the scene bounds. Pure maths, no node
	// changes, so it is safe to call again whenever the bounds or safe area change.

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
            setLivesRowHidden(true)
			endlessGameIcon.isHidden = true
			// Hide UI
		}
				
		gameViewControllerDelegate?.showPauseMenu(levelNumber: levelNumber, numberOfLevels: numberOfLevels, score: score, packNumber: packNumber, height: endlessHeight, sender: sender, gameoverBool: gameoverStatus, newItemsBool: newItemsBool, previousHighscore: previousHighscore, livesRemaining: numberOfLives)
		// Pass over highscore data to pause menu
		
		if firstPause && sender == "Pause" {
			gameViewControllerDelegate?.showWarning(senderID: "firstPause")
		}
		// Pop-up to explain swipe up to pause
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
		firstPause = defaults.bool(forKey: "firstPause")
		// User settings
		
		savedGame = SavedGame.load()
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
			guard node.endlessIIRole != .portal else { return }
			// A Portal cannot be what trapped the ball - it sends it to the top - so there
			// is nothing to gain by clearing it, and it is never destroyed by anything
			if temporarySprite.texture == self.brickIndestructible1Texture || temporarySprite.texture == self.brickIndestructible2Texture {
				temporarySprite.texture = self.brickNullTexture
				self.removeBrick(node: node, sprite: temporarySprite)
			}
		}
		brickBounceCounter = 0
	}

	func ballHorizontalControl(angleDegInput: Double, brickNode: SKNode? = nil,
							   for subject: SKSpriteNode) {
		let ball = subject
		let isExtra = subject !== self.ball
		let isOnPaddle = isExtra ? false : ballIsOnPaddle
		// The correction has to act on the ball that was actually in the contact. Shadowing
		// the property with a local is what lets a hundred lines of arithmetic below stay
		// exactly as they were and still be about the right ball

		if (gravityActivated && ball.position.y > paddle.position.y + ballSize*4) || isOnPaddle {
			return
		}
		// Do not run ball angle correction if gravity is activated and the ball is above the non-gravity area or ball is on the paddle
		
		if gameState.currentState is Playing {
			
			var xSpeed = ball.physicsBody!.velocity.dx
			var ySpeed = ball.physicsBody!.velocity.dy
			let currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
			var angleDeg = angleDegInput
			
			if brickNode != nil {
				if angleDeg == 0 || angleDeg == -0 {
				// Ball travelling horizontally right
					if brickNode!.position.y > ball.position.y {
					// Brick to above
						angleDeg = angleDeg - 1
					}
					if brickNode!.position.y < ball.position.y {
					// Brick to below
						angleDeg = angleDeg + 1
					}
				}
				if angleDeg == 180 || angleDeg == -180 {
				// Ball travelling horizontally left
					if brickNode!.position.y > ball.position.y {
					// Brick to above
						angleDeg = angleDeg + 1
					}
					if brickNode!.position.y < ball.position.y {
					// Brick to below
						angleDeg = angleDeg - 1
					}
				}
			} else if angleDeg == 180.0 || angleDeg == 0.0 || angleDeg == -180 || angleDeg == -0 {
				horizontalBallControlFlipper = !horizontalBallControlFlipper
				if horizontalBallControlFlipper {
					angleDeg = angleDeg + 1
				} else {
					angleDeg = angleDeg - 1
				}
			}
			// Correct horizontal ball
			if angleDeg > 180.0 {
				angleDeg = angleDeg-360
			} else if angleDeg < -180 {
				angleDeg = angleDeg+360
			}
			// Make sure the ball angle doesn't stray from 180 to -180 bounds

			let prob = Int.random(in: 1...10)
			if prob == 1 {
				let angleMag = Double.random(in: -5...5)
				angleDeg = angleDeg+angleMag
			}
			// Apply a random angle factor
					
			// Pushed off horizontal by a little more than the minimum, and by a different
			// little each time. Snapping to exactly the minimum is what let the ball settle
			// into a loop: rescued at exactly ten degrees, it bounces symmetrically and comes
			// back at exactly ten degrees, over and over. The escape has to not repeat
			let escape = minAngleDeg + Double.random(in: 0...GameScene.horizontalEscapeJitter)

			if angleDeg <= minAngleDeg && angleDeg > 0 {
				angleDeg = escape
			}
			// Up and right
			if angleDeg >= -minAngleDeg && angleDeg <= 0 {
				angleDeg = -escape
			}
			// Down and right
			if angleDeg <= 180+minAngleDeg && angleDeg >= 180-minAngleDeg {
				angleDeg = 180-escape
			}
			// Up and left
			if angleDeg >= -180-minAngleDeg && angleDeg <= -180+minAngleDeg {
				angleDeg = -180+escape
			}
			// Down and left
			
			let angleRad = (angleDeg*Double.pi/180)
			xSpeed = CGFloat(cos(angleRad)) * currentSpeed
			ySpeed = CGFloat(sin(angleRad)) * currentSpeed
			ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
			// Set the new angle of the ball
			
			ballSpeedControl()
		}
	}
	
	func ballVerticalControl(brickNode: SKNode? = nil, for subject: SKSpriteNode) {
		let ball = subject
		let isExtra = subject !== self.ball
		let isOnPaddle = isExtra ? false : ballIsOnPaddle

		if (gravityActivated && ball.position.y > paddle.position.y + ballSize*4) || isOnPaddle {
			return
		}
		// Do not run ball angle correction if gravity is activated and the ball is above the non-gravity area or the ball is on the paddle
				
		if gameState.currentState is Playing {
			
			var xSpeed = ball.physicsBody!.velocity.dx
			var ySpeed = ball.physicsBody!.velocity.dy
			let currentSpeed = sqrt(xSpeed*xSpeed + ySpeed*ySpeed)
			let angleDegInput = Double(atan2(ySpeed, xSpeed))/Double.pi*180
			var angleDeg = angleDegInput
			let verticalMinAngle = minAngleDeg/2
			
			if brickNode != nil {
				if angleDeg == 90 {
				// Ball travelling vertically up
					if brickNode!.position.x < ball.position.x {
					// Brick to the left
						angleDeg = angleDeg - 1
					}
					if brickNode!.position.x > ball.position.x {
					// Brick to the right
						angleDeg = angleDeg + 1
					}
				}
				if angleDeg == -90 {
				// Ball travelling vertically down
					if brickNode!.position.x < ball.position.x {
					// Brick to the left
						angleDeg = angleDeg + 1
					}
					if brickNode!.position.x > ball.position.x {
					// Brick to the right
						angleDeg = angleDeg - 1
					}
				}
			} else if angleDeg == 90.0 || angleDeg == -90.0 {
				verticalBallControlFlipper = !verticalBallControlFlipper
				if verticalBallControlFlipper {
					angleDeg = angleDeg + 1
				} else {
					angleDeg = angleDeg - 1
				}
			}
			// Correct vertical ball
			
			let prob = Int.random(in: 1...10)
			if prob == 1 {
				let angleMag = Double.random(in: -5...5)
				angleDeg = angleDeg+angleMag
			}
			// Apply a random angle factor
			
			// Vertical Control
			if ball.position.x >= 0 {
				// ball is on right side of screen
				if angleDeg > 90-verticalMinAngle && angleDeg <= 90 {
					angleDeg = 90-verticalMinAngle
				}
				// Travelling up and right
				if angleDeg <= 90+verticalMinAngle && angleDeg > 90 {
					angleDeg = 90+verticalMinAngle
				}
				// Travelling up and left
				if angleDeg >= -90 && angleDeg < -90+verticalMinAngle {
					angleDeg = -90+verticalMinAngle
				}
				// Travelling down and right
				if angleDeg < -90 && angleDeg >= -90-verticalMinAngle {
					angleDeg = -90-verticalMinAngle
				}
				// Travelling down and left
			} else {
				// ball is on left side of screen
				if angleDeg >= 90-verticalMinAngle && angleDeg < 90 {
					angleDeg = 90-verticalMinAngle
				}
				// Travelling up and right
				if angleDeg < 90+verticalMinAngle && angleDeg >= 90 {
					angleDeg = 90+verticalMinAngle
				}
				// Travelling up and left
				if angleDeg > -90 && angleDeg <= -90+verticalMinAngle {
					angleDeg = -90+verticalMinAngle
				}
				// Travelling down and right
				if angleDeg <= -90 && angleDeg > -90-verticalMinAngle {
					angleDeg = -90-verticalMinAngle
				}
				// Travelling down and left
			}
			
			let angleRad = (angleDeg*Double.pi/180)
			xSpeed = CGFloat(cos(angleRad)) * currentSpeed
			ySpeed = CGFloat(sin(angleRad)) * currentSpeed
			ball.physicsBody!.velocity = CGVector(dx: xSpeed, dy: ySpeed)
			// Set the new angle of the ball
			
			ballSpeedControl()
		}
	}
	
	func ballSpeedControl() {
		if !gravityActivated && gameState.currentState is Playing && ballIsOnPaddle == false {
			let xSpeed = ball.physicsBody!.velocity.dx
			let ySpeed = ball.physicsBody!.velocity.dy
			
			let currentDirectionDeg = Double(atan2(Double(ySpeed), Double(xSpeed)))/Double.pi*180
			let currentDirectionRad = (currentDirectionDeg*Double.pi/180)
			
			let setXSpeed = CGFloat(cos(currentDirectionRad)) * ballSpeedLimit
			let setYSpeed = CGFloat(sin(currentDirectionRad)) * ballSpeedLimit
						
			ball.physicsBody!.velocity = CGVector(dx: setXSpeed, dy: setYSpeed)
		}
	}
	// Set the new speed of the ball and ensure it stays within the boundary
	
	/// How much more than the minimum a ball gets when it is pushed off horizontal.
	///
	/// Small, and random, so no two escapes are the same. A fixed escape angle is a loop
	/// waiting to happen - the ball leaves at exactly the minimum, bounces symmetrically, and
	/// arrives back at exactly the minimum, which is how a ball ends up crossing the screen
	/// horizontally for a dozen bounces before something else knocks it out of it.
	static let horizontalEscapeJitter: Double = 6

	/// Catches a ball that has ended up travelling horizontally, wherever it came from.
	///
	/// The angle correction already refuses to leave a bounce near horizontal, and a ball still
	/// got there - which is the point. That correction only runs on bounces it is told about,
	/// and a ball can arrive at horizontal through a path that never calls it: a seam, a
	/// simultaneous pair of contacts, a power-up that sets a velocity directly. Rather than
	/// find every one of those, this asks the only question that matters, every frame, of the
	/// only thing that can answer it - the ball.
	///
	/// A horizontal ball never comes down, so it can never be lost and never be played. It is
	/// the one heading the game cannot allow.
	func breakHorizontalRuns() {
		for subject in endlessIIBallsInPlay {
			guard let body = subject.physicsBody else { continue }
			if subject === ball && ballIsOnPaddle { continue }

			let speed = hypot(body.velocity.dx, body.velocity.dy)
			guard speed > 1 else { continue }

			let floor = CGFloat(sin(minAngleDeg*Double.pi/180))*speed
			guard abs(body.velocity.dy) < floor else { continue }

			// Sent off at the minimum plus a little, and a different little each time, so two
			// balls in the same fix do not leave in lockstep and one ball cannot fall into a
			// repeating escape
			let escape = minAngleDeg + Double.random(in: 0...GameScene.horizontalEscapeJitter)
			let wanted = CGFloat(sin(escape*Double.pi/180))*speed
			let dy: CGFloat = body.velocity.dy < 0 ? -wanted
				: body.velocity.dy > 0 ? wanted
				: (Bool.random() ? wanted : -wanted)
			let dx = (max(0, speed*speed - dy*dy)).squareRoot()

			body.velocity = CGVector(dx: body.velocity.dx < 0 ? -dx : dx, dy: dy)
		}
	}

	/// A wall bounce, reflected off the approach rather than off whatever the engine left.
	///
	/// A ball travelling straight up is fine - it comes back down off the top and stays
	/// playable the whole way, so nothing here has any business giving it a sideways nudge.
	/// What was not fine was arriving at a side wall a few degrees off vertical and leaving at
	/// exactly vertical: the sideways part of the journey was lost at the bounce, so a shot
	/// aimed to come back across the field went straight up the wall instead.
	///
	/// The cause is the one §8.6 records. A contact is reported partway through resolving the
	/// step, so the velocity read there has already been through the engine's own bounce -
	/// and reflecting that a second time, then correcting the angle from the result, is two
	/// bounces' worth of arithmetic on one bounce. At a shallow angle the horizontal part is
	/// small enough to be lost in it. Taking the approach instead makes the reflection exact:
	/// the ball leaves at the angle it arrived at, mirrored, which is all a wall has ever had
	/// to do.
	func wallBounce(of incoming: CGVector, at x: CGFloat) -> CGVector {
		CGVector(dx: x > 0 ? -abs(incoming.dx) : abs(incoming.dx), dy: incoming.dy)
	}

	func frameBallControl(xSpeed: CGFloat, for subject: SKSpriteNode) {
		let ball = subject
		let isExtra = subject !== self.ball
		let isOnPaddle = isExtra ? false : ballIsOnPaddle

		if gameState.currentState is Playing && isOnPaddle == false {
			// The velocity the ball arrived with, where there is one. `xSpeed` is taken from
			// the contact, by which point the engine has already bounced it
			let incoming = ballStateBeforeStep[ObjectIdentifier(ball)]?.velocity
				?? CGVector(dx: -xSpeed, dy: ball.physicsBody!.velocity.dy)

			ball.physicsBody!.velocity = wallBounce(of: incoming, at: ball.position.x)
			// Ensure the ball bounces off the wall correctly]

			let angleDeg = Double(atan2(Double(ball.physicsBody!.velocity.dy), Double(ball.physicsBody!.velocity.dx)))/Double.pi*180
			ballHorizontalControl(angleDegInput: angleDeg, for: subject)
		}
	}
	
    @objc func laserGenerator() {
		
		if gameState.currentState is Playing {
        
			let laser = SKSpriteNode(imageNamed: "laserNormal")
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
					
					if laser.position.x < -gameWidth/2 {
						laser.position.x = -gameWidth/2 + laser.size.width
					}
					// Correct position of laser if outside of frame
				}
				// adjust laser position when using retro paddle
				
				laser.texture = laserNormalTexture
				laserSideLeft = false
				// Left position
			} else {
				laser.position = CGPoint(x: paddle.position.x + paddle.size.width/2  - laser.size.width, y: paddle.position.y + paddleLaser.size.height/2 + laser.size.height/2)
				
				if paddleTexture == retroPaddle {
					laser.position = CGPoint(x: paddleRetroLaserTexture.position.x + paddleRetroLaserTexture.size.width/2 - laser.size.width, y: paddleRetroLaserTexture.position.y + paddleRetroLaserTexture.size.height/2 + laser.size.height/2)
					
					if laser.position.x > gameWidth/2 {
						laser.position.x = gameWidth/2 - laser.size.width
					}
					// Correct position of laser if outside of frame
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
						achievement.showsCompletionBanner = true
						GKAchievement.report([achievement]) { (error) in
							Log.gameCenter.error("\(error?.localizedDescription ?? "Error reporting gigaLasers achievement", privacy: .public)")
						}
					}
				}
				// Giga-lasers achievement
			}
			// If giga-ball power up is activated, allow laser to pass through bricks
			
			addChild(laser)
			totalStatsArray[0].lasersFired+=1
			
			if soundsSetting {
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
		if endlessMoveInProgress == false && gameState.currentState is Playing && swipeUpPause {
			clearSavedGame()
			gameState.enter(Paused.self)
		}
	}
	
	func saveGameStats() {
		totalStatsArray[0].dateSaved = Date()
		do {
            let data = try encoder.encode(self.totalStatsArray)
            try data.write(to: totalStatsStore!)
        } catch {
            Log.data.error("Error encoding total stats, \(String(describing: error), privacy: .public)")
        }
		CloudKitHandler().saveToiCloud()
        // Save total stats
	}
	
	func saveCurrentGame() {
		guard isDailyChallenge == false else { return }
		// A daily run is never saved: resuming a twisted game into the campaign - or a
		// campaign save into a twisted game - would be the wrong game either way. A daily
		// interrupted is a daily abandoned, which phase 3's attempt rules will formalise

				
		if numberOfLives <= 0 && ballLostBool && ballIsOnPaddle == false {
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
		let currentDeathsPerLevel = deathsPerLevel
		let currentDeathsPerPack = deathsPerPack
		let currentpowerUpsGeneratedPerLevel = powerUpsGeneratedPerLevel
		let currentpowerUpsCollectedPerLevel = powerUpsCollectedPerLevel
		let currentpowerUpsGeneratedPerPack = powerUpsGeneratedPerPack
		let currentpowerUpsCollectedPerPack = powerUpsCollectedPerPack
		let currentpaddleHitsPerLevel = paddleHitsPerLevel
		

		if gameState.currentState is InbetweenLevels && gameoverStatus == false {
			if numberOfLevels > 1 {
				currentLevelNumber+=1
			} else {
				clearSavedGame()
				return
			}
		}
		// If inbetween levels but only playing 1 level at a time don't save
		
		_ = [currentLevelNumber, currentEndLevelNumber, currentPackNumber, currentLevelScore, currentTotalScore, currentNumberOfLives, currentHeight, currentNumberOfLevels, currentLevelTimerValue, currentPackTimerValue, currentDeathsPerLevel, currentDeathsPerPack, currentpowerUpsGeneratedPerLevel, currentpowerUpsCollectedPerLevel, currentpowerUpsGeneratedPerPack, currentpowerUpsCollectedPerPack, currentpaddleHitsPerLevel]
		
		var currentMultiplier = multiplier
		
		if lifeLossPending {
			currentNumberOfLives = max(0, currentNumberOfLives - 1)
		}
		// Only when a loss has been counted against the ball but not yet against the
		// count. ballLostBool is not that condition - see lifeLossPending
		
		if ballLostBool || gameState.currentState is InbetweenLevels {
			currentMultiplier = 1.0
		}
		// If ball is lost or inbetween levels or ads, reset the multiplier
		
		var brickTextureArray: [Int]? = []
		var brickColourArray: [Int]? = []
		var brickXPositionArray: [Int]? = []
		var brickYPositionArray: [Int]? = []
		var ballPropertiesArray: [Double]? = []
		var extraBallPropertiesArray: [Double] = []
		
		var laserXPositionArray: [Int] = []
		var laserYPositionArray: [Int] = []

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
				powerUpActiveMagnitudeArray?.append(laserStacks)
				// The laser's magnitude was unused, so it carries the fire-rate stacking
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
			if endlessIITrajectoryRemaining > 0 {
				powerUpActiveArray?.append("endlessIITrajectory")
				powerUpActiveDurationArray?.append(endlessIITrajectoryRemaining)
				powerUpActiveTimerArray?.append(endlessIITrajectoryTotal)
				powerUpActiveMagnitudeArray?.append(endlessIITrajectoryLevel)
				// The vision power-ups keep their own clocks rather than an SKAction, so
				// there is no bar to read the remaining time off - the clock is the truth
			}
			if endlessIILandingRemaining > 0 {
				powerUpActiveArray?.append("endlessIILanding")
				powerUpActiveDurationArray?.append(endlessIILandingRemaining)
				powerUpActiveTimerArray?.append(endlessIILandingTotal)
				powerUpActiveMagnitudeArray?.append(0)
			}
			for entry in endlessIIPaddleClockSaveEntries() + endlessIIFieldClockSaveEntries() {
				powerUpActiveArray?.append(entry.key)
				powerUpActiveDurationArray?.append(entry.remaining)
				powerUpActiveTimerArray?.append(entry.total)
				powerUpActiveMagnitudeArray?.append(entry.magnitude)
			}
			// The whole paddle batch, one entry per running clock - the key doubles as the
			// ring id, so there is no third list to keep in step
			
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

				extraBallPropertiesArray = EndlessIIBalls.flattened(
					endlessIIExtraBalls.filter { $0.parent != nil }.enumerated().map { index, extra in
						EndlessIIBalls.Saved(position: extra.position,
											 velocity: pauseExtraBallVelocities.indices.contains(index)
												? pauseExtraBallVelocities[index]
												: extra.physicsBody?.velocity ?? .zero)
					})
				// The velocity recorded at the pause where there is one, and the live one where
				// there is not - the game also saves itself on backgrounding, which does not go
				// through the pause menu
			}
			// Only save ball properties if ball is in play and not on paddle
			
			enumerateChildNodes(withName: LaserCategoryName) { (node, _) in
				laserXPositionArray.append(Int(node.position.x))
				laserYPositionArray.append(Int(node.position.y))
			}
			// Lasers still travelling up the screen

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
				
				currentPowerUpXIndex = round(currentPowerUpXIndex)
				currentPowerUpYIndex = round(currentPowerUpYIndex)
				// Round to the nearest integer
				
				powerUpFallingXPositionArray!.append(Int(currentPowerUpXIndex))
				powerUpFallingYPositionArray!.append(Int(currentPowerUpYIndex))
				powerUpFallingArray!.append(powerUpTextureIndex)
			}
		}
		// Save bricks, ball and power-ups if playing or paused

		let previous = savedGame
		// The arrays are only rebuilt while playing or paused. Saving from between levels
		// leaves them empty, and the original code left the stored values untouched in
		// that case, so the last snapshot survives. Preserved here by falling back to the
		// previous save field by field

		savedGame = SavedGame(
			levelNumber: currentLevelNumber,
			endLevelNumber: currentEndLevelNumber,
			packNumber: currentPackNumber,
			levelScore: currentLevelScore,
			totalScore: currentTotalScore,
			numberOfLives: currentNumberOfLives,
			endlessHeight: currentHeight,
			numberOfLevels: currentNumberOfLevels,
			levelTimerValue: currentLevelTimerValue,
			packTimerValue: currentPackTimerValue,
			deathsPerLevel: currentDeathsPerLevel,
			deathsPerPack: currentDeathsPerPack,
			powerUpsGeneratedPerLevel: currentpowerUpsGeneratedPerLevel,
			powerUpsCollectedPerLevel: currentpowerUpsCollectedPerLevel,
			powerUpsGeneratedPerPack: currentpowerUpsGeneratedPerPack,
			powerUpsCollectedPerPack: currentpowerUpsCollectedPerPack,
			paddleHitsPerLevel: currentpaddleHitsPerLevel,
			multiplier: currentMultiplier,
			brickTextures: brickXPositionArray != [] ? brickTextureArray! : previous?.brickTextures ?? [],
			brickColours: brickXPositionArray != [] ? brickColourArray! : previous?.brickColours ?? [],
			brickXPositions: brickXPositionArray != [] ? brickXPositionArray! : previous?.brickXPositions ?? [],
			brickYPositions: brickXPositionArray != [] ? brickYPositionArray! : previous?.brickYPositions ?? [],
			ballProperties: ballPropertiesArray != [] ? ballPropertiesArray! : previous?.ballProperties ?? [],
			extraBallProperties: ballPropertiesArray != [] ? extraBallPropertiesArray : previous?.extraBallProperties,
			// Written whenever the ball is - including empty, which is how a run that has just
			// lost its extras stops claiming to have them
			fallingPowerUpXPositions: powerUpFallingXPositionArray != [] ? powerUpFallingXPositionArray! : previous?.fallingPowerUpXPositions ?? [],
			fallingPowerUpYPositions: powerUpFallingXPositionArray != [] ? powerUpFallingYPositionArray! : previous?.fallingPowerUpYPositions ?? [],
			fallingPowerUps: powerUpFallingXPositionArray != [] ? powerUpFallingArray! : previous?.fallingPowerUps ?? [],
			activePowerUps: powerUpActiveArray != [] ? powerUpActiveArray! : previous?.activePowerUps ?? [],
			activePowerUpDurations: powerUpActiveArray != [] ? powerUpActiveDurationArray! : previous?.activePowerUpDurations ?? [],
			activePowerUpTimers: powerUpActiveArray != [] ? powerUpActiveTimerArray! : previous?.activePowerUpTimers ?? [],
			activePowerUpMagnitudes: powerUpActiveArray != [] ? powerUpActiveMagnitudeArray! : previous?.activePowerUpMagnitudes ?? [],
			laserXPositions: laserXPositionArray,
			laserYPositions: laserYPositionArray,
			stickyPaddleCatchesTotal: stickyPaddleCatches != 0 ? stickyPaddleCatchesTotal : previous?.stickyPaddleCatchesTotal
		)
		savedGame?.save()
		
		resumeGameToLoad = true
		defaults.set(resumeGameToLoad, forKey: "resumeGameToLoad")
	}
	
	func clearSavedGame() {
		userSettings()
		resumeGameToLoad = false
		defaults.set(resumeGameToLoad, forKey: "resumeGameToLoad")
		savedGame = nil
		SavedGame.clear()
	}
	
	/// Puts back the lasers that were still travelling up the screen when the game was
	/// saved.
	///
	/// They were simply dropped before - the save format had nowhere to put them. A laser
	/// crosses the screen height in two seconds, so each one resumes at that same speed
	/// and is removed when it leaves the top, rather than after a fixed two seconds from
	/// nowhere in particular.
	/// Restarts the laser timer at the current rate.
	///
	/// The rate depends on the ball-speed power-up, which can be collected while lasers
	/// are already firing - and a Timer's interval cannot be changed once it is
	/// scheduled, so it is replaced.
	/// What is running, read from the tray's own state.
	///
	/// A timed power-up shows its bar and scales it from one down to zero as it drains,
	/// which is already how the save format works out the time remaining. Reading the same
	/// thing here means no activation code has to be touched to add a second display -
	/// which is what keeps Classic and Endless out of this entirely.
	func activePowerUpEntries() -> [PowerUpRingHUD.Entry] {
		var entries: [PowerUpRingHUD.Entry] = []
		for index in 0..<iconArray.count {
			let bar = iconTimerArray[index]
			guard bar.isHidden == false, bar.xScale > 0.001 else { continue }

			// The sticky paddle counts catches rather than seconds, so its ring is
			// segmented - three marks say "three catches" where a smooth arc only says
			// "about half". Every other tray entry is timed.
			let segments = index == GameScene.stickyPaddleTrayIndex && stickyPaddleCatchesTotal > 0
				? stickyPaddleCatchesTotal
				: nil

			entries.append(PowerUpRingHUD.Entry(id: "tray\(index)",
											    texture: iconArray[index].texture ?? SKTexture(),
											    remaining: bar.xScale,
											    segments: segments))
		}
		entries.append(contentsOf: endlessIIVisionRingEntries())
		entries.append(contentsOf: endlessIIPaddleRingEntries())
		entries.append(contentsOf: endlessIIFieldRingEntries())
		// Endless 2.0's own power-ups have no tray slot to be read from, so they report
		// themselves
		return entries
	}

	/// Where the sticky paddle sits in the tray arrays.
	static let stickyPaddleTrayIndex = 3

	func refreshLaserFiringRate() {
		guard laserPowerUpIsOn, laserTimer != nil else { return }
		laserTimer?.invalidate()
		laserTimer = Timer.scheduledTimer(timeInterval: laserInterval, target: self,
										  selector: #selector(laserGenerator),
										  userInfo: nil, repeats: true)
	}

	/// Paints the playfield background from the setting.
	///
	/// Classic is the artwork on the scene's own background node. The other three are
	/// drawn onto a sprite created here instead, sitting just above it - assigning a new
	/// texture to the node the scene file owns does not take, though clearing it does,
	/// and a node we make ourselves avoids the question entirely.
	///
	/// What each background *is* lives in `GameBackground`, because the selection screen
	/// draws the same four in miniature and a picker that paints them differently from the
	/// game is worse than no picker at all.
	func applyBackgroundSetting() {
		let setting = GameBackground.stored(defaults.integer(forKey: "backgroundSetting"))

		let overlay = backgroundOverlay ?? {
			let node = SKSpriteNode()
			node.zPosition = 0.5
			node.anchorPoint = background.anchorPoint
			addChild(node)
			backgroundOverlay = node
			return node
		}()

		overlay.size = background.size
		overlay.position = background.position

		switch setting.paint {
		case .artwork:
			overlay.isHidden = true
		case .solid(let colour):
			overlay.isHidden = false
			overlay.texture = nil
			overlay.color = colour
			overlay.colorBlendFactor = 1
		case .gradient:
			overlay.isHidden = false
			overlay.colorBlendFactor = 0
			overlay.color = .clear
			overlay.texture = gradientBackgroundTexture(size: overlay.size)
		}
		background.isHidden = setting != .classic
	}

	/// The borders' purple at the top, the Classic background's purple by the paddle, then
	/// away to near black at the bottom of the playfield.
	func gradientBackgroundTexture(size: CGSize) -> SKTexture? {
		guard size.width > 0, size.height > 0 else { return nil }

		// Where the paddle sits within the background, measured from its bottom.
		let bottom = background.frame.minY
		let paddleFraction = (paddlePositionY - bottom)/size.height

		guard let image = GameBackground.gradientImage(size: size,
													   paddleFraction: paddleFraction) else {
			return nil
		}
		return SKTexture(image: image)
	}

	@objc func backgroundSettingChangedNotificationReceived(_ notification: Notification) {
		applyBackgroundSetting()
	}

	func restoreLasers(from savedGame: SavedGame) {
		guard let xs = savedGame.laserXPositions, let ys = savedGame.laserYPositions,
			  xs.count == ys.count, xs.isEmpty == false else { return }

		let pointsPerSecond = frame.height / 2

		for i in 0..<xs.count {
			let laser = SKSpriteNode(imageNamed: "laserNormal")
			laser.texture = laserNormalTexture
			laser.position = CGPoint(x: CGFloat(xs[i]), y: CGFloat(ys[i]))
			laser.zPosition = 2
			laser.name = LaserCategoryName

			laser.physicsBody = SKPhysicsBody(rectangleOf: laser.frame.size)
			laser.physicsBody!.allowsRotation = false
			laser.physicsBody!.friction = 0.0
			laser.physicsBody!.affectedByGravity = false
			laser.physicsBody!.isDynamic = true
			laser.physicsBody!.categoryBitMask = CollisionTypes.laserCategory.rawValue
			laser.physicsBody!.collisionBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue
			laser.physicsBody!.contactTestBitMask = CollisionTypes.brickCategory.rawValue | CollisionTypes.screenBlockCategory.rawValue

			if ball.texture == gigaBallTexture {
				laser.physicsBody!.collisionBitMask = 0
				laser.texture = laserGigaTexture
			}
			// Matches the generator: giga-lasers pass through bricks

			addChild(laser)

			let remaining = frame.maxY - laser.position.y + laser.size.height
			let move = SKAction.moveBy(x: 0, y: remaining, duration: Double(remaining / pointsPerSecond))
			laser.run(move, completion: {
				laser.removeFromParent()
			})
		}
	}

	func resumeGame() {
		guard let savedGame else { return }
		// Bound once, shadowing the property, rather than force-unwrapped at each of the
		// twenty-odd uses below. Nothing here is reachable without a save, but that was
		// implied by the guards rather than stated, and this path runs at launch
		if resumeGameToLoad {
			if savedGame.ballProperties.count >= SavedGame.ballPropertiesCount {
				// Read positionally up to index 4 below. isEmpty was not a strong enough
				// guard - a short array traps here, during resume, at launch.
				ballIsOnPaddle = false
				ballLostBool = false
				ball.position.x = CGFloat(savedGame.ballProperties[0])
				ball.position.y = CGFloat(savedGame.ballProperties[1])
				paddle.position.x = CGFloat(savedGame.ballProperties[4])
				endlessIIRestoreExtraBalls(from: EndlessIIBalls.unflattened(savedGame.extraBallProperties))
				// A run paused with a Multi-Ball in play comes back with it
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
				numberOfLevels = savedGame.numberOfLevels
				levelTimerValue = savedGame.levelTimerValue
				packTimerValue = savedGame.packTimerValue
				deathsPerLevel = savedGame.deathsPerLevel
				deathsPerPack = savedGame.deathsPerPack
				powerUpsGeneratedPerLevel = savedGame.powerUpsGeneratedPerLevel
				powerUpsCollectedPerLevel = savedGame.powerUpsCollectedPerLevel
				powerUpsGeneratedPerPack = savedGame.powerUpsGeneratedPerPack
				powerUpsCollectedPerPack = savedGame.powerUpsCollectedPerPack
				paddleHitsPerLevel = savedGame.paddleHitsPerLevel
				levelTimerBonus = 500
			} else {
				saveCurrentGame()
			}
			// Load ball position and velocity if it has been saved
			
			if (savedGame.fallingPowerUps.isEmpty == false) {
				for i in 0..<savedGame.fallingPowerUps.count {
					
					let powerUpPositionX = savedGame.fallingPowerUpXPositions[i]
					let powerUpPositionY = savedGame.fallingPowerUpYPositions[i]

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
					
					powerUp.texture = powerUpTextureArray[savedGame.fallingPowerUps[i]]
					let move = SKAction.moveBy(x: 0, y: -frame.height, duration: 5)
					powerUp.run(move, withKey: "PowerUpDrop")
					powerUpsOnScreen+=1
				}
			// Load power-up position and texture if it has been saved
			}
			
			if (savedGame.activePowerUps.isEmpty == false) {
				for i in 0..<savedGame.activePowerUps.count {
					
					let remainingTime: Double = savedGame.activePowerUpDurations[i]
					let totalTime: Double = savedGame.activePowerUpTimers[i]
					let scale: CGFloat = CGFloat(remainingTime/totalTime)
					
					switch savedGame.activePowerUps[i] {
					case "ballSpeedTimer":
						switch savedGame.activePowerUpMagnitudes[i] {
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
						ballSpeedControl()
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.ballSpeedLimit = self.ballSpeedNominal
							self.ballSpeedControl()
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
						// The retro paddle art is a wider asset than the default one, so
						// playing normally scales it by its own factor - 1.5 on the paddle
						// is 1.42 on the retro texture. Resume used to apply the paddle's
						// scale to both, leaving the retro paddle wider than it should be
						// for every size except 1.0.
						var setScale: CGFloat?
						var retroScale: CGFloat?
						switch savedGame.activePowerUpMagnitudes[i] {
						case 0:
							setScale = 0.5
							retroScale = 0.59
							paddleSizeIcon.texture = self.iconDecreasePaddleSizeTexture
						case 1:
							setScale = 0.75
							retroScale = 0.79
							paddleSizeIcon.texture = self.iconDecreasePaddleSizeTexture
						case 2:
							setScale = 1.5
							retroScale = 1.42
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						case 3:
							setScale = 2.0
							retroScale = 1.82
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						case 4:
							setScale = 2.5
							retroScale = 2.24
							paddleSizeIcon.texture = self.iconIncreasePaddleSizeTexture
						default:
							break
						}
						guard let setScale, let retroScale else { break }
						paddleCenterRectPlus()
						paddle.run(SKAction.scaleX(to: setScale, duration: 0.0))
						paddle.physicsBody!.collisionBitMask = CollisionTypes.paddleCategory.rawValue | CollisionTypes.boarderCategory.rawValue
						paddleLaser.run(SKAction.scaleX(to: setScale, duration: 0.0))
						paddleSticky.run(SKAction.scaleX(to: setScale, duration: 0.0))
						paddleRetroTexture.run(SKAction.scaleX(to: retroScale, duration: 0.0))
						paddleRetroLaserTexture.run(SKAction.scaleX(to: retroScale, duration: 0.0))
						paddleRetroStickyTexture.run(SKAction.scaleX(to: retroScale, duration: 0.0))
						
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.paddleCenterRectPlus()
							if self.hapticsSetting {
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
						switch savedGame.activePowerUpMagnitudes[i] {
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
						laserStacks = min(savedGame.activePowerUpMagnitudes[i], GameScene.laserMaxStacks)
						paddleLaser.isHidden = false
						if paddleTexture == retroPaddle {
							paddleRetroLaserTexture.isHidden = false
							paddleRetroTexture.isHidden = true
							paddleLaser.isHidden = true
						}
						laserTimer = Timer.scheduledTimer(timeInterval: laserInterval, target: self, selector: #selector(laserGenerator), userInfo: nil, repeats: true)
						powerUpLimit = 4
						let waitDuration = SKAction.wait(forDuration: remainingTime)
						let completionBlock = SKAction.run {
							self.laserTimer?.invalidate()
							self.laserStacks = 0
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
						switch savedGame.activePowerUpMagnitudes[i] {
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
							if self.hapticsSetting {
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
						stickyPaddleCatches = savedGame.activePowerUpMagnitudes[i]
						stickyPaddleCatchesTotal = savedGame.stickyPaddleCatchesTotal ?? stickyPaddleCatches
						// Both are Int, so CGFloat(a/b) truncated to zero for every state
						// except a full bar - which is why the bar came back empty
						let scale: CGFloat = stickyPaddleCatchesTotal > 0
							? CGFloat(stickyPaddleCatches) / CGFloat(stickyPaddleCatchesTotal)
							: 0
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

					case "endlessIITrajectory":
						endlessIITrajectoryRemaining = remainingTime
						endlessIITrajectoryTotal = totalTime
						endlessIITrajectoryLevel = min(max(0, savedGame.activePowerUpMagnitudes[i]),
													   GameScene.endlessIITrajectoryReach.count - 1)
						// Clamped: the magnitude is a file on disk, and an index into the
						// reach table read at launch must not be able to trap

					case "endlessIILanding":
						endlessIILandingRemaining = remainingTime
						endlessIILandingTotal = totalTime

					default:
						if endlessIIRestorePaddleClock(key: savedGame.activePowerUps[i],
													   remaining: remainingTime,
													   total: totalTime,
													   magnitude: savedGame.activePowerUpMagnitudes[i]) == false {
							endlessIIRestoreFieldClock(key: savedGame.activePowerUps[i],
													   remaining: remainingTime,
													   total: totalTime,
													   magnitude: savedGame.activePowerUpMagnitudes[i])
						}
					}
				}
			}
			// Load active power-ups if any saved

			restoreLasers(from: savedGame)
			// After the active power-ups, so the giga-ball state they set is known

			resumeGameToLoad = false
			defaults.set(resumeGameToLoad, forKey: "resumeGameToLoad")
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
							if self.hapticsSetting {
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
        endlessIIRecordExtraBallVelocities()
        // Before they are zeroed below, and only where they have not been recorded already -
        // this runs on the way into the pause menu and again on the way out of it

        enumerateChildNodes(withName: BallCategoryName) { (node, _) in
            node.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            node.isPaused = true
        }
        // Each ball's own body. This zeroed the first ball's velocity once per ball in play
        // and left the others travelling, so an extra ball carried on through the resume
        // countdown while the one being counted in stood still
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
		iconTimerArray.forEach { $0.isPaused = true }
		// The power-up timers too. They are not under any of the names above, so they were
		// the one thing still running during the resume countdown - a player watching three
		// two one was watching their power-ups drain at the same time
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

            endlessIIShowExtraDirectionMarkers()
            // Every ball gets one, after the first ball's texture has been chosen - the extras
            // wear the same one. A countdown that points at one of four balls says nothing
            // about where the other three are going
        }
    }
    // Pause all nodes
	
	func playFromPause() {
		
		clearSavedGame()
		countdownStarted = false
		iconTimerArray.forEach { $0.isPaused = false }
		// Started again at the moment play does, not at the moment the countdown does
		pauseButton.texture = pauseTexture
		pauseButton.size.width = pauseButtonSize
        pauseButton.size.height = pauseButtonSize
		directionMarker.isHidden = true
		endlessIIHideExtraDirectionMarkers()
		isPaused = false
				
		if ballIsOnPaddle == false && pauseBallVelocityX == 0 && pauseBallVelocityY == 0 {
			let randomLaunchDirection = Bool.random()
            if randomLaunchDirection {
                ballLaunchAngleRad = straightLaunchAngleRad + minLaunchAngleRad
            } else {
                ballLaunchAngleRad = straightLaunchAngleRad - minLaunchAngleRad
            }
			pauseBallVelocityX = cos(CGFloat(ballLaunchAngleRad)) * ballSpeedLimit
			pauseBallVelocityY = sin(CGFloat(ballLaunchAngleRad)) * ballSpeedLimit
		}
		
		enumerateChildNodes(withName: PaddleCategoryName) { (node, _) in
			node.isPaused = false
		}
		enumerateChildNodes(withName: BallCategoryName) { (node, _) in
			if let index = self.endlessIIExtraBalls.firstIndex(where: { $0 === node }) {
				// Each extra keeps its own heading. The line below sets the first ball's
				// velocity whichever node it is looking at, so without this every ball in play
				// was given the first one's - four balls travelling as one
				if self.pauseExtraBallVelocities.indices.contains(index) {
					node.physicsBody?.velocity = self.pauseExtraBallVelocities[index]
				}
			} else {
				self.ball.physicsBody!.velocity = CGVector(dx: self.pauseBallVelocityX, dy: self.pauseBallVelocityY)
			}
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
			numberOfLives+=1
			ballLost()
		}
		killBall = false
		
		if endlessMode {
			countBricks()
		}
	}
		
	@objc func refreshViewForSyncNotificationKeyReceived(notification:Notification) {
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
