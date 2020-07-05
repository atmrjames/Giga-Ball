//
//  LevelPackSetup.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import UIKit
import GameplayKit
import GameKit

// This is always constant and never changes throughout use of app - can be referred to directly

class LevelPackSetup {
    let numberOfLevels: [Int] = [1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10]
    let startLevelNumber: [Int] = [0, 0, 1, 11, 21, 31, 41, 51, 61, 71, 81, 91, 101]
    
    let levelPackNameArray: [String] = [
        "Tutorial",
        "Endless Mode",
        "Classic Pack",
        "Space Pack",
        "Nature Pack",
        "Urban Pack",
        "Food Pack",
        "Computer Pack",
        "Body Pack",
        "World Pack",
        "Emoji Pack",
        "Numbers Pack",
        "Challenge Pack"
    ]
    
    let ballImageArray: [UIImage] = [
        UIImage(named:"ballNormal.png")!,
        UIImage(named:"3DBall.png")!,
        UIImage(named:"outlineBall.png")!,
        UIImage(named:"diamondBall.png")!,
        UIImage(named:"beachBall.png")!,
        UIImage(named:"concentricBall.png")!,
        UIImage(named:"pixelBall.png")!,
        UIImage(named:"dotBall.png")!,
        UIImage(named:"hobBall.png")!,
        UIImage(named:"reuleauxBall.png")!,
        UIImage(named:"loadingBall.png")!,
        UIImage(named:"retroBall.png")!
    ]
    
    let ballNameArray: [String] = [
        "Classic",
        "3D",
        "Outline",
        "Diamond",
        "Beach Ball",
        "Concentric",
        "Pixel",
        "Dots",
        "Spokes",
        "Reuleaux",
        "Rainbow",
        "Retro"
    ]
    
    let ballIconArray: [UIImage] = [
        UIImage(named:"ballIcon.png")!,
        UIImage(named:"3DBallIcon.png")!,
        UIImage(named:"outlineBallIcon.png")!,
        UIImage(named:"diamondBallIcon.png")!,
        UIImage(named:"beachBallIcon.png")!,
        UIImage(named:"concentricBallIcon.png")!,
        UIImage(named:"pixelBallIcon.png")!,
        UIImage(named:"dotBallIcon.png")!,
        UIImage(named:"hobBallIcon.png")!,
        UIImage(named:"reuleauxBallIcon.png")!,
        UIImage(named:"loadingBallIcon.png")!,
        UIImage(named:"retroBallIcon.png")!
    ]
    
    let paddleImageArray: [UIImage] = [
        UIImage(named:"regularPaddle.png")!,
        UIImage(named:"3DPaddle.png")!,
        UIImage(named:"outlinePaddle.png")!,
        UIImage(named:"squarePaddle.png")!,
        UIImage(named:"icePaddle.png")!,
        UIImage(named:"glassPaddle.png")!,
        UIImage(named:"pixelPaddle.png")!,
        UIImage(named:"gigaPaddle.png")!,
        UIImage(named:"stripyPaddle.png")!,
        UIImage(named:"splitPaddle.png")!,
        UIImage(named:"rainbowPaddle.png")!,
        UIImage(named:"retroPaddle.png")!
    ]
    
    let paddleNameArray: [String] = [
        "Classic",
        "3D",
        "Outline",
        "Square",
        "Ice",
        "Glass",
        "Pixel",
        "Giga-Paddle",
        "Candy Cane",
        "Split",
        "Rainbow",
        "Retro"
    ]
    
    let paddleIconArray: [UIImage] = [
        UIImage(named:"regularPaddleIcon.png")!,
        UIImage(named:"3DPaddleIcon.png")!,
        UIImage(named:"outlinePaddleIcon.png")!,
        UIImage(named:"squarePaddleIcon.png")!,
        UIImage(named:"icePaddleIcon.png")!,
        UIImage(named:"glassPaddleIcon.png")!,
        UIImage(named:"pixelPaddleIcon.png")!,
        UIImage(named:"gigaPaddleIcon.png")!,
        UIImage(named:"stripyPaddleIcon.png")!,
        UIImage(named:"splitPaddleIcon.png")!,
        UIImage(named:"rainbowPaddleIcon.png")!,
        UIImage(named:"retroPaddleIcon.png")!
    ]
    
    let appIconImageArray: [UIImage] = [
        UIImage(named:"Purple.png")!,
        UIImage(named:"White.png")!,
        UIImage(named:"Yellow.png")!,
        UIImage(named:"Orange.png")!,
        UIImage(named:"Green.png")!,
        UIImage(named:"Blue.png")!,
        UIImage(named:"Brown.png")!,
        UIImage(named:"Black.png")!,
        UIImage(named:"Pink.png")!,
        UIImage(named:"GigaBall.png")!,
        UIImage(named:"Rainbow.png")!,
        UIImage(named:"Retro.png")!
    ]
    
