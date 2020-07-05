//
//  TotalStats.swift
//  Megaball
//
//  Created by James Harding on 13/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import Foundation
import GameKit

class TotalStats: Codable {
    
    var dateSaved: Date = Date(timeIntervalSinceReferenceDate: 0.0) // Seconds since 00:00:00 UTC on 01/01/2001
    var cumulativeScore: Int = 0
    var levelsPlayed: Int = 0
    var levelsCompleted: Int = 0
    var ballHits: Int = 0
    var ballsLost: Int = 0
    var powerupsCollected: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var powerupsGenerated: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var bricksHit: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var bricksDestroyed: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]
    var lasersFired: Int = 0
    var lasersHit: Int = 0
    var playTimeSecs: Int = 0
    var packsPlayed: Int = 0
    var packsCompleted: Int = 0
    
    var endlessModeHeight: [Int] = []
    var endlessModeHeightDate: [Date] = []
    
    var levelPackUnlockedArray: [Bool] = [
        true, // Tutorial
        true, // Endless Mode
        true, // Classic
        true, // Space
        true, // Nature
        false, // Urban
        false, // Food
        false, // Computer
        false, // Body
        false, // World
        false, // Emoji
        false, // Numbers
        false // Challenge
    ]
    
    var ballUnlockedArray: [Bool] = [
        true, // Classic
        false, // 3D
        false, // Outline
        false, // Diamond
        false, // Beach ball
        false, // Concentric
        false, // Pixel
        false, // Dots
        false, // Spokes
        false, // Reuleaux
        false, // Rainbow
        false // Retro
    ]
    
    var paddleUnlockedArray: [Bool] = [
        true, // Classic
        false, // 3D
        false, // Outline
        false, // Square
        false, // Ice
        false, // Glass
        false, // Pixel
        false, // Giga
        false, // Candy Cane
        false, // Split
        false, // Rainbow
        false // Retro
    ]
    
    var appIconUnlockedArray: [Bool] = [
        true, // Purple
        false, // White
        false, // Yellow
        false, // Orange
        false, // Green
        false, // Blue
        false, // Brown
        false, // Black
        false, // Pink
        false, // Giga-Ball
        false, // Rainbow
        false // Retro
    ]
    
    var brickUnlockedArray: [Bool] = [
        true, // Classic
        false // Retro
    ]
    
    var levelUnlockedArray: [Bool] = [
        
        true, // Endless mode
        
        // Classic Pack
        true, // Checkers
        false, // Electric Fence
        false, // Gateway
        false, // Surfer's Paradise
        false, // Chevron
        false, // Vignette
        false, // Cluster
        false, // Vertical Challenge
        false, // Horizontal Challenge
        false, // X Marks The Spot
        
        // Space Pack
        true, // Cresent Moon
        false, // Invader
        false, // Constellation
        false, // Star
        false, // Rocket
        false, // Galaxy
        false, // Meteor Shower
        false, // Neptune
        false, // Saturn
        false, // Meteorite

        // Nature Pack
        true, // Leaf
        false, // Rainbow
        false, // Egg
        false, // Tree
        false, // Sunset
        false, // Apple
        false, // Flower
        false, // Birds
        false, // Germ
        false, // Butterfly
        
        // Urban Pack
        false, // City Map
        false, // Skyscraper
        false, // Subway
        false, // Cottage
        false, // Traffic Light
        false, // Finance
        false, // Apartments
        false, // City Hall
        false, // Bridge
        false, // Cityscape Reflection
        
        // Food Pack
        false, // Hotdog
        false, // Piece of Cake
        false, // Wine Glass
        false, // Fried Egg
        false, // BBQ
        false, // Kebabs
        false, // Ice Cream
        false, // Burger
        false, // Pudding
        false, // Chocolate Bar
        
        // Computer Pack
        false, // Command
        false, // Save
        false, // @
        false, // Mail
        false, // Watch
        false, // Trash
        false, // Bug
        false, // Zoom
        false, // Battery
        false, // Hour Glass
        
        // Body Pack
        false, // Heart
        false, // Brain
        false, // Skull
        false, // Intestine
        false, // Lips
        false, // Eye
        false, // Kidney
        false, // Tooth
        false, // Lungs
        false, // Face
        
        // World Pack
        false, // Globe
        false, // Pyramid
        false, // Union Jack
        false, // Compass
        false, // Mountain
        false, // Africa
        false, // Island
        false, // Partly Cloudy
        false, // Maple Leaf
        false, // Volcano
        
        // Emoji Pack
        false, // Smiling Face
        false, // Eyes
        false, // Fire
        false, // Weird Fish
        false, // Winking Face
        false, // Peach
        false, // Ghost
        false, // Augerbene / Eggplant
        false, // Crying Face
        false, // Poo
        
        // Numbers Pack
        false, // One
        false, // Two
        false, // Three
        false, // Four
        false, // Five
        false, // Six
        false, // Seven
        false, // Eight
        false, // Nine
        false, // Zero
        
        // Challenge Pack
        false, // Lonesome Brick
        false, // Kerplunk
        false, // Gradient
        false, // Restriction
        false, // Barricade
        false, // Minefield
        false, // Split Screen
        false, // Pimple
        false, // Ringfence
        false // Finish Line
    ]
    
    var powerUpUnlockedArray: [Bool] = [
        true, // Get a Life
        true, // Lose a Life
        true, // Decrease Ball Speed
        true, // Increase Ball Speed
        true, // Increase Paddle Size
        true, // Decrease Paddle Size
        false, // Sticky Paddle
        false, // Gravity
        true, // +100 Points
        true, // -100 Points Small
        false, // +1000 Points
        false, // -1000 Points
        false, // x2 Multiplier
        false, // Reset Multiplier
        true, // Next Level
        true, // Show All Bricks
        true, // Hide Bricks
        true, // Clear Multi-Hit Bricks
        true, // Reset Multi-Hit Bricks
        true, // Remove Indestructible Bricks
        false, // Giga-Ball
        false, // Undestructi-Ball
        false, // Lasers
        false, // Quicksand
        false, // Mystery
        false, // Backstop
        false, // Increase Ball Size
        false // Decrease Ball Size
    ]
    
    var achievementsUnlockedArray: [Bool] = [
        false, // 0 achievementEndlessTen
        false, // 1 achievementEndlessHundred
        false, // 2 achievementEndlessFiveHundred
        false, // 3 achievementEndlessOneK
        false, // 4 achievementEndlessFiveK
        false, // 5 achievementEndlessTenK
        false, // 6 classicPackComplete
        false, // 7 spacePackComplete
        false, // 8 naturePackComplete
        false, // 9 urbanPackComplete
        false, // 10 foodPackComplete
        false, // 11 computerPackComplete
        false, // 12 bodyPackComplete
        false, // 13 worldPackComplete
        false, // 14 emojiPackComplete
        false, // 15 numbersPackComplete
        false, // 16 challengePackComplete
        false, // 17 endlessOneMins
        false, // 18 endlessFiveMins
        false, // 19 endlessTenMins
        false, // 20 endlessThirtyMins
        false, // 21 endlessSixtyMins
        false, // 22 endlessCleared
        false, // 23 mysteryPowerUp
        false, // 24 firstPowerUp
        false, // 25 gigaLasers
        false, // 26 endBackstop
        false, // 27 favouritePowerUp
        false, // 28 powerUpCollectorHundred
        false, // 29 powerUpCollectorThousand
        false, // 30 powerUpLeaverHundred
        false, // 31 powerUpLeaverThousand
        false, // 32 maxPaddleSize
        false, // 33 minPaddleSize
        false, // 34 maxBallSize
        false, // 35 minBallSize
        false, // 36 noBallsLost
        false, // 37 threeBallsLost
        false, // 38 allLevelPowerUps
        false, // 39 noLevelPowerUps
        false, // 40 quickLevelComplete
        false, // 41 fivePaddleHits
        false, // 42 tenPaddleHits
        false, // 43 fiveKPointsLevel
        false, // 44 tenKPointsLevel
        false, // 45 oneLevelsComplete
        false, // 46 tenLevelsComplete
        false, // 47 hunderdLevelsComplete
        false, // 48 oneKLevelsComplete
        false, // 49 tenKLevelsComplete
        false, // 50 paddleSpeed
        false, // 51 hundredKTotalScore
        false, // 52 fiveHundredKTotalScore
        false, // 53 millTotalScore
        false, // 54 noBallsLostPack
        false, // 55 tenBallsLostPack
        false, // 56 allPackPowerUps
        false, // 57 noPackPowerUps
        false, // 58 quickPackComplete
        false, // 59 tenKPointsPack
        false, // 60 twoFiveKPointsPack
        false, // 61 fiftyKPointsPack
        false, // 62 onePacksComplete
        false, // 63 tenPacksComplete
        false, // 64 hundredPacksComplete
        false // 65 thousandPacksComplete
    ]

    var achievementsPercentageCompleteArray: [String] = [
        "", // 0 achievementEndlessTen
        "", // 1 achievementEndlessHundred
        "", // 2 achievementEndlessFiveHundred
        "", // 3 achievementEndlessOneK
        "0.0%", // 4 achievementEndlessFiveK
        "0.0%", // 5 achievementEndlessTenK
        "", // 6 classicPackComplete
        "", // 7 spacePackComplete
        "", // 8 naturePackComplete
        "", // 9 urbanPackComplete
        "", // 10 foodPackComplete
        "", // 11 computerPackComplete
        "", // 12 bodyPackComplete
        "", // 13 worldPackComplete
        "", // 14 emojiPackComplete
        "", // 15 numbersPackComplete
        "", // 16 challengePackComplete
        "", // 17 endlessOneMins
        "", // 18 endlessFiveMins
        "", // 19 endlessTenMins
        "", // 20 endlessThirtyMins
        "", // 21 endlessSixtyMins
        "", // 22 endlessCleared
        "", // 23 mysteryPowerUp
        "", // 24 firstPowerUp
        "", // 25 gigaLasers
        "", // 26 endBackstop
        "0.0%", // 27 favouritePowerUp
        "0.0%", // 28 powerUpCollectorHundred
        "0.0%", // 29 powerUpCollectorThousand
        "0.0%", // 30 powerUpLeaverHundred
        "0.0%", // 31 powerUpLeaverThousand
        "", // 32 maxPaddleSize
        "", // 33 minPaddleSize
        "", // 34 maxBallSize
        "", // 35 minBallSize
        "", // 36 noBallsLost
        "", // 37 threeBallsLost
        "", // 38 allLevelPowerUps
        "", // 39 noLevelPowerUps
        "", // 40 quickLevelComplete
        "", // 41 fivePaddleHits
        "", // 42 tenPaddleHits
        "", // 43 fiveKPointsLevel
        "", // 44 tenKPointsLevel
        "", // 45 oneLevelsComplete
        "0.0%", // 46 tenLevelsComplete
        "0.0%", // 47 hunderdLevelsComplete
        "0.0%", // 48 oneKLevelsComplete
        "0.0%", // 49 tenKLevelsComplete
        "", // 50 paddleSpeed
        "0.0%", // 51 hundredKTotalScore
        "0.0%", // 52 fiveHundredKTotalScore
        "0.0%", // 53 millTotalScore
        "", // 54 noBallsLostPack
        "", // 55 tenBallsLostPack
        "", // 56 allPackPowerUps
        "", // 57 noPackPowerUps
        "", // 58 quickPackComplete
        "", // 59 tenKPointsPack
        "", // 60 twoFiveKPointsPack
        "", // 61 fiftyKPointsPack
        "", // 62 onePacksComplete
        "0.0%", // 63 tenPacksComplete
        "0.0%", // 64 hundredPacksComplete
        "0.0%" // 65 thousandPacksComplete
    ]
    var achievementDates: [Date] = [
        Date(), // 0 achievementEndlessTen
        Date(), // 1 achievementEndlessHundred
        Date(), // 2 achievementEndlessFiveHundred
        Date(), // 3 achievementEndlessOneK
        Date(), // 4 achievementEndlessFiveK
        Date(), // 5 achievementEndlessTenK
        Date(), // 6 classicPackComplete
        Date(), // 7 spacePackComplete
        Date(), // 8 naturePackComplete
        Date(), // 9 urbanPackComplete
        Date(), // 10 foodPackComplete
        Date(), // 11 computerPackComplete
        Date(), // 12 bodyPackComplete
        Date(), // 13 worldPackComplete
        Date(), // 14 emojiPackComplete
        Date(), // 15 numbersPackComplete
        Date(), // 16 challengePackComplete
        Date(), // 17 endlessOneMins
        Date(), // 18 endlessFiveMins
        Date(), // 19 endlessTenMins
        Date(), // 20 endlessThirtyMins
        Date(), // 21 endlessSixtyMins
        Date(), // 22 endlessCleared
        Date(), // 23 mysteryPowerUp
        Date(), // 24 firstPowerUp
        Date(), // 25 gigaLasers
        Date(), // 26 endBackstop
        Date(), // 27 favouritePowerUp
        Date(), // 28 powerUpCollectorHundred
        Date(), // 29 powerUpCollectorThousand
        Date(), // 30 powerUpLeaverHundred
        Date(), // 31 powerUpLeaverThousand
        Date(), // 32 maxPaddleSize
        Date(), // 33 minPaddleSize
        Date(), // 34 maxBallSize
        Date(), // 35 minBallSize
        Date(), // 36 noBallsLost
        Date(), // 37 threeBallsLost
        Date(), // 38 allLevelPowerUps
        Date(), // 39 noLevelPowerUps
        Date(), // 40 quickLevelComplete
        Date(), // 41 fivePaddleHits
        Date(), // 42 tenPaddleHits
        Date(), // 43 fiveKPointsLevel
        Date(), // 44 tenKPointsLevel
        Date(), // 45 oneLevelsComplete
        Date(), // 46 tenLevelsComplete
        Date(), // 47 hunderdLevelsComplete
        Date(), // 48 oneKLevelsComplete
        Date(), // 49 tenKLevelsComplete
        Date(), // 50 paddleSpeed
        Date(), // 51 hundredKTotalScore
        Date(), // 52 fiveHundredKTotalScore
        Date(), // 53 millTotalScore
        Date(), // 54 noBallsLostPack
        Date(), // 55 tenBallsLostPack
        Date(), // 56 allPackPowerUps
        Date(), // 57 noPackPowerUps
        Date(), // 58 quickPackComplete
        Date(), // 59 tenKPointsPack
        Date(), // 60 twoFiveKPointsPack
        Date(), // 61 fiftyKPointsPack
        Date(), // 62 onePacksComplete
        Date(), // 63 tenPacksComplete
        Date(), // 64 hundredPacksComplete
        Date() // 65 thousandPacksComplete
    ]
}
