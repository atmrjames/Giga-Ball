//
//  Level006.swift
//  Megaball
//
//  Created by James Harding on 05/03/2020.
//  Copyright © 2019 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel6() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 0 || j == 10) && (i <= 3 || i >= 20) {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 1 || j == 9) && (i <= 2 || i >= 21) {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 2 || j == 8) && i <= 1 {
                    brick.texture = brickIndestructible2Texture
                }
                if (j == 3 || j == 7) && i == 0 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 5 && (i == 11 || i == 12) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 0 || j == 10) && (i == 4 || i == 19) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 1 || j == 9) && (i == 3 || i == 20) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 2 || j == 8) && (i == 2 || i == 21) {
                    brick.texture = brickIndestructible1Texture
                }
                if (j == 3 || j == 7) && i == 1 {
                    brick.texture = brickIndestructible1Texture
                }
                if j >= 4 && j <= 6 && i == 0 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (j == 0 || j == 10) && i >= 6 && i <= 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if (j == 2 || j == 3 || j == 7 || j == 8) && i >= 11 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                if j == 5 && ((i >= 4 && i <= 7) || (i >= 15 && i <= 18)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellow
                }
                
                if (j == 3 || j == 7) && (i == 7 || i == 8 || i == 15 || i == 16) {
                    brick.texture = brickMultiHit1Texture
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
