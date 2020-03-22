//
//  Level004.swift
//  Megaball
//
//  Created by James Harding on 05/03/2020.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel4() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 19 || i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 17 && j >= 0 && j <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i >= 14 && i <= 16 && j >= 0 && j <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (i == 12 || i == 13) && j >= 0 && j <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (i == 10 || i == 11) && j >= 0 && j <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 9 && j >= 0 && j <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 8 && j >= 1 && j <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (i == 6 || i == 7) && j >= 1 && j <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 5 && j >= 2 && j <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 4 && j >= 3 && j <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 3 && j >= 4 && j <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 2 && j >= 6 && j <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 1 && j >= 7 && j <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 5 && j >= 9 && j <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i == 6 && j == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if i == 14 && j >= 4 && j <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if i == 15 && j >= 5 && j <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if i == 16 && j == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if i == 14 && j >= 6 && j <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if i == 13 && j >= 6 && j <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if i == 12 && j == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                
                if i == 12 && j == 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenGigaball
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
