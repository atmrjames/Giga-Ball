//
//  Level000.swift
//  Megaball
//
//  Created by James Harding on 19/02/2020.
//  Copyright © 2020 James Harding. All rights reserved.
//

import SpriteKit
import GameplayKit

extension GameScene {
    
    func prepEndlessMode(height: Int) {
        endlessMode = true
        endlessMoveInProgress = false
        endlessHeight = height

        life.isHidden = true
        livesLabel.isHidden = true
        multiplierLabel.isHidden = true
        // Remove classic mode labels
        
        scoreLabel.fontSize = fontSize*1.25
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position.y = life.position.y-2
        scoreLabel.text = "\(endlessHeight) m"
        // Setup score label for endless mode
    }
    
    func loadLevel0() {
        
        prepEndlessMode(height: 0)
        
        var brickArray: [SKNode] = []
        // Array to store all bricks

        for i in 0..<numberOfBrickRows {
            for j in 0..<numberOfBrickColumns {
                let brick = SKSpriteNode(imageNamed: "BrickNormal")
                brick.texture = brickNullTexture
                
                if (i == 0 || i == 1) && (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) {
                    brick.texture = brickIndestructible1Texture
                }
                
                if (i == 2 || i == 3) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickMultiHit1Texture
                }
                if (i == 4 || i == 5) && (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) {
                    brick.texture = brickMultiHit1Texture
                }
                
                if (i == 6 || i == 7) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickInvisibleTexture
                }
                if (i == 8 || i == 9) && (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) {
                    brick.texture = brickInvisibleTexture
                }
                
                if (i == 10 || i == 11) && (j == 0 || j == 2 || j == 4 || j == 6 || j == 8 || j == 10) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 12 || i == 13) && (j == 1 || j == 3 || j == 5 || j == 7 || j == 9) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 14 || i == 15) && (j == 2 || j == 4 || j == 6 || j == 8) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 16 || i == 17) && (j == 3 || j == 5 || j == 7) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 18 || i == 19) && (j == 4 || j == 6) {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
                }
                if (i == 20 || i == 21) && j == 5 {
                    brick.texture = brickNormalTexture
                    brick.color = brickWhite
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
