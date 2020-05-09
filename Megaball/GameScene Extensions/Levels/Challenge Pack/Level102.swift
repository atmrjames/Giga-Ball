//
//  Level102.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel102() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 0 || j == 3 || j == 6 || j == 9) && (i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 1 || j == 4 || j == 7 || j == 10) && (i == 0 || i == 9 || i == 18) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 2 || j == 5 || j == 8) && (i == 3 || i == 12 || i == 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if (j == 0 || j == 3 || j == 6 || j == 9) && (i == 8 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 1 || j == 4 || j == 7 || j == 10) && (i == 2 || i == 11 || i == 20) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 2 || j == 5 || j == 8) && (i == 5 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                
                if (j == 0 || j == 3 || j == 6 || j == 9) && (i == 0 || i == 9 || i == 18) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 1 || j == 4 || j == 7 || j == 10) && (i == 3 || i == 12 || i == 21) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 2 || j == 5 || j == 8) && (i == 6 || i == 15) {
                    brick.texture = brickIndestructible1Texture
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
