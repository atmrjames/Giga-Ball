//
//  Level072.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel72() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if i >= 4 && i <= 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if i >= 8 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if i >= 12 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if i >= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrownLight
                }
                
                if j >= 4 && j <= 10 && i >= 10 && i <= 13 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 5 && j <= 9 && i >= 8 && i <= 9 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 5 && j <= 8 && i >= 6 && i <= 7 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 6 && j <= 7 && i >= 4 && i <= 5 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 6 && i >= 2 && i <= 3 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j >= 0 && j <= 4 && i >= 12 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j >= 1 && j <= 4 && i >= 10 && i <= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j >= 2 && j <= 4 && i >= 8 && i <= 9 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j >= 3 && j <= 4 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j == 4 && i >= 4 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j == 5 && i >= 2 && i <= 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                
                if j >= 1 && j <= 10 && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j >= 2 && j <= 9 && i == 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j >= 3 && j <= 8 && i == 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j >= 4 && j <= 7 && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j >= 5 && j <= 7 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 6 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
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
