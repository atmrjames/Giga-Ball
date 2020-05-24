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
        
//        powerUpProbArray[0] = 3 // Get a Life
//        powerUpProbArray[1] = 3 // Lose a Life
//        powerUpProbArray[2] = 10 // Decrease Ball Speed
//        powerUpProbArray[3] = 10 // Increase Ball Speed
//        powerUpProbArray[4] = 10 // Increase Paddle Size
//        powerUpProbArray[5] = 10 // Decrease Paddle Size
//        powerUpProbArray[6] = 7 // Sticky Paddle
//        powerUpProbArray[7] = 7 // Gravity
//        powerUpProbArray[8] = 7 // Bonus Points
//        powerUpProbArray[9] = 7 // Penalty Points
//        powerUpProbArray[10] = 7 // x2 Multiplier
//        powerUpProbArray[11] = 7 // Reset Multiplier
//        powerUpProbArray[12] = 1 // Next Level
//        powerUpProbArray[13] = 5 // Show All Bricks
//        powerUpProbArray[14] = 5 // Hide Bricks
//        powerUpProbArray[15] = 5 // Clear Multi-Hit Bricks
//        powerUpProbArray[16] = 5 // Reset Multi-Hit Bricks
//        powerUpProbArray[17] = 5 // Remove Indestructible Bricks
//        powerUpProbArray[18] = 3 // Giga-Ball
//        powerUpProbArray[19] = 3 // Undestructi-Ball
//        powerUpProbArray[20] = 3 // Lasers
//        powerUpProbArray[21] = 7 // Quicksand
//        powerUpProbArray[22] = 7 // Mystery
//        powerUpProbArray[23] = 7 // Backstop
//        powerUpProbArray[24] = 10 // Increase Ball Size
//        powerUpProbArray[25] = 10 // Decrease Ball Size
// default power-up allocation
        
        switch levelNumber {
        
        // Endless mode
        case 0:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[8] = 0 // Bonus Points
            powerUpProbArray[9] = 0 // Penalty Points
            powerUpProbArray[10] = 0 // x2 Multiplier
            powerUpProbArray[11] = 0 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[21] = 0 // Quicksand
            print("llama llama power-up prob alloaction: ", levelNumber)
            
        // Classic Pack
        case 1:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[6] = 0 // Sticky Paddle
            powerUpProbArray[7] = 0 // Gravity
            powerUpProbArray[8] = 0 // Bonus Points
            powerUpProbArray[9] = 0 // Penalty Points
            powerUpProbArray[10] = 0 // x2 Multiplier
            powerUpProbArray[11] = 0 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 0 // Show All Bricks
            powerUpProbArray[14] = 0 // Hide Bricks
            powerUpProbArray[15] = 0 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 0 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 0 // Remove Indestructible Bricks
            powerUpProbArray[18] = 0 // Giga-Ball
            powerUpProbArray[19] = 0 // Undestructi-Ball
            powerUpProbArray[20] = 0 // Lasers
            powerUpProbArray[21] = 0 // Quicksand
            powerUpProbArray[22] = 0 // Mystery
            powerUpProbArray[23] = 0 // Backstop
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 2:
            powerUpProbArray[2] = 5 // Decrease Ball Speed
            powerUpProbArray[3] = 5 // Increase Ball Speed
            powerUpProbArray[4] = 5 // Increase Paddle Size
            powerUpProbArray[5] = 5 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // Bonus Points
            powerUpProbArray[9] = 3 // Penalty Points
            powerUpProbArray[10] = 3 // x2 Multiplier
            powerUpProbArray[11] = 3 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 10 // Show All Bricks
            powerUpProbArray[14] = 10 // Hide Bricks
            powerUpProbArray[15] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 10 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 0 // Remove Indestructible Bricks
            powerUpProbArray[21] = 3 // Quicksand
            powerUpProbArray[22] = 3 // Mystery
            powerUpProbArray[23] = 3 // Backstop
            powerUpProbArray[24] = 5 // Increase Ball Size
            powerUpProbArray[25] = 5 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 3:
            powerUpProbArray[2] = 5 // Decrease Ball Speed
            powerUpProbArray[3] = 5 // Increase Ball Speed
            powerUpProbArray[4] = 5 // Increase Paddle Size
            powerUpProbArray[5] = 5 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // Bonus Points
            powerUpProbArray[9] = 3 // Penalty Points
            powerUpProbArray[10] = 3 // x2 Multiplier
            powerUpProbArray[11] = 3 // Reset Multiplier
            powerUpProbArray[13] = 3 // Show All Bricks
            powerUpProbArray[14] = 3 // Hide Bricks
            powerUpProbArray[15] = 7 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 7 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 10 // Remove Indestructible Bricks
            powerUpProbArray[18] = 5 // Giga-Ball
            powerUpProbArray[19] = 5 // Undestructi-Ball
            powerUpProbArray[20] = 5 // Lasers
            powerUpProbArray[21] = 3 // Quicksand
            powerUpProbArray[22] = 10 // Mystery
            powerUpProbArray[24] = 5 // Increase Ball Size
            powerUpProbArray[25] = 5 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 4:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 5:
            powerUpProbArray[21] = 10 // Quicksand
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 6:
            powerUpProbArray[18] = 0 // Giga-Ball
            powerUpProbArray[19] = 0 // Undestructi-Ball
            powerUpProbArray[20] = 0 // Lasers
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 7:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 8:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 9:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 10:
            powerUpProbArray[13] = 10 // Show All Bricks
            powerUpProbArray[14] = 10 // Hide Bricks
            powerUpProbArray[15] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 10 // Reset Multi-Hit Bricks
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Space Pack
        case 11:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[7] = 10 // Gravity
            powerUpProbArray[13] = 10 // Show All Bricks
            powerUpProbArray[14] = 10 // Hide Bricks
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 12:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[2] = 7 // Decrease Ball Speed
            powerUpProbArray[3] = 7 // Increase Ball Speed
            powerUpProbArray[4] = 7 // Increase Paddle Size
            powerUpProbArray[5] = 7 // Decrease Paddle Size
            powerUpProbArray[6] = 5 // Sticky Paddle
            powerUpProbArray[7] = 5 // Gravity
            powerUpProbArray[8] = 5 // Bonus Points
            powerUpProbArray[9] = 5 // Penalty Points
            powerUpProbArray[10] = 5 // x2 Multiplier
            powerUpProbArray[11] = 5 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 3 // Show All Bricks
            powerUpProbArray[14] = 3 // Hide Bricks
            powerUpProbArray[15] = 3 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 3 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 3 // Remove Indestructible Bricks
            powerUpProbArray[18] = 10 // Giga-Ball
            powerUpProbArray[19] = 1 // Undestructi-Ball
            powerUpProbArray[20] = 10 // Lasers
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[22] = 5 // Mystery
            powerUpProbArray[23] = 5 // Backstop
            powerUpProbArray[24] = 7 // Increase Ball Size
            powerUpProbArray[25] = 7 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 13:
            powerUpProbArray[13] = 10 // Show All Bricks
            powerUpProbArray[14] = 10 // Hide Bricks
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 14:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 15:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 16:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 17:
            powerUpProbArray[0] = 1 // Get a Life
            powerUpProbArray[1] = 1 // Lose a Life
            powerUpProbArray[2] = 1 // Decrease Ball Speed
            powerUpProbArray[4] = 1 // Increase Paddle Size
            powerUpProbArray[6] = 5 // Sticky Paddle
            powerUpProbArray[7] = 5 // Gravity
            powerUpProbArray[8] = 5 // Bonus Points
            powerUpProbArray[9] = 5 // Penalty Points
            powerUpProbArray[10] = 5 // x2 Multiplier
            powerUpProbArray[11] = 5 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 3 // Show All Bricks
            powerUpProbArray[14] = 3 // Hide Bricks
            powerUpProbArray[15] = 3 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 3 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 3 // Remove Indestructible Bricks
            powerUpProbArray[18] = 1 // Giga-Ball
            powerUpProbArray[19] = 1 // Undestructi-Ball
            powerUpProbArray[20] = 1 // Lasers
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[22] = 5 // Mystery
            powerUpProbArray[23] = 5 // Backstop
            powerUpProbArray[24] = 1 // Increase Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 18:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 19:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 20:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Nature Pack
        case 21:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 22:
            powerUpProbArray[0] = 7 // Get a Life
            powerUpProbArray[1] = 7 // Lose a Life
            powerUpProbArray[2] = 1 // Decrease Ball Speed
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[4] = 1 // Increase Paddle Size
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 3 // Sticky Paddle
            powerUpProbArray[7] = 3 // Gravity
            powerUpProbArray[8] = 3 // Bonus Points
            powerUpProbArray[9] = 3 // Penalty Points
            powerUpProbArray[10] = 3 // x2 Multiplier
            powerUpProbArray[11] = 3 // Reset Multiplier
            powerUpProbArray[12] = 10 // Next Level
            powerUpProbArray[13] = 5 // Show All Bricks
            powerUpProbArray[14] = 5 // Hide Bricks
            powerUpProbArray[15] = 5 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 5 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 5 // Remove Indestructible Bricks
            powerUpProbArray[18] = 7 // Giga-Ball
            powerUpProbArray[19] = 7 // Undestructi-Ball
            powerUpProbArray[20] = 7 // Lasers
            powerUpProbArray[21] = 3 // Quicksand
            powerUpProbArray[22] = 3 // Mystery
            powerUpProbArray[23] = 3 // Backstop
            powerUpProbArray[24] = 1 // Increase Ball Size
            powerUpProbArray[25] = 1 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 23:
            powerUpProbArray[0] = 10 // Get a Life
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 24:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 25:
            powerUpProbArray[18] = 7 // Giga-Ball
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 26:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 27:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 28:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 29:
            powerUpProbArray[1] = 10 // Lose a Life
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 30:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Nature Pack
        case 31:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 32:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 33:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 34:
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[23] = 10 // Backstop
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 35:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 36:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 37:
            powerUpProbArray[18] = 10 // Giga-Ball
            powerUpProbArray[20] = 10 // Lasers
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 38:
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[23] = 10 // Backstop
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 39:
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[23] = 10 // Backstop
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 40:
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[23] = 10 // Backstop
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Food Pack
        case 41:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 42:
            powerUpProbArray[0] = 1 // Get a Life
            powerUpProbArray[1] = 1 // Lose a Life
            powerUpProbArray[2] = 1 // Decrease Ball Speed
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[4] = 1 // Increase Paddle Size
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 1 // Sticky Paddle
            powerUpProbArray[7] = 1 // Gravity
            powerUpProbArray[8] = 1 // Bonus Points
            powerUpProbArray[9] = 1 // Penalty Points
            powerUpProbArray[10] = 1 // x2 Multiplier
            powerUpProbArray[11] = 1 // Reset Multiplier
            powerUpProbArray[12] = 1 // Next Level
            powerUpProbArray[13] = 1 // Show All Bricks
            powerUpProbArray[14] = 1 // Hide Bricks
            powerUpProbArray[15] = 1 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 1 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 1 // Remove Indestructible Bricks
            powerUpProbArray[18] = 1 // Giga-Ball
            powerUpProbArray[19] = 1 // Undestructi-Ball
            powerUpProbArray[20] = 1 // Lasers
            powerUpProbArray[21] = 1 // Quicksand
            powerUpProbArray[22] = 1 // Mystery
            powerUpProbArray[23] = 1 // Backstop
            powerUpProbArray[24] = 1 // Increase Ball Size
            powerUpProbArray[25] = 1 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 43:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 44:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 45:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 46:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 47:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 48:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 49:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 50:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Computer Pack
        case 51:
            powerUpProbArray[0] = 10 // Get a Life
            powerUpProbArray[1] = 0 // Lose a Life
            powerUpProbArray[3] = 0 // Increase Ball Speed
            powerUpProbArray[5] = 0 // Decrease Paddle Size
            powerUpProbArray[7] = 0 // Gravity
            powerUpProbArray[9] = 0 // Penalty Points
            powerUpProbArray[11] = 0 // Reset Multiplier
            powerUpProbArray[12] = 5 // Next Level
            powerUpProbArray[14] = 0 // Hide Bricks
            powerUpProbArray[16] = 0 // Reset Multi-Hit Bricks
            powerUpProbArray[19] = 0 // Undestructi-Ball
            powerUpProbArray[21] = 0 // Quicksand
            powerUpProbArray[25] = 0 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 52:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 53:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 54:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 55:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 56:
            powerUpProbArray[1] = 10 // Lose a Life
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 57:
            powerUpProbArray[0] = 0 // Get a Life
            powerUpProbArray[2] = 0 // Decrease Ball Speed
            powerUpProbArray[4] = 0 // Increase Paddle Size
            powerUpProbArray[6] = 0 // Sticky Paddle
            powerUpProbArray[8] = 0 // Bonus Points
            powerUpProbArray[10] = 0 // x2 Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 0 // Show All Bricks
            powerUpProbArray[15] = 0 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 10 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 0 // Remove Indestructible Bricks
            powerUpProbArray[18] = 0 // Giga-Ball
            powerUpProbArray[20] = 0 // Lasers
            powerUpProbArray[23] = 0 // Backstop
            powerUpProbArray[24] = 0 // Increase Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 58:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 59:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 60:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Body Pack
        case 61:
            powerUpProbArray[0] = 10 // Get a Life
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 62:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 63:
            powerUpProbArray[1] = 10 // Lose a Life
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 64:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 65:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 66:
            powerUpProbArray[13] = 10 // Show All Bricks
            powerUpProbArray[14] = 10 // Hide Bricks
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 67:
            powerUpProbArray[15] = 10 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 10 // Reset Multi-Hit Bricks
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 68:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 69:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 70:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Geography Pack
        case 71:
            powerUpProbArray[0] = 1 // Get a Life
            powerUpProbArray[1] = 1 // Lose a Life
            powerUpProbArray[3] = 1 // Increase Ball Speed
            powerUpProbArray[5] = 1 // Decrease Paddle Size
            powerUpProbArray[6] = 5 // Sticky Paddle
            powerUpProbArray[7] = 5 // Gravity
            powerUpProbArray[8] = 5 // Bonus Points
            powerUpProbArray[9] = 5 // Penalty Points
            powerUpProbArray[10] = 5 // x2 Multiplier
            powerUpProbArray[11] = 5 // Reset Multiplier
            powerUpProbArray[12] = 0 // Next Level
            powerUpProbArray[13] = 3 // Show All Bricks
            powerUpProbArray[14] = 3 // Hide Bricks
            powerUpProbArray[15] = 3 // Clear Multi-Hit Bricks
            powerUpProbArray[16] = 3 // Reset Multi-Hit Bricks
            powerUpProbArray[17] = 3 // Remove Indestructible Bricks
            powerUpProbArray[18] = 1 // Giga-Ball
            powerUpProbArray[19] = 1 // Undestructi-Ball
            powerUpProbArray[20] = 1 // Lasers
            powerUpProbArray[21] = 5 // Quicksand
            powerUpProbArray[22] = 5 // Mystery
            powerUpProbArray[23] = 5 // Backstop
            powerUpProbArray[25] = 1 // Decrease Ball Size
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 72:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 73:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 74:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 75:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 76:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 77:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 78:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 79:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 80:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Emoji Pack
        case 81:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 82:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 83:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 84:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 85:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 86:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 87:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 88:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 89:
            powerUpProbFactor = 25
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 90:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Numbers Pack
        case 91:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 92:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 93:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 94:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 95:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 96:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 97:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 98:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 99:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 100:
            print("llama llama power-up prob alloaction: ", levelNumber)

        // Challenge Pack
        case 101:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 102:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 103:
            powerUpProbFactor = 2
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 104:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 105:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 106:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 107:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 108:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 109:
            print("llama llama power-up prob alloaction: ", levelNumber)
        case 110:
            powerUpProbFactor = 0
            print("llama llama power-up prob alloaction: ", levelNumber)

        default:
            break
        }
                
        powerUpProbSum = powerUpProbArray.reduce(0, +)
    }
}




