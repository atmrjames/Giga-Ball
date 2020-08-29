//
//  Level094.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel94() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 1 && j <= 4 && i >= 2 && i <= 9 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j >= 6 && j <= 9 && i >= 2 && i <= 9 {
                    brick.texture = brickMultiHit2Texture
                }
                
                if j >= 6 && j <= 9 && i >= 12 && i <= 19 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if j >= 1 && j <= 4 && i >= 12 && i <= 19 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if j >= 2 && j <= 3 && i >= 4 && i <= 7 {
                    brick.texture = brickNullTexture
                }
                if j >= 7 && j <= 8 && i >= 4 && i <= 7 {
                    brick.texture = brickNullTexture
                }
                if j >= 2 && j <= 3 && i >= 14 && i <= 17 {
                    brick.texture = brickNullTexture
                }
                if j >= 7 && j <= 8 && i >= 14 && i <= 17 {
                    brick.texture = brickNullTexture
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
