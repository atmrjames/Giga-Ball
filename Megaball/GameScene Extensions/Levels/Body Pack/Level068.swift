//
//  Level068.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel68() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i <= 9 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 0 || j == 10) && i >= 12 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 1 || j == 9) && i >= 6 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 2 || j == 4 || j == 6 || j == 8) && i >= 4 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 3 || j == 7) && i >= 3 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 4 || j == 6) && i == 21 {
                    brick.texture = brickNullTexture
                }
                if j == 5 && i >= 8 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if j >= 1 && j <= 9 && i >= 12 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if j >= 2 && j <= 3 && i >= 6 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if j >= 7 && j <= 8 && i >= 6 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if j >= 4 && j <= 6 && i >= 9 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if (j == 4 || j == 6) && i == 8 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if (j == 2 || j == 3 || j == 7 || j == 8) && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                if (j == 3 || j == 7) && i >= 4 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickWhite
                }
                
                if j == 5 && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j >= 6 && j <= 7 && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickGreyLight
                }
                if j == 8 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color =  brickGreyLight
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
