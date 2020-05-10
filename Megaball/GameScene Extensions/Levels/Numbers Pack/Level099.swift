//
//  Level099.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel99() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNormalTexture
                brick.color = brickGreenDark
                
                if j >= 4 && j <= 6 && (i == 4 || i == 5 || i == 10 || i == 11 || i == 16 || i == 17) {
                    brick.texture = brickNullTexture
                }
                if j == 3 && i >= 6 && i <= 9 {
                    brick.texture = brickNullTexture
                }
                if j == 3 && i >= 14 && i <= 15 {
                    brick.texture = brickNullTexture
                }
                if j == 7 && i >= 6 && i <= 15 {
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
