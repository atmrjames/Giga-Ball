//
//  Level048.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel48() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 1 && j <= 9 && i == 9 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j >= 1 && j <= 9 && i == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                
                if j >= 1 && j <= 9 && i == 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                
                if j >= 1 && j <= 9 && i >= 12 && i <= 14 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j >= 1 && j <= 9 && i >= 15 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                if j >= 2 && j <= 8 && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                if j >= 1 && j <= 9 && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                if j >= 2 && j <= 8 && i == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                if j >= 3 && j <= 7 && i == 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                
                if (j == 3 || j == 5 || j == 7) && (i == 4 || i == 8) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 2 || j == 4 || j == 6 || j == 8) && (i == 6) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 1 || j == 9) && i == 8 {
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
