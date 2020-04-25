//
//  Level059.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel59() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 9 && i >= 5 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                
                if j >= 1 && j <= 7 && i >= 7 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if j >= 5 && j <= 8 && i >= 7 && i <= 8 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 6 && j <= 8 && i >= 9 && i <= 10 {
                    brick.texture = brickInvisibleTexture
                }
                if j >= 7 && j <= 8 && i >= 11 && i <= 12 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 8 && i >= 13 && i <= 14 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j == 10 && i >= 9 && i <= 12 {
                    brick.texture = brickIndestructible1Texture
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