    let appIconNameArray: [String] = [
        "Purple",
        "White",
        "Yellow",
        "Orange",
        "Green",
        "Blue",
        "Brown",
        "Black",
        "Pink",
        "Giga-Ball",
        "Rainbow",
        "Retro"        
    ]
    
    let brickImageArray: [UIImage] = [
        UIImage(named:"BrickNormal.png")!,
        UIImage(named:"retroBrickNormal.png")!
    ]
    
    let brickNameArray: [String] = [
        "Classic",
        "Retro"
    ]
    
    let brickIconArray: [UIImage] = [
        UIImage(named:"classicBrickIcon.png")!,
        UIImage(named:"retroBrickIcon.png")!
    ]
    
    let levelImageArray: [UIImage] = [
        UIImage(named:"Level999Image.png")!,
        UIImage(named:"Level01Image.png")!,
        UIImage(named: "Level02Image.png")!,
        UIImage(named: "Level03Image.png")!,
        UIImage(named: "Level04Image.png")!,
        UIImage(named: "Level05Image.png")!,
        UIImage(named: "Level06Image.png")!,
        UIImage(named: "Level07Image.png")!,
        UIImage(named: "Level08Image.png")!,
        UIImage(named: "Level09Image.png")!,
        UIImage(named: "Level10Image.png")!,
        UIImage(named: "Level11Image.png")!,
        UIImage(named: "Level12Image.png")!,
        UIImage(named: "Level13Image.png")!,
        UIImage(named: "Level14Image.png")!,
        UIImage(named: "Level15Image.png")!,
        UIImage(named: "Level16Image.png")!,
        UIImage(named: "Level17Image.png")!,
        UIImage(named: "Level18Image.png")!,
        UIImage(named: "Level19Image.png")!,
        UIImage(named: "Level20Image.png")!,
        UIImage(named: "Level21Image.png")!,
        UIImage(named: "Level22Image.png")!,
        UIImage(named: "Level23Image.png")!,
        UIImage(named: "Level24Image.png")!,
        UIImage(named: "Level25Image.png")!,
        UIImage(named: "Level26Image.png")!,
        UIImage(named: "Level27Image.png")!,
        UIImage(named: "Level28Image.png")!,
        UIImage(named: "Level29Image.png")!,
        UIImage(named: "Level30Image.png")!,
        UIImage(named: "Level31Image.png")!,
        UIImage(named: "Level32Image.png")!,
        UIImage(named: "Level33Image.png")!,
        UIImage(named: "Level34Image.png")!,
        UIImage(named: "Level35Image.png")!,
        UIImage(named: "Level36Image.png")!,
        UIImage(named: "Level37Image.png")!,
        UIImage(named: "Level38Image.png")!,
        UIImage(named: "Level39Image.png")!,
        UIImage(named: "Level40Image.png")!,
        UIImage(named: "Level41Image.png")!,
        UIImage(named: "Level42Image.png")!,
        UIImage(named: "Level43Image.png")!,
        UIImage(named: "Level44Image.png")!,
        UIImage(named: "Level45Image.png")!,
        UIImage(named: "Level46Image.png")!,
        UIImage(named: "Level47Image.png")!,
        UIImage(named: "Level48Image.png")!,
        UIImage(named: "Level49Image.png")!,
        UIImage(named: "Level50Image.png")!,
        UIImage(named: "Level51Image.png")!,
        UIImage(named: "Level52Image.png")!,
        UIImage(named: "Level53Image.png")!,
        UIImage(named: "Level54Image.png")!,
        UIImage(named: "Level55Image.png")!,
        UIImage(named: "Level56Image.png")!,
        UIImage(named: "Level57Image.png")!,
        UIImage(named: "Level58Image.png")!,
        UIImage(named: "Level59Image.png")!,
        UIImage(named: "Level60Image.png")!,
        UIImage(named: "Level61Image.png")!,
        UIImage(named: "Level62Image.png")!,
        UIImage(named: "Level63Image.png")!,
        UIImage(named: "Level64Image.png")!,
        UIImage(named: "Level65Image.png")!,
        UIImage(named: "Level66Image.png")!,
        UIImage(named: "Level67Image.png")!,
        UIImage(named: "Level68Image.png")!,
        UIImage(named: "Level69Image.png")!,
        UIImage(named: "Level70Image.png")!,
        UIImage(named: "Level71Image.png")!,
        UIImage(named: "Level72Image.png")!,
        UIImage(named: "Level73Image.png")!,
        UIImage(named: "Level74Image.png")!,
        UIImage(named: "Level75Image.png")!,
        UIImage(named: "Level76Image.png")!,
        UIImage(named: "Level77Image.png")!,
        UIImage(named: "Level78Image.png")!,
        UIImage(named: "Level79Image.png")!,
        UIImage(named: "Level80Image.png")!,
        UIImage(named: "Level81Image.png")!,
        UIImage(named: "Level82Image.png")!,
        UIImage(named: "Level83Image.png")!,
        UIImage(named: "Level84Image.png")!,
        UIImage(named: "Level85Image.png")!,
        UIImage(named: "Level86Image.png")!,
        UIImage(named: "Level87Image.png")!,
        UIImage(named: "Level88Image.png")!,
        UIImage(named: "Level89Image.png")!,
        UIImage(named: "Level90Image.png")!,
        UIImage(named: "Level91Image.png")!,
        UIImage(named: "Level92Image.png")!,
        UIImage(named: "Level93Image.png")!,
        UIImage(named: "Level94Image.png")!,
        UIImage(named: "Level95Image.png")!,
        UIImage(named: "Level96Image.png")!,
        UIImage(named: "Level97Image.png")!,
        UIImage(named: "Level98Image.png")!,
        UIImage(named: "Level99Image.png")!,
        UIImage(named: "Level100Image.png")!,
        UIImage(named: "Level101Image.png")!,
        UIImage(named: "Level102Image.png")!,
        UIImage(named: "Level103Image.png")!,
        UIImage(named: "Level104Image.png")!,
        UIImage(named: "Level105Image.png")!,
        UIImage(named: "Level106Image.png")!,
        UIImage(named: "Level107Image.png")!,
        UIImage(named: "Level108Image.png")!,
        UIImage(named: "Level109Image.png")!,
        UIImage(named: "Level110Image.png")!
    ]
    let levelNameArray: [String] = [
        "Endless Mode",
        
        // Classic Pack
        "Checkers",
        "Electric Fence",
        "Gateway",
        "Surfer's Paradise",
        "Chevron",
        "Vignette",
        "Cluster",
        "Vertical Challenge",
        "Horizontal Challenge",
        "X Marks The Spot",
        
        // Space Pack
        "Cresent Moon",
        "Invader",
        "Constellation",
        "Star",
        "Rocket",
        "Galaxy",
        "Meteor Shower",
        "Neptune",
        "Saturn",
        "Meteorite",
        
        // Nature Pack
        "Leaf",
        "Rainbow",
        "Egg",
        "Tree",
        "Sunset",
        "Apple",
        "Flower",
        "Birds",
        "Germ",
        "Butterfly",
        
        // Urban Pack
        "City Map",
        "Skyscraper",
        "Subway",
        "Cottage",
        "Traffic Light",
        "Finance",
        "Apartments",
        "City Hall",
        "Bridge",
        "Cityscape Reflection",
        
        // Food Pack
        "Hotdog",
        "Piece of Cake",
        "Wine Glass",
        "Fried Egg",
        "BBQ",
        "Kebabs",
        "Ice Cream",
        "Burger",
        "Pudding",
        "Chocolate Bar",
        
        // Computer Pack
        "Command",
        "Save",
        "@",
        "Mail",
        "Watch",
        "Trash",
        "Bug",
        "Zoom",
        "Battery",
        "Hour Glass",
        
        // Body Pack
        "Heart",
        "Brain",
        "Skull",
        "Intestine",
        "Lips",
        "Eye",
        "Kidney",
        "Tooth",
        "Lungs",
        "Face",
        
        // World Pack
        "Globe",
        "Pyramid",
        "Union Jack",
        "Compass",
        "Mountain",
        "Africa",
        "Island",
        "Partly Cloudy",
        "Maple Leaf",
        "Volcano",
        
        // Emoji Pack
        "Smiling Face",
        "Eyes",
        "Fire",
        "Weird Fish",
        "Winking Face",
        "Peach",
        "Ghost",
        "Augerbene / Eggplant",
        "Crying Face",
        "Poo",
        
        // Numbers Pack
        "One",
        "Two",
        "Three",
        "Four",
        "Five",
        "Six",
        "Seven",
        "Eight",
        "Nine",
        "Zero",
        
        // Challenge Pack
        "Lonesome Brick",
        "Kerplunk",
        "Gradient",
        "Restriction",
        "Barricade",
        "Minefield",
        "Split Screen",
        "Pimple",
        "Ringfence",
        "Finish Line"
    ]
    
