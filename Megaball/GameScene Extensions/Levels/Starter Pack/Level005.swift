//
//  Level005.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel5() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 20 || i == 21 {
                    brick.texture = brickNormalTexture
                }
                if i == 18 || i == 19 {
                    if j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 16 || i == 17 {
                    if j <= 5 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 14 || i == 15 {
                    if j <= 4 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 13 {
                    if j >= 1 && j <= 4 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 11 || i == 12 {
                    if j >= 1 && j <= 3 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 10 {
                    if j >= 2 && j <= 3 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 8 || i == 9 {
                    if j >= 2 && j <= 4 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 7 {
                    if (j >= 3 && j <= 6) || j == 10 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 6 {
                    if (j >= 3 && j <= 6) || (j >= 8 && j <= 9) {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 5 {
                    if j >= 4 && j <= 8 {
                        brick.texture = brickNormalTexture
                    }
                }
                if i == 4 {
                    if j >= 5 && j <= 7 {
                        brick.texture = brickNormalTexture
                    }
                }
                // Normal bricks

                brick.position = CGPoint(x: -gameWidth/2 + brickWidth/2 + brickWidth*CGFloat(j), y: yBrickOffset - brickHeight*CGFloat(i))
                brickArray.append(brick)
            }
        }
        // Set brick textures and positions
        
        brickCreation(brickArray: brickArray)
        // Run brick creation
    }
}
