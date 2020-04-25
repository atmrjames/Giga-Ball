//
//  Level062.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel62() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 3 || j == 4 || j == 6 || j == 7) {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 2 || j == 8) && i >= 1 {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 1 || j == 9) && i >= 5 && i <= 20 {
                    brick.texture = brickMultiHit4Texture
                }
                if (j == 0 || j == 10) && i >= 9 && i <= 17 {
                    brick.texture = brickMultiHit4Texture
                }
                
                if (i == 1 || i == 21) && (j == 2 || j == 3 || j == 7 || j == 8) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if i == 3 && (j == 3 || j == 4 || j == 6 || j == 7) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if i == 5 && ((j >= 1 && j <= 3) || (j >= 7 && j <= 9)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (i == 7 || i == 19) && ((j >= 2 && j <= 4) || (j >= 6 && j <= 8)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (i == 9 || i == 13 || i == 17) && ((j >= 0 && j <= 3) || (j >= 7 && j <= 10)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                if (i == 11 || i == 15) && ((j >= 1 && j <= 4) || (j >= 6 && j <= 9)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if (j == 4 || j == 6) && (i == 0 || i == 5 || i == 8 || i == 12 || i == 16) {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 3 || j == 7) && (i == 2 || i == 10 || i == 14 || i == 18 || i == 20) {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 2 || j == 8) && (i == 4 || i == 6) {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 1 || j == 9) && (i == 8 || i == 12 || i == 16 || i == 19) {
                    brick.texture = brickMultiHit3Texture
                }
                if (j == 0 || j == 10) && (i == 10 || i == 14) {
                    brick.texture = brickMultiHit3Texture
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
