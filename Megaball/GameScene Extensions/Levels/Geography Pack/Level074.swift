//
//  Level074.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel74() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 5 && i >= 0 && i <= 3 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 5 && i >= 18 && i <= 21 {
                    brick.texture = brickIndestructible1Texture
                }
                if j >= 0 && j <= 1 && i >= 10 && i <= 11 {
                    brick.texture = brickIndestructible1Texture
                }
                if j >= 9 && j <= 10 && i >= 10 && i <= 11 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 3 && i >= 10 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 4 && i >= 11 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 5 && i >= 11 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 6 && i >= 11 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 7 && i == 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if j == 7 && i >= 2 && i <= 11 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 6 && i >= 4 && i <= 10 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 5 && i >= 6 && i <= 10 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 4 && i >= 8 && i <= 10 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 3 && i == 9 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j == 5 && i >= 10 && i <= 11 {
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
