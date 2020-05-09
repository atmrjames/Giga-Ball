//
//  Level109.swift
//  Megaball
//
//  Created by James Harding on 02/05/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    func loadLevel109() {

        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (j == 1 || j == 9) && i >= 2 && i <= 19 {
                    brick.texture = brickInvisibleTexture
                }
                
                if j >= 1 && j <= 9 && (i == 2 || i == 3 || i == 18 || i == 19)  {
                    brick.texture = brickInvisibleTexture
                }
                
                if (j == 2 || j == 8) && (i == 4 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueLight
                }
                
                if (j == 2 || j == 8) && (i == 5 || i == 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                if (j == 3 || j == 7) && (i == 4 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDark
                }
                
                if (j == 2 || j == 8) && (i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 3 || j == 7) && (i == 5 || i == 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                if (j == 4 || j == 6) && (i == 4 || i == 17) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBlueDarkExtra
                }
                
                if (j == 2 || j == 8) && (i == 8 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if (j == 3 || j == 7) && (i == 7 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if (j == 4 || j == 6) && (i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                if j == 5 && (i == 5 || i == 16) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
                }
                
                if (j == 2 || j == 8) && (i == 9 || i == 12) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if (j == 3 || j == 7) && (i == 8 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if (j == 4 || j == 6) && (i == 7 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                if j == 5 && (i == 6 || i == 15) {
                    brick.texture = brickNormalTexture
                    brick.color = brickBrown
                }
                
                if (j == 2 || j == 8) && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if (j == 3 || j == 7) && (i == 9 || i == 12) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if (j == 4 || j == 6) && (i == 8 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                if j == 5 && (i == 7 || i == 14) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeDark
                }
                
                if (j == 3 || j == 7) && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if (j == 4 || j == 6) && (i == 9 || i == 12) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                if j == 5 && (i == 8 || i == 13) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrange
                }
                
                if (j == 4 || j == 6) && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                if j == 5 && (i == 9 || i == 12) {
                    brick.texture = brickNormalTexture
                    brick.color = brickOrangeLight
                }
                
                if j == 5 && (i == 10 || i == 11) {
                    brick.texture = brickNormalTexture
                    brick.color = brickYellowDark
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