    let levelLeaderboardsArray: [String] = [
        
        // Endless Mode
        "leaderboardBestHeight",
    
        // Classic Pack
        "leaderboardLevel01Score",
        "leaderboardLevel02Score",
        "leaderboardLevel03Score",
        "leaderboardLevel04Score",
        "leaderboardLevel05Score",
        "leaderboardLevel06Score",
        "leaderboardLevel07Score",
        "leaderboardLevel08Score",
        "leaderboardLevel09Score",
        "leaderboardLevel10Score",
        
        // Space Pack
        "leaderboardLevel11Score",
        "leaderboardLevel12Score",
        "leaderboardLevel13Score",
        "leaderboardLevel14Score",
        "leaderboardLevel15Score",
        "leaderboardLevel16Score",
        "leaderboardLevel17Score",
        "leaderboardLevel18Score",
        "leaderboardLevel19Score",
        "leaderboardLevel20Score",
        
        // Nature Pack
        "leaderboardLevel21Score",
        "leaderboardLevel22Score",
        "leaderboardLevel23Score",
        "leaderboardLevel24Score",
        "leaderboardLevel25Score",
        "leaderboardLevel26Score",
        "leaderboardLevel27Score",
        "leaderboardLevel28Score",
        "leaderboardLevel29Score",
        "leaderboardLevel30Score",
        
        // Urban Pack
        "leaderboardLevel31Score",
        "leaderboardLevel32Score",
        "leaderboardLevel33Score",
        "leaderboardLevel34Score",
        "leaderboardLevel35Score",
        "leaderboardLevel36Score",
        "leaderboardLevel37Score",
        "leaderboardLevel38Score",
        "leaderboardLevel39Score",
        "leaderboardLevel40Score",
        
        // Food Pack
        "leaderboardLevel41Score",
        "leaderboardLevel42Score",
        "leaderboardLevel43Score",
        "leaderboardLevel44Score",
        "leaderboardLevel45Score",
        "leaderboardLevel46Score",
        "leaderboardLevel47Score",
        "leaderboardLevel48Score",
        "leaderboardLevel49Score",
        "leaderboardLevel50Score",
        
        // Computer Pack
        "leaderboardLevel51Score",
        "leaderboardLevel52Score",
        "leaderboardLevel53Score",
        "leaderboardLevel54Score",
        "leaderboardLevel55Score",
        "leaderboardLevel56Score",
        "leaderboardLevel57Score",
        "leaderboardLevel58Score",
        "leaderboardLevel59Score",
        "leaderboardLevel60Score"
    ]
    
