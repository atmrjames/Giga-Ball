//
//  Level011.swift
//  Megaball
//
//  Created by James Harding on 03/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel11() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 1 || j == 7) && i >= 6 && i <= 15 {
                    brick.texture = brickInvisibleTexture
                }
                if (j == 2 || j == 6) && i >= 4 && i <= 17 {
                    brick.texture = brickInvisibleTexture
                }
                if (j == 3 || j == 5) && i >= 3 && i <= 18 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 4 && i >= 2 && i <= 19 {
                    brick.texture = brickInvisibleTexture
                }

                if j == 5 && (i == 2 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 6 && (i == 2 || i == 3 || i == 18 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 7 && ((i >= 3 && i <= 6) || (i >= 15 && i <= 18)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 8 && (i >= 4 && i <= 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 9 && (i >= 6 && i <= 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                // Normal bricks

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
