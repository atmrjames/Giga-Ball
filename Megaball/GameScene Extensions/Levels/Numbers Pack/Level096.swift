//
//  Level096.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel96() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 1 || j == 5 || j == 7 || j == 9) && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 2 && j <= 3 && i >= 6 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if j == 1 && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 3 && i == 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j >= 1 && j <= 3 && i >= 10 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 5 && i >= 9 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 7 && i >= 9 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 8 && i >= 11 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if j == 9 && i >= 9 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if (j == 3 || j == 5 || j == 7 || j == 9) && i >= 13 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 1 && j <= 2 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
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
