//
//  Level022.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel22() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 && i >= 12 && i <= 14 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 1 && i >= 9 && i <= 11 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 2 && i >= 7 && i <= 9 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 3 && i >= 5 && i <= 7 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 4 && i >= 4 && i <= 6 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 5 && i >= 3 && i <= 5 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 6 || j == 7) && i >= 2 && i <= 4 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 8 || j == 9) && i >= 1 && i <= 3 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 10 && i >= 0 && i <= 2 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j == 0 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 1 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 2 && i >= 10 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 3 && i >= 8 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 4 && i >= 7 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 5 && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 6 || j == 7) && i >= 5 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 8 || j == 9) && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 10 && i >= 3 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j == 0 && i >= 18 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 1 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 2 && i >= 13 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 3 && i >= 11 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 4 && i >= 10 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 5 && i >= 9 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if (j == 6 || j == 7) && i >= 8 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if (j == 8 || j == 9) && i >= 7 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 10 && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                
                if j == 0 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 1 && i >= 18 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 2 && i >= 16 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 3 && i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 4 && i >= 13 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 5 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j == 6 || j == 7) && i >= 11 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j == 8 || j == 9) && i >= 10 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 10 && i >= 9 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j == 1 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 2 && i >= 19 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 3 && i >= 17 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 4 && i >= 16 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 5 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (j == 6 || j == 7) && i >= 14 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (j == 8 || j == 9) && i >= 13 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 10 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if j == 3 && i >= 20 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 4 && i >= 19 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 5 && i >= 18 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 6 || j == 7) && i >= 17 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 8 || j == 9) && i >= 16 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 10 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
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