    let powerUpImageArray: [UIImage] = [
        UIImage(named:"PowerUpGetALife.png")!,
        UIImage(named:"PowerUpLoseALife.png")!,
        UIImage(named:"PowerUpReduceBallSpeed.png")!,
        UIImage(named:"PowerUpIncreaseBallSpeed.png")!,
        UIImage(named:"PowerUpIncreasePaddleSize.png")!,
        UIImage(named:"PowerUpDecreasePaddleSize.png")!,
        UIImage(named:"PowerUpStickyPaddle.png")!,
        UIImage(named:"PowerUpGravityBall.png")!,
        UIImage(named:"PowerUpPointsBonusSmall.png")!,
        UIImage(named:"PowerUpPointsPenaltySmall.png")!,
        UIImage(named:"PowerUpPointsBonus.png")!,
        UIImage(named:"PowerUpPointsPenalty.png")!,
        UIImage(named:"PowerUpMultiplier.png")!,
        UIImage(named:"PowerUpMultiplierReset.png")!,
        UIImage(named:"PowerUpNextLevel.png")!,
        UIImage(named:"PowerUpShowInvisibleBricks.png")!,
        UIImage(named:"PowerUpNormalToInvisibleBricks.png")!,
        UIImage(named:"PowerUpMultiHitToNormalBricks.png")!,
        UIImage(named:"PowerUpMultiHitBricksReset.png")!,
        UIImage(named:"PowerUpRemoveIndestructibleBricks.png")!,
        UIImage(named:"PowerUpGigaBall.png")!,
        UIImage(named:"PowerUpUndestructiBall.png")!,
        UIImage(named:"PowerUpLasers.png")!,
        UIImage(named:"PowerUpBricksDown.png")!,
        UIImage(named:"PowerUpMystery.png")!,
        UIImage(named:"PowerUpBackstop.png")!,
        UIImage(named:"PowerUpIncreaseBallSize.png")!,
        UIImage(named:"PowerUpDecreaseBallSize.png")!
    ]
    
    let powerUpNameArray: [String] = [
        "Get A Life",
        "Lose A Life",
        "Decrease Ball Speed",
        "Increase Ball Speed",
        "Increase Paddle Size",
        "Decrease Paddle Size",
        "Sticky Paddle",
        "Gravity",
        "+100 Points",
        "-100 Points",
        "+1000 Points",
        "-1000 Points",
        "x2 Multiplier",
        "Reset Multiplier",
        "Next Level",
        "Show All Bricks",
        "Hide Bricks",
        "Clear Multi-Hit Bricks",
        "Reset Multi-Hit Bricks",
        "Remove Indestructible Bricks",
        "Giga-Ball",
        "Undestructi-Ball",
        "Lasers",
        "Quicksand",
        "Mystery",
        "Backstop",
        "Increase Ball Size",
        "Decrease Ball Size"
    ]
    
