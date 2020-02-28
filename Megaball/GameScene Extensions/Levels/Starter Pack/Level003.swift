//
//  Level003.swift
//  Megaball
//
//  Created by James Harding on 28/11/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel3() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 0 || i == 1 || i == 20 || i == 21 {
                    // Normal bricks
                    brick.texture = brickNormalTexture
                }
                if i == 2 || i == 3 || i == 18 || i == 19 {
                    // Invisible bricks
                    brick.texture = brickInvisibleTexture
                }
                if i == 6 || i == 7 || i == 14 || i == 15 {
                    // Double bricks
                    brick.texture = brickMultiHit1Texture
                }
                if i == 4 || i == 5 || i == 8 || i == 9 || i == 12 || i == 13 || i == 16 || i == 17 {
                    // Null bricks
                    brick.texture = brickNullTexture
                }
                if i == 10 || i == 11 {
                    if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                        // Indestructible bricks
                        brick.texture = brickIndestructible2Texture
                    } else {
                        // Null bricks
                        brick.texture = brickNullTexture
                    }
                }

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
