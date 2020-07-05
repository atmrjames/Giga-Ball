//
//  Level023.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel23() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 1 && i >= 9 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 2 && i >= 7 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 3 && i >= 3 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j == 4 && i >= 1 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 4 && j <= 6 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j == 9 && i >= 9 && i <= 16 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 8 && i >= 7 && i <= 18 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 7 && i >= 3 && i <= 20 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 6 && i >= 1 && i <= 20 {
                    brick.texture = brickIndestructible1Texture
                }
                if j == 5 && i == 0 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j >= 2 && j <= 8 && i >= 9 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 3 && j <= 7 && i >= 7 && i <= 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j >= 4 && j <= 6 && i >= 3 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 5 && i >= 1 && i <= 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
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
