//
//  Level051.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel51() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 0 || j == 10) && i >= 2 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 0 || j == 10) && i >= 16 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 3 || j == 7) && i >= 2 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (i == 0 || i == 1 || i == 20 || i == 21) && j >= 1 && j <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 0 || i == 1 || i == 20 || i == 21) && j >= 8 && j <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 6 || i == 7 || i == 14 || i == 15) && j >= 1 && j <= 9 {
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
