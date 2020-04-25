//
//  Level055.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel55() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 0 || j == 9) && ((i >= 0 && i <= 4) || (i >= 17 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 1 || j == 8) && ((i >= 0 && i <= 2) || (i >= 19 && i <= 21) || (i >= 5 && i <= 16)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 10 && ((i >= 0 && i <= 8) || (i >= 13 && i <= 21)){
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 2 && j <= 7 && i >= 3 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 5 && i >= 5 && i <= 12 {
                    brick.texture = brickNullTexture
                }
                if j >= 3 && j <= 4 && i >= 11 && i <= 12 {
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
