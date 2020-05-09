//
//  Level097.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel97() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (i == 6 || i == 7 || i == 14 || i == 15) {
                    brick.texture = brickInvisibleTexture
                }
                
                if (j == 1 || j == 5) && i >= 6 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                if (j == 2 || j == 4) && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                if j == 3 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
                }
                if (j == 7 || j == 9) && i >= 6 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenSI
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
