//
//  Level047.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel47() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 3 && j <= 7 && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 4 && j <= 6 && i >= 3 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 5 && i >= 1 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 6 && i >= 3 && i <= 6 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 7 && i >= 0 && i <= 3 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j >= 3 && j <= 7 && i >= 10 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 4 && j <= 6 && i >= 12 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 5 && i >= 10 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j >= 3 && j <= 7 && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if (j == 4 || j == 6) && (i == 11 || i == 13 || i == 15 || i == 17 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
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
