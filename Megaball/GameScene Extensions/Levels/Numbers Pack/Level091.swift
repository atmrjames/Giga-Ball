//
//  Level091.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel91() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 5 && i >= 4 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 3 && j <= 7 && (i == 16 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 4 && i >= 6 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 3 && i >= 8 && i <= 9 {
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
