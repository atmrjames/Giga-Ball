//
//  LevelPackSetup.swift
//  Megaball
//
//  Created by James Harding on 07/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import UIKit

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
    
    let levelPackUnlockedArray: [Bool] = [
        true, // Tutorial
        true, // Endless Mode
        true, // Classic
        true, // Space
        true, // Nature
        true, // Urban
        true, // Food
        true, // Computer
        true, // Body
        true, // World
        true, // Emoji
        true, // Numbers
        true // Challenge
    ]
    
    let ballImageArray: [UIImage] = [
        UIImage(named:"ballNormal.png")!,
        UIImage(named:"3DBall.png")!,
        UIImage(named:"outlineBall.png")!,
        UIImage(named:"diamondBall.png")!,
        UIImage(named:"beachBall.png")!,
        UIImage(named:"concentricBall.png")!,
        UIImage(named:"reuleauxBall.png")!,
        UIImage(named:"dotBall.png")!,
        UIImage(named:"hobBall.png")!,
        UIImage(named:"spiralBall.png")!,
        UIImage(named:"pixelBall.png")!,
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
        "Reuleaux",
        "Dots",
        "Spokes",
        "Spiral",
        "Pixel",
        "Rainbow",
        "Retro"
    ]
    
    let ballUnlockedArray: [Bool] = [
        true, // Classic
        true, // 3D
        true, // Outline
        true, // Diamond
        true, // Beach ball
        true, // Concentric
        true, // Reuleaux
        true, // Dots
        true, // Spokes
        true, // Spiral
        true, // Pixel
        true, // Rainbow
        true // Retro
    ]
    
    let ballIconArray: [UIImage] = [
        UIImage(named:"ballIcon.png")!,
        UIImage(named:"3DBallIcon.png")!,
        UIImage(named:"outlineBallIcon.png")!,
        UIImage(named:"diamondBallIcon.png")!,
        UIImage(named:"beachBallIcon.png")!,
        UIImage(named:"concentricBallIcon.png")!,
        UIImage(named:"reuleauxBallIcon.png")!,
        UIImage(named:"dotBallIcon.png")!,
        UIImage(named:"hobBallIcon.png")!,
        UIImage(named:"spiralBallIcon.png")!,
        UIImage(named:"pixelBallIcon.png")!,
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
        "Giga",
        "Candy Cane",
        "Split",
        "Rainbow",
        "Retro"
    ]
    
    let paddleUnlockedArray: [Bool] = [
        true, // Classic
        true, // 3D
        true, // Outline
        true, // Square
        true, // Ice
        true, // Glass
        true, // Pixel
        true, // Giga
        true, // Candy Cane
        true, // Split
        true, // Rainbow
        true // Retro
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
        UIImage(named:"White.png")!,
        UIImage(named:"Yellow.png")!,
        UIImage(named:"Orange.png")!,
        UIImage(named:"Green.png")!,
        UIImage(named:"Blue.png")!,
        UIImage(named:"Brown.png")!,
        UIImage(named:"Black.png")!,
        UIImage(named:"Pink.png")!,
        UIImage(named:"Purple.png")!,
        UIImage(named:"GigaBall.png")!,
        UIImage(named:"Rainbow.png")!,
        UIImage(named:"Retro.png")!
    ]
    
    let appIconNameArray: [String] = [
        "White",
        "Yellow",
        "Orange",
        "Green",
        "Blue",
        "Brown",
        "Black",
        "Pink",
        "Purple",
        "Giga-Ball",
        "Rainbow",
        "Retro"        
    ]
    
    let appIconUnlockedArray: [Bool] = [
        true, // White
        true, // Yellow
        true, // Orange
        true, // Green
        true, // Blue
        true, // Brown
        true, // Black
        true, // Pink
        true, // Purple
        true, // Giga-Ball
        true, // Rainbow
        true // Retro
    ]
    
    let brickImageArray: [UIImage] = [
        UIImage(named:"BrickNormal.png")!,
        UIImage(named:"retroBrickNormal.png")!
    ]
    
    let brickNameArray: [String] = [
        "Classic",
        "Retro"
    ]
    
    let brickUnlockedArray: [Bool] = [
        true, // Classic
        true // Retro
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
    
    let levelUnlockedArray: [Bool] = [
        
        true, // Endless mode
        
        // Classic Pack
        true, // Checkers
        true, // Electric Fence
        true, // Gateway
        true, // Surfer's Paradise
        true, // Chevron
        true, // Vignette
        true, // Cluster
        true, // Vertical Challenge
        true, // Horizontal Challenge
        true, // X Marks The Spot
        
        // Space Pack
        true, // Cresent Moon
        true, // Invader
        true, // Constellation
        true, // Star
        true, // Rocket
        true, // Galaxy
        true, // Meteor Shower
        true, // Neptune
        true, // Saturn
        true, // Meteorite

        // Nature Pack
        true, // Leaf
        true, // Rainbow
        true, // Egg
        true, // Tree
        true, // Sunset
        true, // Apple
        true, // Flower
        true, // Birds
        true, // Germ
        true, // Butterfly
        
        // Urban Pack
        true, // City Map
        true, // Skyscraper
        true, // Subway
        true, // Cottage
        true, // Traffic Light
        true, // Finance
        true, // Apartments
        true, // City Hall
        true, // Bridge
        true, // Cityscape Reflection
        
        // Food Pack
        true, // Hotdog
        true, // Piece of Cake
        true, // Wine Glass
        true, // Fried Egg
        true, // BBQ
        true, // Kebabs
        true, // Ice Cream
        true, // Burger
        true, // Pudding
        true, // Chocolate Bar
        
        // Computer Pack
        true, // Command
        true, // Save
        true, // @
        true, // Mail
        true, // Watch
        true, // Trash
        true, // Bug
        true, // Zoom
        true, // Battery
        true, // Hour Glass
        
        // Body Pack
        true, // Heart
        true, // Brain
        true, // Skull
        true, // Intestine
        true, // Lips
        true, // Eye
        true, // Kidney
        true, // Tooth
        true, // Lungs
        true, // Face
        
        // World Pack
        true, // Globe
        true, // Pyramid
        true, // Union Jack
        true, // Compass
        true, // Mountain
        true, // Africa
        true, // Island
        true, // Partly Cloudy
        true, // Maple Leaf
        true, // Volcano
        
        // Emoji Pack
        true, // Smiling Face
        true, // Eyes
        true, // Fire
        true, // Weird Fish
        true, // Winking Face
        true, // Peach
        true, // Ghost
        true, // Augerbene / Eggplant
        true, // Crying Face
        true, // Poo
        
        // Numbers Pack
        true, // One
        true, // Two
        true, // Three
        true, // Four
        true, // Five
        true, // Six
        true, // Seven
        true, // Eight
        true, // Nine
        true, // Zero
        
        // Challenge Pack
        true, // Lonesome Brick
        true, // Kerplunk
        true, // Gradient
        true, // Restriction
        true, // Barricade
        true, // Minefield
        true, // Split Screen
        true, // Pimple
        true, // Ringfence
        true // Finish Line
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
    
    let powerUpUnlockedArray: [Bool] = [
        true, // Get a Life
        true, // Lose a Life
        true, // Decrease Ball Speed
        true, // Increase Ball Speed
        true, // Increase Paddle Size
        true, // Decrease Paddle Size
        true, //false, // Sticky Paddle
        true, //false, // Gravity
        true, // +100 Points
        true, // -100 Points Small
        true, //false +1000 Points
        true, //false -1000 Points
        true, //false, // x2 Multiplier
        true, //false, // Reset Multiplier
        true, // Next Level
        true, // Show All Bricks
        true, // Hide Bricks
        true, // Clear Multi-Hit Bricks
        true, // Reset Multi-Hit Bricks
        true, // Remove Indestructible Bricks
        true, //false, // Giga-Ball
        true, //false, // Undestructi-Ball
        true, //false, // Lasers
        true, //false, // Quicksand
        true, //false, // Mystery
        true, //false, // Backstop
        true, //false, // Increase Ball Size
        true //false // Decrease Ball Size
    ]
    // true == unlocked, false = locked
    
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
}
