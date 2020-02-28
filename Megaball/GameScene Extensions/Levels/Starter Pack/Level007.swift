//
//  Level007.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel7() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNormalTexture
                
                if i == 0 || i == 21 {
                    if j <= 3 || j >= 7 {
                        brick.texture = brickNullTexture
                    }
                }
                if i == 1 || i == 20 {
                    if j <= 2 || j >= 8 {
                        brick.texture = brickNullTexture
                    }
                }
                if i == 2 || i == 19 || i == 3 || i == 18 {
                    if j <= 1 || j >= 9 {
                        brick.texture = brickNullTexture
                    }
                }
                if (i >= 4 && i <= 7) || (i >= 14 && i <= 17)  {
                    if j == 0 || j == 10 {
                        brick.texture = brickNullTexture
                    }
                }
                // Null bricks
                
                if i == 5 || i == 16 {
                    if j == 5 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i == 6 || i == 15 {
                    if j >= 4 && j <= 6 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i == 7 || i == 14 {
                    if j >= 3 && j <= 7 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i == 8 || i == 13 || i == 9 || i == 12 {
                    if j >= 2 && j <= 8 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                if i == 10 || i == 11 {
                    if j >= 1 && j <= 9 {
                        brick.texture = brickInvisibleTexture
                    }
                }
                // Invisible bricks
                
                if j >= 3 && j <= 7 {
                    if i == 8 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if j == 3 || j == 5 || j == 7 {
                    if i >= 9 && i <= 11 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                if j == 3 || j == 7 {
                    if i >= 12 && i <= 13 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks
                
                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
