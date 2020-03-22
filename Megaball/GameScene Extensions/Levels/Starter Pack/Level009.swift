//
//  Level009.swift
//  Megaball
//
//  Created by James Harding on 28/11/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel9() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 0 || i == 1 || i == 20 || i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if i == 4 || i == 5 || i == 16 || i == 17 {
                    brick.texture = brickInvisibleTexture
                }
                
                if i == 8 || i == 13 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (i == 10 || i == 11) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickIndestructible1Texture
                }

                if brick.texture == brickNormalTexture {
                    brick.colorBlendFactor = 1.0
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
