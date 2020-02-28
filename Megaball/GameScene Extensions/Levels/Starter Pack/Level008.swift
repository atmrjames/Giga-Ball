//
//  Level008.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel8() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 21 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 20 || i == 15 {
                    if j >= 4 && j <= 6 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i >= 16 && i <= 19 {
                    if j == 5 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i == 13 || i == 14 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i >= 10 && i <= 12 {
                    if j >= 2 && j <= 8 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if i >= 5 && i <= 9 {
                    if j >= 1 && j <= 9 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks
                
                if i == 1 || i == 13 {
                    if j == 4 || j == 5 || j == 6 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 2 || i == 3 || (i >= 10 && i <= 12) {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i >= 4 && i <= 9 {
                    if j >= 2 && j <= 8 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks
                
                if i == 0 {
                    if j == 5 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                if i == 14 {
                    if j >= 4 && j <= 6 {
                        brick.texture = brickMultiHit1Texture
                    }
                }
                // Multi-hit bricks (1)
                
                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
