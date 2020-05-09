//
//  Level105.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel105() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 3 && j <= 7 && i >= 0 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if j >= 1 && j <= 9 && i >= 16 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if j >= 4 && j <= 6 && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if j >= 2 && j <= 8 && i >= 2 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 2 || j == 8) && i >= 12 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 1 || j == 9) && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 0 || j == 10) && i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                
                if j >= 1 && j <= 9 && i >= 4 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                if (j == 1 || j == 9) && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                if (j == 0 || j == 10) && i >= 12 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                
                if j >= 1 && j <= 9 && i >= 6 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenGigaball
                }
                
                if j >= 4 && j <= 6 && i >= 15 && i <= 16 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 4 && j <= 6 && i >= 20 && i <= 21 {
                    brick.texture = brickIndestructible2Texture
                }
                if ((j >= 1 && j <= 3) || (j >= 7 && j <= 9)) && i == 18 {
                    brick.texture = brickIndestructible2Texture
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
