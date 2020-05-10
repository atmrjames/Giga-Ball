//
//  Level052.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel52() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 8 && i >= 2 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 1 && j <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 9 && i >= 4 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 10 && i >= 6 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if j >= 2 && j <= 8 && i >= 11 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if i == 10 && j >= 3 && j <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j >= 3 && j <= 7 && i >= 0 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j >= 4 && j <= 6 && i == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                
                if j == 6 && i >= 1 && i <= 3 {
                    brick.texture = brickInvisibleTexture
                }
                
                if i == 13 && ((j >= 3 && j <= 5) || j == 7) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 15 && ((j >= 5 && j <= 7) || j == 3) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 17 && ((j >= 3 && j <= 4) || (j >= 6 && j <= 7)) {
                    brick.texture = brickInvisibleTexture
                }
                if i == 19 && ((j >= 3 && j <= 5) || j == 7) {
                    brick.texture = brickInvisibleTexture
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
