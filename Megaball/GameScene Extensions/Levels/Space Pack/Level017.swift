//
//  Level017.swift
//  Megaball
//
//  Created by James Harding on 03/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel17() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 0 && i == 7 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 2 && i == 21 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 4 && i == 16 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 6 && i == 14 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 8 && i == 9 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 10 && i == 19 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 0 && i >= 4 && i <= 6 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 2 && i >= 18 && i <= 20 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 4 && i >= 13 && i <= 15 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 6 && i >= 11 && i <= 13 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 8 && i >= 6 && i <= 8 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 10 && i >= 16 && i <= 18 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j == 0 && i >= 1 && i <= 3 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 2 && i >= 15 && i <= 17 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 4 && i >= 10 && i <= 12 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 6 && i >= 8 && i <= 10 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 8 && i >= 3 && i <= 5 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 10 && i >= 13 && i <= 15 {
                    brick.texture = brickMultiHit2Texture
                }
                
                if j == 0 && i == 0 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 2 && i >= 12 && i <= 14 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 4 && i >= 7 && i <= 9 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 6 && i >= 5 && i <= 7 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 8 && i >= 0 && i <= 2 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 10 && i >= 10 && i <= 12 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if j == 2 && i >= 9 && i <= 11 {
                    brick.texture = brickMultiHit4Texture
                }
                if j == 4 && i >= 4 && i <= 6 {
                    brick.texture = brickMultiHit4Texture
                }
                if j == 6 && i >= 2 && i <= 4 {
                    brick.texture = brickMultiHit4Texture
                }
                if j == 10 && i >= 7 && i <= 9 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if j == 2 && i >= 6 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 4 && i >= 1 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 6 && i >= 0 && i <= 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 10 && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j == 2 && i >= 3 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 4 && i == 0 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 10 && i >= 1 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 2 && i >= 0 && i <= 2 {
                    brick.texture = brickInvisibleTexture
                }
                if j == 10 && i == 0 {
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
