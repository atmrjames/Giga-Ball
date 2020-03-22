//
//  Level020.swift
//  Megaball
//
//  Created by James Harding on 03/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel20() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j >= 6 && j <= 10 && i >= 15 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j >= 7 && j <= 9 && i >= 14 && i <= 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                
                if j >= 7 && j <= 9 && i >= 16 && i <= 19 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 8 && i >= 17 && i <= 18 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 0 && i >= 2 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 1 && i >= 3 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 2 && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 3 && i == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 1 && i >= 7 && i <= 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 2 && j <= 5 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j == 2 && i >= 8 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j >= 3 && j <= 6 && i == 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                
                if j == 2 && i >= 10 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 3 && i >= 9 && i <= 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j >= 4 && j <= 6 && i == 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if j == 3 && i >= 11 && i <= 12 {
                    brick.texture = brickMultiHit4Texture
                }
                if j == 4 && i >= 10 && i <= 11 {
                    brick.texture = brickMultiHit4Texture
                }
                if j >= 4 && j <= 7 && i == 10 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if j == 3 && i >= 13 && i <= 15 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 4 && i >= 12 && i <= 13 {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 5 && i >= 11 && i <= 12 {
                    brick.texture = brickMultiHit3Texture
                }
                if j >= 6 && j <= 7 && i == 11 {
                    brick.texture = brickMultiHit3Texture
                }
                
                if j == 4 && i >= 14 && i <= 17 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 5 && i >= 13 && i <= 14 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 6 && i >= 12 && i <= 13 {
                    brick.texture = brickMultiHit2Texture
                }
                if j >= 7 && j <= 9 && i == 12 {
                    brick.texture = brickMultiHit2Texture
                }
                
                if j == 5 && i >= 15 && i <= 18 {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 6 && i == 14 {
                    brick.texture = brickMultiHit2Texture
                }
                if j >= 7 && j <= 9 && i == 13 {
                    brick.texture = brickMultiHit2Texture
                }
                
                if j == 0 && i == 15 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 2 && i == 17 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 4 && i == 20 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 7 && i == 1 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 8 && i == 6 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 9 && i == 10 {
                    brick.texture = brickIndestructible1Texture
                }

                if brick.texture == brickNormalTexture {
                    brick.colorBlendFactor = 1.0
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
