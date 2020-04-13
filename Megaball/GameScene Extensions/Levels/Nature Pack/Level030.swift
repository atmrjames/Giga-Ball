//
//  Level030.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel30() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 5 && i >= 5 && i <= 16 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if (j == 0 || j == 10) && i >= 5 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 1 || j == 9) && i >= 3 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 1 || j == 9) && i >= 16 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 2 || j == 8) && i >= 0 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 3 || j == 7) && i >= 1 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 4 || j == 6) && i >= 7 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                
                if (j == 1 || j == 9) && i >= 7 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 2 || j == 8) && i >= 3 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 2 || j == 8) && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 3 || j == 7) && i >= 2 && i <= 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 3 || j == 7) && i >= 16 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 4 || j == 6) && i >= 5 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 4 || j == 6) && i >= 15 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if (j == 2 || j == 8) && i >= 8 && i <= 9 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 2 || j == 8) && i >= 17 && i <= 18 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 3 || j == 7) && i >= 5 && i <= 6 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 3 || j == 7) && i >= 12 && i <= 13 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 4 || j == 6) && i >= 9 && i <= 10 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 1 || j == 9) && i >= 5 && i <= 6 {
                    brick.texture = brickInvisibleTexture
                }
                if (j == 3 || j == 7) && i >= 14 && i <= 15 {
                    brick.texture = brickInvisibleTexture
                }
                
                if (j == 4 || j == 6) && i >= 2 && i <= 4 {
                    brick.texture = brickIndestructible1Texture
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
