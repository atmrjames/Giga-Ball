//
//  Level083.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel83() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 5 && i >= 0 && i <= 1 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 4 || j == 6) && i >= 1 && i <= 2 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 3 || j == 7) && i >= 3 && i <= 6 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 2 || j == 8) && i >= 7 && i <= 16 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 1 || j == 9) && i >= 13 && i <= 21 {
                    brick.texture = brickMultiHit1Texture
                }
                if (j == 0 || j == 10) && i >= 12 && i <= 19 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j == 5 && i >= 2 && i <= 3 {
                    brick.texture = brickMultiHit2Texture
                }
                if (j == 4 || j == 6) && i >= 3 && i <= 4 {
                    brick.texture = brickMultiHit2Texture
                }
                           
                if j == 5 && i >= 4 && i <= 5 {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 4 || j == 6) && i >= 5 && i <= 7 {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 3 || j == 7) && i >= 7 && i <= 8 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if j == 5 && i >= 6 && i <= 8 {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 4 || j == 6) && i >= 8 && i <= 9 {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 3 || j == 7) && i >= 9 && i <= 11 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if j == 5 && i >= 9 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if (j == 4 || j == 6) && i >= 10 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if (j == 3 || j == 7) && i >= 12 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j == 5 && i >= 11 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 4 || j == 6) && i >= 13 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 3 || j == 7) && i >= 14 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 2 || j == 8) && i >= 17 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 1 || j == 9) && i >= 15 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j == 5 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if (j == 4 || j == 6) && i >= 15 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if (j == 3 || j == 7) && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if (j == 2 || j == 8) && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                
                if j == 5 && i >= 16 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if (j == 4 || j == 6) && i >= 18 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if (j == 3 || j == 7) && i >= 20 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j == 5 && i >= 18 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 4 || j == 6) && i >= 20 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
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
