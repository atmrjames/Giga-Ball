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
        "City Pack",
        "Food Pack",
        "Computer Pack",
        "Body Pack",
        "World Pack",
        "Emoji Pack",
        "Numbers Pack",
        "Challenge Pack"
    ]
    
    let unlockedDescriptionArray: [String] = [
        "",
        "Complete Classic Pack to unlock", // White
        "Complete Space Pack to unlock", // Yellow
        "Complete Nature Pack to unlock", // Orange
        "Complete City Pack to unlock", // Green
        "Complete Food Pack to unlock", // Blue
        "Complete Computer Pack to unlock", // Brown
        "Complete Body Pack to unlock", // Black
        "Complete World Pack to unlock", // Pink
        "Complete Emoji Pack to unlock", // Giga
        "Complete Numbers Pack to unlock", // Rainbow
        "Complete Challenge Pack to unlock" // Retro
    ]
    
    let themeNameArray: [String] = [
        "Classic",
        "3D",
        "Ice",
        "Outline",
        "Square",
        "Glass",
        "Pixel",
        "Split",
        "Candy Cane",
        "Glow",
        "Rainbow",
        "Retro"
    ]
    
    let themeIconArray: [UIImage] = [
        UIImage(named:"regularThemeIcon.png")!,
        UIImage(named:"3DThemeIcon.png")!,
        UIImage(named:"iceThemeIcon.png")!,
        UIImage(named:"outlineThemeIcon.png")!,
        UIImage(named:"squareThemeIcon.png")!,
        UIImage(named:"glassThemeIcon.png")!,
        UIImage(named:"pixelThemeIcon.png")!,
        UIImage(named:"splitThemeIcon.png")!,
        UIImage(named:"candyThemeIcon.png")!,
        UIImage(named:"gigaThemeIcon.png")!,
        UIImage(named:"rainbowThemeIcon.png")!,
        UIImage(named:"retroThemeIcon.png")!
    ]
    
    let ballImageArray: [UIImage] = [
        UIImage(named:"ballNormal.png")!,
        UIImage(named:"3DBall.png")!,
        UIImage(named:"iceBallNormal.png")!,
        UIImage(named:"outlineBall.png")!,
        UIImage(named:"squareBall.png")!,
        UIImage(named:"glassBallNormal.png")!,
        UIImage(named:"pixelBall.png")!,
        UIImage(named:"splitBall.png")!,
        UIImage(named:"candyBall.png")!,
        UIImage(named:"ballGigaNormal.png")!,
        UIImage(named:"rainbowBall.png")!,
        UIImage(named:"retroBall.png")!
    ]
    
    let paddleImageArray: [UIImage] = [
        UIImage(named:"regularPaddle.png")!,
        UIImage(named:"3DPaddle.png")!,
        UIImage(named:"icePaddle.png")!,
        UIImage(named:"outlinePaddle.png")!,
        UIImage(named:"squarePaddle.png")!,
        UIImage(named:"glassPaddle.png")!,
        UIImage(named:"pixelPaddle.png")!,
        UIImage(named:"splitPaddle.png")!,
        UIImage(named:"candyPaddle.png")!,
        UIImage(named:"gigaPaddle.png")!,
        UIImage(named:"rainbowPaddle.png")!,
        UIImage(named:"retroPaddle.png")!
    ]
    
    let brickImageArray: [UIImage] = [
        UIImage(named:"BrickNormal.png")!,
        UIImage(named:"retroBrickNormal.png")!
    ]
    
    let appIconNameArray: [String] = [
        "Purple",
        "White",
        "Yellow",
        "Outline",
        "Orange",
        "Green",
        "Blue",
        "Black",
        "Pink",
        "Glow",
        "Rainbow",
        "Retro"
    ]
    
    let appIconImageArray: [UIImage] = [
        UIImage(named:"Purple.png")!,
        UIImage(named:"White.png")!,
        UIImage(named:"Yellow.png")!,
        UIImage(named:"Outline.png")!,
        UIImage(named:"Orange.png")!,
        UIImage(named:"Green.png")!,
        UIImage(named:"Blue.png")!,
        UIImage(named:"Black.png")!,
        UIImage(named:"Pink.png")!,
        UIImage(named:"Glow.png")!,
        UIImage(named:"Rainbow.png")!,
        UIImage(named:"Retro.png")!
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
        "Tunnel",
        "Surfer's Paradise",
        "Spinning Top",
        "Vignette",
        "Cluster",
        "Vertical Challenge",
        "Horizontal Challenge",
        "X Marks The Spot",
        
        // Space Pack
        "Invader",
        "Crescent Moon",
        "Constellation",
        "The Sun",
        "Rocket",
        "Spiral Galaxy",
        "Meteor Shower",
        "Neptune",
        "Saturn",
        "Asteroid",
        
        // Nature Pack
        "Leaf",
        "Rainbow",
        "Egg",
        "Tree",
        "Sunset",
        "Apple",
        "Flower",
        "Mother Goose",
        "Germ",
        "Butterfly",
        
        // City Pack
        "City Map",
        "Skyscraper",
        "Underground",
        "Townhouse",
        "Traffic Lights",
        "Finance",
        "Apartments",
        "City Hall",
        "Bridge",
        "Cityscape Reflection",
        
        // Food Pack
        "Hotdog",
        "Cake",
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
        "Clock",
        "Trash",
        "Bug",
        "Zoom",
        "Battery",
        "Hourglass",
        
        // Body Pack
        "Heart",
        "Brain",
        "Skull",
        "Intestines",
        "Mouth",
        "Eye",
        "Stomach",
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
        "Smiley Face",
        "Side Eyes",
        "Fire",
        "Weird Fish",
        "Cheeky Wink",
        "Peach",
        "Ghost",
        "Aubergine",
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
        "Pinball",
        "Gradient",
        "Narrow",
        "Barricade",
        "Minefield",
        "Mirror",
        "Spot",
        "Shield",
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
        
        // City Pack
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
    
    let powerUpCorrectOrderArray = [0,1,2,3,4,5,8,9,14,15,16,17,18,19,6,7,10,11,12,13,20,21,22,23,26,27,25,24]
    let powerUpPackOrderArray = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7]
    
    let powerUpNameArray: [String] = [
        "Extra Ball",
        "Lose A Ball",
        "Slow Ball",
        "Fast Ball",
        "Expand Paddle",
        "Shrink Paddle",
        "Sticky Paddle",
        "Gravity Field",
        "+100 Points",
        "-100 Points",
        "+1000 Points",
        "-1000 Points",
        "Max Multiplier",
        "Reset Multiplier",
        "Complete Level",
        "Show Bricks",
        "Hide Bricks",
        "Clear Multi-Hit Bricks",
        "Reset Multi-Hit Bricks",
        "Zap Indestructible Bricks",
        "Giga-Ball",
        "Inert Ball",
        "Lasers",
        "Quicksand",
        "Mystery",
        "Backstop",
        "Expand Ball",
        "Shrink Ball"
    ]
    
    let powerUpUnlockedDescriptionArray: [String] = [
        "",
        "",
        "",
        "",
        "",
        "",
        "Complete Classic Pack to unlock", // Sticky Paddle
        "Complete Classic Pack to unlock", // Gravity
        "",
        "",
        "Complete Space Pack to unlock", // +1000 Points
        "Complete Space Pack to unlock", // -1000 Points
        "Complete Nature Pack to unlock", // x2 Multiplier
        "Complete Nature Pack to unlock", // Reset Multiplier
        "",
        "",
        "",
        "",
        "",
        "",
        "Complete City Pack to unlock", // Giga-Ball
        "Complete City Pack to unlock", // Undestructi-Ball
        "Complete Food Pack to unlock", // Lasers
        "Complete Food Pack to unlock", // Quicksand
        "Complete Body to unlock", // Mystery
        "Complete Body to unlock", // Backstop
        "Complete Computer to unlock", // Increase Ball Size
        "Complete Computer to unlock" // Decrease Ball Size
    ]
    
    let powerUpHiddenUnlockedDescriptionArray: [String] = [
        "",
        "",
        "",
        "",
        "",
        "",
        "Complete Pack 1 to unlock", // Sticky Paddle
        "Complete Pack 1 to unlock", // Gravity
        "",
        "",
        "Complete Pack 2 to unlock", // +1000 Points
        "Complete Pack 2 to unlock", // -1000 Points
        "Complete Pack 3 to unlock", // x2 Multiplier
        "Complete Pack 3 to unlock", // Reset Multiplier
        "",
        "",
        "",
        "",
        "",
        "",
        "Complete Pack 4 to unlock", // Giga-Ball
        "Complete Pack 4 to unlock", // Undestructi-Ball
        "Complete Pack 5 to unlock", // Lasers
        "Complete Pack 5 to unlock", // Quicksand
        "Complete Pack 7 to unlock", // Mystery
        "Complete Pack 7 to unlock", // Backstop
        "Complete Pack 6 to unlock", // Increase Ball Size
        "Complete Pack 6 to unlock" // Decrease Ball Size
    ]
    
    let powerUpDescriptionArray: [String] = [
        "Gives you an extra ball",
        "Lose your current ball",
        "Slows the ball down",
        "Speeds the ball up",
        "Makes the paddle wider",
        "Makes the paddle shorter",
        "Sticks the ball to the paddle on contact",
        "Applies a gravity field to the ball",
        "Adds 100 points x multiplier to your score",
        "Removes 100 points x multiplier from your score",
        "Adds 1000 points x multiplier to your score",
        "Removes 1000 points x multiplier from your score",
        "Sets the multiplier to the maximum of x2",
        "Sets the multiplier to the minimum of x1",
        "Moves you directly to the next level",
        "Reveals all hidden bricks",
        "Hides all standard and invisible bricks",
        "Reduces multi-hit bricks to single hit bricks",
        "Resets all multi-hit bricks",
        "Removes all indestructible bricks",
        "Allows the ball to pass through all bricks",
        "Prevents the ball from removing bricks",
        "Fires lasers from the paddle",
        "Moves all bricks down",
        "Applies a random power-up, good or bad",
        "Adds a safety net below the paddle to save a missed ball",
        "Makes the ball larger",
        "Makes the ball smaller"
    ]
    
    let powerUpMultiplierArray: [String] = [
        "+0.1",
        "",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "",
        "",
        "",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "+0.1",
        "+0.1",
        "-0.1",
        "+0.1",
        "-0.1",
        "",
        "+0.1",
        "+0.1",
        "-0.1"
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
        "",
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
        "City Pack Complete", // 9 urbanPackComplete
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
        "Complete all levels in City Pack", // 9 urbanPackComplete
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
        "Passed all levels in City Pack", // 9 urbanPackComplete
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
        "Level pack completed losing 10 or more balls", // 55 tenBallsLostPack
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
