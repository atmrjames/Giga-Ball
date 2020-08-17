//
//  Level103.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel103() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 10 && i >= 0 && i <= 2 {
                    brick.texture = brickMultiHit1Texture
                }
                if j >= 0 && j <= 10 && i >= 3 && i <= 6 {
                    brick.texture = brickMultiHit2Texture
                }
                if j >= 0 && j <= 10 && i >= 7 && i <= 10 {
                    brick.texture = brickMultiHit3Texture
                }
                if j >= 0 && j <= 10 && i >= 11 && i <= 14 {
                    brick.texture = brickMultiHit4Texture
                }
                if j >= 0 && j <= 10 && i >= 15 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 3 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 7 {
                    brick.texture = brickMultiHit2Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 11 {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 15 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 2 {
                    brick.texture = brickMultiHit2Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 6 {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 10 {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if i >= 18 {
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
