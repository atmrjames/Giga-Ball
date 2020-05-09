//
//  Level088.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel88() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 && i >= 4 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 1 && i >= 3 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 2 && i >= 3 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 3 && i >= 9 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 4 && i >= 12 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 5 && i >= 13 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 6 && i >= 14 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 7 && i >= 15 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 8 && i >= 16 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                if j == 9 && i >= 17 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurpleDark
                }
                
                if j == 3 && i >= 4 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 4 && i >= 8 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 5 && i >= 11 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 6 && i >= 12 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 7 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 8 && i >= 13 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 9 && i >= 14 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 10 && i >= 16 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                
                if j == 0 && i >= 2 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 1 && i >= 0 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 2 && i >= 0 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 3 && i >= 2 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                                
                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                
                if brick.texture == brickInvisibleTexture {
                    brick.isHidden = true
                }
                
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
