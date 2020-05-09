//
//  Level090.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel90() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 && i >= 18 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 1 && i >= 14 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 2 && i >= 10 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 3 && i >= 6 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if (j == 4 || j == 6) && i >= 2 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 5 && i >= 0 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 6 && i >= 2 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 7 && i >= 4 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 8 && i >= 8 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 9 && i >= 12 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 10 && i >= 16 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                
                if j >= 3 && j <= 8 && i >= 9 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 4 || j == 7) && i >= 8 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 3 && j <= 8 && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 4 && j <= 7 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 5 && j <= 6 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 4 || j == 7) && i >= 9 && i <= 11 {
                    brick.texture = brickNullTexture
                }
                
                if j >= 4 && j <= 6 && i == 21 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 8 && j <= 10 && i == 20 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 1 && j <= 3 && i == 18 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 7 && j <= 9 && i == 16 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 2 && j <= 3 && i == 14 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 4 && j <= 6 && i == 13 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 8 && i == 12 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 4 && i == 6 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 5 && i == 5 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 6 && i == 4 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 5 && i == 2 {
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
