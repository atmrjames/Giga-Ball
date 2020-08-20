//
//  PowerUpAllocation.swift
//  Megaball
//
//  Created by James Harding on 20/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func powerUpProbAllocation(levelNumber: Int) {
        
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
        powerUpProbArray[25] = 5 // Backstop
        powerUpProbArray[26] = 10 // Increase Ball Size
        powerUpProbArray[27] = 10 // Decrease Ball Size
        
        powerUpProbFactor = 10
        // default power-up allocation
        
        switch levelNumber {
        
        // Endless mode
        case 0:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[8] = 0 // +100 Points
            powerUpProbArray[9] = 0 // -100 Points
            powerUpProbArray[10] = 0 // +1000 Points
            powerUpProbArray[11] = 0 // -1000 Points
            powerUpProbArray[12] = 0 // x2 Multiplier
            powerUpProbArray[13] = 0 // Reset Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[23] = 0 // Quicksand
                        
        // Classic Pack
        case 1:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[6] = 0 // Sticky Paddle
            powerUpProbArray[7] = 0 // Gravity
            powerUpProbArray[8] = 0 // +100 Points
            powerUpProbArray[9] = 0 // -100 Points
            powerUpProbArray[10] = 0 // +1000 Points
            powerUpProbArray[11] = 0 // -1000 Points
            powerUpProbArray[12] = 0 // x2 Multiplier
            powerUpProbArray[13] = 0 // Reset Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[15] = 0 // Show All Bricks
            powerUpProbArray[16] = 0 // Hide Bricks
            powerUpProbArray[17] = 0 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 0 // Remove Indestructible Bricks
            powerUpProbArray[20] = 0 // Giga-Ball
            powerUpProbArray[21] = 0 // Undestructi-Ball
            powerUpProbArray[22] = 0 // Lasers
            powerUpProbArray[23] = 0 // Quicksand
            powerUpProbArray[24] = 0 // Mystery
            powerUpProbArray[25] = 0 // Backstop
        
        case 2:
            powerUpProbArray[2] = 5 // Decrease Ball Speed
            powerUpProbArray[3] = 5 // Increase Ball Speed
            powerUpProbArray[4] = 5 // Increase Paddle Size
            powerUpProbArray[5] = 5 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // +100 Points
            powerUpProbArray[9] = 3 // -100 Points
            powerUpProbArray[10] = 1 // +1000 Points
            powerUpProbArray[11] = 1 // -1000 Points
            powerUpProbArray[12] = 3 // x2 Multiplier
            powerUpProbArray[13] = 3 // Reset Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[15] = 10 // Show All Bricks
            powerUpProbArray[16] = 10 // Hide Bricks
            powerUpProbArray[17] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 10 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 0 // Remove Indestructible Bricks
            powerUpProbArray[23] = 3 // Quicksand
            powerUpProbArray[24] = 3 // Mystery
            powerUpProbArray[25] = 3 // Backstop
            powerUpProbArray[26] = 5 // Increase Ball Size
            powerUpProbArray[27] = 5 // Decrease Ball Size
                        
        case 3:
            powerUpProbArray[2] = 5 // Decrease Ball Speed
            powerUpProbArray[3] = 5 // Increase Ball Speed
            powerUpProbArray[4] = 5 // Increase Paddle Size
            powerUpProbArray[5] = 5 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // +100 Points
            powerUpProbArray[9] = 3 // -100 Points
            powerUpProbArray[10] = 1 // +1000 Points
            powerUpProbArray[11] = 1 // -1000 Points
            powerUpProbArray[12] = 3 // x2 Multiplier
            powerUpProbArray[13] = 3 // Reset Multiplier
            powerUpProbArray[15] = 3 // Show All Bricks
            powerUpProbArray[16] = 3 // Hide Bricks
            powerUpProbArray[17] = 7 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 7 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 10 // Remove Indestructible Bricks
            powerUpProbArray[20] = 5 // Giga-Ball
            powerUpProbArray[21] = 5 // Undestructi-Ball
            powerUpProbArray[22] = 5 // Lasers
            powerUpProbArray[23] = 3 // Quicksand
            powerUpProbArray[24] = 10 // Mystery
            powerUpProbArray[26] = 5 // Increase Ball Size
            powerUpProbArray[27] = 5 // Decrease Ball Size
            
        case 5:
            powerUpProbArray[23] = 10 // Quicksand
            
        case 6:
            powerUpProbArray[20] = 0 // Giga-Ball
            powerUpProbArray[21] = 0 // Undestructi-Ball
            powerUpProbArray[22] = 0 // Lasers
            
        case 7:
            powerUpProbArray[22] = 0 // Lasers
            
        case 10:
            powerUpProbArray[15] = 10 // Show All Bricks
            powerUpProbArray[16] = 10 // Hide Bricks
            powerUpProbArray[17] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 10 // Reset Multi-Hit Bricks

        // Space Pack
        case 11:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[7] = 10 // Gravity
            powerUpProbArray[15] = 10 // Show All Bricks
            powerUpProbArray[16] = 10 // Hide Bricks
        case 12:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[2] = 7 // Decrease Ball Speed
            powerUpProbArray[3] = 7 // Increase Ball Speed
            powerUpProbArray[4] = 7 // Increase Paddle Size
            powerUpProbArray[5] = 7 // Decrease Paddle Size
            powerUpProbArray[6] = 5 // Sticky Paddle
            powerUpProbArray[7] = 5 // Gravity
            powerUpProbArray[8] = 5 // +100 Points
            powerUpProbArray[9] = 5 // -100 Points
            powerUpProbArray[10] = 1// +1000 Points
            powerUpProbArray[11] = 1 // -1000 Points
            powerUpProbArray[12] = 5 // x2 Multiplier
            powerUpProbArray[13] = 5 // Reset Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[15] = 3 // Show All Bricks
            powerUpProbArray[16] = 3 // Hide Bricks
            powerUpProbArray[17] = 3 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 3 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 3 // Remove Indestructible Bricks
            powerUpProbArray[20] = 10 // Giga-Ball
            powerUpProbArray[21] = 1 // Undestructi-Ball
            powerUpProbArray[22] = 10 // Lasers
            powerUpProbArray[23] = 5 // Quicksand
            powerUpProbArray[24] = 5 // Mystery
            powerUpProbArray[25] = 5 // Backstop
            powerUpProbArray[26] = 7 // Increase Ball Size
            powerUpProbArray[27] = 7 // Decrease Ball Size
        case 13:
            powerUpProbArray[15] = 10 // Show All Bricks
            powerUpProbArray[16] = 10 // Hide Bricks
        case 14:
            powerUpProbArray[2] = 10 // Decrease Ball Speed
            powerUpProbArray[25] = 10 // Backstop
        case 17:
            powerUpProbFactor = 5

        // Nature Pack
        case 22:
            powerUpProbArray[0] = 7 // Get a Life
            powerUpProbArray[1] = 7 // Lose a Life
            powerUpProbArray[2] = 1 // Decrease Ball Speed
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[4] = 1 // Increase Paddle Size
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // +100 Points
            powerUpProbArray[9] = 3 // -100 Points
            powerUpProbArray[10] = 7 // +1000 Points
            powerUpProbArray[11] = 7 // -1000 Points
            powerUpProbArray[12] = 3 // x2 Multiplier
            powerUpProbArray[13] = 3 // Reset Multiplier
            powerUpProbArray[14] = 10 // Next Level
            powerUpProbArray[15] = 5 // Show All Bricks
            powerUpProbArray[16] = 5 // Hide Bricks
            powerUpProbArray[17] = 5 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 5 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 5 // Remove Indestructible Bricks
            powerUpProbArray[20] = 7 // Giga-Ball
            powerUpProbArray[21] = 7 // Undestructi-Ball
            powerUpProbArray[22] = 7 // Lasers
            powerUpProbArray[23] = 3 // Quicksand
            powerUpProbArray[24] = 3 // Mystery
            powerUpProbArray[25] = 3 // Backstop
            powerUpProbArray[26] = 1 // Increase Ball Size
            powerUpProbArray[27] = 1 // Decrease Ball Size
        case 23:
            powerUpProbArray[0] = 10 // Get a Life
        case 24:
            powerUpProbArray[0] = 10 // Get a Life
            powerUpProbArray[7] = 10 // Gravity
            powerUpProbArray[23] = 10 // Quicksand
        case 25:
            powerUpProbArray[20] = 7 // Giga-Ball
        case 29:
            powerUpProbArray[1] = 10 // Lose a Life

        // Urban Pack
        case 33:
            powerUpProbArray[23] = 10 // Quicksand
        case 37:
            powerUpProbArray[20] = 10 // Giga-Ball
            powerUpProbArray[22] = 10 // Lasers

        // Food Pack
        case 42:
            powerUpProbArray[0] = 1 // Get a Life
            powerUpProbArray[1] = 1 // Lose a Life
            powerUpProbArray[2] = 1 // Decrease Ball Speed
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[4] = 1 // Increase Paddle Size
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 1 // Sticky Paddle
            powerUpProbArray[7] = 1 // Gravity
            powerUpProbArray[8] = 1 // +100 Points
            powerUpProbArray[9] = 1 // -100 Points
            powerUpProbArray[10] = 1 // +1000 Points
            powerUpProbArray[11] = 1 // -1000 Points
            powerUpProbArray[12] = 1 // x2 Multiplier
            powerUpProbArray[13] = 1 // Reset Multiplier
            powerUpProbArray[14] = 1 // Next Level
            powerUpProbArray[15] = 1 // Show All Bricks
            powerUpProbArray[16] = 1 // Hide Bricks
            powerUpProbArray[17] = 1 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 1 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 1 // Remove Indestructible Bricks
            powerUpProbArray[20] = 1 // Giga-Ball
            powerUpProbArray[21] = 1 // Undestructi-Ball
            powerUpProbArray[22] = 1 // Lasers
            powerUpProbArray[23] = 1 // Quicksand
            powerUpProbArray[24] = 1 // Mystery
            powerUpProbArray[25] = 1 // Backstop
            powerUpProbArray[26] = 1 // Increase Ball Size
            powerUpProbArray[27] = 1 // Decrease Ball Size

        // Computer Pack
        case 51:
            powerUpProbArray[0] = 10 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[3] = 0 // Increase Ball Speed
            powerUpProbArray[5] = 0 // Decrease Paddle Size
            powerUpProbArray[7] = 0 // Gravity
            powerUpProbArray[9] = 0 // -100 Points
            powerUpProbArray[11] = 0 // -1000 Points
            powerUpProbArray[13] = 0 // Reset Multiplier
            powerUpProbArray[14] = 5 // Next Level
            powerUpProbArray[16] = 0 // Hide Bricks
            powerUpProbArray[18] = 0 // Reset Multi-Hit Bricks
            powerUpProbArray[21] = 0 // Undestructi-Ball
            powerUpProbArray[23] = 0 // Quicksand
            powerUpProbArray[27] = 0 // Decrease Ball Size
        case 56:
            powerUpProbArray[1] = 10 // Lose a Life
        case 57:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[2] = 0 // Decrease Ball Speed
            powerUpProbArray[4] = 0 // Increase Paddle Size
            powerUpProbArray[6] = 0 // Sticky Paddle
            powerUpProbArray[8] = 0 // +100 Points
            powerUpProbArray[10] = 0 // +1000 Points
            powerUpProbArray[12] = 0 // x2 Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[15] = 0 // Show All Bricks
            powerUpProbArray[17] = 0 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 10 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 0 // Remove Indestructible Bricks
            powerUpProbArray[20] = 0 // Giga-Ball
            powerUpProbArray[22] = 0 // Lasers
            powerUpProbArray[25] = 0 // Backstop
            powerUpProbArray[26] = 0 // Increase Ball Size

        // Body Pack
        case 61:
            powerUpProbArray[0] = 10 // Get a Life
        case 63:
            powerUpProbArray[1] = 10 // Lose a Life
        case 66:
            powerUpProbArray[15] = 10 // Show All Bricks
            powerUpProbArray[16] = 10 // Hide Bricks
        case 67:
            powerUpProbArray[17] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 10 // Reset Multi-Hit Bricks

        // World Pack
        case 71:
            powerUpProbArray[0] = 1 // Get a Life
            powerUpProbArray[1] = 1 // Lose a Life
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 5 // Sticky Paddle
            powerUpProbArray[7] = 5 // Gravity
            powerUpProbArray[8] = 3 // +100 Points
            powerUpProbArray[9] = 3 // -100 Points
            powerUpProbArray[10] = 1 // +1000 Points
            powerUpProbArray[11] = 1 // -1000 Points
            powerUpProbArray[12] = 5 // x2 Multiplier
            powerUpProbArray[13] = 5 // Reset Multiplier
            powerUpProbArray[14] = 0 // Next Level
            powerUpProbArray[15] = 3 // Show All Bricks
            powerUpProbArray[16] = 3 // Hide Bricks
            powerUpProbArray[17] = 3 // Clear Multi-Hit Bricks
            powerUpProbArray[18] = 3 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 3 // Remove Indestructible Bricks
            powerUpProbArray[20] = 1 // Giga-Ball
            powerUpProbArray[21] = 1 // Undestructi-Ball
            powerUpProbArray[22] = 1 // Lasers
            powerUpProbArray[23] = 5 // Quicksand
            powerUpProbArray[24] = 5 // Mystery
            powerUpProbArray[25] = 5 // Backstop
            powerUpProbArray[27] = 1 // Decrease Ball Size

        // Emoji Pack
        case 89:
            powerUpProbFactor = 25

        // Numbers Pack
        case 93:
            powerUpProbArray[19] = 0 // Remove Indestructible Bricks
            powerUpProbArray[22] = 0 // Lasers

        // Challenge Pack
        case 102:
            powerUpProbArray[25] = 10 // Backstop
        case 103:
            powerUpProbFactor = 2
        case 104:
            powerUpProbArray[22] = 0 // Lasers
        case 105:
            powerUpProbArray[22] = 0 // Lasers
        case 110:
            powerUpProbFactor = 0
        default:
            break
        }
        
        if numberOfLives >= 5 {
            powerUpProbArray[0] = 0 // Get a Life
        }
        if numberOfLevels <= 1 {
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[14] = 0 // Next Level
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
        // Increase probability of extra life if low on lives
        
        // Testing
//        powerUpProbArray[14] = 100 // Next Level
//        powerUpProbFactor = 2
        // Testing
        
        for i in powerUpProbArray {
            if i > totalStatsArray[0].powerUpUnlockedArray.count-1 {
                return
            }
            if totalStatsArray[0].powerUpUnlockedArray[i] == false {
                powerUpProbArray[i] = 0
            }
        }
        // Check if power-ups have been unlocked, if not, set their probability to zero
                        
        powerUpProbSum = powerUpProbArray.reduce(0, +)
    }
}




