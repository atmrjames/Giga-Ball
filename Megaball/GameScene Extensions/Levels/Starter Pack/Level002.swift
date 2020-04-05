//
//  Level002.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel2() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 1 || j == 9 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j >= 1 && j <= 9 && (i == 0 || i == 21) {
                    brick.texture = brickInvisibleTexture
                }
                
                if j >= 3 && j <= 7 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 4 || j == 6) && i == 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 3 || j == 7) && i == 3 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 5 && i == 3 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (j == 3 || j == 7) && i >= 4 && i <= 7 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 3 || j == 7) && i >= 8 && i <= 10 {
                    brick.texture = brickMultiHit2Texture
                }
                
                if (j == 3 || j == 7) && i >= 11 && i <= 13 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if (j == 3 || j == 7) && i >= 14 && i <= 17 {
                    brick.texture = brickMultiHit4Texture
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
