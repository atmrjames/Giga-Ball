//
//  Level086.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel86() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 8 && i >= 0 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 7 && i >= 0 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 6 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j == 4 && i >= 2 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 5 && i >= 6 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 6 && i >= 2 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 7 && i >= 6 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 8 && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j == 5 && ((i >= 4 && i <= 5) || (i >= 18 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 6 && ((i >= 6 && i <= 9) || (i >= 14 && i <= 17)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 7 && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                
                if (j == 0 || j == 10) && i >= 4 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if (j == 1 || j == 9) && i >= 2 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 2 && i >= 0 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 3 && i >= 0 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 4 && i >= 6 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 5 && i >= 10 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j == 5 && i >= 0 && i <= 3 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if (j >= 1 && j <= 3) && i == 0 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j >= 0 && j <= 1) && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 4 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
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
