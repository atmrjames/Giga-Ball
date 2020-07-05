//
//  Level075.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel75() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if i >= 18 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                
                if j == 5 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 6 && i >= 3 && i <= 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 4 && i >= 3 && i <= 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j == 5 && i >= 4 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j == 6 && i >= 5 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j == 7 && i >= 6 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if j == 3 && i >= 6 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j == 4 && i >= 5 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if j == 0 && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 1 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 2 && i >= 9 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 3 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 4 && i >= 7 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }

                if j == 5 && i >= 9 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 10 && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 9 && i >= 12 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 8 && i >= 9 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 7 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 6 && i >= 7 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j >= 0 && j <= 3 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 3 && i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 4 && i >= 13 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j == 5 && i >= 12 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j >= 8 && j <= 10 && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 7 && i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 6 && i >= 13 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                
                if j == 4 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 5 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 5 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 6 && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
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
