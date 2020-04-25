//
//  Level076.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel76() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 6 && i >= 0 && i <= 9 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 1 && j <= 9 && i >= 10 && i <= 11 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 2 && j <= 8 && i >= 12 && i <= 13 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 3 && j <= 7 && i >= 18 && i <= 19 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 3 && j <= 8 && i >= 14 && i <= 17 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 4 && j <= 6 && i >= 0 && i <= 1 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 4 && j <= 6 && i >= 20 && i <= 21 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 7 && i >= 2 && i <= 3 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 8 && j <= 9 && i >= 4 && i <= 5 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 9 && i >= 14 && i <= 19 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 10 && i >= 6 && i <= 9 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 10 && i >= 12 && i <= 17 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j >= 1 && j <= 3 && i >= 0 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 0 && j <= 6 && i >= 2 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 1 && j <= 9 && i >= 6 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 4 && j <= 7 && i >= 4 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 3 && j <= 8 && i >= 10 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 3 && (i == 12 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 7 && i >= 12 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 4 && j <= 6 && i >= 14 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 5 && i >= 20 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 10 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 9 && i >= 16 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
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
