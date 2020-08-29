//
//  Level012.swift
//  Megaball
//
//  Created by James Harding on 04/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel12() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 0 || j == 10) && i >= 8 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if (j == 1 || j == 9) && ((i >= 6 && i <= 7) || (i >= 12 && i <= 15)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if (j == 2 || j == 8) && ((i >= 0 && i <= 1) || (i >= 4 && i <= 9)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if (j == 3 || j == 7) && i >= 2 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if (j == 3 || j == 7) && i >= 6 && i <= 7 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 4 || j == 6) && ((i >= 4 && i <= 11) || (i >= 14 && i <= 15)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if j == 5 && i >= 2 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                
                if (j == 3 || j == 7) && ((i >= 16 && i <= 17) || (i >= 20 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 2 || j == 8) && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
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
