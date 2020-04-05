//
//  Level008.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
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
                
                if j == 0 || j == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 1 || j == 9 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j == 3 || j == 7 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j == 5 && (i == 0 || i == 1 || i == 5 || i == 6 || i == 10 || i == 11 || i == 15 || i == 16 || i == 20 || i == 21) {
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