    let powerUpDescriptionArray: [String] = [
        "Gives you an extra life",
        "Kills the ball in play",
        "Slows the ball down",
        "Speeds the ball up",
        "Makes the paddle wider",
        "Makes the paddle shorter",
        "Retains the ball on the paddle",
        "Makes the ball suseptible to gravity",
        "Adds 100 points to your score",
        "Takes 100 points away from your score",
        "Adds 1000 points to your score",
        "Takes 1000 points away from your score",
        "Sets the multiplier to the maximum of x2",
        "Sets the multiplier to the minimum of x1",
        "Completes the level",
        "Shows all bricks that are currently invisible",
        "Hides all visible bricks",
        "Sets multi-hit bricks to single hit bricks",
        "Resets all multi-hit bricks to their maximum hit setting",
        "Removes all indestructible bricks",
        "Allows the ball to pass uninterrupted through all brick types",
        "Prevents the ball from removing bricks",
        "Lasers fire from either side of the paddle",
        "Moves the bricks down towards the paddle",
        "Randomly generates a mystery power-up when collected",
        "Adds a backstop below the paddle to save a missed ball",
        "Increases the size of the ball",
        "Decreases the size of the ball"
    ]
    
    let powerUpMultiplierArray: [String] = [
        "+0.1x",
        "",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "2.0x",
        "1.0x",
        "",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "+0.1x",
        "-0.1x",
        "+0.1x",
        "-0.1x",
        "",
        "+0.1x",
        "+0.1x",
        "-0.1x"
    ]
    
    let powerUpTimerArray: [String] = [
        "",
        "",
        "10",
        "10",
        "10",
        "10",
        "5",
        "10",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        "10",
        "",
        "",
        "",
        "10",
        "10",
        "10",
        "",
        "",
        "10",
        "10",
        "10"
    ]
    
