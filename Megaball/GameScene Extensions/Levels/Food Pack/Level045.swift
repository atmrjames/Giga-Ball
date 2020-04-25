//
//  Level045.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel45() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 2 && j <= 8 && i >= 7 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 3 && j <= 7 && i >= 11 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 4 && j <= 6 && i == 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j == 5 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 4 && j <= 6 && i >= 16 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if (j == 3 || j == 7) && i >= 19 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                
                if j == 5 && i >= 17 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if j >= 2 && j <= 8 && i == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 3 && j <= 7 && i >= 4 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 4 && j <= 6 && i == 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 5 && i >= 1 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j == 5 && i >= 3 && i <= 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j >= 4 && j <= 6 && i == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j >= 3 && j <= 7 && i == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j == 5 && i >= 5 && i <= 6 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 1 || j == 9) && i == 4 {
                    brick.texture = brickInvisibleTexture
                }
                if (j == 2 || j == 8) && i == 2 {
                    brick.texture = brickInvisibleTexture
                }
                if (j == 3 || j == 7) && i == 0 {
                    brick.texture = brickInvisibleTexture
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
