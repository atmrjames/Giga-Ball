//
//  Level005.swift
//  Megaball
//
//  Created by James Harding on 05/03/2020.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel5() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (i == 15 || i == 14) && j == 5 {
                    brick.texture = brickIndestructible2Texture
                }
                if (i == 12 || i == 13) && j >= 4 && j <= 6  {
                    brick.texture = brickIndestructible2Texture
                }
                if (i == 10 || i == 11) && j >= 3 && j <= 7  {
                    brick.texture = brickIndestructible2Texture
                }
                if (i == 8 || i == 9) && j >= 2 && j <= 8  {
                    brick.texture = brickIndestructible2Texture
                }
                if (i == 6 || i == 7) && j >= 1 && j <= 9  {
                    brick.texture = brickIndestructible2Texture
                }
                
                if i == 8 && j >= 3 && j <= 7 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if i == 2 || i == 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if (i == 4 || i == 5) && j >= 1 && j <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                
                if (i == 6 || i == 7) && j >= 2 && j <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                
                if i == 8 && (j == 1 || j == 9) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 10 && (j == 2 || j == 8) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 12 && (j == 3 || j == 7) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 14 && (j == 4 || j == 6) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 16 && j == 5 {
                    brick.texture = brickInvisibleTexture
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
