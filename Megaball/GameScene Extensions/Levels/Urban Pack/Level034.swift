//
//  Level034.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel34() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 2 && j <= 8 && i >= 6 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 4 && j <= 6 && i >= 3 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j >= 0 && j <= 10 && i >= 19 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if ((j >= 2 && j <= 4) || (j >= 6 && j <= 8)) && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                
                if (j == 3 || j == 7) && i >= 16 && i <= 17 {
                    brick.texture = brickNullTexture
                }
                if (j == 3 || j == 5 || j == 7) && i >= 11 && i <= 12 {
                    brick.texture = brickNullTexture
                }
                if j == 5 && i >= 6 && i <= 7 {
                    brick.texture = brickNullTexture
                }
                
                if j == 5 && i >= 15 && i <= 18 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 1 || j == 9) && i >= 8 && i <= 10 {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 2 || j == 8) && i >= 6 && i <= 8 {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 3 || j == 7) && i >= 4 && i <= 6 {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 4 || j == 6) && i >= 2 && i <= 4 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 5 && i >= 1 && i <= 2 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 8 && i >= 3 && i <= 5 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 8 && i == 2 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 8 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j >= 7 && j <= 9 && i == 0 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if i == 19 && (j == 0 || j == 1 || j == 9 || j == 10) {
                    brick.texture = brickNullTexture
                }
                if i == 20 && (j == 0 || j == 10) {
                    brick.texture = brickNullTexture
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
