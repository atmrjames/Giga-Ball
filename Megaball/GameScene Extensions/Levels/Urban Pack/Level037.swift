//
//  Level037.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel37() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 4 && i >= 11 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 1 && j <= 4 && i == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 2 && j <= 4 && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 3 && j <= 4 && i == 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j == 4 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                
                if j >= 6 && j <= 10 && i >= 3 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j >= 7 && j <= 9 && i == 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                if j == 8 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                
                if j == 8 && i == 0 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 7 || j == 9) && (i == 4 || i == 5) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 3 || j == 7 || j == 9) && (i == 8 || i == 9) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 1 || j == 3 || j == 7 || j == 9) && (i == 12 || i == 13 || i == 16 || i == 17 || i == 20 || i == 21) {
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
