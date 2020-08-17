//
//  Level077.swift
//  Megaball
//
//  Created by James Harding on 20/04/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel77() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if i >= 11 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if j == 2 && i == 1 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if j >= 1 && j <= 3 && i == 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                
                if j == 9 && i <= 3 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                if j >= 8 && j <= 10 && i >= 1 && i <= 2 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowLight
                }
                
                if j == 9 && i >= 1 && i <= 2 {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (j == 5 || j == 7) && i == 4 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                if j >= 5 && j <= 7 && i >= 5 && i <= 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreen
                }
                
                if j == 6 && i == 6 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 7 && i == 7 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                if j == 5 && i == 8 {
                    brick.texture = brickNormalTexture
                    brick.color = brickGreenDark
                }
                
                if j == 7 && i == 6 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 6 && i >= 7 && i <= 9 {
                    brick.texture = brickIndestructible2Texture
                }
                if j >= 0 && j <= 2 && i >= 10 && i <= 11 {
                    brick.texture = brickIndestructible2Texture
                }
                if j == 3 && i == 10 {
                    brick.texture = brickIndestructible2Texture
                }
                
                if j == 1 && i == 9 {
                    brick.texture = brickMultiHit1Texture
                }
                if j >= 0 && j <= 3 && i == 8 {
                    brick.texture = brickMultiHit1Texture
                }
                if j >= 1 && j <= 2 && i == 7 {
                    brick.texture = brickMultiHit1Texture
                }
                if j == 1 && i == 6 {
                    brick.texture = brickMultiHit1Texture
                }
                
                if j >= 5 && j <= 7 && i >= 10 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j >= 4 && j <= 9 && i >= 11 && i <= 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j == 3 && i == 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j == 10 && i == 12 {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                
                if j >= 2 && j <= 3 && i == 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if (j == 1 || j == 10) && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 3 && j <= 5 && i == 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 7 && j <= 8 && i == 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 1 && j <= 3 && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 6 && j <= 7 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j == 5 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if (j == 1 || j == 8) && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 2 && j <= 3 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                if j >= 6 && j <= 7 && i == 21 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                
                if (j == 0 || j == 5) && i == 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 9 && j <= 10 && i == 13 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 8 && i == 14 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 2 && i == 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 4 && j <= 6 && i == 16 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 0 || j == 8) && i == 17 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 2 && j <= 3 && i == 18 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 0 || j == 4) && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j >= 7 && j <= 9 && i == 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 10 && i == 20 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if i == 13 && (j == 1 || j == 2) {
                    brick.texture = brickNullTexture
                }
                if i == 14 && j == 5 {
                    brick.texture = brickNullTexture
                }
                if i == 15 && (j == 1 || j == 2 || j == 9) {
                    brick.texture = brickNullTexture
                }
                if i == 17 && (j == 1 || j == 6 || j == 9) {
                    brick.texture = brickNullTexture
                }
                if i == 18 && (j == 7 || j == 8) {
                    brick.texture = brickNullTexture
                }
                if i == 19 && j == 1 {
                    brick.texture = brickNullTexture
                }
                if i == 20 && (j == 2 || j == 3 || j == 4) {
                    brick.texture = brickNullTexture
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
