//
//  Level026.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel26() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 2 && j <= 6 && i >= 4 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j == 0 && i >= 8 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 1 && i >= 5 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 2 && i >= 4 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 3 && i >= 3 && i <= 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j >= 3 && j <= 7 && i == 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                
                if j == 1 && i >= 9 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 7 && i >= 4 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 7 && i >= 17 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 8 && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 8 && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 9 && i == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j >= 3 && j <= 7 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 8 && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 9 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                
                if j == 5 && i == 21 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 5 && i >= 1 && i <= 4 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 6 && i == 0 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 6 && i >= 10 && i <= 14 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 7 && i >= 8 && i <= 9 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 7 && i >= 15 && i <= 16 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 8 && (i == 7 || i == 17) {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 9 && (i == 6 || i == 18) {
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
