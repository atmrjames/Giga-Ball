//
//  Level031.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel31() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 0 && j <= 10 && i >= 6 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j >= 1 && j <= 9 && i >= 3 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j >= 2 && j <= 8 && i >= 1 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j >= 3 && j <= 7 && i >= 0 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                
                if j >= 1 && j <= 9 && i >= 7 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 2 && j <= 8 && i >= 5 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 3 && j <= 7 && i >= 3 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 4 && j <= 6 && i >= 2 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j >= 2 && j <= 8 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 3 && j <= 7 && i >= 6 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 4 && j <= 6 && i >= 5 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j >= 3 && j <= 7 && i >= 9 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j >= 4 && j <= 6 && i >= 7 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j >= 4 && j <= 6 && i >= 9 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 5 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                
                if j == 5 && i >= 10 && i <= 11 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 1 || j == 5) && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if ((j >= 0 && j <= 2) || (j >= 4 && j <= 6) || j == 10) && i == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 0 || j == 2 || j == 4 || (j >= 6 && j <= 10)) && i == 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 2 || j == 4 || (j >= 7 && j <= 9)) && i == 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 2 && j <= 4 && i == 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 3 && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
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
