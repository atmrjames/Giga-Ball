//
//  Level009.swift
//  Megaball
//
//  Created by James Harding on 28/11/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel9() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (i == 2 || i == 3 || i == 18 || i == 19) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if i == 4 || i == 5 || i == 16 || i == 17 {
                    brick.texture = brickInvisibleTexture
                }
                
                if (i == 6 || i == 7 || i == 14 || i == 15) && (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (i == 10 || i == 11) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickIndestructible1Texture
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
