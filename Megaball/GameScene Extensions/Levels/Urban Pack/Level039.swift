//
//  Level039.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel39() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i >= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if (j == 1 || j == 9) && i <= 17 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 1 || j == 9) && i >= 18 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if ((j >= 0 && j <= 2) || (j >= 8 && j <= 10)) && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if (j <= 2 || j >= 8) && (i == 13 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j >= 3 && j <= 7 && (i == 12 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if (j == 2 || j == 8) && i >= 2 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 3 || j == 7) && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (j == 4 || j == 6) && i >= 9 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j == 5 && i == 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
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
