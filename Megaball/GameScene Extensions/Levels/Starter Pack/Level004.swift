//
//  Level004.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel4() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 0 || i == 16 {
                    if j >= 1 && j <= 9 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i >= 1 && i <= 15 {
                    if j == 1 || j == 9 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                // Invisible bricks

                if i == 13 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks
                
                if i == 3 {
                    if j == 3 || j == 5 || j == 7 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks
                
                if i >= 4 && i <= 6 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                if i == 8 {
                    if j == 5 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                // Multi-hit bricks (1)
                
                if i >= 7 && i <= 9 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit2Texture
                    }
                }
                if i == 7 || i == 9 {
                    if j == 5 {
                        brick.texture = brickMultiHit2Texture
                    }
                }
                // Multi-hit bricks (2)
                
                if i >= 10 && i <= 12 {
                    if j == 3 || j == 7 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                if i == 6 || i == 10 {
                    if j == 5 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                if i == 3 {
                    if j == 4 || j == 6 {
                        brick.texture = brickMultiHit3Texture
                    }
                }
                // Multi-hit bricks (3)

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
