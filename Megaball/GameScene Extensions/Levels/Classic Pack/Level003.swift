//
//  Level003.swift
//  Megaball
//
//  Created by James Harding on 18/12/2019.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel3() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 3 {
                    brick.texture = brickIndestructible1Texture
                }
                
//                if j >= 4 && j <= 10 && ((i >= 4 && i <= 7) || (i >= 14 && i <= 17)) {
//                    brick.texture = brickNormalTexture
//                    brick.color = brickWhite
//                }
                
                if (j == 4 || j == 10) && (i == 4 || i == 8 || i == 13 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 5 || j == 9) && (i == 3 || i == 18 || i == 7 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (j == 6 || j == 8) && (i == 2 || i == 19 || i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j == 7 && (i == 1 || i == 20 || i == 5 || i == 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 4 || j == 10) && (i == 0 || i == 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                
                if (j == 4 || j == 10) && (i == 2 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 5 || j == 9) && (i == 1 || i == 20) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if (j == 6 || j == 8) && (i == 0 || i == 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }

                if (j == 4 || j == 10) && (i == 6 || i == 15) {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 5 || j == 9) && (i == 5 || i == 16) {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 6 || j == 8) && (i == 4 || i == 17) {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 7 && (i == 3 || i == 18) {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j >= 4 && j <= 10 && i >= 9 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j >= 5 && j <= 9 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j >= 6 && j <= 8 && i >= 7 && i <= 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 7 && (i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }

                if j >= 5 && j <= 9 && i >= 9 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if j >= 6 && j <= 8 && i >= 8 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                if j == 7 && (i == 7 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPink
                }
                
                if j >= 6 && j <= 8 && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
                }
                if j == 7 && (i == 9 || i == 12) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlue
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
