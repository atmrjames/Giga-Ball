//
//  Level006.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel6() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 || j == 3 {
                    brick.texture = brickIndestructible2Texture
                }
                // Indestructible bricks

                if j >= 4 {
                    brick.texture = brickNormalTexture
                }
                // Normal bricks
                
                 if i == 2 || i == 19 {
                     if j == 7 {
                         brick.texture = brickMultiHit1Texture
                     }
                 }
                 // Multi-hit bricks (1)
                
                if i == 3 || i == 18 {
                    if j == 6 || j == 8 {
                        brick.texture = brickMultiHit2Texture
                    }
                }
                // Multi-hit bricks (2)
                
                if i == 4 || i == 17 {
                    if j == 5 || j == 9 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                // Multi-hit bricks (3)
                
                if i == 0 || i == 21 {
                    if j == 5 || j == 7 || j == 9 {
                        brick.texture = brickNullTexture
                    }
                }
                if i == 1 || i == 20 {
                    if j == 4 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickNullTexture
                    }
                }
                if i == 2 || i == 19 {
                    if j == 5 || j == 9 {
                        brick.texture = brickNullTexture
                    }
                }
                if i == 3 || i == 18 {
                    if j == 4 || j == 10 {
                        brick.texture = brickNullTexture
                    }
                }
                // Null bricks

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
