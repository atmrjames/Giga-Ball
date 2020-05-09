//
//  Level032.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel32() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 2 && j <= 8 && i >= 12 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if j >= 3 && j <= 7 && i >= 8 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j >= 4 && j <= 6 && i >= 4 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
                }
                
                if j == 5 && i == 0 {
                    brick.texture = brickMultiHit4Texture
                }
                if j == 5 && i == 1 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 5 && i == 2 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 5 && i == 3 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 3 || j == 5 || j == 7) && (i == 14 || i == 18) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if (j == 3 || j == 5 || j == 7) && (i == 15 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 4 && j <= 6 && i >= 8 && i <= 11 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 5 && i >= 4 && i <= 7 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 5 && i >= 8 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
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
