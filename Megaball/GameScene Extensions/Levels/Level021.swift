//
//  Level021.swift
//  Megaball
//
//  Created by James Harding on 13/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel21() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture

                if (j == 0 || j == 10) && (i >= 10 && i <= 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 1 || j == 9) && (i >= 8 && i <= 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 2 || j == 8) && (i >= 6 && i <= 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 3 || j == 7) && (i >= 4 && i <= 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if (j == 4 || j == 6) && (i >= 2 && i <= 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                if j == 5 && (i >= 0 && i <= 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenLight
                }
                
                if (j == 1 || j == 9) && (i >= 10 && i <= 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j == 2 || j == 8) && (i >= 8 && i <= 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j == 3 || j == 7) && (i >= 6 && i <= 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if (j == 4 || j == 6) && (i >= 4 && i <= 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j == 5 && (i >= 2 && i <= 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if (j == 2 || j == 8) && (i >= 11 && i <= 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if (j == 3 || j == 7) && (i >= 10 && i <= 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if (j == 4 || j == 6) && (i >= 7 && i <= 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 5 && (i >= 4 && i <= 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
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