    let achievementsNameArray: [String] = [
        "Endless Mode 10m Milestone", // 0 achievementEndlessTen
        "Endless Mode 100m Milestone", // 1 achievementEndlessHundred
        "Endless Mode 500m Milestone", // 2 achievementEndlessFiveHundred
        "Endless Mode 1,000m Milestone", // 3 achievementEndlessOneK
        "Endless Mode 5,000m Total Height", // 4 achievementEndlessFiveK
        "Endless Mode 10,000m Total Height", // 5 achievementEndlessTenK
        "Classic Pack Complete", // 6 classicPackComplete
        "Space Pack Complete", // 7 spacePackComplete
        "Nature Pack Complete", // 8 naturePackComplete
        "Urban Pack Complete", // 9 urbanPackComplete
        "Food Pack Complete", // 10 foodPackComplete
        "Computer Pack Complete", // 11 computerPackComplete
        "Body Pack Complete", // 12 bodyPackComplete
        "World Pack Complete", // 13 worldPackComplete
        "Emoji Pack Complete", // 14 emojiPackComplete
        "Numbers Pack Complete", // 15 numbersPackComplete
        "Challenge Pack Complete", // 16 challengePackComplete
        "Endless Mode 1 Minute Milestone", // 17 endlessOneMins
        "Endless Mode 5 Minute Milestone", // 18 endlessFiveMins
        "Endless Mode 10 Minute Milestone", // 19 endlessTenMins
        "Endless Mode 30 Minute Milestone", // 20 endlessThirtyMins
        "Endless Mode 1 Hour Milestone", // 21 endlessSixtyMins
        "Tidying Up", // 22 endlessCleared
        "Taking The Plunge", // 23 mysteryPowerUp
        "Now We’re Talking", // 24 firstPowerUp
        "Giga-Lasers!", // 25 gigaLasers
        "Didn’t Even Need It", // 26 endBackstop
        "That’s My Favourite", // 27 favouritePowerUp
        "100 And Counting", // 28 powerUpCollectorHundred
        "Hoarder", // 29 powerUpCollectorThousand
        "Picky", // 30 powerUpLeaverHundred
        "Power-Up Shy", // 31 powerUpLeaverThousand
        "This Is Too Easy", // 32 maxPaddleSize
        "Good Luck", // 33 minPaddleSize
        "Beach Ball", // 34 maxBallSize
        "Pinball", // 35 minBallSize
        "Invincible", // 36 noBallsLost
        "Hanging on", // 37 threeBallsLost
        "Super Powers", // 38 allLevelPowerUps
        "Mere Mortal", // 39 noLevelPowerUps
        "Giga-Speedy", // 40 quickLevelComplete
        "Supreme Paddle Efficiency", // 41 fivePaddleHits
        "Paddle Master", // 42 tenPaddleHits
        "5,000 Points On 1 Level", // 43 fiveKPointsLevel
        "10,000 Points On 1 Level", // 44 tenKPointsLevel
        "1 Level Down", // 45 oneLevelsComplete
        "Level Decade", // 46 tenLevelsComplete
        "Level Century", // 47 hunderdLevelsComplete
        "Level Millennium", // 48 oneKLevelsComplete
        "Level 10 Millenia", // 49 tenKLevelsComplete
        "Panic Move", // 50 paddleSpeed
        "100,000 And Counting", // 51 hundredKTotalScore
        "Half A Mill", // 52 fiveHundredKTotalScore
        "Millionaire", // 53 millTotalScore
        "God-Like", // 54 noBallsLostPack
        "More Balls Please", // 55 tenBallsLostPack
        "Super Hero", // 56 allPackPowerUps
        "Serial Dodger", // 57 noPackPowerUps
        "And Time", // 58 quickPackComplete
        "10,000 Points On 1 Pack", // 59 tenKPointsPack
        "25,000 Points On 1 Pack", // 60 twoFiveKPointsPack
        "50,000 Points On 1 Pack", // 61 fiftyKPointsPack
        "1 Pack Down", // 62 onePacksComplete
        "Pack Decade", // 63 tenPacksComplete
        "Pack Century", // 64 hundredPacksComplete
        "Pack Millennium" // 65 thousandPacksComplete
    ]
    let achievementsPreEarnedDescriptionArray: [String] = [
        "Reach 10m in Endless Mode", // 0 achievementEndlessTen
        "Reach 100m in Endless Mode", // 1 achievementEndlessHundred
        "Reach 500m in Endless Mode", // 2 achievementEndlessFiveHundred
        "Reach 1,000m in Endless Mode", // 3 achievementEndlessOneK
        "Reach 5,000m Total Height in Endless Mode", // 4 achievementEndlessFiveK
        "Reach 10,000m Total Height in Endless Mode", // 5 achievementEndlessTenK
        "Complete all levels in Classic Pack", // 6 classicPackComplete
        "Complete all levels in Space Pack", // 7 spacePackComplete
        "Complete all levels in Nature Pack", // 8 naturePackComplete
        "Complete all levels in Urban Pack", // 9 urbanPackComplete
        "Complete all levels in Food Pack", // 10 foodPackComplete
        "Complete all levels in Computer Pack", // 11 computerPackComplete
        "Complete all levels in Body Pack", // 12 bodyPackComplete
        "Complete all levels in World Pack", // 13 worldPackComplete
        "Complete all levels in Emoji Pack", // 14 emojiPackComplete
        "Complete all levels in Numbers Pack", // 15 numbersPackComplete
        "Complete all levels in Challenge Pack", // 16 challengePackComplete
        "Survive 1 minute in Endless Mode", // 17 endlessOneMins
        "Survive 5 minutes in Endless Mode", // 18 endlessFiveMins
        "Survive 10 minutes in Endless Mode", // 19 endlessTenMins
        "Survive 30 minutes in Endless Mode", // 20 endlessThirtyMins
        "Survive 1 hour in Endless Mode", // 21 endlessSixtyMins
        "Clear Endless Mode of all active bricks", // 22 endlessCleared
        "Collect Mystery power-up for the first time", // 23 mysteryPowerUp
        "Collect power-up for the first time", // 24 firstPowerUp
        "Have Giga-Ball and Lasers power-up at the same time", // 25 gigaLasers
        "End level with Backstop power-up still active", // 26 endBackstop
        "Collect a single power-up 100 times", // 27 favouritePowerUp
        "Collect 100 power-ups", // 28 powerUpCollectorHundred
        "Collect 1000 power-ups", // 29 powerUpCollectorThousand
        "Leave 100 power-ups", // 30 powerUpLeaverHundred
        "Leave 1000 power-ups", // 31 powerUpLeaverThousand
        "Expand the paddle to its maximum width", // 32 maxPaddleSize
        "Shrink the paddle to its minimum width", // 33 minPaddleSize
        "Expand the ball to its maximum size", // 34 maxBallSize
        "Shrink the ball to its minimum size", // 35 minBallSize
        "Complete level without losing ball", // 36 noBallsLost
        "Complete level losing 3 or more balls", // 37 threeBallsLost
        "Collect all power-ups on a level", // 38 allLevelPowerUps
        "Collect no power-ups on a level", // 39 noLevelPowerUps
        "Complete level in under a minute", // 40 quickLevelComplete
        "Complete level in 5 or fewer paddle hits", // 41 fivePaddleHits
        "Complete level in 10 or fewer paddle hits", // 42 tenPaddleHits
        "Collect 5,000 points on a single level", // 43 fiveKPointsLevel
        "Collect 10,000 points on a single level", // 44 tenKPointsLevel
        "Complete first level", // 45 oneLevelsComplete
        "Complete 10 levels", // 46 tenLevelsComplete
        "Complete 100 levels", // 47 hunderdLevelsComplete
        "Complete 1,000 levels", // 48 oneKLevelsComplete
        "Complete 10,000 levels", // 49 tenKLevelsComplete
        "Move the paddle at incredible speeds", // 50 paddleSpeed
        "Earn 100,000 total points", // 51 hundredKTotalScore
        "Earn 500,000 total points", // 52 fiveHundredKTotalScore
        "Earn 1,000,000 total points", // 53 millTotalScore
        "Complete pack without losing ball", // 54 noBallsLostPack
        "Complete pack losing 10 or more balls", // 55 tenBallsLostPack
        "Collect all power-ups on a pack", // 56 allPackPowerUps
        "Collect no power-ups on a pack", // 57 noPackPowerUps
        "Complete pack in under ten minutes", // 58 quickPackComplete
        "Collect 10,000 points on a single pack", // 59 tenKPointsPack
        "Collect 25,000 points on a single pack", // 60 twoFiveKPointsPack
        "Collect 50,000 points on a single pack", // 61 fiftyKPointsPack
        "Complete first pack", // 62 onePacksComplete
        "Complete 10 packs", // 63 tenPacksComplete
        "Complete 100 packs", // 64 hundredPacksComplete
        "Complete 1,000 packs" // 65 thousandPacksComplete
    ]
    let achievementsEarnedDescriptionArray: [String] = [
        "Passed 10m in Endless Mode", // 0 achievementEndlessTen
        "Passed 100m in Endless Mode", // 1 achievementEndlessHundred
        "Passed 500m in Endless Mode", // 2 achievementEndlessFiveHundred
        "Passed 1,000m in Endless Mode", // 3 achievementEndlessOneK
        "Passed 5,000m Total Height in Endless Mode", // 4 achievementEndlessFiveK
        "Passed 10,000m Total Height in Endless Mode", // 5 achievementEndlessTenK
        "Passed all levels in Classic Pack", // 6 classicPackComplete
        "Passed all levels in Space Pack", // 7 spacePackComplete
        "Passed all levels in Nature Pack", // 8 naturePackComplete
        "Passed all levels in Urban Pack", // 9 urbanPackComplete
        "Passed all levels in Food Pack", // 10 foodPackComplete
        "Passed all levels in Computer Pack", // 11 computerPackComplete
        "Passed all levels in Body Pack", // 12 bodyPackComplete
        "Passed all levels in World Pack", // 13 worldPackComplete
        "Passed all levels in Emoji Pack", // 14 emojiPackComplete
        "Passed all levels in Numbers Pack", // 15 numbersPackComplete
        "Passed all levels in Challenge Pack", // 16 challengePackComplete
        "Survived 1 minute in Endless Mode", // 17 endlessOneMins
        "Survived 5 minutes in Endless Mode", // 18 endlessFiveMins
        "Survived 10 minutes in Endless Mode", // 19 endlessTenMins
        "Survived 30 minutes in Endless Mode", // 20 endlessThirtyMins
        "Survived 1 hour in Endless Mode", // 21 endlessSixtyMins
        "Endless Mode cleared of all active bricks", // 22 endlessCleared
        "Collected Mystery power-up", // 23 mysteryPowerUp
        "Collected first power-up", // 24 firstPowerUp
        "Had Giga-Ball and Lasers power-up at the same time", // 25 gigaLasers
        "Ended level with Backstop power-up still active", // 26 endBackstop
        "Collected a single power-up 100 times", // 27 favouritePowerUp
        "Collected 100 power-ups", // 28 powerUpCollectorHundred
        "Collected 1000 power-ups", // 29 powerUpCollectorThousand
        "Left 100 power-ups", // 30 powerUpLeaverHundred
        "Left 1000 power-ups", // 31 powerUpLeaverThousand
        "Paddle expanded to its maximum width", // 32 maxPaddleSize
        "Paddle shrunk to its minimum width", // 33 minPaddleSize
        "Ball expanded to its maximum size", // 34 maxBallSize
        "Ball shrunk to its minimum size", // 35 minBallSize
        "Level completed without losing ball", // 36 noBallsLost
        "Level completed losing 3 or more balls", // 37 threeBallsLost
        "All power-ups on a level collected", // 38 allLevelPowerUps
        "No power-ups on a level collected", // 39 noLevelPowerUps
        "Level completed in under a minute", // 40 quickLevelComplete
        "Level completed in 5 or fewer paddle its", // 41 fivePaddleHits
        "Level completed in 10 or fewer paddle its", // 42 tenPaddleHits
        "5,000 points collected on a single level", // 43 fiveKPointsLevel
        "10,000 points collected on a single level", // 44 tenKPointsLevel
        "First level completed", // 45 oneLevelsComplete
        "Completed 10 levels", // 46 tenLevelsComplete
        "Completed 100 levels", // 47 hunderdLevelsComplete
        "Completed 1,000 levels", // 48 oneKLevelsComplete
        "Completed 10,000 levels", // 49 tenKLevelsComplete
        "Paddle moved at incredible speeds", // 50 paddleSpeed
        "100,000 total points earned", // 51 hundredKTotalScore
        "500,000 total points earned", // 52 fiveHundredKTotalScore
        "1,000,000 total points earned", // 53 millTotalScore
        "Pack completed without losing ball", // 54 noBallsLostPack
        "Level pack losing 10 or more balls", // 55 tenBallsLostPack
        "All power-ups on a pack collected", // 56 allPackPowerUps
        "No power-ups on a pack collected", // 57 noPackPowerUps
        "Pack completed in under ten minutes", // 58 quickPackComplete
        "10,000 points collected on a single pack", // 59 tenKPointsPack
        "25,000 points collected on a single pack", // 60 twoFiveKPointsPack
        "50,000 points collected on a single pack", // 61 fiftyKPointsPack
        "First pack completed", // 62 onePacksComplete
        "Completed 10 packs", // 63 tenPacksComplete
        "Completed 100 packs", // 64 hundredPacksComplete
        "Completed 1,000 packs" // 65 thousandPacksComplete
    ]
    let achievementsImageArray: [String] = [
        "AchivementBadge.png", // 0 achievementEndlessTen
        "AchivementBadge.png", // 1 achievementEndlessHundred
        "AchivementBadge.png", // 2 achievementEndlessFiveHundred
        "AchivementBadge.png", // 3 achievementEndlessOneK
        "AchivementBadge.png", // 4 achievementEndlessFiveK
        "AchivementBadge.png", // 5 achievementEndlessTenK
        "AchivementBadge.png", // 6 classicPackComplete
        "AchivementBadge.png", // 7 spacePackComplete
        "AchivementBadge.png", // 8 naturePackComplete
        "AchivementBadge.png", // 9 urbanPackComplete
        "AchivementBadge.png", // 10 foodPackComplete
        "AchivementBadge.png", // 11 computerPackComplete
        "AchivementBadge.png", // 12 bodyPackComplete
        "AchivementBadge.png", // 13 worldPackComplete
        "AchivementBadge.png", // 14 emojiPackComplete
        "AchivementBadge.png", // 15 numbersPackComplete
        "AchivementBadge.png", // 16 challengePackComplete
        "AchivementBadge.png", // 17 endlessOneMins
        "AchivementBadge.png", // 18 endlessFiveMins
        "AchivementBadge.png", // 19 endlessTenMins
        "AchivementBadge.png", // 20 endlessThirtyMins
        "AchivementBadge.png", // 21 endlessSixtyMins
        "AchivementBadge.png", // 22 endlessCleared
        "AchivementBadge.png", // 23 mysteryPowerUp
        "AchivementBadge.png", // 24 firstPowerUp
        "AchivementBadge.png", // 25 gigaLasers
        "AchivementBadge.png", // 26 endBackstop
        "AchivementBadge.png", // 27 favouritePowerUp
        "AchivementBadge.png", // 28 powerUpCollectorHundred
        "AchivementBadge.png", // 29 powerUpCollectorThousand
        "AchivementBadge.png", // 30 powerUpLeaverHundred
        "AchivementBadge.png", // 31 powerUpLeaverThousand
        "AchivementBadge.png", // 32 maxPaddleSize
        "AchivementBadge.png", // 33 minPaddleSize
        "AchivementBadge.png", // 34 maxBallSize
        "AchivementBadge.png", // 35 minBallSize
        "AchivementBadge.png", // 36 noBallsLost
        "AchivementBadge.png", // 37 threeBallsLost
        "AchivementBadge.png", // 38 allLevelPowerUps
        "AchivementBadge.png", // 39 noLevelPowerUps
        "AchivementBadge.png", // 40 quickLevelComplete
        "AchivementBadge.png", // 41 fivePaddleHits
        "AchivementBadge.png", // 42 tenPaddleHits
        "AchivementBadge.png", // 43 fiveKPointsLevel
        "AchivementBadge.png", // 44 tenKPointsLevel
        "AchivementBadge.png", // 45 oneLevelsComplete
        "AchivementBadge.png", // 46 tenLevelsComplete
        "AchivementBadge.png", // 47 hunderdLevelsComplete
        "AchivementBadge.png", // 48 oneKLevelsComplete
        "AchivementBadge.png", // 49 tenKLevelsComplete
        "AchivementBadge.png", // 50 paddleSpeed
        "AchivementBadge.png", // 51 hundredKTotalScore
        "AchivementBadge.png", // 52 fiveHundredKTotalScore
        "AchivementBadge.png", // 53 millTotalScore
        "AchivementBadge.png", // 54 noBallsLostPack
        "AchivementBadge.png", // 55 tenBallsLostPack
        "AchivementBadge.png", // 56 allPackPowerUps
        "AchivementBadge.png", // 57 noPackPowerUps
        "AchivementBadge.png", // 58 quickPackComplete
        "AchivementBadge.png", // 59 tenKPointsPack
        "AchivementBadge.png", // 60 twoFiveKPointsPack
        "AchivementBadge.png", // 61 fiftyKPointsPack
        "AchivementBadge.png", // 62 onePacksComplete
        "AchivementBadge.png", // 63 tenPacksComplete
        "AchivementBadge.png", // 64 hundredPacksComplete
        "AchivementBadge.png" // 65 thousandPacksComplete
    ]
    let gameCenterAchievementsArray: [GKAchievement] = [
        GKAchievement(identifier: "onePacksComplete"),
        GKAchievement(identifier: "endlessOneMins")
    ]
}
