//
//  Level000.swift
//  Megaball
//
//  Created by James Harding on 19/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func loadLevel0() {
        endlessMode = true
        endlessMoveInProgress = false
        endlessDepth = 0

        life.isHidden = true
        livesLabel.fontSize = fontSize*1.25
        livesLabel.horizontalAlignmentMode = .center
        livesLabel.position.x = 0
        livesLabel.position.y = life.position.y-2
        livesLabel.text = "0 m"
        // Setup lives label to show depth
        
        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i == 0 || i == 1 || i == 5 || i == 16 || i == 20 || i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if i == 6 || i == 15 {
                    if j == 0 || j == 1 || j == 4 || j == 5 || j == 6 || j == 9 || j == 10 {
                        brick.texture = brickNormalTexture
                        brick.color = brickWhite
                    }
                }
                if i == 7 || i == 14 {
                    if j == 0 || j == 2 || j == 4 || j == 5 || j == 6 || j == 8 || j == 10 {
                        brick.texture = brickNormalTexture
                        brick.color = brickWhite
                    }
                }
                if i == 8 || i == 13 {
                    if j == 0 || j == 2 || j == 3 || j == 5 || j == 7 || j == 8 || j == 10 {
                        brick.texture = brickNormalTexture
                        brick.color = brickWhite
                    }
                }
                if i == 9 || i == 12 {
                    if j == 1 || j == 2 || j == 3 || j == 5 || j == 7 || j == 8 || j == 9 {
                        brick.texture = brickNormalTexture
                        brick.color = brickWhite
                    }
                }
                if i == 10 || i == 11 {
                    if j == 1 || j == 2 || j == 3 || j == 4 || j == 6 || j == 7 || j == 8 || j == 9 {
                        brick.texture = brickNormalTexture
                        brick.color = brickWhite
                    }
                }
                // Normal bricks
                
                if i == 18 {
                   if j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10 {
                       brick.texture = brickMultiHit1Texture
                   }
               }
               // Indestructible bricks
                
                if i == 3 {
                    if j == 0 || j == 4 || j == 6 || j == 10 {
                        brick.texture = brickIndestructible1Texture
                    }
                    if j == 2 || j == 8 {
                        brick.texture = brickIndestructible2Texture
                    }
                }
                // Indestructible bricks

                if brick.texture == brickNormalTexture {
                    brick.colorBlendFactor = 1.0
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
