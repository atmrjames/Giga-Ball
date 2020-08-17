//
//  Level001.swift
//  Megaball
//
//  Created by James Harding on 08/09/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel1() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) && (i == 2 || i == 3 || i == 6 || i == 7 || i == 10 || i == 11 || i == 14 || i == 15 || i == 18 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 2 || j == 4 || j == 6 || j == 8) && (i == 4 || i == 5 || i == 8 || i == 9 || i == 12 || i == 13 || i == 16 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 5 && (i == 10 || i == 11) {
                    brick.texture = brickIndestructible1Texture
                }
                
                if brick.texture == brickInvisibleTexture {
                    brick.isHidden = true
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
