//
//  Level028.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel28() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 2 && i >= 12 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 1 && j <= 3 && i >= 6 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 2 && j <= 7 && i >= 2 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 4 && j <= 5 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 3 && j <= 6 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 4 && i == 0 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 5 && i >= 2 && i <= 3 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j >= 7 && j <= 8 && i >= 3 && i <= 5 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 9 && i == 4 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j >= 6 && j <= 8 && i >= 16 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 7 && i >= 15 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 5 && j <= 9 && i >= 19 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if (j == 6 || j == 8) && i == 17 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j == 7 && i == 18 {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 6 || j == 8) && i == 21 {
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
