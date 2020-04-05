//
//  Level016.swift
//  Megaball
//
//  Created by James Harding on 03/03/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel16() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if j == 5 && (i == 10 || i == 11) {
                    brick.texture = brickIndestructible1Texture
                }
                
                if j == 0 && i >= 2 && i <= 19 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 1 && ((i >= 2 && i <= 3) || (i >= 18 && i <= 19)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 2 && ((i >= 0 && i <= 1) || (i >= 8 && i <= 13) || (i >= 20 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 3 && ((i >= 6 && i <= 7) || (i >= 14 && i <= 15)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 4 && ((i >= 0 && i <= 1) || (i >= 4 && i <= 5) || (i >= 16 && i <= 17) || (i >= 20 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 5 && i >= 14 && i <= 15 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 6 && ((i >= 0 && i <= 1) || (i >= 4 && i <= 5) || (i >= 12 && i <= 13) || (i >= 20 && i <= 21)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 7 && ((i >= 6 && i <= 7) || (i >= 18 && i <= 19)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 8 && ((i >= 0 && i <= 1) || (i >= 8 && i <= 13) || (i >= 16 && i <= 17)) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if j == 10 {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) && (i == 0 || i == 1) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 1 || j == 3 || j == 5 || j == 7) && (i == 20 || i == 21) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 0 || j == 10) && (i == 2 || i == 3 || i == 6 || i == 7 || i == 10 || i == 11 || i == 14 || i == 15 || i == 18 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 2 || j == 8) && (i == 6 || i == 7 || i == 10 || i == 11 || i == 14 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 8 && (i == 18 || i == 19) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 3 || j == 5) && (i == 4 || i == 5 || i == 16 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 7 && (i == 4 || i == 5) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 6 && (i == 14 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if (j == 4 || j == 6) && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
                }
                if j == 5 && (i == 8 || i == 9) {
                    brick.texture = brickNormalTexture
                    brick.color = brickPurple
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
