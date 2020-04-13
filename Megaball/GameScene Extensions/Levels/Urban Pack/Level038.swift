//
//  Level038.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel38() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 10 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 1 && j <= 9 && i == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 3 && j <= 7 && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 4 && j <= 6 && i == 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j == 5 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                
                if j >= 1 && j <= 9 && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j >= 2 && j <= 8 && i >= 11 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j == 5 && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if (j == 3 || j == 5 || j == 7) && i >= 11 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if j == 5 && i >= 16 && i <= 19 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j >= 6 && j <= 7 && i >= 4 && i <= 5 {
                    brick.texture = brickMultiHit1Texture
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
