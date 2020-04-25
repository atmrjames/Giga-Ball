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
    let numberOfLevels: [Int] = [1, 1, 10, 10, 10, 10, 10, 10, 10, 10]
    let startLevelNumber: [Int] = [100, 0, 1, 11, 21, 31, 41, 51, 61, 71]
    let packTitles: [String] = [
        "Tutorial",
        "Endless Mode",
        "Classic Pack",
        "Space Pack",
        "Nature Pack",
        "Urban Pack",
        "Food Pack",
        "Computer Pack",
        "Body Pack",
        "World Pack"
    ]
    let levelImageArray: [UIImage] = [
        UIImage(named:"Level00Image.png")!,
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
        UIImage(named: "Level80Image.png")!
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
        
        // Geography Pack
        "Globe",
        "Pyramid",
        "Union Jack",
        "Compass",
        "Mountain",
        "Africa",
        "Island",
        "Partly Cloudy",
        "Maple Leaf",
        "Volcano"
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
        
        // Numbers Pack
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
        UIImage(named:"PowerUpSuperBall.png")!,
        UIImage(named:"PowerUpUndestructiBall.png")!,
        UIImage(named:"PowerUpLasers.png")!,
        UIImage(named:"PowerUpBricksDown.png")!,
        UIImage(named:"PowerUpMystery.png")!
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
        "Bonus Points",
        "Penalty Points",
        "x2 Multiplier",
        "Reset Multiplier",
        "Next Level",
        "Show All Bricks",
        "Hide Bricks",
        "Clear Multi-Hit Bricks",
        "Reset Multi-Hit Bricks",
        "Remove Indestructible Bricks",
        "Superball",
        "Undestructi-Ball",
        "Lasers",
        "Quicksand",
        "Mystery"
    ]
    
    let powerUpDescriptionArray: [String] = [
        "Gives you an extra life",
        "Kills the ball in play",
        "Slows the ball down",
        "Speeds the ball up",
        "Makes the paddle wider",
        "Makes the paddle shorter",
        "Retains the ball on the paddle",
        "Makes the ball suseptible to gravitation forces",
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
        "Prevents the ball from having any action when hitting bricks",
        "Lasers fire from either side of the paddle",
        "Moves the bricks down towards the paddle",
        "Randomly generates a mystery power-up when collected",
    ]
    
    let powerUpPointsArray: [String] = [
        "+50",
        "",
        "+50",
        "-50",
        "+50",
        "-50",
        "+50",
        "-50",
        "+1000",
        "-1000",
        "+50",
        "-50",
        "+50",
        "+50",
        "-50",
        "+50",
        "-50",
        "+50",
        "+50",
        "-50",
        "+50",
        "-50",
        ""
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
        ""
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
        "10",
        "",
        "",
        "",
        "10",
        "10",
        "10",
        "",
        ""
    ]
}
