//
//  Level015.swift
//  Megaball
//
//  Created by James Harding on 03/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel15() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 1 || j == 9) && i == 1 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (j == 0 || j == 2 || j == 8 || j == 10) && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if (j == 1 || j == 9) && (i == 0 || i == 2) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if (j == 2 || j == 8) && i >= 16 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if (j == 2 || j == 8) && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if (j == 3 || j == 7) && i >= 11 && i <= 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if (j == 4 || j == 6) && i >= 6 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyLight
                }
                
                if j == 5 && i >= 6 && i <= 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 5 && (i == 14 || i == 15) {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (j == 4 || j == 6) && (i == 14 || i == 15) {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 5 && (i == 16 || i == 17) {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (j == 4 || j == 6) && (i >= 16 && i <= 17) {
                    brick.texture = brickMultiHit2Texture
                }
                if j == 5 && (i >= 18 && i <= 19) {
                    brick.texture = brickMultiHit2Texture
                }
                
                if (j == 4 || j == 6) && (i >= 18 && i <= 19) {
                    brick.texture = brickMultiHit3Texture
                }
                if j == 5 && (i >= 20 && i <= 21) {
                    brick.texture = brickMultiHit3Texture
                }
                
                if j == 5 && (i >= 0 && i <= 2) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                if j == 5 && i == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGrey
                }
                
                if (j == 4 || j == 6) && (i >= 2 && i <= 5) {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreyDark
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
