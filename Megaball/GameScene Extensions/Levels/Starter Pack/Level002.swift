//
//  Level002.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel2() {
        
        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 || j == 10 {
                    // Normal bricks
                    brick.texture = brickNormalTexture
                }
                if j == 1 || j == 9 {
                    // Invisible bricks
                    brick.texture = brickInvisibleTexture
                }
                if j == 3 || j == 7 {
                    // Double bricks
                    brick.texture = brickMultiHit1Texture
                }
                if j == 5 {
                    if i == 0 || i == 1 || i == 5 || i == 6 || i == 10 || i == 11 || i == 15 || i == 16 || i == 20 || i == 21 {
                        // Indestructible bricks
                        brick.texture = brickIndestructible1Texture
                    } else {
                        // Null bricks
                        brick.texture = brickNullTexture
                    }
                }
                if j == 2 || j == 4 || j == 6 || j == 8 {
                    // Null bricks
                    brick.texture = brickNullTexture
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
