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
    let numberOfLevels: [Int] = [1, 10, 2, 0, 0 ,1]
    let startLevelNumber: [Int] = [1, 1, 11, 21, 31, 0]
    let packTitles: [String] = [
        "Tutorial",
        "Starter Pack",
        "Space Pack",
        "Level Pack 3",
        "Level Pack 4",
        "Endless Mode"
    ]
    let levelImageArray: [UIImage] = [
        UIImage(named:"Level000.png")!,
        UIImage(named:"Level001.png")!,
        UIImage(named: "Level002.png")!,
        UIImage(named: "Level003.png")!,
        UIImage(named: "Level004.png")!,
        UIImage(named: "Level005.png")!,
        UIImage(named: "Level006.png")!,
        UIImage(named: "Level007.png")!,
        UIImage(named: "Level008.png")!,
        UIImage(named: "Level009.png")!,
        UIImage(named: "Level010.png")!,
        UIImage(named: "Level011.png")!,
        UIImage(named: "Level012.png")!
    ]
    let levelNameArray: [String] = [
        "Endless Mode",
        "Beginner",
        "Block Test Vertical",
        "Block Test Horizontal",
        "Electric Fence",
        "Surfer's Paradise",
        "Gateway",
        "MegaBall",
        "Sundae",
        "X Marks The Spot",
        "Comet",
        "Cresent Moon",
        "Space Invader"
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
