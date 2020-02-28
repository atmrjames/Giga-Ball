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
                
                if (j == 0 || j == 10) && i >= 11 && i <= 16 {
                   brick.texture = brickNormalTexture
               }
               if (j == 1 || j == 9) && i >= 9 && i <= 12 {
                   brick.texture = brickNormalTexture
               }
               if (j == 2 || j == 8) && i >= 3 && i <= 4 {
                   brick.texture = brickNormalTexture
               }
               if (j == 2 || j == 8) && i >= 7 && i <= 16 {
                   brick.texture = brickNormalTexture
               }
               if (j == 3 || j == 7) && i >= 5 && i <= 14 {
                   brick.texture = brickNormalTexture
               }
               if (j == 3 || j == 7) && i >= 17 && i <= 18 {
                   brick.texture = brickNormalTexture
               }
               if j >= 4 && j <= 6 && i >= 7 && i <= 14 {
                   brick.texture = brickNormalTexture
               }
               
               if (j == 3 || j == 7) && (i == 9 || i == 10) {
                   brick.texture = brickMultiHit1Texture
               }

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
